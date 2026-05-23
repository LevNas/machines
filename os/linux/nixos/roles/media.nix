{ pkgs, ... }:

{
  # サウンド (PipeWire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  # ブラウザ
  environment.systemPackages = with pkgs; [
    firefox
    brave
  ];
}
