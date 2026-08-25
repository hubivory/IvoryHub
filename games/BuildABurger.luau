local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
    return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

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
local Network = RS:WaitForChild("Network", 10)
local Remotes = RS:WaitForChild("Remotes", 10)

local LinkPlayerToOrder = Network and Network:FindFirstChild("LinkPlayerToOrder")
local UnlinkPlayerFromOrder = Network and Network:FindFirstChild("UnlinkPlayerFromOrder")
local RequestOrderBoard = Network and Network:FindFirstChild("RequestOrderBoard")
local TryAddIngredientToPlate = Network and Network:FindFirstChild("TryAddIngredientToPlate")
local RequestMeatSeasoning = Network and Network:FindFirstChild("RequestMeatSeasoning")
local AddTimeToMeat = Network and Network:FindFirstChild("AddTimeToMeat")
local RequestFriesSeasoning = Network and Network:FindFirstChild("RequestFriesSeasoning")
local AddTimeToFries = Network and Network:FindFirstChild("AddTimeToFries")
local AddMoney = Network and Network:FindFirstChild("AddMoney")
local BuyPcUpgradeRequest = Network and Network:FindFirstChild("BuyPcUpgradeRequest")
local RebirthClass = Network and Network:FindFirstChild("RebirthClass")
local ClaimReward = Network and Network:FindFirstChild("ClaimReward")
local HealthInspector_ClaimRewards = Network and Network:FindFirstChild("HealthInspector_ClaimRewards")
local TycoonPurchase = Remotes and Remotes:FindFirstChild("TycoonPurchase")
local EmployeeUpgrade = Remotes and Remotes:FindFirstChild("EmployeeUpgrade")

local function AutoBurger()
    if not LinkPlayerToOrder or not TryAddIngredientToPlate then return end
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
    if not AddMoney then return end
    while Settings.AutoSellEnabled do
        pcall(function() AddMoney:FireServer() end)
        task.wait(Settings.SellDelay)
    end
end

local function AutoCollect()
    if not ClaimReward then return end
    while Settings.AutoCollectEnabled do
        pcall(function()
            ClaimReward:FireServer()
            if HealthInspector_ClaimRewards then HealthInspector_ClaimRewards:FireServer() end
        end)
        task.wait(Settings.CollectDelay)
    end
end

local function AutoRebirth()
    if not RebirthClass then return end
    while Settings.AutoRebirthEnabled do
        pcall(function() RebirthClass:FireServer() end)
        task.wait(Settings.RebirthDelay)
    end
end

local function AutoUpgradeFloors()
    if not BuyPcUpgradeRequest then return end
    while Settings.AutoUpgradeFloorsEnabled do
        pcall(function() BuyPcUpgradeRequest:FireServer() end)
        task.wait(Settings.UpgradeFloorsDelay)
    end
end

local function AutoUpgradeLives()
    if not EmployeeUpgrade then return end
    while Settings.AutoUpgradeLivesEnabled do
        pcall(function() EmployeeUpgrade:InvokeServer() end)
        task.wait(Settings.UpgradeLivesDelay)
    end
end

local function AutoBegin()
    if not RequestOrderBoard then return end
    while Settings.AutoBeginEnabled do
        pcall(function() RequestOrderBoard:InvokeServer() end)
        task.wait(Settings.BeginDelay)
    end
end

local function AutoContinue()
    if not TycoonPurchase then return end
    while Settings.AutoContinueEnabled do
        pcall(function() TycoonPurchase:FireServer() end)
        task.wait(Settings.ContinueDelay)
    end
end

-- ═══════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "Ivory",
    Icon = "burger",
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
    SearchKeybind = Enum.KeyCode.F,
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

local MainTab = Window:AddTab({ Name = "Main", Icon = "burger", Description = "Automation" })
local DelaysTab = Window:AddTab({ Name = "Delays", Icon = "clock", Description = "Adjust Delays" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Themes & UI" })

-- ═══ MAIN TAB: Automation Sub-Tab ═══
local AutoSub = MainTab:AddSubTab({ Name = "Automation", Icon = "zap" })

local BurgerBox = AutoSub:AddLeftGroupbox("Burger", "burger")
BurgerBox:AddToggle("AutoBurger", { Text = "Auto Burger Perfect", Default = false })
BurgerBox:AddToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false })

local UpgradeBox = AutoSub:AddRightGroupbox("Upgrades", "arrow-up-circle")
UpgradeBox:AddToggle("AutoUpgradeFloors", { Text = "Auto Upgrade Floors", Default = false })
UpgradeBox:AddToggle("AutoUpgradeLives", { Text = "Auto Upgrade Lives", Default = false })

