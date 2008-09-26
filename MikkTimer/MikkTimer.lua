
-- Basic assumptions:
-- * In a typical system, we do more re-scheduling per second than there are timer pulses per second
-- * Regardless of timer implementation, we cannot guarantee timely delivery due to FPS restriction (may be as low as 10)

-- Not yet implemented assumptions:
-- * In a high FPS system (assume 50), one frame per addon (assume 50) means 2500 function calls per second.
--   PRO: Lower CPU load with 1 global frame
--   CON: Profiling?

-- This implementation:
-- CON: The smallest allowable timer interval is constrained by HZ (currently 1/10s)
-- PRO: It will correctly fire any timer faster than HZ over a length of time, e.g. 0.11s interval -> 90 times over 10 seconds
-- PRO: In a small lag burst, timers will STILL be fired the expected amount of times (due to "curbucket" always chasing "newbucket" with +1 intervals)
--   CON: In a BIG lag burst, this may mean lots of catch-up work, and in a _severely_ overloaded system, the processing load does not decrease dynamically
-- PRO: (Re-)scheduling is O(1) with a VERY small constant. It's a simple table insertion in a hash bucket.
-- CAUTION: The BUCKETS constant constrains how many timers can be efficiently handled. With too many hash collisions, performance will decrease.


local HZ=11					-- Timers will not be fired more often than HZ-1 times per second. 
												-- Keep at intended speed PLUS ONE or we get bitten by floating point rounding errors
												-- If this is ever LOWERED, all existing timers need to be enforced to have a delay >= 1/HZ on lib upgrade.
												-- If this number is ever changed, all entries need to be rehashed on lib upgrade.
local BUCKETS=131		-- Prime for good distribution
												-- If this number is ever changed, all entries need to be rehashed on lib upgrade.

MikkTimer = {}

local GetTime = GetTime

local hash = {
}
MikkTimer.hash = hash

for i=0,BUCKETS-1 do
	hash[i] = hash[i] or {}
end

local curbucket = floor(GetTime()*HZ)%BUCKETS
local now = GetTime()

function MikkTimer:Pulse()
	now = GetTime()
	local soon=now+1	-- +1 is safe as long as HZ>1 and HZ<BUCKETS... so forever
	local newbucket = floor(now*HZ)%BUCKETS

	while curbucket~=newbucket do
		curbucket=curbucket+1
		if curbucket>=BUCKETS then
			curbucket=0
		end
	
		for timer,when in pairs(hash[curbucket]) do
			if when<soon then
				local delay=timer.delay
				if delay==nil then	-- has it been cancelled?
					hash[curbucket][timer] = nil
				else
					timer.method()	-- TODO: REAL CALL!
					local newbucket = floor((when+delay)*HZ) % BUCKETS
					if newbucket~=curbucket then
						hash[curbucket][timer] = nil
						hash[newbucket][timer] = when + delay
					else
						print "SAME!"	-- Shouldn't happen with test timers < BUCKETS/HZ (~13) second dura
					end
				end
			end
		end
	
	end	
	
end

function MikkTimer:ScheduleRepeatingTimer(object,method,delay)
	-- TODO: Accept delay=0 -> run asap only once
	assert(delay>=1/(HZ-0.99))
	local timer = { object=object, method=method, delay=delay }
	hash[ floor((now+delay)*HZ) % BUCKETS ][timer] = now + delay
	return timer
end

function MikkTimer:CancelTimer(timer)
	timer.delay = nil
end
