-- Synthetic Lua 5.1 engine fixtures; no game/server is executed.
local function eq(a,b) assert(math.abs(a-b)<0.0001,tostring(a)..' != '..tostring(b)) end
local onClient=false
function isClient() return onClient end
function isServer() return not onClient end
function getText(key,arg) return arg and (key..':'..arg) or key end
function instanceof(o,kind) return o and o.class==kind end
package.preload['TimedActions/ISBaseTimedAction']=function()
    ISBaseTimedAction={}
    function ISBaseTimedAction:derive(name)
        local o={Type=name};o.__index=o;setmetatable(o,{__index=self});return o
    end
    function ISBaseTimedAction:new(character) return setmetatable({character=character},{__index=self}) end
    function ISBaseTimedAction:perform() end
    function ISBaseTimedAction:stop() end
    function ISBaseTimedAction:setActionAnim() end
    function ISBaseTimedAction:setOverrideHandModels() end
end
local M=require 'foodWorks/SweetPreserves'
local getters=M.fields
local setters={age='setAge',fresh='setOffAge',rotten='setOffAgeMax',weight='setActualWeight',hunger='setHungChange',
    baseHunger='setBaseHunger',thirst='setThirstChange',calories='setCalories',carbs='setCarbohydrates',lipids='setLipids',
    proteins='setProteins',unhappy='setUnhappyChange',boredom='setBoredomChange',pain='setPainReduction',flu='setFluReduction',
    sickness='setFoodSicknessChange',fatigue='setFatigueChange',endurance='setEnduranceChange'}
local kinds={'Base.Apple','Base.BerryBlack','Base.BerryBlue','Base.Cherry','Base.Grapes','Base.Peach','Base.Strewberrie'}
local serial=0
local function factory(kind)
    serial=serial+1
    local s={kind=kind,id=serial,age=0,fresh=10,rotten=20,weight=0.1,hunger=-0.1,baseHunger=-0.1,calories=95,
        carbs=25,lipids=0.3,proteins=0.5,thirst=-0.05,unhappy=0,boredom=0,pain=0,flu=0,sickness=0,fatigue=0,endurance=0}
    if kind=='Base.SugarCubes' then s.fresh=1000000000;s.rotten=s.fresh;s.weight=0.02;s.hunger=-0.04;s.baseHunger=-0.04
        s.calories=44;s.carbs=12;s.lipids=0;s.proteins=0;s.thirst=0 end
    if kind=='Base.EmptyJar' then s.weight=0.2 end
    if kind=='Base.JarLid' then s.weight=0.1 end
    for i,v in ipairs(kinds) do
        if v==kind and i>1 then s.calories=s.calories+i*7;s.carbs=s.carbs+i;s.weight=s.weight+i*0.01 end
    end
    function s:getFullType() return self.kind end
    function s:getID() return self.id end
    function s:getContainer() return self.container end
    function s:hasModData() return self.foreign==true end
    function s:isCustomName() return self.custom==true end
    function s:getName() return self.name or self.kind end
    function s:getCondition() return self.condition or 10 end
    function s:getConditionMax() return 10 end
    function s:getFluidContainer() return {getAmount=function() return self.fluid or 0 end} end
    for _,flag in ipairs({'isFrozen','isFreezing','isThawing','isBurnt','isTainted','isPoison','haveExtraItems','hasSpices','isCooked'}) do
        s[flag]=function(self) return self[flag..'Flag']==true end
    end
    function s:getPoisonPower() return self.poison or 0 end
    function s:getFreezingTime() return 0 end
    for key,getter in pairs(getters) do s[getter]=function(self) return self[key] end end
    for key,setter in pairs(setters) do s[setter]=function(self,value) self[key]=value end end
    function s:setWeight(value) self.weight=value end
    function s:setCustomWeight() end
    function s:setCooked(value) self.isCookedFlag=value end
    function s:setName(value) self.name=value end
    function s:setCustomName(value) self.custom=value end
    return s
