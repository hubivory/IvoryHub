-- Karinderya Script using ObsidianUltra
-- Features: Auto Serve, Auto Order, Auto Claim Codes, Auto Pan, Auto Clean Trash, Walkspeed, Infinite Jump

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CounterRemotes = Remotes:WaitForChild("CounterRemotes")
local GetCounterInfo = CounterRemotes:WaitForChild("GetCounterInfo")
local AssignNPC = CounterRemotes:WaitForChild("AssignNPC")
local RedeemCodeRemote = Remotes:WaitForChild("RedeemCode"):WaitForChild("RedeemCode")
local HitRunawayEvent = Remotes:WaitForChild("HitRunawayEvent")

-- State
local Toggles = Library.Toggles
local Options = Library.Options

local autoServeEnabled = false
local autoOrderEnabled = false
local autoClaimCodesEnabled = false
local autoPanEnabled = false
local autoCleanTrashEnabled = false
local walkSpeedValue = 16
local infiniteJumpEnabled = false

-- Helper: Get player's Karenderya plot
local function getPlot()
    for _, v in ipairs(Workspace:GetChildren()) do
        if string.find(v.Name, "^Karenderya") then
            if v:GetAttribute("Owner") == LocalPlayer.UserId then
                return v
            end
        end
    end
    return nil
end

-- Helper: Get character and humanoid
local function getCharacter()
    return LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

-- WINDOW
local Window = Library:CreateWindow({
    Title = "Ivory",
    Footer = {
        "Ivory",
        { Text = "v1.0", Copyable = true },
    },
    Minimizable = true,
    FuzzySearch = true,
    SearchValues = true,
})

-- TABS
local MainTab = Window:AddTab({ Name = "Main", Icon = "utensils", Description = "Core Automation" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user", Description = "Character Mods" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Theme & Config" })

-- ============================================
-- MAIN TAB - Automation
-- ============================================

-- Auto Section
local AutoSection = MainTab:AddLeftGroupbox("Automation", "zap")

AutoSection:AddToggle("AutoServe", {
    Text = "Auto Serve Food",
    Default = false,
    Tooltip = "Automatically serves cooked food to tables",
})

AutoSection:AddToggle("AutoOrder", {
    Text = "Auto Assign Customers",
    Default = false,
    Tooltip = "Automatically assigns waiting customers to available tables",
})

AutoSection:AddToggle("AutoClaimCodes", {
    Text = "Auto Claim Codes",
    Default = false,
    Tooltip = "Automatically redeems the current active code",
})

AutoSection:AddToggle("AutoPan", {
    Text = "Auto Pan (Hit Runaway)",
    Default = false,
    Tooltip = "Automatically equips Pan and hits runaway NPCs",
})

AutoSection:AddToggle("AutoCleanTrash", {
    Text = "Auto Clean Tables",
    Default = false,
    Tooltip = "Automatically cleans dirty tables after customers leave",
})

-- Delays Section
local DelaysSection = MainTab:AddRightGroupbox("Delays", "clock")

DelaysSection:AddSlider("ServeDelay", {
    Text = "Serve Check Delay",
    Default = 2,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
    Tooltip = "Delay between auto serve checks",
})

DelaysSection:AddSlider("OrderDelay", {
    Text = "Order Check Delay",
    Default = 2,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
    Tooltip = "Delay between auto order checks",
})

DelaysSection:AddSlider("CleanDelay", {
    Text = "Clean Check Delay",
    Default = 3,
    Min = 1,
    Max = 15,
    Rounding = 1,
    Suffix = "s",
    Tooltip = "Delay between table clean checks",
})

-- ============================================
-- PLAYER TAB
-- ============================================

-- Character Section
local CharacterSection = PlayerTab:AddLeftGroupbox("Character", "person-standing")

CharacterSection:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 100,
    Rounding = 0,
    Tooltip = "Character walk speed (default: 16)",
})

CharacterSection:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
    Tooltip = "Allows unlimited jumping",
})

-- Teleports Section
local TeleportSection = PlayerTab:AddRightGroupbox("Teleports", "map-pin")

TeleportSection:AddButton("Counter", function()
    local plot = getPlot()
    if plot then
        local counter = plot:FindFirstChild("Counter")
        if counter then
            local comp = counter:FindFirstChild("Comp", true)
            if comp then
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = comp.CFrame * CFrame.new(0, 3, 0)
                    end
                end
            end
        end
    end
end)

TeleportSection:AddButton("Kitchen", function()
    local plot = getPlot()
    if plot then
        local kitchen = plot:FindFirstChild("KitchenPlot1")
        if kitchen then
            local first = kitchen:GetChildren()[1]
            if first then
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = first:GetPivot() * CFrame.new(0, 3, 0)
                    end
                end
            end
        end
    end
end)

TeleportSection:AddButton("Serve Area", function()
    local plot = getPlot()
    if plot then
        local serve = plot:FindFirstChild("Serve")
        if serve then
            local first = serve:GetChildren()[1]
            if first then
                local char = LocalPlayer.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = first:GetPivot() * CFrame.new(0, 3, 0)
                    end
                end
            end
        end
    end
end)

-- ============================================
-- SETTINGS TAB
-- ============================================

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

ThemeManager:SetFolder("IvoryScript")
SaveManager:SetFolder("IvoryScript/saves")

ThemeManager:ApplyToTab(SettingsTab)

SaveManager:BuildConfigSection(SettingsTab)
SaveManager:LoadAutoloadConfig()

-- ============================================
-- TOGGLE CALLBACKS
-- ============================================

Toggles.AutoServe:OnChanged(function(state)
    autoServeEnabled = state
end)

