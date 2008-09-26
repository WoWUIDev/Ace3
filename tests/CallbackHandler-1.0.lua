dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")

local CH = assert(LibStub("CallbackHandler-1.0"))


-----------------------------------------------------------------------
-- test default names
do
	local test = {}
	CH:New(test, nil, nil, nil)

	assert(test.RegisterCallback)
	assert(test.UnregisterCallback)
	assert(test.UnregisterAllCallbacks)
end


-----------------------------------------------------------------------
-- test custom names
do
	local test = {}
	CH:New(test, "Reg", "Unreg", "UnregAll")

	assert(test.Reg)
	assert(test.Unreg)
	assert(test.UnregAll)
end


-----------------------------------------------------------------------
-- test with unregall==false
do
	local test = {}
	CH:New(test, "Reg", "Unreg", false)

	assert(test.Reg)
	assert(test.Unreg)
	assert(test.UnregisterAllCallbacks == nil)
end


-----------------------------------------------------------------------
-- test OnUsed / OnUnused
do
	local test = {}

	local n=0
	
	local reg = CH:New(test, "Reg", "Unreg", "UnregAll")
	
	local lastOnUsed
	function reg:OnUsed(target, event)
		assert(self==reg)
		assert(target==test)
		lastOnUsed=event
		n=n+1
	end
	
	local lastOnUnused
	function reg:OnUnused(target, event)
		assert(self==reg)
		assert(target==test)
		lastOnUnused=event
		n=n+1
	end
	
	
	local function func() end
	
	test.Reg("addon1", "Thing1", func)		-- should fire an OnUsed Thing1
	assert(n==1 and lastOnUsed=="Thing1")

	test.Reg("addon1", "Thing2", func)		-- should fire an OnUsed Thing2
	assert(n==2 and lastOnUsed=="Thing2")
	
	test.Reg("addon1", "Thing1", func)		-- should NOT fire an OnUsed (Thing1 seen already)
	assert(n==2)
	
	test.Reg("addon2", "Thing1", func)		-- should NEITHER fire an OnUsed  (Thing1 seen already)
	assert(n==2)

	test.Reg("addon2", "Thing2", func)		-- should NEITHER fire an OnUsed  (Thing2 seen already)
	assert(n==2)

	-- now start unregging Thing1
	
	test.Unreg("addon1", "Thing1")		-- Still one left, shouldnt fire OnUnused yet
	assert(n==2)
	
	test.Unreg("addon2", "Thing1")
	assert(n==3 and lastOnUnused=="Thing1", dump(n,lastOnUnused))	-- Now we should get OnUnused Thing1
	
	-- aaand unreg Thing2 (via some UnregAlls)
	
	test.UnregAll("addon1")
	assert(n==3)
	test.UnregAll("addon2")
	assert(n==4 and lastOnUnused=="Thing2")
	
end


-----------------------------------------------------------------------
-- ACE-67: Test registering new handlers for an event while in a callback for that event
--
-- Problem: for k,v in pairs(eventlist)  eventlist[somethingnew]=foo end
-- This happens when we fire callback X, and the handler registers another handler for X

do
	local test={}
	local reg = CH:New(test, "Reg", "Unreg", "UnregAll")
	local REPEATS = 1000  -- we get roughly 50% failure ratio, so 1000 tests WILL trigger it
	
	local hasRun = {}
	local hasRunNoops = {}
	
	local function noop(noopName) 
		hasRunNoops[noopName]=hasRunNoops[noopName]+1
	end
	
	local rnd=math.random

	local regMore=true
	local function RegOne(name)
		hasRun[name]=hasRun[name]+1
		if regMore then
			local noopName
			repeat
				noopName = tostring(rnd(1,99999999))
			until not hasRunNoops[noopName] and not hasRun[noopName]
			hasRunNoops[noopName]=0
			test.Reg(noopName, "EVENT", noop, noopName)
		end
	end

	for i=1,REPEATS do	
		local name
		repeat
			name=tostring(rnd(1,99999999))
		until not hasRun[name]
		hasRun[name]=0
		test.Reg(name, "EVENT", RegOne, name)
	end
	
	-- Firing this event should lead to all 1000 callbacks running, and registering another 1000 callbacks
	reg:Fire("EVENT")
	
	-- Test that they all ran once
	local n=0
	for k,v in pairs(hasRun) do
		assert(v==1, dump(k,v).." should be ==1")
		n=n+1
	end
	assert(n==REPEATS, dump(n))
	
	-- And that all the noops didnt run (they should have been delayed til the next fire)
	local n=0
	for k,v in pairs(hasRunNoops) do
		assert(v==0, dump(k,v).." should be ==0")
		n=n+1
	end
	assert(n==REPEATS, dump(n))
	
	
	-- Now we run all of them again without registering more, so we should get 1000+1000 callbacks
	regMore=false
	reg:Fire("EVENT")
	
	-- Test that all main events ran another time (total 2)
	local n=0
	for k,v in pairs(hasRun) do
		assert(v==2, dump(k,v).." should be ==2")
		n=n+1
	end
	assert(n==REPEATS, dump(n))
	
	-- And that all the noops ran once
	local n=0
	for k,v in pairs(hasRunNoops) do
		assert(v==1, dump(k,v).." should be ==1")
		n=n+1
	end
	assert(n==REPEATS, dump(n))
end


-----------------------------------------------------------------------
-- ACE-67: Test reentrancy (firing an event from inside a callback) PLUS regging more callbacks from inside them!

