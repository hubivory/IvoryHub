--// Rocks RNG - Crash Value Tracker & Multi-Feature Hub
--// Ivory Hub integration using Ivory Hub Sakura Edition

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local LocalPlayer = Players.LocalPlayer

local RE = ReplicatedStorage:WaitForChild("ReplicatedStorageHolders"):WaitForChild("RE")
local MiningReveal = RE:WaitForChild("MiningReveal")
local MiningRoll = RE:WaitForChild("MiningRoll")

--// Cleanup previous instance
if getgenv().RocksCrashTracker then
	pcall(function() getgenv().RocksCrashTracker.window:Destroy() end)
	pcall(function() getgenv().RocksCrashTracker.rollConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.revealConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.assistConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.autoLoopRollConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.shardSyncConn:Disconnect() end)
	pcall(function() task.cancel(getgenv().RocksCrashTracker.autoCollectWorker) end)
	pcall(function() task.cancel(getgenv().RocksCrashTracker.shardSyncWatchdog) end)
	pcall(function() getgenv().RocksCrashTracker.shopCurrencyConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.shopStateConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.shopRuneConn:Disconnect() end)
	pcall(function() task.cancel(getgenv().RocksCrashTracker.shopLoopThread) end)
	pcall(function() getgenv().RocksCrashTracker.serverEventConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.luckBoostConn:Disconnect() end)
	pcall(function() task.cancel(getgenv().RocksCrashTracker.eventsLoopThread) end)
	pcall(function() getgenv().RocksCrashTracker.discoveredConn:Disconnect() end)
	pcall(function() getgenv().RocksCrashTracker.indexStarsConn:Disconnect() end)
	pcall(function() task.cancel(getgenv().RocksCrashTracker.starClaimLoopThread) end)
	pcall(function() getgenv().RocksCrashTracker.tradeStateConn:Disconnect() end)
	pcall(function() task.cancel(getgenv().RocksCrashTracker.plotOptimizeLoopThread) end)
	pcall(function() getgenv().RocksCrashTracker.rockInventoryConn:Disconnect() end)
end
getgenv().RocksCrashTracker = {}

--// Load Ivory Hub
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
	warn("[Rocks RNG] Ivory Hub failed to load")
	return
end

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 460,
	Height = 360,
})
getgenv().RocksCrashTracker.window = Window

--// ========================================================
--// UTILITY
--// ========================================================

local rollHistory = {}
getgenv().RocksCrashTracker.rollHistory = rollHistory

local function safeNum(v, fallback)
	return (type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge) and v or fallback
end

local function get_crash_value(payload)
	local X3 = safeNum(payload.X3, 10)
	local crash = safeNum(payload.crash, X3)
	return crash, (payload.crash ~= nil and payload.crash == crash)
end

--// ========================================================
--// TAB 1: CRASH TRACKER
--// ========================================================

local CrashTab = Window:CreateTab({ Name = "Crash Tracker" })
local CrashSub = CrashTab:CreateSection("Live Data")
local CrashSub2 = CrashTab:CreateSection("Session")

local CG1 = CrashSub:CreateSection("Live Crash Value")
local CrashLabel = CG1:CreateLabel("Crash: waiting for a roll...")
local DetailLabel = CG1:CreateLabel("X1: -- | X2: -- | X3: --")
local SourceLabel = CG1:CreateLabel("Source: --")
local RarestLabel = CG1:CreateLabel("Rarest bucket: --")

local CG2 = CrashSub2:CreateSection("Session Stats")
local StatsLabel = CG2:CreateLabel("Rolls: 0 | Avg: -- | Max: -- | Min: --")

local function update_stats_ui()
	local n = #rollHistory
	if n == 0 then
		StatsLabel:SetText("Rolls: 0 | Avg: -- | Max: -- | Min: --")
		return
	end
	local sum, maxC, minC = 0, -math.huge, math.huge
	for _, entry in ipairs(rollHistory) do
		sum = sum + entry.crash
		maxC = math.max(maxC, entry.crash)
		minC = math.min(minC, entry.crash)
	end
	StatsLabel:SetText(string.format("Rolls: %d | Avg: %.4fx | Max: %.4fx | Min: %.4fx",
		n, sum / n, maxC, minC))
end

local CG3 = CrashSub2:CreateSection("Actions")
CG3:CreateButton({
	Name = "Print Full History",
	Callback = function()
		_G.PrintCrashHistory()
	end,
})
CG3:CreateButton({
	Name = "Reset Session Stats",
	Callback = function()
		table.clear(rollHistory)
		StatsLabel:SetText("Rolls: 0 | Avg: -- | Max: -- | Min: --")
		Library.Notify({ Title = "Crash Tracker", Content = "Session stats reset", Type = "Info", Duration = 2 })
	end,
})

