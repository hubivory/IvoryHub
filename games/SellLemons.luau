--!nocheck
-- SellLemons.luau  --  "Sell Lemons"  (place 79268393072444, BloxByte Games)
--
-- A classic conveyor tycoon: 453 purchase buttons across thirteen areas, eight
-- income streams sitting on top of them, and a Rebirth -> Evolve -> Ascend
-- prestige ladder. Everything below was measured against the server through the
-- game's own client component API, which is the state oracle here:
--
--   local T  = require(ReplicatedStorage.Modules.Tycoon.Tycoon)
--   local lt = T.getLocal()
--   lt:GetComponent(require(ReplicatedStorage.Modules.Tycoon.Component.<X>))
--
-- and it is complete: TycoonBalances (cash, cashSpent, investors, tokens),
-- TycoonAnalyzer (all 453 purchases and all 8 earners, keyed by id, each with a
-- live .Instance), TycoonIncome, TycoonUpgrades, TycoonPowers, TycoonRebirth,
-- TycoonEvolution, TycoonAscension, TycoonPhoneOffers, TycoonCompanions.
--
-- ============================================================================
-- EVERY NUMBER IN THIS GAME IS A log10 FLOAT
-- ============================================================================
-- ReplicatedStorage.Modules.Huge is the game's own big-number library and every
-- currency, price, interval, income value and investor count is stored as its
-- base-10 logarithm. H.zero is -inf and H.one is 0, so a balance of $1 is the
-- number 0 and an empty balance is -inf. Verified:
--     H.toNumber(1.1760912590556813) = 15.0      H.formatTime(...)   = "15s"
--     H.formatAbbreviated(50.50261505280331)     = "318Qnd"
-- Never hand-roll a suffix table and never compare a Huge against a plain
-- number. H.formatAbbreviated is what the panel prints.
--
-- TRAP: the attribute and the component disagree. Values.Values carries
-- Investors = "0" as a STRING while TycoonBalances:GetInvestors() returns -inf.
-- The component is authoritative; the attributes are not.
--
-- TRAP: a purchase model's Name is not its Balance key. The model is called
-- "Lemon Stand", the id in Balance.PurchaseOrder / PurchasePrices is
-- "LemonStand". Only TycoonAnalyzer:GetPurchases() knows the mapping, so this
-- file never derives an id from a name.
--
-- ============================================================================
-- MEASURED, ALL OF IT, WITH THE AUTOMATION OFF
-- ============================================================================
--
--  * THE TYCOON ITSELF HAS NO PROXIMITY CHECK ANYWHERE. A purchase fired from
--    578 studs above the plot went through at the exact quoted price (cash $14
--    -> $8 for the $6 Juicer, Purchased flipped true). Waking a stream from 576
--    studs paid identically to waking it from 9 studs: +$76.28 in the same 10s
--    window, both times. Buying, upgrading, waking, the minigames, the drops
--    and the phone offers all work with the body parked wherever it stands.
--
--  * FRUIT IS THE EXCEPTION, AND IT IS ALSO THE BIGGEST EARNER IN THE GAME.
--    Five clicks on map fruit from 204 studs paid exactly 0. The same five from
--    6.2 studs paid twice. The ClickDetector's MaxActivationDistance is 16 and
--    the server honours it, so this is the one thing here that needs the body
--    moved - which is why harvestFruit() teleports and everything else does not.
--    Worth it: a 25-fruit teleport sweep took 6.6s, 9 of the 25 paid, and the
--    total was $3.21 QUADRILLION - about $483 trillion a second, against roughly
--    $25 billion a second from the trade minigame at the same moment.
--
--  * KLICKEN is earner:WakeAsync() -> TycoonIncome:WakeManualStreamAsync(name).
--    A stream with Automatic = false pays nothing on its own, so early on this
--    is the entire income. Payouts are server rate limited and SUBLINEAR in the
--    number of calls - 6s windows, same stream, $3.81 a payout:
--        0.5s spacing / 12 calls -> 6 payouts      0.1s  /  60 -> 9
--        0.3s spacing / 20 calls -> 7 payouts      0.05s / 120 -> 13
--        0.2s spacing / 30 calls -> 7 payouts
--    A separate 10s window at 0.5s spacing paid 20 times for 20 calls, which
--    only fits a token bucket: full after an idle stretch, burstable once, then
--    refilling at roughly the stream interval. Hammering it is therefore mostly
--    wasted, which is why the default spacing is 0.15s and not 0.
--
--  * VERBESSERN is earner:UpgradeAsync(n) -> the earner's Upgrade
--    RemoteFunction. UpgradeAsync(1) took LemonStand level 1 -> 2, charged
--    exactly the quoted $7.65 and moved the stream value $3.81 -> $5.84.
--    UpgradeAsync(10) DID NOTHING AT ALL - level, cash and stream value all
--    unchanged. The server silently drops any n above Count, and Count comes
--    from GetNextUpgradeInfo() and is driven by the UpgradeStack power (1 while
--    that power is unowned, then 5 / 25 / 100 / inf).
--    Both published scripts get this wrong: one doubles n (1, 2, 4, 8 ...) and
--    the other loops i = 1..10. Only the n = 1 call ever lands, and because the
--    remote answers without erroring their pcall still reports success.
--
--  * THE POWERS ARE PRICED IN INVESTORS, NOT CASH. Attempting Manage with $647
--    in the bank and zero investors answered, verbatim:
--        ServerTycoonPowers:130: insufficient investors
--    Tokens (25 on a fresh save) are not the powers currency either. Investors
--    come out of Rebirth, so Rebirth gates the powers and the powers gate
--    everything else. Investors are CONSUMED, not just required - buying one
--    took the balance 176 -> 76. Config.Powers prices, in investors:
--        Manage           100                     (no Bonuses table)
--        ClickFruitValue  250 / 1e6 / 1e18        Amt 2/4/6, Mult 2/4/8
--        WalkSpeed        400 / 1e9 / 1e27 / 1e72 1.5 / 2 / 3 / 4
--        UpgradeStack     1e3 / 1e12 / 1e33 / 1e63  Count 5 / 25 / 100 / inf
--        BuyNext          1e38 / 1e67 / 1e93      150 / 250 / inf
--        AutoFruit        1e42
--    Each one also carries a DevProductID, which is the Robux shortcut. This
--    file only ever spends investors.
--
--  * MANAGE IS 100 INVESTORS FOR A HUD TAB. It was bought to find out: level
--    0 -> 1, investors 176 -> 76, and nothing else moved - no stream turned
--    automatic, the upgrade Count stayed 1, income was unchanged. A getgc sweep
--    for the string finds it referenced only by UI.Layers.Manage.UIManageMenu
--    and the orchard billboard. It is a menu unlock, so this file skips it.
--
--  * REBIRTH, MEASURED END TO END. 93 buttons and $558Qn with 175 potential
--    investors went to 3 buttons, $31 and 176 investors, rebirths 0 -> 1. It
--    wipes the purchases and the balance and pays out the potential in full.
--
--  * THE TRADE MINIGAME IS THE BIGGEST LEVER IN THE GAME.
--    MinigameTradeService.Start returns {MaxEarnings, StartingCash, LineConfig}
--    where MaxEarnings is the server's own statement of a perfect run. Passing
--    that number straight back to .End paid +$7,548,571,798 in one call (cash
--    $368M -> $7.92B). 300s cooldown. This script submits the announced
--    MaxEarnings and nothing above it - that is playing the round perfectly,
--    not inventing a result.
--
--  * THE RACE MINIGAME PAYS ON A CLIENT-SUPPLIED PLACEMENT.
--    Config.MinigameRacePlacementCash = {[1] = 1, [2] = 0.5, [3] = 0.25,
--    [4] = 0}. Start returns the full prize up front, End(n) pays prize *
--    factor[n]. End(1) paid the announced $229 in full ($8 -> $237). 300s.
--
--  * CASH DROPS ARE REDEEMED BY ID AND TOUCHING THEM DOES NOTHING.
--    RemoteSignal "DropService.New" fires (id, kind, lifetime) - measured
--    ("994", "Cash", 1200). RemoteRequest "DropService.Redeem":InvokeServer(id)
--    answered 12.798968597564983, which is $6.3 TRILLION. Dragging the body
--    through the CashDrop part in workspace.Drops left it sitting there.
--    NOTE: the most-viewed published script listens on "CashDropService.New"
--    and "CashDropService.Redeem", neither of which exists in this place. Its
--    drop collector is dead code.
--
--  * PHONE OFFERS CAN BE HAGGLED, AND HAGGLING TOO HARD LOSES THEM.
--    The offer arrives on the tycoon's PhoneOffer RemoteEvent as a Huge number.
--    PhoneOffers:RaiseOffer() raised one from $12.336B -> $17.275B (+40%) and
--    then -> $19.088B (+10%). The THIRD raise returned the offer as nil - the
--    deal was gone. Measured once, so it is probably a per-raise roll; the
--    default here is one raise and the stepper stops at two.
--
--  * A FRUIT IS RIPE EXACTLY WHEN IT STILL HAS ITS ClickFruitPart.
--    Around 820 parts carry the ClickFruit tag across the whole map. A ripe one
--    is Transparency 0 and owns Fruit.ClickFruitPart.ClickDetector; a harvested
--    one is Transparency 1 and the ClickFruitPart is gone entirely, so the
--    presence of that child IS the ripeness test and nothing else has to be
--    read. They regrow on their own.
--    That test is what fixed the first version of this file: it filtered to the
--    player's own tycoon, and after one sweep all 36 fruits there were
--    transparent and detector-less while 448 ripe ones stood on the map trees
--    being ignored. Own plot, map trees and other players' plots all pay - the
--    only thing that matters is the detector and standing next to it.
--
--  * SpecialIncome IS THE PAYOUT ORACLE. The tycoon's SpecialIncome RemoteEvent
--    fires (sourceName, hugeAmount) for every one-off payout - "ClickFruit",
--    "MinigameRace" and so on. That is how this file reports what each feature
--    actually earned instead of guessing from the balance.
--
--  * THE PRESTIGE FORMULAS, read off the components:
--      GetPotentialInvestors = investors + cashToNewInvestors(cash + cashSpent)
--        with Balance.RebirthParameters.Investors = {1.8e17, 0.44}. Spending is
--        therefore never a loss - cashSpent counts towards the next rebirth
--        exactly as unspent cash does, which is why this file spends freely.
--      GetEvolutionProgress = (investors + investorsSpent + potential)
--                             / nextEvolutionInvestors(evolution), evolve at 1.
--      GetAscensionProgress = purchasedCount / 453, ascend at 1.
--      Rebirth / Evolve / Ascend all take NO arguments.
--      Config: EvolutionMultiplier 42, AscensionMultiplier 7.77,
--              AscensionPenalty 3.33, BaseInvestorBonus 0.01.
--
-- ============================================================================
-- NEVER TOUCHED
-- ============================================================================
--  * Purchase:InvokeServer(true) - the "forever purchase". Config.Products
--    lists PermanentPurchase with DevProductID 3558362570, so the published
--    scripts' "Use Forever Purchase" option is a Robux prompt. This file always
--    calls TryPurchaseAsync(), which sends no argument.
--  * earner:PromptBoostAsync() / GetBoostProductName() - EarnerBoost1..8, Robux.
--  * UseTimeCash / UseEarnerBoost / DoubleOfflineCash / FreeRebirth /
--    FreeEvolve / InvestorBoost / RateBoost - every one of them is a DevProduct.
--  * VideoAdService.ShowAd - free, but it plays a real rewarded video at the
--    player. Left out rather than made a surprise.
--  * Core.AdminService.RunCommandRemote - present, never fired.
--
-- ============================================================================
-- UNVERIFIED, AND SAID SO IN THE PANEL
-- ============================================================================
-- The whole Orchard subsystem is gated behind Config.Orchard.UnlockCashPrice =
-- 1e25 and the test account never got within twelve orders of magnitude of it,
-- so none of the orchard code below has ever been executed against a live
-- server. It is written from the module API (OrchardPlot.States = Empty 0,
-- TreeGrowing 1, FruitGrowing 2, FruitReady 3; RemoteRequest OrchardPlot.Plant
-- / .Harvest / .GetFruit / .UseItem / .SellUpgrade / .DestroyTree; the tycoon's
-- UnlockOrchard / UnlockPlot / SellFruits / EatFruit remotes) and it ships OFF.
-- Treat anything it reports as a claim, not a measurement.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local plr = Players.LocalPlayer

