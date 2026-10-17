local inventoryCalls,worldCalls=0,0
local callbacks={}
Events={
    OnFillInventoryObjectContextMenu={Add=function(fn)inventoryCalls=inventoryCalls+1;callbacks.inventory=fn end},
    OnFillWorldObjectContextMenu={Add=function(fn)worldCalls=worldCalls+1;callbacks.world=fn end}}
local translations=TRANSLATIONS
getText=function(key,...)
    assert(translations[key],"missing translation: "..key)
    local result=translations[key]
    for index=1,select('#',...) do
        local value=tostring(select(index,...))
        result=result:gsub("%%"..index,function()return value end)
    end
    return result
end
SandboxVars={foodWorks={EnableFruitDryingPreview=true}}
ComponentType={DryingCraftLogic={},Resources={}}
isServer=function()return false end
local added={}
local context={addOption=function(self,...)added[#added+1]={...}end}
ISInventoryPane={getActualItems=function(items)return items end}
local tests=0
ISWorldObjectContextMenu={setTest=function()tests=tests+1 end}
local items={}
local gets=0
local inventory={getItems=function()return{
    size=function()return #items end,
    get=function(_,i)gets=gets+1;return items[i+1] end}end}
local player={getInventory=function()return inventory end,getJoypadBind=function()return -1 end}
getSpecificPlayer=function(n)assert(n==0);return player end
local data={kind="Base.Apple",container=inventory,age=1,fresh=5,rotten=8,weight=.2,
    isRotten=false,isFrozen=false,isFreezing=false,isThawing=false,isCooked=false,
    isBurnt=false,isTainted=false,isPoison=false,poison=0,custom=false}
local missing={}
local forbiddenReads=0
local definition={getActualWeight=function()return .2 end}
local methods={
    getFullType=function()return data.kind end,getContainer=function()return data.container end,
    getAge=function()return data.age end,getOffAge=function()return data.fresh end,
    getOffAgeMax=function()return data.rotten end,getPoisonPower=function()return data.poison end,
    getActualWeight=function()return data.weight end,getScriptItem=function()return definition end,
    hasModData=function()return data.custom end,
    getDisplayName=function()return '<Apple>\n<IMAGE:bad>' end,
    getModData=function()forbiddenReads=forbiddenReads+1;error('allocating ModData must never be read')end}
for _,name in ipairs({'isRotten','isFrozen','isFreezing','isThawing','isCooked','isBurnt','isTainted','isPoison'}) do
    local key=name;methods[key]=function()return data[key]end
end
for _,name in ipairs({'getCalories','getCarbohydrates','getLipids','getProteins'}) do methods[name]=function()return 1 end end
local apple=setmetatable({}, {__index=function(_,key)
    if missing[key] then error('unsupported getter') end
    if key:match('^set') then forbiddenReads=forbiddenReads+1;error('food setter access')end
    return methods[key]
end,__newindex=function()error('input mutation')end})
items={apple}
local rackData={kind='Base.Herb_Drying_Rack',drying=true,resources=true,square={}}
local rack={getEntityScript=function()return{getScriptObjectFullType=function()return rackData.kind end}end,
    getComponent=function(_,component)
        if component==ComponentType.DryingCraftLogic and rackData.drying then return {} end
        if component==ComponentType.Resources and rackData.resources then return {} end
    end,getSquare=function()return rackData.square end}
local Preview=dofile(arg[1])
assert(dofile(arg[1])==Preview and inventoryCalls==1 and worldCalls==1,'duplicate event registration')
local function state(label,rows)
    for _,row in ipairs(rows)do if row.label==label then return row.state end end
    error('missing row: '..label)
end
local report=Preview.report(player,apple,rack)
assert(report.state=='UNPROVEN')
assert(state('Weight',report.rows)=='PASS' and state('StationIdentity',report.rows)=='PASS')
assert(state('WholeIntegrity',report.rows)=='UNKNOWN' and state('Access',report.rows)=='UNKNOWN')
assert(not report.eligible and not Preview.begin and not Preview.finish)
local text=Preview.format(report)
assert(not text:find('<Apple>',1,true) and not text:find('<IMAGE:',1,true))
assert(text:find('not yet proved',1,true) and text:find('Drying is not available',1,true))

for _,key in ipairs({'isFrozen','isFreezing','isThawing','isCooked','isBurnt','isTainted','isPoison'})do
    data[key]=true;assert(Preview.report(player,apple,rack).state=='BLOCKED',key);data[key]=false
end
data.age=5;assert(Preview.report(player,apple,rack).state=='BLOCKED');data.age=1
data.isRotten=true;assert(Preview.report(player,apple,rack).state=='BLOCKED');data.isRotten=false
data.poison=1;assert(Preview.report(player,apple,rack).state=='BLOCKED');data.poison=0
data.container={};assert(Preview.report(player,apple,rack).state=='BLOCKED','nested/other ownership');data.container=inventory
data.weight=.1;assert(state('Weight',Preview.inspectItem(player,apple))=='BLOCKED','partial weight');data.weight=.2
data.custom=true;assert(state('CustomData',Preview.inspectItem(player,apple))=='BLOCKED');data.custom=false
data.age=0/0;assert(state('Freshness',Preview.inspectItem(player,apple))=='UNKNOWN');data.age=1
missing.isFrozen=true;assert(state('Frozen',Preview.inspectItem(player,apple))=='UNKNOWN');missing.isFrozen=nil
data.isFrozen='false';assert(state('Frozen',Preview.inspectItem(player,apple))=='UNKNOWN');data.isFrozen=false
missing.getActualWeight=true;assert(state('Weight',Preview.inspectItem(player,apple))=='UNKNOWN');missing.getActualWeight=nil
assert(state('AppleType',Preview.inspectItem(player,nil))=='BLOCKED')
assert(state('StationIdentity',Preview.inspectStation(nil))=='UNKNOWN')
rackData.kind='Base.FakeRack';assert(state('StationIdentity',Preview.inspectStation(rack))=='BLOCKED');rackData.kind='Base.Herb_Drying_Rack'
rackData.resources=false;assert(state('StationComponents',Preview.inspectStation(rack))=='UNKNOWN');rackData.resources=true

callbacks.inventory(0,context,{apple});assert(#added==1)
callbacks.inventory(0,context,{apple,apple});assert(#added==1)
data.kind='Base.Banana';callbacks.inventory(0,context,{apple});assert(#added==1);data.kind='Base.Apple'
callbacks.world(0,context,{rack,rack},true);assert(tests==1 and #added==1,'controller test must not add/open')
callbacks.world(0,context,{rack,rack},false);assert(#added==2,'one station entry per menu')
SandboxVars.foodWorks.EnableFruitDryingPreview=false
callbacks.inventory(0,context,{apple});callbacks.world(0,context,{rack},false);assert(#added==2)
assert(not Preview.open(0,apple,rack));SandboxVars.foodWorks.EnableFruitDryingPreview=true

-- A headless UI fixture verifies the full callback and the speed-safe close path.
local latest
local function nop()end
local function uiObject()
    return {width=620,height=560,chatText={setWidth=nop,setHeight=nop,paginate=nop,updateScrollbars=nop,
        doRightJoystickScrolling=function(self)self.scrolled=true end},
        ok={width=100,setX=function(self,x)self.x=x end},initialise=nop,addToUIManager=nop,
        setVisible=nop,removeFromUIManager=nop,setX=nop,setY=nop,
        setWantKeyEvents=function(self,value)self.wantsKeys=value end,
        setWidth=function(self,w)self.width=w end,setHeight=function(self,h)self.height=h end,updateButtons=nop}
end
package.preload['ISUI/ISModalRichText']=function()
    ISModalRichText={derive=function()
        local class={}
        function class:new(x,y,w,h,text,yesno,target,onclick,playerNum)
            local object=uiObject();object.width=w;object.height=h;object.player=playerNum;object.text=text
            latest=setmetatable(object,{__index=class});return latest
        end
        return class
    end,onJoypadDown=nop}
    return ISModalRichText
end
ISPanelJoypad={update=nop}
local screenWidth=700
getPlayerScreenWidth=function()return screenWidth end;getPlayerScreenHeight=function()return 600 end
getPlayerScreenLeft=function()return 0 end;getPlayerScreenTop=function()return 0 end
getTextManager=function()return{getFontHeight=function()return 14 end}end;UIFont={Small=1}
UIManager=setmetatable({},{__index=function()error('must not access pause or speed controls')end})
Joypad={BButton=2};Keyboard={KEY_ESCAPE=1}
assert(Preview.open(0,apple,rack));assert(latest.text:find('not yet proved',1,true) and latest.wantsKeys)
screenWidth=340;latest:update();assert(latest.ok.x==100,'close button stays in resized viewport')
latest:doRightJoystickScrolling({},0,1);assert(latest.chatText.scrolled)
latest:destroy()
assert(latest.wantsKeys==false)
-- Menu action re-evaluates the input at activation, rather than trusting menu-time state.
data.age=8;added[1][3](0,added[1][4]);assert(latest.text:find('A precheck failed',1,true));data.age=1
latest:onJoypadDown(Joypad.BButton)
-- A bounded main-inventory scan never recursively searches bags or scans on ticks.
items={};for index=1,300 do items[index]={getFullType=function()return 'Base.Stone'end}end
gets=0;assert(Preview.open(0,nil,rack,true));assert(gets==256)
assert(latest.text:find('scan reached its limit',1,true));latest:onKeyPress(Keyboard.KEY_ESCAPE)
isServer=function()return true end
assert(next(dofile(arg[1]))==nil and inventoryCalls==1 and worldCalls==1,'server must install no preview')
assert(forbiddenReads==0,'no allocating ModData or mutator access is permitted')
print('foodWorks read-only drying preview: conservative checks, menus, localization, bounds and speed-safe UI passed')
