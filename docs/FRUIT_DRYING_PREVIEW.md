# Apple-drying inspection prototype

Historical prototype version: 0.8.0-dev.1

This is a client-only inspection capability built from the 0.7.0 fruit-drying
design. It never permits or starts processing. A new inspection capability is a
compatible MINOR addition, so the declared implementation checkpoint is
0.8.0-dev.1; this is not a stable release or a completed drying process.

The preview itself remains read-only. Later in-place drying is documented
separately in APPLE_DRYING.md; this historical evidence does not validate it.

## Use

- Right-click exactly one `Base.Apple` in inventory and choose **Inspect
  apple-drying prechecks**. Nested/other inventory items can be inspected, but
  fail the direct-main-inventory check. Multi-selection and unrelated items do
  not add the action.
- Right-click a native small-plant drying rack and choose **Inspect fruit-drying
  station**. This report inspects only the first apple found directly in the
  current player's main inventory; the report explicitly identifies that sampling
  policy. Inspect an individual apple through inventory for exact selection.
- The report is a snapshot, recalculated when the menu entry is activated.
  Use the close button, Escape or the controller's close action to dismiss it.
  The window uses vanilla rich-text scrolling, controller controls and viewport
  sizing; actual input/scale/layout behavior still needs in-game verification.
- `foodWorks.EnableFruitDryingPreview` is a default-on sandbox display toggle on
  the existing Provisions page. It is independent of EnableFoodInspection and
  does not enable a recipe or alter gameplay. Missing sandbox data follows the
  documented default. No client preference/configuration store is added.

Inventory inspection leaves station checks unknown. Station inspection does not
search nearby squares or claim reachability: it checks the clicked object only.
An arbitrary ModData flag, sprite or display name cannot mark a rack as supported.

## Meaning of the checks

The inspector positively reads exact type and direct inventory ownership; finite
freshness/age; frozen/freezing/thawing, cooked/burnt, tainted and poison flags;
poison power; actual weight against its registered script definition; readable
finite nutrition; and whether custom ModData is reported. Unsupported, throwing,
missing or malformed methods return **Not verified**, never a default clean state.
Custom ModData is conservatively rejected using hasModData; getModData is never
called, so inspection cannot allocate or create an item data table.

Any failed precheck gives **A precheck failed**. Otherwise the summary remains
**Eligibility is not yet proved**. Matching weight or readable nutrition is not
proof that an apple is whole/unmodified. Whole-item integrity and server access
always remain unknown. Neither report offers a start button, promises drying
eligibility nor authorizes a gameplay request.

Rack checks require the script full type `Base.Herb_Drying_Rack` or
`Base.Simple_Herb_Drying_Rack`, a native DryingCraftLogic component, Resources and
an available square. These are presentation observations, not authorization or a
claim that either variant has passed native gameplay tests. Unavailable getters
or bindings leave checks unknown. An unrelated drying component can expose an
inspection entry, but its unsupported script identity fails the check.

Work is bounded: at most 32 engine-provided world-menu hits and 256 direct
inventory entries per explicit action. No recursive bag scan, per-tick inventory
scan, world search, persistent selection, timer or job is added. A bounded scan
that finds no apple warns when it stopped before the end of inventory.

## Read-only and authority boundary

All new code is under `media/lua/client/foodWorks`; the module additionally exits
if loaded on a dedicated server. Only the existing client loader installs it.
Its cached API table prevents duplicate handlers if native loading and require
both execute the file. There is no new server/shared gameplay handler.

Calls are getters plus UI/event APIs. No item creation/setter, inventory transfer,
job operation, recipe registration, ModData write, network send or sandbox write
is present. The native modal's speed-resetting destroy method is overridden on
this subclass only; neither opening nor closing the preview changes game speed
or pause controls. Existing food inspection is otherwise unchanged. Per-player
window/focus state is local UI state and is never persisted or synchronized.

The retained foodWorks Lua/API, sandbox and save identifiers remain intact.
No production process, output item or resource configuration is introduced.
Previously proposed gameplay duration/shelf-life settings remain design-only.
The broader production G7 and stable G8 gates stay BLOCKED.

## API evidence

Installed source remains Build 42.21 / Steam build 25485521. The prior design's
18 fingerprints still match. `FRUIT_DRYING_PREVIEW_EVIDENCE.json` adds bounded
source ranges for world-menu controller tests, resource reads, script full-type
reads, modal behavior, keyboard registration and the installed EN JSON format.
Selected installed native declarations corroborate GameEntity.getEntityScript,
BaseScriptObject.getScriptObjectFullType, Item.getActualWeight and InventoryItem.
hasModData. Native declarations and online documentation do not prove Lua
invocation: the preview guards every object getter and leaves unavailable reads
unknown. Those bindings still require native testing before promotion to runtime
evidence, and none authorizes a gameplay mutation.

References: [GameEntity](https://projectzomboid.com/modding/zombie/entity/GameEntity.html),
[GameEntityScript](https://projectzomboid.com/modding/zombie/scripting/entity/GameEntityScript.html),
[Item](https://projectzomboid.com/modding/zombie/scripting/objects/Item.html),
[InventoryItem](https://projectzomboid.com/modding/zombie/inventory/InventoryItem.html).
These online references are unpinned corroboration. The installed class hashes
and explicit scope in the evidence file are the build-bound record.

## Validation and next runtime gates

Offline Lua 5.1 coverage includes failed/unknown/NaN reads, partial weight, nested
ownership, poisoned/cooked/frozen states, markup sanitation, exact selection,
stale menu activation, scan bounds, disabled toggle, duplicate event loading,
controller test mode, client/server loading, resize-safe close controls and no
speed-control access. Translation keys use EN JSON with vanilla language fallback;
no other language is claimed translated. Existing regression suites still apply.

Run the exact commands in TESTING.md. Source/static checks do not validate UI
layout, live method dispatch or controller behavior in PZ. In disposable SP and
dedicated fixtures, inspect both native rack variants, individual/partly eaten
apples, stale/removed objects and nested inventories. Verify scrolling at scale,
split-screen, Escape/controller close and unchanged game speed. Dedicated client
presentation remains NOT TESTED; the prototype owns no shared state. Project G7
remains BLOCKED / NOT TESTED and stable G8 BLOCKED for production drying.
