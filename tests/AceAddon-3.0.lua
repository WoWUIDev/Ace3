-- TODO:
-- Test module support of AceAddon-3.0.



dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../AceAddon-3.0/AceAddon-3.0.lua")

local AceAddon = LibStub("AceAddon-3.0")

do -- Test create addon.

	local success, reason, addon
	
	-- 'name' - string expected
	success, reason = pcall( function() AceAddon:NewAddon() end )
	assert( success == false and reason:find("'name' - string expected",1,true) )

	-- Cannot find a library instance of "Testing123".
	success, reason = pcall( function() AceAddon:NewAddon("TestAddon-1", "Testing123") end )
	assert( success == false and reason:find("Cannot find a library instance",1,true) )

	-- Success.
	addon = AceAddon:NewAddon("TestAddon-2")
	assert( addon and addon == AceAddon:GetAddon("TestAddon-2") )
	
	-- Addon 'TestAddon-2' already exists.
	success, reason = pcall( function() addon = AceAddon:NewAddon("TestAddon-2") end )
	assert( success == false and reason:find("Addon 'TestAddon-2' already exists",1,true) )

end



do -- Test mixin.

	-- Define a simple library for testing mixin.
	local libA = LibStub:NewLibrary("LibStupid",1)
	if libA then
		libA.mixins = { "BecomeStupid", "BecomeDumb" }
		function libA:BecomeStupid()
		end
		function libA:BecomeDumb()
		end
		function libA:Embed(target)
			for i,method in ipairs(self.mixins) do
				target[method] = self[method]
			end
		end
	end

	-- Yet another library.
	local libB = LibStub:NewLibrary("LibSmart",1)
	if libB then
		libB.mixins = { "BecomeSmart", "BecomeClever" }
		function libB:BecomeSmart()
		end
		function libB:BecomeClever()
		end
		function libB:Embed(target)
			for i,method in ipairs(self.mixins) do
				target[method] = self[method]
			end
		end
	end
	
	-- Create an AceAddon object with 2 libraries mixed.
	local addon = AceAddon:NewAddon("TestAddon-3","LibStupid","LibSmart")
	
	-- Are the methods mixed correctly?
	assert( addon.BecomeStupid == libA.BecomeStupid )
	assert( addon.BecomeDumb == libA.BecomeDumb )
	assert( addon.BecomeSmart == libB.BecomeSmart )
	assert( addon.BecomeClever == libB.BecomeClever )
end


do -- Test the call to OnInitialize, OnEnable and OnDisable.

	local addon = AceAddon:NewAddon("TestAddon-4","LibStupid","LibSmart")
	
	local initialized = false
	function addon:OnInitialize()
		initialized = true
	end

	local enabled = false
	function addon:OnEnable()
		enabled = true
	end
	
	function addon:OnDisable()
		enabled = false
	end

	-- Testing the call to addon:OnInitialize().
	WoWAPI_FireEvent("ADDON_LOADED",ADDON_NAME)
	assert(initialized and not enabled)

	-- IsLoggedIn() is supposed to return true when addon receives PLAYER_LOGIN.
	function IsLoggedIn() return true end

	-- Testing the call to addon:OnEnable()
	WoWAPI_FireEvent("PLAYER_LOGIN")
	assert(initialized and enabled)
	
	-- Testing the call to addon:OnDisable()
	AceAddon:DisableAddon(addon)
	assert(initialized and not enabled)
	
end

print("Test finished.")



