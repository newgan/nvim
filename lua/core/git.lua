local M = {}

local function git(dir, args)
    local cmd = { "git" }
    if dir then
        vim.list_extend(cmd, { "-C", dir })
    end
    local out = vim.fn.systemlist(vim.list_extend(cmd, args))
    if vim.v.shell_error == 0 and out[1] and out[1] ~= "" then
        return out[1]
    end
end

function M.base_ref(dir)
    return git(dir, { "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" }) or "origin/main"
end

function M.merge_base(dir)
    local base = M.base_ref(dir)
    local sha = git(dir, { "merge-base", "HEAD", base })
    if not sha then
        vim.notify("no merge base with " .. base, vim.log.levels.WARN)
    end
    return sha
end

return M
