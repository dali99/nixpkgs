{ lib, buildDunePackage, fetchFromGitHub, dune-configurator, ladspaH }:

buildDunePackage rec {
  pname = "ladspa";
  version = "0.2.0";

  useDune2 = true;

  src = fetchFromGitHub {
    owner = "savonet";
    repo = "ocaml-ladspa";
    rev = "v${version}";
    sha256 = "0vcknkhlrg5z0lrs82vf6cw106nas802q9rawjwgwah6mszsvl92";
  };

  buildInputs = [ dune-configurator ];
  propagatedBuildInputs = [ ladspaH ];

  meta = with lib; {
    homepage = "https://github.com/savonet/ocaml-alsa";
    description = "Bindings for the LADSPA API which provides audio effects";
    license = licenses.lgpl21Only;
    maintainers = with maintainers; [ dandellion ];
  };
}
