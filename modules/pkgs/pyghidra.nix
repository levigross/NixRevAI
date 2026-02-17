{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  jpype1,
  packaging,
}:

buildPythonPackage {
  pname = "pyghidra";
  version = "3.0.2";
  pyproject = true;

  src = fetchPypi {
    pname = "pyghidra";
    version = "3.0.2";
    hash = "sha256-ea1P1XHjLzQ88/zb2E/G4zPvGiZHWjqPcrYpqfPIedo=";
  };

  build-system = [ setuptools ];

  dependencies = [
    jpype1
    packaging
  ];

  # Tests require a running Ghidra instance.
  doCheck = false;

  pythonImportsCheck = [ "pyghidra" ];

  meta = {
    description = "Native CPython for Ghidra";
    homepage = "https://github.com/NationalSecurityAgency/ghidra";
    license = lib.licenses.asl20;
  };
}
