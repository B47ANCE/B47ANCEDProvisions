require "TimedActions/ISBaseTimedAction"
local M=require "foodWorks/SweetPreserves"
local D=require "foodWorks/AppleDrying"
local read=M.read
foodWorksSweetPreservesAction=ISBaseTimedAction:derive('foodWorksSweetPreservesAction')
local A=foodWorksSweetPreservesAction
local SET={age='setAge',fresh='setOffAge',rotten='setOffAgeMax',weight='setActualWeight',hunger='setHungChange',
    baseHunger='setBaseHunger',thirst='setThirstChange',calories='setCalories',carbs='setCarbohydrates',lipids='setLipids',
    proteins='setProteins',unhappy='setUnhappyChange',boredom='setBoredomChange',pain='setPainReduction',flu='setFluReduction',
    sickness='setFoodSicknessChange',fatigue='setFatigueChange',endurance='setEnduranceChange'}
local function client() return type(isClient)=='function' and isClient() end
local function initialize(kind,values,name)
    local item=instanceItem(kind)
    if not item or read(item,'getFullType')~=kind or read(item,'getContainer')~=nil then error('output factory rejected') end
    -- Detached items only: a missing setter/read-back aborts before any debit.
    for key,setter in pairs(SET) do item[setter](item,values[key]) end
    item:setWeight(values.weight);item:setCustomWeight(true)
    item:setCooked(true)
    if name then item:setName(name);item:setCustomName(true) end
    local actual=M.food(item,true)
    if not actual then error('output state invalid') end
    for key in pairs(SET) do if not D.close(actual[key],values[key]) then error('output read-back failed') end end
    return item
