#!/usr/bin/env bash
# git module: git, gh, git-delta, lazygit + ~/.gitconfig
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

ensure_homebrew
brew_bundle "$SCRIPT_DIR/Brewfile.git"

echo "Setting up ~/.gitconfig"
copy_if_missing "$SCRIPT_DIR/git/gitconfig.template" "$HOME/.gitconfig"

if command -v gh >/dev/null 2>&1; then
  echo "Setting up gh CLI aliases (gh <alias>, e.g. 'gh prc')"
  # Plain indexed arrays, not associative: macOS ships bash 3.2.
  gh_alias_names=(prc prv prl prco prw)
  gh_alias_cmds=(
    "pr create --fill"
    "pr view --web"
    "pr list"
    "pr checkout"
    "pr checks --watch"
  )
  for i in "${!gh_alias_names[@]}"; do
    gh alias set --clobber "${gh_alias_names[$i]}" "${gh_alias_cmds[$i]}" >/dev/null
  done
fi

echo ""
echo "git module done. Remaining manual steps:"
echo "  - edit ~/.gitconfig (or run 'git config --global user.name/user.email') if it was just created"
echo "  - run 'gh auth login' to authenticate the GitHub CLI"
