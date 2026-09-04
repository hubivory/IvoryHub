--!nocheck
-- SellLemons.luau  --  "Sell Lemons"  (place 79268393072444, BloxByte Games)

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local plr = Players.LocalPlayer

local CONFIG = {
	auto = false,
	autoBuy = true,
	autoUpgrade = true,
	autoWake = true,
	wakeSpacing = 0.15,
	autoFruit = true,
	fruitPerSweep = 30,
	autoRace = true,
	autoTrade = true,
	autoDrops = true,
	autoOffers = true,
	offerRaises = 1,
	autoPowers = true,
	buyCosmeticPowers = false,
	autoRebirth = false,
	rebirthFactor = 10,
	rebirthMinimum = 100,
	autoEvolve = false,
	autoAscend = false,
	autoOrchard = false,
}

local STATE = {
	note = "idle",
	cash = -math.huge, spent = -math.huge, investors = -math.huge,
	potential = -math.huge, tokens = 0,
	purchased = 0, rebirths = 0, evolution = 0, ascension = 0,
	evolveProgress = 0, ascendProgress = 0,
	incomeRate = 0, lastCash = nil, rateAt = nil, rateRef = nil,
	nextBuy = "-", nextBuyPrice = nil,
	nextUpgrade = "-", nextUpgradePrice = nil, nextUpgradeCount = 1,
	streams = {},
	wakes = 0, buys = 0, upgrades = 0, fruits = 0, fruitRipe = 0, fruitHome = nil,
	races = 0, trades = 0, drops = 0, offers = 0, powerBuys = 0,
	earnedRace = 0, earnedTrade = 0, earnedDrop = 0, earnedOffer = 0, earnedFruit = 0,
	raceIn = 0, tradeIn = 0,
	offerValue = nil, offerRaised = 0,
	powerLevels = {}, nextPower = "-", nextPowerPrice = nil,
	orchardUnlocked = false, orchardNote = "off (unverified)",
	blocked = nil,
}

_G.__LEMON = (_G.__LEMON or 0) + 1
local GEN = _G.__LEMON

local function req(module)
	if not module then return nil, "no module" end
	if setthreadidentity then pcall(setthreadidentity, 2) end
	local ok, value = pcall(require, module)
	if not ok then return nil, tostring(value) end
	return value
end

local function path(root, ...)
	local node = root
	for _, name in ipairs({ ... }) do
		if not node then return nil end
		node = node:FindFirstChild(name)
	end
	return node
end

local Huge = req(ReplicatedStorage:WaitForChild("Modules", 20)
	and path(ReplicatedStorage, "Modules", "Huge"))
local Balance = req(ReplicatedStorage:FindFirstChild("Balance"))
local Config = req(ReplicatedStorage:FindFirstChild("Config"))

if not Huge then
	warn("[Ivory] Modules.Huge missing - wrong game?")
	return
end

local NONE = -math.huge

local function isHuge(v) return type(v) == "number" end
local function hugeIsZero(v) return (not isHuge(v)) or v == NONE or v ~= v end

local function fmt(v)
	if hugeIsZero(v) then return "0" end
	local ok, text = pcall(Huge.formatAbbreviated, v)
	if ok and text then return text end
	return string.format("%.2f(log10)", v)
end

local function fmtTime(v)
	if hugeIsZero(v) then return "-" end
	local ok, text = pcall(Huge.formatTime, v)
	return ok and text or "-"
end

local function toNum(v)
	if hugeIsZero(v) then return 0 end
	local ok, n = pcall(Huge.toNumber, v)
	if ok and type(n) == "number" and n == n then return n end
	return 0
end

local function toHuge(n)
	if type(n) ~= "number" or n <= 0 then return NONE end
	local ok, v = pcall(Huge.toHuge, n)
	return ok and v or NONE
end

local function atLeast(a, b)
	if hugeIsZero(b) then return true end
	if hugeIsZero(a) then return false end
	return a >= b
end

local function short(n)
	if type(n) ~= "number" or n <= 0 then return "0" end
	return fmt(toHuge(n))
end

local Tycoon = req(path(ReplicatedStorage, "Modules", "Tycoon", "Tycoon"))
local ComponentFolder = path(ReplicatedStorage, "Modules", "Tycoon", "Component")

local componentCache = {}

local function comp(name)
	if componentCache[name] then return componentCache[name] end
	if not (Tycoon and ComponentFolder) then return nil end
	local class = req(ComponentFolder:FindFirstChild(name))
	if not class then return nil end
	local ok, lt = pcall(Tycoon.getLocal)
	if not ok or not lt then return nil end
	local ok2, instance = pcall(function() return lt:GetComponent(class) end)
	if not ok2 or not instance then return nil end
	componentCache[name] = instance
	return instance
end

