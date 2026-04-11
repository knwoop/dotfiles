### paths ###
typeset -gU PATH path
typeset -gU FPATH fpath

path=(
    '/usr/local/bin'(N-/)
    '/usr/bin'(N-/)
    '/bin'(N-/)
    '/usr/local/sbin'(N-/)
    '/usr/sbin'(N-/)
    '/sbin'(N-/)
    '/opt/homebrew/bin'(N-/)
    '/opt/homebrew/opt/mysql/bin'(N-/)
    '$HOME/.venv/bin'(N-/)
)

path=(
    "$HOME/.local/bin"(N-/)
    "$CARGO_HOME/bin"(N-/)
    "$GOROOT/bin"(N-/)
    "$GOPATH/bin"(N-/)
    "$DENO_INSTALL/bin"(N-/)
    "$GEM_HOME/bin"(N-/)
    "$GHRED_DATA_HOME/bin"(N-/)
    "$XDG_CONFIG_HOME/scripts/bin"(N-/)
    "$MISE_DATA_DIR/shims"(N-/)
    "$path[@]"
)

fpath=(
    "$GHRED_DATA_HOME/completions"(N-/)
    "$XDG_DATA_HOME/zsh/completions"(N-/)
    "$fpath[@]"
)

### history ###
export HISTFILE="$XDG_STATE_HOME/zsh_history"
export HISTSIZE=12000
export SAVEHIST=10000

setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt GLOBDOTS
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_SAVE_NO_DUPS
setopt INTERACTIVE_COMMENTS
setopt NO_SHARE_HISTORY
setopt MAGIC_EQUAL_SUBST
setopt PRINT_EIGHT_BIT
setopt NO_FLOW_CONTROL

### source ###
source() {
    local input="$1"
    local cache="$input.zwc"
    if [[ ! -f "$cache" || "$input" -nt "$cache" ]]; then
        zcompile "$input"
    fi
    \builtin source "$@"
}

### hooks ###
zshaddhistory() {
    local line="${1%%$'\n'}"
    [[ ! "$line" =~ "^(cd|history|jj?|lazygit|la|ll|ls|rm|rmdir|trash)($| )" ]]
}

ghq-fzf() {
  local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}

# Prompt {{{
local grey='246'
local red='1'
local yellow='3'
local blue='4'
local magenta='5'
local cyan='6'
local white='7'

function prompt_anyenv() {
  local ruby_version python_version node_version

  if which rbenv > /dev/null 2>&1; then
    ruby_version="Ruby-$(rbenv version-name)"
  fi
  if which pyenv > /dev/null 2>&1; then
    if [[ -n "$VIRTUAL_ENV" ]]; then
      python_version="Python-venv"
    else
      python_version="Python-$(pyenv version-name)"
    fi
  fi
  if which nodenv > /dev/null 2>&1; then
    node_version="Node-$(nodenv version-name)"
  fi
  p10k segment -f white -t "[%{$MAGENTA%}${ruby_version}%{$DEFAULT%} %{$GREEN%}${python_version}%{$DEFAULT%} %{$BLUE%}${node_version}%{$DEFAULT%}]"
}

function prompt_venv() {
  local venv
  venv=""
  if [[ -n "$VIRTUAL_ENV" ]]; then
    venv="venv:$(basename $VIRTUAL_ENV)"
    p10k segment -f white -t "[%F{72}${venv}%f]"
  fi
}

function prompt_rebasing() {
  if [[ -d ".git/rebase-merge" ]] || [[ -d ".git/rebase-apply" ]]; then
    p10k segment -f red -e -t ' Rebasing '
  fi
}

function prompt_conflicting() {
  if [[ -f ".git/MERGE_HEAD" ]]; then
    p10k segment -f red -e -t ' Conflicting '
  fi
}

function prompt_show_buffer_stack() {
  p10k segment -f white -e -t '$COMMAND_BUFFER_STACK'
}

typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir
  vcs
  conflicting
  rebasing
  newline
  venv
  prompt_char
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  show_buffer_stack
)

function p10k-on-pre-prompt() { p10k display '1'=show }
function p10k-on-post-prompt() { p10k display '1'=hide }

typeset -g POWERLEVEL9K_BACKGROUND=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=
typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION=

typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true

typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS}_FOREGROUND=$white
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS}_FOREGROUND=$red
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VICMD_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIVIS_CONTENT_EXPANSION='$'
typeset -g POWERLEVEL9K_DIR_FOREGROUND=$blue
typeset -g POWERLEVEL9K_VCS_CONTENT_EXPANSION='$(gitprompt)'

ZSH_THEME_GIT_PROMPT_PREFIX=""
ZSH_THEME_GIT_PROMPT_SUFFIX=" "
ZSH_THEME_GIT_PROMPT_SEPARATOR="|"
ZSH_THEME_GIT_PROMPT_DETACHED="%{$fg_bold[cyan]%}:"
ZSH_THEME_GIT_PROMPT_BRANCH="%{$fg_bold[white]%} "
ZSH_THEME_GIT_PROMPT_UPSTREAM_PREFIX="%{$fg[magenta]%}->%{$fg[cyan]%}"
ZSH_THEME_GIT_PROMPT_UPSTREAM_SUFFIX=" "
ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg_bold[cyan]%}↓ "
ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg_bold[cyan]%}↑ "
ZSH_THEME_GIT_PROMPT_UNMERGED=" %{$fg[red]%}X:"
ZSH_THEME_GIT_PROMPT_STAGED=" %{$fg[green]%}M:"
ZSH_THEME_GIT_PROMPT_UNSTAGED=" %{$fg[red]%}M:"
ZSH_THEME_GIT_PROMPT_UNTRACKED=" %{$fg[red]%}?:"
ZSH_THEME_GIT_PROMPT_CLEAN=" %{$fg_bold[green]%}✔ "
ZSH_THEME_GIT_PROMPT_STASHED=" %{$fg[blue]%}Stash:"
ZSH_GIT_PROMPT_SHOW_UPSTREAM=full
ZSH_GIT_PROMPT_SHOW_STASH=1
ZSH_GIT_PROMPT_FORCE_BLANK=1
# }}}

### aliases ###
alias em='emacsclient -c -a "" .'

### key bindings ###
widget::history() {
    local selected="$(history -inr 1 | fzf --exit-0 --query "$LBUFFER" | cut -d' ' -f4- | sed 's/\\n/\n/g')"
    if [[ -n "$selected" ]]; then
        BUFFER="$selected"
        CURSOR=$#BUFFER
    fi
    zle -R -c # refresh screen
}

