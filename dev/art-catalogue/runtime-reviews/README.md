# Current runtime reviews

Put hash-bound review JSON here after inspecting a candidate in the game.
Use the [asset workflow](../../../docs/ASSET_WORKFLOW.md), not a copied approval.

Create an unsigned candidate with:

```sh
node scripts/validate-assets.mjs --candidate game/assets/runtime/path.png > dev/art-catalogue/runtime-reviews/my-asset-v2.json
```

The command records only the current artifact hashes. It does not approve the
art, regenerate the baseline, or invent provenance. Complete the real source,
binding, screenshot, test-report and review records before changing `status`
to `approved`. An `approved` record with stale evidence fails the gate.

Keep evidence outside ignored `game/tests/output/`: copy only the small,
inspected acceptance set to a tracked path such as `docs/web/assets/…`.
The full generated capture folder stays local.
