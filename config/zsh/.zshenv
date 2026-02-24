### locale ###
export LANG="en_US.UTF-8"

unsetopt GLOBAL_RCS

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
export GOROOT="$HOME/sdk/go1.26.0"
export GOMODCACHE="$XDG_CACHE_HOME/go_mod"
export GO111MODULE="on"
export GOFLAGS="-tags=e2e,wireinject"
export GOPRIVATE="github.com/x-asia/*,github.com/showcase-gig-platform/*"
export GOTOOLCHAIN="auto"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

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

### spaceship ###
export SPACESHIP_CONFIG="$ZDOTDIR/spaceshiprc.zsh"

# export GITHUB_TOKEN=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

### mise ###
export MISE_CONFIG_DIR="$XDG_CONFIG_HOME/mise"
export MISE_DATA_DIR="$XDG_DATA_HOME/mise"
export MISE_CACHE_DIR="$XDG_CACHE_HOME/mise"

# uv
export PATH="/Users/knwoop/.local/share/../bin:$PATH"
