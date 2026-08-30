local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(request({ Url = repo .. "Library.lua", Method = "GET" }).Body)()
local ThemeManager = loadstring(request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body)()
local SaveManager = loadstring(request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body)()

local Toggles = Library.Toggles
local Options = Library.Options

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CounterRemotes = Remotes:WaitForChild("CounterRemotes")
local GetCounterInfo = CounterRemotes:WaitForChild("GetCounterInfo")
local AssignNPC = CounterRemotes:WaitForChild("AssignNPC")
local RejectNPC = CounterRemotes:WaitForChild("RejectNPC")
local RedeemCodeRemote = Remotes:WaitForChild("RedeemCode"):WaitForChild("RedeemCode")
local ShopRemotes = Remotes:WaitForChild("ShopRemotes")
local BuyFurniture = ShopRemotes:WaitForChild("BuyFurniture")
local GetShopInfo = ShopRemotes:WaitForChild("GetShopInfo")
local GetFurnitureInventory = ShopRemotes:WaitForChild("GetFurnitureInventory")
local BuyTableEvent = Remotes:WaitForChild("BuyTableEvent")
local GetUnlockedTables = Remotes:WaitForChild("GetUnlockedTables")
local PlaceFurnitureEvent = Remotes:WaitForChild("PlaceFurnitureEvent")
local BuyIngredient = ShopRemotes:WaitForChild("BuyIngredient")
local ToggleStoreStatus = Remotes:WaitForChild("ToggleStoreStatus")
local UseBoostEvent = Remotes:WaitForChild("UseBoostEvent")
local UpgradeToGoldenPan = Remotes:WaitForChild("UpgradeToGoldenPan")
local NPCRemotes = Remotes:WaitForChild("NPCRemotes")
local SoftdrinkOrdersUpdated = NPCRemotes:WaitForChild("SoftdrinkOrdersUpdated")
local AdditionalOrder = NPCRemotes:WaitForChild("AdditionalOrder")
local NPCDrink = NPCRemotes:WaitForChild("NPCDrink")
local GiveSoftdrink = ShopRemotes:WaitForChild("GiveSoftdrink")
local MenuRemotes = Remotes:WaitForChild("MenuRemotes")
local UnlockMenu = MenuRemotes:WaitForChild("UnlockMenu")
local ToggleMenu = MenuRemotes:WaitForChild("ToggleMenu")
local GetMenuData = MenuRemotes:WaitForChild("GetMenuData")
local ChillerRemotes = Remotes:WaitForChild("ChillerRemotes")
local StartRepair = ChillerRemotes:WaitForChild("StartRepair")
local MerchantRemotes = Remotes:WaitForChild("MerchantRemotes")
local GetMerchantStock = MerchantRemotes:WaitForChild("GetMerchantStock")
local BuyMerchantItem = MerchantRemotes:WaitForChild("BuyMerchantItem")
local MysteryBoxRemotes = Remotes:WaitForChild("MysteryBoxRemotes")
local BuyMysteryBox = MysteryBoxRemotes:WaitForChild("BuyMysteryBox")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local FoodConfig = require(Modules:WaitForChild("FoodConfig"))
local IngredientsConfig = require(Modules:WaitForChild("IngredientsConfig"))
local SoftdrinkConfig = require(Modules:WaitForChild("SoftdrinkConfig"))
local FurnitureConfig = require(Modules:WaitForChild("FurnitureConfig"))
local NPCConfig = require(Modules:WaitForChild("NPCConfig"))
local MysteryBoxConfig = require(Modules:WaitForChild("MysteryBoxConfig"))

-- Build NPC list with rarities
local npcNamesWithRarity = {}
local npcRarityMap = {}
for name, data in pairs(NPCConfig.Types) do
    local rarity = data.Rarity or "Unknown"
    table.insert(npcNamesWithRarity, name .. " [" .. rarity .. "]")
    npcRarityMap[name .. " [" .. rarity .. "]"] = name
end
table.sort(npcNamesWithRarity)
table.insert(npcNamesWithRarity, 1, "None")

-- ═══════════════════════════════════════
-- SOFTDRINK ORDER TRACKING
-- ═══════════════════════════════════════
local activeDrinkOrders = {}
local lastDrinkAttempt = {}
local drinkConns = {}

local function resolveDrinkKey(rawKey)
    if not rawKey then return "Kola" end
    local str = tostring(rawKey)
    local lower = str:lower():gsub("%s+", "")
    for ingName, _ in pairs(IngredientsConfig or {}) do
        if tostring(ingName):lower():gsub("%s+", "") == lower then
            return ingName
        end
    end
    if lower == "cola" or lower == "kola" then
        return IngredientsConfig["Kola"] and "Kola" or str
    elseif lower == "suprise" or lower == "surprise" then
        return IngredientsConfig["Suprise"] and "Suprise" or str
    elseif lower == "loyal" then
        return "Loyal"
    end
    return str
end

local function disconnectDrinkConns()
    for _, conn in ipairs(drinkConns) do
        pcall(function() conn:Disconnect() end)
    end
    drinkConns = {}
end

disconnectDrinkConns()

table.insert(drinkConns, SoftdrinkOrdersUpdated.OnClientEvent:Connect(function(orders)
    if type(orders) == "table" then
        activeDrinkOrders = {}
        for _, drink in pairs(orders) do
            table.insert(activeDrinkOrders, resolveDrinkKey(drink))
        end
    end
end))

table.insert(drinkConns, AdditionalOrder.OnClientEvent:Connect(function(_npcName, drinkKey)
    if drinkKey ~= nil then
        table.insert(activeDrinkOrders, resolveDrinkKey(drinkKey))
    end
end))

local drinkStats = { given = 0, state = "Watching for requests" }

table.insert(drinkConns, NPCDrink.OnClientEvent:Connect(function(_npcName, drinkKey)
    drinkStats.given = drinkStats.given + 1
    drinkStats.state = string.format("Delivered %s!", resolveDrinkKey(drinkKey))
end))

-- ═══════════════════════════════════════
-- TELEPORT LOCK - only one feature teleports at a time
-- ═══════════════════════════════════════
local tpLock = false

-- Waits until the lock is free, takes it, returns a release function
local function acquireTp()
    while tpLock do task.wait(0.05) end
    tpLock = true
    return function() tpLock = false end
end

local function getChar() return LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end

local function tp(cframe)
    local c = LocalPlayer.Character
    if c then local h = c:FindFirstChild("HumanoidRootPart") if h then h.CFrame = cframe end end
end

local function getPlot()
    for _, v in ipairs(Workspace:GetChildren()) do
        if string.find(v.Name, "^Karenderya") and v:GetAttribute("Owner") == LocalPlayer.UserId then return v end
    end
end

local function hasIngredients(orderName)
    if not orderName or not FoodConfig[orderName] then return true end
    local req = FoodConfig[orderName].RequiredIngredients
    if not req then return true end
    local ing = LocalPlayer:FindFirstChild("Ingredients")
    if not ing then return false end
    for _, name in ipairs(req) do local v = ing:FindFirstChild(name) if not v or v.Value <= 0 then return false end end
    return true
end

-- Parse inventory key "Tables_MonoblockTable" -> "Tables", "MonoblockTable"
local function parseInvKey(fullKey)
    local cat, key = string.match(fullKey, "^(%w+)_(.+)$")
    return cat, key
end

local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then local c = ls:FindFirstChild("Cash") if c then return c.Value end end
    return 0
end

-- ═══════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════
local cfg = {
    autoServe = false,
    autoOrder = false,
    autoRejectNPC = false,
    rejectNPCList = {},
    autoClaimCodes = false,
    autoPan = false,
    autoClean = false,
    autoWash = false,
    autoBuyFurniture = false,
    autoPlaceFurniture = false,
    furnitureWhitelist = {},
    autoBuyIngredients = false,
    autoSoftdrinks = false,
    autoFixChiller = false,
    autoBuyMerchant = false,
    merchantWhitelist = {},
    autoBuyMysteryBox = false,
    autoOpenMysteryBox = false,
    autoUseBoosts = false,
    autoUnlockTables = false,
    autoUnlockMenu = false,
    noclip = false,
    antiAfk = false,
    espNPCs = false,
    walkSpeed = 16,
    infJump = false,
}

