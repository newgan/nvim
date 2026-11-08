local c = require("true-gruber-darker.palette")

return {
    normal = {
        a = { bg = c.niagara, fg = c.bg_minus_1 },
        b = { bg = c.bg_1, fg = c.fg },
        c = { bg = c.bg, fg = c.quartz },
    },
    insert = { a = { bg = c.green, fg = c.bg_minus_1 } },
    visual = { a = { bg = c.yellow, fg = c.bg_minus_1 } },
    replace = { a = { bg = c.red, fg = c.bg_minus_1 } },
    command = { a = { bg = c.wisteria, fg = c.bg_minus_1 } },
}
