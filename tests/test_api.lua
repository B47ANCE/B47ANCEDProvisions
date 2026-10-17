package.loaded["foodWorks/API"]=nil
_G.foodWorks=nil
local API=require "foodWorks/API"
local cachedProviderModel={marker="original"}
local providerDefinition={id="test.protected",priority=100,
    matches=function(candidate)return candidate.protectedFood==true end,
    inspect=function()return cachedProviderModel end}
local providerResult=API.registerFoodProvider(providerDefinition)
providerDefinition.matches=function()return false end
providerDefinition.inspect=function()return {marker="mutated-input"}end
providerResult.matches=function()return false end
providerResult.inspect=function()return {marker="mutated-result"}end
local providerView=assert(API.inspectFood({protectedFood=true}))
assert(providerView.marker=="original" and providerView.providerId=="test.protected",
    "provider registration must snapshot callbacks instead of retaining a mutable definition")
assert(cachedProviderModel.providerId==nil,"inspection must not decorate a provider-owned result table")
providerView.marker="consumer mutation"
assert(API.inspectFood({protectedFood=true}).marker=="original",
    "inspection must return a detached top-level provider view")
local registered=API.registerIngredient{id="Base.Apple",category="fruit",tags={"fruit","produce"},processes={"dry","cook"},providerId="foodWorks"}
assert(API.hasIngredientTag("Base.Apple","fruit"))
registered.category="corrupted";registered.tags[1]="corrupted";registered.processes[1]="corrupted"
local protected=assert(API.getIngredient("Base.Apple"))
assert(protected.category=="fruit" and API.hasIngredientTag("Base.Apple","fruit"),
    "registration results must not expose mutable canonical ingredient state")
protected.category="also-corrupted";protected.tags[1]="also-corrupted"
assert(API.getIngredient("Base.Apple").category=="fruit" and API.hasIngredientTag("Base.Apple","fruit"),
    "ingredient lookups must return protected snapshots")
local item={fullType="Base.Apple",age=2,offAge=3,offAgeMax=6,hungerChange=-.1,calories=95,proteins=.5,lipids=.3,carbohydrates=25,heat=1,
    packaged=true,tainted=true,freezingTime=42,lastAged=81,rottenTime=10,compostTime=14,replaceOnRotten="Base.RottenApple"}
function item:getFullType() return self.fullType end
function item:getAge() return self.age end
function item:getOffAge() return self.offAge end
function item:getOffAgeMax() return self.offAgeMax end
function item:getHungerChange() return self.hungerChange end
function item:getCalories() return self.calories end
function item:getProteins() return self.proteins end
function item:getLipids() return self.lipids end
function item:getCarbohydrates() return self.carbohydrates end
function item:getItemHeat() return self.heat end
function item:isRotten() return false end
function item:isCooked() return false end
function item:isBurnt() return false end
function item:isFrozen() return false end
function item:isFreezing() return true end
function item:isThawing() return false end
function item:isPackaged() return self.packaged end
function item:isTainted() return self.tainted end
function item:getFreezingTime() return self.freezingTime end
function item:getLastAged() return self.lastAged end
function item:getRottenTime() return self.rottenTime end
function item:getCompostTime() return self.compostTime end
function item:getReplaceOnRotten() return self.replaceOnRotten end
local view=assert(API.inspectFood(item))
assert(view.fullType=="Base.Apple" and view.freshness=="FRESH" and view.ingredient.category=="fruit")
view.ingredient.category="view-corrupted"
assert(API.inspectFood(item).ingredient.category=="fruit","food views must not expose canonical ingredient state")
assert(view.nutrition.calories==95 and view.heat==1)
assert(view.packaged and view.tainted and view.freezing and not view.frozen and not view.thawing)
assert(view.freezingTime==42 and view.lastAged==81 and view.rottenTime==10 and view.compostTime==14)
assert(view.replaceOnRotten=="Base.RottenApple")
item.age=2.5
assert(API.inspectFood(item).freshness=="AGING")
item.age=6
assert(API.inspectFood(item).freshness=="ROTTEN")
assert(API.freshnessState(20,1000000000,nil,false)=="SHELF_STABLE")
print("foodWorks food-adapter/ingredient/freshness/preservation-state checks passed")
