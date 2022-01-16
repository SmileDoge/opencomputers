OpenComputers = OpenComputers or {}

local width = 80
local height = 25

OpenComputers.Buffer = OpenComputers.Buffer or {}

local tex = GetRenderTarget("OpenComputers1", 2048, 1024)
local mat = CreateMaterial("OpenComputers1", "UnlitGeneric", {
    ["$basetexture"] = tex:GetName()
})

OpenComputers.Material = mat

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

    render.Clear(0,0,0,255)

    cam.End2D()
    render.PopRenderTarget()
end
local function initrender()
    render.PushRenderTarget(tex, 0, 0, 2048, 1024)
    cam.Start2D()
end
local function endrender()
    cam.End2D()
    render.PopRenderTarget()
end
local function drawChar(x, y, fg, bg, char)

    surface.SetDrawColor(getColor(bg))
    surface.DrawRect(x*8, y*16, 8, 16)
    
    surface.SetTextColor(getColor(fg))
    surface.SetTextPos(x*8, y*16)
    surface.DrawText(char or "")

end

local function setsize(w, h)
    local tbl = {}

    surface.SetFont("OpenComputersFont")
    for i = 1, h do
        tbl[i] = {}
        for j = 1, w do
            tbl[i][j] = {char = "", fg = 0xffffff, bg = 0x000000}
        end
    end

    OpenComputers.Buffer = tbl
end

local function readheader()
    return net.ReadUInt(8), net.ReadString(), net.ReadString()
end

net.Receive("opencomputers-send-screen-data", function()
    local typ, machine_address, address = readheader()

    if typ == 1 then
        local x = net.ReadInt(16)
        local y = net.ReadInt(16)
        local c = net.ReadString()
        local fg = net.ReadUInt(32)
        local bg = net.ReadUInt(32)

        surface.SetFont("OpenComputersFont")
        OpenComputers.Buffer[y][x] = {char = c, fg = fg, bg = bg}
        initrender()
        drawChar(x-1,y-1,fg,bg,c)
        endrender()
    elseif typ == 2 then
        local x = net.ReadInt(16)
        local y = net.ReadInt(16)
        local text = net.ReadString()
        print(x, y, text)
        local vertical = net.ReadBool()
        local fg = net.ReadUInt(32)
        local bg = net.ReadUInt(32)

        surface.SetFont("OpenComputersFont")
        initrender()
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
        endrender()
    elseif typ == 3 then
        local w = net.ReadInt(16)
        local h = net.ReadInt(16)
        local tier = net.ReadInt(16)
        setsize(w, h)
        prepare()
    elseif typ == 4 then
    elseif typ == 5 then
        local x1 = net.ReadInt(16)
        local y1 = net.ReadInt(16)
        local x2 = net.ReadInt(16)
        local y2 = net.ReadInt(16)
        local ch = net.ReadString()
        local fg = net.ReadUInt(32)
        local bg = net.ReadUInt(32)

        initrender()
        surface.SetFont("OpenComputersFont")
        for y = y1,y2 do
            for x = x1,x2 do
                OpenComputers.Buffer[y][x] = {char = ch, fg = fg, bg = bg}
                drawChar(x-1,y-1,fg,bg,char)
            end
        end
        endrender()
    end
end)

local font = surface.CreateFont("OpenComputersFont", {
    font = "unscii",
    extended = true,
    size = 16,
    weight = 0,
    antialias = false,
})

hook.Remove("HUDPaint", "RenderScreen")

concommand.Add("opencomputers_screen", function()
    local width = 80*8
    local height = 25*16

    local DFrame = vgui.Create("DFrame")
    DFrame:SetSize(width+10, height+34)
    DFrame:SetTitle("OpenComputers Screen")
    DFrame:Center()
    DFrame:MakePopup()

    local panel = vgui.Create("DPanel", DFrame)
    panel:Dock(FILL)

    function panel:Paint( w, h )
        surface.SetDrawColor(color_black)
        surface.DrawRect(0, 0, w, h)

        render.PushFilterMag(1)
        render.PushFilterMin(1)

        surface.SetDrawColor(color_white)
        surface.SetMaterial(OpenComputers.Material)
        surface.DrawTexturedRectUV(0, 0, w, h, 0, 0, w/2048, h/1024)

        render.PopFilterMag()
        render.PopFilterMin()
    end
end)
--[[
hook.Add("HUDPaint", "RenderScreen", function()


    
    --draw.SimpleText(width, "OpenComputersFont", 0, 0, Color(255, 255, 255))
    --draw.SimpleText(height, "OpenComputersFont", 0, 16, Color(255, 255, 255))
end)
]]