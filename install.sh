#!/usr/bin/env bash
# New Mac setup — a thin dispatcher over independent modules/*.sh.
# Run only what you need; each module is also runnable directly (e.g. ./modules/zsh.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This script is for macOS only." >&2
  exit 1
fi

usage() {
  cat <<'EOF'
Usage: ./install.sh <module> [module ...]

Modules (mix and match — nothing here depends on another module):
  git      git, gh (+ aliases), git-delta, lazygit, and ~/.gitconfig
  docker   Docker Desktop (Engine, CLI, Compose v2)
  k8s      kubectl, kubectx/kubens, k9s, stern
  zsh      oh-my-zsh + plugins, starship, atuin, modern CLI tools, ~/.zsh/shortcuts.zsh
  editor   Helix, glow, tmux (+ their configs) — optional, not pulled in by zsh
  iterm    iTerm2 + shell integration (Nerd Font is opt-in, see Brewfile.iterm)
  all      every installable module above (git docker k8s zsh editor iterm)

  doctor   read-only health check across every module — installs nothing

Examples:
  ./install.sh zsh
  ./install.sh git zsh
  ./install.sh all
  ./install.sh doctor

Every module is safe to re-run: each checks what's already installed before acting.
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

# Plain indexed array, not associative: macOS ships bash 3.2 by default.
modules=()
for arg in "$@"; do
  case "$arg" in
    -h|--help)
      usage
      exit 0
      ;;
    all)
      modules=(git docker k8s zsh editor iterm)
      ;;
    git|docker|k8s|zsh|editor|iterm|doctor)
      modules+=("$arg")
      ;;
    *)
      echo "Unknown module: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

for m in "${modules[@]}"; do
  echo ""
  echo "==> $m"
  "$SCRIPT_DIR/modules/$m.sh"
done
