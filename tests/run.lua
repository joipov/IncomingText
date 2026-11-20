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
load("Power.lua")

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
	eq(db.damage.showCombat, nil, "damage.showCombat")
	eq(db.status.enabled, true, "status.enabled")
	eq(db.status.showCombat, true, "showCombat")
	eq(db.status.showDispels, nil, "showDispels")
	eq(db.status.lockPosition, true, "status.lock")
	eq(db.heal.showMisses, nil, "heal.showMisses")
	eq(db.status.showMisses, nil, "status.showMisses")
	eq(db.damage.fontSize, 16, "fontSize")
	eq(db.heal.fontSize, 16, "heal.fontSize")
	eq(db.damage.critSize, 22, "critSize")
	eq(db.damage.font, "Friz Quadrata", "font")
	eq(db.damage.opacity, 100, "opacity")
	eq(db.damage.fadeTime, 1, "fadeTime")
	eq(db.heal.fadeTime, 1, "heal.fadeTime")
	eq(db.damage.lines, 12, "lines")
	eq(db.damage.align, "RIGHT", "align")
	eq(db.damage.animate, true, "animate")
	eq(db.heal.animate, true, "heal.animate")
	eq(db.status.animate, true, "status.animate")
	eq(db.damage.grow, "DOWN", "grow")
	eq(db.damage.point, "CENTER", "point")
	eq(db.damage.relPoint, "CENTER", "relPoint")
	eq(db.damage.x, -260, "x")
	eq(db.damage.y, 80, "damage.y")
	eq(db.heal.y, -80, "heal.y")
	eq(db.status.y, -240, "status.y")
	eq(db.power.enabled, true, "power.enabled")
	eq(db.power.lockPosition, true, "power.lock")
	eq(db.power.x, 260, "power.x")
	eq(db.power.y, 80, "power.y")
	eq(db.power.percentMana, true, "percentMana")
	eq(db.power.percentRage, false, "percentRage")
	eq(db.power.percentEnergy, false, "percentEnergy")
	eq(db.power.percentFocus, false, "percentFocus")
	eq(db.power.showMisses, nil, "power.showMisses")
	eq(db.power.colors.mana.r, 0.25, "mana.r")
	eq(db.power.colors.mana.g, 0.50, "mana.g")
	eq(db.power.colors.mana.b, 1, "mana.b")
	eq(db.power.colors.rage.r, 0.90, "rage.r")
	eq(db.power.colors.rage.g, 0.20, "rage.g")
	eq(db.power.colors.energy.r, 1, "energy.r")
	eq(db.power.colors.energy.g, 0.95, "energy.g")
	eq(db.power.colors.focus.r, 1, "focus.r")
	eq(db.power.colors.focus.g, 0.55, "focus.g")
	eq(db.power.colors.physical, nil, "power.physical")
	eq(db.version, ns.DB_VERSION, "version")
	eq(ns.DB_VERSION, 7, "DB_VERSION")
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
	eq(db.heal.colors.crit.r, 0.50, "heal.crit.r")
	eq(db.heal.colors.crit.g, 1, "heal.crit.g")
	eq(db.heal.colors.crit.b, 0.75, "heal.crit.b")
	eq(db.heal.colors.miss, nil, "heal.miss")
	eq(db.heal.colors.nature, nil, "heal.nature")
	eq(db.damage.colors.interrupt, nil, "interrupt")
	eq(db.status.colors.combat, nil, "combat")
	eq(db.status.colors.combatIn.r, 1, "combatIn.r")
	eq(db.status.colors.combatIn.g, 0.2, "combatIn.g")
	eq(db.status.colors.combatIn.b, 0.2, "combatIn.b")
	eq(db.status.colors.combatOut.r, 0.25, "combatOut.r")
	eq(db.status.colors.combatOut.g, 0.9, "combatOut.g")
	eq(db.status.colors.combatOut.b, 0.35, "combatOut.b")
	eq(db.status.colors.dispel, nil, "status.dispel")
	eq(db.damage.colors.combat, nil, "damage.combat")
	eq(db.damage.colors.dispel, nil, "damage.dispel")
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
	eq(db.damage.showCombat, nil, "damage.showCombat")
	eq(db.status.showCombat, false, "showCombat")
	eq(db.status.showDispels, nil, "showDispels")
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

