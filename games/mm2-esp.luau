local IvoryHub = loadstring(game:HttpGet("https://ivoryy.web.app/IvoryHubLibrary.lua"))()

local targetPlaceId = 142823291
if game.PlaceId ~= targetPlaceId then
	game.StarterGui:SetCore("SendNotification", {
		Title = "Ivory | MM2",
		Text = "You are not in the correct game!\nPlease join Murder Mystery 2.",
		Duration = 5,
	})
	return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Window = IvoryHub.CreateWindow({ Name = "Ivory | MM2" })

-- ============================================================
-- STATE
-- ============================================================
local State = {
	ESP_Enabled = false,
	ESP_Box = false,
	ESP_Name = false,
	ESP_Distance = false,
	ESP_Role = false,
	ESP_Tracer = false,
	ESP_Gun = false,
	ESP_XRay = false,
	BoxThickness = 3,
	TextSize = 20,
	BoxWidthScale = 0.65,
	ESP_MaxDistance = 500,
	Aimbot_MaxDistance = 300,
	Color_Box = Color3.fromRGB(255, 105, 180),
	Color_Name = Color3.fromRGB(255, 220, 240),
	Color_Distance = Color3.fromRGB(180, 140, 170),
	Color_Tracer = Color3.fromRGB(255, 105, 180),

	Highlight_Enabled = false,
	Highlight_Mode = "Full Body",
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Depth = true,
	Highlight_Self = false,
	Color_Innocent = Color3.fromRGB(255, 105, 180),
	Color_Sheriff = Color3.fromRGB(255, 230, 50),
	Color_Murderer = Color3.fromRGB(255, 50, 50),

	Aimbot = false,
	Aimbot_FOV = 100,
	Aimbot_Smooth = 5,
	Aimbot_OnlyMurderer = false,
	Aimbot_WallCheck = false,
	Aimbot_Prediction = false,
	Aimbot_PredictionOffset = 0.5,
	Aimbot_FOV_Circle = false,
	AimbotKey = Enum.UserInputType.MouseButton2,

	CoinHighlight_Enabled = false,
	CoinHighlight_Color = Color3.fromRGB(255, 215, 0),
	CoinFarmTweenSpeed = 0.7,
}

-- ============================================================
-- ROLE DETECTION (uses game's own module, works before countdown)
-- ============================================================
local CurrentRoundClient
pcall(function()
	CurrentRoundClient = require(game.ReplicatedStorage.Modules.CurrentRoundClient)
end)

pcall(function()
	game.ReplicatedStorage.Remotes.Gameplay.PlayerDataChanged.OnClientEvent:Connect(function(data)
		if CurrentRoundClient then
			CurrentRoundClient.PlayerData = data
		end
	end)
end)

local function getRole(player)
	if not player.Character then return "Innocent" end

	local hasKnife = false
	local hasGun = false

	local backpack = player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				local name = tool.Name:lower()
				if name:find("knife") or name:find("murderer") then hasKnife = true end
				if name:find("gun") or name:find("revolver") or name:find("sheriff") then hasGun = true end
			end
		end
	end

	local charTool = player.Character:FindFirstChildOfClass("Tool")
	if charTool then
		local name = charTool.Name:lower()
		if name:find("knife") or name:find("murderer") then hasKnife = true end
		if name:find("gun") or name:find("revolver") or name:find("sheriff") then hasGun = true end
	end

	if hasKnife then return "Murderer" end
	if hasGun then return "Sheriff" end

	if CurrentRoundClient and CurrentRoundClient.PlayerData then
		local pd = CurrentRoundClient.PlayerData
		if pd[player.Name] and pd[player.Name].Role then
			return pd[player.Name].Role
		end
	end

	if player:FindFirstChild("Murderer") then return "Murderer" end
	if player:FindFirstChild("Sheriff") then return "Sheriff" end

	local roleVal = player:FindFirstChild("Role")
	if roleVal and roleVal:IsA("StringValue") then
		return roleVal.Value
	end

	local charRole = player.Character:FindFirstChild("Role")
	if charRole and charRole:IsA("StringValue") then
		return charRole.Value
	end

	local attrRole = player:GetAttribute("Role")
	if attrRole then return tostring(attrRole) end

	if player.Character:FindFirstChild("Murderer") then return "Murderer" end
	if player.Character:FindFirstChild("Sheriff") then return "Sheriff" end

	return "Innocent"
end

local function getRoleColor(role)
	role = role:lower()
	if role:find("murder") then return State.Color_Murderer end
	if role:find("sheriff") then return State.Color_Sheriff end
	return State.Color_Innocent
end

local function worldToScreen(position)
	local screenPos, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

-- ============================================================
-- FOV CIRCLE
-- ============================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Radius = State.Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 105, 180)
FOVCircle.Transparency = 0.8

