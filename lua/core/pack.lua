vim.api.nvim_create_autocmd('PackChanged', {
    group = vim.api.nvim_create_augroup('pack_changed', { clear = true }),
    callback = function(ev)
        if ev.data.kind == 'delete' then
            return
        end
        local name = ev.data.spec.name
        if name == 'nvim-treesitter' then
            pcall(function()
                vim.cmd('TSUpdate')
            end)
        elseif name == 'mason.nvim' then
            pcall(function()
                vim.cmd('MasonUpdate')
            end)
        end
    end,
})

vim.pack.add({
    -- lsp
    { src = 'https://github.com/neovim/nvim-lspconfig' },

    -- treesitter
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter',            version = 'main' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-textobjects' },
    { src = 'https://github.com/nvim-treesitter/nvim-treesitter-context' },

    -- finder
    { src = "https://github.com/ibhagwan/fzf-lua" },

    -- completion
    { src = "https://github.com/saghen/blink.cmp",                           version = vim.version.range("1.x") },
    { src = "https://github.com/rafamadriz/friendly-snippets" },

    -- mini
    { src = "https://github.com/nvim-mini/mini.icons" },

    -- compile mode
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/ej-shafran/compile-mode.nvim",               version = "nightly" },
    { src = "https://github.com/m00qek/baleia.nvim",                         version = "v1.4.0" },

    -- which key
    { src = "https://github.com/folke/which-key.nvim" },

    -- oil
    { src = "https://github.com/refractalize/oil-git-status.nvim" },
    { src = "https://github.com/stevearc/oil.nvim" },
}, { load = true, confirm = false })

require('mini.icons').setup()

require("plugins.fzf")
require("plugins.treesitter")
require("plugins.blink")
require("plugins.compile-mode")
require("plugins.oil")
