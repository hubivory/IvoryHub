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
local VIM = game:GetService("VirtualInputManager")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

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
	-- Combat
	AutoParry = false,
	DetectionRange = 15,
	EvasiveMode = false,
	EvasiveDirectional = false,
	ParryOnly = false,
	PauseM1ForParry = false,
	Priority = "Parry",
	FacingStrictness = 0.5,
	NoParryCooldown = false,
	NoDodgeCooldown = false,
	AutoPunish = false,
	PunishMethod = "M1",
	FlingAura = false,
	NoStun = false,
	NoRagdoll = false,
	LagSwitch = false,
	DisableGlassesKnocked = false,
	NoBlurWhenKnocked = false,

	-- Targeting
	FaceLock = false,
	StickyTarget = false,
	SelectPlayer = "",
	WhitelistPlayers = {},

	-- Rhythm
	AutoGreen = false,
	Accuracy = 0.95,
	AutoRhythm = false,
	RhythmVertical = 0,
	RhythmSmooth = 0.5,
	RhythmAnimSpeed = 1,

	-- ESP
	ESP_Enabled = false,
	ESP_Box = true,
	ESP_Fill = false,
	ESP_Name = true,
	ESP_Distance = true,
	ESP_Health = true,
	ESP_Tracer = false,
	ESP_HeadDot = false,
	ESP_TeamCheck = false,
	ESP_MaxDist = 1500,
	ESP_BoxThickness = 2,
	ESP_TextSize = 14,
	ESP_FillTransparency = 0.5,
	ESP_OutlineTransparency = 0,
	ESP_Color = Color3.fromRGB(140, 110, 220),

	-- Highlight
	Highlight_Enabled = false,
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Color = Color3.fromRGB(140, 110, 220),

	-- World
	FullBright = false,
	NightMode = false,
	AmbientR = 128,
	AmbientG = 128,
	AmbientB = 128,
	CameraFOV = 70,
	LowGFX = false,

	-- Movement
	SpeedEnabled = false,
	SpeedValue = 16,
	FlyEnabled = false,
	FlySpeed = 60,
	InfiniteJump = false,
	InfiniteStamina = false,
	AutoSprint = false,
	Noclip = false,

	-- Aimbot (kept from original)
	Aimbot = false,
	Aimbot_Smooth = 5,
	Aimbot_FOV = 100,
	Aimbot_WallCheck = true,
	Aimbot_TargetPart = "Head",
	Aimbot_TeamCheck = false,
	Aimbot_FOV_Circle = true,
	SilentAim = false,
	SilentAim_HitPart = "Head",
	SilentAim_TeamCheck = false,
	SilentAim_WallCheck = true,
	SilentAim_FOV = 150,
	SilentAim_FOV_Circle = true,

	-- Misc
	NoRecoil = false,
	NoSpread = false,
	InstantReload = false,
	NoSway = false,
	InfiniteAmmo = false,
	ClickTeleport = false,
	AutoRespawn = false,
	AntiAFK = false,
	AutoRejoin = false,
	NoFog = false,
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

-- ═══════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════
local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v2.0 |",
		{ Text = "Game", Copyable = true },
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
--  TABS (matching template)
-- ═══════════════════════════════════════════════════════
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })

-- ═══════════════════════════════════════════════════════
--  MAIN > COMBAT
-- ═══════════════════════════════════════════════════════
local CombatSub = MainTab:AddSubTab("Combat", "swords")
local ParryGroup = CombatSub:AddLeftGroupbox("Auto Parry", "shield")

