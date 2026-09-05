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
local MarketplaceService = game:GetService("MarketplaceService")
local VIM = game:GetService("VirtualInputManager")

local plr = Players.LocalPlayer
local PlaceId = game.PlaceId

--// ═══════════════════════════════════════════════════════════
--// IVORY HUB SAKURA EDITION
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

--// ═══════════════════════════════════════════════════════════
--// WINDOW
--// ═══════════════════════════════════════════════════════════

local isLobby = false
pcall(function()
	isLobby = plr.Character == nil
end)

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 460,
	Height = 360,
	Resizable = true,
	AccentColor = Color3.fromRGB(140, 110, 220),
	CornerRadius = UDim.new(0, 6),
	ToggleKeybind = Enum.KeyCode.RightShift,
	ConfigSaving = true,
	ConfigName = "IvoryHub_LootUp",
	AutoSaveInterval = 60,
})

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
	worldRequestCooldown = 0,
}

--// ═══════════════════════════════════════════════════════════
--// UI TABS
--// ═══════════════════════════════════════════════════════════

local MainTab = Window:CreateTab({Name = "Main"})
local CombatTab = Window:CreateTab({Name = "Combat"})
local DungeonTab = Window:CreateTab({Name = "Dungeons"})
local EconomyTab = Window:CreateTab({Name = "Economy"})
local VisualsTab = Window:CreateTab({Name = "Visuals"})
local StatusTab = Window:CreateTab({Name = "Status"})

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local CommunitySection = MainTab:CreateSection("Community")
CommunitySection:CreateButton({
	Name = "Join Discord",
	Callback = function()
		pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
		Library.Notify({Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3})
	end,
})
CommunitySection:CreateLabel("Click above to join our Discord for dupes, updates & more!")

local FarmSection = MainTab:CreateSection("Auto Farm")
FarmSection:CreateToggle({
	Name = "Auto Farm",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoFarm = v end,
})
FarmSection:CreateToggle({
	Name = "Auto Swing",
	CurrentValue = true,
	Callback = function(v) CONFIG.autoSwing = v end,
})
FarmSection:CreateToggle({
	Name = "Auto Collect Loot",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoLoot = v end,
})
FarmSection:CreateDropdown({
	Name = "World",
	Options = { "World 1", "World 2", "World 3", "World 4", "World 5", "World 6", "World 7" },
	CurrentOption = "World 1",
	Callback = function(v)
		local num = tonumber(v:match("%d+")) or 1
		CONFIG.farmWorld = num
		STATE.note = "World " .. num .. " selected"
		buildWorldRegions()
		local unlocked = RepCache.Data and RepCache.Data.Worlds
		if unlocked and unlocked["World" .. num] ~= true then
			STATE.note = "World " .. num .. " is locked"
			return
		end
		safeFire("TeleportZone", "World" .. num, 1)
		STATE.note = "Traveling to World " .. num
	end,
})

local EquipSection = MainTab:CreateSection("Equipment")
EquipSection:CreateToggle({
	Name = "Auto Equip Best",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoEquip = v end,
})
EquipSection:CreateToggle({
	Name = "Auto Sell",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoSell = v end,
})
EquipSection:CreateSlider({
	Name = "Sell Below Rarity",
	Range = {1, 7},
	Increment = 1,
	CurrentValue = 1,
	Callback = function(v) CONFIG.sellRarity = v end,
})

local QuestSection = MainTab:CreateSection("Quests")
QuestSection:CreateToggle({
	Name = "Auto Claim Quests",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoQuests = v end,
})
QuestSection:CreateToggle({
	Name = "Auto Daily Rewards",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoDaily = v end,
})
QuestSection:CreateToggle({
	Name = "Auto Season Spin",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoSpin = v end,
})
QuestSection:CreateToggle({
	Name = "Auto Use Potions",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoPotions = v end,
})

--// ═══════════════════════════════════════════════════════════
--// COMBAT TAB
--// ═══════════════════════════════════════════════════════════

