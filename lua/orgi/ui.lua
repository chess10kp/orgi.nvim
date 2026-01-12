local M = {}
local nui_popup = require("nui.popup")
local config = require("orgi.config")
local cli = require("orgi.cli")
local parser = require("orgi.parser")

local current_popup = nil

---Show issue detail in a floating window
---@param issue table Issue data
function M.show_issue_detail(issue)
  if current_popup then
    current_popup:unmount()
    current_popup = nil
  end

  local lines = {
    "",
    "  Title:   " .. (issue.title or ""),
    "  State:   " .. (issue.state or "TODO"),
    "  Priority:" .. (issue.priority or "None"),
    "  Tags:    " .. table.concat(issue.tags or {}, ", "),
    "",
    "  Body:",
    "  " .. (issue.body or "No body"),
    "",
  }

  if issue.id then
    table.insert(lines, 1, "  ID:      " .. issue.id)
  end

  if issue.created then
    table.insert(lines, "  Created: " .. issue.created)
  end

  current_popup = nui_popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Issue Details ",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = "80%",
      height = "60%",
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })

  current_popup:map("n", "q", function()
    current_popup:unmount()
    current_popup = nil
  end, {noremap = true})

  current_popup:map("n", "<Esc>", function()
    current_popup:unmount()
    current_popup = nil
  end, {noremap = true})

  if issue.state ~= "DONE" and issue.state ~= "KILL" then
    current_popup:map("n", "d", function()
      if issue.id and cli.mark_done(issue.id) then
        vim.notify("Issue marked as done", vim.log.levels.INFO)
        current_popup:unmount()
        current_popup = nil
      else
        vim.notify("Failed to mark issue as done", vim.log.levels.ERROR)
      end
    end, {noremap = true})
  end

  vim.api.nvim_buf_set_lines(current_popup.bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_add_highlight(current_popup.bufnr, -1, "Comment", 0, 0, -1)

  current_popup:mount()
end

---Show issues picker using snacks.nvim
---@param opts? {all?: boolean, open?: boolean, file?: string}
function M.show_issues_picker(opts)
  opts = opts or {}

  local issues, err = cli.list_issues(opts)
  if err == "not_initialized" then
    vim.notify("orgi has not been initialized. Run :OrgiInit first.", vim.log.levels.ERROR)
    return
  end

  if not issues or #issues == 0 then
    vim.notify("No issues found", vim.log.levels.WARN)
    return
  end

  local entries = {}
  for _, issue in ipairs(issues) do
    table.insert(entries, {
      id = issue.id,
      display = parser.format_issue(issue),
      ordinal = issue.title,
      issue = issue,
    })
  end

  local Snacks = require("snacks")

  Snacks.picker.pick({
    items = entries,
    prompt = "Issues",
    format = function(item)
      local display = item.display or item.ordinal or ""
      local icon, hl = M._get_issue_icon_hl(item.issue)
      return {
        { icon .. " ", hl = hl },
        { display },
      }
    end,
    actions = {
      confirm = function(picker)
        local selected = picker:find()
        if selected and selected.issue then
          M.show_issue_detail(selected.issue)
        end
        picker:close()
      end,
      done = function(picker)
        local selected = picker:find()
        if selected and selected.issue and selected.issue.id then
          if cli.mark_done(selected.issue.id) then
            vim.notify("Issue marked as done", vim.log.levels.INFO)
          else
            vim.notify("Failed to mark issue as done", vim.log.levels.ERROR)
          end
        end
        picker:close()
      end,
    },
    win = {
      input = {
        keys = {
          ["d"] = "done",
        },
      },
    },
  })
end

---Show PRs picker using snacks.nvim
function M.show_prs_picker()
  local prs = cli.list_prs()
  if #prs == 0 then
    vim.notify("No pull requests found", vim.log.levels.WARN)
    return
  end

  local entries = {}
  for _, pr in ipairs(prs) do
    table.insert(entries, {
      id = pr.id,
      display = string.format("[%d] %s (%s - %s)", pr.id, pr.title, pr.status, pr.author),
      ordinal = pr.title,
      pr = pr,
    })
  end

  local Snacks = require("snacks")

  Snacks.picker.pick({
    items = entries,
    prompt = "Pull Requests",
    format = function(item)
      local pr = item.pr
      local icon, hl = M._get_pr_icon_hl(pr)
      return {
        { icon .. " ", hl = hl },
        { string.format("[%d] ", pr.id) },
        { pr.title .. " ", hl = "Title" },
        { string.format("(%s - %s)", pr.status, pr.author), hl = "Comment" },
      }
    end,
    actions = {
      confirm = function(picker)
        local selected = picker:find()
        if selected and selected.pr then
          M._show_pr_detail(selected.pr)
        end
        picker:close()
      end,
    },
  })
end

---Show PR detail in a floating window
---@param pr table PR data
function M._show_pr_detail(pr)
  if current_popup then
    current_popup:unmount()
    current_popup = nil
  end

  local lines = {
    "",
    "  Title:   " .. (pr.title or ""),
    "  Status:  " .. (pr.status or "unknown"),
    "  Author:  " .. (pr.author or "unknown"),
    "",
  }

  if pr.id then
    table.insert(lines, 1, "  ID:      " .. pr.id)
  end

  current_popup = nui_popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = " Pull Request Details ",
        top_align = "center",
      },
    },
    position = "50%",
    size = {
      width = "80%",
      height = "40%",
    },
    buf_options = {
      modifiable = false,
      readonly = true,
    },
  })

  current_popup:map("n", "q", function()
    current_popup:unmount()
    current_popup = nil
  end, {noremap = true})

  current_popup:map("n", "<Esc>", function()
    current_popup:unmount()
    current_popup = nil
  end, {noremap = true})

  vim.api.nvim_buf_set_lines(current_popup.bufnr, 0, -1, false, lines)

  current_popup:mount()
end

---Get icon and highlight for issue state
---@param issue table Issue data
---@return string icon, string highlight
function M._get_issue_icon_hl(issue)
  if issue.state == "TODO" then
    return "", config.options.colors.todo
  elseif issue.state == "INPROGRESS" then
    return "", config.options.colors.inprogress
  elseif issue.state == "DONE" then
    return "", config.options.colors.done
  elseif issue.state == "KILL" then
    return "", config.options.colors.kill
  end
  return "", "Normal"
end

---Get icon and highlight for PR status
---@param pr table PR data
---@return string icon, string highlight
function M._get_pr_icon_hl(pr)
  if pr.status == "OPEN" then
    return "", "OrgiInProgress"
  elseif pr.status == "APPROVED" then
    return "", "OrgiDone"
  elseif pr.status == "DENIED" then
    return "", "OrgiKill"
  elseif pr.status == "MERGED" then
    return "", "OrgiDone"
  end
  return "", "Normal"
end

return M
