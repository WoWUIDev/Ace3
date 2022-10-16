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
	"table", "string",

	"LibStub",

	-- WoW API
	"Ambiguate",
	"C_ChatInfo",
	"C_Timer",
	"ClearCursor",
	"CreateFont",
	"CreateFrame",
	"GetBuildInfo",
	"GetContainerItemLink",
	"GetCurrentRegion",
	"GetCursorInfo",
	"GetCVar",
	"GetFramerate",
	"GetInventoryItemLink",
	"GetLocale",
	"GetLootSlotLink",
	"GetMacroInfo",
	"GetMerchantItemLink",
	"GetQuestItemLink",
	"GetQuestLogItemLink",
	"GetRealmName",
	"GetSpellName",
	"GetSpellInfo",
	"GetTime",
	"HookScript",
	"hooksecurefunc",
	"issecurevariable",
	"IsAltKeyDown",
	"IsControlKeyDown",
	"IsLoggedIn",
	"IsSpellPassive",
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
	"EditBoxGetCursorPosition",
	"EditBoxSetCursorPosition",
	"EditBox_OnFocusLost",
	"InterfaceOptions_AddCategory",
	"IsSecureCmd",
	"PanelTemplates_TabResize",
	"PanelTemplates_SetDisabledTabState",
	"PanelTemplates_SelectTab",
	"PanelTemplates_DeselectTab",
	"SetDesaturation",
	"Settings",
	"SpellBook_GetSpellID",

	-- FrameXML Frames & Constants
	"ACCEPT",
	"CANCEL",
	"BackdropTemplateMixin",
	"BANK_CONTAINER",
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
	"KEYRING_CONTAINER",
	"MAX_SPELLS",
	"MerchantFrame",
	"NORMAL_FONT_COLOR",
	"NORMAL_FONT_COLOR_CODE",
	"NOT_BOUND",
	"NUM_CHAT_WINDOWS",
	"OKAY",
	"OpacitySliderFrame",
	"SELECTED_CHAT_FRAME",
	"SpellBookFrame",
	"UIParent",

	-- Custom Globals
	"GAME_LOCALE",

	-- Events Compatibility
	"arg1",
	"arg2",
	"arg3",
	"arg4",
	"arg5",
	"arg6",
	"arg7",
	"arg8",
	"arg9",
	"event",
	"this",
	"self",

	-- Lua API Compatibility
	"math.mod",
}
