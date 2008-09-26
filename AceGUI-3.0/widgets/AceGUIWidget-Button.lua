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
-- Button		        --
--------------------------
do
	local Type = "Button"
	
	local function Aquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
	end
	
	local function Button_OnClick(this)
		local self = this.obj
		self:Fire("OnClick")
	end
	
	local function Button_OnEnter(this)
		local self = this.obj
		self:Fire("OnEnter")
	end
	
	local function Button_OnLeave(this)
		local self = this.obj
		self:Fire("OnLeave")
	end
	
	local function SetText(self, text)
		self.text:SetText(text or "")
	end
	
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end
	local function Constructor()
		local frame = CreateFrame("Button",nil,UIParent,"UIPanelButtonTemplate")
		local self = {}
		self.type = Type
		self.frame = frame

		--local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		local text = frame:GetFontString()
		self.text = text
		text:SetPoint("LEFT",frame,"LEFT",7,0)
		text:SetPoint("RIGHT",frame,"RIGHT",-7,0)

		frame:SetScript("OnClick",Button_OnClick)
		frame:SetScript("OnEnter",Button_OnEnter)
		frame:SetScript("OnLeave",Button_OnLeave)

		self.SetText = SetText
		self.SetDisabled = SetDisabled
		
		frame:EnableMouse()

		frame:SetHeight(24)
		frame:SetWidth(200)
	
		self.Release = Release
		self.Aquire = Aquire
		
		self.frame = frame
		frame.obj = self

		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end
