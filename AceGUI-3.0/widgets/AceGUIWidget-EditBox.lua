--[[-----------------------------------------------------------------------------
EditBox Widget
-------------------------------------------------------------------------------]]
local Type, Version = "EditBox", 28
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local tostring, pairs, tconcat, unpack = tostring, pairs, table.concat, unpack
local assert, type, error, loadstring = assert, type, error, loadstring
local gsub, sub = string.gsub, string.sub

local wowThirdLegion, wowLegacy, wowClassicRebased, wowTBCRebased, wowWrathRebased
do
	local _, build, _, interface = GetBuildInfo()
	interface = interface or tonumber(build)
	wowThirdLegion = (interface >= 70300)
	wowLegacy = (interface < 11300)
	wowClassicRebased = (interface >= 11300 and interface < 20000)
	wowTBCRebased = (interface >= 20500 and interface < 30000)
	wowWrathRebased = (interface >= 30400 and interface < 40000)
end

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

-- WoW APIs
local PlaySound = PlaySound
local GetCursorInfo, ClearCursor = GetCursorInfo, ClearCursor
local CreateFrame, UIParent = CreateFrame, UIParent
local _G = getfenv() or _G or {}

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
if not AceGUIEditBoxInsertLink then
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
				return _G.AceGUIEditBoxInsertLink(GetContainerItemLink(BANK_CONTAINER, this:GetID()))
			end
		end)

		hooksecurefunc("ContainerFrameItemButton_OnClick", function(button, ignoreModifiers)
			if button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
				return _G.AceGUIEditBoxInsertLink(GetContainerItemLink(this:GetParent():GetID(), this:GetID()))
			end
		end)

		hooksecurefunc("KeyRingItemButton_OnClick", function(button)
			if button == "LeftButton" and IsShiftKeyDown() and not this.isBag then
				return _G.AceGUIEditBoxInsertLink(GetContainerItemLink(KEYRING_CONTAINER, this:GetID()))
			end
		end)

		hooksecurefunc("LootFrameItem_OnClick", function(button)
			if button == "LeftButton" and IsShiftKeyDown() then
				return _G.AceGUIEditBoxInsertLink(GetLootSlotLink(this.slot))
			end
		end)

		hooksecurefunc("SetItemRef", function(link, text, button)
			if IsShiftKeyDown() then
				if sub(link, 1, 6) == "player" then
					local name = sub(link, 8)
					if name and name ~= "" then
						return _G.AceGUIEditBoxInsertLink(name)
					end
				else
					return _G.AceGUIEditBoxInsertLink(text)
				end
			end
		end)

		hooksecurefunc("MerchantItemButton_OnClick", function(button, ignoreModifiers)
			if MerchantFrame.selectedTab == 1 and button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
				return _G.AceGUIEditBoxInsertLink(GetMerchantItemLink(this:GetID()))
			end
		end)

		hooksecurefunc("PaperDollItemSlotButton_OnClick", function(button, ignoreModifiers)
			if button == "LeftButton" and IsShiftKeyDown() and not ignoreModifiers then
				return _G.AceGUIEditBoxInsertLink(GetInventoryItemLink("player", this:GetID()))
			end
		end)

		hooksecurefunc("QuestItem_OnClick", function()
			if IsShiftKeyDown() and this.rewardType ~= "spell" then
				return _G.AceGUIEditBoxInsertLink(GetQuestItemLink(this.type, this:GetID()))
			end
		end)

		hooksecurefunc("QuestRewardItem_OnClick", function()
			if IsShiftKeyDown() and this.rewardType ~= "spell" then
				return _G.AceGUIEditBoxInsertLink(GetQuestItemLink(this.type, this:GetID()))
			end
		end)

		hooksecurefunc("QuestLogTitleButton_OnClick", function(button)
			if IsShiftKeyDown() and (not this.isHeader) then
				return _G.AceGUIEditBoxInsertLink(gsub(this:GetText(), " *(.*)", "%1"))
			end
		end)

		hooksecurefunc("QuestLogRewardItem_OnClick", function()
			if IsShiftKeyDown() and this.rewardType ~= "spell" then
				return _G.AceGUIEditBoxInsertLink(GetQuestLogItemLink(this.type, this:GetID()))
			end
		end)

		hooksecurefunc("SpellButton_OnClick", function(drag)
			local id = SpellBook_GetSpellID(this:GetID())
			if id <= MAX_SPELLS and (not drag) and IsShiftKeyDown() then
				local spellName, subSpellName = GetSpellName(id, SpellBookFrame.bookType)
				if spellName and not IsSpellPassive(id, SpellBookFrame.bookType) then
					if subSpellName and subSpellName ~= "" then
						_G.AceGUIEditBoxInsertLink(spellName.."("..subSpellName..")")
					else
						_G.AceGUIEditBoxInsertLink(spellName)
					end
				end
			end
		end)
	else
		hooksecurefunc("ChatEdit_InsertLink", vararg(0, function(arg)
			return _G.AceGUIEditBoxInsertLink(unpack(arg))
		end))
	end
end

function _G.AceGUIEditBoxInsertLink(text)
	for i = 1, AceGUI:GetWidgetCount(Type) do
		local editbox = _G["AceGUI-3.0EditBox"..i]
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

local function ShowButton(self)
	if not self.disablebutton then
		self.button:Show()
		self.editbox:SetTextInsets(0, 20, 3, 3)
	end
end

local function HideButton(self)
	self.button:Hide()
	self.editbox:SetTextInsets(0, 0, 3, 3)
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

local function Frame_OnShowFocus(frame)
	frame = frame or this
	frame.obj.editbox:SetFocus()
	frame:SetScript("OnShow", nil)
