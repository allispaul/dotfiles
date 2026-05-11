#!/usr/bin/env bash

# bootstrap.sh — create home directory symlinks for dotfiles
# Run from the root of your dotfiles repo.
# Usage: ./bootstrap.sh

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
BACKUP_DIR="$DOTFILES_DIR/backup/$(date +%Y%m%d_%H%M%S)"

DOTFILES=(
    .bash_logout
    .bash_profile
    .bashrc
    .gdbinit
    .gitconfig
    .spacemacs
    .vimrc
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
        mkdir -p "$BACKUP_DIR"
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
echo "Done."
