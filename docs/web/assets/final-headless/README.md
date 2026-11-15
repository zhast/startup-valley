# Final-copy headless acceptance

The current runtime passes **914 checks across26 phases**, covering three clean journeys plus New Company/reset restart. Runtime fingerprint before and after every phase group: `f06f9176745b08fd17ed36b2302f6251789249e8e23ad17e6c549a67092ac3f9`. No runtime files changed during the rerun.

- Run1: 1280×720, pointer, 279 checks.
- Run2: 1440×900, keyboard, 300 checks.
- Run3: 1024×576, pointer, 335 checks.

The clean sequence uses actual engine input with production GameMain and a real production Node worker: Start, movement, Settings/Escape, hire Mina, start project, live working/day progression, first release, courtyard travel, northwest save/reload, Theo's opportunity, return, and a real matching next project. Each milestone restarts the game and compares saved company, product, hires, inventory, story and player position. The third run also performs New Company through the UI and restarts its reset state. Every accepted phase reports headless display, zero screenshots, no failures and a distinct worker process that exits after ordinary shutdown.

Keyboard mode means Tab/Space in dialogs and Escape for Settings, with pointer input for unfocused world affordances. It is not a keyboard-only claim. Engine window sizes are exercised around the normal1280×720 logical viewport. This is functional/integrity acceptance, not visual or browser approval.

## Earlier evidence retained separately

The touch and compatibility folders are **previous-runtime evidence before one welcome-copy change**. They are not claimed as reruns on the new hash. They total109 checks over5 phases: touch16, legacy29, expansion64. The touch test covers844×390 guidance consuming input, then supported-size touch Start and Mina objective. Legacy and expansion use explicitly labeled disposable seeded fixtures; they do not count toward clean journeys.

Previous fingerprint: `4b0a5102524cad47cd1e809bfa79e614d5516b1b441919a0f1aa63b5b85bbc3e`. Exactly one file differs: `game/ui/company_panel.gd`. The final change says “Let’s make our next idea” for a later hire when release history exists; first-hire wording is unchanged. See `runtime-delta.json` for both exact file hashes and `prior-runtime-manifest.json` for the full earlier inventory. A later runtime change requires separately stated evidence; this folder certifies only the hashes recorded here.

## Reproduction

Godot4.7.2, Nodev24.22.1. From the repository, use an unused output path:

```sh
GODOT_BINARY=/private/tmp/startup-valley-godot-4.7.2/Godot.app/Contents/MacOS/Godot GIT_BIN='/Applications/GitHub Desktop.app/Contents/Resources/app/git/bin/git' /Users/openai/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node scripts/test-demo-godot.mjs --runs=3 --reset-check --output=/private/tmp/startup-valley-final-headless-three-copyfix
```

The runner defaults to `--headless`; do not add `--render`. It strips provider keys, ignores host credentials, disables fake-provider mode and refuses reused save directories. The actual production worker owns all gameplay mutations.

Recorded source commit before: `62f4be34ccb9c0bb75c48cceb4b5bf71a485eef0`; after: `75618b0553a9d998a42eccbd15944c2147c6bca7`; Git metadata unchanged: false. Runtime inventory unchanged: true. Final test-file hashes are in `summary.json`. Any Git metadata difference is kept distinct from the stronger runtime-content comparison.

Only the previously documented test-fixture corrections were needed: remove migration19's table when constructing the pre-17 schema; expect the intentional one-time geometry revision increment; retain Godot's JSON number type for exact comparisons. No production bug was found or production file edited by this QA run. The earlier failed fixtures remain outside the accepted folders. No windowed process was launched.
