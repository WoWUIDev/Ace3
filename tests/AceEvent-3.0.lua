dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceEvent-3.0/AceEvent-3.0.lua")

local AceEvent = LibStub("AceEvent-3.0")

local addon = {}

AceEvent:Embed(addon)

-- Test embedding and then registering and unregistering and seeing that things are caught and NOT caught correctly
do 
	local eventResult
	function addon:EVENT_TEST(event,arg1)
		assert(self==addon)
		assert(event=="EVENT_TEST")
		eventResult = arg1
	end

	eventResult = 1
	addon:RegisterEvent("EVENT_TEST")	-- simple reg & test
	WoWAPI_FireEvent("EVENT_TEST", 2)
	assert(eventResult==2)

	eventResult = 3
	addon:UnregisterEvent("SOMETHINGELSE")	-- unreg something that doesn't exist
	WoWAPI_FireEvent("SOMETHINGELSE", 4)	-- fire something with no handler
	assert(eventResult==3)

	eventResult = 5
	addon:UnregisterEvent("SOMETHINGELSE")	-- again unregister something that doesn't exist (why? ohwell)
	WoWAPI_FireEvent("EVENT_TEST", 6)		-- this should still fire
	assert(eventResult==6)
	
	eventResult = 7
	addon:UnregisterAllEvents()		-- test unregging everything
	WoWAPI_FireEvent("EVENT_TEST", 8)	-- this should NOT fire
	assert(eventResult==7)
	
	addon:RegisterEvent("EVENT_TEST")	-- re-register
	WoWAPI_FireEvent("EVENT_TEST", 9)
	assert(eventResult==9)				-- should fire again!

	local switched=0
	function addon:EVENT_TEST()		-- overwrite handler, should work with self["methodname"] syntax
		switched=switched+1
	end
	WoWAPI_FireEvent("EVENT_TEST", 10)
	assert(switched==1)
	assert(eventResult==9)
	
	local woot=0
	addon:RegisterEvent("EVENT_TEST", function(event, arg) 
		assert(event=="EVENT_TEST")
		assert(arg=="woot", dump(event,arg)) 
		woot=woot+1 
	end)	-- CHANGE registration (to a funcref even!)
	WoWAPI_FireEvent("EVENT_TEST", "woot")
	assert(switched==1)
	assert(eventResult==9)
	assert(woot==1)
	
	addon:UnregisterAllEvents()
	WoWAPI_FireEvent("EVENT_TEST")
	assert(switched==1)
	assert(eventResult==9)
	assert(woot==1)
end


-- Test nonembedded funcref calling style, two events to same handler
do
	local eventName
	local eventCount=0
	local function handler(event, ...)
		eventName=event
		eventCount=eventCount+1
	end
	
	AceEvent:RegisterEvent("EVENT1", handler)
	AceEvent:RegisterEvent("EVENT2", handler)
	
	WoWAPI_FireEvent("EVENT1")
	assert(eventName=="EVENT1" and eventCount==1)

	WoWAPI_FireEvent("EVENT2")
	assert(eventName=="EVENT2" and eventCount==2)

end

-- Test "addonID" instead of self
do
	local eventName
	local eventCount=0
	local function handler(event, ...)
		eventName=event
		eventCount=eventCount+1
	end

	local event3Count=0
	local function handler3(event, ...)
		event3Count=event3Count+1
	end
	
	
	AceEvent.RegisterEvent("myAddon", "EVENT1", handler)
	AceEvent.RegisterEvent("myOtherAddon", "EVENT2", handler)
	AceEvent.RegisterEvent("myOtherAddon", "EVENT3", handler3)
	
	WoWAPI_FireEvent("EVENT1")
	assert(eventName=="EVENT1" and eventCount==1)

	WoWAPI_FireEvent("EVENT2")
	assert(eventName=="EVENT2" and eventCount==2)

	WoWAPI_FireEvent("EVENT3")
	assert(event3Count==1)

	AceEvent.UnregisterAllEvents("myAddon")	-- note "." calling style

	WoWAPI_FireEvent("EVENT1")	-- should not fire
	assert(eventCount==2)

	WoWAPI_FireEvent("EVENT2")
	assert(eventCount==3)

	WoWAPI_FireEvent("EVENT3")
	assert(event3Count==2)

	AceEvent:UnregisterAllEvents("myOtherAddon")	-- now ":" calling style
	
	WoWAPI_FireEvent("EVENT1")	-- should not fire
	assert(eventCount==3)
	
	WoWAPI_FireEvent("EVENT2")  -- should not fire
	assert(eventCount==3)

	WoWAPI_FireEvent("EVENT3")  -- should not fire
	assert(event3Count==2)
	
