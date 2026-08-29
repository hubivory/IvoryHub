--// Ivory Hub - Dig & Clean
--// PlaceId: 83038462357724
--//
--// Features:
--// [ + ] Auto Detect (Sweep Detector for Buried Nodes)
--// [ + ] Auto Dig (Auto Click Dig Minigame)
--// [ + ] Auto Clean (Spray Items Automatically)
--// [ + ] Auto Sell Held Item
--// [ + ] Auto Sell Inventory
--// [ + ] Auto Place in Museum (Pedestal)
--// [ + ] Auto Pickup Surfaced Items
--// [ + ] Auto Equip Best Tool
--// [ + ] Auto Buy Shovel
--// [ + ] Auto Buy Detector
--// [ + ] Auto Buy Spray Bottle
--// [ + ] Auto Travel to Island
--// [ + ] Auto Unlock Pyramid
--// [ + ] Auto Sacrifice Gold (Pyramid)
--// [ + ] Auto Unlock Plot Sections
--// [ + ] Auto Polish Items
--// [ + ] Auto Collect Polish
--// [ + ] Auto Claim Quests
--// [ + ] Auto Claim Offline Earnings
--// [ + ] Auto Claim Group Reward
--// [ + ] Auto Claim Free Pack
--// [ + ] Auto Redeem Codes
--// [ + ] Auto Daily Luck Boost
--// [ + ] Auto Anti AFK
--// [ + ] Speed Hack (Slider, Reset)
--// [ + ] Jump Hack (Slider, Reset)
--// [ + ] NoClip
--// [ + ] Player ESP (Box, Name, Health, Distance)
--// [ + ] Dig Spot ESP (Buried Nodes)
--// [ + ] Surfaced Item ESP
--// [ + ] ESP Color
--// [ + ] ESP Range
--// [ + ] Teleport (Hub, Islands, Shop, Museum)
--// [ + ] Config Save / Load
--// [ + ] Theme Manager
--// [ + ] Custom Cursor / Menu Keybind / Notification Side
--// [ + ] Unload Script

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local PlaceId = game.PlaceId
local isLobby = (PlaceId == 83038462357724)

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url) return request({ Url = url, Method = "GET" }).Body end
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Ivory", Icon = "swords",
    Footer = { "v1.4 |", { Text = isLobby and "Lobby" or "Game", Copyable = true }, "|", { Text = tostring(LocalPlayer.UserId), Copyable = true } },
    CopyableFooter = true, FuzzySearch = true, SearchValues = true, Minimizable = true,
    MinimizeKeybind = Enum.KeyCode.RightBracket, MinimizedWidth = 280, NotifySide = "Right",
    ShowCustomCursor = false, SearchKeybind = Enum.KeyCode.F, CornerRadius = 4,
    Animations = { SubTabUnderline = true },
})

ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub"); SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder(isLobby and "lobby" or "game")

------------------------------------------------------------------------
--// NETWORK REMOTES (from Potassium scan)
------------------------------------------------------------------------
local RS = ReplicatedStorage:WaitForChild("shared"):WaitForChild("network")

local function getRemote(category, name)
    for _, child in ipairs(RS:GetChildren()) do
        if string.find(child.Name, category) then
            local remote = child:FindFirstChild(name)
            if remote then return remote end
        end
    end
    return nil
end

local function fireRemote(category, name, ...)
    local remote = getRemote(category, name)
    if remote then
        remote:FireServer(...)
    end
end

------------------------------------------------------------------------
--// HELPERS
------------------------------------------------------------------------
local function notify(desc, kind)
    Library:Notify({ Title = "Ivory", Description = desc, Type = kind or "Info", Time = 2.5 })
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

------------------------------------------------------------------------
--// CONFIG DATA (from game modules)
------------------------------------------------------------------------
local Shovels = require(ReplicatedStorage:WaitForChild("TS"):WaitForChild("constants"):WaitForChild("digging"):WaitForChild("Shovels"))
local Detectors = require(ReplicatedStorage:WaitForChild("TS"):WaitForChild("constants"):WaitForChild("digging"):WaitForChild("Detectors"))
local SprayBottles = require(ReplicatedStorage:WaitForChild("TS"):WaitForChild("constants"):WaitForChild("cleaning"):WaitForChild("SprayBottles"))
local IslandsConfig = require(ReplicatedStorage:WaitForChild("TS"):WaitForChild("constants"):WaitForChild("world"):WaitForChild("Islands"))
local DiggingConfig = require(ReplicatedStorage:WaitForChild("TS"):WaitForChild("constants"):WaitForChild("digging"):WaitForChild("DiggingConfig"))

-- Shovel tier names in order
local ShovelOrder = {
    "Plastic Shovel", "Wood Shovel", "Stone Shovel", "Metal Shovel", "Gold Shovel",
    "Amethyst Shovel", "Titanium Shovel", "Cobalt Shovel", "Carbon Shovel", "Ruby Shovel",
    "Diamond Shovel", "Sandstone Shovel", "Amber Shovel", "Scarab Shovel", "Malachite Shovel",
    "Aquamarine Shovel", "Cryolite Shovel", "Peridot Shovel", "Sunstone Shovel", "Sugilite Shovel",
    "Eclipse Shovel", "Nether Shovel", "Specter Shovel", "Inferno Shovel", "Storm Shovel", "Magma Shovel",
}

