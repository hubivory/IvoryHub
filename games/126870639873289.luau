--[[
    Ivory Hub - Jump for Animals
    PlaceId: 126870639873289
    Version: 1.4
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Settings = ReplicatedStorage:WaitForChild("Settings")

local cfg = {
    AutoTrain = false,
    AutoTrainBonus = false,
    AutoCollectEggs = false,
    AutoPlaceEggs = false,
    AutoHatchEggs = false,
    EggArea = "Meadow",
    WalkSpeed = 16,
    JumpPower = 25,
    NoClip = false,
    InfiniteJump = false,
    CustomSpeed = false,
    CustomJump = false,
    AutoSell = false,
    SellInterval = 1,
    AutoEquipBest = false,
    AutoClaimRewards = false,
    PlayerESP = false,
    EggESP = false,
    ESPDistance = 500,
    AntiAFK = false,
    MenuKeybind = "RightShift",
}

local isRunning = true
local espObjects = {}

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
    error("[Ivory] Failed to fetch library.")
end
if LIB_SRC:byte(1) == 0xEF and LIB_SRC:byte(2) == 0xBB and LIB_SRC:byte(3) == 0xBF then
    LIB_SRC = LIB_SRC:sub(4)
end
local Library = loadstring(LIB_SRC)()
if not Library then
    error("[Ivory] Failed to compile library")
end

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function getDetector()
    local plot = LocalPlayer:FindFirstChild("Plot")
    if plot and plot.Value then
        local sz = plot.Value:FindFirstChild("SquatZone")
        if sz then
            local fl = sz:FindFirstChild("Floor")
            if fl then
                return fl:FindFirstChild("Detector")
            end
        end
    end
    return nil
end

local function getCarriedEggCount()
    return LocalPlayer:GetAttribute("CarriedEggCount") or 0
end

local function getPlotPart()
    local plot = LocalPlayer:FindFirstChild("Plot")
    if plot and plot.Value then
        local plotModel = plot.Value
        local pp = plotModel:FindFirstChildWhichIsA("BasePart")
        if not pp then
            for _, c in ipairs(plotModel:GetChildren()) do
                if c:IsA("BasePart") then
                    pp = c
                    break
                end
            end
        end
        return pp
    end
    return nil
end

local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 720,
    Height = 800,
})

