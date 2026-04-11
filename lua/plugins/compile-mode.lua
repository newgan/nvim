vim.g.compile_mode = {
    input_word_completion = true,
    use_pseudo_terminal = true,
    baleia_setup = true,
    default_command = "",
}

vim.keymap.set("n", "<leader>cc", "<cmd>Compile<CR>", { desc = "compile mode" })
vim.keymap.set("n", "<leader>cr", "<cmd>Recompile<CR>", { desc = "recompile" })
vim.keymap.set("n", "<leader>cn", "<cmd>NextError<CR>", { desc = "go to next compile error" })
