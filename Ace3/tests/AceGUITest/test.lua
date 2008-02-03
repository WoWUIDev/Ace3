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

local p

local testing = { color1 = {r=1,g=1,b=1,a=1}, color2 = {r=0,g=0,b=0,a=1} }

local key1, key2 = "", ""
local testedit = "Testing inherited set/get"

local dragvalue = "Healing Touch(Rank 7)"
	
local BagginsAce3Opts = {
		type = "group",
		icon = "Interface\\Icons\\INV_Jewelry_Ring_03",
		name = "Baggins",
		childGroups = "tree",
		set = function(info, value) Baggins:Print(value) testedit = value end,
		get = function(info) return testedit end,
		args = {
			Test = {
				name = "Test",
				type = 'group',
				order = 1,
				desc = "Test Controls",
				validate = function(info, ...) return true end,
				args = {
					Test = {
						type = 'input',
						order = 1,
						name = 'Testing',
						desc = 'Testing',
						arg = "Test",
						pattern = "%d+",
					},
					TestMulti = {
						type = "multiselect",
						name = "Testing Multiselect",
						order = 1,
						set = function(info, key, value) testing[key] = value end,
						get = function(info, key) return testing[key] end,
						values = {
							Test1 = "Testing 1",
							Test2 = "Testing 2",
							Test3 = "Testing 3"
						}
					},	
					Color = {
						type = 'color',
						name = "Test Color",
						order = 2,
						set = function(info, r,g,b,a) local c = testing.color1 c.r,c.g,c.b,c.a = r,g,b,a end,
						get = function(info) c = testing.color1 return c.r,c.g,c.b,c.a end,
					},
					Color2 = {
						type = 'color',
						name = "Test Color 2",
						order = 3,
						set = function(info, r,g,b,a) local c = testing.color2 c.r,c.g,c.b,c.a = r,g,b,a end,
						get = function(info) c = testing.color2 return c.r,c.g,c.b,c.a end,
					},
					Key1 = {
						type = 'keybinding',
						name = "Test Keybind",
						order = 4,
						set = function(info, key)  key1 = key end,
						get = function(info) return key1 end,
					},
					Key2 = {
						type = 'keybinding',
						name = "Test Keybind 2",
						order = 4,
						set = function(info, key) key2 = key end,
						get = function(info) return key2 end,
					},
					DragTest2 = {
						type = 'input',
						--dlgType = "DragTarget",
						name = "Test Drag - Fallback to Text",
						set = function(info, value) dragvalue = value end,
						get = function(info) return dragvalue end,
						order = 6
					},
					h = {
						type = 'header',
						name = 'Test Drag Control',
						order = 7,
					},
					DragTest = {
						type = 'input',
						--dlgType = "DragTarget",
						name = "Test Drag",
						set = function(info, value) dragvalue = value end,
						get = function(info) return dragvalue end,
						order = 10
					},
				}
			},
			Refresh = {
				name = "Force Full Refresh",
				type = "execute",
				order = 9,
				desc = "Forces a Full Refresh of item sorting",
				func = function(info) Baggins:ForceFullRefresh() Baggins:UpdateBags() end,
			},
			BagCatEdit = {
				name = "Bag/Category Config",
				type = "execute",
				order = 2,
				desc = "Opens the Waterfall Config window",
				func = function(info) waterfall:Open("BagginsEdit") dewdrop:Close() end,
				disabled = function(info) return not waterfall end,
				
			},
			spacer3 = {
				type = "header",
				order = 90,
				dialogHidden=true,
				name = '',
			},
			Items = {
				name = "Items",
				type = 'group',
				order = 120,
				desc = "Item display settings",
				childGroups = "tab",
				args = {
					Compress = {
						name = "Compress",
						desc = "Compress Multiple stacks into one item button",
						type = "group",
						order = 10,
						disabled = function(info) return p.sort == "slot" end,
						args = {
							CompressAll = {
								name = "Compress All",
								type = "toggle",
								desc = "Show all items as a single button with a count on it",
								order = 10,
								get = function(info) return p.compressall end,
								set = function(info, value)
									p.compressall = value
									Baggins:RebuildSectionLayouts()
									Baggins:UpdateBags()
								end,
							},
							CompressStackable = {
								name = "Compress Stackable Items",
								type = "toggle",
								desc = "Show stackable items as a single button with a count on it",
								order = 20,
								disabled = function(info) return p.compressall end,
								get = function(info) return p.compressstackable or p.compressall end,
								set = function(info, value)
									p.compressstackable = value
									Baggins:RebuildSectionLayouts()									
									Baggins:UpdateBags()
								end,
							},
							spacer = {
								type = 'header',
								order = 90,
								name = '',
							},
							CompressEmptySlots = {
								name = "Compress Empty Slots",
								type = "toggle",
								desc = "Show all empty slots as a single button with a count on it",
								order = 100,
								disabled = function(info) return p.compressall end,
								get = function(info) return p.compressempty or p.compressall end,
								set = function(info, value)
									p.compressempty = value
									Baggins:RebuildSectionLayouts()
									Baggins:UpdateBags()
								end,
							},
							CompressShards = {
								name = "Compress Soul Shards",
								type = "toggle",
								desc = "Show all soul shards as a single button with a count on it",
								order = 110,
								disabled = function(info) return p.compressall end,
								get = function(info) return p.compressshards or p.compressall end,
								set = function(info, value)
									p.compressshards = value
									Baggins:RebuildSectionLayouts()
									Baggins:UpdateBags()
								end,
							},
							CompressAmmo = {
								name = "Compress Ammo",
								type = "toggle",
								desc = "Show all ammo as a single button with a count on it",
								order = 120,
								disabled = function(info) return p.compressall or p.compressstackable end,
								get = function(info) return p.compressammo or p.compressstackable or p.compressall end,
								set = function(info, value)
									p.compressammo = value
									Baggins:RebuildSectionLayouts()
									Baggins:UpdateBags()
								end,
							},
						}
					},
					QualityColor = {
						name = "Quality Colors",
						desc = "Color item buttons based on the quality of the item",
						type = "group",
						order = 15,
						args = {
							Enable = {
								name = "Enable",
								type = "toggle",
								desc = "Enable quality coloring",
								order = 10,
								get = function(info) return p.qualitycolor end,
								set = function(info, value)
									p.qualitycolor = value
									Baggins:UpdateItemButtons()
								end,
							},
							Threshold = {
								name = "Color Threshold",
								type = "select",
								desc = "Only color items of this quality or above",
								order = 15,

								get = function(info) return ("%d"):format(p.qualitycolormin) end,
								set = function(info, value)
									p.qualitycolormin = tonumber(value)
									Baggins:UpdateItemButtons()
								end,
								disabled = function(info) return not p.qualitycolor end,
								values = { 
									["0"] = "|c00000000"..select(4,GetItemQualityColor(0))..ITEM_QUALITY0_DESC,
									["1"] = "|c10000000"..select(4,GetItemQualityColor(1))..ITEM_QUALITY1_DESC,
									["2"] = "|c20000000"..select(4,GetItemQualityColor(2))..ITEM_QUALITY2_DESC,
									["3"] = "|c30000000"..select(4,GetItemQualityColor(3))..ITEM_QUALITY3_DESC,
									["4"] = "|c40000000"..select(4,GetItemQualityColor(4))..ITEM_QUALITY4_DESC,
									["5"] = "|c50000000"..select(4,GetItemQualityColor(5))..ITEM_QUALITY5_DESC,
									["6"] = "|c60000000"..select(4,GetItemQualityColor(6))..ITEM_QUALITY6_DESC,
								}
							},
							Intensity = {
								name = "Color Intensity",
								type = "range",
								desc = "Intensity of the quality coloring",
								order = 20,
								max = 1,
								min = 0.1,
								step = 0.1,
								get = function(info) return p.qualitycolorintensity end,
								set = function(info, value)
									p.qualitycolorintensity = value
									Baggins:UpdateItemButtons()
								end,
								disabled = function(info) return not p.qualitycolor end,
							},
						}
					},
					HideDuplicates = {
						name = "Hide Duplicate Items",
						type = "select",
						desc = "Prevents items from appearing in more than one section/bag.",
						order = 20,
						get = function(info) return p.hideduplicates end,
						set = function(info, value)
							p.hideduplicates = value
							Baggins:ResortSections()
							Baggins:UpdateBags()
						end,
						values = { 'global', 'bag', 'disabled' },
					},
					AlwaysReSort = {
						name = "Always Resort",
						type = "toggle",
						desc = "Keeps Items sorted always, this will cause items to jump around when selling etc.",
						order = 22,
						get = function(info) return p.alwaysresort end,
						set = function(info, value)
							p.alwaysresort = value
						end
					},
					spacer = {
						type = 'header',
						order = 25,
						name = '',
					},
					HighlightNew = {
						name = "Highlight New Items",
						type = "toggle",
						desc = "Add *New* to new items, *+++* to items that you have gained more of.",
						order = 30,
						get = function(info) return p.highlightnew end,
						set = function(info, value)
							p.highlightnew = value
							Baggins:UpdateItemButtons()
						end
					},
					ResetNew = {
						name = "Reset New Items",
						type = "execute",
						desc = "Resets the new items highlights.",
						order = 35,
						func = function(info)
							Baggins:SaveItemCounts()
							Baggins:ForceFullUpdate()
						end,
						disabled = function(info) return not p.highlightnew end,
					},
				}
			},
			Layout = {
				name = "Layout",
				type = 'group',
				order = 125,
				desc = "Appearance and layout",
				args = {
					Bags = {
						type = 'header',
						order = 5,
						name = "Bags",
					},
					Type = {
						name = "Layout Type",
						type = 'select',
						order = 10,
						desc = "Sets how all bags are laid out on screen.",
						get = function(info) return p.layout end,
						set = function(info, value) p.layout = value Baggins:UpdateLayout() end,
						values = { "auto", "manual" },
					},
					LayoutAnchor = {
						name = "Layout Anchor",
						type = "select",
						order = 15,
						desc = "Sets which corner of the layout bounds the bags will be anchored to.",
						get = function(info) return p.layoutanchor end,
						set = function(info, value) p.layoutanchor =  value Baggins:LayoutBagFrames() end,
						values = { TOPRIGHT = "Top Right",
									TOPLEFT = "Top Left",
									BOTTOMRIGHT = "Bottom Right",
									BOTTOMLEFT = "Bottom Left" },
						disabled = function(info) return p.layout ~= 'auto' end,
					},
					SetLayoutBounds = {
						name = "Set Layout Bounds",
						type = "execute",
						order = 20,
						desc = "Shows a frame you can drag and size to set where the bags will be placed when Layout is automatic",
						func = function(info) Baggins:ShowPlacementFrame() end,
						disabled = function(info) return p.layout ~= 'auto' end,
					},
					Lock = {
						name = "Lock",
						type = "toggle",
						desc = "Locks the bag frames making them unmovable",
						order = 30,
						get = function(info) return p.lock or p.layout == "auto" end,
						set = function(info, value) p.lock = value end,
						disabled = function(info) return p.layout == "auto" end,
					},
		 			OpenAtAuction = {
		 				name = "Automatically open at auction house",
		 				type = "toggle",
		 				desc = "Automatically open at auction house",
		 				order = 35,
		 				get = function(info) return p.openatauction end,
		 				set = function(info, value) p.openatauction = value end,
		 			},
					ShrinkWidth = {
						name = "Shrink Width",
						type = "toggle",
						desc = "Shrink the bag's width to fit the items contained in them",
						order = 40,
						get = function(info) return p.shrinkwidth end,
						set = function(info, value)
							p.shrinkwidth = value
							Baggins:UpdateBags()
						end,
					},
					ShrinkTitle = {
						name = "Shrink bag title",
						type = "toggle",
						desc = "Mangle bag title to fit to content width",
						order = 50,
						get = function(info) return p.shrinkbagtitle end,
						set = function(info, value)
							p.shrinkbagtitle = value
							Baggins:UpdateBags()
						end,
					},
					Scale = {
						name = "Scale",
						type = "range",
						desc = "Scale of the bag frames",
						order = 60,
						max = 2,
						min = 0.3,
						bigStep = 0.1,
						get = function(info) return p.scale end,
						set = function(info, value)
							p.scale = value 
							Baggins:UpdateBagScale()
							Baggins:UpdateLayout()
						end,
					},
					ShowMoney = {
						name = "Show Money On Bag",
						type = "group",
						desc = "Which Bag to Show Money On",
						order = 64,
						inline = true,
						get = function(info, key) return p.moneybag == key end,
						set = function(info, key, value) p.moneybag = key Baggins:UpdateBags() end,
						args = {
							None = {
								type = "toggle",
								name = "None",
								desc = "None",
								arg = 0,
								order = 1,
							},
						}
					},
					Sections = {
						type = 'header',
						order = 65,
						name = "Sections",
					},
					SectionLayout = {
						name = "Optimize Section Layout",
						type = "toggle",
						desc = "Change order and layout of sections in order to save display space.",
						order = 70,
						get = function(info) return p.optimizesectionlayout end,
						set = function(info, value)
							p.optimizesectionlayout = value
							Baggins:UpdateBags()
						end
					},
					SectionTitle = {
						name = "Show Section Title",
						type = "toggle",
						desc = "Show a title on each section of the bags",
						order = 80,
						get = function(info) return p.showsectiontitle end,
						set = function(info, value)
							p.showsectiontitle = value
							Baggins:UpdateBags()
						end
					},
					HideEmptySections = {
						name = "Hide Empty Sections",
						type = "toggle",
						desc = "Hide sections that have no items in them.",
						order = 90,
						get = function(info) return p.hideemptysections end,
						set = function(info, value)
							p.hideemptysections = value
							Baggins:UpdateBags()
						end
					},
					Sort = {
						name = "Sort",
						type = "select",
						desc = "How items are sorted",
						order = 100,
						get = function(info) return p.sort end,
						set = function(info, value) p.sort = value Baggins:UpdateBags() end,
						values = {'quality', 'name', 'type', 'slot' }
					},
					SortNewFirst = {
						name = "Sort New First",
						type = "toggle",
						desc = "Sorts New Items to the beginning of sections",
						order = 105,
						get = function(info) return p.sortnewfirst end,
						set = function(info, value) p.sortnewfirst = value end,
					},
					Columns = {
						name = "Columns",
						type = "range",
						desc = "Number of Columns shown in the bag frames",
						order = 110,
						get = function(info) return p.columns end,
						set = function(info, value) p.columns = value Baggins:UpdateBags() end,
						min = 2,
						max = 20,
						step = 1,
					},
				}
			},
			FubarText = {
				name = "FuBar Text",
				type = "group",
				desc = "Options for the text shown on fubar",
				order = 130,
				args = {	
					ShowEmpty = {
						name = "Show empty bag slots",
						type = "toggle",
						order = 10,
						desc = "Show empty bag slots",
						get = function(info) return p.showempty end,
						set = function(info, value)
							p.showempty = value
							Baggins:UpdateText()
						end,
					},
					ShowUsed = {
						name = "Show used bag slots",
						type = "toggle",
						order = 20,
						desc = "Show used bag slots",
						get = function(info) return p.showused end,
						set = function(info, value)
							p.showused = value
							Baggins:UpdateText()
						end,
					},
					ShowTotal = {
						name = "Show Total bag slots",
						type = "toggle",
						order = 30,
						desc = "Show Total bag slots",
						get = function(info) return p.showtotal end,
						set = function(info, value)
							p.showtotal = value
							Baggins:UpdateText()
						end,
					},
					Combine = {
						name = "Combine Counts",
						type = "toggle",
						order = 40,
						desc = "Show only one count with all the seclected types included",
						get = function(info) return p.combinecounts end,
						set = function(info, value)
							p.combinecounts = value
							Baggins:UpdateText()
						end,
					},
					spacer = {
						type = 'header',
						order = 45,
						name = '',
					},
					ShowAmmo = {
						name = "Show Ammo Bags Count",
						type = "toggle",
						order = 50,
						desc = "Show Ammo Bags Count",
						get = function(info) return p.showammocount end,
						set = function(info, value)
							p.showammocount = value
							Baggins:UpdateText()
						end,
					},
					ShowSoul = {
						name = "Show Soul Bags Count",
						type = "toggle",
						order = 55,
						desc = "Show Soul Bags Count",
						get = function(info) return p.showsoulcount end,
						set = function(info, value)
							p.showsoulcount = value
							Baggins:UpdateText()
						end,
					},
					ShowSpecialty = {
						name = "Show Specialty Bags Count",
						type = "toggle",
						order = 60,
						desc = "Show Specialty (profession etc) Bags Count",
						get = function(info) return p.showspecialcount end,
						set = function(info, value)
							p.showspecialcount = value
							Baggins:UpdateText()
						end,
					},
					FubarText2 = {
				name = "FuBar Text",
				type = "group",
				desc = "Options for the text shown on fubar",
				order = 130,
				args = {	
					ShowEmpty = {
						name = "Show empty bag slots2",
						type = "toggle",
						order = 10,
						desc = "Show empty bag slots",
						get = function(info) return p.showempty end,
						set = function(info, value)
							p.showempty = value
							Baggins:UpdateText()
						end,
					},
					ShowUsed = {
						name = "Show used bag slots2",
						type = "toggle",
						order = 20,
						desc = "Show used bag slots",
						get = function(info) return p.showused end,
						set = function(info, value)
							p.showused = value
							Baggins:UpdateText()
						end,
					},
					ShowTotal = {
						name = "Show Total bag slots2",
						type = "toggle",
						order = 30,
						desc = "Show Total bag slots",
						get = function(info) return p.showtotal end,
						set = function(info, value)
							p.showtotal = value
							Baggins:UpdateText()
						end,
					},
					Combine = {
						name = "Combine Counts2",
						type = "toggle",
						order = 40,
						desc = "Show only one count with all the seclected types included",
						get = function(info) return p.combinecounts end,
						set = function(info, value)
							p.combinecounts = value
							Baggins:UpdateText()
						end,
					},
					spacer = {
						type = 'header',
						order = 45,
						name = '',
					},
					ShowAmmo = {
						name = "Show Ammo Bags Count",
						type = "toggle",
						hidden = true,
						order = 50,
						desc = "Show Ammo Bags Count",
						get = function(info) return p.showammocount end,
						set = function(info, value)
							p.showammocount = value
							Baggins:UpdateText()
						end,
					},
					ShowSoul = {
						name = "Show Soul Bags Count2",
						type = "toggle",
						hidden = function(info) return true end,
						order = 55,
						desc = "Show Soul Bags Count",
						get = function(info) return p.showsoulcount end,
						set = function(info, value)
							p.showsoulcount = value
							Baggins:UpdateText()
						end,
					},
					ShowSpecialty = {
						name = "Show Specialty Bags Count",
						type = "toggle",
						dialogHidden = true,
						order = 60,
						desc = "Show Specialty (profession etc) Bags Count",
						get = function(info) return p.showspecialcount end,
						set = function(info, value)
							p.showspecialcount = value
							Baggins:UpdateText()
						end,
					},
					FubarText3 = {
				name = "FuBar Text",
				type = "group",
				desc = "Options for the text shown on fubar",
				order = 130,
				dialogHidden = true,
				args = {	
					ShowEmpty = {
						name = "Show empty bag slots32",
						type = "toggle",
						order = 10,
						desc = "Show empty bag slots",
						get = function(info) return p.showempty end,
						set = function(info, value)
							p.showempty = value
							Baggins:UpdateText()
						end,
					},
					ShowUsed = {
						name = "Show used bag slots3",
						type = "toggle",
						order = 20,
						desc = "Show used bag slots",
						get = function(info) return p.showused end,
						set = function(info, value)
							p.showused = value
							Baggins:UpdateText()
						end,
					},
					ShowTotal = {
						name = "Show Total bag slots3",
						type = "toggle",
						order = 30,
						desc = "Show Total bag slots",
						get = function(info) return p.showtotal end,
						set = function(info, value)
							p.showtotal = value
							Baggins:UpdateText()
						end,
					},
					Combine = {
						name = "Combine Counts3",
						type = "toggle",
						order = 40,
						desc = "Show only one count with all the seclected types included",
						get = function(info) return p.combinecounts end,
						set = function(info, value)
							p.combinecounts = value
							Baggins:UpdateText()
						end,
					},
					spacer = {
						type = 'header',
						order = 45,
						name = '',
					},
					ShowAmmo = {
						name = "Show Ammo Bags Count3",
						type = "toggle",
						order = 50,
						desc = "Show Ammo Bags Count",
						get = function(info) return p.showammocount end,
						set = function(info, value)
							p.showammocount = value
							Baggins:UpdateText()
						end,
					},
					ShowSoul = {
						name = "Show Soul Bags Count3",
						type = "toggle",
						order = 55,
						desc = "Show Soul Bags Count",
						get = function(info) return p.showsoulcount end,
						set = function(info, value)
							p.showsoulcount = value
							Baggins:UpdateText()
						end,
					},
					ShowSpecialty = {
						name = "Show Specialty Bags Count3",
						type = "toggle",
						order = 60,
						desc = "Show Specialty (profession etc) Bags Count",
						get = function(info) return p.showspecialcount end,
						set = function(info, value)
							p.showspecialcount = value
							Baggins:UpdateText()
						end,
					},
				},
			},
				},
			},
				},
			},
			
			spacer = {
				type = 'header',
				order = 150,
				dialogHidden=true,
				name = '',
			},
			Skin = {
				name = "Bag Skin",
				type = "select",
				desc = "Select bag skin",
				order = 160,
				get = function(info) return p.skin end,
				set = 'ApplySkin',
				values = {}
				--validate = Baggins:GetSkinList()
			},
			HideDefaultBank = {
				name = "Hide Default Bank",
				type = "toggle",
				desc = "Hide the default bank window.",
				order = 170,
				get = function(info) return p.hidedefaultbank end,
				set = function(info, value) p.hidedefaultbank = value end,
			},
			OverrideBags = {
				name = "Override Default Bags",
				type = "toggle",
				desc = "Baggins will open instead of the default bags",
				order = 180,
				get = function(info) return p.overridedefaultbags end,
				set = function(info, value) p.overridedefaultbags = value Baggins:UpdateBagHooks() end,
			},
		
		},
		plugins = {
			Profiles = {
				LoadProfile = {
					name = "Load Profile",
					type = "group",
					desc = "Load a built-in profile: NOTE: ALL Custom Bags will be lost and any edited built in categories will be lost.",
					order = 20,
					args = {
						Default = {
							name = "Default",
							type = "execute",
							desc = "A default set of bags sorting your inventory into categories",
							func = function(info) Baggins:ApplyProfile(Baggins.profiles.default)	end,
							order = 10,
						},
						AllInOne = {
							name = "All in one",
							type = "execute",
							desc = "A single bag containing your whole inventory, sorted by quality",
							func = function(info) Baggins:ApplyProfile(Baggins.profiles.allinone)	end,
							order = 15,
						},
						AllInOneSorted = {
							name = "All In One Sorted",
							type = "execute",
							desc = "A single bag containing your whole inventory, sorted into categories",
							func = function(info) Baggins:ApplyProfile(Baggins.profiles.allinonesorted) end,
							order = 20,
						},
						UserDefined = {
							name = "User Defined",
							type = "group",
							desc = "Load a User Defined Profile",
							inline = true,
							order = 30,
							func = function(info, name) local p = Baggins.db.account.profiles[name] if p then Baggins:ApplyProfile(p) end end,
							args = {
								test = {
									type = 'execute',
									name = 'Test',
								},	
							},
						},
					},
				},
				SaveProfile = {
					name = "Save Profile",
					type = "group",
					desc = "Save a User Defined Profile",
					order = 30,
					func = function(info, name) Baggins:SaveProfile(name) end,
					set = function(info, key, name) Baggins:SaveProfile(name) end,
					get = false,
					args = {
						New = {
							type = "input",
							name = "New",
							desc = "Create a new Profile",
							usage = "<Name>",
							get = false,
							order = 1
						},
					},
				},
				DeleteProfile = {
					name = "Delete Profile",
					type = "group",
					desc = "Delete a User Defined Profile",
					order = 40,
					func = function(info, name) Baggins:SaveProfile(name) end,
					confirm = true,
					func = function(info, name) Baggins.db.account.profiles[name] = nil Baggins:RefreshProfileOptions() end,
					args = {
					},
				},
			}
		}
	}
	
