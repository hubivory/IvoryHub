--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162

--// ═══════════════════════════════════════════════════════════
--// ANTICHEAT BYPASS - Humanoid Replacement
--// Replaces the Humanoid instance to sever hooks/references
--// the anticheat (Kernel LocalScript) has on the original.
--// All game scripts are compiled (src=0) so constant-wiping
--// is impossible. Instance replacement is the correct approach.
--// ═══════════════════════════════════════════════════════════

local getnamecallmethod = getnamecallmethod or nil
local hookmetamethod = hookmetamethod or nil
local checkcaller = checkcaller or function() return false end
local getgenv = getgenv or getfenv

local function replaceHumanoid(char)
	if not char then return nil end
	local oldHum = char:FindFirstChildOfClass("Humanoid")
	if not oldHum then return nil end

	local animScript = char:FindFirstChild("Animate")
	if animScript and animScript:IsA("LocalScript") then
		animScript.Disabled = true
	end

	local animator = oldHum:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in next, animator:GetPlayingAnimationTracks() do
			track:Stop(0)
		end
	end

	oldHum.Archivable = true
	local newHum = oldHum:Clone()

	for _, child in next, newHum:GetChildren() do
		if child:IsA("Animator") then child:Destroy() end
	end

	oldHum.Name = "_OldHumanoid"
	newHum.Name = "Humanoid"
	newHum.Parent = char

	local newAnimator = Instance.new("Animator")
	newAnimator.Parent = newHum

	newHum.WalkSpeed = oldHum.WalkSpeed
	newHum.JumpPower = oldHum.JumpPower
	newHum.JumpHeight = oldHum.JumpHeight
	newHum.MaxHealth = oldHum.MaxHealth
	newHum.Health = math.min(oldHum.Health, oldHum.MaxHealth)

	local cam = workspace.CurrentCamera
	if cam then cam.CameraSubject = newHum end

	oldHum:Destroy()

	task.defer(function()
		if animScript and animScript:IsA("LocalScript") then
			animScript.Disabled = false
			task.defer(function()
				if animScript.Parent then
					animScript.Disabled = true
					task.wait()
					animScript.Disabled = false
				end
			end)
		end
		if newHum.Parent then
			newHum:ChangeState(Enum.HumanoidStateType.Running)
		end
	end)

	return newHum
end

--// Safety: Hook namecall to block Kick and suspicious remotes
if hookmetamethod and getnamecallmethod then
	pcall(function()
		local oldNamecall
		oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
			local method = getnamecallmethod()

			if method == "Kick" then
				if typeof(self) == "Instance" and self:IsA("Player") then
					return nil
				end
			end

			if method == "FireServer" or method == "InvokeServer" then
				local ok, remoteName = pcall(function() return self.Name end)
				if ok and remoteName then
					local lower = remoteName:lower()
					if lower:find("kick") or lower:find("ban") or lower:find("anti") or lower:find("report") then
						return nil
					end
				end
			end

			return oldNamecall(self, ...)
		end))
	end)
end

--// Safety: Hook __index to spoof humanoid property reads for game scripts
pcall(function()
	if hookmetamethod and checkcaller then
		local oldIndex
		oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
			if not checkcaller() and typeof(self) == "Instance" and self:IsA("Humanoid") then
				if key == "WalkSpeed" then return 16 end
				if key == "JumpPower" then return 50 end
				if key == "JumpHeight" then return 7.2 end
				if key == "HipHeight" then return 0 end
			end
			return oldIndex(self, key)
		end))
	end
end)

