local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- Button		        --
--------------------------
do
	local Type = "Button"
	local Version = 7
	
	local function OnAcquire(self)
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
	end
	
	local function Button_OnClick(this)
		this.obj:Fire("OnClick")
		AceGUI:ClearFocus()
	end
	
	local function Button_OnEnter(this)
		this.obj:Fire("OnEnter")
	end
	
	local function Button_OnLeave(this)
		this.obj:Fire("OnLeave")
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
		local num  = AceGUI:GetNextWidgetNum(Type)
		local frame = CreateFrame("Button","AceGUI30Button"..num,UIParent,"UIPanelButtonTemplate2")
		local self = {}
		self.num = num
		self.type = Type
		self.frame = frame

		local text = frame:GetFontString()
		self.text = text
		text:SetPoint("LEFT",frame,"LEFT",15,0)
		text:SetPoint("RIGHT",frame,"RIGHT",-15,0)

		frame:SetScript("OnClick",Button_OnClick)
		frame:SetScript("OnEnter",Button_OnEnter)
		frame:SetScript("OnLeave",Button_OnLeave)

		self.SetText = SetText
		self.SetDisabled = SetDisabled
		
		frame:EnableMouse(true)

		frame:SetHeight(24)
		frame:SetWidth(200)
	
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		
		self.frame = frame
		frame.obj = self

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
