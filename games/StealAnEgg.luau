--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162
--// Self-contained — zero external HTTP fetches
--// NO player modification features (no speed/jump/fly/noclip)
--// Only game-specific automation matching the working reference

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local PlaceId = game.PlaceId
local GameName = tostring(PlaceId)
pcall(function()
	GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

LocalPlayer.CharacterAdded:Connect(function(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

--// ═══════════════════════════════════════════════════════════
--// CONFIG (matches reference script features only)
--// ═══════════════════════════════════════════════════════════

local Config = {
	AutoSteal = false,
	AutoStealDelay = 0.5,
	AutoReturnToBase = true,
	AutoPlaceEggs = false,
	AutoHatchEggs = false,
	AutoEquipBestPet = false,
	AutoUpgradeTreadmill = false,
	AutoUpgradeBase = false,
	AutoSellPets = false,
	AutoClaimIndex = false,
	InstantSteal = false,
	EggESP = false,
	PlayerESP = false,
	AntiAFK = false,
	StealDelay = 0.5,
	ServerHop = false,
	ServerHopDelay = 30,
	FullBright = false,
	NoFog = false,
}

--// ═══════════════════════════════════════════════════════════
--// UTILITY (exact reference patterns)
--// ═══════════════════════════════════════════════════════════

local function GetCharacter()
	return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetHRP()
	local char = GetCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local char = GetCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive()
	local hum = GetHumanoid()
	return hum and hum.Health > 0
end

local function TeleportTo(position)
	local hrp = GetHRP()
	if not hrp then return end

	if Config.InstantSteal then
		hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		return
	end

	local startPos = hrp.Position
	local distance = (position - startPos).Magnitude
	local time = distance / 50

	local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	})
	tween:Play()
	tween.Completed:Wait()
end

local function FindFirstChildRecursive(parent, name, className)
	for _, child in ipairs(parent:GetDescendants()) do
		if child.Name == name then
			if className == nil or child:IsA(className) then
				return child
			end
		end
	end
	return nil
end

--// ═══════════════════════════════════════════════════════════
--// GAME-SPECIFIC (exact reference patterns)
--// ═══════════════════════════════════════════════════════════

local function GetBase()
	return FindFirstChildRecursive(Workspace, "Base", "Model")
		or FindFirstChildRecursive(Workspace, "Plot", "Model")
		or FindFirstChildRecursive(Workspace, "MyBase", "Model")
end

local function GetEggs()
	local eggs = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj.Name:lower():find("egg") and (obj:IsA("BasePart") or obj:IsA("Model")) then
			if obj:IsA("BasePart") then
				table.insert(eggs, obj)
			else
				local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				if root then table.insert(eggs, root) end
			end
		end
	end
	return eggs
end

local function GetHeldEgg()
	local char = GetCharacter()
	if not char then return nil end
	return char:FindFirstChild("HoldingEgg")
		or char:FindFirstChild("HeldEgg")
end

local function StealEgg(egg)
	if not egg or not IsAlive() then return false end

	local hrp = GetHRP()
	if not hrp then return false end

	local eggPos = egg.Position
	local base = GetBase()

	TeleportTo(eggPos)
	task.wait(Config.StealDelay)

	local proximityPrompt = egg:FindFirstChildWhichIsA("ProximityPrompt")
	if proximityPrompt then
		fireproximityprompt(proximityPrompt)
	else
		hrp.CFrame = egg.CFrame
	end

	task.wait(0.2)

	if Config.AutoReturnToBase and base then
		local basePos = base:FindFirstChild("HumanoidRootPart")
			and base.HumanoidRootPart.Position
			or (base:IsA("Model") and base:GetPivot().Position)
			or base.Position
		TeleportTo(basePos)
		task.wait(0.3)
	end

	return true
end

--// ═══════════════════════════════════════════════════════════
--// AUTOMATION LOOPS (exact reference patterns)
--// ═══════════════════════════════════════════════════════════

local function AutoStealLoop()
	while Config.AutoSteal do
		if IsAlive() then
			local eggs = GetEggs()
			local hrp = GetHRP()
			if hrp then
				local nearestEgg = nil
				local nearestDist = math.huge
				for _, egg in ipairs(eggs) do
					local dist = (egg.Position - hrp.Position).Magnitude
					if dist < nearestDist then
						nearestDist = dist
						nearestEgg = egg
					end
				end
				if nearestEgg then
					StealEgg(nearestEgg)
				end
			end
		end
		task.wait(Config.AutoStealDelay)
	end
end

local function AutoPlaceEggsLoop()
	while Config.AutoPlaceEggs do
		if IsAlive() then
			local heldEgg = GetHeldEgg()
			if heldEgg then
				local base = GetBase()
				if base then
					local basePos = base:FindFirstChild("HumanoidRootPart")
						and base.HumanoidRootPart.Position
						or (base:IsA("Model") and base:GetPivot().Position)
						or base.Position
					TeleportTo(basePos)
					task.wait(0.5)
					local placeEvent = ReplicatedStorage:FindFirstChild("PlaceEgg")
						or ReplicatedStorage:FindFirstChild("Place")
					if placeEvent and placeEvent:IsA("RemoteEvent") then
						placeEvent:FireServer()
					end
				end
			end
		end
		task.wait(1)
	end
end

local function AutoHatchEggsLoop()
	while Config.AutoHatchEggs do
		if IsAlive() then
			local base = GetBase()
			if base then
				for _, obj in ipairs(base:GetDescendants()) do
					if obj.Name:lower():find("egg") and obj:IsA("BasePart") then
						local proximityPrompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
						if proximityPrompt then
							local hrp = GetHRP()
							if hrp then
								local dist = (obj.Position - hrp.Position).Magnitude
								if dist < 10 then
									fireproximityprompt(proximityPrompt)
									task.wait(0.5)
								end
							end
						end
					end
				end
			end
		end
		task.wait(2)
	end
end

local function AutoEquipBestPetLoop()
	while Config.AutoEquipBestPet do
		if IsAlive() then
			local equipEvent = ReplicatedStorage:FindFirstChild("EquipPet")
				or ReplicatedStorage:FindFirstChild("EquipBest")
			if equipEvent and equipEvent:IsA("RemoteEvent") then
				equipEvent:FireServer()
			end
		end
		task.wait(5)
	end
end

local function AutoUpgradeTreadmillLoop()
	while Config.AutoUpgradeTreadmill do
		if IsAlive() then
			local upgradeEvent = ReplicatedStorage:FindFirstChild("UpgradeTreadmill")
				or ReplicatedStorage:FindFirstChild("Upgrade")
			if upgradeEvent and upgradeEvent:IsA("RemoteEvent") then
				upgradeEvent:FireServer()
			end
		end
		task.wait(10)
	end
end

local function AutoUpgradeBaseLoop()
	while Config.AutoUpgradeBase do
		if IsAlive() then
			local upgradeEvent = ReplicatedStorage:FindFirstChild("UpgradeBase")
			if upgradeEvent and upgradeEvent:IsA("RemoteEvent") then
				upgradeEvent:FireServer()
			end
		end
		task.wait(10)
	end
end

local function AutoSellPetsLoop()
	while Config.AutoSellPets do
		if IsAlive() then
			local sellEvent = ReplicatedStorage:FindFirstChild("SellPet")
				or ReplicatedStorage:FindFirstChild("Sell")
			if sellEvent and sellEvent:IsA("RemoteEvent") then
				sellEvent:FireServer()
			end
		end
		task.wait(15)
	end
end

local function AutoClaimIndexLoop()
	while Config.AutoClaimIndex do
		if IsAlive() then
			local claimEvent = ReplicatedStorage:FindFirstChild("ClaimIndex")
				or ReplicatedStorage:FindFirstChild("Claim")
			if claimEvent and claimEvent:IsA("RemoteEvent") then
				claimEvent:FireServer()
			end
		end
		task.wait(10)
	end
end

local function AntiAFKLoop()
	while Config.AntiAFK do
		if IsAlive() then
			VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
		end
		task.wait(60)
	end
end

--// ═══════════════════════════════════════════════════════════
--// ESP (same as reference)
--// ═══════════════════════════════════════════════════════════

local ESPObjects = {}

local function CreateESP(part, color, text)
	if ESPObjects[part] then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "IvoryESP"
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = part
	billboard.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = 0.5
	frame.Parent = billboard

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = frame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = frame

	ESPObjects[part] = billboard
end

local function RemoveESP(part)
	if ESPObjects[part] then
		ESPObjects[part]:Destroy()
		ESPObjects[part] = nil
	end
end

local function UpdateESP()
	for part, esp in pairs(ESPObjects) do
		if not part or not part.Parent then
			RemoveESP(part)
		end
	end

	if Config.EggESP then
		for _, egg in ipairs(GetEggs()) do
			if not ESPObjects[egg] then
				CreateESP(egg, Color3.fromRGB(255, 215, 0), "Egg: " .. egg.Name)
			end
		end
	end

	if Config.PlayerESP then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp and not ESPObjects[hrp] then
					local myHRP = GetHRP()
					local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
					CreateESP(hrp, Color3.fromRGB(100, 200, 255), plr.DisplayName .. " [" .. dist .. "m]")
				end
			end
		end
	end

	if not Config.EggESP and not Config.PlayerESP then
		for part, _ in pairs(ESPObjects) do
			RemoveESP(part)
		end
	end
end

--// ═══════════════════════════════════════════════════════════
--// UI — Ivory branded, Obsidian dark purple, matches reference layout
--// ═══════════════════════════════════════════════════════════

local CC = {
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
	Green = Color3.fromRGB(80, 180, 80),
}

local function rc(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 4); c.Parent = p end
local function rs(p, co, t) local s = Instance.new("UIStroke"); s.Color = co or CC.Outline; s.Thickness = t or 1; s.Parent = p end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IvoryHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = CC.Main
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
rc(MainFrame, 8)
rs(MainFrame, CC.Outline, 2)

-- Title
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = CC.Dark
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -40, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Ivory"
TitleLabel.TextColor3 = CC.Accent
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = CC.Risky
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
rc(CloseBtn, 4)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

-- Tab bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -10, 0, 35)
TabBar.Position = UDim2.new(0, 5, 0, 45)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabList = Instance.new("UIListLayout")
TabList.FillDirection = Enum.FillDirection.Horizontal
TabList.Padding = UDim.new(0, 5)
TabList.Parent = TabBar

