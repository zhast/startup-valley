# Character introductions and a world beyond the office

## Evidence

Reviewed the actual published Stardew Valley farm screenshot in the
[developer's Steam gallery](https://store.steampowered.com/app/413150/Stardew_Valley/)
and captured the expanded Robin introduction in this
[Japanese-edition gameplay diary](https://note.com/nothinghurt/n/n9c38fb19ea0f).
These are published game captures, not a local Stardew playthrough. No Stardew
installation was available here, and none of its artwork enters our game.

![Stardew's published Robin introduction](https://assets.st-note.com/production/uploads/images/112736030/picture_pc_88aadfd5615faeb8724026f553486808.png?width=1200)

Our comparison used the real browser's fresh-company introduction, conversation,
project, and release screens recorded in `playtest-polish.md`.

## Comparison and changes

| Observed reference | Startup Valley finding | Implemented response |
| --- | --- | --- |
| Robin has a large portrait, a name plaque, and dialogue that immediately establishes her role. | Mina's portrait was small; the page explained the workflow but did not say what she did. | A face-and-shoulders portrait, **Product designer**, and one short line. |
| Dialogue occupies the lower screen while the location remains visible above it. | A central, darkened form hid most of the office. | A lower-screen introduction with a much lighter scrim. |
| One dialogue beat is the focus of the introduction. | A title, subtitle, quote, explanatory line, and action competed for attention. | Name, role, a short invitation, and **Invite Mina · Free**. The welcome leads to the first idea. |
| The farmhouse sits within an outdoor world; paths and vegetation give the view depth. | Our full-screen floor read as a sealed rectangle. | Window light is implemented. The compact starter room and garden surround are a separate change described in `gameplay-reference-audit.md`. |

Later Mina conversations also use the closer portrait, explicit role, and a single
short story beat. Their next action still derives from the saved project state.
The opening menu uses the same original game's materials, a prominent title, and
minimal copy. The user's website is a mood reference, not a copied web layout.

## Acceptance

`test_story_conversation.gd` clicks the actual invitation once, verifies the
portrait/role and lower-screen presentation, checks that the welcome opens the
first project, and exercises conversation state changes and animated rail
layering. Native rendered captures supplement these checks; browser captures
must be refreshed after exporting the new screens.

Remaining differences are intentional product decisions: this is an office
tycoon with click-to-move, not Stardew's farming simulation. The garden surround
does not imply that outdoor travel is implemented. Its future town visits should
serve relationships and project ideas, rather than adding another dashboard.
