if type(isClient)=='function' and isClient() then return {} end
local API=require 'foodWorks/API'
local M=require 'foodWorks/SweetPreserves'
local D=require 'foodWorks/AppleDrying'
if API.SweetPreservesServer then return API.SweetPreservesServer end
local S={}
API.SweetPreservesServer=S
local read=M.read
local MODULE='B47ANCEDProvisions.sweetPreserves'
local grants,nextGrant,lastRequest={},0,setmetatable({},{__mode='k'})
local function clock()
    local t=type(getTimestampMs)=='function' and getTimestampMs()
    if D.finite(t) and t>=0 then return t end
end
local function sweep(now)
    local count=0
    for id,g in pairs(grants) do
        if now<g.created or now-g.created>600000 or read(g.actor,'isDead')~=false then grants[id]=nil
        else count=count+1 end
    end
    return count
end
local function active(action)
    local now=clock()
    local g=D.integer(action.grantId,1,2147483647) and grants[action.grantId]
    if not now or not g or now<g.created or now-g.created>600000 or g.actor~=action.character
        or g.fruit~=action.fruit or g.object~=action.object or g.mode~=action.mode then return nil end
    return g
end
function S.claim(action)
    local g=active(action)
    if not g or g.action then return nil end
    g.action=action
    return g.plan
end
function S.current(action)
    local g=active(action)
    return g~=nil and g.action==action
end
function S.finish(action)
    if S.current(action) then grants[action.grantId]=nil;return true end
    return false
end
function S.cancel(actor,id)
    local g=D.integer(id,1,2147483647) and grants[id]
    if g and g.actor==actor then grants[id]=nil end
end
function S.request(actor,args)
    if type(args)~='table' or not D.integer(args.id,-2147483648,2147483647)
        or (args.mode~='jam' and args.mode~='jelly' and args.mode~='open') then return nil end
    local fields=0
    for key in pairs(args) do
        fields=fields+1
        if fields>8 or not ({id=true,mode=true,x=true,y=true,z=true,index=true,ui=true,request=true})[key] then return nil end
    end
    local now=clock()
    if not now then return nil end
    local last=lastRequest[actor]
    if last and now>=last and now-last<250 then return nil end
    lastRequest[actor]=now
    local count=sweep(now)
    local fruit=read(read(actor,'getInventory'),'getItemById',args.id)
    local object
    if args.mode~='open' then
        if not D.integer(args.x,-1000000,1000000) or not D.integer(args.y,-1000000,1000000)
            or not D.integer(args.z,-32,32) or not D.integer(args.index,0,1023) then return nil end
        local square=read(getCell(),'getGridSquare',args.x,args.y,args.z)
        object=read(read(square,'getObjects'),'get',args.index)
        if not M.heat(actor,object) then return nil end
    end
    local plan=M.select(actor,args.mode,fruit)
    if not plan then return nil end
    -- Only the authenticated actor can revoke/replace their prior intent.
    for id,g in pairs(grants) do if g.actor==actor then grants[id]=nil;count=count-1 end end
    if count>=128 or nextGrant>=2147483647 then return nil end
    nextGrant=nextGrant+1
    grants[nextGrant]={actor=actor,fruit=fruit,object=object,mode=args.mode,plan=plan,created=now}
    return nextGrant
end
local function command(module,command,actor,args)
    if module~=MODULE or type(args)~='table' then return end
    if command=='cancel' then S.cancel(actor,args.grantId);return end
    if command~='request' or not D.integer(args.ui,0,3) or not D.integer(args.request,1,2147483647) then return end
    local ok,id=pcall(S.request,actor,args)
    if not ok then print('[foodWorks] preserves: authorization failed: '..tostring(id)) end
    sendServerCommand(actor,MODULE,'grant',{ui=args.ui,request=args.request,grantId=ok and id or 0})
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(command) end
return S