local EconBox = AutoSub:AddLeftGroupbox("Economy", "coins")
EconBox:AddToggle("AutoSell", { Text = "Auto Sell", Default = false })
EconBox:AddToggle("AutoCollect", { Text = "Auto Collect Cash", Default = false })

local BuildBox = AutoSub:AddRightGroupbox("Building", "hammer")
BuildBox:AddToggle("AutoBegin", { Text = "Auto Begin", Default = false })
BuildBox:AddToggle("AutoContinue", { Text = "Auto Continue (Cancel)", Default = false })

-- ═══ DELAYS TAB ═══
local DelaySub = DelaysTab:AddSubTab({ Name = "Delays", Icon = "clock" })

local DL1 = DelaySub:AddLeftGroupbox("Delays (seconds)", "clock")
DL1:AddSlider("BurgerDelay", { Text = "Burger Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })
DL1:AddSlider("SellDelay", { Text = "Sell Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })
DL1:AddSlider("CollectDelay", { Text = "Collect Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })
DL1:AddSlider("RebirthDelay", { Text = "Rebirth Delay", Default = 1, Min = 0.01, Max = 10, Rounding = 2, Suffix = "s" })

local DL2 = DelaySub:AddRightGroupbox("More Delays", "clock")
DL2:AddSlider("UpgradeFloorsDelay", { Text = "Upgrade Floors Delay", Default = 0.5, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })
DL2:AddSlider("UpgradeLivesDelay", { Text = "Upgrade Lives Delay", Default = 0.5, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })
DL2:AddSlider("BeginDelay", { Text = "Begin Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })
DL2:AddSlider("ContinueDelay", { Text = "Continue Delay", Default = 0.1, Min = 0.01, Max = 5, Rounding = 2, Suffix = "s" })

-- ═══ SETTINGS TAB ═══
local ThemesSub = SettingsTab:AddSubTab({ Name = "Themes & UI", Icon = "palette" })
local ConfigSub = SettingsTab:AddSubTab({ Name = "Config", Icon = "save" })

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("burgerperfect")
ThemeManager:ApplyToTab(ThemesSub)
SaveManager:BuildConfigSection(ConfigSub)

local MenuGroup = ThemesSub:AddLeftGroupbox("Menu", "wrench")
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

-- ═══════════════════════════════════════
-- CALLBACKS
-- ═══════════════════════════════════════
Toggles.AutoBurger:OnChanged(function(s) Settings.AutoBurgerEnabled = s if s then task.spawn(AutoBurger) end end)
Toggles.AutoSell:OnChanged(function(s) Settings.AutoSellEnabled = s if s then task.spawn(AutoSell) end end)
Toggles.AutoCollect:OnChanged(function(s) Settings.AutoCollectEnabled = s if s then task.spawn(AutoCollect) end end)
Toggles.AutoRebirth:OnChanged(function(s) Settings.AutoRebirthEnabled = s if s then task.spawn(AutoRebirth) end end)
Toggles.AutoUpgradeFloors:OnChanged(function(s) Settings.AutoUpgradeFloorsEnabled = s if s then task.spawn(AutoUpgradeFloors) end end)
Toggles.AutoUpgradeLives:OnChanged(function(s) Settings.AutoUpgradeLivesEnabled = s if s then task.spawn(AutoUpgradeLives) end end)
Toggles.AutoBegin:OnChanged(function(s) Settings.AutoBeginEnabled = s if s then task.spawn(AutoBegin) end end)
Toggles.AutoContinue:OnChanged(function(s) Settings.AutoContinueEnabled = s if s then task.spawn(AutoContinue) end end)

Options.BurgerDelay:OnChanged(function(v) Settings.BurgerDelay = v end)
Options.SellDelay:OnChanged(function(v) Settings.SellDelay = v end)
Options.CollectDelay:OnChanged(function(v) Settings.CollectDelay = v end)
Options.RebirthDelay:OnChanged(function(v) Settings.RebirthDelay = v end)
Options.UpgradeFloorsDelay:OnChanged(function(v) Settings.UpgradeFloorsDelay = v end)
Options.UpgradeLivesDelay:OnChanged(function(v) Settings.UpgradeLivesDelay = v end)
Options.BeginDelay:OnChanged(function(v) Settings.BeginDelay = v end)
Options.ContinueDelay:OnChanged(function(v) Settings.ContinueDelay = v end)

Library:Notify({
    Title = "Ivory",
    Description = "Build A Burger loaded. RightShift to toggle menu.",
    Type = "Success",
    Time = 3,
})
