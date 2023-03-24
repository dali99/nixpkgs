{ lib
, stdenv
, fetchFromGitHub
, pkg-config
, fixDarwinDylibNames
}:

stdenv.mkDerivation rec {
  pname = "capstone";
  version = "5.0-rc2";

  src = fetchFromGitHub {
    owner = "aquynh";
    repo = "capstone";
    rev = version;
    sha256 = "sha256-nB7FcgisBa8rRDS3k31BbkYB+tdqA6Qyj9hqCnFW+ME=";
  };

  # replace faulty macos detection
  postPatch = lib.optionalString stdenv.isDarwin ''
    sed -i 's/^IS_APPLE := .*$/IS_APPLE := 1/' Makefile
  '';

  configurePhase = "patchShebangs make.sh ";
  buildPhase = "PREFIX=$out ./make.sh";

  doCheck = true;
  checkPhase = ''
    # first remove fuzzing steps from check target
    substituteInPlace Makefile --replace "fuzztest fuzzallcorp" ""
    make check
  '';

  installPhase = (lib.optionalString stdenv.isDarwin "HOMEBREW_CAPSTONE=1 ")
    + "PREFIX=$out ./make.sh install";

  nativeBuildInputs = [
    pkg-config
  ] ++ lib.optionals stdenv.isDarwin [
    fixDarwinDylibNames
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Advanced disassembly library";
    homepage    = "http://www.capstone-engine.org";
    license     = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ thoughtpolice ris ];
    mainProgram = "cstool";
    platforms   = lib.platforms.unix;
  };
}
