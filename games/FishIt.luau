--[[
    Ivory Hub - Fish It!
    PlaceId: 121864768012064
    Version: 1.4
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local cfg = {
    AutoFish = false,
    AutoSell = false,
    AntiAFK = false,
    HidePlayers = false,
    DisableShadows = false,
    DisableReflections = false,
    DisableParticles = false,
    DisableTerrain = false,
    SelectedIsland = "Fisherman Island",
    SelectedNPC = "Alex",
    SelectedMachine = "Luck Machine",
    MenuKeybind = "RightShift",
}

local isRunning = true
local connections = {}
local hiddenPlayerConns = {}

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

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char, char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local net = ReplicatedStorage:FindFirstChild("Packages")
    and ReplicatedStorage.Packages:FindFirstChild("_Index")
    and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"]
    and ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

local SellAll = net and net["RF/SellAllItems"]
local UpdateAutoFish = net and net["RF/UpdateAutoFishingState"]

local function setAutoFishing(state)
    if UpdateAutoFish then
        pcall(function() UpdateAutoFish:InvokeServer(state) end)
    end
end

local function sellAll()
    if SellAll then
        pcall(function() SellAll:InvokeServer() end)
    end
end

local function hidePlayerChar(char, visible)
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("BasePart") then
            pcall(function()
                desc.LocalTransparencyModifier = visible and 0 or 1
                desc.CanCollide = visible
            end)
        elseif desc:IsA("Decal") then
            pcall(function()
                desc.Transparency = visible and 0 or 1
            end)
        end
    end
end

local function hideAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            hidePlayerChar(player.Character, false)
        end
    end
end

local function showAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            hidePlayerChar(player.Character, true)
        end
    end
end

local Islands = {
    ["Fisherman Island"] = CFrame.new(45.28, 252.56, 2987.11),
    ["Coral Reefs"] = CFrame.new(-3025.45, 58.22, 2110.72),
    ["Crystal Island"] = CFrame.new(860.73, 29.42, 4911.59),
    ["Esoteric Depths"] = CFrame.new(3108.01, -1303.79, 1424.69),
    ["Esoteric Island"] = CFrame.new(2061.68, 23.56, 1359.32),
    ["Fisherman Island Old"] = CFrame.new(-125.09, 15.56, 2809.89),
    ["Kohana"] = CFrame.new(-586.18, 18.24, 594.77),
    ["Lost Isle"] = CFrame.new(-3599.31, -165.45, -1362.19),
    ["Tropical Grove"] = CFrame.new(-2195.15, 1.77, 3709.01),
    ["Winter Fest"] = CFrame.new(1679.78, 8.78, 3393.71),
    ["Ancient Jungle"] = CFrame.new(1499.52, 14.28, -409.53),
}

local NPCs = {
    ["Alex"] = CFrame.new(48.09, 17.50, 2877.13),
    ["Alien Merchant"] = CFrame.new(-132.13, 2.72, 2757.46),
    ["Aura Kid"] = CFrame.new(71.09, 18.53, 2830.36),
    ["Billy Bob"] = CFrame.new(79.84, 18.66, 2876.63),
    ["Boat Expert"] = CFrame.new(33.32, 9.8, 2783.01),
    ["Jim"] = CFrame.new(84.90, 9.82, 2797.39),
    ["Joe"] = CFrame.new(144.04, 20.48, 2862.38),
    ["Ron"] = CFrame.new(-51.71, 17.33, 2859.56),
    ["Scientist"] = CFrame.new(-8.04, 14.67, 2885.71),
    ["Scott"] = CFrame.new(-17.13, 9.53, 2703.36),
    ["Seth"] = CFrame.new(111.59, 17.41, 2877.13),
    ["Silly Fisherman"] = CFrame.new(101.95, 9.53, 2690.22),
    ["Temple Guardian"] = CFrame.new(1491.48, 127.63, -593.16),
    ["Tour Guide"] = CFrame.new(1238.89, 7.82, -238.19),
}

local Machines = {
    ["Luck Machine"] = CFrame.new(13.34, 22.53, 2846.63),
    ["Spin Wheel"] = CFrame.new(-151.14, 22.08, 2824.63),
    ["Weather Machine"] = CFrame.new(-1488.86, 22.25, 1875.94),
}

local islandNames = {}
for k in pairs(Islands) do table.insert(islandNames, k) end
table.sort(islandNames)

local npcNames = {}
for k in pairs(NPCs) do table.insert(npcNames, k) end
table.sort(npcNames)

local machineNames = {}
for k in pairs(Machines) do table.insert(machineNames, k) end
table.sort(machineNames)

local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 720,
    Height = 600,
})

