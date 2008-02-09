local AceGUI = LibStub("AceGUI-3.0")

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
-- Tab Group            --
--------------------------
do
	local Type = "TabGroup"
	local Version = 3

	local PaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}
	
	local function Aquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
	end
	
	local function Tab_FixWidth(self)
		self:SetScript("OnUpdate",nil)
		self:SetWidth(self.text:GetWidth()+20)
	end
	
	local function Tab_SetText(self, text)
		self.text:SetText(text)
		self:SetScript("OnUpdate",Tab_FixWidth)
	end
	
	local function UpdateTabLook(self)
		if self.selected then
			self.left:SetAlpha(1)
			self.right:SetAlpha(1)
			self.middle:SetAlpha(1)
			self.text:SetTextColor(1,1,1)
			self:GetHighlightTexture():Hide()
		else
			self.left:SetAlpha(0.5)
			self.right:SetAlpha(0.5)
			self.middle:SetAlpha(0.5)
			self.text:SetTextColor(1,0.82,0)
			self:GetHighlightTexture():Show()
		end
		
		if self.disabled then
			self.text:SetTextColor(0.5,0.5,0.5)
			self:GetHighlightTexture():Hide()
		end
	end
	
	local function Tab_SetSelected(self, selected)
		self.selected = selected
		UpdateTabLook(self)
	end
	
	local function Tab_OnClick(self)
		if not (self.selected or self.disabled) then
			self.obj:SelectTab(self.value)
		end
	end
	
	local function Tab_SetDisabled(self, disabled)
		self.disabled = disabled
		UpdateTabLook(self)
	end
	
	local function CreateTab(self, id)
		local tab = CreateFrame("Button",nil,self.border)
		tab.obj = self
		tab.id = id
		tab:SetWidth(64)
		tab:SetHeight(32)
		
		tab:SetScript("OnClick",Tab_OnClick)
		
		tab:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight")
		tab:GetHighlightTexture():SetBlendMode("ADD")
		tab:GetHighlightTexture():SetPoint("TOPLEFT",tab,"TOPLEFT",2,-7)
		tab:GetHighlightTexture():SetPoint("BOTTOMRIGHT",tab,"BOTTOMRIGHT",-2,-3)
		local left = tab:CreateTexture(nil,"BACKGROUND")
		local middle = tab:CreateTexture(nil,"BACKGROUND")
		local right = tab:CreateTexture(nil,"BACKGROUND")
		local text = tab:CreateFontString(nil,"BACKGROUND","GameFontNormalSmall")
		
		tab.text = text
		tab.left = left
		tab.right = right
		tab.middle = middle
		tab.SetText = Tab_SetText
		tab.SetSelected = Tab_SetSelected
		tab.SetDisabled = Tab_SetDisabled
		
		text:SetPoint("LEFT",tab,"LEFT",5,-4)
		text:SetPoint("RIGHT",tab,"RIGHT",-5,-4)
		text:SetHeight(18)
		text:SetText("")
		
		left:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
		middle:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
		right:SetTexture("Interface\\ChatFrame\\ChatFrameTab")
		
		left:SetWidth(16)
		left:SetHeight(32)
		middle:SetWidth(44)
		middle:SetHeight(32)
		right:SetWidth(16)
		right:SetHeight(32)
		
		left:SetTexCoord(0,0.25,0,1)
		middle:SetTexCoord(0.25,0.75,0,1)
		right:SetTexCoord(0.75,1,0,1)
		
		left:SetPoint("TOPLEFT",tab,"TOPLEFT",0,0)
		right:SetPoint("TOPRIGHT",tab,"TOPRIGHT",0,0)
		
		middle:SetPoint("LEFT",left,"RIGHT",0,0)
		middle:SetPoint("RIGHT",right,"LEFT",0,0)
		
		return tab
	end
	
	local function SetTitle(self, text)
		self.titletext:SetText(text or "")
	end
	
	-- called to set an external table to store status in
	local function SetStatusTable(self, status)
		assert(type(status) == "table")
		self.status = status
	end
	
	local function SelectTab(self, value)
		local status = self.status or self.localstatus

		local found
		for i, v in ipairs(self.tabs) do
			if v.value == value then
				v:SetSelected(true)
				found = true
			else
				v:SetSelected(false)	
			end
		end
		status.selected = value
		if found then
			self:Fire("OnGroupSelected",value)
		end
	end
		
	local function SetTabs(self, tabs)
		self.tablist = tabs
		self:BuildTabs()
	end
	
	local function BuildTabs(self)
		local status = self.status or self.localstatus
		local tablist = self.tablist

		local tabs = self.tabs
		
		for i, v in ipairs(tabs) do
			v:Hide()
		end
		for i, v in ipairs(tablist) do
			local tab = tabs[i]
			if not tab then
				tab = self:CreateTab(i)
				tabs[i] = tab
				if i == 1 then
					tab:SetPoint("BOTTOMLEFT",self.border,"TOPLEFT",0,-3)
				else
					tab:SetPoint("LEFT",tabs[i-1],"RIGHT",-3,0)
				end					
			end
			tab:Show()
			tab:SetText(v.text)
			tab:SetDisabled(v.disabled)
			tab.value = v.value
		end
		if #tablist > 1 then
			self:SelectTab(status.selected or tablist[1].value)
		end
	end
	
	local function OnWidthSet(self, width)
		local content = self.content
		local contentwidth = width - 60
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
	end
	
	
	local function OnHeightSet(self, height)
		local content = self.content
		local contentheight = height - 26
		if contentheight < 0 then
			contentheight = 0
		end
		content:SetHeight(contentheight)
		content.height = contentheight
	end
	

	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type

		self.localstatus = {}
		
		self.Release = Release
		self.Aquire = Aquire
		self.SetTitle = SetTitle
		self.CreateTab = CreateTab
		self.SelectTab = SelectTab
		self.BuildTabs = BuildTabs
		self.SetStatusTable = SetStatusTable
		self.SetTabs = SetTabs
		self.frame = frame
		
		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet

		frame.obj = self
		
		frame:SetHeight(100)
		frame:SetWidth(100)
		frame:SetFrameStrata("FULLSCREEN_DIALOG")
		
		local titletext = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		titletext:SetPoint("TOPLEFT",frame,"TOPLEFT",14,0)
		titletext:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-14,0)
		titletext:SetJustifyH("LEFT")
		titletext:SetHeight(18)
		
		self.titletext = titletext	
		
		local border = CreateFrame("Frame",nil,frame)
		self.border = border
		border:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-37)
		border:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3)
		
		border:SetBackdrop(PaneBackdrop)
		border:SetBackdropColor(0.1,0.1,0.1,0.5)
		border:SetBackdropBorderColor(0.4,0.4,0.4)
		
		self.tabs = {}
		
		--Container Support
		local content = CreateFrame("Frame",nil,border)
		self.content = content
		content.obj = self
		content:SetPoint("TOPLEFT",border,"TOPLEFT",10,-10)
		content:SetPoint("BOTTOMRIGHT",border,"BOTTOMRIGHT",-10,10)
		
		AceGUI:RegisterAsContainer(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
