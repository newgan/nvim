local a = require("plenary.async")

local M = {}

local compile_mode_ns = vim.api.nvim_create_namespace("compile-mode.nvim")

local highlight_ns = vim.api.nvim_create_namespace("compile-mode.nvim/highlight")
---@type table | nil
local highlight_timer
---@type fun() | nil
local highlight_cancel = nil

---@param error CompileModeError
local function highlight_locus_jump(bufnr, error)
	local config = require("compile-mode.config.internal")

	if highlight_timer then
		highlight_timer:close()
		assert(highlight_cancel)
		highlight_cancel()
	end

	if not config.error_locus_highlight then
		return
	end

	-- the error may point past the end of a file that has since shrunk; jump_to_file
	-- clamps the cursor, so clamp the highlight the same way instead of erroring
	local last_row = vim.api.nvim_buf_line_count(bufnr) - 1
	local start = {
		math.min(error.row and error.row.value - 1 or 0, last_row),
		error.col and error.col.value or 1,
	}
	local line = vim.api.nvim_buf_get_lines(bufnr, start[1], start[1] + 1, false)[1] or ""
	local end_ = {
		math.min(error.end_row and error.end_row.value - 1 or start[1], last_row),
		error.end_col and error.end_col.value or line:len(),
	}

	vim.highlight.range(bufnr, highlight_ns, "CompileModeErrorLocus", start, end_, {
		inclusive = true,
		priority = vim.highlight.priorities.diagnostics,
		regtype = "v",
	})

	local timeout = config.error_locus_highlight
	if type(timeout) == "number" then
		highlight_cancel = function()
			highlight_timer = nil
			highlight_cancel = nil
			pcall(vim.api.nvim_buf_clear_namespace, bufnr, highlight_ns, 0, -1)
		end

		highlight_timer = vim.defer_fn(highlight_cancel, timeout)
	end
end

---@param bufnr integer
---@param hlname string
---@param linenum integer
---@param range CompileModeRange
function M.add_highlight(bufnr, hlname, linenum, range)
	vim.api.nvim_buf_set_extmark(
		bufnr,
		compile_mode_ns,
		linenum - 1,
		range.start - 1,
		{ end_col = range.end_, hl_group = hlname }
	)
end

---@param bufnr integer
function M.clear_highlights(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, compile_mode_ns, 0, -1)
end

