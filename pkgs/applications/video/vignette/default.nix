{ lib, stdenv, fetchFromGitHub, fetchurl, makeWrapper, makeDesktopItem, linkFarmFromDrvs
, dotnetCorePackages, dotnetPackages, cacert
, ffmpeg_4, alsa-lib, SDL2, lttng-ust, numactl, alsa-plugins
}:

let
  runtimeDeps = [
    ffmpeg_4 alsa-lib SDL2 lttng-ust numactl
  ];

  dotnet-sdk = dotnetCorePackages.sdk_5_0;
  dotnet-runtime = dotnetCorePackages.runtime_5_0;

  # https://docs.microsoft.com/en-us/dotnet/core/rid-catalog#using-rids
  #runtimeId = "ubuntu.20.04-x64";
  runtimeId = "linux-x64";

in stdenv.mkDerivation rec {
  pname = "vignette";
  version = "2021.1025.1";

  src = fetchFromGitHub {
    owner = "vignetteapp";
    repo = "vignette";
    rev = version;
    sha256 = "1vga15yznrg06hp7bpr1baprx35dli83wqnmb87zx88p2wh9v4r1";
  };

  nativeBuildInputs = [
    dotnet-sdk dotnetPackages.Nuget makeWrapper
    # FIXME: Without `cacert`, we will suffer from https://github.com/NuGet/Announcements/issues/49
    cacert
  ];

  nugetDeps = linkFarmFromDrvs "${pname}-nuget-deps" (import ./deps.nix {
    fetchNuGet = { name, version, sha256 }: fetchurl {
      name = "nuget-${name}-${version}.nupkg";
      url = "https://www.nuget.org/api/v2/package/${name}/${version}";
      inherit sha256;
    };
  });

  configurePhase = ''
    runHook preConfigure
    export HOME=$(mktemp -d)
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    export DOTNET_NOLOGO=1
    nuget sources Add -Name nixos -Source "$PWD/nixos"
    nuget init "$nugetDeps" "$PWD/nixos"
    # FIXME: https://github.com/NuGet/Home/issues/4413
    mkdir -p $HOME/.nuget/NuGet
    cp $HOME/.config/NuGet/NuGet.Config $HOME/.nuget/NuGet
    dotnet restore --source "$PWD/nixos" Vignette.Desktop --runtime ${runtimeId}
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    dotnet build Vignette.Desktop \
      --no-restore \
      --configuration Release \
      --runtime ${runtimeId} \
      -p:Version=${version}
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    dotnet publish Vignette.Desktop \
      --no-build \
      --configuration Release \
      --runtime ${runtimeId} \
      --no-self-contained \
      --output $out/lib/vignette
    makeWrapper $out/lib/vignette/Vignette $out/bin/vignette \
      --set DOTNET_ROOT "${dotnet-runtime}" \
      --suffix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeDeps}"
#    for i in 16 32 48 64 96 128 256 512 1024; do
#      install -D ./assets/lazer.png $out/share/icons/hicolor/''${i}x$i/apps/osu\!.png
#    done
    cp -r ${makeDesktopItem {
      desktopName = "Vignette";
      name = "Vignette";
      exec = meta.mainProgram;
      icon = "org.vignetteapp.Vignette";
      comment = meta.description;
      type = "Application";
      categories = "Utility;Graphics;";
    }}/share/applications $out/share
    runHook postInstall
  '';

  fixupPhase = ''
    runHook preFixup
    cp -f ${./Vignette.runtimeconfig.json} "$out/lib/vignette/Vignette.runtimeconfig.json"
    ln -sft $out/lib/vignette ${SDL2}/lib/libSDL2${stdenv.hostPlatform.extensions.sharedLibrary}
    runHook postFixup
  '';

  # Strip breaks the executable.
  dontStrip = true;

  meta = with lib; {
    description = "The open source VTuber software";
    homepage = "https://vignetteapp.org/";
    license = with licenses; [
      mit
      gpl3Only
    ];
    maintainers = with maintainers; [ dandellion ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "vignette";
  };
  passthru.updateScript = ./update.sh;
}
