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

# Set options for gcc
alias gpc='gcc -Wall -Wextra -Wpedantic -std=c23 -g -lm'
alias gpp='g++ -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -std=c++20 -g'

# Copy to clipboard
alias clip='xclip -selection clipboard'

# Other utilities
alias killstop='kill -9 $(jobs -p -s)'

eval "$(uv generate-shell-completion bash)"

if command -v zoxide &>/dev/null; then
  eval "$(zoxide init bash)"
fi

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# Run machine-specific setup
if [[ -e "$HOME/.bashrc_local" ]]; then
  source $HOME/.bashrc_local
fi
