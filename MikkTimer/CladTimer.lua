
CladTimer={}

local GetTime = GetTime

local heap = {}
local timers = {}

CladTimer.heap=heap
CladTimer.timers=timers


local function HeapSwap(i1, i2)
	heap[i1], heap[i2] = heap[i2], heap[i1]
end

local function HeapBubbleUp(index)
	while index > 1 do
		local parentIndex = math.floor(index / 2)
		if heap[index].timeToFire < heap[parentIndex].timeToFire then
			HeapSwap(index, parentIndex)
			index = parentIndex
		else
			break
		end
	end
end

local function HeapBubbleDown(index)
	while 2 * index <= heap.lastIndex do
		local leftIndex = 2 * index
		local rightIndex = leftIndex + 1
		local current = heap[index]
		local leftChild = heap[leftIndex]
		local rightChild = heap[rightIndex]

		if not rightChild then
			if leftChild.timeToFire < current.timeToFire then
				HeapSwap(index, leftIndex)
				index = leftIndex
			else
				break
			end
		else
			if leftChild.timeToFire < current.timeToFire or
			   rightChild.timeToFire < current.timeToFire then
				if leftChild.timeToFire < rightChild.timeToFire then
					HeapSwap(index, leftIndex)
					index = leftIndex
				else
					HeapSwap(index, rightIndex)
					index = rightIndex
				end
			else
				break
			end
		end
	end
end

function CladTimer:Pulse()
	local schedule = heap[1]
	while schedule and schedule.timeToFire < GetTime() do
		if schedule.cancelled then
			HeapSwap(1, heap.lastIndex)
			heap[heap.lastIndex] = nil
			heap.lastIndex = heap.lastIndex - 1
			HeapBubbleDown(1)
		else
			--[[
			if schedule.args then
				safecall(schedule.func, schedule.name, unpack(schedule.args))
			else
				safecall(schedule.func, schedule.name)
			end
			]]
			schedule.func() -- TODO: REAL CALL!
			
			if schedule.repeating then
				schedule.timeToFire = schedule.timeToFire + schedule.repeating
				HeapBubbleDown(1)
			else
				HeapSwap(1, heap.lastIndex)
				heap[heap.lastIndex] = nil
				heap.lastIndex = heap.lastIndex - 1
				HeapBubbleDown(1)
				timers[schedule.name] = nil
			end
		end
		schedule = heap[1]
	end
	-- if not schedule then frame:Hide() end
end

function CladTimer:ScheduleTimer(name, func, delay, ...)
	--[[
	argcheck(self, 1, "table")
	argcheck(name, 2, "string")
	argcheck(func, 3, "function")
	argcheck(delay, 4, "number")
	]]

	if CladTimer:IsTimerScheduled(name) then
		CladTimer:CancelTimer(name)
	end

	local schedule = {}
	timers[name] = schedule
	schedule.timeToFire = GetTime() + delay
	schedule.func = func
	schedule.name = name
	if select('#', ...) ~= 0 then
		schedule.args = { ... }
	end

	if heap.lastIndex then
		heap.lastIndex = heap.lastIndex + 1
	else
		heap.lastIndex = 1
	end
	heap[heap.lastIndex] = schedule
	HeapBubbleUp(heap.lastIndex)
	--[[
	if not frame:IsShown() then
		frame:Show()
	end
	]]
end

function CladTimer:ScheduleRepeatingTimer(name, func, delay, ...)
	CladTimer:ScheduleTimer(name, func, delay, ...)
	timers[name].repeating = delay
end

function CladTimer:IsTimerScheduled(name)
	--[[
	argcheck(self, 1, "table")
	argcheck(name, 2, "string")
	]]
	local schedule = timers[name]
	if schedule then
		return true, schedule.timeToFire - GetTime()
	else
		return false
	end
end

function CladTimer:CancelTimer(name)
	--[[
	argcheck(self, 1, "table")
	argcheck(name, 2, "string")
	]]
	local schedule = timers[name]
	if not schedule then return end
	schedule.cancelled = true
	timers[name] = nil
end