--------------------------------------------------------------------------------
-- config / state
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- module access
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Huge helpers
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- the tycoon and its components
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- oracle reads
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- KAUFEN - the 453-button ladder
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- VERBESSERN - the earner upgrades
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- KLICKEN - waking the manual streams
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- fruit
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- the two minigames
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- cash drops
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- phone offers
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- powers - the investor spend
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- prestige
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- companions
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- orchard - UNVERIFIED
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- the SpecialIncome tap
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- state refresh
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- loops
--------------------------------------------------------------------------------

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
-- ObsidianUltra UI
--------------------------------------------------------------------------------

local function httpGet(url)
	local ok, res = pcall(function()
		return request({ Url = url, Method = "GET" })
	end)
	if ok and res and res.Body then
		local body = res.Body
		if body:byte(1) == 0xEF and body:byte(2) == 0xBB and body:byte(3) == 0xBF then
			body = body:sub(4)
		end
		return body
	end
	return nil
end

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local genv = getgenv()

local oldCloneref = genv.cloneref
genv.cloneref = function(obj)
	if typeof(obj) == "Instance" then return obj end
	if obj == nil then return nil end
	return obj
end

local libSrc = genv._IvoryLibSrc or httpGet(repo .. "Library.lua")
local tmSrc = genv._IvoryTMSrc or httpGet(repo .. "addons/ThemeManager.lua")
local smSrc = genv._IvorySMSrc or httpGet(repo .. "addons/SaveManager.lua")