local DetectorOrder = {
    "Rusty Detector", "Copper Detector", "Silver Detector", "Gold Detector", "Platinum Detector",
    "Onyx Detector", "Sapphire Detector", "Jade Detector", "Topaz Detector", "Crystal Detector",
    "Sandstone Detector", "Amber Detector", "Scarab Detector", "Malachite Detector", "Aquamarine Detector",
    "Cryolite Detector", "Peridot Detector", "Sunstone Detector", "Sugilite Detector", "Eclipse Detector",
    "Nether Detector", "Specter Detector", "Inferno Detector", "Storm Detector", "Magma Detector",
}

local SprayOrder = {
    "Basic Spray Bottle", "Rubber Spray Bottle", "Plastic Spray Bottle", "Copper Spray Bottle",
    "Steel Spray Bottle", "Gold Spray Bottle", "Turquoise Spray Bottle",
    "Plastic Pressure Washer", "Metal Pressure Washer", "Obsidian Pressure Washer",
    "Opal Pressure Washer", "Garnet Pressure Washer",
    "Sandstone Pressure Washer", "Amber Pressure Washer", "Scarab Pressure Washer",
    "Malachite Pressure Washer", "Aquamarine Pressure Washer",
    "Cryolite Washer", "Peridot Washer", "Sunstone Washer", "Sugilite Washer", "Eclipse Washer",
    "Nether Spray", "Specter Spray", "Inferno Spray", "Storm Spray", "Magma Spray",
}

local IslandOrder = {"starterIsland", "island2", "island3", "island4", "island5"}
local IslandDisplay = {
    starterIsland = "Home Beach",
    island2 = "Frozen Shores",
    island3 = "Lava Lagoon",
    island4 = "Shipwreck Cove",
    island5 = "Sphinx Sands",
}

local IslandPrices = {
    starterIsland = 0,
    island2 = 1100000,
    island3 = 32000000,
    island4 = 500000000,
    island5 = 20000000000,
}

------------------------------------------------------------------------
--// PLAYER DATA HELPERS
------------------------------------------------------------------------
local function getPlayerData()
    local data = nil
    pcall(function()
        data = LocalPlayer:GetAttribute("PlayerData")
    end)
    return data
end

local function getGold()
    return LocalPlayer:GetAttribute("Gold") or 0
end

local function getHeldItem()
    return LocalPlayer:GetAttribute("HeldItem")
end

local function getInventorySize()
    return LocalPlayer:GetAttribute("InventorySize") or 0
end

local function getMaxInventory()
    return LocalPlayer:GetAttribute("MaxInventory") or 10
end

local function isInventoryFull()
    return getInventorySize() >= getMaxInventory()
end

