{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  hatchling,
  hatch-vcs,
  cryptography,
  prettytable,
}:
buildPythonPackage rec {
  pname = "psptool";
  version = "3.4";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "PSPReverse";
    repo = "PSPTool";
    tag = version;
    hash = "sha256-SI6XU8oPKt7f2iDpYiBIZwCjWA/gOVseb9HZzGFj7/I=";
  };

  # hatch-vcs reads the version from git metadata which is absent in the
  # source archive; pin it so the build is deterministic.
  env.HATCH_VCS_PRETEND_VERSION = version;

  build-system = [
    hatchling
    hatch-vcs
  ];

  dependencies = [
    cryptography
    prettytable
  ];

  # Upstream tests depend on real ROM fixtures that ship out-of-band.
  doCheck = false;

  pythonImportsCheck = ["psptool"];

  meta = {
    description = "Parse, inspect, and manipulate AMD Platform Security Processor firmware blobs";
    homepage = "https://github.com/PSPReverse/PSPTool";
    changelog = "https://github.com/PSPReverse/PSPTool/releases/tag/${version}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "psptool";
    maintainers = [];
  };
}
