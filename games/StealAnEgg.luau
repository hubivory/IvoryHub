--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

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
	AutoBuyTrails = false,
	InstantSteal = false,
	AutoDropHeld = false,
	EggESP = false,
	ServerHop = false,
	ServerHopDelay = 30,
	AntiAFK = false,
	CustomSpeed = false,
	WalkSpeed = 50,
	StealDelay = 0.5,
	TweenSpeed = 5,
	TargetRarities = {},
	SelectedRarities = {},
	SelectedArea = "All",
}

local AreaMap = {} -- [{name, center, prompts}]
local AREA_NAMES_ORDER = {"Forest", "Desert", "Lake", "Jungle", "Snow", "Volcano", "Prehistoric", "Abyss Ocean", "Cherry Blossom", "Cosmic", "Titan Temple"}

local RarityCache = {}
local RarityNames = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
	"Mythic", "Cosmic", "Secret", "Eternal", "Divine",
	"Exotic", "Limited", "Exclusive", "Superior", "Titan",
}

local ScreenGui = nil
local MainFrame = nil
local CurrentTab = "Steal"
local Tabs = {}

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
	local hum = GetHumanoid()
	if not hrp or not hum then return false end

	if Config.InstantSteal then
		hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		return true
	end

	local target = position + Vector3.new(0, 3, 0)
	local dist = (target - hrp.Position).Magnitude
	if dist <= 0.5 then return true end

	local prevSpeed = hum.WalkSpeed
	hum.WalkSpeed = math.max(Config.WalkSpeed, 16)

	local waypoints = nil
	pcall(function()
		local path = PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			AgentCanClimb = false,
			WaypointSpacing = 8,
		})
		path:ComputeAsync(hrp.Position, target)
		if path.Status == Enum.PathStatus.Success then
			waypoints = path:GetWaypoints()
		end
	end)

	if waypoints then
		for i = 2, #waypoints do
			local wp = waypoints[i]
			local wpTarget = wp.Position + Vector3.new(0, 3, 0)
			local done = false
			local timeout = tick() + 5
			local conn
			conn = hum.MoveToFinished:Connect(function()
				done = true
				if conn then conn:Disconnect() end
			end)
			hum:MoveTo(wpTarget)
			while not done and tick() < timeout do
				task.wait(0.05)
			end
			if conn then conn:Disconnect() end
		end
	else
		local done = false
		local timeout = tick() + math.clamp(dist / 20, 3, 15)
		local conn
		conn = hum.MoveToFinished:Connect(function()
			done = true
			if conn then conn:Disconnect() end
		end)
		hum:MoveTo(target)
		while not done and tick() < timeout do
			task.wait(0.05)
		end
		if conn then conn:Disconnect() end
	end

	hum.WalkSpeed = prevSpeed
	return true
end

