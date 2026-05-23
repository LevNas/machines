{ ... }:

{
  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;  # 初期セットアップ用、後でfalseに
      PermitRootLogin = "no";
    };
  };

  # ファイアウォール
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];  # SSH
  };
}
