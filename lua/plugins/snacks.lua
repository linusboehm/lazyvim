local term_utils = require("util.toggletem_utils")
local home_dir = vim.fn.expand("~")

local logo = [[
                     ███████            
                   ██░░░░░░░██          
                 ██░░░░░░░░░░░█         
     ██         ██░░░░░░░░██░░█████████ 
   ██░░█        ██░░░░░░░░░░░░█▒▒▒▒▒▒█  
   █░░░░██       ██░░░░░░░░░░░████████  
  █░░░░░░░█        █░░░░░░░░░█          
 █░░░░░░░░░██████████░░░░░░░█           
██░░░░░░░░░░░░░░░░░░░░░░░░░░░██         
██░░░░░░░░░░░░░░░░█░░░░░░░░░░░░█        
 ██░░░░░░░░█░░░░░░░██░░░░░░░░░░█        
   █░░░░░░░░█████████░░░░░░░███         
    █████░░░░░░░░░░░░░░░████            
         ███████████████                ]]

LAST_CMD = nil

local idx = 1
local preferred = {
  "default",
  "bottom",
  "dropdown",
}

local set_next_preferred_layout = function(picker)
  idx = idx % #preferred + 1
  picker:set_layout(preferred[idx])
end

local layouts = require("snacks.picker.config.layouts")
local custom_l = vim.deepcopy(layouts.dropdown)
custom_l.layout[1].height = 0.15

local get_file = function()
  local uv = vim.uv or vim.loop
  local branch = ""
  if uv.fs_stat(".git") then
    local ret = vim.fn.systemlist("git branch --show-current")[1]
    if vim.v.shell_error == 0 then
      branch = ret
    end
  end

  local filekey = {
    tostring(vim.v.count1),
    "cmd_hist",
    svim.fs.normalize(assert(uv.cwd())),
    branch,
  }

  local root = vim.fn.stdpath("data") .. "/cmd_hist"
  local fname = Snacks.util.file_encode(table.concat(filekey, "|"))
  local file = root .. "/" .. fname
  file = svim.fs.normalize(file)
  return file
end

local function append_line_to_file(filename, line)
  if line == nil then
    return
  end
  local dir = filename:match("^(.*)/")
  if dir then
    os.execute("mkdir -p " .. dir)
  end
  local file, err = io.open(filename, "a")
  if not file then
    Snacks.notify.info("Could not open file: " .. err)
    return
  end
  file:write(line .. "\n")
  file:close()
  Snacks.notify.info("Appended to file: " .. filename)
  vim.cmd("e " .. vim.fn.fnameescape(filename))
end

local function read_pr_number(git_root)
  local pr_file = git_root .. "/PR_NUMBER"
  local file = io.open(pr_file, "r")
  if not file then
    Snacks.notify.error("PR_NUMBER file not found in git root")
    return nil
  end

  local pr_number = file:read("*l")
  file:close()

  if not pr_number or pr_number == "" then
    Snacks.notify.error("PR_NUMBER file is empty")
    return nil
  end

  pr_number = pr_number:match("^%s*(%d+)%s*$")
  if not pr_number then
    Snacks.notify.error("Invalid PR number in PR_NUMBER file")
    return nil
  end

  return pr_number
end

local function github_repo_info(git_root)
  local remote = vim.fn.systemlist({ "git", "-C", git_root, "remote", "get-url", "origin" })[1]
  if vim.v.shell_error ~= 0 or remote == nil or remote == "" then
    Snacks.notify.error("Could not read origin remote URL")
    return nil
  end

  local host, repo = remote:match("^git@([^:]+):(.+)$")
  if not host then
    host, repo = remote:match("^ssh://git@([^/]+)/(.+)$")
  end
  if not host then
    host, repo = remote:match("^https?://([^/]+)/(.+)$")
    if host then
      host = host:gsub("^[^@]+@", "")
    end
  end

  if not host or not repo then
    Snacks.notify.error("Unsupported origin remote URL: " .. remote)
    return nil
  end

  repo = repo:gsub("%.git$", "")
  local owner, name = repo:match("^([^/]+)/(.+)$")
  if not owner or not name then
    Snacks.notify.error("Unsupported origin repository path: " .. repo)
    return nil
  end

  return {
    host = host,
    path = repo,
    owner = owner,
    name = name,
    url = "https://" .. host .. "/" .. repo,
  }
end

