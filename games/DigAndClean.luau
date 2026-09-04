--// Ivory Hub - Dig & Clean
--// PlaceId: 83038462357724
--//
--// Based on tested reference: all remote calls verified against live game.
--// Uses PlayerScripts.TS.network modules (invoke/fire pattern).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local plr = Players.LocalPlayer
local PlaceId = game.PlaceId
local isLobby = (PlaceId == 83038462357724)

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

local LIB_SRC = httpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua")
if not LIB_SRC or #LIB_SRC == 0 then
	error("[Ivory] Failed to fetch library. Check HTTP support.")
end
local Library = loadstring(LIB_SRC)()
if not Library then
	error("[Ivory] Failed to compile library")
end

------------------------------------------------------------------------
--// NETWORK (from PlayerScripts.TS.network)
------------------------------------------------------------------------
local netFolder = plr:WaitForChild("PlayerScripts", 10)
    :WaitForChild("TS", 10)
    :WaitForChild("network", 10)
local netCache = {}
local function net(name)
    if not netCache[name] then netCache[name] = require(netFolder[name]) end
    return netCache[name]
end

local function invoke(modName, group, fn, ...)
    local args = table.pack(...)
    local ok, res = pcall(function()
        local m = net(modName)[group][fn]
        local p = m:invoke(table.unpack(args, 1, args.n))
        if p and p.expect then return p:expect() end
        return p
    end)
    return ok, res
end

local function fire(modName, group, ev, ...)
    local args = table.pack(...)
    pcall(function()
        net(modName)[group][ev]:fire(table.unpack(args, 1, args.n))
    end)
end

local function data()
    local ok, d = invoke("DataNetwork", "DataFunctions", "requestDataUpdate")
    return ok and type(d) == "table" and d or nil
end

local function tutorialStep()
    local ok, s = invoke("TutorialNetwork", "TutorialFunctions", "GetTutorialState")
    return ok and type(s) == "table" and s.step or -1
end

------------------------------------------------------------------------
--// GAME CONFIGS
------------------------------------------------------------------------
local Const = ReplicatedStorage:WaitForChild("TS"):WaitForChild("constants")
local CfgShovels = require(Const:WaitForChild("digging"):WaitForChild("Shovels"))
local CfgDig = require(Const:WaitForChild("digging"):WaitForChild("DiggingConfig"))
local CfgSprays = require(Const:WaitForChild("cleaning"):WaitForChild("SprayBottles"))
local CfgDetectors = require(Const:WaitForChild("digging"):WaitForChild("Detectors"))
local CfgItems = require(Const:WaitForChild("items"):WaitForChild("Items"))
local CfgBackpack = require(Const:WaitForChild("inventory"):WaitForChild("BackpackCapacity"))
local CfgIslands = require(Const:WaitForChild("world"):WaitForChild("Islands"))
local CfgSections = require(Const:WaitForChild("plot"):WaitForChild("PlotSections"))
local CfgPolishing = require(Const:WaitForChild("plot"):WaitForChild("Polishing"))
local CfgUpstairs = require(Const:WaitForChild("plot"):WaitForChild("UpstairsPedestals"))

------------------------------------------------------------------------
--// HELPERS
------------------------------------------------------------------------
local function notify(desc, kind)
    Library.Notify({ Title = "Ivory", Content = desc, Type = kind or "Info", Duration = 2.5 })
end

local function short(n)
    if type(n) ~= "number" then return "?" end
    local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
    local i = 1
    while n >= 1000 and i < #units do n = n / 1000 i = i + 1 end
    if i == 1 then return string.format("%d", n) end
    return string.format("%.2f%s", n, units[i])
end

local function char()
    local c = plr.Character
    if not c then return nil end
    return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function hop(goal, extraWait)
    local _, hrp = char()
    if not hrp or not goal then return false end
    local dist = (goal - hrp.Position).Magnitude
    if dist < 4 then return true end
    local dur = math.max(dist / 90, 0.1)
    TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(goal) }):Play()
    task.wait(dur + (extraWait or 0.4))
    return true
end

local function closeModals()
    local main = plr.PlayerGui:FindFirstChild("Main")
    if not main then return end
    for _, frame in ipairs(main:GetChildren()) do
        if frame:IsA("GuiObject") and frame.Visible then
            local button = frame:FindFirstChild("Close", true)
            if button and (button:IsA("ImageButton") or button:IsA("TextButton")) then
                for _, conn in ipairs(getconnections(button.Activated)) do
                    pcall(function() conn:Fire() end)
                end
            else
                frame.Visible = false
            end
        end
    end
end

