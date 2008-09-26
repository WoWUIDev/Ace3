local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- Label 	 			--
--------------------------
do
	local Type = "Icon"
	local Version = 4
	
	local function OnAcquire(self)
		self:SetText("")
		self:SetImage(nil)
	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetText(self, text)
		self.label:SetText(text or "")
	end
	
	local function SetImage(self, path, ...)
		local image = self.image
		image:SetTexture(path)
		
		if image:GetTexture() then
			self.imageshown = true
			local n = select('#', ...)
			if n == 4 or n == 8 then
				image:SetTexCoord(...)
			end
		else
			self.imageshown = nil
		end
	end
	
	local function OnClick(this)
		this.obj:Fire("OnClick")
		AceGUI:ClearFocus()
	end
	
	local function OnEnter(this)
		this.obj.highlight:Show()
	end
	
	local function OnLeave(this)
		this.obj.highlight:Hide()
	end

	local function Constructor()
		local frame = CreateFrame("Button",nil,UIParent)
		local self = {}
		self.type = Type
		
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		self.SetText = SetText
		self.frame = frame
		self.SetImage = SetImage

		frame.obj = self
		
		frame:SetHeight(110)
		frame:SetWidth(110)
		frame:EnableMouse(true)
		frame:SetScript("OnClick", OnClick)
		frame:SetScript("OnLeave", OnLeave)
		frame:SetScript("OnEnter", OnEnter)
		local label = frame:CreateFontString(nil,"BACKGROUND","GameFontHighlight")
		label:SetPoint("BOTTOMLEFT",frame,"BOTTOMLEFT",0,10)
		label:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,10)
		label:SetJustifyH("CENTER")
		label:SetJustifyV("TOP")
		label:SetHeight(18)
		self.label = label
		
		local image = frame:CreateTexture(nil,"BACKGROUND")
		self.image = image
		image:SetWidth(64)
		image:SetHeight(64)
		image:SetPoint("TOP",frame,"TOP",0,-10)
		
		local highlight = frame:CreateTexture(nil,"OVERLAY")
		self.highlight = highlight
		highlight:SetAllPoints(image)
		highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
		highlight:SetTexCoord(0,1,0.23,0.77)
		highlight:SetBlendMode("ADD")
		highlight:Hide()
		
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

