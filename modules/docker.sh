#!/usr/bin/env bash
# docker module: Docker Desktop (Engine, CLI, Compose v2)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

ensure_homebrew
brew_bundle "$SCRIPT_DIR/Brewfile.docker"

echo ""
echo "docker module done. Remaining manual step:"
echo "  - open Docker Desktop once to finish onboarding"
echo "  - enable Kubernetes under Settings -> Kubernetes if you want a local cluster from Docker Desktop"
echo "    (or use the 'k8s' module for kubectl/kubectx/k9s instead)"