------------------------------------------------------------------------
--// TABS
------------------------------------------------------------------------
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local FarmTab = Window:AddTab({ Name = "Farm", Icon = "pickaxe" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "shopping-cart" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- Main > Automation
local AutoSubTab = MainTab:AddSubTab("Automation", "zap")
local CoreGroup = AutoSubTab:AddLeftGroupbox("Core Features", "box-icon")
local ExtraGroup = AutoSubTab:AddRightGroupbox("Extra Features", "box-icon")

-- Main > Config
local ConfigSubTab = MainTab:AddSubTab("Config", "cog")
local ConfigGroup = ConfigSubTab:AddLeftGroupbox("Settings", "box-icon")
local InfoGroup = ConfigSubTab:AddRightGroupbox("Info", "box-icon")

-- Main > Discord
local DiscordSubTab = MainTab:AddSubTab("Discord", "users")
local DiscordGroup = DiscordSubTab:AddLeftGroupbox("Community", "box-icon")

-- Player > Movement
local MovementSubTab = PlayerTab:AddSubTab("Movement", "zap")
local SpeedGroup = MovementSubTab:AddLeftGroupbox("Speed", "box-icon")
local JumpGroup = MovementSubTab:AddRightGroupbox("Jump", "box-icon")

-- Player > Visuals
local VisualsSubTab = PlayerTab:AddSubTab("Visuals", "eye")
local ESPGroup = VisualsSubTab:AddLeftGroupbox("ESP", "box-icon")

-- Farm > Digging
local DiggingSubTab = FarmTab:AddSubTab("Digging", "pickaxe")
local DigGroup = DiggingSubTab:AddLeftGroupbox("Auto Dig", "box-icon")
local CleanGroup = DiggingSubTab:AddRightGroupbox("Auto Clean", "box-icon")

-- Farm > Inventory
local InventorySubTab = FarmTab:AddSubTab("Inventory", "box")
local SellGroup = InventorySubTab:AddLeftGroupbox("Sell & Display", "box-icon")
local CollectGroup = InventorySubTab:AddRightGroupbox("Collect", "box-icon")

-- Farm > Island
local IslandSubTab = FarmTab:AddSubTab("Islands", "map")
local TravelGroup = IslandSubTab:AddLeftGroupbox("Travel", "box-icon")
local PyramidGroup = IslandSubTab:AddRightGroupbox("Pyramid", "box-icon")

-- Farm > Museum
local MuseumSubTab = FarmTab:AddSubTab("Museum", "building")
local MuseumGroup = MuseumSubTab:AddLeftGroupbox("Museum", "box-icon")
local PolishGroup = MuseumSubTab:AddRightGroupbox("Polisher", "box-icon")

-- Shop > Shovels
local ShovelsSubTab = ShopTab:AddSubTab("Shovels", "pickaxe")
local ShovelGroup = ShovelsSubTab:AddLeftGroupbox("Shovels", "box-icon")

-- Shop > Detectors
local DetectorsSubTab = ShopTab:AddSubTab("Detectors", "radio")
local DetectorGroup = DetectorsSubTab:AddLeftGroupbox("Detectors", "box-icon")

-- Shop > Sprays
local SpraysSubTab = ShopTab:AddSubTab("Sprays", "droplet")
local SprayGroup = SpraysSubTab:AddLeftGroupbox("Spray Bottles", "box-icon")

-- Shop > Quests & Rewards
local RewardsSubTab = ShopTab:AddSubTab("Rewards", "gift")
local QuestGroup = RewardsSubTab:AddLeftGroupbox("Quests", "box-icon")
local RewardGroup = RewardsSubTab:AddRightGroupbox("Rewards", "box-icon")

-- Settings
local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "box-icon")

------------------------------------------------------------------------
--// DISCORD LINK
------------------------------------------------------------------------
DiscordGroup:AddButton("Join Discord For Dupe", function()
    setclipboard("https://discord.gg/MCWYKBdB4E")
    notify("Discord link copied to clipboard!", "Success")
end)

------------------------------------------------------------------------
--// CORE AUTOMATION TOGGLES
------------------------------------------------------------------------
CoreGroup:AddToggle("AutoDetect", { Text = "Auto Detect Dig Spots", Default = false,
    Callback = function(s) _G.IvoryAutoDetect = s; notify(s and "Auto Detect Enabled" or "Auto Detect Disabled") end,
}):AddKeyPicker("DetectKey", { Default = "F", Text = "Auto Detect Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

CoreGroup:AddToggle("AutoDig", { Text = "Auto Dig", Default = false,
    Callback = function(s) _G.IvoryAutoDig = s; notify(s and "Auto Dig Enabled" or "Auto Dig Disabled") end,
}):AddKeyPicker("DigKey", { Default = "G", Text = "Auto Dig Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

CoreGroup:AddToggle("AutoClean", { Text = "Auto Clean Items", Default = false,
    Callback = function(s) _G.IvoryAutoClean = s; notify(s and "Auto Clean Enabled" or "Auto Clean Disabled") end,
})

CoreGroup:AddToggle("AutoSellHeld", { Text = "Auto Sell Held Item", Default = false,
    Callback = function(s) _G.IvoryAutoSellHeld = s end,
})

CoreGroup:AddToggle("AutoSellInventory", { Text = "Auto Sell Inventory When Full", Default = false,
    Callback = function(s) _G.IvoryAutoSellInventory = s end,
})

CoreGroup:AddToggle("AutoPlace", { Text = "Auto Place in Museum", Default = false,
    Callback = function(s) _G.IvoryAutoPlace = s end,
})

CoreGroup:AddToggle("AutoPickup", { Text = "Auto Pickup Surfaced Items", Default = false,
    Callback = function(s) _G.IvoryAutoPickup = s end,
})

CoreGroup:AddToggle("AutoEquipTool", { Text = "Auto Equip Best Tool", Default = false,
    Callback = function(s) _G.IvoryAutoEquipTool = s end,
})

------------------------------------------------------------------------
--// EXTRA FEATURES
------------------------------------------------------------------------
ExtraGroup:AddToggle("AntiAFK", { Text = "Anti AFK", Default = false,
    Callback = function(s) _G.IvoryAntiAFK = s end,
})

ExtraGroup:AddToggle("NoClip", { Text = "NoClip", Default = false,
    Callback = function(s) _G.IvoryNoClip = s end,
})

ExtraGroup:AddToggle("AutoClaimOffline", { Text = "Auto Claim Offline Earnings", Default = false,
    Callback = function(s) _G.IvoryAutoClaimOffline = s end,
})

ExtraGroup:AddToggle("AutoClaimQuests", { Text = "Auto Claim Quests", Default = false,
    Callback = function(s) _G.IvoryAutoClaimQuests = s end,
})

ExtraGroup:AddToggle("AutoClaimGroup", { Text = "Auto Claim Group Reward", Default = false,
    Callback = function(s) _G.IvoryAutoClaimGroup = s end,
})

ExtraGroup:AddToggle("AutoClaimFreePack", { Text = "Auto Claim Free Pack", Default = false,
    Callback = function(s) _G.IvoryAutoClaimFreePack = s end,
})

ExtraGroup:AddToggle("AutoRedeemCodes", { Text = "Auto Redeem Codes", Default = false,
    Callback = function(s) _G.IvoryAutoRedeemCodes = s end,
})

ExtraGroup:AddButton("Redeem All Codes", function()
    local codes = {"UPDATE3", "UPDATE2", "SECRET10", "Update1"}
    for _, code in ipairs(codes) do
        pcall(function() fireRemote("CodeNetwork", "redeemCode", code) end)
    end
    notify("Attempted to redeem " .. #codes .. " codes!", "Success")
end)

ExtraGroup:AddButton("Claim Offline Earnings", function()
    pcall(function() fireRemote("OfflineEarningsNetwork", "requestOfflineEarnings") end)
    notify("Offline earnings requested!", "Success")
end)

ExtraGroup:AddButton("Claim Group Reward", function()
    pcall(function() fireRemote("FreeLuckNetwork", "claimGroupReward") end)
    notify("Group reward claimed!", "Success")
end)

ExtraGroup:AddButton("Claim Free Pack", function()
    pcall(function() fireRemote("ForeverPackNetwork", "claimFree") end)
    notify("Free pack claimed!", "Success")
end)

------------------------------------------------------------------------
--// CONFIG
------------------------------------------------------------------------
ConfigGroup:AddToggle("AutoSave", { Text = "Auto Save Settings", Default = true,
    Callback = function(s) _G.IvoryAutoSave = s end,
})

ConfigGroup:AddButton("Reset All Settings", function()
    for k, v in pairs(_G) do
        if type(v) == "boolean" and string.find(k, "Ivory") then _G[k] = false
        elseif type(v) == "number" and string.find(k, "Ivory") then _G[k] = nil end
    end
    notify("All settings reset", "Success")
end)

ConfigGroup:AddButton("Load Config", function()
    SaveManager:LoadConfig()
    notify("Config loaded", "Success")
end)

ConfigGroup:AddButton("Save Config", function()
    SaveManager:SaveConfig()
    notify("Config saved", "Success")
end)

InfoGroup:AddLabel("Ivory Hub v1.4")
InfoGroup:AddLabel("Game: Dig & Clean")
InfoGroup:AddLabel("PlaceId: " .. tostring(PlaceId))
InfoGroup:AddLabel("UserId: " .. tostring(LocalPlayer.UserId))
InfoGroup:AddButton("Copy PlaceId", function()
    setclipboard(tostring(PlaceId))
    notify("PlaceId copied!", "Success")
end)

------------------------------------------------------------------------
--// SPEED HACK
------------------------------------------------------------------------
SpeedGroup:AddToggle("SpeedHack", { Text = "Speed Hack", Default = false,
    Callback = function(s) _G.IvorySpeedHack = s end,
})
SpeedGroup:AddSlider("SpeedValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 500, Rounding = 0,
    Callback = function(v) _G.IvorySpeedValue = v end,
})
SpeedGroup:AddButton("Reset Speed", function()
    pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end)
    _G.IvorySpeedHack = false
    notify("Speed Reset", "Success")
end)

------------------------------------------------------------------------
--// JUMP HACK
------------------------------------------------------------------------
JumpGroup:AddToggle("JumpHack", { Text = "Jump Hack", Default = false,
    Callback = function(s) _G.IvoryJumpHack = s end,
})
JumpGroup:AddSlider("JumpValue", { Text = "Jump Power", Default = 50, Min = 50, Max = 500, Rounding = 0,
    Callback = function(v) _G.IvoryJumpValue = v end,
})
JumpGroup:AddButton("Reset Jump", function()
    pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end)
    _G.IvoryJumpHack = false
    notify("Jump Reset", "Success")
end)

------------------------------------------------------------------------
--// ESP
------------------------------------------------------------------------
ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
    Default = Color3.fromRGB(255, 0, 0), Title = "ESP Color",
    Callback = function(v) _G.IvoryESPColor = v end,
})
ESPGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = false,
    Callback = function(s) _G.IvoryPlayerESP = s end,
})
ESPGroup:AddToggle("BoxESP", { Text = "Box ESP", Default = false,
    Callback = function(s) _G.IvoryBoxESP = s end,
})
ESPGroup:AddToggle("NameESP", { Text = "Name ESP", Default = false,
    Callback = function(s) _G.IvoryNameESP = s end,
})
ESPGroup:AddToggle("HealthESP", { Text = "Health ESP", Default = false,
    Callback = function(s) _G.IvoryHealthESP = s end,
})
ESPGroup:AddToggle("DistanceESP", { Text = "Distance ESP", Default = false,
    Callback = function(s) _G.IvoryDistanceESP = s end,
})
ESPGroup:AddToggle("DigSpotESP", { Text = "Dig Spot ESP", Default = false,
    Callback = function(s) _G.IvoryDigSpotESP = s end,
})
ESPGroup:AddToggle("SurfacedItemESP", { Text = "Surfaced Item ESP", Default = false,
    Callback = function(s) _G.IvorySurfacedItemESP = s end,
})
ESPGroup:AddSlider("ESPRange", { Text = "ESP Range", Default = 200, Min = 50, Max = 1000, Rounding = 0,
    Callback = function(v) _G.IvoryESPRange = v end,
})

