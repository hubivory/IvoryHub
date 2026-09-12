--[[
    Ivory Hub - Baddie Jumping
    PlaceId: 70654235200182
    Version: 1.4
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local cfg = {
    AutoMoney = false,
    AutoRebirth = false,
    MoneyDelay = 0.01,
    RebirthDelay = 0.01,
    WalkSpeed = 16,
    JumpPower = 50,
    CustomSpeed = false,
    CustomJump = false,
    NoClip = false,
    InfiniteJump = false,
    AntiAFK = false,
    MenuKeybind = "RightShift",
}

local isRunning = true

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

local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 720,
    Height = 600,
})

local Tabs = {
    Main = Window:CreateTab({ Name = "Main" }),
    Combat = Window:CreateTab({ Name = "Combat" }),
    Visuals = Window:CreateTab({ Name = "Visuals" }),
    World = Window:CreateTab({ Name = "World" }),
    Misc = Window:CreateTab({ Name = "Misc" }),
    ["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

local MainSection = Tabs.Main:CreateSection("main")
local FarmSection = Tabs.Combat:CreateSection("farm")
local MiscTabSection = Tabs.Misc:CreateSection("miscellaneous")
local ESPSection = Tabs.Visuals:CreateSection("esp")
local MovementSection = Tabs.World:CreateSection("movement")
local CreditsSection = Tabs["UI Settings"]:CreateSection("credits")
local MenuSection = Tabs["UI Settings"]:CreateSection("menu settings")
local ServerSection = Tabs["UI Settings"]:CreateSection("server")
local ThemesSection = Tabs["UI Settings"]:CreateSection("themes")
local ConfigSection = Tabs["UI Settings"]:CreateSection("configuration")

-- ==================== MAIN TAB ====================

local discordBtn = MainSection:CreateButton({
    Name = "Join Discord For Dupe",
    Callback = function()
        if setclipboard then
            setclipboard("https://discord.gg/bac")
        end
        Library.Notify({ Title = "Ivory", Content = "Discord link copied to clipboard!", Type = "Success", Duration = 3 })
    end,
})

-- ==================== COMBAT TAB (FARM) ====================

local GiveOutReward = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Roulette"):WaitForChild("GiveOutReward")
local Rebirth = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Rebirth")

FarmSection:CreateToggle({
    Name = "Auto Money",
    CurrentValue = cfg.AutoMoney,
    Callback = function(value) cfg.AutoMoney = value end,
})

FarmSection:CreateSlider({
    Name = "Money Delay",
    Min = 0.01,
    Max = 1,
    CurrentValue = cfg.MoneyDelay,
    Callback = function(value) cfg.MoneyDelay = value end,
})

FarmSection:CreateToggle({
    Name = "Auto Rebirth",
    CurrentValue = cfg.AutoRebirth,
    Callback = function(value) cfg.AutoRebirth = value end,
})

FarmSection:CreateSlider({
    Name = "Rebirth Delay",
    Min = 0.01,
    Max = 1,
    CurrentValue = cfg.RebirthDelay,
    Callback = function(value) cfg.RebirthDelay = value end,
})

FarmSection:CreateButton({
    Name = "Give Money",
    Callback = function()
        pcall(function()
            GiveOutReward:FireServer({
                value = math.huge - 1,
                type = "Money",
                chance = 0.45,
            })
        end)
    end,
})

FarmSection:CreateButton({
    Name = "Rebirth",
    Callback = function()
        pcall(function()
            Rebirth:FireServer()
        end)
    end,
})

FarmSection:CreateButton({
    Name = "Teleport to Roulette",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end
        local roulette = workspace:FindFirstChild("Roulette")
        if roulette and roulette:IsA("Model") and roulette.PrimaryPart then
            hrp.CFrame = roulette.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

FarmSection:CreateButton({
    Name = "Teleport to Rebirth",
    Callback = function()
        local char, hrp = getChar()
        if not hrp then return end
        local rebirth = workspace:FindFirstChild("Rebirth")
        if rebirth and rebirth:IsA("Model") and rebirth.PrimaryPart then
            hrp.CFrame = rebirth.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

-- ==================== VISUALS TAB ====================

ESPSection:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(value)
        -- Player ESP logic
    end,
})

ESPSection:CreateSlider({
    Name = "ESP Distance",
    Min = 100,
    Max = 2000,
    CurrentValue = 500,
    Callback = function(value) end,
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
    Min = 50,
    Max = 500,
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

-- ==================== MISC TAB ====================

MiscTabSection:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = cfg.AntiAFK,
    Callback = function(value) cfg.AntiAFK = value end,
})

MiscTabSection:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTabSection:CreateButton({
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

CreditsSection:CreateLabel({ Text = "Ivory Hub v1.4 | Baddie Jumping" })
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
            writefile("IvoryHub/JumpingBaddies_Config.json", HttpService:JSONEncode(cfg))
        end
        Library.Notify({ Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 2 })
    end,
})

ConfigSection:CreateButton({
    Name = "Load Config",
    Callback = function()
        if readfile and isfile and isfile("IvoryHub/JumpingBaddies_Config.json") then
            local loaded = HttpService:JSONDecode(readfile("IvoryHub/JumpingBaddies_Config.json"))
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

-- Auto Money
task.spawn(function()
    while isRunning do
        if cfg.AutoMoney then
            pcall(function()
                GiveOutReward:FireServer({
                    value = math.huge - 1,
                    type = "Money",
                    chance = 0.45,
                })
            end)
        end
        task.wait(cfg.MoneyDelay)
    end
end)

-- Auto Rebirth
task.spawn(function()
    while isRunning do
        if cfg.AutoRebirth then
            pcall(function()
                Rebirth:FireServer()
            end)
        end
        task.wait(cfg.RebirthDelay)
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

-- Initialize
Library.Notify({ Title = "Ivory", Content = "Ivory Hub loaded! Baddie Jumping", Type = "Success", Duration = 5 })

return Library