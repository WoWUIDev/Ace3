dofile("wow_api.lua")
dofile("../LibStub/LibStub.lua")
dofile("../AceSerializer-3.0/AceSerializer-3.0.lua")

-- Usage: lua AceSerializer-3.0.lua [<burnin count, default 1>]
local BURNIN = tonumber(arg[1]) or 1	-- roughly 1 sec execution time per loop, 10000 loops should be a good burn-in

local AceSer = LibStub("AceSerializer-3.0")

local function printf(fmt, ...)
	print(fmt:format(...))
end


local function comp(input,res,expect,errlvl)
	if res~=expect then
		error(format("Input %q resulted in %q. Expected %q.", tostring(input), tostring(res), tostring(expect)), 1+(errlvl or 1))
	end
end

local function test(func, input, expect, errlvl)
	local res = func(input)
	comp(input,res,expect, 1+(errlvl or 1))
end


-----------------------------------------------------------------------
-- Test SerializeStringHelper

local SerializeStringHelper = assert(AceSer.internals.SerializeStringHelper)


test(SerializeStringHelper,"\000", "~@")
test(SerializeStringHelper,"\001", "~A")
test(SerializeStringHelper,"\031", "~_")
test(SerializeStringHelper," ", "~`")
test(SerializeStringHelper,"\094", "~\125")
test(SerializeStringHelper,"\126", "~\124")
test(SerializeStringHelper,"\127", "~\123")

for i=33,255 do
	if i~=94 and i~=126 and i~=127 then
		assert(not pcall(SerializeStringHelper, strbyte(i)))	-- should error
	end
end


-----------------------------------------------------------------------
-- Test SerializeValue

local SerializeValue = assert(AceSer.internals.SerializeValue)


local function testsv(input, expect, errlvl)
	local res = {}
	local nres = SerializeValue(input, res, 0)
	
	comp(input,table.concat(res), expect, 1+(errlvl or 1))
end

-- Strings:
testsv("", "^S")
testsv("hi", "^Shi")
testsv("a\000b\032c", "^Sa~@b~`c")
testsv("^S", "^S~\125S")

-- Other simply types
testsv(nil, "^Z")
testsv(true, "^B")
testsv(false, "^b")
testsv(0, "^N0")
testsv(-5, "^N-5")
testsv(12345, "^N12345")

-- Tables:
testsv({}, "^T^t")

testsv({	-- number indices, string values
	"foo","bar"
}, "^T^N1^Sfoo^N2^Sbar^t")	-- 50% chance to get ordering right :S  luckily all 5.1s behave the same way

testsv({
	a="hi",b="bye"	-- string indices, string values
}, "^T^Sa^Shi^Sb^Sbye^t")	-- 50% chance again

testsv({	-- table as index, table as value
	[{theindex="isatable"}]={thevalue=2}
}, "^T^T^Stheindex^Sisatable^t^T^Sthevalue^N2^t^t")


-----------------------------------------------------------------------
-- Test Deserialize

-- Error testing:
local ok, r1,r2,r3 = AceSer:Deserialize("errormoar")	-- plain error
assert(not ok)
assert(strmatch(r1, "not AceSerializer data"))

local ok, r1,r2,r3 = AceSer:Deserialize("^2^^")	-- unknown version -> error
assert(not ok)
assert(strmatch(r1, "not AceSerializer data"))

local ok, r1,r2,r3 = AceSer:Deserialize("^1")	-- unterminated -> error
assert(not ok)
assert(strmatch(r1, "misses AceSerializer terminator"), r1)

-- Empty data
local function x(ok,...)
	assert(ok)
	assert(select("#",...)==0)
end
x(AceSer:Deserialize("^1^^"))	-- empty data -> ok

-- Simple datatypes:
local ok, r1,r2,r3 = assert(AceSer:Deserialize("^1^Sone^Stwo^^"))	-- two strings -> ok
assert(r1=="one" and r2=="two" and r3==nil, dump(ok,r1,r2,r3))

local ok, r1,r2,r3 = assert(AceSer:Deserialize("^1^B^b^^"))	-- true, false -> ok
assert(r1==true and r2==false and r3==nil)

local ok, r1,r2,r3 = assert(AceSer:Deserialize("^1^Z^N5^^"))	-- nil, 5 -> ok
assert(r1==nil and r2==5 and r3==nil, dump(ok,r1,r2,r3))

local ok, r1,r2,r3 = AceSer:Deserialize("^1^Nblurgh^^") -- invalid number -> error
assert(not ok and strmatch(r1,"Invalid serialized number"), r1)

-- Tables (ergh):

local ok, r1,r2,r3 = assert(AceSer:Deserialize("^1^T^t^^"))	-- empty table
assert(type(r1)=="table")
assert(next(r1)==nil)
assert(r2==nil)

local ok, r1,r2,r3 = assert(AceSer:Deserialize("^1^T^N1^Shi^t^^"))	-- number = string
assert(r1[1]=="hi")
assert(r2==nil)

