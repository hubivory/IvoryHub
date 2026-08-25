-- ===============================================================
-- IVORY HUB - BUILD A BURGER AUTO
-- Obsidian UI (deividcomsono/Obsidian)
-- ===============================================================

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
-- UI LOAD
-- ===============================================================
local function SafeLoad(name, url)
    local body = nil
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok and res and typeof(res) == "string" and #res > 100 and not res:find("404") then
        body = res
    end
    if not body then
        local ok2, res2 = pcall(function()
            return request({ Url = url, Method = "GET" }).Body
        end)
        if ok2 and res2 and typeof(res2) == "string" and #res2 > 100 and not res2:find("404") then
            body = res2
        end
    end
    if not body then
        warn("[Ivory] Failed to fetch " .. name)
        return nil
    end
    local fn, err = loadstring(body)
    if not fn then
        warn("[Ivory] Failed to compile " .. name .. ": " .. tostring(err))
        return nil
    end
    return fn()
end

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = SafeLoad("Library", repo .. "Library.lua")
local ThemeManager = SafeLoad("ThemeManager", repo .. "addons/ThemeManager.lua")
local SaveManager = SafeLoad("SaveManager", repo .. "addons/SaveManager.lua")

if not Library then
    warn("[Ivory] ObsidianUltra failed to load")
    return
end

local Options = Library.Options
local Toggles = Library.Toggles

-- ===============================================================
-- THEME
-- ===============================================================
Library.Scheme.BackgroundColor = Color3.fromRGB(18, 16, 26)
Library.Scheme.MainColor = Color3.fromRGB(26, 22, 38)
Library.Scheme.AccentColor = Color3.fromRGB(168, 120, 255)
Library.Scheme.FontColor = Color3.fromRGB(248, 244, 255)

-- ===============================================================
-- WINDOW
-- ===============================================================
local Window = Library:CreateWindow({
    Title = "Ivory | Build A Burger",
    Footer = "v1.0",
    Center = true,
    AutoShow = true,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- ===============================================================
-- TABS
-- ===============================================================
local Tabs = {
    Main = Window:AddTab("Main", "flame"),
    Delays = Window:AddTab("Delays", "clock"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- ===============================================================
-- MAIN TAB
-- ===============================================================
local AutoLeft = Tabs.Main:AddLeftGroupbox("Automation")
local AutoRight = Tabs.Main:AddRightGroupbox("Economy & Building")

AutoLeft:AddToggle("AutoBurger", {
    Text = "Auto Burger Perfect",
    Default = false,
    Callback = function(v)
        Settings.AutoBurgerEnabled = v
        if v then task.spawn(AutoBurger) end
    end,
})
AutoLeft:AddToggle("AutoRebirth", {
    Text = "Auto Rebirth",
    Default = false,
    Callback = function(v)
        Settings.AutoRebirthEnabled = v
        if v then task.spawn(AutoRebirth) end
    end,
})
AutoLeft:AddToggle("AutoUpgradeFloors", {
    Text = "Auto Upgrade Floors",
    Default = false,
    Callback = function(v)
        Settings.AutoUpgradeFloorsEnabled = v
        if v then task.spawn(AutoUpgradeFloors) end
    end,
})
AutoLeft:AddToggle("AutoUpgradeLives", {
    Text = "Auto Upgrade Lives",
    Default = false,
    Callback = function(v)
        Settings.AutoUpgradeLivesEnabled = v
        if v then task.spawn(AutoUpgradeLives) end
    end,
})

AutoRight:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(v)
        Settings.AutoSellEnabled = v
        if v then task.spawn(AutoSell) end
    end,
})
AutoRight:AddToggle("AutoCollect", {
    Text = "Auto Collect Cash",
    Default = false,
    Callback = function(v)
        Settings.AutoCollectEnabled = v
        if v then task.spawn(AutoCollect) end
    end,
})
AutoRight:AddToggle("AutoBegin", {
    Text = "Auto Begin",
    Default = false,
    Callback = function(v)
        Settings.AutoBeginEnabled = v
        if v then task.spawn(AutoBegin) end
    end,
})
AutoRight:AddToggle("AutoContinue", {
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
local DelayLeft = Tabs.Delays:AddLeftGroupbox("Delays (seconds)")
local DelayRight = Tabs.Delays:AddRightGroupbox("More Delays")

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
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")
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
    Time = 3,
})
