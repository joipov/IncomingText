local _, ns = ...

-- One scrolling list. Lines are a fixed pool: a fight must not create a frame
-- per hit. OnUpdate runs only while a line is fading.

local MAX_LINES = 24
-- Drag handle. Lines grow away from this corner.
local SQUARE = 48
local FONT_FALLBACK = "Fonts\\FRIZQT__.TTF"
local HOLD = 4
local FADE = 1

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
local GameTooltip = GameTooltip
local issecretvalue = issecretvalue
local canaccessvalue = canaccessvalue

local list = {
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

local function LineSize(crit)
	if crit then
		return ns.db.critSize
	end
	return ns.db.fontSize
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
	local choices = {}
	for i = 1, #BUILTIN_FONTS do
		local name = BUILTIN_FONTS[i][1]
		seen[name] = true
		choices[#choices + 1] = { name, name }
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
				choices[#choices + 1] = { name, name }
			end
		end
	end
	return choices
end

local function UseFont(fs, size)
	local path = ns.FontPath(ns.db.font)
	if not fs:SetFont(path, size, "OUTLINE") then
		fs:SetFont(FONT_FALLBACK, size, "OUTLINE")
	end
end

local function PeakAlpha()
	local opacity = ns.db and ns.db.opacity
	if type(opacity) ~= "number" then
		return 1
	end
	return opacity / 100
end

local function AlphaFor(born, now)
	local peak = PeakAlpha()
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

local function Paint()
	local count = ns.db.lines
	local now = GetTime()
	local align = ns.db.align == "RIGHT" and "RIGHT" or "LEFT"
	local growUp = ns.db.grow == "UP"
	local vertical = growUp and "BOTTOM" or "TOP"
	local ySign = growUp and 1 or -1
	local fromPoint = vertical .. align
	local toPoint = vertical .. (align == "RIGHT" and "LEFT" or "RIGHT")
	local y = 0
	for i = 1, MAX_LINES do
		local fs = list.fonts[i]
		local slot = list.slots[i]
		if i <= count and slot.active then
			local size = LineSize(slot.crit)
			UseFont(fs, size)
			fs:SetJustifyH(align)
			fs:SetJustifyV(vertical)
			fs:SetText(slot.text)
			local colorName = slot.crit and "crit" or slot.color
			local r, g, b = SlotColor(colorName)
			fs:SetTextColor(r, g, b)
			fs:SetAlpha(AlphaFor(slot.born, now))
			fs:ClearAllPoints()
			fs:SetPoint(fromPoint, list.frame, toPoint, 0, y * ySign)
			fs:Show()
			y = y + size
		else
			fs:Hide()
			if i > count then
				slot.active = false
			end
		end
	end
end

local function ApplyAlpha(now)
	local count = ns.db.lines
	local any = false
	for i = 1, count do
		local slot = list.slots[i]
		if slot.active then
			local fs = list.fonts[i]
			local alpha = AlphaFor(slot.born, now)
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

local function Compact()
	local count = ns.db.lines
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

local function Fade()
	local now = GetTime()
	local count = ns.db.lines
	local expired = false
	for i = 1, count do
		local slot = list.slots[i]
		if slot.active and (now - slot.born) >= HOLD + FADE then
			slot.active = false
			expired = true
		end
	end
	if expired then
		Compact()
		Paint()
	end
	if not ApplyAlpha(GetTime()) then
		list.watchingFade = false
		list.frame:SetScript("OnUpdate", nil)
	end
end

local function StartFade()
	if list.watchingFade then
		return
	end
	list.watchingFade = true
	list.frame:SetScript("OnUpdate", list.fade)
end

local function SavePosition()
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
	db.point = point
	db.relPoint = relPoint
	db.x = x
	db.y = y
end

local function Bind()
	local db = ns.db
	local frame = CreateFrame("Frame", nil, UIParent)
	list.frame = frame
	frame:SetSize(SQUARE, SQUARE)
	frame:SetFrameStrata("MEDIUM")
	frame:SetClampedToScreen(true)
	frame:SetPoint(db.point, UIParent, db.relPoint, db.x, db.y)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Drag to move.")
		GameTooltip:AddLine("Right-click to lock.", 1, 1, 1)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	frame:SetScript("OnDragStart", function()
		if not ns.db or ns.db.lockPosition then
			return
		end
		GameTooltip:Hide()
		frame:StartMoving()
	end)
	frame:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		SavePosition()
	end)
	-- A locked list ignores the mouse, so this click can only lock. SetValue
	-- updates the checkbox, which is how the list unlocks.
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
	if not db.enabled then
		frame:Hide()
	end

	local backdrop = frame:CreateTexture(nil, "BACKGROUND")
	backdrop:SetColorTexture(0.05, 0.05, 0.07, 0.55)
	backdrop:SetAllPoints()
	list.backdrop = backdrop

	for i = 1, MAX_LINES do
		local fs = frame:CreateFontString(nil, "OVERLAY")
		UseFont(fs, db.fontSize)
		fs:SetWordWrap(false)
		fs:Hide()
		list.fonts[i] = fs
	end

	-- Built when the frame is. Not per hit.
	list.fade = function()
		Fade()
	end
end

function ns.ApplyLock()
	if not ns.db or not list.frame then
		return
	end
	local locked = ns.db.lockPosition
	list.frame:EnableMouse(not locked)
	list.frame:SetMovable(not locked)
	list.backdrop:SetShown(not locked)
	if locked then
		GameTooltip:Hide()
	end
end

function ns.RefreshList()
	if not ns.db or not list.frame then
		return
	end
	Paint()
	ns.ApplyLock()
end

function ns.SetListShown(shown)
	if not list.frame then
		if not shown then
			return
		end
		ns.InitList()
		if not list.frame then
			return
		end
	end
	list.frame:SetShown(shown)
	if not shown then
		list.watchingFade = false
		list.frame:SetScript("OnUpdate", nil)
		return
	end
	local count = ns.db.lines
	for n = 1, count do
		if list.slots[n].active then
			StartFade()
			return
		end
	end
end

function ns.InitList()
	if list.frame or not ns.db then
		return
	end
	Bind()
	ns.ApplyLock()
end

function ns.AddLine(text, color, crit)
	if not ns.db or type(text) ~= "string" or text == "" then
		return
	end
	ns.InitList()
	list.frame:Show()
	local count = ns.db.lines
	for i = count, 2, -1 do
		CopySlot(list.slots[i], list.slots[i - 1])
	end
	local top = list.slots[1]
	top.text = text
	top.color = color or "physical"
	top.born = GetTime()
	top.crit = crit and true or false
	top.active = true
	Paint()
	StartFade()
end

function ns.ShowTest()
	ns.AddLine("Dodge", "miss", false)
	ns.AddLine("+640", "heal", false)
	ns.AddLine("1,284", "physical", false)
	ns.AddLine("1,902", "fire", true)
end