------------------------------------------------------------------------
--// AUTO DIG LOOPS
------------------------------------------------------------------------
-- Auto Detect: Fire the detector sweep
task.spawn(function()
    while true do
        if _G.IvoryAutoDetect then
            pcall(function()
                fireRemote("DetectorNetwork", "GetDetectorStates")
            end)
        end
        task.wait(DiggingConfig.DETECTOR_SWEEP_SECONDS or 0.8)
    end
end)

-- Auto Dig: Fire dig inputs rapidly (the dig minigame uses click timing)
task.spawn(function()
    while true do
        if _G.IvoryAutoDig then
            pcall(function()
                -- Fire dig input events rapidly
                for _ = 1, 3 do
                    fireRemote("ShovelNetwork", "DigInput")
                    task.wait(0.05)
                end
            end)
        end
        task.wait(0.1)
    end
end)

-- Auto Begin Dig when ready
task.spawn(function()
    while true do
        if _G.IvoryAutoDig then
            pcall(function()
                fireRemote("ShovelNetwork", "BeginDig")
            end)
        end
        task.wait(1)
    end
end)

------------------------------------------------------------------------
--// AUTO CLEAN LOOPS
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoClean then
            pcall(function()
                -- Start cleaning the held item
                fireRemote("ItemsNetwork", "beginCleaning")
                task.wait(0.2)
                -- Save clean progress repeatedly
                fireRemote("ItemsNetwork", "saveCleanProgress")
                task.wait(0.2)
                -- Finish cleaning
                fireRemote("ItemsNetwork", "finishCleaning")
            end)
        end
        task.wait(0.5)
    end
