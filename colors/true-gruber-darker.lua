local palette = {
    fg = "#e4e4ef",
    fg_1 = "#f4f4ff",
    fg_2 = "#f5f5f5",
    fg_3 = "#3a3a3a",
    white = "#ffffff",
    black = "#000000",
    bg_minus_1 = "#101010",
    bg = "#181818",
    bg_1 = "#282828",
    bg_2 = "#453d41",
    bg_3 = "#484848",
    bg_4 = "#52494e",
    red_minus_1 = "#c73c3f",
    red = "#f43841",
    red_1 = "#ff4f58",
    green = "#73c936",
    yellow = "#ffdd33",
    brown = "#cc8c3c",
    quartz = "#95a99f",
    niagara_2 = "#303540",
    niagara_1 = "#565f73",
    niagara = "#96a6c8",
    wisteria = "#9e95c7",
}

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
end

vim.g.colors_name = "true-gruber-darker"
vim.o.termguicolors = true

local c = palette
local hl = vim.api.nvim_set_hl

hl(0, "Normal", { fg = c.fg, bg = c.bg })
hl(0, "NormalFloat", { fg = c.fg, bg = c.bg_1 })
hl(0, "ColorColumn", { bg = c.bg_1 })
hl(0, "Cursor", { fg = c.black, bg = c.yellow })
hl(0, "CursorLine", { bg = c.bg_1 })
hl(0, "LineNr", { fg = c.bg_4 })
hl(0, "CursorLineNr", { fg = c.yellow, bold = true })
hl(0, "VertSplit", { fg = c.bg_2, bg = c.bg })
hl(0, "Whitespace", { fg = c.fg_3 })

hl(0, "Search", { fg = c.fg, bg = c.bg_4 })
hl(0, "IncSearch", { fg = c.black, bg = c.fg_2 })
hl(0, "Visual", { bg = c.bg_3 })

hl(0, "Comment", { fg = c.brown })
hl(0, "Constant", { fg = c.quartz })
hl(0, "String", { fg = c.green })
hl(0, "Number", { fg = c.wisteria })
hl(0, "Boolean", { fg = c.wisteria })
hl(0, "Identifier", { fg = c.fg_1 })
hl(0, "Function", { fg = c.niagara })
hl(0, "Statement", { fg = c.yellow, bold = true })
hl(0, "Keyword", { fg = c.yellow, bold = true })
hl(0, "Type", { fg = c.quartz })
hl(0, "Special", { fg = c.yellow })

hl(0, "@variable", { fg = c.fg_1 })
hl(0, "@variable.builtin", { fg = c.yellow })
hl(0, "@function", { fg = c.fg_1 })
hl(0, "@keyword", { fg = c.yellow, bold = true })
hl(0, "@type", { fg = c.quartz })

local status_lualine, lualine = pcall(require, "lualine")
if status_lualine then
    lualine.setup({
        options = {
            theme = {
                normal = {
                    a = { bg = c.niagara, fg = c.bg_minus_1, gui = "bold" },
                    b = { bg = c.bg_1, fg = c.fg },
                    c = { bg = c.bg, fg = c.quartz },
                },
                insert = { a = { bg = c.green, fg = c.bg_minus_1, gui = "bold" } },
                visual = { a = { bg = c.yellow, fg = c.bg_minus_1, gui = "bold" } },
                replace = { a = { bg = c.red, fg = c.bg_minus_1, gui = "bold" } },
                command = { a = { bg = c.wisteria, fg = c.bg_minus_1, gui = "bold" } },
            },
        },
    })
end
