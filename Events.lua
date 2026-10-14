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

local function AddMiss(kind)
	if not ns.db.showMisses then
		return
	end
	local label = MISS_LABEL[kind]
	if not label then
		return
	end
	ns.AddLine(label, "miss", false)
end

local function AddDamage(amount, school, crit)
	if not ns.db.showDamage then
		return
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return
	end
	ns.AddLine(FormatAmount(n), SchoolName(school), crit)
end

local function AddHeal(amount, crit)
	if not ns.db.showHealing then
		return
	end
	local n = PlainNumber(amount)
	if not n or n <= 0 then
		return
	end
	ns.AddLine("+" .. FormatAmount(n), "heal", crit)
end

local function HandleCombat(unit, action, flagText, amount, school)
	if not ns.db or not ns.db.enabled then
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
	if not ns.db.enabled then
		ns.SetListShown(false)
		return
	end
	ns.InitList()
	ns.SetListShown(true)
	if ns.db.showDamage or ns.db.showHealing or ns.db.showMisses then
		eventFrame:RegisterUnitEvent("UNIT_COMBAT", "player")
	end
end

function handlers.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end
	eventFrame:UnregisterEvent("ADDON_LOADED")
	_G.IncomingTextDB = ns.LoadDB(_G.IncomingTextDB)
	ns.db = _G.IncomingTextDB
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

eventFrame:SetScript("OnEvent", function(_, event, ...)
	handlers[event](...)
end)
eventFrame:RegisterEvent("ADDON_LOADED")