--// Safety: Hide exploit environment markers
pcall(function()
	local genv = getgenv()
	genv.绘制 = nil
	genv.identifyexecutor = function() return "Ivory", "1.0" end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- Replace Humanoid on current character immediately
if Player.Character then
	task.spawn(function() replaceHumanoid(Player.Character) end)
end

local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera

Player.CharacterAdded:Connect(function(c)
	Character = c
	replaceHumanoid(c)
	Humanoid = c:FindFirstChildOfClass("Humanoid") or c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

local httpGet = function(url)
	local ok, res = pcall(function()
		return request({ Url = url, Method = "GET" })
	end)
	if ok and res and res.Body then
		local body = res.Body
		if body:byte(1) == 0xEF and body:byte(2) == 0xBB and body:byte(3) == 0xBF then
			body = body:sub(4)
		end
		return body
	end
	return nil
end

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
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

local PlaceId = game.PlaceId
local GameName = tostring(PlaceId)
pcall(function()
	GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

local isLobby = false
pcall(function()
	isLobby = Workspace:FindFirstChild("Lobby") ~= nil
		or Workspace:FindFirstChild("lobby") ~= nil
		or Player.Character == nil
end)

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.4 |",
		{ Text = isLobby and "Lobby" or "Game", Copyable = true },
		"|",
		{ Text = tostring(Player.UserId), Copyable = true },
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	MinimizedWidth = 280,
	NotifySide = "Right",
	ShowCustomCursor = true,
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

local State = {
	AutoSteal = false,
	AutoStealRange = 50,
	AutoStealSpeed = 300,
	StealFromPlayers = true,
	StealFromNPCs = true,
	StealNearest = true,
	EggESP = false,
	EggESPColor = Color3.fromRGB(255, 215, 0),
	PetESP = false,
	PetESPColor = Color3.fromRGB(100, 255, 100),
	PlayerESP = false,
	PlayerESPColor = Color3.fromRGB(100, 200, 255),
	ChestESP = false,
	ChestESPColor = Color3.fromRGB(255, 100, 100),
	FullBright = false,
	NoFog = false,
	Speed_Enabled = false,
	Speed_Value = 16,
	JumpPower_Enabled = false,
	JumpPower_Value = 50,
	InfiniteJump = false,
	Noclip = false,
	ClickTeleport = false,
	AutoTrain = false,
	TrainSpeed = 100,
	AutoHatch = false,
	AutoCollect = false,
	AntiAFK = false,
	AutoRejoin = false,
	CollectRadius = 100,
	AutoSell = false,
	SellThreshold = 10,
	AutoUpgrade = false,
	UpgradeType = "Speed",
	WalkOnWater = false,
	Fly_Enabled = false,
	Fly_Speed = 50,
}

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local FarmTab = Window:AddTab({ Name = "Farm", Icon = "cpu" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local TeleportTab = Window:AddTab({ Name = "Teleport", Icon = "map" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local InfoSub = MainTab:AddSubTab("Info", "info")
local DiscordGroup = InfoSub:AddLeftGroupbox("Community", "users")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 })
end)
DiscordGroup:AddLabel("Click above to join our Discord for dupes, updates & more!")

local GameInfoGroup = InfoSub:AddLeftGroupbox("Current Game", "gamepad-2")
GameInfoGroup:AddLabel("Game: " .. GameName)
GameInfoGroup:AddLabel("PlaceId: " .. PlaceId)
GameInfoGroup:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

local ScriptInfoGroup = InfoSub:AddRightGroupbox("Script Status", "check-circle")
ScriptInfoGroup:AddLabel('<font color="#8C6EDC"><b>Ivory Hub v1.4</b></font>', true)
ScriptInfoGroup:AddLabel("Steal An Egg Script Loaded")
ScriptInfoGroup:AddLabel("All features active")

local StealSub = FarmTab:AddSubTab("Steal", "zap")
local StealGroup = StealSub:AddLeftGroupbox("Auto Steal", "target")
local StealSettings = StealSub:AddRightGroupbox("Steal Settings", "sliders")

StealGroup:AddToggle("AutoSteal", {
	Text = "Enable Auto Steal",
	Default = false,
	Callback = function(v) State.AutoSteal = v end,
}):AddKeyPicker("AutoStealKey", {
	Default = "None", Text = "Auto Steal Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

StealGroup:AddToggle("StealFromPlayers", { Text = "Steal From Players", Default = true, Callback = function(v) State.StealFromPlayers = v end })
StealGroup:AddToggle("StealFromNPCs", { Text = "Steal From NPCs", Default = true, Callback = function(v) State.StealFromNPCs = v end })
StealGroup:AddToggle("StealNearest", { Text = "Steal Nearest First", Default = true, Callback = function(v) State.StealNearest = v end })

StealGroup:AddButton("Steal Nearest Egg", function()
	task.spawn(function()
		local nearest = findNearestEgg()
		if nearest then
			tweenToTarget(nearest)
		else
			Library:Notify({ Title = "Ivory", Description = "No eggs found nearby", Type = "Info", Time = 2 })
		end
	end)
end)

StealGroup:AddButton("Steal All Eggs", function()
	task.spawn(function()
		local eggs = findAllEggs()
		for _, egg in ipairs(eggs) do
			if not State.AutoSteal then break end
			tweenToTarget(egg)
			task.wait(0.3)
		end
		Library:Notify({ Title = "Ivory", Description = "Finished stealing eggs!", Type = "Success", Time = 3 })
	end)
end)

StealSettings:AddSlider("AutoStealRange", { Text = "Steal Range (studs)", Default = 50, Min = 10, Max = 500, Rounding = 0, Callback = function(v) State.AutoStealRange = v end })
StealSettings:AddSlider("AutoStealSpeed", { Text = "Move Speed", Default = 300, Min = 50, Max = 1000, Rounding = 0, Callback = function(v) State.AutoStealSpeed = v end })

local CollectSub = FarmTab:AddSubTab("Collect", "package")
local CollectGroup = CollectSub:AddLeftGroupbox("Auto Collect", "box")
local CollectSettings = CollectSub:AddRightGroupbox("Collect Settings", "sliders")

CollectGroup:AddToggle("AutoCollect", {
	Text = "Enable Auto Collect",
	Default = false,
	Callback = function(v) State.AutoCollect = v end,
}):AddKeyPicker("AutoCollectKey", {
	Default = "None", Text = "Collect Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

CollectGroup:AddButton("Collect All Drops", function()
	task.spawn(function()
		local drops = findAllDrops()
		for _, drop in ipairs(drops) do
			if not State.AutoCollect then break end
			tweenToTarget(drop)
			task.wait(0.2)
		end
		Library:Notify({ Title = "Ivory", Description = "Collected all drops!", Type = "Success", Time = 3 })
	end)
end)

CollectSettings:AddSlider("CollectRadius", { Text = "Collect Radius", Default = 100, Min = 10, Max = 500, Rounding = 0, Callback = function(v) State.CollectRadius = v end })

local HatchSub = FarmTab:AddSubTab("Hatch", "egg")
local HatchGroup = HatchSub:AddLeftGroupbox("Auto Hatch", "box")
local HatchSettings = HatchSub:AddRightGroupbox("Hatch Settings", "sliders")

HatchGroup:AddToggle("AutoHatch", {
	Text = "Enable Auto Hatch",
	Default = false,
	Callback = function(v) State.AutoHatch = v end,
}):AddKeyPicker("AutoHatchKey", {
	Default = "None", Text = "Hatch Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

HatchGroup:AddButton("Hatch All Eggs", function()
	task.spawn(function()
		autoHatchAll()
		Library:Notify({ Title = "Ivory", Description = "Hatched all eggs!", Type = "Success", Time = 3 })
	end)
end)

local TrainSub = FarmTab:AddSubTab("Train", "dumbbell")
local TrainGroup = TrainSub:AddLeftGroupbox("Auto Train", "dumbbell")
local TrainSettings = TrainSub:AddRightGroupbox("Train Settings", "sliders")

TrainGroup:AddToggle("AutoTrain", {
	Text = "Enable Auto Train",
	Default = false,
	Callback = function(v) State.AutoTrain = v end,
}):AddKeyPicker("AutoTrainKey", {
	Default = "None", Text = "Train Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

TrainGroup:AddButton("Start Training", function()
	task.spawn(function()
		startAutoTrain()
	end)
end)

TrainGroup:AddButton("Stop Training", function()
	State.AutoTrain = false
	Library:Notify({ Title = "Ivory", Description = "Training stopped", Type = "Info", Time = 2 })
end)

TrainSettings:AddSlider("TrainSpeed", { Text = "Train Speed", Default = 100, Min = 10, Max = 500, Rounding = 0, Callback = function(v) State.TrainSpeed = v end })

local SellSub = FarmTab:AddSubTab("Sell & Upgrade", "dollar-sign")
local SellGroup = SellSub:AddLeftGroupbox("Auto Sell", "shopping-cart")
local UpgradeGroup = SellSub:AddRightGroupbox("Auto Upgrade", "arrow-up-circle")

SellGroup:AddToggle("AutoSell", {
	Text = "Enable Auto Sell",
	Default = false,
	Callback = function(v) State.AutoSell = v end,
}):AddKeyPicker("AutoSellKey", {
	Default = "None", Text = "Sell Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SellGroup:AddSlider("SellThreshold", { Text = "Sell At (eggs)", Default = 10, Min = 1, Max = 100, Rounding = 0, Callback = function(v) State.SellThreshold = v end })

SellGroup:AddButton("Sell Now", function()
	task.spawn(function()
		sellEggs()
		Library:Notify({ Title = "Ivory", Description = "Sold eggs!", Type = "Success", Time = 2 })
	end)
end)

UpgradeGroup:AddToggle("AutoUpgrade", {
	Text = "Enable Auto Upgrade",
	Default = false,
	Callback = function(v) State.AutoUpgrade = v end,
}):AddKeyPicker("AutoUpgradeKey", {
	Default = "None", Text = "Upgrade Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

UpgradeGroup:AddDropdown("UpgradeType", {
	Values = { "Speed", "Jump", "Capacity", "EggQuality" }, Default = "Speed", Text = "Upgrade Type",
	Callback = function(v) State.UpgradeType = v end,
})

UpgradeGroup:AddButton("Upgrade Now", function()
	task.spawn(function()
		buyUpgrade(State.UpgradeType)
		Library:Notify({ Title = "Ivory", Description = "Upgraded " .. State.UpgradeType .. "!", Type = "Success", Time = 2 })
	end)
end)

local MovementSub = PlayerTab:AddSubTab("Movement", "move")
local SpeedGroup = MovementSub:AddLeftGroupbox("Speed", "zap")
local JumpGroup = MovementSub:AddRightGroupbox("Jump", "arrow-up")

SpeedGroup:AddToggle("SpeedEnabled", {
	Text = "Enable Speed",
	Default = false,
	Callback = function(v)
		State.Speed_Enabled = v
		if not v then pcall(function() Humanoid.WalkSpeed = 16 end) end
	end,
}):AddKeyPicker("SpeedKey", {
	Default = "None", Text = "Speed Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SpeedGroup:AddSlider("SpeedValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 500, Rounding = 0, Callback = function(v) State.Speed_Value = v end })
SpeedGroup:AddButton("Apply Speed", function() pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end)

JumpGroup:AddToggle("JumpPowerEnabled", {
	Text = "Enable Jump Power",
	Default = false,
	Callback = function(v)
		State.JumpPower_Enabled = v
		if not v then pcall(function() Humanoid.JumpPower = 50 end) end
	end,
}):AddKeyPicker("JumpKey", {
	Default = "None", Text = "Jump Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

JumpGroup:AddSlider("JumpPowerValue", { Text = "Jump Power", Default = 50, Min = 50, Max = 500, Rounding = 0, Callback = function(v) State.JumpPower_Value = v end })
JumpGroup:AddButton("Apply Jump Power", function() pcall(function() Humanoid.JumpPower = State.JumpPower_Value end) end)
JumpGroup:AddToggle("InfiniteJump", { Text = "Infinite Jump", Default = false, Callback = function(v) State.InfiniteJump = v end })

local MiscPlayerSub = PlayerTab:AddSubTab("Misc", "settings")
local MiscPlayerGroup = MiscPlayerSub:AddLeftGroupbox("Player Mods", "user")
local FlyGroup = MiscPlayerSub:AddRightGroupbox("Fly", "wind")

MiscPlayerGroup:AddToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(v) State.Noclip = v end })
MiscPlayerGroup:AddToggle("ClickTeleport", { Text = "Click Teleport", Default = false, Callback = function(v) State.ClickTeleport = v end })
MiscPlayerGroup:AddToggle("WalkOnWater", {
	Text = "Walk on Water",
	Default = false,
	Callback = function(v)
		State.WalkOnWater = v
		if v then
			task.spawn(function()
				while State.WalkOnWater do
					pcall(function()
						local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
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
					task.wait()
				end
			end)
		else
			local ww = Workspace:FindFirstChild("IvoryWaterWalk")
			if ww then ww:Destroy() end
		end
	end,
})

FlyGroup:AddToggle("FlyEnabled", {
	Text = "Enable Fly",
	Default = false,
	Callback = function(v) State.Fly_Enabled = v end,
}):AddKeyPicker("FlyKey", {
	Default = "None", Text = "Fly Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

FlyGroup:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) State.Fly_Speed = v end })

local PlayerESPSub = VisualsTab:AddSubTab("Player ESP", "users")
local PlayerESPGroup = PlayerESPSub:AddLeftGroupbox("Player ESP", "users")
local PlayerESPSettings = PlayerESPSub:AddRightGroupbox("ESP Colors", "palette")

PlayerESPGroup:AddToggle("PlayerESP", {
	Text = "Enable Player ESP",
	Default = false,
	Callback = function(v) State.PlayerESP = v end,
}):AddKeyPicker("PlayerESPKey", {
	Default = "None", Text = "Player ESP Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

PlayerESPSettings:AddLabel("Player ESP Color"):AddColorPicker("PlayerESPColor", { Default = Color3.fromRGB(100, 200, 255), Title = "Player ESP", Callback = function(v) State.PlayerESPColor = v end })

local EggESPSub = VisualsTab:AddSubTab("Egg ESP", "egg")
local EggESPGroup = EggESPSub:AddLeftGroupbox("Egg ESP", "egg")
local EggESPSettings = EggESPSub:AddRightGroupbox("Egg Colors", "palette")

EggESPGroup:AddToggle("EggESP", {
	Text = "Enable Egg ESP",
	Default = false,
	Callback = function(v) State.EggESP = v end,
}):AddKeyPicker("EggESPKey", {
	Default = "None", Text = "Egg ESP Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

EggESPGroup:AddToggle("PetESP", {
	Text = "Enable Pet ESP",
	Default = false,
	Callback = function(v) State.PetESP = v end,
})

EggESPGroup:AddToggle("ChestESP", {
	Text = "Enable Chest/Drop ESP",
	Default = false,
	Callback = function(v) State.ChestESP = v end,
})

EggESPSettings:AddLabel("Egg ESP Color"):AddColorPicker("EggESPColor", { Default = Color3.fromRGB(255, 215, 0), Title = "Egg ESP", Callback = function(v) State.EggESPColor = v end })
EggESPSettings:AddLabel("Pet ESP Color"):AddColorPicker("PetESPColor", { Default = Color3.fromRGB(100, 255, 100), Title = "Pet ESP", Callback = function(v) State.PetESPColor = v end })
EggESPSettings:AddLabel("Chest ESP Color"):AddColorPicker("ChestESPColor", { Default = Color3.fromRGB(255, 100, 100), Title = "Chest ESP", Callback = function(v) State.ChestESPColor = v end })

local WorldSub = VisualsTab:AddSubTab("World", "globe")
local WorldGroup = WorldSub:AddLeftGroupbox("Lighting", "sun")

WorldGroup:AddButton("Full Bright", function()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
end)

WorldGroup:AddButton("Remove Fog", function()
	Lighting.FogEnd = 999999
	Lighting.FogStart = 0
end)

WorldGroup:AddButton("Reset Lighting", function()
	Lighting.Brightness = 1
	Lighting.ClockTime = 12
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0
end)

WorldGroup:AddButton("Fast Mode", function()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Material = Enum.Material.SmoothPlastic
			obj.Reflectance = 0
			obj.CastShadow = false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj:Destroy()
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
			obj.Enabled = false
		elseif obj:IsA("SurfaceAppearance") then
			obj:Destroy()
		end
	end
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	local Terrain = workspace:FindFirstChildOfClass("Terrain")
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterTransparency = 1
		Terrain.WaterReflectance = 0
	end
	Library:Notify({ Title = "Ivory", Description = "Fast Mode enabled", Type = "Info", Time = 3 })
end)

local TeleportSub = TeleportTab:AddSubTab("Locations", "map-pin")
local TPGroup = TeleportSub:AddLeftGroupbox("Teleport", "compass")
local ServerGroup = TeleportSub:AddRightGroupbox("Server", "globe")

TPGroup:AddButton("Teleport to Base", function()
	task.spawn(function()
		local base = Workspace:FindFirstChild("Base") or Workspace:FindFirstChild("base") or Workspace:FindFirstChild("PlayerBase")
		if base then
			local root = base:FindFirstChildWhichIsA("BasePart") or base.PrimaryPart
			if root then
				tweenToTarget(root.Position)
			end
		end
	end)
end)

TPGroup:AddButton("Teleport to Treadmill", function()
	task.spawn(function()
		local treadmill = Workspace:FindFirstChild("Treadmill") or Workspace:FindFirstChild("treadmill") or Workspace:FindFirstChild("Training")
		if treadmill then
			local root = treadmill:FindFirstChildWhichIsA("BasePart") or treadmill.PrimaryPart
			if root then
				tweenToTarget(root.Position)
			end
		end
	end)
end)

TPGroup:AddButton("Teleport to Egg Shop", function()
	task.spawn(function()
		local shop = Workspace:FindFirstChild("EggShop") or Workspace:FindFirstChild("Shop") or Workspace:FindFirstChild("EggStore")
		if shop then
			local root = shop:FindFirstChildWhichIsA("BasePart") or shop.PrimaryPart
			if root then
				tweenToTarget(root.Position)
			end
		end
	end)
end)

TPGroup:AddButton("Teleport to Sell Area", function()
	task.spawn(function()
		local sell = Workspace:FindFirstChild("Sell") or Workspace:FindFirstChild("SellArea") or Workspace:FindFirstChild("Selling")
		if sell then
			local root = sell:FindFirstChildWhichIsA("BasePart") or sell.PrimaryPart
			if root then
				tweenToTarget(root.Position)
			end
		end
	end)
end)

ServerGroup:AddButton("Rejoin Server", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)

ServerGroup:AddButton("Server Hop", function()
	task.spawn(function()
		local servers = {}
		local cursor = nil
		repeat
			local url = ("https://games.roblox.com/v1/games/%s/servers/Public?limit=100%s"):format(
				game.PlaceId, cursor and "&cursor=" .. HttpService:UrlEncode(cursor) or ""
			)
			local ok, res = pcall(function() return HttpService:GetAsync(url) end)
			if not ok then break end
			local data = HttpService:JSONDecode(res)
			for _, s in ipairs(data.data) do
				if s.id ~= game.JobId and s.playing < s.maxPlayers then
					table.insert(servers, s.id)
				end
			end
			cursor = data.nextPageCursor
		until not cursor
		if #servers > 0 then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], Player)
		end
	end)
end)

ServerGroup:AddButton("Copy Server JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

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
CreditTL.RichText = false
CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
CreditTL.Font = Enum.Font.GothamBold
CreditTL.TextSize = 26

task.spawn(function()
	local full = "Made by mommy Crow & Veqxo </3"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditTL.Text = shown .. cursor
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditTL.Text = shown .. cursor
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

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

local function getHRP()
	local c = Player.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = Player.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local Steal = {}
Steal.Speed = State.AutoStealSpeed

Steal.ResetHumanoidState = function(hum)
	pcall(function()
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end)
end

Steal.TweenTo = function(targetPos, customSpeed, opts)
	opts = opts or {}
	local Char = Player.Character
	local Root = Char and Char:FindFirstChild("HumanoidRootPart")
	local Hum = Char and Char:FindFirstChildOfClass("Humanoid")
	if not Root then return false end

	if Hum then Steal.ResetHumanoidState(Hum) end
	local speed = customSpeed or (opts.Owner == "Steal" and (Steal.Speed or 300))
	local startPos = Root.Position
	local dist = (targetPos - startPos).Magnitude
	if dist <= 0.5 then return true end

	local duration = dist / math.max(speed, 5)
	local startTime = os.clock()

	local diff = Vector3.new(targetPos.X - startPos.X, 0, targetPos.Z - startPos.Z)
	local targetLookDir = (diff.Magnitude > 0.1) and diff.Unit or Root.CFrame.LookVector

	while true do
		local currentChar = Player.Character
		local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
		if not currentRoot then break end

		local elapsed = os.clock() - startTime
		local alpha = math.clamp(elapsed / duration, 0, 1)

		local currentPos = startPos:Lerp(targetPos, alpha)
		currentRoot.CFrame = CFrame.lookAt(currentPos, currentPos + targetLookDir)

		currentRoot.AssemblyLinearVelocity = Vector3.zero
		currentRoot.AssemblyAngularVelocity = Vector3.zero

		if alpha >= 1 then break end
		RunService.Heartbeat:Wait()
	end

	if Root and Root.Parent then
		Root.CFrame = (diff.Magnitude > 0.1) and CFrame.lookAt(targetPos, targetPos + targetLookDir) or CFrame.new(targetPos)
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
	end
	if Hum and Hum.Parent then
		pcall(function() Hum:ChangeState(Enum.HumanoidStateType.Running) end)
	end

	return true
end

local function tweenToTarget(pos)
	return Steal.TweenTo(pos, State.AutoStealSpeed, { Owner = "Steal" })
end

local function findEggParts()
	local eggs = {}
	local searchFolders = { Workspace }
	local knownFolders = { "Eggs", "Drops", "Items", "Collectibles", "Spawns", "EggSpawns" }

	for _, name in ipairs(knownFolders) do
		local folder = Workspace:FindFirstChild(name)
		if folder then table.insert(searchFolders, folder) end
	end

	for _, folder in ipairs(searchFolders) do
		for _, obj in ipairs(folder:GetDescendants()) do
			if obj:IsA("Model") or obj:IsA("BasePart") then
				local nameLower = obj.Name:lower()
				if nameLower:find("egg") or nameLower:find("drop") or nameLower:find("coin") or nameLower:find("gem") then
					local part = obj:IsA("BasePart") and obj or (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
					if part and part.Parent then
						table.insert(eggs, part)
					end
				end
			end
		end
	end
	return eggs
end

local function findNearestEgg()
	local hrp = getHRP()
	if not hrp then return nil end
	local eggs = findEggParts()
	local nearest, nearestDist = nil, math.huge
	for _, egg in ipairs(eggs) do
		local dist = (egg.Position - hrp.Position).Magnitude
		if dist < nearestDist and dist <= State.AutoStealRange then
			nearestDist = dist
			nearest = egg
		end
	end
	return nearest
end

local function findAllEggs()
	local hrp = getHRP()
	if not hrp then return {} end
	local eggs = findEggParts()
	local filtered = {}
	for _, egg in ipairs(eggs) do
		local dist = (egg.Position - hrp.Position).Magnitude
		if dist <= State.AutoStealRange then
			table.insert(filtered, egg)
		end
	end
	table.sort(filtered, function(a, b)
		return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
	end)
	return filtered
end

local function findAllDrops()
	local hrp = getHRP()
	if not hrp then return {} end
	local drops = {}
	local searchFolders = { Workspace }
	for _, folder in ipairs(searchFolders) do
		for _, obj in ipairs(folder:GetDescendants()) do
			if obj:IsA("BasePart") then
				local nameLower = obj.Name:lower()
				if nameLower:find("drop") or nameLower:find("coin") or nameLower:find("gem") or nameLower:find("loot") or nameLower:find("reward") then
					local dist = (obj.Position - hrp.Position).Magnitude
					if dist <= State.CollectRadius then
						table.insert(drops, obj)
					end
				end
			end
		end
	end
	table.sort(drops, function(a, b)
		return (a.Position - hrp.Position).Magnitude < (b.Position - hrp.Position).Magnitude
	end)
	return drops
end

local function autoHatchAll()
	local eggs = findEggParts()
	for _, egg in ipairs(eggs) do
		if not State.AutoHatch then break end
		tweenToTarget(egg.Position)
		task.wait(0.5)
		pcall(function()
			local clickDetector = egg:FindFirstChildOfClass("ClickDetector")
			if clickDetector then
				clickDetector.MouseClick:Fire()
			end
		end)
		pcall(function()
			local proximity = egg:FindFirstChildOfClass("ProximityPrompt")
			if proximity then
				proximity:InputBegin(Player)
				task.wait(0.1)
				proximity:InputEnd(Player)
			end
		end)
		task.wait(0.3)
	end
end

local function startAutoTrain()
	local treadmill = Workspace:FindFirstChild("Treadmill") or Workspace:FindFirstChild("treadmill") or Workspace:FindFirstChild("Training")
	if treadmill then
		local root = treadmill:FindFirstChildWhichIsA("BasePart") or treadmill.PrimaryPart
		if root then
			tweenToTarget(root.Position)
			task.wait(0.5)
			local hrp = getHRP()
			local hum = getHum()
			if hrp and hum then
				local trainConn
				trainConn = RunService.Heartbeat:Connect(function()
					if not State.AutoTrain or not Player.Character then
						trainConn:Disconnect()
						return
					end
					pcall(function()
						hrp.CFrame = root.CFrame * CFrame.new(0, 2, 0)
						hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
					end)
				end)
			end
		end
	end
end

local function sellEggs()
	local sell = Workspace:FindFirstChild("Sell") or Workspace:FindFirstChild("SellArea") or Workspace:FindFirstChild("Selling")
	if sell then
		local root = sell:FindFirstChildWhichIsA("BasePart") or sell.PrimaryPart
		if root then
			tweenToTarget(root.Position)
			task.wait(0.5)
			pcall(function()
				local clickDetector = sell:FindFirstChildOfClass("ClickDetector")
				if clickDetector then
					clickDetector.MouseClick:Fire()
				end
			end)
			pcall(function()
				local proximity = sell:FindFirstChildOfClass("ProximityPrompt")
				if proximity then
					proximity:InputBegin(Player)
					task.wait(0.1)
					proximity:InputEnd(Player)
				end
			end)
		end
	end
end

local function buyUpgrade(upgradeType)
	local upgrade = Workspace:FindFirstChild(upgradeType) or Workspace:FindFirstChild(upgradeType:lower()) or Workspace:FindFirstChild(upgradeType:upper())
	if upgrade then
		local root = upgrade:FindFirstChildWhichIsA("BasePart") or upgrade.PrimaryPart
		if root then
			tweenToTarget(root.Position)
			task.wait(0.5)
			pcall(function()
				local clickDetector = upgrade:FindFirstChildOfClass("ClickDetector")
				if clickDetector then
					clickDetector.MouseClick:Fire()
				end
			end)
			pcall(function()
				local proximity = upgrade:FindFirstChildOfClass("ProximityPrompt")
				if proximity then
					proximity:InputBegin(Player)
					task.wait(0.1)
					proximity:InputEnd(Player)
				end
			end)
		end
	end
end

local ESPObjects = {}

local function clearESP()
	for _, obj in pairs(ESPObjects) do
		pcall(function() if obj and obj.Parent then obj:Destroy() end end)
	end
	ESPObjects = {}
end

local function createBillboardESP(part, text, color, offset)
	if not part or not part.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "IvoryESP"
	bb.Size = UDim2.new(0, 150, 0, 30)
	bb.StudsOffset = offset or Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = part
	bb.Parent = part
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color or State.EggESPColor
	tl.TextSize = 13
	tl.Font = Enum.Font.GothamBold
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.Parent = bb
	table.insert(ESPObjects, bb)
end

local function updateESP()
	clearESP()
	if State.EggESP then
		for _, egg in ipairs(findEggParts()) do
			if egg and egg.Parent then
				createBillboardESP(egg, "Egg: " .. egg.Name, State.EggESPColor, Vector3.new(0, 5, 0))
			end
		end
	end
	if State.PetESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("Model") and obj.Name:lower():find("pet") then
				local root = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				if root then
					createBillboardESP(root, "Pet: " .. obj.Name, State.PetESPColor, Vector3.new(0, 5, 0))
				end
			end
		end
	end
	if State.ChestESP then
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") then
				local nameLower = obj.Name:lower()
				if nameLower:find("chest") or nameLower:find("drop") or nameLower:find("loot") then
					createBillboardESP(obj, obj.Name, State.ChestESPColor, Vector3.new(0, 3, 0))
				end
			end
		end
	end
	if State.PlayerESP then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= Player and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local myHRP = getHRP()
					local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
					local label = plr.DisplayName .. " [" .. dist .. "m]"
					createBillboardESP(hrp, label, State.PlayerESPColor)
				end
			end
		end
	end
end

local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = Player.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

local infJumpConn = nil
local function setInfiniteJump(on)
	if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
	if on then
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			pcall(function()
				local c = Player.Character
				if c then
					local h = c:FindFirstChildWhichIsA("Humanoid")
					if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
				end
			end)
		end)
	end
end

local flyBodyVelocity, flyBodyGyro

local function startFly()
	pcall(function()
		local hrp = getHRP()
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

UserInputService.JumpRequest:Connect(function()
	if State.InfiniteJump then
		pcall(function() Player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping) end)
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if State.ClickTeleport and input.UserInputType == Enum.UserInputType.MouseButton1 then
		pcall(function()
			local mouse = Player:GetMouse()
			local hrp = getHRP()
			if hrp then
				hrp.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(60) do
		if State.AntiAFK then pcall(function() VirtualUser:ClickButton2(Vector2.new()) end) end
	end
end)

RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera

	if State.Speed_Enabled then pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end
	if State.JumpPower_Enabled then pcall(function() Humanoid.JumpPower = State.JumpPower_Value end) end

	if State.Fly_Enabled then
		if not flyBodyVelocity then startFly() end
		pcall(function()
			local hrp = getHRP()
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
				flyBodyVelocity.Velocity = moveDir.Unit * State.Fly_Speed
			else
				flyBodyVelocity.Velocity = Vector3.zero
			end
			flyBodyGyro.CFrame = camCF
		end)
	else
		if flyBodyVelocity then stopFly() end
	end

	if State.Noclip then if not noclipConn then setNoclip(true) end else if noclipConn then setNoclip(false) end end
end)

task.spawn(function()
	while task.wait(2) do
		if State.PlayerESP or State.EggESP or State.PetESP or State.ChestESP then
			updateESP()
		end
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		if State.AutoSteal then
			pcall(function()
				local nearest = findNearestEgg()
				if nearest then
					tweenToTarget(nearest.Position)
					task.wait(0.2)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(1) do
		if State.AutoCollect then
			pcall(function()
				local drops = findAllDrops()
				for _, drop in ipairs(drops) do
					if not State.AutoCollect then break end
					tweenToTarget(drop.Position)
					task.wait(0.1)
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if State.AutoSell then
			pcall(function()
				local eggs = findEggParts()
				if #eggs >= State.SellThreshold then
					sellEggs()
				end
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if State.AutoUpgrade then
			pcall(function()
				buyUpgrade(State.UpgradeType)
			end)
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		if State.AutoRejoin then
			pcall(function()
				if not Player then TeleportService:Teleport(PlaceId) end
			end)
		end
	end
end)

Library:OnUnload(function()
	stopFly()
	setNoclip(false)
	setInfiniteJump(false)
	clearESP()
end)

Library:Notify({
	Title = "Ivory",
	Description = "v1.4 loaded successfully",
	Type = "Success",
	Time = 5,
})
