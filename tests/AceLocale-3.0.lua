dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../AceLocale-3.0/AceLocale-3.0.lua")

local AceLocale = LibStub("AceLocale-3.0")

local locale_1 = AceLocale:NewLocale("test", "enUS")
locale_1["a"] = "A"
locale_1["c"] = "C"

local locale_2 = AceLocale:NewLocale("test", "deDE", true)
locale_2["a"] = "aa"
locale_2["b"] = "bb"
locale_2["c"] = "cc"

local locale_3 = AceLocale:NewLocale("test", "frFR")

local locale_4 = AceLocale:GetLocale("test")

--[[ no longer true with proxy metatables /mikk   assert(locale_2 == locale_1) ]]
assert(locale_3 == nil)
--[[ no longer true with proxy metatables /mikk   assert(locale_4 == locale_1) ]]

print(locale_4["a"], locale_4["b"], locale_4["c"])
assert(locale_4["a"] == "A")
assert(locale_4["b"] == "bb")
assert(locale_4["c"] == "C")

------------------------------------------------
print "OK"