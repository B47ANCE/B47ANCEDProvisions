# First preservation process: fruit drying

Design baseline: 0.7.0; audited October 17, 2026 against installed Build 42.21,
Steam build 25485521. Status: **DESIGN CANDIDATE / PRODUCTION BLOCKED**.
This document selects the first design slice; it does not register gameplay.

## Scope and version decision

The first slice is one whole `Base.Apple`, loaded into an existing native
small-plant drying rack, becoming one portion of dried apple slices. It uses no
powerWorks, waterWorks, weatherWorks or uiWorks dependency. No harvesting, knife
preparation recipe, new station construction, mixed fruit, bulk processing or
automatic collection is included. Preparation/slicing is represented by loading
the portion, pending native action/animation verification.

This audit changes documentation only: canonical VERSION remains 0.7.0 and all
runtime files remain unchanged. A later implementation would add compatible
gameplay, so proposed development target is **0.8.0-dev.1** (MINOR), with expected
0.8.0 distribution subject to gates. Neither value is applied by this design.
The proposed content names below are not existing registrations or public APIs.

| Contract | Selected candidate |
| --- | --- |
| Process identity | `foodWorks.fruitDrying.apple.v1` |
| Input | Exactly one whole, fresh, unmodified `Base.Apple` |
| Station | Native `Base.Herb_Drying_Rack`; `Base.Simple_Herb_Drying_Rack` only after equivalent identity proof |
| Output | One proposed `B47ANCEDProvisions.DriedAppleSlices` food portion |
| Mode | Native rack resource/crafting ownership; manual load/start/collect |
| Resource cost | No additional water, electricity or fuel |
| Runtime status | NOT IMPLEMENTED; no output item/recipe is registered |

Station entity names and DryingCraftLogic membership are verified in installed
script declarations [E01]. Runtime selection must resolve the actual entity,
component and resources. Sprite similarity, display labels, coordinates alone or
an arbitrary ModData flag never authorize a station. Existing vanilla recipes
must remain intact; no vanilla file is modified or copied into the mod.

## Native ownership decision

Use native `DryingCraftLogic` as the preferred owner of elapsed processing,
input resources, consumed inputs and output resources. The installed game already
defines racks and drying recipes [E01-E03]. Client UI uses native start/stop and
resource-transfer paths [E04-E08]; those observed calls establish a research route,
not dedicated correctness. Server validation and callback execution must be proved
before adding the production recipe.

Provisions would own the recipe's eligibility, food-value conservation rules,
server sandbox interpretation and localized explanatory text through supported
vanilla data declarations/Lua hooks. Runtime logic remains Lua only. Vanilla
item/recipe declarations are data; no custom Java, bridge or native dependency
is permitted. Dynamic script parsing or private native reflection is not an
approved substitute for a verified registration/configuration route.

Do not run the generic `PreservationProcesses.advance` timer over the same native
job. It would create two clocks and two completion owners. The existing framework
may supply a read-only adapter later, after stable native job identity can be
observed. Generic custom reservations are a separate blocked alternative, not
part of this first slice. The API audit records why the current framework alone
does not establish durable native transactions.

## Eligibility and player behavior

The server resolves the actor from the engine request and checks that the actor
is alive, can reach/use the exact station, and holds the exact input item. Initial
scope accepts the actor's direct main inventory only. Nested bags, floor items,
vehicle containers and items owned by another player are rejected until audited.

Require positive proof of whole/unmodified `Base.Apple`, finite nonnegative age,
freshness, unfrozen/unfreezing/unthawing state, uncooked/unburnt state and no taint,
poison or unsupported custom transformations. Missing fields/capabilities mean
ineligible; the read-only adapter's default-false flags are insufficient proof.
Compare portion/nutrition properties against the registered input definition,
using verified getters and tolerances; a hunger comparison alone does not prove
an untouched item. This integrity check remains a blocker until its native API
route is verified. Unknown third-party food state is rejected, never erased.

Client presentation shows Dry Apple Slices only for a valid supported candidate;
otherwise show a localized explanation within the station interface. Preview may
be stale; server/native validation must repeat at load/start/completion. Closing
the UI or disconnecting does not refund, duplicate or finish a running job.
Walking away cancels only an uncompleted loading/collection action. Explicit
process cancellation must use verified native stop/return behavior, preserving
the actual aged item; it must not create a new fresh apple.

## Food-value and spoilage rules

These are original proposed balance values, not imported recipes or shipped
settings. Installed Apple data [E09] is the reference: weight 0.2, 95 calories,
25.13 carbohydrates, 0.31 lipids, 0.47 proteins, script HungerChange -16 and
ThirstChange -7, fresh 5 days and rotten 8 days. Script hunger/thirst units must
not be passed unchanged to runtime setters without a verified conversion.

- One input produces at most one portion. Preserve total input calories and
  macronutrients, and never increase available hunger benefit. Output target
  weight is 0.05; drying removes water mass, not calories. Output grants no thirst
  reduction. Do not reuse `Base.DriedApricots`: it is a different fruit with 241
  default calories [E09], and cannot stand in for a 95-calorie apple.
