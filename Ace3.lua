
-- This file is only there in standalone Ace3 and provides handy dev tool stuff I guess
-- for now only /rl to reload your UI :)
-- note the complete overkill use of AceAddon and console, ain't it cool?

Ace3 = LibStub("AceAddon-3.0"):NewAddon("Ace3", "AceConsole-3.0")

Ace3:RegisterChatCommand("rl", function() ReloadUI() end )


