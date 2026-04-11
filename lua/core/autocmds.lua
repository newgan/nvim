-- treesitter auto install parsers and start
vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup("TreeSitterSetup", { clear = true }),
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        local available_langs = require('nvim-treesitter').get_available()
        local is_available = vim.tbl_contains(available_langs, lang)
        if is_available then
            local installed_langs = require('nvim-treesitter').get_installed()
            local installed = vim.tbl_contains(installed_langs, lang)
            if not installed then
                require('nvim-treesitter').install(lang):wait()
            end
            vim.treesitter.start()
        end
    end,
    desc = "Enable nvim-treesitter and install parser if not installed"
})

-- disable lsp highlighting and add formatting
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspFormatting", { clear = true }),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then return end

        if client.server_capabilities then
            client.server_capabilities.semanticTokensProvider = nil
        end

        if not client:supports_method('textDocument/willSaveWaitUntil')
            and client:supports_method('textDocument/formatting') then
            vim.api.nvim_create_autocmd('BufWritePre', {
                group = vim.api.nvim_create_augroup('my.lsp', { clear = false }),
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
