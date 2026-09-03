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
local VIM = game:GetService("VirtualInputManager")

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

--// Patch window icon to use custom image
local IVORY_ICON = "rbxassetid://113133903091338"
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
	pcall(function() trySetIcon(plr.PlayerGui) end)
end)

--// ═══════════════════════════════════════════════════════════
--// CONFIG + STATE
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
	clickSpeed = 0.1,
	statType = "Damage",
	statAmount = 1,
	sellRarity = 1,
	farmWorld = 1,
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
--// UI TABS + SUBTABS
--// ═══════════════════════════════════════════════════════════

local MainTab = Window:AddTab({ Name = "Main", Icon = "swords" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local DungeonTab = Window:AddTab({ Name = "Dungeons", Icon = "swords" })
local EconomyTab = Window:AddTab({ Name = "Economy", Icon = "swords" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "swords" })
local StatusTab = Window:AddTab({ Name = "Status", Icon = "swords" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "swords" })

local FarmingSub = MainTab:AddSubTab("Farming", "rbxassetid://113133903091338")
local QuestSub = MainTab:AddSubTab("Quests", "rbxassetid://113133903091338")
local SkillsSub = CombatTab:AddSubTab("Skills", "rbxassetid://113133903091338")
local StatsSub = CombatTab:AddSubTab("Stats", "rbxassetid://113133903091338")
local DungeonSub = DungeonTab:AddSubTab("Dungeons", "rbxassetid://113133903091338")
local TowerSub = DungeonTab:AddSubTab("Towers", "rbxassetid://113133903091338")
local ForgeSub = EconomyTab:AddSubTab("Forge & Enchant", "rbxassetid://113133903091338")
local MerchantSub = EconomyTab:AddSubTab("Merchants", "rbxassetid://113133903091338")
local MovementSub = VisualsTab:AddSubTab("Movement", "rbxassetid://113133903091338")
local VisualSub = VisualsTab:AddSubTab("Visuals", "rbxassetid://113133903091338")
local LiveSub = StatusTab:AddSubTab("Live", "rbxassetid://113133903091338")
local ToolsSub = StatusTab:AddSubTab("Tools", "rbxassetid://113133903091338")

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB WIDGETS
--// ═══════════════════════════════════════════════════════════

local DiscordGroup = FarmingSub:AddLeftGroupbox("Community", "users")
DiscordGroup:AddButton("Join Discord", function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
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
	Values = { "World 1", "World 2", "World 3", "World 4", "World 5", "World 6", "World 7" },
	Default = 1,
	Text = "World",
	Callback = function(v)
		local num = tonumber(v:match("%d+")) or 1
		CONFIG.farmWorld = num
		STATE.note = "Switching to World " .. num
		local worldFolder = workspace:FindFirstChild("Map")
		if worldFolder then
			local worldObj = worldFolder:FindFirstChild("World" .. num) or worldFolder:FindFirstChild("World " .. num)
			if worldObj then
				local teleportPart = worldObj:FindFirstChildWhichIsA("BasePart")
					or worldObj:FindFirstChildWhichIsA("Model") and worldObj:FindFirstChildWhichIsA("Model"):FindFirstChildWhichIsA("BasePart")
				if teleportPart then
					tpTo(teleportPart.Position)
					STATE.note = "Teleported to World " .. num
				else
					STATE.note = "World " .. num .. " found but no part"
				end
			else
				STATE.note = "World " .. num .. " not found"
			end
		end
	end,
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
--// COMBAT TAB WIDGETS
--// ═══════════════════════════════════════════════════════════

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
--// DUNGEONS TAB WIDGETS
--// ═══════════════════════════════════════════════════════════

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
--// ECONOMY TAB WIDGETS
--// ═══════════════════════════════════════════════════════════

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
--// VISUALS TAB WIDGETS
--// ═══════════════════════════════════════════════════════════

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
--// STATUS TAB WIDGETS
--// ═══════════════════════════════════════════════════════════

local LiveGroup = LiveSub:AddLeftGroupbox("Status", "activity")
local PhaseLabel = LiveGroup:AddLabel("Phase: idle")
local NoteLabel = LiveGroup:AddLabel("Note: -")
local KillsLabel = LiveGroup:AddLabel("Kills: 0")
local LootLabel = LiveGroup:AddLabel("Loot: 0")

local ToolsGroup = ToolsSub:AddLeftGroupbox("Tools", "wrench")
ToolsGroup:AddButton("Teleport to Hub", function()
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
--// REMOTE DISCOVERY (Knit-based: Net/Events + Net/Functions)
--// ═══════════════════════════════════════════════════════════

local Net = ReplicatedStorage:FindFirstChild("Net")
local NetEvents = Net and Net:FindFirstChild("Events")
local NetFunctions = Net and Net:FindFirstChild("Functions")

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
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
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
	end
	if not closest then
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
	end
	return closest
end

local function getDrops()
	local drops = {}
	local dropFolder = workspace:FindFirstChild("Drops") or workspace:FindFirstChild("Loot")
	if dropFolder then
		for _, obj in ipairs(dropFolder:GetChildren()) do
			if obj:IsA("BasePart") or obj:IsA("Tool") then
				table.insert(drops, obj)
			end
		end
	end
	return drops
end

local function shortNumber(n)
	n = tonumber(n) or 0
	for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then return string.format("%.1f%s", n / u[1], u[2]) end
	end
	return tostring(math.floor(n))
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
--// COMBAT (via VirtualInputManager - bypasses anti-exploit)
--// ═══════════════════════════════════════════════════════════

local function vimClick()
	VIM:SendMouseButtonEvent(0, 0, 0, true, game, 1)
	task.wait(0.05)
	VIM:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end

local function vimSkill(slot)
	local keys = { [1] = Enum.KeyCode.One, [2] = Enum.KeyCode.Two, [3] = Enum.KeyCode.Three }
	local key = keys[slot]
	if key then
		VIM:SendKeyEvent(true, key, false, game)
		task.wait(0.05)
		VIM:SendKeyEvent(false, key, false, game)
	end
end

--// ═══════════════════════════════════════════════════════════
--// CORE LOOPS
--// ═══════════════════════════════════════════════════════════

local function farmLoop()
	if not CONFIG.autoFarm then return end
	local enemy = getClosestEnemy(500)
	if enemy then
		STATE.phase = "farming"
		local hrp = rootPart()
		local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
		if hrp and ehrp then
			local dist = (ehrp.Position - hrp.Position).Magnitude
			if dist > 5 then
				hrp.CFrame = CFrame.lookAt(
					(ehrp.CFrame * CFrame.new(0, 2, 5)).Position,
					ehrp.Position
				)
				task.wait(0.1)
			end
		end
		if CONFIG.autoSwing then vimClick() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then vimSkill(1) end
			if CONFIG.skillSlot2 then vimSkill(2) end
			if CONFIG.skillSlot3 then vimSkill(3) end
		end
	else
		STATE.phase = "searching"
		local enemies = workspace:FindFirstChild("Enemies")
		if enemies then
			local children = enemies:GetChildren()
			if #children > 0 then
				local target = children[math.random(1, #children)]
				if target:IsA("Model") then
					local p = target:GetPivot()
					if p then tpTo(p.Position) end
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
	for _ = 1, CONFIG.statAmount do
		safeFire("Inventory", "UpgradeStat", CONFIG.statType)
	end
	STATE.statsUpgraded += CONFIG.statAmount
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
	safeFire("Teleport", "Dungeon")
	local enemy = getClosestEnemy(300)
	if enemy then
		local hrp = rootPart()
		local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
		if hrp and ehrp then
			hrp.CFrame = CFrame.lookAt(
				(ehrp.CFrame * CFrame.new(0, 2, 5)).Position,
				ehrp.Position
			)
		end
		if CONFIG.autoSwing then vimClick() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then vimSkill(1) end
			if CONFIG.skillSlot2 then vimSkill(2) end
			if CONFIG.skillSlot3 then vimSkill(3) end
		end
	end
	if CONFIG.dungeonLeave then
		safeFire("Teleport", "Leave")
	end
end

local function towerLoop()
	if not CONFIG.autoTower then return end
	STATE.phase = "tower"
	safeFire("Teleport", "Tower")
	local enemy = getClosestEnemy(300)
	if enemy then
		local hrp = rootPart()
		local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
		if hrp and ehrp then
			hrp.CFrame = CFrame.lookAt(
				(ehrp.CFrame * CFrame.new(0, 2, 5)).Position,
				ehrp.Position
			)
		end
		if CONFIG.autoSwing then vimClick() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then vimSkill(1) end
			if CONFIG.skillSlot2 then vimSkill(2) end
			if CONFIG.skillSlot3 then vimSkill(3) end
		end
	end
end

local function infiniteTowerLoop()
	if not CONFIG.autoInfiniteTower then return end
	STATE.phase = "infinite tower"
	safeFire("Teleport", "InfiniteTower")
	local enemy = getClosestEnemy(300)
	if enemy then
		local hrp = rootPart()
		local ehrp = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
		if hrp and ehrp then
			hrp.CFrame = CFrame.lookAt(
				(ehrp.CFrame * CFrame.new(0, 2, 5)).Position,
				ehrp.Position
			)
		end
		if CONFIG.autoSwing then vimClick() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then vimSkill(1) end
			if CONFIG.skillSlot2 then vimSkill(2) end
			if CONFIG.skillSlot3 then vimSkill(3) end
		end
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
--// LOOP HELPER
--// ═══════════════════════════════════════════════════════════

local function loop(interval, enabled, fn)
	task.spawn(function()
		while true do
			if CONFIG[enabled] then pcall(fn) end
			task.wait(interval)
		end
	end)
end

--// ═══════════════════════════════════════════════════════════
--// BACKGROUND LOOPS
--// ═══════════════════════════════════════════════════════════

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
			local enemies = workspace:FindFirstChild("Enemies")
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

-- Core loops (combat runs every 0.3s via farmLoop, no separate swing loop)
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

Library:OnUnload(function()
	stopFly()
	stopNoclip()
end)

print("[Ivory] Loot Up loaded!")