local Library, ThemeManager, SaveManager

if libSrc then
	local ls, le = loadstring(libSrc)
	if ls then
		local ok, lib = pcall(ls)
		if ok then Library = lib end
		if not ok then warn("[Ivory] Library init failed:", lib) end
	else
		warn("[Ivory] Library compile failed:", le)
	end
end

if not Library then
	warn("[Ivory] ObsidianUltra failed to load - aborting")
	return
end

if tmSrc then
	local ls = loadstring(tmSrc)
	if ls then
		local ok, tm = pcall(ls)
		if ok then ThemeManager = tm end
	end
end

if smSrc then
	local ls = loadstring(smSrc)
	if ls then
		local ok, sm = pcall(ls)
		if ok then SaveManager = sm end
	end
end

genv.cloneref = oldCloneref

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("game")

if _G.__LEMON_WIN then
	pcall(function() _G.__LEMON_WIN:Destroy() end)
end

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.4 |",
		{ Text = "Game", Copyable = true },
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
--// Patch window icon to use custom image
local IVORY_ICON = "rbxassetid://113133903091338"
task.spawn(function()
	task.wait()
	local function trySetIcon(parent)
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("ImageLabel") and obj.Size.X.Offset >= 20 and obj.Size.X.Offset <= 40 and obj.Size.Y.Offset >= 20 and obj.Size.Y.Offset <= 40 then
						local par = obj.Parent
						if par then
							for _, sib in ipairs(par:GetChildren()) do
								if sib:IsA("TextLabel") and sib.Text == "Ivory" then
									obj.Image = IVORY_ICON
									obj.ImageRectOffset = Vector2.new(0, 0)
									obj.ImageRectSize = Vector2.new(0, 0)
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end
	pcall(function() trySetIcon(CoreGui) end)
	pcall(function() trySetIcon(LocalPlayer.PlayerGui) end)
end)
_G.__LEMON_WIN = Window

