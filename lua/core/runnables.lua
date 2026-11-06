local M = {}

local function quote(word)
    if word:find("[%s'\"$`\\]") then
        return vim.fn.shellescape(word)
    end
    return word
end

local function cargo_words(args, extra)
    local words = { args.overrideCargo or "cargo" }
    vim.list_extend(words, args.cargoArgs or {})
    vim.list_extend(words, args.cargoExtraArgs or {})
    vim.list_extend(words, extra or {})
    return words
end

local function shell_line(words, executable_args, environment)
    words = vim.deepcopy(words)
    if environment and next(environment) then
        local assigns = { "env" }
        for k, v in vim.spairs(environment) do
            table.insert(assigns, k .. "=" .. v)
        end
        words = vim.list_extend(assigns, words)
    end
    if executable_args and #executable_args > 0 then
        table.insert(words, "--")
        vim.list_extend(words, executable_args)
    end
    return table.concat(vim.tbl_map(quote, words), " ")
end

local function compile(cwd, line)
    vim.g.compilation_directory = cwd
    require("compile-mode").compile({ args = line })
end

function M.run(runnable)
    local args = runnable.args
    compile(args.cwd or args.workspaceRoot, shell_line(cargo_words(args), args.executableArgs, args.environment))
end

local function build_words(args)
    local words = cargo_words(args)
    if words[2] == "test" or words[2] == "bench" then
        table.insert(words, "--no-run")
    elseif words[2] == "run" then
        words[2] = "build"
    end
    return words
end

local function executable_from(json_lines)
    local exe
    for line in json_lines:gmatch("[^\n]+") do
        local ok, msg = pcall(vim.json.decode, line)
        if ok and type(msg) == "table" and msg.reason == "compiler-artifact"
            and msg.executable and msg.executable ~= vim.NIL
            and not vim.tbl_contains((msg.target or {}).kind or {}, "custom-build") then
            exe = msg.executable
        end
    end
    return exe
end

function M.debug(runnable)
    local args = runnable.args
    local cwd = args.cwd or args.workspaceRoot
    local words = build_words(args)
    vim.notify("building " .. runnable.label)
    vim.system(vim.list_extend(vim.deepcopy(words), { "--message-format=json" }), { cwd = cwd, env = args.environment, text = true },
        function(out)
            vim.schedule(function()
                if out.code ~= 0 then
                    return compile(cwd, shell_line(words, nil, args.environment))
                end
                local exe = executable_from(out.stdout or "")
                if not exe then
                    return vim.notify("no executable produced for " .. runnable.label, vim.log.levels.ERROR)
                end
                local dap = require("dap")
                local adapter = (dap.adapters.codelldb and "codelldb") or (dap.adapters.lldb and "lldb") or "gdb"
                dap.run({
                    name = runnable.label,
                    type = adapter,
                    request = "launch",
                    program = exe,
                    args = args.executableArgs or {},
                    cwd = cwd,
                    env = args.environment,
                    stopOnEntry = false,
                    sourceLanguages = adapter == "codelldb" and { "rust" } or nil,
                })
            end)
        end)
end

local function most_specific(runnables)
    local best, best_span
    for _, r in ipairs(runnables) do
        local range = r.location and r.location.targetRange
        local span = range and (range["end"].line - range.start.line) or math.huge
        if not best or span < best_span then
            best, best_span = r, span
        end
    end
    return best
end

local function request(bufnr, on_result)
    local client = vim.lsp.get_clients({ bufnr = bufnr, name = "rust_analyzer" })[1]
    if not client then
        return vim.notify("rust-analyzer is not attached", vim.log.levels.WARN)
    end
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = vim.lsp.util.make_position_params(0, client.offset_encoding).position,
    }
    client:request("experimental/runnables", params, function(err, result)
        if err or not result or #result == 0 then
            return vim.notify("no runnable under the cursor", vim.log.levels.WARN)
        end
        on_result(result)
    end, bufnr)
end

function M.run_at_cursor()
    request(0, function(runnables) M.run(most_specific(runnables)) end)
end

function M.debug_at_cursor()
    request(0, function(runnables) M.debug(most_specific(runnables)) end)
end

function M.pick()
    request(0, function(runnables)
        vim.ui.select(runnables, {
            prompt = "Runnable",
            format_item = function(r) return r.label end,
        }, function(choice)
            if choice then
                M.run(choice)
            end
        end)
    end)
end

vim.lsp.commands["rust-analyzer.runSingle"] = function(command)
    M.run(command.arguments[1])
end
vim.lsp.commands["rust-analyzer.debugSingle"] = function(command)
    M.debug(command.arguments[1])
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "rust",
    group = vim.api.nvim_create_augroup("RustRunnables", { clear = true }),
    callback = function(ev)
        local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
        end
        map("<leader>ct", M.run_at_cursor, "run test/bin under cursor")
        map("<leader>cT", M.pick, "pick a runnable")
        map("<leader>cD", M.debug_at_cursor, "debug test/bin under cursor")
    end,
})

return M
