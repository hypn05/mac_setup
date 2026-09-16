#!/usr/bin/env bash
# doctor: read-only health check across every module — installs nothing.
# Run via ./install.sh doctor, or `sc doctor` from an interactive shell
# (which finds this repo by resolving the ~/.zsh/shortcuts.zsh symlink).
set -uo pipefail   # no -e: run every check, don't stop at the first failure
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

fail=0
OS="$(detect_os)"

section() { echo ""; echo "== $1 =="; }

# Reads a Brewfile's `brew "x"` / `cask "x"` lines and checks each is installed.
#
# Checks `brew list --<kind> <name>` per item rather than grepping the full
# `brew list` output — the latter breaks silently when a cask is renamed
# upstream (e.g. "docker" -> "docker-desktop": still installable and listed
# under the old name via brew's alias, but absent from the plain listing).
#
# For formulas specifically, also falls back to `command -v`: things like
# git ship with Xcode Command Line Tools and work fine without ever being
# a Homebrew formula, so brew's install DB alone isn't the right question —
# "is this tool available" is.
check_brewfile() {
  local brewfile="$1" kind name
  [[ -f "$brewfile" ]] || { echo "  [skip]    $(basename "$brewfile") not found"; return; }
  # Read the Brewfile on fd 3, not stdin: `brew list` runs inside this loop,
  # and if anything it invokes ever reads stdin, sharing fd 0 with the loop's
  # own file input would silently eat lines and skip entries further down.
  while IFS= read -r line <&3; do
    case "$line" in
      brew\ \"*) kind=formula; name="${line#brew \"}"; name="${name%%\"*}" ;;
      cask\ \"*) kind=cask; name="${line#cask \"}"; name="${name%%\"*}" ;;
      *) continue ;;
    esac
    if [[ "$kind" == "cask" && "$OS" != "macos" ]]; then
      echo "  [skip]    $name (cask — macOS only)"
      continue
    fi
    if command -v brew >/dev/null 2>&1 && brew list "--$kind" "$name" >/dev/null 2>&1; then
      echo "  [ok]      $name"
    elif [[ "$kind" == "formula" ]] && command -v "$name" >/dev/null 2>&1; then
      echo "  [ok]      $name (on PATH, not via Homebrew)"
    else
      echo "  [missing] $name  (brew bundle --file=$(basename "$brewfile"))"
      fail=1
    fi
  done 3< "$brewfile"
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

check_cmd() {
  local name="$1"
  if command -v "$name" >/dev/null 2>&1; then
    echo "  [ok]      $name"
  else
    echo "  [missing] $name"
    fail=1
  fi
}

echo "doctor — detected OS: $OS"

if ! command -v brew >/dev/null 2>&1; then
  _brew_shellenv 2>/dev/null || true
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew isn't on PATH — formula checks will fall back to command -v only."
  echo "  On Linux/WSL: eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
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
case "$OS" in
  macos)
    check_brewfile "$SCRIPT_DIR/Brewfile.docker"
    ;;
  wsl)
    if command -v docker >/dev/null 2>&1; then
      echo "  [ok]      docker CLI"
      if docker info >/dev/null 2>&1; then
        echo "  [ok]      docker daemon reachable"
      else
        echo "  [warn]    docker CLI present but daemon not reachable"
        echo "            Prefer Docker Desktop on Windows with WSL integration enabled."
        fail=1
      fi
    else
      echo "  [missing] docker"
      echo "            Install Docker Desktop on Windows and enable WSL integration,"
      echo "            or re-run: ./install.sh docker"
      fail=1
    fi
    if docker compose version >/dev/null 2>&1; then
      echo "  [ok]      docker compose"
    else
      echo "  [missing] docker compose"
      fail=1
    fi
    ;;
  linux)
    check_cmd docker
    if docker compose version >/dev/null 2>&1; then
      echo "  [ok]      docker compose"
    else
      echo "  [missing] docker compose"
      fail=1
    fi
    if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1; then
      echo "  [warn]    docker needs a running daemon (and usually membership in the docker group)"
      fail=1
    fi
    ;;
