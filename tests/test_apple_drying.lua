-- Offline Lua 5.1: synthetic native objects. This is not PZ runtime evidence.
local M=require "foodWorks/AppleDrying"
local API=require "foodWorks/API"
local now,server,client=100,true,false
function isServer() return server end
function isClient() return client end
local function list(values)
    return {size=function()return #values end,get=function(_,i)return values[i+1] end}
end
local function event() local e={handlers={}};e.Add=function(fn)e.handlers[#e.handlers+1]=fn end;return e end
Events={OnClientCommand=event(),EveryTenMinutes=event(),OnFillWorldObjectContextMenu=event(),
    OnFillInventoryObjectContextMenu=event(),OnServerCommand=event()}
ComponentType={DryingCraftLogic=1,Resources=2}
local globalStore={}
ModData={getOrCreate=function()return globalStore end}
function getGameTime()return {getWorldAgeHours=function()return now end}end
function getTimestampMs()return 1000 end
function getText(key,...)
    assert(TRANSLATIONS[key],"Missing translation: "..key)
    return TRANSLATIONS[key]
end
local responses,adds,messages,clientRequests={},{},{},{}
function sendServerCommand(player,module,command,args)responses[#responses+1]={player=player,module=module,command=command,args=args}end
function sendAddItemToContainer(inventory,item)adds[#adds+1]={inventory=inventory,item=item}end
function syncItemModData(player,item)assert(item:getContainer()==player:getInventory())end
function sendClientCommand(player,module,command,args)clientRequests[#clientRequests+1]={player=player,module=module,command=command,args=args}end
local getters={getAge="age",getOffAge="fresh",getOffAgeMax="rotten",getActualWeight="weight",getHungChange="hunger",
    getBaseHunger="baseHunger",getThirstChangeUnmodified="thirst",getCalories="calories",getCarbohydrates="carbs",
    getLipids="lipids",getProteins="proteins",getUnhappyChangeUnmodified="unhappy",getBoredomChangeUnmodified="boredom",
    getPainReduction="pain",getFluReduction="flu",getFoodSicknessChange="sickness",getFatigueChange="fatigue",getEnduranceChangeUnmodified="endurance"}
local mutations={setAge="age",setOffAge="fresh",setOffAgeMax="rotten",setActualWeight="weight",setWeight="weight",
    setCustomWeight="customWeight",setThirstChange="thirst",setName="name",setCustomName="customName"}
local function apple(id,age)
    local item={id=id,data={},s={age=age or 1,fresh=5,rotten=8,weight=0.2,hunger=-0.16,baseHunger=-0.16,thirst=-0.07,
        calories=95,carbs=25.13,lipids=0.31,proteins=0.47,unhappy=0,boredom=0,pain=0,flu=0,sickness=0,fatigue=0,endurance=0},aged=now,fail=nil}
    for method,field in pairs(getters) do local f=field;item[method]=function(self)return self.s[f]end end
    for method,field in pairs(mutations) do local f,n=field,method;item[method]=function(self,value)
        assert(not client,"Client attempted food mutation")
        if self.fail==n then error("injected setter failure")end
        self.s[f]=value
    end end
    for _,method in ipairs({"isFrozen","isFreezing","isThawing","isCooked","isBurnt","isTainted","isPoison","haveExtraItems","hasSpices"}) do
        local m=method;item[m]=function(self)return self[m.."Value"]==true end
    end
    function item:getPoisonPower()return self.poison or 0 end
    function item:getFreezingTime()return self.freezing or 0 end
    function item:getFullType()return self.fullType or "Base.Apple" end
    function item:getID()return self.id end
    function item:isCustomName()return self.s.customName==true end
    function item:getContainer()return self.container end
    function item:hasModData()return next(self.data)~=nil end
    function item:getModData()return self.data end
    function item:updateAge()assert(not client);self.s.age=self.s.age+math.max(0,now-self.aged)/24;self.aged=now end
    return item
end
function instanceItem(kind)assert(kind=="Base.Apple");return apple(999,0)end
local square,station,input,output,logic,p1,p2,inventory,items,objects
local function remove(values,item)for i,v in ipairs(values)do if v==item then table.remove(values,i);return true end end end
local function makePlayer()
    local inv={items={}}
    function inv:getItems()return list(self.items)end
    function inv:AddItem(item)
        if self.reject then error("injected AddItem rejection")end
        assert(not client and item:getContainer()==nil)
        self.items[#self.items+1]=item;item.container=self;return item
    end
    local p={inventory=inv,dead=false}
    function p:getInventory()return self.inventory end
    function p:getCurrentSquare()return self.square or square end
    function p:isDead()return self.dead end
    function p:Say(message)messages[#messages+1]=message end
    return p
end
local function resource()
    local r={items={},synced={},locked=false}
    function r:getItemAmount()return #self.items end
    function r:isLocked()return self.locked end
    function r:peekItem(i)return self.items[(i or 0)+1]end
    function r:getItemById(id)for _,item in ipairs(self.items)do if item.id==id then return item end end end
    function r:sync()
        local item=self.items[1]
        local job=item and M.job(item)
        self.synced[#self.synced+1]={id=item and item.id,phase=job and job.phase,weight=item and item.s.weight,thirst=item and item.s.thirst}
    end
    function r:offerItem(item)
        assert(not client)
        if self.locked or #self.items>0 then return item end
        if item.container then assert(remove(item.container.items,item));item.container=nil end
        self.items[#self.items+1]=item;self:sync();return nil
    end
    function r:removeItemById(id)
        assert(not client)
        local item=self:getItemById(id)
        if item then remove(self.items,item);self:sync()end
        return item
    end
    return r
end
function getCell()return {getGridSquare=function(_,x,y,z)if square and not square.unloaded and x==10 and y==20 and z==0 then return square end end}end
local function reset(age)
    now=100;globalStore={};responses={};adds={};messages={};clientRequests={};server=true;client=false
    square={}
    function square:getX()return 10 end
    function square:getY()return 20 end
    function square:getZ()return 0 end
    function square:isSomethingTo(other)return self.blocked==true or other.blocked==true end
    function square:getObjects()return list(objects)end
    input=resource();output=resource()
    logic={running=false}
    function logic:getInputResources()return list({input})end
    function logic:getOutputResources()return list({output})end
    function logic:isRunning()return self.running end
    function logic:start()error("Native crafting must never start")end
    station={data={}}
    function station:getEntityScript()return {getScriptObjectFullType=function()return self.kind or "Base.Herb_Drying_Rack" end}end
    function station:getComponent(which)if which==1 then return logic elseif which==2 then return {}end end
    function station:getSquare()return square end
    function station:getObjectIndex()return 0 end
    function station:getModData()return self.data end
    function station:hasModData()return next(self.data)~=nil end
    function station:transmitModData()self.transmitted=true end
    objects={station};p1=makePlayer();p2=makePlayer();inventory=p1.inventory
    items=inventory.items;items[1]=apple(10,age);items[1].container=inventory
    SandboxVars={foodWorks={EnableFruitDrying=true,FruitDryingHours=6,FruitDryingShelfLifeMultiplier=6}}
    return items[1]
end
function getSpecificPlayer(index)if index==0 then return p1 elseif index==1 then return p2 end end
local S=dofile(arg[1])
local function privateJob(item)return globalStore.jobs and globalStore.jobs[tostring(item.id)]end
assert(dofile(arg[1])==S and #Events.OnClientCommand.handlers==1 and #Events.EveryTenMinutes.handlers==1,"Duplicate server registration")
local function request(command,id,player,extra)
    local a={x=10,y=20,z=0,index=0,id=id or 10,ui=0}
    for k,v in pairs(extra or {})do a[k]=v end
    return S.handle(player or p1,command,a)
end
local function run(hours)
    for _=1,hours*6 do now=now+1/6;S.tick()end
end
assert(M.settings({}).hours==48 and M.settings({}).multiplier==6)
for _,value in ipairs({0,5,169,6.5,"48",math.huge})do assert(not M.settings({FruitDryingHours=value}))end
assert(not M.settings({EnableFruitDrying=1}))
local item=reset()
assert(request("start")=="Started")
assert(input.items[1]==item and #items==0 and M.job(item).itemId==10)
assert(request("start")=="RackBusy")
assert(request("status",10,p1,{hours=1})=="InvalidRequest")
local job=privateJob(item)
assert(job.credit==0 and job.hours==6)
run(6)
assert(job.phase=="done" and item.id==10 and input.items[1]==item and item:getFullType()=="Base.Apple")
assert(M.close(item.s.weight,0.05) and item.s.thirst==0 and item.s.calories==95 and item.s.carbs==25.13)
assert(item.s.fresh==30 and item.s.rotten==48 and M.close(item.s.age,7.5),"Age must carry 1.25 raw days into 7.5 dried days")
assert(input.synced[#input.synced].phase=="done" and input.synced[#input.synced].weight==0.05)
assert(request("collect",10,p2)=="Collected" and p2.inventory.items[1]==item and #adds==1)
assert(request("collect",10,p1)=="InvalidState" and #adds==1,"Repeated/concurrent collect must not create food")
assert(not M.begin(M.snapshot(instanceItem("Base.Apple")),M.settings({}),"anchor",now,nil))

item=reset(0.5)
SandboxVars.foodWorks.FruitDryingHours=nil;SandboxVars.foodWorks.FruitDryingShelfLifeMultiplier=nil
assert(request("start")=="Started" and M.job(item).hours==48)
run(48)
assert(M.job(item).phase=="done" and M.close(item.s.age,15) and item.s.calories==95,"Default 48-hour batch must conserve food and carry all elapsed age")

item=reset();assert(request("start")=="Started");job=privateJob(item)
now=now+24;S.tick();assert(job.credit==0 and job.last==now,"Long gap must pause")
assert(item.s.age==2 and request("cancel")=="Cancelled")
assert(items[1]==item and item.s.age==2 and not M.job(item) and item.s.fresh==5)

item=reset();assert(request("start")=="Started");job=privateJob(item)
now=now+240;S.tick();assert(job.phase=="failed" and item.s.age>=8)
assert(request("collect")=="NotReady")
assert(request("cancel")=="Cancelled" and item.s.age>=8 and item.s.fresh==5,"Rotten food must not be repaired")

item=reset();assert(request("start")=="Started")
SandboxVars.foodWorks.EnableFruitDrying=false;SandboxVars.foodWorks.FruitDryingHours=168;SandboxVars.foodWorks.FruitDryingShelfLifeMultiplier=12
run(6);assert(M.job(item).phase=="done" and item.s.rotten==48,"Existing job settings must remain frozen")
assert(request("collect")=="Collected")
local fresh=apple(11);inventory:AddItem(fresh)
assert(request("start",11)=="Disabled")

for _,bad in ipairs({
    function(a)a.s.hunger=-0.08 end,function(a)a.s.weight=0.1 end,function(a)a.poison=1 end,
    function(a)a.data.foreign=true end,function(a)a.isFrozenValue=true end,function(a)a.hasSpicesValue=true end,
    function(a)a.getCalories=nil end,function(a)a.s.calories=0/0 end,function(a)a.s.age=5 end,
    function(a)a.s.thirst=-0.02 end,function(a)a.freezing=1 end,function(a)a.s.pain=1 end,
    function(a)a.s.customName=true end})do
    item=reset();bad(item);assert(request("start")=="InvalidApple","Unsafe input accepted")
    assert(items[1]==item and #input.items==0)
end
item=reset();assert(request("start",10,p2)=="InvalidApple","Must bind to engine actor, not another inventory")
assert(request("start",10,p1,{id=math.huge})=="InvalidRequest")
square.blocked=true
local adjacent={getX=function()return 9 end,getY=function()return 20 end,getZ=function()return 0 end,isSomethingTo=function()return false end}
p1.square=adjacent;assert(request("start")=="AccessDenied","Wall must block access")
square.blocked=false;adjacent.getX=function()return 8 end;assert(request("start")=="AccessDenied")
p1.square=nil;p1.dead=true;assert(request("start")=="InvalidRequest")

item=reset();assert(request("start")=="Started");job=privateJob(item)
logic.running=true;run(1);assert(job.credit==0,"Native work must pause this process")
logic.running=false
square.unloaded=true;run(1);square.unloaded=false;now=now+1/6;S.tick();assert(job.credit==0,"No unloaded catch-up")
input:removeItemById(10);inventory:AddItem(item);now=now+1/6;S.tick()
assert(S.handle(p1,"cancelInventory",{id=10,ui=0})=="Cancelled" and not M.job(item))

item=reset();assert(request("start")=="Started");job=privateJob(item)
local copy=apple(11);for k,v in pairs(job)do copy.data[M.KEY]=copy.data[M.KEY] or {};copy.data[M.KEY][k]=v end
input.items={copy};run(6);assert(copy.s.fresh==5 and copy.s.weight==0.2,"Copied metadata must not process a different ID")
assert(request("status",11)=="InvalidState")

item=reset();assert(request("start")=="Started");job=privateJob(item)
item.fail="setOffAge";run(6)
assert(job.phase=="converting" and M.close(item.s.age,7.5) and item.s.fresh==5)
assert(request("collect")=="OperationFailed" and #adds==0)
item.fail=nil
-- Simulate serializable state surviving reload with no Lua object references in records.
local function scalarCopy(value)
    if type(value)~="table" then assert(type(value)=="number" or type(value)=="string");return value end
    local copy={};for k,v in pairs(value)do assert(type(k)=="string");copy[k]=scalarCopy(v)end;return copy
end
item.data[M.KEY]=scalarCopy(job);globalStore=scalarCopy(globalStore)
API.AppleDryingServer=nil;Events.OnClientCommand=event();Events.EveryTenMinutes=event();S=dofile(arg[1])
now=now+1/6;S.tick();job=privateJob(item)
assert(job.phase=="done" and item.s.age>=7.5 and item.s.age<8,"Retry must not rescale age again")
inventory.reject=true;assert(request("collect")=="OperationFailed" and input.items[1]==item,"Rejected transfer must restore the same item")
inventory.reject=false;assert(request("collect")=="Collected" and items[1]==item)

item=reset();assert(request("start")=="Started");job=privateJob(item);job.v=2
assert(request("status")=="InvalidState" and job.v==2 and item.s.weight==0.2,"Unknown schema must survive untouched")
item=reset();globalStore={v=99,next=1,racks={}};assert(request("start")=="Capacity" and globalStore.v==99)

item=reset();assert(request("start")=="Started");inventory.reject=true
assert(request("cancel")=="OperationFailed" and input.items[1]==item and M.valid(M.job(item)),"Failed cancellation must remain manageable")
inventory.reject=false;assert(request("cancel")=="Cancelled")
item=reset();input.offerItem=function()error("injected offer rejection")end
assert(request("start")=="OperationFailed" and items[1]==item and not M.job(item),"Failed offer must not strand a carried marker")
item=reset(4.5);assert(request("start")=="Started");run(6)
assert(M.job(item).phase=="done" and item.s.age>=28.5 and item.s.age<30,"Near-stale age must remain near-stale after drying")
item=reset(4.9);assert(request("start")=="Started");run(6)
assert(M.job(item).phase=="done" and item.s.age>30 and item.s.age<48,"Stale-at-finish apple must stay stale")
item=reset();item.setOffAge=nil;assert(request("start")=="InvalidApple" and items[1]==item,"Missing setter must fail before moving food")
item=reset();assert(request("start")=="Started");run(1);job=privateJob(item)
local earned=job.credit
input:removeItemById(10);inventory:AddItem(item);now=now+1;S.tick()
SandboxVars.foodWorks.EnableFruitDrying=false
assert(request("resume")=="Resumed" and job.credit==earned and input.items[1]==item,"Resume must not award carried time or require new-batch enablement")
item=reset();assert(request("start")=="Started");item.fail="setOffAge";run(6);job=privateJob(item)
assert(job.phase=="converting")
input:removeItemById(10);inventory:AddItem(item);item.fail=nil
assert(request("resume")=="Resumed" and job.phase=="done" and input.items[1]==item,"Carried partial conversion must recover on the same item")
item=reset();assert(request("start")=="Started");job=privateJob(item)
station.data[M.STATION]=nil;S.tick();assert(item.s.weight==0.2 and job.phase=="drying","Replacement station must not complete an old job")
item=reset();assert(request("start")=="Started")
local visible=M.job(item)
assert(visible~=privateJob(item),"Public item metadata must not alias the authoritative ledger")
visible.credit=6;assert(M.job(item).credit==0,"Inspection must return detached snapshots")
visible=item.data[M.KEY] -- simulate a client rewriting its native item metadata directly
visible.credit=6;visible.phase="ready";visible.multiplier=12
now=now+1/60
assert(request("collect")=="NotReady" and #adds==0,"A forged ready flag must never authorize collection")
assert(request("status")=="drying" and privateJob(item).credit<1 and privateJob(item).multiplier==6)
assert(item.s.weight==0.2 and M.job(item).phase=="drying","Forged item progress must be ignored and corrected")
item.s.age=0.1;item.aged=now;S.tick();assert(privateJob(item).phase=="failed","Observed input age must not move backwards")
local forged=scalarCopy(privateJob(item));forged.credit=6;forged.phase="ready"
item=reset();item.data[M.KEY]=forged
assert(request("resume")=="InvalidState" and items[1]==item and item.s.weight==0.2,"No private record means no authority to resume")
item=reset()
for _=1,10 do Events.OnClientCommand.handlers[1]("B47ANCEDProvisions.appleDrying","status",p1,{x=10,y=20,z=0,index=0,id=10,ui=0})end
assert(#responses==8,"RPC burst work must be bounded")

-- Client UI submits intent only, including SP dispatch and controller test mode.
item=reset();server=false;client=true
ISInventoryPane={getActualItems=function(selected)return selected end}
local tested=0;ISWorldObjectContextMenu={setTest=function()tested=tested+1 end}
local context={options={}}
function context:addOption(label,target,fn,...)
    assert(label and type(fn)=="function");self.options[#self.options+1]={target=target,fn=fn,args={...}}
end
local C=dofile(arg[2]);assert(dofile(arg[2])==C and #Events.OnFillWorldObjectContextMenu.handlers==1)
C.fillWorld(0,context,{station},true);assert(tested==1 and #context.options==0)
C.fillWorld(0,context,{station},false);assert(#context.options==1)
local option=context.options[1];option.fn(option.target,unpack(option.args))
assert(#clientRequests==1 and clientRequests[1].command=="start" and #input.items==0 and items[1]==item)
Events.OnServerCommand.handlers[1]("B47ANCEDProvisions.appleDrying","result",{code="Started",ui=0,progress=0})
assert(#messages==1 and callMessage==nil,"No leaked UI globals")
client=false
C.send(0,"start",station,item);assert(input.items[1]==item,"SP uses the same server handler")
client=true;context.options={};C.fillWorld(0,context,{station},false);assert(#context.options==2)
local before=#clientRequests;C.fillInventory(0,context,{item});assert(#clientRequests==before,"Rack items are not carried inventory")
client=false;input:removeItemById(10);inventory:AddItem(item);client=true
context.options={};C.fillInventory(0,context,{item});assert(#context.options==1)
client=false;server=true;API.AppleDryingClient=nil
assert(next(dofile(arg[2]))==nil,"Dedicated server must not install client UI")
client=true;API.AppleDryingServer=nil;assert(next(dofile(arg[1]))==nil,"Client must not install server gameplay")
print("foodWorks in-place apple drying: authority, conservation, age, replay, restart, failures and client intent passed (offline)")
