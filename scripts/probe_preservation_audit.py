"""Reproduce known 0.7.0 framework limitations; not a native/runtime test."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().arg = lua.table_from({1: (root / 'Contents/mods/B47ANCEDProvisions/42/media/lua/shared/foodWorks/PreservationProcesses.lua').as_posix()})
lua.execute('''
foodWorks={}
local P=dofile(arg[1])
P.register{id="audit.dry",stationCapability="audit.rack",durationHours=240,cadenceHours=1,
 inputs={{itemType="Base.Apple",quantity=1}},eligible=function()return true end,observe=function()return {} end}
local store={}
local provider={id="audit.inventory",reserve=function()return true,{token="audit",unsafe=function()end}end}
assert(P.begin(store,"audit.dry","j","begin",{stationId="rack",stationCapability="audit.rack",foodId="apple",worldAgeHours=0},provider))
assert(type(P.snapshot(store,"j").reservation.receipt.unsafe)=="function")
print("OBSERVED receipt copy retains functions: serializability is not guaranteed")
assert(P.advance(store,"j","advance",240,{}))
local job=P.snapshot(store,"j")
assert(job.elapsedHours==168 and job.lastWorldAgeHours==240 and #job.observations==64)
print("OBSERVED 240-hour gap credits 168 hours, last marker 240, observations 64")
assert(P.advance(store,"j","advance-again",241,{}))
job=P.snapshot(store,"j")
assert(job.elapsedHours==169 and #job.observations==64 and job.nextCadenceHours==65)
print("OBSERVED next hour credits only 1 hour and cadence remains saturated at 64")
print("PASS bounded audit probes; no game execution or production changes")
''')
