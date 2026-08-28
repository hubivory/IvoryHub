--// Ivory Hub | Blox Fruits
--// Place ID: 2753915549

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local CommF = Remotes and Remotes:WaitForChild("CommF_", 10)
local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
local Net = Modules and Modules:WaitForChild("Net", 10)

local RegisterAttack = nil
local RegisterHit = nil

task.spawn(function()
	RegisterAttack = Net and Net:WaitForChild("RE", 10) and Net.RE:WaitForChild("RegisterAttack", 10)
	RegisterHit = Net and Net:WaitForChild("RE", 10) and Net.RE:WaitForChild("RegisterHit", 10)
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
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local hitData = {[4] = "4676ac1a"}

local STATE = {
	AutoFarm = false,
	AutoFarmMethod = "Quest",
	SelectedWeapon = "Melee",
	AutoChest = false,
	AutoBounty = false,
	BountyDistance = 20,
	AutoStats = false,
	StatType = "Melee",
	StatAmount = 1,
	WalkSpeed = 16,
	InfiniteJump = false,
	Noclip = false,
	AntiAFK = false,
	WalkOnWater = false,
	ESP = false,
	ESPPlayers = false,
	ESPFruits = false,
	ESPChests = false,
	ESPColor = Color3.fromRGB(255, 100, 100),
	FullBright = false,
	NoFog = false,
	FastMode = false,
	AutoRaid = false,
	RaidType = "Light",
}

local LOCAL_AFK_CONN = nil

local function getHRP()
	local c = LocalPlayer.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = LocalPlayer.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getLevel()
	local data = LocalPlayer:FindFirstChild("Data")
	if data then
		local lvl = data:FindFirstChild("Level")
		if lvl then return lvl.Value end
	end
	return 0
end

local function isOnIsland(islandName)
	local map = Workspace:FindFirstChild("Map")
	if not map then return false end
	local island = map:FindFirstChild(islandName)
	if not island then return false end
	local hrp = getHRP()
	if not hrp then return false end
	for _, part in ipairs(island:GetDescendants()) do
		if part:IsA("BasePart") then
			local relative = part.CFrame:PointToObjectSpace(hrp.Position)
			local half = part.Size / 2
			if math.abs(relative.X) <= half.X and math.abs(relative.Z) <= half.Z then
				if relative.Y >= -50 and relative.Y <= half.Y + 50 then return true end
			end
		end
	end
	return false
end

local function teleportToIsland(island)
	local hrp = getHRP()
	if not hrp then return end
	local map = Workspace:FindFirstChild("Map")
	if not map then return end
	if island == "Fishmen" or island == "Fishman" then
		if isOnIsland("Fishmen") or isOnIsland("Fishman") then
			hrp.CFrame = workspace.Map.TeleportSpawn.ExitPoint.CFrame
		else
			hrp.CFrame = workspace.Map.TeleportSpawn.EntrancePoint.CFrame
		end
		return
	end
	local islandModel = map:FindFirstChild(island)
	if islandModel and islandModel:GetPivot() then
		hrp.CFrame = islandModel:GetPivot() + Vector3.new(0, 50, 0)
	end
end

local function moveTo(position)
	local hrp = getHRP()
	if not hrp then return end
	local dist = (hrp.Position - position).Magnitude
	local tweenInfo = TweenInfo.new(math.clamp(dist / 350, 0.1, 5), Enum.EasingStyle.Linear)
	local tween = TweenService:Create(hrp, tweenInfo, {CFrame = CFrame.new(position)})
	tween:Play()
end

local function loadEnemy(enemyName)
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	if not origin then return nil end
	local spawns = origin:FindFirstChild("EnemySpawns")
	if not spawns then return nil end
	for _, spawn in ipairs(spawns:GetChildren()) do
		local cleanName = spawn.Name:gsub("%[Lv%.%s*%d+%]%s*", ""):gsub("%s+$", "")
		if cleanName == enemyName then
			moveTo(spawn.Position + Vector3.new(0, 20, 0))
			return spawn
		end
	end
	return nil
end

local function equipWeapon(weaponType)
	local char = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if not char or not backpack then return end
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip == weaponType then
			tool.Parent = char
			break
		end
	end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool.ToolTip ~= weaponType then
			tool.Parent = backpack
		end
	end
end

local function attachFloat()
	local hrp = getHRP()
	if not hrp then return end
	if not hrp:FindFirstChild("IvoryFloatBV") then
		local bv = Instance.new("BodyVelocity")
		bv.Name = "IvoryFloatBV"
		bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
		bv.Velocity = Vector3.zero
		bv.Parent = hrp
	end
	if not hrp:FindFirstChild("IvoryFloatBG") then
		local bg = Instance.new("BodyGyro")
		bg.Name = "IvoryFloatBG"
		bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
		bg.CFrame = hrp.CFrame
		bg.Parent = hrp
	end
end

local function detachFloat()
	local hrp = getHRP()
	if not hrp then return end
	local bv = hrp:FindFirstChild("IvoryFloatBV")
	if bv then bv:Destroy() end
	local bg = hrp:FindFirstChild("IvoryFloatBG")
	if bg then bg:Destroy() end
end

local function autoAttackLoop()
	while STATE.AutoFarm or STATE.AutoBounty do
		task.wait(0.05)
		pcall(function()
			local hrp = getHRP()
			if not hrp then return end
			local enemiesInRange = {}
			for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
				local hum = enemy:FindFirstChildWhichIsA("Humanoid")
				local head = enemy:FindFirstChild("Head")
				if hum and head and hum.Health > 0 then
					if (hrp.Position - head.Position).Magnitude <= 60 then
						table.insert(enemiesInRange, {enemy, head})
					end
				end
			end
			if STATE.AutoBounty then
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= LocalPlayer and p.Character then
						local head = p.Character:FindFirstChild("Head")
						if head and (hrp.Position - head.Position).Magnitude <= 60 then
							table.insert(enemiesInRange, {p.Character, head})
						end
					end
				end
			end
			if #enemiesInRange >= 1 then
				local target = enemiesInRange[1]
				local args
				if #enemiesInRange >= 2 then
					local other = enemiesInRange[2]
					args = {target[2], {{other[1], other[2]}}, [4] = hitData[4]}
				else
					args = {target[2], {}, [4] = hitData[4]}
				end
				RegisterAttack:FireServer(0)
				RegisterHit:FireServer(unpack(args))
			end
			equipWeapon(STATE.SelectedWeapon)
		end)
	end
end

local islandNames = {
	BanditQuest1 = "Windmill", MarineQuest = "MarineStart", JungleQuest = "Jungle",
	BuggyQuest1 = "Pirate", BuggyQuest2 = "Pirate", DesertQuest = "Desert",
	SnowQuest = "Ice", MarineQuest2 = "MarineBase", SkyQuest = "Sky",
	SkyQuest2 = "Sky", PrisonerQuest = "Prison", ImpelQuest = "Prison",
	ColosseumQuest = "Colosseum", MagmaQuest = "Magma", FishmanQuest = "Fishmen",
	SkyExp1Quest = "SkyArea1", SkyExp2Quest = "SkyArea2", FountainQuest = "Fountain",
}

print("[BF] Loading quest data...")
local Quests = nil
pcall(function()
	Quests = loadstring(game:HttpGet("https://raw.githubusercontent.com/CFR-Executor/resources/refs/heads/main/bfquestdumpfull"))()
end)
print("[BF] Quests loaded: " .. tostring(Quests ~= nil))

local function getQuest()
	if not Quests then return nil end
	local level = getLevel()
	local highestQuest, highestIsland
	for islandName, questList in pairs(Quests) do
		for _, quest in ipairs(questList) do
			if level >= quest.LevelReq then
				if not highestQuest or quest.LevelReq > highestQuest.LevelReq then
					highestQuest = quest
					highestIsland = islandName
				end
			end
		end
	end
	if not highestQuest then return nil end
	local questFrame = LocalPlayer.PlayerGui:WaitForChild("Main"):WaitForChild("Quest")
	local hasQuest = questFrame.Visible
	if not hasQuest then
		pcall(function()
			CommF:InvokeServer(unpack(highestQuest.Args))
		end)
	end
	local enemyName
	if hasQuest then
		local titleLabel = questFrame.Container.QuestTitle:FindFirstChild("Title")
		if titleLabel then
			local parsed = titleLabel.Text:match("Defeat%s+%d+%s+(.+)%s+%(%d+/%d+%)")
			if parsed then enemyName = parsed end
		end
	end
	if not enemyName and highestQuest.Task then
		for name, _ in pairs(highestQuest.Task) do
			enemyName = name
			break
		end
	end
	local island = islandNames[highestIsland] or highestIsland
	if not isOnIsland(island) then
		teleportToIsland(island)
	end
	if enemyName then loadEnemy(enemyName) end
	return {
		quest = highestQuest,
		enemy = enemyName,
		island = island,
		levelReq = highestQuest.LevelReq,
		args = highestQuest.Args,
	}
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
	tl.TextColor3 = color or STATE.ESPColor
	tl.TextSize = 13
	tl.Font = Enum.Font.GothamBold
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.Parent = bb
	table.insert(ESPObjects, bb)
end

local function updateESP()
	clearESP()
	if not STATE.ESP then return end
	if STATE.ESPPlayers then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and plr.Character then
				local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local myHRP = getHRP()
					local dist = myHRP and math.floor((myHRP.Position - hrp.Position).Magnitude) or 0
					local label = plr.DisplayName .. " [" .. dist .. "m]"
					createBillboardESP(hrp, label, Color3.fromRGB(100, 200, 255))
				end
			end
		end
	end
	if STATE.ESPFruits then
		for _, obj in ipairs(Workspace:GetChildren()) do
			if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
				createBillboardESP(obj.Handle, "Fruit: " .. obj.Name, Color3.fromRGB(255, 215, 0), Vector3.new(0, 5, 0))
			end
		end
		local map = Workspace:FindFirstChild("Map")
		if map then
			for _, obj in ipairs(map:GetDescendants()) do
				if obj:IsA("Tool") and obj:FindFirstChild("Handle") then
					createBillboardESP(obj.Handle, "Fruit: " .. obj.Name, Color3.fromRGB(255, 215, 0), Vector3.new(0, 5, 0))
				end
			end
		end
	end
	if STATE.ESPChests then
		local chestModels = Workspace:FindFirstChild("ChestModels")
		if chestModels then
			for _, chest in ipairs(chestModels:GetChildren()) do
				if chest:IsA("Model") then
					local part = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
					if part then
						createBillboardESP(part, "Chest", Color3.fromRGB(255, 200, 50))
					end
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
			local c = LocalPlayer.Character
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
				local c = LocalPlayer.Character
				if c then
					local h = c:FindFirstChildWhichIsA("Humanoid")
					if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
				end
			end)
		end)
	end
