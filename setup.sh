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

  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest"
  echo "Linked $dest -> $src"
done

echo ""

install_macos() {
  local brew_bin="/opt/homebrew/bin/brew"

  # Install Homebrew if it isn't already installed
  if [[ ! -x "$brew_bin" ]]; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Put brew on PATH for the rest of this script
  eval "$("$brew_bin" shellenv)"

  local formulae=(
    bash
    bat
    bat-extras
    eza
    fd
    fzf
    git-lfs
    llvm
    neovim
    python-lsp-server
    ripgrep
    ruff
    shellcheck
    tmux
    uv
    zoxide
  )

  local casks=(
    claude-code
  )

  echo "Installing Homebrew packages..."
  "$brew_bin" install "${formulae[@]}"
  "$brew_bin" install --cask "${casks[@]}"
}

# Print the tag of the latest GitHub release of a repo, e.g. "v0.74.5"
latest_github_tag() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p'
}

# On Linux, CLI tools come from apt, Python tools from `uv tool install`, and
# anything apt's versions are too old for goes into ~/.local. Nothing here
# refers to /home, so this works wherever $HOME lives.
install_linux() {
  local local_bin="$HOME/.local/bin"
  local local_opt="$HOME/.local/opt"
  mkdir -p "$local_bin" "$local_opt"
  export PATH="$local_bin:$PATH"

  # Release assets name the architecture in different ways
  local arch goarch
  case "$(uname -m)" in
  x86_64)
    arch="x86_64"
    goarch="amd64"
    ;;
  aarch64 | arm64)
    arch="aarch64"
    goarch="arm64"
    ;;
  *)
    echo "ERROR: unsupported architecture $(uname -m)"
    exit 1
    ;;
  esac

  # Use sudo unless we're already root (as on many containers)
  local sudo=""
  if [[ $EUID -ne 0 ]]; then
    sudo="sudo"
  fi

  local apt_packages=(
    bash
    bat
    build-essential
    ca-certificates
    curl
    fd-find
    git
    git-lfs
    ripgrep
    shellcheck
    tmux
    unzip
  )

  echo "Installing apt packages..."
  $sudo apt-get update
  $sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y "${apt_packages[@]}"

  # Debian/Ubuntu rename bat and fd to avoid conflicts; link the usual names
  [[ -x "$local_bin/bat" ]] || ln -s "$(command -v batcat)" "$local_bin/bat"
  [[ -x "$local_bin/fd" ]] || ln -s "$(command -v fdfind)" "$local_bin/fd"

  # uv (installs to ~/.local/bin; .bashrc handles PATH setup)
  if [[ ! -x "$local_bin/uv" ]]; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
  fi

  # Python tools, plus clang tools, since PyPI has much newer versions than apt
  local uv_tools=(
    clang-format
    clangd
    python-lsp-server
    ruff
  )

  echo "Installing uv tools..."
  for tool in "${uv_tools[@]}"; do
    uv tool install "$tool"
  done

  # Neovim (apt's is too old for LazyVim)
  if [[ ! -x "$local_bin/nvim" ]]; then
    echo "Installing neovim..."
    local nvim_arch="$arch"
    [[ "$nvim_arch" == "aarch64" ]] && nvim_arch="arm64"
    rm -rf "$local_opt/nvim-linux-$nvim_arch"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$nvim_arch.tar.gz" |
      tar -xz -C "$local_opt"
    ln -s "$local_opt/nvim-linux-$nvim_arch/bin/nvim" "$local_bin/nvim"
  fi

  # fzf (.bashrc needs `fzf --bash`, which apt's is too old for)
  if [[ ! -x "$local_bin/fzf" ]]; then
    echo "Installing fzf..."
    local fzf_tag
    fzf_tag="$(latest_github_tag junegunn/fzf)"
    curl -fsSL "https://github.com/junegunn/fzf/releases/download/$fzf_tag/fzf-${fzf_tag#v}-linux_$goarch.tar.gz" |
      tar -xz -C "$local_bin" fzf
    curl -fsSL -o "$local_bin/fzf-tmux" "https://raw.githubusercontent.com/junegunn/fzf/$fzf_tag/bin/fzf-tmux"
    chmod +x "$local_bin/fzf-tmux"
  fi

  # zoxide (.bashrc needs `zoxide init --cmd`, which apt's is too old for)
  if [[ ! -x "$local_bin/zoxide" ]]; then
    echo "Installing zoxide..."
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh |
      sh -s -- --bin-dir "$local_bin" --man-dir "$HOME/.local/share/man"
  fi

  # eza (not packaged on older Debian/Ubuntu)
  if [[ ! -x "$local_bin/eza" ]]; then
    echo "Installing eza..."
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_$arch-unknown-linux-gnu.tar.gz" |
      tar -xz -C "$local_bin"
  fi

  # bat-extras, for batman (not packaged on Debian/Ubuntu)
  if [[ ! -x "$local_bin/batman" ]]; then
    echo "Installing bat-extras..."
    local bat_extras_tag tmp_zip
    bat_extras_tag="$(latest_github_tag eth-p/bat-extras)"
    tmp_zip="$(mktemp)"
    curl -fsSL -o "$tmp_zip" "https://github.com/eth-p/bat-extras/releases/download/$bat_extras_tag/bat-extras-${bat_extras_tag#v}.zip"
    rm -rf "$local_opt/bat-extras"
    unzip -q "$tmp_zip" -d "$local_opt/bat-extras"
    rm "$tmp_zip"
    ln -s "$local_opt/bat-extras/bin/batman" "$local_bin/batman"
  fi

  # Claude Code (installs to ~/.local/bin)
  if [[ ! -x "$local_bin/claude" ]]; then
    echo "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
  fi
}

OS="$(uname -s)"
case "$OS" in
Darwin) install_macos ;;
Linux) install_linux ;;
*)
  echo "ERROR: unsupported OS $OS"
  exit 1
  ;;
esac

# Install proto if it isn't already installed (.bashrc handles PATH setup)
if [[ ! -x "$HOME/.proto/bin/proto" ]]; then
  echo "Installing proto..."
  bash <(curl -fsSL https://moonrepo.dev/install/proto.sh) --yes --no-modify-profile
fi

echo ""
echo "Done."
