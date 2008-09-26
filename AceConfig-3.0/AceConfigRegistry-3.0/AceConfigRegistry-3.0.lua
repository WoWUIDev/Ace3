--[[
AceConfigRegistry-3.0:

Handle central registration of options tables in use by addons and modules. Do nothing else.

Options tables can be registered as raw tables, or as function refs that return a table.
These functions receive two arguments: "uiType" and "uiName". 
- Valid "uiTypes": "slash", "dropdown", "dialog". This is verified by the library at call time.
- The "uiName" field is expected to contain the full name of the calling addon, including version, e.g. "FooBar-1.0". This is verified by the library at call time.

:IterateOptionsTables() and :GetOptionsTable() always return a function reference that the requesting config handling addon must call with the above arguments.
]]

local MAJOR, MINOR = "AceConfigRegistry-3.0", 0
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

lib.tables = lib.tables or {}


local function verifyGetterArgs(uiType, uiName)
	if uiType~="slash" and uiType~="dropdown" and uiType~="dialog" then
		error("AceConfig: Requesting options table: 'uiType' - invalid configuration UI type, expected 'slash', 'dropdown' or 'dialog'", 3)
	end
	if not strmatch(uiName, "%-[0-9]") then
		error("AceConfig: Requesting options table: 'uiName' - badly formatted or missing version number", 3)
	end
end


---------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options)
-- - appName - string identifying the addon
-- - options - table or function reference

function lib:RegisterOptionsTable(appName, options)
	if type(options)=="table" then
		lib.tables[appName] = function(uiType, uiName)
			verifyGetterArgs(uiType, uiName)
			return options 
		end
	elseif type(options)=="function" then
		lib.tables[appName] = function(uiType, uiName)
			verifyGetterArgs(uiType, uiName)
			return options(uiType, uiName)
		end
	else
		error(MAJOR..": RegisterOptionsTable(appName, options): 'options' - expected table or function reference", 2)
	end
end


---------------------------------------------------------------------
-- :IterateOptionsTables()
--
-- Returns an iterator of ["appName"]=funcref pairs

function lib:IterateOptionsTables()
	return pairs(lib.tables)
end


---------------------------------------------------------------------
-- :GetOptionsTable(appName)
-- - appName - which addon to retreive the options table of
--
-- Returns a function reference

function lib:GetOptionsTable(appName)
	return lib.tables[appName]
end
