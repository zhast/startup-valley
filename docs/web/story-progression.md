# A visible next step

The browser game now presents its opening as a short studio story. A paper goal
card remains visible in the office, states the next task in one line, and opens
the relevant screen directly. It replaces the clipped instructions about finding
another menu.

## Opening arc

1. **Welcome Mina.** The invitation is one character introduction and one choice.
2. **Choose your first project.** Pick an unlocked topic and format. The founder
   and hired teammates join by default; price, marketing, team changes, and other
   options remain under **Adjust the details**.
3. **Bring your idea to life.** The project shows its saved progress and one
   **Wrap up the day** action. When ready, that becomes **Share it with the world**.
4. **Our first release.** A short celebration shows actual saved review, fan, and
   earnings values. Back in the office, the goal points toward the next project.

The **Our story** notebook shows completed, current, and upcoming moments.
Broader management remains accessible under **Studio plans**. These are views of
the existing simulation: no new currency, rewards, fake completion flags, provider
calls, or parallel achievement database were introduced. `StoryMoments.goal()`
derives progress from hired candidates, the developing product, and release
history, so reloads retain the same milestones. Native optional work-order screens
retain their existing flow.

## Reference principles

[Game Dev Tycoon's official description](https://www.greenheartgames.com/app/game-dev-tycoon/)
describes starting with simple projects in a small office, then gaining experience
and unlocking more complex choices. The UI borrows that progression in the order
it presents decisions; it does not change the worker's unlock rules.

[Stardew Valley's official introduction](https://www.stardewvalley.net/)
grounds the opening in arriving somewhere and becoming part of a community.
Mina's authored introduction and conversation apply that character-first approach
to this game's studio. No third-party art or dialogue was copied.

## Verification

`game/tests/test_story_progression.gd` checks real control clicks through goal,
planning, day advancement, and release; confirms that the first format is unlocked
and Mina joins the request; verifies that a serialized/reloaded worker snapshot
produces the same progress. Native rendering saves current screenshots under
`game/tests/output/story-progression-current/`.

`game/tests/test_story_conversation.gd` covers the invitation, welcome, compact
offline conversation, and rail layering during the slide animation.

The local native acceptance passed 34 logic/input checks and 39 checks with the
five rendered captures. Browser acceptance must use a fresh export and the real
worker, rather than treating these fixture captures as proof of persistence.
