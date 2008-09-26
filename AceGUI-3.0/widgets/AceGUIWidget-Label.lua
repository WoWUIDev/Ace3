local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- Label 	 			--
--------------------------
do
	local Type = "Label"
	local Version = 1
	
	local function Aquire(self)
		self:SetText("")
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function SetText(self, text)
		self.label:SetText(text or "")
		self.frame:SetHeight(self.label:GetHeight())
	end
	
	local function OnWidthSet(self, width)
		local frame, label = self.frame, self.label
		label:SetWidth(width)
		frame.resizing = true
		self.frame:SetHeight(self.label:GetHeight())
		self.frame.height = self.label:GetHeight()
		frame.resizing = nil
	end
	
	local function OnFrameResize(this)
		if this.resizing then return end
		local self = this.obj
		OnWidthSet(self, this:GetWidth())
	end

	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type
		
		self.Release = Release
		self.Aquire = Aquire
		self.SetText = SetText
		self.frame = frame
		self.OnWidthSet = OnWidthSet
		frame.obj = self
		
		frame:SetHeight(18)
		frame:SetWidth(200)
		frame:SetScript("OnSizeChanged", OnFrameResize)
		local label = frame:CreateFontString(nil,"BACKGROUND","GameFontNormal")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetWidth(200)
		label:SetJustifyH("LEFT")
		label:SetJustifyV("TOP")
		self.label = label
		
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

