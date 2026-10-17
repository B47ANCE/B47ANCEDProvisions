-- All shared gameplay writes live here. No native crafting job is started.
if type(isClient)=="function" and isClient() then return {} end
local API=require "foodWorks/API"
if API.AppleDryingServer then return API.AppleDryingServer end
local M=require "foodWorks/AppleDrying"
local S={}
API.AppleDryingServer=S
local read=M.read
local RACKS={['Base.Herb_Drying_Rack']=true,['Base.Simple_Herb_Drying_Rack']=true}
-- Technical work bounds, not gameplay balance controls.
local MAX_RACKS,MAX_OBJECTS,MAX_ITEMS=256,256,256
local SETTERS={"setAge","setOffAgeMax","setOffAge","setActualWeight","setWeight","setCustomWeight","setThirstChange","setName","setCustomName"}
local function capable(object,names)
    if not object then return false end
    for _,name in ipairs(names) do
        local ok,available=pcall(function()return type(object[name])=="function" end)
        if not ok or not available then return false end
    end
    return true
end
local function call(object,name,...)
    if object==nil or type(object[name])~="function" then error("Missing native capability: "..name) end
    return object[name](object,...)
end
local function clock() return read(getGameTime(),"getWorldAgeHours") end
local function md(object) return call(object,"getModData") end
local function settings() return M.settings(type(SandboxVars)=="table" and SandboxVars.foodWorks or nil) end
local function registry()
    if not ModData or type(ModData.getOrCreate)~="function" then return nil end
    local store=ModData.getOrCreate(M.INDEX)
    if type(store)~="table" then return nil end
    if next(store)==nil then store.v=1;store.next=1;store.racks={};store.jobs={} end
    if store.v~=1 or not M.integer(store.next,1,1000000000) or type(store.racks)~="table" or type(store.jobs)~="table" then return nil end
    return store
end
local function authoritative(item)
    local store=registry()
    local id=read(item,"getID")
    if not store or not M.integer(id,-2147483648,2147483647) then return nil end
    local job=store.jobs[tostring(id)]
    if M.valid(job) and job.itemId==id then return job end
end
local function mirror(item,job)
    -- Never alias a private ledger table with client-visible/native item ModData.
    local copy={}
    for key,value in pairs(job) do copy[key]=value end
    md(item)[M.KEY]=copy
end
local function forget(item)
    local store=registry()
    if store then store.jobs[tostring(read(item,"getID"))]=nil end
end
local function rackType(object)
    return RACKS[read(read(object,"getEntityScript"),"getScriptObjectFullType")]==true
end
local function holder(object)
    if not rackType(object) or not ComponentType then return nil end
    local logic=read(object,"getComponent",ComponentType.DryingCraftLogic)
    if not logic or not read(object,"getComponent",ComponentType.Resources) then return nil end
    local inputs,outputs=read(logic,"getInputResources"),read(logic,"getOutputResources")
    if read(inputs,"size")~=1 or read(outputs,"size")~=1 then return nil end
    local input,output=read(inputs,"get",0),read(outputs,"get",0)
    local count=read(input,"getItemAmount")
    if not M.integer(count,0,20) then return nil end
    return input,output,logic,count
end
local function at(player,object)
    if read(player,"isDead")~=false then return false end
    local a,b=read(player,"getCurrentSquare"),read(object,"getSquare")
    if not a or not b or read(a,"getZ")~=read(b,"getZ") then return false end
    local ax,ay,bx,by=read(a,"getX"),read(a,"getY"),read(b,"getX"),read(b,"getY")
    if not (M.finite(ax) and M.finite(ay) and M.finite(bx) and M.finite(by)) then return false end
    -- Cardinal adjacency only: diagonal reach never cuts through a corner.
    if math.abs(ax-bx)+math.abs(ay-by)>1 then return false end
    return a==b or (read(a,"isSomethingTo",b)==false and read(b,"isSomethingTo",a)==false)
