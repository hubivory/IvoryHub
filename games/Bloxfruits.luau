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
	RegisterAttack = Net and Net:WaitForChild("RE/RegisterAttack", 10)
	RegisterHit = Net and Net:WaitForChild("RE/RegisterHit", 10)
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

local Monster, NameQuest, LevelQuest, NameCheckQuest, CFrameQ, CFrameMon

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
	AutoFruit = false,
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
			moveTo(workspace.Map.TeleportSpawn.ExitPoint.Position)
		else
			moveTo(workspace.Map.TeleportSpawn.EntrancePoint.Position)
		end
		return
	end
	local islandModel = map:FindFirstChild(island)
	if islandModel and islandModel:GetPivot() then
		moveTo(islandModel:GetPivot().Position + Vector3.new(0, 50, 0))
	end
end

local function moveTo(position)
	local hrp = getHRP()
	if not hrp then return end
	local dist = (hrp.Position - position).Magnitude
	if dist < 3 then return end
	local stepSize = math.clamp(dist / 8, 15, 100)
	local steps = math.clamp(math.ceil(dist / stepSize), 1, 30)
	for i = 1, steps do
		if not getHRP() or not STATE.AutoFarm and not STATE.AutoChest and not STATE.AutoBounty and not STATE.AutoFruit then return end
		local alpha = i / steps
		local targetCFrame = CFrame.new(hrp.Position:Lerp(position, alpha)) * (hrp.CFrame - hrp.CFrame.Position)
		hrp.CFrame = targetCFrame
		task.wait()
	end
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

local EquipWeapon = equipWeapon

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

