--[[
AceConfigRegistry-3.0:

Handle central registration of options tables in use by addons and modules. Do nothing else.

Options tables can be registered as raw tables, or as function refs that return a table.
These functions receive two arguments: "uiType" and "uiName". 
- Valid "uiTypes": "cmd", "dropdown", "dialog". This is verified by the library at call time.
- The "uiName" field is expected to contain the full name of the calling addon, including version, e.g. "FooBar-1.0". This is verified by the library at call time.

:IterateOptionsTables() and :GetOptionsTable() always return a function reference that the requesting config handling addon must call with the above arguments.
]]

local MAJOR, MINOR = "AceConfigRegistry-3.0", 6
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

lib.tables = lib.tables or {}

local CallbackHandler = LibStub:GetLibrary("CallbackHandler-1.0")

if not lib.callbacks then
	lib.callbacks = CallbackHandler:New(lib)
end

-----------------------------------------------------------------------
-- Validating options table consistency:


lib.validated = {
	-- list of options table names ran through :ValidateOptionsTable automatically. 
	-- CLEARED ON PURPOSE, since newer versions may have newer validators
	cmd = {},
	dropdown = {},
	dialog = {},
}



local function err(msg, errlvl, ...)
	local t = {}
	for i=select("#",...),1,-1 do
		tinsert(t, (select(i, ...)))
	end
	error(MAJOR..":ValidateOptionsTable(): "..table.concat(t,".")..msg, errlvl+2)
end


local isstring={["string"]=true, _="string"}
local isstringfunc={["string"]=true,["function"]=true, _="string or funcref"}
local istable={["table"]=true,   _="table"}
local ismethodtable={["table"]=true,["string"]=true,["function"]=true,   _="methodname, funcref or table"}
local optstring={["nil"]=true,["string"]=true, _="string"}
local optstringfunc={["nil"]=true,["string"]=true,["function"]=true, _="string or funcref"}
local optnumber={["nil"]=true,["number"]=true, _="number"}
local optmethod={["nil"]=true,["string"]=true,["function"]=true, _="methodname or funcref"}
local optmethodfalse={["nil"]=true,["string"]=true,["function"]=true,["boolean"]={[false]=true},  _="methodname, funcref or false"}
local optmethodnumber={["nil"]=true,["string"]=true,["function"]=true,["number"]=true,  _="methodname, funcref or number"}
local optmethodtable={["nil"]=true,["string"]=true,["function"]=true,["table"]=true,  _="methodname, funcref or table"}
local optmethodbool={["nil"]=true,["string"]=true,["function"]=true,["boolean"]=true,  _="methodname, funcref or boolean"}
local opttable={["nil"]=true,["table"]=true,  _="table"}
local optbool={["nil"]=true,["boolean"]=true,  _="boolean"}
local optboolnumber={["nil"]=true,["boolean"]=true,["number"]=true,  _="boolean or number"}

local basekeys={
	type=isstring,
	name=isstringfunc,
	desc=optstringfunc,
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
	icon=optstringfunc,
	iconCoords=optmethodtable,
	handler=opttable,
	get=optmethodfalse,
	set=optmethodfalse,
	func=optmethodfalse,
	arg={["*"]=true},
	width=optstring,
}

local typedkeys={
	header={},
	description={
		image=optstringfunc,
		imageCoords=optmethodtable,
		imageHeight=optnumber,
		imageWidth=optnumber,
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
--		func={
--			["function"]=true,
--			["string"]=true, 
--			_="methodname or funcref"
--		},
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
	},
	tristate={
	},
	range={
		min=optnumber,
		max=optnumber,
		step=optnumber,
		bigStep=optnumber,
		isPercent=optbool,
	},
	select={
		values=ismethodtable,
		style={
			["nil"]=true, 
			["string"]={dropdown=true,radio=true}, 
			_="string: 'dropdown' or 'radio'"
		},
		control=optstring,
		dialogControl=optstring,
		dropdownControl=optstring,
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
		hasAlpha=optbool,
	},
	keybinding={
		-- TODO
	},
}

local function validateKey(k,errlvl,...)
	errlvl=(errlvl or 0)+1
	if type(k)~="string" then
		err("["..tostring(k).."] - key is not a string", errlvl,...)
	end
	if strfind(k, "[%c \127]") then
		err("["..tostring(k).."] - key name contained spaces (or control characters)", errlvl,...)
	end
end

local function validateVal(v, oktypes, errlvl,...)
	errlvl=(errlvl or 0)+1
	local isok=oktypes[type(v)] or oktypes["*"]

	if not isok then
		err(": expected a "..oktypes._..", got '"..tostring(v).."'", errlvl,...)
	end
	if type(isok)=="table" then		-- isok was a table containing specific values to be tested for!
		if not isok[v] then
			err(": did not expect "..type(v).." value '"..tostring(v).."'", errlvl,...)
		end
	end
end

