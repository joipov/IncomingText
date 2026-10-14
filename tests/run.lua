-- Unit tests for the client-free part of Combat Text.
--   luajit tests/run.lua
--   lua5.1 tests/run.lua
-- Database.lua and SpellLabel.lua are loaded. The other files create frames.

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)[/\\]tests[/\\]") or "."

local ns = {}
local function load(file)
	local chunk, err = loadfile(root .. "/" .. file)
	assert(chunk, err)
	chunk("CombatText", ns)
end

load("Database.lua")
load("SpellLabel.lua")

local passed, failed = 0, 0

local function eq(actual, expected, label)
	if actual ~= expected then
		error(string.format("%s: expected %s, got %s", label or "value", tostring(expected), tostring(actual)), 2)
	end
end

local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed = passed + 1
	else
		failed = failed + 1
		print("FAIL " .. name .. ": " .. tostring(err))
	end
end

test("LoadDB fills defaults and reports a first run", function()
	local db = ns.LoadDB(nil)
	eq(ns.firstRun, true, "firstRun")
	eq(db.enabled, true, "enabled")
	eq(db.showMinimapButton, true, "showMinimapButton")
	eq(db.lockPosition, true, "lockPosition")
	eq(db.showIncomingDamage, true, "showIncomingDamage")
	eq(db.showIncomingHealing, true, "showIncomingHealing")
	eq(db.inShowMisses, true, "inShowMisses")
	eq(db.inEnabled, true, "inEnabled")
	eq(db.inFontSize, 16, "inFontSize")
	eq(db.inCritSize, 22, "inCritSize")
	eq(db.inFont, "Friz Quadrata", "inFont")
	eq(db.inLines, 12, "inLines")
	eq(db.inAlign, "RIGHT", "inAlign")
	eq(db.inGrow, "DOWN", "inGrow")
	eq(db.inX, -260, "inX")
	eq(db.inY, 80, "inY")
	eq(db.showOutgoingDamage, true, "showOutgoingDamage")
	eq(db.showOutgoingHealing, true, "showOutgoingHealing")
	eq(db.outShowMisses, true, "outShowMisses")
	eq(db.inOpacity, 100, "inOpacity")
	eq(db.outOpacity, 100, "outOpacity")
	eq(db.opacity, nil, "opacity")
	eq(db.lineOrder, "NUMBER_NAME", "lineOrder")
	eq(db.shortSpellNames, false, "shortSpellNames")
	eq(db.iconNormal, false, "iconNormal")
	eq(db.iconCrits, false, "iconCrits")
	eq(db.iconWhite, false, "iconWhite")
	eq(db.showSpellNames, nil, "showSpellNames")
	eq(db.spellIcons, nil, "spellIcons")
	eq(db.outEnabled, true, "outEnabled")
	eq(db.outFontSize, 16, "outFontSize")
	eq(db.outCritSize, 22, "outCritSize")
	eq(db.outFont, "Friz Quadrata", "outFont")
	eq(db.outLines, 12, "outLines")
	eq(db.outAlign, "LEFT", "outAlign")
	eq(db.outGrow, "DOWN", "outGrow")
	eq(db.outX, 260, "outX")
	eq(db.outY, 80, "outY")
	eq(db.version, ns.DB_VERSION, "version")
	eq(db.minimapIcon.minimapPos, 190, "minimapPos")
	eq(db.fontSize, nil, "fontSize")
	eq(db.showMisses, nil, "showMisses")
	eq(db.colors.physical.r, 1, "physical.r")
	eq(db.colors.physical.g, 1, "physical.g")
	eq(db.colors.physical.b, 1, "physical.b")
	eq(db.colors.crit.r, 1, "crit.r")
	eq(db.colors.crit.g, 0.82, "crit.g")
	eq(db.colors.crit.b, 0, "crit.b")
	eq(db.colors.holy.b, 0.50, "holy.b")
	eq(db.colors.fire.g, 0.50, "fire.g")
	eq(db.colors.nature.r, 0.30, "nature.r")
	eq(db.colors.frost.b, 1, "frost.b")
	eq(db.colors.shadow.b, 0.90, "shadow.b")
	eq(db.colors.arcane.r, 0.90, "arcane.r")
	eq(db.colors.heal.g, 0.95, "heal.g")
	eq(db.colors.miss.r, 0.75, "miss.r")
	eq(db.colors.interrupt.b, 0.25, "interrupt.b")
end)

test("LoadDB reports an existing save", function()
	ns.LoadDB({})
	eq(ns.firstRun, false, "firstRun")
end)

test("LoadDB keeps an explicit disabled state", function()
	local db = ns.LoadDB({ enabled = false, showMinimapButton = false, lockPosition = false })
	eq(db.enabled, false, "enabled")
	eq(db.showMinimapButton, false, "showMinimapButton")
	eq(db.lockPosition, false, "lockPosition")
end)