local function open_url(url, title)
  Snacks.notify(("git url: [%s]"):format(url), { title = title })
  vim.fn.setreg("+", url)
  if vim.fn.has("nvim-0.10") == 0 then
    require("lazy.util").open(url, { system = true })
    return
  end
  vim.ui.open(url)
end

local function current_pr_line_context(range)
  local git_root = Snacks.git.get_root()
  if git_root == nil then
    Snacks.notify.error("Not in a git repository")
    return
  end

  local pr_number = read_pr_number(git_root)
  if not pr_number then
    return
  end

  local repo = github_repo_info(git_root)
  if not repo then
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    Snacks.notify.error("Current buffer has no file")
    return
  end

  git_root = vim.fn.fnamemodify(git_root, ":p"):gsub("/$", "")
  local full_path = vim.fn.fnamemodify(path, ":p")
  local prefix = git_root .. "/"
  if full_path:sub(1, #prefix) ~= prefix then
    Snacks.notify.error("Current file is not under the git root")
    return
  end

  local rel_path = full_path:sub(#prefix + 1)
  local changed = vim.fn.systemlist({ "git", "-C", git_root, "diff", "--name-only", "pr_base...pr_head", "--", rel_path })
  if vim.v.shell_error ~= 0 then
    Snacks.notify.error("Could not check PR files. Are pr_base and pr_head available?")
    return
  end
  if #changed == 0 then
    Snacks.notify.warn("Current file is not changed in PR #" .. pr_number)
    return
  end

  local head_sha = vim.fn.systemlist({ "git", "-C", git_root, "rev-parse", "pr_head" })[1]
  if vim.v.shell_error ~= 0 or head_sha == nil or head_sha == "" then
    Snacks.notify.error("Could not resolve pr_head")
    return
  end

  local line = vim.api.nvim_win_get_cursor(0)[1]
  local start_line = line
  if range then
    start_line = tonumber(range.start_line)
    line = tonumber(range.line)
    if not start_line or not line then
      Snacks.notify.error("Invalid PR comment range")
      return
    end
    if start_line > line then
      start_line, line = line, start_line
    end
  end

  local diff_anchor = "diff-" .. vim.fn.sha256(rel_path) .. "R" .. line
  local url = ("%s/pull/%s/files#%s"):format(repo.url, pr_number, diff_anchor)

  return {
    git_root = git_root,
    pr_number = pr_number,
    repo = repo,
    rel_path = rel_path,
    start_line = start_line,
    line = line,
    head_sha = head_sha,
    url = url,
  }
end

local function pr_context_label(context)
  if context.start_line and context.start_line ~= context.line then
    return ("%s:%d-%d"):format(context.rel_path, context.start_line, context.line)
  end
  return ("%s:%d"):format(context.rel_path, context.line)
end

local function visual_line_range()
  local start_line
  local end_line
  local mode = vim.fn.mode()
  if mode:match("^[vV\022]") then
    start_line = vim.fn.line("v")
    end_line = vim.fn.line(".")
  else
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    start_line = start_pos[2]
    end_line = end_pos[2]
  end

  if start_line <= 0 or end_line <= 0 then
    Snacks.notify.error("No visual selection found")
    return nil
  end
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  return { start_line = start_line, line = end_line }
end

local function open_current_line_in_pr()
  local context = current_pr_line_context()
  if not context then
    return
  end

  open_url(context.url, "PR Browse")
end

local function gh_result_error(result, fallback)
  local output = vim.trim((result.stderr or "") .. "\n" .. (result.stdout or ""))
  return output ~= "" and output or fallback
end

local function run_gh_graphql(context, payload, callback)
  local ok, encoded = pcall(vim.json.encode, payload)
  if not ok then
    Snacks.notify.error("Could not encode GraphQL payload: " .. tostring(encoded))
    return false
  end

  local tmp = vim.fn.tempname()
  local write_ok, write_result = pcall(vim.fn.writefile, { encoded }, tmp)
  if not write_ok or write_result ~= 0 then
    Snacks.notify.error("Could not write GraphQL payload")
    return false
  end

  local cmd = {
    "gh",
    "api",
    "graphql",
    "--hostname",
    context.repo.host,
    "--input",
    tmp,
  }

  local system_ok, system_err = pcall(vim.system, cmd, { cwd = context.git_root, text = true }, function(result)
    vim.schedule(function()
      vim.fn.delete(tmp)
      callback(result)
    end)
  end)

  if not system_ok then
    vim.fn.delete(tmp)
    Snacks.notify.error("Failed to run gh api: " .. tostring(system_err))
    return false
  end

  return true
end

local function parse_gh_json(result, fallback)
  if result.code ~= 0 then
    Snacks.notify.error(gh_result_error(result, fallback))
    return nil
  end

  local ok, decoded = pcall(vim.json.decode, result.stdout)
  if not ok then
    Snacks.notify.error("Could not parse GitHub response: " .. tostring(decoded))
    return nil
  end

  if decoded.errors and #decoded.errors > 0 then
    Snacks.notify.error(decoded.errors[1].message or fallback)
    return nil
  end

  return decoded
end

local function pr_comment_thread_input(context)
  local input = {
    path = context.rel_path,
    line = context.line,
    side = "RIGHT",
  }
  if context.start_line and context.start_line ~= context.line then
    input.startLine = context.start_line
    input.startSide = "RIGHT"
  end
  return input
end

local function add_thread_to_pending_review(context, review_id, body)
  local thread = pr_comment_thread_input(context)
  local query
  local variables = {
    reviewId = review_id,
    path = thread.path,
    line = thread.line,
    body = body,
  }
  if thread.startLine then
    query = [[
      mutation(
        $reviewId: ID!
        $path: String!
        $line: Int!
        $body: String!
        $startLine: Int!
        $startSide: DiffSide!
      ) {
        addPullRequestReviewThread(input: {
          pullRequestReviewId: $reviewId
          path: $path
          line: $line
          side: RIGHT
          startLine: $startLine
          startSide: $startSide
          body: $body
        }) {
          thread {
            id
          }
        }
      }
    ]]
    variables.startLine = thread.startLine
    variables.startSide = thread.startSide
  else
    query = [[
      mutation($reviewId: ID!, $path: String!, $line: Int!, $body: String!) {
        addPullRequestReviewThread(input: {
          pullRequestReviewId: $reviewId
          path: $path
          line: $line
          side: RIGHT
          body: $body
        }) {
          thread {
            id
          }
        }
      }
    ]]
  end

  local payload = {
    query = query,
    variables = variables,
  }

  Snacks.notify.info("Adding pending PR comment on " .. pr_context_label(context))
  run_gh_graphql(context, payload, function(result)
    local decoded = parse_gh_json(result, "Failed to add pending PR comment")
    if not decoded then
      return
    end

    Snacks.notify.info("Added pending PR comment")
  end)
end

local function create_pending_review_with_thread(context, pull_request_id, body)
  local thread = pr_comment_thread_input(context)
  local query
  local variables = {
    pullRequestId = pull_request_id,
    commitOID = context.head_sha,
    path = thread.path,
    line = thread.line,
    body = body,
  }
  if thread.startLine then
    query = [[
      mutation(
        $pullRequestId: ID!
        $commitOID: GitObjectID!
        $path: String!
        $line: Int!
        $body: String!
        $startLine: Int!
        $startSide: DiffSide!
      ) {
        addPullRequestReview(input: {
          pullRequestId: $pullRequestId
          commitOID: $commitOID
          threads: [{
            path: $path
            line: $line
            side: RIGHT
            startLine: $startLine
            startSide: $startSide
            body: $body
          }]
        }) {
          pullRequestReview {
            id
          }
        }
      }
    ]]
    variables.startLine = thread.startLine
    variables.startSide = thread.startSide
  else
    query = [[
      mutation($pullRequestId: ID!, $commitOID: GitObjectID!, $path: String!, $line: Int!, $body: String!) {
        addPullRequestReview(input: {
          pullRequestId: $pullRequestId
          commitOID: $commitOID
          threads: [{
            path: $path
            line: $line
            side: RIGHT
            body: $body
          }]
        }) {
          pullRequestReview {
            id
          }
        }
      }
    ]]
  end

  local payload = {
    query = query,
    variables = variables,
  }

  Snacks.notify.info("Creating pending PR review comment on " .. pr_context_label(context))
  run_gh_graphql(context, payload, function(result)
    local decoded = parse_gh_json(result, "Failed to create pending PR comment")
    if not decoded then
      return
    end

    Snacks.notify.info("Created pending PR comment")
  end)
end

local function create_pending_pr_comment(context, body)
  local payload = {
    query = [[
      query($owner: String!, $repo: String!, $number: Int!) {
        viewer {
          login
        }
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            id
            reviews(last: 100) {
              nodes {
                id
                state
                author {
                  login
                }
              }
            }
          }
        }
      }
    ]],
    variables = {
      owner = context.repo.owner,
      repo = context.repo.name,
      number = tonumber(context.pr_number),
    },
  }

  run_gh_graphql(context, payload, function(result)
    local decoded = parse_gh_json(result, "Failed to fetch pending PR reviews")
    if not decoded then
      return
    end

    local data = decoded.data or {}
    local viewer = data.viewer or {}
    local repository = data.repository or {}
    local pull_request = repository.pullRequest or {}
    if not pull_request.id then
      Snacks.notify.error("Could not resolve PR #" .. context.pr_number)
      return
    end

    local pending_review_id = nil
    local reviews = ((pull_request.reviews or {}).nodes) or {}
    for _, review in ipairs(reviews) do
      local author = review.author or {}
      if review.state == "PENDING" and author.login == viewer.login then
        pending_review_id = review.id
      end
    end

    if pending_review_id then
      add_thread_to_pending_review(context, pending_review_id, body)
    else
      create_pending_review_with_thread(context, pull_request.id, body)
    end
  end)
