--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162
--// Based on verified working reference script patterns
--// Fully self-contained — zero external HTTP fetches

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

--// ═══════════════════════════════════════════════════════════
--// CONFIG
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
	ChestESP = false,
	EggESPColor = Color3.fromRGB(255, 215, 0),
	PlayerESPColor = Color3.fromRGB(100, 200, 255),
	ChestESPColor = Color3.fromRGB(255, 100, 100),
	PetESP = false,
	PetESPColor = Color3.fromRGB(100, 255, 100),
	AntiAFK = false,
	StealDelay = 0.5,
	Speed_Enabled = false,
	Speed_Value = 16,
	JumpPower_Enabled = false,
	JumpPower_Value = 50,
	InfiniteJump = false,
	Noclip = false,
	ClickTeleport = false,
	Fly_Enabled = false,
	Fly_Speed = 50,
	WalkOnWater = false,
	FullBright = false,
	NoFog = false,
	FastMode = false,
	ServerHop = false,
	ServerHopDelay = 30,
}

--// ═══════════════════════════════════════════════════════════
--// UTILITY (from reference - exact patterns)
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
--// GAME-SPECIFIC (from reference - exact patterns)
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

local function StealNearestEgg()
	if not IsAlive() then return end
	local eggs = GetEggs()
	local hrp = GetHRP()
	if not hrp then return end

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

--// ═══════════════════════════════════════════════════════════
--// AUTOMATION LOOPS (from reference - exact patterns)
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

local function ServerHopLoop()
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
end

--// ═══════════════════════════════════════════════════════════
--// ESP SYSTEM
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
				CreateESP(egg, Config.EggESPColor, "Egg: " .. egg.Name)
			end
		end
	end

	if Config.PetESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name:lower():find("pet") then
				local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				if root and not ESPObjects[root] then
					CreateESP(root, Config.PetESPColor, "Pet: " .. obj.Name)
				end
			end
		end
	end

	if Config.ChestESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				local nl = obj.Name:lower()
				if nl:find("chest") or nl:find("drop") or nl:find("loot") then
					if not ESPObjects[obj] then
						CreateESP(obj, Config.ChestESPColor, obj.Name)
					end
				end
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
					CreateESP(hrp, Config.PlayerESPColor, plr.DisplayName .. " [" .. dist .. "m]")
				end
			end
		end
	end

	if not Config.EggESP and not Config.PetESP and not Config.ChestESP and not Config.PlayerESP then
		for part, _ in pairs(ESPObjects) do
			RemoveESP(part)
		end
	end
end

--// ═══════════════════════════════════════════════════════════
--// NOCLIP / FLY / MISC
--// ═══════════════════════════════════════════════════════════

local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = LocalPlayer.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

local flyBodyVelocity, flyBodyGyro
local function startFly()
	pcall(function()
		local hrp = GetHRP()
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
--// INLINE UI — Ivory branded, Obsidian dark purple style
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
}

local function rc(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 4); c.Parent = p; return c end
local function rs(p, co, t) local s = Instance.new("UIStroke"); s.Color = co or CC.Outline; s.Thickness = t or 1; s.Parent = p; return s end
local function rp(p, t, b, l, ri) local p2 = Instance.new("UIPadding"); p2.PaddingTop = UDim.new(0, t or 4); p2.PaddingBottom = UDim.new(0, b or 4); p2.PaddingLeft = UDim.new(0, l or 4); p2.PaddingRight = UDim.new(0, ri or 4); p2.Parent = p; return p2 end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IvoryHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 380)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -190)
MainFrame.BackgroundColor3 = CC.Main
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
rc(MainFrame, 6)
rs(MainFrame, CC.Outline, 1)

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = CC.Dark
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 100, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Ivory"
TitleLabel.TextColor3 = CC.Accent
TitleLabel.TextSize = 15
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 4)
CloseBtn.BackgroundColor3 = CC.Risky
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
rc(CloseBtn, 4)
CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 110, 1, -32)
Sidebar.Position = UDim2.new(0, 0, 0, 32)
Sidebar.BackgroundColor3 = CC.Dark
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -110, 1, -32)
Content.Position = UDim2.new(0, 110, 0, 32)
Content.BackgroundColor3 = CC.Main
Content.BorderSizePixel = 0
Content.ClipsDescendants = true
Content.Parent = MainFrame

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
FooterLabel.Text = "v1.4 | " .. (isLobby and "Lobby" or "Game") .. " | " .. tostring(LocalPlayer.UserId)
FooterLabel.TextColor3 = CC.SubText
FooterLabel.TextSize = 9
FooterLabel.Font = Enum.Font.Gotham
FooterLabel.TextXAlignment = Enum.TextXAlignment.Left
FooterLabel.Parent = Footer

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
local Tabs = {}
local TabButtons = {}
local CurrentTab = nil
local TabContents = {}

