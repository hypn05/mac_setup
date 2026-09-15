#!/usr/bin/env bash
# Shared helpers, sourced by modules/*.sh. Not meant to be run directly.
# Every helper here checks current state before acting, so modules are safe to re-run.

# By default `brew install`/`brew bundle` first re-checks (and sometimes
# re-downloads multi-MB JSON indexes for) Homebrew's formula/cask catalog.
# That's fine for a single one-off install, but this repo's whole point is
# running several modules back-to-back, and re-fetching the same catalog
# for every single one is most of what made setup feel slow. Skip it here;
# run a plain `brew update` yourself occasionally to pick up new formula
# versions outside of this script.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALL_CLEANUP=1
export HOMEBREW_NO_ENV_HINTS=1

# Detect the host OS for module filtering and install branches.
# Prints: macos | linux | wsl
# bash 3.2-safe (no associative arrays).
detect_os() {
  local uname_s
  uname_s="$(uname -s)"
  case "$uname_s" in
    Darwin)
      echo "macos"
      ;;
    Linux)
      if grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
        echo "wsl"
      else
        echo "linux"
      fi
      ;;
    *)
      echo "unsupported"
      ;;
  esac
}

# Exit with a clear message unless the current OS is in the allowed list.
# Usage: require_os macos
#        require_os linux wsl
require_os() {
  local current allowed
  current="$(detect_os)"
  for allowed in "$@"; do
    if [[ "$current" == "$allowed" ]]; then
      return 0
    fi
  done
  echo "This module is for $* only (detected: $current)." >&2
  exit 1
}

# Eval brew shellenv from the first known prefix that exists.
_brew_shellenv() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed."
    return
  fi

  _brew_shellenv
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed."
    return
  fi

  local os
  os="$(detect_os)"
  if [[ "$os" == "linux" || "$os" == "wsl" ]]; then
    echo "Linuxbrew needs a compiler toolchain on fresh Ubuntu/Debian."
    echo "  If install fails, run: sudo apt update && sudo apt install -y build-essential curl file git"
  fi

  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  _brew_shellenv

  if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew install finished but 'brew' is not on PATH." >&2
    echo "Add brew to your shell profile, then re-run this module." >&2
    if [[ "$os" == "linux" || "$os" == "wsl" ]]; then
      echo "  echo 'eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"' >> ~/.zprofile" >&2
    fi
    exit 1
  fi
}

# brew bundle is itself idempotent (skips anything already installed).
brew_bundle() {
  local brewfile="$1"
  echo "Installing packages from $(basename "$brewfile")"
  brew bundle --file="$brewfile"
}

# Symlink src -> dest. Backs up any pre-existing, non-symlink file at dest
# so a re-run never silently clobbers something you were keeping.
link_file() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" ]]; then
    ln -sf "$src" "$dest"
  elif [[ -e "$dest" ]]; then
    echo "  $dest already exists — backing up to ${dest}.bak"
    mv "$dest" "${dest}.bak"
    ln -s "$src" "$dest"
  else
    ln -s "$src" "$dest"
  fi
  echo "  linked $dest -> $src"
}

# Copy src -> dest only if dest doesn't exist yet. For files you personalize
# after the fact (gitconfig, secrets) where we must never overwrite your edits.
copy_if_missing() {
  local src="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ -e "$dest" ]]; then
    echo "  $dest already exists, leaving it untouched."
  else
    cp "$src" "$dest"
    echo "  created $dest from template"
  fi
}

# Shallow-clone a git repo to dest only if dest doesn't already exist.
clone_if_missing() {
  local url="$1" dest="$2" name
  name="$(basename "$dest")"
  if [[ -d "$dest" ]]; then
    echo "  $name already installed."
  else
    echo "  installing $name"
    git clone --depth=1 "$url" "$dest"
  fi
}

# Portable octal mode for a file (e.g. 600). Empty string if unreadable.
file_mode() {
  local path="$1"
  case "$(detect_os)" in
    macos)
      stat -f '%Lp' "$path" 2>/dev/null
      ;;
    *)
      stat -c '%a' "$path" 2>/dev/null
      ;;
  esac
}
