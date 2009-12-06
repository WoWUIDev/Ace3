
dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../AceGUI-3.0/AceGUI-3.0.lua")

local AceGUI = LibStub("AceGUI-3.0")

-- create dummy widget
do
	local Type = "Example"
	
	local function Acquire(self)

	end
	
	local function Release(self)

	end
	

	local function Constructor()
		local frame = CreateFrame("Frame",nil,UIParent)
		local self = {}
		self.type = Type

		self.Release = Release
		self.Acquire = Acquire
		
		self.frame = frame
		frame.obj = self

		AceGUI:RegisterAsWidget(self)
		return self
	end
	
	AceGUI:RegisterWidgetType(Type,Constructor, 1)
end

local widget1 = AceGUI:Create("Example")
AceGUI:Release(widget1)

LibStub.minors["AceGUI-3.0"] = 29

dofile("../AceGUI-3.0/AceGUI-3.0.lua")

local widget2 = AceGUI:Create("Example")

assert(widget1 == widget2)

print("OK")
