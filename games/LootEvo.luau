--// Ivory Hub | +1 Loot Evo
--// Place ID: 96033388567901

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local plr = Players.LocalPlayer

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
	isLobby = workspace:FindFirstChild("Lobby") ~= nil
		or workspace:FindFirstChild("lobby") ~= nil
		or plr.Character == nil
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
	pcall(function() trySetIcon(LocalPlayer.PlayerGui) end)
end)

--// ═══════════════════════════════════════════════════════════
--// GAME CONSTANTS
--// ═══════════════════════════════════════════════════════════

local FARM_MODES = { "smart ladder", "repeat cleared", "push next", "fixed stage" }
local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Godly" }

local CONFIG = {
	autoFarm = false,
	farmMode = 1,
	stage = 1,
	stageTimeout = 35,
	spawnTimeout = 5,
	fastSeconds = 5,
	farmRuns = 5,
	autoEggBest = true,
	petCopies = 3,
	autoAura = false,
	godMode = false,
	skipDash = true,
	chaseMobs = true,
	chaseRange = 9,
	autoSkill = false,
	castSkills = false,
	cleanPets = false,
	cleanBag = false,
	deleteRarity = 3,
	petKeep = 12,
	gearKeep = 12,
	gemKeep = 12,
	autoWeapon = false,
	autoEquip = false,
	autoPet = false,
	autoBuyEgg = false,
	egg = 1,
	autoClick = false,
	clickRate = 20,
	autoRebirth = false,
}

local STATE = {
	wins = 0, level = 0, rebirth = 0, damage = 0, cleared = 0, needLevel = 0,
	runs = 0, winsGained = 0, clicks = 0, rebirths = 0, weapon = "-", phase = "idle", note = "-",
	stageNow = "-", mobs = 0, tooHard = {}, unlocked = {}, noSpawn = {},
	deaths = 0, missedClaims = 0, resetToken = 0, primed = false,
	auras = 0, eggsBought = 0, peakDamage = 0, codesDone = false,
	deleted = 0, autoDeleteSet = -1, skillsBought = 0, petsCleanedAt = -1,
	casts = 0, chases = 0, healed = 0, uiOwner = "-",
	lastLevel = 0, ladder = 1, lastClear = 0, bankRuns = 0, blockedAt = 0,
}

_G.__LOOTEVO = (_G.__LOOTEVO or 0) + 1
local generation = _G.__LOOTEVO
if _G.__LOOTEVO_GUI then pcall(function() _G.__LOOTEVO_GUI:Destroy() end) end
if _G.__LOOTEVO_PAD then pcall(function() _G.__LOOTEVO_PAD:Destroy() end) end

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local snapshotRemote = Remotes:WaitForChild("GetPlayerDataSnapshot", 10)
local backpackRemote = Remotes:WaitForChild("BackPackActionEvent", 10)
local rebirthRemote = Remotes:WaitForChild("RebirthRequest", 10)
local buyEggRemote = Remotes:WaitForChild("BuyEggEvent", 10)
local clickRemote = Remotes:WaitForChild("ClickRequest", 10)

local weaponCfg = require(ReplicatedStorage.Config.WeaponConfig)
local eggHelper = require(ReplicatedStorage.Config.EggHelper)

local hall = workspace.Scene.Hall
local stageRoot = workspace.Scene.Stage
local weaponArea = hall:FindFirstChild("WeaponArea")

local HALL_POSITION = Vector3.new(319.105, 7.75, -81.22)
local MAX_STAGE = 36

--// ═══════════════════════════════════════════════════════════
--// CATALOGUES
--// ═══════════════════════════════════════════════════════════

local WEAPONS = {}
for _, entry in pairs(weaponCfg) do
	if type(entry) == "table" and type(entry.ID) == "string" then
		local index = entry.ID:match("^Weapon(%d+)$")
		if index then
			table.insert(WEAPONS, {
				id = entry.ID,
				index = tonumber(index),
				name = entry.Name or entry.ID,
				price = entry.VictoryPoint or 0,
				power = entry.EXP or 0,
			})
		end
	end
end
table.sort(WEAPONS, function(a, b) return a.power < b.power end)

local AURAS = {}
do
	local ok, auraCfg = pcall(require, ReplicatedStorage.Config.AuraConfig)
	if ok and type(auraCfg) == "table" then
		for key, entry in pairs(auraCfg) do
			if type(entry) == "table" and entry.ID then
				table.insert(AURAS, {
					id = entry.ID,
					index = tonumber(key) or tonumber(entry.ID:match("%d+")) or 1,
					name = entry.Name or entry.ID,
					price = entry.Wins or math.huge,
					bonus = entry.WinsBonus or 1,
				})
			end
		end
	end
	table.sort(AURAS, function(a, b) return a.price < b.price end)
end

local EGGS = {}
do
	local ok, all = pcall(eggHelper.GetAllEggs)
	if ok and type(all) == "table" then
		for _, entry in pairs(all) do
			if type(entry) == "table" and entry.ID then
				table.insert(EGGS, { id = entry.ID, name = entry.Name or entry.ID, price = entry.VictoryPoints or 0 })
			end
		end
	end
	table.sort(EGGS, function(a, b) return a.price < b.price end)
	if #EGGS == 0 then EGGS[1] = { id = "NoviceEgg", name = "Grass Egg", price = 400 } end
end

local EGG_BEST = {}
do
	local ok, helper = pcall(require, ReplicatedStorage.Config.EggHelper)
	if ok and helper.GetPoolData then
		for _, egg in ipairs(EGGS) do
			local gotPool, pool = pcall(helper.GetPoolData, egg.id)
			if gotPool and type(pool) == "table" then
				local best
				for _, pet in pairs(pool) do
					if type(pet) == "table" and pet.Name then
						if not best or (pet.Addition or 0) > (best.Addition or 0) then best = pet end
					end
				end
				if best then
					EGG_BEST[egg.id] = { name = best.Name, addition = best.Addition or 0 }
				end
			end
		end
	end
end

local WEAPON_BY_ID = {}
for _, weapon in ipairs(WEAPONS) do WEAPON_BY_ID[weapon.id] = weapon end

--// ═══════════════════════════════════════════════════════════
--// UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════

