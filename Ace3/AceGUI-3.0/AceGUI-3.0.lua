--[[ $Id$ ]]
local ACEGUI_MAJOR, ACEGUI_MINOR = "AceGUI-3.0", 5
local AceGUI, oldminor = LibStub:NewLibrary(ACEGUI_MAJOR, ACEGUI_MINOR)

if not AceGUI then return end -- No upgrade needed

local con = LibStub("AceConsole-3.0",true)

AceGUI.WidgetRegistry = AceGUI.WidgetRegistry or {}
AceGUI.LayoutRegistry = AceGUI.LayoutRegistry or {}
AceGUI.WidgetBase = AceGUI.WidgetBase or {}
AceGUI.WidgetContainerBase = AceGUI.WidgetContainerBase or {}
AceGUI.WidgetVersions = AceGUI.WidgetVersions or {}
 
-- local upvalues
local WidgetRegistry = AceGUI.WidgetRegistry
local LayoutRegistry = AceGUI.LayoutRegistry
local WidgetVersions = AceGUI.WidgetVersions

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

--[[
	 xpcall safecall implementation
]]
local xpcall = xpcall

local function errorhandler(err)
	return geterrorhandler()(err)
end

local function CreateDispatcher(argCount)
	local code = [[
		local xpcall, eh = ...
		local method, ARGS
		local function call() return method(ARGS) end
	
		local function dispatch(func, ...)
			method = func
			if not method then return end
			ARGS = ...
			return xpcall(call, eh)
		end
	
		return dispatch
	]]
	
	local ARGS = {}
	for i = 1, argCount do ARGS[i] = "arg"..i end
	code = code:gsub("ARGS", table.concat(ARGS, ", "))
	return assert(loadstring(code, "safecall Dispatcher["..argCount.."]"))(xpcall, errorhandler)
end

local Dispatchers = setmetatable({}, {__index=function(self, argCount)
	local dispatcher = CreateDispatcher(argCount)
	rawset(self, argCount, dispatcher)
	return dispatcher
end})
Dispatchers[0] = function(func)
	return xpcall(func, errorhandler)
end
 
local function safecall(func, ...)
	return Dispatchers[select('#', ...)](func, ...)
end

-- Recycling functions
local new, del
do
	AceGUI.objPools = AceGUI.objPools or {}
	local objPools = AceGUI.objPools
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
			newObj = constructor and constructor(...) or {}
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


-------------------
-- API Functions --
-------------------

-- Gets a widget Object

local warned = {}
function AceGUI:Create(type)
	local reg = WidgetRegistry
	if reg[type] then
		local widget = new(type,reg[type])
		if widget.Acquire then
			widget:Acquire()
		elseif widget.Aquire then
			if not warned[type] then
				DEFAULT_CHAT_FRAME:AddMessage(("AceGUI: Warning, Widget type %s uses the deprecated Aquire, this should be updated to Acquire"):format(type))
				warned[type] = true
			end
			widget.Acquire = widget.Aquire
			widget:Acquire()
		else
			error(("Widget type %s doesn't supply an Acquire Function"):format(type))
		end		
		safecall(widget.ResumeLayout, widget)
		return widget
	end
end

-- Releases a widget Object
function AceGUI:Release(widget)
	safecall( widget.PauseLayout, widget )
	widget:Fire("OnRelease")
	safecall( widget.ReleaseChildren, widget )
	for k in pairs(widget.userdata) do
		widget.userdata[k] = nil
	end
	for k in pairs(widget.events) do
		widget.events[k] = nil
	end
	widget.width = nil
	widget:Release()
	--widget.frame:SetParent(nil)
	widget.frame:ClearAllPoints()
	widget.frame:Hide()
	widget.frame:SetParent(nil)
	if widget.content then
		widget.content.width = nil
		widget.content.height = nil
	end
	del(widget,widget.type)
end