ParryGroup:AddToggle("AutoParry", {
	Text = "Enable Auto Parry",
	Default = false,
	Callback = function(v) State.AutoParry = v end,
}):AddKeyPicker("ParryKey", {
	Default = "None", Text = "Parry Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

ParryGroup:AddSlider("DetectionRange", {
	Text = "Detection Range", Default = 15, Min = 1, Max = 50, Rounding = 0,
	Callback = function(v) State.DetectionRange = v end,
})

ParryGroup:AddToggle("EvasiveMode", {
	Text = "Evasive Mode",
	Default = false,
	Callback = function(v) State.EvasiveMode = v end,
})

ParryGroup:AddToggle("EvasiveDirectional", {
	Text = "Evasive Directional",
	Default = false,
	Callback = function(v) State.EvasiveDirectional = v end,
})

ParryGroup:AddToggle("ParryOnly", {
	Text = "Parry Only",
	Default = false,
	Callback = function(v) State.ParryOnly = v end,
})

ParryGroup:AddToggle("PauseM1", {
	Text = "Pause M1 for Parry",
	Default = false,
	Callback = function(v) State.PauseM1ForParry = v end,
})

ParryGroup:AddDropdown("Priority", {
	Values = { "Parry", "Dodge" }, Default = "Parry", Text = "Priority",
	Callback = function(v) State.Priority = v end,
})

ParryGroup:AddSlider("FacingStrictness", {
	Text = "Facing Strictness", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.FacingStrictness = v / 100 end,
})

local CooldownGroup = CombatSub:AddRightGroupbox("Cooldowns & Punish", "clock")

CooldownGroup:AddToggle("NoParryCooldown", {
	Text = "No Parry Cooldown",
	Default = false,
	Risky = true,
	Callback = function(v) State.NoParryCooldown = v end,
})

CooldownGroup:AddToggle("NoDodgeCooldown", {
	Text = "No Dodge Cooldown",
	Default = false,
	Risky = true,
	Callback = function(v) State.NoDodgeCooldown = v end,
})

CooldownGroup:AddToggle("AutoPunish", {
	Text = "Auto Punish",
	Default = false,
	Callback = function(v) State.AutoPunish = v end,
})

CooldownGroup:AddDropdown("PunishMethod", {
	Values = { "M1", "Ability", "Gun" }, Default = "M1", Text = "Punish Method",
	Callback = function(v) State.PunishMethod = v end,
})

CooldownGroup:AddToggle("FlingAura", {
	Text = "Fling Aura",
	Default = false,
	Risky = true,
	Callback = function(v) State.FlingAura = v end,
})

local AntiCCGroup = CombatSub:AddLeftGroupbox("Anti CC", "shield")

AntiCCGroup:AddToggle("NoStun", {
	Text = "No Stun",
	Default = false,
	Risky = true,
	Callback = function(v) State.NoStun = v end,
})

AntiCCGroup:AddToggle("NoRagdoll", {
	Text = "No Ragdoll",
	Default = false,
	Risky = true,
	Callback = function(v) State.NoRagdoll = v end,
})

AntiCCGroup:AddToggle("LagSwitch", {
	Text = "Lag Switch",
	Default = false,
	Risky = true,
	Callback = function(v) State.LagSwitch = v end,
})

AntiCCGroup:AddToggle("DisableGlassesKnocked", {
	Text = "Disable Glasses Knocked",
	Default = false,
	Callback = function(v) State.DisableGlassesKnocked = v end,
})

AntiCCGroup:AddToggle("NoBlurWhenKnocked", {
	Text = "No Blur When Knocked",
	Default = false,
	Callback = function(v) State.NoBlurWhenKnocked = v end,
})

-- ═══════════════════════════════════════════════════════
--  MAIN > TARGETING
-- ═══════════════════════════════════════════════════════
local TargetingSub = MainTab:AddSubTab("Targeting", "target")
local TargetGroup = TargetingSub:AddLeftGroupbox("Target", "crosshair")

TargetGroup:AddToggle("FaceLock", {
	Text = "Face Lock",
	Default = false,
	Callback = function(v) State.FaceLock = v end,
})

TargetGroup:AddToggle("StickyTarget", {
	Text = "Sticky Target",
	Default = false,
	Callback = function(v) State.StickyTarget = v end,
})

local PlayerNames = {}
local function refreshPlayerList()
	PlayerNames = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(PlayerNames, p.Name)
		end
	end
end
refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

TargetGroup:AddDropdown("SelectPlayer", {
	Values = PlayerNames, Default = "", Text = "Select Player",
	Callback = function(v) State.SelectPlayer = v end,
})
TargetGroup:AddButton("Refresh Players", function()
	refreshPlayerList()
	Options.SelectPlayer:Refresh(PlayerNames)
end)

local WhiteGroup = TargetingSub:AddRightGroupbox("Whitelist", "users")

WhiteGroup:AddDropdown("WhitelistAdd", {
	Values = PlayerNames, Default = "", Text = "Add to Whitelist",
	Callback = function(v)
		if v and not table.find(State.WhitelistPlayers, v) then
			table.insert(State.WhitelistPlayers, v)
		end
	end,
})
WhiteGroup:AddButton("Add Selected", function()
	local val = Options.WhitelistAdd.Value
	if val and not table.find(State.WhitelistPlayers, val) then
		table.insert(State.WhitelistPlayers, val)
		Library:Notify({ Title = "Ivory", Description = val .. " whitelisted", Type = "Success", Time = 2 })
	end
end)
WhiteGroup:AddButton("Clear Whitelist", function()
	State.WhitelistPlayers = {}
	Library:Notify({ Title = "Ivory", Description = "Whitelist cleared", Type = "Info", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  MAIN > RHYTHM
-- ═══════════════════════════════════════════════════════
local RhythmSub = MainTab:AddSubTab("Rhythm", "music")
local RhythmGroup = RhythmSub:AddLeftGroupbox("Auto Rhythm", "music")

RhythmGroup:AddToggle("AutoGreen", {
	Text = "Auto Green",
	Default = false,
	Callback = function(v) State.AutoGreen = v end,
})

RhythmGroup:AddSlider("Accuracy", {
	Text = "Accuracy", Default = 95, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.Accuracy = v / 100 end,
})

RhythmGroup:AddToggle("AutoRhythm", {
	Text = "Auto Rhythm",
	Default = false,
	Callback = function(v) State.AutoRhythm = v end,
})

local RhythmSet = RhythmSub:AddRightGroupbox("Rhythm Settings", "sliders")

RhythmSet:AddSlider("RhythmVertical", {
	Text = "Vertical", Default = 0, Min = -50, Max = 50, Rounding = 0,
	Callback = function(v) State.RhythmVertical = v end,
})

RhythmSet:AddSlider("RhythmSmooth", {
	Text = "Smooth Factor", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.RhythmSmooth = v / 100 end,
})

RhythmSet:AddSlider("RhythmAnimSpeed", {
	Text = "Animation Speed", Default = 100, Min = 10, Max = 300, Rounding = 0,
	Callback = function(v) State.RhythmAnimSpeed = v / 100 end,
})

-- ═══════════════════════════════════════════════════════
--  MAIN > VISUALS
-- ═══════════════════════════════════════════════════════
local VisualsSub = MainTab:AddSubTab("Visuals", "eye")
local ESPGroup = VisualsSub:AddLeftGroupbox("Player ESP", "eye")

ESPGroup:AddToggle("ESP Enabled", {
	Text = "Player ESP",
	Default = false,
	Callback = function(v) State.ESP_Enabled = v end,
}):AddKeyPicker("ESPKey", {
	Default = "None", Text = "ESP Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = Color3.fromRGB(140, 110, 220), Title = "ESP Color",
	Callback = function(v) State.ESP_Color = v end,
})

ESPGroup:AddToggle("ESP Box", { Text = "Boxes", Default = true, Callback = function(v) State.ESP_Box = v end })
ESPGroup:AddToggle("ESP Fill", { Text = "Fill", Default = false, Callback = function(v) State.ESP_Fill = v end })
ESPGroup:AddToggle("ESP HeadDot", { Text = "Head Dot", Default = false, Callback = function(v) State.ESP_HeadDot = v end })
ESPGroup:AddToggle("ESP Tracer", { Text = "Tracers", Default = false, Callback = function(v) State.ESP_Tracer = v end })
ESPGroup:AddToggle("ESP HPBar", { Text = "HP Bar", Default = true, Callback = function(v) State.ESP_Health = v end })
ESPGroup:AddToggle("ESP Name", { Text = "Name", Default = true, Callback = function(v) State.ESP_Name = v end })
ESPGroup:AddToggle("ESP Health", { Text = "Health Text", Default = false, Callback = function(v) end })
ESPGroup:AddToggle("ESP Distance", { Text = "Distance", Default = true, Callback = function(v) State.ESP_Distance = v end })

local ESPSet = VisualsSub:AddRightGroupbox("ESP Settings", "sliders")

ESPSet:AddSlider("ESP Fill Transparency", {
	Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.ESP_FillTransparency = v / 100 end,
})
ESPSet:AddSlider("ESP Outline Transparency", {
	Text = "Outline Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.ESP_OutlineTransparency = v / 100 end,
})
ESPSet:AddSlider("ESP MaxDist", {
	Text = "Max Distance", Default = 1500, Min = 50, Max = 2000, Rounding = 0,
	Callback = function(v) State.ESP_MaxDist = v end,
})
ESPSet:AddSlider("ESP FontSize", {
	Text = "Font Size", Default = 14, Min = 8, Max = 32, Rounding = 0,
	Callback = function(v) State.ESP_TextSize = v end,
})
ESPSet:AddSlider("ESP BoxThickness", {
	Text = "Box Thickness", Default = 2, Min = 1, Max = 5, Rounding = 0,
	Callback = function(v) State.ESP_BoxThickness = v end,
})
ESPSet:AddToggle("ESP TeamCheck", { Text = "Team Check", Default = false, Callback = function(v) State.ESP_TeamCheck = v end })

local HighlightSub = VisualsSub:AddSubTab("Highlights", "highlighter")
local HighlightGroup = HighlightSub:AddLeftGroupbox("Highlights", "highlighter")
HighlightGroup:AddToggle("Highlight Enabled", {
	Text = "Enable Highlights", Default = false,
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
HighlightGroup:AddSlider("Highlight Fill", {
	Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.Highlight_FillTransparency = v / 100 end,
})
HighlightGroup:AddSlider("Highlight Outline", {
	Text = "Outline Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end,
})
local HighlightColors = HighlightSub:AddRightGroupbox("Highlight Colors", "palette")
HighlightColors:AddLabel("Highlight Color"):AddColorPicker("HighlightColor", {
	Default = Color3.fromRGB(140, 110, 220), Title = "Highlight",
	Callback = function(v) State.Highlight_Color = v end,
})

-- ═══════════════════════════════════════════════════════
--  MAIN > WORLD
-- ═══════════════════════════════════════════════════════
local WorldSub = MainTab:AddSubTab("World", "globe")
local LightingGroup = WorldSub:AddLeftGroupbox("Lighting", "sun")

LightingGroup:AddToggle("FullBright", {
	Text = "Full Bright", Default = false,
	Callback = function(v)
		State.FullBright = v
		if v then
			Lighting.Brightness = 2
			Lighting.ClockTime = 14
			Lighting.GlobalShadows = false
		else
			Lighting.Brightness = 1
			Lighting.GlobalShadows = true
		end
	end,
})

LightingGroup:AddToggle("NightMode", {
	Text = "Night Mode", Default = false,
	Callback = function(v)
		State.NightMode = v
		if v then Lighting.ClockTime = 0 end
	end,
})

LightingGroup:AddSlider("Ambient R", {
	Text = "Ambient R", Default = 128, Min = 0, Max = 255, Rounding = 0,
	Callback = function(v) State.AmbientR = v end,
})
LightingGroup:AddSlider("Ambient G", {
	Text = "Ambient G", Default = 128, Min = 0, Max = 255, Rounding = 0,
	Callback = function(v) State.AmbientG = v end,
})
LightingGroup:AddSlider("Ambient B", {
	Text = "Ambient B", Default = 128, Min = 0, Max = 255, Rounding = 0,
	Callback = function(v) State.AmbientB = v end,
})
LightingGroup:AddButton("Apply Ambient", function()
	Lighting.Ambient = Color3.fromRGB(State.AmbientR, State.AmbientG, State.AmbientB)
	Library:Notify({ Title = "Ivory", Description = "Ambient applied!", Type = "Success", Time = 2 })
end)

local WorldSet = WorldSub:AddRightGroupbox("Camera & GFX", "camera")

WorldSet:AddSlider("CameraFOV", {
	Text = "Camera FOV", Default = 70, Min = 60, Max = 120, Rounding = 0,
	Callback = function(v)
		State.CameraFOV = v
		pcall(function() Camera.FieldOfView = v end)
	end,
})

WorldSet:AddToggle("LowGFX", {
	Text = "Low GFX", Default = false,
	Callback = function(v)
		State.LowGFX = v
		if v then
			Lighting.GlobalShadows = false
			Lighting.FogEnd = 9e9
			settings().Rendering.QualityLevel = "Level01"
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.Material = Enum.Material.SmoothPlastic
					obj.Reflectance = 0
				elseif obj:IsA("Decal") or obj:IsA("Texture") then
					obj.Transparency = 1
				elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
					obj.Lifetime = NumberRange.new(0)
				elseif obj:IsA("Fire") or obj:IsA("SpotLight") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
					obj.Enabled = false
				end
			end
		end
	end,
})

WorldSet:AddToggle("NoFog", {
	Text = "No Fog", Default = false,
	Callback = function(v)
		State.NoFog = v
		if v then
			Lighting.FogEnd = 999999
			Lighting.FogStart = 0
			pcall(function() Lighting.Atmosphere.Density = 0 end)
		else
			Lighting.FogEnd = 100000
			pcall(function() Lighting.Atmosphere.Density = 0.3 end)
		end
	end,
})

-- ═══════════════════════════════════════════════════════
--  MAIN > MOVEMENT
-- ═══════════════════════════════════════════════════════
local MovementSub = MainTab:AddSubTab("Movement", "move")
local SpeedGroup = MovementSub:AddLeftGroupbox("Speed", "zap")

SpeedGroup:AddToggle("Speedhack", {
	Text = "Speedhack", Default = false,
	Callback = function(v)
		State.SpeedEnabled = v
		if not v then pcall(function() Humanoid.WalkSpeed = 16 end) end
	end,
})
SpeedGroup:AddSlider("Speed", {
	Text = "Speed", Default = 16, Min = 16, Max = 500, Rounding = 0,
	Callback = function(v) State.SpeedValue = v end,
})

local FlyGroup = MovementSub:AddRightGroupbox("Fly", "wind")

FlyGroup:AddToggle("Fly", {
	Text = "Fly", Default = false,
	Callback = function(v) State.FlyEnabled = v end,
})
FlyGroup:AddSlider("FlySpeed", {
	Text = "Fly Speed", Default = 60, Min = 16, Max = 500, Rounding = 0,
	Callback = function(v) State.FlySpeed = v end,
})

local MoveMisc = MovementSub:AddLeftGroupbox("Misc Movement", "arrow-up")

MoveMisc:AddToggle("Infinite Jump", {
	Text = "Infinite Jump", Default = false,
	Callback = function(v) State.InfiniteJump = v end,
})

MoveMisc:AddToggle("Infinite Stamina", {
	Text = "Infinite Stamina", Default = false,
	Callback = function(v) State.InfiniteStamina = v end,
})

MoveMisc:AddToggle("Auto Sprint", {
	Text = "Auto Sprint", Default = false,
	Callback = function(v) State.AutoSprint = v end,
})

MoveMisc:AddToggle("Noclip", {
	Text = "Noclip", Default = false,
	Callback = function(v) State.Noclip = v end,
})

MoveMisc:AddToggle("Click Teleport", {
	Text = "Click Teleport", Default = false,
	Risky = true,
	Callback = function(v) State.ClickTeleport = v end,
})

-- ═══════════════════════════════════════════════════════
--  SETTINGS TAB (always last)
-- ═══════════════════════════════════════════════════════
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

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
MenuGroup:AddButton("Join Discord", function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 }) end)
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
FOVCircle.Color = State.ESP_Color
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
		BoxFill = Drawing.new("Square"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Health = Drawing.new("Line"),
		HealthText = Drawing.new("Text"),
		Tracer = Drawing.new("Line"),
		HeadDot = Drawing.new("Circle"),
	}
	esp.Box.Thickness = State.ESP_BoxThickness
	esp.Box.Filled = false
	esp.BoxFill.Thickness = 1
	esp.BoxFill.Filled = true
	esp.BoxFill.Color = State.ESP_Color
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
	esp.HeadDot.Radius = 3
	esp.HeadDot.Filled = true
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
	if player == LocalPlayer then return end
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
--  TEAM DETECTION
-- ═══════════════════════════════════════════════════════
local function GetTeamKey(player)
	if player.Team then return "team:" .. player.Team.Name end
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
		for _, attr in ipairs({ "Team", "TeamName" }) do
			local v = char:GetAttribute(attr)
			if v then return "cattr:" .. tostring(v) end
		end
		for _, child in ipairs(char:GetChildren()) do
			if child:IsA("ObjectValue") and child.Name:lower():find("team") and child.Value then
				return "cobj:" .. tostring(child.Value)
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

local function isWhitelisted(player)
	return table.find(State.WhitelistPlayers, player.Name) ~= nil
end

local function isPartVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { LocalPlayer.Character, targetPart.Parent }
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(origin, direction, rayParams) == nil
end

-- ═══════════════════════════════════════════════════════
--  TARGETING LOGIC
-- ═══════════════════════════════════════════════════════
local lockedTarget = nil

local function getTargetPlayer()
	if State.StickyTarget and lockedTarget and lockedTarget.Parent and lockedTarget.Character then
		local hum = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then return lockedTarget end
	end
	if State.SelectPlayer ~= "" then
		local target = Players:FindFirstChild(State.SelectPlayer)
		if target and target ~= LocalPlayer and target.Character then return target end
	end
	return nil
end

local function getNearestTarget()
	local closestPlayer = nil
	local closestDist = State.Aimbot_FOV
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(State.Aimbot_TargetPart) then
			if State.Aimbot_TeamCheck and IsTeammate(player) then continue end
			if isWhitelisted(player) then continue end
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
			if isWhitelisted(player) then continue end
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
--  AIMBOT KEYBINDS
-- ═══════════════════════════════════════════════════════
local aimbotKeyDown = false

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then aimbotKeyDown = true end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then aimbotKeyDown = false end
end)

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

	-- Movement
	if State.SpeedEnabled then pcall(function() Humanoid.WalkSpeed = State.SpeedValue end) end
	if State.AutoSprint then pcall(function() Humanoid.WalkSpeed = math.max(Humanoid.WalkSpeed, 20) end) end
	if State.InfiniteStamina then pcall(function()
		local stamina = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Stamina")
		if stamina and stamina:IsA("NumberValue") then stamina.Value = stamina.MaxValue end
		local energy = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Energy")
		if energy and energy:IsA("NumberValue") then energy.Value = energy.MaxValue end
	end) end

	-- Fly
	if State.FlyEnabled then
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
			flyBodyVelocity.Velocity = moveDir.Unit * State.FlySpeed
			flyBodyGyro.CFrame = camCF
		end)
	else
		if flyBodyVelocity then stopFly() end
	end

	-- Noclip
	if State.Noclip then if not noclipConnection then startNoclip() end else if noclipConnection then stopNoclip() end end

	-- No Ragdoll
	if State.NoRagdoll then
		pcall(function()
			for _, v in ipairs(Character:GetDescendants()) do
				if v:IsA("JointInstance") then v:Destroy() end
			end
		end)
	end

	-- No Blur When Knocked
	if State.NoBlurWhenKnocked then
		pcall(function()
			for _, v in ipairs(Lighting:GetChildren()) do
				if v:IsA("BlurEffect") then v.Enabled = false end
			end
			for _, v in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
				if v:IsA("BlurEffect") then v.Enabled = false end
			end
		end)
	end

	-- Camera FOV
	pcall(function() Camera.FieldOfView = State.CameraFOV end)

	-- Night Mode
	if State.NightMode then Lighting.ClockTime = 0 end

	-- Auto Punish (send attack when enemy is in range after parry)
	if State.AutoPunish and State.AutoParry then
		pcall(function()
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
					if not State.Aimbot_TeamCheck or not IsTeammate(player) then
						local dist = (player.Character.HumanoidRootPart.Position - HumanoidRootPart.Position).Magnitude
						if dist <= State.DetectionRange then
							if State.PunishMethod == "M1" then
								VirtualUser:CaptureController()
								VirtualUser:Button1Down(Vector2.new(1280, 672))
							elseif State.PunishMethod == "Ability" then
								VIM:SendKeyEvent(true, "Z", false, game)
								task.wait(0.1)
								VIM:SendKeyEvent(false, "Z", false, game)
							elseif State.PunishMethod == "Gun" then
								VIM:SendKeyEvent(true, "Q", false, game)
								task.wait(0.1)
								VIM:SendKeyEvent(false, "Q", false, game)
							end
						end
					end
				end
			end
		end)
	end

	-- Face Lock
	if State.FaceLock then
		local target = getTargetPlayer()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			pcall(function()
				HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.Position, Vector3.new(target.Character.HumanoidRootPart.Position.X, HumanoidRootPart.Position.Y, target.Character.HumanoidRootPart.Position.Z))
			end)
		end
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

	-- ESP
	for player, esp in pairs(espObjects) do
		local show = State.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0
		if show and State.ESP_TeamCheck and IsTeammate(player) then show = false end
		if show and isWhitelisted(player) then show = false end
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
				esp.Box.Color = State.ESP_Color
				esp.Box.Visible = State.ESP_Box
				-- Fill
				esp.BoxFill.Size = Vector2.new(boxWidth - 2, boxHeight - 2)
				esp.BoxFill.Position = Vector2.new(rootPos.X - (boxWidth - 2) / 2, rootPos.Y - (boxHeight - 2) / 2)
				esp.BoxFill.Color = Color3.new(State.ESP_Color.R, State.ESP_Color.G, State.ESP_Color.B)
				esp.BoxFill.Transparency = State.ESP_FillTransparency
				esp.BoxFill.Visible = State.ESP_Fill
				-- Name
				esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 18)
				esp.Name.Text = player.DisplayName
				esp.Name.Size = State.ESP_TextSize
				esp.Name.Color = State.ESP_Color
				esp.Name.Visible = State.ESP_Name
				-- Distance
				esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 4)
				esp.Distance.Text = math.floor(dist) .. "m"
				esp.Distance.Size = State.ESP_TextSize - 2
				esp.Distance.Color = State.ESP_Color
				esp.Distance.Visible = State.ESP_Distance
				-- Health bar
				esp.Health.From = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2)
				esp.Health.To = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2 - (boxHeight * healthPercent))
				esp.Health.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				esp.Health.Visible = State.ESP_Health
				-- Health text
				esp.HealthText.Position = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2 + 4)
				esp.HealthText.Text = math.floor(hum.Health)
				esp.HealthText.Size = State.ESP_TextSize - 4
				esp.HealthText.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				esp.HealthText.Visible = State.ESP_Health
				-- Tracer
				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
				esp.Tracer.Color = State.ESP_Color
				esp.Tracer.Visible = State.ESP_Tracer
				-- Head dot
				local headScreenPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2, 0))
				esp.HeadDot.Position = Vector2.new(headScreenPos.X, headScreenPos.Y)
				esp.HeadDot.Color = State.ESP_Color
				esp.HeadDot.Visible = State.ESP_HeadDot
			else
				esp.Box.Visible = false esp.BoxFill.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.HealthText.Visible = false esp.Tracer.Visible = false esp.HeadDot.Visible = false
			end
		else
			esp.Box.Visible = false esp.BoxFill.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.HealthText.Visible = false esp.Tracer.Visible = false esp.HeadDot.Visible = false
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

Library:Notify({ Title = "Ivory", Description = "v2.0 loaded successfully", Type = "Success", Time = 3 })
