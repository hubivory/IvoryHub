--// Ivory Hub - Multi-Game Script Loader
--// https://github.com/hubivory/IvoryHub

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/"
local LIB_URL = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"

--// Load UI Library
local Library = loadstring(game:HttpGet(LIB_URL .. "Library.lua"))()

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

--// Script Registry
--// Format: { PlaceId = { name, icon, scripts = { { name, file, description } } } }
local GameRegistry = {
    [116497287371701] = {
        Name = "Karinderya",
        Icon = "utensils",
        Scripts = {
            {
                Name = "Karinderya Script",
                File = "games/Karinderya.luau",
                Description = "Auto Serve, Auto Order, Auto Claim Codes, Auto Pan, Auto Clean Trash"
            }
        }
    },
    -- Add more games here as you create scripts
    -- [PLACE_ID] = {
    --     Name = "Game Name",
    --     Icon = "gamepad",
    --     Scripts = {
    --         { Name = "Script Name", File = "games/ScriptName.luau", Description = "Description" }
    --     }
    -- }
}

--// State
getgenv().IvoryHub = {
    Loaded = false,
    CurrentGame = nil,
    ActiveScripts = {},
    Config = {}
}

local State = getgenv().IvoryHub

--// Utility Functions
local function getCharacter()
    return LocalPlayer.Character,
        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),
        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
end

local function isAlive()
    local char, hrp, hum = getCharacter()
    return char and hrp and hum and hum.Health > 0
end

local function loadGameScript(scriptInfo)
    local success, result = pcall(function()
        local scriptContent = game:HttpGet(GITHUB_RAW .. scriptInfo.File)
        return loadstring(scriptContent)()
    end)
    if not success then
        warn("[Ivory Hub] Failed to load script: " .. scriptInfo.Name, result)
        return false
    end
    return true
end

local function stopAllScripts()
    for name, script in pairs(State.ActiveScripts) do
        if type(script) == "table" and script.Stop then
            pcall(script.Stop)
        elseif type(script) == "thread" then
            pcall(task.cancel, script)
        end
    end
    State.ActiveScripts = {}
    State.CurrentGame = nil
end

--// Detect Current Game
local currentPlaceId = game.PlaceId
local currentGame = GameRegistry[currentPlaceId]

if not currentGame then
    warn("[Ivory Hub] Game not supported: " .. currentPlaceId)
end

State.CurrentGame = currentGame

--// Main UI
local Window = Library:CreateWindow({
    Title = "Ivory Hub",
    Subtitle = currentGame and currentGame.Name or "Unknown Game",
    Footer = { { Text = "Ivory Hub v1.0 | github.com/hubivory", Copyable = false } },
    Size = UDim2.fromOffset(520, 580),
})

