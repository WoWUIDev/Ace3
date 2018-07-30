local AceGUI = LibStub("AceGUI-3.0")

local function print(a)
	DEFAULT_CHAT_FRAME:AddMessage(a)
end


local function ZOMGConfig(widget, event)
	AceGUI:Release(widget.userdata.parent)
	
	local f = AceGUI:Create("Frame")
	
	f:SetCallback("OnClose",function(widget, event) print("Closing") AceGUI:Release(widget) end )
	f:SetTitle("ZOMG Config!")
	f:SetStatusText("Status Bar")
	f:SetLayout("Fill")
	
	local maingroup = AceGUI:Create("DropdownGroup")
	maingroup:SetLayout("Fill")
	maingroup:SetGroupList({Addons = "Addons !!", Zomg = "Zomg Addons"})
	maingroup:SetGroup("Addons")
	maingroup:SetTitle("")
	
	f:AddChild(maingroup)
	
	local tree = { "A", "B", "C", "D", B = { "B1", "B2", B1 = { "B11", "B12" } }, C = { "C1", "C2", C1 = { "C11", "C12" } } }
	local text = { A = "Option 1", B = "Option 2", C = "Option 3", D = "Option 4", J = "Option 10", K = "Option 11", L = "Option 12", 
					B1 = "Option 2-1", B2 = "Option 2-2", B11 = "Option 2-1-1", B12 = "Option 2-1-2",
					C1 = "Option 3-1", C2 = "Option 3-2", C11 = "Option 3-1-1", C12 = "Option 3-1-2" }
	local t = AceGUI:Create("TreeGroup")
	t:SetLayout("Fill")
	t:SetTree(tree, text)
	maingroup:AddChild(t)
	
	local tab = AceGUI:Create("TabGroup")
	tab:SetTabs({"A","B","C","D"},{A="Yay",B="We",C="Have",D="Tabs"})
	tab:SetLayout("Fill")
	tab:SelectTab(1)
	t:AddChild(tab)
	
	local component = AceGUI:Create("DropdownGroup")
	component:SetLayout("Fill")
	component:SetGroupList({Blah = "Blah", Splat = "Splat"})
	component:SetGroup("Blah")
	component:SetTitle("Choose Componet")
	
	tab:AddChild(component)
	
	local more = AceGUI:Create("DropdownGroup")
	more:SetLayout("Fill")
	more:SetGroupList({ButWait = "But Wait!", More = "Theres More"})
	more:SetGroup("More")
	more:SetTitle("And More!")
	
	component:AddChild(more)
	
	local sf = AceGUI:Create("ScrollFrame")
	sf:SetLayout("Flow")
	more:AddChild(sf)
	local stuff = AceGUI:Create("Heading")
	stuff:SetText("Omg Stuff Here")
	stuff.width = "fill"
	sf:AddChild(stuff)
	
	for i = 1, 10 do
		local edit = AceGUI:Create("EditBox")
		edit:SetText("")
		edit:SetWidth(200)
		edit:SetLabel("Stuff!")
		edit:SetCallback("OnEnterPressed",function(widget,event,text) widget:SetLabel(text) end )
		edit:SetCallback("OnTextChanged",function(widget,event,text) print(text) end )
		sf:AddChild(edit)
	end
	
	f:Show()
end