local function shortNumber(n)
	n = tonumber(n) or 0
	for _, u in ipairs({ { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" } }) do
		if n >= u[1] then return string.format("%.1f%s", n / u[1], u[2]) end
	end
	return tostring(math.floor(n))
end

local function rootPart()
	local char = plr.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function touch(part)
	local hrp = rootPart()
	if not hrp or not part or not firetouchinterest then return false end
	firetouchinterest(hrp, part, 0)
	task.wait(0.2)
	firetouchinterest(hrp, part, 1)
	return true
end

--// ═══════════════════════════════════════════════════════════
--// DEATH TRACKING
--// ═══════════════════════════════════════════════════════════

local diedFlag = false

local function watchCharacter(char)
	local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
	if not hum then return end
	hum.Died:Connect(function()
		if _G.__LOOTEVO == generation then diedFlag = true end
	end)
end

if plr.Character then watchCharacter(plr.Character) end
plr.CharacterAdded:Connect(function(char)
	if _G.__LOOTEVO ~= generation then return end
	diedFlag = true
	watchCharacter(char)
end)

--// ═══════════════════════════════════════════════════════════
--// CONTROLLER LOOKUP
--// ═══════════════════════════════════════════════════════════

_G.__LOOTEVO_CTRL = _G.__LOOTEVO_CTRL or { stage = nil, skill = nil, lastScan = 0, scanning = false }
local CTRL = _G.__LOOTEVO_CTRL

local function scanControllers()
	if CTRL.scanning or os.clock() - CTRL.lastScan < 20 then return end
	CTRL.scanning = true
	CTRL.lastScan = os.clock()
	task.spawn(function()
		local objects = getgc(true)
		local stageClass, skillClass
		local processed = 0
		for _, t in pairs(objects) do
			if type(t) == "table" and rawget(t, "new") ~= nil then
				if not stageClass and rawget(t, "DamageLocalMobsInRadius") ~= nil then stageClass = t end
				if not skillClass and rawget(t, "GetEquippedSkillIds") ~= nil then skillClass = t end
			end
			processed += 1
			if processed % 500 == 0 then task.wait() end
		end
		processed = 0
		for _, t in pairs(objects) do
			if type(t) == "table" then
				local meta = getmetatable(t)
				if stageClass and meta == stageClass and rawget(t, "attackHitDelays") ~= nil then CTRL.stage = t end
				if skillClass and meta == skillClass and rawget(t, "audio") ~= nil then CTRL.skill = t end
			end
			processed += 1
			if processed % 500 == 0 then task.wait() end
		end
		CTRL.scanning = false
		STATE.note = CTRL.stage and "controllers ready" or "controllers missing"
	end)
end

local function stageCtrl()
	local c = CTRL.stage
	if c and rawget(c, "attackHitDelays") ~= nil then return c end
	CTRL.stage = nil
	scanControllers()
	return nil
end

--// ═══════════════════════════════════════════════════════════
--// GOD MODE HOOK
--// ═══════════════════════════════════════════════════════════

if not _G.__LOOTEVO_HOOK then
	local original
	original = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if _G.__LOOTEVO_BLOCKHIT and getnamecallmethod() == "FireServer" then
			local ok, name = pcall(function() return self.Name end)
			if ok and name == "LocalMobHitPlayer" then return nil end
		end
		return original(self, ...)
	end))
	_G.__LOOTEVO_HOOK = true
end

local function applyGodMode(on)
	_G.__LOOTEVO_BLOCKHIT = on
	local ctrl = CTRL.stage
	if ctrl then
		if on then
			rawset(ctrl, "fireLocalMobHit", function() end)
		else
			rawset(ctrl, "fireLocalMobHit", nil)
		end
	end
end

task.spawn(function()
	while _G.__LOOTEVO == generation do
		if CONFIG.godMode then
			local char = plr.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health < hum.MaxHealth then
				hum.Health = hum.MaxHealth
				STATE.healed += 1
			end
		end
		task.wait(0.1)
	end
end)

--// ═══════════════════════════════════════════════════════════
--// RECOVERY
--// ═══════════════════════════════════════════════════════════

local function unstuck()
	local ctrl = stageCtrl()
	if ctrl then
		ctrl.stageSwingBusy = false
		ctrl.bufferedStageSwing = false
	end
	pcall(function() require(plr.PlayerScripts.PlayerModule):GetControls():Enable() end)
	local char = plr.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
		hum.AutoRotate = true
		if hum.WalkSpeed < 1 then hum.WalkSpeed = 20 end
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		local cam = workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = hum
		plr.CameraMinZoomDistance = 0.5
		plr.CameraMaxZoomDistance = 400
	end
	local hrp = rootPart()
	if hrp then hrp.Anchored = false end
	STATE.note = "unstuck"
end

--// ═══════════════════════════════════════════════════════════
--// DATA
--// ═══════════════════════════════════════════════════════════

local function resetProgression(reason)
	STATE.ladder = 1
	STATE.blockedAt = 0
	STATE.bankRuns = 0
	STATE.tooHard = {}
	STATE.noSpawn = {}
	STATE.peakDamage = STATE.damage
	STATE.resetToken += 1
	STATE.note = string.format("rebirth %d (%s) -> ladder reset to 1",
		STATE.rebirth, reason or "manual")
end

local function snapshot()
	local ok, data = pcall(function() return snapshotRemote:InvokeServer() end)
	if not ok or type(data) ~= "table" then return nil end
	local previousRebirth = STATE.rebirth
	local before = STATE.wins
	STATE.wins = data.VictoryPoints or 0
	STATE.level = data.Level or 0
	STATE.rebirth = data.Rebirth or 0
	STATE.damage = data.Damage or 0
	if STATE.peakDamage < STATE.damage then STATE.peakDamage = STATE.damage end
	STATE.cleared = data.HighestClearedStage or 0
	STATE.needLevel = data.NextRebirthNeedLevel or 0
	STATE.weapon = tostring(data.EquippedWeapon or "-")
	STATE.unlocked = type(data.UnlockedEquipment) == "table" and data.UnlockedEquipment or STATE.unlocked
	if type(data.OwnedAuras) == "table" then
		local owned = {}
		for key, value in pairs(data.OwnedAuras) do
			if type(value) == "string" then owned[value] = true
			elseif value == true then owned[tostring(key)] = true end
		end
		STATE.ownedAuras = owned
	end
	if STATE.primed and STATE.wins > before then STATE.winsGained += STATE.wins - before end
	local levelCollapsed = STATE.lastLevel > 3 and STATE.level < STATE.lastLevel
	STATE.lastLevel = STATE.level
	if not STATE.primed then
		STATE.primed = true
	elseif STATE.rebirth > previousRebirth or levelCollapsed then
		resetProgression(levelCollapsed and "level drop" or "counter")
	end
	return data
end

local function aliveMobs()
	local ctrl = stageCtrl()
	local stage = ctrl and ctrl.activeLocalStage
	if not stage or type(stage.Mobs) ~= "table" then return 0 end
	local n = 0
	for _, mob in pairs(stage.Mobs) do
		if type(mob) == "table" and not mob.Dead then n += 1 end
	end
	return n
end

local function activeStageNumber()
	local ctrl = stageCtrl()
	local id = ctrl and ctrl.activeLocalStage and ctrl.activeLocalStage.Id
	return type(id) == "string" and tonumber(id:match("Stage(%d+)")) or nil
end

--// ═══════════════════════════════════════════════════════════
--// ACTIONS
--// ═══════════════════════════════════════════════════════════

local function goHall()
	local hrp = rootPart()
	if hrp then hrp.CFrame = CFrame.new(HALL_POSITION) end
end

local function enterStage(number)
	local folder = stageRoot:FindFirstChild("Stage" .. number)
	local pad = folder and folder:FindFirstChild("StageStartPart", true)
	local hrp = rootPart()
	if not pad or not hrp then return false end
	hrp.CFrame = CFrame.new(pad.Position + Vector3.new(0, pad.Size.Y / 2 + 3, 0))
	task.wait(0.4)
	touch(pad)
	return true
end

local function claimWin(number)
	local folder = stageRoot:FindFirstChild("Stage" .. number)
	local model = folder and folder:FindFirstChild("WinBut")
	local part = model and model:FindFirstChild("TouchPart")
	if not part then return false end
	local before = STATE.wins
	for attempt = 1, 6 do
		touch(part)
		task.wait(0.7)
		snapshot()
		if STATE.wins > before then
			if attempt > 1 then
				STATE.note = string.format("claimed stage %d on try %d", number, attempt)
			end
			return true
		end
	end
	STATE.note = "claim failed on stage " .. number
	STATE.missedClaims += 1
	return false
end

local clickBudget = 0
local function autoClickTick(delta)
	clickBudget += delta * CONFIG.clickRate
	local sendable = math.floor(clickBudget)
	if sendable < 1 then return end
	clickBudget -= sendable
	for _ = 1, math.min(sendable, 6) do
		pcall(function() clickRemote:FireServer() end)
		STATE.clicks += 1
	end
end

--// ═══════════════════════════════════════════════════════════
--// WEAPONS
--// ═══════════════════════════════════════════════════════════

local padCache = nil

local function weaponPads()
	if padCache then return padCache end
	padCache = {}
	if not weaponArea then return padCache end
	for _, pad in ipairs(weaponArea:GetChildren()) do
		local touchPart = pad:FindFirstChild("TouchPart", true)
		if touchPart then
			for _, child in ipairs(pad:GetChildren()) do
				if WEAPON_BY_ID[child.Name] then
					padCache[child.Name] = { pad = pad, touch = touchPart }
					break
				end
			end
		end
	end
	return padCache
end

local function bestWeapon(wins)
	local pads = weaponPads()
	local best
	for _, weapon in ipairs(WEAPONS) do
		if pads[weapon.id] and weapon.price <= wins then
			if not best or weapon.power > best.power then best = weapon end
		end
	end
	return best
end

local function currentPower()
	local equipped = WEAPON_BY_ID[STATE.weapon]
	return equipped and equipped.power or 0
end

local function weaponReserve()
	local equipped = WEAPON_BY_ID[STATE.weapon]
	return equipped and equipped.price or 0
end

local function spendableWins()
	return STATE.wins - weaponReserve()
end

local function canSpend(cost)
	local reserve = weaponReserve()
	if reserve > 0 and STATE.wins < reserve * 2 then return false end
	return cost <= spendableWins()
end

local function upgradeWeapon()
	if not weaponArea then return end
	snapshot()
	local best = bestWeapon(STATE.wins)
	if not best or best.id == STATE.weapon then return end
	if best.power <= currentPower() then return end
	if best.price > STATE.wins then
		STATE.note = string.format("need %s wins for %s", shortNumber(best.price), best.name)
		return
	end
	local entry = weaponPads()[best.id]
	if not entry then
		STATE.note = "no pad for " .. best.name
		return
	end
	local before = STATE.weapon
	touch(entry.touch)
	task.wait(1.2)
	snapshot()
	if STATE.weapon == best.id then
		STATE.note = "weapon -> " .. best.name
	else
		STATE.note = string.format("weapon %s (wanted %s)", STATE.weapon, best.name)
		if STATE.weapon ~= before then padCache = nil end
	end
end

local function weaponUpgradePending()
	local best = bestWeapon(STATE.wins)
	if not best then return false end
	return best.power > currentPower() and best.price <= STATE.wins
end

local function ensureBestEquipped()
	local best = bestWeapon(STATE.wins)
	if not best or best.id == STATE.weapon then return end
	if best.power <= currentPower() then return end
	local entry = weaponPads()[best.id]
	if not entry then return end
	touch(entry.touch)
	task.wait(1)
	snapshot()
	if STATE.weapon == best.id then
		STATE.note = "re-equipped " .. best.name
	end
end

--// ═══════════════════════════════════════════════════════════
--// EQUIP / EGG / PET
--// ═══════════════════════════════════════════════════════════

local function equipBest()
	pcall(function() backpackRemote:FireServer("EquipBest", { Kind = "Equip" }) end)
	pcall(function() backpackRemote:FireServer("EquipBest", { Kind = "Gem" }) end)
end

local function equipBestPet()
	local main = plr.PlayerGui:FindFirstChild("Main")
	local pet = main and main:FindFirstChild("Pet")
	local button = pet and pet:FindFirstChild("EquipBest")
	if not button or not getconnections then return end
	for _, conn in pairs(getconnections(button.Activated)) do
		pcall(function() conn:Fire() end)
	end
end

local function buyEgg(eggId, count)
	pcall(function() buyEggRemote:FireServer(eggId, count or 1) end)
	STATE.eggsBought += 1
	STATE.note = "opened " .. eggId
end

local function ownedPetCount(petName)
	local main = plr.PlayerGui:FindFirstChild("Main")
	local pet = main and main:FindFirstChild("Pet")
	local list = pet and pet:FindFirstChild("ScrollingFrameB")
	if not list or not petName then return 0 end
	local count = 0
	for _, row in ipairs(list:GetChildren()) do
		if row:IsA("GuiButton") then
			local label = row:FindFirstChild("Name", true)
			if label and label.Text == petName then count += 1 end
		end
	end
	return count
end

local function bestOwnedAddition()
	local main = plr.PlayerGui:FindFirstChild("Main")
	local pet = main and main:FindFirstChild("Pet")
	local list = pet and pet:FindFirstChild("ScrollingFrameB")
	if not list then return 0 end
	local ok, helper = pcall(require, ReplicatedStorage.Config.EggHelper)
	if not ok then return 0 end
	local best = 0
	for _, row in ipairs(list:GetChildren()) do
		if row:IsA("GuiButton") then
			local label = row:FindFirstChild("Name", true)
			if label then
				local gotIt, info = pcall(helper.GetPetInfo, label.Text)
				if gotIt and type(info) == "table" and (info.Addition or 0) > best then
					best = info.Addition
				end
			end
		end
	end
	return best
end

local function eggIsFinished(eggId)
	local best = EGG_BEST[eggId]
	if not best then return false end
	if ownedPetCount(best.name) >= CONFIG.petCopies then return true end
	return best.addition <= bestOwnedAddition()
end

--// ═══════════════════════════════════════════════════════════
--// UI LOCK HELPER
--// ═══════════════════════════════════════════════════════════

local uiBusy = false

local function withUI(name, fn)
	local waited = 0
	while uiBusy do
		task.wait(0.25)
		waited += 0.25
		if waited > 30 then return false end
	end
	uiBusy = true
	STATE.uiOwner = name
	local ok, err = pcall(fn)
	uiBusy = false
	STATE.uiOwner = "-"
	if not ok then STATE.note = name .. " failed: " .. tostring(err):sub(1, 40) end
	return ok
end

local function fireGui(button)
	if not button or not getconnections then return 0 end
	local count = 0
	for _, conn in pairs(getconnections(button.Activated)) do
		pcall(function() conn:Fire() end)
		count += 1
	end
	return count
end

local function fireButton(button)
	if not button or not getconnections then return false end
	local fired = false
	for _, conn in pairs(getconnections(button.Activated)) do
		pcall(function() conn:Fire() end)
		fired = true
	end
	return fired
end

--// ═══════════════════════════════════════════════════════════
--// INVENTORY CLEANUP
--// ═══════════════════════════════════════════════════════════

local function isEquippedRow(row)
	local marker = row:FindFirstChild("Equipped", true)
	return marker ~= nil and marker.Visible
end

local function cleanFrame(frame, listFrame, keep, scoreOf, label)
	if not frame or not listFrame then return end
	local rows = {}
	for _, row in ipairs(listFrame:GetChildren()) do
		if row:IsA("GuiButton") then
			table.insert(rows, { row = row, score = scoreOf(row) or 0, equipped = isEquippedRow(row) })
		end
	end
	if #rows <= keep then return end
	table.sort(rows, function(a, b) return a.score > b.score end)
	local deleteButton = frame:FindFirstChild("Delete")
	local confirmButton = frame:FindFirstChild("ConfirmDelete")
	if not deleteButton or not confirmButton then return end
	fireGui(deleteButton)
	task.wait(0.6)
	local marked = 0
	for index, entry in ipairs(rows) do
		if index > keep and not entry.equipped and marked < 8 then
			if entry.row.Parent then
				fireGui(entry.row)
				marked += 1
				task.wait(0.12)
			end
		end
	end
	if marked == 0 then
		fireGui(frame:FindFirstChild("CancelDelete"))
		return
	end
	task.wait(0.8)
	if confirmButton.Visible then fireGui(confirmButton) end
	STATE.deleted += marked
	STATE.note = string.format("deleted %d %s", marked, label)
	task.wait(0.6)
	local cancel = frame:FindFirstChild("CancelDelete")
	if cancel and cancel.Visible then
		fireGui(cancel)
		task.wait(0.4)
	end
end

local function cleanPets()
	local main = plr.PlayerGui:FindFirstChild("Main")
	local pet = main and main:FindFirstChild("Pet")
	local list = pet and pet:FindFirstChild("ScrollingFrameB")
	if not list then return end
	local rowCount = 0
	for _, row in ipairs(list:GetChildren()) do
		if row:IsA("GuiButton") then rowCount += 1 end
	end
	if rowCount <= CONFIG.petKeep then
		STATE.petsCleanedAt = STATE.eggsBought
		return
	end
	if STATE.petsCleanedAt == STATE.eggsBought then return end
	local wasVisible = pet.Visible
	local function openPet()
		if pet and pet.Visible then return true end
		local hud = plr.PlayerGui:FindFirstChild("HUD")
		local left = hud and hud:FindFirstChild("Left")
		local entry = left and left:FindFirstChild("Pet")
		local button = entry and entry:FindFirstChild("Button")
		if not button then return false end
		fireGui(button)
		task.wait(0.8)
		if pet and not pet.Visible then
			fireGui(button)
			task.wait(0.8)
		end
		return not pet or pet.Visible
	end
	if not openPet() then return end
	local eggHelperOk, helper = pcall(require, ReplicatedStorage.Config.EggHelper)
	local function scoreOf(row)
		local label = row:FindFirstChild("Name", true)
		local name = label and label.Text
		if not eggHelperOk or not name then return 0 end
		local ok, info = pcall(helper.GetPetInfo, name)
		return ok and type(info) == "table" and info.Addition or 0
	end
	for _ = 1, 5 do
		local remaining = 0
		for _, row in ipairs(list:GetChildren()) do
			if row:IsA("GuiButton") then remaining += 1 end
		end
		if remaining <= CONFIG.petKeep then break end
		cleanFrame(pet, list, CONFIG.petKeep, scoreOf, "pets")
		task.wait(1.2)
	end
	STATE.petsCleanedAt = STATE.eggsBought
	if not wasVisible then
		local close = pet:FindFirstChild("CloseBtn")
		if close then fireGui(close) end
		task.wait(0.3)
		pet.Visible = false
	end
end

local function setAutoDelete(frame, threshold)
	if not frame then return 0 end
	local autoFrame = frame:FindFirstChild("AutoFrame")
	local autoButton = frame:FindFirstChild("Auto")
	if not autoFrame or not autoButton then return 0 end
	if not autoFrame.Visible then
		fireGui(autoButton)
		task.wait(0.5)
	end
	local changed = 0
	for index, rarity in ipairs(RARITIES) do
		local toggle = autoFrame:FindFirstChild(rarity)
		local onMarker = toggle and toggle:FindFirstChild("b")
		if toggle and onMarker then
			local isOn = onMarker.Visible
			local wantOn = index <= threshold
			if isOn ~= wantOn then
				fireGui(toggle)
				changed += 1
				task.wait(0.2)
			end
		end
	end
	fireGui(frame:FindFirstChild("AutoBack"))
	task.wait(0.3)
	return changed
end

local function applyAutoDelete()
	local main = plr.PlayerGui:FindFirstChild("Main")
	local bag = main and main:FindFirstChild("BackPack")
	if not bag then return end
	local wasVisible = bag.Visible
	local function openBag()
		if bag and bag.Visible then return true end
		local hud = plr.PlayerGui:FindFirstChild("HUD")
		local left = hud and hud:FindFirstChild("Left")
		local entry = left and left:FindFirstChild("BackPack")
		local button = entry and entry:FindFirstChild("Button")
		if not button then return false end
		fireGui(button)
		task.wait(0.8)
		if bag and not bag.Visible then
			fireGui(button)
			task.wait(0.8)
		end
		return not bag or bag.Visible
	end
	if not openBag() then return end
	local changed = 0
	fireGui(bag:FindFirstChild("EquipBut"))
	task.wait(0.6)
	local gear = bag:FindFirstChild("Equip")
	changed += setAutoDelete(gear and gear:FindFirstChild("EquipFrame"), CONFIG.deleteRarity)
	fireGui(bag:FindFirstChild("GemBut"))
	task.wait(0.6)
	local gems = bag:FindFirstChild("Gem")
	changed += setAutoDelete(gems and gems:FindFirstChild("GemFrame"), CONFIG.deleteRarity)
	STATE.autoDeleteSet = CONFIG.deleteRarity
	STATE.note = string.format("auto-delete <= %s (%d toggles)", RARITIES[CONFIG.deleteRarity] or "off", changed)
	if not wasVisible then
		local close = bag:FindFirstChild("CloseBtn") or bag:FindFirstChild("Exit")
		if close then fireGui(close) end
		task.wait(0.3)
		bag.Visible = false
	end
end

--// ═══════════════════════════════════════════════════════════
--// AURAS
--// ═══════════════════════════════════════════════════════════

local function buyBestAura()
	local rows = plr.PlayerGui:FindFirstChild("Main")
	rows = rows and rows:FindFirstChild("Aura")
	rows = rows and rows:FindFirstChild("ScrollingFrame")
	if not rows then return end
	local owned = STATE.ownedAuras or {}
	local pick
	for _, aura in ipairs(AURAS) do
		if not owned[aura.id] and canSpend(aura.price) then
			if not pick or aura.price > pick.price then pick = aura end
		end
	end
	if not pick then return end
	local row = rows:FindFirstChild("Stage" .. pick.index)
	if not row then return end
	if fireButton(row:FindFirstChild("Buy")) then
		task.wait(1)
		snapshot()
		if (STATE.ownedAuras or {})[pick.id] then
			STATE.auras += 1
			STATE.note = "aura " .. pick.name .. " (+" .. math.floor((pick.bonus - 1) * 100) .. "% wins)"
			task.wait(0.4)
			fireButton(row:FindFirstChild("Equip"))
		else
			STATE.note = "aura " .. pick.name .. " refused"
		end
	end
end

--// ═══════════════════════════════════════════════════════════
--// SKILLS
--// ═══════════════════════════════════════════════════════════

local function skillState()
	local remote = Remotes:FindFirstChild("GetSkillState")
	if not remote then return nil end
	local ok, state = pcall(function() return remote:InvokeServer() end)
	return ok and type(state) == "table" and state or nil
end

local function skillShoppingList()
	local state = skillState()
	local helperOk, helper = pcall(require, ReplicatedStorage.Config.SkillHelper)
	if not state or not helperOk then return {} end
	local list = {}
	for _, entry in pairs(state) do
		if type(entry) == "table" and entry.ID and not entry.Unlocked then
			local priceOk, price = pcall(helper.GetWins, entry.ID)
			price = priceOk and tonumber(price) or nil
			if price and price > 0 then
				table.insert(list, {
					id = entry.ID,
					name = entry.Name or entry.ID,
					price = price,
					slot = entry.Slot,
				})
			end
		end
	end
	table.sort(list, function(a, b) return a.price < b.price end)
	return list
end

local function skillUpgradePending()
	for _, skill in ipairs(skillShoppingList()) do
		if canSpend(skill.price) then return true, skill end
	end
	return false
end

local function buySkills()
	local main = plr.PlayerGui:FindFirstChild("Main")
	local panel = main and main:FindFirstChild("Skill")
	if not panel then return end
	local state = skillState()
	if not state then return end
	local helperOk, helper = pcall(require, ReplicatedStorage.Config.SkillHelper)
	if not helperOk then return end
	local wanted = {}
	for _, entry in pairs(state) do
		if type(entry) == "table" and entry.ID and not entry.Unlocked then
			local priceOk, price = pcall(helper.GetWins, entry.ID)
			price = priceOk and tonumber(price) or nil
			if price and price > 0 and canSpend(price) then
				table.insert(wanted, { id = entry.ID, name = entry.Name or entry.ID, price = price })
			end
		end
	end
	if #wanted == 0 then return end
	table.sort(wanted, function(a, b) return a.price < b.price end)
	local wasVisible = panel.Visible
	panel.Visible = true
	task.wait(0.6)
	local list = panel:FindFirstChild("LeftFrame")
	list = list and list:FindFirstChild("Trails")
	list = list and list:FindFirstChild("LeftScro")
	local right = panel:FindFirstChild("RightFrame")
	if not list or not right then
		panel.Visible = wasVisible
		return
	end
	for _, skill in ipairs(wanted) do
		local row = list:FindFirstChild("Skill_" .. skill.id)
		if row then
			fireGui(row)
			task.wait(0.8)
			fireGui(right:FindFirstChild("Rebirth"))
			task.wait(1.5)
			local equip = right:FindFirstChild("Equip")
			if equip and equip.Visible then
				fireGui(equip)
				task.wait(0.8)
			end
			snapshot()
			STATE.skillsBought += 1
			STATE.note = "skill " .. skill.name .. " (" .. shortNumber(skill.price) .. ")"
		end
	end
	panel.Visible = wasVisible
end

local function castSkills()
	if aliveMobs() < 1 then return end
	local hud = plr.PlayerGui:FindFirstChild("HUD")
	local down = hud and hud:FindFirstChild("Down")
	local fired = 0
	if down then
		local firstSlot = CONFIG.skipDash and 2 or 1
		for slot = firstSlot, 3 do
			local holder = down:FindFirstChild("Skill" .. slot)
			local button = holder and holder:FindFirstChild("Button")
			if button and button.Visible then
				if fireGui(button) > 0 then
					fired += 1
					STATE.casts += 1
				end
			end
		end
	end
	if fired > 0 then return end
	local ctrl = CTRL.skill
	if not ctrl then return end
	local ok, ids = pcall(ctrl.GetEquippedSkillIds, ctrl)
	if not ok or type(ids) ~= "table" then return end
	for _, id in pairs(ids) do
		if id then
			local gotIt, remaining = pcall(ctrl.GetCooldownRemaining, ctrl, id)
			if not gotIt or (tonumber(remaining) or 0) <= 0 then
				pcall(ctrl.UseSkill, ctrl, id)
				STATE.casts += 1
			end
		end
	end
end

--// ═══════════════════════════════════════════════════════════
--// CHASE MOBS
--// ═══════════════════════════════════════════════════════════

local function chaseNearestMob()
	local ctrl = stageCtrl()
	local stage = ctrl and ctrl.activeLocalStage
	local hrp = rootPart()
	if not stage or type(stage.Mobs) ~= "table" or not hrp then return end
	local bestPos, bestDist
	for _, mob in pairs(stage.Mobs) do
		if type(mob) == "table" and not mob.Dead and typeof(mob.Model) == "Instance" then
			local ok, pivot = pcall(function() return mob.Model:GetPivot().Position end)
			if ok then
				local distance = (pivot - hrp.Position).Magnitude
				if not bestDist or distance < bestDist then
					bestPos, bestDist = pivot, distance
				end
			end
		end
	end
	if not bestPos or bestDist <= CONFIG.chaseRange or bestDist > 250 then return end
	local offset = (hrp.Position - bestPos)
	offset = offset.Magnitude > 0.1 and offset.Unit or Vector3.new(0, 0, 1)
	hrp.CFrame = CFrame.new(bestPos + offset * 4 + Vector3.new(0, 2, 0), bestPos)
	STATE.chases += 1
end

--// ═══════════════════════════════════════════════════════════
--// EGGS
--// ═══════════════════════════════════════════════════════════

local function buyBestEgg()
	if CONFIG.autoWeapon and weaponUpgradePending() then
		local best = bestWeapon(STATE.wins)
		STATE.note = "weapon first: " .. (best and best.name or "?")
		upgradeWeapon()
		return
	end
	if CONFIG.autoSkill then
		local pending, skill = skillUpgradePending()
		if pending then
			STATE.note = "skill " .. skill.name .. " first, egg on hold"
			return
		end
	end
	local pick
	if CONFIG.autoEggBest then
		for _, egg in ipairs(EGGS) do
			if canSpend(egg.price) and not eggIsFinished(egg.id) then
				if not pick or egg.price > pick.price then pick = egg end
			end
		end
		if not pick then
			local nextTier
			for _, egg in ipairs(EGGS) do
				if not canSpend(egg.price) and not eggIsFinished(egg.id) then
					if not nextTier or egg.price < nextTier.price then nextTier = egg end
				end
			end
			if nextTier then
				STATE.note = string.format("eggs done, saving %s for %s",
					shortNumber(nextTier.price), nextTier.name)
			end
			return
		end
	else
		local chosen = EGGS[CONFIG.egg]
		if chosen and canSpend(chosen.price) then
			if eggIsFinished(chosen.id) then
				local best = EGG_BEST[chosen.id]
				STATE.note = string.format("%s done (%dx %s)", chosen.name,
					CONFIG.petCopies, best and best.name or "best pet")
				return
			end
			pick = chosen
		end
	end
	if not pick then return end
	_G.__LOOTEVO_PEAKEGG = _G.__LOOTEVO_PEAKEGG or 0
	local peak = _G.__LOOTEVO_PEAKEGG
	if peak > 0 and pick.price < peak / 10 then
		STATE.note = "saving wins for " .. shortNumber(peak) .. " egg tier"
		return
	end
	_G.__LOOTEVO_PEAKEGG = math.max(peak, pick.price)
	local best = EGG_BEST[pick.id]
	for _ = 1, 5 do
		if not canSpend(pick.price) then break end
		if eggIsFinished(pick.id) then
			STATE.note = string.format("%s done (%dx %s)", pick.name,
				CONFIG.petCopies, best and best.name or "best pet")
			break
		end
		buyEgg(pick.id, 1)
		task.wait(0.6)
		snapshot()
	end
	equipBestPet()
end

--// ═══════════════════════════════════════════════════════════
--// REBIRTH
--// ═══════════════════════════════════════════════════════════

local lastRebirth = 0
local function tryRebirth()
	if STATE.needLevel <= 0 or STATE.level < STATE.needLevel then return end
	if os.clock() - lastRebirth < 15 then return end
	lastRebirth = os.clock()
	local before = STATE.rebirth
	STATE.phase = "rebirth: to hall"
	goHall()
	task.wait(2)
	pcall(function() rebirthRemote:FireServer() end)
	task.wait(2.5)
	snapshot()
	if STATE.rebirth > before then
		STATE.rebirths += 1
		STATE.note = string.format("rebirth %d -> %d", before, STATE.rebirth)
	else
		STATE.note = "rebirth refused at lvl " .. STATE.level
	end
end

--// ═══════════════════════════════════════════════════════════
--// CODES
--// ═══════════════════════════════════════════════════════════

local function redeemCodes()
	local ok, helper = pcall(require, ReplicatedStorage.Config.CodeHelper)
	if not ok or type(helper) ~= "table" or not helper.GetAll then return end
	local list = select(2, pcall(helper.GetAll))
	if type(list) ~= "table" then return end
	local remote = Remotes:FindFirstChild("RedeemCodeFunction")
	if not remote then return end
	local tried = 0
	for _, entry in pairs(list) do
		if type(entry) == "table" and entry.Enabled and entry.Code then
			pcall(function() remote:InvokeServer(entry.Code) end)
			tried += 1
			task.wait(1)
		end
	end
	STATE.codesDone = true
	STATE.note = "redeemed " .. tried .. " codes"
end

--// ═══════════════════════════════════════════════════════════
--// FARM LOGIC
--// ═══════════════════════════════════════════════════════════

local function pickStage()
	local mode = FARM_MODES[CONFIG.farmMode]
	if mode == "fixed stage" then return math.clamp(CONFIG.stage, 1, MAX_STAGE) end
	if mode == "repeat cleared" then return math.max(1, STATE.cleared) end
	if mode == "push next" then
		local nextStage = math.clamp(STATE.cleared + 1, 1, MAX_STAGE)
		if STATE.tooHard[nextStage] and STATE.wins < STATE.tooHard[nextStage] then
			return math.max(1, STATE.cleared)
		end
		return nextStage
	end
	return math.clamp(STATE.ladder, 1, MAX_STAGE)
end

local function updateLadder(stage, seconds)
	if FARM_MODES[CONFIG.farmMode] ~= "smart ladder" then return end
	if not seconds then
		STATE.blockedAt = stage
		STATE.bankRuns = 0
		STATE.ladder = math.max(1, stage - 1)
		STATE.note = string.format("stage %d too strong -> banking on %d", stage, STATE.ladder)
		return
	end
	STATE.lastClear = seconds
	if STATE.blockedAt > 0 and stage < STATE.blockedAt then
		STATE.bankRuns += 1
		if seconds <= CONFIG.fastSeconds or STATE.bankRuns >= CONFIG.farmRuns then
			STATE.bankRuns = 0
			STATE.ladder = STATE.blockedAt
			STATE.note = string.format("retrying stage %d (dmg %s)", STATE.blockedAt, shortNumber(STATE.damage))
		end
		return
	end
	STATE.blockedAt = 0
	local step = 1
	if stage < STATE.cleared and seconds <= CONFIG.fastSeconds / 2 then
		step = math.max(1, math.floor((STATE.cleared - stage) / 2))
	end
	STATE.ladder = math.min(stage + step, MAX_STAGE)
	STATE.note = string.format("stage %d in %.1fs -> %s %d",
		stage, seconds, step > 1 and "jumping to" or "climbing to", STATE.ladder)
end

local function farmCycle()
	local want = pickStage()
	local rebirthAtStart = STATE.rebirth
	STATE.phase = "hall"
	goHall()
	task.wait(1)
	STATE.phase = "enter " .. want
	if not enterStage(want) then
		STATE.note = "stage " .. want .. " has no pad"
		task.wait(1)
		return
	end
	local started = os.clock()
	local deadline = started + CONFIG.stageTimeout
	local spawnDeadline = started + CONFIG.spawnTimeout
	local sawMobs = false
	diedFlag = false
	while os.clock() < deadline and CONFIG.autoFarm do
		if diedFlag then break end
		local alive = aliveMobs()
		STATE.mobs = alive
		if alive > 0 then
			sawMobs = true
			STATE.phase = string.format("fighting %d (%.1fs)", alive, os.clock() - started)
			if CONFIG.castSkills then castSkills() end
			if CONFIG.chaseMobs then pcall(chaseNearestMob) end
		elseif sawMobs then
			break
		else
			STATE.phase = "waiting for spawn"
			if os.clock() > spawnDeadline then break end
		end
		task.wait(0.3)
	end
	local elapsed = os.clock() - started
	if diedFlag then
		diedFlag = false
		STATE.deaths += 1
		if STATE.rebirth ~= rebirthAtStart then goHall() return end
		STATE.tooHard[want] = STATE.wins * 2 + 50
		STATE.note = string.format("died on stage %d after %.1fs", want, elapsed)
		updateLadder(want, nil)
		task.wait(2)
		goHall()
		return
	end
	if not sawMobs then
		STATE.noSpawn[want] = (STATE.noSpawn[want] or 0) + 1
		if want <= STATE.cleared and STATE.noSpawn[want] < 2 then
			STATE.note = "no spawn on stage " .. want .. " -> retrying"
			goHall()
			return
		end
		STATE.noSpawn[want] = 0
		STATE.note = "no spawn on stage " .. want .. " -> not unlocked"
		updateLadder(want, nil)
		goHall()
		return
	elseif aliveMobs() > 0 then
		STATE.tooHard[want] = STATE.wins * 2 + 50
		updateLadder(want, nil)
		goHall()
		return
	end
	STATE.phase = "claiming"
	task.wait(0.6)
	claimWin(want)
	task.wait(0.8)
	snapshot()
	STATE.runs += 1
	STATE.noSpawn[want] = 0
	if STATE.rebirth ~= rebirthAtStart then
		STATE.note = "rebirth mid-run, result discarded"
		return
	end
	if sawMobs then updateLadder(want, elapsed) end
	if CONFIG.autoWeapon then withUI("weapon", upgradeWeapon) end
	if CONFIG.autoSkill then withUI("skills", buySkills) end
	if CONFIG.autoEquip then equipBest() end
	if CONFIG.autoBuyEgg then buyBestEgg() end
	if CONFIG.autoPet then withUI("pet equip", equipBestPet) end
end

--// ═══════════════════════════════════════════════════════════
--// UI TABS
--// ═══════════════════════════════════════════════════════════

local MainTab = Window:AddTab({ Name = "Main", Icon = "swords" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "swords" })
local PetTab = Window:AddTab({ Name = "Eggs & Pets", Icon = "swords" })
local StatusTab = Window:AddTab({ Name = "Status", Icon = "swords" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "swords" })

--// ═══════════════════════════════════════════════════════════
--// MAIN TAB
--// ═══════════════════════════════════════════════════════════

local FarmingSub = MainTab:AddSubTab("Farming", "rbxassetid://113133903091338")
local LadderSub = MainTab:AddSubTab("Ladder", "rbxassetid://113133903091338")

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
FarmGroup:AddDropdown("FarmMode", {
	Values = FARM_MODES,
	Default = 1,
	Text = "Farm Mode",
	Callback = function(v)
		for i, mode in ipairs(FARM_MODES) do
			if mode == v then CONFIG.farmMode = i break end
		end
	end,
})
FarmGroup:AddSlider("FarmStage", {
	Text = "Fixed Stage",
	Default = 1,
	Min = 1,
	Max = 36,
	Rounding = 0,
	Callback = function(v) CONFIG.stage = v end,
})

local TimingGroup = FarmingSub:AddLeftGroupbox("Timing", "clock")
TimingGroup:AddSlider("FastSeconds", {
	Text = "Jump Under (s)",
	Default = 5,
	Min = 2,
	Max = 30,
	Rounding = 0,
	Callback = function(v) CONFIG.fastSeconds = v end,
})
TimingGroup:AddSlider("StageTimeout", {
	Text = "Give Up After (s)",
	Default = 35,
	Min = 10,
	Max = 120,
	Rounding = 0,
	Callback = function(v) CONFIG.stageTimeout = v end,
})
TimingGroup:AddSlider("FarmRuns", {
	Text = "Bank Runs",
	Default = 5,
	Min = 1,
	Max = 20,
	Rounding = 0,
	Callback = function(v) CONFIG.farmRuns = v end,
})

local LadderGroup = LadderSub:AddLeftGroupbox("Ladder Status", "trending-up")
local LadderLabel = LadderGroup:AddLabel("Cursor: 1 | Cleared: 0 | Blocked: -")
local LadderNote = LadderGroup:AddLabel("Note: -")

local SessionGroup = LadderSub:AddRightGroupbox("Session", "activity")
local SessionLabel = SessionGroup:AddLabel("Runs: 0 | Deaths: 0 | Missed: 0")
local SessionWins = SessionGroup:AddLabel("Wins Gained: 0")

--// ═══════════════════════════════════════════════════════════
--// COMBAT TAB
--// ═══════════════════════════════════════════════════════════

local ClickSub = CombatTab:AddSubTab("Clicking", "rbxassetid://113133903091338")
local SkillSub = CombatTab:AddSubTab("Skills", "rbxassetid://113133903091338")
local SurvivalSub = CombatTab:AddSubTab("Survival", "rbxassetid://113133903091338")

local ClickGroup = ClickSub:AddLeftGroupbox("Clicking", "mouse-pointer")
ClickGroup:AddToggle("AutoClick", {
	Text = "Auto Click",
	Default = false,
	Callback = function(v) CONFIG.autoClick = v end,
})
ClickGroup:AddSlider("ClickRate", {
	Text = "Clicks/sec",
	Default = 20,
	Min = 2,
	Max = 40,
	Rounding = 0,
	Callback = function(v) CONFIG.clickRate = v end,
})

local SkillGroup = SkillSub:AddLeftGroupbox("Skills", "zap")
SkillGroup:AddToggle("CastSkills", {
	Text = "Cast Skills (Q/E/R)",
	Default = false,
	Callback = function(v) CONFIG.castSkills = v end,
})
SkillGroup:AddToggle("SkipDash", {
	Text = "Skip Dash Skill",
	Default = true,
	Callback = function(v) CONFIG.skipDash = v end,
})

local SurvivalGroup = SurvivalSub:AddLeftGroupbox("Survival", "shield")
SurvivalGroup:AddToggle("GodMode", {
	Text = "God Mode",
	Default = false,
	Callback = function(v)
		CONFIG.godMode = v
		applyGodMode(v)
	end,
})
SurvivalGroup:AddToggle("ChaseMobs", {
	Text = "Chase Runaway Mobs",
	Default = true,
	Callback = function(v) CONFIG.chaseMobs = v end,
})
SurvivalGroup:AddSlider("ChaseRange", {
	Text = "Chase Range",
	Default = 9,
	Min = 3,
	Max = 40,
	Rounding = 0,
	Callback = function(v) CONFIG.chaseRange = v end,
})

--// ═══════════════════════════════════════════════════════════
--// SHOP TAB
--// ═══════════════════════════════════════════════════════════

local WeaponSub = ShopTab:AddSubTab("Weapons", "rbxassetid://113133903091338")
local SkillShopSub = ShopTab:AddSubTab("Skills", "rbxassetid://113133903091338")
local AuraSub = ShopTab:AddSubTab("Auras", "rbxassetid://113133903091338")
local RebirthSub = ShopTab:AddSubTab("Rebirth", "rbxassetid://113133903091338")

local WeaponGroup = WeaponSub:AddLeftGroupbox("Weapons", "swords")
WeaponGroup:AddToggle("AutoWeapon", {
	Text = "Buy Weapons",
	Default = false,
	Callback = function(v) CONFIG.autoWeapon = v end,
})
local WeaponLabel = WeaponGroup:AddLabel("Weapon: -")
WeaponGroup:AddButton("Buy Best Weapon Now", function()
	withUI("weapon", upgradeWeapon)
end)

local SkillShopGroup = SkillShopSub:AddLeftGroupbox("Skills", "zap")
SkillShopGroup:AddToggle("AutoSkill", {
	Text = "Buy Skills",
	Default = false,
	Callback = function(v) CONFIG.autoSkill = v end,
})

local AuraGroup = AuraSub:AddLeftGroupbox("Auras", "sparkles")
AuraGroup:AddToggle("AutoAura", {
	Text = "Buy Auras",
	Default = false,
	Callback = function(v) CONFIG.autoAura = v end,
})

local RebirthGroup = RebirthSub:AddLeftGroupbox("Rebirth", "refresh-cw")
RebirthGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = false,
	Callback = function(v) CONFIG.autoRebirth = v end,
})
RebirthGroup:AddButton("Rebirth Now", function()
	if STATE.needLevel > 0 and STATE.level < STATE.needLevel then
		STATE.note = string.format("need level %d to rebirth (at %d)", STATE.needLevel, STATE.level)
		return
	end
	lastRebirth = 0
	tryRebirth()
end)
RebirthGroup:AddButton("Reset Ladder", function()
	resetProgression("manual")
end)

