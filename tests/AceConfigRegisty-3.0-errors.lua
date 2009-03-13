dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
local MAJOR="AceConfigRegistry-3.0"
dofile("../AceConfig-3.0/"..MAJOR.."/"..MAJOR..".lua")

local creg = assert(LibStub(MAJOR))

local errpattern = "^"..string.gsub(MAJOR,"-","%%-")..":ValidateOptionsTable"

---------------- the option table!!

local opts = {
	type = "group",
	get = function(info) return true end,
	set = function(info,v) end,
	validate = function() return end,
	
	args = {
		input = {
			type="input",
			name="Input",
		},
		toggle = {
			type="toggle",
			name="Toggle",
		},
		grp = {
			type="group",
			name="Grp",
			args = {
				toggle = {
					type="toggle",
					name="Toggle",
				}
			}
		},
		select = {
			type="select",
			name="Select",
			desc="Styled!",
			style="dropdown",
			values={},
		}
	},
	
	plugins = {	-- test plugins
		plugin1 = {
			plugcmd = {
				name="PluggedCmd",
				type="toggle",
			},
			plugcmd2 = {
				name="PluggedCmd2",
				type="toggle",
			}
		},
	}
}

creg:RegisterOptionsTable("testapp", opts)

assert(creg:GetOptionsTable("testapp","cmd","foo-1") == opts)

-- This should not error
creg:ValidateOptionsTable(opts,"mytable")

-----------------------------------------------------------------------
-- Smack various things to pieces and make sure we get a validation error
-- Make sure that errors are indicated on the right callstack offset!

local function test(pattern)
	local ok,msg=pcall(creg.ValidateOptionsTable, creg, opts,"mytable")
	assert(not ok, "Wtf, this didnt error?")
	assert(string.match(msg, errpattern), "<"..msg.."> did not match <"..errpattern..">")	-- error should point at the pcall == no location info
	assert(string.match(msg,pattern), "<"..msg.."> did not match <"..pattern..">")
end

opts.type=nil
test("mytable.type")
opts.type="group"

opts.plugins.plugin1["bad\tkey"]=true
test("mytable.plugins.plugin1.*contained control characters")
opts.plugins.plugin1["bad\tkey"]=nil

opts.plugins.mybad = "hi"
test("mytable.plugins.mybad.*expected a table")
opts.plugins.mybad = nil

opts.plugins.plugin1.plugcmd.type="barf"
test("unknown type")
opts.plugins.plugin1.plugcmd.type="toggle"

opts.args.select.style="hi2u"
test("select.style.*expect string value 'hi2u'")
opts.args.select.style="radio"
assert(pcall(creg.ValidateOptionsTable, creg, opts,"mytable"))
opts.args.select.style=nil
assert(pcall(creg.ValidateOptionsTable, creg, opts,"mytable"))

opts.args.select.values=nil
test("select.values.*expected a methodname, funcref or table")
opts.args.select.values={}


-----------------------------------------------------------------------
-- Make sure we get correct error message levels via other apis also

opts.hateme=true
local pattern="testapp.hateme.*unknown param"

local ok,msg=pcall(creg.GetOptionsTable,creg,"testapp","dropdown","foo-1")
assert(not ok)
assert(string.match(msg, errpattern), "<"..msg.."> did not match <"..errpattern..">")	-- error should point at the pcall == no location info
assert(string.match(msg,pattern), "<"..msg.."> did not match <"..pattern..">")

local ok,msg=pcall(creg:GetOptionsTable("testapp"),"dropdown","foo-1")
assert(not ok)
assert(string.match(msg, errpattern), "<"..msg.."> did not match <"..errpattern..">")	-- error should point at the pcall == no location info
assert(string.match(msg,pattern), "<"..msg.."> did not match <"..pattern..">")





-----------------------------------------------------------------------
print "OK"