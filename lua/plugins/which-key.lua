local wk = require("which-key")

wk.setup({
    delay = 300,
})

wk.add({
    mode = { "n", "x" },
    { "<leader>c", group = "code / compile" },
    { "<leader>d", group = "debug" },
    { "<leader>f", group = "find" },
    { "<leader>g", group = "git" },
    { "<leader>h", group = "git hunk" },
    { "<leader>m", group = "multicursor" },
    { "<leader>q", group = "session" },
    { "<leader>r", group = "rename / restart" },
    { "<leader>s", group = "split" },
    { "<leader>t", group = "toggle" },
    { "<leader>x", group = "diagnostics / trouble" },
    { "<leader>y", group = "yank for agent" },
    {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "buffer local keymaps",
    },
})
