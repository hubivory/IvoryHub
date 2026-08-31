--// Ivory Hub | Hood Rivals
--// Place IDs: 77463332823746, 113272123504853

-- ═══════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

-- ═══════════════════════════════════════════════════════
--  LOAD OBSIDIANULTRA
-- ═══════════════════════════════════════════════════════
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
	return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(getgenv()._IvoryLibSrc or httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(getgenv()._IvoryTMSrc or httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(getgenv()._IvorySMSrc or httpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

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

-- ═══════════════════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════════════════
local State = {
	ESP_Enabled = false,
	ESP_Box = true,
	ESP_Name = true,
	ESP_Distance = true,
	ESP_Health = true,
	ESP_Tracer = false,
	ESP_TeamCheck = false,
	ESP_MaxDist = 1500,
	ESP_BoxThickness = 2,
	ESP_TextSize = 14,
	ESP_Color_Box = Color3.fromRGB(140, 110, 220),
	ESP_Color_Name = Color3.fromRGB(225, 215, 245),
	ESP_Color_Distance = Color3.fromRGB(155, 135, 185),
	ESP_Color_Tracer = Color3.fromRGB(140, 110, 220),
	Speed_Enabled = false,
	Speed_Value = 16,
	JumpPower_Enabled = false,
	JumpPower_Value = 50,
	InfiniteJump = false,
	NoFallDamage = false,
	Fly_Enabled = false,
	Fly_Speed = 60,
	Noclip = false,
	ClickTeleport = false,
	NoRecoil = false,
	NoSpread = false,
	InstantReload = false,
	NoSway = false,
	InfiniteAmmo = false,
	SilentAim = false,
	SilentAim_HitPart = "Head",
	SilentAim_TeamCheck = false,
	SilentAim_WallCheck = true,
	SilentAim_FOV = 150,
	SilentAim_FOV_Circle = true,
	Aimbot = false,
	Aimbot_Smooth = 5,
	Aimbot_FOV = 100,
	Aimbot_WallCheck = true,
	Aimbot_TargetPart = "Head",
	Aimbot_TeamCheck = false,
	Aimbot_FOV_Circle = true,
	Highlight_Enabled = false,
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Color = Color3.fromRGB(140, 110, 220),
	Highlight_Self = false,
	AutoRespawn = false,
	AntiAFK = false,
	AutoRejoin = false,
	FullBright = false,
	NoFog = false,
	NoRagdoll = false,
}

-- ═══════════════════════════════════════════════════════
--  REMOTES
-- ═══════════════════════════════════════════════════════
local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes", 10)
local DataRemotes = ReplicatedStorage:WaitForChild("DataRemotes", 10)
local MatchAction = ReplicatedStorage:WaitForChild("MatchAction", 10)
local MatchEvents = ReplicatedStorage:WaitForChild("MatchEvents", 10)
local MapVote = ReplicatedStorage:WaitForChild("MapVote", 10)
local RequestRespawn = ReplicatedStorage:WaitForChild("RequestRespawn", 10)
local SpectateTarget = ReplicatedStorage:WaitForChild("SpectateTarget", 10)
local BanWeapon = ReplicatedStorage:WaitForChild("BanWeapon", 10)

-- ═══════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════
local isLobby = false

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

-- ═══════════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════════
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local WorldTab = Window:AddTab({ Name = "World", Icon = "globe" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ═══════════════════════════════════════════════════════
--  MAIN TAB — INFO
-- ═══════════════════════════════════════════════════════
local MainInfo = MainTab:AddSubTab("Info", "info")
local GameInfoGroup = MainInfo:AddLeftGroupbox("Current Game", "gamepad-2")
GameInfoGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
GameInfoGroup:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

GameInfoGroup:AddButton("Copy PlaceId", function()
	setclipboard(tostring(game.PlaceId))
	Library:Notify({ Title = "Ivory", Description = "PlaceId copied!", Type = "Success", Time = 2 })
end)

GameInfoGroup:AddButton("Rejoin Server", function()
	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)

GameInfoGroup:AddButton("Server Hop", function()
	pcall(function()
		local servers = HttpService:JSONDecode(request({
			Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET",
		}).Body)
		if servers and servers.data then
			for _, server in ipairs(servers.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					break
				end
			end
		end
	end)
end)

local DiscordGroup = MainInfo:AddRightGroupbox("Community", "heart")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function()
		if setclipboard then setclipboard("https://discord.gg/MCWYKBdB4E") end
	end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied to clipboard!", Type = "Info", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  MAIN TAB — MATCH
-- ═══════════════════════════════════════════════════════
local MainMatch = MainTab:AddSubTab("Match", "swords")
local MatchGroup = MainMatch:AddLeftGroupbox("Match Controls", "target")
MatchGroup:AddButton("Request Respawn", function()
	pcall(function() RequestRespawn:FireServer() end)
end)
MatchGroup:AddButton("Vote Map 1", function()
	pcall(function() MapVote:FireServer(1) end)
end)
MatchGroup:AddButton("Vote Map 2", function()
	pcall(function() MapVote:FireServer(2) end)
end)
MatchGroup:AddButton("Vote Map 3", function()
	pcall(function() MapVote:FireServer(3) end)
end)

local SpectateGroup = MainMatch:AddRightGroupbox("Spectate", "eye")
SpectateGroup:AddToggle("AutoRespawn", { Text = "Auto Respawn", Default = false, Callback = function(v) State.AutoRespawn = v end })

local SpectateList = {}
local function refreshSpectateList()
	SpectateList = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(SpectateList, p.Name)
		end
	end
end
refreshSpectateList()
Players.PlayerAdded:Connect(refreshSpectateList)
Players.PlayerRemoving:Connect(refreshSpectateList)

SpectateGroup:AddDropdown("SpectateTarget", { Text = "Spectate Player", Values = SpectateList, Default = "", Callback = function(v)
	local target = Players:FindFirstChild(v)
	if target then
		pcall(function() SpectateTarget:FireServer(target) end)
	end
end })

SpectateGroup:AddButton("Refresh Players", function()
	refreshSpectateList()
	local dd = Options.SpectateTarget
	if dd then dd:Refresh(SpectateList) end
	Library:Notify({ Title = "Ivory", Description = "Player list refreshed!", Type = "Success", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  COMBAT TAB — AIMBOT
-- ═══════════════════════════════════════════════════════
local AimbotSub = CombatTab:AddSubTab("Aimbot", "crosshair")

local AimbotGroup = AimbotSub:AddLeftGroupbox("Aimbot", "crosshair")
AimbotGroup:AddToggle("Aimbot", { Text = "Enable Aimbot", Default = false, Callback = function(v) State.Aimbot = v end })
AimbotGroup:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", { Default = "MouseButton2", NoUI = true, Text = "Aimbot Key" })
AimbotGroup:AddDropdown("Aimbot Target Part", { Text = "Target Part", Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }, Default = "Head", Callback = function(v) State.Aimbot_TargetPart = v end })
AimbotGroup:AddSlider("Aimbot FOV", { Text = "FOV (px)", Default = 100, Min = 20, Max = 500, Rounding = 0, Callback = function(v) State.Aimbot_FOV = v end })
AimbotGroup:AddSlider("Aimbot Smooth", { Text = "Smoothing", Default = 5, Min = 1, Max = 20, Rounding = 0, Callback = function(v) State.Aimbot_Smooth = v end })
AimbotGroup:AddToggle("Aimbot WallCheck", { Text = "Wall Check", Default = true, Callback = function(v) State.Aimbot_WallCheck = v end })
AimbotGroup:AddToggle("Aimbot TeamCheck", { Text = "Team Check", Default = false, Callback = function(v) State.Aimbot_TeamCheck = v end })
AimbotGroup:AddToggle("Aimbot FOV Circle", { Text = "Show FOV Circle", Default = true, Callback = function(v) State.Aimbot_FOV_Circle = v end })

-- ═══════════════════════════════════════════════════════
--  COMBAT TAB — SILENT AIM
-- ═══════════════════════════════════════════════════════
local SilentAimSub = CombatTab:AddSubTab("Silent Aim", "target")
local SilentAimGroup = SilentAimSub:AddLeftGroupbox("Silent Aim", "target")
SilentAimGroup:AddToggle("SilentAim", { Text = "Enable Silent Aim", Default = false, Callback = function(v) State.SilentAim = v end })
SilentAimGroup:AddLabel("Silent Aim Keybind"):AddKeyPicker("SilentAimKeybind", { Default = "MouseButton2", NoUI = true, Text = "Silent Aim Key" })
SilentAimGroup:AddDropdown("SilentAim HitPart", { Text = "Hit Part", Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }, Default = "Head", Callback = function(v) State.SilentAim_HitPart = v end })
SilentAimGroup:AddSlider("SilentAim FOV", { Text = "FOV (px)", Default = 150, Min = 20, Max = 500, Rounding = 0, Callback = function(v) State.SilentAim_FOV = v end })
SilentAimGroup:AddToggle("SilentAim WallCheck", { Text = "Wall Check", Default = true, Callback = function(v) State.SilentAim_WallCheck = v end })
SilentAimGroup:AddToggle("SilentAim TeamCheck", { Text = "Team Check", Default = false, Callback = function(v) State.SilentAim_TeamCheck = v end })
SilentAimGroup:AddToggle("SilentAim FOV Circle", { Text = "Show FOV Circle", Default = true, Callback = function(v) State.SilentAim_FOV_Circle = v end })

-- ═══════════════════════════════════════════════════════
--  COMBAT TAB — WEAPON MODS
-- ═══════════════════════════════════════════════════════
local WeaponSub = CombatTab:AddSubTab("Weapon Mods", "zap")
local WeaponGroup = WeaponSub:AddLeftGroupbox("Weapon Mods", "zap")
WeaponGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) State.NoRecoil = v end })
WeaponGroup:AddToggle("NoSpread", { Text = "No Spread", Default = false, Callback = function(v) State.NoSpread = v end })
WeaponGroup:AddToggle("InstantReload", { Text = "Instant Reload", Default = false, Callback = function(v) State.InstantReload = v end })
WeaponGroup:AddToggle("NoSway", { Text = "No Weapon Sway", Default = false, Callback = function(v) State.NoSway = v end })
WeaponGroup:AddToggle("InfiniteAmmo", { Text = "Infinite Ammo", Default = false, Callback = function(v) State.InfiniteAmmo = v end })

local AmmoGroup = WeaponSub:AddRightGroupbox("Ammo Info", "info")
AmmoGroup:AddLabel("No Recoil removes weapon kick")
AmmoGroup:AddLabel("No Spread makes all shots precise")
AmmoGroup:AddLabel("Instant Reload skips reload animation")
AmmoGroup:AddLabel("No Sway removes weapon sway")

-- ═══════════════════════════════════════════════════════
--  PLAYER TAB — MOVEMENT
-- ═══════════════════════════════════════════════════════
local MovementSub = PlayerTab:AddSubTab("Movement", "move")
local SpeedGroup = MovementSub:AddLeftGroupbox("Speed", "zap")
SpeedGroup:AddToggle("Speed Enabled", { Text = "Enable Speed", Default = false, Callback = function(v)
	State.Speed_Enabled = v
	if not v then pcall(function() Humanoid.WalkSpeed = 16 end) end
end })
SpeedGroup:AddSlider("Speed Value", { Text = "Walk Speed", Default = 16, Min = 16, Max = 250, Rounding = 0, Callback = function(v) State.Speed_Value = v end })
SpeedGroup:AddButton("Apply Speed", function() pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end)

local JumpGroup = MovementSub:AddRightGroupbox("Jump", "arrow-up")
JumpGroup:AddToggle("JumpPower Enabled", { Text = "Enable Jump Power", Default = false, Callback = function(v)
	State.JumpPower_Enabled = v
	if not v then pcall(function() Humanoid.JumpPower = 50 end) end
end })
JumpGroup:AddSlider("JumpPower Value", { Text = "Jump Power", Default = 50, Min = 50, Max = 350, Rounding = 0, Callback = function(v) State.JumpPower_Value = v end })
JumpGroup:AddButton("Apply Jump Power", function() pcall(function() Humanoid.JumpPower = State.JumpPower_Value end) end })
JumpGroup:AddToggle("Infinite Jump", { Text = "Infinite Jump", Default = false, Callback = function(v) State.InfiniteJump = v end })

-- ═══════════════════════════════════════════════════════
--  PLAYER TAB — MISC
-- ═══════════════════════════════════════════════════════
local MiscSub = PlayerTab:AddSubTab("Misc", "settings")
local FlyGroup = MiscSub:AddLeftGroupbox("Fly", "wind")
FlyGroup:AddToggle("Fly Enabled", { Text = "Enable Fly", Default = false, Callback = function(v) State.Fly_Enabled = v end })
FlyGroup:AddSlider("Fly Speed", { Text = "Fly Speed", Default = 60, Min = 10, Max = 250, Rounding = 0, Callback = function(v) State.Fly_Speed = v end })

local MiscPlayerGroup = MiscSub:AddRightGroupbox("Player Mods", "user")
MiscPlayerGroup:AddToggle("No Fall Damage", { Text = "No Fall Damage", Default = false, Callback = function(v) State.NoFallDamage = v end })
MiscPlayerGroup:AddToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(v) State.Noclip = v end })
MiscPlayerGroup:AddToggle("Click Teleport", { Text = "Click Teleport", Default = false, Callback = function(v) State.ClickTeleport = v end })

-- ═══════════════════════════════════════════════════════
--  VISUALS TAB — ESP
-- ═══════════════════════════════════════════════════════
local ESPSub = VisualsTab:AddSubTab("ESP", "eye")
local ESPControls = ESPSub:AddLeftGroupbox("ESP Controls", "eye")
ESPControls:AddToggle("ESP Enabled", { Text = "Enable ESP", Default = false, Callback = function(v) State.ESP_Enabled = v end })
ESPControls:AddToggle("ESP Box", { Text = "Show Box", Default = true, Callback = function(v) State.ESP_Box = v end })
ESPControls:AddToggle("ESP Name", { Text = "Show Name", Default = true, Callback = function(v) State.ESP_Name = v end })
ESPControls:AddToggle("ESP Distance", { Text = "Show Distance", Default = true, Callback = function(v) State.ESP_Distance = v end })
ESPControls:AddToggle("ESP Health", { Text = "Show Health Bar", Default = true, Callback = function(v) State.ESP_Health = v end })
ESPControls:AddToggle("ESP Tracer", { Text = "Show Tracer Line", Default = false, Callback = function(v) State.ESP_Tracer = v end })
ESPControls:AddToggle("ESP TeamCheck", { Text = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end })
ESPControls:AddSlider("ESP MaxDist", { Text = "Max Distance", Default = 1500, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) State.ESP_MaxDist = v end })

