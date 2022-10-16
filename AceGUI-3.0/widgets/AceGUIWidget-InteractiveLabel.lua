--[[-----------------------------------------------------------------------------
InteractiveLabel Widget
-------------------------------------------------------------------------------]]
local Type, Version = "InteractiveLabel", 21
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, unpack, loadstring = pairs, assert, unpack, loadstring
local tgetn, tconcat = table.getn, table.concat

local supports_ellipsis = loadstring("return ...") ~= nil
local template_args = supports_ellipsis and "{...}" or "arg"

local function vararg(n, f)
	local t = {}
	local params = ""
	if n > 0 then
		for i = 1, n do t[ i ] = "_"..i end
		params = tconcat(t, ", ", 1, n)
		params = params .. ", "
	end
	local code = [[
        return function( f )
        return function( ]]..params..[[... )
            return f( ]]..params..template_args..[[ )
        end
        end
    ]]
	return assert(loadstring(code, "=(vararg)"))()(f)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function Control_OnEnter(frame)
	frame = frame or this
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame = frame or this
	frame.obj:Fire("OnLeave")
end

local function Label_OnClick(frame, button)
	frame = frame or this
	button = button or arg1
	frame.obj:Fire("OnClick", button)
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self:LabelOnAcquire()
		self:SetHighlight()
		self:SetHighlightTexCoord()
		self:SetDisabled(false)
	end,

	-- ["OnRelease"] = nil,

	["SetHighlight"] = vararg(1, function(self, arg)
		self.highlight:SetTexture(unpack(arg))
	end),

	["SetHighlightTexCoord"] = vararg(1, function(self, arg)
		local c = tgetn(arg)
		if c == 4 or c == 8 then
			self.highlight:SetTexCoord(unpack(arg))
		else
			self.highlight:SetTexCoord(0, 1, 0, 1)
		end
	end),

	["SetDisabled"] = function(self,disabled)
		self.disabled = disabled
		if disabled then
			self.frame:EnableMouse(false)
			self.label:SetTextColor(0.5, 0.5, 0.5)
		else
			self.frame:EnableMouse(true)
			self.label:SetTextColor(1, 1, 1)
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	-- create a Label type that we will hijack
	local label = AceGUI:Create("Label")

	local frame = label.frame
	frame:EnableMouse(true)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)
	frame:SetScript("OnMouseDown", Label_OnClick)

	local highlight = frame:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetTexture(nil)
	highlight:SetAllPoints()
	highlight:SetBlendMode("ADD")

	label.highlight = highlight
	label.type = Type
	label.LabelOnAcquire = label.OnAcquire
	for method, func in pairs(methods) do
		label[method] = func
	end

	return label
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

