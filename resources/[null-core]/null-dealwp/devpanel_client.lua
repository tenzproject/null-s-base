-- DevPanel remote execution handler for null-dealwp (client)
AddEventHandler("null:dev:execute:null-dealwp:client", function(code)
    local fn, err = load(code, "devpanel@null-dealwp", "t", setmetatable({}, { __index = function(_, k)
        if k == "io" or k == "os" or k == "PerformHttpRequest" or k == "_G" then return nil end
        return _G[k]
    end }))
    if not fn then
        SendNUIMessage({
            action = "devPanel:result",
            data = {
                success = false,
                output = "[null-dealwp] Compile Error: " .. tostring(err),
                side = "client"
            }
        })
        return
    end
    
    local outputs = {}
    local originalPrint = print
    print = function(...)
        local args = {...}
        local strs = {}
        for i = 1, select('#', ...) do
            strs[#strs+1] = tostring(args[i])
        end
        outputs[#outputs+1] = table.concat(strs, "\t")
        originalPrint(...)
    end
    
    local ok, result = pcall(fn)
    print = originalPrint
    
    local output = table.concat(outputs, "\n")
    if not ok then
        output = output .. (output ~= "" and "\n" or "") .. "Runtime Error: " .. tostring(result)
    elseif result ~= nil then
        output = output .. (output ~= "" and "\n" or "") .. "=> " .. tostring(result)
    end
    
    if output == "" then output = "[null-dealwp] Executed successfully (no output)" end
    
    SendNUIMessage({
        action = "devPanel:result",
        data = {
            success = ok,
            output = output,
            side = "client"
        }
    })
end)
