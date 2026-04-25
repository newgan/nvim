vim.lsp.config('lua_ls', {
    on_init = function(client)
        if client.workspace_folders then
            local path = client.workspace_folders[1].name
            if
                path ~= vim.fn.stdpath('config')
                and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
            then
                return
            end
        end

        client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
            runtime = {
                version = 'LuaJIT',
                path = {
                    'lua/?.lua',
                    'lua/?/init.lua',
                },
            },
            diagnostics = {
                globals = { "vim" },
            },
            workspace = {
                preloadFileSize = 10000,
                library = {
                    vim.env.VIMRUNTIME,
                }
            },
            telemetry = { enable = false },
        })
    end,
    settings = {
        Lua = {},
    },
})

local root_markers1 = {
    ".emmyrc.json",
    ".luarc.json",
    ".luarc.jsonc",
}
local root_markers2 = {
    ".luacheckrc",
    ".stylua.toml",
    "stylua.toml",
    "selene.toml",
    "selene.yml",
}

---@type vim.lsp.Config
return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers1, root_markers2, { ".git" } }
        or vim.list_extend(vim.list_extend(root_markers1, root_markers2), { ".git" }),
    ---@type lspconfig.settings.lua_ls
    settings = {
        Lua = {
            codeLens = { enable = true },
            hint = { enable = true, semicolon = "Disable" },
            defaultConfig = {
                indent_style = "space",
                indent_size = "4",
            },
        },
    },
}
