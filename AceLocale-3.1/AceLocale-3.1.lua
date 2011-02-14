--- **AceLocale-3.1** manages localization in addons, allowing for multiple locale to be registered with fallback to the base locale for untranslated strings.  AceLocale-3.1 is experimental.
-- @class file
-- @name AceLocale-3.0
-- @release $Id: AceLocale-3.0.lua 1005 2011-01-29 14:19:43Z mikk $
local MAJOR, MINOR = "AceLocale-3.1", 1

local AceLocale, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceLocale then return end -- no upgrade needed

-- Lua APIs
local assert, tostring, error = assert, tostring, error
local setmetatable, rawset, rawget = setmetatable, rawset, rawget

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: GAME_LOCALE, geterrorhandler

local gameLocale = GetLocale()
if gameLocale == "enGB" then
    gameLocale = "enUS"
end

AceLocale.apps = AceLocale.apps or {} -- array of ["AppName"]=localetableref
AceLocale.appnames = AceLocale.appnames or {} -- array of [localetableref]="AppName"
AceLocale.appmodes = AceLocale.appmodes or {}
AceLocale.applocales = AceLocale.applocales or {}

AceLocale.KEY_ON_MISSING = "KEY_ON_MISSING"
AceLocale.WARN_ON_MISSING = "WARN_ON_MISSING"
AceLocale.NIL_ON_MISSING = "NIL_ON_MISSING"

local read_metatables = {
    KEY_ON_MISSING = {
        -- returns the key for missing strings, no warning
        __index = function(self, key)
            rawset(self, key, key)
            return key
        end
    },
    WARN_ON_MISSING = {
        -- returns the key for missing strings, but gives a warning
        __index = function(self, key)
            rawset(self, key, key)
            geterrorhandler()(MAJOR .. ": " .. tostring(AceLocale.appnames[self]) .. ": Missing entry for '" .. tostring(key) .. "'")
            return key
        end
    },
    NIL_ON_MISSING = false -- this is here just so that the error checking in SetMode works properly
}

local registering_app
local write_metatables = {
    DEFAULT = setmetatable({}, {
        __newindex = function(self, key, value)
            if not rawget(registering_app, key) then
                rawset(registering_app, key, value == true and key or value)
            end
        end,
        __index = function() assert(false) end
    }),
    LOCALE = setmetatable({}, {
        __newindex = function(self, key, value)
            rawset(registering_app, key, value == true and key or value)
        end,
        __index = function() assert(false) end
    })
}

--- Override the results of GetLocale() for a specific application.
-- This must be called _before_ the first call to NewLocale for a given application.
-- @paramsig application, locale
-- @param application Unique name of the addon / module
-- @param locale Name of the locale to use
-- @usage
-- -- in this example we're wanting to test how the german looks in the addon
-- -- todo this we must call SetLocale before any NewLocale calls
-- local AceLocale = LibStub("AceLocale-3.1")
-- AceLocale:SetLocale("MyAddon", "deDE") -- testing how my addon looks in german
--
-- local L = AceLocale:NewLocale("MyAddon", "enUS", true)
-- L["string1"] = true
--
-- local L = AceLocale:NewLocale("MyAddon", "deDE")
-- L["string1"] = "Zeichenkette1"
--
-- local L = AceLocale:GetLocale("MyAddon")
-- local var = L["string1"] -- will always result in "Zeichenkette1" regardless of what game client locale you're running on
function AceLocale:SetLocale(application, locale)
    if self.apps[application] then
        error("Usage: GetLocale(application, locale): must be called before the first call to NewLocale.", 2)
    end

    self.applocales[application] = locale
end

--- Determines how AceLocale handles keys missing in the translation tables
-- Valid modes are:
-- * AceLocale.KEY_ON_MISSING - returns the key passed in
-- * AceLocale.WARN_ON_MISSING - issues a warning, and then returns the key passed in
-- * AceLocale.NIL_ON_MISSING - fails silently returning nil
-- @paramsig application, mode
-- @param application Unique name of the addon / module
-- @param mode The flag that sets how to handle the missing keys. The default is KEY_ON_MISSING
-- @usage
-- local AceLocale = LibStub("AceLocale-3.1")
--
-- local L = AceLocale:NewLocale("MyAddon", "enUS", true)
-- L["string1"] = true
--
-- local L = AceLocale:NewLocale("MyAddon", "deDE")
-- L["string1"] = "Zeichenkette1"
--
-- local L = AceLocale:GetLocale("MyAddon")
-- local var = L["string2"] -- will result in "string2"
--
-- AceLocale:SetMode("MyAddon", AceLocale.NIL_ON_MISSING)
-- local var = L["string2"] -- will result in in nil
function AceLocale:SetMode(application, mode)
    if not mode then
        mode = self.KEY_ON_MISSING
    end

    if not read_metatables[mode] then
        error("Usage: SetMode(application, mode): 'mode' - Invalid mode '" .. tostring(mode) .. "' used.", 2)
    end

    self.appmodes[application] = mode

    local app = self.apps[application]
    if app then
        setmetatable(app, read_metatables[mode] or nil) -- changes the false to a nil for NIL_ON_MISSING
    end
end

--- Register a new locale (or extend an existing one) for the specified application,
-- returns a table you can fill your locale into, or nil if the locale doesn't need to be loaded
-- @paramsig application, locale[, isDefault]
-- @param application Unique name of addon / module
-- @param locale Name of the locale to register, e.g. "enUS", "deDE", etc.
-- @param isDefault If this is the default locale being registered (your addon is written in this language, generally enUS).  This should only be passed in for _one_ locale.
-- @usage
-- -- enUS.lua
-- local L = LibStub("AceLocale-3.0"):NewLocale("MyAddon", "enUS", true)
-- L["string1"] = true
--
-- -- deDE.lua
-- local L = LibStub("AceLocale-3.0"):NewLocale("MyAddon", "deDE")
-- if not L then return end
-- L["string1"] = "Zeichenkette1"
-- @return Locale Table to add localizations to, or nil if the current locale is not needed.
function AceLocale:NewLocale(application, locale, isDefault)
    local app = AceLocale.apps[application]

    if not app then
        app = {}
        self.apps[application] = app
        self.appnames[app] = application
        self:SetMode(application, self.appmodes[application])
    end

    local targetLocale = self.applocales[application] or gameLocale

    if locale ~= targetLocale and not isDefault then
        return
    end

    registering_app = app
    return isDefault and write_metatables["DEFAULT"] or write_metatables["LOCALE"]
end

--- Returns localizations for the current locale (or default locale if translations are missing).
-- Errors if nothing is registered (spank developer, not just a missing translation)
-- @param application Unique name of addon / module
-- @param silent If true, the locale is optional, silently return nil if it's not found (defaults to false, optional)
-- @return The locale table for the current language.
function AceLocale:GetLocale(application, silent)
    if not silent and not AceLocale.apps[application] then
        error("Usage: GetLocale(application[, silent]): 'application' - No locales registered for '" .. tostring(application) .. "'", 2)
    end
    return AceLocale.apps[application]
end
