#!/usr/bin/env bash
# iterm module: iTerm2 + shell integration (Nerd Font is opt-in, see Brewfile.iterm)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

ensure_homebrew
brew_bundle "$SCRIPT_DIR/Brewfile.iterm"

echo "Installing iTerm2 shell integration"
if [[ -f "$HOME/.iterm2_shell_integration.zsh" ]]; then
  echo "  already installed."
else
  curl -fsSL https://iterm2.com/shell_integration/zsh -o "$HOME/.iterm2_shell_integration.zsh"
fi

echo ""
echo "iterm module done. Remaining manual steps:"
echo "  - shell integration (command status marks, jump-to-prompt) is picked up"
echo "    automatically by the 'zsh' module's ~/.zshrc; if you're not using that"
echo "    module, source ~/.iterm2_shell_integration.zsh from your own .zshrc"
echo "  - starship.toml ships icon-free by default. If you re-enable icons, run"
echo "    'brew install --cask font-hack-nerd-font' and set it under iTerm2:"
echo "    Preferences -> Profiles -> Text -> Font"
