local _, ns = ...

-- Cost of one completed cast. GetSpellPowerCost is first, because it is the
-- cost the client is charging, including a temporary discount. A downrank
-- that API will not price falls back to that rank's own tooltip. A
-- per-second cost has no single total and is skipped. A secret amount is
-- dropped: it cannot be turned into text. The format helpers take plain
-- numbers, so the tests can load this file without a client.

local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue
local issecrettable = issecrettable
local canaccesstable = canaccesstable

local POWER_MANA = (Enum and Enum.PowerType and Enum.PowerType.Mana) or 0
local POWER_RAGE = (Enum and Enum.PowerType and Enum.PowerType.Rage) or 1
local POWER_FOCUS = (Enum and Enum.PowerType and Enum.PowerType.Focus) or 2
local POWER_ENERGY = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3

local COLOR_KEY = {
	[POWER_MANA] = "mana",
	[POWER_RAGE] = "rage",
	[POWER_FOCUS] = "focus",
	[POWER_ENERGY] = "energy",
}

local PERCENT_KEY = {
	[POWER_MANA] = "percentMana",
	[POWER_RAGE] = "percentRage",
	[POWER_FOCUS] = "percentFocus",
	[POWER_ENERGY] = "percentEnergy",
}

local TRACKED_POWER = {
	[POWER_MANA] = true,
	[POWER_RAGE] = true,
	[POWER_FOCUS] = true,
	[POWER_ENERGY] = true,
}

local RESOURCES = {
	{ power = POWER_MANA, word = "mana", costGlobal = "MANA_COST" },
	{ power = POWER_RAGE, word = "rage", costGlobal = "RAGE_COST" },
	{ power = POWER_FOCUS, word = "focus", costGlobal = "FOCUS_COST" },
	{ power = POWER_ENERGY, word = "energy", costGlobal = "ENERGY_COST" },
}

local function SecretBlocked(value)
	return issecretvalue and issecretvalue(value) and not (canaccessvalue and canaccessvalue(value))
end

local function CanIndex(value)
	if value == nil or SecretBlocked(value) then
		return false
	end
	if issecrettable and issecrettable(value) and not (canaccesstable and canaccesstable(value)) then
		return false
	end
	return true
end

local function ReadableNumber(value)
	if type(value) ~= "number" or SecretBlocked(value) or value ~= value then
		return nil
	end
	return value
end

local function ReadableString(value)
	if type(value) ~= "string" or SecretBlocked(value) or value == "" then
		return nil
	end
	return value
end

local function EscapePattern(text)
	return (text:gsub("[%(%)%.%+%-%*%?%[%]%^%$]", "%%%0"))
end

local function PatternFromFormat(fmt)
	if type(fmt) ~= "string" then
		return nil
	end
	local lower = fmt:lower()
	local startAt, stopAt = lower:find("%%d")
	if not startAt then
		startAt, stopAt = lower:find("%%%.?%d*[fg]")
	end
	if not startAt then
		return nil
	end
	local prefix = EscapePattern(lower:sub(1, startAt - 1))
	local suffix = EscapePattern(lower:sub(stopAt + 1))
	return "^" .. prefix .. "([%d,%.]+)" .. suffix
end

local function Normalize(text)
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	text = text:gsub("|T.-|t", ""):gsub("|H.-|h(.-)|h", "%1")
	text = text:gsub("(%d),(%d%d%d)", "%1%2"):gsub("(%d),(%d%d%d)", "%1%2")
	return text:lower()
end

