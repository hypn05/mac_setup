#!/usr/bin/env bash
# editor module: Helix, glow, tmux — split out from zsh so the shell setup
# doesn't force an editor/multiplexer opinion on you.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

ensure_homebrew
brew_bundle "$SCRIPT_DIR/Brewfile.editor"

echo "Linking editor/tmux config"
link_file "$SCRIPT_DIR/helix/config.toml" "$HOME/.config/helix/config.toml"
link_file "$SCRIPT_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"
link_file "$SCRIPT_DIR/bin/tmux-copy" "$HOME/.local/bin/tmux-copy"
chmod +x "$SCRIPT_DIR/bin/tmux-copy"

echo ""
echo "editor module done. Remaining manual steps:"
echo "  - if you also run the 'zsh' module, EDITOR/VISUAL/GIT_EDITOR/KUBE_EDITOR"
echo "    auto-detect hx (falls back to vim/vi if this module isn't installed)"
echo "  - the 'zsh' module's shortcuts.zsh only registers e/ef/eg/ze/hxconfig/mdv"
echo "    and tn/ta/ts/tk/thelp when hx/glow/tmux are actually present"
echo "  - tmux copy uses ~/.local/bin/tmux-copy (pbcopy / wl-copy / xclip / clip.exe)"
echo "  - try: hx --tutor   |   thelp   |   sc editor   |   sc tmux"
