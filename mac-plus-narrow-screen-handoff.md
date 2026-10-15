# Mac Plus "Narrow Screen" Project: Handoff Brief

Context for a coding agent taking over. Written 2026-10-14 from a long troubleshooting chat with Devon (the owner). Devon is technical (PhD student, writes Python/MATLAB/JS daily) but has no electronics experience and no prior classic-Mac development experience.

---

## 1. Goal

Devon's Macintosh Plus works, but its CRT picture is physically **too wide**: the left and right edges of the 512×342 image fall behind the bezel. The Apple menu, the File menu, and the right-hand desktop icons (disk, Trash) are partly or fully hidden.

The hardware fix has not worked (see §3). Devon has chosen a **software workaround**:

> Build a System 6 startup extension (an **INIT**) that makes the OS and well-behaved apps treat the screen as narrower than 512 px (for example ~460–480 px wide, centred), so the menu bar, desktop icons, windows and dialogs all land inside the visible part of the glass.

Preferred extra: make the left/right margins **adjustable on the Mac itself** (for example a small Control Panel `cdev` with sliders, or a resource the INIT reads), so Devon can tune them on real hardware without a rebuild-and-transfer cycle.

### Development model Devon agreed to
1. The agent builds and tests **entirely in an emulator** (Mini vMac in Mac Plus mode), driving it headlessly: virtual display, screenshots, scripted input.
2. The agent delivers **one finished artifact**: a disk image with System 6 plus the INIT installed, and/or the bare INIT file.
3. Devon transfers it to the real Plus once (route TBD, §6), boots, and tunes the margins.

---

## 2. Hardware inventory

### Machine A: Macintosh Plus (the target)
- Model **M0001A**, 68000 @ 7.83 MHz, 128K ROM. RAM is presumably the stock 1 MB (not yet confirmed).
- Internal **800K** double-sided floppy drive.
- Ports: DB-25 SCSI, DB-19 external floppy, 2× mini-DIN-8 serial (RS-422; the printer port does LocalTalk), DE-9 mouse.
- **Boots and runs System 6.0** from Devon's original Apple "Macintosh System Tools, Version 6.0" floppy, which is write-protected.
- External Apple 800K floppy drive also available.
- No hard drive, no BlueSCSI, no network hardware yet.

### Machine B: older compact Mac (parts donor / reference)
- Back label says model **M0001**: an original 128K or 512K case.
- Ports confirmed **original layout**: DE-9 mouse, DB-19 external floppy, 2× DE-9 serial, audio jack, **no SCSI**. So it has original 128K/512K internals, not a Plus upgrade. Whether it's 128K or 512K isn't confirmed yet (4164 RAM chips = 128K, 41256 = 512K).
- Has a 400K single-sided drive. It can't read the 800K disks and can't run System 6.
- Its picture size hasn't been checked yet. Its width coil (L2) and slug are the same part as the Plus's and are a candidate hardware swap (§3).

### Software on hand (original Apple floppies, all 800K double-sided, all labelled "CKV")
- Macintosh System Tools v6.0 (bootable; holds Installer, Apple HD SC Setup, Installer Scripts, System Folder; 776K used, 3K free)
- Macintosh Utilities Disk 1 & 2, v6.0
- Macintosh Printing Tools v6.0
- HyperCard Ideas
- A 1987 HyperCard disk (part 690-5116-C); probably the HyperCard app or stacks
- No ResEdit, compiler, terminal or network software on hand.

**These originals must never be erased or written to.** They're the only working boot media and the rescue disk.

---

## 3. Hardware diagnosis so far (why the software route)

How width works: the yoke's horizontal current sets the beam's swing. The **width coil L2** on the analog board is in series with the yoke. Its ferrite slug, turned with a hex tool, sets its inductance: slug deeper → more inductance → less yoke current → narrower picture. Bench data from another Plus board: L2 ≈ 12.1 µH with the slug out, ≈ 44.2 µH with it in. Apple's service manual spec for the picture is **7.0 in × 4.7 in** (a forum source quotes 7.11 × 4.47 for compact Macs generally), with a black border all round.

