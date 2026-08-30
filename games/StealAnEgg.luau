--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162
--// Fully self-contained — no external HTTP fetches

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera

Player.CharacterAdded:Connect(function(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

local PlaceId = game.PlaceId
local GameName = tostring(PlaceId)
pcall(function()
	GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

local isLobby = false
pcall(function()
	isLobby = Workspace:FindFirstChild("Lobby") ~= nil
		or Workspace:FindFirstChild("lobby") ~= nil
		or Player.Character == nil
end)

local notifFolder = Instance.new("Folder")
notifFolder.Name = "IvoryNotifs"
notifFolder.Parent = Player:WaitForChild("PlayerGui")

--// ═══════════════════════════════════════════════════════════
--// INLINE OBSIDIAN-STYLE UI
--// ═══════════════════════════════════════════════════════════

local UI = {}
UI.__index = UI

local C = {
	Main = Color3.fromRGB(18, 14, 28),
	Accent = Color3.fromRGB(140, 110, 220),
	AccentDark = Color3.fromRGB(110, 80, 190),
	Outline = Color3.fromRGB(50, 40, 70),
	FontColor = Color3.fromRGB(225, 215, 245),
	SubText = Color3.fromRGB(155, 135, 185),
	Bright = Color3.fromRGB(32, 26, 48),
	Dark = Color3.fromRGB(12, 10, 20),
	Risky = Color3.fromRGB(220, 80, 120),
	Success = Color3.fromRGB(80, 200, 120),
}

local function addCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or C.Outline
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function addPadding(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 4)
	p.PaddingBottom = UDim.new(0, b or 4)
	p.PaddingLeft = UDim.new(0, l or 4)
	p.PaddingRight = UDim.new(0, r or 4)
	p.Parent = parent
	return p
end

function UI:Notify(title, desc, typ, time)
	task.spawn(function()
		local notif = Instance.new("Frame")
		notif.Size = UDim2.new(0, 260, 0, 60)
		notif.Position = UDim2.new(1, -270, 1, -70)
		notif.BackgroundColor3 = C.Main
		notif.BorderSizePixel = 0
		notif.Parent = notifFolder
		addCorner(notif, 6)
		addStroke(notif, C.Accent, 1)

		local accent = Instance.new("Frame")
		accent.Size = UDim2.new(0, 4, 1, 0)
		accent.BackgroundColor3 = typ == "Success" and C.Success or typ == "Error" and C.Risky or C.Accent
		accent.BorderSizePixel = 0
		accent.Parent = notif

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, -16, 0, 20)
		tl.Position = UDim2.new(0, 12, 0, 6)
		tl.BackgroundTransparency = 1
		tl.Text = title or "Ivory"
		tl.TextColor3 = C.FontColor
		tl.TextSize = 13
		tl.Font = Enum.Font.GothamBold
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.Parent = notif

		local dl = Instance.new("TextLabel")
		dl.Size = UDim2.new(1, -16, 0, 28)
		dl.Position = UDim2.new(0, 12, 0, 26)
		dl.BackgroundTransparency = 1
		dl.Text = desc or ""
		dl.TextColor3 = C.SubText
		dl.TextSize = 11
		dl.Font = Enum.Font.Gotham
		dl.TextXAlignment = Enum.TextXAlignment.Left
		dl.TextWrapped = true
		dl.Parent = notif

		task.wait(time or 3)
		local tween = TweenService:Create(notif, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Wait()
		notif:Destroy()
	end)
end

function UI.new(title)
	local self = setmetatable({}, UI)

	local gui = Instance.new("ScreenGui")
	gui.Name = "IvoryHub"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = Player:WaitForChild("PlayerGui")
	self.Gui = gui

	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(0, 520, 0, 380)
	main.Position = UDim2.new(0.5, -260, 0.5, -190)
	main.BackgroundColor3 = C.Main
	main.BorderSizePixel = 0
	main.Active = true
	main.Draggable = true
	main.Parent = gui
	addCorner(main, 6)
	addStroke(main, C.Outline, 1)
	self.Main = main

	local titleBar = Instance.new("Frame")
	titleBar.Size = UDim2.new(1, 0, 0, 32)
	titleBar.BackgroundColor3 = C.Dark
	titleBar.BorderSizePixel = 0
	titleBar.Parent = main
	addCorner(titleBar, 6)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0, 100, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title or "Ivory"
	titleLabel.TextColor3 = C.Accent
	titleLabel.TextSize = 15
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = titleBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 24, 0, 24)
	closeBtn.Position = UDim2.new(1, -30, 0, 4)
	closeBtn.BackgroundColor3 = C.Risky
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 12
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleBar
	addCorner(closeBtn, 4)
	closeBtn.MouseButton1Click:Connect(function()
		main.Visible = false
	end)

	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, 110, 1, -32)
	sidebar.Position = UDim2.new(0, 0, 0, 32)
	sidebar.BackgroundColor3 = C.Dark
	sidebar.BorderSizePixel = 0
	sidebar.Parent = main

	local sidebarList = Instance.new("UIListLayout")
	sidebarList.Padding = UDim.new(0, 2)
	sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
	sidebarList.Parent = sidebar

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -110, 1, -32)
	content.Position = UDim2.new(0, 110, 0, 32)
	content.BackgroundColor3 = C.Main
	content.BorderSizePixel = 0
	content.ClipsDescendants = true
	content.Parent = main

	self.Sidebar = sidebar
	self.Content = content
	self.Tabs = {}
	self.TabButtons = {}
	self.CurrentTab = nil
	self.Order = 0

	return self
