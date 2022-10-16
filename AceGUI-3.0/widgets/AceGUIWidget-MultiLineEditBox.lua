local Type, Version = "MultiLineEditBox", 32
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, loadstring, tconcat, format = pairs, assert, loadstring, table.concat, string.format
local unpack, type, error = unpack, type, error
local gsub, sub = string.gsub, string.sub

-- WoW APIs
local GetCursorInfo, ClearCursor = GetCursorInfo, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = getfenv() or _G or {}

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

local wowLegacy
do
	local _, build, _, interface = GetBuildInfo()
	interface = interface or tonumber(build)
	wowLegacy = (interface < 11300)
end

local hooksecurefunc = hooksecurefunc or function (table, functionName, hookfunc)
	if type(table) == "string" then
		table, functionName, hookfunc = _G, table, functionName
	end
	local orig = table[functionName]
	if type(orig) ~= "function" then
		error("The function "..functionName.." does not exist", 2)
	end
	table[functionName] = vararg(0, function(arg)
		local tmp = {orig(unpack(arg))}
		hookfunc(unpack(arg))
		return unpack(tmp)
	end)
end

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]

if not AceGUIMultiLineEditBoxInsertLink then
	-- upgradeable hooks
	if wowLegacy then
		local GetContainerItemLink = GetContainerItemLink
		local GetInventoryItemLink = GetInventoryItemLink
		local GetLootSlotLink = GetLootSlotLink
		local GetMerchantItemLink = GetMerchantItemLink
		local GetQuestItemLink = GetQuestItemLink
		local GetQuestLogItemLink = GetQuestLogItemLink
		local GetSpellName = GetSpellName
		local IsShiftKeyDown = IsShiftKeyDown
		local IsSpellPassive = IsSpellPassive
		local SpellBook_GetSpellID = SpellBook_GetSpellID

		local BANK_CONTAINER = BANK_CONTAINER
		local KEYRING_CONTAINER = KEYRING_CONTAINER
		local MAX_SPELLS = MAX_SPELLS

		hooksecurefunc("BankFrameItemButtonGeneric_OnClick", function(button)
			if button == "LeftButton" and IsShiftKeyDown() and not this.isBag then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetContainerItemLink(BANK_CONTAINER, this:GetID()))
			end
		end)

		hooksecurefunc("ContainerFrameItemButton_OnClick", function(button, ignoreModifiers)
			if button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetContainerItemLink(this:GetParent():GetID(), this:GetID()))
			end
		end)

		hooksecurefunc("KeyRingItemButton_OnClick", function(button)
			if button == "LeftButton" and IsShiftKeyDown() and not this.isBag then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetContainerItemLink(KEYRING_CONTAINER, this:GetID()))
			end
		end)

		hooksecurefunc("LootFrameItem_OnClick", function(button)
			if button == "LeftButton" and IsShiftKeyDown() then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetLootSlotLink(this.slot))
			end
		end)

		hooksecurefunc("SetItemRef", function(link, text, button)
			if IsShiftKeyDown() then
				if sub(link, 1, 6) == "player" then
					local name = sub(link,8)
					if name and name ~= "" then
						return _G.AceGUIMultiLineEditBoxInsertLink(name)
					end
				else
					return _G.AceGUIMultiLineEditBoxInsertLink(text)
				end
			end
		end)

		hooksecurefunc("MerchantItemButton_OnClick", function(button, ignoreModifiers)
			if MerchantFrame.selectedTab == 1 and button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetMerchantItemLink(this:GetID()))
			end
		end)

		hooksecurefunc("PaperDollItemSlotButton_OnClick", function(button, ignoreModifiers)
			if button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetInventoryItemLink("player", this:GetID()))
			end
		end)

		hooksecurefunc("QuestItem_OnClick", function()
			if IsShiftKeyDown() and this.rewardType ~= "spell" then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetQuestItemLink(this.type, this:GetID()))
			end
		end)

		hooksecurefunc("QuestRewardItem_OnClick", function()
			if IsShiftKeyDown() and this.rewardType ~= "spell" then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetQuestItemLink(this.type, this:GetID()))
			end
		end)

		hooksecurefunc("QuestLogTitleButton_OnClick", function(button)
			if IsShiftKeyDown() and (not this.isHeader) then
				return _G.AceGUIMultiLineEditBoxInsertLink(gsub(this:GetText(), " *(.*)", "%1"))
			end
		end)

		hooksecurefunc("QuestLogRewardItem_OnClick", function()
			if IsShiftKeyDown() and this.rewardType ~= "spell" then
				return _G.AceGUIMultiLineEditBoxInsertLink(GetQuestLogItemLink(this.type, this:GetID()))
			end
		end)

		hooksecurefunc("SpellButton_OnClick", function(drag)
			local id = SpellBook_GetSpellID(this:GetID())
			if id <= MAX_SPELLS and (not drag) and IsShiftKeyDown() then
				local spellName, subSpellName = GetSpellName(id, SpellBookFrame.bookType)
				if spellName and not IsSpellPassive(id, SpellBookFrame.bookType) then
					if subSpellName and subSpellName ~= "" then
						_G.AceGUIMultiLineEditBoxInsertLink(spellName.."("..subSpellName..")")
					else
						_G.AceGUIMultiLineEditBoxInsertLink(spellName)
					end
				end
			end
		end)
	else
		hooksecurefunc("ChatEdit_InsertLink", vararg(0, function(arg)
			return _G.AceGUIMultiLineEditBoxInsertLink(unpack(arg))
		end))
	end
