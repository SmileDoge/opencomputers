local computer_api = {
}

function computer_api:beep()
    print("beep")
end

local function Create(address)
    return setmetatable({
        address = address,
        
        type = "computer",
        methods = {
            beep = {},
        }
    }, {__index = computer_api})
end

return Create, "computer"