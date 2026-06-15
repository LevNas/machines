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

    # Claude 系ツール (mise 経由で管理)
    # 移行済み: claude-code (Wave 5: aqua:anthropics/claude-code), nodejs_22 (Wave 4: aqua:nodejs/node)
    # ccusage は mise 直接管理せず公式推奨の `bunx ccusage` で実行 (bun は mise core backend)

    # dotfile管理
    chezmoi
  ];

  # tmux プラグイン (TPM 不使用方針): プラグイン本体を Nix store から取得し、
  # 安定パス ~/.config/tmux/plugins/ へ symlink する。配線 (run-shell・キー割当) は
  # chezmoi 管理の tmux.conf 側に置き、「Nix=依存解決 / chezmoi=設定」の責務分担を維持。
  # ruby (jump) / Rust バイナリ (thumbs) の依存は各 derivation 内に閉じている (store パス埋込)。
  # ※ ~/.config/tmux は chezmoi が tmux.conf のみ管理 (exact_ 無し) のため plugins/ は共存する。
  home.file = {
    ".config/tmux/plugins/jump".source =
      "${pkgs.tmuxPlugins.jump}/share/tmux-plugins/jump";
    ".config/tmux/plugins/thumbs".source =
      "${pkgs.tmuxPlugins.tmux-thumbs}/share/tmux-plugins/tmux-thumbs";
  };

  # home-manager 自身の管理を有効化
  programs.home-manager.enable = true;
}
