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

local loc = AceLocale:NewLocale("test", "frFR")
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

local loc = AceLocale:NewLocale("test2", "enUS", true, true) -- silent flag set on first locale to be registered
loc["This Exists"]=true
AceLocale:NewLocale("test2", "deDE")
AceLocale:NewLocale("test2", "frFR")

local test2=AceLocale:GetLocale("test2")
assert(test2["thisdoesntexist"]=="thisdoesntexist")
assert(test2["This Exists"]=="This Exists")


------------------------------------------------
-- Test the silent flag working even if the default locale is registered second

AceLocale:NewLocale("test3", "deDE", false, true)	-- silent flag set on first locale to be registered
AceLocale:NewLocale("test3", "enUS", true)
AceLocale:NewLocale("test3", "frFR")

local test3=AceLocale:GetLocale("test3")
assert(test3["thisdoesntexist"]=="thisdoesntexist")
assert(test3["This Exists"]=="This Exists")


------------------------------------------------
-- Test the silent flag warning when using it on nonfirst

local oldgeterrorhandler = geterrorhandler
local errors=0
_G.geterrorhandler = function() return function() errors=errors+1 end end

AceLocale:NewLocale("test3a", "deDE")
AceLocale:NewLocale("test3a", "enUS", true, true)
AceLocale:NewLocale("test3a", "frFR")

assert(errors==1)
_G.geterrorhandler=oldgeterrorhandler


------------------------------------------------
-- Test silent="raw" working 

local loc = AceLocale:NewLocale("test4", "enUS", true, "raw")
loc["This Exists"]=true
AceLocale:NewLocale("test4", "deDE")
AceLocale:NewLocale("test4", "frFR")

local test4=AceLocale:GetLocale("test4")
assert(test4["thisdoesntexist"]==nil)
assert(test4["This Exists"]=="This Exists")


------------------------------------------------
-- Test that we can re-get an already-created locale so we can write more to it

local loc = AceLocale:NewLocale("test5", "enUS")
loc["orig1"]=true
loc["orig2"]="orig2"
loc["orig3"]=true
loc["orig4"]="orig4"

local loc = AceLocale:NewLocale("unrelatedLocale", "enUS")  -- touch something else in between to make extra sure

local loc = AceLocale:NewLocale("test5", "enUS")
loc["orig3"]="NEWorig3"
loc["orig4"]="NEWorig4"
loc["orig5"]="thisneverexisted"

local test5=AceLocale:GetLocale("test5")
assert(test5["orig1"]=="orig1")
assert(test5["orig2"]=="orig2")
assert(test5["orig3"]=="NEWorig3")
assert(test5["orig4"]=="NEWorig4")
assert(test5["orig5"]=="thisneverexisted")


------------------------------------------------
print "OK"