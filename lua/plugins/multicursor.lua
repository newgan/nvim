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