end

function UI:AddTab(name, icon)
	self.Order = self.Order + 1
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 28)
	btn.BackgroundColor3 = Color3.new(0, 0, 0)
	btn.BackgroundTransparency = 1
	btn.Text = "  " .. name
	btn.TextColor3 = C.SubText
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.LayoutOrder = self.Order
	btn.Parent = self.Sidebar

	local tabContent = Instance.new("ScrollingFrame")
	tabContent.Name = name
	tabContent.Size = UDim2.new(1, -8, 1, -8)
	tabContent.Position = UDim2.new(0, 4, 0, 4)
	tabContent.BackgroundTransparency = 1
	tabContent.ScrollBarThickness = 3
	tabContent.ScrollBarImageColor3 = C.Accent
	tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
	tabContent.Visible = false
	tabContent.BorderSizePixel = 0
	tabContent.Parent = self.Content

	local tabList = Instance.new("UIListLayout")
	tabList.Padding = UDim.new(0, 4)
	tabList.SortOrder = Enum.SortOrder.LayoutOrder
	tabList.Parent = tabContent

	tabList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabContent.CanvasSize = UDim2.new(0, 0, 0, tabList.AbsoluteContentSize.Y + 8)
	end)

	local tabData = { Name = name, Content = tabContent, Groups = {}, Order = 0 }
	self.Tabs[name] = tabData
	self.TabButtons[name] = btn

	btn.MouseButton1Click:Connect(function()
		for n, t in pairs(self.Tabs) do
			t.Content.Visible = (n == name)
		end
		for n, b in pairs(self.TabButtons) do
			b.TextColor3 = (n == name) and C.Accent or C.SubText
			b.BackgroundColor3 = (n == name) and C.Bright or Color3.new(0, 0, 0)
			b.BackgroundTransparency = (n == name) and 0 or 1
		end
		self.CurrentTab = name
	end)

	if not self.CurrentTab then
		self.CurrentTab = name
		tabContent.Visible = true
		btn.TextColor3 = C.Accent
		btn.BackgroundColor3 = C.Bright
		btn.BackgroundTransparency = 0
	end

	return setmetatable({ UI = self, Data = tabData }, {
		__index = function(t, k)
			if k == "AddLeftGroupbox" or k == "AddRightGroupbox" then
				return function(_, groupName)
					return self:AddGroupbox(t.Data, groupName)
				end
			end
			return rawget(t, k)
		end
	})
end

