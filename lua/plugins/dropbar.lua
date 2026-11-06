require("dropbar").setup({})

local api = require("dropbar.api")
vim.keymap.set("n", "<leader>;", api.pick, { desc = "pick symbol in winbar" })
vim.keymap.set("n", "[;", api.goto_context_start, { desc = "go to start of current context" })
vim.keymap.set("n", "];", api.select_next_context, { desc = "select next context" })
