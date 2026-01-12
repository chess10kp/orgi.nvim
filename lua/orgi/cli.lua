local M = {}
local plenary_job = require("plenary.job")
local config = require("orgi.config")

---Execute orgi command and return stdout
---@param args table Command arguments
---@param callback? fun(output: string, code: number) Callback for async execution
---@return string|nil output, number|nil exit_code
function M.run(args, callback)
  local job = plenary_job:new({
    command = "orgi",
    args = args,
    on_exit = function(j, code)
      local output = table.concat(j:result(), "\n")
      if callback then
        callback(output, code)
      end
    end,
  })

  if callback then
    job:start()
    return nil, nil
  else
    job:sync()
    return table.concat(job:result(), "\n"), job.code
  end
end

---List issues
---@param opts? {all?: boolean, open?: boolean, file?: string}
---@return table[]
function M.list_issues(opts)
  if not M.is_initialized() then
    return nil, "not_initialized"
  end

  opts = opts or {}
  local args = {"list"}

  if opts.all then
    table.insert(args, "--all")
  end

  if opts.file then
    table.insert(args, opts.file)
  end

  local output, code = M.run(args)
  if code ~= 0 or not output or #output == 0 then
    return {}
  end

  return M._parse_list_output(output)
end

---Add a new issue
---@param opts {title?: string, body?: string, priority?: string, state?: string, tags?: string[]}
---@return string|nil issue_id
function M.add_issue(opts)
  local args = {"add"}

  if opts.title then
    table.insert(args, opts.title)
  end

  if opts.body then
    table.insert(args, "--body")
    table.insert(args, opts.body)
  end

  if opts.priority then
    table.insert(args, "--priority")
    table.insert(args, opts.priority)
  end

  local output, code = M.run(args)
  if code ~= 0 or not output then
    return nil
  end

  return (output:match("Created issue: (.+)") or output:match("task%-(%d+)"))
end

---Mark issue as done
---@param id string Issue ID or index
---@return boolean success
function M.mark_done(id)
  local _, code = M.run({"done", tostring(id)})
  return code == 0
end

---Gather TODOs from source code
---@param dry_run? boolean
---@return table[] gathered_issues
function M.gather_todos(dry_run)
  local args = {"gather"}
  if dry_run then
    table.insert(args, "--dry-run")
  end

  local output, code = M.run(args)
  if code ~= 0 or not output then
    return {}
  end

  return M._parse_list_output(output)
end

---Sync completed issues back to source
---@param auto_confirm? boolean
---@return boolean success
function M.sync_issues(auto_confirm)
  local args = {"sync"}
  if auto_confirm then
    table.insert(args, "--auto-confirm")
  end

  local _, code = M.run(args)
  return code == 0
end

---List pull requests
---@return table[]
function M.list_prs()
  local output, code = M.run({"pr", "list"})
  if code ~= 0 or not output or #output == 0 then
    return {}
  end

  return M._parse_pr_list(output)
end

---Create pull request
---@param opts {title: string, source_branch: string, description?: string, target_branch?: string}
---@return string|nil pr_id
function M.create_pr(opts)
  local args = {"pr", "create", "--title", opts.title, "--source-branch", opts.source_branch}

  if opts.description then
    table.insert(args, "--description")
    table.insert(args, opts.description)
  end

  if opts.target_branch then
    table.insert(args, "--target-branch")
    table.insert(args, opts.target_branch)
  end

  local output, code = M.run(args)
  if code ~= 0 or not output then
    return nil
  end

  return output:match("PR (%d+)")
end

---Approve pull request
---@param id string PR ID
---@param opts? {reviewer?: string, comment?: string}
---@return boolean success
function M.approve_pr(id, opts)
  opts = opts or {}
  local args = {"pr", "approve", "--id", tostring(id)}

  if opts.reviewer then
    table.insert(args, "--reviewer")
    table.insert(args, opts.reviewer)
  end

  if opts.comment then
    table.insert(args, "--comment")
    table.insert(args, opts.comment)
  end

  local _, code = M.run(args)
  return code == 0
end

---Deny pull request
---@param id string PR ID
---@param opts? {reviewer?: string, comment?: string}
---@return boolean success
function M.deny_pr(id, opts)
  opts = opts or {}
  local args = {"pr", "deny", "--id", tostring(id)}

  if opts.reviewer then
    table.insert(args, "--reviewer")
    table.insert(args, opts.reviewer)
  end

  if opts.comment then
    table.insert(args, "--comment")
    table.insert(args, opts.comment)
  end

  local _, code = M.run(args)
  return code == 0
end

---Merge pull request
---@param id string PR ID
---@param opts? {merger?: string}
---@return boolean success
function M.merge_pr(id, opts)
  opts = opts or {}
  local args = {"pr", "merge", "--id", tostring(id)}

  if opts.merger then
    table.insert(args, "--merger")
    table.insert(args, opts.merger)
  end

  local _, code = M.run(args)
  return code == 0
end

---Parse list output into structured data
---@param output string Raw CLI output
---@return table[]
function M._parse_list_output(output)
  local issues = {}
  local lines = vim.split(output, "\n", {trimempty = true})

  for _, line in ipairs(lines) do
    local id, state, priority, title, tags = line:match("%[(%d+)%]%s+(%w+)%s+%[#(%w)%]%s+(.+)%s*:(.+):")
    if id and state and priority and title and tags then
      table.insert(issues, {
        id = tonumber(id),
        state = state,
        priority = priority,
        title = title,
        tags = vim.split(tags, ":"),
      })
    end
  end

  return issues
end

---Parse PR list output
---@param output string Raw CLI output
---@return table[]
function M._parse_pr_list(output)
  local prs = {}
  local lines = vim.split(output, "\n", {trimempty = true})

  -- TODO: Adjust regex pattern based on actual orgi pr list output format
  for _, line in ipairs(lines) do
    local id, title, status, author = line:match("%[(%d+)%]%s+(.+)%s+(%w+)%s+(.+)")
    if id and title then
      table.insert(prs, {
        id = tonumber(id),
        title = title,
        status = status or "unknown",
        author = author or "unknown",
      })
    end
  end

  return prs
end

---Initialize orgi
---@return boolean success
function M.init()
  local _, code = M.run({"init"})
  return code == 0
end

---Check if orgi has been initialized
---@return boolean is_initialized
function M.is_initialized()
  local orgi_file = vim.fn.expand(config.options.orgi_file)
  return vim.fn.filereadable(orgi_file) == 1
end

return M
