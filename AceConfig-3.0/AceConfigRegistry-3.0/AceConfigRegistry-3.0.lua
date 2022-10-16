--- AceConfigRegistry-3.0 handles central registration of options tables in use by addons and modules.\\
-- Options tables can be registered as raw tables, OR as function refs that return a table.\\
-- Such functions receive three arguments: "uiType", "uiName", "appName". \\
-- * Valid **uiTypes**: "cmd", "dropdown", "dialog". This is verified by the library at call time. \\
-- * The **uiName** field is expected to contain the full name of the calling addon, including version, e.g. "FooBar-1.0". This is verified by the library at call time.\\
-- * The **appName** field is the options table name as given at registration time \\
--
-- :IterateOptionsTables() (and :GetOptionsTable() if only given one argument) return a function reference that the requesting config handling addon must call with valid "uiType", "uiName".
-- @class file
-- @name AceConfigRegistry-3.0
-- @release $Id$
local CallbackHandler = LibStub("CallbackHandler-1.0")

local MAJOR, MINOR = "AceConfigRegistry-3.0", 20
local AceConfigRegistry = LibStub:NewLibrary(MAJOR, MINOR)

if not AceConfigRegistry then return end

AceConfigRegistry.tables = AceConfigRegistry.tables or {}

if not AceConfigRegistry.callbacks then
	AceConfigRegistry.callbacks = CallbackHandler:New(AceConfigRegistry)
end

-- Lua APIs
local tinsert, tconcat, tgetn = table.insert, table.concat, table.getn
local strfind, unpack = string.find, unpack
local type, tostring, pairs = type, tostring, pairs
local error, assert, loadstring = error, assert, loadstring

local supports_ellipsis = loadstring("return ...") ~= nil
local template_args = supports_ellipsis and "{...}" or "arg"

local function vararg(n, f)
	local t = {}
	local params = ""
	if n > 0 then
		for i = 1, n do t[ i ] = "_"..i end
		params = tconcat(t, ", ", 1, n)
		params = params .. ", "
	end
	local code = [[
        return function( f )
        return function( ]]..params..[[... )
            return f( ]]..params..template_args..[[ )
        end
        end
    ]]
	return assert(loadstring(code, "=(vararg)"))()(f)
end

-----------------------------------------------------------------------
-- Validating options table consistency:


AceConfigRegistry.validated = {
	-- list of options table names ran through :ValidateOptionsTable automatically.
	-- CLEARED ON PURPOSE, since newer versions may have newer validators
	cmd = {},
	dropdown = {},
	dialog = {},
}



local err = vararg(2, function(msg, errlvl, arg)
	local t = {}
	for i=tgetn(arg),1,-1 do
		tinsert(t, arg[i])
	end
	error(MAJOR..":ValidateOptionsTable(): "..tconcat(t,".")..msg, errlvl+2)
end)


local isstring={["string"]=true, _="string"}
local isstringfunc={["string"]=true,["function"]=true, _="string or funcref"}
local istable={["table"]=true,   _="table"}
local ismethodtable={["table"]=true,["string"]=true,["function"]=true,   _="methodname, funcref or table"}
local optstring={["nil"]=true,["string"]=true, _="string"}
local optstringfunc={["nil"]=true,["string"]=true,["function"]=true, _="string or funcref"}
local optstringnumberfunc={["nil"]=true,["string"]=true,["number"]=true,["function"]=true, _="string, number or funcref"}
local optnumber={["nil"]=true,["number"]=true, _="number"}
local optmethodfalse={["nil"]=true,["string"]=true,["function"]=true,["boolean"]={[false]=true},  _="methodname, funcref or false"}
local optmethodnumber={["nil"]=true,["string"]=true,["function"]=true,["number"]=true,  _="methodname, funcref or number"}
local optmethodtable={["nil"]=true,["string"]=true,["function"]=true,["table"]=true,  _="methodname, funcref or table"}
local optmethodbool={["nil"]=true,["string"]=true,["function"]=true,["boolean"]=true,  _="methodname, funcref or boolean"}
local opttable={["nil"]=true,["table"]=true,  _="table"}
local optbool={["nil"]=true,["boolean"]=true,  _="boolean"}
local optboolnumber={["nil"]=true,["boolean"]=true,["number"]=true,  _="boolean or number"}
local optstringnumber={["nil"]=true,["string"]=true,["number"]=true, _="string or number"}

