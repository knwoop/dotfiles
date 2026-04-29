#!/usr/bin/env bash
set -x
# shellcheck source=./scripts/common.bash
source "$(dirname "$0")/common.bash"

[ -n "$SKIP_GO" ] && exit

if ! type go >/dev/null 2>&1; then
    echo "go is not installed; skipping."
    exit
fi

GOPATH_BIN="${GOPATH:-$XDG_DATA_HOME/go}/bin"
mkdir -p "$GOPATH_BIN"

# ooi: stays in $GOPATH/bin so the launchd plist (~/Library/LaunchAgents/com.ooi.plist)
# can use a stable, version-independent path.
go install github.com/knwoop/ooi@latest

# testfuncs: module path is github.com/knwoop/testfuns, but the binary needs
# to be named testfuncs (referenced from navi snippets).
go install github.com/knwoop/testfuns@latest
if [ -x "$GOPATH_BIN/testfuns" ]; then
    mv -f "$GOPATH_BIN/testfuns" "$GOPATH_BIN/testfuncs"
fi
