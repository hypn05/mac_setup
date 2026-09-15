#!/usr/bin/env bash
# wezterm module: install WezTerm + Mac-like keybindings (Super+C/V = Cmd+C/V).
# Primary target: Linux and WSL (Windows host). Optional on macOS as an iTerm alt.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

OS="$(detect_os)"
CFG_SRC="$SCRIPT_DIR/wezterm/wezterm.lua"

_install_wezterm_linux() {
  if command -v wezterm >/dev/null 2>&1; then
    echo "WezTerm already installed: $(command -v wezterm)"
    return 0
  fi

  if command -v brew >/dev/null 2>&1 && brew info wezterm >/dev/null 2>&1; then
    echo "Installing WezTerm via Homebrew..."
    brew install wezterm
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing WezTerm via apt (Wez's fury repo)..."
    sudo apt-get update -y
    sudo apt-get install -y curl gnupg apt-transport-https
    sudo curl -fsSL https://apt.fury.io/wez/gpg.key \
      | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
      | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
    sudo apt-get update -y
    sudo apt-get install -y wezterm
    return 0
  fi

  echo "Could not auto-install WezTerm. Install from https://wezterm.org/ and re-run." >&2
  exit 1
}

_link_config_unix() {
  link_file "$CFG_SRC" "$HOME/.wezterm.lua"
}

_link_config_windows_from_wsl() {
  local win_home win_cfg
  win_home="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"
  if [[ -z "$win_home" ]]; then
    echo "  could not resolve Windows %USERPROFILE% — link manually:"
    echo "    copy $CFG_SRC to C:\\Users\\<you>\\.wezterm.lua"
    return 1
  fi
  win_cfg="$(wslpath "$win_home" 2>/dev/null)/.wezterm.lua" || true
  if [[ -z "$win_cfg" || "$win_cfg" == "/.wezterm.lua" ]]; then
    echo "  could not convert Windows home to a WSL path — copy manually to:"
    echo "    $win_home\\.wezterm.lua"
    return 1
  fi
  echo "Linking WezTerm config into Windows home (GUI runs on the host)..."
  link_file "$CFG_SRC" "$win_cfg"
}

case "$OS" in
  macos)
    ensure_homebrew
    if brew list --cask wezterm >/dev/null 2>&1 || command -v wezterm >/dev/null 2>&1; then
      echo "WezTerm already installed."
    else
      echo "Installing WezTerm (cask)..."
      brew install --cask wezterm
    fi
    _link_config_unix
    echo ""
    echo "wezterm module done."
    echo "  - Super/Cmd+C and Super/Cmd+V copy/paste match iTerm"
    echo "  - optional: keep using ./install.sh iterm if you prefer iTerm2"
    ;;

  linux)
    ensure_homebrew
    _install_wezterm_linux
    _link_config_unix
    echo ""
    echo "wezterm module done."
    echo "  - Super+C / Super+V = copy / paste (same as macOS Cmd+C / Cmd+V)"
    echo "  - Ctrl+Shift+C / Ctrl+Shift+V also work"
    echo "  - launch with: wezterm"
    ;;

  wsl)
    # WezTerm's GUI belongs on Windows; we still drop the shared config there.
    echo "WSL detected — WezTerm should run on the Windows host (not inside WSL)."
    if command -v wezterm.exe >/dev/null 2>&1 || command -v wezterm >/dev/null 2>&1; then
      echo "  WezTerm looks available from this distro."
    else
      echo "  Install on Windows (PowerShell):"
      echo "    winget install --id wez.wezterm -e"
      echo "  Or download: https://wezterm.org/"
    fi
    _link_config_windows_from_wsl || true
    # Also link inside WSL home in case someone runs wezterm under WSLg.
    _link_config_unix
    echo ""
    echo "wezterm module done."
    echo "  - Config uses Super+C / Super+V (Mac Cmd parity) + Ctrl+Shift+C/V"
    echo "  - Open WezTerm on Windows and start a WSL tab/domain"
    ;;

  *)
    echo "Unsupported OS for wezterm module: $OS" >&2
    exit 1
    ;;
esac
