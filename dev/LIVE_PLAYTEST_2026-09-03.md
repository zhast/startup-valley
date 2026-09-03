# Live playtest — 3 September 2026

> Historical pre-fix audit. See [production fixes and acceptance](LIVE_PLAYTEST_FIXES.md)
> for the subsequent repairs and successful paid replays. The findings below
> preserve what was observed in the original build.

Status: completed. Live play took place approximately 13:23–13:41 PDT. Real
OpenRouter calls were authorized by the user. No production fixes were applied.

## Verdict

**Not ready for an unaided player yet.** The original build cannot finish startup.
With one launch-only correction in an isolated copy, the real employee work,
company economy and save loop function, but the evaluator makes normal milestone
completion unreliable. All four live reviews requested revisions and explicitly
cited incomplete/truncated evidence. The chapter was completed using its supported
founder-override path, not by passing the quality gate.

This audit records **20 bugs and UX/polish findings**: two P0 blockers, fifteen P1
correctness/usability issues, and three P2 polish/pacing issues. Prior deterministic
test passes did not establish normal live-launch or live-evaluator readiness.

Recorded AI cost was **$0.08777205** (about nine cents): eight work orders, one chat
exchange and four evaluations. Six jobs completed, one revision hit its token cap,
and one cancellation test was intentionally cancelled. An additional custom
assignment was rejected before a job was created. These are worker-recorded costs,
not an independently reconciled OpenRouter invoice.

## Method and isolation

- Normal Godot game, real mouse/keyboard via computer-use, existing keychain
  credential, production worker and SQLite. Fictional company: DeskBloom,
  $19/month easy-care desk plants for remote workers; waitlist-stage, no customers.
- Save redirected through an audit-only Node launcher to
  `game/tests/output/live-playtest-20260903/company/`. The user's normal company
  database and files are not touched.
- Initial unmodified launch failed before the worker started. To continue, a
  diagnostic game copy at `/private/tmp/startup-valley-playtest.hMinOd/game`
  replaces the untyped empty-array branch in `GameMain._ready` with an explicitly
  initialized `Array[EmployeeRecord]`. No other game/worker behavior is changed.
  All subsequent observations are conditional on this launch workaround.
- Evidence PNGs and logs: `game/tests/output/live-playtest-20260903/`.
- Native Retina capture at the initial 1280×720 pixel window was 640 points wide.
  Subsequent play used a 2560×1440 pixel window (1280×720 logical composition,
  plus the native title bar in screenshots). No production resolution changes.

## Confirmed findings

P0 blocks the advertised play path; P1 materially breaks or confuses interaction;
P2 is polish or pacing. Screenshot names are relative to the evidence directory.

