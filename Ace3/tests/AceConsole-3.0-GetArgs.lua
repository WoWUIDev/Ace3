
local MAJOR="AceConsole-3.0"

dofile("wow_api.lua")

dofile("LibStub.lua")
dofile("../"..MAJOR.."/"..MAJOR..".lua")


local AC = assert(LibStub(MAJOR))




----------------------------------------------------------
-- Simple tests 
-- (no need to explicitly test startpos; if multi-arg tests work, it works)

local a1,a2 = AC:GetArgs("")		-- no arg
assert(a1==nil and a2==1e9)

local a1,a2 = AC:GetArgs("  ")		-- still no arg
assert(a1==nil and a2==1e9)

local a1,a2 = AC:GetArgs("a1")		-- simple
assert(a1=="a1" and a2==1e9)

local a1 = AC:GetArgs("a1", 0) -- fetch 0 args
assert(a1==1)

local a1 = AC:GetArgs("  a1", 0) -- fetch 0 args, leading space
assert(a1==3)

local a1,a2 = AC:GetArgs("a1 a2")   -- args remaining, check nextpos
assert(a1=="a1" and a2==4)

local a1,a2 = AC:GetArgs("a1   a2")   -- args remaining, check nextpos
assert(a1=="a1" and a2==6, dump(a1,a2))

local a1,a2,a3 = AC:GetArgs("a1 a2", 2)	-- 2 args
assert(a1=="a1" and a2=="a2" and a3==1e9)

local a1,a2,a3 = AC:GetArgs("   a1    a2 ", 2)		-- surplous space
assert(a1=="a1" and a2=="a2" and a3==1e9, dump(a1,a2,a3))

local a1,a2,a3 = AC:GetArgs("   a1    a2  ", 2)		-- one more space at end
assert(a1=="a1" and a2=="a2" and a3==1e9, dump(a1,a2,a3))


local a1,a2,a3 = AC:GetArgs("   a1      ", 2)		-- missing arg2
assert(a1=="a1" and a2==nil and a3==1e9, dump(a1,a2,a3))



----------------------------------------------------------
-- Test quoting

local a1,a2 = AC:GetArgs([["a1"]])	-- simple quote
assert(a1=="a1" and a2==1e9, dump(a1,a2))

local a1,a2 = AC:GetArgs([["a 1"]])	-- quote with space in it
assert(a1=="a 1" and a2==1e9, dump(a1,a2))

local a1,a2 = AC:GetArgs([[" a 1 "]]) -- quote with space at beginning and end
assert(a1==" a 1 " and a2==1e9, dump(a1,a2))

local a1,a2 = AC:GetArgs([['a 1']])		-- single quote
assert(a1=="a 1" and a2==1e9, dump(a1,a2))

local a1,a2,a3 = AC:GetArgs([["a 1" "a 2"]], 2)	-- 2 args
assert(a1=="a 1" and a2=="a 2" and a3==1e9, dump(a1,a2,a3))

local a1,a2,a3 = AC:GetArgs([["a 1" 'a 2']], 2)	-- mixed quoting
assert(a1=="a 1" and a2=="a 2" and a3==1e9, dump(a1,a2,a3))

local a1,a2,a3 = AC:GetArgs([[  "a 1"  'a 2' ]], 2)	-- surplous spacing between quotes
assert(a1=="a 1" and a2=="a 2" and a3==1e9, dump(a1,a2,a3))

local a1,a2,a3 = AC:GetArgs([["foo'bar" 'foo"bar']], 2)	-- don't break on nonmatching quote
assert(a1=="foo'bar" and a2=='foo"bar' and a3==1e9, dump(a1,a2,a3))

local a1,a2 = AC:GetArgs([[  "unfinished quote]], 1)  -- missing " at end
assert(a1=="unfinished quote" and a2==1e9, dump(a1,a2))


------------------------------------------------------------
-- Hyperlinks and combos

local a1,a2,a3,a4 = AC:GetArgs("simple |Cff112233|Hitem:0:0:0:0|hand here's a text with \"s and stuff|h|r", 3)
assert(a1=="simple" and a2=="|Cff112233|Hitem:0:0:0:0|hand here's a text with \"s and stuff|h|r" and a3==nil and a4==1e9, dump(a1,a2,a3,a4))

local a1,a2,a3,a4 = AC:GetArgs("simple '|Cff112233|Hitem:0:0:0:0|hand here's a text with \"s and stuff|h|r'", 3)
assert(a1=="simple" and a2=="|Cff112233|Hitem:0:0:0:0|hand here's a text with \"s and stuff|h|r" and a3==nil and a4==1e9, dump(a1,a2,a3,a4))

local a1,a2,a3,a4 = AC:GetArgs("simple \"|Cff112233|Hitem:0:0:0:0|hand here's a text with \"s and stuff|h|r\" 'bar'", 3)
assert(a1=="simple" and a2=="|Cff112233|Hitem:0:0:0:0|hand here's a text with \"s and stuff|h|r" and a3=="bar" and a4==1e9, dump(a1,a2,a3,a4))

local a1,a2,a3,a4 = AC:GetArgs("simple |H|ha 1|h|H|ha 1|h", 3)
assert(a1=="simple" and a2=="|H|ha 1|h|H|ha 1|h" and a3==nil and a4==1e9, dump(a1,a2,a3,a4))

local a1,a2,a3,a4 = AC:GetArgs("simple ||H|ha 1|h|H|ha 1|h", 3)	-- note double ||
assert(a1=="simple" and a2=="||H|ha" and a3=="1|h|H|ha 1|h" and a4==1e9, dump(a1,a2,a3,a4))

local a1,a2,a3,a4 = AC:GetArgs("simple |||H|ha 1|h|H|ha 1|h", 3)	-- note double || followed by |H
assert(a1=="simple" and a2=="|||H|ha 1|h|H|ha 1|h" and a3==nil and a4==1e9, dump(a1,a2,a3,a4))


------------------------------------------------------------
print "OK"
