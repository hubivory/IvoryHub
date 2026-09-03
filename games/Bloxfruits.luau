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
local VIM = game:GetService("VirtualInputManager")
local CollectionService = game:GetService("CollectionService")

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
local CommE = Remotes and Remotes:WaitForChild("CommE", 10)
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
	AutoStoreFruit = false,
	CollectingFruit = false,
	LastFruitSeen = os.time() - math.floor(workspace.DistributedGameTime),
	FruitRespawnTime = 2700,
	AutoSkill = false,
	SkillZ = true,
	SkillX = true,
	SkillC = true,
	SkillV = true,
}

-- New STATE variables (merged from FourHub)
STATE.AutoKen = false
STATE.AutoTeam = "Pirates"
STATE.SelectedBoss = "All"
STATE.SelectedMaterial = "Leather + Scrap Metal"
STATE.AutoBone = false
STATE.AutoCakePrince = false
STATE.AutoFactory = false
STATE.AutoPirateRaid = false
STATE.AutoMastery = false
STATE.MasteryType = "Fruit"
STATE.AutoKillNearest = false
STATE.BringRange = 235
STATE.MaxBringMobs = 3
STATE.FarmHeight = 20
STATE.MobHealthThreshold = 0
STATE.SeaEvents = false
STATE.SeaEventMode = "Shark"
STATE.AutoFrozen = false
STATE.AutoKitsune = false
STATE.AutoPrehistoric = false
STATE.AutoMirage = false
STATE.AutoEliteHunter = false
STATE.AutoYama = false
STATE.AutoTushita = false
STATE.AutoCDK = false
STATE.AutoSwan = false
STATE.AutoCanvendish = false
STATE.AutoBigmom = false
STATE.AutoRengoku = false
STATE.AutoPoleV2 = false
STATE.AutoSoulGuitar = false
STATE.AutoSaber = false
STATE.RaceV4Temple = false
STATE.RaceV4PullLever = false
STATE.RaceV4Train = false
STATE.RaceV4Trials = false
STATE.RaceV4Moon = false
STATE.AutoFruitSniper = false
STATE.SniperFruit = "Dragon"
STATE.AutoRandomFruit = false
STATE.AutoDropFruit = false
STATE.FruitStockCheck = false
STATE.ADVStockCheck = false
STATE.Autofish = false
STATE.ESPIsland = false
STATE.ESPFlower = false
STATE.ESPGear = false
STATE.ESPAdvDealer = false
STATE.ESPHakiColor = false
STATE.ESPBerry = false
STATE.AutoClick = false
STATE.ToggleCombat = false
STATE.KillAura = false
STATE.AimMethod = "AimBot Skill"
STATE.InfiniteEnergy = false
STATE.InfiniteSoru = false
STATE.InfiniteObservation = false
STATE.AutoBuso = false
STATE.AutoV3 = false
STATE.AutoV4 = false
STATE.BuyMelee = "None"
STATE.BuySword = "None"
STATE.BuyAccessory = "None"
STATE.BuyHaki = "None"
STATE.ChangeRace = "None"
STATE.CraftItem = "None"
STATE.AdminHop = false
STATE.FastAttackMode = "Fast Attack"
STATE.LowCPU = false
STATE.FruitSkills = { Z = false, X = false, C = false, V = false, F = false }
STATE.TweenSpeedFar = 300
STATE.TweenSpeedNear = 900
STATE.ClickDelay = 0.1
STATE.GunAuraRange = 500
STATE.GunAuraEnabled = false

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

local function BTP(Point)
	pcall(function()
		local hrp = getHRP()
		if not hrp then return end
		local hum = getHum()
		if not hum then return end
		if (Point.Position - hrp.Position).Magnitude < 1500 then return end
		if hum.Health <= 0 then
			repeat task.wait() until hum.Health > 0
			task.wait(0.2)
		end
		hrp.CFrame = Point
		task.wait(0.1)
		hum.Health = 0
		task.wait(1.5)
		hrp = getHRP()
		if hrp then
			hrp.CFrame = Point
			task.wait(0.1)
		end
	end)
end

local IslandNameMap = {
	Windmill = "Windmill", MarineStart = "MarineStart", Jungle = "Jungle",
	Pirate = "Pirate", Desert = "Desert", Ice = "Frozen",
	MarineBase = "MarineBase", Sky = "Sky", Prison = "Prison",
	Colosseum = "Colosseum", Magma = "Magma", Fishmen = "Fishman", Fountain = "Fountain",
	DarkArea = "DarkArea", Cafe = "Cafe", Ship = "Ship",
	Usoapp = "Usoapp", Forgotten = "Forgotten", Cursed = "Cursed",
	Hydra = "Hydra", Roundtable = "Roundtable", Mansion = "Mansion",
	Castle = "Castle", Temple = "Temple",
}

local function teleportToIsland(island)
	local hrp = getHRP()
	if not hrp then return end
	local map = Workspace:FindFirstChild("Map")
	if not map then return end

	if island == "Fishmen" or island == "Fishman" then
		if isOnIsland("Fishmen") or isOnIsland("Fishman") then
			pcall(function() toTarget(workspace.Map.TeleportSpawn.ExitPoint.Position) end)
		else
			pcall(function() CommF:InvokeServer("requestEntrance", Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)) end)
		end
		return
	end

	if island == "Sky" then
		pcall(function() CommF:InvokeServer("requestEntrance", Vector3.new(-4607.82275, 872.54248, -1667.55688)) end)
		task.wait(1)
	end

	local mapped = IslandNameMap[island] or island
	local islandModel = map:FindFirstChild(mapped)
	if not islandModel then
		for _, child in ipairs(map:GetChildren()) do
			if child.Name:lower():find(mapped:lower()) then
				islandModel = child
				break
			end
		end
	end
	if islandModel then
		toTarget(islandModel:GetPivot().Position + Vector3.new(0, 50, 0))
	end
end

local tweenActive = nil

local function toTarget(Pos)
	local hrp = getHRP()
	if not hrp then return end
	local hum = getHum()
	if not hum then return end

	if hum.Health <= 0 then
		if tweenActive then pcall(function() tweenActive:Cancel() end) end
		repeat task.wait() until getHum() and getHum().Health > 0
		task.wait(0.2)
		hrp = getHRP()
		if not hrp then return end
	end

	pcall(function() hum.Sit = false end)

	local RealTarget
	if typeof(Pos) == "Vector3" then
		RealTarget = CFrame.new(Pos)
	elseif typeof(Pos) == "CFrame" then
		RealTarget = Pos
	else
		return
	end

	local dist = (RealTarget.Position - hrp.Position).Magnitude
	if dist < 10 then
		hrp.CFrame = RealTarget
		return
	end

	local speed = 315
	local origin = hrp.Position
	local target = RealTarget.Position
	local flyHeight = math.max(origin.Y, target.Y) + 80

	-- If we're close horizontally or already high enough, just tween directly
	if math.abs(origin.Y - target.Y) < 30 or (math.abs(origin.X - target.X) < 50 and math.abs(origin.Z - target.Z) < 50) then
		local tweenInfo = TweenInfo.new(dist / speed, Enum.EasingStyle.Linear)
		pcall(function()
			tweenActive = TweenService:Create(hrp, tweenInfo, {CFrame = RealTarget})
			tweenActive:Play()
		end)
		return
	end

	-- Phase 1: Fly straight up to safe height
	local upEnd = CFrame.new(Vector3.new(origin.X, flyHeight, origin.Z))
	local upDist = (flyHeight - origin.Y)
	if upDist > 5 then
		local upTween = TweenInfo.new(upDist / speed, Enum.EasingStyle.Linear)
		pcall(function()
			tweenActive = TweenService:Create(hrp, upTween, {CFrame = upEnd})
			tweenActive:Play()
			tweenActive.Completed:Wait()
		end)
	end

	-- Phase 2: Fly horizontally to target XZ
	hrp = getHRP()
	if not hrp then return end
	local midEnd = CFrame.new(Vector3.new(target.X, flyHeight, target.Z))
	local hDist = (Vector3.new(target.X, 0, target.Z) - Vector3.new(origin.X, 0, origin.Z)).Magnitude
	if hDist > 5 then
		local hTween = TweenInfo.new(hDist / speed, Enum.EasingStyle.Linear)
		pcall(function()
			tweenActive = TweenService:Create(hrp, hTween, {CFrame = midEnd})
			tweenActive:Play()
			tweenActive.Completed:Wait()
		end)
	end

	-- Phase 3: Drop down to target
	hrp = getHRP()
	if not hrp then return end
	local downDist = (flyHeight - target.Y)
	if downDist > 5 then
		local downTween = TweenInfo.new(downDist / speed, Enum.EasingStyle.Linear)
		pcall(function()
			tweenActive = TweenService:Create(hrp, downTween, {CFrame = RealTarget})
			tweenActive:Play()
			tweenActive.Completed:Wait()
		end)
	end

	hrp = getHRP()
	if hrp then
		hrp.CFrame = RealTarget
	end
end

local function GetIsLand(...)
	local RealtargetPos = {...}
	local targetPos = RealtargetPos[1]
	local RealTarget
	if typeof(targetPos) == "Vector3" then
		RealTarget = targetPos
	elseif typeof(targetPos) == "CFrame" then
		RealTarget = targetPos.Position
	end
	local ReturnValue
	local CheckInOut = math.huge
	if LocalPlayer.Team then
		local spawns = Workspace._WorldOrigin.PlayerSpawns:FindFirstChild(tostring(LocalPlayer.Team))
		if spawns then
			for _, v in pairs(spawns:GetChildren()) do
				local ReMagnitude = (RealTarget - v:GetModelCFrame().p).Magnitude
				if ReMagnitude < CheckInOut then
					CheckInOut = ReMagnitude
					ReturnValue = v.Name
				end
			end
		end
	end
	return ReturnValue
end

local function loadEnemy(enemyName)
	local origin = Workspace:FindFirstChild("_WorldOrigin")
	if not origin then return nil end
	local spawns = origin:FindFirstChild("EnemySpawns")
	if not spawns then return nil end
	for _, spawn in ipairs(spawns:GetChildren()) do
		local cleanName = spawn.Name:gsub("%[Lv%.%s*%d+%]%s*", ""):gsub("%s+$", "")
		if cleanName == enemyName then
			toTarget(spawn.Position + Vector3.new(0, 20, 0))
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

local function useSkills(targetPos)
	if not STATE.AutoSkill then return end
	pcall(function()
		local char = LocalPlayer.Character
		if not char then return end
		local fruitTool = char:FindFirstChildOfClass("Tool")
		if not fruitTool then return end

		local remote = fruitTool:FindFirstChild("RemoteEvent")
		if not remote then return end

		local keys = {}
		if STATE.SkillZ then table.insert(keys, "Z") end
		if STATE.SkillX then table.insert(keys, "X") end
		if STATE.SkillC then table.insert(keys, "C") end
		if STATE.SkillV then table.insert(keys, "V") end

		for _, key in ipairs(keys) do
			remote:FireServer(targetPos)
			VIM:SendKeyEvent(true, key, false, game)
			task.wait(0.1)
			VIM:SendKeyEvent(false, key, false, game)
			task.wait(0.15)
		end
	end)
end

local EntranceCF = nil
local function CheckQuest()
	EntranceCF = nil
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
		Monster = "Sky Bandit" NameQuest = "SkyQuest" LevelQuest = 1 NameCheckQuest = "Sky Bandit" CFrameQ = CFrame.new(-4842,718,-2623) CFrameMon = CFrame.new(-4981,278,-2830) EntranceCF = Vector3.new(-4607.82275, 872.54248, -1667.55688)
	elseif level >= 175 and level <= 189 then
		Monster = "Dark Master" NameQuest = "SkyQuest" LevelQuest = 2 NameCheckQuest = "Dark Master" CFrameQ = CFrame.new(-4842,718,-2623) CFrameMon = CFrame.new(-5250,389,-2272) EntranceCF = Vector3.new(-4607.82275, 872.54248, -1667.55688)
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
		Monster = "Fishman Warrior" NameQuest = "FishmanQuest" LevelQuest = 1 NameCheckQuest = "Fishman Warrior" CFrameQ = CFrame.new(61123,19,1569) CFrameMon = CFrame.new(60859,19,1501) EntranceCF = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)
	elseif level >= 400 and level <= 449 then
		Monster = "Fishman Commando" NameQuest = "FishmanQuest" LevelQuest = 2 NameCheckQuest = "Fishman Commando" CFrameQ = CFrame.new(61123,19,1569) CFrameMon = CFrame.new(61891,19,1470) EntranceCF = Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)
	elseif level >= 450 and level <= 474 then
		Monster = "God's Guard" NameQuest = "SkyExp1Quest" LevelQuest = 1 NameCheckQuest = "God's Guards" CFrameQ = CFrame.new(-4722,845,-1954) CFrameMon = CFrame.new(-4698,845,-1912) EntranceCF = Vector3.new(-4607.82275, 872.54248, -1667.55688)
	elseif level >= 475 and level <= 524 then
		Monster = "Shanda" NameQuest = "SkyExp1Quest" LevelQuest = 2 NameCheckQuest = "Shandas" CFrameQ = CFrame.new(-7862,5546,-380) CFrameMon = CFrame.new(-7685,5567,-502) EntranceCF = Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047)
	elseif level >= 525 and level <= 549 then
		Monster = "Royal Squad" NameQuest = "SkyExp2Quest" LevelQuest = 1 NameCheckQuest = "Royal Squad" CFrameQ = CFrame.new(-7904,5636,-1412) CFrameMon = CFrame.new(-7670,5607,-1460) EntranceCF = Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047)
	elseif level >= 550 and level <= 624 then
		Monster = "Royal Soldier" NameQuest = "SkyExp2Quest" LevelQuest = 2 NameCheckQuest = "Royal Soldier" CFrameQ = CFrame.new(-7904,5636,-1412) CFrameMon = CFrame.new(-7828,5607,-1744) EntranceCF = Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047)
	elseif level >= 625 and level <= 649 then
		Monster = "Galley Pirate" NameQuest = "FountainQuest" LevelQuest = 1 NameCheckQuest = "Galley Pirate" CFrameQ = CFrame.new(5256,39,4050) CFrameMon = CFrame.new(5589,45,3996)
	elseif level >= 650 and level <= 699 then
		Monster = "Galley Captain" NameQuest = "FountainQuest" LevelQuest = 2 NameCheckQuest = "Galley Captain" CFrameQ = CFrame.new(5256,39,4050) CFrameMon = CFrame.new(5441,42,4950)
	elseif level >= 700 and level <= 724 then
		Monster = "Raider" NameQuest = "Area1Quest" LevelQuest = 1 NameCheckQuest = "Raider" CFrameQ = CFrame.new(-429,71,1836) CFrameMon = CFrame.new(-728,52,2345)
	elseif level >= 725 and level <= 774 then
		Monster = "Mercenary" NameQuest = "Area1Quest" LevelQuest = 2 NameCheckQuest = "Mercenary" CFrameQ = CFrame.new(-429,71,1836) CFrameMon = CFrame.new(-1004,80,1424)
	elseif level >= 775 and level <= 799 then
		Monster = "Swan Pirate" NameQuest = "Area2Quest" LevelQuest = 1 NameCheckQuest = "Swan Pirate" CFrameQ = CFrame.new(638,71,918) CFrameMon = CFrame.new(1068,137,1322)
	elseif level >= 800 and level <= 874 then
		Monster = "Factory Staff" NameQuest = "Area2Quest" LevelQuest = 2 NameCheckQuest = "Factory Staff" CFrameQ = CFrame.new(632,73,918) CFrameMon = CFrame.new(73,81,-27)
	elseif level >= 875 and level <= 899 then
		Monster = "Marine Lieutenant" NameQuest = "MarineQuest3" LevelQuest = 1 NameCheckQuest = "Marine Lieutenant" CFrameQ = CFrame.new(-2440,71,-3216) CFrameMon = CFrame.new(-2821,75,-3070)
	elseif level >= 900 and level <= 949 then
		Monster = "Marine Captain" NameQuest = "MarineQuest3" LevelQuest = 2 NameCheckQuest = "Marine Captain" CFrameQ = CFrame.new(-2440,71,-3216) CFrameMon = CFrame.new(-1861,80,-3254)
	elseif level >= 950 and level <= 974 then
		Monster = "Zombie" NameQuest = "ZombieQuest" LevelQuest = 1 NameCheckQuest = "Zombie" CFrameQ = CFrame.new(-5497,47,-795) CFrameMon = CFrame.new(-5657,78,-928)
	elseif level >= 975 and level <= 999 then
		Monster = "Vampire" NameQuest = "ZombieQuest" LevelQuest = 2 NameCheckQuest = "Vampire" CFrameQ = CFrame.new(-5497,47,-795) CFrameMon = CFrame.new(-6037,32,-1340)
	elseif level >= 1000 and level <= 1049 then
		Monster = "Snow Trooper" NameQuest = "SnowMountainQuest" LevelQuest = 1 NameCheckQuest = "Snow Trooper" CFrameQ = CFrame.new(609,400,-5372) CFrameMon = CFrame.new(549,427,-5563)
	elseif level >= 1050 and level <= 1099 then
		Monster = "Winter Warrior" NameQuest = "SnowMountainQuest" LevelQuest = 2 NameCheckQuest = "Winter Warrior" CFrameQ = CFrame.new(609,400,-5372) CFrameMon = CFrame.new(1142,475,-5199)
	elseif level >= 1100 and level <= 1124 then
		Monster = "Lab Subordinate" NameQuest = "IceSideQuest" LevelQuest = 1 NameCheckQuest = "Lab Subordinate" CFrameQ = CFrame.new(-6064,15,-4902) CFrameMon = CFrame.new(-5707,15,-4513)
	elseif level >= 1125 and level <= 1174 then
		Monster = "Horned Warrior" NameQuest = "IceSideQuest" LevelQuest = 2 NameCheckQuest = "Horned Warrior" CFrameQ = CFrame.new(-6064,15,-4902) CFrameMon = CFrame.new(-6341,15,-5723)
	elseif level >= 1175 and level <= 1199 then
		Monster = "Magma Ninja" NameQuest = "FireSideQuest" LevelQuest = 1 NameCheckQuest = "Magma Ninja" CFrameQ = CFrame.new(-5428,15,-5299) CFrameMon = CFrame.new(-5449,76,-5808)
	elseif level >= 1200 and level <= 1249 then
		Monster = "Lava Pirate" NameQuest = "FireSideQuest" LevelQuest = 2 NameCheckQuest = "Lava Pirate" CFrameQ = CFrame.new(-5428,15,-5299) CFrameMon = CFrame.new(-5213,49,-4701)
	elseif level >= 1250 and level <= 1274 then
		Monster = "Ship Deckhand" NameQuest = "ShipQuest1" LevelQuest = 1 NameCheckQuest = "Ship Deckhand" CFrameQ = CFrame.new(1037,125,32911) CFrameMon = CFrame.new(1212,150,33059) EntranceCF = Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
	elseif level >= 1275 and level <= 1299 then
		Monster = "Ship Engineer" NameQuest = "ShipQuest1" LevelQuest = 2 NameCheckQuest = "Ship Engineer" CFrameQ = CFrame.new(1037,125,32911) CFrameMon = CFrame.new(919,43,32779) EntranceCF = Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
	elseif level >= 1300 and level <= 1324 then
		Monster = "Ship Steward" NameQuest = "ShipQuest2" LevelQuest = 1 NameCheckQuest = "Ship Steward" CFrameQ = CFrame.new(968,125,33244) CFrameMon = CFrame.new(919,129,33436) EntranceCF = Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
	elseif level >= 1325 and level <= 1349 then
		Monster = "Ship Officer" NameQuest = "ShipQuest2" LevelQuest = 2 NameCheckQuest = "Ship Officer" CFrameQ = CFrame.new(968,125,33244) CFrameMon = CFrame.new(1036,181,33315) EntranceCF = Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)
	elseif level >= 1350 and level <= 1374 then
		Monster = "Arctic Warrior" NameQuest = "FrostQuest" LevelQuest = 1 NameCheckQuest = "Arctic Warrior" CFrameQ = CFrame.new(5667,26,-6486) CFrameMon = CFrame.new(5966,62,-6179) EntranceCF = Vector3.new(-6508.5581054688, 5000.034996032715, -132.83953857422)
	elseif level >= 1375 and level <= 1424 then
		Monster = "Snow Lurker" NameQuest = "FrostQuest" LevelQuest = 2 NameCheckQuest = "Snow Lurker" CFrameQ = CFrame.new(5667,26,-6486) CFrameMon = CFrame.new(5407,69,-6880)
	elseif level >= 1425 and level <= 1449 then
		Monster = "Sea Soldier" NameQuest = "ForgottenQuest" LevelQuest = 1 NameCheckQuest = "Sea Soldier" CFrameQ = CFrame.new(-3054,235,-10142) CFrameMon = CFrame.new(-3028,64,-9775)
	elseif level >= 1450 then
		Monster = "Water Fighter" NameQuest = "ForgottenQuest" LevelQuest = 2 NameCheckQuest = "Water Fighter" CFrameQ = CFrame.new(-3054,235,-10142) CFrameMon = CFrame.new(-3352,285,-10534)
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
	if not RegisterAttack or not RegisterHit or not r then return end
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
	if STATE.ESPIsland then
		local map = Workspace:FindFirstChild("Map")
		if map then
			for _, island in ipairs(map:GetChildren()) do
				if island:IsA("Model") then
					local part = island:FindFirstChildWhichIsA("BasePart")
					if part then
						createBillboardESP(part, "Island: " .. island.Name, Color3.fromRGB(100, 255, 100))
					end
				end
			end
		end
	end
	if STATE.ESPFlower then
		local map = Workspace:FindFirstChild("Map")
		if map then
			for _, flower in ipairs(map:GetDescendants()) do
				if flower:IsA("Part") and flower.Name:find("Flower") then
					createBillboardESP(flower, "Flower", Color3.fromRGB(255, 100, 255))
				end
			end
		end
	end
	if STATE.ESPGear then
		local map = Workspace:FindFirstChild("Map")
		if map then
			for _, gear in ipairs(map:GetDescendants()) do
				if gear:IsA("Part") and gear.Name:find("Gear") then
					createBillboardESP(gear, "Gear", Color3.fromRGB(200, 200, 100))
				end
			end
		end
	end
	if STATE.ESPAdvDealer then
		local map = Workspace:FindFirstChild("Map")
		if map then
			for _, npc in ipairs(map:GetDescendants()) do
				if npc:IsA("Model") and npc.Name:find("Advanced Fruit Dealer") then
					local part = npc:FindFirstChildWhichIsA("BasePart")
					if part then
						createBillboardESP(part, "Adv Dealer", Color3.fromRGB(255, 50, 50))
					end
				end
			end
		end
	end
	if STATE.ESPBerry then
		local map = Workspace:FindFirstChild("Map")
		if map then
			for _, berry in ipairs(map:GetDescendants()) do
				if berry:IsA("Part") and berry.Name:find("Berry") then
					createBillboardESP(berry, "Berry", Color3.fromRGB(200, 100, 50))
				end
			end
		end
	end
end

