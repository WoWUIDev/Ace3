--[[ $Id$ ]]--

local AceGUI = LibStub("AceGUI-3.0")

-- Lua APIs
local assert, loadstring, tconcat, tgetn = assert, loadstring, table.concat, table.getn

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame = CreateFrame

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

local wowThirdLegion, wowClassicRebased, wowTBCRebased, wowWrathRebased
do
	local _, build, _, interface = GetBuildInfo()
	interface = interface or tonumber(build)
	wowThirdLegion = (interface >= 70300)
	wowClassicRebased = (interface >= 11300 and interface < 20000)
	wowTBCRebased = (interface >= 20500 and interface < 30000)
	wowWrathRebased = (interface >= 30400 and interface < 40000)
end

local function fixlevels(parent)
	local child
	local childList = {parent:GetChildren()}
	local level = parent:GetFrameLevel() + 1

	for i = 1, tgetn(childList) do
		child = childList[i]
		child:SetFrameLevel(level)
		fixlevels(child)
	end
end

local function fixstrata(strata, parent)
	local child
	local childList = {parent:GetChildren()}

	parent:SetFrameStrata(strata)
	for i = 1, tgetn(childList) do
		child = childList[i]
		fixstrata(strata, child)
	end
end

-- ItemBase is the base "class" for all dropdown items.
-- Each item has to use ItemBase.Create(widgetType) to
-- create an initial 'self' value.
-- ItemBase will add common functions and ui event handlers.
-- Be sure to keep basic usage when you override functions.

local ItemBase = {
	-- NOTE: The ItemBase version is added to each item's version number
	--       to ensure proper updates on ItemBase changes.
	--       Use at least 1000er steps.
	version = 2000,
	counter = 0,
}

function ItemBase.Frame_OnEnter(frame)
	frame = frame or this
	local self = frame.obj

	if self.useHighlight then
		self.highlight:Show()
	end
	self:Fire("OnEnter")

	if self.specialOnEnter then
		self.specialOnEnter(self)
	end
end

function ItemBase.Frame_OnLeave(frame)
	frame = frame or this
	local self = frame.obj

	self.highlight:Hide()
	self:Fire("OnLeave")

	if self.specialOnLeave then
		self.specialOnLeave(self)
	end
end

-- exported, AceGUI callback
function ItemBase.OnAcquire(self)
	self.frame:SetToplevel(true)
	self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
end

-- exported, AceGUI callback
function ItemBase.OnRelease(self)
	self:SetDisabled(false)
	self.pullout = nil
	self.frame:SetParent(nil)
	self.frame:ClearAllPoints()
	self.frame:Hide()
end

-- exported
-- NOTE: this is called by a Dropdown-Pullout.
--       Do not call this method directly
function ItemBase.SetPullout(self, pullout)
	self.pullout = pullout

	self.frame:SetParent(nil)
	self.frame:SetParent(pullout.itemFrame)
	self.parent = pullout.itemFrame
	fixlevels(pullout.itemFrame)
end

-- exported
function ItemBase.SetText(self, text)
	self.text:SetText(text or "")
end

-- exported
function ItemBase.GetText(self)
	return self.text:GetText()
end

-- exported
ItemBase.SetPoint = vararg(1, function(self, arg)
	self.frame:SetPoint(unpack(arg))
end)

-- exported
function ItemBase.Show(self)
	self.frame:Show()
end

-- exported
function ItemBase.Hide(self)
	self.frame:Hide()
end

-- exported
function ItemBase.SetDisabled(self, disabled)
	self.disabled = disabled
	if disabled then
		self.useHighlight = false
		self.text:SetTextColor(.5, .5, .5)
	else
		self.useHighlight = true
		self.text:SetTextColor(1, 1, 1)
	end
end

-- exported
-- NOTE: this is called by a Dropdown-Pullout.
--       Do not call this method directly
function ItemBase.SetOnLeave(self, func)
	self.specialOnLeave = func
end

-- exported
-- NOTE: this is called by a Dropdown-Pullout.
--       Do not call this method directly
function ItemBase.SetOnEnter(self, func)
	self.specialOnEnter = func
