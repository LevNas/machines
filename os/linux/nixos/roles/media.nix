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

    # 出力デバイスのフォールバック優先度。
    # 既定の priority.session: onboard(pro-output-0)=1500, HDMI=1100-1196, Anker(USB)=1109。
    # BT イヤホン(FreeClip)は configured default のため在席時はそれが選ばれ、オフ時のみ
    # priority.session によるフォールバックが効く。素の値だと Anker が最下位で onboard(無音)に
    # 負けるため、Anker を最上位に引き上げる。
    # TODO: 2つ目のドック(非Anker)接続時にモニター内蔵(HDMI)へ落とすには、当該 HDMI 出力の
    #       node.name を特定して同様に priority.session を onboard(1500)超へ設定する。
    wireplumber.extraConfig."51-output-fallback-priority" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "alsa_output.usb-KTMicro_Anker_USB_Audio-00.analog-stereo"; }
          ];
          actions.update-props."priority.session" = 2000;
        }
      ];
    };
  };

  # ブラウザ・メディアプレーヤー
  environment.systemPackages = with pkgs; [
    firefox
    brave
    # mpv: 動画プレーヤー。ytui (mise: home 限定) の再生バックエンド。
    mpv
    # vibe: ローカル文字起こし GUI (Whisper/Tauri)。nixpkgs 未収載のため deb を wrap
    (callPackage ../pkgs/vibe.nix { })
  ];
}
