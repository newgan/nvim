---@alias SplitModifier
---|"aboveleft"
---|"belowright"
---|"topleft"
---|"botright"
---|""

---@class SMods
---
---@field vertical?   boolean
---@field silent?     boolean
---@field hide?       boolean
---@field tab?        integer
---@field split?      SplitModifier
---@field noswapfile? boolean

---@class CommandParam
---
---@field args?  string
---@field smods? SMods
---@field bang?  boolean
---@field count? integer

local a = require("plenary.async")
local errors = require("compile-mode.errors")
local utils = require("compile-mode.utils")
local log = require("compile-mode.log")
local ansi = require("compile-mode.ansi")

local M = {}

--- FILE-GLOBAL VARIABLES

local header_line_count = 4

---Common exit codes to check against.
---See `:h on_exit` to understand why 128 + signal number
local exit_code = {
	SUCCESS = 0,
	SIGSEGV = 139, -- 128 + signal number 11
	SIGTERM = 143, -- 128 + signal number 15
}

---Line in the compilation buffer that the current error is on;
---acts as an index of `errors.error_list`
local error_cursor = 0

---The previous directory used for compilation.
---@type string|nil
local compilation_directory = nil

---A table which keeps track of the changes in directory for the compilation buffer,
---based on "Entering directory" and "Leaving directory" messages.
---@type table<integer, string>
M.dir_changes = {}

---Whether or not to preview the error under the cursor.
local in_next_error_mode = false
local has_auto_jumped = false

