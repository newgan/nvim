---@type vim.lsp.Config
return {
    settings = {
        redhat = { telemetry = { enabled = false } },
        yaml = {
            schemaStore = {
                enable = true,
                url = "https://www.schemastore.org/api/json/catalog.json",
            },
            schemas = {
                kubernetes = {
                    "**/base/deployment*.yaml",
                    "**/base/statefulset*.yaml",
                    "**/base/daemonset*.yaml",
                    "**/base/service*.yaml",
                    "**/base/configmap*.yaml",
                    "**/base/secret*.yaml",
                    "**/base/namespace*.yaml",
                    "**/base/networkpolicy*.yaml",
                    "**/base/poddisruptionbudget*.yaml",
                    "**/base/pvc*.yaml",
                    "**/base/ingress*.yaml",
                    "**/base/hpa*.yaml",
                    "**/base/cronjob*.yaml",
                    "**/base/job*.yaml",
                    "**/base/role*.yaml",
                    "**/base/clusterrole*.yaml",
                    "**/argo-apps/**/*.yaml",
                    "**/*externalsecret*.yaml",
                    "**/prometheusrule*.yaml",
                },
            },
            format = { enable = false },
            keyOrdering = false,
        },
    },
}
