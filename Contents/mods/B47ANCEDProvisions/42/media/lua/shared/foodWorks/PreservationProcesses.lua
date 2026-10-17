local foodWorks=rawget(_G,"foodWorks")or{}
local Processes={SCHEMA_VERSION=1,MAX_DEFINITIONS=64,MAX_INPUTS=16,MAX_OPERATIONS=64,MAX_ELAPSED_HOURS=168}
local definitions={};local definitionCount=0

local function finite(value)value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil end
local function validId(value,maximum)return type(value)=="string"and value~=""and#value<=maximum and not value:find("[%c]")end
local function copy(value,depth)
    if type(value)~="table"then return value end;depth=(depth or 0)+1;if depth>4 then return nil end
    local result,count={},0;for key,child in pairs(value)do count=count+1;if count>64 then break end
        if type(key)=="string"or type(key)=="number"then result[key]=copy(child,depth)end end;return result
end
local function inputs(values)
    assert(type(values)=="table"and#values>0 and#values<=Processes.MAX_INPUTS,"one to 16 exact inputs required")
    local result,seen={},{};for _,entry in ipairs(values)do
        assert(type(entry)=="table"and validId(entry.itemType,128)and validId(entry.role or"ingredient",64),"exact input identity and role required")
        local quantity=finite(entry.quantity);assert(quantity and quantity>0 and quantity<=10000,"bounded input quantity required")
        assert(not seen[entry.itemType..":"..(entry.role or"ingredient")],"duplicate process input")
        seen[entry.itemType..":"..(entry.role or"ingredient")]=true
        result[#result+1]={itemType=entry.itemType,role=entry.role or"ingredient",quantity=quantity,protected=entry.protected~=false}
    end;return result
end
local function operationSeen(job,id)for _,value in ipairs(job.processedOperations or{})do if value==id then return true end end;return false end
local function remember(job,id)job.processedOperations[#job.processedOperations+1]=id;while#job.processedOperations>Processes.MAX_OPERATIONS do table.remove(job.processedOperations,1)end end
local function validateJob(job)
    if type(job)~="table"or job.schemaVersion~=1 or not definitions[job.processId]or not validId(job.jobId,96)
        or type(job.status)~="string"or type(job.processedOperations)~="table"or type(job.reservation)~="table"then return false,"unsupported preservation job"end
    return true
end

function Processes.register(definition)
    assert(type(definition)=="table"and validId(definition.id,96),"bounded process id required")
    assert(validId(definition.stationCapability,96),"station capability required")
    local duration=finite(definition.durationHours);assert(duration and duration>0 and duration<=8760,"bounded duration required")
    local cadence=finite(definition.cadenceHours);assert(cadence and cadence>0 and cadence<=duration,"bounded cadence required")
    assert(type(definition.eligible)=="function"and type(definition.observe)=="function","eligibility and observation callbacks required")
    assert(not definitions[definition.id],"duplicate preservation process: "..definition.id)
    definitionCount=definitionCount+1;assert(definitionCount<=Processes.MAX_DEFINITIONS,"preservation process limit reached")
    definitions[definition.id]={id=definition.id,stationCapability=definition.stationCapability,durationHours=duration,
        cadenceHours=cadence,inputs=inputs(definition.inputs),eligible=definition.eligible,observe=definition.observe}
    return copy(definitions[definition.id])
end
function Processes.begin(store,processId,jobId,operationId,context,provider)
    if type(store)~="table"then return false,"persistent store required"end
    if not validId(jobId,96)or not validId(operationId,96)then return false,"bounded job and operation ids required"end
    if store[jobId]then local job=store[jobId];if validateJob(job)and operationSeen(job,operationId)then return true,{duplicate=true,job=copy(job)}end;return false,"preservation job already exists"end
    local definition=definitions[processId];if not definition then return false,"unknown preservation process"end
    if type(context)~="table"or not validId(context.stationId,192)or context.stationCapability~=definition.stationCapability
        or not validId(context.foodId,192)then return false,"stable food and matching station capability required"end
    local ok,eligible,reason=pcall(definition.eligible,copy(context));if not ok or eligible~=true then return false,ok and(reason or"food ineligible")or"eligibility failed"end
    if type(provider)~="table"or validId(provider.id,96)==false or type(provider.reserve)~="function"then return false,"reservation provider required"end
    local reserveOk,reserved,receipt=pcall(provider.reserve,copy(definition.inputs),copy(context),operationId)
    if not reserveOk then return false,"input reservation raised"end;if reserved~=true then return false,receipt or"input reservation rejected"end
    local job={schemaVersion=1,jobId=jobId,processId=processId,status="active",stationId=context.stationId,foodId=context.foodId,
        elapsedHours=0,nextCadenceHours=definition.cadenceHours,lastWorldAgeHours=finite(context.worldAgeHours),
        reservation={providerId=provider.id,status="reserved",receipt=copy(receipt)},processedOperations={operationId},observations={}}
    store[jobId]=job;return true,{duplicate=false,job=copy(job)}
end
function Processes.advance(store,jobId,operationId,worldAgeHours,context)
    local job=type(store)=="table"and store[jobId]or nil;local valid,err=validateJob(job);if not valid then return false,err end
    if not validId(operationId,96)then return false,"bounded operation id required"end;if operationSeen(job,operationId)then return true,{duplicate=true,job=copy(job)}end
    if job.status~="active"then return false,"preservation job is not active"end
    worldAgeHours=finite(worldAgeHours);if not worldAgeHours or not job.lastWorldAgeHours or worldAgeHours<job.lastWorldAgeHours then return false,"monotonic world age required"end
    local elapsed=math.min(worldAgeHours-job.lastWorldAgeHours,Processes.MAX_ELAPSED_HOURS);job.lastWorldAgeHours=worldAgeHours;job.elapsedHours=math.min(definitions[job.processId].durationHours,job.elapsedHours+elapsed)
    local definition=definitions[job.processId]
    while job.nextCadenceHours<=job.elapsedHours and#job.observations<64 do
        local ok,value=pcall(definition.observe,copy(context or{}),job.nextCadenceHours);if not ok or type(value)~="table"then job.status="inspection_required";job.failure="observation failed";remember(job,operationId);return false,job.failure end
        job.observations[#job.observations+1]=copy(value);job.nextCadenceHours=job.nextCadenceHours+definition.cadenceHours
    end
    if type(context)=="table"and context.spoiled==true then job.status="spoiled"elseif job.elapsedHours>=definition.durationHours then job.status="ready"end
    remember(job,operationId);return true,{duplicate=false,job=copy(job)}
end
function Processes.finish(store,jobId,operationId,provider,context)
    local job=type(store)=="table"and store[jobId]or nil;local valid,err=validateJob(job);if not valid then return false,err end
    if not validId(operationId,96)then return false,"bounded operation id required"end;if operationSeen(job,operationId)then return true,{duplicate=true,job=copy(job)}end
    if job.status~="ready"then return false,"preservation job is not ready"end
    if type(provider)~="table"or provider.id~=job.reservation.providerId or type(provider.commit)~="function"then return false,"matching completion provider required"end
    job.status="committing";job.reservation.status="committing";local ok,committed,receipt=pcall(provider.commit,copy(job),copy(context or{}),operationId)
    if not ok or committed~=true then job.status="inspection_required";job.reservation.status="inspection_required";job.failure=ok and tostring(receipt or"commit rejected"):sub(1,160)or"completion raised";remember(job,operationId);return false,job.failure end
    job.status="completed";job.reservation.status="committed";job.completionReceipt=copy(receipt);remember(job,operationId);return true,{duplicate=false,job=copy(job)}
end
function Processes.cancel(store,jobId,operationId,provider,reason)
    local job=type(store)=="table"and store[jobId]or nil;local valid,err=validateJob(job);if not valid then return false,err end
    if not validId(operationId,96)then return false,"bounded operation id required"end;if operationSeen(job,operationId)then return true,{duplicate=true,job=copy(job)}end
    if job.status~="active"and job.status~="ready"and job.status~="spoiled"then return false,"preservation job cannot be cancelled"end
    if type(provider)~="table"or provider.id~=job.reservation.providerId or type(provider.release)~="function"then return false,"matching release provider required"end
    local ok,released,receipt=pcall(provider.release,copy(job),operationId);if not ok or released~=true then job.status="inspection_required";job.failure="reservation release uncertain";remember(job,operationId);return false,job.failure end
    job.status="cancelled";job.cancelReason=tostring(reason or"cancelled"):sub(1,160);job.reservation.status="released";job.releaseReceipt=copy(receipt);remember(job,operationId);return true,{duplicate=false,job=copy(job)}
end
function Processes.snapshot(store,jobId)local job=type(store)=="table"and store[jobId]or nil;local ok,err=validateJob(job);return ok and copy(job)or nil,err end

foodWorks.PreservationProcesses=Processes;_G.foodWorks=foodWorks
return Processes
