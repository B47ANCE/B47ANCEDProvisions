local API=require "foodWorks/API"
local Inspection={}
local windows={};local reported=false
local function call(target,method,...)
    local fn=target and target[method]
    if type(fn)~="function"then return nil end
    local ok,value=pcall(fn,target,...)
    if ok then return value end
    return nil
end
local function enabled()
    local root=rawget(_G,"SandboxVars");local settings=type(root)=="table"and root.foodWorks or nil
    return type(settings)~="table"or settings.EnableFoodInspection~=false
end
local function safe(value)return tostring(value==nil and"Unavailable"or value):gsub("<","‹"):gsub(">","›"):gsub("\r",""):gsub("\n"," ")end
local function number(value,precision)
    value=tonumber(value);if not value then return"Unavailable"end
    return string.format("%."..tostring(precision or 1).."f",value)
end
function Inspection.format(view,name)
    local nutrition=view.nutrition or{};local ingredient=view.ingredient
    local lines={"Food inspection: "..safe(name or view.fullType),safe(view.fullType),"Freshness: "..safe(view.freshness),
        "Age: "..number(view.age).." / fresh "..number(view.offAge).." / rotten "..number(view.offAgeMax),
        "State: cooked="..tostring(view.cooked)..", burnt="..tostring(view.burnt)..", frozen="..tostring(view.frozen)..
            ", freezing="..tostring(view.freezing)..", thawing="..tostring(view.thawing),
        "Preservation: packaged="..tostring(view.packaged)..", tainted="..tostring(view.tainted)..
            ", freezing progress="..number(view.freezingTime)..", last aged="..number(view.lastAged),
        "Effects: hunger="..number(view.hungerChange,3)..", thirst="..number(view.thirstChange,3)..", heat="..number(view.heat),
        "Nutrition: calories="..number(nutrition.calories)..", carbs="..number(nutrition.carbohydrates)..
            ", protein="..number(nutrition.proteins)..", fat="..number(nutrition.lipids)}
    if ingredient then lines[#lines+1]="Ingredient: "..safe(ingredient.category).." ["..safe(table.concat(ingredient.tags or{},", ")).."]"end
    if view.replaceOnRotten then lines[#lines+1]="Rotten replacement: "..safe(view.replaceOnRotten)end
    lines[#lines+1]="This report is read-only; vanilla remains authoritative for food state."
    return table.concat(lines," <LINE> ")
end
function Inspection.open(playerNum,item)
    if not enabled()then return false end
    local view=API.inspectFood(item);if not view then return false end
    require "ISUI/ISModalRichText"
    if windows[playerNum]then windows[playerNum]:destroy()end
    local width=math.min(620,getPlayerScreenWidth(playerNum)-40);local height=math.min(440,getPlayerScreenHeight(playerNum)-40)
    local modal;modal=ISModalRichText:new(getPlayerScreenLeft(playerNum)+(getPlayerScreenWidth(playerNum)-width)/2,
        getPlayerScreenTop(playerNum)+(getPlayerScreenHeight(playerNum)-height)/2,width,height,
        Inspection.format(view,call(item,"getDisplayName")),false,nil,function()if windows[playerNum]==modal then windows[playerNum]=nil end end,playerNum)
    modal:initialise();modal:addToUIManager();windows[playerNum]=modal;return true
end
function Inspection.fill(playerNum,context,items)
    if not enabled()then return end
    local ok,err=pcall(function()
        local selected=ISInventoryPane.getActualItems(items);if#selected~=1 or not API.inspectFood(selected[1])then return end
        context:addOption(getText("ContextMenu_foodWorks_InspectFood"),playerNum,Inspection.open,selected[1])
    end)
    if not ok and not reported then reported=true;print("[foodWorks] Food inspection unavailable: "..tostring(err))end
end
if Events and Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(Inspection.fill)end
return Inspection