What Devon observed:
1. The slug turns and moves through the **entire travel within the winding** with **no visible effect on width**.
2. Inserting a **steel** hex driver into the coil narrowed the picture to the correct width, but it snapped back when the tool was removed. That's the tool acting as a core, not the slug moving.
3. So the coil carries current and responds to magnetic material, but the slug has lost its effect. Leading hypothesis: a **cracked ferrite slug**, or a non-ferrite replacement (brass/plastic). Untested: a fridge-magnet attraction test on the slug.
4. Not yet checked: the 12 V rail (spec 11.90–12.75 V; high voltage widens the picture) and capacitor C1 (a known failure part on Plus analog boards).
5. Untried cheap fix: move Machine B's L2 slug (or the whole L2 coil) into the Plus. The same coil is used on 128K-through-SE/30 analog boards.

Devon may still try the hardware fix. The INIT is the project regardless, so **design it so all margins can be set to 0** (a no-op) if the hardware later gets fixed.

Safety notes for anything physical: the Plus flyback may lack a bleeder resistor; the CRT holds about 9 kV; use plastic tools only on L2; work from behind with a mirror. Devon has the case open, so remind him to unplug when not testing.

---

## 4. Technical design notes for the INIT

The Plus's video hardware is fixed: 512×342, 1 bpp, frame buffer at a fixed address near the top of RAM. Software **cannot** shrink the physical raster. It can only keep content out of the hidden edge columns. The INIT must make the system *believe* the usable screen is a centred sub-rectangle.

Candidate things to change at boot. **Verify each in the emulator; these are leads, not confirmed answers:**
- **QuickDraw `screenBits.bounds`.** Each app's `InitGraf` sets this, so it can't simply be set once at INIT time. Likely approach: patch a trap (for example `InitGraf`, or a later hook) to inset `screenBits.bounds` after it's set, keeping `baseAddr`/`rowBytes` unchanged and offsetting appropriately. Keep in mind that bounds.left > 0 with the same baseAddr changes the coordinate mapping. Options: (a) keep the coordinate origin and just shrink right/left in the desktop and window limits, or (b) shift the origin. Prototype both.
- **`GrayRgn` (low-memory global 0x9EE):** the desktop region. Shrinking it keeps window dragging and the desktop pattern within bounds.
- **Cursor pin rectangle (`CrsrPin`, low-mem ≈ 0x834):** constrains the mouse.
- **Menu bar:** the Menu Manager draws across the full `screenBits` width. Making the Apple menu (leftmost) visible may need menus to start further right, which may mean patching `DrawMenuBar`/`InitMenus` or offsetting the menu bar's port.
- **Finder:** desktop icon placement (disk at top right, Trash at bottom right) is computed from screen bounds. Check where the Finder reads them.
- **Dialogs/alerts:** `DLOG`/`ALRT` centring uses `screenBits`. These should follow automatically if `screenBits` is right.
- Apps that hard-code 512×342 will still overflow. That's acceptable, so document it.

Look up the exact low-memory addresses and trap numbers in *Inside Macintosh* (Vols I–IV, and V for System 6 era) rather than trusting the numbers above.

INIT basics on System 6: file type `INIT`, creator anything, code resource type `INIT` (ID usually 0+), loaded by the INIT 31 mechanism from the System Folder at boot. Optionally show an icon at boot via the "ShowINIT" convention (nice for confirming it loaded). A `cdev` (Control Panel device) is a separate resource type in the same file. The INIT could read a small settings resource the `cdev` writes.

