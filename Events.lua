local ADDON_NAME, ns = ...

-- One event frame. The combat log is closed, so a hit is only UNIT_COMBAT:
-- action, crit flag, amount, and school. That event has no source and no spell.

local GetTime = GetTime
local C_Spell = C_Spell
local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue

local CAST_SLOTS = 4
-- A direct cast's damage arrives with the succeed event. A later tick is a
-- different hit and stays unlabeled.
local CAST_WINDOW = 0.4

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

local casts = {}
for i = 1, CAST_SLOTS do
	casts[i] = { time = 0, name = nil, icon = nil, kind = nil }
end
local castIndex = 1

-- A white hit has no spell. The swing that just fired names the weapon.
local SWING_SLOTS = 3
local MELEE_WINDOW = 0.6
local RANGED_WINDOW = 2
local swings = {}
for i = 1, SWING_SLOTS do
	swings[i] = { time = 0, icon = nil, ranged = false }
end
local swingWrite = 1

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
	print("|cff8b5cf6Joipov|r Combat Text: " .. tostring(message or ""))
end

ns.Print = Print

function ns.Debug(...)
	if not (ns.db and ns.db.debug) then
		return
	end
	local count = select("#", ...)
	local parts = {}
	for i = 1, count do
		parts[i] = tostring(select(i, ...))
	end
	Print(table.concat(parts, " "))
end

function ns.Welcome()
	local title = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title") or "Combat Text"
	local version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"
	print(string.format(
		"|cff8b5cf6Joipov|r %s (|cff22d3eev%s|r). Type |cffffffff/ct|r to open settings.",
		title,
		version
	))
end

local function TargetIsPlayer()
	local same = UnitIsUnit("target", "player")
	if SecretBlocked(same) then
		return false
	end
	return same == true
end

local function RecentSpell(kind)
	local now = GetTime()
	local bestTime = 0
	local bestName, bestIcon
	for i = 1, CAST_SLOTS do
		local slot = casts[i]
		if slot.kind == kind and slot.name and (now - slot.time) <= CAST_WINDOW and slot.time >= bestTime then
			bestTime = slot.time
			bestName = slot.name
			bestIcon = slot.icon
		end
	end
	return bestName, bestIcon
end

local function SpellTexture(spellID)
	if not C_Spell.GetSpellTexture then
		return nil
	end
	local icon = C_Spell.GetSpellTexture(spellID)
	if type(icon) ~= "number" and type(icon) ~= "string" then
		return nil
	end
	if SecretBlocked(icon) or icon == "" then
		return nil
	end
	return icon
end

local function ReadFlag(fn, spellID)
	if not fn then
		return false, false
	end
	local value = fn(spellID)
	if type(value) ~= "boolean" or SecretBlocked(value) then
		return false, true
	end
	return value, false
end

local function ReadCastKind(spellID)
	local harmful, secret = ReadFlag(C_Spell.IsSpellHarmful, spellID)
	if secret then
		return nil
	end
	local helpful = false
	if not harmful then
		helpful, secret = ReadFlag(C_Spell.IsSpellHelpful, spellID)
		if secret then
			return nil
		end
	end
	return ns.CastKind(harmful, helpful, false)
end

local function NoteCast(spellID)
	local id = PlainNumber(spellID)
	if not id then
		return
	end
	local kind = ReadCastKind(id)
	if not kind then
		return
	end
	local name = PlainString(C_Spell.GetSpellName(id))
	if not name then
		return
	end
	local slot = casts[castIndex]
	slot.time = GetTime()
	slot.name = name
	slot.icon = SpellTexture(id)
	slot.kind = kind
	castIndex = castIndex % CAST_SLOTS + 1
end

local function OutSize(crit)
	if crit then
		return ns.db.outCritSize
	end
	return ns.db.outFontSize
end

local function UseSpellIcon(crit)
	if not ns.OrderHas(ns.db.lineOrder, "icon") then
		return false
	end
	if crit then
		return ns.db.iconCrits and true or false
	end
	return ns.db.iconNormal and true or false
end

local function Compose(amount, name, icon, crit, useIcon)
	local shorten = ns.OrderHas(ns.db.lineOrder, "name") and ns.db.shortSpellNames
	return ns.FormatLine(amount, name, icon, OutSize(crit), ns.db.lineOrder, shorten, useIcon)
end

local function WeaponSlot(swingType)
	if type(swingType) ~= "number" or SecretBlocked(swingType) then
		return nil
	end
	if not Enum or not Enum.PlayerSwingType then
		return nil
	end
	local swing = Enum.PlayerSwingType
	if swingType == swing.MainHand then
		return 16
	elseif swingType == swing.OffHand then
		return 17
	elseif swingType == swing.Ranged then
		return 18
	end
	return nil
end

local function ItemTexture(slot)
	if not GetInventoryItemTexture then
		return nil
	end
	local icon = GetInventoryItemTexture("player", slot)
	if type(icon) ~= "number" and type(icon) ~= "string" then
		return nil
	end
	if SecretBlocked(icon) or icon == "" then
		return nil
	end
	return icon
end

local function NoteSwing(swingType)
	local slot = WeaponSlot(swingType)
	if not slot then
		return
	end
	local icon = ItemTexture(slot)
	if not icon then
		return
	end
	local row = swings[swingWrite]
	row.time = GetTime()
	row.icon = icon
	row.ranged = slot == 18
	swingWrite = swingWrite % SWING_SLOTS + 1
end

local function ClaimSwing()
	local now = GetTime()
	local oldest = math.huge
	local best
	for i = 1, SWING_SLOTS do
		local row = swings[i]
		if row.icon then
			local window = row.ranged and RANGED_WINDOW or MELEE_WINDOW
			local age = now - row.time
			if age >= 0 and age <= window and row.time < oldest then
				oldest = row.time
				best = row
			end
		end
	end
	if not best then
		return nil
	end
	local icon = best.icon
	best.icon = nil
	return icon
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

