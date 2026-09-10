local debug_getinfo = debug.getinfo

function noop() end

lib = setmetatable({
    -- null-deps bundle : ox_lib vit dans la ressource null-deps sous modules/ox_lib/.
    name = 'null-deps',
    context = IsDuplicityVersion() and 'server' or 'client',
}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        -- null-deps bundle : les sources internes ox_lib sont sous modules/ox_lib/resource/.
        if debug_getinfo(2, 'S').short_src:find('modules/ox_lib/resource') then
            exports(key, fn)
        end
    end,

    __index = function(self, key)
        -- null-deps bundle : imports vivent sous modules/ox_lib/imports/
        local dir = ('modules/ox_lib/imports/%s'):format(key)
        local chunk = LoadResourceFile(self.name, ('%s/%s.lua'):format(dir, self.context))
        local shared = LoadResourceFile(self.name, ('%s/shared.lua'):format(dir))

        if shared then
            chunk = (chunk and ('%s\n%s'):format(shared, chunk)) or shared
        end

        if chunk then
            local fn, err = load(chunk, ('@@ox_lib/%s/%s.lua'):format(key, self.context))

            if not fn or err then
                return error(('\n^1Error importing module (%s): %s^0'):format(dir, err), 3)
            end

            rawset(self, key, fn() or noop)

            return self[key]
        end
    end
})

cache = {
    resource = lib.name,
    game = GetGameName(),
}

-- null-deps bundle : UI ox_lib vit sous modules/ox_lib/web/build/.
if not LoadResourceFile(lib.name, 'modules/ox_lib/web/build/index.html') then
    local err = '^1Unable to load UI. Build ox_lib or download the latest release.\n	^3https://github.com/overextended/ox_lib/releases/latest/download/ox_lib.zip^0'
    function lib.hasLoaded() return err end

    error(err)
end

function lib.hasLoaded() return true end
