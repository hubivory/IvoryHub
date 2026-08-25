-- ===============================================================
-- IVORY HUB - BURGER PERFECT AUTO
-- ObsidianUltra UI (joustingmatch/ObsidianUltra)
-- ===============================================================

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Options = Library.Options
local Toggles = Library.Toggles

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
local Network = RS:WaitForChild("Network", 15)
local Remotes = RS:WaitForChild("Remotes", 15)

local LinkPlayerToOrder = Network:FindFirstChild("LinkPlayerToOrder")
local UnlinkPlayerFromOrder = Network:FindFirstChild("UnlinkPlayerFromOrder")
local RequestOrderBoard = Network:FindFirstChild("RequestOrderBoard")
local TryAddIngredientToPlate = Network:FindFirstChild("TryAddIngredientToPlate")
local RequestMeatSeasoning = Network:FindFirstChild("RequestMeatSeasoning")
local AddTimeToMeat = Network:FindFirstChild("AddTimeToMeat")
local RequestFriesSeasoning = Network:FindFirstChild("RequestFriesSeasoning")
local AddTimeToFries = Network:FindFirstChild("AddTimeToFries")
local AddMoney = Network:FindFirstChild("AddMoney")
local BuyPcUpgradeRequest = Network:FindFirstChild("BuyPcUpgradeRequest")
local RebirthClass = Network:FindFirstChild("RebirthClass")
local ClaimReward = Network:FindFirstChild("ClaimReward")
local HealthInspector_ClaimRewards = Network:FindFirstChild("HealthInspector_ClaimRewards")
local TycoonPurchase = Remotes:FindFirstChild("TycoonPurchase")
local EmployeeUpgrade = Remotes:FindFirstChild("EmployeeUpgrade")

local function AutoBurger()
    if not LinkPlayerToOrder or not TryAddIngredientToPlate then
        warn("[Ivory] Order remotes missing")
        return
    end
    while Settings.AutoBurgerEnabled do
        pcall(function()
            if RequestOrderBoard then RequestOrderBoard:InvokeServer() end
            task.wait(0.1)
            if LinkPlayerToOrder then LinkPlayerToOrder:FireServer() end
            task.wait(0.1)
            if TryAddIngredientToPlate then TryAddIngredientToPlate:FireServer() end
            task.wait(0.05)
            if RequestMeatSeasoning then RequestMeatSeasoning:FireServer() end
            task.wait(0.05)
            if AddTimeToMeat then AddTimeToMeat:FireServer() end
            task.wait(0.05)
            if RequestFriesSeasoning then RequestFriesSeasoning:FireServer() end
            task.wait(0.05)
            if AddTimeToFries then AddTimeToFries:FireServer() end
            task.wait(0.05)
            if UnlinkPlayerFromOrder then UnlinkPlayerFromOrder:FireServer() end
        end)
        task.wait(Settings.BurgerDelay)
    end
end

local function AutoSell()
    if not AddMoney then warn("[Ivory] AddMoney remote missing") return end
    while Settings.AutoSellEnabled do
        pcall(function()
            AddMoney:FireServer()
        end)
        task.wait(Settings.SellDelay)
    end
end

local function AutoCollect()
    if not ClaimReward then warn("[Ivory] ClaimReward remote missing") return end
    while Settings.AutoCollectEnabled do
        pcall(function()
            ClaimReward:FireServer()
            if HealthInspector_ClaimRewards then HealthInspector_ClaimRewards:FireServer() end
        end)
        task.wait(Settings.CollectDelay)
    end
end

local function AutoRebirth()
    if not RebirthClass then warn("[Ivory] RebirthClass remote missing") return end
    while Settings.AutoRebirthEnabled do
        pcall(function()
            RebirthClass:FireServer()
        end)
        task.wait(Settings.RebirthDelay)
    end
end

local function AutoUpgradeFloors()
    if not BuyPcUpgradeRequest then warn("[Ivory] BuyPcUpgradeRequest remote missing") return end
    while Settings.AutoUpgradeFloorsEnabled do
        pcall(function()
            BuyPcUpgradeRequest:FireServer()
        end)
        task.wait(Settings.UpgradeFloorsDelay)
    end
end

local function AutoUpgradeLives()
    if not EmployeeUpgrade then warn("[Ivory] EmployeeUpgrade remote missing") return end
    while Settings.AutoUpgradeLivesEnabled do
        pcall(function()
            EmployeeUpgrade:InvokeServer()
        end)
        task.wait(Settings.UpgradeLivesDelay)
    end
end

local function AutoBegin()
    if not RequestOrderBoard then warn("[Ivory] RequestOrderBoard remote missing") return end
    while Settings.AutoBeginEnabled do
        pcall(function()
            RequestOrderBoard:InvokeServer()
        end)
        task.wait(Settings.BeginDelay)
    end
end

local function AutoContinue()
    if not TycoonPurchase then warn("[Ivory] TycoonPurchase remote missing") return end
    while Settings.AutoContinueEnabled do
        pcall(function()
            TycoonPurchase:FireServer()
        end)
        task.wait(Settings.ContinueDelay)
    end
end

-- ===============================================================
-- UI
-- ===============================================================
Library.Scheme.BackgroundColor = Color3.fromRGB(18, 16, 26)
Library.Scheme.MainColor = Color3.fromRGB(26, 22, 38)
Library.Scheme.AccentColor = Color3.fromRGB(168, 120, 255)
Library.Scheme.FontColor = Color3.fromRGB(248, 244, 255)

