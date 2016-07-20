function CDFrames_Module()
    local data, is_public, is_declared, public_interface, private_interface, public, private = {}, {}, {}, {}, {}, {}, {}
    setmetatable(public_interface, {
        __newindex = function(_, key)
            error('Illegal write of attribute "'..key..'"', 2)
        end,
        __index = function(_, key)
            if not is_public[key] then
                error('Access of undeclared attribute "'..key..'"', 2)
            end
            if is_public[key] then
                return data[key]
            end
        end,
        __call = function(_, key)
            return is_public[key]
        end
    })
    setmetatable(private_interface, {
        __newindex = function(_, key, value)
            if not is_declared[key] then
                error('Assignment of undeclared attribute "'..key..'"', 2)
            end
            data[key] = value
        end,
        __index = function(_, key)
            if not is_declared[key] then
                error('Access of undeclared attribute "'..key..'"', 2)
            end
            return data[key]
        end,
        __call = function(_, key)
            return is_declared[key]
        end
    })
    setmetatable(public, {
        __newindex = function(_, key, value)
            if is_declared[key] then
                error('Multiple declarations of "'..key..'"', 2)
            end
            data[key] = value
            is_public[key] = true
            is_declared[key] = true
        end,
        __index = function(_, key)
            error('Illegal read of attribute "'..key..'"', 2)
        end,
    })
    setmetatable(private, {
        __newindex = function(_, key, value)
            if is_declared[key] then
                error('Multiple declarations of "'..key..'"', 2)
            end
            data[key] = value
            is_declared[key] = true
        end,
        __index = function(_, key)
            error('Illegal read of attribute "'..key..'"', 2)
        end,
    })
    return { public_interface, private_interface, public, private }
end