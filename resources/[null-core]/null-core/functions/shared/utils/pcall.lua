null.fct.safe.wait = function(func, timeout)
    if timeout == nil then timeout = 10 end
    local success, result, error = false, nil, nil
    while not success and timeout > 0 do 
        success, result, error = pcall(func)
        if success then break end
        timeout = timeout - 1
        Wait(100)
    end
    return success, result, error
end