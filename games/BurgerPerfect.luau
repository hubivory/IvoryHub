-- ===============================================================
-- IVORY HUB - BURGER PERFECT AUTO
-- ObsidianUltra UI
-- ===============================================================

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(request({ Url = repo .. "Library.lua", Method = "GET" }).Body)()
local ThemeManager = loadstring(request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body)()
local SaveManager = loadstring(request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body)()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Options = Library.Options
local Toggles = Library.Toggles

-- ===============================================================
-- SETTINGS / STATE
-- ===============================================================
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

-- ===============================================================
-- GET REMOTES
-- ===============================================================
local RS = game:GetService("ReplicatedStorage")
local Network = RS:WaitForChild("Network", 15)
local Remotes = RS:WaitForChild("Remotes", 15)

local LinkPlayerToOrder = Network and Network:FindFirstChild("LinkPlayerToOrder")
local UnlinkPlayerFromOrder = Network and Network:FindFirstChild("UnlinkPlayerFromOrder")
local RequestOrderBoard = Network and Network:FindFirstChild("RequestOrderBoard")
local TryAddIngredientToPlate = Network and Network:FindFirstChild("TryAddIngredientToPlate")
local RequestMeatSeasoning = Network and Network:FindFirstChild("RequestMeatSeasoning")
local AddTimeToMeat = Network and Network:FindFirstChild("AddTimeToMeat")
local RequestFriesSeasoning = Network and Network:FindFirstChild("RequestFriesSeasoning")
local AddTimeToFries = Network and Network:FindFirstChild("AddTimeToFries")
local AddMoney = Network and Network:FindFirstChild("AddMoney")
local GetCashRegisterData = Network and Network:FindFirstChild("GetCashRegisterData")
local BuyPcUpgradeRequest = Network and Network:FindFirstChild("BuyPcUpgradeRequest")
local RebirthClass = Network and Network:FindFirstChild("RebirthClass")
local ClaimReward = Network and Network:FindFirstChild("ClaimReward")
local HealthInspector_ClaimRewards = Network and Network:FindFirstChild("HealthInspector_ClaimRewards")
local TycoonPurchase = Remotes and Remotes:FindFirstChild("TycoonPurchase")
local EmployeeUpgrade = Remotes and Remotes:FindFirstChild("EmployeeUpgrade")

