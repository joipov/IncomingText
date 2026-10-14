local _, ns = ...

-- Two scrolling lists. Lines are a fixed pool: a fight must not create a frame
-- per hit. Each frame's OnUpdate runs only while one of its lines is fading.

local MAX_LINES = 24
local WIDTH = 260
local FONT_FALLBACK = "Fonts\\FRIZQT__.TTF"
local HOLD = 4
local FADE = 1
local PAD = 4

local BUILTIN_FONTS = {
	{ "Friz Quadrata", FONT_FALLBACK },
	{ "Arial Narrow", "Fonts\\ARIALN.TTF" },
	{ "Skurri", "Fonts\\skurri.ttf" },
	{ "Morpheus", "Fonts\\MORPHEUS.TTF" },
}

local BUILTIN_PATH = {}
for i = 1, #BUILTIN_FONTS do
	BUILTIN_PATH[BUILTIN_FONTS[i][1]] = BUILTIN_FONTS[i][2]
end

local GetTime = GetTime
local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue

local function SecretBlocked(value)
	return issecretvalue(value) and not canaccessvalue(value)
end

local function CopySlot(dst, src)
	dst.text = src.text
	dst.color = src.color
	dst.born = src.born
	dst.crit = src.crit
	dst.active = src.active
end

local function NewList(prefix, keys)
	local list = {
		prefix = prefix,
		keys = keys,
		fonts = {},
		slots = {},
		watchingFade = false,
	}
	for i = 1, MAX_LINES do
		list.slots[i] = {
			text = "",
			color = "physical",
			born = 0,
			crit = false,
			active = false,
		}
	end
	return list
end

local lists = {
	NewList("in", {
		enabled = "inEnabled",
		font = "inFontSize",
		crit = "inCritSize",
		face = "inFont",
		opacity = "inOpacity",
		lines = "inLines",
		align = "inAlign",
		grow = "inGrow",
		point = "inPoint",
		relPoint = "inRelPoint",
		x = "inX",
		y = "inY",
	}),
	NewList("out", {
		enabled = "outEnabled",
		font = "outFontSize",
		crit = "outCritSize",
		face = "outFont",
		opacity = "outOpacity",
		lines = "outLines",
		align = "outAlign",
		grow = "outGrow",
		point = "outPoint",
		relPoint = "outRelPoint",
		x = "outX",
		y = "outY",
	}),
}

local incoming = lists[1]
local outgoing = lists[2]

local function LineSize(list, crit)
	if crit then
		return ns.db[list.keys.crit]
	end
	return ns.db[list.keys.font]
end

local function FrameHeight(list)
	local size = ns.db[list.keys.font]
	local crit = ns.db[list.keys.crit]
	if crit > size then
		size = crit
	end
	return math.floor(ns.db[list.keys.lines] * (size + 4) + 8)
end

local function SlotColor(name)
	local colors = ns.db.colors
	local row = colors and colors[name]
	if type(row) ~= "table" then
		return 1, 1, 1
	end
	return row.r or 1, row.g or 1, row.b or 1
end

local function Media()
	if not LibStub then
		return nil
	end
	return LibStub("LibSharedMedia-3.0", true)
end

function ns.FontPath(name)
	local path = BUILTIN_PATH[name]
	if path then
		return path
	end
	local media = Media()
	if media then
		local fetched = media:Fetch("font", name, true)
		if type(fetched) == "string" and fetched ~= "" then
			return fetched
		end
	end
	return FONT_FALLBACK
end

