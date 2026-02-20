#!/usr/bin/env bash
set -euo pipefail

failures=0
pass_count=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

pass() {
  pass_count=$((pass_count + 1))
}

assert_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "missing command in devShell PATH: ${cmd}"
  else
    pass
  fi
}

assert_env_nonempty() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" ]]; then
    fail "required environment variable is empty: ${key}"
  else
    pass
  fi
}

assert_env_equals() {
  local key="$1"
  local expected="$2"
  local value="${!key:-}"
  if [[ "$value" != "$expected" ]]; then
    fail "expected ${key}='${expected}', got '${value:-<empty>}'"
  else
    pass
  fi
}

assert_env_contains() {
  local key="$1"
  local substring="$2"
  local value="${!key:-}"
  if [[ "$value" != *"$substring"* ]]; then
    fail "expected ${key} to contain '${substring}', got '${value:-<empty>}'"
  else
    pass
  fi
}

assert_dir_from_env() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" || ! -d "$value" ]]; then
    fail "expected directory path in ${key}, got: ${value:-<empty>}"
  else
    pass
  fi
}

assert_file_exists() {
  local path="$1"
  local desc="${2:-$path}"
  if [[ ! -e "$path" ]]; then
    fail "expected file to exist: ${desc} (${path})"
  else
    pass
  fi
}

assert_symlink() {
  local path="$1"
  local desc="${2:-$path}"
  if [[ ! -L "$path" ]]; then
    fail "expected symlink: ${desc} (${path})"
  else
    pass
  fi
}

# ---------------------------------------------------------------------------
# Section: Core reversing tools (reversing toolset)
# ---------------------------------------------------------------------------
assert_cmd ghidra
assert_cmd rizin
assert_cmd r2
assert_cmd jadx
assert_cmd retdec-decompiler

# bindiff and wine are x86_64-only
if [[ "$(uname -m)" == "x86_64" ]]; then
  assert_cmd bindiff
  assert_cmd binexport2dump
  assert_cmd wine
fi

# ---------------------------------------------------------------------------
# Section: Debugging toolset
# ---------------------------------------------------------------------------
assert_cmd gdb
assert_cmd strace

# ---------------------------------------------------------------------------
# Section: Binary analysis toolset
# ---------------------------------------------------------------------------
assert_cmd afl-fuzz

# ---------------------------------------------------------------------------
# Section: Forensics toolset
# ---------------------------------------------------------------------------
assert_cmd binwalk
assert_cmd foremost
assert_cmd sleuthkit

# ---------------------------------------------------------------------------
# Section: Crypto toolset
# ---------------------------------------------------------------------------
assert_cmd hashcat
assert_cmd openssl

# ---------------------------------------------------------------------------
# Section: Dev tools toolset
# ---------------------------------------------------------------------------
assert_cmd bat
assert_cmd cmake
assert_cmd gcc
assert_cmd git
assert_cmd go
assert_cmd jq
assert_cmd just
assert_cmd rg
assert_cmd uv

# ---------------------------------------------------------------------------
# Section: Python toolset
# ---------------------------------------------------------------------------
assert_cmd python3

# ---------------------------------------------------------------------------
# Section: Hardware toolset
# ---------------------------------------------------------------------------
assert_cmd qemu-img
assert_cmd openocd
assert_cmd lspci
assert_cmd lsusb

# ---------------------------------------------------------------------------
# Section: Environment variables — reverse-engineering tooling
# ---------------------------------------------------------------------------
assert_env_nonempty GHIDRA_INSTALL_DIR
assert_env_nonempty NIX_GHIDRAHOME
assert_env_nonempty SLEIGHHOME
assert_env_nonempty JAVA_HOME

assert_dir_from_env GHIDRA_INSTALL_DIR
assert_dir_from_env NIX_GHIDRAHOME
assert_dir_from_env SLEIGHHOME
assert_dir_from_env JAVA_HOME

# ---------------------------------------------------------------------------
# Section: JAVA_HOME points to JDK 21
# ---------------------------------------------------------------------------
if [[ -x "${JAVA_HOME:-}/bin/java" ]]; then
  java_version_output="$("${JAVA_HOME}/bin/java" -version 2>&1)"
  if [[ "$java_version_output" != *"21."* && "$java_version_output" != *'"21'* ]]; then
    fail "JAVA_HOME java -version does not indicate JDK 21: ${java_version_output}"
  else
    pass
  fi
else
  fail "JAVA_HOME/bin/java is not executable"
fi

# ---------------------------------------------------------------------------
# Section: Build/shell environment variables
# ---------------------------------------------------------------------------
assert_env_equals CGO_ENABLED "0"
assert_env_nonempty LD_LIBRARY_PATH

# ---------------------------------------------------------------------------
# Section: MCP configuration symlink
# ---------------------------------------------------------------------------
assert_symlink ".mcp.json" "MCP config symlink (.mcp.json)"

# Verify the symlink target is valid JSON
if [[ -L ".mcp.json" && -r ".mcp.json" ]]; then
  if jq empty .mcp.json 2>/dev/null; then
    pass
  else
    fail ".mcp.json symlink target is not valid JSON"
  fi
else
  fail ".mcp.json is not a readable symlink"
fi

# ---------------------------------------------------------------------------
# Section: Ghidra directory structure
# ---------------------------------------------------------------------------
assert_file_exists "${GHIDRA_INSTALL_DIR:-/nonexistent}/Ghidra" \
  "GHIDRA_INSTALL_DIR contains Ghidra subdirectory"

assert_file_exists "${NIX_GHIDRAHOME:-/nonexistent}" \
  "NIX_GHIDRAHOME directory exists"

# ---------------------------------------------------------------------------
# Results
# ---------------------------------------------------------------------------
if [[ "$failures" -ne 0 ]]; then
  printf 'Unit tests failed: %s passed, %s failed.\n' "$pass_count" "$failures" >&2
  exit 1
fi

printf 'All unit tests passed (%s assertions).\n' "$pass_count"