--// Hook MiningRoll
local rollCount = 0
local rollConn = MiningRoll.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	rollCount = rollCount + 1
	local crash, fromExplicitField = get_crash_value(payload)

	print(string.format("[RocksRNG] Roll #%d received: crash=%.6f explicit=%s X3=%s bucketMins=%s",
		rollCount, crash, tostring(fromExplicitField),
		tostring(payload.X3),
		type(payload.bucketMins) == "table" and tostring(#payload.bucketMins) or "none"))

	local ok1, e1 = pcall(function()
		CrashLabel:SetText(string.format("Crash: %.4fx", crash))
	end)
	if not ok1 then warn("[RocksRNG] CrashLabel:SetText failed: " .. tostring(e1)) end

	local ok2, e2 = pcall(function()
		DetailLabel:SetText(string.format("X1: %s | X2: %s | X3: %s",
			tostring(payload.X1), tostring(payload.X2), tostring(payload.X3)))
	end)
	if not ok2 then warn("[RocksRNG] DetailLabel:SetText failed: " .. tostring(e2)) end

	local ok3, e3 = pcall(function()
		SourceLabel:SetText("Source: " .. (fromExplicitField and "payload.crash" or "fallback -> X3/10"))
	end)
	if not ok3 then warn("[RocksRNG] SourceLabel:SetText failed: " .. tostring(e3)) end

	if type(payload.bucketMins) == "table" and #payload.bucketMins > 0 then
		local rarestMin = nil
		for i = #payload.bucketMins, 1, -1 do
			local val = payload.bucketMins[i]
			if type(val) == "number" and val > 0 and val < crash then
				rarestMin = val
				break
			end
		end
		if rarestMin and crash > 0 then
			local rarestProb = (crash - rarestMin) / crash
			rarestProb = math.clamp(rarestProb, 0, 1)
			local ok4, e4 = pcall(function()
				RarestLabel:SetText(string.format("Starts at: %.4f | Odds: %.4f%% (1 in %.0f)",
					rarestMin, rarestProb * 100, rarestProb > 0 and 1 / rarestProb or math.huge))
			end)
			if not ok4 then warn("[RocksRNG] RarestLabel:SetText failed: " .. tostring(e4)) end
		else
			local ok4, e4 = pcall(function()
				RarestLabel:SetText("Rarest bucket: no valid bucket below crash")
			end)
			if not ok4 then warn("[RocksRNG] RarestLabel:SetText failed: " .. tostring(e4)) end
		end
	else
		local ok4, e4 = pcall(function()
			RarestLabel:SetText("Rarest bucket: no data")
		end)
		if not ok4 then warn("[RocksRNG] RarestLabel:SetText failed: " .. tostring(e4)) end
	end

	table.insert(rollHistory, {
		tick = tick(),
		crash = crash,
		X1 = payload.X1,
		X2 = payload.X2,
		X3 = payload.X3,
	})
	update_stats_ui()
	print(string.format("[ROLL] crash=%.6f (explicit field: %s)", crash, tostring(fromExplicitField)))
end)
getgenv().RocksCrashTracker.rollConn = rollConn

local revealConn = MiningReveal.OnClientEvent:Connect(function(...)
	print("[REVEAL] MiningReveal fired! (rolls tracked so far: " .. #rollHistory .. ")")
end)
getgenv().RocksCrashTracker.revealConn = revealConn

--// ========================================================
--// TAB 2: CASH-OUT ASSIST
--// ========================================================

local AssistTab = Window:CreateTab({ Name = "Cash-Out Assist" })
local AssistSub = AssistTab:CreateSection("Suggestion")
local AG1 = AssistSub:CreateSection("Suggested Cash-Out")

local AssistCrashLabel = AG1:CreateLabel("Crash: waiting for a roll...")
local AssistSuggestLabel = AG1:CreateLabel("Suggested target: --")
AG1:CreateLabel("Suggestion only. Nothing is auto-filled or auto-toggled. Copy the value below and paste it into the game's own \"Auto Roll\" box yourself, then flip Auto Roll on if you want it. Target = crash - 1 (one under the ceiling for that roll).")

local lastSuggested = nil

local function copy_to_clipboard(text)
	return pcall(function()
		if setclipboard then
			setclipboard(text)
		elseif toclipboard then
			toclipboard(text)
		elseif Clipboard and Clipboard.set then
			Clipboard.set(text)
		else
			error("no clipboard function available on this executor")
		end
	end)
end

AG1:CreateButton({
	Name = "Copy Suggested Value",
	Callback = function()
		if not lastSuggested then
			Library.Notify({ Title = "Cash-Out Assist", Content = "Wait for a roll first.", Type = "Warning", Duration = 3 })
			return
		end
		local text = string.format("%.4f", lastSuggested)
		if copy_to_clipboard(text) then
			Library.Notify({ Title = "Cash-Out Assist", Content = "Copied: " .. text, Type = "Success", Duration = 3 })
		else
			print("[Cash-Out Assist] Suggested value (clipboard unsupported): " .. text)
			Library.Notify({ Title = "Cash-Out Assist", Content = "Clipboard unsupported, printed to console", Type = "Warning", Duration = 4 })
		end
	end,
})

local assistConn = MiningRoll.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	local crash = get_crash_value(payload)
	local suggested = math.max(crash - 1, 1)
	lastSuggested = suggested
	AssistCrashLabel:SetText(string.format("Crash: %.4fx", crash))
	AssistSuggestLabel:SetText(string.format("Suggested target: %.4fx (crash - 1)", suggested))
end)
getgenv().RocksCrashTracker.assistConn = assistConn

--// ========================================================
--// TAB 3: AUTO-LOOP
--// ========================================================

local AutoLoopTab = Window:CreateTab({ Name = "Auto-Loop" })
local AutoLoopSub = AutoLoopTab:CreateSection("Auto-Fill")
local ALG1 = AutoLoopSub:CreateSection("Auto-Fill Auto-Roll")

local AutoLoopEnabled = false
local AutoLoopStatusLabel = ALG1:CreateLabel("Status: idle")
local AutoLoopCrashLabel = ALG1:CreateLabel("Crash: --")
local AutoLoopTargetLabel = ALG1:CreateLabel("Target: --")

ALG1:CreateLabel("When enabled, automatically fills the game's \"Auto Roll\" input box with crash - 1 on every roll. You still need to manually enable/disable the game's Auto Roll toggle yourself. This only changes the VALUE.")

ALG1:CreateToggle({
	Name = "Auto-fill cash-out target",
	CurrentValue = false,
	Callback = function(Value)
		AutoLoopEnabled = Value
		AutoLoopStatusLabel:Set(Value and "Status: ENABLED" or "Status: disabled")
	end,
})

ALG1:CreateButton({
	Name = "Scan PlayerGui for TextBoxes",
	Callback = function()
		print("\n[Auto-Loop] Scanning entire PlayerGui for TextBoxes...")
		print(string.rep("=", 70))
		local found_any = false
		for _, obj in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
			if obj:IsA("TextBox") then
				found_any = true
				print(string.format("TextBox: %s", obj:GetFullName()))
				print(string.format("  PlaceholderText: %s", obj.PlaceholderText or "none"))
				print(string.format("  CurrentValue: %s", obj.Text or "empty"))
				print()
			end
		end
		print(string.rep("=", 70))
		if not found_any then
			print("[Auto-Loop] No TextBoxes found in PlayerGui at all.")
		end
		print()
	end,
})

local function find_autoroll_input()
	local miningAuto = LocalPlayer.PlayerGui:FindFirstChild("MiningAuto")
	if not miningAuto then return nil end
	local autoBar = miningAuto:FindFirstChild("AutoBar")
	if not autoBar then return nil end
	local label = autoBar:FindFirstChild("Label")
	if label and label:IsA("TextBox") then return label end
	return nil
end

local function force_fire_focuslost(textBox)
	if type(firesignal) == "function" then
		local ok = pcall(firesignal, textBox.FocusLost, true)
		if ok then return true, "firesignal" end
	end
	if type(getconnections) == "function" then
		local ok = pcall(function()
			local conns = getconnections(textBox.FocusLost)
			if #conns == 0 then error("no connections found") end
			for _, conn in ipairs(conns) do conn:Fire(true) end
		end)
		if ok then return true, "getconnections():Fire()" end
	end
	if type(getconnections) == "function" then
		local ok = pcall(function()
			local conns = getconnections(textBox.FocusLost)
			if #conns == 0 then error("no connections found") end
			for _, conn in ipairs(conns) do conn.Function() end
		end)
		if ok then return true, "getconnections().Function()" end
	end
	if type(replicatesignal) == "function" then
		local ok = pcall(replicatesignal, textBox.FocusLost)
		if ok then return true, "replicatesignal" end
	end
	return false, nil
end

local loggedCapability = false

local autoLoopRollConn = MiningRoll.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	if not AutoLoopEnabled then return end

	local crash = get_crash_value(payload)
	local target = math.max(crash - 1, 1)
	local targetWhole = math.floor(target)

	AutoLoopCrashLabel:SetText(string.format("Crash: %.4fx", crash))
	AutoLoopTargetLabel:SetText(string.format("Target: %d (%.4f rounded down)", targetWhole, target))
	AutoLoopStatusLabel:SetText("Status: updating value...")

	task.wait(0.05)
	local autorollBox = find_autoroll_input()

	if not autorollBox then
		AutoLoopStatusLabel:SetText("Status: TextBox not found")
		return
	end

	if not loggedCapability then
		loggedCapability = true
		print(string.format("[Auto-Loop] firesignal: %s | getconnections: %s | replicatesignal: %s",
			tostring(type(firesignal) == "function"),
			tostring(type(getconnections) == "function"),
			tostring(type(replicatesignal) == "function")))
	end

	autorollBox.Text = tostring(targetWhole)
	local fired, method = force_fire_focuslost(autorollBox)

	if fired then
		AutoLoopStatusLabel:SetText(string.format("Status: committed %d (%s)", targetWhole, method))
		print(string.format("[Auto-Loop] Forced FocusLost via %s with value %d (crash %.4f - 1)", method, targetWhole, crash))
	else
		AutoLoopStatusLabel:SetText("Status: executor lacks firesignal/getconnections")
		print("[Auto-Loop] ERROR: Executor does not expose firesignal or getconnections")
	end
end)
getgenv().RocksCrashTracker.autoLoopRollConn = autoLoopRollConn

--// ========================================================
--// TAB 4: AUTO COLLECT
--// ========================================================

local AutoCollectTab = Window:CreateTab({ Name = "Auto Collect" })
local AutoCollectSub = AutoCollectTab:CreateSection("Shards")
local ACG1 = AutoCollectSub:CreateSection("Auto Collect Shards")

local AutoCollectEnabled = false
local AutoCollectStatusLabel = ACG1:CreateLabel("Status: idle")
local AutoCollectCountLabel = ACG1:CreateLabel("Collected: 0")

ACG1:CreateLabel("Hooks the game's own ShardSync/CollectCrystal remotes (the same ones the real Auto Collect gamepass uses) and collects every synced crystal shard immediately, instead of waiting for the player to walk within range.")

ACG1:CreateToggle({
	Name = "Auto collect enabled",
	CurrentValue = false,
	Callback = function(Value)
		AutoCollectEnabled = Value
		AutoCollectStatusLabel:Set(Value and "Status: ENABLED" or "Status: disabled")
	end,
})

local CollectCrystal = RE:WaitForChild("CollectCrystal")
local ShardSync = RE:WaitForChild("ShardSync")

local collectCount = 0
local collectedIds = {}
local pendingQueue = {}
local queuedIds = {}

local function handle_shard_sync(_, shards)
	if not AutoCollectEnabled then
		AutoCollectStatusLabel:SetText("Status: disabled")
		return
	end
	if type(shards) ~= "table" then return end

	local currentIds = {}
	local shardCount = 0
	for _, shard in ipairs(shards) do
		shardCount = shardCount + 1
		if type(shard) == "table" and shard.id ~= nil then
			currentIds[shard.id] = true
			if not collectedIds[shard.id] and not queuedIds[shard.id] then
				queuedIds[shard.id] = true
				pendingQueue[#pendingQueue + 1] = shard.id
			end
		end
	end

	for id in pairs(collectedIds) do
		if not currentIds[id] then collectedIds[id] = nil end
	end
	AutoCollectStatusLabel:SetText(string.format("Status: active (%d shards, %d queued)", shardCount, #pendingQueue))
end

local function connect_shard_sync()
	return ShardSync.OnClientEvent:Connect(function(...)
		local ok, err = pcall(handle_shard_sync, ...)
		if not ok then warn("[Auto-Collect] ShardSync handler error: " .. tostring(err)) end
	end)
end

local shardSyncConn = connect_shard_sync()

local autoCollectWorker = task.spawn(function()
	while true do
		if not AutoCollectEnabled or #pendingQueue == 0 then
			task.wait(0.1)
		else
			local id = table.remove(pendingQueue, 1)
			queuedIds[id] = nil
			local ok, err = pcall(function() CollectCrystal:FireServer(id) end)
			if ok then
				collectedIds[id] = true
				collectCount = collectCount + 1
				AutoCollectCountLabel:SetText(string.format("Collected: %d", collectCount))
			else
				warn(string.format("[Auto-Collect] Failed to fire CollectCrystal for id=%s: %s", tostring(id), tostring(err)))
			end
			task.wait(0.02)
		end
	end
end)

local shardSyncWatchdog = task.spawn(function()
	while true do
		task.wait(5)
		if not shardSyncConn or not shardSyncConn.Connected then
			warn("[Auto-Collect] ShardSync connection lost -- reconnecting")
			pcall(function() shardSyncConn:Disconnect() end)
			shardSyncConn = connect_shard_sync()
			getgenv().RocksCrashTracker.shardSyncConn = shardSyncConn
		end
	end
end)

getgenv().RocksCrashTracker.autoCollectWorker = autoCollectWorker
getgenv().RocksCrashTracker.shardSyncWatchdog = shardSyncWatchdog
getgenv().RocksCrashTracker.shardSyncConn = shardSyncConn

--// ========================================================
--// TAB 5: RUNE SHOP
--// ========================================================

local ShopTab = Window:CreateTab({ Name = "Rune Shop" })
local ShopSub = ShopTab:CreateSection("Auto-Buy")
local SG1 = ShopSub:CreateSection("Auto-Buy Runes")

local AutoShopEnabled = false
local ShopStatusLabel = SG1:CreateLabel("Status: idle")
local ShopBoughtLabel = SG1:CreateLabel("Bought: 0")

SG1:CreateLabel("Hooks the game's own shop remotes (ShopState, RuneUpdate, CurrencyUpdate, BuyShopItem) and buys every rune currently in stock and affordable, repeating as currency/stock allow.")

SG1:CreateToggle({
	Name = "Auto-buy affordable runes",
	CurrentValue = false,
	Callback = function(Value)
		AutoShopEnabled = Value
		ShopStatusLabel:Set(Value and "Status: ENABLED" or "Status: disabled")
	end,
})

local MD = require(ReplicatedStorage:WaitForChild("ReplicatedStorageHolders"):WaitForChild("MD"))
local BuyShopItem = RE:WaitForChild("BuyShopItem")
local ShopState = RE:WaitForChild("ShopState")
local RuneUpdate = RE:WaitForChild("RuneUpdate")
local CurrencyUpdate = RE:WaitForChild("CurrencyUpdate")

local shopCounts = {}
local shopRestocked = false
local ownedRunes = {}
local currencyBalance = {}

local shopCurrencyConn = CurrencyUpdate.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" and payload.balance then
		currencyBalance = payload.balance
	end
end)

local shopStateConn = ShopState.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" then
		shopCounts = payload.counts or {}
		shopRestocked = payload.restocked == true
	end
end)

local shopRuneConn = RuneUpdate.OnClientEvent:Connect(function(payload)
	if typeof(payload) == "table" then
		ownedRunes = payload.runes or {}
	end
end)

pcall(function() ShopState:FireServer() end)
pcall(function() RuneUpdate:FireServer() end)
pcall(function() CurrencyUpdate:FireServer() end)

local boughtCount = 0

local function get_current_offers()
	local window = MD.ShopWindow(Workspace:GetServerTimeNow())
	local offers = shopRestocked and MD.FullShop() or MD.RollShop(window)
	return offers, window
end

local function try_buy_all_affordable()
	local offers, window = get_current_offers()
	for _, item in ipairs(offers) do
		local keepBuying = true
		while keepBuying do
			keepBuying = false
			local owned = ownedRunes[item.Name] or 0
			local maxCopies = MD.RuneMaxCopies(item.Name)
			if maxCopies and owned >= maxCopies then break end
			local boughtThisWindow = shopCounts[item.Name] or 0
			local remainingStock = (item.Stock or 0) - boughtThisWindow
			if remainingStock <= 0 then break end
			local price = MD.RunePrice(item.Name, owned)
			local currencyName = item.PayCurrency or "Normal"
			local balance = currencyBalance[currencyName] or 0
			if balance < price then break end

			local ok, result = pcall(function()
				return BuyShopItem:InvokeServer(item.Name, window)
			end)
			if ok and typeof(result) == "table" and result.ok then
				boughtCount = boughtCount + 1
				ShopBoughtLabel:SetText(string.format("Bought: %d", boughtCount))
				print(string.format("[Shop] Bought %s for %d %s (owned now %d)", item.Name, price, currencyName, owned + 1))
				if result.counts then shopCounts = result.counts end
				ownedRunes[item.Name] = owned + 1
				currencyBalance[currencyName] = balance - price
				keepBuying = true
			else
				print(string.format("[Shop] Buy failed for %s: %s", item.Name, tostring(result)))
				break
			end
			task.wait(0.05)
		end
	end
end

local shopLoopThread = task.spawn(function()
	while true do
		task.wait(1)
		if AutoShopEnabled then
			ShopStatusLabel:SetText("Status: buying...")
			pcall(try_buy_all_affordable)
			ShopStatusLabel:SetText("Status: active")
		else
			ShopStatusLabel:SetText("Status: disabled")
		end
	end
end)

getgenv().RocksCrashTracker.shopCurrencyConn = shopCurrencyConn
getgenv().RocksCrashTracker.shopStateConn = shopStateConn
getgenv().RocksCrashTracker.shopRuneConn = shopRuneConn
getgenv().RocksCrashTracker.shopLoopThread = shopLoopThread

--// ========================================================
--// TAB 6: LIVE EVENTS
--// ========================================================

local EventsTab = Window:CreateTab({ Name = "Live Events" })
local EventsSub = EventsTab:CreateSection("World Event")
local EventsSub2 = EventsTab:CreateSection("Luck Boost")

local EG1 = EventsSub:CreateSection("World Mutation Event")
local WorldEventLabel = EG1:CreateLabel("No active event")
local WorldEventTimeLabel = EG1:CreateLabel("")

local EG2 = EventsSub2:CreateSection("Your Luck Boost")
local LuckBoostLabel = EG2:CreateLabel("No active personal boost")

EG1:CreateLabel("Read-only. Hooks RE.ServerEvent (the world mutation-boost event) and RE.LuckBoostState (your own personal luck boost) and keeps a persistent HUD of both. Nothing is fired or modified.")

local ServerEvent = RE:WaitForChild("ServerEvent")
local LuckBoostState = RE:FindFirstChild("LuckBoostState") or RE:WaitForChild("LuckBoostState", 10)

local activeWorldEvent = nil
local activeLuckBoost = nil

local serverEventConn = ServerEvent.OnClientEvent:Connect(function(payload)
	local ok, err = pcall(function()
		if type(payload) ~= "table" then
			activeWorldEvent = nil
			WorldEventLabel:SetText("No active event")
			WorldEventTimeLabel:SetText("")
			return
		end
		local name = tostring(payload.name or "?")
		local left = tonumber(payload.left) or 300
		local pct = tonumber(payload.pct) or 15
		local starter = tostring(payload.starter or "Someone")
		activeWorldEvent = {
			name = name,
			endsAt = os.clock() + left,
			pct = pct,
			starter = starter,
		}
		WorldEventLabel:SetText(string.format("%s EVENT: +%d%% mutation luck", name:upper(), pct))
		WorldEventTimeLabel:SetText(string.format("Started by %s | %ds left", starter, math.floor(left)))
		print(string.format("[Live Events] %s started %s event: +%d%% for %ds", starter, name, pct, math.floor(left)))
	end)
	if not ok then warn("[Live Events] ServerEvent handler error: " .. tostring(err)) end
end)

local luckBoostConn = nil
if LuckBoostState then
	luckBoostConn = LuckBoostState.OnClientEvent:Connect(function(payload)
		local ok, err = pcall(function()
			if type(payload) ~= "table" then return end
			local mult = tonumber(payload.mult) or 1
			local expiresAt = tonumber(payload.expiresAt) or 0
			activeLuckBoost = { mult = mult, expiresAt = expiresAt }
			if mult > 1 and Workspace:GetServerTimeNow() < expiresAt then
				LuckBoostLabel:SetText(string.format("Active: %.2fx luck", mult))
			else
				LuckBoostLabel:SetText("No active personal boost")
			end
		end)
		if not ok then warn("[Live Events] LuckBoostState handler error: " .. tostring(err)) end
	end)
else
	LuckBoostLabel:SetText("LuckBoostState remote not found")
end

local eventsLoopThread = task.spawn(function()
	while true do
		task.wait(1)
		if activeWorldEvent then
			local remaining = math.floor(activeWorldEvent.endsAt - os.clock())
			if remaining > 0 then
				WorldEventTimeLabel:SetText(string.format("Started by %s | %ds left", activeWorldEvent.starter, remaining))
			else
				activeWorldEvent = nil
				WorldEventLabel:SetText("No active event")
				WorldEventTimeLabel:SetText("")
			end
		end
		if activeLuckBoost then
			local remaining = activeLuckBoost.expiresAt - Workspace:GetServerTimeNow()
			if activeLuckBoost.mult > 1 and remaining > 0 then
				LuckBoostLabel:SetText(string.format("Active: %.2fx luck (%ds left)", activeLuckBoost.mult, math.floor(remaining)))
			else
				LuckBoostLabel:SetText("No active personal boost")
			end
		end
	end
end)

getgenv().RocksCrashTracker.serverEventConn = serverEventConn
getgenv().RocksCrashTracker.luckBoostConn = luckBoostConn
getgenv().RocksCrashTracker.eventsLoopThread = eventsLoopThread

--// ========================================================
--// TAB 7: CLAIMS & JUNK
--// ========================================================

local ClaimsTab = Window:CreateTab({ Name = "Claims & Junk" })
local ClaimsSub = ClaimsTab:CreateSection("Index Stars")
local ClaimsSub2 = ClaimsTab:CreateSection("Junk Crush")

local CG1c = ClaimsSub:CreateSection("Auto-Claim Index Stars")
local AutoClaimEnabled = false
local ClaimStatusLabel = CG1c:CreateLabel("Status: idle")
local ClaimedCountLabel = CG1c:CreateLabel("Claimed: 0")

CG1c:CreateLabel("Free, no cost. Fires ClaimIndexStar for any rock whose discovery star tier is ahead of what you've already claimed -- a permanent small luck bonus you've already earned.")

CG1c:CreateToggle({
	Name = "Auto-claim index stars",
	CurrentValue = false,
	Callback = function(Value)
		AutoClaimEnabled = Value
		ClaimStatusLabel:Set(Value and "Status: ENABLED" or "Status: disabled")
	end,
})

local ClaimIndexStar = RE:WaitForChild("ClaimIndexStar")
local DiscoveredUpdate = RE:WaitForChild("DiscoveredUpdate")
local IndexStarsUpdate = RE:WaitForChild("IndexStarsUpdate")

local discoveredKg = {}
local claimedTier = {}
local claimedCount = 0

local discoveredConn = DiscoveredUpdate.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then discoveredKg = payload end
end)

local indexStarsConn = IndexStarsUpdate.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" then claimedTier = payload end
end)

