-- LibStub is a simple versioning stub meant for use in Libraries.  http://www.wowace.com/wiki/LibStub for more info
-- LibStub is hereby placed in the Public Domain Credits: Kaelten, Cladhaire, ckknight, Mikk, Ammo, Nevcairiel, joshborke
local LIBSTUB_MAJOR, LIBSTUB_MINOR = "LibStub", 2  -- NEVER MAKE THIS AN SVN REVISION! IT NEEDS TO BE USABLE IN ALL REPOS!
local _G = getfenv() or _G or {}
local strfind, strfmt = string.find, string.format
local assert, type, error = assert, type, error
local tonumber, tostring = tonumber, tostring
local pairs, setmetatable = pairs, setmetatable
local LibStub = _G[LIBSTUB_MAJOR]

if not LibStub or LibStub.minor < LIBSTUB_MINOR then
	LibStub = LibStub or { libs = {}, minors = {} }
	_G[LIBSTUB_MAJOR] = LibStub
	LibStub.minor = LIBSTUB_MINOR

	function LibStub:NewLibrary(major, minor)
		assert(type(major) == "string", "Bad argument #2 to `NewLibrary' (string expected)")
		local _,_,num = strfind(minor, "(%d+)")
		minor = assert(tonumber(num), "Minor version must either be a number or contain a number.")

		local oldminor = self.minors[major]
		if oldminor and oldminor >= minor then return nil end
		self.minors[major], self.libs[major] = minor, self.libs[major] or {}
		return self.libs[major], oldminor
	end

	function LibStub:GetLibrary(major, silent)
		if not self.libs[major] and not silent then
			error(strfmt("Cannot find a library instance of %q.", tostring(major)), 2)
		end
		return self.libs[major], self.minors[major]
	end

	function LibStub:IterateLibraries() return pairs(self.libs) end
	setmetatable(LibStub, { __call = LibStub.GetLibrary })
end
