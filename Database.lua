local _, ns = ...

-- Saved variables: defaults and validation. Plain Lua, so the tests can load
-- it without a client. Damage, healing, and status are separate list tables.

local DB_VERSION = 4
local MINIMAP_POS = 190
local HEAL_SHIFT = -160

local POINTS = {
	CENTER = true,
	LEFT = true,
	RIGHT = true,
	TOP = true,
	BOTTOM = true,
	TOPLEFT = true,
	TOPRIGHT = true,
	BOTTOMLEFT = true,
	BOTTOMRIGHT = true,
}

local ALIGNS = {
	LEFT = true,
	CENTER = true,
	RIGHT = true,
}

local GROWS = {
	UP = true,
	DOWN = true,
}

-- Numbers only. Each saved color row is built in EnsureColors.
local COLOR_DEFAULTS = {
	physical = { 1, 1, 1 },
	crit = { 1, 0.82, 0 },
	holy = { 1, 0.90, 0.50 },
	fire = { 1, 0.50, 0.20 },
	nature = { 0.55, 0.75, 0.15 },
	frost = { 0.50, 0.85, 1 },
	shadow = { 0.70, 0.40, 0.90 },
	arcane = { 0.90, 0.50, 0.90 },
	heal = { 0.20, 0.90, 0.55 },
	miss = { 0.75, 0.75, 0.75 },
	combat = { 139 / 255, 92 / 255, 246 / 255 },
}

local DAMAGE_COLORS = {
	"physical",
	"crit",
	"holy",
	"fire",
	"nature",
	"frost",
	"shadow",
	"arcane",
	"miss",
}

local HEAL_COLORS = {
	"heal",
	"crit",
}

local STATUS_COLORS = {
	"combat",
}

local OLD_KEYS = {
	"enabled",
	"lockPosition",
	"showDamage",
	"showHealing",
	"showMisses",
	"showCombat",
	"fontSize",
	"critSize",
	"font",
	"opacity",
	"fadeTime",
	"lines",
	"align",
	"grow",
	"point",
	"relPoint",
	"x",
	"y",
	"colors",
}

local COPY_KEYS = {
	"lockPosition",
	"fontSize",
	"critSize",
	"font",
	"opacity",
	"fadeTime",
	"lines",
	"align",
	"grow",
	"point",
	"relPoint",
	"x",
	"y",
}

local function ListScalars(y)
	return {
		enabled = true,
		lockPosition = true,
		fontSize = 16,
		critSize = 22,
		font = "Friz Quadrata",
		opacity = 100,
		fadeTime = 1,
		lines = 12,
		align = "RIGHT",
		animate = true,
		grow = "DOWN",
		point = "CENTER",
		relPoint = "CENTER",
		x = -260,
		y = y,
	}
end

local damageDefaults = ListScalars(80)
damageDefaults.showMisses = true

local healDefaults = ListScalars(80 + HEAL_SHIFT)

local statusDefaults = ListScalars(80 + HEAL_SHIFT * 2)
statusDefaults.showCombat = true

-- Root scalars only. List tables are built in EnsureLists.
local defaults = {
	showMinimapButton = true,
}

local function ClampNumber(value, lo, hi, fallback)
	if type(value) ~= "number" or value ~= value then
		return fallback
	end
	if value < lo then
		return lo
	end
	if value > hi then
		return hi
	end
	return value
end

local function ClampChannel(value, fallback)
	return ClampNumber(value, 0, 1, fallback)
end

local function EnsureColors(list, keys)
	if type(list.colors) ~= "table" then
		list.colors = {}
	end
	for i = 1, #keys do
		local key = keys[i]
		local fallback = COLOR_DEFAULTS[key]
		local row = list.colors[key]
		if type(row) ~= "table" then
			row = {}
			list.colors[key] = row
		end
		row.r = ClampChannel(row.r, fallback[1])
		row.g = ClampChannel(row.g, fallback[2])
		row.b = ClampChannel(row.b, fallback[3])
	end
end

local function Anchor(value, fallback)
	if type(value) ~= "string" or not POINTS[value] then
		return fallback
	end
	return value
end

local function Choice(value, allowed, fallback)
	if type(value) ~= "string" or not allowed[value] then
		return fallback
	end
	return value
end

local function FontName(value, fallback)
	if type(value) ~= "string" or value == "" then
		return fallback
	end
	return value
end

local function ValidateList(list, listDefaults)
	list.fontSize = math.floor(ClampNumber(list.fontSize, 10, 32, listDefaults.fontSize) + 0.5)
	list.critSize = math.floor(ClampNumber(list.critSize, 10, 48, listDefaults.critSize) + 0.5)
	list.font = FontName(list.font, listDefaults.font)
	list.opacity = math.floor(ClampNumber(list.opacity, 10, 100, listDefaults.opacity) + 0.5)
	list.fadeTime = math.floor(ClampNumber(list.fadeTime, 0, 10, listDefaults.fadeTime) + 0.5)
	list.lines = math.floor(ClampNumber(list.lines, 4, 24, listDefaults.lines) + 0.5)
	list.align = Choice(list.align, ALIGNS, listDefaults.align)
	list.grow = Choice(list.grow, GROWS, listDefaults.grow)
	list.point = Anchor(list.point, listDefaults.point)
	list.relPoint = Anchor(list.relPoint, listDefaults.relPoint)
	list.x = ClampNumber(list.x, -4000, 4000, listDefaults.x)
	list.y = ClampNumber(list.y, -4000, 4000, listDefaults.y)