local ok, r1,r2,r3 = assert(AceSer:Deserialize("^1^T^T^Stheindex^Sisatable^t^T^Sthevalue^N2^t^t^Send^^"))	-- table = table, with tacked on string to test iterator
local k,v = next(r1)
assert(type(k)=="table")
assert(type(v)=="table")
assert(k.theindex=="isatable")
assert(v.thevalue==2)
assert(r2=="end")

-- Table error testing:
local ok,res = AceSer:Deserialize("^1^T")
assert(not ok and strmatch(res, "misses AceSerializer terminator"))

local ok,res = AceSer:Deserialize("^1^T^^")
assert(not ok and strmatch(res, "no table end marker"))

local ok,res = AceSer:Deserialize("^1^T^Sa")
assert(not ok and strmatch(res, "misses AceSerializer terminator"))

local ok,res = AceSer:Deserialize("^1^T^Sa^^")
assert(not ok and strmatch(res, "no table end marker"))

local ok,res = AceSer:Deserialize("^1^T^Sa^Sb")
assert(not ok and strmatch(res, "misses AceSerializer terminator"))

local ok,res = AceSer:Deserialize("^1^T^Sa^Sb^^")
assert(not ok and strmatch(res, "no table end marker"))

assert(AceSer:Deserialize("^1^T^Sa^Sb^t^^"))



-----------------------------------------------------------------------
-- Wild combos

local ser = AceSer:Serialize(
	"firstval",
	123e-17,
	true,
	false,
	nil,
	{
		{
			foo="bar"
		},
		{
			baz={}
		},
		name="val",
	},
	"\001\032\127^~fin!^^"
)

local ok,r1,r2,r3,r4,r5,r6,r7,r8 = assert(AceSer:Deserialize(ser))
assert(r1=="firstval")
assert(r2==1.23e-15)
assert(r3==true)
assert(r4==false)
assert(r5==nil)
assert(type(r6)=="table")
assert(r6[1].foo=="bar")
assert(type(r6[2].baz)=="table")
assert(r6.name=="val")
comp("?", r7, "\001\032\127^~fin!^^")
assert(r8==nil)


-----------------------------------------------------------------------
-- Wild combos, now as a table

local ser = AceSer:Serialize({
	"firstval",
	123e-17,
	true,
	false,	-- ACE-130
	nil,
	{
		{
			foo="bar"
		},
		{
			baz={}
		},
		name="val",
	},
	"\001\032\127^~fin!^^",
	[true]="yes",
	[false]="no"	-- ACE-130
})

local ok,r = assert(AceSer:Deserialize(ser))
assert(r[1]=="firstval")
assert(r[2]==1.23e-15)
assert(r[3]==true)
assert(r[4]==false)
assert(r[5]==nil)
assert(type(r[6])=="table")
assert(r[6][1].foo=="bar")
assert(type(r[6][2].baz)=="table")
assert(r[6].name=="val")
comp("?", r7, "\001\032\127^~fin!^^")
assert(r[8]==nil)

assert(r[true]=="yes")
assert(r[false]=="no")


-----------------------------------------------------------------------
-- NaN, inf, etc

local ok,res = AceSer:Deserialize(AceSer:Serialize(0/0))
assert(ok and tostring(res)==tostring(0/0))

local ok,res = AceSer:Deserialize(AceSer:Serialize(1/0))
assert(ok and tostring(res)==tostring(1/0))

local ok,res = AceSer:Deserialize(AceSer:Serialize(-1/0))
assert(ok and tostring(res)==tostring(-1/0))


-----------------------------------------------------------------------
-- Floating-point accuracy (ACE-123)

local function testone(v)
	local ser = AceSer:Serialize(v)
	local ok,deser = AceSer:Deserialize(ser)
	assert(ok and deser==v, dump(ok, v, ser, deser))
end

local __myrand_n = 0
local function myrand()
	__myrand_n = (__myrand_n + 1.23456789) % 123	-- this prng does not repeat for at least 10G iterations - tested up to 13.048G
	local n = frexp(__myrand_n)*2
	local ret = math.random() + n
	ret = ret - floor(ret)
	return ret
end


testone(1/3)
testone(2/3)
testone(math.pi)
testone(math.exp(1))	-- 2.718281828459...
testone(math.sqrt(math.exp(1)))  -- 1.6487212707001...
testone(math.sqrt(0.5))   -- 0.70710678118655...

if BURNIN>1 then
	print "Floating point precision burn-in test:"
end
local startt = os.clock()
for l=0,BURNIN-1 do	-- default 1 = 1 loop, but no printing
	if l>=1 then
		local tick = (os.clock()-startt) / l
		printf("%.2f%% (%.1fs)", (l/BURNIN*100), (BURNIN-l)*tick)
	end
	for i=1,10000 do
		local v = myrand() + myrand()*(2^-20) + myrand()*(2^-40) + myrand()*(2^-60)
		if math.random(1,2)==1 then
			v = v * -1
		end
		-- str=format("%+0.20f\t",v)
		local e = math.random(-1000, 1000)
		v = v * 2^(e)
		-- print(str,e,v)
		
		testone(v)
	end
end


-----------------------------------------------------------------------
print "OK"
