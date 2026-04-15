{pkgs}: [
  (pkgs.python3.withPackages (ps:
    with ps; [
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
      pefile # PE32/PE32+ parsing — dissect extracted UEFI/DXE modules
      capstone # multi-arch disassembler used by pefile/scripts
    ]))
]
