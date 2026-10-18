if type(isServer)=='function' and isServer() then return {} end
local API=require 'foodWorks/API'
local M=require 'foodWorks/SweetPreserves'
local D=require 'foodWorks/AppleDrying'
local A=require 'foodWorks/SweetPreservesAction'
if API.SweetPreservesClient then return API.SweetPreservesClient end
local C={}
API.SweetPreservesClient=C
local read=M.read
local pending,sequence={},0
local MODULE='B47ANCEDProvisions.sweetPreserves'
local function granted(playerNum,request,id)
    local p=pending[playerNum]
    if not p or p.request~=request then return end
    pending[playerNum]=nil
    local player=getSpecificPlayer(playerNum)
    if player and D.integer(id,1,2147483647) then
        ISTimedActionQueue.add(A:new(player,p.fruit,p.object,p.mode,id))
    elseif player then player:Say(getText('UI_foodWorks_Preserves_Unavailable')) end
end
function C.queue(playerNum,fruit,object,mode)
    local player=getSpecificPlayer(playerNum)
    if not player or sequence>=2147483647 then return end
    sequence=sequence+1
    pending[playerNum]={request=sequence,fruit=fruit,object=object,mode=mode}
    local args={id=read(fruit,'getID'),mode=mode,ui=playerNum,request=sequence}
    if object then
        local square=read(object,'getSquare')
        args.x=read(square,'getX');args.y=read(square,'getY');args.z=read(square,'getZ')
        args.index=read(object,'getObjectIndex')
    end
    if type(isClient)=='function' and isClient() then sendClientCommand(player,MODULE,'request',args)
    elseif API.SweetPreservesServer then granted(playerNum,sequence,API.SweetPreservesServer.request(player,args)) end
end
function C.fillWorld(playerNum,context,objects,test)
    if type(objects)~='table' then return end
    local player=getSpecificPlayer(playerNum)
    local list=read(read(player,'getInventory'),'getItems')
    local n=read(list,'size')
    if type(n)~='number' or n>256 then return end
    for i=1,math.min(#objects,32) do
        local object=objects[i]
        if M.heat(player,object) then
            local seen={}
            for j=0,n-1 do
                local fruit=read(list,'get',j)
                local kind=read(fruit,'getFullType')
                if M.supported(kind) and not seen[kind] then
                    for _,mode in ipairs({'jam','jelly'}) do
                        if M.select(player,mode,fruit) then
                            if test then ISWorldObjectContextMenu.setTest();return end
                            context:addOption(getText('UI_foodWorks_Preserves_'..(mode=='jam' and 'MakeJam' or 'MakeJelly'),
                                getText('UI_foodWorks_FruitDrying_Input_'..kind:sub(6))),playerNum,C.queue,fruit,object,mode)
                            seen[kind]=true
                        end
                    end
                end
            end
            return
        end
    end
end
function C.fillInventory(playerNum,context,items)
    local actual=ISInventoryPane.getActualItems(items)
    if type(actual)~='table' or #actual~=1 then return end
    local fruit=actual[1]
    if M.select(getSpecificPlayer(playerNum),'open',fruit) then
        context:addOption(getText('UI_foodWorks_Preserves_Open',read(fruit,'getName')),playerNum,C.queue,fruit,nil,'open')
    end
end
if Events then
    if Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(C.fillWorld) end
    if Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(C.fillInventory) end
    if Events.OnServerCommand then Events.OnServerCommand.Add(function(module,command,args)
        if module==MODULE and command=='grant' and type(args)=='table' and D.integer(args.ui,0,3)
            and D.integer(args.request,1,2147483647) then granted(args.ui,args.request,args.grantId) end
    end) end
end
return C