**Rescue path:** System 6 has **no** "hold Shift to disable extensions" (that's System 7). If the INIT hangs the boot, Devon boots from the locked System Tools floppy and deletes the INIT from the other volume. Make the INIT fail safe: on anything unexpected, do nothing. Optionally skip itself if a key (for example Shift or Caps Lock) is held at boot, implemented by reading the keymap.

---

## 5. Toolchain plan (agent-side)

Planned, but **not set up yet**:
- **Compiler: Retro68** (GCC-based 68k cross-compiler, github.com/autc04/Retro68). It runs on Linux/macOS, builds apps and code resources (INIT/cdev), and can output HFS disk images. Building the toolchain takes a while.
  - Alternative: THINK C 5 running inside the emulator (period-correct, but much harder to drive headlessly).
- **Emulator: Mini vMac** in Mac Plus mode (gryphel.com; source mirrors on GitHub). Run it headless under Xvfb, script input with xdotool or similar, take screenshots to verify. Draw an overlay of the "visible glass" region to check fit, because the emulator shows the full 512 px.
- **HFS image tools:** hfsutils (`hformat`, `hcopy`, `hmkdir`, `hattrib`) or Retro68's MakeImport/Rez outputs, plus `machfs` (Python) as another option.

**Inputs Devon must supply** (the agent can't download these):
1. A **Mac Plus ROM image** (128K, `vMac.ROM`). It's Apple-copyrighted; Devon needs one he's entitled to, for example dumped from his own Plus once he has a transfer route.
2. **System 6.0.x disk images.** Apple released System 6.0.8 for free download, but the agent's sandbox may not reach hosting sites (Macintosh Garden, WinWorld, Macintosh Repository), so Devon may need to attach them. Note: Devon's real Plus runs **6.0** (from his floppy). Targeting 6.0.8 is fine, but test that the INIT doesn't depend on 6.0.5+ features, or ask Devon to provide images of his own disks.
3. A **measurement** of how much is hidden on each side of the real screen, in pixels or as a fraction. Not provided yet. Default guess: ~20–30 px per side. A tunable `cdev` makes this less critical.

---

## 6. Getting files onto the real Plus (unresolved, Devon's side)

Devon wants a free route. Facts established:
- Modern USB floppy drives **can't** read or write the Mac 800K (GCR) format, and the Plus can't read 1.44 MB disks.
- Devon's blank disks are **1.44 MB HD**. The Plus's 800K drive has no density sensor, so it can erase HD disks as 800K directly. Drives that sense density (SuperDrive, PC drives) need the HD hole taped over. HD media at 800K is somewhat less reliable but fine for transfers.
- The Plus has **no Ethernet**. It has **LocalTalk** (AppleTalk over the printer port) and serial.

Candidate routes, roughly best to worst:
1. **SuperDrive Mac in Devon's psych-department shop** (SE FDHD, SE/30, Classic, LC, II-series). Modern Mac → 1.44 MB PC disk → SuperDrive Mac (Apple File Exchange / PC Exchange) → Disk Copy onto a taped HD disk as 800K → Plus. Free.
2. **LocalTalk bridge in the shop** (AsantéTalk, Farallon, PhoneNET) + **Netatalk 2.x** on a Linux box or Raspberry Pi as an AppleShare server; or **TashTalk** (cheap open-source LocalTalk adapter for a Pi). Best long-term, since the Plus mounts a shared volume. Check whether an AppleShare client is on Devon's System 6 disks.
3. **Greaseweazle** (~$25) + an internal PC 3.5" drive: writes Mac 800K images (`mac.800` format) from a modern computer onto taped HD disks.
4. **BlueSCSI v2 DB25** (~$30–60): SD-card SCSI hard drive. Best overall: put the built HFS image on the SD card and boot from it.
5. Serial cable + USB-serial adapter (XMODEM). Chicken-and-egg: the Plus needs a terminal app first.

Shape the deliverable to the route: an **800K HFS image** (fits a floppy; System Folder plus INIT should fit, perhaps with a trimmed System) for floppy routes, or a larger HFS hard-disk image for BlueSCSI. Ideally provide both, plus the bare INIT file.

---

## 7. Related artifacts from this session
- **"Width Coil Lab"**: an interactive Three.js explainer of the CRT, yoke and width coil (slug depth, slug material, steel tool, 12 V). Not part of the coding task; it's just for Devon's understanding.
- Apple Mac Plus Service Source manual (Adjustments section: voltage 11.90–12.75 V / 4.85–5.15 V; size 7 in × 4.7 in; yoke tilt and centering rings). Found at powerbuch.ch, but that link has been unreliable for Devon. Archive.org has "Service Guide Macintosh Computers Vol 1, 1993."

---

## 8. Suggested first steps for the agent
1. Confirm with Devon which transfer route he'll use (decides image size/format) and whether he can supply the ROM and System 6 images.
2. Build or install Retro68; build Mini vMac (Plus model); get a headless boot-and-screenshot loop working with a stock System 6 image.
3. Spike: a minimal INIT that only shows a boot icon. Confirm the build → image → boot → screenshot pipeline.
4. Experiment with insetting `GrayRgn`, `CrsrPin` and `screenBits` (via a trap patch) to find the minimal set of changes that pulls the Finder, menu bar and dialogs inward. Screenshot each.
5. Add the settings resource and `cdev` sliders; default margins from Devon's measurement.
6. Package the deliverables; write a short install/rescue README for Devon (drop into System Folder, restart; rescue = boot from the locked System Tools floppy).