--// Tabs
local HomeTab = Window:AddTab({ Name = "Home", Icon = "home", Description = "Hub overview" })
local ScriptsTab = Window:AddTab({ Name = "Scripts", Icon = "code", Description = "Load scripts" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Hub settings" })

--// Home Tab - Game Info
local GameGroup = HomeTab:AddLeftGroupbox("Current Game", "info")
if currentGame then
    GameGroup:AddLabel("Game: " .. currentGame.Name)
    GameGroup:AddLabel("Place ID: " .. currentPlaceId)
    GameGroup:AddLabel("Scripts Available: " .. #currentGame.Scripts)
else
    GameGroup:AddLabel("No game detected")
    GameGroup:AddLabel("Place ID: " .. currentPlaceId)
end

local StatusGroup = HomeTab:AddRightGroupbox("Status", "activity")
local StatusLabel = StatusGroup:AddLabel("Status: Idle")
local LoadedLabel = StatusGroup:AddLabel("Loaded Scripts: 0")

--// Scripts Tab - Load/Stop Scripts
if currentGame then
    local ScriptList = ScriptsTab:AddLeftGroupbox("Available Scripts", "list")

    for _, scriptInfo in ipairs(currentGame.Scripts) do
        ScriptList:AddToggle("Script_" .. scriptInfo.Name, {
            Text = scriptInfo.Name,
            Default = false,
            Callback = function(enabled)
                if enabled then
                    StatusLabel:SetText("Status: Loading " .. scriptInfo.Name .. "...")
                    local success = loadGameScript(scriptInfo)
                    if success then
                        State.ActiveScripts[scriptInfo.Name] = true
                        StatusLabel:SetText("Status: Running " .. scriptInfo.Name)
                    else
                        StatusLabel:SetText("Status: Failed to load")
                    end
                else
                    State.ActiveScripts[scriptInfo.Name] = nil
                    StatusLabel:SetText("Status: Stopped " .. scriptInfo.Name)
                end
                LoadedLabel:SetText("Loaded Scripts: " .. #table.keys(State.ActiveScripts))
            end,
        })

        if scriptInfo.Description then
            ScriptList:AddLabel("  " .. scriptInfo.Description)
        end
    end

    local ControlGroup = ScriptsTab:AddRightGroupbox("Controls", "power")
    ControlGroup:AddButton("Stop All Scripts", function()
        stopAllScripts()
        StatusLabel:SetText("Status: All stopped")
        LoadedLabel:SetText("Loaded Scripts: 0")
    end)

    ControlGroup:AddButton("Reload Hub", function()
        stopAllScripts()
        -- Reload would re-execute this script
        StatusLabel:SetText("Status: Reloading...")
        task.delay(0.5, function()
            StatusLabel:SetText("Status: Ready")
        end)
    end)
else
    local NoGameGroup = ScriptsTab:AddLeftGroupbox("No Game Detected", "alert-circle")
    NoGameGroup:AddLabel("Ivory Hub does not support this game yet.")
    NoGameGroup:AddLabel("Place ID: " .. currentPlaceId)
    NoGameGroup:AddLabel("Add this game to GameRegistry to get started.")
end

--// Settings Tab
local MiscGroup = SettingsTab:AddLeftGroupbox("Hub", "settings")
MiscGroup:AddToggle("ShowNotifications", {
    Text = "Show Notifications",
    Default = true,
    Callback = function(val)
        State.Config.ShowNotifications = val
    end,
})

MiscGroup:AddToggle("AutoStopOnLeave", {
    Text = "Auto-Stop on Leave",
    Default = true,
    Callback = function(val)
        State.Config.AutoStopOnLeave = val
    end,
})

MiscGroup:AddButton("Toggle UI", function() Library:Toggle() end)
MiscGroup:AddButton("Stop Everything", function()
    stopAllScripts()
    StatusLabel:SetText("Status: All stopped")
    LoadedLabel:SetText("Loaded Scripts: 0")
end)

local InfoGroup = SettingsTab:AddRightGroupbox("Info", "info")
InfoGroup:AddLabel("Ivory Hub v1.0")
InfoGroup:AddLabel("GitHub: hubivory/IvoryHub")
InfoGroup:AddLabel("UI: ObsidianUltra")

--// Auto-cleanup on leave
Players.LocalPlayer.CharacterRemoving:Connect(function()
    if State.Config.AutoStopOnLeave then
        stopAllScripts()
    end
end)

--// Load saved config
local function loadConfig()
    local saved = nil
    pcall(function()
        saved = HttpService:JSONDecode(readfile("IvoryHub_Config.json"))
    end)
    if saved then
        State.Config = saved
    end
end

local function saveConfig()
    pcall(function()
        writefile("IvoryHub_Config.json", HttpService:JSONEncode(State.Config))
    end)
end

loadConfig()

--// Finalize
State.Loaded = true
print("[Ivory Hub] Loaded successfully!")
print("[Ivory Hub] Game: " .. (currentGame and currentGame.Name or "Unknown"))
print("[Ivory Hub] Scripts: " .. (currentGame and #currentGame.Scripts or 0) .. " available")

--// Expose for external scripts
getgenv().IvoryHub = State