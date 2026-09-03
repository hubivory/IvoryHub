--// Ivory Hub - Elemental Magic Arena
--// PlaceId: 7243409883
--// Combat pipeline: RempteFolder.Server {skill, Function}
--// Light (WarthofGod): Start = M1, Shoot = projectile rain (no cooldown, client-trusted hitbox)

local genv = getgenv()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlaceId = game.PlaceId

--// ═══════════════════════════════════════════════════════════
--// GAME ANTI-CHEAT BYPASS (kicks on CoreGui names containing "hub")
--// ═══════════════════════════════════════════════════════════

local function disableAnti()
	pcall(function()
		for _, c in ipairs(getconnections(CoreGui.DescendantAdded)) do
			c:Disable()
		end
	end)
	pcall(function()
		for _, c in ipairs(getconnections(CoreGui.ChildAdded)) do
			c:Disable()
		end
	end)
end
disableAnti()
Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	disableAnti()
end)

--// ═══════════════════════════════════════════════════════════
--// UI LIBRARY
--// ═══════════════════════════════════════════════════════════

local Library = nil
local ThemeManager = nil
local SaveManager = nil

local libSrc = genv._IvoryLibSrc
local tmSrc = genv._IvoryTMSrc
local smSrc = genv._IvorySMSrc

if libSrc then
	Library = loadstring(libSrc)()
	ThemeManager = loadstring(tmSrc)()
	SaveManager = loadstring(smSrc)()
	print("[Ivory] Loaded ObsidianUltra from loader cache")
else
	local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
	local function httpGet(url)
		return request({ Url = url, Method = "GET" }).Body
	end
	pcall(function() Library = loadstring(httpGet(repo .. "Library.lua"))() end)
	pcall(function() ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))() end)
	pcall(function() SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))() end)
end

if not Library then
	warn("[Ivory] ObsidianUltra failed to load - aborting")
	return
end

local Options = Library.Options
local Toggles = Library.Toggles

--// ═══════════════════════════════════════════════════════════
--// GAME DATA
--// ═══════════════════════════════════════════════════════════

local CombatRemote = ReplicatedStorage:WaitForChild("RempteFolder"):WaitForChild("Server", 10)

local ElementMenuRemotes = ReplicatedStorage:FindFirstChild("ElementMenuRemotes")
local ConfirmLoadout = ElementMenuRemotes and ElementMenuRemotes:FindFirstChild("ConfirmLoadout")
local RequestSpawn = ElementMenuRemotes and ElementMenuRemotes:FindFirstChild("RequestSpawn")

local ElementConfig = nil
local ElementLabels = {}
local ElementFolders = {}

