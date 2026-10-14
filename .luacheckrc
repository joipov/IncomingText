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
	"CombatTextDB",
	"CombatText_OnAddonCompartmentClick",
	"CombatText_OnAddonCompartmentEnter",
	"CombatText_OnAddonCompartmentLeave",
	"SLASH_CT1",
	"SLASH_CT2",
	SlashCmdList = { fields = { "CT" } },
}

-- WoW globals this addon reads. Anything else is an error.
read_globals = {
	"issecretvalue",
	"canaccessvalue",

	"C_AddOns",
	"C_Spell",
	"C_Timer",
	"LibStub",
	"bit",

	"CreateFrame",
	"GetTime",
	"UnitIsUnit",
	"GetInventoryItemTexture",
	"Enum",

	"GameTooltip",
	"GetCursorPosition",
	"Minimap",
	"UIParent",

	"Settings",
	"ColorPickerFrame",
	"CreateSettingsButtonInitializer",
	"MinimalSliderWithSteppersMixin",

	"print",
}
