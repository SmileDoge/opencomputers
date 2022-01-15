local screen_api = {
    buffer = {},
    foreground = 0xFFFFFF,
    background = 0x000000
}

function screen_api:isTouchModeInverted()
    return self.touchinvert
end

function screen_api:setTouchModeInverted(value)
    self.touchinvert = value
end

function screen_api:isPrecise()
    return self.precise
end

function screen_api:setPrecise(enabled)
    self.precise = enabled
end

function screen_api:turnOff()
    --todo
    return false
end

function screen_api:turnOn()
    --todo
    return false
end

function screen_api:isOn()
    --todo
    return true
end

function screen_api:getAspectRatio()
    --todo
    return 1, 1
end

function screen_api:getKeyboards()
    local klist = {}
    for addr in OpenComputers.Machines[self.machine_address]:ListComponent("keyboard", true) do
        klist[#klist+1] = addr
    end
    return klist
end

local t3pal = {}
for i = 0,15 do
	t3pal[i] = (i+1)*0x0F0F0F
end
local t2pal = {[0]=0xFFFFFF,0xFFCC33,0xCC66CC,0x6699FF,0xFFFF33,0x33CC33,0xFF6699,0x333333,0xCCCCCC,0x336699,0x9933CC,0x333399,0x663300,0x336600,0xFF3333,0x000000}
local palcol = {}

local function loadPalette(tier)
	local palcopy
	if tier == 3 then
		palcopy = t3pal
	else
		palcopy = t2pal
	end
	for i = 0,15 do
		palcol[i] = palcopy[i]
	end
end

local function extract(value)
	return bit.rshift(bit.band(value,0xFF0000),16),
		bit.rshift(bit.band(value,0xFF00),8),
		bit.band(value,0xFF)
end

local function compare(value1, value2)
	local r1,g1,b1 = extract(value1)
	local r2,g2,b2 = extract(value2)
	local dr,dg,db = r1-r2,g1-g2,b1-b2
	return 0.2126*dr^2 + 0.7152*dg^2 + 0.0722*db^2
end

local function searchPalette(value)
	local score, index = math.huge
	for i = 0,15 do
		local tscore = compare(value,palcol[i])
		if score > tscore then
			score = tscore
			index = i
		end
	end
	return index, score
end
local function getColor(value, sel, tier)
	selectPal(nil, sel)
	if tier == 3 then
		local pi,ps = searchPalette(value)
		local r,g,b = extract(value)
		r=math.floor(math.floor(r*5/255+0.5)*255/5+0.5)
		g=math.floor(math.floor(g*7/255+0.5)*255/7+0.5)
		b=math.floor(math.floor(b*4/255+0.5)*255/4+0.5)
		local defc = r*65536 + g*256 + b
		local defs = compare(value, defc)
		if defs < ps then
			return defc
		else
			selectPal(pi, sel)
			return palcol[pi]
		end
	elseif tier == 2 then
		local pi = searchPalette(value)
		selectPal(pi, sel)
		return palcol[pi]
	else
		if value > 0 then
			return settings.monochromeColor
		else
			return 0
		end
	end
end


util.AddNetworkString("opencomputers-send-screen-data")

local function send_char(addr, x, y, char, fg, bg)
    net.Start("opencomputers-send-screen-data")
        net.WriteUInt(1, 8)
        net.WriteString(addr)
        net.WriteInt(x, 16)
        net.WriteInt(y, 16)
        net.WriteString(char)
        net.WriteUInt(fg, 32)
        net.WriteUInt(bg, 32)
    net.Broadcast()
end
local function set_resolution(addr, width, height)
    net.Start("opencomputers-send-screen-data")
        net.WriteUInt(2, 8)
        net.WriteString(addr)
        net.WriteInt(width, 16)
        net.WriteInt(height, 16)
    net.Broadcast()
end
local function new_screen(addr, width, height, tier)
    net.Start("opencomputers-send-screen-data")
        net.WriteUInt(3, 8)
        net.WriteString(addr)
        net.WriteInt(width, 16)
        net.WriteInt(height, 16)
        net.WriteInt(tier, 16)
    net.Broadcast()
end
local function send_str(addr, x, y, text, vertical, fg, bg)
    net.Start("opencomputers-send-screen-data")
        net.WriteUInt(4, 8)
        net.WriteString(addr)
        net.WriteInt(x, 16)
        net.WriteInt(y, 16)
        net.WriteString(text)
        net.WriteBool(vertical)
        net.WriteUInt(fg, 32)
        net.WriteUInt(bg, 32)
    net.Broadcast()
end

local function fill_char(addr, x1, y1, x2, y2, char, fg, bg)
    net.Start("opencomputers-send-screen-data")
        net.WriteUInt(5, 8)
        net.WriteString(addr)
        net.WriteInt(x1, 16)
        net.WriteInt(y1, 16)
        net.WriteInt(x2, 16)
        net.WriteInt(y2, 16)
        net.WriteString(char)
        net.WriteUInt(fg, 32)
        net.WriteUInt(bg, 32)
    net.Broadcast()
end
--[[
local function send_buffer(buf, ply)
    net.Start("opencomputers-send-screen-data")
        net.WriteInt(#buf[1], 32)
        net.WriteInt(#buf, 32)
        for y, xval in pairs(buf) do
            for x, val in pairs(xval) do
                net.WriteString(val.char)
                net.WriteUInt(fg, 32)
                net.WriteUInt(bg, 32)
            end
        end
    net.Send(ply)
end
]]

local function init_buffer(width, height)
    local tbl = {}

    for i = 1, height do
        tbl[i] = {}
        for j = 1, width do
            tbl[i][j] = {char = "", fg = 0xFFFFFF, bg = 0x000000}
        end
    end

    return tbl
end

function screen_api:getColor(color)
    if self.tier == 3 then
        local r, g, b = extract(color)
        r=math.floor(math.floor(r*5/255+0.5)*255/5+0.5)
        g=math.floor(math.floor(g*7/255+0.5)*255/7+0.5)
        b=math.floor(math.floor(b*4/255+0.5)*255/4+0.5)
        local defc = r*65536 + g*256 + b
        return defc
    elseif self.tier == 2 then
        return color
    else
        if color > 0 then return 0xffffff else return 0 end
    end
end

function screen_api:getForeground()
    return self.foreground, false
end

function screen_api:setForeground(value, palette)
    if palette then
        print("attemp to set palette / foreground")
        print(debug.traceback())
    end

    local old = self.foreground

    self.foreground = self:getColor(value)

    return old, false
end

function screen_api:getBackground()
    return self.background, false
end

function screen_api:setBackground(value, palette)
    if palette then
        --todo
        print("attemp to set palette / background")
        print(debug.traceback())
    end

    local old = self.background

    self.background = self:getColor(value)

    return old, false
end

function screen_api:getDepth()
    return self.tier
end

function screen_api:setDepth(depth)
    return -- todo
end

function screen_api:maxDepth()
    return 3 -- todo
end

function screen_api:fill(x1, y1, w, h, char)
    x1, y1, w, h = math.Truncate(x1), math.Truncate(y1), math.Truncate(w), math.Truncate(h)
    if w <= 0 or h <= 0 then
        return true
    end
    char = utf8.sub(char, 1, 1)
    local x2 = x1+w-1
    local y2 = y1+h-1
    if x2 < 1 or y2 < 1 or x1 > self.width or y1 > self.height then
        return true
    end
    x1, y1, x2, y2 = math.max(x1, 1), math.max(y1, 1), math.min(x2, self.width), math.min(y2, self.height)
    --(addr, x1, y1, x2, y2, char, fg, bg)
    fill_char(self.address, x1, y1, x2, y2, char, self.foreground, self.background)
    for y = y1, y2 do
        for x = x1, x2 do
            self.buffer[y][x].char = char
            self.buffer[y][x].fg = self.foreground
            self.buffer[y][x].bg = self.background
        end
    end
    return true
end

function screen_api:getResolution()
    return self.width, self.height
end

function screen_api:setResolution(newwidth, newheight)
    newwidth  = math.Clamp(newwidth , 10, self.maxwidth)
    newheight = math.Clamp(newheight, 10, self.maxheight)

    local oldw, oldh = self.width, self.height

    if self.width ~= newwidth or self.height ~= newheight then
        self.width = newwidth
        self.height = newheight

        set_resolution(self.address, newwidth, newheight)

        self.buffer = init_buffer(newwidth, newheight)
    end

    return oldw ~= newwidth or oldh ~= newheight
end

function screen_api:maxResolution()
    return self.maxwidth, self.maxheight
end

function screen_api:getPaletteColor(index)
    return 0 -- todo
end

function screen_api:setPaletteColor(index, color)
    return 0 -- todo
end

function screen_api:get(x, y)
    x, y = math.Truncate(x), math.Truncate(y)

    return self.buffer[y][x].char, self.buffer[y][x].fg, self.buffer[y][x].bg, 0, 0
end

function screen_api:set(x, y, val, vertical)
    val = tostring(val)
    val = utf8.sub(val, 1, vertical and self.height or self.width)

    x, y = math.Truncate(x), math.Truncate(y)
    send_str(self.address, x, y, val, vertical, self.foreground, self.background)
    if vertical and x >= 1 and x <= self.width and y <= self.height then
        for _, c in utf8.codes(val) do
            if y >= 1 then
                --send_char(self.address, x, y, utf8.char(c), self.foreground, self.background)
                self.buffer[y][x].char = c
                self.buffer[y][x].fg = self.foreground
                self.buffer[y][x].bg = self.background
            end
            y = y + 1
            if y > height then break end
        end
    elseif not vertical and y >= 1 and y <= self.height and x <= self.width then
        for _, c in utf8.codes(val) do
            if x >= 1 then
                --send_char(self.address, x, y, utf8.char(c), self.foreground, self.background)
                self.buffer[y][x].char = c
                self.buffer[y][x].fg = self.foreground
                self.buffer[y][x].bg = self.background
            end
            x = x + 1
            if x > self.height then break end
        end
    end
    return true
end

function screen_api:copy(x1, y1, w, h, tx, ty)
    return -- todo
end

local function Create(address, maxwidth, maxheight, tier)
    local tbl = setmetatable({
        address = address or OpenComputers.Component.GenUUID(),
        maxwidth = maxwidth or 80,
        maxheight = maxheight or 25,

        tier = tier or 3,

        width = maxwidth,
        height = maxheight,

        touchinvert = false,
        precise = false,

        type = "screen",
        methods = {
            isTouchModeInverted = {},
            setTouchModeInverted = {},
            isPrecise = {},
            setPrecise = {},
            turnOff = {},
            turnOn = {},
            isOn = {},
            getAspectRatio = {},
            getKeyboards = {},
        }
    }, {__index = screen_api})
    --loadPalette(tbl.tier)
    new_screen(tbl.address, tbl.width, tbl.height, tbl.tier)
    tbl.buffer = init_buffer(tbl.width, tbl.height)
    return tbl
end

return Create