end
local function mainItem(player,id)
    local inventory=read(player,"getInventory")
    local items=read(inventory,"getItems")
    local n=read(items,"size")
    if not M.integer(n,0,1000000) then return nil end
    for i=0,math.min(n,MAX_ITEMS)-1 do
        local item=read(items,"get",i)
        if read(item,"getID")==id and read(item,"getContainer")==inventory then return item end
    end
end
local function ownData(item)
    if read(item,"hasModData")==false then return true end
    local data=read(item,"getModData")
    if type(data)~="table" then return false end
    for key in pairs(data) do if key~=M.KEY then return false end end
    return true
end
local function baseline()
    if type(instanceItem)~="function" then return nil end
    -- Unowned comparison object only; never added to an inventory/resource/world.
    return M.snapshot(instanceItem("Base.Apple"))
end
local function anchor(object,create)
    local store=registry()
    local square=read(object,"getSquare")
    if not store or not square then return nil end
    local data=md(object)
    local uid=data[M.STATION]
    if uid==nil and create then
        local now=clock()
        if not M.finite(now) or now<0 then return nil end
        uid=tostring(store.next).."_"..string.format("%.6f",now);store.next=store.next+1
        data[M.STATION]=uid
        call(object,"transmitModData")
    end
    if type(uid)~="string" or not uid:match("^%d+_%d+%.%d+$") or #uid>40 then return nil end
    local x,y,z=read(square,"getX"),read(square,"getY"),read(square,"getZ")
    if not M.integer(x,-1000000,1000000) or not M.integer(y,-1000000,1000000) or not M.integer(z,-32,32) then return nil end
    return uid..":"..x..":"..y..":"..z,{x=x,y=y,z=z,uid=uid},store
end
local function track(object)
    local key,record,store=anchor(object,true)
    if not key then return nil end
    if not store.racks[key] then
        local count=0
        for _ in pairs(store.racks) do count=count+1;if count>=MAX_RACKS then return nil end end
        store.racks[key]=record
    end
    return key
end
local function sync(resource) call(resource,"sync") end
local function commit(item,job)
    if not M.valid(job) or job.phase~="converting" or not ownData(item) or not capable(item,SETTERS) then return false end
    local s=M.snapshot(item)
    local base=M.base(job)
    local standard=baseline()
    if not s or not M.matches(base,standard) then return false end
    -- Replays only finish this item's existing conversion. They never recreate it.
    for _,field in ipairs({"hunger","baseHunger","calories","carbs","lipids","proteins","unhappy","boredom","pain","flu","sickness","fatigue","endurance"}) do
        if not M.close(s[field],base[field]) then return false end
    end
    local function oldOrNew(value,old,new) return M.close(value,old) or M.close(value,new) end
    if not oldOrNew(s.weight,base.weight,base.weight/4) or not oldOrNew(s.thirst,base.thirst,0)
        or not oldOrNew(s.fresh,base.fresh,base.fresh*job.multiplier)
        or not oldOrNew(s.rotten,base.rotten,base.rotten*job.multiplier) then return false end
    -- Age first; partial failure can over-age but never refresh food. Each setter
    -- is idempotent. The plan remains on this same saved item until completion.
    call(item,"setAge",math.max(s.age,job.targetAge))
    call(item,"setOffAgeMax",base.rotten*job.multiplier)
    call(item,"setOffAge",base.fresh*job.multiplier)
    call(item,"setActualWeight",base.weight/4)
    call(item,"setWeight",base.weight/4)
    call(item,"setCustomWeight",true)
    call(item,"setThirstChange",0)
    call(item,"setName",getText("UI_foodWorks_AppleDrying_DriedName"))
    call(item,"setCustomName",true)
    local expected=M.base(job)
    expected.weight=expected.weight/4;expected.thirst=0
    expected.fresh=expected.fresh*job.multiplier;expected.rotten=expected.rotten*job.multiplier
    local after=M.snapshot(item)
    if not M.matches(after,expected) or (after.age<job.targetAge and not M.close(after.age,job.targetAge)) or read(item,"getID")~=job.itemId
        or read(item,"isCustomName")~=true then error("Native apple conversion postconditions failed") end
    job.phase="done"
    return true
