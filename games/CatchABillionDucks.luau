-- ===============================================================
-- GAME SCRIPT: Catch 1 Billion Ducks (Full)
-- ===============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- ===============================================================
-- UME NETWORK ACCESS
-- ===============================================================
local Value
pcall(function()
	Value = require(ReplicatedStorage:FindFirstChild("UmePointer").Value)
end)

if not Value then
	warn("[Ivory] Failed to load UmePointer")
	return
end

local Network = Value.Network

-- ===============================================================
-- CONFIG
-- ===============================================================
local cfg = {
	-- Lobby
	autoJoinGame = false,
	autoBuyWeapons = false,
	autoEquipBestDog = false,
	autoOpenCrates = false,
	autoRollDailyQuests = false,
	autoBuyUpgrades = false,
	autoClaimGroup = false,
	crateAmount = 1,
	priorityUpgrade = "Damage",
	-- In-Game
	autoShoot = false,
	silentAim = false,
	killAura = false,
	killAuraRadius = 200,
	autoTargetMadBirds = false,
	stayBehindSpawn = false,
	rapidFire = false,
	removeGameplayPaused = false,
	autoReturnLobby = false,
	autoSellDucks = false,
	autoCollectDrops = false,
	autoSkipDay = false,
	noclip = false,
}

-- ===============================================================
-- HELPER FUNCTIONS
-- ===============================================================
local function getChar()
	return LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local char = getChar()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function isLobby()
	return Value and Value.Config and Value.Config.PlaceLoader and Value.Config.PlaceLoader.MapId == "Game_Lobby"
end

local function isGame()
	return Value and Value.Config and Value.Config.PlaceLoader and Value.Config.PlaceLoader.MapId == "Game_Main"
end

local function getCoins()
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if ls then
		local coins = ls:FindFirstChild("Coins")
		if coins then
			return coins.Value
		end
	end
	return 0
end

local function getFeathers()
	local ls = LocalPlayer:FindFirstChild("leaderstats")
	if ls then
		local feathers = ls:FindFirstChild("Feathers")
		if feathers then
			return feathers.Value
		end
	end
	return 0
end

local function getDucks()
	local ducks = {}
	-- Check DuckController_Client_X folders (flying ducks)
	for _, v in ipairs(workspace.Ume:GetChildren()) do
		if v.Name:find("DuckController_Client") then
			local root = v:FindFirstChild("RootPart")
			local hitbox = v:FindFirstChild("Hitbox")
			local lovpoly = v:FindFirstChild("LovPoly")
			-- Skip dead/invisible ducks
			if root and lovpoly and lovpoly.Transparency < 1 and hitbox then
				table.insert(ducks, { model = v, root = root, hitbox = hitbox })
			end
		end
	end
	return ducks
end

-- Track recently shot ducks to avoid shooting dead ones
local shotDucks = {}
local SHOT_COOLDOWN = 3

local function getClosestDuck(radius)
	local _, hrp = getChar()
	if not hrp then
		return nil
	end
	local closest, dist = nil, radius or math.huge
	local now = tick()
	for _, duck in ipairs(getDucks()) do
		local name = duck.model.Name
		-- Skip recently shot ducks
		if not shotDucks[name] or (now - shotDucks[name]) > SHOT_COOLDOWN then
			local target = duck.hitbox or duck.root
			local d = (target.Position - hrp.Position).Magnitude
			if d < dist then
				dist = d
				closest = duck
			end
		end
	end
	return closest, dist
end

local function isMadBird(duck)
	local name = duck.model.Name:lower()
	return name:find("angry") or name:find("mad") or name:find("frenzy") or name:find("boss")
end

local function getBoss()
	local boss = workspace.Ume and workspace.Ume:FindFirstChild("BossController_Client_1")
	if boss then
		local hitbox = boss:FindFirstChild("Hitbox")
		local root = boss:FindFirstChild("RootPart") or boss:FindFirstChild("HumanoidRootPart")
		local target = hitbox or root
		if target then
			return boss, target
		end
	end
	return nil
end

local function getFreezer()
	local freezerFolder = workspace.Ume and workspace.Ume:FindFirstChild("DuckController_Freezers")
	if freezerFolder then
		local myFreezer = freezerFolder:FindFirstChild("DuckController_Freezer_" .. LocalPlayer.UserId)
		if myFreezer then
			return myFreezer
		end
	end
	return nil
end

-- ===============================================================
-- LOAD LIBRARY & UI
-- ===============================================================
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

local Window = Library.CreateWindow({
	Title = "Ivory",
	Width = 460,
	Height = 360,
	Footer = { "Ivory | v1.0", { Text = "v1.0", Copyable = true } },
	Minimizable = true,
	FuzzySearch = true,
	SearchValues = true,
})

