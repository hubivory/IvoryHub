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
	difficulty = "NORMAL",
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
	-- Settings
	menuKeybind = "RightShift",
	fpsCap = 60,
	antiAfk = false,
	notificationSide = "Right",
	dpiScale = 100,
	cornerRadius = 8,
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
	for _, v in ipairs(workspace.Ume:GetChildren()) do
		if v.Name:find("DuckController_Client") then
			local root = v:FindFirstChild("RootPart")
			local hitbox = v:FindFirstChild("Hitbox")
			local lovpoly = v:FindFirstChild("LovPoly")
			if root and lovpoly and lovpoly.Transparency < 1 and hitbox then
				table.insert(ducks, { model = v, root = root, hitbox = hitbox })
			end
		end
	end
	return ducks
end

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

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
    writefile(LIB_FILE, httpGet(LIB_URL))
end
local Library = loadstring(readfile(LIB_FILE))()

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 720,
	Height = 600,
})

local Tabs = {
	Main = Window:CreateTab({ Name = "Main" }),
	Lobby = Window:CreateTab({ Name = "Lobby" }),
	Shop = Window:CreateTab({ Name = "Shop" }),
	["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

-- ===============================================================
-- MAIN TAB (In-Game)
-- ===============================================================
-- Discord Button
local DiscordSection = Tabs.Main:CreateSection("discord")
DiscordSection:CreateButton({
	Name = "Join Discord For Dupe",
	Callback = function()
		pcall(function()
			setclipboard("https://discord.gg/H9T7CHBEZX")
		end)
		Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 })
	end,
})

local CombatSection = Tabs.Main:CreateSection("Combat")

CombatSection:CreateToggle({
	Name = "Auto Shoot",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoShoot = v
	end,
})

CombatSection:CreateToggle({
	Name = "Silent Aim",
	CurrentValue = false,
	Callback = function(v)
		cfg.silentAim = v
	end,
})

CombatSection:CreateToggle({
	Name = "Kill Aura",
	CurrentValue = false,
	Callback = function(v)
		cfg.killAura = v
	end,
})

CombatSection:CreateSlider({
	Name = "Kill Aura Radius",
	Min = 50,
	Max = 1000,
	CurrentValue = 200,
	Callback = function(v)
		cfg.killAuraRadius = v
	end,
})

CombatSection:CreateToggle({
	Name = "Target Mad/Boss Birds",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoTargetMadBirds = v
	end,
})

CombatSection:CreateToggle({
	Name = "Rapid Fire",
	CurrentValue = false,
	Callback = function(v)
		cfg.rapidFire = v
	end,
})

local PositionSection = Tabs.Main:CreateSection("Positioning")

PositionSection:CreateToggle({
	Name = "Behind Duck Spawn",
	CurrentValue = false,
	Callback = function(v)
		cfg.stayBehindSpawn = v
	end,
})

PositionSection:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Callback = function(v)
		cfg.noclip = v
	end,
})

