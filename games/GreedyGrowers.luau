local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Knit = require(RS.Packages.Knit)
local SeedConfig = require(RS.Shared.Info.SeedConfig)
local MutationConfig = require(RS.Shared.Info.MutationConfig)
local RebirthConfig = require(RS.Shared.Info.RebirthConfig)
local FertilizerConfig = require(RS.Shared.Info.FertilizerConfig)
local WeatherConfig = require(RS.Shared.Info.WeatherConfig)
local CustomEnum = require(RS.Shared.Info.CustomEnum)
local PetConfig = require(RS.Shared.Info.PetConfig)
local GearConfig = require(RS.Shared.Info.GearConfig)
local WormConfig = require(RS.Shared.Info.WormConfig)
local FarmersMarketConfig = require(RS.Shared.Info.FarmersMarketConfig)
local Constants = require(RS.Shared.Info.Constants)

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
local IvoryHub = loadstring(readfile(LIB_FILE))()

local LocalPlayer = Players.LocalPlayer

local Window = IvoryHub.CreateWindow({
    Name = "Ivory",
    Width = 720,
    Height = 600,
})

local SeedsTab = Window:CreateTab("Seeds")
local FarmTab = Window:CreateTab("Farm")
local ShopsTab = Window:CreateTab("Shops")
local PlayerTab = Window:CreateTab("Player")
local SettingsTab = Window:CreateTab("Settings")

getgenv().GreedyGrowers = {
    Window = Window,
    Tabs = {
        Seeds = SeedsTab,
        Farm = FarmTab,
        Shops = ShopsTab,
        Player = PlayerTab,
        Settings = SettingsTab,
    },
}

-- Discord Button
local DiscordSection = SeedsTab:CreateSection("discord")
DiscordSection:CreateButton({
    Name = "Join Discord For Dupe",
    Callback = function()
        pcall(function()
            setclipboard("https://discord.gg/bac")
        end)
        IvoryHub.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 })
    end,
})

-- SEEDS TAB: Auto Buy Seeds
SeedsTab:CreateSection("Auto Buy Seeds")

local seedEntries = {}
for key, data in pairs(SeedConfig.Seeds) do
    table.insert(seedEntries, {key = key, name = data.displayName, cost = data.plantCost})
end
table.sort(seedEntries, function(a, b) return a.cost < b.cost end)

local seedNames = {}
local seedKeysByName = {}
for _, entry in ipairs(seedEntries) do
    local label = entry.name .. " ($" .. tostring(entry.cost) .. ")"
    table.insert(seedNames, label)
    seedKeysByName[label] = entry.key
end

local selectedSeeds = {}
local onlyMutated = false
local autoBuyEnabled = false

SeedsTab:CreateDropdown({
    Name = "Seeds to Buy",
    Values = seedNames,
    CurrentOption = seedNames[1] or "",
    Callback = function(selected)
        selectedSeeds = {}
        local key = seedKeysByName[selected]
        if key then
            selectedSeeds[key] = true
        end
    end,
})

SeedsTab:CreateToggle({
    Name = "Only Mutated Seeds",
    CurrentValue = false,
    Flag = "GG_OnlyMutated",
    Callback = function(value)
        onlyMutated = value
    end,
})

SeedsTab:CreateToggle({
    Name = "Auto Buy Seeds",
    CurrentValue = false,
    Flag = "GG_AutoBuyToggle",
    Callback = function(value)
        autoBuyEnabled = value
    end,
})

local function hasMutation(spawnData)
    if not spawnData then return false end
    local mut = spawnData.mutation
    if not mut then return false end
    if type(mut) == "table" then
        return next(mut) ~= nil
    end
    if type(mut) == "string" then
        return #mut > 0
    end
    return true
end

local function matchesAutoBuy(spawnData)
    if not spawnData then return false end
    if not autoBuyEnabled then return false end
    local key = spawnData.seedKey
    if not key then return false end
    if not selectedSeeds[key] then return false end
    if onlyMutated and not hasMutation(spawnData) then return false end
    return true