end
local function update(object,input,logic,item,key)
    local job=authoritative(item)
    if not M.valid(job) or job.itemId~=read(item,"getID") or job.anchor~=key then return nil end
    call(item,"updateAge")
    if job.phase=="done" or job.phase=="failed" then mirror(item,job);sync(input);return job end
    local now=clock()
    if not M.finite(now) then return nil end
    if job.phase=="converting" then mirror(item,job);commit(item,job);mirror(item,job);sync(input);return job end
    local snapshot=M.snapshot(item)
    if not ownData(item) or read(item,"isCustomName")~=false or not M.matches(M.base(job),baseline()) or not snapshot or snapshot.age>=snapshot.rotten then
        job.phase="failed"
    elseif read(logic,"isRunning")~=false or read(input,"getItemAmount")~=1 then
        job.last=math.max(job.last,now) -- pause while a native/foreign operation owns the rack
    else
        M.advance(job,snapshot,now)
        if job.phase=="ready" then
            if M.plan(job,snapshot,now) then mirror(item,job);commit(item,job) else job.phase="failed" end
        end
    end
    mirror(item,job)
    sync(input) -- food and ModData are finalized before the explicit native resource sync
    return job
end
local function take(player,input,item)
    local inventory=read(player,"getInventory")
    if not capable(inventory,{"AddItem"}) or not capable(input,{"removeItemById","offerItem","sync"})
        or (type(isServer)=="function" and isServer() and type(sendAddItemToContainer)~="function")
        or read(input,"isLocked")~=false or read(input,"getItemById",read(item,"getID"))~=item then return false end
    -- Verified vanilla resource -> inventory path, with exact identity and no poll fallback.
    local removed=call(input,"removeItemById",read(item,"getID"))
    if removed~=item then return false end
    local ok,err=pcall(function() call(inventory,"AddItem",item) end)
    if read(item,"getContainer")~=inventory then
        -- Restore the actual object after a known rejection; no replacement is created.
        call(input,"offerItem",item)
        sync(input)
        if not ok then error(err) end
        return false
    end
    if type(isServer)=="function" and isServer() then sendAddItemToContainer(inventory,item) end
    return true
end
local function resolve(player,args)
    local square=read(getCell(),"getGridSquare",args.x,args.y,args.z)
    local objects=read(square,"getObjects")
    local n=read(objects,"size")
    if not M.integer(n,0,MAX_OBJECTS) or args.index>=n then return nil end
    local object=read(objects,"get",args.index)
    if not rackType(object) or not at(player,object) then return nil end
    return object
