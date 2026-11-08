local compile_mode = require("compile-mode")
local check = require("compile-mode.config.check")
local log = require("compile-mode.log")

---@class CompileModeConfig
local default_config = {
	---@type string
	default_command = "make -k ",
	---@type CompileModeAnsiColor
	ansi_color = { kind = "filter", baleia_options = {} },
	---@type boolean|table
	baleia_setup = false,
	---@type boolean
	bang_expansion = false,
	---@type CompileModeDirectoryMatcher[]
	directory_change_matchers = {},
	---@type table<string, CompileModeRegexpMatcher>
	error_regexp_table = {},
	---@type string[]
	error_ignore_file_list = {},
	---@type CompileModeLevel
	error_threshold = compile_mode.level.WARNING,
	---@type boolean
	auto_jump_to_first_error = false,
	---@type boolean|number|nil
	error_locus_highlight = 500,
	---@type boolean
	use_diagnostics = false,
	---@type boolean
	recompile_no_fail = false,
	---@type boolean
	ask_about_save = true,
	---@type boolean
	ask_to_interrupt = true,
	---@type string
	buffer_name = "*compilation*",
	---@type string
	time_format = "%a %b %e %H:%M:%S",
	---@type integer|nil
	max_lines = nil,
	---@type integer|false
	max_line_length = 4000,
	---@type string[]
	hidden_output = {},
	---@type table<string, string>|nil
	environment = nil,
	---@type boolean
	clear_environment = false,
	---@type boolean
	debug = false,
	---@type boolean
	input_word_completion = false,
	--- @type boolean
	hidden_buffer = false,
	--- @type boolean
	focus_compilation_buffer = false,
	--- @type boolean
	auto_scroll = true,
	---@type boolean
	use_circular_error_navigation = false,
	---@type boolean
	use_pseudo_terminal = false,
	---@type CompileModeLevelHeader[]
	error_level_headers = {},
	---@type boolean
	live_quickfix = false,
	---@type boolean
	live_diagnostics = false,
	---@type number
	flush_interval = 30,
	---@type CompileModeWindow
	window = { split = "", vertical = false, size = nil },
	---@type boolean
	remember_commands = false,
	---@type string
	history_file = vim.fs.joinpath(vim.fn.stdpath("state"), "compile-mode", "history.json"),
	---@type CompileModeAnsiOsc
	ansi_osc = {
		kind = "render",
		handlers = {},
	},
}

local user_config = type(vim.g.compile_mode) == "function" and vim.g.compile_mode() or vim.g.compile_mode

local health_info = {
	health_info = {
		unrecognized_keys = check.unrecognized_keys(user_config or {}, default_config),
		no_user_config = user_config == nil,
	},
}

local config = vim.tbl_extend("force", health_info, default_config, user_config or {})

-- Deprecation: top-level baleia_setup overrides ansi_color entirely
if config.baleia_setup ~= nil and config.baleia_setup ~= false then
	if config.baleia_setup == true then
		log.warn(
			[['baleia_setup' at top level is deprecated;]]
				.. [[ use 'ansi_color = { kind = "render" }' instead.]]
				.. [[ It will be removed in v6.]]
		)
	else
		log.warn(
			[['baleia_setup' at top level is deprecated;]]
				.. [[ use 'ansi_color = { kind = "render", baleia_options = ]]
				.. vim.inspect(config.baleia_setup, { newline = "" })
				.. [[ }' instead.]]
				.. [[ It will be removed in v6.]]
		)
	end
	config.ansi_color = {
		kind = "render",
		baleia_options = config.baleia_setup == true and {} or config.baleia_setup,
	}
end
config.error_regexp_table =
	vim.tbl_extend("force", require("compile-mode.errors").error_regexp_table, config.error_regexp_table)
config.directory_change_matchers = vim.list_extend({
	{ regex = [[\<cd \zs\(\S\+\)\ze]], filename = 1 },
	{ regex = [[\%(Entering\|Leavin\(g\)\) directory [`']\zs\(.\+\)\ze'$]], filename = 2, leaving = 1 },
}, config.directory_change_matchers)
config.error_ignore_file_list = vim.list_extend({ "/bin/[a-z]*sh$" }, config.error_ignore_file_list)
-- headers give a level to the location-only lines that follow them (`level_from_previous`
-- matchers, e.g. rustc's "  --> file:line:col"); user entries go first so they win
config.error_level_headers = vim.list_extend(vim.deepcopy((user_config or {}).error_level_headers or {}), {
	{ regex = [[^error\%(\[\|:\)]], level = compile_mode.level.ERROR },
	{ regex = [[^warning\%(\[\|:\)]], level = compile_mode.level.WARNING },
	{ regex = [[^\%(note\|help\):]], level = compile_mode.level.INFO },
})
config.window = vim.tbl_extend("force", default_config.window, config.window or {})
config.hidden_output = type(config.hidden_output) == "string" and { config.hidden_output } or config.hidden_output

local errors = check.get_errors(config)
if #errors > 0 then
	log.error("invalid config: " .. vim.iter(errors):join("; "))
end

if #config.health_info.unrecognized_keys > 0 then
	log.fmt_warn("found unrecognized options: %s", config.health_info.unrecognized_keys)
end

if config.health_info.no_user_config then
	log.warn("no configuration found; did you forget to set the `vim.g.compile_mode` table?")
end

---@cast config CompileModeConfig

--- Modify the log level based off the parsed config
log.new({ level = config.debug and "debug" or "info" }, true)

return config