-- ═══════════════════════════════════════
-- SOFTDRINK FULFILLMENT (needs cfg)
-- ═══════════════════════════════════════
local function buyIngredient(key)
    local ingCfg = IngredientsConfig[key]
    if not ingCfg or not ingCfg.Cost then return false end
    if getCash() - ingCfg.Cost < 5000 then return false end
    local ok, success = pcall(function()
        return BuyIngredient:InvokeServer(key, 1, "Cash")
    end)
    return ok and success
end

local function stepFulfillSoftdrinkOrders()
    if not cfg.autoSoftdrinks or #activeDrinkOrders == 0 then return false end

    local drinkKey = resolveDrinkKey(activeDrinkOrders[1])
    local now = os.clock()
    if now < (lastDrinkAttempt[drinkKey] or 0) then return false end
    lastDrinkAttempt[drinkKey] = now + 1.5

    local ingredients = LocalPlayer:FindFirstChild("Ingredients")
    local stock = ingredients and ingredients:FindFirstChild(drinkKey)
    if not stock or stock.Value <= 0 then
        if cfg.autoBuyIngredients then
            buyIngredient(drinkKey)
            task.wait(0.2)
            ingredients = LocalPlayer:FindFirstChild("Ingredients")
            stock = ingredients and ingredients:FindFirstChild(drinkKey)
        end
        if not stock or stock.Value <= 0 then
            lastDrinkAttempt[drinkKey] = now + 5
            drinkStats.state = drinkKey .. " out of stock"
            return false
        end
    end

    local ok, success, msg = pcall(function()
        return GiveSoftdrink:InvokeServer(drinkKey)
    end)

    if ok and success then
        table.remove(activeDrinkOrders, 1)
        drinkStats.given = drinkStats.given + 1
        drinkStats.state = string.format("Delivered %s!", drinkKey)
        return true
    else
        if tostring(msg):match("Nobody") or tostring(msg):match("ordered") then
            table.remove(activeDrinkOrders, 1)
        end
        drinkStats.state = string.format("%s: %s", drinkKey, tostring(msg or success))
    end
    return false
end

-- ═══════════════════════════════════════
-- MONEY LOGGING
-- ═══════════════════════════════════════
local moneyLog = { entries = {}, totalEarned = 0, totalSpent = 0, startCash = getCash() }

local function logMoney(action, amount)
    table.insert(moneyLog.entries, 1, {
        time = os.date("%H:%M:%S"),
        action = action,
        amount = amount,
        cash = getCash(),
    })
    if amount > 0 then
        moneyLog.totalEarned = moneyLog.totalEarned + amount
    else
        moneyLog.totalSpent = moneyLog.totalSpent + math.abs(amount)
    end
end

-- ═══════════════════════════════════════
-- STATUS TRACKING
-- ═══════════════════════════════════════
local status = {
    serve = "Idle",
    order = "Idle",
    codes = "Idle",
    pan = "Idle",
    clean = "Idle",
    buyFurn = "Idle",
    placeFurn = "Idle",
    buyIng = "Idle",
    drink = "Idle",
    boosts = "Idle",
    unlockTbl = "Idle",
    unlockMenu = "Idle",
    chiller = "Idle",
    merchant = "Idle",
    mysteryBox = "Idle",
}

local function setStatus(key, text)
    status[key] = text
end

-- ═══════════════════════════════════════
-- MY NPCs TRACKING (for runaway filtering)
-- ═══════════════════════════════════════
local myAssignedNPCs = {} -- tracks NPCs assigned to my tables

local function trackNPC(npcId)
    if npcId and npcId ~= "" then
        myAssignedNPCs[npcId] = true
    end
end

local function isMyRunaway(npc)
    local id = npc.Name
    return myAssignedNPCs[id] == true
end

-- Background scanner: continuously track NPCs at my tables
task.spawn(function() while true do
    local plot = getPlot()
    if plot then
        local dp = plot:FindFirstChild("DiningPlot1")
        if dp then
            for _, slot in ipairs(dp:GetChildren()) do
                if slot:IsA("Model") then
                    local o1 = slot:GetAttribute("OccupiedBy1")
                    local o2 = slot:GetAttribute("OccupiedBy2")
                    if o1 then trackNPC(o1) end
                    if o2 then trackNPC(o2) end
                end
            end
        end
    end
    task.wait(1)
end end)

-- ═══════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "Ivory",
    Footer = { "Ivory | v1.0", { Text = "v1.0", Copyable = true } },
    Minimizable = true, FuzzySearch = true, SearchValues = true,
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "utensils", Description = "Core Automation" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "shopping-cart", Description = "Buying & Inventory" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user", Description = "Character Mods" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Themes & UI" })
local LogsTab = Window:AddTab({ Name = "Logs", Icon = "scroll-text", Description = "Money & Status" })

-- ═══ MAIN TAB: Automation Sub-Tab ═══
local AutoSub = MainTab:AddSubTab({ Name = "Automation", Icon = "zap" })

local FoodBox = AutoSub:AddLeftGroupbox("Food", "utensils")
FoodBox:AddToggle("AutoServe", { Text = "Auto Serve Food", Default = false })
FoodBox:AddToggle("AutoOrder", { Text = "Auto Assign Customers", Default = false })
FoodBox:AddToggle("AutoSoftdrinks", { Text = "Auto Serve Drinks", Default = false, Tooltip = "Instantly fulfills customer drink orders from inventory via GiveSoftdrink remote" })

FoodBox:AddDropdown("RejectNPCList", {
	Values = {},
	Multi = true,
	Default = {},
	Text = "Reject NPCs",
})
Options.RejectNPCList:SetValues(npcNamesWithRarity)
FoodBox:AddToggle("AutoRejectNPC", { Text = "Auto Reject Selected NPCs", Default = false })

local KitchenBox = AutoSub:AddLeftGroupbox("Kitchen", "chef-hat")
KitchenBox:AddToggle("AutoClean", { Text = "Auto Clean Tables", Default = false })
KitchenBox:AddToggle("AutoWash", { Text = "Auto Wash Dishes", Default = false, Tooltip = "Auto-collects dirty dishes, puts in sink, and washes them" })
KitchenBox:AddToggle("AutoPan", { Text = "Auto Pan (Hit Runaway)", Default = false })
KitchenBox:AddToggle("AutoFixChiller", { Text = "Auto Fix Chiller", Default = false, Tooltip = "Auto-repairs the chiller when it breaks (costs $200,000)" })

local CodesBox = AutoSub:AddRightGroupbox("Codes", "ticket")
CodesBox:AddToggle("AutoClaimCodes", { Text = "Auto Claim Codes", Default = false })

local DelaysBox = AutoSub:AddRightGroupbox("Delays", "settings")
DelaysBox:AddSlider("ServeDelay", { Text = "Serve Delay", Default = 1, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })
DelaysBox:AddSlider("OrderDelay", { Text = "Order Delay", Default = 2, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })
DelaysBox:AddSlider("CleanDelay", { Text = "Clean Delay", Default = 2, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })
DelaysBox:AddSlider("WashDelay", { Text = "Wash Delay", Default = 2, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })

-- ═══ MAIN TAB: Furniture & Menu Sub-Tab ═══
local FurnMenuSub = MainTab:AddSubTab({ Name = "Furniture & Menu", Icon = "armchair" })

local FurnBox = FurnMenuSub:AddLeftGroupbox("Furniture", "armchair")
FurnBox:AddToggle("AutoBuyFurniture", { Text = "Auto Buy Furniture", Default = false })
FurnBox:AddToggle("AutoPlaceFurniture", { Text = "Auto Place Furniture", Default = false })
FurnBox:AddSlider("FurnDelay", { Text = "Furniture Delay", Default = 5, Min = 2, Max = 20, Rounding = 1, Suffix = "s" })

-- Build furniture list for dropdown
local furnitureList = {}
do
    local furnCfg = require(Modules:WaitForChild("FurnitureConfig"))
    if furnCfg.Dining then
        if furnCfg.Dining.Tables then
            for k, v in pairs(furnCfg.Dining.Tables) do
                if type(v) == "table" then table.insert(furnitureList, "Tables: " .. k) end
            end
        end
        if furnCfg.Dining.Chairs then
            for k, v in pairs(furnCfg.Dining.Chairs) do
                if type(v) == "table" then table.insert(furnitureList, "Chairs: " .. k) end
            end
        end
    end
    if furnCfg.Kitchen and furnCfg.Kitchen.Stoves then
        for k, v in pairs(furnCfg.Kitchen.Stoves) do
            if type(v) == "table" then table.insert(furnitureList, "Stoves: " .. k) end
        end
    end
    table.sort(furnitureList)
    table.insert(furnitureList, 1, "None")
