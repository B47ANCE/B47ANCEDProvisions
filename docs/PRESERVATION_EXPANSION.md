# Vanilla preservation expansion

Project Version: 0.8.0-dev.4

## Implemented checkpoint

The existing Lua-only, server-owned drying path now recognizes 22 exact vanilla
fruit types. Apple remains compatible; 21 additional identities can use the same
process. New jobs bind both native item ID and full type in the private ledger.
Nothing can request an arbitrary output type. Old v1 jobs without a type remain
Apple jobs. Unknown schemas/types fail closed and their data is retained.

Supported: Apple, Banana, Cherry, Grapefruit, Grapes, Lemon, Lime, Mango, Orange,
Peach, Pear, Pineapple, Strewberrie, BerryBlack, BerryBlue, BeautyBerry, WinterBerry,
and BerryGeneric1 through BerryGeneric5, all in `Base`. Only whole/default, fresh,
non-poisonous, unmodified items pass the server's actual eligibility checks.
Instance-specific foraged nutrition or foreign metadata can cause rejection;
the whitelist alone is not a guarantee of an accepted item.

An empty small-plant rack offers one start action per supported fruit type found
in the bounded main-inventory scan, using the exact first fresh item of that type.
The client sends only item/rack intent. The server owns validation, progress,
transformation and full native resource synchronization. Cancel, resume and
collection retain the original exact-ID transfer rules.

Default duration stays 48 observed loaded game hours and shelf-life factor stays
6, using the existing server sandbox options. Accepted settings stay with each
job. Age scales with freshness thresholds, weight becomes one quarter, thirst
benefit becomes zero, and nutrients/hunger remain unchanged. There are no new
per-fruit micro-settings. Identity/localization and the audited recipe whitelist
are implementation contracts; unsupported item types cannot be made safe by a
configuration toggle. Previous saves gain the additional eligibility when enabled.

Outputs retain their own original base types and vanilla visuals, with localized
custom names (for example `Base.Grapes` named Raisins). No actual `Base.Raisins`
type is invented. The new apple art/model remains an authoring asset pending
verified per-item visual selection. This is not a general processed-food engine.

## Adopted catalog and remaining work

`PRESERVATION_CATALOG.csv` retains all 149 reviewed vanilla ingredient identities
and their primary/alternative methods. Each row has an implementation status.
The catalog is data/documentation, not recipe registration. All proposed foods
are still vanilla inputs; future preserved outputs require their own contracts.

| Family | Intended additions | Current status |
| --- | --- | --- |
| Fruit drying | The 22 profiles above | Implemented in source; offline tested |
| Sweet preserves | Jam and strained jelly for seven vanilla fruit choices, using an additional apple | Implemented via vanilla server timed actions; offline tested. Marmalade, butter, fruit jars and leather remain deferred |
| Pickling | Cucumber, onion, cauliflower, Brussels sprouts, daikon, turnip, zucchini, garlic, ginger, green onions, grape leaves | BLOCKED: vinegar/water/salt consumption and jar processing |
| Meat/fish preservation | Prepared salted fish; lean-meat jerky; cut-specific curing/smoking | BLOCKED: ingredient/holder authority, preparation and heat stages |
| Fermentation | Cabbage sauerkraut first; other brined vegetables later | BLOCKED: authoritative brine consumption, sealed-holder lifecycle and completion |
| Additional drying | Prepared vegetables/mushrooms, roots/herbs, later cooked protein | BLOCKED: preparation, poison/medicinal effects and controlled-heat contracts |

Reuse existing vanilla drying for its 21 edible inputs. Native `MakeJar` already
maps bell pepper, broccoli, cabbage, carrots, eggplant, leek, potato, radish,
tomato and fish roe. Do not duplicate those methods. Cabbage fermentation and
tomato dehydration would be distinct additions. Vanilla finished jam, marmalade,
pickles and jerky items do not themselves establish production recipes.

Watermelon forms, rose hips and questionable berry identities are not silently
accepted by this checkpoint. Required preparation is not inferred from a food
type. Poison/spoilage must never be cured by drying. Tofu, avocado and lettuce
remain deferred instead of receiving arbitrary shelf-stable transformations.

## Native callback limits and the alternative sweet-preserve route

Installed evidence is Build 42.21 / Steam build 25485521, inspected without
executing or modifying game classes. `PRESERVATION_EXPANSION_EVIDENCE.json` binds
the relevant installed files/classes and current authored files.

1. [VERIFIED source] `ISHandcraftAction` rebuilds server handcraft logic in
   `serverStart`; its dedicated `complete` calls `performRecipe`. That method
   adds/drops created output items before invoking `luaCallOnCreate`, then
   processes destroyed/used inputs. A post-create callback is not a pre-output
   validation or rollback predicate.
2. [VERIFIED native inspection] `CraftRecipeData.createOutputItems` obtains the
   **first** input carrying `InheritFood` and calls `copyFoodFromSplit`. That does
   not sum fruit plus sugar nutrition. Native `copyFoodFromSplit` also copies
   frozen/cooked/poison/age/extra-item state. A flag alone cannot establish the
   multi-input preservation contract.
3. [VERIFIED native inspection] `Food.update`'s `ReplaceOnCooked` branch adds a
   new item, copies condition state, sends the added-item result and removes the
   original. The inspected replacement interval has no nutrition/age-copy call.
   This does not establish a safe generic heat-to-preserved-food transformation.
4. [VERIFIED source/static] The new [sweet-preserve route](SWEET_PRESERVES.md)
   uses native `NetTimedAction` server construction/timing/completion, exact
   inventory ownership checks, detached food initialization and vanilla
   `Actions.addOrDropItem` full-item synchronization. It bypasses those native
   callbacks and accounts for all fruit/sugar values before publication.

Jam and jelly are implemented for Apple, BerryBlack, BerryBlue, Cherry, Grapes,
Peach and Strewberrie. Each uses an additional apple for pectin, eight SugarCubes,
an empty jar and pristine lid, tools and attended hot-stove processing. Jelly
splits fruit values into jelly plus edible pulp; sugar remains in the jar.
Sealed/opened identities and relative-age transfer are explicit. Other sweet
processes and pickling/curing/fermentation remain unimplemented. The original
negative findings remain true; the alternative is not a callback rollback fix.

## Validation and remaining gates

```powershell
python scripts/run_checks.py
python scripts/check_versions.py --root .
python scripts/check_preservation_expansion.py --game-root '<installed game root>' --steam-build 25485521
python scripts/check_apple_drying_evidence.py --game-root '<installed game root>' --steam-build 25485521
```

[TESTED offline, Lua 5.1] Every profile follows the production server path with
different fixture nutrients/weights. Checks cover exact-type binding, nutrient
conservation, carried age, repeated collection, forged public type/progress,
partial/poisoned/unsupported foods, legacy Apple v1 jobs, and client intent-only
menus. Existing interruption/restart/access tests remain active. Native source
fingerprints are current static evidence, not execution or an integrity certificate.

[RUNTIME GATE] SP and dedicated NOT TESTED. G7 BLOCKED / NOT TESTED; stable G8
BLOCKED. Native save/reload, partial conversions, foraged-food eligibility,
late join/rejoin, concurrent access and station destruction require live tests.
No downgrade migration exists for new fruit jobs; preserve backups. Older code
does not understand their optional type field. Legacy Apple module/network/save
identifiers and sandbox IDs remain unchanged. No package, deployment or publication.
