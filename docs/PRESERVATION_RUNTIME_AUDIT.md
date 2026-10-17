# Build 42 Preservation Runtime Audit

This audit uses the locally installed Build 42.20 Lua source and the official
Project Zomboid Java API documentation. It establishes what foodWorks may read
now and what remains unproven for authoritative preservation gameplay.

## Verified native state

The official [`Food` API](https://projectzomboid.com/modding/zombie/inventory/types/Food.html)
exposes food-specific `save`/`load`, `getFreezingTime`, `setFreezingTime`,
`freeze`, `isFrozen`, `setFrozen`, `isFreezing`, `isThawing`, packaging, taint,
rot/compost timers, and rotten-replacement state. Its private fridge/freezer
checks and age multipliers show that vanilla already owns refrigeration and
freezing behavior.

The official [`InventoryItem` API](https://projectzomboid.com/modding/zombie/inventory/InventoryItem.html)
exposes native item serialization, `createCloneItem`, age accessors, ModData,
and item-field synchronization. Installed Lua uses `createCloneItem` in the
client inventory debug duplication command, which is evidence that the method
exists—not evidence that client-side cloning is a safe gameplay transaction.

## Implemented boundary

foodWorks reads and normalizes the preservation-relevant state above. Version
0.3.0 exposes it through an optional read-only inventory report. It
does not set those fields, clone items, or replace inputs. Vanilla age,
temperature, refrigeration, freezing, serialization, and item ownership remain
authoritative.

## Remaining proof before mutation

An authoritative preservation transaction still needs:

1. A server-owned input reservation that revalidates exact item identity and
   container ownership at completion.
2. A verified way to create or transform output while preserving the intended
   age, portions, nutrition, custom state, and third-party fields.
3. Rollback or quarantine behavior for failure after input removal or output
   insertion; duplicating food is not an acceptable recovery strategy.
4. Save/reload proof for active processes and transformed items.
5. Hosted and dedicated multiplayer proof for inventory synchronization,
   interruption, reconnect, and replay.

Until those tests can run in Project Zomboid, preservation mutation remains
blocked. No recipe, timing, yield, spoilage multiplier, or migration policy is
inferred by this audit.
