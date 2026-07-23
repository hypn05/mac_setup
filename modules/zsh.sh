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

echo "Setting up ~/.zshrc.secrets (long-lived secrets — sourced from .zshrc, never committed)"
copy_if_missing "$SCRIPT_DIR/zsh/zshrc.secrets.template" "$HOME/.zshrc.secrets"
chmod 600 "$HOME/.zshrc.secrets"

echo ""
echo "zsh module done. Remaining manual steps:"
echo "  - restart your shell (or run 'exec zsh') to pick everything up"
echo "  - fill in ~/.zshrc.secrets with tokens"
echo "  - run the 'editor' module for Helix/tmux (EDITOR falls back to vim/vi without it)"
echo "  - optional: atuin login   # sync history across machines (works local-only without this)"
