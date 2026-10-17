-- Presentation only. No server commands, item setters, jobs or recipe registration.
if type(isServer)=="function" and isServer() then return {} end
local API=require "foodWorks/API"
if API.FruitDryingPreview then return API.FruitDryingPreview end
local Preview={}
API.FruitDryingPreview=Preview
local windows={}
local Window
local reported=false
-- Explicit user-triggered scans only; these are technical UI work limits.
local MAX_HITS,MAX_ITEMS=32,256
local RACKS={['Base.Herb_Drying_Rack']=true,['Base.Simple_Herb_Drying_Rack']=true}

local function read(object,method,...)
    if object==nil then return nil end
    local ok,value=pcall(function(...)
        local fn=object[method]
        if type(fn)~="function" then return nil end
        return fn(object,...)
    end,...)
    if ok then return value end
end
local function finite(value)
    return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
local function tr(key,...)
    return getText("UI_foodWorks_DryingPreview_"..key,...)
end
local function safe(value)
    if type(value)~="string" and type(value)~="number" then return tr("Unavailable") end
    return tostring(value):sub(1,160):gsub("<","‹"):gsub(">","›"):gsub("[%c]"," ")
end
local function add(rows,label,state,detail)
    rows[#rows+1]={label=label,state=state,detail=detail}
end
local function clearFlag(rows,item,method,label)
    local value=read(item,method)
    add(rows,label,value==false and "PASS" or value==true and "BLOCKED" or "UNKNOWN")
end
local function enabled()
    local vars=rawget(_G,"SandboxVars")
    local settings=type(vars)=="table" and vars.foodWorks
    return type(settings)~="table" or settings.EnableFruitDryingPreview~=false
end
local function playerFor(number)
    if type(getSpecificPlayer)=="function" then return getSpecificPlayer(number) end
end
local function component(station,name)
    local types=rawget(_G,"ComponentType")
    if types and types[name] then return read(station,"getComponent",types[name]) end
end

function Preview.inspectItem(player,item)
    local rows={}
    if not item then add(rows,"AppleType","BLOCKED",tr("NoApple"));return rows end
    local kind=read(item,"getFullType")
    add(rows,"AppleType",kind=="Base.Apple" and "PASS" or kind and "BLOCKED" or "UNKNOWN",safe(kind))
    local inventory=read(player,"getInventory")
    local owner=read(item,"getContainer")
    add(rows,"Ownership",inventory and owner and (owner==inventory and "PASS" or "BLOCKED") or "UNKNOWN")
    local age,fresh,rotten=read(item,"getAge"),read(item,"getOffAge"),read(item,"getOffAgeMax")
    local bad=read(item,"isRotten")
    local state="UNKNOWN"
    if bad==true then state="BLOCKED"
    elseif finite(age) and age>=0 and finite(fresh) and fresh>0 and finite(rotten) and rotten>=fresh then
        if age>=fresh then state="BLOCKED" elseif bad==false then state="PASS" end
    end
    add(rows,"Freshness",state)
    for _,field in ipairs({{"isFrozen","Frozen"},{"isFreezing","Freezing"},{"isThawing","Thawing"},
        {"isCooked","Cooked"},{"isBurnt","Burnt"},{"isTainted","Tainted"},{"isPoison","Poison"}}) do
        clearFlag(rows,item,field[1],field[2])
    end
    local poison=read(item,"getPoisonPower")
    add(rows,"PoisonPower",finite(poison) and poison>=0 and (poison==0 and "PASS" or "BLOCKED") or "UNKNOWN")
    -- Compare against the registered script definition, never a hardcoded apple weight.
    local definition=read(item,"getScriptItem")
    local actual,expected=read(item,"getActualWeight"),read(definition,"getActualWeight")
    state="UNKNOWN"
    if finite(actual) and actual>0 and finite(expected) and expected>0 then
        -- Floating-point comparison tolerance is an internal diagnostic constant.
        state=math.abs(actual-expected)<=math.max(1,math.abs(expected))*0.0001 and "PASS" or "BLOCKED"
    end
    add(rows,"Weight",state)
    local nutrients=true
    for _,method in ipairs({"getCalories","getCarbohydrates","getLipids","getProteins"}) do
        local value=read(item,method)
        if not finite(value) or value<0 then nutrients=false end
    end
    add(rows,"Nutrition",nutrients and "PASS" or "UNKNOWN")
    -- hasModData avoids a potentially allocating getModData read. No data is created.
    local custom=read(item,"hasModData")
    add(rows,"CustomData",custom==false and "PASS" or custom==true and "BLOCKED" or "UNKNOWN")
    add(rows,"WholeIntegrity","UNKNOWN",tr("WholeUnproven"))
    return rows
end

function Preview.inspectStation(station)
    local rows={}
    if not station then add(rows,"StationIdentity","UNKNOWN",tr("NoStation"));return rows end
    local script=read(station,"getEntityScript")
    local kind=read(script,"getScriptObjectFullType")
    add(rows,"StationIdentity",RACKS[kind] and "PASS" or kind and "BLOCKED" or "UNKNOWN",safe(kind))
    local drying=component(station,"DryingCraftLogic")
    local resources=component(station,"Resources")
    add(rows,"StationComponents",drying and resources and "PASS" or "UNKNOWN")
    add(rows,"StationLoaded",read(station,"getSquare") and "PASS" or "UNKNOWN")
    add(rows,"Access","UNKNOWN",tr("AccessUnproven"))
    return rows
end

function Preview.report(player,item,station)
    local rows=Preview.inspectItem(player,item)
    for _,row in ipairs(Preview.inspectStation(station)) do rows[#rows+1]=row end
    local state="UNPROVEN"
    for _,row in ipairs(rows) do if row.state=="BLOCKED" then state="BLOCKED" end end
    return {state=state,name=safe(read(item,"getDisplayName")),rows=rows}
end

function Preview.format(report)
    local lines={tr("Title"),tr(report.state),tr("ReadOnly"),tr("AppleName",safe(report.name))}
    for _,row in ipairs(report.rows) do
        local line=tr(row.label)..": "..tr(row.state)
        if row.detail then line=line.." — "..safe(row.detail) end
        lines[#lines+1]=line
    end
    lines[#lines+1]=tr("NoProcessing")
    return table.concat(lines," <LINE> ")
end

local function firstApple(player)
    local items=read(read(player,"getInventory"),"getItems")
    local count=read(items,"size")
    if not finite(count) or count<0 then return nil,true end
    for index=0,math.min(count,MAX_ITEMS)-1 do
        local item=read(items,"get",index)
        if read(item,"getFullType")=="Base.Apple" then return item,false end
    end
    return nil,count>MAX_ITEMS
end

local function windowClass()
    if Window then return Window end
    require "ISUI/ISModalRichText"
    Window=ISModalRichText:derive("foodWorksDryingPreviewWindow")
    -- Vanilla modal destroy resets game speed. This inspection window never does.
    function Window:destroy()
        self:setWantKeyEvents(false)
        self:setVisible(false)
        self:removeFromUIManager()
        if windows[self.player]==self then windows[self.player]=nil end
        local focus=JoypadState and JoypadState.players and JoypadState.players[self.player+1]
        if focus and focus.focus==self and type(setJoypadFocus)=="function" then
            setJoypadFocus(self.player,self.prevFocus)
        end
    end
    function Window:update()
        ISPanelJoypad.update(self)
        local width=math.min(620,getPlayerScreenWidth(self.player)-40)
        local height=math.min(560,getPlayerScreenHeight(self.player)-40)
        if width>160 and height>100 and (width~=self.width or height~=self.height) then
            self:setWidth(width);self:setHeight(height)
            self:setX(getPlayerScreenLeft(self.player)+(getPlayerScreenWidth(self.player)-width)/2)
            self:setY(getPlayerScreenTop(self.player)+(getPlayerScreenHeight(self.player)-height)/2)
            self.chatText:setWidth(width-4)
            self.chatText:paginate()
        end
        local buttonHeight=math.max(25,getTextManager():getFontHeight(UIFont.Small)+6)
        self.chatText:setHeight(self.height-buttonHeight-20)
        self:updateButtons()
        if self.ok then self.ok:setX((self.width-self.ok.width)/2) end
        self.chatText:updateScrollbars()
    end
    function Window:onJoypadDown(button)
        if button==Joypad.BButton then self:destroy() else ISModalRichText.onJoypadDown(self,button) end
    end
    function Window:doRightJoystickScrolling(joypadData,dx,dy)
        self.chatText:doRightJoystickScrolling(joypadData,dx,dy)
    end
    function Window:onKeyPress(key)
        if Keyboard and key==Keyboard.KEY_ESCAPE then self:destroy();return true end
    end
    function Window:isKeyConsumed(key)
        return Keyboard and key==Keyboard.KEY_ESCAPE or false
    end
    return Window
end

function Preview.open(playerNum,item,station,fromStation)
    if not enabled() then return false end
    local player=playerFor(playerNum)
    if not player then return false end
    local truncated
    if fromStation then item,truncated=firstApple(player) end
    local report=Preview.report(player,item,station)
    if fromStation then add(report.rows,"Sample","UNKNOWN",tr(truncated and "ScanLimited" or "FirstApple")) end
    local width,height=math.min(620,getPlayerScreenWidth(playerNum)-40),math.min(560,getPlayerScreenHeight(playerNum)-40)
    if width<160 or height<100 then return false end
    local Class=windowClass()
    if windows[playerNum] then windows[playerNum]:destroy() end
    local window=Class:new(getPlayerScreenLeft(playerNum)+(getPlayerScreenWidth(playerNum)-width)/2,
        getPlayerScreenTop(playerNum)+(getPlayerScreenHeight(playerNum)-height)/2,width,height,
        Preview.format(report),false,nil,nil,playerNum)
    window:initialise();window:setWantKeyEvents(true);window:addToUIManager();windows[playerNum]=window
    local focus=JoypadState and JoypadState.players and JoypadState.players[playerNum+1]
    local bind=read(player,"getJoypadBind")
    if focus and finite(bind) and bind>=0 and type(setJoypadFocus)=="function" then
        window.prevFocus=focus.focus;setJoypadFocus(playerNum,window)
    end
    return true
end

local function contained(fn,...)
    local ok=pcall(fn,...)
    if not ok and not reported then
        reported=true;print("[foodWorks] Drying preview unavailable; presentation callback failed.")
    end
end
local function open(playerNum,item,station,fromStation)
    contained(Preview.open,playerNum,item,station,fromStation)
end
function Preview.fillInventory(playerNum,context,items)
    if not enabled() then return end
    contained(function()
        local selected=ISInventoryPane.getActualItems(items)
        if type(selected)=="table" and #selected==1 and read(selected[1],"getFullType")=="Base.Apple" then
            context:addOption(tr("InventoryAction"),playerNum,open,selected[1])
        end
    end)
end
function Preview.fillWorld(playerNum,context,objects,test)
    if not enabled() or type(objects)~="table" then return end
    contained(function()
        for index=1,math.min(#objects,MAX_HITS) do
            local station=objects[index]
            local kind=read(read(station,"getEntityScript"),"getScriptObjectFullType")
            if RACKS[kind] or component(station,"DryingCraftLogic") then
                if test then ISWorldObjectContextMenu.setTest();return end
                context:addOption(tr("WorldAction"),playerNum,open,nil,station,true)
                return
            end
        end
    end)
end
if Events then
    if Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(Preview.fillInventory) end
    if Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(Preview.fillWorld) end
end
return Preview