local function CheckQuest()
	local level = getLevel()
	if level >= 0 and level <= 9 then
		Monster = "Bandit" NameQuest = "BanditQuest1" LevelQuest = 1 NameCheckQuest = "Bandit" CFrameQ = CFrame.new(1060,17,1547) CFrameMon = CFrame.new(1145,17,1634)
	elseif level >= 10 and level <= 14 then
		Monster = "Monkey" NameQuest = "JungleQuest" LevelQuest = 1 NameCheckQuest = "Monkey" CFrameQ = CFrame.new(-1602,37,152) CFrameMon = CFrame.new(-1496,39,35)
	elseif level >= 15 and level <= 29 then
		Monster = "Gorilla" NameQuest = "JungleQuest" LevelQuest = 2 NameCheckQuest = "Gorilla" CFrameQ = CFrame.new(-1602,37,152) CFrameMon = CFrame.new(-1237,6,-486)
	elseif level >= 30 and level <= 39 then
		Monster = "Pirate" NameQuest = "BuggyQuest1" LevelQuest = 1 NameCheckQuest = "Pirate" CFrameQ = CFrame.new(-1140,5,3828) CFrameMon = CFrame.new(-1115,14,3938)
	elseif level >= 40 and level <= 59 then
		Monster = "Brute" NameQuest = "BuggyQuest1" LevelQuest = 2 NameCheckQuest = "Brute" CFrameQ = CFrame.new(-1140,5,3828) CFrameMon = CFrame.new(-1145,15,4350)
	elseif level >= 60 and level <= 74 then
		Monster = "Desert Bandit" NameQuest = "DesertQuest" LevelQuest = 1 NameCheckQuest = "Desert Bandit" CFrameQ = CFrame.new(897,7,4388) CFrameMon = CFrame.new(932,7,4484)
	elseif level >= 75 and level <= 89 then
		Monster = "Desert Officer" NameQuest = "DesertQuest" LevelQuest = 2 NameCheckQuest = "Desert Officers" CFrameQ = CFrame.new(897,7,4388) CFrameMon = CFrame.new(1572,10,4373)
	elseif level >= 90 and level <= 99 then
		Monster = "Snow Bandit" NameQuest = "SnowQuest" LevelQuest = 1 NameCheckQuest = "Snow Bandits" CFrameQ = CFrame.new(1386,87,-1297) CFrameMon = CFrame.new(1289,150,-1442)
	elseif level >= 100 and level <= 119 then
		Monster = "Snowman" NameQuest = "SnowQuest" LevelQuest = 2 NameCheckQuest = "Snowman" CFrameQ = CFrame.new(1386,87,-1297) CFrameMon = CFrame.new(1289,150,-1442)
	elseif level >= 120 and level <= 149 then
		Monster = "Chief Petty Officer" NameQuest = "MarineQuest2" LevelQuest = 1 NameCheckQuest = "Chief Petty Officer" CFrameQ = CFrame.new(-5036,29,4325) CFrameMon = CFrame.new(-4855,23,4308)
	elseif level >= 150 and level <= 174 then
		Monster = "Sky Bandit" NameQuest = "SkyQuest" LevelQuest = 1 NameCheckQuest = "Sky Bandit" CFrameQ = CFrame.new(-4842,718,-2623) CFrameMon = CFrame.new(-4981,278,-2830)
	elseif level >= 175 and level <= 189 then
		Monster = "Dark Master" NameQuest = "SkyQuest" LevelQuest = 2 NameCheckQuest = "Dark Master" CFrameQ = CFrame.new(-4842,718,-2623) CFrameMon = CFrame.new(-5250,389,-2272)
	elseif level >= 190 and level <= 209 then
		Monster = "Prisoner" NameQuest = "PrisonerQuest" LevelQuest = 1 NameCheckQuest = "Prisoners" CFrameQ = CFrame.new(5308,2,474) CFrameMon = CFrame.new(5411,96,690)
	elseif level >= 210 and level <= 249 then
		Monster = "Dangerous Prisoner" NameQuest = "PrisonerQuest" LevelQuest = 2 NameCheckQuest = "Dangerous Prisoner" CFrameQ = CFrame.new(5308,2,474) CFrameMon = CFrame.new(5411,96,690)
	elseif level >= 250 and level <= 299 then
		Monster = "Toga Warrior" NameQuest = "ColosseumQuest" LevelQuest = 1 NameCheckQuest = "Toga Warrior" CFrameQ = CFrame.new(-1576,8,-2985) CFrameMon = CFrame.new(-1641,7,-2864)
	elseif level >= 300 and level <= 329 then
		Monster = "Military Soldier" NameQuest = "MagmaQuest" LevelQuest = 1 NameCheckQuest = "Military Soldier" CFrameQ = CFrame.new(-5316,12,8517) CFrameMon = CFrame.new(-5408,11,8447)
	elseif level >= 330 and level <= 374 then
		Monster = "Military Spy" NameQuest = "MagmaQuest" LevelQuest = 2 NameCheckQuest = "Military Spy" CFrameQ = CFrame.new(-5316,12,8517) CFrameMon = CFrame.new(-5815,84,8820)
	elseif level >= 375 and level <= 399 then
		Monster = "Fishman Warrior" NameQuest = "FishmanQuest" LevelQuest = 1 NameCheckQuest = "Fishman Warrior" CFrameQ = CFrame.new(61123,19,1569) CFrameMon = CFrame.new(60859,19,1501)
	elseif level >= 400 and level <= 449 then
		Monster = "Fishman Commando" NameQuest = "FishmanQuest" LevelQuest = 2 NameCheckQuest = "Fishman Commando" CFrameQ = CFrame.new(61123,19,1569) CFrameMon = CFrame.new(61891,19,1470)
	elseif level >= 450 and level <= 474 then
		Monster = "God's Guard" NameQuest = "SkyExp1Quest" LevelQuest = 1 NameCheckQuest = "God's Guards" CFrameQ = CFrame.new(-4722,845,-1954) CFrameMon = CFrame.new(-4698,845,-1912)
	elseif level >= 475 and level <= 524 then
		Monster = "Shanda" NameQuest = "SkyExp1Quest" LevelQuest = 2 NameCheckQuest = "Shandas" CFrameQ = CFrame.new(-7862,5546,-380) CFrameMon = CFrame.new(-7685,5567,-502)
	elseif level >= 525 and level <= 549 then
		Monster = "Royal Squad" NameQuest = "SkyExp2Quest" LevelQuest = 1 NameCheckQuest = "Royal Squad" CFrameQ = CFrame.new(-7904,5636,-1412) CFrameMon = CFrame.new(-7670,5607,-1460)
	elseif level >= 550 and level <= 624 then
		Monster = "Royal Soldier" NameQuest = "SkyExp2Quest" LevelQuest = 2 NameCheckQuest = "Royal Soldier" CFrameQ = CFrame.new(-7904,5636,-1412) CFrameMon = CFrame.new(-7828,5607,-1744)
	elseif level >= 625 and level <= 649 then
		Monster = "Galley Pirate" NameQuest = "FountainQuest" LevelQuest = 1 NameCheckQuest = "Galley Pirate" CFrameQ = CFrame.new(5256,39,4050) CFrameMon = CFrame.new(5589,45,3996)
	elseif level >= 650 and level <= 850 then
		Monster = "Galley Captain" NameQuest = "FountainQuest" LevelQuest = 2 NameCheckQuest = "Galley Captain" CFrameQ = CFrame.new(5256,39,4050) CFrameMon = CFrame.new(5649,39,4936)
	end
