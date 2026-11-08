-- Specs for the local changes listed under "Local changes" in CHANGELOG.md.
local helpers = require("spec.test_helpers")
local compile_mode = require("compile-mode")
local errors = require("compile-mode.errors")
local assert = require("luassert")

local rustc = {
	regex = [[^\s*-->\s\+\(\S\+\):\([0-9]\+\):\([0-9]\+\)]],
	filename = 1,
	row = 2,
	col = 3,
	priority = 2,
	level_from_previous = true,
}

---Run `lines` through a script file, so the command line itself (which is parsed too)
---cannot match an error pattern.
---@param lines string[]
---@return string command
local function script_printing(lines)
	local path = vim.fn.tempname() .. ".sh"
	local script = { "#!/bin/sh" }
	for _, line in ipairs(lines) do
		table.insert(script, ("printf '%%s\\n' '%s'"):format(line))
	end
	vim.fn.writefile(script, path)
	return "sh " .. path
end

---@param filename string
local function level_of(filename)
	for _, error in pairs(errors.error_list) do
		if error.filename.value == filename then
			return error.level
		end
	end
	return nil
end

describe("level_from_previous", function()
	before_each(function()
		helpers.setup_tests({ error_regexp_table = { rustc = rustc } })
	end)

	it("takes the level of the header line above a location-only line", function()
		helpers.compile({
			args = "printf 'warning: w\\n  --> a.rs:1:1\\nerror[E1]: e\\n  --> b.rs:2:2\\nnote: n\\n  --> c.rs:3:3\\n'",
		})
		assert.are.same(compile_mode.level.WARNING, level_of("a.rs"))
		assert.are.same(compile_mode.level.ERROR, level_of("b.rs"))
		assert.are.same(compile_mode.level.INFO, level_of("c.rs"))
	end)
end)

