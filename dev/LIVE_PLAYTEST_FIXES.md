# Live-playtest production fixes

Status: **accepted for the tested internal-MVP route** on 3 September 2026.
The paid journey completes with normal quality-gated rewards, a successful
revision, working approvals/cancellation, and durable restart recovery. No known
reproducible blocker remains in this route after the final targeted regression
and visual checks. This is bounded playtest evidence, not a guarantee that every
possible input, platform or future AI-generated artifact is bug-free.

Acceptance is the route in LIVE_PLAYTEST_2026-09-03.md on the production game,
with a fresh isolated company, real AI, normal quality-gated rewards and a
successful revision. No launch-only copy or founder overrides. Keep all twenty
findings in scope; tests alone do not establish visual/live readiness.

| Findings | Work | Evidence / status |
| --- | --- | --- |
| L01 | Typed founder-only startup | Real-worker disposable startup regression passed; native capture 01 |
| L02 | Distinct first run; no premature save notification | Native captures 01–04; distinct Start Company and meet-team onboarding |
| L03 | Explicit chat-to-deliverable and milestone selection | Native ordinary brief, distinct Journey binding, A10/A17; both dispatch correctly |
| L04–L07, L10 | Chat, file widths, modal layers, Activity, code reader | Native chat, delivery, Studio and reader; 42 preserves CSS source; 104 fits delivery actions |
| L08–L09 | Representative evaluator evidence; honest static website | Paid website 2.75/3, ads 3/3, incorporation 3/3; no overrides |
| L11 | Bounded revisions and retained-work recovery | Paid website revision completed; immutable originals and editable copies verified; 12k/24k selector |
| L12 | Refresh Journey on lifecycle transitions | Native preparation, evaluation, revision, reward and chapter states; no stale actions |
| L13–L14 | Current-job attention; restore without toast replay | Per-job cached views; terminal state precedes old deliveries; hydration tests pass |
| L15 | Office/day guidance and meaningful next actions | Native first-hire guidance, physical desk/archive/console interactions, next-milestone guidance and early End Day explanation; unaided-player enjoyment/pacing still requires user research |
| L16–L17 | Distinct Studio/delivery; explicit draft binding | Activity history owns scratch; Studio remains approved files; accepted draft clears bindings; rejected form retained; tests pass |
| L18 | Approval remains running/pending until real decision | Native 74/77/78; SQLite remains running/pending, then approved exactly once |
| L19–L20 | Activity cancellation; final component coherence | Native 86/87 cancellation; 96/99 Settings/fullscreen; all 27 static states recaptured |

## Completed playtest evidence

`game/tests/output/fix-playtest-20260903/` contains production native captures,
logs, a disposable company and its Node launcher. The original company remains
untouched. Native replay now includes first hire, floor movement, physical
employee approach, real chat, a completed direction brief, promotion and reading,
a deliberately CTA-free website followed by a successful paid revision, the full
$600/10-reputation reward, Theo's single $300 hire, and Day 2's ad plan with live
steering. Ads and incorporation both passed 3/3. Capture 71 shows chapter
completion with full rewards. Native approval and cancellation then passed;
105 confirms exact restored chapter state: $1,000 cash, $1,800 gross earnings,
45 reputation, two hires, no overrides and five unique economy transactions.
A second, untouched `acceptance-company/` repeated the chapter on production
source with real AI and no overrides: A65 confirms the same full-reward totals.
Its revision received 2.75/3, ads and incorporation both received 3/3. Approval
and cancellation also passed (A69–A74). A79–A80 verify restart at Day 3 09:51
with founder feet `(176,504)`, saved settings, all seven Studio files, unchanged
finances, six completed jobs, one cancelled job and five unique economy entries.
There were no replayed delivery toasts. A89 reconfirms the completed chapter.
The final native acceptance restart was saved and closed normally with exit code
0; its final console output contained no errors or leaked-object warnings.

During this replay, removing the old oversized chat minimum exposed a pre-existing
container sizing dependency: the content collapsed to a small upper-left block
(capture 07). Fixed by giving the 1280×720 composition an explicit 368×720 drawer
content size and refitting after wrapped text's provisional minimum settles.
Capture 09 shows the repaired drawer. `test_ui_flow_regressions.gd` now asserts
the actual reading viewport dimensions, not merely that controls exist.
Godot's [Control layout documentation](https://docs.godotengine.org/en/stable/classes/class_control.html)
describes the distinction between anchors, offsets and minimum-size presets.

