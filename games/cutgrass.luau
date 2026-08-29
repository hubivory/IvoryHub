--[[
    Cut Grass Adventure - Ivory Hub
    PlaceId: 90086669327265
    
    Features: Auto click, training pads, cut grass, loot, sell,
    cutters, auras, upgrades, rebirth, worlds, free rewards
    
    Anti-Cheat aware: uses MoveTo only, no WalkSpeed writes,
    no honeypot remotes, respects all server checks
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer

local GEN = (_G.__CUTGRASS or 0) + 1
_G.__CUTGRASS = GEN

--------------------------------------------------------------------------------
-- UI Library
--------------------------------------------------------------------------------

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
    return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local CONFIG = {
    auto = false,

    click = true,
    train = true,
    trainSecs = 20,
    trainMinMult = 2,
    trainMinShare = 0.25,

    cut = true,
    loot = true,
    tripSecs = 45,
    cutSecs = 25,
    zoneMode = "Auto",
    zoneTarget = 1,
    probeHoldSecs = 120,

    sell = true,
    cutters = true,
    auras = true,
    upgrades = true,
    rebirth = true,
    worlds = true,
    freebies = true,

    reserveWindow = 90,
}

local STATE = {
    phase = "idle",
    note = "ready",
    strength = 0, money = 0, level = 0, rebirths = 0,
    world = 1, zone = 1, zoneBest = 1, zoneProbe = 0,
    cutter = "-", cutterMult = 0, aura = "-", auraMult = 1,
    pad = "-", padMult = 0, clickAmount = 1,
    bag = 0, bagCap = 0, bagValue = 0,
    strRate = 0, moneyRate = 0,
    cutTotal = 0, lootTotal = 0, sold = 0, earned = 0, spent = 0,
    trips = 0, blocked = 0, homeTrips = 0, probeHold = 0,
    busy = false, halted = false,
}

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

local function short(n)
    n = tonumber(n) or 0
    local units = {
        { 1e33, "Dc" }, { 1e30, "No" }, { 1e27, "Oc" }, { 1e24, "Sp" },
        { 1e21, "Sx" }, { 1e18, "Qi" }, { 1e15, "Qa" }, { 1e12, "T" },
        { 1e9, "B" }, { 1e6, "M" }, { 1e3, "K" },
    }
    for _, u in ipairs(units) do
        if math.abs(n) >= u[1] then return string.format("%.2f%s", n / u[1], u[2]) end
    end
    return string.format("%.0f", n)
end

local function note(text) STATE.note = tostring(text) end

local function char()
    local model = plr.Character
    if not model then return nil, nil, nil end
    return model, model:FindFirstChild("HumanoidRootPart"), model:FindFirstChildOfClass("Humanoid")
end

local function attr(name, default)
    local v = plr:GetAttribute(name)
    if v == nil then return default end
    return v
end

local function waitFor(parent, name, secs)
    if not parent then return nil end
    return parent:WaitForChild(name, secs or 10)
end

--------------------------------------------------------------------------------
-- knit, and the honeypot blacklist
--------------------------------------------------------------------------------

local SERVICES
do
    local index = waitFor(waitFor(ReplicatedStorage, "Packages"), "_Index")
    if index then
        for _, pkg in ipairs(index:GetChildren()) do
            local knit = pkg:FindFirstChild("knit")
            local svc = knit and knit:FindFirstChild("Services")
            if svc then SERVICES = svc break end
        end
    end
end

local HONEYPOT = {
    AddCoins = true, AddCash = true, AddMoney = true, GiveCash = true,
    GiveCoins = true, GiveCurrency = true, GiveMoney = true,
    SetCash = true, SetCoins = true, SetCurrency = true, SetMoney = true,
    UpdateMoney = true, UpdateTokens = true, ClaimMoney = true,
    CollectMoney = true, ClaimAllRewards = true, SellAll = true,
    CollectAllLoot = true, RebirthAll = true, UpgradeAll = true, TrainAll = true,
}

local function remote(service, kind, name)
    if not SERVICES then return nil end
    local s = SERVICES:FindFirstChild(service)
    local folder = s and s:FindFirstChild(kind)
    return folder and folder:FindFirstChild(name) or nil
end

local function fire(service, event, ...)
    if HONEYPOT[event] then
        note("REFUSED honeypot remote " .. event)
        return false
    end
    local re = remote(service, "RE", event)
    if not re then return false end
    local args = table.pack(...)
    local ok = pcall(function() re:FireServer(table.unpack(args, 1, args.n)) end)
    return ok
end

local function call(service, fn, ...)
    local rf = remote(service, "RF", fn)
    if not rf then return nil, "no remote" end
    local args = table.pack(...)
    local done, ok, res = false, false, nil
    task.spawn(function()
        ok, res = pcall(function() return rf:InvokeServer(table.unpack(args, 1, args.n)) end)
        done = true
    end)
    local waited = 0
    while not done and waited < 8 do
        task.wait(0.1)
        waited = waited + 0.1
    end
    if not done then return nil, "timeout" end
    if not ok then return nil, tostring(res) end
    return res
end

--------------------------------------------------------------------------------
-- movement
--------------------------------------------------------------------------------

local function walkTo(pos, timeout, tol)
    tol = tol or 4
    timeout = timeout or 20
    local started = os.clock()
    local stuckSince, lastD = os.clock(), nil
    while os.clock() - started < timeout do
        local _, hrp, hum = char()
        if not hrp or not hum then return false, "no body" end
        local d = (hrp.Position - pos).Magnitude
        if d <= tol then return true end
        if lastD and lastD - d < 0.5 then
            if os.clock() - stuckSince > 3.5 then return false, "stuck" end
        else
            stuckSince, lastD = os.clock(), d
        end
        hum:MoveTo(pos)
        task.wait(0.2)
    end
    return false, "timeout"
end

local function stopWalking()
    local _, hrp, hum = char()
    if hrp and hum then hum:MoveTo(hrp.Position) end
end

--------------------------------------------------------------------------------
-- world geography
--------------------------------------------------------------------------------

local function worldId() return math.floor(tonumber(attr("CurrentWorld", 1)) or 1) end

local function worldFolder()
    local worlds = workspace:FindFirstChild("Worlds")
    return worlds and worlds:FindFirstChild("World_" .. worldId()) or nil
end

local function zonesFolder()
    local zones = workspace:FindFirstChild("Zones")
    return zones and zones:FindFirstChild("W" .. worldId()) or nil
end

local function startLine()
    local w = worldFolder()
    local safe = w and w:FindFirstChild("Safe_Zone_0")
    local part = safe and safe:FindFirstChild("StartLine", true)
    if part and part:IsA("BasePart") then return part end
    return nil
end

local function basePos()
    local w = worldFolder()
    if not w then return nil end
    for _, c in ipairs(w:GetChildren()) do
        if c:IsA("BasePart") and c.Name:match("^Spawn_Point") then return c.Position end
    end
    local safe = w:FindFirstChild("Safe_Zone_0")
    local ok, p = pcall(function() return safe and safe:GetPivot().Position end)
    if ok and p then return p end
    return nil
end

_G.__CUTGRASS_ZPOS = _G.__CUTGRASS_ZPOS or {}

local function zoneModel(i)
    local zf = zonesFolder()
    return zf and zf:FindFirstChild("Zone_" .. i) or nil
end

local function zonePos(i)
    local key = worldId() .. ":" .. i
    local m = zoneModel(i)
    if m then
        local spawn = m:FindFirstChild("SpawnZone")
        local ok, p = pcall(function()
            return (spawn and spawn.Position) or m:GetPivot().Position
        end)
        if ok and p then
            _G.__CUTGRASS_ZPOS[key] = { x = p.X, z = p.Z }
            return p.X, p.Z
        end
    end
    local hit = _G.__CUTGRASS_ZPOS[key]
    if type(hit) == "table" then return hit.x, hit.z end
    local known = {}
    for k, v in pairs(_G.__CUTGRASS_ZPOS) do
        local w, idx = k:match("^(%d+):(%d+)$")
        if tonumber(w) == worldId() and type(v) == "table" then
            known[#known + 1] = { tonumber(idx), v.x, v.z }
        end
    end
    table.sort(known, function(a, b) return a[1] < b[1] end)
    if #known == 0 then return nil, nil end
    local last = known[#known]
    local gap = 100
    if #known >= 2 then
        local prev = known[#known - 1]
        gap = (last[2] - prev[2]) / math.max(1, last[1] - prev[1])
    end
    return last[2] + gap * (i - last[1]), last[3]
end

local function zoneCount()
    local zf = zonesFolder()
    if not zf then return 9 end
    local n = 0
    for _, c in ipairs(zf:GetChildren()) do
        if c.Name:match("^Zone_%d+$") then n = n + 1 end
    end
    return math.max(n, 1)
end

local function grassCounts(i)
    local z = zoneModel(i)
    if not z then return 0, 0 end
    local total, hidden = 0, 0
    for _, line in ipairs(z:GetChildren()) do
        if line.Name == "GrassLine" then
            for _, chunk in ipairs(line:GetChildren()) do
                for _, blade in ipairs(chunk:GetChildren()) do
                    total = total + 1
                    if blade:GetAttribute("GD_LocalGrassHidden") then hidden = hidden + 1 end
                end
            end
        end
    end
    return total, hidden
end

--------------------------------------------------------------------------------
-- the click engine
--------------------------------------------------------------------------------

local function clickOnce() return fire("StrengthService", "ClickRequested") end

--------------------------------------------------------------------------------
-- training pads
--------------------------------------------------------------------------------

local PadConfig
do
    local ok, cfg = pcall(function()
        pcall(function() setthreadidentity(2) end)
        return require(waitFor(waitFor(waitFor(ReplicatedStorage, "Shared"), "Configs"), "TrainingPads"))
    end)
    if ok then PadConfig = cfg end
end

local function bestPad()
    if not PadConfig or not PadConfig.Pads then return nil end
    local w = worldFolder()
    local folder = w and w:FindFirstChild("TrainZones")
    if not folder then return nil end
    local reb = tonumber(attr("RebirthLevel", 0)) or 0
    local best, bestMult = nil, -1
    for _, model in ipairs(folder:GetChildren()) do
        local cfg
        for id, entry in pairs(PadConfig.Pads) do
            if model.Name == id or model.Name == tostring(entry.Id) then cfg = entry break end
        end
        if not cfg then
            local n = model.Name:match("TrainZone_(%d+)$")
            if n then cfg = PadConfig.Pads["Training_" .. n] end
        end
        if cfg and not cfg.GamepassId and not cfg.ShowRobux then
            local mult = tonumber(cfg.Multiplier) or 0
            local req = tonumber(cfg.RequiredRebirths) or 0
            if reb >= req and mult > bestMult then
                local part = model:FindFirstChild("Grass_Zone") or model:FindFirstChild("Hitbox")
                    or model:FindFirstChild("Pad") or model:FindFirstChild("Area")
                local ok, pos = pcall(function()
                    return (part and part.Position) or model:GetPivot().Position
                end)
                if ok and pos then
                    best, bestMult = { model = model, cfg = cfg, pos = pos, mult = mult }, mult
                end
            end
        end
    end
    return best
end

local function trainPass(secs)
    if secs <= 0 then return end
    local pad = bestPad()
    if not pad then
        note("no free training pad in reach")
        return
    end
    STATE.pad, STATE.padMult = tostring(pad.cfg.DisplayName or pad.cfg.Id), pad.mult

    local padWorth = 1.83 * pad.mult
    local clickWorth = 11.66 * math.max(1, STATE.clickAmount or 1)
    if pad.mult < CONFIG.trainMinMult
        or (CONFIG.click and padWorth < clickWorth * CONFIG.trainMinShare) then
        STATE.phase = "clicking, pad not worth the walk"
        return
    end
    STATE.phase = "training"
    local _, hrp = char()
    local base = basePos()
    if hrp and base and (hrp.Position - pad.pos).Magnitude > 150 then
        walkTo(base, 90, 10)
    end
    local ok, why = walkTo(pad.pos, 40, 5)
    if not ok then
        note("pad walk: " .. tostring(why))
        return
    end
    stopWalking()
    local until_ = os.clock() + secs
    while os.clock() < until_ and CONFIG.auto and CONFIG.train and GEN == _G.__CUTGRASS and not STATE.halted do
        task.wait(0.25)
    end
end

--------------------------------------------------------------------------------
-- loot
--------------------------------------------------------------------------------

local sellPass

local function bagState()
    local st = call("DataService", "GetBackpackSlotsState")
    if type(st) ~= "table" then return nil end
    STATE.bag = tonumber(st.BackpackLoad) or tonumber(st.Count) or 0
    STATE.bagCap = tonumber(st.Capacity) or 0
    return st
end

local function homePass()
    if STATE.bagCap > 0 and STATE.bag <= 0 then return true end
    local base = basePos()
    if not base then
        note("no spawn point found for world " .. worldId())
        return false
    end
    STATE.phase = "going home"
    local ok = walkTo(base, 90, 8)
    if not ok then
        note("could not reach base to empty the bag")
        return false
    end
    stopWalking()
    task.wait(0.4)
    local res = call("LootInventoryService", "ResetBackpackLoadAtBase")
    task.wait(0.4)
    bagState()
    if res == true or STATE.bag <= 0 then
        STATE.homeTrips = (STATE.homeTrips or 0) + 1
        return true
    end
    note("base refused the backpack reset")
    return false
end

local lootStrikes = setmetatable({}, { __mode = "k" })

local function lootCandidates()
    local out = {}
    local _, hrp = char()
    if not hrp then return out end
    local zf = zonesFolder()
    if not zf then return out end
    local now = os.time()
    for _, zone in ipairs(zf:GetChildren()) do
        local spawn = zone:FindFirstChild("SpawnZone")
        if spawn then
            for _, model in ipairs(spawn:GetChildren()) do
                local price = tonumber(model:GetAttribute("LootSellPrice"))
                local struck = lootStrikes[model]
                if struck and struck > os.clock() then price = nil end
                if price then
                    local expires = tonumber(model:GetAttribute("LootExpiresAt")) or (now + 60)
                    local ok, pos = pcall(function() return model:GetPivot().Position end)
                    if ok and pos then
                        local dist = (pos - hrp.Position).Magnitude
                        if expires - now > dist / 20 + 1.5 then
                            out[#out + 1] = {
                                model = model, pos = pos, price = price, dist = dist,
                                rarity = tostring(model:GetAttribute("LootRarity") or "?"),
                            }
                        end
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b)
        if a.price ~= b.price then return a.price > b.price end
        return a.dist < b.dist
    end)
    return out
end

local function grabLoot(entry)
    local budget = math.clamp(entry.dist / 10 + 5, 8, 75)
    local ok = walkTo(entry.pos, budget, 3.2)
    if not ok then
        lootStrikes[entry.model] = os.clock() + 25
        return false
    end
    stopWalking()
    task.wait(0.25)
    local prompt
    for _, d in ipairs(entry.model:GetDescendants()) do
        if d:IsA("ProximityPrompt") then prompt = d break end
    end
    if not prompt then return false end
    local before = STATE.bag
    pcall(function() fireproximityprompt(prompt) end)
    task.wait(0.55)
    bagState()
    if STATE.bag > before then
        STATE.lootTotal = STATE.lootTotal + 1
        return true
    end
    lootStrikes[entry.model] = os.clock() + 15
    return false
end

--------------------------------------------------------------------------------
-- the cutting trip
--------------------------------------------------------------------------------

local attackRemote

local function attackOnce()
    if not attackRemote then attackRemote = remote("AttackService", "RE", "AttackRequested") end
    if not attackRemote then return false end
    local ok = pcall(function() attackRemote:FireServer() end)
    return ok
end

local cutSinceMark = 0
do
    local re = remote("AttackService", "RE", "AttackPerformed")
    if re then
        re.OnClientEvent:Connect(function(accepted, count)
            if accepted then
                local n = tonumber(count) or 0
                cutSinceMark = cutSinceMark + n
                STATE.cutTotal = STATE.cutTotal + n
            end
        end)
    end
end

local function targetZone()
    if CONFIG.zoneMode == "Manual" then
        return math.clamp(math.floor(CONFIG.zoneTarget), 1, zoneCount())
    end
    local z = math.clamp(STATE.zoneBest, 1, zoneCount())
    if os.clock() < (STATE.probeHold or 0) then return z end
    return math.min(z + 1, zoneCount())
end

local function cutPass()
    local zone = targetZone()
    STATE.zone = zone
    local goal, lane = zonePos(zone)
    if not goal then
        note("zone " .. zone .. " position unknown yet")
        return
    end
    local line = startLine()
    lane = lane or (line and line.Position.Z) or 1

    STATE.phase = "cutting"
    STATE.trips = STATE.trips + 1
    local probing = (CONFIG.zoneMode == "Auto") and zone > STATE.zoneBest

    local _, hrp = char()
    if not hrp then return end

    if math.abs(hrp.Position.Z - lane) > 12 then
        STATE.phase = "to lane"
        walkTo(Vector3.new(hrp.Position.X, hrp.Position.Y, lane), 25, 6)
        STATE.phase = "cutting"
    end

    cutSinceMark = 0
    local lastX = select(2, char()) and select(2, char()).Position.X or 0
    local noProgress = 0

    local deadline = os.clock() + CONFIG.cutSecs
    local nextAttack = 0
    while os.clock() < deadline and CONFIG.auto and CONFIG.cut and GEN == _G.__CUTGRASS and not STATE.halted do
        local _, root, hum = char()
        if not root or not hum then break end

        if os.clock() >= nextAttack then
            attackOnce()
            nextAttack = os.clock() + 0.52
        end

        hum:MoveTo(Vector3.new(goal, root.Position.Y, lane))

        if root.Position.X >= goal - 6 then
            break
        end

        if root.Position.X - lastX < 0.4 then
            noProgress = noProgress + 1
        else
            noProgress = 0
            lastX = root.Position.X
        end

        if noProgress > 20 then
            if cutSinceMark > 0 then
                noProgress = 0
                cutSinceMark = 0
            else
                STATE.blocked = STATE.blocked + 1
                break
            end
        end
        task.wait(0.5)
    end

    stopWalking()
    local _, endPos = char()
    local reached = endPos and endPos.Position.X >= goal - 10

    if CONFIG.zoneMode == "Auto" then
        if reached then
            if zone > STATE.zoneBest then
                STATE.zoneBest = zone
                note("zone " .. zone .. " opened - frontier moved")
            end
            STATE.probeHold = 0
        elseif probing then
            STATE.probeHold = os.clock() + CONFIG.probeHoldSecs
            note("zone " .. zone .. " is beyond this cutter - farming " .. STATE.zoneBest)
        end
    end
end

local function lootPass()
    if STATE.bagCap > 0 and STATE.bag >= STATE.bagCap then
        STATE.phase = "bag full"
        return
    end
    local cands = lootCandidates()
    local best
    for _, c in ipairs(cands) do
        local zi = tonumber(c.model:GetAttribute("LootZoneIndex")) or 1
        if zi <= STATE.zoneBest then
            local score = c.price / (1 + c.dist / 40)
            if not best or score > best.score then
                best = { entry = c, score = score }
            end
        end
    end
    if not best then
        STATE.phase = "no loot in reach"
        return
    end
    STATE.phase = "looting"
    grabLoot(best.entry)
end

--------------------------------------------------------------------------------
-- selling
--------------------------------------------------------------------------------

function sellPass()
    local st = call("DataService", "GetBackpackLootSellState")
    if type(st) ~= "table" then return end
    STATE.bagValue = tonumber(st.TotalSellPrice) or 0
    local count = tonumber(st.Count) or 0
    if count <= 0 then return end
    local res = call("DataService", "SellAllBackpackLoot")
    if type(res) == "table" and res.Success then
        STATE.sold = STATE.sold + (tonumber(res.SoldCount) or 0)
        STATE.earned = STATE.earned + (tonumber(res.Earned) or 0)
        note("sold " .. tostring(res.SoldCount) .. " for $" .. short(res.Earned))
    end
    bagState()
end

--------------------------------------------------------------------------------
-- spending
--------------------------------------------------------------------------------

local reserveTarget = 0

local function spendable(cost)
    local money = tonumber(attr("MoneyRaw", 0)) or 0
    if cost > money then return false end
    if reserveTarget <= 0 then return true end
    if cost <= money * 0.02 then return true end
    local rate = math.max(0, STATE.moneyRate)
    local reachable = reserveTarget <= money + rate * CONFIG.reserveWindow
    if not reachable then return true end
    return money - cost >= reserveTarget
end

local function cutterPass()
    local st = call("CuttersShopService", "GetShopState")
    if type(st) ~= "table" then return end
    local cat = st.CuttersData or call("CuttersShopService", "GetCatalog")
    if type(cat) ~= "table" then return end
    local owned = st.OwnedCutters or {}
    local current = tostring(st.CurrentCutter or "")
    local curMult = 0
    for name, c in pairs(cat) do
        if name == current then curMult = tonumber(c.DamageMult) or 0 end
    end
    STATE.cutter, STATE.cutterMult = current, curMult

    local world = worldId()
    local money = tonumber(attr("MoneyRaw", 0)) or 0

    local bestOwned, bestOwnedMult = nil, curMult
    local buy, buyCost, buyMult = nil, 0, curMult
    local saveFor, saveCost = nil, math.huge

    for name, c in pairs(cat) do
        if type(c) == "table" then
            local mult = tonumber(c.DamageMult) or 0
            local price = tonumber(c.Price) or 0
            local reqWorld = tonumber(c.RequiredWorld) or 1
            if owned[name] and mult > bestOwnedMult then
                bestOwned, bestOwnedMult = name, mult
            end
            if not owned[name] and mult > curMult and price > 0 and world >= reqWorld then
                if price <= money then
                    if mult > buyMult then buy, buyCost, buyMult = name, price, mult end
                elseif price < saveCost then
                    saveFor, saveCost = name, price
                end
            end
        end
    end

    if bestOwned then
        call("CuttersShopService", "EquipCutter", bestOwned)
        note("equipped owned " .. bestOwned)
        return
    end

    if buy then
        local res = call("CuttersShopService", "BuyCutter", buy)
        if res then
            STATE.spent = STATE.spent + buyCost
            note("bought cutter " .. buy .. " x" .. short(buyMult))
            call("CuttersShopService", "EquipCutter", buy)
        end
        reserveTarget = 0
        return
    end

    reserveTarget = saveFor and saveCost or 0
end

local function auraPass()
    local st = call("AuraService", "GetState")
    if type(st) ~= "table" or type(st.Items) ~= "table" then return end
    local world = worldId()
    local curMult = 1
    local equipped = tostring(st.EquippedAura or "")
    for _, item in pairs(st.Items) do
        if item.Equipped then curMult = tonumber(item.StrengthMultiplier) or 1 end
    end
    STATE.aura, STATE.auraMult = (equipped ~= "" and equipped or "-"), curMult

    for id, item in pairs(st.Items) do
        if item.Owned and not item.Equipped and (tonumber(item.StrengthMultiplier) or 0) > curMult then
            call("AuraService", "BuyOrToggleAura", id)
            note("equipped owned aura " .. tostring(item.DisplayName or id))
            return
        end
    end

    local buy, cost, mult = nil, math.huge, curMult
    for id, item in pairs(st.Items) do
        local price = tonumber(item.Price) or 0
        local m = tonumber(item.StrengthMultiplier) or 0
        local reqWorld = tonumber(item.RequiredWorld) or 1
        if not item.Owned and price > 0 and m > curMult and world >= reqWorld then
            if m > mult or (m == mult and price < cost) then buy, cost, mult = id, price, m end
        end
    end
    if not buy then return end
    if not spendable(cost) then return end
    local res = call("AuraService", "BuyOrToggleAura", buy)
    if res then
        STATE.spent = STATE.spent + cost
        note("bought aura " .. buy .. " x" .. tostring(mult))
    end
end

local UPGRADES = { "AttackSpeedButtonClicked", "AttackRangeButtonClicked", "CarryButtonClicked", "SpeedButtonClicked" }
local upgradeCursor = 1
local upgradeBlocked = {}

local function upgradePass()
    local money = tonumber(attr("MoneyRaw", 0)) or 0
    for i = 1, #UPGRADES do
        local idx = ((upgradeCursor + i - 2) % #UPGRADES) + 1
        local name = UPGRADES[idx]
        local blockedUntil = upgradeBlocked[name]
        if not blockedUntil or money >= blockedUntil then
            if spendable(money * 0.05) then
                local before = money
                fire("UpgradesService", name)
                task.wait(0.6)
                local after = tonumber(attr("MoneyRaw", 0)) or 0
                if after < before then
                    upgradeBlocked[name] = nil
                    STATE.spent = STATE.spent + (before - after)
                    upgradeCursor = idx + 1
                    return
                end
                upgradeBlocked[name] = before * 1.5
            end
        end
    end
    upgradeCursor = upgradeCursor + 1
end

--------------------------------------------------------------------------------
-- rebirth, worlds, free rewards
--------------------------------------------------------------------------------

local function rebirthPass()
    local st = call("RebirtService", "GetState")
    if type(st) ~= "table" then return end
    STATE.rebirths = tonumber(st.RebirthLevel) or STATE.rebirths
    STATE.level = tonumber(st.PlayerLevel) or STATE.level
    if not st.CanRebirth then return end
    fire("RebirtService", "RebirthButtonClicked")
    note("rebirth -> level " .. tostring(st.NextRebirthLevel))
    task.wait(1.5)
end

local function worldPass()
    local st = call("WorldService", "GetState")
    if type(st) ~= "table" then return end
    local cur = tonumber(st.CurrentWorld) or 1
    local unlocked = tonumber(st.HighestUnlockedWorld) or cur
    STATE.world = cur
    if unlocked > cur then
        call("WorldService", "TeleportToWorld", unlocked)
        note("travelling to world " .. unlocked)
        task.wait(3)
    end
end

local function freePass()
    local off = call("DataService", "GetOfflineRewardState")
    if type(off) == "table" and (off.CanClaim or off.Available or off.Pending) then
        call("DataService", "ClaimOfflineReward")
    end
    local like = call("DataService", "GetLikeRewardState")
    if type(like) == "table" and (like.CanClaim or like.Available) then
        call("DataService", "ClaimLikeReward")
    end
    local quests = call("QuestProgressService", "GetState")
    if type(quests) == "table" then
        local list = quests.Quests or quests.Items or quests
        if type(list) == "table" then
            for key, q in pairs(list) do
                if type(q) == "table" and q.Completed and not q.Claimed then
                    call("QuestProgressService", "ClaimQuest", q.Id or key)
                    task.wait(0.3)
                end
            end
        end
    end
    local wheel = call("LuckyWheelService", "GetState")
    if type(wheel) == "table" then
        local free = tonumber(wheel.FreeSpins or wheel.Spins or 0) or 0
        if wheel.CanClaimFreeSpin or wheel.CanClaim then call("LuckyWheelService", "ClaimSpin") end
        if free > 0 then call("LuckyWheelService", "RequestSpin") end
    end
end

--------------------------------------------------------------------------------
-- refresh
--------------------------------------------------------------------------------

_G.__CUTGRASS_FRONTIER = _G.__CUTGRASS_FRONTIER or {}

local function rememberFrontier()
    local key = "w" .. worldId()
    local best = tonumber(_G.__CUTGRASS_FRONTIER[key]) or 1
    if STATE.zoneBest > best then
        _G.__CUTGRASS_FRONTIER[key] = STATE.zoneBest
    elseif best > STATE.zoneBest then
        STATE.zoneBest = best
    end
end

local function refresh()
    rememberFrontier()
    STATE.strength = tonumber(attr("StrengthRaw", 0)) or 0
    STATE.money = tonumber(attr("MoneyRaw", 0)) or 0
    STATE.level = tonumber(attr("StrengthLevel", 0)) or 0
    STATE.rebirths = tonumber(attr("RebirthLevel", 0)) or 0
    STATE.world = worldId()
    if STATE.zoneBest < 1 then STATE.zoneBest = 1 end
end

local function statePass()
    local s = call("StrengthService", "GetState")
    if type(s) ~= "table" then return end
    STATE.clickAmount = tonumber(s.ClickAmount) or STATE.clickAmount
    STATE.level = tonumber(s.Level) or STATE.level
end

local function unstuck()
    CONFIG.auto = false
    STATE.busy = false
    STATE.halted = false
    local _, hrp, hum = char()
    if hum then
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
    if hrp then hrp.Anchored = false end
    local scripts = plr:FindFirstChild("PlayerScripts")
    local pm = scripts and scripts:FindFirstChild("PlayerModule")
    if pm then pcall(function() require(pm):GetControls():Enable() end) end
    stopWalking()
    STATE.phase = "idle"
    note("unstuck, auto off")
end

--------------------------------------------------------------------------------
-- anti-cheat listener
--------------------------------------------------------------------------------

do
    local re = remote("AntiCheatService", "RE", "IncidentWarning")
    if re then
        re.OnClientEvent:Connect(function(payload)
            STATE.halted = true
            CONFIG.auto = false
            local reason = "unknown"
            if type(payload) == "table" then
                reason = tostring(payload.Reason or payload.reason or payload.Check or payload.Title or reason)
            elseif payload ~= nil then
                reason = tostring(payload)
            end
            note("ANTI-CHEAT WARNING: " .. reason .. " - everything stopped")
            warn("[Ivory] anti-cheat incident: " .. reason)
        end)
    end
end

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

local isLobby = false
local isGame = true

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
if isGame then
    SaveManager:SetSubFolder("game")
else
    SaveManager:SetSubFolder("lobby")
end

--------------------------------------------------------------------------------
-- tabs
--------------------------------------------------------------------------------

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

--------------------------------------------------------------------------------
-- Main > Automation sub tab
--------------------------------------------------------------------------------

local AutomationSub = MainTab:AddSubTab("Automation", "zap")
local FarmGroup = AutomationSub:AddLeftGroupbox("Core Features", "box-icon")
local ExtraGroup = AutomationSub:AddRightGroupbox("Extra Features", "box-icon")

FarmGroup:AddToggle("Auto Farm", CONFIG.auto, function(v)
    CONFIG.auto = v
    STATE.phase = v and "farming" or "idle"
    if not v then stopWalking() end
    note(v and "running" or "stopped")
end):AddKeyPicker("AutoFarmKey", {
    Default = "RightShift",
    Text = "Auto Farm Toggle",
    Mode = "Toggle",
    SyncToggleState = true,
    NoUI = true,
})

FarmGroup:AddToggle("Click Engine", CONFIG.click, function(v)
    CONFIG.click = v
end)

FarmGroup:AddToggle("Training Pad", CONFIG.train, function(v)
    CONFIG.train = v
end)

FarmGroup:AddSlider("Train Secs/Trip", {
    Default = CONFIG.trainSecs,
    Min = 0,
    Max = 90,
    Rounding = 0,
    Callback = function(v) CONFIG.trainSecs = v end,
    Text = "Seconds on pad per trip",
})

FarmGroup:AddSlider("Min Pad Mult", {
    Default = CONFIG.trainMinMult,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Callback = function(v) CONFIG.trainMinMult = v end,
    Text = "Minimum pad multiplier",
})

FarmGroup:AddToggle("Cut Grass", CONFIG.cut, function(v)
    CONFIG.cut = v
end)

FarmGroup:AddToggle("Pick Up Loot", CONFIG.loot, function(v)
    CONFIG.loot = v
end)

FarmGroup:AddSlider("Loot Secs/Lap", {
    Default = CONFIG.tripSecs,
    Min = 15,
    Max = 120,
    Rounding = 0,
    Callback = function(v) CONFIG.tripSecs = v end,
    Text = "Seconds for loot patrol",
})

FarmGroup:AddSlider("Cut Secs/Lap", {
    Default = CONFIG.cutSecs,
    Min = 10,
    Max = 90,
    Rounding = 0,
    Callback = function(v) CONFIG.cutSecs = v end,
    Text = "Seconds for cutting",
})

ExtraGroup:AddDropdown("Zone Mode", {
    Options = { "Auto", "Manual" },
    Default = CONFIG.zoneMode,
    Callback = function(v) CONFIG.zoneMode = v end,
    Text = "Zone selection",
})

ExtraGroup:AddSlider("Manual Zone", {
    Default = CONFIG.zoneTarget,
    Min = 1,
    Max = 15,
    Rounding = 0,
    Callback = function(v) CONFIG.zoneTarget = v end,
    Text = "Target zone (Manual mode)",
})

ExtraGroup:AddSlider("Probe Hold (s)", {
    Default = CONFIG.probeHoldSecs,
    Min = 30,
    Max = 300,
    Rounding = 0,
    Callback = function(v) CONFIG.probeHoldSecs = v end,
    Text = "Hold time for walled zone",
})

ExtraGroup:AddToggle("Sell Loot", CONFIG.sell, function(v)
    CONFIG.sell = v
end)

ExtraGroup:AddToggle("Buy Cutters", CONFIG.cutters, function(v)
    CONFIG.cutters = v
end)

ExtraGroup:AddToggle("Buy Auras", CONFIG.auras, function(v)
    CONFIG.auras = v
end)

ExtraGroup:AddToggle("Buy Upgrades", CONFIG.upgrades, function(v)
    CONFIG.upgrades = v
end)

ExtraGroup:AddToggle("Auto Rebirth", CONFIG.rebirth, function(v)
    CONFIG.rebirth = v
end)

ExtraGroup:AddToggle("Travel Worlds", CONFIG.worlds, function(v)
    CONFIG.worlds = v
end)

ExtraGroup:AddToggle("Free Rewards", CONFIG.freebies, function(v)
    CONFIG.freebies = v
end)

ExtraGroup:AddSlider("Reserve Window", {
    Default = CONFIG.reserveWindow,
    Min = 15,
    Max = 300,
    Rounding = 0,
    Callback = function(v) CONFIG.reserveWindow = v end,
    Text = "Reserve window for cutters",
})

--------------------------------------------------------------------------------
-- Main > Manual sub tab
--------------------------------------------------------------------------------

local ManualSub = MainTab:AddSubTab("Manual", "play")
local ManualGroup = ManualSub:AddLeftGroupbox("Actions", "box-icon")

ManualGroup:AddButton("Trip Now", function()
    task.spawn(cutPass)
end)

ManualGroup:AddButton("Sell All", function()
    task.spawn(sellPass)
end)

ManualGroup:AddButton("Shop Now", function()
    task.spawn(function() cutterPass() auraPass() end)
end)

ManualGroup:AddButton("Claim Free", function()
    task.spawn(freePass)
end)

ManualGroup:AddButton("Unstuck", function()
    unstuck()
end)

--------------------------------------------------------------------------------
-- Main > Discord sub tab
--------------------------------------------------------------------------------

local DiscordSub = MainTab:AddSubTab("Discord", "message-circle")
local DiscordGroup = DiscordSub:AddLeftGroupbox("Community", "box-icon")

DiscordGroup:AddButton("Join Discord For Dupe", function()
    if setclipboard then
        setclipboard("https://discord.gg/MCWYKBdB4E")
        Library:Notify({ Title = "Ivory", Description = "Discord link copied to clipboard!", Type = "Success", Time = 3 })
    end
end)

DiscordGroup:AddLabel("Join our community for updates, support, and exclusive features.")

--------------------------------------------------------------------------------
-- Main > Status sub tab
--------------------------------------------------------------------------------

local StatusSub = MainTab:AddSubTab("Status", "bar-chart")
local StatusGroup = StatusSub:AddLeftGroupbox("Live Stats", "box-icon")

StatusGroup:AddLabel("Phase: " .. STATE.phase)
StatusGroup:AddLabel("Strength: " .. short(STATE.strength))
StatusGroup:AddLabel("Money: $" .. short(STATE.money))
StatusGroup:AddLabel("Level: " .. tostring(STATE.level))
StatusGroup:AddLabel("Rebirths: " .. tostring(STATE.rebirths))
StatusGroup:AddLabel("World: " .. tostring(STATE.world))
StatusGroup:AddLabel("Zone: " .. tostring(STATE.zone) .. " (open to " .. tostring(STATE.zoneBest) .. ")")
StatusGroup:AddLabel("Cutter: " .. STATE.cutter .. " x" .. short(STATE.cutterMult))
StatusGroup:AddLabel("Aura: " .. STATE.aura .. " x" .. tostring(STATE.auraMult))
StatusGroup:AddLabel("Pad: " .. STATE.pad .. " x" .. tostring(STATE.padMult))
StatusGroup:AddLabel("Backpack: " .. tostring(STATE.bag) .. "/" .. tostring(STATE.bagCap))
StatusGroup:AddLabel("Trips: " .. tostring(STATE.trips))
StatusGroup:AddLabel("Loot: " .. tostring(STATE.lootTotal) .. " taken, " .. tostring(STATE.sold) .. " sold")
StatusGroup:AddLabel("Earned: $" .. short(STATE.earned) .. " | Spent: $" .. short(STATE.spent))
StatusGroup:AddLabel("Note: " .. STATE.note)

StatusGroup:AddDivider()
StatusGroup:AddLabel("Auto: " .. (CONFIG.auto and "ON" or "OFF"))
StatusGroup:AddLabel("Phase: " .. STATE.phase)

-- Update status labels
task.spawn(function()
    while GEN == _G.__CUTGRASS do
        pcall(function()
            StatusGroup:Clear()
            StatusGroup:AddLabel("Phase: " .. STATE.phase)
            StatusGroup:AddLabel("Strength: " .. short(STATE.strength) .. " (" .. short(STATE.strRate) .. "/s)")
            StatusGroup:AddLabel("Money: $" .. short(STATE.money) .. " ($" .. short(STATE.moneyRate) .. "/s)")
            StatusGroup:AddLabel("Level: " .. tostring(STATE.level) .. " | Rebirths: " .. tostring(STATE.rebirths))
            StatusGroup:AddLabel("World: " .. tostring(STATE.world))
            StatusGroup:AddLabel("Zone: " .. tostring(STATE.zone) .. " (open to " .. tostring(STATE.zoneBest) .. ")")
            StatusGroup:AddLabel("Cutter: " .. STATE.cutter .. " x" .. short(STATE.cutterMult))
            StatusGroup:AddLabel("Aura: " .. STATE.aura .. " x" .. tostring(STATE.auraMult))
            StatusGroup:AddLabel("Pad: " .. STATE.pad .. " x" .. tostring(STATE.padMult))
            StatusGroup:AddLabel("Backpack: " .. tostring(STATE.bag) .. "/" .. tostring(STATE.bagCap) .. " ($" .. short(STATE.bagValue) .. ")")
            StatusGroup:AddLabel("Trips: " .. tostring(STATE.trips) .. " | Walled: " .. tostring(STATE.blocked))
            StatusGroup:AddLabel("Loot: " .. tostring(STATE.lootTotal) .. " taken, " .. tostring(STATE.sold) .. " sold")
            StatusGroup:AddLabel("Earned: $" .. short(STATE.earned) .. " | Spent: $" .. short(STATE.spent))
            StatusGroup:AddLabel("Note: " .. STATE.note)
        end)
        task.wait(0.5)
    end
end)

--------------------------------------------------------------------------------
-- Player > Stats sub tab
--------------------------------------------------------------------------------

local StatsSub = PlayerTab:AddSubTab("Stats", "activity")
local StatsGroup = StatsSub:AddLeftGroupbox("Player Stats", "box-icon")

StatsGroup:AddLabel("UserId: " .. tostring(plr.UserId))
StatsGroup:AddLabel("Display: " .. tostring(plr.DisplayName))
StatsGroup:AddLabel("Strength: " .. short(STATE.strength))
StatsGroup:AddLabel("Money: $" .. short(STATE.money))
StatsGroup:AddLabel("Level: " .. tostring(STATE.level))
StatsGroup:AddLabel("Rebirths: " .. tostring(STATE.rebirths))
StatsGroup:AddLabel("World: " .. tostring(STATE.world))
StatsGroup:AddLabel("Zone: " .. tostring(STATE.zoneBest))

--------------------------------------------------------------------------------
-- Settings tab (always last)
--------------------------------------------------------------------------------

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "box-icon")

MenuGroup:AddToggle("Custom Cursor", true, function(v)
    Library.ShowCustomCursor = v
end)

MenuGroup:AddButton("Test Notification", function()
    Library:Notify({ Title = "Ivory", Description = "Test notification!", Type = "Info", Time = 3 })
end)

MenuGroup:AddDropdown("Notification Side", {
    Options = { "Right", "Left" },
    Default = "Right",
    Callback = function(v)
        Library.NotifySide = v
    end,
    Text = "Notification position",
})

MenuGroup:AddDropdown("DPI Scale", {
    Options = { "50%", "75%", "100%", "125%", "150%", "200%" },
    Default = "100%",
    Callback = function(v)
        local scale = tonumber(v:gsub("%%", "")) / 100
        Library.DPIScale = scale
    end,
    Text = "UI scale",
})

MenuGroup:AddSlider("Corner Radius", {
    Default = 4,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(v)
        Library.CornerRadius = v
    end,
    Text = "Corner radius",
})

MenuGroup:AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    Text = "Menu Toggle",
    Mode = "Toggle",
    SyncToggleState = false,
})

MenuGroup:AddButton("Unload", function()
    CONFIG.auto = false
    stopWalking()
    pcall(function() Library:Destroy() end)
end)

--------------------------------------------------------------------------------
-- loops
--------------------------------------------------------------------------------

local function loop(sec, key, fn, needsBody)
    task.spawn(function()
        while GEN == _G.__CUTGRASS do
            if CONFIG.auto and not STATE.halted and (key == nil or CONFIG[key])
                and not (needsBody and STATE.busy) then
                local ok, err = pcall(fn)
                if not ok then note(tostring(key) .. " failed: " .. tostring(err)) end
            end
            task.wait(sec)
        end
    end)
end

task.spawn(function()
    while GEN == _G.__CUTGRASS do
        if CONFIG.auto and CONFIG.click and not STATE.halted then
            clickOnce()
            task.wait(0.075)
        else
            task.wait(0.3)
        end
    end
end)

task.spawn(function()
    local lastS, lastM, lastT = nil, nil, os.clock()
    while GEN == _G.__CUTGRASS do
        pcall(refresh)
        local now = os.clock()
        local dt = now - lastT
        if dt >= 4 then
            if lastS then STATE.strRate = math.max(0, (STATE.strength - lastS) / dt) end
            if lastM then STATE.moneyRate = math.max(0, (STATE.money - lastM) / dt) end
            lastS, lastM, lastT = STATE.strength, STATE.money, now
        end
        task.wait(1)
    end
end)

task.spawn(function()
    while GEN == _G.__CUTGRASS do
        if CONFIG.auto and not STATE.halted and (CONFIG.cut or CONFIG.train or CONFIG.loot) then
            STATE.busy = true

            if CONFIG.sell then pcall(sellPass) end
            pcall(bagState)
            if STATE.bagCap > 0 and STATE.bag > 0 then
                local ok, err = pcall(homePass)
                if not ok then note("home failed: " .. tostring(err)) end
            end

            if CONFIG.train and CONFIG.trainSecs > 0 then
                local ok, err = pcall(trainPass, CONFIG.trainSecs)
                if not ok then note("train failed: " .. tostring(err)) end
            end

            if CONFIG.cut and targetZone() > STATE.zoneBest then
                local ok, err = pcall(cutPass)
                if not ok then note("cut failed: " .. tostring(err)) end
            end

            if CONFIG.loot then
                local until_ = os.clock() + CONFIG.tripSecs
                while os.clock() < until_ and CONFIG.auto and CONFIG.loot
                    and GEN == _G.__CUTGRASS and not STATE.halted do
                    if STATE.bagCap > 0 and STATE.bag >= STATE.bagCap then break end
                    local ok, err = pcall(lootPass)
                    if not ok then note("loot failed: " .. tostring(err)) break end
                    if STATE.phase == "no loot in reach" then break end
                    task.wait(0.2)
                end
            end
            STATE.busy = false
        else
            STATE.phase = "idle"
        end
        task.wait(0.4)
    end
end)

loop(6, "sell", sellPass)
loop(12, "cutters", cutterPass)
loop(18, "auras", auraPass)
loop(9, "upgrades", upgradePass)
loop(15, "rebirth", rebirthPass)
loop(30, "worlds", worldPass)
loop(150, "freebies", freePass)
loop(5, nil, bagState)
loop(20, nil, statePass)
task.spawn(function() task.wait(2) pcall(statePass) end)

--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

_G.__CUTGRASS_DBG = {
    CONFIG = CONFIG, STATE = STATE, GEN = GEN,
    short = short, note = note, attr = attr,
    fire = fire, call = call, remote = remote, HONEYPOT = HONEYPOT,
    walkTo = walkTo, stopWalking = stopWalking,
    worldId = worldId, worldFolder = worldFolder, zonesFolder = zonesFolder,
    startLine = startLine, zoneModel = zoneModel, zonePos = zonePos, zoneCount = zoneCount,
    grassCounts = grassCounts,
    clickOnce = clickOnce, attackOnce = attackOnce,
    bestPad = bestPad, trainPass = trainPass,
    bagState = bagState, lootCandidates = lootCandidates, grabLoot = grabLoot,
    basePos = basePos, homePass = homePass,
    targetZone = targetZone, cutPass = cutPass, lootPass = lootPass, sellPass = sellPass,
    cutSince = function() return cutSinceMark end,
    spendable = spendable, cutterPass = cutterPass, auraPass = auraPass,
    upgradePass = upgradePass, rebirthPass = rebirthPass, worldPass = worldPass,
    freePass = freePass, refresh = refresh, unstuck = unstuck, statePass = statePass,
    rememberFrontier = rememberFrontier,
}

print("[Ivory] gen " .. GEN .. " ready - " .. (isLobby and "Lobby" or "Game") .. " mode")