local Tabs = {
    Main = Window:CreateTab({ Name = "Main" }),
    Visuals = Window:CreateTab({ Name = "Visuals" }),
    World = Window:CreateTab({ Name = "World" }),
    Misc = Window:CreateTab({ Name = "Misc" }),
    ["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

local MainSection = Tabs.Main:CreateSection("main")
local FarmSection = Tabs.Main:CreateSection("fishing")
local TeleportSection = Tabs.World:CreateSection("teleports")
local PerfSection = Tabs.Visuals:CreateSection("performance")
local MiscSection = Tabs.Misc:CreateSection("miscellaneous")
local CreditsSection = Tabs["UI Settings"]:CreateSection("credits")
local MenuSection = Tabs["UI Settings"]:CreateSection("menu settings")
local ServerSection = Tabs["UI Settings"]:CreateSection("server")
local ThemesSection = Tabs["UI Settings"]:CreateSection("themes")
local ConfigSection = Tabs["UI Settings"]:CreateSection("configuration")

-- ==================== MAIN TAB ====================

MainSection:CreateButton({
    Name = "Join Discord For Dupe",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/bac")
        end
        Library.Notify({ Title = "Ivory", Content = "Discord link copied to clipboard!", Type = "Success", Duration = 3 })
    end,
})

-- ==================== MAIN TAB (FISHING) ====================

FarmSection:CreateToggle({
    Name = "Auto Fish",
    CurrentValue = cfg.AutoFish,
    Callback = function(value)
        cfg.AutoFish = value
        setAutoFishing(value)
    end,
})

FarmSection:CreateToggle({
    Name = "Auto Sell",
    CurrentValue = cfg.AutoSell,
    Callback = function(value) cfg.AutoSell = value end,
})

FarmSection:CreateButton({
    Name = "Sell All Fish",
    Callback = function()
        sellAll()
        Library.Notify({ Title = "Ivory", Content = "Sold all fish!", Type = "Success", Duration = 2 })
    end,
})

-- ==================== WORLD TAB (TELEPORTS) ====================

TeleportSection:CreateDropdown({
    Name = "Select Island",
    Values = islandNames,
    CurrentOption = cfg.SelectedIsland,
    Callback = function(value) cfg.SelectedIsland = value end,
})

TeleportSection:CreateButton({
    Name = "Teleport to Island",
    Callback = function()
        local char, hrp = getChar()
        if hrp and Islands[cfg.SelectedIsland] then
            char:PivotTo(Islands[cfg.SelectedIsland])
        end
    end,
})

TeleportSection:CreateDropdown({
    Name = "Select NPC",
    Values = npcNames,
    CurrentOption = cfg.SelectedNPC,
    Callback = function(value) cfg.SelectedNPC = value end,
})

TeleportSection:CreateButton({
    Name = "Teleport to NPC",
    Callback = function()
        local char, hrp = getChar()
        if hrp and NPCs[cfg.SelectedNPC] then
            char:PivotTo(NPCs[cfg.SelectedNPC])
        end
    end,
})

TeleportSection:CreateDropdown({
    Name = "Select Machine",
    Values = machineNames,
    CurrentOption = cfg.SelectedMachine,
    Callback = function(value) cfg.SelectedMachine = value end,
})

TeleportSection:CreateButton({
    Name = "Teleport to Machine",
    Callback = function()
        local char, hrp = getChar()
        if hrp and Machines[cfg.SelectedMachine] then
            char:PivotTo(Machines[cfg.SelectedMachine])
        end
    end,
})

-- ==================== VISUALS TAB (PERFORMANCE) ====================

PerfSection:CreateToggle({
    Name = "Hide Players",
    CurrentValue = cfg.HidePlayers,
    Callback = function(value)
        cfg.HidePlayers = value
        if value then
            hideAllPlayers()
            connections.playerAdded = Players.PlayerAdded:Connect(function(player)
                hiddenPlayerConns[player] = player.CharacterAdded:Connect(function(char)
                    task.wait(0.5)
                    hidePlayerChar(char, false)
                end)
                if player.Character then
                    task.wait(0.1)
                    hidePlayerChar(player.Character, false)
                end
            end)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and not hiddenPlayerConns[player] then
                    hiddenPlayerConns[player] = player.CharacterAdded:Connect(function(char)
                        task.wait(0.5)
                        hidePlayerChar(char, false)
                    end)
                end
            end
        else
            showAllPlayers()
            if connections.playerAdded then
                connections.playerAdded:Disconnect()
                connections.playerAdded = nil
            end
            for _, conn in pairs(hiddenPlayerConns) do
                if conn then conn:Disconnect() end
            end
            hiddenPlayerConns = {}
        end
    end,
})

PerfSection:CreateToggle({
    Name = "Disable Shadows",
    CurrentValue = cfg.DisableShadows,
    Callback = function(value)
        cfg.DisableShadows = value
        pcall(function() Lighting.GlobalShadows = not value end)
    end,
})

PerfSection:CreateToggle({
    Name = "Disable Water Reflections",
    CurrentValue = cfg.DisableReflections,
    Callback = function(value)
        cfg.DisableReflections = value
        pcall(function() Lighting.EnvironmentSpecularScale = value and 0 or 1 end)
    end,
})

PerfSection:CreateToggle({
    Name = "Disable Particles",
    CurrentValue = cfg.DisableParticles,
    Callback = function(value)
        cfg.DisableParticles = value
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ParticleEmitter") or desc:IsA("Trail") or desc:IsA("Beam") then
                pcall(function() desc.Enabled = not value end)
            end
        end
    end,
})

PerfSection:CreateToggle({
    Name = "Disable Terrain Decoration",
    CurrentValue = cfg.DisableTerrain,
    Callback = function(value)
        cfg.DisableTerrain = value
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            pcall(function() terrain.Decoration = not value end)
        end
    end,
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

CreditsSection:CreateLabel({ Text = "Ivory Hub v1.4 | Fish It!" })
CreditsSection:CreateLabel({ Text = "UserId: " .. LocalPlayer.UserId })

CreditsSection:CreateButton({
    Name = "Join Discord For Dupe",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/bac")
        end
        Library.Notify({ Title = "Ivory", Content = "Discord link copied to clipboard!", Type = "Success", Duration = 3 })
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
        Library.Notify({ Title = "Ivory", Content = "This is a test notification!", Type = "Info", Duration = 3 })
    end,
})

MenuSection:CreateButton({
    Name = "Unload Script",
    Callback = function()
        Library:Unload()
    end,
})

ServerSection:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

ServerSection:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        if servers and servers.data and #servers.data > 0 then
            local jobId = servers.data[math.random(1, #servers.data)].id
            TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
        end
    end,
})

ThemesSection:CreateLabel({ Text = "Theme Colors" })

ConfigSection:CreateButton({
    Name = "Save Config",
    Callback = function()
        if writefile then
            writefile("IvoryHub/FishIt_Config.json", HttpService:JSONEncode(cfg))
        end
        Library.Notify({ Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 2 })
    end,
})

ConfigSection:CreateButton({
    Name = "Load Config",
    Callback = function()
        if readfile and isfile and isfile("IvoryHub/FishIt_Config.json") then
            local loaded = HttpService:JSONDecode(readfile("IvoryHub/FishIt_Config.json"))
            for k, v in pairs(loaded) do
                cfg[k] = v
            end
            Library.Notify({ Title = "Ivory", Content = "Config loaded! Toggle values to refresh.", Type = "Success", Duration = 2 })
        end
    end,
})

-- ==================== FOOTER ====================

task.spawn(function()
    while isRunning do
        local location = LocalPlayer.Character and "Game" or "Lobby"
        local footer = "v1.4 | " .. location .. " | " .. LocalPlayer.UserId
        pcall(function()
            Window:SetFooter(footer)
        end)
        task.wait(1)
    end
end)

-- ==================== MAIN LOOPS ====================

-- Auto Sell
task.spawn(function()
    while isRunning do
        if cfg.AutoSell then
            sellAll()
        end
        task.wait(5)
    end
end)

-- Anti AFK
task.spawn(function()
    while isRunning do
        if cfg.AntiAFK then
            pcall(function()
                LocalPlayer.Idled:Connect(function()
                    VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    task.wait(1)
                    VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                end)
            end)
        end
        task.wait(60)
    end
end)

-- Initialize
Library.Notify({ Title = "Ivory", Content = "Ivory Hub loaded! Fish It!", Type = "Success", Duration = 5 })

return Library