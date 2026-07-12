# Modular zsh functions（dot_zshrc の ~/.config/zsh/*.zsh ループから自動 source される）

# bulletty ラッパー: TUI 終了後に after_tui フックを代行実行する。
# bulletty v0.2.2 は config の [hooks] を未サポート（upstream ではリリース後に追加）のため、
# hooks 対応リリースが出るまでこのラッパーが config から after_tui のコマンドを読んで実行する。
# コマンド文字列はマシンローカル（chezmoi が config.toml.tmpl へ注入）なので、ここには何も焼かない。
# 対応リリース後も残して無害（同期スクリプトは冪等・二重実行安全）。不要になったら削除してよい。
bulletty() {
    command bulletty "$@"
    local rc=$?
    # after_tui の意味論に合わせ、引数なし（= TUI 起動）のときだけ実行する
    if (( $# == 0 )); then
        local hook
        hook="$(sed -n 's/^after_tui = "\(.*\)"$/\1/p' \
            "${XDG_CONFIG_HOME:-$HOME/.config}/bulletty/config.toml" 2>/dev/null | head -n1)"
        # upstream の実装（sh -c）と同じ意味論で実行する（引数付きコマンドに対応）
        [[ -n "$hook" ]] && sh -c "$hook"
    fi
    return $rc
}