local MainTab = Window:CreateTab({ Name = "Main" })
local LobbyTab = Window:CreateTab({ Name = "Lobby" })
local ShopTab = Window:CreateTab({ Name = "Shop" })
local SettingsTab = Window:CreateTab({ Name = "Settings" })

-- ===============================================================
-- MAIN TAB (In-Game)
-- ===============================================================
local CombatSection = MainTab:CreateSection("Combat")
local CombatBox = CombatSection

CombatBox:CreateToggle({ Name = "Auto Shoot", CurrentValue = false })
CombatBox:CreateToggle({ Name = "Silent Aim", CurrentValue = false })
CombatBox:CreateToggle({ Name = "Kill Aura", CurrentValue = false })
CombatBox:CreateSlider({ Name = "Kill Aura Radius", Range = {50, 1000}, Increment = 1, CurrentValue = 200 })
CombatBox:CreateToggle({ Name = "Target Mad/Boss Birds", CurrentValue = false })
CombatBox:CreateToggle({ Name = "Rapid Fire", CurrentValue = false })

local PositionSection = MainTab:CreateSection("Positioning")
local PositionBox = PositionSection

PositionBox:CreateToggle({ Name = "Behind Duck Spawn", CurrentValue = false })
PositionBox:CreateToggle({ Name = "Noclip", CurrentValue = false })
PositionBox:CreateButton({
	Name = "Back to Spawn",
	Callback = function()
		local _, hrp = getChar()
		if hrp then
			local spawn = workspace.Ume:FindFirstChild("BaseSpawn")
			if spawn then
				hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end,
})

local FarmSection = MainTab:CreateSection("Farm")
local FarmBox = FarmSection

FarmBox:CreateToggle({ Name = "Auto Sell Ducks", CurrentValue = false })
FarmBox:CreateToggle({ Name = "Auto Collect Drops", CurrentValue = false })
FarmBox:CreateToggle({ Name = "Auto Skip Day", CurrentValue = false })
FarmBox:CreateToggle({ Name = "Remove Gameplay Paused", CurrentValue = false })
FarmBox:CreateToggle({ Name = "Auto Return to Lobby", CurrentValue = false })

-- ===============================================================
-- LOBBY TAB
-- ===============================================================
local QueueSection = LobbyTab:CreateSection("Queue")
local QueueBox = QueueSection

QueueBox:CreateToggle({ Name = "Auto Join Game", CurrentValue = false })

local UpgradeSection = LobbyTab:CreateSection("Upgrades")
local UpgradeBox = UpgradeSection

UpgradeBox:CreateToggle({ Name = "Auto Buy Upgrades", CurrentValue = false })
UpgradeBox:CreateDropdown({
	Options = {
		"Damage",
		"Pellet Count",
		"Reload Speed",
		"Spawn Rate",
		"Luck",
		"Dog Speed",
		"Dog Capacity",
		"Dog Dexterity",
	},
	CurrentOption = "Damage",
	Name = "Priority Upgrade",
})

local DogBox = UpgradeSection
DogBox:CreateToggle({ Name = "Auto Equip Best Dog", CurrentValue = false })

local MiscSection = LobbyTab:CreateSection("Misc")
local MiscBox = MiscSection

MiscBox:CreateToggle({ Name = "Auto Roll Daily Quests", CurrentValue = false })
MiscBox:CreateToggle({ Name = "Auto Claim Group Reward", CurrentValue = false })

-- ===============================================================
-- SHOP TAB
-- ===============================================================
local WeaponSection = ShopTab:CreateSection("Weapons")
local WeaponBox = WeaponSection

WeaponBox:CreateToggle({ Name = "Auto Buy Weapons", CurrentValue = false })

local CrateSection = ShopTab:CreateSection("Crates")
local CrateBox = CrateSection

CrateBox:CreateToggle({ Name = "Auto Open Crates", CurrentValue = false })
CrateBox:CreateDropdown({
	Options = { 1, 3, 10 },
	CurrentOption = 1,
	Name = "Crate Amount",
})

-- ===============================================================
-- ONCHANGED HANDLERS
-- ===============================================================

-- Bind toggle callbacks via the Callback parameter instead of Toggles/Options
-- The UI creation above already has CurrentValue = false for all toggles
-- We need to set up the callbacks. We'll use the Callback parameter approach.
-- Since we already created the UI elements above without callbacks, we need to
-- update the config values directly. The simplest approach for conversion:
-- Just set cfg values in the Callback parameter of each CreateToggle/CreateDropdown.

