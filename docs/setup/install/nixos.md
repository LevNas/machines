# NixOS インストール手順

新規マシンに NixOS をインストールするまでの汎用手順。マシン固有のセットアップは [docs/setup/hosts/](../hosts/) の各ホスト用ドキュメントを参照。

## 前提

- UEFI 起動可能なマシン（Secure Boot は後で有効化するので、この段階では Disabled でよい）
- インターネット接続（有線 or Wi-Fi）
- 別マシンでこのドキュメントを参照できる環境（スマホ/タブレットでも可）
- 既存データのバックアップ済み（インストール先のディスクは完全に消去される）

## 1. インストール ISO の準備

- NixOS unstable の graphical ISO を公式から取得
  - <https://nixos.org/download/#nixos-iso>
  - 「Graphical ISO image (unstable)」を選択（GNOME ベースのライブ環境）
- USB メモリへ書き込み
  - Linux/macOS: `dd if=<iso> of=/dev/sdX bs=4M status=progress`（書き込み先デバイスを必ず確認）
  - Windows: Rufus または Ventoy

## 2. BIOS / UEFI 設定

- Secure Boot: **Disabled**（インストール時のみ。後で lanzaboote で有効化）
- Boot Mode: **UEFI**
- USB から起動できるよう Boot Priority を調整

## 3. ライブ環境での動作確認

ISO から起動後、本番インストール前に以下を確認しておくと安心：

- Wi-Fi 接続が可能か（`nmtui` で確認）
- CPU/iGPU/メモリが正しく認識されているか（`lscpu`, `lspci`, `free -h`）
- NVMe/SSD が認識されているか（`lsblk`）
- Bluetooth、Webカメラ、サウンド、サスペンド復帰が動作するか

★ 重要：ライブ環境で動かないハードウェアは、インストール後も同じ状況のことが多い。先に検証しておくこと。

## 4. ネットワーク接続

```bash
sudo systemctl start NetworkManager
nmtui
```

## 5. パーティション構成

このリポジトリの推奨構成：

```
nvme0n1 (or sda)
├── nvme0n1p1  1GB    FAT32 (LABEL=BOOT)  → /boot (ESP)
└── nvme0n1p2  残り   LUKS2 cryptroot
    └── cryptroot      ext4 (LABEL=nixos) → /
```

- **swap なし**（zramSwap を 50% で有効化、後述の configuration.nix で設定）
- **ディスク全暗号化**（LUKS2 パスフレーズ）

### コマンド例

```bash
# パーティション作成（既存パーティションは parted などで事前削除）
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1025MiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary 1025MiB 100%

# ESP フォーマット
sudo mkfs.fat -F 32 -n BOOT /dev/nvme0n1p1

# LUKS2 暗号化
sudo cryptsetup luksFormat /dev/nvme0n1p2
sudo cryptsetup open /dev/nvme0n1p2 cryptroot

# ext4 フォーマット
sudo mkfs.ext4 -L nixos /dev/mapper/cryptroot

# マウント
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/BOOT /mnt/boot
```

## 6. 初期設定ファイル生成

```bash
sudo nixos-generate-config --root /mnt --force
```

生成された `/mnt/etc/nixos/configuration.nix` と `/mnt/etc/nixos/hardware-configuration.nix` を編集する。

### `hardware-configuration.nix` の確認

- `boot.initrd.luks.devices` の UUID が正しく設定されているか
- bind mount の誤検出（特に btrfs 用）があれば削除
  - 例: `/mnt/boot` への重複 mount 定義など

### `configuration.nix` の最小構成

このリポジトリ運用前提（後で flake 化するので、ここでは最低限の起動構成だけ書く）：

```nix
{ config, pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "<hostname>";
  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "ja_JP.UTF-8";
  console.keyMap = "jp106";

  users.users.<username> = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  services.openssh.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim git curl wget chezmoi
  ];

  system.stateVersion = "25.11";  # ISO のリリースに合わせる
}
```

`<hostname>` と `<username>` は適宜置換。

## 7. インストール実行

```bash
sudo nixos-install --root /mnt
```

完了後、root と一般ユーザーのパスワードを設定するプロンプトが出る。

## 8. 再起動

```bash
sudo reboot
```

USB を抜いて NixOS が起動することを確認。LUKS パスフレーズを入力 → ログイン画面まで進めば成功。

## 9. インストール後の流れ

ここまでで「素の NixOS が起動する」状態。machines リポジトリの適用は **[docs/setup/hosts/](../hosts/) の各ホストドキュメント**を参照。

具体的には：

1. 一般ユーザーでログイン
2. インターネット接続を確認
3. 該当する `docs/setup/hosts/<hostname>.md` の手順に進む

## 既知の問題・トラブルシュート

### LUKS パスフレーズで止まる場合

- `boot.initrd.luks.devices` の UUID が `/etc/nixos/hardware-configuration.nix` で正しいか確認
- パーティションが暗号化されていない場合、`cryptsetup luksFormat` をやり直す必要あり

### `nixos-install` 中にビルドエラー

- パッケージ名の変更が原因のことが多い（例: `noto-fonts-color-emoji` の改名）
- エラーメッセージで該当パッケージ名を検索し、現行の名前に修正
- `configuration.nix` を最小構成にして、まず起動を成功させてから機能追加するのが安全

### ライブ環境で Wi-Fi が認識されない

- 有線接続を使う、もしくは別マシンでファームウェア入りの ISO を再作成
- Realtek 系のチップは `linux-firmware` が必要なケースあり

## 参考リンク

- NixOS 公式マニュアル: <https://nixos.org/manual/nixos/stable/>
- NixOS インストールガイド: <https://nixos.org/manual/nixos/stable/#sec-installation>