local function myTycoon()
	if _G.__LEMON_T and _G.__LEMON_T.Parent then return _G.__LEMON_T end
	for _, folder in ipairs(Workspace:GetChildren()) do
		if folder:IsA("Folder") and folder.Name:match("^Tycoon%d+$") then
			local owner = folder:FindFirstChild("Owner")
			if owner and owner:IsA("ObjectValue") and owner.Value == plr then
				_G.__LEMON_T = folder
				return folder
			end
		end
	end
	return nil
end

local function tycoonRemote(name)
	local t = myTycoon()
	if not t then return nil end
	local remotes = t:FindFirstChild("Remotes")
	return remotes and remotes:FindFirstChild(name)
end

local function coreRequest(name)
	return path(ReplicatedStorage, "Core", "RemoteRequest") and
		path(ReplicatedStorage, "Core", "RemoteRequest"):FindFirstChild(name)
end

local function coreSignal(name)
	local folder = path(ReplicatedStorage, "Core", "RemoteSignal")
	return folder and folder:FindFirstChild(name)
end

local function balances() return comp("TycoonBalances") end
local function analyzer() return comp("TycoonAnalyzer") end
local function income() return comp("TycoonIncome") end
local function upgrades() return comp("TycoonUpgrades") end
local function powers() return comp("TycoonPowers") end
local function rebirth() return comp("TycoonRebirth") end
local function evolution() return comp("TycoonEvolution") end
local function ascension() return comp("TycoonAscension") end
local function purchases() return comp("TycoonPurchases") end
local function phoneOffers() return comp("TycoonPhoneOffers") end
local function companions() return comp("TycoonCompanions") end

local function cash()
	local b = balances()
	if not b then return NONE end
	local ok, v = pcall(function() return b:GetCash() end)
	return (ok and isHuge(v)) and v or NONE
end

local function canAfford(price)
	if hugeIsZero(price) then return true end
	return atLeast(cash(), price)
end

local function nextPurchase()
	local a = analyzer()
	if not (a and Balance and Balance.PurchaseOrder) then return nil end
	local ok, all = pcall(function() return a:GetPurchases() end)
	if not ok or type(all) ~= "table" then return nil end
	for _, id in ipairs(Balance.PurchaseOrder) do
		local entry = all[id]
		if entry and entry.Instance and entry.Instance.Parent then
			local inst = entry.Instance
			if inst:GetAttribute("Enabled") and not inst:GetAttribute("Purchased") then
				return entry, id, Balance.PurchasePrices and Balance.PurchasePrices[id]
			end
		end
	end
	return nil
end

local function stepBuy()
	local entry, id, price = nextPurchase()
	if not entry then
		STATE.nextBuy, STATE.nextBuyPrice = "all bought", nil
		return
	end
	STATE.nextBuy, STATE.nextBuyPrice = id, price
	if not canAfford(price) then return end
	local ok = pcall(function() return entry:TryPurchaseAsync() end)
	if ok and entry.Instance:GetAttribute("Purchased") then
		STATE.buys = STATE.buys + 1
		STATE.note = "bought " .. tostring(id)
	end
end

local function earnerList()
	local a = analyzer()
	if not a then return {} end
	local ok, all = pcall(function() return a:GetEarners() end)
	return (ok and type(all) == "table") and all or {}
end

local function bestUpgrade()
	local best, bestId, bestPrice, bestCount
	for id, earner in pairs(earnerList()) do
		local ok, info = pcall(function() return earner:GetNextUpgradeInfo() end)
		if ok and type(info) == "table" and not info.Max and isHuge(info.Price) then
			if (not bestPrice) or info.Price < bestPrice then
				best, bestId, bestPrice, bestCount = earner, id, info.Price, info.Count or 1
			end
		end
	end
	return best, bestId, bestPrice, bestCount
end

local function stepUpgrade()
	local earner, id, price, count = bestUpgrade()
	if not earner then
		STATE.nextUpgrade, STATE.nextUpgradePrice = "maxed", nil
		return
	end
	STATE.nextUpgrade, STATE.nextUpgradePrice, STATE.nextUpgradeCount = id, price, count
	if not canAfford(price) then return end
	local ok = pcall(function() return earner:UpgradeAsync(count) end)
	if ok then
		STATE.upgrades = STATE.upgrades + 1
		STATE.note = "upgraded " .. tostring(id) .. " x" .. tostring(count)
	end
end

local function stepWake()
	local inc = income()
	if not inc then return end
	for id, earner in pairs(earnerList()) do
		if GEN ~= _G.__LEMON then return end
		local ok, auto = pcall(function() return inc:IsStreamAutomatic(id) end)
		if ok and not auto then
			pcall(function() earner:WakeAsync() end)
			STATE.wakes = STATE.wakes + 1
		end
	end
end

