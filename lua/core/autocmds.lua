vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup("TreeSitterSetup", { clear = true }),
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        local ts = require('nvim-treesitter')
        if not lang or not vim.tbl_contains(ts.get_available(), lang) then
            return
        end
        local function start()
            if vim.api.nvim_buf_is_valid(ev.buf) then
                pcall(vim.treesitter.start, ev.buf, lang)
            end
        end
        if vim.tbl_contains(ts.get_installed(), lang) then
            start()
        else
            ts.install(lang):await(function(err)
                if not err then
                    vim.schedule(start)
                end
            end)
        end
    end,
    desc = "Enable nvim-treesitter and install parser if not installed"
})

-- disable lsp highlighting and add formatting
local format_group = vim.api.nvim_create_augroup('my.lsp.format', { clear = true })
local no_format_on_save = { yamlls = true, taplo = true, dockerls = true, helm_ls = true, clangd = true }
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

        if client.server_capabilities then
            client.server_capabilities.semanticTokensProvider = nil
        end

        if not no_format_on_save[client.name]
            and not client:supports_method('textDocument/willSaveWaitUntil')
            and client:supports_method('textDocument/formatting') then
            vim.api.nvim_clear_autocmds({ group = format_group, buffer = ev.buf })
            vim.api.nvim_create_autocmd('BufWritePre', {
                group = format_group,
                buffer = ev.buf,
                callback = function()
                    vim.lsp.buf.format({ bufnr = ev.buf, id = client.id, timeout_ms = 1000 })
                end,
            })
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

-- lsp progress bar
vim.api.nvim_create_autocmd('LspProgress', {
    callback = function(ev)
        local value = ev.data.params.value
        vim.api.nvim_echo({ { value.message or 'done' } }, false, {
            id = 'lsp.' .. ev.data.params.token,
            kind = 'progress',
            source = 'vim.lsp',
            title = value.title,
            status = value.kind ~= 'end' and 'running' or 'success',
            percent = value.percentage,
        })
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