| ID | Priority | Finding and impact | Evidence |
| --- | --- | --- | --- |
| L01 | P0 | Normal launch throws `Invalid type in function _spawn_employees`; title, worker and company flow never initialize. Worker-disabled tests take the other branch and miss it. | `01-launch-blocked.png`, `game.log`; `game/world/main.gd:42` |
| L02 | P1 | A brand-new save is presented as Continue plus New Company, with “Company saved. Safe to close” before the player has started. Fresh-start semantics are confusing. | `02-title-live.png` |
| L03 | P1 | Chat → Create work order retains the question “What should we build first?” as the assignment and creates an ordinary job (`milestone_id = NULL`). It delivered a recommendation document, not a website, and Journey remained untouched. There is no explicit choice/link to the current milestone. | `12-chat-to-work-order.png`, `20-journey-after-generic-job.png`; job `job-5cfb244-150edb10` |
| L04 | P1 | Real chat replies show literal Markdown (`**...**`); narrow bubbles require extensive scrolling. The received reply was initially below the viewport, while the screen remained on the founder's message. Waiting layout briefly clips the right edge and helper text. | `09-chat-waiting.png`, `10-chat-reply.png`, `11-chat-reply-scrolled.png` |
| L05 | P1 | Selecting a long Studio attachment expands Assign contents beyond the drawer. The cancel button and right-hand controls disappear; the Start button moves vertically under the pointer. Studio paths and explanatory text also overflow. | `18-studio-list.png`, `23-website-started.png` (name predates verification; work had NOT started), `32-revision-draft.png` |
| L06 | P1 | The drawer's left wooden edge renders on top of both the artifact reader and Journey, cutting through document text and buttons. Reader title is dark against a transparent/dim header. | `19-reader-recommendation.png`, `20-journey-after-generic-job.png`, `28-website-evaluate-button.png`; drawer frame uses `z_index = 100` |
| L07 | P1 | Activity's CURRENT WORK heading is white partly over pale parchment, body status is low-contrast blue, and the delivery-card decoration crosses its copy. After promotion the summary vanished but “Last work order · none yet” remained despite completed work. | `15-activity-running.png`, `17-promoted.png` |
| L08 | P0 | Website evaluator grades missing evidence as deficient work. It receives only the file prefixes, explicitly cites truncation, and gives completeness 1/3 although the full file contains hero, benefits, how-it-works, waitlist and FAQ. First verdict: 2.00/3, revision required. The 1,700-byte aggregate input budget includes instructions and is far smaller than the stated 3,000-token cap. | `30-evaluation-result.png`, `31-evaluation-revision-actions.png`; evaluator record for `job-ab4f32b-ce1e0f4c`; `harness/src/pi-worker-adapter.ts:405` |
| L09 | P1 | Generated website's form uses `action="#" method="post"`, yet promises launch updates and collection of details. It has no signup backend and does not clearly label the form as nonfunctional. This is an artifact-quality issue distinct from the evaluator's truncation issue. | `company/company-project/jobs/job-ab4f32b-ce1e0f4c/site/index.html` |
| L10 | P2 | CSS opens as a prose document; the Markdown formatter turns a CSS universal-selector line into a list bullet. There is no rendered website preview in-game, so reviewing a website means reading source files. | `27-steer-result.png` (job finished before the attempted update; screenshot actually shows CSS reader) |
| L11 | P1 | First revision reaches the default 12,000-token limit after both files are written (12,175 reported) and becomes blocked, so its work cannot be evaluated. Revision handoffs add enough context to make the existing budget problematic for an ordinary website revision; the UI provides no budget adjustment or continuation action. | `37-revision-activity.png`; job `job-111ecdc7-92f6cf9b` |
| L12 | P1 | Journey does not refresh when a revision starts or becomes blocked: it retains the prior result's rubric and revision/override actions. Clicking the visible Override returns “Only the current result can complete a milestone.” | `35-founder-desk-arrival.png`, `38-journey-after-blocked-revision.png`, `39-override-after-blocked-revision.png` |
| L13 | P1 | After the blocked revision, employee header still says DELIVERY READY and a promotion card is shown beside the token-budget failure. Old delivery attention masks the latest blocked status. | `37-revision-activity.png` |
| L14 | P1 | Bootstrap replays old delivery toasts on restart and on hiring Theo; the title/hiring screens announce “Mina finished” again for existing work. | `40-restart-title.png`, `51-theo-hired.png` |
| L15 | P2 | The three-day journey has almost no reason to inhabit the office: most time is paused in menus, and End Day can immediately unlock the next milestone. Day 2's entire ads milestone took about two simulated minutes, with Day 1 ending around 09:01. Useful for testing, but not yet a convincing day-based game loop. | `52-day-one-summary.png`, `58-ads-evaluation-ready.png`, `63-day-two-summary.png` |
| L16 | P1 | Studio's approved/shared-files surface is replaced by the latest unpromoted job files. The already promoted recommendation is no longer in the visible list while current deliveries are shown as “Open delivery.” Artifact arrival also switches the active tab to Studio. This interrupts Activity and mixes job scratch with the durable archive. | `68-archive-arrival.png`, `86-approval-completed.png`; `show_artifacts` / `show_studio_files` share `_artifact_list` |
| L17 | P1 | After completing a milestone, editing the already-selected Custom work order's title and instructions retains a hidden `milestone_id`. An unrelated approval memo is rejected as “Milestone is locked or already complete.” Switching away from Custom and back clears it. | `76-fresh-custom-draft.png`, `78-hidden-milestone-binding-error.png`, `79-reset-work-type-menu.png` |
| L18 | P1 | Waiting for approval writes `blocked`, `finished_at`, clears the employee assignment, and immediately marks the new approval denied (“Work order ended before a decision”). The live broker still waits and the UI still asks for approval. Clicking Approve DID work and overwrote the row, but persisted state was false throughout the wait. | Read-only SQLite observations of approval `8dd3130d-622b-4bd2-b86b-874629d2a9e0`, `84-approval-console-arrival.png`; `database.ts:383`, `pi-worker-adapter.ts:584` |
| L19 | P1 | Cancellation is in Assign, not Activity. Chat tells the player to manage active work in Activity, but that screen has no cancel action. The working cancel button is beside the disabled Start button in Assign, near the bottom edge. | `84-approval-console-arrival.png`, `89-cancel-control.png`; `_cancel_button` is created in the assignment form |
| L20 | P2 | Short world status plaques truncate “heading to desk” / “needs approval”; the default movement hint omits click movement and Journey; the work picker still offers inventory-keyboard design-note tasks unrelated to the startup fantasy; Settings sliders use plain grey styling. | `24-website-running.png`, `89-cancel-control.png`, `79-reset-work-type-menu.png`, `92-settings.png` |

