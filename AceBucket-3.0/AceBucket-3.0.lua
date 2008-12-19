--- A bucket to catch events in. AceBucket-3.0 provides throttling of events that fire in bursts and
-- your addon only needs to know about the full burst.
-- This file is still on the TODO for complete documentation.
-- @class file
-- @name AceBucket-3.0
-- @release $Id$

--[[
	This Bucket implementation works as follows:
	-- Initially, no schedule is running, and its waiting for the first event to happen.
	-- The first event will start the bucket, and get the scheduler running, which will collect all
		events in the given interval. When that interval is reached, the bucket is pushed to the 
		callback and a new schedule is started. When a bucket is empty after its interval, the scheduler is 
		stopped, and the bucket is only listening for the next event to happen, basicly back in initial state.
]]

local MAJOR, MINOR = "AceBucket-3.0", 3
local AceBucket, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceBucket then return end -- No Upgrade needed

AceBucket.buckets = AceBucket.buckets or {}
AceBucket.embeds = AceBucket.embeds or {}

-- the libraries will be lazyly bound later, to avoid errors due to loading order issues
local AceEvent, AceTimer

-- local upvalues
local type = type
local next = next
local pairs = pairs
local select = select
local tonumber = tonumber
local tostring = tostring

local bucketCache = setmetatable({}, {__mode='k'})

--[[
	 xpcall safecall implementation
]]
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			 method = func
			 if not method then return end
			 ARGS = ...
			 return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", table.concat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {__index=function(self, argCount)
	local dispatcher = CreateDispatcher(argCount)
	rawset(self, argCount, dispatcher)
	return dispatcher
end})
Dispatchers[0] = function(func)
	return xpcall(func, errorhandler)
end
 
local function safecall(func, ...)
	return Dispatchers[select('#', ...)](func, ...)
end

-- FireBucket ( bucket )
--
-- send the bucket to the callback function and schedule the next FireBucket in interval seconds
local function FireBucket(bucket)
	local received = bucket.received
	
	-- we dont want to fire empty buckets
	if next(received) then
		local callback = bucket.callback
		if type(callback) == "string" then
			safecall(bucket.object[callback], bucket.object, received)
		else
			safecall(callback, received)
		end
		
		for k in pairs(received) do
			received[k] = nil
		end
		
		-- if the bucket was not empty, schedule another FireBucket in interval seconds
		bucket.timer = AceTimer.ScheduleTimer(bucket, FireBucket, bucket.interval, bucket)
	else -- if it was empty, clear the timer and wait for the next event
		bucket.timer = nil
	end
end

-- BucketHandler ( event, arg1 )
-- 
-- callback func for AceEvent
-- stores arg1 in the received table, and schedules the bucket if necessary
local function BucketHandler(self, event, arg1)
	if arg1 == nil then
		arg1 = "nil"
	end
	
	self.received[arg1] = (self.received[arg1] or 0) + 1
	
	-- if we are not scheduled yet, start a timer on the interval for our bucket to be cleared
	if not self.timer then
		self.timer = AceTimer.ScheduleTimer(self, FireBucket, self.interval, self)
	end
end

