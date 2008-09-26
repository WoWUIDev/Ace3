--[[ $Id$ ]]
local MAJOR, MINOR = "AceEvent-3.0", 2
local AceEvent = LibStub:NewLibrary(MAJOR, MINOR)

if not AceEvent then return end

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")


AceEvent.frame = AceEvent.frame or CreateFrame("Frame", "AceEvent30Frame") -- our event frame
AceEvent.embeds = AceEvent.embeds or {} -- what objects embed this lib


-- APIs and registry for blizzard events, using CallbackHandler lib
local OnEventUsed, OnEventUnused

if not AceEvent.events then
	AceEvent.events = CallbackHandler:New(AceEvent, 
		"RegisterEvent", "UnregisterEvent", "UnregisterAllEvents",
		--[[OnUsed]]   function(self,eventname) self.frame:RegisterEvent(eventname) end,
		--[[OnUnused]] function(self,eventname) self.frame:UnregisterEvent(eventname) end
	)
end

-- APIs and registry for IPC messages, using CallbackHandler lib
if not AceEvent.messages then
	AceEvent.messages = CallbackHandler:New(AceEvent, 
		"RegisterMessage", "UnregisterMessage", "UnregisterAllMessages"
	)
	AceEvent.SendMessage = AceEvent.messages.Fire
end

--- embedding and embed handling
local mixins = {
	"RegisterEvent", "UnregisterEvent",
	"RegisterMessage", "UnregisterMessage",
	"SendMessage",
	"UnregisterAllEvents", "UnregisterAllMessages",
} 

-- AceEvent:Embed( target )
-- target (object) - target object to embed AceEvent in
--
-- Embeds AceEvent into the target object making the functions from the mixins list available on target:..
function AceEvent:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
end

-- AceEvent:OnEmbedDisable( target )
-- target (object) - target object that is being disabled
--
-- Unregister all events messages etc when the target disables.
-- this method should be called by the target manually or by an addon framework
function AceEvent:OnEmbedDisable(target)
	target:UnregisterAllEvents()
	target:UnregisterAllMessages()
end

-- Script to fire blizzard events into the event listeners
local events = AceEvent.events
AceEvent.frame:SetScript("OnEvent", function(this, event, ...)
	events:Fire(event, ...)
end)

--- Finally: upgrade our old embeds
for target, v in pairs(AceEvent.embeds) do
	AceEvent:Embed(target)
end
