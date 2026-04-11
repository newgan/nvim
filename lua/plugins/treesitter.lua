-- Treesitter
require('nvim-treesitter').setup({
    install_dir = vim.fn.stdpath('data') .. '/site',
    auto_install = true,
})

require('nvim-treesitter-textobjects').setup({
    move = {
        set_jumps = true,
    },
})

local map = vim.keymap.set

-- Movement
map({ 'n', 'x', 'o' }, ']f', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
end, { desc = 'next function start' })
map({ 'n', 'x', 'o' }, '[f', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
end, { desc = 'previous function start' })
map({ 'n', 'x', 'o' }, ']F', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@function.outer', 'textobjects')
end, { desc = 'next function end' })
map({ 'n', 'x', 'o' }, '[F', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@function.outer', 'textobjects')
end, { desc = 'previous function end' })
map({ 'n', 'x', 'o' }, ']k', function()
    require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects')
end, { desc = 'next class start' })
map({ 'n', 'x', 'o' }, '[k', function()
    require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
end, { desc = 'previous class start' })
map({ 'n', 'x', 'o' }, ']K', function()
    require('nvim-treesitter-textobjects.move').goto_next_end('@class.outer', 'textobjects')
end, { desc = 'next class end' })
map({ 'n', 'x', 'o' }, '[K', function()
    require('nvim-treesitter-textobjects.move').goto_previous_end('@class.outer', 'textobjects')
end, { desc = 'previous class end' })

-- context
require('treesitter-context').setup({
    max_lines = 3,
    min_window_height = 20,
})

map('n', 'gC', function()
    require('treesitter-context').go_to_context()
end, { desc = 'go to context' })