--------------------------------------------------------------------------------
-- tabs & sub-tabs
--------------------------------------------------------------------------------

local MainTab = Window:AddTab({ Name = "Main", Icon = "swords" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "swords" })

local AutoSub = MainTab:AddSubTab("Automation", "rbxassetid://113133903091338")
local FruitSub = MainTab:AddSubTab("Fruit", "rbxassetid://113133903091338")
local PrestigeSub = MainTab:AddSubTab("Prestige", "rbxassetid://113133903091338")
local StatusSub = MainTab:AddSubTab("Status", "rbxassetid://113133903091338")

--------------------------------------------------------------------------------
-- Automation: Tycoon
--------------------------------------------------------------------------------

local TycoonGroup = AutoSub:AddLeftGroupbox("Tycoon", "cpu")
local MinigameGroup = AutoSub:AddRightGroupbox("Minigames", "gamepad")

TycoonGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() setclipboard("https://discord.gg/ivory") end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 })
end)

TycoonGroup:AddToggle("AutoFarm", {
	Text = "Auto Farm",
	Default = CONFIG.auto,
	Callback = function(v)
		CONFIG.auto = v
		STATE.note = v and "running" or "stopped"
	end,
}):AddKeyPicker("AutoFarmKey", {
	Default = "None", Text = "Auto Farm Key", Mode = "Toggle", SyncToggleState = true, NoUI = false,
})

