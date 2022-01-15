local filesystem_api = {
    handles = {},
    handles_id = 0,
}
local function cleanPath(path)
	local path = path:gsub("\\", "/")

	local tPath = {}
	for part in path:gmatch("[^/]+") do
   		if part ~= "" and part ~= "." then
   			if part == ".." and #tPath > 0 and tPath[#tPath] ~= ".." then
   				table.remove(tPath)
   			else
   				table.insert(tPath, part)
   			end
   		end
	end
	if #tPath == 0 then
		return "."
	end
	return table.concat(tPath, "/")
end
function filesystem_api:read(handle, count)
    if self.handles[handle] then
        if self.handles[handle][2] ~= "r" then return nil, "bad file descriptor" end
        count = math.min(math.max(count, 0), 65536)
        local ret = self.handles[handle][1]:Read(count)
        return ret
    end
end
function filesystem_api:lastModified(path)
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
    return file.Time(self.directory .. "/" .. path) or 0
end
function filesystem_api:spaceUsed()
    return 0 // todo
end
function filesystem_api:rename(from, to)
    from = cleanPath(from)
    if from == ".." or from:sub(1,3) == "../" then
		return nil,"file not found"
	end
    to = cleanPath(to)
    if to == ".." or to:sub(1,3) == "../" then
		return nil,"file not found"
	end
	if self.readonly then
		return false
	end
    local status = file.Rename(self.directory .. "/" .. from, self.directory .. "/" .. to)
    if status then
        return true
    else
        return nil, "missing permissions"
    end
end
function filesystem_api:close(handle)
    if self.handles[handle] == nil then
        return nil, "bad file descriptor"
    end
    self.handles[handle][1]:Close()
    self.handles[handle] = nil
end
function filesystem_api:write(handle, value)
    if self.handles[handle] == nil or (self.handles[handle][2] ~= "w" and self.handles[handle][2] ~= "a") then
        return nil, "bad file descriptor"
    end
    self.handles[handle][1]:Write(value)
    return true
end
function filesystem_api:remove(path)
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
	if self.readonly then
		return false
	end
    file.Delete(directory .. "/" .. path)
    return true
end
function filesystem_api:seek(handle, whence, offset)
    if self.handles[handle] == nil then 
        return nil, "bad file descriptor"
    end
    self.handles[handle][1]:Seek(offset)
    return self.handles[handle][1]:Tell()
end
function filesystem_api:spaceTotal()
    return 1024*1024*10
end
function filesystem_api:getLabel()
    return self.label
end
function filesystem_api:setLabel(value)
    if self.readonly then
        return nil, "storage is readonly"
    end
    self.label = value
end
function filesystem_api:open(path, mode)
    if mode == nil then mode = "r" end
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil, "file not found"
	end
	if mode ~= "r" and mode ~= "rb" and mode ~= "w" and mode ~= "wb" and mode ~= "a" and mode ~= "ab" then
		error("unsupported mode", 0)
	end
    if (mode == "r" or mode == "rb") and not file.Exists(self.directory .. "/" .. path, "DATA") then
		return nil, "file not found"
	elseif not (mode == "r" or mode == "rb") and readonly then
		return nil, "filesystem is read only"
	end
    local handl = file.Open(self.directory .. "/" .. path, mode, "DATA")
    if handl == nil then
        return nil, "file open error"
    end
    self.handles[self.handles_id] = {handl,mode:sub(1,1)}
    self.handles_id = self.handles_id + 1
    return self.handles_id-1
end
function filesystem_api:exists(path)
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
    return file.Exists(self.directory .. "/" .. path, "DATA")
end
function filesystem_api:list(path)
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
    if not file.Exists(self.directory .. "/" .. path, "DATA") then
        return nil, "no such file or directory"
    elseif not file.IsDir(self.directory .. "/" .. path, "DATA") then
        local entry = (self.directory .. "/" .. path):match(".*/(.+)")
        return {entry}
    end
    local tbl = {}
    local files, dirs = file.Find(self.directory .. "/" .. path .. "/*", "DATA")
    for i = 1, #files do
        tbl[#tbl+1] = files[i]
    end
    for i = 1, #dirs do
        tbl[#tbl+1] = dirs[i] .. "/"
    end
    return tbl
end
function filesystem_api:isReadOnly()
    return self.readonly
end
function filesystem_api:makeDirectory(path)
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
    if file.Exists(self.directory .. "/" .. path, "DATA") or self.readonly then
        return false 
    end
    file.CreateDir(self.directory .. "/" .. path)
    return true
end
function filesystem_api:isDirectory(path)
    path = cleanPath(path)
	if path == ".." or path:sub(1,3) == "../" then
		return nil,"file not found"
	end
    return file.IsDir(self.directory .. "/" .. path, "GAME")
end
local function Create(address, directory, label, readonly)
    return setmetatable({
        address = address or OpenComputers.Component.GenUUID(),
        directory = directory,
        label = label,
        readonly = readonly,

        type = "filesystem",
        methods = {
            read = {direct = true, limit = 15},
            lastModified = {direct = true},
            spaceUsed = {direct = true},
            rename = {},
            close = {direct = true},
            write = {direct = true},
            remove = {direct = true},
            size = {direct = true},
            seek = {direct = true},
            spaceTotal = {direct = true},
            getLabel = {direct = true},
            setLabel = {},
            open = {direct = true, limit = 4},
            exists = {direct = true},
            list = {},
            isReadOnly = {direct = true},
            makeDirectory = {direct = true},
            isDirectory = {direct = true},
        }
    }, {__index = filesystem_api})
end

return Create, "filesystem"