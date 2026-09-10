null.fct.input = LPH_NO_VIRTUALIZE(function(TextEntry, isAdvanced, table, button)
    local input = nil
    local resourceName = nil
    if type(isAdvanced) == "string" then
        resourceName = isAdvanced
    end

    if isAdvanced and table then
        -- Advanced input with multiple fields (ox_lib style)
        local inputData = {
            title = TextEntry,
            fields = table
        }
        if type(isAdvanced) == "table" then
            inputData.options = isAdvanced.options
            inputData.size = isAdvanced.size
        end
        input = exports['null-core']:Input(inputData, resourceName)
    else
        input = exports['null-core']:Input({
            title = TextEntry,
            fields = {
                {
                    type = "input",
                    label = TextEntry,
                    required = true
                }
            }
        }, resourceName)
    end

    -- Handle nil/cancelled input
    if input == nil then
        return nil
    end

    -- Handle boolean type
    if type(input) == "boolean" then
        return input
    end

    -- Handle table results
    if type(input) == "table" then
        if button and input[1] ~= nil then
            return input[1]
        end
        
        if input[1] == nil then 
            return nil 
        end
        
        if type(input[1]) == "string" then
            if #input[1] == 0 or input[1] == "" then
                return nil
            end
        end
        
        return input[1]
    end

    if type(input) == "string" then
        local success, result = pcall(function()
            inputNumber = tonumber(input)
            return inputNumber
        end)
        if success and result ~= nil then
            input = result
        end
    end

    return input
end)

null.fct.input2 = LPH_NO_VIRTUALIZE(function(TextEntry, isAdvanced, table, button)
    local input = nil
    local resourceName = nil
    if type(isAdvanced) == "string" then
        resourceName = isAdvanced
    end
    
    if isAdvanced and table then
        -- Advanced input with multiple fields
        input = exports['null-core']:Input({
            title = TextEntry,
            fields = table
        }, resourceName)
    else
        -- Simple input
        input = exports['null-core']:Input({
            title = TextEntry,
            fields = {
                {
                    type = "input",
                    label = TextEntry,
                    required = true
                }
            }
        }, resourceName)
    end

    -- Handle nil/cancelled input
    if input == nil then
        return nil
    end

    -- Handle boolean type
    if type(input) == "boolean" then
        return input
    end

    -- Handle table results
    if type(input) == "table" then
        if button and input[1] ~= nil then
            return input[1]
        end
        
        if input[1] == nil then 
            return nil 
        end
        
        if type(input[1]) == "string" then
            if #input[1] == 0 or input[1] == "" then
                return nil
            end
        end
        
        -- Return full array for advanced inputs
        return input
    end

    return input
end)

null.fct.smallInput = LPH_NO_VIRTUALIZE(function(Title, Description)
    local input = exports['null-core']:Input({
        title = Title,
        fields = {
            {
                type = "input",
                label = Title,
                description = Description,
                required = true
            }
        }
    })

    -- Handle nil/cancelled input
    if input == nil then
        return nil
    end

    -- Handle boolean type
    if type(input) == "boolean" then
        return input
    end

    -- Handle table results
    if type(input) == "table" then
        if button and input[1] ~= nil then
            return input[1]
        end
        
        if input[1] == nil then 
            return nil 
        end
        
        if type(input[1]) == "string" then
            if #input[1] == 0 or input[1] == "" then
                return nil
            end
        end
        
        return input[1]
    end

    if type(input) == "string" then
        local success, result = pcall(function()
            inputNumber = tonumber(input)
            return inputNumber
        end)
        if success and result ~= nil then
            input = result
        end
    end

    return input
end)

null.fct.inputCb = LPH_NO_VIRTUALIZE(function(title, cb)
    local input = exports['null-core']:Input({
        title = title,
        fields = {
            {
                type = "input",
                label = title,
                required = true
            }
        }
    })
    
    if input == nil then
        cb(nil)
        return
    end
    
    if type(input) == "table" and input[1] ~= nil then
        if type(input[1]) == "string" and (#input[1] == 0 or input[1] == "") then
            cb(nil)
        else
            cb(input[1])
        end
    else
        cb(input)
    end
end)