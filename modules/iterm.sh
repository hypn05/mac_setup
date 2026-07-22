#!/usr/bin/env bash
# iterm module: iTerm2 + Nerd Font (for prompt icons)
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
echo "iterm module done. Remaining manual step:"
echo "  - in iTerm2: Preferences -> Profiles -> Text -> Font, set it to 'Hack Nerd Font'"
echo "    so prompt icons (from the 'zsh' module's starship config) render correctly"
echo "  - shell integration (command status marks, jump-to-prompt) is picked up"
echo "    automatically by the 'zsh' module's ~/.zshrc; if you're not using that"
echo "    module, source ~/.iterm2_shell_integration.zsh from your own .zshrc"
