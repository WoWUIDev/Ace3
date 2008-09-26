--[[ $Id$ ]]
--[[
AceConfig-3.0

Very light wrapper library that combines all the AceConfig subcomponents into one more easily used whole.

Also automatically adds "config", "enable" and "disable" commands to options table as appropriate.

]]

local MAJOR, MINOR = "AceConfig-3.0", 0
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end


local cfgreg = LibStub("AceConfigRegistry-3.0")
local cfgcmd = LibStub("AceConfigCmd-3.0")
local cfgdlg = LibStub("AceConfigDialog-3.0")
--TODO: local cfgdrp = LibStub("AceConfigDropdown-3.0")

local con -- AceConsole, LoD


---------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options, slashcmd, persist)
--
-- - appName - (string) application name
-- - options - table or function ref, see AceConfigRegistry
-- - slashcmd - slash command (string) or nil to not create a slash command

function lib:RegisterOptionsTable(appName, options, slashcmd)
	local ok,msg = pcall(cfgreg.RegisterOptionsTable, self, appName, options)
	if not ok then error(msg, 2) end
	
	if slashcmd then
		if not con then
			con = LibStub("AceConsole-3.0")
			con.RegisterChatCommand(self, slashcmd, function(input)
						cfgcmd.HandleCommand(self, slashcmd, appName, input)
				end, 
			true)
		end
	end
end
