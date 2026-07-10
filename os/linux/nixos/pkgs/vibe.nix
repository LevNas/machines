# vibe: ローカル文字起こし GUI (Whisper / Tauri)
#
# nixpkgs 未収載 (packaging request: NixOS/nixpkgs#368788 が stale) のため、
# 公式 GitHub release の deb を autoPatchelf で wrap する自前 derivation。
# Linux 向け公式配布は deb/rpm のみ (AppImage 無し)。
#
# バイナリ構成:
#   - vibe: Tauri GUI 本体 (webkit2gtk-4.1 / gtk3 / libxdo / alsa に動的リンク)
#   - sona: Whisper 推論エンジンのサイドカー (openssl / vulkan / libgomp に動的リンク。
#           whisper.cpp は静的リンク済みでバンドル .so は無い)
#
# リンク依存以外の実行時依存 (deb の control Depends と実挙動から。NEEDED には現れない):
#   - ffmpeg: vibe が外部 CLI として exec する (無いと transcribe 時に "ffmpeg not found" エラー)
#     → wrapper の PATH に注入
#   - GStreamer plugins (base/good 等): webkit のメディア再生・録音が実行時に要求。
#     欠けると WebKitWebProcess が createAudioSink で coredump し UI がフリーズする
#     → buildInputs に置けば wrapGAppsHook3 が GST_PLUGIN_SYSTEM_PATH_1_0 を注入
#
# バージョン更新手順:
#   1. version を上げる
#   2. nix store prefetch-file https://github.com/thewh1teagle/vibe/releases/download/v<ver>/vibe_<ver>_amd64.deb
#      で hash を更新
{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, wrapGAppsHook3
, alsa-lib
, cairo
, ffmpeg
, gdk-pixbuf
, glib
, glib-networking
, gst_all_1
, gtk3
, libsoup_3
, openssl
, vulkan-loader
, webkitgtk_4_1
, xdotool
}:

stdenv.mkDerivation rec {
  pname = "vibe";
  version = "3.0.20";

  src = fetchurl {
    url = "https://github.com/thewh1teagle/vibe/releases/download/v${version}/vibe_${version}_amd64.deb";
    hash = "sha256-+7LtOju3C0Eri0GQXrvqtKFDy/uhYFHS9g/XMG2tPek=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    cairo
    gdk-pixbuf
    glib
    # libsoup の TLS backend。モデルダウンロード (https) に必須。
    # wrapGAppsHook3 が GIO_EXTRA_MODULES として wrapper に注入する
    glib-networking
    # webkit のメディア再生・録音 (appsink/autoaudiosink 等)。wrapGAppsHook3 が
    # GST_PLUGIN_SYSTEM_PATH_1_0 を注入する。libav は ffmpeg 系コーデックの補完
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gtk3
    libsoup_3
    openssl
    # libstdc++ / libgomp (sona が要求)
    (lib.getLib stdenv.cc.cc)
    # sona の GPU (Vulkan) 推論。Mesa 環境 (AMD/Intel) はこれで有効化される
    vulkan-loader
    webkitgtk_4_1
    xdotool
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out/
    runHook postInstall
  '';

  # upstream の .desktop は Categories が空でメニュー分類されない・
  # MimeType (x-scheme-handler) 宣言に対して Exec に %u が無い、をそれぞれ補完する
  postInstall = ''
    substituteInPlace $out/share/applications/vibe.desktop \
      --replace-fail "Categories=" "Categories=AudioVideo;Audio;Utility;" \
      --replace-fail "Exec=vibe" "Exec=vibe %u"
  '';

  # ffmpeg は vibe が外部 CLI として exec する実行時依存 (deb control の Depends 参照)
  preFixup = ''
    gappsWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ ffmpeg ]})
  '';

  meta = {
    description = "Offline audio/video transcription app powered by Whisper";
    homepage = "https://github.com/thewh1teagle/vibe";
    changelog = "https://github.com/thewh1teagle/vibe/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "vibe";
  };
}
