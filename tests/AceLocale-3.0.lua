dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../AceLocale-3.0/AceLocale-3.0.lua")

local AceLocale = LibStub("AceLocale-3.0")

local loc = AceLocale:NewLocale("test", "enUS")
loc["a"] = "A"
loc["c"] = "C"

local loc = AceLocale:NewLocale("test", "deDE", true)
loc["a"] = "aa"
loc["b"] = "bb"
loc["c"] = "cc"

local locale_3 = AceLocale:NewLocale("test", "frFR")
assert(loc == nil)


local test = AceLocale:GetLocale("test")

assert(test["a"] == "A")
assert(test["b"] == "bb")
assert(test["c"] == "C")

-- Test requesting an unknown string
local oldgeterrorhandler = geterrorhandler
local errors=0
 _G.geterrorhandler = function() return function() errors=errors+1 end end
assert(test["thisdoesntexist"]=="thisdoesntexist")
assert(errors==1)
_G.geterrorhandler=oldgeterrorhandler

------------------------------------------------
-- Test the silent flag working 

AceLocale:NewLocale("test2", "enUS", true, true) -- silent flag set on first locale to be registered
AceLocale:NewLocale("test2", "deDE")
AceLocale:NewLocale("test2", "frFR")

local test2=AceLocale:GetLocale("test2")
assert(test2["thisdoesntexist"]=="thisdoesntexist")


------------------------------------------------
-- Test the silent flag working even if the default locale is registered second

AceLocale:NewLocale("test3", "deDE", false, true)	-- silent flag set on first locale to be registered
AceLocale:NewLocale("test3", "enUS", true)
AceLocale:NewLocale("test3", "frFR")

local test3=AceLocale:GetLocale("test2")
assert(test3["thisdoesntexist"]=="thisdoesntexist")



------------------------------------------------
print "OK"