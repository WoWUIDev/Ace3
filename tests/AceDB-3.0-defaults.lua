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
				siblingDeriv = {
					starDefault = "not-so-starDefault",
				},
			},
			doubleStarTest = {
				["**"] = {
					doubleStarDefault = "doubleStarDefault",
				},
				sibling = {
					siblingDefault = "siblingDefault",
				},
				siblingDeriv = {
					doubleStarDefault = "overruledDefault",
				}
			},
			starTest2 = {
				["*"] = "fun",
				sibling = "notfun",
			}
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
	assert(db.profile.doubleStarTest.siblingDeriv.doubleStarDefault == "overruledDefault")
	assert(db.profile.starTest2.randomkey == "fun")
	assert(db.profile.starTest2.sibling == "notfun")
	
	db.profile.doubleStarTest.siblingDeriv.doubleStarDefault = "doubleStarDefault"
	db.profile.starTest2.randomkey = "notfun"
	db.profile.starTest2.randomkey2 = "fun" 
	db.profile.starTest2.sibling = "fun"
	
	WoWAPI_FireEvent("PLAYER_LOGOUT")
	
	assert(db.profile.singleEntry == nil)
	assert(db.profile.tableEntry == nil)
	assert(db.profile.starTest == nil)
	assert(db.profile.doubleStarTest.randomkey	== nil)
	assert(db.profile.doubleStarTest.siblingDeriv.doubleStarDefault == "doubleStarDefault")
	assert(db.profile.starTest2.randomkey == "notfun")
	assert(db.profile.starTest2.randomkey2 == nil)
	assert(db.profile.starTest2.sibling == "fun")
end

do
	local defaultTest = { 
		profile = { 
			units = { 
				["**"] = { 
					test = 2 
				}, 
				["player"] = { 
				},
				["pet"] = {
					test = 3
				},
				["bug"] = {
					test = 3,
				},
			} 
		} 
	} 
	
	local bugdb = { 
		["profileKeys"] = { 
			["player - Realm Name"] = "player - Realm Name", 
		}, 
		["profiles"] = { 
			["player - Realm Name"] = { 
				["units"] = { 
					["player"] = { 
					}, 
					["pet"] = {
					}, 
					["focus"] = { 
					}, 
					bug = "bug",
				}, 
			}, 
		}, 
	} 
	
	local data = LibStub("AceDB-3.0"):New(bugdb, defaultTest) 
	 
	assert(data.profile.units["player"].test == 2)
	assert(data.profile.units["pet"].test == 3)
	assert(data.profile.units["focus"].test == 2)
	assert(type(data.profile.units.bug) == "string")
	WoWAPI_FireEvent("PLAYER_LOGOUT")
end

do
	local defaultTest = { 
		profile = { 
			units = { 
				["*"] = { 
					test = 2 
				}, 
				["player"] = { 
				} 
			} 
		} 
	} 
	
	local bugdb = { 
		["profileKeys"] = { 
			["player - Realm Name"] = "player - Realm Name", 
		}, 
		["profiles"] = { 
			["player - Realm Name"] = { 
				["units"] = { 
					["player"] = { 
					}, 
					["pet"] = {
					}, 
				}, 
			}, 
		}, 
	} 
	
	local data = LibStub("AceDB-3.0"):New(bugdb, defaultTest) 
	 
	assert(data.profile.units["player"].test == nil)
	assert(data.profile.units["pet"].test == 2)
	assert(data.profile.units["focus"].test == 2)
end

do
	local defaultTest = {
		profile = {
			foo = {
				["*"] = {
					plyf = true,
			},
			}     
		}
	}


	local bugdb = {
		["profileKeys"] = {
			["player - Realm Name"] = "player - Realm Name",
		},
		["profiles"] = {
			["player - Realm Name"] = {
				["foo"] = {
					hopla = 42,
				},
			},
		},
	}

	local data = LibStub("AceDB-3.0"):New(bugdb, defaultTest)

	assert(data.profile.foo.hopla == 42)
end 

do
	local defaultTest = {
		profile = {
			['**'] = {
				['*'] = {
					stuff = 5,
					stuff2 = {
						['**'] = {
							a = 4,
						},
					},
				},
			},
			stuff2 = {
				blu = {
					stuff = 6,
					stuff2 = {
						b = {
							a = 5
						},
					},
				},
			},
		},
	}
	
	local bugdb = {}
	local data = LibStub("AceDB-3.0"):New(bugdb, defaultTest)
	data.profile.stuff2.blu.stuff = 5
	data.profile.stuff2.blu.stuff2.b.a = 4
	data:RegisterDefaults()
	
	local data2 = LibStub("AceDB-3.0"):New(bugdb, defaultTest)
	
	assert(data2.profile.stuff2.blu.stuff == 5)
	assert(data2.profile.stuff2.blu.stuff2.b.a == 4)
end 

do
	local defaultTest = {
		profile = {
			boo = {
				[true] = "true",
				[false] = "false",
			},
		}
	}
	
	local bugdb = {}
	local data = LibStub("AceDB-3.0"):New(bugdb, defaultTest)
	data.profile.boo[true] = "not so true"
	data.profile.boo[false] = "not so false"
	WoWAPI_FireEvent("PLAYER_LOGOUT")
	
	local data2 = LibStub("AceDB-3.0"):New(bugdb, defaultTest)
	assert(data2.profile.boo[true] == "not so true")
	assert(data2.profile.boo[false] == "not so false")
end

do
	local db = {}
	-- test case for ticket 66
	local defaults = {
		profile = {
			Positions = { 
				["**"] = { 
					point = "CENTER", relativeTo = "UIParent", relativePoint = "CENTER", xOfs = 0, yOfs = 0 
				}, 
			},
		},
	}
	
	local data = LibStub("AceDB-3.0"):New(db, defaults)
	
	local v1 = data.profile.Positions.foo
	
	defaults.profile.Positions["TestFrame"] = {
		point = "TOP",
		relativeTo = "UIParent",
		relativePoint = "TOP",
		xOfs = 100,
		yOfs = 200,
	}
	
	data:RegisterDefaults(defaults)
	assert(data.profile.Positions.TestFrame.xOfs == 100)
end
