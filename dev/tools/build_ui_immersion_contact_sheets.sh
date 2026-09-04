#!/bin/sh
# Navigation indexes only; acceptance is performed on native 1280x720 PNGs.
set -eu
project_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)
font_path="$project_root/game/assets/fonts/nunito-sans/NunitoSans-Variable.ttf"
for suite in ui-material-specimen ui-material-audit-after ui-material-audit-after-shell; do
  evidence="$project_root/game/tests/output/$suite"
  test -f "$evidence/manifest.json"
  # Read only manifest-owned captures, excluding previous contact sheets.
  /opt/homebrew/bin/node -e '
    const fs = require("fs"), cp = require("child_process"), path = require("path");
    const folder = process.argv[1], font = process.argv[2];
    const manifest = JSON.parse(fs.readFileSync(path.join(folder, "manifest.json"), "utf8"));
    const images = manifest.captures.map(c => path.join(folder, (typeof c === "string" ? c : c.name) + ".png"));
    cp.execFileSync("magick", ["montage", ...images, "-filter", "point", "-thumbnail", "640x360", "-tile", "2x", "-geometry", "+12+28", "-background", "#151515", "-fill", "#f1f1f1", "-font", font, "-pointsize", "16", "-set", "label", "%t", path.join(folder, "contact-sheet.png")]);
  ' "$evidence" "$font_path"
done