local SkillSection = CombatTab:CreateSection("Skills")
SkillSection:CreateToggle({
	Name = "Auto Cast Skills",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoSkills = v end,
})
SkillSection:CreateToggle({
	Name = "Skill Slot 1",
	CurrentValue = true,
	Callback = function(v) CONFIG.skillSlot1 = v end,
})
SkillSection:CreateToggle({
	Name = "Skill Slot 2",
	CurrentValue = true,
	Callback = function(v) CONFIG.skillSlot2 = v end,
})
SkillSection:CreateToggle({
	Name = "Skill Slot 3",
	CurrentValue = true,
	Callback = function(v) CONFIG.skillSlot3 = v end,
})
SkillSection:CreateToggle({
	Name = "Auto Dodge",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoDodge = v end,
})

local StatsSection = CombatTab:CreateSection("Auto Stats")
StatsSection:CreateToggle({
	Name = "Auto Upgrade Stats",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoStats = v end,
})
StatsSection:CreateDropdown({
	Name = "Stat Type",
	Options = { "Damage", "Health", "Defence", "Speed", "Luck" },
	CurrentOption = "Damage",
	Callback = function(v) CONFIG.statType = v end,
})
StatsSection:CreateSlider({
	Name = "Points Per Click",
	Range = {1, 50},
	Increment = 1,
	CurrentValue = 1,
	Callback = function(v) CONFIG.statAmount = v end,
})

local RebirthSection = CombatTab:CreateSection("Rebirth")
RebirthSection:CreateToggle({
	Name = "Auto Rebirth",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoRebirth = v end,
})

--// ═══════════════════════════════════════════════════════════
--// DUNGEONS TAB
--// ═══════════════════════════════════════════════════════════

local DungeonSection = DungeonTab:CreateSection("Dungeons")
DungeonSection:CreateToggle({
	Name = "Auto Dungeon",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoDungeon = v end,
})
DungeonSection:CreateToggle({
	Name = "Auto Leave When Done",
	CurrentValue = false,
	Callback = function(v) CONFIG.dungeonLeave = v end,
})

local TowerSection = DungeonTab:CreateSection("Towers")
TowerSection:CreateToggle({
	Name = "Auto Tower",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoTower = v end,
})
TowerSection:CreateToggle({
	Name = "Auto Infinite Tower",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoInfiniteTower = v end,
})
TowerSection:CreateToggle({
	Name = "x2 Tower Speed",
	CurrentValue = false,
	Callback = function(v) CONFIG.towerSpeed = v end,
})

--// ═══════════════════════════════════════════════════════════
--// ECONOMY TAB
--// ═══════════════════════════════════════════════════════════

local ForgeSection = EconomyTab:CreateSection("Forge")
ForgeSection:CreateToggle({
	Name = "Auto Forge",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoForge = v end,
})
ForgeSection:CreateToggle({
	Name = "Auto Enchant",
	CurrentValue = false,
	Callback = function(v) CONFIG.autoEnchant = v end,
})

local MerchantSection = EconomyTab:CreateSection("Merchants")
MerchantSection:CreateButton({
	Name = "Refresh Stock",
	Callback = function()
		safeFire("GoldMerchant", "Refresh")
	end,
})
MerchantSection:CreateButton({
	Name = "Buy Merchant",
	Callback = function()
		safeFire("GoldMerchant", "Buy")
	end,
})

--// ═══════════════════════════════════════════════════════════
--// VISUALS TAB
--// ═══════════════════════════════════════════════════════════

local MovementSection = VisualsTab:CreateSection("Movement")
MovementSection:CreateToggle({
	Name = "Fly",
	CurrentValue = false,
	Callback = function(v)
		CONFIG.fly = v
		if v then startFly() else stopFly() end
	end,
})
MovementSection:CreateSlider({
	Name = "Fly Speed",
	Range = {10, 200},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) CONFIG.flySpeed = v end,
})
MovementSection:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Callback = function(v) CONFIG.infiniteJump = v end,
})
MovementSection:CreateToggle({
	Name = "NoClip",
	CurrentValue = false,
	Callback = function(v)
		CONFIG.noclip = v
		if v then startNoclip() else stopNoclip() end
	end,
})
MovementSection:CreateSlider({
	Name = "Walk Speed",
	Range = {16, 200},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(v) CONFIG.walkSpeed = v end,
})
MovementSection:CreateSlider({
	Name = "Jump Power",
	Range = {50, 300},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) CONFIG.jumpPower = v end,
})
MovementSection:CreateToggle({
	Name = "Anti AFK",
	CurrentValue = false,
	Callback = function(v) CONFIG.antiAFK = v end,
})

