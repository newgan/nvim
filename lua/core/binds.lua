vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "clear search highlights" })
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "even split window" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "close current split" })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'move to left split' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'move to bottom split' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'move to top split' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'move to right split' })

vim.keymap.set('n', '<leader>gd', '<cmd>Gitsigns diffthis<CR>', { desc = "gitsigns diff" })
