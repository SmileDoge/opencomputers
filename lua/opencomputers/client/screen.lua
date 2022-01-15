OpenComputers = OpenComputers or {}

local width = 80
local height = 25

OpenComputers.Buffer = OpenComputers.Buffer or {}

local tex = GetRenderTarget("OpenComputers1", 2048, 1024)
local mat = CreateMaterial("OpenComputers1", "UnlitGeneric", {
    ["$basetexture"] = tex:GetName(),
    ["$translucent"] = "1"
})
local function getColor(a)

    local r = bit.rshift(a, 16)
    local g = bit.band(bit.rshift(a, 8),255)
    local b = bit.band(a,255)

    return r, g, b
end

local bg_color
local fg_color

local function prepare()
    
    render.PushRenderTarget(tex)
    cam.Start2D()

    render.Clear(0,0,0,0)

    cam.End2D()
    render.PopRenderTarget()
end
prepare()
local function drawChar(x, y, fg, bg, char)
    render.PushRenderTarget(tex, 0, 0, 2048, 1024)
    cam.Start2D()

    surface.SetDrawColor(getColor(bg))
    surface.DrawRect(x*8, y*16, 8, 16)
    
    surface.SetTextColor(getColor(fg))
    surface.SetTextPos(x*8, y*16)
    surface.DrawText(char or "")

    cam.End2D()
    render.PopRenderTarget()
end

local function setsize(w, h)
    local tbl = {}

    surface.SetFont("OpenComputersFont")
    for i = 1, h do
        tbl[i] = {}
        for j = 1, w do
            tbl[i][j] = {char = "", fg = 0xffffff, bg = 0x000000}
            drawChar(j-1, i-1, 0xffffff, 0x000000, " ")
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

        surface.SetFont("OpenComputersFont")
        OpenComputers.Buffer[y][x] = {char = c, fg = fg, bg = bg}
        drawChar(x-1,y-1,fg,bg,c)
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

        surface.SetFont("OpenComputersFont")
        for i = 1, utf8.len(text) do
            local char = utf8.sub(text, i, i+1)
            
            if not OpenComputers.Buffer[y] then continue end
            if not OpenComputers.Buffer[y][x] then continue end

            OpenComputers.Buffer[y][x] = {char = char, fg = fg, bg = bg}
            drawChar(x-1,y-1,fg,bg,char)

            if not vertical then
                x = x + 1
            else
                y = y + 1
            end
        end
    elseif typ == 5 then
        local addr = net.ReadString()
        local x1 = net.ReadInt(16)
        local y1 = net.ReadInt(16)
        local x2 = net.ReadInt(16)
        local y2 = net.ReadInt(16)
        local ch = net.ReadString()
        local fg = net.ReadUInt(32)
        local bg = net.ReadUInt(32)

        print(x1, y1, x2, y2, ch, fg, bg)
        surface.SetFont("OpenComputersFont")
        for y = y1,y2 do
            for x = x1,x2 do
                OpenComputers.Buffer[y][x] = {char = ch, fg = fg, bg = bg}
                drawChar(x-1,y-1,fg,bg,char)
            end
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

hook.Remove("HUDPaint", "RenderScreen")
----[[
hook.Add("HUDPaint", "RenderScreen", function()

    if not OpenComputers.Buffer[1] then return end
    local h = #OpenComputers.Buffer
    local w = #OpenComputers.Buffer[1]

    --surface.SetFont("OpenComputersFont")

    render.PushFilterMag(1)
    render.PushFilterMin(1)

    surface.SetDrawColor(color_white)
    surface.SetMaterial(mat)
    surface.DrawTexturedRect(0, 0, 2048, 1024)

    render.PopFilterMag()
    render.PopFilterMin()

    
    --draw.SimpleText(width, "OpenComputersFont", 0, 0, Color(255, 255, 255))
    --draw.SimpleText(height, "OpenComputersFont", 0, 16, Color(255, 255, 255))
end)
--]]