local _, ns = ...

-- Saved variables: defaults, migrations, validation. Plain Lua, so the tests
-- can load it without a client.

local DB_VERSION = 4
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

local FONT_NAMES = {
	FRIZ = "Friz Quadrata",
	ARIAL = "Arial Narrow",
	SKURRI = "Skurri",
	MORPHEUS = "Morpheus",
}

local LINE_ORDERS = {
	NUMBER = true,
	NUMBER_NAME = true,
	NUMBER_ICON = true,
	NUMBER_NAME_ICON = true,
	ICON_NUMBER = true,
	ICON_NUMBER_NAME = true,
	ICON_NAME_NUMBER = true,
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
	interrupt = { 0.95, 0.75, 0.25 },
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
	"interrupt",
}

-- Scalars only. Tables are built fresh in EnsureTables.
local defaults = {
	enabled = true,
	showMinimapButton = true,
	lockPosition = true,
	inEnabled = true,
	showIncomingDamage = true,
	showIncomingHealing = true,
	inShowMisses = true,
	inFontSize = 16,
	inCritSize = 22,
	inFont = "Friz Quadrata",
	inOpacity = 100,
	inLines = 12,
	inAlign = "RIGHT",
	inGrow = "DOWN",
	inPoint = "CENTER",
	inRelPoint = "CENTER",
	inX = -260,
	inY = 80,
	outEnabled = true,
	showOutgoingDamage = true,
	showOutgoingHealing = true,
	outShowMisses = true,
	lineOrder = "NUMBER_NAME",
	shortSpellNames = false,
	iconNormal = false,
	iconCrits = false,
	iconWhite = false,
	outFontSize = 16,
	outCritSize = 22,
	outFont = "Friz Quadrata",
	outOpacity = 100,
	outLines = 12,
	outAlign = "LEFT",
	outGrow = "DOWN",
	outPoint = "CENTER",
	outRelPoint = "CENTER",
	outX = 260,
	outY = 80,
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

local function ValidateSide(db, fontKey, critKey, faceKey, opacityKey, linesKey, alignKey, growKey, pointKey, relKey, xKey, yKey)
	db[fontKey] = math.floor(ClampNumber(db[fontKey], 10, 32, defaults[fontKey]) + 0.5)
	db[critKey] = math.floor(ClampNumber(db[critKey], 10, 48, defaults[critKey]) + 0.5)
	db[faceKey] = FontName(db[faceKey], defaults[faceKey])
	db[opacityKey] = math.floor(ClampNumber(db[opacityKey], 10, 100, defaults[opacityKey]) + 0.5)
	db[linesKey] = math.floor(ClampNumber(db[linesKey], 4, 24, defaults[linesKey]) + 0.5)
	db[alignKey] = Choice(db[alignKey], ALIGNS, defaults[alignKey])
	db[growKey] = Choice(db[growKey], GROWS, defaults[growKey])
	db[pointKey] = Anchor(db[pointKey], defaults[pointKey])
	db[relKey] = Anchor(db[relKey], defaults[relKey])
	db[xKey] = ClampNumber(db[xKey], -4000, 4000, defaults[xKey])
	db[yKey] = ClampNumber(db[yKey], -4000, 4000, defaults[yKey])
end

local function Validate(db)
	ValidateSide(db, "inFontSize", "inCritSize", "inFont", "inOpacity", "inLines", "inAlign", "inGrow", "inPoint", "inRelPoint", "inX", "inY")
	ValidateSide(db, "outFontSize", "outCritSize", "outFont", "outOpacity", "outLines", "outAlign", "outGrow", "outPoint", "outRelPoint", "outX", "outY")
	db.lineOrder = Choice(db.lineOrder, LINE_ORDERS, defaults.lineOrder)
	EnsureColors(db)
end

local function TakeNumber(db, key)
	if type(db[key]) == "number" then
		local value = db[key]
		db[key] = nil
		return value
	end
	db[key] = nil
	return nil
end

local function TakeBoolean(db, key)
	if type(db[key]) == "boolean" then
		local value = db[key]
		db[key] = nil
		return value
	end
	db[key] = nil
	return nil
end

local function TakeString(db, key)
	if type(db[key]) == "string" then
		local value = db[key]
		db[key] = nil
		return value
	end
	db[key] = nil
	return nil
end

-- One shared list became two. The old anchor belongs to outgoing; incoming
-- picks up its default on the left.
local function MigrateDB(db)
	local version = type(db.version) == "number" and db.version or 0
	if version < 2 then
		local fontSize = TakeNumber(db, "fontSize")
		local lines = TakeNumber(db, "lines")
		local misses = TakeBoolean(db, "showMisses")
		local point = TakeString(db, "point")
		local relPoint = TakeString(db, "relPoint")
		local x = TakeNumber(db, "x")
		local y = TakeNumber(db, "y")
		if fontSize and type(db.inFontSize) ~= "number" then
			db.inFontSize = fontSize
		end
		if fontSize and type(db.outFontSize) ~= "number" then
			db.outFontSize = fontSize
		end
		if lines and type(db.inLines) ~= "number" then
			db.inLines = lines
		end
		if lines and type(db.outLines) ~= "number" then
			db.outLines = lines
		end
		if misses ~= nil and type(db.inShowMisses) ~= "boolean" then
			db.inShowMisses = misses
		end
		if misses ~= nil and type(db.outShowMisses) ~= "boolean" then
			db.outShowMisses = misses
		end
		if point and type(db.outPoint) ~= "string" then
			db.outPoint = point
			db.outRelPoint = relPoint
			db.outX = x
			db.outY = y
		end
	end
	-- Names and a single icon box became a line order plus three icon switches.
	if version < 3 then
		local names = TakeBoolean(db, "showSpellNames")
		local icons = TakeBoolean(db, "spellIcons")
		local showNames = names ~= false
		local showIcons = icons == true
		if type(db.lineOrder) ~= "string" then
			if showIcons then
				db.lineOrder = "ICON_NUMBER"
			elseif showNames then
				db.lineOrder = "NUMBER_NAME"
			else
				db.lineOrder = "NUMBER"
			end
		end
		if showIcons then
			if type(db.iconNormal) ~= "boolean" then
				db.iconNormal = true
			end
			if type(db.iconCrits) ~= "boolean" then
				db.iconCrits = true
			end
		end
	end
	-- One opacity and four font keys became a value per list and a font name.
	if version < 4 then
		local shared = TakeNumber(db, "opacity")
		if shared and type(db.inOpacity) ~= "number" then
			db.inOpacity = shared
		end
		if shared and type(db.outOpacity) ~= "number" then
			db.outOpacity = shared
		end
		if type(db.inFont) == "string" and FONT_NAMES[db.inFont] then
			db.inFont = FONT_NAMES[db.inFont]
		end
		if type(db.outFont) == "string" and FONT_NAMES[db.outFont] then
			db.outFont = FONT_NAMES[db.outFont]
		end
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
ns.DB_VERSION = DB_VERSION
