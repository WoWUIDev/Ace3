dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceDB-3.0/AceDB-3.0.lua")
dofile("serialize.lua")

-- Test the defaults system
do

	local defaults = {
		profile = {
			singleEntry = "singleEntry",
			tableEntry = {
				tableDefault = "tableDefault",
			},
			starTest = {
				["*"] = {
					starDefault = "starDefault",
				},
				sibling = {
					siblingDefault = "siblingDefault",
				},
			},
			doubleStarTest = {
				["**"] = {
					doubleStarDefault = "doubleStarDefault",
				},
				sibling = {
					siblingDefault = "siblingDefault",
				},
			},
		},
	}

	local db = LibStub("AceDB-3.0"):New("MyDB", defaults)
	assert(db.profile.singleEntry == "singleEntry")
	assert(db.profile.tableEntry.tableDefault == "tableDefault")
	assert(db.profile.starTest.randomkey.starDefault == "starDefault")
	assert(db.profile.starTest.sibling.siblingDefault == "siblingDefault")
	assert(db.profile.starTest.sibling.starDefault == nil)
	assert(db.profile.doubleStarTest.randomkey.doubleStarDefault == "doubleStarDefault")
	assert(db.profile.doubleStarTest.sibling.siblingDefault == "siblingDefault")
	assert(db.profile.doubleStarTest.sibling.doubleStarDefault == "doubleStarDefault")
end

-- Test the dynamic creation of sections
do
	local defaults = {
		char = { alpha = "alpha",},
		realm = { beta = "beta",},
		class = { gamma = "gamma",},
		race = { delta = "delta",},
		faction = { epsilon = "epsilon",},
		factionrealm = { zeta = "zeta",},
		profile = { eta = "eta",},
		global = { theta = "theta",},
	}

	local db = LibStub("AceDB-3.0"):New({}, defaults)
	
	assert(rawget(db, "char") == nil)
	assert(rawget(db, "realm") == nil)
	assert(rawget(db, "class") == nil)
	assert(rawget(db, "race") == nil)
	assert(rawget(db, "faction") == nil)
	assert(rawget(db, "factionrealm") == nil)
	assert(rawget(db, "profile") == nil)
	assert(rawget(db, "global") == nil)
	assert(rawget(db, "profiles") == nil)

	-- Check dynamic default creation
	assert(db.char.alpha == "alpha")
	assert(db.realm.beta == "beta")
	assert(db.class.gamma == "gamma")
	assert(db.race.delta == "delta")
	assert(db.faction.epsilon == "epsilon")
	assert(db.factionrealm.zeta == "zeta")
	assert(db.profile.eta == "eta")
	assert(db.global.theta == "theta")
end

-- Test OnProfileChanged
do
	local testdb = LibStub("AceDB-3.0"):New({})
	
	local triggers = {}

	local function OnProfileChanged(message, db, ...)
		if message == "OnProfileChanged" and db == testdb then
			local profile = ...
			assert(profile == "Healers")
			triggers[message] = true
		end
	end

	testdb:RegisterCallback("OnProfileChanged", OnProfileChanged)
	testdb:SetProfile("Healers")
	assert(triggers.OnProfileChanged)
end

-- Test GetProfiles() fix for ACE-35
do
	local db = LibStub("AceDB-3.0"):New({})
	
	local profiles = {
		"Healers",
		"Tanks",
		"Hunter",
	}

	for idx,profile in ipairs(profiles) do
		db:SetProfile(profile)
	end

	local profileList = db:GetProfiles()
	table.sort(profileList)
	assert(profileList[1] == "Healers")
	assert(profileList[2] == "Hunter")
	assert(profileList[3] == "Tanks")
	assert(profileList[4] == UnitName("player" .. " - " .. GetRealmName()))
end

-- Very simple default test
do
	local defaults = {
		profile = {
			sub = {
				["*"] = {
					sub2 = {},
					sub3 = {},
				},
			},
		},
	}

	local db = LibStub("AceDB-3.0"):New({}, defaults)
	
	assert(type(db.profile.sub.monkey.sub2) == "table")
	assert(type(db.profile.sub.apple.sub3) == "table")
	
	db.profile.sub.random.sub2.alpha = "alpha"
end

-- Table insert kills us
do
	local defaults = {
		profile = {
			["*"] = {},
		},
	}

	local db = LibStub("AceDB-3.0"):New({}, defaults)
	
	table.insert(db.profile.monkey, "alpha")
	table.insert(db.profile.random, "beta")

	-- Here, the tables db.profile.monkey should be REAL, not cached
	assert(rawget(db.profile, "monkey"))
end


-- Test multi-level defaults for hyper
do
	local defaults = {
		profile = {
			autoSendRules = {
				['*'] = {
					include = {
						['*'] = {},
					},
					exclude = {
						['*'] = {},
					},
				},
			},
		}
	}

	local db = LibStub("AceDB-3.0"):New({}, defaults)

	assert(rawget(db.profile.autoSendRules.Cairthas.include, "ptSets") == nil)
	assert(rawget(db.profile.autoSendRules.Cairthas.include, "items") == nil)
	table.insert(db.profile.autoSendRules.Cairthas.include.ptSets, "TradeSkill.Mat.ByProfession.Leatherworking")
	table.insert(db.profile.autoSendRules.Cairthas.include.items, "Light Leather")

	db.profile.autoSendRules.Cairthas.include.ptSets.boo = true

	-- Tables should be real now, not cached.
	assert(rawget(db.profile.autoSendRules.Cairthas.include, "ptSets"))
	assert(rawget(db.profile.autoSendRules.Cairthas.include, "items"))
end

do
	local testdb = LibStub("AceDB-3.0"):New("testdbtable", {profile = { test = 2, test3 = { a=1}}})
	assert(testdb.profile.test == 2) --true
	testdb.profile.test = 3
	testdb.profile.test2 = 4
	testdb.profile.test3.b = 2
	assert(testdb.profile.test == 3) --true
	assert(testdb.profile.test2 == 4) --true
	local firstprofile = testdb:GetCurrentProfile()
	testdb:SetProfile("newprofile")
	assert(testdb.profile.test == 2) --true
	testdb:CopyProfile(firstprofile)
	assert(testdb.profile.test == 3) --false, the value is 2
	assert(testdb.profile.test2 == 4) --true 
	assert(testdb.profile.test3.a == 1)
end

do
	local testdb = LibStub("AceDB-3.0"):New({})
	testdb:SetProfile("testprofile")
	testdb:SetProfile("testprofile2")
	testdb:SetProfile("testprofile")
	assert(#testdb:GetProfiles() == 3)
end

do

local TestDB = {
	["namespaces"] = {
		["Space"] = {
			["profiles"] = {
				["Default"] = {
				},
			},
		},
	},
	["profiles"] = {
		["Default"] = {
			["notEmpty"] = true,
		},
		["Test"] = {
		},
	},
	["char"] = {
		["TestChar - SomeRealm"] = {
		},
	},
	["realm"] = {
		["SomeRealm"] = {
			["notEmpty"] = true,
		},
	},
}

local nsdef = {
	profile = {
		bla = true,
	}
}

wipe(LibStub("AceDB-3.0").db_registry)
local testdb = LibStub("AceDB-3.0"):New(TestDB, nil, true)
local ns = testdb:RegisterNamespace("Space", nsdef)

WoWAPI_FireEvent("PLAYER_LOGOUT")
assert(not TestDB.char)
assert(TestDB.profiles.Test)
assert(TestDB.realm.SomeRealm.notEmpty)
assert(not TestDB.namespaces.Space.profiles)
end
