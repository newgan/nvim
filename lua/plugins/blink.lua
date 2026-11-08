require("blink.cmp").setup {
    fuzzy = {
        implementation = 'prefer_rust',
    },
    keymap = {
        preset = "enter",
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
    },
    completion = {
        list = {
            selection = {
                preselect = false,
                auto_insert = false,
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
            snippets = {
                should_show_items = function(ctx)
                    return ctx.trigger.initial_kind ~= "trigger_character"
                end,
            },
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                score_offset = 100,
            },
        },
    },
    cmdline = {
        keymap = {
            preset = 'inherit',
            ['<Tab>'] = { 'select_next', 'show' },
            ['<S-Tab>'] = { 'select_prev', 'show' },
            ['<CR>'] = { 'accept_and_enter', 'fallback' },
            ['<C-n>'] = { 'select_next', 'fallback' },
            ['<C-p>'] = { 'select_prev', 'fallback' },
            ['<Up>'] = false,
            ['<Down>'] = false,
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                },
            },
            menu = { auto_show = true } },
    },
}
