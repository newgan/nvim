local function helm(path)
    if vim.fs.root(path, "Chart.yaml") then
        return "helm"
    end
end

vim.filetype.add({
    extension = { nomad = "hcl" },
    pattern = {
        [".*/templates/.*%.ya?ml"] = helm,
        [".*/templates/NOTES%.txt"] = helm,
        [".*/charts/.*%.tpl"] = "helm",
    },
})
