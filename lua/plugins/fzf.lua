require("fzf-lua").setup {
    fzf_colors = true,
    oldfiles = {
        include_current_session = true,
        cwd_only = true,
    },
    file_ignore_patterns = {
        "node_modules/",
        "%.next/",
        "%.git/",
        "%.gitlab/",
        "target/",
        "package%-lock%.json",
        "pnpm%-lock%.yaml",
        "yarn%.lock",
        "dependencies/",
    },
}

require("fzf-lua").register_ui_select()

vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "fuzzy find recent files" })

vim.keymap.set("n", "<leader>fs", "<cmd>FzfLua live_grep_native<cr>", { desc = "find string in cwd" })
vim.keymap.set("n", "<leader>fc", "<cmd>FzfLua grep_cword<cr>", { desc = "find string under cursor in cwd" })

vim.keymap.set("n", "<leader>fd", "<cmd>FzfLua lsp_document_symbols<cr>", { desc = "find doc symbols" })
vim.keymap.set("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", { desc = "find open buffers" })

vim.keymap.set("n", "<leader>fz", "<cmd>FzfLua diagnostics_document<cr>", { desc = "find doc diagnostics" })
vim.keymap.set("n", "<leader>fZ", "<cmd>FzfLua diagnostics_workspace<cr>", { desc = "find workspace diagnostics" })

vim.keymap.set("n", "<leader>fg", "<cmd>FzfLua git_files<cr>", { desc = "find git files" })
vim.keymap.set("n", "<leader>gc", "<cmd>FzfLua git_commits<cr>", { desc = "find git commits" })
vim.keymap.set("n", "<leader>gC", "<cmd>FzfLua git_bcommits<cr>", { desc = "find git b commits" })

vim.keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "find keymaps (command palette)" })
vim.keymap.set("n", "<leader>fh", "<cmd>FzfLua helptags<cr>", { desc = "find help" })
vim.keymap.set("n", "<leader>f.", "<cmd>FzfLua resume<cr>", { desc = "resume last picker" })
vim.keymap.set("n", "<leader><leader>", "<cmd>FzfLua global<cr>", { desc = "find anything" })
