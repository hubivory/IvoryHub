--// Ivory Hub | Universal Loader
--// Works in ALL games via Ivory Hub Sakura Edition

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Load Ivory Hub Library
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
local httpGet do
	local fn = request or http_request or (syn and syn.request)
	if fn then
		httpGet = function(url)
			local res = fn({ Url = url, Method = "GET" })
			return res and res.Body
		end
	else
		httpGet = function(url)
			return game:HttpGet(url, true)
		end
	end
end

local LIB_SRC = httpGet(LIB_URL)
if not LIB_SRC or #LIB_SRC == 0 then
	error("[Ivory] Library source could not be loaded. Check your executor's HTTP support.")
end

local fn, loadErr = loadstring(LIB_SRC)
if not fn then
	error("[Ivory] Library compile error: " .. tostring(loadErr))
end
local Library = fn()
if not Library then
	error("[Ivory] Library did not return a valid module.")
end

--// Game info
local PlaceId = game.PlaceId
local GameName = tostring(PlaceId)
pcall(function()
	GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

local isLobby = false
pcall(function()
	isLobby = Workspace:FindFirstChild("Lobby") ~= nil
		or Workspace:FindFirstChild("lobby") ~= nil
		or LocalPlayer.Character == nil
end)

--// Window
local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 460,
	Height = 360,
	Resizable = true,
	AccentColor = Color3.fromRGB(140, 110, 220),
	CornerRadius = UDim.new(0, 6),
	ToggleKeybind = Enum.KeyCode.RightShift,
	ConfigSaving = true,
	ConfigName = "IvoryHub_Universal",
	AutoSaveInterval = 60,
	WatermarkEnabled = true,
})

--// State
local State = {
	ESP_Enabled = false,
	ESP_Box = true,
	ESP_Name = true,
	ESP_Distance = true,
	ESP_Health = true,
	ESP_Tracer = false,
	ESP_TeamCheck = false,
	ESP_MaxDist = 1000,
	BoxThickness = 2,
	TextSize = 14,
	Color_Box = Color3.fromRGB(140, 110, 220),
	Color_Name = Color3.fromRGB(225, 215, 245),
	Color_Distance = Color3.fromRGB(155, 135, 185),
	Color_Tracer = Color3.fromRGB(140, 110, 220),
	Color_Friend = Color3.fromRGB(100, 255, 100),
	Color_Enemy = Color3.fromRGB(220, 80, 120),
	Speed_Enabled = false,
	Speed_Value = 16,
	JumpPower_Enabled = false,
	JumpPower_Value = 50,
	NoFallDamage = false,
	InfiniteJump = false,
	ClickTeleport = false,
	Fly_Enabled = false,
	Fly_Speed = 50,
	Noclip = false,
	Aimbot = false,
	Aimbot_Smooth = 5,
	Aimbot_FOV = 100,
	Aimbot_WallCheck = true,
	Aimbot_Prediction = true,
	Aimbot_PredictionOffset = 0.5,
	Aimbot_FOV_Circle = true,
	Aimbot_TargetPart = "Head",
	Aimbot_TeamCheck = false,
	Aimbot_Keybind = "MouseButton2",
	Highlight_Enabled = false,
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Color = Color3.fromRGB(140, 110, 220),
	Highlight_Self = false,
	AutoRejoin = false,
	AntiAFK = false,
}

--// Tabs
local MainTab = Window:CreateTab("Main")
local PlayerTab = Window:CreateTab("Player")
local CombatTab = Window:CreateTab("Combat")
local WorldTab = Window:CreateTab("World")

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local InfoSection = MainTab:CreateSection("Current Game")
InfoSection:CreateLabel("Game: " .. GameName)
InfoSection:CreateLabel("PlaceId: " .. PlaceId)
InfoSection:CreateButton({
	Name = "Copy JobId",
	Callback = function()
		setclipboard(game.JobId)
		Library.Notify({ Title = "Ivory", Content = "JobId copied!", Type = "Success", Duration = 2 })
	end,
})

local ScriptInfoSection = MainTab:CreateSection("Script Status")
ScriptInfoSection:CreateLabel("Universal Mode")