function UI:AddGroupbox(tabData, groupName)
	tabData.Order = tabData.Order + 1

	local group = Instance.new("Frame")
	group.Size = UDim2.new(1, 0, 0, 0)
	group.AutomaticSize = Enum.AutomaticSize.Y
	group.BackgroundColor3 = C.Bright
	group.BorderSizePixel = 0
	group.LayoutOrder = tabData.Order
	group.Parent = tabData.Content
	addCorner(group, 4)
	addPadding(group, 6, 6, 6, 6)

	local groupList = Instance.new("UIListLayout")
	groupList.Padding = UDim.new(0, 3)
	groupList.SortOrder = Enum.SortOrder.LayoutOrder
	groupList.Parent = group

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = "  " .. groupName
	label.TextColor3 = C.Accent
	label.TextSize = 11
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.LayoutOrder = 0
	label.Parent = group

	local order = 0
	local function nextOrder()
		order = order + 1
		return order
	end

	local methods = {}

	function methods:AddToggle(id, opts)
		order = nextOrder()
		local togg = Instance.new("Frame")
		togg.Size = UDim2.new(1, 0, 0, 22)
		togg.BackgroundTransparency = 1
		togg.LayoutOrder = order
		togg.Parent = group

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(0.7, 0, 1, 0)
		tl.BackgroundTransparency = 1
		tl.Text = opts.Text or id
		tl.TextColor3 = C.FontColor
		tl.TextSize = 11
		tl.Font = Enum.Font.Gotham
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.Parent = togg

		local state = opts.Default or false
		local toggleBtn = Instance.new("TextButton")
		toggleBtn.Size = UDim2.new(0, 36, 0, 18)
		toggleBtn.Position = UDim2.new(1, -40, 0.5, -9)
		toggleBtn.BackgroundColor3 = state and C.Accent or C.Dark
		toggleBtn.Text = state and "ON" or "OFF"
		toggleBtn.TextColor3 = Color3.new(1, 1, 1)
		toggleBtn.TextSize = 9
		toggleBtn.Font = Enum.Font.GothamBold
		toggleBtn.Parent = togg
		addCorner(toggleBtn, 9)

		local function set(v)
			state = v
			toggleBtn.BackgroundColor3 = state and C.Accent or C.Dark
			toggleBtn.Text = state and "ON" or "OFF"
			if opts.Callback then opts.Callback(state) end
		end

		toggleBtn.MouseButton1Click:Connect(function()
			set(not state)
		end)

		if opts.Callback and state then opts.Callback(state) end

		return setmetatable({}, {
			__call = function(_, v) set(v) end,
			__index = { Set = set, Get = function() return state end }
		})
	end

	function methods:AddSlider(id, opts)
		order = nextOrder()
		local min = opts.Min or 0
		local max = opts.Max or 100
		local def = opts.Default or min
		local val = def

		local sf = Instance.new("Frame")
		sf.Size = UDim2.new(1, 0, 0, 32)
		sf.BackgroundTransparency = 1
		sf.LayoutOrder = order
		sf.Parent = group

		local sl = Instance.new("TextLabel")
		sl.Size = UDim2.new(0.55, 0, 0, 14)
		sl.BackgroundTransparency = 1
		sl.Text = opts.Text or id
		sl.TextColor3 = C.FontColor
		sl.TextSize = 11
		sl.Font = Enum.Font.Gotham
		sl.TextXAlignment = Enum.TextXAlignment.Left
		sl.Parent = sf

		local vl = Instance.new("TextLabel")
		vl.Size = UDim2.new(0.35, 0, 0, 14)
		vl.Position = UDim2.new(0.6, 0, 0, 0)
		vl.BackgroundTransparency = 1
		vl.Text = tostring(def)
		vl.TextColor3 = C.Accent
		vl.TextSize = 11
		vl.Font = Enum.Font.GothamBold
		vl.TextXAlignment = Enum.TextXAlignment.Right
		vl.Parent = sf

		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(0.95, 0, 0, 5)
		bg.Position = UDim2.new(0.025, 0, 0, 18)
		bg.BackgroundColor3 = C.Dark
		bg.Parent = sf
		addCorner(bg, 3)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
		fill.BackgroundColor3 = C.Accent
		fill.Parent = bg
		addCorner(fill, 3)

		local knob = Instance.new("TextButton")
		knob.Size = UDim2.new(0, 10, 0, 10)
		knob.Position = UDim2.new((def - min) / (max - min), -5, 0.5, -5)
		knob.BackgroundColor3 = Color3.new(1, 1, 1)
		knob.Text = ""
		knob.ZIndex = 2
		knob.Parent = bg
		addCorner(knob, 5)

		local dragging = false

		knob.MouseButton1Down:Connect(function() dragging = true end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local mp = UserInputService:GetMouseLocation()
				local pct = math.clamp((mp.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
				val = math.floor(min + (max - min) * pct)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				knob.Position = UDim2.new(pct, -5, 0.5, -5)
				vl.Text = tostring(val)
				if opts.Callback then opts.Callback(val) end
			end
		end)

		if opts.Callback then opts.Callback(def) end

		return setmetatable({}, {
			__call = function(_, v)
				val = math.clamp(v, min, max)
				local pct = (val - min) / (max - min)
				fill.Size = UDim2.new(pct, 0, 1, 0)
				knob.Position = UDim2.new(pct, -5, 0.5, -5)
				vl.Text = tostring(val)
			end,
			__index = { Set = function(_, v) val = math.clamp(v, min, max) end, Get = function() return val end }
		})
	end

	function methods:AddButton(text, callback)
		order = nextOrder()
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 24)
		btn.BackgroundColor3 = C.Accent
		btn.Text = text
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamMedium
		btn.LayoutOrder = order
		btn.Parent = group
		addCorner(btn, 4)

		btn.MouseButton1Click:Connect(function()
			pcall(callback)
		end)
		return btn
	end

	function methods:AddLabel(text)
		order = nextOrder()
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, 0, 0, 18)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = C.SubText
		l.TextSize = 11
		l.Font = Enum.Font.Gotham
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.LayoutOrder = order
		l.Parent = group
		return l
	end

	function methods:AddDivider()
		order = nextOrder()
		local d = Instance.new("Frame")
		d.Size = UDim2.new(1, 0, 0, 1)
		d.BackgroundColor3 = C.Outline
		d.BorderSizePixel = 0
		d.LayoutOrder = order
		d.Parent = group
	end

	function methods:AddDropdown(id, opts)
		order = nextOrder()
		local vals = opts.Values or {}
		local def = opts.Default or vals[1] or ""
		local sel = def

		local df = Instance.new("Frame")
		df.Size = UDim2.new(1, 0, 0, 22)
		df.BackgroundTransparency = 1
		df.LayoutOrder = order
		df.Parent = group

		local dl = Instance.new("TextLabel")
		dl.Size = UDim2.new(0.45, 0, 1, 0)
		dl.BackgroundTransparency = 1
		dl.Text = opts.Text or id
		dl.TextColor3 = C.FontColor
		dl.TextSize = 11
		dl.Font = Enum.Font.Gotham
		dl.TextXAlignment = Enum.TextXAlignment.Left
		dl.Parent = df

		local db = Instance.new("TextButton")
		db.Size = UDim2.new(0.5, 0, 0, 20)
		db.Position = UDim2.new(0.48, 0, 0.5, -10)
		db.BackgroundColor3 = C.Dark
		db.Text = " " .. def
		db.TextColor3 = C.FontColor
		db.TextSize = 10
		db.Font = Enum.Font.Gotham
		db.TextXAlignment = Enum.TextXAlignment.Left
		db.Parent = df
		addCorner(db, 3)

		local open = false
		local optsFrame = Instance.new("Frame")
		optsFrame.Size = UDim2.new(0.5, 0, 0, math.min(#vals * 20, 100))
		optsFrame.Position = UDim2.new(0.48, 0, 0, 22)
		optsFrame.BackgroundColor3 = C.Dark
		optsFrame.BorderSizePixel = 0
		optsFrame.Visible = false
		optsFrame.ZIndex = 10
		optsFrame.ClipsDescendants = true
		optsFrame.Parent = df
		addCorner(optsFrame, 3)

		local optsScroll = Instance.new("ScrollingFrame")
		optsScroll.Size = UDim2.new(1, 0, 1, 0)
		optsScroll.BackgroundTransparency = 1
		optsScroll.ScrollBarThickness = 2
		optsScroll.CanvasSize = UDim2.new(0, 0, 0, #vals * 20)
		optsScroll.ZIndex = 11
		optsScroll.Parent = optsFrame

		for _, v in ipairs(vals) do
			local ob = Instance.new("TextButton")
			ob.Size = UDim2.new(1, -4, 0, 18)
			ob.Position = UDim2.new(0, 2, 0, 0)
			ob.BackgroundColor3 = C.Bright
			ob.Text = " " .. v
			ob.TextColor3 = C.FontColor
			ob.TextSize = 10
			ob.Font = Enum.Font.Gotham
			ob.TextXAlignment = Enum.TextXAlignment.Left
			ob.ZIndex = 12
			ob.Parent = optsScroll
			addCorner(ob, 2)

			ob.MouseButton1Click:Connect(function()
				sel = v
				db.Text = " " .. v
				open = false
				optsFrame.Visible = false
				if opts.Callback then opts.Callback(v) end
			end)
		end

		db.MouseButton1Click:Connect(function()
			open = not open
			optsFrame.Visible = open
		end)

		if opts.Callback then opts.Callback(def) end
	end

	function methods:AddColorPicker(id, opts)
		order = nextOrder()
		local def = opts.Default or C.Accent
		local col = def

		local cf = Instance.new("Frame")
		cf.Size = UDim2.new(1, 0, 0, 22)
		cf.BackgroundTransparency = 1
		cf.LayoutOrder = order
		cf.Parent = group

		local cl = Instance.new("TextLabel")
		cl.Size = UDim2.new(0.65, 0, 1, 0)
		cl.BackgroundTransparency = 1
		cl.Text = opts.Text or id
		cl.TextColor3 = C.FontColor
		cl.TextSize = 11
		cl.Font = Enum.Font.Gotham
		cl.TextXAlignment = Enum.TextXAlignment.Left
		cl.Parent = cf

		local preset = {
			Color3.fromRGB(255, 215, 0),
			Color3.fromRGB(100, 255, 100),
			Color3.fromRGB(100, 200, 255),
			Color3.fromRGB(255, 100, 100),
			Color3.fromRGB(255, 100, 255),
			Color3.fromRGB(255, 165, 0),
		}

		local swatch = Instance.new("TextButton")
		swatch.Size = UDim2.new(0, 18, 0, 18)
		swatch.Position = UDim2.new(1, -22, 0.5, -9)
		swatch.BackgroundColor3 = def
		swatch.Text = ""
		swatch.Parent = cf
		addCorner(swatch, 3)
		addStroke(swatch, C.Outline, 1)

		local idx = 1
		for i, p in ipairs(preset) do
			if p == def then idx = i break end
		end

		swatch.MouseButton1Click:Connect(function()
			idx = idx % #preset + 1
			col = preset[idx]
			swatch.BackgroundColor3 = col
			if opts.Callback then opts.Callback(col) end
		end)

		if opts.Callback then opts.Callback(def) end
	end

	function methods:AddKeyPicker(id, opts)
		local kp = Instance.new("TextLabel")
		kp.Size = UDim2.new(1, 0, 0, 16)
		kp.BackgroundTransparency = 1
		kp.Text = (opts.Text or id) .. ": [None]"
		kp.TextColor3 = C.SubText
		kp.TextSize = 10
		kp.Font = Enum.Font.Gotham
		kp.TextXAlignment = Enum.TextXAlignment.Left
		kp.LayoutOrder = 999
		kp.Parent = group
		return kp
	end

	return methods
end

function UI:BuildFooter()
	local footer = Instance.new("Frame")
	footer.Size = UDim2.new(1, 0, 0, 18)
	footer.Position = UDim2.new(0, 0, 1, -18)
	footer.BackgroundColor3 = C.Dark
	footer.BorderSizePixel = 0
	footer.Parent = self.Main

	local footLabel = Instance.new("TextLabel")
	footLabel.Size = UDim2.new(1, -10, 1, 0)
	footLabel.Position = UDim2.new(0, 5, 0, 0)
	footLabel.BackgroundTransparency = 1
	footLabel.Text = "v1.4 | " .. (isLobby and "Lobby" or "Game") .. " | " .. tostring(Player.UserId)
	footLabel.TextColor3 = C.SubText
	footLabel.TextSize = 9
	footLabel.Font = Enum.Font.Gotham
	footLabel.TextXAlignment = Enum.TextXAlignment.Left
	footLabel.Parent = footer

	footLabel.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pcall(function() setclipboard(footLabel.Text) end)
			self:Notify("Ivory", "Copied to clipboard!", "Success", 2)
		end
	end)
end

--// ═══════════════════════════════════════════════════════════
--// STATE
--// ═══════════════════════════════════════════════════════════

local State = {
	AutoSteal = false,
	AutoStealRange = 50,
	AutoStealSpeed = 300,
	StealFromPlayers = true,
	StealFromNPCs = true,
	EggESP = false,
	EggESPColor = Color3.fromRGB(255, 215, 0),
	PetESP = false,
	PetESPColor = Color3.fromRGB(100, 255, 100),
	PlayerESP = false,
	PlayerESPColor = Color3.fromRGB(100, 200, 255),
	ChestESP = false,
	ChestESPColor = Color3.fromRGB(255, 100, 100),
	Speed_Enabled = false,
	Speed_Value = 16,
	JumpPower_Enabled = false,
	JumpPower_Value = 50,
	InfiniteJump = false,
	Noclip = false,
	ClickTeleport = false,
	AutoCollect = false,
	CollectRadius = 100,
	AutoHatch = false,
	AutoTrain = false,
	TrainSpeed = 100,
	AutoSell = false,
	SellThreshold = 10,
	AutoUpgrade = false,
	UpgradeType = "Speed",
	WalkOnWater = false,
	Fly_Enabled = false,
	Fly_Speed = 50,
	AntiAFK = false,
	FullBright = false,
	NoFog = false,
	FastMode = false,
}

--// ═══════════════════════════════════════════════════════════
--// BUILD UI
--// ═══════════════════════════════════════════════════════════

local Window = UI.new("Ivory")
Window:BuildFooter()

-- Main Tab
local MainTab = Window:AddTab("Main")
local InfoGroup = MainTab:AddLeftGroupbox("Info")
InfoGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
	UI:Notify("Ivory", "Discord link copied!", "Success", 3)
end)
InfoGroup:AddLabel("Game: " .. GameName)
InfoGroup:AddLabel("PlaceId: " .. PlaceId)
InfoGroup:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	UI:Notify("Ivory", "JobId copied!", "Success", 2)
end)

