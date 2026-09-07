# Mina North mount — targeted retry2: alpha extraction

Completed09:24UTC, `exec-8464908d-30ce-49be-8b60-6576edcf3832.png`. V2 stillRGB; genuinealpha needed for meaningful nativeassembly.
Initial+two targetedattempts including thiscall. No productionapproval.

Result still opaque checkerboard; no native export or false matte recovery.

Use case: background-extraction.
Edit ONLY background/transparency of this eight-cell Mina sprite sheet. Remove
every white/lightgrey checkerboard square between and around the figures and
inside true exterior gaps. Output a PNG with GENUINE TRANSPARENT ALPHA, alpha0
outside the character pixels. Do not draw another checkerboard, solidcolor,
paper, shadow or background. Preserve all eight character drawings exactly:
identity,outfit,bag,bun,pose,colors,pixel edges,positions,sizes,cellspacing and
canvasdimensions. Do not redraw,recenter,resize,add a chair or correct anatomy.
No blur,softmatte,whitehalo,text,frames,labels or new objects. All eight separate
complete sprites should remain at the exact same coordinates, with actual
transparent pixels wherever the painted checkerboard used to be.
