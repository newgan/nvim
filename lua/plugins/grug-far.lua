require("grug-far").setup({})

vim.keymap.set("n", "<leader>fR", function()
    require("grug-far").open({ transient = true })
end, { desc = "find & replace in project" })

vim.keymap.set("x", "<leader>fR", function()
    require("grug-far").with_visual_selection({ transient = true })
end, { desc = "find & replace selection" })