end
local function request(player,command,args)
    if type(args)~="table" or not ({start=true,resume=true,status=true,cancel=true,collect=true,cancelInventory=true})[command] then return "InvalidRequest" end
    local allowed={x=true,y=true,z=true,index=true,id=true,ui=true}
    for k in pairs(args) do if not allowed[k] then return "InvalidRequest" end end
    if not M.integer(args.id,-2147483648,2147483647) or not M.integer(args.ui,0,3) or read(player,"isDead")~=false then return "InvalidRequest" end
    if command=="cancelInventory" then
        local item=mainItem(player,args.id)
        local job=authoritative(item)
        if not M.valid(job) or job.itemId~=args.id or not ownData(item) or job.phase=="done" or job.phase=="converting" then return "InvalidState" end
        if type(isServer)=="function" and isServer() and type(syncItemModData)~="function" then return "OperationFailed" end
        md(item)[M.KEY]=nil
        forget(item)
        -- Only metadata changes here. The command never mutates food or creates output.
        if type(isServer)=="function" and isServer() then syncItemModData(player,item) end
        return "Cancelled"
    end
    if not M.integer(args.x,-1000000,1000000) or not M.integer(args.y,-1000000,1000000)
        or not M.integer(args.z,-32,32) or not M.integer(args.index,0,MAX_OBJECTS-1) then return "InvalidRequest" end
    local object=resolve(player,args)
    local input,output,logic,count=holder(object)
    if not input then return "AccessDenied" end
    if command=="resume" then
        if count~=0 or read(output,"getItemAmount")~=0 or read(logic,"isRunning")~=false
            or read(input,"isLocked")~=false or not capable(input,{"offerItem","sync","getItemById"}) then return "RackBusy" end
        local item=mainItem(player,args.id)
        local job=authoritative(item)
        if not M.valid(job) or job.itemId~=args.id or job.phase=="done" or job.phase=="failed"
            or not ownData(item) or not capable(item,SETTERS) then return "InvalidState" end
        call(item,"updateAge")
        local snapshot=M.snapshot(item)
        if not snapshot or not M.matches(M.base(job),baseline()) then return "InvalidApple" end
        if job.phase~="converting" and (not M.matches(snapshot,M.base(job)) or snapshot.age>=snapshot.rotten
            or read(item,"isCustomName")~=false) then return "InvalidApple" end
        local key=track(object)
        local now=clock()
        if not key or not M.finite(now) then return "Capacity" end
        job.anchor=key;job.last=math.max(job.last,now) -- never credit carried time
        mirror(item,job)
        call(input,"offerItem",item)
        if read(input,"getItemById",args.id)~=item or read(item,"getContainer")==read(player,"getInventory") then return "OperationFailed" end
        sync(input)
        return "Resumed",update(object,input,logic,item,key)
    end
    if command=="start" then
        local cfg=settings()
        if not cfg then return "InvalidSettings" end
        if not cfg.enabled then return "Disabled" end
        if count~=0 or read(output,"getItemAmount")~=0 or read(logic,"isRunning")~=false
            or read(input,"isLocked")~=false then return "RackBusy" end
        local item=mainItem(player,args.id)
        if not item or not capable(item,SETTERS) or not capable(input,{"offerItem","sync","getItemById"})
            or read(item,"hasModData")~=false or read(item,"isCustomName")~=false then return "InvalidApple" end
        call(item,"updateAge")
        local snapshot=M.snapshot(item)
        if not M.matches(snapshot,baseline()) then return "InvalidApple" end
        local store=registry()
        if not store then return "Capacity" end
        if store.jobs[tostring(args.id)]~=nil then return "InvalidState" end
        local jobs=0
        for _ in pairs(store.jobs) do jobs=jobs+1;if jobs>=MAX_RACKS then return "Capacity" end end
        local key=track(object)
        if not key then return "Capacity" end
        local job=M.begin(snapshot,cfg,key,clock(),args.id)
        if not job then return "InvalidApple" end
        store.jobs[tostring(args.id)]=job
        mirror(item,job)
        local offered,offerError=pcall(function() call(input,"offerItem",item) end)
        if read(input,"getItemById",args.id)~=item or read(item,"getContainer")==read(player,"getInventory") then
            if read(item,"getContainer")==read(player,"getInventory") then md(item)[M.KEY]=nil;forget(item) end
            if not offered then error(offerError) end
            return "OperationFailed"
        end
        if not offered then error(offerError) end
        sync(input)
        return "Started",job
    end
    local item=read(input,"getItemById",args.id)
    local key=anchor(object,false)
    local job=authoritative(item)
    if not item or not key or not M.valid(job) or job.anchor~=key or not ownData(item) then return "InvalidState" end
    if not track(object) then return "Capacity" end
    job=update(object,input,logic,item,key)
    if not job then return "InvalidState" end
    if command=="status" then return job.phase,job end
    if command=="collect" then
        if job.phase~="done" then return "NotReady",job end
        call(item,"updateAge")
        if take(player,input,item) then forget(item);return "Collected",job end
        return "OperationFailed",job
    end
    if job.phase=="done" or job.phase=="converting" then return "InvalidState",job end
    -- Cancellation discards only process metadata, preserving the actual aged input.
    md(item)[M.KEY]=nil
    sync(input)
    local ok,taken=pcall(take,player,input,item)
    if not ok or not taken then
        if read(input,"getItemById",args.id)==item then mirror(item,job);sync(input) end
        if not ok then error(taken) end
        return "OperationFailed"
    end
    forget(item)
    return "Cancelled"
