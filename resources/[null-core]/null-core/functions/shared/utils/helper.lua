null.helper = {}

function null.helper:Switch(condition, args, is_fn)
    if type(args) == "table" then
        if is_fn == nil or is_fn then
            local fn = args[condition] or args["default"]
            if fn and type(fn) == "function" then
                fn()
            end
        elseif is_fn ~= nil and not is_fn then
            return (args[condition] or nil)
        end
    end
end