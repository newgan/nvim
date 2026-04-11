vim.lsp.enable("clangd")                -- c, c++
vim.lsp.enable("lua_ls")                -- lua
vim.lsp.enable("rust_analyzer")         -- rust
vim.lsp.enable("gopls")                 -- go
vim.lsp.enable("ts_ls")                 -- ts, js
vim.lsp.enable("ruff")                  -- python
vim.lsp.enable("basedpyright")          -- python
vim.lsp.enable("pyrefly")               -- python
vim.lsp.enable("cmake-language-server") -- cmake

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(ev)
        local opts = { buffer = ev.buf, silent = true }

        opts.desc = "Show LSP references"
        vim.keymap.set("n", "gR", "<cmd>FzfLua lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        vim.keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        vim.keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        vim.keymap.set("n", "gt", "<cmd>FzfLua lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        vim.keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        vim.keymap.set("n", "<leader>d", function()
            vim.diagnostic.open_float(nil, {
                scope = "line",
                focus = false,
            })
        end, { desc = "Show line diagnostics" })

        opts.desc = "Go to previous diagnostic"
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary

        opts.desc = "Toggle inlay hinting"
        vim.keymap.set("n", "th", function()
            local current = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
            vim.lsp.inlay_hint.enable(not current, { bufnr = ev.buf })
        end, opts)
    end,
})
