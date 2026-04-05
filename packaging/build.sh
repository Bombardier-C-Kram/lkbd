#!/bin/bash
# Build RPM, DEB, and tar.gz packages using nfpm
#
# Prerequisites:
#   Install nfpm: https://nfpm.goreleaser.com/install/
#     go install github.com/goreleaser/nfpm/v2/cmd/nfpm@latest
#     # or: curl -sfL https://install.goreleaser.com/github.com/goreleaser/nfpm.sh | sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Check nfpm is installed
if ! command -v nfpm &>/dev/null; then
    echo "Error: nfpm not found. Install it from https://nfpm.goreleaser.com/install/"
    exit 1
fi

# Check generated files exist
if [ ! -f "../OUTLAYOUT/dyalog" ]; then
    echo "Error: OUTLAYOUT/dyalog not found. Generate the layout first."
    exit 1
fi

if [ ! -f "../OUTLAYOUT/layout.xml" ]; then
    echo "Error: OUTLAYOUT/layout.xml not found. Generate the layout first."
    exit 1
fi

mkdir -p dist

echo "Building DEB package..."
nfpm package --config nfpm.yaml --packager deb --target dist/

echo "Building RPM package..."
nfpm package --config nfpm.yaml --packager rpm --target dist/

echo "Building tar.gz archive..."
VERSION=$(grep '^version:' nfpm.yaml | awk '{print $2}')
TARDIR="dyalog-apl-keyboard-${VERSION}"
TARBALL="dist/${TARDIR}.tar.gz"
rm -rf "/tmp/${TARDIR}"
mkdir -p "/tmp/${TARDIR}/usr/share/X11/xkb/symbols"
mkdir -p "/tmp/${TARDIR}/usr/share/dyalog-apl-keyboard"
mkdir -p "/tmp/${TARDIR}/usr/lib/systemd/system"
cp ../OUTLAYOUT/dyalog "/tmp/${TARDIR}/usr/share/X11/xkb/symbols/dyalog"
cp ../OUTLAYOUT/layout.xml "/tmp/${TARDIR}/usr/share/dyalog-apl-keyboard/layout.xml"
cp scripts/register-layout.sh "/tmp/${TARDIR}/usr/share/dyalog-apl-keyboard/register-layout.sh"
cp systemd/dyalog-apl-keyboard.service "/tmp/${TARDIR}/usr/lib/systemd/system/"
cp scripts/postinstall.sh "/tmp/${TARDIR}/install.sh"
cp scripts/preremove.sh "/tmp/${TARDIR}/uninstall.sh"
chmod +x "/tmp/${TARDIR}/install.sh" "/tmp/${TARDIR}/uninstall.sh" "/tmp/${TARDIR}/usr/share/dyalog-apl-keyboard/register-layout.sh"
tar -czf "$TARBALL" -C /tmp "$TARDIR"
rm -rf "/tmp/${TARDIR}"

echo ""
echo "Packages built in dist/:"
ls -lh dist/
