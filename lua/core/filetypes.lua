vim.filetype.add({
    extension = { nomad = "hcl" },
    pattern = {
        [".*/charts/[^/]+/templates/.*%.ya?ml"] = "helm",
        [".*/charts/[^/]+/templates/NOTES%.txt"] = "helm",
        [".*/templates/.*%.tpl"] = "helm",
    },
})
