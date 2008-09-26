
dofile("wow_api.lua")


dofile("LibStub.lua")
dofile("../AceLocale-3.0/AceLocale-3.0.lua")

local AL = assert(LibStub("AceLocale-3.0"))

------------------------------------------
-- Create enUS locale

local L = assert(AL:NewLocale("Loc1", "enUS", true))
L["foo1"] = true

local L = assert(AL:NewLocale("Loc1", "enUS", true))	-- should be ok to add more!
L["foo1"] = "this should not overwrite foo1 since this a default locale"
L["foo2"] = "manual foo2"
L["foo2"] = "this should not overwrite foo2 since this a default locale"


local x="untouched"
ok, msg = pcall(function() x = L["i can't read from write proxies"] end)
assert(not ok, "got: "..tostring(ok))
assert(x=="untouched", "got: "..tostring(x))
assert(strfind(msg, "assertion failed"), "got: "..tostring(msg))




-------------------------------------------
-- Test enUS locale

local L = assert(AL:GetLocale("Loc1"))
assert(L["foo1"] == "foo1")
assert(L["foo2"] == "manual foo2")

-- test warning system for nonexistant strings
local errormsg
function geterrorhandler() return function(msg) errormsg=msg end end

assert(L["this doesn't exist"]=="this doesn't exist")
assert(errormsg=="AceLocale-3.0: Loc1: Missing entry for 'this doesn't exist'", "got: "..errormsg)

-- we shouldnt get warnings for the same string twice
errormsg="no error"

assert(L["this doesn't exist"]=="this doesn't exist")
assert(errormsg=="no error")


-- (don't) create deDE locale
local L = AL:NewLocale("Loc1", "deDE")
assert(not L)




-------------------------------------------
-- Get locale for nonexisting app

-- silent
local L = AL:GetLocale("Loc2", true)
assert(not L)

-- nonsilent - should error
local ok, msg = pcall(function() return AL:GetLocale("Loc2") end)
assert(not ok, "got: "..tostring(ok))
assert(msg=="Usage: GetLocale(application[, silent]): 'application' - No locales registered for 'Loc2'", "got: "..tostring(msg))






---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--
-- Hi2u, we're a german client now!
--


function GetLocale() return "deDE" end

LibStub = nil
dofile("LibStub.lua")
dofile("../AceLocale-3.0/AceLocale-3.0.lua")

local AL = assert(LibStub("AceLocale-3.0"))



assert( not AL:NewLocale("Loc1", "frFR") )  -- no, we're still not french


---------------------------------------------------------------
-- Register deDE

local L = assert(AL:NewLocale("Loc1", "deDE"))
L["yes"]="jawohl"
L["no"]="nein"


---------------------------------------------------------------
-- Register enUS (default)

local L = assert(AL:NewLocale("Loc1", "enUS", true))
L["yes"]=true
L["no"]="no"
L["untranslated"]="untranslated"

---------------------------------------------------------------
-- Test deDE

local L = assert(AL:GetLocale("Loc1"))
assert(L["yes"]=="jawohl")
assert(L["no"]=="nein")
assert(L["untranslated"]=="untranslated")




---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--
-- Test overriding with GAME_LOCALE
--

GAME_LOCALE = "frFR"

assert(not AL:NewLocale("Loc1", "deDE"))		-- shouldn't be krauts anymore now

local L = assert(AL:NewLocale("Loc1", "frFR"))	-- we're frog eaters!
L["yes"] = "oui"

local L = assert(AL:GetLocale("Loc1"))
assert(L["yes"] == "oui")	-- should have been overwritten
assert(L["no"] == "nein") -- should be left from kraut days


---------------------------------------------------------------

print "OK"