end

FurnBox:AddDropdown("FurnitureWhitelist", {
    Values = furnitureList,
    Multi = true,
    Default = {},
    Text = "Buy Only These",
    Tooltip = "Select which furniture to auto-buy. Empty = buy all",
})

local MenuBox = FurnMenuSub:AddRightGroupbox("Menu", "book-open")
MenuBox:AddToggle("AutoUnlockMenu", { Text = "Auto Unlock Menu", Default = false, Tooltip = "Unlocks SILOG & LUTONG BAHAY when requirements met" })
MenuBox:AddButton({ Text = "Enable All Menus", Func = function()
    pcall(function() ToggleMenu:InvokeServer("LUGAW", true) end)
    pcall(function() ToggleMenu:InvokeServer("SILOG", true) end)
    pcall(function() ToggleMenu:InvokeServer("LUTONG BAHAY", true) end)
end })

-- ═══ SHOP TAB: Groceries Sub-Tab ═══
local GrocerySub = ShopTab:AddSubTab({ Name = "Groceries", Icon = "apple" })

local GroceryBox = GrocerySub:AddLeftGroupbox("Ingredients", "apple")
GroceryBox:AddToggle("AutoBuyIngredients", { Text = "Auto Buy Ingredients", Default = false, Tooltip = "Auto-buys ingredients when stock is low" })
GroceryBox:AddSlider("IngBuyThreshold", { Text = "Buy When Below", Default = 5, Min = 1, Max = 50, Rounding = 1, Tooltip = "Buy ingredient when count drops below this" })

local MerchantBox = GrocerySub:AddRightGroupbox("Merchant", "store")
MerchantBox:AddToggle("AutoBuyMerchant", { Text = "Auto Buy Merchant", Default = false, Tooltip = "Auto-buys selected items from the rotating merchant when in stock" })
MerchantBox:AddDropdown("MerchantWhitelist", { Text = "Items to Buy", Multi = true, Default = 0, Values = {"FoldingChair", "FoldingTable", "BambooChair", "BambooTable", "Dipper", "Hanger", "Slipper", "MalunggayPandesal"}, Tooltip = "Select which merchant items to auto-buy" })

local UnlockBox = GrocerySub:AddRightGroupbox("Unlocks", "lock-open")
UnlockBox:AddToggle("AutoUnlockTables", { Text = "Auto Unlock Tables", Default = false, Tooltip = "Auto-unlocks Table7-12 when affordable" })
UnlockBox:AddButton({ Text = "Upgrade to Golden Pan", Func = function() pcall(function() UpgradeToGoldenPan:InvokeServer() end) end })

-- ═══ SHOP TAB: Boosts & Store Sub-Tab ═══
local BoostStoreSub = ShopTab:AddSubTab({ Name = "Boosts & Store", Icon = "zap" })

local BoostBox = BoostStoreSub:AddLeftGroupbox("Boosts", "zap")
BoostBox:AddToggle("AutoUseBoosts", { Text = "Auto Use Boosts", Default = false, Tooltip = "Auto-uses Cash/Luck/UltraLuck potions" })
BoostBox:AddButton({ Text = "Use Cash Potion", Func = function() pcall(function() UseBoostEvent:FireServer("CashPotion") end) end })
BoostBox:AddButton({ Text = "Use Luck Potion", Func = function() pcall(function() UseBoostEvent:FireServer("LuckPotion") end) end })
BoostBox:AddButton({ Text = "Use Ultra Luck Potion", Func = function() pcall(function() UseBoostEvent:FireServer("UltraLuckPotion") end) end })

local StoreBox = BoostStoreSub:AddRightGroupbox("Store", "store")
StoreBox:AddButton({ Text = "Toggle Store Open/Close", Func = function() pcall(function() ToggleStoreStatus:InvokeServer() end) end })
StoreBox:AddToggle("AutoBuyMysteryBox", { Text = "Auto Buy Mystery Box", Default = false, Tooltip = "Buys Mystery Box when you can afford it ($10,000 each, max 5)" })
StoreBox:AddToggle("AutoOpenMysteryBox", { Text = "Auto Open Mystery Box", Default = false, Tooltip = "Auto-opens mystery boxes when available" })

-- ═══ PLAYER TAB: Character Sub-Tab ═══
local CharSub = PlayerTab:AddSubTab({ Name = "Character", Icon = "person-standing" })

local CharBox = CharSub:AddLeftGroupbox("Movement", "person-standing")
CharBox:AddSlider("WalkSpeed", { Text = "Walk Speed", Default = 16, Min = 16, Max = 100, Rounding = 0 })
CharBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
CharBox:AddToggle("NoClip", { Text = "NoClip", Default = false, Tooltip = "Walk through walls" })
CharBox:AddToggle("AntiAfk", { Text = "Anti-AFK", Default = false, Tooltip = "Prevents AFK kick" })

local EspBox = CharSub:AddRightGroupbox("Visuals", "eye")
EspBox:AddToggle("EspNPCs", { Text = "ESP NPCs", Default = false, Tooltip = "Highlights all NPCs with colored boxes" })

-- ═══ PLAYER TAB: Teleports Sub-Tab ═══
local TPSub = PlayerTab:AddSubTab({ Name = "Teleports", Icon = "map-pin" })

local PlotTPBox = TPSub:AddLeftGroupbox("My Plot", "map-pin")
PlotTPBox:AddButton({ Text = "Teleport to Counter", Func = function() local p = getPlot() if p then local c = p:FindFirstChild("Counter") if c then local cp = c:FindFirstChild("Comp", true) if cp then tp(cp.CFrame * CFrame.new(0,3,0)) end end end end })
PlotTPBox:AddButton({ Text = "Teleport to Kitchen", Func = function() local p = getPlot() if p then local k = p:FindFirstChild("KitchenPlot1") if k then local f = k:GetChildren()[1] if f then tp(f:GetPivot() * CFrame.new(0,3,0)) end end end end })
PlotTPBox:AddButton({ Text = "Teleport to Serve Area", Func = function() local p = getPlot() if p then local s = p:FindFirstChild("Serve") if s then local f = s:GetChildren()[1] if f then tp(f:GetPivot() * CFrame.new(0,3,0)) end end end end })
PlotTPBox:AddButton({ Text = "Teleport to NPC Spawn", Func = function() local p = getPlot() if p then local ns = p:FindFirstChild("NpcSpawn") if ns then tp(ns:GetPivot() * CFrame.new(0,3,0)) end end end })

local WorldTPBox = TPSub:AddRightGroupbox("World", "globe")
WorldTPBox:AddButton({ Text = "Teleport to Grocery", Func = function() local g = Workspace:FindFirstChild("Grocery") if g then local c = g:FindFirstChild("Comp", true) if c then tp(c.CFrame * CFrame.new(0,3,0)) end end end })
WorldTPBox:AddButton({ Text = "Teleport to Shop", Func = function() local s = Workspace:FindFirstChild("SHOP") if s then local sh = s:FindFirstChild("Shop") if sh then local pp = sh:FindFirstChild("ProximityPrompt") if pp and pp.Parent:IsA("BasePart") then tp(pp.Parent.CFrame * CFrame.new(0,3,0)) end end end end })

-- ═══ SETTINGS TAB ═══
local ThemesSub = SettingsTab:AddSubTab({ Name = "Themes & UI", Icon = "palette" })
local ConfigSub = SettingsTab:AddSubTab({ Name = "Config", Icon = "save" })

-- LOGS TAB
local StatusBox = LogsTab:AddLeftGroupbox("Status", "activity")
local StatusLabels = {}
local statusOrder = {"serve", "order", "drink", "codes", "pan", "clean", "wash", "buyFurn", "placeFurn", "buyIng", "boosts", "unlockTbl", "unlockMenu", "chiller", "merchant", "mysteryBox"}
local statusNames = {serve="Serve", order="Order", drink="Drinks", codes="Codes", pan="Pan", clean="Clean", wash="Wash", buyFurn="Buy Furn", placeFurn="Place Furn", buyIng="Buy Ing", boosts="Boosts", unlockTbl="Unlock Tbl", unlockMenu="Unlock Menu", chiller="Chiller", merchant="Merchant", mysteryBox="Mystery Box"}
for _, key in ipairs(statusOrder) do
    StatusLabels[key] = StatusBox:AddLabel(statusNames[key] .. ": Idle", true)
