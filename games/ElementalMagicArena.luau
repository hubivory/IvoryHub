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

local LIB_SRC = httpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua")
if not LIB_SRC or #LIB_SRC == 0 then
	error("[Ivory] Failed to fetch library. Check HTTP support.")
end
local Library = loadstring(LIB_SRC)()
if not Library then
	error("[Ivory] Failed to compile library")
end

if not Library then
	warn("[Ivory] Ivory Hub failed to load - aborting")
	return
end

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
		Library.Notify({ Title = "Ivory", Content = "Waiting for character...", Type = "Info", Duration = 3 })
		local waited = 0
		repeat
			task.wait(0.5)
			waited = waited + 0.5
			char = LocalPlayer.Character
		until char or waited > 15
		if not char then
			Library.Notify({ Title = "Ivory", Content = "No character - spawn first", Type = "Error", Duration = 3 })
			return
		end
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		Library.Notify({ Title = "Ivory", Content = "No HumanoidRootPart", Type = "Error", Duration = 3 })
		return
	end

	local tpsFolder = Workspace:FindFirstChild("TPS")
	if not tpsFolder then
		Library.Notify({ Title = "Ivory", Content = "Could not find TPS folder", Type = "Error", Duration = 3 })
		return
	end

	local teleporters = tpsFolder:GetChildren()

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

	Library.Notify({
		Title = "Ivory",
		Content = "Teleported to pad " .. CurrentPadIndex .. "/" .. #teleporters,
		Type = "Success",
		Duration = 3,
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

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 460,
	Height = 360,
})

--// ═══════════════════════════════════════════════════════════
--// TABS
--// ═══════════════════════════════════════════════════════════

local MainTab = Window:CreateTab({ Name = "Main" })
local PlayerTab = Window:CreateTab({ Name = "Player" })
local VisualsTab = Window:CreateTab({ Name = "Visuals" })
local SettingsTab = Window:CreateTab({ Name = "Settings" })

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local AutoSub = MainTab:CreateSection("Automation")
local CombatSub = MainTab:CreateSection("Combat")
local UtilitySub = MainTab:CreateSection("Utility")

--// Automation: Auto Pick
local PickGroup = AutoSub:CreateSection("Auto Pick Class")
PickGroup:CreateToggle({
	Name = "Auto Pick On Spawn",
	CurrentValue = false,
})

PickGroup:CreateDropdown({
	Name = "Teleporter Pad",
	Options = {"1","2","3","4","5","6","7","8","9","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31","32","33","34","35","36","37","38","39"},
	CurrentOption = "1",
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
			Library.Notify({ Title = "Ivory", Content = "Pad " .. idx .. " not found", Type = "Error", Duration = 3 })
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
		Library.Notify({ Title = "Ivory", Content = "Teleported to pad " .. idx, Type = "Success", Duration = 3 })
	end,
})

--// Automation: Collectibles
local CollectGroup = AutoSub:CreateSection("Collectibles")
CollectGroup:CreateToggle({
	Name = "Auto Collect Diamonds",
	CurrentValue = false,
})
CollectGroup:CreateToggle({
	Name = "Auto Collect Souls",
	CurrentValue = false,
})
CollectGroup:CreateSlider({
	Name = "Collect Delay",
	Range = {0.05, 2},
	Increment = 0.01,
	CurrentValue = 0.4,
})
CollectGroup:CreateSlider({
	Name = "Collect Radius",
	Range = {0, 2000},
	Increment = 1,
	CurrentValue = 0,
})

--// Automation: Farming
local FarmGroup = AutoSub:CreateSection("Farming")
FarmGroup:CreateToggle({
	Name = "Auto M1",
	CurrentValue = false,
})
FarmGroup:CreateSlider({
	Name = "M1 Interval",
	Range = {0.1, 11},
	Increment = 0.1,
	CurrentValue = 0.5,
})

