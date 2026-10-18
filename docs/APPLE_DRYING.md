# Server-owned in-place fruit drying

Project Version: 0.8.0-dev.5

Compatible feature checkpoint within the 0.8.0 MINOR development line. Implemented
in Lua and tested offline; native SP and dedicated multiplayer **NOT TESTED**.
This changes the original proposed implementation rather than weakening its
authority, calorie-conservation or no-refresh requirements.

The 0.8.0-dev.3 extension accepts 22 exact vanilla fruit types through the legacy
AppleDrying modules. See [supported types and blocked families](PRESERVATION_EXPANSION.md).
All references to the original Apple below also describe the same-item lifecycle
for the accepted fruit. New non-Apple jobs bind their exact full type; omitted
type remains the original Apple v1 representation. This additive format is not a
downgrade migration; old code cannot process the new fruit jobs.

## Player flow

1. Carry a whole, fresh, unmodified supported fruit directly in your main inventory. Stand
   on or cardinally beside an empty native small-plant drying rack, without a wall,
   window or door edge in between. Both Herb Drying Rack variants are candidates.
2. Right-click the rack and choose **Dry [fruit]**. The server rechecks the exact
   item, type, actor, rack and configuration. The first fresh item of each supported
   fruit type among at most 256 direct inventory entries is sampled;
   a partially eaten/modified sample is rejected rather than silently substituted.
3. Leave it to dry. Default: 48 observed, loaded game hours. Use **Check
   apple-drying progress**. Long observation gaps/unloaded racks pause progress;
   the native apple still ages when the server updates it. Rotten/unsupported
   batches stop and can be cancelled to recover the actual food.
4. Use **Collect dried apple slices** when complete. Other nearby players may
   collect a shared rack's result; the first exact-ID removal wins. Cancel before
   conversion to recover the original aged apple. A carried unfinished batch has
   a separate inventory cancellation action. **Return carried drying batch to this
   rack** resumes an unfinished batch at any supported empty rack, preserving earned
   progress and awarding no carried time. This also recovers a carried partial conversion.

Loading and collection are immediate, validated server operations in this slice;
no action animation or claimed native timed-action duration is added. Existing
read-only preview actions remain independent.

## One physical item, one owner

The apple moves through vanilla resource/inventory APIs. It is **never consumed
and replaced by this process**. Completion updates that same item, including its
same native ID, to a saved dried state. There is no output-spawning command,
native craft registration, native start call, second native-job clock, or generic
PreservationProcesses job over the same input. The sole timer is this server
process, invoked every ten game minutes and on explicit server inspection.

The Apple result remains `Base.Apple`, named **Dried apple slices**; other accepted
fruit keeps its own original type and vanilla icon/model with its localized dried
name. `B47ANCEDProvisions.DriedAppleSlices` is not registered. This
identity choice removes the cross-item consume/create transaction. Vanilla and
other mods can still recognize its base type as Apple; recipes that require a
whole/default apple may reject its modified thirst/weight. No third-party
compatibility or runtime artwork hookup is claimed. Original apple art/model source
is retained under assets, outside the runtime tree.

Calories, carbohydrates, lipids, proteins, hunger and other food effects are not
rewritten. Whole/default integrity is checked against an unowned native default
comparison object of the exact supported full type; it is never added to an inventory, rack or world.
Poison, taint, cooking, freezing/thawing, extra ingredients/spices, custom names,
nonempty foreign ModData, partial weight/effects and unsupported getters reject
new batches. Unmodified getters avoid confusing native stale-food presentation
penalties with changed authored effects.

At completion weight becomes one quarter of the original; thirst benefit becomes
zero. Both freshness thresholds and actual current age are multiplied by the saved
shelf-life factor. Thus 1.25 raw days becomes 7.5 dried days at factor 6, with
thresholds 30/48 instead of 5/8. Freshness class carries forward. Rotten input
never becomes edible dried food. Collecting an old completed batch does not
reapply conversion or reset its age.

## Authority, synchronization and recovery

Clients send only command, rack coordinates/object index, exact item ID and a
local UI index. The engine supplies the actor. The server validates argument
shape/bounds, alive state, same-level cardinal adjacency, both-direction barrier
checks, exact rack script/components, exact item ownership, food state and settings.
It resolves objects again on every action. Remote requests are bounded to eight
per actor per second; scans are bounded. Clients never supply progress, nutrition,
balance, batch state or output type/count. MP clients cannot load gameplay handlers.
SP dispatches the same server-owned handler.

