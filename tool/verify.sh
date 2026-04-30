#!/usr/bin/env bash
# tool/verify.sh
#
# End-to-end verification an AI agent (or human) can run from this folder.
# Steps:
#   1. Ensure Flutter is on PATH (auto-installs if FLUTTER_HOME exists)
#   2. flutter pub get
#   3. flutter analyze   → catches the issues `flutter analyze` would catch
#   4. flutter test      → runs widget + unit tests in test/
#
# Exits non-zero on the first failure. Stdout / stderr is preserved so the
# caller (CI or a watching agent) can attribute failures.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Add Flutter to PATH if installed by tool/install_flutter.sh.
if ! command -v flutter >/dev/null 2>&1; then
  if [ -d "${FLUTTER_HOME:-$HOME/flutter}" ]; then
    export PATH="${FLUTTER_HOME:-$HOME/flutter}/bin:$PATH"
  fi
fi

if ! command -v flutter >/dev/null 2>&1; then
  cat >&2 <<EOF
flutter not on PATH. Run first:

  bash tool/install_flutter.sh
  export PATH="\$HOME/flutter/bin:\$PATH"

EOF
  exit 127
fi

echo "==> flutter --version"
flutter --version

echo
echo "==> flutter pub get"
flutter pub get

echo
echo "==> flutter analyze"
flutter analyze

echo
echo "==> flutter test"
flutter test --reporter expanded

echo
echo "All checks passed."