-- ============================================================
-- ESP DRAWING OBJECTS
-- ============================================================
local espObjects = {}

local function createESP(player)
	if player == LocalPlayer then return end
	local esp = {
		Box = Drawing.new("Square"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Role = Drawing.new("Text"),
		Tracer = Drawing.new("Line"),
	}
	esp.Box.Thickness = State.BoxThickness
	esp.Box.Filled = false
	esp.Name.Size = State.TextSize
	esp.Name.Center = true
	esp.Name.Outline = true
	esp.Name.Font = Drawing.Fonts.UI
	esp.Distance.Size = State.TextSize - 2
	esp.Distance.Center = true
	esp.Distance.Outline = true
	esp.Distance.Font = Drawing.Fonts.UI
	esp.Role.Size = State.TextSize - 1
	esp.Role.Center = true
	esp.Role.Outline = true
	esp.Role.Font = Drawing.Fonts.UI
	esp.Tracer.Thickness = 1
	espObjects[player] = esp
end

local function removeESP(player)
	if espObjects[player] then
		for _, obj in pairs(espObjects[player]) do obj:Remove() end
		espObjects[player] = nil
	end
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- ============================================================
-- GUN ESP (dropped sheriff gun)
-- ============================================================
local gunESP = {
	Box = Drawing.new("Square"),
	Name = Drawing.new("Text"),
	Distance = Drawing.new("Text"),
}
gunESP.Box.Thickness = State.BoxThickness
gunESP.Box.Filled = false
gunESP.Name.Size = State.TextSize
gunESP.Name.Center = true
gunESP.Name.Outline = true
gunESP.Name.Font = Drawing.Fonts.UI
gunESP.Name.Text = "GUN"
gunESP.Distance.Size = State.TextSize - 2
gunESP.Distance.Center = true
gunESP.Distance.Outline = true
gunESP.Distance.Font = Drawing.Fonts.UI
gunESP.Distance.Text = ""

local CollectionService = game:GetService("CollectionService")
local lastSheriffDeathPos = nil
local prevPlayerData = {}
local gunPickedUp = false
local gunHighlight = nil

local function createGunHighlight(inst)
	if gunHighlight then pcall(function() gunHighlight:Destroy() end) end
	local hl = Instance.new("Highlight")
	hl.Name = "IvoryGunHL"
	hl.FillColor = Color3.fromRGB(255, 200, 0)
	hl.OutlineColor = Color3.fromRGB(255, 200, 0)
	hl.FillTransparency = 0.3
	hl.OutlineTransparency = 0
	hl.Adornee = inst
	hl.Parent = game:GetService("CoreGui")
	gunHighlight = hl
end

local function removeGunHighlight()
	if gunHighlight then
		pcall(function() gunHighlight:Destroy() end)
		gunHighlight = nil
	end
end

local function getSheriffInfo()
	local ok, cr = pcall(function() return require(game.ReplicatedStorage.Modules.CurrentRoundClient) end)
	if not ok or not cr or not cr.PlayerData then return nil, nil, nil end

	local sheriffName = nil
	local sheriffDead = false
	for name, data in pairs(cr.PlayerData) do
		if data.Role == "Sheriff" then
			sheriffName = name
			sheriffDead = data.Dead == true
			break
		end
	end

	local hasRound = false
	for name, data in pairs(cr.PlayerData) do
		if data.Role and data.Role ~= "" then hasRound = true break end
	end

	return sheriffName, sheriffDead, hasRound
end

local function isGunHeldByAnyone()
	for _, obj in ipairs(CollectionService:GetTagged("GunDrop")) do
		if obj:IsA("BasePart") and obj.Transparency > 0.5 then return true end
	end
	return false
end

local function getGunDropPart()
	for _, obj in ipairs(CollectionService:GetTagged("GunDrop")) do
		if obj:IsA("BasePart") and obj.Transparency < 0.5 then return obj end
	end
	return nil
end

local function updateGunESP()
	if not State.ESP_Enabled or not State.ESP_Gun then
		gunESP.Box.Visible = false
		gunESP.Name.Visible = false
		gunESP.Distance.Visible = false
		removeGunHighlight()
		return
	end

	local sheriffName, sheriffDead, hasRound = getSheriffInfo()

	if not hasRound or not sheriffName then
		lastSheriffDeathPos = nil
		gunPickedUp = false
		prevPlayerData = {}
		gunESP.Box.Visible = false
		gunESP.Name.Visible = false
		gunESP.Distance.Visible = false
		removeGunHighlight()
		return
	end

	local prev = prevPlayerData[sheriffName]
	if sheriffDead and (not prev or not prev.Dead) then
		gunPickedUp = false
		local player = Players:FindFirstChild(sheriffName)
		if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			lastSheriffDeathPos = player.Character.HumanoidRootPart.Position
		end
	end

	if not sheriffDead then
		gunPickedUp = false
		lastSheriffDeathPos = nil
	end

	prevPlayerData = {}
	local ok2, cr2 = pcall(function() return require(game.ReplicatedStorage.Modules.CurrentRoundClient) end)
	if ok2 and cr2 and cr2.PlayerData then
		for name, data in pairs(cr2.PlayerData) do
			prevPlayerData[name] = { Dead = data.Dead, Role = data.Role }
		end
	end

	local gunHeld = isGunHeldByAnyone()
	if gunHeld then
		gunPickedUp = true
		removeGunHighlight()
	end

	local pos = nil

	-- Priority 1: GunDrop part exists and is visible
	local gunDrop = getGunDropPart()
	if gunDrop then
		pos = gunDrop.Position
		if not gunHighlight or gunHighlight.Adornee ~= gunDrop then
			createGunHighlight(gunDrop)
		end
	else
		removeGunHighlight()
	end

	-- Priority 2: sheriff is dead, gun not picked up, use death position
	if not pos and sheriffDead and not gunPickedUp and lastSheriffDeathPos then
		pos = lastSheriffDeathPos
	end

	if not pos then
		gunESP.Box.Visible = false
		gunESP.Name.Visible = false
		gunESP.Distance.Visible = false
		removeGunHighlight()
		return
	end

	local screenPos, onScreen, dist = worldToScreen(pos)
	if not onScreen or dist <= 0 then
		gunESP.Box.Visible = false
		gunESP.Name.Visible = false
		gunESP.Distance.Visible = false
		return
	end

	local boxSize = Vector2.new(30, 30)
	local color = Color3.fromRGB(255, 200, 0)

	gunESP.Box.Size = boxSize
	gunESP.Box.Position = Vector2.new(screenPos.X - boxSize.X / 2, screenPos.Y - boxSize.Y / 2)
	gunESP.Box.Thickness = State.BoxThickness
	gunESP.Box.Color = color
	gunESP.Box.Visible = State.ESP_Box

	gunESP.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
	gunESP.Name.Size = State.TextSize
	gunESP.Name.Color = color
	gunESP.Name.Text = "GUN"
	gunESP.Name.Visible = true

	gunESP.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + 20)
	gunESP.Distance.Text = math.floor(dist) .. "m"
	gunESP.Distance.Size = State.TextSize - 2
	gunESP.Distance.Color = color
	gunESP.Distance.Visible = true