local ESPStyle = ESPSub:AddRightGroupbox("ESP Style", "sliders")
ESPStyle:AddSlider("BoxThickness", { Text = "Box Thickness", Default = 2, Min = 1, Max = 5, Rounding = 0, Callback = function(v) State.ESP_BoxThickness = v end })
ESPStyle:AddSlider("TextSize", { Text = "Text Size", Default = 14, Min = 10, Max = 24, Rounding = 0, Callback = function(v) State.ESP_TextSize = v end })

local ESPColors = ESPSub:AddLeftGroupbox("ESP Colors", "palette")
ESPColors:AddLabel("Box Color"):AddColorPicker("ColorBox", { Default = Color3.fromRGB(140, 110, 220), Title = "Box", Callback = function(v) State.ESP_Color_Box = v end })
ESPColors:AddLabel("Name Color"):AddColorPicker("ColorName", { Default = Color3.fromRGB(225, 215, 245), Title = "Name", Callback = function(v) State.ESP_Color_Name = v end })
ESPColors:AddLabel("Distance Color"):AddColorPicker("ColorDistance", { Default = Color3.fromRGB(155, 135, 185), Title = "Distance", Callback = function(v) State.ESP_Color_Distance = v end })
ESPColors:AddLabel("Tracer Color"):AddColorPicker("ColorTracer", { Default = Color3.fromRGB(140, 110, 220), Title = "Tracer", Callback = function(v) State.ESP_Color_Tracer = v end })

