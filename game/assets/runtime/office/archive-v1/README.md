# Archive v1 — four reviewed standing-service views

Promoted locally on 2026-09-04 after independent source/native/4× review and canonical standing-service input, collision and headroom verification. Only this family is promoted; no workstation or other shared furniture direction is implied.

There are 24 exact native exports: `{north,east,south,west}-{carcass,top,front,plinth,insert,whole}.png`. Every file is byte-identical to its retained counterpart in `game/tests/fixtures/furniture-calibration/modular-archive-v1/`. All canvases are **192×288**, with floor pivot **(96,224)**. Imported RGBA, including zero-alpha padding, is checked against those exports. Lossless imports have no mipmaps, no size limit and no alpha-border filling.

The production catalogue renders Carcass, Top, Front, Plinth and Insert in that order at the same physical ground depth, with full-canvas region `[0,0,192,288]` and centered-sprite offset `[0,-80]`. Whole PNGs are retained as exact union/reference exports, not a substitute for the modular layers.

North/South floor footprint is 96×32; East/West exchanges the floor axes to 32×96. Vertical rise remains 64px. No source bitmap is rotated, mirrored or stretched. The independent panels show the rear, locker end, service front and display end respectively. The approach side and the standing visitor's opposite gaze are explicit service semantics, never invented seated-worker metadata.

The original `../artifact-archive.png` and its legacy flat profile fields remain intact for backward-compatibility checks. Normal placement remains South at grid `(4,13)`, unlocked with the first employee; physical South footprint, clearance and interaction cell are unchanged.

Provenance and acceptance evidence:

- [Generated-panel and native assembly review](../../../../../dev/art-catalogue/ARCHIVE_ASSEMBLY_REVIEW.md).
- [Canonical service/headroom integration](../../../../../dev/art-catalogue/CANONICAL_SERVICE_INTEGRATION.md).
- [Normal production-room verification](../../../../../dev/art-catalogue/ARCHIVE_PRODUCTION_REVIEW.md).
- [Exact-copy promotion script](../../../../../dev/tools/install_archive_runtime.sh).

The coordinator accepted bounded visual scores 3/3/2/3/2/2. Dark end faces and substantial natural occlusion behind the tall North cabinet are documented nonblocking polish limits. No door-use animation or new backend functionality is claimed. The source masters, failed attempts and calibration exports remain preserved outside this runtime directory.
