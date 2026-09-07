# Validator proposal — passive art-library approval without runtime admission

Date: **2026-09-06**

This is a proposed validator change only. `validate_art_catalogue.mjs` and the
shared catalogue are intentionally unchanged by this review.

## Problem

The generic validator already distinguishes `approved` from
`runtime_integrated`, but two older study-specific checks still equate an
approved native export with runtime authorization:

- the `code_native_symmetric_projection_with_generated_material` branch
  requires every variant to remain outside the approved states;
- its self-test is phrased as “symmetry study does not imply production,” even
  though an exact symmetric object can now pass the visual gate while remaining
  wholly absent from runtime.

Changing `construction.runtime_approved` to `true`, deleting the test, or
removing the symmetry checks would be wrong. It would erase the exact N=S and
E=W proof and could accidentally imply a production binding.

## Minimal explicit contract

Add one family-level object only for a reviewed passive library family:

```json
{
  "art_library_approval": {
    "scope": "passive_art_library",
    "review_path": "dev/art-catalogue/PASSIVE_FURNITURE_LIBRARY_REVIEW_2026-09-06.md",
    "acceptance_date": "2026-09-06",
    "runtime_admission": false
  }
}
```

Treat this as an alternate **art lifecycle** branch, never a runtime gate. The
validator should allow approved variants under the symmetric projection only
when all of the following hold:

1. `production_status === "approved"` and all four variants are `approved`;
2. every required layer has a measured native export, the approved whole exists,
   and the existing six-score/minimum/mean checks pass;
3. `construction.runtime_approved === false`;
4. `runtime_art_path`, `runtime_exports`, and `current_runtime_registration`
   are absent/null for the family and all four variants;
5. `direction_semantics === "visual_orientation"`, no service/interaction/gaze
   metadata is present, and `seated_pose_needed === false`;
6. the existing exact symmetry-pair hashes and fixed canvas/pivot checks still
   pass; and
7. `art_library_approval.review_path` exists and
   `runtime_admission === false`.

In pseudodiff form, replace only the unconditional “all variants unapproved”
part of the symmetric-study check:

```diff
- verify(construction.runtime_approved === false
-   && variants.every(v => !APPROVED.has(v.status)),
-   `${prefix}: bounded symmetric study is not production approval`)
+ const passiveLibrary = family.art_library_approval?.scope === "passive_art_library"
+   && family.art_library_approval.runtime_admission === false
+ verify(construction.runtime_approved === false
+   && (variants.every(v => !APPROVED.has(v.status))
+     || (passiveLibrary && family.production_status === "approved"
+       && variants.every(v => v.status === "approved")
+       && !family.current_runtime_registration
+       && variants.every(v => !v.runtime_art_path && !(v.runtime_exports?.length)))),
+   `${prefix}: symmetric passive approval must remain library-only`)
```

The normal approved-variant branch should continue to verify paths, required
layer coverage, placement, geometry and rubric scores. Add a path check for the
new review field rather than trusting a boolean alone.

## Required self-tests

Keep the existing “symmetry cannot invent four drawings,” pair-equivalence and
hash-mismatch failures. Replace no protection; add these negative cases:

- passive-library scope missing or misspelled while symmetric variants claim
  `approved`;
- `runtime_admission: true` or `construction.runtime_approved: true`;
- any runtime path/export/registration added to a library-only family;
- a service side, interaction cell, employee gaze or seated-pose requirement
  added to the symmetric divider;
- one missing required layer, one score below 2, or a mean below 2.5;
- one symmetry-equivalent whole whose decoded/file hash no longer matches.

This exception is intentionally narrower than “all art studies may be
approved.” It permits the reviewed acoustic divider’s exact passive art to
enter the dev library while retaining every runtime, symmetry and quality gate.

## Proposal dry run

An in-memory merge of the five proposed family objects into the current
catalogue completed **22,088 validator checks** and returned exactly one error:
`acoustic_divider: bounded symmetric study is not production approval`. All
twenty approved paths, required-layer coverage checks, PNG dimensions/hashes,
geometry, rubric scores, and the other four family records passed the current
validator. That single expected error is the guard addressed above; the shared
validator and catalogue were not changed to make the dry run green.
