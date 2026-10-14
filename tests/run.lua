-- Unit tests for the client-free part of Incoming Text.
--   luajit tests/run.lua
--   lua5.1 tests/run.lua
-- Database.lua is loaded. The other files create frames.

local root = (arg and arg[0] or "tests/run.lua"):match("^(.*)[/\\]tests[/\\]") or "."

local ns = {}
local function load(file)
	local chunk, err = loadfile(root .. "/" .. file)
	assert(chunk, err)
	chunk("IncomingText", ns)
end

load("Database.lua")

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
	eq(db.showMinimapButton, true, "showMinimapButton")
	eq(db.enabled, nil, "enabled")
	eq(db.colors, nil, "colors")
	eq(db.damage.enabled, true, "damage.enabled")
	eq(db.heal.enabled, true, "heal.enabled")
	eq(db.damage.lockPosition, true, "damage.lock")
	eq(db.heal.lockPosition, true, "heal.lock")
	eq(db.damage.showMisses, true, "showMisses")
	eq(db.damage.showCombat, true, "showCombat")
	eq(db.heal.showMisses, nil, "heal.showMisses")
	eq(db.damage.fontSize, 16, "fontSize")
	eq(db.heal.fontSize, 16, "heal.fontSize")
	eq(db.damage.critSize, 22, "critSize")
	eq(db.damage.font, "Friz Quadrata", "font")
	eq(db.damage.opacity, 100, "opacity")
	eq(db.damage.fadeTime, 1, "fadeTime")
	eq(db.heal.fadeTime, 1, "heal.fadeTime")
	eq(db.damage.lines, 12, "lines")
	eq(db.damage.align, "RIGHT", "align")
	eq(db.damage.grow, "DOWN", "grow")
	eq(db.damage.point, "CENTER", "point")
	eq(db.damage.relPoint, "CENTER", "relPoint")
	eq(db.damage.x, -260, "x")
	eq(db.damage.y, 80, "damage.y")
	eq(db.heal.y, -80, "heal.y")
	eq(db.version, ns.DB_VERSION, "version")
	eq(ns.DB_VERSION, 3, "DB_VERSION")
	eq(db.minimapIcon.minimapPos, 190, "minimapPos")
	eq(db.damage.colors.physical.r, 1, "physical.r")
	eq(db.damage.colors.physical.g, 1, "physical.g")
	eq(db.damage.colors.physical.b, 1, "physical.b")
	eq(db.damage.colors.crit.r, 1, "crit.r")
	eq(db.damage.colors.crit.g, 0.82, "crit.g")
	eq(db.damage.colors.crit.b, 0, "crit.b")
	eq(db.damage.colors.holy.b, 0.50, "holy.b")
	eq(db.damage.colors.fire.g, 0.50, "fire.g")
	eq(db.damage.colors.nature.r, 0.55, "nature.r")
	eq(db.damage.colors.nature.g, 0.75, "nature.g")
	eq(db.damage.colors.nature.b, 0.15, "nature.b")
	eq(db.damage.colors.frost.b, 1, "frost.b")
	eq(db.damage.colors.shadow.b, 0.90, "shadow.b")
	eq(db.damage.colors.arcane.r, 0.90, "arcane.r")
	eq(db.damage.colors.miss.r, 0.75, "miss.r")
	eq(db.damage.colors.heal, nil, "damage.heal")
	eq(db.heal.colors.heal.r, 0.20, "heal.r")
	eq(db.heal.colors.heal.g, 0.90, "heal.g")
	eq(db.heal.colors.heal.b, 0.55, "heal.b")
	eq(db.heal.colors.crit.g, 0.82, "heal.crit.g")
	eq(db.heal.colors.miss, nil, "heal.miss")
	eq(db.heal.colors.nature, nil, "heal.nature")
	eq(db.damage.colors.interrupt, nil, "interrupt")
end)

test("LoadDB reports an existing save", function()
	ns.LoadDB({})
	eq(ns.firstRun, false, "firstRun")
end)

test("LoadDB keeps an explicit disabled state", function()
	local db = ns.LoadDB({
		enabled = false,
		showMinimapButton = false,
		lockPosition = false,
		showDamage = false,
		showHealing = false,
		showMisses = false,
		showCombat = false,
	})
	eq(db.showMinimapButton, false, "showMinimapButton")
	eq(db.damage.enabled, false, "damage.enabled")
	eq(db.heal.enabled, false, "heal.enabled")
	eq(db.damage.lockPosition, false, "damage.lock")
	eq(db.heal.lockPosition, false, "heal.lock")
	eq(db.damage.showMisses, false, "showMisses")
	eq(db.damage.showCombat, false, "showCombat")
	eq(db.enabled, nil, "enabled")
end)

test("LoadDB clamps font size, line count, opacity, align, and position", function()
	local db = ns.LoadDB({
		fontSize = 80,
		critSize = 3,
		opacity = 0,
		fadeTime = 40,
		lines = 1,
		x = 9000,
		y = -9000,
		align = "NOPE",
		grow = "",
		point = "NOPE",
		relPoint = "",
		font = "",
	})
	eq(db.damage.fontSize, 32, "fontSize")
	eq(db.heal.fontSize, 32, "heal.fontSize")
	eq(db.damage.critSize, 10, "critSize")
	eq(db.damage.opacity, 10, "opacity")
	eq(db.damage.fadeTime, 10, "fadeTime")
	eq(db.heal.fadeTime, 10, "heal.fadeTime")
	eq(db.damage.lines, 4, "lines")
	eq(db.damage.x, 4000, "x")
	eq(db.damage.y, -4000, "damage.y")
	eq(db.heal.y, -4000, "heal.y")
	eq(db.damage.align, "RIGHT", "align")
	eq(db.damage.grow, "DOWN", "grow")
	eq(db.damage.point, "CENTER", "point")
	eq(db.damage.relPoint, "CENTER", "relPoint")
	eq(db.damage.font, "Friz Quadrata", "font")
end)