end

local function EditBox_OnEscapePressed(frame)
	--frame = frame or this
	AceGUI:ClearFocus()
end

local function EditBox_OnEnterPressed(frame)
	frame = frame or this
	local self = frame.obj
	local value = frame:GetText()
	local cancel = self:Fire("OnEnterPressed", value)
	if not cancel then
		PlaySound((wowThirdLegion or wowClassicRebased or wowTBCRebased or wowWrathRebased) and 856 or "igMainMenuOptionCheckBoxOn") -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
		HideButton(self)
	end
end

local function EditBox_OnReceiveDrag(frame)
	if not GetCursorInfo then return end

	frame = frame or this
	local self = frame.obj
	local infoType, id, info = GetCursorInfo()
	local name
	if infoType == "item" then
		name = info
	elseif infoType == "spell" then
		if GetSpellInfo then
			name = GetSpellInfo(id, info)
		else
			local spellName, rank = GetSpellName(id, info)
			if rank ~= "" then
				spellName = spellName.."("..rank..")"
			end
			name = spellName
		end
	elseif infoType == "macro" then
		name = GetMacroInfo(id)
	end
	if name then
		self:SetText(name)
		self:Fire("OnEnterPressed", name)
		ClearCursor()
		HideButton(self)
		AceGUI:ClearFocus()
	end
end

local function EditBox_OnTextChanged(frame)
	frame = frame or this
	local self = frame.obj
	local value = frame:GetText()
	if tostring(value) ~= tostring(self.lasttext) then
		self:Fire("OnTextChanged", value)
		self.lasttext = value
		ShowButton(self)
	end
end

local function EditBox_OnFocusGained(frame)
	frame = frame or this
	AceGUI:SetFocus(frame.obj)
end

local function Button_OnClick(frame)
	frame = frame or this
	local editbox = frame.obj.editbox
	editbox:ClearFocus()
	EditBox_OnEnterPressed(editbox)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- height is controlled by SetLabel
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetLabel()
		self:SetText()
		self:DisableButton(false)
		self:SetMaxLetters(0)
	end,

	["OnRelease"] = function(self)
		self:ClearFocus()
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.editbox:EnableMouse(false)
			self.editbox:ClearFocus()
			self.editbox:SetTextColor(0.5,0.5,0.5)
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.editbox:EnableMouse(true)
			self.editbox:SetTextColor(1,1,1)
			self.label:SetTextColor(1,.82,0)
		end
	end,

	["SetText"] = function(self, text)
		self.lasttext = text or ""
		self.editbox:SetText(text or "")
		if self.editbox.SetCursorPosition then
			self.editbox:SetCursorPosition(0)
		else
			EditBoxSetCursorPosition(self.editbox, 0)
		end
		HideButton(self)
	end,

	["GetText"] = function(self, text)
		return self.editbox:GetText()
	end,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,-18)
			self:SetHeight(44)
			self.alignoffset = 30
		else
			self.label:SetText("")
			self.label:Hide()
			self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",7,0)
			self:SetHeight(26)
			self.alignoffset = 12
		end
	end,

	["DisableButton"] = function(self, disabled)
		self.disablebutton = disabled
		if disabled then
			HideButton(self)
		end
	end,

	["SetMaxLetters"] = function (self, num)
		self.editbox:SetMaxLetters(num or 0)
	end,

	["ClearFocus"] = function(self)
		self.editbox:ClearFocus()
		self.frame:SetScript("OnShow", nil)
	end,

	["SetFocus"] = function(self)
		self.editbox:SetFocus()
		if not self.frame:IsShown() then
			self.frame:SetScript("OnShow", Frame_OnShowFocus)
		end
	end,

	["HighlightText"] = function(self, from, to)
		self.editbox:HighlightText(from, to)
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local num  = AceGUI:GetNextWidgetNum(Type)
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local editbox = CreateFrame("EditBox", "AceGUI-3.0EditBox"..num, frame, "InputBoxTemplate")
	editbox:SetAutoFocus(false)
	editbox:SetFontObject(ChatFontNormal)
	editbox:SetScript("OnEnter", Control_OnEnter)
	editbox:SetScript("OnLeave", Control_OnLeave)
	editbox:SetScript("OnEscapePressed", EditBox_OnEscapePressed)
	editbox:SetScript("OnEnterPressed", EditBox_OnEnterPressed)
	editbox:SetScript("OnTextChanged", EditBox_OnTextChanged)
	editbox:SetScript("OnReceiveDrag", EditBox_OnReceiveDrag)
	editbox:SetScript("OnMouseDown", EditBox_OnReceiveDrag)
	editbox:SetScript("OnEditFocusGained", EditBox_OnFocusGained)
	editbox:SetScript("OnEditFocusLost", EditBox_OnFocusLost)
	editbox:SetTextInsets(0, 0, 3, 3)
	editbox:SetMaxLetters(256)
	editbox:SetPoint("BOTTOMLEFT", 6, 0)
	editbox:SetPoint("BOTTOMRIGHT", 0, 0)
	editbox:SetHeight(19)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", 0, -2)
	label:SetPoint("TOPRIGHT", 0, -2)
	label:SetJustifyH("LEFT")
	label:SetHeight(18)

	local button = CreateFrame("Button", nil, editbox, "UIPanelButtonTemplate")
	button:SetWidth(40)
	button:SetHeight(20)
	button:SetPoint("RIGHT", -2, 0)
	button:SetText(OKAY)
	button:SetScript("OnClick", Button_OnClick)
	button:Hide()

	local widget = {
		alignoffset = 30,
		editbox     = editbox,
		label       = label,
		button      = button,
		frame       = frame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	editbox.obj, button.obj = widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
