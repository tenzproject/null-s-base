--[[
    Figlet - ASCII Art Text Generator
    Ported for Null Core
]]

local Figlet = {}

local deutsch = {196, 214, 220, 228, 246, 252, 223}
local fcharlist = {}
local magic, hardblank, charheight, maxlen, smush, cmtlines, ffright2left, smush2

local function readfontchar(fontfile, theord)
    local t = {}
    fcharlist[theord] = t

    for i = 1, charheight do
        local line = assert(fontfile:read("*l"), "Not enough character lines for character " .. theord)
        line = string.gsub(line, "%s+$", "") -- remove trailing spaces
        assert(line ~= "", "Unexpected empty line")

        -- find the last character (eg. @)
        local endchar = line:sub(-1) -- last character

        -- trim one or more of the last character from the end
        while line:sub(-1) == endchar do
            line = line:sub(1, #line - 1)
        end

        table.insert(t, line)
    end
end

--- Read a FIGlet font file
---@param filename string Path to the .flf font file
function Figlet.readfont(filename)
    local fontfile = assert(io.open(filename, "r"))

    fcharlist = {}

    -- header line
    local s = assert(fontfile:read("*l"), "Empty FIGlet file")

    -- eg.  flf2a$ 8 6          59     15     10        0             24463   153
    --      magic  charheight  maxlen  smush  cmtlines  ffright2left  smush2  ??

    -- configuration line
    magic, hardblank, charheight, maxlen, smush, cmtlines, ffright2left, smush2 = string.match(s,
        "^(flf2).(.) (%d+) %d+ (%d+) (%-?%d+) (%d+) ?(%d*) ?(%d*) ?(%-?%d*)")

    assert(magic, "Not a FIGlet 2 font file")

    -- convert to numbers
    charheight = tonumber(charheight)
    maxlen = tonumber(maxlen)
    smush = tonumber(smush)
    cmtlines = tonumber(cmtlines)

    -- sanity check
    if charheight < 1 then
        charheight = 1
    end

    -- skip comment lines
    for i = 1, cmtlines do
        assert(fontfile:read("*l"), "Not enough comment lines")
    end

    -- get characters space to tilde
    for theord = string.byte(' '), string.byte('~') do
        readfontchar(fontfile, theord)
    end

    -- get 7 German characters
    for theord = 1, 7 do
        readfontchar(fontfile, deutsch[theord])
    end

    -- get extra ones
    repeat
        local extra = fontfile:read("*l")
        if not extra then
            break
        end

        local negative, theord = string.match(extra, "^(%-?)0[xX](%x+)")
        if theord then
            theord = tonumber(theord, 16)
            if negative == "-" then
                theord = -theord
            end
        else
            theord = string.match(extra, "^%d+")
            if not theord then break end
            theord = tonumber(theord)
        end

        readfontchar(fontfile, theord)
    until false

    fontfile:close()

    -- remove leading/trailing spaces
    for k, v in pairs(fcharlist) do
        local leading_space = true
        local trailing_space = true
        
        for _, line in ipairs(v) do
            if line:sub(1, 1) ~= " " then
                leading_space = false
            end
            if line:sub(-1, -1) ~= " " then
                trailing_space = false
            end
        end

        for i, line in ipairs(v) do
            if leading_space then
                v[i] = line:sub(2)
            end
            if trailing_space then
                v[i] = line:sub(1, -2)
            end
        end
    end
end

-- add one character to output lines
local function addchar(which, output, kern, smushMode)
    local c = fcharlist[string.byte(which)]
    if not c then
        return
    end

    for i = 1, charheight do
        if smushMode and output[i] ~= "" and which ~= " " then
            local lhc = output[i]:sub(-1)
            local rhc = c[i]:sub(1, 1)
            output[i] = output[i]:sub(1, -2)
            if rhc ~= " " then
                output[i] = output[i] .. rhc
            else
                output[i] = output[i] .. lhc
            end
            output[i] = output[i] .. c[i]:sub(2)
        else
            output[i] = output[i] .. c[i]
        end

        if not (kern or smushMode) or which == " " then
            output[i] = output[i] .. " "
        end
    end
end

--- Returns a table of lines representing a string as figlet
---@param s string The text to make into a figlet
---@param kern boolean Should we reduce spacing
---@param smushMode boolean Causes the letters to share edges
---@return table Lines of ASCII art
function Figlet.ascii_art(s, kern, smushMode)
    assert(fcharlist)
    assert(charheight > 0)

    local output = {}
    for i = 1, charheight do
        output[i] = ""
    end

    for i = 1, #s do
        local c = s:sub(i, i)
        if c >= " " and c < "\127" then
            addchar(c, output, kern, smushMode)
        end
    end

    -- fix up blank character
    local fixedblank = string.gsub(hardblank, "[%%%]%^%-$().[*+?]", "%%%1")

    for i, line in ipairs(output) do
        output[i] = string.gsub(line, fixedblank, " ")
    end

    return output
end

--- Returns the figlet as a string
---@param str string The string to make into a figlet
---@param kern boolean Should we reduce the space between letters?
---@param smushMode boolean Should the letters share edges?
---@return string
function Figlet.getString(str, kern, smushMode)
    local tbl = Figlet.ascii_art(str, kern, smushMode)
    return table.concat(tbl, "\n")
end

--- Returns a figlet as a string, with kern set to true
---@param str string The string to turn into a figlet
---@return string
function Figlet.getKern(str)
    return Figlet.getString(str, true)
end

--- Returns a figlet as a string, with smush set to true
---@param str string The string to turn into a figlet
---@return string
function Figlet.getSmush(str)
    return Figlet.getString(str, true, true)
end

--- Print figlet to console with color
---@param str string Text to display
---@param color string FiveM color code (e.g., "^2" for green)
function Figlet.print(str, color)
    color = color or "^7"
    local lines = Figlet.ascii_art(str, true, true)
    for _, line in ipairs(lines) do
        print(color .. line .. "^7")
    end
end

return Figlet
