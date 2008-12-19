--- Safe Hooking/Unhooking of functions, methods and frame scripts.
-- @class file
-- @name AceHook-3.0
-- @release $Id$
local ACEHOOK_MAJOR, ACEHOOK_MINOR = "AceHook-3.0", 4
local AceHook, oldminor = LibStub:NewLibrary(ACEHOOK_MAJOR, ACEHOOK_MINOR)

if not AceHook then return end -- No upgrade needed

AceHook.embeded = AceHook.embeded or {}
AceHook.registry = AceHook.registry or setmetatable({}, {__index = function(tbl, key) tbl[key] = {} return tbl[key] end })
AceHook.handlers = AceHook.handlers or {}
AceHook.actives = AceHook.actives or {}
AceHook.scripts = AceHook.scripts or {}
AceHook.onceSecure = AceHook.onceSecure or {}
AceHook.hooks = AceHook.hooks or {}

-- local upvalues
local registry = AceHook.registry
local handlers = AceHook.handlers
local actives = AceHook.actives
local scripts = AceHook.scripts
local onceSecure = AceHook.onceSecure

local _G = _G
local format = string.format
local next = next
local pairs = pairs
local type = type

-- functions for later definition
local donothing, createHook, hook

local protectedScripts = {
	OnClick = true,
}

-- upgrading of embeded is done at the bottom of the file

local mixins = {
	"Hook", "SecureHook",
	"HookScript", "SecureHookScript",
	"Unhook", "UnhookAll",
	"IsHooked",
	"RawHook", "RawHookScript"
}

-- AceHook:Embed( target )
-- target (object) - target object to embed AceHook in
--
-- Embeds AceEevent into the target object making the functions from the mixins list available on target:..
function AceHook:Embed( target )
	for k, v in pairs( mixins ) do
		target[v] = self[v]
	end
	self.embeded[target] = true
	-- inject the hooks table safely
	target.hooks = target.hooks or {}
	return target
end

-- AceHook:OnEmbedDisable( target )
-- target (object) - target object that is being disabled
--
-- Unhooks all hooks when the target disables.
-- this method should be called by the target manually or by an addon framework
function AceHook:OnEmbedDisable( target )
	target:UnhookAll()
end

function createHook(self, handler, orig, secure, failsafe)
	local uid
	local method = type(handler) == "string"
	if failsafe and not secure then
		-- failsafe hook creation
		uid = function(...)
			if actives[uid] then
				if method then
					self[handler](self, ...)
				else
					handler(...)
				end
			end
			return orig(...)
		end
		-- /failsafe hook
	else
		-- all other hooks
		uid = function(...)
			if actives[uid] then
				if method then
					return self[handler](self, ...)
				else
					return handler(...)
				end
			elseif not secure then -- backup on non secure
				return orig(...)
			end
		end
		-- /hook
	end
	return uid
end

function donothing() end