end

task.spawn(function()
    local SeedConveyorService = Knit.GetService("SeedConveyorService")
    SeedConveyorService.SeedSpawned:Connect(function(spawnData)
        if not matchesAutoBuy(spawnData) then return end
        local ok, result = SeedConveyorService:RequestPurchase(spawnData.spawnId):await()
        if ok and result then
            warn("[Greedy Growers] Auto-bought:", spawnData.seedKey)
        end
    end)
end)

-- FARM TAB: Auto Plant & Auto Harvest

FarmTab:CreateSection("Auto Plant")

local plantSeeds = {}
for key, data in pairs(SeedConfig.Seeds) do
    table.insert(plantSeeds, {key = key, name = data.displayName, cost = data.plantCost})
end
table.sort(plantSeeds, function(a, b) return a.cost < b.cost end)

local plantSeedNames = {}
local plantSeedKeysByName = {}
for _, entry in ipairs(plantSeeds) do
    local label = entry.name .. " ($" .. tostring(entry.cost) .. ")"
    table.insert(plantSeedNames, label)
    plantSeedKeysByName[label] = entry.key
end

local selectedPlantSeeds = {}
local selectedFertilizer = "None"
local weatherFilterEnabled = false
local selectedWeather = "Misty"
local autoPlantEnabled = false
local plantInterval = 3

FarmTab:CreateDropdown({
    Name = "Seed to Plant",
    Values = plantSeedNames,
    CurrentOption = plantSeedNames[1] or "",
    Callback = function(selected)
        selectedPlantSeeds = {}
        local key = plantSeedKeysByName[selected]
        if key then
            selectedPlantSeeds[key] = true
        end
    end,
})

local fertNames = {}
for _, fertKey in ipairs(FertilizerConfig.Order) do
    local fert = FertilizerConfig.Fertilizers[fertKey]
    if fert then
        table.insert(fertNames, fert.displayName)
    end
end

FarmTab:CreateDropdown({
    Name = "Fertilizer",
    Options = fertNames,
    CurrentOption = "None",
    Flag = "GG_PlantFertilizer",
    Callback = function(value)
        for fertKey, fert in pairs(FertilizerConfig.Fertilizers) do
            if fert.displayName == value then
                selectedFertilizer = fertKey
                break
            end
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Only Plant When Weather",
    CurrentValue = false,
    Flag = "GG_WeatherFilter",
    Callback = function(value)
        weatherFilterEnabled = value
    end,
})

local weatherNames = {}
for _, wKey in ipairs(WeatherConfig.Order) do
    local w = WeatherConfig.Weathers[wKey]
    if w then
        table.insert(weatherNames, w.displayName)
    end
end

FarmTab:CreateDropdown({
    Name = "Weather Condition",
    Options = weatherNames,
    CurrentOption = "Misty",
    Flag = "GG_PlantWeather",
    Callback = function(value)
        for wKey, w in pairs(WeatherConfig.Weathers) do
            if w.displayName == value then
                selectedWeather = wKey
                break
            end
        end
    end,
})

FarmTab:CreateSlider({
    Name = "Planting Cooldown",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 3,
    Suffix = "s",
    Flag = "GG_PlantInterval",
    Callback = function(value)
        plantInterval = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Plant",
    CurrentValue = false,
    Flag = "GG_AutoPlant",
    Callback = function(value)
        autoPlantEnabled = value
    end,
})

local function getCurrentWeatherKey()
    local cw = RS:FindFirstChild("CurrentWeather")
    if cw and cw:IsA("StringValue") and cw.Value ~= "" then
        return cw.Value
    end
    return nil
end

local function getDataClient()
    local dc = getgenv().GreedyGrowers._dataClient
    if not dc then
        local ok, d = pcall(function() return Knit.GetController("DataClient") end)
        if ok and d then
            getgenv().GreedyGrowers._dataClient = d
            dc = d
        end
    end
    return dc
end

