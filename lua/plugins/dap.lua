local dap = require("dap")
local dapui = require("dapui")

local native
if vim.fn.executable("codelldb") == 1 then
    dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = { command = "codelldb", args = { "--port", "${port}" } },
    }
    native = "codelldb"
elseif vim.fn.executable("lldb-dap") == 1 then
    dap.adapters.lldb = { type = "executable", command = "lldb-dap" }
    native = "lldb"
else
    dap.adapters.gdb = {
        type = "executable",
        command = "gdb",
        args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
    }
    native = "gdb"
end

local function pick_executable(default_dir)
    return function()
        return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/" .. default_dir, "file")
    end
end

dap.configurations.c = {
    {
        name = "Launch",
        type = native,
        request = "launch",
        program = pick_executable(""),
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}
dap.configurations.cpp = dap.configurations.c
dap.configurations.rust = {
    {
        name = "Launch",
        type = native,
        request = "launch",
        program = pick_executable("target/debug/"),
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
    },
}

local dlv = vim.fn.exepath("dlv")
if dlv == "" then
    dlv = vim.fn.expand("~/go/bin/dlv")
end
dap.adapters.delve = {
    type = "server",
    port = "${port}",
    executable = { command = dlv, args = { "dap", "-l", "127.0.0.1:${port}" } },
}
dap.configurations.go = {
    { type = "delve", name = "Debug file", request = "launch", program = "${file}" },
    { type = "delve", name = "Debug package", request = "launch", program = "${fileDirname}" },
    { type = "delve", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
    { type = "delve", name = "Debug test (package)", request = "launch", mode = "test", program = "./${relativeFileDirname}" },
}

dap.adapters.python = { type = "executable", command = "debugpy-adapter" }
local function python_path()
    local venv = os.getenv("VIRTUAL_ENV")
    if venv then
        return venv .. "/bin/python"
    end
    if vim.fn.executable(vim.fn.getcwd() .. "/.venv/bin/python") == 1 then
        return vim.fn.getcwd() .. "/.venv/bin/python"
    end
    return "python3"
end
dap.configurations.python = {
    {
        type = "python",
        request = "launch",
        name = "Launch file",
        program = "${file}",
        console = "integratedTerminal",
        pythonPath = python_path,
    },
}

dapui.setup()
dap.listeners.before.attach.dapui_config = function() dapui.open() end
dap.listeners.before.launch.dapui_config = function() dapui.open() end
dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
vim.fn.sign_define("DapLogPoint", { text = "◇", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticWarn", linehl = "CursorLine" })

local map = vim.keymap.set
map("n", "<F5>", dap.continue, { desc = "debug: continue / start" })
map("n", "<F9>", dap.toggle_breakpoint, { desc = "debug: toggle breakpoint" })
map("n", "<F10>", dap.step_over, { desc = "debug: step over" })
map("n", "<F11>", dap.step_into, { desc = "debug: step into" })
map("n", "<S-F11>", dap.step_out, { desc = "debug: step out" })

map("n", "<leader>dc", dap.continue, { desc = "continue / start" })
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "toggle breakpoint" })
map("n", "<leader>dB", function()
    dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "conditional breakpoint" })
map("n", "<leader>do", dap.step_over, { desc = "step over" })
map("n", "<leader>di", dap.step_into, { desc = "step into" })
map("n", "<leader>dO", dap.step_out, { desc = "step out" })
map("n", "<leader>dC", dap.run_to_cursor, { desc = "run to cursor" })
map("n", "<leader>dl", dap.run_last, { desc = "run last" })
map("n", "<leader>dt", dap.terminate, { desc = "terminate" })
map("n", "<leader>dr", dap.repl.toggle, { desc = "toggle repl" })
map("n", "<leader>du", dapui.toggle, { desc = "toggle debug ui" })
map({ "n", "x" }, "<leader>de", dapui.eval, { desc = "evaluate expression" })
