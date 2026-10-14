local _, ns = ...

-- How an outgoing spell is written on a line. No frames, so the tests can
-- load this file.

function ns.ShortSpellName(name)
	if type(name) ~= "string" or name == "" then
		return nil
	end
	local letters = {}
	local words = 0
	local take = true
	for i = 1, #name do
		local c = name:sub(i, i)
		if c:match("%a") then
			if take then
				letters[#letters + 1] = c:upper()
				words = words + 1
				take = false
			end
		elseif c ~= "'" then
			take = true
		end
	end
	if words < 2 then
		return name
	end
	return table.concat(letters)
end

function ns.SpellIconText(icon, size)
	if icon == "" or (type(icon) ~= "number" and type(icon) ~= "string") then
		return nil
	end
	local n = tonumber(size)
	if not n then
		n = 16
	end
	n = math.floor(n)
	if n < 1 then
		n = 1
	end
	return string.format("|T%s:%d|t", icon, n)
end

local ORDER_PARTS = {
	NUMBER = { "number" },
	NUMBER_NAME = { "number", "name" },
	NUMBER_ICON = { "number", "icon" },
	NUMBER_NAME_ICON = { "number", "name", "icon" },
	ICON_NUMBER = { "icon", "number" },
	ICON_NUMBER_NAME = { "icon", "number", "name" },
	ICON_NAME_NUMBER = { "icon", "name", "number" },
}

ns.LINE_ORDERS = {
	{ "NUMBER", "1,902" },
	{ "NUMBER_NAME", "1,902 Sinister Strike" },
	{ "NUMBER_ICON", "1,902, icon" },
	{ "NUMBER_NAME_ICON", "1,902 Sinister Strike, icon" },
	{ "ICON_NUMBER", "Icon, 1,902" },
	{ "ICON_NUMBER_NAME", "Icon, 1,902, Sinister Strike" },
	{ "ICON_NAME_NUMBER", "Icon, Sinister Strike, 1,902" },
}

-- A cast names damage only when it can hit an enemy, and a heal only when it
-- is helpful. A secret answer names nothing.
function ns.CastKind(harmful, helpful, secret)
	if secret then
		return nil
	end
	if harmful == true then
		return "damage"
	end
	if helpful == true then
		return "heal"
	end
	return nil
end

function ns.OrderHas(order, piece)
	local parts = ORDER_PARTS[order] or ORDER_PARTS.NUMBER_NAME
	for i = 1, #parts do
		if parts[i] == piece then
			return true
		end
	end
	return false
end

function ns.FormatLine(amount, name, icon, size, order, shorten, useIcon)
	local parts = ORDER_PARTS[order] or ORDER_PARTS.NUMBER_NAME
	local out = {}
	for i = 1, #parts do
		local piece = parts[i]
		local text
		if piece == "number" then
			text = amount
		elseif piece == "name" then
			if type(name) == "string" and name ~= "" then
				if shorten then
					text = ns.ShortSpellName(name)
				else
					text = name
				end
			end
		elseif piece == "icon" and useIcon then
			text = ns.SpellIconText(icon, size)
		end
		if type(text) == "string" and text ~= "" then
			out[#out + 1] = text
		end
	end
	if #out == 0 then
		return ""
	end
	return table.concat(out, " ")
end