for REPEATS=1,20 do
	local test={}
	local reg = CH:New(test, "Reg", "Unreg", "UnregAll")
	
	local fires=0
	local extraFires=0
	
	local function extrahandler()
		extraFires = extraFires+1
	end
	
	local function handler(n, event, arg)
		fires=fires+1
		assert(reg.recurse==arg, dump(reg.recurse, arg))	-- check up that the internal recursion counter is tracking correctly
		
		-- to make things even more interesting, we'll reg even more callbacks recursively (a lot of these should be overwrites)
		test.Reg("extra"..n..","..arg, "EVENT", extrahandler)

		if arg==n then
			reg:Fire("EVENT", arg+1)	-- we'll end up with up to REPEATS levels of recursion
		end
	end
	
	for n=1,REPEATS do
		test.Reg("handler"..n, "EVENT", handler, n)
	end

	-- Fire the event!
	assert(reg.recurse==0)
	reg:Fire("EVENT", 1)
	assert(reg.recurse==0)
	
	assert(fires == REPEATS + (REPEATS*REPEATS), dump(fires, REPEATS + (REPEATS*REPEATS), REPEATS))
	assert(extraFires==0)

	-- Fire again! This time we should see extraFires
	fires=0
	assert(reg.recurse==0)
	reg:Fire("EVENT", 1)
	assert(reg.recurse==0)

	assert(fires == REPEATS + (REPEATS*REPEATS), dump(fires, REPEATS + (REPEATS*REPEATS), REPEATS))
	assert(extraFires== fires + fires*REPEATS)

end


-----------------------------------------------------------------------
-- ACE-67: Test that a recursively registered callback is properly removed

for REPEATS=1,20 do
	local test={}
	local reg = CH:New(test, "Reg", "Unreg", "UnregAll")
	
	local extraFired=0
	local function extra()
		extraFired=extraFired+1
	end

	local fired=0
	local function RegExtra()
		fired = fired + 1
		
		local name=tostring(math.random(1,999999))
		test.Reg(name,"EVENT",extra)
		if fired==1 then
			test.Unreg(name,"EVENT")	-- #1: test single unreg
		elseif fired==2 then
			test.UnregAll(name)			-- #2: test unregall
		elseif fired==3 then
			-- let it be regged
		end
	end

	test.Reg("test","EVENT",RegExtra)
	
	reg:Fire("EVENT")
	assert(fired==1)
	assert(extraFired==0, dump(extraFired))
	
	reg:Fire("EVENT")
	assert(fired==2)
	assert(extraFired==0, dump(extraFired))

	reg:Fire("EVENT")
	assert(fired==3)
	assert(extraFired==0, dump(extraFired))	-- there's an extra regged, but it hasn't fired yet
	
	reg:Fire("EVENT")
	assert(fired==4)
	assert(extraFired==1, dump(extraFired)) -- yeah ok now it fired
	
end



-----------------------------------------------------------------------
-- Delayed registration:
-- - Verify that delayed OnUsed are fired
-- - Verify that OnUnused aren't fired if OnUsed hasn't been fired yet

do
	local obj = {}
	local reg = CH:New(obj, "Reg", "Unreg", "UnregAll")

	local dummys, regs, onused, onunused = 0,0,0,0
	
	local addon = {}
	addon.Dummy = function() dummys=dummys+1 end
	addon.ReggingEvent = function() end
	obj.Reg(addon,"ReggingEvent")
	
	reg.OnUsed = function(reg,tgt,evt) 
		assert(evt=="Dummy")
		onused = onused + 1  
	end
	reg.OnUnused = function(rev,tgt,evt) 
		assert(evt=="Dummy")
		onunused = onunused + 1  
	end

	-- Register "Dummy" from inside "ReggingEvent"
	addon.ReggingEvent = function() 	
		regs=regs+1
		obj.Reg(addon,"Dummy")
		assert(onused==0) -- shouldn't fire yet
	end
	
	reg:Fire("ReggingEvent")
	assert(regs==1)		-- should have run once
	assert(onused==1)	-- should have fired now
	assert(dummys==0)
	reg:Fire("Dummy")
	assert(dummys==1)
	assert(onunused==0)
	
	-- Now unregister "Dummy" normally
	obj.Unreg(addon,"Dummy")
	assert(onunused==1)
	reg:Fire("Dummy")		-- sanity: should do nothing unless something is SERIOUSLY broken
	assert(dummys==1)
	
	
	-- Register "Dummy" from inside "ReggingEvent" and then unregister it
	dummys, regs, onused, onunused = 0,0,0,0
	addon.ReggingEvent = function() 	-- This event tries to register more events inside it
		regs=regs+1
		obj.Reg(addon,"Dummy")
		assert(onused==0) -- shouldn't fire yet
		reg:Fire("Dummy")	-- this shouldn't fire; it should still be queued
		obj.Unreg(addon,"Dummy")
		assert(onunused==0) -- shouldn't fire at all now since onused never did
	end
	
	reg:Fire("ReggingEvent")
	assert(regs==1)
	assert(dummys==0)
	
	reg:Fire("Dummy")	-- sanity: should do nothing unless something is SERIOUSLY broken
	assert(onused==0)
	assert(onunused==0)
	assert(dummys==0)
	
end



-- We do not test the actual callback logic here. The AceEvent tests do that plenty.

-----------------------------------------------------------------------
print "OK"