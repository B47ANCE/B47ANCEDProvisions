# foodWorks — PROJECT ZOMBOID BUILD 42
# VANILLA COOKING, FOOD PREP, SPOILAGE & FOOD API DEEP-DIVE
#
# Food Ingredients, Cooking, Recipes, Preservation, Spoilage, Storage,
# Food Safety, Processing, Nutrition & Cross-Works Food Framework

TARGET:
Project Zomboid Build 42.20+ Stable

PROJECT:
foodWorks

MISSION:

Turn Project Zomboid's existing food, cooking, recipe, nutrition and spoilage
systems into a comprehensive food-production and preservation framework.

foodWorks should NOT replace vanilla Food or Build 42 crafting.

foodWorks should extend and normalize:

- ingredients;
- food categories;
- preparation;
- evolved recipes;
- cooking;
- baking;
- roasting;
- frying;
- boiling;
- smoking;
- drying;
- curing;
- fermenting;
- canning;
- pickling;
- freezing;
- refrigeration;
- root-cellar/cool storage;
- food spoilage;
- food safety;
- leftovers;
- bulk cooking;
- food processing;
- butchered agricultural products;
- dairy processing;
- grain processing;
- preservation equipment;
- cooking equipment;
- recipe knowledge;
- third-party food APIs.

Core principle:

VANILLA OWNS THE FOOD ITEM.

foodWorks OWNS THE FOOD SYSTEM AROUND IT.

======================================================================
0. FUNDAMENTAL ARCHITECTURAL FINDING
======================================================================

Project Zomboid already provides several distinct food layers:

InventoryItem
    ↓
Food
    ↓
age / fresh / rotten
cooking
freezing
nutrition
hunger / thirst
poison / food-safety state

Recipe
    ↓
fixed crafting transformation

EvolvedRecipe
    ↓
base meal
    +
ingredients
    +
spices
    ↓
dynamic meal

B42 Crafting
    ↓
recipes
workstations
tools
ingredients
skills
knowledge

Therefore:

DO NOT BUILD:

foodWorksFood
foodWorksCookingTime
foodWorksRotten
foodWorksNutrition

as parallel canonical state.

Build adapters around vanilla.

======================================================================
1. CONFIDENCE CLASSIFICATION
======================================================================

Every capability should be classified:

CONFIRMED

    Verified against current B42.20 runtime/repository or a working current
    implementation.

HIGH

    Engine/API support is strong but needs production validation.

EXPERIMENTAL

    Plausible, but exact recipe/cooking/storage/MP behavior requires a spike.

BLOCKED

    No clean current implementation path.

UNVERIFIED

    Documentation suggests support but current stable runtime has not been
    inspected.

Critical:

OLD B41 JAVADOC
!=
CURRENT B42 LUA CONTRACT.

B42 RECIPE REWORK
!=
ASSUME LEGACY RECIPE BEHAVIOR.

Codex must inspect current B42.20 scripts.

======================================================================
2. FOOD CLASS
======================================================================

zombie.inventory.types.Food is the central vanilla food runtime type.

Research shows it inherits InventoryItem and exposes food-specific state.

Relevant known concepts include:

- hunger change;
- thirst change;
- calories;
- carbohydrates;
- proteins;
- lipids;
- boredom;
- unhappiness;
- fatigue changes;
- poison;
- spices;
- age;
- off age;
- off age max;
- cooked state;
- burnt state;
- cookable state;
- cooking time;
- minutes to cook;
- minutes to burn;
- freezing;
- frozen state;
- freezer-age multiplier;
- item heat;
- replacement/results;
- evolved-recipe naming.

foodWorks should wrap this.

======================================================================
3. FOOD ADAPTER
======================================================================

Create a normalized provider.

Conceptually:

foodWorks.Food.get(item)

Potential queries:

getCategory()
getIngredientTags()
getNutrition()
getAge()
getFreshnessState()
getTemperature()
isFrozen()
isCooked()
isBurnt()
isRotten()
isCookable()
getSpoilageProfile()

Do not expose raw implementation details as the public API.

======================================================================
4. VANILLA AGE / SPOILAGE
======================================================================

InventoryItem/Food exposes:

getAge()
setAge(...)

getOffAge()
setOffAge(...)

getOffAgeMax()
setOffAgeMax(...)

HowRotten()

IsRotten()

Vanilla already owns core food aging.

foodWorks should NOT maintain a second freshness timer.

======================================================================
5. FRESHNESS STATES
======================================================================

foodWorks can normalize vanilla aging into semantic states:

FRESH
AGING
STALE
SPOILED
ROTTEN

Exact mapping must respect actual B42 item behavior.

Do not rewrite vanilla values merely for prettier labels.

======================================================================
6. PERISHABILITY
======================================================================

Different foods already have different spoilage thresholds.

foodWorks can provide reusable profiles:

HIGHLY_PERISHABLE
PERISHABLE
STABLE
SHELF_STABLE

but backing vanilla `OffAge` / `OffAgeMax` remains authoritative.

======================================================================
7. REFRIGERATION
======================================================================

Vanilla already slows spoilage in refrigerators.

powerWorks owns whether refrigeration has power.

Vanilla/Food owns aging response.

foodWorks should not create another refrigerator timer.

Potential foodWorks responsibilities:

- normalized storage-quality query;
- cool-storage equipment;
- preservation content;
- diagnostics.

======================================================================
8. FREEZING
======================================================================

Food exposes:

canBeFrozen()
freeze()
updateFreezing()

and a FreezerAgeMultiplier.

This is a strong vanilla foundation.

foodWorks can improve:

- thawing workflow;
- refreezing consequences where appropriate;
- freezer storage UI;
- freezing of prepared meals;
- bulk freezer use.

Do not replace vanilla freeze state.

======================================================================
9. ITEM TEMPERATURE
======================================================================

InventoryItem exposes:

getItemHeat()
setItemHeat(...)

and cooking-related state.

foodWorks should audit exact B42 temperature propagation before building
advanced cooking.

Potential normalized:

FROZEN
COLD
COOL
AMBIENT
HOT
COOKING
BURNING

Do not maintain a duplicate temperature if vanilla gives adequate state.

======================================================================
10. COOKING
======================================================================

Vanilla already supports cookable food with:

minutesToCook
minutesToBurn
cookingTime
cooked state
burnt state.

foodWorks should preserve this.

foodWorks adds:

- process definitions;
- equipment requirements;
- preparation;
- bulk operations;
- recipe expansion;
- food safety.

======================================================================
11. COOKING PROCESS MODEL
======================================================================

Create semantic process types:

RAW_PREP
BOIL
SIMMER
FRY
SAUTE
BAKE
ROAST
GRILL
SMOKE
DRY
FERMENT
CURE
PICKLE
CAN
FREEZE
THAW
MILL
CHURN
PRESS
BUTCHER_PROCESS

Not every process must map to vanilla `isCookable`.

Some are crafting/preservation transformations.

======================================================================
12. VANILLA RECIPE SYSTEM
======================================================================

Recipe provides:

sources
result
required skill
LuaCreate
LuaGiveXP
LuaGrab
frozen-item rules
destroyed-item rules
inventory constraints

RecipeManager performs recipe discovery/execution.