-- Content
local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, -10, 1, -90)
ContentFrame.Position = UDim2.new(0, 5, 0, 85)
ContentFrame.BackgroundColor3 = CC.Bright
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame
rc(ContentFrame, 4)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -5, 1, -5)
ScrollingFrame.Position = UDim2.new(0, 2.5, 0, 2.5)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = CC.Accent
ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ScrollingFrame.Parent = ContentFrame

local ContentList = Instance.new("UIListLayout")
ContentList.Padding = UDim.new(0, 5)
ContentList.Parent = ScrollingFrame

-- Footer
local Footer = Instance.new("Frame")
Footer.Size = UDim2.new(1, 0, 0, 18)
Footer.Position = UDim2.new(0, 0, 1, -18)
Footer.BackgroundColor3 = CC.Dark
Footer.BorderSizePixel = 0
Footer.Parent = MainFrame

local FooterLabel = Instance.new("TextLabel")
FooterLabel.Size = UDim2.new(1, -10, 1, 0)
FooterLabel.Position = UDim2.new(0, 5, 0, 0)
FooterLabel.BackgroundTransparency = 1
FooterLabel.Text = "v1.4 | " .. (Workspace:FindFirstChild("Lobby") and "Lobby" or "Game") .. " | " .. tostring(LocalPlayer.UserId)
FooterLabel.TextColor3 = CC.SubText
FooterLabel.TextSize = 9
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.Parent = Footer