---Most recent header line seen while parsing (e.g. rustc's `error[E0308]: ...`); gives its
---level to the location-only lines that follow it (matchers with `level_from_previous`).
---@type { level: CompileModeLevel, linenum: integer }|nil
local last_header = nil
---How many lines a location-only line may trail its header by and still inherit its level.
local HEADER_DISTANCE = 3

---Id of this run's "Compilation" quickfix list, nil until pushed (see `live_quickfix`).
---@type integer|nil
local qf_id = nil

---Pending live quickfix/diagnostics sync (see `request_live_sync`).
---@type uv.uv_timer_t|nil
local sync_timer = nil
---Milliseconds between live quickfix/diagnostics syncs while output arrives.
local SYNC_INTERVAL = 200

---Diagnostics for files that were not loaded when computed, keyed by absolute path and
---applied when the file is read (see `live_diagnostics`).
---@type table<string, CompileModeError[]>
local pending_diagnostics = {}
local diagnostics_autocmd_registered = false

---The command of the run in progress (or the last run), for events.
---@type string|nil
local current_command = nil

---Last command per directory (see `remember_commands`): the JSON file `history_file`
---holds a list of {dir, command}, newest first. It is re-read on every use so that
---several Nvim instances do not overwrite each other's entries.
local HISTORY_LIMIT = 50
---What this plugin itself last stored in vim.g.compile_command, to tell apart a value the
---user set explicitly (for example from a project-local .nvim.lua).
---@type string|nil
local plugin_set_command = nil

--- UTILITY FUNCTIONS

---@param bufnr integer
---@param start integer
---@param end_ integer
---@param data string[]
---@return integer
local function set_lines(bufnr, start, end_, data, trim)
	local config = require("compile-mode.config.internal")

	if vim.fn.bufexists(bufnr) == 0 then
		return 0
	end

	-- follow the output only in windows already at the end (see utils.windows_at_end)
	local following = config.auto_scroll and utils.windows_at_end(bufnr) or {}

	utils.buf_set_opt(bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(bufnr, start, end_, false, data)

	local removed_lines = 0
	if trim ~= false and config.max_lines then
		local effective_max_lines = config.max_lines + header_line_count

		local line_count = vim.api.nvim_buf_line_count(bufnr)
		removed_lines = math.max(line_count - effective_max_lines, 0)

		if removed_lines > 0 then
			vim.api.nvim_buf_set_lines(bufnr, header_line_count, header_line_count + removed_lines, false, {})
		end
	end

	vim.schedule(function()
		utils.buf_set_opt(bufnr, "modifiable", false)
		utils.buf_set_opt(bufnr, "modified", false)
	end)

	utils.scroll_to_end(bufnr, following)

	return removed_lines
end

---@param line integer
---@param removed_lines integer
---@return integer|nil
local function shift_linenum(line, removed_lines)
	if line <= header_line_count then
		return line
	end

	if line <= header_line_count + removed_lines then
		return nil
	end

	return line - removed_lines
end

---@param removed_lines integer
local function trim_line_metadata(removed_lines)
	if removed_lines <= 0 then
		return
	end

	local new_error_list = {}
	for line, error in pairs(errors.error_list) do
		local new_line = shift_linenum(line, removed_lines)
		if new_line then
			error.linenum = new_line
			new_error_list[new_line] = error
		end
	end
	errors.error_list = new_error_list

	local new_dir_changes = {}
	for line, dir in pairs(M.dir_changes) do
		local new_line = shift_linenum(line, removed_lines)
		if new_line then
			new_dir_changes[new_line] = dir
		end
	end
	M.dir_changes = new_dir_changes

	error_cursor = shift_linenum(error_cursor, removed_lines) or 0
end

---Get the directory to look in for a specific line in the compilation buffer,
---while respecting "Entering directory" and "Leaving directory" messages.
---@param linenum integer the line number to check the directory for
---@return string
local function find_directory_for_line(linenum)
	local latest_linenum = nil
	local dir = compilation_directory or vim.fn.getcwd()
	for old_linenum, old_dir in pairs(M.dir_changes) do
		if old_linenum < linenum and (not latest_linenum or latest_linenum <= old_linenum) then
			latest_linenum = old_linenum
			dir = old_dir
		end
	end
	return dir
end

---Like `:find`, but splits unless `same_window` is configured.
---@param file string the file to find
---@param same_window boolean if `true`, do not split
local function file_find(file, same_window)
	if not same_window and vim.fn.filereadable(file) ~= 0 then
		vim.cmd("split")
	end

	local ok, msg = pcall(vim.cmd.find, file)
	if not ok then
		vim.notify(string.gsub(msg, "^Vim:", ""), vim.log.levels.ERROR)
	end
end

---Returns a function that acts like `gf` or `CTRL-W_f` (depending on the `same_window` parameter),
---while respecting "Entering directory" and "Leaving directory" messages.
---@param same_window boolean whether to split (i.e. act like `gf`) or not (i.e. act like `CTRL-W_f`)
---@return fun()
local function goto_file(same_window)
	return function()
		local cfile = vim.fn.expand("<cfile>")
		local linenum = unpack(vim.api.nvim_win_get_cursor(0))

		local dir = find_directory_for_line(linenum)

		vim.cmd("set path+=" .. dir)
		file_find(cfile, same_window)
		vim.cmd("set path-=" .. dir)
	end
end

---Normalised absolute form of a directory, the key used in the history file.
---@param dir string
---@return string
local function history_key(dir)
	local abs = vim.fs.normalize(vim.fn.fnamemodify(dir, ":p"))
	return (abs:gsub("(.)/$", "%1"))
end

---@return { dir: string, command: string }[]
local function load_history()
	local config = require("compile-mode.config.internal")
	local ok, lines = pcall(vim.fn.readfile, config.history_file)
	if ok and #lines > 0 then
		local decoded_ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
		if decoded_ok and type(decoded) == "table" then
			return decoded
		end
	end
	return {}
end

---The last command compiled from `dir`, if any.
---@param dir string
---@return string|nil
local function remembered_command(dir)
	local key = history_key(dir)
	for _, entry in ipairs(load_history()) do
		if entry.dir == key then
			return entry.command
		end
	end
	return nil
end

---@param dir string
---@param command string
local function remember_command(dir, command)
	local key = history_key(dir)
	local list = load_history()
	for i = #list, 1, -1 do
		if list[i].dir == key then
			table.remove(list, i)
		end
	end
	table.insert(list, 1, { dir = key, command = command })
	while #list > HISTORY_LIMIT do
		table.remove(list)
	end
	local config = require("compile-mode.config.internal")
	vim.fn.mkdir(vim.fs.dirname(config.history_file), "p")
	local ok, err = pcall(vim.fn.writefile, { vim.json.encode(list) }, config.history_file)
	if not ok then
		log.fmt_warn("could not write %s: %s", config.history_file, err)
	end
end

---@type fun(cmd: string, bufnr: integer, param: CommandParam): integer, integer, integer, boolean
local runjob = a.wrap(
	---@param cmd string
	---@param bufnr integer
	---@param param CommandParam
	---@param callback fun(integer, integer, integer, boolean)
	function(cmd, bufnr, param, callback)
		local config = require("compile-mode.config.internal")

		log.debug("calling runjob()")

		local count = 0
		---Raw text of the buffer's last line, which the next read may continue.
		local partial_line = ""
		local is_exited = false
		local line_limit_exceeded = false
		local job_id

		---Raw output lines not written to the buffer yet; the last one is the partial line.
		---@type string[]
		local pending = {}
		---@type uv.uv_timer_t|nil
		local flush_timer = nil
		---Flushes in progress (a flush yields once between writing and parsing).
		local flushing = 0

		---Write everything pending in one go and parse it. Output arrives in many small
		---reads; batching them bounds redraws and parsing to one per `flush_interval`.
		---Must run inside a coroutine (see `utils.wait`).
		local function flush_pending()
			flush_timer = nil
			if #pending == 0 or vim.fn.bufexists(bufnr) == 0 then
				return
			end
			local new_lines = pending
			pending = {}

			flushing = flushing + 1
			local ok, err = pcall(function()
			local line_count = vim.api.nvim_buf_line_count(bufnr)

			for i, line in ipairs(new_lines) do
				for _, re in ipairs(config.hidden_output) do
					line = vim.fn.substitute(line, re, "", "")
				end

				while vim.endswith(line, "\r") do
					line = line:sub(0, -2)
				end

				local last_carriage_return = vim.fn.strridx(line, "\r")
				if last_carriage_return >= 0 and last_carriage_return < line:len() - 1 then
					line = line:sub(last_carriage_return + 2, -1)
				end

				new_lines[i] = line
			end

			local max_lines = config.max_lines
			if max_lines then
				local effective_max_lines = max_lines + header_line_count
				local max_new_lines = effective_max_lines - (line_count - 1)
				if max_new_lines <= 0 then
					line_limit_exceeded = true
					vim.fn.jobstop(job_id)
					return
				elseif #new_lines > max_new_lines then
					line_limit_exceeded = true
					new_lines = vim.list_slice(new_lines, 1, max_new_lines)
					partial_line = new_lines[#new_lines]
				end
			end

			ansi.buf_set_lines(bufnr, -2, -1, new_lines)
			utils.wait()
			M._parse_errors(bufnr, line_count - 1, line_count - 1 + #new_lines)

			if line_limit_exceeded then
				vim.fn.jobstop(job_id)
			end
			end)
			flushing = flushing - 1
			if not ok then
				log.fmt_error("writing output failed: %s", err)
			end
		end
		local flush = a.void(flush_pending)

		local function schedule_flush()
			if config.flush_interval <= 0 then
				flush()
				return
			end
			if not flush_timer then
				flush_timer = vim.defer_fn(flush, config.flush_interval)
			end
		end

		local function on_either(_, data)
			if is_exited or not data or #data < 1 or (#data == 1 and data[1] == "") then
				return
			end

			count = count + #data

			-- data[1] continues the partial line; the rest are new lines
			local first = (data[1]:gsub("\n", ""))
			if #pending == 0 then
				pending[1] = partial_line .. first
			else
				pending[#pending] = pending[#pending] .. first
			end
			for i = 2, #data do
				table.insert(pending, (data[i]:gsub("\n", "")))
			end
			partial_line = pending[#pending]

			schedule_flush()
		end

		local finish = a.void(function(id, code)
			is_exited = true
			if flush_timer and not flush_timer:is_closing() then
				flush_timer:stop()
				flush_timer:close()
			end
			flush_timer = nil
			-- a timer flush may be between its write and its parse: let it finish first,
			-- then write whatever is still pending, so the run completes with everything parsed
			while flushing > 0 do
				utils.wait()
			end
			flush_pending()
			local effective_code = line_limit_exceeded and exit_code.SIGTERM or code
			callback(count, effective_code, id, line_limit_exceeded)
		end)

		log.debug("starting job...")
		job_id = vim.fn.jobstart(cmd, {
			cwd = compilation_directory,
			on_stdout = on_either,
			on_stderr = on_either,
			on_exit = finish,
			pty = config.use_pseudo_terminal,
			env = config.environment,
			clear_env = config.clear_environment,
		})
		log.fmt_debug("job_id = %d", job_id)

		if job_id <= 0 then
			vim.notify("Failed to start job with command " .. cmd, vim.log.levels.ERROR)
			return
		end

		vim.g.compile_job_id = job_id
		vim.cmd.redrawstatus()

		-- only a command that actually started is worth remembering
		if config.remember_commands then
			remember_command(compilation_directory or vim.fn.getcwd(), cmd)
		end

		vim.api.nvim_exec_autocmds("User", {
			pattern = "CompilationStarted",
			data = {
				command = cmd,
				bufnr = bufnr,
				job_id = job_id,
				directory = compilation_directory or vim.fn.getcwd(),
			},
		})

		if param.bang then
			log.debug("sync mode - waiting for job to finish...")
			vim.fn.jobwait({ job_id })
		end

		-- one handler per buffer: without clearing, every (re)compile stacked another one
		local group = vim.api.nvim_create_augroup("compile-mode.nvim/job", { clear = false })
		vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr, event = "BufDelete" })
		vim.api.nvim_create_autocmd({ "BufDelete" }, {
			group = group,
			buffer = bufnr,
			callback = function()
				vim.g.compilation_exit_code = nil
				vim.g.compile_job_id = nil
				vim.fn.jobstop(job_id)
			end,
		})
	end,
	4
)

---Get the current time, formatted.
local function time()
	local config = require("compile-mode.config.internal")
	return vim.fn.strftime(config.time_format)
end

---Get the default directory, formatted.
local function default_dir()
	local cwd = compilation_directory or vim.fn.getcwd() --[[@as string]]
	return cwd:gsub("^" .. vim.env.HOME, "~")
end

---Run `command` and place the results in the "Compilation" buffer.
---
---@type fun(command: string, param: CommandParam)
local runcommand = a.void(
	---@param command string
	---@param param CommandParam
	function(command, param)
		local config = require("compile-mode.config.internal")

		log.debug("calling runcommand()")

		if config.ask_about_save and utils.ask_to_save(param.smods or {}) then
			return
		end

		error_cursor = 0
		errors.error_list = {}
		M.dir_changes = {}
		has_auto_jumped = false
		last_header = nil
		qf_id = nil
		pending_diagnostics = {}
		current_command = command
		M._cancel_live_sync()
		utils.clear_diagnostics()

		if vim.g.compile_job_id then
			if config.ask_to_interrupt then
				local response = vim.fn.confirm("Interrupt running process?", "&Yes\n&No")
				if response ~= 1 then
					return
				end
			end

			M.interrupt()

			utils.delay(1000)
		end

		if config.bang_expansion then
			command = vim.fn.expandcmd(command)
		end

		local error = errors.parse(command, 4)
		if error then
			errors.error_list[4] = error
		end

		log.debug("opening compilation buffer...")

		local prev_win = vim.api.nvim_get_current_win()
		local wsmods, wcount = utils.apply_window_defaults(param.smods, param.count)
		local bufnr = utils.split_unless_open(
			{ fname = config.buffer_name },
			vim.tbl_extend("force", wsmods, { noswapfile = true }),
			wcount
		)
		utils.wait()

		utils.clear_highlights(bufnr)

		if config.focus_compilation_buffer then
			vim.api.nvim_set_current_win(vim.fn.win_findbuf(bufnr)[1])
		else
			vim.api.nvim_set_current_win(prev_win)
		end

		log.fmt_debug("bufnr = %d", bufnr)

		utils.buf_set_opt(bufnr, "buftype", "nofile")
		utils.buf_set_opt(bufnr, "buflisted", not config.hidden_buffer)

		-- reset compilation buffer
		set_lines(bufnr, 0, -1, {})
		utils.wait()

		vim.b[bufnr].compilation_main_buffer = true
		utils.buf_set_opt(bufnr, "filetype", "compilation")

		set_lines(bufnr, 0, 0, {
			"vim: filetype=compilation:path+=" .. default_dir(),
			"Compilation started at " .. time(),
			"",
			command,
		})

		utils.wait()
		M._parse_errors(bufnr, 0, -1)
		errors.highlight(bufnr)

		log.fmt_debug("running command: %s", command)

		local start_time = vim.loop.hrtime()

		local line_count, code, job_id, line_limit_exceeded = runjob(command, bufnr, param)

		local elapsed = (vim.loop.hrtime() - start_time) / 1e9

		if job_id ~= vim.g.compile_job_id then
			return
		end
		vim.g.compile_job_id = nil

		ansi.flush(bufnr)

		if line_count == 0 then
			trim_line_metadata(set_lines(bufnr, -1, -1, { "" }))
		end

		local compilation_message
		if line_limit_exceeded then
			compilation_message = "Compilation terminated: max_lines reached"
		elseif code == exit_code.SUCCESS then
			compilation_message = "Compilation finished"
		elseif code == exit_code.SIGSEGV then
			compilation_message = "Compilation segmentation fault (core dumped)"
		elseif code == exit_code.SIGTERM then
			compilation_message = "Compilation terminated"
		else
			compilation_message = "Compilation exited abnormally with code " .. tostring(code)
		end
		vim.g.compilation_exit_code = code
		vim.cmd.redrawstatus()

		local fmt_elapsed = string.format(", duration %.2f s", elapsed)

		set_lines(bufnr, -1, -1, {
			compilation_message .. " at " .. time() .. fmt_elapsed,
			"",
		}, false)

		if not param.smods or not param.smods.silent then
			local level = vim.log.levels.INFO
			if line_limit_exceeded or code == exit_code.SIGTERM then
				level = vim.log.levels.WARN
			elseif code ~= exit_code.SUCCESS then
				level = vim.log.levels.ERROR
			end
			local counts = M.statusline_info().counts
			vim.notify(
				("%s: %d errors, %d warnings, %.1f s"):format(compilation_message, counts.error, counts.warning, elapsed),
				level
			)
		end

		M._cancel_live_sync()
		M._live_sync()

		vim.api.nvim_exec_autocmds("User", {
			pattern = "CompilationFinished",
			data = {
				command = command,
				code = code,
				bufnr = bufnr,
				elapsed = elapsed,
				directory = compilation_directory or vim.fn.getcwd(),
				counts = M.statusline_info().counts,
			},
		})

		utils.wait()
	end
)

---Create a command that takes some action on the next/previous error from the current error cursor.
---The command is repeated equal to the `count` that it receives, which defaults to `1`.
---
---@param action "jump"|"move" the action to do with the matching error:
--- * "jump" means go to the locus of the error
--- * "move" means scroll to the line in the compilation buffer
---@param direction "next"|"prev" what direction from the error cursor to find matches from:
--- * "next" means work forward from the current error
--- * "prev" means work backwards from the current error
---This also determines the printed message if there is no match in the specified direction.
---@param different_file boolean whether to only match errors that occur in different files from the current error
---@return fun(param: CommandParam?) command an async callback that performs the created action
local function act_from_current_error(action, direction, different_file)
	local name = (action == "jump" and "" or "move_to_") .. direction .. "_" .. (different_file and "file" or "error")
	return a.void(function(param)
		local config = require("compile-mode.config.internal")

		log.debug("calling " .. name .. "()")

		param = param or {}

		local count = param.count or 1
		local current_error = errors.error_list[error_cursor]

		local lines = vim.tbl_keys(errors.error_list)
		table.sort(lines)
		if direction == "prev" then
			lines = vim.fn.reverse(lines)
		end

		local function fits_constraints(line)
			local error = errors.error_list[line]
			if error.level < config.error_threshold then
				return false
			end
			if different_file and current_error and error.filename.value == current_error.filename.value then
				return false
			end
			return true
		end

		local error_line = nil
		local errors_found = 0
		local past_cursor = error_cursor == 0

		for _, line in ipairs(lines) do
			if line == error_cursor then
				past_cursor = true
			elseif past_cursor and fits_constraints(line) then
				errors_found = errors_found + 1
				if errors_found == count then
					error_line = line
					break
				end
			end
		end

		if not error_line and config.use_circular_error_navigation then
			local remaining_count = count - errors_found
			for _, line in ipairs(lines) do
				if fits_constraints(line) then
					remaining_count = remaining_count - 1
					if remaining_count == 0 then
						error_line = line
						break
					end
				end
			end
		end

		if not error_line then
			if not param.smods or not param.smods.silent then
				local message = direction == "next" and "past last" or "back before first"
				vim.notify("Moved " .. message .. " error")
			end
			return
		end

		error_cursor = error_line
		if action == "jump" then
			local dir = find_directory_for_line(error_line)
			utils.jump_to_error(errors.error_list[error_line], dir, param.smods or {})
		else
			vim.api.nvim_win_set_cursor(0, { error_line, 0 })
		end
	end)
end

--- PUBLIC (NON-COMMAND) API

M.level = errors.level

---@class CompileModeStatuslineInfo
---@field counts {error: integer, warning: integer, info: integer}
---@field status {type: "run"}|{type:"exit", code: integer}|nil

---@return CompileModeStatuslineInfo
function M.statusline_info()
	local info = {
		status = nil,
		counts = vim.iter(pairs(errors.error_list)):fold({ error = 0, warning = 0, info = 0 }, function(acc, _, v)
			if not v then
				return acc
			end

			if v.level == M.level.ERROR then
				acc.error = acc.error + 1
			elseif v.level == M.level.WARNING then
				acc.warning = acc.warning + 1
			elseif v.level == M.level.INFO then
				acc.info = acc.info + 1
			end

			return acc
		end),
	}

	if vim.g.compile_job_id then
		info.status = { type = "run" }
	elseif vim.g.compilation_exit_code then
		info.status = { type = "exit", code = vim.g.compilation_exit_code }
	end

	return info
end

function M.statusline(colors)
	if vim.bo.filetype ~= "compilation" and not vim.g.compile_job_id and not vim.g.compilation_exit_code then
		return ""
	end

	colors = colors and colors ~= 0

	local info = M.statusline_info()

	local status_text
	if not info.status then
		status_text = ""
	elseif info.status.type == "run" then
		status_text = ":run"
		if colors then
			status_text = "%#CompileModeCheckTarget#" .. status_text .. "%*"
		end
	elseif info.status.type == "exit" then
		status_text = (":exit [%d]"):format(info.status.code)
		if colors then
			local color = info.status.code == exit_code.SUCCESS and "%#CompileModeInfo#" or "%#CompileModeError#"
			status_text = color .. status_text .. "%*"
		end
	end

	local error_count = ("%d"):format(info.counts.error)
	if colors then
		error_count = "%#CompileModeError#" .. error_count .. "%*"
	end
	local warning_count = ("%d"):format(info.counts.warning)
	if colors then
		warning_count = "%#CompileModeWarning#" .. warning_count .. "%*"
	end
	local info_count = ("%d"):format(info.counts.info)
	if colors then
		info_count = "%#CompileModeInfo#" .. info_count .. "%*"
	end

	return ("Compilation%s [%s %s %s]"):format(status_text, error_count, warning_count, info_count)
end

--- GENERAL COMMANDS

---Prompt for (or get by parameter) a command and run it.
---
---@type fun(param: CommandParam?)
M.compile = a.void(
	---@param param CommandParam?
	function(param)
		local config = require("compile-mode.config.internal")

		log.debug("calling compile()")

		param = param or {}

		local command = param.args
		if not command or command == "" then
			local input_completion_func = "CompileInputComplete"
			if package.loaded["cmp_cmdline_prompt"] or config.input_word_completion then
				input_completion_func = "CompileInputCompleteWord"
			end

			local buf = vim.api.nvim_get_current_buf()
			local ft = vim.bo[buf].filetype
			---@type string|nil
			local default_cmd
			if not config.remember_commands then
				default_cmd = vim.g.compile_command
			elseif vim.g.compile_command and vim.g.compile_command ~= plugin_set_command then
				-- set explicitly by the user, not by this plugin after a run
				default_cmd = vim.g.compile_command
			else
				default_cmd = remembered_command(vim.g.compilation_directory or vim.fn.getcwd())
			end
			if not default_cmd then
				if type(config.default_command) == "table" then
					default_cmd = config.default_command[ft] or config.default_command["*"] or ""
				elseif type(config.default_command) == "function" then
					default_cmd = config.default_command(ft) or ""
				else
					default_cmd = config.default_command or ""
				end
			end

			command = utils.input({
				prompt = "Compile command: ",
				default = default_cmd,
				completion = ("customlist,%s"):format(input_completion_func),
			})
		end

		if command == nil then
			return
		end

		vim.g.compile_command = command
		plugin_set_command = command
		compilation_directory = vim.g.compilation_directory or vim.fn.getcwd()

		runcommand(command, param)
		vim.g.compilation_directory = nil
	end
)

---Rerun the last command.
---
---@type fun(param: CommandParam?)
M.recompile = a.void(
	---@param param CommandParam?
	function(param)
		local config = require("compile-mode.config.internal")

		log.debug("calling recompile()")

		param = param or {}

		local cwd = vim.g.compilation_directory or vim.fn.getcwd()
		-- a vim.g.compile_command the user set explicitly beats the directory's history,
		-- as it does for the :Compile prompt
		local explicit = vim.g.compile_command ~= nil and vim.g.compile_command ~= plugin_set_command
		local remembered = (config.remember_commands and not explicit) and remembered_command(cwd) or nil
		if remembered then
			-- this directory has its own last command: rerun that one here
			compilation_directory = cwd
			runcommand(remembered, param)
		elseif vim.g.compile_command then
			runcommand(vim.g.compile_command, param)
		elseif config.recompile_no_fail then
			M.compile(param)
		else
			vim.notify("Cannot recompile without previous command; compile first", vim.log.levels.ERROR)
		end
	end
)

---Jump to the Nth error in the error list, based on the count
---
---@type fun(param: CommandParam?)
M.first_error = a.void(
	---@param param CommandParam?
	function(param)
		local config = require("compile-mode.config.internal")

		log.debug("calling first_error()")

		param = param or {}

		local count = param.count or 1
		log.fmt_debug("count = %d", count)

		local lines = vim.iter(pairs(errors.error_list))
			:filter(function(_, error)
				return error.level >= config.error_threshold
			end)
			:map(function(line, _)
				return line
			end)
			:totable()

		if count < 1 then
			vim.notify("Moved back before first error")
			return
		end

		if count > #lines then
			vim.notify("Moved past last error")
			return
		end

		table.sort(lines)

		error_cursor = assert(lines[count])
		local error = assert(errors.error_list[error_cursor])

		local dir = find_directory_for_line(error_cursor)
		utils.jump_to_error(error, dir, param.smods or {})
	end
)

---Jump to the current error in the error list
---
---@type fun(param: CommandParam?)
M.current_error = a.void(
	---@param param CommandParam?
	function(param)
		log.debug("calling current_error()")

		param = param or {}

		log.fmt_debug("line = %d", error_cursor)

		local error = errors.error_list[error_cursor]
		if not error then
			if not param.smods or not param.smods.silent then
				vim.notify("No error currently loaded")
			end

			return
		end

		local dir = find_directory_for_line(error_cursor)
		utils.jump_to_error(error, dir, param.smods or {})
	end
)

---Jump to the next error in the error list.
M.next_error = act_from_current_error("jump", "next", false)

---Jump to the previous error in the error list.
M.prev_error = act_from_current_error("jump", "prev", false)

---Load all compilation errors into the quickfix list, replacing the existing list.
---
---@type fun()
M.send_to_qflist = a.void(function()
	log.debug("calling send_to_qflist()")

	vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
	vim.fn.setqflist(errors.toqflist(errors.error_list), "r")
	vim.api.nvim_exec_autocmds("QuickFixCmdPost", {})
end)

---Load all compilation errors into the quickfix list, appending onto the existing list.
---
---@type fun()
M.add_to_qflist = a.void(function()
	log.debug("calling add_to_qflist()")

	vim.api.nvim_exec_autocmds("QuickFixCmdPre", {})
	vim.fn.setqflist(errors.toqflist(errors.error_list), "a")
	vim.api.nvim_exec_autocmds("QuickFixCmdPost", {})
end)

---Toggle "Next Error Follow", which causes the error under the cursor to be previewed whenever you move in the compilation buffer.
function M.next_error_follow()
	in_next_error_mode = not in_next_error_mode
	M._follow_cursor()
end

--- COMPILATION BUFFER COMMANDS

---Go to the error on the current line.
---
---@type fun(param: CommandParam?)
M.goto_error = a.void(
	---@param param CommandParam?
	function(param)
		log.debug("calling goto_error()")

		param = param or {}

		local linenum = unpack(vim.api.nvim_win_get_cursor(0))
		local error = errors.error_list[linenum]
		log.fmt_debug("error = %s", error)

		if not error then
			if not param.smods or not param.smods.silent then
				vim.notify("No error here")
			end

			return
		end

		local dir = find_directory_for_line(linenum)

		error_cursor = linenum
		utils.jump_to_error(error, dir, param.smods or {})
	end
)

---Print information about the error on the current line.
---
---@type fun()
M.debug_error = a.void(function()
	log.debug("calling debug_error()")

	local linenum = unpack(vim.api.nvim_win_get_cursor(0))
	local error = errors.error_list[linenum]
	if not error then
		vim.notify("No error here")
		return
	end

	print(("error = %s"):format(vim.inspect(error)))
end)

---Interrupt the currently running compilation command.
---
---@type fun()
M.interrupt = a.void(function()
	log.debug("calling interrupt()")

	if not vim.g.compile_job_id then
		log.debug("nothing to interrupt")
		return
	end

	log.debug("interrupting compilation")
	log.fmt_debug("vim.g.compile_job_id = %d", vim.g.compile_job_id)

	local bufnr = vim.g.compilation_buffer
	log.fmt_debug("bufnr = %d", bufnr)

	local interrupt_message = "Compilation interrupted"

	set_lines(bufnr, -1, -1, {
		"",
		interrupt_message .. " at " .. time(),
	})
	utils.wait()

	local job_id = vim.g.compile_job_id
	vim.fn.jobstop(job_id)
	vim.g.compile_job_id = nil
	vim.api.nvim_exec_autocmds("User", {
		pattern = "CompilationInterrupted",
		data = {
			job_id = job_id,
			bufnr = bufnr,
			command = current_command,
		},
	})
end)

---Close the compilation buffer.
function M.close_buffer()
	local bufnr = vim.g.compilation_buffer

	local win_ids = vim.fn.win_findbuf(bufnr)

	if #vim.api.nvim_list_wins() > 1 then
		vim.iter(win_ids):each(function(win_id)
			vim.api.nvim_win_close(win_id, true)
		end)
	elseif vim.fn.bufexists("#") ~= 0 then
		vim.cmd.buffer("#")
	else
		vim.cmd.bnext()
	end
end

---Move to the location of the next error within the compilation buffer.
---Does not jump to the error's actual locus.
M.move_to_next_error = act_from_current_error("move", "next", false)

---Move to the location of the next error within the compilation buffer that has a different file to the current one.
---Does not jump to the error's actual locus.
M.move_to_next_file = act_from_current_error("move", "next", true)

---Move to the location of the previous error within the compilation buffer.
---Does not jump to the error's actual locus.
M.move_to_prev_error = act_from_current_error("move", "prev", false)

---Move to the location of the previous error within the compilation buffer that has a different file to the current one.
---Does not jump to the error's actual locus.
M.move_to_prev_file = act_from_current_error("move", "prev", true)

-- OUTWARD-FACING UTILITIES

---Absolute path of an error's file, honouring directory-change messages.
---@param linenum integer
---@param error CompileModeError
---@return string
local function error_path(linenum, error)
	local filename = error.filename.value
	if not utils.is_absolute(filename) then
		filename = find_directory_for_line(linenum) .. "/" .. filename
	end
	return vim.fs.normalize(filename)
end

---@class CompileModeErrorItem
---@field linenum integer line of the compilation buffer the error is on
---@field filename string absolute path
---@field lnum integer|nil
---@field end_lnum integer|nil
---@field col integer|nil
---@field end_col integer|nil
---@field text string
---@field type "E"|"W"|"I"

---The current errors at or above `error_threshold`, in buffer order, with absolute paths.
---The order matches |:FirstError| counts, so item N is reachable with `first_error({ count = N })`.
---@return CompileModeErrorItem[]
function M.error_items()
	local config = require("compile-mode.config.internal")
	local type_for = { [errors.level.ERROR] = "E", [errors.level.WARNING] = "W", [errors.level.INFO] = "I" }

	local lines = vim.tbl_keys(errors.error_list)
	table.sort(lines)
	local items = {}
	for _, linenum in ipairs(lines) do
		local error = errors.error_list[linenum]
		if error.level >= config.error_threshold then
			table.insert(items, {
				linenum = linenum,
				filename = error_path(linenum, error),
				lnum = error.row and error.row.value,
				end_lnum = error.end_row and error.end_row.value,
				col = error.col and error.col.value,
				end_col = error.end_col and error.end_col.value,
				text = error.full_text,
				type = type_for[error.level],
			})
		end
	end
	return items
end

---Replace this run's "Compilation" quickfix list with the current errors, pushing a new
---list the first time so other quickfix lists stay on the stack. The list is addressed by
---id, so it is found even after |:QuickfixErrors| retitled it or |:colder| moved away.
function M._update_quickfix()
	local items = M.error_items()
	if #items == 0 and not qf_id then
		return
	end
	local what = { title = "Compilation", items = items }
	if qf_id and vim.fn.setqflist({}, "r", vim.tbl_extend("force", what, { id = qf_id })) == 0 then
		return
	end
	-- first push of this run, or the list was dropped off the stack
	vim.fn.setqflist({}, " ", what)
	qf_id = vim.fn.getqflist({ id = 0 }).id
end

local function ensure_diagnostics_autocmd()
	if diagnostics_autocmd_registered then
		return
	end
	diagnostics_autocmd_registered = true
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = vim.api.nvim_create_augroup("compile-mode.nvim/diagnostics", { clear = true }),
		desc = "Apply compile-mode diagnostics to a file opened after its errors arrived",
		callback = function(ev)
			local path = vim.fs.normalize(vim.api.nvim_buf_get_name(ev.buf))
			local errs = pending_diagnostics[path]
			if errs then
				pending_diagnostics[path] = nil
				utils.set_diagnostics(
					ev.buf,
					vim.tbl_map(function(error)
						return errors.map_to_diagnostic(ev.buf, error)
					end, errs)
				)
			end
		end,
	})
end

---Publish the current errors as diagnostics in the buffers they belong to. Files that are
---not loaded yet get theirs when they are read.
function M._update_diagnostics()
	local by_path = {}
	for linenum, error in pairs(errors.error_list) do
		if error.row then
			local path = error_path(linenum, error)
			by_path[path] = by_path[path] or {}
			table.insert(by_path[path], error)
		end
	end

	pending_diagnostics = {}
	for path, errs in pairs(by_path) do
		local bufnr = utils.find_loaded_buffer(path)
		if bufnr then
			utils.set_diagnostics(
				bufnr,
				vim.tbl_map(function(error)
					return errors.map_to_diagnostic(bufnr, error)
				end, errs)
			)
		else
			pending_diagnostics[path] = errs
		end
	end
	ensure_diagnostics_autocmd()
end

---Push the current errors to quickfix and diagnostics, whichever are enabled.
function M._live_sync()
	local config = require("compile-mode.config.internal")
	if config.live_quickfix then
		M._update_quickfix()
	end
	if config.live_diagnostics then
		M._update_diagnostics()
	end
end

function M._cancel_live_sync()
	if sync_timer and not sync_timer:is_closing() then
		sync_timer:stop()
		sync_timer:close()
	end
	sync_timer = nil
end

---Sync at most once per SYNC_INTERVAL while output streams in; each sync rebuilds the
---whole list, so doing it per flush would be quadratic in the number of errors.
local function request_live_sync()
	local config = require("compile-mode.config.internal")
	if not (config.live_quickfix or config.live_diagnostics) or sync_timer then
		return
	end
	sync_timer = vim.defer_fn(function()
		sync_timer = nil
		M._live_sync()
	end, SYNC_INTERVAL)
end

---Open the compilation window if it is not visible in this tabpage, close it otherwise.
---@param param CommandParam?
function M.toggle_window(param)
	param = param or {}
	local config = require("compile-mode.config.internal")

	local bufnr = vim.g.compilation_buffer
	if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
		vim.notify("No compilation buffer yet; run :Compile first")
		return
	end

	local tab = vim.api.nvim_get_current_tabpage()
	local wins = vim.tbl_filter(function(win)
		return vim.api.nvim_win_get_tabpage(win) == tab
	end, vim.fn.win_findbuf(bufnr))

	if #wins > 0 then
		if #vim.api.nvim_list_wins() == 1 then
			M.close_buffer()
		else
			for _, win in ipairs(wins) do
				vim.api.nvim_win_close(win, true)
			end
		end
		return
	end

	local prev_win = vim.api.nvim_get_current_win()
	local smods, count = utils.apply_window_defaults(param.smods, param.count)
	utils.split_unless_open({ bufnr = bufnr }, smods, count)
	if not config.focus_compilation_buffer then
		vim.api.nvim_set_current_win(prev_win)
	end
end

---Send a line of text to the running compilation's stdin; prompts when none is given.
---@type fun(param: CommandParam?)
M.send_input = a.void(function(param)
	param = param or {}

	local job_id = vim.g.compile_job_id
	if not job_id then
		vim.notify("No compilation running", vim.log.levels.WARN)
		return
	end

	local text = param.args
	if not text or text == "" then
		text = utils.input({ prompt = "Input: " })
	end
	if text == nil then
		return
	end

	vim.fn.chansend(job_id, text .. "\n")
end)

---Close the running compilation's stdin, like CTRL-D in a terminal.
function M.send_eof()
	local config = require("compile-mode.config.internal")

	local job_id = vim.g.compile_job_id
	if not job_id then
		vim.notify("No compilation running", vim.log.levels.WARN)
		return
	end

	if config.use_pseudo_terminal then
		-- a pty has no separate stdin to close; the EOT byte is what CTRL-D sends
		vim.fn.chansend(job_id, "\4")
	else
		vim.fn.chanclose(job_id, "stdin")
	end
end

M._gf = goto_file(false)

M._CTRL_W_f = goto_file(true)

---@type fun(bufnr: integer, start_line: integer, end_line: integer)
M._parse_errors = a.void(function(bufnr, start_line, end_line)
	local config = require("compile-mode.config.internal")

	local output_highlights = {}
	---@type integer[]
	local new_errors = {}

	-- a parse from the top (ftplugin re-parse of another buffer) must not inherit a header
	-- seen in the main buffer
	if start_line == 0 then
		last_header = nil
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line, false)
	for linenum, line in ipairs(lines) do
		linenum = start_line + linenum

		-- very long lines (nvcc and linker command lines) are plain output: every matcher
		-- would cost milliseconds on them and none would match
		local too_long = config.max_line_length and #line > config.max_line_length
		local error = not too_long and errors.parse(line, linenum) or nil

		if error then
			-- location-only lines (rustc's "  --> file:line:col") take the level of the
			-- header line just above them
			local matcher = config.error_regexp_table[error.group]
			if
				matcher
				and matcher.level_from_previous
				and last_header
				and linenum - last_header.linenum <= HEADER_DISTANCE
			then
				error.level = last_header.level
			end

			errors.error_list[linenum] = error
			table.insert(new_errors, linenum)

			if config.auto_jump_to_first_error and not has_auto_jumped then
				has_auto_jumped = true
				local dir = find_directory_for_line(linenum)
				utils.jump_to_error(error, dir, {})
				error_cursor = linenum
			end
		elseif not too_long then
			for _, header in ipairs(config.error_level_headers) do
				if header._rx and header._rx:match_str(line) then
					last_header = { level = header.level, linenum = linenum }
					break
				end
			end

			---@type CompileModeDirectoryMatcher
			local matcher = vim.iter(config.directory_change_matchers):find(function(matcher)
				local s0 = matcher._rx:match_str(line)
				return s0
			end)

			if matcher then
				local matches = vim.fn.matchlist(line, matcher.regex)

				local leaving = matcher.leaving and matches[matcher.leaving + 1] ~= ""
				local dir = matches[matcher.filename + 1]

				if utils.is_absolute(dir) then
					M.dir_changes[linenum] = vim.fn.fnamemodify(dir, ":p:h" .. (leaving and ":h" or ""))
				else
					local latest_dir = find_directory_for_line(linenum)
					if leaving then
						M.dir_changes[linenum] = vim.fn.fnamemodify(latest_dir, ":h")
					else
						M.dir_changes[linenum] = vim.fn.resolve(latest_dir .. "/" .. dir)
					end
				end
			end

			if not (linenum == 1 and vim.startswith(line, "vim:")) then
				local highlights = utils.match_command_ouput(line, linenum)
				for _, value in ipairs(highlights) do
					table.insert(output_highlights, value)
				end
			end
		end
	end

	for _, linenum in ipairs(new_errors) do
		errors.highlight_error(bufnr, errors.error_list[linenum], linenum)
	end
	utils.highlight_command_outputs(bufnr, output_highlights)

	if #new_errors > 0 then
		request_live_sync()
	end

	vim.cmd.redrawstatus()
end)

function M._follow_cursor()
	local compilation_buffer = vim.g.compilation_buffer

	if not in_next_error_mode then
		return
	end

	if vim.api.nvim_get_current_buf() ~= compilation_buffer then
		return
	end

	local cursor_row = unpack(vim.api.nvim_win_get_cursor(0))
	local error = errors.error_list[cursor_row]
	if not error then
		return
	end

	local preview_win
	local win_ids = vim.api.nvim_list_wins()
	if #win_ids == 1 then
		-- If there are no other windows, split a new one for the preview
		preview_win = vim.api.nvim_open_win(vim.api.nvim_create_buf(true, true), false, { split = "below" })
	else
		-- If there is already a window for this file, use it
		preview_win = vim.iter(win_ids):find(function(win_id)
			local fbuf = vim.fn.bufadd(error.filename.value)
			local winbuf = vim.api.nvim_win_get_buf(win_id)
			return fbuf == winbuf
		end)
	end
	-- If we still don't have a preview window,
	-- use the first existing window that isn't the first compilation window
	if not preview_win then
		local past_first_window = false
		preview_win = vim.iter(win_ids):find(function(win_id)
			if past_first_window then
				return true
			end

			local winbuf = vim.api.nvim_win_get_buf(win_id)
			if winbuf ~= compilation_buffer then
				return true
			end

			past_first_window = true
			return false
		end)
	end

	vim.schedule(function()
		local dir = find_directory_for_line(cursor_row)
		vim.api.nvim_win_call(preview_win, function()
			utils.jump_to_error(error, dir, {})
		end)
		vim.notify("Current locus from " .. vim.fn.bufname(compilation_buffer))
	end)
end

return M
