# Jams and jellies

Project Version: 0.8.0-dev.4

## Playable source slice

Stand directly beside a powered non-microwave vanilla stove that is switched on and has reached
100 C. Carry all ingredients and tools directly in the main inventory (at most
256 items). Right-click the stove and choose **Make [fruit] jam** or **Make [fruit]
jelly (strain pulp)**. There is no custom crafting window or native recipe override.

Each batch uses one selected whole fresh fruit, one additional whole fresh apple
for natural pectin, eight whole `Base.SugarCubes` items, one empty `Base.EmptyJar`
and one pristine `Base.JarLid`. Apple preserves therefore use two apples. Supported
selected fruits are Apple, Blackberry (`BerryBlack`), Blueberry (`BerryBlue`),
Cherry, Grapes, Peach and Strawberry (`Strewberrie`), all vanilla `Base` types.
Require and keep an empty `Base.Pot` and usable `Base.KitchenKnife`. Jelly also
requires and keeps `Base.Strainer` and `Base.CheeseCloth`. These are apple-assisted
game recipes: heated preparation and jar heat processing are one attended action
using the fruit's own moisture. They are not real-world canning instructions.

Only whole, default, fresh, non-poisoned, non-frozen, uncooked and unmodified
ingredients qualify. Foraged instances with different food values/metadata can
be rejected. Filled jars/pots, damaged lids, stale food, dried fruit and partially
used sugar are rejected. Other vanilla jar types, sugars, heat sources and fruits
are not silently substituted. No vanilla food, recipe, script or Lua class is
overridden. Existing vanilla vegetable/roe jarring and native plant drying remain
available through vanilla systems.

Jam retains all input food values. Jelly defaults to 70% of both fruits' food
values plus 100% of sugar; the remaining 30% returns as edible strained fruit pulp.
Calories, carbohydrates, fat, protein, hunger and food effects are summed/split;
jar and lid contribute mass only. There is no duplication of sugar in the pulp.
Pulp has 1/2-day fresh/rotten thresholds. Juice yield is a game-wide proportional
model, not a claim about nutrient-specific extraction or fiber simulation.

The sealed jar cannot be eaten or used as a native evolved-recipe ingredient.
Right-click it in inventory to **Open [name]**; this returns a vanilla lid and an
opened preserve. Eat normally or use it in the declared vanilla sandwich, pancake,
toast, bread and oatmeal preparations. Finishing an opened jar uses vanilla
`ReplaceOnUse = Base.EmptyJar`. Icons and held/world models reuse vanilla JamFruit.
Jelly has its own item identities and straining yield, with the same vanilla art.

## Age, configuration and persistence

The worse fruit's age/fresh-threshold ratio is carried into the sealed jar and
pulp. New jars default to 30/60 days. For example, fruit halfway through its fresh
period yields a jar aged 15 days with a 30-day fresh threshold. Opening scales
the jar's current ratio onto 3/6 days, so even a stale/rotten jar is never refreshed.
Poison/freeze/taint checks also apply when opening. Native food aging, refrigeration,
freezing, eating, inventory/world saves and added-item replication own the results.

Server sandbox options (existing saves receive defaults for missing options):

| Stable identifier under `foodWorks` | Default | Bounds and meaning |
| --- | --- | --- |
| `EnableSweetPreserves` | true | Stops new batches when false; opening existing jars remains available |
| `SweetPreservesShelfLifeDays` | 30 | Integer 7–180, step 1; sealed rotten threshold is twice this |
| `SweetPreservesTimeMultiplier` | 1 | Integer 1–5, step 1; multiplies native action units: jam 600, jelly 900, open 40 |
| `JellyJuiceYieldPercent` | 70 | Integer 25–90, step 1; fruit food values split between jelly and pulp |

Settings are read/validated by the server. Accepted settings stay in the active
server action; completed jars retain their actual native fields when settings
change. Invalid settings fail closed. Heat threshold, ingredient constitution,
open/pulp spoilage ratios, exact type IDs, scan limits and network-constructor
shape define the process/safety contract rather than extra per-item options.
Default template snapshots are cached per full type to avoid repeated factory
allocations during action validation. No global/per-tick world scan is added.

New identities: `foodWorks.JamSealed`, `foodWorks.JellySealed`,
`foodWorks.JamOpened`, `foodWorks.JellyOpened`, `foodWorks.StrainedFruitPulp`.
There is no new custom persistent ledger/schema. A bounded transient server intent
table is discarded on restart; it holds no consumed food or output. Native inventory objects persist
all food state; localized custom names are presentation only. Keep this mod enabled
while these items exist. No downgrade conversion is provided. Existing drying
IDs, data, settings and recovery paths are unchanged.

## Authority and native API audit