TycoonGroup:AddToggle("AutoBuy", {
	Text = "Auto Buy",
	Default = CONFIG.autoBuy,
	Callback = function(v) CONFIG.autoBuy = v end,
})

TycoonGroup:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = CONFIG.autoUpgrade,
	Callback = function(v) CONFIG.autoUpgrade = v end,
})

TycoonGroup:AddToggle("AutoWake", {
	Text = "Auto Click Earners",
	Default = CONFIG.autoWake,
	Callback = function(v) CONFIG.autoWake = v end,
})

TycoonGroup:AddSlider("WakeSpacing", {
	Text = "Click Spacing (s)",
	Default = math.floor((CONFIG.wakeSpacing or 0.15) * 100),
	Min = 5,
	Max = 100,
	Rounding = 0,
	Callback = function(v) CONFIG.wakeSpacing = v / 100 end,
})

--------------------------------------------------------------------------------
-- Automation: Minigames
--------------------------------------------------------------------------------

MinigameGroup:AddToggle("AutoRace", {
	Text = "Auto Race",
	Default = CONFIG.autoRace,
	Callback = function(v) CONFIG.autoRace = v end,
})

MinigameGroup:AddToggle("AutoTrade", {
	Text = "Auto Trade",
	Default = CONFIG.autoTrade,
	Callback = function(v) CONFIG.autoTrade = v end,
})

MinigameGroup:AddToggle("AutoDrops", {
	Text = "Auto Cash Drops",
	Default = CONFIG.autoDrops,
	Callback = function(v) CONFIG.autoDrops = v end,
})

MinigameGroup:AddToggle("AutoOffers", {
	Text = "Auto Phone Offers",
	Default = CONFIG.autoOffers,
	Callback = function(v) CONFIG.autoOffers = v end,
})

MinigameGroup:AddSlider("OfferRaises", {
	Text = "Haggle Raises",
	Default = CONFIG.offerRaises or 0,
	Min = 0,
	Max = 2,
	Rounding = 0,
	Callback = function(v) CONFIG.offerRaises = v end,
})

--------------------------------------------------------------------------------
-- Fruit: Harvest
--------------------------------------------------------------------------------

