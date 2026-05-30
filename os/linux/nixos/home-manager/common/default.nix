{ pkgs, ... }:

{
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    # エディタ (mise 経由で管理)
    # 移行済み: neovim

    # バージョン管理 (git は NixOS systemPackages、その他は mise 経由で管理)
    # 移行済み: ghq, gh, lazygit

    # 検索・ファイル操作 (mise 経由で管理: .mise.toml 参照)
    # 移行済み: ripgrep, fd, eza, zoxide, fzf, bat, yazi

    # ターミナル
    tmux

    # データ処理 (mise 経由で管理)
    # 移行済み: jq, yq

    # Claude Code 関連 (claude-code は nixpkgs 版で安定運用)
    claude-code
    # nodejs_22: mise 2026.5.6 の core:node が source build バグで使えないため home-manager に保留
    nodejs_22

    # dotfile管理
    chezmoi
  ];

  # home-manager 自身の管理を有効化
  programs.home-manager.enable = true;
}
