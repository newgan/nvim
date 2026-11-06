vim.g.compile_mode = {
    input_word_completion = true,
    baleia_setup = true,
    default_command = "",
    error_regexp_table = {
        rustc = {
            regex = [[^\s*-->\s\+\(.\+\):\(\d\+\):\(\d\+\)$]],
            filename = 1,
            row = 2,
            col = 3,
            priority = 2,
        },
        rust_panic = {
            regex = [[panicked at \(.\+\):\(\d\+\):\(\d\+\):\?$]],
            filename = 1,
            row = 2,
            col = 3,
            priority = 2,
        },
        rustfmt = {
            regex = [[^Diff in \(.\+\):\(\d\+\):$]],
            filename = 1,
            row = 2,
            type = require("compile-mode").level.WARNING,
            priority = 2,
        },
    },
}

vim.keymap.set("n", "<leader>cc", "<cmd>Compile<CR>", { desc = "compile mode" })
vim.keymap.set("n", "<leader>cr", "<cmd>Recompile<CR>", { desc = "recompile" })
vim.keymap.set("n", "<leader>cn", "<cmd>NextError<CR>", { desc = "go to next compile error" })
