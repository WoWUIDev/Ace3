dofile("wow_api.lua")
dofile("../LibStub/LibStub.lua")
dofile("../AceSerializer-3.0/AceSerializer-3.0.lua")

local inf = math.huge


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
test(SerializeStringHelper,"\030", "~\122") -- v3 / Ticket 115: Argh. 30+64=94 ("^"). OOPS. Unique encoding for \030 now.
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
-- Ticket 115: Serializing and then de-serializing strings

for i=0,255 do
	local str = strbyte(i)
	local ok,res = AceSer:Deserialize(AceSer:Serialize(str))
	assert( ok and str == res , i)
end

if BURNIN>1 then
	print("String burn-in test:")
end
for b=1,BURNIN do
	for i=1,1e4 do
		local str = strbyte(random(0,255))..strbyte(random(0,255))..strbyte(random(0,255))..strbyte(random(0,255))
		local ok,res = AceSer:Deserialize(AceSer:Serialize(str))
		assert( ok and str == res , str, res)
	end
	for i=1,1e4 do
		local str = strbyte(random(0,255))..strbyte(random(0,255))..strbyte(random(0,255))..strbyte(random(0,255))
		local ok,r1,r2,r3 = AceSer:Deserialize(AceSer:Serialize(true,str))
		assert( ok and r1==true and str == r2 , str, r2)
	end
	for i=1,1e4 do
		local str = strbyte(random(0,255))..strbyte(random(0,255))..strbyte(random(0,255))..strbyte(random(0,255))
		local ok,r1,r2,r3 = AceSer:Deserialize(AceSer:Serialize(5,str,true))
		assert( ok and r1==5 and str == r2 and r3 == true , str, res)
	end
	if BURNIN>1 then
		printf("%.1f%%", b/BURNIN*100)
	end
end



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

--[[ not as of 4.3
local ok,res = AceSer:Deserialize(AceSer:Serialize(0/0))
assert(ok and tostring(res)==tostring(0/0))
]]

local ok,res = AceSer:Deserialize(AceSer:Serialize(inf))
assert(ok and tostring(res)==tostring(inf))

local ok,res = AceSer:Deserialize(AceSer:Serialize(-inf))
assert(ok and tostring(res)==tostring(-inf))


-----------------------------------------------------------------------
-- Floating-point accuracy (ACE-123)

local function testone(v)
	local ser = AceSer:Serialize(v)
	local ok,deser = AceSer:Deserialize(ser)
	assert(ok and deser==v, dump(ok, v, ser, deser))
end

local function testone_tostr(v)
	local ser = AceSer:Serialize(v)
	local ok,deser = AceSer:Deserialize(ser)
	assert(ok and tostring(deser)==tostring(v), dump(ok, v, ser, deser))
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

-- These have to be tested via tostring() comparison of the results since e.g. NaN isn't == NaN
testone_tostr(inf)	 -- INF
testone_tostr(-inf)  -- -INF
--not as of 4.3  testone_tostr(0/0)   -- NaN



if BURNIN>1 then
	print "Floating point precision burn-in test:"
end
for b=1,BURNIN do	-- default 1 = 1 loop, but no printing
	for i=1,1e4 do
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
	if BURNIN>1 then
		printf("%.1f%%", b/BURNIN*100)
	end
end


-----------------------------------------------------------------------
-- vhaarr's testcase of BananaDKP