foodWorks should use vanilla recipe infrastructure where appropriate.

Do not create custom ad-hoc crafting menus for every food process.

======================================================================
13. EVOLVED RECIPES
======================================================================

EvolvedRecipe is a major food-specific system.

Known properties include:

baseItem
resultItem
itemsList
maxItems
cookable
allowFrozenItem
addIngredientIfCooked
spices
ingredient querying
dynamic item addition.

This should remain the basis for flexible dishes where appropriate.

======================================================================
14. B42 RECIPE REWORK
======================================================================

TIS specifically redesigned recipe architecture to:

- reduce old recipe complexity;
- use templates;
- use tags;
- make new evolved recipes easier for modders;
- simplify ingredient integration;
- support more dynamic food naming.

Codex MUST inspect current B42.20 implementation rather than assuming older
EvolvedRecipe internals are still the final design.

======================================================================
15. INGREDIENT TAGS
======================================================================

foodWorks should lean heavily on semantic item tags.

Examples:

foodWorks_MEAT
foodWorks_POULTRY
foodWorks_FISH
foodWorks_VEGETABLE
foodWorks_FRUIT
foodWorks_GRAIN
foodWorks_FLOUR
foodWorks_DAIRY
foodWorks_EGG
foodWorks_FAT
foodWorks_SPICE
foodWorks_HERB
foodWorks_SWEETENER
foodWorks_PRESERVATIVE

Prefer vanilla tags if equivalent ones already exist.

Do not invent duplicate taxonomy.

======================================================================
16. INGREDIENT PROVIDER API
======================================================================

Third-party food mods should be able to register ingredients without foodWorks
hard-coding item names.

Concept:

foodWorks.Ingredients.register(...)

Provider gives:

category
tags
nutrition class
process compatibility
preservation compatibility.

Do not mutate third-party items unnecessarily.

======================================================================
17. DYNAMIC MEALS
======================================================================

Evolved recipes should support meals such as:

soups
stews
sandwiches
salads
pizza
rice dishes
pasta dishes
roasts
omelets
stir-fry-like meals where appropriate.

Use vanilla dynamic naming where possible.

foodWorks should not create a unique item definition for every combination.

======================================================================
18. RECIPE NAMES
======================================================================

Vanilla already supports evolved-recipe naming.

Translator also exposes evolved-recipe name lookups/debugging.

foodWorks should extend naming templates rather than manually assign names after
crafting where possible.

======================================================================
19. UNIQUE RECIPES
======================================================================

ScriptModule also contains UniqueRecipe support.

Audit current B42 use.

Potential:

special ingredient combinations
    ↓
named dishes / bonuses.

Do not overuse this for hundreds of gimmick meals.

======================================================================
20. PREPARATION STATE
======================================================================

Vanilla food items often represent prep state as distinct items.

Examples conceptually:

whole
sliced
chopped
peeled
diced
ground
filleted.

foodWorks should use normal item transformations when the state materially
affects gameplay.

Do not store every knife cut as ModData.

======================================================================
21. KNIFE / TOOL PREP
======================================================================

Possible actions:

Slice
Dice
Chop
Peel
Mince
Grind
Fillet
Debone

Tool properties can affect:

time
yield
condition use.

Use B42 crafting/timed-action architecture.

======================================================================
22. PREP STATIONS
======================================================================

Potential:

cutting board
counter
butcher table
kitchen workstation.

B42 workstations may already support this.

Audit first.

Do not require a workstation for trivial food prep.

======================================================================
23. FOOD YIELD
======================================================================

Processing should conserve sensible quantities.

Example:

whole animal cut
    ↓
meat portions
fat
bones
offal where applicable.

But butchery ownership must remain clean.

animalWorks/vanilla owns animal/carcass source.
foodWorks owns edible food processing downstream.

======================================================================
24. animalWorks INTEGRATION
======================================================================

animalWorks owns:

- live animals;
- animal products;
- milk production;
- eggs;
- carcass/husbandry state.

foodWorks consumes:

milk
eggs
meat
fat
other edible products.

animalWorks should not implement cheese-making, cooking or preservation.

======================================================================
25. farmWorks INTEGRATION
======================================================================

farmWorks owns:

- crops;
- harvest;
- grain/produce source;
- agricultural processing only where directly field-related.

foodWorks owns:

- kitchen/food processing;
- preservation;
- milling into culinary ingredients where agreed;
- recipe use;
- cooking.

Boundary for grain processing should be explicitly audited.

======================================================================
26. GRAIN PROCESSING
======================================================================

Potential chain:

farmWorks crop
    ↓
grain
    ↓
foodWorks cleaning/milling
    ↓
flour / meal
    ↓
baking/cooking.

If farmWorks already owns threshing as agricultural equipment:

farmWorks:
    plant → raw grain.

foodWorks:
    raw grain → culinary ingredient.

======================================================================
27. MILLING
======================================================================

Potential equipment:

hand mill
stone mill
powered grain mill.

powerWorks optionally powers electrical mill.

foodWorks owns resulting flour/meal.

CLASSIFICATION:
HIGH.

======================================================================
28. FLOUR
======================================================================

Flour should be a generic ingredient category.

Potential:

wheat flour
cornmeal
other meal/flour.

Do not create recipes hard-coded to one exact flour if tags can handle it.

======================================================================
29. BAKING
======================================================================

Potential foodWorks expansion:

bread
rolls
biscuits
pies
cakes
pizza
flatbread.

Use vanilla ovens/heat sources.

Audit B42 baking recipes first.

Do not duplicate existing content blindly.

======================================================================
30. DOUGH
======================================================================

Potential generic intermediate:

dough.

Properties may depend on:

flour
water
fat
yeast/leavening.

Use ingredient/tag templates.

Avoid dozens of nearly identical dough items unless mechanically meaningful.

======================================================================
31. FERMENTED DOUGH / YEAST
======================================================================

Potential bread-rising system.

Could use:

elapsed time
temperature
starter/yeast.

Do not create excessive micromanagement.

A simple proofing stage is sufficient if useful.

======================================================================
32. MEAT PROCESSING
======================================================================

Potential:

cut
trim
grind
cure
smoke
dry.

Vanilla butchering output remains source of truth.

foodWorks transforms edible portions.

======================================================================
33. GRINDING MEAT
======================================================================

Equipment:

hand grinder
powered grinder.

Results:

ground meat.

Uses:

sausages
meatloaf
other recipes.

HIGH confidence through recipes/workstations.

======================================================================
34. SAUSAGE MAKING
======================================================================

Potential chain:

ground meat
fat
salt
spices
casing
    ↓
fresh sausage.

Then optionally:

cook
smoke
dry/cure.

Do not collapse all preservation into one recipe.

======================================================================
35. CURING
======================================================================

Preservation process.

Potential variables:

salt
curing mix
time
temperature/storage requirement.

Products:

cured meat
salted meat.

foodWorks owns spoilage transformation.

======================================================================
36. SMOKING
======================================================================

Major preservation feature.

Potential equipment:

improvised smoker
smokehouse
smoking cabinet.

Inputs:

meat
fish
possibly cheese.

Requires:

fuel
time
appropriate temperature.

foodWorks owns process.

======================================================================
37. SMOKEHOUSE
======================================================================

Potential fixed workstation.