end

-- ============================================================
-- HIGHLIGHTS
-- ============================================================
local function applyHighlight(player)
	if player == LocalPlayer and not State.Highlight_Self then return end
	if not player.Character then return end

	local hl = player.Character:FindFirstChild("IvoryHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "IvoryHighlight"
		hl.Parent = player.Character
	end

	local role = getRole(player)
	local color = getRoleColor(role)

	hl.FillColor = color
	hl.OutlineColor = color

	if State.Highlight_Mode == "Full Body" then
		hl.FillTransparency = State.Highlight_FillTransparency
		hl.OutlineTransparency = State.Highlight_OutlineTransparency
	else
		hl.FillTransparency = 1
		hl.OutlineTransparency = State.Highlight_OutlineTransparency
	end

	hl.DepthMode = State.Highlight_Depth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	hl.Enabled = State.Highlight_Enabled
end

local function removeHighlight(player)
	if player.Character then
		local hl = player.Character:FindFirstChild("IvoryHighlight")
		if hl then hl:Destroy() end
	end
end

-- ============================================================
-- X-RAY
-- ============================================================
local xrayOriginals = {}
local xrayEnabled = false

local function enableXRay()
	if xrayEnabled then return end
	xrayEnabled = true
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj:IsA("Terrain") and not obj:FindFirstChild("IvoryHighlight") then
			if not xrayOriginals[obj] then
				xrayOriginals[obj] = obj.LocalTransparencyModifier
			end
			obj.LocalTransparencyModifier = 0.7
		end
	end
end

local function disableXRay()
	if not xrayEnabled then return end
	xrayEnabled = false
	for obj, mod in pairs(xrayOriginals) do
		if obj and obj.Parent then
			obj.LocalTransparencyModifier = mod
		end
	end
	xrayOriginals = {}
end

-- ============================================================
-- COIN HIGHLIGHTS (through walls)
-- ============================================================
local coinHighlights = {}

local function findCoins()
	local coins = {}
	local function scan(c)
		for _, obj in ipairs(c:GetChildren()) do
			if obj.Name:lower():find("coin") then
				table.insert(coins, obj)
			end
			if obj:IsA("Model") or obj:IsA("Folder") then
				scan(obj)
			end
		end
	end
	scan(Workspace)
	return coins
end

local function updateCoinHighlights()
	for _, coin in ipairs(findCoins()) do
		if not coinHighlights[coin] then
			local hl = Instance.new("Highlight")
			hl.Name = "IvoryCoinHighlight"
			hl.FillColor = State.CoinHighlight_Color
			hl.OutlineColor = State.CoinHighlight_Color
			hl.FillTransparency = 0.3
			hl.OutlineTransparency = 0
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = coin
			coinHighlights[coin] = hl
		end
		coinHighlights[coin].FillColor = State.CoinHighlight_Color
		coinHighlights[coin].OutlineColor = State.CoinHighlight_Color
		coinHighlights[coin].Enabled = State.CoinHighlight_Enabled
	end

	for coin, hl in pairs(coinHighlights) do
		if not coin or not coin.Parent then
			hl:Destroy()
			coinHighlights[coin] = nil
		end
	end
end

local function clearCoinHighlights()
	for coin, hl in pairs(coinHighlights) do
		if hl then hl:Destroy() end
	end
	coinHighlights = {}
end

-- ============================================================
-- AIMBOT
-- ============================================================
local aimbotKeyDown = false

local function isPartVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	return Workspace:Raycast(origin, direction, rayParams) == nil
end

local function getNearestTarget()
	local closestPlayer = nil
	local closestDist = State.Aimbot_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if not player.Character then continue end
		local hrp = player.Character:FindFirstChild("HumanoidRootPart")
		local hum = player.Character:FindFirstChild("Humanoid")
		if not hrp or not hum or hum.Health <= 0 then continue end

		local role = getRole(player)
		if State.Aimbot_OnlyMurderer and not role:lower():find("murder") then continue end
		if State.Aimbot_WallCheck and not isPartVisible(hrp) then continue end

		local screenDist = (hrp.Position - Camera.CFrame.Position).Magnitude
		if screenDist > State.Aimbot_MaxDistance then continue end

		local pos = Camera:WorldToViewportPoint(hrp.Position)
		local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
		if dist < closestDist then
			closestDist = dist
			closestPlayer = player
		end
	end

	return closestPlayer
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == State.AimbotKey or input.KeyCode == State.AimbotKey then
		aimbotKeyDown = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == State.AimbotKey or input.KeyCode == State.AimbotKey then
		aimbotKeyDown = false
	end
end)

