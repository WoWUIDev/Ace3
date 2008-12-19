--- AceConfig-3.0 wrapper library.
-- Provides an API to register an options table with the config registry,
-- as well as associate it with a slash command.
-- @class file
-- @name AceConfig-3.0
-- @release $Id$

--[[
AceConfig-3.0

Very light wrapper library that combines all the AceConfig subcomponents into one more easily used whole.

Also automatically adds "config", "enable" and "disable" commands to options table as appropriate.

]]

local MAJOR, MINOR = "AceConfig-3.0", 2
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end


local cfgreg = LibStub("AceConfigRegistry-3.0")
local cfgcmd = LibStub("AceConfigCmd-3.0")
local cfgdlg = LibStub("AceConfigDialog-3.0")
--TODO: local cfgdrp = LibStub("AceConfigDropdown-3.0")


---------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options, slashcmd, persist)
--
-- - appName - (string) application name
-- - options - table or function ref, see AceConfigRegistry
-- - slashcmd - slash command (string) or table with commands, or nil to NOT create a slash command

function lib:RegisterOptionsTable(appName, options, slashcmd)
	local ok,msg = pcall(cfgreg.RegisterOptionsTable, self, appName, options)
	if not ok then error(msg, 2) end
	
	if slashcmd then
		if type(slashcmd) == "table" then
			for _,cmd in pairs(slashcmd) do
				cfgcmd:CreateChatCommand(cmd, appName)
			end
		else
			cfgcmd:CreateChatCommand(slashcmd, appName)
		end
	end
end
