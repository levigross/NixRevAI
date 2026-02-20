{
  inputs,
  system,
}: let
  retdecPkgs = import inputs.nixpkgs-retdec {
    inherit system;
    config.allowUnfree = true;
  };
in
  final: prev: {
    # retdec 5.0 doesn't build with CMake 4 / GCC 14 on unstable.
    retdec = retdecPkgs.retdec;

    # Google BinDiff - not in nixpkgs, packaged from pre-built .deb.
    bindiff = final.callPackage ../pkgs/bindiff.nix {};

    # pyGhidra 3.0.2 requires JPype1 == 1.5.2; nixpkgs has 1.6.0.
    python3 = prev.python3.override {
      packageOverrides = psFinal: psPrev: {
        jpype1 = psPrev.jpype1.overridePythonAttrs {
          version = "1.5.2";
          src = final.fetchFromGitHub {
            owner = "originell";
            repo = "jpype";
            tag = "v1.5.2";
            hash = "sha256-Q5/umU7JHiro+7YuC6nVG9ocpQ/Yc4LGa5+7SGGARTo=";
          };
        };

        pyghidra = psFinal.callPackage ../pkgs/pyghidra.nix {};
      };
    };
  }
