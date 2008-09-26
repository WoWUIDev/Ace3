--[[ $Id$ ]]

--[[ AceComm-3.0 proof-of-concept
]]

local MAJOR, MINOR = "AceComm-3.0", 0
	
local AceComm, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceComm then return end

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")

local CTL = ChatThrottleLib
local single_prio = "NORMAL"
local multipart_prio = "BULK"

local pairs = pairs
local ceil = math.ceil
local strsub = string.sub

AceComm.frame = AceComm.frame or CreateFrame("Frame", "AceComm30Frame")
AceComm.embeds = AceComm.embeds or {}
AceComm.__incomplete_data = AceComm.__incomplete_data or {}
AceComm.__prefixes = AceComm.__prefixes or {}
AceComm.__original_prefix = AceComm.__original_prefix or {}

----------------------------------------
-- abbreviated prefix metadata for quick lookup in CHAT_MSG_ADDON
----------------------------------------

local message_types = {
	["\001A"] = "multipart_begin",
	["\001B"] = "multipart_continue",
	["\001C"] = "multipart_end",
}

local message_type_rev = {
	["multipart_begin"] = "\001A",
	["multipart_continue"] = "\001B",
	["multipart_end"] = "\001C",
}


----------------------------------------
-- Callbacks
----------------------------------------

if not AceComm.callbacks then
	-- ensure that 'prefix to watch' table is consistent with registered
	-- callbacks
	AceComm.__prefixes = {}

	function AceComm:PrefixUsed(prefix)
		local prefixes = self.__prefixes
		local original_prefix = self.__original_prefix
		prefixes[prefix] = true
		for k, v in pairs(message_types) do
			local p = prefix .. k
			prefixes[p] = v
			original_prefix[p] = prefix
		end
	end

	function AceComm:PrefixUnused(prefix)
		local prefixes = self.__prefixes
		local original_prefix = self.__original_prefix
		prefixes[prefix] = nil
		for k, v in pairs(message_types) do
			local p = prefix .. k
			prefixes[p] = nil
			original_prefix[p] = nil
		end
	end

	AceComm.callbacks = CallbackHandler:New(AceComm,
						"_RegisterComm",
						"UnregisterComm",
						"UnregisterAllComm",
						AceComm.PrefixUsed,
						AceComm.PrefixUnused)

	AceComm.MessageCompleted = AceComm.callbacks.Fire
end

function AceComm.RegisterComm(addon, prefix, method)
	if method == nil then
		method = "OnCommReceived"
	end

	return AceComm._RegisterComm(addon, prefix, method)
end


----------------------------------------
-- Mixins
----------------------------------------

local mixins = {
	"RegisterComm",
	"UnregisterComm",
	"UnregisterAllComm",
	"SendCommMessage",
}

function AceComm:Embed(target)
	for k, v in pairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
end

function AceComm:OnEmbedDisable(target)
	target:UnregisterAllComm()
end


----------------------------------------
-- Message sending
----------------------------------------

-- 254 is the max length of prefix + text that can be sent in one message
function AceComm.SendCommMessage(addon, prefix, text, distribution, target)
	local prefix_len = #prefix
	local text_len = #text
	local meta_len = 2
	local chunk_size = 253 - prefix_len - meta_len

	assert(type(prefix) == "string")
	assert(type(text) == "string")
	assert(type(distribution) == "string")
	
	if text_len < chunk_size + meta_len then
		-- fits all in one message
		CTL:SendAddonMessage(single_prio, prefix, text, distribution,
				     target)
	else
		local chunks = ceil(text_len / chunk_size)
		-- string offsets
		local chunk_begin = 1
		local chunk_end = 1 + chunk_size
		-- first part
		local real_prefix = prefix .. message_type_rev["multipart_begin"]
		local chunk = strsub(text, chunk_begin, chunk_end)
		chunk_begin = chunk_end + 1
		chunk_end = chunk_begin + chunk_size
		CTL:SendAddonMessage(multipart_prio, real_prefix, chunk,
				     distribution, target)
		
		-- continuation
		real_prefix = prefix .. message_type_rev["multipart_continue"]
		for i = 2, chunks - 1, 1 do
			chunk = strsub(text, chunk_begin, chunk_end)
			chunk_begin = chunk_end + 1
			chunk_end = chunk_begin + chunk_size
			CTL:SendAddonMessage(multipart_prio, real_prefix, chunk,
					     distribution, target)
		end
		
		-- end
		real_prefix = prefix .. message_type_rev["multipart_end"]
		chunk = strsub(text, chunk_begin, chunk_end)
		CTL:SendAddonMessage(multipart_prio, real_prefix, chunk,
				     distribution, target)
	end
end


----------------------------------------
-- Message receiving
----------------------------------------

function AceComm:ReceiveMultipart(prefix, message, distribution, sender,
				 messagetype)
	-- a unique stream is defined by the prefix + distribution + sender
	local data_key = ("%s\t%s\t%s"):format(prefix, distribution, sender)
	local incomplete_data = self.__incomplete_data
	local data = incomplete_data[data_key]

	if messagetype == "multipart_begin" then
		-- Begin multipart message
		data = message
		incomplete_data[data_key] = data
	elseif messagetype == "multipart_continue" then
		-- Continue multipart message
		assert(data ~= nil)
		data = data .. message
		incomplete_data[data_key] = data
	elseif messagetype == "multipart_end" then
		-- End multipart message
		assert(data ~= nil)
		data = data .. message
		self:MessageCompleted(prefix, data, distribution, sender)
		incomplete_data[data_key] = nil
	else
		-- Unknown!
		error("AceComm:ReceiveMultipart unknown messagetype.")
	end
end


function AceComm:CHAT_MSG_ADDON(prefix, message, distribution, sender)
	-- ignore messages from ourself
	--if sender == player_name then return end

	--local prefix, layer, options =
	--	strmatch(prefix, "^([^\001-\031]+)([\001-\031]?)(.*)")

	local messagetype = self.__prefixes[prefix]

	if not messagetype then
		-- not a prefix registered with us
		return
	elseif messagetype == true then
		-- single-part message
		self:MessageCompleted(prefix, message, distribution, sender)
	else
		-- multi-part message
		self:ReceiveMultipart(self.__original_prefix[prefix], message,
				      distribution, sender, messagetype)
	end
end

-- Event Handling
function AceComm.OnEvent(this, event, ...)
	if event == "CHAT_MSG_ADDON" then
		AceComm:CHAT_MSG_ADDON(...)
	else
		error("Something strange happened to AceComm's event frame.")
	end
end

AceComm.frame:SetScript("OnEvent", AceComm.OnEvent)
AceComm.frame:UnregisterAllEvents()
AceComm.frame:RegisterEvent("CHAT_MSG_ADDON")

-- Update embeds
for target, v in pairs(AceComm.embeds) do
	AceComm:Embed(target)
end