pcall(function()
	ElementConfig = require(ReplicatedStorage:WaitForChild("ElementConfig", 10))
	if ElementConfig then
		for _, cfg in ipairs(ElementConfig) do
			local label = cfg.name
			if cfg.badge then
				label = label .. " (Gamepass)"
			elseif cfg.diamondCost and cfg.diamondCost > 0 then
				label = label .. " (" .. cfg.diamondCost .. " Diamonds)"
			end
			ElementLabels[#ElementLabels + 1] = label
			ElementFolders[label] = cfg.folder
		end
	end
end)

local CurrentPadIndex = 0

local function DoAutoPick()
	local char = LocalPlayer.Character
	if not char then
		--// Wait for character to spawn
		Library:Notify({ Title = "Ivory", Description = "Waiting for character...", Type = "Info", Time = 3 })
		local waited = 0
		repeat
			task.wait(0.5)
			waited = waited + 0.5
			char = LocalPlayer.Character
		until char or waited > 15
		if not char then
			Library:Notify({ Title = "Ivory", Description = "No character - spawn first", Type = "Error", Time = 3 })
			return
		end
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		Library:Notify({ Title = "Ivory", Description = "No HumanoidRootPart", Type = "Error", Time = 3 })
		return
	end

	local tpsFolder = Workspace:FindFirstChild("TPS")
	if not tpsFolder then
		Library:Notify({ Title = "Ivory", Description = "Could not find TPS folder", Type = "Error", Time = 3 })
		return
	end

	local teleporters = tpsFolder:GetChildren()

	--// Move to next pad
	CurrentPadIndex = CurrentPadIndex + 1
	if CurrentPadIndex > #teleporters then
		CurrentPadIndex = 1
	end

	local pad = teleporters[CurrentPadIndex]
	local ok, err = pcall(function()
		local part = pad
		if pad:IsA("Model") then
			part = pad:FindFirstChild("Part") or pad:FindFirstChildOfClass("BasePart") or pad.PrimaryPart
		end
		if part and part:IsA("BasePart") then
			hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
		end
	end)
	if not ok then
		warn("[Ivory] Pad " .. CurrentPadIndex .. " failed: " .. tostring(err))
	end

	Library:Notify({
		Title = "Ivory",
		Description = "Teleported to pad " .. CurrentPadIndex .. "/" .. #teleporters,
		Type = "Success",
		Time = 3,
	})
end
local function GetWarthofGodModule()
	return ReplicatedStorage:FindFirstChild("MoveSets"):FindFirstChild("Light"):FindFirstChild("WarthofGodClient")
end

local function ApplyHitboxSize(size)
	pcall(function()
		local mod = GetWarthofGodModule()
		if mod and mod:FindFirstChild("Hitboxes") then
			local hb = mod.Hitboxes:FindFirstChild("Hitbox")
			if hb then
				hb.Size = Vector3.new(size, size, size)
			end
		end
	end)
end

local function IsLightSkill()
	local cs = LocalPlayer:FindFirstChild("CurrentSkill")
	return cs and cs.Value == "Light"
end

local isLobby = false
pcall(function()
	isLobby = Workspace:FindFirstChild("Lobby") ~= nil
		or Workspace:FindFirstChild("lobby") ~= nil
		or LocalPlayer.Character == nil
end)

--// ═══════════════════════════════════════════════════════════
--// STATE
--// ═══════════════════════════════════════════════════════════

local State = {
	AutoDiamonds = false,
	AutoSouls = false,
	CollectDelay = 0.4,
	CollectRadius = 0,

	AutoPickOnSpawn = false,
	AutoPickElement = "Light",
	AutoPickPad = 1,
	LockedPad = 0,

	AutoM1 = false,
	M1Delay = 0.5,

	SkillSpam = false,
	SpamDelay = 0.25,
	SpamTarget = "Nearest Enemy",
	HitboxSize = 150,

	AutoBang = false,
	BangDelay = 0.8,
	BangDist = 4,

	WalkSpeedEnabled = false,
	WalkSpeedValue = 40,
	JumpPowerEnabled = false,
	JumpPowerValue = 100,
	InfiniteJump = false,

	Noclip = false,
	FlyEnabled = false,
	FlySpeed = 50,
	AntiKnockback = false,
	NoFallDamage = false,
	AntiAFK = false,

	ESPEnabled = false,
	ESPBox = true,
	ESPName = true,
	ESPDistance = true,
	ESPHealth = true,
	ESPTracer = false,
	ESPTeamCheck = false,
	ESPMaxDist = 1500,
	BoxThickness = 2,
	TextSize = 14,
	ColorBox = Color3.fromRGB(140, 110, 220),
	ColorName = Color3.fromRGB(225, 215, 245),
	ColorDistance = Color3.fromRGB(155, 135, 185),
	ColorTracer = Color3.fromRGB(140, 110, 220),

	ChamsEnabled = false,
	ChamsFill = 50,
	ChamsOutline = 0,
	ChamsColor = Color3.fromRGB(140, 110, 220),
	ChamsSelf = false,
}

--// ═══════════════════════════════════════════════════════════
--// WINDOW
--// ═══════════════════════════════════════════════════════════

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
--// Patch window icon to use custom image
local IVORY_ICON = "rbxassetid://110090697336524"
task.spawn(function()
	task.wait()
	local function trySetIcon(parent)
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("ImageLabel") and obj.Size.X.Offset >= 20 and obj.Size.X.Offset <= 40 and obj.Size.Y.Offset >= 20 and obj.Size.Y.Offset <= 40 then
						local par = obj.Parent
						if par then
							for _, sib in ipairs(par:GetChildren()) do
								if sib:IsA("TextLabel") and sib.Text == "Ivory" then
									obj.Image = IVORY_ICON
									obj.ImageRectOffset = Vector2.new(0, 0)
									obj.ImageRectSize = Vector2.new(0, 0)
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end
	pcall(function() trySetIcon(CoreGui) end)
	pcall(function() trySetIcon(LocalPlayer.PlayerGui) end)
end)

--// ═══════════════════════════════════════════════════════════
--// TABS
--// ═══════════════════════════════════════════════════════════

local MainTab = Window:AddTab({ Name = "Main", Icon = "swords" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "swords" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "swords" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "swords" })

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local AutoSub = MainTab:AddSubTab("Automation", "rbxassetid://110090697336524")
local CombatSub = MainTab:AddSubTab("Combat", "rbxassetid://110090697336524")
local UtilitySub = MainTab:AddSubTab("Utility", "rbxassetid://110090697336524")

--// Automation: Auto Pick
local PickGroup = AutoSub:AddLeftGroupbox("Auto Pick Class", "person-standing")
PickGroup:AddToggle("AutoPickOnSpawn", {
	Text = "Auto Pick On Spawn",
	Default = false,
	Tooltip = "Teleports to the selected pad whenever you're not spawned",
})

PickGroup:AddDropdown("AutoPickPad", {
	Text = "Teleporter Pad",
	Values = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39"},
	Default = "1",
	Tooltip = "Which teleporter pad to use",
	Callback = function(v)
		local idx = tonumber(v)
		local char = LocalPlayer.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local tpsFolder = Workspace:FindFirstChild("TPS")
		if not tpsFolder then return end
		local teleporters = tpsFolder:GetChildren()
		local pad = teleporters[idx]
		if not pad then
			Library:Notify({ Title = "Ivory", Description = "Pad " .. idx .. " not found", Type = "Error", Time = 3 })
			return
		end
		pcall(function()
			local part = pad
			if pad:IsA("Model") then
				part = pad:FindFirstChild("Part") or pad:FindFirstChildOfClass("BasePart") or pad.PrimaryPart
			end
			if part and part:IsA("BasePart") then
				hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
			end
		end)
		State.LockedPad = idx
		Library:Notify({ Title = "Ivory", Description = "Teleported to pad " .. idx, Type = "Success", Time = 3 })
	end,
})

--// Automation: Collectibles
local CollectGroup = AutoSub:AddLeftGroupbox("Collectibles", "gem")
CollectGroup:AddToggle("AutoDiamonds", {
	Text = "Auto Collect Diamonds",
	Default = false,
	Tooltip = "Teleports to the nearest diamond",
})
CollectGroup:AddToggle("AutoSouls", {
	Text = "Auto Collect Souls",
	Default = false,
	Tooltip = "Teleports to dropped souls",
})
CollectGroup:AddSlider("CollectDelay", {
	Text = "Collect Delay",
	Default = 0.4,
	Min = 0.05,
	Max = 2,
	Rounding = 2,
	Suffix = "s",
})
CollectGroup:AddSlider("CollectRadius", {
	Text = "Collect Radius",
	Default = 0,
	Min = 0,
	Max = 2000,
	Rounding = 0,
	Suffix = " (0 = inf)",
})

--// Automation: Farming
local FarmGroup = AutoSub:AddRightGroupbox("Farming", "zap")
FarmGroup:AddToggle("AutoM1", {
	Text = "Auto M1",
	Default = false,
	Tooltip = "Fires the legit M1 on cooldown (10s server cooldown)",
})
FarmGroup:AddSlider("M1Delay", {
	Text = "M1 Interval",
	Default = 0.5,
	Min = 0.1,
	Max = 11,
	Rounding = 1,
	Suffix = "s",
})

--// Combat: Skill spam
local SpamGroup = CombatSub:AddLeftGroupbox("Skill Spam", "swords")
SpamGroup:AddToggle("SkillSpam", {
	Text = "Skill Spam",
	Default = false,
	Tooltip = "Rains WarthofGod arrows at the target - no cooldown bypass",
})
SpamGroup:AddSlider("SpamDelay", {
	Text = "Spam Interval",
	Default = 0.25,
	Min = 0.05,
	Max = 2,
	Rounding = 2,
	Suffix = "s",
})
SpamGroup:AddDropdown("SpamTarget", {
	Text = "Target",
	Values = { "Nearest Enemy", "Self (Defense)" },
	Default = "Nearest Enemy",
})
SpamGroup:AddSlider("HitboxSize", {
	Text = "Hitbox Size",
	Default = 150,
	Min = 32,
	Max = 400,
	Rounding = 0,
	Tooltip = "Size of the client-trusted hitbox (32 = legit)",
	Callback = function(v)
		ApplyHitboxSize(v)
	end,
})

--// Combat: Bang
local BangGroup = CombatSub:AddRightGroupbox("Bang", "target")
local BangToggle = BangGroup:AddToggle("AutoBang", {
	Text = "Auto Bang",
	Default = false,
	Tooltip = "Keeps teleporting behind the nearest enemy",
})
BangToggle:AddKeyPicker("BangKeybind", {
	Default = "V",
	Text = "Bang keybind",
	Mode = "Toggle",
	SyncToggleState = true,
})
BangGroup:AddSlider("BangDelay", {
	Text = "Bang Interval",
	Default = 0.8,
	Min = 0.1,
	Max = 5,
	Rounding = 2,
	Suffix = "s",
})
BangGroup:AddSlider("BangDist", {
	Text = "Distance Behind",
	Default = 4,
	Min = 1,
	Max = 15,
	Rounding = 0,
})

--// Utility
local UtilGroup = UtilitySub:AddLeftGroupbox("Server", "globe")
UtilGroup:AddToggle("AntiAFK", { Text = "Anti AFK", Default = false })
UtilGroup:AddButton("Rejoin", function()
	pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
end)
UtilGroup:AddButton("Server Hop", function()
	pcall(function()
		local servers = HttpService:JSONDecode(request({
			Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET",
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

local ExtraGroup = UtilitySub:AddRightGroupbox("Protection", "shield")
ExtraGroup:AddToggle("AntiKnockback", {
	Text = "Anti Knockback",
	Default = false,
	Tooltip = "Instantly clears PlatformStand stuns",
})
ExtraGroup:AddToggle("NoFallDamage", {
	Text = "No Fall Damage",
	Default = false,
})

--// ═══════════════════════════════════════════════════════════
--// PLAYER TAB
--// ═══════════════════════════════════════════════════════════

local MoveSub = PlayerTab:AddSubTab("Movement", "rbxassetid://110090697336524")
local MiscSub = PlayerTab:AddSubTab("Misc", "rbxassetid://110090697336524")

local SpeedGroup = MoveSub:AddLeftGroupbox("Speed", "zap")
SpeedGroup:AddToggle("WalkSpeedEnabled", {
	Text = "Enable Walk Speed",
	Default = false,
	Callback = function(v)
		State.WalkSpeedEnabled = v
		if not v then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end) end
	end,
})
SpeedGroup:AddSlider("WalkSpeedValue", {
	Text = "Walk Speed",
	Default = 40,
	Min = 16,
	Max = 200,
	Rounding = 0,
})

local JumpGroup = MoveSub:AddRightGroupbox("Jump", "arrow-up")
JumpGroup:AddToggle("JumpPowerEnabled", {
	Text = "Enable Jump Power",
	Default = false,
	Callback = function(v)
		State.JumpPowerEnabled = v
		if not v then pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end) end
	end,
})
JumpGroup:AddSlider("JumpPowerValue", {
	Text = "Jump Power",
	Default = 100,
	Min = 50,
	Max = 300,
	Rounding = 0,
})
JumpGroup:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false })

local ModsGroup = MiscSub:AddLeftGroupbox("Player Mods", "user")
ModsGroup:AddToggle("Noclip", { Text = "Noclip", Default = false })

local FlyGroup = MiscSub:AddRightGroupbox("Fly", "wind")
FlyGroup:AddToggle("FlyEnabled", { Text = "Enable Fly", Default = false })
FlyGroup:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 50,
	Min = 10,
	Max = 200,
	Rounding = 0,
})