describe("live_quickfix", function()
	before_each(function()
		helpers.setup_tests({ live_quickfix = true })
	end)

	it("keeps a Compilation quickfix list with typed entries", function()
		helpers.compile({ args = script_printing({ "x.c:3:4: error: boom", "y.c:5:1: warning: meh" }) })
		local list = vim.fn.getqflist({ title = 1, items = 1 })
		assert.are.same("Compilation", list.title)
		assert.are.same(2, #list.items)
		assert.are.same("E", list.items[1].type)
		assert.are.same(3, list.items[1].lnum)
		assert.are.same("W", list.items[2].type)
	end)
end)

describe("flush_interval", function()
	before_each(helpers.setup_tests)

	it("writes a burst of output completely and in order", function()
		helpers.compile({ args = "sh -c 'i=1; while [ $i -le 200 ]; do echo l$i; i=$((i+1)); done'" })
		local output = helpers.get_output()
		assert.are.same("l1", output[2])
		assert.are.same("l200", output[201])
	end)
end)

describe(":CompileToggle", function()
	before_each(helpers.setup_tests)

	it("closes and reopens the compilation window", function()
		helpers.compile({ args = "echo hi" })
		local bufnr = helpers.get_compilation_bufnr()
		assert.are.same(1, #vim.fn.win_findbuf(bufnr))
		compile_mode.toggle_window({})
		assert.are.same(0, #vim.fn.win_findbuf(bufnr))
		compile_mode.toggle_window({})
		assert.are.same(1, #vim.fn.win_findbuf(bufnr))
	end)
end)

describe(":CompileInput", function()
	before_each(helpers.setup_tests)

	it("sends a line to the running process", function()
		helpers.compile({ args = "sh -c 'read x; echo got:$x'" }, true)
		helpers.wait_ms(300)
		compile_mode.send_input({ args = "hello" })
		helpers.wait_for_compilation()
		assert.are.same("got:hello", helpers.get_output()[2])
	end)
end)

describe("events", function()
	before_each(helpers.setup_tests)

	it("fire CompilationStarted and enrich CompilationFinished", function()
		local started, finished
		vim.api.nvim_create_autocmd("User", {
			once = true,
			pattern = "CompilationStarted",
			callback = function(ev)
				started = ev.data
			end,
		})
		vim.api.nvim_create_autocmd("User", {
			once = true,
			pattern = "CompilationFinished",
			callback = function(ev)
				finished = ev.data
			end,
		})
		local command = script_printing({ "x.c:3:4: error: boom" })
		helpers.compile({ args = command })
		assert.are.same(command, started.command)
		assert.are.same("number", type(started.job_id))
		assert.are.same(vim.fn.getcwd(), started.directory)
		assert.are.same("number", type(finished.elapsed))
		assert.are.same(vim.fn.getcwd(), finished.directory)
		assert.are.same({ error = 1, warning = 0, info = 0 }, finished.counts)
	end)
end)

describe("remember_commands", function()
	local history_file

	before_each(function()
		history_file = vim.fn.tempname()
		helpers.setup_tests({ remember_commands = true, history_file = history_file })
	end)

	after_each(function()
		vim.fn.delete(history_file)
	end)

	it("reruns the directory's own last command on :Recompile", function()
		local here = vim.fn.getcwd()
		helpers.compile({ args = "echo here" })
		helpers.change_vim_directory("..")
		helpers.compile({ args = "echo parent" })
		helpers.change_vim_directory(here)
		helpers.recompile()
		assert.are.same({ "echo here", "here" }, helpers.get_output())
	end)
end)

describe("window defaults", function()
	before_each(function()
		helpers.setup_tests({ window = { split = "botright", size = 15 } })
	end)

	it("apply the size only when the orientation matches", function()
		local utils = require("compile-mode.utils")
		local _, horizontal = utils.apply_window_defaults({ split = "", vertical = false }, 0)
		local _, vertical = utils.apply_window_defaults({ split = "", vertical = true }, 0)
		assert.are.same(15, horizontal)
		assert.is_nil(vertical)
	end)
end)

describe("remember_commands with an explicit vim.g.compile_command", function()
	local history_file

	before_each(function()
		history_file = vim.fn.tempname()
		helpers.setup_tests({ remember_commands = true, history_file = history_file })
	end)

	after_each(function()
		vim.fn.delete(history_file)
		vim.g.compile_command = nil
	end)

	it("lets the explicit command win on :Recompile", function()
		helpers.compile({ args = "echo remembered" })
		vim.g.compile_command = "echo explicit"
		helpers.recompile()
		assert.are.same({ "echo explicit", "explicit" }, helpers.get_output())
	end)
end)

describe("live_quickfix after :QuickfixErrors", function()
	before_each(function()
		helpers.setup_tests({ live_quickfix = true })
	end)

	it("keeps updating the same list instead of pushing another", function()
		helpers.compile({ args = script_printing({ "x.c:3:4: error: boom" }) })
		local stack = vim.fn.getqflist({ nr = "$" }).nr
		compile_mode.send_to_qflist() -- retitles the list, as :QuickfixErrors does
		helpers.wait_ms(50)
		helpers.compile({ args = script_printing({ "x.c:3:4: error: boom", "y.c:1:1: error: again" }) })
		assert.are.same(stack + 1, vim.fn.getqflist({ nr = "$" }).nr)
		assert.are.same(2, #vim.fn.getqflist({ items = 1 }).items)
	end)
end)

describe("max_line_length", function()
	before_each(function()
		helpers.setup_tests({ max_line_length = 100 })
	end)

	it("does not parse errors on lines longer than the limit", function()
		local long = "x.c:3:4: error: " .. string.rep("a", 200)
		helpers.compile({ args = script_printing({ long, "y.c:5:1: error: short" }) })
		assert.is_nil(level_of("x.c"))
		assert.are.same(compile_mode.level.ERROR, level_of("y.c"))
	end)
end)

describe("error_regexp_table entries set to false", function()
	before_each(function()
		helpers.setup_tests({ error_regexp_table = { gnu = false } })
	end)

	it("are skipped without breaking the other matchers", function()
		helpers.compile({
			args = script_printing({ "x.c:3:4: error: boom", "CMake Error at CMakeLists.txt:12 (add_executable):" }),
		})
		assert.is_nil(level_of("x.c"))
		assert.are.same(compile_mode.level.ERROR, level_of("CMakeLists.txt"))
	end)
end)

describe("jumping to an error past the end of the file", function()
	before_each(helpers.setup_tests)

	it("clamps the cursor and highlight instead of erroring", function()
		local file = vim.fn.tempname() .. ".c"
		vim.fn.writefile({ "int main(void) { return 0; }" }, file)
		helpers.compile({ args = script_printing({ file .. ":999:1: error: stale" }) })
		compile_mode.first_error({ smods = { silent = true } })
		helpers.wait_ms(100)
		assert.are.same(file, vim.api.nvim_buf_get_name(0))
		assert.are.same(1, vim.api.nvim_win_get_cursor(0)[1])
		vim.fn.delete(file)
	end)
end)
