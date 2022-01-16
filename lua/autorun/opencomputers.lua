OpenComputers = OpenComputers or {}

if SERVER then

AddCSLuaFile("opencomputers/client/screen.lua")
include("opencomputers/component_api.lua")

OpenComputers.Machines = OpenComputers.Machines or {}

function OpenComputers.GetMachineEnt(machine_address)
    return OpenComputers.Machines[machine_address]
end

function OpenComputers.GetMachine(machine_address)
    if OpenComputers.Machines[machine_address] then
        return OpenComputers.Machines[machine_address].machine
    end
    return {}
end

function table.pack(...)
    local a = {...}
    a.n = #a
    return a
end

function table.unpack(tbl, st, en)
    tbl.n = nil
    return unpack(tbl, st, en)
end

else
    include("opencomputers/client/screen.lua")
end