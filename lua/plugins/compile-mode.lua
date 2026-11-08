local level = require("compile-mode").level

local function project_default_command()
    local markers = {
        { "Makefile", "make" },
        { "Cargo.toml", "cargo build" },
        { "go.mod", "go build ./..." },
        { "CMakeLists.txt", "cmake --build build" },
        { "pyproject.toml", "pytest" },
        { "package.json", "npm run build" },
    }
    local best, best_depth = "", -1
    for _, marker in ipairs(markers) do
        local found = vim.fs.find(marker[1], { upward = true, path = vim.fn.getcwd(), type = "file" })[1]
        if found then
            local depth = #vim.fs.dirname(found)
            if depth > best_depth then
                best, best_depth = marker[2], depth
            end
        end
    end
    return best
end

vim.g.compile_mode = {
    input_word_completion = true,
    ansi_color = { kind = "render" },
    environment = {
        CARGO_TERM_COLOR = "always",
        CLICOLOR_FORCE = "1",
        FORCE_COLOR = "1",
        PY_COLORS = "1",
        CMAKE_COLOR_DIAGNOSTICS = "ON",
    },
    default_command = project_default_command,
    remember_commands = true,
    ask_about_save = false,
    use_circular_error_navigation = true,
    hidden_buffer = true,
    error_ignore_file_list = { [[\%(^\|/\)target/]], [[/\.cargo/registry/]] },
    live_quickfix = true,
    live_diagnostics = true,
    window = { split = "botright", size = 15 },
    error_regexp_table = {
        absoft = false,
        ada = false,
        aix = false,
        ant = false,
        borland = false,
        comma = false,
        cucumber = false,
        msft = false,
        epc = false,
        ftnchek = false,
        gradle_kotlin = false,
        iar = false,
        ibm = false,
        irix = false,
        java = false,
        jikes_file = false,
        maven = false,
        ["ruby_Test::Unit"] = false,
        lcc = false,
        makepp = false,
        mips_1 = false,
        mips_2 = false,
        omake = false,
        oracle = false,
        perl = false,
        php = false,
        rxp = false,
        sun = false,
        sun_ada = false,
        watcom = false,
        ["4bsd"] = false,
        ["perl__Pod::Checker"] = false,
        rustc = {
            regex = [[^\s*-->\s\+\(.\+\):\(\d\+\):\(\d\+\)$]],
            filename = 1,
            row = 2,
            col = 3,
            priority = 2,
            level_from_previous = true,
        },
        rust_panic = {
            regex = [[panicked at \(.\+\):\(\d\+\):\(\d\+\):\?$]],
            filename = 1,
            row = 2,
            col = 3,
            priority = 2,
        },
        rustfmt = {
            regex = [[^Diff in \(.\+\):\(\d\+\):$]],
            filename = 1,
            row = 2,
            type = level.WARNING,
            priority = 2,
        },
        tsc = {
            regex = [[^\(\S\+\)(\(\d\+\),\(\d\+\)): \%(error\|\(warning\)\)]],
            filename = 1,
            row = 2,
            col = 3,
            type = { 4 },
            priority = 2,
        },
        pytest = {
            regex = [[^FAILED \(\S\+\.py\)::]],
            filename = 1,
            priority = 2,
        },
        nvim_lua = {
            regex = [[^E5108: Error executing lua \(\S\+\.lua\):\(\d\+\):]],
            filename = 1,
            row = 2,
            priority = 2,
        },
    },
}

local function map(key, rhs, desc)
    vim.keymap.set("n", key, rhs, { desc = desc })
end

local function save_all()
    pcall(vim.cmd.wall)
end

map("<leader>cc", function()
    save_all()
    vim.cmd.Compile()
end, "compile")
map("<leader>cr", function()
    save_all()
    vim.cmd.Recompile()
end, "recompile")
map("<leader>cn", "<cmd>NextError<CR>", "next compile error")
map("<leader>cp", "<cmd>PrevError<CR>", "previous compile error")
map("<leader>cf", "<cmd>FirstError<CR>", "first compile error")
map("<leader>ce", "<cmd>CurrentError<CR>", "current compile error")
map("<leader>cq", "<cmd>QuickfixErrors<CR>", "compile errors to quickfix")
map("<leader>ci", function()
    require("compile-mode").interrupt()
end, "interrupt compilation")
map("<leader>co", "<cmd>CompileToggle<CR>", "toggle compilation window")
map("<leader>cF", function()
    save_all()
    require("compile-mode").compile({ args = "cargo fmt --check" })
end, "cargo fmt --check")

