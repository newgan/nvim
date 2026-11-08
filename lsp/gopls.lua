return {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
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