local basekeys={
	type=isstring,
	name=isstringfunc,
	desc=optstringfunc,
	descStyle=optstring,
	order=optmethodnumber,
	validate=optmethodfalse,
	confirm=optmethodbool,
	confirmText=optstring,
	disabled=optmethodbool,
	hidden=optmethodbool,
	guiHidden=optmethodbool,
	dialogHidden=optmethodbool,
	dropdownHidden=optmethodbool,
	cmdHidden=optmethodbool,
	icon=optstringnumberfunc,
	iconCoords=optmethodtable,
	handler=opttable,
	get=optmethodfalse,
	set=optmethodfalse,
	func=optmethodfalse,
	arg={["*"]=true},
	width=optstringnumber,
	-- This key is used by legacy versions of ElvUI --
	buttonElvUI=optmethodbool,
}

local typedkeys={
	header={
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	description={
		image=optstringnumberfunc,
		imageCoords=optmethodtable,
		imageHeight=optnumber,
		imageWidth=optnumber,
		fontSize=optstringfunc,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	group={
		args=istable,
		plugins=opttable,
		inline=optbool,
		cmdInline=optbool,
		guiInline=optbool,
		dropdownInline=optbool,
		dialogInline=optbool,
		childGroups=optstring,
	},
	execute={
		image=optstringnumberfunc,
		imageCoords=optmethodtable,
		imageHeight=optnumber,
		imageWidth=optnumber,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	input={
		pattern=optstring,
		usage=optstring,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
		multiline=optboolnumber,
	},
	toggle={
		tristate=optbool,
		image=optstringnumberfunc,
		imageCoords=optmethodtable,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	tristate={
	},
	range={
		min=optnumber,
		softMin=optnumber,
		max=optnumber,
		softMax=optnumber,
		step=optnumber,
		bigStep=optnumber,
		isPercent=optbool,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	select={
		values=ismethodtable,
		sorting=optmethodtable,
		style={
			["nil"]=true,
			["string"]={dropdown=true,radio=true},
			_="string: 'dropdown' or 'radio'"
		},
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
		itemControl=optstring,
	},
	multiselect={
		values=ismethodtable,
		style=optstring,
		tristate=optbool,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	color={
		hasAlpha=optmethodbool,
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
	keybinding={
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
	},
}

local validateKey = vararg(2, function(k,errlvl,arg)
	errlvl=(errlvl or 0)+1
	if type(k)~="string" then
		err("["..tostring(k).."] - key is not a string", errlvl,unpack(arg))
	end
	if strfind(k, "[%c\127]") then
		err("["..tostring(k).."] - key name contained control characters", errlvl,unpack(arg))
	end
end)

local validateVal = vararg(3, function(v, oktypes, errlvl,arg)
	errlvl=(errlvl or 0)+1
	local isok=oktypes[type(v)] or oktypes["*"]

	if not isok then
		err(": expected a "..oktypes._..", got '"..tostring(v).."'", errlvl,unpack(arg))
	end
	if type(isok)=="table" then		-- isok was a table containing specific values to be tested for!
		if not isok[v] then
			err(": did not expect "..type(v).." value '"..tostring(v).."'", errlvl,unpack(arg))
		end
	end
end)

AceConfigRegistry.validate = vararg(2, function(options,errlvl,arg)
	errlvl=(errlvl or 0)+1
	-- basic consistency
	if type(options)~="table" then
		err(": expected a table, got a "..type(options), errlvl,unpack(arg))
	end
	if type(options.type)~="string" then
		err(".type: expected a string, got a "..type(options.type), errlvl,unpack(arg))
	end

	-- get type and 'typedkeys' member
	local tk = typedkeys[options.type]
	if not tk then
		err(".type: unknown type '"..options.type.."'", errlvl,unpack(arg))
	end

	-- make sure that all options[] are known parameters
	for k,v in pairs(options) do
		if not (tk[k] or basekeys[k]) then
			err(": unknown parameter", errlvl,tostring(k),unpack(arg))
		end
	end

	-- verify that required params are there, and that everything is the right type
	for k,oktypes in pairs(basekeys) do
		validateVal(options[k], oktypes, errlvl,k,unpack(arg))
	end
	for k,oktypes in pairs(tk) do
		validateVal(options[k], oktypes, errlvl,k,unpack(arg))
	end

	-- extra logic for groups
	if options.type=="group" then
		for k,v in pairs(options.args) do
			validateKey(k,errlvl,"args",unpack(arg))
			AceConfigRegistry.validate(v, errlvl,k,"args",unpack(arg))
		end
		if options.plugins then
			for plugname,plugin in pairs(options.plugins) do
				if type(plugin)~="table" then
					err(": expected a table, got '"..tostring(plugin).."'", errlvl,tostring(plugname),"plugins",unpack(arg))
				end
				for k,v in pairs(plugin) do
					validateKey(k,errlvl,tostring(plugname),"plugins",unpack(arg))
					AceConfigRegistry.validate(v, errlvl,k,tostring(plugname),"plugins",unpack(arg))
				end
			end
		end
	end
end)


--- Validates basic structure and integrity of an options table \\
-- Does NOT verify that get/set etc actually exist, since they can be defined at any depth
-- @param options The table to be validated
-- @param name The name of the table to be validated (shown in any error message)
-- @param errlvl (optional number) error level offset, default 0 (=errors point to the function calling :ValidateOptionsTable)
function AceConfigRegistry:ValidateOptionsTable(options,name,errlvl)
	errlvl=(errlvl or 0)+1
	name = name or "Optionstable"
	if not options.name then
		options.name=name	-- bit of a hack, the root level doesn't really need a .name :-/
	end
	AceConfigRegistry.validate(options,errlvl,name)
end

--- Fires a "ConfigTableChange" callback for those listening in on it, allowing config GUIs to refresh.
-- You should call this function if your options table changed from any outside event, like a game event
-- or a timer.
-- @param appName The application name as given to `:RegisterOptionsTable()`
function AceConfigRegistry:NotifyChange(appName)
	if not AceConfigRegistry.tables[appName] then return end
	AceConfigRegistry.callbacks:Fire("ConfigTableChange", appName)
end

-- -------------------------------------------------------------------
-- Registering and retreiving options tables:


-- validateGetterArgs: helper function for :GetOptionsTable (or, rather, the getter functions returned by it)

local function validateGetterArgs(uiType, uiName, errlvl)
	errlvl=(errlvl or 0)+2
	if uiType~="cmd" and uiType~="dropdown" and uiType~="dialog" then
		error(MAJOR..": Requesting options table: 'uiType' - invalid configuration UI type, expected 'cmd', 'dropdown' or 'dialog'", errlvl)
	end
	if not strfind(uiName, "[A-Za-z]+-[0-9]") then	-- Expecting e.g. "MyLib-1.2"
		error(MAJOR..": Requesting options table: 'uiName' - badly formatted or missing version number. Expected e.g. 'MyLib-1.2'", errlvl)
	end
end

--- Register an options table with the config registry.
-- @param appName The application name as given to `:RegisterOptionsTable()`
-- @param options The options table, OR a function reference that generates it on demand. \\
-- See the top of the page for info on arguments passed to such functions.
-- @param skipValidation Skip options table validation (primarily useful for extremely huge options, with a noticeable slowdown)
function AceConfigRegistry:RegisterOptionsTable(appName, options, skipValidation)
	if type(options)=="table" then
		if options.type~="group" then	-- quick sanity checker
			error(MAJOR..": RegisterOptionsTable(appName, options): 'options' - missing type='group' member in root group", 2)
		end
		AceConfigRegistry.tables[appName] = function(uiType, uiName, errlvl)
			errlvl=(errlvl or 0)+1
			validateGetterArgs(uiType, uiName, errlvl)
			if not AceConfigRegistry.validated[uiType][appName] and not skipValidation then
				AceConfigRegistry:ValidateOptionsTable(options, appName, errlvl)	-- upgradable
				AceConfigRegistry.validated[uiType][appName] = true
			end
			return options
		end
	elseif type(options)=="function" then
		AceConfigRegistry.tables[appName] = function(uiType, uiName, errlvl)
			errlvl=(errlvl or 0)+1
			validateGetterArgs(uiType, uiName, errlvl)
			local tab = assert(options(uiType, uiName, appName))
			if not AceConfigRegistry.validated[uiType][appName] and not skipValidation then
				AceConfigRegistry:ValidateOptionsTable(tab, appName, errlvl)	-- upgradable
				AceConfigRegistry.validated[uiType][appName] = true
			end
			return tab
		end
	else
		error(MAJOR..": RegisterOptionsTable(appName, options): 'options' - expected table or function reference", 2)
	end
end

--- Returns an iterator of ["appName"]=funcref pairs
function AceConfigRegistry:IterateOptionsTables()
	return pairs(AceConfigRegistry.tables)
end




--- Query the registry for a specific options table.
-- If only appName is given, a function is returned which you
-- can call with (uiType,uiName) to get the table.\\
-- If uiType&uiName are given, the table is returned.
-- @param appName The application name as given to `:RegisterOptionsTable()`
-- @param uiType The type of UI to get the table for, one of "cmd", "dropdown", "dialog"
-- @param uiName The name of the library/addon querying for the table, e.g. "MyLib-1.0"
function AceConfigRegistry:GetOptionsTable(appName, uiType, uiName)
	local f = AceConfigRegistry.tables[appName]
	if not f then
		return nil
	end

	if uiType then
		return f(uiType,uiName,1)	-- get the table for us
	else
		return f	-- return the function
	end
end
