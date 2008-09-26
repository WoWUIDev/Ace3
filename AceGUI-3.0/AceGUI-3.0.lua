--[[ $Id$ ]]
local ACEGUI_MAJOR, ACEGUI_MINOR = "AceGUI-3.0", 0
local AceGUI, oldminor = LibStub:NewLibrary(ACEGUI_MAJOR, ACEGUI_MINOR)

if not AceGUI then return end -- No upgrade needed

local con = LibStub("AceConsole-3.0",true)

AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.LayoutRegistry = AceGUI.LayoutRegistry or {}

-- local upvalues
local WidgetRegistry = AceGUI.WidgetRegistry
local LayoutRegistry = AceGUI.LayoutRegistry

local pcall = pcall
local select = select
local pairs = pairs
local ipairs = ipairs
local type = type
local assert = assert
local tinsert = tinsert
local tremove = tremove
local CreateFrame = CreateFrame
local UIParent = UIParent

local function safecall(func, ...)
	local success, err = pcall(func, ...)
	if success then return err end
	if not err:find("%.lua:%d+:") then err = (debugstack():match("\n(.-: )in.-\n") or "") .. err end 
	geterrorhandler()(err)
end

-- Recycling functions
local new, del
do
	local objPools = {}
	--Returns a new instance, if none are available either returns a new table or calls the given contructor
	function new(type,constructor,...)
		if not type then
			type = "table"
		end
		if not objPools[type] then
			objPools[type] = {}
		end
		local newObj = tremove(objPools[type])
		if not newObj then
			if constructor then
				newObj = constructor(...)
			else
				newObj = {}
			end
		end
		return newObj
	end
	-- Releases an instance to the Pool
	function del(obj,type)
		if not type then
			type = "table"
		end
		if not objPools[type] then
			objPools[type] = {}
		end
		tinsert(objPools[type],obj)
	end
end

AceGUI.new, AceGUI.del = new, del


-------------------
-- API Functions --
-------------------

-- Gets a widget Object
function AceGUI:Create(type)
	local reg = WidgetRegistry
	if reg[type] then
		local widget = new(type,reg[type])
		widget:Aquire()
		if widget.ResumeLayout then
			widget:ResumeLayout()
		end
		return widget
	end
end

-- Releases a widget Object
function AceGUI:Release(widget)
	if widget.PauseLayout then
		widget:PauseLayout()
	end
	widget:Fire("OnRelease")
	if widget.ReleaseChildren then
		widget:ReleaseChildren()
	end
	for k in pairs(widget.userdata) do
		widget.userdata[k] = nil
	end
	for k in pairs(widget.events) do
		widget.events[k] = nil
	end
	widget:Release()
	--widget.frame:SetParent(nil)
	widget.frame:ClearAllPoints()
	widget.frame:Hide()
	widget.frame:SetParent(nil)
	del(widget,widget.type)
end


--------------------------
-- Widget Base Template --
--------------------------
do
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
	
	local WidgetBase = {
		SetParent = function(self, parent)
			local frame = self.frame
			frame:SetParent(nil)
			frame:SetParent(parent)
			fixlevels(frame,frame:GetChildren())
		end,
		
		SetCallback = function(self, name, func)
			if type(func) == "function" then
				self.events[name] = func
			end
		end,
		
		Fire = function(self, name, ...)
			if self.events[name] then
				safecall(self.events[name], self, name, ...)
			end
		end
		
	}
	
		
	local function LayoutOnUpdate(this)
		this:SetScript("OnUpdate",nil)
		this.obj:PerformLayout()
	end
	
	local WidgetContainerBase = {
		
		PauseLayout = function(self)
			self.LayoutPaused = true
		end,
		
		ResumeLayout = function(self)
			self.LayoutPaused = nil
		end,
		
		PerformLayout = function(self)
			if self.LayoutPaused then
				return
			end
			for k, v in ipairs(self.children) do
				if v.PerformLayout then
					v:PerformLayout()
				end
			end
			if self.LayoutFunc then
				self.LayoutFunc(self.content, self.children)
			end
		end,
		
		--call this function to layout, makes sure layed out objects get a frame to get sizes etc
		DoLayout = function(self)
			self:PerformLayout()
			self.frame:SetScript("OnUpdate", LayoutOnUpdate)
		end,
		
		AddChild = function(self, child)
			tinsert(self.children,child)
			child:SetParent(self.content)
			child.frame:Show()
			self:DoLayout()
		end,
		
		ReleaseChildren = function(self)
			local children = self.children
			for i in ipairs(children) do
				AceGUI:Release(children[i])
				children[i] = nil
			end
		end,
		
		SetLayout = function(self, Layout)
			self.LayoutFunc = AceGUI:GetLayout(Layout)
		end,
	}
	
	local function ContentResize(this)
		if this.lastwidth ~= this:GetWidth() then
			this.obj:DoLayout()
		end
	end


	setmetatable(WidgetContainerBase,{__index=WidgetBase})

	--One of these function should be called on each Widget Instance as part of its creation process
	function AceGUI:RegisterAsContainer(widget)
		widget.children = {}
		widget.userdata = {}
		widget.events = {}
		widget.base = WidgetContainerBase
		widget.content:SetScript("OnSizeChanged",ContentResize)
		setmetatable(widget,{__index=WidgetContainerBase})
		widget:SetLayout("List")
	end
	
	function AceGUI:RegisterAsWidget(widget)
		widget.userdata = {}
		widget.events = {}
		widget.base = WidgetBase
		setmetatable(widget,{__index=WidgetBase})
	end