local VisualSection = VisualsTab:CreateSection("Visuals")
VisualSection:CreateToggle({
	Name = "Hitbox Expand",
	CurrentValue = false,
	Callback = function(v) CONFIG.hitboxExpand = v end,
})
VisualSection:CreateSlider({
	Name = "Hitbox Size",
	Range = {5, 50},
	Increment = 1,
	CurrentValue = 15,
	Callback = function(v) CONFIG.hitboxSize = v end,
})

--// ═══════════════════════════════════════════════════════════
--// STATUS TAB
--// ═══════════════════════════════════════════════════════════

local LiveSection = StatusTab:CreateSection("Live Status")
local PhaseLabel = LiveSection:CreateLabel("Phase: idle")
local NoteLabel = LiveSection:CreateLabel("Note: -")
local KillsLabel = LiveSection:CreateLabel("Kills: 0")
local LootLabel = LiveSection:CreateLabel("Loot: 0")

local ToolsSection = StatusTab:CreateSection("Tools")
ToolsSection:CreateButton({
	Name = "Teleport to Hub",
	Callback = function()
		local hub = workspace:FindFirstChild("Hub") or workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("Spawn")
		if hub then
			local part = hub:IsA("BasePart") and hub or hub:FindFirstChildWhichIsA("BasePart")
			if part then tpTo(part.Position) end
		end
	end,
})
ToolsSection:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		TeleportService:Teleport(PlaceId, plr)
	end,
})
ToolsSection:CreateButton({
	Name = "Server Hop",
	Callback = function()
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
	end,
})
ToolsSection:CreateButton({
	Name = "Copy JobId",
	Callback = function()
		pcall(function() setclipboard(game.JobId) end)
		Library.Notify({Title = "Ivory", Content = "JobId copied!", Type = "Success", Duration = 2})
	end,
})

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

--// World regions: each world's map area lives under workspace.Map (e.g. "World1",
--// "World 5"). Enemies carry no World attribute, so classify them by distance to
--// the nearest world region center.
local worldRegions = {}
local worldRegionsBuilt = false

local function buildWorldRegions()
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	worldRegions = {}
	for _, obj in ipairs(map:GetChildren()) do
		local num = tonumber(obj.Name:match("^World%s?(%d+)$"))
		if num then
			local center
			local ok, size, cf = pcall(function()
				local sz, box = obj:GetBoundingBox()
				return sz, box
			end)
			if ok and cf then
				center = cf.Position
			else
				local sum = Vector3.new(0, 0, 0)
				local count = 0
				for _, d in ipairs(obj:GetDescendants()) do
					if d:IsA("BasePart") then
						sum += d.Position
						count += 1
						if count >= 100 then break end
					end
				end
				if count > 0 then
					center = sum / count
				end
			end
			if center then
				worldRegions[num] = center
			end
		end
	end
	worldRegionsBuilt = true
end

local enemyWorldCache = setmetatable({}, { __mode = "k" })
local function enemyWorldNum(enemy)
	if not worldRegionsBuilt then buildWorldRegions() end
	local cached = enemyWorldCache[enemy]
	if cached then return cached end
	local part = enemy:FindFirstChild("HumanoidRootPart") or enemy:FindFirstChild("Head")
	if not part then return nil end
	local pos = part.Position
	local bestNum, bestDist
	for num, center in pairs(worldRegions) do
		local dist = (center - pos).Magnitude
		if not bestDist or dist < bestDist then
			bestNum = num
			bestDist = dist
		end
	end
	enemyWorldCache[enemy] = bestNum
	return bestNum
end

local function getClosestEnemy(maxDist, worldNum)
	maxDist = maxDist or 500
	local hrp = rootPart()
	if not hrp then return nil end
	local function worldMatches(mob)
		if not worldNum then return true end
		return enemyWorldNum(mob) == worldNum
	end
	local closest, closestDist
	local enemies = workspace:FindFirstChild("Enemies")
	if enemies then
		for _, mob in ipairs(enemies:GetChildren()) do
			if mob:IsA("Model") then
				local hum = mob:FindFirstChild("Humanoid")
				local hrp2 = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
				if hum and hrp2 and hum.Health > 0 and worldMatches(mob) then
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
				if hum and hrp2 and hum.Health > 0 and worldMatches(obj) then
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
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name == "LootDrop" and obj:GetAttribute("BasePos") ~= nil then
			table.insert(drops, obj)
		end
	end
	return drops
