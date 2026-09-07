local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local REvents = ReplicatedStorage:WaitForChild("rEvents")
local orbEvent = REvents:WaitForChild("orbEvent")
local hoopEvent = REvents:WaitForChild("hoopEvent")
local rebirthEvent = REvents:WaitForChild("rebirthEvent")
local openCrystalRemote = REvents:WaitForChild("openCrystalRemote")
local changeSpeedJumpRemote = REvents:WaitForChild("changeSpeedJumpRemote")
local raceEvent = REvents:WaitForChild("raceEvent")
local questsEvent = REvents:WaitForChild("questsEvent")
local openFortuneWheelRemote = REvents:WaitForChild("openFortuneWheelRemote")
local freeGiftClaimRemote = REvents:WaitForChild("freeGiftClaimRemote")

local dataLoaded = LP:WaitForChild("dataLoaded")
repeat task.wait() until dataLoaded.Value == true

local character = LP.Character or LP.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

LP.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    hrp = char:WaitForChild("HumanoidRootPart")
end)

local currentMap = LP:WaitForChild("currentMap")
local orbFolder = Workspace:WaitForChild("orbFolder")
local hoopsFolder = Workspace:WaitForChild("Hoops")
local mapCrystalsFolder = Workspace:WaitForChild("mapCrystalsFolder")
local raceInProgress = ReplicatedStorage:WaitForChild("raceInProgress")
local raceStarted = ReplicatedStorage:WaitForChild("raceStarted")
local fortuneWheelChances = ReplicatedStorage:WaitForChild("fortuneWheelChances")

local globalFunctions
do
    globalFunctions = require(ReplicatedStorage:WaitForChild("globalFunctions"))
end

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local State = {
    AutoFarmSpeed = false,
    AutoFarmGems = false,
    AutoFarmXp = false,
    AutoFarmHoops = false,
    AutoRebirth = false,
    AutoBuyEggs = false,
    AutoJoinRace = false,
    AutoWinRace = false,
    AutoClaimQuests = false,
    AutoSpinWheel = false,
    AutoClaimGifts = false,
    Fly = false,
    Noclip = false,
    AntiAFK = false,
    FlySpeed = 50,
    FarmDelay = 0.10,
    BuyEggDelay = 1,
    SelectedCrystal = "Blue Crystal",
}

local flyBodyVel, flyBodyGyro
local noclipConn
local afkConn

-- ═══════════════════════════════════════════════════════════════
-- IVORY HUB
-- ═══════════════════════════════════════════════════════════════
local Library = loadstring(game:HttpGet("https://ivoryy.web.app/IvoryHubLibrary.lua"))()
local Window = Library.CreateWindow({ Name = "Legends of Speed", ConfigurationSaving = { Enabled = true, FolderName = "LegendsOfSpeed", FileName = "Config" } })

