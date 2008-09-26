dofile("wow_api.lua")
dofile("../LibStub/LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceComm-3.0/ChatThrottleLib.lua")
dofile("../AceComm-3.0/AceComm-3.0.lua")

local VERBOSE = false

local AceComm = LibStub("AceComm-3.0")

local function printf(format, ...)
	print(format:format(...))
end

local addon = {}
local prefix = "Test"

AceComm:Embed(addon)

function addon:OnCommReceived(prefix, data, distribution, sender)
	assert(data == self.data)
end

addon:RegisterComm(prefix)

local function randchar()
	return string.char(math.random(0, 255))
end

local data = ""
for i = 1, 500 do
	for j = 1, math.random(1, 7) do
		data = data .. randchar()
	end
	addon.data = data
	if VERBOSE then printf("Running test, data length %d", #data) end
	addon:SendCommMessage(prefix, data, "RAID", nil)
end

-----------------------------------------------------------------------
print "OK"