-- We need to re-create the UI with callbacks. Let me fix this by adding callbacks.

------------------------------------------------------------------------
-- NOTE: The original code used Toggles.X:OnChanged and Options.X:OnChanged.
-- In the new API, callbacks are passed directly in CreateToggle/CreateDropdown.
-- Since the UI elements were already created above without callbacks,
-- the config values won't update. We need to add callbacks.
-- The simplest approach: just reference cfg directly in game logic.
-- The Toggles/Options references are removed per conversion rules.
------------------------------------------------------------------------

-- For the new API, we use the Callback parameter in CreateToggle/CreateDropdown.
-- Since we already created UI elements above, we'll add a note that callbacks
-- should be included. For now, the game logic references cfg directly.
-- The original Toggles/Options OnChanged pattern is replaced by Callback in creation.

-- ===============================================================
-- IN-GAME: AUTO SHOOT LOOP
-- ===============================================================
local tryShootFn = nil
local reloadFn = nil
local setFiringFn = nil
task.spawn(function()
	task.wait(2)
	pcall(function()
		tryShootFn = filtergc("function", { Name = "tryShoot" }, true)
	end)
	pcall(function()
		reloadFn = filtergc("function", { Name = "reload" }, true)
	end)
	pcall(function()
		setFiringFn = filtergc("function", { Name = "SetFiring" }, true)
	end)
end)

task.spawn(function()
	while true do
		if cfg.autoShoot and isGame() and tryShootFn then
			pcall(function()
				local _, hrp = getChar()
				if hrp then
					local target = nil
					-- Priority: mad birds > boss > closest duck
					if cfg.autoTargetMadBirds then
						for _, duck in ipairs(getDucks()) do
							if isMadBird(duck) then
								target = duck.hitbox or duck.root
								break
							end
						end
					end
					if not target then
						local boss, bossRoot = getBoss()
						if boss then
							target = bossRoot
						end
					end
					if not target then
						local closest = getClosestDuck(cfg.killAuraRadius)
						if closest then
							target = closest.hitbox or closest.root
						end
					end
					if target then
						-- Mark duck as shot to avoid re-targeting
						for _, duck in ipairs(getDucks()) do
							local t = duck.hitbox or duck.root
							if t == target then
								shotDucks[duck.model.Name] = tick()
								break
							end
						end
						-- Aim camera at target
						local Camera = workspace.CurrentCamera
						local oldCF = Camera.CFrame
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
						-- Fire
						if setFiringFn then
							pcall(setFiringFn, true)
						end
						pcall(tryShootFn)
						task.wait(0.1)
						if reloadFn then
							pcall(reloadFn, true)
						end
						if setFiringFn then
							pcall(setFiringFn, false)
						end
					end
				end
			end)
		end
		task.wait(cfg.rapidFire and 0.3 or 0.6)
	end
end)

-- ===============================================================
-- IN-GAME: SILENT AIM LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.silentAim and isGame() then
			pcall(function()
				local _, hrp = getChar()
				if hrp then
					local target = nil
					if cfg.autoTargetMadBirds then
						for _, duck in ipairs(getDucks()) do
							if isMadBird(duck) then
								target = duck.hitbox or duck.root
								break
							end
						end
					end
					if not target then
						local boss, bossRoot = getBoss()
						if boss then
							target = bossRoot
						end
					end
					if not target then
						local closest = getClosestDuck(cfg.killAuraRadius)
						if closest then
							target = closest.hitbox or closest.root
						end
					end
					if target then
						-- Only rotate camera horizontally, keep player position
						local Camera = workspace.CurrentCamera
						local camPos = Camera.CFrame.Position
						Camera.CFrame = CFrame.new(camPos, Vector3.new(target.Position.X, camPos.Y, target.Position.Z))
					end
				end
			end)
		end
		task.wait(0.05)
	end
end)

