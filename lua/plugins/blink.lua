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
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
        },
        ghost_text = {
            enabled = true,
        },
    },
    signature = { enabled = true },
    sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                score_offset = 100,
            },
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
