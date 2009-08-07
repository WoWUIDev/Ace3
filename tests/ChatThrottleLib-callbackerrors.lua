dofile("wow_api.lua")
dofile("../AceComm-3.0/ChatThrottleLib.lua")




-- Test errors in CTL callbacks - messages should still be delivered!
do
	WoWAPI_FireUpdate(0)	-- 0 o'clock

	local frame=CreateFrame("Frame")
	frame:RegisterEvent("CHAT_MSG_ADDON")
	
	-- Queue 2 messages in sequence. They should pop out at different times
	
	ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg1", "SAY", nil, nil,
		function() error("test error 1") end
	)
	ChatThrottleLib:SendAddonMessage("NORMAL", "MyPrefix", "msg2", "SAY", nil, nil,
		function() error("test error 2") end
	)

	local n=0
	frame:SetScript("OnEvent", function(self, event, prefix, msg)
		assert(msg=="msg1")
		n=n+1
	end)
	
	local ok,msg = pcall(WoWAPI_FireUpdate,1)	-- 1 o'clock. CTL starts up in "hard clamping mode", so should only allow 80 CPS for the first few seconds
	assert(not ok)
	assert(strmatch(msg,"test error 1"), msg)
	assert(n==1)
	
	local ok,msg = pcall(WoWAPI_FireUpdate,1)	-- 1 o'clock. CTL starts up in "hard clamping mode", so should only allow 80 CPS for the first few seconds
	assert(ok)
	assert(n==1)	-- WE SHOULD NOT SEE ANOTHER MESSAGE YET
	
	frame:SetScript("OnEvent", function(self, event, prefix, msg)
		assert(msg=="msg2")
		n=n+1
	end)

	local ok,msg = pcall(WoWAPI_FireUpdate,2)	-- 2 o'clock. CTL starts up in "hard clamping mode", so should only allow 80 CPS for the first few seconds
	assert(not ok)
	assert(strmatch(msg,"test error 2"), msg)
	assert(n==2)
	
	
	-- Now queue 2 messages up and hop 2 seconds into the future. (And pulse there twice)

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






	-- Now we jump a loooong time into the future and make room for an immediate burst
	-- Errors should happen immediately on :Send now!

	WoWAPI_FireUpdate(100)
	
	n=0
	frame:SetScript("OnEvent", function(self, event, prefix, msg)
		n=n+1
		assert(msg=="msg"..n, msg)
	end)

	n2=0
	local function callbackFn(arg)
		n2=n2+1
		assert(n2==n)
		error("test error "..n2)
	end
	for i=1,50 do	-- 50 * ~50 = ~2500 bytes, max burst is 4000
		local ok,msg = pcall(ChatThrottleLib.SendAddonMessage, ChatThrottleLib,
			"NORMAL", "MyPrefix", "msg"..i, "SAY", nil, nil, callbackFn)
		assert(not ok)
		assert(strmatch(msg, "test error "..n2), msg)
		assert(n==i, n)
		assert(n2==i, n2)
	end
	assert(n==50 and n2==50)
	
	WoWAPI_FireUpdate(101)	-- shouldn't cause anything untowards to happen

	assert(n==50 and n2==50)
	
	frame:UnregisterEvent("CHAT_MSG_ADDON")
end



------------------------------------------------------------------------------
print ("OK")