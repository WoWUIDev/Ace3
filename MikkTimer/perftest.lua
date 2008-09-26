
local RUNTIME = 600
local MAXDELAY = 2
local TIMERS = 70

local FPSFROM=5
local FPSTO=105
local FPSSTEP=5

local _time = 0
function GetTime()
	return _time
end

local Object = {
}


local cnt=0
local function func()
	cnt=cnt+1
end


print("---------------------------\nMikkTimer\n\n")
dofile("MikkTimer.lua")
local Pulse = MikkTimer.Pulse
math.randomseed(0)
_time = 0
for i=1,TIMERS do
	MikkTimer:ScheduleRepeatingTimer(Object, func, math.random()*MAXDELAY+0.1)
end

local totcnt=0
for fps=FPSFROM,FPSTO,FPSSTEP do
	cnt=0
	local begin=os.clock()
	for i=0,RUNTIME,1/fps do
		_time = _time + 1/fps
		Pulse()
	end
	local done=os.clock()
	print(format("%3d fps: %.3fs  -- %5d timers fired", fps,done-begin, cnt))
	totcnt=totcnt + cnt
end
print("Total "..totcnt.." timers fired\n\n")



print("---------------------------\nCladTimer\n\n")
dofile("CladTimer.lua")
local Pulse = CladTimer.Pulse
math.randomseed(0)
_time=0
local begin=os.clock()
for i=1,TIMERS do
	CladTimer:ScheduleRepeatingTimer(i, func, math.random()*MAXDELAY+0.1)
end

local totcnt=0
for fps=FPSFROM,FPSTO,FPSSTEP do
	cnt=0
	local begin=os.clock()
	for i=0,RUNTIME,1/fps do
		_time = _time + 1/fps
		Pulse()
	end
	local done=os.clock()
	print(format("%3d fps: %.3fs  -- %5d timers fired", fps,done-begin, cnt))
	totcnt=totcnt + cnt
end
print("Total "..totcnt.." timers fired\n\n")

