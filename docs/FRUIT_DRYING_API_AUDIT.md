# Fruit-drying API audit

Project baseline: 0.7.0 at `93400d5cd607925f132aaf591fbfd32cd3f048ec`.
Audit date: October 17, 2026. Installed Steam app 108600, build **25485521**;
packaged Core constructs `GameVersion(42, 21, "")`: **42.21**. No additional patch
suffix was observed. Version was inspected statically; no game/server was launched.

Result: **source audit complete; production mutation BLOCKED**. The preferred
candidate reuses native drying racks/crafting. Evidence below supports research
and observed call forms, not an established safe production authority model.

## Provenance and scope

The Steam library and appmanifest were discovered locally; the build/public branch
fields were read without copying account/manifest contents. The installed game
tree was read-only. `FRUIT_DRYING_EVIDENCE.json` fingerprints relevant files,
inclusive line ranges and selected packaged class metadata. It contains no copied
game implementation or private paths. Hashes identify locally installed bytes;
they do not certify that Steam files are pristine or that loose/packaged class
loading has been exercised. The old 42.20.3 audit remains historical.

The shared API catalog and local draft were searched first. Useful entries included
world-age reads, OnClientCommand, OnInitGlobalModData and syncItemModData; hash
matches were rechecked where applicable. The catalog had no usable CraftLogic or
item-resource transaction entry. No match was treated as absence from the engine.
Observed receivers and arguments below were inspected directly.

Six reusable observations, including the unresolved resource receiver and private
drying-factor limitation, were recorded through the API helper into the local
unmanaged draft. Draft validation passed. The installed managed catalog was not
edited and no finding was promoted to runtime proof.

## Installed source findings

| Evidence | Observation and execution side | What it establishes / limit |
| --- | --- | --- |
| E01 | `Base.Herb_Drying_Rack` and `Base.Simple_Herb_Drying_Rack` declarations contain item resources, manual DryingCraftLogic and `DryingRackHerb` recipe query | [VERIFIED: script data] Existing station candidates; runtime lookup/identity stability UNKNOWN |
| E02-E03 | Native large-plant rack and herb/grain drying recipe declarations exist | [VERIFIED: script data] Native processing architecture; no selected fruit recipe, no proof that recipe time equals elapsed hours |
| E04 | Client widget calls `_component:canStart(_player)`, `:start(_player)` and `:stop(_player)` through ISEntityUI | [VERIFIED: observed Lua calls] CraftLogic is invoked from Lua; return handling is observed only, server authorization not proved |
| E05-E06 | Client helper queues shared `ISGenericCraftStart`; actual callback runs in `perform`; `complete` is commented out | [VERIFIED: source] Do not assume a shared filename means server-owned completion; native dispatch must be checked |
| E07 | Shared `ISItemSlotAddAction:complete()` checks item presence and calls `self.resource:offerItem(self.item)`; `isValid` returns true | [VERIFIED: source] A ResourceItem-like receiver accepts an offer call; return value is ignored, so reservation success and exploit resistance are UNKNOWN |
| E08 | Shared removal has a server branch using `:removeItemById(self.targetItem)`, `:sync()`, inventory `:AddItem(removedItem)` and `sendAddItemToContainer(inventory, item)` | [VERIFIED: source] Exact observed resource/inventory synchronization path; fallback `pollItem()` is unsuitable for strict identity guarantees |
| E09 | Installed Apple and DriedApricots item declarations differ in type and food values | [VERIFIED: script data] Apple is a concrete first input; dried apricots are not an interchangeable output |
| E10 | Server trap code calls `instanceItem(type)`, food hunger/weight/macronutrient setters and sends an added item to the actor's inventory | [VERIFIED: observed Lua calls] Native item creation/setter route exists; not a preservation transaction or atomic replacement contract |
| E11 | Server vehicle code uses `ModData.getOrCreate(name)` and subscribes to `Events.OnInitGlobalModData.Add(callback)` | [VERIFIED: source] Server global-data initialization route; no inventory crash-atomicity or custom job schema proved |
| E12 | Server SGlobalObjectSystem registers a named system, reads existing ModData and exposes an initial-client-state hook | [VERIFIED: source/comment] Persistence/late-join pattern; station selection, lifecycle and full restart behavior remain untested |
| E13 | Server farming source uses `getGameTime():getWorldAgeHours()` and divides by 24 | [VERIFIED: observed Lua call] A world-hour source; not a guarantee of per-job unloaded progress |
| E14 | Server command dispatcher calls the handler with engine-provided `player, args` | [VERIFIED: source] Optional custom-intent entry point; handler must validate all args. No new network protocol selected |
| P01 | Existing Provisions module takes arbitrary stores/providers and changes table state | [VERIFIED: project source] Framework only; no registered station, native inventory provider, persistence or server-only loader contract |

