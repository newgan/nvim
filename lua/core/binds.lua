vim.keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "clear search highlights" })
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "even split window" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "close current split" })

vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'move to left split' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'move to bottom split' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'move to top split' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'move to right split' })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "clear search highlights" })
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "exit terminal mode" })

local function yank_location(visual)
    local path = vim.fn.expand("%:.")
    if path == "" then
        return vim.notify("no file name", vim.log.levels.WARN)
    end
    local text
    if visual then
        local first, last = vim.fn.line("v"), vim.fn.line(".")
        if first > last then
            first, last = last, first
        end
        local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
        text = string.format("%s:%d-%d\n```%s\n%s\n```", path, first, last, vim.bo.filetype, table.concat(lines, "\n"))
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    else
        text = string.format("%s:%d", path, vim.fn.line("."))
    end
    vim.fn.setreg("+", text)
    vim.notify("yanked " .. text:match("^[^\n]*"))
end
vim.keymap.set("n", "<leader>yl", function() yank_location(false) end, { desc = "yank path:line for an agent" })
vim.keymap.set("x", "<leader>yl", function() yank_location(true) end, { desc = "yank path:lines + code for an agent" })
vim.keymap.set("n", "<leader>yf", function()
    local path = vim.fn.expand("%:.")
    vim.fn.setreg("+", path)
    vim.notify("yanked " .. path)
end, { desc = "yank file path" })

local function yank_gh(args, cwd)
    vim.system(vim.list_extend({ "gh" }, args), { text = true, cwd = cwd }, function(r)
        vim.schedule(function()
            local url = vim.trim(r.stdout or "")
            if r.code ~= 0 or url == "" then
                return vim.notify(vim.trim(r.stderr or "") ~= "" and vim.trim(r.stderr) or "gh failed", vim.log.levels.ERROR)
            end
            vim.fn.setreg("+", url)
            vim.notify("yanked " .. url)
        end)
    end)
end

vim.keymap.set({ "n", "x" }, "<leader>yu", function()
    local file = vim.api.nvim_buf_get_name(0)
    local root = vim.fs.root(0, ".git")
    if file == "" or not root then
        return vim.notify("not a file in a git repo", vim.log.levels.WARN)
    end
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
        first, last = last, first
    end
    if vim.fn.mode():find("^[vV\22]") then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
    local lines = first == last and tostring(first) or first .. "-" .. last
    yank_gh({ "browse", "-n", "--commit", vim.fs.relpath(root, file) .. ":" .. lines }, root)
end, { desc = "yank GitHub permalink" })
vim.keymap.set("n", "<leader>yp", function()
    yank_gh({ "pr", "view", "--json", "url", "-q", ".url" }, vim.fs.root(0, ".git") or vim.fn.getcwd())
end, { desc = "yank PR url" })

vim.keymap.set("n", "<leader>tu", function()
    if vim.fn.exists(":Undotree") == 0 then
        vim.cmd.packadd("nvim.undotree")
    end
    vim.cmd.Undotree()
end, { desc = "toggle undo tree" })
