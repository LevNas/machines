# VPN クライアント (work マシン用、FortiGate SSL VPN)
#
# - CLI 接続: `sudo openconnect --protocol=fortinet --user=<id> https://<gateway>`
#   - TOTP/MFA は対話入力 (`Password+TOTP` 連結形式の会社が多い)
# - GUI 接続: Plasma の System Settings → Connections → VPN → "OpenConnect" を選択
#   - Protocol を "Fortinet SSL VPN" に設定
#   - 注意: この plugin を追加した初回は switch 直後だと System Settings に OpenConnect が出ない。
#     plasmashell が古い VPN service descriptor キャッシュを保持しているため。
#     セッション再起動 (再ログイン or OS 再起動) で出現する。
# - 会社接続情報 (gateway URL, user 名, 認証手順) は private のためここには記載しない
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    openconnect    # FortiGate SSL VPN 対応 (--protocol=fortinet)
    vpnc-scripts   # tun デバイス + route 設定 helper (openconnect が内部で呼ぶ)
  ];

  # NetworkManager の OpenConnect plugin を有効化して Plasma の Network 設定 UI からも管理可能にする
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];
}
