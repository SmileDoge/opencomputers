local gpu_api = {
    bind_address = nil
}

local invoke = function() end

function gpu_api:bind(address, reset )
    if reset == nil then
        reset = true
    end
    local thing = OpenComputers.Component.Exists(address)
    if thing == nil then
        return nil, "invalid address"
    elseif thing ~= "screen" then
        return nil, "not a screen"
    end
    self.bind_address = address
    if reset then
        local mw, mh = invoke(self.bind_address, "maxResolution")
        print(mw, mh)
        invoke(self.bind_address, "setResolution", math.min(mw, self.maxwidth), math.min(mh, self.maxheight))
        invoke(self.bind_address, "setDepth", math.min(invoke(self.bind_address, "maxDepth"), self.maxtier))
        invoke(self.bind_address, "setForeground", 0xFFFFFF)
        invoke(self.bind_address, "setBackground", 0x000000)
    end
end

function gpu_api:getForeground()
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "getForeground")
end

function gpu_api:setForeground(value, palette)
    if self.bind_address == nil then 
        return nil, "no screen"
    end
    if palette and invoke(self.bind_address, "getDepth") == 1 then
        error("color palette not supported", 0)
    end
    if palette == true and (value < 0 or value > 15) then
        error("invalid palette index", 0)
    end
    return invoke(self.bind_address, "setForeground", value, palette)
end

function gpu_api:getBackground()
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "getBackground")
end

function gpu_api:setBackground(value, palette)
    if self.bind_address == nil then 
        return nil, "no screen"
    end
    if palette and invoke(self.bind_address, "getDepth") == 1 then
        error("color palette not supported", 0)
    end
    if palette == true and (value < 0 or value > 15) then
        error("invalid palette index", 0)
    end
    return invoke(self.bind_address, "setBackground", value, palette)
end

local depthTbl = {1,4,8}
local rdepthTbl = {1,[4]=2,[8]=3}
local depthNames = {"OneBit","FourBit","EightBit"}

function gpu_api:getDepth()
    return depthTbl[invoke(self.bind_address, "getDepth")]
end

function gpu_api:setDepth(depth)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    depth = math.floor(depth)
    local scrmax = invoke(self.bind_address, "maxDepth")
    if rdepthTbl[depth] == nil or rdepthTbl[depth] > math.max(scrmax, self.maxtier) then
        error("unsupported depth", 0)
    end
    local old = depthNames[invoke(self.bind_address, "getDepth")]
    invoke(self.bind_address, "setDepth", rdepthTbl[depth])
    return old
end

function gpu_api:maxDepth()
    return depthTbl[math.min(invoke(self.bind_address, "maxDepth"), self.maxtier)]
end

function gpu_api:fill(x, y, width, height, char)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "fill", x, y, width, height, char)
end

function gpu_api:getScreen()
    return self.bind_address
end

function gpu_api:getResolution()
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "getResolution")
end

function gpu_api:setResolution(width, height)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    local mw, mh = invoke(self.bind_address, "maxResolution")
    print(mw, mh, width, height)
    mw, mh = math.min(mw, self.maxwidth), math.min(mh, self.maxheight)
    if width <= 0 or width >= mw+1 or height <= 0 or height >= mh + 1 then
        error("unsupported resolution", 0)
    end
    return invoke(self.bind_address, "setResolution", width, height)
end

function gpu_api:maxResolution()
    if self.bind_address == nil then
        return nil, "no screen"
    end
    local mw, mh = invoke(self.bind_address, "maxResolution")
    return math.min(mw, self.maxwidth), math.min(mh, self.maxheight)
end

function gpu_api:getViewport()
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "getResolution")
end

function gpu_api:setViewport(width, height)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    local mw, mh = invoke(self.bind_address, "maxResolution")
    mw, mh = math.min(mw, self.maxwidth), math.min(mh, self.maxheight)
    if width <= 0 or width >= mw+1 or height <= 0 or height >= mh + 1 then
        error("unsupported viewport size", 0)
    end
    return invoke(self.bind_address, "setResolution", width, height)
end

function gpu_api:getPaletteColor(index)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    if invoke(self.bind_address, "getDepth") == 1 then
        return "paletter not available"
    end
    index = math.floor(index)
    if index < 0 or index > 15 then
        error("invalid palette index", 0)
    end
    return invoke(self.bind_address, "getPaletteColor", index)
end

function gpu_api:setPaletteColor(index)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    if invoke(self.bind_address, "getDepth") == 1 then
        return "paletter not available"
    end
    index = math.floor(index)
    if index < 0 or index > 15 then
        error("invalid palette index", 0)
    end
    return invoke(self.bind_address, "setPaletteColor", index)
end

function gpu_api:get(x, y)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    local w,h = invoke(self.bind_address, "getResolution")
    if x < 1 or x >= w+1 or y < 1 or y >= h+1 then
		error("index out of bounds", 0)
	end
    return invoke(self.bind_address, "get", x, y)
end

function gpu_api:set(x, y, val, vert)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "set", x, y, val, vert)
end

function gpu_api:copy(x, y, width, height, tx, ty)
    if self.bind_address == nil then
        return nil, "no screen"
    end
    return invoke(self.bind_address, "copy", x, y, width, height, tx, ty)
end

local function Create(address, maxwidth, maxheight, maxtier, machine_address)
    local tbl = setmetatable({
        address = address or OpenComputers.Component.GenUUID(),
        machine_address = machine_address,
        maxwidth = maxwidth or 80,
        maxheight = maxheight or 25,
        maxtier = maxtier or 3,

        tier = maxtier,

        type = "gpu",
        methods = {
            bind = {},
            getForeground = {direct = true},
            setForeground = {direct = true},
            getBackground = {direct = true},
            setBackground = {direct = true},
            getDepth = {direct = true},
            setDepth = {},
            maxDepth = {direct = true},
            fill = {direct = true},
            getScreen = {direct = true},
            getResolution = {direct = true},
            setResolution = {},
            maxResolution = {direct = true},
            getViewport = {direct = true},
            setViewport = {},
            getPaletteColor = {direct = true},
            setPaletteColor = {direct = true},
            get = {direct = true},
            set = {direct = true},
            copy = {direct = true},

        }
    }, {__index = gpu_api})
    invoke = function(address, method, ...)
        print(OpenComputers.Machines[machine_address])
        print(address, method, ...)
        local a = table.pack(OpenComputers.Machines[machine_address]:InvokeComponent(address, method, ...))
        PrintTable(a)
        return table.unpack(a, 1, a.n)
    end
    return tbl
end

return Create