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
	eq(db.enabled, true, "enabled")
	eq(db.showMinimapButton, true, "showMinimapButton")
	eq(db.lockPosition, true, "lockPosition")
	eq(db.showDamage, true, "showDamage")
	eq(db.showHealing, true, "showHealing")
	eq(db.showMisses, true, "showMisses")
	eq(db.fontSize, 16, "fontSize")
	eq(db.critSize, 22, "critSize")
	eq(db.font, "Friz Quadrata", "font")
	eq(db.opacity, 100, "opacity")
	eq(db.lines, 12, "lines")
	eq(db.align, "RIGHT", "align")
	eq(db.grow, "DOWN", "grow")
	eq(db.point, "CENTER", "point")
	eq(db.relPoint, "CENTER", "relPoint")
	eq(db.x, -260, "x")
	eq(db.y, 80, "y")
	eq(db.version, ns.DB_VERSION, "version")
	eq(ns.DB_VERSION, 1, "DB_VERSION")
	eq(db.minimapIcon.minimapPos, 190, "minimapPos")
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
	eq(db.colors.interrupt, nil, "interrupt")
end)

test("LoadDB reports an existing save", function()
	ns.LoadDB({})
	eq(ns.firstRun, false, "firstRun")
end)

test("LoadDB keeps an explicit disabled state", function()
	local db = ns.LoadDB({ enabled = false, showMinimapButton = false, lockPosition = false, showDamage = false, showHealing = false, showMisses = false })
	eq(db.enabled, false, "enabled")
	eq(db.showMinimapButton, false, "showMinimapButton")
	eq(db.lockPosition, false, "lockPosition")
	eq(db.showDamage, false, "showDamage")
	eq(db.showHealing, false, "showHealing")
	eq(db.showMisses, false, "showMisses")
end)

test("LoadDB clamps font size, line count, opacity, align, and position", function()
	local db = ns.LoadDB({
		fontSize = 80,
		critSize = 3,
		opacity = 0,
		lines = 1,
		x = 9000,
		y = -9000,
		align = "NOPE",
		grow = "",
		point = "NOPE",
		relPoint = "",
		font = "",
	})
	eq(db.fontSize, 32, "fontSize")
	eq(db.critSize, 10, "critSize")
	eq(db.opacity, 10, "opacity")
	eq(db.lines, 4, "lines")
	eq(db.x, 4000, "x")
	eq(db.y, -4000, "y")
	eq(db.align, "RIGHT", "align")
	eq(db.grow, "DOWN", "grow")
	eq(db.point, "CENTER", "point")
	eq(db.relPoint, "CENTER", "relPoint")
	eq(db.font, "Friz Quadrata", "font")
end)

test("LoadDB keeps a media font name and clamps a high opacity", function()
	local db = ns.LoadDB({ font = "Ellesmere Display", opacity = 200, critSize = 80 })
	eq(db.font, "Ellesmere Display", "font")
	eq(db.opacity, 100, "opacity")
	eq(db.critSize, 48, "critSize")
end)

test("LoadDB fills a missing color table and clamps channels", function()
	local db = ns.LoadDB({})
	eq(db.colors.fire.r, 1, "fire.r")
	eq(db.colors.heal.g, 0.95, "heal.g")

	local patched = ns.LoadDB({
		colors = { physical = { r = 2, g = -1, b = "x" } },
	})
	eq(patched.colors.physical.r, 1, "clamped.r")
	eq(patched.colors.physical.g, 0, "clamped.g")
	eq(patched.colors.physical.b, 1, "clamped.b")
	eq(patched.colors.miss.r, 0.75, "miss.r")
	eq(patched.colors.interrupt, nil, "interrupt")
end)

test("LoadDB clamps the minimap position", function()
	eq(ns.LoadDB({ minimapIcon = { minimapPos = 400 } }).minimapIcon.minimapPos, 360, "minimapPos")
end)

if failed > 0 then
	print(string.format("%d passed, %d failed", passed, failed))
	os.exit(1)
end
print(string.format("%d passed", passed))
