#!/usr/bin/env bash
# touchid module: use Touch ID to authenticate sudo (macOS only, on Macs with Touch ID).
# On macOS Ventura+ /etc/pam.d/sudo includes /etc/pam.d/sudo_local, which survives
# macOS updates — so we write the pam_tid.so line there. On older macOS we patch
# /etc/pam.d/sudo directly (and warn that updates may revert it).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/modules/lib.sh"

require_os macos

PAM_LINE="auth       sufficient     pam_tid.so"
SUDO_PAM="/etc/pam.d/sudo"
SUDO_LOCAL="/etc/pam.d/sudo_local"

# Touch ID requires the hardware sensor; bioutil is only present on real Macs.
if ! /usr/bin/bioutil -r >/dev/null 2>&1; then
  echo "No Touch ID hardware detected on this Mac — nothing to do."
  exit 0
fi

if grep -q 'pam_tid\.so' "$SUDO_PAM" 2>/dev/null || \
   { [[ -f "$SUDO_LOCAL" ]] && grep -q 'pam_tid\.so' "$SUDO_LOCAL"; }; then
  echo "Touch ID for sudo is already enabled."
else
  if grep -q 'sudo_local' "$SUDO_PAM" 2>/dev/null; then
    # Modern macOS: sudo PAM config includes sudo_local — survives OS updates.
    echo "Enabling Touch ID for sudo via $SUDO_LOCAL (survives macOS updates)..."
    if [[ -f "$SUDO_LOCAL" ]] && [[ -s "$SUDO_LOCAL" ]]; then
      # Keep existing sudo_local content, insert the Touch ID line first.
      { echo "$PAM_LINE"; cat "$SUDO_LOCAL"; } | sudo tee "$SUDO_LOCAL.tmp" >/dev/null
      sudo mv "$SUDO_LOCAL.tmp" "$SUDO_LOCAL"
    else
      echo "$PAM_LINE" | sudo tee "$SUDO_LOCAL" >/dev/null
    fi
    sudo chmod 444 "$SUDO_LOCAL"
  else
    # Older macOS: patch /etc/pam.d/sudo in place (insert before the first auth line).
    echo "Enabling Touch ID for sudo via $SUDO_PAM..."
    sudo sed -i '' -e "/^auth/i\\
$PAM_LINE
" "$SUDO_PAM"
    echo "  note: macOS updates may reset $SUDO_PAM — re-run this module after upgrading."
  fi
fi

echo ""
echo "touchid module done. Touch ID now satisfies the sudo password prompt."
echo "  Test with: sudo -k && sudo true  (should offer Touch ID)"
echo "  Password still works as fallback (e.g. over SSH or with wet fingers)."
