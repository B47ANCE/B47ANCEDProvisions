-- Pure selection/accounting. Gameplay mutation belongs to the native timed action.
local API=require "foodWorks/API"
local D=require "foodWorks/AppleDrying"
if API.SweetPreserves then return API.SweetPreserves end
local M={}
API.SweetPreserves=M
local read=D.read
M.read=read
local FRUIT={['Base.Apple']=true,['Base.BerryBlack']=true,['Base.BerryBlue']=true,
    ['Base.Cherry']=true,['Base.Grapes']=true,['Base.Peach']=true,['Base.Strewberrie']=true}
local SEALED={['foodWorks.JamSealed']='jam',['foodWorks.JellySealed']='jelly'}
local BASELINES={}
local F={age='getAge',fresh='getOffAge',rotten='getOffAgeMax',weight='getActualWeight',
    hunger='getHungChange',baseHunger='getBaseHunger',thirst='getThirstChangeUnmodified',calories='getCalories',
    carbs='getCarbohydrates',lipids='getLipids',proteins='getProteins',unhappy='getUnhappyChangeUnmodified',
    boredom='getBoredomChangeUnmodified',pain='getPainReduction',flu='getFluReduction',sickness='getFoodSicknessChange',
    fatigue='getFatigueChange',endurance='getEnduranceChangeUnmodified'}
M.fields=F
function M.settings()
    local v=type(SandboxVars)=='table' and SandboxVars.foodWorks or {}
    v=v or {}
    if type(v)~='table' then return nil end
    local days=v.SweetPreservesShelfLifeDays
    local time=v.SweetPreservesTimeMultiplier
    local yield=v.JellyJuiceYieldPercent
    if days==nil then days=30 end
    if time==nil then time=1 end
    if yield==nil then yield=70 end
    if not D.integer(days,7,180) or not D.integer(time,1,5) or not D.integer(yield,25,90)
        or (v.EnableSweetPreserves~=nil and type(v.EnableSweetPreserves)~='boolean') then return nil end
    return {enabled=v.EnableSweetPreserves~=false,days=days,time=time,yield=yield/100}
end
function M.supported(kind) return FRUIT[kind]==true end
function M.sealed(kind) return SEALED[kind] end
local function noForeignData(item)
    if read(item,'hasModData')==false then return true end
    local data=read(item,'getModData')
    return type(data)=='table' and next(data)==nil
end
local function plain(item)
    return noForeignData(item) and read(item,'isCustomName')==false
end
function M.food(item,allowCooked)
    for _,flag in ipairs({'isFrozen','isFreezing','isThawing','isBurnt','isTainted','isPoison','haveExtraItems','hasSpices'}) do
        if read(item,flag)~=false then return nil end
    end
    if not allowCooked and read(item,'isCooked')~=false then return nil end
    if read(item,'getPoisonPower')~=0 or read(item,'getFreezingTime')~=0 then return nil end
    local s={}
    for key,getter in pairs(F) do
        s[key]=read(item,getter)
        if not D.finite(s[key]) or math.abs(s[key])>1000000000 then return nil end
    end
    if s.age<0 or s.fresh<=0 or s.rotten<s.fresh or s.weight<=0 or s.hunger>=0
        or s.calories<0 or s.carbs<0 or s.lipids<0 or s.proteins<0 then return nil end
    return s
end
function M.whole(item)
    local kind=read(item,'getFullType')
    if not (FRUIT[kind] or kind=='Base.SugarCubes') or not plain(item) then return nil end
    local s=M.food(item)
    if not s or s.age>=s.fresh then return nil end
    local b=BASELINES[kind]
    if not b then
        local reference=type(instanceItem)=='function' and instanceItem(kind)
        b=reference and M.food(reference)
        if b then BASELINES[kind]=b end
    end
    if not b then return nil end
    for key in pairs(F) do if key~='age' and not D.close(s[key],b[key]) then return nil end end
    return s
end
local function empty(item)
    local fluid=read(item,'getFluidContainer')
    return fluid~=nil and read(fluid,'getAmount')==0
end
local function owned(inv,item)
    return item~=nil and read(item,'getContainer')==inv and read(inv,'contains',item)==true
