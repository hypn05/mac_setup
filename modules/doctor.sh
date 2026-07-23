#!/usr/bin/env bash
# doctor: read-only health check across every module — installs nothing.
# Run via ./install.sh doctor, or `sc doctor` from an interactive shell
# (which finds this repo by resolving the ~/.zsh/shortcuts.zsh symlink).
set -uo pipefail   # no -e: run every check, don't stop at the first failure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

fail=0

section() { echo ""; echo "== $1 =="; }

# Reads a Brewfile's `brew "x"` / `cask "x"` lines and checks each is installed.
check_brewfile() {
  local brewfile="$1" kind name
  [[ -f "$brewfile" ]] || { echo "  [skip]    $(basename "$brewfile") not found"; return; }
  while IFS= read -r line; do
    case "$line" in
      brew\ \"*) kind=formula; name="${line#brew \"}"; name="${name%%\"*}" ;;
      cask\ \"*) kind=cask; name="${line#cask \"}"; name="${name%%\"*}" ;;
      *) continue ;;
    esac
    if brew list "--$kind" 2>/dev/null | grep -qx "$name"; then
      echo "  [ok]      $name"
    else
      echo "  [missing] $name  (brew bundle --file=$(basename "$brewfile"))"
      fail=1
    fi
  done < "$brewfile"
}

# Confirms dest is a symlink pointing at exactly $want.
check_link() {
  local dest="$1" want="$2"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$want" ]]; then
    echo "  [ok]      $dest"
  elif [[ -e "$dest" ]]; then
    echo "  [warn]    $dest exists but doesn't point at $want (see ${dest}.bak?)"
    fail=1
  else
    echo "  [missing] $dest"
    fail=1
  fi
}

check_exists() {
  local dest="$1"
  if [[ -e "$dest" ]]; then
    echo "  [ok]      $dest"
  else
    echo "  [missing] $dest"
    fail=1
  fi
}

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew isn't installed — nothing else can be verified."
  exit 1
fi

section "git"
check_brewfile "$SCRIPT_DIR/Brewfile.git"
check_exists "$HOME/.gitconfig"
if command -v gh >/dev/null 2>&1; then
  if gh alias list 2>/dev/null | grep -q '^prc'; then
    echo "  [ok]      gh aliases set"
  else
    echo "  [missing] gh aliases (re-run: ./install.sh git)"
    fail=1
  fi
fi

section "docker"
check_brewfile "$SCRIPT_DIR/Brewfile.docker"

section "k8s"
check_brewfile "$SCRIPT_DIR/Brewfile.k8s"

section "zsh"
check_brewfile "$SCRIPT_DIR/Brewfile.zsh"
check_exists "$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
for p in zsh-autosuggestions zsh-syntax-highlighting you-should-use fzf-tab; do
  check_exists "$ZSH_CUSTOM/plugins/$p"
done
check_link "$HOME/.zshrc" "$SCRIPT_DIR/zsh/zshrc"
check_link "$HOME/.zsh/shortcuts.zsh" "$SCRIPT_DIR/zsh/shortcuts.zsh"
check_link "$HOME/.config/starship.toml" "$SCRIPT_DIR/starship.toml"
if [[ -e "$HOME/.zshrc.secrets" ]]; then
  perm=$(stat -f '%Lp' "$HOME/.zshrc.secrets" 2>/dev/null)
  if [[ "$perm" == "600" ]]; then
    echo "  [ok]      ~/.zshrc.secrets (chmod 600)"
  else
    echo "  [warn]    ~/.zshrc.secrets exists but permissions are $perm, expected 600"
    fail=1
  fi
  set_vars=$(grep -cE '^export [A-Z_]+=.+' "$HOME/.zshrc.secrets" 2>/dev/null)
  echo "  [info]    $set_vars optional var(s) set in ~/.zshrc.secrets"
else
  echo "  [missing] ~/.zshrc.secrets"
  fail=1
fi

section "editor"
check_brewfile "$SCRIPT_DIR/Brewfile.editor"
check_link "$HOME/.config/helix/config.toml" "$SCRIPT_DIR/helix/config.toml"
check_link "$HOME/.tmux.conf" "$SCRIPT_DIR/tmux/tmux.conf"

section "iterm"
check_brewfile "$SCRIPT_DIR/Brewfile.iterm"
check_exists "$HOME/.iterm2_shell_integration.zsh"

echo ""
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "Some checks failed or warned — see [missing]/[warn] above."
fi
exit "$fail"
