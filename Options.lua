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
	{ "physical", "Physical hits", "Physical damage you take." },
	{ "crit", "Critical hits", "A critical hit uses this color instead of the school or heal color." },
	{ "holy", "Holy", "Holy damage you take." },
	{ "fire", "Fire", "Fire damage you take." },
	{ "nature", "Nature", "Nature damage you take." },
	{ "frost", "Frost", "Frost damage you take." },
	{ "shadow", "Shadow", "Shadow damage you take." },
	{ "arcane", "Arcane", "Arcane damage you take." },
	{ "heal", "Healing", "Healing that lands on you and is not a critical hit." },
	{ "miss", "Misses", "Miss, dodge, parry, block, and similar lines." },
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

-- Rows other than the enable switch grey out while the addon is off.
local function Gate(initializer)
	initializer:AddModifyPredicate(function()
		if not ns.db or not ns.db.enabled then
			return false
		end
		return true
	end)
	initializer:AddEvaluateStateCVar("IT_ENABLED")
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
	local category = Settings.RegisterVerticalLayoutCategory("Incoming Text")
	ns.settingsCategory = category
	local general = Settings.RegisterVerticalLayoutSubcategory(category, "General")
	local colors = Settings.RegisterVerticalLayoutSubcategory(category, "Colors")

	local function AddCheckbox(page, var, key, label, tooltip, onChanged, gated)
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
			Gate(initializer)
		end
		Settings.RegisterInitializer(page, initializer)
		return setting
	end

	local function AddSlider(page, var, key, label, tooltip, lo, hi, step)
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
			ns.RefreshList()
		end)
		local options = Settings.CreateSliderOptions(lo, hi, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return string.format("%.0f", value)
		end)
		local initializer = Settings.CreateSliderInitializer(setting, options, tooltip)
		Gate(initializer)
		Settings.RegisterInitializer(page, initializer)
	end

	local function AddDropdown(page, var, key, label, tooltip, choices)
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
			ns.RefreshList()
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
		Gate(initializer)
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

	AddCheckbox(general, "IT_ENABLED", "enabled", "Enable Incoming Text", "Damage, healing, and misses that land on you.", function()
		ns.ApplyWatching()
	end, false)
	AddCheckbox(general, "IT_SHOW_MINIMAP", "showMinimapButton", "Minimap button", "Button on the minimap. Opens settings.", function()
		ns.UpdateMinimapButton()
	end, false)
	ns.lockSetting = AddCheckbox(general, "IT_LOCK", "lockPosition", "Lock position", "Drag the corner square while this is off. Right-click the square to lock it.", function()
		ns.ApplyLock()
	end, true)

	AddCheckbox(general, "IT_DAMAGE", "showDamage", "Show damage", "Damage you take.", OnDisplay, true)
	AddCheckbox(general, "IT_HEALING", "showHealing", "Show healing", "Healing that lands on you.", OnDisplay, true)
	AddCheckbox(general, "IT_MISSES", "showMisses", "Show misses", "Miss, dodge, parry, block, and similar lines.", OnDisplay, true)
	AddDropdown(general, "IT_FONT", "font", "Font", "The face used for the list. Fonts from other addons appear here when the shared media library is installed.", ns.FontChoices)
	AddSlider(general, "IT_FONT_SIZE", "fontSize", "Font size", "Size of a normal line.", 10, 32, 1)
	AddSlider(general, "IT_CRIT_SIZE", "critSize", "Crit size", "Size of a critical hit.", 10, 48, 1)
	AddSlider(general, "IT_OPACITY", "opacity", "Opacity", "How solid the text is. Lines fade out from this level.", 10, 100, 1)
	AddSlider(general, "IT_LINES", "lines", "Lines shown", "How many lines stay on screen.", 4, 24, 1)
	AddDropdown(general, "IT_ALIGN", "align", "Text align", "Which side the lines sit on.", ALIGNS)
	AddDropdown(general, "IT_GROW", "grow", "Grow", "Down puts the newest line at the top. Up puts it at the bottom.", GROWS)

	for i = 1, #COLOR_ROWS do
		local row = COLOR_ROWS[i]
		AddColor(row[1], row[2], row[3])
	end

	OpenButton("General", general)
	OpenButton("Colors", colors)

	Settings.RegisterAddOnCategory(category)
end

-- Addon compartment, named by the TOC.
function _G.IncomingText_OnAddonCompartmentClick()
	ns.OpenSettings()
end

function _G.IncomingText_OnAddonCompartmentEnter(_, menuButton)
	GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
	GameTooltip:AddLine("Incoming Text")
	GameTooltip:AddLine("Click for settings.", 1, 1, 1)
	GameTooltip:Show()
end

function _G.IncomingText_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

local function SlashCommand(msg)
	msg = (msg and msg:match("^%s*(.-)%s*$") or ""):lower()
	if msg == "test" then
		ns.ShowTest()
		return
	end
	if msg == "help" then
		ns.Print("Type /it to open settings. /it test shows sample lines.")
		return
	end
	ns.OpenSettings()
end

_G.SLASH_INCOMINGTEXT1 = "/it"
_G.SLASH_INCOMINGTEXT2 = "/incoming"
_G.SlashCmdList.INCOMINGTEXT = SlashCommand