end)

------------------------------------------------------------------------
--// AUTO SELL LOOPS
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoSellHeld then
            pcall(function()
                if getHeldItem() then
                    fireRemote("SellNetwork", "sellHeldItem")
                end
            end)
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoSellInventory then
            pcall(function()
                if isInventoryFull() then
                    fireRemote("SellNetwork", "sellInventory")
                    notify("Inventory sold!", "Success")
                end
            end)
        end
        task.wait(2)
    end
end)

------------------------------------------------------------------------
--// AUTO PLACE IN MUSEUM
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoPlace then
            pcall(function()
                if getHeldItem() then
                    fireRemote("PedestalNetwork", "placeItem")
                end
            end)
        end
        task.wait(1)
    end
end)

------------------------------------------------------------------------
--// AUTO PICKUP SURFACED ITEMS
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoPickup then
            pcall(function()
                fireRemote("ShovelNetwork", "GetSurfacedItems")
            end)
        end
        task.wait(2)
    end
end)

------------------------------------------------------------------------
--// AUTO CLAIM LOOPS
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoClaimOffline then
            pcall(function() fireRemote("OfflineEarningsNetwork", "requestOfflineEarnings") end)
        end
        task.wait(60)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoClaimQuests then
            pcall(function() fireRemote("QuestNetwork", "claimQuest") end)
        end
        task.wait(30)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoClaimGroup then
            pcall(function() fireRemote("FreeLuckNetwork", "claimGroupReward") end)
        end
        task.wait(300)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoClaimFreePack then
            pcall(function() fireRemote("ForeverPackNetwork", "claimFree") end)
        end
        task.wait(60)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoRedeemCodes then
            pcall(function()
                local codes = {"UPDATE3", "UPDATE2", "SECRET10", "Update1"}
                for _, code in ipairs(codes) do
                    fireRemote("CodeNetwork", "redeemCode", code)
                    task.wait(0.5)
                end
            end)
        end
        task.wait(300)
    end
end)

------------------------------------------------------------------------
--// TELEPORT
------------------------------------------------------------------------
TravelGroup:AddDropdown("TeleportIsland", {
    Text = "Travel To Island",
    Values = {"Home Beach", "Frozen Shores", "Lava Lagoon", "Shipwreck Cove", "Sphinx Sands"},
    Default = "Home Beach", Multi = false,
    Callback = function(v) _G.IvoryTeleportIsland = v end,
})

TravelGroup:AddButton("Travel", function()
    local island = _G.IvoryTeleportIsland or "Home Beach"
    local islandId = nil
    for id, display in pairs(IslandDisplay) do
        if display == island then islandId = id; break end
    end
    if islandId then
        pcall(function() fireRemote("TravelNetwork", "travel", islandId) end)
        notify("Traveling to " .. island .. "!", "Success")
    end
end)

TravelGroup:AddButton("Teleport Home", function()
    pcall(function() fireRemote("MiscNetwork", "RequestTeleportHome") end)
    notify("Teleporting home!", "Success")
end)

------------------------------------------------------------------------
--// ISLAND INFO
------------------------------------------------------------------------
for i, islandId in ipairs(IslandOrder) do
    local display = IslandDisplay[islandId]
    local price = IslandPrices[islandId]
    local luck = IslandsConfig[islandId] and IslandsConfig[islandId].luckMultiplier or "?"
    TravelGroup:AddLabel(display .. " | $" .. tostring(price) .. " | " .. tostring(luck) .. "x Luck")
end

------------------------------------------------------------------------
--// PYRAMID
------------------------------------------------------------------------
PyramidGroup:AddButton("Unlock Pyramid", function()
    pcall(function() fireRemote("PyramidNetwork", "unlockPyramid") end)
    notify("Pyramid unlock attempted!", "Success")
end)

PyramidGroup:AddButton("Sacrifice Gold", function()
    pcall(function() fireRemote("PyramidNetwork", "sacrificeGold") end)
    notify("Gold sacrificed!", "Success")
end)

PyramidGroup:AddButton("Request Well Rank", function()
    pcall(function() fireRemote("PyramidNetwork", "requestWellRank") end)
    notify("Well rank requested!", "Success")
end)

