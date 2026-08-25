local genv = getgenv()
local Library = nil
local ThemeManager = nil
local SaveManager = nil

-- Try pre-fetched sources from loader first, fall back to request()
local libSrc = genv._IvoryLibSrc
local tmSrc = genv._IvoryTMSrc
local smSrc = genv._IvorySMSrc

if libSrc then
    Library = loadstring(libSrc)()
    ThemeManager = loadstring(tmSrc)()
    SaveManager = loadstring(smSrc)()
    print("[Ivory] Loaded ObsidianUltra from loader cache")
else
    warn("[Ivory] No cached sources, falling back to request()")
    local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
    local ok1, err1 = pcall(function()
        Library = loadstring(request({ Url = repo .. "Library.lua", Method = "GET" }).Body)()
    end)
    if not ok1 then warn("[Ivory] Library load failed:", err1) end
    local ok2, err2 = pcall(function()
        ThemeManager = loadstring(request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body)()
    end)
    if not ok2 then warn("[Ivory] ThemeManager load failed:", err2) end
    local ok3, err3 = pcall(function()
        SaveManager = loadstring(request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body)()
    end)
    if not ok3 then warn("[Ivory] SaveManager load failed:", err3) end
end

if not Library then
    warn("[Ivory] ObsidianUltra failed to load - aborting")
    return
end

local Toggles = Library.Toggles
local Options = Library.Options

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    AutoBurgerEnabled = false,
    AutoSellEnabled = false,
    AutoCollectEnabled = false,
    AutoRebirthEnabled = false,
    AutoUpgradeFloorsEnabled = false,
    AutoUpgradeLivesEnabled = false,
    AutoBeginEnabled = false,
    AutoContinueEnabled = false,

    BurgerDelay = 0.1,
    SellDelay = 0.1,
    CollectDelay = 0.1,
    RebirthDelay = 1,
    UpgradeFloorsDelay = 0.5,
    UpgradeLivesDelay = 0.5,
    BeginDelay = 0.1,
    ContinueDelay = 0.1,
}

local RS = game:GetService("ReplicatedStorage")
local function GetRemote(path)
    local obj = RS
    for part in path:gmatch("[^:]+") do
        obj = obj:WaitForChild(part, 10)
        if not obj then return nil end
    end
    return obj
end

local BuildingSuccess = GetRemote("Shared:Network:Remotes:Building:Success")
local PlayerSell = GetRemote("Shared:Network:Remotes:PlayerData:Sell")
local PlotCollect = GetRemote("Shared:Network:Remotes:Plot:Collect")
local RequestRebirth = GetRemote("Shared:Network:Remotes:PlayerData:RequestRebirth")
local UpgradeFloors = GetRemote("Shared:Network:Remotes:PlayerData:UpgradeFloors")
local UpgradeLives = GetRemote("Shared:Network:Remotes:PlayerData:UpgradeLives")
local BuildingBegin = GetRemote("Shared:Network:Remotes:Building:Begin")
local BuildingCancel = GetRemote("Shared:Network:Remotes:Building:Cancel")

local function AutoBurger()
    while Settings.AutoBurgerEnabled do
        pcall(function()
            if BuildingSuccess then BuildingSuccess:FireServer(-0.658413290977478) end
        end)
        task.wait(Settings.BurgerDelay)
    end
end

local function AutoSell()
    while Settings.AutoSellEnabled do
        pcall(function()
            if PlayerSell then PlayerSell:FireServer() end
        end)
        task.wait(Settings.SellDelay)
    end
end

local function AutoCollect()
    while Settings.AutoCollectEnabled do
        pcall(function()
            if PlotCollect then
                for slot = 1, 8 do
                    PlotCollect:FireServer(slot)
                    task.wait(Settings.CollectDelay / 8)
                end
            end
        end)
        task.wait(Settings.CollectDelay)
    end
end

local function AutoRebirth()
    while Settings.AutoRebirthEnabled do
        pcall(function()
            if RequestRebirth then RequestRebirth:FireServer() end
        end)
        task.wait(Settings.RebirthDelay)
    end
end

local function AutoUpgradeFloors()
    while Settings.AutoUpgradeFloorsEnabled do
        pcall(function()
            if UpgradeFloors then UpgradeFloors:FireServer() end
        end)
        task.wait(Settings.UpgradeFloorsDelay)
    end
end

local function AutoUpgradeLives()
    while Settings.AutoUpgradeLivesEnabled do
        pcall(function()
            if UpgradeLives then UpgradeLives:FireServer() end
        end)
        task.wait(Settings.UpgradeLivesDelay)
    end
end

local function AutoBegin()
    while Settings.AutoBeginEnabled do
        pcall(function()
            if BuildingBegin then BuildingBegin:FireServer() end
        end)
        task.wait(Settings.BeginDelay)
    end
end

local function AutoContinue()
    while Settings.AutoContinueEnabled do
        pcall(function()
            if BuildingCancel then BuildingCancel:FireServer() end
        end)
        task.wait(Settings.ContinueDelay)
    end
