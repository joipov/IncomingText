local _, ns = ...

-- Settings panel. Subcategories keep a tall page usable. Rows are registered
-- from Blizzard's delegate so the settings search stays secure.

local Settings = Settings
local ColorPickerFrame = ColorPickerFrame
local CreateSettingsButtonInitializer = CreateSettingsButtonInitializer

local ALIGNS = {
	{ "LEFT", "Left" },
	{ "RIGHT", "Right" },
}
local GROWS = {
	{ "DOWN", "Down" },
	{ "UP", "Up" },
}
local COLOR_ROWS = {
	{ "physical", "Physical hits", "Normal melee hits." },
	{ "crit", "Critical hits", "A critical hit uses this color instead of the school or heal color." },
	{ "holy", "Holy", "Holy damage." },
	{ "fire", "Fire", "Fire damage." },
	{ "nature", "Nature", "Nature damage." },
	{ "frost", "Frost", "Frost damage." },
	{ "shadow", "Shadow", "Shadow damage." },
	{ "arcane", "Arcane", "Arcane damage." },
	{ "heal", "Healing", "Healing that is not a critical hit." },
	{ "miss", "Misses", "Miss, dodge, parry, block, and similar lines." },
	{ "interrupt", "Interrupts", "A cast that dies on your target." },
}

local function Clamp(value, lo, hi, fallback)
	value = tonumber(value)
	if not value then
		return fallback
	end
	if value < lo then
		return lo
	elseif value > hi then
		return hi
	end
	return value
end

local function Clamp01(value, fallback)
	value = tonumber(value)
	if not value then
		return fallback
	end
	if value < 0 then
		return 0
	elseif value > 1 then
		return 1
	end
	return value
end

-- One check for the addon and, on a list page, that list. The settings
-- search stays secure because the row is registered, not added by hand.
local function Gate(initializer, sectionKey, sectionVar)
	initializer:AddModifyPredicate(function()
		if not ns.db or not ns.db.enabled then
			return false
		end
		if sectionKey and not ns.db[sectionKey] then
			return false
		end
		return true
	end)
	initializer:AddEvaluateStateCVar("CT_ENABLED")
	if sectionVar then
		initializer:AddEvaluateStateCVar(sectionVar)
	end
end

-- Shorten needs a name in the order. Icon switches need an icon in the order.
local function GatePiece(initializer, piece)
	initializer:AddModifyPredicate(function()
		if not ns.db or not ns.db.enabled or not ns.db.outEnabled then
			return false
		end
		if piece and not ns.OrderHas(ns.db.lineOrder, piece) then
			return false
		end
		return true
	end)
	initializer:AddEvaluateStateCVar("CT_ENABLED")
	initializer:AddEvaluateStateCVar("CT_OUT_ENABLED")
	initializer:AddEvaluateStateCVar("CT_LINE_ORDER")
end

function ns.OpenSettings()
	if not ns.settingsCategory then
		ns.InitOptions()
	end
	if not ns.settingsCategory then
		ns.Print("Couldn't open settings.")
		return
	end
	Settings.OpenToCategory(ns.settingsCategory:GetID())
end

