require("persistence").setup({})

local map = vim.keymap.set
map("n", "<leader>qs", function() require("persistence").load() end, { desc = "restore session for cwd" })
map("n", "<leader>qS", function() require("persistence").select() end, { desc = "select a session" })
map("n", "<leader>ql", function() require("persistence").load({ last = true }) end, { desc = "restore last session" })
map("n", "<leader>qd", function() require("persistence").stop() end, { desc = "don't save this session" })
