-- noice.nvim: コマンドライン UI を浮動ポップアップ化し、入力エリアをカーソル付近に出す。
-- 旧 dotfiles の cmdline_popup (relative="cursor") を新環境へ反映。
--
-- 【最小構成方針】本構成は通知/メッセージを snacks.notifier が担うため、noice は cmdline 専用にする:
--   - messages.enabled = false / notify.enabled = false で noice にメッセージ系を乗っ取らせない
--     (snacks と二重通知・競合させない)。これにより依存は nui.nvim のみで足りる (nvim-notify 不要)。
--   - cmdline と補完 popupmenu だけ noice が担当する。
return {
  "folke/noice.nvim",
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    cmdline = {
      enabled = true,
      view = "cmdline_popup",   -- ":" や "/" をカーソル付近の浮動窓に出す
    },
    messages = { enabled = false }, -- メッセージは snacks/標準に任せる
    notify = { enabled = false },   -- 通知は snacks.notifier に任せる
    popupmenu = { enabled = true }, -- cmdline 補完メニュー
    presets = {
      bottom_search = false,        -- "/" 検索も bottom ではなく cmdline_popup (= カーソル付近) に出す
      long_message_to_split = true, -- 長いメッセージは split へ
    },
    views = {
      -- ここが本題: 入力エリアをカーソル相対で配置する (旧 dotfiles 踏襲)
      cmdline_popup = {
        relative = "cursor",
        position = { row = 2, col = 0 },  -- カーソルの 2 行下から
        size = { width = "auto", height = "auto" },
        border = { style = "rounded" },
      },
    },
  },
}