end

local function open_pending_pr_comment_buffer(context)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_name(buf, ("PR comment #%s %s"):format(context.pr_number, pr_context_label(context)))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })

  local columns = math.max(vim.o.columns, 40)
  local lines = math.max(vim.o.lines, 12)
  local width = math.min(math.max(math.floor(columns * 0.65), 64), columns - 4)
  local height = math.min(math.max(math.floor(lines * 0.35), 10), lines - 6)
  width = math.max(width, 40)
  height = math.max(height, 6)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(math.floor((lines - height) / 2) - 1, 0),
    col = math.max(math.floor((columns - width) / 2), 0),
    style = "minimal",
    border = "rounded",
    title = (" PR #%s %s "):format(context.pr_number, pr_context_label(context)),
    title_pos = "center",
    footer = " Ctrl-S submit | Ctrl-C abort | q abort ",
    footer_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true

  local done = false

  local close = function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    elseif vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  local abort = function()
    if done then
      return
    end
    done = true
    close()
    Snacks.notify.info("Aborted PR comment")
  end

  local submit = function()
    if done then
      return
    end

    local body = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    if body == "" then
      Snacks.notify.warn("PR comment is empty")
      return
    end

    done = true
    close()
    create_pending_pr_comment(context, body)
  end

  vim.keymap.set({ "n", "i", "v" }, "<C-s>", submit, { buffer = buf, desc = "Submit PR comment" })
  vim.keymap.set({ "n", "i", "v" }, "<C-c>", abort, { buffer = buf, desc = "Abort PR comment" })
  vim.keymap.set("n", "q", abort, { buffer = buf, desc = "Abort PR comment" })
  vim.cmd.startinsert()
