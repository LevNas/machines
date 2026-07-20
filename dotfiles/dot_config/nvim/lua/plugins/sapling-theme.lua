return {
  {
    -- see: https://github.com/catgoose/nvim-colorizer.lua
    "catgoose/nvim-colorizer.lua",
    event = "BufReadPre",
    opts = { -- set to setup table
    },
    config = function(_, opts)
      require("colorizer").setup(opts)
    end,
  },
  {
    "LevNas/sapling-theme.nvim",
    dependencies = { "rktjmp/lush.nvim", "folke/tokyonight.nvim" },
    dev = true,
    lazy = false,
    priority = 1000,
    config = function()
      local p = {
        -- 背景系
        bg_dark   = "#000000",
        bg_light  = "#232433",
        -- 前景系
        fg        = "#ced6f7",
        fg_dark   = "#a9b1d6",
        fg_gutter = "#3b4261",
        -- アクセントカラー
        black           = "#000000",
        white           = "#ffffff",
        red             = "#f7768e",
        green           = "#cff7d1",
        yellow          = "#ffff60",
        blue            = "#808bed",
        magenta         = "#bb9af7",
        cyan            = "#b9f4ee",
        lightred        = "#f7768e",
        lightgreen      = "#f2fdf2",
        lightyellow     = "#e0af68",
        lightblue       = "#7aa2f7",
        lightmagenta    = "#bb9af7",
        lightcyan       = "#7dcfff",
        darkred         = "#f7768e",
        darkgreen       = "#9ece6a",
        darkyellow      = "#fff1ad",
        darkblue        = "#7aa2f7",
        darkmagenta     = "#bb9af7",
        darkcyan        = "#7dcfff",
        orange          = "#ffeac2",
        gray            = "#444444",
        -- 以下は highlights から参照されているため必須。コメントアウトすると
        -- nil 参照で設定テーブルが空になり、nvim_set_hl がそのグループを
        -- 完全クリアする (base へフォールバックしない)。
        teal            = "#73daca",
        border          = "#545c7e",
        comment         = "#8e96b8",
        selection       = "#283457",
      }

      require("sapling-theme").setup({
        base = "tokyonight",
        palette = p,
        highlights = {
          -- 基本UI
          Normal       = { fg = p.white },
          NormalFloat  = { fg = p.fg, bg = p.bg_dark },
          FloatBorder  = { fg = p.border, bg = p.bg_dark },
          Cursor       = { fg = p.bg_dark, bg = p.lightgreen },
          CursorLine   = { bg = p.bg_light },
          CursorColumn = { bg = p.bg_light },
          Visual       = { bg = p.selection },
          LineNr       = { fg = p.fg_gutter },
          CursorLineNr = { fg = p.blue, bg = p.bg_light, bold = true },
          Search       = { fg = p.black, bg = p.darkyellow },
          IncSearch    = { fg = p.fg, bg = p.lightyellow },
          Pmenu        = { fg = p.fg, bg = p.bg_dark },
          PmenuSel     = { fg = p.fg, bg = p.selection, bold = true },
          PmenuSbar    = { bg = p.bg_light },
          PmenuThumb   = { bg = p.fg_gutter },
          StatusLine   = { fg = p.fg, bg = p.bg_dark },
          StatusLineNC = { fg = p.fg_gutter, bg = p.bg_dark },
          TabLine      = { fg = p.fg_gutter, bg = p.bg_dark },
          TabLineFill  = { bg = p.bg_dark },
          TabLineSel   = { fg = p.fg, bold = true },
          VertSplit    = { fg = p.border },
          WinSeparator = { fg = p.border },
          -- シンタックス
          Comment    = { fg = p.comment },
          Constant   = { fg = p.magenta },
          String     = { fg = p.lightgreen },
          Character  = { fg = p.lightgreen },
          Number     = { fg = p.lightyellow },
          Boolean    = { fg = p.lightyellow },
          Float      = { fg = p.lightyellow },
          Identifier = { fg = p.fg },
          Function   = { fg = p.blue, bold = true },
          Statement  = { fg = p.cyan },
          Keyword    = { fg = p.cyan },
          Operator   = { fg = p.cyan },
          PreProc    = { fg = p.magenta },
          Type       = { fg = p.teal },
          Special    = { fg = p.lightyellow },
          Delimiter  = { fg = p.fg_dark },
          Error      = { fg = p.red },
          Todo       = { fg = p.bg_dark, bg = p.darkyellow, bold = true },
          -- Treesitter
          ["@keyword"]          = { fg = p.cyan },
          ["@keyword.function"] = { fg = p.cyan },
          ["@keyword.return"]   = { fg = p.magenta },
          ["@function"]         = { fg = p.blue, bold = true },
          ["@function.builtin"] = { fg = p.teal },
          ["@function.call"]    = { fg = p.blue },
          ["@method"]           = { fg = p.blue },
          ["@method.call"]      = { fg = p.blue },
          ["@variable"]         = { fg = p.fg },
          ["@variable.builtin"] = { fg = p.magenta },
          ["@parameter"]        = { fg = p.lightyellow },
          ["@string"]           = { fg = p.green },
          ["@string.escape"]    = { fg = p.cyan },
          ["@string.regex"]     = { fg = p.teal },
          ["@number"]           = { fg = p.lightyellow },
          ["@boolean"]          = { fg = p.lightyellow },
          ["@constant"]         = { fg = p.magenta },
          ["@constant.builtin"] = { fg = p.magenta },
          ["@type"]             = { fg = p.teal },
          ["@type.builtin"]     = { fg = p.teal },
          ["@property"]         = { fg = p.fg },
          ["@field"]            = { fg = p.fg },
          ["@punctuation.delimiter"] = { fg = p.fg_dark },
          ["@punctuation.bracket"]   = { fg = p.fg_dark },
          ["@comment"]          = { fg = p.comment },
          ["@tag"]              = { fg = p.cyan },
          ["@tag.attribute"]    = { fg = p.lightyellow },
          ["@tag.delimiter"]    = { fg = p.fg_dark },
          -- LSP
          DiagnosticError = { fg = p.red },
          DiagnosticWarn  = { fg = p.yellow },
          DiagnosticInfo  = { fg = p.blue },
          DiagnosticHint  = { fg = p.teal },
          DiagnosticUnderlineError = { undercurl = true, sp = p.red },
          DiagnosticUnderlineWarn  = { undercurl = true, sp = p.yellow },
          DiagnosticUnderlineInfo  = { undercurl = true, sp = p.blue },
          DiagnosticUnderlineHint  = { undercurl = true, sp = p.teal },
          LspReferenceText  = { bg = p.bg_light },
          LspReferenceRead  = { bg = p.bg_light },
          LspReferenceWrite = { bg = p.bg_light },
          -- Git
          GitSignsAdd    = { fg = p.green },
          GitSignsChange = { fg = p.yellow },
          GitSignsDelete = { fg = p.red },
          -- flash.nvim (cmigemo migemo ジャンプ)
          -- base の tokyonight は遅延ロードされたプラグイン向けハイライトを
          -- 後追い適用するが、その時点の colors_name が sapling-theme のため
          -- 自分の担当外と判断してスキップする。ラッパーテーマ側で明示しないと
          -- ラベルが無スタイル (背景と同化) になるため、ここで定義する。
          FlashBackdrop = { fg = p.fg_gutter },
          FlashMatch    = { fg = p.black, bg = p.darkyellow }, -- Search と同系
          FlashLabel    = { fg = p.white, bg = p.red, bold = true }, -- マッチと対比
          FlashCurrent  = { fg = p.black, bg = p.lightyellow }, -- IncSearch と同系
          FlashPrompt      = { fg = p.fg, bg = p.bg_dark },
          FlashPromptIcon  = { fg = p.lightyellow },
        },
      })
      vim.cmd.colorscheme("sapling-theme")
    end,
  },
}
