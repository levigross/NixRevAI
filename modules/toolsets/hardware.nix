{pkgs}: [
  pkgs.qemu
  pkgs.openocd
  pkgs.pciutils
  pkgs.usbutils
  pkgs.flashrom # read/write/verify SPI flash chips via supported programmers
]
