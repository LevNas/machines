# 仮想化ホスト (libvirt/QEMU、Windows 11 ゲスト対応)
#
# - GUI 管理: virt-manager
# - Windows 11 ゲストのインストール要件に対応:
#   - TPM 2.0: swtpm (ソフトウェア TPM エミュレータ)
#   - Secure Boot: QEMU 同梱の OVMF (secure boot 対応ビルド含む) をそのまま利用。
#     かつての virtualisation.libvirtd.qemu.ovmf サブモジュールは nixpkgs から削除済みで、
#     現在は QEMU 配布の全 OVMF イメージが既定で libvirt から選択可能
# - VirtIO ドライバ ISO は /etc/virtio-win.iso に配置される (nixpkgs の virtio-win パッケージは
#   展開済みディレクトリツリーで .iso を含まないため、この role 内で ISO 化する)
# - ネットワークは libvirt 既定の NAT (virbr0)。IPsec VPN は NAT-T で越えられるため
#   ゲスト内 VPN クライアント用途でも二重 NAT で問題ない
# - 利用ユーザーは hosts 側で libvirtd グループへ追加すること (users.users.<user>.extraGroups)
# - VM 作成・運用手順は docs/roles/virtualization.md を参照
{ pkgs, ... }:

let
  # nixpkgs の virtio-win (0.1.285 で確認) は $out 直下に NetKVM/ viostor/ 等を展開した
  # ディレクトリで .iso を含まない。ゲストの CD ドライブへ渡せるよう ISO を生成する
  virtio-win-iso = pkgs.runCommand "virtio-win.iso"
    { nativeBuildInputs = [ pkgs.cdrkit ]; }
    "genisoimage -r -J -joliet-long -V virtio-win -o $out ${pkgs.virtio-win}/";
in
{
  virtualisation.libvirtd = {
    enable = true;
    # Windows 11 要件: TPM 2.0 (Secure Boot 対応 UEFI は QEMU 同梱の OVMF で追加設定不要)
    qemu.swtpm.enable = true;
  };

  programs.virt-manager.enable = true;

  # SPICE 経由でホストの USB デバイスをゲストへリダイレクト (setuid wrapper が必要なため専用オプション)
  virtualisation.spiceUSBRedirection.enable = true;

  # Windows ゲスト用 VirtIO ドライバ ISO を安定パスへ配置 (実体は store への symlink)。
  # virtio-win を environment.systemPackages に入れても bin/ や share/ を持たないため何も
  # リンクされない — パッケージ本体ではなく ISO 化した派生物を配るのが正しい
  environment.etc."virtio-win.iso".source = virtio-win-iso;

  environment.systemPackages = with pkgs; [
    spice-gtk  # SPICE クライアントライブラリ (USB リダイレクト・クリップボード共有等)
  ];
}