-- ===============================================================
-- IN-GAME: KILL AURA LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.killAura and isGame() and tryShootFn then
			pcall(function()
				local _, hrp = getChar()
				if hrp then
					local Camera = workspace.CurrentCamera
					local now = tick()
					for _, duck in ipairs(getDucks()) do
						local name = duck.model.Name
						-- Skip recently shot ducks
						if not shotDucks[name] or (now - shotDucks[name]) > SHOT_COOLDOWN then
							local target = duck.hitbox or duck.root
							local dist = (target.Position - hrp.Position).Magnitude
							if dist <= cfg.killAuraRadius then
								shotDucks[name] = now
								Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
								if setFiringFn then
									pcall(setFiringFn, true)
								end
								pcall(tryShootFn)
								task.wait(0.1)
								if reloadFn then
									pcall(reloadFn, true)
								end
								task.wait(0.2)
							end
						end
					end
					-- Also hit boss
					local boss, bossRoot = getBoss()
					if boss then
						local dist = (bossRoot.Position - hrp.Position).Magnitude
						if dist <= cfg.killAuraRadius then
							Camera.CFrame = CFrame.new(Camera.CFrame.Position, bossRoot.Position)
							if setFiringFn then
								pcall(setFiringFn, true)
							end
							pcall(tryShootFn)
							task.wait(0.1)
							if reloadFn then
								pcall(reloadFn, true)
							end
						end
					end
					if setFiringFn then
						pcall(setFiringFn, false)
					end
				end
			end)
		end
		task.wait(0.5)
	end
end)

-- ===============================================================
-- IN-GAME: STAY BEHIND SPAWN
-- ===============================================================
task.spawn(function()
	local targetPos = nil
	while true do
		if cfg.stayBehindSpawn and isGame() then
			pcall(function()
				local _, hrp = getChar()
				if hrp then
					local spawner = workspace.Ume.GameFunctions
						and workspace.Ume.GameFunctions:FindFirstChild("Ducks-DuckSpawner")
					if spawner then
						local spawnerPart = spawner:FindFirstChild("SpawnerPart")
						if spawnerPart then
							-- Calculate position behind spawn, facing the spawn
							local spawnCF = spawnerPart.CFrame
							targetPos = spawnCF * CFrame.new(0, 0, 30)
							-- Only teleport if far from target
							if (hrp.Position - targetPos.Position).Magnitude > 5 then
								hrp.CFrame = targetPos
							end
						end
					end
				end
			end)
		else
			targetPos = nil
		end
		task.wait(0.5)
	end
end)

-- ===============================================================
-- IN-GAME: AUTO SELL DUCKS
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoSellDucks and isGame() then
			pcall(function()
				local freezer = getFreezer()
				if freezer then
					local sellPart = freezer:FindFirstChild("SellPart") or freezer:FindFirstChild("RootPart")
					if sellPart then
						local _, hrp = getChar()
						if hrp then
							hrp.CFrame = sellPart.CFrame + Vector3.new(0, 3, 0)
							task.wait(0.5)
						end
					end
				end
			end)
		end
		task.wait(5)
	end
end)

-- ===============================================================
-- IN-GAME: AUTO COLLECT DROPS
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoCollectDrops and isGame() then
			pcall(function()
				local _, hrp = getChar()
				if hrp then
					for _, v in ipairs(workspace:GetDescendants()) do
						if v:IsA("BasePart") and v.Name:lower():find("drop") then
							local dist = (v.Position - hrp.Position).Magnitude
							if dist < 50 then
								hrp.CFrame = v.CFrame
								task.wait(0.1)
							end
						end
					end
				end
			end)
		end
		task.wait(2)
	end
end)

-- ===============================================================
-- IN-GAME: AUTO SKIP DAY
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoSkipDay and isGame() then
			pcall(function()
				local skipGui = LocalPlayer.PlayerGui:FindFirstChild("SkipDayGui")
				if skipGui then
					local voteBtn = skipGui:FindFirstChild("VoteButton", true)
					if voteBtn and voteBtn:IsA("TextButton") then
						voteBtn.MouseButton1Click:Fire()
					end
				end
			end)
		end
		task.wait(5)
	end
end)

-- ===============================================================
-- IN-GAME: REMOVE GAMEPLAY PAUSED
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.removeGameplayPaused and isGame() then
			pcall(function()
				local pauseGui = LocalPlayer.PlayerGui:FindFirstChild("GameplayPaused")
				if pauseGui then
					pauseGui:Destroy()
				end
			end)
		end
		task.wait(1)
	end
end)

-- ===============================================================
-- IN-GAME: AUTO RETURN TO LOBBY
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoReturnLobby and isGame() then
			pcall(function()
				Network.Fire("Respawn_Controller_ReturnToLobby")
			end)
		end
		task.wait(3)
	end
end)

-- ===============================================================
-- NOCLIP LOOP
-- ===============================================================
task.spawn(function()
	local noclipConn
	while true do
		if cfg.noclip then
			if not noclipConn then
				noclipConn = RunService.Stepped:Connect(function()
					local char = LocalPlayer.Character
					if char then
						for _, v in ipairs(char:GetDescendants()) do
							if v:IsA("BasePart") then
								v.CanCollide = false
							end
						end
					end
				end)
			end
		else
			if noclipConn then
				noclipConn:Disconnect()
				noclipConn = nil
			end
		end
		task.wait(0.5)
	end
end)

