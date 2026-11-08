local c = require("orca-oled.palette")

local function mode(color)
    return { a = { fg = c.bg, bg = color } }
end

return {
    normal = {
        a = { fg = c.bg, bg = c.fg },
        b = { fg = c.fg, bg = c.accent },
        c = { fg = c.muted, bg = c.bg },
    },
    insert = mode(c.string),
    visual = mode(c.keyword),
    replace = mode(c.error),
    command = mode(c.escape),
    inactive = {
        a = { fg = c.muted, bg = c.bg },
        b = { fg = c.muted, bg = c.bg },
        c = { fg = c.muted, bg = c.bg },
    },
}
