-- Audited recipe identities, not an arbitrary user-editable whitelist. Gameplay
-- balance/enablement uses the existing server-authoritative fruit sandbox options.
local types={"Apple","Banana","Cherry","Grapefruit","Grapes","Lemon","Lime","Mango","Orange","Peach","Pear","Pineapple",
    "Strewberrie","BerryBlack","BerryBlue","BeautyBerry","WinterBerry","BerryGeneric1","BerryGeneric2","BerryGeneric3","BerryGeneric4","BerryGeneric5"}
local known={}
for _,name in ipairs(types) do known["Base."..name]=name end
local P={}
function P.get(fullType)
    local name=known[fullType]
    if not name then return nil end
    return {fullType=fullType,input="UI_foodWorks_FruitDrying_Input_"..name,
        dried=name=="Apple" and "UI_foodWorks_AppleDrying_DriedName" or "UI_foodWorks_FruitDrying_Dried_"..name}
end
function P.list()
    local copy={}
    for i,name in ipairs(types) do copy[i]="Base."..name end
    return copy
end
return P
