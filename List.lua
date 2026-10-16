local _, ns = ...

-- Three scrolling lists. Lines are a fixed pool: a fight must not create a frame
-- per hit. OnUpdate runs only while a line is entering or fading.

local MAX_LINES = 24
-- Used when a line's width cannot be read, so the drag frame still has a size.
local SECRET_WIDTH = 120
-- The two fixed edges and the area they enclose. Lines grow away from that corner.
local THICK = 3
local MIN_ARM = 48
local HIT = 6
local FONT_FALLBACK = "Fonts\\FRIZQT__.TTF"
local HOLD = 4

-- Shown only while that list is unlocked and empty. Not scrolling slots.
local PREVIEWS = {
	damage = {
		{ "-1,902", "fire", true },
		{ "-1,284", "physical", false },
		{ "Dodge", "miss", false },
	},
	heal = {
		{ "+1,100", "heal", true },
		{ "+640", "heal", false },
	},
	status = {
		{ "+Combat", "combat", false },
		{ "-Combat", "combat", false },
	},
}
-- A new line fades and slides into place. Ease-out, then it sits still.
local ENTER = 0.15
local ENTER_SLIDE = 8

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

local function CreateList(key)
	local list = {
		fonts = {},
		slots = {},
		watchingFade = false,
		nudging = false,
		preview = {},
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

	local function Cfg()
		return ns.db and ns.db[key]
	end

	local function LineSize(crit)
		local cfg = Cfg()
		if not cfg then
			return 16
		end
		if crit then
			return cfg.critSize
		end
		return cfg.fontSize
	end

	local function SlotColor(name)
		local cfg = Cfg()
		local colors = cfg and cfg.colors
		local row = colors and colors[name]
		if type(row) ~= "table" then
			return 1, 1, 1
		end
		return row.r or 1, row.g or 1, row.b or 1
	end

	local function UseFont(fs, size)
		local cfg = Cfg()
		local path = ns.FontPath(cfg and cfg.font)
		if not fs:SetFont(path, size, "OUTLINE") then
			fs:SetFont(FONT_FALLBACK, size, "OUTLINE")
		end
	end

	local function PeakAlpha()
		local cfg = Cfg()
		local opacity = cfg and cfg.opacity
		if type(opacity) ~= "number" then
			return 1
		end
		return opacity / 100
	end

	local function FadeSpan()
		local cfg = Cfg()
		local fade = cfg and cfg.fadeTime
		if type(fade) ~= "number" or fade < 0 then
			return 1
		end
		return fade
	end

	local function EaseRemain(age)
		if age <= 0 then
			return 1
		end
		if age >= ENTER then
			return 0
		end
		local remain = 1 - age / ENTER
		return remain * remain
	end

	local function AlphaFor(born, now)
		local peak = PeakAlpha()
		local age = now - born
		local cfg = Cfg()
		if cfg and cfg.animate and age < ENTER then
			return peak * (1 - EaseRemain(age))
		end
		if age <= HOLD then
			return peak
		end
		local fade = FadeSpan()
		if fade <= 0 then
			return 0
		end
		local alpha = peak * (1 - (age - HOLD) / fade)
		if alpha < 0 then
			return 0
		end
		return alpha
	end

	local function Slide(age, growUp)
		local dist = ENTER_SLIDE * EaseRemain(age)
		if dist == 0 then
			return 0
		end
		if growUp then
			return -dist
		end
		return dist
	end

	local function Corner()
		local cfg = Cfg()
		local align = "LEFT"
		if cfg and cfg.align == "RIGHT" then
			align = "RIGHT"
		elseif cfg and cfg.align == "CENTER" then
			align = "CENTER"
		end
		local growUp = cfg and cfg.grow == "UP"
		local vertical = growUp and "BOTTOM" or "TOP"
		local fromPoint = vertical
		if align ~= "CENTER" then
			fromPoint = vertical .. align
		end
		return align, growUp, vertical, fromPoint
	end

	local function InsetX(align)
		if align == "RIGHT" then
			return -THICK
		end
		if align == "CENTER" then
			return 0
		end
		return THICK
	end

	local function Arm(length)
		if length < MIN_ARM then
			return MIN_ARM
		end
		return length
	end

	local function PlaceBorders(width, height)
		local align, _, _, corner = Corner()
		local armW = Arm(width)
		local armH = Arm(height)
		local body = list.body
		local edgeV = list.edgeV
		local edgeH = list.edgeH
		body:ClearAllPoints()
		body:SetSize(armW, armH)
		body:SetPoint(corner, list.frame, corner, 0, 0)
		edgeH:ClearAllPoints()
		edgeH:SetSize(armW, THICK)
		edgeH:SetPoint(corner, list.frame, corner, 0, 0)
		-- Center keeps one bar: the top when text grows down, the bottom when it grows up.
		if align == "CENTER" then
			edgeV:Hide()
			return
		end
		edgeV:ClearAllPoints()
		edgeV:SetSize(THICK, armH)
		edgeV:SetPoint(corner, list.frame, corner, 0, 0)
	end

	local function HasLive()
		local cfg = Cfg()
		if not cfg then
			return false
		end
		local count = cfg.lines
		for i = 1, count do
			if list.slots[i].active then
				return true
			end
		end
		return false
	end

	local function HidePreview()
		local rows = list.preview
		for i = 1, #rows do
			rows[i]:Hide()
		end
	end

	-- Sample lines fill an unlocked list that has nothing live on it.
	local function ShowPreview()
		local cfg = Cfg()
		if not cfg or not list.frame or not list.preview then
			return
		end
		if cfg.lockPosition or HasLive() then
			HidePreview()
			return
		end
		local samples = PREVIEWS[key]
		if not samples then
			HidePreview()
			return
		end
		local align, growUp, vertical, fromPoint = Corner()
		local ySign = growUp and 1 or -1
		local xInset = InsetX(align)
		local yInset = growUp and THICK or -THICK
		local peak = PeakAlpha()
		local y = 0
		local width = 0
		for i = 1, #list.preview do
			local fs = list.preview[i]
			local sample = samples[i]
			if sample then
				local crit = sample[3]
				local size = LineSize(crit)
				UseFont(fs, size)
				fs:SetJustifyH(align)
				fs:SetJustifyV(vertical)
				fs:SetText(sample[1])
				local colorName = crit and "crit" or sample[2]
				local r, g, b = SlotColor(colorName)
				fs:SetTextColor(r, g, b)
				fs:SetAlpha(peak)
				fs:ClearAllPoints()
				fs:SetPoint(fromPoint, list.frame, fromPoint, xInset, yInset + y * ySign)
				fs:Show()
				local textWidth = fs:GetStringWidth()
				if type(textWidth) == "number" and textWidth > width then
					width = textWidth
				end
				y = y + size
			else
				fs:Hide()
			end
		end
		PlaceBorders(width + THICK, y + THICK)
	end

	local function Paint()
		local cfg = Cfg()
		if not cfg or not list.frame then
			return
		end
		local count = cfg.lines
		local now = GetTime()
		local align, growUp, vertical, fromPoint = Corner()
		local ySign = growUp and 1 or -1
		local xInset = InsetX(align)
		local yInset = growUp and THICK or -THICK
		local y = 0
		local width = 0
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
				local age = now - slot.born
				local slide = 0
				if cfg.animate then
					slide = Slide(age, growUp)
				end
				fs:SetAlpha(AlphaFor(slot.born, now))
				fs:ClearAllPoints()
				fs:SetPoint(fromPoint, list.frame, fromPoint, xInset, yInset + y * ySign + slide)
				fs:Show()
				-- A secret string has no readable width. Skip the measure.
				if SecretBlocked(slot.text) then
					if SECRET_WIDTH > width then
						width = SECRET_WIDTH
					end
				else
					local textWidth = fs:GetStringWidth()
					if SecretBlocked(textWidth) then
						if SECRET_WIDTH > width then
							width = SECRET_WIDTH
						end
					elseif type(textWidth) == "number" and textWidth > width then
						width = textWidth
					end
				end
				y = y + size
			else
				fs:Hide()
				if i > count then
					slot.active = false
				end
			end
		end
		PlaceBorders(width + THICK, y + THICK)
		ShowPreview()
	end

	local function ApplyAlpha(now)
		local cfg = Cfg()
		if not cfg then
			return false
		end
		local count = cfg.lines
		local any = false
		for i = 1, count do
			local slot = list.slots[i]
			if slot.active then
				local fs = list.fonts[i]
				local alpha = AlphaFor(slot.born, now)
				-- The entrance starts at zero. That is not the line ending.
				if alpha <= 0 and not (cfg.animate and (now - slot.born) < ENTER) then
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
		local cfg = Cfg()
		if not cfg then
			return
		end
		local count = cfg.lines
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

	local function AnyEntering(now, cfg)
		if not cfg.animate then
			return false
		end
		local count = cfg.lines
		for i = 1, count do
			local slot = list.slots[i]
			if slot.active and (now - slot.born) < ENTER then
				return true
			end
		end
		return false
	end

	local function Nudge(now)
		local cfg = Cfg()
		if not cfg or not list.frame then
			return
		end
		local count = cfg.lines
		local align, growUp, _, fromPoint = Corner()
		local ySign = growUp and 1 or -1
		local xInset = InsetX(align)
		local yInset = growUp and THICK or -THICK
		local y = 0
		for i = 1, count do
			local slot = list.slots[i]
			if slot.active then
				local age = now - slot.born
				if age < ENTER then
					local fs = list.fonts[i]
					fs:ClearAllPoints()
					fs:SetPoint(fromPoint, list.frame, fromPoint, xInset, yInset + y * ySign + Slide(age, growUp))
				end
				y = y + LineSize(slot.crit)
			end
		end
	end

	local function Fade()
		local cfg = Cfg()
		if not cfg or not list.frame then
			return
		end
		local now = GetTime()
		local count = cfg.lines
		local life = HOLD + FadeSpan()
		local expired = false
		for i = 1, count do
			local slot = list.slots[i]
			if slot.active and (now - slot.born) >= life then
				slot.active = false
				expired = true
			end
		end
		local entering = AnyEntering(now, cfg)
		if expired then
			Compact()
		end
		if expired or (list.nudging and not entering) then
			Paint()
		elseif entering then
			Nudge(now)
		end
		list.nudging = entering
		if not ApplyAlpha(GetTime()) then
			list.watchingFade = false
			list.nudging = false
			list.frame:SetScript("OnUpdate", nil)
		end
	end

	local function StartFade()
		if list.watchingFade or not list.frame then
			return
		end
		list.watchingFade = true
		list.frame:SetScript("OnUpdate", list.fade)
	end

	local function SavePosition()
		local cfg = Cfg()
		if not cfg or not list.frame then
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
		cfg.point = point
		cfg.relPoint = relPoint
		cfg.x = x
		cfg.y = y
	end

	local function LockFromClick(_, button)
		local cfg = Cfg()
		if button ~= "RightButton" or not cfg or cfg.lockPosition then
			return
		end
		-- A locked list ignores the mouse, so this click can only lock. SetValue
		-- updates the checkbox, which is how the list unlocks.
		if list.lockSetting then
			list.lockSetting:SetValue(true)
			return
		end
		cfg.lockPosition = true
		list:ApplyLock()
	end

	local function OnEdgeEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Drag to move.")
		GameTooltip:AddLine("Right-click to lock.", 1, 1, 1)
		GameTooltip:Show()
	end

	local function OnEdgeLeave()
		GameTooltip:Hide()
	end

	local function OnEdgeDragStart()
		local cfg = Cfg()
		if not cfg or cfg.lockPosition or not list.frame then
			return
		end
		GameTooltip:Hide()
		list.frame:StartMoving()
	end

	local function OnEdgeDragStop()
		if not list.frame then
			return
		end
		list.frame:StopMovingOrSizing()
		SavePosition()
	end

	local function CreateHandle(parent, alpha)
		local handle = CreateFrame("Frame", nil, parent)
		handle:RegisterForDrag("LeftButton")
		handle:SetScript("OnEnter", OnEdgeEnter)
		handle:SetScript("OnLeave", OnEdgeLeave)
		handle:SetScript("OnDragStart", OnEdgeDragStart)
		handle:SetScript("OnDragStop", OnEdgeDragStop)
		handle:SetScript("OnMouseUp", LockFromClick)
		local tex = handle:CreateTexture(nil, "BACKGROUND")
		tex:SetColorTexture(0.05, 0.05, 0.07, alpha)
		tex:SetAllPoints()
		return handle
	end

	local function Bind()
		local cfg = Cfg()
		if not cfg or list.frame then
			return
		end
		local frame = CreateFrame("Frame", nil, UIParent)
		list.frame = frame
		-- Point-sized so the saved corner does not move when the lines change size.
		frame:SetSize(1, 1)
		frame:SetFrameStrata("MEDIUM")
		frame:SetClampedToScreen(true)
		frame:SetPoint(cfg.point, UIParent, cfg.relPoint, cfg.x, cfg.y)
		if not cfg.enabled then
			frame:Hide()
		end

		local level = frame:GetFrameLevel()
		list.body = CreateHandle(frame, 0.55)
		list.body:SetFrameLevel(level + 1)
		-- Above the fill and ignoring the mouse, so a drag in the middle hits the body.
		local textFrame = CreateFrame("Frame", nil, frame)
		textFrame:SetAllPoints()
		textFrame:EnableMouse(false)
		textFrame:SetFrameLevel(level + 2)
		list.edgeV = CreateHandle(frame, 0.9)
		list.edgeH = CreateHandle(frame, 0.9)
		list.edgeV:SetHitRectInsets(-HIT, -HIT, -HIT, -HIT)
		list.edgeH:SetHitRectInsets(-HIT, -HIT, -HIT, -HIT)
		list.edgeV:SetFrameLevel(level + 3)
		list.edgeH:SetFrameLevel(level + 3)
		PlaceBorders(0, 0)

		for i = 1, MAX_LINES do
			local fs = textFrame:CreateFontString(nil, "OVERLAY")
			UseFont(fs, cfg.fontSize)
			fs:SetWordWrap(false)
			fs:Hide()
			list.fonts[i] = fs
		end

		local samples = PREVIEWS[key]
		if samples then
			for i = 1, #samples do
				local fs = textFrame:CreateFontString(nil, "OVERLAY")
				fs:SetWordWrap(false)
				fs:Hide()
				list.preview[i] = fs
			end
		end

		-- Built when the frame is. Not per hit.
		list.fade = function()
			Fade()
		end
	end

	function list:ApplyLock()
		local cfg = Cfg()
		if not cfg or not list.frame then
			return
		end
		local locked = cfg.lockPosition
		local sideEdge = not locked and cfg.align ~= "CENTER"
		list.frame:SetMovable(not locked)
		list.body:EnableMouse(not locked)
		list.edgeV:EnableMouse(sideEdge)
		list.edgeH:EnableMouse(not locked)
		list.body:SetShown(not locked)
		list.edgeV:SetShown(sideEdge)
		list.edgeH:SetShown(not locked)
		if locked then
			GameTooltip:Hide()
		end
		ShowPreview()
	end

	function list:Refresh()
		if not Cfg() or not list.frame then
			return
		end
		Paint()
		list:ApplyLock()
	end

	function list:SetShown(shown)
		if not list.frame then
			if not shown then
				return
			end
			list:Init()
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
		local cfg = Cfg()
		if not cfg then
			return
		end
		local count = cfg.lines
		for n = 1, count do
			if list.slots[n].active then
				StartFade()
				return
			end
		end
	end

	function list:Init()
		if list.frame or not Cfg() then
			return
		end
		Bind()
		list:ApplyLock()
	end

	function list:AddLine(text, color, crit)
		if not Cfg() then
			return
		end
		if type(text) ~= "string" or text == "" then
			return
		end
		list:Init()
		if not list.frame then
			return
		end
		list.frame:Show()
		local cfg = Cfg()
		local count = cfg.lines
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

	return list
end

ns.damageList = CreateList("damage")
ns.healList = CreateList("heal")
ns.statusList = CreateList("status")

function ns.AddLine(list, text, color, crit)
	list:AddLine(text, color, crit)
end

function ns.InitLists()
	ns.damageList:Init()
	ns.healList:Init()
	ns.statusList:Init()
end

function ns.ShowTest()
	ns.AddLine(ns.statusList, "-Combat", "combat", false)
	ns.AddLine(ns.statusList, "+Combat", "combat", false)
	ns.AddLine(ns.damageList, "Dodge", "miss", false)
	ns.AddLine(ns.damageList, "-860", "nature", false)
	ns.AddLine(ns.damageList, "-1,284", "physical", false)
	ns.AddLine(ns.damageList, "-1,902", "fire", true)
	ns.AddLine(ns.healList, "+640", "heal", false)
	ns.AddLine(ns.healList, "+1,100", "heal", true)
end
