{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  openssl,
  pkg-config,
  # libkrb5
}:

buildPythonPackage rec {
  pname = "connectorx";
  version = "0.3.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "sfu-db";
    repo = "connector-x";
    rev = "v${version}";
    hash = "sha256-L/tI2Lux+UnXZrpBxXX193pvb34hr5kqWo0Ncb1V+R0=";
  };

  # Can't use buildAndTestDir, since it needs to change in cargoDeps as well
  prePatch = ''
    cd connectorx-python
  '';

  patchPhase = ''
    runHook prePatch

    # The libgssapi-sys in the lockfile is hardcoded to look for gssapi in /usr/lib64. This is fixed in a newer version
    substituteInPlace "../connectorx/Cargo.toml" \
      --replace 'tiberius = {version = "0.5", features = ["rust_decimal", "chrono", "integrated-auth-gssapi"], optional = true}' \
        'tiberius = {version = "0.5", features = ["rust_decimal", "chrono"], optional = true}'

    # fetchCargoVendor *NEEDS* a version to work
    substituteInPlace "../connectorx/Cargo.toml" \
      --replace-warn 'serde = {optional = true}' \
        'serde = {version = "1", optional = true}'

    runHook postPatch
  '';

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src prePatch;
    hash = "sha256-UUGWQFb1JrIZrqA3w/1lpeOrbeYvOFkidt/1k7bFd4A=";
  };

  nativeBuildInputs = [
    pkg-config
    rustPlatform.bindgenHook
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  buildInputs = [
    openssl
    # libkrb5.dev
  ];

  OPENSSL_NO_VENDOR = 1;
}
