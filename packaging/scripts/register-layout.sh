#!/bin/bash
# Idempotent registration of Dyalog APL layout in XKB evdev.xml/base.xml
# Safe to run repeatedly. Only patches if the entry is missing.

set -euo pipefail

LAYOUT_NAME="dyalog"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAYOUT_XML="${SCRIPT_DIR}/layout.xml"

if [ ! -f "$LAYOUT_XML" ]; then
    echo "Error: layout.xml not found at ${LAYOUT_XML}" >&2
    exit 1
fi

register_in_file() {
    local xml_file="$1"
    [ -f "$xml_file" ] || return 0

    if grep -q "<name>${LAYOUT_NAME}</name>" "$xml_file" 2>/dev/null; then
        return 0
    fi

    local tmp mode
    tmp="$(mktemp "${xml_file}.tmp.XXXXXX")"
    mode="$(stat -c '%a' "$xml_file" 2>/dev/null || echo 644)"
    chmod "$mode" "$tmp"
    awk -v layoutfile="$LAYOUT_XML" '
        /<\/layoutList>/ {
            while ((getline line < layoutfile) > 0) print "  " line
            close(layoutfile)
        }
        { print }
    ' "$xml_file" > "$tmp"
    mv "$tmp" "$xml_file"
}

register_in_file /usr/share/X11/xkb/rules/evdev.xml
register_in_file /usr/share/X11/xkb/rules/base.xml

# Clear XKB cache
rm -rf /var/lib/xkb/*.xkm 2>/dev/null || true
