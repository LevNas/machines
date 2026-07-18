-- cmigemo.nvim: 自作 migemo プラグイン (ローマ字 → 日本語あいまい検索)。
-- lazy の dev = true でローカル checkout (~/src/github.com/LevNas/cmigemo.nvim) を読む。
-- flash (f キーの migemo jump) と snacks.picker (migemo grep) の両方が依存する。
return {
  "LevNas/cmigemo.nvim",
  dev = true,
  opts = {
    -- migemo エンジンは自動検出 (cmigemo → rustmigemo の順)。
    -- NixOS 機は本家 cmigemo (home-manager 管理) ＋同梱の SKK-L 系辞書を使う
    -- (辞書はバイナリの install prefix 相対で自動検出)。compact-dict は複合語語彙の
    -- 欠落でヒット率が落ちるため、cmigemo が無いホストのみ rustmigemo (mise 管理) ＋
    -- ~/.local/share/migemo/migemo-compact-dict へ fallback する
    -- (辞書は chezmoi run_once_install-migemo-dict.sh が配置)。
    -- どちらのバックエンドも PCRE 出力を cmigemo.nvim 内部の pcre_to_vim_magic() で
    -- Vim regex に変換する。
  },
  event = "VeryLazy",
}
