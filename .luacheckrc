-- Lua 5.1, explicit WoW globals. Same layout in every Joipov addon.
std = "lua51"
max_line_length = false
self = false

exclude_files = {
	".release/",
	".annotations/",
	"assets/",
}

files["tests/"] = {
	std = "lua51",
}

-- Globals this addon writes. It writes them through _G, so luacheck does not
-- require them; the list documents intent and catches accidental renames.
globals = {
	"IncomingTextDB",
	"IncomingText_OnAddonCompartmentClick",
	"IncomingText_OnAddonCompartmentEnter",
	"IncomingText_OnAddonCompartmentLeave",
	"SLASH_INCOMINGTEXT1",
	"SLASH_INCOMINGTEXT2",
	SlashCmdList = { fields = { "INCOMINGTEXT" } },
}

-- WoW globals this addon reads. Anything else is an error.
read_globals = {
	"issecretvalue",
	"canaccessvalue",
	"issecrettable",
	"canaccesstable",

	"C_AddOns",
	"C_Spell",
	"C_Timer",
	"C_TooltipInfo",
	"Enum",
	"LibStub",
	"bit",

	"CreateFrame",
	"GetSpellPowerCost",
	"GetTime",
	"UnitPowerMax",

	"GameTooltip",
	"GetCursorPosition",
	"Minimap",
	"UIParent",

	"Settings",
	"ColorPickerFrame",
	"CreateSettingsButtonInitializer",
	"MinimalSliderWithSteppersMixin",
	"GameFontHighlightSmall",
	"InputBoxTemplate",
	"SettingsListElementTemplate",

	"print",
}