pcall(function() DiscoveredUpdate:FireServer() end)

local function try_claim_all_stars()
	for _, rockName in ipairs(MD.RockOrder) do
		local bestKg = discoveredKg[rockName] or 0
		local tier = claimedTier[rockName] or 0
		local claimable = MD.StarTierForKG(bestKg) - tier
		if claimable > 0 then
			local ok, result = pcall(function() return ClaimIndexStar:InvokeServer(rockName) end)
			if ok and type(result) == "table" and result.ok then
				claimedTier[rockName] = result.tier
				claimedCount = claimedCount + 1
				ClaimedCountLabel:SetText(string.format("Claimed: %d", claimedCount))
				print(string.format("[Claims] Claimed star tier %s for %s", tostring(result.tier), rockName))
			elseif not ok then
				warn(string.format("[Claims] ClaimIndexStar errored for %s: %s", rockName, tostring(result)))
			end
			task.wait(0.05)
		end
	end
end

local starClaimLoopThread = task.spawn(function()
	while true do
		task.wait(2)
		if AutoClaimEnabled then
			ClaimStatusLabel:SetText("Status: checking...")
			local ok, err = pcall(try_claim_all_stars)
			if not ok then warn("[Claims] claim loop error: " .. tostring(err)) end
			ClaimStatusLabel:SetText("Status: active")
		else
			ClaimStatusLabel:SetText("Status: disabled")
		end
	end
end)