end

function ItemBase.Create(type)
	-- NOTE: Most of the following code is copied from AceGUI-3.0/Dropdown widget
	local count = AceGUI:GetNextWidgetNum(type)
	local frame = CreateFrame("Button", "AceGUI30DropDownItem"..count)
	local self = {}
	self.frame = frame
	frame.obj = self
	self.type = type

	self.useHighlight = true

	frame:SetHeight(17)
	frame:SetFrameStrata("FULLSCREEN_DIALOG")

	local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
	text:SetTextColor(1,1,1)
	text:SetJustifyH("LEFT")
	text:SetPoint("TOPLEFT",frame,"TOPLEFT",18,0)
	text:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-8,0)
	self.text = text

	local highlight = frame:CreateTexture(nil, "OVERLAY")
	highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	highlight:SetBlendMode("ADD")
	highlight:SetHeight(14)
	highlight:ClearAllPoints()
	highlight:SetPoint("RIGHT",frame,"RIGHT",-3,0)
	highlight:SetPoint("LEFT",frame,"LEFT",5,0)
	highlight:Hide()
	self.highlight = highlight

	local check = frame:CreateTexture(nil, "OVERLAY")
	check:SetWidth(16)
	check:SetHeight(16)
	check:SetPoint("LEFT",frame,"LEFT",3,-1)
	check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	check:Hide()
	self.check = check

	local sub = frame:CreateTexture(nil, "OVERLAY")
	sub:SetWidth(16)
	sub:SetHeight(16)
	sub:SetPoint("RIGHT",frame,"RIGHT",-3,-1)
	sub:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
	sub:Hide()
	self.sub = sub

	frame:SetScript("OnEnter", ItemBase.Frame_OnEnter)
	frame:SetScript("OnLeave", ItemBase.Frame_OnLeave)

	self.OnAcquire = ItemBase.OnAcquire
	self.OnRelease = ItemBase.OnRelease

	self.SetPullout = ItemBase.SetPullout
	self.GetText    = ItemBase.GetText
	self.SetText    = ItemBase.SetText
	self.SetDisabled = ItemBase.SetDisabled

	self.SetPoint   = ItemBase.SetPoint
	self.Show       = ItemBase.Show
	self.Hide       = ItemBase.Hide

	self.SetOnLeave = ItemBase.SetOnLeave
	self.SetOnEnter = ItemBase.SetOnEnter

	return self
end

-- Register a dummy LibStub library to retrieve the ItemBase, so other addons can use it.
local IBLib = LibStub:NewLibrary("AceGUI-3.0-DropDown-ItemBase", ItemBase.version)
if IBLib then
	IBLib.GetItemBase = function() return ItemBase end
end

--[[
	Template for items:

-- Item:
--
do
	local widgetType = "Dropdown-Item-"
	local widgetVersion = 1

	local function Constructor()
		local self = ItemBase.Create(widgetType)

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
end
--]]

-- Item: Header
-- A single text entry.
-- Special: Different text color and no highlight
do
	local widgetType = "Dropdown-Item-Header"
	local widgetVersion = 1

	local function OnEnter(frame)
		frame = frame or this
		local self = frame.obj
		self:Fire("OnEnter")

		if self.specialOnEnter then
			self.specialOnEnter(self)
		end
	end

	local function OnLeave(frame)
		frame = frame or this
		local self = frame.obj
		self:Fire("OnLeave")

		if self.specialOnLeave then
			self.specialOnLeave(self)
		end
	end

	-- exported, override
	local function SetDisabled(self, disabled)
		ItemBase.SetDisabled(self, disabled)
		if not disabled then
			self.text:SetTextColor(1, 1, 0)
		end
	end

	local function Constructor()
		local self = ItemBase.Create(widgetType)

		self.SetDisabled = SetDisabled

		self.frame:SetScript("OnEnter", OnEnter)
		self.frame:SetScript("OnLeave", OnLeave)

		self.text:SetTextColor(1, 1, 0)

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
end

