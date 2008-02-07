local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- ColorPicker		  --
--------------------------
do
	local Type = "ColorPicker"
	local Version = 2
	
	local function Aquire(self)
	end
	
	local function SetLabel(self, text)
		self.text:SetText(text)
	end

	local function SetColor(self,r,g,b,a)
		self.r = r
		self.g = g
		self.b = b
		self.a = a or 1
		self.colorSwatch.texture:SetTexture(r,g,b)
	end

	local function Control_OnEnter(this)
		this.obj:Fire("OnEnter")
	end

	local function Control_OnLeave(this)
		this.obj:Fire("OnLeave")
	end

	local function ColorCallback(self,r,g,b,a,isAlpha)
		self:SetColor(r,g,b,a)
		if ColorPickerFrame:IsVisible() then
			--colorpicker is still open
			self:Fire("OnValueChanged",r,g,b,a)
		else
			--colorpicker is closed, color callback is first, ignore it,
			--alpha callback is the final call after it closes so confirm now
			if isAlpha then
				self:Fire("OnValueConfirmed",r,g,b,a)
			end
		end
	end
	
	local function ColorSwatch_OnClick(this)
		local self = this.obj
		if not self.disabled then
			ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
			
			ColorPickerFrame.func = function()
				local r,g,b = ColorPickerFrame:GetColorRGB()
				local a = 1 - OpacitySliderFrame:GetValue()
				ColorCallback(self,r,g,b,a)
			end
			
			ColorPickerFrame.hasOpacity = 1
			ColorPickerFrame.opacityFunc = function()
				local r,g,b = ColorPickerFrame:GetColorRGB()
				local a = 1 - OpacitySliderFrame:GetValue()
				ColorCallback(self,r,g,b,a,true)
			end
			local r, g, b, a = self.r, self.g, self.b, self.a
			ColorPickerFrame.opacity = 1 - (a or 0)
			ColorPickerFrame:SetColorRGB(r, g, b)
			
			ColorPickerFrame.cancelFunc = function()
				ColorCallback(self,r,g,b,a)
			end
			ShowUIPanel(ColorPickerFrame)
		end
	end

	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end

	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if self.disabled then
			self.text:SetTextColor(0.5,0.5,0.5)
		else
			self.text:SetTextColor(1,.82,0)
		end
	end

	local function Constructor()
		local frame = CreateFrame("Button",nil,UIParent)
		local self = {}
		self.type = Type

		self.Release = Release
		self.Aquire = Aquire
		
		self.SetLabel = SetLabel
		self.SetColor = SetColor
		self.SetDisabled = SetDisabled
		
		self.frame = frame
		frame.obj = self
		
		local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		self.text = text
		text:SetJustifyH("LEFT")
		text:SetTextColor(1,.82,0)
		frame:SetHeight(24)
		frame:SetWidth(200)
		text:SetHeight(24)
		frame:SetScript("OnClick", ColorSwatch_OnClick)
		frame:SetScript("OnEnter",Control_OnEnter)
		frame:SetScript("OnLeave",Control_OnLeave)
	
		local colorSwatch = frame:CreateTexture(nil, "OVERLAY")
		self.colorSwatch = colorSwatch
		colorSwatch:SetWidth(24)
		colorSwatch:SetHeight(24)
		colorSwatch:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
		local texture = frame:CreateTexture(nil, "OVERLAY")
		colorSwatch.texture = texture
		texture:SetTexture(1, 1, 1)
		texture:SetWidth(13.8)
		texture:SetHeight(13.8)
		texture:Show()
	
		local highlight = frame:CreateTexture(nil, "BACKGROUND")
		self.highlight = highlight
		highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		highlight:SetBlendMode("ADD")
		highlight:SetAllPoints(frame)
		highlight:Hide()
	
		texture:SetPoint("CENTER", colorSwatch, "CENTER")
		colorSwatch:SetPoint("LEFT", frame, "LEFT", 0, 0)
		text:SetPoint("LEFT",colorSwatch,"RIGHT",2,0)
		text:SetPoint("RIGHT",frame,"RIGHT")

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
