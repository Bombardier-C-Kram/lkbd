#!/bin/bash
# Post-install script for dyalog-apl-keyboard

set -euo pipefail

if [ -d /usr/share/xkeyboard-config-2.d ]; then
    # Extensions mode: xkeyboard-config >= 2.45 supports XKB extensions natively.
    # Files are installed to /usr/share/xkeyboard-config.d/; no runtime patching needed.
    echo ""
    echo "Dyalog APL keyboard layout installed."
    echo "Find 'Dyalog APL' in your desktop keyboard settings."
    echo "(Note: the layout may not appear in X11 settings UIs.)"
else
    # Legacy mode: patch XKB rules files and enable systemd service.
    /usr/share/dyalog-apl-keyboard/register-layout.sh

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload || true
        systemctl enable dyalog-apl-keyboard.service || true
    fi

    echo ""
    echo "Dyalog APL keyboard layout installed and registered."
    echo "Find 'Dyalog APL/en-US' in your desktop keyboard settings,"
    echo "or configure your compositor directly with layout name 'dyalog'."
fi
