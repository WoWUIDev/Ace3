--- Manages localization in addons, allowing for multiple locale to be registered with fallback to the base locale for untranslated strings.
-- @class file
-- @name AceLocale-3.0
-- @release $Id$
local MAJOR,MINOR = "AceLocale-3.0", 1

local AceLocale, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceLocale then return end -- no upgrade needed

local gameLocale = GetLocale()
if gameLocale == "enGB" then
	gameLocale = "enUS"
end

AceLocale.apps = AceLocale.apps or {}          -- array of ["AppName"]=localetableref
AceLocale.appnames = AceLocale.appnames or {}  -- array of [localetableref]="AppName"

-- This metatable is used on all tables returned from GetLocale
local readmeta = {
	__index = function(self, key)	-- requesting totally unknown entries: fire off a nonbreaking error and return key
		geterrorhandler()(MAJOR..": "..tostring(AceLocale.appnames[self])..": Missing entry for '"..tostring(key).."'")
		rawset(self, key, key)	-- only need to see the warning once, really
		return key
	end
}

-- Remember the locale table being registered right now (it gets set by :NewLocale())
local registering

-- local assert false function
local assertfalse = function() assert(false) end

-- This metatable proxy is used when registering nondefault locales
local writeproxy = setmetatable({}, {
	__newindex = function(self, key, value)
		rawset(registering, key, value == true and key or value) -- assigning values: replace 'true' with key string
	end,
	__index = assertfalse
})

-- This metatable proxy is used when registering the default locale. 
-- It refuses to overwrite existing values
-- Reason 1: Allows loading locales in any order
-- Reason 2: If 2 modules have the same string, but only the first one to be 
--           loaded has a translation for the current locale, the translation
--           doesn't get overwritten.
--
local writedefaultproxy = setmetatable({}, {
	__newindex = function(self, key, value)
		if not rawget(registering, key) then
			rawset(registering, key, value == true and key or value)
		end
	end,
	__index = assertfalse
})

-- AceLocale:NewLocale(application, locale, isDefault)
--
--  application (string)  - unique name of addon / module
--  locale (string)       - name of locale to register, e.g. "enUS", "deDE", etc...
--  isDefault (string)    - if this is the default locale being registered
--
-- Returns a table where localizations can be filled out, or nil if the locale is not needed
function AceLocale:NewLocale(application, locale, isDefault)

	-- GAME_LOCALE allows translators to test translations of addons without having that wow client installed
	-- Ammo: I still think this is a bad idea, for instance an addon that checks for some ingame string will fail, just because some other addon
	-- gives the user the illusion that they can run in a different locale? Ditch this whole thing or allow a setting per 'application'. I'm of the
	-- opinion to remove this.
	local gameLocale = GAME_LOCALE or gameLocale

	if locale ~= gameLocale and not isDefault then
		return -- nop, we don't need these translations
	end
	
	local app = AceLocale.apps[application]
	
	if not app then
		app = setmetatable({}, readmeta)
		AceLocale.apps[application] = app
		AceLocale.appnames[app] = application
	end

	registering = app	-- remember globally for writeproxy and writedefaultproxy
	
	if isDefault then
		return writedefaultproxy
	end

	return writeproxy
end

-- AceLocale:GetLocale(application [, silent])
--
--  application (string) - unique name of addon
--  silent (boolean)     - if true, the locale is optional, silently return nil if it's not found 
--
-- Returns localizations for the current locale (or default locale if translations are missing)
-- Errors if nothing is registered (spank developer, not just a missing translation)
function AceLocale:GetLocale(application, silent)
	if not silent and not AceLocale.apps[application] then
		error("Usage: GetLocale(application[, silent]): 'application' - No locales registered for '"..tostring(application).."'", 2)
	end
	return AceLocale.apps[application]
end