test("LoadDB keeps center alignment and a disabled entrance", function()
	local db = ns.LoadDB({
		version = 4,
		damage = { align = "CENTER", animate = false },
		heal = { align = "CENTER", animate = false },
		status = { align = "CENTER", animate = false },
	})
	eq(db.damage.align, "CENTER", "align")
	eq(db.heal.align, "CENTER", "heal.align")
	eq(db.status.align, "CENTER", "status.align")
	eq(db.damage.animate, false, "animate")
	eq(db.heal.animate, false, "heal.animate")
	eq(db.status.animate, false, "status.animate")
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
	eq(db.version, 7, "version")
	eq(db.colors, nil, "colors")
end)

test("LoadDB turns the original gold critical heal into a lighter green", function()
	local db = ns.LoadDB({
		version = 6,
		heal = { colors = { crit = { r = 1, g = 0.82, b = 0 } } },
		damage = { colors = { crit = { r = 1, g = 0.82, b = 0 } } },
	})
	eq(db.heal.colors.crit.r, 0.50, "heal.crit.r")
	eq(db.heal.colors.crit.g, 1, "heal.crit.g")
	eq(db.heal.colors.crit.b, 0.75, "heal.crit.b")
	eq(db.damage.colors.crit.r, 1, "damage.crit.r")
	eq(db.damage.colors.crit.g, 0.82, "damage.crit.g")
	eq(db.damage.colors.crit.b, 0, "damage.crit.b")
	eq(db.version, 7, "version")
end)