-- ═══════════════════════════════════════════════════════════════
-- TYPEWRITER HELPER
-- ═══════════════════════════════════════════════════════════════
local function typewriterLabel(labelObj, text, color, speed)
    spawn(function()
        local textLabel = labelObj.Instance:FindFirstChild("LabelText", true)
        if textLabel and color then
            textLabel.RichText = true
            textLabel.TextColor3 = color
        end
        labelObj:Set("")
        for i = 1, #text do
            labelObj:Set(string.sub(text, 1, i))
            task.wait(speed or 0.03)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- UTILITY
-- ═══════════════════════════════════════════════════════════════
local function getCharacter()
    if character and hrp and hrp.Parent then
        return character, hrp, humanoid
    end
    return nil, nil, nil
end

local function getMapOrbs()
    local map = currentMap.Value
    local folder = orbFolder:FindFirstChild(map)
    if folder then
        return folder:GetChildren()
    end
    return {}
end

local function getHoopParts()
    return hoopsFolder:GetChildren()
end

local function getCrystalNames()
    local names = {}
    for _, v in ipairs(mapCrystalsFolder:GetChildren()) do
        table.insert(names, v.Name)
    end
    return names
end

local function getRequiredRebirthLevel()
    local rebirths = LP:WaitForChild("leaderstats"):WaitForChild("Rebirths").Value
    return globalFunctions.calculateRequiredRebirthLevel(rebirths, LP)
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO FARM - collect orbs by teleporting through them
-- ═══════════════════════════════════════════════════════════════
local function farmOrbs(filterType)
    local _, rootPart = getCharacter()
    if not rootPart then return end

    local orbs = getMapOrbs()
    for _, orb in ipairs(orbs) do
        if not (State.AutoFarmSpeed or State.AutoFarmGems or State.AutoFarmXp) then break end

        local primary = orb.PrimaryPart
        if primary and orb.Parent then
            local shouldCollect = false
            if filterType == "speed" and (orb.Name == "Red Orb" or orb.Name == "Orange Orb" or orb.Name == "Blue Orb" or orb.Name == "Ethereal Orb") then
                shouldCollect = true
            elseif filterType == "gems" and (orb.Name == "Gem" or orb.Name == "Infernal Gem") then
                shouldCollect = true
            elseif filterType == "xp" and orb.Name == "Yellow Orb" then
                shouldCollect = true
            end

            if shouldCollect then
                rootPart.CFrame = primary.CFrame + Vector3.new(0, 3, 0)
                task.wait(State.FarmDelay)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO FARM HOOPS
-- ═══════════════════════════════════════════════════════════════
local function farmHoops()
    local _, rootPart = getCharacter()
    if not rootPart then return end

    local hoops = getHoopParts()
    for _, hoop in ipairs(hoops) do
        if not State.AutoFarmHoops then break end

        if hoop:IsA("BasePart") and hoop.Parent then
            local offset = hoop.CFrame.LookVector * 5
            rootPart.CFrame = hoop.CFrame + offset
            task.wait(State.FarmDelay)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO REBIRTH
-- ═══════════════════════════════════════════════════════════════
local function autoRebirth()
    local level = LP:WaitForChild("level").Value
    local required = getRequiredRebirthLevel()
    if required and level >= required then
        rebirthEvent:FireServer("rebirthRequest")
        task.wait(1)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO BUY EGGS (CRYSTALS)
-- ═══════════════════════════════════════════════════════════════
local function autoBuyEggs()
    local crystalName = State.SelectedCrystal
    local crystal = mapCrystalsFolder:FindFirstChild(crystalName)
    if crystal then
        openCrystalRemote:InvokeServer("openCrystal", crystalName)
        task.wait(State.BuyEggDelay)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO JOIN RACE - presses yes and joins
-- ═══════════════════════════════════════════════════════════════
local hasJoinedCurrentRace = false

local function autoJoinRace()
    if raceInProgress.Value == true and raceStarted.Value == false and not hasJoinedCurrentRace then
        hasJoinedCurrentRace = true
        raceEvent:FireServer("joinRace")
    end
    if raceStarted.Value == true or raceInProgress.Value == false then
        hasJoinedCurrentRace = false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO WIN RACE - teleport to finish when countdown ends
-- ═══════════════════════════════════════════════════════════════
local hasWonCurrentRace = false

local function autoWinRace()
    local _, rootPart = getCharacter()
    if not rootPart then return end

    if raceStarted.Value == true and not hasWonCurrentRace then
        hasWonCurrentRace = true
        local raceMaps = Workspace:FindFirstChild("raceMaps")
        if raceMaps then
            for _, map in ipairs(raceMaps:GetChildren()) do
                local finishPart = map:FindFirstChild("finishPart")
                if finishPart then
                    rootPart.CFrame = finishPart.CFrame + Vector3.new(0, 5, 0)
                    task.wait(0.1)
                end
            end
        end
    end
    if raceStarted.Value == false then
        hasWonCurrentRace = false
    end
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO CLAIM QUESTS
-- ═══════════════════════════════════════════════════════════════
local function autoClaimQuests()
    pcall(function()
        questsEvent:FireServer("seenQuest", "dailyQuests")
        questsEvent:FireServer("seenQuest", "weeklyQuests")
        questsEvent:FireServer("seenQuest", "storyQuests")
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO SPIN FORTUNE WHEEL
-- ═══════════════════════════════════════════════════════════════
local function autoSpinWheel()
    pcall(function()
        local fw = fortuneWheelChances:FindFirstChild("Fortune Wheel")
        if fw then
            openFortuneWheelRemote:InvokeServer("openFortuneWheel", fw)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- AUTO CLAIM FREE GIFTS
-- ═══════════════════════════════════════════════════════════════
local function autoClaimGifts()
    pcall(function()
        local giftNumber = LP:FindFirstChild("giftNumber")
        if giftNumber then
            freeGiftClaimRemote:InvokeServer("claimGift", giftNumber.Value)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════════════════════════
local function startFly()
    local _, rootPart = getCharacter()
    if not rootPart then return end

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVel.Velocity = Vector3.zero
    flyBodyVel.Parent = rootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 9000
    flyBodyGyro.D = 500
    flyBodyGyro.Parent = rootPart
end

local function stopFly()
    if flyBodyVel then flyBodyVel:Destroy() flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════════════════
local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then noclipConn:Disconnect() noclipConn = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- ANTI AFK
-- ═══════════════════════════════════════════════════════════════
local function startAntiAFK()
    afkConn = LP.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

local function stopAntiAFK()
    if afkConn then afkConn:Disconnect() afkConn = nil end
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════════════════
spawn(function()
    while task.wait(0.1) do
        pcall(function()
            if State.Fly then
                local cam = Workspace.CurrentCamera
                local _, rootPart = getCharacter()
                if rootPart and flyBodyVel and flyBodyGyro then
                    local moveDir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                    if moveDir.Magnitude > 0 then
                        flyBodyVel.Velocity = moveDir.Unit * State.FlySpeed
                    else
                        flyBodyVel.Velocity = Vector3.zero
                    end
                    flyBodyGyro.CFrame = cam.CFrame
                end
            end
        end)
    end
end)

spawn(function()
    while task.wait(0.3) do
        pcall(function()
            if State.AutoFarmSpeed then farmOrbs("speed") end
        end)
        pcall(function()
            if State.AutoFarmGems then farmOrbs("gems") end
        end)
        pcall(function()
            if State.AutoFarmXp then farmOrbs("xp") end
        end)
        pcall(function()
            if State.AutoFarmHoops then farmHoops() end
        end)
        pcall(function()
            if State.AutoRebirth then autoRebirth() end
        end)
        pcall(function()
            if State.AutoBuyEggs then autoBuyEggs() end
        end)
        pcall(function()
            if State.AutoJoinRace then autoJoinRace() end
        end)
        pcall(function()
            if State.AutoWinRace then autoWinRace() end
        end)
        pcall(function()
            if State.AutoClaimQuests then autoClaimQuests() end
        end)
        pcall(function()
            if State.AutoSpinWheel then autoSpinWheel() end
        end)
        pcall(function()
            if State.AutoClaimGifts then autoClaimGifts() end
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- UI - MAIN TAB
-- ═══════════════════════════════════════════════════════════════
local MainTab = Window:CreateTab("Main")

local discordLabel = MainTab:CreateLabel("")
typewriterLabel(discordLabel, "Join Discord For Free Keys", Color3.fromRGB(170, 85, 255), 0.04)

MainTab:CreateButton({
    Name = "Copy Discord Link",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/HCW5Nr3t5F")
        elseif toclipboard then
            toclipboard("https://discord.gg/HCW5Nr3t5F")
        end
    end,
})

MainTab:CreateDivider()

MainTab:CreateSection("Auto Farm")

MainTab:CreateToggle({
    Name = "Auto Farm Speed",
    CurrentValue = false,
    Flag = "AutoFarmSpeed",
    Callback = function(value)
        State.AutoFarmSpeed = value
    end,
})

MainTab:CreateToggle({
    Name = "Auto Farm Gems",
    CurrentValue = false,
    Flag = "AutoFarmGems",
    Callback = function(value)
        State.AutoFarmGems = value
    end,
})

MainTab:CreateToggle({
    Name = "Auto Farm XP",
    CurrentValue = false,
    Flag = "AutoFarmXp",
    Callback = function(value)
        State.AutoFarmXp = value
    end,
})

MainTab:CreateToggle({
    Name = "Auto Farm Hoops",
    CurrentValue = false,
    Flag = "AutoFarmHoops",
    Callback = function(value)
        State.AutoFarmHoops = value
    end,
})

MainTab:CreateSlider({
    Name = "Farm Delay",
    Range = {0.10, 0.50},
    Increment = 0.01,
    Suffix = "s",
    CurrentValue = 0.10,
    Flag = "FarmDelay",
    Callback = function(value)
        State.FarmDelay = value
    end,
})

MainTab:CreateDivider()

MainTab:CreateSection("Auto Rebirth")

MainTab:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(value)
        State.AutoRebirth = value
    end,
})

MainTab:CreateDivider()

MainTab:CreateSection("Auto Buy Eggs")

local crystalNames = getCrystalNames()
MainTab:CreateDropdown({
    Name = "Select Crystal",
    Options = crystalNames,
    CurrentOption = { "Blue Crystal" },
    Flag = "SelectedCrystal",
    Callback = function(option)
        State.SelectedCrystal = option
    end,
})

MainTab:CreateToggle({
    Name = "Auto Buy Eggs",
    CurrentValue = false,
    Flag = "AutoBuyEggs",
    Callback = function(value)
        State.AutoBuyEggs = value
    end,
})

MainTab:CreateSlider({
    Name = "Buy Delay",
    Range = {0.5, 5},
    Increment = 0.5,
    Suffix = "s",
    CurrentValue = 1,
    Flag = "BuyEggDelay",
    Callback = function(value)
        State.BuyEggDelay = value
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- UI - RACES TAB
-- ═══════════════════════════════════════════════════════════════
local RacesTab = Window:CreateTab("Races")

RacesTab:CreateSection("Race Automation")

RacesTab:CreateToggle({
    Name = "Auto Join Race",
    CurrentValue = false,
    Flag = "AutoJoinRace",
    Callback = function(value)
        State.AutoJoinRace = value
    end,
})

RacesTab:CreateToggle({
    Name = "Auto Win Race (Teleport to Finish)",
    CurrentValue = false,
    Flag = "AutoWinRace",
    Callback = function(value)
        State.AutoWinRace = value
    end,
})

RacesTab:CreateDivider()

RacesTab:CreateSection("Teleport to Race Map")

RacesTab:CreateButton({
    Name = "Teleport to Grassland Race",
    Callback = function()
        local _, rootPart = getCharacter()
        if rootPart then
            rootPart.CFrame = CFrame.new(-782.36, 1.21, -5923.33)
        end
    end,
})

RacesTab:CreateButton({
    Name = "Teleport to Desert Race",
    Callback = function()
        local _, rootPart = getCharacter()
        if rootPart then
            rootPart.CFrame = CFrame.new(-782.36, 1.21, -8568.33)
        end
    end,
})

RacesTab:CreateButton({
    Name = "Teleport to Magma Race",
    Callback = function()
        local _, rootPart = getCharacter()
        if rootPart then
            rootPart.CFrame = CFrame.new(-782.36, 1.21, -10781.34)
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- UI - REWARDS TAB
-- ═══════════════════════════════════════════════════════════════
local RewardsTab = Window:CreateTab("Rewards")

RewardsTab:CreateSection("Auto Claim")

RewardsTab:CreateToggle({
    Name = "Auto Claim Quests",
    CurrentValue = false,
    Flag = "AutoClaimQuests",
    Callback = function(value)
        State.AutoClaimQuests = value
    end,
})

RewardsTab:CreateToggle({
    Name = "Auto Spin Fortune Wheel",
    CurrentValue = false,
    Flag = "AutoSpinWheel",
    Callback = function(value)
        State.AutoSpinWheel = value
    end,
})

RewardsTab:CreateToggle({
    Name = "Auto Claim Free Gifts",
    CurrentValue = false,
    Flag = "AutoClaimGifts",
    Callback = function(value)
        State.AutoClaimGifts = value
    end,
})

RewardsTab:CreateButton({
    Name = "Spin Fortune Wheel Once",
    Callback = function()
        autoSpinWheel()
    end,
})

RewardsTab:CreateButton({
    Name = "Claim Free Gift Once",
    Callback = function()
        autoClaimGifts()
    end,
})

RewardsTab:CreateButton({
    Name = "Claim All Quests Once",
    Callback = function()
        autoClaimQuests()
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- UI - TELEPORT TAB
-- ═══════════════════════════════════════════════════════════════
local TeleportTab = Window:CreateTab("Teleport")

TeleportTab:CreateSection("World Areas")

local worldAreas = {
    { name = "City", pos = CFrame.new(-9682.99, 74.85, 3099.03) },
    { name = "Snow City", pos = CFrame.new(-9676.14, 74.85, 3782.69) },
    { name = "Magma City", pos = CFrame.new(-11054.97, 232.79, 4898.63) },
    { name = "Legends Highway", pos = CFrame.new(-13098.87, 232.79, 5907.63) },
    { name = "Speed Jungle", pos = CFrame.new(-15273.23, 414.15, 5573.19) },
}

for _, area in ipairs(worldAreas) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. area.name,
        Callback = function()
            local _, rootPart = getCharacter()
            if rootPart then
                rootPart.CFrame = area.pos
            end
        end,
    })
end

TeleportTab:CreateDivider()

TeleportTab:CreateSection("Courses")

local courses = {
    { name = "Grass Course", pos = CFrame.new(-835.16, 32.79, 126.26) },
    { name = "Frost Course", pos = CFrame.new(370.31, 21.90, -21.82) },
    { name = "Pirate Course", pos = CFrame.new(-923.32, 44.30, 2822.18) },
    { name = "Parkour Challenge", pos = CFrame.new(-336.97, 90.80, -254.55) },
}

for _, course in ipairs(courses) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. course.name,
        Callback = function()
            local _, rootPart = getCharacter()
            if rootPart then
                rootPart.CFrame = course.pos
            end
        end,
    })
end

TeleportTab:CreateDivider()

TeleportTab:CreateSection("Caves & Dungeons")

local caves = {
    { name = "Mysterious Cave", pos = CFrame.new(-791.24, 19.65, 578.63) },
    { name = "Inferno Cave", pos = CFrame.new(-121.54, 19.65, 2568.01) },
    { name = "Electro Cave", pos = CFrame.new(3643.64, 87.25, 5591.08) },
    { name = "Jungle Cave", pos = CFrame.new(3517.46, 233.83, 7246.21) },
}

for _, cave in ipairs(caves) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. cave.name,
        Callback = function()
            local _, rootPart = getCharacter()
            if rootPart then
                rootPart.CFrame = cave.pos
            end
        end,
    })
end

TeleportTab:CreateDivider()

TeleportTab:CreateSection("Crystal / Egg Locations")

local crystals = {
    { name = "Blue Crystal", pos = CFrame.new(-576.38, 6.00, 499.09) },
    { name = "Red Crystal", pos = CFrame.new(-649.47, 6.10, 256.98) },
    { name = "Purple Crystal", pos = CFrame.new(-436.15, 6.00, 202.08) },
    { name = "Yellow Crystal", pos = CFrame.new(-300.78, 6.00, -371.91) },
    { name = "Snow Crystal", pos = CFrame.new(-334.82, 6.00, 2254.54) },
    { name = "Lightning Crystal", pos = CFrame.new(375.01, 66.80, 23.04) },
    { name = "Inferno Crystal", pos = CFrame.new(1741.55, 5.68, 4019.73) },
    { name = "Lava Crystal", pos = CFrame.new(2224.33, 5.68, 4441.54) },
    { name = "Electro Legends Crystal", pos = CFrame.new(4550.01, 76.60, 6410.42) },
    { name = "Jungle Crystal", pos = CFrame.new(2725.64, 34.04, 12884.37) },
}

for _, crystal in ipairs(crystals) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. crystal.name,
        Callback = function()
            local _, rootPart = getCharacter()
            if rootPart then
                rootPart.CFrame = crystal.pos
            end
        end,
    })
end

TeleportTab:CreateDivider()

TeleportTab:CreateSection("Reward Chests")

local chests = {
    { name = "Reward Chest 1", pos = CFrame.new(-1624.53, 28.20, -497.83) },
    { name = "Reward Chest 2", pos = CFrame.new(2497.66, 26.24, -2133.53) },
    { name = "Reward Chest 3", pos = CFrame.new(2235.76, 321.17, 1003.06) },
    { name = "Reward Chest 4", pos = CFrame.new(-1561.52, 108.68, 5680.74) },
    { name = "Golden Chest", pos = CFrame.new(-1624.53, 28.20, -497.83) },
    { name = "Enchanted Chest", pos = CFrame.new(2497.66, 26.24, -2133.53) },
    { name = "Magma Chest", pos = CFrame.new(2235.76, 321.17, 1003.06) },
    { name = "Jungle Chest", pos = CFrame.new(-1561.52, 108.68, 5680.74) },
}

for _, chest in ipairs(chests) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. chest.name,
        Callback = function()
            local _, rootPart = getCharacter()
            if rootPart then
                rootPart.CFrame = chest.pos
            end
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- UI - PLAYER TAB
-- ═══════════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("Player")

PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(value)
        State.Fly = value
        if value then
            startFly()
        else
            stopFly()
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Flag = "FlySpeed",
    Callback = function(value)
        State.FlySpeed = value
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(value)
        State.Noclip = value
        if value then
            startNoclip()
        else
            stopNoclip()
        end
    end,
})

