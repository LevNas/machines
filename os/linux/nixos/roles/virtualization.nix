# 仮想化ホスト (libvirt/QEMU、Windows 11 ゲスト対応)
#
# - GUI 管理: virt-manager
# - Windows 11 ゲストのインストール要件に対応:
#   - TPM 2.0: swtpm (ソフトウェア TPM エミュレータ)
#   - Secure Boot: QEMU 同梱の OVMF (secure boot 対応ビルド含む) をそのまま利用。
#     かつての virtualisation.libvirtd.qemu.ovmf サブモジュールは nixpkgs から削除済みで、
#     現在は QEMU 配布の全 OVMF イメージが既定で libvirt から選択可能
# - VirtIO ドライバ ISO は /run/current-system/sw/share/virtio-win/virtio-win.iso に配置される
# - ネットワークは libvirt 既定の NAT (virbr0)。IPsec VPN は NAT-T で越えられるため
#   ゲスト内 VPN クライアント用途でも二重 NAT で問題ない
# - 利用ユーザーは hosts 側で libvirtd グループへ追加すること (users.users.<user>.extraGroups)
# - VM 作成・運用手順は docs/roles/virtualization.md を参照
{ pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    # Windows 11 要件: TPM 2.0 (Secure Boot 対応 UEFI は QEMU 同梱の OVMF で追加設定不要)
    qemu.swtpm.enable = true;
  };

  programs.virt-manager.enable = true;

  # SPICE 経由でホストの USB デバイスをゲストへリダイレクト (setuid wrapper が必要なため専用オプション)
  virtualisation.spiceUSBRedirection.enable = true;

  environment.systemPackages = with pkgs; [
    virtio-win  # Windows ゲスト用 VirtIO ドライバ ISO
    spice-gtk   # SPICE クライアントライブラリ (USB リダイレクト・クリップボード共有等)
  ];
}
