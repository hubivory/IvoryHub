local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

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

local LIB_SRC = getgenv()._IvoryLibSrc
if not LIB_SRC or #LIB_SRC == 0 then
	LIB_SRC = httpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua")
end
if not LIB_SRC or #LIB_SRC == 0 then
	error("[Ivory] Failed to fetch library. Check HTTP support.")
end
if LIB_SRC:byte(1) == 0xEF and LIB_SRC:byte(2) == 0xBB and LIB_SRC:byte(3) == 0xBF then
	LIB_SRC = LIB_SRC:sub(4)
end
local IvoryHub = loadstring(LIB_SRC)()
if not IvoryHub then
	error("[Ivory] Failed to compile library")
end

local Network = require(ReplicatedStorage.Shared.modules.Network)
local CombatFormulas = require(ReplicatedStorage.Shared.modules.CombatFormulas)
local ExpansionGate = require(ReplicatedStorage.Shared.modules.ExpansionGate)

local ActionRequest = Network.GetFunction("ActionRequest")
local CombatRequest = Network.GetFunction("CombatRequest")
local FarmingRequest = Network.GetFunction("FarmingRequest")
local GetProfileData = Network.GetFunction("GetProfileData")

local ActionStateChanged = Network.GetEvent("ActionStateChanged")
local CombatStateChanged = Network.GetEvent("CombatStateChanged")
local ProfileStateChanged = Network.GetEvent("ProfileStateChanged")
local FarmingStateChanged = Network.GetEvent("FarmingStateChanged")

local Window = IvoryHub.CreateWindow({
	Name = "Ivory",
	Width = 720,
	Height = 600,
})

local Tabs = {
	Combat = Window:CreateTab({ Name = "Combat" }),
	Fishing = Window:CreateTab({ Name = "Fishing" }),
	Cooking = Window:CreateTab({ Name = "Cooking" }),
	Farming = Window:CreateTab({ Name = "Farming" }),
	Auto = Window:CreateTab({ Name = "Auto" }),
	Misc = Window:CreateTab({ Name = "Misc" }),
	["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

-- Discord Button
local DiscordSection = Tabs.Combat:CreateSection("discord")
DiscordSection:CreateButton({
	Name = "Join Discord For Dupe",
	Callback = function()
		pcall(function()
			setclipboard("https://discord.gg/bac")
		end)
		IvoryHub.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 })
	end,
})

-- ═══════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════
local State = {
	Combat_AutoFight = false,
	Combat_MonsterId = "",
	Combat_MonsterStyle = "Stab",
	Combat_AutoEat = false,
	Combat_EatThreshold = 40,

	Fishing_AutoFish = false,
	Fishing_AreaId = "",
	Fishing_FishId = "",

	Cooking_AutoCook = false,
	Cooking_StationId = "",
	Cooking_RecipeId = "",

	Farming_AutoFarm = false,
	Farming_Category = "Allotment",
	Farming_CropId = "Potato",
	Farming_PlotIndex = 1,
	Farming_Compost = false,

	Auto_LoopEnabled = false,
	Auto_FightThreshold = 60,
	Auto_FishFoodCount = 50,
	Auto_CookAfterFish = true,
	Auto_FarmOnFullHp = true,

	Misc_AntiAfk = false,
	Misc_AutoDaily = false,
	Misc_AutoClaimMastery = false,
}

local profile = nil
local combatState = nil
local actionState = nil
local farmingState = nil

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════
local function getProfile()
	local ok, data = pcall(function()
		return GetProfileData:InvokeServer()
	end)
	if ok and data then
		profile = data
		return data
	end
	return profile
end

local function getCombatHp()
	if not profile then return 100, 100 end
	local hp = profile.CombatHP or 100
	local maxHp = 100
	if profile.Skills and profile.Skills.Hitpoints then
		maxHp = CombatFormulas.MaxHitpoints(profile.Skills.Hitpoints.Level or 1)
	end
	return hp, maxHp
end

local function getSkillLevel(skillName)
	if not profile or not profile.Skills or not profile.Skills[skillName] then return 1 end
	return profile.Skills[skillName].Level or 1
end