local function validate(options,errlvl,...)
	errlvl=(errlvl or 0)+1
	-- basic consistency
	if type(options)~="table" then
		err(": expected a table, got a "..type(options), errlvl,...)
	end
	if type(options.type)~="string" then
		err(".type: expected a string, got a "..type(options.type), errlvl,...)
	end
	
	-- get type and 'typedkeys' member
	local tk = typedkeys[options.type]
	if not tk then
		err(".type: unknown type '"..options.type.."'", errlvl,...)
	end
	
	-- make sure that all options[] are known parameters
	for k,v in pairs(options) do
		if not (tk[k] or basekeys[k]) then
			err(": unknown parameter", errlvl,tostring(k),...)
		end
	end

	-- verify that required params are there, and that everything is the right type
	for k,oktypes in pairs(basekeys) do
		validateVal(options[k], oktypes, errlvl,k,...)
	end
	for k,oktypes in pairs(tk) do
		validateVal(options[k], oktypes, errlvl,k,...)
	end

	-- extra logic for groups
	if options.type=="group" then
		for k,v in pairs(options.args) do
			validateKey(k,errlvl,"args",...)
			validate(v, errlvl,k,"args",...)
		end
		if options.plugins then
			for plugname,plugin in pairs(options.plugins) do
				if type(plugin)~="table" then
					err(": expected a table, got '"..tostring(plugin).."'", errlvl,tostring(plugname),"plugins",...)
				end
				for k,v in pairs(plugin) do
					validateKey(k,errlvl,tostring(plugname),"plugins",...)
					validate(v, errlvl,k,tostring(plugname),"plugins",...)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- :ValidateOptionsTable(options,name,errlvl)
-- - options - the table
-- - name    - (string) name of table, used in error reports
-- - errlvl  - (optional number) error level offset, default 0
--
-- Validates basic structure and integrity of an options table
-- Does NOT verify that get/set etc actually exist, since they can be defined at any depth

function lib:ValidateOptionsTable(options,name,errlvl)
	errlvl=(errlvl or 0)+1
	name = name or "Optionstable"
	if not options.name then
		options.name=name	-- bit of a hack, the root level doesn't really need a .name :-/
	end
	validate(options,errlvl,name)
end

------------------------------
-- :NotifyChange(appName)
-- - appName - string identifying the addon
--
-- Fires a ConfigTableChange callback for those listening in on it, allowing config GUIs to refresh
------------------------------

function lib:NotifyChange(appName)
	if not lib.tables[appName] then return end
	lib.callbacks:Fire("ConfigTableChange", appName)
end

---------------------------------------------------------------------
-- Registering and retreiving options tables:


-- validateGetterArgs: helper function for :GetOptionsTable (or, rather, the getter functions returned by it)

local function validateGetterArgs(uiType, uiName, errlvl)
	errlvl=(errlvl or 0)+2
	if uiType~="cmd" and uiType~="dropdown" and uiType~="dialog" then
		error(MAJOR..": Requesting options table: 'uiType' - invalid configuration UI type, expected 'cmd', 'dropdown' or 'dialog'", errlvl)
	end
	if not strmatch(uiName, "[A-Za-z]%-[0-9]") then	-- Expecting e.g. "MyLib-1.2"
		error(MAJOR..": Requesting options table: 'uiName' - badly formatted or missing version number. Expected e.g. 'MyLib-1.2'", errlvl)
	end
end


---------------------------------------------------------------------
-- :RegisterOptionsTable(appName, options)
-- - appName - string identifying the addon
-- - options - table or function reference

function lib:RegisterOptionsTable(appName, options)
	if type(options)=="table" then
		if options.type~="group" then	-- quick sanity checker
			error(MAJOR..": RegisterOptionsTable(appName, options): 'options' - missing type='group' member in root group", 2)
		end
		lib.tables[appName] = function(uiType, uiName, errlvl)
			errlvl=(errlvl or 0)+1
			validateGetterArgs(uiType, uiName, errlvl)
			if not lib.validated[uiType][appName] then
				lib:ValidateOptionsTable(options, appName, errlvl)	-- upgradable
				lib.validated[uiType][appName] = true
			end
			return options 
		end
	elseif type(options)=="function" then
		lib.tables[appName] = function(uiType, uiName, errlvl)
			errlvl=(errlvl or 0)+1
			validateGetterArgs(uiType, uiName, errlvl)
			local tab = assert(options(uiType, uiName))
			if not lib.validated[uiType][appName] then
				lib:ValidateOptionsTable(tab, appName, errlvl)	-- upgradable
				lib.validated[uiType][appName] = true
			end
			return tab
		end
	else
		error(MAJOR..": RegisterOptionsTable(appName, options): 'options' - expected table or function reference", 2)
	end
end


---------------------------------------------------------------------
-- :IterateOptionsTables()
--
-- Returns an iterator of ["appName"]=funcref pairs

function lib:IterateOptionsTables()
	return pairs(lib.tables)
end


---------------------------------------------------------------------
-- :GetOptionsTable(appName)
-- - appName - which addon to retreive the options table of
-- Optional:
-- - uiType - "cmd", "dropdown", "dialog"
-- - uiName - e.g. "MyLib-1.0"
--
-- If only appName is given, a function is returned which you
-- can call with (uiType,uiName) to get the table.
-- If uiType&uiName are given, the table is returned.

function lib:GetOptionsTable(appName, uiType, uiName)
	local f = lib.tables[appName]
	if not f then
		return nil
	end
	
	if uiType then
		return f(uiType,uiName,1)	-- get the table for us
	else
		return f	-- return the function
	end
end