Fuel source may be:

wood/fire.

powerWorks generally not required.

weatherWorks may matter for exposed improvised drying/smoking structures.

Keep optional.

======================================================================
38. DRYING / DEHYDRATION
======================================================================

Potential:

fruit
vegetables
herbs
meat
fish.

Methods:

air drying
rack drying
electric dehydrator.

powerWorks supplies electrical power for electric dehydrator.

foodWorks owns food transformation.

======================================================================
39. weatherWorks INTEGRATION
======================================================================

weatherWorks may provide:

temperature
humidity
rain
weather exposure.

foodWorks may consume those for:

outdoor drying
smokehouse performance
food left outdoors.

Do NOT make weatherWorks aware of food.

======================================================================
40. SALT
======================================================================

Salt becomes an important culinary/preservation resource.

Uses:

seasoning
curing
brining
pickling.

Audit vanilla availability and existing recipes.

Do not create duplicate salt types unless necessary.

======================================================================
41. BRINING
======================================================================

Potential process:

water
salt
food
container
time.

Used for:

meat
vegetables
pickling preparation.

If represented as fluid, B42 FluidContainer may help.

Prototype before architecture.

======================================================================
42. PICKLING
======================================================================

Potential:

vegetables
brine/vinegar
jar
time.

Creates longer-lasting preserved food.

foodWorks owns preservation.

waterWorks owns water quality only when water is relevant.

======================================================================
43. VINEGAR
======================================================================

Audit vanilla vinegar.

Potential use:

pickling
culinary recipes.

Fermentation production may come later.

Do not add redundant vinegar if already plentiful.

======================================================================
44. CANNING
======================================================================

Vanilla already has some jar/preservation history.

Audit B42.20 current canning/preservation system.

foodWorks should extend, not replace.

Potential generalized pipeline:

prepare food
    ↓
fill sterilized jar
    ↓
seal
    ↓
heat process
    ↓
shelf-stable preserved food.

======================================================================
45. JAR STERILIZATION
======================================================================

Potential process:

clean jar
    ↓
heat/boil
    ↓
sterilized jar.

waterWorks may provide water.

foodWorks owns food-preparation consequence.

Avoid excessive sterile-state complexity if canning already abstracts it.

======================================================================
46. PRESSURE CANNING
======================================================================

Potential advanced preservation.

Useful for:

low-acid foods
meats
vegetables.

Requires:

pressure canner
heat source
knowledge.

Historically appropriate.

HIGH/EXPERIMENTAL depending workstation mechanics.

======================================================================
47. WATER-BATH CANNING
======================================================================

Simpler preservation for suitable foods.

Could use large pot/canner.

Do not teach unsafe real-world canning behavior through arbitrary rules.

Food safety mechanics should be reasonably grounded.

======================================================================
48. BOTULISM / CANNING FAILURE
======================================================================

Potential advanced food-safety risk.

But avoid opaque random deaths.

If modeled:

risk should derive from:

wrong process
bad seal
contamination
insufficient heat/time.

Potential poisoning consequence may use vanilla food-poisoning mechanisms.

CLASSIFICATION:
HIGH/EXPERIMENTAL.

Not initial release requirement.

======================================================================
49. FERMENTATION
======================================================================

Potential food fermentation:

sauerkraut-like vegetables
pickles
fermented dough
cultured dairy.

Alcohol production may deserve separate scope if substantial.

foodWorks can own culinary fermentation.

======================================================================
50. ALCOHOL BOUNDARY
======================================================================

Vanilla contains alcoholic beverages.

foodWorks may support culinary fermentation where relevant.

Do not let foodWorks become an entire brewing/distilling overhaul unless
explicitly scoped later.

Potential future separate subsystem/mod if necessary.

======================================================================
51. DAIRY
======================================================================

animalWorks provides milk.

foodWorks owns processing:

cream
butter
cheese
yogurt/cultured dairy where appropriate.

This creates substantial sustainable-food gameplay.

======================================================================
52. MILK SPOILAGE
======================================================================

Milk should remain a vanilla Food/fluid item using vanilla aging where possible.

foodWorks can adapt:

raw
pasteurized
processed.

Do not implement duplicate milk clocks.

======================================================================
53. PASTEURIZATION
======================================================================

Potential:

raw milk
    ↓
controlled heating
    ↓
pasteurized milk.

foodWorks owns food-safety transformation.

animalWorks owns milk source.

======================================================================
54. BUTTER
======================================================================

Potential chain:

cream/milk
    ↓
churn
    ↓
butter.

Equipment:

jar/churn.

High confidence using recipes/workstations.

======================================================================
55. CHEESE
======================================================================

Potential deeper processing:

milk
starter/acid
rennet where appropriate
salt
time
    ↓
cheese.

Aging can use foodWorks process state.

Do not create dozens of cheeses initially.

Start with meaningful categories.

======================================================================
56. CHEESE AGING
======================================================================

Unlike ordinary spoilage, controlled aging improves a product.

This cannot simply reuse "age until rotten."

foodWorks may need ProcessState metadata:

startedAt
processType
progress
conditions.

Use only for intentionally processed food.

======================================================================
57. PROCESS STATE
======================================================================

Core foodWorks abstraction for non-vanilla transformations.

Concept:

foodWorks.Process {
    type
    startTime
    progress
    requiredConditions
    container
    targetResult
}

Use for:

fermentation
curing
drying
cheese aging
proofing.

Do not use it for ordinary vanilla food spoilage.

======================================================================
58. PROCESS UPDATE RATE
======================================================================

These processes are slow.

Use elapsed world time.

Do NOT update every jar/cheese every tick.

Store:

startWorldAge
lastChecked

Calculate progress on access/coarse schedule.

======================================================================
59. FOOD SAFETY
======================================================================

Vanilla Food already exposes poisoning concepts and rotten/spoiled states.

foodWorks should deepen but preserve compatibility.

Potential risks:

raw meat
spoiled food
failed preservation
contaminated water
unsafe canning
cross-contamination.

Do not build a medical-disease simulator inside foodWorks.

======================================================================
60. RAW FOOD
======================================================================

Audit vanilla `DangerousUncooked` / raw-food mechanics in current B42 scripts.

foodWorks should respect vanilla unsafe-raw states.

Do not create duplicate raw-danger metadata unless needed.

======================================================================
61. COOKING SAFETY
======================================================================

foodWorks may classify foods that require cooking.

Proper cooking:

reduces/clears applicable food safety risk.

Overcooking/burning:

creates poor-quality food.

Use vanilla state where supported.

======================================================================
62. CROSS-CONTAMINATION
======================================================================

Potential advanced mechanic:

raw meat tool/surface
    ↓
ready-to-eat food
    ↓
contamination.

This could become tedious quickly.

Recommend:

OPTIONAL / later.

If implemented, use simple workstation/tool cleanliness state rather than
tracking microbial state on every object.

======================================================================
63. waterWorks INTEGRATION
======================================================================

waterWorks owns:

water quantity
water quality
water treatment.

foodWorks consumes:

whether water is suitable for:
drinking
cooking
washing produce
brining
canning.

foodWorks MUST NOT recalculate water contamination.

======================================================================
64. COOKING WATER
======================================================================

A recipe requiring water should consume actual vanilla/B42 fluid where possible.

