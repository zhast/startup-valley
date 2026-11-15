# Studio website preview

`game/ui/studio_website_preview.gd` is a native Godot view of a fictional product
homepage. It uses the current or a saved tycoon product, with the project's name,
topic, type and existing release state. The page identifies itself as an **in-game
website preview**. It does not generate HTML, publish a website, read a save file,
call a provider, or issue simulation commands.

The visual direction takes the warm illustration/short benefit-card structure of
the owner's reference site as inspiration. The implementation uses Startup
Valley's own paper/card materials, pixel display font, office window, floor,
separate desk layers and character idle frames. The vignette is drawn in code
at native pixel size; there is no new raster asset or borrowed game art.

## Integration

CompanyPanel now exposes **Preview our website** as the secondary action on
active-project and saved-release story screens. Its public `show_website(project)`
opens the passed project. Closing leaves the original screen visible; navigating
or hiding the host dismisses the child. State refreshes preserve modal focus.

The component is created once as a **direct child** of the fullscreen CompanyPanel,
outside the header/content/footer containers that are cleared during rerenders:

```gdscript
var _website_preview: StudioWebsitePreview

func _ready() -> void:
    # Existing CompanyPanel setup ...
    _website_preview = StudioWebsitePreview.new()
    add_child(_website_preview)

func _preview_project(project: Dictionary) -> void:
    _website_preview.present(project, "Our little studio")
```

Use the current `product` for a project-screen action, and the selected
`_released_focus()` product for a release-screen action. For a general entry
point, `StudioWebsitePreview.project_from_state(state)` returns a deep copy of
`state.tycoon.developing`, then the first valid `state.tycoon.history` entry, then
an empty dictionary. The worker already orders history newest first.

Keep CompanyPanel visible while the child preview is open, so the existing
CompanyPanel pause behavior still applies. The component closes only itself;
its optional `closed` signal lets the caller observe dismissal. Call `dismiss()`
when deliberately navigating away from the host. No change to the legacy
provider-artifact helper `site_preview.gd` is needed.

The modal captures pointer input, loops Tab between its two real actions,
supports Escape and Page Up/Down, and restores focus to the caller's action.
It holds a deep copy of passed data and never changes the original dictionary.
Labels render bounded plain text. Release copy reflects passed worker state;
previewing does not change that state.

## Verification

```sh
godot --headless --path game --script res://tests/test_studio_website_preview.gd
godot --path game --script res://tests/test_studio_website_preview.gd
```

The focused test passes 38 checks headlessly and 41 with native rendering
(three additional screenshot writes). It checks current/saved selection,
nested-copy isolation, malformed-data fallbacks, release/ready copy, modal focus,
real pointer clicks, Escape, keyboard scrolling, and bounds at 1280×720 and
640×640. An initial wrapping/minimum-height regression was caught and fixed by
refitting after the container layout settles.

The connected story-progression test also passes 57 headless / 64 rendered checks.
It opens both entry points with real pointer input, checks that no simulation
requests or state changes occur, closes with Escape and the back button, verifies
focus through a host refresh, and checks host navigation/hide dismissal.

The retained images below were inspected from Godot 4.7.2's native renderer on
2026-11-15. They use fixture project data and a plain backdrop. They verify the
component and connected CompanyPanel; the final browser export still needs its
own playtest.

- [Current project](assets/studio-website-preview/website-developing.png)
- [Saved release](assets/studio-website-preview/website-released.png)
- [Narrow layout with a long name](assets/studio-website-preview/website-narrow.png)
- [Active-project entry](assets/studio-website-preview/project-entry.png)
- [Saved-release entry](assets/studio-website-preview/release-entry.png)
- [Connected preview](assets/studio-website-preview/project-connected.png)

At 640 pixels, the page stacks and scrolls while its close/back controls remain
fixed. Longer names wrap in full within the bounded input limit. These checks do
not establish support below that viewport width.