local Tabs = {
    Combat = Window:CreateTab({ Name = "Combat" }),
    Visuals = Window:CreateTab({ Name = "Visuals" }),
    World = Window:CreateTab({ Name = "World" }),
    Misc = Window:CreateTab({ Name = "Misc" }),
    ["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

local CombatSection = Tabs.Combat:CreateSection("training")
local EggSection = Tabs.Combat:CreateSection("eggs")
local TeleportSection = Tabs.Combat:CreateSection("teleports")
local ESPSection = Tabs.Visuals:CreateSection("esp")
local MovementSection = Tabs.World:CreateSection("movement")
local FarmSection = Tabs.World:CreateSection("farm")
local MiscSection = Tabs.Misc:CreateSection("miscellaneous")
local CreditsSection = Tabs["UI Settings"]:CreateSection("credits")
local MenuSection = Tabs["UI Settings"]:CreateSection("menu settings")
local ConfigSection = Tabs["UI Settings"]:CreateSection("configuration")

-- ==================== COMBAT TAB ====================

CombatSection:CreateToggle({
    Name = "Auto Train",
    CurrentValue = cfg.AutoTrain,
    Callback = function(value) cfg.AutoTrain = value end,
})

CombatSection:CreateToggle({
    Name = "Auto Train Bonus",
    CurrentValue = cfg.AutoTrainBonus,
    Callback = function(value) cfg.AutoTrainBonus = value end,
})

CombatSection:CreateButton({
    Name = "Start Training",
    Callback = function()
        local char, hrp = getChar()
        local detector = getDetector()
        if hrp and detector then
            hrp.CFrame = detector.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.3)
            Remotes.SquatTrainingRequest:FireServer(detector)
        end
    end,
})

CombatSection:CreateButton({
    Name = "Stop Training",
    Callback = function()
        Remotes.StopSquattingRequest:FireServer()
    end,
})

CombatSection:CreateButton({
    Name = "Claim Training Bonus",
    Callback = function()
        local version = tonumber(LocalPlayer:GetAttribute("SquatBonusVersion")) or 0
        Remotes.SquatBonusRequest:FireServer(version)
    end,
})

CombatSection:CreateButton({
    Name = "Teleport to Squat Zone",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end
        local detector = getDetector()
        if detector then
            hrp.CFrame = detector.CFrame + Vector3.new(0, 3, 0)
        end
    end,
})

CombatSection:CreateButton({
    Name = "Complete Tutorial",
    Callback = function()
        Remotes.Tutorial:FireServer("Complete")
    end,
})

-- Egg Section
EggSection:CreateDropdown({
    Name = "Egg Steal Area",
    Values = {"Meadow", "Coral Reef", "Winter", "Desert", "Crystal Mines", "Jungle", "Mystic Isles", "Prehistoric", "Celestial Heights", "Savannah"},
    CurrentOption = cfg.EggArea,
    Callback = function(value) cfg.EggArea = value end,
})

EggSection:CreateToggle({
    Name = "Auto Collect Eggs",
    CurrentValue = cfg.AutoCollectEggs,
    Callback = function(value) cfg.AutoCollectEggs = value end,
})

EggSection:CreateToggle({
    Name = "Auto Place Eggs",
    CurrentValue = cfg.AutoPlaceEggs,
    Callback = function(value) cfg.AutoPlaceEggs = value end,
})

EggSection:CreateToggle({
    Name = "Auto Hatch Eggs",
    CurrentValue = cfg.AutoHatchEggs,
    Callback = function(value) cfg.AutoHatchEggs = value end,
})

EggSection:CreateButton({
    Name = "Teleport to Nearest Egg",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end

        local stage = Workspace.Map.Stages:FindFirstChild(cfg.EggArea)
        if stage then
            local eggs = stage:FindFirstChild("SpawnedEggs")
            if eggs and #eggs:GetChildren() > 0 then
                local nearest, nearDist = nil, math.huge
                for _, egg in ipairs(eggs:GetChildren()) do
                    local root = egg:FindFirstChild("EggRoot")
                    if root then
                        local d = (hrp.Position - root.Position).Magnitude
                        if d < nearDist then
                            nearDist = d
                            nearest = root
                        end
                    end
                end
                if nearest then
                    hrp.CFrame = nearest.CFrame + Vector3.new(0, 3, 0)
                end
            end
        end
    end,
})

EggSection:CreateButton({
    Name = "Collect Nearest Egg",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end

        local stage = Workspace.Map.Stages:FindFirstChild(cfg.EggArea)
        if stage then
            local eggs = stage:FindFirstChild("SpawnedEggs")
            if eggs then
                for _, egg in ipairs(eggs:GetChildren()) do
                    local root = egg:FindFirstChild("EggRoot")
                    if root then
                        local attach = root:FindFirstChild("EggPromptAttachment")
                        if attach then
                            local prompt = attach:FindFirstChild("CollectPrompt")
                            if prompt and prompt.Enabled then
                                hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                                task.wait(0.3)
                                fireproximityprompt(prompt)
                                return
                            end
                        end
                    end
                end
            end
        end
    end,
})

EggSection:CreateButton({
    Name = "Place Egg on Plot",
    Callback = function()
        local Backpack = LocalPlayer:FindFirstChild("Backpack")
        local Plot = LocalPlayer:FindFirstChild("Plot")
        local plotModel = Plot and Plot.Value
        local region = plotModel and plotModel:FindFirstChild("Detector")
        if Backpack and region and region:IsA("BasePart") then
            for _, tool in ipairs(Backpack:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("IsEggTool") then
                    local eggId = tool:GetAttribute("EggId")
                    if eggId then
                        tool.Parent = LocalPlayer.Character
                        task.wait(0.3)
                        Remotes.PlaceEggRequest:FireServer(eggId, region.Position)
                        task.wait(0.8)
                        return
                    end
                end
            end
        end
    end,
})

EggSection:CreateButton({
    Name = "Return to Base",
    Callback = function() Remotes.ReturnToBaseRequest:FireServer() end,
})

-- Teleport Section
TeleportSection:CreateDropdown({
    Name = "Select Area",
    Values = {"Meadow", "Coral Reef", "Winter", "Desert", "Crystal Mines", "Jungle", "Mystic Isles", "Prehistoric", "Celestial Heights", "Savannah"},
    CurrentOption = "Meadow",
    Callback = function(value) cfg.SelectedArea = value end,
})

TeleportSection:CreateButton({
    Name = "Teleport to Area",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end
        local stage = Workspace.Map.Stages:FindFirstChild(cfg.SelectedArea)
        if stage then
            local spawners = stage:FindFirstChild("Spawners")
            if spawners and #spawners:GetChildren() > 0 then
                hrp.CFrame = spawners:GetChildren()[1].CFrame + Vector3.new(0, 5, 0)
            end
        end
    end,
})

TeleportSection:CreateButton({
    Name = "Teleport to Sell",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end
        local sell = Workspace.Map:FindFirstChild("Sell")
        if sell then
            hrp.CFrame = sell.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

TeleportSection:CreateButton({
    Name = "Teleport to Discord NPC",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end
        local discord = Workspace.Map:FindFirstChild("Discord")
        if discord then
            hrp.CFrame = discord.CFrame + Vector3.new(0, 3, 0)
        end
    end,
})

-- ==================== VISUALS TAB ====================

ESPSection:CreateToggle({
    Name = "Player ESP",
    CurrentValue = cfg.PlayerESP,
    Callback = function(value) cfg.PlayerESP = value end,
})

ESPSection:CreateToggle({
    Name = "Egg ESP",
    CurrentValue = cfg.EggESP,
    Callback = function(value) cfg.EggESP = value end,
})

ESPSection:CreateSlider({
    Name = "ESP Distance",
    Min = 100,
    Max = 2000,
    CurrentValue = cfg.ESPDistance,
    Callback = function(value) cfg.ESPDistance = value end,
})

-- ==================== WORLD TAB ====================

MovementSection:CreateToggle({
    Name = "Custom Walk Speed",
    CurrentValue = cfg.CustomSpeed,
    Callback = function(value) cfg.CustomSpeed = value end,
})

MovementSection:CreateSlider({
    Name = "Walk Speed",
    Min = 16,
    Max = 200,
    CurrentValue = cfg.WalkSpeed,
    Callback = function(value) cfg.WalkSpeed = value end,
})

MovementSection:CreateToggle({
    Name = "Custom Jump Power",
    CurrentValue = cfg.CustomJump,
    Callback = function(value) cfg.CustomJump = value end,
})

MovementSection:CreateSlider({
    Name = "Jump Power",
    Min = 25,
    Max = 1000,
    CurrentValue = cfg.JumpPower,
    Callback = function(value) cfg.JumpPower = value end,
})

MovementSection:CreateToggle({
    Name = "No Clip",
    CurrentValue = cfg.NoClip,
    Callback = function(value) cfg.NoClip = value end,
})

MovementSection:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = cfg.InfiniteJump,
    Callback = function(value) cfg.InfiniteJump = value end,
})

-- Farm Section
FarmSection:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = cfg.AutoSell,
    Callback = function(value) cfg.AutoSell = value end,
})

