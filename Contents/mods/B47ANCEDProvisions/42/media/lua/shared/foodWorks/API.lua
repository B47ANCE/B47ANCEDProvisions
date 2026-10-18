foodWorks=rawget(_G,"foodWorks") or {}
foodWorks.VERSION="0.8.0-dev.4"
foodWorks.FoodProviders=foodWorks.FoodProviders or {}
foodWorks.Ingredients=foodWorks.Ingredients or {}

local function call(object,method,...)
    if not object then return nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return nil end
    local called,result=pcall(fn,object,...)
    return called and result or nil
end
local function value(object,key,method)
    if key and type(object)=="table" and object[key]~=nil then return object[key] end
    return call(object,method)
end
local function boolean(object,key,method) return value(object,key,method)==true end
local function number(object,key,method) return tonumber(value(object,key,method)) end
local function normalizeList(values)
    local result,seen={},{}
    for _,entry in ipairs(values or {}) do entry=tostring(entry); if entry~="" and not seen[entry] then seen[entry]=true; result[#result+1]=entry end end
    table.sort(result); return result
end
local function copyIngredient(definition)
    if type(definition)~="table" then return nil end
    return {id=definition.id,category=definition.category,tags=normalizeList(definition.tags),
        processes=normalizeList(definition.processes),providerId=definition.providerId}
end

function foodWorks.registerFoodProvider(definition)
    assert(type(definition)=="table" and type(definition.id)=="string" and type(definition.matches)=="function" and type(definition.inspect)=="function","food provider id/matches/inspect required")
    for _,provider in ipairs(foodWorks.FoodProviders) do assert(provider.id~=definition.id,"duplicate foodWorks provider: "..definition.id) end
    local registered={id=definition.id,priority=tonumber(definition.priority) or 0,
        matches=definition.matches,inspect=definition.inspect}
    foodWorks.FoodProviders[#foodWorks.FoodProviders+1]=registered
    table.sort(foodWorks.FoodProviders,function(a,b) return a.priority==b.priority and a.id<b.id or a.priority>b.priority end)
    return {id=registered.id,priority=registered.priority,matches=registered.matches,inspect=registered.inspect}
end

function foodWorks.registerIngredient(definition)
    assert(type(definition)=="table" and type(definition.id)=="string" and definition.id~="","ingredient id required")
    assert(not foodWorks.Ingredients[definition.id],"duplicate foodWorks ingredient: "..definition.id)
    local normalized={id=definition.id,category=definition.category or "other",tags=normalizeList(definition.tags),processes=normalizeList(definition.processes),providerId=definition.providerId or "thirdParty"}
    foodWorks.Ingredients[normalized.id]=normalized
    return copyIngredient(normalized)
end

function foodWorks.getIngredient(id) return copyIngredient(foodWorks.Ingredients[id]) end
function foodWorks.hasIngredientTag(id,tag)
    local definition=foodWorks.Ingredients[id]
    for _,candidate in ipairs(definition and definition.tags or {}) do if candidate==tag then return true end end
    return false
end

function foodWorks.freshnessState(age,offAge,offAgeMax,rotten)
    if rotten==true then return "ROTTEN" end
    age,offAge,offAgeMax=tonumber(age),tonumber(offAge),tonumber(offAgeMax)
    if not age or not offAge or offAge>=1000000000 then return "SHELF_STABLE" end
    if offAgeMax and age>=offAgeMax then return "ROTTEN" end
    if age>=offAge then return "SPOILED" end
    if offAge>0 and age/offAge>=0.8 then return "AGING" end
    return "FRESH"
end

function foodWorks.inspectFood(item)
    if not item then return nil,"item required" end
    for _,provider in ipairs(foodWorks.FoodProviders) do
        local ok,matches=pcall(provider.matches,item)
        if ok and matches then
            local inspected,result=pcall(provider.inspect,item)
            if inspected and type(result)=="table" then
                local view={};for key,entry in pairs(result)do view[key]=entry end
                view.providerId=provider.id;return view
            end
        end
    end
    return nil,"unsupported food"
end

foodWorks.registerFoodProvider{
    id="vanilla.Food",priority=-100,
    matches=function(item)
        local instance=rawget(_G,"instanceof")
        if type(instance)=="function" then local ok,result=pcall(instance,item,"Food"); if ok and result then return true end end
        return value(item,"hungerChange","getHungerChange")~=nil and (value(item,"offAge","getOffAge")~=nil or value(item,"calories","getCalories")~=nil)
    end,
    inspect=function(item)
        local age=number(item,"age","getAge")
        local offAge=number(item,"offAge","getOffAge")
        local offAgeMax=number(item,"offAgeMax","getOffAgeMax")
        local rotten=boolean(item,"rotten","isRotten")
        local fullType=value(item,"fullType","getFullType")
        return {
            item=item,fullType=fullType and tostring(fullType) or nil,
            ingredient=fullType and foodWorks.getIngredient(tostring(fullType)) or nil,
            age=age,offAge=offAge,offAgeMax=offAgeMax,howRotten=number(item,"howRotten","HowRotten"),
            freshness=foodWorks.freshnessState(age,offAge,offAgeMax,rotten),rotten=rotten,
            cooked=boolean(item,"cooked","isCooked"),burnt=boolean(item,"burnt","isBurnt"),
            packaged=boolean(item,"packaged","isPackaged"),tainted=boolean(item,"tainted","isTainted"),
            frozen=boolean(item,"frozen","isFrozen"),freezing=boolean(item,"freezing","isFreezing"),thawing=boolean(item,"thawing","isThawing"),
            freezingTime=number(item,"freezingTime","getFreezingTime"),lastAged=number(item,"lastAged","getLastAged"),
            cookable=boolean(item,"cookable","isCookable"),canBeFrozen=boolean(item,"canFreeze","canBeFrozen"),
            cookingTime=number(item,"cookingTime","getCookingTime"),minutesToCook=number(item,"minutesToCook","getMinutesToCook"),minutesToBurn=number(item,"minutesToBurn","getMinutesToBurn"),
            rottenTime=number(item,"rottenTime","getRottenTime"),compostTime=number(item,"compostTime","getCompostTime"),
            replaceOnRotten=value(item,"replaceOnRotten","getReplaceOnRotten"),
            heat=number(item,"heat","getItemHeat"),hungerChange=number(item,"hungerChange","getHungerChange"),thirstChange=number(item,"thirstChange","getThirstChange"),
            nutrition={calories=number(item,"calories","getCalories"),carbohydrates=number(item,"carbohydrates","getCarbohydrates"),proteins=number(item,"proteins","getProteins"),lipids=number(item,"lipids","getLipids")},
        }
    end,
}

_G.foodWorks=foodWorks
return foodWorks
