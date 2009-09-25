dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceDB-3.0/AceDB-3.0.lua")
dofile("serialize.lua")

-- Test OnProfileChanged
do
	local testdb = LibStub("AceDB-3.0"):New({})
	
	local triggers = {}

	local function OnCallback(message, db, ...)
		if db == testdb then
			if message == "OnProfileChanged" then
				local profile = ...
				assert(profile == "Healers" or profile == "Tanks")
			elseif message == "OnProfileDeleted" then
				local profile = ...
				assert(profile == "Healers")
			elseif message == "OnProfileCopied" then
				local profile = ...
				assert(profile == "Healers")
			elseif message == "OnNewProfile" then
				local profile = ...
				assert(profile == "Healers" or profile == "Tanks")
			end
			triggers[message] = triggers[message] and triggers[message] + 1 or 1
		end
	end

	testdb:RegisterCallback("OnProfileChanged", OnCallback)
	testdb:RegisterCallback("OnProfileDeleted", OnCallback)
	testdb:RegisterCallback("OnProfileCopied", OnCallback)
	testdb:RegisterCallback("OnDatabaseReset", OnCallback)
	testdb:RegisterCallback("OnNewProfile", OnCallback)
	testdb:ResetDB("Healers")
	testdb:SetProfile("Tanks")
	testdb:CopyProfile("Healers")
	testdb:DeleteProfile("Healers")
	assert(triggers.OnProfileChanged == 2)
	assert(triggers.OnDatabaseReset == 1)
	assert(triggers.OnProfileDeleted == 1)
	assert(triggers.OnProfileCopied == 1)
	assert(triggers.OnNewProfile == 2)
end

do
	local dbDefaults = {
		profile = { bla = 0, },
	}
	local db = LibStub("AceDB-3.0"):New({}, dbDefaults, true)
	db:RegisterCallback("OnNewProfile", function()
		db.profile.bla = 1
	end)
	db:SetProfile("blatest")
	assert(db.profile.bla == 1)
end