local function getItemCount(itemId)
	if not profile or not profile.Inventory then return 0 end
	return profile.Inventory[itemId] or 0
end

local function startCombat(monsterId, style)
	local ok, err = CombatRequest:InvokeServer("Start", {
		Style = style or "Stab",
		MonsterId = monsterId,
	})
	return ok, err
end

local function eatFood()
	local ok, err = CombatRequest:InvokeServer("EatFood")
	return ok, err
end

local function selectFood(itemId)
	local ok, err = CombatRequest:InvokeServer("SelectFood", itemId)
	return ok, err
end

local function startFishing(fishId)
	local ok, err = ActionRequest:InvokeServer("Start", {
		SkillType = "Fishing",
		ActionName = fishId,
	})
	return ok, err
end

local function startCooking(recipeId)
	local ok, err = ActionRequest:InvokeServer("Start", {
		SkillType = "Cooking",
		ActionName = recipeId,
	})
	return ok, err
end

local function stopAction()
	local ok, err = ActionRequest:InvokeServer("Stop")
	return ok, err
end

local function selectCookingRecipe(stationId, recipeId)
	local ok, err = ActionRequest:InvokeServer("SelectRecipe", {
		Station = stationId,
		RecipeId = recipeId,
	})
	return ok, err
end

local function farmingPlant(category, plotIndex, cropId)
	local ok, err = FarmingRequest:InvokeServer("Plant", {
		Category = category,
		PlotIndex = plotIndex,
		CropId = cropId,
	})
	return ok, err
end

local function farmingHarvest(category, plotIndex)
	local ok, err = FarmingRequest:InvokeServer("Harvest", {
		Category = category,
		PlotIndex = plotIndex,
	})
	return ok, err
end

local function claimDailyReward()
	local ok, err = pcall(function()
		local Remote = ReplicatedStorage.Remotes:FindFirstChild("DailyRewardRequest")
		if Remote then
			Remote:InvokeServer("Claim")
		end
	end)
	return ok
end

-- ═══════════════════════════════════════════════════════════
-- LOAD CONFIGS
-- ═══════════════════════════════════════════════════════════
local CombatAreaData = require(ReplicatedStorage.Shared.config.CombatAreaData)
local FishingConfig = require(ReplicatedStorage.Shared.config.FishingConfig)
local CookingConfig = require(ReplicatedStorage.Shared.config.CookingConfig)
local FarmingConfig = require(ReplicatedStorage.Shared.config.FarmingConfig)

