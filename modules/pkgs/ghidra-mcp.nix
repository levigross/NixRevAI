{
  lib,
  stdenv,
  ghidra,
  jdk21,
  zip,
  fetchFromGitHub,
}: let
  ghidraHome = "${ghidra}/lib/ghidra";

  # JARs required for compilation (from pom.xml system-scope deps)
  ghidraJars = [
    "Framework/Generic/lib/Generic.jar"
    "Framework/SoftwareModeling/lib/SoftwareModeling.jar"
    "Framework/Project/lib/Project.jar"
    "Framework/Docking/lib/Docking.jar"
    "Framework/Utility/lib/Utility.jar"
    "Framework/Gui/lib/Gui.jar"
    "Framework/FileSystem/lib/FileSystem.jar"
    "Features/Decompiler/lib/Decompiler.jar"
    "Features/Base/lib/Base.jar"
  ];

  classpath = lib.concatMapStringsSep ":" (j: "${ghidraHome}/Ghidra/${j}") ghidraJars;
in
  stdenv.mkDerivation {
    pname = "ghidra-mcp";
    version = "2.0.0";

    src = fetchFromGitHub {
      owner = "bethington";
      repo = "ghidra-mcp";
      rev = "680b5aec97073fd0bb18947d39b19fdd4f1daf41";
      hash = "sha256-tKJZ0uxbndfZWnNmzfHuQaG7DQGmYjBmhWeDDPM3s5c=";
    };

    nativeBuildInputs = [jdk21 zip];

    buildPhase = ''
      runHook preBuild

      # Compile Java sources
      mkdir -p build/classes
      find src/main/java -name '*.java' > sources.txt
      javac -cp "${classpath}" \
            -source 21 -target 21 \
            -d build/classes \
            @sources.txt

      # Copy resources (excluding those needing substitution)
      cp -r src/main/resources/META-INF build/classes/

      # Substitute only Maven-style placeholder variables; leave the upstream
      # Ghidra compatibility version (12.0.2) untouched — Ghidra matches on
      # major.minor so 12.0.x extensions load on any 12.0 release.
      sed -e 's/\''${project.version}/2.0.0/g' \
          src/main/resources/extension.properties > build/classes/extension.properties

      sed -e 's/\''${project.version}/2.0.0/g' \
          -e 's/\''${build.timestamp}/nixbuild/g' \
          -e 's/\''${build.number}/nixbuild/g' \
          src/main/resources/version.properties > build/classes/version.properties

      cp src/main/resources/Module.manifest build/classes/

      # Create JAR
      jar cfm build/GhidraMCP.jar build/classes/META-INF/MANIFEST.MF \
          -C build/classes .

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      local extDir="$out/lib/ghidra/Ghidra/Extensions/GhidraMCP"
      mkdir -p "$extDir/lib"
      cp build/GhidraMCP.jar "$extDir/lib/"
      cp build/classes/extension.properties "$extDir/"
      cp build/classes/Module.manifest "$extDir/"

      # Keep the upstream bridge script available for MCP client wiring.
      mkdir -p "$out/libexec/ghidra-mcp"
      cp bridge_mcp_ghidra.py "$out/libexec/ghidra-mcp/"

      runHook postInstall
    '';

    meta = {
      description = "Production-grade Ghidra MCP Server for AI-powered reverse engineering";
      homepage = "https://github.com/bethington/ghidra-mcp";
      license = lib.licenses.asl20;
    };
  }
