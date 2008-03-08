dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceConsole-3.0/AceConsole-3.0.lua")
dofile("../AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua")
dofile("../AceConfig-3.0/AceConfigCmd-3.0/AceConfigCmd-3.0.lua")

local ccmd = assert(LibStub("AceConfigCmd-3.0"))
local creg = assert(LibStub("AceConfigRegistry-3.0"))


local app={}

-- helper: counts of what's been execd
local n = setmetatable({}, { __index = function(self,k) return 0 end })
function n:clear()
	for k,v in pairs(self) do
		if k~="clear" then
			self[k]=nil
		end
	end
end


----- set / get on application object

function app:get_toggle(info, ...)
	assert(self==app)
	assert(select("#",...)==0)
	
	n.get_toggle = n.get_toggle + 1
	return true
end

function app:set_toggle(info, ...)
	assert(self==app, "Expected self=="..tostring(app)..", got "..tostring(self))
	assert(select("#",...)==1)
	local b = select(1,...)
	n.set_toggle = n.set_toggle + 1
	assert(b==false)
end


--- set / get / validate as function refs

function makefunc(name)
	_G[name] = function(info,...)
		assert(type(info)=="table")
		assert(#info>=1)
		n[name] = n[name] + 1
		return _G["_"..name](info,...)
	end
end

makefunc("set_base")
makefunc("get_base")
makefunc("validate_base")




---------------- the option table!!

local opts = {
	type = "group",
	get = get_base,	 -- tests inheritance by declaring it at the bottom
	set = set_base,
	validate = validate_base,
	
	args = {
		input = {
			type="input",
			name="Input",
			desc="Input Desc",
			validate = false,		-- tests removing inherited validate
		},
		toggle = {
			type="toggle",
			name="Toggle",
			desc="Toggle Desc",
			handler=app,			-- tests "handler" arg
			get = "get_toggle",	-- tests overriding, and membernames
			set = "set_toggle",
		},
		plugcmd = {	-- this should never be used, we should use the plugin!
			name="PlugCmdOrig",
			desc="YOU SHOULD NOT SEE THIS",
			type="toggle",
			set = function() assert(false) end,
			get = function() assert(false) end,
		}
	},
	
	plugins = {	-- test plugins
		plugin1 = {
			plugcmd = {
				name="PluggedCmd",
				desc="Woohoo",
				type="toggle",
			},
			plugcmd2 = {
				name="PluggedCmd2",
				desc="WooTwo",
				type="toggle",
			}
		},
		plugin2 = {
			-- empty, shouldnt cause errors
		},
		plugin3 = {
			p3cmd = {
				name="Plugin3Cmd",
				desc="WooThree",
				type="toggle",
			},
		}
		
	}
}

creg:RegisterOptionsTable("testapp", opts)

assert(creg:GetOptionsTable("testapp")("cmd","foo-1") == opts)
assert(creg:GetOptionsTable("testapp","cmd","foo-1") == opts)


-- User error handler
local expect = {}	-- list of strings to expect
function ChatFrame1.AddMessage(self, txt)
	local expstr = tremove(expect)
	assert(expstr, "Unexpected output: <"..txt..">")
	assert(string.match(txt,expstr), "Got output <"..txt..">, expected <"..expstr..">")
end



--------------- test "/test toggle"  (via handler:methodname)

function _validate_base() end -- noop

tinsert(expect, "/test toggle : 'thisshoulderror' %- expected 'on' or 'off', or no argument to toggle.")
ccmd:HandleCommand("test","testapp","toggle thisshoulderror") -- shouldn't work
assert(n.get_toggle==0)
assert(n.set_toggle==0)
assert(n.validate_base==0)
assert(table.getn(expect)==0)

n:clear()
ccmd:HandleCommand("test","testapp","toggle off")
assert(n.get_toggle==0)
assert(n.set_toggle==1)
assert(n.validate_base==1)

n:clear()
ccmd:HandleCommand("test","testapp","toggle")
assert(n.get_toggle==1)
assert(n.set_toggle==1)
assert(n.validate_base==1)

function _validate_base(info, ...)
	return "THIS FAILS"
end
n:clear()
tinsert(expect, "/test toggle : 'on' %- THIS FAILS")
ccmd:HandleCommand("test","testapp","toggle on")	-- "on" since it'll error if it reachest the set handler (it only accepts false)
assert(n.get_base==0)
assert(n.set_base==0)
assert(n.validate_base==1)



-------------- test "/test input"  (via funcrefs)

function _set_base(info,...)
	assert(select("#",...)==1)
	assert(#info==1)
	assert(info[0]=="test")
	assert(info[1]=="input")
	local a1 = ...
	assert(a1=="")
end

n:clear()
ccmd:HandleCommand("test","testapp","input")
assert(n.get_base==0)
assert(n.validate_base==0)
assert(n.set_base==1)


function _set_base(info, ...)
	assert(...=="hi2u  woo  ",dump(...))
end
ccmd:HandleCommand("test","testapp","input   hi2u  woo  ")




-----------------------------------------------------------------------

local seen = {
  [".*Arguments to.*"]=0,
  ["input.*Input Desc"]=0,
  ["toggle.*Toggle Desc"]=0,
  ["plugcmd.*Woohoo"]=0,
  ["plugcmd2.*WooTwo"]=0,
  ["p3cmd.*WooThree"]=0,
}
function ChatFrame1.AddMessage(self, txt)
	local ok
	for k,v in pairs(seen) do
		if strmatch(txt, k) then
			seen[k]=seen[k]+1
			ok=true
			break
		end
	end
	assert(ok, "Did not expect to see "..format("%q",txt))
end

ccmd:HandleCommand("test","testapp","")

for k,v in pairs(seen) do
  assert(v==1, "Expected to see <"..k.."> once. Saw it "..v.." times.")
end

-----------------------------------------------------------------------
print "OK"