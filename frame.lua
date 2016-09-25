cooldowns 'frame'

private.ORIENTATIONS = A('RU', 'RD', 'DR', 'DL', 'LD', 'LU', 'UL', 'UR')

private.DEFAULT_SETTINGS = T(
	'active', true,
	'locked', false,
	'x', UIParent:GetCenter(),
	'y', (temp-A(UIParent:GetCenter()))[2],
	'scale', 1,
	'size', 15,
	'line', 8,
	'spacing', .1,
	'orientation', 'RU',
	'skin', 'darion',
	'count', true,
	'blink', 0,
	'animation', false,
	'clickthrough', false,
	'ignoreList', ''
)

function public.new(title, color, settings)
	local self = t
	for k, v in method do self[k] = v end
	self.title = title
	self.color = color
	self.cooldowns = t
	self.iconFramePool = t
	self:Loadsettings(settings)
	return self
end

private.method = t

function method:Loadsettings(settings)
	for k, v in DEFAULT_SETTINGS do
		if settings[k] == nil then settings[k] = v end
	end
	self.settings = settings
	self:Configure()
end

function method:CreateFrames()
	if not self.frame then
		local frame = CreateFrame('Button', nil, UIParent)
		self.frame = frame
		frame:SetMovable(true)
		frame:SetToplevel(true)
		frame:SetClampedToScreen(true)
		frame:RegisterForDrag('LeftButton')
		frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
		frame:SetScript('OnDragStart', function() this:StartMoving() end)
		frame:SetScript('OnDragStop', function()
			this:StopMovingOrSizing()
			self.settings.x, self.settings.y = this:GetCenter()
		end)
		frame:SetScript('OnClick', function() self:OnClick() end) -- TODO string lambdas?
		frame:SetScript('OnEnter', function() self:Tooltip() end)
		frame:SetScript('OnLeave', function() GameTooltip:Hide() end)
		frame:SetScript('OnUpdate', function() return self.settings.locked and self:Update() end)
		frame.cd_frames = t
	end
	for i = getn(self.frame.cd_frames) + 1, self.settings.size do
		tinsert(self.frame.cd_frames, self:CDFrame())
	end
	for i = self.settings.size + 1, getn(self.frame.cd_frames) do
		self.frame.cd_frames[i]:Hide()
	end
	for i = 1, self.settings.size do
		local cd_frame = self.frame.cd_frames[i]
		skin(cd_frame, self.settings.skin)
		cd_frame:EnableMouse(not self.settings.clickthrough)
		cd_frame.cooldown:SetSequenceTime(0, 1000)
	end
	if not self.frame.arrow then
		local arrow = self.frame.cd_frames[1]:CreateTexture(nil, 'OVERLAY')
		arrow:SetTexture([[Interface\Buttons\UI-SortArrow]])
		arrow:SetPoint('CENTER', 0, 0)
		arrow:SetWidth(9)
		arrow:SetHeight(8)
		self.frame.arrow = arrow
	end
end

