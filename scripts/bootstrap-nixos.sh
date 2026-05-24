#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for NixOS machines
# Usage: curl -fsSL https://raw.githubusercontent.com/LevNas/machines/main/scripts/bootstrap-nixos.sh | bash
# Or: ./scripts/bootstrap-nixos.sh

REPO_URL="git@github.com:LevNas/machines.git"
REPO_DIR="$HOME/src/github.com/LevNas/machines"
NIXOS_DIR="$REPO_DIR/os/linux/nixos"
PRIVATE_NIX="/etc/machines/private.nix"

echo "=== machines bootstrap (NixOS) ==="

# --- Step 1: Clone repo if not present ---
if [ ! -d "$REPO_DIR" ]; then
    echo "[1/6] Cloning repository..."
    if command -v ghq &>/dev/null; then
        ghq get "$REPO_URL"
    else
        mkdir -p "$(dirname "$REPO_DIR")"
        git clone --recursive "$REPO_URL" "$REPO_DIR"
    fi
else
    echo "[1/6] Repository already exists, pulling latest..."
    git -C "$REPO_DIR" pull --ff-only
fi

# --- Step 2: 1Password authentication ---
echo "[2/6] Authenticating with 1Password..."
if ! op account list &>/dev/null; then
    echo "Please sign in to 1Password:"
    eval "$(op signin)"
fi

# Verify authentication
if ! op vault list &>/dev/null; then
    echo "ERROR: 1Password authentication failed."
    exit 1
fi
echo "  1Password authenticated."

# --- Step 3: Deploy private.nix ---
echo "[3/6] Deploying private.nix from 1Password..."
sudo mkdir -p "$(dirname "$PRIVATE_NIX")"
op item get "machines-private-nix" --vault "Personal" --fields content | \
    sed 's/^"//; s/"$//' | \
    sudo tee "$PRIVATE_NIX" > /dev/null
echo "  Deployed to $PRIVATE_NIX"

# --- Step 4: NixOS rebuild ---
echo "[4/6] Building NixOS configuration..."
HOSTNAME=$(hostname)
echo "  Host: $HOSTNAME"
cd "$NIXOS_DIR"
sudo nixos-rebuild switch --impure --flake ".#$HOSTNAME"
echo "  NixOS rebuild complete."

# --- Step 5: chezmoi setup ---
echo "[5/6] Setting up chezmoi..."
chezmoi init --source "$REPO_DIR/dotfiles" --apply
echo "  chezmoi applied."

# Deploy settings.local.json from 1Password
CLAUDE_LOCAL="$HOME/.claude/settings.local.json"
if ! [ -f "$CLAUDE_LOCAL" ]; then
    mkdir -p "$HOME/.claude"
    op item get "claude-settings-local" --vault "Personal" --fields content > "$CLAUDE_LOCAL"
    echo "  Claude settings.local.json deployed."
fi

# --- Step 6: Git hooks ---
echo "[6/6] Setting up git hooks..."
HOOK_FILE="$REPO_DIR/.git/hooks/pre-commit"
cat > "$HOOK_FILE" << 'HOOK'
#!/bin/sh
# Re-add chezmoi-managed files before commit (bidirectional sync)
chezmoi re-add ~/.claude/settings.json 2>/dev/null || true
chezmoi re-add ~/.zshrc 2>/dev/null || true

# Stage any re-added changes
cd "$(git rev-parse --show-toplevel)"
git add dotfiles/ 2>/dev/null || true
HOOK
chmod +x "$HOOK_FILE"
echo "  pre-commit hook installed."

echo ""
echo "=== Bootstrap complete ==="
echo "  Repo:    $REPO_DIR"
echo "  NixOS:   $NIXOS_DIR"
echo "  chezmoi: chezmoi managed"
