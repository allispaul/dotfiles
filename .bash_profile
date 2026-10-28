# The following lines were added by Docker Desktop to add commands to your PATH.
export PATH="$PATH:/Users/paul.vankoughnett/.docker/bin"
# End of Docker Desktop section.

#
# ~/.bash_profile
#

eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -f $HOME/.bashrc ]] && . "$HOME/.bashrc"
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