Toggles.AutoOrder:OnChanged(function(state)
    autoOrderEnabled = state
end)

Toggles.AutoClaimCodes:OnChanged(function(state)
    autoClaimCodesEnabled = state
end)

Toggles.AutoPan:OnChanged(function(state)
    autoPanEnabled = state
end)

Toggles.AutoCleanTrash:OnChanged(function(state)
    autoCleanTrashEnabled = state
end)

Options.WalkSpeed:OnChanged(function(value)
    walkSpeedValue = value
    local _, hum = getCharacter()
    if hum then
        hum.WalkSpeed = value
    end
end)

Toggles.InfiniteJump:OnChanged(function(state)
    infiniteJumpEnabled = state
end)

-- ============================================
-- LOOPS
-- ============================================

-- AUTO SERVE LOOP
task.spawn(function()
    while true do
        if autoServeEnabled then
            local plot = getPlot()
            if plot then
                local serve = plot:FindFirstChild("Serve")
                if serve then
                    local char, hum = getCharacter()
                    if char and hum then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local bestPos, bestDist = nil, math.huge
                            for _, child in ipairs(serve:GetChildren()) do
                                if child:IsA("BasePart") then
                                    local dist = (hrp.Position - child.Position).Magnitude
                                    if dist < bestDist then
                                        bestDist = dist
                                        bestPos = child.Position
                                    end
                                end
                            end
                            if bestPos then
                                hum:MoveTo(bestPos)
                                task.wait(0.5)
                            end
                            for _, desc in ipairs(serve:GetDescendants()) do
                                if desc:IsA("ProximityPrompt") and desc.Enabled then
                                    fireproximityprompt(desc)
                                    task.wait(0.3)
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(Options.ServeDelay and Options.ServeDelay.Value or 2)
    end
end)

-- AUTO ORDER LOOP
task.spawn(function()
    while true do
        if autoOrderEnabled then
            local ok, npcData, tables = pcall(function()
                return GetCounterInfo:InvokeServer()
            end)
            if ok and npcData and tables then
                local npcId = npcData.NpcId or npcData.TemplateName or ""
                for _, tbl in ipairs(tables) do
                    if tbl.Slot and tbl.Seat then
                        local success = pcall(function()
                            AssignNPC:FireServer({
                                Slot = tbl.Slot,
                                Seat = tbl.Seat,
                                NPCName = npcId,
                                NpcId = npcId,
                            })
                        end)
                        if success then
                            break
                        end
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(Options.OrderDelay and Options.OrderDelay.Value or 2)
    end
end)

-- AUTO CLAIM CODES LOOP
task.spawn(function()
    local claimed = {}
    while true do
        if autoClaimCodesEnabled then
            local codes = { "LERISNATO" }
            for _, code in ipairs(codes) do
                if not claimed[code] then
                    pcall(function()
                        RedeemCodeRemote:FireServer(code)
                    end)
                    claimed[code] = true
                    task.wait(3)
                end
            end
        end
        task.wait(10)
    end
end)

-- AUTO PAN LOOP
task.spawn(function()
    while true do
        if autoPanEnabled then
            local char, hum = getCharacter()
            if char and hum then
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                local pan = backpack and backpack:FindFirstChild("Pan")
                if not pan then
                    pan = char:FindFirstChild("Pan")
                end

                local clientNPCs = Workspace:FindFirstChild("ClientNPCs")
                local hasRunaway = false
                if clientNPCs then
                    for _, npc in ipairs(clientNPCs:GetChildren()) do
                        if npc:IsA("Model") and npc:GetAttribute("IsRunaway") == true then
                            hasRunaway = true
                            local npcHRP = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                            if npcHRP then
                                hum:MoveTo(npcHRP.Position)
                            end
                            break
                        end
                    end
                end

                if hasRunaway and pan then
                    if pan.Parent == backpack then
                        hum:EquipTool(pan)
                        task.wait(0.3)
                    end
                    if pan.Parent == char then
                        pcall(function()
                            pan:Activate()
                        end)
                        task.wait(0.6)
                    end
                elseif not hasRunaway and pan and pan.Parent == char then
                    hum:UnequipTools()
                end
            end
        end
        task.wait(0.5)
    end
end)

-- AUTO CLEAN TRASH LOOP
task.spawn(function()
    while true do
        if autoCleanTrashEnabled then
            local plot = getPlot()
            if plot then
                local diningPlot = plot:FindFirstChild("DiningPlot1")
                if diningPlot then
                    local char, hum = getCharacter()
                    if char and hum then
                        for _, tableModel in ipairs(diningPlot:GetChildren()) do
                            if tableModel:IsA("Model") or tableModel:IsA("Folder") then
                                for _, desc in ipairs(tableModel:GetDescendants()) do
                                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                                        local promptParent = desc.Parent
                                        if promptParent and promptParent:IsA("BasePart") then
                                            local hrp = char:FindFirstChild("HumanoidRootPart")
                                            if hrp then
                                                local dist = (hrp.Position - promptParent.Position).Magnitude
                                                if dist < 20 then
                                                    hum:MoveTo(promptParent.Position)
                                                    task.wait(0.4)
                                                    fireproximityprompt(desc)
                                                    task.wait(0.5)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(Options.CleanDelay and Options.CleanDelay.Value or 3)
    end
end)

-- WALKSPEED HANDLER
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 10)
    if hum then
        hum.WalkSpeed = walkSpeedValue
    end
end)

do
    local _, hum = getCharacter()
    if hum then
        hum.WalkSpeed = walkSpeedValue
    end
end

-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled then
        local _, hum = getCharacter()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

Library:Toggle()