test("LoadDB clamps font size, line count, align, and position", function()
	local db = ns.LoadDB({
		version = 2,
		inFontSize = 80,
		outLines = 1,
		inX = 9000,
		outY = -9000,
		inAlign = "NOPE",
		outGrow = "",
		inPoint = "NOPE",
		outRelPoint = "",
	})
	eq(db.inFontSize, 32, "inFontSize")
	eq(db.outLines, 4, "outLines")
	eq(db.inX, 4000, "inX")
	eq(db.outY, -4000, "outY")
	eq(db.inAlign, "RIGHT", "inAlign")
	eq(db.outGrow, "DOWN", "outGrow")
	eq(db.inPoint, "CENTER", "inPoint")
	eq(db.outRelPoint, "CENTER", "outRelPoint")
end)

test("LoadDB moves a version 1 list onto the outgoing side", function()
	local db = ns.LoadDB({
		version = 1,
		fontSize = 20,
		lines = 8,
		showMisses = false,
		point = "LEFT",
		relPoint = "LEFT",
		x = 10,
		y = 20,
	})
	eq(db.inFontSize, 20, "inFontSize")
	eq(db.outFontSize, 20, "outFontSize")
	eq(db.inLines, 8, "inLines")
	eq(db.outLines, 8, "outLines")
	eq(db.inShowMisses, false, "inShowMisses")
	eq(db.outShowMisses, false, "outShowMisses")
	eq(db.outPoint, "LEFT", "outPoint")
	eq(db.outRelPoint, "LEFT", "outRelPoint")
	eq(db.outX, 10, "outX")
	eq(db.outY, 20, "outY")
	eq(db.inX, -260, "inX")
	eq(db.fontSize, nil, "fontSize")
	eq(db.lines, nil, "lines")
	eq(db.showMisses, nil, "showMisses")
	eq(db.point, nil, "point")
	eq(db.x, nil, "x")
	eq(db.version, 4, "version")
	eq(db.lineOrder, "NUMBER_NAME", "lineOrder")
	eq(db.inCritSize, 22, "inCritSize")
	eq(db.inFont, "Friz Quadrata", "inFont")
	eq(db.colors.physical.r, 1, "physical.r")
end)

test("LoadDB clamps crit size and font, and fills a missing color table", function()
	local db = ns.LoadDB({
		version = 2,
		inEnabled = false,
		inCritSize = 80,
		outCritSize = 3,
		inFont = "Comic",
		outFont = "MORPHEUS",
	})
	eq(db.inEnabled, false, "inEnabled")
	eq(db.outEnabled, true, "outEnabled")
	eq(db.inCritSize, 48, "inCritSize")
	eq(db.outCritSize, 10, "outCritSize")
	eq(db.inFont, "Comic", "inFont")
	eq(db.outFont, "Morpheus", "outFont")
	eq(db.colors.fire.r, 1, "fire.r")
	eq(db.colors.heal.g, 0.95, "heal.g")

	local patched = ns.LoadDB({
		version = 2,
		colors = { physical = { r = 2, g = -1, b = "x" } },
	})
	eq(patched.colors.physical.r, 1, "clamped.r")
	eq(patched.colors.physical.g, 0, "clamped.g")
	eq(patched.colors.physical.b, 1, "clamped.b")
	eq(patched.colors.interrupt.r, 0.95, "interrupt.r")
end)

test("ShortSpellName uses initials and keeps a one-word name", function()
	eq(ns.ShortSpellName("Sinister Strike"), "SS", "SS")
	eq(ns.ShortSpellName("Shadow Word: Pain"), "SWP", "SWP")
	eq(ns.ShortSpellName("Hand of Gul'dan"), "HOG", "HOG")
	eq(ns.ShortSpellName("Eviscerate"), "Eviscerate", "one word")
	eq(ns.ShortSpellName(""), nil, "empty")
	eq(ns.ShortSpellName(nil), nil, "nil")
end)

test("SpellIconText builds a texture escape", function()
	eq(ns.SpellIconText(136197, 22), "|T136197:22|t", "file id")
	eq(ns.SpellIconText("Interface\\Icons\\INV_Sword_04", 16), "|TInterface\\Icons\\INV_Sword_04:16|t", "path")
	eq(ns.SpellIconText(nil, 16), nil, "nil")
	eq(ns.SpellIconText("", 16), nil, "empty")
end)

test("CastKind keeps a harmful cast for damage and a helpful cast for a heal", function()
	eq(ns.CastKind(true, false, false), "damage", "harmful")
	eq(ns.CastKind(false, true, false), "heal", "helpful")
	eq(ns.CastKind(false, false, false), nil, "neither")
	eq(ns.CastKind(true, false, true), nil, "secret")
end)

