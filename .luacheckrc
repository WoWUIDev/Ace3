std = "lua51"
max_line_length = false
exclude_files = {
	"tests/",
	".luacheckrc"
}

ignore = {
	"11./BINDING_.*", -- Setting an undefined (Keybinding) global variable
	"211", -- Unused local variable
	"212", -- Unused argument
	"213", -- Unused loop variable
	"542", -- empty if branch
}

globals = {
	"Ace3",
	"ChatThrottleLib",

	"AceGUIEditBoxInsertLink",
	"AceGUIMultiLineEditBoxInsertLink",
	"ChatEdit_CustomTabPressed",
	"CloseSpecialWindows",
	"ColorPickerFrame",
	"SlashCmdList", "hash_SlashCmdList",
}

read_globals = {
	"geterrorhandler",
	"securecallfunction",
	"table", "string",

	"LibStub",

	-- WoW API
	"Ambiguate",
	"C_ChatInfo",
	"C_Timer",
	"ClearCursor",
	"CreateFont",
	"CreateFrame",
	"Enum.SendAddonMessageResult",
	"GetCurrentRegion",
	"GetCurrentRegionName",
	"GetCursorInfo",
	"GetFramerate",
	"GetLocale",
	"GetMacroInfo",
	"GetRealmName",
	"GetSpellInfo",
	"GetTime",
	"hooksecurefunc",
	"issecurevariable",
	"IsAltKeyDown",
	"IsControlKeyDown",
	"IsLoggedIn",
	"IsShiftKeyDown",
	"PlaySound",
	"RegisterAddonMessagePrefix",
	"ReloadUI",
	"UnitClass",
	"UnitFactionGroup",
	"UnitInParty",
	"UnitInRaid",
	"UnitName",
	"UnitRace",

	-- FrameXML API
	"ChatEdit_GetActiveWindow",
	"InterfaceOptions_AddCategory",
	"IsSecureCmd",
	"SetDesaturation",
	"Settings",

	-- FrameXML Frames & Constants
	"ACCEPT",
	"CANCEL",
	"ChatFontNormal",
	"CLOSE",
	"DEFAULT_CHAT_FRAME",
	"FONT_COLOR_CODE_CLOSE",
	"GameFontDisableSmall",
	"GameFontHighlight",
	"GameFontHighlightLarge",
	"GameFontHighlightSmall",
	"GameFontNormal",
	"GameFontNormalSmall",
	"GameTooltip",
	"InterfaceOptionsFramePanelContainer",
	"NORMAL_FONT_COLOR",
	"NORMAL_FONT_COLOR_CODE",
	"NOT_BOUND",
	"NUM_CHAT_WINDOWS",
	"OKAY",
	"OpacitySliderFrame",
	"SELECTED_CHAT_FRAME",
	"UIParent",
	"WOW_PROJECT_ID",
	"WOW_PROJECT_MAINLINE",

	-- Custom Globals
	"GAME_LOCALE",
}
