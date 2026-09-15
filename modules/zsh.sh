#!/usr/bin/env bash
# zsh module: oh-my-zsh + plugins, starship prompt, modern CLI tools, shortcuts.zsh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

ensure_homebrew
brew_bundle "$SCRIPT_DIR/Brewfile.zsh"

echo "Installing oh-my-zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "  oh-my-zsh already installed."
else
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "Installing custom zsh plugins (not bundled with oh-my-zsh core)"
# Plain indexed arrays on purpose: macOS ships bash 3.2, which has no associative arrays.
# Order of install does not matter; load order is controlled in zsh/zshrc.
plugin_names=(zsh-autosuggestions zsh-syntax-highlighting you-should-use fzf-tab)
plugin_urls=(
  "https://github.com/zsh-users/zsh-autosuggestions"
  "https://github.com/zsh-users/zsh-syntax-highlighting"
  "https://github.com/MichaelAquilina/zsh-you-should-use"
  "https://github.com/Aloxaf/fzf-tab"
)
for i in "${!plugin_names[@]}"; do
  clone_if_missing "${plugin_urls[$i]}" "$ZSH_CUSTOM/plugins/${plugin_names[$i]}"
done

# Stale symlink cleanup: earlier versions also linked ~/.zsh/shortcut.zsh
# (singular) as a back-compat redirect. shortcuts.zsh (plural) is now the
# only source of truth — remove the old link if a prior run created it.
if [[ -L "$HOME/.zsh/shortcut.zsh" ]]; then
  echo "Removing stale ~/.zsh/shortcut.zsh symlink (superseded by shortcuts.zsh)"
  rm "$HOME/.zsh/shortcut.zsh"
fi

echo "Linking zsh config"
link_file "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$SCRIPT_DIR/zsh/shortcuts.zsh" "$HOME/.zsh/shortcuts.zsh"
link_file "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"

# On Linux/WSL, install clipboard backends + macOS-named shims so the same
# shortcuts work (OMZ copyfile/copypath, scpath, pipes like `cmd | pbcopy`).
os="$(detect_os)"
if [[ "$os" == "linux" || "$os" == "wsl" ]]; then
  echo "Installing Linux clipboard backends (xclip, wl-clipboard when available)"
  if command -v brew >/dev/null 2>&1; then
    brew install xclip >/dev/null 2>&1 || brew install xclip || true
    # wl-clipboard is Linux-only in Homebrew; ignore failures on odd hosts.
    brew install wl-clipboard >/dev/null 2>&1 || true
  fi

  echo "Linking macOS-compatible clipboard shims (pbcopy / pbpaste)"
  mkdir -p "$HOME/.local/bin"
  chmod +x "$SCRIPT_DIR/bin/pbcopy" "$SCRIPT_DIR/bin/pbpaste"
  if ! command -v pbcopy >/dev/null 2>&1 || [[ "$(command -v pbcopy)" == "$HOME/.local/bin/pbcopy" ]]; then
    link_file "$SCRIPT_DIR/bin/pbcopy" "$HOME/.local/bin/pbcopy"
  else
    echo "  pbcopy already on PATH ($(command -v pbcopy)) — leaving it"
  fi
  if ! command -v pbpaste >/dev/null 2>&1 || [[ "$(command -v pbpaste)" == "$HOME/.local/bin/pbpaste" ]]; then
    link_file "$SCRIPT_DIR/bin/pbpaste" "$HOME/.local/bin/pbpaste"
  else
    echo "  pbpaste already on PATH ($(command -v pbpaste)) — leaving it"
  fi
fi

echo "Setting up ~/.zshrc.secrets (long-lived secrets — sourced from .zshrc, never committed)"
copy_if_missing "$SCRIPT_DIR/zsh/zshrc.secrets.template" "$HOME/.zshrc.secrets"
chmod 600 "$HOME/.zshrc.secrets"

echo ""
echo "zsh module done. Remaining manual steps:"
echo "  - restart your shell (or run 'exec zsh') to pick everything up"
echo "  - fill in ~/.zshrc.secrets with tokens"
echo "  - on Linux/WSL, if 'brew' is missing in new shells, add to ~/.zprofile:"
echo "      eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\""
echo "  - run the 'editor' module for Helix/tmux (EDITOR falls back to vim/vi without it)"
echo "  - optional: atuin login   # sync history across machines (works local-only without this)"
