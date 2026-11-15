# Verification record

Date: November 15, 2026. Source: `zhast/startup-valley` at `c4d1829df5ce2924ef68964bf16b7c1c369e0e46`.

## Completed

| Area | Result |
| --- | --- |
| Source checkout | Shallow, runtime-focused sparse clone; required concept sheet and import sidecar retained |
| Source status after harness tests | Clean; no tracked game changes |
| Engine release research | Existing 4.7.2 pin is the latest stable; 4.8 is beta |
| Web scaffold tests | 23 passed, 0 failed, including after relocation into the repository |
| Loading-shell browser checks | Desktop, mobile portrait, and mobile landscape passed; no page errors or horizontal overflow |
| Native harness dependencies | Exact committed package lock installed; original lock preserved |
| Native TypeScript build | Passed |
| Native harness tests | 136 total: 134 passed, 0 failed, 2 skipped pending Godot binary |
| Offline evaluation | 8/8 fixtures, 27 checks passed |
| Asset audit | 804 PNGs/imports checked; no blocking raster defect found; only two stale asset-guide entries corrected |
| Native Godot import | Exit 0; 2,124 assets imported |
| Native project validator | Passed: runtime scenes, art, and all modular office stages valid |
| Native main Godot suite | Passed: test_worker_walks_to_desk and remaining assertions |
| Git setup | All web groundwork moved into the repository on local branch `codex/web-port-scaffold`; original README preserved |
| Real Godot startup integration | Passed separately with the verified Godot binary |
| Real Godot furnishing integration | Failed at opening Settings with Escape, cascading into Renovate assertions; worker bootstrap and SQLite snapshot succeeded |

Harness tests used Node 24.22.1, which satisfies the repository's Node 22.19+ requirement. Host credentials were ignored and no paid-provider checks ran. The two skipped cases exercise real Godot furnishing input and production startup.

Logs from this session:

- `/private/tmp/startup-valley-native-tests.log`
- `/private/tmp/startup-valley-offline-eval.log`
- Shell captures: `/private/tmp/startup-valley-shell-desktop.png`, `/private/tmp/startup-valley-shell-mobile.png`, `/private/tmp/startup-valley-shell-mobile-landscape.png`

## In progress

The browser runtime and real browser playtest are now in implementation. The native furnishing input failure above was observed before changing gameplay code and remains an explicit issue to investigate. The asset review is complete; see [the illustrated audit](asset-audit.md).

Godot 4.7.2 was downloaded from the official release and verified against SHA256 and SHA512 checksums. Its temporary executable is `/private/tmp/startup-valley-godot-4.7.2/Godot.app/Contents/MacOS/Godot`. The initial restricted-sandbox runs emitted startup errors accessing default user-data and macOS certificate locations; there were no script/import/assertion failures. Full logs are in `/private/tmp/startup-valley-native-checks/`.

## Not claimed

No browser Worker/SQLite port or playable browser game has been implemented. A real Godot web export, browser simulation parity, and durable browser saves are not verified by the web scaffold or native harness tests.
