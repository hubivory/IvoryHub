--// Ivory Hub | Universal Loader
--// Works in ALL games via ObsidianUltra

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Load ObsidianUltra
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
	return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(getgenv()._IvoryLibSrc or httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(getgenv()._IvoryTMSrc or httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(getgenv()._IvorySMSrc or httpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

--// Ivory scheme
Library.Scheme.MainColor = Color3.fromRGB(18, 14, 28)
Library.Scheme.AccentColor = Color3.fromRGB(140, 110, 220)
Library.Scheme.AcccentDark = Color3.fromRGB(110, 80, 190)
Library.Scheme.OutlineColor = Color3.fromRGB(50, 40, 70)
Library.Scheme.FontColor = Color3.fromRGB(225, 215, 245)
Library.Scheme.SubText = Color3.fromRGB(155, 135, 185)
Library.Scheme.Bright = Color3.fromRGB(32, 26, 48)
Library.Scheme.Dark = Color3.fromRGB(12, 10, 20)
Library.Scheme.Risky = Color3.fromRGB(220, 80, 120)
Library.ShowToggleFrameInKeybinds = true
Library.ForceCheckbox = false

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
local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.4 |",
		{ Text = isLobby and "Lobby" or "Game", Copyable = true },
		"|",
		{ Text = tostring(LocalPlayer.UserId), Copyable = true },
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	MinimizedWidth = 280,
	NotifySide = "Right",
	ShowCustomCursor = false,
	SearchKeybind = Enum.KeyCode.F,
	CornerRadius = 4,
	Animations = {
		ToggleWindow = false,
		TabSwitch = false,
		Groupbox = false,
		Dropdown = false,
		KeyPicker = false,
		SubTabUnderline = true,
	},
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
	Highlight_Enabled = false,
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Color = Color3.fromRGB(140, 110, 220),
	Highlight_Self = false,
	AutoRejoin = false,
	AntiAFK = false,
}

--// Tabs
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local WorldTab = Window:AddTab({ Name = "World", Icon = "globe" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local InfoTab = MainTab:AddSubTab("Info", "info")
local ESPTab = MainTab:AddSubTab("ESP", "eye")
local VisualTab = MainTab:AddSubTab("Visuals", "highlighter")

local GameInfoGroup = InfoTab:AddLeftGroupbox("Current Game", "gamepad-2")
GameInfoGroup:AddLabel("Game: " .. GameName)
GameInfoGroup:AddLabel("PlaceId: " .. PlaceId)
GameInfoGroup:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

local ScriptInfoGroup = InfoTab:AddRightGroupbox("Script Status", "check-circle")
ScriptInfoGroup:AddLabel('<font color="#FFB74D"><b>Universal Mode</b></font>', true)
ScriptInfoGroup:AddLabel("Using universal features")

--// ESP
local ESPControls = ESPTab:AddLeftGroupbox("ESP Controls", "eye")
ESPControls:AddToggle("ESP Enabled", { Text = "Enable ESP", Default = false, Callback = function(v) State.ESP_Enabled = v end })
ESPControls:AddToggle("ESP Box", { Text = "Show Box", Default = true, Callback = function(v) State.ESP_Box = v end })
ESPControls:AddToggle("ESP Name", { Text = "Show Name", Default = true, Callback = function(v) State.ESP_Name = v end })
ESPControls:AddToggle("ESP Distance", { Text = "Show Distance", Default = true, Callback = function(v) State.ESP_Distance = v end })
ESPControls:AddToggle("ESP Health", { Text = "Show Health Bar", Default = true, Callback = function(v) State.ESP_Health = v end })
ESPControls:AddToggle("ESP Tracer", { Text = "Show Tracer Line", Default = false, Callback = function(v) State.ESP_Tracer = v end })
ESPControls:AddToggle("ESP TeamCheck", { Text = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end })
ESPControls:AddSlider("ESP MaxDist", { Text = "Max Distance", Default = 1000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) State.ESP_MaxDist = v end })

local ESPStyle = ESPTab:AddRightGroupbox("ESP Style", "sliders")
ESPStyle:AddSlider("BoxThickness", { Text = "Box Thickness", Default = 2, Min = 1, Max = 5, Rounding = 0, Callback = function(v) State.BoxThickness = v end })
ESPStyle:AddSlider("TextSize", { Text = "Text Size", Default = 14, Min = 10, Max = 24, Rounding = 0, Callback = function(v) State.TextSize = v end })

local ESPColors = ESPTab:AddLeftGroupbox("ESP Colors", "palette")
ESPColors:AddLabel("Box Color"):AddColorPicker("ColorBox", { Default = Color3.fromRGB(140, 110, 220), Title = "Box", Callback = function(v) State.Color_Box = v end })
ESPColors:AddLabel("Name Color"):AddColorPicker("ColorName", { Default = Color3.fromRGB(225, 215, 245), Title = "Name", Callback = function(v) State.Color_Name = v end })
ESPColors:AddLabel("Distance Color"):AddColorPicker("ColorDistance", { Default = Color3.fromRGB(155, 135, 185), Title = "Distance", Callback = function(v) State.Color_Distance = v end })
ESPColors:AddLabel("Tracer Color"):AddColorPicker("ColorTracer", { Default = Color3.fromRGB(140, 110, 220), Title = "Tracer", Callback = function(v) State.Color_Tracer = v end })

local HighlightGroup = VisualTab:AddLeftGroupbox("Highlights", "highlighter")
HighlightGroup:AddToggle("Highlight Enabled", { Text = "Enable Highlights", Default = false, Callback = function(v)
	State.Highlight_Enabled = v
	if not v then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				local hl = player.Character:FindFirstChild("IvoryHighlight")
				if hl then hl:Destroy() end
			end
		end
	end
end })
HighlightGroup:AddToggle("Highlight Self", { Text = "Highlight Yourself", Default = false, Callback = function(v) State.Highlight_Self = v end })
HighlightGroup:AddSlider("Highlight Fill", { Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0, Callback = function(v) State.Highlight_FillTransparency = v / 100 end })
HighlightGroup:AddSlider("Highlight Outline", { Text = "Outline Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0, Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end })

local HighlightColors = VisualTab:AddRightGroupbox("Highlight Colors", "palette")
HighlightColors:AddLabel("Highlight Color"):AddColorPicker("HighlightColor", { Default = Color3.fromRGB(140, 110, 220), Title = "Highlight", Callback = function(v) State.Highlight_Color = v end })

--// ═══════════════════════════════════════════════════════════
--// PLAYER TAB
--// ═══════════════════════════════════════════════════════════

local MovementTab = PlayerTab:AddSubTab("Movement", "move")
local MiscTab = PlayerTab:AddSubTab("Misc", "settings")

local SpeedGroup = MovementTab:AddLeftGroupbox("Speed", "zap")
SpeedGroup:AddToggle("Speed Enabled", { Text = "Enable Speed", Default = false, Callback = function(v)
	State.Speed_Enabled = v
	if not v then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end) end
end })
SpeedGroup:AddSlider("Speed Value", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0, Callback = function(v) State.Speed_Value = v end })
SpeedGroup:AddButton("Apply Speed", function() pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = State.Speed_Value end) end)

local JumpGroup = MovementTab:AddRightGroupbox("Jump", "arrow-up")
JumpGroup:AddToggle("JumpPower Enabled", { Text = "Enable Jump Power", Default = false, Callback = function(v)
	State.JumpPower_Enabled = v
	if not v then pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end) end
end })
JumpGroup:AddSlider("JumpPower Value", { Text = "Jump Power", Default = 50, Min = 50, Max = 300, Rounding = 0, Callback = function(v) State.JumpPower_Value = v end })
JumpGroup:AddButton("Apply Jump Power", function() pcall(function() LocalPlayer.Character.Humanoid.JumpPower = State.JumpPower_Value end) end)
JumpGroup:AddToggle("Infinite Jump", { Text = "Infinite Jump", Default = false, Callback = function(v) State.InfiniteJump = v end })

local MiscPlayerGroup = MiscTab:AddLeftGroupbox("Player Mods", "user")
MiscPlayerGroup:AddToggle("No Fall Damage", { Text = "No Fall Damage", Default = false, Callback = function(v) State.NoFallDamage = v end })
MiscPlayerGroup:AddToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(v) State.Noclip = v end })
MiscPlayerGroup:AddToggle("Click Teleport", { Text = "Click Teleport", Default = false, Callback = function(v) State.ClickTeleport = v end })