-------------
-- Widgets --
-------------
--[[
	Widgets must provide the following functions
		Acquire() - Called when the object is acquired, should set everything to a default hidden state
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
	
	local WidgetBase = AceGUI.WidgetBase 
	
	WidgetBase.SetParent = function(self, parent)
		local frame = self.frame
		frame:SetParent(nil)
		frame:SetParent(parent.content)
		self.parent = parent
		fixlevels(frame,frame:GetChildren())
	end
	
	WidgetBase.SetCallback = function(self, name, func)
		if type(func) == "function" then
			self.events[name] = func
		end
	end
	
	WidgetBase.Fire = function(self, name, ...)
		if self.events[name] then
			local success, ret = safecall(self.events[name], self, name, ...)
			if success then
				return ret
			end
		end
	end
	
	WidgetBase.SetWidth = function(self, width)
		self.frame:SetWidth(width)
		self.frame.width = width
		if self.OnWidthSet then
			self:OnWidthSet(width)
		end
	end
	
	WidgetBase.SetHeight = function(self, height)
		self.frame:SetHeight(height)
		self.frame.height = height
		if self.OnHeightSet then
			self:OnHeightSet(height)
		end
	end
		
--	local function LayoutOnUpdate(this)
--		this:SetScript("OnUpdate",nil)
--		this.obj:PerformLayout()
--	end
	
	local WidgetContainerBase = AceGUI.WidgetContainerBase
		
	WidgetContainerBase.PauseLayout = function(self)
		self.LayoutPaused = true
	end
	
	WidgetContainerBase.ResumeLayout = function(self)
		self.LayoutPaused = nil
	end
	
	WidgetContainerBase.PerformLayout = function(self)
		if self.LayoutPaused then
			return
		end
		safecall(self.LayoutFunc,self.content, self.children)
	end
	
	--call this function to layout, makes sure layed out objects get a frame to get sizes etc
	WidgetContainerBase.DoLayout = function(self)
		self:PerformLayout()
--		if not self.parent then
--			self.frame:SetScript("OnUpdate", LayoutOnUpdate)
--		end
	end
	
	WidgetContainerBase.AddChild = function(self, child)
		tinsert(self.children,child)
		child:SetParent(self)
		child.frame:Show()
		self:DoLayout()
	end
	
	WidgetContainerBase.ReleaseChildren = function(self)
		local children = self.children
		for i in ipairs(children) do
			AceGUI:Release(children[i])
			children[i] = nil
		end
	end
	
	WidgetContainerBase.SetLayout = function(self, Layout)
		self.LayoutFunc = AceGUI:GetLayout(Layout)
	end

	
	local function ContentResize(this)
		if this.lastwidth ~= this:GetWidth() then
			this.width = this:GetWidth()
			this.height = this:GetHeight()
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
function AceGUI:RegisterWidgetType(Name, Constructor, Version)
	assert(type(Constructor) == "function")
	assert(type(Version) == "number") 
	
	local oldVersion = WidgetVersions[Name]
	if oldVersion and oldVersion >= Version then return end
	
	WidgetVersions[Name] = Version
	WidgetRegistry[Name] = Constructor
end

-- Registers a Layout Function
function AceGUI:RegisterLayout(Name, LayoutFunc)
	assert(type(LayoutFunc) == "function")
	if type(Name) == "string" then
		Name = Name:upper()
	end
	LayoutRegistry[Name] = LayoutFunc
end

function AceGUI:GetLayout(Name)
	if type(Name) == "string" then
		Name = Name:upper()
	end
	return LayoutRegistry[Name]
end

--[[ Widget Template

--------------------------
-- Widget Name		  --
--------------------------
do
	local Type = "Type"
	
	local function Acquire(self)

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
		self.Acquire = Acquire
		
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
			
			if child.width == "fill" then
				frame:SetPoint("RIGHT",content,"RIGHT")
				if child.DoLayout then
					child:DoLayout()
				end
			end
			
			height = height + (frame.height or frame:GetHeight() or 0)
		end
		safecall( content.obj.LayoutFinished, content.obj, nil, height )
	 end
	)
	
-- A single control fills the whole content area
AceGUI:RegisterLayout("Fill",
	 function(content, children)
		if children[1] then
			children[1].frame:SetAllPoints(content)	
			children[1].frame:Show()
			safecall( content.obj.LayoutFinished, content.obj, nil, children[1].frame:GetHeight() )
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
	 	local rowoffset = 0
	 	local lastrowoffset

	 	local width = content.width or content:GetWidth() or 0
	 	
	 	--control at the start of the row
	 	local rowstart
		local rowstartoffset
	 	local lastrowstart
	 	local isfullheight
	 	
	 	local frameoffset
	 	local lastframeoffset
		for i, child in ipairs(children) do
			
			local frame = child.frame
			local frameheight = frame.height or frame:GetHeight() or 0
			local framewidth = frame.width or frame:GetWidth() or 0
			lastframeoffset = frameoffset
			frameoffset = child.alignoffset or (frameheight / 2)
			
			frame:Show()
			frame:ClearAllPoints()
			if i == 1 then
				-- anchor the first control to the top left
				--frame:SetPoint("TOPLEFT",content,"TOPLEFT",0,0)
				rowheight = frameheight
				rowoffset = frameoffset
				rowstart = frame
				rowstartoffset = frameoffset
				usedwidth = framewidth
			else
				-- if there isn't available width for the control start a new row
				-- if a control is "fill" it will be on a row of its own full width
				if usedwidth == 0 or ((framewidth) + usedwidth > width) or child.width == "fill" then
					--anchor the previous row, we will now know its height and offset
					rowstart:SetPoint("TOPLEFT",content,"TOPLEFT",0,-(height+(rowoffset-rowstartoffset)+3))
					height = height + rowheight + 3
					--save this as the rowstart so we can anchor it after the row is complete and we have the max height and offset of controls in it
					rowstart = frame
					rowstartoffset = frameoffset
					rowheight = frameheight
					rowoffset = frameoffset
					usedwidth = frame.width or frame:GetWidth()
				-- put the control on the current row, adding it to the width and checking if the height needs to be increased
				else
					--handles cases where the new height is higher than either control because of the offsets
					--math.max(rowheight-rowoffset+frameoffset, frameheight-frameoffset+rowoffset)
					
					--offset is always the larger of the two offsets
					rowoffset = math.max(rowoffset, frameoffset)
					
					rowheight = math.max(rowheight,rowoffset+(frameheight/2))
					frame:SetPoint("TOPLEFT",children[i-1].frame,"TOPRIGHT",0,frameoffset-lastframeoffset)
					usedwidth = framewidth + usedwidth
				end
			end

			if child.width == "fill" then
				child:SetWidth(width)
				frame:SetPoint("RIGHT",content,"RIGHT",0,0)
				
				usedwidth = 0
				rowstart = frame
				rowstartoffset = frameoffset
				
				if child.DoLayout then
					child:DoLayout()
				end
				rowheight = frame.height or frame:GetHeight() or 0
				rowoffset = child.alignoffset or (rowheight / 2)
				rowstartoffset = rowoffset
			end
			
			if child.height == "fill" then
				frame:SetPoint("BOTTOM",content,"BOTTOM")
				isfullheight = true
				break
			end
		end
		
		--anchor the last row, if its full height needs a special case since  its height has just been changed by the anchor
		if isfullheight then
			rowstart:SetPoint("TOPLEFT",content,"TOPLEFT",0,-height)
		elseif rowstart then
			rowstart:SetPoint("TOPLEFT",content,"TOPLEFT",0,-(height+(rowoffset-rowstartoffset)+3))
		end
		
		height = height + rowheight + 3
		safecall( content.obj.LayoutFinished, content.obj, nil, height )		
	 end
	)
