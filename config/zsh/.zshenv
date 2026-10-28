### locale ###
export LANG="en_US.UTF-8"

unsetopt GLOBAL_RCS

### resource limits ###
# macOS hands every process a soft RLIMIT_NOFILE of 256. The tmux server keeps
# one pty master fd open per pane, so a few hundred panes walk it up to the
# ceiling — and tmux 3.6a's display-popup does not check job_run() for NULL, so
# the first popup that cannot get an fd segfaults the server and takes every
# session with it. The hard limit is unlimited, so raising the soft one needs
# no privileges. A running server keeps the limit it was forked with: this only
# helps servers started from a shell that read this file.
#
# Raise only. Some hosts (Claude Code) hand their shells a far higher limit on
# purpose, and a bare `ulimit -n 4096` would quietly cut it back down.
() {
    local cur=$(ulimit -Sn)
    [[ $cur == unlimited ]] && return
    (( cur < 4096 )) && ulimit -n 4096
}

### XDG ###
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

### zsh ###
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

### Rust ###
export RUST_BACKTRACE=1
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"

### Go ###
export GOPATH="$XDG_DATA_HOME/go"
export GOMODCACHE="$XDG_CACHE_HOME/go_mod"
export GO111MODULE="on"
export GOFLAGS="-tags=e2e,wireinject"
export GOPRIVATE="github.com/x-asia/*,github.com/showcase-gig-platform/*"
export GOTOOLCHAIN="auto"

### Deno ###
export DENO_INSTALL="$XDG_DATA_HOME/deno"
export DENO_INSTALL_ROOT="$DENO_INSTALL"

### Rubygems ###
export GEM_HOME="$XDG_DATA_HOME/gem"
export GEM_SPEC_CACHE="$XDG_CACHE_HOME/gem"

export BUNDLE_USER_HOME="$XDG_CONFIG_HOME/bundle"
export BUNDLE_USER_CACHE="$XDG_CACHE_HOME/bundle"
export BUNDLE_USER_PLUGIN="$XDG_DATA_HOME/bundle/plugin"

### sheldon ###
export SHELDON_CONFIG_DIR="$ZDOTDIR"

### gh-red ###
export GHRED_CONFIG_HOME="$XDG_CONFIG_HOME/gh-red"
export GHRED_DATA_HOME="$XDG_DATA_HOME/gh-red"

### mise ###
export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"
export PATH="$HOME/.local/share/mise/shims:$PATH"

### aqua ###
export PATH="${AQUA_ROOT_DIR:-$XDG_DATA_HOME/aquaproj-aqua}/bin:$PATH"

# uv
export PATH="/Users/knwoop/.local/share/../bin:$PATH"

# Homebrew for non-interactive shells too (`ssh host cmd`, mosh starting
# mosh-server over ssh); .zshrc rebuilds PATH for interactive ones.
path+=(/opt/homebrew/bin(N-/))