Use FluidContainer integration rather than fake "water units" if current
crafting supports it.

Audit B42.20 recipes.

======================================================================
65. BOILING WATER
======================================================================

waterWorks owns water-treatment result.

foodWorks may initiate boiling as a cooking operation.

Do not maintain separate foodWorks potable-water state.

======================================================================
66. WASHING PRODUCE
======================================================================

Potential:

dirty produce
    ↓
wash
    ↓
clean produce.

Need audit of current produce dirt/contamination mechanics.

Not necessary unless there is actual gameplay value.

======================================================================
67. NUTRITION
======================================================================

Vanilla Food already owns macronutrient/calorie effects.

foodWorks should preserve:

calories
carbohydrates
protein
fat.

Do not create second nutrition values.

======================================================================
68. DYNAMIC NUTRITION
======================================================================

Prepared dishes should derive nutrition from ingredients.

Vanilla evolved recipes already handle this to some degree.

Audit current implementation before changing.

foodWorks can correct/generalize only where needed.

======================================================================
69. PORTIONING
======================================================================

Potential:

pot of stew
    ↓
bowls/servings.

Use vanilla portion/split semantics where possible.

Do not duplicate nutrition during splitting.

This is an important exploit test.

======================================================================
70. BULK MEALS
======================================================================

foodWorks should improve cooking for groups.

Examples:

stockpot
large roasting pan
bulk stew
communal meal.

Benefits:

less repetitive clicking
better base logistics.

Time/resources still scale appropriately.

======================================================================
71. LEFTOVERS
======================================================================

Potential:

large meal
    ↓
portions
    ↓
stored leftovers.

Each portion uses vanilla Food aging.

No custom leftover timer.

======================================================================
72. REHEATING
======================================================================

Potential quality-of-life process.

Cold cooked food
    ↓
heat
    ↓
hot food.

Do not reset freshness.

This must never become an exploit that makes old food fresh.

======================================================================
73. COOKED AGE
======================================================================

Audit how B42 handles age when food is cooked.

foodWorks should not blindly reset age unless vanilla does and it is appropriate.

Preservation transformations may intentionally create a new shelf life.

Document each transformation.

======================================================================
74. BURNING
======================================================================

Vanilla supports burnt food.

foodWorks should preserve this.

Potential:

burnt food salvage?
charred exterior?

Probably unnecessary.

Avoid overcomplicating failed cooking.

======================================================================
75. MICROWAVE
======================================================================

Audit vanilla microwave behavior.

Potential issues:

metal containers
food heat
cooking speed
power dependency.

Do not create separate microwave cooking if vanilla already handles it.

powerWorks supplies electricity generically.

======================================================================
76. OVENS / STOVES
======================================================================

Audit:

electric stove
gas/propane if applicable
wood stove
campfire
barbecue
other heat sources.

foodWorks owns recipe/process compatibility.

Heat source owns heat/fuel/power.

======================================================================
77. powerWorks INTEGRATION
======================================================================

powerWorks owns electricity.

foodWorks powered equipment may include:

- refrigerator/freezer indirectly vanilla;
- electric oven;
- dehydrator;
- grinder;
- mixer;
- powered mill;
- commercial kitchen equipment.

foodWorks registers loads where powerWorks integration exists.

======================================================================
78. HEAT SOURCE PROVIDER
======================================================================

foodWorks should not hard-code only oven names.

Potential:

foodWorks.HeatSources

Adapters:

VanillaOven
Campfire
Barbecue
WoodStove
CustomAppliance

Capabilities:

BAKE
BOIL
FRY
ROAST
SMOKE
DRY

This makes recipes equipment-aware without item-name spaghetti.

======================================================================
79. COOKWARE
======================================================================

Audit vanilla:

pots
pans
baking trays
roasting pans
bowls
mugs
kettles.

foodWorks should reuse these.

Potential additions only when process requires them:

pressure canner
stockpot
smoker rack
dehydrator tray.

======================================================================
80. KITCHEN WORKSTATIONS
======================================================================

B42's crafting overhaul may support workstation concepts.

foodWorks should leverage:

counters
ovens
prep tables
mills
smokers
canners.

Do not create custom context menus when recipe stations work.

======================================================================
81. REFRIGERATOR STORAGE
======================================================================

Vanilla ItemContainer/objects already manage refrigerator/freezer behavior.

foodWorks should provide utility queries such as:

foodWorks.Storage.getPreservationFactor(container)

but vanilla remains the real aging authority.

======================================================================
82. ROOT CELLARS
======================================================================

Potential cross-project feature.

groundWorks owns:

excavation/basement/root-cellar space.

foodWorks owns:

food-storage suitability/preservation benefit.

weatherWorks provides:

ambient environmental conditions if useful.

powerWorks not required.

This can provide passive cool storage after grid loss.

======================================================================
83. ROOT CELLAR MODEL
======================================================================

Do NOT manually freeze food.

Represent:

cool stable environment
    ↓
reduced spoilage rate

only if vanilla food-aging multipliers can be adjusted safely.

CLASSIFICATION:
HIGH/EXPERIMENTAL.

Needs spike.

======================================================================
84. PANTRIES
======================================================================

Potential dry storage category.

Could primarily be organizational rather than a magical spoilage modifier.

Shelf-stable food remains shelf-stable.

No reason for pantry to make fresh meat last weeks.

======================================================================
85. ICEBOXES
======================================================================

Period-appropriate passive refrigeration.

Potential:

insulated container
+
ice
    ↓
cool storage.

foodWorks owns preservation equipment.

waterWorks may provide ice/water only if relevant.

CLASSIFICATION:
HIGH.

======================================================================
86. ICE
======================================================================

Audit current B42 freezing/ice item support.

Do not create ice subsystem blindly.

Potential future:

freeze water
    ↓
ice
    ↓
icebox.

======================================================================
87. FOOD STORAGE CONDITIONS
======================================================================

Possible normalized environmental categories:

FROZEN
REFRIGERATED
COOL
AMBIENT
HOT
DRYING
SMOKING
CONTROLLED_AGING

Only vanilla-recognized conditions should directly affect vanilla spoilage
unless tested.

======================================================================
88. CONTAINER EFFECTS
======================================================================

Potential:

sealed jar
sealed can
airtight container
open container.

Vanilla does not necessarily model all packaging effects generically.

foodWorks can add preservation-state metadata to foodWorks-created products.

Do not add container state to every vanilla snack.

======================================================================
89. OPENED PACKAGES
======================================================================

Potential:

sealed package
    ↓
opened
    ↓
shorter shelf life.

Interesting but potentially huge compatibility burden.

Defer unless B42 already exposes opened-package mechanics.

======================================================================
90. CANNED FOOD
======================================================================

Vanilla canned food is already shelf-stable.

foodWorks should NOT track spoilage for factory-sealed cans unless vanilla does.

Player-canned goods are a separate crafted-preservation state.

======================================================================
91. FOOD PACKAGING
======================================================================

Potential preservation items:

jars
lids
wax paper
foil
freezer bags
containers.

Keep period-appropriate.

No modern vacuum-sealer ecosystem unless historically plausible and useful.

======================================================================
92. VACUUM SEALING
======================================================================

