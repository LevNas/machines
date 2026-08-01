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
  opts = function()
    -- 購読フィードは 1Password → chezmoi apply で生成される ext/feeds.lua が持つ
    -- (公開 repo に購読リストを置かない。編集は 1Password 側 → apply で反映)。
    -- 生成物が無い環境 (apply 前・project マシン) では空リストで起動する。
    -- 空でも feeds キー自体は必須: feed.nvim の setup は resolve 済み config でなく
    -- 生 opts の feeds を DB 同期に渡すため、nil だと pairs(nil) で起動時エラーになる。
    -- なお :Feed soft_sync / hard_sync は config を source of truth として
    -- config 外フィードを DB から削除する (:Feed load_opml との併用は不可)。
    local ok, feeds = pcall(require, "ext.feeds")
    return { feeds = ok and feeds or {} }
  end,
}