end




------------------
-- Widget API   --
------------------
-- Registers a widget Constructor, this function returns a new instance of the Widget
function AceGUI:RegisterWidgetType(Name, Constructor)
	assert(type(Constructor) == "function")
	WidgetRegistry[Name] = Constructor
end
-- Registers a Layout Function
function AceGUI:RegisterLayout(Name, LayoutFunc)
	assert(type(Name) == "string" and type(LayoutFunc) == "function")
	LayoutRegistry[Name:upper()] = LayoutFunc
end

function AceGUI:GetLayout(Name)
	assert(type(Name) == "string")
	return LayoutRegistry[Name:upper()]
end

--[[ Widget Template

--------------------------
-- Widget Name		  --
--------------------------
do
	local Type = "Type"
	
	local function Aquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	

	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type

		self.Release = Release
		self.Aquire = Aquire
		
		self.frame = frame
		frame.obj = self

		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
end


]]

-------------
-- Layouts --
-------------

--[[
	A Layout is a func that takes 2 parameters
		content - the frame that widgets will be placed inside
		children - a table containing the widgets to layout

]]

-- Very simple Layout, Children are stacked on top of each other down the left side
AceGUI:RegisterLayout("List",
	 function(content, children)
	 
	 	local height = 0
		for i, child in ipairs(children) do
			
			
			local frame = child.frame
			frame:ClearAllPoints()
			frame:Show()
			if i == 1 then
				frame:SetPoint("TOPLEFT",content,"TOPLEFT",0,0)
			else
				frame:SetPoint("TOPLEFT",children[i-1].frame,"BOTTOMLEFT",0,0)
			end
			height = height + frame:GetHeight()
			
			if child.width == "fill" then
				frame:SetPoint("RIGHT",content,"RIGHT")
			end
			
		end
		
		if content.obj.LayoutFinished then
			content.obj:LayoutFinished(nil, height)
		end
	 end
	)
	
-- A single control fills the whole content area
AceGUI:RegisterLayout("Fill",
	 function(content, children)
		if children[1] then
			children[1].frame:SetAllPoints(content)
			children[1].frame:Show()
			
			if content.obj.LayoutFinished then
				content.obj:LayoutFinished(nil, children[1].frame:GetHeight())
			end
		end
	 end
	)
	
AceGUI:RegisterLayout("Flow",
	 function(content, children)
	 	--used height so far
	 	local height = 0
	 	--width used in the current row
	 	local usedwidth = 0
	 	--height of the current row
	 	local rowheight = 0
	 	local width = content:GetWidth() or 0
	 	--control at the start of the row
	 	local rowstart
	 	
		for i, child in ipairs(children) do
			
			local frame = child.frame
			frame:Show()
			frame:ClearAllPoints()
			if i == 1 then
				-- anchor the first control to the top left
				frame:SetPoint("TOPLEFT",content,"TOPLEFT",0,0)
				rowheight = frame:GetHeight() or 0
				height = height + rowheight
				rowstart = frame
				usedwidth = frame:GetWidth()
			else
				-- if there isn't available width for the control start a new row
				-- if a control is "fill" it will be on a row of its own full width
				if usedwidth == 0 or ((frame:GetWidth() or 0) + usedwidth > width) or child.width == "fill" then
					frame:SetPoint("TOPLEFT",rowstart,"TOPLEFT",0,-rowheight)
					rowstart = frame
					rowheight = frame:GetHeight() or 0
					height = height + rowheight
					usedwidth = frame:GetWidth()
				-- put the control on the current row, adding it to the width and checking if the height needs to be increased
				else
					frame:SetPoint("TOPLEFT",children[i-1].frame,"TOPRIGHT",0,0)
					rowheight = math.max(rowheight, frame:GetHeight() or 0)
					usedwidth = frame:GetWidth() + usedwidth
				end
			end

			if child.width == "fill" then
				frame:SetPoint("RIGHT",content,"RIGHT")
				usedwidth = 0
				rowstart = frame
			end
			if child.height == "fill" then
				frame:SetPoint("BOTTOM",content,"BOTTOM")
				break
			end
		end
		
		if content.obj.LayoutFinished then
			content.obj:LayoutFinished(nil, height)
		end
	 end
	)
