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

--[[
	Selection Group controls all have an interface to select a group for thier contents
	None of them will auto size to thier contents, and should usually be used with a scrollframe
	unless you know that the controls will fit inside
]]

--------------------------
-- Dropdown Group		--
--------------------------
--[[
	Events :
		OnGroupSelected

]]
do
	local Type = "DropdownGroup"
	local Version = 2
	
	local function Aquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.dropdown.list = nil
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
	end

	local PaneBackdrop  = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 5, bottom = 3 }
	}
	
	local function SetTitle(self,title)
		self.titletext:SetText(title)
	end
	

	local function SelectedGroup(self,event,value)
		local group = self.parentgroup
		local status = group.status or group.localstatus
		status.selectedgroup = value
		self.parentgroup:Fire("OnGroupSelected", value)
	end
	
	local function SetGroupList(self,list)
		self.dropdown.list = list
	end
	
	-- called to set an external table to store status in
	local function SetStatusTable(self, status)
		assert(type(status) == "table")
		self.status = status
	end
	
	local function SetGroup(self,group)
		self.dropdown:SetValue(group)
		local status = self.status or self.localstatus
		status.selectedgroup = group
		self:Fire("OnGroupSelected", group)
	end
	
	local function OnWidthSet(self, width)
		local content = self.content
		local contentwidth = width - 63
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
		local frame = CreateFrame("Frame")
		local self = {}
		self.type = Type

		self.Release = Release
		self.Aquire = Aquire
		self.SetTitle = SetTitle
		
		self.SetGroupList = SetGroupList
		self.SetGroup = SetGroup
		self.SetStatusTable = SetStatusTable
		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet
		
		self.localstatus = {}

		self.frame = frame
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
		
		local dropdown = AceGUI:Create("Dropdown")
		self.dropdown = dropdown
		dropdown:SetStrict(true)
		dropdown.frame:SetParent(frame)
		dropdown.parentgroup = self
		dropdown:SetCallback("OnValueChanged",SelectedGroup)
		
		dropdown.frame:SetPoint("TOPLEFT",titletext,"BOTTOMLEFT",-7,3)
		dropdown.frame:Show()
		dropdown:SetLabel("")
		
		local border = CreateFrame("Frame",nil,frame)
		self.border = border
		border:SetPoint("TOPLEFT",frame,"TOPLEFT",3,-40)
		border:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3)
		
		border:SetBackdrop(PaneBackdrop)
		border:SetBackdropColor(0.1,0.1,0.1,0.5)
		border:SetBackdropBorderColor(0.4,0.4,0.4)
		
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
