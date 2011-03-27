dofile("wow_api.lua")
dofile("../LibStub/LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceComm-3.0/ChatThrottleLib.lua")
dofile("../AceComm-3.0/AceComm-3.0.lua")

switches = arg[1] or ""

local VERBOSE,n = strfind(switches, "vv*")	-- "v" anywhere in the first arg
if VERBOSE then VERBOSE = n-VERBOSE+1 end -- "v"=1, "vv"=2, ...




local AceComm = LibStub("AceComm-3.0")

local function printf(format, ...)
	print(format:format(...))
end

assert(RegisterAddonMessagePrefix)

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
-- Disable ChatThrottleLib?
--


local NOCTL = strfind(switches, "t")

if NOCTL then	-- "t" anywhere in the first arg
	print("NOTE: Testing mode without ChatThrottleLib!")
	-- Replace ChatThrottleLib with a dummy passthrough for testing purposes
	function ChatThrottleLib:SendAddonMessage(prio, prefix, text, chattype, target, queueName)
		SendAddonMessage(prefix, text, chattype, target)
	end
	function ChatThrottleLib:SendChatMessage(prio, prefix,   text, chattype, language, destination, queueName)
		SendChatMessage(text, chattype, language, destination)
	end
end




-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
-- Basic AceComm splitting/queueing tests
--

do


	local addon1 = {}
	local prefix1 = "Test"

	local addon2 = {}
	local prefix2 = "TestTest"


	local data = ""
	local received = {}
	local chartot = 0

	AceComm:Embed(addon1)

	local received1 = {}
	function addon1:OnCommReceived(prefix, message, distribution, sender)
		assert(self==addon1)
		assert(prefix == prefix1)
		assert(distribution == "RAID", dump(distribution))
		tinsert(received, message)
		tinsert(received1, message)
		assert(#message == #received1)
		assert(message == strsub(data,1,#message))
		chartot=chartot+#message
	end

	AceComm:Embed(addon2)

	local received2 = {}
	function addon2:OnCommReceived(prefix, message, distribution, sender)
		assert(self==addon2)
		assert(prefix == prefix2)
		assert(distribution == "GROUP", dump(distribution))
		tinsert(received, message)
		tinsert(received2, message)
		assert(#message == #received2+9)
		local control = string.char((#message-9)%32+1)
		assert(message == control.."OogaBoog"..strsub(data,1,#message-9))
		chartot=chartot+#message
	end

	addon1:RegisterComm(prefix1)
	addon2:RegisterComm(prefix2)


	local MSGS=255*4  -- length 1..1000, covers all of: Single, First+Last, First+Next+Last, First+Next+Next+Last
	data=string.char(math.random(10, 255))
	for i = 1,MSGS do
		data = data .. string.char(math.random(1, 255))
	end



	-- First send a boatload of data without pumping OnUpdates to CTL

	for i = 1,MSGS do
		if VERBOSE and VERBOSE>=2 then print("Sending len "..i) end
		addon1:SendCommMessage(prefix1, strsub(data,1,i), "RAID", nil)
		local control = string.char(i%32+1)
		addon2:SendCommMessage(prefix2, control.."OogaBoog"..strsub(data,1,i), "GROUP", nil)
	end

	-- Now start pumping OnUpdates; there should be plenty of stuff queued in CTL, and it should all be sent in the right order!
	if not NOCTL then
		local sampledmid
		local esttime = ( (MSGS+20)*MSGS*2/1.62 ) / ChatThrottleLib.MAX_CPS
		local midpos = esttime * 0.5
		local latepos = esttime * 0.9

		local lastchartot=0
		local dispinterval=20

		local t=0
		if VERBOSE then
			print("time","rcvtot","rcv1","rcv2","cps","CTL choke")
		end
		while #received < MSGS*2 do
			WoWAPI_FireUpdate(t)
			if t%dispinterval==0 then
				local cps = floor((chartot-lastchartot)/dispinterval)
				if VERBOSE then print(t..": ",#received, #received1, #received2, cps, ChatThrottleLib.bChoking) end
				lastchartot=chartot
				if t>midpos then	-- when our bandwidth isn't mostly eaten by headers and stuff
					assert(cps>=ChatThrottleLib.MAX_CPS*0.6 and cps<ChatThrottleLib.MAX_CPS*1.1, cps)
				end
			end
			if t>midpos and not sampledmid then
				sampledmid=true
				assert(#received > MSGS*1.33 and #received < MSGS*1.5, dump(#received, MSGS*1.33, MSGS*1.5))	-- would be around 1 if we sent the same amount of data in each message, but we send less around the start
			end
			if t>midpos and t<latepos then
				-- prefix2 should have slightly less data transferred since the prefix name itself is longer and uses more bandwidth compared to useful data
				assert(#received2 >= #received1*0.975 and #received2 < #received1*0.999, #received1.." : "..#received2)	
			end
			t=t+1
		end

		assert(t>=esttime*0.9 and t<=esttime*1.1, dump(t, esttime))

		assert(sampledmid)
		
	end

	assert(#received==MSGS*2)
	assert(#received1==MSGS and #received2==MSGS)

	function addon1:OnCommReceived()
		assert(false,"We shouldn't receive more here now!!!!")
	end
	
	function addon2:OnCommReceived()
		assert(false,"We shouldn't receive more here now!!!!")
	end

	addon1:UnregisterComm(prefix1)
	addon2:UnregisterAllComm()
	
end


AceComm:SendCommMessage("Test", "This should not be received", "RAID", nil)
AceComm:SendCommMessage("TestTest", "This should not be received", "GROUP", nil)

WoWAPI_FireUpdate(GetTime()+100)


-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
-- Unit test escaping
--

local addon = AceComm:Embed({})
local comms = {}
function addon:OnCommReceived(...)
	tinsert(comms, {...})
	-- print("OnCommReceived", ...)
end
addon:RegisterComm("MyPrefix")

local frame = CreateFrame("Frame")
local events = {}
frame:SetScript("OnEvent", function(self,event,...)
	tinsert(events, {...})
	-- print("CHAT_MSG_ADDON", ...)
end)
frame:RegisterEvent("CHAT_MSG_ADDON")

for i=1,9 do
	local control = string.char(i)
	AceComm:SendCommMessage("MyPrefix", control.."asdf", "RAID")
	WoWAPI_FireUpdate(GetTime()+100)

	assert(#comms==i)
	assert(comms[i][1]=="MyPrefix")
	assert(comms[i][2]==control.."asdf")
	assert(comms[i][3]=="RAID")
	assert(comms[i][4]=="Sender")

	assert(#events==i)
	assert(events[i][1]=="MyPrefix")
	assert(events[i][2]=="\004"..control.."asdf")
	assert(events[i][3]=="RAID")
	assert(events[i][4]=="Sender")
end

-----------------------------------------------------------------------
print "OK"
