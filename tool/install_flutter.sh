#!/usr/bin/env bash
# tool/install_flutter.sh
#
# One-time Flutter SDK installer for Linux sandboxes (e.g. CI agents that
# only have git + curl). Idempotent. Adds Flutter to the current shell's PATH.
#
# Usage:
#   source tool/install_flutter.sh        # to also export PATH in caller
#   ./tool/install_flutter.sh             # just install
#
# Env vars:
#   FLUTTER_HOME    Where to install (default: $HOME/flutter)
#   FLUTTER_CHANNEL stable | beta | master  (default: stable)

set -euo pipefail

FLUTTER_HOME="${FLUTTER_HOME:-$HOME/flutter}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

if command -v flutter >/dev/null 2>&1; then
  echo "Flutter already on PATH at: $(command -v flutter)"
  flutter --version || true
  exit 0
fi

if [ ! -d "$FLUTTER_HOME" ]; then
  echo "==> Cloning Flutter ($FLUTTER_CHANNEL) into $FLUTTER_HOME"
  git clone --depth 1 -b "$FLUTTER_CHANNEL" \
    https://github.com/flutter/flutter.git "$FLUTTER_HOME"
else
  echo "==> Flutter dir exists at $FLUTTER_HOME — skipping clone"
fi

export PATH="$FLUTTER_HOME/bin:$PATH"

echo "==> Disabling analytics"
flutter config --no-analytics --no-cli-animations >/dev/null 2>&1 || true

echo "==> flutter --version"
flutter --version

cat <<EOF

Flutter installed at: $FLUTTER_HOME
Add to your shell rc to persist:
  export PATH="$FLUTTER_HOME/bin:\$PATH"
EOF
