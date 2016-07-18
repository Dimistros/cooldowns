CDC_Settings = {}

local R, D, L, U = 'R', 'D', 'L', 'U'
local ORIENTATIONS = {R, D, L, U}

local DEFAULT_SETTINGS = {
	active = true,
	locked = false,
	position = {UIParent:GetWidth()/2, UIParent:GetHeight()/2},
	orientation = R,
	ignoreList = '',
	clickThrough = false,
}

local method = {}

function method:LoadSettings()
	if not CDC_Settings[self.key] then
		self:CreateSettings()
	end
	self.settings = CDC_Settings[self.key]
	self:ApplySettings()
end

function method:CreateSettings()
	CDC_Settings[self.key] = {}
	for k, v in DEFAULT_SETTINGS do
		CDC_Settings[self.key][k] = v
	end
end

function method:CreateFrames()
	local frame = CreateFrame('Frame', nil, UIParent)
	self.frame = frame
	frame:SetWidth(32)
	frame:SetHeight(32)
	frame:SetFrameStrata('HIGH')
	frame:SetMovable(true)
	frame:SetToplevel(true)

	frame.button = CreateFrame('Button', nil, frame)
	frame.button:SetWidth(32)
	frame.button:SetHeight(40)
	frame.button:SetPoint('CENTER', 0, 8)
	frame.button:SetNormalTexture([[Interface\Buttons\UI-MicroButton-Abilities-Up.blp]])
	frame.button:RegisterForDrag('LeftButton')
	frame.button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	frame.button:SetScript('OnDragStart', function()
		self:OnDragStart()
	end)
	frame.button:SetScript('OnDragStop', function()
		self:OnDragStop()
	end)
	frame.button:SetScript('OnClick', function()
		self:OnClick()
	end)
	frame.button:SetScript('OnEnter', function()
		self:ButtonTooltip()
	end)
	frame.button:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)

	frame.CDFrames = {}
	for i=1,10 do
		tinsert(frame.CDFrames, self:CDFrame(frame))
	end

	frame:SetScript('OnUpdate', function()
		if self.settings.locked then
			self:Update()
		end
	end)
end

function method:CDFrame(parent)
	local frame = CreateFrame('Frame', nil, parent)
	frame:SetWidth(32)
	frame:SetHeight(32)
	frame:SetScript('OnEnter', function()
		self:CDTooltip()
	end)
	frame:SetScript('OnLeave', function()
		GameTooltip:Hide()
	end)
	frame.texture = frame:CreateTexture()
	frame.texture:SetAllPoints()
	frame.count = frame:CreateFontString()
	frame.count:SetFont([[Fonts\ARIALN.TTF]], 14, 'THICKOUTLINE')
	frame.count:SetWidth(32)
	frame.count:SetHeight(12)
	frame.count:SetPoint('BOTTOM', 0, 10)
	return frame
end

function method:ApplySettings()
	if self.settings.active then
		self.frame:Show()
	else
		self.frame:Hide()
	end

	if self.settings.locked then
		self:Lock()
	else
		self:Unlock()
	end

	for _, frame in self.frame.CDFrames do
		frame:EnableMouse(not self.settings.clickThrough)
	end

	self:PlaceFrames()
end

function method:PlaceFrames()
	self.frame:SetPoint('BOTTOMLEFT', unpack(self.settings.position))
	for i, frame in self.frame.CDFrames do
		frame:ClearAllPoints()
		local orientation, offset = self.settings.orientation, (i-1)*32
		if orientation == U then
			frame:SetPoint('BOTTOM', self.frame, 'TOP', 0, offset-3)
		elseif orientation == D then
			frame:SetPoint('TOP', self.frame, 'BOTTOM', 0, 3-offset)
		elseif orientation == L then
			frame:SetPoint('RIGHT', self.frame, 'LEFT', -offset, 0)
		elseif orientation == R then
			frame:SetPoint('LEFT', self.frame, 'RIGHT', offset, 0)
		end
	end
end

function method:Lock()
	self.frame.button:Hide()
	for _, frame in self.frame.CDFrames do
		frame:Hide()
	end
end

function method:Unlock()
	self.frame.button:Show()
	for i, frame in self.frame.CDFrames do
		frame.tooltip = {'test'..i, 'test'..i}
		frame.texture:SetTexture([[Interface\Icons\temp]])
		frame.count:SetText()
		frame:Show()
	end
end

function method:ButtonTooltip()
	GameTooltip_SetDefaultAnchor(GameTooltip, this)
	GameTooltip:AddLine(self.title)
	GameTooltip:AddLine('Left-click/drag to position', .8, .8, .8)
	GameTooltip:AddLine('Right-click to lock', .8, .8, .8)
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
				self.settings.orientation = ORIENTATIONS[mod(i,4)+1]
				break
			end
		end
		self:PlaceFrames()
	elseif arg1 == 'RightButton' then
		self.settings.locked = true
		self:ApplySettings()
	end
end

function method:OnDragStart()
	self.frame:StartMoving()
end

function method:OnDragStop()
	self.frame:StopMovingOrSizing()
	self.settings.position = {self.frame:GetLeft(), self.frame:GetBottom()}
end

function method:Ignored(name)
	for entry in string.gfind(self.settings.ignoreList, '[^,]+') do
		if strupper(entry) == strupper(name) then
			return true
		end
	end
end

function method:Update()
	local t = GetTime()
	local i = 1

	local temp = {}
	sort(self.CDs, function(a, b) local ta, tb = a.finish - t, b.finish - t return ta < tb or tb == ta and a.name < b.name end)
	for _, CD in self.CDs do
		local timeleft = CD.finish - t

		if timeleft > 0 then
			tinsert(temp, CD)
			if i <= 10 and not self:Ignored(CD.name) and (not CD.predicate or CD:predicate()) then
				local frame = self.frame.CDFrames[i]
				if timeleft <= 10 then
					local x = t*4/3
					frame.texture:SetAlpha((mod(floor(x),2) == 0 and x-floor(x) or 1-x+floor(x))*0.7+0.3)
					-- frame.texture:SetAlpha((math.sin(GetTime()*(4/3)*math.pi)+1)/2*.7+.3)
				else
					frame.texture:SetAlpha(1)
				end

				timeleft = ceil(timeleft)
				if timeleft >= 60 then
					timeleft = ceil((timeleft/60)*10)/10
					frame.count:SetTextColor(0, 1, 0)
				else
					frame.count:SetTextColor(1, 1, 0)
				end

				frame.texture:SetTexture([[Interface\Icons\]]..CD.texture)
				frame.count:SetText(timeleft)
				frame:Show()

				frame.tooltip = {CD.name, CD.info}

				i = i + 1
			end
		end
	end
	self.CDs = temp

	while i <= 10 do
		self.frame.CDFrames[i]:Hide()
		i = i + 1
	end	
end

function method:StartCD(CD)
	tinsert(self.CDs, CD)
end

function CDC_Frame(key, title)
	local self = {}
	for k, v in method do
		self[k] = v
	end

	self.key = key
	self.title = title
	self.CDs = {}

	self:CreateFrames()
	self:LoadSettings()

	return self
end