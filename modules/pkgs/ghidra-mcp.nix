{
  lib,
  stdenv,
  ghidra,
  jdk21,
  zip,
  src,
}: let
  ghidraHome = "${ghidra}/lib/ghidra";

  ghidraVersion = ghidra.version;

  # Build the classpath from all JARs under Ghidra's Framework/ and Features/
  # directories. This is more robust than listing individual JARs: upstream
  # ghidra-mcp can gain new imports (e.g. Gson, Help) without derivation edits.
  ghidraLibGlob = "${ghidraHome}/Ghidra/{Framework,Features}/*/lib/*.jar";
in
  stdenv.mkDerivation {
    pname = "ghidra-mcp";
    # The Nix version tracks the Ghidra compatibility version since that's
    # what extension.properties `version=` expands to.
    version = ghidraVersion;

    inherit src;

    nativeBuildInputs = [jdk21 zip];

    buildPhase = ''
      runHook preBuild

      # Compile Java sources
      mkdir -p build/classes
      find src/main/java -name '*.java' > sources.txt
      classpath="$(echo ${ghidraLibGlob} | tr ' ' ':')"
      javac -cp "$classpath" \
            -source 21 -target 21 \
            -d build/classes \
            @sources.txt

      # Copy resources (excluding those needing substitution)
      cp -r src/main/resources/META-INF build/classes/

      # Extract the plugin version from pom.xml so we don't hardcode it.
      projectVersion=$(sed -n '/<groupId>/,/<\/version>/{s|.*<version>\(.*\)</version>|\1|p}' pom.xml | head -1)

      # Substitute Maven-style placeholders that the upstream build would
      # normally resolve via the pom.xml properties at compile time.
      sed -e "s/\''${project.version}/$projectVersion/g" \
          -e "s/\''${ghidra.version}/${ghidraVersion}/g" \
          src/main/resources/extension.properties > build/classes/extension.properties

      sed -e "s/\''${project.version}/$projectVersion/g" \
          -e "s/\''${ghidra.version}/${ghidraVersion}/g" \
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