local HarvestGroup = FruitSub:AddLeftGroupbox("Tree Harvest", "tree")
local OrchardGroup = FruitSub:AddRightGroupbox("Orchard", "flower")

HarvestGroup:AddToggle("AutoFruit", {
	Text = "Auto Fruit",
	Default = CONFIG.autoFruit,
	Callback = function(v) CONFIG.autoFruit = v end,
})

HarvestGroup:AddSlider("FruitPerSweep", {
	Text = "Fruit Per Sweep",
	Default = CONFIG.fruitPerSweep or 30,
	Min = 10,
	Max = 200,
	Rounding = 0,
	Callback = function(v) CONFIG.fruitPerSweep = v end,
})

OrchardGroup:AddToggle("AutoOrchard", {
	Text = "Auto Orchard",
	Default = CONFIG.autoOrchard,
	Callback = function(v) CONFIG.autoOrchard = v end,
})

local orchardStatusLabel = OrchardGroup:AddLabel("Status: off (unverified)")

OrchardGroup:AddLabel("UNVERIFIED - never reached in testing")
OrchardGroup:AddLabel("Robux is never touched: no boosts, no forever purchase")

--------------------------------------------------------------------------------
-- Prestige: Powers
--------------------------------------------------------------------------------

local PowersGroup = PrestigeSub:AddLeftGroupbox("Powers", "shield")
local PrestigeControlGroup = PrestigeSub:AddRightGroupbox("Prestige Controls", "refresh-cw")

PowersGroup:AddToggle("AutoPowers", {
	Text = "Auto Powers",
	Default = CONFIG.autoPowers,
	Callback = function(v) CONFIG.autoPowers = v end,
})

PowersGroup:AddToggle("BuyCosmeticPowers", {
	Text = "Buy Manage & WalkSpeed",
	Default = CONFIG.buyCosmeticPowers,
	Callback = function(v) CONFIG.buyCosmeticPowers = v end,
})

local nextPowerLabel = PowersGroup:AddLabel("Next Power: -")

--------------------------------------------------------------------------------
-- Prestige: Controls
--------------------------------------------------------------------------------

PrestigeControlGroup:AddToggle("AutoRebirth", {
	Text = "Auto Rebirth",
	Default = CONFIG.autoRebirth,
	Callback = function(v) CONFIG.autoRebirth = v end,
})

PrestigeControlGroup:AddSlider("RebirthFactor", {
	Text = "Rebirth At (x)",
	Default = CONFIG.rebirthFactor or 10,
	Min = 2,
	Max = 100,
	Rounding = 0,
	Callback = function(v) CONFIG.rebirthFactor = v end,
})

PrestigeControlGroup:AddDropdown("RebirthMinimum", {
	Values = { "10", "100", "1000", "10000", "100000" },
	Default = tostring(CONFIG.rebirthMinimum or 100),
	Text = "Never Below",
	Callback = function(v) CONFIG.rebirthMinimum = tonumber(v) or 100 end,
})

PrestigeControlGroup:AddToggle("AutoEvolve", {
	Text = "Auto Evolve",
	Default = CONFIG.autoEvolve,
	Callback = function(v) CONFIG.autoEvolve = v end,
})

PrestigeControlGroup:AddToggle("AutoAscend", {
	Text = "Auto Ascend",
	Default = CONFIG.autoAscend,
	Callback = function(v) CONFIG.autoAscend = v end,
})

--------------------------------------------------------------------------------
-- Status
--------------------------------------------------------------------------------

local EconomyGroup = StatusSub:AddLeftGroupbox("Economy", "dollar-sign")
local ActivityGroup = StatusSub:AddRightGroupbox("Activity", "bar-chart")

local statusLabel = EconomyGroup:AddLabel("Loading...")
local streamLabel = ActivityGroup:AddLabel("No streams yet")
local counterLabel = ActivityGroup:AddLabel("...")

--------------------------------------------------------------------------------
-- Settings
--------------------------------------------------------------------------------

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "settings")

