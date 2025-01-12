{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  rustPlatform,
  polars,
  pyarrow,
}:

buildPythonPackage rec {
  pname = "maplib";
  version = "0.14.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "DataTreehouse";
    repo = "maplib";
    tag = "py-v${version}";
    hash = "sha256-cwXhPj27nilVl/c23+h6II7ehXXrm+WhfLyNYLY7FDY=";
  };


  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit src;
    hash = "sha256-KP7+FW10rSugVlfNOiKgMKJvsTTDvAKoySecRiphLLI=";
  };


  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    rustPlatform.maturinBuildHook
  ];

  propagatedBuildInputs = [
    polars
    pyarrow
  ];

  RUSTC_BOOTSTRAP = 1;

  # Since all packages are workspace, this is fine
  buildAndTestSubdir = "py_maplib";
}

