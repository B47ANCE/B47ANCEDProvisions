foodWorks={};isClient=function()return false end
local Transactions=dofile(arg[1])
local root={};local appliance={kind="coffee",getModData=function()return root end};local water={}
local events={}
powerWorks={beginEnergyTransaction=function(_,amount,id)events[#events+1]="reserve-power:"..amount;return true end,
    commitEnergyTransaction=function()events[#events+1]="commit-power";return true end,
    rollbackEnergyTransaction=function()events[#events+1]="rollback-power";return true end}
waterWorks={beginDrainTransaction=function(_,amount,id)events[#events+1]="reserve-water:"..amount;return true end,
    commitDrainTransaction=function()events[#events+1]="commit-water";return true end,
    rollbackDrainTransaction=function()events[#events+1]="rollback-water";return true end}
local commits=0
Transactions.register{id="fixture.brew",energyAmount=2,waterAmount=1,matches=function(value)return value.kind=="coffee"end,
    validate=function()return true end,commit=function()commits=commits+1;events[#events+1]="process";return true,{output="coffee"}end}
local context={applianceStableId="coffee:1",waterStableId="tank:1"}
local ok,result=Transactions.execute(appliance,water,"fixture.brew","brew-1",context)
assert(ok and not result.duplicate and commits==1 and#events==5)
assert(events[1]=="reserve-power:2"and events[2]=="reserve-water:1"and events[3]=="process"and events[4]=="commit-water"and events[5]=="commit-power")
assert(Transactions.execute(appliance,water,"fixture.brew","brew-1",context)and commits==1,"replay must not duplicate output")
Transactions.register{id="fixture.reject",energyAmount=1,waterAmount=1,matches=function()return true end,commit=function()return false,"no output"end}
events={};assert(not Transactions.execute(appliance,water,"fixture.reject","reject-1",context));assert(events[3]=="rollback-water"and events[4]=="rollback-power"and Transactions.inspect(appliance)==nil)
Transactions.register{id="fixture.uncertain",energyAmount=1,waterAmount=1,matches=function()return true end,commit=function()error("unknown output")end}
events={};assert(not Transactions.execute(appliance,water,"fixture.uncertain","uncertain-1",context));local inspection=assert(Transactions.inspect(appliance));assert(inspection.status=="process_inspection_required")
assert(not Transactions.execute(appliance,water,"fixture.brew","later",context),"uncertain process must quarantine appliance")
print("foodWorks recoverable cross-domain appliance transaction checks passed")