--// Combat: Skill spam
local SpamGroup = CombatSub:CreateSection("Skill Spam")
SpamGroup:CreateToggle({
	Name = "Skill Spam",
	CurrentValue = false,
})
SpamGroup:CreateSlider({
	Name = "Spam Interval",
	Range = {0.05, 2},
	Increment = 0.01,
	CurrentValue = 0.25,
})
SpamGroup:CreateDropdown({
	Name = "Target",
	Options = { "Nearest Enemy", "Self (Defense)" },
	CurrentOption = "Nearest Enemy",
})
SpamGroup:CreateSlider({
	Name = "Hitbox Size",
	Range = {32, 400},
	Increment = 1,
	CurrentValue = 150,
	Callback = function(v)
		ApplyHitboxSize(v)
	end,
})

--// Combat: Bang
local BangGroup = CombatSub:CreateSection("Bang")
BangGroup:CreateToggle({
	Name = "Auto Bang",
	CurrentValue = false,
})
BangGroup:CreateKeybind({
	Name = "Bang keybind",
	CurrentKeybind = "V",
})
BangGroup:CreateSlider({
	Name = "Bang Interval",
	Range = {0.1, 5},
	Increment = 0.01,
	CurrentValue = 0.8,
})
BangGroup:CreateSlider({
	Name = "Distance Behind",
	Range = {1, 15},
	Increment = 1,
	CurrentValue = 4,
})

--// Utility
local UtilGroup = UtilitySub:CreateSection("Server")
UtilGroup:CreateToggle({
	Name = "Anti AFK",
	CurrentValue = false,
})
UtilGroup:CreateButton({ Name = "Rejoin", Callback = function()
	pcall(function() TeleportService:Teleport(PlaceId, LocalPlayer) end)
end })
UtilGroup:CreateButton({ Name = "Server Hop", Callback = function()
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
end })

local ExtraGroup = UtilitySub:CreateSection("Protection")
ExtraGroup:CreateToggle({
	Name = "Anti Knockback",
	CurrentValue = false,
})
ExtraGroup:CreateToggle({
	Name = "No Fall Damage",
	CurrentValue = false,
})

--// ═══════════════════════════════════════════════════════════
--// PLAYER TAB
--// ═══════════════════════════════════════════════════════════

local MoveSub = PlayerTab:CreateSection("Movement")
local MiscSub = PlayerTab:CreateSection("Misc")

local SpeedGroup = MoveSub:CreateSection("Speed")
SpeedGroup:CreateToggle({
	Name = "Enable Walk Speed",
	CurrentValue = false,
	Callback = function(v)
		State.WalkSpeedEnabled = v
		if not v then pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end) end
	end,
})
SpeedGroup:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 200},
	Increment = 1,
	CurrentValue = 40,
})

local JumpGroup = MoveSub:CreateSection("Jump")
JumpGroup:CreateToggle({
	Name = "Enable Jump Power",
	CurrentValue = false,
	Callback = function(v)
		State.JumpPowerEnabled = v
		if not v then pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end) end
	end,
})
JumpGroup:CreateSlider({
	Name = "Jump Power",
	Range = {50, 300},
	Increment = 1,
	CurrentValue = 100,
})
JumpGroup:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
})

local ModsGroup = MiscSub:CreateSection("Player Mods")
ModsGroup:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
})

local FlyGroup = MiscSub:CreateSection("Fly")
FlyGroup:CreateToggle({
	Name = "Enable Fly",
	CurrentValue = false,
})
FlyGroup:CreateSlider({
	Name = "Fly Speed",
	Range = {10, 200},
	Increment = 1,
	CurrentValue = 50,
})

--// ═══════════════════════════════════════════════════════════
--// VISUALS TAB
--// ═══════════════════════════════════════════════════════════

local ESPSub = VisualsTab:CreateSection("ESP")
local ChamsSub = VisualsTab:CreateSection("Chams")

local ESPControls = ESPSub:CreateSection("ESP")
ESPControls:CreateToggle({
	Name = "Enable ESP",
	CurrentValue = false,
})
ESPControls:CreateToggle({
	Name = "Show Box",
	CurrentValue = true,
})
ESPControls:CreateToggle({
	Name = "Show Name",
	CurrentValue = true,
})
ESPControls:CreateToggle({
	Name = "Show Distance",
	CurrentValue = true,
})
ESPControls:CreateToggle({
	Name = "Show Health Bar",
	CurrentValue = true,
})
ESPControls:CreateToggle({
	Name = "Show Tracer",
	CurrentValue = false,
})
ESPControls:CreateToggle({
	Name = "Team Check",
	CurrentValue = false,
})
ESPControls:CreateSlider({
	Name = "Max Distance",
	Range = {100, 5000},
	Increment = 1,
	CurrentValue = 1500,
})

