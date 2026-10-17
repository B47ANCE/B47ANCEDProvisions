# B47ANCE’d Provisions

B47ANCE’d Provisions (formerly foodWorks) is the planned food-production, cooking, preservation, spoilage, storage, nutrition, and food-safety framework for the theWorks ecosystem. It extends Build 42 food and crafting systems instead of replacing them.

- Status: version `0.8.0-dev.1` adds a read-only rack/apple drying preview to the food inspection and preservation foundations. No production process is registered; this is not yet a gameplay release.
- Mod ID: `B47ANCEDProvisions`
- Author: B47ANCE
- Source: [B47ANCE/B47ANCEDProvisions](https://github.com/B47ANCE/B47ANCEDProvisions) (public).
- Hard dependencies: none beyond Project Zomboid.
- Planned integrations: farmWorks, animalWorks, waterWorks, powerWorks, weatherWorks, and uiWorks.
- Non-goals: replacing vanilla `Food`, replacing Build 42 crafting, or duplicating provider-owned crops, animals, fluids, power, or weather.

The detailed research program is preserved in [docs/B42_API_RESEARCH_HANDOFF.md](docs/B42_API_RESEARCH_HANDOFF.md). The current API reads vanilla-owned age, freshness, cooking, freezing, heat, hunger/thirst, and nutrition state and allows third-party ingredient classification without mutating food items. Steam thumbnail and in-game icon metadata use the staged existing project assets.
Approved feature research is allocated in [docs/ROADMAP.md](docs/ROADMAP.md).

`ApplianceTransactions` lets first-party process definitions reserve exact
power and water, perform one owner-defined outcome, then commit both resources.
A declared rejection rolls both reservations back; an ambiguous process or
post-outcome resource commit remains quarantined on the appliance. Definitions
must match the exact appliance and supply stable appliance/water identities.

`PreservationProcesses` owns bounded persistent jobs over registered definitions.
Definitions freeze exact protected inputs, station capability, eligibility,
duration, cadence, and environmental observation. Reservation, cancellation,
spoilage, ready state, replay-safe completion, and uncertain-output quarantine
are host-tested. The [first-process design](docs/FRUIT_DRYING_DESIGN.md) selects
apple drying at a native small-plant rack as the candidate; no production item,
recipe or station integration is registered. The [API audit](docs/FRUIT_DRYING_API_AUDIT.md)
records installed Build 42.21 / Steam build 25485521 evidence and the authority,
food-state, configuration and persistence blockers before implementation.

The normalized view now includes packaging, taint, freeze/thaw progress,
last-aging time, rotten replacement, and compost/rotting timers. See
[docs/PRESERVATION_RUNTIME_AUDIT.md](docs/PRESERVATION_RUNTIME_AUDIT.md) for the
verified persistence and authority boundary that still blocks mutation.

Right-click one food item and choose **Inspect Food State** to view that
normalized state without changing the item. The option is enabled by default and
can be disabled with `foodWorks.EnableFoodInspection`.

## Identity and compatibility

The project and mod folder are `B47ANCEDProvisions`. Workshop item `3788591331`
is unchanged. Replace the enabled Mod ID `foodWorks` with `B47ANCEDProvisions`
in launcher/server configuration when deploying this rename; do not enable both
identities. No installed copy or server configuration was changed here.

The public `foodWorks` Lua global, `require "foodWorks/..."` module paths,
`foodWorks.EnableFoodInspection` sandbox option and translation identifiers,
and `foodWorks.*.v1` persistence keys intentionally remain compatible. A Mod ID
change does not establish save compatibility: existing-save load and dedicated
join/rejoin still require native testing.

Authoritative source: `Contents/mods/B47ANCEDProvisions`; no parallel `src/` tree.
Canonical project version: root `VERSION`; mirrors: `version-inventory.json`.
See [versioning](docs/VERSIONING.md), [identity migration](docs/IDENTITY_MIGRATION.md),
and [testing](docs/TESTING.md) for commands and evidence boundaries. Historical
ZIPs, staging backups, upload hashes and original research remain historical.
The 0.7.0 rename was merged through PR #1; its design audit remains historical.
The [0.8.0-dev.1 inspection prototype](docs/FRUIT_DRYING_PREVIEW.md) adds localized
context actions for one apple or a clicked native rack. It reports failed/unknown
prechecks, never claims whole-item eligibility and cannot start drying. Disable
the display with `foodWorks.EnableFruitDryingPreview`. Production mutation remains
blocked on the documented API, authority and runtime gates.
No current package, deployment or Workshop publication is claimed. Offline checks
pass; SP and dedicated multiplayer remain NOT TESTED, with G7 and stable G8 blocked.