function BagginsConfigTest()
	p = Baggins.db.profile
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("Baggins", BagginsAce3Opts)
	LibStub("AceConfigDialog-3.0"):Open("Baggins")
end
--TestFrame()


do
	local Type = "DragTarget"
	
	local function Aquire(self)

	end
	
	local function Release(self)
		self.frame:ClearAllPoints()
		self.frame:Hide()
	end
	

	local function SetLabel(self, text)
		self.text:SetText(text)
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
			PickupMacro(strsub(self.value,3))
		end
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
			local name, texture = GetMacroInfo(strsub(self.value,3))
			return texture
		end
		return "Interface\\Icons\\INV_Misc_QuestionMark"
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
			return "m:"..GetMacroInfo(Info1)
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
		if text:find("item:%d+") then
			self.objType = "item"
			self.value = text
		elseif strsub(text,1,2) == "m:" then
			self.objType = "macro"
			self.value = text
		elseif text ~= "" then
			self.objType = "spell"
			self.value = text
		end
		self.linkIcon:SetTexture(DragLinkGetTexture(self))
	end
	
	local function SetDisabled(self, disabled)
	
	end
	
	local function Constructor()
		local frame = CreateFrame("Button",nil,UIParent)
		local self = {}
		self.type = Type
		

		self.Release = Release
		self.Aquire = Aquire
		self.SetLabel = SetLabel
		self.SetText = SetText
		self.SetDisabled = SetDisabled
		self.UpdateValue = UpdateValue
		
		self.frame = frame
		frame.obj = self

		local text = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		self.text = text
	
		frame:SetScript("OnDragStart", DragLinkOnDragStart)
		frame:SetScript("OnReceiveDrag", DragLinkOnReceiveDrag)
		frame:SetScript("OnClick", DragLinkOnReceiveDrag)
		frame:SetScript("OnEnter", DragLinkOnEnter)
		frame:SetScript("OnLeave", DragLinkOnLeave)
	
		frame:EnableMouse()
		frame:RegisterForDrag("LeftButton")
		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	
		local linkIcon = frame:CreateTexture(nil, "OVERLAY")
		linkIcon:SetWidth(self.iconWidth or WaterfallDragLink.defaultIconSize)
		linkIcon:SetHeight(self.iconHeight or WaterfallDragLink.defaultIconSize)
		linkIcon:SetPoint("LEFT",frame,"LEFT",0,0)
		linkIcon:SetTexture(DragLinkGetTexture(self))
		linkIcon:SetTexCoord(0,1,0,1)
		linkIcon:Show()
		self.linkIcon = linkIcon
	
		text:SetJustifyH("LEFT")
		text:SetTextColor(1,1,1)
	
		frame:SetHeight(36)
		frame:SetWidth(200)
	
		text:SetHeight(36)
		text:SetPoint("LEFT",check,"RIGHT",0,0)

		--Container Support
		--local content = CreateFrame("Frame",nil,frame)
		--self.content = content
		
		--AceGUI:RegisterAsContainer(self)
		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor)
	
end