-- ============================================================
-- HOME TAB
-- ============================================================
local HomeTab = Window:CreateTab("Home")

HomeTab:CreateSection("Ivory Hub")

HomeTab:CreateParagraph({
	Title = "Ivory | MM2",
	Content = "Murder Mystery 2 cheat hub with ESP, Highlights, Aimbot, and more.",
})

HomeTab:CreateButton({
	Name = "Join Discord",
	Callback = function()
		setclipboard("discord.gg/heya")
		IvoryHub.Notify({
			Title = "Discord",
			Content = "Invite link copied to clipboard!",
			Type = "Success",
			Duration = 3,
		})
	end,
})

-- ============================================================
-- ESP TAB
-- ============================================================
local ESPTab = Window:CreateTab("ESP")

ESPTab:CreateSection("ESP Controls")

ESPTab:CreateToggle({
	Name = "Enable ESP",
	Description = "Master ESP toggle",
	CurrentValue = false,
	TrackActive = true,
	Flag = "ESP_Enabled",
	Callback = function(v) State.ESP_Enabled = v end,
})

ESPTab:CreateToggle({
	Name = "Show Box",
	Description = "2D box around players",
	CurrentValue = false,
	Flag = "ESP_Box",
	Callback = function(v) State.ESP_Box = v end,
})

