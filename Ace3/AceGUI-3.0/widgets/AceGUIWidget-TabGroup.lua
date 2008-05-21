local AceGUI = LibStub("AceGUI-3.0")

-------------
-- Widgets --
-------------
--[[
	Widgets must provide the following functions
		Acquire() - Called when the object is aquired, should set everything to a default hidden state
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
	local Version = 11

	local PaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}
	
	local function OnAcquire(self)

	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
		self.tablist = nil
	end
	
	local function Tab_SetText(self, text)
		self:_SetText(text)
		PanelTemplates_TabResize(0, self)
	end
	
	local function UpdateTabLook(self)
		if self.disabled then
			PanelTemplates_SetDisabledTabState(self)
		elseif self.selected then
			PanelTemplates_SelectTab(self)
		else
			PanelTemplates_DeselectTab(self)
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
		local tabname = "AceGUITabGroup"..self.num.."Tab"..id
		local tab = CreateFrame("Button",tabname,self.border,"OptionsFrameTabButtonTemplate")
		tab.obj = self
		tab.id = id
		
		tab:SetScript("OnClick",Tab_OnClick)

		tab._SetText = tab.SetText
		tab.SetText = Tab_SetText
		tab.SetSelected = Tab_SetSelected
		tab.SetDisabled = Tab_SetDisabled
		
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
		if not tablist then return end
		local row = 1
		local tabcount = 0
		local rowstart = 0
		local usedwidth = 0
		local width = self.frame.width or self.frame:GetWidth() or 0
		
		for i, v in ipairs(tablist) do
			local tab = tabs[i]
			if not tab then
				tab = self:CreateTab(i)
				tabs[i] = tab
			end

			tab:Show()
			tab:SetText(v.text)
			tab:SetDisabled(v.disabled)
			tab.value = v.value
			
			local tabwidth = tab:GetWidth()
			
			tab:ClearAllPoints()
			if i == 1 then
				tab:SetPoint("TOPLEFT",self.frame,"TOPLEFT",0,-7-(row-1)*20 )
				usedwidth = tab:GetWidth() -10
				tabcount = tabcount + 1
				rowstart = i
			else
				local rowwidth = usedwidth
				usedwidth = usedwidth + tab:GetWidth() -10
				if usedwidth > width then
					
					local padding = (width - rowwidth - 10) / (tabcount)
					for n = rowstart, i-1 do
						PanelTemplates_TabResize(padding, tabs[n])
					end
					row = row + 1
					tabcount = 1
					rowstart = i
					usedwidth = tab:GetWidth()-10
					tab:SetPoint("TOPLEFT",self.frame,"TOPLEFT",0,-7-(row-1)*20 )
				else
					tab:SetPoint("LEFT",tabs[i-1],"RIGHT",-10,0)
					tabcount = tabcount + 1
				end				
			end			
		end
		local padding = (width - usedwidth - 10) / (tabcount)
		for n = rowstart, #tabs do
			PanelTemplates_TabResize(padding, tabs[n])
		end
		self.borderoffset = 10+((row)*20)
		self.border:SetPoint("TOPLEFT",self.frame,"TOPLEFT",3,-self.borderoffset)
	end
	
	local function OnWidthSet(self, width)
		local content = self.content
		local contentwidth = width - 60
		if contentwidth < 0 then
			contentwidth = 0
		end
		content:SetWidth(contentwidth)
		content.width = contentwidth
		BuildTabs(self)
	end
	
	
	local function OnHeightSet(self, height)
		local content = self.content
		local contentheight = height - (self.borderoffset + 23)
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
		
		self.num = AceGUI:GetNextWidgetNum(Type)

		self.localstatus = {}
		
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
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
		self.borderoffset = 27
		border:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-27)
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