--// ═══════════════════════════════════════════════════════════
--// EGGS & PETS TAB
--// ═══════════════════════════════════════════════════════════

local EggSub = PetTab:AddSubTab("Eggs", "rbxassetid://113133903091338")
local PetSub = PetTab:AddSubTab("Pets", "rbxassetid://113133903091338")

local EggGroup = EggSub:AddLeftGroupbox("Eggs", "egg")
EggGroup:AddToggle("AutoBuyEgg", {
	Text = "Buy Eggs",
	Default = false,
	Callback = function(v) CONFIG.autoBuyEgg = v end,
})
EggGroup:AddToggle("AutoEggBest", {
	Text = "Pick Best Egg",
	Default = true,
	Callback = function(v) CONFIG.autoEggBest = v end,
})
EggGroup:AddDropdown("EggSelect", {
	Values = (function()
		local names = {}
		for _, egg in ipairs(EGGS) do
			table.insert(names, egg.name .. " (" .. shortNumber(egg.price) .. ")")
		end
		return names
	end)(),
	Default = 1,
	Text = "Select Egg",
	Callback = function(v)
		for i, egg in ipairs(EGGS) do
			if egg.name .. " (" .. shortNumber(egg.price) .. ")" == v then
				CONFIG.egg = i
				CONFIG.autoEggBest = false
				break
			end
		end
	end,
})

