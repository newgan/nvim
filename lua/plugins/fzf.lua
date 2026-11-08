local fd_excludes = { "target", "node_modules", ".next", ".gitlab", "package-lock.json", "pnpm-lock.yaml", "yarn.lock" }
local fd_opts = require("fzf-lua.defaults").defaults.files.fd_opts
    .. " --exclude " .. table.concat(fd_excludes, " --exclude ")

local rg_opts = '-g "!package-lock.json" -g "!pnpm-lock.yaml" -g "!yarn.lock" '
    .. require("fzf-lua.defaults").defaults.grep.rg_opts

require("fzf-lua").setup {
    fzf_colors = true,
    fzf_opts = { ["--cycle"] = true },
    oldfiles = {
        include_current_session = true,
        cwd_only = true,
    },
    files = { fd_opts = fd_opts },
    global = { fd_opts = fd_opts },
    grep = { rg_opts = rg_opts },
}

require("fzf-lua").register_ui_select()

vim.keymap.set("n", "<leader>ff", "<cmd>FzfLua files<cr>", { desc = "fuzzy find files in cwd" })
vim.keymap.set("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", { desc = "fuzzy find recent files" })

vim.keymap.set("n", "<leader>fs", "<cmd>FzfLua live_grep_native<cr>", { desc = "find string in cwd" })
vim.keymap.set("x", "<leader>fs", "<cmd>FzfLua grep_visual<cr>", { desc = "find selection in cwd" })
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
vim.keymap.set("n", "<leader>gf", function()
    local base = require("core.git").merge_base()
    if base then require("fzf-lua").git_diff({ ref = base }) end
end, { desc = "files changed vs merge base" })
vim.keymap.set("n", "<leader>hF", function()
    local base = require("core.git").merge_base()
    if base then require("fzf-lua").git_hunks({ ref = base }) end
end, { desc = "hunks vs merge base" })
vim.keymap.set("n", "<leader>gB", "<cmd>FzfLua git_branches<cr>", { desc = "git branches" })
vim.keymap.set("n", "<leader>gS", "<cmd>FzfLua git_stash<cr>", { desc = "git stash" })

vim.keymap.set("n", "<leader>fw", "<cmd>FzfLua lsp_live_workspace_symbols<cr>", { desc = "find workspace symbols" })
vim.keymap.set("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", { desc = "find keymaps (command palette)" })
vim.keymap.set("n", "<leader>fh", "<cmd>FzfLua helptags<cr>", { desc = "find help" })
vim.keymap.set("n", "<leader>f.", "<cmd>FzfLua resume<cr>", { desc = "resume last picker" })
vim.keymap.set("n", "<leader>f/", "<cmd>FzfLua blines<cr>", { desc = "find lines in buffer" })
vim.keymap.set("n", "<leader>fq", "<cmd>FzfLua quickfix<cr>", { desc = "find in quickfix" })
vim.keymap.set("n", "<leader>fQ", "<cmd>FzfLua quickfix_stack<cr>", { desc = "quickfix history" })
vim.keymap.set("n", '<leader>f"', "<cmd>FzfLua registers<cr>", { desc = "registers" })
vim.keymap.set("n", "<leader>fj", "<cmd>FzfLua jumps<cr>", { desc = "jumplist" })
vim.keymap.set("n", "<leader>fm", "<cmd>FzfLua marks<cr>", { desc = "marks" })
vim.keymap.set("n", "<leader>f:", "<cmd>FzfLua command_history<cr>", { desc = "command history" })
vim.keymap.set("n", "<leader>ft", "<cmd>FzfLua treesitter<cr>", { desc = "treesitter symbols" })
vim.keymap.set("n", "<leader>fi", "<cmd>FzfLua lsp_incoming_calls<cr>", { desc = "incoming calls" })
vim.keymap.set("n", "<leader>fo", "<cmd>FzfLua lsp_outgoing_calls<cr>", { desc = "outgoing calls" })
vim.keymap.set("n", "<leader>fa", "<cmd>FzfLua lsp_finder<cr>", { desc = "all LSP locations" })
vim.keymap.set("n", "z=", "<cmd>FzfLua spell_suggest<cr>", { desc = "spelling suggestions" })
vim.keymap.set("i", "<C-x><C-f>", function() require("fzf-lua").complete_path() end, { desc = "complete path" })
vim.keymap.set("i", "<C-x><C-l>", function() require("fzf-lua").complete_line() end, { desc = "complete line" })
vim.keymap.set("n", "<leader><leader>", "<cmd>FzfLua global<cr>", { desc = "find anything" })
