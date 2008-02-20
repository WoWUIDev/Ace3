local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- Button		        --
--------------------------
do
	local Type = "Button"
	local Version = 2
	
	local function Aquire(self)
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
	end
	
	local function Button_OnClick(this)
		this.obj:Fire("OnClick")
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
	
	local count = 0
	local function Constructor()
		count = count + 1
		local frame = CreateFrame("Button","AceGUI-3.0 Button"..count,UIParent,"UIPanelButtonTemplate2")
		local self = {}
		self.type = Type
		self.frame = frame

		local text = frame:GetFontString()
		self.text = text
		text:SetPoint("LEFT",frame,"LEFT",15,-1)
		text:SetPoint("RIGHT",frame,"RIGHT",-15,-1)

		frame:SetScript("OnClick",Button_OnClick)
		frame:SetScript("OnEnter",Button_OnEnter)
		frame:SetScript("OnLeave",Button_OnLeave)

		self.SetText = SetText
		self.SetDisabled = SetDisabled
		
		frame:EnableMouse(true)

		frame:SetHeight(24)
		frame:SetWidth(200)
	
		self.Release = Release
		self.Aquire = Aquire
		
		self.frame = frame
		frame.obj = self

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