end

--// Physical loot drops are rendered client-side as "LootDrop" parts parented
--// to workspace. The server assigns each drop a seqId; to collect you must be
--// near the drop and fire Net.Events.LootDrop with that seqId (same thing the
--// game does when you press E). Track seqIds by hooking the "i"/"c" events.
local dropSeqQueue = {}
local function pruneSeqQueue()
	local now = os.clock()
	for i = #dropSeqQueue, 1, -1 do
		if now - dropSeqQueue[i].time > 120 then
			table.remove(dropSeqQueue, i)
		end
	end
end

local function trackDropSeqs()
	local events = Net and Net:FindFirstChild("Events")
	local ldEvent = events and events:FindFirstChild("LootDrop")
	if not ldEvent then return end
	ldEvent.OnClientEvent:Connect(function(kind, ...)
		if kind == "i" then
			local args = { ... }
			local pos = args[1]
			local seq = args[3]
			if pos and seq then
				table.insert(dropSeqQueue, { pos = pos, seq = seq, time = os.clock() })
				if #dropSeqQueue > 100 then table.remove(dropSeqQueue, 1) end
			end
		elseif kind == "c" then
			local seq = select(1, ...)
			for i = #dropSeqQueue, 1, -1 do
				if dropSeqQueue[i].seq == seq then
					table.remove(dropSeqQueue, i)
					break
				end
			end
		end
	end)
end

local function claimSeqForPos(pos)
	pruneSeqQueue()
	for i, entry in ipairs(dropSeqQueue) do
		if (entry.pos - pos).Magnitude < 4 then
			local seq = entry.seq
			table.remove(dropSeqQueue, i)
			return seq
		end
	end
	return nil
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
--// COMBAT (remote-based - does not touch the mouse)
--// ═══════════════════════════════════════════════════════════

-- Fallback input simulation (only used if the Combat remote is missing)
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

-- The game's own client swings via Combat:FireServer("s", "Attack", seq) and
-- casts skills via Combat:FireServer("s", skillName, seq). Using the same path
-- keeps the mouse completely free so the UI stays clickable while farming.
local castSeq = 0
local RepCache = { Data = {}, Cooldowns = {} }

