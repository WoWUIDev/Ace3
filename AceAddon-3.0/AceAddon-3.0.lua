--[[ $Id$ ]]
local MAJOR, MINOR = "AceAddon-3.0", 0
local AceAddon, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceAddon then return end -- No Upgrade needed.

AceAddon.frame = AceAddon.frame or CreateFrame("Frame", "AceAddon30Frame") -- Our very own frame
AceAddon.addons = AceAddon.addons or {} -- addons in general
AceAddon.statuses = AceAddon.statues or {} -- statuses of addon.
AceAddon.initializequeue = AceAddon.initializequeue or {} -- addons that are new and not initialized
AceAddon.enablequeue = AceAddon.enablequeue or {} -- addons that are initialized and waiting to be enabled
AceAddon.embeds = AceAddon.embeds or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end }) -- contains a list of libraries embedded in an addon

local function safecall(func, ...)
	-- we check to see if the func is passed is actually a function here and don't error when it isn't
	-- this safecall is used for optional functions like OnInitialize OnEnable etc. When they are not
	-- present execution should continue without hinderance
	if type(func) == "function" then
		local success, err = pcall(func, ...)
		if success then return err end
		
		if not err:find("%.lua:%d+:") then err = (debugstack():match("\n(.-: )in.-\n") or "") .. err end
		geterrorhandler()(err)
	end
end

-- local functions that will be implemented further down
local Embed, NewModule, GetModule, SetDefaultModuleState, SetDefaultModuleLibraries, SetEnabledState, SetDefaultPrototype

-- used in the addon metatable
local function addontostring( self ) return self.name end 

-- AceAddon:NewAddon( name, [lib, lib, lib, ...] )
-- name (string) - unique addon object name
-- [lib] (string) - optional libs to embed in the addon object
--
-- returns the addon object when succesful
function AceAddon:NewAddon(name, ...)
	if type(name) ~= "string" then error(("Usage: NewAddon(name, [lib, lib, lib, ...]): 'name' - string expected got '%s'."):format(type(name)), 2) end
	
	if self.addons[name] then error(("Usage: NewAddon(name, [lib, lib, lib, ...]): 'name' - Addon '%s' already exists."):format(name), 2) end
	
	local addon = setmetatable( {name = name}, { __tostring = addontostring } )
	self.addons[name] = addon
	addon.modules = {}
	addon.defaultModuleLibraries = {}
	Embed( addon ) -- embed NewModule, GetModule methods
	self:EmbedLibraries(addon, ...)
	
	-- add to queue of addons to be initialized upon ADDON_LOADED
	table.insert(self.initializequeue, addon)
	return addon
end

-- AceAddon:GetAddon( name, [silent])
-- name (string) - unique addon object name
-- silent (boolean) - if true, addon is optional, silently return nil if its not found
--
-- throws an error if the addon object can not be found (except silent is set)
-- returns the addon object if found
function AceAddon:GetAddon(name, silent)
	if not silent and not self.addons[name] then
		error(("Usage: GetAddon(name): 'name' - Cannot find an AceAddon '%s'."):format(tostring(name)), 2)
	end
	return self.addons[name]
end

-- AceAddon:EmbedLibraries( addon, [lib, lib, lib, ...] )
-- addon (object) - addon to embed the libs in
-- [lib] (string) - optional libs to embed
function AceAddon:EmbedLibraries(addon, ...)
	for i=1,select("#", ... ) do
		local libname = select(i, ...)
		self:EmbedLibrary(addon, libname, false, 3)
	end
end

-- AceAddon:EmbedLibrary( addon, libname, silent, offset )
-- addon (object) - addon to embed the libs in
-- libname (string) - lib to embed
-- [silent] (boolean) - optional, marks an embed to fail silently if the library doesn't exist.
-- [offset] (number) - will push the error messages back to said offset defaults to 2
function AceAddon:EmbedLibrary(addon, libname, silent, offset)
	local lib = LibStub:GetLibrary(libname, true)
	if not lib and not silent then
		error(("Usage: EmbedLibrary(addon, libname, silent, offset): 'libname' - Cannot find a library instance of %q."):format(tostring(libname)), offset or 2)
	elseif lib and type(lib.Embed) == "function" then
		lib:Embed(addon)
		table.insert(self.embeds[addon], libname)
		return true
	elseif lib then
		error(("Usage: EmbedLibrary(addon, libname, silent, offset): 'libname' - Library '%s' is not Embed capable"):format(libname), offset or 2)
	end
