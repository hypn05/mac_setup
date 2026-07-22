#!/usr/bin/env bash
# Shared helpers, sourced by modules/*.sh. Not meant to be run directly.
# Every helper here checks current state before acting, so modules are safe to re-run.

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    echo "Homebrew already installed."
    return
  fi
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
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