-- ===============================================================
-- AUTO FUNCTIONS
-- ===============================================================
local function AutoBurger()
    if not LinkPlayerToOrder or not TryAddIngredientToPlate then warn("[Ivory] Order remotes missing") return end
    while Settings.AutoBurgerEnabled do
        pcall(function()
            -- Request order board, link to order, add ingredients, season, complete
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
-- THEME TOKENS
-- ===============================================================
local Tokens = {
    primary = Color3.fromRGB(168, 120, 255),
    background = Color3.fromRGB(18, 16, 26),
    surface = Color3.fromRGB(26, 22, 38),
    text = Color3.fromRGB(248, 244, 255),
    cornerRadius = 8,
}
Library.Scheme.BackgroundColor = Tokens.background
Library.Scheme.MainColor = Tokens.surface
Library.Scheme.AccentColor = Tokens.primary
Library.Scheme.FontColor = Tokens.text

-- ===============================================================
-- WINDOW
-- ===============================================================
local Window = Library:CreateWindow({
    Title = "Ivory",
    Icon = "flame",
    Footer = {
        "v1.4 |",
        { Text = "Game", Copyable = true },
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
Window:SetCornerRadius(Tokens.cornerRadius)

-- ===============================================================
-- TABS
-- ===============================================================
local MainTab = Window:AddTab({ Name = "Main", Icon = "flame" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ===============================================================
-- MAIN TAB - AUTOMATION
-- ===============================================================
local AutoSub = MainTab:AddSubTab({ Name = "Automation", Icon = "zap" })

local BurgerBox = AutoSub:AddLeftGroupbox("Burger", "flame")
BurgerBox:AddToggle("AutoBurgerEnabled", {
    Text = "Auto Burger Perfect",
    Default = false,
    Callback = function(v)
        Settings.AutoBurgerEnabled = v
        if v then task.spawn(AutoBurger) end
    end,
}):AddKeyPicker("AutoBurgerKey", {
    Default = "None",
    Text = "Auto Burger Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

local SellBox = AutoSub:AddRightGroupbox("Economy", "coins")
SellBox:AddToggle("AutoSellEnabled", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(v)
        Settings.AutoSellEnabled = v
        if v then task.spawn(AutoSell) end
    end,
}):AddKeyPicker("AutoSellKey", {
    Default = "None",
    Text = "Auto Sell Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

SellBox:AddToggle("AutoCollectEnabled", {
    Text = "Auto Collect Cash (All Slots)",
    Default = false,
    Callback = function(v)
        Settings.AutoCollectEnabled = v
        if v then task.spawn(AutoCollect) end
    end,
}):AddKeyPicker("AutoCollectKey", {
    Default = "None",
    Text = "Auto Collect Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

SellBox:AddToggle("AutoRebirthEnabled", {
    Text = "Auto Rebirth",
    Default = false,
    Callback = function(v)
        Settings.AutoRebirthEnabled = v
        if v then task.spawn(AutoRebirth) end
    end,
}):AddKeyPicker("AutoRebirthKey", {
    Default = "None",
    Text = "Auto Rebirth Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

local UpgradeBox = AutoSub:AddLeftGroupbox("Upgrades", "arrow-up-circle")
UpgradeBox:AddToggle("AutoUpgradeFloorsEnabled", {
    Text = "Auto Upgrade Floors",
    Default = false,
    Callback = function(v)
        Settings.AutoUpgradeFloorsEnabled = v
        if v then task.spawn(AutoUpgradeFloors) end
    end,
}):AddKeyPicker("AutoUpgradeFloorsKey", {
    Default = "None",
    Text = "Upgrade Floors Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

UpgradeBox:AddToggle("AutoUpgradeLivesEnabled", {
    Text = "Auto Upgrade Lives",
    Default = false,
    Callback = function(v)
        Settings.AutoUpgradeLivesEnabled = v
        if v then task.spawn(AutoUpgradeLives) end
    end,
}):AddKeyPicker("AutoUpgradeLivesKey", {
    Default = "None",
    Text = "Upgrade Lives Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

local BuildBox = AutoSub:AddRightGroupbox("Building", "hammer")
BuildBox:AddToggle("AutoBeginEnabled", {
    Text = "Auto Begin",
    Default = false,
    Callback = function(v)
        Settings.AutoBeginEnabled = v
        if v then task.spawn(AutoBegin) end
    end,
}):AddKeyPicker("AutoBeginKey", {
    Default = "None",
    Text = "Auto Begin Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

BuildBox:AddToggle("AutoContinueEnabled", {
    Text = "Auto Continue (Cancel)",
    Default = false,
    Callback = function(v)
        Settings.AutoContinueEnabled = v
        if v then task.spawn(AutoContinue) end
    end,
}):AddKeyPicker("AutoContinueKey", {
    Default = "None",
    Text = "Auto Continue Key",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = false,
})

-- ===============================================================
-- MAIN TAB - DELAYS
-- ===============================================================
local DelaySub = MainTab:AddSubTab({ Name = "Delays", Icon = "clock" })

local DelayBox = DelaySub:AddLeftGroupbox("Adjust Delays (seconds)", "clock")
DelayBox:AddSlider("BurgerDelay", {
    Text = "Burger Delay",
    Default = 0.1,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.BurgerDelay = v end,
})
DelayBox:AddSlider("SellDelay", {
    Text = "Sell Delay",
    Default = 0.1,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.SellDelay = v end,
})
DelayBox:AddSlider("CollectDelay", {
    Text = "Collect Delay",
    Default = 0.1,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.CollectDelay = v end,
})
DelayBox:AddSlider("RebirthDelay", {
    Text = "Rebirth Delay",
    Default = 1,
    Min = 0.01,
    Max = 10,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.RebirthDelay = v end,
})

local DelayBox2 = DelaySub:AddRightGroupbox("More Delays", "clock")
DelayBox2:AddSlider("UpgradeFloorsDelay", {
    Text = "Upgrade Floors Delay",
    Default = 0.5,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.UpgradeFloorsDelay = v end,
})
DelayBox2:AddSlider("UpgradeLivesDelay", {
    Text = "Upgrade Lives Delay",
    Default = 0.5,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.UpgradeLivesDelay = v end,
})
DelayBox2:AddSlider("BeginDelay", {
    Text = "Begin Delay",
    Default = 0.1,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v) Settings.BeginDelay = v end,
})
DelayBox2:AddSlider("ContinueDelay", {
    Text = "Continue Delay",
    Default = 0.1,
    Min = 0.01,
    Max = 5,
    Rounding = 2,
    Suffix = "s",
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
    Default = Library.ShowCustomCursor,
    Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddButton("Test Notification", function()
    Library:Notify({ Title = "Ivory", Description = "Works!", Time = 4 })
end)
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
    Description = "Burger Perfect Auto loaded. RightShift to open menu.",
    Type = "Success",
    Time = 4,
})
Window:SetMinimizedSubtitle("Ivory | Burger Perfect Auto")