test("LoadDB keeps a chosen critical heal color", function()
	local db = ns.LoadDB({
		version = 6,
		heal = { colors = { crit = { r = 1, g = 0, b = 0 } } },
	})
	eq(db.heal.colors.crit.r, 1, "heal.crit.r")
	eq(db.heal.colors.crit.g, 0, "heal.crit.g")
	eq(db.heal.colors.crit.b, 0, "heal.crit.b")
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

test("LoadDB splits a version 2 save into damage and healing", function()
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
	eq(db.version, 7, "version")
	eq(db.damage.showCombat, nil, "damage.showCombat")
	eq(db.status.showCombat, true, "status.showCombat")
	eq(db.status.y, -240, "status.y")
end)

test("LoadDB moves Show combat off a version 3 save", function()
	local db = ns.LoadDB({
		version = 3,
		damage = {
			enabled = true,
			showCombat = false,
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
	eq(db.status.y, -240, "status.y")
	eq(db.heal.enabled, false, "heal.enabled")
	eq(db.damage.colors.physical.r, 0.2, "physical.r")
	eq(db.heal.colors.heal.r, 0.3, "heal.r")
	eq(db.damage.showCombat, nil, "damage.showCombat")
	eq(db.status.showCombat, false, "status.showCombat")
	eq(db.status.showDispels, nil, "showDispels")
	eq(db.version, 7, "version")
end)

test("LoadDB splits the combat color off a version 4 save", function()
	local db = ns.LoadDB({
		version = 4,
		status = {
			colors = { combat = { r = 0.1, g = 0.2, b = 0.3 } },
		},
	})
	eq(db.status.colors.combat, nil, "combat")
	eq(db.status.colors.combatIn.r, 1, "combatIn.r")
	eq(db.status.colors.combatIn.g, 0.2, "combatIn.g")
	eq(db.status.colors.combatIn.b, 0.2, "combatIn.b")
	eq(db.status.colors.combatOut.r, 0.25, "combatOut.r")
	eq(db.status.colors.combatOut.g, 0.9, "combatOut.g")
	eq(db.status.colors.combatOut.b, 0.35, "combatOut.b")
	eq(db.version, 7, "version")
end)

test("LoadDB clamps the minimap position", function()
	eq(ns.LoadDB({ minimapIcon = { minimapPos = 400 } }).minimapIcon.minimapPos, 360, "minimapPos")
end)

test("LoadDB adds the power list without moving the others", function()
	local db = ns.LoadDB({
		version = 5,
		damage = { x = 10, y = 20 },
		heal = { x = 11, y = 21 },
		status = { x = 12, y = 22 },
	})
	eq(db.damage.x, 10, "damage.x")
	eq(db.damage.y, 20, "damage.y")
	eq(db.heal.x, 11, "heal.x")
	eq(db.heal.y, 21, "heal.y")
	eq(db.status.x, 12, "status.x")
	eq(db.status.y, 22, "status.y")
	eq(db.power.enabled, true, "power.enabled")
	eq(db.power.x, 260, "power.x")
	eq(db.power.y, 80, "power.y")
	eq(db.power.percentMana, true, "percentMana")
	eq(db.power.percentRage, false, "percentRage")
	eq(db.power.percentEnergy, false, "percentEnergy")
	eq(db.power.percentFocus, false, "percentFocus")
	eq(db.version, 7, "version")
end)

test("LoadDB keeps power percent choices and a chosen mana color", function()
	local db = ns.LoadDB({
		version = 6,
		power = {
			percentMana = false,
			percentRage = true,
			x = 4,
			colors = { mana = { r = 0.1, g = 0.2, b = 0.3 } },
		},
	})
	eq(db.power.percentMana, false, "percentMana")
	eq(db.power.percentRage, true, "percentRage")
	eq(db.power.percentEnergy, false, "percentEnergy")
	eq(db.power.percentFocus, false, "percentFocus")
	eq(db.power.x, 4, "x")
	eq(db.power.colors.mana.r, 0.1, "mana.r")
	eq(db.power.colors.mana.g, 0.2, "mana.g")
	eq(db.power.colors.mana.b, 0.3, "mana.b")
	eq(db.power.colors.rage.r, 0.90, "rage.r")
	eq(db.power.colors.focus.g, 0.55, "focus.g")
end)

test("power text is a percent for mana and the cost itself for rage", function()
	local cfg = {
		percentMana = true,
		percentRage = false,
		percentEnergy = false,
		percentFocus = false,
	}
	local text, color = ns.FormatPowerLine(cfg, 320, 0, 4000)
	eq(text, "-8%", "mana percent")
	eq(color, "mana", "mana color")
	text, color = ns.FormatPowerLine(cfg, 120, 0, 4000)
	eq(text, "-3%", "lower rank")
	eq(color, "mana", "lower color")
	text, color = ns.FormatPowerLine(cfg, 15, 1, 100)
	eq(text, "-15", "rage")
	eq(color, "rage", "rage color")
	text, color = ns.FormatPowerLine(cfg, 40, 3)
	eq(text, "-40", "energy")
	eq(color, "energy", "energy color")
	text, color = ns.FormatPowerLine(cfg, 25, 2)
	eq(text, "-25", "focus")
	eq(color, "focus", "focus color")
	text, color = ns.FormatPowerLine(cfg, 10, 0, 4000)
	eq(text, "<1%", "under one percent")
	eq(color, "mana", "under color")
	eq(ns.FormatPowerLine(cfg, 0, 0, 4000), nil, "zero")
	eq(ns.FormatPowerLine(cfg, -8, 0, 4000), nil, "negative")
	eq(ns.FormatPowerLine(cfg, 15, 9, 100), nil, "unknown power")
	text, color = ns.FormatPowerLine(cfg, 200, 0)
	eq(text, "-200", "percent without a maximum")
	eq(color, "mana", "fallback color")
	cfg.percentRage = true
	text, color = ns.FormatPowerLine(cfg, 15, 1, 100)
	eq(text, "-15%", "rage percent")
	eq(color, "rage", "rage percent color")
	eq(ns.FormatPowerLine(nil, 15, 1, 100), nil, "no list")
end)

test("a tooltip cost line is the flat amount, and a percent or per-second line is not", function()
	local amount, power = ns.MatchPowerCost("120 Mana")
	eq(amount, 120, "mana")
	eq(power, 0, "mana power")
	amount, power = ns.MatchPowerCost("15 Rage")
	eq(amount, 15, "rage")
	eq(power, 1, "rage power")
	amount, power = ns.MatchPowerCost("1,250 mana")
	eq(amount, 1250, "comma")
	eq(power, 0, "comma power")
	amount, power = ns.MatchPowerCost("3% of base mana")
	eq(amount, nil, "percent amount")
	eq(power, 0, "percent power")
	amount, power = ns.MatchPowerCost("30 mana per sec")
	eq(amount, nil, "per second amount")
	eq(power, 0, "per second power")
	amount, power = ns.MatchPowerCost("hello")
	eq(amount, nil, "plain amount")
	eq(power, nil, "plain power")
end)

if failed > 0 then
	print(string.format("%d passed, %d failed", passed, failed))
	os.exit(1)
end
print(string.format("%d passed", passed))