local function getHotbarSlotForSeed(seedKey)
    local dc = getDataClient()
    if dc and dc.currentData and dc.currentData.Inventory then
        local hotbar = dc.currentData.Inventory.Hotbar
        if hotbar then
            for slotStr, entry in pairs(hotbar) do
                if type(entry) == "table" and entry.seedType == seedKey then
                    return tonumber(slotStr)
                end
            end
        end
    end
    return nil
end

local function hasSeedInInventory(seedKey)
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("IsSeed") and tool:GetAttribute("SeedType") == seedKey then
                return true
            end
        end
    end
    return getHotbarSlotForSeed(seedKey) ~= nil
end

local function equipSeedTool(seedKey)
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("IsSeed") and tool:GetAttribute("SeedType") == seedKey then
                return true
            end
        end
    end

    local slot = getHotbarSlotForSeed(seedKey)
    if not slot then return false end

    local ok, ToolService = pcall(function() return Knit.GetService("ToolService") end)
    if not ok or not ToolService then return false end

    ToolService.ToggleEquip:Fire(true, slot)

    for _ = 1, 20 do
        task.wait(0.1)
        local c = LocalPlayer.Character
        if c then
            for _, tool in ipairs(c:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("IsSeed") and tool:GetAttribute("SeedType") == seedKey then
                    return true
                end
            end
        end
    end
    return false
end

task.spawn(function()
    local PlantRoundService = Knit.GetService("PlantRoundService")
    while true do
        task.wait(plantInterval)
        if not autoPlantEnabled then continue end
        if not next(selectedPlantSeeds) then continue end

        if weatherFilterEnabled then
            local current = getCurrentWeatherKey()
            if current ~= selectedWeather then continue end
        end

        local seedPool = {}
        for seedKey in pairs(selectedPlantSeeds) do
            if hasSeedInInventory(seedKey) then
                table.insert(seedPool, seedKey)
            end
        end

        if #seedPool == 0 then continue end

        local seedToPlant = seedPool[math.random(1, #seedPool)]
        local equipped = equipSeedTool(seedToPlant)
        if not equipped then
            warn("[Greedy Growers] Failed to equip seed:", seedToPlant)
            continue
        end

        pcall(function()
            PlantRoundService:StartRound(seedToPlant, selectedFertilizer)
        end)

        warn("[Greedy Growers] Auto-planted:", seedToPlant, "with", selectedFertilizer)
    end
end)

FarmTab:CreateSection("Auto Harvest")

local autoHarvestEnabled = false
local harvestMultiplier = 1.0
local collectDeadEnabled = false

local roundStartTime = nil
local isRoundActive = false
local justStopped = false

FarmTab:CreateInput({
    Name = "Harvest at Multiplier",
    PlaceholderText = "e.g. 1.0",
    Flag = "GG_HarvestMult",
    Callback = function(text)
        local val = tonumber(text)
        if val and val >= 0.5 and val <= 50 then
            harvestMultiplier = val
        end
    end,
})

FarmTab:CreateToggle({
    Name = "Collect Dead Trees",
    CurrentValue = false,
    Flag = "GG_CollectDead",
    Callback = function(value)
        collectDeadEnabled = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Harvest",
    CurrentValue = false,
    Flag = "GG_AutoHarvest",
    Callback = function(value)
        autoHarvestEnabled = value
    end,
})

local autoHarvestFruitsEnabled = false
local selectedHarvestFruit = nil
local autoCollectAllFruitsEnabled = false

local fruitEntries = {}
for key, data in pairs(SeedConfig.Seeds) do
    if type(data) == "table" and data.sellPrice then
        table.insert(fruitEntries, {key = key, name = data.displayName, sellPrice = data.sellPrice})
    end
end
table.sort(fruitEntries, function(a, b) return a.sellPrice < b.sellPrice end)

local fruitNames = {}
local fruitKeysByName = {}
for _, entry in ipairs(fruitEntries) do
    local label = entry.name .. " ($" .. entry.sellPrice .. ")"
    table.insert(fruitNames, label)
    fruitKeysByName[label] = entry.key
end

FarmTab:CreateDropdown({
    Name = "Fruit to Harvest",
    Options = fruitNames,
    CurrentOption = fruitNames[1] or "",
    Flag = "GG_HarvestFruitType",
    Callback = function(value)
        selectedHarvestFruit = fruitKeysByName[value]
    end,
})

selectedHarvestFruit = fruitKeysByName[fruitNames[1]]

FarmTab:CreateToggle({
    Name = "Auto Harvest Fruits",
    CurrentValue = false,
    Flag = "GG_AutoHarvestFruits",
    Callback = function(value)
        autoHarvestFruitsEnabled = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Collect All Fruits",
    CurrentValue = false,
    Flag = "GG_AutoCollectAllFruits",
    Callback = function(value)
        autoCollectAllFruitsEnabled = value
    end,
})

task.spawn(function()
    local PlantRoundService = Knit.GetService("PlantRoundService")
    local PPS = Knit.GetService("PlayerPlotService")

    PlantRoundService.RoundStartedAll:Connect(function(userId, position, ...)
        if userId == LocalPlayer.UserId then
            roundStartTime = os.clock()
            isRoundActive = true
            justStopped = false
        end
    end)

    PlantRoundService.PlantStoppedAll:Connect(function(userId, ...)
        if userId == LocalPlayer.UserId then
            isRoundActive = false
            roundStartTime = nil
            justStopped = true
            if collectDeadEnabled then
                task.delay(0.5, function()
                    pcall(function()
                        PlantRoundService:CollectDeadTree()
                    end)
                end)
            end
        end
    end)

    while true do
        task.wait(0.5)

        if autoHarvestEnabled and isRoundActive and roundStartTime then
            local elapsed = os.clock() - roundStartTime
            local currentMult = math.max(0, math.floor((math.exp(0.28 * elapsed) - 1) * 100) / 100)

            if currentMult >= harvestMultiplier then
                pcall(function()
                    PlantRoundService:StopPlant()
                end)
                warn("[Greedy Growers] Harvested at multiplier:", currentMult)
            end
        end

        if autoHarvestFruitsEnabled and selectedHarvestFruit then
            local ok, trees = PPS:GetPlotTrees():await()
            if ok and trees then
                for _, treeData in pairs(trees) do
                    if type(treeData) == "table" and treeData.seedType == selectedHarvestFruit and treeData.fruitsReady then
                        pcall(function()
                            PPS:CollectAllFruits()
                        end)
                        break
                    end
                end
            end
        end

        if autoCollectAllFruitsEnabled then
            pcall(function()
                PPS:CollectAllFruits()
            end)
        end
    end
end)

-- FARM TAB: Auto Sell

FarmTab:CreateSection("Auto Sell")

local autoSellHandEnabled = false
local autoSellCapacityEnabled = false
local autoSellAllEnabled = false
local sellAllDelay = 5

FarmTab:CreateToggle({
    Name = "Sell Fruit Held in Hand",
    CurrentValue = false,
    Flag = "GG_SellHand",
    Callback = function(value)
        autoSellHandEnabled = value
    end,
})

FarmTab:CreateToggle({
    Name = "Sell at Max Capacity",
    CurrentValue = false,
    Flag = "GG_SellCapacity",
    Callback = function(value)
        autoSellCapacityEnabled = value
    end,
})

FarmTab:CreateSlider({
    Name = "Sell Delay",
    Range = {1, 60},
    Increment = 1,
    CurrentValue = 5,
    Suffix = "s",
    Flag = "GG_SellDelay",
    Callback = function(value)
        sellAllDelay = value
    end,
})

FarmTab:CreateToggle({
    Name = "Auto Sell All",
    CurrentValue = false,
    Flag = "GG_SellAll",
    Callback = function(value)
        autoSellAllEnabled = value
    end,
})

task.spawn(function()
    local SellFruitsService = Knit.GetService("SellFruitsService")
    local SellStandService = Knit.GetService("SellStandService")
    local lastSellAll = 0

    while true do
        task.wait(0.5)

        if autoSellHandEnabled then
            local char = LocalPlayer.Character
            if char then
                for _, tool in ipairs(char:GetChildren()) do
                    if tool:IsA("Tool") and tool:GetAttribute("IsFruit") then
                        pcall(function()
                            SellFruitsService:SellFruit()
                        end)
                        break
                    end
                end
            end
        end

        if autoSellCapacityEnabled then
            local dc = getDataClient()
            if dc and dc.currentData and dc.currentData.Inventory then
                local storage = dc.currentData.Inventory.Storage
                local count = 0
                if storage then
                    for _ in pairs(storage) do count = count + 1 end
                end
                if count >= Constants.STORAGE_MAX_SIZE then
                    pcall(function()
                        SellStandService:SellAll()
                    end)
                    warn("[Greedy Growers] Sold all - storage full (" .. count .. "/" .. Constants.STORAGE_MAX_SIZE .. ")")
                    task.wait(2)
                end
            end
        end

        if autoSellAllEnabled then
            local now = os.clock()
            if now - lastSellAll >= sellAllDelay then
                lastSellAll = now
                pcall(function()
                    SellStandService:SellAll()
                end)
            end
        end
    end
end)

-- PLAYER TAB
local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

PlayerTab:CreateSection("Character")

local baseWalkSpeed = 16
local baseJumpPower = 50

PlayerTab:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    CurrentValue = 16,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then
            baseWalkSpeed = value
            hum.WalkSpeed = value
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Jump Power",
    Min = 50,
    Max = 200,
    CurrentValue = 50,
    Callback = function(value)
        local hum = getHumanoid()
        if hum then
            baseJumpPower = value
            hum.JumpPower = value
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(value)
        getgenv().GreedyGrowers.noclip = value
    end,
})

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        hum.WalkSpeed = baseWalkSpeed
        hum.JumpPower = baseJumpPower
    end
end)

