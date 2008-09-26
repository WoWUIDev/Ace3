dofile("wow_api.lua")
dofile("LibStub.lua")

local MAJOR = "AceTimer-3.0"

dofile("../"..MAJOR.."/"..MAJOR..".lua")

local AceTimer,minor = LibStub:GetLibrary(MAJOR)


---- test all methods of registration: anonymous funcs, member func names, etc etc


local function func(arg)
	assert(arg=="t1s" or arg=="t2s" or arg=="t3s" or arg=="t4s")
	assert(_G[arg]==nil or type(_G[arg])=="number", dump(arg,type(_G[arg])))
	_G[arg]=(_G[arg] or 0)+1
end

-- Completely anonymous timer
local t1 = AceTimer:ScheduleRepeatingTimer(func, 1, "t1s")

-- Timer associated to a table
local obj2={}
local t2 = AceTimer.ScheduleRepeatingTimer(obj2, func, 1, "t2s")

-- Member function on a table
local obj3={}
function obj3:func(arg)
	assert(self==obj3 and arg=="oogabooga")
	func("t3s")
end
local t3 = AceTimer.ScheduleRepeatingTimer(obj3, "func", 1, "oogabooga")

-- Timer associated to a string
local t4 = AceTimer.ScheduleRepeatingTimer("me4", func, 1, "t4s")



WoWAPI_FireUpdate(0)
assert(t1s==nil and t2s==nil and t3s==nil and t4s==nil, dump(t1s,t2s,t3s,t4s))

WoWAPI_FireUpdate(1)
assert(t1s==1 and t2s==1 and t3s==1 and t4s==1, dump(t1s,t2s,t3s,t4s))

AceTimer.CancelAllTimers(obj2)

WoWAPI_FireUpdate(2)
assert(t1s==2 and t2s==1 and t3s==2 and t4s==2, dump(t1s,t2s,t3s,t4s))

AceTimer.CancelAllTimers(obj3)

WoWAPI_FireUpdate(3)
assert(t1s==3 and t2s==1 and t3s==2 and t4s==3, dump(t1s,t2s,t3s,t4s))

AceTimer.CancelAllTimers("me4")

WoWAPI_FireUpdate(4)
assert(t1s==4 and t2s==1 and t3s==2 and t4s==3, dump(t1s,t2s,t3s,t4s))

AceTimer:CancelTimer(t1)

WoWAPI_FireUpdate(5)
assert(t1s==4 and t2s==1 and t3s==2 and t4s==3, dump(t1s,t2s,t3s,t4s))



-----------------------------------------------------------------------
print "OK"