Call observations are not complete signatures or validated invocation examples.
In particular, no direct Lua call to the private drying-factor function is approved.
The deprecated ISStartCraftProcessorAction was encountered and excluded as the
chosen integration path; its mere existence does not justify new hooks.

## Packaged metadata and official documentation

Selected class metadata [N01-N03] identifies public CraftLogic start/stop/request/
sync members, protected save/load, and private DryingCraftLogic.getDryingFactor.
Native declarations alone are **[INFERRED] as Lua capabilities**; only matching
vanilla Lua callers above establish observed exposure for their specific forms.
Authentication, packet validation, crash ordering and unknown overloads were not
promoted to VERIFIED. The Core version constructor is a static identity fact.

The official [DryingCraftLogic reference](https://projectzomboid.com/modding/zombie/entity/components/crafting/DryingCraftLogic.html)
corroborates the private drying-factor method and protected save/load. The
[CraftRecipe reference](https://projectzomboid.com/modding/zombie/scripting/entity/components/crafting/CraftRecipe.html)
lists time getters and Lua-call metadata; it does not establish a usable public
time setter or a preservation callback's execution side. The
[Food reference](https://projectzomboid.com/modding/zombie/inventory/types/Food.html)
lists both getHungerChange and getHungChange: they must not be mechanically
renamed or assumed equivalent. Installed trap Lua specifically writes base hunger
and HungChange alongside nutrients. Online docs are unpinned corroboration, not
a substitute for the installed build or runtime tests.

## Blockers and permitted next steps

| ID | Blocker | Evidence needed before affected implementation |
| --- | --- | --- |
| B01 | Native recipe registration and eligible-input/output callback ownership | Prove supported own-data/Lua hook route, exact argument/return forms, server execution and revalidation; no private reflection or vanilla replacement |
| B02 | Whole-item integrity and food-state conservation | Prove partial-use/custom/poison/taint rejection, exact input at commit, nutrient/portion mapping, age mapping and rotten-at-finish rejection without refreshing food |
| B03 | Meaningful sandbox settings | Prove server duration binding and settings snapshot persistence. Neither an undocumented setter nor private drying-factor override is acceptable |
| B04 | Durable native inventory/output completion | Prove concurrent access, output capacity, once-only consume/create, cancel/stop return semantics and station destruction/recovery |
| B05 | Unloaded time, serialization and join/restart | Test native processor saves, removed/rebuilt station identity, late join, long absence and dedicated restart without duplicate catch-up |
| B06 | Existing generic framework is not a safe fallback | Supply a server-only provider, serializable store/receipts, durable reservation/commit journal and tested catch-up/observation behavior before using it for gameplay |

Production recipe/item registration, input mutation and job advancement stop at
these gates. A read-only native station/eligibility inspector is the next bounded
implementation slice. Failure to verify a required hook leaves fruit drying
disabled; it never transfers gameplay authority to the client.

## Generic-framework audit observations

Source inspection P01 shows that reserve happens before a job is attached to the
provided store, and no disk flush/atomic inventory commit exists. Receipt copying
preserves non-table values, including possible userdata/functions; the store is
not intrinsically guaranteed serializable. Validation is shallow, and observation
context must be supplied by a trusted owner. These are integration blockers,
not a reason to change existing code during this design task.

[TESTED: offline Lua 5.1 audit probe] With a synthetic 240-hour definition and a
single 240-hour gap, the existing engine credits 168 elapsed hours, moves the
last-world-age marker to 240 and records at most 64 observations. The 72-hour
remainder is not retained for later catch-up. The bounded observation history also
does not by itself prove continued cadence evaluation after saturation. This
observes existing behavior; it is not a native bug reproduction or a new runtime
test. The probe and five baseline suites are recorded in TESTING.md.

## Evidence status

G6/source findings and offline checks cover only the stated static scope; they do
not declare a project G6 PASS. SP NOT TESTED; dedicated G7 BLOCKED / NOT TESTED;
stable G8 BLOCKED. No packaging, deployment, publication, Java code, private game
modification, game/server launch or third-party mod analysis occurred.