end

local function add_pending_pr_comment(range)
  local context = current_pr_line_context(range)
  if not context then
    return
  end

  open_pending_pr_comment_buffer(context)
end

local function add_pending_pr_comment_for_visual_selection()
  local range = visual_line_range()
  if not range then
    return
  end

  add_pending_pr_comment(range)
end

function FindCmd(filename)
  Snacks.picker({
    title = "bash history",
    finder = "proc",
    cmd = "bash",
    args = { "-c", "tail -n 10000 " .. filename .. " | tac | awk '!/^#/ && !count[$0]++'" },
    -- name = "cmd",
    format = "text",
    preview = function(ctx)
      if ctx.item.buf and not ctx.item.file and not vim.api.nvim_buf_is_valid(ctx.item.buf) then
        ctx.preview:notify("Buffer no longer exists", "error")
        return
      end
      ctx.preview:set_lines({ ctx.item.text })
      ctx.preview:highlight({ ft = "bash", buf = ctx.buf })
    end,
    layout = custom_l,
    matcher = {
      filename_bonus = false,
      history_bonus = true,
    },
    sort = { fields = { "score:desc", "idx" } },
    win = { preview = { wo = { number = false, relativenumber = false, signcolumn = "no", wrap = true } } },
    confirm = function(picker, item)
      picker:close()
      if item then
        LAST_CMD = item.text
        term_utils.run_in_terminal(LAST_CMD)
      end
    end,
    formatters = { text = { ft = "bash" } },
  })
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    scroll = { enabled = false },
    dashboard = {
      enabled = true,
      preset = {
        header = logo,
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          -- { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "/", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = "󰒲 ", key = "L", desc = "Lazy", action = ":Lazy", enabled = package.loaded.lazy ~= nil },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
      sections = {
        { section = "header" },
        { section = "keys", gap = 0, padding = 3 },
        -- { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 1 },
        { pane = 1, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 3 },
        {
          pane = 1,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = vim.fn.isdirectory(".git") == 1,
          cmd = "git status --short --branch --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = "startup" },
        -- { section = "terminal", cmd = "curl -s 'wttr.in/?0'", pane = 1 },
        -- { section = "terminal",
        --   cmd = "$HOME/.config/nvim/lua/plugins/colorstrip",
        --   height = 2,
        --   padding = 1,
        -- },
      },
    },
    git = { enabled = true },

    lazygit = {
      enabled = true,
      interactive = true,
      config = {
        os = { editPreset = "" }, -- use `editPreset = "nvim-remote"` to edit in main nvim window
      },
      win = {
        keys = {
          ["jj"] = false,
        },
      },
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    input = {
      win = {
        keys = {
          i_del_word = { "<C-w>", "delete_WORD", mode = "i" },
          i_del_to_slash = { "<A-BS>", "delete_word", mode = "i" },
        },
        actions = {
          delete_WORD = function()
            vim.cmd("normal! diW<cr>")
          end,
          delete_word = function()
            vim.cmd("normal! diw<cr>")
          end,
        },
      },
    },
    gh = {
      enabled = true,
      scratch = {
        width = 100, -- width of scratch window for PR approvals/comments (0 = full width)
        -- height = 15, -- default height is already 15
      },
    },
    scratch = {
      enabled = true,
    },
    statuscolumn = { enabled = true },
    terminal = { enabled = true, interactive = false, win = { wo = { winbar = "" } } },
    words = { enabled = true },
    zen = {
      toggles = {
        dim = false,
        git_signs = false,
        diagnostics = true,
        inlay_hints = true,
        indent = false,
      },
    },
    indent = {
      enabled = true,
      indent = { hl = "SnacksIndent" },
      scope = { hl = "SnacksIndent", animate = { enabled = false } },
    },
    explorer = { enabled = true },
    picker = {
      previewers = { git = { native = true }, diff = { builtin = true, cmd = { "delta" } } },
      formatters = { file = { min_width = 10000 } },
      win = {
        input = {
          keys = {
            ["<c-l>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-h>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-v>"] = { "cycle_layouts", mode = { "i", "n" } },
          },
        },
        list = {
          keys = {
            ["<c-l>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-h>"] = { "focus_preview", mode = { "i", "n" } },
            ["<c-k>"] = { "focus_input", mode = { "i", "n" } },
            ["<c-j>"] = { "focus_input", mode = { "i", "n" } },
          },
        },
        preview = {
          keys = {
            ["<c-l>"] = { "focus_input", mode = { "i", "n" } },
            ["<c-h>"] = { "focus_input", mode = { "i", "n" } },
            ["<c-k>"] = { "focus_list", mode = { "i", "n" } },
            ["<c-j>"] = { "focus_list", mode = { "i", "n" } },
          },
        },
      },
      actions = {
        cycle_layouts = function(picker)
          set_next_preferred_layout(picker)
        end,
      },
      sources = {
        git_grep_hunks = {
          supports_live = false,
          format = function(item, picker)
            local file_format = Snacks.picker.format.file(item, picker)
            -- Use colorscheme's diff highlights for consistency
            vim.api.nvim_set_hl(0, "SnacksPickerGitGrepLineNew", { link = "DiffAdd" })
            vim.api.nvim_set_hl(0, "SnacksPickerGitGrepLineOld", { link = "DiffDelete" })

            -- Apply diff background to the line text while preserving syntax highlighting
            -- The treesitter highlights are separate metadata entries, so we just mark the text element
            local line_idx = #file_format - 1
            if type(file_format[line_idx]) == "table" and file_format[line_idx][1] then
              -- Apply the diff highlight to the text element
              -- The treesitter highlights will be composited on top
              if item.sign == "+" then
                file_format[line_idx][2] = "SnacksPickerGitGrepLineNew"
              else
                file_format[line_idx][2] = "SnacksPickerGitGrepLineOld"
              end
            end
            return file_format
          end,
          finder = function(_, ctx)
            local hcount = 0
            local header = {
              file = "",
              old = { start = 0, count = 0 },
              new = { start = 0, count = 0 },
            }
            local sign_count = 0
            return require("snacks.picker.source.proc").proc(
              ctx:opts({
                cmd = "git",
                args = { "diff", "--unified=0" },
                transform = function(item) ---@param item snacks.picker.finder.Item
                  local line = item.text
                  -- [[Header]]
                  if line:match("^diff") then
                    hcount = 3
                  elseif hcount > 0 then
                    if hcount == 1 then
                      header.file = line:sub(7)
                    end
                    hcount = hcount - 1
                  elseif line:match("^@@") then
                    local parts = vim.split(line:match("@@ ([^@]+) @@"), " ")
                    local old_start, old_count = parts[1]:match("-(%d+),?(%d*)")
                    local new_start, new_count = parts[2]:match("+(%d+),?(%d*)")
                    header.old.start, header.old.count = tonumber(old_start), tonumber(old_count) or 1
                    header.new.start, header.new.count = tonumber(new_start), tonumber(new_count) or 1
                    sign_count = 0
                    -- [[Body]]
                  elseif not line:match("^[+-]") then
                    sign_count = 0
                  elseif line:match("^[+-]%s*$") then
                    sign_count = sign_count + 1
                  else
                    item.sign = line:sub(1, 1)
                    item.file = header.file
                    item.line = line:sub(2)
                    if item.sign == "+" then
                      item.pos = { header.new.start + sign_count, 0 }
                      sign_count = sign_count + 1
                    else
                      item.pos = { header.new.start, 0 }
                      sign_count = 0
                    end
                    return true
                  end
                  return false
                end,
              }),
              ctx
            )
          end,
        },
      },
    },
    gitbrowse = {
      enabled = true,
      -- don't just try to open, but also copy to clipboard -> can just paste from remote box
      ---@param url string
      open = function(url)
        Snacks.notify(("git url: [%s]"):format(url), { title = "Git Browse" })
        vim.fn.setreg("+", url)
        if vim.fn.has("nvim-0.10") == 0 then
          require("lazy.util").open(url, { system = true })
          return
        end
        vim.ui.open(url)
      end,
      url_patterns = {
        -- other github addresses
        ["github.e"] = {
          branch = "/tree/{branch}",
          file = "/blob/{branch}/{file}#L{line_start}-L{line_end}",
          permalink = "/blob/{commit}/{file}#L{line_start}-L{line_end}",
          commit = "/commit/{commit}",
        },
      },
    },
    styles = {
      terminal = { keys = { gf = false, nav_h = false, nav_l = false } },
      notification = { wo = { wrap = true } },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    -- Register custom gh action
    local actions = require("snacks.gh.actions")
    actions.actions.open_in_diffview = {
      desc = "Open PR in Diffview",
      icon = "󰊢",
      type = "pr",
      priority = 150,
      action = function(item, ctx)
        vim.notify("Fetching PR details...", vim.log.levels.INFO)

        -- Use gh CLI to get the commit SHAs
        local gh_cmd = string.format("gh pr view %s --repo %s --json baseRefOid,headRefOid", item.number, item.repo)

        vim.system({ "sh", "-c", gh_cmd }, {}, function(result)
          vim.schedule(function()
            if result.code ~= 0 then
              vim.notify("Failed to fetch PR info: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
              return
            end

            local ok, pr_data = pcall(vim.json.decode, result.stdout)
            if not ok or not pr_data.baseRefOid or not pr_data.headRefOid then
              vim.notify("Failed to parse PR data", vim.log.levels.ERROR)
              return
            end

            local base_sha = pr_data.baseRefOid
            local head_sha = pr_data.headRefOid

            vim.notify("Fetching commits...", vim.log.levels.INFO)

            -- Fetch the specific commits
            vim.system({ "git", "fetch", "origin", head_sha, base_sha }, {}, function(fetch_result)
              vim.schedule(function()
                if fetch_result.code ~= 0 then
                  vim.notify("Fetch completed with warnings, opening diff...", vim.log.levels.WARN)
                end

                -- Use commit SHAs for the diff range
                local diff_range = string.format("%s...%s", base_sha, head_sha)

                -- Open in diffview
                local success, err = pcall(vim.cmd, "DiffviewOpen " .. diff_range .. " --imply-local")

                if not success then
                  vim.notify("Failed to open diff: " .. tostring(err), vim.log.levels.ERROR)
                  return
                end

                -- Store PR context for potential future use
                vim.g.current_pr = {
                  repo = item.repo,
                  number = item.number,
                  base = item.baseRefName,
                  head = item.headRefName,
                  baseOid = base_sha,
                  headOid = head_sha,
                }

                vim.notify(string.format("Opened PR #%d in Diffview", item.number))
              end)
            end)
          end)
        end)
      end,
    }
  end,
  -- stylua: ignore
  keys = {
    { "<leader>ua", false },
    { "<leader>z", function() Snacks.zen.zoom() end, desc = "Toggle Zoom", },
    { "<leader>Z", function() Snacks.zen() end, desc = "Toggle Zen Mode", },
    { "<leader>td", function() FindCmd(get_file()) end, desc = "search dir hist command", },
    { "<leader>tq", function() append_line_to_file(get_file(), LAST_CMD) end, desc = "Append command to dir history", },
    { "<leader>n", function() Snacks.picker.notifications({ win = { preview = { wo = { wrap = true } } } }) end, desc = "Notification History" },
    { "<leader>th", function() Snacks.terminal("htop") end, desc = "Terminal htop", },
    -- ---------------------------------
    -- picker keys
    { "<leader>,", false, desc = "Buffers" },
    -- { "<leader>sb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    -- { "<leader>/", function()
    --                   local res = Snacks.picker.get({source = "explorer"})
    --                   if #res > 0
    --                   then
    --                     res[1].input.win:focus()
    --                   else
    --                     Snacks.explorer({focus = "input"})
    --                   end
    --               end,
    --   desc = "Grep (Root Dir)" },
    { "<leader>:", false, desc = "Command History" },
    { "<leader>;", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader><space>", false, desc = "Find Files (Root Dir)" },
    -- disable find
    { "<leader>fb", false, desc = "Buffers" },
    { "<leader>fc", false, desc = "Find Config File" },
    { "<leader>ff", false, desc = "Find Files (Root Dir)" },
    { "<leader>fF", false, desc = "Find Files (cwd)" },
    { "<leader>fg", false, desc = "Find Files (git-files)" },
    { "<leader>fr", false, desc = "Recent" },
    { "<leader>fR", false, desc = "Recent (cwd)" },
    { "<leader>e", function() Snacks.explorer({focus = "input"}) end, desc = "File Explorer" },

    -- find
    { "<leader>sb", function() Snacks.picker.buffers() end, desc = "Buffers" },
    { "<leader>sc", LazyVim.pick.config_files(), desc = "Find Config File" },
    { "<leader>sf", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    -- { "<leader>sF", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" }, -- TODO(lboehm): find under dir of currently open file
    -- { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)" },
    -- { "<leader>br", LazyVim.pick("oldfiles"), desc = "Recent" },
    { "<leader>br", function() Snacks.picker.recent({ filter = { cwd = false }}) end, desc = "Recent" },
    -- { "<leader>br", function() Snacks.picker.recent() end, desc = "Recent" },
    -- { "<leader>fR", LazyVim.pick("oldfiles", { filter = { cwd = true }}), desc = "Recent (cwd)" },
    -- git
    { "<leader>gc", function() Snacks.picker.git_log() end, desc = "Git Log" },
    -- { "<leader>gD", function() Snacks.picker.git_diff() end, desc = "Git Diff (hunks)" }, -- TODO(lboehm): check this
    { "<leader>gs", function() Snacks.picker.git_status() end, desc = "Git Status" },
    { "<leader>gm", function() Snacks.gitbrowse({ branch = "master", open = function(url) vim.fn.setreg("+", url) Snacks.notify("Copied to clipboard: " .. url) end }) end, desc = "Copy git link (master)", mode = { "n", "v" } },
    { "<leader>gM", function() Snacks.gitbrowse() end, desc = "Copy git link (current branch)", mode = { "n", "v" } },
    { "<leader>gn", open_current_line_in_pr, desc = "Open current line in PR" },
    { "<leader>gN", add_pending_pr_comment, desc = "Add pending PR comment" },
    { "<leader>gN", add_pending_pr_comment_for_visual_selection, desc = "Add pending PR range comment", mode = "x" },

    -- Grep
    -- { "<leader>sb", function() Snacks.picker.lines() end, desc = "Buffer Lines" },
    -- { "<leader>sb", false, desc = "Buffer Lines" },
    { "<leader>sB", false, desc = "Grep Open Buffers" },
    { "<leader>sio", function() Snacks.picker.grep_buffers() end, desc = "Grep Open Buffers" },
    { "<leader>sib", function() local file_p = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.") Snacks.picker.grep({ glob = file_p }) end, desc = "Grep current buffer" },
    { "<leader>sis", function() local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":p:h") Snacks.picker.grep({ dirs = { path } }) end, desc = "Grep subdirs" },
    { "<leader>so", function() Snacks.picker.grep({dirs={home_dir .. "/vaults/work/", home_dir .. "/anki/"}}) end, desc = "Grep obsidian" },
    { "<leader>sih", function() Snacks.picker.pick("git_grep_hunks") end, desc = "Grep git hunks" },
    { "<leader>sl", function() Snacks.picker.grep({dirs={home_dir .. "/.local/share/nvim/lazy/"}}) end, desc = "Search lua/nvim plugins" },


    { "<leader>sg", LazyVim.pick("live_grep"), desc = "Grep (Root Dir)" },
    { "<leader>sG", LazyVim.pick("live_grep", { root = false }), desc = "Grep (cwd)" },
    -- { "<leader>sw", LazyVim.pick("grep_word"), desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
    { "<leader>sW", false, desc = "Visual selection or word (cwd)", mode = { "n", "x" } },
    -- { "<leader>sW", LazyVim.pick("grep_word", { buffers = true }), desc = "Visual selection or word in Buffers", mode = { "n", "x" } },
    { "<leader>sw", function() Snacks.picker.grep({search = function(picker) return picker:word() end, }) end, desc = "Visual selection or word (Root Dir)", mode = { "n", "x" } },
    { "<leader>sW", function() Snacks.picker.grep({search = function(picker) return picker:word() end, buffers = true}) end, desc = "Visual selection or word (buffers)", mode = { "n", "x" } },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = "Registers" },
    { "<leader>sa", function() Snacks.picker.autocmds() end, desc = "Autocmds" },
    { "<leader>sc", function() Snacks.picker.command_history() end, desc = "Command History" },
    { "<leader>sC", function() Snacks.picker.commands() end, desc = "Commands" },
    { "<leader>sd", function() Snacks.picker.diagnostics() end, desc = "Diagnostics" },
    { "<leader>sh", function() Snacks.picker.help() end, desc = "Help Pages" },
    { "<leader>sH", function() Snacks.picker.highlights() end, desc = "Highlights" },
    { "<leader>si", false, desc = "Icons" },
    { "<leader>sI", function() Snacks.picker.icons() end, desc = "Icons" },
    { "<leader>sj", function() Snacks.picker.jumps() end, desc = "Jumps" },
    { "<leader>sk", function() Snacks.picker.keymaps() end, desc = "Keymaps" },
    { "<c-/>", function() Snacks.terminal() end, desc = "Toggle terminal" },
    { "<c-_>", function() Snacks.terminal() end, desc = "Toggle terminal" },
    -- { "<leader>sl", function() Snacks.picker.loclist() end, desc = "Location List" },
    -- { "<leader>sl", false, desc = "Location List" },
    -- { "<leader>sM", function() Snacks.picker.man() end, desc = "Man Pages" },
    { "<leader>sM", false, desc = "Man Pages" },
    { "<leader>sm", function() Snacks.picker.marks() end, desc = "Marks" },
    { "<leader>sR", function() Snacks.picker.resume() end, desc = "Resume" },
    -- { "<leader>sq", function() Snacks.picker.qflist() end, desc = "Quickfix List" },
    { "<leader>sq", function() Snacks.picker.grep({dirs={home_dir .. "/.local/share/db_ui" }}) end, desc = "Search db queries" },
    { "<leader>uC", function() Snacks.picker.colorschemes() end, desc = "Colorschemes" },
    { "<leader>qp", function() Snacks.picker.projects() end, desc = "Projects" },
    { "<leader>go",
      function()
        -- Find git root
        local git_root = Snacks.git.get_root()
        if git_root == nil then
          Snacks.notify.error("Not in a git repository")
          return
        end

        local pr_number = read_pr_number(git_root)
        if not pr_number then
          return
        end

        -- Fetch PR data and open actions
        local Api = require("snacks.gh.api")
        Api.view(function(item)
          vim.schedule(function()
            if not item then
              Snacks.notify.error("Failed to fetch PR #" .. pr_number)
              return
            end
            require("snacks.gh.actions").actions.gh_actions.action(item, {
              items = { item },
              main = vim.api.nvim_get_current_win()
            })
          end)
        end, { type = "pr", number = tonumber(pr_number) })
      end,
      desc = "Open actions for PR from PR_NUMBER file"
    },
  },
}
