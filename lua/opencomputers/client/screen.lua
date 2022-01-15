OpenComputers = OpenComputers or {}

local width = 80
local height = 25

OpenComputers.Buffer = OpenComputers.Buffer or {}

local function setsize(w, h)
    local tbl = {}

    for i = 1, h do
        tbl[i] = {}
        for j = 1, w do
            tbl[i][j] = {char = "", fg = 0xffffff, bg = 0x000000}
        end
    end


    OpenComputers.Buffer = tbl
end

net.Receive("opencomputers-send-screen-data", function()
    local typ = net.ReadUInt(8)
    if typ == 1 then
        
        local addr = net.ReadString()
        local x = net.ReadInt(16)
        local y = net.ReadInt(16)
        local c = net.ReadString()
        local fg = net.ReadUInt(32)
        local bg = net.ReadUInt(32)

        OpenComputers.Buffer[y][x] = {char = c, fg = fg, bg = bg}
    elseif typ == 2 then
        
    elseif typ == 3 then
        local addr = net.ReadString()
        local w = net.ReadInt(16)
        local h = net.ReadInt(16)
        setsize(w, h)
    elseif typ == 4 then 
        local addr = net.ReadString()
        local x = net.ReadInt(16)
        local y = net.ReadInt(16)
        local text = net.ReadString()
        print(x, y, text)
        local vertical = net.ReadBool()
        local fg = net.ReadUInt(32)
        local bg = net.ReadUInt(32)

        for i = 1, utf8.len(text) do
            local char = utf8.sub(text, i, i+1)
            
            if not OpenComputers.Buffer[y] then continue end
            if not OpenComputers.Buffer[y][x] then continue end

            OpenComputers.Buffer[y][x] = {char = char, fg = fg, bg = bg}

            x = x + 1
        end
    end
end)

local font = surface.CreateFont("OpenComputersFont", {
    font = "Unifont",
    extended = true,
    size = 16,
    weight = 0,
    antialias = false,
})

local function getColor(a)

    local r = bit.rshift(a, 16)
    local g = bit.band(bit.rshift(a, 8),255)
    local b = bit.band(a,255)

    return Color(r, g, b)
end


local fg_color = -math.huge
local bg_color = -math.huge

local function getColor2(a)

    --if bg_color == a then return end
    --bg_color = a

    local r = bit.rshift(a, 16)
    local g = bit.band(bit.rshift(a, 8),255)
    local b = bit.band(a,255)

    surface.SetDrawColor(r, g, b, 255)
end

local function getColor3(a)

    --if fg_color == a then return end
    --fg_color = a

    local r = bit.rshift(a, 16)
    local g = bit.band(bit.rshift(a, 8),255)
    local b = bit.band(a,255)

    surface.SetTextColor(r, g, b, 255)
end

hook.Remove("HUDPaint", "RenderScreen")
--[[
hook.Add("HUDPaint", "RenderScreen", function()

    if not OpenComputers.Buffer[1] then return end
    local h = #OpenComputers.Buffer
    local w = #OpenComputers.Buffer[1]

    surface.SetFont("OpenComputersFont")
    for i = 1, h do
        for j = 1, w do
            local tbl = OpenComputers.Buffer[i][j]
            getColor2(tbl.bg)
            surface.DrawRect((j-1)*8, (i-1)*16, 8, 16)
            if tbl.char ~= "" then
                getColor3(tbl.fg)
                surface.SetTextPos((j-1)*8, (i-1)*16)
                surface.DrawText(tbl.char)
                --draw.SimpleText(tbl.char, "OpenComputersFont", (j-1)*8, (i-1)*16, getColor(tbl.fg))
            end
        end
    end

    
    --draw.SimpleText(width, "OpenComputersFont", 0, 0, Color(255, 255, 255))
    --draw.SimpleText(height, "OpenComputersFont", 0, 16, Color(255, 255, 255))
end)
]]