local function AddTab(name)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 26)
	btn.BackgroundColor3 = CC.Dark
	btn.BackgroundTransparency = 1
	btn.Text = "  " .. name
	btn.TextColor3 = CC.SubText
	btn.TextSize = 11
	btn.Font = Enum.Font.GothamMedium
	btn.TextXAlignment = Enum.TextXAlignment.Left
	btn.Parent = Sidebar

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -8, 1, -8)
	scroll.Position = UDim2.new(0, 4, 0, 4)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = CC.Accent
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Visible = false
	scroll.BorderSizePixel = 0
	scroll.Parent = Content

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 4)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
	end)

	Tabs[name] = scroll
	TabButtons[name] = btn
	TabContents[name] = { Order = 0 }

	btn.MouseButton1Click:Connect(function()
		for n, s in pairs(Tabs) do s.Visible = (n == name) end
		for n, b in pairs(TabButtons) do
			b.TextColor3 = (n == name) and CC.Accent or CC.SubText
			b.BackgroundColor3 = (n == name) and CC.Bright or CC.Dark
			b.BackgroundTransparency = (n == name) and 0 or 1
		end
		CurrentTab = name
	end)

	if not CurrentTab then
		CurrentTab = name
		scroll.Visible = true
		btn.TextColor3 = CC.Accent
		btn.BackgroundColor3 = CC.Bright
		btn.BackgroundTransparency = 0
	end

	return scroll
end

