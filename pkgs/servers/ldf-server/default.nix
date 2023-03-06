{ lib, yarn2nix-moretea, mkYarnPackage, fetchYarnDeps, fetchFromGitHub, nodejs, python3 }:
let
  pin = lib.importJSON ./pin.json;
  workspace = yarn2nix-moretea.mkYarnWorkspace {
    pname = "ldf-server";
    inherit (pin) version;
    inherit nodejs;

    src = fetchFromGitHub {
      owner = "LinkedDataFragments";
      repo = "Server.js";
      rev = "v${pin.version}";
      sha256 = pin.srcSha256;
    };

    packageJSON = ./package.json;

    pkgConfig = {
      hdt = {
        buildInputs = [ nodejs.pkgs.node-gyp python3 ];
        yarnPreBuild = ''
          mkdir -p $HOME/.node-gyp/${nodejs.version}
          echo 9 > $HOME/.node-gyp/${nodejs.version}/installVersion
          ln -sfv ${nodejs}/include $HOME/.node-gyp/${nodejs.version}
          export npm_config_nodedir=${nodejs}
        '';
        postInstall = ''
          node-gyp rebuild
          rm -rf build/Release/obj.target
        '';
      };
    };

    meta = with lib; {
      description = "A Triple Pattern Fragments server for Node.js ";
      homepage = "https://linkeddatafragments.org/";
      license = licenses.mit;
      maintainers = with maintainers; [ dandellion ];
    };
  };
in workspace.ldf-server.overrideAttrs (old: {    

  passthru.workspace = workspace;

  postFixup = ''
    echo STARTING TERRIBLE HACK
    rm "$out/libexec/@ldf/server/deps/@ldf/server/node_modules"
    ln -s "$out/libexec/@ldf/server/node_modules" "$out/libexec/@ldf/server/deps/@ldf/server"
    echo ENDING TERRIBLE HACK
  '';
})