end

function _G.AceGUIMultiLineEditBoxInsertLink(text)
	for i = 1, AceGUI:GetWidgetCount(Type) do
		local editbox = _G[format("MultiLineEditBox%uEdit", i)]
		local hasfocus
		if editbox.HasFocus then
			hasfocus = editbox:HasFocus()
		else
			hasfocus = editbox.hasfocus
		end
		if editbox and editbox:IsVisible() and hasfocus then
			editbox:Insert(text)
			return true
		end
	end
end


local function Layout(self)
	self:SetHeight(self.numlines * 14 + (self.disablebutton and 19 or 41) + self.labelHeight)

	if self.labelHeight == 0 then
		self.scrollBar:SetPoint("TOP", self.frame, "TOP", 0, -23)
	else
		self.scrollBar:SetPoint("TOP", self.label, "BOTTOM", 0, -19)
	end

	if self.disablebutton then
		self.scrollBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 21)
		self.scrollBG:SetPoint("BOTTOMLEFT", 0, 4)
	else
		self.scrollBar:SetPoint("BOTTOM", self.button, "TOP", 0, 18)
		self.scrollBG:SetPoint("BOTTOMLEFT", self.button, "TOPLEFT")
	end
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function OnClick(self)                                                     -- Button
	self = self or this
	self = self.obj
	self.editBox:ClearFocus()
	if not self:Fire("OnEnterPressed", self.editBox:GetText()) then
		self.button:Disable()
	end
end

local function OnCursorChanged(self, _, y, _, cursorHeight)                      -- EditBox
	self = self or this
	y = y or arg2
	cursorHeight = cursorHeight or arg4
	self, y = self.obj.scrollFrame, -y
	local offset = self:GetVerticalScroll()
	if y < offset then
		self:SetVerticalScroll(y)
	else
		y = y + cursorHeight - self:GetHeight()
		if y > offset then
			self:SetVerticalScroll(y)
		end
	end
end

local function OnEditFocusLost(self)                                             -- EditBox
	self = self or this
	self.hasfocus = false
	self:HighlightText(0, 0)
	self.obj:Fire("OnEditFocusLost")
end

local function OnEnter(self)                                                     -- EditBox / ScrollFrame
	self = self or this
	self = self.obj
	if not self.entered then
		self.entered = true
		self:Fire("OnEnter")
	end
end

local function OnLeave(self)                                                     -- EditBox / ScrollFrame
	self = self or this
	self = self.obj
	if self.entered then
		self.entered = nil
		self:Fire("OnLeave")
	end
end

local function OnMouseUp(self)                                                   -- ScrollFrame
	self = self or this
	self = self.obj.editBox
	self:SetFocus()
	if self.SetCursorPosition then
		self:SetCursorPosition(self:GetNumLetters())
	else
		EditBoxSetCursorPosition(self, self:GetNumLetters())
	end
end

local function OnReceiveDrag(self)                                               -- EditBox / ScrollFrame
	if not GetCursorInfo then return end

	self = self or this
	local infoType, id, info = GetCursorInfo()
	if infoType == "spell" then
		if GetSpellInfo then
			info = GetSpellInfo(id, info)
		else
			local spellName, rank = GetSpellName(id, info)
			if rank ~= "" then
				spellName = spellName.."("..rank..")"
			end
			info = spellName
		end
	elseif infoType ~= "item" then
		return
	end
	ClearCursor()
	self = self.obj
	local editBox = self.editBox
	local hasfocus
	if editBox.HasFocus then
		hasfocus = editBox:HasFocus()
	else
		hasfocus = editBox.hasfocus
	end
	if not hasfocus then
		editBox.hasfocus = true
		editBox:SetFocus()
		if editBox.SetCursorPosition then
			editBox:SetCursorPosition(editBox:GetNumLetters())
		else
			EditBoxSetCursorPosition(editBox, editBox:GetNumLetters())
		end
	end
	editBox:Insert(info)
	self.button:Enable()
