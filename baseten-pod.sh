#!/usr/bin/env bash
# Baseten dev pod setup: point git's GitHub credentials at the PATs pod-auth.sh
# puts on the pod, and clone Baseten's repos. bootstrap.sh runs this on dev
# pods, and pod-auth.sh runs it again once the PATs are in place. Safe to rerun.

set -euo pipefail

if ! command -v gh &>/dev/null; then
  echo "ERROR: gh isn't installed."
  exit 1
fi

gitconfig_local="$HOME/.gitconfig_local"
pvk_token="$HOME/.config/git-tokens/allispaul"

# Pods have no GitHub SSH key, so git uses HTTPS with gh's token (the basetenlabs
# PAT). The empty value drops the helpers inherited from .gitconfig.
git config --file "$gitconfig_local" --replace-all credential.https://github.com.helper ''
git config --file "$gitconfig_local" --add credential.https://github.com.helper '!gh auth git-credential'

# gh holds one token per account, so allispaul's own repos read their PAT from a
# file. Rewritten every run to stay below the github.com section: git applies
# every matching section in file order, so an earlier one would be reset by it.
git config --file "$gitconfig_local" --remove-section credential.https://github.com/allispaul 2>/dev/null || true
if [[ -f "$pvk_token" ]]; then
  git config --file "$gitconfig_local" --add credential.https://github.com/allispaul.helper ''
  # shellcheck disable=SC2016  # expanded by git's shell each time it asks
  git config --file "$gitconfig_local" --add credential.https://github.com/allispaul.helper \
    '!f() { test "$1" = get && printf "username=allispaul\npassword=%s\n" "$(cat ~/.config/git-tokens/allispaul)"; }; f'
fi

# A failed clone shouldn't stop the rest of the setup.
clone_basetenlabs() {
  local repo="$1" dest="$2"
  shift 2
  [[ -d "$dest" ]] && return
  echo "Cloning basetenlabs/$repo..."
  git clone "$@" "https://github.com/basetenlabs/$repo.git" "$dest" ||
    echo "WARNING: couldn't clone basetenlabs/$repo, skipping."
}

if gh auth status &>/dev/null; then
  clone_basetenlabs baseten "$HOME/baseten"
  # On the branch prod's image is built from (ENGINE_SHA in the monorepo's
  # mp/baseten_dynamo/cache_aware_routing_trtllm/versions/trtllm.env), not the
  # repo's default branch. Blobs are fetched on demand and LFS files skipped
  # (`git lfs pull` gets them), since it's several GB.
  GIT_LFS_SKIP_SMUDGE=1 clone_basetenlabs trt-llm "$HOME/trt-llm" --filter=blob:none --branch b10-1.3.0rc29
else
  echo "WARNING: gh isn't logged in, so skipping the basetenlabs clones. Run pod-auth.sh <pod> on your Mac."
fi