end
local function outputs(action,plan)
    if plan.mode=='open' then
        local old=plan.foods[1]
        local s={}
        for k,v in pairs(old) do s[k]=v end
        s.fresh=3;s.rotten=6;s.age=old.age/old.fresh*3;s.weight=old.weight-0.1
        if s.weight<=0.2 then error('jar mass invalid') end
        local kind=plan.kind=='jam' and 'foodWorks.JamOpened' or 'foodWorks.JellyOpened'
        local lid=instanceItem('Base.JarLid')
        if not lid or read(lid,'getFullType')~='Base.JarLid' or read(lid,'getContainer')~=nil then error('lid factory rejected') end
        return {initialize(kind,s,read(action.fruit,'getName')),lid}
    end
    local s,pulp=M.account(plan)
    local fruit=read(action.fruit,'getFullType'):sub(6)
    local name=getText('UI_foodWorks_Preserves_'..(plan.mode=='jam' and 'JamName' or 'JellyName'),
        getText('UI_foodWorks_FruitDrying_Input_'..fruit))
    local kind=plan.mode=='jam' and 'foodWorks.JamSealed' or 'foodWorks.JellySealed'
    local result={initialize(kind,s,name)}
    if plan.mode=='jelly' then result[#result+1]=initialize('foodWorks.StrainedFruitPulp',pulp,nil) end
    return result
end
local function sameInputs(a,b)
    if not a or not b or a.mode~=b.mode or a.kind~=b.kind or a.inv~=b.inv or #a.consume~=#b.consume then return false end
    for i,item in ipairs(a.consume) do if item~=b.consume[i] then return false end end
    for i,item in ipairs(a.keep or {}) do if item~=(b.keep or {})[i] then return false end end
    return true
end
function A:serverStart()
    self._plan=nil;self._finished=false
    local server=foodWorks.SweetPreservesServer
    if not client() and server and (self.mode=='open' or M.heat(self.character,self.object)) then
        local approved=server.claim(self)
        local plan=M.select(self.character,self.mode,self.fruit)
        if sameInputs(approved,plan) then self._plan=approved end
    end
end
function A:isValid()
    if self._finished or (self.mode~='open' and not M.heat(self.character,self.object)) then return false end
    if not client() and self._plan and not foodWorks.SweetPreservesServer.current(self) then return false end
    return M.select(self.character,self.mode,self.fruit)~=nil
end
function A:start()
    if not client() then self:serverStart() end
    self:setActionAnim('Craft')
    self:setOverrideHandModels(nil,nil)
end
function A:update()
    if self.mode~='open' and self.object then self.character:faceThisObject(self.object) end
end
function A:perform() ISBaseTimedAction.perform(self) end
function A:stop()
    self._plan=nil
    if client() then
        sendClientCommand(self.character,'B47ANCEDProvisions.sweetPreserves','cancel',{grantId=self.grantId})
    elseif foodWorks.SweetPreservesServer then foodWorks.SweetPreservesServer.cancel(self.character,self.grantId) end
    ISBaseTimedAction.stop(self)
end
function A:serverStop()
    self._plan=nil
    if foodWorks.SweetPreservesServer then foodWorks.SweetPreservesServer.finish(self) end
end
function A:getDuration()
    local cfg=M.settings()
    local base=self.mode=='open' and 40 or (self.mode=='jelly' and 900 or 600)
    return base*(cfg and cfg.time or 1)
end
function A:complete()
    if client() or self._finished then return false end
    local server=foodWorks.SweetPreservesServer
    if not server or not server.current(self) then return false end
    -- This state is constructed on the server; it is not a constructor/network argument.
    local plan=M.select(self.character,self.mode,self.fruit)
    if not sameInputs(self._plan,plan) or not self:isValid() then self._finished=true;server.finish(self);return false end
    plan.cfg=self._plan.cfg -- Accepted server settings; changing them never refreshes a jar.
    self._finished=true
    if not server.finish(self) then return false end
    local ok,result=pcall(outputs,self,plan)
    if not ok then print('[foodWorks] preserves: output preparation failed; inputs retained: '..tostring(result));return false end
    local removed={}
    local debit,debitError=pcall(function()
        for _,item in ipairs(plan.consume) do
            if not M.owned(plan.inv,item) then error('input moved') end
            plan.inv:Remove(item)
            if read(plan.inv,'contains',item)~=false or read(item,'getContainer')~=nil then error('input removal rejected') end
            removed[#removed+1]=item
        end
    end)
    if not debit then
        print('[foodWorks] preserves: debit failed; restoring originals: '..tostring(debitError))
        -- Restore the exact original objects only. Never create replacement ingredients.
        for _,item in ipairs(plan.consume) do
            if read(plan.inv,'contains',item)==false and read(item,'getContainer')==nil then
                local restored=pcall(function() plan.inv:AddItem(item) end)
                if not restored or not M.owned(plan.inv,item) then
                    print('[foodWorks] preserves: original input recovery failed; no output published')
                end
            elseif not M.owned(plan.inv,item) then
                print('[foodWorks] preserves: inconsistent original input; no output published')
            end
        end
        return false
    end
    -- Commit point: inputs have all left the authoritative inventory. No rollback,
    -- regeneration or retry after publication can duplicate a partially delivered batch.
    if type(isServer)=='function' and isServer() then
        for _,item in ipairs(removed) do
            local synced,err=pcall(sendRemoveItemFromContainer,plan.inv,item)
            if not synced then print('[foodWorks] preserves: input synchronization failed: '..tostring(err)) end
        end
    end
    for _,item in ipairs(result) do
        local published,err=pcall(Actions.addOrDropItem,self.character,item)
        if not published then print('[foodWorks] preserves: output delivery failed; batch will not retry: '..tostring(err)) end
    end
    self._plan=nil
    return true
end
-- Parameter names and stored fields must agree: NetTimedAction serializes new() arguments.
function A:new(character,fruit,object,mode,grantId)
    local o=ISBaseTimedAction.new(self,character)
    o.fruit=fruit;o.object=object;o.mode=mode
    o.grantId=grantId
    o.maxTime=o:getDuration()
    return o
end
return A
