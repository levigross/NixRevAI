#!/usr/bin/env bash
set -euo pipefail

failures=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

assert_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    fail "missing command in devShell PATH: ${cmd}"
  fi
}

assert_env_nonempty() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" ]]; then
    fail "required environment variable is empty: ${key}"
  fi
}

assert_dir_from_env() {
  local key="$1"
  local value="${!key:-}"
  if [[ -z "$value" || ! -d "$value" ]]; then
    fail "expected directory path in ${key}, got: ${value:-<empty>}"
  fi
}

# Validate core tools expected from the shell composition.
assert_cmd ghidra
assert_cmd rizin
assert_cmd uv
assert_cmd git
assert_cmd jq

# Validate shell variables required by reverse-engineering tooling.
assert_env_nonempty GHIDRA_INSTALL_DIR
assert_env_nonempty NIX_GHIDRAHOME
assert_env_nonempty SLEIGHHOME
assert_env_nonempty JAVA_HOME

assert_dir_from_env GHIDRA_INSTALL_DIR
assert_dir_from_env NIX_GHIDRAHOME
assert_dir_from_env SLEIGHHOME
assert_dir_from_env JAVA_HOME

if [[ "$failures" -ne 0 ]]; then
  printf 'Unit tests failed (%s failure(s)).\n' "$failures" >&2
  exit 1
fi

printf 'All unit tests passed.\n'