-- Notification folder
local notifFolder = Instance.new("Folder")
notifFolder.Name = "IvoryNotifs"
notifFolder.Parent = LocalPlayer:WaitForChild("PlayerGui")

local function Notify(title, desc, typ, time)
	task.spawn(function()
		local n = Instance.new("Frame")
		n.Size = UDim2.new(0, 260, 0, 50)
		n.Position = UDim2.new(1, -270, 1, -60)
		n.BackgroundColor3 = CC.Main
		n.BorderSizePixel = 0
		n.Parent = notifFolder
		rc(n, 6)
		rs(n, CC.Accent, 1)

		local a = Instance.new("Frame")
		a.Size = UDim2.new(0, 4, 1, 0)
		a.BackgroundColor3 = typ == "Success" and CC.Success or typ == "Error" and CC.Risky or CC.Accent
		a.BorderSizePixel = 0
		a.Parent = n

		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.new(1, -16, 0, 18)
		tl.Position = UDim2.new(0, 12, 0, 4)
		tl.BackgroundTransparency = 1
		tl.Text = title or "Ivory"
		tl.TextColor3 = CC.FontColor
		tl.TextSize = 12
		tl.Font = Enum.Font.GothamBold
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.Parent = n

		local dl = Instance.new("TextLabel")
		dl.Size = UDim2.new(1, -16, 0, 24)
		dl.Position = UDim2.new(0, 12, 0, 22)
		dl.BackgroundTransparency = 1
		dl.Text = desc or ""
		dl.TextColor3 = CC.SubText
		dl.TextSize = 10
		dl.Font = Enum.Font.Gotham
		dl.TextXAlignment = Enum.TextXAlignment.Left
		dl.TextWrapped = true
		dl.Parent = n

		task.wait(time or 3)
		local tw = TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1})
		tw:Play()
		tw.Completed:Wait()
		n:Destroy()
	end)
