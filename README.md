# machines

Multi-machine environment configuration for NixOS, WSL, and Windows.

## Structure

```
os/           - OS-specific implementations
dotfiles/     - Cross-platform dotfiles (chezmoi)
scripts/      - Bootstrap scripts
docs/         - Role definitions and setup guides
```

## Managed Machines

| Host | OS | Purpose |
|---|---|---|
| mynix | NixOS | Personal: development, gaming, media |
| work-wsl | WSL | Work: development |
| work-win | Windows 11 | Work: business |
| nixvm-win | Windows VM | Personal: tax filing etc. |

## Quick Start (NixOS)

```bash
# Bootstrap a new NixOS machine
curl -fsSL https://raw.githubusercontent.com/LevNas/machines/main/scripts/bootstrap-nixos.sh | bash

# Or manually
sudo nixos-rebuild switch --impure --flake ./os/linux/nixos#mynix
```
