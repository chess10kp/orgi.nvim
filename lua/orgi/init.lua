local M = {}

local config = require("orgi.config")
local cli = require("orgi.cli")
local ui = require("orgi.ui")

---Setup orgi.nvim plugin
---@param opts OrgiConfig|nil Configuration options
function M.setup(opts)
  config.setup(opts)

  M._create_commands()
  M._create_autocmds()
  M._create_keybindings()

  vim.notify("orgi.nvim loaded successfully", vim.log.levels.INFO)
end

---Create Neovim commands
function M._create_commands()
  vim.api.nvim_create_user_command("OrgiList", function(opts)
    local args = opts.fargs
    local cmd_opts = {}
    if args[1] == "--all" then
      cmd_opts.all = true
    elseif args[1] == "--open" then
      cmd_opts.open = true
    end

    if args[2] then
      cmd_opts.file = args[2]
    end

    ui.show_issues_picker(cmd_opts)
  end, {
    nargs = "*",
    desc = "List orgi issues",
    complete = function(arglead)
      if arglead:match("^-") then
        return {"--all", "--open"}
      end
      return {}
    end,
  })

  vim.api.nvim_create_user_command("OrgiAdd", function(opts)
    local title = opts.fargs[1]
    local body = opts.fargs[2]

    if not title then
      title = vim.fn.input("Issue title: ")
    end

    if #title == 0 then
      vim.notify("Issue title is required", vim.log.levels.ERROR)
      return
    end

    local result = cli.add_issue({
      title = title,
      body = body,
    })

    if result then
      vim.notify("Issue created: " .. result, vim.log.levels.INFO)
    else
      vim.notify("Failed to create issue", vim.log.levels.ERROR)
    end
  end, {
    nargs = "*",
    desc = "Add a new orgi issue",
  })

  vim.api.nvim_create_user_command("OrgiDone", function(opts)
    local id = opts.fargs[1]
    if not id then
      vim.notify("Issue ID is required", vim.log.levels.ERROR)
      return
    end

    if cli.mark_done(id) then
      vim.notify("Issue marked as done", vim.log.levels.INFO)
    else
      vim.notify("Failed to mark issue as done", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    desc = "Mark an orgi issue as done",
  })

  vim.api.nvim_create_user_command("OrgiGather", function(opts)
    local dry_run = opts.fargs[1] == "--dry-run"

    if dry_run then
      vim.notify("Running gather in dry-run mode", vim.log.levels.INFO)
    end

    local gathered = cli.gather_todos(dry_run)
    if #gathered > 0 then
      vim.notify(string.format("Gathered %d TODOs", #gathered), vim.log.levels.INFO)
    else
      vim.notify("No TODOs found to gather", vim.log.levels.WARN)
    end
  end, {
    nargs = "?",
    desc = "Gather TODOs from source code",
    complete = function(arglead)
      if arglead:match("^-") then
        return {"--dry-run"}
      end
      return {}
    end,
  })

  vim.api.nvim_create_user_command("OrgiSync", function(opts)
    local auto_confirm = opts.fargs[1] == "--auto-confirm"

    if cli.sync_issues(auto_confirm) then
      vim.notify("Issues synced successfully", vim.log.levels.INFO)
    else
      vim.notify("Failed to sync issues", vim.log.levels.ERROR)
    end
  end, {
    nargs = "?",
    desc = "Sync completed issues back to source",
    complete = function(arglead)
      if arglead:match("^-") then
        return {"--auto-confirm"}
      end
      return {}
    end,
  })

  vim.api.nvim_create_user_command("OrgiPrList", function()
    ui.show_prs_picker()
  end, {
    desc = "List orgi pull requests",
  })

  vim.api.nvim_create_user_command("OrgiPrCreate", function(opts)
    local title = opts.fargs[1]
    local source_branch = opts.fargs[2]
    local description = opts.fargs[3]

    if not title or not source_branch then
      vim.notify("Title and source branch are required", vim.log.levels.ERROR)
      return
    end

    local result = cli.create_pr({
      title = title,
      source_branch = source_branch,
      description = description,
    })

    if result then
      vim.notify("PR created: " .. result, vim.log.levels.INFO)
    else
      vim.notify("Failed to create PR", vim.log.levels.ERROR)
    end
  end, {
    nargs = "*",
    desc = "Create a new pull request",
  })

  vim.api.nvim_create_user_command("OrgiPrApprove", function(opts)
    local id = opts.fargs[1]
    if not id then
      vim.notify("PR ID is required", vim.log.levels.ERROR)
      return
    end

    if cli.approve_pr(id) then
      vim.notify("PR approved", vim.log.levels.INFO)
    else
      vim.notify("Failed to approve PR", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    desc = "Approve a pull request",
  })

  vim.api.nvim_create_user_command("OrgiPrDeny", function(opts)
    local id = opts.fargs[1]
    if not id then
      vim.notify("PR ID is required", vim.log.levels.ERROR)
      return
    end

    if cli.deny_pr(id) then
      vim.notify("PR denied", vim.log.levels.INFO)
    else
      vim.notify("Failed to deny PR", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    desc = "Deny a pull request",
  })

  vim.api.nvim_create_user_command("OrgiPrMerge", function(opts)
    local id = opts.fargs[1]
    if not id then
      vim.notify("PR ID is required", vim.log.levels.ERROR)
      return
    end

    if cli.merge_pr(id) then
      vim.notify("PR merged", vim.log.levels.INFO)
    else
      vim.notify("Failed to merge PR", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    desc = "Merge a pull request",
  })
end

---Create autocmds for auto-refresh
function M._create_autocmds()
  if not config.options.auto_refresh then
    return
  end

  local group = vim.api.nvim_create_augroup("Orgi", {clear = true})

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.org",
    callback = function()
      local filepath = vim.fn.expand("%:p")
      if filepath:match("orgi%.org$") then
        vim.notify("orgi file updated", vim.log.levels.INFO)
      end
    end,
  })
end

---Create default keybindings
function M._create_keybindings()
  local opts = {silent = true, noremap = true}

  vim.keymap.set("n", "<leader>ol", "<cmd>OrgiList<CR>", opts)
  vim.keymap.set("n", "<leader>oia", "<cmd>OrgiAdd<CR>", opts)
  vim.keymap.set("n", "<leader>od", "<cmd>OrgiDone<CR>", opts)
  vim.keymap.set("n", "<leader>og", "<cmd>OrgiGather<CR>", opts)
  vim.keymap.set("n", "<leader>os", "<cmd>OrgiSync<CR>", opts)
  vim.keymap.set("n", "<leader>opl", "<cmd>OrgiPrList<CR>", opts)
  vim.keymap.set("n", "<leader>opc", "<cmd>OrgiPrCreate<CR>", opts)
end

return M