end

-- addon:GetModule( name, [silent])
-- name (string) - unique module object name
-- silent (boolean) - if true, module is optional, silently return nil if its not found
--
-- throws an error if the addon object can not be found (except silent is set)
-- returns the module object if found
function GetModule(self, name, silent)
	if not self.modules[name] and not silent then
		error(("Usage: GetModule(name, silent): 'name' - Cannot find module '%s'."):format(tostring(name)), 2)
	end
	return self.modules[name]
end

local function IsModuleTrue(self) return true end

-- addon:NewModule( name, [prototype, [lib, lib, lib, ...] )
-- name (string) - unique module object name for this addon
-- prototype (object) - object to derive this module from, methods and values from this table will be mixed into the module, if a string is passed a lib is assumed
-- [lib] (string) - optional libs to embed in the addon object
--
-- returns the addon object when succesful
function NewModule(self, name, prototype, ...)
	if type(name) ~= "string" then error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'name' - string expected got '%s'."):format(type(name)), 2) end
	if type(prototype) ~= "string" and type(prototype) ~= "table" and type(prototype) ~= "nil" then error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'prototype' - table (prototype), string (lib) or nil expected got '%s'."):format(type(prototype)), 2) end
	
	if self.modules[name] then error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'name' - Module '%s' already exists."):format(name), 2) end
	
	-- modules are basically addons. We treat them as such. They will be added to the initializequeue properly as well.
	-- NewModule can only be called after the parent addon is present thus the modules will be initialized after their parent is.
	local module = AceAddon:NewAddon(("%s_%s"):format(self.name or tostring(self), name))
	
	module.IsModule = IsModuleTrue
	module:SetEnabledState(self.defaultModuleState)

	if type(prototype) == "string" then
		AceAddon:EmbedLibraries(module, prototype, ...)
	else
		AceAddon:EmbedLibraries(module, ...)
	end
	AceAddon:EmbedLibraries(module, unpack(self.defaultModuleLibraries))

	if not prototype or type(prototype) == "string" then
		prototype = self.defaultModulePrototype or nil
	end
	
	if type(prototype) == "table" then
		local mt = getmetatable(module)
		mt.__index = prototype
		setmetatable(module, mt)  -- More of a Base class type feel.
	end
	
	safecall(self.OnModuleCreated, self, module) -- Was in Ace2 and I think it could be a cool thing to have handy.
	self.modules[name] = module
	
	return module
end

-- addon:SetDefaultModuleLibraries( [lib, lib, lib, ...]  )
-- [lib] (string) - libs to embed in every module
function SetDefaultModuleLibraries(self, ...)
	self.defaultModuleLibraries = {...}
end

-- addon:SetDefaultModuleState( state )
-- state (boolean) - default state for new modules (enabled=true, disabled=false)
function SetDefaultModuleState(self, state)
	self.defaultModuleState = state
end

-- addon:SetDefaultModulePrototype( prototype )
-- prototype (string or table) - the default prototype to use if none is specified on module creation
function SetDefaultModulePrototype(self, prototype)
	if type(prototype) ~= "table" then
		error(("Usage: SetDefaultModulePrototype(prototype): 'prototype' - table expected got '%s'."):format(type(prototype)), 2)
	end
	self.defaultModulePrototype = prototype
end

-- addon:SetEnabledState ( state )
-- state ( boolean ) - set the state of an addon or module  (enabled=true, disabled=false)
--
-- should only be called before any Enabling actually happend, aka in OnInitialize
function SetEnabledState(self, state)
	self.enabledState = state
end


local function IterateModules(self) return pairs(self.modules) end
local function IterateEmbeds(self) return pairs(AceAddon.embeds[self]) end
local mixins = {
	NewModule = NewModule,
	GetModule = GetModule,
	SetDefaultModuleLibraries = SetDefaultModuleLibraries,
	SetDefaultModuleState = SetDefaultModuleState,
	SetDefaultModulePrototype = SetDefaultModulePrototype,
	SetEnabledState = SetEnabledState,
	IterateModules = IterateModules,
	IterateEmbeds = IterateEmbeds,
}
local function IsModule(self) return false end
local pmixins = {
	defaultModuleState = true,
	enabledState = true,
	IsModule = IsModule,
}
-- Embed( target )
-- target (object) - target object to embed aceaddon in
--
-- this is a local function specifically since it's meant to be only called internally
function Embed(target)
	for k, v in pairs(mixins) do
		target[k] = v
	end
	for k, v in pairs(pmixins) do
		target[k] = target[k] or v
	end
end


-- AceAddon:IntializeAddon( addon )
-- addon (object) - addon to intialize
--
-- calls OnInitialize on the addon object if available
-- calls OnEmbedInitialize on embedded libs in the addon object if available
function AceAddon:InitializeAddon(addon)
	safecall(addon.OnInitialize, addon)
	
	for k, libname in ipairs(self.embeds[addon]) do
		local lib = LibStub:GetLibrary(libname, true)
		if lib then safecall(lib.OnEmbedInitialize, lib, addon) end
	end
	
	-- we don't call InitializeAddon on modules specifically, this is handled
	-- from the event handler and only done _once_
end

-- AceAddon:EnableAddon( addon )
-- addon (object) - addon to enable
--
-- calls OnEnable on the addon object if available
-- calls OnEmbedEnable on embedded libs in the addon object if available
function AceAddon:EnableAddon(addon)
	if self.statuses[addon.name] or not addon.enabledState then return false end
	-- TODO: handle 'first'? Or let addons do it on their own?
	safecall(addon.OnEnable, addon)
	for k, libname in ipairs(self.embeds[addon]) do
		local lib = LibStub:GetLibrary(libname, true)
		if lib then safecall(lib.OnEmbedEnable, lib, addon) end
	end
	self.statuses[addon.name] = true
	
	-- enable possible modules.
	for name, module in pairs(addon.modules) do
		self:EnableAddon(module)
	end
	
	return true
end

-- AceAddon:DisableAddon( addon )
-- addon (object) - addon to disable
--
-- calls OnDisable on the addon object if available
-- calls OnEmbedDisable on embedded libs in the addon object if available
function AceAddon:DisableAddon(addon)
	if not self.statuses[addon.name] then return false end
	safecall( addon.OnDisable, addon )
	for k, libname in ipairs(self.embeds[addon]) do
		local lib = LibStub:GetLibrary(libname, true)
		if lib then safecall(lib.OnEmbedDisable, lib, addon) end
	end
	self.statuses[addon.name] = nil
	
	-- disable possible modules.
	for name, module in pairs(addon.modules) do
		self:DisableAddon(module)
	end
	
	return true
end

--The next few funcs are just because no one should be reaching into the internal registries
--Thoughts?
function AceAddon:IterateAddons() return pairs(self.addons) end
function AceAddon:IterateEmbedsOnAddon(addon) return pairs(self.embeds[addon]) end
function AceAddon:IterateAddonStatus() return pairs(self.statuses) end
function AceAddon:IterateModulesOfAddon(addon) return pairs(addon.modules) end

-- Event Handling
local function onEvent(this, event, arg1)
	if event == "ADDON_LOADED" or event == "PLAYER_LOGIN" then
		for i = 1, #AceAddon.initializequeue do
			local addon = AceAddon.initializequeue[i]
			if event == "ADDON_LOADED" then addon.baseName = arg1 end
			AceAddon:InitializeAddon(addon)
			AceAddon.initializequeue[i] = nil
			table.insert(AceAddon.enablequeue, addon)
		end
		
		if IsLoggedIn() then
			for i = 1, #AceAddon.enablequeue do
				local addon = AceAddon.enablequeue[i]
				AceAddon:EnableAddon(addon)
				AceAddon.enablequeue[i] = nil
			end
		end
	end
end

AceAddon.frame:RegisterEvent("ADDON_LOADED")
AceAddon.frame:RegisterEvent("PLAYER_LOGIN")
AceAddon.frame:SetScript("OnEvent", onEvent)

-- upgrade embeded
for name, addon in pairs(AceAddon.addons) do
	Embed(addon)
end
