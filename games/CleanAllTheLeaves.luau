--// Ivory Hub - Clean All The Leaves
--// PlaceId: 92637789841354 / 100068273119174
--//
--// Features:
--// [ + ] Auto Farm Leaves (Toggle, Keybind)
--// [ + ] Farm Mode (Teleport to Leaves / Collect In Range)
--// [ + ] Target Zone (All, Frontyard, Porch, Garage, Shed, Court, Rooftop, Backyard, Maze, Pool, Farm, Basement)
--// [ + ] Instant Batch Collect (budget aware, up to 40 leaves per tick)
--// [ + ] Auto Collect Nearest
--// [ + ] Auto Sell at Dumpster (verifies bag actually emptied)
--// [ + ] Auto Equip Tool
--// [ + ] Auto Zone Progression
--// [ + ] Anti AFK
--// [ + ] NoClip
--// [ + ] Auto Daily Claim
--// [ + ] Claim Daily / Free Gift
--// [ + ] Double Leaves / Double Cash Boosts
--// [ + ] Speed Hack (Slider, Reset)
--// [ + ] Jump Hack (Slider, Reset)
--// [ + ] Player ESP (Box, Name, Health, Distance)
--// [ + ] ESP Color
--// [ + ] Leaf Pile ESP
--// [ + ] Vent ESP (Locked/Open)
--// [ + ] Zone Progress ESP
--// [ + ] ESP Range
--// [ + ] Buy Rake / Leaf Blower / Molotov (cash & discount aware)
--// [ + ] Upgrade Bag (real max levels, price check)
--// [ + ] Buy All Vents (teleports beside each vent)
--// [ + ] Auto Buy Vents
--// [ + ] Hand Upgrades (Hold, Dexterity, Grasp)
--// [ + ] Rake Upgrades (Radius, Range, Stickiness)
--// [ + ] Leaf Blower Upgrades (Width, Power, Spread)
--// [ + ] Auto Buy Bag Upgrades
--// [ + ] Auto Buy Hand Upgrades
--// [ + ] Teleport (Spawn, Shop, Upgrades, Dumpster)
--// [ + ] Config Save / Load
--// [ + ] Theme Manager
--// [ + ] Custom Cursor / Menu Keybind / Notification Side
--// [ + ] Unload Script

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local isLobby = (game.PlaceId == 92637789841354)

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

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 5)
local function getRemote(name) if Remotes then return Remotes:FindFirstChild(name) end return nil end

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local FarmTab = Window:AddTab({ Name = "Farm", Icon = "leaf" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local AutoSubTab = MainTab:AddSubTab("Automation", "zap")
local CoreGroup = AutoSubTab:AddLeftGroupbox("Core Features", "box-icon")
local BoostGroup = AutoSubTab:AddRightGroupbox("Boosts & Rewards", "box-icon")

local ConfigSubTab = MainTab:AddSubTab("Config", "cog")
local ConfigGroup = ConfigSubTab:AddLeftGroupbox("Settings", "box-icon")
local InfoGroup = ConfigSubTab:AddRightGroupbox("Info", "box-icon")

local MovementSubTab = PlayerTab:AddSubTab("Movement", "zap")
local SpeedGroup = MovementSubTab:AddLeftGroupbox("Speed", "box-icon")
local JumpGroup = MovementSubTab:AddRightGroupbox("Jump", "box-icon")

local VisualsSubTab = PlayerTab:AddSubTab("Visuals", "eye")
local ESPGroup = VisualsSubTab:AddLeftGroupbox("ESP", "box-icon")

local LeavesSubTab = FarmTab:AddSubTab("Leaves", "leaf")
local FarmGroup = LeavesSubTab:AddLeftGroupbox("Auto Farm", "box-icon")
local TeleportGroup = LeavesSubTab:AddRightGroupbox("Teleport", "box-icon")

local UpgradesSubTab = FarmTab:AddSubTab("Upgrades", "zap")
local UpgradesGroup = UpgradesSubTab:AddLeftGroupbox("Upgrades", "box-icon")

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "box-icon")

------------------------------------------------------------------------
CoreGroup:AddToggle("AutoFarm", { Text = "Auto Farm Leaves", Default = false,
    Callback = function(state) _G.IvoryAutoFarm = state; Library:Notify({ Title = "Ivory", Description = state and "Auto Farm Enabled" or "Auto Farm Disabled", Type = "Info", Time = 2 }) end,
}):AddKeyPicker("AutoFarmKey", { Default = "F", Text = "Auto Farm Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

CoreGroup:AddToggle("AutoCollect", { Text = "Auto Collect Nearest", Default = false, Callback = function(s) _G.IvoryAutoCollect = s end })
CoreGroup:AddToggle("AutoSell", { Text = "Auto Sell at Dumpster", Default = false, Callback = function(s) _G.IvoryAutoSell = s end })
CoreGroup:AddToggle("AntiAFK", { Text = "Anti AFK", Default = false, Callback = function(s) _G.IvoryAntiAFK = s end })
CoreGroup:AddToggle("NoClip", { Text = "NoClip", Default = false, Callback = function(s) _G.IvoryNoClip = s end })

------------------------------------------------------------------------
BoostGroup:AddToggle("AutoDailyClaim", { Text = "Auto Daily Claim", Default = false, Callback = function(s) _G.IvoryAutoDailyClaim = s end })
BoostGroup:AddButton("Claim Daily", function() pcall(function() getRemote("DailyClaim"):FireServer() end); Library:Notify({ Title = "Ivory", Description = "Daily Claimed!", Type = "Success", Time = 3 }) end)
BoostGroup:AddButton("Claim Free Gift", function() pcall(function() getRemote("FreeGiftClaim"):InvokeServer() end); Library:Notify({ Title = "Ivory", Description = "Free Gift Claimed!", Type = "Success", Time = 3 }) end)
BoostGroup:AddButton("Use Double Leaves", function() pcall(function() getRemote("UseBoost"):FireServer("DoubleLeaves") end); Library:Notify({ Title = "Ivory", Description = "Double Leaves!", Type = "Success", Time = 3 }) end)
BoostGroup:AddButton("Use Double Cash", function() pcall(function() getRemote("UseBoost"):FireServer("DoubleCash") end); Library:Notify({ Title = "Ivory", Description = "Double Cash!", Type = "Success", Time = 3 }) end)
BoostGroup:AddButton("Toggle Music", function() pcall(function() getRemote("ToggleSetting"):FireServer("Music") end) end)

------------------------------------------------------------------------
ConfigGroup:AddToggle("AutoSave", { Text = "Auto Save Settings", Default = true, Callback = function(s) _G.IvoryAutoSave = s end })
ConfigGroup:AddButton("Reset All Settings", function()
    for k, v in pairs(_G) do if type(v) == "boolean" and string.find(k, "Ivory") then _G[k] = false elseif type(v) == "number" and string.find(k, "Ivory") then _G[k] = nil end end
    Library:Notify({ Title = "Ivory", Description = "All settings reset", Type = "Success", Time = 3 })
end)
ConfigGroup:AddButton("Load Config", function() SaveManager:LoadConfig(); Library:Notify({ Title = "Ivory", Description = "Config loaded", Type = "Success", Time = 3 }) end)
ConfigGroup:AddButton("Save Config", function() SaveManager:SaveConfig(); Library:Notify({ Title = "Ivory", Description = "Config saved", Type = "Success", Time = 3 }) end)
InfoGroup:AddLabel("Ivory Hub v1.4")
InfoGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
InfoGroup:AddLabel("UserId: " .. tostring(LocalPlayer.UserId))
InfoGroup:AddButton("Copy PlaceId", function() setclipboard(tostring(game.PlaceId)); Library:Notify({ Title = "Ivory", Description = "PlaceId copied!", Type = "Success", Time = 2 }) end)

------------------------------------------------------------------------
SpeedGroup:AddToggle("SpeedHack", { Text = "Speed Hack", Default = false, Callback = function(s) _G.IvorySpeedHack = s end })
SpeedGroup:AddSlider("SpeedValue", { Text = "Walk Speed", Default = 16, Min = 16, Max = 500, Rounding = 0, Callback = function(v) _G.IvorySpeedValue = v end })
SpeedGroup:AddButton("Reset Speed", function() pcall(function() LocalPlayer.Character.Humanoid.WalkSpeed = 16 end); _G.IvorySpeedHack = false; Library:Notify({ Title = "Ivory", Description = "Speed Reset", Type = "Success", Time = 2 }) end)

JumpGroup:AddToggle("JumpHack", { Text = "Jump Hack", Default = false, Callback = function(s) _G.IvoryJumpHack = s end })
JumpGroup:AddSlider("JumpValue", { Text = "Jump Power", Default = 50, Min = 50, Max = 500, Rounding = 0, Callback = function(v) _G.IvoryJumpValue = v end })
JumpGroup:AddButton("Reset Jump", function() pcall(function() LocalPlayer.Character.Humanoid.JumpPower = 50 end); _G.IvoryJumpHack = false; Library:Notify({ Title = "Ivory", Description = "Jump Reset", Type = "Success", Time = 2 }) end)

------------------------------------------------------------------------
ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", { Default = Color3.fromRGB(255, 0, 0), Title = "ESP Color", Callback = function(v) _G.IvoryESPColor = v end })
ESPGroup:AddToggle("PlayerESP", { Text = "Player ESP", Default = false, Callback = function(s) _G.IvoryPlayerESP = s end })
ESPGroup:AddToggle("LeafESP", { Text = "Leaf Pile ESP", Default = false, Callback = function(s) _G.IvoryLeafESP = s end })
ESPGroup:AddToggle("BoxESP", { Text = "Box ESP", Default = false, Callback = function(s) _G.IvoryBoxESP = s end })
ESPGroup:AddToggle("NameESP", { Text = "Name ESP", Default = false, Callback = function(s) _G.IvoryNameESP = s end })
ESPGroup:AddToggle("HealthESP", { Text = "Health ESP", Default = false, Callback = function(s) _G.IvoryHealthESP = s end })
ESPGroup:AddToggle("DistanceESP", { Text = "Distance ESP", Default = false, Callback = function(s) _G.IvoryDistanceESP = s end })
ESPGroup:AddToggle("VentESP", { Text = "Vent ESP", Default = false, Callback = function(s) _G.IvoryVentESP = s end })
ESPGroup:AddToggle("ZoneProgressESP", { Text = "Zone Progress ESP", Default = false, Callback = function(s) _G.IvoryZoneProgressESP = s end })
ESPGroup:AddSlider("ESPRange", { Text = "ESP Range", Default = 1000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) _G.IvoryESPRange = v end })

------------------------------------------------------------------------
FarmGroup:AddDropdown("FarmMode", { Text = "Farm Mode", Values = {"Teleport to Leaves", "Collect In Range"}, Default = "Teleport to Leaves", Multi = false, Callback = function(v) _G.IvoryFarmMode = v end })
FarmGroup:AddDropdown("TargetZone", { Text = "Target Zone", Values = {"All", "Frontyard", "Porch", "Garage", "Shed", "Court", "Rooftop", "Backyard", "Maze", "Pool", "Farm", "Basement"}, Default = "All", Multi = false, Callback = function(v) _G.IvoryTargetZone = v end })
FarmGroup:AddSlider("FarmSpeed", { Text = "Farm Speed (ms)", Default = 100, Min = 50, Max = 500, Rounding = 0, Callback = function(v) _G.IvoryFarmSpeed = v end })
FarmGroup:AddSlider("FarmRadius", { Text = "Farm Radius", Default = 100, Min = 10, Max = 500, Rounding = 0, Callback = function(v) _G.IvoryFarmRadius = v end })
FarmGroup:AddToggle("AutoEquipTool", { Text = "Auto Equip Tool", Default = false, Callback = function(s) _G.IvoryAutoEquipTool = s end })
FarmGroup:AddToggle("AutoZoneProgress", { Text = "Auto Zone Progression", Default = false, Callback = function(s) _G.IvoryAutoZoneProgress = s end })

------------------------------------------------------------------------
TeleportGroup:AddDropdown("TeleportLocation", { Text = "Teleport To", Values = {"Spawn", "Shop", "Upgrades", "Dumpster"}, Default = "Spawn", Multi = false, Callback = function(v) _G.IvoryTeleportLocation = v end })
TeleportGroup:AddButton("Teleport", function()
    local loc = _G.IvoryTeleportLocation or "Spawn"
    pcall(function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local locs = { ["Spawn"] = CFrame.new(-69, 5, -16), ["Shop"] = CFrame.new(85, 5, -18), ["Upgrades"] = CFrame.new(85, 5, 40), ["Dumpster"] = CFrame.new(-23, 5, -65) }
            hrp.CFrame = locs[loc] or CFrame.new(-69, 5, -16)
            Library:Notify({ Title = "Ivory", Description = "Teleported to " .. loc, Type = "Success", Time = 2 })
        end
    end)
end)

------------------------------------------------------------------------
--// UPGRADE HELPERS
------------------------------------------------------------------------
local UpgradeConfig = nil
local BagConfig = nil
pcall(function() UpgradeConfig = require(ReplicatedStorage:WaitForChild("UpgradeConfig")) end)
pcall(function() BagConfig = require(ReplicatedStorage:WaitForChild("BagConfig")) end)

local function getCash() return LocalPlayer:GetAttribute("Cash") or 0 end

local function notify(desc, kind)
    Library:Notify({ Title = "Ivory", Description = desc, Type = kind or "Info", Time = 2.5 })
end

local function inGameGuard(silent)
    if isLobby then
        if not silent then notify("Upgrades only work in the game!", "Info") end
        return false
    end
    return true
end

local function toolPrice(key)
    if UpgradeConfig and UpgradeConfig.shop and UpgradeConfig.shop[key] then
        local price = UpgradeConfig.shop[key].cash
        local discount = 0
        if key == "Rake" then discount = LocalPlayer:GetAttribute("LobbyRakeDiscount") or 0
        elseif key == "LeafBlower" then discount = LocalPlayer:GetAttribute("LobbyBlowerDiscount") or 0 end
        if price and discount > 0 then
            return math.round(price * (1 - discount) * 100) / 100
        end
        return price
    end
    return nil
end

local function ownsTool(key)
    if UpgradeConfig and UpgradeConfig.tools[key] and UpgradeConfig.tools[key].ownsAttr then
        return LocalPlayer:GetAttribute(UpgradeConfig.tools[key].ownsAttr) == true
    end
    return true
end

local function upgradeLevel(tool, upg)
    return LocalPlayer:GetAttribute("Upg_" .. tool .. "_" .. upg) or 0
end

local function upgradeMax(tool, upg)
    if UpgradeConfig and UpgradeConfig.tools[tool] and UpgradeConfig.tools[tool].upgrades[upg] then
        return UpgradeConfig.tools[tool].upgrades[upg].max or 0
    end
    return 5
end

local function upgradePrice(tool, upg)
    local level = upgradeLevel(tool, upg)
    if UpgradeConfig and UpgradeConfig.tools[tool] and UpgradeConfig.tools[tool].upgrades[upg] then
        local prices = UpgradeConfig.tools[tool].upgrades[upg].prices or {}
        return prices[level + 1]
    end
    return nil
end

local function buyTool(key, silent)
    if not inGameGuard(silent) then return false end
    local display = key == "LeafBlower" and "Leaf Blower" or key
    if ownsTool(key) then
        if not silent then notify(display .. " already owned!", "Info") end
        return true
    end
    local price = toolPrice(key)
    if price and getCash() < price then
        if not silent then notify("Need $" .. tostring(price) .. " for " .. display .. "!", "Error") end
        return false
    end
    getRemote("BuyToolCash"):FireServer(key)
    task.wait(0.5)
    if ownsTool(key) then
        if not silent then notify(display .. " purchased!", "Success") end
        return true
    end
    if not silent then notify(display .. " purchase failed!", "Error") end
    return false
end

local function buyUpgrade(tool, upg, silent)
    if not inGameGuard(silent) then return false end
    local level = upgradeLevel(tool, upg)
    local max = upgradeMax(tool, upg)
    if level >= max then
        if not silent then notify(tool .. " " .. upg .. " is maxed!", "Info") end
        return false
    end
    if not ownsTool(tool) then
        if not silent then notify("Buying " .. tool .. " first...", "Info") end
        if not buyTool(tool, silent) then return false end
        task.wait(0.3)
    end
    local price = upgradePrice(tool, upg)
    if price and getCash() < price then
        if not silent then notify("Need $" .. tostring(price) .. " for " .. upg .. "!", "Error") end
        return false
    end
    getRemote("BuyUpgrade"):FireServer(tool, upg)
    task.wait(0.5)
    if upgradeLevel(tool, upg) > level then
        if not silent then notify(tool .. " " .. upg .. " upgraded!", "Success") end
        return true
    end
    if not silent then notify(tool .. " " .. upg .. " upgrade failed!", "Error") end
    return false
end

local function buyBag(silent)
    if not inGameGuard(silent) then return false end
    if LocalPlayer:GetAttribute("InfiniteBag") == true then
        if not silent then notify("Bag is infinite!", "Info") end
        return false
    end
    local maxLevel = BagConfig and (#BagConfig.caps - 1) or 3
    local level = LocalPlayer:GetAttribute("BagLevel") or 0
    if level >= maxLevel then
        if not silent then notify("Bag is maxed!", "Info") end
        return false
    end
    local price = BagConfig and BagConfig.prices[level + 1] or 2
    if getCash() < price then
        if not silent then notify("Need $" .. tostring(price) .. " for bag upgrade!", "Error") end
        return false
    end
    getRemote("BuyBagUpgrade"):FireServer()
    task.wait(0.5)
    if (LocalPlayer:GetAttribute("BagLevel") or 0) > level then
        if not silent then notify("Bag upgraded!", "Success") end
        return true
    end
    if not silent then notify("Bag upgrade failed!", "Error") end
    return false
end

local function buyAllVents(silent)
    if not inGameGuard(silent) then return 0 end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        if not silent then notify("No character!", "Error") end
        return 0
    end
    local ventsFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Vents")
    if not ventsFolder then
        if not silent then notify("No vents found!", "Error") end
        return 0
    end
    local buyRemote = getRemote("BuyVent")
    if not buyRemote then return 0 end
    local bought = 0
    for _, vent in ipairs(ventsFolder:GetChildren()) do
        if vent:IsA("BasePart") and not vent:GetAttribute("Unlocked") then
            local cost = vent:GetAttribute("Cost") or 0
            if getCash() >= cost then
                -- Must stand next to the vent: the server validates proximity
                hrp.CFrame = vent.CFrame + Vector3.new(0, 3, 0)
                task.wait(0.35)
                buyRemote:FireServer(vent)
                task.wait(0.4)
                if vent:GetAttribute("Unlocked") then
                    bought = bought + 1
                end
            end
        end
    end
    if not silent then
        if bought > 0 then notify("Bought " .. bought .. " vent(s)!", "Success")
        else notify("No affordable vents left!", "Info") end
    end
    return bought
end

------------------------------------------------------------------------
UpgradesGroup:AddButton("Buy Rake", function() pcall(buyTool, "Rake") end)
UpgradesGroup:AddButton("Buy Leaf Blower", function() pcall(buyTool, "LeafBlower") end)
UpgradesGroup:AddButton("Buy Molotov", function() pcall(buyTool, "Molotov") end)
UpgradesGroup:AddButton("Upgrade Bag", function() pcall(buyBag) end)

--// Vent Purchasing
UpgradesGroup:AddLabel("--- Vents ---")
UpgradesGroup:AddButton("Buy All Vents", function() pcall(buyAllVents) end)
UpgradesGroup:AddToggle("AutoBuyVents", { Text = "Auto Buy Vents", Default = false, Callback = function(s) _G.IvoryAutoBuyVents = s end })

--// Tool Upgrades
UpgradesGroup:AddLabel("--- Hand Upgrades ---")
UpgradesGroup:AddButton("Hand: Hold (Auto Collect)", function() pcall(buyUpgrade, "Hand", "Hold") end)
UpgradesGroup:AddButton("Hand: Dexterity (Speed)", function() pcall(buyUpgrade, "Hand", "Dexterity") end)
UpgradesGroup:AddButton("Hand: Grasp (Multi-Collect)", function() pcall(buyUpgrade, "Hand", "Grasp") end)

UpgradesGroup:AddLabel("--- Rake Upgrades ---")
UpgradesGroup:AddButton("Rake: Radius", function() pcall(buyUpgrade, "Rake", "Radius") end)
UpgradesGroup:AddButton("Rake: Range", function() pcall(buyUpgrade, "Rake", "Range") end)
UpgradesGroup:AddButton("Rake: Stickiness", function() pcall(buyUpgrade, "Rake", "Stickiness") end)

UpgradesGroup:AddLabel("--- Leaf Blower Upgrades ---")
UpgradesGroup:AddButton("Blower: Width", function() pcall(buyUpgrade, "LeafBlower", "Width") end)
UpgradesGroup:AddButton("Blower: Power", function() pcall(buyUpgrade, "LeafBlower", "Power") end)
UpgradesGroup:AddButton("Blower: Spread", function() pcall(buyUpgrade, "LeafBlower", "Spread") end)

UpgradesGroup:AddLabel("--- Auto Buy ---")
UpgradesGroup:AddToggle("AutoBuyBag", { Text = "Auto Buy Bag Upgrades", Default = false, Callback = function(s) _G.IvoryAutoBuyBag = s end })
UpgradesGroup:AddToggle("AutoBuyHand", { Text = "Auto Buy Hand Upgrades", Default = false, Callback = function(s) _G.IvoryAutoBuyHand = s end })

------------------------------------------------------------------------
ThemeManager:ApplyToTab(SettingsTab); SaveManager:BuildConfigSection(SettingsTab)
MenuGroup:AddToggle("MenuToggle", { Text = "Toggle Menu", Default = true }):AddKeyPicker("MenuKeybind", { Default = "RightShift", Text = "Menu Keybind", Mode = "Toggle", SyncToggleState = false, NoUI = false })
MenuGroup:AddToggle("CustomCursor", { Text = "Custom Cursor", Default = false, Callback = function(s) Library.ShowCustomCursor = s end })
MenuGroup:AddButton("Test Notification", function() Library:Notify({ Title = "Ivory", Description = "Test Notification!", Type = "Success", Time = 5 }) end)
MenuGroup:AddDropdown("NotifySide", { Text = "Notification Side", Values = {"Left", "Right"}, Default = "Right", Multi = false, Callback = function(v) Library.NotifySide = v end })
MenuGroup:AddSlider("CornerRadius", { Text = "Corner Radius", Default = 4, Min = 0, Max = 20, Rounding = 0, Callback = function(v) Library.CornerRadius = v end })
MenuGroup:AddButton("Unload Script", function() Library:Notify({ Title = "Ivory", Description = "Unloading...", Type = "Info", Time = 2 }); task.wait(0.5); for k in pairs(_G) do if string.find(k, "Ivory") then _G[k] = nil end end; pcall(function() Library:ToggleWindow() end) end)

--// Helper: Get LeafSim module
local LeafSim = nil
pcall(function()
    local playerScripts = LocalPlayer:WaitForChild("PlayerScripts")
    LeafSim = require(playerScripts:WaitForChild("LeafSim"))
end)

------------------------------------------------------------------------
--// Helper: Zone mapping (leaf -> zone)
------------------------------------------------------------------------
local zoneBounds = {}
pcall(function()
    for _, zoneModel in ipairs(game.Workspace.Map.Leave_Locations:GetChildren()) do
        if zoneModel:IsA("Model") then
            local min, max
            for _, part in ipairs(zoneModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    local p = part.Position
                    local s = part.Size / 2
                    local cmin = p - s
                    local cmax = p + s
                    if not min then min = cmin; max = cmax
                    else
                        min = Vector3.new(math.min(min.X, cmin.X), math.min(min.Y, cmin.Y), math.min(min.Z, cmin.Z))
                        max = Vector3.new(math.max(max.X, cmax.X), math.max(max.Y, cmax.Y), math.max(max.Z, cmax.Z))
                    end
                end
            end
            if min then zoneBounds[zoneModel.Name] = { min = min, max = max, center = (min + max) / 2 } end
        end
    end
end)

local function getZoneForLeaf(pos)
    for name, bounds in pairs(zoneBounds) do
        if pos.X >= bounds.min.X and pos.X <= bounds.max.X and pos.Z >= bounds.min.Z and pos.Z <= bounds.max.Z then
            return name
        end
    end
    return "Unknown"
end

local function getZoneCenter(name)
    local b = zoneBounds[name]
    return b and b.center or Vector3.new(0, 0, 0)
end

local function getZoneProgress(name)
    local zoneModel = game.Workspace.Map.Leave_Locations:FindFirstChild(name)
    if zoneModel then
        local goal = zoneModel:GetAttribute("GoalTotal") or 0
        local completed = zoneModel:GetAttribute("Completed") == true
        return { name = name, goal = goal, completed = completed }
    end
    return nil
end

local function getNextUnlockedZone()
    local zonePrereq = nil
    pcall(function() zonePrereq = require(ReplicatedStorage:WaitForChild("MapRegistry")).config().zonePrereq end)
    if not zonePrereq then return nil end
    for zoneName, prereq in pairs(zonePrereq) do
        local prog = getZoneProgress(zoneName)
        if prog and not prog.completed then
            if prereq == "ALL" then
                local allDone = true
                for _, z in ipairs(game.Workspace.Map.Leave_Locations:GetChildren()) do
                    if z:IsA("Model") and z.Name ~= zoneName and z:GetAttribute("GoalTotal") and z:GetAttribute("Completed") ~= true then
                        allDone = false; break
                    end
                end
                if allDone then return zoneName end
            elseif type(prereq) == "table" then
                local met = true
                for _, req in ipairs(prereq) do
                    local rm = game.Workspace.Map.Leave_Locations:FindFirstChild(req)
                    if not rm or rm:GetAttribute("Completed") ~= true then met = false; break end
                end
                if met then return zoneName end
            end
        end
    end
    return nil
end

------------------------------------------------------------------------
local function getLeafParts()
    local leaves = {}
    local folder = Workspace:FindFirstChild("Leaves") or Workspace:FindFirstChild("Fallen leaves")
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            local part = nil
            if child:IsA("BasePart") then part = child
            elseif child:IsA("Model") then part = child:FindFirstChildOfClass("Part") or child.PrimaryPart end
            if part then table.insert(leaves, part) end
        end
    end
    return leaves
end

local function getNearestLeaf(hrp, radius)
    local nearest, nearestDist = nil, radius or math.huge
    for _, part in ipairs(getLeafParts()) do
        local dist = (part.Position - hrp.Position).Magnitude
        if dist < nearestDist then nearestDist = dist; nearest = part end
    end
    return nearest, nearestDist
end

local function isBagFull()
    return (LocalPlayer:GetAttribute("Leaves") or 0) >= (LocalPlayer:GetAttribute("LeafCapacity") or 25)
end

------------------------------------------------------------------------
--// AUTO FARM (LeafSim.collect) - Zone Aware
------------------------------------------------------------------------
task.spawn(function()
    local lastCollect = 0
    while true do
        if _G.IvoryAutoFarm and not isLobby then
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 and not isBagFull() then
                        if _G.IvoryAutoEquipTool then
                            LocalPlayer:SetAttribute("SelectedTool", "Hand")
                            local eq = getRemote("EquipTool")
                            if eq then eq:FireServer("Hand") end
                        end
                        local radius = _G.IvoryFarmRadius or 100
                        local targetZone = _G.IvoryTargetZone or "All"
                        local mode = _G.IvoryFarmMode or "Teleport to Leaves"
                        local function inZone(p)
                            return (targetZone == "All") or (getZoneForLeaf(p.Position) == targetZone)
                        end
                        local nearest, nearestDist = nil, mode == "Teleport to Leaves" and math.huge or radius
                        for _, part in ipairs(getLeafParts()) do
                            if inZone(part) then
                                local dist = (part.Position - hrp.Position).Magnitude
                                if dist < nearestDist then nearestDist = dist; nearest = part end
                            end
                        end
                        if nearest then
                            if mode == "Teleport to Leaves" then
                                hrp.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.15) -- let the server register the new position
                            end
                            if LeafSim and (tick() - lastCollect) > 0.1 then
                                local budget = LeafSim.collectBudget() or 25
                                if budget > 0 then
                                    local batch = {}
                                    local collectRadius = mode == "Teleport to Leaves" and 20 or radius
                                    for _, part in ipairs(getLeafParts()) do
                                        if part.Parent and inZone(part) and (part.Position - hrp.Position).Magnitude < collectRadius then
                                            table.insert(batch, part)
                                            if #batch >= math.min(budget, 40) then break end
                                        end
                                    end
                                    if #batch > 0 then
                                        LeafSim.collectMany(batch)
                                    end
                                end
                                lastCollect = tick()
                            end
                        elseif targetZone ~= "All" and _G.IvoryAutoZoneProgress then
                            local prog = getZoneProgress(targetZone)
                            if prog and prog.completed then
                                local nextZone = getNextUnlockedZone()
                                if nextZone then
                                    _G.IvoryTargetZone = nextZone
                                    Library:Notify({ Title = "Ivory", Description = targetZone .. " complete! Moving to " .. nextZone, Type = "Info", Time = 3 })
                                end
                            elseif prog and not prog.completed then
                                local center = getZoneCenter(targetZone)
                                hrp.CFrame = CFrame.new(center + Vector3.new(0, 10, 0))
                            end
                        end
                    end
                    if _G.IvoryAutoSell and isBagFull() then
                        local dumpstersFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Dumpsters")
                        if dumpstersFolder then
                            for _, dumpster in ipairs(dumpstersFolder:GetChildren()) do
                                if dumpster:IsA("Model") then
                                    local part = dumpster:FindFirstChildOfClass("Part") or dumpster.PrimaryPart
                                    if not part then
                                        for _, child in ipairs(dumpster:GetDescendants()) do
                                            if child:IsA("BasePart") then part = child; break end
                                        end
                                    end
                                    if part then
                                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(4, -2, 4))
                                        task.wait(0.5)
                                        local before = LocalPlayer:GetAttribute("Leaves") or 0
                                        local emptyRemote = getRemote("EmptyBackpack")
                                        if emptyRemote then emptyRemote:FireServer() end
                                        for _ = 1, 6 do
                                            task.wait(0.3)
                                            if (LocalPlayer:GetAttribute("Leaves") or 0) < before then break end
                                        end
                                        if (LocalPlayer:GetAttribute("Leaves") or 0) < before then
                                            Library:Notify({ Title = "Ivory", Description = "Sold leaves!", Type = "Success", Time = 2 })
                                        end
                                        task.wait(1); break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait((_G.IvoryFarmSpeed or 100) / 1000)
    end
end)

------------------------------------------------------------------------
--// AUTO COLLECT
------------------------------------------------------------------------
task.spawn(function()
    local lastCollect = 0
    while true do
        if _G.IvoryAutoCollect and not isLobby then
            pcall(function()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and not isBagFull() then
                    local radius = _G.IvoryFarmRadius or 100
                    if LeafSim and (tick() - lastCollect) > 0.1 then
                        local budget = LeafSim.collectBudget() or 25
                        if budget > 0 then
                            local batch = {}
                            for _, part in ipairs(getLeafParts()) do
                                if part.Parent and (part.Position - hrp.Position).Magnitude < radius then
                                    table.insert(batch, part)
                                    if #batch >= math.min(budget, 40) then break end
                                end
                            end
                            if #batch > 0 then LeafSim.collectMany(batch) end
                        end
                        lastCollect = tick()
                    end
                end
            end)
        end
        task.wait(0.1)
    end
end)

------------------------------------------------------------------------
--// AUTO SELL
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoSell and not isLobby then
            pcall(function()
                if isBagFull() then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local dumpstersFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Dumpsters")
                        if dumpstersFolder then
                            for _, dumpster in ipairs(dumpstersFolder:GetChildren()) do
                                if dumpster:IsA("Model") then
                                    local part = dumpster:FindFirstChildOfClass("Part") or dumpster.PrimaryPart
                                    if not part then
                                        for _, child in ipairs(dumpster:GetDescendants()) do
                                            if child:IsA("BasePart") then part = child; break end
                                        end
                                    end
                                    if part then
                                        hrp.CFrame = CFrame.new(part.Position + Vector3.new(4, -2, 4))
                                        task.wait(0.5)
                                        local before = LocalPlayer:GetAttribute("Leaves") or 0
                                        local emptyRemote = getRemote("EmptyBackpack")
                                        if emptyRemote then emptyRemote:FireServer() end
                                        for _ = 1, 6 do
                                            task.wait(0.3)
                                            if (LocalPlayer:GetAttribute("Leaves") or 0) < before then break end
                                        end
                                        if (LocalPlayer:GetAttribute("Leaves") or 0) < before then
                                            Library:Notify({ Title = "Ivory", Description = "Sold leaves!", Type = "Success", Time = 2 })
                                        end
                                        task.wait(1); break
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

------------------------------------------------------------------------
--// AUTO DAILY
------------------------------------------------------------------------
task.spawn(function() while true do if _G.IvoryAutoDailyClaim then pcall(function() getRemote("DailyClaim"):FireServer() end) end; task.wait(60) end end)

------------------------------------------------------------------------
--// AUTO BUY BAG UPGRADES
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoBuyBag and not isLobby then
            pcall(function() buyBag(true) end)
        end
        task.wait(5)
    end
end)

------------------------------------------------------------------------
--// AUTO BUY HAND UPGRADES
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoBuyHand and not isLobby then
            pcall(function()
                local handUpgrades = {"Hold", "Dexterity", "Grasp"}
                for _, upg in ipairs(handUpgrades) do
                    buyUpgrade("Hand", upg, true)
                end
            end)
        end
        task.wait(5)
    end
end)

------------------------------------------------------------------------
--// AUTO BUY VENTS
------------------------------------------------------------------------
task.spawn(function()
    while true do
        if _G.IvoryAutoBuyVents and not isLobby then
            pcall(function() buyAllVents(true) end)
        end
        task.wait(10)
    end
end)

------------------------------------------------------------------------
--// ESP
------------------------------------------------------------------------
task.spawn(function()
    local espObjects = {}
    local function createESP(player)
        if player == LocalPlayer then return end
        espObjects[player] = { Box = Drawing.new("Square"), Name = Drawing.new("Text"), Health = Drawing.new("Text"), Distance = Drawing.new("Text") }
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
    Players.PlayerAdded:Connect(createESP); Players.PlayerRemoving:Connect(removeESP)
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
                        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if localHRP and (hrp.Position - localHRP.Position).Magnitude > (_G.IvoryESPRange or 1000) then esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Distance.Visible = false; return end
                        local rootPos = cam:WorldToViewportPoint(hrp.Position)
                        local headPos = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                        local height = math.abs(rootPos.Y - headPos.Y) * 2; local width = height / 2
                        if _G.IvoryBoxESP then esp.Box.Size = Vector2.new(width, height); esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2); esp.Box.Visible = true; esp.Box.Color = color else esp.Box.Visible = false end
                        if _G.IvoryNameESP then esp.Name.Text = player.DisplayName; esp.Name.Position = Vector2.new(pos.X, pos.Y - 20); esp.Name.Visible = true; esp.Name.Color = color else esp.Name.Visible = false end
                        if _G.IvoryHealthESP then local hp, maxHp = math.floor(hum.Health), math.floor(hum.MaxHealth); esp.Health.Text = hp.."/"..maxHp; esp.Health.Position = Vector2.new(pos.X, pos.Y + height/2 + 5); esp.Health.Visible = true; esp.Health.Color = Color3.fromRGB(255*(1-hp/maxHp), 255*(hp/maxHp), 0) else esp.Health.Visible = false end
                        if _G.IvoryDistanceESP and localHRP then esp.Distance.Text = math.floor((hrp.Position - localHRP.Position).Magnitude).."m"; esp.Distance.Position = Vector2.new(pos.X, pos.Y + height/2 + 20); esp.Distance.Visible = true; esp.Distance.Color = color else esp.Distance.Visible = false end
                    else esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Distance.Visible = false end
                else esp.Box.Visible = false; esp.Name.Visible = false; esp.Health.Visible = false; esp.Distance.Visible = false end
            end)
        end
    end)
