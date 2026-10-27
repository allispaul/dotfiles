#
# ~/.bash_profile
#

eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -f $HOME/.bashrc ]] && . "$HOME/.bashrc"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
