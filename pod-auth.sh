#!/usr/bin/env bash
# Log a Baseten dev pod into GitHub with the PATs in this Mac's Keychain, then
# run the pod's Baseten setup (baseten-pod.sh). Run on the Mac; safe to rerun,
# e.g. after rotating a PAT. The PATs go over kubectl's stdin, never argv.
# Usage: ./pod-auth.sh <pod>   (targets the current kube context; switch with `intertubin clusters use`)

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <pod>"
  exit 1
fi
pod="$1"
echo "Using kube context $(kubectl config current-context)"

pod_exec() {
  kubectl -n mp-devenv exec -i "$pod" -- "$@"
}

# Read up front, so a missing Keychain item fails here instead of sending an
# empty token to the pod.
b10_token="$(security find-generic-password -s gh-pod-pat-b10 -w)"
pvk_token="$(security find-generic-password -s gh-pod-pat-pvk -w)"

echo "Logging gh into GitHub with gh-pod-pat-b10..."
printf '%s\n' "$b10_token" | pod_exec gh auth login -h github.com --with-token

echo "Storing gh-pod-pat-pvk for allispaul's repos..."
printf '%s\n' "$pvk_token" |
  pod_exec bash -c 'umask 077 && mkdir -p ~/.config/git-tokens && cat > ~/.config/git-tokens/allispaul'

pod_exec bash -c 'if [[ -x ~/dotfiles/baseten-pod.sh ]]; then ~/dotfiles/baseten-pod.sh; else echo "No ~/dotfiles/baseten-pod.sh on the pod yet; run ~/dotfiles/bootstrap.sh there."; fi'
