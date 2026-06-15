-- ~/.config/nvim/init.lua — chezmoi managed
-- 新 machines の最小 nvim 設定。lazy.nvim を土台にプラグインを段階的に育てる。
-- (旧 dotfiles の WSL 固有コード等は持ち込まず、NixOS クリーンから再構築)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.autocmds")
require("config.lazy")
