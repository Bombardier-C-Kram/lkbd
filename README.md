# Dyalog APL Keyboard Layouts for Linux

XKB keyboard layouts that let you type APL characters on Linux.

Supports US, UK, and Canadian French base layouts. Normal typing is unaffected, and APL characters are only produced when holding a modifier key.

## Layouts

| Variant | Base Layout | Default APL Key | XKB Option |
|---------|-------------|-----------------|------------|
| en-US   | `us(basic)` | Right Alt (AltGr) | `level3(ralt_switch)` |
| en-GB   | `gb(basic)` | Right Ctrl | `level5(rctrl_switch)` |
| fr-CA   | `ca(fr)`    | Right Ctrl | `level5(rctrl_switch)` |

GB and FR-CA base layouts already use AltGr for accents and other characters, so APL characters default to Right Ctrl instead. The XKB option in the generated layout controls this and can be changed if you prefer a different key.

## Install

Grab a package from releases, or build one yourself (see below), then:

```sh
# Debian/Ubuntu
sudo apt install ./dyalog-apl-keyboard_*.deb

# Fedora/RHEL
sudo rpm -i dyalog-apl-keyboard-*.rpm
```

The package registers the layout with XKB and installs a systemd service to keep it registered across `xkb-data` updates.

To uninstall, use your package manager as usual, and cleanup will be handled automatically.

## Usage

### Activating the layout

Open your desktop's keyboard settings and add **Dyalog APL** with your preferred variant (en-US, en-GB, or fr-CA). You may need to log out and back in for the layout to appear.

You can also activate it from the command line. The exact command depends on your desktop environment:

```sh
# GNOME (Wayland or X11)
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'dyalog+us')]"

# KDE Plasma (Wayland)
# Use System Settings > Keyboard > Layouts, or:
kwriteconfig6 --file kxkbrc --group Layout --key LayoutList dyalog
kwriteconfig6 --file kxkbrc --group Layout --key VariantList us

# Sway
swaymsg input type:keyboard xkb_layout dyalog
swaymsg input type:keyboard xkb_variant us
```

Replace `us` with `gb` or `fr-ca` for other variants.

### Typing APL characters

Normal typing is unaffected. APL characters are produced by holding the modifier key for your variant:

| | en-US | en-GB | fr-CA |
|---|---|---|---|
| **Modifier** | Right Alt (AltGr) | Right Ctrl | Right Ctrl |

- **Modifier + key**: primary APL symbol
- **Modifier + Shift + key**: extended APL symbol

## Generating Layouts

The XKB files in `OUTLAYOUT/` are generated from the JSON definitions in `layouts/` using Dyalog APL:

```apl
⍝ First load the project:
⍝ ]link.Create # APLSource
⍝ Then run:
_←GenerateKb
```

This reads `layouts/*.json` and `xkb-symbols.json` and writes `OUTLAYOUT/dyalog` (XKB symbols) and `OUTLAYOUT/layout.xml` (XKB registration metadata).

## Building Packages

Requires [nfpm](https://github.com/goreleaser/nfpm).

```sh
cd packaging
./build.sh
```

Produces `.deb`, `.rpm`, and `.tar.gz` in `packaging/dist/`.

## License

MIT: See [LICENSE](LICENSE).