PlayerTab:CreateSection("Visual")

local fullbrightEnabled = false

PlayerTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(value)
        fullbrightEnabled = value
        local lighting = game:GetService("Lighting")
        if value then
            lighting.Brightness = 2
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
            lighting.GlobalShadows = false
        else
            lighting.Brightness = 1
            lighting.ClockTime = 12
            lighting.FogEnd = 10000
            lighting.GlobalShadows = true
        end
    end,
})

local espEnabled = false
local espObjects = {}

local function createEsp(player)
    if espObjects[player] then return end
    if player == LocalPlayer then return end

    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GG_ESP"
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 1000
    billboard.Adornee = hrp
    billboard.Parent = player.Character

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    nameLabel.Parent = billboard

    local healthLabel = Instance.new("TextLabel")
    healthLabel.Size = UDim2.new(1, 0, 0.5, 0)
    healthLabel.Position = UDim2.new(0, 0, 0.5, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font = Enum.Font.Gotham
    healthLabel.TextSize = 12
    healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
    healthLabel.TextStrokeTransparency = 0
    healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    healthLabel.Text = ""
    healthLabel.Parent = billboard

    espObjects[player] = {billboard = billboard, nameLabel = nameLabel, healthLabel = healthLabel}
end

local function removeEsp(player)
    if espObjects[player] then
        espObjects[player].billboard:Destroy()
        espObjects[player] = nil
    end
end

PlayerTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(value)
        espEnabled = value
        if value then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    createEsp(player)
                end
            end
        else
            for player, _ in pairs(espObjects) do
                removeEsp(player)
            end
        end
    end,
})