--// ═══════════════════════════════════════════════════════════
--// VISUALS TAB
--// ═══════════════════════════════════════════════════════════

local ESPSub = VisualsTab:AddSubTab("ESP", "rbxassetid://110090697336524")
local ChamsSub = VisualsTab:AddSubTab("Chams", "rbxassetid://110090697336524")

local ESPControls = ESPSub:AddLeftGroupbox("ESP", "eye")
ESPControls:AddToggle("ESPEnabled", { Text = "Enable ESP", Default = false })
ESPControls:AddToggle("ESPBox", { Text = "Show Box", Default = true })
ESPControls:AddToggle("ESPName", { Text = "Show Name", Default = true })
ESPControls:AddToggle("ESPDistance", { Text = "Show Distance", Default = true })
ESPControls:AddToggle("ESPHealth", { Text = "Show Health Bar", Default = true })
ESPControls:AddToggle("ESPTracer", { Text = "Show Tracer", Default = false })
ESPControls:AddToggle("ESPTeamCheck", { Text = "Team Check", Default = false })
ESPControls:AddSlider("ESPMaxDist", {
	Text = "Max Distance",
	Default = 1500,
	Min = 100,
	Max = 5000,
	Rounding = 0,
})

local ESPStyle = ESPSub:AddRightGroupbox("ESP Style", "sliders")
ESPStyle:AddSlider("BoxThickness", {
	Text = "Box Thickness",
	Default = 2,
	Min = 1,
	Max = 5,
	Rounding = 0,
})
ESPStyle:AddSlider("TextSize", {
	Text = "Text Size",
	Default = 14,
	Min = 10,
	Max = 24,
	Rounding = 0,
})