ESPTab:CreateToggle({
	Name = "Show Name",
	Description = "Player name above head",
	CurrentValue = false,
	Flag = "ESP_Name",
	Callback = function(v) State.ESP_Name = v end,
})

ESPTab:CreateToggle({
	Name = "Show Distance",
	Description = "Distance in meters",
	CurrentValue = false,
	Flag = "ESP_Distance",
	Callback = function(v) State.ESP_Distance = v end,
})

ESPTab:CreateToggle({
	Name = "Show Role",
	Description = "Player role text",
	CurrentValue = false,
	Flag = "ESP_Role",
	Callback = function(v) State.ESP_Role = v end,
})

ESPTab:CreateToggle({
	Name = "Show Tracer",
	Description = "Line from screen bottom to player",
	CurrentValue = false,
	Flag = "ESP_Tracer",
	Callback = function(v) State.ESP_Tracer = v end,
})

ESPTab:CreateToggle({
	Name = "Show Gun",
	Description = "Highlight dropped sheriff gun",
	CurrentValue = false,
	Flag = "ESP_Gun",
	Callback = function(v) State.ESP_Gun = v end,
})

ESPTab:CreateToggle({
	Name = "X-Ray",
	Description = "See through walls",
	CurrentValue = false,
	TrackActive = true,
	Flag = "ESP_XRay",
	Callback = function(v)
		State.ESP_XRay = v
		if not v then disableXRay() end
	end,
})

ESPTab:CreateDivider()
ESPTab:CreateSection("ESP Style")

ESPTab:CreateSlider({
	Name = "Max ESP Distance",
	Range = {50, 2000},
	Increment = 50,
	CurrentValue = 500,
	Suffix = "m",
	Flag = "ESP_MaxDist",
	Callback = function(v) State.ESP_MaxDistance = v end,
})

ESPTab:CreateSlider({
	Name = "Box Thickness",
	Range = {1, 5},
	Increment = 1,
	CurrentValue = 3,
	Flag = "BoxThickness",
	Callback = function(v) State.BoxThickness = v end,
})

ESPTab:CreateSlider({
	Name = "Text Size",
	Range = {10, 30},
	Increment = 1,
	CurrentValue = 20,
	Flag = "TextSize",
	Callback = function(v) State.TextSize = v end,
})

ESPTab:CreateSlider({
	Name = "Box Width",
	Range = {40, 100},
	Increment = 5,
	CurrentValue = 65,
	Suffix = "%",
	Flag = "BoxWidthScale",
	Callback = function(v) State.BoxWidthScale = v / 100 end,
})

ESPTab:CreateDivider()
ESPTab:CreateSection("ESP Colors")

ESPTab:CreateColorPicker({
	Name = "Box Color",
	Color = Color3.fromRGB(255, 105, 180),
	Flag = "Color_Box",
	Callback = function(v) State.Color_Box = v end,
})

ESPTab:CreateColorPicker({
	Name = "Name Color",
	Color = Color3.fromRGB(255, 220, 240),
	Flag = "Color_Name",
	Callback = function(v) State.Color_Name = v end,
})

ESPTab:CreateColorPicker({
	Name = "Distance Color",
	Color = Color3.fromRGB(180, 140, 170),
	Flag = "Color_Distance",
	Callback = function(v) State.Color_Distance = v end,
})

ESPTab:CreateColorPicker({
	Name = "Tracer Color",
	Color = Color3.fromRGB(255, 105, 180),
	Flag = "Color_Tracer",
	Callback = function(v) State.Color_Tracer = v end,
})

-- ============================================================
-- VISUALS TAB (HIGHLIGHTS)
-- ============================================================
local VisualsTab = Window:CreateTab("Visuals")

VisualsTab:CreateSection("Highlights")

VisualsTab:CreateToggle({
	Name = "Enable Highlights",
	Description = "Color players by role",
	CurrentValue = false,
	TrackActive = true,
	Flag = "Highlight_Enabled",
	Callback = function(v)
		State.Highlight_Enabled = v
		if not v then
			for _, player in ipairs(Players:GetPlayers()) do
				removeHighlight(player)
			end
		end
	end,
})