end

local MoneyBox = LogsTab:AddRightGroupbox("Money Log", "dollar-sign")
local MoneyEarnedLabel = MoneyBox:AddLabel("Earned: $0", true)
local MoneySpentLabel = MoneyBox:AddLabel("Spent: $0", true)
local MoneyNetLabel = MoneyBox:AddLabel("Net: $0", true)
local MoneyStartLabel = MoneyBox:AddLabel("Start: $" .. moneyLog.startCash, true)

local MONEY_DISPLAY = 15
local moneyScrollOffset = 0
local MoneyLogLines = {}
for i = 1, MONEY_DISPLAY do
    MoneyLogLines[i] = MoneyBox:AddLabel("", true)
end

local function refreshMoneyDisplay()
    for i = 1, MONEY_DISPLAY do
        local entry = moneyLog.entries[i + moneyScrollOffset]
        if entry then
            local sign = entry.amount >= 0 and "+" or ""
            MoneyLogLines[i]:SetText(entry.time .. " | " .. entry.action .. " | " .. sign .. "$" .. entry.amount .. " | Bal: $" .. entry.cash)
        else
            MoneyLogLines[i]:SetText(i == 1 and "No entries yet" or "")
        end
    end
end

MoneyBox:AddButton({ Text = "Clear Logs", Func = function()
    moneyLog.entries = {}
    moneyLog.totalEarned = 0
    moneyLog.totalSpent = 0
    moneyLog.startCash = getCash()
    moneyScrollOffset = 0
    for i = 1, MONEY_DISPLAY do MoneyLogLines[i]:SetText("") end
    MoneyEarnedLabel:SetText("Earned: $0")
    MoneySpentLabel:SetText("Spent: $0")
    MoneyNetLabel:SetText("Net: $0")
    MoneyStartLabel:SetText("Start: $" .. getCash())
end })

MoneyBox:AddButton({ Text = "Scroll Up", Func = function()
    moneyScrollOffset = math.max(0, moneyScrollOffset - MONEY_DISPLAY)
    refreshMoneyDisplay()
end })