end

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.4 |",
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

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local TeleportTab = Window:AddTab({ Name = "Teleport", Icon = "map" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local DiscordGroup = MainTab:AddLeftGroupbox("Community", "users")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 })
end)
DiscordGroup:AddLabel("Click above to join our Discord for dupes, updates & more!")

print("[BF] Building Farming subtab...")
local FarmSub = MainTab:AddSubTab("Farming", "zap")
local FarmGroup = FarmSub:AddLeftGroupbox("Auto Farm", "cpu")
local ChestGroup = FarmSub:AddRightGroupbox("Chests", "package")
print("[BF] FarmGroup created, adding toggle...")

FarmGroup:AddToggle("AutoFarm", {
	Text = "Auto Farm Level",
	Default = false,
	Callback = function(v)
		STATE.AutoFarm = v
		if v then
			attachFloat()
			task.spawn(function()
				while STATE.AutoFarm do
					pcall(function()
						local info = getQuest()
						if info and info.enemy then
							local hrp = getHRP()
							if not hrp then return end
							local target
							for _, enemy in ipairs(Workspace.Enemies:GetChildren()) do
								local hum = enemy:FindFirstChildWhichIsA("Humanoid")
								if enemy.Name == info.enemy and hum and hum.Health > 0 then
									target = enemy
									break
								end
							end
							if not LocalPlayer.PlayerGui.Main.Quest.Visible then
								getQuest()
								return
							end
							if target then
								local root = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChild("Head")
								if root then
									local dist = (hrp.Position - root.Position).Magnitude
									if dist > 15 then
										moveTo(root.Position + Vector3.new(0, 10, 0))
									else
										hrp.CFrame = root.CFrame * CFrame.new(0, 10, -8)
									end
								end
							else
								loadEnemy(info.enemy)
							end
							for _, bodypart in ipairs(Character:GetChildren()) do
								if bodypart:IsA("BasePart") then bodypart.CanCollide = false end
							end
						end
					end)
					task.wait(0.3)
				end
				detachFloat()
			end)
			task.spawn(autoAttackLoop)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("AutoFarmKey", {
	Default = "None", Text = "Auto Farm Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})
print("[BF] AutoFarm toggle OK")

FarmGroup:AddDropdown("FarmMethod", {
	Values = { "Quest", "Nearest" }, Default = "Quest", Text = "Farm Method",
	Callback = function(v) STATE.AutoFarmMethod = v end,
})

FarmGroup:AddDropdown("WeaponType", {
	Values = { "Melee", "Sword", "Gun", "Blox Fruit" }, Default = "Melee", Text = "Weapon Type",
	Callback = function(v) STATE.SelectedWeapon = v end,
})

FarmGroup:AddButton("Refresh Quest", function()
	pcall(function() getQuest() end)
end)

FarmGroup:AddButton("Stop Farming", function()
	STATE.AutoFarm = false
	detachFloat()
end)

ChestGroup:AddToggle("AutoChest", {
	Text = "Auto Farm Chests",
	Default = false,
	Callback = function(v)
		STATE.AutoChest = v
		if v then
			task.spawn(function()
				while STATE.AutoChest do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						local chestModels = Workspace:FindFirstChild("ChestModels")
						if chestModels then
							for _, chest in ipairs(chestModels:GetChildren()) do
								if chest:IsA("Model") then
									hrp.CFrame = chest:GetPivot()
									task.wait(0.1)
								end
							end
						end
					end)
					task.wait(0.2)
				end
			end)
		end
	end,
}):AddKeyPicker("AutoChestKey", {
	Default = "None", Text = "Chest Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

ChestGroup:AddButton("Collect All Chests", function()
	task.spawn(function()
		local hrp = getHRP()
		if not hrp then return end
		local chestModels = Workspace:FindFirstChild("ChestModels")
		if chestModels then
			for _, chest in ipairs(chestModels:GetChildren()) do
				if chest:IsA("Model") then
					hrp.CFrame = chest:GetPivot()
					task.wait(0.1)
				end
			end
		end
		Library:Notify({ Title = "Ivory", Description = "Collected all chests!", Type = "Success", Time = 3 })
	end)
end)

local RaidSub = MainTab:AddSubTab("Raids", "shield")
local RaidGroup = RaidSub:AddLeftGroupbox("Raid Control", "zap")
local RaidSet = RaidSub:AddRightGroupbox("Raid Settings", "settings")

RaidGroup:AddToggle("AutoRaid", {
	Text = "Auto Raid",
	Default = false,
	Callback = function(v) STATE.AutoRaid = v end,
}):AddKeyPicker("AutoRaidKey", {
	Default = "None", Text = "Raid Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

RaidGroup:AddButton("Start Raid", function()
	pcall(function()
		CommF:InvokeServer("RaidsNpc", "Select", STATE.RaidType)
		task.wait(1)
		CommF:InvokeServer("RaidsNpc", "Start")
	end)
end)

RaidGroup:AddButton("Buy Raid Chip", function()
	pcall(function() CommF:InvokeServer("RaidsNpc", "Buy", STATE.RaidType) end)
end)

RaidSet:AddDropdown("RaidType", {
	Values = { "Light", "Dark", "Magma", "Quake", "Human", "Snow", "Ice", "Flame", "Bird", "Dragon" },
	Default = "Light", Text = "Raid Type",
	Callback = function(v) STATE.RaidType = v end,
})

local CombatSub = CombatTab:AddSubTab("Bounty", "crosshair")
local BountyGroup = CombatSub:AddLeftGroupbox("Bounty Farm", "target")
local BountySet = CombatSub:AddRightGroupbox("Settings", "sliders")

BountyGroup:AddToggle("AutoBounty", {
	Text = "Auto Bounty Farm",
	Default = false,
	Risky = true,
	Callback = function(v)
		STATE.AutoBounty = v
		if v then
			attachFloat()
			task.spawn(autoAttackLoop)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("BountyKey", {
	Default = "None", Text = "Bounty Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

BountyGroup:AddButton("Stop Bounty", function()
	STATE.AutoBounty = false
	detachFloat()
end)

BountySet:AddSlider("BountyDist", {
	Text = "Follow Distance", Default = 20, Min = 5, Max = 50, Rounding = 0,
	Callback = function(v) STATE.BountyDistance = v end,
})

local StatsSub = CombatTab:AddSubTab("Stats", "bar-chart")
local StatsGroup = StatsSub:AddLeftGroupbox("Auto Stats", "cpu")

StatsGroup:AddToggle("AutoStats", {
	Text = "Auto Allocate Stats",
	Default = false,
	Callback = function(v)
		STATE.AutoStats = v
		if v then
			task.spawn(function()
				while STATE.AutoStats do
					pcall(function() CommF:InvokeServer("AddPoint", STATE.StatType, STATE.StatAmount) end)
					task.wait(0.5)
				end
			end)
		end
	end,
}):AddKeyPicker("AutoStatsKey", {
	Default = "None", Text = "Stats Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

StatsGroup:AddDropdown("StatType", {
	Values = { "Melee", "Defense", "Sword", "Gun", "Demon Fruit" }, Default = "Melee", Text = "Stat Type",
	Callback = function(v) STATE.StatType = v end,
})

StatsGroup:AddSlider("StatAmount", {
	Text = "Points Per Click", Default = 1, Min = 1, Max = 100, Rounding = 0,
	Callback = function(v) STATE.StatAmount = v end,
})

StatsGroup:AddButton("Reset Stats", function()
	pcall(function() CommF:InvokeServer("BuyTrait", "Reset") end)
end)

local TeleSub1 = TeleportTab:AddSubTab("Islands", "map-pin")
local Sea1Group = TeleSub1:AddLeftGroupbox("Sea 1", "compass")
local Sea2Group = TeleSub1:AddRightGroupbox("Sea 2", "compass")

for _, island in ipairs({"Windmill", "MarineStart", "Jungle", "Pirate", "Desert", "Ice", "MarineBase", "Sky", "Prison", "Colosseum", "Magma", "Fishmen", "Fountain"}) do
	Sea1Group:AddButton(island, function() teleportToIsland(island) end)
end

for _, island in ipairs({"DarkArea", "Cafe", "Ship", "Usoapp", "Forgotten", "Cursed", "Hydra", "Roundtable", "Mansion", "Castle", "Temple"}) do
	Sea2Group:AddButton(island, function() teleportToIsland(island) end)
end

local TeleSub2 = TeleportTab:AddSubTab("NPCs", "user")
local QuestNPCGroup = TeleSub2:AddLeftGroupbox("Quest NPCs", "scroll")
local ShopNPCGroup = TeleSub2:AddRightGroupbox("Shop NPCs", "shopping-cart")

for _, npc in ipairs({"BanditQuest1", "MarineQuest", "JungleQuest", "BuggyQuest1", "DesertQuest", "SnowQuest", "MarineQuest2", "SkyQuest", "PrisonerQuest", "ColosseumQuest", "MagmaQuest", "FishmanQuest"}) do
	QuestNPCGroup:AddButton(npc, function()
		pcall(function() CommF:InvokeServer("StartQuest", npc) end)
	end)
end

for _, npc in ipairs({"Sword Dealer", "Archangel", "Master of Enhancement", "Expert Swordsman", "Blox Fruits Dealer"}) do
	ShopNPCGroup:AddButton(npc, function()
		pcall(function() CommF:InvokeServer("Buy" .. npc:gsub(" ", "")) end)
	end)
end

local ESPSub = VisualsTab:AddSubTab("ESP", "eye")
local ESPGroup = ESPSub:AddLeftGroupbox("Player ESP", "users")
local WorldESP = ESPSub:AddRightGroupbox("World ESP", "globe")

ESPGroup:AddToggle("ESPEnabled", {
	Text = "Enable ESP",
	Default = false,
	Callback = function(v)
		STATE.ESP = v
		if v then
			task.spawn(function()
				while STATE.ESP do updateESP(); task.wait(2) end
			end)
		else
			clearESP()
		end
	end,
}):AddKeyPicker("ESPKey", {
	Default = "None", Text = "ESP Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

ESPGroup:AddToggle("ESPPlayers", {
	Text = "Player ESP", Default = false,
	Callback = function(v) STATE.ESPPlayers = v end,
})

WorldESP:AddToggle("ESPFruits", {
	Text = "Fruit ESP", Default = false,
	Callback = function(v) STATE.ESPFruits = v end,
})

WorldESP:AddToggle("ESPChests", {
	Text = "Chest ESP", Default = false,
	Callback = function(v) STATE.ESPChests = v end,
})

ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = Color3.fromRGB(255, 100, 100), Title = "ESP Color",
	Callback = function(v) STATE.ESPColor = v end,
})

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

local MoveSub = PlayerTab:AddSubTab("Movement", "move")
local SpeedGroup = MoveSub:AddLeftGroupbox("Speed", "zap")
local JumpGroup = MoveSub:AddRightGroupbox("Jump", "arrow-up")

SpeedGroup:AddToggle("SpeedBoost", {
	Text = "Speed Boost", Risky = true, Default = false,
	Callback = function(v)
		if v then
			task.spawn(function()
				while Toggles.SpeedBoost and Toggles.SpeedBoost.Value do
					pcall(function() local h = getHum(); if h then h.WalkSpeed = STATE.WalkSpeed end end)
					task.wait(0.1)
				end
			end)
		else
			pcall(function() local h = getHum(); if h then h.WalkSpeed = 16 end end)
		end
	end,
}):AddKeyPicker("SpeedKey", {
	Default = "None", Text = "Speed Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SpeedGroup:AddSlider("WalkSpeed", {
	Text = "Walk Speed", Default = 16, Min = 16, Max = 325, Rounding = 0,
	Callback = function(v) STATE.WalkSpeed = v end,
})

JumpGroup:AddToggle("InfJump", {
	Text = "Infinite Jump", Default = false,
	Callback = function(v) STATE.InfiniteJump = v; setInfiniteJump(v) end,
}):AddKeyPicker("InfJumpKey", {
	Default = "None", Text = "Jump Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

JumpGroup:AddToggle("Noclip", {
	Text = "Noclip", Default = false,
	Callback = function(v) STATE.Noclip = v; setNoclip(v) end,
}):AddKeyPicker("NoclipKey", {
	Default = "None", Text = "Noclip Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

local MiscSub = PlayerTab:AddSubTab("Misc", "settings")
local MiscGroup = MiscSub:AddLeftGroupbox("Utilities", "tool")

MiscGroup:AddToggle("WalkOnWater", {
	Text = "Walk on Water", Default = false,
	Callback = function(v)
		STATE.WalkOnWater = v
		if v then
			local ww = Instance.new("Part")
			ww.Name = "IvoryWaterWalk"
			ww.Transparency = 1
			ww.CanCollide = true
			ww.Size = Vector3.new(1000, 1, 1000)
			ww.Anchored = true
			ww.Parent = Workspace
		else
			local ww = Workspace:FindFirstChild("IvoryWaterWalk")
			if ww then ww:Destroy() end
		end
	end,
}):AddKeyPicker("WaterKey", {
	Default = "None", Text = "Water Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

MiscGroup:AddToggle("AntiAFK", {
	Text = "Anti AFK", Default = false,
	Callback = function(v)
		STATE.AntiAFK = v
		if v then
			LOCAL_AFK_CONN = LocalPlayer.Idled:Connect(function()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		else
			if LOCAL_AFK_CONN then LOCAL_AFK_CONN:Disconnect() end
		end
	end,
})

MiscGroup:AddButton("Redeem All Codes", function()
	task.spawn(function()
		local ok, raw = pcall(function() return game:HttpGet("https://pastebin.com/raw/cLp2LXrs") end)
		if ok and raw then
			local codes = {}
			for code in string.gmatch(raw, "[^\r\n]+") do table.insert(codes, code) end
			local redeemRemote = Remotes:FindFirstChild("Redeem")
			for _, code in ipairs(codes) do
				pcall(function() redeemRemote:InvokeServer(code) end)
				task.wait(0.2)
			end
			Library:Notify({ Title = "Ivory", Description = "Redeemed " .. #codes .. " codes!", Type = "Success", Time = 3 })
		end
	end)
end)

MiscGroup:AddButton("Toggle Damage UI", function()
	pcall(function()
		local dmg = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("GUI"):FindFirstChild("DamageCounter")
		if dmg then dmg.Enabled = not dmg.Enabled end
	end)
end)

MiscGroup:AddButton("Toggle Notifications", function()
	pcall(function()
		local n = LocalPlayer.PlayerGui:FindFirstChild("Notifications")
		if n then n.Enabled = not n.Enabled end
	end)
end)

MiscGroup:AddButton("Buso Haki", function()
	pcall(function() CommF:InvokeServer("Buso") end)
end)

MiscGroup:AddButton("Rejoin Server", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

MiscGroup:AddButton("Server Hop", function()
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
			TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(#servers)], LocalPlayer)
		end
	end)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("bloxfruits")
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu",
	Callback = function(v) Library.KeybindFrame.Visible = v end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor", Default = Library.ShowCustomCursor,
	Callback = function(v) Library.ShowCustomCursor = v end,
})

MenuGroup:AddButton("Test Notification", function()
	Library:Notify({ Title = "Ivory", Description = "Works!", Time = 4 })
end)

MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side",
	Callback = function(v) Library:SetNotifySide(v) end,
})

MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale",
	Callback = function(v) Library:SetDPIScale(tonumber(v:gsub("%%", ""))) end,
})

MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius", Default = Library.CornerRadius, Min = 0, Max = 20, Rounding = 0,
	Callback = function(v) Window:SetCornerRadius(v) end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift", NoUI = true, Text = "Menu keybind",
})
MenuGroup:AddButton("Unload", function()
	clearESP()
	setNoclip(false)
	setInfiniteJump(false)
	detachFloat()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

pcall(function()
	CommF:InvokeServer("Buso")
end)

print("[BF] Script complete!")
Library:Notify({
	Title = "Ivory",
	Description = "v1.4 loaded successfully",
	Type = "Success",
	Time = 5,
})