1993 consumer vacuum sealers existed, but this is niche.

Potential late-game appliance.

Not core.

powerWorks could supply electricity.

======================================================================
93. SMOKED / DRIED / CURED STATE
======================================================================

Prefer transforming into a new vanilla `Food` item with appropriate spoilage
parameters.

This keeps vanilla aging working.

Example:

RawVenison
    ↓
smoke process
    ↓
SmokedVenison

SmokedVenison is still a vanilla Food item.

This is preferable to custom global spoilage simulation.

======================================================================
94. FERMENTATION RESULTS
======================================================================

Likewise:

Milk
    ↓
cheese process
    ↓
Cheese Food item.

Cabbage
    ↓
fermentation
    ↓
preserved vegetable item.

Process state exists only during transformation.

======================================================================
95. PROCESS CONTAINERS
======================================================================

Fermentation/pickling/canning may need a container association.

Potential:

foodWorks.ProcessContainer

Properties:

process
contents
start time
conditions.

Use actual ItemContainer/FluidContainer where practical.

Do not invent a container engine.

======================================================================
96. FLUID FOODS
======================================================================

Soups, milk, broth, sauces, brines may overlap B42 FluidContainer.

Codex must audit whether current B42 food crafting integrates fluid components
cleanly.

Do not assume every soup should become a generic fluid.

Keep meal gameplay compatible with vanilla food items.

======================================================================
97. BROTH / STOCK
======================================================================

Potential cooking chain:

bones/meat/vegetables
+
water
+
heat
    ↓
stock/broth.

Useful as evolved-recipe ingredient.

High confidence.

======================================================================
98. SOUPS / STEWS
======================================================================

Already a core vanilla evolved-recipe style.

foodWorks should improve ingredient compatibility and scaling, not replace it.

======================================================================
99. SPICES
======================================================================

Food already stores spices.

EvolvedRecipe supports spice behavior.

foodWorks should audit current spice integration.

Potential:

herbs from farmWorks
spices
salt
pepper.

No need for custom seasoning state.

======================================================================
100. HERBS
======================================================================

farmWorks supplies cultivated herbs.
Vanilla foraging supplies wild herbs.

foodWorks uses them as ingredients/spices.

farmWorks does not own recipe effects.

======================================================================
101. PRESERVATION KNOWLEDGE
======================================================================

Skill != knowledge.

Potential foodWorks books:

- Home Cooking
- Baking
- Food Preservation
- Canning & Pickling
- Meat Curing
- Smoking & Drying
- Dairy Processing
- Butchery & Sausage Making
- Bread Making
- Commercial Kitchen Techniques.

Do not turn every simple sandwich into a learned recipe.

======================================================================
102. COOKING SKILL
======================================================================

Reuse vanilla Cooking skill.

Do NOT create foodWorks Cooking skill.

Skill can affect:

- preparation speed;
- burn margin;
- ingredient efficiency;
- recipe access where vanilla does;
- yield;
- diagnosis of spoilage;
- advanced techniques.

======================================================================
103. FOOD PRESERVATION SKILL
======================================================================

Prefer Cooking + knowledge rather than new skill.

Only introduce separate preservation progression if vanilla Cooking cannot
represent it without distortion.

Default:
NO NEW SKILL.

======================================================================
104. RECIPE KNOWLEDGE
======================================================================

Use vanilla recipe-known/learning infrastructure wherever possible.

RecipeManager exposes known recipe counts and recipe discovery.

Codex should audit current B42 learned-recipe system.

======================================================================
105. FOOD QUALITY
======================================================================

Do not create arbitrary MMO rarity tiers.

Possible outcome modifiers:

poorly prepared
normal
well prepared

should emerge from vanilla nutrition/happiness/cooking where possible.

Avoid duplicating food quality unless it materially improves gameplay.

======================================================================
106. COOKING XP
======================================================================

Use vanilla Cooking XP hooks/recipe LuaGiveXP.

Do not award duplicate foodWorks XP.

======================================================================
107. NUTRITION BALANCE
======================================================================

foodWorks must preserve reasonable calories/macros when ingredients transform.

Critical exploit tests:

- cutting cannot multiply calories;
- splitting cannot multiply nutrients;
- cooking cannot duplicate portions;
- preservation cannot create free food;
- leftovers cannot reset portions.

======================================================================
108. MASS CONSERVATION
======================================================================

Food processing should broadly preserve mass/yield minus reasonable waste.

Use quantity/yield abstractions.

Do not model every gram, but prevent duplication exploits.

======================================================================
109. FOOD WASTE
======================================================================

Potential:

bones
peels
trimmings
spoiled food.

Some can feed:

compost
animals where suitable.

farmWorks owns compost agricultural use.
animalWorks owns animal feed consequences.

foodWorks owns food-preparation byproducts.

======================================================================
110. COMPOST INTEGRATION
======================================================================

foodWorks may tag compostable scraps.

farmWorks consumes those through its compost system.

foodWorks should not modify soil.

======================================================================
111. ANIMAL FEED
======================================================================

foodWorks may produce food-processing byproducts.

animalWorks determines whether an animal can eat them.

Do not hard-code pig diet into foodWorks.

======================================================================
112. SPOILED FOOD USE
======================================================================

Potential:

spoiled produce
    ↓
compost.

stale bread
    ↓
some recipes/animal feed where safe.

rotten meat
    generally unsafe.

Use tags/providers.

======================================================================
113. FOOD POISONING
======================================================================

Vanilla handles sickness/poisoning consequences.

foodWorks provides unsafe food state/process outcomes.

medWorks may provide medical treatment.

foodWorks does not own the patient's illness system.

======================================================================
114. medWorks INTEGRATION
======================================================================

medWorks may consume:

food poisoning cause/type
nutrition context
dehydration context.

foodWorks should not diagnose or treat.

======================================================================
115. KNOX INFECTION
======================================================================

foodWorks should not create infection/cure mechanics for zombie disease.

Keep out of scope.

======================================================================
116. COOKING WITH UNSAFE WATER
======================================================================

waterWorks says:

water quality.

foodWorks process may:

boil sufficiently
    ↓
ask waterWorks treatment API

or require potable water.

Do not silently mark waterWorks water safe itself.

======================================================================
117. POWER LOSS
======================================================================

powerWorks determines electricity availability.

Vanilla refrigeration then stops/starts as supported.

foodWorks may expose alerts:

Freezer lost power.

But do not run duplicate appliance power state.

======================================================================
118. REFRIGERATION RECOVERY
======================================================================

When power returns:

food continues from actual vanilla age/frozen state.

Do not reset spoilage.

======================================================================
119. FREEZER BURN
======================================================================

Potential realistic feature, but not high value.

Defer.

Vanilla freezing already provides preservation.

======================================================================
120. WEATHER-EXPOSED FOOD
======================================================================

Potential:

food left outside
heat exposure
freezing.

Vanilla inventory/container aging may already account for temperature to some
degree.

Audit before adding.

======================================================================
121. SUMMER HEAT
======================================================================

Potential preservation impact should ideally emerge from vanilla temperature
and storage.

If vanilla spoilage is not ambient-temperature sensitive beyond refrigeration,
foodWorks could add an optional storage modifier.

CLASSIFICATION:
EXPERIMENTAL.

