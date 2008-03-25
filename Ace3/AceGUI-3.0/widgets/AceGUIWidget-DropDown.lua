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
	local Version = 10
	local ControlBackdrop  = {
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 32,
		tileSize = 32,
		tile = true,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	}

	local function Acquire(self)
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
		self.text:SetText(text or "")
	end
	
	local function SetValue(self, value)
		if self.list then
			self.text:SetText(self.list[value] or "")
		end
		self.text.value = value
	end
	
	local function SetList(self, list)
		self.list = list
	end
	
	local function AddItem(self, value, text)
		if self.list then
			self.list[value] = text
		end
	end
	
	local function Dropdown_OnEnterPressed(this)
		local self = this.obj
		if not self.disabled then
			local ret = this.value or this:GetText()
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
		self.text:SetText(this.text:GetText())
		self.text.value = this.value
		Dropdown_OnEnterPressed(self.text)
	end
	
	local function Dropdown_LineEnter(this)
		this.highlight:Show()
	end
	
	local function Dropdown_LineLeave(this)
		this.highlight:Hide()
	end	
	
	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.text:SetTextColor(0.5,0.5,0.5)
			self.button:Disable()
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.button:Enable()
			self.label:SetTextColor(1,.82,0)
			self.text:SetTextColor(1,1,1)
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
		local totalheight = 22
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
						lines[i]:SetPoint("TOP",self.pullout,"TOP",0,-10)
					else
						lines[i]:SetPoint("TOP",lines[i-1],"BOTTOM",0,1)
					end
				end
				lines[i].text:SetText(text)
				lines[i]:SetFrameLevel(self.frame:GetFrameLevel()+1001)
				lines[i].value = value
				if lines[i].value == self.text.value then
					lines[i].check:Show()
				else
					lines[i].check:Hide()
				end
				lines[i]:Show()
				totalheight = totalheight + 16
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
			self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,-18)
			self.frame:SetHeight(44)
		else
			self.label:SetText("")
			self.label:Hide()
			self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,0)
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
		highlight:SetHeight(14)
		highlight:ClearAllPoints()
		highlight:SetPoint("RIGHT",frame,"RIGHT",-3,0)
		highlight:SetPoint("LEFT",frame,"LEFT",5,0)
		highlight:Hide()
		frame.highlight = highlight
	
		local check = frame:CreateTexture("OVERLAY")
		frame.check = check
		check:SetWidth(16)
		check:SetHeight(16)
		check:SetPoint("LEFT",frame,"LEFT",3,-1)
		check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		frame.text:SetPoint("TOPLEFT",frame,"TOPLEFT",18,0)
		frame.text:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-8,0)
	
		frame:SetScript("OnClick",Dropdown_LineClicked)
		frame:SetScript("OnEnter",Dropdown_LineEnter)
		frame:SetScript("OnLeave",Dropdown_LineLeave)
		return frame
	end
	
	local count = 0
	local function Constructor()
		count = count + 1 
		local self = {}
		local frame = CreateFrame("Frame",nil,UIParent)
		local dropdown = CreateFrame("Frame","AceGUI30DropDown" .. count,frame, "UIDropDownMenuTemplate")
		self.dropdown = dropdown
		self.type = Type

		self.Release = Release
		self.Acquire = Acquire

		self.CreateLine = CreateLine
		self.ClearPullout = ClearPullout
		self.BuildPullout = BuildPullout
		self.SetText = SetText
		self.SetValue = SetValue
		self.SetList = SetList
		self.AddItem = AddItem
		self.SetLabel = SetLabel
		self.SetDisabled = SetDisabled
		
		self.frame = frame
		frame.obj = self
		
		self.alignoffset = 30
		
		frame:SetHeight(44)
		frame:SetWidth(200)
		frame:SetScript("OnHide",Dropdown_OnHide)
		
		dropdown:ClearAllPoints()
		dropdown:SetPoint("TOPLEFT",frame,"TOPLEFT",-15,0)
		dropdown:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",17,0)
		dropdown:SetScript("OnHide", nil)
		
		-- fix anchoring of the dropdown
		local left = _G[dropdown:GetName() .. "Left"]
		local middle = _G[dropdown:GetName() .. "Middle"]
		local right = _G[dropdown:GetName() .. "Right"]
		
		middle:ClearAllPoints()
		right:ClearAllPoints()
		
		middle:SetPoint("LEFT", left, "RIGHT", 0, 0)
		middle:SetPoint("RIGHT", right, "LEFT", 0, 0)
		right:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", 0, 17)

		local button = _G[dropdown:GetName() .. "Button"]
		self.button = button
		button.obj = self
		button:SetScript("OnEnter",Control_OnEnter)
		button:SetScript("OnLeave",Control_OnLeave)
		button:SetScript("OnClick",Dropdown_TogglePullout)
		
		local text = _G[dropdown:GetName() .. "Text"]
		self.text = text
		text.obj = self
		text:ClearAllPoints()
		text:SetPoint("RIGHT", right, "RIGHT" ,-43, 2)
		text:SetPoint("LEFT", left, "LEFT", 25, 2)
		
		local pullout = CreateFrame("Frame",nil,UIParent)
		self.pullout = pullout
		frame:EnableMouse()
		pullout:SetBackdrop(ControlBackdrop)
		pullout:SetBackdropColor(0,0,0)
		pullout:SetFrameStrata("FULLSCREEN_DIALOG")
		pullout:SetPoint("TOPLEFT",frame,"BOTTOMLEFT",0,0)
		pullout:SetPoint("TOPRIGHT",frame,"BOTTOMRIGHT",0,0)
		pullout:SetClampedToScreen(true)
		pullout:Hide()
	
		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetJustifyH("LEFT")
		label:SetHeight(18)
		label:Hide()
		self.label = label
		
		self.lines = {}

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
