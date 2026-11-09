-- disable lsp highlighting and add formatting
local function ruff_configured(bufnr)
    return vim.fs.root(bufnr, function(name, path)
        if name == "ruff.toml" or name == ".ruff.toml" then
            return true
        end
        if name ~= "pyproject.toml" then
            return false
        end
        local f = io.open(vim.fs.joinpath(path, name))
        if not f then
            return false
        end
        local text = f:read("*a")
        f:close()
        return text:find("[tool.ruff", 1, true) ~= nil
    end) ~= nil
end

local format_on_save = {
    rust_analyzer = true,
    gopls = true,
    clangd = { ".clang-format", "_clang-format" },
    lua_ls = { ".editorconfig" },
    ruff = ruff_configured,
    cmake = { ".cmake-format", ".cmake-format.yaml" },
    yamlls = false,
    taplo = false,
    dockerls = false,
    helm_ls = false,
    tsc = false,
    bashls = false,
}

local function formats_on_save(client, bufnr)
    local rule = format_on_save[client.name]
    if type(rule) == "function" then
        return rule(bufnr)
    end
    if type(rule) == "table" then
        return vim.fs.root(bufnr, rule) ~= nil
    end
    return rule ~= false
end

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client.server_capabilities then
            client.server_capabilities.semanticTokensProvider = nil
        end
    end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("my.lsp.format", { clear = true }),
    callback = function(ev)
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = ev.buf, method = "textDocument/formatting" })) do
            if not client:supports_method("textDocument/willSaveWaitUntil", ev.buf) and formats_on_save(client, ev.buf) then
                vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1000 })
                return
            end
        end
    end,
})

-- highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup('HighlightYank', { clear = true }),
    callback = function()
        vim.hl.on_yank({ higroup = 'Search' })
    end,
})

local function strip_bold()
    for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
        if hl.bold or (hl.cterm and hl.cterm.bold) then
            hl.bold = nil
            hl.default = nil
            if hl.cterm then
                hl.cterm.bold = nil
            end
            vim.api.nvim_set_hl(0, name, hl)
        end
    end
end

vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme" }, {
    group = vim.api.nvim_create_augroup("NoBold", { clear = true }),
    callback = strip_bold,
    desc = "Strip bold from every highlight group",
})

local autoread = vim.api.nvim_create_augroup("AutoreadOnIdle", { clear = true })
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "TermLeave" }, {
    group = autoread,
    callback = function()
        if vim.fn.getcmdwintype() == "" then
            vim.cmd.checktime()
        end
    end,
    desc = "Reload buffers that changed on disk",
})
vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = autoread,
    callback = function(ev)
        vim.notify("reloaded from disk: " .. vim.fn.fnamemodify(ev.file, ":."))
    end,
    desc = "Say which buffer was replaced by an on-disk change",
})