local monsterNames = {}
local monsterIds = {}
for _, area in ipairs(CombatAreaData and CombatAreaData.Areas or {}) do
	if area.Monsters then
		for _, monster in ipairs(area.Monsters) do
			table.insert(monsterNames, monster.Name .. " (Lv " .. (monster.LevelReq or "?") .. ")")
			monsterIds[#monsterNames] = monster.Id
		end
	end
end

local AllFish = {
	{Id = "RawShrimp", Name = "Raw Shrimp", Area = "Shallow Shores", AreaId = "ShallowShores", Level = 1},
	{Id = "RawLobster", Name = "Raw Lobster", Area = "Shallow Shores", AreaId = "ShallowShores", Level = 40},
	{Id = "RawCrab", Name = "Raw Crab", Area = "Shallow Shores", AreaId = "ShallowShores", Level = 60},
	{Id = "RawSardine", Name = "Raw Sardine", Area = "Shrapnel River", AreaId = "ShrapnelRiver", Level = 5},
	{Id = "RawHerring", Name = "Raw Herring", Area = "Shrapnel River", AreaId = "ShrapnelRiver", Level = 10},
	{Id = "RawCarp", Name = "Raw Carp", Area = "Shrapnel River", AreaId = "ShrapnelRiver", Level = 65},
	{Id = "RawBlowfish", Name = "Raw Blowfish", Area = "Trench of Despair", AreaId = "TrenchOfDespair", Level = 8},
	{Id = "RawPoisonFish", Name = "Raw Poison Fish", Area = "Trench of Despair", AreaId = "TrenchOfDespair", Level = 24},
	{Id = "RawAnglerfish", Name = "Raw Anglerfish", Area = "Trench of Despair", AreaId = "TrenchOfDespair", Level = 50},
	{Id = "RawCaveFish", Name = "Raw Cave Fish", Area = "Trench of Despair", AreaId = "TrenchOfDespair", Level = 75},
	{Id = "RawTrout", Name = "Raw Trout", Area = "Lemvor Pier", AreaId = "LemvorPier", Level = 20},
	{Id = "RawSalmon", Name = "Raw Salmon", Area = "Lemvor Pier", AreaId = "LemvorPier", Level = 28},
	{Id = "RawFanfish", Name = "Raw Fanfish", Area = "Lemvor Pier", AreaId = "LemvorPier", Level = 55},
	{Id = "RawSwordfish", Name = "Raw Swordfish", Area = "Open Waters", AreaId = "OpenWaters", Level = 50},
	{Id = "RawMantaRay", Name = "Raw Manta Ray", Area = "Open Waters", AreaId = "OpenWaters", Level = 85},
	{Id = "RawShark", Name = "Raw Shark", Area = "Barren Ocean", AreaId = "BarrenOcean", Level = 70},
	{Id = "RawWhale", Name = "Raw Whale", Area = "Barren Ocean", AreaId = "BarrenOcean", Level = 95},
	{Id = "LeapingTrout", Name = "Leaping Trout", Area = "Barbarian Fishing", AreaId = "BarbarianFishing", Level = 20},
	{Id = "LeapingSalmon", Name = "Leaping Salmon", Area = "Barbarian Fishing", AreaId = "BarbarianFishing", Level = 35},
	{Id = "LeapingBroadFish", Name = "Leaping Broad Fish", Area = "Barbarian Fishing", AreaId = "BarbarianFishing", Level = 70},
	{Id = "RawSeahorse", Name = "Raw Seahorse", Area = "Secret Area", AreaId = "SecretArea", Level = 13},
	{Id = "RawSkeletonFish", Name = "Raw Skeleton Fish", Area = "Secret Area", AreaId = "SecretArea", Level = 40},
	{Id = "RawMagicFish", Name = "Raw Magic Fish", Area = "Secret Area", AreaId = "SecretArea", Level = 80},
	{Id = "RawLavaFish", Name = "Raw Lava Fish", Area = "Magma Lake", AreaId = "MagmaLake", Level = 100},
	{Id = "RawMagmaFish", Name = "Raw Magma Fish", Area = "Magma Lake", AreaId = "MagmaLake", Level = 105},
	{Id = "RawMagmaEel", Name = "Raw Magma Eel", Area = "Magma Lake", AreaId = "MagmaLake", Level = 112},
	{Id = "RawSpikeFish", Name = "Raw Spike Fish", Area = "Jungle Waters", AreaId = "JungleWaters", Level = 101},
	{Id = "RawBlueCrab", Name = "Raw Blue Crab", Area = "Jungle Waters", AreaId = "JungleWaters", Level = 104},
	{Id = "RawLargeBlowfish", Name = "Raw Large Blowfish", Area = "Jungle Waters", AreaId = "JungleWaters", Level = 106},
	{Id = "RawRockfish", Name = "Raw Rockfish", Area = "Static Valley", AreaId = "StaticValley", Level = 102},
	{Id = "RawStaticJellyfish", Name = "Raw Static Jellyfish", Area = "Static Valley", AreaId = "StaticValley", Level = 108},
	{Id = "RawFrostCrab", Name = "Raw Frost Crab", Area = "Frozen Sea", AreaId = "FrozenSea", Level = 110},
	{Id = "RawFrozenMantaRay", Name = "Raw Frozen Manta Ray", Area = "Frozen Sea", AreaId = "FrozenSea", Level = 113},
	{Id = "RawGhostFish", Name = "Raw Ghost Fish", Area = "Midnight Lagoon", AreaId = "MidnightLagoon", Level = 115},
	{Id = "RawTerrorfish", Name = "Raw Terrorfish", Area = "Midnight Lagoon", AreaId = "MidnightLagoon", Level = 118},
	{Id = "RawMysticSeahorse", Name = "Raw Mystic Seahorse", Area = "Mystic Pond", AreaId = "MysticPond", Level = 116},
	{Id = "RawMysticShark", Name = "Raw Mystic Shark", Area = "Mystic Pond", AreaId = "MysticPond", Level = 120},
	{Id = "RawMackerel", Name = "Raw Mackerel", Area = "Fisherman's Enclave", AreaId = "FishermansEnclave", Level = 18},
	{Id = "RawHalibut", Name = "Raw Halibut", Area = "Fisherman's Enclave", AreaId = "FishermansEnclave", Level = 34},
	{Id = "RawTilapia", Name = "Raw Tilapia", Area = "Fisherman's Enclave", AreaId = "FishermansEnclave", Level = 75},
}

local fishNames = {}
local fishIds = {}
local fishAreas = {}
for _, fish in ipairs(AllFish) do
	local label = fish.Name .. " (" .. fish.Area .. " Lv" .. fish.Level .. ")"
	table.insert(fishNames, label)
	fishIds[#fishNames] = fish.Id
	fishAreas[#fishNames] = fish.AreaId
end

local cookingRecipeNames = {}
local cookingRecipeIds = {}
local cookingStations = {}
for _, recipe in ipairs(CookingConfig.Recipes or {}) do
	local inputName = ""
	if recipe.Inputs and recipe.Inputs[1] then
		inputName = recipe.Inputs[1].ItemId or ""
	end
	local label = recipe.Name .. " (in: " .. (inputName ~= "" and inputName or "?") .. ")"
	table.insert(cookingRecipeNames, label)
	cookingRecipeIds[#cookingRecipeNames] = recipe.Id
	cookingStations[#cookingRecipeNames] = recipe.Station or "BasicCookingFire"
end

local cropNames = {}
local cropIds = {}
for _, crop in ipairs(FarmingConfig.Crops or {}) do
	local label = crop.Name .. " (Lv " .. (crop.LevelReq or 1) .. ")"
	table.insert(cropNames, label)
	cropIds[#cropNames] = crop.Id
end

local plotIndices = {}
for i = 1, 6 do table.insert(plotIndices, tostring(i)) end

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════
local CombatSection = Tabs.Combat:CreateSection("combat")

CombatSection:CreateDropdown({
	Name = "Monster",
	Values = monsterNames,
	Callback = function(v)
		local idx = table.find(monsterNames, v)
		if idx then State.Combat_MonsterId = monsterIds[idx] end
	end,
})

CombatSection:CreateDropdown({
	Name = "Attack Style",
	Values = { "Stab", "Slash", "Block", "Accurate", "Rapid", "Longrange" },
	CurrentOption = "Stab",
	Callback = function(v) State.Combat_MonsterStyle = v end,
})

CombatSection:CreateToggle({
	Name = "Auto Fight",
	CurrentValue = false,
	Callback = function(v) State.Combat_AutoFight = v end,
})

local EatSection = Tabs.Combat:CreateSection("eat")

EatSection:CreateToggle({
	Name = "Auto Eat",
	CurrentValue = false,
	Callback = function(v) State.Combat_AutoEat = v end,
})

EatSection:CreateSlider({
	Name = "Eat at HP %",
	Min = 5,
	Max = 90,
	CurrentValue = 40,
	Callback = function(v) State.Combat_EatThreshold = v end,
})

EatSection:CreateButton({
	Name = "Eat Now",
	Callback = function()
		eatFood()
	end,
})

-- ═══════════════════════════════════════════════════════════
-- FISHING TAB
-- ═══════════════════════════════════════════════════════════
local FishSection = Tabs.Fishing:CreateSection("fishing")

FishSection:CreateDropdown({
	Name = "Fish Type",
	Values = fishNames,
	Callback = function(v)
		local idx = table.find(fishNames, v)
		if idx then
			State.Fishing_FishId = fishIds[idx]
			State.Fishing_AreaId = fishAreas[idx]
		end
	end,
})

FishSection:CreateToggle({
	Name = "Auto Fish",
	CurrentValue = false,
	Callback = function(v) State.Fishing_AutoFish = v end,
})

FishSection:CreateButton({
	Name = "Start Fishing",
	Callback = function()
		if State.Fishing_FishId ~= "" then
			startFishing(State.Fishing_FishId)
		end
	end,
})

FishSection:CreateButton({
	Name = "Stop Action",
	Callback = function()
		stopAction()
	end,
})

-- ═══════════════════════════════════════════════════════════
-- COOKING TAB
-- ═══════════════════════════════════════════════════════════
local CookSection = Tabs.Cooking:CreateSection("cooking")

CookSection:CreateDropdown({
	Name = "Recipe",
	Values = cookingRecipeNames,
	Callback = function(v)
		local idx = table.find(cookingRecipeNames, v)
		if idx then
			State.Cooking_RecipeId = cookingRecipeIds[idx]
			State.Cooking_StationId = cookingStations[idx]
		end
	end,
})

CookSection:CreateToggle({
	Name = "Auto Cook",
	CurrentValue = false,
	Callback = function(v) State.Cooking_AutoCook = v end,
})

CookSection:CreateButton({
	Name = "Select Recipe & Cook",
	Callback = function()
		if State.Cooking_StationId ~= "" and State.Cooking_RecipeId ~= "" then
			selectCookingRecipe(State.Cooking_StationId, State.Cooking_RecipeId)
			task.wait(0.5)
			startCooking(State.Cooking_RecipeId)
		end
	end,
})

CookSection:CreateButton({
	Name = "Stop Action",
	Callback = function()
		stopAction()
	end,
})

-- ═══════════════════════════════════════════════════════════
-- FARMING TAB
-- ═══════════════════════════════════════════════════════════
local FarmSection = Tabs.Farming:CreateSection("farming")

FarmSection:CreateDropdown({
	Name = "Crop",
	Values = cropNames,
	Callback = function(v)
		local idx = table.find(cropNames, v)
		if idx then State.Farming_CropId = cropIds[idx] end
	end,
})

FarmSection:CreateDropdown({
	Name = "Category",
	Values = FarmingConfig.CategoryOrder or { "Allotment" },
	CurrentOption = "Allotment",
	Callback = function(v) State.Farming_Category = v end,
})

FarmSection:CreateDropdown({
	Name = "Plot Number",
	Values = plotIndices,
	CurrentOption = "1",
	Callback = function(v) State.Farming_PlotIndex = tonumber(v) or 1 end,
})

FarmSection:CreateToggle({
	Name = "Auto Farm",
	CurrentValue = false,
	Callback = function(v) State.Farming_AutoFarm = v end,
})

FarmSection:CreateButton({
	Name = "Plant Crop",
	Callback = function()
		farmingPlant(State.Farming_Category, State.Farming_PlotIndex, State.Farming_CropId)
	end,
})

FarmSection:CreateButton({
	Name = "Harvest Plot",
	Callback = function()
		farmingHarvest(State.Farming_Category, State.Farming_PlotIndex)
	end,
})

-- ═══════════════════════════════════════════════════════════
-- AUTO LOOP TAB
-- ═══════════════════════════════════════════════════════════
local AutoSection = Tabs.Auto:CreateSection("auto loop")

AutoSection:CreateLabel({ Text = "Fight > Eat > Fish > Cook > Repeat" })

AutoSection:CreateToggle({
	Name = "Enable Auto Loop",
	CurrentValue = false,
	Callback = function(v) State.Auto_LoopEnabled = v end,
})

AutoSection:CreateSlider({
	Name = "Fight Until HP %",
	Min = 10,
	Max = 90,
	CurrentValue = 60,
	Callback = function(v) State.Auto_FightThreshold = v end,
})

AutoSection:CreateSlider({
	Name = "Fish Until Food Count",
	Min = 10,
	Max = 200,
	CurrentValue = 50,
	Callback = function(v) State.Auto_FishFoodCount = v end,
})

AutoSection:CreateToggle({
	Name = "Auto Cook After Fishing",
	CurrentValue = true,
	Callback = function(v) State.Auto_CookAfterFish = v end,
})

AutoSection:CreateToggle({
	Name = "Auto Farm When Full HP",
	CurrentValue = true,
	Callback = function(v) State.Auto_FarmOnFullHp = v end,
})

AutoSection:CreateLabel({ Text = "Current Phase: Idle" })
local phaseLabel = Tabs.Auto:CreateSection("status")
local statusLabel = phaseLabel:CreateLabel({ Text = "Waiting..." })
local statusTextLabel = nil
pcall(function()
	statusTextLabel = statusLabel and statusLabel.TextLabel
end)

-- ═══════════════════════════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════════════════════════
local MiscSection = Tabs.Misc:CreateSection("miscellaneous")

MiscSection:CreateToggle({
	Name = "Anti AFK",
	CurrentValue = false,
	Callback = function(v) State.Misc_AntiAfk = v end,
})

MiscSection:CreateButton({
	Name = "Claim Daily Reward",
	Callback = function()
		claimDailyReward()
		IvoryHub.Notify({ Title = "Ivory", Content = "Daily reward claimed!", Type = "Success", Duration = 2 })
	end,
})

MiscSection:CreateButton({
	Name = "Refresh Profile Data",
	Callback = function()
		getProfile()
		IvoryHub.Notify({ Title = "Ivory", Content = "Profile data refreshed!", Type = "Info", Duration = 2 })
	end,
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB (always last)
-- ═══════════════════════════════════════════════════════════
local CreditsSection = Tabs["UI Settings"]:CreateSection("credits")
CreditsSection:CreateLabel({ Text = "Made by mommy Crow" })

local MenuSection = Tabs["UI Settings"]:CreateSection("menu settings")

MenuSection:CreateKeybind({
	Name = "Menu Keybind",
	CurrentKeybind = "RightShift",
	Callback = function(k) end,
})

MenuSection:CreateToggle({
	Name = "Keybind List",
	CurrentValue = false,
	Callback = function(v)
		if IvoryHub.KeybindList then IvoryHub.KeybindList.Visible = v end
	end,
})

MenuSection:CreateSlider({
	Name = "FPS Cap",
	Min = 30,
	Max = 240,
	CurrentValue = 60,
	Callback = function(v)
		pcall(function() setfpscap(v) end)
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
	Callback = function(v) State.Misc_AntiAfk = v end,
})

MenuSection:CreateToggle({
	Name = "Custom Cursor",
	CurrentValue = false,
	Callback = function(v) end,
})

MenuSection:CreateButton({
	Name = "Test Notification",
	Callback = function()
		IvoryHub.Notify({ Title = "Ivory", Content = "This is a test notification!", Type = "Info", Duration = 3 })
	end,
})

MenuSection:CreateDropdown({
	Name = "Notification Side",
	Values = { "Left", "Right" },
	CurrentOption = "Right",
	Callback = function(v) end,
})

MenuSection:CreateDropdown({
	Name = "DPI Scale",
	Values = { "50%", "75%", "100%", "125%", "150%", "200%" },
	CurrentOption = "100%",
	Callback = function(v) end,
})

MenuSection:CreateSlider({
	Name = "Corner Radius",
	Min = 0,
	Max = 20,
	CurrentValue = 8,
	Callback = function(v) end,
})

MenuSection:CreateButton({
	Name = "Unload",
	Callback = function()
		IvoryHub:Unload()
	end,
})

local ServerSection = Tabs["UI Settings"]:CreateSection("server")

ServerSection:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
		end)
	end,
})

ServerSection:CreateButton({
	Name = "Server Hop",
	Callback = function()
		pcall(function()
			local body = httpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
			local servers = HttpService:JSONDecode(body)
			if servers and servers.data then
				for _, server in ipairs(servers.data) do
					if server.id ~= game.JobId and server.playing < server.maxPlayers then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
						break
					end
				end
			end
		end)
	end,
})

local ThemesSection = Tabs["UI Settings"]:CreateSection("themes")

ThemesSection:CreateLabel({ Text = "Accent Color" }):CreateColorPicker("AccentColor", {
	Default = Color3.fromRGB(255, 255, 255),
	Callback = function(c)
		IvoryHub.Scheme.Accent = c
		IvoryHub:UpdateColorsUsingRegistry()
	end,
})

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
		IvoryHub.Notify({ Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 2 })
	end,
})

ConfigSection:CreateButton({
	Name = "Load Config",
	Callback = function()
		IvoryHub.Notify({ Title = "Ivory", Content = "Config loaded!", Type = "Success", Duration = 2 })
	end,
})

-- ═══════════════════════════════════════════════════════════
-- STATE LISTENERS
-- ═══════════════════════════════════════════════════════════
ProfileStateChanged.OnClientEvent:Connect(function(data)
	profile = data
end)

CombatStateChanged.OnClientEvent:Connect(function(data)
	combatState = data
end)

ActionStateChanged.OnClientEvent:Connect(function(data)
	actionState = data
end)

FarmingStateChanged.OnClientEvent:Connect(function(data)
	farmingState = data
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO FIGHT LOOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(1)
		if not State.Combat_AutoFight then continue end
		if State.Combat_MonsterId == "" then continue end
		if State.Auto_LoopEnabled then continue end

		local data = getProfile()
		if not data then continue end

		local inCombat = combatState and combatState.InCombat
		if not inCombat then
			startCombat(State.Combat_MonsterId, State.Combat_MonsterStyle)
		end

		if State.Combat_AutoEat then
			local hp, maxHp = getCombatHp()
			local pct = (hp / maxHp) * 100
			if pct <= State.Combat_EatThreshold then
				eatFood()
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO FISH LOOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(1)
		if not State.Fishing_AutoFish then continue end
		if State.Fishing_FishId == "" then continue end
		if State.Auto_LoopEnabled then continue end

		local isActive = actionState and actionState.IsActive and actionState.SkillType == "Fishing"
		if not isActive then
			startFishing(State.Fishing_FishId)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO COOK LOOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(1)
		if not State.Cooking_AutoCook then continue end
		if State.Cooking_RecipeId == "" then continue end
		if State.Auto_LoopEnabled then continue end

		local isActive = actionState and actionState.IsActive and actionState.SkillType == "Cooking"
		if not isActive then
			startCooking(State.Cooking_RecipeId)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO FARM LOOP
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(2)
		if not State.Farming_AutoFarm then continue end
		if State.Auto_LoopEnabled and not State.Auto_FarmOnFullHp then continue end

		local data = getProfile()
		if not data then continue end

		if State.Auto_LoopEnabled and State.Auto_FarmOnFullHp then
			local hp, maxHp = getCombatHp()
			local pct = (hp / maxHp) * 100
			if pct < 90 then continue end
		end

		local plots = nil
		if data.Farming and data.Farming.Plots then
			plots = data.Farming.Plots
		end

		if plots then
			local plotKey = State.Farming_Category .. "_" .. State.Farming_PlotIndex
			local plot = plots[plotKey]
			if plot and plot.CropId and (plot.ReadyAt and os.time() >= plot.ReadyAt) then
				farmingHarvest(State.Farming_Category, State.Farming_PlotIndex)
				task.wait(1)
			end

			if not plot or not plot.CropId then
				farmingPlant(State.Farming_Category, State.Farming_PlotIndex, State.Farming_CropId)
			end
		else
			farmingPlant(State.Farming_Category, State.Farming_PlotIndex, State.Farming_CropId)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- MASTER AUTO LOOP: Fight > Eat > Fish > Cook > Repeat
-- ═══════════════════════════════════════════════════════════
local autoLoopPhase = "idle"

task.spawn(function()
	while true do
		task.wait(1)
		if not State.Auto_LoopEnabled then
			autoLoopPhase = "idle"
			continue
		end

		local data = getProfile()
		if not data then continue end

		local hp, maxHp = getCombatHp()
		local hpPct = (hp / maxHp) * 100

		local cookedFood = 0
		if data.Inventory then
			for itemId, count in pairs(data.Inventory) do
				local itemInfo = require(ReplicatedStorage.Shared.modules.RecipesConfig).Items[itemId]
				if itemInfo and itemInfo.ConsumableEffect and itemInfo.HealsFor and itemInfo.HealsFor > 0 then
					cookedFood = cookedFood + count
				end
			end
		end

		if cookedFood <= 0 and autoLoopPhase == "fight" then
			autoLoopPhase = "fish"
		end

		if autoLoopPhase == "idle" then
			if cookedFood > 0 then
				autoLoopPhase = "fight"
			else
				autoLoopPhase = "fish"
			end
		end

		if autoLoopPhase == "fight" then
			if State.Auto_FarmOnFullHp and hpPct >= 90 then
				autoLoopPhase = "farm"
				continue
			end

			local inCombat = combatState and combatState.InCombat
			if not inCombat and State.Combat_MonsterId ~= "" then
				startCombat(State.Combat_MonsterId, State.Combat_MonsterStyle)
			end

			if State.Combat_AutoEat and hpPct <= State.Combat_EatThreshold then
				eatFood()
			end
		elseif autoLoopPhase == "farm" then
			local plots = nil
			if data.Farming and data.Farming.Plots then
				plots = data.Farming.Plots
			end

			local needsPlant = false
			if plots then
				local plotKey = State.Farming_Category .. "_" .. State.Farming_PlotIndex
				local plot = plots[plotKey]
				if plot and plot.CropId and plot.ReadyAt and os.time() >= plot.ReadyAt then
					farmingHarvest(State.Farming_Category, State.Farming_PlotIndex)
					task.wait(1)
					needsPlant = true
				elseif not plot or not plot.CropId then
					needsPlant = true
				end
			else
				needsPlant = true
			end

			if needsPlant and State.Farming_CropId ~= "" then
				farmingPlant(State.Farming_Category, State.Farming_PlotIndex, State.Farming_CropId)
			end

			autoLoopPhase = "fight"
		elseif autoLoopPhase == "fish" then
			if State.Fishing_FishId == "" then
				autoLoopPhase = "idle"
				continue
			end

			local fishingCount = 0
			if data.Inventory then
				for itemId, count in pairs(data.Inventory) do
					local itemInfo = require(ReplicatedStorage.Shared.modules.RecipesConfig).Items[itemId]
					if itemInfo and itemInfo.Category == "Fishing" then
						fishingCount = fishingCount + count
					end
				end
			end

			if fishingCount >= State.Auto_FishFoodCount then
				if State.Auto_CookAfterFish then
					autoLoopPhase = "cook"
				else
					autoLoopPhase = "fight"
				end
				continue
			end

			local isActive = actionState and actionState.IsActive and actionState.SkillType == "Fishing"
			if not isActive then
				startFishing(State.Fishing_FishId)
			end
		elseif autoLoopPhase == "cook" then
			if State.Cooking_RecipeId == "" then
				autoLoopPhase = "fight"
				continue
			end

			local isActive = actionState and actionState.IsActive and actionState.SkillType == "Cooking"
			if not isActive then
				startCooking(State.Cooking_RecipeId)
			end

			local remainingRaw = 0
			if data.Inventory then
				local recipeInfo = nil
				for _, recipe in ipairs(CookingConfig.Recipes or {}) do
					if recipe.Id == State.Cooking_RecipeId then
						recipeInfo = recipe
						break
					end
				end
				if recipeInfo and recipeInfo.Inputs then
					for _, input in ipairs(recipeInfo.Inputs) do
						remainingRaw = remainingRaw + (data.Inventory[input.ItemId] or 0)
					end
				end
			end

			if remainingRaw <= 0 then
				autoLoopPhase = "fight"
			end
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- ANTI AFK
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(60)
		if State.Misc_AntiAfk then
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				LocalPlayer.Idled:Connect(function()
					VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
					task.wait(0.1)
					VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
				end)
			end)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- STATUS UPDATE
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(1)
		local hp, maxHp = getCombatHp()
		local hpPct = math.floor((hp / maxHp) * 100)
		local phase = State.Auto_LoopEnabled and autoLoopPhase or "manual"
		local txt = "HP: " .. hpPct .. "% | Phase: " .. phase
		if statusTextLabel then
			statusTextLabel.Text = txt
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- FOOTER UPDATE
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while true do
		local footer = "v1.4 | Lobby/Game | " .. LocalPlayer.UserId
		pcall(function()
			Window:SetFooter(footer)
		end)
		task.wait(1)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- INITIALIZE
-- ═══════════════════════════════════════════════════════════
getProfile()

if not IvoryHub.Toggled then
	IvoryHub.Toggle()
end
print("[Ivory] Runeheaven - Loaded!")
