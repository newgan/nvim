local mc = require("multicursor-nvim")
mc.setup()

local set = vim.keymap.set

set({ "n", "x" }, "<up>", function() mc.lineAddCursor(-1) end, { desc = "add cursor above" })
set({ "n", "x" }, "<down>", function() mc.lineAddCursor(1) end, { desc = "add cursor below" })
set({ "n", "x" }, "<leader><up>", function() mc.lineSkipCursor(-1) end, { desc = "skip line above" })
set({ "n", "x" }, "<leader><down>", function() mc.lineSkipCursor(1) end, { desc = "skip line below" })

set({ "n", "x" }, "<leader>mn", function() mc.matchAddCursor(1) end, { desc = "add cursor at next match" })
set({ "n", "x" }, "<leader>mN", function() mc.matchAddCursor(-1) end, { desc = "add cursor at previous match" })
set({ "n", "x" }, "<leader>ms", function() mc.matchSkipCursor(1) end, { desc = "skip next match" })
set({ "n", "x" }, "<leader>mS", function() mc.matchSkipCursor(-1) end, { desc = "skip previous match" })
set({ "n", "x" }, "<leader>ma", mc.matchAllAddCursors, { desc = "add cursors at all matches" })
set("n", "ga", mc.addCursorOperator, { desc = "add cursors over a motion" })
set("x", "I", mc.insertVisual, { desc = "insert on each line" })
set("x", "A", mc.appendVisual, { desc = "append on each line" })
set("x", "M", mc.matchCursors, { desc = "cursors at regex matches" })
set("x", "S", mc.splitCursors, { desc = "split selection by regex" })
set("n", "<leader>mo", mc.operator, { desc = "cursors at matches in a motion" })
set("n", "<leader>m=", mc.alignCursors, { desc = "align cursors" })
set("n", "<leader>mv", mc.restoreCursors, { desc = "restore cursors" })
set("n", "<leader>md", function()
    vim.cmd("normal! gg")
    mc.diagnosticMatchCursors({ severity = vim.diagnostic.severity.ERROR })
    vim.api.nvim_feedkeys("G", "n", false)
end, { desc = "cursors at every error" })
set("x", "<leader>md", function()
    mc.diagnosticMatchCursors({ severity = vim.diagnostic.severity.ERROR })
end, { desc = "cursors at errors in selection" })
set("n", "<leader>m/", mc.searchAllAddCursors, { desc = "cursors at all search matches" })
set("x", "<leader>mt", function() mc.transposeCursors(1) end, { desc = "rotate selections" })
set({ "n", "x" }, "g<c-a>", mc.sequenceIncrement, { desc = "increment as a sequence" })
set({ "n", "x" }, "g<c-x>", mc.sequenceDecrement, { desc = "decrement as a sequence" })

set("n", "<c-leftmouse>", mc.handleMouse)
set("n", "<c-leftdrag>", mc.handleMouseDrag)
set("n", "<c-leftrelease>", mc.handleMouseRelease)

set({ "n", "x" }, "<c-q>", mc.toggleCursor, { desc = "toggle multicursor" })

mc.addKeymapLayer(function(layerSet)
    layerSet({ "n", "x" }, "<left>", mc.prevCursor)
    layerSet({ "n", "x" }, "<right>", mc.nextCursor)
    layerSet({ "n", "x" }, "<leader>mx", mc.deleteCursor)
    layerSet("n", "<esc>", function()
        if not mc.cursorsEnabled() then
            mc.enableCursors()
        else
            mc.clearCursors()
        end
    end)
end)

local hl = vim.api.nvim_set_hl
hl(0, "MultiCursorCursor", { reverse = true })
hl(0, "MultiCursorVisual", { link = "Visual" })
hl(0, "MultiCursorSign", { link = "SignColumn" })
hl(0, "MultiCursorMatchPreview", { link = "Search" })
hl(0, "MultiCursorDisabledCursor", { reverse = true })
hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })
