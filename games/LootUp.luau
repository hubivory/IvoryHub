--// Ivory Hub | [EVO] Loot Up!
--// Place ID: 83622406313819

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local plr = Players.LocalPlayer
local PlaceId = game.PlaceId

--// ═══════════════════════════════════════════════════════════
--// OBSIDIAN ULTRA
--// ═══════════════════════════════════════════════════════════

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

--// ═══════════════════════════════════════════════════════════
--// WINDOW
--// ═══════════════════════════════════════════════════════════

local isLobby = false
pcall(function()
	isLobby = plr.Character == nil
end)

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.4 |",
		{ Text = isLobby and "Lobby" or "Game", Copyable = true },
		"|",
		{ Text = tostring(plr.UserId), Copyable = true },
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

--// ═══════════════════════════════════════════════════════════
--// UI TABS (created early so they always show)
--// ═══════════════════════════════════════════════════════════

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local DungeonTab = Window:AddTab({ Name = "Dungeons", Icon = "castle" })
local EconomyTab = Window:AddTab({ Name = "Economy", Icon = "coins" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local StatusTab = Window:AddTab({ Name = "Status", Icon = "bar-chart" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

--// ═══════════════════════════════════════════════════════════
--// GAME DATA
--// ═══════════════════════════════════════════════════════════

local CONFIG = {
	autoFarm = false,
	autoSwing = true,
	autoLoot = false,
	autoSkills = false,
	autoQuests = false,
	autoSell = false,
	autoEquip = false,
	autoForge = false,
	autoEnchant = false,
	autoDungeon = false,
	autoTower = false,
	autoInfiniteTower = false,
	autoStats = false,
	autoRebirth = false,
	autoPotions = false,
	autoDaily = false,
	autoSpin = false,
	autoDodge = false,
	fly = false,
	flySpeed = 50,
	infiniteJump = false,
	noclip = false,
	antiAFK = false,
	hitboxExpand = false,
	hitboxSize = 15,
	walkSpeed = 16,
	jumpPower = 50,
	statType = "Damage",
	statAmount = 1,
	sellRarity = 1,
	farmWorld = 1,
	farmZone = "All",
	skillSlot1 = true,
	skillSlot2 = true,
	skillSlot3 = true,
	dungeonLeave = false,
	towerSpeed = false,
}

local STATE = {
	phase = "idle",
	note = "-",
	kills = 0,
	lootCollected = 0,
	questsClaimed = 0,
	forgesDone = 0,
	enchantDone = 0,
	dungeonsCleared = 0,
	towersCleared = 0,
	rebirths = 0,
	statsUpgraded = 0,
	potionsUsed = 0,
}

--// ═══════════════════════════════════════════════════════════
--// REMOTE DISCOVERY (Knit-based: Net/Events + Net/Functions)
--// ═══════════════════════════════════════════════════════════

local Net = ReplicatedStorage:WaitForChild("Net", 10)
local NetEvents = Net and Net:WaitForChild("Events", 5)
local NetFunctions = Net and Net:WaitForChild("Functions", 5)

local RemoteCache = {}
local function getRemote(name)
	if RemoteCache[name] then return RemoteCache[name] end
	local remote
	if NetEvents then remote = NetEvents:FindFirstChild(name) end
	if not remote and NetFunctions then remote = NetFunctions:FindFirstChild(name) end
	if remote then
		RemoteCache[name] = remote
		return remote
	end
	return nil
end

local function fireRemote(name, ...)
	local remote = getRemote(name)
	if remote then
		if remote:IsA("RemoteEvent") then
			remote:FireServer(...)
		elseif remote:IsA("RemoteFunction") then
			return remote:InvokeServer(...)
		end
	end
end

local function safeFire(name, ...)
	local args = { ... }
	pcall(function() fireRemote(name, unpack(args)) end)
end

--// ═══════════════════════════════════════════════════════════
--// MODULE DATA
--// ═══════════════════════════════════════════════════════════

local function getModule(name)
	local ok, mod = pcall(function() return require(ReplicatedStorage:WaitForChild(name, 5)) end)
	return ok and mod or nil
end

local EnemyData = getModule("Enemies") or getModule("EnemyData") or {}
local BossData = getModule("Bosses") or getModule("BossData") or {}
local ItemData = getModule("ItemData") or getModule("Items") or {}
local SkillData = getModule("Skills") or getModule("SkillData") or {}
local EquipmentData = getModule("Equipment") or {}
local RarityNames = getModule("RarityNames") or {}
local StatNames = getModule("StatNames") or {}
local WorldData = getModule("Worlds") or getModule("WorldData") or {}

--// ═══════════════════════════════════════════════════════════
--// UTILITY
--// ═══════════════════════════════════════════════════════════

local function rootPart()
	local char = plr.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
	local char = plr.Character
	return char and char:FindFirstChildWhichIsA("Humanoid")
end

local function shortNumber(n)
	n = tonumber(n) or 0
	for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then return string.format("%.1f%s", n / u[1], u[2]) end
	end
	return tostring(math.floor(n))
end

local function getCharacter()
	return plr.Character or plr.CharacterAdded:Wait()
end

local function tpTo(pos)
	local hrp = rootPart()
	if hrp then
		hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
	end
end

local function getClosestEnemy(maxDist)
	maxDist = maxDist or 500
	local hrp = rootPart()
	if not hrp then return nil end
	local closest, closestDist
	local enemies = workspace:FindFirstChild("EnemySpawns") or workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mobs")
	if not enemies then
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj ~= plr.Character then
				local hum = obj:FindFirstChild("Humanoid")
				local hrp2 = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
				if hum and hrp2 and hum.Health > 0 then
					local dist = (hrp2.Position - hrp.Position).Magnitude
					if dist < maxDist and (not closestDist or dist < closestDist) then
						closest = obj
						closestDist = dist
					end
				end
			end
		end
		return closest
	end
	for _, mob in ipairs(enemies:GetChildren()) do
		if mob:IsA("Model") then
			local hum = mob:FindFirstChild("Humanoid")
			local hrp2 = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
			if hum and hrp2 and hum.Health > 0 then
				local dist = (hrp2.Position - hrp.Position).Magnitude
				if dist < maxDist and (not closestDist or dist < closestDist) then
					closest = mob
					closestDist = dist
				end
			end
		end
	end
	return closest
end

local function getDrops()
	local drops = {}
	local dropFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Loot") or workspace:FindFirstChild("Drop")
	if dropFolder then
		for _, obj in ipairs(dropFolder:GetChildren()) do
			if obj:IsA("BasePart") or obj:IsA("Tool") then
				table.insert(drops, obj)
			end
		end
	end
	return drops
end

--// ═══════════════════════════════════════════════════════════
--// MOVEMENT
--// ═══════════════════════════════════════════════════════════

local flyBV, flyBG
local function startFly()
	local hrp = rootPart()
	if not hrp then return end
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	flyBV.Velocity = Vector3.new(0, 0, 0)
	flyBV.Parent = hrp
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	flyBG.P = 9000
	flyBG.D = 500
	flyBG.Parent = hrp
end

local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
end

local noclipConn = nil
local function startNoclip()
	noclipConn = RunService.Stepped:Connect(function()
		local char = plr.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end
	end)
end

local function stopNoclip()
	if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end

--// ═══════════════════════════════════════════════════════════
--// COMBAT
--// ═══════════════════════════════════════════════════════════

local function attackEnemy(enemy)
	if not enemy or not enemy.Parent then return end
	local hrp = rootPart()
	if not hrp then return end
	local enemyHRP = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
	if not enemyHRP then return end

	local dist = (enemyHRP.Position - hrp.Position).Magnitude
	if dist > 10 then
		tpTo(enemyHRP.Position + Vector3.new(0, 0, 3))
		task.wait(0.2)
	end

	safeFire("Combat", "Attack", enemyHRP.CFrame, enemy.Name)
end

local function useSkills()
	local enemy = getClosestEnemy(500)
	if not enemy then return end
	local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
	if not ehrp then return end
	if CONFIG.skillSlot1 then safeFire("SkillCast", 1, ehrp.Position) end
	task.wait(0.1)
	if CONFIG.skillSlot2 then safeFire("SkillCast", 2, ehrp.Position) end
	task.wait(0.1)
	if CONFIG.skillSlot3 then safeFire("SkillCast", 3, ehrp.Position) end
end

--// ═══════════════════════════════════════════════════════════
--// CORE LOOPS
--// ═══════════════════════════════════════════════════════════

local function farmLoop()
	local enemy = getClosestEnemy(500)
	if enemy then
		STATE.phase = "farming"
		attackEnemy(enemy)
		if CONFIG.autoSkills then useSkills() end
		if CONFIG.autoLoot then
			for _, drop in ipairs(getDrops()) do
				if drop:IsA("BasePart") then
					tpTo(drop.Position)
					task.wait(0.1)
				elseif drop:IsA("Tool") and drop:FindFirstChild("Handle") then
					tpTo(drop.Handle.Position)
					task.wait(0.1)
				end
			end
			safeFire("CollectLoot")
			safeFire("LootAll")
			safeFire("CollectAll")
		end
	else
		STATE.phase = "searching"
		-- Teleport to enemy spawn area
		local spawns = workspace:FindFirstChild("EnemySpawns") or workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mobs")
		if spawns then
			local children = spawns:GetChildren()
			if #children > 0 then
				local target = children[math.random(1, #children)]
				if target:IsA("Model") then
					tpTo(target:GetPivot().Position)
				elseif target:IsA("BasePart") then
					tpTo(target.Position)
				end
			end
		end
	end
end

local function collectLoop()
	if not CONFIG.autoLoot then return end
	for _, drop in ipairs(getDrops()) do
		if drop:IsA("BasePart") then
			tpTo(drop.Position)
			task.wait(0.15)
		elseif drop:IsA("Tool") and drop:FindFirstChild("Handle") then
			tpTo(drop.Handle.Position)
			task.wait(0.15)
		end
	end
	safeFire("LootDrop")
end

local function questLoop()
	if not CONFIG.autoQuests then return end
	STATE.phase = "quests"
	safeFire("Quest")
	STATE.questsClaimed += 1
end

local function equipLoop()
	if not CONFIG.autoEquip then return end
	safeFire("Inventory", "EquipBest")
end

local function sellLoop()
	if not CONFIG.autoSell then return end
	STATE.phase = "selling"
	safeFire("Inventory", "Sell")
end

local function forgeLoop()
	if not CONFIG.autoForge then return end
	STATE.phase = "forging"
	safeFire("Forge")
	STATE.forgesDone += 1
end

local function enchantLoop()
	if not CONFIG.autoEnchant then return end
	STATE.phase = "enchanting"
	safeFire("Enchant")
	STATE.enchantDone += 1
end

local function statsLoop()
	if not CONFIG.autoStats then return end
	STATE.phase = "stats"
	local amount = CONFIG.statAmount or 1
	for _ = 1, amount do
		safeFire("Inventory", "UpgradeStat", CONFIG.statType)
	end
	STATE.statsUpgraded += amount
end

local function dailyLoop()
	if not CONFIG.autoDaily then return end
	safeFire("Reward")
end

local function potionLoop()
	if not CONFIG.autoPotions then return end
	safeFire("Inventory", "UsePotion")
	STATE.potionsUsed += 1
end

local function dungeonLoop()
	if not CONFIG.autoDungeon then return end
	STATE.phase = "dungeon"
	local pad = workspace:FindFirstChild("DungeonPad") or workspace:FindFirstChild("Dungeon")
	if pad then
		local padPart = pad:IsA("BasePart") and pad or pad:FindFirstChildWhichIsA("BasePart")
		if padPart then
			tpTo(padPart.Position)
			safeFire("Teleport", "Dungeon")
		end
	end
	local enemy = getClosestEnemy(300)
	if enemy then
		attackEnemy(enemy)
		if CONFIG.autoSkills then useSkills() end
	end
	if CONFIG.dungeonLeave then
		safeFire("Teleport", "Leave")
	end
end

local function towerLoop()
	if not CONFIG.autoTower then return end
	STATE.phase = "tower"
	local pad = workspace:FindFirstChild("TowerPad") or workspace:FindFirstChild("Tower")
	if pad then
		local padPart = pad:IsA("BasePart") and pad or pad:FindFirstChildWhichIsA("BasePart")
		if padPart then
			tpTo(padPart.Position)
			safeFire("Teleport", "Tower")
		end
	end
	local enemy = getClosestEnemy(300)
	if enemy then
		attackEnemy(enemy)
		if CONFIG.autoSkills then useSkills() end
	end
end

local function infiniteTowerLoop()
	if not CONFIG.autoInfiniteTower then return end
	STATE.phase = "infinite tower"
	local pad = workspace:FindFirstChild("InfiniteTowerPad") or workspace:FindFirstChild("InfiniteTower")
	if pad then
		local padPart = pad:IsA("BasePart") and pad or pad:FindFirstChildWhichIsA("BasePart")
		if padPart then
			tpTo(padPart.Position)
			safeFire("Teleport", "InfiniteTower")
		end
	end
	local enemy = getClosestEnemy(300)
	if enemy then
		attackEnemy(enemy)
		if CONFIG.autoSkills then useSkills() end
	end
end

local function rebirthLoop()
	if not CONFIG.autoRebirth then return end
	safeFire("Inventory", "Rebirth")
	STATE.rebirths += 1
end

local function spinLoop()
	if not CONFIG.autoSpin then return end
	safeFire("Reward", "Spin")
end

local function dodgeLoop()
	if not CONFIG.autoDodge then return end
	safeFire("Dash")
end

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local FarmingSub = MainTab:AddSubTab("Farming", "zap")
local QuestSub = MainTab:AddSubTab("Quests", "check-circle")

local DiscordGroup = FarmingSub:AddLeftGroupbox("Community", "users")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/ivory") end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 })
end)
DiscordGroup:AddLabel("Click above to join our Discord for dupes, updates & more!")

local FarmGroup = FarmingSub:AddRightGroupbox("Auto Farm", "cpu")
FarmGroup:AddToggle("AutoFarm", {
	Text = "Auto Farm",
	Default = false,
	Callback = function(v) CONFIG.autoFarm = v end,
})
FarmGroup:AddToggle("AutoSwing", {
	Text = "Auto Swing",
	Default = true,
	Callback = function(v) CONFIG.autoSwing = v end,
})
FarmGroup:AddToggle("AutoLoot", {
	Text = "Auto Collect Loot",
	Default = false,
	Callback = function(v) CONFIG.autoLoot = v end,
})
FarmGroup:AddDropdown("FarmWorld", {
	Values = { "1", "2", "3", "4", "5", "6", "7" },
	Default = 1,
	Text = "World",
	Callback = function(v) CONFIG.farmWorld = tonumber(v) or 1 end,
})

local EquipGroup = FarmingSub:AddLeftGroupbox("Equipment", "package")
EquipGroup:AddToggle("AutoEquip", {
	Text = "Auto Equip Best",
	Default = false,
	Callback = function(v) CONFIG.autoEquip = v end,
})
EquipGroup:AddToggle("AutoSell", {
	Text = "Auto Sell",
	Default = false,
	Callback = function(v) CONFIG.autoSell = v end,
})
EquipGroup:AddSlider("SellRarity", {
	Text = "Sell Below Rarity",
	Default = 1,
	Min = 1,
	Max = 7,
	Rounding = 0,
	Callback = function(v) CONFIG.sellRarity = v end,
})

local QuestGroup = QuestSub:AddLeftGroupbox("Quests", "check-circle")
QuestGroup:AddToggle("AutoQuests", {
	Text = "Auto Claim Quests",
	Default = false,
	Callback = function(v) CONFIG.autoQuests = v end,
})
QuestGroup:AddToggle("AutoDaily", {
	Text = "Auto Daily Rewards",
	Default = false,
	Callback = function(v) CONFIG.autoDaily = v end,
})
QuestGroup:AddToggle("AutoSpin", {
	Text = "Auto Season Spin",
	Default = false,
	Callback = function(v) CONFIG.autoSpin = v end,
})
QuestGroup:AddToggle("AutoPotions", {
	Text = "Auto Use Potions",
	Default = false,
	Callback = function(v) CONFIG.autoPotions = v end,
})

--// ═══════════════════════════════════════════════════════════
--// COMBAT TAB
--// ═══════════════════════════════════════════════════════════

local SkillsSub = CombatTab:AddSubTab("Skills", "zap")
local StatsSub = CombatTab:AddSubTab("Stats", "bar-chart")

local SkillGroup = SkillsSub:AddLeftGroupbox("Skills", "zap")
SkillGroup:AddToggle("AutoSkills", {
	Text = "Auto Cast Skills",
	Default = false,
	Callback = function(v) CONFIG.autoSkills = v end,
})
SkillGroup:AddToggle("SkillSlot1", {
	Text = "Skill Slot 1",
	Default = true,
	Callback = function(v) CONFIG.skillSlot1 = v end,
})
SkillGroup:AddToggle("SkillSlot2", {
	Text = "Skill Slot 2",
	Default = true,
	Callback = function(v) CONFIG.skillSlot2 = v end,
})
SkillGroup:AddToggle("SkillSlot3", {
	Text = "Skill Slot 3",
	Default = true,
	Callback = function(v) CONFIG.skillSlot3 = v end,
})
SkillGroup:AddToggle("AutoDodge", {
	Text = "Auto Dodge",
	Default = false,
	Callback = function(v) CONFIG.autoDodge = v end,
})

local StatGroup = StatsSub:AddLeftGroupbox("Auto Stats", "bar-chart")
StatGroup:AddToggle("AutoStats", {
	Text = "Auto Upgrade Stats",
	Default = false,
	Callback = function(v) CONFIG.autoStats = v end,
})
StatGroup:AddDropdown("StatType", {
	Values = { "Damage", "Health", "Defence", "Speed", "Luck" },
	Default = "Damage",
	Text = "Stat Type",
	Callback = function(v) CONFIG.statType = v end,
})
StatGroup:AddSlider("StatAmount", {
	Text = "Points Per Click",
	Default = 1,
	Min = 1,
	Max = 50,
	Rounding = 0,
	Callback = function(v) CONFIG.statAmount = v end,
})

local RebirthGroup = StatsSub:AddRightGroupbox("Rebirth", "refresh-cw")
RebirthGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Callback = function(v) CONFIG.autoRebirth = v end,
})

--// ═══════════════════════════════════════════════════════════
--// DUNGEONS TAB
--// ═══════════════════════════════════════════════════════════

local DungeonSub = DungeonTab:AddSubTab("Dungeons", "castle")
local TowerSub = DungeonTab:AddSubTab("Towers", "building")

local DungeonGroup = DungeonSub:AddLeftGroupbox("Dungeons", "castle")
DungeonGroup:AddToggle("AutoDungeon", {
	Text = "Auto Dungeon",
	Default = false,
	Callback = function(v) CONFIG.autoDungeon = v end,
})
DungeonGroup:AddToggle("DungeonLeave", {
	Text = "Auto Leave When Done",
	Default = false,
	Callback = function(v) CONFIG.dungeonLeave = v end,
})

local TowerGroup = TowerSub:AddLeftGroupbox("Towers", "building")
TowerGroup:AddToggle("AutoTower", {
	Text = "Auto Tower",
	Default = false,
	Callback = function(v) CONFIG.autoTower = v end,
})
TowerGroup:AddToggle("AutoInfiniteTower", {
	Text = "Auto Infinite Tower",
	Default = false,
	Callback = function(v) CONFIG.autoInfiniteTower = v end,
})
TowerGroup:AddToggle("TowerSpeed", {
	Text = "x2 Tower Speed",
	Default = false,
	Callback = function(v) CONFIG.towerSpeed = v end,
})

--// ═══════════════════════════════════════════════════════════
--// ECONOMY TAB
--// ═══════════════════════════════════════════════════════════

local ForgeSub = EconomyTab:AddSubTab("Forge & Enchant", "hammer")
local MerchantSub = EconomyTab:AddSubTab("Merchants", "shopping-cart")

local ForgeGroup = ForgeSub:AddLeftGroupbox("Forge", "hammer")
ForgeGroup:AddToggle("AutoForge", {
	Text = "Auto Forge",
	Default = false,
	Callback = function(v) CONFIG.autoForge = v end,
})
ForgeGroup:AddToggle("AutoEnchant", {
	Text = "Auto Enchant",
	Default = false,
	Callback = function(v) CONFIG.autoEnchant = v end,
})

local MerchantGroup = MerchantSub:AddLeftGroupbox("Merchants", "shopping-cart")
MerchantGroup:AddButton("Refresh Stock", function()
	safeFire("GoldMerchant", "Refresh")
end)
MerchantGroup:AddButton("Buy Merchant", function()
	safeFire("GoldMerchant", "Buy")
end)

--// ═══════════════════════════════════════════════════════════
--// VISUALS TAB
--// ═══════════════════════════════════════════════════════════

local MovementSub = VisualsTab:AddSubTab("Movement", "move")
local VisualSub = VisualsTab:AddSubTab("Visuals", "eye")

local MovementGroup = MovementSub:AddLeftGroupbox("Movement", "move")
MovementGroup:AddToggle("Fly", {
	Text = "Fly",
	Default = false,
	Callback = function(v)
		CONFIG.fly = v
		if v then startFly() else stopFly() end
	end,
})
MovementGroup:AddSlider("FlySpeed", {
	Text = "Fly Speed",
	Default = 50,
	Min = 10,
	Max = 200,
	Rounding = 0,
	Callback = function(v) CONFIG.flySpeed = v end,
})
MovementGroup:AddToggle("InfiniteJump", {
	Text = "Infinite Jump",
	Default = false,
	Callback = function(v) CONFIG.infiniteJump = v end,
})
MovementGroup:AddToggle("NoClip", {
	Text = "NoClip",
	Default = false,
	Callback = function(v)
		CONFIG.noclip = v
		if v then startNoclip() else stopNoclip() end
	end,
})
MovementGroup:AddSlider("WalkSpeed", {
	Text = "Walk Speed",
	Default = 16,
	Min = 16,
	Max = 200,
	Rounding = 0,
	Callback = function(v) CONFIG.walkSpeed = v end,
})
MovementGroup:AddSlider("JumpPower", {
	Text = "Jump Power",
	Default = 50,
	Min = 50,
	Max = 300,
	Rounding = 0,
	Callback = function(v) CONFIG.jumpPower = v end,
})
MovementGroup:AddToggle("AntiAFK", {
	Text = "Anti AFK",
	Default = false,
	Callback = function(v) CONFIG.antiAFK = v end,
})

local VisualGroup = VisualSub:AddLeftGroupbox("Visuals", "eye")
VisualGroup:AddToggle("HitboxExpand", {
	Text = "Hitbox Expand",
	Default = false,
	Callback = function(v) CONFIG.hitboxExpand = v end,
})
VisualGroup:AddSlider("HitboxSize", {
	Text = "Hitbox Size",
	Default = 15,
	Min = 5,
	Max = 50,
	Rounding = 0,
	Callback = function(v) CONFIG.hitboxSize = v end,
})

--// ═══════════════════════════════════════════════════════════
--// STATUS TAB
--// ═══════════════════════════════════════════════════════════

local LiveSub = StatusTab:AddSubTab("Live", "activity")
local ToolsSub = StatusTab:AddSubTab("Tools", "wrench")

local LiveGroup = LiveSub:AddLeftGroupbox("Status", "activity")
local PhaseLabel = LiveGroup:AddLabel("Phase: idle")
local NoteLabel = LiveGroup:AddLabel("Note: -")
local KillsLabel = LiveGroup:AddLabel("Kills: 0")
local LootLabel = LiveGroup:AddLabel("Loot: 0")

local ToolsGroup = ToolsSub:AddLeftGroupbox("Tools", "wrench")
ToolsGroup:AddButton("Teleport to Hub", function()
	-- Try common hub locations
	local hub = workspace:FindFirstChild("Hub") or workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("Spawn")
	if hub then
		local part = hub:IsA("BasePart") and hub or hub:FindFirstChildWhichIsA("BasePart")
		if part then tpTo(part.Position) end
	end
end)
ToolsGroup:AddButton("Rejoin Server", function()
	TeleportService:Teleport(PlaceId, plr)
end)
ToolsGroup:AddButton("Server Hop", function()
	pcall(function()
		local servers = HttpService:JSONDecode(request({
			Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET"
		}).Body)
		if servers and servers.data then
			for _, server in ipairs(servers.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					TeleportService:TeleportToPlaceInstance(PlaceId, server.id, plr)
					break
				end
			end
		end
	end)
end)
ToolsGroup:AddButton("Copy JobId", function()
	pcall(function() setclipboard(game.JobId) end)
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
MenuGroup:AddLabel("Menu: RightShift (default)"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

--// ═══════════════════════════════════════════════════════════
--// LOOPS
--// ═══════════════════════════════════════════════════════════

local function loop(interval, enabled, fn)
	task.spawn(function()
		while true do
			if CONFIG[enabled] then pcall(fn) end
			task.wait(interval)
		end
	end)
end

-- Fly movement
task.spawn(function()
	while true do
		if CONFIG.fly then
			local hrp = rootPart()
			local cam = workspace.CurrentCamera
			if hrp and cam then
				local moveDir = Vector3.new(0, 0, 0)
				if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0, 1, 0) end
				if flyBV then flyBV.Velocity = moveDir.Unit * CONFIG.flySpeed end
				if flyBG then flyBG.CFrame = cam.CFrame end
			end
		end
		task.wait()
	end
end)

-- Infinite jump
UserInputService.JumpRequest:Connect(function()
	if CONFIG.infiniteJump then
		pcall(function()
			local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
		end)
	end
end)

-- Anti-AFK
task.spawn(function()
	while true do
		if CONFIG.antiAFK then
			pcall(function() VirtualUser:ClickButton2(Vector2.new()) end)
		end
		task.wait(60)
	end
end)

-- Hitbox expand
task.spawn(function()
	while true do
		if CONFIG.hitboxExpand then
			local enemies = workspace:FindFirstChild("EnemySpawns") or workspace:FindFirstChild("Enemies") or workspace:FindFirstChild("Mobs")
			if enemies then
				for _, mob in ipairs(enemies:GetChildren()) do
					if mob:IsA("Model") then
						local hrp = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
						if hrp then
							hrp.Size = Vector3.new(CONFIG.hitboxSize, CONFIG.hitboxSize, CONFIG.hitboxSize)
							hrp.Transparency = 0.7
							hrp.CanCollide = false
						end
					end
				end
			end
		end
		task.wait(1)
	end
end)

-- Speed/jump enforcement
task.spawn(function()
	while true do
		local hum = getHumanoid()
		if hum then
			if CONFIG.walkSpeed > 16 then hum.WalkSpeed = CONFIG.walkSpeed end
			if CONFIG.jumpPower > 50 then hum.JumpPower = CONFIG.jumpPower end
		end
		task.wait(0.5)
	end
end)

-- Core loops
loop(0.3, "autoFarm", farmLoop)
loop(1, "autoLoot", collectLoop)
loop(3, "autoQuests", questLoop)
loop(2, "autoEquip", equipLoop)
loop(3, "autoSell", sellLoop)
loop(5, "autoForge", forgeLoop)
loop(5, "autoEnchant", enchantLoop)
loop(2, "autoStats", statsLoop)
loop(10, "autoDaily", dailyLoop)
loop(8, "autoPotions", potionLoop)
loop(3, "autoDungeon", dungeonLoop)
loop(3, "autoTower", towerLoop)
loop(3, "autoInfiniteTower", infiniteTowerLoop)
loop(10, "autoRebirth", rebirthLoop)
loop(5, "autoSpin", spinLoop)
loop(1, "autoDodge", dodgeLoop)

-- Status update loop
task.spawn(function()
	while true do
		PhaseLabel:SetText("Phase: " .. STATE.phase)
		NoteLabel:SetText("Note: " .. STATE.note)
		KillsLabel:SetText("Kills: " .. STATE.kills)
		LootLabel:SetText("Loot: " .. STATE.lootCollected)
		task.wait(0.5)
	end
end)

-- Auto swing via remotes
task.spawn(function()
	while true do
		if CONFIG.autoSwing and CONFIG.autoFarm then
			local enemy = getClosestEnemy(500)
			if enemy then
				local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
				if ehrp then
					safeFire("Combat", "Attack", ehrp.CFrame, enemy.Name)
				end
			end
		end
		task.wait(0.2)
	end
end)

Library:OnUnload(function()
	stopFly()
	stopNoclip()
end)

print("[Ivory] Loot Up loaded!")
