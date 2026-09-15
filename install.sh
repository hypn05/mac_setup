#!/usr/bin/env bash
# Dev environment setup — a thin dispatcher over independent modules/*.sh.
# Works on macOS, Linux, and Windows via WSL2 (Ubuntu).
# Run only what you need; each module is also runnable directly (e.g. ./modules/zsh.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=modules/lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

OS="$(detect_os)"
case "$OS" in
  macos|linux|wsl) ;;
  *)
    echo "Unsupported OS (detected: $(uname -s))." >&2
    echo "Supported: macOS, Linux, and Windows via WSL2 (Ubuntu)." >&2
    echo "On Windows, run windows/bootstrap.ps1 on the host first, then install inside Ubuntu." >&2
    exit 1
    ;;
esac

# Modules available on every supported OS.
COMMON_MODULES=(git docker k8s zsh editor)
# WezTerm: in `all` on Linux/WSL (Cmd/Super+C/V parity); optional on macOS (iTerm is default).
WEZTERM_MODULE=wezterm
# macOS-only modules.
MACOS_ONLY=(iterm)

module_allowed() {
  local m="$1" x
  for x in "${COMMON_MODULES[@]}"; do
    [[ "$x" == "$m" ]] && return 0
  done
  [[ "$m" == "$WEZTERM_MODULE" ]] && return 0
  if [[ "$OS" == "macos" ]]; then
    for x in "${MACOS_ONLY[@]}"; do
      [[ "$x" == "$m" ]] && return 0
    done
  fi
  return 1
}

all_modules_for_os() {
  local out=() x
  out=("${COMMON_MODULES[@]}")
  case "$OS" in
    linux|wsl)
      out+=("$WEZTERM_MODULE")
      ;;
    macos)
      for x in "${MACOS_ONLY[@]}"; do
        out+=("$x")
      done
      ;;
  esac
  # bash 3.2: print space-separated for the caller to re-read into an array.
  echo "${out[*]}"
}

usage() {
  cat <<EOF
Usage: ./install.sh <module> [module ...]

Detected OS: $OS

Modules (mix and match — nothing here depends on another module):
  git      git, gh (+ aliases), git-delta, lazygit, and ~/.gitconfig
  docker   Docker (Desktop on macOS; Engine or Desktop+WSL elsewhere)
  k8s      kubectl, kubectx/kubens, k9s, stern
  zsh      oh-my-zsh + plugins, starship, atuin, modern CLI tools, pbcopy/pbpaste shims
  editor   Helix, glow, tmux (+ their configs) — optional, not pulled in by zsh
  wezterm  WezTerm + Mac-like Cmd/Super+C/V copy-paste (all OSes; recommended on Linux/WSL)
  iterm    iTerm2 + shell integration (macOS only; Nerd Font is opt-in)
  all      every installable module for this OS ($(all_modules_for_os))

  doctor   read-only health check across every module — installs nothing

Examples:
  ./install.sh zsh
  ./install.sh git zsh wezterm
  ./install.sh all
  ./install.sh doctor

Windows (host): run windows/bootstrap.ps1 once, then clone and install inside WSL Ubuntu.

Every module is safe to re-run: each checks what's already installed before acting.
Packages install via Homebrew (including Linuxbrew on Linux/WSL).
Shell shortcuts (sc, pbcopy, pbpaste, tmux yank) are identical across OSes.
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
      # shellcheck disable=SC2207
      modules=($(all_modules_for_os))
      ;;
    doctor)
      modules+=(doctor)
      ;;
    git|docker|k8s|zsh|editor|wezterm|iterm)
      if ! module_allowed "$arg"; then
        echo "Module '$arg' is not available on $OS." >&2
        if [[ "$arg" == "iterm" ]]; then
          echo "  iterm is macOS-only. On Linux/WSL run: ./install.sh wezterm" >&2
          echo "  (Super+C / Super+V match macOS Cmd+C / Cmd+V)." >&2
        fi
        exit 1
      fi
      modules+=("$arg")
      ;;
    *)
      echo "Unknown module: $arg" >&2
      usage
      exit 1
      ;;
  esac
done

echo "dev_setup — detected OS: $OS"

for m in "${modules[@]}"; do
  echo ""
  echo "==> $m"
  "$SCRIPT_DIR/modules/$m.sh"
done
