{ pkgs, ... }:

{
  # シェル
  programs.zsh.enable = true;

  # 開発ツール
  environment.systemPackages = with pkgs; [
    # エディタ
    vim
    neovim

    # バージョン管理
    git
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

    # ビルドツール
    gcc
    gnumake

    # Claude Code 関連
    claude-code
    nodejs_22

    # dotfile管理
    chezmoi
  ];
}