[VERIFIED source/static inspection] Installed Build 42.21, Steam build 25485521.
`SWEET_PRESERVES_EVIDENCE.json` binds the exact inspected files/classes and authored
source. No game classes were executed or modified during inspection.

- `NetTimedAction.set` serializes constructor parameter fields by their Lua local
  names. `parse` calls the global class constructor and supplies `netAction`.
  Player arguments use native PlayerID parsing (normal local indices resolve
  against the sending connection; the native ID fallback is not treated as
  sufficient authorization). Only `character`, `fruit`, `object`, `mode`,
  `grantId` are constructor arguments; none can authorize gameplay by themselves.
  No nutrition, output type, settings, timer or server proof comes from the client.
  Server-only `_plan`/`_finished` are reconstructed, not serialized.
- Native `NetTimedAction.start` calls `serverStart`; timing uses server time and
  Lua `getDuration`. `perform` calls `complete`. `LuaTimedActionNew.complete` skips
  Lua completion on the client. The subclass does not override native action
  processing or globally patch crafting; its authorization handler is separate.
- An authenticated `OnClientCommand` request uses the actual event player, never
  a payload actor. It resolves the exact fruit and stove, validates ingredients,
  and stores one server-owned authorization per actor. The reply allows the client
  to queue the native action. A grant binds actual actor/fruit/stove/mode/inputs;
  one actual server action can claim it. Completion requires that same active
  authorization and invalidates it before mutation. Cancel/replacement revokes it.
  No guessed action arguments can create a new authorized transaction. Requests
  are limited to four/second/actor and 128 global outstanding grants; unused grants
  expire after ten wall-clock minutes. These are internal protocol safety limits.
- The server validates actual actor inventory ownership, allowed mode/type,
  exact selected fruit, all other ingredients/tools, same-floor cardinal stove
  access, both-direction obstruction, power, activation and current temperature.
  Native action validity plus completion rechecks handle movement/cooling. Replays
  have no original fruit or no server-start proof; the same action finishes once.
- `LuaManager.Exposer` registers Food, InventoryItem, ItemContainer and IsoStove;
  inspected public methods supply food setters/getters, native removal and heat.
  Registration and source calls are static binding evidence; actual dispatch is
  still a runtime gate. Newly authored food definitions follow installed B42 syntax.
- Results are created with `instanceItem`, initialized and read back while detached.
  Preparation failure leaves every input untouched. Removal failure attempts to
  restore the exact original objects before any output is published, never cloned
  ingredients. All confirmed removals precede added-item publication.
- Vanilla `Actions.addOrDropItem` adds the initialized object, drops it to the world
  when overloaded, and sends the full added item when it remains in inventory.
  Input removals use `sendRemoveItemFromContainer` on the dedicated server. Native
  save/load and full-item transfer replace custom item-stat synchronization.

The previously recorded native first-input inheritance and post-publication
`OnCreate` blockers remain true. This route bypasses them; it does not promote
native callbacks into vetoes. The legacy `RecipeManager.validateCanPerform` body
returns false in this installed build, so that abandoned route is not used.

## Failure boundaries and validation

Cancellation or restart before completion and invalidation consume nothing.
Disconnect handling also relies on native action cancellation; this needs runtime
validation. An abandoned authorization expires without consuming anything.
An active action is not persisted/resumed; start a new action with retained inputs.
Once all inputs are removed, the transaction never rolls back/regenerates after
publication starts. An unexpected native delivery/sync exception is logged and
does not retry; it may lose some output or leave a client stale. A server crash
between debit and output save can also lose a batch. No crash-atomic transaction
or recovery across native player/world save ordering is claimed. Native transfer
failures are mandatory runtime tests, not hidden by successful synthetic mocks.

[TESTED offline, Lua 5.1] Authority, input/heat rejection, nutrient/mass conservation,
jelly/sugar split, carried/opened age, settings, single completion, moved inputs,
cancelled actions, pre-debit setter failure, removal rollback, no retry after delivery
failure, client no-op completion, authorization denial/revocation/expiry/single claim, intent-only menus and production loading.

```powershell
python scripts/run_checks.py
python scripts/check_versions.py --root .
python scripts/check_sweet_preserves.py --game-root '<installed game root>' --steam-build 25485521
```

[RUNTIME GATE] Native SP and dedicated NOT TESTED. G7 BLOCKED / NOT TESTED; stable
G8 BLOCKED. Test native action construction/timing/cancel/forged mode, each actual
vanilla input, cold/unpowered/blocked/destroyed stoves, repeated/concurrent actions,
hot-to-cold interruption, overloaded output drops, native eating/evolved recipes,
empty-jar/lid return, age across refrigeration/opening, partial eating, save/reload,
late join/rejoin, disconnect during action and dedicated restarts. No game/server
launch, package, deployment, Workshop publication or stable-release tag authorized.