esac

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
  perm="$(file_mode "$HOME/.zshrc.secrets")"
  if [[ "$perm" == "600" ]]; then
    echo "  [ok]      ~/.zshrc.secrets (chmod 600)"
  else
    echo "  [warn]    ~/.zshrc.secrets exists but permissions are ${perm:-unknown}, expected 600"
    fail=1
  fi
  set_vars=$(grep -cE '^export [A-Z_]+=.+' "$HOME/.zshrc.secrets" 2>/dev/null || true)
  echo "  [info]    $set_vars optional var(s) set in ~/.zshrc.secrets"
else
  echo "  [missing] ~/.zshrc.secrets"
  fail=1
fi

# Clipboard parity: pbcopy/pbpaste must exist everywhere (native or shim).
if command -v pbcopy >/dev/null 2>&1; then
  echo "  [ok]      pbcopy ($(command -v pbcopy))"
else
  echo "  [missing] pbcopy (re-run: ./install.sh zsh — installs Linux/WSL shim)"
  fail=1
fi
if command -v pbpaste >/dev/null 2>&1; then
  echo "  [ok]      pbpaste ($(command -v pbpaste))"
else
  echo "  [missing] pbpaste (re-run: ./install.sh zsh — installs Linux/WSL shim)"
  fail=1
fi

# theme.sh — terminal palette switcher with fzf preview
check_link "$HOME/.local/bin/theme.sh" "$SCRIPT_DIR/bin/theme.sh"
if command -v theme.sh >/dev/null 2>&1; then
  echo "  [ok]      theme.sh on PATH"
else
  echo "  [warn]    theme.sh not on PATH (ensure ~/.local/bin is on PATH)"
  fail=1
fi

section "editor"
check_brewfile "$SCRIPT_DIR/Brewfile.editor"
check_link "$HOME/.config/helix/config.toml" "$SCRIPT_DIR/helix/config.toml"
check_link "$HOME/.tmux.conf" "$SCRIPT_DIR/tmux/tmux.conf"
check_link "$HOME/.local/bin/tmux-copy" "$SCRIPT_DIR/bin/tmux-copy"

section "wezterm"
if [[ -L "$HOME/.wezterm.lua" || -f "$HOME/.wezterm.lua" ]]; then
  if [[ -L "$HOME/.wezterm.lua" ]]; then
    check_link "$HOME/.wezterm.lua" "$SCRIPT_DIR/wezterm/wezterm.lua"
  else
    echo "  [ok]      ~/.wezterm.lua (file present)"
  fi
else
  if [[ "$OS" == "macos" ]]; then
    echo "  [info]    ~/.wezterm.lua not linked (optional on macOS — iTerm is fine)"
  else
    echo "  [missing] ~/.wezterm.lua (re-run: ./install.sh wezterm for Cmd/Super+C/V parity)"
    fail=1
  fi
fi
if command -v wezterm >/dev/null 2>&1 || command -v wezterm.exe >/dev/null 2>&1; then
  echo "  [ok]      wezterm binary on PATH"
else
  if [[ "$OS" == "macos" ]]; then
    echo "  [info]    wezterm not installed (optional — use iterm or ./install.sh wezterm)"
  else
    echo "  [warn]    wezterm binary not on PATH (install via ./install.sh wezterm)"
    fail=1
  fi
fi

if [[ "$OS" == "macos" ]]; then
  section "iterm"
  check_brewfile "$SCRIPT_DIR/Brewfile.iterm"
  check_exists "$HOME/.iterm2_shell_integration.zsh"
else
  section "iterm"
  echo "  [skip]    iterm is macOS-only — use wezterm for Cmd/Super+C/V parity"
fi

echo ""
if [[ "$fail" -eq 0 ]]; then
  echo "All checks passed."
else
  echo "Some checks failed or warned — see [missing]/[warn] above."
fi
exit "$fail"
