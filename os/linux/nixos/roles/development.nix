{ pkgs, ... }:

{
  # シェル
  programs.zsh.enable = true;

  # システムレベルの開発ツール (ユーザーツールは home-manager/common/ で管理)
  environment.systemPackages = with pkgs; [
    vim
    gcc
    gnumake
  ];
}