local PetGroup = PetSub:AddLeftGroupbox("Pets", "dog")
PetGroup:AddToggle("AutoPet", {
	Text = "Equip Best Pet",
	Default = false,
	Callback = function(v) CONFIG.autoPet = v end,
})
PetGroup:AddSlider("PetCopies", {
	Text = "Pet Copies",
	Default = 3,
	Min = 1,
	Max = 10,
	Rounding = 0,
	Callback = function(v) CONFIG.petCopies = v end,
})
PetGroup:AddToggle("CleanPets", {
	Text = "Sell Bad Pets",
	Default = false,
	Callback = function(v) CONFIG.cleanPets = v end,
})
PetGroup:AddSlider("PetKeep", {
	Text = "Keep Pets",
	Default = 12,
	Min = 3,
	Max = 34,
	Rounding = 0,
	Callback = function(v) CONFIG.petKeep = v end,
})

--// ═══════════════════════════════════════════════════════════
--// STATUS TAB
--// ═══════════════════════════════════════════════════════════

local PlayerSub = StatusTab:AddSubTab("Player", "rbxassetid://113133903091338")
local ProgressSub = StatusTab:AddSubTab("Progress", "rbxassetid://113133903091338")
local ToolsSub = StatusTab:AddSubTab("Tools", "rbxassetid://113133903091338")

