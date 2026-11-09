vim.g.vscodebones_mute = 35

vim.g.zenwritten = {
    italic_comments = true,
    italic_strings = true,
}

vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("BlackBackground", { clear = true }),
    callback = function()
        local old = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
        if not old or old == 0 then
            return
        end
        for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
            if not hl.link and hl.bg == old then
                hl.bg = 0
                pcall(vim.api.nvim_set_hl, 0, name, hl)
            end
        end
    end,
})

vim.o.background = "dark"
vim.cmd.colorscheme("vscodebones")