local ESPColors = ESPSub:AddLeftGroupbox("ESP Colors", "palette")
ESPColors:AddLabel("Box Color"):AddColorPicker("ColorBox", {
	Default = Color3.fromRGB(140, 110, 220),
	Title = "Box",
})
ESPColors:AddLabel("Name Color"):AddColorPicker("ColorName", {
	Default = Color3.fromRGB(225, 215, 245),
	Title = "Name",
})
ESPColors:AddLabel("Distance Color"):AddColorPicker("ColorDistance", {
	Default = Color3.fromRGB(155, 135, 185),
	Title = "Distance",
})
ESPColors:AddLabel("Tracer Color"):AddColorPicker("ColorTracer", {
	Default = Color3.fromRGB(140, 110, 220),
	Title = "Tracer",
})

local ChamsGroup = ChamsSub:AddLeftGroupbox("Chams", "highlighter")
ChamsGroup:AddToggle("ChamsEnabled", {
	Text = "Enable Chams",
	Default = false,
	Tooltip = "See players through walls",
})
ChamsGroup:AddToggle("ChamsSelf", { Text = "Highlight Yourself", Default = false })
ChamsGroup:AddSlider("ChamsFill", {
	Text = "Fill Transparency",
	Default = 50,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
})
ChamsGroup:AddSlider("ChamsOutline", {
	Text = "Outline Transparency",
	Default = 0,
	Min = 0,
	Max = 100,
	Rounding = 0,
	Suffix = "%",
})

