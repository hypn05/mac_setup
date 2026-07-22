# Backward-compatible name. Prefer ~/.zsh/shortcuts.zsh (linked by modules/zsh.sh).
# If both exist, zshrc sources shortcuts.zsh only.
# This file exists so older docs / re-runs that look for shortcut.zsh still work.
if [[ -f "${0:A:h}/shortcuts.zsh" ]]; then
  source "${0:A:h}/shortcuts.zsh"
elif [[ -f "$HOME/.zsh/shortcuts.zsh" ]]; then
  source "$HOME/.zsh/shortcuts.zsh"
fi