local function readStreams()
	local inc = income()
	if not inc then return end
	local rows = {}
	for id in pairs(earnerList()) do
		local function get(fn, ...)
			local ok, v = pcall(fn, ...)
			return ok and v or nil
		end
		rows[#rows + 1] = {
			id = id,
			auto = get(function() return inc:IsStreamAutomatic(id) end) and true or false,
			value = get(function() return inc:GetStreamRealValue(id) end),
			interval = get(function() return inc:GetStreamRealInterval(id) end),
			count = get(function() return inc:GetStreamCount(id) end) or 0,
		}
	end
	table.sort(rows, function(a, b)
		return (isHuge(a.value) and a.value or NONE) > (isHuge(b.value) and b.value or NONE)
	end)
	STATE.streams = rows
end

local FRUIT_REACH = 16
local FRUIT_HOP = 0.1
local FRUIT_SETTLE = 0.1

local function humanoidRoot()
	local char = plr.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function ripeFruits()
	local out = {}
	for _, part in ipairs(CollectionService:GetTagged("ClickFruit")) do
		if part.Parent then
			local clickPart = part:FindFirstChild("ClickFruitPart")
			local detector = clickPart and clickPart:FindFirstChildOfClass("ClickDetector")
			if detector then out[#out + 1] = { part = part, detector = detector } end
		end
	end
	return out
end

local function stepFruit()
	if not fireclickdetector then
		STATE.blocked = "executor has no fireclickdetector - fruit harvesting off"
		return
	end
	local root = humanoidRoot()
	if not root then return end

	local ripe = ripeFruits()
	STATE.fruitRipe = #ripe
	if #ripe == 0 then return end

	local origin = root.Position
	table.sort(ripe, function(a, b)
		return (a.part.Position - origin).Magnitude < (b.part.Position - origin).Magnitude
	end)

	local home = root.CFrame
	STATE.fruitHome = home

	local budget = math.clamp(CONFIG.fruitPerSweep or 30, 5, 200)

	for index, entry in ipairs(ripe) do
		if GEN ~= _G.__LEMON then break end
		if not (CONFIG.auto and CONFIG.autoFruit) then break end
		if index > budget then break end

		if entry.part.Parent then
			root = humanoidRoot()
			if not root then break end

			if (root.Position - entry.part.Position).Magnitude > FRUIT_REACH then
				root.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 3, 0))
				task.wait(FRUIT_HOP)
				root = humanoidRoot()
				if not root then break end
			end

			pcall(fireclickdetector, entry.detector)
			STATE.fruits = STATE.fruits + 1
			task.wait(FRUIT_SETTLE)
		end
	end

	local back = humanoidRoot()
	if back and home then pcall(function() back.CFrame = home end) end
end

local function raceAvailableAt()
	local svc = req(path(ReplicatedStorage, "Modules", "Service", "MinigameRaceService"))
	if not svc or not svc.GetRaceAvailableTime then return math.huge end
	local ok, t = pcall(svc.GetRaceAvailableTime)
	return (ok and type(t) == "number") and t or math.huge
end

local function tradeAvailableAt()
	local svc = req(path(ReplicatedStorage, "Modules", "Service", "MinigameTradeService"))
	if not svc or not svc.GetTradingAvailableTime then return math.huge end
	local ok, t = pcall(svc.GetTradingAvailableTime)
	return (ok and type(t) == "number") and t or math.huge
end

local function stepRace()
	local at = raceAvailableAt()
	STATE.raceIn = math.max(0, at - os.time())
	if at > os.time() then return end
	local startRemote = coreRequest("MinigameRaceService.Start")
	local endRemote = coreRequest("MinigameRaceService.End")
	if not (startRemote and endRemote) then return end
	local ok, prize = pcall(function() return startRemote:InvokeServer() end)
	if not ok or not isHuge(prize) then return end
	task.wait(0.3)
	local okEnd = pcall(function() return endRemote:InvokeServer(1) end)
	if okEnd then
		STATE.races = STATE.races + 1
		STATE.earnedRace = STATE.earnedRace + toNum(prize)
		STATE.note = "race won, " .. fmt(prize)
	end
end

local function stepTrade()
	local at = tradeAvailableAt()
	STATE.tradeIn = math.max(0, at - os.time())
	if at > os.time() then return end
	local startRemote = coreRequest("MinigameTradeService.Start")
	local endRemote = coreRequest("MinigameTradeService.End")
	if not (startRemote and endRemote) then return end
	local ok, cfg = pcall(function() return startRemote:InvokeServer() end)
	if not ok or type(cfg) ~= "table" or not isHuge(cfg.MaxEarnings) then return end
	task.wait(0.3)
	local okEnd = pcall(function() return endRemote:InvokeServer(cfg.MaxEarnings) end)
	if okEnd then
		STATE.trades = STATE.trades + 1
		STATE.earnedTrade = STATE.earnedTrade + toNum(cfg.MaxEarnings)
		STATE.note = "trade closed, " .. fmt(cfg.MaxEarnings)
	end
