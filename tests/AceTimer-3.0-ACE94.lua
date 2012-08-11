-- Test for ACE-94: memory reclaiming of table indices

dofile("wow_api.lua")
dofile("LibStub.lua")

local MAJOR = "AceTimer-3.0"

dofile("../"..MAJOR.."/"..MAJOR..".lua")

local AceTimer,minor = LibStub:GetLibrary(MAJOR)

local function dummy() end

local VERBOSE = strmatch(arg[1] or "", "v")

-- Initial memory that we have to include...

local objs={}
for n=1,3 do
	objs[n] = {}
end

WoWAPI_FireUpdate(GetTime()+100)

-----------------------------------------------------------------------
-- Get "empty" memory count

collectgarbage("collect")
local mem = collectgarbage("count")



-----------------------------------------------------------------------
-- Run the whole test five times to make sure the cleaner keeps working after a loop

for LOOP=1,5 do

	if VERBOSE then print("\n------------- Loop "..LOOP) end

	-----------------------------------------------------------------------
	-- Schedule a boatload of timers

	for _,obj in pairs(objs) do
		for t=1,1000 do
			AceTimer.ScheduleTimer(obj, dummy, 1)
		end
	end

	collectgarbage("collect")
	if VERBOSE then print(collectgarbage("count") - mem.."KB used - everything live") end
	-- About 688K in original test



	-----------------------------------------------------------------------
	-- Cancel them all again

	for _,obj in pairs(objs) do
		AceTimer.CancelAllTimers(obj)
	end

	-- .. and let them get removed from hash buckets over time
	WoWAPI_FireUpdate(GetTime()+100)

	collectgarbage("collect")
	local idxwaste = collectgarbage("count") - mem
	if VERBOSE then print(idxwaste.."KB used - this is table index waste. Expecting ~110 KB.") end

	-- We should be wasting about 110K here (warnmsg in original test)
	-- 1000 timers * 3 objects * ~40 bytes per index = ~120KB. Sounds about right.
	assert(idxwaste>80 and idxwaste<160, dump(idxwaste))



	-----------------------------------------------------------------------
	-- Now start firing PLAYER_REGEN_ENABLED and watch memory decrease

	-- Clean up 2 thirds
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")

	-- See if 1 third remains
	collectgarbage("collect")
	local thirdwaste = collectgarbage("count") - mem

	assert(thirdwaste > idxwaste/3*0.9 and thirdwaste < idxwaste/3*1.1, dump(thirdwaste, idxwaste))

	-- Clean up last third
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")


	-----------------------------------------------------------------------
	-- We should now be back to near 0 mem consumption

	collectgarbage("collect")
	local endresult = collectgarbage("count") - mem
	if VERBOSE then print(endresult.."KB used - should be nearly clean") end
	-- I'm getting ~2.5K waste from system total, probably something eating a bit more after being run once, not going to go hunting for it
	-- Loops 2..n keep using the same total.
	assert(endresult>0 and endresult<10)


end -- for LOOP=1,5


-----------------------------------------------------------------------
-- Test the excessive timer count warning system
-- Also make sure the cleaner obeys our minimum operation criteria and doesn't run too often
-- (Cleaner and warning runs at the same time)

if VERBOSE then print("\n------------- Testing excessive timer count warnings") end

local obj = setmetatable({}, {
	__tostring = function(self)
		return "MyTestObj"
	end
})

assert(AceTimer.debug.BUCKETS < 1000)	-- .BUCKETS is the warning limit
for t=1,1000 do
	AceTimer.ScheduleTimer(obj, dummy, 1)
end

local warnmsg
local numwarnmsgs=0
function ChatFrame1:AddMessage(msg)
	if VERBOSE then print("Warning message emitted: <"..msg..">") end
	warnmsg = msg
	numwarnmsgs=numwarnmsgs+1
end

for _ in pairs(AceTimer.selfs) do
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
end
assert(numwarnmsgs==1, dump(numwarnmsgs))
assert(strmatch(warnmsg, "MyTestObj.*has 100[0-9] live timers"), dump(warnmsg, msg))	-- it won't be 1000 since __ops etc gets counted. it'll be a little more.

-- Now it shouldn't clean&warn again since there are no operations on the table
numwarnmsgs=0
for _ in pairs(AceTimer.selfs) do
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
end
assert(numwarnmsgs==0)

-- Artificially inflate __ops somewhat, still shouldn't warn
AceTimer.selfs[obj].__ops = 10
numwarnmsgs=0
for _ in pairs(AceTimer.selfs) do
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
end
assert(numwarnmsgs==0)

-- Artificially inflate __ops A LOT, now it should warn again. Once.
AceTimer.selfs[obj].__ops = 1000000
numwarnmsgs=0
for LOOP=1,20 do
	for _ in pairs(AceTimer.selfs) do
		WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
	end
end
assert(numwarnmsgs==1)


-----------------------------------------------------------------------
-- Test a fencepost case: only one addon. That one addon should be 
-- checked for every PLAYER_REGEN_ENABLED.

LibStub.libs[MAJOR] = nil
LibStub.minors[MAJOR] = nil
dofile("../"..MAJOR.."/"..MAJOR..".lua")

local AceTimer,minor = LibStub:GetLibrary(MAJOR)

assert(AceTimer.debug.BUCKETS < 1000)	-- .BUCKETS is the warning limit
for t=1,1000 do
	AceTimer.ScheduleTimer(obj, dummy, 1)
end

for LOOP=1,3 do
	numwarnmsgs=0
	AceTimer.selfs[obj].__ops = 1000000
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
	assert(numwarnmsgs==1)
end

for LOOP=1,3 do
	numwarnmsgs=0
	-- no __ops increase, nothing should be checked
	WoWAPI_FireEvent("PLAYER_REGEN_ENABLED")
	assert(numwarnmsgs==0)
end




-----------------------------------------------------------------------
print "OK"
