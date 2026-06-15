-- smart-splits.nvim: nvim split ↔ tmux pane をシームレスに移動/リサイズ。
-- tmux 側の is_vim 判定 Ctrl-hjkl バインド (tmux.conf) と対で機能する。
--   nvim ペイン内 Ctrl-h → tmux が nvim へ送出 → smart-splits が
--   「nvim split 内移動」か「端なら tmux pane へ越境」かを判断 (multiplexer_integration="tmux")。
-- キー体系は tmux と統一: Ctrl-hjkl=移動 / Alt-hjkl=リサイズ。
return {
  "mrjones2014/smart-splits.nvim",
  opts = {
    at_edge = "stop",                  -- 端で停止 (tmux 側 #{pane_at_*} 停止と揃える)
    multiplexer_integration = "tmux",  -- nvim の端で tmux pane へ越える
    default_amount = 3,
  },
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end,  desc = "Move to left split" },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end,  desc = "Move to below split" },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end,    desc = "Move to above split" },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end, desc = "Move to right split" },
    { "<A-h>", function() require("smart-splits").resize_left() end,  desc = "Resize split left" },
    { "<A-j>", function() require("smart-splits").resize_down() end,  desc = "Resize split down" },
    { "<A-k>", function() require("smart-splits").resize_up() end,    desc = "Resize split up" },
    { "<A-l>", function() require("smart-splits").resize_right() end, desc = "Resize split right" },
  },
}