do
	local apply = {
		blizzard = function(frame)
			frame:SetWidth(33.5)
			frame:SetHeight(33.5)

			frame.icon:SetWidth(30)
			frame.icon:SetHeight(30)
			frame.icon:SetTexCoord(.07, .93, .07, .93)

			frame.border:Show()
			frame.border:SetPoint('CENTER', .5, -.5)
			frame.border:SetWidth(56)
			frame.border:SetHeight(56)
			frame.border:SetTexture([[Interface\Buttons\UI-Quickslot2]])
			frame.border:SetTexCoord(0, 1, 0, 1)
			frame.border:SetVertexColor(1, 1, 1)

			frame.gloss:Hide()

			frame.cooldown:SetScale(32.5/36)

			frame.label:SetFont(STANDARD_TEXT_FONT, 20, 'OUTLINE')
			frame.count:SetFont([[Fonts\ARIALN.ttf]], 15, 'THICKOUTLINE')
		end,
		zoomed = function(frame)
			frame:SetWidth(36)
			frame:SetHeight(36)

			frame.icon:SetWidth(36)
			frame.icon:SetHeight(36)
			frame.icon:SetTexCoord(.08, .92, .08, .92)

			frame.border:Hide()

			frame.gloss:Hide()

			frame.cooldown:SetScale(1.01)

			frame.label:SetFont(STANDARD_TEXT_FONT, 22, 'OUTLINE')
			frame.count:SetFont([[Fonts\ARIALN.ttf]], 17, 'THICKOUTLINE')
		end,
		elvui = function(frame)
			frame:SetWidth(36.5)
			frame:SetHeight(36.5)

			frame.icon:SetWidth(36)
			frame.icon:SetHeight(36)
			frame.icon:SetTexCoord(.07,.93,.07,.93)

			frame.border:Show()
			frame.border:SetPoint('CENTER', 0, 0)
			frame.border:SetWidth(38)
			frame.border:SetHeight(38)
			frame.border:SetTexture([[Interface\Addons\cooldowns\Textures\elvui\Border]])
			frame.border:SetTexCoord(0, 1, 0, 1)
			frame.border:SetVertexColor(0, 0, 0)

			frame.gloss:Hide()

			frame.cooldown:SetScale(38/36)

			frame.label:SetFont(STANDARD_TEXT_FONT, 22, 'OUTLINE')
			frame.count:SetFont([[Fonts\ARIALN.ttf]], 17, 'THICKOUTLINE')
		end,
		darion = function(frame)
			frame:SetWidth(34.5)
			frame:SetHeight(34.5)

			frame.icon:SetWidth(33)
			frame.icon:SetHeight(33)
			frame.icon:SetTexCoord(0, 1, 0, 1)

			frame.border:Show()
			frame.border:SetPoint('CENTER', 0, 0)
			frame.border:SetWidth(40)
			frame.border:SetHeight(40)
			frame.border:SetTexture([[Interface\Addons\cooldowns\Textures\darion\Border]])
			frame.border:SetTexCoord(0, 1, 0, 1)
			frame.border:SetVertexColor(.2, .2, .2)

			frame.gloss:Show()
			frame.gloss:SetWidth(40)
			frame.gloss:SetHeight(40)
			frame.gloss:SetTexture([[Interface\Addons\cooldowns\Textures\darion\Gloss]])
			frame.gloss:SetTexCoord(0, 1, 0, 1)

			frame.cooldown:SetScale(34/36)

			frame.label:SetFont(STANDARD_TEXT_FONT, 20, 'OUTLINE')
			frame.count:SetFont([[Fonts\ARIALN.ttf]], 15, 'THICKOUTLINE')
		end,
	}
	function private.skin(frame, skin)
		apply[skin](frame)
	end
end

function method:CDFrame()
	local frame = CreateFrame('Frame', nil, self.frame)
	frame:SetScript('OnEnter', function()
		self:CDTooltip()
	end)
	frame:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	frame.icon = frame:CreateTexture(nil, 'BORDER')
	frame.icon:SetPoint('CENTER', 0, 0)

	frame.background = frame:CreateTexture(nil, 'BACKGROUND')
	frame.background:SetAllPoints(frame.icon)
	frame.background:SetTexture(unpack(self.color))
	frame.background:SetAlpha(.6)

	frame.border = frame:CreateTexture(nil, 'ARTWORK')
	frame.border:SetPoint('CENTER', 0, 0)

	frame.gloss = frame:CreateTexture(nil, 'OVERLAY')
	frame.gloss:SetPoint('CENTER', 0, 0)

	frame.label = frame:CreateFontString(nil, 'OVERLAY')
	frame.label:SetPoint('CENTER', 0, 0)

	do
		local count_frame = CreateFrame('Frame', nil, frame)
		count_frame:SetFrameLevel(4)
		count_frame:SetAllPoints()
		frame.count = count_frame:CreateFontString()
		frame.count:SetPoint('CENTER', .7, 0)
	end

	do
		local cooldown = CreateFrame('Model', nil, frame, 'CooldownFrameTemplate')
		cooldown:ClearAllPoints()
		cooldown:SetPoint('CENTER', frame.icon, 'CENTER', .5, -.5)
		cooldown:SetWidth(36)
		cooldown:SetHeight(36)
		cooldown:SetScript('OnAnimFinished', nil)
		cooldown:SetScript('OnUpdateModel', function()
			if self.settings.animation and this.started then
				local progress = (GetTime() - this.started) / this.duration
				this:SetSequenceTime(0, (1 - progress) * 1000)
			end
		end)
		cooldown:Show()
		frame.cooldown = cooldown
	end
	frame.tooltip = t
	return frame
end