-- RegisterBucket( event, interval, callback, isMessage )
--
-- event(string or table) - the event, or a table with the events, that this bucket listens to
-- interval(int) - time between bucket fireings
-- callback(func or string) - function pointer, or method name of the object, that gets called when the bucket is cleared
-- isMessage(boolean) - register AceEvent Messages instead of game events
local function RegisterBucket(self, event, interval, callback, isMessage)
	-- try to fetch the librarys
	if not AceEvent or not AceTimer then 
		AceEvent = LibStub:GetLibrary("AceEvent-3.0", true)
		AceTimer = LibStub:GetLibrary("AceTimer-3.0", true)
		if not AceEvent or not AceTimer then
			error(MAJOR .. " requires AceEvent-3.0 and AceTimer-3.0", 3)
		end
	end
	
	if type(event) ~= "string" and type(event) ~= "table" then error("Usage: RegisterBucket(event, interval, callback): 'event' - string or table expected.", 3) end
	if not callback then
		if type(event) == "string" then
			callback = event
		else
			error("Usage: RegisterBucket(event, interval, callback): cannot omit callback when event is not a string.", 3)
		end
	end
	if not tonumber(interval) then error("Usage: RegisterBucket(event, interval, callback): 'interval' - number expected.", 3) end
	if type(callback) ~= "string" and type(callback) ~= "function" then error("Usage: RegisterBucket(event, interval, callback): 'callback' - string or function or nil expected.", 3) end
	if type(callback) == "string" and type(self[callback]) ~= "function" then error("Usage: RegisterBucket(event, interval, callback): 'callback' - method not found on target object.", 3) end
	
	local bucket = next(bucketCache)
	if bucket then
		bucketCache[bucket] = nil
	else
		bucket = { handler = BucketHandler, received = {} }
	end
	bucket.object, bucket.callback, bucket.interval = self, callback, tonumber(interval)
	
	local regFunc = isMessage and AceEvent.RegisterMessage or AceEvent.RegisterEvent
	
	if type(event) == "table" then
		for _,e in pairs(event) do
			regFunc(bucket, e, "handler")
		end
	else
		regFunc(bucket, event, "handler")
	end
	
	local handle = tostring(bucket)
	AceBucket.buckets[handle] = bucket
	
	return handle
end

-- AceBucket:RegisterBucketEvent(event, interval, callback)
-- AceBucket:RegisterBucketMessage(message, interval, callback)
--
-- event/message(string or table) -  the event, or a table with the events, that this bucket listens to
-- interval(int) - time between bucket fireings
-- callback(func or string) - function pointer, or method name of the object, that gets called when the bucket is cleared
function AceBucket:RegisterBucketEvent(event, interval, callback)
	return RegisterBucket(self, event, interval, callback, false)
end

function AceBucket:RegisterBucketMessage(message, interval, callback)
	return RegisterBucket(self, message, interval, callback, true)
end

-- AceBucket:UnregisterBucket ( handle )
-- handle - the handle of the bucket as returned by RegisterBucket*
--
-- will unregister any events and messages from the bucket and clear any remaining data
function AceBucket:UnregisterBucket(handle)
	local bucket = AceBucket.buckets[handle]
	if bucket then
		AceEvent.UnregisterAllEvents(bucket)
		AceEvent.UnregisterAllMessages(bucket)
		
		-- clear any remaining data in the bucket
		for k in pairs(bucket.received) do
			bucket.received[k] = nil
		end
		
		if bucket.timer then
			AceTimer.CancelTimer(bucket, bucket.timer)
			bucket.timer = nil
		end
		
		AceBucket.buckets[handle] = nil
		-- store our bucket in the cache
		bucketCache[bucket] = true
	end
end

-- AceBucket:UnregisterAllBuckets()
-- 
-- will unregister all bucketed events.
function AceBucket:UnregisterAllBuckets()
	-- hmm can we do this more efficient? (it is not done often so shouldn't matter much)
	for handle, bucket in pairs(AceBucket.buckets) do
		if bucket.object == self then
			AceBucket.UnregisterBucket(self, handle)
		end
	end
end



--- embedding and embed handling

local mixins = {
	"RegisterBucketEvent",
	"RegisterBucketMessage", 
	"UnregisterBucket",
	"UnregisterAllBuckets",
} 

-- AceBucket:Embed( target )
-- target (object) - target object to embed AceBucket in
--
-- Embeds AceBucket into the target object making the functions from the mixins list available on target:..
function AceBucket:Embed( target )
	for _, v in pairs( mixins ) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

--AceBucket:OnEmbedDisable( target )
-- target (object) - target object that AceBucket is embedded in.
--
-- Disables all buckets registered on the object
function AceBucket:OnEmbedDisable( target )
	target:UnregisterAllBuckets()
end

for addon in pairs(AceBucket.embeds) do
	AceBucket:Embed(addon)
end