-- ═══════════════════════════════════════════════════════
--  VISUALS TAB — HIGHLIGHTS
-- ═══════════════════════════════════════════════════════
local HighlightSub = VisualsTab:AddSubTab("Highlights", "highlighter")
local HighlightGroup = HighlightSub:AddLeftGroupbox("Highlights", "highlighter")
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

local HighlightColors = HighlightSub:AddRightGroupbox("Highlight Colors", "palette")
HighlightColors:AddLabel("Highlight Color"):AddColorPicker("HighlightColor", { Default = Color3.fromRGB(140, 110, 220), Title = "Highlight", Callback = function(v) State.Highlight_Color = v end })

-- ═══════════════════════════════════════════════════════
--  WORLD TAB
-- ═══════════════════════════════════════════════════════
local WorldMiscTab = WorldTab:AddSubTab("World Misc", "globe")
local WorldMiscGroup = WorldMiscTab:AddLeftGroupbox("World Settings", "globe")
WorldMiscGroup:AddToggle("FullBright", { Text = "Full Bright", Default = false, Callback = function(v)
	State.FullBright = v
	if v then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.GlobalShadows = false
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
	end
end })
WorldMiscGroup:AddToggle("No Fog", { Text = "No Fog", Default = false, Callback = function(v)
	State.NoFog = v
	if v then
		Lighting.FogEnd = 999999
		Lighting.FogStart = 0
		Lighting.Atmosphere.Density = 0
	else
		Lighting.FogEnd = 100000
		Lighting.Atmosphere.Density = 0.3
	end
end })
WorldMiscGroup:AddToggle("No Ragdoll", { Text = "No Ragdoll", Default = false, Callback = function(v) State.NoRagdoll = v end })
WorldMiscGroup:AddToggle("Anti AFK", { Text = "Anti AFK", Default = false, Callback = function(v) State.AntiAFK = v end })
WorldMiscGroup:AddToggle("Auto Rejoin", { Text = "Auto Rejoin on Kick", Default = false, Callback = function(v) State.AutoRejoin = v end })

