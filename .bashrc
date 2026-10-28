#!/usr/bin/env bash

# PATH setup (before the interactive check so non-interactive shells get it too)
case "$(uname -s)" in
Darwin)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    [[ -d "$HOMEBREW_PREFIX/opt/llvm/bin" ]] && export PATH="$HOMEBREW_PREFIX/opt/llvm/bin:$PATH"
  fi
  export PATH="$PATH:$HOME/.local/bin"
  ;;
Linux)
  # setup.sh installs tools here; let them take precedence over system packages
  export PATH="$HOME/.local/bin:$PATH"
  ;;
esac

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set vim keybindings
set -o vi

export MANPATH="/usr/local/texlive/2023/texmf-dist/doc/man:$MANPATH"
export INFOPATH="/usr/local/texlive/2023/texmf-dist/doc/info:$INFOPATH"
export BROWSER="firefox"
export VCPKG_ROOT=$HOME/.local/share/vcpkg

# Command aliases

alias ls='ls --color=auto'
alias grep='grep --color=auto'

# gcc
alias gpc='gcc -Wall -Wextra -Wpedantic -std=c23 -g -lm'
alias gpp='g++ -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -std=c++20 -g'

# git
alias gs='git status'
alias ga='git add -u && git status'

# handle typos
alias sl='ls'

# Copy to clipboard
if command -v xclip &>/dev/null; then
  alias clip='xclip -selection clipboard'
fi

alias killstop='kill -9 $(jobs -p -s)'

# print PATH separated into newlines
alias path='echo -e ${PATH//:/\\n}'

if command -v eza &>/dev/null; then
  alias l='eza -la --git --icons --group-directories-first'
fi

if command -v bat &>/dev/null; then
  alias cat='bat -pp'
fi

if command -v batman &>/dev/null; then
  alias man='batman'
fi

if command -v fd &>/dev/null; then
  alias v='fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs -0 nvim'
fi

if command -v nvim &>/dev/null; then
  alias vim='nvim'
fi

# Bash tool integration setup

if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
fi

# shellcheck disable=SC1091
[[ -f "$HOME/.fzf.bash" ]] && source "$HOME/.fzf.bash"

# shellcheck disable=SC1091
[[ -f "$HOME/.cargo.env" ]] && source "$HOME/.cargo.env"

eval "$(uv generate-shell-completion bash)"

# Silence mac insistence on zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

# Set prompt command
# shellcheck disable=SC1091
[[ -f "$HOME/.bash_prompt" ]] && source "$HOME/.bash_prompt"

# Finally, run machine-specific setup
# shellcheck disable=SC1091
[[ -f "$HOME/.bashrc_local" ]] && source "$HOME/.bashrc_local"

# zoxide init wants to go last
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash --cmd cd)"
fi

# proto
if [ -d "$HOME/.proto" ]; then
  export PROTO_HOME="$HOME/.proto"
  export PATH="$PROTO_HOME/shims:$PROTO_HOME/bin:$PATH"
fi
