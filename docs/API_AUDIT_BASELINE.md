# foodWorks Build 42.20.3 API Audit Baseline

Installed target: Project Zomboid `42.20.3` (`70207f62e0`).

## Confirmed installed Lua surfaces

- Vanilla Lua reads and mutates `Food` age and checks fresh, rotten, frozen, cooked, and burnt state.
- Inventory UI exposes cooking progress and nutrition information.
- Vanilla uses `RecipeManager`, `CraftRecipeManager`, evolved recipes, unique recipes, and `ISAddItemInRecipe`.
- Nutrition state is exposed through the player nutrition object and synchronized by existing command paths.
- Farming, foraging, trapping, animals, and butchery already exchange food state with vanilla systems.

## High confidence, requiring isolated prototypes

- A read-only FoodAdapter and script-field inventory.
- An ingredient/capability registry that preserves vanilla recipe authority.
- One bounded preservation process through save/load without nutrition or portion duplication.

## Experimental

- Multi-stage fermentation, curing, smoking, drying, and canning.
- Bulk food processing and cross-container planning.
- Dedicated-server synchronization for long-running processes and third-party food compatibility.

The former Nightfall deferral is obsolete. Runtime development is authorized;
current read-only behavior and the still-unproven mutation boundary are
documented in `ARCHITECTURE.md` and `PRESERVATION_RUNTIME_AUDIT.md`. This file
remains the API-confidence baseline only.
