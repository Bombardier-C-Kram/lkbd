#!/bin/bash
# Pre-remove script for dyalog-apl-keyboard

set -euo pipefail

# Remove layout entry from evdev.xml and base.xml (safe no-op if never patched)
unregister_from_file() {
    local xml_file="$1"
    [ -f "$xml_file" ] || return 0
    grep -q '<name>dyalog</name>' "$xml_file" 2>/dev/null || return 0

    sed -i '/<layout>/{
        :start
        /<\/layout>/!{N;b start}
        /<name>dyalog<\/name>/d
    }' "$xml_file"
}

unregister_from_file /usr/share/X11/xkb/rules/evdev.xml
unregister_from_file /usr/share/X11/xkb/rules/base.xml

# Clear XKB cache
rm -rf /var/lib/xkb/*.xkm 2>/dev/null || true

# Disable boot-time check (only if systemctl is available)
if command -v systemctl >/dev/null 2>&1; then
    systemctl disable dyalog-apl-keyboard.service 2>/dev/null || true
    systemctl daemon-reload || true
fi

# Remove extensions files (for tarball installs; deb/rpm package manager handles these)
rm -f /usr/share/xkeyboard-config.d/dyalog-apl-keyboard/symbols/dyalog
rm -f /usr/share/xkeyboard-config.d/dyalog-apl-keyboard/rules/evdev.xml
rmdir /usr/share/xkeyboard-config.d/dyalog-apl-keyboard/symbols 2>/dev/null || true
rmdir /usr/share/xkeyboard-config.d/dyalog-apl-keyboard/rules 2>/dev/null || true
rmdir /usr/share/xkeyboard-config.d/dyalog-apl-keyboard 2>/dev/null || true
