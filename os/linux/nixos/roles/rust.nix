# Rust 開発環境 (toolchain + component バイナリ)
#
# 設計方針 (2026-06-07 決定):
# - バイナリ (rustc/cargo/clippy/rustfmt/rust-analyzer) は Nix で管理。
#   nixpkgs は同一 rev 内で component バージョンを整合させるため、個別に並べても
#   バージョン不整合は起きない (現状すべて 1.94.1、rust-analyzer は対応日付版)。
# - エディタ統合 (rust-analyzer の起動オプション・診断表示・キーマップ・fmt on save) は
#   dotfiles の nvim lua 側で詰める (別タスク)。「バイナリは揃える、振る舞いは dotfiles」。
# - 用途: Rust 学習 + youtube-tui 等の cargo ビルド対象のビルド基盤。
#
# 関連:
# - roles/development.nix … bootstrap 層 (gcc/mise/git)。Rust 固有はこの rust.nix に分離。
# - nvim lua (dotfiles) … rust-analyzer の LSP 設定は別タスクで実装予定。
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rustc          # コンパイラ本体
    cargo          # ビルド / パッケージマネージャ
    clippy         # lint
    rustfmt        # コード整形
    rust-analyzer  # LSP サーバ (nvim から呼ぶバイナリ本体)

    # -sys クレートのビルド基盤。openssl-sys は reqwest/native-tls 経由で多くの
    # クレートが要求する普遍的依存のため、Rust 学習・cargo ビルドの土台として常備する。
    # (当初 youtube-tui の cargo build 用に追加したが、同ツールは native closure と RPATH の
    #  都合で nixpkgs 管理に切替済み。本依存は汎用ビルド基盤として残置。)
    pkg-config
    openssl
  ];

  # rust-analyzer が標準ライブラリ (std) のソースを解決できるようにする。
  # rustcSrc はソースツリーの derivation なので systemPackages ではなく
  # RUST_SRC_PATH 環境変数で library ディレクトリを指す (これが正しいイディオム)。
  # これで std::Vec 等の定義ジャンプ・補完が効く。
  environment.variables.RUST_SRC_PATH =
    "${pkgs.rustPlatform.rustcSrc}/lib/rustlib/src/rust/library";

  # nix-build 外の `cargo install` / `cargo build` でも pkg-config が openssl の .pc を
  # 発見できるようにする。NixOS の pkg-config は buildInputs 経由でしか自動探索しないため、
  # dev 出力の pkgconfig ディレクトリを明示する。
  # 注意: PKG_CONFIG_PATH はスカラ env var。他ロールでも .pc を足す必要が出たら、
  #       単純な二重代入は option 衝突になるため lib.mkMerge でコロン連結するか集約すること。
  environment.variables.PKG_CONFIG_PATH =
    "${pkgs.openssl.dev}/lib/pkgconfig";
}
