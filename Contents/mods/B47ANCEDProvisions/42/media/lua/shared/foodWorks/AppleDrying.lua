-- Pure inspection/state model. Only the server module may apply gameplay changes.
local API=require "foodWorks/API"
if API.AppleDrying then return API.AppleDrying end
local M={KEY="foodWorks.appleDrying.v1",INDEX="foodWorks.appleDrying.index.v1",STATION="foodWorks.appleDrying.rack.v1"}
API.AppleDrying=M
local F={age="getAge",fresh="getOffAge",rotten="getOffAgeMax",weight="getActualWeight",
    hunger="getHungChange",baseHunger="getBaseHunger",thirst="getThirstChangeUnmodified",calories="getCalories",
    carbs="getCarbohydrates",lipids="getLipids",proteins="getProteins",unhappy="getUnhappyChangeUnmodified",boredom="getBoredomChangeUnmodified",
    pain="getPainReduction",flu="getFluReduction",sickness="getFoodSicknessChange",fatigue="getFatigueChange",endurance="getEnduranceChangeUnmodified"}
local BASE={"fresh","rotten","weight","hunger","baseHunger","thirst","calories","carbs","lipids","proteins","unhappy","boredom","pain","flu","sickness","fatigue","endurance"}
M.fields=BASE
function M.finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function M.integer(n,lo,hi) return M.finite(n) and n==math.floor(n) and n>=lo and n<=hi end
function M.read(object,name,...)
    if object==nil then return nil end
    local ok,value=pcall(function(...)
        if type(object[name])=="function" then return object[name](object,...) end
    end,...)
    if ok then return value end
end
function M.close(a,b) return M.finite(a) and M.finite(b) and math.abs(a-b)<=math.max(1,math.abs(b))*0.00001 end
function M.settings(vars)
    vars=vars or {}
    if type(vars)~="table" then return nil end
    local hours=vars.FruitDryingHours
    local shelf=vars.FruitDryingShelfLifeMultiplier
    if hours==nil then hours=48 end
    if shelf==nil then shelf=6 end
    if not M.integer(hours,6,168) or not M.integer(shelf,1,12)
        or (vars.EnableFruitDrying~=nil and type(vars.EnableFruitDrying)~="boolean") then return nil end
    return {enabled=vars.EnableFruitDrying~=false,hours=hours,multiplier=shelf}
end
function M.snapshot(item)
    if M.read(item,"getFullType")~="Base.Apple" then return nil end
    for _,flag in ipairs({"isFrozen","isFreezing","isThawing","isCooked","isBurnt","isTainted","isPoison","haveExtraItems","hasSpices"}) do
        if M.read(item,flag)~=false then return nil end
    end
    if M.read(item,"getPoisonPower")~=0 or M.read(item,"getFreezingTime")~=0 then return nil end
    local s={}
    for key,getter in pairs(F) do
        s[key]=M.read(item,getter)
        if not M.finite(s[key]) or math.abs(s[key])>1000000 then return nil end
    end
    if s.age<0 or s.fresh<=0 or s.rotten<s.fresh or s.weight<=0 or s.hunger>=0
        or s.calories<0 or s.carbs<0 or s.lipids<0 or s.proteins<0 then return nil end
    return s
end
function M.matches(a,b)
    if not a or not b then return false end
    for _,key in ipairs(BASE) do if not M.close(a[key],b[key]) then return false end end
    return true
end
function M.job(item)
    if M.read(item,"hasModData")~=true then return nil end
    local md=M.read(item,"getModData")
    local job=type(md)=="table" and md[M.KEY] or nil
    if type(job)~="table" then return nil end
    local copy,count={},0
    for key,value in pairs(job) do
        count=count+1
        if count>64 or type(key)~="string" or (type(value)~="number" and type(value)~="string") then return nil end
        copy[key]=value
    end
    return copy