## Working observations

- Isolated company starts founder-only; free Mina hire adds the rail card and
  office props. Click-to-move worked and the movement hint disappeared.
- Chat used the paid provider and produced a relevant response in approximately
  three seconds. No-tools Chat is explicitly described; active-job Chat links
  to Activity instead of silently starting another conversation.
- Generic work produced a real artifact. Add to Studio and guarded reader worked.
- Website milestone produced both required local files and kept the company brief
  when attached manually. World clock paused in the drawer while the job continued.
- First evaluation completed without provider/parsing error and recorded usage.
- Restart preserved founder position `(400,568)`, day/time, hires, jobs, files and
  cash. It refreshed the blocked milestone to “Active / Prepare work order.”
- A smaller manually edited website retry completed. It again scored 2.00 because
  of truncated evidence, so Founder override was used: exactly $300, zero rep.
  Double-clicking the override did not duplicate the reward; Theo's double-clicked
  hire deducted exactly $300 once.
- End Day persisted its summary and advanced to 08:00. Day 1 spend was $0.06366705.
- Theo retained DeskBloom context from teammate memories/artifacts, produced both
  ads files, and accepted an in-flight steering instruction in the same work
  session (`57-theo-steer.png`). No campaign was actually launched.
- Ads evaluation scored 1.20 and claimed measurement information was not visible
  in the supplied prefixes; the full file contains a Success metrics section.
  Override correctly awarded $600. Day 2 spend was approximately $0.0119.
- Incorporation produced both planning-only files; evaluation again scored 2.00
  because the excerpts omit most of the questions/checklist. Override charged the
  $500 in-game fee once. Chapter completed on Day 3 with $100 cash, $900 gross
  earnings and zero reputation. All three completions required the override route.
- Archive and approval-console physical interactions both navigated to the station
  and opened the associated screen. Explicit live approval resumed its original
  job and created `approval-test.md`; see L18 for its incorrect persisted wait state.
- Cancelling a second approval-waiting job worked and left a durable cancelled
  row; the UI reported “Cancelled by player.” It retained old delivery attention.
- Settings focus was visibly keyboard-accessible. Repeated alternating rail clicks
  settled on the last selected employee. Fullscreen and back preserved composition;
  letterboxing outside the 16:9 game region on this display is expected, not counted
  as an internal black-background defect. No frame-latency claim is made.
- A second quit/relaunch preserved the completed chapter, both hires, $100 cash,
  $900 earned, zero reputation, and founder feet `(720,472)` at Day 3 08:45 before
  exploration resumed. No duplicate reward or fee appeared. The isolated game and
  its worker were closed after the check; the test company remains available.

## Live sequence

1. Unmodified launch blocked; isolated-copy workaround applied.
2. Continue fresh save → hire Mina → explore → ask about DeskBloom.
3. Chat conversion → generic recommendation → promote → open reader.
4. Journey website → attach recommendation → build website → evaluate → revise.
5. Revision writes both files but hits token cap. Founder desk physical interaction
   opens Journey; End Day correctly refuses while AI work is running. After
   failure, Journey remains stale and old Override is rejected. Quit/restart.
6. Restart → smaller fresh website work order → evaluate → same truncation failure
   → override → hire Theo → End Day → Day 2 ads → successful steering → evaluate
   → override → End Day → Day 3 incorporation planning.
7. Incorporation → evaluate → override → chapter complete. Attempt unrelated work
   → hidden milestone rejection → reset work type → approval test → cancellation.
8. Settings, keyboard focus, repeated rail selection, fullscreen/windowed check;
   quit/relaunch and verify chapter, finances, hires, clock and player position.

## Prioritized correction plan and acceptance checks

All immediate corrections below are code, layout, typography, or product-copy
work. This playtest does **not** justify another broad raster-asset generation pass.

