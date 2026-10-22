-- AceTab-3.0: Tab completion in a chat edit box, driven through AceTab:OnTabPressed on a
-- fake edit box.
--
-- Upgrade: a set registered before a newer copy of the library loads still completes after
-- it. AceTab-3.0 minor 11 and earlier lose it: the upgrade starts the tables that sort sets
-- into fallback and non-fallback empty, so OnTabPressed never looks at the set again.

dofile("wow_api.lua")
dofile("LibStub.lua")

local MAJOR = "AceTab-3.0"

-- game names that wow_api.lua leaves out: what AceTab reads from the chat frames, and the
-- tinsert its own dump() calls
NUM_CHAT_WINDOWS = NUM_CHAT_WINDOWS or 1
ChatEdit_GetActiveWindow = function() return nil end
tinsert = tinsert or table.insert

dofile("../"..MAJOR.."/"..MAJOR..".lua")

local AceTab = assert(LibStub(MAJOR))

-- the chat lines AceTab prints, kept instead of printed
local printed = {}
DEFAULT_CHAT_FRAME.AddMessage = function(self, text) printed[#printed + 1] = text end

-- a chat edit box: its text, the cursor, one selection; Insert replaces the selection
local function NewBox()
	local box = { [0] = newproxy(), text = "", cursor = 0, scripts = {} }
	function box:IsObjectType() return true end
	function box:GetObjectType() return "EditBox" end
	function box:GetName() return "AceTabTestEditBox" end
	function box:GetScript(name) return self.scripts[name] end
	function box:SetScript(name, func) self.scripts[name] = func end
	function box:GetText() return self.text end
	function box:GetCursorPosition() return self.cursor end
	function box:HighlightText(from, to) self.selection = { from, to } end
	function box:Insert(text)
		local from, to = self.cursor, self.cursor
		if self.selection then from, to = self.selection[1], self.selection[2] end
		self.text = self.text:sub(1, from) .. text .. self.text:sub(to + 1)
		self.cursor, self.selection = from + #text, nil
	end
	function box:Type(text) self.text, self.cursor, self.selection = text, #text, nil end
	function box:Tab() self.scripts.OnTabPressed(self) end
	return box
end


-----------------------------------------------------------------------
-- Upgrade: register, load the library again as a newer copy would, and the set still completes

do
	local box = NewBox()
	AceTab:RegisterTabCompletion("early", "/early ", { "a1", "a2" }, nil, box)
	LibStub.minors[MAJOR] = LibStub.minors[MAJOR] - 1 -- so the same file loads as an upgrade
	dofile("../"..MAJOR.."/"..MAJOR..".lua")
	assert(LibStub(MAJOR) == AceTab)
	box:Type("/early a")
	printed = {}
	box:Tab() -- two matches: prints them
	local listed = false
	for _, line in ipairs(printed) do
		if line == "early:" then listed = true end
	end
	assert(listed, dump("the set registered before the upgrade printed nothing"))
	box:Tab()
	assert(box.text == "/early a1" or box.text == "/early a2", dump(box.text))
end


-----------------------------------------------------------------------

print "OK"
