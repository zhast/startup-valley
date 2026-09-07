# Publishing the completed art pass

The accepted runtime art, reusable native furniture, editable exporters, original
ImageGen masters, prompts, catalogue and review notes belong in Git. Accepted
passive furniture lives under `game/tests/fixtures/furniture-calibration`, not
only in ignored test output. Keep the existing `.gdignore` import boundary.

## Retained evidence

The catalogue also depends on files below the normally ignored
`game/tests/output` directory. A source-only commit would leave its validator
and gallery broken on a fresh checkout.

`dev/tools/publish_art_evidence.mjs` constructs a deterministic, exact inventory:

1. Record the files read by the actual catalogue validator, including original
   hashes and native image checks; do not approximate its schema.
2. Include local catalogue HTML links and image targets.
3. Follow existing local file references recursively through selected JSON
   reports. This preserves the native screenshots supporting their claims,
   including referenced historical failure evidence.
4. Retain every allowed file from the final game regression and final browser
   review directories: `art-completion-20260906-final-fit` and
   `art-catalogue-browser-final-20260906-v2`.

Only PNG, JSON, log and `.gdignore` evidence files are eligible. The generated
`publish-evidence.json` records their exact repository-relative paths, byte
sizes and SHA-256 hashes. It binds the source catalogue and HTML hashes, has no
timestamp and does not modify either catalogue file. Repeated inventories of
the same checkout produce identical manifest bytes.

Historical JSON reports may name the original checkout with absolute paths.
The helper rebases only their `/game/tests/output/` suffix to the current
repository root before validating a reference. It never opens the old absolute
location. This keeps the same closure reproducible in a clean checkout at a
different path without rewriting the original evidence or its recorded hashes.

## Deliberate exclusions

Raw AVI movies remain local and regenerable, rather than entering Git history.
They are not missing artwork: the retained movie manifests, sampled keyframes,
contact sheets, test logs and acceptance notes preserve the review evidence.
Links or command lines naming a raw movie in an original report remain intact;
they do not claim that the movie itself is shipped in Git. The completion
runner documents the commands for recording fresh movies.

SQLite databases and sidecars, credentials, personal saves, caches, dependencies
and unrelated historical captures are not selected. The helper neither reads
nor hashes excluded movies or databases. Symlinks are never accepted as evidence,
and no external filesystem or URL reference is followed. It does not start
Godot, the worker, a browser, a provider session or a network service.

Do not force-add the entire output directory. The local audit found more than
11 GiB there, including 76 raw AVIs and database fixtures; 30 movies exceeded
100 MiB. Git LFS was not configured for this checkpoint. Native source and
runtime artwork had no individual file above 100 MiB.

## Commands and verification

From the repository root:

```sh
node dev/tools/publish_art_evidence.mjs
node dev/tools/publish_art_evidence.mjs --write-manifest
node dev/tools/publish_art_evidence.mjs --check
```

The default is read-only. `--write-manifest` writes only the generated manifest.
Stage the reviewed manifest and its exact `files[].path` list with explicit
`git add -f` paths; the helper intentionally does not stage, commit or push.
Do not replace that list with a directory glob. Then run:

```sh
node dev/tools/publish_art_evidence.mjs --check --check-index
node dev/tools/validate_art_catalogue.mjs --self-test
node dev/tools/build_art_catalogue_html.mjs --self-test
node dev/tools/build_art_catalogue_html.mjs --check
node dev/tools/test_gallery_portability.mjs
```

`--check-index` is read-only and confirms that every selected evidence path is
tracked or staged through `git ls-files`. It checks index membership, not that
staged bytes equal subsequently edited working-tree bytes. A final exported
index/fresh-checkout run of manifest, catalogue and HTML checks is therefore
the publishing acceptance gate. Keep this check provider-free.

The Markdown gallery now uses repository-relative image embeds so GitHub and
relocated checkouts render the same 175 previews (168 views plus seven legacy
references). Construction records that use `method` instead of `note` now show
their real provenance rather than `undefined`. These are publishing fixes;
the catalogue JSON and HTML hashes remain those of the final reviewed snapshot.
Minor trailing-blank cleanup preserves Markdown hard breaks explicitly and
does not alter image pixels or gameplay. The research runtime manifest's final
extra newline was removed; earlier frozen run hashes remain historical evidence.

The publishing inventory is a repository handoff, not a production export
allowlist. Shipping a game build must independently exclude developer fixtures,
source masters, reports and review tooling; that release task remains separate.
