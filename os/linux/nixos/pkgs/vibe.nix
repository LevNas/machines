# vibe: ローカル文字起こし GUI (Whisper / Tauri)
#
# nixpkgs 未収載 (packaging request: NixOS/nixpkgs#368788 が stale) のため、
# 公式 GitHub release の deb を autoPatchelf で wrap する自前 derivation。
# Linux 向け公式配布は deb/rpm のみ (AppImage 無し)。
#
# バイナリ構成:
#   - vibe: Tauri GUI 本体 (webkit2gtk-4.1 / gtk3 / libxdo / alsa に動的リンク)
#   - sona: Whisper 推論エンジンのサイドカー (openssl / vulkan / libgomp に動的リンク。
#           whisper.cpp / ffmpeg は静的リンク済みでバンドル .so は無い)
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
, gdk-pixbuf
, glib
, glib-networking
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

  # upstream の .desktop は Categories が空でメニュー分類されないため補完する
  postInstall = ''
    substituteInPlace $out/share/applications/vibe.desktop \
      --replace-fail "Categories=" "Categories=AudioVideo;Audio;Utility;"
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
