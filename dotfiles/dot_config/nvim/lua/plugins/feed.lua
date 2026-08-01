-- feed.nvim: nvim 内で完結する RSS/Atom リーダー (:Feed で起動、cmd で遅延ロード)。
-- 外部依存 (:checkhealth feed で確認可):
--   curl   … フィード取得
--   pandoc … 記事 HTML の Markdown 変換 (mise conf.d/personal.toml で導入)
--   treesitter xml / html パーサ … 記事パース (plugins/treesitter.lua の languages で導入)
-- 検索 UI は導入済みプラグインの自動検出で snacks.picker を使う。
-- 個人愛用ツールのため project マシンには配布しない (.chezmoiignore の gating 対象)。
return {
  "neo451/feed.nvim",
  cmd = "Feed",
  opts = {
    -- 購読フィードはここに追記していく (例: "https://example.com/rss.xml" や
    -- { "https://...", name = "...", tags = { "tech" } })。
    -- 空でも feeds キー自体は必須: feed.nvim の setup は resolve 済み config でなく
    -- 生 opts の feeds を DB 同期に渡すため、省略すると pairs(nil) で起動時エラーになる。
    feeds = {},
  },
}
