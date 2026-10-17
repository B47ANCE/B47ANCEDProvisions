foodWorks={}
local Processes=dofile(arg[1])
Processes.register{id="fixture.airDry",stationCapability="foodWorks.dryingRack",durationHours=24,cadenceHours=6,
    inputs={{itemType="fixture.Fruit",quantity=2,role="food",protected=true}},
    eligible=function(context)return context.freshness=="FRESH"end,
    observe=function(context,hour)return{hour=hour,humidity=context.humidity or 0}end}
local reserved,released,committed=0,0,0
local provider={id="fixture.inventory",reserve=function(inputs,context)reserved=reserved+1;assert(inputs[1].itemType=="fixture.Fruit");return true,{token="r1"}end,
    release=function()released=released+1;return true,{released=true}end,
    commit=function(job)committed=committed+1;assert(job.status=="committing");return true,{outputId="dried:1"}end}
local store={};local context={stationId="rack:1",stationCapability="foodWorks.dryingRack",foodId="food:1",freshness="FRESH",worldAgeHours=10}
local ok,result=Processes.begin(store,"fixture.airDry","job:1","begin:1",context,provider);assert(ok and reserved==1 and result.job.status=="active")
assert(Processes.begin(store,"fixture.airDry","job:1","begin:1",context,provider)and reserved==1)
ok,result=Processes.advance(store,"job:1","tick:1",22,{humidity=.4});assert(ok and result.job.elapsedHours==12 and#result.job.observations==2)
ok,result=Processes.advance(store,"job:1","tick:2",34,{humidity=.5});assert(ok and result.job.status=="ready"and#result.job.observations==4)
ok,result=Processes.finish(store,"job:1","finish:1",provider,{});assert(ok and committed==1 and result.job.status=="completed")
assert(Processes.finish(store,"job:1","finish:1",provider,{})and committed==1)
local cancelStore={};context.foodId="food:2";assert(Processes.begin(cancelStore,"fixture.airDry","job:2","begin:2",context,provider))
assert(Processes.cancel(cancelStore,"job:2","cancel:1",provider,"player cancelled")and released==1)
local spoiled={};context.foodId="food:3";assert(Processes.begin(spoiled,"fixture.airDry","job:3","begin:3",context,provider))
ok,result=Processes.advance(spoiled,"job:3","spoil:1",11,{spoiled=true});assert(ok and result.job.status=="spoiled")
assert(Processes.cancel(spoiled,"job:3","spoil-release",provider,"spoiled")and released==2)
local uncertain={};context.foodId="food:4";assert(Processes.begin(uncertain,"fixture.airDry","job:4","begin:4",context,provider))
assert(Processes.advance(uncertain,"job:4","ready:4",34,{}));local bad={id="fixture.inventory",commit=function()error("unknown output")end}
assert(not Processes.finish(uncertain,"job:4","finish:4",bad,{}));assert(Processes.snapshot(uncertain,"job:4").status=="inspection_required")
assert(not Processes.begin({},"fixture.airDry","bad","bad",{stationId="rack",stationCapability="wrong",foodId="food",freshness="FRESH"},provider))
print("foodWorks persistent named-preservation process checks passed")