Do not interfere with vanilla age globally without profiling.

======================================================================
122. OUTDOOR DRYING
======================================================================

weatherWorks integration can make:

warm
dry
low humidity
no rain

ideal drying conditions.

foodWorks owns process progress.

weatherWorks supplies environment.

======================================================================
123. SMOKEHOUSE WEATHER PROTECTION
======================================================================

An enclosed smoker/smokehouse should not fail because it rains.

foodWorks workstation determines exposure rules.

Do not blindly apply outdoor weather.

======================================================================
124. ROOT CELLAR CROSS-WORKS
======================================================================

groundWorks:
    creates/exposes valid below-grade/root-cellar space.

weatherWorks:
    environmental climate context if needed.

foodWorks:
    determines storage preservation modifier.

powerWorks:
    not required.

This is a strong low-tech preservation pathway.

======================================================================
125. LARGE KITCHENS
======================================================================

Potential late-game/base feature:

prep counters
large stove
commercial oven
stockpots
storage racks.

foodWorks should scale cooking without turning it into factory automation.

======================================================================
126. COMMERCIAL APPLIANCES
======================================================================

Potential:

commercial oven
griddle
meat slicer
mixer
grinder
dehydrator.

powerWorks supplies electricity where appropriate.

foodWorks owns culinary operation.

======================================================================
127. GENERATOR COOKING
======================================================================

No special foodWorks logic.

If powerWorks/vanilla supplies stove power:

stove works.

======================================================================
128. WOOD-FIRED COOKING
======================================================================

Critical after grid failure.

Support/adapt:

campfire
wood stove
barbecue
other non-electric heat sources.

foodWorks should remain fully playable without powerWorks.

======================================================================
129. SOLAR COOKING
======================================================================

Possible niche device.

Not core.

Could use weatherWorks/lightWorks environmental input.

Defer.

======================================================================
130. BULK PRESERVATION
======================================================================

Late-game foodWorks should reduce repetition.

Example:

Smoking rack with 12 pieces.

Server processes one workstation batch rather than 12 independent timers where
safe.

Same for:

canning
drying
cheese aging.

This improves performance and usability.

======================================================================
131. BATCH SYSTEM
======================================================================

Potential:

foodWorks.BatchProcess

workstation
input inventory
recipe/process
start time
duration
conditions
outputs.

Use B42 crafting stations if they already provide equivalent batching.

Audit first.

======================================================================
132. WORKSTATION INVENTORY
======================================================================

Prefer vanilla ItemContainer/component storage.

Do not keep invisible Lua item arrays.

Canonical items must exist in actual inventories.

======================================================================
133. PROCESS INTERRUPTION
======================================================================

Different processes behave differently.

Cooking:
may burn if unattended.

Smoking:
can pause/fail if fuel lost.

Drying:
progress depends on conditions.

Canning:
timed active process.

Cheese aging:
continues slowly.

Define per-process policy.

======================================================================
134. FUEL
======================================================================

foodWorks does not own generic fuel systems.

Heat source consumes vanilla fuel/electricity.

foodWorks only requires suitable process capability.

======================================================================
135. FOOD DATABASE / REGISTRY
======================================================================

Do not manually maintain every vanilla food item forever.

At load:

enumerate script items
detect Food type/tags
build normalized registry.

Allow explicit overrides for unusual foods.

======================================================================
136. VANILLA FOOD AUDIT
======================================================================

Codex must enumerate current B42.20 Food definitions.

Record:

Item
Category
Hunger
Thirst
Calories
Carbs
Protein
Fat
OffAge
OffAgeMax
Cookable?
MinutesToCook
MinutesToBurn
CanFreeze?
DangerousRaw?
EvolvedRecipe tags
ReplaceOnUse
Relevant recipe tags.

Do NOT use an old wiki list.

======================================================================
137. RECIPE AUDIT
======================================================================

Enumerate:

Recipe
EvolvedRecipe
UniqueRecipe
B42 crafting recipes/templates
food-related workstations.

For each:

inputs
tags
tools
skills
knowledge
outputs
Lua hooks
MP behavior.

======================================================================
138. HEAT-SOURCE AUDIT
======================================================================

Audit all current B42 heat/cooking sources:

- campfire;
- oven/stove;
- microwave;
- barbecue;
- wood stove;
- fireplace;
- industrial/commercial cooking appliances;
- B42 crafting stations.

Record:

power/fuel
temperature behavior
container handling
cooking support.

======================================================================
139. STORAGE AUDIT
======================================================================

Audit:

fridge
freezer
cooler
shelves
cabinets
containers
vehicle refrigeration if any
other B42 storage modifiers.

Determine exactly where aging multipliers are applied.

======================================================================
140. MULTIPLAYER AUTHORITY
======================================================================

B42 increasingly makes inventory/crafting interactions server-authoritative.

foodWorks should follow this.

SERVER owns:

- recipe validation;
- ingredient consumption;
- result creation;
- preservation processes;
- workstation state;
- process completion;
- food-safety metadata;
- custom aging-process state;
- batch state.

CLIENT:

- UI;
- animation;
- progress display;
- contextual recipe lists.

Never trust client-provided outputs.

======================================================================
141. FOOD ITEM MUTATION
======================================================================

Server-authoritative mutation only for:

age changes
process state
result transformation
nutrition where custom
preservation state.

Do not duplicate item IDs.

======================================================================
142. PORTION MP
======================================================================

Splitting/bulk meals are high duplication risk.

Server validates:

source item
remaining amount/nutrition
target portions
containers.

Test aggressively.

======================================================================
143. WORKSTATION MP
======================================================================

Server owns:

input inventory
process state
fuel/power validation
outputs.

Two players must not both collect same completed batch.

======================================================================
144. PERSISTENCE
======================================================================

Vanilla food state persists on the Food item.

Do not copy:

age
cooked
burnt
nutrition
frozen

into foodWorks ModData.

Persist only foodWorks-owned state such as:

fermentation process
curing progress
cheese aging
canning seal state
batch/workstation state
provider-specific metadata.

======================================================================
145. OFFLINE PROCESSING
======================================================================

Slow food processes should progress with world time while unloaded if appropriate.

Use:

startTime
currentWorldTime
environment snapshots/rules.

Do not replay every tick.

Processes requiring continuous active heat/fuel may need more careful
integration.

======================================================================
146. SPOILAGE PERFORMANCE
======================================================================

Vanilla already updates food aging.

Do not create a second timer over every Food item.

foodWorks custom processing should track only actively processed items/batches.

Sparse registry only.

======================================================================
147. RECIPE PERFORMANCE
======================================================================

Avoid scanning every food item and every recipe every UI frame.

Cache:

ingredient tags
recipe compatibility
known recipes

and invalidate when inventory/knowledge changes.

======================================================================
148. DEBUGGER
======================================================================

foodWorks needs a Food Inspector.

Selected item:

Type
Food?
Age
Fresh state
OffAge
OffAgeMax
HowRotten
Cookable
CookingTime
MinutesToCook
MinutesToBurn
Cooked
Burnt
Frozen
Temperature
Nutrition
Spices
Tags
Current Process
Storage Context.

======================================================================
149. RECIPE DEBUGGER
======================================================================

Display:

