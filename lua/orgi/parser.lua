local M = {}
local config = require("orgi.config")

---Parse Org file content into structured issues
---@param filepath string Path to .orgi file
---@return table[] issues
function M.parse_issues(filepath)
  if not vim.fn.filereadable(filepath) then
    return {}
  end

  local content = table.concat(vim.fn.readfile(filepath), "\n")
  return M._parse_fallback(content)
end

---Parse Org file content using regex patterns
---@param content string File content
---@return table[] issues
function M._parse_fallback(content)
  local issues = {}
  local state = nil
  local priority = nil
  local tags = {}
  local title = ""
  local body_lines = {}
  local id = nil
  local created = nil
  local in_properties = false
  local in_body = false

  for line in content:gmatch("[^\n]+") do
    if line:match("^%*%s+(TODO|INPROGRESS|DONE|KILL)") then
      if title ~= "" then
        table.insert(issues, {
          id = id,
          state = state,
          priority = priority,
          title = title,
          tags = tags,
          body = table.concat(body_lines, "\n"),
          created = created,
        })
      end

      state, priority, title = line:match("^%*%s+(%w+)%s+%[#(%w)%]%s+(.+)")
      if not state then
        state, title = line:match("^%*%s+(%w+)%s+(.+)")
      end

      local tags_str = line:match(":(.+):$")
      if tags_str then
        tags = vim.split(tags_str, ":")
      else
        tags = {}
      end

      id = nil
      created = nil
      body_lines = {}
      in_body = false
      in_properties = false
    elseif line:match("^%s*:PROPERTIES:") then
      in_properties = true
    elseif line:match("^%s*:END:") then
      in_properties = false
      in_body = true
    elseif in_properties then
      local key, value = line:match("^%s*:(%w+):%s*(.+)")
      if key == "ID" then
        id = value
      elseif key == "CREATED" then
        created = value
      elseif key == "TITLE" then
        title = value
      end
    elseif in_body and not line:match("^%s*$") then
      table.insert(body_lines, line)
    end
  end

  if title ~= "" then
    table.insert(issues, {
      id = id,
      state = state,
      priority = priority,
      title = title,
      tags = tags,
      body = table.concat(body_lines, "\n"),
      created = created,
    })
  end

  return issues
end

---Get formatted display text for an issue
---@param issue table Issue data
---@return string formatted text
function M.format_issue(issue)
  local colors = config.options.colors
  local state_text = issue.state or "TODO"
  local priority_text = issue.priority and string.format("[#%s]", issue.priority) or ""
  local tags_text = #issue.tags > 0 and " :" .. table.concat(issue.tags, ":") .. ":" or ""

  local color_hl
  if issue.state == "TODO" then
    color_hl = colors.todo
  elseif issue.state == "INPROGRESS" then
    color_hl = colors.inprogress
  elseif issue.state == "DONE" then
    color_hl = colors.done
  elseif issue.state == "KILL" then
    color_hl = colors.kill
  end

  local priority_hl
  if issue.priority == "A" then
    priority_hl = colors.priority_a
  elseif issue.priority == "B" then
    priority_hl = colors.priority_b
  elseif issue.priority == "C" then
    priority_hl = colors.priority_c
  end

  local result = string.format("[%s] ", issue.id or "?")
  if color_hl then
    result = result .. string.format("%%#%s#%s%%*", color_hl, state_text)
  else
    result = result .. state_text
  end
  result = result .. " "

  if priority_hl then
    result = result .. string.format("%%#%s#%s%%*", priority_hl, priority_text)
  else
    result = result .. priority_text
  end

  result = result .. " " .. issue.title .. tags_text

  return result
end

return M
