# Macintosh Plus: Narrow Screen

A System 6 Control Panel device (`cdev` + `INIT`) for a Mac Plus whose CRT picture is too wide. It makes the system treat the screen as a narrower, centred rectangle so the menu bar, desktop icons and dialogs land inside the visible glass. Left and right margins are adjustable from the Control Panel.

- `narrowscreen/src/` — 68000 assembly for the INIT and cdev
- `narrowscreen/build.py` — assembles both, builds the resource fork and MacBinary file, and installs it onto a copy of a System 6 boot disk
- `narrowscreen/build/Narrow Screen.bin` — the built file (MacBinary); drop it into the System Folder
- `emu/` — headless MAME test harness (`run_test.sh`) and Lua test scripts; `emu/shots/` holds screenshots from test runs
- `site/` — Width Coil Lab, an interactive explainer of the Plus's CRT width circuit, published at https://devon7y.github.io/macintosh_plus/
- `mac-plus-narrow-screen-handoff.md` — project background and design notes

## Not included

Apple's ROM and System software are copyrighted and are not in this repository. To build and test, supply your own:

- `emu/roms/macplus/` — Mac Plus ROM (`342-0341-c.u6d`, `342-0342-b.u8d`) and `emu/roms/mackbd_m0110a/` keyboard ROM, in MAME's layout
- `emu/disks/system-6.0/6.0 System Tools.dc42` — a System 6.0 boot disk in Disk Copy 4.2 format

Build requirements: `m68k-elf-binutils` and `hfsutils`. Testing requires MAME.