local function BuildAreaMap()
	AreaMap = {}
	local allPrompts = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.ActionText == "Steal" and obj.ObjectText == "Egg" then
			local part = obj.Parent
			if part and part:IsA("BasePart") then
				table.insert(allPrompts, {prompt = obj, part = part, x = part.Position.X})
			end
		end
	end

	if #allPrompts == 0 then return end

	table.sort(allPrompts, function(a, b) return a.x < b.x end)

	local clusters = {}
	local current = {allPrompts[1]}
	for i = 2, #allPrompts do
		if allPrompts[i].x - allPrompts[i - 1].x > 100 then
			table.insert(clusters, current)
			current = {allPrompts[i]}
		else
			table.insert(current, allPrompts[i])
		end
	end
	table.insert(clusters, current)

	for i, cluster in ipairs(clusters) do
		local sumX, sumY, sumZ = 0, 0, 0
		for _, entry in ipairs(cluster) do
			sumX = sumX + entry.part.Position.X
			sumY = sumY + entry.part.Position.Y
			sumZ = sumZ + entry.part.Position.Z
		end
		local n = #cluster
		local name = AREA_NAMES_ORDER[i] or ("Area " .. i)
		table.insert(AreaMap, {
			name = name,
			center = Vector3.new(sumX / n, sumY / n, sumZ / n),
			prompts = {},
		})
		for _, entry in ipairs(cluster) do
			table.insert(AreaMap[#AreaMap].prompts, entry.prompt)
		end
	end
end

local function GetStealPrompts()
	if Config.SelectedArea == "All" then
		local prompts = {}
		for _, area in ipairs(AreaMap) do
			for _, p in ipairs(area.prompts) do
				table.insert(prompts, p)
			end
		end
		return prompts
	end

	for _, area in ipairs(AreaMap) do
		if area.name == Config.SelectedArea then
			return area.prompts
		end
	end
	return {}
end

local function GetAreaCenter(areaName)
	for _, area in ipairs(AreaMap) do
		if area.name == areaName then
			return area.center
		end
	end
	return nil
end

local function GetNearestStealPrompt()
	local hrp = GetHRP()
	if not hrp then return nil, math.huge end

	local nearest = nil
	local nearestDist = math.huge

	for _, prompt in ipairs(GetStealPrompts()) do
		local part = prompt.Parent
		if part and part:IsA("BasePart") then
			local dist = (part.Position - hrp.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearest = prompt
			end
		end
	end

	return nearest, nearestDist
end

local function GetBase()
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return nil end

	local hrp = GetHRP()
	if not hrp then return nil end

	local nearestPlot = nil
	local nearestDist = math.huge

	for _, plot in ipairs(plots:GetChildren()) do
		if plot:IsA("Model") then
			local pivot = plot:GetPivot()
			local dist = (pivot.Position - hrp.Position).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestPlot = plot
			end
		end
	end

	return nearestPlot
end

local function GetHeldEgg()
	local char = GetCharacter()
	if not char then return nil end
	return char:FindFirstChild("HoldingEgg")
		or char:FindFirstChild("HeldEgg")
		or char:FindFirstChildWhichIsA("MeshPart")
end

local function InitRaritySystem()
	pcall(function()
		local rarityData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Rarity"))
		if rarityData and rarityData.Configs then
			for name, config in pairs(rarityData.Configs) do
				if config.DisplayName then
					RarityCache[name] = config.DisplayName
				end
			end
		end
	end)

	pcall(function()
		local eggState = require(ReplicatedStorage:WaitForChild("Client"):WaitForChild("EggState"))
		if eggState and eggState.RarityPresented then
			eggState.RarityPresented:Connect(function(data)
				if type(data) == "table" then
					for uid, rarity in pairs(data) do
						if type(rarity) == "string" then
							RarityCache[tostring(uid)] = rarity
						end
					end
				end
			end)
		end
	end)

	pcall(function()
		local rarityShown = ReplicatedStorage
			:WaitForChild("Packages")
			:WaitForChild("Networking")
			:FindFirstChild("RE/EggWorld/FieldEggRaritiesShown")
		if rarityShown and rarityShown:IsA("RemoteEvent") then
			rarityShown.OnClientEvent:Connect(function(data)
				if type(data) == "table" then
					for key, val in pairs(data) do
						if type(val) == "string" then
							RarityCache[tostring(key)] = val
						elseif type(val) == "table" and val.Rarity then
							RarityCache[tostring(key)] = val.Rarity
						elseif type(val) == "table" and val.rarity then
							RarityCache[tostring(key)] = val.rarity
						end
					end
				end
			end)
		end
	end)
end

local function GetEggRarityFromSmartPart(smartPart)
	if not smartPart then return "Unknown" end

	local pos = smartPart.Position
	local posKey = math.floor(pos.X) .. "," .. math.floor(pos.Z)
	if RarityCache[posKey] then return RarityCache[posKey] end

	local cra = Workspace:FindFirstChild("ClientRenderedAssets")
	if cra then
		for _, model in ipairs(cra:GetChildren()) do
			if model:IsA("Model") then
				local pivot = model:GetPivot()
				local dist = (pivot.Position - pos).Magnitude
				if dist < 12 then
					local bbg = model:FindFirstChild("Data")
					if bbg and bbg:IsA("BillboardGui") then
						local odds = bbg:FindFirstChild("Odds")
						if odds and odds:IsA("TextLabel") and odds.Text ~= "" then
							RarityCache[posKey] = odds.Text
							return odds.Text
						end
						local rarityLabel = bbg:FindFirstChild("Rarity")
						if rarityLabel and rarityLabel:IsA("TextLabel") and rarityLabel.Text ~= "" then
							RarityCache[posKey] = rarityLabel.Text
							return rarityLabel.Text
						end
					end
				end
			end
		end
	end

	local eggModel = nil
	local eggDist = math.huge
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("Egg") then
			local pivot = obj:GetPivot()
			local dist = (pivot.Position - pos).Magnitude
			if dist < eggDist then
				eggDist = dist
				eggModel = obj
			end
		end
	end

	if eggModel and eggDist < 12 then
		for _, descendant in ipairs(eggModel:GetDescendants()) do
			if descendant:IsA("TextLabel") and descendant.Visible then
				local text = descendant.Text
				if text and text ~= "" then
					for _, rName in ipairs(RarityNames) do
						if text:lower():find(rName:lower()) then
							RarityCache[posKey] = rName
							return rName
						end
					end
				end
			end
		end
	end

	return "Unknown"
end

local function IsEggTargeted(smartPart)
	if #Config.SelectedRarities == 0 then return true end

	local rarity = GetEggRarityFromSmartPart(smartPart)
	if rarity == "Unknown" then return true end

	for _, r in ipairs(Config.SelectedRarities) do
		if r == rarity then
			return true
		end
	end

	return false
end

local function StealEgg(prompt)
	if not prompt or not IsAlive() then return false end

	local smartPart = prompt.Parent
	if not smartPart or not smartPart:IsA("BasePart") then return false end

	local eggPos = smartPart.Position
	local base = GetBase()

	TeleportTo(eggPos)
	task.wait(Config.StealDelay)

	pcall(function()
		fireproximityprompt(prompt)
	end)

	task.wait(0.2)

	if Config.AutoReturnToBase and base then
		local basePos = base:GetPivot().Position
		TeleportTo(basePos)
		task.wait(0.3)
	end

	return true
end

local function AutoStealLoop()
	while Config.AutoSteal do
		if IsAlive() then
			if Config.SelectedArea ~= "All" then
				local center = GetAreaCenter(Config.SelectedArea)
				if center then
					local hrp = GetHRP()
					if hrp and (center - hrp.Position).Magnitude > 100 then
						TeleportTo(center)
						task.wait(0.5)
					end
				end
			end

			local prompt = GetNearestStealPrompt()
			if prompt and IsEggTargeted(prompt.Parent) then
				StealEgg(prompt)
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
					local basePos = base:GetPivot().Position
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

local function AutoBuyTrailsLoop()
	while Config.AutoBuyTrails do
		if IsAlive() then
			local buyEvent = ReplicatedStorage:FindFirstChild("BuyTrail")
			if buyEvent and buyEvent:IsA("RemoteEvent") then
				buyEvent:FireServer()
			end
		end
		task.wait(30)
	end
end

local function AntiAFKLoop()
	while Config.AntiAFK do
		if IsAlive() then
			local VirtualUser = game:GetService("VirtualUser")
			VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
			task.wait(0.1)
			VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
		end
		task.wait(60)
	end
end

local function SpeedLoop()
	while Config.CustomSpeed do
		local hum = GetHumanoid()
		if hum then
			hum.WalkSpeed = Config.WalkSpeed
		end
		task.wait(0.5)
	end
	local hum = GetHumanoid()
	if hum then
		hum.WalkSpeed = 16
	end
end

local ESPObjects = {}

local function CreateESP(part, color, text)
	if ESPObjects[part] then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EggESP"
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
		for _, prompt in ipairs(GetStealPrompts()) do
			local part = prompt.Parent
			if part and part:IsA("BasePart") and not ESPObjects[part] then
				local rarity = GetEggRarityFromSmartPart(part)
				local color = Color3.fromRGB(90, 220, 120)
				CreateESP(part, color, rarity)
			end
		end
	else
		for part, _ in pairs(ESPObjects) do
			RemoveESP(part)
		end
	end
end

local function ServerHop()
	local servers = {}
	local success, result = pcall(function()
		return HttpService:JSONDecode(
			game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		)
	end)

	if success and result and result.data then
		for _, server in ipairs(result.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				table.insert(servers, server.id)
			end
		end
	end

	if #servers > 0 then
		local randomServer = servers[math.random(1, #servers)]
		TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, LocalPlayer)
	end
end

local function CreateWindow(title)
	if ScreenGui then ScreenGui:Destroy() end

	ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "IvoryHub"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 999
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 380, 0, 520)
	MainFrame.Position = UDim2.new(0.5, -190, 0.5, -260)
	MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
	MainFrame.BorderSizePixel = 0
	MainFrame.Active = true
	MainFrame.Draggable = true
	MainFrame.ClipsDescendants = false
	MainFrame.Parent = ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = MainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(90, 80, 220)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = MainFrame

	local shadow = Instance.new("ImageLabel")
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -15)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6015897843"
	shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.ZIndex = -1
	shadow.Parent = MainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 44)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(30, 28, 50)
	titleLabel.BackgroundTransparency = 0
	titleLabel.Text = "  " .. (title or "Ivory")
	titleLabel.TextColor3 = Color3.fromRGB(220, 215, 255)
	titleLabel.TextSize = 16
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = MainFrame

	local titleGradient = Instance.new("UIGradient")
	titleGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(30, 28, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 35, 70)),
	})
	titleGradient.Rotation = 90
	titleGradient.Parent = titleLabel

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 10)
	titleCorner.Parent = titleLabel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 26, 0, 26)
	closeBtn.Position = UDim2.new(1, -34, 0, 9)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Text = ""
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 12
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleLabel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 6)
	closeCorner.Parent = closeBtn

	local closeX = Instance.new("TextLabel")
	closeX.Size = UDim2.new(1, 0, 1, 0)
	closeX.BackgroundTransparency = 1
	closeX.Text = "X"
	closeX.TextColor3 = Color3.new(1, 1, 1)
	closeX.TextSize = 12
	closeX.Font = Enum.Font.GothamBold
	closeX.Parent = closeBtn

	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	end)
	closeBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	local divider = Instance.new("Frame")
	divider.Size = UDim2.new(1, 0, 0, 1)
	divider.Position = UDim2.new(0, 0, 0, 44)
	divider.BackgroundColor3 = Color3.fromRGB(90, 80, 220)
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel = 0
	divider.Parent = MainFrame

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, -16, 0, 32)
	tabContainer.Position = UDim2.new(0, 8, 0, 50)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = MainFrame

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.Padding = UDim.new(0, 4)
	tabList.Parent = tabContainer

	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, -16, 1, -100)
	contentFrame.Position = UDim2.new(0, 8, 0, 88)
	contentFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
	contentFrame.BorderSizePixel = 0
	contentFrame.ClipsDescendants = true
	contentFrame.Parent = MainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 6)
	contentCorner.Parent = contentFrame

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, -4, 1, -4)
	scrollingFrame.Position = UDim2.new(0, 2, 0, 2)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 3
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 80, 220)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.Parent = contentFrame

	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 4)
	contentList.Parent = scrollingFrame

	local footer = Instance.new("TextLabel")
	footer.Size = UDim2.new(1, 0, 0, 18)
	footer.Position = UDim2.new(0, 0, 1, -20)
	footer.BackgroundTransparency = 1
	footer.Text = "v1.4 | Lobby/Game | " .. LocalPlayer.UserId
	footer.TextColor3 = Color3.fromRGB(80, 80, 100)
	footer.TextSize = 9
	footer.Font = Enum.Font.Gotham
	footer.Parent = MainFrame

	footer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pcall(function()
				if setclipboard then
					setclipboard(footer.Text)
				end
			end)
			footer.TextColor3 = Color3.fromRGB(150, 140, 255)
			task.delay(0.5, function()
				footer.TextColor3 = Color3.fromRGB(80, 80, 100)
			end)
		end
	end)

	Tabs = {}
	local tabNames = {"Steal", "Automation", "ESP", "Settings"}

	for _, tabName in ipairs(tabNames) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(0, 82, 0, 28)
		tabBtn.BackgroundColor3 = Color3.fromRGB(38, 36, 55)
		tabBtn.Text = tabName
		tabBtn.TextColor3 = Color3.fromRGB(140, 135, 180)
		tabBtn.TextSize = 11
		tabBtn.Font = Enum.Font.GothamMedium
		tabBtn.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 6)
		tabCorner.Parent = tabBtn

		Tabs[tabName] = {
			Button = tabBtn,
			Content = scrollingFrame,
			Sections = {}
		}

		tabBtn.MouseEnter:Connect(function()
			if CurrentTab ~= tabName then
				tabBtn.BackgroundColor3 = Color3.fromRGB(48, 45, 70)
			end
		end)
		tabBtn.MouseLeave:Connect(function()
			if CurrentTab ~= tabName then
				tabBtn.BackgroundColor3 = Color3.fromRGB(38, 36, 55)
			end
		end)
		tabBtn.MouseButton1Click:Connect(function()
			CurrentTab = tabName
			for name, tab in pairs(Tabs) do
				if name == tabName then
					tabBtn.BackgroundColor3 = Color3.fromRGB(90, 80, 220)
					tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				else
					tabBtn.BackgroundColor3 = Color3.fromRGB(38, 36, 55)
					tabBtn.TextColor3 = Color3.fromRGB(140, 135, 180)
				end
			end
			for name, tab in pairs(Tabs) do
				for _, section in ipairs(tab.Sections) do
					section.Frame.Visible = (name == tabName)
				end
			end
		end)
	end

	Tabs["Steal"].Button.BackgroundColor3 = Color3.fromRGB(90, 80, 220)
	Tabs["Steal"].Button.TextColor3 = Color3.fromRGB(255, 255, 255)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.RightShift then
			MainFrame.Visible = not MainFrame.Visible
		end
	end)

	return {
		Frame = MainFrame,
		Content = scrollingFrame,
		Tabs = Tabs,
		AddSection = function(self, tabName, sectionName)
			local tab = Tabs[tabName]
			if not tab then return nil end

			local section = Instance.new("Frame")
			section.Size = UDim2.new(1, 0, 0, 0)
			section.AutomaticSize = Enum.AutomaticSize.Y
			section.BackgroundColor3 = Color3.fromRGB(32, 30, 48)
			section.BackgroundTransparency = 0
			section.BorderSizePixel = 0
			section.Visible = (tabName == CurrentTab)
			section.Parent = tab.Content

			local sectionCorner = Instance.new("UICorner")
			sectionCorner.CornerRadius = UDim.new(0, 6)
			sectionCorner.Parent = section

			local sectionPadding = Instance.new("UIPadding")
			sectionPadding.PaddingTop = UDim.new(0, 6)
			sectionPadding.PaddingBottom = UDim.new(0, 6)
			sectionPadding.PaddingLeft = UDim.new(0, 8)
			sectionPadding.PaddingRight = UDim.new(0, 8)
			sectionPadding.Parent = section

			local sectionList = Instance.new("UIListLayout")
			sectionList.Padding = UDim.new(0, 2)
			sectionList.Parent = section

			local sectionLabel = Instance.new("TextLabel")
			sectionLabel.Size = UDim2.new(1, 0, 0, 18)
			sectionLabel.BackgroundTransparency = 1
			sectionLabel.Text = string.upper(sectionName)
			sectionLabel.TextColor3 = Color3.fromRGB(120, 110, 200)
			sectionLabel.TextSize = 10
			sectionLabel.Font = Enum.Font.GothamBold
			sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
			sectionLabel.LayoutOrder = 0
			sectionLabel.Parent = section

			table.insert(tab.Sections, {Frame = section, Name = sectionName})

			return {
				Frame = section,
				AddToggle = function(self, text, default, callback)
					local toggle = Instance.new("Frame")
					toggle.Size = UDim2.new(1, 0, 0, 28)
					toggle.BackgroundColor3 = Color3.fromRGB(36, 34, 52)
					toggle.BackgroundTransparency = 0
					toggle.BorderSizePixel = 0
					toggle.Parent = section

					local togglePadding = Instance.new("UIPadding")
					togglePadding.PaddingLeft = UDim.new(0, 4)
					togglePadding.PaddingRight = UDim.new(0, 4)
					togglePadding.Parent = toggle

					local toggleInnerCorner = Instance.new("UICorner")
					toggleInnerCorner.CornerRadius = UDim.new(0, 4)
					toggleInnerCorner.Parent = toggle

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(0.65, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = text
					label.TextColor3 = Color3.fromRGB(200, 195, 230)
					label.TextSize = 11
					label.Font = Enum.Font.Gotham
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = toggle

					local toggleBtn = Instance.new("TextButton")
					toggleBtn.Size = UDim2.new(0, 38, 0, 18)
					toggleBtn.Position = UDim2.new(0.78, 0, 0.5, -9)
					toggleBtn.BackgroundColor3 = default and Color3.fromRGB(80, 180, 80) or Color3.fromRGB(60, 58, 80)
					toggleBtn.Text = ""
					toggleBtn.TextColor3 = Color3.new(1, 1, 1)
					toggleBtn.TextSize = 9
					toggleBtn.Font = Enum.Font.GothamBold
					toggleBtn.Parent = toggle

					local toggleCorner = Instance.new("UICorner")
					toggleCorner.CornerRadius = UDim.new(0, 9)
					toggleCorner.Parent = toggleBtn

					local toggleLabel = Instance.new("TextLabel")
					toggleLabel.Size = UDim2.new(1, 0, 1, 0)
					toggleLabel.BackgroundTransparency = 1
					toggleLabel.Text = default and "ON" or "OFF"
					toggleLabel.TextColor3 = Color3.new(1, 1, 1)
					toggleLabel.TextSize = 9
					toggleLabel.Font = Enum.Font.GothamBold
					toggleLabel.Parent = toggleBtn

					local indicator = Instance.new("Frame")
					indicator.Size = UDim2.new(0, 14, 0, 14)
					indicator.Position = default and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
					indicator.BackgroundColor3 = Color3.new(1, 1, 1)
					indicator.BorderSizePixel = 0
					indicator.Parent = toggleBtn

					local indicatorCorner = Instance.new("UICorner")
					indicatorCorner.CornerRadius = UDim.new(1, 0)
					indicatorCorner.Parent = indicator

					local state = default or false

					local function updateToggle()
						if state then
							toggleBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
							toggleLabel.Text = "ON"
							indicator.Position = UDim2.new(1, -16, 0.5, -7)
						else
							toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 58, 80)
							toggleLabel.Text = "OFF"
							indicator.Position = UDim2.new(0, 2, 0.5, -7)
						end
					end

					toggleBtn.MouseButton1Click:Connect(function()
						state = not state
						updateToggle()
						if callback then callback(state) end
					end)

					return {
						Set = function(self, value)
							state = value
							updateToggle()
							if callback then callback(state) end
						end,
						Get = function(self) return state end
					}
				end,
				AddSlider = function(self, text, min, max, default, callback)
					local slider = Instance.new("Frame")
					slider.Size = UDim2.new(1, 0, 0, 38)
					slider.BackgroundColor3 = Color3.fromRGB(36, 34, 52)
					slider.BackgroundTransparency = 0
					slider.BorderSizePixel = 0
					slider.Parent = section

					local sliderInnerCorner = Instance.new("UICorner")
					sliderInnerCorner.CornerRadius = UDim.new(0, 4)
					sliderInnerCorner.Parent = slider

					local sLabel = Instance.new("TextLabel")
					sLabel.Size = UDim2.new(0.55, 0, 0, 16)
					sLabel.Position = UDim2.new(0, 8, 0, 4)
					sLabel.BackgroundTransparency = 1
					sLabel.Text = text
					sLabel.TextColor3 = Color3.fromRGB(200, 195, 230)
					sLabel.TextSize = 11
					sLabel.Font = Enum.Font.Gotham
					sLabel.TextXAlignment = Enum.TextXAlignment.Left
					sLabel.Parent = slider

					local valueLabel = Instance.new("TextLabel")
					valueLabel.Size = UDim2.new(0.35, -8, 0, 16)
					valueLabel.Position = UDim2.new(0.6, 0, 0, 4)
					valueLabel.BackgroundTransparency = 1
					valueLabel.Text = tostring(default)
					valueLabel.TextColor3 = Color3.fromRGB(140, 130, 255)
					valueLabel.TextSize = 11
					valueLabel.Font = Enum.Font.GothamBold
					valueLabel.TextXAlignment = Enum.TextXAlignment.Right
					valueLabel.Parent = slider

					local sliderBg = Instance.new("Frame")
					sliderBg.Size = UDim2.new(1, -16, 0, 4)
					sliderBg.Position = UDim2.new(0, 8, 0, 28)
					sliderBg.BackgroundColor3 = Color3.fromRGB(45, 42, 65)
					sliderBg.Parent = slider

					local sliderCorner = Instance.new("UICorner")
					sliderCorner.CornerRadius = UDim.new(0, 2)
					sliderCorner.Parent = sliderBg

					local fill = Instance.new("Frame")
					fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
					fill.BackgroundColor3 = Color3.fromRGB(90, 80, 220)
					fill.Parent = sliderBg

					local fillCorner = Instance.new("UICorner")
					fillCorner.CornerRadius = UDim.new(0, 2)
					fillCorner.Parent = fill

					local knob = Instance.new("TextButton")
					knob.Size = UDim2.new(0, 14, 0, 14)
					knob.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
					knob.BackgroundColor3 = Color3.new(1, 1, 1)
					knob.Text = ""
					knob.Parent = sliderBg

					local knobCorner = Instance.new("UICorner")
					knobCorner.CornerRadius = UDim.new(1, 0)
					knobCorner.Parent = knob

					local knobShadow = Instance.new("Frame")
					knobShadow.Size = UDim2.new(1, 4, 1, 4)
					knobShadow.Position = UDim2.new(0, -2, 0, -2)
					knobShadow.BackgroundColor3 = Color3.fromRGB(90, 80, 220)
					knobShadow.BackgroundTransparency = 0.6
					knobShadow.BorderSizePixel = 0
					knobShadow.ZIndex = -1
					knobShadow.Parent = knob

					local knobShadowCorner = Instance.new("UICorner")
					knobShadowCorner.CornerRadius = UDim.new(1, 0)
					knobShadowCorner.Parent = knobShadow

					local dragging = false
					local currentValue = default

					knob.MouseButton1Down:Connect(function()
						dragging = true
					end)

					UserInputService.InputEnded:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = false
						end
					end)

					UserInputService.InputChanged:Connect(function(input)
						if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
							local mousePos = UserInputService:GetMouseLocation()
							local sPos = sliderBg.AbsolutePosition.X
							local sSize = sliderBg.AbsoluteSize.X

							local percent = math.clamp((mousePos.X - sPos) / sSize, 0, 1)
							currentValue = math.floor(min + (max - min) * percent)

							fill.Size = UDim2.new(percent, 0, 1, 0)
							knob.Position = UDim2.new(percent, -7, 0.5, -7)
							valueLabel.Text = tostring(currentValue)

							if callback then callback(currentValue) end
						end
					end)

					return {
						Set = function(self, value)
							currentValue = math.clamp(value, min, max)
							local percent = (currentValue - min) / (max - min)
							fill.Size = UDim2.new(percent, 0, 1, 0)
							knob.Position = UDim2.new(percent, -7, 0.5, -7)
							valueLabel.Text = tostring(currentValue)
							if callback then callback(currentValue) end
						end,
						Get = function(self) return currentValue end
					}
				end,
				AddButton = function(self, text, callback)
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, 0, 0, 28)
					btn.BackgroundColor3 = Color3.fromRGB(45, 42, 70)
					btn.Text = text
					btn.TextColor3 = Color3.fromRGB(200, 195, 230)
					btn.TextSize = 11
					btn.Font = Enum.Font.GothamMedium
					btn.Parent = section

					local btnCorner = Instance.new("UICorner")
					btnCorner.CornerRadius = UDim.new(0, 4)
					btnCorner.Parent = btn

					btn.MouseEnter:Connect(function()
						btn.BackgroundColor3 = Color3.fromRGB(55, 52, 85)
					end)
					btn.MouseLeave:Connect(function()
						btn.BackgroundColor3 = Color3.fromRGB(45, 42, 70)
					end)
					btn.MouseButton1Click:Connect(function()
						btn.BackgroundColor3 = Color3.fromRGB(90, 80, 220)
						task.delay(0.15, function()
							btn.BackgroundColor3 = Color3.fromRGB(45, 42, 70)
						end)
						if callback then callback() end
					end)

					return {Button = btn}
				end,
				AddDropdown = function(self, text, options, default, multiSelect, callback)
					local dropdown = Instance.new("Frame")
					dropdown.Size = UDim2.new(1, 0, 0, 28)
					dropdown.BackgroundColor3 = Color3.fromRGB(36, 34, 52)
					dropdown.BackgroundTransparency = 0
					dropdown.BorderSizePixel = 0
					dropdown.Parent = section

					local dropInnerCorner = Instance.new("UICorner")
					dropInnerCorner.CornerRadius = UDim.new(0, 4)
					dropInnerCorner.Parent = dropdown

					local dLabel = Instance.new("TextLabel")
					dLabel.Size = UDim2.new(0.5, 0, 1, 0)
					dLabel.Position = UDim2.new(0, 8, 0, 0)
					dLabel.BackgroundTransparency = 1
					dLabel.Text = text
					dLabel.TextColor3 = Color3.fromRGB(200, 195, 230)
					dLabel.TextSize = 11
					dLabel.Font = Enum.Font.Gotham
					dLabel.TextXAlignment = Enum.TextXAlignment.Left
					dLabel.Parent = dropdown

					local dropBtn = Instance.new("TextButton")
					dropBtn.Size = UDim2.new(0.42, -4, 0, 20)
					dropBtn.Position = UDim2.new(0.58, 0, 0.5, -10)
					dropBtn.BackgroundColor3 = Color3.fromRGB(45, 42, 65)
					dropBtn.Text = "  Select..."
					dropBtn.TextColor3 = Color3.fromRGB(160, 155, 200)
					dropBtn.TextSize = 10
					dropBtn.Font = Enum.Font.Gotham
					dropBtn.TextXAlignment = Enum.TextXAlignment.Left
					dropBtn.Parent = dropdown

					local dropCorner = Instance.new("UICorner")
					dropCorner.CornerRadius = UDim.new(0, 4)
					dropCorner.Parent = dropBtn

					local arrow = Instance.new("TextLabel")
					arrow.Size = UDim2.new(0, 16, 0, 20)
					arrow.Position = UDim2.new(1, -16, 0, 0)
					arrow.BackgroundTransparency = 1
					arrow.Text = ">"
					arrow.TextColor3 = Color3.fromRGB(120, 110, 200)
					arrow.TextSize = 10
					arrow.Font = Enum.Font.GothamBold
					arrow.Parent = dropBtn

					local selected = default or {}
					local isOpen = false
					local maxVisible = 5
					local optionHeight = 24
					local visibleHeight = math.min(#options, maxVisible) * optionHeight

					local optionsFrame = Instance.new("Frame")
					optionsFrame.Size = UDim2.new(0.42, 0, 0, visibleHeight)
					optionsFrame.Position = UDim2.new(0.58, 0, 0, 28)
					optionsFrame.BackgroundColor3 = Color3.fromRGB(38, 36, 55)
					optionsFrame.BorderSizePixel = 0
					optionsFrame.Visible = false
					optionsFrame.ZIndex = 50
					optionsFrame.ClipsDescendants = true
					optionsFrame.Parent = MainFrame

					local optionsFrameCorner = Instance.new("UICorner")
					optionsFrameCorner.CornerRadius = UDim.new(0, 4)
					optionsFrameCorner.Parent = optionsFrame

					local optionsFrameStroke = Instance.new("UIStroke")
					optionsFrameStroke.Color = Color3.fromRGB(90, 80, 220)
					optionsFrameStroke.Thickness = 1
					optionsFrameStroke.Transparency = 0.5
					optionsFrameStroke.Parent = optionsFrame

					local optionsScroll = Instance.new("ScrollingFrame")
					optionsScroll.Size = UDim2.new(1, 0, 1, 0)
					optionsScroll.BackgroundTransparency = 1
					optionsScroll.ScrollBarThickness = 2
					optionsScroll.ScrollBarImageColor3 = Color3.fromRGB(90, 80, 220)
					optionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight)
					optionsScroll.BorderSizePixel = 0
					optionsScroll.ZIndex = 51
					optionsScroll.Parent = optionsFrame

					local optionsList = Instance.new("UIListLayout")
					optionsList.Padding = UDim.new(0, 2)
					optionsList.Parent = optionsScroll

					for _, option in ipairs(options) do
						local optBtn = Instance.new("TextButton")
						optBtn.Size = UDim2.new(1, -4, 0, optionHeight - 2)
						optBtn.Position = UDim2.new(0, 2, 0, 0)
						optBtn.BackgroundColor3 = Color3.fromRGB(42, 40, 62)
						optBtn.Text = "  " .. option
						optBtn.TextColor3 = Color3.fromRGB(180, 175, 210)
						optBtn.TextSize = 10
						optBtn.Font = Enum.Font.Gotham
						optBtn.TextXAlignment = Enum.TextXAlignment.Left
						optBtn.ZIndex = 52
						optBtn.Parent = optionsScroll

						local optCorner = Instance.new("UICorner")
						optCorner.CornerRadius = UDim.new(0, 3)
						optCorner.Parent = optBtn

						optBtn.MouseEnter:Connect(function()
							optBtn.BackgroundColor3 = Color3.fromRGB(55, 52, 80)
						end)
						optBtn.MouseLeave:Connect(function()
							optBtn.BackgroundColor3 = Color3.fromRGB(42, 40, 62)
						end)

						optBtn.MouseButton1Click:Connect(function()
							if multiSelect then
								local found = false
								for i, s in ipairs(selected) do
									if s == option then
										table.remove(selected, i)
										found = true
										break
									end
								end
								if not found then
									table.insert(selected, option)
								end
								dropBtn.Text = #selected > 0 and "  " .. table.concat(selected, ", ") or "  Select..."
							else
								selected = {option}
								dropBtn.Text = "  " .. option
								optionsFrame.Visible = false
								isOpen = false
							end
							if callback then callback(selected) end
						end)
					end

					local function updateArrow()
						arrow.Text = isOpen and "v" or ">"
					end

					dropBtn.MouseButton1Click:Connect(function()
						isOpen = not isOpen
						optionsFrame.Visible = isOpen
						updateArrow()
					end)

					return {
						Set = function(self, value)
							if type(value) == "table" then
								selected = value
								dropBtn.Text = #selected > 0 and "  " .. table.concat(selected, ", ") or "  Select..."
							else
								selected = {value}
								dropBtn.Text = "  " .. value
							end
							if callback then callback(selected) end
						end,
						Get = function(self) return selected end
					}
				end
			}
		end
	}