local ESPStyle = ESPSub:CreateSection("ESP Style")
ESPStyle:CreateSlider({
	Name = "Box Thickness",
	Range = {1, 5},
	Increment = 1,
	CurrentValue = 2,
})
ESPStyle:CreateSlider({
	Name = "Text Size",
	Range = {10, 24},
	Increment = 1,
	CurrentValue = 14,
})

local ESPColors = ESPSub:CreateSection("ESP Colors")
ESPColors:CreateColorPicker({
	Name = "Box Color",
	Color = Color3.fromRGB(140, 110, 220),
})
ESPColors:CreateColorPicker({
	Name = "Name Color",
	Color = Color3.fromRGB(225, 215, 245),
})
ESPColors:CreateColorPicker({
	Name = "Distance Color",
	Color = Color3.fromRGB(155, 135, 185),
})
ESPColors:CreateColorPicker({
	Name = "Tracer Color",
	Color = Color3.fromRGB(140, 110, 220),
})

local ChamsGroup = ChamsSub:CreateSection("Chams")
ChamsGroup:CreateToggle({
	Name = "Enable Chams",
	CurrentValue = false,
})
ChamsGroup:CreateToggle({
	Name = "Highlight Yourself",
	CurrentValue = false,
})
ChamsGroup:CreateSlider({
	Name = "Fill Transparency",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 50,
})
ChamsGroup:CreateSlider({
	Name = "Outline Transparency",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
})

local ChamsColors = ChamsSub:CreateSection("Chams Colors")
ChamsColors:CreateColorPicker({
	Name = "Chams Color",
	Color = Color3.fromRGB(140, 110, 220),
})

--// ═══════════════════════════════════════════════════════════
--// SETTINGS TAB (always last)
--// ═══════════════════════════════════════════════════════════

local CreditGroup = SettingsTab:CreateSection("Credits")
local CreditLabel = CreditGroup:CreateLabel("")
task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:SetText(shown .. cursor)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:SetText(shown .. cursor)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

local MenuGroup = SettingsTab:CreateSection("Menu")
MenuGroup:CreateToggle({
	Name = "Open Keybind Menu",
	CurrentValue = false,
})
MenuGroup:CreateToggle({
	Name = "Custom Cursor",
	CurrentValue = false,
})
MenuGroup:CreateButton({ Name = "Test Notification", Callback = function()
	Library.Notify({ Title = "Ivory", Content = "This is a test notification!", Type = "Info", Duration = 3 })
end })
MenuGroup:CreateDropdown({
	Name = "Notification Side",
	Options = { "Left", "Right" },
	CurrentOption = "Right",
})
MenuGroup:CreateDropdown({
	Name = "DPI Scale",
	Options = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	CurrentOption = "100%",
})
MenuGroup:CreateSlider({
	Name = "Corner Radius",
	Range = {0, 20},
	Increment = 1,
	CurrentValue = 4,
})
MenuGroup:CreateDivider()
MenuGroup:CreateLabel("Menu bind")
MenuGroup:CreateKeybind({ Name = "Menu keybind", CurrentKeybind = "RightShift" })
MenuGroup:CreateButton({ Name = "Join Discord", Callback = function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 }) end })
MenuGroup:CreateButton({ Name = "Unload", Callback = function()
	Library:Unload()
end })

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
	local padIndex = tonumber(State.LockedPad or 1)
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
	Library.Notify({
		Title = "Ivory",
		Content = "Auto teleported to pad " .. padIndex,
		Type = "Success",
		Duration = 3,
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
		if input.KeyCode == Enum.KeyCode.V then
			DoBang()
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

RunService.RenderStepped:Connect(function()
	Camera = Workspace.CurrentCamera

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

do
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
end

Library.Notify({
	Title = "Ivory",
	Content = "Elemental Magic Arena loaded. RightShift to toggle menu.",
	Type = "Success",
	Duration = 3,
})

print("[Ivory] Elemental Magic Arena loaded!")