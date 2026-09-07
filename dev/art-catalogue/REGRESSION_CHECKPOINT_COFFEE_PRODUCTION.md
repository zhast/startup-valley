# Regression checkpoint: coffee-station-v1 production

Captured 2026-09-04 20:12 UTC after the accepted code-native coffee station was
copied into the runtime tree and registered in the production furniture
catalogue. This checkpoint covers the promotion boundary; it does not reopen
the candidate art decision or authorize interactive coffee behavior.

## Locked facts

- Runtime directory: `game/assets/runtime/office/coffee-station-v1/`.
- Reviewed source: `game/tests/fixtures/furniture-calibration/coffee-station-code-v1/`.
- 40 registered semantic layers plus four whole references; all runtime bytes
  equal the reviewed source bytes and match the runtime manifest hashes.
- N/E/S/W use canvas `(192,256)`, pivot `(96,192)`, offset `(0,-64)`, scale1,
  rotation0, no flips, and side-specific far-to-near render order.
- The active production catalogue admits all four profiles without a
  calibration permit and keeps `interaction_enabled` false.
- The legacy South PNG is retained as historical/recovery evidence only; it is
  not substituted into any new facing.

## Commands and results

Using `STARTUP_VALLEY_NO_WORKER=1` and Godot 4.7.2:

```text
--headless --path game --import
PASS

--headless --path game --script res://tools/validate_project.gd
PASS: runtime scenes, art, and all modular office stages are valid

--headless --fixed-fps 30 --path game --script res://tests/test_coffee_station_production.gd
Coffee station production: 409 checks, 0 failures; interaction intentionally disabled.

--headless --fixed-fps 30 --path game --script res://tests/test_furniture_directions.gd
Furniture direction tests: 429 checks, 0 failures.

--headless --fixed-fps 30 --path game --script res://tests/test_archive_production.gd
Archive production: 3297 checks, 0 failures, 0 captures, 2900 actual physics ticks.

--headless --fixed-fps 30 --path game --script res://tests/test_service_furniture.gd
Service furniture: 2675 checks, 0 failures, 0 captures, 1184 actual physics ticks.
```

Catalogue validation and deterministic gallery/HTML results are recorded in
the current run log after the concurrent production-truth reconciliation. The
[production review](COFFEE_STATION_PRODUCTION_REVIEW.md) is the authoritative
scope and acceptance note for this checkpoint.