test("LoadDB keeps a media font name and clamps a high opacity", function()
	local db = ns.LoadDB({ font = "Ellesmere Display", opacity = 200, critSize = 80 })
	eq(db.damage.font, "Ellesmere Display", "font")
	eq(db.heal.font, "Ellesmere Display", "heal.font")
	eq(db.damage.opacity, 100, "opacity")
	eq(db.damage.critSize, 48, "critSize")
	eq(db.heal.critSize, 48, "heal.critSize")
end)

test("LoadDB fills a missing color table and clamps channels", function()
	local db = ns.LoadDB({})
	eq(db.damage.colors.fire.r, 1, "fire.r")
	eq(db.heal.colors.heal.r, 0.20, "heal.r")
	eq(db.heal.colors.heal.g, 0.90, "heal.g")
	eq(db.heal.colors.heal.b, 0.55, "heal.b")

	local patched = ns.LoadDB({
		colors = { physical = { r = 2, g = -1, b = "x" } },
	})
	eq(patched.damage.colors.physical.r, 1, "clamped.r")
	eq(patched.damage.colors.physical.g, 0, "clamped.g")
	eq(patched.damage.colors.physical.b, 1, "clamped.b")
	eq(patched.damage.colors.miss.r, 0.75, "miss.r")
	eq(patched.damage.colors.interrupt, nil, "interrupt")
end)

test("LoadDB retints the original nature and heal greens", function()
	local db = ns.LoadDB({
		version = 1,
		colors = {
			nature = { r = 0.30, g = 0.90, b = 0.30 },
			heal = { r = 0.30, g = 0.95, b = 0.45 },
			fire = { r = 0.2, g = 0.2, b = 0.2 },
		},
	})
	eq(db.damage.colors.nature.r, 0.55, "nature.r")
	eq(db.damage.colors.nature.g, 0.75, "nature.g")
	eq(db.damage.colors.nature.b, 0.15, "nature.b")
	eq(db.heal.colors.heal.r, 0.20, "heal.r")
	eq(db.heal.colors.heal.g, 0.90, "heal.g")
	eq(db.heal.colors.heal.b, 0.55, "heal.b")
	eq(db.damage.colors.fire.r, 0.2, "fire.r")
	eq(db.version, 3, "version")
	eq(db.colors, nil, "colors")
end)

test("LoadDB keeps a chosen nature color", function()
	local db = ns.LoadDB({
		version = 1,
		colors = { nature = { r = 1, g = 0, b = 0 } },
	})
	eq(db.damage.colors.nature.r, 1, "nature.r")
	eq(db.damage.colors.nature.g, 0, "nature.g")
	eq(db.damage.colors.nature.b, 0, "nature.b")
end)

test("LoadDB splits a version 2 save into two lists", function()
	local db = ns.LoadDB({
		version = 2,
		showDamage = false,
		showHealing = true,
		fontSize = 18,
		x = 10,
		y = 40,
		colors = {
			physical = { r = 0.1, g = 0.2, b = 0.3 },
			heal = { r = 0.4, g = 0.5, b = 0.6 },
			crit = { r = 0.7, g = 0.8, b = 0.9 },
		},
	})
	eq(db.damage.enabled, false, "damage.enabled")
	eq(db.heal.enabled, true, "heal.enabled")
	eq(db.damage.fontSize, 18, "fontSize")
	eq(db.heal.fontSize, 18, "heal.fontSize")
	eq(db.damage.x, 10, "x")
	eq(db.heal.x, 10, "heal.x")
	eq(db.damage.y, 40, "damage.y")
	eq(db.heal.y, -120, "heal.y")
	eq(db.damage.colors.physical.r, 0.1, "physical.r")
	eq(db.heal.colors.heal.g, 0.5, "heal.g")
	eq(db.damage.colors.crit.b, 0.9, "damage.crit")
	eq(db.heal.colors.crit.b, 0.9, "heal.crit")
	eq(db.damage.colors.crit ~= db.heal.colors.crit, true, "crit copies")
	eq(db.colors, nil, "colors")
	eq(db.fontSize, nil, "flat font")
	eq(db.version, 3, "version")
end)

test("LoadDB leaves a version 3 save in place", function()
	local db = ns.LoadDB({
		version = 3,
		damage = {
			enabled = true,
			y = 10,
			colors = { physical = { r = 0.2, g = 0.2, b = 0.2 } },
		},
		heal = {
			enabled = false,
			y = 20,
			colors = { heal = { r = 0.3, g = 0.3, b = 0.3 } },
		},
	})
	eq(db.damage.y, 10, "damage.y")
	eq(db.heal.y, 20, "heal.y")
	eq(db.heal.enabled, false, "heal.enabled")
	eq(db.damage.colors.physical.r, 0.2, "physical.r")
	eq(db.heal.colors.heal.r, 0.3, "heal.r")
	eq(db.version, 3, "version")
end)

test("LoadDB clamps the minimap position", function()
	eq(ns.LoadDB({ minimapIcon = { minimapPos = 400 } }).minimapIcon.minimapPos, 360, "minimapPos")
end)

if failed > 0 then
	print(string.format("%d passed, %d failed", passed, failed))
	os.exit(1)
end
print(string.format("%d passed", passed))