function ns.InitOptions()
	if ns.settingsCategory then
		return
	end
	local category = Settings.RegisterVerticalLayoutCategory("Combat Text")
	ns.settingsCategory = category
	local general = Settings.RegisterVerticalLayoutSubcategory(category, "General")
	local incoming = Settings.RegisterVerticalLayoutSubcategory(category, "Incoming")
	local outgoing = Settings.RegisterVerticalLayoutSubcategory(category, "Outgoing")
	local colors = Settings.RegisterVerticalLayoutSubcategory(category, "Colors")

	local function AddCheckbox(page, var, key, label, tooltip, onChanged, gated, sectionKey, sectionVar)
		local setting = Settings.RegisterAddOnSetting(
			page,
			var,
			key,
			ns.db,
			Settings.VarType.Boolean,
			label,
			ns.defaults[key]
		)
		if onChanged then
			setting:SetValueChangedCallback(onChanged)
		end
		local initializer = Settings.CreateCheckboxInitializer(setting, nil, tooltip)
		if gated then
			Gate(initializer, sectionKey, sectionVar)
		end
		Settings.RegisterInitializer(page, initializer)
		return setting
	end

	local function AddSlider(page, var, key, label, tooltip, lo, hi, step, which, sectionKey, sectionVar)
		local setting = Settings.RegisterAddOnSetting(
			page,
			var,
			key,
			ns.db,
			Settings.VarType.Number,
			label,
			ns.defaults[key]
		)
		setting:SetValueChangedCallback(function()
			ns.db[key] = math.floor(Clamp(ns.db[key], lo, hi, ns.defaults[key]) + 0.5)
			ns.RefreshList(which)
		end)
		local options = Settings.CreateSliderOptions(lo, hi, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return string.format("%.0f", value)
		end)
		local initializer = Settings.CreateSliderInitializer(setting, options, tooltip)
		Gate(initializer, sectionKey, sectionVar)
		Settings.RegisterInitializer(page, initializer)
	end

	local function AddDropdown(page, var, key, label, tooltip, choices, which, sectionKey, sectionVar, onChanged)
		local setting = Settings.RegisterAddOnSetting(
			page,
			var,
			key,
			ns.db,
			Settings.VarType.String,
			label,
			ns.defaults[key]
		)
		setting:SetValueChangedCallback(function()
			if which then
				ns.RefreshList(which)
			end
			if onChanged then
				onChanged()
			end
		end)
		local initializer = Settings.CreateDropdownInitializer(setting, function()
			local rows = choices
			if type(choices) == "function" then
				rows = choices()
			end
			local container = Settings.CreateControlTextContainer()
			for i = 1, #rows do
				container:Add(rows[i][1], rows[i][2])
			end
			return container:GetData()
		end, tooltip)
		Gate(initializer, sectionKey, sectionVar)
		Settings.RegisterInitializer(page, initializer)
	end

	local function AddColor(key, label, tooltip)
		local function SetColor(r, g, b)
			local row = ns.db.colors and ns.db.colors[key]
			if type(row) ~= "table" then
				row = {}
				ns.db.colors[key] = row
			end
			row.r = Clamp01(r, 1)
			row.g = Clamp01(g, 1)
			row.b = Clamp01(b, 1)
			ns.RefreshList()
		end
		local function Open()
			local row = ns.db.colors and ns.db.colors[key]
			local r = row and row.r or 1
			local g = row and row.g or 1
			local b = row and row.b or 1
			ColorPickerFrame:SetupColorPickerAndShow({
				r = r,
				g = g,
				b = b,
				hasOpacity = false,
				swatchFunc = function()
					SetColor(ColorPickerFrame:GetColorRGB())
				end,
				cancelFunc = function()
					SetColor(r, g, b)
				end,
			})
		end
		local initializer = CreateSettingsButtonInitializer(label, "Choose color", Open, tooltip, true)
		Gate(initializer)
		Settings.RegisterInitializer(colors, initializer)
	end

	local function OpenButton(name, page)
		Settings.RegisterInitializer(
			category,
			CreateSettingsButtonInitializer(name, "Open", function()
				Settings.OpenToCategory(page:GetID())
			end, nil, false)
		)
	end

	local function OnDisplay()
		ns.ApplyWatching()
	end

	AddCheckbox(general, "CT_ENABLED", "enabled", "Enable Combat Text", "Incoming and outgoing damage and healing, in two lists.", function()
		ns.ApplyWatching()
	end, false)
	AddCheckbox(general, "CT_SHOW_MINIMAP", "showMinimapButton", "Minimap button", "Button on the minimap. Opens settings.", function()
		ns.UpdateMinimapButton()
	end, false)
	ns.lockSetting = AddCheckbox(general, "CT_LOCK", "lockPosition", "Lock position", "Drag either list while this is off. Right-click a list to lock it.", function()
		ns.ApplyLock()
	end, true)

	AddCheckbox(incoming, "CT_IN_ENABLED", "inEnabled", "Show incoming", "Hits on you. Off hides this list.", OnDisplay, true)
	AddSlider(incoming, "CT_IN_FONT_SIZE", "inFontSize", "Font size", "Size of a normal line.", 10, 32, 1, "in", "inEnabled", "CT_IN_ENABLED")
	AddSlider(incoming, "CT_IN_CRIT_SIZE", "inCritSize", "Crit size", "Size of a critical hit.", 10, 48, 1, "in", "inEnabled", "CT_IN_ENABLED")
	AddSlider(incoming, "CT_IN_OPACITY", "inOpacity", "Opacity", "How solid this list's text and icons are. They fade out from this level.", 10, 100, 1, "in", "inEnabled", "CT_IN_ENABLED")
	AddDropdown(incoming, "CT_IN_FONT", "inFont", "Font", "The face used for this list. Fonts from other addons appear here when the shared media library is installed.", ns.FontChoices, "in", "inEnabled", "CT_IN_ENABLED")
	AddCheckbox(incoming, "CT_INCOMING_DAMAGE", "showIncomingDamage", "Show incoming damage", "Damage you take.", OnDisplay, true, "inEnabled", "CT_IN_ENABLED")
	AddCheckbox(incoming, "CT_INCOMING_HEALING", "showIncomingHealing", "Show incoming healing", "Healing that lands on you.", OnDisplay, true, "inEnabled", "CT_IN_ENABLED")
	AddCheckbox(incoming, "CT_IN_MISSES", "inShowMisses", "Show misses", "Miss, dodge, parry, block, and similar lines on you.", OnDisplay, true, "inEnabled", "CT_IN_ENABLED")
	AddSlider(incoming, "CT_IN_LINES", "inLines", "Lines shown", "How many lines stay on screen.", 4, 24, 1, "in", "inEnabled", "CT_IN_ENABLED")
	AddDropdown(incoming, "CT_IN_ALIGN", "inAlign", "Text align", "Which side the lines sit on.", ALIGNS, "in", "inEnabled", "CT_IN_ENABLED")
	AddDropdown(incoming, "CT_IN_GROW", "inGrow", "Grow", "Down puts the newest line at the top. Up puts it at the bottom.", GROWS, "in", "inEnabled", "CT_IN_ENABLED")

	AddCheckbox(outgoing, "CT_OUT_ENABLED", "outEnabled", "Show outgoing", "Hits on your target. Off hides this list.", OnDisplay, true)
	AddSlider(outgoing, "CT_OUT_FONT_SIZE", "outFontSize", "Font size", "Size of a normal line.", 10, 32, 1, "out", "outEnabled", "CT_OUT_ENABLED")
	AddSlider(outgoing, "CT_OUT_CRIT_SIZE", "outCritSize", "Crit size", "Size of a critical hit.", 10, 48, 1, "out", "outEnabled", "CT_OUT_ENABLED")
	AddSlider(outgoing, "CT_OUT_OPACITY", "outOpacity", "Opacity", "How solid this list's text and icons are. They fade out from this level.", 10, 100, 1, "out", "outEnabled", "CT_OUT_ENABLED")
	AddDropdown(outgoing, "CT_OUT_FONT", "outFont", "Font", "The face used for this list. Fonts from other addons appear here when the shared media library is installed.", ns.FontChoices, "out", "outEnabled", "CT_OUT_ENABLED")
	AddCheckbox(outgoing, "CT_OUTGOING_DAMAGE", "showOutgoingDamage", "Show outgoing damage", "Damage your target takes. In a group this includes other players.", OnDisplay, true, "outEnabled", "CT_OUT_ENABLED")
	AddCheckbox(outgoing, "CT_OUTGOING_HEALING", "showOutgoingHealing", "Show outgoing healing", "Healing that lands on your target.", OnDisplay, true, "outEnabled", "CT_OUT_ENABLED")
	AddCheckbox(outgoing, "CT_OUT_MISSES", "outShowMisses", "Show misses", "Miss, dodge, parry, block, and similar lines on your target.", OnDisplay, true, "outEnabled", "CT_OUT_ENABLED")
	AddDropdown(outgoing, "CT_LINE_ORDER", "lineOrder", "Line order", "The order of the icon, the number, and the spell name. A missing piece is skipped.", ns.LINE_ORDERS, nil, "outEnabled", "CT_OUT_ENABLED", OnDisplay)

	local function AddPieceCheckbox(var, key, label, tooltip, piece, onChanged)
		local setting = Settings.RegisterAddOnSetting(
			outgoing,
			var,
			key,
			ns.db,
			Settings.VarType.Boolean,
			label,
			ns.defaults[key]
		)
		if onChanged then
			setting:SetValueChangedCallback(onChanged)
		end
		local initializer = Settings.CreateCheckboxInitializer(setting, nil, tooltip)
		GatePiece(initializer, piece)
		Settings.RegisterInitializer(outgoing, initializer)
	end

	AddPieceCheckbox("CT_SHORT_SPELL_NAMES", "shortSpellNames", "Shorten spell names", "Initials of the spell. Sinister Strike becomes SS.", "name", nil)
	AddPieceCheckbox("CT_ICON_NORMAL", "iconNormal", "Icons on normal hits", "Shows the spell icon on a hit that is not a critical hit.", "icon", OnDisplay)
	AddPieceCheckbox("CT_ICON_CRITS", "iconCrits", "Icons on crits", "Shows the spell icon on a critical hit.", "icon", OnDisplay)
	AddPieceCheckbox("CT_ICON_WHITE", "iconWhite", "Icons on white hits", "A white hit uses the weapon that just swung: sword, axe, wand, bow, and so on.", "icon", OnDisplay)
	AddSlider(outgoing, "CT_OUT_LINES", "outLines", "Lines shown", "How many lines stay on screen.", 4, 24, 1, "out", "outEnabled", "CT_OUT_ENABLED")
	AddDropdown(outgoing, "CT_OUT_ALIGN", "outAlign", "Text align", "Which side the lines sit on.", ALIGNS, "out", "outEnabled", "CT_OUT_ENABLED")
	AddDropdown(outgoing, "CT_OUT_GROW", "outGrow", "Grow", "Down puts the newest line at the top. Up puts it at the bottom.", GROWS, "out", "outEnabled", "CT_OUT_ENABLED")

	for i = 1, #COLOR_ROWS do
		local row = COLOR_ROWS[i]
		AddColor(row[1], row[2], row[3])
	end

	OpenButton("General", general)
	OpenButton("Incoming", incoming)
	OpenButton("Outgoing", outgoing)
	OpenButton("Colors", colors)

	Settings.RegisterAddOnCategory(category)
end

-- Addon compartment, named by the TOC.
function _G.CombatText_OnAddonCompartmentClick()
	ns.OpenSettings()
end

function _G.CombatText_OnAddonCompartmentEnter(_, menuButton)
	GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
	GameTooltip:AddLine("Combat Text")
	GameTooltip:AddLine("Click for settings.", 1, 1, 1)
	GameTooltip:Show()
end

function _G.CombatText_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

local function SlashCommand(msg)
	msg = (msg and msg:match("^%s*(.-)%s*$") or ""):lower()
	if msg == "test" then
		ns.ShowTest()
		return
	end
	if msg == "help" then
		ns.Print("Type /ct to open settings. /ct test shows sample lines.")
		return
	end
	ns.OpenSettings()
end

_G.SLASH_CT1 = "/ct"
_G.SLASH_CT2 = "/combattext"
_G.SlashCmdList.CT = SlashCommand