end

local function OnSizeChanged(self, width, height)                                -- ScrollFrame
	self = self or this
	width = width or arg1
	--height = height or arg2
	if wowLegacy then
		self:UpdateScrollChildRect()
		self:SetVerticalScroll(self:GetHeight())
	end
	self.obj.editBox:SetWidth(width)
end

local function OnTextChanged(self)                                               -- EditBox
	self = self or this
	self = self.obj
	local value = self.editBox:GetText()
	if tostring(value) ~= tostring(self.lasttext) then
		self:Fire("OnTextChanged", value)
		self.lasttext = value
		self.button:Enable()
	end
end

local function OnTextSet(self)                                                   -- EditBox
	self = self or this
	self:HighlightText(0, 0)
	if self.SetCursorPosition then
		self:SetCursorPosition(self:GetNumLetters())
		self:SetCursorPosition(0)
	else
		EditBoxSetCursorPosition(self, self:GetNumLetters())
		EditBoxSetCursorPosition(self, 0)
	end
	self.obj.button:Disable()
end

local function OnVerticalScroll(self, offset)                                    -- ScrollFrame
	self = self or this
	offset = offset or arg1
	local editBox = self.obj.editBox
	editBox:SetHitRectInsets(0, 0, offset, editBox:GetHeight() - offset - self:GetHeight())

	if wowLegacy then
		self.obj.scrollFrame:SetScrollChild(editBox)
		editBox:SetPoint("TOPLEFT", 0, offset)
		editBox:SetPoint("TOPRIGHT", 0, offset)
	end
end

local function OnScrollRangeChanged(self, xrange, yrange)
	self = self or this
	--xrange = xrange or arg1
	yrange = yrange or arg2
	if yrange == 0 then
		self.obj.editBox:SetHitRectInsets(0, 0, 0, 0)
	else
		OnVerticalScroll(self, self:GetVerticalScroll())
	end
end

local function OnShowFocus(frame)
	frame = frame or this
	frame.obj.editBox:SetFocus()
	frame:SetScript("OnShow", nil)
end

local function OnEditFocusGained(frame)
	frame = frame or this
	frame.hasfocus = true
	AceGUI:SetFocus(frame.obj)
	frame.obj:Fire("OnEditFocusGained")
end

local function OnEscapePressed()
	AceGUI:ClearFocus()
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		self.editBox:SetText("")
		self:SetDisabled(false)
		self:SetWidth(200)
		self:DisableButton(false)
		self:SetNumLines()
		self.entered = nil
		self:SetMaxLetters(0)
	end,

	["OnRelease"] = function(self)
		self:ClearFocus()
	end,

	["SetDisabled"] = function(self, disabled)
		local editBox = self.editBox
		if disabled then
			editBox:ClearFocus()
			editBox:EnableMouse(false)
			editBox:SetTextColor(0.5, 0.5, 0.5)
			self.label:SetTextColor(0.5, 0.5, 0.5)
			self.scrollFrame:EnableMouse(false)
			self.button:Disable()
		else
			editBox:EnableMouse(true)
			editBox:SetTextColor(1, 1, 1)
			self.label:SetTextColor(1, 0.82, 0)
			self.scrollFrame:EnableMouse(true)
		end
	end,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			if self.labelHeight ~= 10 then
				self.labelHeight = 10
				self.label:Show()
			end
		elseif self.labelHeight ~= 0 then
			self.labelHeight = 0
			self.label:Hide()
		end
		Layout(self)
	end,

	["SetNumLines"] = function(self, value)
		if not value or value < 4 then
			value = 4
		end
		self.numlines = value
		Layout(self)
	end,

	["SetText"] = function(self, text)
		self.lasttext = text or ""
		self.editBox:SetText(text or "")
	end,

	["GetText"] = function(self)
		return self.editBox:GetText()
	end,

	["SetMaxLetters"] = function (self, num)
		self.editBox:SetMaxLetters(num or 0)
	end,

	["DisableButton"] = function(self, disabled)
		self.disablebutton = disabled
		if disabled then
			self.button:Hide()
		else
			self.button:Show()
		end
		Layout(self)
	end,

	["ClearFocus"] = function(self)
		self.editBox:ClearFocus()
		self.frame:SetScript("OnShow", nil)
	end,

	["SetFocus"] = function(self)
		self.editBox:SetFocus()
		if not self.frame:IsShown() then
			self.frame:SetScript("OnShow", OnShowFocus)
		end
	end,

	["HighlightText"] = function(self, from, to)
		self.editBox:HighlightText(from, to)
	end,

	["GetCursorPosition"] = function(self)
		if self.editbox.GetCursorPosition then
			return self.editBox:GetCursorPosition()
		else
			return EditBoxGetCursorPosition(self.editBox)
		end
	end,

	["SetCursorPosition"] = vararg(1, function(self, arg)
		if self.editbox.SetCursorPosition then
			return self.editbox:SetCursorPosition(unpack(arg))
		else
			return EditBoxSetCursorPosition(self.editBox, unpack(arg))
		end
	end),
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local widgetNum = AceGUI:GetNextWidgetNum(Type)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
	label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
	label:SetJustifyH("LEFT")
	label:SetText(ACCEPT)
	label:SetHeight(10)

	local button = CreateFrame("Button", format("%s%dButton", Type, widgetNum), frame, "UIPanelButtonTemplate")
	button:SetPoint("BOTTOMLEFT", 0, 4)
	button:SetHeight(22)
	button:SetWidth(label:GetStringWidth() + 24)
	button:SetText(ACCEPT)
	button:SetScript("OnClick", OnClick)
	button:Disable()

	local text = button:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
	text:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 1)
	text:SetJustifyV("MIDDLE")

	local scrollBG = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate" or nil)
	scrollBG:SetBackdrop(backdrop)
	scrollBG:SetBackdropColor(0, 0, 0)
	scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)

	local scrollFrame = CreateFrame("ScrollFrame", format("%s%dScrollFrame", Type, widgetNum), frame, "UIPanelScrollFrameTemplate")

	local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOP", label, "BOTTOM", 0, -19)
	scrollBar:SetPoint("BOTTOM", button, "TOP", 0, 18)
	scrollBar:SetPoint("RIGHT", frame, "RIGHT")

	scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)
	scrollBG:SetPoint("BOTTOMLEFT", button, "TOPLEFT")

	scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)
	scrollFrame:SetScript("OnEnter", OnEnter)
	scrollFrame:SetScript("OnLeave", OnLeave)
	scrollFrame:SetScript("OnMouseUp", OnMouseUp)
	scrollFrame:SetScript("OnReceiveDrag", OnReceiveDrag)
	scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
	if scrollFrame.HookScript then
		scrollFrame:HookScript("OnVerticalScroll", OnVerticalScroll)
		scrollFrame:HookScript("OnScrollRangeChanged", OnScrollRangeChanged)
	else
		HookScript(scrollFrame, "OnVerticalScroll", OnVerticalScroll)
		HookScript(scrollFrame, "OnScrollRangeChanged", OnScrollRangeChanged)
	end

	local editBox = CreateFrame("EditBox", format("%s%dEdit", Type, widgetNum), scrollFrame)
	editBox:SetAllPoints()
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetMultiLine(true)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	if editBox.SetCountInvisibleLetters then
		editBox:SetCountInvisibleLetters(false)
	end
	editBox:SetScript("OnCursorChanged", OnCursorChanged)
	editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
	editBox:SetScript("OnEnter", OnEnter)
	editBox:SetScript("OnEscapePressed", OnEscapePressed)
	editBox:SetScript("OnLeave", OnLeave)
	editBox:SetScript("OnMouseDown", OnReceiveDrag)
	editBox:SetScript("OnReceiveDrag", OnReceiveDrag)
	editBox:SetScript("OnTextChanged", OnTextChanged)
	editBox:SetScript("OnTextSet", OnTextSet)
	editBox:SetScript("OnEditFocusGained", OnEditFocusGained)


	scrollFrame:SetScrollChild(editBox)

	local widget = {
		button      = button,
		editBox     = editBox,
		frame       = frame,
		label       = label,
		labelHeight = 10,
		numlines    = 4,
		scrollBar   = scrollBar,
		scrollBG    = scrollBG,
		scrollFrame = scrollFrame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	button.obj, editBox.obj, scrollFrame.obj = widget, widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
