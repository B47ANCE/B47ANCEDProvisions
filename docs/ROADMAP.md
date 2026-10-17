# B47ANCE’d Provisions Roadmap

> Consolidated status: [MASTER_ROADMAP.md](MASTER_ROADMAP.md).

## Current foundation

B47ANCE’d Provisions currently exposes read-only canonical food, protected ingredient, and
preservation-state inspection. Vanilla Food and Build 42 crafting remain owners of
their state and actions.

## Approved research additions

### EXT-09 — Named preservation processes

Define processes with stable identity, eligible food-state predicates, exact
inputs/quantities, protected items, station capabilities, optional water/power/
weather observations, duration/cadence, outputs, cancellation, spoilage
interaction, persistence, and recovery. Prove one process end to end before
generalizing; do not import external recipes or balance.

Version 0.6.0 host-implements the generic persistent job contract, including
protected reservations, bounded cadence/elapsed progress, spoilage, cancellation,
replay, completion and quarantine. EXT-09 remains unfinished until one approved
first-party station/input/output definition is connected through server-owned
inventory mutation and proven end to end in native play.

### EXT-07 — Functional appliance consumers

Define project-owned appliance actions for specifically approved appliances.
Each action resolves one logical appliance, reserves inputs, obtains measured
water and power transactions when required, runs a canonical timed action, and
commits atomically or enters recoverable quarantine. UI and appliance assets remain
separate presentation/content concerns.

Version 0.5.0 host-implements the cross-domain coordinator: exact registered
power/water quantities are reserved, the owner-defined process commits once,
declared rejection rolls both resources back, and ambiguous output or resource
finalization is quarantined. Remaining work is one first-party appliance/content
vertical slice with native identity, inventory/output transaction, timed action,
save/reload, late-join, and dedicated validation.

## Proof order

The read-only [0.8.0-dev.1 preview](FRUIT_DRYING_PREVIEW.md) is source-implemented
and offline-tested. Live getter/identity/UI behavior and whole-item integrity are
still unproved. The next affected slice is native validation and server hook
proof; do not promote preview matches to permission to register or run drying.

The first candidate is [apple drying](FRUIT_DRYING_DESIGN.md). Installed source
supports researching native DryingCraftLogic ownership; do not layer the generic
preservation timer over the same job. [Audit blockers B01-B06](FRUIT_DRYING_API_AUDIT.md)
must be resolved before production registration or mutation.

1. Verify one preservation station and one appliance identity in Build 42.
2. Implement read-only eligibility/planning without mutation.
3. Prove reservation, cancellation, completion, rollback, and uncertain outcome.
4. Validate aging/spoilage and unloaded elapsed time.
5. Validate nested inventories, save/load, hosted, late join, and dedicated play.

For the initial apple slice, nested inventories are deliberately rejected. Their
later acceptance remains a separate audited extension; rejecting them is not proof
that their processing works. Source-only station/eligibility inspection comes first.
