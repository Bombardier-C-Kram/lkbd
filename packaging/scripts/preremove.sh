#!/bin/bash
# Pre-remove script for dyalog-apl-keyboard

set -euo pipefail

# Disable boot-time check
if command -v systemctl >/dev/null 2>&1; then
    systemctl disable dyalog-apl-keyboard.service 2>/dev/null || true
    systemctl daemon-reload || true
fi

# Remove layout entry from evdev.xml and base.xml
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
