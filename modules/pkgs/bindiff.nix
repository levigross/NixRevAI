{ lib
, stdenv
, fetchurl
, autoPatchelfHook
, dpkg
, glibc
, gcc-unwrapped
, jdk17
, makeWrapper
}:

stdenv.mkDerivation rec {
  pname = "bindiff";
  version = "8";

  src = fetchurl {
    url = "https://github.com/google/bindiff/releases/download/v${version}/bindiff_${version}_amd64.deb";
    sha256 = "1njd5w4mymxy9rms0xyplmmjgb46ai40wdwl6xrzd7aajzir06c2";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    glibc
    gcc-unwrapped.lib
  ];

  unpackPhase = ''
    dpkg-deb -x $src .
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/opt/bindiff $out/etc/opt/bindiff

    # Install native binaries
    cp opt/bindiff/bin/bindiff $out/opt/bindiff/
    cp opt/bindiff/bin/binexport2dump $out/opt/bindiff/
    cp opt/bindiff/libexec/bindiff_config_setup $out/opt/bindiff/

    # Install the Java UI jar
    cp opt/bindiff/bin/bindiff.jar $out/opt/bindiff/

    # Install Ghidra BinExport extension
    if [ -d opt/bindiff/extra/ghidra ]; then
      cp -r opt/bindiff/extra/ghidra $out/opt/bindiff/
    fi

    # Install config
    cp etc/opt/bindiff/bindiff.json $out/etc/opt/bindiff/

    # Install license
    cp opt/bindiff/LICENSE $out/opt/bindiff/

    # Create wrapper for the CLI differ
    makeWrapper $out/opt/bindiff/bindiff $out/bin/bindiff

    # Create wrapper for binexport2dump
    makeWrapper $out/opt/bindiff/binexport2dump $out/bin/binexport2dump

    # Create wrapper for the Java UI
    makeWrapper ${jdk17}/bin/java $out/bin/bindiff-ui \
      --add-flags "-jar $out/opt/bindiff/bindiff.jar"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Find differences and similarities in disassembled code";
    homepage = "https://github.com/google/bindiff";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    maintainers = [ ];
  };
}
