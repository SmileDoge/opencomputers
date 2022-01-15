OpenComputers = OpenComputers or {}

if SERVER then

AddCSLuaFile("opencomputers/client/screen.lua")
include("opencomputers/machine.lua")

include("opencomputers/component_api.lua")


OpenComputers.Machines = OpenComputers.Machines or {}

function table.pack(...)
    local a = {...}
    a.n = #a
    return a
end

function table.unpack(...)
    return unpack(...)
end

else
    include("opencomputers/client/screen.lua")
end