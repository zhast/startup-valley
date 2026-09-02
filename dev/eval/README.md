# Offline evaluation

Run the deterministic evaluation from `harness/`:

```sh
npm run eval:offline
```

The eight JSON fixtures exercise real worker components without a provider key or network call: constrained create/edit tools, bounded attached context, off-hours queueing, fail-closed attachments, traversal defense, studio write denial, and approved promotion provenance. Every fixture snapshots both studio files and studio database records. The runner requires an exact match before and after unless that fixture explicitly approves promotion.

`npm run eval:live` is the optional paid OpenRouter smoke test. Run it only when a person explicitly chooses to incur the provider call.
