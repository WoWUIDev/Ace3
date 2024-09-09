dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../AceState-3.0/AceState-3.0.lua")

-- Test RegisterReducer
do
	local AceState = LibStub("AceState-3.0")
	local initialState = { count = 0 }
	local reducer = function(state, actionType, payload)
		if actionType == "INCREMENT" then
			return { count = state.count + 1 }
		else
			return state
		end
	end
	local dispatch = AceState:RegisterReducer("count", initialState, reducer)
	-- Dispatching no actions should leave count at zero.
	assert(AceState:GetState("count").count == 0)
end

-- Test Dispatch
do
	local AceState = LibStub("AceState-3.0")
	local initialState = { count = 0 }
	local reducer = function(state, actionType, payload)
		if actionType == "INCREMENT" then
			if not payload then
				payload = 1
			end
			return { count = state.count + payload }
		else
			return state
		end
	end
	local dispatch = AceState:RegisterReducer("count", initialState, reducer)
	dispatch("INCREMENT")
	assert(AceState:GetState("count").count == 1)
	dispatch("INCREMENT", 5)
	assert(AceState:GetState("count").count == 6)
end

-- Test Embed
do
	local MyAddon = {}
	local AceState = LibStub("AceState-3.0"):Embed(MyAddon)
	local initialState = { count = 0 }
	local reducer = function(state, actionType, payload)
		if actionType == "INCREMENT" then
			return { count = state.count + 1 }
		else
			return state
		end
	end
	local dispatch = MyAddon:RegisterReducer("count", initialState, reducer)
	dispatch("INCREMENT")
	assert(MyAddon:GetState("count").count == 1)
end
