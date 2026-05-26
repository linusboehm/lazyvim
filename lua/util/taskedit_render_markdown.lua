local M = {}

local annotation_indent = string.rep(" ", 21)
local annotation_header = "^  Annotation:%s+%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d %-%- "
local namespace = vim.api.nvim_create_namespace("taskedit-render-markdown")

local function add_highlight(marks, row, start_col, end_col, hl_group)
  if end_col <= start_col then
    return
  end

  marks[#marks + 1] = {
    conceal = false,
    start_row = row,
    start_col = start_col,
    opts = {
      end_row = row,
      end_col = end_col,
      hl_group = hl_group,
      hl_mode = "combine",
    },
  }
end

local function add_overlay(marks, row, col, text, hl_group)
  marks[#marks + 1] = {
    conceal = false,
    start_row = row,
    start_col = col,
    opts = {
      virt_text = { { text, hl_group } },
      virt_text_pos = "overlay",
    },
  }
end

local function add_inline(marks, row, col, text, hl_group)
  marks[#marks + 1] = {
    conceal = false,
    start_row = row,
    start_col = col,
    opts = {
      virt_text = { { text, hl_group } },
      virt_text_pos = "inline",
    },
  }
end

local function enabled(config, key)
  return not config or not config[key] or config[key].enabled ~= false
end

local function add_checkbox_highlight(marks, row, start_col, checkbox)
  local checked = checkbox:match("[xX]") ~= nil
  add_highlight(
    marks,
    row,
    start_col,
    start_col + #checkbox,
    checked and "@markup.list.checked" or "@markup.list.unchecked"
  )
end

local function overlaps(ranges, start_pos, end_pos)
  for _, range in ipairs(ranges) do
    if start_pos < range[2] and end_pos > range[1] then
      return true
    end
  end

  return false
end

local function add_link(marks, row, body_start, start_pos, end_pos, ranges)
  if overlaps(ranges, start_pos, end_pos) then
    return
  end

  ranges[#ranges + 1] = { start_pos, end_pos }
  add_inline(marks, row, body_start + start_pos - 1, "󰌹 ", "RenderMarkdownLink")
  add_highlight(marks, row, body_start + start_pos - 1, body_start + end_pos - 1, "RenderMarkdownLink")
end

local function annotation_body_start(line, in_annotation)
  local sep_start, sep_end = line:find(" -- ", 1, true)

  if sep_start and line:match(annotation_header) then
    return sep_end, true
  end

  if in_annotation and line:sub(1, #annotation_indent) == annotation_indent then
    return #annotation_indent, true
  end

  return nil, false
end

local function render_inline(config, marks, row, line, body_start)
  local body = line:sub(body_start + 1)

  if enabled(config, "code") then
    for start_pos, _, end_pos in body:gmatch("()(`[^`]+`)()") do
      add_highlight(marks, row, body_start + start_pos - 1, body_start + end_pos - 1, "RenderMarkdownCodeInline")
    end
  end

  if enabled(config, "link") then
    local link_ranges = {}

    for start_pos, _, end_pos in body:gmatch("()(%[[^][]+%]%b())()") do
      add_link(marks, row, body_start, start_pos, end_pos, link_ranges)
    end

    for start_pos, end_pos in body:gmatch("()%[https?://[^%]]+%]()") do
      add_link(marks, row, body_start, start_pos, end_pos, link_ranges)
    end

    for start_pos, _, end_pos in body:gmatch("()(https?://%S+)()") do
      local trimmed_end = end_pos

      while trimmed_end > start_pos do
        local trailing = body:sub(trimmed_end - 1, trimmed_end - 1)
        if
          trailing ~= "]"
          and trailing ~= ")"
          and trailing ~= "."
          and trailing ~= ","
          and trailing ~= ";"
          and trailing ~= ":"
        then
          break
        end
        trimmed_end = trimmed_end - 1
      end

      add_link(marks, row, body_start, start_pos, trimmed_end, link_ranges)
    end
  end

  for start_pos, _, end_pos in body:gmatch("()%*%*([^*]-)%*%*()") do
    add_highlight(marks, row, body_start + start_pos + 1, body_start + end_pos - 3, "@markup.strong")
  end
end

local function render_block(config, marks, row, line, body_start)
  local body = line:sub(body_start + 1)
  local leading, rest = body:match("^(%s*)(.*)$")
  local content_col = body_start + #leading

  local heading = rest:match("^(#+)%s*%S")
  if heading and enabled(config, "heading") then
    local level = math.min(#heading, 6)
    add_highlight(marks, row, content_col, #line, ("RenderMarkdownH%d"):format(level))
    return
  end

  local quote = rest:match("^>%s*")
  if quote and enabled(config, "quote") then
    add_overlay(marks, row, content_col, "▋", "RenderMarkdownQuote1")
    add_highlight(marks, row, content_col, #line, "RenderMarkdownQuote")
    return
  end

  local marker = rest:match("^([-*+])%s+") or rest:match("^(%d+[.)])%s+")
  if marker then
    local after_marker = content_col + #marker + 1
    local checkbox = line:sub(after_marker + 1, after_marker + 3)
    if checkbox:match("^%[[ xX]%]$") then
      add_checkbox_highlight(marks, row, after_marker, checkbox)
    end

    if enabled(config, "bullet") then
      add_overlay(marks, row, content_col, "●", "RenderMarkdownBullet")
    end
  end
end

function M.parse_taskedit(ctx)
  local marks = {}
  local config = ctx.config
  local lines = vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)
  local in_annotation = false

  for index, line in ipairs(lines) do
    local body_start
    body_start, in_annotation = annotation_body_start(line, in_annotation)

    if body_start then
      local row = index - 1
      render_block(config, marks, row, line, body_start)
      render_inline(config, marks, row, line, body_start)
    end
  end

  return marks
end

function M.render(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)

  if vim.bo[buf].filetype ~= "taskedit" then
    return
  end

  local ok, state = pcall(require, "render-markdown.state")
  local config = ok and state.get(buf) or nil

  for _, mark in ipairs(M.parse_taskedit({ buf = buf, config = config })) do
    local opts = vim.tbl_extend("force", { strict = false, priority = 4096 }, mark.opts)
    pcall(vim.api.nvim_buf_set_extmark, buf, namespace, mark.start_row, mark.start_col, opts)
  end
end

function M.attach(buf)
  if vim.b[buf].taskedit_render_markdown_attached then
    M.render(buf)
    return
  end

  vim.b[buf].taskedit_render_markdown_attached = true
  M.render(buf)

  vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("taskedit_render_markdown_buffer_" .. buf, { clear = true }),
    buffer = buf,
    callback = function(event)
      M.render(event.buf)
    end,
  })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("taskedit_render_markdown", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "taskedit",
    callback = function(event)
      M.attach(event.buf)
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "taskedit" then
      M.attach(buf)
    end
  end
end

return M