local FlyGroup = MiscTab:AddRightGroupbox("Fly", "wind")
FlyGroup:AddToggle("Fly Enabled", { Text = "Enable Fly", Default = false, Callback = function(v) State.Fly_Enabled = v end })
FlyGroup:AddSlider("Fly Speed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) State.Fly_Speed = v end })

--// ═══════════════════════════════════════════════════════════
--// COMBAT TAB
--// ═══════════════════════════════════════════════════════════

local AimbotTab = CombatTab:AddSubTab("Aimbot", "crosshair")
local AimbotGroup = AimbotTab:AddLeftGroupbox("Aimbot", "crosshair")
AimbotGroup:AddToggle("Aimbot", { Text = "Enable Aimbot", Default = false, Callback = function(v) State.Aimbot = v end })
AimbotGroup:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", { Default = "MouseButton2", NoUI = true, Text = "Aimbot Key" })
AimbotGroup:AddDropdown("Aimbot Target Part", { Text = "Target Part", Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }, Default = "Head", Callback = function(v) State.Aimbot_TargetPart = v end })
AimbotGroup:AddSlider("Aimbot FOV", { Text = "FOV (px)", Default = 100, Min = 20, Max = 500, Rounding = 0, Callback = function(v) State.Aimbot_FOV = v end })
AimbotGroup:AddSlider("Aimbot Smooth", { Text = "Smoothing", Default = 5, Min = 1, Max = 20, Rounding = 0, Callback = function(v) State.Aimbot_Smooth = v end })
AimbotGroup:AddToggle("Aimbot WallCheck", { Text = "Wall Check", Default = true, Callback = function(v) State.Aimbot_WallCheck = v end })
AimbotGroup:AddToggle("Aimbot Prediction", { Text = "Predict Movement", Default = true, Callback = function(v) State.Aimbot_Prediction = v end })
AimbotGroup:AddSlider("Aimbot Pred Offset", { Text = "Prediction Lead", Default = 5, Min = 0, Max = 50, Rounding = 0, Callback = function(v) State.Aimbot_PredictionOffset = v / 10 end })
AimbotGroup:AddToggle("Aimbot FOV Circle", { Text = "Show FOV Circle", Default = true, Callback = function(v) State.Aimbot_FOV_Circle = v end })
AimbotGroup:AddToggle("Aimbot TeamCheck", { Text = "Team Check", Default = false, Callback = function(v) State.Aimbot_TeamCheck = v end })