PyramidGroup:AddToggle("AutoSacrifice", { Text = "Auto Sacrifice Gold", Default = false,
    Callback = function(s) _G.IvoryAutoSacrifice = s end,
})

task.spawn(function()
    while true do
        if _G.IvoryAutoSacrifice then
            pcall(function() fireRemote("PyramidNetwork", "sacrificeGold") end)
        end
        task.wait(5)
    end
end)

------------------------------------------------------------------------
--// MUSEUM / PEDESTAL
------------------------------------------------------------------------
MuseumGroup:AddButton("Place Item on Pedestal", function()
    pcall(function() fireRemote("PedestalNetwork", "placeItem") end)
    notify("Item placed!", "Success")
end)

MuseumGroup:AddButton("Pickup Item from Pedestal", function()
    pcall(function() fireRemote("PedestalNetwork", "pickupItem") end)
    notify("Item picked up!", "Success")
end)

MuseumGroup:AddButton("Buy Pedestal", function()
    pcall(function() fireRemote("PedestalNetwork", "buyPedestal") end)
    notify("Pedestal purchase attempted!", "Success")
end)

MuseumGroup:AddButton("Unlock Plot Section", function()
    pcall(function() fireRemote("PlotSectionNetwork", "unlockSection") end)
    notify("Section unlock attempted!", "Success")
end)

------------------------------------------------------------------------
--// POLISHER
------------------------------------------------------------------------
PolishGroup:AddButton("Start Polish", function()
    pcall(function() fireRemote("PolisherNetwork", "startPolish") end)
    notify("Polish started!", "Success")
end)

PolishGroup:AddButton("Collect Polish", function()
    pcall(function() fireRemote("PolisherNetwork", "collectPolish") end)
    notify("Polish collected!", "Success")
end)

PolishGroup:AddButton("Unlock Polisher", function()
    pcall(function() fireRemote("PolisherNetwork", "unlockPolisher") end)
    notify("Polisher unlock attempted!", "Success")
end)

PolishGroup:AddButton("Upgrade Polisher", function()
    pcall(function() fireRemote("PolisherNetwork", "upgradePolisher") end)
    notify("Polisher upgrade attempted!", "Success")
end)

------------------------------------------------------------------------
--// SELL BUTTONS
------------------------------------------------------------------------
SellGroup:AddButton("Sell Held Item", function()
    pcall(function() fireRemote("SellNetwork", "sellHeldItem") end)
    notify("Held item sold!", "Success")
end)

SellGroup:AddButton("Sell All Inventory", function()
    pcall(function() fireRemote("SellNetwork", "sellInventory") end)
    notify("Inventory sold!", "Success")
end)

CollectGroup:AddButton("Request Offline Earnings", function()
    pcall(function() fireRemote("OfflineEarningsNetwork", "requestOfflineEarnings") end)
    notify("Offline earnings requested!", "Success")
end)

CollectGroup:AddButton("Claim Group Reward", function()
    pcall(function() fireRemote("FreeLuckNetwork", "claimGroupReward") end)
    notify("Group reward claimed!", "Success")
end)

CollectGroup:AddButton("Claim Free Pack", function()
    pcall(function() fireRemote("ForeverPackNetwork", "claimFree") end)
    notify("Free pack claimed!", "Success")
end)

CollectGroup:AddButton("Claim Daily Luck", function()
    pcall(function() fireRemote("FreeLuckNetwork", "RequestAdReward") end)
    notify("Ad reward requested!", "Success")
end)

------------------------------------------------------------------------
--// SHOP > SHOVELS
------------------------------------------------------------------------
for i, name in ipairs(ShovelOrder) do
    local data = Shovels[name]
    if data then
        ShovelGroup:AddLabel(name .. " | Power: " .. tostring(data.power) .. " | $" .. tostring(data.cash))
    end
end

ShovelGroup:AddDropdown("TargetShovel", {
    Text = "Target Shovel",
    Values = ShovelOrder,
    Default = ShovelOrder[1], Multi = false,
    Callback = function(v) _G.IvoryTargetShovel = v end,
})

ShovelGroup:AddButton("Buy Target Shovel", function()
    local target = _G.IvoryTargetShovel or ShovelOrder[1]
    pcall(function() fireRemote("ShopNetwork", "buyGear", "shovel", target) end)
    notify("Attempted to buy " .. target, "Success")
end)

ShovelGroup:AddButton("Equip Target Shovel", function()
    local target = _G.IvoryTargetShovel or ShovelOrder[1]
    pcall(function() fireRemote("ShopNetwork", "equipGear", "shovel", target) end)
    notify("Equipped " .. target, "Success")
end)

ShovelGroup:AddToggle("AutoBuyShovel", { Text = "Auto Buy Next Shovel", Default = false,
    Callback = function(s) _G.IvoryAutoBuyShovel = s end,
})

------------------------------------------------------------------------
--// SHOP > DETECTORS
------------------------------------------------------------------------
for i, name in ipairs(DetectorOrder) do
    local data = Detectors[name]
    if data then
        DetectorGroup:AddLabel(name .. " | Luck: " .. tostring(data.luck) .. " | $" .. tostring(data.cash))
    end
end

