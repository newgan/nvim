require("fzf-lua").setup {
    oldfiles = {
        include_current_session = true,
        cwd_only = true,
    },
    file_ignore_patterns = {
        "node_modules/",
        "dist/",
        ".next/",
        ".git/",
        ".gitlab/",
        "build/",
        "target/",
        "package-lock.json",
        "pnpm-lock.yaml",
        "yarn.lock",
        "dependencies/",
    },
}

vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "fuzzy find recent files" })

vim.keymap.set("n", "<leader>fs", "<cmd>FzfLua live_grep_native<cr>", { desc = "find string in cwd" })
vim.keymap.set("n", "<leader>fc", "<cmd>FzfLua grep_cword<cr>", { desc = "find string under cursor in cwd" })

vim.keymap.set("n", "<leader>fd", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "find doc symbols" })
vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "find open buffers" })

vim.keymap.set("n", "<leader>fz", "<cmd>FzfLua diagnostics_document<cr>", { desc = "find doc diagnostics" })
vim.keymap.set("n", "<leader>fZ", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "find workspace diagnostics" })

vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua git_files<cr>", { desc = "find git files" })
vim.keymap.set("n", "<leader>fgc", "<cmd>FzfLua git_commits<cr>", { desc = "find git commits" })
vim.keymap.set("n", "<leader>fgC", "<cmd>FzfLua git_bcommits<cr>", { desc = "find git b commits" })
