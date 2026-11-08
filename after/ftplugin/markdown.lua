vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true
vim.opt_local.spell = true

MiniPairs.map_buf(0, "i", "`", {
    action = "closeopen",
    pair = "``",
    neigh_pattern = "^[^\\`]",
    register = { cr = false },
})
