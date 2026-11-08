local quicker = require("quicker")

quicker.setup({
    keys = {
        { ">", function() quicker.expand({ before = 2, after = 2, add_to_existing = true }) end, desc = "show more context" },
        { "<", quicker.collapse, desc = "hide context" },
    },
})

vim.keymap.set("n", "<leader>xq", function() quicker.toggle() end, { desc = "toggle quickfix" })