local function backpackTools()
    local out = {}
    for _, t in ipairs(plr.Backpack:GetChildren()) do
        if t:IsA("Tool") then out[#out + 1] = t end
    end
    local c = plr.Character
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then out[#out + 1] = t end
        end
    end
    return out
end

local function inventoryList()
    local d = data()
    if not d or type(d.Inventory) ~= "table" then return {} end
    local out = {}
    for _, entry in pairs(d.Inventory) do
        if type(entry) == "table" and entry.uid then out[#out + 1] = entry end
    end
    return out
end

local function valueOf(entry)
    if not entry or not entry.id then return 0 end
    local ok, v = pcall(function()
        return CfgItems.itemValueFor(entry.id, entry.condition or "ok", tonumber(entry.kg) or 0)
    end)
    return ok and tonumber(v) or 0
end

local function backpackFullness()
    local d = data()
    if not d then return 0 end
    local count = #inventoryList()
    local limit = CfgBackpack.BASE_BACKPACK_CAPACITY + (d.BonusBackpackSlots or 0)
    local ok, lim = pcall(function() return CfgBackpack.BackpackCapacity.limitFor(d) end)
    if ok and tonumber(lim) then limit = lim end
    if limit <= 0 then return 0 end
    return count / limit
end

------------------------------------------------------------------------
--// WORLD HELPERS
------------------------------------------------------------------------
local function islandNameFor(id)
    if not _G.__DC_ISLE_NAMES then
        local ok, list = invoke("TravelNetwork", "TravelFunctions", "getIslands")
        local map = {}
        if ok and type(list) == "table" then
            for _, entry in ipairs(list) do
                if entry.id and entry.name then map[entry.id] = entry.name end
            end
        end
        _G.__DC_ISLE_NAMES = map
    end
    return _G.__DC_ISLE_NAMES[id]
end

local function islandFolder()
    local islands = Workspace:FindFirstChild("Islands")
    if not islands then return nil end
    local d = data()
    local name = d and islandNameFor(d.CurrentIsland)
    local folder = name and islands:FindFirstChild(name)
    if folder then return folder end
    return islands:GetChildren()[1]
end

local function nearestTagged(tag, container)
    local _, hrp = char()
    if not hrp then return nil end
    local best, bestDist
    for _, z in ipairs(CollectionService:GetTagged(tag)) do
        if not container or z:IsDescendantOf(container) then
            local ok, pivot = pcall(function() return z:GetPivot() end)
            if ok then
                local dist = (pivot.Position - hrp.Position).Magnitude
                if not bestDist or dist < bestDist then best, bestDist = z, dist end
            end
        end
    end
    return best, bestDist
end

local function npcNamed(name)
    local isl = islandFolder()
    local npcs = isl and isl:FindFirstChild("NPCs")
    if not npcs then return nil end
    local found = npcs:FindFirstChild(name, true)
    if not found then return nil end
    local ok, pivot = pcall(function() return found:GetPivot() end)
    return ok and pivot.Position or nil
end

------------------------------------------------------------------------
--// DIG CONTROLLER
------------------------------------------------------------------------
local DigClass
do
    local ctrl = plr.PlayerScripts.TS:FindFirstChild("controllers")
    local mod = ctrl and ctrl:FindFirstChild("DigController", true)
    if mod then
        local ok, m = pcall(require, mod)
        if ok and type(m) == "table" then DigClass = m.DigController end
    end
end

local function digController()
    local cached = _G.__DC_DIG
    if cached and getmetatable(cached) == DigClass then return cached end
    if not DigClass then return nil end
    for _, t in ipairs(getgc(true)) do
        if type(t) == "table" and getmetatable(t) == DigClass then
            _G.__DC_DIG = t
            return t
        end
    end
    return nil
end

------------------------------------------------------------------------
--// BURIED NODES
------------------------------------------------------------------------
local NODE_TTL = 25

local function armNodeListener()
    if _G.__DC_NODECONN then pcall(function() _G.__DC_NODECONN:Disconnect() end) end
    _G.__DC_SEEN = _G.__DC_SEEN or {}
    local ok, conn = pcall(function()
        return net("DetectorNetwork").DetectorEvents.BuriedNodes:connect(function(nodes)
            if type(nodes) ~= "table" then return end
            local now = os.clock()
            for _, n in ipairs(nodes) do
                if n.id and typeof(n.position) == "Vector3" then
                    local kept = _G.__DC_SEEN[n.id]
                    _G.__DC_SEEN[n.id] = {
                        id = n.id, position = n.position, rarity = n.rarity,
                        seenAt = kept and kept.seenAt or now,
                        lastSeen = now,
                    }
                end
            end
        end)
    end)
    if ok then _G.__DC_NODECONN = conn end
end

local function forgetNode(id)
    if id and _G.__DC_SEEN then _G.__DC_SEEN[id] = nil end
end

local function nodeList()
    local seen = _G.__DC_SEEN
    if type(seen) ~= "table" then return {} end
    local now = os.clock()
    local out = {}
    for id, n in pairs(seen) do
        if now - (n.seenAt or 0) > NODE_TTL then
            seen[id] = nil
        else
            out[#out + 1] = n
        end
    end
    return out
end

------------------------------------------------------------------------
--// DIG COST MODEL
------------------------------------------------------------------------
local RARITY = {}
do
    local order = CfgItems.RARITY_ORDER
    if type(order) == "table" then
        for i, name in ipairs(order) do RARITY[name] = i end
    end
end

local DIG_SPAN = (CfgDig.DIG_WIN_THRESHOLD or 0.985) - (CfgDig.DIG_PROGRESS_START or 0.33)

local function rarityStats(power)
    local key = string.format("%.3f", power or 1)
    _G.__DC_STATS2 = _G.__DC_STATS2 or {}
    if _G.__DC_STATS2[key] then return _G.__DC_STATS2[key] end
    local out = {}
    for _, rarity in ipairs(CfgItems.RARITY_ORDER or {}) do
        local powers, decays, values = {}, {}, {}
        for id, item in pairs(CfgItems.Items or {}) do
            if item.rarity == rarity then
                local ok, diff = pcall(CfgDig.digDifficultyFor, id, item.averageKg, power)
                if ok and type(diff) == "table" and (diff.clickPower or 0) > 0 then
                    powers[#powers + 1] = diff.clickPower
                    decays[#decays + 1] = diff.decay or 0
                end
                local okv, value = pcall(CfgItems.itemValueFor, id, "ok", item.averageKg)
                if okv and type(value) == "number" then values[#values + 1] = value end
            end
        end
        local function mid(t) table.sort(t); return t[math.ceil(#t / 2)] end
        out[rarity] = {
            clickPower = mid(powers) or 0,
            decay = mid(decays) or math.huge,
            value = mid(values) or 0,
        }
        out[rarity].cost = out[rarity].clickPower > 0
            and (out[rarity].decay / out[rarity].clickPower) or math.huge
    end
    _G.__DC_STATS2[key] = out
    return out
end

------------------------------------------------------------------------
--// WINDOW
------------------------------------------------------------------------
local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 460,
    Height = 360,
    Footer = {
        "v1.4 |",
        { Text = isLobby and "Lobby" or "Game", Copyable = true },
        "|",
        { Text = tostring(plr.UserId), Copyable = true },
    },
    CopyableFooter = true,
    FuzzySearch = true,
    SearchValues = true,
    Minimizable = true,
    MinimizeKeybind = Enum.KeyCode.RightBracket,
    MinimizedWidth = 280,
    NotifySide = "Right",
    ShowCustomCursor = false,
    SearchKeybind = Enum.KeyCode.F,
    CornerRadius = 4,
})

------------------------------------------------------------------------
--// CONFIG
------------------------------------------------------------------------
local CFG = {
    auto = false,
    dig = true,
    clean = true,
    sell = true,
    display = true,
    polish = true,
    plot = true,
    islands = true,
    islandFirst = true,
    buyGear = true,
    claimFree = true,
    autoMuseum = true,
    autoPedestal = true,
    autoSection = true,
    moveSpeed = 90,
    clicksPerSec = 35,
    scan = true,
    scanPoints = 4,
    scanDwell = 0.45,
    scanUntil = 6,
    scanEvery = 25,
    scanRarity = 3,
    rarityAuto = true,
    digSeconds = 25,
    giveUpAfter = 4,
    sellAt = 0.3,
    gearEvery = 30,
    swapExhibits = true,
    swapMargin = 1.2,
}

local ST = {
    note = "idle", phase = "-", gold = 0, level = 0, xp = 0,
    dug = 0, cleaned = 0, sold = 0, digs = 0, nodes = 0,
    power = 1, cps = 8, cap = "-", lastRarity = "-",
    goldRate = 0, lastGold = 0, lastGoldAt = 0,
    tutorial = -1, busy = false, nextGearAt = 0,
    gear = "-", island = "-",
}

------------------------------------------------------------------------
--// TABS
------------------------------------------------------------------------
local MainTab = Window:CreateTab({ Name = "Main" })
local PlayerTab = Window:CreateTab({ Name = "Player" })
local FarmTab = Window:CreateTab({ Name = "Farm" })
local ShopTab = Window:CreateTab({ Name = "Shop" })
local SettingsTab = Window:CreateTab({ Name = "Settings" })

------------------------------------------------------------------------
--// MAIN > AUTOMATION
------------------------------------------------------------------------
local AutoSection = MainTab:CreateSection("Automation")
local CoreGroup = AutoSection
local ExtraGroup = AutoSection

CoreGroup:CreateToggle({ Name = "Auto Farm", CurrentValue = false,
    Callback = function(s) CFG.auto = s; ST.note = s and "running" or "stopped"
        notify(s and "Auto Farm Enabled" or "Auto Farm Disabled") end })
CoreGroup:CreateKeybind({ Name = "Auto Farm Key", CurrentKeybind = "F" })

CoreGroup:CreateToggle({ Name = "Auto Dig", CurrentValue = true, Callback = function(s) CFG.dig = s end })
CoreGroup:CreateToggle({ Name = "Auto Clean", CurrentValue = true, Callback = function(s) CFG.clean = s end })
CoreGroup:CreateToggle({ Name = "Auto Sell", CurrentValue = true, Callback = function(s) CFG.sell = s end })
CoreGroup:CreateToggle({ Name = "Auto Display", CurrentValue = true, Callback = function(s) CFG.display = s end })
CoreGroup:CreateToggle({ Name = "Auto Polish", CurrentValue = true, Callback = function(s) CFG.polish = s end })
CoreGroup:CreateToggle({ Name = "Auto Expand Plot", CurrentValue = true, Callback = function(s) CFG.plot = s end })
CoreGroup:CreateToggle({ Name = "Auto Unlock Islands", CurrentValue = true, Callback = function(s) CFG.islands = s end })
CoreGroup:CreateToggle({ Name = "Auto Buy Gear", CurrentValue = true, Callback = function(s) CFG.buyGear = s end })
CoreGroup:CreateToggle({ Name = "Auto Claim Rewards", CurrentValue = true, Callback = function(s) CFG.claimFree = s end })

CoreGroup:CreateSlider({ Name = "Clicks/sec", Range = {4, 50}, Increment = 1, CurrentValue = 35,
    Callback = function(v) CFG.clicksPerSec = math.floor(v) end })
CoreGroup:CreateSlider({ Name = "Max Dig Time", Range = {4, 45}, Increment = 1, CurrentValue = 25,
    Callback = function(v) CFG.digSeconds = math.floor(v) end })

ExtraGroup:CreateToggle({ Name = "Scan Field", CurrentValue = true, Callback = function(s) CFG.scan = s end })
ExtraGroup:CreateToggle({ Name = "Match Shovel Power", CurrentValue = true, Callback = function(s) CFG.rarityAuto = s end })
ExtraGroup:CreateToggle({ Name = "Swap Exhibits", CurrentValue = true, Callback = function(s) CFG.swapExhibits = s end })
ExtraGroup:CreateToggle({ Name = "Island Before Gear", CurrentValue = true, Callback = function(s) CFG.islandFirst = s end })
ExtraGroup:CreateSlider({ Name = "Sell At %", Range = {10, 100}, Increment = 1, CurrentValue = 30,
    Callback = function(v) CFG.sellAt = v / 100 end })
ExtraGroup:CreateSlider({ Name = "Swap Margin %", Range = {5, 200}, Increment = 1, CurrentValue = 20,
    Callback = function(v) CFG.swapMargin = 1 + v / 100 end })
ExtraGroup:CreateButton({ Name = "Unstuck", Callback = function()
    CFG.auto = false
    local _, hrp, hum = char()
    if hrp then hrp.Anchored = false end
    if hum then hum.PlatformStand = false end
    ST.busy = false; ST.note = "unstuck"
    notify("Unstuck! Auto off.", "Info")
end })

------------------------------------------------------------------------
--// MAIN > DISCORD
------------------------------------------------------------------------
local DiscordSection = MainTab:CreateSection("Discord")
DiscordSection:CreateButton({ Name = "Join Discord For Dupe", Callback = function()
    setclipboard("https://discord.gg/ivory")
    notify("Discord link copied to clipboard!", "Success")
end })

------------------------------------------------------------------------
--// MAIN > CONFIG
------------------------------------------------------------------------
local ConfigSection = MainTab:CreateSection("Config")

ConfigSection:CreateToggle({ Name = "Auto Save Settings", CurrentValue = true,
    Callback = function(s) _G.IvoryAutoSave = s end })

ConfigSection:CreateLabel("Ivory Hub v1.4")
ConfigSection:CreateLabel("Game: Dig & Clean")
ConfigSection:CreateLabel("PlaceId: " .. tostring(PlaceId))

------------------------------------------------------------------------
--// PLAYER > MOVEMENT
------------------------------------------------------------------------
local MovementSection = PlayerTab:CreateSection("Movement")

MovementSection:CreateToggle({ Name = "Speed Hack", CurrentValue = false,
    Callback = function(s) _G.IvorySpeedHack = s end })
MovementSection:CreateSlider({ Name = "Walk Speed", Range = {16, 500}, Increment = 1, CurrentValue = 16,
    Callback = function(v) _G.IvorySpeedValue = v end })
MovementSection:CreateButton({ Name = "Reset Speed", Callback = function()
    pcall(function() plr.Character.Humanoid.WalkSpeed = 16 end)
    _G.IvorySpeedHack = false; notify("Speed Reset", "Success")
end })

MovementSection:CreateToggle({ Name = "Jump Hack", CurrentValue = false,
    Callback = function(s) _G.IvoryJumpHack = s end })
MovementSection:CreateSlider({ Name = "Jump Power", Range = {50, 500}, Increment = 1, CurrentValue = 50,
    Callback = function(v) _G.IvoryJumpValue = v end })
MovementSection:CreateButton({ Name = "Reset Jump", Callback = function()
    pcall(function() plr.Character.Humanoid.JumpPower = 50 end)
    _G.IvoryJumpHack = false; notify("Jump Reset", "Success")
end })

------------------------------------------------------------------------
--// PLAYER > VISUALS
------------------------------------------------------------------------
local VisualsSection = PlayerTab:CreateSection("Visuals")

VisualsSection:CreateColorPicker({ Name = "ESP Color", Color = Color3.fromRGB(255, 0, 0),
    Callback = function(v) _G.IvoryESPColor = v end })
VisualsSection:CreateToggle({ Name = "Player ESP", CurrentValue = false,
    Callback = function(s) _G.IvoryPlayerESP = s end })
VisualsSection:CreateSlider({ Name = "ESP Range", Range = {50, 1000}, Increment = 1, CurrentValue = 200,
    Callback = function(v) _G.IvoryESPRange = v end })

------------------------------------------------------------------------
--// FARM > STATUS
------------------------------------------------------------------------
local StatusSection = FarmTab:CreateSection("Status")

local StatusLabel = StatusSection:CreateLabel("Loading...")
StatusSection:CreateButton({ Name = "Refresh Status", Callback = function()
    local d = data()
    if d then
        ST.gold = d.Gold or 0; ST.level = d.Level or 0
        ST.dug = d.ItemsDug or 0; ST.cleaned = d.ItemsCleaned or 0
    end
end })

------------------------------------------------------------------------
--// FARM > DIGGING
------------------------------------------------------------------------
local DiggingSection = FarmTab:CreateSection("Digging")

DiggingSection:CreateButton({ Name = "Begin Dig", Callback = function()
    local ctrl = digController()
    if ctrl then pcall(function() ctrl:attemptDig() end); notify("Dig started!", "Success")
    else notify("No dig controller found", "Error") end
end })
DiggingSection:CreateButton({ Name = "Sweep Area", Callback = function()
    local zone, _ = nearestTagged("DigZone", islandFolder())
    if zone then
        local ok, pivot = pcall(function() return zone:GetPivot() end)
        if ok then hop(pivot.Position + Vector3.new(0, 5, 0)) end
        notify("Sweeping...", "Info")
    else notify("No dig zone found", "Error") end
end })

------------------------------------------------------------------------
--// FARM > MUSEUM
------------------------------------------------------------------------
local function plotNumber()
    if _G.__DC_PLOT then return _G.__DC_PLOT end
    local ok, num = invoke("MiscNetwork", "MiscFunctions", "RequestPlotNumber")
    if ok and num then _G.__DC_PLOT = num end
    return _G.__DC_PLOT
end

local function allPedestals(plotNum)
    local plot = Workspace:FindFirstChild("Plots")
    plot = plot and plot:FindFirstChild("Plot_" .. tostring(plotNum))
    local inner = plot and plot:FindFirstChild("Plot")
    if not inner then return {} end
    local out = {}
    for _, d in ipairs(inner:GetDescendants()) do
        if d:IsA("Model") and d.Name:sub(1, 9) == "Pedestal_" and d:GetAttribute("Slot") then
            out[#out + 1] = d
        end
    end
    table.sort(out, function(a, b)
        return (a:GetAttribute("Slot") or 0) < (b:GetAttribute("Slot") or 0)
    end)
    return out
end

local function doPlaceBest()
    local plotNum = plotNumber()
    if not plotNum then return false end
    local peds = allPedestals(plotNum)
    if #peds == 0 then return false end

    local free, placed = {}, {}
    for _, p in ipairs(peds) do
        local uid = p:GetAttribute("ItemUid") or ""
        if uid ~= "" then
            placed[uid] = true
        elseif p:GetAttribute("Owned") then
            free[#free + 1] = p:GetAttribute("Slot")
        end
    end
    table.sort(free)

    local candidates = {}
    for _, entry in ipairs(inventoryList()) do
        if not entry.dirty and not placed[entry.uid] then
            entry.__value = valueOf(entry)
            candidates[#candidates + 1] = entry
        end
    end
    if #candidates == 0 then return false end
    table.sort(candidates, function(a, b) return (a.__value or 0) > (b.__value or 0) end)

    local anchorPos
    for _, p in ipairs(peds) do
        local okPivot, pivot = pcall(function() return p:GetPivot() end)
        if okPivot then anchorPos = pivot.Position break end
    end
    if anchorPos then hop(anchorPos + Vector3.new(0, 4, 6), 0.6) end

    local placedCount = 0
    local nextCandidate = 1
    for _, slot in ipairs(free) do
        local entry = candidates[nextCandidate]
        if not entry then break end
        local okPlace, done = invoke("PedestalNetwork", "PedestalFunctions", "placeItem", slot, entry.uid)
        if okPlace and done == true then
            placedCount = placedCount + 1
            task.wait(0.35)
        end
        nextCandidate = nextCandidate + 1
    end

    local swaps = 0
    if #free == 0 then
        local used = {}
        for _ = 1, 8 do
            local worstSlot, worstValue
            for _, p in ipairs(peds) do
                local uid = p:GetAttribute("ItemUid") or ""
                local slot = p:GetAttribute("Slot")
                if uid ~= "" and not used[slot] then
                    local v = valueOf({
                        id = p:GetAttribute("ItemId"),
                        kg = p:GetAttribute("Kg"),
                        condition = p:GetAttribute("Condition"),
                    })
                    if not worstValue or v < worstValue then worstSlot, worstValue = slot, v end
                end
            end
            local top = candidates[nextCandidate]
            if not worstSlot or not top then break end
            if (top.__value or 0) <= (worstValue or 0) * CFG.swapMargin then break end

            local evictedUid
            for _, p in ipairs(peds) do
                if p:GetAttribute("Slot") == worstSlot then evictedUid = p:GetAttribute("ItemUid") end
            end
            local okPick = invoke("PedestalNetwork", "PedestalFunctions", "pickupItem", worstSlot)
            if not okPick then break end
            task.wait(0.35)
            local okSwap, done = invoke("PedestalNetwork", "PedestalFunctions",
                "placeItem", worstSlot, top.uid)
            if not (okSwap and done == true) and evictedUid then
                invoke("PedestalNetwork", "PedestalFunctions", "placeItem", worstSlot, evictedUid)
            end
            if okSwap and done == true then
                swaps = swaps + 1
                used[worstSlot] = true
            else
                break
            end
            nextCandidate = nextCandidate + 1
            task.wait(0.3)
        end
    end

    if placedCount > 0 then ST.note = "placed " .. placedCount .. " items" end
    return placedCount > 0 or swaps > 0
end

local MuseumSection = FarmTab:CreateSection("Museum")

MuseumSection:CreateToggle({ Name = "Auto Place Best Item", CurrentValue = true,
    Callback = function(s) CFG.autoMuseum = s end })
MuseumSection:CreateToggle({ Name = "Auto Buy Pedestal", CurrentValue = true,
    Callback = function(s) CFG.autoPedestal = s end })
MuseumSection:CreateToggle({ Name = "Auto Unlock Section", CurrentValue = true,
    Callback = function(s) CFG.autoSection = s end })

MuseumSection:CreateButton({ Name = "Place Best Item", Callback = function()
    local ok, result = pcall(doPlaceBest)
    if not ok then notify("Error: " .. tostring(result), "Error") return end
    if result then notify("Placed/swapped items!", "Success")
    else notify("No items to place", "Info") end
end })

MuseumSection:CreateButton({ Name = "Sell All Inventory", Callback = function()
    local where = npcNamed("SellerNPC")
    if where then hop(where + Vector3.new(0, 3, 4), 0.8) end
    local ok, earned = invoke("SellNetwork", "SellFunctions", "sellInventory")
    if ok and tonumber(earned) then notify("Sold for " .. math.floor(tonumber(earned)), "Success")
    else notify("Sell failed", "Error") end
end })

MuseumSection:CreateButton({ Name = "Buy Pedestal", Callback = function()
    doBuyPedestal()
    notify("Pedestal purchase attempted", "Success")
end })

MuseumSection:CreateButton({ Name = "Unlock Section", Callback = function()
    doUnlockSection()
    notify("Section unlock attempted", "Success")
end })

local PolishSection = FarmTab:CreateSection("Polisher")

PolishSection:CreateButton({ Name = "Start Polish", Callback = function()
    invoke("PolisherNetwork", "PolisherFunctions", "startPolish", 1)
    notify("Polish started!", "Success")
end })
PolishSection:CreateButton({ Name = "Collect Polish", Callback = function()
    invoke("PolisherNetwork", "PolisherFunctions", "collectPolish", 1)
    notify("Polish collected!", "Success")
end })
PolishSection:CreateButton({ Name = "Upgrade Polisher", Callback = function()
    invoke("PolisherNetwork", "PolisherFunctions", "upgradePolisher", 1)
    notify("Polisher upgrade attempted", "Success")
end })

------------------------------------------------------------------------
--// FARM > ISLANDS
------------------------------------------------------------------------
local IslandSection = FarmTab:CreateSection("Islands")

IslandSection:CreateDropdown({ Name = "Target Island",
    Options = {"starterIsland", "island2", "island3", "island4", "island5"},
    CurrentOption = "starterIsland",
    Callback = function(v) _G.IvoryTargetIsland = v end })

IslandSection:CreateButton({ Name = "Travel", Callback = function()
    local target = _G.IvoryTargetIsland or "starterIsland"
    local ok, res = invoke("TravelNetwork", "TravelFunctions", "travel", target)
    notify("Travel " .. target .. ": " .. tostring(res), ok and "Success" or "Error")
end })

IslandSection:CreateButton({ Name = "Unlock Next Island", Callback = function()
    local d = data()
    if not d then return end
    local unlocked = {}
    for _, id in ipairs(d.UnlockedIslands or {}) do unlocked[id] = true end
    for _, id in ipairs(CfgIslands.ISLAND_ORDER or {}) do
        local entry = (CfgIslands.Islands or {})[id]
        if entry and not unlocked[id] then
            local ok, res = invoke("TravelNetwork", "TravelFunctions", "travel", id)
            notify("Unlock " .. id .. ": " .. tostring(res), ok and "Success" or "Error")
            return
        end
    end
    notify("All islands unlocked!", "Success")
end })

IslandSection:CreateLabel("starterIsland | Free | 1x Luck")
IslandSection:CreateLabel("island2 | $1.1M | 2x Luck")
IslandSection:CreateLabel("island3 | $32M | 4x Luck")
IslandSection:CreateLabel("island4 | $500M | 8x Luck")
IslandSection:CreateLabel("island5 | $20B | 16x Luck")

------------------------------------------------------------------------
--// SHOP > SHOVELS
------------------------------------------------------------------------
local ShovelsSection = ShopTab:CreateSection("Shovels")

ShovelsSection:CreateButton({ Name = "Buy Best Shovel", Callback = function()
    local where = npcNamed("GearNPC")
    if where then hop(where + Vector3.new(0, 3, 4), 0.8) end
    local d = data()
    if not d then return end
    local list = CfgShovels.Shovels or {}
    local order = CfgShovels.SHOVEL_TIER_ORDER or {}
    local ownedSet = {}
    for _, id in ipairs(d.OwnedShovels or {}) do ownedSet[id] = true end
    local islandSet = {}
    for _, id in ipairs(d.UnlockedIslands or {}) do islandSet[id] = true end
    for _, id in ipairs(order) do
        local entry = list[id]
        if entry and not ownedSet[id] then
            local cost = tonumber(entry.cost) or math.huge
            if cost <= (d.Gold or 0) and islandSet[entry.islandId] then
                invoke("ShopNetwork", "ShopFunctions", "buyGear", "shovel", id)
                invoke("ShopNetwork", "ShopFunctions", "equipGear", "shovel", id)
                notify("Bought " .. id, "Success")
                return
            end
        end
    end
    notify("No affordable shovel found", "Info")
end })

ShovelsSection:CreateButton({ Name = "Equip Best Shovel", Callback = function()
    local d = data()
    if not d then return end
    local list = CfgShovels.Shovels or {}
    local order = CfgShovels.SHOVEL_TIER_ORDER or {}
    local best, bestRank = nil, -1
    for index, id in ipairs(order) do
        local entry = list[id]
        if entry then
            local rank = tonumber(entry.power) or index
            local owned = false
            for _, oid in ipairs(d.OwnedShovels or {}) do if oid == id then owned = true end end
            if owned and rank > bestRank then best, bestRank = id, rank end
        end
    end
    if best then
        invoke("ShopNetwork", "ShopFunctions", "equipGear", "shovel", best)
        notify("Equipped " .. best, "Success")
    end
end })

------------------------------------------------------------------------
--// SHOP > DETECTORS
------------------------------------------------------------------------
local DetectorsSection = ShopTab:CreateSection("Detectors")

DetectorsSection:CreateButton({ Name = "Buy Best Detector", Callback = function()
    local where = npcNamed("GearNPC")
    if where then hop(where + Vector3.new(0, 3, 4), 0.8) end
    local d = data()
    if not d then return end
    local list = CfgDetectors.Detectors or {}
    local order = CfgDetectors.DETECTOR_TIER_ORDER or {}
    local ownedSet = {}
    for _, id in ipairs(d.OwnedDetectors or {}) do ownedSet[id] = true end
    local islandSet = {}
    for _, id in ipairs(d.UnlockedIslands or {}) do islandSet[id] = true end
    for _, id in ipairs(order) do
        local entry = list[id]
        if entry and not ownedSet[id] then
            local cost = tonumber(entry.cost) or math.huge
            if cost <= (d.Gold or 0) and islandSet[entry.islandId] then
                invoke("ShopNetwork", "ShopFunctions", "buyGear", "detector", id)
                invoke("ShopNetwork", "ShopFunctions", "equipGear", "detector", id)
                notify("Bought " .. id, "Success")
                return
            end
        end
    end
    notify("No affordable detector found", "Info")
end })

DetectorsSection:CreateButton({ Name = "Equip Best Detector", Callback = function()
    local d = data()
    if not d then return end
    local list = CfgDetectors.Detectors or {}
    local order = CfgDetectors.DETECTOR_TIER_ORDER or {}
    local best, bestRank = nil, -1
    for index, id in ipairs(order) do
        local entry = list[id]
        if entry then
            local rank = tonumber(entry.range) or index
            local owned = false
            for _, oid in ipairs(d.OwnedDetectors or {}) do if oid == id then owned = true end end
            if owned and rank > bestRank then best, bestRank = id, rank end
        end
    end
    if best then
        invoke("ShopNetwork", "ShopFunctions", "equipGear", "detector", best)
        notify("Equipped " .. best, "Success")
    end
end })

------------------------------------------------------------------------
--// SHOP > SPRAYS
------------------------------------------------------------------------
local SpraysSection = ShopTab:CreateSection("Sprays")

SpraysSection:CreateButton({ Name = "Buy Best Spray", Callback = function()
    local where = npcNamed("GearNPC")
    if where then hop(where + Vector3.new(0, 3, 4), 0.8) end
    local d = data()
    if not d then return end
    local list = CfgSprays.SprayBottles or {}
    local order = CfgSprays.SPRAY_TIER_ORDER or {}
    local ownedSet = {}
    for _, id in ipairs(d.OwnedSprays or {}) do ownedSet[id] = true end
    local islandSet = {}
    for _, id in ipairs(d.UnlockedIslands or {}) do islandSet[id] = true end
    for _, id in ipairs(order) do
        local entry = list[id]
        if entry and not ownedSet[id] then
            local cost = tonumber(entry.cost) or math.huge
            if cost <= (d.Gold or 0) and islandSet[entry.islandId] then
                invoke("ShopNetwork", "ShopFunctions", "buyGear", "spray", id)
                invoke("ShopNetwork", "ShopFunctions", "equipGear", "spray", id)
                notify("Bought " .. id, "Success")
                return
            end
        end
    end
    notify("No affordable spray found", "Info")
end })

SpraysSection:CreateButton({ Name = "Equip Best Spray", Callback = function()
    local d = data()
    if not d then return end
    local list = CfgSprays.SprayBottles or {}
    local order = CfgSprays.SPRAY_TIER_ORDER or {}
    local best, bestRank = nil, -1
    for index, id in ipairs(order) do
        local entry = list[id]
        if entry then
            local rank = tonumber(entry.strength) or index
            local owned = false
            for _, oid in ipairs(d.OwnedSprays or {}) do if oid == id then owned = true end end
            if owned and rank > bestRank then best, bestRank = id, rank end
        end
    end
    if best then
        invoke("ShopNetwork", "ShopFunctions", "equipGear", "spray", best)
        notify("Equipped " .. best, "Success")
    end
end })

------------------------------------------------------------------------
--// SHOP > REWARDS
------------------------------------------------------------------------
local RewardsSection = ShopTab:CreateSection("Rewards")

RewardsSection:CreateButton({ Name = "Redeem All Codes", Callback = function()
    local codes = {"UPDATE3", "UPDATE2", "SECRET10", "Update1"}
    for _, code in ipairs(codes) do
        pcall(function() invoke("CodeNetwork", "CodeFunctions", "redeemCode", code) end)
    end
    notify("Attempted to redeem " .. #codes .. " codes!", "Success")
end })

RewardsSection:CreateButton({ Name = "Claim Offline Earnings", Callback = function()
    invoke("OfflineEarningsNetwork", "OfflineEarningsFunctions", "claimOfflineEarnings")
    notify("Offline earnings claimed!", "Success")
end })

RewardsSection:CreateButton({ Name = "Claim Free Pack", Callback = function()
    fire("ForeverPackNetwork", "ForeverPackEvents", "claimFree")
    notify("Free pack claimed!", "Success")
end })

RewardsSection:CreateButton({ Name = "Claim Group Reward", Callback = function()
    invoke("FreeLuckNetwork", "FreeLuckFunctions", "claimGroupReward")
    notify("Group reward claimed!", "Success")
end })

------------------------------------------------------------------------
--// PLAYER ESP
------------------------------------------------------------------------
task.spawn(function()
    local espObjects = {}
    local function createESP(player)
        if player == plr then return end
        espObjects[player] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Distance = Drawing.new("Text"),
        }
        local e = espObjects[player]
        e.Box.Thickness = 1; e.Box.Filled = false; e.Box.Visible = false
        e.Name.Size = 14; e.Name.Center = true; e.Name.Outline = true; e.Name.Visible = false
        e.Distance.Size = 12; e.Distance.Center = true; e.Distance.Outline = true; e.Distance.Visible = false
    end
    local function removeESP(player)
        if espObjects[player] then
            pcall(function() for _, v in pairs(espObjects[player]) do v:Remove() end end)
            espObjects[player] = nil
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(removeESP)
    RunService.RenderStepped:Connect(function()
        local color = _G.IvoryESPColor or Color3.fromRGB(255, 0, 0)
        local cam = Workspace.CurrentCamera
        for player, esp in pairs(espObjects) do
            pcall(function()
                local c = player.Character
                if c and c:FindFirstChild("HumanoidRootPart") and c:FindFirstChild("Humanoid") then
                    local hrp = c.HumanoidRootPart
                    local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                    if onScreen then
                        local _, localHRP = char()
                        if localHRP and (hrp.Position - localHRP.Position).Magnitude > (_G.IvoryESPRange or 200) then
                            esp.Box.Visible = false; esp.Name.Visible = false; esp.Distance.Visible = false; return
                        end
                        local rootPos = cam:WorldToViewportPoint(hrp.Position)
                        local headPos = cam:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
                        local height = math.abs(rootPos.Y - headPos.Y) * 2
                        local width = height / 2
                        if _G.IvoryPlayerESP then
                            esp.Box.Size = Vector2.new(width, height)
                            esp.Box.Position = Vector2.new(rootPos.X - width/2, rootPos.Y - height/2)
                            esp.Box.Visible = true; esp.Box.Color = color
                            esp.Name.Text = player.DisplayName
                            esp.Name.Position = Vector2.new(pos.X, pos.Y - 20)
                            esp.Name.Visible = true; esp.Name.Color = color
                            if localHRP then
                                esp.Distance.Text = math.floor((hrp.Position - localHRP.Position).Magnitude) .. "m"
                                esp.Distance.Position = Vector2.new(pos.X, pos.Y + height/2 + 5)
                                esp.Distance.Visible = true; esp.Distance.Color = color
                            end
                        else esp.Box.Visible = false; esp.Name.Visible = false; esp.Distance.Visible = false end
                    else esp.Box.Visible = false; esp.Name.Visible = false; esp.Distance.Visible = false end
                else esp.Box.Visible = false; esp.Name.Visible = false; esp.Distance.Visible = false end
            end)
        end
    end)
end)

------------------------------------------------------------------------
--// CORE ACTIONS
------------------------------------------------------------------------
local function doClean()
    local cleaned = 0
    for _, tool in ipairs(backpackTools()) do
        if tool:GetAttribute("dirty") then
            local uid = tool:GetAttribute("inventoryId")
            if uid then
                ST.phase = "clean"
                local ok = invoke("ItemsNetwork", "ItemsFunctions", "beginCleaning", uid)
                if ok then task.wait(0.35); fire("ItemsNetwork", "ItemsEvents", "finishCleaning", uid)
                    cleaned = cleaned + 1; task.wait(0.5) end
            end
        end
    end
    if cleaned > 0 then ST.note = "cleaned " .. cleaned end
    return cleaned > 0
end

local function doSell()
    local where = npcNamed("SellerNPC")
    if not where then ST.note = "no seller npc" return false end
    ST.phase = "sell"
    hop(where + Vector3.new(0, 3, 4), 0.8)
    local ok, earned = invoke("SellNetwork", "SellFunctions", "sellInventory")
    if ok and tonumber(earned) then
        ST.sold = ST.sold + tonumber(earned)
        ST.note = "sold for " .. tostring(math.floor(tonumber(earned)))
        return true
    end
    return false
end

local function doDig()
    local ctrl = digController()
    if not ctrl then ST.note = "no dig controller" return false end

    local zone, _ = nearestTagged("DigZone", islandFolder())
    if zone then
        local _, hrp = char()
        local inside = false
        if zone:IsA("BasePart") and hrp then
            local local_ = zone.CFrame:PointToObjectSpace(hrp.Position)
            inside = math.abs(local_.X) <= zone.Size.X / 2 and math.abs(local_.Z) <= zone.Size.Z / 2
        end
        if not inside then
            ST.phase = "walk to dig area"
            local ok, pivot = pcall(function() return zone:GetPivot() end)
            if ok then hop(pivot.Position + Vector3.new(0, 5, 0)) end
            task.wait(0.6)
        end
    end

    fire("DetectorNetwork", "DetectorEvents", "SetDetectorHeld", true)

    local _, hrp = char()
    if not hrp then return false end
    local best, bestDist
    for _, n in ipairs(nodeList()) do
        if typeof(n.position) == "Vector3" then
            local dist = (n.position - hrp.Position).Magnitude
            if not bestDist or dist < bestDist then best, bestDist = n, dist end
        end
    end
    if not best then
        fire("DetectorNetwork", "DetectorEvents", "SetDetectorHeld", false)
        task.wait(0.3)
        fire("DetectorNetwork", "DetectorEvents", "SetDetectorHeld", true)
        task.wait(1.5)
        for _, n in ipairs(nodeList()) do
            if typeof(n.position) == "Vector3" then
                local dist = (n.position - hrp.Position).Magnitude
                if not bestDist or dist < bestDist then best, bestDist = n, dist end
            end
        end
    end
    if not best then ST.note = "no buried nodes" return false end

    ST.phase = "dig " .. tostring(best.rarity)
    hop(best.position + Vector3.new(0, 3, 0), 0.8)
    task.wait(0.7)

    local finished, started
    if _G.__DC_ENDCONN then pcall(function() _G.__DC_ENDCONN:Disconnect() end) end
    if _G.__DC_STARTCONN then pcall(function() _G.__DC_STARTCONN:Disconnect() end) end
    local okConn, conn = pcall(function()
        return net("ShovelNetwork").ShovelEvents.DigSceneEnd:connect(function(userId, success)
            if userId == plr.UserId then finished = success end
        end)
    end)
    if okConn then _G.__DC_ENDCONN = conn end
    local okStart, startConn = pcall(function()
        return net("ShovelNetwork").ShovelEvents.DigSceneStart:connect(function(userId)
            if userId == plr.UserId then started = true end
        end)
    end)
    if okStart then _G.__DC_STARTCONN = startConn end

    fire("ShovelNetwork", "ShovelEvents", "SetShovelEquipped", true)
    pcall(function() ctrl:attemptDig() end)
    task.wait(0.4)

    local interval = 1 / math.clamp(CFG.clicksPerSec, 1, 40)
    local startDeadline = os.clock() + 1.6
    while not started and finished == nil and os.clock() < startDeadline do
        pcall(function() ctrl:onDigInput() end)
        task.wait(interval)
    end
    if not started and finished == nil then
        if okConn then pcall(function() conn:Disconnect() end) end
        if okStart then pcall(function() startConn:Disconnect() end) end
        forgetNode(best.id)
        ST.note = "stale node"; return false
    end

    local deadline = os.clock() + math.clamp(CFG.digSeconds * 2.5 + 3, 6, CfgDig.DIG_SESSION_TIMEOUT or 45)
    local bestProgress, bestAt = 0, os.clock()
    local firstProgress, firstAt, lastProgress, lastAt

    local progConn
    if _G.__DC_PROGCONN then pcall(function() _G.__DC_PROGCONN:Disconnect() end) end
    local progress = 0
    local okProg, pc = pcall(function()
        return net("ShovelNetwork").ShovelEvents.DigSceneProgress:connect(function(userId, value)
            if userId == plr.UserId then progress = value or 0 end
        end)
    end)
    if okProg then progConn = pc _G.__DC_PROGCONN = pc end

    while finished == nil and os.clock() < deadline and CFG.auto do
        pcall(function() ctrl:onDigInput() end)
        task.wait(interval)
        if progress > 0 and progress ~= lastProgress then
            if not firstAt then firstProgress, firstAt = progress, os.clock() end
            lastProgress, lastAt = progress, os.clock()
        end
        if progress > bestProgress + 0.01 then bestProgress, bestAt = progress, os.clock()
        elseif os.clock() - bestAt > CFG.giveUpAfter then break end
    end

    if okConn then pcall(function() conn:Disconnect() end) end
    if okStart then pcall(function() startConn:Disconnect() end) end
    if progConn then pcall(function() pc:Disconnect() end) end

    forgetNode(best.id)

    if finished then
        ST.digs = ST.digs + 1
        ST.note = "dug " .. tostring(best.rarity)
        return true
    end
    ST.note = "dig lost/timed out (" .. tostring(best.rarity) .. ")"
    return false
end

local function doTravel()
    local d = data()
    if not d then return false end
    local unlocked = {}
    for _, id in ipairs(d.UnlockedIslands or {}) do unlocked[id] = true end
    local nextLocked, nextCost
    for _, id in ipairs(CfgIslands.ISLAND_ORDER or {}) do
        local entry = (CfgIslands.Islands or {})[id]
        if entry and not unlocked[id] then
            nextLocked, nextCost = id, tonumber(entry.cost) or math.huge
            break
        end
    end
    if nextLocked and nextCost and (d.Gold or 0) >= nextCost then
        local ok, res = invoke("TravelNetwork", "TravelFunctions", "travel", nextLocked)
        if ok and res ~= "poor" then ST.note = "unlocked " .. nextLocked; return true end
    end
    return false
end

local function claimFree()
    invoke("OfflineEarningsNetwork", "OfflineEarningsFunctions", "claimOfflineEarnings")
    fire("ForeverPackNetwork", "ForeverPackEvents", "claimFree")
end

local function doBuyGear()
    local d = data()
    if not d then return false end

    local gearNPC = npcNamed("GearNPC")
    if not gearNPC then return false end
    local bought = false

    local shovelList = CfgShovels.Shovels or {}
    local shovelOrder = CfgShovels.SHOVEL_TIER_ORDER or {}
    local ownedShovels = {}
    for _, id in ipairs(d.OwnedShovels or {}) do ownedShovels[id] = true end
    local islandSet = {}
    for _, id in ipairs(d.UnlockedIslands or {}) do islandSet[id] = true end
    for _, id in ipairs(shovelOrder) do
        local entry = shovelList[id]
        if entry and not ownedShovels[id] then
            local cost = tonumber(entry.cost) or math.huge
            if cost <= (d.Gold or 0) and islandSet[entry.islandId] then
                hop(gearNPC + Vector3.new(0, 3, 4), 0.6)
                invoke("ShopNetwork", "ShopFunctions", "buyGear", "shovel", id)
                invoke("ShopNetwork", "ShopFunctions", "equipGear", "shovel", id)
                ST.note = "bought " .. id
                bought = true
                break
            end
        end
    end

    local detectorList = CfgDetectors.Detectors or {}
    local detectorOrder = CfgDetectors.DETECTOR_TIER_ORDER or {}
    local ownedDetectors = {}
    for _, id in ipairs(d.OwnedDetectors or {}) do ownedDetectors[id] = true end
    for _, id in ipairs(detectorOrder) do
        local entry = detectorList[id]
        if entry and not ownedDetectors[id] then
            local cost = tonumber(entry.cost) or math.huge
            if cost <= (d.Gold or 0) and islandSet[entry.islandId] then
                hop(gearNPC + Vector3.new(0, 3, 4), 0.6)
                invoke("ShopNetwork", "ShopFunctions", "buyGear", "detector", id)
                invoke("ShopNetwork", "ShopFunctions", "equipGear", "detector", id)
                ST.note = "bought " .. id
                bought = true
                break
            end
        end
    end

    local sprayList = CfgSprays.SprayBottles or {}
    local sprayOrder = CfgSprays.SPRAY_TIER_ORDER or {}
    local ownedSprays = {}
    for _, id in ipairs(d.OwnedSprays or {}) do ownedSprays[id] = true end
    for _, id in ipairs(sprayOrder) do
        local entry = sprayList[id]
        if entry and not ownedSprays[id] then
            local cost = tonumber(entry.cost) or math.huge
            if cost <= (d.Gold or 0) and islandSet[entry.islandId] then
                hop(gearNPC + Vector3.new(0, 3, 4), 0.6)
                invoke("ShopNetwork", "ShopFunctions", "buyGear", "spray", id)
                invoke("ShopNetwork", "ShopFunctions", "equipGear", "spray", id)
                ST.note = "bought " .. id
                bought = true
                break
            end
        end
    end

    return bought
end

local function doBuyPedestal()
    invoke("PedestalNetwork", "PedestalFunctions", "buyPedestal")
end

local function doUnlockSection()
    invoke("PlotSectionNetwork", "PlotSectionFunctions", "unlockSection")
end

------------------------------------------------------------------------
--// MAIN LOOP
------------------------------------------------------------------------
_G.__IVORY_GEN = (_G.__IVORY_GEN or 0) + 1
local GEN = _G.__IVORY_GEN

armNodeListener()

task.spawn(function()
    while GEN == _G.__IVORY_GEN do
        if CFG.auto then
            local ok, err = pcall(function()
                if ST.tutorial >= 0 and ST.tutorial < 11 then
                    ST.phase = "tutorial " .. ST.tutorial
                    ST.note = "finish tutorial first"
                    task.wait(3); return
                end
                closeModals()
                if CFG.clean then doClean() end
                if CFG.sell and backpackFullness() >= CFG.sellAt then doSell(); closeModals() end
                if CFG.autoMuseum then doPlaceBest() end
                if CFG.autoPedestal then doBuyPedestal() end
                if CFG.autoSection then doUnlockSection() end
                if CFG.islands then doTravel() end
                if CFG.buyGear and doBuyGear() then task.wait(1); closeModals() end
                if CFG.dig then doDig() end
            end)
            if not ok then ST.note = tostring(err) end
        end
        task.wait(0.5)
    end
end)

task.spawn(function()
    while GEN == _G.__IVORY_GEN do
        if CFG.auto then
            local d = data()
            if d then
                ST.gold = d.Gold or 0; ST.level = d.Level or 0
                ST.dug = d.ItemsDug or 0; ST.cleaned = d.ItemsCleaned or 0
                ST.tutorial = tutorialStep()
                ST.gear = tostring(d.EquippedShovel) .. " / " .. tostring(d.EquippedSpray) .. " / " .. tostring(d.EquippedDetector)
                local now = os.clock()
                if ST.lastGoldAt > 0 and now > ST.lastGoldAt then
                    local rate = (ST.gold - ST.lastGold) / (now - ST.lastGoldAt)
                    if rate >= 0 then ST.goldRate = rate end
                end
                ST.lastGold, ST.lastGoldAt = ST.gold, now
                ST.island = tostring(d.CurrentIsland)
                local order = CfgItems.RARITY_ORDER or {}
                local idx = 1
                for i, rarity in ipairs(order) do
                    local stats = rarityStats(ST.power)
                    local s = stats[rarity]
                    if s and s.clickPower > 0 then
                        local rate = s.clickPower * ST.cps - s.decay
                        if rate > 0 and DIG_SPAN / rate <= CFG.digSeconds then idx = i end
                    end
                end
                ST.cap = tostring(order[idx] or "?")
                ST.nodes = #nodeList()
            end
        end
        task.wait(6)
    end
end)

task.spawn(function()
    while GEN == _G.__IVORY_GEN do
        if CFG.claimFree then pcall(claimFree) end
        task.wait(120)
    end
end)

task.spawn(function()
    while GEN == _G.__IVORY_GEN do
        pcall(function() StatusLabel:SetText(
            ST.note .. "\nGold: " .. short(ST.gold) .. " (" .. short(ST.goldRate) .. "/s)" ..
            "\nLevel: " .. ST.level .. " | Dug: " .. ST.dug ..
            "\nGear: " .. ST.gear .. "\nIsland: " .. ST.island ..
            "\nCap: " .. ST.cap .. " | Nodes: " .. ST.nodes ..
            "\nBackpack: " .. math.floor(backpackFullness() * 100) .. "%"
        ) end)
        task.wait(1)
    end
end)

------------------------------------------------------------------------
--// MOVEMENT
------------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    pcall(function()
        local _, _, hum = char()
        if hum then
            if _G.IvorySpeedHack and _G.IvorySpeedValue then hum.WalkSpeed = _G.IvorySpeedValue end
            if _G.IvoryJumpHack and _G.IvoryJumpValue then hum.JumpPower = _G.IvoryJumpValue end
        end
    end)
end)

task.spawn(function()
    plr.Idled:Connect(function()
        if CFG.auto then
            local VirtualUser = game:GetService("VirtualUser")
            VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
            VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
        end
    end)
end)

------------------------------------------------------------------------
--// SETTINGS
------------------------------------------------------------------------
local MenuSection = SettingsTab:CreateSection("Menu")
MenuSection:CreateToggle({ Name = "Toggle Menu", CurrentValue = true })
MenuSection:CreateKeybind({ Name = "Menu Keybind", CurrentKeybind = "RightShift" })
MenuSection:CreateToggle({ Name = "Custom Cursor", CurrentValue = false,
    Callback = function(s) Library.ShowCustomCursor = s end })
MenuSection:CreateButton({ Name = "Test Notification", Callback = function()
    Library.Notify({ Title = "Ivory", Content = "Test Notification!", Type = "Success", Duration = 5 }) end })
MenuSection:CreateDropdown({ Name = "Notification Side", Options = {"Left", "Right"}, CurrentOption = "Right",
    Callback = function(v) Library.NotifySide = v end })
MenuSection:CreateSlider({ Name = "Corner Radius", Range = {0, 20}, Increment = 1, CurrentValue = 4,
    Callback = function(v) Library.CornerRadius = v end })
MenuSection:CreateButton({ Name = "Unload Script", Callback = function()
    Library.Notify({ Title = "Ivory", Content = "Unloading...", Type = "Info", Duration = 2 })
    task.wait(0.5)
    for k in pairs(_G) do if string.find(k, "Ivory") then _G[k] = nil end end
    pcall(function() Library.ToggleWindow() end)
end })

------------------------------------------------------------------------
task.spawn(function()
    while _G.__IVORY_GEN == GEN do
        if _G.IvoryAutoSave then pcall(function() SaveManager:SaveConfig() end) end
        task.wait(30)
    end
end)

------------------------------------------------------------------------
Library.Notify({ Title = "Ivory", Content = "Dig & Clean Loaded!", Type = "Success", Duration = 5 })
print("[Ivory] Dig & Clean loaded | PlaceId: " .. tostring(PlaceId) .. " | v1.4")