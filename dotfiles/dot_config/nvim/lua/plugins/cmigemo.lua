-- cmigemo.nvim: 自作 migemo プラグイン (ローマ字 → 日本語あいまい検索)。
-- lazy の dev = true でローカル checkout (~/src/github.com/LevNas/cmigemo.nvim) を読む。
-- flash (f キーの migemo jump) と snacks.picker (migemo grep) の両方が依存する。
return {
  "LevNas/cmigemo.nvim",
  dev = true,
  opts = {
    -- migemo エンジンは rustmigemo (mise 管理: github:oguna/rustmigemo)。
    -- 辞書パスは cmigemo.nvim の DICT_CANDIDATES が
    -- ~/.local/share/migemo/migemo-compact-dict を auto-detect するので明示指定は不要
    -- (辞書は chezmoi run_once_install-migemo-dict.sh が配置)。
    -- rustmigemo の default 出力 (PCRE) は cmigemo.nvim 内部の
    -- pcre_to_vim_magic() で Vim regex に変換される。
    cmigemo_cmd = "rustmigemo",
  },
  event = "VeryLazy",
}