local ScriptGroup = MainTab:AddRightGroupbox("Status")
ScriptGroup:AddLabel("Ivory Hub v1.4")
ScriptGroup:AddLabel("Self-contained build")
ScriptGroup:AddLabel("No external HTTP")

-- Farm Tab
local FarmTab = Window:AddTab("Farm")

local StealSub = FarmTab:AddLeftGroupbox("Auto Steal")
StealSub:AddToggle("AutoSteal", { Text = "Enable Auto Steal", Default = false, Callback = function(v) State.AutoSteal = v end })
StealSub:AddToggle("StealFromPlayers", { Text = "Steal From Players", Default = true, Callback = function(v) State.StealFromPlayers = v end })
StealSub:AddButton("Steal Nearest Egg", function()
	task.spawn(function()
		local egg = findNearestEgg()
		if egg then
			tweenToTarget(egg.Position)
		else
			UI:Notify("Ivory", "No eggs found nearby", "Info", 2)
		end
	end)
end)

local StealSettings = FarmTab:AddRightGroupbox("Steal Settings")
StealSettings:AddSlider("AutoStealRange", { Text = "Steal Range", Default = 50, Min = 10, Max = 500, Rounding = 0, Callback = function(v) State.AutoStealRange = v end })
StealSettings:AddSlider("AutoStealSpeed", { Text = "Move Speed", Default = 300, Min = 50, Max = 1000, Rounding = 0, Callback = function(v) State.AutoStealSpeed = v end })

