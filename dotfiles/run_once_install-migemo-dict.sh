#!/bin/bash
# ==============================================================================
# Install oguna/yet-another-migemo-dict for rustmigemo / cmigemo.nvim
# ==============================================================================
# 配置先: ~/.local/share/migemo/migemo-compact-dict
# 冪等: 既に同サイズのファイルがあればスキップ
# rustmigemo (mise: github:oguna/rustmigemo) と cmigemo.nvim が
# DICT_CANDIDATES でこのパスを auto-detect する。
set -e

DICT_DIR="$HOME/.local/share/migemo"
DICT_FILE="$DICT_DIR/migemo-compact-dict"
DICT_VERSION="v0.6"
DICT_URL="https://github.com/oguna/yet-another-migemo-dict/releases/download/${DICT_VERSION}/migemo-compact-dict.zip"
EXPECTED_SIZE=1384379

if [[ -f "$DICT_FILE" ]] && [[ "$(stat -c%s "$DICT_FILE" 2>/dev/null)" -eq "$EXPECTED_SIZE" ]]; then
  echo "✓ migemo-compact-dict already installed (${DICT_VERSION})"
  exit 0
fi

echo "📦 Installing migemo-compact-dict (${DICT_VERSION})..."
mkdir -p "$DICT_DIR"
TMPZIP=$(mktemp --suffix=.zip)
trap 'rm -f "$TMPZIP"' EXIT
curl -fsSL -o "$TMPZIP" "$DICT_URL"
unzip -j -o "$TMPZIP" "migemo-compact-dict" -d "$DICT_DIR" > /dev/null
echo "✅ migemo-compact-dict installed at $DICT_FILE"