end

local v106 = tostring(LocalPlayer.UserId):sub(2, 4) .. tostring(coroutine.running()):sub(11, 15)
local seed = ReplicatedStorage.Modules.Net.seed:InvokeServer() * 2
local AttackRotation = 0
local LastRotate = 0
local LastAttackTime = 0

local r = nil
task.spawn(function()
	while task.wait() do
		local paths = {ReplicatedStorage.Util, ReplicatedStorage.Remotes, ReplicatedStorage.Assets, ReplicatedStorage.Common, ReplicatedStorage.FX}
		for _, v in paths do
			for _, v1 in v:GetChildren() do
				if v1:GetAttribute("Id") and v1:IsA("RemoteEvent") then
					r = v1
					break
				end
			end
		end
	end
end)

local function IsOwn(name)
	if LocalPlayer.Backpack:FindFirstChild(name) then
		return LocalPlayer.Backpack:FindFirstChild(name)
	end
	local k
	for _, v in LocalPlayer.Character:GetChildren() do
		if v:IsA("Tool") and v.Name == name then
			k = v
		end
	end
	return k or LocalPlayer.Character:FindFirstChild(name)
end

local function Attack(v)
	if tick() - LastAttackTime >= 0.2 then
		if not LocalPlayer.Character:FindFirstChild("HasBuso") then
			CommF:InvokeServer("Buso")
		end
		local h = "RE/RegisterHit"
		local key = math.floor(workspace:GetServerTimeNow() / 10 % 10)
		local encoded = ""
		for i = 1, #h do
			encoded = encoded .. string.char(bit32.bxor(string.byte(h, i), key + 1))
		end
		if type(v) == "table" then
			RegisterAttack:FireServer(0)
			r:FireServer(encoded, bit32.bxor(r:GetAttribute("Id") + 909090, seed), v[1]:FindFirstChild("Head"), {{v[1], v[1]:FindFirstChild("Head")}, v[1], {v[2], v[2]:FindFirstChild("Head")}, v[2]}, nil, v106)
			RegisterHit:FireServer(v[1]:FindFirstChild("Head"), {{v[1], v[1]:FindFirstChild("Head")}, v[1], {v[2], v[2]:FindFirstChild("Head")}, v[2]}, nil, v106)
		else
			RegisterAttack:FireServer(0)
			r:FireServer(encoded, bit32.bxor(r:GetAttribute("Id") + 909090, seed), v:FindFirstChild("Head"), {v, v:FindFirstChild("Head")}, v106)
			RegisterHit:FireServer(v:FindFirstChild("Head"), {v, v:FindFirstChild("Head")}, v106)
		end
		LastAttackTime = tick()
	end
end

local function BringMob(target)
	pcall(sethiddenproperty, LocalPlayer, "SimulationRadius", math.huge)
	local acf = target.HumanoidRootPart.CFrame
	local targets = {target}
	for _, v in ipairs(workspace.Enemies:GetChildren()) do
		if v.Name == target.Name and v ~= target and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 and (acf.Position - v.HumanoidRootPart.Position).Magnitude <= 350 then
			local bv = v.HumanoidRootPart:FindFirstChild("BringVelocity")
			if not bv then
				bv = Instance.new("BodyVelocity")
				bv.Name = "BringVelocity"
				bv.MaxForce = Vector3.new(10000, 10000, 10000)
				bv.Parent = v.HumanoidRootPart
			end
			bv.Velocity = Vector3.zero
			v.HumanoidRootPart.CFrame = acf
			table.insert(targets, v)
			break
		end
	end
	return targets
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

