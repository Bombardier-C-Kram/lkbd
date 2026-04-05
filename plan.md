## Plan: Dual-mode XKB installation (legacy + extensions)

Ship one package with files for both the legacy (< 2.45) and extensions (>= 2.45) methods. Detect at install time which to activate. On xkeyboard-config upgrade, the systemd service auto-migrates from legacy to extensions.

**Steps**

### Phase 1: Build output — generate `evdev.xml`
1. Modify `APLSource/GenerateKb.aplf` — after the existing `layout.xml` generation (line ~38), also emit `OUTLAYOUT/evdev.xml`. This wraps the same layout/variant entries in a full `<xkbConfigRegistry>` document:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE xkbConfigRegistry SYSTEM "xkb.dtd">
   <xkbConfigRegistry version="1.1">
     <layoutList>
       {same <layout>...</layout> content as layout.xml}
     </layoutList>
   </xkbConfigRegistry>
   ```
   After `⎕XML layoutXml` produces `x`, string-wrap `x` with the registry boilerplate and write to a second file. Do not manipulate the matrix — it is simpler to concatenate the header/footer strings around the existing `x`.

### Phase 2: Packaging — `nfpm.yaml`
2. In `packaging/nfpm.yaml`, add two new `contents` entries (*parallel with step 1*):
   - `../OUTLAYOUT/dyalog` → `/usr/share/xkeyboard-config.d/dyalog-apl-keyboard/symbols/dyalog` (mode 0644)
   - `../OUTLAYOUT/evdev.xml` → `/usr/share/xkeyboard-config.d/dyalog-apl-keyboard/rules/evdev.xml` (mode 0644)
3. Remove the upper version bounds: delete `xkb-data (<< 2.45)` from deb overrides and `xkeyboard-config < 2.45` from rpm overrides. Keep `>= 2.33`.

### Phase 3: Scripts — runtime detection and migration
4. Rewrite `packaging/scripts/postinstall.sh` — add detection at top:
   - Detection: `[ -d /usr/share/xkeyboard-config-2.d ]` (the versioned extensions directory created by xkeyboard-config 2.45+ itself — distinct from the unversioned `xkeyboard-config.d` that our package installs to, so it is present iff the system supports extensions *before* our package ran)
   - If the check passes → extensions mode: print success message, do NOT run `register-layout.sh`, do NOT enable systemd service
   - Else → legacy mode: existing behavior (run `register-layout.sh`, enable systemd)

5. Rewrite `packaging/scripts/preremove.sh` — make cleanup conditional:
   - Keep `unregister_from_file` and XKB cache clearing unconditional. These are safe no-ops if legacy patching was never used, and this avoids leaving stale XML edits behind when `systemctl` is unavailable, `enable` failed during install, or the unit was manually disabled later
   - Make only the service cleanup conditional: `if command -v systemctl >/dev/null 2>&1; then systemctl disable ... || true; systemctl daemon-reload || true; fi`
   - For deb/rpm installs, package-manager removal handles the extensions files automatically after `preremove.sh` exits
   - For the tarball install path, add explicit removal of the extensions files/directories from `uninstall.sh`, since there is no package manager to remove them

6. Modify `packaging/scripts/register-layout.sh` — add migration logic at the top, before the existing patching code:
   - Detection: same `[ -d /usr/share/xkeyboard-config-2.d ]` check
   - If the check passes:
     - Inline the `unregister_from_file` function from `preremove.sh` (do not source preremove.sh — it has side effects; duplicate the ~10-line function here)
     - Call it on evdev.xml and base.xml to remove any legacy patches
     - Clear `/var/lib/xkb/*.xkm` after removing the legacy patches, so the system does not keep using stale cached rule data
     - Run `systemctl disable dyalog-apl-keyboard.service || true` (the `|| true` prevents `set -euo pipefail` from aborting if disable fails)
     - Exit 0
   - Else: proceed with existing patching behavior
   - This handles the migration case: system was installed with legacy, xkeyboard-config upgrades to >= 2.45, next boot the systemd service runs, detects extensions support, cleans up legacy patches, and disables itself.

### Phase 4: Build script
7. Update `packaging/build.sh` (*depends on step 1*):
   - Add existence check for `../OUTLAYOUT/evdev.xml`
   - In the tarball section, add `mkdir -p` for the extensions path and copy `dyalog` and `evdev.xml` into it
   - Update the tarball `uninstall.sh` behavior to remove the extensions files it installed, because unlike deb/rpm there is no package manager to clean them up

### Phase 5: Documentation
8. Update `README.md`:
   - Replace the current "always patches XKB and installs a systemd service" wording with dual-mode behavior: legacy systems patch rules and enable the service; >= 2.45 systems use XKB extensions and do not need runtime patching
   - Document the accepted X11 limitation on >= 2.45 systems: the layout works, but may not appear in X11 settings UIs
   - Mention that generated outputs now include `OUTLAYOUT/evdev.xml`

**Relevant files**
- `APLSource/GenerateKb.aplf` — add evdev.xml generation after line 38 (`⎕NPUT` for layout.xml), reuse `layoutXml` matrix
- `packaging/nfpm.yaml` — add 2 contents entries in `contents:` block; remove upper bounds from `overrides:` section
- `packaging/scripts/postinstall.sh` — add `if [ -d /usr/share/xkeyboard-config-2.d ]` branch
- `packaging/scripts/preremove.sh` — keep XML cleanup unconditional; make only service cleanup conditional; add tarball extensions cleanup
- `packaging/scripts/register-layout.sh` — add migration block at top
- `packaging/build.sh` — add evdev.xml check and extensions dir to tarball
- `README.md` — document dual-mode install behavior and the X11 settings limitation on >= 2.45 systems
- `evdevBase.xml` — no changes (template stays as-is, used for both outputs)

**Verification**
1. Run `GenerateKb` and confirm both `OUTLAYOUT/layout.xml` and `OUTLAYOUT/evdev.xml` exist with correct content
2. Build packages via `build.sh` — confirm deb/rpm/tar.gz all include files at both paths
3. On a < 2.45 system: install package, confirm evdev.xml is patched, systemd service enabled, layout discoverable in settings
4. On a >= 2.45 system: install package, confirm evdev.xml is NOT patched, systemd NOT enabled, layout discoverable via extensions
5. Simulate migration: install on < 2.45, "upgrade" xkeyboard-config to >= 2.45 (create `/usr/share/xkeyboard-config-2.d/`), reboot/run service — confirm legacy patches removed, XKB cache cleared, and service self-disables
6. Verify uninstall behavior in both modes:
   - deb/rpm legacy install removes legacy XML patches and extension files
   - deb/rpm extensions install removes extension files without leaving legacy state behind
   - tarball uninstall removes both legacy patches (if any) and extension files/directories it created

**Decisions**
- Full `evdev.xml` generated in APL alongside `layout.xml` (user chose APL generation)
- X11 limitation accepted: on >= 2.45, extensions-only; layout works in X11 but won't appear in X11 settings UIs
- Detection method: existence of `/usr/share/xkeyboard-config-2.d/` (the versioned directory created by xkeyboard-config 2.45+ itself). Do NOT use `/usr/share/xkeyboard-config.d/` — our own package creates that directory, so checking it would always pass
- Extensions path for our files uses the **unversioned** directory (`xkeyboard-config.d`, not `xkeyboard-config-2.d`) for forward compatibility; detection uses the versioned one because xkeyboard-config 2.45 creates it as part of its own install

**Further Considerations**
1. The deb trigger (`interest_noawait: /usr/share/X11/xkb/rules`) is only useful for legacy mode. It could be kept harmlessly or removed — keeping it is simpler and it's a no-op on extensions systems.
2. The `systemd` dependency in both deb/rpm overrides: on extensions-only systems systemd isn't needed. Could make it a `Recommends` instead — but this is a minor optimization that could be deferred.
3. Cleanup should be keyed to actual system state, not only service enablement. XML unpatching and cache clearing are intentionally unconditional because they are safe no-ops when legacy mode was never active.
