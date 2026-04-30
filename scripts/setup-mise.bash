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