getgenv().RocksCrashTracker.discoveredConn = discoveredConn
getgenv().RocksCrashTracker.indexStarsConn = indexStarsConn
getgenv().RocksCrashTracker.starClaimLoopThread = starClaimLoopThread

--// Junk Crush
local CG2c = ClaimsSub2:CreateSection("Auto-Crush Junk")
local JunkStatusLabel = CG2c:CreateLabel("Status: idle")

CG2c:CreateLabel("Manual button, not automatic -- crushing junk CONSUMES those rocks from your inventory in exchange for a guaranteed-multiplier roll. Press it when you want to cash in your current junk, not before.")

local TradeState = RE:WaitForChild("TradeState")
local ExchangeAction = RE:WaitForChild("ExchangeAction")

local tradeState = nil

local tradeStateConn = TradeState.OnClientEvent:Connect(function(payload)
	if type(payload) == "table" and payload.window then
		tradeState = payload
		local junk = payload.junk
		if junk and (junk.count or 0) >= 1 then
			JunkStatusLabel:SetText(string.format("Status: %d junk ready (%sx mult)", junk.count, tostring(junk.mult)))
		else
			JunkStatusLabel:SetText("Status: nothing to crush")
		end
	end
end)

pcall(function() TradeState:FireServer() end)
getgenv().RocksCrashTracker.tradeStateConn = tradeStateConn

