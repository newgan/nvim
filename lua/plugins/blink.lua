require("blink.cmp").setup {
    fuzzy = {
        implementation = 'prefer_rust',
    },
    keymap = {
        preset = "enter",
        ["<C-n>"] = { "select_next", "snippet_forward", "fallback" },
        ["<C-p>"] = { "select_prev", "snippet_backward", "fallback" },
    },
    completion = {
        list = {
            selection = {
                preselect = false,
            },
        },
        ghost_text = {
            enabled = true,
        },
    },
    cmdline = {
        keymap = { preset = 'inherit' },
        completion = {
            list = {
                selection = {
                    preselect = false,
                },
            },
            menu = { auto_show = true } },
    },
}
