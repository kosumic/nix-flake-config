{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  runCommand,
  kmod,
  v2ray-geoip,
  v2ray-domain-list-community,
  # The pinned NixOS module overrides a legacy v2ray argument; accept it here.
  # v2rayA 2.5 uses its matching core below instead of an external V2Ray binary.
  ...
}: let
  version = "2.5.13";
  releases = {
    x86_64-linux = {
      arch = "x64";
      managerHash = "sha256-g3D4fq9coXdkfsoWyMRKlNWUYyTKLTumNuHg3QlbY1U=";
      coreHash = "sha256-GMEX/ChaTd8cNMpu5lkr2j7cW4VUTU8ebJS2gB9FvSw=";
    };
    aarch64-linux = {
      arch = "arm64";
      managerHash = "sha256-lsJtP6FFjp8sQ8RuO5hh6DH0XiFKToQA2zAW4OK9pd0=";
      coreHash = "sha256-OHz1oVTnZ41XpoGNTY263454IumLzc+egHslJOIp+Oo=";
    };
  };
  release = releases.${stdenvNoCC.hostPlatform.system};
  releaseUrl = "https://github.com/v2rayA/v2rayA/releases/download/v${version}";

  # Keep the official manager and core on the same release until nixpkgs
  # packages both. Hashes come from the release's SHA-256 checksum files.
  core = stdenvNoCC.mkDerivation {
    pname = "v2raya-core";
    inherit version;
    src = fetchurl {
      url = "${releaseUrl}/v2raya_core_linux_${release.arch}_${version}";
      hash = release.coreHash;
    };
    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    nativeBuildInputs = [autoPatchelfHook];
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/v2raya_core"
      runHook postInstall
    '';
    meta = {
      description = "Matching v2rayA proxy core";
      homepage = "https://github.com/v2rayA/v2rayA";
      license = lib.licenses.mpl20;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames releases;
      mainProgram = "v2raya_core";
    };
  };

  # v2rayA 2.5 searches share/v2raya; nixpkgs' data packages use share/v2ray.
  assets = runCommand "v2raya-assets" {} ''
    mkdir -p "$out/share/v2raya"
    ln -s ${v2ray-geoip}/share/v2ray/geoip.dat "$out/share/v2raya/geoip.dat"
    ln -s ${v2ray-domain-list-community}/share/v2ray/geosite.dat "$out/share/v2raya/geosite.dat"
  '';
in
  stdenvNoCC.mkDerivation {
    pname = "v2raya";
    inherit version;
    src = fetchurl {
      url = "${releaseUrl}/v2raya_linux_${release.arch}_${version}";
      hash = release.managerHash;
    };
    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;
    nativeBuildInputs = [autoPatchelfHook makeWrapper];
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/v2rayA"
      ln -s ${core}/bin/v2raya_core "$out/bin/v2raya_core"
      wrapProgram "$out/bin/v2rayA" \
        --prefix PATH : ${lib.makeBinPath [core kmod]} \
        --prefix XDG_DATA_DIRS : ${assets}/share
      runHook postInstall
    '';
    passthru = {inherit core assets;};
    meta = {
      description = "Web client for v2rayA's matching proxy core";
      homepage = "https://github.com/v2rayA/v2rayA";
      license = lib.licenses.agpl3Only;
      sourceProvenance = [lib.sourceTypes.binaryNativeCode];
      platforms = builtins.attrNames releases;
      mainProgram = "v2rayA";
    };
  }
