local eeprom_api = {
}

function eeprom_api:getLabel()
    return self.label
end

function eeprom_api:setLabel(label)
    if self.readonly then
        return nil, "storage is readonly"
    end
    if label == nil then label = "EEPROM" end
    self.label = label
    return label
end

function eeprom_api:getChecksum()
    return string.format("%08x", tonumber(util.CRC()))
end

function eeprom_api:setData(data)
    self.data = data
end

function eeprom_api:getData()
    return self.data
end

function eeprom_api:set(code)
    if self.readonly then
        return nil, "storage is readonly"
    end
    if code == nil then code = "" end
    file.Write(self.path, code)
    self.code = code
end

function eeprom_api:get()
    return self.code
end

function eeprom_api:makeReadonly()
    if self.readonly then
        return nil, "storage is readonly"
    end
    self.readonly = true
end

local function Create(address, path, label, readonly)
    local tbl = setmetatable({
        address = address or OpenComputers.Component.GenUUID(),
        path = path,
        code = "",
        data = "",
        label = label,
        readonly = readonly,

        type = "eeprom",
        methods = {
            setData = {},
            getData = {direct = true},
            getLabel = {direct = true},
            setLabel = {},
            getChecksum = {direct = true},
            set = {},
            get = {direct = true},
            makeReadonly = {direct = true,}
        }
    }, {__index = eeprom_api})
    tbl.code = file.Read(path, "DATA")
    return tbl
end

return Create, "eeprom"