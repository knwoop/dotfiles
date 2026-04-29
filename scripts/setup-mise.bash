#!/usr/bin/env bash
set -x
# shellcheck source=./scripts/common.bash
source "$(dirname "$0")/common.bash"

[ -n "$SKIP_MISE" ] && exit

if ! type mise >/dev/null 2>&1; then
    echo "mise is not installed; skipping."
    exit
fi

echo "Installing mise tools..."
mise install

GOTIP_BIN="$HOME/.local/share/mise/shims/gotip"
if [ -x "$GOTIP_BIN" ] && [ ! -x "$HOME/sdk/gotip/bin/go" ]; then
    echo "Downloading and building Go master via gotip (takes several minutes)..."
    "$GOTIP_BIN" download
fi
