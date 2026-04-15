{pkgs}: [
  pkgs.hashcat
  pkgs.hashcat-utils
  pkgs.openssl
  # UEFI Secure Boot signature / key-store tooling
  pkgs.efitools # efi-readvar, sbsiglist, hash-to-efi-sig-list, cert-to-efi-sig-list
  pkgs.sbsigntool # sbsign, sbverify, sbattach, sbvarsign
]
