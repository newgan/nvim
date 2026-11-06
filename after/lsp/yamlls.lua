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
                },
                ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/external-secrets.io/externalsecret_v1beta1.json"] =
                "**/*externalsecret*.yaml",
                ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/monitoring.coreos.com/prometheusrule_v1.json"] =
                "**/prometheusrule*.yaml",
                ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/applicationset_v1alpha1.json"] =
                "**/argo-apps/**/!(*-app).yaml",
                ["https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/argoproj.io/application_v1alpha1.json"] =
                "**/argo-apps/**/*-app.yaml",
            },
            format = { enable = false },
            keyOrdering = false,
        },
    },
}
