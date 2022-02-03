OpenComputers = OpenComputers or {}

local width = 80
local height = 25

OpenComputers.Buffer = OpenComputers.Buffer or {}
OpenComputers.Addresses = OpenComputers.Addresses or {}


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

    OpenComputers.Addresses = {
        machine_address = machine_address,
        address = address,
    }

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

concommand.Add("opencomputers_test",function()
    
    local DFrame = vgui.Create("DFrame")
    DFrame:SetSize(800, 600)
    DFrame:SetTitle("OpenComputers Screen")
    DFrame:Center()
    DFrame:MakePopup()
    DFrame:SetAllowNonAsciiCharacters( true )

    local text = vgui.Create("RichText", DFrame)
    text:SetSize(100, 100)
    text:SetPos(200, 200)

    function text:OneKeyCodeTyped(code)
        print(code)
    end
end)

--[[
    
local function sendheader(typ, tbl)
    net.WriteUInt(typ, 8)
    net.WriteString(tbl.machine_address)
    net.WriteString(tbl.address)
end
--1
function screen_api:sendChar(x, y, char, fg, bg)
    net.Start("opencomputers-send-screen-data")
        sendheader(1, self)
        net.WriteInt(x, 16)
        net.WriteInt(y, 16)
        net.WriteString(char)
        net.WriteUInt(fg, 32)
        net.WriteUInt(bg, 32)
    net.Broadcast()
end
]]

local function sendkeyboard(code, char, down)
    local machine_addr = OpenComputers.Addresses["machine_address"]
    local addr = OpenComputers.Addresses["address"]

    net.Start("opencomputers-send-screen-data")
        net.WriteUInt(101, 8)
        net.WriteString(machine_addr)
        net.WriteString(addr)
        net.WriteBool(down) -- true = key_down, false = key_up
        net.WriteUInt(code, 32)
        net.WriteUInt(char, 32)
    net.SendToServer()
end