Only an empty one-input/one-output native rack with no running native craft can
start. Other native work or additional input items pause the process; it does not
stop, replace or override vanilla crafting. The accepted apple remains in its
native input resource. Any vanilla resource removal moves the actual item; the
custom timer does not follow it into inventory. A moved-away/returned item can
receive at most the normal bounded observation interval; sampled presence is not
a claim of continuous custody between observations. No long absence is credited.

The authoritative flat scalar job lives in a **server-only ledger** under
`foodWorks.appleDrying.index.v1`, keyed by native item ID. That server global table
also holds bounded rack-discovery records. The item's `foodWorks.appleDrying.v1`
table is a separate copied display/recovery snapshot, never an authority source.
The tables never alias. Changing/copying a public snapshot cannot change accepted
hours, shelf life, progress, observed-age floor or conversion plan. A resume with
no valid private record is rejected, even if item metadata claims it is ready.

A server-assigned rack marker uses a saved counter plus creation world time;
coordinates and marker form the current anchor. Returning the exact carried item
to a validated rack rebinds that same private job and resets its observation time,
not its earned progress. Server-observed raw age cannot move backwards.

The ledger contains no live items or replacement-spawn entitlements. Unknown schema
or corrupt/unavailable data fails closed without resetting saved state. A missing
discovery entry can be rebuilt from a valid private job by inspection/resume. A
lost private ledger is **not** reconstructed from client-visible item snapshots.
Native/save discrepancies therefore may stall recovery, but never authorize a
new physical output. Failed/carried unfinished records remain until cancellation
or recovery; ambiguous records are not silently deleted. There is a technical cap
of 256 ledger jobs/rack discovery entries; a full ledger rejects new work.

Conversion records an immutable target in the private ledger and copies it to
the original item before setters, then
applies idempotent setters and marks it done. Age is never decreased during retry.
A failure remains `converting` and is reported, not treated as rollback/success.
Missing setter capabilities are checked before starting. Retries address only the
same item ID and cannot create food. Finished food and ModData are synchronized
through an explicit full-item native resource sync **after** setters; this does
not rely on the native post-output recipe hook or inventory-only stat packets.

Collection uses exact `removeItemById`, `AddItem(existingItem)` and vanilla added-item
synchronization, with no poll fallback or replacement spawn. A known inventory
rejection restores the same object to the resource. These are vanilla transfer
operations: native crash/save ordering across world/player files remains a runtime
gate, not a custom crash-atomicity guarantee. Partial conversion, native auto-rot,
station destruction, native resource UI removal and client transfer races require
actual in-game failure testing. Do not downgrade a save containing these items
without a backup; no reverse migration is implemented.

## Sandbox contract

| Server setting | Default | Bounds / existing-save behavior |
| --- | --- | --- |
| `foodWorks.EnableFruitDrying` | true | Boolean; disables new batches only; existing ones remain manageable |
| `foodWorks.FruitDryingHours` | 48 | Integer 6–168, step 1; snapshotted at start |
| `foodWorks.FruitDryingShelfLifeMultiplier` | 6 | Integer 1–12, step 1; snapshotted at start |

Missing values use the documented defaults; invalid provided values reject new
work. No power, water, fuel, temperature or rain integration is included. Weight
reduction, no thirst benefit and nutrient conservation define this recipe's
physical result, rather than adjustable micro-settings. Scan/index limits,
comparison tolerances, request throttles and the 0.2-hour continuity cutoff are
internal technical bounds. The cutoff bounds ten-minute observations and does
not substitute for configured drying hours.

EN keys cover actions, feedback, saved output name and all sandbox labels/tooltips;
other languages use vanilla fallback. The saved custom name uses the server's
translation, not per-client item-name translation. Existing foodWorks API/module,
sandbox and prior persistence identifiers remain intact; no old-save migration runs.

## Evidence and gates

See [source fingerprints](APPLE_DRYING_EVIDENCE.json) and [testing](TESTING.md).
Native inspection confirms that Food saves/loads age and modified freshness
thresholds, item serialization retains IDs/ModData/custom weight, and resource sync
serializes full items. This establishes a source-supported authority/persistence
model, not live Lua dispatch, native save compatibility or dedicated correctness.
Individual native bindings without matching vanilla callers remain INFERRED and
guarded; absent capabilities fail closed.

G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. No packaging, deployment, game/server
launch or Workshop publication. The original native-recipe route remains blocked
as documented in FRUIT_DRYING_NATIVE_HOOKS.md; this process does not enable it.
