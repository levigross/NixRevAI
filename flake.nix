{
  description = "re-toolkit";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    # Pinned for retdec 5.0 which doesn't build with CMake 4 / GCC 14
    nixpkgs-retdec.url = "github:NixOS/nixpkgs/nixos-25.05";
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghidra-mcp = {
      url = "github:bethington/ghidra-mcp";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [ ./modules/devshell/default.nix ];
    };
}
