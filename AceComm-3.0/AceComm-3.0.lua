--- **AceComm-3.0** allows you to send messages of unlimited length over the addon comm channels.
-- It'll automatically split the messages into multiple parts and rebuild them on the receiving end.\\
-- **ChatThrottleLib** is of course being used to avoid being disconnected by the server.
--
-- AceComm-3.0 can be embeded into your addon, either explicitly by calling AceComm:Embed(MyAddon) or by 
-- specifying it as an embeded library in your AceAddon. All functions will be available on your addon object
-- and can be accessed directly, without having to explicitly call AceComm itself.\\
-- It is recommended to embed AceComm, otherwise you'll have to specify a custom `self` on all calls you
-- make into AceComm.
-- @class file
-- @name AceComm-3.0
-- @release $Id$

--[[ AceComm-3.0

TODO: Time out old data rotting around from dead senders? Not a HUGE deal since the number of possible sender names is somewhat limited.

]]

local MAJOR, MINOR = "AceComm-3.0", 5
	
local AceComm,oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceComm then return end

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")
local CTL = assert(ChatThrottleLib, "AceComm-3.0 requires ChatThrottleLib")

local type = type
local strsub = string.sub
local strfind = string.find
local tinsert = table.insert
local tconcat = table.concat

AceComm.embeds = AceComm.embeds or {}

-- for my sanity and yours, let's give the message type bytes names
local MSG_MULTI_FIRST = "\001"
local MSG_MULTI_NEXT  = "\002"
local MSG_MULTI_LAST  = "\003"

AceComm.multipart_origprefixes = AceComm.multipart_origprefixes or {} -- e.g. "Prefix\001"="Prefix", "Prefix\002"="Prefix"
AceComm.multipart_reassemblers = AceComm.multipart_reassemblers or {} -- e.g. "Prefix\001"="OnReceiveMultipartFirst"

-- the multipart message spool: indexed by a combination of sender+distribution+
AceComm.multipart_spool = AceComm.multipart_spool or {} 

--- Register for Addon Traffic on a specified prefix
-- @param prefix A printable character (\032-\255) classification of the message (typically AddonName or AddonNameEvent)
-- @param method Callback to call on message reception: Function reference, or method name (string) to call on self. Defaults to "OnCommReceived"
function AceComm:RegisterComm(prefix, method)
	if method == nil then
		method = "OnCommReceived"
	end

	return AceComm._RegisterComm(self, prefix, method)	-- created by CallbackHandler
end

--- Send a message over the Addon Channel
-- @param prefix A printable character (\032-\255) classification of the message (typically AddonName or AddonNameEvent)
-- @param text Data to send, nils (\000) not allowed. Any length.
-- @param distribution Addon channel, e.g. "RAID", "GUILD", etc; see SendAddonMessage API
-- @param target Destination for some distributions; see SendAddonMessage API
-- @param prio OPTIONAL: ChatThrottleLib priority, "BULK", "NORMAL" or "ALERT". Defaults to "NORMAL".
function AceComm:SendCommMessage(prefix, text, distribution, target, prio)
	prio = prio or "NORMAL"	-- pasta's reference implementation had different prio for singlepart and multipart, but that's a very bad idea since that can easily lead to out-of-sequence delivery!
	if not( type(prefix)=="string" and
			type(text)=="string" and
			type(distribution)=="string" and
			(target==nil or type(target)=="string") and
			(prio=="BULK" or prio=="NORMAL" or prio=="ALERT") 
		) then
		error('Usage: SendCommMessage(addon, "prefix", "text", "distribution"[, "target"[, "prio"]])', 2)
	end
	
	if strfind(prefix, "[\001-\003]") then
		error("SendCommMessage: Characters \\001--\\003) in prefix are reserved for AceComm metadata", 2)
	end


	local textlen = #text
	local maxtextlen = 254 - #prefix	-- 254 is the max length of prefix + text that can be sent in one message
	local queueName = prefix..distribution..(target or "")

	if textlen <= maxtextlen then
		-- fits all in one message
		CTL:SendAddonMessage(prio, prefix, text, distribution, target, queueName)
	else
		maxtextlen = maxtextlen - 1	-- 1 extra byte for part indicator in suffix

		-- first part
		local chunk = strsub(text, 1, maxtextlen)
		CTL:SendAddonMessage(prio, prefix..MSG_MULTI_FIRST, chunk, distribution, target, queueName)

		-- continuation
		local pos = 1+maxtextlen
		local prefix2 = prefix..MSG_MULTI_NEXT

		while pos+maxtextlen <= textlen do
			chunk = strsub(text, pos, pos+maxtextlen-1)
			CTL:SendAddonMessage(prio, prefix2, chunk, distribution, target, queueName)
			pos = pos + maxtextlen
		end
		
		-- final part
		chunk = strsub(text, pos)
		CTL:SendAddonMessage(prio, prefix..MSG_MULTI_LAST, chunk, distribution, target, queueName)
	end
end


----------------------------------------
-- Message receiving
----------------------------------------

