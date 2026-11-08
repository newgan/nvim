vim.lsp.config('lua_ls', {
    cmd = {
        "lua-language-server",
        "--logpath=" .. vim.fn.stdpath("state") .. "/lua_ls/log",
        "--metapath=" .. vim.fn.stdpath("state") .. "/lua_ls/meta",
    },
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
        },
    },
})

---@type vim.lsp.Config
return {
    ---@type lspconfig.settings.lua_ls
    settings = {
        Lua = {
            codeLens = { enable = true },
            hint = { enable = true, semicolon = "Disable" },
        },
    },
}