| Order | Findings | Correction | Acceptance test |
| --- | --- | --- | --- |
| 1 | L01 | Initialize the empty employee array with the correct concrete type. Add a real-worker startup smoke test using a disposable save. | Launch without `STARTUP_VALLEY_NO_WORKER`; title, credential status, founder-only roster and Continue all work with no script errors. |
| 2 | L08, L09, L11 | Build bounded but representative evidence covering every rubric criterion; budget in tokens, not a tiny aggregate byte prefix. Distinguish insufficient reviewer evidence from deficient work. Add honest-static-CTA criteria, version-aware revisions, and a recoverable token-cap outcome. | A complete website/ads/checklist fixture can pass; removing a required element fails for the correct reason. A truncation-only case asks to retry evidence collection rather than forcing paid rewriting. A budget-limited revision preserves work and offers a clear next action without restarting. |
| 3 | L12–L14, L17–L18 | Refresh Journey on every job lifecycle transition; distinguish approval waiting from terminal blocking; key attention and drafts by employee/job/version. Reset milestone metadata when opening new ordinary work. Hydration restores badges, not fresh completion toasts. | Start/revise/block/cancel/restart shows the current job only; ordinary custom work after chapter completion is accepted; waiting approval remains pending in SQLite until decided; hiring never replays a delivery. |
| 4 | L03, L16, L19 | Let chat explicitly propose/link to the current milestone; summarize the deliverable rather than copying the original question. Separate job deliveries from Studio. Keep all active-work controls, including Cancel, in Activity; do not change the selected tab on artifact arrival. | Chat-derived website work clearly identifies whether it earns the milestone. Completion does not move the user's controls. Promoted files remain visible alongside a distinct current-delivery section; Cancel is discoverable in Activity. |
| 5 | L04–L07, L10, L20 | Bound minimum widths; ellipsize long file/option labels; render chat Markdown and source code appropriately; fix modal stacking; keep essential text on opaque parchment; fit status plaques and reuse the existing theme for remaining controls. | Replay this transcript and long attachment path at 1280×720. No horizontal clipping, unreadable title, modal-overlaid rail edge, hidden cancellation button or truncated essential status. A new reply is visible without hunting through the transcript. |
| 6 | L02, L15 | Make the first run a distinct Start Company flow; introduce a visible “next action” and a reason to return to the office between decisions. Clarify day pacing without forcing artificial waiting. | A new player knows how to hire, assign, review and advance a day without developer knowledge or a walkthrough. Measure actual office exploration and time-to-first-meaningful-reward in another unaided session. |

Before another feature pass, repeat the live route **without the diagnostic launch
workaround or founder overrides**. Treat a full-reward journey and one successful
revision as the acceptance gate, with real evidence that supports the evaluator's
scores. Keep paid calls bounded per job even though this audit had no user-set
overall spending cap.

## Evidence guide

Coordinates below use the 1280-wide window captures including the 32-pixel title
bar; subtract 32 from Y for the internal game composition.

- Drawer overflow: `(812, 301)` through `(1138, 735)` in
  [long-attachment capture](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/23-website-started.png).
- Modal overlap: vertical wood at approximately `x=784–798`, crossing the reader
  and Journey. See [reader](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/19-reader-recommendation.png)
  and [Journey](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/28-website-evaluate-button.png).
- Unfair evidence grading: feedback body around `(320, 490)` in the
  [website evaluation](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/30-evaluation-result.png);
  also [ads missing-evidence verdict](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/61-ads-evaluation-actions.png).
- Stale recovery: [blocked revision](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/37-revision-activity.png)
  and [rejected stale override](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/39-override-after-blocked-revision.png).
- Post-chapter hidden binding: [custom work rejected](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/78-hidden-milestone-binding-error.png).
- Successful persistence: [restored chapter](/Users/zhast/GitHub/startup-valley/game/tests/output/live-playtest-20260903/100-restored-chapter.png).

There are approximately 100 sequential screenshots; the numeric ordering is the
play timeline. Some filenames describe the intended action before verification;
the finding table explicitly corrects the ambiguous ones. The accidental Project
Manager capture `02-title.png` is tooling setup noise, not a game defect.

The test database retains exact jobs, events, artifact paths, evaluations, costs
and transactions. No credentials are included in screenshots or report. Logs:
`game.log` (unmodified launch failure), `diagnostic.log`, `restart.log`, and
`final-restart.log` (live-copy sessions). The only diagnostic source change was:

```gdscript
var initial_employees: Array[EmployeeRecord] = []
if OS.get_environment("STARTUP_VALLEY_NO_WORKER") == "1":
    initial_employees = room.placeholder_records()
_spawn_employees(initial_employees)
```

## Not validated by this playtest

- Normal quality-gated completion and full reputation rewards: all live verdicts
  requested revision; only override-based completion was reached.
- Active-job SIGKILL recovery, network loss, invalid credentials, or evaluator
  provider/parsing failures. No such live failure was injected here.
- Natural 17:30 closing, lunch/off-hours queue carryover, and three full ten-minute
  office days. End Day was deliberately used early to cover the chapter.
- New Company backup/restore UI; a separate fresh data directory was used instead.
- Measured one-frame click feedback, 80–180 ms easing, frame pacing/shimmer under
  load, continuous keyboard locomotion, Windows, or subjective sound quality.
- An unaided human's experience. This was an agent-operated native UI playtest,
  and the agent consulted source/SQLite after reproducing issues to establish cause.

No ads, incorporation filing, publishing, payments, or email delivery occurred.
OpenRouter inference was the only paid external activity. The original user's
save was not modified, and no production code was changed in this audit.
