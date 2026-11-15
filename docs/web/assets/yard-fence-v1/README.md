# Approved connected boundary

The current boundary is visually approved in exported Godot build
`d23a483542544696`, with runtime fingerprint
`5e8afa18aa826a0883d0af6506aa47c96e9d405c7766fe86befe7d474c882ebd`.
See the [actual in-app frame manifest](../world-final/capture-manifest.json)
and [independent image/geometry review](independent-review/README.md).

The previous in-app courtyard looked porous despite its bounded movement.
`rejected-porous-boundary.jpg` preserves that rejected pre-fence iteration.

Current production `YardFence` derives 82 exposed edges from the unchanged
373-cell courtyard floor, then omits exactly two edges at the existing Studio
return path (x480–544, south y640). It draws 80 rails and 81 posts, including both
gate terminals, with no post in the opening. Its 32px connections use one generated
post, paired horizontal rails and a separately generated north–south rail.
It does not add collision, navigation, worker state or travel behavior.

`headless-results.json` records 752 passing checks: exact permitted gate omissions,
terminal connections, binding to the existing return interaction, all 15
cardinal connection masks using real source alpha, a disconnected-rail negative
control, native registration, depth, and unchanged northwest path. `routes.json`
records 9 passing actual component movement checks. The exact source/report
hashes are retained in `source-manifest.json`.

`rejected-sealed-fence.jpg` preserves the next in-app iteration: its joins and
style were accepted, but its continuous south fence incorrectly enclosed the
functional return sign. The declared opening resolves that specific issue;
the current front/northwest in-app frames show the two-cell gap, both terminal
posts and coherent foreground/rear depth, and are bound by the approved review.

The reports in this directory provide mechanical evidence; current approval
also uses the actual exported-Godot in-app frames. The independent review
verifies that the seven-file delta adds visual fence composition and gate
metadata only: movement, worker state, props and interaction coordinates are
unchanged. Its 17 map tests and 9 routes pass alongside the 752 fence checks.
All three current map reviews and both new atlas reviews are approved.

No windowed Godot test or new native capture was used. The parent performed
live browser checks; the independent agent reviewed the supplied static
images. This is not a new three-journey run or blanket animation approval.
The rejected porous and sealed variants remain historical evidence.