--// ESP
local ESPSection = MainTab:CreateSection("ESP Controls")
ESPSection:CreateToggle({
	Name = "Enable ESP",
	CurrentValue = false,
	Callback = function(v) State.ESP_Enabled = v end,
})
ESPSection:CreateToggle({
	Name = "Show Box",
	CurrentValue = true,
	Callback = function(v) State.ESP_Box = v end,
})
ESPSection:CreateToggle({
	Name = "Show Name",
	CurrentValue = true,
	Callback = function(v) State.ESP_Name = v end,
})
ESPSection:CreateToggle({
	Name = "Show Distance",
	CurrentValue = true,
	Callback = function(v) State.ESP_Distance = v end,
})
ESPSection:CreateToggle({
	Name = "Show Health Bar",
	CurrentValue = true,
	Callback = function(v) State.ESP_Health = v end,
})
ESPSection:CreateToggle({
	Name = "Show Tracer Line",
	CurrentValue = false,
	Callback = function(v) State.ESP_Tracer = v end,
})
ESPSection:CreateToggle({
	Name = "Team Check",
	CurrentValue = false,
	Callback = function(v) State.ESP_TeamCheck = v end,
})
ESPSection:CreateSlider({
	Name = "Max Distance",
	Range = {100, 5000},
	Increment = 100,
	CurrentValue = 1000,
	Callback = function(v) State.ESP_MaxDist = v end,
})

local ESPStyleSection = MainTab:CreateSection("ESP Style")
ESPStyleSection:CreateSlider({
	Name = "Box Thickness",
	Range = {1, 5},
	Increment = 1,
	CurrentValue = 2,
	Callback = function(v) State.BoxThickness = v end,
})
ESPStyleSection:CreateSlider({
	Name = "Text Size",
	Range = {10, 24},
	Increment = 1,
	CurrentValue = 14,
	Callback = function(v) State.TextSize = v end,
})

local ESPColorSection = MainTab:CreateSection("ESP Colors")
ESPColorSection:CreateColorPicker({
	Name = "Box Color",
	Color = Color3.fromRGB(140, 110, 220),
	Callback = function(v) State.Color_Box = v end,
})
ESPColorSection:CreateColorPicker({
	Name = "Name Color",
	Color = Color3.fromRGB(225, 215, 245),
	Callback = function(v) State.Color_Name = v end,
})
ESPColorSection:CreateColorPicker({
	Name = "Distance Color",
	Color = Color3.fromRGB(155, 135, 185),
	Callback = function(v) State.Color_Distance = v end,
})
ESPColorSection:CreateColorPicker({
	Name = "Tracer Color",
	Color = Color3.fromRGB(140, 110, 220),
	Callback = function(v) State.Color_Tracer = v end,
})

local HighlightSection = MainTab:CreateSection("Highlights")
HighlightSection:CreateToggle({
	Name = "Enable Highlights",
	CurrentValue = false,
	Callback = function(v)
		State.Highlight_Enabled = v
		if not v then
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local hl = player.Character:FindFirstChild("IvoryHighlight")
					if hl then hl:Destroy() end
				end
			end
		end
	end,
})
HighlightSection:CreateToggle({
	Name = "Highlight Yourself",
	CurrentValue = false,
	Callback = function(v) State.Highlight_Self = v end,
})
HighlightSection:CreateSlider({
	Name = "Fill Transparency",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) State.Highlight_FillTransparency = v / 100 end,
})
HighlightSection:CreateSlider({
	Name = "Outline Transparency",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end,
})
HighlightSection:CreateColorPicker({
	Name = "Highlight Color",
	Color = Color3.fromRGB(140, 110, 220),
	Callback = function(v) State.Highlight_Color = v end,
})

--// ═══════════════════════════════════════════════════════════
--// PLAYER TAB
--// ═══════════════════════════════════════════════════════════

local SpeedSection = PlayerTab:CreateSection("Speed")
SpeedSection:CreateToggle({
	Name = "Enable Speed",
	CurrentValue = false,
	Callback = function(v)
		State.Speed_Enabled = v
		if not v then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end) end
	end,
})
SpeedSection:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 200},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(v) State.Speed_Value = v end,
})
SpeedSection:CreateButton({
	Name = "Apply Speed",
	Callback = function() pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed_Value end) end,
})

local JumpSection = PlayerTab:CreateSection("Jump")
JumpSection:CreateToggle({
	Name = "Enable Jump Power",
	CurrentValue = false,
	Callback = function(v)
		State.JumpPower_Enabled = v
		if not v then pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end) end
	end,
})
JumpSection:CreateSlider({
	Name = "Jump Power",
	Range = {50, 300},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) State.JumpPower_Value = v end,
})
JumpSection:CreateButton({
	Name = "Apply Jump Power",
	Callback = function() pcall(function() LocalPlayer.Character.Humanoid.JumpPower = State.JumpPower_Value end) end,
})
JumpSection:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Callback = function(v) State.InfiniteJump = v end,
})

