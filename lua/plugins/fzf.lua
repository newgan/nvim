local fd_excludes = { "target", "node_modules", ".next", ".gitlab", "package-lock.json", "pnpm-lock.yaml", "yarn.lock" }

require("fzf-lua").setup {
    fzf_colors = true,
    oldfiles = {
        include_current_session = true,
        cwd_only = true,
    },
    files = {
        fd_opts = require("fzf-lua.defaults").defaults.files.fd_opts
            .. " --exclude " .. table.concat(fd_excludes, " --exclude "),
    },
    grep = {
        file_ignore_patterns = { "package%-lock%.json$", "pnpm%-lock%.yaml$", "yarn%.lock$" },
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
vim.keymap.set("n", "<leader>gs", "<cmd>FzfLua git_status<cr>", { desc = "git status (stage / unstage)" })
vim.keymap.set("n", "<leader>hf", "<cmd>FzfLua git_hunks<cr>", { desc = "find hunks across the repo" })
vim.keymap.set("n", "<leader>gw", "<cmd>FzfLua git_worktrees<cr>", { desc = "switch worktree (:cd)" })

vim.keymap.set("n", "<leader>fw", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", { desc = "find workspace symbols" })
vim.keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "find keymaps (command palette)" })
vim.keymap.set("n", "<leader>fh", "<cmd>FzfLua helptags<cr>", { desc = "find help" })
vim.keymap.set("n", "<leader>f.", "<cmd>FzfLua resume<cr>", { desc = "resume last picker" })
vim.keymap.set("n", "<leader><leader>", "<cmd>FzfLua global<cr>", { desc = "find anything" })
