{ config, pkgs, lib, ... }:

let
  privatePath = /etc/machines/private.nix;
  private = import privatePath;
in
{
  imports = [
    ../../hardware/mynix/hardware-configuration.nix
    ../../roles/development.nix
    ../../roles/rust.nix
    ../../roles/personal-desktop.nix
    ../../roles/media.nix
    ../../roles/gaming.nix
    ../../roles/onepassword.nix
    ../../roles/virtualization.nix
    ../../roles/server.nix
    ../../roles/secure-boot.nix
    ../../roles/vpn.nix
    ../../roles/rdp.nix
  ];

  # ブートローダ
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # ネットワーク
  networking.hostName = private.hostname;
  networking.networkmanager.enable = true;

  # ユーザー
  users.users.${private.user} = {
    isNormalUser = true;
    description = private.fullName;
    extraGroups = [ "wheel" "networkmanager" "audio" "video" "libvirtd" "input" ];
    shell = pkgs.zsh;
  };

  # 基本ツール (role に分類しにくいもの)
  environment.systemPackages = with pkgs; [
    curl
    wget
    tree
    unzip
    zip
    htop
    btop
    file
    pciutils
    usbutils
    alsa-utils
    pulseaudio
    tldr
    ncdu
    bottom
    duf
  ];

  # Nix 設定
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" private.user ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # 1Password GUI polkit (ユーザー固有)
  programs._1password-gui.polkitPolicyOwners = [ private.user ];

  # Nixpkgs
  nixpkgs.config.allowUnfree = true;

  # state version (変更しないこと)
  system.stateVersion = "25.11";
}