local function GroupA(content)
	content:ReleaseChildren()
	
	local sf = AceGUI:Create("ScrollFrame")
	sf:SetLayout("Flow")
	
	local edit = AceGUI:Create("EditBox")
	edit:SetText("Testing")
	edit:SetWidth(200)
	edit:SetLabel("Group A Option")
	edit:SetCallback("OnEnterPressed",function(widget,event,text) widget:SetLabel(text) end )
	edit:SetCallback("OnTextChanged",function(widget,event,text) print(text) end )
	sf:AddChild(edit)
	
	local slider = AceGUI:Create("Slider")
	slider:SetLabel("Group A Slider")
	slider:SetSliderValues(0,1000,5)
	slider:SetDisabled(false)
	sf:AddChild(slider)
	
	local zomg = AceGUI:Create("Button")
	zomg.userdata.parent = content.userdata.parent
	zomg:SetText("Zomg!")
	zomg:SetCallback("OnClick", ZOMGConfig)
	sf:AddChild(zomg)
	
	local heading1 = AceGUI:Create("Heading")
	heading1:SetText("Heading 1")
	heading1.width = "fill"
	sf:AddChild(heading1)
	
	for i = 1, 5 do
		local radio = AceGUI:Create("CheckBox")
		radio:SetLabel("Test Check "..i)
		radio:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Check "..i.." Checked" or "Check "..i.." Unchecked") end )
		sf:AddChild(radio)
	end
	
	local heading2 = AceGUI:Create("Heading")
	heading2:SetText("Heading 2")
	heading2.width = "fill"
	sf:AddChild(heading2)
	
	for i = 1, 5 do
		local radio = AceGUI:Create("CheckBox")
		radio:SetLabel("Test Check "..i+5)
		radio:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Check "..i.." Checked" or "Check "..i.." Unchecked") end )
		sf:AddChild(radio)
	end
	
	local heading1 = AceGUI:Create("Heading")
	heading1:SetText("Heading 1")
	heading1.width = "fill"
	sf:AddChild(heading1)
	
    for i = 1, 5 do
	    local radio = AceGUI:Create("CheckBox")
	    radio:SetLabel("Test Check "..i)
	    radio:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Check "..i.." Checked" or "Check "..i.." Unchecked") end )
	    sf:AddChild(radio)
	end
	
	local heading2 = AceGUI:Create("Heading")
	heading2:SetText("Heading 2")
	heading2.width = "fill"
	sf:AddChild(heading2)
	
    for i = 1, 5 do
	    local radio = AceGUI:Create("CheckBox")
	    radio:SetLabel("Test Check "..i+5)
	    radio:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Check "..i.." Checked" or "Check "..i.." Unchecked") end )
	    sf:AddChild(radio)
	end
    
	content:AddChild(sf)
end

local function GroupB(content)
	content:ReleaseChildren()
	local sf = AceGUI:Create("ScrollFrame")
	sf:SetLayout("Flow")
	
 	local check = AceGUI:Create("CheckBox")
	check:SetLabel("Group B Checkbox")
	check:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Checked" or "Unchecked") end )
	
	local dropdown = AceGUI:Create("Dropdown")
	dropdown:SetText("Test")
	dropdown:SetLabel("Group B Dropdown")
	dropdown.list = {"Test","Test2"}
	dropdown:SetCallback("OnValueChanged",function(widget,event,value) print(value) end )
	
	sf:AddChild(check)
	sf:AddChild(dropdown)
	content:AddChild(sf)
end

local function OtherGroup(content)
	content:ReleaseChildren()
	
	local sf = AceGUI:Create("ScrollFrame")
	sf:SetLayout("Flow")
	
 	local check = AceGUI:Create("CheckBox")
	check:SetLabel("Test Check")
	check:SetCallback("OnValueChanged",function(widget,event,value) print(value and "CheckButton Checked" or "CheckButton Unchecked") end )
	
	sf:AddChild(check)
	
	local inline = AceGUI:Create("InlineGroup")
	inline:SetLayout("Flow")
	inline:SetTitle("Inline Group")
	inline.width = "fill"

	local heading1 = AceGUI:Create("Heading")
	heading1:SetText("Heading 1")
	heading1.width = "fill"
	inline:AddChild(heading1)
	
	for i = 1, 10 do
		local radio = AceGUI:Create("CheckBox")
		radio:SetLabel("Test Radio "..i)
		radio:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Radio "..i.." Checked" or "Radio "..i.." Unchecked") end )
		radio:SetType("radio")
		inline:AddChild(radio)
	end
	
	local heading2 = AceGUI:Create("Heading")
	heading2:SetText("Heading 2")
	heading2.width = "fill"
	inline:AddChild(heading2)
	
	for i = 1, 10 do
		local radio = AceGUI:Create("CheckBox")
		radio:SetLabel("Test Radio "..i)
		radio:SetCallback("OnValueChanged",function(widget,event,value) print(value and "Radio "..i.." Checked" or "Radio "..i.." Unchecked") end )
		radio:SetType("radio")
		inline:AddChild(radio)
	end
	
	
	sf:AddChild(inline)
	content:AddChild(sf)
end

local function SelectGroup(widget, event, value)
	if value == "A" then
		GroupA(widget)
	elseif value == "B" then
	 GroupB(widget)
	else
		OtherGroup(widget)
	end
end


local function TreeWindow(content)
	content:ReleaseChildren()
	
	local tree = { 
			{ 
				value = "A",
				text = "Alpha"
			},
			{
				value = "B",
				text = "Bravo",
				children = {
					{ 
						value = "C", 
						text = "Charlie",
					},
					{
						value = "D",	
						text = "Delta",
						children = { 
							{ 
								value = "E",
								text = "Echo",
							} 
						} 
					},
				}
			},
			{ 
				value = "F", 
				text = "Foxtrot",
			},
		}
	local t = AceGUI:Create("TreeGroup")
	t:SetLayout("Fill")
	t:SetTree(tree)
	t:SetCallback("OnGroupSelected", SelectGroup )
	content:AddChild(t)
	SelectGroup(t,"OnGroupSelected","A")
	