map("<leader>fe", function()
    local cm = require("compile-mode")
    local items = cm.error_items()
    if #items == 0 then
        vim.notify("No compile errors")
        return
    end
    local entries, index = {}, {}
    for i, item in ipairs(items) do
        local entry = string.format("%s:%d:%d: [%s] %s", item.filename, item.lnum or 1, item.col or 1, item.type, item.text)
        table.insert(entries, entry)
        if not index[entry] then
            index[entry] = i
        end
    end

    require("fzf-lua").fzf_exec(entries, {
        prompt = "Compile errors> ",
        previewer = "builtin",
        actions = {
            ["default"] = function(selected)
                local idx = index[selected[1]]
                if idx then
                    cm.first_error({ count = idx })
                end
            end,
        },
    })
end, "find compile errors")

vim.api.nvim_create_autocmd("User", {
    pattern = "CompilationFinished",
    group = vim.api.nvim_create_augroup("CompileModeFinish", { clear = true }),
    callback = function(ev)
        local data = ev.data
        if data.counts.error > 0 then
            require("compile-mode").first_error({ smods = { silent = true } })
        elseif data.code == 0 and data.counts.warning == 0 then
            vim.defer_fn(function()
                if #vim.api.nvim_list_wins() == 1 or not vim.api.nvim_buf_is_valid(data.bufnr) then
                    return
                end
                local tab = vim.api.nvim_get_current_tabpage()
                for _, win in ipairs(vim.fn.win_findbuf(data.bufnr)) do
                    if vim.api.nvim_win_get_tabpage(win) == tab and #vim.api.nvim_list_wins() > 1 then
                        vim.api.nvim_win_close(win, true)
                    end
                end
            end, 800)
        end
    end,
})

local function project_targets()
    local cwd = vim.fn.getcwd()
    local targets = {}
    local function add(cmd)
        if not vim.tbl_contains(targets, cmd) then
            table.insert(targets, cmd)
        end
    end
    local function find_up(name)
        return vim.fs.find(name, { upward = true, path = cwd, type = "file" })[1]
    end

    local makefile = find_up("Makefile")
    if makefile then
        local dir = vim.fs.dirname(makefile)
        local prefix = dir == cwd and "make " or ("make -C " .. vim.fn.shellescape(dir) .. " ")
        for _, line in ipairs(vim.fn.readfile(makefile)) do
            local target = line:match("^([%w][%w_%-%./]*):[^=]*$")
            if target then
                add(prefix .. target)
            end
        end
    end

    local cargo = find_up("Cargo.toml")
    if cargo then
        for _, sub in ipairs({ "build", "check", "clippy", "test", "run", "fmt --check" }) do
            add("cargo " .. sub)
        end
        local config = vim.fs.joinpath(vim.fs.dirname(cargo), ".cargo", "config.toml")
        if vim.fn.filereadable(config) == 1 then
            local in_alias = false
            for _, line in ipairs(vim.fn.readfile(config)) do
                local section = line:match("^%s*%[(.-)%]")
                if section then
                    in_alias = section == "alias"
                elseif in_alias then
                    local name = line:match("^%s*([%w_%-]+)%s*=")
                    if name then
                        add("cargo " .. name)
                    end
                end
            end
        end
    end

    if find_up("go.mod") then
        for _, cmd in ipairs({ "go build ./...", "go test ./...", "go vet ./..." }) do
            add(cmd)
        end
    end

    local package_json = find_up("package.json")
    if package_json then
        local ok, json = pcall(vim.json.decode, table.concat(vim.fn.readfile(package_json), "\n"))
        if ok and type(json) == "table" and type(json.scripts) == "table" then
            local names = vim.tbl_keys(json.scripts)
            table.sort(names)
            for _, name in ipairs(names) do
                add("npm run " .. name)
            end
        end
    end

    if find_up("pyproject.toml") then
        add("pytest")
        add("ruff check .")
    end
    if find_up("CMakeLists.txt") then
        add("cmake --build build")
        add("ctest --test-dir build")
    end
    return targets
end

map("<leader>cm", function()
    local targets = project_targets()
    if #targets == 0 then
        vim.notify("No build targets found above " .. vim.fn.getcwd())
        return
    end
    require("fzf-lua").fzf_exec(targets, {
        prompt = "Compile> ",
        actions = {
            ["default"] = function(selected)
                if selected[1] then
                    save_all()
                    require("compile-mode").compile({ args = selected[1] })
                end
            end,
        },
    })
end, "pick a build target")
