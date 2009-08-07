dofile("wow_api.lua")


local ORIG_SendChatMessage = _G.SendChatMessage

------------------------------------------------------------------------
-- Pull in v14
dofile("ChatThrottleLibs/ChatThrottleLib-v14.lua")


local AfterV14_SendChatMessage = _G.SendChatMessage
assert(AfterV14_SendChatMessage ~= ORIG_SendChatMessage)


------------------------------------------------------------------------
-- Queue up some messages - they should live through the upgrades below!

local frame=CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function() error("Shouldn't see this yet!") end)

ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg1", "SAY")
ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg2", "SAY")

WoWAPI_FireUpdate(0)	-- 0 o'clock - no bandwidth available yet



------------------------------------------------------------------------
-- Now pull in v20, should be straightforward, will still use the old hook

dofile("ChatThrottleLibs/ChatThrottleLib-v20.lua")

local AfterV20_SendChatMessage = _G.SendChatMessage
assert(AfterV20_SendChatMessage == AfterV14_SendChatMessage)




------------------------------------------------------------------------
-- Now pull in v21+, which will complain about v14 being ANCIENT and attempt to restore the original handlers

local origprint = print
local nAncient = 0
_G.print = function(...)
	if strmatch(..., "ANCIENT") then
		nAncient = nAncient + 1
	else
		return origprint(...)
	end
end
	
dofile("../AceComm-3.0/ChatThrottleLib.lua")

assert(nAncient==1)	-- did it complain?

_G.print = origprint

local AfterV21_SendChatMessage = _G.SendChatMessage
assert(AfterV21_SendChatMessage ~= AfterV14_SendChatMessage)




------------------------------------------------------------------------
-- Now start pumping OnUpdates and see if our messages survived!

local n=0
frame:SetScript("OnEvent", function(self, event, prefix, msg)
	assert(msg=="msg1")
	n=n+1
end)

WoWAPI_FireUpdate(1)	-- 1 o'clock. CTL starts up in "hard clamping mode", so should only allow 80 CPS for the first few seconds
assert(n==1)

WoWAPI_FireUpdate(1)	-- 1 o'clock again
assert(n==1)	-- WE SHOULD NOT SEE ANOTHER MESSAGE YET

frame:SetScript("OnEvent", function(self, event, prefix, msg)
	assert(msg=="msg2")
	n=n+1
end)

WoWAPI_FireUpdate(2)	-- 2 o'clock. CTL starts up in "hard clamping mode", so should only allow 80 CPS for the first few seconds
assert(n==2)


------------------------------------------------------------------------
-- Now queue 2 messages up and hop 2 seconds into the future. (And pulse there twice)
-- (Basic functionality test)

ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg3", "WHISPER", "target1", nil,
	function() error("test error 3") end
)
ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg4", "WHISPER", "target2", nil,
	function() error("test error 4") end
)



frame:SetScript("OnEvent", function(self, event, prefix, msg)
	assert(msg=="msg3")
	n=n+1
end)

local ok,msg = pcall(WoWAPI_FireUpdate,4)	-- hop to 4 o'clock
assert(not ok)
assert(strmatch(msg,"test error 3"), msg)
assert(n==3)

frame:SetScript("OnEvent", function(self, event, prefix, msg)
	assert(msg=="msg4")
	n=n+1
end)

local ok,msg = pcall(WoWAPI_FireUpdate,4)	-- again! it should still get the next event off of the queue.
assert(not ok)
assert(strmatch(msg,"test error 4"), msg)
assert(n==4)





------------------------------------------------------------------------
-- Now we jump a loooong time into the future and make room for an immediate burst
-- (Basic functionality test)

WoWAPI_FireUpdate(100)

n=0
frame:SetScript("OnEvent", function(self, event, prefix, msg)
	n=n+1
	assert(msg=="msg"..n, msg)
end)

for i=1,50 do	-- 50 * ~50 = ~2500 bytes, max burst is 4000
	ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg"..i, "SAY")
	assert(n==i, n)
end
assert(n==50)

WoWAPI_FireUpdate(101)	-- shouldn't cause anything untowards to happen

assert(n==50)




------------------------------------------------------------------------------
print ("OK")