# Mina North: head-scale re-export feasibility

2026-09-04. Read-only assessment; no export, new image request, socket change or production edit.

**Recommendation: do not treat uniform rescaling as a likely endpoint fix.** Measured standing and seated head envelopes already substantially match. The obvious difference is the source's long rear hair/back and compressed lower anatomy, not a uniformly enlarged head that can safely define a substantially smaller global scale.

Inspected the retained true-alpha `characters/mira-north-v2.png` master, its original builder and native six-frame atlas, the current native locomotion sheet, and the [actual standing/seated identity pair](../../game/tests/output/mina-north-mount-reference/identity-standing-seated-4x.png). Measurements below are exact alpha>127 bounding rectangles in native48×80 cells; the crop windows are explicit silhouette proxies, **not a claim of recovered anatomical head segmentation**.

| Native measurement | North standing idles0–1 | North seated/typing0–5 |
|---|---|---|
| Whole opaque body | `(10,4,29,67)` | Idle`(10,4,29,68)`; typing33–35px wide,68px tall |
| Existing export's upper28px head-registration window | `(12,4,25,24)` | Five frames`(12,4,25,24)`; frame5`(11,4,26,24)` |
| Upper13px bun silhouette window | `(18,4,13,9)` | Four frames`(17,4,14,9)`; frames3/5`(17,4,15,9)` |

The standing body actually has67 opaque rows after its native export, while the work atlas has68; “both68px” describes normalization targets, not an exact opaque-height equality. The upper registration window is already25×24 in both sources. Even the slightly wider seated bun is14–15px rather than13px, with the same9px height. Scaling all six to match only one bun width would create a conflicting vertical/head-width target and cannot consistently remove its one-pixel per-frame width variation.

The builder's current shared source-height factor is68/514≈0.13230 (`build_mira_north_calibration.sh:13–19,32–43`). An illustrative13/14 bun-width ratio gives a63px body, but shrinks the already-matching25×24 upper head envelope to roughly23×22. It also shortens the already-compressed leg segment and reduces hand span. This is a trade-off, not a justified head-scale correction. A stronger56px-body shrink would be especially unsupported by these measured heads.

Changing registration cannot repair those ratios. With a head-anchored normalization, the inferred hip moves upward in the cell; with bottom anchoring, it moves differently. In either case, deriving the socket as `seat_y + 72 - hip_row` can put the measured hip back on the candidate chair plane, **but cannot restore missing satchel/strap detail or independently correct hair/leg lengths and hand-to-hip reach**. The current North seat surface is itself inferred and hidden by the whole backrest, so it is not an independently proven target for a new socket.

Existing [North contact evidence](NORTH_MONITOR_SOCKET_REVIEW.md) already has marginal/incomplete hand samples (Mina7/16,6/12,8/11,8/16 typing samples over the keybed). Uniformly shrinking the source while matching the same hip surface reduces vertical and horizontal hand reach; no mechanical change can be certified from a more compact whole-body silhouette alone.

A small independently labeled scale study is technically possible and source-preserving, but these measurements do **not** make it the highest-confidence next fix. The standing reference should remain identity authority; the current North endpoint needs an anatomically consistent source and/or verified chair contact, not a disguised per-pose fit. Do not reset the exhausted mount-generation retry bound, alter frozen studies, or enable this endpoint based on a normalized-height comparison. No new candidate was produced by this assessment.
