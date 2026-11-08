local ts = require("nvim-treesitter")
local installed = ts.get_installed()
local missing = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(installed, lang)
end, { "markdown", "markdown_inline" })
if #missing > 0 then
    ts.install(missing)
end

require("render-markdown").setup({
    completions = { blink = { enabled = true } },
    sign = { enabled = false },
})
