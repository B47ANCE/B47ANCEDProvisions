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

> Content-decision gate: no authoritative document currently selects the first
> process/appliance, station identity, inputs, outputs, duration, spoilage rule,
> resource quantities, or balance. EXT-07/09 approval authorizes the framework,
> not a copied research-mod recipe or an invented production definition.

- One approved first-party preservation process with verified recipe, station,
  input/output, timing, spoilage, and balance values.
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
