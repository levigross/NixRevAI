{ pkgs }:
[
  (pkgs.python3.withPackages (ps: with ps; [
    httpx
    ghidra-bridge
    pyghidra
    r2pipe
    unicorn
    pyyaml
    pwntools
    lief
    cryptography
    mcp
    angr
    angrcli
  ]))
]