local noclipConn = nil
local autoNoclipActive = false
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		autoNoclipActive = true
		noclipConn = RunService.Stepped:Connect(function()
			local c = LocalPlayer.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	else
		autoNoclipActive = false
	end
end

local lastStuckCheck = 0
local lastPosition = nil
local stuckNoclipOn = false
local function checkAndFixStuck(targetPos)
	if not STATE.AutoFarm then return end
	local hrp = getHRP()
	if not hrp then return end

	local now = tick()
	if now - lastStuckCheck < 0.5 then return end
	lastStuckCheck = now

	local distToTarget = (hrp.Position - targetPos).Magnitude
	if distToTarget < 15 then
		if stuckNoclipOn then setNoclip(false); stuckNoclipOn = false end
		lastPosition = nil
		return
	end

	if lastPosition then
		local moved = (hrp.Position - lastPosition).Magnitude
		if moved < 1 and distToTarget > 20 and not stuckNoclipOn then
			setNoclip(true)
			stuckNoclipOn = true
		elseif moved > 5 and stuckNoclipOn and not STATE.Noclip then
			setNoclip(false)
			stuckNoclipOn = false
		end
	end
	lastPosition = hrp.Position
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

-- ========================================
-- DATA TABLES (from FourHub + expanded)
-- ========================================

local BossList = {
	World1 = {
		"The Gorilla King", "Bobby", "The Saw", "Yeti", "Mob Leader",
		"Vice Admiral", "Saber Expert", "Warden", "Chief Warden", "Swan",
		"Magma Admiral", "Fishman Lord", "Wysper", "Thunder God", "Cyborg",
		"Ice Admiral", "Greybeard",
	},
	World2 = {
		"Diamond", "Jeremy", "Fajita", "Don Swan", "Smoke Admiral",
		"Awakened Ice Admiral", "Tide Keeper", "Darkbeard", "Cursed Captain", "Order",
	},
	World3 = {
		"Stone", "Hydra Leader", "Kilo Admiral", "Captain Elephant",
		"Beautiful Pirate", "Cake Queen", "Longma", "Soul Reaper",
	},
}

local MaterialList = {
	World1 = { "Leather + Scrap Metal", "Angel Wings", "Magma Ore", "Fish Tail" },
	World2 = { "Leather + Scrap Metal", "Radioactive Material", "Ectoplasm", "Mystic Droplet", "Magma Ore", "Vampire Fang" },
	World3 = { "Scrap Metal", "Demonic Wisp", "Conjured Cocoa", "Dragon Scale", "Gunpowder", "Fish Tail", "Mini Tusk" },
}

local MaterialMobs = {
	["Leather + Scrap Metal"] = { World1 = {"Brute","Pirate"}, World2 = {"Marine Captain"}, World3 = {"Jungle Pirate","Forest Pirate"} },
	["Angel Wings"] = { World1 = {"Shanda","Royal Squad","Royal Soldier","Wysper","Thunder God"} },
	["Magma Ore"] = { World1 = {"Military Soldier","Military Spy","Magma Admiral"}, World2 = {"Magma Ninja","Lava Pirate"} },
	["Fish Tail"] = { World1 = {"Fishman Warrior","Fishman Commando","Fishman Lord"}, World3 = {"Fishman Raider","Fishman Captain"} },
	["Radioactive Material"] = { World2 = {"Factory Staff"} },
	["Ectoplasm"] = { World2 = {"Ship Deckhand","Ship Engineer","Ship Steward","Ship Officer"} },
	["Mystic Droplet"] = { World2 = {"Water Fighter"} },
	["Vampire Fang"] = { World2 = {"Vampire"} },
	["Scrap Metal"] = { World3 = {"Jungle Pirate","Forest Pirate"} },
	["Demonic Wisp"] = { World3 = {"Demonic Soul"} },
	["Conjured Cocoa"] = { World3 = {"Chocolate Bar Battler","Cocoa Warrior"} },
	["Dragon Scale"] = { World3 = {"Dragon Crew Archer","Dragon Crew Warrior"} },
	["Gunpowder"] = { World3 = {"Pistol Billionaire"} },
	["Mini Tusk"] = { World3 = {"Mythological Pirate"} },
}

local MaterialPos = {
	["Leather + Scrap Metal"] = { World1 = CFrame.new(-1145,15,4350), World2 = CFrame.new(-2010,73,-3326), World3 = CFrame.new(-11975,331,-10620) },
	["Angel Wings"] = { World1 = CFrame.new(-4698,845,-1912) },
	["Magma Ore"] = { World1 = CFrame.new(-5815,84,8820), World2 = CFrame.new(-5428,78,-5959) },
	["Fish Tail"] = { World1 = CFrame.new(61123,19,1569), World3 = CFrame.new(-10993,332,-8940) },
	["Radioactive Material"] = { World2 = CFrame.new(295,73,-56) },
	["Ectoplasm"] = { World2 = CFrame.new(911,125,33159) },
	["Mystic Droplet"] = { World2 = CFrame.new(-3385,239,-10542) },
	["Vampire Fang"] = { World2 = CFrame.new(-6033,7,-1317) },
	["Scrap Metal"] = { World3 = CFrame.new(-11975,331,-10620) },
	["Demonic Wisp"] = { World3 = CFrame.new(-9495,453,5977) },
	["Conjured Cocoa"] = { World3 = CFrame.new(620,78,-12581) },
	["Dragon Scale"] = { World3 = CFrame.new(6594,383,139) },
	["Gunpowder"] = { World3 = CFrame.new(-84,85,6132) },
	["Mini Tusk"] = { World3 = CFrame.new(-13545,470,-6917) },
}

local MaterialEntrance = {
	["Angel Wings"] = Vector3.new(-4607.82275, 872.54248, -1667.55688),
	["Fish Tail"] = { World1 = Vector3.new(61163.85, 11.68, 1819.78) },
	["Ectoplasm"] = Vector3.new(923.21, 126.98, 32852.83),
}

local BossQuestData = {
	-- World 1
	["The Gorilla King"] = { quest = "JungleQuest", data = 3, posQ = CFrame.new(-1601,37,153), posB = CFrame.new(-1088,8,-488) },
	["Bobby"] = { quest = "BuggyQuest1", data = 3, posQ = CFrame.new(-1140,5,3828), posB = CFrame.new(-1087,47,4040) },
	["The Saw"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-785,72,1603) },
	["Yeti"] = { quest = "SnowQuest", data = 3, posQ = CFrame.new(1386,87,-1297), posB = CFrame.new(1218,138,-1488) },
	["Mob Leader"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-2845,7,5357) },
	["Vice Admiral"] = { quest = "MarineQuest2", data = 2, posQ = CFrame.new(-5036,29,4325), posB = CFrame.new(-5007,88,4353) },
	["Saber Expert"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-1459,30,-51) },
	["Warden"] = { quest = "ImpelQuest", data = 1, posQ = CFrame.new(5192,3,686), posB = CFrame.new(5278,2,944) },
	["Chief Warden"] = { quest = "ImpelQuest", data = 2, posQ = CFrame.new(5192,3,686), posB = CFrame.new(5207,1,815) },
	["Swan"] = { quest = "ImpelQuest", data = 3, posQ = CFrame.new(5192,3,686), posB = CFrame.new(5325,7,720) },
	["Magma Admiral"] = { quest = "MagmaQuest", data = 3, posQ = CFrame.new(-5316,12,8517), posB = CFrame.new(-5766,83,8718) },
	["Fishman Lord"] = { quest = "FishmanQuest", data = 3, posQ = CFrame.new(61123,19,1569), posB = CFrame.new(61260,31,1193) },
	["Wysper"] = { quest = "SkyExp1Quest", data = 3, posQ = CFrame.new(-7862,5546,-380), posB = CFrame.new(-7866,5576,-547) },
	["Thunder God"] = { quest = "SkyExp2Quest", data = 3, posQ = CFrame.new(-7904,5636,-1412), posB = CFrame.new(-7995,5761,-2089) },
	["Cyborg"] = { quest = "FountainQuest", data = 3, posQ = CFrame.new(5258,39,4050), posB = CFrame.new(6094,74,3826) },
	["Ice Admiral"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(1266,26,-1400) },
	["Greybeard"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-5081,85,4257) },
	-- World 2
	["Diamond"] = { quest = "Area1Quest", data = 3, posQ = CFrame.new(-428,74,1835), posB = CFrame.new(-1577,199,14) },
	["Jeremy"] = { quest = "Area2Quest", data = 3, posQ = CFrame.new(637,73,918), posB = CFrame.new(2007,449,854) },
	["Fajita"] = { quest = "MarineQuest3", data = 3, posQ = CFrame.new(-2442,73,-3218), posB = CFrame.new(-2173,103,-4015) },
	["Don Swan"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(2286,15,864) },
	["Smoke Admiral"] = { quest = "IceSideQuest", data = 3, posQ = CFrame.new(-5429,16,-5298), posB = CFrame.new(-5275,21,-5261) },
	["Awakened Ice Admiral"] = { quest = "FrostQuest", data = 3, posQ = CFrame.new(5669,29,-6483), posB = CFrame.new(6404,340,-6895) },
	["Tide Keeper"] = { quest = "ForgottenQuest", data = 3, posQ = CFrame.new(-3054,238,-10145), posB = CFrame.new(-3796,106,-11421) },
	["Darkbeard"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(3677,63,-3145) },
	["Cursed Captain"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(917,181,33422) },
	["Order"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-6217,28,-5053) },
	-- World 3
	["Stone"] = { quest = "PiratePortQuest", data = 3, posQ = CFrame.new(-290,44,5580), posB = CFrame.new(-1028,92,6579) },
	["Hydra Leader"] = { quest = "AmazonQuest2", data = 3, posQ = CFrame.new(5822,1019,-74), posB = CFrame.new(5822,1019,-74) },
	["Kilo Admiral"] = { quest = "MarineTreeIsland", data = 3, posQ = CFrame.new(2179,29,-6740), posB = CFrame.new(2764,432,-7144) },
	["Captain Elephant"] = { quest = "DeepForestIsland", data = 3, posQ = CFrame.new(-13232,332,-7626), posB = CFrame.new(-13377,433,-8071) },
	["Beautiful Pirate"] = { quest = "DeepForestIsland2", data = 3, posQ = CFrame.new(-12682,391,-9902), posB = CFrame.new(5284,23,-111) },
	["Cake Queen"] = { quest = "IceCreamIslandQuest", data = 3, posQ = CFrame.new(-819,65,-10967), posB = CFrame.new(-679,381,-11114) },
	["Longma"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-10239,390,-9550) },
	["Soul Reaper"] = { quest = nil, data = nil, posQ = nil, posB = CFrame.new(-9525,316,6656) },
}

local SeaEventNames = {
	"Shark", "Piranha", "Terror Shark", "Fish Crew", "Haunted Crew",
	"Fish Boat", "Sea Beast", "Pirate Brigade", "Pirate Grand Brigade",
}

local RaceUpgradeCosts = {
	MinkV3 = { ["Ectoplasm"] = 20, ["Demon Fragment"] = 10 },
	HumanV3 = { ["Bones"] = 20, ["Frog"] = 1 },
	AngelV3 = { ["Bones"] = 25, ["Feather"] = 1 },
	FishmanV3 = { ["Bones"] = 20, ["Shark Anchor"] = 1 },
	GhoulV3 = { ["Bones"] = 20, ["Ectoplasm"] = 10 },
	CyborgV3 = { ["Bones"] = 20, ["Core Brain"] = 1 },
	SkypieaV3 = { ["Bones"] = 25, ["Rainbow Saviour"] = 1 },
}

local SeaEventShopItems = {
	"Shark Anchor", "Mysterious Fragment", "Leviathan Crown", "Kitsune Ribbon",
	"God's Chalice", "Fool's Gold", "Dragon Heart", "Dragon Storm",
	"Shark Tooth Necklace", "Terror Jaw",
}

local FruitShopList = {
	"Dragon", "Leopard", "Dough", "Spirit", "Venom", "Control", "Kitsune",
	"Blizzard", "T-Rex", "Mammoth", "Sound", "Spider", "Phoenix", "Rumble",
	"Light", "Magma", "Quake", "Buddha", "Shadow", "Gravity", "Ice",
	"Flame", "Dark", "Diamond", "Love", "Rubber", "String", "Bomb",
	"Smoke", "Spike", "Chop", "Spring", "Bird: Falcon", "Hand: Soul",
	"Paw", "Revive", "Human: Buddha", "Kilo", "Barrier", "Ghost",
	"Sand", "Bird: Phoenix", "Alpha"
}

local FightingStyleShop = {
	"Black Leg", "Electro", "Fishman Karate", "Dragon Claw",
	"Super Human", "Death Step", "Sharkman Karate", "Electric Claw",
	"Dragon Talon", "God Human",
}

local SwordShop = {
	"Cutlass", "Katana", "Iron Mace", "Dual Katana", "Triple Katana",
	"Pipe", "Saber", "Bisento", "Pole", "Shisui", "Saddi", "Wando",
	"True Triple Katana", "Gravity Blade", "Dragon Trident", "Yama",
	"Tushita", "Canvendish", "Dark Blade",
}

local AccessoryShop = {
	"Black Cape", "Swordsman Hat", "Travel Quest", "Marine Coat",
	"Swan Wing", "Usoap's Hat", "Pirate Cape", "Black Spikey Coat",
	"Tomoe Ring", "Choppa Cape", "Zebra Cap", "Dragon Hunter",
	"Leather Coat", "Gentleman Cape",
}

local AdminNames = {
	"Roblox", "Builderman", "Shedletsky", "Matt Dusek",
	"Donis Drones", "Telamon", "Merely", "Builder_Boy",
}

