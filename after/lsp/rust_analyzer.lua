return {
    settings = {
        ["rust-analyzer"] = {
            lens = {
                references = {
                    adt = { enable = false },
                    enumVariant = { enable = false },
                    method = { enable = false },
                    trait = { enable = false },
                },
            },
            check = {
                workspace = false,
                command = "clippy",
            },
            cargo = {
                targetDir = true,
            },
            files = {
                watcher = "server",
            },
            workspace = {
                symbol = {
                    search = { kind = "all_symbols" },
                },
            },
            inlayHints = {
                lifetimeElisionHints = { enable = "skip_trivial" },
                closureReturnTypeHints = { enable = "with_block" },
                reborrowHints = { enable = "mutable" },
            },
            references = {
                excludeImports = true,
            },
        },
    },
}