Players.PlayerRemoving:Connect(removeEsp)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if espEnabled and player ~= LocalPlayer then
            task.wait(1)
            createEsp(player)
        end
    end)
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        if espEnabled then
            for player, refs in pairs(espObjects) do
                if player and player.Character then
                    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if humanoid and hrp then
                        refs.billboard.Adornee = hrp
                        local health = math.floor(humanoid.Health)
                        local maxHealth = math.floor(humanoid.MaxHealth)
                        refs.nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                        refs.healthLabel.Text = health .. "/" .. maxHealth
                        refs.healthLabel.TextColor3 = humanoid.Health > 0 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 80, 80)
                    end
                end
            end
        end
    end
end)

PlayerTab:CreateSection("Rebirth")

local autoRebirthEnabled = false

PlayerTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "GG_AutoRebirth",
    Callback = function(value)
        autoRebirthEnabled = value
    end,
})

task.spawn(function()
    local RebirthService = Knit.GetService("RebirthService")
    while task.wait(2) do
        if not autoRebirthEnabled then continue end

        local currentData = getDataClient()
        if currentData and currentData.currentData then
            local data = currentData.currentData
            local rebirth = data.Rebirth or 0
            local nextRebirth = RebirthConfig.GetNext(rebirth)
            if nextRebirth then
                local coins = 0
                if data.Currency then
                    coins = data.Currency[CustomEnum.CURRENCIES.COINS] or 0
                end
                if coins >= nextRebirth.cost then
                    local ok, err = RebirthService:DoRebirth():await()
                    if ok then
                        warn("[Greedy Growers] Rebirth completed! Level:", nextRebirth.level)
                    end
                end
            end
        end
    end
end)