local MiscSection = PlayerTab:CreateSection("Player Mods")
MiscSection:CreateToggle({
	Name = "No Fall Damage",
	CurrentValue = false,
	Callback = function(v) State.NoFallDamage = v end,
})
MiscSection:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Callback = function(v) State.Noclip = v end,
})
MiscSection:CreateToggle({
	Name = "Click Teleport",
	CurrentValue = false,
	Callback = function(v) State.ClickTeleport = v end,
})

local FlySection = PlayerTab:CreateSection("Fly")
FlySection:CreateToggle({
	Name = "Enable Fly",
	CurrentValue = false,
	Callback = function(v) State.Fly_Enabled = v end,
})
FlySection:CreateSlider({
	Name = "Fly Speed",
	Range = {10, 200},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) State.Fly_Speed = v end,
})

--// ═══════════════════════════════════════════════════════════
--// COMBAT TAB
--// ═══════════════════════════════════════════════════════════

local AimbotSection = CombatTab:CreateSection("Aimbot")
AimbotSection:CreateToggle({
	Name = "Enable Aimbot",
	CurrentValue = false,
	Callback = function(v) State.Aimbot = v end,
})
AimbotSection:CreateKeybind({
	Name = "Aimbot Keybind",
	CurrentKeybind = "MouseButton2",
	Callback = function(keybind)
		State.Aimbot_Keybind = keybind
		refreshAimbotBind()
	end,
})
AimbotSection:CreateDropdown({
	Name = "Target Part",
	Options = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" },
	CurrentOption = "Head",
	Callback = function(v) State.Aimbot_TargetPart = v end,
})
AimbotSection:CreateSlider({
	Name = "FOV (px)",
	Range = {20, 500},
	Increment = 10,
	CurrentValue = 100,
	Callback = function(v) State.Aimbot_FOV = v end,
})
AimbotSection:CreateSlider({
	Name = "Smoothing",
	Range = {1, 20},
	Increment = 1,
	CurrentValue = 5,
	Callback = function(v) State.Aimbot_Smooth = v end,
})
AimbotSection:CreateToggle({
	Name = "Wall Check",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_WallCheck = v end,
})
AimbotSection:CreateToggle({
	Name = "Predict Movement",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_Prediction = v end,
})
AimbotSection:CreateSlider({
	Name = "Prediction Lead",
	Range = {0, 50},
	Increment = 1,
	CurrentValue = 5,
	Callback = function(v) State.Aimbot_PredictionOffset = v / 10 end,
})
AimbotSection:CreateToggle({
	Name = "Show FOV Circle",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_FOV_Circle = v end,
})
AimbotSection:CreateToggle({
	Name = "Team Check",
	CurrentValue = false,
	Callback = function(v) State.Aimbot_TeamCheck = v end,
})

--// ═══════════════════════════════════════════════════════════
--// WORLD TAB
--// ═══════════════════════════════════════════════════════════

local WorldSection = WorldTab:CreateSection("World Settings")
WorldSection:CreateToggle({
	Name = "Auto Rejoin on Kick",
	CurrentValue = false,
	Callback = function(v) State.AutoRejoin = v end,
})
WorldSection:CreateToggle({
	Name = "Anti AFK",
	CurrentValue = false,
	Callback = function(v) State.AntiAFK = v end,
})
WorldSection:CreateButton({
	Name = "Rejoin Now",
	Callback = function() pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end) end,
})
WorldSection:CreateButton({
	Name = "Server Hop",
	Callback = function()
		pcall(function()
			local servers = HttpService:JSONDecode(request({
				Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
				Method = "GET"
			}).Body)
			if servers and servers.data then
				for _, server in ipairs(servers.data) do
					if server.id ~= game.JobId and server.playing < server.maxPlayers then
						TeleportService:TeleportToPlaceInstance(PlaceId, server.id, LocalPlayer)
						break
					end
				end
			end
		end)
	end,
})
WorldSection:CreateButton({
	Name = "Copy Server JobId",
	Callback = function()
		setclipboard(game.JobId)
		Library.Notify({ Title = "Ivory", Content = "JobId copied!", Type = "Success", Duration = 2 })
	end,
})

--// ═══════════════════════════════════════════════════════════
--// ESP LOGIC
--// ═══════════════════════════════════════════════════════════

local espObjects = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = State.Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = State.Color_Box
FOVCircle.Transparency = 0.8

