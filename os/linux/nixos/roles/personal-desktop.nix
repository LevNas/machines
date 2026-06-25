{ pkgs, lib, ... }:

{
  # ディスプレイマネージャ
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # KDE Plasma 6 (メイン)
  services.desktopManager.plasma6.enable = true;

  # GNOME (緊急避難用、最小設定)
  services.desktopManager.gnome.enable = true;
  services.xserver.enable = true;

  # SSH ask-password: Plasmaを優先(GNOMEとの競合解消)
  programs.ssh.askPassword = lib.mkForce "${pkgs.kdePackages.ksshaskpass.out}/bin/ksshaskpass";

  # GNOMEから不要なアプリを除外(最小化)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-connections
    epiphany
    geary
    gnome-music
    gnome-maps
    gnome-weather
    gnome-contacts
  ];

  # ロケール・タイムゾーン
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ja_JP.UTF-8";
    LC_IDENTIFICATION = "ja_JP.UTF-8";
    LC_MEASUREMENT = "ja_JP.UTF-8";
    LC_MONETARY = "ja_JP.UTF-8";
    LC_NAME = "ja_JP.UTF-8";
    LC_NUMERIC = "ja_JP.UTF-8";
    LC_PAPER = "ja_JP.UTF-8";
    LC_TELEPHONE = "ja_JP.UTF-8";
    LC_TIME = "ja_JP.UTF-8";
  };

  console.keyMap = "jp106";
  services.xserver.xkb = {
    layout = "jp";
    variant = "";
  };

  # 日本語入力 (fcitx5 + mozc)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-mozc
      fcitx5-gtk
    ];
    fcitx5.settings.inputMethod = {
      GroupOrder = {
        "0" = "Default";
      };
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "mozc";
      };
      "Groups/0/Items/0" = {
        Name = "keyboard-us";
        Layout = "";
      };
      "Groups/0/Items/1" = {
        Name = "mozc";
        Layout = "";
      };
    };
    fcitx5.waylandFrontend = true;
  };

  # フォント
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    ipafont
    ipaexfont
    # HackGen Nerd Font (旧 dotfiles と同じ wezterm 用フォント。"HackGen Console NF" 等を含む)。
    # システム既定 monospace は JetBrainsMono のままで、wezterm.lua だけがこれを参照する。
    hackgen-nf-font
  ];
  fonts.fontconfig.defaultFonts = {
    serif = [ "Noto Serif CJK JP" "IPAexMincho" ];
    sansSerif = [ "Noto Sans CJK JP" "IPAexGothic" ];
    monospace = [ "JetBrainsMono Nerd Font" ];
  };

  # デスクトップアプリ (GUI)
  environment.systemPackages = with pkgs; [
    # ターミナルエミュレータ
    wezterm
    # ビデオ会議 (unfree, allowUnfree は hosts/mynix/default.nix で設定済み)。
    # nixpkgs が Zoom 公式バイナリを buildFHSEnv(bubblewrap) で wrap（更新は nixpkgs 追従）。
    # FHS 互換のための名前空間分離はあるが権限縮小ではない（ホーム/デバイスへのアクセスは広い）。
    # 脆弱性履歴を踏まえ、常用はブラウザ参加・ネイティブは必要時のみ起動する運用前提で採用。
    zoom-us
  ];
}