local FarmSub = MainTab:AddSubTab("Farming", "zap")
local FarmGroup = FarmSub:AddLeftGroupbox("Auto Farm", "cpu")
local ChestGroup = FarmSub:AddRightGroupbox("Chests", "package")

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
						CheckQuest()
						local Quest = LocalPlayer.PlayerGui.Main.Quest
						local QuestTitle = Quest.Container.QuestTitle
						local hrp = getHRP()
						if not hrp then return end

						if not Quest.Visible then
							if (CFrameQ.Position - hrp.Position).Magnitude > 150 then
								moveTo(CFrameQ.Position)
							else
								CommF:InvokeServer("StartQuest", NameQuest, LevelQuest)
							end
						else
							if workspace.Enemies:FindFirstChild(Monster) then
								for _, v in pairs(workspace.Enemies:GetChildren()) do
									if v.Name == Monster and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
										if string.find(QuestTitle.Title.Text, NameCheckQuest) then
											local mobHRP = v.HumanoidRootPart
											v.Humanoid.JumpPower = 0
											v.Humanoid.WalkSpeed = 0
											mobHRP.CanCollide = false

											local targets = BringMob(v)
											local myHRP = getHRP()
											if not myHRP then return end
											local dist = (myHRP.Position - mobHRP.Position).Magnitude

											if dist > 150 then
												moveTo(mobHRP.Position + Vector3.new(0, 30, 0))
											else
												EquipWeapon(STATE.SelectedWeapon)
												if tick() - LastRotate >= 0.25 then
													AttackRotation = (AttackRotation + 180) % 360
													LastRotate = tick()
												end
												myHRP.CFrame = mobHRP.CFrame * CFrame.new(0, 30, 0) * CFrame.Angles(0, math.rad(AttackRotation), 0)
												if #targets >= 2 then
													Attack({targets[1], targets[2]})
												else
													Attack(v)
												end
											end
											break
										else
											CommF:InvokeServer("AbandonQuest")
										end
									end
								end
							else
								moveTo(CFrameMon.Position)
							end
						end
						for _, bodypart in ipairs(Character:GetChildren()) do
							if bodypart:IsA("BasePart") then bodypart.CanCollide = false end
						end
					end)
					task.wait(0.1)
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("AutoFarmKey", {
	Default = "None", Text = "Auto Farm Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

FarmGroup:AddDropdown("FarmMethod", {
	Values = { "Quest", "Nearest" }, Default = "Quest", Text = "Farm Method",
	Callback = function(v) STATE.AutoFarmMethod = v end,
})

FarmGroup:AddDropdown("WeaponType", {
	Values = { "Melee", "Sword", "Gun", "Blox Fruit" }, Default = "Melee", Text = "Weapon Type",
	Callback = function(v) STATE.SelectedWeapon = v end,
})

FarmGroup:AddButton("Refresh Quest", function()
	pcall(function() CheckQuest() end)
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
								if chest:IsA("Model") and STATE.AutoChest then
									local part = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
									if part then
										moveTo(part.Position)
									end
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
					local part = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
					if part then
						moveTo(part.Position)
					end
				end
			end
		end
		Library:Notify({ Title = "Ivory", Description = "Collected all chests!", Type = "Success", Time = 3 })
	end)
end)

local FruitGroup = FarmSub:AddLeftGroupbox("Fruits", "apple")
FruitGroup:AddToggle("AutoFruit", {
	Text = "Auto Collect Fruits",
	Default = false,
	Callback = function(v)
		STATE.AutoFruit = v
		if v then
			task.spawn(function()
				while STATE.AutoFruit do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						for _, obj in ipairs(Workspace:GetChildren()) do
							if obj:IsA("Tool") and STATE.AutoFruit then
								local handle = obj:FindFirstChild("Handle")
								if handle then
									moveTo(handle.Position)
								end
							end
						end
						local map = Workspace:FindFirstChild("Map")
						if map then
							for _, obj in ipairs(map:GetDescendants()) do
								if obj:IsA("Tool") and STATE.AutoFruit then
									local handle = obj:FindFirstChild("Handle")
									if handle then
										moveTo(handle.Position)
									end
								end
							end
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
}):AddKeyPicker("AutoFruitKey", {
	Default = "None", Text = "Fruit Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})
FruitGroup:AddLabel("Automatically tweens to spawned fruits")

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

Library:Notify({
	Title = "Ivory",
	Description = "v1.4 loaded successfully",
	Type = "Success",
	Time = 5,
})
