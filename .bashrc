#!/bin/bash

#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Set vim keybindings
set -o vi

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='\u@\h: \W\$ '

export MANPATH="/usr/local/texlive/2023/texmf-dist/doc/man:$MANPATH"
export INFOPATH="/usr/local/texlive/2023/texmf-dist/doc/info:$INFOPATH"
export PATH="$PATH:$HOME/.local/bin"
export BROWSER="firefox"
export VCPKG_ROOT=$HOME/.local/share/vcpkg

# Command aliases
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
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash --cmd cd)"
fi

if command -v fzf &>/dev/null; then
  eval "$(fzf --bash)"
fi

if [[ -f $HOME/.fzf.bash ]]; then
  source "$HOME/.fzf.bash"
fi

if [[ -f $HOME/.cargo.env ]]; then
  source "$HOME/.cargo.env"
fi

eval "$(uv generate-shell-completion bash)"

# Silence mac insistence on zsh
export BASH_SILENCE_DEPRECATION_WARNING=1

# Run machine-specific setup
if [[ -e "$HOME/.bashrc_local" ]]; then
  source "$HOME/.bashrc_local"
fi
