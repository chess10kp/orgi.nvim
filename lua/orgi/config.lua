local M = {}

---@class OrgiConfig
---@field orgi_file string Path to the .orgi file
---@field keymaps table<string, string>|nil Custom keybindings
local defaults = {
  orgi_file = ".orgi/orgi.org",
  auto_refresh = true,
  colors = {
    todo = "OrgiTodo",
    inprogress = "OrgiInProgress",
    done = "OrgiDone",
    kill = "OrgiKill",
    priority_a = "OrgiPriorityA",
    priority_b = "OrgiPriorityB",
    priority_c = "OrgiPriorityC",
  },
}

---@type OrgiConfig
M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", defaults, opts or {})
  M._setup_colors()
end

function M._setup_colors()
  vim.cmd([[
    highlight OrgiTodo guifg=#E5C07B gui=bold
    highlight OrgiInProgress guifg=#61AFEF gui=bold
    highlight OrgiDone guifg=#98C379 gui=bold
    highlight OrgiKill guifg=#E06C75 gui=bold
    highlight OrgiPriorityA guifg=#E06C75 gui=bold
    highlight OrgiPriorityB guifg=#E5C07B gui=bold
    highlight OrgiPriorityC guifg=#98C379 gui=bold
  ]])
end

return M
