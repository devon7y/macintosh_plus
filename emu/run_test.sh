#!/bin/zsh
# Headless MAME run: run_test.sh <disk.dc42> <script.lua> [seconds]
E=${0:A:h}
export EMU=$E
exec mame macplus -bios v3 -ramsize 1M -rompath "$E/roms" -flop1 "$1" \
  -homepath "$E/mame" -cfg_directory "$E/mame/cfg" -nvram_directory "$E/mame/nvram" -diff_directory "$E/mame/diff" \
  -snapshot_directory "$E/shots" -video none -sound none -nothrottle -skip_gameinfo \
  -seconds_to_run ${3:-120} -autoboot_script "$2" 2>&1 | grep -v -E "^Average speed|seconds_to_run"
