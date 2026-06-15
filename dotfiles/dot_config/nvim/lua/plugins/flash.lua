-- flash.nvim: nvim バッファ内のラベルジャンプ (EasyMotion 系)。
-- cmigemo.nvim 連携でローマ字入力 → 日本語位置へジャンプ (f キー)。
-- budoux.lua 連携で文節境界ジャンプ (gb キー)。
-- ※ flash はあくまで nvim 内が対象。tmux 別ペインへのジャンプは tmux 側
--    (tmux-jump / tmux-thumbs) が別レイヤーで担当する (層が違うため別エンジン)。
return {
  "folke/flash.nvim",
  dependencies = { "LevNas/cmigemo.nvim", "atusy/budoux.lua" },
  event = "VeryLazy",
  ---@type Flash.Config
  opts = {
    labels = "asdfghjklqwertyuiopzxcvbnm",
    search = {
      exclude = {
        "notify",
        "cmp_menu",
        "noice",
        "flash_prompt",
        function(win)
          local cfg = vim.api.nvim_win_get_config(win)
          -- exclude non-focusable windows
          if not cfg.focusable then
            return true
          end
          -- exclude all floating windows (relative ~= "" or zindex set)
          if cfg.relative ~= "" or cfg.zindex then
            return true
          end
          return false
        end,
      },
    },
    modes = {
      char = { enabled = false },
      search = { enabled = false },
      treesitter = { enabled = true },
    },
    jump = { pos = "start" },
  },
  config = function(_, opts)
    local cmigemo_flash = require("cmigemo.ext.flash")
    opts.search.mode = cmigemo_flash.migemo_mode
    require("flash").setup(opts)
    cmigemo_flash.setup()
  end,
  keys = {
    { "f", function() require("cmigemo.ext.flash").jump() end,
      mode = { "n", "x", "o" }, desc = "Flash: Migemo Jump" },
    { "F", function() require("flash").jump() end,
      mode = { "n", "x", "o" }, desc = "Flash: Jump" },
    { "S", function() require("flash").treesitter() end,
      mode = { "n", "x", "o" }, desc = "Flash: Treesitter Jump" },
    { "r", function() require("flash").remote() end,
      mode = "o", desc = "Flash: Remote" },
    { "R", function() require("flash").treesitter_search() end,
      mode = { "o", "x" }, desc = "Flash: Treesitter Search" },
    { "gb", function() require("cmigemo.ext.flash").bunsetsu() end,
      mode = { "n", "x", "o" }, desc = "Flash: Bunsetsu Jump (BudouX)" },
  },
}
