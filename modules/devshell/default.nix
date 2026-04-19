{reenvInputs}: {
  lib,
  config,
  ...
}: {
  options.reenv = {
    nixpkgs = lib.mkOption {
      type = lib.types.unspecified;
      default = reenvInputs.nixpkgs;
      defaultText = lib.literalExpression "reenvInputs.nixpkgs";
      description = ''
        Nixpkgs flake input used to build the ReEnv dev shell.

        Defaults to the nixpkgs that ReEnv itself is pinned against. Downstream
        flakes consuming `reenv.flakeModules.default` can override this to use
        their own nixpkgs pin.
      '';
    };

    extraOverlays = lib.mkOption {
      type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo (lib.types.attrsOf lib.types.unspecified)));
      default = [];
      description = ''
        Extra overlays to stack on top of ReEnv's overlay when importing
        nixpkgs for the dev shell.
      '';
    };

    enableDevTools = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable general development tools in the default dev shell.";
    };

    enablePythonToolset = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Python reversing and automation tooling in the default dev shell.";
    };

    enableHardwareToolset = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hardware and emulation tooling in the default dev shell.";
    };
  };

  config.perSystem = {system, ...}: let
    pkgs = import config.reenv.nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays =
        [
          (import ../overlays/default.nix {inherit reenvInputs;})
        ]
        ++ config.reenv.extraOverlays;
    };

    reenvToolsets = import ../toolsets/default.nix {
      inherit pkgs;
      enableDevTools = config.reenv.enableDevTools;
      enablePythonToolset = config.reenv.enablePythonToolset;
      enableHardwareToolset = config.reenv.enableHardwareToolset;
    };
  in {
    _module.args.pkgs = pkgs;
    _module.args.reenvToolsets = reenvToolsets;

    devShells.default = pkgs.mkShell {
      CGO_ENABLED = 0;
      GHIDRA_INSTALL_DIR = "${pkgs.ghidra-bin}/lib/ghidra";
      NIX_GHIDRAHOME = "${pkgs.ghidra-with-extensions}/lib/ghidra/Ghidra";
      JAVA_HOME = "${pkgs.openjdk21}";

      LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
        pkgs.stdenv.cc.cc.lib
        pkgs.boost
      ];

      buildInputs = reenvToolsets.allPackages;

      shellHook = let
        mcpConfig = reenvInputs.mcp-servers-nix.lib.mkConfig pkgs {
          flavor = "claude-code";
          programs = {
            context7.enable = true;
          };
          settings.servers =
            {
              ghidra-mcp = {
                command = "${pkgs.lib.getExe pkgs.uv}";
                args = [
                  "run"
                  "${pkgs.ghidra-mcp}/libexec/ghidra-mcp/bridge_mcp_ghidra.py"
                ];
              };
            }
            // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
              framewalk = {
                command = "${reenvInputs.framewalk.packages.${pkgs.stdenv.hostPlatform.system}.framewalk-mcp}/bin/framewalk-mcp";
                args = [];
              };
            };
        };
      in ''
        ln -sf ${mcpConfig} .mcp.json
        export SLEIGHHOME="${pkgs.rizinPlugins.rz-ghidra}/lib/rizin/plugins/rz_ghidra_sleigh"
      '';
    };
  };
}