function method:Configure()
	self:CreateFrames()
	if self.settings.active then self.frame:Show() else self.frame:Hide() end
	if self.settings.locked then self:Lock() else self:Unlock() end
	self:PlaceFrames()
end

function method:PlaceFrames()
	local scale = self.settings.scale
	self.frame:SetScale(scale)
	local orientation = self.settings.orientation
	local axis1, axis2 = ret(strfind(orientation, '^[LR]') and A('x', 'y') or A('y', 'x'))
	local sign = temp-T(
		'x', (strfind(orientation, 'R') and 1 or -1),
		'y', (strfind(orientation, 'U') and 1 or -1)
	)
	local anchor = (strfind(orientation, 'D') and 'TOP' or 'BOTTOM') .. (strfind(orientation, 'R') and 'LEFT' or 'RIGHT')

	local size = self.frame.cd_frames[1]:GetWidth()

	local spacing = self.settings.spacing * size
	local slotSize = size + spacing

	self.frame:SetWidth(size)
	self.frame:SetHeight(size)
	
	for i = 1, self.settings.size do
		local frame = self.frame.cd_frames[i]
		frame:ClearAllPoints()
		local offset = temp-T(
			axis1, sign[axis1] * mod(i - 1, self.settings.line) * slotSize,
			axis2, sign[axis2] * floor((i - 1) / self.settings.line) * slotSize
		)
		frame:SetPoint(anchor, offset.x, offset.y)
	end

	self.frame:ClearAllPoints()
	self.frame:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', self.settings.x, self.settings.y)
end

function method:Lock()
	self.frame:EnableMouse(false)
	self.frame.arrow:Hide()
	for i = 1, self.settings.size do
		local frame = self.frame.cd_frames[i]
		frame.background:Hide()
		frame:Hide()
	end
end

do
	ROTATIONS = {
		D = 0,
		R = 1,
		U = 2,
		L = 3,
	}
	function method:Unlock()
		self.frame:EnableMouse(true)
		self.frame.arrow:Show()
		self.frame.arrow:SetTexCoord(0, .5625, 0, 1)
		rotate(self.frame.arrow, ROTATIONS[strsub(self.settings.orientation, 1, 1)])
		for i = 1, self.settings.size do
			local frame = self.frame.cd_frames[i]
			frame:EnableMouse(false)
			frame.background:Show()
			frame.label:SetText('')
			frame.count:SetText('')
			frame.cooldown:SetAlpha(0)
			if i == 1 then
				frame.icon:SetTexture('')
			else
				frame.icon:SetTexture([[Interface\Icons\INV_Misc_QuestionMark]])
				frame.icon:SetAlpha(.6)
			end
			frame:Show()
		end
	end
end

function method:Tooltip()
	GameTooltip_SetDefaultAnchor(GameTooltip, this)
	GameTooltip:AddLine(self.title)
	GameTooltip:AddLine('<Left Drag> move', 1, 1, 1)
	GameTooltip:AddLine('<Left Click> turn', 1, 1, 1)
	GameTooltip:AddLine('<Right Click> lock', 1, 1, 1)
	GameTooltip:Show()
end

function method:CDTooltip()
	GameTooltip:SetOwner(this, 'ANCHOR_RIGHT')
	GameTooltip:AddLine(this.tooltip[1])
	GameTooltip:AddLine(this.tooltip[2], .8, .8, .8, 1)
	GameTooltip:Show()
end

function method:OnClick()
	if arg1 == 'LeftButton' then
		for i, orientation in ORIENTATIONS do
			if orientation == self.settings.orientation then
				for _ = 1, (self.settings.size <= self.settings.line and 2 or 1) do
					i = mod(i, getn(ORIENTATIONS)) + 1
					self.settings.orientation = ORIENTATIONS[i]
				end
				break
			end
		end
	elseif arg1 == 'RightButton' then
		self.settings.locked = true
	end
	self:Configure()
end

function method:Ignored(name)
	return contains(strupper(self.settings.ignoreList), strupper(name))
end

function method:CDID(cooldown) return tostring(cooldown) end

