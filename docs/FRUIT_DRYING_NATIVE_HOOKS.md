# Native apple-drying hook decision

Audit baseline: 0.8.0-dev.1, merged commit
`77771cbf27c0b0ea1b5812c23798c53e8f37b1a3`, October 17, 2026.
Installed Build 42.21 / Steam build 25485521. **Production remains BLOCKED.**

This follow-up traces the native implementation behind the previous API
declarations. It does not execute game classes, launch a game/server, register a
recipe/item, or modify the installed game. Findings describe the packaged classes;
matching loose classes are checked where present. They do not certify the Steam
installation or determine which classes a modified launcher loads.

## Verified static control flow

The evidence file fingerprints seven installed classes. Offsets below are bytecode
instruction offsets, not source lines. Native behavior and Lua invocation remain
distinct from offline inspection.

| Finding | Installed control flow | Consequence |
| --- | --- | --- |
| H01 | `CraftLogicSystem.updateSimulation` returns on GameClient; `start` repeats `canStart`, consumes inputs, invokes native `onStart`, then `luaCallOnStart` | [VERIFIED: native inspection] Native simulation is the intended server/SP owner. Start callback is after consumption, with no Boolean veto. Connection/actor/reach security is not fully established by this finding. |
| H02 | `CraftRecipeData.luaCallOnTest()` is only `iconst_1; ireturn` | [VERIFIED: native inspection] This recipe-level method cannot gate work. It must not be confused with the per-item test. |
| H03 | `CraftRecipeManager.consumeInputItemInternal` calls the parent recipe's `OnTestItem`; `CraftRecipe.OnTestItem(item, character)` resolves OnTest and uses `protectedCallBoolean` | [VERIFIED: native inspection] A separate per-item Boolean hook exists in resource consumption. A missing function resolves to acceptance; a resolved callback returning nil/false rejects. Live dispatch and rack actor context remain NOT TESTED. |
| H04 | `CraftLogicSystem.stop` calls `createOutputs` (45), then `luaCallOnCreate` (52), then finalization (101). `createOutputsInternal` calls `destroyAllSurvivingDestroyInputs` after creating outputs and before returning | [VERIFIED: native inspection] OnCreate is post-output/post-destruction. It is not a transactional commit predicate or rollback hook. |
| H05 | `createRecipeOutputs` creates items then distributes them; distribution calls `Resource.offerItem(item,true,true,true)`; `ResourceItem.offerItem` synchronizes on the server when its last Boolean is true | [VERIFIED: native inspection] Output resource synchronization is requested before OnCreate. Post-create food setters require a separately verified resource resynchronization route; progress synchronization alone is insufficient proof. |
| H06 | Start/update/create/failed Lua dispatchers return void and use protected void calls | [VERIFIED: native inspection] Returning false or throwing cannot be treated as native cancellation. A custom quarantine flag alone cannot recall an already-created/synchronized output. |
| H07 | `CraftRecipe` declares time getters, no `setTime`. `DryingCraftLogic` advances in game seconds with native drying-factor adjustment | [VERIFIED: native inspection] Base recipe duration is game seconds, not an arbitrary Lua timer. No supported mutable duration binding was established; 48 hours would be 172800 base game seconds, subject to native environmental effects. |
| H08 | `CraftRecipeData.save/load` serializes elapsed time, input data, and nonempty job ModData | [VERIFIED: native inspection] Native per-job scalar snapshots are a credible lead. Lua exposure, live schema survival, restart/cancel behavior and inventory crash consistency remain NOT TESTED. |

The checker verifies the central call sequences and class fingerprints. H01's
client guard and H07's environmental update were additionally inspected manually;
the checker does not claim to prove every security branch or a complete native
transaction. No raw game source or bytecode dump is stored in this repository.

## Food inheritance does not close the remaining gates

Native input flags include whole-food and uncooked checks. Output creation also
supports `InheritFood`, `InheritFoodAge` and native food age copying. These are
useful leads, not proof of this process's complete contract. In particular:

- Whole-food checks alone do not prove absence of poison, taint, custom state,
  frozen/thawing state or other unsupported transformations.
- Native age inheritance does not by itself establish that a detached, consumed
  apple ages correctly throughout drying, unload, save and restart.
- A post-create correction has to address both server state and the resource
  snapshot already sent to clients. Ordinary inventory item-stat synchronization
  must not be assumed to cover an entity resource.
- The callback must reject rotten/invalid input at completion without first
  exposing edible output. That pre-output veto/validated mapping route has not
  been established. A protected Lua exception does not supply one.

It would be possible to investigate pre-authored duration variants selected by
server-side per-item tests. That avoids an invented time setter, but still needs
supported recipe discovery, correct server selection, persistent settings identity,
and safe completion. It does not solve the output ordering problem by itself.

## Implementation decision and Lua-only alternative

Do not register a production apple recipe or spawn dried food using these findings.
The global authority rule requires stopping affected gameplay implementation when
a safe model cannot be established. This is an engineering blocker, not an
approval request and not a claim that every Lua-only solution is impossible.

First pursue a verified native pre-output mapping/validation route and resource
resynchronization, retaining a single native clock and completion owner. If those
cannot enforce the contract, the alternative is a separately designed Lua-only,
server-owned process using an exclusive recoverable input holder and a durable
reservation/completion journal. It must prove exact item ownership, scalar save
state, once-only collection, interrupted commits, cancellation and restart before
being enabled. Do not silently put a second timer over the native job or reuse the
generic framework without supplying those missing guarantees.

Canonical VERSION remains 0.8.0-dev.1: only audit documentation and offline tooling
change. A compatible working-drying checkpoint would target **0.8.0-dev.2** within
the existing MINOR development line; it is not applied or claimed implemented.
All legacy identifiers and current runtime bytes are preserved.

## Reproduction and runtime gates

Use Python with development-only `jawa==2.2.0` on PYTHONPATH (or installed in an
isolated development environment), then:

```powershell
python scripts/check_native_drying_hooks.py --game-root '<verified installed game root>' --steam-build 25485521
python scripts/check_versions.py --root .
python scripts/run_checks.py
```

`run_checks.py` additionally requires the existing `lupa.lua51` test dependency.
PASS from the hook checker means the recorded static limitations match the
installed files. It does not mean apple drying works. Native SP and dedicated
tests have not been run. G7 BLOCKED / NOT TESTED; stable G8 BLOCKED. No package,
deployment or Workshop publication is produced.
