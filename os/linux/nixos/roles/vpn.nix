# VPN クライアント (work マシン用、FortiGate)
#
# 2 系統を提供する:
#
# 1) SSL-VPN (従来方式): openconnect --protocol=fortinet
#    - CLI 接続: `sudo openconnect --protocol=fortinet --user=<id> https://<gateway>`
#      - TOTP/MFA は対話入力 (`Password+TOTP` 連結形式の会社が多い)
#    - GUI 接続: Plasma の System Settings → Connections → VPN → "OpenConnect" を選択
#      - Protocol を "Fortinet SSL VPN" に設定
#      - 注意: この plugin を追加した初回は switch 直後だと System Settings に OpenConnect が出ない。
#        plasmashell が古い VPN service descriptor キャッシュを保持しているため。
#        セッション再起動 (再ログイン or OS 再起動) で出現する。
#
# 2) IPsec-VPN (新方式): strongSwan (swanctl) による IKEv2 dialup
#    - 接続定義 (gateway FQDN / PSK / 社内サブネット) は機微情報のため
#      machine-local の /etc/machines/vpn-work.swanctl.conf に置く (テンプレートと
#      セットアップ手順は docs/roles/vpn.md)。swanctl.conf の include 機構で
#      Nix store を経由せずに読み込む (PSK を store に置かないため)。
#    - 接続操作は同梱の `wvpn` ヘルパー (`wvpn up` / `wvpn down` / `wvpn status`)。
#      パスワード + メール OTP (6 桁) は接続時に対話入力し、連結して EAP secret
#      として一時投入する (FortiGate の 2FA は「password+OTP 連結」で通る方式)。
#    - スプリットトンネル: ゲートウェイがフルトンネル (0.0.0.0/0) を配る構成でも、
#      クライアント側から remote_ts を社内サブネットに絞って提案する (IKEv2 の
#      traffic selector narrowing)。張った child SA のサブネットだけが table 220 に
#      経路投入され、それ以外の通信は通常経路のまま = クライアント側スプリットトンネル。
#    - 会社接続情報 (gateway URL, user 名, PSK, サブネット) は private のためここには記載しない
{ pkgs, ... }:

let
  # IPsec-VPN 接続ヘルパー。root 前提 (vici ソケット) なので非 root なら sudo で再実行する。
  wvpn = pkgs.writeShellApplication {
    name = "wvpn";
    runtimeInputs = with pkgs; [
      strongswan
      gawk
      coreutils
    ];
    text = ''
      CONN=work
      CONF=/etc/machines/vpn-work.swanctl.conf

      usage() {
        echo "usage: wvpn {up|down|status}" >&2
        exit 1
      }
      [ $# -ge 1 ] || usage
      cmd=$1

      if [ "$cmd" = status ]; then
        exec sudo swanctl --list-sas
      fi

      if [ "$(id -u)" -ne 0 ]; then
        exec sudo "$0" "$@"
      fi

      case "$cmd" in
        up)
          if [ ! -s "$CONF" ]; then
            echo "error: $CONF が未配置です (docs/roles/vpn.md 参照)" >&2
            exit 1
          fi
          systemctl start strongswan-swanctl.service
          # conf 編集後の再実行でも最新定義になるよう毎回リロード
          swanctl --load-all --noprompt >/dev/null

          eap_id=$(awk -F= '/eap_id/ { gsub(/[ \t"]/, "", $2); print $2; exit }' "$CONF")
          if [ -z "$eap_id" ]; then
            echo "error: $CONF に eap_id が見つかりません" >&2
            exit 1
          fi

          # EAP secret を /run (tmpfs) 上の一時 swanctl ツリーから --load-creds で
          # charon のメモリにだけ載せ、ファイルは即削除する (ディスクに平文を残さない)。
          load_creds() {
            tmpdir=$(mktemp -d /run/wvpn.XXXXXX)
            trap 'rm -rf "$tmpdir"' EXIT
            cat > "$tmpdir/swanctl.conf" <<EOF
      include /etc/swanctl/swanctl.conf
      secrets {
        eap-wvpn {
          id = $eap_id
          secret = "$1"
        }
      }
      EOF
            SWANCTL_DIR=$tmpdir swanctl --load-creds --noprompt >/dev/null
            rm -rf "$tmpdir"
          }

          children=$(swanctl --list-conns | awk -F: '/: TUNNEL/ { gsub(/^[ \t]+/, "", $1); print $1 }')
          if [ -z "$children" ]; then
            echo "error: 接続定義 ($CONN) の child が見つかりません" >&2
            exit 1
          fi
          first_child=$(printf '%s\n' "$children" | head -1)

          printf 'Password (%s): ' "$eap_id"
          read -rs pw
          echo

          # メール OTP はパスワード付きの認証試行がゲートウェイに届いた時点で発送される
          # (TOTP と違いコードが事前に手元にない)。未着なら空 Enter でパスワードのみの
          # 試行を先に打ち、メール送信をトリガーする (この試行は token 不足で失敗するのが期待動作)。
          printf 'OTP 6 桁 (未着なら空 Enter でメール送信をトリガー): '
          read -r otp
          if [ -z "$otp" ]; then
            load_creds "$pw"
            echo "パスワードのみで初回試行します (認証失敗になりますが OTP メールが発送されます)..."
            swanctl --initiate --child "$first_child" --timeout 30 || true
            printf 'メールで届いた 6 桁を入力: '
            read -r otp
          fi

          # EAP secret = password + OTP 連結。OTP は毎回変わるため静的設定にできない。
          load_creds "$pw$otp"
          unset pw otp

          # 社内サブネットごとの child SA を順に張る。EAP/OTP 認証は最初の 1 本目
          # (IKE_SA 確立時) だけで、以降の child は同じ IKE_SA に相乗りする。
          printf '%s\n' "$children" | while read -r child; do
            swanctl --initiate --child "$child" --timeout 30
          done
          swanctl --list-sas
          ;;
        down)
          swanctl --terminate --ike "$CONN" --timeout 15 || true
          # 停止で charon メモリ上の認証情報 (PSK / EAP secret) も消える
          systemctl stop strongswan-swanctl.service
          ;;
        *)
          usage
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    openconnect # FortiGate SSL VPN 対応 (--protocol=fortinet)
    vpnc-scripts # tun デバイス + route 設定 helper (openconnect が内部で呼ぶ)
    strongswan # swanctl CLI (状態確認用。デーモンは services.strongswan-swanctl)
    wvpn # IPsec-VPN 接続ヘルパー
  ];

  # NetworkManager の OpenConnect plugin を有効化して Plasma の Network 設定 UI からも管理可能にする
  networking.networkmanager.plugins = with pkgs; [
    networkmanager-openconnect
  ];

  # IPsec-VPN (IKEv2) クライアント。接続定義は machine-local ファイルを include する
  # (モジュールの includes オプションは「Nix store 外から秘密値を渡す」ための公式手段)。
  # サービスは常駐するが start_action = none なので自動接続はしない (wvpn up で明示接続)。
  services.strongswan-swanctl = {
    enable = true;
    includes = [ "/etc/machines/vpn-work.swanctl.conf" ];
  };

  # include 先が無いと swanctl --load-all が起動時にこける可能性があるため、
  # 空ファイルを保証しておく (実内容の配置は docs/roles/vpn.md の手順で行う)
  systemd.tmpfiles.rules = [
    "f /etc/machines/vpn-work.swanctl.conf 0600 root root -"
  ];
}