local ChamsColors = ChamsSub:AddRightGroupbox("Chams Colors", "palette")
ChamsColors:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {
	Default = Color3.fromRGB(140, 110, 220),
	Title = "Chams",
})

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
local CreditGroup = SettingsTab:AddLeftGroupbox("Credits", "heart")
local CreditLabel = CreditGroup:AddLabel({ Text = "", Size = 26, DoesWrap = true })
local CreditTL = CreditLabel.TextLabel
CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
CreditTL.Font = Enum.Font.GothamBold
CreditTL.TextSize = 26

task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddButton("Test Notification", function()
	Library:Notify({ Title = "Ivory", Description = "This is a test notification!", Type = "Info", Time = 3 })
end)
MenuGroup:AddDropdown("NotifySide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value) Library.NotifySide = Value end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value) Library:SetDPIScale(tonumber(Value:gsub("%%", ""))) end,
})
MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = 4,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value) Window:SetCornerRadius(value) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})
MenuGroup:AddButton("Join Discord", function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 }) end)
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)
Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

--// ═══════════════════════════════════════════════════════════
--// HELPERS
--// ═══════════════════════════════════════════════════════════

local function GetHRP()
	local c = LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function GetNearestEnemyHRP(maxDist)
	local myRoot = GetHRP()
	if not myRoot then return nil end
	local best, bestDist
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChild("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local d = (hrp.Position - myRoot.Position).Magnitude
				if d <= maxDist and (not bestDist or d < bestDist) then
					best, bestDist = hrp, d
				end
			end
		end
	end
	return best
end

local function DoBang()
	pcall(function()
		local myRoot = GetHRP()
		if not myRoot then return end
		local target = GetNearestEnemyHRP(math.huge)
		if not target then return end
		local behind = target.Position - target.CFrame.LookVector * State.BangDist
		myRoot.CFrame = CFrame.lookAt(behind + Vector3.new(0, 0, 0), target.Position)
	end)
end

--// ═══════════════════════════════════════════════════════════
--// COMBAT (WarthofGod payload)
--// ═══════════════════════════════════════════════════════════

local CombatPayloadReady = false
local WGModule = nil
local WGProjectiles = nil
local WGOriginalSize = nil

task.spawn(function()
	if not CombatRemote then
		warn("[Ivory] Combat remote missing - combat features disabled")
		return
	end
	local ok = pcall(function()
		local mod = GetWarthofGodModule()
		if mod then
			WGModule = mod
			WGProjectiles = mod:FindFirstChild("projectiles")
			local hb = mod:FindFirstChild("Hitboxes") and mod.Hitboxes:FindFirstChild("Hitbox")
			if WGProjectiles and hb then
				CombatPayloadReady = true
				WGOriginalSize = hb.Size
			end
		end
	end)
	if not ok or not CombatPayloadReady then
		warn("[Ivory] WarthofGod module missing - combat features disabled")
	else
		task.wait(1)
		ApplyHitboxSize(State.HitboxSize)
	end
end)

local function DoAutoM1()
	if not CombatRemote or not IsLightSkill() then return end
	pcall(function()
		CombatRemote:FireServer({ skill = "WarthofGod", Function = "Start" })
	end)
end

local function DoSkillSpam()
	if not CombatRemote or not CombatPayloadReady or not IsLightSkill() then return end
	pcall(function()
		local myRoot = GetHRP()
		if not myRoot then return end

		local targetPos
		if State.SpamTarget == "Nearest Enemy" then
			local enemy = GetNearestEnemyHRP(500)
			targetPos = enemy and enemy.Position or (myRoot.Position + myRoot.CFrame.LookVector * 30)
		else
			targetPos = myRoot.Position
		end

		-- Server trusts the sent hitbox: send the ORIGINAL part (resized by the Hitbox Size slider)
		CombatRemote:FireServer(
			{ skill = "WarthofGod", Function = "Shoot" },
			WGModule.Hitboxes.Hitbox,
			CFrame.new(targetPos),
			WGProjectiles,
			WGModule
		)
	end)
end

--// ═══════════════════════════════════════════════════════════
--// AUTO PICK LOOP
--// ═══════════════════════════════════════════════════════════

local lastAutoPick = 0

local function TeleportToPad()
	local padIndex = tonumber(Options.AutoPickPad and Options.AutoPickPad.Value or State.LockedPad or 1)
	local tpsFolder = Workspace:FindFirstChild("TPS")
	if not tpsFolder or not padIndex then return end
	local teleporters = tpsFolder:GetChildren()
	local pad = teleporters[padIndex]
	if not pad then return end

	local char = LocalPlayer.Character
	if not char then
		local waited = 0
		repeat
			task.wait(0.5)
			waited = waited + 0.5
			char = LocalPlayer.Character
		until char or waited > 10
	end
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local part = pad
	if pad:IsA("Model") then
		part = pad:FindFirstChild("Part") or pad:FindFirstChildOfClass("BasePart") or pad.PrimaryPart
	end
	if not part or not part:IsA("BasePart") then return end

	hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0)
	Library:Notify({
		Title = "Ivory",
		Description = "Auto teleported to pad " .. padIndex,
		Type = "Success",
		Time = 3,
	})