PlayerTab:CreateSection("Auto Claim")

local autoClaimGroup = false
local autoClaimIndex = false

PlayerTab:CreateToggle({
    Name = "Auto Claim Group Reward",
    CurrentValue = false,
    Flag = "GG_AutoClaimGroup",
    Callback = function(value)
        autoClaimGroup = value
    end,
})

PlayerTab:CreateToggle({
    Name = "Auto Claim Index Reward",
    CurrentValue = false,
    Flag = "GG_AutoClaimIndex",
    Callback = function(value)
        autoClaimIndex = value
    end,
})

task.spawn(function()
    local GroupRewardService = Knit.GetService("GroupRewardService")
    local IndexService = Knit.GetService("IndexService")
    while task.wait(5) do
        if autoClaimGroup then
            pcall(function()
                GroupRewardService:Claim()
            end)
        end
        if autoClaimIndex then
            local indexes = CustomEnum.INDEXES
            for _, indexType in pairs(indexes) do
                pcall(function()
                    IndexService.ClaimIndexReward:Fire(indexType)
                end)
            end
        end
    end
end)

PlayerTab:CreateSection("Codes")

local autoClaimCodes = false
local claimedCodes = {}
local KNOWN_CODES = {}

PlayerTab:CreateInput({
    Name = "Enter Code",
    PlaceholderText = "Type a code...",
    Flag = "GG_CodeInput",
    Callback = function(text)
        if #text == 0 then return end
        task.spawn(function()
            local CodeService = Knit.GetService("CodeService")
            local ok, result = CodeService:ClaimCode(text):await()
            if ok and result then
                if result.success then
                    claimedCodes[text] = true
                    warn("[Greedy Growers] Code claimed:", text)
                else
                    warn("[Greedy Growers] Code failed:", result.msg or "unknown error")
                end
            end
        end)
    end,
})

PlayerTab:CreateToggle({
    Name = "Auto Claim New Codes",
    CurrentValue = false,
    Flag = "GG_AutoClaimCodes",
    Callback = function(value)
        autoClaimCodes = value
    end,
})

task.spawn(function()
    local CodeService = Knit.GetService("CodeService")
    while task.wait(30) do
        if not autoClaimCodes then continue end
        for _, code in ipairs(KNOWN_CODES) do
            if not claimedCodes[code] then
                local ok, result = CodeService:ClaimCode(code):await()
                if ok and result and result.success then
                    claimedCodes[code] = true
                    warn("[Greedy Growers] Auto-claimed code:", code)
                end
            end
        end
    end
end)

-- SHOPS TAB

-- Pet Shop Section
ShopsTab:CreateSection("Pet Shop")

local autoBuyEggs = false
local selectedEgg = nil

local eggEntries = {}
for key, data in pairs(PetConfig.Eggs) do
    if type(data) == "table" and not data.noNormalBuy then
        table.insert(eggEntries, {key = key, name = data.displayName, price = data.price})
    end
