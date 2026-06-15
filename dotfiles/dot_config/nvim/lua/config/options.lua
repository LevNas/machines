-- 基本オプション (最小・sane defaults)。育てる過程で追記していく。
local opt = vim.opt

opt.termguicolors = true        -- 24bit color: tmux(Tc)/wezterm への truecolor 連携前提
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"   -- OS クリップボード連携
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true           -- 縦分割は右に
opt.splitbelow = true           -- 横分割は下に
opt.undofile = true
opt.signcolumn = "yes"
opt.scrolloff = 4