--// ═══════════════════════════════════════════════════════════
--// WORLD TAB
--// ═══════════════════════════════════════════════════════════

local WorldMiscTab = WorldTab:AddSubTab("World Misc", "globe")
local WorldMiscGroup = WorldMiscTab:AddLeftGroupbox("World Settings", "globe")
WorldMiscGroup:AddToggle("Auto Rejoin", { Text = "Auto Rejoin on Kick", Default = false, Callback = function(v) State.AutoRejoin = v end })
WorldMiscGroup:AddToggle("Anti AFK", { Text = "Anti AFK", Default = false, Callback = function(v) State.AntiAFK = v end })
WorldMiscGroup:AddButton("Rejoin Now", function() pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end) end)
WorldMiscGroup:AddButton("Server Hop", function()
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
end)
WorldMiscGroup:AddButton("Copy Server JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

--// ═══════════════════════════════════════════════════════════
--// SETTINGS TAB (always last)
--// ═══════════════════════════════════════════════════════════

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
if isLobby then SaveManager:SetSubFolder("lobby") else SaveManager:SetSubFolder("game") end
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = Library.ShowCustomCursor, Callback = function(Value) Library.ShowCustomCursor = Value end })
MenuGroup:AddButton("Test Notification", function() Library:Notify({ Title = "Ivory", Description = "This is a test notification!", Type = "Info", Time = 3 }) end)
MenuGroup:AddDropdown("NotifySide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(Value) Library.NotifySide = Value end })
MenuGroup:AddDropdown("DPIDropdown", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(Value) Library:SetDPIScale(tonumber(Value:gsub("%%", ""))) end })
MenuGroup:AddSlider("UICornerSlider", { Text = "Corner Radius", Default = 4, Min = 0, Max = 20, Rounding = 0, Callback = function(value) Window:SetCornerRadius(value) end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu: RightShift (default)"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

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

local function updateAimbotBind()
	local ok, val = pcall(function() return Options.AimbotKeybind.Value end)
	if ok and val and val ~= "" then
		if val:find("MouseButton") then
			aimbotBindType = "Mouse"
			aimbotBindCode = Enum.UserInputType[val]
		else
			aimbotBindType = "Keyboard"
			aimbotBindCode = Enum.KeyCode[val]
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if aimbotBindType == "Keyboard" and input.KeyCode == aimbotBindCode then aimbotKeyDown = true
	elseif aimbotBindType == "Mouse" and input.UserInputType == aimbotBindCode then aimbotKeyDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if aimbotBindType == "Keyboard" and input.KeyCode == aimbotBindCode then aimbotKeyDown = false
	elseif aimbotBindType == "Mouse" and input.UserInputType == aimbotBindCode then aimbotKeyDown = false end
end)

local function isPartVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(origin, direction, rayParams) == nil
end

--// Team detection: supports built-in Teams AND custom team systems
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
	local char = player.Character
	if char then
		for _, attr in ipairs(TeamAttributeNames) do
			local v = char:GetAttribute(attr)
			if v then return "cattr:" .. tostring(v) end
		end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("Folder") and child.Name:lower():find("team") then
				return "folder:" .. child.Name
			end
			if (child:IsA("StringValue") or child:IsA("BoolValue")) and child.Name:lower():find("team") then
				return "val:" .. tostring(child.Value)
			end
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
end)

spawn(function()
	while true do
		wait(60)
		if State.AntiAFK then pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end
	end
end)

--// ═══════════════════════════════════════════════════════════
--// MAIN LOOP
--// ═══════════════════════════════════════════════════════════

RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera
	updateAimbotBind()

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

	if State.Aimbot and aimbotKeyDown then
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

spawn(function()
	while true do
		wait(5)
		if State.AutoRejoin then
			pcall(function()
				if not LocalPlayer then TeleportService:Teleport(PlaceId) end
			end)
		end
	end
end)

Library:OnUnload(function()
	FOVCircle:Remove()
	stopFly()
	stopNoclip()
	for player, _ in pairs(espObjects) do removeESP(player) end
	for _, player in ipairs(Players:GetPlayers()) do removeHighlight(player) end
end)

print("[Ivory] Universal loaded!")
