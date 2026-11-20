local ADDON_NAME, ns = ...

-- One event frame. The combat log is closed, so a hit is only UNIT_COMBAT on
-- the player: action, crit flag, amount, and school. A readable amount is
-- grouped with commas. A secret amount is signed and drawn as the client
-- prints it: it can be concatenated and handed to the font, not read.
-- A physical hit is white. Any other school uses that school's color.
-- A spell cost comes from the cast that lands, not from the power bar.

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

-- The sign is concatenated. A secret number stays secret, which the font
-- can draw, and a readable number is grouped first. A secret cannot be
-- compared, so a hidden 0 is shown rather than dropped.
local function DisplayAmount(sign, amount)
	if type(amount) == "number" and SecretBlocked(amount) then
		return sign .. amount
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return nil
	end
	return sign .. FormatAmount(n)
end

-- Plain Lua 5.1 has no bit library; the client supplies one, and the
-- arithmetic form is the same test for these single-bit values.
local function HasSchoolBit(n, bitValue)
	if bit and bit.band then
		return bit.band(n, bitValue) == bitValue
	end
	return math.floor(n / bitValue) % 2 == 1
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
		if name and HasSchoolBit(n, bitValue) then
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

local function PowerCfg()
	return ns.db and ns.db.power
end

-- Channel start and cast success for one spell arrive together. The same
-- cast guid, or the same spell a moment later, is one line.
local lastPowerGUID
local lastPowerID
local lastPowerTime
local POWER_DEDUPE = 0.25

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
	local text = DisplayAmount("-", amount)
	if not text then
		return
	end
	ns.AddLine(ns.damageList, text, SchoolName(school), crit)
end

local function AddHeal(amount, crit)
	local cfg = HealCfg()
	if not cfg or not cfg.enabled then
		return
	end
	local text = DisplayAmount("+", amount)
	if not text then
		return
	end
	ns.AddLine(ns.healList, text, "heal", crit)
end

local function AddCombat(entering)
	local cfg = StatusCfg()
	if not cfg or not cfg.enabled or not cfg.showCombat then
		return
	end
	if entering then
		ns.ReplaceLine(ns.statusList, "+Combat", "combatIn", false)
	else
		ns.ReplaceLine(ns.statusList, "-Combat", "combatOut", false)
	end
end

local function AddPower(castGUID, spellID)
	local cfg = PowerCfg()
	if not cfg or not cfg.enabled or not ns.powerList then
		return
	end
	local id = PlainNumber(spellID)
	if not id or id <= 0 then
		return
	end
	local amount, powerType = ns.PlayerSpellCost(id)
	local text, color = ns.FormatPowerLine(cfg, amount, powerType)
	if not text or not color then
		return
	end
	local guid = PlainString(castGUID)
	local now = PlainNumber(GetTime())
	if guid and guid == lastPowerGUID then
		return
	end
	if now and id == lastPowerID and type(lastPowerTime) == "number" and (now - lastPowerTime) < POWER_DEDUPE then
		return
	end
	lastPowerGUID = guid
	lastPowerID = id
	lastPowerTime = now
	ns.AddLine(ns.powerList, text, color, false)
end

local function HandleSpellCast(unit, castGUID, spellID)
	if PlainString(unit) ~= "player" then
		return
	end
	AddPower(castGUID, spellID)
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
	eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	eventFrame:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	local damage = DamageCfg()
	local heal = HealCfg()
	local status = StatusCfg()
	local power = PowerCfg()
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
	if power then
		ns.powerList:SetShown(power.enabled)
	end
	if (damage and damage.enabled) or (heal and heal.enabled) then
		eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player")
	end
	if status and status.enabled and status.showCombat then
		eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
	if power and power.enabled then
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
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

function handlers.UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
	HandleSpellCast(unit, castGUID, spellID)
end

function handlers.UNIT_SPELLCAST_CHANNEL_START(unit, castGUID, spellID)
	HandleSpellCast(unit, castGUID, spellID)
end

function handlers.PLAYER_REGEN_DISABLED()
	AddCombat(true)
end

function handlers.PLAYER_REGEN_ENABLED()
	AddCombat(false)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	handlers[event](...)
end)
eventFrame:RegisterEvent("ADDON_LOADED")