local ServerGroup = WorldMiscTab:AddRightGroupbox("Server", "server")
ServerGroup:AddButton("Rejoin Now", function()
	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)
ServerGroup:AddButton("Server Hop", function()
	pcall(function()
		local servers = HttpService:JSONDecode(request({
			Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET",
		}).Body)
		if servers and servers.data then
			for _, server in ipairs(servers.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					break
				end
			end
		end
	end)
end)
ServerGroup:AddButton("Copy Server JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  SETTINGS TAB (always last)
-- ═══════════════════════════════════════════════════════
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("hoodrivals")

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

-- ═══════════════════════════════════════════════════════
--  ESP LOGIC
-- ═══════════════════════════════════════════════════════
local espObjects = {}
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = State.Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = State.ESP_Color_Box
FOVCircle.Transparency = 0.8

local SilentAimFOVCircle = Drawing.new("Circle")
SilentAimFOVCircle.Thickness = 1.5
SilentAimFOVCircle.NumSides = 64
SilentAimFOVCircle.Radius = State.SilentAim_FOV
SilentAimFOVCircle.Filled = false
SilentAimFOVCircle.Visible = false
SilentAimFOVCircle.Color = Color3.fromRGB(255, 100, 100)
SilentAimFOVCircle.Transparency = 0.8

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
	esp.Box.Thickness = State.ESP_BoxThickness
	esp.Box.Filled = false
	esp.Name.Size = State.ESP_TextSize
	esp.Name.Center = true
	esp.Name.Outline = true
	esp.Name.Font = Drawing.Fonts.UI
	esp.Distance.Size = State.ESP_TextSize - 2
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

-- ═══════════════════════════════════════════════════════
--  HIGHLIGHTS
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
--  AIMBOT / SILENT AIM
-- ═══════════════════════════════════════════════════════
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

local function GetTeamKey(player)
	if player.Team then
		return "team:" .. player.Team.Name
	end
	if player.TeamColor and player.TeamColor ~= BrickColor.new("Medium stone grey") then
		return "color:" .. tostring(player.TeamColor)
	end
	for _, attr in ipairs({ "Team", "TeamName", "team", "teamName" }) do
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
		for _, attr in ipairs({ "Team", "TeamName", "team", "teamName" }) do
			local v = char:GetAttribute(attr)
			if v then return "cattr:" .. tostring(v) end
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			for _, attr in ipairs({ "Team", "TeamName", "team", "teamName" }) do
				local v = hum:GetAttribute(attr)
				if v then return "hattr:" .. tostring(v) end
			end
		end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("ObjectValue") and child.Name:lower():find("team") and child.Value then
				return "cobj:" .. tostring(child.Value)
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
			if State.Aimbot_TeamCheck and IsTeammate(player) then continue end
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

local function getNearestTargetForSilentAim()
	local closestPlayer = nil
	local closestDist = State.SilentAim_FOV
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(State.SilentAim_HitPart) then
			if State.SilentAim_TeamCheck and IsTeammate(player) then continue end
			if not State.SilentAim_WallCheck or isPartVisible(player.Character[State.SilentAim_HitPart]) then
				local pos = Camera:WorldToViewportPoint(player.Character[State.SilentAim_HitPart].Position)
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

-- ═══════════════════════════════════════════════════════
--  FLY / NOCLIP
-- ═══════════════════════════════════════════════════════
local flyBodyVelocity, flyBodyGyro, noclipConnection

local function startFly()
	pcall(function()
		local hrp = HumanoidRootPart
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
			for _, part in ipairs(Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end)
end

local function stopNoclip()
	if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

-- ═══════════════════════════════════════════════════════
--  WEAPON MOD HOOKS
-- ═══════════════════════════════════════════════════════
local function hookWeaponMods()
	if State.NoRecoil or State.NoSpread or State.InstantReload or State.NoSway or State.InfiniteAmmo then
		pcall(function()
			for _, tool in ipairs(Character:GetChildren()) do
				if tool:IsA("Tool") then
					local handler = tool:FindFirstChild("Handler") or tool:FindFirstChildWhichIsA("LocalScript")
					if handler then
						local env = getsenv and getsenv(handler)
						if env then
							if State.NoRecoil and env.Recoil then
								env.Recoil = function() return Vector3.new(0, 0, 0) end
							end
							if State.NoSpread and env.Spread then
								env.Spread = function() return 0 end
							end
						end
					end
				end
			end
		end)
	end
end

-- ═══════════════════════════════════════════════════════
--  INPUT HANDLERS
-- ═══════════════════════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
	if State.InfiniteJump then
		pcall(function() Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if State.ClickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
		pcall(function()
			local mouse = LocalPlayer:GetMouse()
			HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(60)
		if State.AntiAFK then pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end
	end
end)

-- ═══════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera
	Character = LocalPlayer.Character or Character
	Humanoid = Character and Character:FindFirstChildOfClass("Humanoid") or Humanoid
	HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart") or HumanoidRootPart

	updateAimbotBind()

	if State.Speed_Enabled then pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end
	if State.JumpPower_Enabled then pcall(function() Humanoid.JumpPower = State.JumpPower_Value end) end

	if State.Fly_Enabled then
		if not flyBodyVelocity then startFly() end
		pcall(function()
			local hrp = HumanoidRootPart
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

	if State.NoRagdoll then
		pcall(function()
			for _, v in ipairs(Character:GetDescendants()) do
				if v:IsA("JointInstance") then v:Destroy() end
			end
		end)
	end

	if State.InstantReload then
		pcall(function()
			for _, tool in ipairs(Character:GetChildren()) do
				if tool:IsA("Tool") then
					local reload = tool:FindFirstChild("ReloadTime") or tool:FindFirstChild("Reload")
					if reload and reload:IsA("NumberValue") then reload.Value = 0 end
				end
			end
		end)
	end

	-- FOV Circles
	if State.Aimbot_FOV_Circle and State.Aimbot then
		FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		FOVCircle.Radius = State.Aimbot_FOV
		FOVCircle.Visible = true
	else
		FOVCircle.Visible = false
	end

	if State.SilentAim_FOV_Circle and State.SilentAim then
		SilentAimFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		SilentAimFOVCircle.Radius = State.SilentAim_FOV
		SilentAimFOVCircle.Visible = true
	else
		SilentAimFOVCircle.Visible = false
	end

	-- Aimbot
	if State.Aimbot and aimbotKeyDown then
		local target = getNearestTarget()
		if target and target.Character and target.Character:FindFirstChild(State.Aimbot_TargetPart) then
			local targetPos = target.Character[State.Aimbot_TargetPart].Position
			Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 1 / State.Aimbot_Smooth)
		end
	end

	-- ESP & Highlights
	for player, esp in pairs(espObjects) do
		local show = State.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
		if show and State.ESP_TeamCheck and IsTeammate(player) then show = false end
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
				esp.Box.Thickness = State.ESP_BoxThickness
				esp.Box.Color = State.ESP_Color_Box
				esp.Box.Visible = State.ESP_Box
				esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 18)
				esp.Name.Text = player.DisplayName
				esp.Name.Size = State.ESP_TextSize
				esp.Name.Color = State.ESP_Color_Name
				esp.Name.Visible = State.ESP_Name
				esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 4)
				esp.Distance.Text = math.floor(dist) .. "m"
				esp.Distance.Size = State.ESP_TextSize - 2
				esp.Distance.Color = State.ESP_Color_Distance
				esp.Distance.Visible = State.ESP_Distance
				esp.Health.From = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2)
				esp.Health.To = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2 - (boxHeight * healthPercent))
				esp.Health.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				esp.Health.Visible = State.ESP_Health
				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
				esp.Tracer.Color = State.ESP_Color_Tracer
				esp.Tracer.Visible = State.ESP_Tracer
			else
				esp.Box.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.Tracer.Visible = false
			end
		else
			esp.Box.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.Tracer.Visible = false
		end
	end
end)

-- ═══════════════════════════════════════════════════════
--  AUTO RESPAWN
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(1)
		if State.AutoRespawn then
			pcall(function()
				if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
					RequestRespawn:FireServer()
				end
			end)
		end
	end
end)

-- ═══════════════════════════════════════════════════════
--  AUTO REJOIN
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(30)
		if State.AutoRejoin then
			pcall(function()
				if not LocalPlayer or not LocalPlayer.Parent then
					TeleportService:Teleport(game.PlaceId)
				end
			end)
		end
	end
end)

-- ═══════════════════════════════════════════════════════
--  UNLOAD CLEANUP
-- ═══════════════════════════════════════════════════════
Library:OnUnload(function()
	FOVCircle:Remove()
	SilentAimFOVCircle:Remove()
	stopFly()
	stopNoclip()
	for player, _ in pairs(espObjects) do removeESP(player) end
	for _, player in ipairs(Players:GetPlayers()) do removeHighlight(player) end
end)

Library:Notify({ Title = "Ivory", Description = "Script loaded. RightBracket to toggle menu.", Type = "Success", Time = 3 })
print("[Ivory] Hood Rivals loaded!")