end





-- Test multiple args, different types
do
	local arg3={}
	
	local args
	local function handler(event, ...)
		args = { ... }
	end

	AceEvent:RegisterEvent("ARGZZ", handler)	-- ":" calling style, self=AceEvent
	
	WoWAPI_FireEvent("ARGZZ", "arg1", 2, arg3)
	
	assert(#args==3)
	assert(args[1]=="arg1")
	assert(args[2]==2)
	assert(args[3]==arg3)
end


-- Test user-supplied args, all styles
do
	local addon={}
	local n=0
	AceEvent:Embed(addon)

	-- test self["methodname"]
	function addon:HANDLER(userarg, event, a1,a2)
		assert(self==addon)
		assert(userarg=="userarg")
		assert(event=="EVENT")
		assert(a1==1 and a2==2, dump(a1,a2))
		n=n+1
	end
	addon:RegisterEvent("EVENT", "HANDLER", "userarg")
	WoWAPI_FireEvent("EVENT",1,2)
	assert(n==1)
	
	-- test functionref
	local function handler(userarg, event, a1,a2)
		assert(userarg==nil)
		assert(event=="EVENT")
		assert(a1==1 and a2==2, dump(a1,a2))
		n=n+1
	end
	addon:RegisterEvent("EVENT", handler, nil)	-- look, a nil that should still be passed!
	WoWAPI_FireEvent("EVENT",1,2)
	assert(n==2)
	
	-- test functionref with self="addonId"
	AceEvent.RegisterEvent("myAddon", "EVENT", handler, nil)  -- look, a nil that should still be passed!
	WoWAPI_FireEvent("EVENT",1,2)
	assert(n==4) -- should have fired twice, once for the addon table, once for "myAddon"
	
	addon:UnregisterAllEvents("myAddon")	-- unregs BOTH for addon and "myAddon"
	WoWAPI_FireEvent("EVENT",1,2)
	assert(n==4) -- shouldnt have fired
	
end


-- Register a methodname on AceEvent itself -- should error
do
	local addon={}
	local ok,res = pcall(AceEvent.RegisterEvent, AceEvent, "whatever")
	assert(not ok and res=="Usage: RegisterEvent(\"eventname\", \"methodname\"): do not use Library:RegisterEvent(), use your own 'self'", dump(ok,res))
end

-- Register a nonexistant methodname -- should error
do
	local addon={}
	local ok,res = pcall(AceEvent.RegisterEvent, addon, "THISDOESNTEXIST")
	assert(not ok and res=="Usage: RegisterEvent(\"eventname\", \"methodname\"): 'methodname' - method 'THISDOESNTEXIST' not found on self.", dump(ok,res))
end

-- Don't give UnregAll an arg -- should error
do
	local ok,res = pcall(AceEvent.UnregisterAllEvents)
	assert(not ok and res==[[Usage: UnregisterAllEvents([whatFor]): missing 'self' or "addonId" to unregister events for.]], dump(ok,res))
end

-- Attempt to unregister everything on the library itself -- should error
do
	local ok,res = pcall(AceEvent.UnregisterAllEvents, AceEvent)
	assert(not ok and res==[[Usage: UnregisterAllEvents([whatFor]): supply a meaningful 'self' or "addonId"]], dump(ok,res))
end

-- These should be ok though (note '.' rather than ':' )
AceEvent.UnregisterAllEvents(AceEvent, "BLAH")
AceEvent.UnregisterAllEvents("BLAH")
AceEvent.UnregisterAllEvents("BLAH", AceEvent)
AceEvent.UnregisterAllEvents({})






do -- Tests on messages.
	local messageResult
	function addon:MESSAGE_TEST(message,...)
	end
	-- TODO
end



------------------------------------------------
print "OK"