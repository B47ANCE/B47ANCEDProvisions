local added={};local item={getDisplayName=function()return"<Apple>"end}
local view={fullType="Base.Apple",freshness="AGING",age=2.5,offAge=3,offAgeMax=6,cooked=false,burnt=false,
    frozen=false,freezing=true,thawing=false,packaged=true,tainted=false,freezingTime=42,lastAged=80,
    hungerChange=-.1,thirstChange=0,heat=1,nutrition={calories=95,carbohydrates=25,proteins=.5,lipids=.3},
    ingredient={category="fruit",tags={"produce"}},replaceOnRotten="Base.RottenApple"}
package.preload["foodWorks/API"]=function()return{inspectFood=function(candidate)if candidate==item then return view end end}end
Events={OnFillInventoryObjectContextMenu={Add=function(fn)_G.fill=fn end}}
ISInventoryPane={getActualItems=function(items)return items end};SandboxVars={foodWorks={EnableFoodInspection=true}}
getText=function(key)return key end
local Inspection=dofile(arg[1]);local context={addOption=function(self,...)added[#added+1]={...}end}
fill(0,context,{item});assert(#added==1 and added[1][1]=="ContextMenu_foodWorks_InspectFood")
fill(0,context,{item,item});assert(#added==1,"multi-selection must not add inspection")
SandboxVars.foodWorks.EnableFoodInspection=false;fill(0,context,{item});assert(#added==1,"disabled inspection must remain absent")
local text=Inspection.format(view,"<Apple>");assert(text:find("‹Apple›",1,true)and text:find("Freshness: AGING",1,true))
assert(text:find("calories=95.0",1,true)and text:find("Rotten replacement: Base.RottenApple",1,true))
print("foodWorks nil-safe read-only food inspection checks passed")