local function AddGroupbox(parent, text)
	local tc = TabContents[parent.Name] or TabContents[CurrentTab]
	tc.Order = tc.Order + 1

	local g = Instance.new("Frame")
	g.Size = UDim2.new(1, 0, 0, 0)
	g.AutomaticSize = Enum.AutomaticSize.Y
	g.BackgroundColor3 = CC.Bright
	g.BorderSizePixel = 0
	g.LayoutOrder = tc.Order
	g.Parent = parent
	rc(g, 4)
	rp(g, 6, 6, 6, 6)

	local gl = Instance.new("UIListLayout")
	gl.Padding = UDim.new(0, 3)
	gl.SortOrder = Enum.SortOrder.LayoutOrder
	gl.Parent = g

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 18)
	lbl.BackgroundTransparency = 1
	lbl.Text = "  " .. text
	lbl.TextColor3 = CC.Accent
	lbl.TextSize = 11
	lbl.Font = Enum.Font.GothamBold
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = 0
	lbl.Parent = g

	local order = 0
	local function no() order = order + 1; return order end

	return {
		AddToggle = function(_, id, opts)
			local o = no()
			local state = opts.Default or false
			local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 22); f.BackgroundTransparency = 1; f.LayoutOrder = o; f.Parent = g
			local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.7, 0, 1, 0); l.BackgroundTransparency = 1; l.Text = opts.Text or id; l.TextColor3 = CC.FontColor; l.TextSize = 11; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
			local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 36, 0, 18); b.Position = UDim2.new(1, -40, 0.5, -9); b.BackgroundColor3 = state and CC.Accent or CC.Dark; b.Text = state and "ON" or "OFF"; b.TextColor3 = Color3.new(1, 1, 1); b.TextSize = 9; b.Font = Enum.Font.GothamBold; b.Parent = f; rc(b, 9)
			b.MouseButton1Click:Connect(function()
				state = not state
				b.BackgroundColor3 = state and CC.Accent or CC.Dark
				b.Text = state and "ON" or "OFF"
				opts.Callback(state)
			end)
			if opts.Callback then opts.Callback(state) end
		end,
		AddSlider = function(_, id, opts)
			local o = no()
			local mn, mx, df = opts.Min or 0, opts.Max or 100, opts.Default or 0
			local val = df
			local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 32); f.BackgroundTransparency = 1; f.LayoutOrder = o; f.Parent = g
			local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.55, 0, 0, 14); l.BackgroundTransparency = 1; l.Text = opts.Text or id; l.TextColor3 = CC.FontColor; l.TextSize = 11; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
			local vl = Instance.new("TextLabel"); vl.Size = UDim2.new(0.35, 0, 0, 14); vl.Position = UDim2.new(0.6, 0, 0, 0); vl.BackgroundTransparency = 1; vl.Text = tostring(df); vl.TextColor3 = CC.Accent; vl.TextSize = 11; vl.Font = Enum.Font.GothamBold; vl.TextXAlignment = Enum.TextXAlignment.Right; vl.Parent = f
			local bg = Instance.new("Frame"); bg.Size = UDim2.new(0.95, 0, 0, 5); bg.Position = UDim2.new(0.025, 0, 0, 18); bg.BackgroundColor3 = CC.Dark; bg.Parent = f; rc(bg, 3)
			local fill = Instance.new("Frame"); fill.Size = UDim2.new((df - mn)/(mx - mn), 0, 1, 0); fill.BackgroundColor3 = CC.Accent; fill.Parent = bg; rc(fill, 3)
			local knob = Instance.new("TextButton"); knob.Size = UDim2.new(0, 10, 0, 10); knob.Position = UDim2.new((df - mn)/(mx - mn), -5, 0.5, -5); knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.Text = ""; knob.ZIndex = 2; knob.Parent = bg; rc(knob, 5)
			local dragging = false
			knob.MouseButton1Down:Connect(function() dragging = true end)
			UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
			UserInputService.InputChanged:Connect(function(i)
				if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
					local mp = UserInputService:GetMouseLocation()
					local pct = math.clamp((mp.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
					val = math.floor(mn + (mx - mn) * pct)
					fill.Size = UDim2.new(pct, 0, 1, 0)
					knob.Position = UDim2.new(pct, -5, 0.5, -5)
					vl.Text = tostring(val)
					opts.Callback(val)
				end
			end)
			if opts.Callback then opts.Callback(df) end
		end,
		AddButton = function(_, text, cb)
			local o = no()
			local b = Instance.new("TextButton"); b.Size = UDim2.new(1, 0, 0, 24); b.BackgroundColor3 = CC.Accent; b.Text = text; b.TextColor3 = Color3.new(1, 1, 1); b.TextSize = 11; b.Font = Enum.Font.GothamMedium; b.LayoutOrder = o; b.Parent = g; rc(b, 4)
			b.MouseButton1Click:Connect(function() pcall(cb) end)
		end,
		AddLabel = function(_, text)
			local o = no()
			local l = Instance.new("TextLabel"); l.Size = UDim2.new(1, 0, 0, 18); l.BackgroundTransparency = 1; l.Text = text; l.TextColor3 = CC.SubText; l.TextSize = 11; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left; l.LayoutOrder = o; l.Parent = g
		end,
		AddDivider = function(_)
			local o = no()
			local d = Instance.new("Frame"); d.Size = UDim2.new(1, 0, 0, 1); d.BackgroundColor3 = CC.Outline; d.BorderSizePixel = 0; d.LayoutOrder = o; d.Parent = g
		end,
		AddColorPicker = function(_, id, opts)
			local o = no()
			local presets = { Color3.fromRGB(255,215,0), Color3.fromRGB(100,255,100), Color3.fromRGB(100,200,255), Color3.fromRGB(255,100,100), Color3.fromRGB(255,100,255), Color3.fromRGB(255,165,0) }
			local idx = 1
			local f = Instance.new("Frame"); f.Size = UDim2.new(1, 0, 0, 22); f.BackgroundTransparency = 1; f.LayoutOrder = o; f.Parent = g
			local l = Instance.new("TextLabel"); l.Size = UDim2.new(0.65, 0, 1, 0); l.BackgroundTransparency = 1; l.Text = opts.Text or id; l.TextColor3 = CC.FontColor; l.TextSize = 11; l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left; l.Parent = f
			local sw = Instance.new("TextButton"); sw.Size = UDim2.new(0, 18, 0, 18); sw.Position = UDim2.new(1, -22, 0.5, -9); sw.BackgroundColor3 = opts.Default or CC.Accent; sw.Text = ""; sw.Parent = f; rc(sw, 3); rs(sw, CC.Outline, 1)
			sw.MouseButton1Click:Connect(function()
				idx = idx % #presets + 1
				sw.BackgroundColor3 = presets[idx]
				if opts.Callback then opts.Callback(presets[idx]) end
			end)
			if opts.Callback then opts.Callback(presets[1]) end
		end,
	}
end

--// ═══════════════════════════════════════════════════════════
--// BUILD UI TABS
--// ═══════════════════════════════════════════════════════════

local MainTab = AddTab("Main")
local mainG = AddGroupbox(MainTab, "Info")
mainG:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
	Notify("Ivory", "Discord link copied!", "Success", 3)
end)
mainG:AddLabel("Game: " .. GameName)
mainG:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	Notify("Ivory", "JobId copied!", "Success", 2)
end)