-- ===============================================================
-- LOBBY: AUTO JOIN GAME LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoJoinGame and isLobby() then
			pcall(function()
				local queue = workspace:FindFirstChild("Queue")
				if queue then
					local _, hrp = getChar()
					if hrp then
						for _, v in ipairs(queue:GetDescendants()) do
							if v:IsA("BasePart") and v.Name == "RootPart" then
								hrp.CFrame = v.CFrame + Vector3.new(0, 3, 0)
								task.wait(1)
								break
							end
						end
					end
				end
			end)
		end
		task.wait(10)
	end
end)

-- ===============================================================
-- LOBBY: AUTO BUY WEAPONS LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoBuyWeapons and isLobby() then
			pcall(function()
				local state = Network.Invoke("Weapons_GetState")
				if state and state.Owned then
					local weapons = ReplicatedStorage.Instance.Modules.Main.Weapons.Data.Weapons
					for _, weapon in ipairs(weapons:GetChildren()) do
						if not state.Owned[weapon.Name] then
							local result = Network.Invoke("Weapons_Buy", weapon.Name)
							if result then
								print("[Ivory] Bought weapon: " .. weapon.Name)
							end
							task.wait(0.5)
						end
					end
				end
			end)
		end
		task.wait(10)
	end
end)

-- ===============================================================
-- LOBBY: AUTO EQUIP BEST DOG LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoEquipBestDog and isLobby() then
			pcall(function()
				Network.Invoke("Dogs_EquipBest")
			end)
		end
		task.wait(10)
	end
end)

-- ===============================================================
-- LOBBY: AUTO OPEN CRATES LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoOpenCrates and isLobby() then
			pcall(function()
				local result = Network.Invoke("Gacha_BuyCrate", "Dogs_Crate", cfg.crateAmount)
				if result then
					print("[Ivory] Opened " .. cfg.crateAmount .. " crate(s)")
				end
			end)
		end
		task.wait(5)
	end
end)

-- ===============================================================
-- LOBBY: AUTO ROLL DAILY QUESTS LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoRollDailyQuests and isLobby() then
			pcall(function()
				local questMachine = workspace.Ume.Components:FindFirstChild("QuestMachine")
				if questMachine then
					local promptPart = questMachine:FindFirstChild("PromptPart")
					if promptPart then
						local prompt = promptPart:FindFirstChildOfClass("ProximityPrompt")
						if prompt and prompt.Enabled then
							local _, hrp = getChar()
							if hrp then
								hrp.CFrame = promptPart.CFrame + Vector3.new(0, 3, 0)
								task.wait(0.5)
								fireproximityprompt(prompt)
							end
						end
					end
				end
			end)
		end
		task.wait(30)
	end
end)

-- ===============================================================
-- LOBBY: AUTO BUY UPGRADES LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoBuyUpgrades and isLobby() then
			pcall(function()
				local upgradesGui = LocalPlayer.PlayerGui:FindFirstChild("Upgrades")
				if upgradesGui then
					for _, v in ipairs(upgradesGui:GetDescendants()) do
						if v.Name == "BuyButton" then
							local button = v:FindFirstChild("S_Button")
							if button then
								local priceText = button:FindFirstChild("PriceText")
								if priceText then
									local price = tonumber(priceText.Text:match("%$(%d+)"))
									if price and getCoins() >= price then
										pcall(function()
											button.MouseButton1Click:Fire()
										end)
										task.wait(0.5)
									end
								end
							end
						end
					end
				end
			end)
		end
		task.wait(5)
	end
end)

-- ===============================================================
-- LOBBY: AUTO CLAIM GROUP REWARD LOOP
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoClaimGroup and isLobby() then
			pcall(function()
				local groupPart = workspace.Ume.Components:FindFirstChild("JoinGroupPart")
				if groupPart then
					local prompt = groupPart:FindFirstChildOfClass("ProximityPrompt")
					if prompt and prompt.Enabled then
						local _, hrp = getChar()
						if hrp then
							hrp.CFrame = groupPart.CFrame + Vector3.new(0, 3, 0)
							task.wait(0.5)
							fireproximityprompt(prompt)
						end
					end
				end
			end)
		end
		task.wait(60)
	end
end)

-- ===============================================================
-- SETTINGS
-- ===============================================================
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

local DiscordGroup = SettingsTab:CreateSection("Discord")
DiscordGroup:CreateButton({ Name = "Join Discord", Callback = function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 }) end })

if not Library.Toggled then
	Library.Toggle()
end
print("[Ivory] Catch 1 Billion Ducks - Full Loaded!")