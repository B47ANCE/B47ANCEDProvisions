if type(isServer)=="function" and isServer() then return {} end
local API=require "foodWorks/API"
if API.AppleDryingClient then return API.AppleDryingClient end
local M=require "foodWorks/AppleDrying"
local C={}
API.AppleDryingClient=C
local read=M.read
local RACKS={['Base.Herb_Drying_Rack']=true,['Base.Simple_Herb_Drying_Rack']=true}
local MODULE="B47ANCEDProvisions.appleDrying"
local CODES={InvalidRequest=true,InvalidState=true,AccessDenied=true,InvalidSettings=true,Disabled=true,RackBusy=true,
    InvalidApple=true,Capacity=true,OperationFailed=true,Started=true,Resumed=true,NotReady=true,Collected=true,Cancelled=true,
    drying=true,ready=true,converting=true,done=true,failed=true}
local function text(key,...) return getText("UI_foodWorks_AppleDrying_"..key,...) end
local function result(playerNum,code,progress)
    local player=getSpecificPlayer(playerNum)
    if player then
        if not CODES[code] then code="OperationFailed" end
        player:Say(text(code,M.integer(progress,0,100) and progress or 0))
    end
end
function C.send(playerNum,command,object,item)
    local player=getSpecificPlayer(playerNum)
    if not player or not item then return end
    local args={id=read(item,"getID"),ui=playerNum}
    if object then
        local square=read(object,"getSquare")
        args.x=read(square,"getX");args.y=read(square,"getY");args.z=read(square,"getZ")
        args.index=read(object,"getObjectIndex")
    end
    if type(isClient)=="function" and isClient() then
        sendClientCommand(player,MODULE,command,args)
    elseif API.AppleDryingServer then
        local code,job=API.AppleDryingServer.handle(player,command,args)
        result(playerNum,code,M.valid(job) and math.floor(job.credit/job.hours*100) or 0)
    else result(playerNum,"OperationFailed",0) end
end
local function firstApple(player)
    local items=read(read(player,"getInventory"),"getItems")
    local n=read(items,"size")
    if not M.integer(n,0,1000000) then return nil end
    for i=0,math.min(n,256)-1 do
        local item=read(items,"get",i)
        local age,fresh=read(item,"getAge"),read(item,"getOffAge")
        if read(item,"getFullType")=="Base.Apple" and read(item,"hasModData")==false
            and M.finite(age) and M.finite(fresh) and age>=0 and age<fresh then return item end
    end
end
local function carriedBatch(player)
    local items=read(read(player,"getInventory"),"getItems")
    local n=read(items,"size")
    if not M.integer(n,0,1000000) then return nil end
    for i=0,math.min(n,256)-1 do
        local item=read(items,"get",i)
        local job=M.job(item)
        if M.valid(job) and job.itemId==read(item,"getID") and job.phase~="done" and job.phase~="failed" then return item end
    end
end
local function options(playerNum,object)
    if not ComponentType or not RACKS[read(read(object,"getEntityScript"),"getScriptObjectFullType")] then return {} end
    local logic=read(object,"getComponent",ComponentType.DryingCraftLogic)
    local inputs=read(logic,"getInputResources")
    if read(inputs,"size")~=1 then return {} end
    local resource=read(inputs,"get",0)
    local count=read(resource,"getItemAmount")
    local actions={}
    if count==0 then
        local batch=carriedBatch(getSpecificPlayer(playerNum))
        if batch and read(logic,"isRunning")==false then actions[#actions+1]={"Resume","resume",batch} end
        local vars=type(SandboxVars)=="table" and SandboxVars.foodWorks or nil
        local cfg=M.settings(vars)
        if cfg and cfg.enabled and read(logic,"isRunning")==false then
            local apple=firstApple(getSpecificPlayer(playerNum))
            if apple then actions[#actions+1]={"Start","start",apple} end
        end
    elseif M.integer(count,1,20) then
        for i=0,count-1 do
            local item=read(resource,"peekItem",i)
            local job=M.job(item)
            if M.valid(job) and job.itemId==read(item,"getID") then
                actions[#actions+1]={"Status","status",item}
                if job.phase=="done" or job.phase=="ready" then
                    actions[#actions+1]={"Collect","collect",item}
                elseif job.phase~="converting" then actions[#actions+1]={"Cancel","cancel",item} end
                break
            end
        end
    end
    return actions
end
function C.fillWorld(playerNum,context,objects,test)
    if type(objects)~="table" then return end
    for i=1,math.min(#objects,32) do
        local object=objects[i]
        local actions=options(playerNum,object)
        if #actions>0 then
            if test then ISWorldObjectContextMenu.setTest();return end
            for _,action in ipairs(actions) do
                context:addOption(text(action[1]),playerNum,C.send,action[2],object,action[3])
            end
            return
        end
    end
end
function C.fillInventory(playerNum,context,items)
    local selected=ISInventoryPane.getActualItems(items)
    if type(selected)~="table" or #selected~=1 then return end
    local item=selected[1]
    local player=getSpecificPlayer(playerNum)
    local job=M.job(item)
    if M.valid(job) and job.itemId==read(item,"getID") and job.phase~="done" and job.phase~="converting"
        and read(item,"getContainer")==read(player,"getInventory") then
        context:addOption(text("CancelCarried"),playerNum,C.send,"cancelInventory",nil,item)
    end
end
local function onResult(module,command,args)
    if module~=MODULE or command~="result" or type(args)~="table" or not M.integer(args.ui,0,3) then return end
    result(args.ui,args.code,args.progress)
end
if Events then
    if Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(C.fillWorld) end
    if Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(C.fillInventory) end
    if Events.OnServerCommand then Events.OnServerCommand.Add(onResult) end
end
return C
