require("diffview").setup({
    enhanced_diff_hl = true,
    view = {
        merge_tool = { layout = "diff3_mixed", disable_diagnostics = true },
    },
})

local function base_ref()
    local out = vim.fn.systemlist("git symbolic-ref --quiet --short refs/remotes/origin/HEAD")
    if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
        return out[1]
    end
    return "origin/main"
end

local map = vim.keymap.set
map("n", "<leader>gv", "<cmd>DiffviewOpen<CR>", { desc = "diff: working tree vs HEAD" })
map("n", "<leader>gm", function() vim.cmd.DiffviewOpen(base_ref() .. "...HEAD") end,
    { desc = "diff: branch commits vs base" })
map("n", "<leader>gM", function() vim.cmd.DiffviewOpen(base_ref()) end,
    { desc = "diff: working tree vs base" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { desc = "history: current file" })
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<CR>", { desc = "history: branch" })
map("n", "<leader>gq", "<cmd>DiffviewClose<CR>", { desc = "close diffview" })
