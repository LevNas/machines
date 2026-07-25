-- flash.nvim: nvim バッファ内のラベルジャンプ (EasyMotion 系)。
-- cmigemo.nvim 連携でローマ字入力 → 日本語位置へジャンプ (s キー)。
-- budoux.lua 連携で文節境界ジャンプ (gb キー)。
--
-- 軽量化方針 (低スペック WSL 等で打鍵毎のもたつきを抑える):
--   * event を持たず keys のみで遅延ロード (起動時コストゼロ)
--   * highlight.backdrop = false … 打鍵毎に可視領域全体を減光する再描画を止める
--   * search.multi_window = false … 検索・ラベル先読み・読みインデックス構築を
--     現在ウィンドウに限定する。cmigemo 連携は可視テキスト全量を打鍵毎に照合する
--     ため、対象ウィンドウ数がそのまま打鍵コストに乗る。multi_window を戻す場合は
--     floating window を除外する search.exclude 関数の復活が必要 (git 履歴参照)
--   * modes.char / modes.search 無効 … f/t/F/T と / 検索は素の Vim のまま。
--     char は無効だと flash 側の autocmd 自体が登録されない。search は無効でも
--     <c-s> の toggle() で必要な時だけ有効化できる
--
-- キーマップは flash.nvim 標準 (s / S / r / R / <c-s>) に整合。s が migemo
-- ジャンプを兼ねる (ASCII 入力はリテラル層/migemo 層が拾うため素の jump は不要)。
-- グローバル search.mode は設定しない: migemo ジャンプは cmigemo 側の jump() が
-- 生成済みクロージャを force マージする。ここに migemo_mode (ファクトリ) を
-- 未呼び出しのまま代入すると、<c-s> トグル等の素の検索経路で mode(pattern) の
-- 戻り値が関数になり正規表現コンパイルが壊れる。
-- ※ flash はあくまで nvim 内が対象。tmux 別ペインへのジャンプは tmux 側
--    (tmux-jump / tmux-thumbs) が別レイヤーで担当する (層が違うため別エンジン)。
return {
  "folke/flash.nvim",
  dependencies = { "LevNas/cmigemo.nvim", "atusy/budoux.lua" },
  ---@type Flash.Config
  opts = {
    search = { multi_window = false },
    highlight = { backdrop = false },
    jump = { pos = "start" },
    modes = {
      char = { enabled = false },
      search = { enabled = false },
    },
  },
  config = function(_, opts)
    require("flash").setup(opts)
    require("cmigemo.ext.flash").setup()
  end,
  keys = {
    { "s", function() require("cmigemo.ext.flash").jump() end,
      mode = { "n", "x", "o" }, desc = "Flash: Migemo Jump" },
    { "S", function() require("flash").treesitter() end,
      mode = { "n", "x", "o" }, desc = "Flash: Treesitter Jump" },
    { "r", function() require("flash").remote() end,
      mode = "o", desc = "Flash: Remote" },
    { "R", function() require("flash").treesitter_search() end,
      mode = { "o", "x" }, desc = "Flash: Treesitter Search" },
    { "<c-s>", function() require("flash").toggle() end,
      mode = "c", desc = "Flash: Toggle Flash Search" },
    { "gb", function() require("cmigemo.ext.flash").bunsetsu() end,
      mode = { "n", "x", "o" }, desc = "Flash: Bunsetsu Jump (BudouX)" },
  },
}