local FarmSub2 = FarmTab:AddLeftGroupbox("Auto Collect")
FarmSub2:AddToggle("AutoCollect", { Text = "Enable Auto Collect", Default = false, Callback = function(v) State.AutoCollect = v end })
FarmSub2:AddSlider("CollectRadius", { Text = "Collect Radius", Default = 100, Min = 10, Max = 500, Rounding = 0, Callback = function(v) State.CollectRadius = v end })

local FarmSub3 = FarmTab:AddRightGroupbox("Auto Hatch")
FarmSub3:AddToggle("AutoHatch", { Text = "Enable Auto Hatch", Default = false, Callback = function(v) State.AutoHatch = v end })

local FarmSub4 = FarmTab:AddLeftGroupbox("Auto Train")
FarmSub4:AddToggle("AutoTrain", { Text = "Enable Auto Train", Default = false, Callback = function(v) State.AutoTrain = v end })

local FarmSub5 = FarmTab:AddRightGroupbox("Sell & Upgrade")
FarmSub5:AddToggle("AutoSell", { Text = "Enable Auto Sell", Default = false, Callback = function(v) State.AutoSell = v end })
FarmSub5:AddSlider("SellThreshold", { Text = "Sell At (eggs)", Default = 10, Min = 1, Max = 100, Rounding = 0, Callback = function(v) State.SellThreshold = v end })
FarmSub5:AddToggle("AutoUpgrade", { Text = "Enable Auto Upgrade", Default = false, Callback = function(v) State.AutoUpgrade = v end })
FarmSub5:AddDropdown("UpgradeType", { Values = { "Speed", "Jump", "Capacity", "EggQuality" }, Default = "Speed", Text = "Upgrade Type", Callback = function(v) State.UpgradeType = v end })

-- Player Tab
local PlayerTab = Window:AddTab("Player")

local MovementGroup = PlayerTab:AddLeftGroupbox("Speed")
MovementGroup:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false, Callback = function(v)
	State.Speed_Enabled = v
	if not v then pcall(function() Humanoid.WalkSpeed = 16 end) end
end })
MovementGroup:AddSlider("SpeedValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 500, Rounding = 0, Callback = function(v) State.Speed_Value = v end })

local JumpGroup = PlayerTab:AddRightGroupbox("Jump")
JumpGroup:AddToggle("JumpPowerEnabled", { Text = "Enable Jump Power", Default = false, Callback = function(v)
	State.JumpPower_Enabled = v
	if not v then pcall(function() Humanoid.JumpPower = 50 end) end
end })
JumpGroup:AddSlider("JumpPowerValue", { Text = "Jump Power", Default = 50, Min = 50, Max = 500, Rounding = 0, Callback = function(v) State.JumpPower_Value = v end })
JumpGroup:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false, Callback = function(v) State.InfiniteJump = v end })

