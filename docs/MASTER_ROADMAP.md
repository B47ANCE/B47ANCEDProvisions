# B47ANCE’d Provisions Master Roadmap

Canonical version: 0.7.0.

## Implemented

- Canonical food, protected ingredient, freshness, nutrition, and preservation-
  state inspection while vanilla food/crafting retain ownership.
- Recoverable appliance coordinator with exact water/power reservations, one
  owner-defined process commit, rollback, replay protection, and quarantine.
- Persistent named-preservation job framework with exact protected inputs,
  station capabilities, eligibility, cadence, elapsed progress, spoilage,
  cancellation, ready state, replay-safe completion, and inspection failures.
- Public API and production load-graph tests.

## Still to add

> First-process design: [apple drying](FRUIT_DRYING_DESIGN.md) selects a native
> small-plant rack, one Apple input and proposed dried-apple output/balance.
> This is a reviewed-source design candidate, not a registered production recipe.
> The [Build 42.21 API audit](FRUIT_DRYING_API_AUDIT.md) leaves production mutation
> blocked on authority, food-state, configuration and persistence proof.

- A read-only native rack/whole-apple eligibility prototype, followed by proof of
  the required server-owned hooks and one complete first-party preservation process.
- One first-party functional appliance/content vertical slice using the existing
  water/power/process transaction contracts.
- Player-facing timed action, inventory/output presentation, and optional uiWorks
  integration for those approved slices.

## Validation and release gates

- Native identity and station proof; cancellation/completion/rollback/uncertain
  outcomes; nested inventories; unloaded elapsed time; save/reload; late join;
  hosted and dedicated servers.

## Identity checkpoint

Version 0.7.0 changes branding and Mod ID only. Prior framework implementation
and content-decision gates remain unchanged. See [identity migration](IDENTITY_MIGRATION.md).

The subsequent documentation-only fruit-drying audit retains 0.7.0 and existing
runtime bytes. Proposed implementation target is 0.8.0-dev.1; no version bump or
gameplay implementation is included. Native SP/dedicated validation remains open.
