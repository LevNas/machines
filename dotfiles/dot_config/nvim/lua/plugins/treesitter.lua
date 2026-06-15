-- nvim-treesitter (main ブランチ = リライト版): 構文ハイライト + treesitter ベース indent。
-- 旧 dotfiles と同じ main ブランチ流儀で揃える (master の configs.setup{ensure_installed,highlight} は
-- main では廃止。代わりに .install(langs) でパーサ取得 + FileType autocmd で vim.treesitter.start())。
-- NixOS 向け調整: powershell を除外し、nix / vim / vimdoc / query / diff / git* / regex を追加。
-- ※ flash の S (treesitter jump) / modes.treesitter はここでパーサが入って初めて機能する。

-- パーサ導入対象。育てる過程で追記していく。
local languages = {
  -- nvim 自身を編集する基盤
  "lua", "luadoc", "vim", "vimdoc", "query", "regex", "comment",
  -- NixOS 設定編集
  "nix",
  -- シェル / 設定ファイル
  "bash", "make", "toml", "yaml", "json", "json5", "jsonc", "properties", "tmux",
  -- git
  "diff", "git_config", "gitcommit", "git_rebase",
  -- ドキュメント
  "markdown", "markdown_inline",
  -- その他よく触る言語
  "jq", "ruby", "typescript", "xml", "todotxt",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    dependencies = {
      {
        -- 画面上端に現在のスコープ (関数/見出し等) を貼り付ける sticky context。
        "nvim-treesitter/nvim-treesitter-context",
        opts = {
          max_lines = 6,            -- context 行の上限
          multiline_threshold = 4,  -- 1 コンテキストの最大表示行
        },
      },
    },
    config = function()
      -- パーサのインストール (非同期)。未導入言語は :TSInstall <lang> で個別追加も可。
      require("nvim-treesitter").install(languages)

      -- FileType ごとに treesitter ハイライト + indent を有効化 (main ブランチの作法)。
      local group = vim.api.nvim_create_augroup("treesitter_setup", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = languages,
        callback = function(args)
          vim.treesitter.start(args.buf)  -- 構文ハイライト開始
          -- treesitter ベースの indentexpr (= キーストロークで構文に沿った字下げ)
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },
}