local FarmTab = AddTab("Farm")
local stealG = AddGroupbox(FarmTab, "Auto Steal")
stealG:AddToggle("AutoSteal", { Text = "Enable Auto Steal", Default = false, Callback = function(v) Config.AutoSteal = v; if v then task.spawn(AutoStealLoop) end end })
stealG:AddToggle("InstantSteal", { Text = "Instant Steal", Default = false, Callback = function(v) Config.InstantSteal = v end })
stealG:AddToggle("AutoReturnToBase", { Text = "Auto Return to Base", Default = true, Callback = function(v) Config.AutoReturnToBase = v end })
stealG:AddSlider("StealDelay", { Text = "Steal Delay (s)", Default = 5, Min = 1, Max = 50, Callback = function(v) Config.StealDelay = v / 10 end })
stealG:AddButton("Steal Nearest Egg", StealNearestEgg)
stealG:AddButton("Steal All Eggs", function()
	task.spawn(function()
		for _, egg in ipairs(GetEggs()) do
			if not Config.AutoSteal then break end
			StealEgg(egg)
			task.wait(Config.StealDelay)
		end
		Notify("Ivory", "Finished stealing eggs!", "Success", 3)
	end)
end)

local autoG = AddGroupbox(FarmTab, "Automation")
autoG:AddToggle("AutoPlaceEggs", { Text = "Auto Place Eggs", Default = false, Callback = function(v) Config.AutoPlaceEggs = v; if v then task.spawn(AutoPlaceEggsLoop) end end })
autoG:AddToggle("AutoHatchEggs", { Text = "Auto Hatch Eggs", Default = false, Callback = function(v) Config.AutoHatchEggs = v; if v then task.spawn(AutoHatchEggsLoop) end end })
autoG:AddToggle("AutoEquipBestPet", { Text = "Auto Equip Best Pet", Default = false, Callback = function(v) Config.AutoEquipBestPet = v; if v then task.spawn(AutoEquipBestPetLoop) end end })
autoG:AddToggle("AutoUpgradeTreadmill", { Text = "Auto Upgrade Treadmill", Default = false, Callback = function(v) Config.AutoUpgradeTreadmill = v; if v then task.spawn(AutoUpgradeTreadmillLoop) end end })
autoG:AddToggle("AutoUpgradeBase", { Text = "Auto Upgrade Base", Default = false, Callback = function(v) Config.AutoUpgradeBase = v; if v then task.spawn(AutoUpgradeBaseLoop) end end })
autoG:AddToggle("AutoSellPets", { Text = "Auto Sell Pets", Default = false, Callback = function(v) Config.AutoSellPets = v; if v then task.spawn(AutoSellPetsLoop) end end })
autoG:AddToggle("AutoClaimIndex", { Text = "Auto Claim Index", Default = false, Callback = function(v) Config.AutoClaimIndex = v; if v then task.spawn(AutoClaimIndexLoop) end end })

