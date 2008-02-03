-- Test1: Tests basic functionality and upgrading of AceTimer

dofile("wow_api.lua")
dofile("LibStub.lua")

local MAJOR = "AceTimer-3.0"

dofile("../"..MAJOR.."/"..MAJOR..".lua")

local AceTimer,minor = LibStub:GetLibrary(MAJOR)
_G.AceTimer=AceTimer

-----------------------------------------------------------------------
-- Test embedding

local obj={}
AceTimer:Embed(obj)

assert(type(obj.ScheduleTimer)=="function")
assert(type(obj.ScheduleRepeatingTimer)=="function")
assert(type(obj.CancelTimer)=="function")
assert(type(obj.CancelAllTimers)=="function")



-----------------------------------------------------------------------
-- Test basic registering, both ways

t1s = 0
function obj:Timer1(arg)
	assert(self==obj)
	assert(arg=="t1")
	t1s = t1s + 1
end

t2s = 0
function Timer2(arg)
	assert(arg=="t2")
	t2s = t2s + 1
end

function obj:Timer3()
	assert(false)	-- This should never run!
end

t4s=0
t5s=0
local function Timer4_5(arg)
	assert(arg=="t4s" or arg=="t5s", dump(arg))
	_G[arg] = _G[arg] + 1
end
function obj:Timer4(arg)
	assert(self==obj)
	Timer4_5(arg)
end

-- 3 repeating timers:
timer1 = obj:ScheduleRepeatingTimer("Timer1", 1, "t1")
timer2 = obj:ScheduleRepeatingTimer(Timer2, 2, "t2")
timer3 = obj:ScheduleRepeatingTimer("Timer3", 3, "t3")	

-- 2 single shot timers:
timer4 = obj:ScheduleTimer("Timer4", 1, "t4s")
timer5 = obj.ScheduleTimer("myObj", Timer4_5, 2, "t5s")	-- string as self


t3s = 0
function obj:Timer3(arg) 	-- This should be the one to run, not the old Timer3
	assert(self==obj)
	assert(arg=="t3")
	t3s = t3s + 1
end


-----------------------------------------------------------------------
-- Now do some basic tests of timers running at the right time and 
-- the right amount of times


WoWAPI_FireUpdate(0)
assert(t1s==0 and t2s==0 and t3s==0 and t4s==0 and t5s==0)

WoWAPI_FireUpdate(0.99)
assert(t1s==0 and t2s==0 and t3s==0 and t4s==0 and t5s==0)

WoWAPI_FireUpdate(1.00)
assert(t1s==1 and t2s==0 and t3s==0 and t4s==1 and t5s==0, dump(t1s,t2s,t3s,t4s,t5s))

WoWAPI_FireUpdate(1.99)
assert(t1s==1 and t2s==0 and t3s==0 and t4s==1 and t5s==0)

WoWAPI_FireUpdate(2.5)
assert(t1s==2 and t2s==1 and t3s==0 and t4s==1 and t5s==1)

WoWAPI_FireUpdate(2.99)
assert(t1s==2 and t2s==1 and t3s==0)

WoWAPI_FireUpdate(3.099)
assert(t1s==3 and t2s==1, t2s and t3s==1, t3s)

WoWAPI_FireUpdate(6.000)
assert(t3s==2)

assert(t4s==1 and t5s==1)	-- make sure our single shot timers haven't run more than once



t6s=0
obj:ScheduleTimer(function() t6s=t6s+1 end, 1)	-- fire up a single oneshot timer to live past our upgrade below


-----------------------------------------------------------------------
-- Screw up our mixins, pretend to have an older acetimer loaded, and reload acetimer

obj.ScheduleTimer = 12345

dofile("../"..MAJOR.."/"..MAJOR..".lua")

assert(obj.ScheduleTimer == 12345)	-- shouldn't have gotten replaced yet

LibStub.minors[MAJOR] = LibStub.minors[MAJOR] - 1

dofile("../"..MAJOR.."/"..MAJOR..".lua")

assert(type(obj.ScheduleTimer)=="function")	-- should have been replaced now


-----------------------------------------------------------------------
-- Test that timers still live

t1s, t2s, t3s, t4s, t5s = 0,0,0,0,0

WoWAPI_FireUpdate(6.5)
assert(t1s==0 and t2s==0 and t3s==0 and t4s==0 and t5s==0 and t6s==0)

WoWAPI_FireUpdate(7.7)
assert(t1s==1 and t2s==0 and t3s==0 and t4s==0 and t5s==0 and t6s==1, dump(t1s,t2s,t3s,t4s,t5s,t6s))

WoWAPI_FireUpdate(9.8)
assert(t1s==2 and t2s==1 and t3s==1 and t4s==0 and t5s==0 and t6s==1)	-- NOTE: t1s will only fire ONCE now, since we had a >1.99s lag!



-----------------------------------------------------------------------
-- Test cancelling
-- - test right and wrong 'self'
-- - test cancelling from within the timer

t1s, t2s, t3s, t4s, t5s, t6s = 0,0,0,0,0,0

assert(not AceTimer:CancelTimer(timer1, true))	-- wrong self, shouldnt cancel anything

assert(obj:CancelTimer(timer1))	-- right self - cancel timer1

WoWAPI_FireUpdate(10.01)
assert(t1s==0 and t2s==1)	-- timer 2 should still work

obj.Timer3 = function() 
	t3s=t3s+1
	t3cancelled=true
	assert(obj:CancelTimer(timer3))
end

WoWAPI_FireUpdate(13.01)
assert(t1s==0 and t2s==2 and t3s==1)
assert(t3cancelled)

WoWAPI_FireUpdate(16.01)
assert(t1s==0 and t2s==3 and t3s==1, t1s..t2s..t3s)
assert(t3cancelled)


t1s, t2s, t3s, t4s, t5s = 0,0,0,0,0

obj:CancelAllTimers()

local i = 17
local e = i + AceTimer.debug.BUCKETS / AceTimer.debug.HZ * 5	-- 5 full loops of all buckets
while i < e do
	i=i+math.random()
	WoWAPI_FireUpdate(i) -- long time in the future
end
assert(t1s==0 and t2s==0 and t3s==0 and t4s==0 and t5s==0 and t6s==0)	-- nothing should have fired


-----------------------------------------------------------------------
--

for i=1,AceTimer.debug.BUCKETS do
	if AceTimer.hash[i]~=false then
		error("AceTimer.hash["..i.."] was '"..tostring(AceTimer.hash[i]).."' - expected false")
	end
end

-----------------------------------------------------------------------

print "OK"
