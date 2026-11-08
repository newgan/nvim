vim.g.mapleader = " "

-- ui --
-- current line number
vim.opt.number = true
-- line number relative to current line
vim.opt.relativenumber = true
vim.o.signcolumn = "yes:2"
vim.o.numberwidth = 2
-- hide cmd line by default
vim.o.cmdheight = 0
vim.o.showcmdloc = "statusline"
vim.o.splitright = true
vim.o.splitbelow = true
-- multi line text behavior
vim.o.smoothscroll = true
vim.o.cursorline = true
vim.o.scrolloff = 8
vim.o.showmode = false
vim.o.winborder = "rounded"
vim.o.inccommand = "split"
vim.o.updatetime = 250


vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldtext = ""


vim.o.undofile = true
vim.o.confirm = true
vim.o.exrc = true
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize,help,globals,skiprtp,folds"
vim.opt.diffopt:append("algorithm:histogram")


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
vim.cmd.colorscheme("orca-oled")


-- clipboard --
local osc52 = require("vim.ui.clipboard.osc52")
vim.g.clipboard = {
    name = "osc52",
    copy = {
        ["+"] = osc52.copy("+"),
        ["*"] = osc52.copy("*"),
    },
    paste = {
        ["+"] = function()
            return vim.split(vim.fn.getreg('"'), "\n")
        end,
        ["*"] = function()
            return vim.split(vim.fn.getreg('"'), "\n")
        end,
    },
}

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
