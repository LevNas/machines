# RDP クライアント (work マシン用、会社 Windows へ VPN 経由で接続)
#
# - GUI: Remmina を起動 → RDP プロファイルを新規作成
#   - Server: <会社 Windows の IP / ホスト名> (VPN 接続後に到達可能)
#   - Protocol: RDP - Remote Desktop Protocol
#   - User/Password/Domain は会社アカウント
# - CLI テスト: `xfreerdp /v:<host> /u:<user> /d:<domain> /cert:ignore` (Remmina と別に疎通確認したい時)
# - 前提: roles/vpn.nix の FortiGate VPN で社内ネットに到達していること
# - 会社接続情報 (IP, user, domain) は private のためここには記載しない
#
# トラブルシュート (2026-06-01 実機で遭遇):
# - 画面は出るがキー/マウス入力が全く効かない (Alt+Tab 等ローカル処理のキーだけ反応):
#     → まず *リモート Windows 側* を再起動する。RDP セッションの入力チャンネルが固まった状態で、
#       クライアント (Remmina/FreeRDP) 設定をいじっても直らない。リモート再起動で解消した実績あり。
# - 画面描画が固まる / 数十秒で ERRCONNECT_CONNECT_CANCELLED を繰り返す:
#     → GFX (RemoteFX/H264) パイプラインが不安定なケース。`xfreerdp ... -gfx` で描画は安定する。
#       Remmina なら接続プロファイルの GFX 系オプションを無効化。
# - 補足: nixpkgs の freerdp には xfreerdp(X11) のほか wlfreerdp(Wayland)/sdl-freerdp(SDL) も同梱。
#   Wayland セッションで入力グラブが怪しい時は sdl-freerdp / wlfreerdp も切り分けに使える。
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    remmina   # GTK ベースの GUI リモートデスクトップクライアント (RDP/VNC/SSH/SPICE)
    freerdp   # xfreerdp CLI (単体接続テスト用、Remmina のバックエンドと同系)
  ];
}