end

--// Trigger on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
	if not State.AutoPickOnSpawn then return end
	if os.clock() - lastAutoPick < 3 then return end
	lastAutoPick = os.clock()
	task.wait(1)
	TeleportToPad()
end)

task.spawn(function()
	task.wait(4)
	while true do
		task.wait(2)
		if State.AutoPickOnSpawn then
			local char = LocalPlayer.Character
			if not char then
				if os.clock() - lastAutoPick > 5 then
					lastAutoPick = os.clock()
					TeleportToPad()
				end
			else
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health <= 0 and os.clock() - lastAutoPick > 5 then
					lastAutoPick = os.clock()
					TeleportToPad()
				end
			end
		end
	end
end)

--// ═══════════════════════════════════════════════════════════
--// AUTO COLLECT
--// ═══════════════════════════════════════════════════════════

local CollectibleDiamonds = { "Diamond", "DiamondDrop" }
local CollectibleSouls = { "Soul" }
local CollectBlacklist = {}

local function IsStatueOrDecoration(obj)
	local anc = obj.Parent
	while anc and anc ~= Workspace do
		if anc:IsA("Model") and anc:FindFirstChildOfClass("Humanoid") then
			return true
		end
		anc = anc.Parent
	end
	return false
end

local function FindNearestCollectible(names, requireDirectChild)
	local myRoot = GetHRP()
	if not myRoot then return nil end
	local now = os.clock()
	local best, bestDist
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and table.find(names, obj.Name) and obj.Transparency < 0.9 then
			-- Only real drops: skip lobby/shop decorations and statues.
			-- Diamonds must be direct workspace children (platform drops).
			if IsStatueOrDecoration(obj) then continue end
			if requireDirectChild and obj.Parent ~= Workspace then continue end
			local skip = CollectBlacklist[obj]
			if not (skip and skip.skipUntil > now) then
				local d = (obj.Position - myRoot.Position).Magnitude
				if State.CollectRadius <= 0 or d <= State.CollectRadius then
					if not bestDist or d < bestDist then
						best, bestDist = obj, d
					end
				end
			end
		end
	end
	return best
end