for i = 1, #RESOURCES do
	local res = RESOURCES[i]
	local word = EscapePattern(res.word)
	res.patterns = {}
	local fromGlobal = PatternFromFormat(_G[res.costGlobal])
	if fromGlobal then
		res.patterns[#res.patterns + 1] = fromGlobal
	end
	res.patterns[#res.patterns + 1] = "^([%d,%.]+)%s*" .. word
	res.percentPattern = "^[%d%.]+%%.-" .. word
end

-- amount, powerType. A percent-of-base line and a per-second line return
-- the power with no amount, so the scan stops instead of reading a later
-- description line as the cost.
local function MatchCost(text)
	for i = 1, #RESOURCES do
		local res = RESOURCES[i]
		if text:find(res.percentPattern) then
			return nil, res.power
		end
	end
	for i = 1, #RESOURCES do
		local res = RESOURCES[i]
		for p = 1, #res.patterns do
			local num = text:match(res.patterns[p])
			if num then
				if text:find("per sec", 1, true) or text:find("per second", 1, true) then
					return nil, res.power
				end
				return tonumber((num:gsub(",", ""))), res.power
			end
		end
	end
	return nil
end

function ns.MatchPowerCost(text)
	if type(text) ~= "string" then
		return nil
	end
	return MatchCost(Normalize(text))
end

local function ReadCostEntry(entry)
	if not CanIndex(entry) then
		return nil
	end
	local powerType = ReadableNumber(entry.type)
	if not powerType or not TRACKED_POWER[powerType] then
		return nil
	end

	local secretAmount = SecretBlocked(entry.cost) or SecretBlocked(entry.minCost)
	local cost = ReadableNumber(entry.cost)
	local minCost = ReadableNumber(entry.minCost)
	-- cost may be 0 while minCost is the real flat cost. 0 is truthy in Lua.
	local amount = nil
	if cost and cost > 0 then
		amount = cost
	elseif minCost and minCost > 0 then
		amount = minCost
	end
	if not amount then
		return nil, nil, secretAmount or nil
	end

	local costPerSec = ReadableNumber(entry.costPerSec) or 0
	-- A per-second cost has no single cast total. A percent-of-base cost
	-- still carries the client's resolved flat amount in `cost`.
	if costPerSec ~= 0 then
		return nil
	end
	return amount, powerType
end

local function BestCostEntry(costs)
	if not CanIndex(costs) then
		return nil
	end
	-- Prefer an entry whose required aura is met. Otherwise still use a
	-- flat cost, so a stance ability shows.
	local fallbackAmount, fallbackType, anySecret
	for i = 1, #costs do
		local amount, powerType, secretAmount = ReadCostEntry(costs[i])
		if secretAmount then
			anySecret = true
		end
		if amount then
			local entry = costs[i]
			local requiredAuraID = ReadableNumber(entry.requiredAuraID)
			local hasAura = entry.hasRequiredAura
			local unmet = requiredAuraID and requiredAuraID > 0 and not SecretBlocked(hasAura) and hasAura == false
			if unmet then
				fallbackAmount = fallbackAmount or amount
				fallbackType = fallbackType or powerType
			else
				return amount, powerType
			end
		end
	end
	if fallbackAmount then
		return fallbackAmount, fallbackType
	end
	return nil, nil, anySecret or nil
end

local function DirectSpellCost(spellID)
	local getCosts = (C_Spell and C_Spell.GetSpellPowerCost) or GetSpellPowerCost
	if type(getCosts) ~= "function" then
		return nil
	end
	local ok, costs = pcall(getCosts, spellID)
	if not ok then
		return nil
	end
	-- No row at all is a downrank the API will not price. An unreadable
	-- row is a combat secret, and the tooltip must not stand in for it.
	if costs ~= nil and not CanIndex(costs) then
		return nil, nil, true
	end
	return BestCostEntry(costs)
end

local function TooltipForSpell(spellID)
	if not (C_TooltipInfo and C_TooltipInfo.GetSpellByID) then
		return nil
	end
	-- dontOverride keeps a lower rank from being replaced by the trained rank.
	local ok, data = pcall(C_TooltipInfo.GetSpellByID, spellID, false, true, true)
	if ok and CanIndex(data) then
		return data
	end
	if C_Spell and C_Spell.GetSpellLink and C_TooltipInfo.GetHyperlink then
		local linkOk, link = pcall(C_Spell.GetSpellLink, spellID)
		link = linkOk and ReadableString(link) or nil
		if link then
			local hyperOk, hyper = pcall(C_TooltipInfo.GetHyperlink, link)
			if hyperOk and CanIndex(hyper) then
				return hyper
			end
		end
	end
	return nil
end

local function TooltipSpellCost(spellID)
	local data = TooltipForSpell(spellID)
	if not data then
		return nil
	end
	local lines = data.lines
	if type(lines) ~= "table" or not CanIndex(lines) then
		return nil
	end
	-- The cost is near the title. A short scan keeps a description line
	-- that starts with a number and a resource word from being the cost.
	local count = #lines
	if count > 10 then
		count = 10
	end
	for i = 1, count do
		local line = lines[i]
		if CanIndex(line) then
			local text = ReadableString(line.leftText)
			if text then
				local amount, powerType = ns.MatchPowerCost(text)
				if powerType then
					if amount and amount > 0 then
						return amount, powerType
					end
					return nil
				end
			end
		end
	end
	return nil
end

--- Flat cost of this spell id, then that rank's tooltip when the API has
--- no row for it. A secret API amount is not replaced by the tooltip.
function ns.PlayerSpellCost(spellID)
	spellID = ReadableNumber(spellID)
	if not spellID or spellID <= 0 then
		return nil
	end
	local amount, powerType, secretAmount = DirectSpellCost(spellID)
	if amount then
		return amount, powerType
	end
	if secretAmount then
		return nil
	end
	return TooltipSpellCost(spellID)
end

local function PlayerMaxPower(powerType)
	if type(UnitPowerMax) ~= "function" then
		return nil
	end
	local ok, value = pcall(UnitPowerMax, "player", powerType)
	if not ok then
		return nil
	end
	return ReadableNumber(value)
end

--- "-8%", "-15", or "<1%". Nil when there is nothing to print.
--- maxPower is optional; a percent line reads UnitPowerMax when it is omitted.
function ns.FormatPowerLine(cfg, amount, powerType, maxPower)
	if type(cfg) ~= "table" then
		return nil
	end
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return nil
	end
	local color = COLOR_KEY[powerType]
	if not color then
		return nil
	end
	local percentKey = PERCENT_KEY[powerType]
	local usePercent = percentKey and cfg[percentKey] == true
	if usePercent then
		if type(maxPower) ~= "number" or maxPower ~= maxPower or maxPower <= 0 then
			maxPower = PlayerMaxPower(powerType)
		end
		if type(maxPower) == "number" and maxPower > 0 then
			local pct = math.floor((amount / maxPower) * 100 + 0.5)
			if pct < 1 then
				return "<1%", color
			end
			return "-" .. tostring(pct) .. "%", color
		end
	end
	return "-" .. tostring(math.floor(amount + 0.5)), color
end
