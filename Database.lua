local _, ns = ...

-- Saved variables: defaults and validation. Plain Lua, so the tests can load
-- it without a client.

local DB_VERSION = 1
local MINIMAP_POS = 190

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
	nature = { 0.30, 0.90, 0.30 },
	frost = { 0.50, 0.85, 1 },
	shadow = { 0.70, 0.40, 0.90 },
	arcane = { 0.90, 0.50, 0.90 },
	heal = { 0.30, 0.95, 0.45 },
	miss = { 0.75, 0.75, 0.75 },
}

local COLOR_KEYS = {
	"physical",
	"crit",
	"holy",
	"fire",
	"nature",
	"frost",
	"shadow",
	"arcane",
	"heal",
	"miss",
}

-- Scalars only. Tables are built fresh in EnsureTables.
local defaults = {
	enabled = true,
	showMinimapButton = true,
	lockPosition = true,
	showDamage = true,
	showHealing = true,
	showMisses = true,
	fontSize = 16,
	critSize = 22,
	font = "Friz Quadrata",
	opacity = 100,
	lines = 12,
	align = "RIGHT",
	grow = "DOWN",
	point = "CENTER",
	relPoint = "CENTER",
	x = -260,
	y = 80,
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

local function EnsureColors(db)
	if type(db.colors) ~= "table" then
		db.colors = {}
	end
	for i = 1, #COLOR_KEYS do
		local key = COLOR_KEYS[i]
		local fallback = COLOR_DEFAULTS[key]
		local row = db.colors[key]
		if type(row) ~= "table" then
			row = {}
			db.colors[key] = row
		end
		row.r = ClampChannel(row.r, fallback[1])
		row.g = ClampChannel(row.g, fallback[2])
		row.b = ClampChannel(row.b, fallback[3])
	end
end

local function EnsureTables(db)
	if type(db.minimapIcon) ~= "table" then
		db.minimapIcon = {}
	end
	db.minimapIcon.minimapPos = ClampNumber(db.minimapIcon.minimapPos, 0, 360, MINIMAP_POS)
	EnsureColors(db)
end

local function CopyDefaults(db)
	for key, value in pairs(defaults) do
		if type(db[key]) ~= type(value) then
			db[key] = value
		end
	end
	EnsureTables(db)
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

local function Validate(db)
	db.fontSize = math.floor(ClampNumber(db.fontSize, 10, 32, defaults.fontSize) + 0.5)
	db.critSize = math.floor(ClampNumber(db.critSize, 10, 48, defaults.critSize) + 0.5)
	db.font = FontName(db.font, defaults.font)
	db.opacity = math.floor(ClampNumber(db.opacity, 10, 100, defaults.opacity) + 0.5)
	db.lines = math.floor(ClampNumber(db.lines, 4, 24, defaults.lines) + 0.5)
	db.align = Choice(db.align, ALIGNS, defaults.align)
	db.grow = Choice(db.grow, GROWS, defaults.grow)
	db.point = Anchor(db.point, defaults.point)
	db.relPoint = Anchor(db.relPoint, defaults.relPoint)
	db.x = ClampNumber(db.x, -4000, 4000, defaults.x)
	db.y = ClampNumber(db.y, -4000, 4000, defaults.y)
	EnsureColors(db)
end

function ns.LoadDB(saved)
	ns.firstRun = type(saved) ~= "table"
	local db = ns.firstRun and {} or saved
	db.version = DB_VERSION
	CopyDefaults(db)
	Validate(db)
	return db
end

ns.defaults = defaults
ns.DB_VERSION = DB_VERSION
