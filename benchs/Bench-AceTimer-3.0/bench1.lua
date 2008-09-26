-- What did I do with this bench:
-- 1. Log in WoW with this addon loaded.
-- 2. Find somewhere and stare at the wall to have a more constant FPS, check the FPS value.
-- 3. type "/test start" to start running 2000 OnUpdate frames, check how much the FPS suffers.
-- 4. type "/test stop" to hide frames, make sure the FPS went back the original value.
-- 5. type "/test2 start" to start 2000 AceTimer-3.0 timers, check the FPS.
-- 6. type "/test2 stop" to cancel the timers, make sure the FPS went back to original value.


-- Make sure AceTimer-3.0's Hz value supports this delay.
local DELAY = 0.05

-- OnUpdate Frames.
do
	local mainFrame = CreateFrame("Frame")
	local frames = {}

	local count = 0
	local function DoSomething()
		count = count + 1
	end

	local delay = 0
	local function OnUpdate(frame,elapsed)
		delay = delay + elapsed
		if delay > DELAY then
			delay = 0
			DoSomething()
		end
	end

	local function CreateNewFrame()
		local frame = CreateFrame("Frame")
		frame:SetScript("OnUpdate", OnUpdate)
		table.insert(frames,frame)
		frame.id = #frames
		return frame
	end

	local function SlashParser(cmd)
		if cmd == 'start' then
			if #frames == 0 then
				ChatFrame1:AddMessage("Creating 2000 frames.")
				for i=1,2000 do
					local frame = CreateNewFrame()
					frame:Show()
				end
			else
				ChatFrame1:AddMessage("Showing all frames.")
				for i, frame in ipairs(frames) do
					frame:Show()
				end
			end
		elseif cmd == 'stop' then
			ChatFrame1:AddMessage("Hiding all frames.")
			for i, frame in ipairs(frames) do
				frame:Hide()
			end
		elseif cmd == 'stat' then
			ChatFrame1:AddMessage(count)
		end
	end

	SlashCmdList["TESTONUPDATE"] = SlashParser
	SLASH_TESTONUPDATE1 = "/test"
end


-- AceTimer-3.0
do
	local Timer = LibStub("AceTimer-3.0")
	local timers = {}
	local addon = {}

	local count = 0
	addon.DoSomething = function()
		count = count + 1 
	end

	local function CreateNewTimer()
		local timer = Timer.ScheduleRepeatingTimer(addon,"DoSomething",DELAY)
		table.insert(timers,timer)
		return timer
	end

	local function SlashParser(cmd)
		if cmd == 'start' then
			ChatFrame1:AddMessage("Creating 2000 timers.")
			for i=1,2000 do
				CreateNewTimer()
			end
		elseif cmd == 'stop' then
			ChatFrame1:AddMessage("Cancelling all timers.")
			Timer.CancelAllTimers(addon)
		elseif cmd == 'stat' then
			ChatFrame1:AddMessage(count)
		end
	end

	SlashCmdList["TESTACETIMER"] = SlashParser
	SLASH_TESTACETIMER1 = "/test2"
end