end
function M.valid(job)
    if type(job)~="table" or job.v~=1 or not M.integer(job.itemId,-2147483648,2147483647) or type(job.anchor)~="string" or #job.anchor>160
        or not M.integer(job.hours,6,168) or not M.integer(job.multiplier,1,12)
        or not M.finite(job.started) or job.started<0 or not M.finite(job.last) or job.last<job.started
        or not M.finite(job.ageFloor) or job.ageFloor<0 or job.ageFloor>1000000
        or not M.finite(job.credit) or job.credit<0 or job.credit>job.hours
        or not ({drying=true,ready=true,converting=true,done=true,failed=true})[job.phase] then return false end
    local allowed={v=true,itemId=true,anchor=true,hours=true,multiplier=true,started=true,last=true,ageFloor=true,credit=true,phase=true,targetAge=true,targetAt=true}
    for _,key in ipairs(BASE) do
        local field="b_"..key
        allowed[field]=true
        if not M.finite(job[field]) or math.abs(job[field])>1000000 then return false end
    end
    for k,v in pairs(job) do
        if not allowed[k] or (type(v)~="number" and type(v)~="string") then return false end
    end
    if job.b_fresh<=0 or job.b_rotten<job.b_fresh or job.b_weight<=0 or job.b_hunger>=0
        or job.b_calories<0 or job.b_carbs<0 or job.b_lipids<0 or job.b_proteins<0 then return false end
    if job.phase=="ready" or job.phase=="converting" or job.phase=="done" then
        if job.credit~=job.hours then return false end
    end
    if job.phase=="converting" or job.phase=="done" then
        if not M.finite(job.targetAge) or job.targetAge<0 or job.targetAge>=job.b_rotten*job.multiplier
            or (job.targetAge<job.ageFloor*job.multiplier and not M.close(job.targetAge,job.ageFloor*job.multiplier))
            or not M.finite(job.targetAt) or job.targetAt+0.00001<job.started+job.hours then return false end
    elseif job.targetAge~=nil or job.targetAt~=nil then return false end
    return true
end
function M.base(job)
    local s={}
    for _,key in ipairs(BASE) do s[key]=job["b_"..key] end
    return s
end
function M.begin(snapshot,settings,anchor,now,itemId)
    if not snapshot or snapshot.age>=snapshot.fresh or not settings or not settings.enabled
        or not M.finite(now) or now<0 then return nil end
    local job={v=1,itemId=itemId,phase="drying",anchor=anchor,hours=settings.hours,multiplier=settings.multiplier,
        started=now,last=now,ageFloor=snapshot.age,credit=0}
    for _,key in ipairs(BASE) do job["b_"..key]=snapshot[key] end
    return M.valid(job) and job or nil
end
function M.advance(job,snapshot,now)
    if not M.valid(job) then return false end
    if job.phase~="drying" then return true end
    if not M.matches(snapshot,M.base(job)) or snapshot.age>=snapshot.rotten
        or (snapshot.age<job.ageFloor and not M.close(snapshot.age,job.ageFloor)) or not M.finite(now) or now<job.last then
        job.phase="failed";return false
    end
    local delta=now-job.last
    job.ageFloor=math.max(job.ageFloor,snapshot.age)
    -- Ten-minute observation cadence. Longer gaps pause, including unload/restart gaps.
    -- This is a technical continuity bound, not an alternative balance duration.
    if delta<=0.2 then job.credit=math.min(job.hours,job.credit+delta) end
    job.last=now
    if job.credit+0.000001>=job.hours and now+0.000001>=job.started+job.hours then
        job.credit=job.hours;job.phase="ready"
    end
    return true
end
function M.plan(job,snapshot,now)
    if not M.valid(job) or job.phase~="ready" or not M.matches(snapshot,M.base(job))
        or snapshot.age>=snapshot.rotten or (snapshot.age<job.ageFloor and not M.close(snapshot.age,job.ageFloor))
        or not M.finite(now) or now+0.00001<job.started+job.hours then return false end
    job.targetAge=math.max(snapshot.age,job.ageFloor)*job.multiplier
    job.targetAt=now
    job.phase="converting"
    return M.valid(job)
end
return M
