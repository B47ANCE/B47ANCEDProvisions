# B47ANCE’d Provisions Architecture

B47ANCE’d Provisions owns normalized food and ingredient classification, food processing and preservation definitions, food-state transitions beyond vanilla coverage, food safety, portion and nutrition accounting, and food-production integration contracts.

Vanilla remains authoritative for `Food`, item age, freshness/rottenness, freezing, cooking/burning, nutrition, recipes, evolved recipes, crafting execution, appliances, and synchronization wherever those systems already provide the needed behavior.

Provider boundaries:

- farmWorks owns crops and agricultural production.
- animalWorks owns animals and animal-product production.
- waterWorks owns fluid volume and quality.
- powerWorks owns appliance energy supply and consumption.
- weatherWorks owns normalized climate observations.
- uiWorks owns presentation components; foodWorks supplies food-domain data.

The first runtime component must be a read-only `FoodAdapter`, followed by an ingredient registry. Persistent preservation processes require duplication, save/load, refrigeration, and multiplayer proof before content expansion.

## Identity compatibility

Version 0.7.0 uses Mod ID `B47ANCEDProvisions`; the legacy `foodWorks` API,
module paths, sandbox option and persistence keys remain stable. No gameplay,
state ownership, server authority, networking or sandbox behavior changes.

## Implemented foundation

The [fruit-drying design](FRUIT_DRYING_DESIGN.md) proposes native rack crafting
as the single owner of a future apple-drying job. This is not implemented and
does not change the generic framework. Avoid a second custom timer or output
creator for a native craft. [Audit evidence](FRUIT_DRYING_API_AUDIT.md) separates
observed client/shared calls from unproven server authorization, save/reload and
food-state mapping. Existing Lua/save identifiers remain unchanged.

`foodWorks/API.lua` implements ordered food providers and a normalized ingredient
registry. Its vanilla provider reads `Food` age thresholds, rotten/cooked/burnt/
frozen state, heat, cooking progress, hunger/thirst effects, and macronutrients.
Freshness labels are derived views only; vanilla item age remains canonical.
Version 0.4.0 protects registry ownership by returning detached ingredient
snapshots from registration, lookup, and food inspection. Consumers cannot
mutate canonical tags, processes, category, or provider identity through a
returned view. Provider definitions are also snapshotted at registration, so
later mutation of the caller's table or returned registration record cannot
replace canonical matching and inspection callbacks. Inspection decorates a
detached top-level view rather than writing ownership metadata into the
provider's result table.

Long-running preservation processes and portion mutation are intentionally not
implemented until authority, save/load, and duplication tests exist.

Version 0.2.0 extended the read-only adapter across vanilla preservation state:
packaging, taint, freezing/thawing, freezing progress, last aging time, rotten
replacement, and compost/rot timers. These values remain vanilla-owned. The
runtime audit confirms native item serialization and clone/mutation methods
exist, but does not establish a safe authoritative replacement transaction or
multiplayer synchronization contract, so foodWorks still performs no mutation.

Version 0.3.0 adds a client-only inventory presentation over that same API. It
accepts exactly one selected food item, formats a sanitized report, and never
sets item state or submits a command. The context-menu callback is contained so
an unsupported or malformed third-party item cannot break the inventory menu.
Presentation may be disabled independently through the default-on sandbox
option; provider ownership and vanilla authority are unchanged.

Version 0.5.0 adds `ApplianceTransactions`. foodWorks owns process ordering and
the appliance recovery marker; powerWorks owns energy reservation and waterWorks
owns reserved drains. Exact registered resource quantities are reserved before
the content owner commits its outcome. A false process result guarantees no
outcome and triggers both rollbacks. A raised/ambiguous outcome or failed
post-outcome resource commit stays quarantined rather than duplicating output or
guessing rollback. No process content is registered by this foundation.

Version 0.6.0 adds the persistent `PreservationProcesses` state machine.
Definitions contain exact input identity/quantity/protection, station capability,
eligibility, duration, cadence, and observation callbacks. Jobs retain scalar
stable identities and bounded operation/observation histories. Inputs are
reserved before attachment; elapsed catch-up is capped at seven days per call;
spoilage is explicit; cancellation delegates release to the same provider; and
completion records the in-flight state before the provider creates output.
Ambiguous release or output remains quarantined. The engine-independent store is
ready for a server persistence owner, but no gameplay definition is registered.
