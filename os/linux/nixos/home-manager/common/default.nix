{ pkgs, ... }:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # エディタ
    neovim

    # バージョン管理 (git は NixOS systemPackages で管理)
    ghq
    gh
    lazygit

    # 検索・ファイル操作
    ripgrep
    fd
    eza
    zoxide
    fzf
    bat
    yazi

    # ターミナル
    tmux

    # データ処理
    jq
    yq

    # Claude Code 関連
    claude-code
    nodejs_22

    # dotfile管理
    chezmoi
  ];

  # home-manager 自身の管理を有効化
  programs.home-manager.enable = true;
}