PositionSection:CreateButton({
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

local FarmSection = Tabs.Main:CreateSection("Farm")

FarmSection:CreateToggle({
	Name = "Auto Sell Ducks",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoSellDucks = v
	end,
})

FarmSection:CreateToggle({
	Name = "Auto Collect Drops",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoCollectDrops = v
	end,
})

FarmSection:CreateToggle({
	Name = "Auto Skip Day",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoSkipDay = v
	end,
})

FarmSection:CreateToggle({
	Name = "Remove Gameplay Paused",
	CurrentValue = false,
	Callback = function(v)
		cfg.removeGameplayPaused = v
	end,
})

FarmSection:CreateToggle({
	Name = "Auto Return to Lobby",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoReturnLobby = v
	end,
})

-- ===============================================================
-- LOBBY TAB
-- ===============================================================
local QueueSection = Tabs.Lobby:CreateSection("Queue")

QueueSection:CreateDropdown({
	Name = "Difficulty",
	Values = { "NORMAL", "HARDCORE", "NIGHTMARE" },
	CurrentOption = "NORMAL",
	Callback = function(v)
		cfg.difficulty = v
	end,
})

QueueSection:CreateButton({
	Name = "Select Difficulty",
	Callback = function()
		pcall(function()
			-- Try to find and open difficulty selection
			local difficultyPart = workspace:FindFirstChild("DifficultySelect")
				or workspace.Ume and workspace.Ume:FindFirstChild("DifficultySelect")
			if difficultyPart then
				local prompt = difficultyPart:FindFirstChildOfClass("ProximityPrompt")
				if prompt and prompt.Enabled then
					local _, hrp = getChar()
					if hrp then
						hrp.CFrame = difficultyPart.CFrame + Vector3.new(0, 3, 0)
						task.wait(0.5)
						fireproximityprompt(prompt)
						Library.Notify({ Title = "Ivory", Content = "Select difficulty: " .. cfg.difficulty, Type = "Info", Duration = 2 })
					end
				end
			else
				Library.Notify({ Title = "Ivory", Content = "Difficulty select not found", Type = "Warning", Duration = 2 })
			end
		end)
	end,
})

QueueSection:CreateToggle({
	Name = "Auto Join Game",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoJoinGame = v
	end,
})

local UpgradeSection = Tabs.Lobby:CreateSection("Upgrades")

UpgradeSection:CreateToggle({
	Name = "Auto Buy Upgrades",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoBuyUpgrades = v
	end,
})

UpgradeSection:CreateDropdown({
	Name = "Priority Upgrade",
	Values = {
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
	Callback = function(v)
		cfg.priorityUpgrade = v
	end,
})

UpgradeSection:CreateToggle({
	Name = "Auto Equip Best Dog",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoEquipBestDog = v
	end,
})

local MiscSection = Tabs.Lobby:CreateSection("Misc")

MiscSection:CreateToggle({
	Name = "Auto Roll Daily Quests",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoRollDailyQuests = v
	end,
})

MiscSection:CreateToggle({
	Name = "Auto Claim Group Reward",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoClaimGroup = v
	end,
})

-- ===============================================================
-- SHOP TAB
-- ===============================================================
local WeaponSection = Tabs.Shop:CreateSection("Weapons")

WeaponSection:CreateToggle({
	Name = "Auto Buy Weapons",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoBuyWeapons = v
	end,
})

local CrateSection = Tabs.Shop:CreateSection("Crates")

CrateSection:CreateToggle({
	Name = "Auto Open Crates",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoOpenCrates = v
	end,
})

CrateSection:CreateDropdown({
	Name = "Crate Amount",
	Values = { "1", "3", "10" },
	CurrentOption = "1",
	Callback = function(v)
		cfg.crateAmount = tonumber(v) or 1
	end,
})

-- ===============================================================
-- SETTINGS TAB (Always Last)
-- ===============================================================
-- Credits Section
local CreditsSection = Tabs["UI Settings"]:CreateSection("Credits")
local CreditLabel = CreditsSection:CreateLabel({ Text = "Made by mommy Crow" })

-- Menu Settings Section
local MenuSection = Tabs["UI Settings"]:CreateSection("menu settings")

MenuSection:CreateKeybind({
	Name = "Menu Keybind",
	CurrentKeybind = "RightShift",
	Callback = function(k)
		cfg.menuKeybind = k
	end,
})

MenuSection:CreateToggle({
	Name = "Keybind List",
	CurrentValue = false,
	Callback = function(v)
		Library.KeybindList.Visible = v
	end,
})

MenuSection:CreateSlider({
	Name = "FPS Cap",
	Min = 30,
	Max = 240,
	CurrentValue = 60,
	Callback = function(v)
		cfg.fpsCap = v
		setfpscap(v)
	end,
})

MenuSection:CreateDropdown({
	Name = "Language",
	Values = { "English" },
	CurrentOption = "English",
	Callback = function(v) end,
})

MenuSection:CreateToggle({
	Name = "Anti AFK",
	CurrentValue = false,
	Callback = function(v)
		cfg.antiAfk = v
		if v then
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				LocalPlayer.Idled:Connect(function()
					VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
					VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				end)
			end)
		end
	end,
})

MenuSection:CreateButton({
	Name = "Test Notification",
	Callback = function()
		Library.Notify({ Title = "Ivory", Content = "This is a test notification!", Type = "Info", Duration = 3 })
	end,
})

MenuSection:CreateDropdown({
	Name = "Notification Side",
	Values = { "Left", "Right" },
	CurrentOption = "Right",
	Callback = function(v)
		cfg.notificationSide = v
	end,
})

MenuSection:CreateDropdown({
	Name = "DPI Scale",
	Values = { "50%", "75%", "100%", "125%", "150%", "200%" },
	CurrentOption = "100%",
	Callback = function(v)
		cfg.dpiScale = tonumber(v:match("%d+")) or 100
	end,
})

MenuSection:CreateSlider({
	Name = "Corner Radius",
	Min = 0,
	Max = 20,
	CurrentValue = 8,
	Callback = function(v)
		cfg.cornerRadius = v
	end,
})

MenuSection:CreateButton({
	Name = "Unload",
	Callback = function()
		Library:Unload()
	end,
})

-- Server Section
local ServerSection = Tabs["UI Settings"]:CreateSection("server")

ServerSection:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
	end,
})

