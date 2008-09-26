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
-- Keybinding  		    --
--------------------------
do
	local Type = "Keybinding"
	
	local function keybindingMsgFixWidth(this)
		this:SetWidth(this.msg:GetWidth()+10)
		this:SetScript("OnUpdate",nil)
	end

	local function Keybinding_OnClick(this, button)
		local self = this.obj
	
		if button == "LeftButton" or button == "RightButton" then
			if self.waitingForKey then
				this:EnableKeyboard(false)
				self.msgframe:Hide()
				this:UnlockHighlight()
				self.waitingForKey = nil
			else
				this:EnableKeyboard(true)
				self.msgframe:Show()
				this:LockHighlight()
				self.waitingForKey = true
			end
		end
	end
	
	
	local function Keybinding_OnKeyDown(this, key)
		local self = this.obj
		if self.waitingForKey then
			local keyPressed = key;
				if keyPressed == "ESCAPE" then
					keyPressed = ""
				else
					if ( keyPressed == "BUTTON1" or keyPressed == "BUTTON2" ) then
						return;
					end
					if ( keyPressed == "UNKNOWN" ) then
						return;
					end
					if ( keyPressed == "LSHIFT" or keyPressed == "LCTRL" or keyPressed == "LALT") then
						return;
					end
					if ( keyPressed == "RSHIFT" or keyPressed == "RCTRL" or keyPressed == "RALT") then
						return;
					end
					if ( IsShiftKeyDown() ) then
						keyPressed = "SHIFT-"..keyPressed;
					end
					if ( IsControlKeyDown() ) then
						keyPressed = "CTRL-"..keyPressed;
					end
					if ( IsAltKeyDown() ) then
						keyPressed = "ALT-"..keyPressed;
					end
				end
	
			if not self.disabled then
				self:Fire("OnKeyChanged",keyPressed)
			end
	
			this:EnableKeyboard(false)
			self.msgframe:Hide()
			this:UnlockHighlight()
			self.waitingForKey = nil
		end
	end
	
	local function Keybinding_OnMouseDown(this, button)
		if ( button == "LeftButton" or button == "RightButton" ) then
			return
		elseif ( button == "MiddleButton" ) then
			button = "BUTTON3";
		elseif ( button == "Button4" ) then
			button = "BUTTON4"
		elseif ( button == "Button5" ) then
			button = "BUTTON5"
		end
		Keybinding_OnKeyDown(this, button)
	end
	local function Aquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.waitingForKey = nil
		self.msgframe:Hide()
	end
	
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.button:Disable()
		else
			self.button:Enable()
		end
	end
	
	local function SetKey(self, key)
		self.button:SetText(key or "")
	end
	
	local function SetLabel(self, label)
		self.label:SetText(label or "")
	end

	local function Constructor()
	
		local frame = CreateFrame("Frame",nil,UIParent)
		
		local button = CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
		
		local self = {}
		self.type = Type

		--local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		local text = button:GetFontString()
		text:SetPoint("LEFT",button,"LEFT",7,0)
		text:SetPoint("RIGHT",button,"RIGHT",-7,0)
	
		button:SetScript("OnClick",Keybinding_OnClick)
		button:SetScript("OnKeyDown",Keybinding_OnKeyDown)
		button:SetScript("OnEnter",Control_OnEnter)
		button:SetScript("OnLeave",Control_OnLeave)
		button:SetScript("OnMouseDown",Keybinding_OnMouseDown)
		button:RegisterForClicks("AnyDown")
		button:EnableMouse()
	
		button:SetHeight(24)
		button:SetWidth(200)
		button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT",0,0)
		button:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		
		frame:SetWidth(200)
		frame:SetHeight(44)
		
		self.button = button
		
		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetJustifyH("CENTER")
		label:SetHeight(18)
		self.label = label
		
		local msgframe = CreateFrame("Frame",nil,UIParent)
		msgframe:SetHeight(30)
		msgframe:SetBackdrop(ControlBackdrop)
		msgframe:SetBackdropColor(0,0,0)
		msgframe:SetFrameStrata("DIALOG")
		msgframe:SetFrameLevel(1000)
		self.msgframe = msgframe
		local msg = msgframe:CreateFontString(nil,"OVERLAY","GameFontNormal")
		msg:SetText("Press a key to bind, ESC to clear the binding or click the button again to cancel")
		msgframe.msg = msg
		msg:SetPoint("TOPLEFT",msgframe,"TOPLEFT",5,-5)
		msgframe:SetScript("OnUpdate", keybindingMsgFixWidth)
		msgframe:SetPoint("BOTTOM",button,"TOP",0,0)
		msgframe:Hide()
	
		self.Release = Release
		self.Aquire = Aquire
		self.SetLabel = SetLabel
		self.SetDisabled = SetDisabled
		self.SetKey = SetKey
		
		self.frame = frame
		frame.obj = self
		button.obj = self

		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end