end

local function TabWindow(content)
	content:ReleaseChildren()
	local tab = AceGUI:Create("TabGroup")
	tab.userdata.parent = content.userdata.parent
	tab:SetTabs({"A","B","C","D"},{A="Alpha",B="Bravo",C="Charlie",D="Deltaaaaaaaaaaaaaa"})
	tab:SetTitle("Tab Group")
	tab:SetLayout("Fill")
	tab:SetCallback("OnGroupSelected",SelectGroup)
	tab:SelectTab(1)
	content:AddChild(tab)
	
end


function TestFrame()
	local f = AceGUI:Create("Frame")
	f:SetCallback("OnClose",function(widget, event) print("Closing") AceGUI:Release(widget) end )
	f:SetTitle("AceGUI Prototype")
	f:SetStatusText("Root Frame Status Bar")
	f:SetLayout("Fill")
	
	local maingroup = AceGUI:Create("DropdownGroup")
	maingroup.userdata.parent = f
	maingroup:SetLayout("Fill")
	maingroup:SetGroupList({Tab = "Tab Frame", Tree = "Tree Frame"})
	maingroup:SetGroup("Tab")
	maingroup:SetTitle("Select Group Type")
	maingroup:SetCallback("OnGroupSelected", function(widget, event, value)
		widget:ReleaseChildren()
		if value == "Tab" then
			TabWindow(widget)
		else
			TreeWindow(widget)
		end
	end )
	
	TabWindow(maingroup)
	f:AddChild(maingroup)
	
	
	f:Show()
end

-----------------------
-- DragTarget Widget --
-----------------------
-- Designed to replace type='input' in AceConfigDialog-3.0
do
	local Type = "DragTarget"
	local Version = 1
	local function Acquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	

	local function SetLabel(self, text)
		self.label:SetText(text)
	end

	local function PickupItem(link)
		local name = GetItemInfo(link)
		for bag = 0, 4 do
			for slot = 1, GetContainerNumSlots(bag) do
				local slotlink = GetContainerItemLink(bag, slot)
				if slotlink then
					local slotname = GetItemInfo(slotlink)
					if slotname == name then
						PickupContainerItem(bag, slot)
						return
					end
				end
			end
		end
	end

	local function DragLinkOnDragStart(this)
		local self = this.obj
		if (self.objType == "item") then
			PickupItem(self.value)
		elseif (self.objType == "spell") then
			PickupSpell(self.value)
		elseif (self.objType == "macro") then
			PickupMacro(strsub(self.value,7))
		end
		self:SetText("")
		self:Fire("OnEnterPressed", self.value)
	end
	

	local function DragLinkGetTexture(self)
		if (self.objType == "item") then
				local texture = select(10,GetItemInfo(self.value))
				if (texture) then
					return texture
				end
		elseif (self.objType == "spell") then
			local texture = GetSpellTexture(self.value)
			if (texture) then
				return texture
			end
		elseif (self.objType == "macro") then
			local name, texture = GetMacroInfo(strsub(self.value,7))
			return texture
		end
		return 134400 -- Interface\\Icons\\INV_Misc_QuestionMark
	end
	
	local function GetValueFromParams(objType, Info1, Info2)
		if objType == "item" then
			--for items use the link
			return Info2
		elseif objType == "spell" then
			local name, rank = GetSpellName(Info1, Info2)
			if rank ~= "" then name = name.."("..rank..")" end
			return name
		elseif objType == "macro" then
			return "macro:"..GetMacroInfo(Info1)
		end
	end
	
	local function DragLinkOnReceiveDrag(this)
		local self = this.obj

		local objType, Info1, Info2 = GetCursorInfo()

		if (objType == "item" or objType == "spell" or objType == "macro") then
			self.objType = objType
			self.value = GetValueFromParams(objType, Info1, Info2)
			self:Fire("OnEnterPressed", self.value)
			self.linkIcon:SetTexture(DragLinkGetTexture(self))

			ClearCursor()
		end
	end
	
	local function SetText(self, text)
		if not text then text = "" end
		if text:find("item:%d+") then
			self.objType = "item"
			self.value = text
		elseif strsub(text,1,6) == "macro:" then
			self.objType = "macro"
			self.value = text
		elseif text ~= "" then
			self.objType = "spell"
			self.value = text
		else
			self.objType = nil
			self.value = ""
		end
		self.linkIcon:SetTexture(DragLinkGetTexture(self))
		self.text:SetText(self.value or "")
	end
	
	local function SetDisabled(self, disabled)
	
	end
	
	local function Constructor()
		local frame = CreateFrame("Button",nil,UIParent)
		local self = {}
		self.type = Type
		

		self.Release = Release
		self.Acquire = Acquire
		self.SetLabel = SetLabel
		self.SetText = SetText
		self.SetDisabled = SetDisabled
		self.UpdateValue = UpdateValue
		
		self.frame = frame
		frame.obj = self

		frame:SetScript("OnDragStart", DragLinkOnDragStart)
		frame:SetScript("OnReceiveDrag", DragLinkOnReceiveDrag)
		frame:SetScript("OnClick", DragLinkOnReceiveDrag)
		frame:SetScript("OnEnter", DragLinkOnEnter)
		frame:SetScript("OnLeave", DragLinkOnLeave)
	
		frame:EnableMouse()
		frame:RegisterForDrag("LeftButton")
		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
		local linkIcon = frame:CreateTexture(nil, "OVERLAY")
		linkIcon:SetWidth(self.iconWidth or 36)
		linkIcon:SetHeight(self.iconHeight or 36)
		linkIcon:SetPoint("LEFT",frame,"LEFT",0,0)
		linkIcon:SetTexture(DragLinkGetTexture(self))
		linkIcon:SetTexCoord(0,1,0,1)
		linkIcon:Show()
		self.linkIcon = linkIcon
		
		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		label:SetPoint("TOPLEFT",linkIcon,"TOPRIGHT",3,-3)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetHeight(10)
		label:SetJustifyH("LEFT")
		self.label = label
		
		local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
		text:SetPoint("BOTTOMLEFT",linkIcon,"BOTTOMRIGHT",3,3)
		text:SetPoint("RIGHT",frame,"RIGHT",0,0)
		text:SetHeight(10)
		text:SetTextColor(1,1,1,1)
		text:SetJustifyH("LEFT")
		self.text = text
	
		text:SetJustifyH("LEFT")
		text:SetTextColor(1,1,1)
	
		frame:SetHeight(36)
		frame:SetWidth(200)

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor,Version)
	