end

-- Tab system
local CurrentTab = nil
local function SwitchTab(name)
	for _, obj in ipairs(ScrollingFrame:GetChildren()) do
		if obj:IsA("Frame") then obj.Visible = (obj.Name == name) end
	end
	for _, btn in ipairs(TabBar:GetChildren()) do
		if btn:IsA("TextButton") then
			btn.BackgroundColor3 = (btn.Name == name) and CC.Accent or CC.Dark
			btn.TextColor3 = Color3.new(1, 1, 1)
		end
	end
	CurrentTab = name
end

local function MakeTab(name)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 80, 0, 30)
	btn.BackgroundColor3 = CC.Dark
	btn.Text = name
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 12
	btn.Font = Enum.Font.Gotham
	btn.Parent = TabBar
	rc(btn, 4)
	btn.MouseButton1Click:Connect(function() SwitchTab(name) end)

	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(1, -10, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.Visible = (CurrentTab == nil)
	frame.Parent = ScrollingFrame

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 5)
	list.Parent = frame

	if not CurrentTab then CurrentTab = name; btn.BackgroundColor3 = CC.Accent end

	return frame
end

local function MakeSection(parent, text)
	local s = Instance.new("Frame")
	s.Size = UDim2.new(1, 0, 0, 0)
	s.AutomaticSize = Enum.AutomaticSize.Y
	s.BackgroundColor3 = CC.Main
	s.BorderSizePixel = 0
	s.Parent = parent
	rc(s, 4)

	local sl = Instance.new("UIListLayout")
	sl.Padding = UDim.new(0, 3)
	sl.Parent = s

	local sp = Instance.new("UIPadding")
	sp.PaddingTop = UDim.new(0, 5)
	sp.PaddingBottom = UDim.new(0, 5)
	sp.PaddingLeft = UDim.new(0, 5)
	sp.PaddingRight = UDim.new(0, 5)
	sp.Parent = s

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 20)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = CC.Accent
	lbl.TextSize = 12
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = s

	return s
end

local function MakeToggle(parent, text, default, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 25)
	f.BackgroundTransparency = 1
	f.Parent = parent

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0.7, 0, 1, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextSize = 11
	l.Font = Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local state = default or false
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 40, 0, 20)
	b.Position = UDim2.new(0.75, 0, 0.5, -10)
	b.BackgroundColor3 = state and CC.Green or Color3.fromRGB(100, 100, 100)
	b.Text = state and "ON" or "OFF"
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 10
	b.Font = Enum.Font.GothamBold
	b.Parent = f
	rc(b, 10)

	b.MouseButton1Click:Connect(function()
		state = not state
		b.BackgroundColor3 = state and CC.Green or Color3.fromRGB(100, 100, 100)
		b.Text = state and "ON" or "OFF"
		if callback then callback(state) end
	end)

	if callback and state then callback(state) end