widget::ghq::source() {
    local session color icon green="\e[32m" blue="\e[34m" reset="\e[m" checked="󰄲" unchecked="󰄱"
    local sessions=($(tmux list-sessions -F "#S" 2>/dev/null))

    ghq list | sort | while read -r repo; do
        session="${repo//[:. ]/-}"
        color="$blue"
        icon="$unchecked"
        if (( ${+sessions[(r)$session]} )); then
            color="$green"
            icon="$checked"
        fi
        printf "$color$icon %s$reset\n" "$repo"
    done
}
widget::ghq::select() {
    local root="$(ghq root)"
    widget::ghq::source | fzf --exit-0 --preview="fzf-preview-git ${(q)root}/{+2}" --preview-window="right:60%" | cut -d' ' -f2-
}
widget::ghq::dir() {
    local selected="$(widget::ghq::select)"
    if [[ -z "$selected" ]]; then
        return
    fi

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    BUFFER="cd ${(q)repo_dir}"
    zle accept-line
    zle -R -c # refresh screen
}
widget::ghq::session() {
    local selected="$(widget::ghq::select)"
    if [[ -z "$selected" ]]; then
        return
    fi

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    local session_name="${selected//[:. ]/-}"

    if [[ -z "$TMUX" ]]; then
        BUFFER="tmux new-session -A -s ${(q)session_name} -c ${(q)repo_dir}"
        zle accept-line
    elif [[ "$(tmux display-message -p "#S")" != "$session_name" ]]; then
        tmux new-session -d -s "$session_name" -c "$repo_dir" 2>/dev/null
        tmux switch-client -t "$session_name"
    else
        BUFFER="cd ${(q)repo_dir}"
        zle accept-line
    fi
    zle -R -c # refresh screen
}

widget::muxac::source() {
    local green="\e[32m" yellow="\e[33m" red="\e[31m" reset="\e[m"
    local json
    json="$(muxac list --json 2>/dev/null)" || return
    echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
colors = {'running': '\033[32m', 'waiting': '\033[33m', 'stopped': '\033[31m'}
reset = '\033[0m'
for s in data.get('sessions', []):
    c = colors.get(s['status'], reset)
    print(f\"{c}{s['status']:<10} {s['name']:<40} {s['directory']}{reset}\")
"
}
muxac-new() {
    local root repo_dir session_prefix branch
    root="$(ghq root 2>/dev/null)"
    repo_dir="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "Not in a git repo"; return 1; }
    session_prefix="$(python3 -c "import os; print(os.path.relpath('$repo_dir', '$root').replace(':', '-').replace('.', '-').replace(' ', '-'))")"

    echo -n "Branch name: "
    read branch
    [[ -z "$branch" ]] && return

    local worktree_dir="$repo_dir/.worktrees/$branch"
    local session_name="$session_prefix/$branch"

    # ensure .worktrees/ in .gitignore
    local gitignore="$repo_dir/.gitignore"
    if ! grep -q '^\\.worktrees/?$' "$gitignore" 2>/dev/null; then
        echo '.worktrees/' >> "$gitignore"
    fi

    git worktree add -b "$branch" "$worktree_dir" || return
    muxac new --name "$session_name" --dir "$worktree_dir" claude
}
widget::muxac::new() {
    local selected="$(widget::ghq::select)"
    [[ -z "$selected" ]] && return

    local repo_dir="$(ghq list --exact --full-path "$selected")"
    [[ -z "$repo_dir" ]] && return

    BUFFER="cd ${(q)repo_dir} && muxac-new"
    zle accept-line
    zle -R -c
}
widget::muxac::select() {
    widget::muxac::source | fzf --exit-0 --ansi | awk '{ print $2, $3 }'
}
widget::muxac::attach() {
    local selected name dir
    selected="$(widget::muxac::select)"
    if [[ -z "$selected" ]]; then
        zle -M "muxac: no sessions"
        return
    fi

    name="$(echo "$selected" | awk '{ print $1 }')"
    dir="$(echo "$selected" | awk '{ print $2 }')"

    if [[ -z "$TMUX" ]]; then
        BUFFER="muxac attach --name ${(q)name} --dir ${(q)dir}"
        zle accept-line
    else
        muxac attach --name "$name" --dir "$dir"
    fi
    zle -R -c
}

zle -N widget::history
zle -N widget::ghq::dir
zle -N widget::ghq::session
zle -N widget::muxac::new
zle -N widget::muxac::attach
zle -N forward-kill-word
zle -N ghq-fzf

bindkey "^R"        widget::history                 # C-r
bindkey "^G"        widget::ghq::session            # C-g
bindkey "^[g"       widget::ghq::dir                # Alt-g
bindkey "^[n"       widget::muxac::new              # Alt-n (ghq -> muxac new)
bindkey "^[m"       widget::muxac::attach           # Alt-m (muxac attach)
bindkey "^A"        beginning-of-line               # C-a
bindkey "^E"        end-of-line                     # C-e
bindkey '^B'        backward-char
bindkey '^F'        forward-char
bindkey '^P'        up-line-or-history
bindkey '^N'        up-line-or-beginning-search
bindkey '^D'        delete-char
bindkey "^K"        kill-line                       # C-k
bindkey "^Q"        push-line-or-edit               # C-q
bindkey "^W"        vi-backward-kill-word           # C-w
bindkey "^]"        ghq-fzf                         # C-]
bindkey "^?"        backward-delete-char            # backspace
bindkey "^[[3~"     delete-char                     # delete

# sheldon
sheldon::load() {
    local profile="$1"
    local plugins_file="$SHELDON_CONFIG_DIR/plugins.toml"
    local cache_file="$XDG_CACHE_HOME/sheldon/$profile.zsh"
    if [[ ! -f "$cache_file" || "$plugins_file" -nt "$cache_file" ]]; then
        mkdir -p "$XDG_CACHE_HOME/sheldon"
        sheldon --profile="$profile" source >"$cache_file"
        zcompile "$cache_file"
    fi
    \builtin source "$cache_file"
}

sheldon::update() {
    sheldon --profile="eager" lock --update
    sheldon --profile="lazy" lock --update
}

sheldon::load eager

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/knwoop/Downloads/google-cloud-sdk 2/path.zsh.inc' ]; then . '/Users/knwoop/Downloads/google-cloud-sdk 2/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/knwoop/Downloads/google-cloud-sdk 2/completion.zsh.inc' ]; then . '/Users/knwoop/Downloads/google-cloud-sdk 2/completion.zsh.inc'; fi

