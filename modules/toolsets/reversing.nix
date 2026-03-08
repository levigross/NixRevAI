{pkgs}: let
  ghidra-bin = pkgs.callPackage ../pkgs/ghidra-bin.nix {};

  ghidraMCP = pkgs.callPackage ../pkgs/ghidra-mcp.nix {
    ghidra = ghidra-bin;
  };

  ghidraExts = import ../pkgs/ghidra-extensions.nix {
    inherit pkgs;
    ghidra = ghidra-bin;
  };

  ghidraWithExtensions = ghidra-bin.withExtensions [
    ghidraMCP
    ghidraExts.findcrypt
    ghidraExts.ghidra-firmware-utils
    ghidraExts.ret-sync
    ghidraExts.ghidra-golanganalyzerextension
    ghidraExts.ghidraninja-ghidra-scripts
    ghidraExts.sleighdevtools
  ];

  rizinWithPlugins = pkgs.rizin.withPlugins (ps: with ps; [jsdec rz-ghidra sigdb]);
in {
  meta = {
    ghidra = ghidraWithExtensions;
    ghidraBase = ghidra-bin;
    ghidraMcp = ghidraMCP;
  };

  packages =
    [
      pkgs.apktool
      ghidraWithExtensions
      rizinWithPlugins
      pkgs.radare2
      pkgs.retdec
      pkgs.cutter
      pkgs.binaryninja-free
      pkgs.jadx
      pkgs.krakatau2
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isx86_64 [
      pkgs.bindiff
      pkgs.wineWowPackages.stableFull
    ];
}