concommand.Add("opencomputers_screen", function()
    local width = 80*8
    local height = 25*16

    local DFrame = vgui.Create("DFrame")
    DFrame:SetSize(width+10, height+34)
    DFrame:SetTitle("OpenComputers Screen")
    DFrame:Center()
    DFrame:MakePopup()
    DFrame:SetAllowNonAsciiCharacters( true )

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

    function panel:OnMousePressed(code)
        local mx, my = input.GetCursorPos()
        local px, py = panel:LocalToScreen()
        local cx, cy = mx-px, my-py
        local x, y = math.floor(cx/8)+1, math.floor(cy/16)+1 
        print(x, y)
    end

    local key_map_lwjgl = {
        [KEY_NONE] = 0,

        [KEY_F1] = 59,
        [KEY_F2] = 60,
        [KEY_F3] = 61,
        [KEY_F4] = 62,
        [KEY_F5] = 63,
        [KEY_F6] = 64,
        [KEY_F7] = 65,
        [KEY_F8] = 66,
        [KEY_F9] = 67,
        [KEY_F10] = 68,
        [KEY_F11] = 87,
        [KEY_F11] = 88,

        [KEY_BACKQUOTE] = 41,

        [KEY_1] = 2,
        [KEY_2] = 3,
        [KEY_3] = 4,
        [KEY_4] = 5,
        [KEY_5] = 6,
        [KEY_6] = 7,
        [KEY_7] = 8,
        [KEY_8] = 9,
        [KEY_9] = 10,
        [KEY_0] = 11,
        [KEY_MINUS] = 12,
        [KEY_EQUAL] = 13,

        [KEY_BACKSLASH] = 0, -- ???

        [KEY_BACKSPACE] = 14,

        [KEY_TAB] = 15,

        [KEY_Q] = 16,
        [KEY_W] = 17,
        [KEY_E] = 18,
        [KEY_R] = 19,
        [KEY_T] = 20,
        [KEY_Y] = 21,
        [KEY_U] = 22,
        [KEY_I] = 23,
        [KEY_O] = 24,
        [KEY_P] = 25,

        [KEY_LBRACKET] = 26,
        [KEY_RBRACKET] = 27,
        [KEY_ENTER] = 28,

        [KEY_CAPSLOCK] = 58,

        [KEY_A] = 30,
        [KEY_S] = 31,
        [KEY_D] = 32,
        [KEY_F] = 33,
        [KEY_G] = 34,
        [KEY_H] = 35,
        [KEY_J] = 36,
        [KEY_K] = 37,
        [KEY_L] = 38,
        [KEY_SEMICOLON] = 39,
        [KEY_APOSTROPHE] = 40,

        [KEY_LSHIFT] = 42,

        [KEY_Z] = 44,
        [KEY_X] = 45,
        [KEY_C] = 46,
        [KEY_V] = 47,
        [KEY_B] = 48,
        [KEY_N] = 49,
        [KEY_M] = 50,
        [KEY_COMMA] = 51,
        [KEY_PERIOD] = 52,
        [KEY_SLASH] = 53,

        [KEY_LCONTROL] = 29,
        [KEY_LWIN] = 0, -- ???
        [KEY_LALT] = 56,
        [KEY_SPACE] = 57,
        [KEY_RALT] = 184,
        [KEY_RWIN] = 0, -- ???
        [KEY_APP] = 0, -- ???
        [KEY_RCONTROL] = 157,

        [KEY_SCROLLLOCK] = 70,
        [KEY_BREAK] = 197,

        [KEY_INSERT] = 210,
        [KEY_HOME] = 199,
        [KEY_PAGEUP] = 201,

        [KEY_DELETE] = 211,
        [KEY_END] = 207,
        [KEY_PAGEDOWN] = 209,

        [KEY_UP] = 200,
        [KEY_LEFT] = 203,
        [KEY_DOWN] = 208,
        [KEY_RIGHT] = 205,

        [KEY_NUMLOCK] = 69,

        [KEY_PAD_DIVIDE] = 181,
        [KEY_PAD_MULTIPLY] = 55,
        [KEY_PAD_MINUS] = 74,

        [KEY_PAD_7] = 71,
        [KEY_PAD_8] = 72,
        [KEY_PAD_9] = 73,

        [KEY_PAD_4] = 75,
        [KEY_PAD_5] = 76,
        [KEY_PAD_6] = 77,

        [KEY_PAD_1] = 79,
        [KEY_PAD_2] = 80,
        [KEY_PAD_3] = 81,

        [KEY_PAD_0] = 82,
        [KEY_PAD_DECIMAL] = 83,

        [KEY_PAD_PLUS] = 78,
        [KEY_PAD_ENTER] = 156,
    }

    local key_map_layout = {
        [KEY_NONE] = "",
        [KEY_A] = "a",
        [KEY_B] = "b",
        [KEY_C] = "c",
        [KEY_D] = "d",
        [KEY_E] = "e",
        [KEY_F] = "f",
        [KEY_G] = "g",
        [KEY_H] = "h",
        [KEY_I] = "i",
        [KEY_J] = "j",
        [KEY_K] = "k",
        [KEY_L] = "l",
        [KEY_M] = "m",
        [KEY_N] = "n",
        [KEY_P] = "p",
        [KEY_Q] = "q",
        [KEY_R] = "r",
        [KEY_S] = "s",
        [KEY_T] = "t",
        [KEY_U] = "u",
        [KEY_V] = "v",
        [KEY_W] = "w",
        [KEY_X] = "x",
        [KEY_Y] = "y",
        [KEY_Z] = "z",

        [KEY_SPACE] = " ",
        [KEY_1] = "1",
        [KEY_2] = "2",
        [KEY_3] = "3",
        [KEY_4] = "4",
        [KEY_5] = "5",
        [KEY_6] = "6",
        [KEY_7] = "7",
        [KEY_8] = "8",
        [KEY_9] = "9",
        [KEY_0] = "0",

        [KEY_ENTER] = "\n",
        [KEY_BACKSPACE] = 8,
        [KEY_TAB] = 8,
        [KEY_DELETE] = 127,

        [KEY_LBRACKET] = "[",
        [KEY_RBRACKET] = "]",
        [KEY_SEMICOLON] = ";",
        [KEY_APOSTROPHE] = "'",
        [KEY_BACKQUOTE] = "`",
        [KEY_COMMA] = ",",
        [KEY_PERIOD] = ".",
        [KEY_SLASH] = "/",
        [KEY_BACKSLASH] = "\\",
        [KEY_MINUS] = "-",
        [KEY_EQUAL] = "=",
    }

    local function tocodepoint(symbol)
        
        if not isstring(symbol) then return symbol end
        if symbol == "" then return 0 end

        return utf8.codepoint(symbol)
    end

    function DFrame:OnKeyCodePressed(code)
        if code == 104 then return end

        local char = tocodepoint(key_map_layout[code] or "")
        local code = key_map_lwjgl[code] or 0
        sendkeyboard(code, char, true)
    end

    function DFrame:OnKeyCodeReleased(code)
        if code == 104 then return end

        local char = tocodepoint(key_map_layout[code] or "")
        local code = key_map_lwjgl[code] or 0
        sendkeyboard(code, char, false)
    end
end)
--[[
hook.Add("HUDPaint", "RenderScreen", function()


    
    --draw.SimpleText(width, "OpenComputersFont", 0, 0, Color(255, 255, 255))
    --draw.SimpleText(height, "OpenComputersFont", 0, 16, Color(255, 255, 255))
end)
]]