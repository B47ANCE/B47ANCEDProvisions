local foodWorks=rawget(_G,"foodWorks")or{}
local Transactions={ROOT_KEY="foodWorks.applianceTransaction.v1",HISTORY_KEY="foodWorks.applianceOperations.v1",MAX_PROCESSES=64}
local processes={};local processCount=0

local function authoritative()return not(type(isClient)=="function"and isClient()==true)end
local function validId(value,maximum)return type(value)=="string"and value~=""and#value<=maximum and not value:find("[%c]")end
local function finite(value)value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil end
local function data(object)
    if not object or type(object.getModData)~="function"then return nil,"appliance ModData unavailable"end
    local ok,result=pcall(object.getModData,object);return ok and type(result)=="table"and result or nil,"appliance ModData unavailable"
end
local function summary(value)
    if type(value)~="table"then return type(value)=="string"and value:sub(1,160)or nil end
    local result,count={},0;for key,child in pairs(value)do if count>=16 then result.truncated=true;break end
        if(type(key)=="string"or type(key)=="number")and(type(child)=="string"or type(child)=="number"or type(child)=="boolean")then result[key]=type(child)=="string"and child:sub(1,160)or child;count=count+1 end end
    return result
end
local function seen(root,id)for _,value in ipairs(type(root[Transactions.HISTORY_KEY])=="table"and root[Transactions.HISTORY_KEY]or{})do if value==id then return true end end;return false end
local function remember(root,id)local values=type(root[Transactions.HISTORY_KEY])=="table"and root[Transactions.HISTORY_KEY]or{};root[Transactions.HISTORY_KEY]=values;values[#values+1]=id;while#values>64 do table.remove(values,1)end end
local function rollbackResources(record,appliance,waterOwner,powerAPI,waterAPI)
    local waterOk=not record.waterReserved or waterAPI and waterAPI.rollbackDrainTransaction(waterOwner,record.waterOperationId)==true
    local powerOk=not record.powerReserved or powerAPI and powerAPI.rollbackEnergyTransaction(appliance,record.powerOperationId)==true
    return waterOk and powerOk
end

function Transactions.register(definition)
    assert(type(definition)=="table"and validId(definition.id,96),"bounded process id required")
    assert(type(definition.matches)=="function"and type(definition.commit)=="function","process matches and commit callbacks required")
    local energy=finite(definition.energyAmount)or 0;local water=finite(definition.waterAmount)or 0
    assert(energy>=0 and energy<=1000000 and water>=0 and water<=1000000 and(energy>0 or water>0),"absolute resource amount required")
    assert(not processes[definition.id],"duplicate appliance process: "..definition.id)
    processCount=processCount+1;assert(processCount<=Transactions.MAX_PROCESSES,"appliance process limit reached")
    processes[definition.id]={id=definition.id,energyAmount=energy,waterAmount=water,matches=definition.matches,validate=definition.validate,commit=definition.commit}
    return{id=definition.id,energyAmount=energy,waterAmount=water}
end
function Transactions.execute(appliance,waterOwner,processId,operationId,context)
    if not authoritative()then return false,"non-authority"end
    if not validId(operationId,96)then return false,"bounded operation id required"end
    local definition=processes[processId];if not definition then return false,"unknown appliance process"end
    local root,err=data(appliance);if not root then return false,err end
    if seen(root,operationId)then return true,{duplicate=true,operationId=operationId}end
    if root[Transactions.ROOT_KEY]~=nil then return false,"appliance transaction requires inspection"end
    context=type(context)=="table"and context or{}
    if not validId(context.applianceStableId,192)or definition.waterAmount>0 and not validId(context.waterStableId,192)then return false,"stable resource identities required"end
    local matchedOk,matched=pcall(definition.matches,appliance,context);if not matchedOk or matched~=true then return false,"exact appliance identity rejected"end
    if type(definition.validate)=="function"then local ok,allowed,reason=pcall(definition.validate,appliance,waterOwner,context);if not ok then return false,"process validation failed"end;if allowed~=true then return false,reason or"process rejected"end end
    local powerAPI=rawget(_G,"powerWorks");local waterAPI=rawget(_G,"waterWorks")
    if definition.energyAmount>0 and(type(powerAPI)~="table"or type(powerAPI.beginEnergyTransaction)~="function")then return false,"power transaction API unavailable"end
    if definition.waterAmount>0 and(type(waterAPI)~="table"or type(waterAPI.beginDrainTransaction)~="function")then return false,"water transaction API unavailable"end
    local record={schemaVersion=1,status="reserving",operationId=operationId,processId=processId,
        applianceStableId=context.applianceStableId,waterStableId=context.waterStableId,
        powerOperationId=operationId..":power",waterOperationId=operationId..":water",powerReserved=false,waterReserved=false}
    root[Transactions.ROOT_KEY]=record
    if definition.energyAmount>0 then local ok,reason=powerAPI.beginEnergyTransaction(appliance,definition.energyAmount,record.powerOperationId);if not ok then root[Transactions.ROOT_KEY]=nil;return false,reason end;record.powerReserved=true end
    if definition.waterAmount>0 then local ok,reason=waterAPI.beginDrainTransaction(waterOwner,definition.waterAmount,record.waterOperationId);if not ok then
        if not rollbackResources(record,appliance,waterOwner,powerAPI,waterAPI)then record.status="inspection_required";record.reason="water reservation failed and power rollback is uncertain";return false,record.reason end
        root[Transactions.ROOT_KEY]=nil;return false,reason
    end;record.waterReserved=true end
    record.status="resources_reserved"
    local called,committed,receipt=pcall(definition.commit,appliance,waterOwner,context)
    if not called then record.status="process_inspection_required";record.reason=tostring(committed):sub(1,160);return false,"process commit raised; inspection required"end
    if committed~=true then
        if rollbackResources(record,appliance,waterOwner,powerAPI,waterAPI)then root[Transactions.ROOT_KEY]=nil;return false,tostring(receipt or"process rejected"):sub(1,160)end
        record.status="inspection_required";record.reason="process rejected but resource rollback is uncertain";return false,record.reason
    end
    record.status="process_committed";record.processReceipt=summary(receipt)
    if record.waterReserved then local ok,reason=waterAPI.commitDrainTransaction(waterOwner,record.waterOperationId);if not ok then record.status="water_commit_inspection_required";record.reason=tostring(reason):sub(1,160);return false,record.reason end;record.waterReserved=false end
    if record.powerReserved then local ok,reason=powerAPI.commitEnergyTransaction(appliance,record.powerOperationId);if not ok then record.status="power_commit_inspection_required";record.reason=tostring(reason):sub(1,160);return false,record.reason end;record.powerReserved=false end
    remember(root,operationId);root[Transactions.ROOT_KEY]=nil
    return true,{duplicate=false,operationId=operationId,processId=processId,receipt=summary(receipt)}
end
function Transactions.inspect(appliance)local root,err=data(appliance);if not root then return nil,err end;return summary(root[Transactions.ROOT_KEY])end

foodWorks.ApplianceTransactions=Transactions
_G.foodWorks=foodWorks
return Transactions