end

local function EnsureList(list, listDefaults, colorKeys)
	if type(list) ~= "table" then
		list = {}
	end
	for key, value in pairs(listDefaults) do
		if type(list[key]) ~= type(value) then
			list[key] = value
		end
	end
	ValidateList(list, listDefaults)
	EnsureColors(list, colorKeys)
	return list
end

local function EnsureLists(db)
	if type(db.minimapIcon) ~= "table" then
		db.minimapIcon = {}
	end
	db.minimapIcon.minimapPos = ClampNumber(db.minimapIcon.minimapPos, 0, 360, MINIMAP_POS)
	db.damage = EnsureList(db.damage, damageDefaults, DAMAGE_COLORS)
	db.heal = EnsureList(db.heal, healDefaults, HEAL_COLORS)
	db.status = EnsureList(db.status, statusDefaults, STATUS_COLORS)
end

local function CopyDefaults(db)
	if type(db.showMinimapButton) ~= "boolean" then
		db.showMinimapButton = defaults.showMinimapButton
	end
	EnsureLists(db)
end

local function Validate(db)
	EnsureLists(db)
end

local function Near(a, b)
	return type(a) == "number" and math.abs(a - b) < 0.02
end

-- Only the original pair. A color the player chose stays.
local function Retint(db, key, oldR, oldG, oldB)
	local colors = db.colors
	local row = colors and colors[key]
	local fallback = COLOR_DEFAULTS[key]
	if type(row) ~= "table" or not fallback then
		return
	end
	if Near(row.r, oldR) and Near(row.g, oldG) and Near(row.b, oldB) then
		row.r = fallback[1]
		row.g = fallback[2]
		row.b = fallback[3]
	end
end

local function CopyColorRow(row)
	if type(row) ~= "table" then
		return nil
	end
	return { r = row.r, g = row.g, b = row.b }
end

local function CopyColorSet(src, keys)
	local out = {}
	if type(src) ~= "table" then
		return out
	end
	for i = 1, #keys do
		local key = keys[i]
		local row = CopyColorRow(src[key])
		if row then
			out[key] = row
		end
	end
	return out
end

local function On(value)
	if type(value) == "boolean" then
		return value
	end
	return true
end

local function Snapshot(db, yOffset)
	local list = {}
	for i = 1, #COPY_KEYS do
		local key = COPY_KEYS[i]
		if db[key] ~= nil then
			list[key] = db[key]
		end
	end
	if type(list.y) == "number" then
		list.y = list.y + yOffset
	end
	return list
end

-- Combat state leaves the damage list. A chosen Show combat value stays.
local function MoveCombat(db)
	local damage = db.damage
	if type(damage) ~= "table" or type(damage.showCombat) ~= "boolean" then
		return
	end
	if type(db.status) ~= "table" then
		db.status = {}
	end
	db.status.showCombat = damage.showCombat
	damage.showCombat = nil
end

-- A flat save becomes the damage and healing lists. Damage keeps the point.
-- Healing sits below it. Status is added by the later steps.
local function SplitLists(db)
	local master = On(db.enabled)
	local damage = Snapshot(db, 0)
	local heal = Snapshot(db, HEAL_SHIFT)
	damage.enabled = master and On(db.showDamage)
	heal.enabled = master and On(db.showHealing)
	if type(db.showMisses) == "boolean" then
		damage.showMisses = db.showMisses
	end
	if type(db.showCombat) == "boolean" then
		damage.showCombat = db.showCombat
	end
	damage.colors = CopyColorSet(db.colors, DAMAGE_COLORS)
	heal.colors = CopyColorSet(db.colors, HEAL_COLORS)
	db.damage = damage
	db.heal = heal
	for i = 1, #OLD_KEYS do
		db[OLD_KEYS[i]] = nil
	end
end

local function MigrateDB(db)
	local version = db.version
	if type(version) ~= "number" then
		version = 0
	end
	if version < 2 then
		Retint(db, "nature", 0.30, 0.90, 0.30)
		Retint(db, "heal", 0.30, 0.95, 0.45)
	end
	if version < 3 then
		SplitLists(db)
	end
	if version < 4 then
		MoveCombat(db)
	end
	db.version = DB_VERSION
end

function ns.LoadDB(saved)
	ns.firstRun = type(saved) ~= "table"
	local db = ns.firstRun and {} or saved
	MigrateDB(db)
	CopyDefaults(db)
	Validate(db)
	return db
end

ns.defaults = defaults
ns.damageDefaults = damageDefaults
ns.healDefaults = healDefaults
ns.statusDefaults = statusDefaults
ns.DB_VERSION = DB_VERSION
