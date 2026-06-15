{ lib, ... }:

{
  # Secure Boot via lanzaboote
  # systemd-boot を無効化し、lanzaboote に置き換え
  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
}
