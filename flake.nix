{
  description = "re-toolkit";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    # Stable channel — avoids the churn and intermittent regressions of
    # nixpkgs-unstable (e.g. angr losing setuptools-rust in April 2026).
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    # Separately pinned to nixos-25.05 (the last stable with CMake 3.x).
    # retdec 5.0 bundles an LLVM source tree whose CMakeLists requires
    # `cmake_minimum_required` below 3.5, which CMake 4 — shipped on
    # nixos-25.11 and on unstable — refuses.
    nixpkgs-retdec.url = "github:NixOS/nixpkgs/nixos-25.05";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghidra-mcp = {
      url = "github:bethington/ghidra-mcp";
      flake = false;
    };
    # pwndbg was removed from nixpkgs in 2025-02 because its dependency pinning
    # (e.g. unicorn) is too burdensome for nixpkgs. Upstream ships its own flake
    # with uv2nix-managed deps; consume it directly as recommended.
    pwndbg = {
      url = "github:pwndbg/pwndbg";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}: let
    # The devshell module and overlay both close over ReEnv's own inputs,
    # so they continue to reference ReEnv's bundled `nixpkgs-retdec`,
    # `pwndbg`, and `mcp-servers-nix` even when the exported flakeModule
    # or overlay is imported into a foreign flake.
    devshellModule = import ./modules/devshell/default.nix {reenvInputs = inputs;};
    reenvOverlay = import ./modules/overlays/default.nix {reenvInputs = inputs;};
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [devshellModule];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;

        # Re-export the ReEnv-specific custom packages so plain-flake
        # consumers can do `reenv.packages.<system>.pwndbg` without having
        # to apply the overlay themselves.
        packages =
          {
            inherit
              (pkgs)
              pwndbg
              pwndbg-lldb
              retdec
              ghidra-bin
              ghidra-mcp
              ghidra-with-extensions
              ;
          }
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isx86_64 {
            inherit (pkgs) bindiff;
          };
      };

      flake = {
        flakeModules.default = devshellModule;

        overlays.default = reenvOverlay;

        # Per-toolset builders. Each takes `{ pkgs }` (already overlayed with
        # ReEnv's overlay, or an equivalent) and returns a list of packages
        # that a consumer can drop straight into a `mkShell.buildInputs`.
        lib.toolsets = {
          reversing = import ./modules/toolsets/reversing.nix;
          debugging = import ./modules/toolsets/debugging.nix;
          binaryAnalysis = import ./modules/toolsets/binary-analysis.nix;
          forensics = import ./modules/toolsets/forensics.nix;
          crypto = import ./modules/toolsets/crypto.nix;
          hardware = import ./modules/toolsets/hardware.nix;
          python = import ./modules/toolsets/python.nix;
          devTools = import ./modules/toolsets/dev-tools.nix;
        };
      };
    };
}
