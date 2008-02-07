local AceGUI = LibStub("AceGUI-3.0")

--------------------------
-- Dropdown			 --
--------------------------
--[[
	Events :
		OnValueChanged

]]
do
	local Type = "Dropdown"
	local Version = 3
	
	local ControlBackdrop  = {
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	local function Aquire(self)
		self:SetStrict(true)
		self:SetLabel("")
	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self:SetLabel(nil)
		self.list = nil
		self:SetDisabled(false)
	end

	local function Control_OnEnter(this)
		this.obj:Fire("OnEnter")
	end
	
	local function Control_OnLeave(this)
		this.obj:Fire("OnLeave")
	end
	
	local function SetText(self, text)
		self.editbox:SetText(text or "")
		self.editbox:SetCursorPosition(0)
	end
	
	local function SetValue(self, value)
		if self.list then
			self.editbox:SetText(self.list[value] or "")
		end
		self.editbox.value = value
		self.editbox:SetCursorPosition(0)
	end
	
	local function SetList(self, list)
		self.list = list
	end
	
	local function AddItem(self, value, text)
		if self.list then
			self.list[value] = text
		end
	end
	
	local function Dropdown_OnEscapePressed(this)
		this:ClearFocus()
	end
	
	local function Dropdown_OnEnterPressed(this)
		local self = this.obj
		if not self.disabled then
			local ret
			if self.strict and this.value then
				ret = this.value
			else
				ret = this:GetText()
			end
			self:Fire("OnValueChanged",ret)
		end
	end
	
	local function Dropdown_TogglePullout(this)
		local self = this.obj
		if self.open then
			self.open = nil
			self.pullout:Hide()
		else
			self.open = true
			self:BuildPullout()
			if self.lines[1] and self.lines[1]:IsShown() then
				self.pullout:Show()
			end
		end
	end
	
	local function Dropdown_OnHide(this)
		this.obj.pullout:Hide()
	end
	
	local function Dropdown_LineClicked(this)
		local self = this.obj
		self.open = false
		self.pullout:Hide()
		self.editbox:SetText(this.text:GetText())
		self.editbox.value = this.value
		Dropdown_OnEnterPressed(self.editbox)
	end
	
	local function Dropdown_LineEnter(this)
		this.highlight:Show()
	end
	
	local function Dropdown_LineLeave(this)
		this.highlight:Hide()
	end	
	
	local function SetStrict(self, strict)
		self.strict = strict
		if strict then
			self.editbox:EnableMouse(false)
			self.editbox:ClearFocus()
			self.editbox:SetTextColor(1,1,1)
		else
			self.editbox:EnableMouse(true)
			self.editbox:SetTextColor(1,1,1)
		end
	end
	
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.editbox:EnableMouse(false)
			self.editbox:ClearFocus()
			self.editbox:SetTextColor(0.5,0.5,0.5)
			self.button:Disable()
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.button:Enable()
			self.label:SetTextColor(1,.82,0)
			if self.strict then
				self.editbox:EnableMouse(false)
				self.editbox:ClearFocus()
				self.editbox:SetTextColor(1,1,1)
			else
				self.editbox:EnableMouse(true)
				self.editbox:SetTextColor(1,1,1)
			end
		end
	end
	
	local function fixlevels(parent,...)
		local i = 1
		local child = select(i, ...)
		while child do
			child:SetFrameLevel(parent:GetFrameLevel()+1)
			fixlevels(child, child:GetChildren())
			i = i + 1
			child = select(i, ...)
		end
	end
	
	local ddsort = {}
	local function BuildPullout(self)
		local list = self.list
		local lines = self.lines
		local totalheight = 10
		self:ClearPullout()
		self.pullout:SetFrameLevel(self.frame:GetFrameLevel()+1000)
		if type(list) == "table" then
			for k, v in pairs(list) do
				tinsert(ddsort,k)
			end
			table.sort(ddsort)
			for i, value in pairs(ddsort) do
				local text = list[value]
				if not lines[i] then
					lines[i] = self:CreateLine()
					if i == 1 then
						lines[i]:SetPoint("TOP",self.pullout,"TOP",0,-5)
					else
						lines[i]:SetPoint("TOP",lines[i-1],"BOTTOM",0,0)
					end
				end
				lines[i].text:SetText(text)
				lines[i]:SetFrameLevel(self.frame:GetFrameLevel()+1001)
				lines[i].value = value
				if lines[i].value == self.editbox.value then
					lines[i].check:Show()
				else
					lines[i].check:Hide()
				end
				lines[i]:Show()
				totalheight = totalheight + 17
				i = i + 1
			end
			for k in pairs(ddsort) do
				ddsort[k] = nil
			end
		end
		self.pullout:SetHeight(totalheight)
		fixlevels(self.pullout,self.pullout:GetChildren())
	end

	local function ClearPullout(self)
		if self.lines then
			for i, line in ipairs(self.lines) do
				line.text:SetText("")
				line:Hide()
			end
		end
		self.pullout:SetHeight(10)
		self.pullout:SetWidth(200)
	end
	
	local function SetLabel(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",0,-18)
			self.frame:SetHeight(44)
		else
			self.label:SetText("")
			self.label:Hide()
			self.editbox:SetPoint("TOPLEFT",self.frame,"TOPLEFT",0,0)
			self.frame:SetHeight(26)
		end
	end

	local function CreateLine(self, row, column)
		local frame = CreateFrame("Button",nil,self.pullout)
		frame.text = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		frame.text:SetTextColor(1,1,1)
		frame.text:SetJustifyH("LEFT")
		frame:SetHeight(17)
		frame:SetPoint("LEFT",self.pullout,"LEFT",6,0)
		frame:SetPoint("RIGHT",self.pullout,"RIGHT",-6,0)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		frame.obj = self
	
		local highlight = frame:CreateTexture(nil, "OVERLAY")
		highlight:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
		highlight:SetBlendMode("ADD")
		highlight:SetAllPoints(frame)
		highlight:Hide()
		frame.highlight = highlight
	
		local check = frame:CreateTexture("OVERLAY")
		frame.check = check
		check:SetWidth(16)
		check:SetHeight(16)
		check:SetPoint("LEFT",frame,"LEFT",0,0)
		check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		frame.text:SetPoint("TOPLEFT",frame,"TOPLEFT",16,0)
		frame.text:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
	
		frame:SetScript("OnClick",Dropdown_LineClicked)
		frame:SetScript("OnEnter",Dropdown_LineEnter)
		frame:SetScript("OnLeave",Dropdown_LineLeave)
		return frame
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type

		self.Release = Release
		self.Aquire = Aquire

		self.CreateLine = CreateLine
		self.ClearPullout = ClearPullout
		self.BuildPullout = BuildPullout
		self.SetText = SetText
		self.SetValue = SetValue
		self.SetList = SetList
		self.AddItem = AddItem
		self.SetStrict = SetStrict
		self.SetLabel = SetLabel
		self.SetDisabled = SetDisabled
		
		self.frame = frame
		frame.obj = self
		
		self.alignoffset = 30
		
		local editbox = CreateFrame("EditBox",nil,frame)
		self.editbox = editbox
		editbox.obj = self
		editbox:SetFontObject(ChatFontNormal)
		editbox:SetScript("OnEscapePressed",Dropdown_OnEscapePressed)
		editbox:SetScript("OnEnterPressed",Dropdown_OnEnterPressed)
		frame:SetScript("OnEnter",Control_OnEnter)
		frame:SetScript("OnLeave",Control_OnLeave)
		editbox:SetScript("OnEnter",Control_OnEnter)
		editbox:SetScript("OnLeave",Control_OnLeave)
		editbox:SetTextInsets(5,5,3,3)
		editbox:SetMaxLetters(256)
		editbox:SetAutoFocus(false)
		
		editbox:SetBackdrop(ControlBackdrop)
		editbox:SetBackdropColor(0,0,0)
		editbox:SetBackdropBorderColor(0.4,0.4,0.4)
	
		editbox:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		editbox:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-20,0)
		local button = CreateFrame("Button",nil,frame)
		self.button = button
		button.obj = self
		button:SetWidth(24)
		button:SetHeight(24)
		button:SetScript("OnEnter",Control_OnEnter)
		button:SetScript("OnLeave",Control_OnLeave)
		button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
		button:GetNormalTexture():SetTexCoord(.09,.91,.09,.91)
		button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
		button:GetPushedTexture():SetTexCoord(.09,.91,.09,.91)
		button:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
		button:GetDisabledTexture():SetTexCoord(.09,.91,.09,.91)
		button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
		button:GetHighlightTexture():SetTexCoord(.09,.91,.09,.91)
		button:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",0,0)
		button:SetScript("OnClick",Dropdown_TogglePullout)
		frame:SetHeight(44)
		frame:SetWidth(200)
		frame:SetScript("OnHide",Dropdown_OnHide)
		local pullout = CreateFrame("Frame",nil,UIParent)
		self.pullout = pullout
		frame:EnableMouse()
		pullout:SetBackdrop(ControlBackdrop)
		pullout:SetBackdropColor(0,0,0)
		pullout:SetFrameStrata("FULLSCREEN_DIALOG")
		pullout:SetPoint("TOPLEFT",frame,"BOTTOMLEFT",0,0)
		pullout:SetPoint("TOPRIGHT",frame,"BOTTOMRIGHT",-24,0)
		pullout:SetClampedToScreen(true)
		pullout:Hide()
	
		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetJustifyH("CENTER")
		label:SetHeight(18)
		label:Hide()
		self.label = label
		
		self.lines = {}

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
