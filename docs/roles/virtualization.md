# virtualization role

libvirt/QEMU による仮想化ホスト機能。Windows 11 ゲストのインストール要件（TPM 2.0 / Secure Boot）に対応する。

定義: [os/linux/nixos/roles/virtualization.nix](../../os/linux/nixos/roles/virtualization.nix)

## 提供する機能

| 項目 | 内容 |
|---|---|
| ハイパーバイザ | libvirtd + QEMU/KVM |
| GUI 管理 | virt-manager |
| TPM 2.0 | swtpm（ソフトウェア TPM。Windows 11 の必須要件） |
| UEFI / Secure Boot | QEMU 同梱の OVMF（secure boot 対応ビルド含む。現行 nixpkgs では旧 `qemu.ovmf` オプションは削除済みで、追加設定不要） |
| VirtIO ドライバ | `virtio-win` パッケージ。ISO は `/run/current-system/sw/share/virtio-win/virtio-win.iso` |
| USB リダイレクト | `virtualisation.spiceUSBRedirection.enable`（SPICE 経由） |
| ネットワーク | libvirt 既定の NAT（`default` ネットワーク、virbr0） |

## 前提

- 利用ユーザーが `libvirtd` グループに入っていること（hosts 側の `users.users.<user>.extraGroups` で設定。mynix は設定済み）
- 反映後、libvirt の `default` ネットワークが inactive の場合は起動しておく:

  ```bash
  virsh net-start default
  virsh net-autostart default
  ```

## Windows 11 VM 作成チェックリスト

virt-manager で新規 VM を作成する際のポイント:

1. **Customize configuration before install** にチェックを入れて作成に進む
2. **Overview → Firmware**: `UEFI x86_64: ...OVMF_CODE.secboot.fd` など secure boot 対応のものを選択
3. **TPM**: モデル TIS または CRB、バージョン 2.0 を追加（swtpm が使われる）
4. **CPU/メモリ**: Windows 11 の最小要件は 2 vCPU / 4GB。実用上は 4 vCPU / 8GB 程度を推奨
5. **ディスク**: バス **VirtIO** を選択（性能のため）
6. **NIC**: デバイスモデル **virtio**
7. **CD 2 台構成**でインストール開始:
   - 1 台目: Windows 11 インストール ISO（`~/Downloads/Win11_25H2_Japanese_x64_v2.iso`。Nix 管理外のローカルファイル）
   - 2 台目: `virtio-win.iso`（インストーラがディスクを認識しない場合、ここから `viostor`/`NetKVM` ドライバを読み込む）
   - ホームディレクトリ配下の ISO は qemu ユーザーから読めず権限エラーになることがある。virt-manager が権限修正を提案するのでそれに従うか、ISO を `/var/lib/libvirt/images/` へコピーする
8. インストール後、`virtio-win.iso` 内の `virtio-win-guest-tools.exe` を実行してドライバ一式と SPICE ゲストツールを導入

### ネットワークについて

既定の NAT のままでよい。IPsec (IKEv2) VPN は NAT-T (UDP 4500) で NAT を越えられるため、ゲスト内で VPN クライアントを使う用途でも二重 NAT で問題ない。ブリッジ接続が必要になった場合のみ別途検討する。

### VPN クライアント用途での注意（public repo のため）

VPN の接続先・認証情報などの実値は本リポジトリには一切書かない（[roles/vpn.nix](../../os/linux/nixos/roles/vpn.nix) と同じ方針）。VM 内の設定は VM のディスクイメージ内に閉じる。

## 未決事項（VM 作成前にホスト利用者が決めること）

- **Windows 11 ISO**: 取得済み（25H2 日本語 x64、`~/Downloads/` に配置。Microsoft 公式ダウンロード）。ライセンス（プロダクトキー）の扱いは利用目的に応じて決める
- **VM ディスクの容量・配置**: 既定のストレージプールは `/var/lib/libvirt/images`（root パーティション）。Windows 11 実用には 64GB 以上（推奨 80–100GB、qcow2 の thin provisioning でよい）。別パーティション・別プールにする場合は `virsh pool-define` で追加する

## 変更を反映する際の注意

- 新規ファイルを追加した場合は `git add` してからビルドすること（flake は untracked ファイルを見ない）
- ビルド検証のみ（switch しない）:

  ```bash
  cd os/linux/nixos
  nix build --impure .#nixosConfigurations.mynix.config.system.build.toplevel
  ```

## 関連ドキュメント

- [mynix セットアップ](../setup/hosts/mynix.md)
- [README](../../README.md)
