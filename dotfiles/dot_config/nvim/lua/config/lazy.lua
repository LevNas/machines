-- lazy.nvim ブートストラップ + プラグイン読み込み
-- プラグイン本体は stdpath("data")/lazy/ に置かれ chezmoi 管理外 (mise 同様 user-tool 層)。
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },   -- lua/plugins/*.lua を自動読み込み
  -- 自動更新はしない (mise の latest 非追従方針に合わせ、更新は :Lazy update で明示的に)
  checker = { enabled = false },
  change_detection = { notify = false },
  -- ローカル開発プラグイン: dev = true のものはここから読む。
  -- 自作 cmigemo.nvim を ~/src/github.com/LevNas 配下から直接ロードする
  -- (ghq 配置と一致。GitHub 取得ではなくローカル checkout を使う)。
  dev = {
    path = "~/src/github.com/LevNas",
    patterns = { "cmigemo.nvim" },
  },
})