local function worldToScreen(position)
	local screenPos, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function createESP(player)
	if player == LocalPlayer then return end
	local esp = {
		Box = Drawing.new("Square"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Health = Drawing.new("Line"),
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
	esp.Health.Thickness = 3
	esp.Tracer.Thickness = 1
	esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
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

--// ═══════════════════════════════════════════════════════════
--// HIGHLIGHTS
--// ═══════════════════════════════════════════════════════════

local function applyHighlight(player)
	if player == LocalPlayer and not State.Highlight_Self then return end
	if not player.Character then return end
	local hl = player.Character:FindFirstChild("IvoryHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "IvoryHighlight"
		hl.Parent = player.Character
	end
	hl.FillColor = State.Highlight_Color
	hl.OutlineColor = State.Highlight_Color
	hl.Adornee = player.Character
	hl.FillTransparency = State.Highlight_FillTransparency
	hl.OutlineTransparency = State.Highlight_OutlineTransparency
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled = State.Highlight_Enabled
end

local function removeHighlight(player)
	if player.Character then
		local hl = player.Character:FindFirstChild("IvoryHighlight")
		if hl then hl:Destroy() end
	end
end

--// ═══════════════════════════════════════════════════════════
--// AIMBOT
--// ═══════════════════════════════════════════════════════════

local aimbotKeyDown = false
local aimbotBindType = "Mouse"
local aimbotBindCode = Enum.UserInputType.MouseButton2

local function parseKeybind(keybindStr)
	if not keybindStr or keybindStr == "" then return "Mouse", Enum.UserInputType.MouseButton2 end
	if keybindStr:find("MouseButton") then return "Mouse", Enum.UserInputType[keybindStr] end
	return "Keyboard", Enum.KeyCode[keybindStr]
end

local function refreshAimbotBind()
	local tp, code = parseKeybind(State.Aimbot_Keybind)
	aimbotBindType = tp
	aimbotBindCode = code
end
refreshAimbotBind()

local function isPartVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(origin, direction, rayParams) == nil
end

--// Team detection
local TeamAttributeNames = { "Team", "TeamName", "team", "teamName" }

local function GetTeamKey(player)
	if player.Team then
		return "team:" .. player.Team.Name
	end
	if player.TeamColor and player.TeamColor ~= BrickColor.new("Medium stone grey") then
		return "color:" .. tostring(player.TeamColor)
	end
	for _, attr in ipairs(TeamAttributeNames) do
		local v = player:GetAttribute(attr)
		if v then return "attr:" .. tostring(v) end
	end
	for _, child in ipairs(player:GetChildren()) do
		if child:IsA("ObjectValue") and child.Name:lower():find("team") and child.Value then
			return "obj:" .. tostring(child.Value)
		end
	end
	local char = player.Character
	if char then
		for _, attr in ipairs(TeamAttributeNames) do
			local v = char:GetAttribute(attr)
			if v then return "cattr:" .. tostring(v) end
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			for _, attr in ipairs(TeamAttributeNames) do
				local v = hum:GetAttribute(attr)
				if v then return "hattr:" .. tostring(v) end
			end
		end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("ObjectValue") and child.Name:lower():find("team") and child.Value then
				return "cobj:" .. tostring(child.Value)
			end
			if child:IsA("Folder") and child.Name:lower():find("team") then
				return "folder:" .. child.Name
			end
			if (child:IsA("StringValue") or child:IsA("BoolValue")) and child.Name:lower():find("team") then
				return "val:" .. tostring(child.Value)
			end
		end
		local parent = char.Parent
		if parent and parent ~= Workspace and parent:IsA("Model") and parent ~= player then
			return "parent:" .. parent.Name
		end
	end
	return nil
end

local function IsTeammate(player)
	local myTeam = GetTeamKey(LocalPlayer)
	if not myTeam then return false end
	local theirTeam = GetTeamKey(player)
	if not theirTeam then return false end
	return theirTeam == myTeam
end

local function getNearestTarget()
	local closestPlayer = nil
	local closestDist = State.Aimbot_FOV
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(State.Aimbot_TargetPart) then
			if State.Aimbot_TeamCheck and IsTeammate(player) then
				continue
			end
			if not State.Aimbot_WallCheck or isPartVisible(player.Character[State.Aimbot_TargetPart]) then
				local pos = Camera:WorldToViewportPoint(player.Character[State.Aimbot_TargetPart].Position)
				local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
				if dist < closestDist then
					closestDist = dist
					closestPlayer = player
				end
			end
		end
	end
	return closestPlayer
end

--// ═══════════════════════════════════════════════════════════
--// FLY / NOCLIP
--// ═══════════════════════════════════════════════════════════

local flyBodyVelocity, flyBodyGyro, noclipConnection

local function startFly()
	pcall(function()
		local hrp = LocalPlayer.Character.HumanoidRootPart
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

local function startNoclip()
	noclipConnection = RunService.Stepped:Connect(function()
		pcall(function()
			for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end)
end

local function stopNoclip()
	if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

--// ═══════════════════════════════════════════════════════════
--// INPUT HANDLERS
--// ═══════════════════════════════════════════════════════════

UserInputService.JumpRequest:Connect(function()
	if State.InfiniteJump then
		pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if State.ClickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
		pcall(function()
			local mouse = LocalPlayer:GetMouse()
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
		end)
	end
	if State.Aimbot then
		if aimbotBindType == "Mouse" and input.UserInputType == aimbotBindCode then
			aimbotKeyDown = true
		elseif aimbotBindType == "Keyboard" and input.KeyCode == aimbotBindCode then
			aimbotKeyDown = true
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if aimbotBindType == "Mouse" and input.UserInputType == aimbotBindCode then
		aimbotKeyDown = false
	elseif aimbotBindType == "Keyboard" and input.KeyCode == aimbotBindCode then
		aimbotKeyDown = false
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		if State.AntiAFK then pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end
	end
end)

--// ═══════════════════════════════════════════════════════════
--// MAIN LOOP
--// ═══════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera

	if State.Speed_Enabled then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed_Value end) end
	if State.JumpPower_Enabled then pcall(function() LocalPlayer.Character.Humanoid.JumpPower = State.JumpPower_Value end) end

	if State.Fly_Enabled then
		if not flyBodyVelocity then startFly() end
		pcall(function()
			local hrp = LocalPlayer.Character.HumanoidRootPart
			local camCF = Camera.CFrame
			local moveDir = Vector3.new(0, 0, 0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
			flyBodyVelocity.Velocity = moveDir.Unit * State.Fly_Speed
			flyBodyGyro.CFrame = camCF
		end)
	else
		if flyBodyVelocity then stopFly() end
	end

	if State.Noclip then if not noclipConnection then startNoclip() end else if noclipConnection then stopNoclip() end end

	if State.Aimbot_FOV_Circle and State.Aimbot then
		FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		FOVCircle.Radius = State.Aimbot_FOV
		FOVCircle.Visible = true
	else
		FOVCircle.Visible = false
	end

	if State.Aimbot then
		local target = getNearestTarget()
		if target and target.Character and target.Character:FindFirstChild(State.Aimbot_TargetPart) then
			local targetPart = target.Character[State.Aimbot_TargetPart]
			local targetPos = targetPart.Position
			if State.Aimbot_Prediction then
				targetPos = targetPos + targetPart.AssemblyLinearVelocity * State.Aimbot_PredictionOffset * 0.1
			end
			Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 1 / State.Aimbot_Smooth)
		end
	end

	for player, esp in pairs(espObjects) do
		local show = State.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
		if show and State.ESP_TeamCheck and IsTeammate(player) then
			show = false
		end
		if State.Highlight_Enabled then applyHighlight(player) else removeHighlight(player) end
		if show then
			local hrp = player.Character.HumanoidRootPart
			local hum = player.Character.Humanoid
			local _, onScreen, dist = worldToScreen(hrp.Position)
			if onScreen and dist > 0 and dist <= State.ESP_MaxDist then
				local rootPos = Camera:WorldToViewportPoint(hrp.Position)
				local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
				local boxHeight = math.abs(rootPos.Y - headPos.Y) * 2.2
				local boxWidth = boxHeight * 0.65
				local healthPercent = hum.Health / hum.MaxHealth
				esp.Box.Size = Vector2.new(boxWidth, boxHeight)
				esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
				esp.Box.Thickness = State.BoxThickness
				esp.Box.Color = State.Color_Box
				esp.Box.Visible = State.ESP_Box
				esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 18)
				esp.Name.Text = player.DisplayName
				esp.Name.Size = State.TextSize
				esp.Name.Color = State.Color_Name
				esp.Name.Visible = State.ESP_Name
				esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 4)
				esp.Distance.Text = math.floor(dist) .. "m"
				esp.Distance.Size = State.TextSize - 2
				esp.Distance.Color = State.Color_Distance
				esp.Distance.Visible = State.ESP_Distance
				esp.Health.From = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2)
				esp.Health.To = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2 - (boxHeight * healthPercent))
				esp.Health.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				esp.Health.Visible = State.ESP_Health
				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
				esp.Tracer.Color = State.Color_Tracer
				esp.Tracer.Visible = State.ESP_Tracer
			else
				esp.Box.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.Tracer.Visible = false
			end
		else
			esp.Box.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.Tracer.Visible = false
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if State.AutoRejoin then
			pcall(function()
				if not LocalPlayer then TeleportService:Teleport(PlaceId) end
			end)
		end
	end
end)

print("[Ivory] Universal loaded!")