end

local dropQueue = {}

local function armDrops()
	if _G.__LEMON_DROPCONN then pcall(function() _G.__LEMON_DROPCONN:Disconnect() end) end
	local signal = coreSignal("DropService.New")
	if not signal then return end
	_G.__LEMON_DROPCONN = signal.OnClientEvent:Connect(function(id)
		if id ~= nil then dropQueue[#dropQueue + 1] = id end
	end)
end

local function stepDrops()
	if #dropQueue == 0 then return end
	local redeem = coreRequest("DropService.Redeem")
	if not redeem then return end
	local id = table.remove(dropQueue, 1)
	local ok, value = pcall(function() return redeem:InvokeServer(id) end)
	if ok and isHuge(value) then
		STATE.drops = STATE.drops + 1
		STATE.earnedDrop = STATE.earnedDrop + toNum(value)
		STATE.note = "drop " .. tostring(id) .. " = " .. fmt(value)
	end
end

local function currentOffer()
	local po = phoneOffers()
	if not po then return nil end
	local ok, v = pcall(function() return po:GetCurrentOffer() end)
	return (ok and isHuge(v)) and v or nil
end

local function stepOffer()
	local po = phoneOffers()
	if not po then return end
	local value = currentOffer()
	STATE.offerValue = value
	if not value then return end

	local raised = 0
	for _ = 1, math.clamp(CONFIG.offerRaises or 0, 0, 2) do
		pcall(function() po:RaiseOffer() end)
		task.wait(1.2)
		local after = currentOffer()
		if not after then
			STATE.note = "offer lost on raise " .. (raised + 1)
			STATE.offerValue = nil
			return
		end
		raised = raised + 1
		STATE.offerValue = after
		value = after
	end

	local ok = pcall(function() po:AcceptOffer() end)
	if ok then
		STATE.offers = STATE.offers + 1
		STATE.offerRaised = raised
		STATE.earnedOffer = STATE.earnedOffer + toNum(value)
		STATE.note = "offer accepted " .. fmt(value) .. (raised > 0 and (" (+" .. raised .. " raise)") or "")
	end
end

local POWER_ORDER = { "ClickFruitValue", "UpgradeStack", "BuyNext", "AutoFruit", "Manage", "WalkSpeed" }
local SKIP_POWERS = { Manage = true, WalkSpeed = true }

local function powerState()
	local pw = powers()
	if not pw then return {} end
	local ok, levels = pcall(function() return pw:GetLevels() end)
	if not ok or type(levels) ~= "table" then return {} end
	local out = {}
	for name, level in pairs(levels) do
		local okMax, max = pcall(function() return pw:GetMaxLevel(name) end)
		local okPrice, price = pcall(function() return pw:GetUpgradePrice(name) end)
		out[name] = {
			level = level,
			max = okMax and max or nil,
			price = (okPrice and isHuge(price)) and price or nil,
		}
	end
	return out
end

local function investors()
	local b = balances()
	if not b then return NONE end
	local ok, v = pcall(function() return b:GetInvestors() end)
	return (ok and isHuge(v)) and v or NONE
end

local function stepPowers()
	local pw = powers()
	if not pw then return end
	local state = powerState()
	STATE.powerLevels = state
	local have = investors()

	local firstTarget, firstPrice
	for _, name in ipairs(POWER_ORDER) do
		local entry = state[name]
		local skipped = SKIP_POWERS[name] and not CONFIG.buyCosmeticPowers
		if entry and entry.price and not skipped and (not entry.max or entry.level < entry.max) then
			if not firstTarget then firstTarget, firstPrice = name, entry.price end
			if atLeast(have, entry.price) then
				local ok = pcall(function() return pw:UpgradeAsync(name) end)
				if ok then
					STATE.powerBuys = STATE.powerBuys + 1
					STATE.note = "power " .. name .. " -> " .. tostring((entry.level or 0) + 1)
				end
				STATE.nextPower, STATE.nextPowerPrice = name, entry.price
				return
			end
		end
	end
	STATE.nextPower = firstTarget or "all owned"
	STATE.nextPowerPrice = firstPrice
end

local function potentialInvestors()
	local r = rebirth()
	if not r then return NONE end
	local ok, v = pcall(function() return r:GetPotentialInvestors() end)
	return (ok and isHuge(v)) and v or NONE
end

local function shouldRebirth()
	local potential = potentialInvestors()
	if hugeIsZero(potential) then return false end
	local minimum = toHuge(CONFIG.rebirthMinimum)
	if not atLeast(potential, minimum) then return false end
	local have = investors()
	if hugeIsZero(have) then return true end
	local factor = math.log10(math.max(CONFIG.rebirthFactor or 1, 1))
	return potential >= have + factor
end

local function stepRebirth()
	if not shouldRebirth() then return end
	local r = rebirth()
	if not r then return end
	local before = potentialInvestors()
	local ok = pcall(function() return r:RebirthAsync() end)
	if ok then
		STATE.note = "rebirthed for " .. fmt(before) .. " investors"
		task.wait(2)
	end
end

local function stepEvolve()
	local e = evolution()
	if not e then return end
	local ok, progress = pcall(function() return e:GetEvolutionProgress() end)
	if not ok or type(progress) ~= "number" then return end
	STATE.evolveProgress = progress
	if progress < 1 then return end
	if pcall(function() return e:EvolveAsync() end) then
		STATE.note = "evolved"
		task.wait(2)
	end
end

local function stepAscend()
	local a = ascension()
	if not a then return end
	local ok, progress = pcall(function() return a:GetAscensionProgress() end)
	if not ok or type(progress) ~= "number" then return end
	STATE.ascendProgress = progress
	if progress < 1 then return end
	if pcall(function() return a:AscendAsync() end) then
		STATE.note = "ascended"
		task.wait(2)
	end
end

local function stepCompanions()
	local c = companions()
	if not c then return end
	local ok, pending = pcall(function() return c:GetPending() end)
	if ok and type(pending) == "table" then
		for _, key in ipairs(pending) do
			pcall(function() return c:ClaimCompanionAsync(key) end)
		end
	end
	local okEq, equipped = pcall(function() return c:GetEquippedCompanion() end)
	if okEq and equipped == nil then
		local okUn, unlocked = pcall(function() return c:GetUnlocked() end)
		if okUn and type(unlocked) == "table" and unlocked[1] then
			pcall(function() return c:SetEquippedAsync(unlocked[1]) end)
		end
	end
end

local PLOT_EMPTY, PLOT_TREE_GROWING, PLOT_FRUIT_GROWING, PLOT_FRUIT_READY = 0, 1, 2, 3

local function orchardModule()
	return req(path(ReplicatedStorage, "Modules", "Tycoon", "Orchard", "Orchard"))
end

local function orchardIsUnlocked()
	local mod = orchardModule()
	if not (mod and Tycoon) then return false end
	local ok, lt = pcall(Tycoon.getLocal)
	if not ok or not lt then return false end
	local okO, orchard = pcall(function() return mod.getFromTycoon(lt) end)
	if not okO or not orchard then return false end
	local okU, unlocked = pcall(function() return orchard:IsUnlocked() end)
	return okU and unlocked or false
end

local function stepOrchard()
	STATE.orchardUnlocked = orchardIsUnlocked()

	if not STATE.orchardUnlocked then
		local price = Config and Config.Orchard and Config.Orchard.UnlockCashPrice
		local hugePrice = price and toHuge(price) or nil
		if hugePrice and canAfford(hugePrice) then
			local remote = tycoonRemote("UnlockOrchard")
			if remote and remote:IsA("RemoteFunction") then
				if pcall(function() return remote:InvokeServer() end) then
					STATE.orchardNote = "unlock fired (unverified)"
				end
			end
		else
			STATE.orchardNote = "locked, needs " .. (hugePrice and fmt(hugePrice) or "1e25")
		end
		return
	end

	local t = myTycoon()
	local plots = t and path(t, "Orchard", "Plots")
	if not plots then return end

	local plant = coreRequest("OrchardPlot.Plant")
	local harvest = coreRequest("OrchardPlot.Harvest")
	local unlockPlot = tycoonRemote("UnlockPlot")
	local ready, planted, unlockedNow = 0, 0, 0

	for _, plot in ipairs(plots:GetChildren()) do
		if GEN ~= _G.__LEMON then return end
		local state = plot:GetAttribute("State")
		local enabled = plot:GetAttribute("Enabled")
		local base = plot:GetAttribute("BaseUnlocked")

		if not base and plot:GetAttribute("Available") and unlockPlot then
			if pcall(function() return unlockPlot:InvokeServer(plot.Name) end) then
				unlockedNow = unlockedNow + 1
			end
		elseif enabled and state == PLOT_FRUIT_READY and harvest then
			if pcall(function() return harvest:InvokeServer(plot) end) then ready = ready + 1 end
		elseif enabled and state == PLOT_EMPTY and plant then
			if pcall(function() return plant:InvokeServer(plot) end) then planted = planted + 1 end
		end
	end

	local sell = path(t, "Values", "SellFruits")
	if sell and sell:IsA("RemoteFunction") then
		pcall(function() return sell:InvokeServer() end)
	end

	STATE.orchardNote = string.format("unverified: %d harvested, %d planted, %d plots unlocked",
		ready, planted, unlockedNow)
end

local function armSpecialIncome()
	if _G.__LEMON_SICONN then pcall(function() _G.__LEMON_SICONN:Disconnect() end) end
	local remote = tycoonRemote("SpecialIncome")
	if not remote then return end
	_G.__LEMON_SICONN = remote.OnClientEvent:Connect(function(source, amount)
		if not isHuge(amount) then return end
		if source == "ClickFruit" then
			STATE.earnedFruit = STATE.earnedFruit + toNum(amount)
		end
	end)
end

local RATE_WINDOW = 8

local function refresh()
	local b, p, r, e, a = balances(), purchases(), rebirth(), evolution(), ascension()
	if b then
		local function get(fn)
			local ok, v = pcall(fn)
			return (ok and isHuge(v)) and v or NONE
		end
		STATE.cash = get(function() return b:GetCash() end)
		STATE.spent = get(function() return b:GetCashSpent() end)
		STATE.investors = get(function() return b:GetInvestors() end)
		local okT, tokens = pcall(function() return b:GetTokens() end)
		STATE.tokens = okT and tokens or 0
	end
	if p then
		local ok, n = pcall(function() return p:GetPurchasedCount() end)
		STATE.purchased = ok and n or STATE.purchased
	end
	if r then
		STATE.potential = potentialInvestors()
		local ok, n = pcall(function() return r:GetRebirths() end)
		STATE.rebirths = ok and n or STATE.rebirths
	end
	if e then
		local ok, v = pcall(function() return e:GetEvolutionProgress() end)
		if ok and type(v) == "number" then STATE.evolveProgress = v end
		local okE, n = pcall(function() return e:GetEvolution() end)
		STATE.evolution = okE and n or STATE.evolution
	end
	if a then
		local ok, v = pcall(function() return a:GetAscensionProgress() end)
		if ok and type(v) == "number" then STATE.ascendProgress = v end
		local okA, n = pcall(function() return a:GetAscension() end)
		STATE.ascension = okA and n or STATE.ascension
	end

	STATE.raceIn = math.max(0, raceAvailableAt() - os.time())
	STATE.tradeIn = math.max(0, tradeAvailableAt() - os.time())

	local total = toNum(STATE.cash) + toNum(STATE.spent)
	local now = os.clock()
	if STATE.rateAt == nil then
		STATE.rateAt, STATE.rateRef = now, total
	elseif now - STATE.rateAt >= RATE_WINDOW then
		local span = now - STATE.rateAt
		local delta = total - (STATE.rateRef or total)
		if delta >= 0 then STATE.incomeRate = delta / span end
		STATE.rateAt, STATE.rateRef = now, total
	end
end

local function loop(interval, key, fn)
	task.spawn(function()
		while GEN == _G.__LEMON do
			if CONFIG.auto and (key == nil or CONFIG[key]) then
				local ok, err = pcall(fn)
				if not ok then STATE.note = tostring(err) end
			end
			task.wait(interval)
		end
	end)
end

task.spawn(function()
	while GEN == _G.__LEMON do
		if CONFIG.auto and CONFIG.autoWake then
			pcall(stepWake)
		end
		task.wait(math.max(CONFIG.wakeSpacing or 0.15, 0.05))
	end
end)

loop(0.3, "autoBuy", stepBuy)
loop(0.4, "autoUpgrade", stepUpgrade)
loop(1, "autoFruit", stepFruit)
loop(1, "autoDrops", stepDrops)
loop(5, "autoOffers", stepOffer)
loop(8, "autoRace", stepRace)
loop(8, "autoTrade", stepTrade)
loop(4, "autoPowers", stepPowers)
loop(6, "autoRebirth", stepRebirth)
loop(6, "autoEvolve", stepEvolve)
loop(10, "autoAscend", stepAscend)
loop(20, nil, stepCompanions)
loop(15, "autoOrchard", stepOrchard)

task.spawn(function()
	while GEN == _G.__LEMON do
		pcall(refresh)
		pcall(readStreams)
		task.wait(1)
	end
end)

armDrops()
armSpecialIncome()

--------------------------------------------------------------------------------
-- UI (Ivory Hub Sakura Edition)
--------------------------------------------------------------------------------

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

if not Library then
	warn("[Ivory] Library failed to load - aborting")
	return
end

if _G.__LEMON_WIN then
	pcall(function() _G.__LEMON_WIN:Destroy() end)
end

local Window = Library.CreateWindow({Name = "Ivory", Width = 460, Height = 360, Minimizable = true, NotifySide = "Right", ShowCustomCursor = true, CornerRadius = 4})
_G.__LEMON_WIN = Window

local MainTab = Window:CreateTab({Name = "Main"})
local SettingsTab = Window:CreateTab({Name = "Settings"})

local AutoSub = MainTab:CreateSection("Automation")
local FruitSub = MainTab:CreateSection("Fruit")
local PrestigeSub = MainTab:CreateSection("Prestige")
local StatusSub = MainTab:CreateSection("Status")

local TycoonGroup = AutoSub:CreateSection("Tycoon")
local MinigameGroup = AutoSub:CreateSection("Minigames")

TycoonGroup:CreateButton({Name = "Join Discord For Dupe", Callback = function()
	pcall(function() setclipboard("https://discord.gg/ivory") end)
	Library.Notify({Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3})
end})

TycoonGroup:CreateToggle({Name = "Auto Farm", CurrentValue = CONFIG.auto, Callback = function(v)
	CONFIG.auto = v
	STATE.note = v and "running" or "stopped"
end})

TycoonGroup:CreateToggle({Name = "Auto Buy", CurrentValue = CONFIG.autoBuy, Callback = function(v) CONFIG.autoBuy = v end})

TycoonGroup:CreateToggle({Name = "Auto Upgrade", CurrentValue = CONFIG.autoUpgrade, Callback = function(v) CONFIG.autoUpgrade = v end})

TycoonGroup:CreateToggle({Name = "Auto Click Earners", CurrentValue = CONFIG.autoWake, Callback = function(v) CONFIG.autoWake = v end})

TycoonGroup:CreateSlider({Name = "Click Spacing (s)", Range = {5, 100}, Increment = 1, CurrentValue = math.floor((CONFIG.wakeSpacing or 0.15) * 100), Callback = function(v) CONFIG.wakeSpacing = v / 100 end})

MinigameGroup:CreateToggle({Name = "Auto Race", CurrentValue = CONFIG.autoRace, Callback = function(v) CONFIG.autoRace = v end})

MinigameGroup:CreateToggle({Name = "Auto Trade", CurrentValue = CONFIG.autoTrade, Callback = function(v) CONFIG.autoTrade = v end})

MinigameGroup:CreateToggle({Name = "Auto Cash Drops", CurrentValue = CONFIG.autoDrops, Callback = function(v) CONFIG.autoDrops = v end})

MinigameGroup:CreateToggle({Name = "Auto Phone Offers", CurrentValue = CONFIG.autoOffers, Callback = function(v) CONFIG.autoOffers = v end})

MinigameGroup:CreateSlider({Name = "Haggle Raises", Range = {0, 2}, Increment = 1, CurrentValue = CONFIG.offerRaises or 0, Callback = function(v) CONFIG.offerRaises = v end})

local HarvestGroup = FruitSub:CreateSection("Tree Harvest")
local OrchardGroup = FruitSub:CreateSection("Orchard")

HarvestGroup:CreateToggle({Name = "Auto Fruit", CurrentValue = CONFIG.autoFruit, Callback = function(v) CONFIG.autoFruit = v end})

HarvestGroup:CreateSlider({Name = "Fruit Per Sweep", Range = {10, 200}, Increment = 1, CurrentValue = CONFIG.fruitPerSweep or 30, Callback = function(v) CONFIG.fruitPerSweep = v end})

OrchardGroup:CreateToggle({Name = "Auto Orchard", CurrentValue = CONFIG.autoOrchard, Callback = function(v) CONFIG.autoOrchard = v end})

local PowersGroup = PrestigeSub:CreateSection("Powers")
local PrestigeControlGroup = PrestigeSub:CreateSection("Prestige Controls")

PowersGroup:CreateToggle({Name = "Auto Powers", CurrentValue = CONFIG.autoPowers, Callback = function(v) CONFIG.autoPowers = v end})

PowersGroup:CreateToggle({Name = "Buy Manage & WalkSpeed", CurrentValue = CONFIG.buyCosmeticPowers, Callback = function(v) CONFIG.buyCosmeticPowers = v end})

PrestigeControlGroup:CreateToggle({Name = "Auto Rebirth", CurrentValue = CONFIG.autoRebirth, Callback = function(v) CONFIG.autoRebirth = v end})

PrestigeControlGroup:CreateSlider({Name = "Rebirth At (x)", Range = {2, 100}, Increment = 1, CurrentValue = CONFIG.rebirthFactor or 10, Callback = function(v) CONFIG.rebirthFactor = v end})

PrestigeControlGroup:CreateDropdown({Name = "Never Below", Options = { "10", "100", "1000", "10000", "100000" }, CurrentOption = tostring(CONFIG.rebirthMinimum or 100), Callback = function(v) CONFIG.rebirthMinimum = tonumber(v) or 100 end})

PrestigeControlGroup:CreateToggle({Name = "Auto Evolve", CurrentValue = CONFIG.autoEvolve, Callback = function(v) CONFIG.autoEvolve = v end})

PrestigeControlGroup:CreateToggle({Name = "Auto Ascend", CurrentValue = CONFIG.autoAscend, Callback = function(v) CONFIG.autoAscend = v end})

local EconomyGroup = StatusSub:CreateSection("Economy")
local ActivityGroup = StatusSub:CreateSection("Activity")

local MenuGroup = SettingsTab:CreateSection("Menu")

MenuGroup:CreateButton({Name = "Test Notification", Callback = function()
	Library.Notify({Title = "Ivory", Content = "Test notification!", Type = "Info", Duration = 3})
end})

MenuGroup:CreateButton({Name = "Unload", Callback = function()
	Library.Notify({Title = "Ivory", Content = "Unloaded!", Type = "Info", Duration = 2})
	task.wait(1)
	Library:Destroy()
end})

task.spawn(function()
	while GEN == _G.__LEMON do
		local lines = {
			CONFIG.auto and "AUTO RUNNING" or "STOPPED",
			"Cash: " .. fmt(STATE.cash) .. "  Spent: " .. fmt(STATE.spent),
			"Income: " .. short(STATE.incomeRate) .. "/s",
			"Buttons: " .. STATE.purchased .. " / 453  (" .. string.format("%.1f%%", (STATE.ascendProgress or 0) * 100) .. " to ascend)",
			"Investors: " .. fmt(STATE.investors) .. "  Potential: " .. fmt(STATE.potential),
			"Rebirths: " .. STATE.rebirths .. "  Evolution: " .. STATE.evolution .. " (" .. string.format("%.1f%%", (STATE.evolveProgress or 0) * 100) .. ")",
			"Next Buy: " .. tostring(STATE.nextBuy) .. (STATE.nextBuyPrice and ("  " .. fmt(STATE.nextBuyPrice)) or ""),
			"Next Upg: " .. tostring(STATE.nextUpgrade) .. (STATE.nextUpgradePrice and ("  " .. fmt(STATE.nextUpgradePrice) .. "  x" .. tostring(STATE.nextUpgradeCount)) or ""),
			"Next Pow: " .. tostring(STATE.nextPower) .. (STATE.nextPowerPrice and ("  " .. fmt(STATE.nextPowerPrice) .. " investors") or ""),
		}

		local actLines = {
			"Race: " .. (STATE.raceIn > 0 and (math.floor(STATE.raceIn) .. "s") or "ready") .. "  Won: " .. STATE.races .. "  " .. short(STATE.earnedRace),
			"Trade: " .. (STATE.tradeIn > 0 and (math.floor(STATE.tradeIn) .. "s") or "ready") .. "  Closed: " .. STATE.trades .. "  " .. short(STATE.earnedTrade),
			"Drops: " .. STATE.drops .. "  " .. short(STATE.earnedDrop) .. "  Offers: " .. STATE.offers .. "  " .. short(STATE.earnedOffer),
			"Fruit: " .. STATE.fruits .. " picked  " .. short(STATE.earnedFruit) .. "  " .. STATE.fruitRipe .. " ripe",
			"Clicks: " .. STATE.wakes .. " wakes  " .. STATE.upgrades .. " upgrades  " .. STATE.buys .. " buys",
		}

		actLines[#actLines + 1] = STATE.note
		if STATE.blocked then actLines[#actLines + 1] = "Blocked: " .. STATE.blocked end

		pcall(function() EconomyGroup:CreateLabel(table.concat(lines, "\n")) end)
		pcall(function() ActivityGroup:CreateLabel(table.concat(actLines, "\n")) end)

		task.wait(0.5)
	end
end)

_G.__LEMON_DBG = {
	CONFIG = CONFIG, STATE = STATE,
	Huge = Huge, Balance = Balance, Config = Config,
	comp = comp, myTycoon = myTycoon, tycoonRemote = tycoonRemote,
	coreRequest = coreRequest, coreSignal = coreSignal,
	fmt = fmt, toNum = toNum, toHuge = toHuge, atLeast = atLeast,
	nextPurchase = nextPurchase, stepBuy = stepBuy,
	bestUpgrade = bestUpgrade, stepUpgrade = stepUpgrade,
	stepWake = stepWake, readStreams = readStreams,
	ripeFruits = ripeFruits, stepFruit = stepFruit, humanoidRoot = humanoidRoot,
	stepRace = stepRace, stepTrade = stepTrade,
	stepDrops = stepDrops, stepOffer = stepOffer, currentOffer = currentOffer,
	powerState = powerState, stepPowers = stepPowers,
	potentialInvestors = potentialInvestors, shouldRebirth = shouldRebirth,
	stepRebirth = stepRebirth, stepEvolve = stepEvolve, stepAscend = stepAscend,
	stepOrchard = stepOrchard, stepCompanions = stepCompanions,
	refresh = refresh, dropQueue = dropQueue,
}

print("[Ivory] Sell Lemons loaded - gen " .. GEN)