end

-- ═══════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "Ivory",
    Footer = {
        "v1.4 |",
        { Text = "Build A Burger", Copyable = true },
        "|",
        { Text = tostring(LocalPlayer.UserId), Copyable = true },
    },
    CopyableFooter = true,
    FuzzySearch = true,
    SearchValues = true,
    Minimizable = true,
    MinimizeKeybind = Enum.KeyCode.RightBracket,
    MinimizedWidth = 280,
    NotifySide = "Right",
    ShowCustomCursor = true,
    CornerRadius = 4,
})

local MainTab = Window:AddTab({ Name = "Main", Description = "Automation" })
local DelaysTab = Window:AddTab({ Name = "Delays", Description = "Adjust Delays" })
local SettingsTab = Window:AddTab({ Name = "Settings", Description = "Themes & UI" })

-- ═══ MAIN TAB: Automation Sub-Tab ═══
local AutoSub = MainTab:AddSubTab("Automation")

local BurgerBox = AutoSub:AddLeftGroupbox("Burger")
BurgerBox:AddToggle("AutoBurger", { Text = "Auto Burger Perfect", Default = false, Callback = function(v) Settings.AutoBurgerEnabled = v if v then task.spawn(AutoBurger) end end })
BurgerBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(v) Settings.AutoRebirthEnabled = v if v then task.spawn(AutoRebirth) end end })

local UpgradeBox = AutoSub:AddRightGroupbox("Upgrades")
UpgradeBox:AddToggle("AutoUpgradeFloors", { Text = "Auto Upgrade Floors", Default = false, Callback = function(v) Settings.AutoUpgradeFloorsEnabled = v if v then task.spawn(AutoUpgradeFloors) end end })
UpgradeBox:AddToggle("AutoUpgradeLives", { Text = "Auto Upgrade Lives", Default = false, Callback = function(v) Settings.AutoUpgradeLivesEnabled = v if v then task.spawn(AutoUpgradeLives) end end })

local EconBox = AutoSub:AddLeftGroupbox("Economy")
EconBox:AddToggle("AutoSell", { Text = "Auto Sell", Default = false, Callback = function(v) Settings.AutoSellEnabled = v if v then task.spawn(AutoSell) end end })
EconBox:AddToggle("AutoCollect", { Text = "Auto Collect Cash", Default = false, Callback = function(v) Settings.AutoCollectEnabled = v if v then task.spawn(AutoCollect) end end })

local BuildBox = AutoSub:AddRightGroupbox("Building")
BuildBox:AddToggle("AutoBegin", { Text = "Auto Begin", Default = false, Callback = function(v) Settings.AutoBeginEnabled = v if v then task.spawn(AutoBegin) end end })
BuildBox:AddToggle("AutoContinue", { Text = "Auto Continue (Cancel)", Default = false, Callback = function(v) Settings.AutoContinueEnabled = v if v then task.spawn(AutoContinue) end end })

-- ═══ DELAYS TAB ═══
local DelaySub = DelaysTab:AddSubTab("Delays")

local DL1 = DelaySub:AddLeftGroupbox("Delays (seconds)")
DL1:AddSlider("BurgerDelay", { Text = "Burger Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.BurgerDelay = v end })
DL1:AddSlider("SellDelay", { Text = "Sell Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.SellDelay = v end })
DL1:AddSlider("CollectDelay", { Text = "Collect Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.CollectDelay = v end })
DL1:AddSlider("RebirthDelay", { Text = "Rebirth Delay", Default = 1, Min = 0.01, Max = 10, Rounding = 2, Suffix = "s", Callback = function(v) Settings.RebirthDelay = v end })

local DL2 = DelaySub:AddRightGroupbox("More Delays")
DL2:AddSlider("UpgradeFloorsDelay", { Text = "Upgrade Floors Delay", Default = 0.5, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.UpgradeFloorsDelay = v end })
DL2:AddSlider("UpgradeLivesDelay", { Text = "Upgrade Lives Delay", Default = 0.5, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.UpgradeLivesDelay = v end })
DL2:AddSlider("BeginDelay", { Text = "Begin Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.BeginDelay = v end })
DL2:AddSlider("ContinueDelay", { Text = "Continue Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s", Callback = function(v) Settings.ContinueDelay = v end })

-- ═══ SETTINGS TAB ═══
local ThemesSub = SettingsTab:AddSubTab("Themes & UI")
local ConfigSub = SettingsTab:AddSubTab("Config")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("burgerperfect")
ThemeManager:ApplyToTab(ThemesSub)
SaveManager:BuildConfigSection(ConfigSub)

local MenuGroup = ThemesSub:AddLeftGroupbox("Menu")
MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind",
})
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)
Library.ToggleKeybind = Options.MenuKeybind

SaveManager:LoadAutoloadConfig()

Library:Notify({
    Title = "Ivory",
    Description = "Build A Burger loaded. RightShift to toggle menu.",
    Type = "Success",
    Time = 3,
})
