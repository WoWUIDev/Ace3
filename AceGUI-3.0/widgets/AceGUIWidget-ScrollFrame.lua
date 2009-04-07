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
-- Scroll Frame		    --
--------------------------
do
	local Type = "ScrollFrame"
	local Version = 4
	
	local function OnAcquire(self)

	end
	
	local function OnRelease(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
		self.status = nil
		for k in pairs(self.localstatus) do
			self.localstatus[k] = nil
		end
	end
	
	local function SetScroll(self, value)
		
		local status = self.status or self.localstatus
		
		local frame, child = self.scrollframe, self.content
		local viewheight = frame:GetHeight()
		local height = child:GetHeight()
		local offset
		if viewheight > height then
			offset = 0
		else
			offset = floor((height - viewheight) / 1000.0 * value)
		end
		child:ClearAllPoints()
		child:SetPoint("TOPLEFT",frame,"TOPLEFT",0,offset)
		child:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,offset)
		status.offset = offset
		status.scrollvalue = value
	end
	
	local function MoveScroll(self, value)
		local status = self.status or self.localstatus
		local frame, child = self.scrollframe, self.content
		local height, viewheight = frame:GetHeight(), child:GetHeight()
		if height > viewheight then
			self.scrollbar:Hide()
		else
			self.scrollbar:Show()
			local diff = height - viewheight
			local delta = 1
			if value < 0 then
				delta = -1
			end
			self.scrollbar:SetValue(math.min(math.max(status.scrollvalue + delta*(1000/(diff/45)),0), 1000))
		end
	end
	
	
	local function FixScroll(self)
		local status = self.status or self.localstatus
		local frame, child = self.scrollframe, self.content
		local height, viewheight = frame:GetHeight(), child:GetHeight()
		local offset = status.offset
		if not offset then
			offset = 0
		end
		local curvalue = self.scrollbar:GetValue()
		if viewheight < height then
			self.scrollbar:Hide()
			self.scrollbar:SetValue(0)
			--self.scrollframe:SetPoint("BOTTOMRIGHT",self.frame,"BOTTOMRIGHT",0,0)
		else
			self.scrollbar:Show()
			--self.scrollframe:SetPoint("BOTTOMRIGHT",self.frame,"BOTTOMRIGHT",-16,0)
			local value = (offset / (viewheight - height) * 1000)
			if value > 1000 then value = 1000 end
			self.scrollbar:SetValue(value)
			self:SetScroll(value)
			if value < 1000 then
				child:ClearAllPoints()
				child:SetPoint("TOPLEFT",frame,"TOPLEFT",0,offset)
				child:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,offset)
				status.offset = offset
			end
		end
	end

	local function OnMouseWheel(this,value)
		this.obj:MoveScroll(value)
	end

	local function OnScrollValueChanged(this, value)
		this.obj:SetScroll(value)
	end
	
	local function FixScrollOnUpdate(this)
		this:SetScript("OnUpdate", nil)
		this.obj:FixScroll()
	end
	local function OnSizeChanged(this)
		--this:SetScript("OnUpdate", FixScrollOnUpdate)
		this.obj:FixScroll()
	end
	
	local function LayoutFinished(self,width,height)
		self.content:SetHeight(height or 0 + 20)
		self:FixScroll()
	end
	
	-- called to set an external table to store status in
	local function SetStatusTable(self, status)
		assert(type(status) == "table")
		self.status = status
		if not status.scrollvalue then
			status.scrollvalue = 0
		end
	end
	
	
	local createdcount = 0
	
	local function OnWidthSet(self, width)
		local content = self.content
		content.width = width
	end
	
	
	local function OnHeightSet(self, height)
		local content = self.content
		content.height = height
	end
	
	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type
	
		self.OnRelease = OnRelease
		self.OnAcquire = OnAcquire
		
		self.MoveScroll = MoveScroll
		self.FixScroll = FixScroll
		self.SetScroll = SetScroll
		self.LayoutFinished = LayoutFinished
		self.SetStatusTable = SetStatusTable
		self.OnWidthSet = OnWidthSet
		self.OnHeightSet = OnHeightSet
		
		self.localstatus = {} 	
		self.frame = frame
		frame.obj = self

		--Container Support
		local scrollframe = CreateFrame("ScrollFrame",nil,frame)
		local content = CreateFrame("Frame",nil,scrollframe)
		createdcount = createdcount + 1
		local scrollbar = CreateFrame("Slider",("AceConfigDialogScrollFrame%dScrollBar"):format(createdcount),scrollframe,"UIPanelScrollBarTemplate")
		local scrollbg = scrollbar:CreateTexture(nil,"BACKGROUND")
		scrollbg:SetAllPoints(scrollbar)
		scrollbg:SetTexture(0,0,0,0.4)
		self.scrollframe = scrollframe
		self.content = content
		self.scrollbar = scrollbar
		
		scrollbar.obj = self
		scrollframe.obj = self
		content.obj = self
		
		scrollframe:SetScrollChild(content)
		scrollframe:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		scrollframe:SetPoint("BOTTOMRIGHT",self.frame,"BOTTOMRIGHT",-20,0)
		scrollframe:EnableMouseWheel(true)
		scrollframe:SetScript("OnMouseWheel", OnMouseWheel)
		scrollframe:SetScript("OnSizeChanged", OnSizeChanged)
		
		
		content:SetPoint("TOPLEFT",scrollframe,"TOPLEFT",0,0)
		content:SetPoint("TOPRIGHT",scrollframe,"TOPRIGHT",0,0)
		content:SetHeight(400)
		
		scrollbar:SetPoint("TOPLEFT",scrollframe,"TOPRIGHT",4,-16)
		scrollbar:SetPoint("BOTTOMLEFT",scrollframe,"BOTTOMRIGHT",4,16)
		scrollbar:SetScript("OnValueChanged", OnScrollValueChanged)
		scrollbar:SetMinMaxValues(0,1000)
		scrollbar:SetValueStep(1)
		scrollbar:SetValue(0)
		scrollbar:SetWidth(16)
		
		self.localstatus.scrollvalue = 0
		

		self:FixScroll()
		AceGUI:RegisterAsContainer(self)
		--AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
end