The native draft also exposed redundant selectors and excessive controls. The
latest source uses one purpose picker and a sticky Start footer (capture 16).
Body copy now uses an explicit Nunito
Sans weight resource; source files are read without Markdown reinterpretation.

## Additional regressions found during the paid replay

- Capture 20: inline Markdown inside list items was not parsed. Apply emphasis
  before block formatting, while keeping fenced code literal; regression added.
- Capture 25: Mina's contextual plaque briefly hid the approaching founder.
  Label arbitration now reserves actor silhouettes; real-input regression added.
- Capture 29: the review correctly detected the deliberately missing CTA, but
  falsely reported mismatched CSS. The evidence compactor had removed HTML
  classes. Preserve classes; the revised production review (37) correctly scored
  page structure 3/3. Website revision passed 2.75/3 using 1,976 review tokens.
- Capture 31: themed scrollbars overlaid the right edge of Journey prose.
  Godot reserves `get_minimum_size()`, not the scrollbar's custom minimum. Give
  track/thumb styles their authored 15 px / 14 px theme minimum. The added
  long-review layout assertion now passes. See [Godot ScrollContainer source](https://github.com/godotengine/godot/blob/master/scene/gui/scroll_container.cpp).
- Review-in-progress now labels the clicked card and button, not only a notice
  below the fold (36). Journey reopens at its heading; updates retain position.
- Duplicate work titles now receive sequence numbers in Activity history.
  Day summaries label revisions. Day end closes prior documents/drawers so the
  next day returns to the office rather than a stale screen.
- Capture 40: shortened `finding a seat` to `to seat` to fit its plaque.
- Capture 54: the rail updated on delivery while the Chat header briefly said
  available. Header and rail now refresh together. Removed redundant attention
  badges when the normal status icon already communicates the same condition.
- Captures 66–67: a movement-key tap between physics frames did not cancel a
  click route. Cancel at the input event, not only in the next physics tick.
  Captures 81–82 and a same-frame press/release regression verify this.
- Captures 75–76: Mina could block the narrow research exit and oscillate forever.
  Add safe passage requests, a net-progress watchdog and footprint-checked
  separation. Never choose a yield path through the requesting founder. Captures
  85–86 show Mina stepping aside and the founder reaching the approval console.
  The console now selects the employee who actually owns the pending decision,
  even when another employee was selected in the rail.
- Captures 79/91: side-by-side delivery actions widened the drawer and clipped
  its close button. Stack the actions inside the authored width. Capture 104 and
  the actual-container-width assertion verify the fix.
- Historical work usage disappeared after restart. Bootstrap now includes the
  existing persisted token/cost fields; capture 102 and a reopen regression
  verify them. Plain status summaries strip Markdown markers; accepting approval
  immediately replaces the stale decision-needed text.
- The looping ambient sound left two audio objects at shutdown. Stop playback
  before the normal save/quit sequence and allow the mixer to retire it. Native
  `live6.log` and `live7.log` end cleanly without leaked-object warnings. Dev-only
  capture teardown now follows the same retirement order.
- A75 exposed a separate label path: the high-priority `E · CHAT` prompt itself
  could cover the founder when standing beside Mina. Its placement now tests
  candidate positions against every actor silhouette. Twelve close-quarters and
  viewport-edge arrangements pass the new regression, and fresh static captures
  show a clear prompt. Native A87–A88 verify unobstructed placement and a working
  click target after restart. The keyboard interaction remains usable if a crowded
  layout leaves no safe place for a visible prompt.
- Capture fixtures now include the accepted-submission and queued events that
  real production receives, plus explicit work titles and daily spend. This
  removes misleading empty history pickers, missing cancel controls and stale
  submitting text from audit-only screenshots. No worker behavior was changed.

Native paid evidence: ordinary brief `job-866bac1-fc215ae1`; first website
`job-d441996-43c579`; successful revision `job-283c97f-c44678c5`; ads
`job-1052cf82-3276b9b8`. Capture 38 and SQLite show one website reward despite
double click; 39/45 show one Theo charge and the saved Day 1 summary. No overrides.
The first website's missing CTA was an intentional test input, not an application
failure; the class-stripping false finding was an application failure and is fixed.

Passing checks: worker build; **50/50 worker tests** with real-worker Godot startup
enabled, zero skips; **8/8 offline evaluator fixtures**; Godot import,
project validation, gameplay suite, real-input framework suite and UI-flow
regressions. Final static review contains 27 isolated states. Both fixed-30-FPS
motion suites contain six scenarios with validated distinct frames, endpoints,
contact sheets, native texture inventory and an empty known-flags list. Final
capture teardown exits without errors or leaked-object warnings.

## Second paid replay

| Work | Production job ID | Outcome |
| --- | --- | --- |
| Chat-derived ordinary brief | `job-5569a24-789b2be7` | Completed; promoted and read |
| Deliberately CTA-free website | `job-a52bf14-e3d499a0` | Correctly requested revision: CTA 1/3, other criteria 3/3 |
| Website revision | `job-e40dfc9-12f6301d` | 2.75/3; full reward, two files promoted |
| Ads | `job-1cfab012-38ebf43c` | 3/3; live steering incorporated, full reward |
| Incorporation planning | `job-22cdfc75-38f71ae0` | 3/3; one filing fee and full reputation |
| Approval memo | `job-2781c74a-7e7e52c8` | Running/pending → approved → completed with `approval-test.md` |
| Cancellation check | `job-2ae9b16b-1ef5b9f2` | Running/pending → cancelled; approval released, zero artifacts |

The second replay cost **$0.07079475** as recorded by the worker: $0.060486 work,
$0.000663 chat and $0.00964575 evaluation. The earlier corrective replay cost
$0.0720234. These totals are usage records, not reconciled provider invoices.

Evidence `A01`–`A90` is under the same output root, separate from the first
corrective replay's numbered captures. Some native-tool captures were stale or
thumbnail-sized during window-selection failures. The game process continued
and the worker persisted actions; reacquiring the window through its native
fullscreen control restored capture/input. A37–A40 are diagnostic transition
captures, not accepted layout references. A41–A43 show the settled, correct
fullscreen and restored windowed composition. No engine/application crash was
observed; process sampling showed the main event loop running.

The last prompt-overlap correction was made after the paid chapter completed;
its targeted input/layout regressions and final recaptures were rerun. It does
not alter the paid work, economy, evaluation or persistence paths.

## Verified acceptance coverage

- Worker build/tests/offline evaluator; Godot import/validation/gameplay/real-input.
- Static + motion recaptures and 100%-scale native inspection.
- Normal startup, founder/Mina/website/revision/full reward/Theo/ads/incorporation.
- Promotion, Studio, guarded document reading, steering, approval, cancellation.
- Rapid clicks, modal focus/Escape, settings, aspect-preserved fullscreen.
- Restart exact state; no duplicate rewards/charges or stale attention.
- Document newly discovered regressions and close them before acceptance.

The visual review examined the 27 static states and the twelve motion-scenario
contact sheets; the harness additionally validates motion markers and expected
endpoints. It does not measure end-to-end native input latency or prove every
movie frame is visually perfect. The native replay exercised actual mouse,
keyboard, dropdown, focus, modal and physical-station interactions separately.

## Remaining product research, not a blocked playthrough

- Have an unfamiliar player try the chapter without a walkthrough. Scripted
  testing cannot establish whether the office loop is fun or its pacing feels
  natural. Early End Day is deliberately supported and explained, not padded
  with forced waiting.
- A rendered website preview would make reviewing generated sites friendlier.
  The current reader correctly displays guarded HTML/CSS source; it is not a
  browser and does not pretend to render a live website.
- Capture-tool window/clipboard timeouts are recorded above. Fullscreen/windowed
  layouts were inspected after settling; transient/stale tool images are not
  treated as proof of a rendering failure or silently counted as passing frames.

No live ads, payments, publishing or incorporation filing occurred. The normal
user company was not modified. All paid work used disposable audit companies
with the existing constrained worker and keychain credential. No asset-generation
batch, provider change or production dependency was added for these fixes.