function method:Update()
	local tm = GetTime()

	local cooldownList = tt
	for _, cooldown in self.cooldowns do tinsert(cooldownList, cooldown) end
	sort(cooldownList, function(a, b) local ta, tb = a.started + a.duration - tm, b.started + b.duration - tm return ta < tb or tb == ta and a.name < b.name end)

	local i = 1
	for _, cooldown in cooldownList do
		local timeLeft = cooldown.started + cooldown.duration - tm

		if timeLeft > 0 then
			if i <= self.settings.size and not self:Ignored(cooldown.name) then
				local frame = self.frame.cd_frames[i]
				do
					local alpha = timeLeft <= self.settings.blink and blink_alpha1(tm) or 1
					frame.icon:SetAlpha(alpha); frame.border:SetAlpha(alpha); frame.gloss:SetAlpha(alpha); frame.cooldown:SetAlpha(alpha)
				end
				frame.icon:SetTexture(cooldown.icon)
				frame.label:SetText(cooldown.label)
				frame.count:SetText(self.settings.count and time_text(timeLeft) or '')
				frame.cooldown.started, frame.cooldown.duration = cooldown.started, cooldown.duration
				init[frame.tooltip] = temp-A(cooldown.name, cooldown.info)
				frame:Show()

				i = i + 1
			end
		else
			self.cooldowns[self:CDID(cooldown)] = nil
		end
	end
	for j = i, self.settings.size do self.frame.cd_frames[j]:Hide() end
end

function method:StartCD(name, info, icon, started, duration, label)
	local cooldown = T(
		'name', name,
		'info', info,
		'icon', icon,
		'started', started,
		'duration', duration,
		'label', label or ''
	)
	self.cooldowns[self:CDID(cooldown)] = cooldown
	return self:CDID(cooldown)
end

function method:CancelCD(CDID)
	local cooldowns = self.cooldowns
	cooldowns[CDID] = cooldowns[CDID] and release(cooldowns[CDID])
end

function private.rotate(tex, n)
	for i = 1, n do
	    local x1, y1, x2, y2, x3, y3, x4, y4 = tex:GetTexCoord()
	    tex:SetTexCoord(x3, y3, x1, y1, x4, y4, x2, y2)
    end
end

function private.blink_alpha1(t)
	local x = t * 4/3
	return (mod(floor(x), 2) == 0 and x - floor(x) or 1 - x + floor(x)) * .7 + .3
end

function private.blink_alpha2(t)
	return (sin(t * 240) + 1) / 2 * .7 + .3
end

do
	local DAY, HOUR, MINUTE = 86400, 3600, 60

	function private.time_text(t)
		if t > HOUR then
			return color_code(.7, .7, .7) .. ceil(t / HOUR * 10) / 10
		elseif t > MINUTE then
			return color_code(0, 1, 0) .. ceil(t / MINUTE * 10) / 10
		elseif t > 5 then
			return color_code(1, 1, 0) .. ceil(t)
		else
			return color_code(1, 0, 0) .. ceil(t)
		end
	end
end

local bars = t

function private.bar(name, time, text, icon, color)
	text = text or name
	color = color or A(0, 1, 0, 1)

	local bar = t
	bars[name] = bar
	bar.name, bar.time, bar.text, bar.icon = name, time, text or name, icon
	bar.color = A(unpack(color))
	bar.color[4] = 1
	bar.running = nil
	bar.endtime = 0
	bar.fadetime = 1
	bar.fadeout = true
	bar.reversed = nil
	bar.frame = bar_frame(name)
end

function private.bar_frame(name)
	local bar = bars[name]

	local f = bar.frame

	local color = bar.color or A(1, 0, 1, 1)
	local bgcolor = A(0, .5, .5, .5)
	local icon = bar.icon or nil
	local iconpos = 'LEFT'
	local texture = [[Interface\TargetingFrame\UI-StatusBar]]
	local width = 200
	local height = 16
	local point = 'CENTER'
	local rframe = UIParent
	local rpoint = 'CENTER'
	local xoffset = 0
	local yoffset = 0
	local text = bar.text
	local fontsize = 11
	local textcolor = A(1, 1, 1, 1)
	local timertextcolor = A(1, 1, 1, 1)
	local scale = 1

	local timertextwidth = fontsize * 3.6
	local font, _, style = GameFontHighlight:GetFont()

	bar.width = 200
	bar.bgcolor = bgcolor
	bar.textcolor = textcolor
	bar.timertextcolor = timertextcolor
	bar.gradienttable = t

	f = CreateFrame('Button', nil, UIParent)

	f:Hide()
	f.owner = name

	f:SetWidth(width + height)
	f:SetHeight(height)
	f:ClearAllPoints()
	f:SetPoint(point, rframe, rpoint, xoffset, yoffset)

	f:EnableMouse(false)
	f:RegisterForClicks()
	f:SetScript('OnClick', nil)
	f:SetScale(scale)

	f.icon = CreateFrame('Button', nil, f)
	f.icon:ClearAllPoints()
	f.icon.owner = name
	f.icon:EnableMouse(false)
	f.icon:RegisterForClicks()
	f.icon:SetScript('OnClick', nil)
	-- an icno is square and the height of the bar, so yes 2x height there
	f.icon:SetHeight(height)
	f.icon:SetWidth(height)
	f.icon:SetPoint('LEFT', f, iconpos, 0, 0)
	f.icon:SetNormalTexture(icon)
	f.icon:GetNormalTexture():SetTexCoord(.08, .92, .08, .92)
