local LIB_SRC = getgenv()._IvoryLibSrc
if not LIB_SRC then
	local ok, src = pcall(function()
		return request({
			Url = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua",
			Method = "GET"
		}).Body
	end)
	if ok then LIB_SRC = src end
end
local Library = loadstring(LIB_SRC)()

if not Library then
    warn("[Ivory] Ivory Hub failed to load - aborting")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Settings = {
    AutoBurgerEnabled = false,
    AutoSellEnabled = false,
    AutoCollectEnabled = false,
    AutoRebirthEnabled = false,
    AutoUpgradeFloorsEnabled = false,
    AutoUpgradeLivesEnabled = false,

    BurgerDelay = 0.1,
    SellDelay = 0.1,
    CollectDelay = 0.1,
    RebirthDelay = 1,
    UpgradeFloorsDelay = 0.5,
    UpgradeLivesDelay = 0.5,
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

local function AutoBurger()
    pcall(function()
        if BuildingBegin then BuildingBegin:FireServer() end
    end)
    task.wait(0.5)
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

-- ---------------------------------------
-- WINDOW
-- ---------------------------------------
local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 460,
    Height = 360,
})

local MainTab = Window:CreateTab({ Name = "Main" })
local DelaysTab = Window:CreateTab({ Name = "Delays" })
local SettingsTab = Window:CreateTab({ Name = "Settings" })

-- --- MAIN TAB: Automation Sub-Tab ---
local AutoSub = MainTab:CreateSection("Automation")

local BurgerBox = AutoSub:CreateSection("Burger")
BurgerBox:CreateToggle({ Name = "Auto Burger Perfect", CurrentValue = false, Callback = function(v) Settings.AutoBurgerEnabled = v if v then task.spawn(AutoBurger) end end })
BurgerBox:CreateToggle({ Name = "Auto Rebirth", CurrentValue = false, Callback = function(v) Settings.AutoRebirthEnabled = v if v then task.spawn(AutoRebirth) end end })

local UpgradeBox = AutoSub:CreateSection("Upgrades")
UpgradeBox:CreateToggle({ Name = "Auto Upgrade Floors", CurrentValue = false, Callback = function(v) Settings.AutoUpgradeFloorsEnabled = v if v then task.spawn(AutoUpgradeFloors) end end })
UpgradeBox:CreateToggle({ Name = "Auto Upgrade Lives", CurrentValue = false, Callback = function(v) Settings.AutoUpgradeLivesEnabled = v if v then task.spawn(AutoUpgradeLives) end end })

local EconBox = AutoSub:CreateSection("Economy")
EconBox:CreateToggle({ Name = "Auto Sell", CurrentValue = false, Callback = function(v) Settings.AutoSellEnabled = v if v then task.spawn(AutoSell) end end })
EconBox:CreateToggle({ Name = "Auto Collect Cash", CurrentValue = false, Callback = function(v) Settings.AutoCollectEnabled = v if v then task.spawn(AutoCollect) end end })

-- --- DELAYS TAB ---
local DelaySub = DelaysTab:CreateSection("Delays")

local DL1 = DelaySub:CreateSection("Delays (seconds)")
DL1:CreateSlider({ Name = "Burger Delay", Range = {0.01, 5}, Increment = 0.01, CurrentValue = 0.1, Callback = function(v) Settings.BurgerDelay = v end })
DL1:CreateSlider({ Name = "Sell Delay", Range = {0.01, 5}, Increment = 0.01, CurrentValue = 0.1, Callback = function(v) Settings.SellDelay = v end })
DL1:CreateSlider({ Name = "Collect Delay", Range = {0.01, 5}, Increment = 0.01, CurrentValue = 0.1, Callback = function(v) Settings.CollectDelay = v end })
DL1:CreateSlider({ Name = "Rebirth Delay", Range = {0.01, 10}, Increment = 0.01, CurrentValue = 1, Callback = function(v) Settings.RebirthDelay = v end })

local DL2 = DelaySub:CreateSection("More Delays")
DL2:CreateSlider({ Name = "Upgrade Floors Delay", Range = {0.01, 5}, Increment = 0.01, CurrentValue = 0.5, Callback = function(v) Settings.UpgradeFloorsDelay = v end })
DL2:CreateSlider({ Name = "Upgrade Lives Delay", Range = {0.01, 5}, Increment = 0.01, CurrentValue = 0.5, Callback = function(v) Settings.UpgradeLivesDelay = v end })

-- --- SETTINGS TAB ---
local CreditGroup = SettingsTab:CreateSection("Credits")
local CreditLabel = CreditGroup:CreateLabel("")
task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:SetText(shown .. cursor)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:SetText(shown .. cursor)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

local MenuGroup = SettingsTab:CreateSection("Menu")
MenuGroup:CreateToggle({
    Name = "Open Keybind Menu",
    CurrentValue = false,
})
MenuGroup:CreateToggle({
    Name = "Custom Cursor",
    CurrentValue = false,
})
MenuGroup:CreateDropdown({
    Name = "Notification Side",
    Options = { "Left", "Right" },
    CurrentOption = "Right",
})
MenuGroup:CreateDivider()
MenuGroup:CreateLabel("Menu bind")
MenuGroup:CreateKeybind({ Name = "Menu keybind", CurrentKeybind = "RightShift" })
MenuGroup:CreateButton({ Name = "Join Discord", Callback = function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 }) end })
MenuGroup:CreateButton({ Name = "Unload", Callback = function()
    Library:Unload()
end })

Library.Notify({
    Title = "Ivory",
    Content = "Build A Burger loaded. RightShift to toggle menu.",
    Type = "Success",
    Duration = 3,
})