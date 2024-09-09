local MAJOR, MINOR = "AceState-3.0", 1
local AceState, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not AceState then
	return -- No upgrade needed
end

-- Register a reducer with the initial state and the reducer function
function AceState:RegisterReducer(name, initialState, reducer)
	-- If the reducer is a string, it should be a method on the addon
	if type(reducer) == "string" then
		if not self[reducer] or type(self[reducer]) ~= "function" then
			error("Reducer method " .. reducer .. " does not exist on addon")
		end
		reducer = self[reducer]
	elseif type(reducer) ~= "function" then
		error("Reducer must be a function or a string referring to a method on the addon.")
	end

	-- Return a dispatch function for this reducer
	local dispatch = function(actionType, payload)
		local oldState = self.DeepCopy(self.state[name])
		local newState = self.reducers[name](oldState, actionType, payload)

		-- Update the state
		for k, v in pairs(newState) do
			self.state[name][k] = v
		end
		for k in pairs(self.state[name]) do
			if newState[k] == nil then
				self.state[name][k] = nil
			end
		end
	end

	-- Store the initial state and the reducer
	self.state = self.state or {}
	self.state[name] = initialState
	self.reducers = self.reducers or {}
	self.reducers[name] = reducer
	self.dispatchers = self.dispatchers or {}
	self.dispatchers[name] = dispatch

	return dispatch
end

-- Dispatch an action to all reducers
function AceState:Dispatch(actionType, payload)
	if not self.reducers then
		error("No reducers registered")
	end

	for _, dispatch in pairs(self.dispatchers) do
		dispatch(actionType, payload)
	end
end

-- Get the current state
function AceState:GetState(name)
	if name then
		return self.state and self.state[name]
	else
		return self.state
	end
end

-- Utility function for creating deep copies of objects.
function AceState:DeepCopy(orig, seen)
	if type(orig) ~= "table" then
		return orig
	end
	if seen and seen[orig] then
		return seen[orig]
	end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(orig))
	s[orig] = res
	for k, v in pairs(orig) do
		res[self.DeepCopy(k, s)] = self.DeepCopy(v, s)
	end
	return res
end

-- Embedding
AceState.embeds = AceState.embeds or {}

local mixins = {
	"RegisterReducer",
	"Dispatch",
	"GetState",
}

-- Embed AceState into another addon
function AceState:Embed(target)
	for _, v in ipairs(mixins) do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

-- Handle disabling of an addon
function AceState:OnEmbedDisable(target)
	self[target] = nil
end

-- Re-embed in case of upgrades
for addon in pairs(AceState.embeds) do
	AceState:Embed(addon)
end
