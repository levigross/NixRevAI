{ pkgs, ghidra }:
let
  inherit (pkgs) lib fetchFromGitHub;

  builders = pkgs.callPackage ./build-ghidra-extension.nix {
    inherit ghidra;
    jdk = pkgs.openjdk21;
  };

  inherit (builders) buildGhidraExtension buildGhidraScripts;
in
{
  findcrypt = buildGhidraExtension (finalAttrs: {
    pname = "findcrypt";
    version = "3.1.6";

    src = fetchFromGitHub {
      owner = "antoniovazquezblanco";
      repo = "GhidraFindcrypt";
      rev = "v${finalAttrs.version}";
      hash = "sha256-9y1cPkQNZ3QyPYwL8ueZ0HGyEuo5L1n3Q3/mNRvOUgM=";
    };

    meta = {
      description = "Ghidra analysis plugin to locate cryptographic constants";
      homepage = "https://github.com/antoniovazquezblanco/GhidraFindcrypt";
      license = lib.licenses.gpl3;
    };
  });

  ghidra-firmware-utils = buildGhidraExtension (finalAttrs: {
    pname = "ghidra-firmware-utils";
    version = "2026.01.14";

    src = fetchFromGitHub {
      owner = "al3xtjames";
      repo = "ghidra-firmware-utils";
      rev = finalAttrs.version;
      hash = "sha256-FEjcqsisMvmNCQikon/3EEkLEtgKmGRBl/WwZebP+/A=";
    };

    meta = {
      description = "Ghidra utilities for analyzing PC firmware";
      homepage = "https://github.com/al3xtjames/ghidra-firmware-utils";
      license = lib.licenses.asl20;
    };
  });

  ret-sync = buildGhidraExtension {
    pname = "ret-sync-ghidra";
    version = "0-unstable-2026-02-15";

    src = fetchFromGitHub {
      owner = "bootleg";
      repo = "ret-sync";
      rev = "60e7b0fd1bea7bad44da7688801b2bd12fb02040";
      hash = "sha256-pHj9B3X/2ZnQIalZ5yf+MoDZ0jph9/XUStuE28tvjOY=";
    };

    preConfigure = ''
      cd ext_ghidra
    '';

    # The Gradle build produces zips for multiple Ghidra versions; keep only
    # the one matching our Ghidra.
    preInstall = ''
      correct_version=$(ls dist | grep ${ghidra.version})
      mv dist/$correct_version dist/safe.zip
      rm dist/ghidra*
      mv dist/safe.zip dist/$correct_version
    '';

    meta = {
      description = "Reverse-Engineering Tools SYNChronization for Ghidra";
      homepage = "https://github.com/bootleg/ret-sync";
      license = lib.licenses.gpl3Only;
    };
  };

  ghidra-golanganalyzerextension = buildGhidraExtension {
    pname = "Ghidra-GolangAnalyzerExtension";
    version = "0-unstable-2026-01-17";

    src = fetchFromGitHub {
      owner = "mooncat-greenpy";
      repo = "Ghidra_GolangAnalyzerExtension";
      rev = "3f668e88661883f4112cc2c2f7d7145c506747d0";
      hash = "sha256-XavjD5xfjKnzPwxKYqTRRZD6zgPn/9FzPOcCkphuJ5I=";
    };

    # Upstream restructured into a subdirectory after v1.2.4.
    preConfigure = ''
      cd GolangAnalyzerExtension
    '';

    meta = {
      description = "Facilitates the analysis of Golang binaries using Ghidra";
      homepage = "https://github.com/mooncat-greenpy/Ghidra_GolangAnalyzerExtension";
      license = lib.licenses.mit;
    };
  };

  ghidraninja-ghidra-scripts = buildGhidraScripts {
    pname = "ghidraninja-ghidra-scripts";
    version = "unstable-2020-10-07";

    src = fetchFromGitHub {
      owner = "ghidraninja";
      repo = "ghidra_scripts";
      rev = "99f2a8644a29479618f51e2d4e28f10ba5e9ac48";
      hash = "sha256-aElx0mp66/OHQRfXwTkqdLL0gT2T/yL00bOobYleME8=";
    };

    postPatch = ''
      substituteInPlace binwalk.py \
        --replace-fail 'subprocess.call(["binwalk"' \
                       'subprocess.call(["${lib.getExe pkgs.binwalk}"'
      substituteInPlace yara.py \
        --replace-fail 'subprocess.check_output(["yara"' \
                       'subprocess.check_output(["${lib.getExe pkgs.yara}"'
      substituteInPlace YaraSearch.py \
        --replace-fail '"yara "' '"${lib.getExe pkgs.yara} "'
      rm swift_demangler.py
    '';

    meta = {
      description = "Scripts for the Ghidra software reverse engineering suite";
      homepage = "https://github.com/ghidraninja/ghidra_scripts";
      license = with lib.licenses; [ gpl3Only gpl2Only ];
    };
  };

  sleighdevtools = buildGhidraExtension {
    pname = "sleighdevtools";
    version = lib.getVersion ghidra;

    src = "${ghidra}/lib/ghidra/Extensions/Ghidra/${ghidra.distroPrefix}_SleighDevTools.zip";
    dontUnpack = true;
    dontBuild = true;
    buildInputs = [ pkgs.python3 ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/ghidra/Ghidra/Extensions
      unzip -d $out/lib/ghidra/Ghidra/Extensions $src

      runHook postInstall
    '';

    meta = {
      inherit (ghidra.meta) homepage license;
      description = "Sleigh language development tools including external disassembler capabilities";
    };
  };
}
