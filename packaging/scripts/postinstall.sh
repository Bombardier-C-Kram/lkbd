#!/bin/bash
# Post-install script for dyalog-apl-keyboard

set -euo pipefail

# Register layout in evdev.xml now
/usr/share/dyalog-apl-keyboard/register-layout.sh

# Enable boot-time check so registration survives xkb-data upgrades
if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload || true
    systemctl enable dyalog-apl-keyboard.service || true
fi

echo ""
echo "Dyalog APL keyboard layout installed and registered."
echo "Find 'Dyalog APL/en-US' in your desktop keyboard settings,"
echo "or configure your compositor directly with layout name 'dyalog'."