local Window = Library:CreateWindow({
    Title = "Ivory | Burger Perfect",
    Footer = {
        "v1.5 |",
        { Text = tostring(LocalPlayer.UserId), Copyable = true },
    },
    CopyableFooter = true,
    Center = true,
    AutoShow = true,
    NotifySide = "Right",
    ShowCustomCursor = true,
    FuzzySearch = true,
    SearchValues = true,
    Minimizable = true,
    MinimizeKeybind = Enum.KeyCode.RightBracket,
    MinimizedWidth = 280,
    CornerRadius = 4,
    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Groupbox = false,
        Dropdown = false,
        KeyPicker = false,
        SubTabUnderline = true,
    },
})

-- ===============================================================
-- TABS
-- ===============================================================
local MainTab = Window:AddTab({ Name = "Main", Icon = "flame", Description = "Automation" })
local DelaysTab = Window:AddTab({ Name = "Delays", Icon = "clock", Description = "Configure delays" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "UI & Config" })

-- ===============================================================
-- MAIN TAB - AUTOMATION
-- ===============================================================
local AutoSub = MainTab:AddSubTab({ Name = "Automation", Icon = "zap" })

local BurgerBox = AutoSub:AddLeftGroupbox("Burger", "flame")
BurgerBox:AddToggle("AutoBurger", {
    Text = "Auto Burger Perfect",
    Default = false,
    Callback = function(v)
        Settings.AutoBurgerEnabled = v
        if v then task.spawn(AutoBurger) end
    end,
})

BurgerBox:AddToggle("AutoRebirth", {
    Text = "Auto Rebirth",
    Default = false,
    Callback = function(v)
        Settings.AutoRebirthEnabled = v
        if v then task.spawn(AutoRebirth) end
    end,
})

local UpgradeBox = AutoSub:AddRightGroupbox("Upgrades", "arrow-up-circle")
UpgradeBox:AddToggle("AutoUpgradeFloors", {
    Text = "Auto Upgrade Floors",
    Default = false,
    Callback = function(v)
        Settings.AutoUpgradeFloorsEnabled = v
        if v then task.spawn(AutoUpgradeFloors) end
    end,
})

UpgradeBox:AddToggle("AutoUpgradeLives", {
    Text = "Auto Upgrade Lives",
    Default = false,
    Callback = function(v)
        Settings.AutoUpgradeLivesEnabled = v
        if v then task.spawn(AutoUpgradeLives) end
    end,
})

local EconBox = AutoSub:AddLeftGroupbox("Economy", "coins")
EconBox:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(v)
        Settings.AutoSellEnabled = v
        if v then task.spawn(AutoSell) end
    end,
})

EconBox:AddToggle("AutoCollect", {
    Text = "Auto Collect Cash",
    Default = false,
    Callback = function(v)
        Settings.AutoCollectEnabled = v
        if v then task.spawn(AutoCollect) end
    end,
})

local BuildBox = AutoSub:AddRightGroupbox("Building", "hammer")
BuildBox:AddToggle("AutoBegin", {
    Text = "Auto Begin",
    Default = false,
    Callback = function(v)
        Settings.AutoBeginEnabled = v
        if v then task.spawn(AutoBegin) end
    end,
})

BuildBox:AddToggle("AutoContinue", {
    Text = "Auto Continue (Cancel)",
    Default = false,
    Callback = function(v)
        Settings.AutoContinueEnabled = v
        if v then task.spawn(AutoContinue) end
    end,
})

-- ===============================================================
-- DELAYS TAB
-- ===============================================================
local DelayLeft = DelaysTab:AddLeftGroupbox("Delays (seconds)", "clock")

DelayLeft:AddSlider("BurgerDelay", {
    Text = "Burger Delay",
    Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.BurgerDelay = v end,
})
DelayLeft:AddSlider("SellDelay", {
    Text = "Sell Delay",
    Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.SellDelay = v end,
})
DelayLeft:AddSlider("CollectDelay", {
    Text = "Collect Delay",
    Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.CollectDelay = v end,
})
DelayLeft:AddSlider("RebirthDelay", {
    Text = "Rebirth Delay",
    Default = 1, Min = 0.01, Max = 10, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.RebirthDelay = v end,
})

local DelayRight = DelaysTab:AddRightGroupbox("More Delays", "clock")

DelayRight:AddSlider("UpgradeFloorsDelay", {
    Text = "Upgrade Floors Delay",
    Default = 0.5, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.UpgradeFloorsDelay = v end,
})
DelayRight:AddSlider("UpgradeLivesDelay", {
    Text = "Upgrade Lives Delay",
    Default = 0.5, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.UpgradeLivesDelay = v end,
})
DelayRight:AddSlider("BeginDelay", {
    Text = "Begin Delay",
    Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.BeginDelay = v end,
})
DelayRight:AddSlider("ContinueDelay", {
    Text = "Continue Delay",
    Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s",
    Callback = function(v) Settings.ContinueDelay = v end,
})

-- ===============================================================
-- SETTINGS TAB
-- ===============================================================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("burgerperfect")
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(v) Library.KeybindFrame.Visible = v end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = Library.CornerRadius,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(v) Window:SetCornerRadius(v) end,
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
    Description = "Burger Perfect Auto loaded. RightShift to toggle menu.",
    Type = "Success",
    Time = 4,
})
Window:SetMinimizedSubtitle("Ivory | Burger Perfect Auto")
