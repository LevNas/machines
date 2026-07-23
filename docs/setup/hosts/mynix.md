# mynix セットアップ

ASUS ExpertBook P3 上の NixOS マシン `mynix` の構築手順。

OS のインストール手順は [docs/setup/install/nixos.md](../install/nixos.md) を参照。本ドキュメントは NixOS が起動した後の machines リポジトリ適用と固有設定を扱う。

## マシン仕様

| 項目 | 値 |
|---|---|
| 機種 | ASUS ExpertBook P3 PM3406CKA-LY0326X |
| CPU | AMD Ryzen AI 7 350 (Krackan Point, 8C/16T) |
| iGPU | AMD Radeon 860M |
| メモリ | 32GB DDR5 SO-DIMM |
| SSD | Micron MTFDKBA1T0QGN 1TB NVMe |
| Wi-Fi | Realtek RTL8852BE |
| Bluetooth | IMC Networks (USB) |
| TPM | TPM 2.0 (有効) |
| 指紋認証 | Focal FocalTech FT9365 (Linux未対応、利用不可) |

## 用途

個人用：開発、ゲーム（Steam）、メディア（YouTube等）、Windows VM（確定申告など）。

DE は Plasma 6 をメイン、GNOME を緊急避難用として共存。

## 1. 1Password GUI のインストール・サインイン

machines リポジトリ適用前に、1Password 経由でシークレットを取得するため最初に設定する。

### 1.1 1Password GUI を起動してサインイン

- NixOS 標準パッケージで導入済みなので、アプリケーションメニューから起動
- 個人アカウントでサインイン

### 1.2 SSH Agent の有効化

1Password GUI で：

- Settings → Developer
  - ✅ Use the SSH agent
  - ✅ Integrate with 1Password CLI

確認：

```bash
ls -la ~/.1password/agent.sock
ssh-add -L
```

### 1.3 SSH Agent の vault 設定

`~/.config/1Password/ssh/agent.toml` に SSH キーを提供する vault を指定：

```toml
[[ssh-keys]]
vault = "Personal"
```

vault 名は `op vault list` で確認できる。

### 1.4 SSH 鍵を 1Password で生成（または既存鍵をインポート）

- 1Password で SSH キー（Ed25519）を新規作成
- 命名例：`mynix-github-levnas`
- **「Use for SSH signing」を有効化**（git commit 署名に必要）
- 公開鍵を GitHub に登録：
  - GitHub Settings → SSH and GPG keys → New SSH key
  - Key type: Authentication Key
- 動作確認：

```bash
ssh -T git@github.com
# → 初回は 1Password ポップアップで Allow
# → "Hi LevNas! ..." が表示されれば成功
```

## 2. 1Password に必要なアイテムを作成

machines リポジトリのブートストラップが参照する以下のアイテムを **Personal vault** に作成する。

### 2.1 `machines-private-nix`

- 種類: Secure Note
- フィールド `content`（テキストフィールド）:

  ```nix
  {
    user = "levnas";
    hostname = "mynix";
    fullName = "LevNas";
  }
  ```

### 2.2 `claude-settings-local`

- 種類: Secure Note
- フィールド `content`（テキストフィールド）:

  ```json
  {}
  ```

  （環境固有の Claude Code 設定上書きが必要になったら内容を追加）

### 2.3 `git-config`

- 種類: Secure Note または Login
- フィールド：
  - `username`: GitHub ハンドル名（例: `LevNas`）
  - `email`: noreply メールアドレス（例: `<id>+LevNas@users.noreply.github.com`）
  - `signing-key`: SSH 公開鍵全体（`ssh-ed25519 AAAA...`）

## 3. machines リポジトリの適用

### 3.1 git 最小設定

bootstrap スクリプトを取得・実行するためだけの最小設定（最終的な git 設定は chezmoi で配置される）：

```bash
git config --global init.defaultBranch main
```

### 3.2 ブートストラップ実行

```bash
curl -fsSL https://raw.githubusercontent.com/LevNas/machines/main/scripts/bootstrap-nixos.sh | bash
```

スクリプトが以下を自動実行：

1. リポジトリの clone（`~/src/github.com/LevNas/machines`）
2. 1Password 認証（マスターパスワードのプロンプト）
3. `/etc/machines/private.nix` の配置
4. NixOS rebuild（flake ビルド）
5. chezmoi init + apply
6. `~/.claude/settings.local.json` の配置
7. git pre-commit hook の設定

### 3.3 ビルド完了後の確認

```bash
# パッケージ確認
which neovim nvim tmux fzf chezmoi claude

# chezmoi 管理ファイル確認
chezmoi managed

# git 設定確認（chezmoi 経由で配置されたはず）
git config --global user.name
git config --global user.email
```

## 4. Secure Boot 有効化（lanzaboote）

ブートストラップで lanzaboote 自体は導入されているが、署名鍵生成・UEFI 設定が必要。

### 4.1 署名鍵の生成

