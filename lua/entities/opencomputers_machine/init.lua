include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

function ENT:Initialize()
    self:SetModel("models/props_c17/consolebox01a.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
 
    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end

	self.TPS = 30
	self.Time = CurTime()

	self:InitEmulator()
	self:Register()
	self:InitComponents()
	self:StartMachine()
end

local function load(code, name, mode, env)
    local func = CompileString(code, name, true)
	if type(func) == "string" then
		error(func)
	end
    if env then
        func = setfenv(func, env)
    end
    return func
end

function ENT:InitEmulator()
	self.machine = {
		starttime = SysTime(),
		deadline = SysTime(),
		signals = {},
		totalMemory = 1*1024*1024*1024*1024,
		insynccall = false,
		address = OpenComputers.Component.GenUUID(),
		boot_address = "",
		components = {}
	}

	local env = {
		_VERSION = "Lua 5.2",
		assert = assert,
		error = error,
		getmetatable = getmetatable,
		ipairs = ipairs,
		load = load,
		next = next,
		pairs = pairs,
		pcall = pcall,
		rawget = rawget,
		rawset = rawset,
		rawequal = rawequal,
		select = select,
		setmetatable = setmetatable,
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		xpcall = xpcall,
		bit32 = {
			arshift = bit.arshift,
			band = bit.band,
			bnot = bit.bnot,
			bor = bit.bor,
			btest = function () end, -- todo
			bxor = bit.bxor,
			extract = function () end, -- todo
			lrotate = bit.rol,
			lshift = bit.lshift,
			replace = function () end, -- todo
			rrotate = bit.ror,
			rshift = bit.rshift
		},
		coroutine = {
			create = coroutine.create,
			resume = coroutine.resume,
			running = coroutine.running,
			status = coroutine.status,
			wrap = coroutine.wrap,
			yield = coroutine.yield,
		},
		debug = {
			getinfo = debug.getinfo,
			traceback = debug.traceback,
			getlocal = debug.getlocal,
			sethook = debug.sethook,
			getupvalue = debug.getupvalue,
		},
		math = {
			abs = math.abs,
			acos = math.acos,
			asin = math.asin,
			atan = math.atan,
			atan2 = math.atan2,
			ceil = math.ceil,
			cos = math.cos,
			cosh = math.cosh,
			deg = math.deg,
			exp = math.exp,
			floor = math.floor,
			fmod = math.fmod,
			frexp = math.frexp,
			huge = (1/0),
			ldexp = math.ldexp,
			log = math.log,
			max = math.max,
			min = math.min,
			modf = math.modf,
			pi = (3.14159265359),
			pow = math.pow,
			rad = math.rad,
			random = math.random,
			randomseed = function () end,
			sin = math.sin,
			sinh = math.sinh,
			sqrt = math.sqrt,
			tan = math.tan,
			tanh = math.tanh
		},
		os = {
			clock = os.clock,
			date = os.date,
			difftime = os.difftime,
			time = os.time,
		},
		string = {
			byte = string.byte,
			char = string.char,
			dump = string.dump,
			find = string.find,
			format = string.format,
			gmatch = string.gmatch,
			gsub = string.gsub,
			len = string.len,
			lower = string.lower,
			match = string.match,
			rep = string.rep,
			reverse = string.reverse,
			sub = string.sub,
			upper = string.upper,
		},
		table = {
			concat = table.concat,
			insert = table.insert,
			pack = function (...) return {...} end,
			remove = table.remove,
			sort = table.sort,
			unpack = table.unpack,
			pack = table.pack,
		},
		computer = {
			realTime = function() return SysTime() end,
			uptime = function() return SysTime() - self.machine.starttime end,
			address = function() return self.machine.address end,
			freeMemory = function() return self.machine.totalMemory end,
			totalMemory = function() return self.machine.totalMemory end,
			pushSignal = function(name, ...)
				local signalWhitelist={["nil"]=true,boolean=true,string=true,number=true}

				local signal = {n = select("#", ...) + 1, name, ... }
				for i = 2, signal.n do
					if not signalWhitelist[type(signal[i])] then
						signal[i] = nil
					end
				end
				table.insert(self.machine.signals, signal)
			end,
			tmpAddress = function() return end,
			beep = function() end
		},
		component = OpenComputers.Component.GenENV(self.machine),
		system = {
			allowBytecode = function() return false end,
			allowGC = function() return true end,
			timeout = function() return 5 end,
		},
		unicode = {},
		print = print,
		PrintTable = PrintTable,
	}

	function env.unicode.char(...)
		local args = table.pack(...)
		for i = 1, args.n do
			args[i] = args[i]%0x10000
		end
		return utf8.char(table.unpack(args))
	end
	function env.unicode.charWidth(ch)
		return 1 -- todo
	end
	function env.unicode.isWide(ch)
		return false -- todo
	end
	function env.unicode.len(str, st, en)
		return utf8.len(str, st, en)
	end
	function env.unicode.lower(str)
		return str -- todo
	end
	function env.unicode.upper(str)
		return str -- todo
	end
	function env.unicode.reverse(str)
		local final = ""
		for _, v in utf8.codes(str) do
			final = utf8.char(v) .. final
		end
		return final
	end
	function env.unicode.sub(str, st, en)
		return utf8.sub(str, st, en)
	end
	function env.unicode.wlen(str)
		return utf8.len(str)
	end
	function env.unicode.wtrunc(str, count)
		if count == math.huge then
			count = 0
		end
		local width = 0
		local pos = 0
		local len = utf8.len(str)
		while (width < count) do
			pos = pos + 1
			if pos > len then
				error("String index out of range", 0)
			end
			width = width + 1
		end
		return utf8.sub(str, 1, math.max(pos-1,0))
	end
	
	self.env = env
end

function ENT:InitComponents()
	local EEPROM_const = include("opencomputers/components/eeprom.lua")
	local FILESYS_const = include("opencomputers/components/filesystem.lua")
	local COMPUTER_const = include("opencomputers/components/computer.lua")
	local SCREEN_const = include("opencomputers/components/screen.lua")
	local GPU_const = include("opencomputers/components/gpu.lua")
	local KEYBOARD_const = include("opencomputers/components/keyboard.lua")

	local eeprom = EEPROM_const(nil, "opencomputers/eeprom.txt", "EEPROM", true)
	local filesys = FILESYS_const(nil, "opencomputers/loot/openos", "GMOD", true)
	local computer = COMPUTER_const(self.machine.address)
	local screen = SCREEN_const(nil, 80, 25, 3, self.machine.address)
	local gpu = GPU_const(nil, 80, 25, 3, self.machine.address)
	local keyboard = KEYBOARD_const(nil, self.machine.address)

	self:ConnectComponent(computer)
	self:ConnectComponent(eeprom)
	self:ConnectComponent(filesys)
	self:ConnectComponent(screen)
	self:ConnectComponent(gpu)
	self:ConnectComponent(keyboard)
end

function ENT:StartMachine()
    local fn = CompileFile("static/machine.lua")
    
    fn = setfenv(fn, self.env)
    
    self.machine.thread = coroutine.create(fn)
    local results = { coroutine.resume(self.machine.thread) }
    print("Machine.lua boot...")
end

function ENT:ResumeMachine(...)
	local machine = self.machine
	if machine.thread == nil then return end
	if coroutine.status(machine.thread) ~= "dead" then
		print("resume",...)
		local results = table.pack(coroutine.resume(machine.thread, ...))
		print("yield",table.unpack(results))
		if coroutine.status(machine.thread) ~= "dead" then
			if type(results[2]) == "function" then
				self:ResumeMachine(results[2]())
				--machine.syncfunc = results[2]
			elseif type(results[2]) == "boolean" then
				if results[2] then
					self:StartMachine()
				else
					error("Machine power off",0)
				end
			elseif type(results[2]) == "number" then
				machine.deadline = SysTime() + results[2]
			end
		else
			if type(results[2]) ~= "boolean" or (type(results[3]) ~= "string" and results[3] ~= nil) then
				error("Kernel returned unexpected results.", 0)
			elseif results[2] then
				error("Kernel stopped unexpectedly", 0)
			else
				error(results[3], 0)
			end
		end
	end
end

local maxCallBudget = (1.5 + 1.5 + 1.5) / 3

function ENT:Think()
	local time = self.Time
	local tps = self.TPS
	local machine = self.machine

	if CurTime() > time+(1/tps) then
        machine.callBudget = maxCallBudget
        if machine.syncfunc then
            local func = machine.syncfunc
            machine.syncfunc = nil
            machine.insynccall = true
            local result = func() -- should be a table
            machine.insynccall = false
            self:ResumeMachine(result)
        elseif #machine.signals > 0 then
            signal = machine.signals[1]
            table.remove(machine.signals, 1)
            self:ResumeMachine(table.unpack(signal, 1, signal.n or #signal))
        elseif SysTime() >= machine.deadline then
            self:ResumeMachine()
        end
    
        self.Time = CurTime()
    end
end

function ENT:Register()
	OpenComputers.Machines[self.machine.address] = self
end
function ENT:Unregister()
	if OpenComputers.Machines[self.machine.address] then
		OpenComputers.Machines[self.machine.address] = nil
	end
end
function ENT:OnRemove()
	self.machine.thread = nil

	self:Unregister()
end

function ENT:ConnectComponent(obj)
    local addr = obj.address

    for k, v in pairs(obj.methods) do
        v.direct = v.direct or false
        v.getter = v.getter or false
        v.setter = v.setter or false
        v.limit = v.limit or math.huge
    end

	obj.machine_address = self.machine.address

    self.machine.components[addr] = obj
end
function ENT:DisconnectComponent(address)
    if self.machine.components[address] then
        self.machine.components[address] = nil
    end

    self.machine.components[addr] = obj
end
function ENT:InvokeComponent(address, method, ...)
	if self.machine.components[address] ~= nil then
		local meth = self.machine.components[address][method]
		if meth == nil then
			error("no such method", 2)
		end
		return meth(self.machine.components[address], ...)
	end
end
function ENT:ListComponent(filter, exact)
	local tbl = {}
	local data = {}
	for k, v in pairs(self.machine.components) do
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
function ENT:ExistsComponent(address)
	if self.machine.components[address] ~= nil then
		return self.machine.components[address].type
	end
end