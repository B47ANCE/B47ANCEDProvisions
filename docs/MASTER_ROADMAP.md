# B47ANCE’d Provisions Master Roadmap

Canonical version: 0.8.0-dev.2.

## Implemented

- 0.8.0-dev.2: server-owned in-place apple drying at native small-plant racks,
  preserving item ID/nutrition, with configurable observed hours/shelf life and
  saved recovery state. Offline only; see [current scope](APPLE_DRYING.md).

- Client-only apple/rack drying inspection prototype in 0.8.0-dev.1: localized
  prechecks, conservative unknown states, sandbox display toggle and no processing.

- Canonical food, protected ingredient, freshness, nutrition, and preservation-
  state inspection while vanilla food/crafting retain ownership.
- Recoverable appliance coordinator with exact water/power reservations, one
  owner-defined process commit, rollback, replay protection, and quarantine.
- Persistent named-preservation job framework with exact protected inputs,
  station capabilities, eligibility, cadence, elapsed progress, spoilage,
  cancellation, ready state, replay-safe completion, and inspection failures.
- Public API and production load-graph tests.

## Still to add

> Historical first-process design: [apple drying](FRUIT_DRYING_DESIGN.md) selects a native
> small-plant rack, one Apple input and proposed dried-apple output/balance.
> This is a reviewed-source design candidate, not a registered production recipe.
> The [Build 42.21 API audit](FRUIT_DRYING_API_AUDIT.md) leaves production mutation
> blocked on authority, food-state, configuration and persistence proof.

- Native validation of the preview and in-place process: getter/setter dispatch,
  resource UI/transfer behavior, age conservation, cancellation, unload/reload,
  save/restart, late join/rejoin and dedicated contention/failure scenarios.
- A distinct dried-food full type/native recipe would need a separately verified
  replacement transaction; current dried results intentionally retain Base.Apple.
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

The historical design/API audit retains its actual 0.7.0 baseline. The approved
prototype uses 0.8.0-dev.1 for a local inspection capability only; see
[preview scope](FRUIT_DRYING_PREVIEW.md). Production recipe and native mutation
remain absent and all historical audit evidence retains its original baseline.
