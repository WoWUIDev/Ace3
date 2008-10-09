dofile("wow_api.lua")
dofile("LibStub.lua")
dofile("../CallbackHandler-1.0/CallbackHandler-1.0.lua")
dofile("../AceConsole-3.0/AceConsole-3.0.lua")
dofile("../AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua")
dofile("../AceConfig-3.0/AceConfigCmd-3.0/AceConfigCmd-3.0.lua")

local ccmd = assert(LibStub("AceConfigCmd-3.0"))
local creg = assert(LibStub("AceConfigRegistry-3.0"))


local app={}


---------------- the option table!!

local opts = {
	type = "group",
	get = function() end,
	set = function() end,
	
	args = {
		first = {
			type="toggle",
			name="1",
			order=1
		},
		second = {
			type="toggle",
			name="2",
			order=2
		},
		plugcmd = {	-- this should never be used, we should use the plugin!
			name="PlugCmdOrig",
			desc="YOU SHOULD NOT SEE THIS",
			type="toggle",
		},
		inlinegroup = {
			order=70,
			name="inlinegroup",
			desc="An inline group",
			type="group",
			inline=false,
			cmdInline=true,	-- test that cmdInline overrides inline
			args = {
				inline1 = {
					type="toggle",
					name="inline1",
					order=11,
				},
				inline2 = {
					type="toggle",
					name="inline2",
					order=12,
				},
				ininlinegroup = {
					order=1,
					name="ininlinegroup",
					desc="An inline inline group",
					type="group",
					inline=true,
					args = {
						ininline1 = {
							type="toggle",
							name="ininline1",
						}
					}
				}
			},
		},
		unset1 = {
			type="toggle",
			name="unset1",
		},
		unset2 = {
			type="toggle",
			name="unset2",
		},
		unset3 = {
			type="toggle",
			name="unset3",
		},
		afterunset = {
			type="toggle",
			name="101",
			order=101
		},
		last1 = {
			type="toggle",
			name="-1",
			order=-1,
		},
		last2 = {
			type="toggle",
			name="-2",
			order=-2,
		},
		last3 = {
			type="toggle",
			name="-3",
			order=-3,
		},
		last4 = {
			type="toggle",
			name="-4",
			order=-4,
		},
	},
	
	plugins = {	-- test plugins
		plugin1 = {
			plugcmd = {
				name="50",
				type="toggle",
				order=50
			},
			plugcmd2 = {
				name="52",
				type="toggle",
				order=52
			}
		},
		plugin2 = {
			-- empty, shouldnt cause errors
		},
		plugin3 = {
			p3cmd = {
				name="51",
				type="toggle",
				order=51,
			},
		}
		
	}
}

creg:RegisterOptionsTable("testapp", opts)



local output = {
	"Arguments to", -- header
	"first",
	"second",
	"plugcmd.*50",
	"p3cmd",
	"plugcmd2",
	"An inline group",
	"An inline inline group",
	"ininline1",
	"inline1",
	"inline2",
	"unset1",
	"unset2",
	"unset3",
	"afterunset",
	"last4",
	"last3",
	"last2",
	"last1"
}

function ChatFrame1.AddMessage(self, txt)
	-- print("> "..txt)
	local str = assert(tremove(output, 1))
	assert(string.match(txt, str), "Expected <"..str.."> got <"..txt..">")
end

ccmd:HandleCommand("test","testapp","")

assert(not next(output), "we didnt get all the output we expected!")


-----------------------------------------------------------------------
print "OK"