VisualsTab:CreateDropdown({
	Name = "Highlight Mode",
	Options = {"Full Body", "Outline Only"},
	CurrentOption = "Full Body",
	Flag = "Highlight_Mode",
	Callback = function(v) State.Highlight_Mode = v end,
})

VisualsTab:CreateToggle({
	Name = "Occluded (Through Walls)",
	Description = "Highlights visible through walls",
	CurrentValue = true,
	Flag = "Highlight_Depth",
	Callback = function(v) State.Highlight_Depth = v end,
})

VisualsTab:CreateToggle({
	Name = "Highlight Self",
	Description = "Show highlight on yourself",
	CurrentValue = false,
	Flag = "Highlight_Self",
	Callback = function(v) State.Highlight_Self = v end,
})

VisualsTab:CreateDivider()
VisualsTab:CreateSection("Highlight Colors")

VisualsTab:CreateColorPicker({
	Name = "Innocent Color",
	Color = Color3.fromRGB(255, 105, 180),
	Flag = "Color_Innocent",
	Callback = function(v) State.Color_Innocent = v end,
})

VisualsTab:CreateColorPicker({
	Name = "Sheriff Color",
	Color = Color3.fromRGB(255, 230, 50),
	Flag = "Color_Sheriff",
	Callback = function(v) State.Color_Sheriff = v end,
})

VisualsTab:CreateColorPicker({
	Name = "Murderer Color",
	Color = Color3.fromRGB(255, 50, 50),
	Flag = "Color_Murderer",
	Callback = function(v) State.Color_Murderer = v end,
})

VisualsTab:CreateSlider({
	Name = "Fill Transparency",
	Range = {0, 100},
	Increment = 5,
	CurrentValue = 50,
	Suffix = "%",
	Flag = "Highlight_FillTransparency",
	Callback = function(v) State.Highlight_FillTransparency = v / 100 end,
})

VisualsTab:CreateSlider({
	Name = "Outline Transparency",
	Range = {0, 100},
	Increment = 5,
	CurrentValue = 0,
	Suffix = "%",
	Flag = "Highlight_OutlineTransparency",
	Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end,
})

-- ============================================================
-- AIM TAB
-- ============================================================
local AimTab = Window:CreateTab("Aim")

AimTab:CreateSection("Aimbot")

AimTab:CreateToggle({
	Name = "Enable Aimbot",
	Description = "Lock camera to nearest target",
	CurrentValue = false,
	TrackActive = true,
	Flag = "Aimbot",
	Callback = function(v) State.Aimbot = v end,
})

AimTab:CreateToggle({
	Name = "Show FOV Circle",
	Description = "Display aimbot field of view",
	CurrentValue = false,
	Flag = "Aimbot_FOV_Circle",
	Callback = function(v) State.Aimbot_FOV_Circle = v end,
})

AimTab:CreateSlider({
	Name = "FOV",
	Range = {20, 500},
	Increment = 10,
	CurrentValue = 100,
	Suffix = "px",
	Flag = "Aimbot_FOV",
	Callback = function(v) State.Aimbot_FOV = v end,
})

AimTab:CreateSlider({
	Name = "Smoothing",
	Range = {1, 20},
	Increment = 1,
	CurrentValue = 5,
	Flag = "Aimbot_Smooth",
	Callback = function(v) State.Aimbot_Smooth = v end,
})

AimTab:CreateSlider({
	Name = "Max Aim Distance",
	Range = {50, 2000},
	Increment = 50,
	CurrentValue = 300,
	Suffix = "m",
	Flag = "Aimbot_MaxDist",
	Callback = function(v) State.Aimbot_MaxDistance = v end,
})

AimTab:CreateToggle({
	Name = "Only Target Murderer",
	Description = "Ignore non-murderers",
	CurrentValue = false,
	Flag = "Aimbot_OnlyMurderer",
	Callback = function(v) State.Aimbot_OnlyMurderer = v end,
})

AimTab:CreateToggle({
	Name = "Wall Check",
	Description = "Don't aim through walls",
	CurrentValue = false,
	Flag = "Aimbot_WallCheck",
	Callback = function(v) State.Aimbot_WallCheck = v end,
})

