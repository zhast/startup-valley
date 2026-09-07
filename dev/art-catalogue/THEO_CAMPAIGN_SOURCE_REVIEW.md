# Theo campaign kit source review

Date: September 4, 2026\
Family: `theo_campaign_kit`\
Attempt: `theo-campaign-fourway-v1`

## Requested contract

- Four independently authored N/E/S/W desk-surface groups in a strict 2×2 sheet.
- Campaign cards, audience notes and a generic creative-thumbnail sheet only.
- No desk, actor, UI, logos, performance claims or readable text.
- True transparent RGBA with separated objects and native-pixel cleanup potential.

## Measured result

- Source: `game/assets/source/overnight-20260904/roles/theo-campaign-fourway-v1.png`
- Size: 1254×1254.
- PNG type: TrueColor RGB (`IHDR` color type 2), with no alpha channel.
- SHA-256: `80a576c1a441fbf22c0fc6690fd81e8d837857a387ddfe33b447dc9a438b6e2b`.
- The visible checkerboard is painted into the source.
- Layout contains six object groups in each row instead of four directional cells.
- Several marks read as tiny lines/text rather than stable game-scale iconography.

## Disposition

**Rejected.** Do not threshold, crop, normalize, index as a directional
deliverable, or place in the game. The source and prompt note remain only as
generation provenance. Repeating the same broad transparent-sheet request is
not justified after the existing research-pose and this role-kit failure mode;
the next attempt should be deterministic native construction or one isolated
object/direction with a separately proven alpha path.

Catalogue consequence of this source: none. The rejected master remains
source-only provenance and was not used for a native export. A later, separately
constructed deterministic candidate now supplies N/E/S/W layers at
`native_review_required`; that registration does not rehabilitate this source,
approve the art or create a runtime binding.