end)

------------------------------------------------------------------------
--// LEAF ESP
------------------------------------------------------------------------
task.spawn(function()
    local leafBoxes = {}
    while true do
        pcall(function()
            for _, box in ipairs(leafBoxes) do pcall(function() box:Remove() end) end; leafBoxes = {}
            if _G.IvoryLeafESP then
                local fallen = Workspace:FindFirstChild("Leaves") or Workspace:FindFirstChild("Fallen leaves")
                if fallen then
                    local cam = Workspace.CurrentCamera
                    local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local color = _G.IvoryESPColor or Color3.fromRGB(0, 255, 0)
                    local range = _G.IvoryESPRange or 1000
                    for _, child in ipairs(fallen:GetChildren()) do
                        local pp = nil
                        if child:IsA("BasePart") then pp = child
                        elseif child:IsA("Model") then pp = child:FindFirstChildOfClass("Part") or child.PrimaryPart end
                        if pp then
                            if localHRP and (pp.Position - localHRP.Position).Magnitude > range then continue end
                            local pos, onScreen = cam:WorldToViewportPoint(pp.Position)
                            if onScreen then
                                local box = Drawing.new("Square")
                                box.Thickness = 1; box.Filled = true; box.Color = color; box.Transparency = 0.5
                                box.Size = Vector2.new(30, 30)
                                box.Position = Vector2.new(pos.X - 15, pos.Y - 15)
                                box.Visible = true
                                table.insert(leafBoxes, box)
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
--// VENT ESP
------------------------------------------------------------------------
task.spawn(function()
    local ventHighlights = {}
    while true do
        pcall(function()
            for _, h in ipairs(ventHighlights) do pcall(function() h:Remove() end) end; ventHighlights = {}
            if _G.IvoryVentESP and not isLobby then
                local ventsFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Vents")
                if ventsFolder then
                    local cam = Workspace.CurrentCamera
                    for _, vent in ipairs(ventsFolder:GetChildren()) do
                        if vent:IsA("BasePart") then
                            local unlocked = vent:GetAttribute("Unlocked")
                            local color = unlocked and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 100, 0)
                            local pos, onScreen = cam:WorldToViewportPoint(vent.Position)
                            if onScreen then
                                local txt = Drawing.new("Text")
                                txt.Size = 14; txt.Center = true; txt.Outline = true; txt.Color = color
                                txt.Text = unlocked and "VENT [OPEN]" or ("VENT [$" .. tostring(vent:GetAttribute("Cost") or 0) .. "]")
                                txt.Position = Vector2.new(pos.X, pos.Y - 20); txt.Visible = true
                                table.insert(ventHighlights, txt)
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
--// ZONE PROGRESS ESP
------------------------------------------------------------------------
task.spawn(function()
    local zoneTexts = {}
    while true do
        pcall(function()
            for _, t in ipairs(zoneTexts) do pcall(function() t:Remove() end) end; zoneTexts = {}
            if _G.IvoryZoneProgressESP and not isLobby then
                local cam = Workspace.CurrentCamera
                for zoneName, bounds in pairs(zoneBounds) do
                    local prog = getZoneProgress(zoneName)
                    if prog then
                        local pos, onScreen = cam:WorldToViewportPoint(bounds.center + Vector3.new(0, 15, 0))
                        if onScreen then
                            local txt = Drawing.new("Text")
                            txt.Size = 14; txt.Center = true; txt.Outline = true
                            txt.Color = prog.completed and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
                            txt.Text = zoneName .. (prog.completed and " [DONE]" or (" " .. tostring(prog.goal) .. " leaves"))
                            txt.Position = Vector2.new(pos.X, pos.Y); txt.Visible = true
                            table.insert(zoneTexts, txt)
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

------------------------------------------------------------------------
RunService.Heartbeat:Connect(function() pcall(function() local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid"); if hum then if _G.IvorySpeedHack and _G.IvorySpeedValue then hum.WalkSpeed = _G.IvorySpeedValue end; if _G.IvoryJumpHack and _G.IvoryJumpValue then hum.JumpPower = _G.IvoryJumpValue end end end) end)
RunService.Stepped:Connect(function() if _G.IvoryNoClip then pcall(function() local char = LocalPlayer.Character; if char then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end) end end)
task.spawn(function() local VirtualUser = game:GetService("VirtualUser"); LocalPlayer.Idled:Connect(function() if _G.IvoryAntiAFK then VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame); VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame) end end) end)
task.spawn(function() while true do if _G.IvoryAutoSave then pcall(function() SaveManager:SaveConfig() end) end; task.wait(30) end end)

------------------------------------------------------------------------
Library:Notify({ Title = "Ivory", Description = "Ivory Hub Loaded! PlaceId: " .. tostring(game.PlaceId), Type = "Success", Time = 5 })
print("[Ivory] Clean All The Leaves loaded | PlaceId: " .. tostring(game.PlaceId) .. " | v1.4")