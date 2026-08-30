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
	StealDelay = 0.5,
	SelectedRarities = {},
	SelectedMutations = {},
	TargetRarities = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Golden", "Shiny", "Rainbow", "Cosmic"},
}

local ScreenGui = nil
local MainFrame = nil
local CurrentTab = "Steal"
local Tabs = {}

local RARITIES = {
	{Name = "Common", Color = Color3.fromRGB(180, 180, 180), Priority = 1},
	{Name = "Uncommon", Color = Color3.fromRGB(80, 200, 80), Priority = 2},
	{Name = "Rare", Color = Color3.fromRGB(80, 120, 255), Priority = 3},
	{Name = "Epic", Color = Color3.fromRGB(180, 80, 255), Priority = 4},
	{Name = "Legendary", Color = Color3.fromRGB(255, 180, 50), Priority = 5},
	{Name = "Mythic", Color = Color3.fromRGB(255, 50, 50), Priority = 6},
	{Name = "Golden", Color = Color3.fromRGB(255, 215, 0), Priority = 7},
	{Name = "Shiny", Color = Color3.fromRGB(200, 200, 255), Priority = 8},
	{Name = "Rainbow", Color = Color3.fromRGB(255, 100, 100), Priority = 9},
	{Name = "Cosmic", Color = Color3.fromRGB(150, 50, 255), Priority = 10},
}

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

local function TeleportTo(position, duration)
	local hrp = GetHRP()
	if not hrp then return end

	if Config.InstantSteal then
		hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
		return
	end

	local distance = (position - hrp.Position).Magnitude
	local time = duration or (distance / 50)

	local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
	})
	tween:Play()
	tween.Completed:Wait()
end

local function GetStealPrompts()
	local prompts = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.ActionText == "Steal" and obj.ObjectText == "Egg" then
			table.insert(prompts, obj)
		end
	end
	return prompts
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