function hook(self, obj, method, handler, script, secure, raw, forceSecure, usage)
	if not handler then handler = method end
	
	-- These asserts make sure AceHooks's devs play by the rules.
	assert(not script or type(script) == "boolean")
	assert(not secure or type(secure) == "boolean")
	assert(not raw or type(raw) == "boolean")
	assert(not forceSecure or type(forceSecure) == "boolean")
	assert(usage)
	
	-- Error checking Battery!
	if obj and type(obj) ~= "table" then
		error(format("%s: 'object' - nil or table expected got %s", usage, type(obj)), 3)
	end
	if type(method) ~= "string" then
		error(format("%s: 'method' - string expected got %s", usage, type(method)), 3)
	end
	if type(handler) ~= "string" and type(handler) ~= "function" then
		error(format("%s: 'handler' - nil, string, or function expected got %s", usage, type(handler)), 3)
	end
	if type(handler) == "string" and type(self[handler]) ~= "function" then
		error(format("%s: 'handler' - Handler specified does not exist at self[handler]", usage), 3)
	end
	if script then
	 	if not secure and obj:IsProtected() and protectedScripts[method] then
			error(format("Cannot hook secure script %q; Use SecureHookScript(obj, method, [handler]) instead.", method), 3)
		end
		if not obj or not obj.GetScript or not obj:HasScript(method) then
			error(format("%s: You can only hook a script on a frame object", usage), 3)
		end
	else
		local issecure 
		if obj then 
			issecure = onceSecure[obj] and onceSecure[obj][method] or issecurevariable(obj, method)
		else
			issecure = onceSecure[method] or issecurevariable(method)
		end
		if issecure then
			if forceSecure then
				if obj then
					onceSecure[obj] = onceSecure[obj] or {}
					onceSecure[obj][method] = true
				else
					onceSecure[method] = true
				end
			elseif not secure then
				error(format("%s: Attempt to hook secure function %s. Use `SecureHook' or add `true' to the argument list to override.", usage, method), 3)
			end
		end
	end
	
	local uid
	if obj then
		uid = registry[self][obj] and registry[self][obj][method]
	else
		uid = registry[self][method]
	end
	
	if uid then
		if actives[uid] then
			-- Only two sane choices exist here.  We either a) error 100% of the time or b) always unhook and then hook
			-- choice b would likely lead to odd debuging conditions or other mysteries so we're going with a.
			error(format("Attempting to rehook already active hook %s.", method))
		end
		
		if handlers[uid] == handler then -- turn on a decative hook, note enclosures break this ability, small memory leak
			actives[uid] = true
			return
		elseif obj then -- is there any reason not to call unhook instead of doing the following several lines?
			if self.hooks and self.hooks[obj] then
				self.hooks[obj][method] = nil
			end
			registry[self][obj][method] = nil
		else
			if self.hooks then
				self.hooks[method] = nil
			end
			registry[self][method] = nil
		end
		handlers[uid], actives[uid], scripts[uid] = nil, nil, nil
		uid = nil
	end
	
	local orig
	if script then
		orig = obj:GetScript(method) or donothing
	elseif obj then
		orig = obj[method]
	else
		orig = _G[method]
	end
	
	if not orig then
		error(format("%s: Attempting to hook a non existing target", usage), 3)
	end
	
	uid = createHook(self, handler, orig, secure, not (raw or secure))
	
	if obj then
		self.hooks[obj] = self.hooks[obj] or {}
		registry[self][obj] = registry[self][obj] or {}
		registry[self][obj][method] = uid

		if not secure then
			if script then
				obj:SetScript(method, uid)
			else
				obj[method] = uid
			end
			self.hooks[obj][method] = orig
		else
			if script then
				obj:HookScript(method, uid)
			else
				hooksecurefunc(obj, method, uid)
			end
		end
	else
		registry[self][method] = uid
		
		if not secure then
			_G[method] = uid
			self.hooks[method] = orig
		else
			hooksecurefunc(method, uid)
		end
	end
	
	actives[uid], handlers[uid], scripts[uid] = true, handler, script and true or nil	
end

-- ("function" [, handler] [, hookSecure]) or (object, "method" [, handler] [, hookSecure])
function AceHook:Hook(object, method, handler, hookSecure)
	if type(object) == "string" then
		method, handler, hookSecure, object = object, method, handler, nil
	end
	
	if handler == true then
		handler, hookSecure = nil, true
	end

	hook(self, object, method, handler, false, false, false, hookSecure or false, "Usage: Hook([object], method, [handler], [hookSecure])")	
end

-- ("function" [, handler] [, hookSecure]) or (object, "method" [, handler] [, hookSecure])
function AceHook:RawHook(object, method, handler, hookSecure)
	if type(object) == "string" then
		method, handler, hookSecure, object = object, method, handler, nil
	end
	
	if handler == true then
		handler, hookSecure = nil, true
	end
	
	hook(self, object, method, handler, false, false, true, hookSecure or false,  "Usage: RawHook([object], method, [handler], [hookSecure])")
