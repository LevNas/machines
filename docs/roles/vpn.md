# vpn role — FortiGate への VPN 接続 (SSL-VPN / IPsec-VPN)

`os/linux/nixos/roles/vpn.nix` が提供する work 用 VPN クライアントのセットアップ手順。
会社の実接続情報 (gateway FQDN / PSK / ユーザー名 / 社内サブネット) は機微情報のため
このリポジトリには置かず、machine-local ファイル + 1Password で管理する。

## 構成の全体像

| 系統 | 実装 | 用途 |
|---|---|---|
| SSL-VPN (従来方式) | openconnect (`--protocol=fortinet`) + NetworkManager plugin | 従来ゲートウェイ |
| IPsec-VPN (新方式) | strongSwan (swanctl) IKEv2 + `wvpn` ヘルパー | 新ゲートウェイ |

IPsec-VPN の秘密情報の流れ:

```
1Password (Secure Note)
  └─ op item get → /etc/machines/vpn-work.swanctl.conf   (root:root 0600, gitignore 対象外の /etc 直置き)
       └─ swanctl.conf の include で実行時に読み込み (Nix store を経由しない)
            └─ パスワード + メール OTP だけは wvpn up が接続の都度プロンプトで受け取り、
               /run (tmpfs) 経由で charon のメモリにのみ投入
```

## セットアップ手順 (初回のみ)

### 1. 接続定義ファイルを作成

FortiClient の設定手引きに記載の値を下記テンプレートへ転記し、1Password の
**Personal vault** に Secure Note `machines-vpn-work-swanctl` (フィールド `content`)
として保存する。

```
connections {
  work {
    version = 2                     # 手引き「IKE: バージョン 2」
    remote_addrs = <gateway-fqdn>   # 手引き「リモート GW」の FQDN
    vips = 0.0.0.0                  # 手引き「Address Assignment: モードコンフィグ」(IP をゲートウェイから貰う)
    encap = yes                     # FortiGate の NAT-T checksum 不具合対策 (常時 UDP カプセル化)
    mobike = no                     # FortiGate 相手の定石 (MOBIKE 非対応挙動の回避)
    fragmentation = yes
    dpd_delay = 30s                 # 手引き「DPD: チェック」
    rekey_time = 86400s             # 手引きフェーズ 1「鍵の有効期間: 86400」
    # 手引きフェーズ 1「AES256/SHA256, AES128/SHA256 × DH グループ 20, 21」
    # (DH 20 = ecp384, DH 21 = ecp521)
    proposals = aes256-sha256-ecp384,aes256-sha256-ecp521,aes128-sha256-ecp384,aes128-sha256-ecp521

    local {
      round = 2                     # 重要: EAP は認証ラウンド 2 に置く (round 1 だと FortiGate が無視して失敗する)
      auth = eap                    # 手引き「認証(XAuth): ユーザ名入力」= IKEv2 では EAP。方式はサーバ提示に追従 (通常 MSCHAPv2)
      eap_id = <username>           # 配布されたユーザー名
    }
    remote {
      id = %any
      auth = psk                    # 手引き「認証方法: 事前共有鍵」
    }

    children {
      # スプリットトンネル: 通したい社内サブネットごとに child を 1 つ作る
      # (FortiGate は 1 CHILD_SA = 1 サブネットのため複数書くなら child を複製する)。
      # ゲートウェイがフルトンネル (0.0.0.0/0) 設定でも、クライアントから狭い
      # remote_ts を提案すれば IKEv2 の narrowing で通る (広げる方向は不可、狭める方向は可)。
      lan1 {
        remote_ts = <社内サブネット>/24   # 例: 10.x.y.0/24 (実値は手引き・情シス情報から)
        # 手引きフェーズ 2「AES256/SHA256, AES128/SHA256」「PFS: DH グループ 20」
        esp_proposals = aes256-sha256-ecp384,aes128-sha256-ecp384
        rekey_time = 43200s         # 手引きフェーズ 2「鍵の有効期間: 43200 秒」
        start_action = none         # 自動接続しない (wvpn up で明示的に張る)
        dpd_action = clear
      }
      # lan2 { ... }  # 必要なら追加
    }
  }
}

secrets {
  ike-work {
    secret = "<事前共有鍵>"          # 手引き「事前共有鍵」の値
  }
}
```

### 2. mynix に配置

```bash
op item get "machines-vpn-work-swanctl" --vault "Personal" --fields content | \
    sed 's/^"//; s/"$//' | \
    sudo tee /etc/machines/vpn-work.swanctl.conf > /dev/null
sudo chmod 600 /etc/machines/vpn-work.swanctl.conf
```

配置後にサービスへ反映:

```bash
sudo systemctl restart strongswan-swanctl.service
```

## 日常の使い方

```bash
wvpn up       # パスワードとメール OTP (6 桁) を対話入力して接続
wvpn status   # SA の状態表示 (= swanctl --list-sas)
wvpn down     # 切断 + デーモン停止 (メモリ上の認証情報も破棄)
```

- 2FA はメールで届く 6 桁コード。FortiGate の Linux (strongSwan) クライアントには
  FortiClient のような専用トークン入力ダイアログが無いため、**パスワードと OTP を
  連結した文字列を EAP secret として投入する**方式を使う (`wvpn` が内部でやる)。
- OTP が「届いてから入力するまで」に時間切れになったら `wvpn up` をやり直す。
  「コードが正しいのに拒否される」場合はクライアント/ゲートウェイ間の時刻ずれを疑う (NTP 確認)。
- 接続に成功すると、child に書いたサブネットへの経路だけが routing table 220 に入る
  (`ip route show table 220` で確認)。それ以外の通信 (デフォルトルート) は VPN を通らない。

## 制約・既知の落とし穴

- **UDP 500/4500 が通る回線が前提**。FortiClient の「Auto (UDP fallback TCP)」の
  TCP 443 フォールバックは Fortinet 独自仕様で、strongSwan は非対応。
  UDP が塞がれた回線では接続できない (その場合は SSL-VPN 側を使う)。
- ゲートウェイが traffic selector の narrowing を拒否する場合 (`TS_UNACCEPTABLE` で
  child が張れない場合) は、child を 1 つにして `remote_ts = 0.0.0.0/0` にすれば
  FortiClient と同じフルトンネルになる (スプリットはあきらめるか、table 220 の
  経路を手で調整する route-based 方式に切り替える)。
- ゲートウェイがモードコンフィグで DNS サーバを配ってきた場合、charon の resolve
  plugin が resolv.conf に追記を試みる。NetworkManager 管理下で挙動が怪しいときは、
  社内ホスト名は IP 直か /etc/hosts での運用に逃がす。
- FortiGate は有効な peer からの IKE_SA_INIT を受けると自分からも tunnel を張りに
  来ることがあり、CHILD_SA が重複して見えることがある (実害は通常ない)。

## 参考

- strongSwan 公式 interop ドキュメント (Fortinet Devices):
  https://docs.strongswan.org/docs/latest/interop/fortinet.html
- FortiGate IKEv2 PSK+EAP を strongSwan から張る際の round=2 の要点:
  https://community.fortinet.com/support-forum-92/strongswan-connecting-to-fortigate-ikev2-ipsec-vpn-using-psk-eap-223635
- FortiToken/OTP を password 連結で通す方式:
  https://infosecmonkey.com/deploying-a-fortigate-as-an-ipsec-ikev2-remote-access-vpn-concentrator-for-linux-clients-with-fortitoken-mfa/
