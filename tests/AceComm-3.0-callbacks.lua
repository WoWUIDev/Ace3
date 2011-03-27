dofile("wow_api.lua")
dofile("../LibStub/LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceComm-3.0/ChatThrottleLib.lua")
dofile("../AceComm-3.0/AceComm-3.0.lua")



local AceComm = LibStub("AceComm-3.0")

local addon1 = {}

AceComm:Embed(addon1)




-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
-- Test callbacks firing delayed
--


-- Single message

local nSingle=0
addon1:SendCommMessage("single", "1234567890", "RAID", nil, "NORMAL", 
	function(arg,sent,total)
		assert(arg=="singlearg")
		nSingle=nSingle+1
		assert(sent==10 and total==10)
	end,
	"singlearg"
)

-- Multipart message
local nMulti=0
addon1:SendCommMessage("multi", strrep("1234567890", 80), "RAID", nil, "NORMAL", 
	function(arg,sent,total)
		assert(arg=="multiarg")
		nMulti=nMulti+1
		--	print(sent)
		if nMulti>=1 and nMulti<=3 then
			assert(sent==(255-1)*nMulti)	-- 256 - \0 - \t - #prefix - [\001-\003]
		elseif nMulti==4 then
			assert(sent==800)
		end
		assert(total==800)
	end,
	"multiarg"
)

assert(nSingle==0)
assert(nMulti==0)

WoWAPI_FireUpdate(GetTime()+100)	-- 100 seconds later

assert(nSingle==1)
assert(nMulti==4)



-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
--
-- Test callbacks firing IMMEDIATELY (recursively)
--

WoWAPI_FireUpdate(GetTime()+100)	-- 100 seconds later


-- Single message

local nSingle=0
addon1:SendCommMessage("single", "1234567890", "RAID", nil, "NORMAL", 
	function(arg,sent,total)
		assert(arg=="singlearg")
		nSingle=nSingle+1
		assert(sent==10 and total==10)
	end,
	"singlearg"
)
assert(nSingle==1)


-- Multipart message
local nMulti=0
addon1:SendCommMessage("multi", strrep("1234567890", 80), "RAID", nil, "NORMAL", 
	function(arg,sent,total)
		assert(arg=="multiarg")
		nMulti=nMulti+1
		--	print(sent)
		if nMulti>=1 and nMulti<=3 then
			assert(sent==(255-1)*nMulti)	-- 256 - \0 - \t - #prefix - [\001-\003]
		elseif nMulti==4 then
			assert(sent==800)
		end
		assert(total==800)
	end,
	"multiarg"
)

assert(nMulti==4)

WoWAPI_FireUpdate(time()+100)	-- 100 seconds later

assert(nSingle==1)
assert(nMulti==4)





-----------------------------------------------------------------------
print "OK"