end
function S.handle(player,command,args)
    if type(isClient)=="function" and isClient() then return "AccessDenied" end
    local ok,code,job=pcall(request,player,command,args)
    if not ok then print("[Provisions] apple drying command failed: "..tostring(code));return "OperationFailed" end
    return code,job
end
local function findRack(record)
    if type(record)~="table" or not M.integer(record.x,-1000000,1000000) or not M.integer(record.y,-1000000,1000000)
        or not M.integer(record.z,-32,32) or type(record.uid)~="string" then return nil,false end
    local square=read(getCell(),"getGridSquare",record.x,record.y,record.z)
    if not square then return nil,true end -- unloaded: keep the index, never award catch-up
    local objects=read(square,"getObjects")
    local n=read(objects,"size")
    if not M.integer(n,0,MAX_OBJECTS) then return nil,true end
    for i=0,n-1 do
        local object=read(objects,"get",i)
        if rackType(object) and read(object,"hasModData")==true and md(object)[M.STATION]==record.uid then return object,true end
    end
    return nil,false
end
function S.tick()
    if type(isClient)=="function" and isClient() then return end
    local store=registry()
    if not store then return end
    local processed=0
    local checked,seen={},{ }
    for key,record in pairs(store.racks) do
        processed=processed+1
        if processed>MAX_RACKS then print("[Provisions] drying index exceeds safety bound");return end
        local ok,keep=pcall(function()
            local object,retain=findRack(record)
            if not object then return retain end
            local input,_,logic,count=holder(object)
            if not input then return true end
            checked[key]=true
            local active=false
            for i=0,count-1 do
                local item=read(input,"peekItem",i)
                local job=update(object,input,logic,item,key)
                if job then active=true;seen[tostring(job.itemId)]=true end
            end
            return active
        end)
        if not ok then print("[Provisions] apple drying tick failed: "..tostring(keep))
        elseif not keep then store.racks[key]=nil end
    end
    local jobs=0
    for id,job in pairs(store.jobs) do
        jobs=jobs+1
        if jobs>MAX_RACKS then print("[Provisions] drying ledger exceeds safety bound");return end
        if M.valid(job) and checked[job.anchor] and not seen[id] and job.phase=="done" then
            store.jobs[id]=nil -- native collection/removal; never recreate a missing physical item
        end
    end
end
local requestWindows=setmetatable({},{__mode="k"}) -- transient per-actor network work bound
local function onCommand(module,command,player,args)
    if module~="B47ANCEDProvisions.appleDrying" then return end
    if player==nil or type(getTimestampMs)~="function" then return end
    local now=getTimestampMs()
    if not M.finite(now) then return end
    local window=requestWindows[player]
    if not window or now<window.at or now-window.at>=1000 then window={at=now,count=0};requestWindows[player]=window end
    if window.count>=8 then return end
    window.count=window.count+1
    local code,job=S.handle(player,command,args)
    local ui=type(args)=="table" and args.ui or 0
    if not M.integer(ui,0,3) then ui=0 end
    sendServerCommand(player,module,"result",{code=code,ui=ui,
        progress=M.valid(job) and math.floor(job.credit/job.hours*100) or 0})
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(onCommand) end
if Events and Events.EveryTenMinutes then Events.EveryTenMinutes.Add(S.tick) end
return S