-- Item: Execute
-- A simple button
do
	local widgetType = "Dropdown-Item-Execute"
	local widgetVersion = 1

	local function Frame_OnClick(frame, button)
		frame = frame or this
		--button = button or arg1
		local self = frame.obj
		if self.disabled then return end
		self:Fire("OnClick")
		if self.pullout then
			self.pullout:Close()
		end
	end

	local function Constructor()
		local self = ItemBase.Create(widgetType)

		self.frame:SetScript("OnClick", Frame_OnClick)

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
end

-- Item: Toggle
-- Some sort of checkbox for dropdown menus.
-- Does not close the pullout on click.
do
	local widgetType = "Dropdown-Item-Toggle"
	local widgetVersion = 4

	local function UpdateToggle(self)
		if self.value then
			self.check:Show()
		else
			self.check:Hide()
		end
	end

	local function OnRelease(self)
		ItemBase.OnRelease(self)
		self:SetValue(nil)
	end

	local function Frame_OnClick(frame, button)
		frame = frame or this
		--button = button or arg1
		local self = frame.obj
		if self.disabled then return end
		self.value = not self.value
		if self.value then
			PlaySound((wowThirdLegion or wowClassicRebased or wowTBCRebased or wowWrathRebased) and 856 or "igMainMenuOptionCheckBoxOn") -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
		else
			PlaySound((wowThirdLegion or wowClassicRebased or wowTBCRebased or wowWrathRebased) and 857 or "igMainMenuOptionCheckBoxOff") -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
		end
		UpdateToggle(self)
		self:Fire("OnValueChanged", self.value)
	end

	-- exported
	local function SetValue(self, value)
		self.value = value
		UpdateToggle(self)
	end

	-- exported
	local function GetValue(self)
		return self.value
	end

	local function Constructor()
		local self = ItemBase.Create(widgetType)

		self.frame:SetScript("OnClick", Frame_OnClick)

		self.SetValue = SetValue
		self.GetValue = GetValue
		self.OnRelease = OnRelease

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
end

-- Item: Menu
-- Shows a submenu on mouse over
-- Does not close the pullout on click
do
	local widgetType = "Dropdown-Item-Menu"
	local widgetVersion = 2

	local function OnEnter(frame)
		frame = frame or this
		local self = frame.obj
		self:Fire("OnEnter")

		if self.specialOnEnter then
			self.specialOnEnter(self)
		end

		self.highlight:Show()

		if not self.disabled and self.submenu then
			self.submenu:Open("TOPLEFT", self.frame, "TOPRIGHT", self.pullout:GetRightBorderWidth(), 0, self.frame:GetFrameLevel() + 100)
		end
	end

	local function OnHide(frame)
		frame = frame or this
		local self = frame.obj
		if self.submenu then
			self.submenu:Close()
		end
	end

	-- exported
	local function SetMenu(self, menu)
		assert(menu.type == "Dropdown-Pullout")
		self.submenu = menu
	end

	-- exported
	local function CloseMenu(self)
		self.submenu:Close()
	end

	local function Constructor()
		local self = ItemBase.Create(widgetType)

		self.sub:Show()

		self.frame:SetScript("OnEnter", OnEnter)
		self.frame:SetScript("OnHide", OnHide)

		self.SetMenu   = SetMenu
		self.CloseMenu = CloseMenu

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
end

-- Item: Separator
-- A single line to separate items
do
	local widgetType = "Dropdown-Item-Separator"
	local widgetVersion = 2

	-- exported, override
	local function SetDisabled(self, disabled)
		ItemBase.SetDisabled(self, disabled)
		self.useHighlight = false
	end

	local function Constructor()
		local self = ItemBase.Create(widgetType)

		self.SetDisabled = SetDisabled

		local line = self.frame:CreateTexture(nil, "OVERLAY")
		line:SetHeight(1)
		if line.SetColorTexture then
			line:SetColorTexture(.5, .5, .5)
		else
			line:SetTexture(.5, .5, .5)
		end
		line:SetPoint("LEFT", self.frame, "LEFT", 10, 0)
		line:SetPoint("RIGHT", self.frame, "RIGHT", -10, 0)

		self.text:Hide()

		self.useHighlight = false

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion + ItemBase.version)
end
