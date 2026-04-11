vim.g.mapleader = " "

-- ui --
-- current line number
vim.opt.number = true
-- line number relative to current line
vim.opt.relativenumber = true
-- min sign col width
vim.o.signcolumn = "yes:1"
vim.o.numberwidth = 2
-- hide cmd line by default
vim.o.cmdheight = 0
vim.o.splitright = true
vim.o.splitbelow = true
-- multi line text behavior
vim.o.smoothscroll = true


-- indentation --
-- number of spaces tab represents
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
-- number of spaces for indentation
vim.opt.shiftwidth = 4
-- tabs to spaces
vim.opt.expandtab = true


-- pattern matching --
-- case insensitive pattern match
vim.opt.ignorecase = true
-- case sensitive only if capital letter used
vim.opt.smartcase = true


-- color --
-- 24 bit colors
vim.opt.termguicolors = true
vim.cmd.colorscheme("true-gruber-darker")


-- clipboard --
vim.opt.clipboard:append("unnamedplus")


-- list chars --
vim.opt.list = true
vim.opt.listchars = {
    tab = "  ",
    space = " ",
    trail = "·",
    nbsp = "␣",
    extends = "…",
    precedes = "…",
}