end

local name = "ConfigTest" 
local groups = {} 
local testgroups = {
	type = "group",
	name = "Test Group Delete/Hide/Diabled",
	childGroups = "select",
	args = {
	
	}
}

local function Delete(info) 
  testgroups.args[info.arg] = nil 
end 

local function Disable(info) 
  testgroups.args[info.arg].disabled = true 
end 

local function Hide(info)
  testgroups.args[info.arg].hidden = true
end

local function Replace(info)
	testgroups.args[info.arg] = {
		type = "execute",
		name = "Replaced"..info.arg
	}
end

groups.description = {
	type = 'description',
	name = 'This is a test Description Icon + Width and height from a function, no coords',
	image = function() return 136235, 100, 100 end, -- Interface\\Icons\\Temp
	--imageCoords = { 0, 0.5, 0, 0.5 },
	order = 1,
}
--[[
groups.description2 = {
	type = 'description',
	name = 'This is a test Description Image + width and height directly set',
	image = 136235, -- Interface\\Icons\\Temp
	imageCoords = { 0, 0.5, 0, 0.5 },
	imageWidth = 100,
	imageHeight = 100,
	order = 2,
}

groups.description3 = {
	type = 'description',
	name = '',
	image = function() return 136235, 100, 100 end, -- Interface\\Icons\\Temp
	--imageCoords = { 0, 0.5, 0, 0.5 },
	order = 3,
}
--]]
groups.confirm = {
	type = 'execute',
	name = 'Test Confirm',
	order = 15,
	func = function() print("Confirmed") end,
	confirm = true,
	confirmText = "Confirm Prompt",
}

local dragvalue = nil

groups.customDrag = {
	type = 'input',
	name = 'Test Custom Control',
	get = function() return dragvalue end,
	set = function(info, value) dragvalue = value end,
	dialogControl = "DragTarget",
	order = 16,
}


