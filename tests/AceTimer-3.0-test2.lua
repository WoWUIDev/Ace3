
-- AceTimer test suite 2: Errors


dofile("wow_api.lua")
dofile("LibStub.lua")

local MAJOR = "AceTimer-3.0"

dofile("../"..MAJOR.."/"..MAJOR..".lua")

local AceTimer,minor = LibStub:GetLibrary(MAJOR)

-- NOTE, the below pcalls should NOT contain error position information.
-- The reason is that if the error level is correctly set, it will point to _inside_ the pcall(), which does not have a position


-------------------------------------------------------------------
-- Test ScheduleTimer errorchecking of method

obj = {}

ok,msg = pcall(AceTimer.ScheduleTimer, obj, "method", 4, "arg")	-- This should fail - method not defined
assert(not ok)
assert(msg == MAJOR..": ScheduleTimer(\"methodName\", delay, arg): 'methodName' - method not found on target object.", msg)


obj.method = "hi, i'm NOT a function, i'm something else"

ok,msg = pcall(AceTimer.ScheduleTimer, obj, "method", 4, "arg")	-- This should fail - obj["method"] is not a function
assert(not ok)
assert(msg == MAJOR..": ScheduleTimer(\"methodName\", delay, arg): 'methodName' - method not found on target object.", msg)


ok,msg = pcall(AceTimer.ScheduleTimer, obj, nil, 4, "arg")	-- This should fail (method is nil)
assert(not ok)
assert(msg == MAJOR..": ScheduleTimer(callback, delay, arg): 'callback' - function or method name expected.", msg)


ok,msg = pcall(AceTimer.ScheduleTimer, obj, {}, 4, "arg")	-- This should fail (method is table)
assert(not ok)
assert(msg == MAJOR..": ScheduleTimer(callback, delay, arg): 'callback' - function or method name expected.", msg)


-- (Note: ScheduleRepeatingTimer here just to check naming)
ok,msg = pcall(AceTimer.ScheduleRepeatingTimer, obj, 123, 4, "arg")	-- This should fail too (method is integer)
assert(not ok)
assert(msg == MAJOR..": ScheduleRepeatingTimer(callback, delay, arg): 'callback' - function or method name expected.", msg)



-------------------------------------------------------------------
-- Check AceTimer:CancelAllTimers() -- not allowed

ok,msg = pcall(AceTimer.CancelAllTimers, AceTimer)
assert(not ok)
assert(msg == MAJOR..": CancelAllTimers(): supply a meaningful 'self'", dump(msg))


-------------------------------------------------------------------
-- Scheduling a timer on a member function that later becomes a nonfunction

cnt=0
obj.method = function() cnt=cnt+1 end

AceTimer.ScheduleRepeatingTimer(obj, "method", 1, "arg")

WoWAPI_FireUpdate(2)	-- Border case: at this exact bucket, we should be able to convince the timer to fire twice even though it only gets a single onupdate
assert(cnt==2, cnt)		-- This should have worked nicely

errors=0
function geterrorhandler() 
	return function(msg)
		errors=errors+1
		assert(strmatch(msg, "a string value"))
	end
end

obj.method = "this should cause errors"
WoWAPI_FireUpdate(4)

assert(errors==2)  -- timer should have run twice


-----------------------------------------------------------------------
-- :CancelTimer() on something that's already cancelled / never existed

local handle = AceTimer.ScheduleTimer(obj, function() assert("this shouldnt run") end, 1)

AceTimer.CancelTimer(obj, handle)	-- Should work


errors=0
function geterrorhandler() 
	return function(msg)
		errors=errors+1
		assert(strmatch(msg, "already cancelled"))
	end
end

AceTimer.CancelTimer(obj, handle)	-- Should error -- already cancelled
assert(errors==1)


WoWAPI_FireUpdate(6)	-- Let the timer disappear from the buckets


errors=0
function geterrorhandler() 
	return function(msg)
		errors=errors+1
		assert(strmatch(msg, "no such timer"))
	end
end

AceTimer.CancelTimer(obj, handle)	-- Should error -- doesnt exist at all
assert(errors==1)


function geterrorhandler() 
	return function(msg)
		error("This shouldn't have errored!  -- "..msg)
	end
end
AceTimer.CancelTimer(obj, handle, true)	-- silent: shouldn't error








-----------------------------------------------------------------------

print "OK"
