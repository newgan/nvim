local indent = require("blink.indent")

indent.setup({
    scope = { highlights = { "BlinkIndentScope" } },
})

vim.keymap.set("n", "<leader>tg", function()
    indent.enable(not indent.is_enabled())
end, { desc = "toggle indent guides" })
