{ pkgs, ... }:

{
  # シェル
  programs.zsh.enable = true;

  # システムレベルのツール:
  # - vim: dotfiles 取り込み前の fallback エディタ
  # - gcc/gnumake: ビルド基盤
  # - mise: ユーザーツール (tmux, neovim, gh 等) のメタ管理。dotfiles の .mise.toml で宣言
  # - git: 1Password 統合 (op-ssh-sign) と密接なため NixOS で管理
  environment.systemPackages = with pkgs; [
    vim
    gcc
    gnumake
    mise
    git
  ];

  # dotfiles 取り込み前のデフォルトエディタ
  # (dotfiles 取り込み後は .zshrc 等で nvim へ上書き)
  environment.variables = {
    EDITOR = "vim";
    VISUAL = "vim";
  };
}