end
M.owned=owned
function M.select(character,mode,fruit)
    local cfg=M.settings()
    local inv=read(character,'getInventory')
    if not cfg or not inv or read(character,'isDead')~=false or not owned(inv,fruit) then return nil end
    if mode=='open' then
        local kind=SEALED[read(fruit,'getFullType')]
        local s=kind and M.food(fruit,true)
        -- Native food fields are the persistent authority; no client ModData ledger.
        if not s or not noForeignData(fruit) then return nil end
        return {mode=mode,kind=kind,consume={fruit},foods={s},cfg=cfg,inv=inv}
    end
    if (mode~='jam' and mode~='jelly') or not cfg.enabled or not FRUIT[read(fruit,'getFullType')] then return nil end
    local first=M.whole(fruit)
    if not first then return nil end
    local items=read(inv,'getItems')
    local count=read(items,'size')
    if not D.integer(count,0,256) then return nil end
    local plan={mode=mode,kind=mode,consume={fruit},foods={first},keep={},cfg=cfg,inv=inv}
    local apple,jar,lid,pot,knife,strainer,cloth
    local sugar={}
    for i=0,count-1 do
        local item=read(items,'get',i)
        if item~=fruit and owned(inv,item) then
            local kind=read(item,'getFullType')
            if kind=='Base.Apple' and not apple and M.whole(item) then apple=item
            elseif kind=='Base.SugarCubes' and #sugar<8 and M.whole(item) then sugar[#sugar+1]=item
            elseif kind=='Base.EmptyJar' and not jar and plain(item) and empty(item) then jar=item
            elseif kind=='Base.JarLid' and not lid and plain(item) and read(item,'getCondition')==read(item,'getConditionMax')
                and (read(item,'getCondition') or 0)>0 then lid=item
            elseif kind=='Base.Pot' and not pot and empty(item) then pot=item
            elseif kind=='Base.KitchenKnife' and not knife and (read(item,'getCondition') or 0)>0 then knife=item
            elseif kind=='Base.Strainer' and not strainer then strainer=item
            elseif kind=='Base.CheeseCloth' and not cloth then cloth=item end
        end
    end
    if not apple or not jar or not lid or not pot or not knife or #sugar~=8
        or (mode=='jelly' and (not strainer or not cloth)) then return nil end
    plan.consume[#plan.consume+1]=apple;plan.foods[#plan.foods+1]=M.whole(apple)
    for _,item in ipairs(sugar) do plan.consume[#plan.consume+1]=item;plan.foods[#plan.foods+1]=M.whole(item) end
    plan.consume[#plan.consume+1]=jar;plan.consume[#plan.consume+1]=lid
    plan.keep={pot,knife}
    if mode=='jelly' then plan.keep[#plan.keep+1]=strainer;plan.keep[#plan.keep+1]=cloth end
    return plan
end
function M.heat(character,object)
    if type(instanceof)~='function' or not instanceof(object,'IsoStove') or read(object,'getObjectIndex')==nil
        or read(object,'getObjectIndex')<0 or read(object,'Activated')~=true or read(object,'isMicrowave')~=false then return false end
    local heat=read(object,'getCurrentTemperature')
    local container=read(object,'getContainer')
    if not D.finite(heat) or heat<100 or read(container,'isPowered')~=true then return false end
    local a=read(character,'getSquare');local b=read(object,'getSquare')
    if not a or not b or read(a,'getZ')~=read(b,'getZ') then return false end
    local x,y=read(a,'getX'),read(a,'getY');local bx,by=read(b,'getX'),read(b,'getY')
    if not D.finite(x) or not D.finite(y) or not D.finite(bx) or not D.finite(by) or math.abs(x-bx)+math.abs(y-by)~=1 then return false end
    return read(a,'isSomethingTo',b)==false and read(b,'isSomethingTo',a)==false
end
function M.account(plan)
    local total={weight=0,hunger=0,baseHunger=0,thirst=0,calories=0,carbs=0,lipids=0,proteins=0,
        unhappy=0,boredom=0,pain=0,flu=0,sickness=0,fatigue=0,endurance=0}
    local pulp={}
    for key in pairs(total) do pulp[key]=0 end
    local age=0
    for i,s in ipairs(plan.foods) do
        local share=plan.mode=='jelly' and i<=2 and plan.cfg.yield or 1
        for key in pairs(total) do total[key]=total[key]+s[key]*share;pulp[key]=pulp[key]+s[key]*(1-share) end
        if i<=2 then age=math.max(age,s.age/s.fresh) end
    end
    total.fresh=plan.cfg.days;total.rotten=plan.cfg.days*2;total.age=age*total.fresh
    total.weight=total.weight+0.3 -- Consumed native jar + lid mass; returned on eating the opened jar.
    pulp.fresh=1;pulp.rotten=2;pulp.age=age
    return total,pulp
end
return M
