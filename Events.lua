local ADDON_NAME, ns = ...

-- One event frame. The combat log is closed, so a hit is only UNIT_COMBAT on
-- the player: action, crit flag, amount, and school.

local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue

local SCHOOL_NAME = {
	[1] = "physical",
	[2] = "holy",
	[4] = "fire",
	[8] = "nature",
	[16] = "frost",
	[32] = "shadow",
	[64] = "arcane",
}

local SCHOOL_BITS = { 1, 2, 4, 8, 16, 32, 64 }

local MISS_LABEL = {
	MISS = "Miss",
	DODGE = "Dodge",
	PARRY = "Parry",
	BLOCK = "Block",
	RESIST = "Resist",
	ABSORB = "Absorb",
	REFLECT = "Reflect",
	DEFLECT = "Deflect",
	IMMUNE = "Immune",
	EVADE = "Evade",
}

local eventFrame = CreateFrame("Frame")
local handlers = {}

local function SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end

local function PlainString(value)
	if type(value) ~= "string" or SecretBlocked(value) or value == "" then
		return nil
	end
	return value
end

local function PlainNumber(value)
	if type(value) ~= "number" or SecretBlocked(value) then
		return nil
	end
	return value
end

local function Print(message)
	print("|cff8b5cf6Joipov|r Incoming Text: " .. tostring(message or ""))
end

ns.Print = Print

function ns.Welcome()
	local title = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Incoming Text"
	local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
	print(string.format(
		"|cff8b5cf6Joipov|r %s (|cff22d3eev%s|r). Type |cffffffff/it|r to open settings.",
		title,
		version
	))
end

local function FormatAmount(amount)
	local n = math.floor(amount + 0.5)
	if n < 0 then
		n = -n
	end
	local text = tostring(n)
	local left = #text % 3
	if left == 0 then
		left = 3
	end
	local out = text:sub(1, left)
	local i = left + 1
	while i <= #text do
		out = out .. "," .. text:sub(i, i + 2)
		i = i + 3
	end
	return out
end

local function SchoolName(mask)
	local n = PlainNumber(mask)
	if not n then
		return "physical"
	end
	n = math.floor(n)
	local exact = SCHOOL_NAME[n]
	if exact then
		return exact
	end
	for i = 1, #SCHOOL_BITS do
		local bitValue = SCHOOL_BITS[i]
		local name = SCHOOL_NAME[bitValue]
		if name and bit.band(n, bitValue) == bitValue then
			return name
		end
	end
	return "physical"
end

local function IsCrit(flagText)
	return PlainString(flagText) == "CRITICAL"
end

local function DamageCfg()
	return ns.db and ns.db.damage
end

local function HealCfg()
	return ns.db and ns.db.heal
end

local function StatusCfg()
	return ns.db and ns.db.status
end

local function AddMiss(kind)
	local cfg = DamageCfg()
	if not cfg or not cfg.enabled or not cfg.showMisses then
		return
	end
	local label = MISS_LABEL[kind]
	if not label then
		return
	end
	ns.AddLine(ns.damageList, label, "miss", false)
end

local function AddDamage(amount, school, crit)
	local cfg = DamageCfg()
	if not cfg or not cfg.enabled then
		return
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return
	end
	ns.AddLine(ns.damageList, "-" .. FormatAmount(n), SchoolName(school), crit)
end

local function AddHeal(amount, crit)
	local cfg = HealCfg()
	if not cfg or not cfg.enabled then
		return
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return
	end
	ns.AddLine(ns.healList, "+" .. FormatAmount(n), "heal", crit)
end

local function AddCombat(entering)
	local cfg = StatusCfg()
	if not cfg or not cfg.enabled or not cfg.showCombat then
		return
	end
	if entering then
		ns.AddLine(ns.statusList, "+Combat", "combat", false)
	else
		ns.AddLine(ns.statusList, "-Combat", "combat", false)
	end
end

local function AddDispel(name)
	local cfg = StatusCfg()
	if not cfg or not cfg.enabled or not cfg.showDispels then
		return
	end
	if not SecretBlocked(name) then
		name = PlainString(name)
		if not name then
			return
		end
	elseif type(name) ~= "string" then
		return
	end
	ns.AddLine(ns.statusList, name, "dispel", false, "%s dispelled")
end

local function HandleCombat(unit, action, flagText, amount, school)
	if not ns.db then
		return
	end
	if PlainString(unit) ~= "player" then
		return
	end
	local kind = PlainString(action)
	if not kind then
		return
	end
	local crit = IsCrit(flagText)
	if kind == "WOUND" then
		AddDamage(amount, school, crit)
	elseif kind == "HEAL" then
		AddHeal(amount, crit)
	else
		AddMiss(kind)
	end
end

function ns.ApplyWatching()
	if not ns.db then
		return
	end
	eventFrame:UnregisterEvent("UNIT_COMBAT")
	eventFrame:UnregisterEvent("PLAYER_REGEN_DISABLED")
	eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	eventFrame:UnregisterEvent("COMBAT_TEXT_UPDATE")
	local damage = DamageCfg()
	local heal = HealCfg()
	local status = StatusCfg()
	ns.InitLists()
	if damage then
		ns.damageList:SetShown(damage.enabled)
	end
	if heal then
		ns.healList:SetShown(heal.enabled)
	end
	if status then
		ns.statusList:SetShown(status.enabled)
	end
	if (damage and damage.enabled) or (heal and heal.enabled) then
		eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player")
	end
	if status and status.enabled and status.showCombat then
		eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	if status and status.enabled and status.showDispels then
		C_CombatText.SetActiveUnit("player")
		eventFrame:RegisterEvent("COMBAT_TEXT_UPDATE")
	end
end

function handlers.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end
	eventFrame:UnregisterEvent("ADDON_LOADED")
	_G.IncomingTextDB = ns.LoadDB(_G.IncomingTextDB)
	ns.db = _G.IncomingTextDB
	ns.InitLists()
	ns.InitOptions()
	ns.ApplyWatching()
	eventFrame:RegisterEvent("PLAYER_LOGIN")
end

function handlers.PLAYER_LOGIN()
	ns.CreateMinimapButton()
	ns.Welcome()
end

function handlers.UNIT_COMBAT(unit, action, flagText, amount, school)
	HandleCombat(unit, action, flagText, amount, school)
end

function handlers.PLAYER_REGEN_DISABLED()
	AddCombat(true)
end

function handlers.PLAYER_REGEN_ENABLED()
	AddCombat(false)
end

function handlers.COMBAT_TEXT_UPDATE(kind)
	if PlainString(kind) ~= "SPELL_DISPELLED" then
		return
	end
	local name = C_CombatText.GetCurrentEventInfo()
	AddDispel(name)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	handlers[event](...)
end)
eventFrame:RegisterEvent("ADDON_LOADED")