FarmSection:CreateSlider({
    Name = "Sell Interval",
    Min = 0.5,
    Max = 5,
    CurrentValue = cfg.SellInterval,
    Callback = function(value) cfg.SellInterval = value end,
})

FarmSection:CreateToggle({
    Name = "Auto Equip Best Pets",
    CurrentValue = cfg.AutoEquipBest,
    Callback = function(value) cfg.AutoEquipBest = value end,
})

FarmSection:CreateToggle({
    Name = "Auto Claim Group Reward",
    CurrentValue = cfg.AutoClaimRewards,
    Callback = function(value) cfg.AutoClaimRewards = value end,
})

FarmSection:CreateButton({
    Name = "Claim Offline Rewards",
    Callback = function() Remotes.OfflineRewards:FireServer("Claim") end,
})

FarmSection:CreateButton({
    Name = "Equip Best Pets",
    Callback = function() Remotes.PetInventory:FireServer("EquipBest") end,
})

FarmSection:CreateButton({
    Name = "Slap Hand",
    Callback = function() Remotes.SlapHand:FireServer() end,
})

-- ==================== MISC TAB ====================

MiscSection:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = cfg.AntiAFK,
    Callback = function(value) cfg.AntiAFK = value end,
})

MiscSection:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscSection:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        if servers and servers.data and #servers.data > 0 then
            local jobId = servers.data[math.random(1, #servers.data)].id
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end
    end,
})