local function IsWhiteSchool(mask)
	local n = PlainNumber(mask)
	if not n then
		return false
	end
	return bit.band(math.floor(n), 1) == 1
end

local function IsCrit(flagText)
	return PlainString(flagText) == "CRITICAL"
end

local function AddLine(incoming, text, color, crit)
	if incoming then
		ns.AddIncoming(text, color, crit)
	else
		ns.AddOutgoing(text, color, crit)
	end
end

local function AddMiss(incoming, kind)
	if incoming and not ns.db.inShowMisses then
		return
	end
	if not incoming and not ns.db.outShowMisses then
		return
	end
	local label = MISS_LABEL[kind]
	if not label then
		return
	end
	AddLine(incoming, label, "miss", false)
end

local function AddDamage(incoming, amount, school, crit)
	if incoming and not ns.db.showIncomingDamage then
		return
	end
	if not incoming and not ns.db.showOutgoingDamage then
		return
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return
	end
	local text = FormatAmount(n)
	if not incoming then
		local name, icon = RecentSpell("damage")
		local useIcon = UseSpellIcon(crit)
		if not name and IsWhiteSchool(school) then
			name = nil
			icon = nil
			useIcon = false
			if ns.OrderHas(ns.db.lineOrder, "icon") and ns.db.iconWhite then
				icon = ClaimSwing()
				useIcon = icon ~= nil
			end
		end
		text = Compose(text, name, icon, crit, useIcon)
	end
	AddLine(incoming, text, SchoolName(school), crit)
end

local function AddHeal(incoming, amount, crit)
	if incoming and not ns.db.showIncomingHealing then
		return
	end
	if not incoming and not ns.db.showOutgoingHealing then
		return
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return
	end
	local text = "+" .. FormatAmount(n)
	if not incoming then
		local name, icon = RecentSpell("heal")
		text = Compose(text, name, icon, crit, UseSpellIcon(crit))
	end
	AddLine(incoming, text, "heal", crit)
end

local function HandleCombat(unit, action, flagText, amount, school)
	if not ns.db or not ns.db.enabled then
		return
	end
	local token = PlainString(unit)
	local kind = PlainString(action)
	if not token or not kind then
		return
	end
	local incoming = token == "player"
	if not incoming then
		if token ~= "target" or TargetIsPlayer() then
			return
		end
	end
	if incoming and not ns.db.inEnabled then
		return
	end
	if not incoming and not ns.db.outEnabled then
		return
	end
	local crit = IsCrit(flagText)
	if kind == "WOUND" then
		AddDamage(incoming, amount, school, crit)
	elseif kind == "HEAL" then
		AddHeal(incoming, amount, crit)
	else
		AddMiss(incoming, kind)
	end
end

local function HandleInterrupted(unit, spellID)
	if not ns.db or not ns.db.enabled then
		return
	end
	if not ns.db.outEnabled then
		return
	end
	if PlainString(unit) ~= "target" or TargetIsPlayer() then
		return
	end
	local text = "Interrupted"
	local id = PlainNumber(spellID)
	if id then
		local name = PlainString(C_Spell.GetSpellName(id))
		local body = Compose(nil, name, SpellTexture(id), false, UseSpellIcon(false))
		if body ~= "" then
			text = text .. " " .. body
		end
	end
	ns.AddOutgoing(text, "interrupt", false)
end

function ns.ApplyWatching()
	if not ns.db then
		return
	end
	eventFrame:UnregisterEvent("UNIT_COMBAT")
	eventFrame:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	eventFrame:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	eventFrame:UnregisterEvent("PLAYER_SWING")
	if not ns.db.enabled then
		ns.SetListShown(false)
		return
	end
	ns.InitList()
	ns.SetListShown(true)
	local incoming = ns.db.inEnabled and (ns.db.showIncomingDamage or ns.db.showIncomingHealing or ns.db.inShowMisses)
	local outgoing = ns.db.outEnabled and (ns.db.showOutgoingDamage or ns.db.showOutgoingHealing or ns.db.outShowMisses)
	if incoming and outgoing then
		eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player", "target")
	elseif incoming then
		eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player")
	elseif outgoing then
		eventFrame:RegisterUnitEvent("UNIT_COMBAT", "target")
	end
	local wantsHit = ns.db.showOutgoingDamage or ns.db.showOutgoingHealing
	local wantsIcon = ns.OrderHas(ns.db.lineOrder, "icon") and (ns.db.iconNormal or ns.db.iconCrits)
	if ns.db.outEnabled and wantsHit and (ns.OrderHas(ns.db.lineOrder, "name") or wantsIcon) then
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
	end
	if ns.db.outEnabled and ns.db.showOutgoingDamage and ns.db.iconWhite and ns.OrderHas(ns.db.lineOrder, "icon") then
		eventFrame:RegisterEvent("PLAYER_SWING")
	end
	if ns.db.outEnabled then
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target")
	end
end

function handlers.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end
	eventFrame:UnregisterEvent("ADDON_LOADED")
	_G.CombatTextDB = ns.LoadDB(_G.CombatTextDB)
	ns.db = _G.CombatTextDB
	ns.InitList()
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

function handlers.PLAYER_SWING(_, swingType)
	NoteSwing(swingType)
end

function handlers.UNIT_SPELLCAST_SUCCEEDED(_, _, spellID)
	NoteCast(spellID)
end

function handlers.UNIT_SPELLCAST_INTERRUPTED(unit, _, spellID)
	HandleInterrupted(unit, spellID)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	handlers[event](...)
end)
eventFrame:RegisterEvent("ADDON_LOADED")
