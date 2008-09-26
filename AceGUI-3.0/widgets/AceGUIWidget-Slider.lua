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
-- Slider  	            --
--------------------------
do
	local Type = "Slider"
	
	local function Aquire(self)
		self:SetDisabled(false)
		self:SetSliderValues(0,100,1)
		self:SetValue(0)
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetDisabled(false)
	end
	
	local function Slider_OnValueChanged(this)
		local self = this.obj
		if not this.setup then
			local newvalue
			newvalue = this:GetValue()
			if newvalue ~= self.value and not self.disabled then
				self.value = newvalue
				self:Fire("OnValueChanged", newvalue)
			end
			if self.value then
				--this.obj.valuetext:SetText(math.floor(self.value*10)/10)
				this.obj.editbox:SetText(math.floor(self.value*100)/100)
			end
		end
	end
	
	local function Slider_OnMouseUp(this)
		local self = this.obj
		self:Fire("OnMouseUp",this:GetValue())
	end
	
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.slider:EnableMouse(false)
			self.label:SetTextColor(.5,.5,.5)
			self.hightext:SetTextColor(.5,.5,.5)
			self.lowtext:SetTextColor(.5,.5,.5)
			--self.valuetext:SetTextColor(.5,.5,.5)
			self.editbox:SetTextColor(.5,.5,.5)
			self.editbox:EnableMouse(false)
			self.editbox:ClearFocus()
		else
			self.slider:EnableMouse(true)
			self.label:SetTextColor(1,.82,0)
			self.hightext:SetTextColor(1,1,1)
			self.lowtext:SetTextColor(1,1,1)
			--self.valuetext:SetTextColor(1,1,1)
			self.editbox:SetTextColor(1,1,1)
			self.editbox:EnableMouse(true)
		end
	end
	
	local function SetValue(self, value)
		self.slider.setup = true
		self.slider:SetValue(value)
		self.value = value
		self.editbox:SetText(math.floor(self.value*100)/100)
		self.slider.setup = nil
	end
	
	local function SetLabel(self, text)
		self.label:SetText(text)
	end
	
	local function SetSliderValues(self,min, max, step)
		local frame = self.slider
		frame.setup = true
		self.min = min
		self.max = max
		self.step = step
		frame:SetMinMaxValues(min or 0,max or 100)
		self.lowtext:SetText(min or 0)
		self.hightext:SetText(max or 100)
		frame:SetValueStep(step or 1)
		frame.setup = nil
	end
	
	local function EditBox_OnEscapePressed(this)
		this:ClearFocus()
	end
	
	local function EditBox_OnEnterPressed(this)
		local self = this.obj
		local value = this:GetText()
		value = tonumber(value)
		if value then
			self:Fire("OnMouseUp",value)
		end
	end
	
	local SliderBackdrop  = {
		bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
		edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
		tile = true, tileSize = 8, edgeSize = 8,
		insets = { left = 3, right = 3, top = 6, bottom = 6 }
	}
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type

		self.Release = Release
		self.Aquire = Aquire
		
		self.frame = frame
		frame.obj = self
		
		self.SetDisabled = SetDisabled
		self.SetValue = SetValue
		self.SetSliderValues = SetSliderValues
		self.SetLabel = SetLabel

		self.slider = CreateFrame("Slider",nil,frame)
		local slider = self.slider
		slider:SetScript("OnEnter",Control_OnEnter)
		slider:SetScript("OnLeave",Control_OnLeave)
		slider:SetScript("OnMouseUp", Slider_OnMouseUp)
		slider.obj = self
		slider:SetOrientation("HORIZONTAL")
		slider:SetHeight(15)
		slider:SetHitRectInsets(0,0,-10,0)
		slider:SetBackdrop(SliderBackdrop)
		
		

		
		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetJustifyH("CENTER")
		label:SetHeight(15)
		self.label = label
	
		self.lowtext = slider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		self.lowtext:SetPoint("TOPLEFT",slider,"BOTTOMLEFT",2,3)
	
		self.hightext = slider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		self.hightext:SetPoint("TOPRIGHT",slider,"BOTTOMRIGHT",-2,3)
	
	
		local editbox = CreateFrame("EditBox",nil,frame)
		editbox:SetAutoFocus(false)
		editbox:SetFontObject(GameFontHighlightSmall)
		editbox:SetPoint("TOP",slider,"BOTTOM",0,0)
		editbox:SetHeight(14)
		editbox:SetWidth(100)
		editbox:SetJustifyH("CENTER")
		editbox:EnableMouse(true)
		editbox:SetScript("OnEscapePressed",EditBox_OnEscapePressed)
		editbox:SetScript("OnEnterPressed",EditBox_OnEnterPressed)
		self.editbox = editbox
		editbox.obj = self
		
		--self.valuetext = slider:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
		--self.valuetext:SetPoint("TOP",slider,"BOTTOM",0,3)
	
		slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
	
		frame:SetWidth(200)
		frame:SetHeight(44)
		slider:SetPoint("TOP",label,"BOTTOM",0,0)
		slider:SetPoint("LEFT",frame,"LEFT",3,0)
		slider:SetPoint("RIGHT",frame,"RIGHT",-3,0)
	

		slider:SetValue(self.value or 0)
		slider:SetScript("OnValueChanged",Slider_OnValueChanged)
	
		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end