local MiscGroup = PlayerTab:AddLeftGroupbox("Misc")
MiscGroup:AddToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(v) State.Noclip = v end })
MiscGroup:AddToggle("ClickTeleport", { Text = "Click Teleport", Default = false, Callback = function(v) State.ClickTeleport = v end })
MiscGroup:AddToggle("AntiAFK", { Text = "Anti AFK", Default = false, Callback = function(v) State.AntiAFK = v end })

local FlyGroup = PlayerTab:AddRightGroupbox("Fly")
FlyGroup:AddToggle("FlyEnabled", { Text = "Enable Fly", Default = false, Callback = function(v) State.Fly_Enabled = v end })
FlyGroup:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) State.Fly_Speed = v end })

-- Visuals Tab
local VisualsTab = Window:AddTab("Visuals")

local PlayerESPGroup = VisualsTab:AddLeftGroupbox("Player ESP")
PlayerESPGroup:AddToggle("PlayerESP", { Text = "Enable Player ESP", Default = false, Callback = function(v) State.PlayerESP = v end })
PlayerESPGroup:AddColorPicker("PlayerESPColor", { Text = "Player ESP Color", Default = Color3.fromRGB(100, 200, 255), Callback = function(v) State.PlayerESPColor = v end })

local EggESPGroup = VisualsTab:AddRightGroupbox("Egg ESP")
EggESPGroup:AddToggle("EggESP", { Text = "Enable Egg ESP", Default = false, Callback = function(v) State.EggESP = v end })
EggESPGroup:AddToggle("PetESP", { Text = "Enable Pet ESP", Default = false, Callback = function(v) State.PetESP = v end })
EggESPGroup:AddToggle("ChestESP", { Text = "Enable Chest/Drop ESP", Default = false, Callback = function(v) State.ChestESP = v end })
EggESPGroup:AddColorPicker("EggESPColor", { Text = "Egg ESP Color", Default = Color3.fromRGB(255, 215, 0), Callback = function(v) State.EggESPColor = v end })
EggESPGroup:AddColorPicker("PetESPColor", { Text = "Pet ESP Color", Default = Color3.fromRGB(100, 255, 100), Callback = function(v) State.PetESPColor = v end })
EggESPGroup:AddColorPicker("ChestESPColor", { Text = "Chest ESP Color", Default = Color3.fromRGB(255, 100, 100), Callback = function(v) State.ChestESPColor = v end })

local WorldGroup = VisualsTab:AddLeftGroupbox("World")
WorldGroup:AddButton("Full Bright", function()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	State.FullBright = true
end)
WorldGroup:AddButton("Remove Fog", function()
	Lighting.FogEnd = 999999
	Lighting.FogStart = 0
	State.NoFog = true
end)
WorldGroup:AddButton("Reset Lighting", function()
	Lighting.Brightness = 1
	Lighting.ClockTime = 12
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
	State.FullBright = false
	State.NoFog = false
end)
WorldGroup:AddButton("Fast Mode", function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.SmoothPlastic
			obj.Reflectance = 0
			obj.CastShadow = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj:Destroy()
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			obj.Enabled = false
		end
	end
	Lighting.GlobalShadows = false
	State.FastMode = true
	UI:Notify("Ivory", "Fast Mode enabled", "Info", 3)
end)

-- Teleport Tab
local TeleportTab = Window:AddTab("Teleport")

local TPGroup = TeleportTab:AddLeftGroupbox("Teleport")
TPGroup:AddButton("Teleport to Base", function()
	task.spawn(function()
		local base = Workspace:FindFirstChild("Base") or Workspace:FindFirstChild("base") or Workspace:FindFirstChild("PlayerBase")
		if base then
			local root = base:FindFirstChildWhichIsA("BasePart") or base.PrimaryPart
			if root then tweenToTarget(root.Position) end
		end
	end)
end)
TPGroup:AddButton("Teleport to Treadmill", function()
	task.spawn(function()
		local tm = Workspace:FindFirstChild("Treadmill") or Workspace:FindFirstChild("treadmill") or Workspace:FindFirstChild("Training")
		if tm then
			local root = tm:FindFirstChildWhichIsA("BasePart") or tm.PrimaryPart
			if root then tweenToTarget(root.Position) end
		end
	end)
end)
TPGroup:AddButton("Teleport to Egg Shop", function()
	task.spawn(function()
		local shop = Workspace:FindFirstChild("EggShop") or Workspace:FindFirstChild("Shop") or Workspace:FindFirstChild("EggStore")
		if shop then
			local root = shop:FindFirstChildWhichIsA("BasePart") or shop.PrimaryPart
			if root then tweenToTarget(root.Position) end
		end
	end)
end)
TPGroup:AddButton("Teleport to Sell Area", function()
	task.spawn(function()
		local sell = Workspace:FindFirstChild("Sell") or Workspace:FindFirstChild("SellArea") or Workspace:FindFirstChild("Selling")
		if sell then
			local root = sell:FindFirstChildWhichIsA("BasePart") or sell.PrimaryPart
			if root then tweenToTarget(root.Position) end
		end
	end)
end)

local ServerGroup = TeleportTab:AddRightGroupbox("Server")
ServerGroup:AddButton("Rejoin Server", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)
ServerGroup:AddButton("Server Hop", function()
	task.spawn(function()
		local servers = {}
		local cursor = nil
		repeat
			local url = ("https://games.roblox.com/v1/games/%s/servers/Public?limit=100%s"):format(
				game.PlaceId, cursor and "&cursor=" .. HttpService:UrlEncode(cursor) or ""
			)
			local ok, res = pcall(function() return HttpService:GetAsync(url) end)
			if not ok then break end
			local data = HttpService:JSONDecode(res)
			for _, s in ipairs(data.data) do
				if s.id ~= game.JobId and s.playing < s.maxPlayers then
					table.insert(servers, s.id)
				end
			end
			cursor = data.nextPageCursor
		until not cursor
		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], Player)
		end
	end)