task.spawn(function()
	while true do
		task.wait(State.CollectDelay)
		pcall(function()
			if not (State.AutoDiamonds or State.AutoSouls) then return end
			local myRoot = GetHRP()
			if not myRoot then return end

			local target
			if State.AutoDiamonds and State.AutoSouls then
				local dia = FindNearestCollectible(CollectibleDiamonds, true)
				local soul = FindNearestCollectible(CollectibleSouls, false)
				local myPos = myRoot.Position
				local dD = dia and (dia.Position - myPos).Magnitude or math.huge
				local dS = soul and (soul.Position - myPos).Magnitude or math.huge
				target = dD <= dS and dia or soul
			elseif State.AutoDiamonds then
				target = FindNearestCollectible(CollectibleDiamonds, true)
			elseif State.AutoSouls then
				target = FindNearestCollectible(CollectibleSouls, false)
			end

			if target and target.Parent then
				-- Stuck protection: if we keep landing on the same uncollectible part, skip it a while
				local entry = CollectBlacklist[target]
				if not entry then
					entry = { attempts = 0, skipUntil = 0 }
					CollectBlacklist[target] = entry
				end
				entry.attempts = entry.attempts + 1
				if entry.attempts > 6 then
					entry.skipUntil = os.clock() + 20
					entry.attempts = 0
				end
				myRoot.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
			end
		end)
	end
end)

--// ═══════════════════════════════════════════════════════════
--// BANG LOOP
--// ═══════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(State.BangDelay)
		if State.AutoBang then
			DoBang()
		end
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	pcall(function()
		local kp = Options.BangKeybind
		if kp and kp.Value and typeof(kp.Value) == "string" and kp.Value ~= "None" and kp.Value ~= "Unknown" then
			if input.KeyCode == Enum.KeyCode[kp.Value] then
				DoBang()
			end
		end
	end)
end)

--// ═══════════════════════════════════════════════════════════
--// COMBAT LOOPS
--// ═══════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(State.M1Delay)
		if State.AutoM1 then
			DoAutoM1()
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(State.SpamDelay)
		if State.SkillSpam then
			DoSkillSpam()
		end
	end
end)

--// ═══════════════════════════════════════════════════════════
--// MOVEMENT
--// ═══════════════════════════════════════════════════════════