end
instanceItem=factory
local A=dofile(arg[1])
local S=dofile(arg[3])
local actor,inv,stove,fruit,published,removed,tools,ingredients
local now=1000
function getTimestampMs()return now end
local function setup(kind)
    SandboxVars={foodWorks={}}
    onClient=false;instanceItem=factory;published={};removed={};tools={};ingredients={}
    inv={items={}}
    function inv:getItems() return {size=function()return #inv.items end,get=function(_,i)return inv.items[i+1]end} end
    function inv:contains(item) for _,v in ipairs(self.items) do if v==item then return true end end return false end
    function inv:getItemById(id)for _,v in ipairs(self.items)do if v.id==id then return v end end end
    function inv:AddItem(item) assert(not self:contains(item));self.items[#self.items+1]=item;item.container=self;return item end
    function inv:Remove(item)
        if self.fail==item then error('injected removal failure') end
        for i,v in ipairs(self.items) do if v==item then table.remove(self.items,i);item.container=nil;return end end
    end
    local function square(x,y)
        return {getX=function()return x end,getY=function()return y end,getZ=function()return 0 end,
            isSomethingTo=function(self) return self.blocked==true end}
    end
    actor={square=square(1,0)}
    function actor:getInventory() return inv end
    function actor:getSquare() return self.square end
    function actor:isDead() return self.dead==true end
    function actor:faceThisObject() end
    stove={class='IsoStove',square=square(0,0),heat=150,powered=true,active=true,index=0}
    function stove:getSquare() return self.square end
    function stove:getCurrentTemperature() return self.heat end
    function stove:isMicrowave() return self.microwave==true end
    function stove:Activated() return self.active end
    function stove:getObjectIndex() return self.index end
    function stove:getContainer() return {isPowered=function()return self.powered end} end
    function getCell()return {getGridSquare=function()return {getObjects=function()return {get=function(_,i)if i==0 then return stove end end}end}end}end
    function sendRemoveItemFromContainer(container,item)
        assert(container==inv and not inv:contains(item));removed[#removed+1]=item
    end
    Actions={addOrDropItem=function(character,item)
        assert(character==actor)
        for _,v in ipairs(ingredients) do assert(not inv:contains(v),'publication preceded debit') end
        assert(item.container==nil)
        if item.kind:find('foodWorks.',1,true) then assert(item.calories>0 and item.age>=0 and item.isCookedFlag) end
        published[#published+1]=item;inv:AddItem(item)
    end}
    local function add(kind,isTool)
        local item=factory(kind);inv:AddItem(item)
        local target=isTool and tools or ingredients;target[#target+1]=item;return item
    end
    fruit=add(kind or 'Base.Apple');fruit.age=5
    add('Base.Apple').age=2
    for i=1,8 do add('Base.SugarCubes') end
    add('Base.EmptyJar');add('Base.JarLid')
    for _,kind in ipairs({'Base.Pot','Base.KitchenKnife','Base.Strainer','Base.CheeseCloth'}) do add(kind,true) end
end
local function action(mode)
    mode=mode or 'jam';now=now+1000
    local id=S.request(actor,{id=fruit.id,mode=mode,x=0,y=0,z=0,index=0})
    local object=stove;if mode=='open' then object=nil end
    local a=A:new(actor,fruit,object,mode,id);a:serverStart();return a
end
for _,kind in ipairs(kinds) do
    for _,mode in ipairs({'jam','jelly'}) do
        setup(kind)
        local expected={calories=0,carbs=0,lipids=0,proteins=0,hunger=0,weight=0.3}
        for _,input in ipairs(ingredients) do
            if input.kind~='Base.EmptyJar' and input.kind~='Base.JarLid' then
                for key in pairs(expected) do expected[key]=expected[key]+input[key] end
            end
        end
        local a=action(mode)
        assert(a:isValid());assert(a:complete())
        assert(#removed==12 and #published==(mode=='jam' and 1 or 2))
        for _,tool in ipairs(tools) do assert(inv:contains(tool)) end
        local jar=published[1]
        eq(jar.age,15);eq(jar.fresh,30);eq(jar.rotten,60)
        local calories,carbs,lipids,proteins,hunger,weight=0,0,0,0,0,0
        for _,out in ipairs(published) do
            calories=calories+out.calories;carbs=carbs+out.carbs;lipids=lipids+out.lipids
            proteins=proteins+out.proteins;hunger=hunger+out.hunger;weight=weight+out.weight
        end
        eq(calories,expected.calories);eq(carbs,expected.carbs);eq(lipids,expected.lipids)
        eq(proteins,expected.proteins);eq(hunger,expected.hunger);eq(weight,expected.weight)
        if mode=='jelly' then
            eq(jar.calories,(expected.calories-352)*0.7+352)
            eq(published[2].calories,(expected.calories-352)*0.3);eq(published[2].age,0.5)
        end
        assert(not a:complete() and #published==(mode=='jam' and 1 or 2),'repeat completion duplicated food')
        -- Open after further native aging; preserve relative age and return the lid.
        ingredients={jar};fruit=jar;jar.age=45;published={};removed={}
        SandboxVars.foodWorks.EnableSweetPreserves=false
        local opening=action('open');assert(opening:complete())
        local opened=published[1]
        eq(opened.age,4.5);eq(opened.fresh,3);eq(opened.rotten,6)
        eq(opened.calories,jar.calories);eq(opened.weight,jar.weight-0.1)
        assert(published[2].kind=='Base.JarLid')
    end
end
-- All rejection/failure paths leave no usable output or duplicate original.
for _,change in ipairs({
    function() fruit.poison=1 end,
    function() fruit.calories=1 end,
    function() fruit.age=10 end,
    function() fruit.foreign=true end,
    function() fruit.isFrozenFlag=true end,
    function() fruit.kind='Base.Banana' end,
    function() ingredients[11].fluid=0.2 end,
    function() ingredients[12].condition=5 end,
    function() stove.heat=99 end,
    function() stove.active=false end,
    function() stove.microwave=true end,
    function() stove.powered=false end,
    function() stove.index=-1 end,
    function() actor.square.blocked=true end,
    function() actor.dead=true end,
    function() SandboxVars.foodWorks.EnableSweetPreserves=false end,
    function() SandboxVars.foodWorks.JellyJuiceYieldPercent=100 end,
    function() SandboxVars.foodWorks.SweetPreservesShelfLifeDays=false end,
}) do
    setup();change();local a=action();assert(not a:complete());assert(#published==0 and #removed==0)
end
setup();local a=action();inv:Remove(ingredients[2]);assert(not a:complete() and #published==0)
setup();a=action();stove.heat=30;assert(not a:complete() and #removed==0)
setup();a=action();a:stop();assert(not a:complete() and #removed==0)
setup();a=action();a.mode='jelly';assert(not a:complete() and #removed==0)
setup();a=A:new(actor,fruit,stove,'jam');assert(not a:complete(),'completion without server start')
setup();a=action();onClient=true;assert(not a:complete() and #removed==0);onClient=false
setup();a=action();inv.fail=ingredients[7];assert(not a:complete())
assert(#published==0 and #inv.items==16)
for _,item in ipairs(ingredients) do assert(inv:contains(item),'rollback lost exact original') end
setup();a=action();instanceItem=function(kind)local item=factory(kind);item.setCalories=function()error('injected setter failure')end;return item end
assert(not a:complete() and #removed==0 and #published==0)
setup();a=action();Actions.addOrDropItem=function()error('injected delivery failure')end
assert(a:complete() and #removed==12 and not a:complete())
setup();a=action();SandboxVars.foodWorks.SweetPreservesShelfLifeDays=90
SandboxVars.foodWorks.JellyJuiceYieldPercent=25
assert(a:complete());eq(published[1].fresh,30)
setup();a=action();local originalRemove=inv.Remove
function inv:Remove(item) originalRemove(self,item);if item==ingredients[5] then error('after detach')end end
assert(not a:complete() and #published==0)
for _,item in ipairs(ingredients) do assert(inv:contains(item)) end
-- SP uses the same completion, without dedicated-server removal packets.
setup();function isServer()return false end;now=now+1000
local spId=S.request(actor,{id=fruit.id,mode='jam',x=0,y=0,z=0,index=0})
a=A:new(actor,fruit,stove,'jam',spId);a:start()
assert(a:complete() and #published==1 and #removed==0)
function isServer()return not onClient end
-- Server defaults/ranges and non-default juice yield; sugar never goes into waste.
setup();SandboxVars.foodWorks.JellyJuiceYieldPercent=25;SandboxVars.foodWorks.SweetPreservesShelfLifeDays=90
SandboxVars.foodWorks.SweetPreservesTimeMultiplier=3;a=action('jelly');eq(a:getDuration(),2700)
assert(a:complete());eq(published[1].calories,399.5);eq(published[2].calories,142.5);eq(published[1].age,45)
-- Menus submit only native action intent and do not touch inventory.
setup();onClient=true
function getSpecificPlayer() return actor end
ISInventoryPane={getActualItems=function(items)return items end}
local received
Events={OnServerCommand={Add=function(fn)received=fn end}}
local C=dofile(arg[2]);local options={}
local context={addOption=function(_,...)options[#options+1]={...}end}
C.fillWorld(0,context,{stove},false);assert(#options==2)
local queued
ISTimedActionQueue={add=function(value)queued=value end}
local intent
function sendClientCommand(character,module,command,args)intent={character=character,module=module,command=command,args=args}end
C.queue(0,fruit,stove,'jelly');assert(not queued and intent.command=='request' and intent.args.id==fruit.id)
assert(not intent.args.character and not intent.args.calories and not intent.args.days)
received(intent.module,'grant',{ui=0,request=intent.args.request,grantId=33})
assert(queued.mode=='jelly' and queued.fruit==fruit and queued.grantId==33 and not queued._plan)
assert(#inv.items==16 and #removed==0)
options={};stove.heat=20;C.fillWorld(0,context,{stove},false);assert(#options==0)
-- A forged native action cannot initiate or reuse an unapproved gameplay transaction.
setup();a=A:new(actor,fruit,stove,'jam',123456);a:serverStart();assert(not a:complete() and #removed==0)
setup();a=action();local replay=A:new(actor,fruit,stove,'jam',a.grantId);replay:serverStart()
assert(not replay:complete());assert(a:complete())
setup();a=action();S.cancel({},a.grantId);assert(S.current(a));S.cancel(actor,a.grantId)
assert(not a:complete() and #removed==0)
setup();a=action();now=now+600001;assert(not a:complete() and #removed==0)
setup();a=action();local impostor={getInventory=function()return inv end,isDead=function()return false end}
local forged=A:new(impostor,fruit,stove,'jam',a.grantId);forged:serverStart()
assert(not forged:complete() and #removed==0)
assert(S.request(actor,{id=fruit.id,mode='jam',x=0,y=0,z=0,index=0,actor=impostor})==nil)
assert(S.request(actor,{id=fruit.id,mode='jam',x=0,y=0,z=0,index=0})==nil,'request throttling')
now=now+1000
local replacement=S.request(actor,{id=fruit.id,mode='jelly',x=0,y=0,z=0,index=0})
assert(replacement and not a:complete(),'new authorized intent must revoke its predecessor')
local latest=A:new(actor,fruit,stove,'jelly',replacement);latest:serverStart();assert(latest:complete())
print('sweet preserves authority, accounting, aging, interruption, replay, recovery and intent-only UI checks passed')