end)
ServerGroup:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	UI:Notify("Ivory", "JobId copied!", "Success", 2)
end)

-- Settings Tab
local SettingsTab = Window:AddTab("Settings")
local MenuGroup = SettingsTab:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function()
	if flyBodyVelocity then stopFly() end
	if noclipConn then noclipConn:Disconnect() end
	Window.Gui:Destroy()
end)
MenuGroup:AddButton("Test Notification", function()
	UI:Notify("Ivory", "This is a test notification!", "Info", 3)
end)
MenuGroup:AddLabel("Menu toggle: RightShift")
MenuGroup:AddButton("Hide/Show Menu", function()
	Window.Main.Visible = not Window.Main.Visible
end)

--// ═══════════════════════════════════════════════════════════
--// GAME LOGIC
--// ═══════════════════════════════════════════════════════════

local function getHRP()
	local c = Player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = Player.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

function tweenToTarget(targetPos)
	local hrp = getHRP()
	if not hrp then return false end
	local hum = getHum()
	if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end) end

	local startPos = hrp.Position
	local dist = (targetPos - startPos).Magnitude
	if dist <= 0.5 then return true end

	local duration = dist / math.max(State.AutoStealSpeed, 5)

	local tween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
	})
	tween:Play()

	local completed = false
	tween.Completed:Connect(function() completed = true end)

	while not completed do
		if not hrp or not hrp.Parent then return false end
		RunService.Heartbeat:Wait()
	end
	return true
end

local function findEggParts()
	local eggs = {}
	local searchFolders = { Workspace }
	for _, name in ipairs({ "Eggs", "Drops", "Items", "Collectibles", "Spawns", "EggSpawns" }) do
		local folder = Workspace:FindFirstChild(name)
		if folder then table.insert(searchFolders, folder) end
	end
	for _, folder in ipairs(searchFolders) do
		for _, obj in ipairs(folder:GetDescendants()) do
			if obj:IsA("Model") or obj:IsA("BasePart") then
				local nl = obj.Name:lower()
				if nl:find("egg") or nl:find("drop") or nl:find("coin") or nl:find("gem") then
					local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
					if part and part.Parent then table.insert(eggs, part) end
				end
			end
		end
	end
	return eggs
end

local function findNearestEgg()
	local hrp = getHRP()
	if not hrp then return nil end
	local eggs = findEggParts()
	local nearest, nearestDist = nil, math.huge
	for _, egg in ipairs(eggs) do
		local dist = (egg.Position - hrp.Position).Magnitude
		if dist < nearestDist and dist <= State.AutoStealRange then
			nearestDist = dist
			nearest = egg
		end
	end
	return nearest
end

local function findAllDrops()
	local hrp = getHRP()
	if not hrp then return {} end
	local drops = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			local nl = obj.Name:lower()
			if nl:find("drop") or nl:find("coin") or nl:find("gem") or nl:find("loot") or nl:find("reward") then
				if (obj.Position - hrp.Position).Magnitude <= State.CollectRadius then
					table.insert(drops, obj)
				end
			end
		end
	end
	return drops
end