test("FormatLine orders the icon, the number, and the name", function()
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "NUMBER_NAME", false, false), "1,902 Sinister Strike", "name")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "NUMBER_NAME", true, false), "1,902 SS", "short")
	eq(ns.FormatLine("1,902", "Eviscerate", 5, 16, "NUMBER_NAME", true, false), "1,902 Eviscerate", "one word")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "ICON_NUMBER", false, true), "|T5:16|t 1,902", "icon number")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "ICON_NUMBER_NAME", true, true), "|T5:16|t 1,902 SS", "icon number name")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "ICON_NAME_NUMBER", false, true), "|T5:16|t Sinister Strike 1,902", "icon name number")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "NUMBER", false, true), "1,902", "skip icon")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "NUMBER_ICON", false, false), "1,902", "icon off")
	eq(ns.FormatLine("1,902", "Sinister Strike", 5, 16, "ICON_NUMBER_NAME", false, false), "1,902 Sinister Strike", "name stays")
	eq(ns.FormatLine(nil, "Fireball", 5, 16, "NUMBER_NAME", false, false), "Fireball", "no number")
	eq(ns.FormatLine("842", nil, 5, 16, "ICON_NUMBER", false, true), "|T5:16|t 842", "white")
	eq(ns.FormatLine(nil, nil, nil, 16, "ICON_NUMBER", false, false), "", "empty")
end)

test("LoadDB maps spell names and icons onto line order", function()
	local named = ns.LoadDB({ version = 2, showSpellNames = true, spellIcons = false })
	eq(named.lineOrder, "NUMBER_NAME", "names")
	eq(named.iconNormal, false, "names.normal")
	eq(named.iconCrits, false, "names.crits")
	eq(named.iconWhite, false, "names.white")
	eq(named.showSpellNames, nil, "names.old")
	eq(named.spellIcons, nil, "names.icons")
	eq(named.version, 4, "names.version")

	local icons = ns.LoadDB({ version = 2, showSpellNames = true, spellIcons = true })
	eq(icons.lineOrder, "ICON_NUMBER", "icons")
	eq(icons.iconNormal, true, "icons.normal")
	eq(icons.iconCrits, true, "icons.crits")
	eq(icons.iconWhite, false, "icons.white")

	local bare = ns.LoadDB({ version = 2, showSpellNames = false, spellIcons = false })
	eq(bare.lineOrder, "NUMBER", "bare")

	local iconsOnly = ns.LoadDB({ version = 2, showSpellNames = false, spellIcons = true })
	eq(iconsOnly.lineOrder, "ICON_NUMBER", "icons only")
	eq(iconsOnly.iconNormal, true, "icons only normal")
end)

test("LoadDB clamps opacity and line order", function()
	local low = ns.LoadDB({ version = 3, opacity = 0, lineOrder = "NOPE" })
	eq(low.inOpacity, 10, "low in")
	eq(low.outOpacity, 10, "low out")
	eq(low.opacity, nil, "low shared")
	eq(low.lineOrder, "NUMBER_NAME", "bad order")
	local high = ns.LoadDB({ version = 3, opacity = 200 })
	eq(high.inOpacity, 100, "high in")
	eq(high.outOpacity, 100, "high out")
end)

test("LoadDB maps font keys and keeps a media font name", function()
	local mapped = ns.LoadDB({ version = 3, inFont = "FRIZ", outFont = "ARIAL", opacity = 40 })
	eq(mapped.inFont, "Friz Quadrata", "friz")
	eq(mapped.outFont, "Arial Narrow", "arial")
	eq(mapped.inOpacity, 40, "shared in")
	eq(mapped.outOpacity, 40, "shared out")
	eq(mapped.opacity, nil, "shared cleared")

	local kept = ns.LoadDB({ version = 4, inFont = "Ellesmere Display", outFont = "" })
	eq(kept.inFont, "Ellesmere Display", "media")
	eq(kept.outFont, "Friz Quadrata", "empty")
	eq(ns.LoadDB({ version = 4, inOpacity = 0, outOpacity = 200 }).inOpacity, 10, "clamp in")
	eq(ns.LoadDB({ version = 4, inOpacity = 0, outOpacity = 200 }).outOpacity, 100, "clamp out")
end)

test("LoadDB clamps the minimap position", function()
	eq(ns.LoadDB({ minimapIcon = { minimapPos = 400 } }).minimapIcon.minimapPos, 360, "minimapPos")
end)

if failed > 0 then
	print(string.format("%d passed, %d failed", passed, failed))
	os.exit(1)
end
print(string.format("%d passed", passed))
