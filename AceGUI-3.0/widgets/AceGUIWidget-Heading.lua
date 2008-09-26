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
-- Heading 	 			--
--------------------------
do
	local Type = "Heading"
	
	local function Aquire(self)
		self:SetText("")
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetText(self, text)
		self.label:SetText(text or "")
		if (text or "") == "" then
			self.left:SetPoint("RIGHT",self.frame,"RIGHT",-3,0)
			self.right:Hide()
		else
			self.left:SetPoint("RIGHT",self.label,"LEFT",-5,0)
			self.right:Show()
		end
	end

	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type
		
		self.Release = Release
		self.Aquire = Aquire
		self.SetText = SetText
		self.frame = frame
		frame.obj = self
		
		frame:SetHeight(18)
		
		local label = frame:CreateFontString(nil,"BACKGROUND","GameFontNormal")
		label:SetPoint("TOP",frame,"TOP",0,0)
		label:SetPoint("BOTTOM",frame,"BOTTOM",0,0)
		label:SetJustifyH("CENTER")
		label:SetHeight(18)
		self.label = label
		
		local left = frame:CreateTexture(nil, "BACKGROUND")
		self.left = left
		left:SetHeight(8)
		left:SetPoint("LEFT",frame,"LEFT",3,0)
		left:SetPoint("RIGHT",label,"LEFT",-5,0)
		left:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		left:SetTexCoord(0.81, 0.94, 0.5, 1)

		local right = frame:CreateTexture(nil, "BACKGROUND")
		self.right = right
		right:SetHeight(8)
		right:SetPoint("RIGHT",frame,"RIGHT",-3,0)
		right:SetPoint("LEFT",label,"RIGHT",5,0)
		right:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
		right:SetTexCoord(0.81, 0.94, 0.5, 1)
		
		
		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end
