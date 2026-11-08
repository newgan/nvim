require("diffview").setup({
    enhanced_diff_hl = true,
    view = {
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
    },
})

local base_ref = require("core.git").base_ref

local map = vim.keymap.set
map("n", "<leader>gv", "<cmd>DiffviewOpen<CR>", { desc = "diff: working tree vs HEAD" })
map("n", "<leader>gm", function() vim.cmd("DiffviewOpen " .. base_ref() .. "...HEAD") end,
    { desc = "diff: branch commits vs base" })
map("n", "<leader>gM", function() vim.cmd("DiffviewOpen " .. base_ref() .. "...HEAD --imply-local") end,
    { desc = "diff: working tree vs base" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "history: current file" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<CR>", { desc = "history: branch" })
map("n", "<leader>gl", function()
    vim.cmd("DiffviewFileHistory --range=" .. base_ref() .. "...HEAD --right-only --no-merges")
end, { desc = "history: branch commits one by one" })
map("n", "<leader>gW", "<cmd>DiffviewWorktreeOverview<CR>", { desc = "worktree overview" })
map("n", "<leader>gq", "<cmd>DiffviewClose<CR>", { desc = "close diffview" })
