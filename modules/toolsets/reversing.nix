{pkgs}: let
  rizinWithPlugins = pkgs.rizin.withPlugins (ps: with ps; [jsdec rz-ghidra sigdb]);
in
  [
    pkgs.apktool
    pkgs.ghidra-with-extensions
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
  ]
