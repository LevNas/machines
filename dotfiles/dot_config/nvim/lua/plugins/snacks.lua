-- snacks.nvim (picker): ファイル/grep/git/gh の統合ピッカー。
-- 独自 grep finder: "#tag" 構文で先頭30行のタグ AND 絞り込み、無タグ時は
-- cmigemo grep にフォールバック (ローマ字 → 日本語あいまい grep)。
-- cmigemo.nvim 不在でも pcall で素の snacks grep に degrade する。

-- Helper: UTF-8 safe first character extraction
local function utf8_first_char(s)
  if not s or s == "" then return "" end
  local b = s:byte(1)
  local len = 1
  if b >= 0xF0 then len = 4
  elseif b >= 0xE0 then len = 3
  elseif b >= 0xC0 then len = 2
  end
  return s:sub(1, len)
end

-- Helper: search directories (cwd + machine-local extra roots + cwd's .claude/knowledge)
local function get_search_dirs()
  local cwd = vim.fn.getcwd()
  local home = vim.env.HOME or os.getenv("HOME") or ""
  local dirs = { cwd }
  -- 追加の横断検索ルートはマシンローカル設定 (chezmoi data) 由来の ext.search_roots から取り込む。
  -- 環境差を設定で吸収するため。モジュールが無い/空なら cwd 由来の generic 検索のみに降格する。
  local ok, extra_roots = pcall(require, "ext.search_roots")
  if ok and type(extra_roots) == "table" then
    for _, d in ipairs(extra_roots) do
      if d ~= cwd and vim.fn.isdirectory(d) == 1 then
        table.insert(dirs, d)
      end
    end
  end
  -- chezmoi source (全機共通の標準パス)
  local chezmoi = home .. "/.local/share/chezmoi"
  if cwd ~= chezmoi and vim.fn.isdirectory(chezmoi) == 1 then
    table.insert(dirs, chezmoi)
  end
  -- cwd 配下の .claude/knowledge (cwd から導出する generic ルート)
  local cwd_knowledge = cwd .. "/.claude/knowledge"
  if vim.fn.isdirectory(cwd_knowledge) == 1 then
    table.insert(dirs, cwd_knowledge)
  end
  return dirs
end

-- Helper: parse search input into tags and text parts
-- e.g. "#zmk #keyboard cornix build" -> tags={"zmk","keyboard"}, text="cornix build"
local function parse_search(search)
  local tags = {}
  local text_parts = {}
  for word in search:gmatch("%S+") do
    if word:match("^#%S") then
      table.insert(tags, word:sub(2)) -- strip #
    else
      table.insert(text_parts, word)
    end
  end
  return tags, table.concat(text_parts, " ")
end

-- Helper: check if file's first 30 lines contain all tags
local function file_has_tags(path, tags, cache)
  if cache[path] ~= nil then return cache[path] end
  local f = io.open(path, "r")
  if not f then
    cache[path] = false
    return false
  end
  local lines = {}
  for i = 1, 30 do
    local line = f:read("*l")
    if not line then break end
    lines[i] = line
  end
  f:close()
  local content = table.concat(lines, "\n")
  for _, tag in ipairs(tags) do
    if not content:find("#" .. tag, 1, true) then
      cache[path] = false
      return false
    end
  end
  cache[path] = true
  return true
end

-- Helper: grep finder with hashtag AND filter + cmigemo fallback
local function grep_finder(opts, ctx)
  local search = ctx.filter and ctx.filter.search or ""
  local tags, text = parse_search(search)

  -- No tags: default cmigemo-enhanced grep
  if #tags == 0 then
    local ok, cmigemo_snacks = pcall(require, "cmigemo.ext.snacks")
    if ok then
      return cmigemo_snacks.grep(opts, ctx)
    end
    return require("snacks.picker.source.grep").grep(opts, ctx)
  end

  -- Has tags: grep by first tag or text, then AND filter by remaining tags
  if text ~= "" then
    -- Text + tags: grep by text (with cmigemo), AND filter by all tags
    ctx.filter.search = text
    local ok, cmigemo_snacks = pcall(require, "cmigemo.ext.snacks")
    local inner
    if ok then
      inner = cmigemo_snacks.grep(opts, ctx)
    else
      inner = require("snacks.picker.source.grep").grep(opts, ctx)
    end
    ctx.filter.search = search -- restore
    local file_cache = {}
    return function(cb)
      inner(function(item)
        if item.file and file_has_tags(item.file, tags, file_cache) then
          cb(item)
        end
      end)
    end
  else
    -- Tags only: grep by first tag, AND filter by rest
    ctx.filter.search = "#" .. tags[1]
    local inner = require("snacks.picker.source.grep").grep(opts, ctx)
    ctx.filter.search = search -- restore
    if #tags <= 1 then
      return inner
    end
    local extra_tags = { unpack(tags, 2) }
    local file_cache = {}
    return function(cb)
      inner(function(item)
        if item.file and file_has_tags(item.file, extra_tags, file_cache) then
          cb(item)
        end
      end)
    end
  end
end

-- State for path abbreviation toggle
local abbrev_enabled = true

return {
  {
    "folke/snacks.nvim",
    dependencies = { "LevNas/cmigemo.nvim" },
    priority = 1000,
    lazy = false,
    ---@class snacks.Config
    opts = {
      picker = {
        enabled = true,
        layout = {
          cycle = false,
        },
        matcher = {
          cwd_bonus = true,
          frecency = true,
          history_bonus = true,
        },
        formatters = {
          file = {
            truncate = "left",
          },
        },
        sources = {
          grep = {
            finder = grep_finder,
          },
        },
        actions = {
          flash = function(picker)
            require("flash").jump({
              pattern = "^",
              label = { after = { 0, 0 } },
              search = {
                mode = "search",
                exclude = {
                  function(win)
                    return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                  end,
                },
              },
              action = function(match)
                local idx = picker.list:row2idx(match.pos[1])
                picker.list:_move(idx, true, true)
              end,
            })
          end,
          toggle_abbrev = function(picker)
            abbrev_enabled = not abbrev_enabled
            -- Clear cached paths to force re-render
            for _, item in ipairs(picker.list.items or {}) do
              item._path = nil
            end
            picker.list:redraw()
          end,
        },
        on_change = function(picker, item)
          if not item then return end
          local path = item.file or item.filename or ""
          if path == "" then return end
          local dir = vim.fn.fnamemodify(path, ":h") .. "/"
          local fname = vim.fn.fnamemodify(path, ":t")
          pcall(vim.api.nvim_win_set_config, picker.list.win.win, {
            footer = { { " " .. dir, "Comment" }, { fname .. " ", "Normal" } },
            footer_pos = "right",
          })
        end,
      },
    },
    config = function(_, opts)
      require("snacks").setup(opts)
      local ok, cmigemo_snacks = pcall(require, "cmigemo.ext.snacks")
      if ok then
        cmigemo_snacks.setup()
      end
    end,
    keys = {
      { "<leader><space>", function() Snacks.picker.smart() end, desc = "SnacksPicker Smart Find Files" },
      { "<leader>fg", function() Snacks.picker.grep({ dirs = get_search_dirs() }) end, desc = "SnacksPicker Grep" },
      { "<leader>:", function() Snacks.picker.command_history() end, desc = "SnacksPicker Command History" },
      { "<leader>ff", function() Snacks.picker.files({ dirs = get_search_dirs() }) end, desc = "SnacksPicker Find Files" },
      { "<leader>fb", function() Snacks.picker.buffers() end, desc = "SnacksPicker Buffers" },
      { "<leader>sm", function() Snacks.picker.marks() end, desc = "SnacksPicker Marks" },
      { "<leader>fp", function() Snacks.picker.projects() end, desc = "SnacksPicker Projects" },
      { "<leader>fh", function() Snacks.picker.recent() end, desc = "SnacksPicker OldFiles" },

      -- git
      { "<leader>gb", function() Snacks.picker.git_branches() end, desc = "SnacksPicker Git Branches" },
      { "<leader>gl", function() Snacks.picker.git_log() end, desc = "SnacksPicker Git Log" },
      { "<leader>gL", function() Snacks.picker.git_log_line() end, desc = "SnacksPicker Git Log Line" },
      { "<leader>gs", function() Snacks.picker.git_status() end, desc = "SnacksPicker Git Status" },
      { "<leader>gS", function() Snacks.picker.git_stash() end, desc = "SnacksPicker Git Stash" },
      { "<leader>gd", function() Snacks.picker.git_diff() end, desc = "SnacksPicker Git Diff (Hunks)" },
      { "<leader>gf", function() Snacks.picker.git_log_file() end, desc = "SnacksPicker Git Log File" },
      -- gh
      { "<leader>gi", function() Snacks.picker.gh_issue() end, desc = "SnacksPicker GitHub Issues (open)" },
      { "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, desc = "SnacksPicker GitHub Issues (all)" },
      { "<leader>gp", function() Snacks.picker.gh_pr() end, desc = "SnacksPicker GitHub Pull Requests (open)" },
      { "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, desc = "SnacksPicker GitHub Pull Requests (all)" },
    },
  },
}