--	if f.icon:GetNormalTexture() then
--		f.icon:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
--	end
	f.icon:SetAlpha(1)
	f.icon:Show()

	f.statusbarbg = CreateFrame('StatusBar', nil, f)
	f.statusbarbg:SetFrameLevel(f.statusbarbg:GetFrameLevel() - 1)
	f.statusbarbg:ClearAllPoints()
	f.statusbarbg:SetHeight(height)
	f.statusbarbg:SetWidth(width)
	-- offset the height of the frame on the x-axis for the icon.
	f.statusbarbg:SetPoint('TOPLEFT', f, 'TOPLEFT', height, 0)
	f.statusbarbg:SetStatusBarTexture(texture)
	f.statusbarbg:SetStatusBarColor(bgcolor[1], bgcolor[2], bgcolor[3], bgcolor[4])
	f.statusbarbg:SetMinMaxValues(0, 100)
	f.statusbarbg:SetValue(100)

	f.statusbar = CreateFrame('StatusBar', nil, f)
	f.statusbar:ClearAllPoints()
	f.statusbar:SetHeight(height)
	f.statusbar:SetWidth(width)
	-- offset the height of the frame on the x-axis for the icon.
	f.statusbar:SetPoint('TOPLEFT', f, 'TOPLEFT', height, 0)
	f.statusbar:SetStatusBarTexture(texture)
	f.statusbar:SetStatusBarColor(color[1], color[2], color[3], color[4])
	f.statusbar:SetMinMaxValues(0, 1)
	f.statusbar:SetValue(1)

	f.spark = f.statusbar:CreateTexture(nil, 'OVERLAY')
	f.spark:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
	f.spark:SetWidth(16)
	f.spark:SetHeight(height + 25)
	f.spark:SetBlendMode('ADD')
	f.spark:Show()

	f.timertext = f.statusbar:CreateFontString(nil, 'OVERLAY')
	f.timertext:SetFontObject(GameFontHighlight)
	f.timertext:SetFont(font, fontsize, style)
	f.timertext:SetHeight(height)
	f.timertext:SetWidth(timertextwidth)
	f.timertext:SetPoint('LEFT', f.statusbar, 'LEFT', 0, 0)
	f.timertext:SetJustifyH('RIGHT')
	f.timertext:SetText('')
	f.timertext:SetTextColor(timertextcolor[1], timertextcolor[2], timertextcolor[3], timertextcolor[4])

	f.text = f.statusbar:CreateFontString(nil, 'OVERLAY')
	f.text:SetFontObject(GameFontHighlight)
	f.text:SetFont(font, fontsize, style)
	f.text:SetHeight(height)
	f.text:SetWidth((width - timertextwidth) * .9)
	f.text:SetPoint('RIGHT', f.statusbar, 'RIGHT', 0, 0)
	f.text:SetJustifyH('LEFT')
	f.text:SetText(text)
	f.text:SetTextColor(textcolor[1], textcolor[2], textcolor[3], textcolor[4])

	if bar.onclick then
		f:EnableMouse(true)
		f:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp', 'Button4Up', 'Button5Up')
		f:SetScript('OnClick', function()
			CandyBar:OnClick()
		end)
		f.icon:EnableMouse(true)
		f.icon:RegisterForClicks('LeftButtonUp', 'RightButtonUp', 'MiddleButtonUp', 'Button4Up', 'Button5Up')
		f.icon:SetScript('OnClick', function()
			CandyBar:OnClick()
		end)
	end

	return f
end

