#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S)"

DOTFILES=(
  .bash_logout
  .bash_profile
  .bash_prompt
  .bashrc
  .clang-format
  .gdbinit
  .gitconfig
  .spacemacs
  .tmux.conf
  .vimrc
  .config/nvim
)

echo "Dotfiles dir: $DOTFILES_DIR"
echo "Target dir:   $HOME_DIR"
echo ""

for file in "${DOTFILES[@]}"; do
  src="$DOTFILES_DIR/$file"
  dest="$HOME_DIR/$file"

  # Make sure the source file actually exists in the repo
  if [[ ! -e "$src" ]]; then
    echo "WARNING: $src not found in dotfiles repo, skipping."
    continue
  fi

  # If something already exists at the destination, back it up
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$file")"
    echo "Backing up existing $dest -> $BACKUP_DIR/$file"
    mv "$dest" "$BACKUP_DIR/$file"
  fi

  # Remove an existing symlink (possibly stale) before creating a new one
  if [[ -L "$dest" ]]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
done

echo ""

# Homebrew's install location depends on the OS (matches .bashrc)
OS="$(uname -s)"
case "$OS" in
Darwin) BREW_BIN="/opt/homebrew/bin/brew" ;;
Linux) BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew" ;;
*)
  echo "ERROR: unsupported OS $OS"
  exit 1
  ;;
esac

# Install Homebrew if it isn't already installed
if [[ ! -x "$BREW_BIN" ]]; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Put brew on PATH for the rest of this script
eval "$("$BREW_BIN" shellenv)"

BREW_FORMULAE=(
  bash
  bat
  bat-extras
  eza
  fd
  fzf
  git-lfs
  llvm
  neovim
  ripgrep
  tmux
  uv
  zoxide
)

BREW_CASKS=(
  claude-code
)

echo "Installing Homebrew packages..."
"$BREW_BIN" install "${BREW_FORMULAE[@]}"

# Casks are macOS-only; on Linux, use Claude Code's own installer instead
if [[ "$OS" == "Darwin" ]]; then
  "$BREW_BIN" install --cask "${BREW_CASKS[@]}"
elif [[ ! -x "$HOME/.local/bin/claude" ]]; then
  echo "Installing Claude Code..."
  curl -fsSL https://claude.ai/install.sh | bash
fi

# Install proto if it isn't already installed (.bashrc handles PATH setup)
if [[ ! -x "$HOME/.proto/bin/proto" ]]; then
  echo "Installing proto..."
  bash <(curl -fsSL https://moonrepo.dev/install/proto.sh) --yes --no-modify-profile
fi

echo ""
echo "Done."