do
	local compost = setmetatable({}, {__mode = "k"})
	local function new()
		local t = next(compost)
		if t then 
			compost[t]=nil
			for i=#t,3,-1 do	-- faster than pairs loop. don't even nil out 1/2 since they'll be overwritten
				t[i]=nil
			end
			return t
		end
		
		return {}
	end
	
	local function lostdatawarning(prefix,sender,where)
		DEFAULT_CHAT_FRAME:AddMessage(MAJOR..": Warning: lost network data regarding '"..tostring(prefix).."' from '"..tostring(sender).."' (in "..where..")")
	end

	function AceComm:OnReceiveMultipartFirst(prefix, message, distribution, sender)
		local key = prefix.."\t"..distribution.."\t"..sender	-- a unique stream is defined by the prefix + distribution + sender
		local spool = AceComm.multipart_spool
		
		--[[
		if spool[key] then 
			lostdatawarning(prefix,sender,"First")
			-- continue and overwrite
		end
		--]]
		
		spool[key] = message  -- plain string for now
	end

	function AceComm:OnReceiveMultipartNext(prefix, message, distribution, sender)
		local key = prefix.."\t"..distribution.."\t"..sender	-- a unique stream is defined by the prefix + distribution + sender
		local spool = AceComm.multipart_spool
		local olddata = spool[key]
		
		if not olddata then
			--lostdatawarning(prefix,sender,"Next")
			return
		end

		if type(olddata)~="table" then
			-- ... but what we have is not a table. So make it one. (Pull a composted one if available)
			local t = new()
			t[1] = olddata    -- add old data as first string
			t[2] = message    -- and new message as second string
			spool[key] = t    -- and put the table in the spool instead of the old string
		else
			tinsert(olddata, message)
		end
	end

	function AceComm:OnReceiveMultipartLast(prefix, message, distribution, sender)
		local key = prefix.."\t"..distribution.."\t"..sender	-- a unique stream is defined by the prefix + distribution + sender
		local spool = AceComm.multipart_spool
		local olddata = spool[key]
		
		if not olddata then
			--lostdatawarning(prefix,sender,"End")
			return
		end

		spool[key] = nil
		
		if type(olddata) == "table" then
			-- if we've received a "next", the spooled data will be a table for rapid & garbage-free tconcat
			tinsert(olddata, message)
			AceComm.callbacks:Fire(prefix, tconcat(olddata, ""), distribution, sender)
			compost[olddata] = true
		else
			-- if we've only received a "first", the spooled data will still only be a string
			AceComm.callbacks:Fire(prefix, olddata..message, distribution, sender)
		end
	end
end






----------------------------------------
-- Embed CallbackHandler
----------------------------------------

if not AceComm.callbacks then
	-- ensure that 'prefix to watch' table is consistent with registered
	-- callbacks
	AceComm.__prefixes = {}

	AceComm.callbacks = CallbackHandler:New(AceComm,
						"_RegisterComm",
						"UnregisterComm",
						"UnregisterAllComm")
end

function AceComm.callbacks:OnUsed(target, prefix)
	AceComm.multipart_origprefixes[prefix..MSG_MULTI_FIRST] = prefix
	AceComm.multipart_reassemblers[prefix..MSG_MULTI_FIRST] = "OnReceiveMultipartFirst"
	
	AceComm.multipart_origprefixes[prefix..MSG_MULTI_NEXT] = prefix
	AceComm.multipart_reassemblers[prefix..MSG_MULTI_NEXT] = "OnReceiveMultipartNext"
	
	AceComm.multipart_origprefixes[prefix..MSG_MULTI_LAST] = prefix
	AceComm.multipart_reassemblers[prefix..MSG_MULTI_LAST] = "OnReceiveMultipartLast"
end

function AceComm.callbacks:OnUnused(target, prefix)
	AceComm.multipart_origprefixes[prefix..MSG_MULTI_FIRST] = nil
	AceComm.multipart_reassemblers[prefix..MSG_MULTI_FIRST] = nil
	
	AceComm.multipart_origprefixes[prefix..MSG_MULTI_NEXT] = nil
	AceComm.multipart_reassemblers[prefix..MSG_MULTI_NEXT] = nil
	
	AceComm.multipart_origprefixes[prefix..MSG_MULTI_LAST] = nil
	AceComm.multipart_reassemblers[prefix..MSG_MULTI_LAST] = nil
end

local function OnEvent(this, event, ...)
	if event == "CHAT_MSG_ADDON" then
		local prefix,message,distribution,sender = ...
		local reassemblername = AceComm.multipart_reassemblers[prefix]
		if reassemblername then
			-- multipart: reassemble
			local aceCommReassemblerFunc = AceComm[reassemblername]
			local origprefix = AceComm.multipart_origprefixes[prefix]
			aceCommReassemblerFunc(AceComm, origprefix, message, distribution, sender)
		else
			-- single part: fire it off immediately and let CallbackHandler decide if it's registered or not
			AceComm.callbacks:Fire(prefix, message, distribution, sender)
		end
	else
		assert(false, "Received "..tostring(event).." event?!")
	end
end

AceComm.frame = AceComm.frame or CreateFrame("Frame", "AceComm30Frame")
AceComm.frame:SetScript("OnEvent", OnEvent)
AceComm.frame:UnregisterAllEvents()
AceComm.frame:RegisterEvent("CHAT_MSG_ADDON")


----------------------------------------
-- Base library stuff
----------------------------------------

local mixins = {
	"RegisterComm",
	"UnregisterComm",
	"UnregisterAllComm",
	"SendCommMessage",
}

-- Embeds AceComm-3.0 into the target object making the functions from the mixins list available on target:..
-- @param target target object to embed AceComm-3.0 in
function AceComm:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

function AceComm:OnEmbedDisable(target)
	target:UnregisterAllComm()
end

-- Update embeds
for target, v in pairs(AceComm.embeds) do
	AceComm:Embed(target)
end