PlayerTab:CreateDivider()

PlayerTab:CreateSection("Misc")

PlayerTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(value)
        State.AntiAFK = value
        if value then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- UI - SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════
local SettingsTab = Window:CreateTab("Settings")

local sniperLabel = SettingsTab:CreateLabel("")
typewriterLabel(sniperLabel, "Made By Sniper", Color3.fromRGB(255, 0, 0), 0.04)

SettingsTab:CreateDivider()

SettingsTab:CreateSection("Configuration")

SettingsTab:CreateButton({
    Name = "Save Config",
    Callback = function()
        Library.SaveConfiguration("LegendsOfSpeed")
    end,
})

SettingsTab:CreateButton({
    Name = "Load Config",
    Callback = function()
        Library.LoadConfiguration("LegendsOfSpeed")
    end,
})

SettingsTab:CreateButton({
    Name = "Reset Config",
    Callback = function()
        Library.SaveConfiguration("LegendsOfSpeed")
    end,
})

SettingsTab:CreateDivider()

SettingsTab:CreateSection("Server")

SettingsTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end,
})

SettingsTab:CreateDivider()

SettingsTab:CreateSection("Script")

SettingsTab:CreateButton({
    Name = "Destroy Script",
    Callback = function()
        stopFly()
        stopNoclip()
        stopAntiAFK()
        if Window and Window.Destroy then
            pcall(function() Window:Destroy() end)
        end
    end,
})

-- load config on start
pcall(function()
    Library.LoadConfiguration("LegendsOfSpeed")
end)