- Proposed shelf-life multiplier is 6: fresh 30 days, rotten 48 days. At completion,
  carry the actual native-aged input's relative age: `outputAge = inputAge * 6`
  when both output thresholds use the same factor. Preserve freshness class;
  do not reset the clock. For differently configured definitions, the mapping must
  preserve at least the existing fresh/rotten fractions and be proved separately.
- Native food aging continues while loaded/running; rotten input never yields
  edible dried output. Failed/rotten batches retain the actual spoiled input or
  native failure result according to a verified hook. A native recipe that can
  turn rotten input into fresh output does not meet this design.
- Native temperature/wetness behavior determines environmental progress. The
  private drying-factor method is not a Lua customization point. No custom
  weather simulation, rain-based spoilage rule or temperature threshold is invented.

Food setters are observed in vanilla Lua [E10], but preservation of all input
fields and atomic recipe-completion hooks remain UNKNOWN. If the native route
cannot enforce these invariants, leave the process unregistered and document
the missing capability; do not weaken the rules to make the recipe appear to work.

## Proposed server sandbox contract

All entries below are design-only and must be localized before implementation.
Use the retained `foodWorks` sandbox namespace and a Provisions page. The server
validates/snapshots settings at batch creation; clients never choose balance.

| Identifier | Proposed default and bounds | Meaning / feasibility gate |
| --- | --- | --- |
| `foodWorks.EnableFruitDrying` | Boolean, default true once implementation gates pass | Enables new batches; disabling does not delete existing inputs/jobs |
| `foodWorks.FruitDryingHours` | 48 base hours; integer 6-168, step 6 | Must map to a verified native duration input; does not promise wall-clock completion under weather |
| `foodWorks.FruitDryingShelfLifeMultiplier` | 6; integer 1-12, step 1 | Scale both shelf thresholds and age mapping consistently; never refresh old food |

Enablement defaults to absence today because nothing is registered. Reject invalid
new settings rather than accepting client values. On a valid server configuration
change, existing batches retain the accepted definition/settings revision; later
batches use the new values. Snapshot persistence and native duration binding are
unverified blockers. No invisible hardcoded duration replaces a blocked option.

Input/output counts, nutrient conservation and exact supported types define this
recipe and its safety contract, so they are not user-adjustable micro-settings.
Weight/thirst are authored food properties with a documented conservation rationale;
reassess them as gameplay settings if future balance modes make them variable.
Native station capacity stays native. Protocol IDs, UI coordinates, replay bounds,
finite-number checks and schema numbers remain implementation details.

## Persistence, trust and recovery

Native entity/resource/craft persistence and replication are the intended source
of truth. Clients send intent through the verified vanilla route; they never
submit trusted elapsed hours, eligible state, nutrients, output type/count, settings
or a command to spawn food. Prove connection/actor binding, distance, ownership,
capacity, exact identity and recipe selection on the server. Client predicates
and `ISItemSlotAddAction:isValid()` returning true are not that proof [E07].

If extra Provisions state is unavoidable, use a server-owned, scalar-only schema
with definition revision, exact native station/input/job identities, accepted
settings and completion receipt. Never serialize Lua functions, userdata, live
items/containers or player objects. `ModData.getOrCreate` and SGlobalObjects are
verified vanilla persistence leads [E11-E12], not a chosen crash-atomic inventory
journal. Do not transmit the whole journal to clients. Existing legacy save keys
remain unchanged; no data migration runs in this design.

Join/rejoin must read native resource/progress state plus an optional sanitized
snapshot, not replay creation. Restart/unloaded catch-up must have one owner and
never infer that uncertain output is safe to create again. Missing output receipts,
removed racks, mismatched definitions or ambiguous completion require inspection.
Quarantine must durably preserve recoverable inputs/outputs; a process-local flag
alone cannot provide recovery. Cancellation must not undo an already committed
output. Downgrade after new persistent state is unsupported until explicitly tested
with disposable fixtures and backups.

## Acceptance sequence

1. Read-only eligibility/station prototype on current installed Lua APIs; no
   input removal, food setters, native recipe registration or job advancement.
2. Prove native recipe discovery and safe server-owned hooks for whole-item
   eligibility, duration, value/age mapping and rotten-at-completion rejection.
3. In disposable runtime fixtures: interrupt loading, move/remove/eat input,
   fill output resources, cancel at each phase, and remove/rebuild the station.
4. Verify input/output count, nutrient totals, age/freshness and custom-field
   policy; repeated collection/start/stop must not duplicate or repair food.
5. Verify actual save/reload, unloaded time, multi-day absence, configuration
   changes, client disconnect, two-player contention, late join and restart.
6. Dedicated validation includes forged/stale IDs, far-away actors, forged
   quantities/settings, replay, concurrent collection and failures across commits.

All native SP and dedicated cases are NOT TESTED. G7 BLOCKED / NOT TESTED and
stable G8 BLOCKED. Design completion, source hashes, offline tests and a GitHub
PR do not satisfy runtime gates. See [API audit](FRUIT_DRYING_API_AUDIT.md) and
[evidence index](FRUIT_DRYING_EVIDENCE.json) for exact findings and fingerprints.