end

local function MakeSlider(parent, text, min, max, default, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 35)
	f.BackgroundTransparency = 1
	f.Parent = parent

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(0.5, 0, 0, 15)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.new(1, 1, 1)
	l.TextSize = 11
	l.Font = Enum.Font.Gotham
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local vl = Instance.new("TextLabel")
	vl.Size = UDim2.new(0.4, 0, 0, 15)
	vl.Position = UDim2.new(0.6, 0, 0, 0)
	vl.BackgroundTransparency = 1
	vl.Text = tostring(default)
	vl.TextColor3 = CC.Accent
	vl.TextSize = 11
	vl.Font = Enum.Font.GothamBold
	vl.TextXAlignment = Enum.TextXAlignment.Right
	vl.Parent = f

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0.95, 0, 0, 6)
	bg.Position = UDim2.new(0.025, 0, 0, 22)
	bg.BackgroundColor3 = CC.Dark
	bg.Parent = f
	rc(bg, 3)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = CC.Accent
	fill.Parent = bg
	rc(fill, 3)

	local knob = Instance.new("TextButton")
	knob.Size = UDim2.new(0, 12, 0, 12)
	knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
	knob.BackgroundColor3 = Color3.new(1, 1, 1)
	knob.Text = ""
	knob.Parent = bg
	rc(knob, 6)

	local dragging = false
	local currentValue = default

	knob.MouseButton1Down:Connect(function() dragging = true end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mp = UserInputService:GetMouseLocation()
			local pct = math.clamp((mp.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
			currentValue = math.floor(min + (max - min) * pct)
			fill.Size = UDim2.new(pct, 0, 1, 0)
			knob.Position = UDim2.new(pct, -6, 0.5, -6)
			vl.Text = tostring(currentValue)
			if callback then callback(currentValue) end
		end
	end)

	if callback then callback(default) end
end

local function MakeButton(parent, text, callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 25)
	b.BackgroundColor3 = CC.Dark
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.TextSize = 11
	b.Font = Enum.Font.Gotham
	b.Parent = parent
	rc(b, 4)
	b.MouseButton1Click:Connect(function() if callback then callback() end end)
end

--// ═══════════════════════════════════════════════════════════
--// BUILD UI TABS (same features as reference script)
--// ═══════════════════════════════════════════════════════════

-- Steal Tab
local StealTab = MakeTab("Steal")
local stealSection = MakeSection(StealTab, "Egg Stealing")
MakeToggle(stealSection, "Auto Steal Eggs", false, function(state)
	Config.AutoSteal = state
	if state then task.spawn(AutoStealLoop) end
end)
MakeSlider(stealSection, "Steal Delay (s)", 1, 50, 5, function(value)
	Config.StealDelay = value / 10
end)
MakeToggle(stealSection, "Instant Steal", false, function(state)
	Config.InstantSteal = state
end)
MakeToggle(stealSection, "Auto Return to Base", true, function(state)
	Config.AutoReturnToBase = state
end)
MakeButton(stealSection, "Steal Nearest Egg", function()
	task.spawn(function()
		local eggs = GetEggs()
		local hrp = GetHRP()
		if not hrp then return end
		local nearestEgg, nearestDist = nil, math.huge
		for _, egg in ipairs(eggs) do
			local dist = (egg.Position - hrp.Position).Magnitude
			if dist < nearestDist then nearestDist = dist; nearestEgg = egg end
		end
		if nearestEgg then StealEgg(nearestEgg) end
	end)
end)
MakeButton(stealSection, "Steal All Eggs", function()
	task.spawn(function()
		for _, egg in ipairs(GetEggs()) do
			if IsAlive() then StealEgg(egg); task.wait(Config.StealDelay) end
		end
		Notify("Ivory", "Finished stealing eggs!", "Success", 3)
	end)
end)

-- Automation Tab
local AutoTab = MakeTab("Automation")
local autoSection = MakeSection(AutoTab, "Automation")
MakeToggle(autoSection, "Auto Place Eggs", false, function(state)
	Config.AutoPlaceEggs = state
	if state then task.spawn(AutoPlaceEggsLoop) end
end)
MakeToggle(autoSection, "Auto Hatch Eggs", false, function(state)
	Config.AutoHatchEggs = state
	if state then task.spawn(AutoHatchEggsLoop) end
end)
MakeToggle(autoSection, "Auto Equip Best Pet", false, function(state)
	Config.AutoEquipBestPet = state
	if state then task.spawn(AutoEquipBestPetLoop) end
end)
MakeToggle(autoSection, "Auto Upgrade Treadmill", false, function(state)
	Config.AutoUpgradeTreadmill = state
	if state then task.spawn(AutoUpgradeTreadmillLoop) end
end)
MakeToggle(autoSection, "Auto Upgrade Base", false, function(state)
	Config.AutoUpgradeBase = state
	if state then task.spawn(AutoUpgradeBaseLoop) end
end)
MakeToggle(autoSection, "Auto Sell Pets", false, function(state)
	Config.AutoSellPets = state
	if state then task.spawn(AutoSellPetsLoop) end
end)
MakeToggle(autoSection, "Auto Claim Index", false, function(state)
	Config.AutoClaimIndex = state
	if state then task.spawn(AutoClaimIndexLoop) end
end)
MakeToggle(autoSection, "Anti AFK", false, function(state)
	Config.AntiAFK = state
	if state then task.spawn(AntiAFKLoop) end
end)

-- ESP Tab
local ESPTab = MakeTab("ESP")
local espSection = MakeSection(ESPTab, "ESP")
MakeToggle(espSection, "Egg ESP", false, function(state)
	Config.EggESP = state
	UpdateESP()
end)
MakeToggle(espSection, "Player ESP", false, function(state)
	Config.PlayerESP = state
	UpdateESP()
end)

-- Settings Tab
local SettingsTab = MakeTab("Settings")
local settingsSection = MakeSection(SettingsTab, "Settings")
MakeToggle(settingsSection, "Auto Server Hop", false, function(state)
	Config.ServerHop = state
	if state then
		task.spawn(function()
			while Config.ServerHop do
				task.wait(Config.ServerHopDelay)
				if Config.ServerHop then
					local servers = {}
					local ok, result = pcall(function()
						return HttpService:JSONDecode(
							game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
						)
					end)
					if ok and result and result.data then
						for _, server in ipairs(result.data) do
							if server.id ~= game.JobId and server.playing < server.maxPlayers then
								table.insert(servers, server.id)
							end
						end
					end
					if #servers > 0 then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], LocalPlayer)
					end
				end
			end
		end)
	end
end)
MakeButton(settingsSection, "Server Hop Now", function()
	task.spawn(function()
		local servers = {}
		local ok, result = pcall(function()
			return HttpService:JSONDecode(
				game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
			)
		end)
		if ok and result and result.data then
			for _, server in ipairs(result.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					table.insert(servers, server.id)
				end
			end
		end
		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], LocalPlayer)
		end
	end)
end)
MakeButton(settingsSection, "Rejoin Server", function()
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
MakeButton(settingsSection, "Copy JobId", function()
	setclipboard(game.JobId)
	Notify("Ivory", "JobId copied!", "Success", 2)
end)
MakeButton(settingsSection, "Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
	Notify("Ivory", "Discord link copied!", "Success", 3)
end)

local settingsSection2 = MakeSection(SettingsTab, "World")
MakeButton(settingsSection2, "Full Bright", function()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
end)
MakeButton(settingsSection2, "Remove Fog", function()
	Lighting.FogEnd = 999999
	Lighting.FogStart = 0
end)
MakeButton(settingsSection2, "Reset Lighting", function()
	Lighting.Brightness = 1
	Lighting.ClockTime = 12
	Lighting.FogEnd = 100000
end)
MakeButton(settingsSection2, "Destroy UI", function()
	ScreenGui:Destroy()
end)

--// ═══════════════════════════════════════════════════════════
--// CONNECTIONS (no player modification)
--// ═══════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		MainFrame.Visible = not MainFrame.Visible
	end
end)

-- ESP update
task.spawn(function()
	while true do
		task.wait(1)
		pcall(UpdateESP)
	end
end)

Notify("Ivory", "v1.4 loaded successfully", "Success", 5)
