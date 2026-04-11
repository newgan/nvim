return {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_markers = {
        "go.mod",
        "go.work",
        ".git",
    },
    settings = {
        gopls = {
            ["ui.inlayhint.hints"] = {
                assignVariableTypes = true,
                compositeLiteralTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
            },
        },
    },
}