local function GetEggRarityFromSmartPart(smartPart)
	if not smartPart then return "Unknown" end

	local pos = smartPart.Position
	local cra = Workspace:FindFirstChild("ClientRenderedAssets")
	if not cra then return "Unknown" end

	local nearestModel = nil
	local nearestDist = math.huge

	for _, model in ipairs(cra:GetChildren()) do
		if model:IsA("Model") then
			local pivot = model:GetPivot()
			local dist = (pivot.Position - pos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestModel = model
			end
		end
	end

	if nearestModel and nearestDist < 20 then
		local bbg = nearestModel:FindFirstChild("Data")
		if bbg and bbg:IsA("BillboardGui") then
			local oddsLabel = bbg:FindFirstChild("Odds")
			if oddsLabel and oddsLabel:IsA("TextLabel") then
				local rarity = oddsLabel.Text
				if rarity and rarity ~= "" then
					return rarity
				end
			end

			local rarityLabel = bbg:FindFirstChild("Rarity")
			if rarityLabel and rarityLabel:IsA("TextLabel") then
				local rarity = rarityLabel.Text
				if rarity and rarity ~= "" then
					return rarity
				end
			end

			local displayName = bbg:FindFirstChild("DisplayName")
			if displayName and displayName:IsA("TextLabel") then
				local name = displayName.Text
				for _, rarity in ipairs(RARITIES) do
					if name:lower():find(rarity.Name:lower()) then
						return rarity.Name
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
			local prompt = GetNearestStealPrompt()
			if prompt and IsEggTargeted(prompt) then
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
				local rarityColor = Color3.new(1, 1, 1)

				for _, r in ipairs(RARITIES) do
					if r.Name == rarity then
						rarityColor = r.Color
						break
					end
				end

				CreateESP(part, rarityColor, rarity)
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
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

	MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 400, 0, 500)
	MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
	MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	MainFrame.BorderSizePixel = 0
	MainFrame.Active = true
	MainFrame.Draggable = true
	MainFrame.Parent = ScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = MainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 255)
	stroke.Thickness = 2
	stroke.Parent = MainFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	titleLabel.Text = title or "Ivory"
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.TextSize = 18
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = MainFrame

	local titleCorner = Instance.new("UICorner")
	titleCorner.CornerRadius = UDim.new(0, 8)
	titleCorner.Parent = titleLabel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 30, 0, 30)
	closeBtn.Position = UDim2.new(1, -35, 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.new(1, 1, 1)
	closeBtn.TextSize = 14
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Parent = titleLabel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 4)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		ScreenGui:Destroy()
	end)

	local tabContainer = Instance.new("Frame")
	tabContainer.Size = UDim2.new(1, -10, 0, 35)
	tabContainer.Position = UDim2.new(0, 5, 0, 45)
	tabContainer.BackgroundTransparency = 1
	tabContainer.Parent = MainFrame

	local tabList = Instance.new("UIListLayout")
	tabList.FillDirection = Enum.FillDirection.Horizontal
	tabList.Padding = UDim.new(0, 5)
	tabList.Parent = tabContainer

	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, -10, 1, -90)
	contentFrame.Position = UDim2.new(0, 5, 0, 85)
	contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	contentFrame.BorderSizePixel = 0
	contentFrame.Parent = MainFrame

	local contentCorner = Instance.new("UICorner")
	contentCorner.CornerRadius = UDim.new(0, 4)
	contentCorner.Parent = contentFrame

	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Size = UDim2.new(1, -5, 1, -5)
	scrollingFrame.Position = UDim2.new(0, 2.5, 0, 2.5)
	scrollingFrame.BackgroundTransparency = 1
	scrollingFrame.ScrollBarThickness = 4
	scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 255)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollingFrame.Parent = contentFrame

	local contentList = Instance.new("UIListLayout")
	contentList.Padding = UDim.new(0, 5)
	contentList.Parent = scrollingFrame

	local footer = Instance.new("TextLabel")
	footer.Size = UDim2.new(1, 0, 0, 20)
	footer.Position = UDim2.new(0, 0, 1, -22)
	footer.BackgroundTransparency = 1
	footer.Text = "v1.4 | Lobby/Game | " .. LocalPlayer.UserId
	footer.TextColor3 = Color3.fromRGB(150, 150, 150)
	footer.TextSize = 10
	footer.Font = Enum.Font.Gotham
	footer.Parent = MainFrame

	footer.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			pcall(function()
				if setclipboard then
					setclipboard(footer.Text)
				end
			end)
		end
	end)

	Tabs = {}
	local tabNames = {"Steal", "Automation", "ESP", "Settings"}

	for _, tabName in ipairs(tabNames) do
		local tabBtn = Instance.new("TextButton")
		tabBtn.Size = UDim2.new(0, 80, 0, 30)
		tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		tabBtn.Text = tabName
		tabBtn.TextColor3 = Color3.new(1, 1, 1)
		tabBtn.TextSize = 12
		tabBtn.Font = Enum.Font.Gotham
		tabBtn.Parent = tabContainer

		local tabCorner = Instance.new("UICorner")
		tabCorner.CornerRadius = UDim.new(0, 4)
		tabCorner.Parent = tabBtn

		Tabs[tabName] = {
			Button = tabBtn,
			Content = scrollingFrame,
			Sections = {}
		}

		tabBtn.MouseButton1Click:Connect(function()
			CurrentTab = tabName
			for name, tab in pairs(Tabs) do
				if name == tabName then
					tabBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
				else
					tabBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
				end
			end
			for name, tab in pairs(Tabs) do
				for _, section in ipairs(tab.Sections) do
					section.Frame.Visible = (name == tabName)
				end
			end
		end)
	end

	Tabs["Steal"].Button.BackgroundColor3 = Color3.fromRGB(100, 100, 255)

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
			section.Size = UDim2.new(1, -10, 0, 0)
			section.AutomaticSize = Enum.AutomaticSize.Y
			section.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			section.BorderSizePixel = 0
			section.Visible = (tabName == CurrentTab)
			section.Parent = tab.Content

			local sectionCorner = Instance.new("UICorner")
			sectionCorner.CornerRadius = UDim.new(0, 4)
			sectionCorner.Parent = section

			local sectionPadding = Instance.new("UIPadding")
			sectionPadding.PaddingTop = UDim.new(0, 5)
			sectionPadding.PaddingBottom = UDim.new(0, 5)
			sectionPadding.PaddingLeft = UDim.new(0, 5)
			sectionPadding.PaddingRight = UDim.new(0, 5)
			sectionPadding.Parent = section

			local sectionList = Instance.new("UIListLayout")
			sectionList.Padding = UDim.new(0, 3)
			sectionList.Parent = section

			local sectionLabel = Instance.new("TextLabel")
			sectionLabel.Size = UDim2.new(1, 0, 0, 20)
			sectionLabel.BackgroundTransparency = 1
			sectionLabel.Text = sectionName
			sectionLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
			sectionLabel.TextSize = 12
			sectionLabel.Font = Enum.Font.GothamBold
			sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
			sectionLabel.Parent = section

			table.insert(tab.Sections, {Frame = section, Name = sectionName})

			return {
				Frame = section,
				AddToggle = function(self, text, default, callback)
					local toggle = Instance.new("Frame")
					toggle.Size = UDim2.new(1, 0, 0, 25)
					toggle.BackgroundTransparency = 1
					toggle.Parent = section

					local label = Instance.new("TextLabel")
					label.Size = UDim2.new(0.7, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = text
					label.TextColor3 = Color3.new(1, 1, 1)
					label.TextSize = 11
					label.Font = Enum.Font.Gotham
					label.TextXAlignment = Enum.TextXAlignment.Left
					label.Parent = toggle

					local toggleBtn = Instance.new("TextButton")
					toggleBtn.Size = UDim2.new(0, 40, 0, 20)
					toggleBtn.Position = UDim2.new(0.75, 0, 0.5, -10)
					toggleBtn.BackgroundColor3 = default and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 100)
					toggleBtn.Text = default and "ON" or "OFF"
					toggleBtn.TextColor3 = Color3.new(1, 1, 1)
					toggleBtn.TextSize = 10
					toggleBtn.Font = Enum.Font.GothamBold
					toggleBtn.Parent = toggle

					local toggleCorner = Instance.new("UICorner")
					toggleCorner.CornerRadius = UDim.new(0, 4)
					toggleCorner.Parent = toggleBtn

					local state = default or false

					toggleBtn.MouseButton1Click:Connect(function()
						state = not state
						toggleBtn.BackgroundColor3 = state and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 100)
						toggleBtn.Text = state and "ON" or "OFF"
						if callback then callback(state) end
					end)

					return {
						Set = function(self, value)
							state = value
							toggleBtn.BackgroundColor3 = state and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(100, 100, 100)
							toggleBtn.Text = state and "ON" or "OFF"
							if callback then callback(state) end
						end,
						Get = function(self) return state end
					}
				end,
				AddSlider = function(self, text, min, max, default, callback)
					local slider = Instance.new("Frame")
					slider.Size = UDim2.new(1, 0, 0, 35)
					slider.BackgroundTransparency = 1
					slider.Parent = section

					local sLabel = Instance.new("TextLabel")
					sLabel.Size = UDim2.new(0.5, 0, 0, 15)
					sLabel.BackgroundTransparency = 1
					sLabel.Text = text
					sLabel.TextColor3 = Color3.new(1, 1, 1)
					sLabel.TextSize = 11
					sLabel.Font = Enum.Font.Gotham
					sLabel.TextXAlignment = Enum.TextXAlignment.Left
					sLabel.Parent = slider

					local valueLabel = Instance.new("TextLabel")
					valueLabel.Size = UDim2.new(0.4, 0, 0, 15)
					valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
					valueLabel.BackgroundTransparency = 1
					valueLabel.Text = tostring(default)
					valueLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
					valueLabel.TextSize = 11
					valueLabel.Font = Enum.Font.GothamBold
					valueLabel.TextXAlignment = Enum.TextXAlignment.Right
					valueLabel.Parent = slider

					local sliderBg = Instance.new("Frame")
					sliderBg.Size = UDim2.new(0.95, 0, 0, 6)
					sliderBg.Position = UDim2.new(0.025, 0, 0, 22)
					sliderBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
					sliderBg.Parent = slider

					local sliderCorner = Instance.new("UICorner")
					sliderCorner.CornerRadius = UDim.new(0, 3)
					sliderCorner.Parent = sliderBg

					local fill = Instance.new("Frame")
					fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
					fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
					fill.Parent = sliderBg

					local fillCorner = Instance.new("UICorner")
					fillCorner.CornerRadius = UDim.new(0, 3)
					fillCorner.Parent = fill

					local knob = Instance.new("TextButton")
					knob.Size = UDim2.new(0, 12, 0, 12)
					knob.Position = UDim2.new((default - min) / (max - min), -6, 0.5, -6)
					knob.BackgroundColor3 = Color3.new(1, 1, 1)
					knob.Text = ""
					knob.Parent = sliderBg

					local knobCorner = Instance.new("UICorner")
					knobCorner.CornerRadius = UDim.new(0.5, 0)
					knobCorner.Parent = knob

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
							knob.Position = UDim2.new(percent, -6, 0.5, -6)
							valueLabel.Text = tostring(currentValue)

							if callback then callback(currentValue) end
						end
					end)

					return {
						Set = function(self, value)
							currentValue = math.clamp(value, min, max)
							local percent = (currentValue - min) / (max - min)
							fill.Size = UDim2.new(percent, 0, 1, 0)
							knob.Position = UDim2.new(percent, -6, 0.5, -6)
							valueLabel.Text = tostring(currentValue)
							if callback then callback(currentValue) end
						end,
						Get = function(self) return currentValue end
					}
				end,
				AddButton = function(self, text, callback)
					local btn = Instance.new("TextButton")
					btn.Size = UDim2.new(1, 0, 0, 25)
					btn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
					btn.Text = text
					btn.TextColor3 = Color3.new(1, 1, 1)
					btn.TextSize = 11
					btn.Font = Enum.Font.Gotham
					btn.Parent = section

					local btnCorner = Instance.new("UICorner")
					btnCorner.CornerRadius = UDim.new(0, 4)
					btnCorner.Parent = btn

					btn.MouseButton1Click:Connect(function()
						if callback then callback() end
					end)

					return {Button = btn}
				end,
				AddDropdown = function(self, text, options, default, multiSelect, callback)
					local dropdown = Instance.new("Frame")
					dropdown.Size = UDim2.new(1, 0, 0, 25)
					dropdown.BackgroundTransparency = 1
					dropdown.Parent = section

					local dLabel = Instance.new("TextLabel")
					dLabel.Size = UDim2.new(0.5, 0, 1, 0)
					dLabel.BackgroundTransparency = 1
					dLabel.Text = text
					dLabel.TextColor3 = Color3.new(1, 1, 1)
					dLabel.TextSize = 11
					dLabel.Font = Enum.Font.Gotham
					dLabel.TextXAlignment = Enum.TextXAlignment.Left
					dLabel.Parent = dropdown

					local dropBtn = Instance.new("TextButton")
					dropBtn.Size = UDim2.new(0.45, 0, 0, 20)
					dropBtn.Position = UDim2.new(0.55, 0, 0.5, -10)
					dropBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
					dropBtn.Text = "Select..."
					dropBtn.TextColor3 = Color3.new(1, 1, 1)
					dropBtn.TextSize = 10
					dropBtn.Font = Enum.Font.Gotham
					dropBtn.Parent = dropdown

					local dropCorner = Instance.new("UICorner")
					dropCorner.CornerRadius = UDim.new(0, 4)
					dropCorner.Parent = dropBtn

					local selected = default or {}
					local isOpen = false

					local optionsFrame = Instance.new("Frame")
					optionsFrame.Size = UDim2.new(0.45, 0, 0, #options * 22)
					optionsFrame.Position = UDim2.new(0.55, 0, 0, 25)
					optionsFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
					optionsFrame.BorderSizePixel = 0
					optionsFrame.Visible = false
					optionsFrame.ZIndex = 10
					optionsFrame.Parent = dropdown

					local optionsCorner = Instance.new("UICorner")
					optionsCorner.CornerRadius = UDim.new(0, 4)
					optionsCorner.Parent = optionsFrame

					local optionsList = Instance.new("UIListLayout")
					optionsList.Padding = UDim.new(0, 2)
					optionsList.Parent = optionsFrame

					for _, option in ipairs(options) do
						local optBtn = Instance.new("TextButton")
						optBtn.Size = UDim2.new(1, -4, 0, 20)
						optBtn.Position = UDim2.new(0, 2, 0, 0)
						optBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 90)
						optBtn.Text = option
						optBtn.TextColor3 = Color3.new(1, 1, 1)
						optBtn.TextSize = 10
						optBtn.Font = Enum.Font.Gotham
						optBtn.TextXAlignment = Enum.TextXAlignment.Left
						optBtn.ZIndex = 11
						optBtn.Parent = optionsFrame

						local optCorner = Instance.new("UICorner")
						optCorner.CornerRadius = UDim.new(0, 3)
						optCorner.Parent = optBtn

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
								dropBtn.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
							else
								selected = {option}
								dropBtn.Text = option
								optionsFrame.Visible = false
							end
							if callback then callback(selected) end
						end)
					end

					dropBtn.MouseButton1Click:Connect(function()
						isOpen = not isOpen
						optionsFrame.Visible = isOpen
					end)

					return {
						Set = function(self, value)
							if type(value) == "table" then
								selected = value
								dropBtn.Text = #selected > 0 and table.concat(selected, ", ") or "Select..."
							else
								selected = {value}
								dropBtn.Text = value
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
	local window = CreateWindow("Ivory")

	local stealSection = window:AddSection("Steal", "Egg Stealing")

	stealSection:AddToggle("Auto Steal Eggs", false, function(state)
		Config.AutoSteal = state
		if state then
			task.spawn(AutoStealLoop)
		end
	end)

	stealSection:AddSlider("Steal Delay (s)", 1, 50, 5, function(value)
		Config.StealDelay = value / 10
	end)

	stealSection:AddToggle("Instant Steal", false, function(state)
		Config.InstantSteal = state
	end)

	stealSection:AddToggle("Auto Return to Base", true, function(state)
		Config.AutoReturnToBase = state
	end)

	stealSection:AddDropdown("Rarity Filter", Config.TargetRarities, {}, true, function(selected)
		Config.SelectedRarities = selected
	end)

	stealSection:AddButton("Steal Nearest Egg", function()
		if IsAlive() then
			local prompt = GetNearestStealPrompt()
			if prompt and IsEggTargeted(prompt) then
				StealEgg(prompt)
			end
		end
	end)

	stealSection:AddButton("Steal All Eggs", function()
		task.spawn(function()
			local prompts = GetStealPrompts()
			for _, prompt in ipairs(prompts) do
				if IsEggTargeted(prompt) and IsAlive() then
					StealEgg(prompt)
					task.wait(Config.StealDelay)
				end
			end
		end)
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
	end)
end

Main()