local PlayerTab = AddTab("Player")
local speedG = AddGroupbox(PlayerTab, "Speed")
speedG:AddToggle("SpeedEnabled", { Text = "Enable Speed", Default = false, Callback = function(v)
	Config.Speed_Enabled = v
	if not v then pcall(function() GetHumanoid().WalkSpeed = 16 end) end
end })
speedG:AddSlider("SpeedValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 500, Callback = function(v) Config.Speed_Value = v end })

local jumpG = AddGroupbox(PlayerTab, "Jump")
jumpG:AddToggle("JumpPowerEnabled", { Text = "Enable Jump Power", Default = false, Callback = function(v)
	Config.JumpPower_Enabled = v
	if not v then pcall(function() GetHumanoid().JumpPower = 50 end) end
end })
jumpG:AddSlider("JumpPowerValue", { Text = "Jump Power", Default = 50, Min = 50, Max = 500, Callback = function(v) Config.JumpPower_Value = v end })
jumpG:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false, Callback = function(v) Config.InfiniteJump = v end })

local miscG = AddGroupbox(PlayerTab, "Misc")
miscG:AddToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(v) Config.Noclip = v end })
miscG:AddToggle("ClickTeleport", { Text = "Click Teleport", Default = false, Callback = function(v) Config.ClickTeleport = v end })
miscG:AddToggle("AntiAFK", { Text = "Anti AFK", Default = false, Callback = function(v) Config.AntiAFK = v; if v then task.spawn(AntiAFKLoop) end end })

local flyG = AddGroupbox(PlayerTab, "Fly")
flyG:AddToggle("FlyEnabled", { Text = "Enable Fly", Default = false, Callback = function(v) Config.Fly_Enabled = v end })
flyG:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Callback = function(v) Config.Fly_Speed = v end })

local VisualsTab = AddTab("Visuals")
local espG1 = AddGroupbox(VisualsTab, "Player ESP")
espG1:AddToggle("PlayerESP", { Text = "Enable Player ESP", Default = false, Callback = function(v) Config.PlayerESP = v end })
espG1:AddColorPicker("PlayerESPColor", { Text = "Player ESP Color", Default = Color3.fromRGB(100, 200, 255), Callback = function(v) Config.PlayerESPColor = v end })

local espG2 = AddGroupbox(VisualsTab, "Egg & Pet ESP")
espG2:AddToggle("EggESP", { Text = "Enable Egg ESP", Default = false, Callback = function(v) Config.EggESP = v end })
espG2:AddToggle("PetESP", { Text = "Enable Pet ESP", Default = false, Callback = function(v) Config.PetESP = v end })
espG2:AddToggle("ChestESP", { Text = "Enable Chest/Drop ESP", Default = false, Callback = function(v) Config.ChestESP = v end })

local worldG = AddGroupbox(VisualsTab, "World")
worldG:AddButton("Full Bright", function()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
end)
worldG:AddButton("Remove Fog", function()
	Lighting.FogEnd = 999999
	Lighting.FogStart = 0
end)
worldG:AddButton("Reset Lighting", function()
	Lighting.Brightness = 1
	Lighting.ClockTime = 12
	Lighting.FogEnd = 100000
end)
worldG:AddButton("Fast Mode", function()
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
	Notify("Ivory", "Fast Mode enabled", "Info", 3)
end)

