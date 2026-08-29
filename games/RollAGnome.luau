--[[
    Ivory Hub - Roll A Gnome
    Game PlaceId: 117539213094671
    
    Features: Auto Farm, Rolling, Upgrades, Pets, Gear Shop, Expansion
]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

----------------------------------------------------------------------------
-- UI Library
----------------------------------------------------------------------------

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
    return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

----------------------------------------------------------------------------
-- Module access
----------------------------------------------------------------------------

local function requireIdent(inst)
    local previous
    pcall(function() previous = getthreadidentity and getthreadidentity() or nil end)
    pcall(function() setthreadidentity(2) end)
    local ok, result = pcall(require, inst)
    pcall(function() setthreadidentity(previous or 8) end)
    if not ok then error(tostring(result), 0) end
    return result
end

local LibraryModules = ReplicatedStorage:WaitForChild("Library", 20)
local Configs = LibraryModules:WaitForChild("Configs", 20)

local Net         = requireIdent(LibraryModules:WaitForChild("Imported", 20):WaitForChild("Network", 20))
local Replication = requireIdent(ReplicatedStorage:WaitForChild("Replication", 20))

local CfgFarmers  = requireIdent(Configs:WaitForChild("Farmers", 20))
local CfgPlants   = requireIdent(Configs:WaitForChild("Plants", 20))
local CfgTree     = requireIdent(Configs:WaitForChild("Upgrade Tree", 20))
local CfgRebirths = requireIdent(Configs:WaitForChild("Rebirths", 20))
local CfgExpand   = requireIdent(Configs:WaitForChild("Expand", 20))
local CfgShop     = requireIdent(Configs:WaitForChild("ItemShop", 20))
local CfgPets     = requireIdent(Configs:WaitForChild("Pets", 20))
local CfgSprink   = requireIdent(Configs:WaitForChild("Sprinklers", 20))
local CfgFert     = requireIdent(Configs:WaitForChild("Fertilizer", 20))

----------------------------------------------------------------------------
-- Config
----------------------------------------------------------------------------

local CONFIG = {
    auto          = false,
    autoCollect   = true,
    autoSell      = true,
    autoRoll      = true,
    autoBuy       = true,
    autoPlace     = true,
    autoPets      = true,
    autoUpgrade   = true,
    autoExpand    = true,
    autoFreeGnome = true,
    autoRebirth   = false,
    autoGear      = true,
    autoGearUse   = true,
    autoBuyPets   = true,
    collectGap    = 0.06,
    collectBatch  = 40,
    sellAt        = 0.85,
    placeClear    = 3.0,
    placeTries    = 6,
    buyMargin     = 1.0,
    expandKeep    = 3.0,
    reserveWindow = 90,
    gearMode      = "Sprinklers + fertilizer",
    gearKeep      = 3.0,
    petRarity     = "Common",
    petKeep       = 2.0,
}

local STATE = {
    money = 0, rebirths = 0, phase = "starting", note = "",
    collected = 0, sold = 0, earned = 0, lastSale = 0,
    rolls = 0, bought = 0, placed = 0, upgrades = 0, expansions = 0,
    gnomes = 0, invUsed = 0, invMax = 0, ready = 0, growing = 0,
    rollLuck = 1, bestGnome = "-", weakest = "-", target = "-",
    placeFails = 0, plotFull = false, gnomeCap = 0, swaps = 0,
    rate = 0, reserve = 0, observed = 0,
    pets = 0, petsPlaced = 0, petCap = 3,
    gearBought = 0, gearUsed = 0, gearLive = 0, lastGear = "-", restock = 0,
    petsBought = 0, petsOwned = 0, petSeen = 0, petBest = "-", petReserve = 0, petSwaps = 0,
}

_G.__IVORY = (_G.__IVORY or 0) + 1
local GEN = _G.__IVORY
local function alive() return _G.__IVORY == GEN end

local function note(fmt, ...)
    STATE.note = select("#", ...) > 0 and string.format(fmt, ...) or tostring(fmt)
end

----------------------------------------------------------------------------
-- Oracle helpers
----------------------------------------------------------------------------

local function data()
    local d = Replication and Replication.Data
    return type(d) == "table" and d or {}
end

local function money()
    local s = data().stats
    return (type(s) == "table" and tonumber(s.money)) or 0
end

local function rebirths()
    local s = data().stats
    return (type(s) == "table" and tonumber(s.rebirths)) or 0
end

local function inventory()
    local inv = data().inventory
    return type(inv) == "table" and inv or {}
end

local function inventoryCounts()
    local plants, farmers, total, pets, gear = 0, 0, 0, 0, 0
    for _, item in pairs(inventory()) do
        total = total + 1
        if type(item) == "table" then
            local kind = item.type
            if kind == "Farmer" then farmers = farmers + 1
            elseif kind == "Plant" then plants = plants + 1
            elseif kind == "Pet" then pets = pets + 1
            elseif kind then gear = gear + 1 end
        end
    end
    return plants, farmers, total, pets, gear
end

local function inventoryMax()
    return tonumber(data().max_inventory) or 100
end

local function placedFarmers()
    local f = data().farmers
    return type(f) == "table" and f or {}
end

local function placedCount()
    local n = 0
    for _ in pairs(placedFarmers()) do n = n + 1 end
    return n
end

----------------------------------------------------------------------------
-- Remotes
----------------------------------------------------------------------------

local function fire(name, ...)
    local args = table.pack(...)
    local ok, err = pcall(function() Net:FireServer(name, table.unpack(args, 1, args.n)) end)
    if not ok then note("%s: %s", name, tostring(err)) end
    return ok
end

local function invoke(name, timeout, ...)
    local args = table.pack(...)
    local done, result = false, nil
    task.spawn(function()
        local ok, res = pcall(function() return Net:InvokeServer(name, table.unpack(args, 1, args.n)) end)
        result = ok and res or nil
        if not ok then note("%s: %s", name, tostring(res)) end
        done = true
    end)
    local started = os.clock()
    while not done and os.clock() - started < (timeout or 8) do
        task.wait(0.05)
    end
    if not done then note("%s did not answer", name) end
    return result, done
end

----------------------------------------------------------------------------
-- Plot
----------------------------------------------------------------------------

local function plot()
    local holder = LocalPlayer:FindFirstChild("Plot")
    local value = holder and holder.Value
    if value and value.Parent then return value end
    return nil
end

local function folderOf(name)
    local p = plot()
    return p and p:FindFirstChild(name) or nil
end

local function occupiedPoints()
    local points = {}
    for _, name in ipairs({ "Plants", "ReadyToCollect", "Workers" }) do
        local folder = folderOf(name)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local ok, pivot = pcall(function() return child:GetPivot().Position end)
                    if ok then points[#points + 1] = pivot end
                end
            end
        end
    end
    return points
end

local function gardenBounds()
    local points = occupiedPoints()
    if #points == 0 then
        local p = plot()
        local pivot = p and p:FindFirstChild("GardenPivot")
        if pivot and pivot:IsA("BasePart") then
            local pos = pivot.Position
            return pos.X - 8, pos.X + 8, pos.Z - 8, pos.Z + 8, 2.0999982357025146
        end
        return nil
    end
    local minx, maxx, minz, maxz = math.huge, -math.huge, math.huge, -math.huge
    local y = 2.0999982357025146
    for _, point in ipairs(points) do
        if point.X < minx then minx = point.X end
        if point.X > maxx then maxx = point.X end
        if point.Z < minz then minz = point.Z end
        if point.Z > maxz then maxz = point.Z end
    end
    return minx, maxx, minz, maxz, y
end

local function placementSpots(count)
    local minx, maxx, minz, maxz, y = gardenBounds()
    if not minx then return {} end
    local points = occupiedPoints()
    local function clearance(x, z)
        local nearest = math.huge
        for _, point in ipairs(points) do
            local dx, dz = point.X - x, point.Z - z
            local d = math.sqrt(dx * dx + dz * dz)
            if d < nearest then nearest = d end
        end
        return nearest
    end
    local candidates = {}
    local step = 1
    for x = minx - 2, maxx + 2, step do
        for z = minz - 2, maxz + 2, step do
            local c = clearance(x, z)
            if c >= CONFIG.placeClear then
                candidates[#candidates + 1] = { x = x, z = z, c = c }
            end
        end
    end
    table.sort(candidates, function(a, b) return a.c < b.c end)
    local out = {}
    for i = 1, math.min(count or CONFIG.placeTries, #candidates) do
        local pick = candidates[i]
        out[#out + 1] = Vector3.new(pick.x, y, pick.z)
    end
    return out
end

----------------------------------------------------------------------------
-- Gnome valuation
----------------------------------------------------------------------------

local function plantPrice(plantName)
    local cfg = CfgPlants[plantName]
    if type(cfg) ~= "table" then return 0 end
    return tonumber(cfg.sell_price) or 0
end

local function gnomeRate(farmerName)
    local cfg = CfgFarmers[farmerName]
    if type(cfg) ~= "table" then return 0 end
    local duration = cfg.plant_duration
    local seconds
    if type(duration) == "table" then
        local lo, hi = tonumber(duration[1]), tonumber(duration[2])
        if lo and hi then seconds = (lo + hi) / 2 else seconds = lo or hi end
    else
        seconds = tonumber(duration)
    end
    if not seconds or seconds <= 0 then return 0 end
    return plantPrice(cfg.plant) / seconds
end

local function gnomePrice(farmerName)
    local cfg = CfgFarmers[farmerName]
    return (type(cfg) == "table" and tonumber(cfg.price)) or math.huge
end

local function weakestPlaced()
    local worstName, worstRate, worstUid = nil, math.huge, nil
    for uid, entry in pairs(placedFarmers()) do
        if type(entry) == "table" and entry.name then
            local rate = gnomeRate(entry.name)
            if rate < worstRate then
                worstRate, worstName, worstUid = rate, entry.name, uid
            end
        end
    end
    if not worstName then return nil, 0, nil end
    return worstName, worstRate, worstUid
end

local function gardenFull()
    return STATE.gnomeCap > 0 and placedCount() >= STATE.gnomeCap
end

----------------------------------------------------------------------------
-- Actions
----------------------------------------------------------------------------

local function collectReady()
    local folder = folderOf("ReadyToCollect")
    if not folder then return 0 end
    local _, _, used = inventoryCounts()
    local room = inventoryMax() - used
    if room <= 0 then return 0 end
    local fired = 0
    for _, model in ipairs(folder:GetChildren()) do
        if not alive() or fired >= CONFIG.collectBatch or room <= 0 then break end
        if model:IsA("Model")
            and model:GetAttribute("READY") == true
            and model:GetAttribute("FruitReady") ~= false then
            task.spawn(function()
                pcall(function() Net:InvokeServer("CollectPlant", model) end)
            end)
            fired = fired + 1
            room = room - 1
            task.wait(CONFIG.collectGap)
        end
    end
    if fired > 0 then STATE.collected = STATE.collected + fired end
    return fired
end

local function sellPlants()
    local plants = select(1, inventoryCounts())
    if plants <= 0 then return 0 end
    local before = money()
    local result = invoke("SellAll", 8)
    task.wait(0.4)
    local gained = money() - before
    if gained > 0 then
        STATE.sold = STATE.sold + plants
        STATE.earned = STATE.earned + gained
        STATE.lastSale = gained
    elseif result == "No Plants" then
        note("sell: nothing to sell")
    end
    return gained
end

local function previewModels()
    local p = plot()
    local rng = p and p:FindFirstChild("RNG")
    local preview = rng and rng:FindFirstChild("Preview")
    if not preview then return {} end
    local out = {}
    for _, child in ipairs(preview:GetChildren()) do
        if child:IsA("Model") then out[#out + 1] = child end
    end
    return out
end

local function rollOnce()
    invoke("Roll", 8)
    STATE.rolls = STATE.rolls + 1
    task.wait(0.6)
end

local function podiumWorthKeeping()
    local _, worstRate = weakestPlaced()
    local haveRoom = not gardenFull()
    for _, model in ipairs(previewModels()) do
        if haveRoom or gnomeRate(model.Name) > worstRate * CONFIG.buyMargin then
            return true
        end
    end
    return false
end

local function buyFromPodium()
    local models = previewModels()
    if #models == 0 then return false end
    local _, worstRate = weakestPlaced()
    local haveRoom = not gardenFull()
    local bestModel, bestName, bestRate = nil, nil, -1
    for _, model in ipairs(models) do
        local name = model.Name
        local rate = gnomeRate(name)
        local price = gnomePrice(name)
        if price <= money() and rate > bestRate then
            local worthIt = haveRoom or rate > worstRate * CONFIG.buyMargin
            if worthIt then bestModel, bestName, bestRate = model, name, rate end
        end
    end
    if not bestModel then return false end
    local _, farmersBefore = inventoryCounts()
    fire("BuyFarmer", bestModel)
    task.wait(1.0)
    local _, farmersAfter = inventoryCounts()
    if farmersAfter > farmersBefore or bestModel.Parent == nil then
        STATE.bought = STATE.bought + 1
        STATE.bestGnome = bestName
        note("bought %s ($%s, %.2f/s)", bestName, tostring(gnomePrice(bestName)), bestRate)
        return true
    end
    return false
end

local function heldGnomeTools()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return {} end
    local tools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("type") == "Farmer" then
            tools[#tools + 1] = tool
        end
    end
    table.sort(tools, function(a, b)
        return gnomeRate(a:GetAttribute("FarmerName") or a.Name)
             > gnomeRate(b:GetAttribute("FarmerName") or b.Name)
    end)
    return tools
end

local function seatTool(tool, humanoid)
    local name = tool:GetAttribute("FarmerName") or tool.Name
    local spots = placementSpots(CONFIG.placeTries)
    if #spots == 0 then
        note("place: no spot found")
        return false
    end
    humanoid:EquipTool(tool)
    task.wait(0.35)
    for _, spot in ipairs(spots) do
        local before = placedCount()
        fire("Place", "Farmer", name, CFrame.new(spot), "1")
        task.wait(0.8)
        if placedCount() > before then
            STATE.placed = STATE.placed + 1
            STATE.plotFull = false
            STATE.placeFails = 0
            return true
        end
    end
    return false
end

local function placeGnomes()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end
    local tools = heldGnomeTools()
    if #tools == 0 then return 0 end
    local placed = 0
    for _, tool in ipairs(tools) do
        if not alive() then break end
        if gardenFull() then
            local worstName, worstRate, worstUid = weakestPlaced()
            local mine = gnomeRate(tool:GetAttribute("FarmerName") or tool.Name)
            if not worstUid or mine <= worstRate * CONFIG.buyMargin then
                break
            end
            fire("PickupFarmer", worstUid)
            task.wait(1.0)
            if placedCount() >= STATE.gnomeCap then
                note("swap: %s would not come off the plot", tostring(worstName))
                break
            end
            STATE.swaps = STATE.swaps + 1
            note("swapping out %s (%.2f/s) for %.2f/s", tostring(worstName), worstRate, mine)
        end
        if seatTool(tool, humanoid) then
            placed = placed + 1
        else
            STATE.placeFails = STATE.placeFails + 1
            if STATE.placeFails >= 2 then
                STATE.gnomeCap = placedCount()
                STATE.plotFull = true
                note("garden is full at %d gnomes", STATE.gnomeCap)
            end
            break
        end
    end
    pcall(function() humanoid:UnequipTools() end)
    return placed
end

----------------------------------------------------------------------------
-- Pets
----------------------------------------------------------------------------

local PET_TIERS = {
    Common = 1, Uncommon = 2, Rare = 3, Epic = 4,
    Legendary = 5, Mythic = 6, Godly = 7, IMPOSSIBLE = 8,
}
local PET_CHOICES = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }

local function petTier(name)
    local cfg = CfgPets[name]
    return (type(cfg) == "table" and PET_TIERS[cfg.rarity]) or 0
end

local function petPrice(name)
    local cfg = CfgPets[name]
    return (type(cfg) == "table" and tonumber(cfg.price)) or math.huge
end

local function maxPets()
    return tonumber(data().max_equipped_pets) or 3
end

local function placedPets()
    local folder = folderOf("ClientPets")
    if not folder then return 0 end
    local n = 0
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("Model") then n = n + 1 end
    end
    return n
end

local function heldPetTools()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return {} end
    local tools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("type") == "Pet" then
            tools[#tools + 1] = tool
        end
    end
    table.sort(tools, function(a, b)
        return petTier(a:GetAttribute("PetName") or a.Name)
             > petTier(b:GetAttribute("PetName") or b.Name)
    end)
    return tools
end

local function weakestPlacedPet()
    local worstUid, worstName, worstTier
    for uid, entry in pairs(data().pets or {}) do
        if type(entry) == "table" and entry.name then
            local tier = petTier(entry.name)
            if not worstTier or tier < worstTier then
                worstUid, worstName, worstTier = uid, entry.name, tier
            end
        end
    end
    return worstUid, worstName, worstTier or 0
end

local function placePets()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end
    local tools = heldPetTools()
    if #tools == 0 then return 0 end
    local seated = 0
    for _, tool in ipairs(tools) do
        if not alive() then break end
        if placedPets() >= maxPets() then
            local worstUid, worstName, worstTier = weakestPlacedPet()
            local mine = petTier(tool:GetAttribute("PetName") or tool.Name)
            if not worstUid or mine <= worstTier then break end
            fire("PickupPet", worstUid)
            task.wait(1.0)
            if placedPets() >= maxPets() then
                note("pet swap: the %s would not come off the plot", tostring(worstName))
                break
            end
            STATE.petSwaps = STATE.petSwaps + 1
            note("swapping the %s out for a %s", tostring(worstName),
                tostring(tool:GetAttribute("PetName") or tool.Name))
        end
        humanoid:EquipTool(tool)
        task.wait(0.35)
        local allowed = invoke("CanPlacePet", 6, tool)
        if not allowed then
            note("pet %s: server says it cannot be placed", tool.Name)
            break
        end
        local spots = placementSpots(CONFIG.placeTries)
        local placedOne = false
        for _, spot in ipairs(spots) do
            local before = placedPets()
            fire("PlacePet", tool, CFrame.new(spot))
            task.wait(0.8)
            if placedPets() > before then
                placedOne = true
                seated = seated + 1
                STATE.petsPlaced = STATE.petsPlaced + 1
                note("placed pet %s", tool.Name)
                break
            end
        end
        if not placedOne then break end
    end
    pcall(function() humanoid:UnequipTools() end)
    return seated
end

----------------------------------------------------------------------------
-- Upgrade tree
----------------------------------------------------------------------------

local BRANCHES = { "Main", "Gnomes", "Plants", "Player", "Pets" }

local function ownedNodes()
    local owned = data().upgrade_tree
    return type(owned) == "table" and owned or {}
end

local function requirementsMet(node, owned)
    local requires = node.Requires
    if type(requires) ~= "table" then return true end
    for _, needed in pairs(requires) do
        if not owned[needed] then return false end
    end
    return true
end

local function plotRate()
    local total = 0
    for _, entry in pairs(placedFarmers()) do
        if type(entry) == "table" and entry.name then
            total = total + gnomeRate(entry.name)
        end
    end
    return total
end

local rateSamples = {}
local function observedRate()
    return STATE.observed or 0
end

local function sampleRate()
    local now = os.clock()
    rateSamples[#rateSamples + 1] = { t = now, v = STATE.earned }
    while #rateSamples > 45 do table.remove(rateSamples, 1) end
    local first = rateSamples[1]
    if first and now - first.t >= 5 then
        STATE.observed = (STATE.earned - first.v) / (now - first.t)
    end
end

local function income()
    return math.max(plotRate(), observedRate())
end

local function gnomeReserve()
    if not CONFIG.autoBuy then return 0 end
    local _, worstRate = weakestPlaced()
    local full = gardenFull()
    local perSecond = income()
    local cash = money()
    local reserve = 0
    for _, model in ipairs(previewModels()) do
        local name = model.Name
        local price = gnomePrice(name)
        local worthIt = (not full) or gnomeRate(name) > worstRate * CONFIG.buyMargin
        local reachable = price <= cash + perSecond * CONFIG.reserveWindow
        if worthIt and reachable and price < math.huge and price > reserve then
            reserve = price
        end
    end
    return reserve
end

local petReserve

local function spendable()
    return money() - gnomeReserve() - (petReserve and petReserve() or 0)
end

local function buyTreeNode()
    local owned = ownedNodes()
    local budget = spendable()
    local bestBranch, bestKey, bestNode, bestPrice = nil, nil, nil, math.huge
    for _, branch in ipairs(BRANCHES) do
        local nodes = CfgTree[branch]
        if type(nodes) == "table" then
            for key, node in pairs(nodes) do
                if type(node) == "table" and not owned[key] then
                    local price = tonumber(node.Price)
                    if price and price <= budget and price < bestPrice
                        and requirementsMet(node, owned) then
                        bestBranch, bestKey, bestNode, bestPrice = branch, key, node, price
                    end
                end
            end
        end
    end
    if not bestKey then return false end
    local result = invoke("Upgrade", 8, bestBranch, bestKey)
    task.wait(0.5)
    if ownedNodes()[bestKey] then
        STATE.upgrades = STATE.upgrades + 1
        note("upgrade %s ($%s)", bestNode.Name or bestKey, tostring(bestPrice))
        return true
    end
    if result == "Not Enough" or result == "Maxed" or result == "Invalid" then
        note("upgrade %s: %s", bestKey, tostring(result))
    end
    return false
end

----------------------------------------------------------------------------
-- Gear shop
----------------------------------------------------------------------------

local GEAR_MODES = {
    ["Sprinklers + fertilizer"] = { Sprinkler = true, Fertilizer = true },
    ["Sprinklers only"]         = { Sprinkler = true },
    ["Everything"]              = { Sprinkler = true, Fertilizer = true, GnomeItem = true, WateringCan = true },
}

local GEAR_KINDS     = { Sprinkler = true, Fertilizer = true, GnomeItem = true, WateringCan = true }
local GEAR_PLACEABLE = { Sprinkler = true, Fertilizer = true }

local function gearWanted(kind)
    local set = GEAR_MODES[CONFIG.gearMode] or GEAR_MODES["Sprinklers + fertilizer"]
    return set[kind] == true
end

local function shopStock()
    local shop = data().timedShop
    local stock = type(shop) == "table" and shop.stock or nil
    return type(stock) == "table" and stock or {}
end

local function shopEntries()
    local items = type(CfgShop) == "table" and CfgShop.Items or nil
    return type(items) == "table" and items or {}
end

local function gearLive()
    local n = 0
    for _, key in ipairs({ "sprinklers", "fertilizer" }) do
        local t = data()[key]
        if type(t) == "table" then for _ in pairs(t) do n = n + 1 end end
    end
    return n
end

local function placedGear(kind)
    local t = data()[kind == "Fertilizer" and "fertilizer" or "sprinklers"]
    local n = 0
    if type(t) == "table" then for _ in pairs(t) do n = n + 1 end end
    return n
end

local function buyGear()
    local stock = shopStock()
    local cash, budget = money(), spendable()
    local bestName, bestPrice = nil, math.huge
    for name, entry in pairs(shopEntries()) do
        if type(entry) == "table" and (tonumber(stock[name]) or 0) > 0 and gearWanted(entry.type) then
            local price = tonumber(entry.price)
            local usable = entry.type == "WateringCan" or placedCount() >= 2
            if price and usable and price < bestPrice
                and price <= budget and cash >= price * CONFIG.gearKeep then
                bestName, bestPrice = name, price
            end
        end
    end
    if not bestName then return false end
    local before = tonumber(stock[bestName]) or 0
    local result = invoke("Purchase", 8, bestName)
    task.wait(0.6)
    if result == true or (tonumber(shopStock()[bestName]) or 0) < before then
        STATE.gearBought = STATE.gearBought + 1
        STATE.lastGear = bestName
        note("bought %s ($%s)", bestName, tostring(bestPrice))
        return true
    end
    note("shop: %s refused (%s)", bestName, tostring(result))
    return false
end

local function gearRange(kind, name)
    local cfg = kind == "Fertilizer" and CfgFert or CfgSprink
    local entry = type(cfg) == "table" and cfg[name] or nil
    return (type(entry) == "table" and tonumber(entry.range)) or 11
end

local function gearSpots(range)
    local minx, maxx, minz, maxz, y = gardenBounds()
    if not minx then return {} end
    local points = occupiedPoints()
    local candidates = {}
    for x = minx, maxx, 2 do
        for z = minz, maxz, 2 do
            local covered = 0
            for _, point in ipairs(points) do
                local dx, dz = point.X - x, point.Z - z
                if dx * dx + dz * dz <= range * range then covered = covered + 1 end
            end
            candidates[#candidates + 1] = { x = x, z = z, n = covered }
        end
    end
    table.sort(candidates, function(a, b) return a.n > b.n end)
    local spacing = math.max(range * 0.5, 3)
    local out = {}
    for _, pick in ipairs(candidates) do
        local far = true
        for _, taken in ipairs(out) do
            local dx, dz = taken.X - pick.x, taken.Z - pick.z
            if math.sqrt(dx * dx + dz * dz) < spacing then far = false break end
        end
        if far then
            out[#out + 1] = Vector3.new(pick.x, y, pick.z)
            if #out >= 4 then break end
        end
    end
    return out
end

local function gearTools()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return {} end
    local tools = {}
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and GEAR_KINDS[tool:GetAttribute("type")] then
            tools[#tools + 1] = tool
        end
    end
    return tools
end

local function gearHeld(kind)
    local n = 0
    for _, item in pairs(inventory()) do
        if type(item) == "table" and item.type == kind then n = n + 1 end
    end
    return n
end

local function seatGear(kind, name, spots)
    for _, spot in ipairs(spots) do
        local before = placedGear(kind)
        fire("Place", kind, name, CFrame.new(spot), "1")
        task.wait(0.7)
        if placedGear(kind) > before then
            note("placed %s", name)
            return true
        end
    end
    return false
end

local function bestCoffeeGnome()
    local folder = folderOf("Workers")
    if not folder then return nil end
    local placed = placedFarmers()
    local best, bestRate
    for _, gnome in ipairs(folder:GetChildren()) do
        local entry = placed[gnome.Name]
        local farmer = (type(entry) == "table" and entry.name) or gnome:GetAttribute("FarmerName")
        local speed = tonumber(gnome:GetAttribute("GnomeSpeed")) or 1
        if farmer and speed <= 1 then
            local rate = gnomeRate(farmer)
            if not bestRate or rate > bestRate then best, bestRate = gnome, rate end
        end
    end
    return best, bestRate
end

local function giveGnomeItem(tool, name, gnome)
    local before = gearHeld("GnomeItem")
    fire("GiveFarmerItem", gnome, tool)
    task.wait(0.8)
    if gearHeld("GnomeItem") < before then
        note("gave the %s to a gnome", name)
        return true
    end
    return false
end

local function slowestPlant()
    local folder = folderOf("Plants")
    if not folder then return nil end
    local best, worst
    for _, model in ipairs(folder:GetChildren()) do
        local left = tonumber(model:GetAttribute("SecondsUntilReady"))
        if left and (not worst or left > worst) then best, worst = model, left end
    end
    return best, worst
end

local function waterOne(name, model)
    local before = gearHeld("WateringCan")
    fire("WaterPlant", model)
    task.wait(0.8)
    if gearHeld("WateringCan") < before then
        note("watered a crop with the %s", name)
        return true
    end
    return false
end

local function useGear()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0 end
    local tools = gearTools()
    if #tools == 0 then return 0 end
    local used, touched = 0, false
    for _, tool in ipairs(tools) do
        if not alive() then break end
        local kind = tool:GetAttribute("type")
        local name = tool:GetAttribute("ItemName") or tool.Name
        local spots, gnome, plant
        if GEAR_PLACEABLE[kind] then       spots = gearSpots(gearRange(kind, name))
        elseif kind == "GnomeItem" then    gnome = bestCoffeeGnome()
        elseif kind == "WateringCan" then  plant = slowestPlant()
        end
        if (spots and #spots > 0) or gnome or plant then
            touched = true
            humanoid:EquipTool(tool)
            task.wait(0.35)
            local ok
            if spots then       ok = seatGear(kind, name, spots)
            elseif gnome then   ok = giveGnomeItem(tool, name, gnome)
            elseif plant then   ok = waterOne(name, plant)
            end
            if ok then
                used = used + 1
                STATE.gearUsed = STATE.gearUsed + 1
            else
                note("gear %s: the server did not take it", name)
                break
            end
        end
    end
    if touched then pcall(function() humanoid:UnequipTools() end) end
    return used
end

----------------------------------------------------------------------------
-- World pets
----------------------------------------------------------------------------

local function petSecondsLeft(model)
    local overhead = model:FindFirstChild("Overhead")
    local label = overhead and overhead:FindFirstChild("Timer")
    local text = label and label.Text or ""
    local minutes, seconds = text:match("(%d+)m%s*(%d+)s")
    if minutes then return tonumber(minutes) * 60 + tonumber(seconds) end
    local only = text:match("(%d+)s")
    return only and tonumber(only) or nil
end

local function worldPets()
    local spawns = workspace:FindFirstChild("PetSpawns")
    local folder = spawns and spawns:FindFirstChild("Pets")
    if not folder then return {} end
    local out = {}
    for _, model in ipairs(folder:GetChildren()) do
        local name = model.Name:match("^WorldPet_(.+)$")
        if name and type(CfgPets[name]) == "table" then
            out[#out + 1] = {
                model  = model,
                name   = name,
                tier   = petTier(name),
                price  = petPrice(name),
                huge   = model:GetAttribute("Huge") == true,
                rolled = tonumber(model:GetAttribute("RolledRarity")) or 0,
                left   = petSecondsLeft(model),
            }
        end
    end
    return out
end

local function petFloor()
    local floor = PET_TIERS[CONFIG.petRarity] or 1
    if placedPets() >= maxPets() then
        floor = math.max(floor, select(3, weakestPlacedPet()) + 1)
    end
    return floor
end

local function ownedPets()
    local _, _, _, pets = inventoryCounts()
    return pets + placedPets()
end

function petReserve()
    if not CONFIG.autoBuyPets then return 0 end
    local floor = petFloor()
    local cash, perSecond = money(), income()
    local reserve = 0
    for _, pet in ipairs(worldPets()) do
        local window = math.min(CONFIG.reserveWindow, pet.left or CONFIG.reserveWindow)
        local worthIt = pet.tier >= floor and (pet.left == nil or pet.left >= 20)
        local reachable = pet.price <= cash + perSecond * window
        if worthIt and reachable and pet.price > reserve then reserve = pet.price end
    end
    return reserve
end

local function fetchPet(pet)
    if not fireproximityprompt then
        note("pets: this executor has no fireproximityprompt")
        return false
    end
    local root = pet.model:FindFirstChild("HumanoidRootPart")
    local prompt = root and root:FindFirstChild("BuyPetPrompt")
    if not prompt then return false end
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local home = hrp.CFrame
    local target = CFrame.new(pet.model:GetPivot().Position + Vector3.new(0, 4, 4))
    local before = ownedPets()
    local pin
    pin = RunService.Heartbeat:Connect(function()
        if not alive() then pin:Disconnect() return end
        local ch = LocalPlayer.Character
        local body = ch and ch:FindFirstChild("HumanoidRootPart")
        if body then body.CFrame = target end
    end)
    pcall(function()
        task.wait(0.8)
        fireproximityprompt(prompt)
        task.wait(1.2)
    end)
    pin:Disconnect()
    pcall(function()
        local ch = LocalPlayer.Character
        local body = ch and ch:FindFirstChild("HumanoidRootPart")
        if body then body.CFrame = home end
    end)
    if ownedPets() > before then
        STATE.petsBought = STATE.petsBought + 1
        STATE.petBest = pet.name
        note("bought pet %s (1/%s, $%s)", pet.name, tostring(pet.rolled), tostring(pet.price))
        return true
    end
    note("pet %s: not sold", pet.name)
    return false
end

local function buyWorldPet()
    local pets = worldPets()
    STATE.petSeen = #pets
    if #pets == 0 then return false end
    local floor = petFloor()
    local cash = money()
    local budget = cash - gnomeReserve()
    local best
    for _, pet in ipairs(pets) do
        if pet.tier >= floor and pet.price <= budget and cash >= pet.price * CONFIG.petKeep then
            if not best
                or pet.tier > best.tier
                or (pet.tier == best.tier and pet.huge and not best.huge) then
                best = pet
            end
        end
    end
    if not best then return false end
    return fetchPet(best)
end

----------------------------------------------------------------------------
-- Expansion, free gnome, rebirth
----------------------------------------------------------------------------

local function expansionSquares()
    local p = plot()
    local holder = p and p:FindFirstChild("ExpandPlot")
    if not holder then return {} end
    local seen, out = {}, {}
    for _, descendant in ipairs(holder:GetDescendants()) do
        if descendant.Name == "BoundaryPart" and descendant:IsA("BasePart") then
            local parent = descendant.Parent
            if parent and parent.Name ~= "Highlight" and not seen[parent] then
                seen[parent] = true
                local price = tonumber(CfgExpand[parent.Name])
                if price then out[#out + 1] = { model = parent, price = price } end
            end
        end
    end
    table.sort(out, function(a, b) return a.price < b.price end)
    return out
end

local function expansionCount()
    local owned = data().plot_expansions
    local n = 0
    if type(owned) == "table" then for _ in pairs(owned) do n = n + 1 end end
    return n
end

local function expandPlot()
    for _, square in ipairs(expansionSquares()) do
        local model, price = square.model, square.price
        if money() >= price * CONFIG.expandKeep and spendable() >= price then
            local before = expansionCount()
            fire("ExpandPlot", model)
            task.wait(1.2)
            if expansionCount() > before then
                STATE.expansions = STATE.expansions + 1
                STATE.gnomeCap = 0
                STATE.plotFull = false
                STATE.placeFails = 0
                note("expanded plot: %s ($%s)", model.Name, tostring(price))
                return true
            end
        end
    end
    return false
end

local function claimFreeGnome()
    local free = data().freeGnome
    if type(free) == "table" and free.canClaim == true then
        fire("ClaimFreeGnome")
        task.wait(0.8)
        note("claimed the free gnome")
        return true
    end
    return false
end

local function rebirthOnce()
    local tier = CfgRebirths["Rebirth" .. tostring(rebirths() + 1)]
    if type(tier) ~= "table" then return false end
    local requirement = tonumber(tier.requirements and tier.requirements.money) or math.huge
    if money() < requirement then return false end
    if not CONFIG.autoRebirth then
        note("rebirth is affordable ($%d) - toggle it on to run it", requirement)
        return false
    end
    local result = invoke("Rebirth", 10)
    task.wait(1.5)
    if result then
        STATE.gnomeCap = 0
        STATE.plotFull = false
        STATE.placeFails = 0
        note("rebirthed")
    end
    return result and true or false
end

----------------------------------------------------------------------------
-- Census
----------------------------------------------------------------------------

local function census()
    STATE.money = money()
    STATE.rebirths = rebirths()
    STATE.rollLuck = tonumber(LocalPlayer:GetAttribute("RollLuck")) or 1
    local plants, farmers, used = inventoryCounts()
    STATE.invUsed = used
    STATE.invMax = inventoryMax()
    STATE.gnomes = placedCount()
    local ready, growing = 0, 0
    local folder = folderOf("ReadyToCollect")
    if folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA("Model") and model:GetAttribute("READY") == true then
                ready = ready + 1
            end
        end
    end
    local plantFolder = folderOf("Plants")
    if plantFolder then
        for _, model in ipairs(plantFolder:GetChildren()) do
            if model:IsA("Model") then growing = growing + 1 end
        end
    end
    STATE.ready = ready
    STATE.growing = growing
    local worstName = weakestPlaced()
    STATE.weakest = worstName or "-"
    sampleRate()
    STATE.rate = plotRate()
    STATE.reserve = gnomeReserve()
    STATE.pets = placedPets()
    STATE.petCap = maxPets()
    STATE.petsOwned = ownedPets()
    STATE.petReserve = petReserve()
    STATE.gearLive = gearLive()
    STATE.restock = tonumber(ReplicatedStorage:GetAttribute("RestockSecondsLeft")) or 0
    return plants, farmers
end

----------------------------------------------------------------------------
-- Loops
----------------------------------------------------------------------------

local function loop(name, gap, fn)
    task.spawn(function()
        while alive() do
            local ok, err = pcall(fn)
            if not ok then note("%s: %s", name, tostring(err)) end
            task.wait(gap)
        end
    end)
end

task.spawn(function()
    while alive() do
        if not CONFIG.auto then
            STATE.phase = "idle"
            task.wait(1)
        else
            local plants = census()
            if CONFIG.autoCollect then
                STATE.phase = "collecting"
                collectReady()
            end
            plants = select(1, inventoryCounts())
            if CONFIG.autoSell and plants > 0 then
                local full = STATE.invUsed >= STATE.invMax * CONFIG.sellAt
                local nothingReady = STATE.ready == 0
                if full or nothingReady then
                    STATE.phase = "selling"
                    sellPlants()
                end
            end
            if CONFIG.autoPlace then
                STATE.phase = "placing"
                placeGnomes()
            end
            if CONFIG.autoBuyPets then
                STATE.phase = "pet hunt"
                buyWorldPet()
            end
            if CONFIG.autoPets and #heldPetTools() > 0 then
                STATE.phase = "pets"
                placePets()
            end
            if CONFIG.autoGearUse and #gearTools() > 0 then
                STATE.phase = "gear"
                useGear()
            end
            if CONFIG.autoBuy then
                STATE.phase = "buying"
                buyFromPodium()
            end
            if CONFIG.autoRoll and not podiumWorthKeeping() then
                STATE.phase = "rolling"
                rollOnce()
            end
            task.wait(0.3)
        end
    end
end)

loop("spend", 6, function()
    if not CONFIG.auto then return end
    if CONFIG.autoUpgrade then buyTreeNode() end
    if CONFIG.autoGear then buyGear() end
    if CONFIG.autoExpand then expandPlot() end
    rebirthOnce()
end)

loop("free", 30, function()
    if not CONFIG.auto then return end
    if CONFIG.autoFreeGnome then claimFreeGnome() end
end)

loop("census", 1, census)

----------------------------------------------------------------------------
-- Window Setup
----------------------------------------------------------------------------

local isLobby = false

local Window = Library:CreateWindow({
    Title = "Ivory",
    Icon = "swords",
    Footer = {
        "v1.4 |",
        { Text = isLobby and "Lobby" or "Game", Copyable = true },
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

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("game")

----------------------------------------------------------------------------
-- Tabs
----------------------------------------------------------------------------

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local FarmingTab = Window:AddTab({ Name = "Farming", Icon = "leaf" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "bag" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- Main Tab
local MainSubTab = MainTab:AddSubTab("Overview", "home")
local MainLeft = MainSubTab:AddLeftGroupbox("Discord", "users")
local MainRight = MainSubTab:AddRightGroupbox("Status", "info")

MainLeft:AddButton("Join Discord For Dupe", function()
    if setclipboard then
        setclipboard("https://discord.gg/MCWYKBdB4E")
        Library:Notify({ Title = "Ivory", Description = "Discord link copied to clipboard!", Type = "Success", Time = 3 })
    else
        Library:Notify({ Title = "Ivory", Description = "setclipboard not available", Type = "Error", Time = 3 })
    end
end)

local StatusLabel = MainRight:AddLabel("Status: Idle")
local CashLabel = MainRight:AddLabel("Cash: $0")
local GnomesLabel = MainRight:AddLabel("Gnomes: 0")
local PetsLabel = MainRight:AddLabel("Pets: 0/3")

-- Farming Tab
local AutoSubTab = FarmingTab:AddSubTab("Automation", "zap")
local GardenGroup = AutoSubTab:AddLeftGroupbox("Garden", "box-icon")
local RollGroup = AutoSubTab:AddRightGroupbox("Rolling", "refresh-cw")

GardenGroup:AddToggle("AutoHarvest", {
    Text = "Auto Harvest",
    Default = CONFIG.autoCollect,
    Callback = function(v) CONFIG.autoCollect = v end
})
GardenGroup:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = CONFIG.autoSell,
    Callback = function(v) CONFIG.autoSell = v end
})
GardenGroup:AddToggle("AutoPlace", {
    Text = "Auto Place",
    Default = CONFIG.autoPlace,
    Callback = function(v) CONFIG.autoPlace = v end
})
GardenGroup:AddToggle("AutoPlacePets", {
    Text = "Auto Place Pets",
    Default = CONFIG.autoPets,
    Callback = function(v) CONFIG.autoPets = v end
})
GardenGroup:AddSlider("HarvestGap", {
    Text = "Harvest Gap (ms)",
    Min = 40,
    Max = 300,
    Default = math.floor(CONFIG.collectGap * 1000),
    Callback = function(v) CONFIG.collectGap = v / 1000 end
})
GardenGroup:AddSlider("SellAt", {
    Text = "Sell At %",
    Min = 40,
    Max = 100,
    Default = math.floor(CONFIG.sellAt * 100),
    Callback = function(v) CONFIG.sellAt = v / 100 end
})
GardenGroup:AddSlider("PlacementClearance", {
    Text = "Placement Clearance",
    Min = 2,
    Max = 8,
    Default = math.floor(CONFIG.placeClear),
    Callback = function(v) CONFIG.placeClear = v end
})

RollGroup:AddToggle("AutoRoll", {
    Text = "Auto Roll",
    Default = CONFIG.autoRoll,
    Callback = function(v) CONFIG.autoRoll = v end
})
RollGroup:AddToggle("AutoBuyGnome", {
    Text = "Auto Buy Gnome",
    Default = CONFIG.autoBuy,
    Callback = function(v) CONFIG.autoBuy = v end
})
RollGroup:AddSlider("BuyMargin", {
    Text = "Buy Margin",
    Min = 100,
    Max = 300,
    Default = math.floor(CONFIG.buyMargin * 100),
    Callback = function(v) CONFIG.buyMargin = v / 100 end
})

local SpendSubTab = FarmingTab:AddSubTab("Spending", "dollar-sign")
local UpgradeGroup = SpendSubTab:AddLeftGroupbox("Upgrades", "arrow-up-circle")
local ExpandGroup = SpendSubTab:AddRightGroupbox("Expansion", "maximize-2")

UpgradeGroup:AddToggle("AutoUpgrades", {
    Text = "Auto Upgrades",
    Default = CONFIG.autoUpgrade,
    Callback = function(v) CONFIG.autoUpgrade = v end
})
UpgradeGroup:AddToggle("AutoFreeGnome", {
    Text = "Auto Free Gnome",
    Default = CONFIG.autoFreeGnome,
    Callback = function(v) CONFIG.autoFreeGnome = v end
})
UpgradeGroup:AddToggle("AutoRebirth", {
    Text = "Auto Rebirth",
    Default = CONFIG.autoRebirth,
    Callback = function(v) CONFIG.autoRebirth = v end,
    Tooltip = "UNVERIFIED - never tested on a real save"
})

ExpandGroup:AddToggle("AutoExpandPlot", {
    Text = "Auto Expand Plot",
    Default = CONFIG.autoExpand,
    Callback = function(v) CONFIG.autoExpand = v end
})
ExpandGroup:AddSlider("ExpandKeep", {
    Text = "Expand Cash Multiple",
    Min = 1,
    Max = 10,
    Default = math.floor(CONFIG.expandKeep),
    Callback = function(v) CONFIG.expandKeep = v end
})

-- Shop Tab
local GearSubTab = ShopTab:AddSubTab("Gear", "package")
local GearGroup = GearSubTab:AddLeftGroupbox("Item Shop", "shopping-cart")
local PetShopGroup = GearSubTab:AddRightGroupbox("Pet Field", "heart")

GearGroup:AddToggle("AutoBuyGear", {
    Text = "Auto Buy Gear",
    Default = CONFIG.autoGear,
    Callback = function(v) CONFIG.autoGear = v end
})
GearGroup:AddToggle("AutoUseGear", {
    Text = "Auto Use Gear",
    Default = CONFIG.autoGearUse,
    Callback = function(v) CONFIG.autoGearUse = v end
})
GearGroup:AddDropdown("GearMode", {
    Text = "Gear Mode",
    Values = { "Sprinklers + fertilizer", "Sprinklers only", "Everything" },
    Default = CONFIG.gearMode,
    Callback = function(v) CONFIG.gearMode = v end
})
GearGroup:AddSlider("GearKeep", {
    Text = "Gear Cash Multiple",
    Min = 1,
    Max = 10,
    Default = math.floor(CONFIG.gearKeep),
    Callback = function(v) CONFIG.gearKeep = v end
})

PetShopGroup:AddToggle("AutoBuyPets", {
    Text = "Auto Buy Pets",
    Default = CONFIG.autoBuyPets,
    Callback = function(v) CONFIG.autoBuyPets = v end
})
PetShopGroup:AddDropdown("LowestRarity", {
    Text = "Lowest Rarity",
    Values = PET_CHOICES,
    Default = CONFIG.petRarity,
    Callback = function(v) CONFIG.petRarity = v end
})
PetShopGroup:AddSlider("PetKeep", {
    Text = "Pet Cash Multiple",
    Min = 1,
    Max = 10,
    Default = math.floor(CONFIG.petKeep),
    Callback = function(v) CONFIG.petKeep = v end
})

local StatusSubTab = ShopTab:AddSubTab("Status", "bar-chart-2")
local StatusGroup = StatusSubTab:AddLeftGroupbox("Shop Stock", "package")
local PetStatusGroup = StatusSubTab:AddRightGroupbox("Pet Status", "heart")

StatusGroup:AddLabel("Loading...")
PetStatusGroup:AddLabel("Loading...")

-- Settings Tab
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "settings")

MenuGroup:AddToggle("CustomCursor", {
    Text = "Custom Cursor",
    Default = true,
    Callback = function(v) Library.ShowCustomCursor = v end
})

MenuGroup:AddDropdown("NotifSide", {
    Text = "Notification Side",
    Values = { "Left", "Right" },
    Default = "Right",
    Callback = function(v) Library.NotifySide = v end
})

MenuGroup:AddButton("Test Notification", function()
    Library:Notify({ Title = "Ivory", Description = "This is a test notification!", Type = "Info", Time = 3 })
end)

MenuGroup:AddSlider("DPIScale", {
    Text = "DPI Scale",
    Min = 50,
    Max = 200,
    Default = 100,
    Callback = function(v) Library:SetDPIScale(v) end
})

MenuGroup:AddSlider("CornerRadius", {
    Text = "Corner Radius",
    Min = 0,
    Max = 20,
    Default = 4,
    Callback = function(v) Library.CornerRadius = v end
})

local MenuKeybind = MenuGroup:AddToggle("MenuKeybindToggle", {
    Text = "Menu Keybind",
    Default = false,
})
MenuKeybind:AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    Text = "Menu Toggle",
    Mode = "Toggle",
    SyncToggleState = true
})

MenuGroup:AddButton("Unload", function()
    _G.__IVORY = (_G.__IVORY or 0) + 1
    pcall(function() Window:Destroy() end)
    Library:Notify({ Title = "Ivory", Description = "Script unloaded!", Type = "Info", Time = 2 })
end)

----------------------------------------------------------------------------
-- Status Updates
----------------------------------------------------------------------------

task.spawn(function()
    while alive() do
        pcall(function()
            StatusLabel.Text = "Status: " .. STATE.phase
            CashLabel.Text = "Cash: $" .. tostring(STATE.money)
            GnomesLabel.Text = "Gnomes: " .. tostring(STATE.gnomes)
            PetsLabel.Text = "Pets: " .. tostring(STATE.pets) .. "/" .. tostring(STATE.petCap)
        end)
        task.wait(1)
    end
end)

----------------------------------------------------------------------------
-- Init
----------------------------------------------------------------------------

census()
Library:Notify({ Title = "Ivory", Description = "Loaded successfully! Press ] to toggle menu.", Type = "Success", Time = 5 })