```bash
nix shell nixpkgs#sbctl -c sudo sbctl create-keys
```

鍵は `/var/lib/sbctl` に保存される。

### 4.2 EFI ファイルの署名確認

`nixos-rebuild switch` が自動で署名するため、ブートストラップ後の状態で確認：

```bash
nix shell nixpkgs#sbctl -c sudo sbctl verify
```

すべて ✓ になっていれば OK（古い世代の未署名カーネルが残っていれば、`sudo nix-collect-garbage -d` で除去）。

### 4.3 UEFI を Setup Mode にする

1. 再起動 → systemd-boot メニューで **"Reboot into Firmware"** を選択
2. UEFI 設定画面で：
   - Security → Secure Boot → **"Reset to Setup Mode"** を実行
3. F10 で保存して NixOS を起動

### 4.4 鍵を UEFI に登録

```bash
nix shell nixpkgs#sbctl -c sudo sbctl enroll-keys --microsoft
```

`--microsoft` は Microsoft の鍵も同時に登録するためのフラグ。ハードウェア OptionROM（GPU・NIC等のファームウェア）は Microsoft 署名されているため、これがないと一部のデバイスが動かない可能性がある。

### 4.5 Secure Boot を有効化

1. 再起動 → UEFI 設定画面に入る
2. Security → Secure Boot → **Enabled** に変更
3. F10 で保存して NixOS を起動

### 4.6 動作確認

```bash
bootctl status | grep "Secure Boot"
# → "Secure Boot: enabled (user)" と表示されれば成功
```

## 5. 残りの初期セットアップ

### 5.1 日本語入力（fcitx5 + mozc）

- アプリケーションメニューから「Fcitx 5 Configuration」を起動
- Input Method に Mozc を追加
- 半角/全角キー or Ctrl+Space で切り替え動作確認

環境変数が必要な場合は `roles/personal-desktop.nix` に追加することを検討：

```nix
environment.sessionVariables = {
  GTK_IM_MODULE = "fcitx";
  QT_IM_MODULE = "fcitx";
  XMODIFIERS = "@im=fcitx";
};
```

### 5.2 1Password GUI 自動起動

Plasma: システム設定 → 起動と終了 → 自動起動 → 1Password を追加

### 5.3 主要リポジトリの clone

```bash
ghq get <your-org>/<knowledge-repo>  # 個人ナレッジ repo (private)
ghq get LevNas/cmigemo.nvim
ghq get LevNas/ccmemo
# その他必要なもの
```

### 5.4 SSH サーバの公開鍵認証化（任意）

初期状態は `PasswordAuthentication = true`（接続テスト用）。本格運用時は無効化する：

1. `roles/server.nix` を編集
2. `~/.ssh/authorized_keys` に GitHub から取得した公開鍵を配置：
   ```bash
   curl https://github.com/LevNas.keys >> ~/.ssh/authorized_keys
   ```
3. `nixos-rebuild switch --impure --flake .#mynix`

## 既知の問題・トラブルシュート

### `dbus-broker.service` reload 失敗の warning

- `nixos-rebuild test/switch` 中に user activation で出る warning
- 機能には影響なし。再起動で解消する
- GNOME と Plasma の共存時に起きやすい

### `sbctl verify` で `EFI/nixos/kernel-*.efi` が未署名（✗）と表示される

- lanzaboote の仕様であり異常ではない（現行世代のカーネルにも常に ✗ が付く）
- カーネル本体は未署名のまま ESP に置かれ、署名済みスタブ
  （`EFI/Linux/nixos-generation-*.efi`）が埋め込み SHA-256 ハッシュで検証する
- ファームウェアが直接実行するのは署名済みスタブのみのため、Secure Boot
  チェーンは健全。確認すべきは `EFI/Linux/` 配下と `systemd-bootx64.efi` が
  すべて signed であること
- `sbctl verify` は sbctl 自身が署名管理する前提のツールで、lanzaboote の
  ハッシュ検証方式を認識できないだけ（2026-07-20 の nixpkgs 更新時に確認。
  旧記述「導入前世代の遺物で GC により削除可能」は誤りだったため訂正）

### git commit 時に `op-ssh-sign` 接続エラー

- 1Password GUI が起動していない場合に発生
- 1Password GUI を起動するか、SSH agent socket を再設定
- **GUI 起動済みでもロック中は別症状で失敗する**: `1Password: failed to fill whole buffer` /
  `fatal: failed to write commit object`（再起動直後に典型）。プロセス稼働・agent.sock 存在でも
  ロックだけで起きるため、ロック解除してリトライすれば解消（2026-07-21 確認）

### 指紋認証・顔認証は使えない

- Focal FocalTech FT9365 は Linux 未対応
- IR カメラの顔認証も Linux ではほぼ無理

## 関連ドキュメント

- [OS インストール手順](../install/nixos.md)
- [README](../../../README.md)
- [machines リポジトリ全体構成](../../../README.md)
