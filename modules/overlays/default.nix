{reenvInputs}: final: prev: let
  system = final.stdenv.hostPlatform.system;

  retdecPkgs = import reenvInputs.nixpkgs-retdec {
    inherit system;
    config.allowUnfree = true;
  };

  ghidra-extensions = import ../pkgs/ghidra-extensions.nix {
    pkgs = final;
    ghidra = final.ghidra-bin;
  };
in {
  # retdec 5.0 doesn't build with CMake 4 / GCC 14 on unstable.
  retdec = retdecPkgs.retdec;

  # Google BinDiff - not in nixpkgs, packaged from pre-built .deb.
  bindiff = final.callPackage ../pkgs/bindiff.nix {};

  # pwndbg was removed from nixpkgs (2025-02). Pull from its upstream flake,
  # which ships both a gdb-flavored and an lldb-flavored variant.
  pwndbg = reenvInputs.pwndbg.packages.${system}.pwndbg;
  pwndbg-lldb = reenvInputs.pwndbg.packages.${system}.pwndbg-lldb;

  # Ghidra binary release (faster than the source build in nixpkgs proper).
  ghidra-bin = final.callPackage ../pkgs/ghidra-bin.nix {};

  # GhidraMCP server extension. The source tree comes from the `ghidra-mcp`
  # flake input (declared with `flake = false`), so `nix flake update` actually
  # updates the build — previously the source rev was hardcoded inside the
  # derivation and the flake input was silently dead.
  ghidra-mcp = final.callPackage ../pkgs/ghidra-mcp.nix {
    ghidra = final.ghidra-bin;
    src = reenvInputs.ghidra-mcp;
  };

  # Scoped attrset of Ghidra extensions (findcrypt, firmware-utils, etc.).
  inherit ghidra-extensions;

  # Ghidra base with the ReEnv-curated extension set pre-applied. Consumers
  # who want a different set can call `final.ghidra-bin.withExtensions` with
  # attrs from `final.ghidra-extensions` plus `final.ghidra-mcp`.
  ghidra-with-extensions = final.ghidra-bin.withExtensions [
    final.ghidra-mcp
    ghidra-extensions.findcrypt
    ghidra-extensions.ghidra-firmware-utils
    ghidra-extensions.ret-sync
    ghidra-extensions.ghidra-golanganalyzerextension
    ghidra-extensions.ghidraninja-ghidra-scripts
    ghidra-extensions.sleighdevtools
  ];

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

      # PSPTool - AMD PSP firmware parser/inspector. Not in nixpkgs.
      psptool = psFinal.callPackage ../pkgs/psptool.nix {};

      # BIOSUtilities - platomav's multi-vendor BIOS/capsule extractors.
      biosutilities = psFinal.callPackage ../pkgs/biosutilities.nix {};
    };
  };

  # Top-level aliases so `pkgs.<tool>` exposes the CLI directly, matching
  # how other callers reach it (e.g. `lib.getExe pkgs.psptool`).
  psptool = final.python3.pkgs.psptool;
  biosutilities = final.python3.pkgs.biosutilities;
}
