-- Treesitter
require('nvim-treesitter').setup({
    install_dir = vim.fn.stdpath('data') .. '/site',
})

local ts = require('nvim-treesitter')
local map = vim.keymap.set

local max_bytes = 2 * 1024 * 1024
local function huge(buf)
    return vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) > max_bytes
end

local installed = ts.get_installed()
local missing = vim.tbl_filter(function(lang)
    return not vim.list_contains(installed, lang)
end, { 'gotmpl', 'comment', 'regex', 'printf', 'luadoc', 'luap', 'promql', 'html' })
if #missing > 0 then
    ts.install(missing)
end

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('TreeSitterSetup', { clear = true }),
    callback = function(ev)
        local lang = vim.treesitter.language.get_lang(ev.match)
        if not lang or not vim.list_contains(ts.get_available(), lang) or huge(ev.buf) then
            return
        end
        local function start()
            if not vim.api.nvim_buf_is_valid(ev.buf) or not pcall(vim.treesitter.start, ev.buf, lang) then
                return
            end
            for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
                vim.wo[win][0].foldmethod = 'expr'
                vim.wo[win][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
            end
        end
        if vim.list_contains(ts.get_installed(), lang) then
            start()
        else
            ts.install(lang):await(function(err)
                if not err then
                    vim.schedule(start)
                end
            end)
        end
    end,
    desc = 'Start treesitter highlighting and folds, installing the parser if needed',
})

require('nvim-treesitter-textobjects').setup({
    select = {
        lookahead = true,
    },
    move = {
        set_jumps = true,
    },
})

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

local repeat_move = require('nvim-treesitter-textobjects.repeatable_move')
map({ 'n', 'x', 'o' }, ';', repeat_move.repeat_last_move, { desc = 'repeat last move' })
map({ 'n', 'x', 'o' }, ',', repeat_move.repeat_last_move_opposite, { desc = 'repeat last move backwards' })
for _, key in ipairs({ 'f', 'F', 't', 'T' }) do
    map({ 'n', 'x', 'o' }, key, repeat_move['builtin_' .. key .. '_expr'], { expr = true })
end

local swap = require('nvim-treesitter-textobjects.swap')
map('n', '<leader>a', function()
    swap.swap_next('@parameter.inner')
end, { desc = 'swap parameter with next' })
map('n', '<leader>A', function()
    swap.swap_previous('@parameter.inner')
end, { desc = 'swap parameter with previous' })

-- context
require('treesitter-context').setup({
    max_lines = 3,
    min_window_height = 20,
    multiline_threshold = 1,
    on_attach = function(buf)
        return not huge(buf)
    end,
})

map('n', 'gC', function()
    require('treesitter-context').go_to_context()
end, { desc = 'go to context' })
