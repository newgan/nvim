require("blink.cmp").setup {
    fuzzy = {
        implementation = 'prefer_rust',
    },
    keymap = {
        preset = "enter",
        ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
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