local PlayerGroup = PlayerSub:AddLeftGroupbox("Player Data", "user")
local PlayerWins = PlayerGroup:AddLabel("Wins: 0")
local PlayerDmg = PlayerGroup:AddLabel("Damage: 0")
local PlayerLvl = PlayerGroup:AddLabel("Level: 0")
local PlayerRb = PlayerGroup:AddLabel("Rebirth: 0")

local SpendGroup = PlayerSub:AddRightGroupbox("Spending", "credit-card")
local SpendReserve = SpendGroup:AddLabel("Reserve: 0")
local SpendFree = SpendGroup:AddLabel("Free: 0")
local SpendWeapon = SpendGroup:AddLabel("Weapon: -")
local SpendNext = SpendGroup:AddLabel("Next: -")

local ProgressGroup = ProgressSub:AddLeftGroupbox("Progress", "bar-chart")
local ProgressStage = ProgressGroup:AddLabel("Stage Now: -")
local ProgressHigh = ProgressGroup:AddLabel("Highest: 0")
local ProgressPeak = ProgressGroup:AddLabel("Peak Damage: 0")
local ProgressAuras = ProgressGroup:AddLabel("Auras: 0")
local ProgressEggs = ProgressGroup:AddLabel("Eggs: 0")
local ProgressSkills = ProgressGroup:AddLabel("Skills: 0")
local ProgressDel = ProgressGroup:AddLabel("Deleted: 0")