UserInputService.JumpRequest:Connect(function()
	if State.InfiniteJump then
		pcall(function()
			local hum = GetHum()
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
end)

local flyBodyVelocity, flyBodyGyro
local noclipConnection

local function StartFly()
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

local function StopFly()
	pcall(function()
		if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
		if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
	end)
end

local function StartNoclip()
	noclipConnection = RunService.Stepped:Connect(function()
		pcall(function()
			for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end)
end

local function StopNoclip()
	if noclipConnection then noclipConnection:Disconnect() noclipConnection = nil end
end

--// ═══════════════════════════════════════════════════════════
--// ESP
--// ═══════════════════════════════════════════════════════════

local espObjects = {}

local function CreateESP(player)
	if player == LocalPlayer then return end
	local ok, esp = pcall(function()
		return {
			Box = Drawing.new("Square"),
			Name = Drawing.new("Text"),
			Distance = Drawing.new("Text"),
			Health = Drawing.new("Line"),
			Tracer = Drawing.new("Line"),
		}
	end)
	if not ok then
		espObjects[player] = { Box = false, Name = false, Distance = false, Health = false, Tracer = false }
		return
	end
	espObjects[player] = esp
	pcall(function()
		if not esp.Box then return end
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
	end)
end

local function RemoveESP(player)
	if espObjects[player] then
		pcall(function()
			for _, obj in pairs(espObjects[player]) do
				if obj and obj ~= false then obj:Remove() end
			end
		end)
		espObjects[player] = nil
	end
end

for _, player in ipairs(Players:GetPlayers()) do CreateESP(player) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

--// ═══════════════════════════════════════════════════════════
--// CHAMS
--// ═══════════════════════════════════════════════════════════

local function ApplyChams(player)
	if player == LocalPlayer and not State.ChamsSelf then return end
	if not player.Character then return end
	local hl = player.Character:FindFirstChild("IvoryHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "IvoryHighlight"
		hl.Parent = player.Character
	end
	hl.FillColor = State.ChamsColor
	hl.OutlineColor = State.ChamsColor
	hl.Adornee = player.Character
	hl.FillTransparency = State.ChamsFill / 100
	hl.OutlineTransparency = State.ChamsOutline / 100
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled = State.ChamsEnabled
end

local function RemoveChams(player)
	if player.Character then
		local hl = player.Character:FindFirstChild("IvoryHighlight")
		if hl then hl:Destroy() end
	end
end

--// ═══════════════════════════════════════════════════════════
--// MAIN LOOP
--// ═══════════════════════════════════════════════════════════

local function SyncState()
	pcall(function()
		for name, toggle in pairs(Toggles) do
			if State[name] ~= nil and toggle.Value ~= nil and typeof(toggle.Value) ~= "table" then
				State[name] = toggle.Value
			end
		end
		for name, opt in pairs(Options) do
			if State[name] ~= nil and opt.Value ~= nil and typeof(opt.Value) ~= "table" then
				State[name] = opt.Value
			end
		end
	end)
end

RunService.RenderStepped:Connect(function()
	Camera = Workspace.CurrentCamera
	SyncState()

	pcall(function()
		local hum = GetHum()
		if hum then
			if State.WalkSpeedEnabled then hum.WalkSpeed = State.WalkSpeedValue end
			if State.JumpPowerEnabled then hum.JumpPower = State.JumpPowerValue end
			if State.NoFallDamage then
				hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				if hum.FloorMaterial == Enum.Material.Air then
					hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				end
			end
			if State.AntiKnockback and hum.PlatformStand then
				hum.PlatformStand = false
			end
		end
	end)

	if State.FlyEnabled then
		if not flyBodyVelocity then StartFly() end
		pcall(function()
			local hrp = GetHRP()
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
				flyBodyVelocity.Velocity = moveDir.Unit * State.FlySpeed
			else
				flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
			end
			flyBodyGyro.CFrame = camCF
		end)
	else
		if flyBodyVelocity then StopFly() end
	end

	if State.Noclip then
		if not noclipConnection then StartNoclip() end
	else
		if noclipConnection then StopNoclip() end
	end

	for player, esp in pairs(espObjects) do
		local show = State.ESPEnabled
			and player.Character
			and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character:FindFirstChild("Humanoid")
			and player.Character.Humanoid.Health > 0
		if State.ChamsEnabled then
			ApplyChams(player)
		else
			RemoveChams(player)
		end
		if not esp.Box then continue end
		if show and (not State.ESPTeamCheck or not player.Team or player.Team ~= LocalPlayer.Team) then
			local hrp = player.Character.HumanoidRootPart
			local hum = player.Character.Humanoid
			local rootPos = Camera:WorldToViewportPoint(hrp.Position)
			if rootPos.Z > 0 and rootPos.Z <= State.ESPMaxDist then
				local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
				local boxHeight = math.abs(rootPos.Y - headPos.Y) * 2.2
				local boxWidth = boxHeight * 0.65
				local healthPercent = hum.Health / hum.MaxHealth
				esp.Box.Size = Vector2.new(boxWidth, boxHeight)
				esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
				esp.Box.Thickness = State.BoxThickness
				esp.Box.Color = State.ColorBox
				esp.Box.Visible = State.ESPBox
				esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 18)
				esp.Name.Text = player.DisplayName
				esp.Name.Size = State.TextSize
				esp.Name.Color = State.ColorName
				esp.Name.Visible = State.ESPName
				esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 4)
				esp.Distance.Text = math.floor(rootPos.Z) .. "m"
				esp.Distance.Size = State.TextSize - 2
				esp.Distance.Color = State.ColorDistance
				esp.Distance.Visible = State.ESPDistance
				esp.Health.From = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2)
				esp.Health.To = Vector2.new(rootPos.X - boxWidth / 2 - 4, rootPos.Y + boxHeight / 2 - (boxHeight * healthPercent))
				esp.Health.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
				esp.Health.Visible = State.ESPHealth
				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
				esp.Tracer.Color = State.ColorTracer
				esp.Tracer.Visible = State.ESPTracer
			else
				esp.Box.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.Tracer.Visible = false
			end
		else
			esp.Box.Visible = false esp.Name.Visible = false esp.Distance.Visible = false esp.Health.Visible = false esp.Tracer.Visible = false
		end
	end
end)

--// ═══════════════════════════════════════════════════════════
--// ANTI AFK
--// ═══════════════════════════════════════════════════════════

task.spawn(function()
	while true do
		task.wait(60)
		if State.AntiAFK then
			pcall(function() VirtualUser:CaptureController() end)
			pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
		end
	end
end)

--// ═══════════════════════════════════════════════════════════
--// UNLOAD
--// ═══════════════════════════════════════════════════════════

Library:OnUnload(function()
	StopFly()
	StopNoclip()
	if WGOriginalSize then ApplyHitboxSize(WGOriginalSize.X) end
	for player in pairs(espObjects) do RemoveESP(player) end
	for _, player in ipairs(Players:GetPlayers()) do RemoveChams(player) end
	pcall(function()
		local hum = GetHum()
		if hum then
			hum.WalkSpeed = 16
			hum.JumpPower = 50
		end
	end)
end)

Library:Notify({
	Title = "Ivory",
	Description = "Elemental Magic Arena loaded. RightShift to toggle menu.",
	Type = "Success",
	Time = 3,
})

print("[Ivory] Elemental Magic Arena loaded!")