end

-- ("function", handler) or (object, "method", handler)
function AceHook:SecureHook(object, method, handler)
	if type(object) == "string" then
		method, handler, object = object, method, nil
	end
	
	hook(self, object, method, handler, false, true, false, false,  "Usage: SecureHook([object], method, [handler])")
end

function AceHook:HookScript(frame, script, handler)
	hook(self, frame, script, handler, true, false, false, false,  "Usage: HookScript(object, method, [handler])")
end

function AceHook:RawHookScript(frame, script, handler)
	hook(self, frame, script, handler, true, false, true, false, "Usage: RawHookScript(object, method, [handler])")
end

function AceHook:SecureHookScript(frame, script, handler)
	hook(self, frame, script, handler, true, true, false, false, "Usage: SecureHookScript(object, method, [handler])")
end

-- ("function") or (object, "method")
function AceHook:Unhook(obj, method)
	local usage = "Usage: Unhook([obj], method)"
	if type(obj) == "string" then
		method, obj = obj, nil
	end
		
	if obj and type(obj) ~= "table" then
		error(format("%s: 'obj' - expecting nil or table got %s", usage, type(obj)), 2)
	end
	if type(method) ~= "string" then
		error(format("%s: 'method' - expeting string got %s", usage, type(method)), 2)
	end
	
	local uid
	if obj then
		uid = registry[self][obj] and registry[self][obj][method]
	else
		uid = registry[self][method]
	end
	
	if not uid or not actives[uid] then
		-- Declining to error on an unneeded unhook since the end effect is the same and this would just be annoying.
		return false
	end
	
	actives[uid], handlers[uid] = nil, nil
	
	if obj then
		registry[self][obj][method] = nil
		registry[self][obj] = next(registry[self][obj]) and registry[self][obj] or nil
		
		-- if the hook reference doesnt exist, then its a secure hook, just bail out and dont do any unhooking
		if not self.hooks[obj] or not self.hooks[obj][method] then return true end
		
		if scripts[uid] and obj:GetScript(method) == uid then  -- unhooks scripts
			obj:SetScript(method, self.hooks[obj][method] ~= donothing and self.hooks[obj][method] or nil)	
			scripts[uid] = nil
		elseif obj and self.hooks[obj] and self.hooks[obj][method] and obj[method] == uid then -- unhooks methods
			obj[method] = self.hooks[obj][method]
		end
		
		self.hooks[obj][method] = nil
		self.hooks[obj] = next(self.hooks[obj]) and self.hooks[obj] or nil
	else
		registry[self][method] = nil
		
		-- if self.hooks[method] doesn't exist, then this is a SecureHook, just bail out
		if not self.hooks[method] then return true end
		
		if self.hooks[method] and _G[method] == uid then -- unhooks functions
			_G[method] = self.hooks[method]
		end
		
		self.hooks[method] = nil
	end
	return true
end

function AceHook:UnhookAll()
	for key, value in pairs(registry[self]) do
		if type(key) == "table" then
			for method in pairs(value) do
				self:Unhook(key, method)
			end
		else
			self:Unhook(key)
		end
	end
end

-- ("function") or (object, "method")
function AceHook:IsHooked(obj, method)
	-- we don't check if registry[self] exists, this is done by evil magicks in the metatable
	if type(obj) == "string" then
		if registry[self][obj] and actives[registry[self][obj]] then
			return true, handlers[registry[self][obj]]
		end
	else
		if registry[self][obj] and registry[self][obj][method] and actives[registry[self][obj][method]] then
			return true, handlers[registry[self][obj][method]]
		end
	end
	
	return false, nil
end

--- Upgrade our old embeded
for target, v in pairs( AceHook.embeded ) do
	AceHook:Embed( target )
end