local ToolsGroup = ToolsSub:AddLeftGroupbox("Tools", "wrench")
ToolsGroup:AddButton("Unstuck Movement", unstuck)
ToolsGroup:AddButton("Redeem Codes", redeemCodes)
ToolsGroup:AddButton("Rescan Controllers", function()
	CTRL.lastScan = 0
	scanControllers()
	STATE.note = "controllers rescanned"
end)
ToolsGroup:AddButton("Clean Backpack", function()
	withUI("backpack", function()
		local main = plr.PlayerGui:FindFirstChild("Main")
		local bag = main and main:FindFirstChild("BackPack")
		if not bag then return end
		if not bag.Visible then return end
		local function scoreOf(row)
			return row:GetAttribute("RatingScore") or row:GetAttribute("Rank") or 0
		end
		local function cleanTab(tabButton, frameName, innerName, keep, label)
			fireGui(bag:FindFirstChild(tabButton))
			task.wait(0.8)
			local outer = bag:FindFirstChild(frameName)
			local frame = outer and outer:FindFirstChild(innerName)
			if not frame then return end
			for _ = 1, 4 do
				local remaining = 0
				for _, row in ipairs((frame:FindFirstChild("ScrollingFrame") or frame):GetChildren()) do
					if row:IsA("GuiButton") then remaining += 1 end
				end
				if remaining <= keep then break end
				cleanFrame(frame, frame:FindFirstChild("ScrollingFrame"), keep, scoreOf, label)
				task.wait(1)
			end
		end
		cleanTab("EquipBut", "Equip", "EquipFrame", CONFIG.gearKeep, "gear")
		cleanTab("GemBut", "Gem", "GemFrame", CONFIG.gemKeep, "gems")
	end)
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
--// UI REFRESH LOOP
--// ═══════════════════════════════════════════════════════════

task.spawn(function()
	while _G.__LOOTEVO == generation do
		local best = bestWeapon(STATE.wins)
		local active = activeStageNumber()

		LadderLabel:SetText(string.format("Cursor: %d | Cleared: %d | Blocked: %s | Banked: %d/%d",
			STATE.ladder, STATE.cleared,
			STATE.blockedAt > 0 and tostring(STATE.blockedAt) or "-",
			STATE.bankRuns, CONFIG.farmRuns))
		LadderNote:SetText("Note: " .. tostring(STATE.note))

		SessionLabel:SetText(string.format("Runs: %d | Deaths: %d | Missed: %d",
			STATE.runs, STATE.deaths, STATE.missedClaims))
		SessionWins:SetText(string.format("Wins Gained: %s | Clicks: %d | Casts: %d",
			shortNumber(STATE.winsGained), STATE.clicks, STATE.casts))

		WeaponLabel:SetText(string.format("%s -> %s", STATE.weapon, best and best.name or "-"))

		PlayerWins:SetText("Wins: " .. shortNumber(STATE.wins))
		PlayerDmg:SetText("Damage: " .. shortNumber(STATE.damage))
		PlayerLvl:SetText("Level: " .. STATE.level .. (STATE.needLevel > 0 and (" / " .. STATE.needLevel) or ""))
		PlayerRb:SetText("Rebirth: " .. STATE.rebirth)

		SpendReserve:SetText("Reserve: " .. shortNumber(weaponReserve()))
		SpendFree:SetText("Free: " .. shortNumber(spendableWins()))
		SpendWeapon:SetText("Weapon: " .. STATE.weapon)
		SpendNext:SetText("Next: " .. (best and best.name or "-"))

		ProgressStage:SetText("Stage Now: " .. tostring(active or STATE.ladder))
		ProgressHigh:SetText("Highest: " .. STATE.cleared)
		ProgressPeak:SetText("Peak Damage: " .. shortNumber(STATE.peakDamage))
		ProgressAuras:SetText("Auras: " .. STATE.auras)
		ProgressEggs:SetText("Eggs: " .. STATE.eggsBought)
		ProgressSkills:SetText("Skills: " .. STATE.skillsBought)
		ProgressDel:SetText("Deleted: " .. STATE.deleted)

		task.wait(0.5)
	end
end)

--// ═══════════════════════════════════════════════════════════
--// LOOPS
--// ═══════════════════════════════════════════════════════════

local function loop(interval, enabled, fn)
	task.spawn(function()
		while _G.__LOOTEVO == generation do
			if CONFIG[enabled] then pcall(fn) end
			task.wait(interval)
		end
	end)
end

do
	local last = os.clock()
	RunService.Heartbeat:Connect(function()
		if _G.__LOOTEVO ~= generation then return end
		local now = os.clock()
		local delta = now - last
		last = now
		if CONFIG.autoClick then autoClickTick(math.min(delta, 0.25)) end
	end)
end

loop(5, "autoRebirth", tryRebirth)
loop(15, "autoBuyEgg", buyBestEgg)
loop(12, "autoAura", buyBestAura)
loop(1.2, "castSkills", castSkills)
loop(8, "autoSkill", function() withUI("skills", buySkills) end)
loop(20, "autoWeapon", function() withUI("weapon check", ensureBestEquipped) end)
loop(45, "cleanPets", function() withUI("pets", cleanPets) end)
loop(120, "cleanBag", function()
	if STATE.autoDeleteSet ~= CONFIG.deleteRarity then
		withUI("auto-delete", applyAutoDelete)
	end
end)

task.spawn(function()
	while _G.__LOOTEVO == generation do
		if CONFIG.autoFarm then
			pcall(farmCycle)
		else
			STATE.phase = "idle"
			task.wait(0.5)
		end
		task.wait(0.2)
	end
end)

task.spawn(function()
	while _G.__LOOTEVO == generation do
		pcall(snapshot)
		task.wait(4)
	end
end)

--// ═══════════════════════════════════════════════════════════
--// INIT
--// ═══════════════════════════════════════════════════════════

CTRL.lastScan = 0
scanControllers()
snapshot()
STATE.ladder = math.max(1, math.min(STATE.ladder, STATE.cleared + 1))
task.spawn(function()
	if not _G.__LOOTEVO_CODES then
		_G.__LOOTEVO_CODES = true
		redeemCodes()
	end
end)

Library:OnUnload(function()
	-- nothing extra to clean up
end)

print("[Ivory] LootEvo loaded! (gen " .. generation .. ")")
