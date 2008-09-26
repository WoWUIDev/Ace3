dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceDB-3.0/AceDB-3.0.lua")
dofile("serialize.lua")

do
	local defaults = { profile = { key3 = "stillfun" } }
	local db = LibStub("AceDB-3.0"):New({})
	local namespace = db:RegisterNamespace("test", defaults)
	
	namespace.profile.key1 = "fun"
	namespace.profile.key2 = "nofun"
	
	local oldprofile = db:GetCurrentProfile()
	db:SetProfile("newprofile")
	assert(namespace.profile.key1 == nil)
	assert(namespace.profile.key2 == nil)
	assert(namespace.profile.key3 == "stillfun")
	db:SetProfile(oldprofile)
	assert(namespace.profile.key1 == "fun")
	assert(namespace.profile.key2 == "nofun")
	assert(namespace.profile.key3 == "stillfun")
	db:SetProfile("newprofile2")
	db:CopyProfile(oldprofile)
	assert(namespace.profile.key1 == "fun")
	assert(namespace.profile.key2 == "nofun")
	assert(namespace.profile.key3 == "stillfun")
	db:ResetProfile()
	assert(namespace.profile.key1 == nil)
	assert(namespace.profile.key2 == nil)
	assert(namespace.profile.key3 == "stillfun")
	db:DeleteProfile(oldprofile)
	db:SetProfile(oldprofile)
	assert(namespace.profile.key1 == nil)
	assert(namespace.profile.key2 == nil)
	assert(namespace.profile.key3 == "stillfun")
end
