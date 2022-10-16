--[[-----------------------------------------------------------------------------
Button Widget
Graphical Button.
-------------------------------------------------------------------------------]]
local Type, Version = "Button", 24
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, loadstring, tconcat = pairs, assert, loadstring, table.concat

-- WoW APIs
local PlaySound, CreateFrame, UIParent = PlaySound, CreateFrame, UIParent

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

local wowMoP, wowThirdLegion, wowClassicRebased, wowTBCRebased, wowWrathRebased
do
	local _, build, _, interface = GetBuildInfo()
	interface = interface or tonumber(build)
	wowMoP = (interface >= 50000)
	wowThirdLegion = (interface >= 70300)
	wowClassicRebased = (interface >= 11300 and interface < 20000)
	wowTBCRebased = (interface >= 20500 and interface < 30000)
	wowWrathRebased = (interface >= 30400 and interface < 40000)
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local Button_OnClick = vararg(1, function(frame, arg)
	frame = frame or this
	AceGUI:ClearFocus()
	PlaySound((wowThirdLegion or wowClassicRebased or wowTBCRebased or wowWrathRebased) and 852 or "igMainMenuOption") -- SOUNDKIT.IG_MAINMENU_OPTION
	frame.obj:Fire("OnClick", unpack(arg))
end)

local function Control_OnEnter(frame)
	frame = frame or this
	frame.obj:Fire("OnEnter")
end

local function Control_OnLeave(frame)
	frame = frame or this
	frame.obj:Fire("OnLeave")
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetAutoWidth(false)
		self:SetText()
	end,

	-- ["OnRelease"] = nil,

	["SetText"] = function(self, text)
		self.text:SetText(text)
		if self.autoWidth then
			self:SetWidth(self.text:GetStringWidth() + 30)
		end
	end,

	["SetAutoWidth"] = function(self, autoWidth)
		self.autoWidth = autoWidth
		if self.autoWidth then
			self:SetWidth(self.text:GetStringWidth() + 30)
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local name = "AceGUI30Button" .. AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Button", name, UIParent, (wowMoP or wowClassicRebased or wowTBCRebased or wowWrathRebased) and "UIPanelButtonTemplate" or "UIPanelButtonTemplate2")
	frame:Hide()

	frame:EnableMouse(true)
	frame:SetScript("OnClick", Button_OnClick)
	frame:SetScript("OnEnter", Control_OnEnter)
	frame:SetScript("OnLeave", Control_OnLeave)

	local text = frame:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", 15, -1)
	text:SetPoint("BOTTOMRIGHT", -15, 1)
	text:SetJustifyV("MIDDLE")

	local widget = {
		text  = text,
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