-- World detection helper
local function getWorld()
	if game.PlaceId == 2753915549 or game.PlaceId == 85211729168715 then return "World1"
	elseif game.PlaceId == 4442272183 or game.PlaceId == 79091703265657 then return "World2"
	elseif game.PlaceId == 7449423635 or game.PlaceId == 100117331123089 then return "World3"
	end
	return "World1"
end

local currentWorld = getWorld()

local function getBossList()
	return BossList[currentWorld] or {}
end

local function getMaterialList()
	return MaterialList[currentWorld] or {}
end

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

local FarmSub = MainTab:AddSubTab("Farming", "zap")
local DiscordGroup = FarmSub:AddLeftGroupbox("Community", "users")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/ivory") end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 })
end)
DiscordGroup:AddLabel("Click above to join our Discord for dupes, updates & more!")

local FarmGroup = FarmSub:AddRightGroupbox("Auto Farm", "cpu")
local ChestGroup = FarmSub:AddLeftGroupbox("Chests", "package")

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
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						if STATE.AutoFarmMethod == "Nearest" then
							local closest, closestDist = nil, math.huge
							for _, mob in pairs(workspace.Enemies:GetChildren()) do
								if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
									local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
									if mobDist < closestDist then
										closest = mob
										closestDist = mobDist
									end
								end
							end
							if closest then
								repeat task.wait()
									hrp = getHRP()
									if not hrp then break end
									EquipWeapon(STATE.SelectedWeapon)
									local mobHRP = closest.HumanoidRootPart
									closest.Humanoid.WalkSpeed = 0
									closest.HumanoidRootPart.CanCollide = false
									closest.Head.CanCollide = false
									closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
									closest.HumanoidRootPart.Transparency = 1
									closest.Humanoid:ChangeState(11)

								local targets = BringMob(closest)
								toTarget(mobHRP.CFrame * CFrame.new(0, 30, 5))
								checkAndFixStuck(mobHRP.Position)

								hrp = getHRP()
								if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
									if tick() - LastRotate >= 0.25 then
										AttackRotation = (AttackRotation + 180) % 360
										LastRotate = tick()
									end
									if #targets >= 2 then
										Attack({targets[1], targets[2]})
									else
										Attack(closest)
									end
									useSkills(mobHRP.Position)
								end
							until not STATE.AutoFarm or not closest.Parent or closest.Humanoid.Health <= 0
						end
					else
							CheckQuest()
							local Quest = LocalPlayer.PlayerGui.Main.Quest
							local QuestTitle = Quest.Container.QuestTitle
							if Quest.Visible then
								if string.find(QuestTitle.Title.Text, NameCheckQuest) then
									if workspace.Enemies:FindFirstChild(Monster) then
										for _, v in pairs(workspace.Enemies:GetChildren()) do
											if v.Name == Monster and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
												if string.find(QuestTitle.Title.Text, NameCheckQuest) then
													repeat task.wait()
														hrp = getHRP()
														if not hrp then break end
														EquipWeapon(STATE.SelectedWeapon)
														local mobHRP = v.HumanoidRootPart
														v.Humanoid.WalkSpeed = 0
														v.HumanoidRootPart.CanCollide = false
														v.Head.CanCollide = false
														v.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
														v.HumanoidRootPart.Transparency = 1
														v.Humanoid:ChangeState(11)

													local targets = BringMob(v)
													toTarget(mobHRP.CFrame * CFrame.new(0, 30, 5))
													checkAndFixStuck(mobHRP.Position)

													hrp = getHRP()
													if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
														if tick() - LastRotate >= 0.25 then
															AttackRotation = (AttackRotation + 180) % 360
															LastRotate = tick()
														end
														if #targets >= 2 then
															Attack({targets[1], targets[2]})
														else
															Attack(v)
														end
														useSkills(mobHRP.Position)
													end
													until not STATE.AutoFarm or not v.Parent or v.Humanoid.Health <= 0 or not Quest.Visible or not v:FindFirstChild("HumanoidRootPart")
												else
													CommF:InvokeServer("AbandonQuest")
												end
											end
										end
									else
										if CFrameMon and CFrameMon.Position then
											toTarget(CFrameMon * CFrame.new(0, 30, 5))
										end
									end
								else
									CommF:InvokeServer("AbandonQuest")
								end
							else
								local questDist = (CFrameQ.Position - hrp.Position).Magnitude
								if questDist >= 3000 then
									if EntranceCF then
										pcall(function() CommF:InvokeServer("requestEntrance", EntranceCF) end)
										task.wait(1)
									else
										BTP(CFrameQ)
									end
								else
									toTarget(CFrameQ)
								end
								if (hrp.Position - CFrameQ.Position).Magnitude <= 20 then
									CommF:InvokeServer("StartQuest", NameQuest, LevelQuest)
									task.wait(0.5)
								end
							end
						end -- end Quest mode
						for _, bodypart in ipairs(Character:GetChildren()) do
							if bodypart:IsA("BasePart") then bodypart.CanCollide = false end
						end
					end)
					task.wait()
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
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end
						local chestModels = Workspace:FindFirstChild("ChestModels")
						if chestModels then
							for _, chest in ipairs(chestModels:GetChildren()) do
								if chest:IsA("Model") and STATE.AutoChest then
									local part = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
									if part then
										toTarget(part.Position)
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
						toTarget(part.Position)
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

						local function collectFruit(fruit)
							if not fruit or not fruit.Parent then STATE.CollectingFruit = false; return end
							local handle = fruit:FindFirstChild("Handle")
							if not handle then STATE.CollectingFruit = false; return end

							STATE.CollectingFruit = true
							if tweenActive then pcall(function() tweenActive:Cancel() end) end

							local dist = (handle.Position - hrp.Position).Magnitude

							if dist > 3000 then
								BTP(CFrame.new(handle.Position))
							else
								toTarget(handle.Position)
							end

							task.wait(0.5)
							hrp = getHRP()
							if hrp and (hrp.Position - handle.Position).Magnitude <= 25 then
								pcall(function()
									local originalName = fruit:GetAttribute("OriginalName")
									if originalName then
										CommF:InvokeServer("StoreFruit", originalName, fruit)
									end
								end)
							end
							STATE.CollectingFruit = false
						end

						local foundFruit = false

						for _, obj in ipairs(Workspace:GetChildren()) do
							if obj:IsA("Tool") and STATE.AutoFruit then
								collectFruit(obj)
								foundFruit = true
								STATE.LastFruitSeen = os.time()
							end
						end

						local map = Workspace:FindFirstChild("Map")
						if map then
							for _, obj in ipairs(map:GetDescendants()) do
								if obj:IsA("Tool") and STATE.AutoFruit then
									collectFruit(obj)
									foundFruit = true
									STATE.LastFruitSeen = os.time()
								end
							end
						end

						if not foundFruit then
							STATE.CollectingFruit = false
						end
					end)
					task.wait()
				end
				detachFloat()
				if stuckNoclipOn and not STATE.Noclip then
					setNoclip(false)
					stuckNoclipOn = false
				end
			end)
		else
			detachFloat()
			if stuckNoclipOn and not STATE.Noclip then
				setNoclip(false)
				stuckNoclipOn = false
			end
		end
	end,
}):AddKeyPicker("AutoFruitKey", {
	Default = "None", Text = "Fruit Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

FruitGroup:AddToggle("AutoStoreFruit", {
	Text = "Auto Store Fruits",
	Default = false,
	Callback = function(v)
		STATE.AutoStoreFruit = v
		if v then
			task.spawn(function()
				while STATE.AutoStoreFruit do
					pcall(function()
						for _, backpack in ipairs({LocalPlayer.Backpack, Character}) do
							for _, tool in ipairs(backpack:GetChildren()) do
								if tool:IsA("Tool") and tool.Name:find("Fruit") then
									local originalName = tool:GetAttribute("OriginalName")
									if originalName then
										CommF:InvokeServer("StoreFruit", originalName, tool)
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
})

local MoonPhaseLabel = FruitGroup:AddLabel("Moon: detecting...")
local FruitTimerLabel = FruitGroup:AddLabel("Next fruit in: calculating...")

FruitGroup:AddButton("Reset Fruit Timer", function()
	STATE.LastFruitSeen = os.time()
	Library:Notify({ Title = "Ivory", Description = "Fruit timer reset! Counting down...", Type = "Success", Time = 3 })
end)

FruitGroup:AddLabel("Auto Collect: tweens to spawned fruits on map")
FruitGroup:AddLabel("Auto Store: stores all fruits in inventory")

local MOON_TEXTURES = {
	["9709149431"] = "Full Moon (100%)",
	["9709149052"] = "Full Moon (75%)",
	["9709143733"] = "Full Moon (50%)",
	["9709150401"] = "Full Moon (25%)",
	["9709149680"] = "Full Moon (15%)",
}

task.spawn(function()
	while task.wait(5) do
		pcall(function()
			local sky = Lighting:FindFirstChildOfClass("Sky")
			if sky then
				local texId = sky.MoonTextureId
				local id = texId:match("%d+")
				if id and MOON_TEXTURES[id] then
					MoonPhaseLabel:SetText("Moon: " .. MOON_TEXTURES[id])
				else
					MoonPhaseLabel:SetText("Moon: Waiting...")
				end
			end

			local dayOfWeek = os.date("*t").wday
			local isWeekend = (dayOfWeek == 1 or dayOfWeek == 7)
			STATE.FruitRespawnTime = isWeekend and 2700 or 3600
		end)
	end
end)

task.spawn(function()
	while task.wait(15) do
		pcall(function()
			for _, obj in ipairs(Workspace:GetChildren()) do
				if obj:IsA("Tool") then
					STATE.LastFruitSeen = os.time()
				end
			end
			local map = Workspace:FindFirstChild("Map")
			if map then
				for _, obj in ipairs(map:GetDescendants()) do
					if obj:IsA("Tool") then
						STATE.LastFruitSeen = os.time()
					end
				end
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(1) do
		pcall(function()
			if STATE.LastFruitSeen == 0 then
				FruitTimerLabel:SetText("Next fruit in: searching...")
			else
				local elapsed = os.time() - STATE.LastFruitSeen
				local remaining = math.max(0, STATE.FruitRespawnTime - elapsed)
				if remaining <= 0 then
					FruitTimerLabel:SetText("Next fruit in: soon")
				else
					local mins = math.floor(remaining / 60)
					local secs = remaining % 60
					local dayOfWeek = os.date("*t").wday
					local isWeekend = (dayOfWeek == 1 or dayOfWeek == 7)
					local serverType = isWeekend and "Private" or "Public"
					FruitTimerLabel:SetText("Next fruit in: " .. mins .. "m " .. secs .. "s (" .. serverType .. ")")
				end
			end
		end)
	end
end)

-- ========================================
-- EXTENDED FARMING (Phase 1)
-- ========================================
local ExtFarmSub = MainTab:AddSubTab("Extended", "plus-circle")

-- Boss Farm
local BossFarmGroup = ExtFarmSub:AddLeftGroupbox("Boss Farm", "skull")
BossFarmGroup:AddDropdown("SelectedBoss", {
	Values = (function() local t = {"All"}; for _, b in ipairs(getBossList()) do table.insert(t, b) end; return t end)(),
	Default = "All", Text = "Select Boss",
	Callback = function(v) STATE.SelectedBoss = v end,
})
BossFarmGroup:AddToggle("AutoBossFarm", {
	Text = "Auto Farm Boss",
	Default = false,
	Callback = function(v)
		STATE.AutoBossFarm = v
		if v then
			task.spawn(function()
				while STATE.AutoBossFarm do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local targetBoss = nil
						if STATE.SelectedBoss == "All" then
							for _, bossName in ipairs(getBossList()) do
								local boss = workspace.Enemies:FindFirstChild(bossName)
								if boss and boss:FindFirstChild("HumanoidRootPart") and boss:FindFirstChild("Humanoid") and boss.Humanoid.Health > 0 then
									targetBoss = boss
									break
								end
							end
							-- check ReplicatedStorage too
							if not targetBoss then
								for _, bossName in ipairs(getBossList()) do
									for _, model in ipairs(ReplicatedStorage:GetChildren()) do
										if model:IsA("Model") and model.Name == bossName and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
											targetBoss = model
											break
										end
									end
									if targetBoss then break end
								end
							end
						else
							targetBoss = workspace.Enemies:FindFirstChild(STATE.SelectedBoss)
							if not targetBoss then
								for _, model in ipairs(ReplicatedStorage:GetChildren()) do
									if model:IsA("Model") and model.Name == STATE.SelectedBoss and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
										targetBoss = model
										break
									end
								end
							end
						end

						if targetBoss then
							local bossData = BossQuestData[targetBoss.Name]
							if bossData and bossData.quest and bossData.data then
								local quest = LocalPlayer.PlayerGui.Main.Quest
								if not quest.Visible or not string.find(quest.Container.QuestTitle.Title.Text, targetBoss.Name) then
									CommF:InvokeServer("AbandonQuest")
									if bossData.posQ then
										if (bossData.posQ.Position - hrp.Position).Magnitude >= 3000 then
											BTP(bossData.posQ)
										else
											toTarget(bossData.posQ)
										end
										if (hrp.Position - bossData.posQ.Position).Magnitude <= 20 then
											CommF:InvokeServer("StartQuest", bossData.quest, bossData.data)
											task.wait(0.5)
										end
									end
								end
							end

							local bossHRP = targetBoss:FindFirstChild("HumanoidRootPart")
							if bossHRP then
								repeat task.wait()
									hrp = getHRP()
									if not hrp then break end
									EquipWeapon(STATE.SelectedWeapon)
									bossHRP = targetBoss:FindFirstChild("HumanoidRootPart")
									if not bossHRP then break end
									bossHRP.CanCollide = false
									targetBoss:FindFirstChild("Head").CanCollide = false
									toTarget(bossHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
									checkAndFixStuck(bossHRP.Position)
									hrp = getHRP()
									if hrp and bossHRP and (hrp.Position - bossHRP.Position).Magnitude <= 150 then
										Attack(targetBoss)
										useSkills(bossHRP.Position)
									end
								until not STATE.AutoBossFarm or not targetBoss.Parent or not targetBoss:FindFirstChild("Humanoid") or targetBoss.Humanoid.Health <= 0
							end
						else
							task.wait(1)
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("BossFarmKey", {
	Default = "None", Text = "Boss Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

-- Material Farm
local MatFarmGroup = ExtFarmSub:AddRightGroupbox("Material Farm", "layers")
MatFarmGroup:AddDropdown("SelectedMaterial", {
	Values = getMaterialList(),
	Default = (function() local ml = getMaterialList(); return ml[1] or "Leather + Scrap Metal" end)(),
	Text = "Select Material",
	Callback = function(v) STATE.SelectedMaterial = v end,
})
MatFarmGroup:AddToggle("AutoMaterialFarm", {
	Text = "Auto Farm Material",
	Default = false,
	Callback = function(v)
		STATE.AutoMaterial = v
		if v then
			task.spawn(function()
				while STATE.AutoMaterial do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local matData = MaterialMobs[STATE.SelectedMaterial]
						if not matData then return end
						local mobs = matData[currentWorld]
						if not mobs then return end

						-- Check quest
						local quest = LocalPlayer.PlayerGui.Main.Quest
						local hasQuest = quest.Visible
						if hasQuest then
							for _, mobName in ipairs(mobs) do
								if string.find(quest.Container.QuestTitle.Title.Text, mobName) then
									hasQuest = true
									break
								end
							end
						end

						if not hasQuest then
							-- Find a mob to get quest
							for _, mobName in ipairs(mobs) do
								if workspace.Enemies:FindFirstChild(mobName) then
									-- Start quest for this mob
									CommF:InvokeServer("AbandonQuest")
									break
								end
							end
						end

						-- Kill nearest material mob
						local closest, closestDist = nil, math.huge
						for _, mobName in ipairs(mobs) do
							for _, mob in ipairs(workspace.Enemies:GetChildren()) do
								if mob.Name == mobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
									local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
									if mobDist < closestDist then
										closest = mob
										closestDist = mobDist
									end
								end
							end
						end

						if closest then
							EquipWeapon(STATE.SelectedWeapon)
							local mobHRP = closest.HumanoidRootPart
							closest.Humanoid.WalkSpeed = 0
							closest.HumanoidRootPart.CanCollide = false
							closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
							closest.HumanoidRootPart.Transparency = 1
							closest.Humanoid:ChangeState(11)

							local targets = BringMob(closest)
							toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
							checkAndFixStuck(mobHRP.Position)

							hrp = getHRP()
							if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
								if #targets >= 2 then
									Attack({targets[1], targets[2]})
								else
									Attack(closest)
								end
								useSkills(mobHRP.Position)
							end

							-- Check entrance for special areas
							local matEntrance = MaterialEntrance[STATE.SelectedMaterial]
							if matEntrance and (hrp.Position - (typeof(matEntrance) == "Vector3" and matEntrance or matEntrance[currentWorld] or hrp.Position)).Magnitude > 10000 then
								pcall(function() CommF:InvokeServer("requestEntrance", typeof(matEntrance) == "Vector3" and matEntrance or matEntrance[currentWorld]) end)
								task.wait(1)
							end
						else
							-- Move to material position
							local matPos = MaterialPos[STATE.SelectedMaterial]
							if matPos and matPos[currentWorld] then
								toTarget(matPos[currentWorld])
							end
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("MaterialKey", {
	Default = "None", Text = "Material Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

-- Bone / Cake Prince / Factory / Pirate Raid
local SpecialFarmGroup = ExtFarmSub:AddLeftGroupbox("Special Farms", "star")

SpecialFarmGroup:AddToggle("AutoBone", {
	Text = "Auto Farm Bone",
	Default = false,
	Callback = function(v)
		STATE.AutoBone = v
		if v then
			task.spawn(function()
				while STATE.AutoBone do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						-- Quest for bones
						local quest = LocalPlayer.PlayerGui.Main.Quest
						if not quest.Visible or not string.find(quest.Container.QuestTitle.Title.Text, "Reborn Skeleton") then
							CommF:InvokeServer("StartQuest", "HauntedQuest1", 1)
							task.wait(0.5)
						end

						local closest, closestDist = nil, math.huge
						local boneMobs = {"Reborn Skeleton", "Living Zombie", "Demonic Soul", "Posessed Mummy"}
						for _, mobName in ipairs(boneMobs) do
							for _, mob in ipairs(workspace.Enemies:GetChildren()) do
								if mob.Name == mobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
									local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
									if mobDist < closestDist then
										closest = mob
										closestDist = mobDist
									end
								end
							end
						end

						if closest then
							EquipWeapon(STATE.SelectedWeapon)
							local mobHRP = closest.HumanoidRootPart
							closest.Humanoid.WalkSpeed = 0
							closest.HumanoidRootPart.CanCollide = false
							closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
							closest.HumanoidRootPart.Transparency = 1
							closest.Humanoid:ChangeState(11)

							local targets = BringMob(closest)
							toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
							checkAndFixStuck(mobHRP.Position)

							hrp = getHRP()
							if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
								if #targets >= 2 then
									Attack({targets[1], targets[2]})
								else
									Attack(closest)
								end
								useSkills(mobHRP.Position)
							end
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("BoneKey", {
	Default = "None", Text = "Bone Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SpecialFarmGroup:AddToggle("AutoCakePrince", {
	Text = "Auto Cake Prince",
	Default = false,
	Callback = function(v)
		STATE.AutoCakePrince = v
		if v then
			task.spawn(function()
				while STATE.AutoCakePrince do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local cakeMobs = {"Cookie Crafter", "Cake Guard", "Baking Staff", "Head Baker"}
						local closest, closestDist = nil, math.huge
						for _, mobName in ipairs(cakeMobs) do
							for _, mob in ipairs(workspace.Enemies:GetChildren()) do
								if mob.Name == mobName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
									local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
									if mobDist < closestDist then
										closest = mob
										closestDist = mobDist
									end
								end
							end
						end

						-- If Cake Prince spawned, target it
						if workspace.Enemies:FindFirstChild("Cake Prince") then
							closest = workspace.Enemies:FindFirstChild("Cake Prince")
						end

						if closest then
							EquipWeapon(STATE.SelectedWeapon)
							local mobHRP = closest.HumanoidRootPart
							closest.Humanoid.WalkSpeed = 0
							closest.HumanoidRootPart.CanCollide = false
							closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
							closest.HumanoidRootPart.Transparency = 1
							closest.Humanoid:ChangeState(11)

							local targets = BringMob(closest)
							toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
							checkAndFixStuck(mobHRP.Position)

							hrp = getHRP()
							if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
								if #targets >= 2 then
									Attack({targets[1], targets[2]})
								else
									Attack(closest)
								end
								useSkills(mobHRP.Position)
							end
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("CakePrinceKey", {
	Default = "None", Text = "Cake Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SpecialFarmGroup:AddToggle("AutoFactory", {
	Text = "Auto Factory Raid",
	Default = false,
	Callback = function(v)
		STATE.AutoFactory = v
		if v then
			task.spawn(function()
				while STATE.AutoFactory do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						-- Find Factory Core
						local core = workspace:FindFirstChild("Factory") and workspace.Factory:FindFirstChild("Core")
						if core then
							EquipWeapon(STATE.SelectedWeapon)
							toTarget(core.CFrame * CFrame.new(0, 30, 5))
							hrp = getHRP()
							if hrp and (hrp.Position - core.Position).Magnitude <= 150 then
								Attack(core)
							end
						else
							-- Kill Factory Staff
							local closest, closestDist = nil, math.huge
							for _, mob in ipairs(workspace.Enemies:GetChildren()) do
								if mob.Name == "Factory Staff" and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
									local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
									if mobDist < closestDist then
										closest = mob
										closestDist = mobDist
									end
								end
							end
							if closest then
								EquipWeapon(STATE.SelectedWeapon)
								toTarget(closest.HumanoidRootPart.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
								Attack(closest)
								useSkills(closest.HumanoidRootPart.Position)
							end
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
})

SpecialFarmGroup:AddToggle("AutoPirateRaid", {
	Text = "Auto Pirate Raid",
	Default = false,
	Callback = function(v)
		STATE.AutoPirateRaid = v
		if v then
			task.spawn(function()
				while STATE.AutoPirateRaid do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local closest, closestDist = nil, math.huge
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if (mob.Name == "Pirate Grand Brigade" or mob.Name == "Pirate Brigade") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if mobDist < closestDist then
									closest = mob
									closestDist = mobDist
								end
							end
						end
						if closest then
							EquipWeapon(STATE.SelectedWeapon)
							toTarget(closest.HumanoidRootPart.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
							Attack(closest)
							useSkills(closest.HumanoidRootPart.Position)
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
})

-- Mastery Farm & Kill Nearest
local MasteryGroup = ExtFarmSub:AddRightGroupbox("Mastery / Kill", "target")

MasteryGroup:AddDropdown("MasteryType", {
	Values = { "Fruit", "Gun", "Sword" }, Default = "Fruit", Text = "Mastery Type",
	Callback = function(v) STATE.MasteryType = v end,
})

MasteryGroup:AddToggle("AutoMastery", {
	Text = "Auto Mastery Farm",
	Default = false,
	Callback = function(v)
		STATE.AutoMastery = v
		if v then
			task.spawn(function()
				while STATE.AutoMastery do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local quest = LocalPlayer.PlayerGui.Main.Quest
						if not quest.Visible then
							CheckQuest()
							if CFrameQ then
								if (CFrameQ.Position - hrp.Position).Magnitude >= 3000 then
									if EntranceCF then
										pcall(function() CommF:InvokeServer("requestEntrance", EntranceCF) end)
										task.wait(1)
									else
										BTP(CFrameQ)
									end
								else
									toTarget(CFrameQ)
								end
								if (hrp.Position - CFrameQ.Position).Magnitude <= 20 then
									CommF:InvokeServer("StartQuest", NameQuest, LevelQuest)
									task.wait(0.5)
								end
							end
							return
						end

						-- Find mob
						local closest, closestDist = nil, math.huge
						if Monster and workspace.Enemies:FindFirstChild(Monster) then
							for _, mob in ipairs(workspace.Enemies:GetChildren()) do
								if mob.Name == Monster and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
									local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
									if mobDist < closestDist then
										closest = mob
										closestDist = mobDist
									end
								end
							end
						end

						if closest then
							local mobHRP = closest.HumanoidRootPart
							closest.Humanoid.WalkSpeed = 0
							closest.HumanoidRootPart.CanCollide = false
							closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
							closest.HumanoidRootPart.Transparency = 1
							closest.Humanoid:ChangeState(11)

							BringMob(closest)

							-- Use selected weapon type for mastery
							if STATE.MasteryType == "Fruit" then
								if closest.Humanoid.Health <= closest.Humanoid.MaxHealth * 0.3 then
									toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 0))
									-- Use fruit skills
									local keys = {}
									if STATE.FruitSkills.Z then table.insert(keys, "Z") end
									if STATE.FruitSkills.X then table.insert(keys, "X") end
									if STATE.FruitSkills.C then table.insert(keys, "C") end
									if STATE.FruitSkills.V then table.insert(keys, "V") end
									for _, key in ipairs(keys) do
										VIM:SendKeyEvent(true, key, false, game)
										task.wait(0.1)
										VIM:SendKeyEvent(false, key, false, game)
										task.wait(0.15)
									end
								else
									equipWeapon("Melee")
									toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 0))
									Attack(closest)
								end
							elseif STATE.MasteryType == "Gun" then
								if closest.Humanoid.Health <= closest.Humanoid.MaxHealth * 0.3 then
									equipWeapon("Gun")
									toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 8))
									VIM:SendKeyEvent(true, "Z", false, game)
									task.wait(0.1)
									VIM:SendKeyEvent(false, "Z", false, game)
									task.wait(0.2)
									VIM:SendKeyEvent(true, "X", false, game)
									task.wait(0.1)
									VIM:SendKeyEvent(false, "X", false, game)
								else
									equipWeapon("Melee")
									toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 0))
									Attack(closest)
								end
							elseif STATE.MasteryType == "Sword" then
								equipWeapon("Sword")
								toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 0))
								Attack(closest)
							end
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("MasteryKey", {
	Default = "None", Text = "Mastery Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

MasteryGroup:AddToggle("AutoKillNearest", {
	Text = "Kill Nearest Mob",
	Default = false,
	Callback = function(v)
		STATE.AutoKillNearest = v
		if v then
			task.spawn(function()
				while STATE.AutoKillNearest do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local closest, closestDist = nil, math.huge
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if mobDist < closestDist then
									closest = mob
									closestDist = mobDist
								end
							end
						end

						if closest then
							EquipWeapon(STATE.SelectedWeapon)
							local mobHRP = closest.HumanoidRootPart
							closest.Humanoid.WalkSpeed = 0
							closest.HumanoidRootPart.CanCollide = false
							closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
							closest.HumanoidRootPart.Transparency = 1
							closest.Humanoid:ChangeState(11)

							local targets = BringMob(closest)
							toTarget(mobHRP.CFrame * CFrame.new(0, STATE.FarmHeight, 5))
							checkAndFixStuck(mobHRP.Position)

							hrp = getHRP()
							if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
								if #targets >= 2 then
									Attack({targets[1], targets[2]})
								else
									Attack(closest)
								end
								useSkills(mobHRP.Position)
							end
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
		else
			detachFloat()
		end
	end,
}):AddKeyPicker("KillNearestKey", {
	Default = "None", Text = "Kill Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

-- Auto Ken (Observation Haki)
local KenGroup = ExtFarmSub:AddLeftGroupbox("Auto Haki", "shield")
KenGroup:AddToggle("AutoKen", {
	Text = "Auto Ken (Observation)",
	Default = false,
	Callback = function(v)
		STATE.AutoKen = v
		if v then
			task.spawn(function()
				while STATE.AutoKen do
					pcall(function()
						local char = LocalPlayer.Character
						if char and not CollectionService:HasTag(char, "Ken") then
							if CommE then CommE:FireServer("Ken", true) end
						end
					end)
					task.wait(0.2)
				end
			end)
		end
	end,
})

KenGroup:AddToggle("AutoBuso", {
	Text = "Auto Buso Haki",
	Default = false,
	Callback = function(v)
		STATE.AutoBuso = v
		if v then
			task.spawn(function()
				while STATE.AutoBuso do
					pcall(function()
						local char = LocalPlayer.Character
						if char and not char:FindFirstChild("HasBuso") then
							CommF:InvokeServer("Buso")
						end
					end)
					task.wait(1)
				end
			end)
		end
	end,
})

-- Auto Team Selection
KenGroup:AddDropdown("AutoTeam", {
	Values = { "Pirates", "Marines" }, Default = "Pirates", Text = "Auto Team",
	Callback = function(v) STATE.AutoTeam = v end,
})
KenGroup:AddButton("Join Team", function()
	pcall(function() CommF:InvokeServer("SetTeam", STATE.AutoTeam) end)
	Library:Notify({ Title = "Ivory", Description = "Joined " .. STATE.AutoTeam, Type = "Success", Time = 3 })
end)

local RaidSub = MainTab:AddSubTab("Raids", "shield")
local RaidGroup = RaidSub:AddLeftGroupbox("Raid Control", "zap")
local RaidSet = RaidSub:AddRightGroupbox("Raid Settings", "settings")

RaidGroup:AddToggle("AutoRaid", {
	Text = "Auto Raid",
	Default = false,
	Callback = function(v)
		STATE.AutoRaid = v
		if v then
			task.spawn(function()
				while STATE.AutoRaid do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						if not (LocalPlayer.Backpack:FindFirstChild("Special Microchip") or (Character and Character:FindFirstChild("Special Microchip"))) then
							pcall(function() CommF:InvokeServer("RaidsNpc", "Buy", STATE.RaidType) end)
							task.wait(1)
						end

						if not (LocalPlayer.Backpack:FindFirstChild("Special Microchip") or (Character and Character:FindFirstChild("Special Microchip"))) then
							return
						end

						pcall(function()
							CommF:InvokeServer("RaidsNpc", "Select", STATE.RaidType)
							task.wait(1)
							CommF:InvokeServer("RaidsNpc", "Start")
						end)
						task.wait(2)

						local raidFolder = Workspace:FindFirstChild("RaidsFolder") or Workspace:FindFirstChild("ridge")
						if not raidFolder then
							raidFolder = Workspace:FindFirstChildWhichIsA("Folder")
						end

						for i = 1, 4 do
							if not STATE.AutoRaid then break end
							repeat task.wait()
								hrp = getHRP()
								if not hrp then break end
								EquipWeapon(STATE.SelectedWeapon)

								local closest, closestDist = nil, math.huge
								local enemies = Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("RaidsFolder")
								if enemies then
									for _, mob in pairs(enemies:GetChildren()) do
										if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
											local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
											if mobDist < closestDist then
												closest = mob
												closestDist = mobDist
											end
										end
									end
								end

							if closest then
								toTarget(closest.HumanoidRootPart.CFrame * CFrame.new(0, 30, 5))
								checkAndFixStuck(closest.HumanoidRootPart.Position)
								closest.Humanoid.WalkSpeed = 0
								closest.HumanoidRootPart.CanCollide = false
								closest.HumanoidRootPart.Size = Vector3.new(60, 60, 60)
								closest.HumanoidRootPart.Transparency = 1
								closest.Humanoid:ChangeState(11)

								hrp = getHRP()
								if hrp and (hrp.Position - closest.HumanoidRootPart.Position).Magnitude <= 150 then
									Attack(closest)
									useSkills(closest.HumanoidRootPart.Position)
								end
								end
							until not STATE.AutoRaid or i > 4
						end

						pcall(function() CommF:InvokeServer("RaidsNpc", "Start") end)
						task.wait(2)
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
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

-- ========================================
-- SEA EVENTS (Phase 2)
-- ========================================
local SeaEventSub = MainTab:AddSubTab("Sea Events", "anchor")
local SeaEventGroup = SeaEventSub:AddLeftGroupbox("Event Farm", "ship")
local SeaEventSettings = SeaEventSub:AddRightGroupbox("Settings", "sliders")

SeaEventGroup:AddDropdown("SeaEventMode", {
	Values = SeaEventNames,
	Default = "Shark", Text = "Event Type",
	Callback = function(v) STATE.SeaEventMode = v end,
})

SeaEventGroup:AddToggle("AutoSeaEvent", {
	Text = "Auto Sea Event",
	Default = false,
	Callback = function(v)
		STATE.SeaEvents = v
		if v then
			task.spawn(function()
				while STATE.SeaEvents do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local targetName = STATE.SeaEventMode
						local closest, closestDist = nil, math.huge

						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob.Name == targetName and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local mobDist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if mobDist < closestDist then
									closest = mob
									closestDist = mobDist
								end
							end
						end

						if closest then
							EquipWeapon(STATE.SelectedWeapon)
							local mobHRP = closest.HumanoidRootPart
							toTarget(mobHRP.CFrame * CFrame.new(0, 50, 8))
							hrp = getHRP()
							if hrp and (hrp.Position - mobHRP.Position).Magnitude <= 150 then
								Attack(closest)
								useSkills(mobHRP.Position)
							end
						else
							task.wait(1)
						end
					end)
					task.wait()
				end
			end)
		end
	end,
}):AddKeyPicker("SeaEventKey", {
	Default = "None", Text = "Sea Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SeaEventGroup:AddToggle("AutoFrozen", {
	Text = "Auto Frozen Dimension",
	Default = false,
	Callback = function(v)
		STATE.AutoFrozen = v
		if v then
			task.spawn(function()
				while STATE.AutoFrozen do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						-- Try to find Frozen Dimension portal
						local frozen = Workspace:FindFirstChild("FrozenDimension")
						if frozen then
							local part = frozen:FindFirstChildWhichIsA("BasePart")
							if part then toTarget(part.Position + Vector3.new(0, 50, 0)) end
						end
						-- Kill FrozenDimension mobs
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if dist <= 1000 then
									EquipWeapon(STATE.SelectedWeapon)
									Attack(mob)
									useSkills(mob.HumanoidRootPart.Position)
								end
							end
						end
					end)
					task.wait()
				end
			end)
		end
	end,
})

SeaEventGroup:AddToggle("AutoKitsune", {
	Text = "Auto Kitsune Island",
	Default = false,
	Callback = function(v)
		STATE.AutoKitsune = v
		if v then
			task.spawn(function()
				while STATE.AutoKitsune do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						-- Find Kitsune shrine NPCs
						local map = Workspace:FindFirstChild("Map")
						if map then
							for _, part in ipairs(map:GetDescendants()) do
								if part:IsA("Model") and (part.Name:find("Kitsune") or part.Name:find("Shrine")) then
									local p = part:FindFirstChildWhichIsA("BasePart")
									if p then toTarget(p.Position + Vector3.new(0, 10, 0)); break end
								end
							end
						end
						-- Kill Kitsune mobs
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob.Name:find("Kitsune") and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								EquipWeapon(STATE.SelectedWeapon)
								toTarget(mob.HumanoidRootPart.CFrame * CFrame.new(0, 30, 5))
								Attack(mob)
								useSkills(mob.HumanoidRootPart.Position)
							end
						end
					end)
					task.wait()
				end
			end)
		end
	end,
})

SeaEventGroup:AddToggle("AutoPrehistoric", {
	Text = "Auto Prehistoric Island",
	Default = false,
	Callback = function(v)
		STATE.AutoPrehistoric = v
		if v then
			task.spawn(function()
				while STATE.AutoPrehistoric do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						-- Find and kill lava golems / dino mobs
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if (mob.Name:find("Lava Golem") or mob.Name:find("Dino") or mob.Name:find("Pterodactyl")) and mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								EquipWeapon(STATE.SelectedWeapon)
								toTarget(mob.HumanoidRootPart.CFrame * CFrame.new(0, 30, 5))
								Attack(mob)
								useSkills(mob.HumanoidRootPart.Position)
							end
						end
					end)
					task.wait()
				end
			end)
		end
	end,
})

SeaEventGroup:AddToggle("AutoMirage", {
	Text = "Auto Mirage Island",
	Default = false,
	Callback = function(v)
		STATE.AutoMirage = v
		if v then
			task.spawn(function()
				while STATE.AutoMirage do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						local map = Workspace:FindFirstChild("Map")
						if map then
							for _, part in ipairs(map:GetDescendants()) do
								if part:IsA("Model") and part.Name:find("Mirage") then
									local p = part:FindFirstChildWhichIsA("BasePart")
									if p then toTarget(p.Position + Vector3.new(0, 10, 0)); break end
								end
							end
						end
						-- Collect gears
						if map then
							for _, gear in ipairs(map:GetDescendants()) do
								if gear:IsA("Part") and gear.Name:find("Gear") then
									toTarget(gear.Position)
								end
							end
						end
					end)
					task.wait()
				end
			end)
		end
	end,
})

SeaEventSettings:AddSlider("BringRange", {
	Text = "Bring Range", Default = 235, Min = 50, Max = 500, Rounding = 0,
	Callback = function(v) STATE.BringRange = v end,
})
SeaEventSettings:AddSlider("MaxBring", {
	Text = "Max Bring Mobs", Default = 3, Min = 1, Max = 10, Rounding = 0,
	Callback = function(v) STATE.MaxBringMobs = v end,
})
SeaEventSettings:AddSlider("FarmHeight", {
	Text = "Farm Height", Default = 20, Min = 5, Max = 50, Rounding = 0,
	Callback = function(v) STATE.FarmHeight = v end,
})

-- ========================================
-- FRUIT SYSTEM (Phase 5)
-- ========================================
local FruitSystemSub = MainTab:AddSubTab("Fruits+", "apple")
local FruitSniperGroup = FruitSystemSub:AddLeftGroupbox("Fruit Sniper", "crosshair")
local FruitStockGroup = FruitSystemSub:AddRightGroupbox("Stock Checker", "package")

FruitSniperGroup:AddDropdown("SniperFruit", {
	Values = FruitShopList,
	Default = "Dragon", Text = "Sniper Target",
	Callback = function(v) STATE.SniperFruit = v end,
})
FruitSniperGroup:AddToggle("AutoFruitSniper", {
	Text = "Auto Buy Sniper Fruit",
	Default = false,
	Callback = function(v)
		STATE.AutoFruitSniper = v
		if v then
			task.spawn(function()
				while STATE.AutoFruitSniper do
					pcall(function()
						local stock = CommF:InvokeServer("getStock")
						if stock then
							for _, item in ipairs(stock) do
								if item[1] == STATE.SniperFruit then
									CommF:InvokeServer("BuyFruit", item[1])
									Library:Notify({ Title = "Ivory", Description = "Bought " .. item[1] .. "!", Type = "Success", Time = 5 })
									STATE.AutoFruitSniper = false
									return
								end
							end
						end
					end)
					task.wait(3)
				end
			end)
		end
	end,
})

FruitSniperGroup:AddToggle("AutoRandomFruit", {
	Text = "Auto Random Fruit",
	Default = false,
	Callback = function(v)
		STATE.AutoRandomFruit = v
		if v then
			task.spawn(function()
				while STATE.AutoRandomFruit do
					-- Scan for cooldown text in Gacha Box UI
					local cooldownSeconds = 0
					pcall(function()
						for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
							if gui:IsA("TextLabel") and gui.Text:find("You must wait") then
								-- Parse "01:46 hours" or "00:05 minutes" etc
								local hours, mins = gui.Text:match("(%d+):(%d+) hours")
								if hours then
									cooldownSeconds = tonumber(hours) * 3600 + tonumber(mins) * 60
								else
									local m, s = gui.Text:match("(%d+):(%d+) minutes")
									if m then cooldownSeconds = tonumber(m) * 60 + tonumber(s) end
								end
								break
							end
						end
					end)

					if cooldownSeconds > 0 then
						Library:Notify({ Title = "Ivory", Description = "Random fruit on cooldown — waiting " .. math.ceil(cooldownSeconds / 60) .. " min", Type = "Info", Time = 3 })
						task.wait(cooldownSeconds + 5)
					else
						pcall(function() CommF:InvokeServer("Cousin", "Buy") end)
						task.wait(5)
					end
				end
			end)
		end
	end,
})

FruitSniperGroup:AddButton("Drop All Fruits", function()
	pcall(function()
		for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:find("Fruit") then
				tool.Parent = LocalPlayer.Character
				task.wait(0.1)
				if tool:FindFirstChild("EatRemote") then
					tool.EatRemote:InvokeServer("Drop")
				end
			end
		end
		for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:find("Fruit") then
				if tool:FindFirstChild("EatRemote") then
					tool.EatRemote:InvokeServer("Drop")
				end
			end
		end
		Library:Notify({ Title = "Ivory", Description = "Dropped all fruits!", Type = "Success", Time = 3 })
	end)
end)

FruitStockGroup:AddButton("Check Fruit Stock", function()
	pcall(function()
		local stock = CommF:InvokeServer("getStock")
		if stock then
			local msg = "Fruit Stock:\n"
			for _, item in ipairs(stock) do
				msg = msg .. item[1] .. " - $" .. tostring(item[2]) .. "\n"
			end
			Library:Notify({ Title = "Ivory", Description = msg, Type = "Info", Time = 10 })
		end
	end)
end)

FruitStockGroup:AddButton("Check ADV Stock", function()
	pcall(function()
		local stock = CommF:InvokeServer("getStock")
		-- Also check Advanced Dealer
		local advStock = CommF:InvokeServer("Adv_Cousin", "getStock")
		if advStock then
			local msg = "ADV Stock:\n"
			for _, item in ipairs(advStock) do
				msg = msg .. item[1] .. " - $" .. tostring(item[2]) .. "\n"
			end
			Library:Notify({ Title = "Ivory", Description = msg, Type = "Info", Time = 10 })
		end
	end)
end)

FruitStockGroup:AddToggle("AutoBerry", {
	Text = "Auto Collect Berry",
	Default = false,
	Callback = function(v)
		STATE.AutoBerry = v
		if v then
			task.spawn(function()
				while STATE.AutoBerry do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						local map = Workspace:FindFirstChild("Map")
						if map then
							for _, part in ipairs(map:GetDescendants()) do
								if part:IsA("Part") and part.Name:find("Berry") then
									toTarget(part.Position)
								end
							end
						end
					end)
					task.wait()
				end
			end)
		end
	end,
})

-- ========================================
-- RACE V4 (Phase 4)
-- ========================================
local RaceV4Sub = TeleportTab:AddSubTab("Race V4", "users")
local TempleGroup = RaceV4Sub:AddLeftGroupbox("Temple of Time", "landmark")
local TrialsGroup = RaceV4Sub:AddRightGroupbox("Trials & Training", "target")

TempleGroup:AddButton("Teleport to Temple", function()
	-- Teleport to Temple of Time
	local map = Workspace:FindFirstChild("Map")
	if map then
		local temple = map:FindFirstChild("TempleOfTime") or map:FindFirstChild("Temple") or map:FindFirstChild("AncientClock")
		if temple then
			local part = temple:FindFirstChildWhichIsA("BasePart")
			if part then toTarget(part.Position + Vector3.new(0, 50, 0)) end
		end
	end
	-- Try CommF teleport
	pcall(function() CommF:InvokeServer("requestEntrance", Vector3.new(-12462, 378, -7543)) end)
end)

TempleGroup:AddButton("Pull Lever", function()
	pcall(function()
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") and obj.ActionText == "Pull" then
				fireproximityprompt(obj)
			end
		end
	end)
end)

TempleGroup:AddToggle("RaceV4Train", {
	Text = "Auto Train V4",
	Default = false,
	Callback = function(v)
		STATE.RaceV4Train = v
		if v then
			task.spawn(function()
				while STATE.RaceV4Train do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						-- Find and kill bone mobs for training
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if dist <= 500 then
									EquipWeapon(STATE.SelectedWeapon)
									Attack(mob)
									useSkills(mob.HumanoidRootPart.Position)
								end
							end
						end
						-- Activate RaceEnergy
						pcall(function()
							local char = LocalPlayer.Character
							if char and char:FindFirstChild("RaceEnergy") then
								char.RaceEnergy.Value = 0
							end
						end)
					end)
					task.wait()
				end
			end)
		end
	end,
})

TrialsGroup:AddButton("Auto Complete Trials", function()
	-- Auto attempt race trials
	pcall(function()
		CommF:InvokeServer("RaceV4Progress", "Check")
		task.wait(1)
		CommF:InvokeServer("RaceV4Progress", "Begin")
	end)
end)

TrialsGroup:AddToggle("AutoLookAtMoon", {
	Text = "Auto Look At Moon",
	Default = false,
	Callback = function(v)
		STATE.RaceV4Moon = v
		if v then
			task.spawn(function()
				while STATE.RaceV4Moon do
					pcall(function()
						local char = LocalPlayer.Character
						local hrp = char and char:FindFirstChild("HumanoidRootPart")
						if hrp then
							-- Find moon direction
							local moonDir = Vector3.new(0, 1, 0) -- simplified
							hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + moonDir)
						end
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

TrialsGroup:AddButton("Teleport to Ancient One", function()
	pcall(function()
		CommF:InvokeServer("requestEntrance", Vector3.new(-12462, 378, -7543))
	end)
end)

local CombatSub = CombatTab:AddSubTab("Bounty", "crosshair")
local BountyGroup = CombatSub:AddLeftGroupbox("Bounty Farm", "target")
local BountySet = CombatSub:AddRightGroupbox("Settings", "sliders")

local SkillsSub = CombatTab:AddSubTab("Skills", "zap")
local SkillsGroup = SkillsSub:AddLeftGroupbox("Auto Skills", "swords")
local SkillsSet = SkillsSub:AddRightGroupbox("Skill Config", "sliders")

SkillsGroup:AddToggle("AutoSkill", {
	Text = "Auto Use Skills",
	Default = false,
	Callback = function(v)
		STATE.AutoSkill = v
	end,
}):AddKeyPicker("AutoSkillKey", {
	Default = "None", Text = "Skill Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

SkillsSet:AddToggle("SkillZ", { Text = "Skill Z", Default = true, Callback = function(v) STATE.SkillZ = v end })
SkillsSet:AddToggle("SkillX", { Text = "Skill X", Default = true, Callback = function(v) STATE.SkillX = v end })
SkillsSet:AddToggle("SkillC", { Text = "Skill C", Default = true, Callback = function(v) STATE.SkillC = v end })
SkillsSet:AddToggle("SkillV", { Text = "Skill V", Default = true, Callback = function(v) STATE.SkillV = v end })
SkillsSet:AddToggle("SkillF", { Text = "Skill F", Default = false, Callback = function(v) STATE.FruitSkills.F = v end })

SkillsGroup:AddLabel("Uses fruit skills automatically during combat")

BountyGroup:AddToggle("AutoBounty", {
	Text = "Auto Bounty Farm",
	Default = false,
	Risky = true,
	Callback = function(v)
		STATE.AutoBounty = v
		if v then
			attachFloat()
			task.spawn(function()
				while STATE.AutoBounty do
					pcall(function()
						if STATE.CollectingFruit then task.wait(0.5) return end
						local hrp = getHRP()
						if not hrp then return end

						local closest, closestDist = nil, math.huge
						for _, plr in ipairs(Players:GetPlayers()) do
							if plr ~= LocalPlayer and plr.Character then
								local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
								local targetHum = plr.Character:FindFirstChild("Humanoid")
								if targetHRP and targetHum and targetHum.Health > 0 then
									if not plr.Team or plr.Team ~= LocalPlayer.Team then
										local dist = (targetHRP.Position - hrp.Position).Magnitude
										if dist < closestDist then
											closest = plr
											closestDist = dist
										end
									end
								end
							end
						end

						if closest and closestDist <= STATE.BountyDistance then
							repeat task.wait()
								hrp = getHRP()
								if not hrp then break end
								if not closest.Character then break end
								local targetHRP = closest.Character:FindFirstChild("HumanoidRootPart")
								local targetHum = closest.Character:FindFirstChild("Humanoid")
								if not targetHRP or not targetHum or targetHum.Health <= 0 then break end

								EquipWeapon(STATE.SelectedWeapon)
								toTarget(targetHRP.CFrame * CFrame.new(0, 30, 5))

								hrp = getHRP()
								if hrp and (hrp.Position - targetHRP.Position).Magnitude <= 150 then
									if tick() - LastRotate >= 0.25 then
										AttackRotation = (AttackRotation + 180) % 360
										LastRotate = tick()
									end
									hrp.CFrame = targetHRP.CFrame * CFrame.new(0, 30, 5) * CFrame.Angles(0, math.rad(AttackRotation), 0)
									Attack(closest.Character)
								end
							until not STATE.AutoBounty or closestDist > STATE.BountyDistance
						elseif closest and closestDist > STATE.BountyDistance then
							toTarget(closest.Character.HumanoidRootPart.CFrame)
						end
					end)
					task.wait()
				end
				detachFloat()
			end)
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

-- ========================================
-- PVP SECTION (Phase 8)
-- ========================================
local PvPSub = CombatTab:AddSubTab("PvP", "swords")
local PvPGroup = PvPSub:AddLeftGroupbox("Combat", "crosshair")
local PvPSettings = PvPSub:AddRightGroupbox("Settings", "sliders")

PvPGroup:AddToggle("AutoClick", {
	Text = "Auto Click",
	Default = false,
	Callback = function(v)
		STATE.AutoClick = v
		if v then
			task.spawn(function()
				while STATE.AutoClick do
					pcall(function()
						local char = LocalPlayer.Character
						if char and char:FindFirstChildOfClass("Tool") then
							VirtualUser:CaptureController()
							VirtualUser:Button1Down(Vector2.new(1280, 672))
						end
					end)
					task.wait(STATE.ClickDelay)
				end
			end)
		end
	end,
})

PvPGroup:AddToggle("ToggleCombat", {
	Text = "Toggle Combat (Mob)",
	Default = false,
	Callback = function(v)
		STATE.ToggleCombat = v
		if v then
			task.spawn(function()
				while STATE.ToggleCombat do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						local closest, closestDist = nil, math.huge
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if dist < closestDist then
									closest = mob
									closestDist = dist
								end
							end
						end
						if closest and closestDist <= 500 then
							EquipWeapon(STATE.SelectedWeapon)
							Attack(closest)
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

PvPGroup:AddToggle("KillAura", {
	Text = "Kill Aura (All Nearby)",
	Default = false,
	Risky = true,
	Callback = function(v)
		STATE.KillAura = v
		if v then
			task.spawn(function()
				while STATE.KillAura do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if dist <= 100 then
									EquipWeapon(STATE.SelectedWeapon)
									Attack(mob)
								end
							end
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

PvPGroup:AddToggle("GunAura", {
	Text = "Gun Aura",
	Default = false,
	Risky = true,
	Callback = function(v)
		STATE.GunAuraEnabled = v
		if v then
			task.spawn(function()
				while STATE.GunAuraEnabled do
					pcall(function()
						local hrp = getHRP()
						if not hrp then return end
						local closest, closestDist = nil, math.huge
						for _, mob in ipairs(workspace.Enemies:GetChildren()) do
							if mob:FindFirstChild("HumanoidRootPart") and mob:FindFirstChild("Humanoid") and mob.Humanoid.Health > 0 then
								local dist = (mob.HumanoidRootPart.Position - hrp.Position).Magnitude
								if dist < closestDist and dist <= STATE.GunAuraRange then
									closest = mob
									closestDist = dist
								end
							end
						end
						if closest then
							equipWeapon("Gun")
							local net = Modules and Modules:FindFirstChild("Net")
							local shoot = net and net:FindFirstChild("RE/ShootGunEvent")
							if shoot then
								pcall(function() shoot:FireServer(closest.HumanoidRootPart.Position, {closest.HumanoidRootPart}) end)
							end
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

PvPSettings:AddDropdown("AimMethod", {
	Values = { "AimBot Skill", "Auto Aimbots" }, Default = "AimBot Skill", Text = "Aim Method",
	Callback = function(v) STATE.AimMethod = v end,
})
PvPSettings:AddSlider("GunAuraRange", {
	Text = "Gun Range", Default = 500, Min = 100, Max = 2000, Rounding = 0,
	Callback = function(v) STATE.GunAuraRange = v end,
})
PvPSettings:AddSlider("ClickDelay", {
	Text = "Click Delay", Default = 0.1, Min = 0.01, Max = 1, Rounding = 2,
	Callback = function(v) STATE.ClickDelay = v end,
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

local QuestNPCData = {
	{"BanditQuest1", 1}, {"MarineQuest", 1}, {"JungleQuest", 1}, {"BuggyQuest1", 1},
	{"DesertQuest", 1}, {"SnowQuest", 1}, {"MarineQuest2", 1}, {"SkyQuest", 1},
	{"PrisonerQuest", 1}, {"ColosseumQuest", 1}, {"MagmaQuest", 1}, {"FishmanQuest", 1},
}
for _, data in ipairs(QuestNPCData) do
	QuestNPCGroup:AddButton(data[1], function()
		pcall(function() CommF:InvokeServer("StartQuest", data[1], data[2]) end)
	end)
end

for _, npc in ipairs({"Sword Dealer", "Archangel", "Master of Enhancement", "Expert Swordsman", "Blox Fruits Dealer"}) do
	ShopNPCGroup:AddButton(npc, function()
		pcall(function() CommF:InvokeServer("Buy" .. npc:gsub("%s+", "")) end)
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

WorldESP:AddToggle("ESPIsland", {
	Text = "Island ESP", Default = false,
	Callback = function(v) STATE.ESPIsland = v end,
})

WorldESP:AddToggle("ESPFlower", {
	Text = "Flower ESP", Default = false,
	Callback = function(v) STATE.ESPFlower = v end,
})

WorldESP:AddToggle("ESPGear", {
	Text = "Gear ESP", Default = false,
	Callback = function(v) STATE.ESPGear = v end,
})

WorldESP:AddToggle("ESPAdvDealer", {
	Text = "Adv Dealer ESP", Default = false,
	Callback = function(v) STATE.ESPAdvDealer = v end,
})

WorldESP:AddToggle("ESPHakiColor", {
	Text = "Haki Color ESP", Default = false,
	Callback = function(v) STATE.ESPHakiColor = v end,
})

WorldESP:AddToggle("ESPBerry", {
	Text = "Berry ESP", Default = false,
	Callback = function(v) STATE.ESPBerry = v end,
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
			task.spawn(function()
				while STATE.WalkOnWater do
					pcall(function()
						local hrp = getHRP()
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

MiscGroup:AddButton("Admin Detection Hop", function()
	task.spawn(function()
		while true do
			task.wait(10)
			pcall(function()
				for _, plr in ipairs(Players:GetPlayers()) do
					for _, adminName in ipairs(AdminNames) do
						if plr.Name:lower():find(adminName:lower()) then
							Library:Notify({ Title = "Ivory", Description = "Admin detected: " .. plr.Name .. " - Hopping!", Type = "Warning", Time = 5 })
							task.wait(1)
							-- hop to new server
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
							return
						end
					end
				end
			end)
		end
	end)
end)

MiscGroup:AddButton("Low CPU Mode", function()
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		local Terrain = workspace:FindFirstChildOfClass("Terrain")
		if Terrain then
			Terrain.WaterWaveSize = 0
			Terrain.WaterWaveSpeed = 0
			Terrain.WaterReflectance = 0
			Terrain.WaterTransparency = 0
		end
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
			elseif obj:IsA("MeshPart") then
				obj.Material = Enum.Material.SmoothPlastic
				obj.Reflectance = 0
			end
		end
		Library:Notify({ Title = "Ivory", Description = "Low CPU mode enabled", Type = "Info", Time = 3 })
	end)
end)

-- ========================================
-- PLAYER SUBTABS: Infinite Abilities, Buy, Craft
-- ========================================
local PlayerMiscSub = PlayerTab:AddSubTab("Abilities", "star")

local AbilityGroup = PlayerMiscSub:AddLeftGroupbox("Infinite Abilities", "zap")
AbilityGroup:AddToggle("InfiniteEnergy", {
	Text = "Infinite Energy", Default = false,
	Callback = function(v)
		STATE.InfiniteEnergy = v
		if v then
			task.spawn(function()
				while STATE.InfiniteEnergy do
					pcall(function()
						local char = LocalPlayer.Character
						if char and char:FindFirstChild("Energy") then
							char.Energy.Value = char.Energy.MaxValue
						end
					end)
					task.wait(0.1)
				end
			end)
		end
	end,
})

AbilityGroup:AddToggle("InfiniteSoru", {
	Text = "Infinite Soru", Default = false,
	Callback = function(v)
		STATE.InfiniteSoru = v
		if v then
			task.spawn(function()
				while STATE.InfiniteSoru do
					pcall(function()
						local char = LocalPlayer.Character
						if char and char:FindFirstChild("Soru") then
							for _, func in ipairs(getgc()) do
								if typeof(func) == "function" and getfenv(func).script == char.Soru then
									for _, upval in ipairs(getupvalues(func)) do
										if typeof(upval) == "table" then
											upval.LastUse = 0
										end
									end
								end
							end
						end
					end)
					task.wait(0.5)
				end
			end)
		end
	end,
})

AbilityGroup:AddToggle("InfiniteObservation", {
	Text = "Infinite Observation", Default = false,
	Callback = function(v)
		STATE.InfiniteObservation = v
		if v then
			pcall(function()
				LocalPlayer.VisionRadius.Value = math.huge
			end)
		end
	end,
})

local BuyGroup = PlayerMiscSub:AddRightGroupbox("Shop", "shopping-cart")

BuyGroup:AddDropdown("BuyMelee", {
	Values = FightingStyleShop, Default = "None", Text = "Buy Melee",
	Callback = function(v) STATE.BuyMelee = v end,
})
BuyGroup:AddButton("Buy Selected Melee", function()
	if STATE.BuyMelee ~= "None" then
		pcall(function() CommF:InvokeServer("Buy" .. STATE.BuyMelee:gsub("%s+", "")) end)
		Library:Notify({ Title = "Ivory", Description = "Buying " .. STATE.BuyMelee, Type = "Info", Time = 3 })
	end
end)

BuyGroup:AddDropdown("BuySword", {
	Values = SwordShop, Default = "None", Text = "Buy Sword",
	Callback = function(v) STATE.BuySword = v end,
})
BuyGroup:AddButton("Buy Selected Sword", function()
	if STATE.BuySword ~= "None" then
		pcall(function() CommF:InvokeServer("Buy" .. STATE.BuySword:gsub("%s+", "")) end)
		Library:Notify({ Title = "Ivory", Description = "Buying " .. STATE.BuySword, Type = "Info", Time = 3 })
	end
end)

BuyGroup:AddDropdown("BuyAccessory", {
	Values = AccessoryShop, Default = "None", Text = "Buy Accessory",
	Callback = function(v) STATE.BuyAccessory = v end,
})
BuyGroup:AddButton("Buy Selected Accessory", function()
	if STATE.BuyAccessory ~= "None" then
		pcall(function() CommF:InvokeServer("Buy" .. STATE.BuyAccessory:gsub("%s+", "")) end)
		Library:Notify({ Title = "Ivory", Description = "Buying " .. STATE.BuyAccessory, Type = "Info", Time = 3 })
	end
end)

local CraftGroup = PlayerMiscSub:AddLeftGroupbox("Craft / Race", "hammer")
CraftGroup:AddDropdown("CraftItem", {
	Values = SeaEventShopItems, Default = "None", Text = "Craft Sea Item",
	Callback = function(v) STATE.CraftItem = v end,
})
CraftGroup:AddButton("Craft Selected Item", function()
	if STATE.CraftItem ~= "None" then
		pcall(function() CommF:InvokeServer("CraftItem", STATE.CraftItem) end)
		Library:Notify({ Title = "Ivory", Description = "Crafting " .. STATE.CraftItem, Type = "Info", Time = 3 })
	end
end)

CraftGroup:AddDropdown("ChangeRace", {
	Values = { "Ghoul", "Cyborg" }, Default = "None", Text = "Change Race",
	Callback = function(v) STATE.ChangeRace = v end,
})
CraftGroup:AddButton("Buy Race Change", function()
	if STATE.ChangeRace ~= "None" then
		pcall(function() CommF:InvokeServer("Buy" .. STATE.ChangeRace) end)
		Library:Notify({ Title = "Ivory", Description = "Buying " .. STATE.ChangeRace .. " race", Type = "Info", Time = 3 })
	end
end)

CraftGroup:AddButton("Buy Haki (Flowing)", function()
	pcall(function() CommF:InvokeServer("Buso", 1) end)
end)
CraftGroup:AddButton("Buy Soru", function()
	pcall(function() CommF:InvokeServer("BuyHaki", "Soru") end)
end)
CraftGroup:AddButton("Buy Geppo", function()
	pcall(function() CommF:InvokeServer("BuyHaki", "Geppo") end)
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("game")
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
	Description = "v2.0 loaded successfully",
	Type = "Success",
	Time = 5,
})
