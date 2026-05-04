return {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
    on_attach = function(client, _)
        client.server_capabilities.hoverProvider = false
    end,
    init_options = {
        settings = {
            args = {
                "--ignore",
                "F821",
                "--ignore",
                "E402",
                "ignore",
                "E722",
                "--ignore",
                "E712"
            }
        },
    },
}