MoneyBox:AddButton({ Text = "Scroll Down", Func = function()
    local maxOffset = math.max(0, #moneyLog.entries - MONEY_DISPLAY)
    moneyScrollOffset = math.min(maxOffset, moneyScrollOffset + MONEY_DISPLAY)
    refreshMoneyDisplay()
end })

local RefreshBox = LogsTab:AddLeftGroupbox("Auto Refresh", "refresh-cw")
RefreshBox:AddToggle("AutoRefreshLogs", { Text = "Auto Refresh", Default = true })
RefreshBox:AddSlider("RefreshInterval", { Text = "Refresh Interval", Default = 2, Min = 1, Max = 10, Rounding = 0, Suffix = "s" })

-- CALLBACKS
Toggles.AutoServe:OnChanged(function(s) cfg.autoServe = s end)
Toggles.AutoOrder:OnChanged(function(s) cfg.autoOrder = s end)
Toggles.AutoRejectNPC:OnChanged(function(s) cfg.autoRejectNPC = s end)
Options.RejectNPCList:OnChanged(function(v)
    if v["None"] then
        -- "None" selected, clear everything
        Options.RejectNPCList:SetValue({})
        cfg.rejectNPCList = {}
        return
    end
    cfg.rejectNPCList = {}
    for displayName, selected in pairs(v) do
        if selected and displayName ~= "None" then
            local npcName = npcRarityMap[displayName]
            if npcName then
                cfg.rejectNPCList[npcName] = true
            end
        end
    end
end)
Toggles.AutoClaimCodes:OnChanged(function(s) cfg.autoClaimCodes = s end)
Toggles.AutoPan:OnChanged(function(s) cfg.autoPan = s end)
Toggles.AutoClean:OnChanged(function(s) cfg.autoClean = s end)
Toggles.AutoWash:OnChanged(function(s) cfg.autoWash = s end)
Toggles.AutoFixChiller:OnChanged(function(s) cfg.autoFixChiller = s end)
Toggles.AutoBuyFurniture:OnChanged(function(s) cfg.autoBuyFurniture = s end)
Toggles.AutoPlaceFurniture:OnChanged(function(s) cfg.autoPlaceFurniture = s end)
Options.FurnitureWhitelist:OnChanged(function(v)
    if v["None"] then
        -- "None" selected, clear everything
        Options.FurnitureWhitelist:SetValue({})
        cfg.furnitureWhitelist = {}
        return
    end
    cfg.furnitureWhitelist = {}
    for name, enabled in pairs(v) do
        if enabled and name ~= "None" then cfg.furnitureWhitelist[name] = true end
    end
end)
Toggles.AutoBuyIngredients:OnChanged(function(s) cfg.autoBuyIngredients = s end)
Toggles.AutoBuyMerchant:OnChanged(function(s) cfg.autoBuyMerchant = s end)
Options.MerchantWhitelist:OnChanged(function(v)
    cfg.merchantWhitelist = {}
    for name, enabled in pairs(v) do
        if enabled then cfg.merchantWhitelist[name] = true end
    end
end)
Toggles.AutoSoftdrinks:OnChanged(function(s) cfg.autoSoftdrinks = s end)
Toggles.AutoUseBoosts:OnChanged(function(s) cfg.autoUseBoosts = s end)
Toggles.AutoBuyMysteryBox:OnChanged(function(s) cfg.autoBuyMysteryBox = s end)
Toggles.AutoOpenMysteryBox:OnChanged(function(s) cfg.autoOpenMysteryBox = s end)
Toggles.AutoUnlockTables:OnChanged(function(s) cfg.autoUnlockTables = s end)
Toggles.AutoUnlockMenu:OnChanged(function(s) cfg.autoUnlockMenu = s end)
Toggles.NoClip:OnChanged(function(s) cfg.noclip = s end)
Toggles.AntiAfk:OnChanged(function(s) cfg.antiAfk = s end)
Toggles.EspNPCs:OnChanged(function(s) cfg.espNPCs = s end)
Options.WalkSpeed:OnChanged(function(v) cfg.walkSpeed = v local _,h = getChar() if h then h.WalkSpeed = v end end)
Toggles.InfJump:OnChanged(function(s) cfg.infJump = s end)
Toggles.AutoRefreshLogs:OnChanged(function(s) cfg.autoRefreshLogs = s end)

-- ═══ AUTO SERVE ═══
task.spawn(function() while true do
    if cfg.autoServe then
        local cashBefore = getCash()
        setStatus("serve", "Scanning...")
        local served = 0
        local plot = getPlot()
        if plot then
            local dp = plot:FindFirstChild("DiningPlot1")
            if dp then
                for _, slot in ipairs(dp:GetChildren()) do
                    if served >= 3 then break end
                    if slot:IsA("Model") then
                        for _, desc in ipairs(slot:GetDescendants()) do
                            if served >= 3 then break end
                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                local action = desc.ActionText
                                if string.sub(action, 1, 5) == "Serve" then
                                    local pp = desc.Parent
                                    if pp and pp:IsA("BasePart") then
                                        local release = acquireTp()
                                        tp(pp.CFrame * CFrame.new(0, 3, 0))
                                        task.wait(0.15)
                                        fireproximityprompt(desc)
                                        release()
                                        served = served + 1
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local serve = plot:FindFirstChild("Serve")
            if serve then
                for _, desc in ipairs(serve:GetDescendants()) do
                    if served >= 3 then break end
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local pp = desc.Parent
                        if pp and pp:IsA("BasePart") then
                            local release = acquireTp()
                            tp(pp.CFrame * CFrame.new(0, 3, 0))
                            task.wait(0.15)
                            fireproximityprompt(desc)
                            release()
                            served = served + 1
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
        local cashAfter = getCash()
        local diff = cashAfter - cashBefore
        if served > 0 then
            setStatus("serve", "Served " .. served .. " food")
        else
            setStatus("serve", "No food to serve")
        end
        if diff ~= 0 then
            logMoney("Serve Food", diff)
        end

        if cfg.autoSoftdrinks then
            for _ = 1, 5 do
                if not stepFulfillSoftdrinkOrders() then break end
                task.wait(0.1)
            end
            setStatus("drink", drinkStats.state)
        end
    else
        setStatus("serve", "Disabled")
    end
    task.wait(0.3)
end end)

-- ═══ AUTO ORDER ═══
task.spawn(function() while true do
    if cfg.autoOrder then
        local totalAssigned = 0
        for attempt = 1, 15 do
            setStatus("order", "Assigning... (" .. totalAssigned .. ")")
            local plot = getPlot()
            if plot then
                local counter = plot:FindFirstChild("Counter")
                if counter then
                    local comp = counter:FindFirstChild("Comp", true)
                    if comp then
                        for _, desc in ipairs(comp:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                local action = desc.ActionText
                                if string.find(action, "Take Order") or string.find(action, "Take") then
                                    local pp = desc.Parent
                                    if pp and pp:IsA("BasePart") then
                                        local release = acquireTp()
                                        tp(pp.CFrame * CFrame.new(0, 3, 0))
                                        task.wait(0.1)
                                        fireproximityprompt(desc)
                                        release()
                                        task.wait(0.15)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local ok, npc, tbls = pcall(function() return GetCounterInfo:InvokeServer() end)
            if ok and npc and tbls then
                local id = npc.NpcId or npc.TemplateName or ""
                local templateName = npc.TemplateName or ""
                if cfg.autoRejectNPC and cfg.rejectNPCList[templateName] then
                    pcall(function() RejectNPC:FireServer(id) end)
                    setStatus("order", "Rejected " .. templateName)
                    task.wait(0.5)
                    break
                end
                trackNPC(id)
                local s = false
                for _, t in ipairs(tbls) do
                    if t.Slot and t.Seat then
                        s = pcall(function() AssignNPC:FireServer({Slot=t.Slot, Seat=t.Seat, NPCName=id, NpcId=id}) end)
                        if s then totalAssigned = totalAssigned + 1 break end
                    end
                end
                if not s then break end
            else
                break
            end
            task.wait(0.05)
        end
        setStatus("order", totalAssigned > 0 and "Assigned " .. totalAssigned or "No NPC")
    else
        setStatus("order", "Disabled")
    end
    task.wait(0.5)
end end)

-- ═══ AUTO CLAIM CODES ═══
task.spawn(function() local claimed = {} while true do
    if cfg.autoClaimCodes then
        setStatus("codes", "Claiming codes...")
        local count = 0
        for _, code in ipairs({"LERISNATO"}) do
            if not claimed[code] then
                pcall(function() RedeemCodeRemote:FireServer(code) end)
                claimed[code] = true
                count = count + 1
                task.wait(3)
            end
        end
        if count > 0 then
            setStatus("codes", "Claimed " .. count .. " code(s)")
        else
            setStatus("codes", "All codes claimed")
        end
    else
        setStatus("codes", "Disabled")
    end
    task.wait(10)
end end)

-- ═══ AUTO PAN ═══
task.spawn(function() while true do
    if cfg.autoPan then
        local char, hum = getChar()
        if char and hum then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local pan = nil
            if bp then for _, t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("pan") then pan = t break end end end
            if not pan and char then for _, t in ipairs(char:GetChildren()) do if t:IsA("Tool") and t.Name:lower():find("pan") then pan = t break end end end

            if not pan then
                setStatus("pan", "No pan equipped")
            else
                local chased = false
                for attempt = 1, 10 do
                    local cn = Workspace:FindFirstChild("ClientNPCs")
                    local runawayNPC = nil
                    if cn then
                        for _, npc in ipairs(cn:GetChildren()) do
                            if npc:IsA("Model") and npc:GetAttribute("IsRunaway") == true and isMyRunaway(npc) then
                                runawayNPC = npc
                                break
                            end
                        end
                    end

                    if not runawayNPC then
                        setStatus("pan", chased and "Done!" or "No my runaways")
                        break
                    end

                    local nh = runawayNPC:FindFirstChild("HumanoidRootPart") or runawayNPC.PrimaryPart
                    if not nh then break end
                    local npcCF = nh.CFrame

                    chased = true
                    setStatus("pan", "Chasing... (" .. attempt .. ")")

                    if pan.Parent ~= char then
                        hum:EquipTool(pan)
                        task.wait(0.2)
                    end

                    local release = acquireTp()
                    tp(npcCF * CFrame.new(0, 0, -3))
                    task.wait(0.1)

                    if pan.Parent == char then
                        pcall(function() pan:Activate() end)
                    end

                    release()
                    task.wait(0.4)

                    if pan.Parent == char then
                        hum:UnequipTools()
                        task.wait(0.15)
                    end
                end
            end
        end
    else
        setStatus("pan", "Disabled")
    end
    task.wait(0.5)
end end)

-- ═══ AUTO CLEAN ═══
task.spawn(function() while true do
    if cfg.autoClean then
        setStatus("clean", "Scanning...")
        local cleaned = 0
        local plot = getPlot()
        if plot then
            local dp = plot:FindFirstChild("DiningPlot1")
            if dp then
                for _, tm in ipairs(dp:GetChildren()) do
                    if tm:IsA("Model") or tm:IsA("Folder") then
                        for _, desc in ipairs(tm:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                local action = desc.ActionText:lower()
                                if string.find(action, "clean") or string.find(action, "pick") or string.find(action, "dispose") or string.find(action, "collect") or string.find(action, "trash") then
                                    local pp = desc.Parent
                                    if pp and pp:IsA("BasePart") then
                                        local release = acquireTp()
                                        tp(pp.CFrame * CFrame.new(0, 3, 0))
                                        task.wait(0.15)
                                        fireproximityprompt(desc)
                                        release()
                                        cleaned = cleaned + 1
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local serve = plot:FindFirstChild("Serve")
            if serve then
                for _, desc in ipairs(serve:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local action = desc.ActionText:lower()
                        if string.find(action, "clean") or string.find(action, "pick") or string.find(action, "dispose") then
                            local pp = desc.Parent
                            if pp and pp:IsA("BasePart") then
                                local release = acquireTp()
                                tp(pp.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.15)
                                fireproximityprompt(desc)
                                release()
                                cleaned = cleaned + 1
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
            local others = plot:FindFirstChild("Others")
            if others then
                local trash = others:FindFirstChild("Trash")
                if trash then
                    for _, desc in ipairs(trash:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Enabled then
                            local pp = desc.Parent
                            if pp and pp:IsA("BasePart") then
                                local release = acquireTp()
                                tp(pp.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.15)
                                fireproximityprompt(desc)
                                release()
                                cleaned = cleaned + 1
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
        if cleaned > 0 then
            setStatus("clean", "Cleaned " .. cleaned .. " items")
        else
            setStatus("clean", "Nothing to clean")
        end
    else
        setStatus("clean", "Disabled")
    end
    task.wait(Options.CleanDelay and Options.CleanDelay.Value or 2)
end end)

-- ═══ AUTO WASH ═══
task.spawn(function() while true do
    if cfg.autoWash then
        setStatus("wash", "Scanning...")
        local plot = getPlot()
        if plot then
            local sink = plot:FindFirstChild("Sink")
            local washed = 0

            -- Step 1: Collect dirty dishes from key areas only (not entire plot)
            local collectAreas = {}
            local dp = plot:FindFirstChild("DiningPlot1")
            if dp then table.insert(collectAreas, dp) end
            local serve = plot:FindFirstChild("Serve")
            if serve then table.insert(collectAreas, serve) end

            for _, area in ipairs(collectAreas) do
                for _, desc in ipairs(area:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local action = desc.ActionText:lower()
                        local obj = desc.ObjectText:lower()
                        if string.find(obj, "dirty") or string.find(obj, "dish") or string.find(action, "wash") or string.find(action, "pick") then
                            local pp = desc.Parent
                            if pp and pp:IsA("BasePart") then
                                -- Pick up the dish (quick tp + fire + release)
                                local release = acquireTp()
                                tp(pp.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.15)
                                pcall(function() if desc.Enabled then fireproximityprompt(desc) end end)
                                release()
                                task.wait(0.3)

                                -- Wait for tool (no lock held)
                                local gotTool = false
                                for _ = 1, 20 do
                                    local c = LocalPlayer.Character
                                    if c and c:FindFirstChildOfClass("Tool") then gotTool = true; break end
                                    task.wait(0.1)
                                end

                                if gotTool and sink then
                                    task.wait(0.15)
                                    -- Find Put prompt in sink
                                    for _, pd in ipairs(sink:GetDescendants()) do
                                        if pd:IsA("ProximityPrompt") and pd.Enabled then
                                            local a = pd.ActionText:lower()
                                            if string.find(a, "put") or string.find(a, "place") or pd.Name == "Put" then
                                                local r2 = acquireTp()
                                                tp(pd.Parent.CFrame * CFrame.new(0, 3, 0))
                                                task.wait(0.2)
                                                pcall(function() fireproximityprompt(pd) end)
                                                r2()
                                                task.wait(0.5)
                                                break
                                            end
                                        end
                                    end
                                end
                                -- Drop any held tool if still holding
                                pcall(function()
                                    local c = LocalPlayer.Character
                                    if c then
                                        local t = c:FindFirstChildOfClass("Tool")
                                        if t then t.Parent = LocalPlayer.Backpack end
                                    end
                                end)
                            end
                        end
                    end
                end
            end

            -- Step 2: Wash all dishes in sink
            if sink then
                for attempt = 1, 10 do
                    local washPrompt = nil
                    for _, pd in ipairs(sink:GetDescendants()) do
                        if pd:IsA("ProximityPrompt") and pd.Enabled then
                            local a = pd.ActionText:lower()
                            local o = pd.ObjectText:lower()
                            if string.find(a, "wash") or string.find(a, "clean") or string.find(a, "scrub")
                                or string.find(o, "dish") or string.find(o, "dirty") or string.find(o, "plate") then
                                washPrompt = pd
                                break
                            end
                        end
                    end
                    if not washPrompt then break end

                    local release3 = acquireTp()
                    tp(washPrompt.Parent.CFrame * CFrame.new(0, 3, 0))
                    task.wait(0.15)
                    -- Quick fire + hold attempt, release lock immediately after
                    pcall(function()
                        local holdTime = washPrompt.HoldDuration or 1
                        local VIM = game:GetService("VirtualInputManager")
                        VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.delay(holdTime + 0.3, function()
                            pcall(function() VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
                        end)
                    end)
                    pcall(fireproximityprompt, washPrompt)
                    release3() -- release lock right away, don't wait for hold
                    washed = washed + 1
                    task.wait(1.5)
                end
            end

            if washed > 0 then
                setStatus("wash", "Washed " .. washed .. " dishes")
            else
                setStatus("wash", "Nothing to wash")
            end
        end
    else
        setStatus("wash", "Disabled")
    end
    task.wait(Options.WashDelay and Options.WashDelay.Value or 2)
end end)

-- ═══ AUTO FIX CHILLER ═══
task.spawn(function() while true do
    if cfg.autoFixChiller then
        local plot = getPlot()
        if plot then
            local softdrinks = plot:FindFirstChild("Softdrinks")
            if softdrinks then
                local chiller = softdrinks:FindFirstChild("Chiller")
                if chiller then
                    local promptPart = chiller:FindFirstChild("PromptPart")
                    if promptPart then
                        for _, pp in ipairs(promptPart:GetChildren()) do
                            if pp:IsA("ProximityPrompt") and pp.Name == "Repair" and pp.Enabled then
                                local release = acquireTp()
                                tp(pp.Parent.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.2)
                                pcall(function() fireproximityprompt(pp) end)
                                release()
                                setStatus("chiller", "Repairing...")
                                task.wait(1)
                                setStatus("chiller", "Done!")
                                break
                            end
                        end
                        if not promptPart:FindFirstChild("Repair") or not promptPart.Repair.Enabled then
                            setStatus("chiller", "Chiller OK")
                        end
                    else
                        setStatus("chiller", "No prompt part")
                    end
                else
                    setStatus("chiller", "No chiller")
                end
            else
                setStatus("chiller", "No softdrinks")
            end
        end
    else
        setStatus("chiller", "Disabled")
    end
    task.wait(3)
end end)

-- ═══ AUTO BUY MERCHANT ═══
task.spawn(function() while true do
    if cfg.autoBuyMerchant then
        local hasItems = false
        for _ in pairs(cfg.merchantWhitelist) do hasItems = true; break end
        if not hasItems then
            setStatus("merchant", "No items selected")
        else
            setStatus("merchant", "Checking stock...")
            local ok, stock = pcall(function() return GetMerchantStock:InvokeServer() end)
            if ok and stock and type(stock) == "table" then
                local bought = 0
                for _, item in ipairs(stock) do
                    if item.Stock > 0 and not item.Owned and cfg.merchantWhitelist[item.Key] then
                        local cash = getCash()
                        if cash >= item.Price then
                            setStatus("merchant", "Buying " .. item.Name .. "...")
                            local buyOk, buyErr = pcall(function() return BuyMerchantItem:InvokeServer(item.Key) end)
                            if buyOk then
                                bought = bought + 1
                                logMoney("Merchant: " .. item.Name, -item.Price)
                                task.wait(0.5)
                            else
                                setStatus("merchant", "Failed: " .. item.Name)
                                task.wait(1)
                            end
                        else
                            setStatus("merchant", "Need $" .. item.Price .. " for " .. item.Name)
                        end
                    end
                end
                if bought > 0 then
                    setStatus("merchant", "Bought " .. bought .. " items")
                else
                    setStatus("merchant", "Nothing to buy")
                end
            else
                setStatus("merchant", "Failed to fetch stock")
            end
        end
    else
        setStatus("merchant", "Disabled")
    end
    task.wait(5)
end end)

-- ═══ AUTO BUY MYSTERY BOX ═══
task.spawn(function() while true do
    if cfg.autoBuyMysteryBox then
        local mbCfg = MysteryBoxConfig and MysteryBoxConfig.Common
        local cost = mbCfg and mbCfg.Cost or 10000
        local cash = getCash()
        if cash >= cost then
            setStatus("mysteryBox", "Buying...")
            local clientLoader = LocalPlayer:WaitForChild("PlayerScripts"):FindFirstChild("ClientLoader")
            local ok, result = pcall(function() return BuyMysteryBox:InvokeServer(clientLoader) end)
            if ok and result then
                setStatus("mysteryBox", "Bought! (-$" .. cost .. ")")
                logMoney("Mystery Box", -cost)
                task.wait(3)
            else
                setStatus("mysteryBox", "On cooldown, retrying...")
                task.wait(10)
            end
        else
            setStatus("mysteryBox", "Need $" .. cost .. " (have $" .. cash .. ")")
        end
    else
        setStatus("mysteryBox", "Disabled")
    end
    task.wait(5)
end end)

-- ═══ AUTO OPEN MYSTERY BOX ═══
task.spawn(function() while true do
    if cfg.autoOpenMysteryBox then
        local gui = LocalPlayer:FindFirstChild("PlayerGui")
        if gui then
            local myInfo = gui:FindFirstChild("GUI", true) and gui.GUI:FindFirstChild("Frames", true) and gui.GUI.Frames:FindFirstChild("MyInfo", true)
            if myInfo then
                local scroll = myInfo:FindFirstChild("Scrolling")
                if scroll then
                    local openFrame = scroll:FindFirstChild("Open/Close")
                    if openFrame then
                        local btn = openFrame:FindFirstChild("open/close")
                        if btn and btn.Visible and btn.Active then
                            setStatus("mysteryBox", "Opening...")
                            pcall(function() btn:Activate() end)
                            task.wait(1)
                            setStatus("mysteryBox", "Opened!")
                        end
                    end
                end
            end
        end
    end
    task.wait(3)
end end)

-- ═══ AUTO BUY FURNITURE ═══
task.spawn(function() while true do
    if cfg.autoBuyFurniture then
        setStatus("buyFurn", "Checking shop...")
        local cash = getCash()
        local ok, shopData = pcall(function() return GetShopInfo:InvokeServer() end)
        if ok and shopData then
            local furnCfg = FurnitureConfig
            local allItems = {}
            local hasWhitelist = next(cfg.furnitureWhitelist) ~= nil
            for _, category in ipairs({"Tables", "Chairs", "Stoves"}) do
                local items = shopData[category]
                if items then
                    for _, item in ipairs(items) do
                        if item.Stock and item.Stock > 0 then
                            local displayName = category .. ": " .. item.Key
                            if not hasWhitelist or cfg.furnitureWhitelist[displayName] then
                                local price = 0
                                local sysType = item.SystemType or "Dining"
                                if sysType == "Kitchen" then
                                    local stoves = furnCfg.Kitchen and furnCfg.Kitchen.Stoves
                                    if stoves and stoves[item.Key] and type(stoves[item.Key]) == "table" then
                                        price = stoves[item.Key].Price or 0
                                    end
                                else
                                    local catData = furnCfg.Dining and furnCfg.Dining[category]
                                    if catData and catData[item.Key] and type(catData[item.Key]) == "table" then
                                        price = catData[item.Key].Price or 0
                                    end
                                end
                                table.insert(allItems, {item = item, price = price})
                            end
                        end
                    end
                end
            end
            table.sort(allItems, function(a, b) return a.price > b.price end)

            local bought = 0
            for _, entry in ipairs(allItems) do
                if entry.price <= cash and entry.price > 0 then
                    local cashBefore = getCash()
                    pcall(function()
                        BuyFurniture:InvokeServer(entry.item.SystemType, entry.item.Category, entry.item.Key)
                    end)
                    local cashAfter = getCash()
                    local diff = cashAfter - cashBefore
                    if diff ~= 0 then
                        logMoney("Buy " .. entry.item.Key, diff)
                    end
                    cash = cashAfter
                    bought = bought + 1
                    task.wait(0.5)
                end
            end
            if bought > 0 then
                setStatus("buyFurn", "Bought " .. bought .. " items")
            else
                setStatus("buyFurn", "Nothing affordable")
            end
        else
            setStatus("buyFurn", "Shop query failed")
        end
    else
        setStatus("buyFurn", "Disabled")
    end
    task.wait(Options.FurnDelay and Options.FurnDelay.Value or 5)
end end)

-- ═══ AUTO PLACE / UPGRADE FURNITURE ═══
task.spawn(function()
    local priceLookup = {}
    local furnCfg = FurnitureConfig
    if furnCfg.Dining then
        if furnCfg.Dining.Tables then
            for k, v in pairs(furnCfg.Dining.Tables) do
                if type(v) == "table" and v.Price then priceLookup["Tables_" .. k] = v.Price end
            end
        end
        if furnCfg.Dining.Chairs then
            for k, v in pairs(furnCfg.Dining.Chairs) do
                if type(v) == "table" and v.Price then priceLookup["Chairs_" .. k] = v.Price end
            end
        end
    end
    if furnCfg.Kitchen and furnCfg.Kitchen.Stoves then
        for k, v in pairs(furnCfg.Kitchen.Stoves) do
            if type(v) == "table" and v.Price then priceLookup["Stoves_" .. k] = v.Price end
        end
    end

    local modelNameToKey = {}
    if furnCfg.Dining then
        if furnCfg.Dining.Tables then
            for k, v in pairs(furnCfg.Dining.Tables) do
                if type(v) == "table" and v.Name then modelNameToKey[v.Name] = k end
            end
        end
        if furnCfg.Dining.Chairs then
            for k, v in pairs(furnCfg.Dining.Chairs) do
                if type(v) == "table" and v.Name then modelNameToKey[v.Name] = k end
            end
        end
    end
    if furnCfg.Kitchen and furnCfg.Kitchen.Stoves then
        for k, v in pairs(furnCfg.Kitchen.Stoves) do
            if type(v) == "table" and v.Name then modelNameToKey[v.Name] = k end
        end
    end

    while true do
        if cfg.autoPlaceFurniture then
            setStatus("placeFurn", "Checking inventory...")
            local plot = getPlot()
            if plot then
                local ok, inv = pcall(function() return GetFurnitureInventory:InvokeServer() end)
                if ok and inv then
                    local inventory = {Tables = {}, Chairs = {}, Stoves = {}}
                    for fullKey, count in pairs(inv) do
                        if type(count) == "number" and count > 0 then
                            local cat, key = parseInvKey(fullKey)
                            if cat and inventory[cat] then
                                table.insert(inventory[cat], {key = key, count = count, price = priceLookup[fullKey] or 0})
                            end
                        end
                    end
                    for _, list in pairs(inventory) do
                        table.sort(list, function(a, b) return a.price > b.price end)
                    end

                    local dp = plot:FindFirstChild("DiningPlot1")
                    if dp then
                        for _, slot in ipairs(dp:GetChildren()) do
                            if slot:IsA("Model") then
                                local ct = slot:FindFirstChild("CurrentTable")
                                if ct then
                                    local currentChildren = ct:GetChildren()
                                    local currentPrice = 0
                                    if #currentChildren > 0 then
                                        local currentModel = currentChildren[1]
                                        local currentKey = modelNameToKey[currentModel.Name] or currentModel.Name
                                        currentPrice = priceLookup["Tables_" .. currentKey] or 0
                                    end
                                    if #inventory.Tables > 0 then
                                        local best = inventory.Tables[1]
                                        if best.price > currentPrice then
                                            pcall(function() PlaceFurnitureEvent:FireServer(slot, "Tables", best.key) end)
                                            task.wait(1)
                                        end
                                    end
                                end
                                local cc = slot:FindFirstChild("CurrentChair")
                                if cc then
                                    local currentChildren = cc:GetChildren()
                                    local currentPrice = 0
                                    if #currentChildren > 0 then
                                        local currentModel = currentChildren[1]
                                        local currentKey = modelNameToKey[currentModel.Name] or currentModel.Name
                                        currentPrice = priceLookup["Chairs_" .. currentKey] or 0
                                    end
                                    if #inventory.Chairs > 0 then
                                        local best = inventory.Chairs[1]
                                        if best.price > currentPrice then
                                            pcall(function() PlaceFurnitureEvent:FireServer(slot, "Chairs", best.key) end)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    local kp = plot:FindFirstChild("KitchenPlot1")
                    if kp then
                        for _, slot in ipairs(kp:GetChildren()) do
                            if slot:IsA("Model") or slot:IsA("Folder") then
                                local cb = slot:FindFirstChild("CurrentBuilding")
                                if cb then
                                    local currentChildren = cb:GetChildren()
                                    local currentPrice = 0
                                    if #currentChildren > 0 then
                                        local currentModel = currentChildren[1]
                                        local currentKey = modelNameToKey[currentModel.Name] or currentModel.Name
                                        currentPrice = priceLookup["Stoves_" .. currentKey] or 0
                                    end
                                    if #inventory.Stoves > 0 then
                                        local best = inventory.Stoves[1]
                                        if best.price > currentPrice then
                                            pcall(function() PlaceFurnitureEvent:FireServer(slot, "Stoves", best.key, "Kitchen") end)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            setStatus("placeFurn", "Placement done")
        else
            setStatus("placeFurn", "Disabled")
        end
        task.wait(Options.FurnDelay and Options.FurnDelay.Value or 5)
    end
end)

-- ═══ AUTO BUY INGREDIENTS ═══
task.spawn(function() while true do
    if cfg.autoBuyIngredients then
        setStatus("buyIng", "Checking stock...")
        local cash = getCash()
        local threshold = Options.IngBuyThreshold and Options.IngBuyThreshold.Value or 5
        local bought = 0
        local ing = LocalPlayer:FindFirstChild("Ingredients")
        if ing then
            for name, data in pairs(IngredientsConfig) do
                local val = ing:FindFirstChild(name)
                if val and val.Value < threshold then
                    local price = data.Cost or 0
                    local buyCount = math.max(1, threshold - val.Value)
                    for i = 1, buyCount do
                        if cash >= price then
                            local cashBefore = getCash()
                            pcall(function() BuyIngredient:InvokeServer(name, 1, "Cash") end)
                            local cashAfter = getCash()
                            local diff = cashAfter - cashBefore
                            if diff ~= 0 then
                                logMoney("Buy " .. name, diff)
                            end
                            cash = cashAfter
                            bought = bought + 1
                            task.wait(0.3)
                        else
                            break
                        end
                    end
                end
            end
        end
        if bought > 0 then
            setStatus("buyIng", "Bought " .. bought .. " ingredients")
        else
            setStatus("buyIng", "Stock OK")
        end
    else
        setStatus("buyIng", "Disabled")
    end
    task.wait(5)
end end)

-- ═══ AUTO USE BOOSTS ═══
task.spawn(function() while true do
    if cfg.autoUseBoosts then
        local used = 0
        local cashPotions = LocalPlayer:GetAttribute("CashPotionCount") or 0
        if cashPotions > 0 then
            setStatus("boosts", "Using Cash Potion...")
            pcall(function() UseBoostEvent:FireServer("CashPotion") end)
            used = used + 1
            task.wait(1)
        end
        local luckPotions = LocalPlayer:GetAttribute("LuckPotionCount") or 0
        if luckPotions > 0 then
            setStatus("boosts", "Using Luck Potion...")
            pcall(function() UseBoostEvent:FireServer("LuckPotion") end)
            used = used + 1
            task.wait(1)
        end
        local ultraPotions = LocalPlayer:GetAttribute("UltraLuckPotionCount") or 0
        if ultraPotions > 0 then
            setStatus("boosts", "Using Ultra Luck Potion...")
            pcall(function() UseBoostEvent:FireServer("UltraLuckPotion") end)
            used = used + 1
            task.wait(1)
        end
        if used > 0 then
            setStatus("boosts", "Used " .. used .. " potion(s)")
        else
            setStatus("boosts", "No potions")
        end
    else
        setStatus("boosts", "Disabled")
    end
    task.wait(30)
end end)

-- ═══ AUTO UNLOCK TABLES ═══
task.spawn(function() while true do
    if cfg.autoUnlockTables then
        setStatus("unlockTbl", "Checking tables...")
        local cash = getCash()
        local ok, unlocked = pcall(function() return GetUnlockedTables:InvokeServer() end)
        if ok and unlocked then
            local count = 0
            for _, v in pairs(unlocked) do if v == true then count = count + 1 end end
            local cost = (count + 1) * 20000
            if cash >= cost then
                for i = 7, 12 do
                    local tableName = "Table" .. i
                    if not unlocked[tableName] then
                        local cashBefore = getCash()
                        pcall(function() BuyTableEvent:InvokeServer(tableName) end)
                        local cashAfter = getCash()
                        local diff = cashAfter - cashBefore
                        if diff ~= 0 then
                            logMoney("Unlock " .. tableName, diff)
                            setStatus("unlockTbl", "Unlocked " .. tableName)
                        end
                        task.wait(0.5)
                        break
                    end
                end
            else
                setStatus("unlockTbl", "Need $" .. cost .. " (have $" .. cash .. ")")
            end
        else
            setStatus("unlockTbl", "Query failed")
        end
    else
        setStatus("unlockTbl", "Disabled")
    end
    task.wait(10)
end end)

-- ═══ AUTO UNLOCK MENU ═══
task.spawn(function() while true do
    if cfg.autoUnlockMenu then
        setStatus("unlockMenu", "Checking menu...")
        local ok, menuData = pcall(function() return GetMenuData:InvokeServer() end)
        if ok and menuData then
            local served = menuData.TotalServed or 0
            if served >= 100 and not menuData.UnlockedMenus.SILOG then
                setStatus("unlockMenu", "Unlocking SILOG...")
                pcall(function() UnlockMenu:InvokeServer("SILOG") end)
                setStatus("unlockMenu", "SILOG unlocked!")
                task.wait(1)
            elseif served >= 670 and not (menuData.UnlockedMenus["LUTONG BAHAY"]) then
                setStatus("unlockMenu", "Unlocking LUTONG BAHAY...")
                pcall(function() UnlockMenu:InvokeServer("LUTONG BAHAY") end)
                setStatus("unlockMenu", "LUTONG BAHAY unlocked!")
                task.wait(1)
            else
                setStatus("unlockMenu", served .. " served")
            end
        else
            setStatus("unlockMenu", "Query failed")
        end
    else
        setStatus("unlockMenu", "Disabled")
    end
    task.wait(15)
end end)

-- ═══ NOCLIP ═══
RunService.Stepped:Connect(function()
    if cfg.noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ═══ ANTI-AFK ═══
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if cfg.antiAfk then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- ═══ ESP NPCS ═══
task.spawn(function()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "KarinderyaESP"
    espFolder.Parent = CoreGui

    local function addESP(npc)
        if not npc:IsA("Model") then return end
        if npc:FindFirstChild("KarinderyaESP") then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "KarinderyaESP"
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.2
        if npc:GetAttribute("IsRunaway") then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
        elseif npc:GetAttribute("Order") then
            highlight.FillColor = Color3.fromRGB(0, 170, 255)
            highlight.OutlineColor = Color3.fromRGB(0, 120, 255)
        else
            highlight.FillColor = Color3.fromRGB(0, 255, 100)
            highlight.OutlineColor = Color3.fromRGB(0, 200, 80)
        end
        highlight.Adornee = npc
        highlight.Parent = npc
    end

    local function removeESP(npc)
        local esp = npc:FindFirstChild("KarinderyaESP")
        if esp then esp:Destroy() end
    end

    while true do
        local cn = Workspace:FindFirstChild("ClientNPCs")
        if cn then
            for _, npc in ipairs(cn:GetChildren()) do
                if cfg.espNPCs then
                    addESP(npc)
                else
                    removeESP(npc)
                end
            end
        end
        if not cfg.espNPCs and cn then
            for _, npc in ipairs(cn:GetChildren()) do
                removeESP(npc)
            end
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════
-- WALKSPEED & INFINITE JUMP
-- ═══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(c) local h = c:WaitForChild("Humanoid",10) if h then h.WalkSpeed = cfg.walkSpeed end end)
do local _,h = getChar() if h then h.WalkSpeed = cfg.walkSpeed end end
UserInputService.JumpRequest:Connect(function() if cfg.infJump then local _,h = getChar() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

-- ═══════════════════════════════════════
-- LOGS REFRESH LOOP
-- ═══════════════════════════════════════
task.spawn(function() while true do
    if Library.Toggled then
        for _, key in ipairs(statusOrder) do
            if StatusLabels[key] then
                StatusLabels[key]:SetText(statusNames[key] .. ": " .. (status[key] or "Idle"))
            end
        end
        MoneyEarnedLabel:SetText("Earned: $" .. moneyLog.totalEarned)
        MoneySpentLabel:SetText("Spent: $" .. moneyLog.totalSpent)
        MoneyNetLabel:SetText("Net: $" .. (moneyLog.totalEarned - moneyLog.totalSpent))
        MoneyStartLabel:SetText("Start: $" .. moneyLog.startCash .. " | Now: $" .. getCash())
        refreshMoneyDisplay()
    end
    local interval = Options.RefreshInterval and Options.RefreshInterval.Value or 2
    task.wait(interval)
end end)

-- ═══════════════════════════════════════
-- CASH MONITOR (passive detection)
-- ═══════════════════════════════════════
task.spawn(function()
    local lastCash = getCash()
    while true do
        task.wait(3)
        local currentCash = getCash()
        local diff = currentCash - lastCash
        if diff ~= 0 and not cfg.autoServe and not cfg.autoBuyFurniture and not cfg.autoBuyIngredients and not cfg.autoUnlockTables and not cfg.autoFixChiller and not cfg.autoBuyMerchant and not cfg.autoBuyMysteryBox then
            if diff > 0 then
                logMoney("Passive earn", diff)
            else
                logMoney("Passive spend", diff)
            end
        end
        lastCash = currentCash
    end
end)

-- THEME & SAVE
ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("KarinderyaScript") SaveManager:SetFolder("KarinderyaScript/saves")
local CreditGroup = ThemesSub:AddLeftGroupbox("Credits", "heart")
local CreditLabel = CreditGroup:AddLabel({ Text = "", Size = 26, DoesWrap = true })
local CreditTL = CreditLabel.TextLabel
CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
CreditTL.Font = Enum.Font.GothamBold
CreditTL.TextSize = 26

task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

ThemeManager:ApplyToTab(ThemesSub)
SaveManager:BuildConfigSection(ConfigSub) SaveManager:LoadAutoloadConfig()

if not Library.Toggled then Library:Toggle() end
print("[Karinderya] Loaded - RightControl to toggle")