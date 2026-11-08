local theme = require('lualine.themes.auto')
for _, mode in pairs(theme) do
    for _, section in pairs(mode) do
        section.gui = nil
    end
end

local compile_status = {
    function()
        local info = require("compile-mode").statusline_info()
        if not info.status then
            return ""
        end
        local state = info.status.type == "run" and "running" or ("exit " .. info.status.code)
        return string.format("compile: %s  E%d W%d", state, info.counts.error, info.counts.warning)
    end,
    color = function()
        local info = require("compile-mode").statusline_info()
        if not info.status then
            return nil
        end
        if info.status.type == "run" then
            return "CompileModeWarning"
        end
        return info.status.code == 0 and "CompileModeInfo" or "CompileModeError"
    end,
}

local compile_ext = vim.deepcopy(require("compile-mode.extensions.lualine"))
compile_ext.sections.lualine_b[1].color = "CompileModeError"
compile_ext.sections.lualine_b[2].color = "CompileModeWarning"
compile_ext.sections.lualine_b[3].color = "CompileModeInfo"

require('lualine').setup {
    options = {
        icons_enabled = true,
        theme = theme,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        always_show_tabline = true,
        globalstatus = true,
        refresh = {
            statusline = 1000,
            tabline = 1000,
            winbar = 1000,
            refresh_time = 16, -- ~60fps
            events = {
                'WinEnter',
                'BufEnter',
                'BufWritePost',
                'SessionLoadPost',
                'FileChangedShellPost',
                'VimResized',
                'Filetype',
                'CursorMoved',
                'CursorMovedI',
                'ModeChanged',
            },
        }
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = {
            'branch',
            {
                'diff',
                source = function()
                    local s = vim.b.gitsigns_status_dict
                    return s and { added = s.added, modified = s.changed, removed = s.removed }
                end,
            },
        },
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { compile_status },
        lualine_y = { 'progress' },
        lualine_z = {
            "diagnostics",
            {
                "lsp_status",
                icons_enabled = false,
            }
        },
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {},
        lualine_x = {},
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = { compile_ext }
}