CG2c:CreateButton({
	Name = "Crush All Junk Now",
	Callback = function()
		if not tradeState or not tradeState.junk or (tradeState.junk.count or 0) < 1 then
			JunkStatusLabel:SetText("Status: nothing to crush")
			return
		end
		local names = {}
		local seen = {}
		for _, entry in ipairs(tradeState.junkRocks or {}) do
			if type(entry) == "table" and entry.Name and not seen[entry.Name] then
				seen[entry.Name] = true
				names[#names + 1] = entry.Name
			end
		end
		if #names == 0 then
			JunkStatusLabel:SetText("Status: nothing to crush")
			return
		end
		JunkStatusLabel:SetText("Status: crushing...")
		local ok, result = pcall(function()
			return ExchangeAction:InvokeServer("junk", names, tradeState.window)
		end)
		if ok and type(result) == "table" and result.ok then
			JunkStatusLabel:SetText(string.format("Status: crushed %d for %sx roll", result.count or 0, tostring(result.mult)))
			print(string.format("[Claims] Crushed %d junk for %sx roll", result.count or 0, tostring(result.mult)))
		elseif ok and type(result) == "table" then
			JunkStatusLabel:SetText("Status: " .. tostring(result.reason or "failed"))
			if result.state then tradeState = result.state end
		else
			JunkStatusLabel:SetText("Status: request failed")
			warn("[Claims] ExchangeAction junk crush errored: " .. tostring(result))
		end
	end,
})

--// ========================================================
--// TAB 8: PLOT OPTIMIZER
--// ========================================================

local PlotTab = Window:CreateTab({ Name = "Plot Optimizer" })
local PlotSub = PlotTab:CreateSection("Income")
local PlotSub2 = PlotTab:CreateSection("Bulk Actions")

local PG1 = PlotSub:CreateSection("Current Plot Income")
local PlotTotalLabel = PG1:CreateLabel("Total: -- (no data yet)")
local PlotBreakdownLabel = PG1:CreateLabel("No data -- click Refresh")
local PlotWorstLabel = PG1:CreateLabel("Worst rock: --")

PG1:CreateButton({
	Name = "Refresh Plot Scan",
	Callback = function()
		scan_and_report_plot()
	end,
})

--// Target Income Ratio
PG1:CreateDivider()
PG1:CreateLabel("Target Income Ratio (weights)")

local targetWeights = {
	Normal = 100,
	MutSurged = 0,
	MutPrisma = 0,
	MutMolten = 0,
	MutVoid = 0,
}

PG1:CreateSlider({
	Name = "Rock Coins Weight",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 100,
	Callback = function(v) targetWeights.Normal = v end,
})
PG1:CreateSlider({
	Name = "Surge Coins Weight",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v) targetWeights.MutSurged = v end,
})
PG1:CreateSlider({
	Name = "Prisma Coins Weight",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v) targetWeights.MutPrisma = v end,
})
PG1:CreateSlider({
	Name = "Molten Coins Weight",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v) targetWeights.MutMolten = v end,
})
PG1:CreateSlider({
	Name = "Void Coins Weight",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v) targetWeights.MutVoid = v end,
})