AimTab:CreateToggle({
	Name = "Predict Movement",
	Description = "Lead the target",
	CurrentValue = false,
	Flag = "Aimbot_Prediction",
	Callback = function(v) State.Aimbot_Prediction = v end,
})

AimTab:CreateSlider({
	Name = "Prediction Lead",
	Range = {0, 50},
	Increment = 5,
	CurrentValue = 5,
	Flag = "Aimbot_PredictionOffset",
	Callback = function(v) State.Aimbot_PredictionOffset = v / 10 end,
})

AimTab:CreateKeybind({
	Name = "Aim Key",
	CurrentKeybind = "MouseButton2",
	Flag = "AimbotKey",
	Callback = function() end,
	ChangedCallback = function(key)
		local keyMap = {
			MouseButton2 = Enum.UserInputType.MouseButton2,
			MouseButton3 = Enum.UserInputType.MouseButton3,
			LeftShift = Enum.KeyCode.LeftShift,
			LeftControl = Enum.KeyCode.LeftControl,
			Q = Enum.KeyCode.Q,
			E = Enum.KeyCode.E,
		}
		State.AimbotKey = keyMap[key] or Enum.UserInputType.MouseButton2
	end,
})

-- ============================================================
-- FARM TAB
-- ============================================================
local FarmTab = Window:CreateTab("Farm")

FarmTab:CreateSection("Coin ESP")

FarmTab:CreateToggle({
	Name = "Coin Highlights",
	Description = "Highlight coins through walls",
	CurrentValue = false,
	TrackActive = true,
	Flag = "CoinHighlight_Enabled",
	Callback = function(v)
		State.CoinHighlight_Enabled = v
		if not v then clearCoinHighlights() end
	end,
})

FarmTab:CreateColorPicker({
	Name = "Coin Color",
	Color = Color3.fromRGB(255, 215, 0),
	Flag = "CoinHighlight_Color",
	Callback = function(v) State.CoinHighlight_Color = v end,
})

FarmTab:CreateDivider()
FarmTab:CreateSection("Coin Auto Farm")

FarmTab:CreateToggle({
	Name = "Enable Coin Farm",
	Description = "Tween to coins on the map",
	CurrentValue = false,
	TrackActive = true,
	Flag = "CoinFarmEnabled",
	Callback = function(v)
		State.CoinFarmEnabled = v
		if v then
			task.spawn(function()
				while State.CoinFarmEnabled do
					local char = LocalPlayer.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if not hrp then task.wait(0.5) continue end

					local inRound = false
					if CurrentRoundClient and CurrentRoundClient.PlayerData then
						local pd = CurrentRoundClient.PlayerData
						if pd[LocalPlayer.Name] and pd[LocalPlayer.Name].Role then
							inRound = true
						end
					end
					if not inRound then
						for _, v in ipairs(LocalPlayer.Character:GetChildren()) do
							if v:IsA("Tool") then inRound = true break end
						end
					end
					if not inRound then
						if LocalPlayer:FindFirstChild("Murderer") or LocalPlayer:FindFirstChild("Sheriff") then
							inRound = true
						end
					end
					if not inRound then task.wait(1) continue end

					local coins = findCoins()
					local coinData = {}
					for _, coin in ipairs(coins) do
						if coin and coin.Parent then
							local pos = nil
							if coin:IsA("BasePart") then
								pos = coin.Position
							elseif coin:IsA("Model") then
								local p = coin.PrimaryPart
								if p then
									pos = p.Position
								else
									for _, pt in ipairs(coin:GetDescendants()) do
										if pt:IsA("BasePart") then
											pos = pt.Position
											break
										end
									end
								end
							end
							if pos then
								local dist = (hrp.Position - pos).Magnitude
								table.insert(coinData, { coin = coin, pos = pos, dist = dist })
							end
						end
					end

					table.sort(coinData, function(a, b) return a.dist < b.dist end)

					for _, data in ipairs(coinData) do
						if not State.CoinFarmEnabled then break end
						if data.coin and data.coin.Parent then
							local cf = CFrame.new(data.pos + Vector3.new(0, -2, 0))
							local speed = State.CoinFarmTweenSpeed
							local dur = data.dist / (15 * speed)
							local tween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {CFrame = cf})
							tween:Play()
							tween.Completed:Wait()
							task.wait(0.5)
						end
					end

					task.wait(0.2)
				end
			end)
		end
	end,
})

FarmTab:CreateLabel("Speeds under 1x recommended to bypass kicks")

