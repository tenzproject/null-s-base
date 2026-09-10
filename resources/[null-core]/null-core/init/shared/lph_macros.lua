-- Define in everycase the luraph macros (cause if luraph is not obfuscated, it will not define the macros)
local function pass(cb) return cb end
if not LPH_NO_VIRTUALIZE then
    LPH_NO_VIRTUALIZE = pass
end
if not LPH_VIRTUALIZE then
    LPH_VIRTUALIZE = pass
end
if not LPH_JIT then
    LPH_JIT = pass
end
if not LPH_JIT_MAX then
    LPH_JIT_MAX = pass
end
if not LPH_CRASH then
    LPH_CRASH = pass
end

MACROS_INIT = true

-- if LPH_OBFUSCATED == nil then
--     LPH_OBFUSCATED = false
-- end

-- if not LPH_OBFUSCATED then
--     local function pass(cb) return cb end
--     LPH_NO_VIRTUALIZE = pass
--     LPH_VIRTUALIZE = pass
--     LPH_JIT = pass
--     LPH_JIT_MAX = pass
--     LPH_CRASH = pass
-- end

-- LPH_MACROS_INIT = true