end
table.sort(eggEntries, function(a, b) return a.price < b.price end)

local eggNames = {}
local eggKeysByName = {}
for _, entry in ipairs(eggEntries) do
    local label = entry.name .. " (" .. entry.price .. " tickets)"
    table.insert(eggNames, label)
    eggKeysByName[label] = entry.key
end

ShopsTab:CreateDropdown({
    Name = "Select Egg",
    Options = eggNames,
    CurrentOption = eggNames[1] or "",
    Flag = "GG_SelectEgg",
    Callback = function(value)
        selectedEgg = eggKeysByName[value]
    end,
})

selectedEgg = eggKeysByName[eggNames[1]]

ShopsTab:CreateToggle({
    Name = "Auto Buy Eggs",
    CurrentValue = false,
    Flag = "GG_AutoBuyEggs",
    Callback = function(value)
        autoBuyEggs = value
    end,
})

task.spawn(function()
    local PetsService = Knit.GetService("PetsService")
    while task.wait(3) do
        if not autoBuyEggs or not selectedEgg then continue end
        pcall(function()
            PetsService:BuyEgg(selectedEgg)
        end)
    end
end)

-- Gear Shop Section
ShopsTab:CreateSection("Gear Shop")

local autoBuyGears = false
local selectedGear = nil

local gearEntries = {}
for key, data in pairs(GearConfig.Items) do
    if type(data) == "table" and not data.gearShopExclude then
        table.insert(gearEntries, {key = key, name = data.displayName, price = data.price})
    end
end
table.sort(gearEntries, function(a, b) return a.price < b.price end)

local gearNames = {}
local gearKeysByName = {}
for _, entry in ipairs(gearEntries) do
    local label = entry.name .. " ($" .. entry.price .. ")"
    table.insert(gearNames, label)
    gearKeysByName[label] = entry.key
end

ShopsTab:CreateDropdown({
    Name = "Select Gear",
    Options = gearNames,
    CurrentOption = gearNames[1] or "",
    Flag = "GG_SelectGear",
    Callback = function(value)
        selectedGear = gearKeysByName[value]
    end,
})

selectedGear = gearKeysByName[gearNames[1]]

ShopsTab:CreateToggle({
    Name = "Auto Buy Gears",
    CurrentValue = false,
    Flag = "GG_AutoBuyGears",
    Callback = function(value)
        autoBuyGears = value
    end,
})

task.spawn(function()
    local GearShopService = Knit.GetService("GearShopService")
    while task.wait(3) do
        if not autoBuyGears or not selectedGear then continue end
        pcall(function()
            GearShopService:BuyGear(selectedGear)
        end)
    end
end)

-- Farmer's Market Section
ShopsTab:CreateSection("Farmer's Market")

local autoGiveMarketFruits = false
local autoClaimMarketTickets = false
local selectedMarketRow = nil

ShopsTab:CreateToggle({
    Name = "Auto Give Market Fruits",
    CurrentValue = false,
    Flag = "GG_AutoGiveFruits",
    Callback = function(value)
        autoGiveMarketFruits = value
    end,
})

ShopsTab:CreateToggle({
    Name = "Auto Claim Market Tickets",
    CurrentValue = false,
    Flag = "GG_AutoClaimTickets",
    Callback = function(value)
        autoClaimMarketTickets = value
    end,
})

local rowEntries = {}
for idx, rowData in ipairs(FarmersMarketConfig.Rows) do
    if type(rowData) == "table" then
        local kind = rowData.kind or "regular"
        local difficulty = rowData.difficulty or "easy"
        local reward = rowData.reward or 0
        table.insert(rowEntries, {idx = idx, label = kind .. " " .. difficulty, reward = reward})
    end
end
table.sort(rowEntries, function(a, b) return a.reward < b.reward end)

local rowNames = {}
local rowIdxByName = {}
for _, entry in ipairs(rowEntries) do
    local label = entry.label .. " (" .. entry.reward .. " tickets)"
    table.insert(rowNames, label)
    rowIdxByName[label] = entry.idx