Recipe ID
Type
Fixed/Evolved/B42 Craft
Inputs
Ingredient tags
Tools
Skills
Knowledge
Workstation
Heat requirement
Fluid requirement
Output
Nutrition transfer
MP authority path.

======================================================================
150. PROCESS DEBUGGER
======================================================================

Display:

Process
Input
Container/Station
Start Time
Elapsed
Required Conditions
Current Conditions
Progress
Predicted Result
Failure State.

======================================================================
151. STORAGE DEBUGGER
======================================================================

Selected container:

Type
Temperature
Powered?
Fridge?
Freezer?
Vanilla preservation behavior
foodWorks modifier
Root-cellar/cool-storage state.

======================================================================
152. FEATURE FEASIBILITY MATRIX
======================================================================

FEATURE                               STATUS

Food item adapter                     VERY HIGH
Food age                              VERY HIGH
Fresh/rotten state                    VERY HIGH
Nutrition                             VERY HIGH
Cooked/burnt state                    VERY HIGH
Cooking time                          VERY HIGH
Food temperature                      VERY HIGH
Freezing                              VERY HIGH
Freezer preservation                  VERY HIGH
Vanilla recipe adapter                VERY HIGH
Evolved recipes                       VERY HIGH
Ingredient tags                       VERY HIGH/HIGH current B42 audit
Dynamic meals                         VERY HIGH
Dynamic meal naming                   VERY HIGH/HIGH
Recipe knowledge                      VERY HIGH
Cooking skill                         VERY HIGH
Food-prep transformations             VERY HIGH
Knife prep                            HIGH
Bulk meals                            HIGH
Portioning                            HIGH/VERIFY exploit safety
Leftovers                             HIGH
Reheating                             HIGH
Milling                               HIGH
Bread/baking expansion                HIGH
Meat grinding                         HIGH
Sausage making                        HIGH
Smoking                              HIGH
Drying                               HIGH
Curing                               HIGH
Pickling                             HIGH
Brining                              HIGH
Canning                              HIGH/VERIFY vanilla
Pressure canning                     HIGH
Fermentation                         HIGH
Cheese making                        HIGH
Butter                               HIGH
Pasteurization                       HIGH
Controlled cheese aging              HIGH
Root-cellar storage                  HIGH/EXPERIMENTAL
Icebox                               HIGH
Outdoor drying                       HIGH
Weather-dependent drying             HIGH
waterWorks food-water integration    HIGH
Powered kitchen equipment            HIGH
powerWorks integration               HIGH
Food-safety metadata                 HIGH
Unsafe preservation                  HIGH/EXPERIMENTAL
Botulism-like risk                   EXPERIMENTAL/FUTURE
Cross-contamination                  EXPERIMENTAL/FUTURE
Ambient-temp spoilage enhancement    EXPERIMENTAL
Full microbial simulation            DO NOT DO
Replacement vanilla food-aging       DO NOT DO
Replacement nutrition system         DO NOT DO
Replacement B42 crafting             DO NOT DO

======================================================================
153. REQUIRED TECHNICAL SPIKES
======================================================================

FDW-SPIKE-01
Enumerate all current B42 Food items.

FDW-SPIKE-02
Read Food age/offAge/offAgeMax from Lua.

FDW-SPIKE-03
Observe vanilla fresh -> stale/rotten lifecycle.

FDW-SPIKE-04
Observe refrigerator aging.

FDW-SPIKE-05
Observe freezer/freezing lifecycle.

FDW-SPIKE-06
Read/modify food heat safely.

FDW-SPIKE-07
Trace vanilla cooking lifecycle.

FDW-SPIKE-08
Trace burnt-food lifecycle.

FDW-SPIKE-09
Enumerate B42 Recipe system.

FDW-SPIKE-10
Enumerate current EvolvedRecipe implementation.

FDW-SPIKE-11
Inspect B42 tags/templates.

FDW-SPIKE-12
Add third-party ingredient to one evolved recipe through supported path.

FDW-SPIKE-13
Create one dynamic foodWorks recipe.

FDW-SPIKE-14
Split one meal without nutrition duplication.

FDW-SPIKE-15
Bulk meal workstation.

FDW-SPIKE-16
Smoking process.

FDW-SPIKE-17
Drying process.

FDW-SPIKE-18
Pickling process.

FDW-SPIKE-19
Canning process.

FDW-SPIKE-20
Cheese aging elapsed-time process.

FDW-SPIKE-21
animalWorks milk -> foodWorks dairy product.

FDW-SPIKE-22
farmWorks grain -> foodWorks flour.

FDW-SPIKE-23
waterWorks water consumed in cooking recipe.

FDW-SPIKE-24
powerWorks-powered food-processing appliance.

FDW-SPIKE-25
weatherWorks outdoor drying.

FDW-SPIKE-26
groundWorks root-cellar storage query.

FDW-SPIKE-27
Dedicated-server fixed recipe.

FDW-SPIKE-28
Dedicated-server evolved recipe.

FDW-SPIKE-29
Dedicated-server persistent preservation process.

FDW-SPIKE-30
Save/unload/reload long-running process.

======================================================================
154. REQUIRED VANILLA B42.20 AUDIT
======================================================================

Codex must inspect current stable scripts/runtime and enumerate:

FOOD

- Food class usage;
- all food item script fields;
- age;
- freshness;
- nutrition;
- poison;
- frozen;
- cooking;
- burnt state;
- raw-danger fields;
- replacement rules.

RECIPES

- Recipe;
- EvolvedRecipe;
- UniqueRecipe;
- B42 templates;
- tags;
- crafting recipe definitions;
- food workstations;
- skills;
- recipe learning.

COOKING

- heat-source detection;
- cooking updates;
- food temperature;
- ovens;
- stoves;
- microwave;
- barbecue;
- campfire;
- wood stove;
- other B42 appliances.

STORAGE

- refrigerator;
- freezer;
- container temperature;
- food aging multipliers;
- frozen-food behavior.

PRESERVATION

- current vanilla canning;
- jars/lids;
- drying/smoking if any;
- salted/preserved foods;
- current B42 additions.

UI

- crafting;
- evolved recipe UI;
- cooking context menus;
- nutrition display.

MP

- recipe execution;
- evolved recipe mutation;
- ingredient consumption;
- Food item state sync;
- appliance interactions.

Do not rely on Build 41 lists.

======================================================================
155. CONTENT GAP AUDIT
======================================================================

For each feature record:

VANILLA HAS
VANILLA PARTIALLY HAS
VANILLA LACKS
API HOOK
foodWorks IMPROVEMENT
CONFIDENCE.

Audit at minimum:

- chopping/slicing;
- bulk prep;
- bread;
- baking;
- grain milling;
- meat grinding;
- sausage;
- curing;
- smoking;
- drying;
- dehydration;
- canning;
- pressure canning;
- pickling;
- fermentation;
- dairy;
- cheese;
- butter;
- pasteurization;
- root-cellar storage;
- icebox;
- leftovers;
- reheating;
- large meals;
- food waste;
- food safety;
- water quality in cooking.

======================================================================
156. DEVELOPMENT ROADMAP
======================================================================

FDW0 — VANILLA/API AUDIT

- Food;
- B42 item scripts;
- Recipe;
- EvolvedRecipe;
- tags/templates;
- cooking;
- storage;
- preservation;
- MP.

