#!/usr/bin/env bash
# zsh module: oh-my-zsh + plugins, starship prompt, modern CLI tools, shortcut.zsh
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

echo "Linking zsh config"
link_file "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
link_file "$SCRIPT_DIR/zsh/shortcut.zsh" "$HOME/.zsh/shortcut.zsh"
link_file "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"

echo "Setting up ~/.zshrc.secrets (long-lived secrets — sourced from .zshrc, never committed)"
copy_if_missing "$SCRIPT_DIR/zsh/zshrc.secrets.template" "$HOME/.zshrc.secrets"
chmod 600 "$HOME/.zshrc.secrets"

echo ""
echo "zsh module done. Remaining manual steps:"
echo "  - restart your shell (or run 'exec zsh') to pick everything up"
echo "  - if you also run the 'iterm' module, set its font to a Nerd Font so prompt icons render"
