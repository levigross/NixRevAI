{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  pythonRelaxDepsHook,
  setuptools,
  dissect-util,
  pefile,
}:
buildPythonPackage rec {
  pname = "biosutilities";
  version = "25.7.1";
  pyproject = true;

  disabled = pythonOlder "3.10";

  # Upstream does not cut git tags; pin to the commit that carries the
  # `BIOSUtilities v25.07.01` release message (matching PyPI 25.7.1).
  src = fetchFromGitHub {
    owner = "platomav";
    repo = "BIOSUtilities";
    rev = "70c3a0852a6aa2643c8114ea73bc833e3b4cff0d";
    hash = "sha256-zRCHLVzMLGfvJ6tYeTp6bI3KfsHYF0AZEMbY/lNic3w=";
  };

  build-system = [setuptools];

  nativeBuildInputs = [pythonRelaxDepsHook];

  # Upstream pins `dissect.util == 3.20` and `pefile == 2023.2.7`; nixpkgs
  # ships newer patch-compatible releases. Relax the exact-pin so the
  # runtime extras resolve against whatever nixpkgs provides.
  pythonRelaxDeps = [
    "dissect.util"
    "pefile"
  ];

  # Pull in the optional extras as first-class dependencies so every
  # extractor (AMI PFAT, Apple IM4P, etc.) is immediately usable.
  dependencies = [
    dissect-util
    pefile
  ];

  pythonImportsCheck = ["biosutilities"];

  meta = {
    description = "Various BIOS utilities for modding and research (AMI/Phoenix/Insyde/Dell/Apple/Award/VAIO/Fujitsu/Portwell/Panasonic/Toshiba)";
    homepage = "https://github.com/platomav/BIOSUtilities";
    changelog = "https://github.com/platomav/BIOSUtilities/blob/main/CHANGELOG";
    license = lib.licenses.bsd2Patent;
    mainProgram = "biosutilities";
    maintainers = [];
  };
}