ServerSection:CreateButton({
	Name = "Server Hop",
	Callback = function()
		pcall(function()
			local servers = game:GetService("HttpService"):JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
			if servers and servers.data then
				for _, server in ipairs(servers.data) do
					if server.id ~= game.JobId and server.playing < server.maxPlayers then
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
						break
					end
				end
			end
		end)
	end,
})

-- Themes Section
local ThemesSection = Tabs["UI Settings"]:CreateSection("themes")

ThemesSection:CreateLabel({ Text = "Accent Color" }):CreateColorPicker("AccentColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(c)
		Library.Scheme.Accent = c
		Library:UpdateColorsUsingRegistry()
	end,
})

-- Configuration Section
local ConfigSection = Tabs["UI Settings"]:CreateSection("configuration")

ConfigSection:CreateInput({
	Name = "Config Name",
	Default = "",
	Placeholder = "Enter config name",
	Callback = function(v) end,
})

ConfigSection:CreateButton({
	Name = "Save Config",
	Callback = function()
		Library.Notify({ Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 2 })
	end,
})

ConfigSection:CreateButton({
	Name = "Load Config",
	Callback = function()
		Library.Notify({ Title = "Ivory", Content = "Config loaded!", Type = "Success", Duration = 2 })
	end,
})

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
						for _, duck in ipairs(getDucks()) do
							local t = duck.hitbox or duck.root
							if t == target then
								shotDucks[duck.model.Name] = tick()
								break
							end
						end
						local Camera = workspace.CurrentCamera
						local oldCF = Camera.CFrame
						Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
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
							local spawnCF = spawnerPart.CFrame
							targetPos = spawnCF * CFrame.new(0, 0, 30)
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
-- Uses the game's own Queue API via Value.Queue
-- ===============================================================
task.spawn(function()
	while true do
		if cfg.autoJoinGame and isLobby() then
			pcall(function()
				-- Map our config difficulty to the game's mode name
				local modeMap = {
					NORMAL = "Normal",
					HARDCORE = "Hardcore",
					NIGHTMARE = "Nightmare",
				}
				local mode = modeMap[cfg.difficulty] or "Normal"

				-- Teleport to Queue_Teleport stand to trigger zone entry
				local queue = workspace:FindFirstChild("Queue")
				if queue then
					local _, hrp = getChar()
					if hrp then
						for _, v in ipairs(queue:GetDescendants()) do
							if v:IsA("BasePart") and v.Name == "RootPart" then
								hrp.CFrame = v.CFrame + Vector3.new(0, 3, 0)
								break
							end
						end
					end
				end

				-- Wait for server to open the party queue
				task.wait(3)

				-- Use the game's Queue API to configure and create
				if Value and Value.Queue then
					Value.Queue.ChooseMode(mode)
					task.wait(0.3)
					Value.Queue.ChooseSize(5)
					task.wait(0.3)
					Value.Queue.CreateParty()
					print("[Ivory] Auto Join: Creating party (mode=" .. mode .. ")")
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
-- FOOTER UPDATE
-- ===============================================================
task.spawn(function()
	while true do
		local location = isLobby() and "Lobby" or (isGame() and "Game" or "Unknown")
		local diff = isLobby() and (" | " .. cfg.difficulty) or ""
		local footer = "v1.4 | " .. location .. diff .. " | " .. LocalPlayer.UserId
		pcall(function()
			Window:SetFooter(footer)
		end)
		task.wait(1)
	end
end)

-- ===============================================================
-- INITIALIZE
-- ===============================================================
if not Library.Toggled then
	Library.Toggle()
end
print("[Ivory] Catch 1 Billion Ducks - Full Loaded!")