--// Auto-Optimize
local PG2 = PlotSub:CreateSection("Auto-Optimize (experimental)")
local PlotOptimizeEnabled = false
local PlotOptimizeStatusLabel = PG2:CreateLabel("Status: idle")
local SwapTallyLabel = PG2:CreateLabel("Confirmed swaps: 0 / 0 attempts")
local LastSwapLabel = PG2:CreateLabel("No attempt yet")

PG2:CreateLabel("This can only choose WHICH slot to ask the game to swap -- the server decides what rock actually fills it. It briefly teleports your character to the target slot to satisfy the game's proximity requirement, then returns you. Treat as experimental.")

PG2:CreateToggle({
	Name = "Auto-optimize plot (experimental)",
	CurrentValue = false,
	Callback = function(Value)
		PlotOptimizeEnabled = Value
		PlotOptimizeStatusLabel:Set(Value and "Status: ENABLED" or "Status: disabled")
	end,
})

--// Bulk Actions
local PG3 = PlotSub2:CreateSection("Bulk Take & Place")
local BulkStatusLabel = PG3:CreateLabel("Status: idle")
local BulkResultLabel = PG3:CreateLabel("No action run yet")

PG3:CreateLabel("Firing a slot's prompt without a pre-selected candidate rock just TAKES the current rock off the plot rather than swapping. So: empty every slot first, then try filling them again.")