MenuGroup:AddToggle("MenuToggle", {
	Text = "Toggle Menu",
	Default = false,
}):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	Text = "Menu Keybind",
	Mode = "Toggle",
	SyncToggleState = false,
	NoUI = false,
})

MenuGroup:AddToggle("CustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(v) Library.ShowCustomCursor = v end,
})

MenuGroup:AddButton("Test Notification", function()
	Library:Notify({ Title = "Ivory", Description = "Test notification!", Type = "Info", Time = 3 })
end)

MenuGroup:AddDropdown("NotifySide", {
	Values = { "Right", "Left" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(v) Library.NotifySide = v end,
})

MenuGroup:AddDropdown("DPIScale", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(v)
		local scale = tonumber(v:gsub("%%", "")) / 100
		Library.DPI = scale
	end,
})

MenuGroup:AddSlider("CornerRadius", {
	Text = "Corner Radius",
	Default = 4,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(v) Library.CornerRadius = v end,
})

MenuGroup:AddButton("Unload", function()
	Library:Notify({ Title = "Ivory", Description = "Unloaded!", Type = "Info", Time = 2 })
	task.wait(1)
	Library:Destroy()
end)

--------------------------------------------------------------------------------
-- status update loop
--------------------------------------------------------------------------------

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

		pcall(function() statusLabel.Text = table.concat(lines, "\n") end)

		local actLines = {
			"Race: " .. (STATE.raceIn > 0 and (math.floor(STATE.raceIn) .. "s") or "ready") .. "  Won: " .. STATE.races .. "  " .. short(STATE.earnedRace),
			"Trade: " .. (STATE.tradeIn > 0 and (math.floor(STATE.tradeIn) .. "s") or "ready") .. "  Closed: " .. STATE.trades .. "  " .. short(STATE.earnedTrade),
			"Drops: " .. STATE.drops .. "  " .. short(STATE.earnedDrop) .. "  Offers: " .. STATE.offers .. "  " .. short(STATE.earnedOffer),
			"Fruit: " .. STATE.fruits .. " picked  " .. short(STATE.earnedFruit) .. "  " .. STATE.fruitRipe .. " ripe",
			"Clicks: " .. STATE.wakes .. " wakes  " .. STATE.upgrades .. " upgrades  " .. STATE.buys .. " buys",
		}

		local streamLine = "Streams: "
		local shown = 0
		for _, row in ipairs(STATE.streams or {}) do
			if shown < 3 and not hugeIsZero(row.value) then
				streamLine = streamLine .. row.id .. " " .. fmt(row.value) .. "/" .. fmtTime(row.interval) .. (row.auto and "(a) " or "(m) ")
				shown = shown + 1
			end
		end
		if shown > 0 then actLines[#actLines + 1] = streamLine end

		if STATE.orchardUnlocked or CONFIG.autoOrchard then
			actLines[#actLines + 1] = "Orchard: " .. tostring(STATE.orchardNote)
		end

		actLines[#actLines + 1] = STATE.note
		if STATE.blocked then actLines[#actLines + 1] = "Blocked: " .. STATE.blocked end

		pcall(function() streamLabel.Text = table.concat(actLines, "\n") end)
		pcall(function() counterLabel.Text = "Buys: " .. STATE.buys .. "  Upgrades: " .. STATE.upgrades .. "  Wakes: " .. STATE.wakes .. "  Fruits: " .. STATE.fruits .. "  Powers: " .. STATE.powerBuys end)
		pcall(function() nextPowerLabel.Text = "Next Power: " .. tostring(STATE.nextPower) .. (STATE.nextPowerPrice and (" (" .. fmt(STATE.nextPowerPrice) .. " investors)") or "") end)
		pcall(function() orchardStatusLabel.Text = "Status: " .. tostring(STATE.orchardNote) end)

		task.wait(0.5)
	end
end)

--------------------------------------------------------------------------------

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
