vim.diagnostic.config({
    virtual_text = { current_line = true },
    severity_sort = true,
    jump = {
        on_jump = function(_, bufnr)
            vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
        end,
    },
})

vim.lsp.enable("clangd")
vim.lsp.enable("lua_ls")        -- lua
vim.lsp.enable("rust_analyzer") -- rust
vim.lsp.enable("gopls")         -- go
vim.lsp.enable("ts_ls")         -- ts, js
vim.lsp.enable("ruff")          -- python
vim.lsp.enable("ty")            -- python
vim.lsp.enable("cmake")
vim.lsp.enable("yamlls")
vim.lsp.enable("helm_ls")
vim.lsp.enable("taplo")
vim.lsp.enable("bashls")
vim.lsp.enable("dockerls")

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        local opts = { buffer = ev.buf, silent = true }

        opts.desc = "Show LSP references"
        vim.keymap.set("n", "gR", "<cmd>FzfLua lsp_references<CR>", opts)

        opts.desc = "Go to declaration"
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        opts.desc = "Show LSP definitions"
        vim.keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts)

        opts.desc = "Show LSP implementations"
        vim.keymap.set("n", "gri", "<cmd>FzfLua lsp_implementations<CR>", opts)

        opts.desc = "Show LSP type definitions"
        vim.keymap.set("n", "grt", "<cmd>FzfLua lsp_type_definitions<CR>", opts)

        opts.desc = "See available code actions"
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        opts.desc = "Smart rename"
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        opts.desc = "Show buffer diagnostics"
        vim.keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics bufnr=0<CR>", opts)

        opts.desc = "Show line diagnostics"
        vim.keymap.set("n", "<leader>cd", function()
            vim.diagnostic.open_float(nil, { scope = "line", focus = false })
        end, opts)

        opts.desc = "Show documentation for what is under cursor"
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

        opts.desc = "Restart LSP"
        vim.keymap.set("n", "<leader>rs", "<cmd>lsp restart<CR>", opts)

        opts.desc = "Toggle inlay hints"
        vim.keymap.set("n", "<leader>th", function()
            local current = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
            vim.lsp.inlay_hint.enable(not current, { bufnr = ev.buf })
        end, opts)

        if client and client:supports_method("textDocument/codeLens") then
            vim.lsp.codelens.enable(true, { bufnr = ev.buf })
        end

        if client and client.name == "clangd" then
            opts.desc = "Switch source/header"
            vim.keymap.set("n", "<leader>tt", "<cmd>LspClangdSwitchSourceHeader<CR>", opts)

            opts.desc = "Show symbol info"
            vim.keymap.set("n", "<leader>ti", "<cmd>LspClangdShowSymbolInfo<CR>", opts)
        end
    end,
})