function private.start_bar(name, fireforget)
	local bar = bars[name]

	local t = GetTime()
	if bar.paused then
		local pauseoffset = t - bar.pausetime
		bar.endtime = bar.endtime + pauseoffset
		bar.starttime = bar.starttime + pauseoffset
	else
		-- bar hasn't elapsed a second.
		bar.elapsed = 0
		bar.endtime = t + bar.time
		bar.starttime = t
	end
	bar.fireforget = fireforget
	bar.running = true
	bar.paused = nil
	bar.fading = nil
--	CandyBar:AcquireBarFrame(name) -- this will reset the barframe incase we were fading out when it was restarted
	bar.frame:Show()
--	if bar.group then
--		CandyBar:UpdateGroup(bar.group) -- update the group
--	end
--	CandyBar.frame:Show()
--	return true
end

function private.stop_bar(name)

	local bar = bars[name]

	bar.running = nil
	bar.paused = nil

	if bar.fadeout then
		bar.frame.spark:Hide()
		bar.fading = true
		bar.fadeelapsed = 0
		local t = GetTime()
		if bar.endtime > t then
			bar.endtime = t
		end
	else
		bar.frame:Hide()
		bar.starttime = nil
		bar.endtime = 0
--		if bar.group then
--			CandyBar:UpdateGroup(bar.group)
--		end
--		if bar.fireforget then
--			return CandyBar:Unregister(name)
--		end
	end
--	if not CandyBar:HasHandlers() then
--		CandyBar.frame:Hide()
--	end
	return true
end

function private.fade_bar(name)
	local bar = bars[name]

	if bar.fadeelapsed > bar.fadetime then
		bar.fading = nil
		bar.starttime = nil
		bar.endtime = 0
		bar.frame:Hide()
--		if bar.group then
--			CandyBar:UpdateGroup(bar.group)
--		end
--		if bar.fireforget then
--			return CandyBar:Unregister(name)
--		end
	else
		local t = bar.fadetime - bar.fadeelapsed
		local p = t / bar.fadetime
		local color = bar.color
		local bgcolor = bar.bgcolor
		local textcolor = bar.textcolor
		local timertextcolor = bar.timertextcolor
		local colora = color[4] * p
		local bgcolora = bgcolor[4] * p
		local textcolora = textcolor[4] * p
		local timertextcolora = timertextcolor[4] * p

		bar.frame.statusbarbg:SetStatusBarColor(bgcolor[1], bgcolor[2], bgcolor[3], bgcolora)
		bar.frame.statusbar:SetStatusBarColor(color[1], color[2], color[3], colora)
		bar.frame.text:SetTextColor(textcolor[1], textcolor[2], textcolor[3], textcolora)
		bar.frame.timertext:SetTextColor(timertextcolor[1], timertextcolor[2], timertextcolor[3], timertextcolora)
		bar.frame.icon:SetAlpha(p)
	end
end

function private.update_bar(name)
	local bar = bars[name]

	local t = bar.time - bar.elapsed

	local reversed = bar.reversed

	do
		local timetext
		local h = floor(t / 3600)
		local m = t - h * 3600
		m = floor(m / 60)
		local s = t - (h * 3600 + m * 60)
		if h > 0 then
			timetext = format('%d:%02d', h, m)
		elseif m > 0 then
			timetext = format('%d:%02d', m, floor(s))
		elseif s < 10 then
			timetext = format('%1.1f', s)
		else
			timetext = format('%.0f', floor(s))
		end
		bar.frame.timertext:SetText(timetext)
	end

	local perc = t / bar.time

	bar.frame.statusbar:SetValue(reversed and 1 - perc or perc)

	local sp =  bar.width * perc
	sp = reversed and -sp or sp
	bar.frame.spark:SetPoint('CENTER', bar.frame.statusbar, reversed and 'RIGHT' or 'LEFT', sp, 0)
end

CreateFrame('Frame'):SetScript('OnUpdate', function()
	local t = GetTime()
	for k, v in bars do
		if v.running then
			v.elapsed = t - v.starttime
			if v.endtime <= t then
				local c = bars[i]
--				if c.completion then
--					c.completion(getArgs(c, "completion", 1))
--				end
				stop_bar(k)
			else
				update_bar(k)
			end
		elseif v.fading then
			v.fadeelapsed = (t - v.endtime)
			fade_bar(k)
		end
	end
end)

--bar('kek', 10, 'kektext', [[Interface\Icons\INV_Misc_QuestionMark]], {1, 1, 1})
--start_bar('kek')