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

    # 日本語検索 (migemo)
    # cmigemo は GitHub releases 無し (source-only) のため mise に乗らず Nix 層で管理。
    # SKK-L 系テキスト辞書 (share/migemo/utf-8/migemo-dict) を同梱し、cmigemo.nvim が
    # バイナリの install prefix 相対で辞書を自動検出する。rustmigemo + compact-dict は
    # 複合語語彙の欠落によりヒット率が落ちるため、本家辞書へ回帰した。
    # cmigemo が無いホストでは cmigemo.nvim が rustmigemo (mise 管理) へ fallback する。
    # 根拠: 個人ナレッジ KB エントリ 20260718-153000-cmigemo-quality-diagnosis-compact-dict-regression
    cmigemo
    # mecab は cmigemo.nvim の flash 読みモード用 (可視テキストを読み化してかな照合)。
    # release 無しのため mise に乗らず Nix 層 (cmigemo と同一判定)。nixpkgs 版は
    # ipadic 同梱で PATH にあれば cmigemo.nvim が自動検出する (無ければ migemo のみで動作)。
    mecab

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

    # fcitx5 の XDG autostart を無効化 (Plasma Wayland 専用前提)。
    # i18n.inputMethod が systemPackages に入れる fcitx5 はパッケージ同梱の
    # etc/xdg/autostart/org.fcitx.Fcitx5.desktop を持ち、systemd-xdg-autostart-generator が
    # app-org.fcitx.Fcitx5@autostart.service を生成する。一方 Plasma Wayland では KWin が
    # input-method-v2 経由で fcitx5 を起動するのが正で、両者がログイン時に二重起動を競合する。
    # systemd autostart 側が勝つと KWin 管理外 fcitx5 が単一インスタンス制約 (dbus org.fcitx.Fcitx5)
    # で正規の v2 起動を塞ぎ、日本語入力が突然死ぬ (protocol 0)。
    # Hidden=true でユーザ autostart を最優先で無効化し、起動を KWin に一本化する。
    # ※ X11 セッションや KWin 以外の WM を使うホストを追加する場合は要再検討。
    # 根拠: 個人ナレッジ KB エントリ 20260616-160000-plasma-wayland-fcitx5-kwin-vs-systemd-autostart-conflict
    ".config/autostart/org.fcitx.Fcitx5.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Fcitx 5
      Hidden=true
    '';
  };

  # home-manager 自身の管理を有効化
  programs.home-manager.enable = true;
}
