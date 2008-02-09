local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- Label 	 			--
--------------------------
do
	local Type = "Label"
	local Version = 2
	
	local function Aquire(self)
		self:SetText("")
		self:SetImage(nil)
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	
	local function UpdateImageAnchor(self)
		local width = self.frame.width or self.frame:GetWidth() or 0
		local image = self.image
		local label = self.label
		local frame = self.frame
		local height
		
		label:ClearAllPoints()
		image:ClearAllPoints()
		
		if self.imageshown then
			local imagewidth = image:GetWidth()
			if (width - imagewidth) < 200 then
				--image goes on top when less than 200 width for the text
				image:SetPoint("TOP",frame,"TOP",0,0)
				label:SetPoint("TOP",image,"BOTTOM",0,0)
				label:SetPoint("LEFT",frame,"LEFT",0,0)
				label:SetWidth(width)
				height = image:GetHeight() + label:GetHeight()
			else
				--image on the left
				image:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
				label:SetPoint("TOPLEFT",image,"TOPRIGHT",0,0)
				label:SetWidth(width - imagewidth)
				height = math.max(image:GetHeight(), label:GetHeight())
			end
		else
			--no image shown
			label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
			label:SetWidth(width)
			height = self.label:GetHeight()
		end
		
		frame.resizing = true
		self.frame:SetHeight(height)
		self.frame.height = height
		frame.resizing = nil
	end
	
	local function SetText(self, text)
		self.label:SetText(text or "")
		UpdateImageAnchor(self)
	end
	
	local function OnWidthSet(self, width)
		UpdateImageAnchor(self)
	end
	
	local function OnFrameResize(this)
		if this.resizing then return end
		local self = this.obj
		OnWidthSet(self, this:GetWidth())
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
		UpdateImageAnchor(self)
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
		self.SetImage = SetImage
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
		
		local image = frame:CreateTexture(nil,"BACKGROUND")
		self.image = image
		
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end