function ns.FontChoices()
	local seen = {}
	local list = {}
	for i = 1, #BUILTIN_FONTS do
		local name = BUILTIN_FONTS[i][1]
		seen[name] = true
		list[#list + 1] = { name, name }
	end
	local media = Media()
	if media then
		local names = media:List("font")
		if type(names) == "table" then
			local copy = {}
			for i = 1, #names do
				local name = names[i]
				if type(name) == "string" and name ~= "" and not seen[name] then
					copy[#copy + 1] = name
				end
			end
			table.sort(copy)
			for i = 1, #copy do
				local name = copy[i]
				seen[name] = true
				list[#list + 1] = { name, name }
			end
		end
	end
	return list
end

local function UseFont(fs, list, size)
	local path = ns.FontPath(ns.db[list.keys.face])
	if not fs:SetFont(path, size, "OUTLINE") then
		fs:SetFont(FONT_FALLBACK, size, "OUTLINE")
	end
end

local function SectionOn(list)
	return ns.db.enabled and ns.db[list.keys.enabled]
end

local function PeakAlpha(list)
	local opacity = ns.db and ns.db[list.keys.opacity]
	if type(opacity) ~= "number" then
		return 1
	end
	return opacity / 100
end

local function AlphaFor(list, born, now)
	local peak = PeakAlpha(list)
	local age = now - born
	if age <= HOLD then
		return peak
	end
	local alpha = peak * (1 - (age - HOLD) / FADE)
	if alpha < 0 then
		return 0
	end
	return alpha
end

local function Paint(list)
	local count = ns.db[list.keys.lines]
	local now = GetTime()
	local align = ns.db[list.keys.align] == "RIGHT" and "RIGHT" or "LEFT"
	local growUp = ns.db[list.keys.grow] == "UP"
	local anchor = (growUp and "BOTTOM" or "TOP") .. align
	local ySign = growUp and 1 or -1
	local x = align == "RIGHT" and -PAD or PAD
	local y = 0
	for i = 1, MAX_LINES do
		local fs = list.fonts[i]
		local slot = list.slots[i]
		if i <= count and slot.active then
			local size = LineSize(list, slot.crit)
			UseFont(fs, list, size)
			fs:SetWidth(WIDTH - PAD * 2)
			fs:SetJustifyH(align)
			fs:SetText(slot.text)
			local colorName = slot.crit and "crit" or slot.color
			local r, g, b = SlotColor(colorName)
			fs:SetTextColor(r, g, b)
			fs:SetAlpha(AlphaFor(list, slot.born, now))
			fs:ClearAllPoints()
			fs:SetPoint(anchor, list.frame, anchor, x, y * ySign)
			fs:Show()
			y = y + size + 2
		else
			fs:Hide()
			if i > count then
				slot.active = false
			end
		end
	end
end

local function ApplyAlpha(list, now)
	local count = ns.db[list.keys.lines]
	local any = false
	for i = 1, count do
		local slot = list.slots[i]
		if slot.active then
			local fs = list.fonts[i]
			local alpha = AlphaFor(list, slot.born, now)
			if alpha <= 0 then
				slot.active = false
				fs:Hide()
			else
				any = true
				fs:SetAlpha(alpha)
			end
		end
	end
	return any
end

local function Compact(list)
	local count = ns.db[list.keys.lines]
	local write = 1
	for read = 1, count do
		local src = list.slots[read]
		if src.active then
			if write ~= read then
				CopySlot(list.slots[write], src)
				src.active = false
			end
			write = write + 1
		end
	end
	for i = write, count do
		list.slots[i].active = false
	end
end

local function Fade(list)
	local now = GetTime()
	local count = ns.db[list.keys.lines]
	local expired = false
	for i = 1, count do
		local slot = list.slots[i]
		if slot.active and (now - slot.born) >= HOLD + FADE then
			slot.active = false
			expired = true
		end
	end
	if expired then
		Compact(list)
		Paint(list)
	end
	if not ApplyAlpha(list, GetTime()) then
		list.watchingFade = false
		list.frame:SetScript("OnUpdate", nil)
	end
end

local function StartFade(list)
	if list.watchingFade then
		return
	end
	list.watchingFade = true
	list.frame:SetScript("OnUpdate", list.fade)
end

local function SavePosition(list)
	local db = ns.db
	if not db or not list.frame then
		return
	end
	local point, _, relPoint, x, y = list.frame:GetPoint(1)
	if SecretBlocked(point) or SecretBlocked(relPoint) or SecretBlocked(x) or SecretBlocked(y) then
		return
	end
	if type(point) ~= "string" or type(relPoint) ~= "string" then
		return
	end
	if type(x) ~= "number" or type(y) ~= "number" then
		return
	end
	db[list.keys.point] = point
	db[list.keys.relPoint] = relPoint
	db[list.keys.x] = x
	db[list.keys.y] = y
end

local function Bind(list)
	local db = ns.db
	local frame = CreateFrame("Frame", nil, UIParent)
	list.frame = frame
	frame:SetSize(WIDTH, FrameHeight(list))
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetPoint(db[list.keys.point], UIParent, db[list.keys.relPoint], db[list.keys.x], db[list.keys.y])
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function()
		if not ns.db or ns.db.lockPosition then
			return
		end
		frame:StartMoving()
	end)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		SavePosition(list)
	end)
	-- A locked list ignores the mouse, so this click can only lock. SetValue
	-- updates the checkbox, which is how the lists unlock.
	frame:SetScript("OnMouseUp", function(_, button)
		if button ~= "RightButton" or not ns.db or ns.db.lockPosition then
			return
		end
		if ns.lockSetting then
			ns.lockSetting:SetValue(true)
			return
		end
		ns.db.lockPosition = true
		ns.ApplyLock()
	end)
	if not db.enabled or not db[list.keys.enabled] then
		frame:Hide()
	end

	local backdrop = frame:CreateTexture(nil, "BACKGROUND")
	backdrop:SetColorTexture(0.05, 0.05, 0.07, 0.55)
	backdrop:SetAllPoints()
	list.backdrop = backdrop

	-- Shown with the drag backdrop. It is the way back to a click-through list.
	local hint = frame:CreateFontString(nil, "OVERLAY")
	hint:SetFont(FONT_FALLBACK, 12, "OUTLINE")
	hint:SetPoint("CENTER")
	hint:SetText("Right-click to lock.")
	hint:SetTextColor(1, 1, 1)
	hint:Hide()
	list.hint = hint

	for i = 1, MAX_LINES do
		local fs = frame:CreateFontString(nil, "OVERLAY")
		UseFont(fs, list, db[list.keys.font])
		fs:Hide()
		list.fonts[i] = fs
	end

	-- One fade function per list, built when the frame is. Not per hit.
	list.fade = function()
		Fade(list)
	end
end

function ns.ApplyLock()
	if not ns.db then
		return
	end
	local locked = ns.db.lockPosition
	for i = 1, #lists do
		local list = lists[i]
		if list.frame then
			list.frame:EnableMouse(not locked)
			list.frame:SetMovable(not locked)
			list.backdrop:SetShown(not locked)
			if list.hint then
				list.hint:SetShown(not locked)
			end
		end
	end
end

function ns.RefreshList(which)
	if not ns.db then
		return
	end
	for i = 1, #lists do
		local list = lists[i]
		if list.frame and (not which or list.prefix == which) then
			list.frame:SetSize(WIDTH, FrameHeight(list))
			Paint(list)
		end
	end
	ns.ApplyLock()
end

function ns.SetListShown(shown)
	if not incoming.frame then
		if not shown then
			return
		end
		ns.InitList()
		if not incoming.frame then
			return
		end
	end
	for i = 1, #lists do
		local list = lists[i]
		local visible = shown and SectionOn(list)
		list.frame:SetShown(visible)
		if not visible then
			list.watchingFade = false
			list.frame:SetScript("OnUpdate", nil)
		else
			local count = ns.db[list.keys.lines]
			for n = 1, count do
				if list.slots[n].active then
					StartFade(list)
					break
				end
			end
		end
	end
end

function ns.InitList()
	if incoming.frame or not ns.db then
		return
	end
	for i = 1, #lists do
		Bind(lists[i])
	end
	ns.ApplyLock()
end

local function AddTo(list, text, color, crit)
	if not ns.db or type(text) ~= "string" or text == "" then
		return
	end
	ns.InitList()
	list.frame:Show()
	local count = ns.db[list.keys.lines]
	for i = count, 2, -1 do
		CopySlot(list.slots[i], list.slots[i - 1])
	end
	local top = list.slots[1]
	top.text = text
	top.color = color or "physical"
	top.born = GetTime()
	top.crit = crit and true or false
	top.active = true
	Paint(list)
	StartFade(list)
end

function ns.AddIncoming(text, color, crit)
	AddTo(incoming, text, color, crit)
end

function ns.AddOutgoing(text, color, crit)
	AddTo(outgoing, text, color, crit)
end

function ns.ShowTest()
	local icon = "Interface\\Icons\\INV_Sword_04"
	local order = ns.db.lineOrder
	local shorten = ns.OrderHas(order, "name") and ns.db.shortSpellNames
	local function sample(amount, name, crit, white)
		local size = ns.db.outFontSize
		if crit then
			size = ns.db.outCritSize
		end
		local useIcon = ns.OrderHas(order, "icon")
		if white then
			useIcon = useIcon and ns.db.iconWhite
			name = nil
		elseif crit then
			useIcon = useIcon and ns.db.iconCrits
		else
			useIcon = useIcon and ns.db.iconNormal
		end
		return ns.FormatLine(amount, name, icon, size, order, shorten, useIcon)
	end
	local function interrupted(name)
		local body = sample(nil, name, false, false)
		if body == "" then
			return "Interrupted"
		end
		return "Interrupted " .. body
	end
	ns.AddIncoming("Dodge", "miss", false)
	ns.AddIncoming("+640", "heal", false)
	ns.AddIncoming("1,284", "physical", false)
	ns.AddOutgoing(interrupted("Fireball"), "interrupt", false)
	ns.AddOutgoing(sample("+1,200", "Heal", false, false), "heal", false)
	ns.AddOutgoing(sample("1,902", "Fireball", true, false), "fire", true)
	ns.AddOutgoing(sample("842", nil, false, true), "physical", false)
end