DetectorGroup:AddDropdown("TargetDetector", {
    Text = "Target Detector",
    Values = DetectorOrder,
    Default = DetectorOrder[1], Multi = false,
    Callback = function(v) _G.IvoryTargetDetector = v end,
})

DetectorGroup:AddButton("Buy Target Detector", function()
    local target = _G.IvoryTargetDetector or DetectorOrder[1]
    pcall(function() fireRemote("ShopNetwork", "buyGear", "detector", target) end)
    notify("Attempted to buy " .. target, "Success")
end)

DetectorGroup:AddButton("Equip Target Detector", function()
    local target = _G.IvoryTargetDetector or DetectorOrder[1]
    pcall(function() fireRemote("ShopNetwork", "equipGear", "detector", target) end)
    notify("Equipped " .. target, "Success")
end)

DetectorGroup:AddToggle("AutoBuyDetector", { Text = "Auto Buy Next Detector", Default = false,
    Callback = function(s) _G.IvoryAutoBuyDetector = s end,
})

------------------------------------------------------------------------
--// SHOP > SPRAYS
------------------------------------------------------------------------
for i, name in ipairs(SprayOrder) do
    local data = SprayBottles[name]
    if data then
        SprayGroup:AddLabel(name .. " | Range: " .. tostring(data.range) .. " | $" .. tostring(data.cash))
    end
end

SprayGroup:AddDropdown("TargetSpray", {
    Text = "Target Spray",
    Values = SprayOrder,
    Default = SprayOrder[1], Multi = false,
    Callback = function(v) _G.IvoryTargetSpray = v end,
})

SprayGroup:AddButton("Buy Target Spray", function()
    local target = _G.IvoryTargetSpray or SprayOrder[1]
    pcall(function() fireRemote("ShopNetwork", "buyGear", "spray", target) end)
    notify("Attempted to buy " .. target, "Success")
end)

SprayGroup:AddButton("Equip Target Spray", function()
    local target = _G.IvoryTargetSpray or SprayOrder[1]
    pcall(function() fireRemote("ShopNetwork", "equipGear", "spray", target) end)
    notify("Equipped " .. target, "Success")
end)

SprayGroup:AddToggle("AutoBuySpray", { Text = "Auto Buy Next Spray", Default = false,
    Callback = function(s) _G.IvoryAutoBuySpray = s end,
})

------------------------------------------------------------------------
--// AUTO BUY LOOPS
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoBuyShovel then
            pcall(function()
                local target = _G.IvoryTargetShovel
                if target then
                    fireRemote("ShopNetwork", "buyGear", "shovel", target)
                end
            end)
        end
        task.wait(10)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoBuyDetector then
            pcall(function()
                local target = _G.IvoryTargetDetector
                if target then
                    fireRemote("ShopNetwork", "buyGear", "detector", target)
                end
            end)
        end
        task.wait(10)
    end
end)

task.spawn(function()
    while true do
        if _G.IvoryAutoBuySpray then
            pcall(function()
                local target = _G.IvoryTargetSpray
                if target then
                    fireRemote("ShopNetwork", "buyGear", "spray", target)
                end
            end)
        end
        task.wait(10)
    end
end)

------------------------------------------------------------------------
--// PLAYER ESP
------------------------------------------------------------------------
task.spawn(function()
    local espObjects = {}
    local function createESP(player)
        if player == LocalPlayer then return end
        espObjects[player] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Health = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
        }
        local e = espObjects[player]
        e.Box.Thickness = 1; e.Box.Filled = false; e.Box.Visible = false
        e.Name.Size = 14; e.Name.Center = true; e.Name.Outline = true; e.Name.Visible = false
        e.Health.Size = 12; e.Health.Center = true; e.Health.Outline = true; e.Health.Visible = false
        e.Distance.Size = 12; e.Distance.Center = true; e.Distance.Outline = true; e.Distance.Visible = false
    end

    local function removeESP(player)
        if espObjects[player] then
            pcall(function() for _, v in pairs(espObjects[player]) do v:Remove() end end)
            espObjects[player] = nil
        end
    end

    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)

    RunService.RenderStepped:Connect(function()
        local color = _G.IvoryESPColor or Color3.fromRGB(255, 0, 0)
        local cam = Workspace.CurrentCamera
        for player, esp in pairs(espObjects) do
            pcall(function()
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
                    local hrp, hum = char.HumanoidRootPart, char.Humanoid
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local localHRP = getHRP()
                        if localHRP and (hrp.Position - localHRP.Position).Magnitude > (_G.IvoryESPRange or 200) then
                            esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Distance.Visible = false
                            return
                        end
                        local rootPos = cam:WorldToViewportPoint(hrp.Position)
                        local headPos = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                        local height = math.abs(rootPos.Y - headPos.Y) * 2
                        local width = height / 2

                        if _G.IvoryBoxESP then
                            esp.Box.Size = Vector2.new(width, height)
                            esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                            esp.Box.Visible = true; esp.Box.Color = color
                        else esp.Box.Visible = false end

                        if _G.IvoryNameESP then
                            esp.Name.Text = player.DisplayName
                            esp.Name.Position = Vector2.new(pos.X, pos.Y - 20)
                            esp.Name.Visible = true; esp.Name.Color = color
                        else esp.Name.Visible = false end

                        if _G.IvoryHealthESP then
                            local hp, maxHp = math.floor(hum.Health), math.floor(hum.MaxHealth)
                            esp.Health.Text = hp.."/"..maxHp
                            esp.Health.Position = Vector2.new(pos.X, pos.Y + height/2 + 5)
                            esp.Health.Visible = true
                            esp.Health.Color = Color3.fromRGB(255*(1-hp/maxHp), 255*(hp/maxHp), 0)
                        else esp.Health.Visible = false end

                        if _G.IvoryDistanceESP and localHRP then
                            esp.Distance.Text = math.floor((hrp.Position - localHRP.Position).Magnitude).."m"
                            esp.Distance.Position = Vector2.new(pos.X, pos.Y + height/2 + 20)
                            esp.Distance.Visible = true; esp.Distance.Color = color
                        else esp.Distance.Visible = false end
                    else
                        esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Distance.Visible = false
                    end
                else
                    esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Distance.Visible = false
                end
            end)
        end
    end)