FDW1 — CORE ADAPTER

- FoodAdapter;
- IngredientRegistry;
- process capability tags;
- recipe adapters;
- diagnostics;
- third-party provider API.

FDW2 — FOOD PREP

- cutting;
- slicing;
- chopping;
- grinding;
- preparation transformations;
- yield safety.

FDW3 — COOKING QUALITY / SCALE

- bulk cooking;
- stockpots;
- portions;
- leftovers;
- improved evolved recipe integration.

FDW4 — GRAIN / BAKING

- milling;
- flour;
- dough;
- bread/baking;
- farmWorks integration.

FDW5 — MEAT PROCESSING

- grinding;
- sausages;
- trimming;
- animalWorks/vanilla meat integration.

FDW6 — PRESERVATION CORE

- ProcessState;
- smoking;
- drying;
- curing;
- brining;
- pickling.

FDW7 — CANNING

- jars;
- sterilization;
- water-bath;
- pressure canning;
- preservation safety.

FDW8 — DAIRY

- pasteurization;
- butter;
- cheese;
- controlled aging;
- animalWorks milk.

FDW9 — STORAGE

- cool-storage adapter;
- icebox;
- root-cellar integration;
- groundWorks;
- weatherWorks environment.

FDW10 — FOOD SAFETY

- unsafe raw foods;
- failed preservation;
- optional contamination extensions;
- waterWorks integration.

FDW11 — EQUIPMENT

- smoker;
- dehydrator;
- grinder;
- mill;
- canner;
- commercial kitchen equipment;
- powerWorks loads.

FDW12 — CROSS-WORKS

- animalWorks;
- farmWorks;
- waterWorks;
- powerWorks;
- weatherWorks;
- groundWorks;
- medWorks.

FDW13 — COMPATIBILITY / POLISH

- third-party foods;
- recipe providers;
- sandbox;
- MP;
- performance;
- balance;
- migrations.

======================================================================
157. DEPENDENCY ARCHITECTURE
======================================================================

foodWorks HARD DEPENDENCY:

Project Zomboid only.

Optional providers:

animalWorks
farmWorks
waterWorks
powerWorks
weatherWorks
groundWorks

Potential downstream:

medWorks may consume food-poisoning/nutrition context.

foodWorks should NOT hard-require the entire theWorks ecosystem.

======================================================================
158. CROSS-WORKS OWNERSHIP
======================================================================

foodWorks OWNS:

- culinary ingredients;
- cooking;
- food preparation;
- recipe integrations;
- preservation;
- food processing;
- culinary fermentation;
- dairy processing;
- smoking;
- curing;
- drying;
- canning;
- pickling;
- food-storage modifiers it specifically provides;
- food-safety outcomes;
- food-processing equipment.

animalWorks OWNS:

- live animals;
- eggs/milk/meat source;
- animal products.

farmWorks OWNS:

- crops;
- grain/produce source;
- agricultural production.

waterWorks OWNS:

- water quality;
- water infrastructure.

powerWorks OWNS:

- electrical supply.

weatherWorks OWNS:

- weather/environment.

groundWorks OWNS:

- excavation/below-grade space.

medWorks OWNS:

- medical treatment of foodborne illness.

======================================================================
159. FLAGSHIP FOOD CHAIN EXAMPLES
======================================================================

EXAMPLE A — BREAD

farmWorks Wheat
    ↓
farmWorks harvest/raw grain
    ↓
foodWorks Mill
    ↓
Flour
    ↓
waterWorks Water
    ↓
Dough
    ↓
Proof
    ↓
Bake
    ↓
Bread

---------------------------------------------------------------------

EXAMPLE B — CHEESE

animalWorks Cow
    ↓
Milk
    ↓
foodWorks Pasteurization
    ↓
Cheese Making
    ↓
Aging
    ↓
Finished Cheese

---------------------------------------------------------------------

EXAMPLE C — PRESERVED MEAT

animalWorks / vanilla carcass
    ↓
Meat
    ↓
foodWorks trim/grind/cure
    ↓
Smokehouse
    ↓
Smoked/Cured Food
    ↓
Vanilla Food aging continues with new preservation profile.

---------------------------------------------------------------------

EXAMPLE D — PICKLED FARM PRODUCE

farmWorks Vegetables
    ↓
foodWorks preparation
    ↓
waterWorks-safe water/brine
    ↓
Jar
    ↓
Pickle Process
    ↓
Preserved Food.

---------------------------------------------------------------------

EXAMPLE E — ROOT CELLAR

groundWorks
    ↓
Player-built below-grade/root-cellar space
    ↓
weatherWorks environment
    ↓
foodWorks recognizes cool-storage context
    ↓
Vanilla Food aging modified through verified adapter.

No duplicate food item simulation.

======================================================================
160. CORE DESIGN PRINCIPLE
======================================================================

DO NOT MAKE:

"500 New Recipes."

DO NOT MAKE:

"More Canned Food."

DO NOT MAKE:

"Better Cooking Menu."

MAKE FOOD PRODUCTION SCALE.

Vanilla already gives us:

FOOD
    ↓
AGE
    ↓
COOK
    ↓
EAT.

foodWorks adds:

SOURCE
    ↓
PREP
    ↓
PROCESS
    ↓
COOK
    ↓
PRESERVE
    ↓
STORE
    ↓
SERVE
    ↓
WASTE / REUSE.

The objective is to make food a sustainable infrastructure problem, not merely
a growing list of item recipes.

======================================================================
161. CODEX NEXT ACTION
======================================================================

Before broad implementation:

1. Audit the foodWorks repository.
2. Audit current installed B42.20 Food class usage.
3. Enumerate every current Food script item.
4. Enumerate all food-related script fields.
5. Trace age/fresh/rotten update.
6. Trace refrigeration.
7. Trace freezing.
8. Trace cooking.
9. Trace burn state.
10. Trace nutrition transfer.
11. Audit current Recipe.
12. Audit current EvolvedRecipe.
13. Audit current UniqueRecipe.
14. Audit B42 recipe tags/templates.
15. Enumerate all evolved-recipe ingredient mappings.
16. Audit Cooking skill and XP hooks.
17. Audit recipe-learning/knowledge system.
18. Audit ovens/stoves/campfires/barbecues/microwaves.
19. Audit current vanilla canning/preservation.
20. Audit B42 crafting workstations relevant to food.
21. Audit food-state synchronization in MP.
22. Audit recipe execution in dedicated MP.
23. Audit current maintained B42 food/cooking mods as feature research.
24. Run FDW-SPIKE-01 through FDW-SPIKE-30.
25. Replace every assumption with runtime evidence.
26. Build FoodAdapter before adding custom food-state logic.
27. Build IngredientRegistry before hard-coding recipe compatibility.
28. Prove one long-running preservation process through save/load.
29. Prove no nutrition/portion duplication exploit.
30. Test dedicated MP before expanding bulk-food processes.
31. Preserve vanilla food aging as canonical.
32. Only then implement the complete foodWorks preservation/processing roadmap.

CURRENT B42.20 RUNTIME AND THE foodWorks REPOSITORY OVERRIDE THIS DOCUMENT
WHENEVER THEY DISAGREE.