end

ShopsTab:CreateDropdown({
    Name = "Ticket Row",
    Options = rowNames,
    CurrentOption = rowNames[1] or "",
    Flag = "GG_MarketRow",
    Callback = function(value)
        selectedMarketRow = rowIdxByName[value]
    end,
})

selectedMarketRow = rowIdxByName[rowNames[1]]

task.spawn(function()
    local FarmersMarketService = Knit.GetService("FarmersMarketService")
    while task.wait(5) do
        if autoGiveMarketFruits then
            pcall(function()
                FarmersMarketService:GiveFruit()
            end)
        end
        if autoClaimMarketTickets then
            pcall(function()
                local ok, offers = FarmersMarketService:GetOffers():await()
                if ok and offers and offers.claimed then
                    for rowStr, claimed in pairs(offers.claimed) do
                        if not claimed then
                            local rowIdx = tonumber(rowStr)
                            if rowIdx then
                                pcall(function()
                                    FarmersMarketService:ClaimRow(rowIdx)
                                end)
                            end
                        end
                    end
                end
            end)
        end
    end
end)

-- SETTINGS TAB

-- Credits Section
local CreditsSection = SettingsTab:CreateSection("Credits")
local CreditLabel = CreditsSection:CreateLabel({ Text = "Made by mommy Crow" })

-- Menu Settings Section
local MenuSection = SettingsTab:CreateSection("menu settings")

MenuSection:CreateKeybind({
    Name = "Menu Keybind",
    CurrentKeybind = "RightShift",
    Callback = function(k) end,
})

MenuSection:CreateToggle({
    Name = "Keybind List",
    CurrentValue = false,
    Callback = function(v)
        IvoryHub.KeybindList.Visible = v
    end,
})

MenuSection:CreateSlider({
    Name = "FPS Cap",
    Min = 30,
    Max = 240,
    CurrentValue = 60,
    Callback = function(v)
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
    Callback = function(value)
        if value then
            local VirtualUser = game:GetService("VirtualUser")
            LocalPlayer.Idled:Connect(function()
                VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                task.wait(0.1)
                VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            end)
        end
    end,
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

-- Server Section
local ServerSection = SettingsTab:CreateSection("server")

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
local ThemesSection = SettingsTab:CreateSection("themes")

ThemesSection:CreateLabel({ Text = "Accent Color" }):CreateColorPicker("AccentColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(c)
        IvoryHub.Scheme.Accent = c
        IvoryHub:UpdateColorsUsingRegistry()
    end,
})

-- Configuration Section
local ConfigSection = SettingsTab:CreateSection("configuration")

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

-- Worm Shop Section
ShopsTab:CreateSection("Worm Shop")

local autoBuyWorms = false

ShopsTab:CreateToggle({
    Name = "Auto Buy Worms",
    CurrentValue = false,
    Flag = "GG_AutoBuyWorms",
    Callback = function(value)
        autoBuyWorms = value
    end,
})

task.spawn(function()
    local WormShopService = Knit.GetService("WormShopService")
    while task.wait(5) do
        if not autoBuyWorms then continue end
        pcall(function()
            WormShopService:BuyCanOfWorms()
        end)
    end
end)

-- ===============================================================
-- NOCLIP LOOP
-- ===============================================================
task.spawn(function()
    local RunService = game:GetService("RunService")
    local noclipConn
    while true do
        if getgenv().GreedyGrowers.noclip then
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
-- FOOTER UPDATE
-- ===============================================================
task.spawn(function()
    while true do
        local footer = "v1.4 | GreedyGrowers | " .. LocalPlayer.UserId
        pcall(function()
            Window:SetFooter(footer)
        end)
        task.wait(1)
    end
end)

-- ===============================================================
-- INITIALIZE
-- ===============================================================
if not IvoryHub.Toggled then
    IvoryHub.Toggle()
end
print("[Ivory] Greedy Growers - Loaded!")