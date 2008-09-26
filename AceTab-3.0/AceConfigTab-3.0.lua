--[[
-- AceConfigTab-3.0
--
-- Creates an AceTab-3.0 completion set for handling AceConfig-3.0 command trees.
-- ]]

local MAJOR, MINOR = "AceConfigTab-3.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

local ac = LibStub("AceConsole-3.0")

local function printf(...)
	DEFAULT_CHAT_FRAME:AddMessage(string.format(...))
end

-- getChildren(opt, ...)
--
-- Retrieve the next valid group args in an AceConfig table.
--
--   opt - AceConfig options table 
--   ...  - args following the slash command
-- 
-- opt will need to be determined by the slash-command
-- The args will be obtained using AceConsole:GetArgs() or something similar on the remainder of the line.
--
-- Returns arg1, arg2, ...
local function getLevel(opt, ...)
    -- Walk down the options tree to the last arg in the commandline, or return if it does not follow the tree.
    local path = ""
    local lastChild
    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        if not arg or type(arg) == 'number' then break end
        if opt.plugins then
            for k in pairs(opt.plugins) do
                if string.lower(k) == string.lower(arg) then
                    opt = opt.plugins[k]
                    path = path..arg.." "
                    lastChild = arg
                    break
                end
            end
        elseif opt.args then
            for k in pairs(opt.args) do
                if string.lower(k) == string.lower(arg) then
                    opt = opt.args[k]
                    path = path..arg.." "
                    lastChild = arg
                    break
                end
            end
        else
            break
        end
    end
    return opt, path
end

local function getChildren(opt, ...)
	local lastChild, path
    opt, path, lastChild = getLevel(opt, ...)
    local args = {}
    for _, field in ipairs({"args", "plugins"}) do
        if type(opt[field]) == 'table' then
            for k in pairs(opt[field]) do
                if opt[field].type ~= 'header' then
                    table.insert(args, k)
                end
            end
        end
    end
    return args, path
end

--LibStub("AceConfig-3.0"):RegisterOptionsTable("ag_UnitFrames", aUF.Options.table)
local function createWordlist(t, cmdline, pos)
    local cmd = string.match(cmdline, "(/[^ \t\n]+)")
    local argslist = string.sub(cmdline, pos, this:GetCursorPosition())
    local opt  -- TODO: figure out options table using cmd
    opt = LibStub("AceConfigRegistry-3.0"):GetOptionsTable("ag_UnitFrames", "cmd", "AceTab-3.0")  -- hardcoded temporarily for testing
	if not opt then return end
	local args, path = getChildren(opt, ac:GetArgs(argslist, #argslist/2))  -- largest # of args representable by a string of length #argslist, since they must be separated by spaces
	for _, v in ipairs(args) do
		table.insert(t, path..v)
	end
end

local function usage(t, matches, _, cmdline)
    local cmd = string.match(cmdline, "(/[^ \t\n]+)")
    local argslist = string.sub(cmdline, #cmd, this:GetCursorPosition())
    local opt  -- TODO: figure out options table using cmd
    opt = LibStub("AceConfigRegistry-3.0"):GetOptionsTable("ag_UnitFrames")("cmd", "AceTab-3.0")  -- hardcoded temporarily for testing
	if not opt then return end
    local level = getLevel(opt, ac:GetArgs(argslist, #argslist/2))  -- largest # of args representable by a string of length #argslist, since they must be separated by spaces
    local option
    for _, m in pairs(matches) do
        local tail = string.match(m, "([^ \t\n]+)$")
        option = level.plugins and level.plugins[tail] or level.args and level.args[tail]
        printf("%s - %s", tail, option.desc)
    end
end

LibStub("AceTab-3.0"):RegisterTabCompletion("aguftest", "%/%w+ ", createWordlist, usage)
