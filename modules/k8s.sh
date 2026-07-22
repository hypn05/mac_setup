#!/usr/bin/env bash
# k8s module: kubectl, kubectx/kubens, k9s
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

ensure_homebrew
brew_bundle "$SCRIPT_DIR/Brewfile.k8s"

echo ""
echo "k8s module done: kubectl, kubectx, kubens, k9s are installed."
echo "  - kubectx/kubens become interactive fuzzy-pickers automatically if fzf is installed (the 'zsh' module installs it)."
