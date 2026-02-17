{
  stdenv,
  fetchzip,
  fetchurl,
  lib,
  makeWrapper,
  makeBinaryWrapper,
  autoPatchelfHook,
  openjdk21,
  pam,
  makeDesktopItem,
  icoutils,
  symlinkJoin,
}:

let
  pkg_path = "$out/lib/ghidra";
  jdk = openjdk21;

  desktopItem = makeDesktopItem {
    name = "ghidra";
    exec = "ghidra";
    icon = "ghidra";
    desktopName = "Ghidra";
    genericName = "Ghidra Software Reverse Engineering Suite";
    categories = [ "Development" ];
    terminal = false;
    startupWMClass = "ghidra-Ghidra";
  };

  # Upstream ApplicationUtilities.java for patching NIX_GHIDRAHOME support.
  # This is the same patch nixpkgs applies at source level to the source-built
  # Ghidra package (0002-Load-nix-extensions.patch).
  applicationUtilitiesSrc = fetchurl {
    url = "https://raw.githubusercontent.com/NationalSecurityAgency/ghidra/Ghidra_12.0.3_build/Ghidra/Framework/Utility/src/main/java/utility/application/ApplicationUtilities.java";
    hash = "sha256-V1re9uZOTEI3RX9r+MP6B9wEjjkYZUNhUK00ijOIhXE=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ghidra";
  version = "12.0.3";

  src = fetchzip {
    url =
      let
        versiondate = "20260210";
      in
      "https://github.com/NationalSecurityAgency/ghidra/releases/download/Ghidra_${finalAttrs.version}_build/ghidra_${finalAttrs.version}_PUBLIC_${versiondate}.zip";
    hash = "sha256-BeGqBCs7AWHl4Zt710f8g/39nXJH6+DMEyJ4y+9iBSw=";
  };

  nativeBuildInputs =
    [
      makeWrapper
      icoutils
      jdk
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    pam
  ];

  dontStrip = true;

  installPhase = ''
    mkdir -p "${pkg_path}" "$out/share/applications"
    cp -a * "${pkg_path}"
    ln -s ${desktopItem}/share/applications/* $out/share/applications

    icotool -x "${pkg_path}/support/ghidra.ico"
    rm ghidra_4_40x40x32.png
    for f in ghidra_*.png; do
      res=$(basename "$f" ".png" | cut -d"_" -f3 | cut -d"x" -f1-2)
      mkdir -pv "$out/share/icons/hicolor/$res/apps"
      mv "$f" "$out/share/icons/hicolor/$res/apps/ghidra.png"
    done;
  '';

  postFixup = ''
    # ── Patch Utility.jar with NIX_GHIDRAHOME support ──
    # This mirrors nixpkgs' 0002-Load-nix-extensions.patch but applied to the
    # pre-built binary release by recompiling a single class.
    local utilityJar="${pkg_path}/Ghidra/Framework/Utility/lib/Utility.jar"
    local patchDir=$(mktemp -d)

    # Apply the NIX_GHIDRAHOME patch to the upstream source
    mkdir -p "$patchDir/utility/application"
    sed '/List<ResourceFile> applicationRootDirs = new ArrayList<>();/a\
\t\tString nixGhidraHome = System.getenv("NIX_GHIDRAHOME");\
\t\tif (nixGhidraHome != null) {\
\t\t\tapplicationRootDirs.add(new ResourceFile(nixGhidraHome));\
\t\t}' \
      ${applicationUtilitiesSrc} > "$patchDir/utility/application/ApplicationUtilities.java"

    # Compile the patched class against the existing Ghidra JARs
    local classpath="${pkg_path}/Ghidra/Framework/Utility/lib/Utility.jar"
    classpath="$classpath:${pkg_path}/Ghidra/Framework/Generic/lib/Generic.jar"
    javac -cp "$classpath" \
          -source 21 -target 21 \
          -d "$patchDir" \
          "$patchDir/utility/application/ApplicationUtilities.java"

    # Inject the patched class into the JAR
    rm "$patchDir/utility/application/ApplicationUtilities.java"
    jar -uf "$utilityJar" -C "$patchDir" utility/application/ApplicationUtilities.class
    rm -rf "$patchDir"

    # ── Create bin wrappers ──
    mkdir -p "$out/bin"
    ln -s "${pkg_path}/ghidraRun" "$out/bin/ghidra"
    ln -s "${pkg_path}/support/analyzeHeadless" "$out/bin/ghidra-analyzeHeadless"

    wrapProgram "${pkg_path}/support/launch.sh" \
      --set-default NIX_GHIDRAHOME "${pkg_path}/Ghidra" \
      --prefix PATH : ${lib.makeBinPath [ jdk ]}
  '';

  passthru.distroPrefix = "ghidra_${finalAttrs.version}_PUBLIC_20260210";

  passthru.withExtensions =
    extensions:
    let
      ghidra = finalAttrs.finalPackage;
    in
    symlinkJoin {
      name = "ghidra-with-extensions-${finalAttrs.version}";
      paths = extensions;
      nativeBuildInputs = [ makeBinaryWrapper ];
      postBuild = ''
        # Prevent attempted creation of plugin lock files in the nix store
        touch $out/lib/ghidra/Ghidra/.dbDirLock

        makeBinaryWrapper '${ghidra}/bin/ghidra' "$out/bin/ghidra" \
          --set NIX_GHIDRAHOME "$out/lib/ghidra/Ghidra"
        makeBinaryWrapper '${ghidra}/bin/ghidra-analyzeHeadless' "$out/bin/ghidra-analyzeHeadless" \
          --set NIX_GHIDRAHOME "$out/lib/ghidra/Ghidra"
        ln -s ${ghidra}/share $out/share
      '';
      inherit (ghidra) meta;
    };

  meta = {
    description = "Software reverse engineering (SRE) suite of tools developed by NSA's Research Directorate";
    mainProgram = "ghidra";
    homepage = "https://github.com/NationalSecurityAgency/ghidra";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryBytecode ];
    license = lib.licenses.asl20;
  };
})