PG3:CreateButton({
	Name = "Take ALL Rocks from Plot",
	Callback = function()
		BulkStatusLabel:SetText("Status: taking all rocks...")
		local results, err = fire_all_my_slots("Take")
		if not results then
			BulkStatusLabel:SetText("Status: failed - " .. tostring(err))
			BulkResultLabel:SetText("TAKE ALL failed: " .. tostring(err))
			return
		end
		local changedCount, detail = summarize_bulk_results(results)
		BulkStatusLabel:SetText(string.format("Status: done -- %d/%d slots changed", changedCount, #results))
		BulkResultLabel:SetText(string.format("TAKE ALL: %d/%d changed", changedCount, #results))
	end,
})

PG3:CreateButton({
	Name = "Fill Empty Slots (experimental)",
	Callback = function()
		BulkStatusLabel:SetText("Status: attempting to fill slots...")
		local results, err = fire_all_my_slots("Fill")
		if not results then
			BulkStatusLabel:SetText("Status: failed - " .. tostring(err))
			BulkResultLabel:SetText("FILL failed: " .. tostring(err))
			return
		end
		local changedCount, detail = summarize_bulk_results(results)
		BulkStatusLabel:SetText(string.format("Status: done -- %d/%d slots changed", changedCount, #results))
		BulkResultLabel:SetText(string.format("FILL: %d/%d changed", changedCount, #results))
	end,
})

--// Plot scan functions (shared with auto-optimize)
local RockInventoryUpdate = RE:WaitForChild("InventoryUpdate")
local SetHotbarRemote = RE:WaitForChild("SetHotbar")
local SwapHotbarRemote = RE:WaitForChild("SwapHotbar")
local HoldEquipSlotRemote = RE:WaitForChild("EquipSlot")

local inventoryEntries = {}
local hotbarSlots = table.create(9, 0)
local equippedHotbarSlot = 0

local rockInventoryConn = RockInventoryUpdate.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then return end
	local byId = {}
	for _, entry in ipairs(payload.entries or {}) do
		if type(entry) == "table" and entry.Id then byId[entry.Id] = entry end
	end
	inventoryEntries = byId
	local hb = payload.hotbar
	if type(hb) == "table" then hotbarSlots = hb end
	equippedHotbarSlot = tonumber(payload.equipped) or 0
end)

pcall(function() RockInventoryUpdate:FireServer() end)
getgenv().RocksCrashTracker.rockInventoryConn = rockInventoryConn

local function pick_best_inventory_candidate(neededCurrency)
	local inHotbar = {}
	for _, id in ipairs(hotbarSlots) do
		if id ~= 0 then inHotbar[id] = true end
	end
	local best, bestScore = nil, -math.huge
	for id, entry in pairs(inventoryEntries) do
		if not inHotbar[id] then
			local ok, income, currencyKey = pcall(MD.RockIncome, entry.Name, 1, entry.Mutation)
			if ok and currencyKey == neededCurrency and income > bestScore then
				best, bestScore = entry, income
			end
		end
	end
	return best
end

local function hold_inventory_item(entryId)
	local emptySlot = nil
	for i = 1, 9 do
		if (hotbarSlots[i] or 0) == 0 then emptySlot = i; break end
	end
	local slot = emptySlot or 9
	if emptySlot then
		SetHotbarRemote:FireServer(entryId, slot)
	else
		SwapHotbarRemote:FireServer(entryId, slot)
	end
	task.wait(0.2)
	HoldEquipSlotRemote:FireServer(slot)
	task.wait(0.2)
	return slot
end

local function get_my_plot()
	local plotFolder = Workspace:FindFirstChild("Plot")
	if not plotFolder then return nil end
	for _, plot in ipairs(plotFolder:GetChildren()) do
		if plot:GetAttribute("OwnerId") == LocalPlayer.UserId then return plot end
	end
	return nil
end

local function get_my_slot_prompts(myPlot)
	local prompts = {}
	for _, obj in ipairs(myPlot:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Name == "SlotPrompt" then
			prompts[#prompts + 1] = obj
		end
	end
	return prompts
end

local function nearest_placed_rock(position)
	local best, bestDist = nil, 15
	for _, model in ipairs(CollectionService:GetTagged("PlacedRock")) do
		if model:IsA("Model") and model.PrimaryPart then
			local ok, pos = pcall(function() return model:GetPivot().Position end)
			if ok then
				local dist = (pos - position).Magnitude
				if dist < bestDist then best, bestDist = model, dist end
			end
		end
	end
	return best
end

local function scan_plot_slots()
	local myPlot = get_my_plot()
	if not myPlot then return {} end
	local slots = {}
	for _, prompt in ipairs(get_my_slot_prompts(myPlot)) do
		local part = prompt.Parent
		if part and part:IsA("BasePart") then
			local rock = nearest_placed_rock(part.Position)
			if rock then
				local rockName = rock:GetAttribute("RockName")
				local kg = rock:GetAttribute("KG") or 0
				local mutation = rock:GetAttribute("Mutation")
				local ok, income, currencyKey = pcall(MD.RockIncome, rockName, kg, mutation)
				if ok then
					slots[#slots + 1] = {
						prompt = prompt, part = part, rock = rock,
						rockName = rockName, kg = kg, mutation = mutation,
						income = income or 0, currencyKey = currencyKey or "Normal",
					}
				end
			end
		end
	end
	return slots
end

function scan_and_report_plot()
	local ok, slots = pcall(scan_plot_slots)
	if not ok then
		PlotTotalLabel:SetText("Total: scan error")
		warn("[Plot Optimizer] scan error: " .. tostring(slots))
		return {}
	end
	if #slots == 0 then
		PlotTotalLabel:SetText("Total: no placed rocks found")
		PlotBreakdownLabel:SetText("No data.")
		PlotWorstLabel:SetText("Worst rock: --")
		return {}
	end

	local totals = {}
	local grandTotal = 0
	local worst = nil
	for _, s in ipairs(slots) do
		totals[s.currencyKey] = (totals[s.currencyKey] or 0) + s.income
		grandTotal = grandTotal + s.income
		if not worst or s.income < worst.income then worst = s end
	end

	PlotTotalLabel:SetText(string.format("Total: %s/s across %d slots", MD.FormatPrice(grandTotal), #slots))

	local lines = {}
	for _, key in ipairs(MD.AllCurrencies) do
		local amount = totals[key] or 0
		local pct = grandTotal > 0 and (amount / grandTotal * 100) or 0
		lines[#lines + 1] = string.format("%s: %s/s (%.1f%%)", MD.CurrencyName(key), MD.FormatPrice(amount), pct)
	end
	PlotBreakdownLabel:SetText(table.concat(lines, " | "))

	if worst then
		PlotWorstLabel:SetText(string.format("Worst: %s (%.2fkg, %s/s %s)",
			tostring(worst.rockName), worst.kg, MD.FormatPrice(worst.income), MD.CurrencyName(worst.currencyKey)))
	end
	return slots
end

local function pick_swap_target(slots)
	if #slots == 0 then return nil end
	local totals = {}
	local grandTotal = 0
	for _, s in ipairs(slots) do
		totals[s.currencyKey] = (totals[s.currencyKey] or 0) + s.income
		grandTotal = grandTotal + s.income
	end
	if grandTotal <= 0 then return nil end
	local weightTotal = 0
	for _, w in pairs(targetWeights) do weightTotal = weightTotal + w end
	if weightTotal <= 0 then return nil end

	local worstCurrency, worstOver = nil, -math.huge
	for _, key in ipairs(MD.AllCurrencies) do
		local currentShare = (totals[key] or 0) / grandTotal
		local targetShare = (targetWeights[key] or 0) / weightTotal
		local over = currentShare - targetShare
		if over > worstOver then worstOver = over; worstCurrency = key end
	end
	if not worstCurrency or worstOver <= 0.01 then return nil end

	local target = nil
	for _, s in ipairs(slots) do
		if s.currencyKey == worstCurrency and (not target or s.income < target.income) then
			target = s
		end
	end
	return target
end

local function pick_underrepresented_currency(slots)
	if #slots == 0 then return nil end
	local totals = {}
	local grandTotal = 0
	for _, s in ipairs(slots) do
		totals[s.currencyKey] = (totals[s.currencyKey] or 0) + s.income
		grandTotal = grandTotal + s.income
	end
	local weightTotal = 0
	for _, w in pairs(targetWeights) do weightTotal = weightTotal + w end
	if weightTotal <= 0 then return nil end

	local neededCurrency, worstUnder = nil, -math.huge
	for _, key in ipairs(MD.AllCurrencies) do
		local currentShare = grandTotal > 0 and ((totals[key] or 0) / grandTotal) or 0
		local targetShare = (targetWeights[key] or 0) / weightTotal
		local under = targetShare - currentShare
		if under > worstUnder then worstUnder = under; neededCurrency = key end
	end
	if not neededCurrency or worstUnder <= 0.01 then return nil end
	return neededCurrency
end

local swapAttempts = 0
local swapConfirmed = 0

local plotOptimizeLoopThread = task.spawn(function()
	while true do
		task.wait(5)
		if not PlotOptimizeEnabled then
			PlotOptimizeStatusLabel:SetText("Status: disabled")
			continue
		end
		if type(fireproximityprompt) ~= "function" then
			PlotOptimizeStatusLabel:SetText("Status: executor has no fireproximityprompt")
			continue
		end

		local ok, err = pcall(function()
			local slots = scan_and_report_plot()
			local target = pick_swap_target(slots)
			if not target then
				PlotOptimizeStatusLabel:SetText("Status: plot already near target ratio")
				return
			end
			local neededCurrency = pick_underrepresented_currency(slots)
			if not neededCurrency then
				PlotOptimizeStatusLabel:SetText("Status: plot already near target ratio")
				return
			end
			local candidate = pick_best_inventory_candidate(neededCurrency)
			if not candidate then
				PlotOptimizeStatusLabel:SetText(string.format("Status: no inventory rock for %s", MD.CurrencyName(neededCurrency)))
				return
			end

			print(string.format("[Plot Optimizer] Holding candidate: %s (%s) for %s",
				tostring(candidate.Name), tostring(candidate.Mutation), MD.CurrencyName(neededCurrency)))

			local heldSlot = hold_inventory_item(candidate.Id)
			local character = LocalPlayer.Character
			local hrp = character and character:FindFirstChild("HumanoidRootPart")
			if not hrp then PlotOptimizeStatusLabel:SetText("Status: no character"); return end

			PlotOptimizeStatusLabel:SetText(string.format("Status: swapping %s for %s",
				tostring(target.rockName), tostring(candidate.Name)))

			local originalCFrame = hrp.CFrame
			local fireOk, fireErr = pcall(function()
				hrp.CFrame = CFrame.new(target.part.Position + Vector3.new(0, 3, 0))
				task.wait(0.3)
				fireproximityprompt(target.prompt)
			end)
			task.wait(0.3)
			pcall(function() hrp.CFrame = originalCFrame end)

			if not fireOk then
				warn("[Plot Optimizer] fireproximityprompt error: " .. tostring(fireErr))
				PlotOptimizeStatusLabel:SetText("Status: fireproximityprompt errored")
				return
			end

			local beforeText = string.format("BEFORE: %s (%.2fkg, %s/s %s)",
				tostring(target.rockName), target.kg, MD.FormatPrice(target.income), MD.CurrencyName(target.currencyKey))
			swapAttempts = swapAttempts + 1

			task.wait(1.2)
			local function read_target_slot()
				for _, s in ipairs(scan_and_report_plot()) do
					if s.part == target.part then return s end
				end
				return nil
			end

			local afterSlot = read_target_slot()
			if afterSlot and afterSlot.rock == target.rock and afterSlot.rockName == target.rockName then
				task.wait(1.0)
				afterSlot = read_target_slot() or afterSlot
			end

			if not afterSlot then
				LastSwapLabel:SetText(beforeText .. " | AFTER: could not re-read slot")
				PlotOptimizeStatusLabel:SetText("Status: swap attempted, could not verify")
			else
				local sameInstance = afterSlot.rock == target.rock
				local sameName = afterSlot.rockName == target.rockName
				local sameKg = math.abs((afterSlot.kg or 0) - (target.kg or 0)) < 0.01
				local sameMutation = afterSlot.mutation == target.mutation
				local changed = not (sameInstance and sameName and sameKg and sameMutation)

				local afterText = string.format("AFTER: %s (%.2fkg, %s/s %s)",
					tostring(afterSlot.rockName), afterSlot.kg, MD.FormatPrice(afterSlot.income), MD.CurrencyName(afterSlot.currencyKey))
				local gotIntended = afterSlot.rockName == candidate.Name and afterSlot.mutation == candidate.Mutation

				LastSwapLabel:SetText(beforeText .. " | " .. afterText)
				PlotOptimizeStatusLabel:SetText(gotIntended and "Status: CONFIRMED"
					or (changed and "Status: changed, not as intended" or "Status: no change"))

				if gotIntended then swapConfirmed = swapConfirmed + 1 end
				SwapTallyLabel:SetText(string.format("Confirmed swaps: %d / %d attempts", swapConfirmed, swapAttempts))
				print(string.format("[Plot Optimizer] %s | %s | gotIntended=%s", beforeText, afterText, tostring(gotIntended)))
			end
		end)

		if not ok then
			warn("[Plot Optimizer] loop error: " .. tostring(err))
			PlotOptimizeStatusLabel:SetText("Status: error, see console")
		end
	end
end)

getgenv().RocksCrashTracker.plotOptimizeLoopThread = plotOptimizeLoopThread

function fire_all_my_slots(actionLabel)
	local myPlot = get_my_plot()
	if not myPlot then return nil, "Could not find your plot." end
	if type(fireproximityprompt) ~= "function" then return nil, "Executor has no fireproximityprompt." end
	local character = LocalPlayer.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, "No character found." end

	local prompts = get_my_slot_prompts(myPlot)
	local originalCFrame = hrp.CFrame
	local results = {}

	for i, prompt in ipairs(prompts) do
		local part = prompt.Parent
		if part and part:IsA("BasePart") then
			local beforeRock = nearest_placed_rock(part.Position)
			local beforeName = beforeRock and beforeRock:GetAttribute("RockName") or nil
			BulkStatusLabel:SetText(string.format("Status: %s slot %d/%d...", actionLabel, i, #prompts))
			pcall(function()
				hrp.CFrame = CFrame.new(part.Position + Vector3.new(0, 3, 0))
				task.wait(0.25)
				fireproximityprompt(prompt)
			end)
			task.wait(0.35)
			local afterRock = nearest_placed_rock(part.Position)
			local afterName = afterRock and afterRock:GetAttribute("RockName") or nil
			results[#results + 1] = { index = i, before = beforeName, after = afterName, changed = beforeName ~= afterName }
		end
	end
	pcall(function() hrp.CFrame = originalCFrame end)
	return results, nil
end

function summarize_bulk_results(results)
	local changedCount = 0
	for _, r in ipairs(results) do
		if r.changed then changedCount = changedCount + 1 end
	end
	return changedCount, ""
end

pcall(scan_and_report_plot)

--// ========================================================
--// SETTINGS TAB
--// ========================================================

local SettingsTab = Window:CreateTab({ Name = "UI Settings" })
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
MenuGroup:CreateButton({ Name = "Test Notification", Callback = function()
	Library.Notify({ Title = "Test", Content = "Fired at " .. os.date("%H:%M:%S"), Duration = 4 })
end })
MenuGroup:CreateDropdown({
	Name = "Notification Side",
	Options = { "Left", "Right" },
	CurrentOption = "Right",
})
MenuGroup:CreateDropdown({
	Name = "DPI Scale",
	Options = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	CurrentOption = "100%",
})
MenuGroup:CreateSlider({
	Name = "Corner Radius",
	Range = {0, 20},
	Increment = 1,
	CurrentValue = 4,
})
MenuGroup:CreateDivider()
MenuGroup:CreateLabel("Menu bind")
MenuGroup:CreateKeybind({ Name = "Menu keybind", CurrentKeybind = "RightShift" })
MenuGroup:CreateButton({ Name = "Join Discord", Callback = function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 }) end })
MenuGroup:CreateButton({ Name = "Unload", Callback = function() Library:Unload() end })

--// ========================================================
--// GLOBAL UTILITIES
--// ========================================================

_G.PrintCrashHistory = function()
	print("\n[CRASH VALUE HISTORY]")
	print(string.rep("=", 60))
	for i, entry in ipairs(rollHistory) do
		print(string.format("Roll #%d | crash=%.4f | X1=%s X2=%s X3=%s",
			i, entry.crash, tostring(entry.X1), tostring(entry.X2), tostring(entry.X3)))
	end
	print(string.rep("=", 60) .. "\n")
end

Library.Notify({
	Title = "Ivory",
	Content = "Rocks RNG loaded successfully",
	Type = "Success",
	Duration = 3,
})

print("[Rocks RNG] Script loaded successfully.")