local function applyRepUpdate(ch, key, val)
	local node = RepCache[ch]
	if not node then
		node = {}
		RepCache[ch] = node
	end
	if key == "_CH" then
		if val == "_DEL" then RepCache[ch] = {} end
		return
	end
	local parts = {}
	for part in string.gmatch(key, "[^.]+") do
		table.insert(parts, part)
	end
	local n = node
	for i = 1, #parts - 1 do
		if type(n[parts[i]]) ~= "table" then n[parts[i]] = {} end
		n = n[parts[i]]
	end
	if val == "_DEL" or val == nil then
		n[parts[#parts]] = nil
	else
		n[parts[#parts]] = val
	end
end

local function hookReplication()
	local repEvent = Net and Net:FindFirstChild("Events") and Net.Events:FindFirstChild("Replication")
	if not repEvent then return end
	repEvent.OnClientEvent:Connect(function(kind, payload)
		if kind == "f" then
			for ch, data in pairs(payload) do
				RepCache[ch] = data
			end
		elseif kind == "s" then
			for ch, changes in pairs(payload) do
				for key, val in pairs(changes) do
					applyRepUpdate(ch, key, val)
				end
			end
		end
	end)
	task.spawn(function()
		pcall(function() repEvent:FireServer("f") end)
	end)
end

local function skillNameForSlot(slot)
	local skills = RepCache.Data and RepCache.Data.Skills
	if not skills then return nil end
	return skills[tostring(slot)]
end

local function skillOnCooldown(skillName)
	local cd = RepCache.Cooldowns and RepCache.Cooldowns[skillName]
	if cd and cd[1] and cd[1] - workspace:GetServerTimeNow() > 0 then
		return true
	end
	return false
end

local combatRemoteAvailable = getRemote("Combat") ~= nil

local function doSwing()
	if combatRemoteAvailable then
		castSeq += 1
		safeFire("Combat", "s", "Attack", castSeq)
	else
		vimClick()
	end
end

local function doSkill(slot)
	if not combatRemoteAvailable then
		vimSkill(slot)
		return
	end
	local skillName = skillNameForSlot(slot)
	if not skillName then return end
	if skillOnCooldown(skillName) then return end
	castSeq += 1
	safeFire("Combat", "s", skillName, castSeq)
end

--// ═══════════════════════════════════════════════════════════
--// CORE LOOPS
--// ═══════════════════════════════════════════════════════════

local function farmLoop()
	if not CONFIG.autoFarm then return end
	local targetWorld = CONFIG.farmWorld
	local wanted = "World" .. targetWorld
	local current = RepCache.Data and RepCache.Data.CurrentWorld
	local unlocked = RepCache.Data and RepCache.Data.Worlds
	local effectiveWorld = targetWorld
	if current and unlocked then
		if unlocked[wanted] ~= true then
			-- selected world is locked: keep farming the world we are in
			local curNum = tonumber(current:match("%d+"))
			if curNum then effectiveWorld = curNum end
			STATE.note = "World " .. targetWorld .. " locked - farming World " .. (curNum or "?")
		elseif current ~= wanted then
			local now = os.clock()
			if now - STATE.worldRequestCooldown > 8 then
				STATE.worldRequestCooldown = now
				STATE.note = "Traveling to World " .. targetWorld
				safeFire("TeleportZone", wanted, 1)
			end
		end
	end
	local enemy = getClosestEnemy(500, effectiveWorld)
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
		if CONFIG.autoSwing then doSwing() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then doSkill(1) end
			if CONFIG.skillSlot2 then doSkill(2) end
			if CONFIG.skillSlot3 then doSkill(3) end
		end
	else
		STATE.phase = "searching"
		local enemies = workspace:FindFirstChild("Enemies")
		local pool = {}
		if enemies then
			for _, child in ipairs(enemies:GetChildren()) do
				if child:IsA("Model")
					and child:FindFirstChild("Humanoid")
					and child:FindFirstChild("Humanoid").Health > 0
					and enemyWorldNum(child) == effectiveWorld then
					table.insert(pool, child)
				end
			end
		end
		if #pool > 0 then
			local target = pool[math.random(1, #pool)]
			local p = target:GetPivot()
			if p then tpTo(p.Position) end
		elseif current == ("World" .. effectiveWorld) then
			-- already in the right world but nothing alive nearby: roam to its center
			local center = worldRegions[effectiveWorld]
			if center then tpTo(center) end
		end
	end
end

local function collectLoop()
	if not CONFIG.autoLoot then return end
	local hrp = rootPart()
	if not hrp then return end
	for _, drop in ipairs(getDrops()) do
		if drop:IsA("BasePart") and drop.Parent then
			tpTo(drop.Position)
			task.wait(0.3)
			local seq = claimSeqForPos(drop.Position)
			if seq then
				safeFire("LootDrop", seq)
			else
				-- no seqId tracked: press E near the drop so the game's own
				-- pickup logic (closest drop within 5 studs) claims it
				VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
				task.wait(0.08)
				VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
			end
			STATE.lootCollected += 1
			STATE.phase = "looting"
			task.wait(0.2)
		elseif drop:IsA("Tool") and drop:FindFirstChild("Handle") then
			tpTo(drop.Handle.Position)
			task.wait(0.15)
		end
	end
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
		if CONFIG.autoSwing then doSwing() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then doSkill(1) end
			if CONFIG.skillSlot2 then doSkill(2) end
			if CONFIG.skillSlot3 then doSkill(3) end
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
		if CONFIG.autoSwing then doSwing() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then doSkill(1) end
			if CONFIG.skillSlot2 then doSkill(2) end
			if CONFIG.skillSlot3 then doSkill(3) end
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
		if CONFIG.autoSwing then doSwing() end
		if CONFIG.autoSkills then
			if CONFIG.skillSlot1 then doSkill(1) end
			if CONFIG.skillSlot2 then doSkill(2) end
			if CONFIG.skillSlot3 then doSkill(3) end
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
trackDropSeqs()
hookReplication()
buildWorldRegions()
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
		PhaseLabel:Set("Phase: " .. STATE.phase)
		NoteLabel:Set("Note: " .. STATE.note)
		KillsLabel:Set("Kills: " .. STATE.kills)
		LootLabel:Set("Loot: " .. STATE.lootCollected)
		task.wait(0.5)
	end
end)

print("[Ivory] Loot Up loaded!")