local function findNearestProximityPrompt(maxDist)
	local hrp = getHRP()
	if not hrp then return nil end
	local nearest, nearestDist = nil, maxDist or 10
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") then
			local parent = obj.Parent
			if parent then
				local pp = parent:IsA("BasePart") and parent or (parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart"))
				if pp then
					local dist = (pp.Position - hrp.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearest = obj
					end
				end
			end
		end
	end
	return nearest
end

--// ESP
local ESPObjects = {}

local function clearESP()
	for _, obj in pairs(ESPObjects) do
		pcall(function() if obj and obj.Parent then obj:Destroy() end end)
	end
	ESPObjects = {}
end

local function createBillboardESP(part, text, color, offset)
	if not part or not part.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "IvoryESP"
	bb.Size = UDim2.new(0, 150, 0, 30)
	bb.StudsOffset = offset or Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = part
	bb.Parent = part
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color or Color3.new(1, 1, 1)
	tl.TextSize = 13
	tl.Font = Enum.Font.GothamBold
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.Parent = bb
	table.insert(ESPObjects, bb)
end

local function updateESP()
	clearESP()
	if State.EggESP then
		for _, egg in ipairs(findEggParts()) do
			if egg and egg.Parent then
				createBillboardESP(egg, "Egg: " .. egg.Name, State.EggESPColor, Vector3.new(0, 5, 0))
			end
		end
	end
	if State.PetESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name:lower():find("pet") then
				local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				if root then createBillboardESP(root, "Pet: " .. obj.Name, State.PetESPColor) end
			end
		end
	end
	if State.ChestESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				local nl = obj.Name:lower()
				if nl:find("chest") or nl:find("drop") or nl:find("loot") then
					createBillboardESP(obj, obj.Name, State.ChestESPColor, Vector3.new(0, 3, 0))
				end
			end
		end
	end
	if State.PlayerESP then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local myHRP = getHRP()
					local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
					createBillboardESP(hrp, plr.DisplayName .. " [" .. dist .. "m]", State.PlayerESPColor)
				end
			end
		end
	end
end

--// Noclip
local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = Player.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

--// Fly
local flyBodyVelocity, flyBodyGyro

local function startFly()
	pcall(function()
		local hrp = getHRP()
		if not hrp then return end
		flyBodyVelocity = Instance.new("BodyVelocity")
		flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
		flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
		flyBodyVelocity.Parent = hrp
		flyBodyGyro = Instance.new("BodyGyro")
		flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
		flyBodyGyro.P = 9000
		flyBodyGyro.D = 500
		flyBodyGyro.Parent = hrp
	end)
end

local function stopFly()
	pcall(function()
		if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	end)
end

--// ═══════════════════════════════════════════════════════════
--// LOOPS
--// ═══════════════════════════════════════════════════════════

UserInputService.JumpRequest:Connect(function()
	if State.InfiniteJump then
		pcall(function()
			local h = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		Window.Main.Visible = not Window.Main.Visible
	end
	if State.ClickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
		pcall(function()
			local mouse = Player:GetMouse()
			local hrp = getHRP()
			if hrp then hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
		end)
	end
end)

task.spawn(function()
	while task.wait(60) do
		if State.AntiAFK then pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end
	end
end)

RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera
	if State.Speed_Enabled then pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end
	if State.JumpPower_Enabled then pcall(function() Humanoid.JumpPower = State.JumpPower_Value end) end
	if State.Fly_Enabled then
		if not flyBodyVelocity then startFly() end
		pcall(function()
			local hrp = getHRP()
			if not hrp then return end
			local camCF = Camera.CFrame
			local moveDir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
			if moveDir.Magnitude > 0 then
				flyBodyVelocity.Velocity = moveDir.Unit * State.Fly_Speed
			else
				flyBodyVelocity.Velocity = Vector3.zero
			end
			flyBodyGyro.CFrame = camCF
		end)
	else
		if flyBodyVelocity then stopFly() end
	end
	if State.Noclip then if not noclipConn then setNoclip(true) end else if noclipConn then setNoclip(false) end end
end)

task.spawn(function()
	while task.wait(2) do
		if State.PlayerESP or State.EggESP or State.PetESP or State.ChestESP then
			updateESP()
		end
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		if State.AutoSteal then
			pcall(function()
				local nearest = findNearestEgg()
				if nearest then
					tweenToTarget(nearest.Position)
					task.wait(0.2)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(1) do
		if State.AutoCollect then
			pcall(function()
				local drops = findAllDrops()
				for _, drop in ipairs(drops) do
					if not State.AutoCollect then break end
					tweenToTarget(drop.Position)
					task.wait(0.1)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		if State.AutoHatch then
			pcall(function()
				local prompt = findNearestProximityPrompt(15)
				if prompt then
					local hrp = getHRP()
					local parent = prompt.Parent
					local pp = parent and (parent:IsA("BasePart") and parent or parent.PrimaryPart or parent:FindFirstChildWhichIsA("BasePart"))
					if hrp and pp and (pp.Position - hrp.Position).Magnitude < 15 then
						prompt:InputBegin(Player)
						task.wait(0.1)
						prompt:InputEnd(Player)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		if State.AutoTrain then
			pcall(function()
				local tm = Workspace:FindFirstChild("Treadmill") or Workspace:FindFirstChild("treadmill") or Workspace:FindFirstChild("Training")
				if tm then
					local root = tm:FindFirstChildWhichIsA("BasePart") or tm.PrimaryPart
					local hrp = getHRP()
					if root and hrp then
						hrp.CFrame = root.CFrame * CFrame.new(0, 2, 0)
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if State.AutoSell then
			pcall(function()
				local eggs = findEggParts()
				if #eggs >= State.SellThreshold then
					local sell = Workspace:FindFirstChild("Sell") or Workspace:FindFirstChild("SellArea") or Workspace:FindFirstChild("Selling")
					if sell then
						local root = sell:FindFirstChildWhichIsA("BasePart") or sell.PrimaryPart
						if root then
							tweenToTarget(root.Position)
							task.wait(0.5)
							local prompt = sell:FindFirstChildWhichIsA("ProximityPrompt")
							if prompt then
								prompt:InputBegin(Player)
								task.wait(0.1)
								prompt:InputEnd(Player)
							end
						end
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if State.AutoUpgrade then
			pcall(function()
				local up = Workspace:FindFirstChild(State.UpgradeType) or Workspace:FindFirstChild(State.UpgradeType:lower())
				if up then
					local root = up:FindFirstChildWhichIsA("BasePart") or up.PrimaryPart
					if root then
						tweenToTarget(root.Position)
						task.wait(0.5)
						local prompt = up:FindFirstChildWhichIsA("ProximityPrompt")
						if prompt then
							prompt:InputBegin(Player)
							task.wait(0.1)
							prompt:InputEnd(Player)
						end
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(2) do
		if State.WalkOnWater then
			pcall(function()
				local hrp = getHRP()
				if hrp then
					local ww = Workspace:FindFirstChild("IvoryWaterWalk")
					if not ww then
						ww = Instance.new("Part")
						ww.Name = "IvoryWaterWalk"
						ww.Transparency = 1
						ww.CanCollide = true
						ww.Size = Vector3.new(1000, 1, 1000)
						ww.Anchored = true
						ww.Parent = Workspace
					end
					ww.Position = Vector3.new(hrp.Position.X, hrp.Position.Y - 3, hrp.Position.Z)
				end
			end)
		else
			local ww = Workspace:FindFirstChild("IvoryWaterWalk")
			if ww then ww:Destroy() end
		end
	end
end)

UI:Notify("Ivory", "v1.4 loaded successfully", "Success", 5)
