OpenComputers.Component = OpenComputers.Component or {}
OpenComputers.Component.Connected = OpenComputers.Component.Connected or {}

local r = math.random
function OpenComputers.Component.GenUUID()
    return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
	r(0,255),r(0,255),r(0,255),r(0,255),
	r(0,255),r(0,255),
	r(64,79),r(0,255),
	r(128,191),r(0,255),
	r(0,255),r(0,255),r(0,255),r(0,255),r(0,255),r(0,255))
end

function OpenComputers.Component.GenENV(machine)
    local component = {}

    function component.doc()
        return "" -- todo
    end

    function component.methods(address)
        if machine.components[address] then
            local methods = {}
            for k, v in pairs(machine.components[address].methods) do
                methods[k] = {direct = v.direct, getter = v.getter, setter = v.setter}
            end
            return methods
        end
        return nil, "no such component"
    end

    function component.invoke(address, method, ...)
        if machine.components[address] ~= nil then
            local meth = machine.components[address][method]
            if meth == nil then
                error("no such method", 2)
            end
            return meth(machine.components[address], ...)
        end
    end

    function component.list(filter, exact)
        local tbl = {}
        local data = {}
        for k, v in pairs(machine.components) do
            if filter == nil or (exact and v.type == filter) or (not exact and v.type:find(filter, nil, true)) then
                tbl[k] = v.type
                data[#data + 1] = k
                data[#data + 1] = v.type
            end
        end
        local place = 1
        return setmetatable(tbl,{__call = function()
            local addr,type = data[place], data[place + 1]
            place = place + 2
            return addr,type
        end})
    end

    function component.type(address)
        if machine.components[address] ~= nil then
            return machine.components[address].type
        end
        return nil, "no such component"
    end

    function component.slot(address)
        if machine.components[address] ~= nil then
            return machine.components[address].slot or 0
        end
        return nil, "no such component"
    end

    return component
end

--[[
function OpenComputers.Component.Reset()
    OpenComputers.Component.Connected = {}
end

function OpenComputers.Component.Connect(obj)
    local addr = obj.address

    for k, v in pairs(obj.methods) do
        v.direct = v.direct or false
        v.getter = v.getter or false
        v.setter = v.setter or false
        v.limit = v.limit or math.huge
    end

    OpenComputers.Component.Connected[addr] = obj
end

function OpenComputers.Component.Disconnect(address)
    if OpenComputers.Component.Connected[address] then
        OpenComputers.Component.Connected[address] = nil
    end
end

function OpenComputers.Component.Invoke(address, method, ...)
    if OpenComputers.Component.Connected[address] ~= nil then
        local comp = OpenComputers.Component.Connected[address]
        local meth = OpenComputers.Component.Connected[address][method]
        if meth == nil then
            error("no such method", 2)
        end
        return meth(OpenComputers.Component.Connected[address], ...)
    end
end

function OpenComputers.Component.List(filter, exact)
    return env_component.list(filter, exact)
end

function OpenComputers.Component.Exists(address)
    if OpenComputers.Component.Connected[address] ~= nil then
        return OpenComputers.Component.Connected[address].type
    end
end

local env_component = {}


return env_component
]]