-- ==================== UI SETTINGS TAB ====================

CreditsSection:CreateLabel({Text = "Ivory Hub v1.4 | Jump for Animals"})
CreditsSection:CreateLabel({Text = "UserId: " .. LocalPlayer.UserId})

CreditsSection:CreateButton({
    Name = "Join Discord For Dupe",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/ivory")
        end
        Library.Notify({Title = "Ivory", Content = "Discord link copied to clipboard!", Type = "Success", Duration = 3})
    end,
})

MenuSection:CreateKeybind({
    Name = "Menu Keybind",
    CurrentKeybind = cfg.MenuKeybind,
    Callback = function(key) cfg.MenuKeybind = key end,
})

MenuSection:CreateButton({
    Name = "Test Notification",
    Callback = function()
        Library.Notify({Title = "Ivory", Content = "This is a test notification!", Type = "Info", Duration = 3})
    end,
})

MenuSection:CreateButton({
    Name = "Unload Script",
    Callback = function()
        Library:Unload()
    end,
})

ConfigSection:CreateButton({
    Name = "Save Config",
    Callback = function()
        if writefile then
            writefile("IvoryHub/JFA_Config.json", HttpService:JSONEncode(cfg))
        end
        Library.Notify({Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 2})
    end,
})

ConfigSection:CreateButton({
    Name = "Load Config",
    Callback = function()
        if readfile and isfile and isfile("IvoryHub/JFA_Config.json") then
            local loaded = HttpService:JSONDecode(readfile("IvoryHub/JFA_Config.json"))
            for k, v in pairs(loaded) do
                cfg[k] = v
            end
            Library.Notify({Title = "Ivory", Content = "Config loaded! Toggle values to refresh.", Type = "Success", Duration = 2})
        end
    end,
})

-- ==================== MAIN LOOPS ====================

-- Auto Train: teleport to detector and fire with detector argument
-- Training only works after tutorial step "ReachTrain" or "Train", or after TutorialCompleted
task.spawn(function()
    while isRunning do
        if cfg.AutoTrain then
            local completed = LocalPlayer:GetAttribute("TutorialCompleted") == true
            local step = LocalPlayer:GetAttribute("TutorialStep")
            local canTrain = completed or step == "ReachTrain" or step == "Train"

            if canTrain then
                local detector = getDetector()
                if detector then
                    local char, hrp = getChar()
                    if hrp and LocalPlayer:GetAttribute("IsSquatting") ~= true then
                        hrp.CFrame = detector.CFrame + Vector3.new(0, 2, 0)
                        task.wait(0.3)
                    end
                    Remotes.SquatTrainingRequest:FireServer(detector)
                end
            end
        end
        task.wait(0.5)
    end
end)

-- Auto Train Bonus: claims the 2x bonus when it appears during training
-- Must pass SquatBonusVersion to the remote
task.spawn(function()
    while isRunning do
        if cfg.AutoTrainBonus then
            local bonusAvailable = LocalPlayer:GetAttribute("SquatBonusAvailable") == true
            if bonusAvailable then
                local version = tonumber(LocalPlayer:GetAttribute("SquatBonusVersion")) or 0
                Remotes.SquatBonusRequest:FireServer(version)
            end
        end
        task.wait(0.5)
    end
end)