local TeleportTab = AddTab("Teleport")
local tpG = AddGroupbox(TeleportTab, "Locations")
tpG:AddButton("Teleport to Base", function()
	task.spawn(function()
		local b = GetBase()
		if b then
			local r = b:FindFirstChild("HumanoidRootPart") or b:GetPivot().Position
			if typeof(r) == "Vector3" then TeleportTo(r) elseif r then TeleportTo(r.Position) end
		end
	end)
end)
tpG:AddButton("Teleport to Treadmill", function()
	task.spawn(function()
		local tm = Workspace:FindFirstChild("Treadmill") or Workspace:FindFirstChild("treadmill") or Workspace:FindFirstChild("Training")
		if tm then
			local r = tm:FindFirstChildWhichIsA("BasePart") or tm.PrimaryPart
			if r then TeleportTo(r.Position) end
		end
	end)
end)
tpG:AddButton("Teleport to Egg Shop", function()
	task.spawn(function()
		local s = Workspace:FindFirstChild("EggShop") or Workspace:FindFirstChild("Shop") or Workspace:FindFirstChild("EggStore")
		if s then
			local r = s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart
			if r then TeleportTo(r.Position) end
		end
	end)
end)
tpG:AddButton("Teleport to Sell Area", function()
	task.spawn(function()
		local s = Workspace:FindFirstChild("Sell") or Workspace:FindFirstChild("SellArea") or Workspace:FindFirstChild("Selling")
		if s then
			local r = s:FindFirstChildWhichIsA("BasePart") or s.PrimaryPart
			if r then TeleportTo(r.Position) end
		end
	end)
end)

local srvG = AddGroupbox(TeleportTab, "Server")
srvG:AddButton("Rejoin Server", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)
srvG:AddButton("Server Hop", function()
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
srvG:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	Notify("Ivory", "JobId copied!", "Success", 2)
end)

local SettingsTab = AddTab("Settings")
local menuG = AddGroupbox(SettingsTab, "Menu")
menuG:AddButton("Unload", function()
	stopFly()
	setNoclip(false)
	ScreenGui:Destroy()
end)
menuG:AddButton("Hide/Show Menu", function() MainFrame.Visible = not MainFrame.Visible end)
menuG:AddButton("Test Notification", function()
	Notify("Ivory", "This is a test notification!", "Info", 3)
end)
menuG:AddLabel("Toggle: RightShift")

--// ═══════════════════════════════════════════════════════════
--// CONNECTIONS
--// ═══════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		MainFrame.Visible = not MainFrame.Visible
	end
	if Config.ClickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
		pcall(function()
			local mouse = LocalPlayer:GetMouse()
			local hrp = GetHRP()
			if hrp then hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0)) end
		end)
	end
end)

UserInputService.JumpRequest:Connect(function()
	if Config.InfiniteJump then
		pcall(function()
			local h = GetHumanoid()
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
end)

RunService.RenderStepped:Connect(function()
	if Config.Speed_Enabled then pcall(function() GetHumanoid().WalkSpeed = Config.Speed_Value end) end
	if Config.JumpPower_Enabled then pcall(function() GetHumanoid().JumpPower = Config.JumpPower_Value end) end
	if Config.Fly_Enabled then
		if not flyBodyVelocity then startFly() end
		pcall(function()
			local hrp = GetHRP()
			if not hrp then return end
			local camCF = Workspace.CurrentCamera.CFrame
			local moveDir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
			if moveDir.Magnitude > 0 then
				flyBodyVelocity.Velocity = moveDir.Unit * Config.Fly_Speed
			else
				flyBodyVelocity.Velocity = Vector3.zero
			end
			flyBodyGyro.CFrame = camCF
		end)
	else
		if flyBodyVelocity then stopFly() end
	end
	if Config.Noclip then if not noclipConn then setNoclip(true) end else if noclipConn then setNoclip(false) end end
end)

task.spawn(function() while task.wait(60) do if Config.AntiAFK then pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end end end)
task.spawn(function() while task.wait(2) do UpdateESP() end end)
task.spawn(function() while task.wait(1) do if Config.ServerHop then Config.ServerHop = false; task.spawn(ServerHopLoop) end end end)

-- Walk on Water
task.spawn(function()
	while true do
		task.wait(0.5)
		if Config.WalkOnWater then
			pcall(function()
				local hrp = GetHRP()
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

Notify("Ivory", "v1.4 loaded successfully", "Success", 5)
