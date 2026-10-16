local _, ns = ...

-- Settings panel. The parent page sets all three lists at once. Each list still
-- has its own page. Rows are registered from Blizzard's delegate so the settings
-- search stays secure.

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
local DAMAGE_COLORS = {
	{ "physical", "Physical hits", "Physical damage you take." },
	{ "crit", "Critical hits", "A critical hit uses this color instead of the school color." },
	{ "holy", "Holy", "Holy damage you take." },
	{ "fire", "Fire", "Fire damage you take." },
	{ "nature", "Nature", "Nature damage you take." },
	{ "frost", "Frost", "Frost damage you take." },
	{ "shadow", "Shadow", "Shadow damage you take." },
	{ "arcane", "Arcane", "Arcane damage you take." },
	{ "miss", "Misses", "Miss, dodge, parry, block, and similar lines." },
}
local HEAL_COLORS = {
	{ "heal", "Healing", "Healing that lands on you and is not a critical hit." },
	{ "crit", "Critical hits", "A critical heal uses this color instead of the heal color." },
}
local STATUS_COLORS = {
	{ "combat", "Combat", "Entering and leaving combat." },
	{ "dispel", "Dispels", "An aura removed from you." },
}
local ENABLE = {
	damage = { "Enable damage", "Damage and misses that land on you." },
	heal = { "Enable healing", "Healing that lands on you." },
	status = { "Enable status", "Combat state, and auras dispelled from you." },
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

-- Rows other than the enable switch grey out while that list is off.
local function Gate(initializer, storage, varName)
	initializer:AddModifyPredicate(function()
		if not storage or not storage.enabled then
			return false
		end
		return true
	end)
	initializer:AddEvaluateStateCVar(varName)
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

	local minimap = Settings.RegisterAddOnSetting(
		category,
		"IT_SHOW_MINIMAP",
		"showMinimapButton",
		ns.db,
		Settings.VarType.Boolean,
		"Minimap button",
		ns.defaults.showMinimapButton
	)
	minimap:SetValueChangedCallback(function()
		ns.UpdateMinimapButton()
	end)
	Settings.RegisterInitializer(category, Settings.CreateCheckboxInitializer(
		minimap,
		nil,
		"Button on the minimap. Opens settings."
	))

	-- Set while a main-page change is being copied onto every list, so a list
	-- checkbox does not write that change back and lock the other lists too.
	local applying = false
	local bothLock
	local shared
	local SyncBothLock

	local function BuildPage(page, prefix, storage, listDefaults, listObj, colorRows, kind)
		local enableVar = prefix .. "_ENABLED"

		local function AddCheckbox(var, key, label, tooltip, onChanged, gated)
			local setting = Settings.RegisterAddOnSetting(
				page,
				var,
				key,
				storage,
				Settings.VarType.Boolean,
				label,
				listDefaults[key]
			)
			if onChanged then
				setting:SetValueChangedCallback(onChanged)
			end
			local initializer = Settings.CreateCheckboxInitializer(setting, nil, tooltip)
			if gated then
				Gate(initializer, storage, enableVar)
			end
			Settings.RegisterInitializer(page, initializer)
			return setting
		end

		local function AddSlider(var, key, label, tooltip, lo, hi, step)
			local setting = Settings.RegisterAddOnSetting(
				page,
				var,
				key,
				storage,
				Settings.VarType.Number,
				label,
				listDefaults[key]
			)
			setting:SetValueChangedCallback(function()
				storage[key] = math.floor(Clamp(storage[key], lo, hi, listDefaults[key]) + 0.5)
				listObj:Refresh()
			end)
			local options = Settings.CreateSliderOptions(lo, hi, step)
			options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
				return string.format("%.0f", value)
			end)
			local initializer = Settings.CreateSliderInitializer(setting, options, tooltip)
			Gate(initializer, storage, enableVar)
			Settings.RegisterInitializer(page, initializer)
			return setting
		end

		local function AddDropdown(var, key, label, tooltip, choices)
			local setting = Settings.RegisterAddOnSetting(
				page,
				var,
				key,
				storage,
				Settings.VarType.String,
				label,
				listDefaults[key]
			)
			setting:SetValueChangedCallback(function()
				listObj:Refresh()
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
			Gate(initializer, storage, enableVar)
			Settings.RegisterInitializer(page, initializer)
			return setting
		end

		local function AddColor(key, label, tooltip)
			local function SetColor(r, g, b)
				local row = storage.colors and storage.colors[key]
				if type(row) ~= "table" then
					row = {}
					storage.colors[key] = row
				end
				row.r = Clamp01(r, 1)
				row.g = Clamp01(g, 1)
				row.b = Clamp01(b, 1)
				listObj:Refresh()
			end
			local function Open()
				local row = storage.colors and storage.colors[key]
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
			Gate(initializer, storage, enableVar)
			Settings.RegisterInitializer(page, initializer)
		end

		local function OnWatch()
			ns.ApplyWatching()
		end

		local controls = {}
		local enable = ENABLE[kind]
		controls.enabled = AddCheckbox(prefix .. "_ENABLED", "enabled", enable[1], enable[2], OnWatch, false)
		controls.lockPosition = AddCheckbox(prefix .. "_LOCK", "lockPosition", "Lock position", "Drag the area or either edge while this is off. Right-click it to lock.", function()
			listObj:ApplyLock()
			if SyncBothLock then
				SyncBothLock()
			end
		end, true)
		listObj.lockSetting = controls.lockPosition
		if kind == "damage" then
			controls.showMisses = AddCheckbox(prefix .. "_MISSES", "showMisses", "Show misses", "Miss, dodge, parry, block, and similar lines.", OnWatch, true)
		elseif kind == "status" then
			controls.showCombat = AddCheckbox(prefix .. "_COMBAT", "showCombat", "Show combat", "Entering and leaving combat.", OnWatch, true)
			controls.showDispels = AddCheckbox(prefix .. "_DISPELS", "showDispels", "Show dispels", "An aura removed from you, by name.", OnWatch, true)
		end
		controls.font = AddDropdown(prefix .. "_FONT", "font", "Font", "The face used for the list. Fonts from other addons appear here when the shared media library is installed.", ns.FontChoices)
		controls.fontSize = AddSlider(prefix .. "_FONT_SIZE", "fontSize", "Font size", "Size of a normal line.", 10, 32, 1)
		controls.critSize = AddSlider(prefix .. "_CRIT_SIZE", "critSize", "Crit size", "Size of a critical line.", 10, 48, 1)
		controls.opacity = AddSlider(prefix .. "_OPACITY", "opacity", "Opacity", "How solid the text is. Lines fade out from this level.", 10, 100, 1)
		controls.fadeTime = AddSlider(prefix .. "_FADE", "fadeTime", "Fade time", "How long a line takes to fade out, in seconds.", 0, 10, 1)
		controls.lines = AddSlider(prefix .. "_LINES", "lines", "Lines shown", "How many lines stay on screen.", 4, 24, 1)
		controls.align = AddDropdown(prefix .. "_ALIGN", "align", "Text align", "Which side the lines sit on.", ALIGNS)
		controls.grow = AddDropdown(prefix .. "_GROW", "grow", "Grow", "Down puts the newest line at the top. Up puts it at the bottom.", GROWS)

		for i = 1, #colorRows do
			local row = colorRows[i]
			AddColor(row[1], row[2], row[3])
		end
		return controls
	end

	local damagePage = Settings.RegisterVerticalLayoutSubcategory(category, "Damage")
	local healPage = Settings.RegisterVerticalLayoutSubcategory(category, "Healing")
	local statusPage = Settings.RegisterVerticalLayoutSubcategory(category, "Status")
	local damageControls = BuildPage(damagePage, "IT_DMG", ns.db.damage, ns.damageDefaults, ns.damageList, DAMAGE_COLORS, "damage")
	local healControls = BuildPage(healPage, "IT_HEAL", ns.db.heal, ns.healDefaults, ns.healList, HEAL_COLORS, "heal")
	local statusControls = BuildPage(statusPage, "IT_STATUS", ns.db.status, ns.statusDefaults, ns.statusList, STATUS_COLORS, "status")

	-- Not saved. A change here is written onto every list, which keeps its own copy.
	local damage = ns.db.damage
	local heal = ns.db.heal
	local status = ns.db.status
	shared = {
		lockPosition = damage.lockPosition and heal.lockPosition and status.lockPosition,
		font = damage.font,
		fontSize = damage.fontSize,
		critSize = damage.critSize,
		opacity = damage.opacity,
		fadeTime = damage.fadeTime,
		lines = damage.lines,
		align = damage.align,
		grow = damage.grow,
	}

	local function Push(key)
		if applying then
			return
		end
		applying = true
		damageControls[key]:SetValue(shared[key])
		healControls[key]:SetValue(shared[key])
		statusControls[key]:SetValue(shared[key])
		applying = false
	end

	SyncBothLock = function()
		if applying or not bothLock then
			return
		end
		applying = true
		shared.lockPosition = ns.db.damage.lockPosition and ns.db.heal.lockPosition and ns.db.status.lockPosition
		bothLock:SetValue(shared.lockPosition)
		applying = false
	end

	local function AddSharedSlider(var, key, label, tooltip, lo, hi, step)
		local setting = Settings.RegisterAddOnSetting(
			category,
			var,
			key,
			shared,
			Settings.VarType.Number,
			label,
			ns.damageDefaults[key]
		)
		setting:SetValueChangedCallback(function()
			shared[key] = math.floor(Clamp(shared[key], lo, hi, ns.damageDefaults[key]) + 0.5)
			Push(key)
		end)
		local options = Settings.CreateSliderOptions(lo, hi, step)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return string.format("%.0f", value)
		end)
		Settings.RegisterInitializer(category, Settings.CreateSliderInitializer(setting, options, tooltip))
	end

	local function AddSharedDropdown(var, key, label, tooltip, choices)
		local setting = Settings.RegisterAddOnSetting(
			category,
			var,
			key,
			shared,
			Settings.VarType.String,
			label,
			ns.damageDefaults[key]
		)
		setting:SetValueChangedCallback(function()
			Push(key)
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
		Settings.RegisterInitializer(category, initializer)
	end

	local function AddSharedCheckbox(var, key, label, tooltip)
		local setting = Settings.RegisterAddOnSetting(
			category,
			var,
			key,
			shared,
			Settings.VarType.Boolean,
			label,
			ns.damageDefaults[key]
		)
		setting:SetValueChangedCallback(function()
			Push(key)
		end)
		Settings.RegisterInitializer(category, Settings.CreateCheckboxInitializer(setting, nil, tooltip))
		return setting
	end

	bothLock = AddSharedCheckbox("IT_BOTH_LOCK", "lockPosition", "Lock position", "Locks or unlocks all three lists. Drag any area while this is off. Right-click an area to lock it.")

	AddSharedDropdown("IT_BOTH_FONT", "font", "Font", "Sets the font on all three lists. Fonts from other addons appear here when the shared media library is installed.", ns.FontChoices)
	AddSharedSlider("IT_BOTH_FONT_SIZE", "fontSize", "Font size", "Sets the normal line size on all three lists.", 10, 32, 1)
	AddSharedSlider("IT_BOTH_CRIT_SIZE", "critSize", "Crit size", "Sets the critical line size on all three lists.", 10, 48, 1)
	AddSharedSlider("IT_BOTH_OPACITY", "opacity", "Opacity", "Sets how solid the text is on all three lists.", 10, 100, 1)
	AddSharedSlider("IT_BOTH_FADE", "fadeTime", "Fade time", "Sets how long a line takes to fade out on all three lists, in seconds.", 0, 10, 1)
	AddSharedSlider("IT_BOTH_LINES", "lines", "Lines shown", "Sets how many lines stay on screen for all three lists.", 4, 24, 1)
	AddSharedDropdown("IT_BOTH_ALIGN", "align", "Text align", "Sets which side the lines sit on for all three lists.", ALIGNS)
	AddSharedDropdown("IT_BOTH_GROW", "grow", "Grow", "Sets the grow direction on all three lists. Down puts the newest line at the top. Up puts it at the bottom.", GROWS)

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
