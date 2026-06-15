-- which-key.nvim: leader 等を押した後にキー候補をポップアップ表示 (旧 mini.clue の置き換え)。
--
-- 【独自拡張のフェイルセーフ方針】
-- which-key は v3 でポップアップのカーソル相対表示に非対応 (画面端のみ)。
-- カーソル付近表示は lua/ext/whichkey_cursor.lua の自前拡張で「窓を開いた後に再配置」する。
-- 拡張は which-key の critical path に乗せない:
--   - which-key.setup(opts) は素の opts で完結させる (拡張の存在を知らない)。
--   - 拡張の呼び出しは pcall で隔離 → 欠落/エラーでも which-key 起動は中断しない。
-- これにより「拡張あり=カーソル付近 / 拡張なし or 失敗=素の which-key (画面端)」が保証される。
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    delay = 200,                      -- 旧 mini.clue と同じ 200ms 遅延
    -- win/preset 等は素の既定のまま (拡張側で位置だけ後付け調整)。
  },
  config = function(_, opts)
    require("which-key").setup(opts)
    -- 独自拡張 (カーソル相対表示) を pcall で隔離して読む。
    -- 失敗しても which-key 本体は既に setup 済みなので素の状態で動作する。
    pcall(function()
      require("ext.whichkey_cursor").setup()
    end)
  end,
}