local BananaDKP = {
	[""] = 0.474609375,
	["Sarene"] = 23.2291748046875,
	["Exatos"] = 6,
	["Skyfiah"] = 4,
	["Níena"] = 5,
	["Azax"] = 102.08,
	["Korumo"] = 28.78446006774903,
	["Tarannon"] = 51.19950154685832,
	["Relinquish"] = 76.03103977709394,
	["Outofcontrol"] = 45.57863802415056,
	["Naryaa"] = 69.01798407067545,
	["Zakris"] = 7.3996074843177,
	["Exodous"] = 128.1306512626569,
	["Flirfull"] = 100.6661528351939,
	["Birdwings"] = 33.7216552734375,
	["Theoxis"] = 5,
	["Adior"] = 54.953125,
	["Vdgg"] = 4,
	["Positronics"] = 46.96747932434081,
	["Paces"] = 37.74374999999998,
	["Ríot"] = 14.9,
	["Kaostechno"] = 34.04490834849657,
	["Skrinky"] = 93.79947433816274,
	["Eezilla"] = 20.81249999999999,
	["Folk"] = 6,
	["Knaus"] = 22.596875,
	["Undeadangel"] = 44.78000434875492,
	["Purplerattii"] = 57.53351999828472,
	["Laloena"] = 55.53190727233888,
	["Druidturtle"] = 1.5,
	["Shiaq"] = 105.3250000000001,
	["Heavyx"] = 26.7,
	["Omgashammy"] = 174.3007940918701,
	["Vesira"] = 49.56464843750001,
	["Szentlovag"] = 31.47292669415476,
	["Moohawk"] = 90.65259001851082,
	["Kain"] = 124.6437499999999,
	["Ewandor"] = 8,
	["Molh"] = 19.10390625,
	["Shekowaffle"] = 61.71009125776505,
	["Nesitn"] = 4.5,
	["Spikyo"] = 41,
	["Winning"] = 6.5,
	["Soaz"] = 6.299999999999999,
	["Terezka"] = 88.11159490764035,
	["Palaxm"] = 18.06328125,
	["Purplemist"] = 16.68659827320444,
	["Fallirin"] = 38.675,
	["Deriyana"] = 7.5,
	["Tohil"] = 51.7,
	["Leksa"] = 13.475,
	["Guldy"] = 74.54692840576169,
	["Cryptos"] = 35.3587890625,
	["Weisses"] = 53.52014426127423,
	["Kalano"] = 6,
	["Bakanti"] = 2.6,
	["Donaster"] = 65.97841796874999,
	["Glimmer"] = 16.525,
	["Darkshaman"] = 36.04368476867675,
	["Janarsk"] = 52.0042827545898,
	["Anarchos"] = 11.2,
	["Nipp"] = 103.4,
	["Limp"] = 103.8734375,
	["Abolish"] = 71.16988067626951,
	["Stilnox"] = 19.9,
	["Pastorcrone"] = 1.1,
	["Standawarlok"] = 178.5589128405881,
	["Diller"] = 65.02421337477864,
	["Moonies"] = 42.15624999999999,
	["Reapz"] = 101.1989096983292,
	["Skyle"] = 18,
	["Yoshimoto"] = 50.5578125,
	["Jahlight"] = 55.84861385010445,
	["Purplerat"] = 58.18249032591219,
	["Yojin"] = 6.699999999999999,
	["Standawarlock"] = 0,
	["Mythic"] = 72.82499999999999,
	["Mallfurion"] = 12.420703125,
	["Masai"] = 26.56874999999999,
	["Lookapally"] = 1,
	["Kaiiden"] = 12.9125,
	["Littlepope"] = 27.31436767578125,
	["Luciferael"] = 14.6162109375,
	["Thornak"] = 55.27390024662017,
	["Wyxan"] = 12.42806396484375,
	["Sínk"] = 45.17230918665088,
	["Nicklaswiik"] = 49.7,
	["Sixpounder"] = 112.7498674331468,
	["Nìghtmare"] = 160.5467726655844,
	["Goldenwand"] = 163.5234313964844,
	["Irmishor"] = 77.47978515625003,
	["Annubís"] = 81.70629262239996,
	["Silverstonez"] = 27.6111152901094,
	["Skep"] = 17.928125,
	["Amarilis"] = 90.50000000000003,
	["Sullen"] = 134.71,
	["Anomandaris"] = 20.9765625,
	["Modrack"] = 6,
	["Drakespotter"] = 51.27382812499999,
	["Znufflessd"] = 115.7564419515773,
	["Lysia"] = 74.2980165224523,
	["Oxider"] = 45.61875,
	["Marjory"] = 107.6768582475093,
	["Hipocrates"] = 110.91,
	["Madwarp"] = 38.8439841499554,
	["Wazzockk"] = 27.64375,
	["Casse"] = 82.34733895370744,
	["Redsnap"] = 82.81875000000002,
	["Browniee"] = 14.9,
	["Neurox"] = 142.0123014972254,
	["Undenth"] = 81.38942842581224,
	["Ghallar"] = 10,
	["Faxzorr"] = 39.02792450294366,
	["Dhaffy"] = 13.2572021484375,
	["Nealuchy"] = 24.2,
	["Kazoku"] = 120.24519861394,
	["Ozaku"] = 50.1734170750901,
	["Howll"] = 70.53942653812121,
	["Missturtle"] = 10.8,
	["Velimatti"] = 96.97339012753626,
	["Snapi"] = 4.8,
	["Zorlex"] = 83.34489687817376,
	["Barracudos"] = 8.199999999999999,
	["Twee"] = 105.8170643531485,
	["Naayse"] = 126.9,
	["Albazz"] = 51.88214008212089,
	["Rands"] = 10.8,
	["Missheals"] = 136.3382218568287,
	["Puscifer"] = 175.0551752018927,
	["Hôwl"] = 40.58535041809083,
	["Fáhad"] = 2.6,
	["Lorena"] = 73.17797993007233,
	["Superfax"] = 0,
	["Samynix"] = 78.66168365867924,
	["Terab"] = 2.8,
	["Deadblack"] = 93.94579782714179,
	["Dåre"] = 11.1875,
	["Olymp"] = 28.5984375,
	["Thirnova"] = 82.84477098052523,
	["Smashing"] = 3,
	["Bahmut"] = 77.98728485107419,
	["Kiplex"] = 68.9339790189577,
	["Frankaz"] = 35.59999999999999,
	["Satyr"] = 3.715301513671875,
	["Crysanthos"] = 12.1,
	["Raziel"] = 54.59892578124997,
	["Xen"] = 47.8171875,
	["Kafo"] = 33.95000000000001,
	["Lunaatj"] = 25.2,
	["Mainrak"] = 15.74119808673859,
	["Sheve"] = 72.96606826782228,
	["Netherdruid"] = 4,
	["Jitter"] = 80.43541267343595,
	["Nerezza"] = 19.2,
	["Yumad"] = 57.10804011713954,
	["Deshai"] = 31.86718749999999,
	["Fourever"] = 3.96875,
	["Gromkàr"] = 60.73427623669271,
	["Gomarius"] = 26.85820312499999,
	["Bubblebutt"] = 15.059375,
	["Falconcrest"] = 47.18560546875,
	["Glexy"] = 50.09467261158207,
	["Broly"] = 143.215447998047,
	["Wojtyla"] = 76.56250000000001,
	["Laloeno"] = 21,
	["Deccal"] = 56.79538574218747,
	["Littlepiggy"] = 19.8595703125,
	["Kaldrgrimmr"] = 22.53134765625,
	["Mageyoulook"] = 89.40824390664915,
	["Ains"] = 20.01286297092336,
	["Jahblin"] = 65.44852752685547,
	["Tingse"] = 6.9,
	["Harmonize"] = 57.47371152867748,
	["Wilhelm"] = 18.139013671875,
	["Clixx"] = 16.175,
	["Nuzanix"] = 20.3,
	["Evó"] = 32.63125,
	["Deefa"] = 22.2515625,
	["Lumide"] = 25.2796875,
	["Sacrament"] = 34.46691145896911,
	["Greenrow"] = 36.815625,
	["Pureshamy"] = 11.3,
	["Tubbygold"] = 112.3197134133892,
	["Uskilla"] = 7.1,
	["Wilsón"] = 17.925,
	["Scuttlebutt"] = 64.85407714843747,
	["Spectero"] = 27.8,
	["Bingzork"] = 58.97460937499999,
	["Stjärtpirat"] = 50.44058861732481,
	["Holypad"] = 69.09421386718751,
	["Revex"] = 29.12885131835938,
	["Giblex"] = 61.29557364186327,
	["Savá"] = 3.46875,
	["Xiola"] = 43.33394042968753,
	["Agonias"] = 25.9,
	["Fenteria"] = 13.6,
	["Dismantle"] = 1.1,
	["Ridikk"] = 13.475,
	["Zhopher"] = 18.1,
	["Cadaverous"] = 3,
	["Sakinio"] = 83.72360839843752,
	["Uzargah"] = 53.7,
	["Zenìth"] = 30.63310546875001,
	["Flaytality"] = 30.4328125,
	["Asch"] = 24,
	["Youdare"] = 34.25,
	["Glexx"] = 96.89479795349136,
	["Keselamatan"] = 5.5,
	["Vélamelaxa"] = 57.95,
	["Bullsteak"] = 62.86201494510381,
	["Avaliot"] = 59.96668634414672,
	["Sensorme"] = 16,
	["Gzes"] = 86.2139735617442,
	["Lexii"] = 1.5,
	["Suppremus"] = 12.45,
	["Nihtera"] = 54.71874999999998,
	["Drekkar"] = 1.2,
	["Deathshaker"] = 16.10708417687565,
	["Isuckbigtime"] = 49.04806583523752,
	["Wilk"] = 7.5,
	["Liisanantti"] = 5.699999999999999,
	["Talkytoaster"] = 47.91855073869228,
	["Eezo"] = 7.424999999999999,
	["Naraku"] = 172.587070465088,
	["Ebica"] = 21.19234375,
	["Aceventauren"] = 5,
	["Kinigos"] = 141.325,
	["Aarwen"] = 65.27267533369734,
	["Zwitsalkid"] = 49.87586200456557,
	["Faroon"] = 28.52035051390259,
	["Soviett"] = 20.175,
	["Razhgat"] = 59.425,
	["Kohee"] = 81.23796118079324,
	["Inh"] = 21.2,
	["Vanke"] = 10.6375,
	["Koraag"] = 52.17578125000004,
	["Grekko"] = 6.65,
	["Jinkha"] = 148.6349520375164,
	["Mithrill"] = 65.09988472960455,
	["Darkblud"] = 77.07862319643684,
	["Lagwin"] = 2.9,
	["Glexor"] = 11,
	["Smoothe"] = 32.59999999999999,
	["Klesk"] = 13.8734375,
	["Standadruid"] = 5.6,
	["Este"] = 4,
	["Tirazea"] = 29.40651037693024,
	["Deadlybaker"] = 23.02175271011469,
	["Gunjah"] = 2.9,
	["Ruudolf"] = 12.825,
	["Ickis"] = 24.8315185546875,
	["Mhemnosis"] = 51.70825500488279,
	["Intro"] = 18,
	["Shevelkov"] = 18.4,
	["Nënya"] = 3,
	["Pumpum"] = 6,
	["Deadangel"] = 3,
	["Iribal"] = 5,
	["Fuzz"] = 6,
	["Turbopippip"] = 22.58085935115814,
	["Reewez"] = 29.14369135306568,
	["Dutchegg"] = 2.6,
	["Msd"] = 1,
	["Arthuss"] = 7,
	["Fancel"] = 76,
	["Apocalypsé"] = 100.219256567955,
	["Isshin"] = 14.8,
	["Donimo"] = 28.1375,
	["Evildoc"] = 34.67125854492187,
	["Aimstaren"] = 9.725000000000001,
	["Eido"] = 27.41901125013827,
	["Augustina"] = 38.2522705078125,
	["Astraea"] = 84.77500000000003,
	["Nitalia"] = 77.15156250000001,
	["Keda"] = 47.99218749999999,
	["Bruker"] = 54.46365778744223,
	["Vate"] = 71.29377851486206,
	["Nolram"] = 6,
	["Tertius"] = 11.8,
	["Preluden"] = 28.6078125,
	["Tód"] = 6,
	["Depression"] = 24.31875,
	["Luuly"] = 26.9,
	["Iokasti"] = 5.2,
	["Parkerlewis"] = 25.2125,
	["Xsur"] = 63.28885148193271,
	["Hezekiah"] = 45.8791930607004,
	["Thoójs"] = 43.81240234375,
	["Belie"] = 56.78018793293472,
	["Aelhia"] = 72.11211488842963,
	["Msdynamite"] = 57.34350404497852,
	["Jyscal"] = 16.875,
	["Arcadi"] = 27.9610513073206,
	["Omikron"] = 90.29614257812503,
	["Scotney"] = 23.85000000000001,
	["Feroxs"] = 2.75,
	["Kunegunda"] = 67.01597518752254,
	["Almond"] = 12,
	["Souljaxx"] = 45.09790072393639,
	["Cahira"] = 123.9350390605105,
	["Nartis"] = 68.90000000000001,
	["Islandwalker"] = 7.5,
	["Bambulance"] = 55.90195312499998,
	["Bonelady"] = 130.0804811610219,
	["Mariaeglorum"] = 80.46449127197268,
	["Reapzor"] = 100.5175882567523,
	["Heavénly"] = 32.48786249496042,
	["Kaeleth"] = 22.15709753036499,
	["Standacousin"] = 5.6,
	["Steeltotem"] = 20.7,
	["Keltherkain"] = 149.8924741572648,
	["Zák"] = 14.23125000000001,
	["Lednew"] = 55.53098552393228,
	["Powerbrew"] = 30.651171875,
	["Kilionaire"] = 67.60606225119086,
	["Dóctorwho"] = 86.80875795118057,
	["Plujer"] = 72.44062500000001,
	["Gobb"] = 6.84375,
	["Litigious"] = 12.6,
	["Affix"] = 119.2229248046875,
	["Irónjaw"] = 24.95343017578125,
	["Wendel"] = 125.4807928578717,
	["Azandai"] = 24.77099609375,
	["Xenh"] = 40.92499999999999,
	["Sipsen"] = 16.95,
	["Nruff"] = 1.5,
	["Phistashka"] = 7,
	["Miss"] = 10,
	["Zykee"] = 38.7,
	["Kotek"] = 44.21045989990233,
}

local ser = AceSer:Serialize(BananaDKP)
local ok,res = assert(AceSer:Deserialize(ser))
local n1=0
for k,v in pairs(BananaDKP) do n1=n1+1 end
local n2=0
for k,v in pairs(res) do n2=n2+1 assert(v==BananaDKP[k]) end
assert(n1==n2)


-----------------------------------------------------------------------
print "OK"
