local keyboard_api = {}

function Create(address)
    return setmetatable({
        address = address or OpenComputers.Component.GenUUID(),

        type = "keyboard",
        methods = {
        }
    }, {__index = keyboard_api})
end

return Create