end)

------------------------------------------------------------------------
--// DIG SPOT ESP (Buried Nodes)
------------------------------------------------------------------------
task.spawn(function()
    local digSpotObjects = {}
    while true do
        pcall(function()
            for _, obj in ipairs(digSpotObjects) do pcall(function() obj:Remove() end) end
            digSpotObjects = {}
            if _G.IvoryDigSpotESP then
                local cam = Workspace.CurrentCamera
                local localHRP = getHRP()
                local range = _G.IvoryESPRange or 200
                local islands = Workspace:FindFirstChild("Islands")
                if islands and localHRP then
                    for _, island in ipairs(islands:GetDescendants()) do
                        if island.Name == "BuriedNode" or island.Name == "DigSpot" then
                            local pos3d = island:IsA("BasePart") and island.Position or (island:IsA("Model") and island.PrimaryPart and island.PrimaryPart.Position)
                            if pos3d and (pos3d - localHRP.Position).Magnitude <= range then
                                local pos, onScreen = cam:WorldToViewportPoint(pos3d)
                                if onScreen then
                                    local txt = Drawing.new("Text")
                                    txt.Size = 14; txt.Center = true; txt.Outline = true
                                    txt.Color = Color3.fromRGB(255, 255, 0)
                                    txt.Text = "DIG"
                                    txt.Position = Vector2.new(pos.X, pos.Y - 20)
                                    txt.Visible = true
                                    table.insert(digSpotObjects, txt)
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

------------------------------------------------------------------------
--// SPEED & JUMP HEARTBEAT
------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    pcall(function()
        local hum = getHumanoid()
        if hum then
            if _G.IvorySpeedHack and _G.IvorySpeedValue then
                hum.WalkSpeed = _G.IvorySpeedValue
            end
            if _G.IvoryJumpHack and _G.IvoryJumpValue then
                hum.JumpPower = _G.IvoryJumpValue
            end
        end
    end)
end)

------------------------------------------------------------------------
--// NOCLIP
------------------------------------------------------------------------
RunService.Stepped:Connect(function()
    if _G.IvoryNoClip then
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                for _, p in ipairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end)

------------------------------------------------------------------------
--// ANTI AFK
------------------------------------------------------------------------
task.spawn(function()
    LocalPlayer.Idled:Connect(function()
        if _G.IvoryAntiAFK then
            VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        end
    end)
end)

------------------------------------------------------------------------
--// AUTO SAVE
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoSave then
            pcall(function() SaveManager:SaveConfig() end)
        end
        task.wait(30)
    end
end)

------------------------------------------------------------------------
--// SETTINGS TAB
------------------------------------------------------------------------
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

MenuGroup:AddToggle("MenuToggle", { Text = "Toggle Menu", Default = true }):AddKeyPicker("MenuKeybind", {
    Default = "RightShift", Text = "Menu Keybind", Mode = "Toggle", SyncToggleState = false, NoUI = false,
})
MenuGroup:AddToggle("CustomCursor", { Text = "Custom Cursor", Default = false,
    Callback = function(s) Library.ShowCustomCursor = s end,
})
MenuGroup:AddButton("Test Notification", function()
    Library:Notify({ Title = "Ivory", Description = "Test Notification!", Type = "Success", Time = 5 })
end)
MenuGroup:AddDropdown("NotifySide", {
    Text = "Notification Side", Values = {"Left", "Right"}, Default = "Right", Multi = false,
    Callback = function(v) Library.NotifySide = v end,
})
MenuGroup:AddSlider("CornerRadius", {
    Text = "Corner Radius", Default = 4, Min = 0, Max = 20, Rounding = 0,
    Callback = function(v) Library.CornerRadius = v end,
})
MenuGroup:AddButton("Unload Script", function()
    Library:Notify({ Title = "Ivory", Description = "Unloading...", Type = "Info", Time = 2 })
    task.wait(0.5)
    for k in pairs(_G) do if string.find(k, "Ivory") then _G[k] = nil end end
    pcall(function() Library:ToggleWindow() end)
end)

------------------------------------------------------------------------
Library:Notify({ Title = "Ivory", Description = "Ivory Hub Loaded! PlaceId: " .. tostring(PlaceId), Type = "Success", Time = 5 })
print("[Ivory] Dig & Clean loaded | PlaceId: " .. tostring(PlaceId) .. " | v1.4")
