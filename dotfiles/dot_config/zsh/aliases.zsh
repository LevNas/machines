# ~/.config/zsh/aliases.zsh — chezmoi managed
# dot_zshrc 末尾の `for _f in ~/.config/zsh/*.zsh` で mise activate 後に source される。
# 可搬性のため mise 管理ツール前提の alias は存在確認付き (未導入環境でも壊れない)。

# --- eza (ls 置換) ---
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lh --icons --group-directories-first --git'
  alias la='eza -lah --icons --group-directories-first --git'
  alias lt='eza --tree --level=2 --icons'
fi

# --- bat (cat 置換) ---
command -v bat &>/dev/null && alias cat='bat --paging=never'

# --- git 略記 (git は NixOS systemPackages で常在) ---
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

# 注: `cd='z'` (zoxide) は init と結合させるため dot_zshrc 本体に置いている (順序事故防止)。
