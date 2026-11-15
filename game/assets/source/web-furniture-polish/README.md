# Reviewed phone-booth camera correction

`phone-booth-south.png` is the reviewed, already normalized native source for
`game/assets/runtime/office/phone-booth-south.png`. Install it by copying the file
byte-for-byte; do not rotate, stretch or rescale it at runtime.

The built-in OpenAI image tool generated the camera correction on 2026-11-15.
The original booth and current desk/archive/room were supplied as references.
The selected result removes the prominent left side and centers the front.
It was uniformly normalized to 175 pixels high, then mapped to the original
booth's 14-color palette and binary alpha. Its 96×175 painted envelope fits
inside the existing 111×175 catalog envelope. The 192×224 canvas, bottom-center
contact at (96,216), scene offset, occupancy, clearance and depth stay unchanged.

[Prompt](../../../../docs/web/assets/asset-audit/prompts/phone-booth-camera-v1.md) ·
[Native room comparison](../../../../docs/web/assets/asset-audit/phone-booth-native-comparison.png) ·
[Audit](../../../../docs/web/asset-audit.md)

The original generated output is `exec-1026ae07-ab01-4590-8926-9dd59e41784f.png`
in built-in generation session `01a1e141-b332-7001-8b53-6317a3b8a502`.
`manifest.json` records the normalization and immutable runtime contract.
