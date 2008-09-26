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
-- Tab Group            --
--------------------------
do
	local Type = "TabGroup"
	
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
	
	local function Tab_SetSelected(self, selected)
		self.selected = selected
		if selected then
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
	end
	
	local function Tab_OnClick(self)
		if not self.selected then
			self.obj:SelectTab(self.id)
		end
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
		
		text:SetPoint("LEFT",tab,"LEFT",5,-7)
		text:SetPoint("RIGHT",tab,"RIGHT",-5,-7)
		text:SetHeight(18)
		text:SetText("Test")
		
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
	
	local function SelectTab(self, id)
		local status = self.status or self.localstatus
		for i, v in ipairs(self.tabs) do
			v:SetSelected(v.id == id)
		end
		status.selected = id
		self:Fire("OnGroupSelected",self.tablist[id])
	end
		
	local function SetTabs(self, tabs, text)
		self.tablist = tabs
		self.text = text
		self:BuildTabs()
	end
	
	local function BuildTabs(self)
		local status = self.status or self.localstatus
		local tablist = self.tablist
		local text = self.text
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
			tab:SetText(text[v])
		end
		
		self:SelectTab(status.selected or 1)
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
		frame.obj = self
		
		frame:SetHeight(100)
		frame:SetWidth(100)
		frame:SetFrameStrata("DIALOG")
		
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
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end
