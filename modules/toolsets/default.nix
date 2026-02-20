{
  pkgs,
  enableDevTools ? true,
  enablePythonToolset ? true,
  enableHardwareToolset ? true,
}: let
  reversing = import ./reversing.nix {inherit pkgs;};
  debugging = import ./debugging.nix {inherit pkgs;};
  binaryAnalysis = import ./binary-analysis.nix {inherit pkgs;};
  forensics = import ./forensics.nix {inherit pkgs;};
  crypto = import ./crypto.nix {inherit pkgs;};
  hardware = import ./hardware.nix {inherit pkgs;};
  python = import ./python.nix {inherit pkgs;};
  devTools = import ./dev-tools.nix {inherit pkgs;};

  packagesByGroup = {
    reversing = reversing.packages;
    inherit
      debugging
      binaryAnalysis
      forensics
      crypto
      hardware
      python
      devTools
      ;
  };

  allPackages =
    packagesByGroup.reversing
    ++ packagesByGroup.debugging
    ++ packagesByGroup.binaryAnalysis
    ++ packagesByGroup.forensics
    ++ packagesByGroup.crypto
    ++ pkgs.lib.optionals enableHardwareToolset packagesByGroup.hardware
    ++ pkgs.lib.optionals enablePythonToolset packagesByGroup.python
    ++ pkgs.lib.optionals enableDevTools packagesByGroup.devTools;
in {
  inherit packagesByGroup allPackages;

  reversingMeta = reversing.meta;
}