-- Auto Collect Eggs: teleport to egg, grab it, teleport to plot, return to base
task.spawn(function()
    while isRunning do
        if cfg.AutoCollectEggs then
            local char, hrp = getChar()
            if hrp then
                local stage = Workspace.Map.Stages:FindFirstChild(cfg.EggArea)
                if stage then
                    local eggs = stage:FindFirstChild("SpawnedEggs")
                    if eggs then
                        for _, egg in ipairs(eggs:GetChildren()) do
                            if not isRunning or not cfg.AutoCollectEggs then break end

                            local root = egg:FindFirstChild("EggRoot")
                            if root then
                                local attach = root:FindFirstChild("EggPromptAttachment")
                                if attach then
                                    local prompt = attach:FindFirstChild("CollectPrompt")
                                    if prompt and prompt.Enabled then
                                        -- Teleport to egg
                                        hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                                        task.wait(0.3)

                                        -- Collect egg
                                        fireproximityprompt(prompt)
                                        task.wait(0.5)

                                        -- ReturnToBase only works near the plot, teleport there first
                                        if getCarriedEggCount() > 0 then
                                            local pp = getPlotPart()
                                            if pp then
                                                hrp.CFrame = pp.CFrame + Vector3.new(0, 5, 0)
                                                task.wait(0.5)
                                            end
                                            Remotes.ReturnToBaseRequest:FireServer()
                                            task.wait(1.5)
                                        end

                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Auto Tutorial Progressor: auto-advances tutorial steps
task.spawn(function()
    while isRunning do
        local completed = LocalPlayer:GetAttribute("TutorialCompleted") == true
        local step = LocalPlayer:GetAttribute("TutorialStep")

        if not completed and step then
            local char, hrp, hum = getChar()

            if step == "ReachEgg" or step == "GrabEgg" then
                -- Auto grab egg from Meadow
                if hrp then
                    local stage = Workspace.Map.Stages:FindFirstChild("Meadow")
                    if stage then
                        local eggs = stage:FindFirstChild("SpawnedEggs")
                        if eggs then
                            for _, egg in ipairs(eggs:GetChildren()) do
                                local root = egg:FindFirstChild("EggRoot")
                                if root then
                                    local attach = root:FindFirstChild("EggPromptAttachment")
                                    if attach then
                                        local prompt = attach:FindFirstChild("CollectPrompt")
                                        if prompt and prompt.Enabled then
                                            hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
                                            task.wait(0.5)
                                            fireproximityprompt(prompt)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

            elseif step == "ReturnStart" or step == "ReachPlot" or step == "PlaceEgg" then
                -- Must teleport to plot before ReturnToBase (server requires proximity)
                if hrp then
                    local pp = getPlotPart()
                    if pp then
                        hrp.CFrame = pp.CFrame + Vector3.new(0, 5, 0)
                        task.wait(0.5)
                    end
                end
                Remotes.ReturnToBaseRequest:FireServer()
                task.wait(2)

            elseif step == "WaitEggReady" then
                -- Wait for egg to incubate
                task.wait(3)

            elseif step == "HatchEgg" then
                -- Try to hatch by waiting
                task.wait(2)

            elseif step == "ReachTrails" then
                -- Click the Buy button on Blue Trail in the trail shop GUI
                local trailsPage = LocalPlayer.PlayerGui:FindFirstChild("UI")
                if trailsPage then
                    trailsPage = trailsPage:FindFirstChild("Pages")
                    if trailsPage then
                        trailsPage = trailsPage:FindFirstChild("Trails")
                        if trailsPage then
                            local main = trailsPage:FindFirstChild("Main")
                            if main then
                                local frame = main:FindFirstChild("ScrollingFrame")
                                if frame then
                                    local blueTrail = frame:FindFirstChild("Blue Trail")
                                    if blueTrail then
                                        local buyBtn = blueTrail:FindFirstChild("Buy")
                                        if buyBtn then
                                            buyBtn.Activated:Fire()
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(1)

            elseif step == "ReachTrain" then
                -- Teleport to squat zone
                if hrp then
                    local detector = getDetector()
                    if detector then
                        hrp.CFrame = detector.CFrame + Vector3.new(0, 3, 0)
                    end
                end
                task.wait(1)

            elseif step == "Train" then
                -- Start training
                local detector = getDetector()
                if detector then
                    Remotes.SquatTrainingRequest:FireServer(detector)
                end
                task.wait(3)
            end
        end

        task.wait(1)
    end
end)

-- Auto Place Eggs: equips each egg tool and fires PlaceEggRequest with EggId + position
task.spawn(function()
    while isRunning do
        if cfg.AutoPlaceEggs then
            local Backpack = LocalPlayer:FindFirstChild("Backpack")
            local Plot = LocalPlayer:FindFirstChild("Plot")
            local plotModel = Plot and Plot.Value
            local region = plotModel and plotModel:FindFirstChild("Detector")
            if Backpack and region and region:IsA("BasePart") then
                for _, tool in ipairs(Backpack:GetChildren()) do
                    if not isRunning or not cfg.AutoPlaceEggs then break end
                    if tool:IsA("Tool") and tool:GetAttribute("IsEggTool") then
                        local eggId = tool:GetAttribute("EggId")
                        if eggId then
                            -- Server requires tool to be equipped
                            tool.Parent = LocalPlayer.Character
                            task.wait(0.3)
                            Remotes.PlaceEggRequest:FireServer(eggId, region.Position)
                            task.wait(0.8)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Auto Hatch Eggs: teleports to each placed egg with HatchReady and fires its HatchPrompt
task.spawn(function()
    while isRunning do
        if cfg.AutoHatchEggs then
            local char, hrp = getChar()
            local Plot = LocalPlayer:FindFirstChild("Plot")
            local plotModel = Plot and Plot.Value
            local placedEggs = plotModel and plotModel:FindFirstChild("PlacedEggs")
            if hrp and placedEggs then
                for _, egg in ipairs(placedEggs:GetChildren()) do
                    if not isRunning or not cfg.AutoHatchEggs then break end
                    if egg:GetAttribute("HatchReady") == true and egg:GetAttribute("HatchOpening") ~= true then
                        local hatchPrompt = egg:FindFirstChild("HatchPrompt", true)
                        if hatchPrompt and hatchPrompt:IsA("ProximityPrompt") and hatchPrompt.Enabled then
                            local root = egg:FindFirstChild("HumanoidRootPart") or egg:FindFirstChildWhichIsA("BasePart")
                            if root then
                                hrp.CFrame = root.CFrame + Vector3.new(0, 2, 0)
                                task.wait(0.3)
                                fireproximityprompt(hatchPrompt)
                                task.wait(1)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end)

-- Auto Sell
task.spawn(function()
    while isRunning do
        if cfg.AutoSell then
            Remotes.Sell:FireServer()
        end
        task.wait(cfg.SellInterval)
    end
end)

-- Auto Equip Best Pets
task.spawn(function()
    while isRunning do
        if cfg.AutoEquipBest then
            Remotes.PetInventory:FireServer("EquipBest")
        end
        task.wait(5)
    end
end)

-- Auto Claim Group Reward
task.spawn(function()
    while isRunning do
        if cfg.AutoClaimRewards then
            Remotes.GroupReward:FireServer()
        end
        task.wait(10)
    end
end)

-- Movement
RunService.Heartbeat:Connect(function()
    if not isRunning then return end
    local char, hrp, hum = getChar()
    if not hum then return end

    if cfg.CustomSpeed then
        hum.WalkSpeed = cfg.WalkSpeed
    end
    if cfg.CustomJump then
        hum.UseJumpPower = true
        hum.JumpPower = cfg.JumpPower
    end
    if cfg.NoClip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if cfg.InfiniteJump then
        local char, hrp, hum = getChar()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Anti AFK
task.spawn(function()
    while isRunning do
        if cfg.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
        task.wait(60)
    end
end)

-- ESP
task.spawn(function()
    while isRunning do
        for _, esp in ipairs(espObjects) do
            pcall(function() esp:Destroy() end)
        end
        espObjects = {}

        local char, hrp = getChar()
        if hrp then
            if cfg.PlayerESP then
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                        if targetHRP and (hrp.Position - targetHRP.Position).Magnitude <= cfg.ESPDistance then
                            local h = Instance.new("Highlight")
                            h.FillColor = Color3.fromRGB(0, 255, 0)
                            h.OutlineColor = Color3.fromRGB(255, 255, 255)
                            h.FillTransparency = 0.5
                            h.Adornee = player.Character
                            h.Parent = player.Character
                            table.insert(espObjects, h)
                        end
                    end
                end
            end

            if cfg.EggESP then
                for _, stage in ipairs(Workspace.Map.Stages:GetChildren()) do
                    local eggs = stage:FindFirstChild("SpawnedEggs")
                    if eggs then
                        for _, egg in ipairs(eggs:GetChildren()) do
                            local root = egg:FindFirstChild("EggRoot")
                            if root and (hrp.Position - root.Position).Magnitude <= cfg.ESPDistance then
                                local h = Instance.new("Highlight")
                                h.FillColor = Color3.fromRGB(255, 255, 0)
                                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                                h.FillTransparency = 0.5
                                h.Adornee = root
                                h.Parent = root
                                table.insert(espObjects, h)
                            end
                        end
                    end
                end
            end
        end

        task.wait(1)
    end
end)

-- Initialize
Library.Notify({Title = "Ivory", Content = "Ivory Hub loaded!", Type = "Success", Duration = 5})

return Library