---Find the `\(` of the `group`-th capturing group in a magic-mode Vim pattern and the
---end of that group including any multi (`*`, `\+`, `\?`, `\=`, `\{..}`, `\@..`)
---that follows its `\)`. Non-capturing `\%(` groups and `[...]` collections are
---skipped. Returns nil when the pattern cannot be walked.
---@param pattern string
---@param group integer
---@return integer|nil open byte index of the `\` in `\(`
---@return integer|nil after byte index just past the group and its multi
local function find_group(pattern, group)
	local i, n = 1, #pattern
	local stack = {} ---@type boolean[] true when the open paren is the wanted group
	local count = 0
	local open_at = nil
	while i <= n do
		local c = pattern:sub(i, i)
		if c == "\\" then
			local nxt = pattern:sub(i + 1, i + 1)
			if nxt == "(" then
				count = count + 1
				table.insert(stack, count == group)
				if count == group then
					open_at = i
				end
				i = i + 2
			elseif (nxt == "%" or nxt == "z") and pattern:sub(i + 2, i + 2) == "(" then
				table.insert(stack, false)
				i = i + 3
			elseif nxt == ")" then
				local wanted = table.remove(stack)
				if wanted == nil then
					return nil
				end
				i = i + 2
				if wanted then
					local rest = pattern:sub(i)
					local multi = rest:match("^\\[+?=]")
						or rest:match("^%*")
						or rest:match("^\\{[^}]*}")
						or rest:match("^\\@%d*<?[=!>]")
					return open_at, i + (multi and #multi or 0)
				end
			else
				i = i + 2
			end
		elseif c == "[" then
			-- collection: find the closing `]`; a `]` right after `[` or `[^` is literal,
			-- and `\]` inside is escaped. An unterminated `[` is a literal `[`.
			local j = i + 1
			if pattern:sub(j, j) == "^" then
				j = j + 1
			end
			if pattern:sub(j, j) == "]" then
				j = j + 1
			end
			while j <= n and pattern:sub(j, j) ~= "]" do
				j = j + (pattern:sub(j, j) == "\\" and 2 or 1)
			end
			i = j <= n and j + 1 or i + 1
		else
			i = i + 1
		end
	end
	return nil
end

---Cache of per-group regexes: pattern -> group -> vim.regex|false
---@type table<string, table<integer, vim.regex|false>>
local group_rx_cache = {}

---Exact position of a capture group, found by re-matching the pattern with `\zs` and
---`\ze` wrapped around that group. Returns nil when that is not possible or when the
---result does not reproduce the captured text (e.g. a group inside a repetition).
---@param pattern string
---@param group integer
---@param input string
---@param capture string
---@return CompileModeRange|nil
local function group_range(pattern, group, input, capture)
	local cache = group_rx_cache[pattern]
	if not cache then
		cache = {}
		group_rx_cache[pattern] = cache
	end
	local rx = cache[group]
	if rx == nil then
		rx = false
		local open, after = find_group(pattern, group)
		if open then
			local wrapped = pattern:sub(1, open - 1)
				.. "\\zs"
				.. pattern:sub(open, after - 1)
				.. "\\ze"
				.. pattern:sub(after)
			local ok, compiled = pcall(vim.regex, wrapped)
			if ok then
				rx = compiled
			end
		end
		cache[group] = rx
	end
	if not rx then
		return nil
	end
	local s, e = rx:match_str(input)
	if not s or input:sub(s + 1, e) ~= capture then
		return nil
	end
	return { start = s + 1, end_ = e }
end

---@param input string
---@param pattern string
---@param compiled_rx vim.regex|nil
---@return (CompileModeRange|nil)[]
function M.matchlistpos(input, pattern, compiled_rx)
	local result = {} ---@type (CompileModeIntByInt|nil)[]
	local rx = compiled_rx or vim.regex(pattern)
	local s0, e0 = rx:match_str(input)
	if not s0 then
		return result
	end

	local list = vim.fn.matchlist(input, pattern) --[[@as string[] ]]
	if not list or #list == 0 then
		return result
	end

	-- the whole match is known exactly
	local seg_start = s0 + 1
	result[1] = { start = seg_start, end_ = e0 }
	local seg = string.sub(input, seg_start, e0)

	-- groups: exact positions via `\zs`/`\ze` when possible; otherwise fall back to
	-- locating the captured text, searching forward from the previous group
	local cursor = 1
	for i = 2, #list do
		local capture = list[i]
		if capture ~= "" then
			local range = group_range(pattern, i - 1, input, capture)
			if not range then
				local s, e = string.find(seg, capture, cursor, true)
				if not s then
					s, e = string.find(seg, capture, 1, true)
				end
				if s and e then
					range = { start = seg_start + s - 1, end_ = seg_start + e - 1 }
				end
			end
			if range then
				result[i] = range
				cursor = range.end_ - seg_start + 2
			end
		end
	end

	return result
end

---Fill in the configured `window` defaults for the compilation window where the command
---gave no modifier or count of its own.
---@param smods SMods|nil
---@param count integer|nil
---@return SMods smods
---@return integer|nil count
function M.apply_window_defaults(smods, count)
	local window = require("compile-mode.config.internal").window
	smods = vim.deepcopy(smods or {})
	if (smods.split or "") == "" then
		smods.split = window.split
	end
	if not smods.vertical then
		smods.vertical = window.vertical
	end
	-- the configured size is lines for a horizontal window and columns for a vertical
	-- one, so it only makes sense when the orientation is the configured one
	if (not count or count == 0) and (smods.vertical or false) == (window.vertical or false) then
		count = window.size
	end
	if count == 0 then
		count = nil
	end
	return smods, count
end

---The loaded buffer whose name is exactly `path` (normalised), if any. Unlike
---|bufnr()|, this never falls back to pattern matching.
---@param path string
---@return integer|nil
function M.find_loaded_buffer(path)
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) and vim.fs.normalize(vim.api.nvim_buf_get_name(bufnr)) == path then
			return bufnr
		end
	end
	return nil
end

---@param bufnr integer
---@param diagnostics vim.Diagnostic[]
function M.set_diagnostics(bufnr, diagnostics)
	vim.diagnostic.set(compile_mode_ns, bufnr, diagnostics, {})
end

---Windows showing `bufnr` whose cursor sits on its last line: the ones that should keep
---following output as it is appended. Windows scrolled up to read earlier output are
---left alone, as Emacs does.
---@param bufnr integer
---@return integer[] win_ids
function M.windows_at_end(bufnr)
	local last = vim.api.nvim_buf_line_count(bufnr)
	local wins = {}
	for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_get_cursor(win)[1] >= last then
			table.insert(wins, win)
		end
	end
	return wins
end

---Move the given windows to the last line of `bufnr`.
---@param bufnr integer
---@param win_ids integer[]
function M.scroll_to_end(bufnr, win_ids)
	local last = vim.api.nvim_buf_line_count(bufnr)
	for _, win in ipairs(win_ids) do
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_set_cursor(win, { last, 0 })
		end
	end
end

---@type fun(opts: table): string
M.input = a.wrap(vim.ui.input, 2)

---@type fun()
M.wait = a.wrap(vim.schedule, 1)

---@type fun(ms: number)
M.delay = a.wrap(function(timeout, callback)
	vim.defer_fn(callback, timeout)
end, 2)

---@param bufnr integer
---@param opt string
---@param value any
function M.buf_set_opt(bufnr, opt, value)
	vim.api.nvim_set_option_value(opt, value, { buf = bufnr })
end

---If `fname` has a window open, do nothing.
---Otherwise, split a new window (and possibly buffer) open for that file, respecting split mods.
---
---@param opts { fname: string } | { bufnr: integer }
---@param smods SMods
---@param count integer
---@return integer bufnr the identifier of the buffer for `fname`
function M.split_unless_open(opts, smods, count)
	local bufnr
	if opts.bufnr then
		bufnr = opts.bufnr
	else
		bufnr = vim.fn.bufadd(opts.fname)
	end

	if smods.hide then
		return bufnr
	end

	local current_tab_id = vim.api.nvim_get_current_tabpage()
	local window_open = vim.iter(vim.fn.win_findbuf(bufnr))
		:filter(function(win_id)
			local tab_id = vim.api.nvim_win_get_tabpage(win_id)
			return tab_id == current_tab_id
		end)
		:any(function()
			return true
		end)

	if not window_open then
		vim.cmd({ cmd = "sbuffer", args = { bufnr }, mods = smods })

		if count ~= 0 and count ~= nil then
			vim.cmd({ cmd = "resize", args = { count }, mods = smods })
		end
	end

	return bufnr
end

---@param filename string
---@param error CompileModeError
---@param smods SMods
local function jump_to_file(filename, error, smods)
	local config = require("compile-mode.config.internal")

	local compilation_buffer = vim.g.compilation_buffer
	if config.use_diagnostics then
		compilation_buffer = compilation_buffer or vim.fn.bufadd(config.buffer_name)
		local win_ids = vim.fn.win_findbuf(compilation_buffer)

		if #vim.api.nvim_list_wins() > 1 then
			vim.iter(win_ids):each(function(win_id)
				vim.api.nvim_win_close(win_id, true)
			end)
		end
	else
		local wsmods, wcount = M.apply_window_defaults(smods, 0)
		compilation_buffer =
			M.split_unless_open({ bufnr = compilation_buffer, fname = config.buffer_name }, wsmods, wcount)
		local compilation_win_id = vim.fn.win_findbuf(compilation_buffer)[1]

		vim.api.nvim_win_set_cursor(compilation_win_id, { error.linenum, 0 })
	end

	local row = error.row and error.row.value or 1

	local col = (error.col and error.col.value or 1) - 1
	if col < 0 then
		col = 0
	end

	local target_bufnr = vim.fn.bufadd(filename)
	local current_bufnr = vim.api.nvim_get_current_buf()

	if current_bufnr ~= target_bufnr then
		if current_bufnr ~= compilation_buffer then
			vim.api.nvim_set_current_buf(target_bufnr)
		else
			local current_tab_id = vim.api.nvim_get_current_tabpage()
			local buf_win_id = vim.iter(vim.fn.win_findbuf(target_bufnr)):find(function(win_id)
				local tab_id = vim.api.nvim_win_get_tabpage(win_id)
				return tab_id == current_tab_id
			end)

			if not buf_win_id and #vim.api.nvim_tabpage_list_wins(current_tab_id) > 1 then
				buf_win_id = vim.fn.win_getid(vim.fn.winnr("#"))
			end

			if buf_win_id then
				vim.api.nvim_win_set_buf(buf_win_id, target_bufnr)
				vim.api.nvim_set_current_win(buf_win_id)
			else
				M.split_unless_open({ bufnr = target_bufnr }, smods, 0)
			end
		end
	end

	local target_win_id = vim.fn.win_findbuf(target_bufnr)[1]

	local last_row = vim.api.nvim_buf_line_count(target_bufnr)
	if row > last_row then
		row = last_row
	end
	vim.api.nvim_win_set_cursor(target_win_id, { row, col })
	highlight_locus_jump(target_bufnr, error)

	if config.use_diagnostics then
		local errors = require("compile-mode.errors")
		local diagnostics = errors.todiagnostic(target_bufnr, errors.error_list)
		vim.diagnostic.set(compile_mode_ns, target_bufnr, diagnostics, {})
		M.delay(100)
		vim.diagnostic.open_float()
	end
end

function M.clear_diagnostics()
	vim.diagnostic.reset(compile_mode_ns)
end

--- @type string|nil
local last_corrected_dir = nil

---@type fun(error: CompileModeError, current_dir: string, smods: SMods)
M.jump_to_error = a.void(function(error, current_dir, smods)
	current_dir = string.gsub(current_dir or "", "/$", "")

	local filename = error.filename.value
	if not M.is_absolute(filename) then
		filename = current_dir .. "/" .. filename
	end

	local file_exists = vim.fn.filereadable(filename) ~= 0
	if not file_exists and last_corrected_dir ~= nil then
		local maybe_filename = vim.fs.normalize(last_corrected_dir .. "/" .. error.filename.value)

		if vim.fn.filereadable(maybe_filename) ~= 0 then
			jump_to_file(maybe_filename, error, smods)

			return
		else
			last_corrected_dir = nil
		end
	end

	if file_exists then
		jump_to_file(filename, error, smods)
		return
	end

	local dir = M.input({
		prompt = "Find this error in: ",
		completion = "file",
	})
	if not dir then
		return
	end
	dir = string.gsub(dir, "/$", "")

	M.wait()

	if vim.fn.isdirectory(dir) == 0 then
		if vim.fn.filereadable(dir) == 0 then
			vim.notify(dir .. " is not readable", vim.log.levels.ERROR)
			return
		end

		jump_to_file(dir, error, smods)
		return
	end

	local nested_filename = vim.fs.normalize(dir .. "/" .. error.filename.value)
	if vim.fn.filereadable(nested_filename) == 0 then
		vim.notify(error.filename.value .. " does not exist in " .. dir, vim.log.levels.ERROR)
		return
	end

	last_corrected_dir = dir
	jump_to_file(nested_filename, error, smods)
end)

function M.match_command_ouput(line, linenum)
	local highlights = {}

	local result = M.matchlistpos(line, "^\\([[:alnum:]_/.+-]\\+\\)\\%(\\[\\([0-9]\\+\\)\\]\\)\\?[ \t]*:")
	if result then
		local entire = result[1]
		if entire then
			table.insert(highlights, { "CompileModeCommandOutput", linenum, entire })
		end

		local num = result[3]
		if num then
			table.insert(highlights, { "CompileModeMessageRow", linenum, num })
		end
	end

	return highlights
end

function M.highlight_command_outputs(bufnr, command_output_highlights)
	for _, highlight in ipairs(command_output_highlights) do
		M.add_highlight(bufnr, unpack(highlight))
	end
end

---Ask user whether to save each modified buffer, and save them as requested.
---@param smods SMods
---@return boolean quit whether to quit or not
function M.ask_to_save(smods)
	local buffers = vim.api.nvim_list_bufs()
	local buffers_with_changes = vim.tbl_filter(function(bufnr)
		return vim.api.nvim_buf_is_loaded(bufnr)
			and vim.api.nvim_get_option_value("buflisted", { buf = bufnr })
			and vim.api.nvim_get_option_value("modified", { buf = bufnr })
	end, buffers)

	for _, bufnr in ipairs(buffers_with_changes) do
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		local result = vim.fn.confirm("Save changes to " .. bufname .. "?", "&Yes\n&No\nSkip &All\n&Quit")

		if result == 1 then
			vim.cmd(tostring(bufnr) .. "bufdo w")
		end

		if result == 3 then
			break
		end

		if result == 4 and not smods.silent then
			vim.notify("Quit")
			return true
		end
	end

	return false
end

function M.is_windows()
	return vim.uv.os_uname().sysname == "Windows_NT"
end

---@param path string
---@return boolean is_absolute whether `path` is absolute or relative.
function M.is_absolute(path)
	if vim.fn.has("nvim-0.11.0") == 1 then
		return vim.fn.isabsolutepath(path) ~= 0
	end

	if M.is_windows() then
		return path:match("^%a:[/\\]") or path:match("^//") or path:match("^\\\\")
	else
		local first = path:sub(1, 1)
		return first == "/" or first == "~"
	end
end

return M
