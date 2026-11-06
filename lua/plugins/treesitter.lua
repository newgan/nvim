-- Treesitter
require('nvim-treesitter').setup({
    install_dir = vim.fn.stdpath('data') .. '/site',
})

require('nvim-treesitter-textobjects').setup({
    select = {
        lookahead = true,
    },
    move = {
        set_jumps = true,
    },
})

local map = vim.keymap.set

local select = require('nvim-treesitter-textobjects.select').select_textobject
for key, capture in pairs({
    af = '@function.outer',
    ['if'] = '@function.inner',
    ac = '@class.outer',
    ic = '@class.inner',
    aa = '@parameter.outer',
    ia = '@parameter.inner',
}) do
    map({ 'x', 'o' }, key, function()
        select(capture, 'textobjects')
    end, { desc = 'select ' .. capture })
end

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
