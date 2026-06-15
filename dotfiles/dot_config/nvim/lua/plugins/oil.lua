-- oil.nvim: バッファとしてのファイラ。ディレクトリを通常バッファのように編集し、
-- 行の追加/削除/リネームがそのままファイル操作になる (vim の編集操作で fs を扱う)。
-- 旧 dotfiles から移植。ただし NixOS クリーン方針で以下を変更:
--   - fzf-lua bridge (bridge_fzf_oil.lua) は外した。新環境の picker は snacks に一本化済みのため。
--   - 旧設定の "<C-l>"=refresh は smart-splits の <C-l> (右split/tmux pane 移動) と衝突するので不採用。
--     oil は変更を自動反映するため手動 refresh の必要性は低い。
--   - 明示しても既定と同じになる git/preview_win/confirmation/progress 等の冗長ブロックは削除。
return {
  "stevearc/oil.nvim",
  -- snacks がアイコンを内包するが、oil は nvim-web-devicons / mini.icons を直接参照するため依存に明示。
  dependencies = { "nvim-tree/nvim-web-devicons" },
  -- default_file_explorer で netrw を乗っ取り `nvim <dir>` を oil で開くため、遅延ロードしない。
  lazy = false,
  ---@module "oil"
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = true,
    columns = { "icon", "permissions", "size", "mtime" },
    delete_to_trash = false,          -- trash-cli 等に依存しないよう実削除 (旧設定踏襲)
    skip_confirm_for_simple_edits = false,
    prompt_save_on_select_new_entry = true,
    constrain_cursor = "editable",    -- カーソルを編集可能領域 (ファイル名) に拘束
    keymaps = {
      ["g?"] = "actions.show_help",
      ["<CR>"] = "actions.select",
      ["<C-v>"] = "actions.select_vsplit",
      ["<C-s>"] = "actions.select_split",
      ["<C-t>"] = "actions.select_tab",
      ["<C-p>"] = "actions.preview",
      ["<Esc>"] = "actions.close",
      -- ["<C-l>"] は smart-splits の右移動を優先するため意図的に未割り当て (上のコメント参照)。
      ["-"] = "actions.parent",       -- 親ディレクトリへ
      ["_"] = "actions.open_cwd",     -- cwd を開く
      ["`"] = "actions.cd",           -- oil の場所へ :cd
      ["~"] = "actions.tcd",          -- タブローカル :tcd
      ["gs"] = "actions.change_sort",
      ["gx"] = "actions.open_external",
      ["g."] = "actions.toggle_hidden",
      ["g\\"] = "actions.toggle_trash",
    },
    view_options = {
      show_hidden = false,
      -- 先頭ドットを隠しファイル扱い (g. でトグル)
      is_hidden_file = function(name, _)
        return name:match("^%.") ~= nil
      end,
      natural_order = "fast",         -- file10 が file2 の後に並ぶ自然順
      case_insensitive = false,
      sort = {
        { "type", "asc" },            -- ディレクトリを先に
        { "name", "asc" },
      },
    },
  },
  keys = {
    { "<leader>e", "<cmd>Oil<cr>", desc = "Oil: 親ディレクトリを開く" },
  },
}
