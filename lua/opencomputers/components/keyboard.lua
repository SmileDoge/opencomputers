local keyboard_api = {}

net.Receive("opencomputers-send-screen-data", function(_, ply)
    local typ = net.ReadUInt(8)
    local machine_address = net.ReadString()
    local screen_address = net.ReadString()

    if OpenComputers.Machines[machine_address] == nil then return end

    if typ == 101 then -- keyboard
        local press_typ = net.ReadBool() -- true = key_down, false = key_up
        local code = net.ReadUInt(32)
        local char = net.ReadUInt(32)
        print(press_typ, code, char)
        if press_typ then
            table.insert(OpenComputers.Machines[machine_address].machine.signals, {"key_down", machine_address, code, char})
        else
            
            table.insert(OpenComputers.Machines[machine_address].machine.signals, {"key_up", machine_address, code, char})
        end

    elseif typ == 102 then -- mouse click
        
    end
end)

function Create(address, machine_address)
    return setmetatable({
        address = address or OpenComputers.Component.GenUUID(),
        machine_address = machine_address,

        type = "keyboard",
        methods = {
        }
    }, {__index = keyboard_api})
end

return Create