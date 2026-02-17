{ inputs, lib, config, ... }:
{
  options.reenv = {
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

  config.perSystem =
    { system
    , ...
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (import ../overlays/default.nix {
            inherit inputs system;
          })
        ];
      };

      reenvToolsets = import ../toolsets/default.nix {
        inherit pkgs inputs;
        enableDevTools = config.reenv.enableDevTools;
        enablePythonToolset = config.reenv.enablePythonToolset;
        enableHardwareToolset = config.reenv.enableHardwareToolset;
      };
    in
    {
      _module.args.pkgs = pkgs;
      _module.args.reenvToolsets = reenvToolsets;

      devShells.default = pkgs.mkShell {
        CGO_ENABLED = 0;
        GHIDRA_INSTALL_DIR = "${reenvToolsets.reversingMeta.ghidraBase}/lib/ghidra";
        NIX_GHIDRAHOME = "${reenvToolsets.reversingMeta.ghidra}/lib/ghidra/Ghidra";
        JAVA_HOME = "${pkgs.openjdk21}";

        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
          pkgs.stdenv.cc.cc.lib
          pkgs.boost
        ];

        buildInputs = reenvToolsets.allPackages;

        shellHook =
          let
            mcpConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
              flavor = "claude-code";
              programs = {
                context7.enable = true;
              };
              settings.servers = {
                ghidra-mcp = {
                  command = "${pkgs.lib.getExe pkgs.uv}";
                  args = [
                    "run"
                    "${inputs.ghidra-mcp}/bridge_mcp_ghidra.py"
                  ];
                };
              };
            };
          in
          ''
            if [ -L ".mcp.json" ]; then
              unlink .mcp.json
            fi
            ln -sf ${mcpConfig} .mcp.json
            export SLEIGHHOME="${pkgs.rizinPlugins.rz-ghidra}/lib/rizin/plugins/rz_ghidra_sleigh"
          '';
      };
    };
}