FarmTab:CreateSlider({
	Name = "Farm Speed",
	Range = {0.5, 1.5},
	Increment = 0.1,
	CurrentValue = 0.7,
	Suffix = "x",
	Flag = "CoinFarmTweenSpeed",
	Callback = function(v) State.CoinFarmTweenSpeed = v end,
})

-- ============================================================
-- SETTINGS TAB
-- ============================================================
local SettingsTab = Window:CreateTab("Settings")

SettingsTab:CreateSection("Config")

SettingsTab:CreateButton({
	Name = "Save Configuration",
	Callback = function()
		IvoryHub.SaveConfiguration("IvoryMM2")
		IvoryHub.Notify({ Title = "Config", Content = "Settings saved.", Type = "Success", Duration = 3 })
	end,
})

SettingsTab:CreateButton({
	Name = "Load Configuration",
	Callback = function()
		IvoryHub.LoadConfiguration("IvoryMM2")
		IvoryHub.Notify({ Title = "Config", Content = "Settings loaded.", Type = "Info", Duration = 3 })
	end,
})

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
	Camera = Workspace.CurrentCamera

	if State.ESP_XRay then
		enableXRay()
	else
		disableXRay()
	end

	if State.CoinHighlight_Enabled then
		updateCoinHighlights()
	end

	updateGunESP()

	if State.Highlight_Enabled and State.Highlight_Self then
		applyHighlight(LocalPlayer)
	elseif not State.Highlight_Self then
		removeHighlight(LocalPlayer)
	end

	if State.Aimbot_FOV_Circle and State.Aimbot then
		FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		FOVCircle.Radius = State.Aimbot_FOV
		FOVCircle.Visible = true
	else
		FOVCircle.Visible = false
	end

	if State.Aimbot and aimbotKeyDown then
		local target = getNearestTarget()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = target.Character.HumanoidRootPart
			local targetPos = hrp.Position
			if State.Aimbot_Prediction then
				targetPos = targetPos + hrp.CFrame.LookVector * State.Aimbot_PredictionOffset
			end
			Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 1 / State.Aimbot_Smooth)
		end
	end

	for player, esp in pairs(espObjects) do
		local show = State.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0

		if State.Highlight_Enabled then applyHighlight(player) else removeHighlight(player) end

		if show then
			local hrp = player.Character.HumanoidRootPart
			local _, onScreen, dist = worldToScreen(hrp.Position)
			if onScreen and dist > 0 and dist <= State.ESP_MaxDistance then
				local rootPos = Camera:WorldToViewportPoint(hrp.Position)
				local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
				local boxHeight = math.abs(rootPos.Y - headPos.Y) * 2.2
				local boxWidth = boxHeight * State.BoxWidthScale
				local role = getRole(player)
				local color = getRoleColor(role)

				esp.Box.Size = Vector2.new(boxWidth, boxHeight)
				esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
				esp.Box.Thickness = State.BoxThickness
				esp.Box.Color = color
				esp.Box.Visible = State.ESP_Box

				esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 20)
				esp.Name.Text = player.DisplayName
				esp.Name.Size = State.TextSize
				esp.Name.Color = State.Color_Name
				esp.Name.Visible = State.ESP_Name

				esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 6)
				esp.Distance.Text = math.floor(dist) .. "m"
				esp.Distance.Size = State.TextSize - 2
				esp.Distance.Color = State.Color_Distance
				esp.Distance.Visible = State.ESP_Distance

				esp.Role.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 38)
				esp.Role.Text = role
				esp.Role.Color = color
				esp.Role.Size = State.TextSize - 1
				esp.Role.Visible = State.ESP_Role

				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
				esp.Tracer.Color = State.Color_Tracer
				esp.Tracer.Visible = State.ESP_Tracer
			else
				esp.Box.Visible = false
				esp.Name.Visible = false
				esp.Distance.Visible = false
				esp.Role.Visible = false
				esp.Tracer.Visible = false
			end
		else
			esp.Box.Visible = false
			esp.Name.Visible = false
			esp.Distance.Visible = false
			esp.Role.Visible = false
			esp.Tracer.Visible = false
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
	removeHighlight(player)
end)

IvoryHub.Notify({
	Title = "Ivory | MM2 Loaded",
	Content = "ESP, Highlights, Aimbot, Coin Farm, and Gun ESP ready.",
	Type = "Success",
	Duration = 4,
})
