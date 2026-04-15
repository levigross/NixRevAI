{pkgs}: [
  pkgs.binwalk
  pkgs.foremost
  pkgs.mitmproxy
  pkgs.volatility3
  pkgs.squashfsTools
  pkgs.jefferson
  pkgs.ubi_reader
  pkgs.scalpel
  pkgs.sleuthkit
  pkgs.wireshark
  pkgs."yara-x"
  pkgs.p7zip
  pkgs.rar
  # Platform firmware: extract / parse / security-assess
  pkgs.uefitool # uefitool, uefiextract, uefifind
  pkgs.psptool # AMD PSP directory parser
  pkgs.biosutilities # AMI/Phoenix/Insyde/Dell/Apple capsule extractors (platomav)
  pkgs.uefi-firmware-parser # scriptable pure-python FV parser (ahupp)
  pkgs.coreboot-utils # ifdtool, cbfstool, amdfwtool (AMD PSP/BIOS dir)
  pkgs.fiano # Google Go UEFI toolkit (utk, fmap, ...)
  pkgs.chipsec # Platform Security Assessment Framework
]