end

local function Main()
	InitRaritySystem()
	BuildAreaMap()
	local window = CreateWindow("Ivory")

	local stealSection = window:AddSection("Steal", "Egg Stealing")

	local areaOptions = {"All"}
	for _, area in ipairs(AreaMap) do
		table.insert(areaOptions, area.name)
	end

	stealSection:AddDropdown("Target Area", areaOptions, {"All"}, false, function(selected)
		Config.SelectedArea = #selected > 0 and selected[1] or "All"
	end)

	stealSection:AddToggle("Auto Steal Eggs", false, function(state)
		Config.AutoSteal = state
		if state then
			task.spawn(AutoStealLoop)
		end
	end)

	stealSection:AddSlider("Steal Delay (s)", 1, 50, 5, function(value)
		Config.StealDelay = value / 10
	end)

	stealSection:AddSlider("Tween Speed", 1, 10, 5, function(value)
		Config.TweenSpeed = value
	end)

	stealSection:AddToggle("Instant Steal", false, function(state)
		Config.InstantSteal = state
	end)

	stealSection:AddToggle("Auto Return to Base", true, function(state)
		Config.AutoReturnToBase = state
	end)

	stealSection:AddDropdown("Rarity Filter", RarityNames, {}, true, function(selected)
		Config.SelectedRarities = selected
	end)

	stealSection:AddButton("Steal Nearest Egg", function()
		if IsAlive() then
			local prompt = GetNearestStealPrompt()
			if prompt and IsEggTargeted(prompt.Parent) then
				StealEgg(prompt)
			end
		end
	end)

	stealSection:AddButton("Steal All Eggs", function()
		task.spawn(function()
			if Config.SelectedArea ~= "All" then
				local center = GetAreaCenter(Config.SelectedArea)
				if center then
					TeleportTo(center)
					task.wait(0.5)
				end
			end

			local prompts = GetStealPrompts()
			for _, prompt in ipairs(prompts) do
				if IsAlive() and IsEggTargeted(prompt.Parent) then
					StealEgg(prompt)
					task.wait(Config.StealDelay)
				end
			end
		end)
	end)

	stealSection:AddButton("Go to Area", function()
		if Config.SelectedArea ~= "All" then
			local center = GetAreaCenter(Config.SelectedArea)
			if center then
				TeleportTo(center)
			end
		end
	end)

	stealSection:AddButton("Refresh Areas", function()
		BuildAreaMap()
	end)

	local autoSection = window:AddSection("Automation", "Automation")

	autoSection:AddToggle("Auto Place Eggs", false, function(state)
		Config.AutoPlaceEggs = state
		if state then task.spawn(AutoPlaceEggsLoop) end
	end)

	autoSection:AddToggle("Auto Hatch Eggs", false, function(state)
		Config.AutoHatchEggs = state
		if state then task.spawn(AutoHatchEggsLoop) end
	end)

	autoSection:AddToggle("Auto Equip Best Pet", false, function(state)
		Config.AutoEquipBestPet = state
		if state then task.spawn(AutoEquipBestPetLoop) end
	end)

	autoSection:AddToggle("Auto Upgrade Treadmill", false, function(state)
		Config.AutoUpgradeTreadmill = state
		if state then task.spawn(AutoUpgradeTreadmillLoop) end
	end)

	autoSection:AddToggle("Auto Upgrade Base", false, function(state)
		Config.AutoUpgradeBase = state
		if state then task.spawn(AutoUpgradeBaseLoop) end
	end)

	autoSection:AddToggle("Auto Sell Pets", false, function(state)
		Config.AutoSellPets = state
		if state then task.spawn(AutoSellPetsLoop) end
	end)

	autoSection:AddToggle("Auto Claim Index", false, function(state)
		Config.AutoClaimIndex = state
		if state then task.spawn(AutoClaimIndexLoop) end
	end)

	autoSection:AddToggle("Auto Buy Trails", false, function(state)
		Config.AutoBuyTrails = state
		if state then task.spawn(AutoBuyTrailsLoop) end
	end)

	autoSection:AddToggle("Anti AFK", false, function(state)
		Config.AntiAFK = state
		if state then task.spawn(AntiAFKLoop) end
	end)

	autoSection:AddToggle("Custom Speed", false, function(state)
		Config.CustomSpeed = state
		if state then task.spawn(SpeedLoop) end
	end)

	autoSection:AddSlider("Walk Speed", 16, 500, 50, function(value)
		Config.WalkSpeed = value
		local hum = GetHumanoid()
		if hum and Config.CustomSpeed then
			hum.WalkSpeed = value
		end
	end)

	local espSection = window:AddSection("ESP", "Egg ESP")

	espSection:AddToggle("Show Egg ESP", false, function(state)
		Config.EggESP = state
		UpdateESP()
	end)

	espSection:AddButton("Refresh ESP", function()
		for part, _ in pairs(ESPObjects) do
			RemoveESP(part)
		end
		UpdateESP()
	end)

	local settingsSection = window:AddSection("Settings", "Settings")

	settingsSection:AddSlider("Server Hop Delay (s)", 10, 300, 30, function(value)
		Config.ServerHopDelay = value
	end)

	settingsSection:AddToggle("Auto Server Hop", false, function(state)
		Config.ServerHop = state
		if state then
			task.spawn(function()
				while Config.ServerHop do
					task.wait(Config.ServerHopDelay)
					if Config.ServerHop then
						ServerHop()
					end
				end
			end)
		end
	end)

	settingsSection:AddButton("Hop Now", function()
		ServerHop()
	end)

	settingsSection:AddButton("Rejoin Server", function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)

	settingsSection:AddButton("Join Discord", function()
		pcall(function()
			if setclipboard then
				setclipboard("https://discord.gg/MCWYKBdB4E")
			end
		end)
	end)

	settingsSection:AddButton("Destroy GUI", function()
		ScreenGui:Destroy()
	end)

	task.spawn(function()
		while ScreenGui and ScreenGui.Parent do
			UpdateESP()
			task.wait(1)
		end
	end)

	LocalPlayer.CharacterAdded:Connect(function(char)
		Character = char
		Humanoid = char:WaitForChild("Humanoid")
		HumanoidRootPart = char:WaitForChild("HumanoidRootPart")
		if Config.CustomSpeed then
			task.spawn(SpeedLoop)
		end
	end)
end

Main()
