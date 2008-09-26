local AceGUI = LibStub("AceGUI-3.0")

---------------------
-- Common Elements --
---------------------

local FrameBackdrop = {
	bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
	tile = true, tileSize = 32, edgeSize = 32, 
	insets = { left = 8, right = 8, top = 8, bottom = 8 }
}

local PaneBackdrop  = {

	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 5, bottom = 3 }
}

local ControlBackdrop  = {
	bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

local function Control_OnEnter(this)
	this.obj:Fire("OnEnter")
end

local function Control_OnLeave(this)
	this.obj:Fire("OnLeave")
end

-------------
-- Widgets --
-------------
--[[
	Widgets must provide the following functions
		Aquire() - Called when the object is aquired, should set everything to a default hidden state
		Release() - Called when the object is Released, should remove any anchors and hide the Widget
		
	And the following members
		frame - the frame or derivitive object that will be treated as the widget for size and anchoring purposes
		type - the type of the object, same as the name given to :RegisterWidget()
		
	Widgets contain a table called userdata, this is a safe place to store data associated with the wigdet
	It will be cleared automatically when a widget is released
	Placing values directly into a widget object should be avoided
	
	If the Widget can act as a container for other Widgets the following
		content - frame or derivitive that children will be anchored to
		
	The Widget can supply the following Optional Members


]]

--------------------------
-- Check Box			--
--------------------------
--[[
	Events :
		OnValueChanged

]]
do
	local Type = "CheckBox"
	
	local function Aquire(self)
		self:SetValue(false)
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.check:Hide()
		self.highlight:Hide()
		self.down = nil
		self.checked = nil
		self:SetType()
		self:SetDisabled(false)
	end
	
  
	local function CheckBox_OnEnter(this)
		local self = this.obj
		if not self.disabled then
			self.highlight:Show()
		end
		self:Fire("OnEnter")
	end
	
	local function CheckBox_OnLeave(this)
		local self = this.obj
		if not self.down then
			self.highlight:Hide()
		end
		self:Fire("OnLeave")
	end
	
	local function CheckBox_OnMouseUp(this)
		local self = this.obj
		if not self.disabled then
			self:ToggleChecked()
			self:Fire("OnValueChanged",self.checked)
			self.text:SetPoint("LEFT",self.check,"RIGHT",0,0)
		end
		self.down = nil
	end
	
	local function CheckBox_OnMouseDown(this)
		local self = this.obj
		if not self.disabled then
			self.text:SetPoint("LEFT",self.check,"RIGHT",1,-1)
			self.down = true
		end
	end

	local function SetDisabled(self,disabled)
		self.disabled = disabled
		if disabled then
			self.text:SetTextColor(0.5,0.5,0.5)
			SetDesaturation(self.check, true)
		else
			self.text:SetTextColor(1,.82,0)
			SetDesaturation(self.check, false)
		end
	end
	
	local function SetValue(self,value)
		self.checked = value
		if value then
			self.check:Show()
		else
			self.check:Hide()
		end
	end
	
	local function GetValue(self)
		return self.checked
	end
	
	local function SetType(self, type)
		local checkbg = self.checkbg
		local check = self.check
		local highlight = self.highlight
	
		if type == "radio" then
			checkbg:SetTexture("Interface\\Buttons\\UI-RadioButton")
			checkbg:SetTexCoord(0,0.25,0,1)
			check:SetTexture("Interface\\Buttons\\UI-RadioButton")
			check:SetTexCoord(0.5,0.75,0,1)
			check:SetBlendMode("ADD")
			highlight:SetTexture("Interface\\Buttons\\UI-RadioButton")
			highlight:SetTexCoord(0.5,0.75,0,1)
		else
			checkbg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
			checkbg:SetTexCoord(0,1,0,1)
			check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
			check:SetTexCoord(0,1,0,1)
			check:SetBlendMode("BLEND")
			highlight:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
			highlight:SetTexCoord(0,1,0,1)
		end
	end
	
	local function ToggleChecked(self)
		self:SetValue(not self:GetValue())
	end
	
	local function SetLabel(self, label)
		self.text:SetText(label)
	end
	
	local function Constructor()
		local frame = CreateFrame("Button",nil,UIParent)
		local self = {}
		self.type = Type

		self.Release = Release
		self.Aquire = Aquire

		self.SetValue = SetValue
		self.GetValue = GetValue
		self.SetDisabled = SetDisabled
		self.SetType = SetType
		self.ToggleChecked = ToggleChecked
		self.SetLabel = SetLabel
		
		self.frame = frame
		frame.obj = self

	
		local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		self.text = text
	
		frame:SetScript("OnEnter",CheckBox_OnEnter)
		frame:SetScript("OnLeave",CheckBox_OnLeave)
		frame:SetScript("OnMouseUp",CheckBox_OnMouseUp)
		frame:SetScript("OnMouseDown",CheckBox_OnMouseDown)
		frame:EnableMouse()
		local checkbg = frame:CreateTexture(nil,"ARTWORK")
		self.checkbg = checkbg
		checkbg:SetWidth(24)
		checkbg:SetHeight(24)
		checkbg:SetPoint("LEFT",frame,"LEFT",0,0)
		checkbg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
		local check = frame:CreateTexture(nil,"OVERLAY")
		self.check = check
		check:SetWidth(24)
		check:SetHeight(24)
		check:SetPoint("LEFT",frame,"LEFT",0,0)
		check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
	
		local highlight = frame:CreateTexture(nil, "BACKGROUND")
		self.highlight = highlight
		highlight:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
		highlight:SetBlendMode("ADD")
		highlight:SetAllPoints(checkbg)
		highlight:Hide()
	
	
		text:SetJustifyH("LEFT")
		frame:SetHeight(24)
		frame:SetWidth(200)
		text:SetHeight(18)
		text:SetPoint("LEFT",check,"RIGHT",0,0)
		text:SetPoint("RIGHT",frame,"RIGHT",0,0)
		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end
