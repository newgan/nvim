local colors_name = "vscodebones"
vim.g.colors_name = colors_name

local lush = require("lush")
local hsluv = lush.hsluv
local util = require("zenbones.util")
local bg = vim.o.background

local mute = vim.g.vscodebones_mute or 35

local dark_plus = {
    keyword = hsluv("#569cd6"),
    control = hsluv("#c586c0"),
    string = hsluv("#ce9178"),
    func = hsluv("#dcdcaa"),
    type = hsluv("#4ec9b0"),
    comment = hsluv("#6a9955"),
    number = hsluv("#b5cea8"),
}
for name, color in pairs(dark_plus) do
    dark_plus[name] = color.de(mute)
end

local palette = util.palette_extend({
    bg = hsluv("#1e1e1e"),
    fg = hsluv("#d4d4d4"),
    rose = hsluv("#f44747"),
    leaf = hsluv("#6a9955"),
    wood = hsluv("#ce9178"),
    water = hsluv("#569cd6"),
    blossom = hsluv("#c586c0"),
    sky = hsluv("#4ec9b0"),
}, bg)

local generator = require("zenbones.specs")
local base = generator.generate(palette, bg, generator.get_global_config(colors_name, bg))

---@diagnostic disable: undefined-global
local specs = lush.extends({ base }).with(function(injected)
    local sym = injected.sym
    local c = dark_plus
    return {
        Statement { base.Statement, fg = c.keyword },
        PreProc { fg = c.keyword },
        Conditional { base.Statement, fg = c.control },
        Repeat { base.Statement, fg = c.control },
        String { base.String, fg = c.string },
        Number { fg = c.number },
        Function { fg = c.func },
        Type { fg = c.type },
        Comment { base.Comment, fg = c.comment },
        sym("@keyword") { Statement },
        sym("@keyword.function") { Statement },
        sym("@keyword.operator") { Statement },
        sym("@keyword.return") { Conditional },
        sym("@keyword.conditional") { Conditional },
        sym("@keyword.repeat") { Repeat },
        sym("@keyword.coroutine") { Conditional },
        sym("@string") { String },
        sym("@string.documentation") { String },
        sym("@number") { Number },
        sym("@type") { Type },
        sym("@type.builtin") { Statement },
        sym("@constructor") { Type },
        sym("@function") { Function },
        sym("@function.call") { Function },
        sym("@function.method") { Function },
        sym("@function.method.call") { Function },
        sym("@function.macro") { PreProc },
        sym("@attribute") { PreProc },
        sym("@comment") { Comment },

        Operator { fg = base.Normal.fg },
        OkMsg { base.DiagnosticOk },
        PmenuMatch { fg = c.keyword, gui = "bold" },
        PmenuMatchSel { fg = c.keyword, gui = "bold" },

        CompileModeError { base.DiagnosticError },
        CompileModeWarning { base.DiagnosticWarn },
        CompileModeInfo { base.DiagnosticOk },
        CompileModeMessageRow { base.LineNr },
        CompileModeMessageCol { base.LineNr },
        CompileModeCommandOutput { base.Title },
        CompileModeDirectoryMessage { base.Directory },
        CompileModeOutputFile { base.Directory },
        CompileModeCheckResult { base.DiagnosticWarn },
        CompileModeCheckTarget { base.DiagnosticWarn },

        GrugFarResultsAddIndicator { base.GitSignsAdd },
        GrugFarResultsChangeIndicator { base.GitSignsChange },
        GrugFarResultsRemoveIndicator { base.GitSignsDelete },

        FzfLuaLivePrompt { base.Statement },
    }
end)

lush(specs)
require("zenbones.term").apply_colors(palette)