for i = 1, 5 do 
  testgroups.args["group"..i] = { 
    order = i, 
    type = "group", 
    name = "Group"..i, 
    args = { 
      delete = { 
        name = "Delete", 
        desc = "Delete this group", 
        type = "execute", 
        arg = "group"..i, 
        func = Delete, 
      }, 
		disable = { 
        name = "Disable", 
        desc = "Disable this group", 
        type = "execute", 
        arg = "group"..i, 
        func = Disable, 
      }, 
		hide = { 
        name = "Hide", 
        desc = "Hide this group", 
        type = "execute", 
        arg = "group"..i, 
        func = Hide, 
      }, 
		replace = { 
        name = "Replace", 
        desc = "Replace this group", 
        type = "execute", 
        arg = "group"..i, 
        func = Replace, 
      }, 
    } 
  } 
end 

local m = { }

groups.multi = {
	type = 'multiselect',
	name = 'multi',
	desc = 'Test Multiselect',
	tristate = true,
	width = "half",
	set = function(info, key, value) m[key] = value print(key, value) end,
	get = function(info, key) return m[key] end,
	order = 100,
	values = {
		a = "Alpha",
		b = "Bravo",
		c = "Charlie",
		d = "Delta",
		e = "Echo",
		f = "Foxtrot",
	}
}

local sel = 'a'

groups.select = {
	type = 'select',
	name = 'select',
	desc = 'Test Select',
	set = function(info, key, value) sel = key print(sel) end,
	get = function(info, key) return sel end,
	order = 101,
	values = {
		a = "Alpha",
		b = "Bravo",
		c = "Charlie",
		d = "Delta",
		e = "Echo",
		f = "Foxtrot",
	}
}

local toggleval

groups.toggle = {
	type = 'toggle',
	name = 'toggle',
	desc = 'Test Toggle',
	set = function(info, value) toggleval = value print(toggleval) end,
	get = function(info) return toggleval end,
	tristate = true,
	order = 102
}

local R,G,B,A = 1.0,1.0,1.0,1.0

groups.color = {
	type = 'color',
	name = 'color',
	desc = 'Test Color',
	set = function(info, r,g,b,a) R,G,B,A = r,g,b,a print(R,G,B,A) end,
	get = function(info) return R,G,B,A end,
	hasAlpha = false,
	order = 103
}

groups.colora = {
	type = 'color',
	name = 'colora',
	desc = 'Test Color with Alpha',
	set = function(info, r,g,b,a) R,G,B,A = r,g,b,a print(R,G,B,A) end,
	get = function(info) return R,G,B,A end,
	hasAlpha = true,
	order = 104
}

local keyval
groups.key = {
	type = 'keybinding',
	name = 'key',
	desc = 'Test Keybind',
	set = function(info, value) keyval = value print(keyval) end,
	get = function(info) return keyval end,
	order = 105,
}

local mval
groups.multiline = {
	type = 'input',
	name = "Multiline",
	desc = "Test Multiline",
	set = function(info, value) mval = value print(mval) end,
	get = function(info) return mval end,
	multiline = true,
}

local options = { 
  type = "group", 
  name = name, 
  childGroups = "tab", 
  args = {
	  	test = {
	  	type = "group",
	  	name = "Test Controls",
	  	args = groups,
	  	disabled = false
  	}
  } 
} 

local types = {'input', 'toggle', 'select', 'multiselect', 'range', 'keybinding', 'execute', 'color'}
local function GetTestOpts(disabled)
	local values = { input = "Test", select = 'a', multiselect = true, range = 1}
	local group = {
		type = "group",
		--inline = true,
		name = "Options",
		set = function(info, value) values[info[#info]] = value end,
		get = function(info, value) return values[info[#info]] end,
		args = {}
	}
	
	if disabled then
		group.name = "Disabled Options"
	end

	for i, type in ipairs(types) do
		local opt = {}
		opt.name = type
		opt.type = type
		opt.desc = "Test "..type
		opt.order = i
		opt.disabled = disabled
		if type == "select" or type =="multiselect" then
			opt.values = {
				a = "Alpha",
				b = "Bravo",
				c = "Charlie",
				d = "Delta",
				e = "Echo",
				f = "Foxtrot",
			}
		end
		
		if type == "range" then
			opt.min = 0
			opt.max = 1000
			opt.step = 1
			opt.bigStep = 10
		end
		
		if type == "execute" then
			opt.func = function(info) print("Execute") end
		end
		
		group.args[type] = opt
	end
	return group
end

options.plugins = {}
options.plugins.normal = { normal = GetTestOpts() }
options.plugins.disabled = { disabled = GetTestOpts(true) }
options.plugins.test = { testgroups = testgroups }

LibStub("AceConfig-3.0"):RegisterOptionsTable(name, options, "ct") 
--LibStub("AceConfigDialog-3.0"):Open("ConfigTest" )

