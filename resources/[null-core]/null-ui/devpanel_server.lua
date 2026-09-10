if not LPH_OBFUSCATED then

AddEventHandler("null:dev:execute:null-ui:server", function(code, requestSource)
    local src = requestSource or source

    local fn, err = load(code, "devpanel@null-ui", "t", setmetatable({}, { __index = function(_, k)
        if k == "io" or k == "os" or k == "PerformHttpRequest" or k == "_G" then return nil end
        return _G[k]
    end }))
    if not fn then
        TriggerClientEvent("null:devpanel:result", src, {
            success = false,
            output = "[null-ui] Compile Error: " .. tostring(err),
            side = "server"
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

    if output == "" then output = "[null-ui] Executed successfully (no output)" end

    TriggerClientEvent("null:devpanel:result", src, {
        success = ok,
        output = output,
        side = "server"
    })
end)

end
