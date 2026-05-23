{ pkgs, ... }:

{
  programs._1password.enable = true;
  programs._1password-gui.enable = true;
  # polkitPolicyOwners is set per-host (requires username from private.nix)

  environment.systemPackages = with pkgs; [
    _1password-cli
  ];
}
