--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162
--// v2.1 | Egg Stealing, Rarity, Area, Grid Placement, Auto Steal, Egg ESP

-- ═══════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════
--  CONFIG / STATE
-- ═══════════════════════════════════════════════════════
local Config = {
	PerfMode = false,
	PhysReady = false,
	AntiTrap = true,
	ManualBase = nil,
	AutoEquipBest = false,
	AutoClaim = false,
	AutoUpgrade = false,
	AntiAFK = false,
	FpsBoost = false,
	AutoFireProx = false,
	ServerHop = false,
	ServerHopDelay = 30,
	ServerHopCount = 0,
	ServerHopMax = 15,
	Unloaded = false,
	AutoTreadmill = false,
	AutoUpgradeTreadmill = false,
	SellPets = false,
	ParasiteFarm = false,
	AutoSteal = false,
	FarmMethod = "TP Walk",
	AreaFocus = {},
	RarityFilter = {},
	SecretPriority = true,
	AutoHatch = false,
	EggESP = false,
	AutoSellEggs = false,
	SellEggRarities = {},
}

local Threads = {}
local Conns = {}

local Assets = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Assets"))
local F = {}

-- ═══════════════════════════════════════════════════════
--  NETWORKING
-- ═══════════════════════════════════════════════════════
local NET = ReplicatedStorage:FindFirstChild("Packages")
NET = NET and NET:FindFirstChild("Networking") or nil

local Remotes = {
	EggSnapshot   = "RF/EggWorld/AskFieldEggSnapshot",
	EggCarry      = "RF/EggWorld/AskFieldEggCarry",
	EggPlace      = "RF/EggWorld/AskPlaceEgg",
	EggDrop       = "RF/EggWorld/AskFieldEggDrop",
	EggLive       = "RF/EggWorld/AskLiveSnapshot",
	EggRarityShow = "RF/EggWorld/AskFieldEggRarityShows",
	Hatch         = "RF/EggWorld/AskHatch",
	HatchFinish   = "RF/EggWorld/AskFinishHatch",
	SkipGrowth    = "RF/EggWorld/AskSkipGrowth",
	WearTool      = "RF/EggWorld/AskWearTool",
	DoffTool      = "RF/EggWorld/AskDoffTool",
	PlotState     = "RF/Homestead/AskState",
	BaseTierRaise = "RE/Homestead/AskBaseTierRaise",
	NearbyBuy     = "RE/Homestead/AskNearbyPurchase",
	Collect       = "RF/AwayEarnings/AskCollect",
	PendingCheck  = "RF/AwayEarnings/PendingCheck",
	CodexAll      = "RF/Codex/AskRedeemAll",
	WearBest      = "RF/Haul/WearBest",
	SatchelSale   = "RF/Haul/OfferFullSatchelSale",
	SellEveryPet  = "RE/PetSatchel/SellEveryPet",
	SellPet       = "RE/PetSatchel/SellPet",
	PetSnapshot   = "RF/PenRoster/AskLiveSnapshot",
	PetSale       = "RF/PenRoster/AskSale",
	PetWear       = "RF/PenRoster/AskWear",
	PetDoff       = "RF/PenRoster/AskDoff",
	TreadRaise    = "RF/Treadmill/AskTierRaise",
	TreadRender   = "RF/Treadmill/AskRenderSnapshot",
	RigWipe       = "RE/RigSync/AskRigWipe",
	WriteAutoSell = "RF/Haul/WriteAutoSell",
	FetchAutoSell = "RF/Haul/FetchAutoSell",
}

local function net(name)
	return NET and NET:FindFirstChild(name) or nil
end

local function callNet(name, ...)
	local r = net(name)
	if not r then return nil end
	if r:IsA("RemoteFunction") then
		local ok, res = pcall(r.InvokeServer, r, ...)
		return ok and res or nil
	end
	local ok = pcall(r.FireServer, r, ...)
	return ok or nil
end

local function netNames()
	local out = {}
	if NET then
		for _, r in ipairs(NET:GetChildren()) do
			if r:IsA("RemoteFunction") or r:IsA("RemoteEvent") then
				out[#out + 1] = r.Name
			end
		end
	end
	table.sort(out)
	return out
end

local uidShapeCache = {}

local function askUid(name, uid)
	local shape = uidShapeCache[name]
	if shape ~= 2 then
		local res = callNet(name, { Uid = uid })
		if res ~= nil and res ~= false then
			uidShapeCache[name] = 1
			return true
		end
		if shape == 1 then return false end
	end
	local res = callNet(name, uid)
	if res ~= nil and res ~= false then
		uidShapeCache[name] = 2
		return true
	end
	return false
end

-- ═══════════════════════════════════════════════════════
--  UTILITY
-- ═══════════════════════════════════════════════════════
local function alive()
	return not Config.Unloaded
end

local function root()
	local ch = LocalPlayer.Character
	return ch and ch:FindFirstChild("HumanoidRootPart") or nil
end

local function hum()
	local ch = LocalPlayer.Character
	return ch and ch:FindFirstChildWhichIsA("Humanoid") or nil
end

local function charReady()
	local h = hum()
	return root() ~= nil and h ~= nil and h.Health > 0
end

local function track(conn)
	Conns[#Conns + 1] = conn
	return conn
end

local function spawnLoop(fn)
	local th = task.spawn(function()
		xpcall(fn, function(err)
			warn("[Ivory] " .. tostring(err) .. "\n" .. debug.traceback())
		end)
	end)
	Threads[#Threads + 1] = th
	return th
end

local fireprompt = fireproximityprompt or (syn and syn.fireproximityprompt)

local function firePrompt(pp)
	if not fireprompt or not pp or not pp.Enabled then return false end
	pcall(function() pp.HoldDuration = 0 end)
	return pcall(fireprompt, pp)
end

local function promptInRange(pp)
	local hrp = root()
	local part = pp and pp.Parent
	if not hrp or not part then return false end
	local pos
	if part:IsA("BasePart") then
		pos = part.Position
	elseif part:IsA("Model") then
		local ok, pv = pcall(function() return part:GetPivot() end)
		pos = ok and pv.Position or nil
	elseif part:IsA("Attachment") then
		pos = part.WorldPosition
	end
	if not pos then return false end
	local max = pp.MaxActivationDistance > 0 and pp.MaxActivationDistance or 12
	return (hrp.Position - pos).Magnitude <= max + 4
end

local function promptsUnder(inst, words)
	local out = {}
	if not inst then return out end
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("ProximityPrompt") and d.Enabled then
			local hay = (d.Name .. " " .. d.ActionText .. " " .. d.ObjectText):lower()
			if d.Parent then hay = hay .. " " .. d.Parent.Name:lower() end
			for _, w in ipairs(words) do
				if hay:find(w, 1, true) then
					out[#out + 1] = d
					break
				end
			end
		end
	end
	return out
end

local function recordsOf(t)
	if type(t) ~= "table" then return {} end
	return t.Records or t.Pets or t.Items or t.Entries or t.Inventory or t
end

-- ═══════════════════════════════════════════════════════
--  RARITY SYSTEM
-- ═══════════════════════════════════════════════════════
local Rarities = {}
local rarityLadder = {}
local rarityColor = {}

do
	local ok, mod = pcall(function()
		return require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Rarity", 5))
	end)
	if ok and mod and type(mod.Rarities) == "table" then
		for id, info in pairs(mod.Rarities) do
			if type(info) == "table" then
				local dn = info.DisplayName or info._id or id
				local rn = info.RarityNumber or 0
				Rarities[#Rarities + 1] = dn
				rarityLadder[dn] = rn
				if info.Color then rarityColor[dn] = info.Color end
			end
		end
	end
	if #Rarities == 0 then
		Rarities = { "Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Divine","Eternal" }
		for i, n in ipairs(Rarities) do rarityLadder[n] = i end
		rarityColor = {
			Common = Color3.fromRGB(190, 190, 190),
			Uncommon = Color3.fromRGB(120, 220, 120),
			Rare = Color3.fromRGB(90, 160, 255),
			Epic = Color3.fromRGB(180, 110, 255),
			Legendary = Color3.fromRGB(255, 200, 70),
			Mythic = Color3.fromRGB(255, 110, 190),
			Cosmic = Color3.fromRGB(130, 240, 255),
			Secret = Color3.fromRGB(60, 60, 70),
			Divine = Color3.fromRGB(255, 250, 200),
			Eternal = Color3.fromRGB(255, 90, 90),
		}
	end
	table.sort(Rarities, function(a, b) return (rarityLadder[a] or 0) < (rarityLadder[b] or 0) end)
end

local function ladderOf(name)
	if type(name) ~= "string" then return 0 end
	return rarityLadder[name] or 0
end

F.resolveRarity = function(assetCategory)
    if typeof(assetCategory) ~= "string" then
        return nil
    end
    local asset = Assets.Directory[assetCategory]
    if not asset or not asset.Rarity then
        return nil
    end
    return asset.Rarity._id or asset.Rarity.DisplayName
end

local function rarityOf(rec)
	local v = F.resolveRarity(rec.AssetCategory)
	if v then return v end
	v = rec.Rarity or rec.RarityName or rec.Tier or rec.RarityId
	if type(v) == "table" then
		v = v.DisplayName or v._id or v.Name or v.Id
	end
	return type(v) == "string" and v or nil
end

local function rankOf(rec)
	local v = F.resolveRarity(rec.AssetCategory)
	if v and ladderOf(v) > 0 then return ladderOf(v) end
	v = rec.Rarity or rec.RarityName or rec.Tier or rec.RarityId
	if type(v) == "table" then
		local rn = v.RarityNumber
		if type(rn) == "number" and rn > 0 then return rn end
		v = v.DisplayName or v._id or v.Name or v.Id
	end
	local name = type(v) == "string" and v or nil
	return name and ladderOf(name) or 0
end

local FX = {}

do
-- ═══════════════════════════════════════════════════════
--  HUMANOID UNLOCK (Performance Mode)
-- ═══════════════════════════════════════════════════════
local _pk = {"RigType","HipHeight","JumpPower","JumpHeight","UseJumpPower","AutoRotate","MaxSlopeAngle","DisplayDistanceType","NameDisplayDistance","HealthDisplayDistance","AutomaticScalingEnabled","BreakJointsOnDeath","RequiresNeck","EvaluateStateMachine"}

local _Qk = function()
	local ch = LocalPlayer.Character; if not ch then return false end
	local old = ch:FindFirstChildWhichIsA("Humanoid"); if not old then return false end
	local p = {}; for _, n in ipairs(_pk) do local ok, v = pcall(function() return old[n] end); if ok then p[n] = v end end
	local _b = old.WalkSpeed
	pcall(function() old:Destroy() end); RunService.Heartbeat:Wait()
	local nw = Instance.new("Humanoid"); for k, v in pairs(p) do pcall(function() nw[k] = v end) end
	nw.Parent = ch; RunService.Heartbeat:Wait()
	if nw.Parent ~= ch then return false end
	nw.WalkSpeed = _b; pcall(function() nw:ChangeState(Enum.HumanoidStateType.Landed) end)
	local c = Workspace.CurrentCamera; if c then pcall(function() c.CameraSubject = nw end) end
	Config.PhysReady = true; return true
end

local _Ek = function()
	if Config.PerfMode and not Config.PhysReady and charReady() then return _Qk() end
	return Config.PhysReady
end

-- ═══════════════════════════════════════════════════════
--  AREA SYSTEM
-- ═══════════════════════════════════════════════════════
local AreaData = {
	areaLabel = {},
	areaRarity = {},
	areaTierName = {},
	areaByLabel = {},
	areaOrder = {},
}

local function addArea(id, label, rank, tierName)
	if not id or AreaData.areaLabel[id] then return end
	label = label or id
	AreaData.areaLabel[id] = label
	AreaData.areaRarity[id] = rank or 0
	AreaData.areaTierName[id] = tierName
	AreaData.areaByLabel[label] = id
	AreaData.areaOrder[#AreaData.areaOrder + 1] = id
end

local function sortAreas()
	table.sort(AreaData.areaOrder, function(a, b)
		local ra, rb = AreaData.areaRarity[a] or 0, AreaData.areaRarity[b] or 0
		if ra == rb then
			return tostring(AreaData.areaLabel[a]) < tostring(AreaData.areaLabel[b])
		end
		return ra < rb
	end)
end

local function areaLabels()
	local out = {}
	for _, id in ipairs(AreaData.areaOrder) do
		out[#out + 1] = AreaData.areaLabel[id]
	end
	return out
end

do
	local Data = ReplicatedStorage:FindFirstChild("Data")
	local m = Data and Data:FindFirstChild("Areas")
	local ok, mod = pcall(function() return m and require(m) end)
	local dir = ok and type(mod) == "table" and (mod.Directory or mod) or nil
	if type(dir) == "table" then
		for id, info in pairs(dir) do
			if type(id) == "string" and type(info) == "table" then
				local rank, tierName = 0, nil
				if type(info.Rarity) == "table" then
					rank = tonumber(info.Rarity.RarityNumber) or 0
					tierName = info.Rarity.DisplayName or info.Rarity._id
				end
				addArea(id, info.DisplayName or info.Name or id, rank, tierName)
			end
		end
	end
	if #AreaData.areaOrder == 0 then
		local folder = Workspace:FindFirstChild("Areas") or Workspace:FindFirstChild("Islands")
		if folder then
			local rank = 0
			for _, a in ipairs(folder:GetChildren()) do
				rank = rank + 1
				addArea(a.Name, a.Name, rank, nil)
			end
		end
	end
	sortAreas()
end

local function asSet(list)
	local set, n = {}, 0
	if type(list) == "table" then
		for _, v in ipairs(list) do
			if type(v) == "string" and v ~= "" then
				set[v] = true
				n = n + 1
			end
		end
	end
	return set, n
end

local AreaWanted, AreaWantedCount = {}, 0
local RarityWanted, RarityWantedCount = {}, 0

local function rebuildAreaSet()
	local labels = asSet(Config.AreaFocus)
	local ids, n = {}, 0
	for label in pairs(labels) do
		local id = AreaData.areaByLabel[label] or label
		ids[id] = true
		n = n + 1
	end
	AreaWanted, AreaWantedCount = ids, n
end

local function rebuildRaritySet()
	RarityWanted, RarityWantedCount = asSet(Config.RarityFilter)
end

local function pickList(v)
	local out = {}
	if type(v) == "table" then
		for k, val in pairs(v) do
			if val == true then
				out[#out + 1] = k
			elseif type(val) == "string" then
				out[#out + 1] = val
			end
		end
	elseif type(v) == "string" then
		out[1] = v
	end
	return out
end

local filterValues = {}
for _, r in ipairs(Rarities) do
	filterValues[#filterValues + 1] = r
end

-- ═══════════════════════════════════════════════════════
--  EGG SLOTS & HELPERS
-- ═══════════════════════════════════════════════════════
local SlotsCache = nil

local function slots()
	if SlotsCache and SlotsCache.Parent then return SlotsCache end
	SlotsCache = Workspace:FindFirstChild("AreaEggSlotsClient")
	return SlotsCache
end

local function eggModel(uid)
	local folder = slots()
	return folder and folder:FindFirstChild(uid) or nil
end

local function eggPart(uid)
	local mdl = eggModel(uid)
	if not mdl then return nil end
	return mdl.PrimaryPart or mdl:FindFirstChild("Hitbox") or mdl:FindFirstChildWhichIsA("BasePart")
end

local function eggPos(rec)
	local part = eggPart(rec.Uid)
	if part then return part.Position end
	local cf = rec.BoundsCFrame or rec.BottomCFrame
	return cf and cf.Position or nil
end

local function isMutated(rec)
	if rec.BaseMutation then return true end
	return type(rec.Mutations) == "table" and next(rec.Mutations) ~= nil
end

local function eggAlive(uid)
	local folder = slots()
	if not folder then return true end
	return folder:FindFirstChild(uid) ~= nil
end

-- ═══════════════════════════════════════════════════════
--  EGG LIST, ELIGIBILITY, PICKING
-- ═══════════════════════════════════════════════════════
local EggList = {}
local EggListAt = 0
local TriedUids = {}
local FailUids = {}
local AreaDirty = false

local function refreshEggs(force)
	if not force and tick() - EggListAt < 1.5 then return EggList end
	local snap = callNet(Remotes.EggSnapshot)
	local recs = snap and snap.Records
	if type(recs) ~= "table" then return EggList end
	local list = {}
	for _, rec in pairs(recs) do
		if rec.State == "Slot" and rec.Uid then
			local pos = eggPos(rec)
			if pos then
				local id = rec.AreaId
				if id and not AreaData.areaLabel[id] then
					addArea(id, id, #AreaData.areaOrder + 1, rarityOf(rec))
					AreaDirty = true
				end
			local own = rarityOf(rec)
			local rnk = rankOf(rec)
			if rnk == 0 and ladderOf(own) > 0 then rnk = ladderOf(own) end
			local name = own or (id and AreaData.areaTierName[id]) or rarityOf(rec)
			if rnk == 0 then rnk = ladderOf(name) end
			list[#list + 1] = {
				uid = rec.Uid,
				area = id,
				label = id and AreaData.areaLabel[id] or "Unknown",
				pos = pos,
				tier = id and AreaData.areaRarity[id] or 0,
				rarity = name,
				rank = rnk,
				mutated = isMutated(rec),
				size = rec.BoundsSize and rec.BoundsSize.Magnitude or 3,
			}
			end
		end
	end
	if AreaDirty then
		AreaDirty = false
		sortAreas()
		rebuildAreaSet()
	end
	EggList = list
	EggListAt = tick()
	local live = {}
	for i = 1, #list do live[list[i].uid] = true end
	local now = tick()
	for uid, at in pairs(TriedUids) do
		if not live[uid] and now - at > 300 then
			TriedUids[uid] = nil
			FailUids[uid] = nil
		end
	end
	return list
end

local function eligible(e)
	local at = TriedUids[e.uid]
	if at then
		local f = FailUids[e.uid] or 0
		local hold = 6
		if f >= 4 then hold = 600
		elseif f == 3 then hold = 120
		elseif f == 2 then hold = 45
		elseif f == 1 then hold = 18
		end
		if tick() - at < hold then return false end
	end
	if AreaWantedCount > 0 and not AreaWanted[e.area] then return false end
	if RarityWantedCount > 0 and not RarityWanted[e.rarity] then return false end
	return true
end

local function pickEgg()
	local hrp = root()
	if not hrp then return nil end
	refreshEggs(false)
	local origin = hrp.Position
	local best, bestScore
	for i = 1, #EggList do
		local e = EggList[i]
		if eligible(e) then
			local d = (e.pos - origin).Magnitude
			local tier = e.tier > 0 and e.tier or e.rank
			local score = e.rank * 1e12 + tier * 1e8 + (e.mutated and 1e6 or 0) - math.min(d, 1e5)
			if not bestScore or score > bestScore then
				best, bestScore = e, score
			end
		end
	end
	return best
end

-- ═══════════════════════════════════════════════════════
--  TRAP DETECTION
-- ═══════════════════════════════════════════════════════
local TRAP_RADIUS = 16
local TRAP_WORDS = { "trap", "cage", "snare" }
local TrapList = {}
local TrapModels = {}
local TrapAt = 0

local function refreshTraps()
	local function trapish(inst)
		if not inst:IsA("Model") then return false end
		if inst:FindFirstChild("UnplacePrompt") then return true end
		local n = inst.Name:lower()
		for _, w in ipairs(TRAP_WORDS) do
			if n:find(w, 1, true) then return true end
		end
		return false
	end
	local function defuse(m)
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				pcall(function() d.CanTouch = false end)
				pcall(function() d.CanCollide = false end)
			end
		end
	end
	local spots, models = {}, {}
	local debris = Workspace:FindFirstChild("__DEBRIS")
	for _, scope in ipairs({ debris, Workspace }) do
		if scope then
			for _, m in ipairs(scope:GetChildren()) do
				if trapish(m) then
					local ok, pv = pcall(function() return m:GetPivot() end)
					if ok and pv then
						spots[#spots + 1] = pv.Position
						models[#models + 1] = m
						if Config.AntiTrap then defuse(m) end
					end
				end
			end
		end
	end
	TrapList = spots
	TrapModels = models
	TrapAt = tick()
	return spots
end

local function traps()
	if tick() - TrapAt > 2 then refreshTraps() end
	return TrapList
end

local function trapNear(x, z, pad)
	if not Config.AntiTrap then return false end
	local list = traps()
	local lim = pad or TRAP_RADIUS
	lim = lim * lim
	for i = 1, #list do
		local p = list[i]
		local dx, dz = p.X - x, p.Z - z
		if dx * dx + dz * dz < lim then return true end
	end
	return false
end

local function breakTrapHold()
	local ch = LocalPlayer.Character
	if not ch then return end
	for _, d in ipairs(ch:GetDescendants()) do
		if d:IsA("BasePart") then
			if d.Anchored then pcall(function() d.Anchored = false end) end
		elseif d:IsA("WeldConstraint") or d:IsA("Weld") then
			pcall(function()
				local a, b = d.Part0, d.Part1
				if (a and not a:IsDescendantOf(ch)) or (b and not b:IsDescendantOf(ch)) then
					d:Destroy()
				end
			end)
		end
	end
	local h = hum()
	if h then
		pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		pcall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end)
	end
end

-- ═══════════════════════════════════════════════════════
--  MOVEMENT
-- ═══════════════════════════════════════════════════════
local GroundParams = RaycastParams.new()
GroundParams.FilterType = Enum.RaycastFilterType.Exclude
GroundParams.IgnoreWater = true

local function groundSkip()
	local skip = {}
	if LocalPlayer.Character then skip[#skip + 1] = LocalPlayer.Character end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then skip[#skip + 1] = p.Character end
	end
	local eggFolder = slots()
	if eggFolder then skip[#skip + 1] = eggFolder end
	for _, m in ipairs(TrapModels) do
		if m.Parent then skip[#skip + 1] = m end
	end
	return skip
end

local function refreshGroundFilter()
	GroundParams.FilterDescendantsInstances = groundSkip()
end

local PROBE_LOW = 7
local PROBE_HIGH = 160
local PROBE_DOWN = 420
local STEP_MAX = 6
local TRAVEL_SPEED = 1000

local function notFloor(inst)
	local node = inst
	for _ = 1, 6 do
		if not node or node == Workspace then return false end
		if node:IsA("Model")
			and (node:FindFirstChildWhichIsA("Humanoid") or node:FindFirstChildWhichIsA("AnimationController")) then
			return true
		end
		node = node.Parent
	end
	return false
end

local function castFloor(x, z, top, drop)
	local y = top
	for _ = 1, 4 do
		local res = Workspace:Raycast(Vector3.new(x, y, z), Vector3.new(0, -(y - (top - drop)), 0), GroundParams)
		if not res then return nil end
		if not notFloor(res.Instance) then return res.Position.Y end
		y = res.Position.Y - 0.6
		if y <= top - drop then return nil end
	end
	return nil
end

local function floorY(x, z, near)
	local y = castFloor(x, z, near + PROBE_LOW, PROBE_LOW + PROBE_DOWN)
	if y then return y end
	y = castFloor(x, z, near + PROBE_HIGH, PROBE_HIGH + PROBE_DOWN)
	if y and y > near + PROBE_LOW then return y end
	return nil
end

local function rootRise()
	local hrp, h = root(), hum()
	local half = hrp and hrp.Size.Y * 0.5 or 1
	local hip = 2
	if h then
		local ok, v = pcall(function() return h.HipHeight end)
		if ok and type(v) == "number" and v > 0 then hip = v end
	end
	return half + hip
end

local function pinRoot(hrp, h)
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
	if h then
		pcall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end)
	end
end

local function releaseRoot()
	local hrp, h = root(), hum()
	if hrp then
		pcall(function()
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
		end)
	end
	if h then
		pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
		pcall(function() h:ChangeState(Enum.HumanoidStateType.Landed) end)
	end
end

-- ═══════════════════════════════════════════════════════
--  ROUTING
-- ═══════════════════════════════════════════════════════
local ROUTE_SAMPLE = 14
local ROUTE_DROP = 26
local STRAIGHT_MAX = 60
local SIDE_OFFSETS = { 30, -30, 70, -70, 140, -140, 240, -240 }
local TP_STEP = 45
local TP_WAIT = 0.08

local function walkable(a, b, floor_start)
	local flatVec = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local dist = flatVec.Magnitude
	if dist < 1 then return true, floor_start end
	local dir = flatVec.Unit
	local steps = math.ceil(dist / ROUTE_SAMPLE)
	local y = floor_start
	for i = 1, steps do
		local p = a + dir * math.min(dist, i * ROUTE_SAMPLE)
		if trapNear(p.X, p.Z) then return false, y end
		local g = floorY(p.X, p.Z, y)
		if not g or math.abs(g - y) > ROUTE_DROP then return false, y end
		y = g
	end
	return true, y
end

local function chainWalkable(from, points)
	local y = floorY(from.X, from.Z, from.Y)
	if not y then return false end
	local prev = from
	for i = 1, #points do
		local ok, endY = walkable(prev, points[i], y)
		if not ok then return false end
		prev, y = points[i], endY
	end
	return true
end

local HubCache = nil
local HubTried = false

local function centroidOf(scope, cap)
	if not scope then return nil end
	local sum, n = Vector3.zero, 0
	for _, d in ipairs(scope:GetDescendants()) do
		if d:IsA("BasePart") then
			sum = sum + d.Position
			n = n + 1
			if n >= cap then break end
		end
	end
	if n == 0 then return nil end
	return sum / n
end

local function hubPoint()
	if HubCache or HubTried then return HubCache end
	HubTried = true
	local mid = centroidOf(Workspace:FindFirstChild("Stands"), 60)
	if not mid then
		local plots = Workspace:FindFirstChild("Plots")
		if plots then
			local sum, n = Vector3.zero, 0
			for _, p in ipairs(plots:GetChildren()) do
				if p:IsA("Model") then
					local ok, pv = pcall(function() return p:GetPivot() end)
					if ok and pv then sum = sum + pv.Position; n = n + 1 end
				end
			end
			if n > 0 then mid = sum / n end
		end
	end
	if mid then
		local g = floorY(mid.X, mid.Z, mid.Y) or floorY(mid.X, mid.Z, mid.Y + 200)
		if g then HubCache = Vector3.new(mid.X, g, mid.Z) end
	end
	return HubCache
end

local function simplify(points)
	local out = {}
	for i = 1, #points do
		local p = points[i]
		local last = out[#out]
		if not last or Vector3.new(p.X - last.X, 0, p.Z - last.Z).Magnitude > 3 then
			out[#out + 1] = p
		end
	end
	if #out < 3 then return out end
	local keep = {}
	for i = 2, #out - 1 do
		local a = Vector3.new(out[i].X - out[i - 1].X, 0, out[i].Z - out[i - 1].Z)
		local b = Vector3.new(out[i + 1].X - out[i].X, 0, out[i + 1].Z - out[i].Z)
		if a.Magnitude > 0.1 and b.Magnitude > 0.1 and a.Unit:Dot(b.Unit) < 0.995 then
			keep[#keep + 1] = out[i]
		end
	end
	keep[#keep + 1] = out[#out]
	return keep
end

local function pathRoute(from, to)
	local ok, path = pcall(function()
		return PathfindingService:CreatePath({
			AgentRadius = 3,
			AgentHeight = 6,
			AgentCanJump = true,
			AgentCanClimb = false,
			WaypointSpacing = 24,
		})
	end)
	if not ok or not path then return nil end
	local ran = pcall(function() path:ComputeAsync(from, to) end)
	local status, wps
	pcall(function() status = path.Status end)
	if ran and status == Enum.PathStatus.Success then
		pcall(function() wps = path:GetWaypoints() end)
	end
	pcall(function() path:Destroy() end)
	if type(wps) ~= "table" or #wps < 2 then return nil end
	local pts = {}
	for i = 2, #wps do pts[#pts + 1] = wps[i].Position end
	pts[#pts] = to
	return simplify(pts)
end

local function routeVia(from, to, mid)
	if chainWalkable(from, { mid, to }) then return { mid, to } end
	local toMid = Vector3.new(mid.X - from.X, 0, mid.Z - from.Z)
	if toMid.Magnitude > 1 then
		local side = Vector3.new(-toMid.Unit.Z, 0, toMid.Unit.X)
		for i = 1, #SIDE_OFFSETS do
			local m = mid + side * SIDE_OFFSETS[i]
			local g = floorY(m.X, m.Z, mid.Y)
			if g then
				local mp = Vector3.new(m.X, g, m.Z)
				if chainWalkable(from, { mp, to }) then return { mp, to } end
			end
		end
	end
	return nil
end

local function routeTo(from, to)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z).Magnitude
	if flat <= STRAIGHT_MAX and chainWalkable(from, { to }) then return { to } end
	local mid = hubPoint()
	if mid then
		local via = routeVia(from, to, mid)
		if via then return via end
	end
	local flatVec = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flatVec.Magnitude > 1 then
		local dir = flatVec.Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local centre = from + flatVec * 0.5
		for i = 1, #SIDE_OFFSETS do
			local w = centre + side * SIDE_OFFSETS[i]
			local g = floorY(w.X, w.Z, centre.Y)
			if g then
				local wp = Vector3.new(w.X, g, w.Z)
				if chainWalkable(from, { wp, to }) then return { wp, to } end
			end
		end
	end
	local viaMesh = pathRoute(from, to)
	if viaMesh and #viaMesh > 0 then return viaMesh end
	if mid then return { mid, to } end
	return { to }
end

-- ═══════════════════════════════════════════════════════
--  TRAVEL
-- ═══════════════════════════════════════════════════════
local TravelToken = 0
local Travelling = false
local TravelStep = 0

local function cancelTravel()
	TravelToken = TravelToken + 1
	Travelling = false
end

local function tpLeg(targetPos, reachDist, keepGoing, token)
	local hrp = root()
	if not hrp then return false end
	local start = hrp.Position
	local flatVec = Vector3.new(targetPos.X - start.X, 0, targetPos.Z - start.Z)
	local flat = flatVec.Magnitude
	if flat <= 0.5 then return true end
	local dir = flatVec.Unit
	local yaw = CFrame.lookAt(Vector3.zero, dir).Rotation
	local rise = rootRise()
	local y = (floorY(start.X, start.Z, start.Y - rise) or (start.Y - rise)) + rise
	local moved = 0
	local hops = math.ceil(flat / TP_STEP)
	local deadline = tick() + hops * (TP_WAIT + 0.06) + 10
	local realPos, realAt = start, tick()

	while alive() and TravelToken == token do
		if keepGoing and not keepGoing() then break end
		local r, h = root(), hum()
		if not r or not r.Parent or not h or h.Health <= 0 then break end
		if tick() > deadline then break end
		if (r.Position - realPos).Magnitude > 2 then
			realPos, realAt = r.Position, tick()
		elseif tick() - realAt > 0.5 then
			realAt = tick()
			breakTrapHold()
		end
		moved = math.min(flat, moved + TP_STEP)
		local p = start + dir * moved
		local g = floorY(p.X, p.Z, y - rise)
		if g then y = g + rise end
		pcall(function() r.CFrame = CFrame.new(p.X, y, p.Z) * yaw end)
		pinRoot(r, h)
		TravelStep = tick()
		if moved >= flat - 0.01 then return true end
		task.wait(TP_WAIT)
	end

	if TravelToken ~= token then return false end
	local r = root()
	if not r then return false end
	return Vector3.new(targetPos.X - r.Position.X, 0, targetPos.Z - r.Position.Z).Magnitude <= (reachDist or 8)
end

local function travelLeg(targetPos, reachDist, keepGoing, token)
	local hrp = root()
	if not hrp then return false end
	local start = hrp.Position
	local flatVec = Vector3.new(targetPos.X - start.X, 0, targetPos.Z - start.Z)
	local flat = flatVec.Magnitude
	if flat <= 0.5 then return true end
	local dir = flatVec.Unit
	local yaw = CFrame.lookAt(Vector3.zero, dir).Rotation
	local rise = rootRise()
	local y = (floorY(start.X, start.Z, start.Y - rise) or (start.Y - rise)) + rise
	local moved = 0
	local deadline = tick() + flat / TRAVEL_SPEED + 10
	local done = false
	local realPos, realAt = start, tick()

	while alive() and TravelToken == token do
		if keepGoing and not keepGoing() then break end
		local dt = RunService.Heartbeat:Wait()
		TravelStep = tick()
		local r, h = root(), hum()
		if not r or not r.Parent or not h or h.Health <= 0 then break end
		if (r.Position - realPos).Magnitude > 2 then
			realPos, realAt = r.Position, tick()
		elseif tick() - realAt > 0.5 then
			realAt = tick()
			breakTrapHold()
		end
		if tick() > deadline then break end
		local frameStep = math.min(TRAVEL_SPEED * math.min(dt, 0.1), flat - moved)
		local subs = math.max(1, math.ceil(frameStep / STEP_MAX))
		local per = frameStep / subs
		for _ = 1, subs do
			moved = math.min(flat, moved + per)
			local p = start + dir * moved
			local g = floorY(p.X, p.Z, y - rise)
			if g then
				y = y + math.clamp((g + rise) - y, -STEP_MAX * 4, STEP_MAX * 4)
			end
			if moved >= flat then break end
		end
		local p = start + dir * moved
		pcall(function() r.CFrame = CFrame.new(p.X, y, p.Z) * yaw end)
		pinRoot(r, h)
		if moved >= flat - 0.01 then done = true; break end
	end

	if TravelToken ~= token then return false end
	if done then return true end
	local r = root()
	if not r then return false end
	return Vector3.new(targetPos.X - r.Position.X, 0, targetPos.Z - r.Position.Z).Magnitude <= (reachDist or 8)
end

local function travelTo(targetPos, reachDist, keepGoing)
	local hrp = root()
	if not hrp or not targetPos then return false end
	reachDist = reachDist or 8
	if Vector3.new(targetPos.X - hrp.Position.X, 0, targetPos.Z - hrp.Position.Z).Magnitude <= reachDist then
		return true
	end
	cancelTravel()
	refreshGroundFilter()
	refreshTraps()
	local token = TravelToken
	TravelStep = tick()
	Travelling = true
	local leg = Config.FarmMethod == "TP Walk" and tpLeg or travelLeg
	local legs = routeTo(hrp.Position, targetPos)
	local ok = true
	for i = 1, #legs do
		if not leg(legs[i], i == #legs and reachDist or 4, keepGoing, token) then
			ok = false
			break
		end
	end
	if TravelToken ~= token then return false end
	Travelling = false
	releaseRoot()
	local r = root()
	if not r then return false end
	local left = Vector3.new(targetPos.X - r.Position.X, 0, targetPos.Z - r.Position.Z).Magnitude
	return ok and left <= reachDist + 6
end

track(RunService.Heartbeat:Connect(function()
	if Travelling and tick() - TravelStep > 6 then
		Travelling = false
		releaseRoot()
	end
end))

-- -------------------------------------------------------
--  WARN TOAST
-- -------------------------------------------------------
local warnLayer = nil

local function warnRoot()
	if warnLayer and warnLayer.Parent then return warnLayer end
	local ok = pcall(function()
		local sg = Instance.new("ScreenGui")
		sg.Name = "IvoryWarn"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.DisplayOrder = 9999
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
		warnLayer = sg
	end)
	return ok and warnLayer or nil
end

local function warnToast(text, dur)
	local layer = warnRoot()
	if not layer then return end
	dur = dur or 4
	pcall(function()
		local card = Instance.new("Frame")
		card.AnchorPoint = Vector2.new(1, 1)
		card.Position = UDim2.new(1, 20, 1, -22)
		card.Size = UDim2.fromOffset(232, 54)
		card.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
		card.BorderSizePixel = 0
		card.Parent = layer
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local stroke = Instance.new("UIStroke", card)
		stroke.Thickness = 1
		stroke.Color = Color3.fromRGB(238, 168, 62)
		stroke.Transparency = 0.35
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 3, 1, -16)
		bar.Position = UDim2.new(0, 8, 0, 8)
		bar.BackgroundColor3 = Color3.fromRGB(238, 168, 62)
		bar.BorderSizePixel = 0
		bar.Parent = card
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
		local head = Instance.new("TextLabel")
		head.BackgroundTransparency = 1
		head.Position = UDim2.new(0, 20, 0, 9)
		head.Size = UDim2.new(1, -30, 0, 16)
		head.Font = Enum.Font.GothamBold
		head.TextSize = 12
		head.TextColor3 = Color3.fromRGB(238, 168, 62)
		head.TextXAlignment = Enum.TextXAlignment.Left
		head.Text = "Warning"
		head.Parent = card
		local body = Instance.new("TextLabel")
		body.BackgroundTransparency = 1
		body.Position = UDim2.new(0, 20, 0, 27)
		body.Size = UDim2.new(1, -30, 0, 18)
		body.Font = Enum.Font.Gotham
		body.TextSize = 12
		body.TextColor3 = Color3.fromRGB(206, 206, 212)
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextTruncate = Enum.TextTruncate.AtEnd
		body.Text = text
		body.Parent = card
		TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -18, 1, -22),
		}):Play()
		task.delay(dur, function()
			local out = TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
				Position = UDim2.new(1, 260, 1, -22),
			})
			out:Play()
			out.Completed:Wait()
			card:Destroy()
		end)
	end)
end

-- -------------------------------------------------------
--  VOID DROP
-- -------------------------------------------------------
local VoidBusy = false

local function backOnMap(floor)
	if not charReady() then return false end
	local r = root()
	return r ~= nil and r.Parent ~= nil and r.Position.Y > floor
end

local function voidDrop()
	if VoidBusy then return false end
	local hrp = root()
	if not hrp then return false end
	VoidBusy = true
	cancelTravel()
	local killY = -500
	local okY, v = pcall(function() return Workspace.FallenPartsDestroyHeight end)
	if okY and type(v) == "number" then killY = v end
	local safe = killY + 60
	local p = hrp.Position
	local h = hum()
	if h then pcall(function() h:ChangeState(Enum.HumanoidStateType.Physics) end) end
	local hold = tick() + 5
	while alive() and tick() < hold do
		local r = root()
		if not r or not r.Parent then break end
		pcall(function()
			r.CFrame = CFrame.new(p.X, safe, p.Z)
			r.AssemblyLinearVelocity = Vector3.zero
			r.AssemblyAngularVelocity = Vector3.zero
		end)
		RunService.Heartbeat:Wait()
	end
	local r = root()
	if r and r.Parent then
		pcall(function()
			r.CFrame = CFrame.new(p.X, killY - 250, p.Z)
			r.AssemblyLinearVelocity = Vector3.new(0, -280, 0)
		end)
	end
	local watch = killY + 200
	local deadline = tick() + 20
	local back = false
	while alive() and tick() < deadline do
		if backOnMap(watch) then back = true; break end
		task.wait(0.2)
	end
	if not back and alive() then
		warnToast("Using Fallback..", 5)
		callNet(Remotes.RigWipe)
		local retry = tick() + 12
		while alive() and tick() < retry do
			if backOnMap(watch) then back = true; break end
			task.wait(0.2)
		end
	end
	VoidBusy = false
	return back
end

-- -------------------------------------------------------
--  PLOT / BASE DETECTION
-- -------------------------------------------------------
local CachedPlot = nil
local CachedSlot = nil
local PlotTried = 0
local OriginCache = nil
local OriginCacheAt = 0

local function myPlot()
	if CachedPlot and CachedPlot.Parent then return CachedPlot end
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then return nil end
	if not CachedSlot then
		local st = callNet(Remotes.PlotState)
		if type(st) == "table" then
			local map = st.OwnersBySlot or st.SlotOwners or st.Owners or st.Slots
			if type(map) == "table" then
				for slot, owner in pairs(map) do
					local id = owner
					if type(owner) == "table" then
						id = owner.UserId or owner.OwnerUserId or owner.Id or owner.Name
					end
					if id == LocalPlayer.UserId or id == tostring(LocalPlayer.UserId) or id == LocalPlayer.Name then
						CachedSlot = slot
						break
					end
				end
			end
		end
	end
	if CachedSlot then
		CachedPlot = plots:FindFirstChild(tostring(CachedSlot))
		if CachedPlot then return CachedPlot end
	end
	if tick() - PlotTried < 10 then return nil end
	PlotTried = tick()
	for _, p in ipairs(plots:GetChildren()) do
		for _, d in ipairs(p:GetDescendants()) do
			if d:IsA("TextLabel") or d:IsA("TextButton") then
				local ok, txt = pcall(function() return d.Text end)
				if ok and type(txt) == "string" and #txt > 0 and txt:find(LocalPlayer.Name, 1, true) then
					CachedPlot = p
					return CachedPlot
				end
			end
		end
	end
	return nil
end

local function plotPivot()
	local p = myPlot()
	if not p then return nil end
	local ok, pv = pcall(function() return p:GetPivot() end)
	return ok and pv or nil
end

local PenCache = nil

local function penPivot()
	if PenCache then return PenCache end
	local p = myPlot()
	if p then
		for _, d in ipairs(p:GetDescendants()) do
			if d.Name:lower():find("pen", 1, true) then
				if d:IsA("BasePart") then PenCache = d.CFrame; return PenCache end
				if d:IsA("Model") then
					local ok, pv = pcall(function() return d:GetPivot() end)
					if ok and pv then PenCache = pv; return PenCache end
				end
			end
		end
	end
	local base = plotPivot()
	if base then PenCache = base * CFrame.new(0, 0, 15); return PenCache end
	return nil
end

local function ownerId(t)
	local id = t.OwnerUserId or t.UserId or t.PlayerId or t.Owner
	if type(id) == "table" then id = id.UserId or id.userId or id.Id end
	return id
end

local function ownedBy(t)
	local id = ownerId(t)
	if type(id) == "number" then return id == LocalPlayer.UserId end
	if type(id) == "string" then return id == tostring(LocalPlayer.UserId) or id == LocalPlayer.Name end
	return nil
end

local function myRecords()
	local out = {}
	local seen = {}
	local live = callNet(Remotes.EggLive)
	if type(live) ~= "table" then return out end
	local function take(t)
		for key, rec in pairs(t) do
			if type(rec) == "table" then
				local uid = rec.Uid or (type(key) == "string" and key) or nil
				if uid and not seen[uid] and ownedBy(rec) ~= false then
					seen[uid] = true
					if rec.Uid == nil then rec.Uid = uid end
					out[#out + 1] = rec
				end
			end
		end
	end
	for _, entry in pairs(live) do
		if type(entry) == "table" and ownedBy(entry) == true and type(entry.Records) == "table" then
			take(entry.Records)
		end
	end
	if #out == 0 then
		for _, entry in pairs(live) do
			if type(entry) == "table" and type(entry.Records) == "table" then
				take(entry.Records)
			end
		end
	end
	if #out == 0 and type(live.Records) == "table" then
		take(live.Records)
	end
	return out
end

local function usedSpots()
	local used = { l = {}, w = {} }
	for _, rec in ipairs(myRecords()) do
		local pl = rec.Placement
		local cf = pl and (pl.LocalCFrame or pl.CFrame or pl.WorldCFrame)
		if typeof(cf) == "CFrame" then
			used.l[#used.l + 1] = cf.Position
		elseif typeof(cf) == "Vector3" then
			used.l[#used.l + 1] = cf
		end
	end
	for _, c in ipairs(Workspace:GetChildren()) do
		if c.Name == "PlacedEggRenders" then
			for _, m in ipairs(c:GetChildren()) do
				local ok, p = pcall(function()
					if m:IsA("BasePart") then return m.Position end
					if m:IsA("Model") then return m:GetPivot().Position end
					return nil
				end)
				if ok and p then used.w[#used.w + 1] = p end
			end
		end
	end
	return used
end

local function baseOrigins()
	if OriginCache and tick() - OriginCacheAt < 15 then return OriginCache end
	local list = {}
	local p = myPlot()
	if p then
		local ok, pp = pcall(function() return p.PrimaryPart end)
		if ok and pp then list[#list + 1] = pp.CFrame end
		local best, bestArea = nil, 0
		for _, d in ipairs(p:GetChildren()) do
			if d:IsA("BasePart") then
				local nm = d.Name:lower()
				if nm:find("base", 1, true) or nm:find("plate", 1, true) or nm:find("pad", 1, true)
					or nm:find("floor", 1, true) or nm:find("ground", 1, true) or nm:find("origin", 1, true) then
					local area = d.Size.X * d.Size.Z
					if area > bestArea then best, bestArea = d, area end
				end
			end
		end
		if best then list[#list + 1] = best.CFrame end
		local ok2, pv = pcall(function() return p:GetPivot() end)
		if ok2 and pv then list[#list + 1] = pv end
	end
	if #list == 0 then list[1] = CFrame.new() end
	local dedup = {}
	for _, cf in ipairs(list) do
		local keep = true
		for _, e in ipairs(dedup) do
			if (e.Position - cf.Position).Magnitude < 0.5 then keep = false; break end
		end
		if keep then dedup[#dedup + 1] = cf end
	end
	OriginCache = dedup
	OriginCacheAt = tick()
	return dedup
end

-- -------------------------------------------------------
--  EGG PLACEMENT
-- -------------------------------------------------------
local RING8 = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
local PLACE_PITCH = 6
local PLACE_HALF = 24
local EGG_CLEAR = 7
local ZONE_HALF = 20
local GRID_STEP = 4
local ClaimedCells = {}

local SHAPE_FILE = "IvoryPlaceShape.txt"
local PlaceOK = nil
local PlaceWhy = ""
local PlaceLog = {}
local PlaceFails = 0

local function logShape(tag, msg)
	PlaceLog[#PlaceLog + 1] = tostring(tag) .. " " .. tostring(msg)
	if #PlaceLog > 12 then table.remove(PlaceLog, 1) end
end

local function savePlaceOK()
	if PlaceOK and type(writefile) == "function" then
		pcall(function() writefile(SHAPE_FILE, tostring(PlaceOK.origin)) end)
	end
end

if type(isfile) == "function" and type(readfile) == "function" then
	local ok, s = pcall(function()
		if isfile(SHAPE_FILE) then return readfile(SHAPE_FILE) end
		return nil
	end)
	local n = ok and tonumber(s) or nil
	if n and n >= 1 then PlaceOK = { origin = math.floor(n) } end
end

local function placeTargets()
	local origins = baseOrigins()
	local o = origins[1]
	if not o then return {} end
	local used = usedSpots().w
	local out = {}
	local seen = {}
	local clear2 = EGG_CLEAR * EGG_CLEAR
	local function nearestEgg(wx, wz)
		local best = math.huge
		for _, w in ipairs(used) do
			local dx, dz = w.X - wx, w.Z - wz
			local d2 = dx * dx + dz * dz
			if d2 < best then best = d2 end
		end
		return best
	end
	local function add(lx, lz)
		local wp = o * CFrame.new(lx, 0, lz)
		local key = math.floor(wp.X / 3) .. ":" .. math.floor(wp.Z / 3)
		if seen[key] then return end
		local at = ClaimedCells[key]
		if at and tick() - at < 20 then return end
		local near = nearestEgg(wp.X, wp.Z)
		if near < clear2 then return end
		local gy = floorY(wp.X, wp.Z, o.Position.Y)
		if not gy then return end
		seen[key] = true
		out[#out + 1] = { key = key, w = Vector3.new(wp.X, gy, wp.Z), lx = lx, lz = lz, clr = math.sqrt(near) }
	end
	local half = ZONE_HALF
	local step = GRID_STEP
	local z = -half
	while z <= half do
		local x = -half
		while x <= half do
			add(x, z)
			x = x + step
		end
		z = z + step
	end
	return out
end

local function holdingEgg()
	local ch = LocalPlayer.Character
	return ch ~= nil and ch:FindFirstChildWhichIsA("Tool") ~= nil
end

local function ensureHeld(uid)
	if holdingEgg() then return true end
	for _ = 1, 8 do
		askUid(Remotes.WearTool, uid)
		for _ = 1, 4 do
			RunService.Heartbeat:Wait()
			if holdingEgg() then return true end
		end
	end
	return false
end

local function placeShot(uid, oi, wcf)
	local origins = baseOrigins()
	local o = origins[oi]
	if not o then return false end
	local r = net(Remotes.EggPlace)
	if not r or not r:IsA("RemoteFunction") then return false end
	if not holdingEgg() then return false end
	local lp = (o:Inverse() * wcf).Position
	local lcf = CFrame.new(lp)
	local ok, res = pcall(function()
		return r:InvokeServer({ Uid = uid, LocalCFrame = lcf })
	end)
	if not ok then
		if type(res) == "string" and #res > 0 then PlaceWhy = res:sub(1, 140) end
		logShape("O" .. oi, res)
		return false
	end
	if type(res) == "string" and #res > 0 then
		PlaceWhy = res:sub(1, 140)
		logShape("O" .. oi, res)
	elseif type(res) == "table" then
		local why = res.Error or res.Reason or res.Message or res.Why
		if type(why) == "string" and #why > 0 then PlaceWhy = why:sub(1, 140) end
		logShape("O" .. oi, why or "table reply")
	else
		PlaceWhy = "server returned " .. tostring(res)
		logShape("O" .. oi, "returned " .. tostring(res))
	end
	for _ = 1, 16 do
		if not holdingEgg() then return true end
		RunService.Heartbeat:Wait()
	end
	return false
end

local function tryAt(uid, target)
	local wcf = CFrame.new(target.w)
	local origins = baseOrigins()
	if PlaceOK and origins[PlaceOK.origin] then
		return placeShot(uid, PlaceOK.origin, wcf)
	end
	for oi = 1, #origins do
		if placeShot(uid, oi, wcf) then
			PlaceOK = { origin = oi }
			savePlaceOK()
			return true
		end
		task.wait(0.04)
	end
	return false
end

local function placeEgg(uid, maxTries)
	maxTries = maxTries or 18
	if not ensureHeld(uid) then
		PlaceWhy = "egg never reached the hand"
		return false, false
	end
	local htool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
	if htool then
		local u = htool:GetAttribute("UID")
		if u == nil then
			for _, ch in ipairs(htool:GetChildren()) do
				if ch:IsA("Model") then
					u = ch.Name:match("_(%w+)$")
					if u then break end
				end
			end
		end
		if u ~= nil then uid = tostring(u) end
	end
	if not PlaceOK then PlaceLog = {}; PlaceWhy = "" end
	local targets = placeTargets()
	local origins = baseOrigins()
	local center = origins[1] and origins[1].Position or (root() and root().Position) or Vector3.zero
	table.sort(targets, function(a, b)
		return (a.w - center).Magnitude < (b.w - center).Magnitude
	end)
	local mine = #myRecords()
	local tries = 0
	for _, t in ipairs(targets) do
		tries = tries + 1
		if tryAt(uid, t) then
			ClaimedCells[t.key] = tick()
			PlaceFails = 0
			return true
		end
		if not holdingEgg() then PlaceFails = 0; return true end
		if tries >= maxTries then break end
		task.wait(0.04)
	end
	if not holdingEgg() then PlaceFails = 0; return true end
	if #myRecords() > mine then PlaceFails = 0; return true end
	PlaceFails = PlaceFails + 1
	if PlaceOK and PlaceFails >= 3 then PlaceOK = nil; PlaceFails = 0 end
	return false, #targets == 0
end

local function smartPlacePrompt()
	for _, c in ipairs(Workspace:GetChildren()) do
		if c.Name == "SmartPromptPart" then
			for _, pp in ipairs(c:GetChildren()) do
				if pp:IsA("ProximityPrompt") and pp.Enabled then
					local t = (pp.Name .. " " .. tostring(pp.ActionText) .. " " .. tostring(pp.ObjectText)):lower()
					if t:find("place", 1, true) or t:find("plant", 1, true) or t:find("drop", 1, true) then
						return pp
					end
				end
			end
		end
	end
	return nil
end

-- -------------------------------------------------------
--  GRAB, DELIVER, AUTO STEAL LOOP
-- -------------------------------------------------------
local CarryingUid = nil
local DeliverFails = 0
local DryRuns = 0
local DeliverAt = 0
local WarnPlantAt = 0
local HatchCursor = 0

local function grabEgg(uid)
	if callNet(Remotes.EggCarry, { Uid = uid }) ~= true then return false end
	task.spawn(function()
		for _ = 1, 3 do
			if holdingEgg() then return end
			askUid(Remotes.WearTool, uid)
			task.wait(0.15)
		end
	end)
	return true
end

local GRAB_TOLERANCE = 8

local function inRange(pos, reach)
	local hrp = root()
	if not hrp or not pos then return false end
	local a = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
	local b = Vector3.new(pos.X, 0, pos.Z)
	return (a - b).Magnitude <= (reach or 12) + GRAB_TOLERANCE
end

local function autoStealOn()
	return alive() and Config.AutoSteal
end

local function livePos(e)
	local part = eggPart(e.uid)
	if part then e.pos = part.Position end
	return e.pos
end

local function deliver(uid)
	local basePos = Config.ManualBase or (plotPivot() and plotPivot().Position)
	if basePos and not inRange(basePos, 26) then
		travelTo(basePos, 14, autoStealOn)
	end
	if Config.ManualBase then
		local pen = penPivot()
		if pen and not inRange(pen.Position, 12) then
			travelTo(pen.Position, 8, autoStealOn)
		end
		local ok = placeEgg(uid)
		if not ok then
			for _, pp in ipairs({ smartPlacePrompt() }) do
				if pp and promptInRange(pp) and firePrompt(pp) then
					for _ = 1, 12 do
						if not holdingEgg() then return true end
						RunService.Heartbeat:Wait()
					end
				end
			end
			askUid(Remotes.DoffTool, uid)
		end
		return true
	end
	local base = plotPivot()
	if base and not inRange(base.Position, 26) then
		travelTo(base.Position, 14, autoStealOn)
	end
	local pen = penPivot()
	if pen and not inRange(pen.Position, 12) then
		travelTo(pen.Position, 8, autoStealOn)
	end
	local ok, full = placeEgg(uid)
	if ok then return true end
	if full and _hatchAll then
		pcall(_hatchAll, false)
		if placeEgg(uid) then return true end
	end
	for _, pp in ipairs({ smartPlacePrompt() }) do
		if pp and promptInRange(pp) and firePrompt(pp) then
			for _ = 1, 12 do
				if not holdingEgg() then return true end
				RunService.Heartbeat:Wait()
			end
		end
	end
	return false
end

local function goHome(reach)
	local pv = plotPivot()
	if not pv then return false end
	if inRange(pv.Position, reach or 20) then return true end
	return travelTo(pv.Position, 12)
end

-- -------------------------------------------------------
--  HATCH ALL
-- -------------------------------------------------------
local function hatchAllFn(walk)
	if walk then goHome(20) end
	local recs = myRecords()
	local before = #recs
	if before == 0 then
		HatchCursor = 0
	else
		if HatchCursor >= before then HatchCursor = 0 end
		local batch = walk and before or math.min(before, 12)
		for i = 1, batch do
			local rec = recs[(HatchCursor + i - 1) % before + 1]
			local uid = rec and rec.Uid
			if uid then
				askUid(Remotes.SkipGrowth, uid)
				askUid(Remotes.Hatch, uid)
				askUid(Remotes.HatchFinish, uid)
				task.wait(0.06)
			end
		end
		HatchCursor = (HatchCursor + batch) % before
	end
	local n = 0
	if before > 0 then
		local after = #myRecords()
		if before > after then n = before - after end
	end
	if n == 0 then
		for _, pp in ipairs(promptsUnder(myPlot(), { "hatch", "open" })) do
			if promptInRange(pp) and firePrompt(pp) then
				n = n + 1
				task.wait(0.08)
			end
		end
	end
	return n
end
local _hatchAll = hatchAllFn

-- -------------------------------------------------------
--  MAIN AUTO STEAL LOOP
-- -------------------------------------------------------
spawnLoop(function()
	while alive() do
		local idle = 0.1
		if Config.AutoSteal and charReady() then
			local ok, err = pcall(function()
				if CarryingUid then
					if not holdingEgg() and not eggAlive(CarryingUid) then
						CarryingUid = nil
						DeliverFails = 0
						return
					end
					if Config.FarmMethod == "TP Walk" then
						local basePos = Config.ManualBase or (plotPivot() and plotPivot().Position)
						if basePos and not inRange(basePos, 20) then
							travelTo(basePos, 12, autoStealOn)
						end
						askUid(Remotes.DoffTool, CarryingUid)
						CarryingUid = nil
						DeliverFails = 0
						return
					end
					if tick() - DeliverAt < 1 then return end
					DeliverAt = tick()
					if deliver(CarryingUid) then
						CarryingUid = nil
						DeliverFails = 0
					else
						DeliverFails = DeliverFails + 1
						if DeliverFails >= 4 then
							DeliverFails = 0
							askUid(Remotes.DoffTool, CarryingUid)
							CarryingUid = nil
							if tick() - WarnPlantAt > 60 then
								WarnPlantAt = tick()
								warnToast("Could not plant that egg" ..
									(#PlaceWhy > 0 and ": " .. PlaceWhy or "") ..
									". Moving on.", 6)
							end
						end
					end
					return
				end
				if Config.SecretPriority then
					refreshEggs(false)
					for i = 1, #EggList do
						local e = EggList[i]
						if e.rank >= (rarityLadder.Secret or 8) and eligible(e) then
							local carryRank = 0
							if CarryingUid then
								for j = 1, #EggList do
									if EggList[j].uid == CarryingUid then
										carryRank = EggList[j].rank; break
									end
								end
							end
							if e.rank > carryRank and CarryingUid then
								pcall(function() askUid(Remotes.DoffTool, CarryingUid) end)
								CarryingUid = nil
								DeliverFails = 0
								cancelTravel()
								warnToast("Secret egg spotted - switching!", 4)
							end
							break
						end
					end
				end
				local e = pickEgg()
				if not e then
					DryRuns = DryRuns + 1
					refreshEggs(true)
					idle = math.min(0.6 + DryRuns * 0.4, 3)
					return
				end
				DryRuns = 0
				TriedUids[e.uid] = tick()
				local reach = math.max(9, e.size * 0.6 + 7)
				local keep = function() return autoStealOn() and eggAlive(e.uid) end
				local target = livePos(e)
				if not inRange(target, reach) then
					travelTo(target, reach, keep)
					if not autoStealOn() then return end
					local fresh = livePos(e)
					if not inRange(fresh, reach) then
						travelTo(fresh, reach, keep)
						if not autoStealOn() then return end
					end
				end
				local got = grabEgg(e.uid)
				if not got then
					task.wait(0.1)
					got = grabEgg(e.uid)
				end
				if got then
					FailUids[e.uid] = nil
					CarryingUid = e.uid
					DeliverAt = tick()
					DeliverFails = 0
					if Config.FarmMethod == "TP Walk" then
						local basePos = Config.ManualBase or (plotPivot() and plotPivot().Position)
						if basePos and not inRange(basePos, 20) then
							travelTo(basePos, 12, autoStealOn)
						end
						askUid(Remotes.DoffTool, e.uid)
						CarryingUid = nil
					elseif deliver(e.uid) then
						CarryingUid = nil
					else
						DeliverFails = 1
					end
					idle = 0
				else
					FailUids[e.uid] = (FailUids[e.uid] or 0) + 1
				end
			end)
			if not ok then
				warn("[Ivory] steal: " .. tostring(err))
				task.wait(0.5)
			end
		else
			idle = 0.3
		end
		if idle > 0 then task.wait(idle) else RunService.Heartbeat:Wait() end
	end
end)

-- Auto hatch loop
spawnLoop(function()
	while alive() do
		if Config.AutoHatch and charReady() and not Travelling then
			pcall(_hatchAll, false)
		end
		task.wait(2)
	end
end)

-- -------------------------------------------------------
--  EGG ESP
-- -------------------------------------------------------
local espFolder = nil
local ESPTags = {}

local function espParent()
	if espFolder and espFolder.Parent then return espFolder end
	espFolder = Instance.new("Folder")
	espFolder.Name = "IvoryEggESP"
	espFolder.Parent = (type(gethui) == "function" and gethui()) or game:GetService("CoreGui")
	return espFolder
end

local function clearESP()
	for uid, tag in pairs(ESPTags) do
		pcall(function() tag:Destroy() end)
		ESPTags[uid] = nil
	end
	if espFolder then
		pcall(function() espFolder:Destroy() end)
		espFolder = nil
	end
end

local function makeTag(e)
	local mdl = eggModel(e.uid)
	local part = eggPart(e.uid)
	if not mdl or not part then return nil end
	local colour = rarityColor[e.rarity] or Color3.fromRGB(255, 255, 255)
	local box = Instance.new("Folder")
	box.Name = e.uid
	local hl = Instance.new("Highlight")
	hl.Adornee = mdl
	hl.FillColor = colour
	hl.OutlineColor = e.mutated and Color3.fromRGB(255, 150, 60) or colour
	hl.FillTransparency = 0.62
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = box
	local bb = Instance.new("BillboardGui")
	bb.Adornee = part
	bb.Size = UDim2.fromOffset(190, 26)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 100000
	bb.Parent = box
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 13
	lbl.TextColor3 = colour
	lbl.TextStrokeTransparency = 0.35
	lbl.Text = (e.rarity or e.label or "Egg") .. (e.mutated and "  MUT" or "")
	lbl.Parent = bb
	box.Parent = espParent()
	return box
end

spawnLoop(function()
	while alive() do
		if Config.EggESP then
			pcall(function()
				local list = refreshEggs(false)
				local seen = {}
				for _, e in ipairs(list) do
					seen[e.uid] = true
					local tag = ESPTags[e.uid]
					if not tag or not tag.Parent or not eggModel(e.uid) then
						if tag then pcall(function() tag:Destroy() end) end
						ESPTags[e.uid] = makeTag(e)
					end
				end
				for uid, tag in pairs(ESPTags) do
					if not seen[uid] then
						pcall(function() tag:Destroy() end)
						ESPTags[uid] = nil
					end
				end
			end)
		elseif next(ESPTags) then
			clearESP()
		end
		task.wait(1.2)
	end
end)

-- -------------------------------------------------------
--  WASD MANUAL MOVEMENT
-- -------------------------------------------------------
local MOVE_KEYS = {
	[Enum.KeyCode.W] = Vector3.new(0, 0, -1),
	[Enum.KeyCode.S] = Vector3.new(0, 0, 1),
	[Enum.KeyCode.A] = Vector3.new(-1, 0, 0),
	[Enum.KeyCode.D] = Vector3.new(1, 0, 0),
}
local ManualHeld = {}

track(UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if MOVE_KEYS[input.KeyCode] then ManualHeld[input.KeyCode] = true end
end))

track(UserInputService.InputEnded:Connect(function(input)
	if MOVE_KEYS[input.KeyCode] then ManualHeld[input.KeyCode] = nil end
end))

track(UserInputService.JumpRequest:Connect(function()
	if not Config.PhysReady or Travelling then return end
	local h = hum()
	if h and h.Health > 0 then
		pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
	end
end))

local function manualDir()
	local cam = Workspace.CurrentCamera
	if not cam then return Vector3.zero end
	local raw = Vector3.zero
	for key, offset in pairs(MOVE_KEYS) do
		if ManualHeld[key] then raw = raw + offset end
	end
	if raw.Magnitude < 0.01 then return Vector3.zero end
	local cf = cam.CFrame
	local dir = cf.RightVector * raw.X - cf.LookVector * raw.Z
	return Vector3.new(dir.X, 0, dir.Z)
end

spawnLoop(function()
	while alive() do
		RunService.Heartbeat:Wait()
		if Config.PhysReady and not Travelling then
			local h = hum()
			if h and h.Health > 0 then
				local dir = manualDir()
				if dir.Magnitude > 0.01 then h:Move(dir.Unit, false) end
			end
		end
	end
end)

-- Reset state on respawn
track(LocalPlayer.CharacterAdded:Connect(function(ch)
	Config.PhysReady = false
	CarryingUid = nil
	DeliverFails = 0
	PenCache = nil
	cancelTravel()
	TravelStep = 0
	pcall(function() ch:WaitForChild("HumanoidRootPart", 10) end)
	task.wait(0.7)
	if Config.AutoSteal then _Qk() end
end))

-- -------------------------------------------------------
--  SELL PETS
-- -------------------------------------------------------
local function sellStandPrompt()
	local stands = Workspace:FindFirstChild("Stands")
	local prompts = stands and stands:FindFirstChild("Prompts")
	local holder = prompts and (prompts:FindFirstChild("SellAll") or prompts:FindFirstChild("Sell"))
	return holder and holder:FindFirstChildWhichIsA("ProximityPrompt") or nil
end

local function goSellStand()
	local pp = sellStandPrompt()
	local part = pp and pp.Parent
	if part and part:IsA("BasePart") then
		local cf = part.CFrame * CFrame.new(0, 0, 3)
		if inRange(cf.Position, 14) then return true end
		return travelTo(cf.Position, 8)
	end
	return false
end

local function sellPets(walk)
	if walk then goSellStand() end
	local pp = sellStandPrompt()
	if pp and promptInRange(pp) then firePrompt(pp) end
	callNet(Remotes.SellEveryPet)
	callNet(Remotes.SatchelSale)
end

-- -------------------------------------------------------
--  ANTI TRAP LOOP
-- -------------------------------------------------------
spawnLoop(function()
	while alive() do
		if Config.AntiTrap then pcall(refreshTraps) end
		task.wait(3)
	end
end)

do
	local debris = Workspace:FindFirstChild("__DEBRIS")
	if debris then
		track(debris.ChildAdded:Connect(function()
			task.delay(0.1, function()
				if alive() and Config.AntiTrap then pcall(refreshTraps) end
			end)
		end))
	end
end

-- -------------------------------------------------------
--  AUTOMATION LOOPS
-- -------------------------------------------------------
spawnLoop(function()
	while alive() do
		if Config.AutoEquipBest and charReady() then
			callNet(Remotes.WearBest)
		end
		task.wait(6)
	end
end)

spawnLoop(function()
	while alive() do
		if Config.AntiAFK and charReady() then
			pcall(function()
				local VirtualUser = game:GetService("VirtualUser")
				VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
				task.wait(0.1)
				VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
			end)
		end
		task.wait(60)
	end
end)
-- -------------------------------------------------------
--  AUTO SELL EGGS
-- -------------------------------------------------------
spawnLoop(function()
	while alive() do
		if Config.AutoSellEggs and charReady() then
			pcall(function()
				callNet(Remotes.WriteAutoSell, Config.SellEggRarities)
				callNet(Remotes.SatchelSale)
			end)
		end
		task.wait(4)
	end
end)
-- -------------------------------------------------------
--  SERVER HOP
-- -------------------------------------------------------
local function serverHop()
	local best, bestOk = nil, -1
	local sub = HttpService:GenerateGUID(false):sub(1, 12)
	local prefix = sub:sub(1, 8)
	local function okTele()
		if not ServerHopReady then return false end
		if HttpService.HttpEnabled then
			local sg, body = pcall(function()
				return HttpService:JSONDecode((request or HttpService.RequestAsync)({
					Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullServers=true",
					Method = "GET",
				}).Body)
			end)
			if sg and type(body) == "table" then
				for _, data in ipairs(body.data or {}) do
					local id = data.id or data.serverId or data.JobId
					local px = data.playing or data.currentPlayers or 0
					local mx = data.maxPlayers or data.capacity or 0
					if type(id) == "string" and id ~= GameJobId and px < mx and px > bestOk then
						best = id
						bestOk = px
					end
				end
			end
		end
		return best ~= nil
	end
	ServerHopReady = true
	okTele()
	ServerHopReady = false
	local extra = (prefix ~= "68ef8f3b" and prefix ~= "4bd66a0f") and "shared=true" or "secure=true"
	local target = best
		-- If no specific server found, use roblox://placeId/... as fallback
		or (PlaceId .. "/job?gameId=" .. PlaceId .. "&" .. extra)
	local ok2 = pcall(function()
		game:GetService("TeleportService"):TeleportToPlaceInstance(
			PlaceId,
			target,
			LocalPlayer,
			Workspace:WaitForChild("SpawnLocation", 0.5)
		)
	end)
	return ok2
end

-- -------------------------------------------------------
--  FPS BOOST
-- -------------------------------------------------------
local FPSSettings = {}
local FpsTarget = 60

local function setFpsTarget(n)
	FpsTarget = math.clamp(n, 15, 240)
end

local function fpsOn()
	local lighting = game:GetService("Lighting")
	for _, setting in ipairs({
		"FutureIsBright", "GlobalShadows", "Technology",
		"Brightness", "ClockTime", "EnvironmentDiffuseScale",
		"EnvironmentSpecularScale", "GlobalIntensity",
		"OutdoorAmbient", "ShadowSoftness",
	}) do
		FPSSettings[setting] = lighting[setting]
	end
	pcall(function()
		lighting.Technology = Enum.Technology.Compatibility
		lighting.GlobalShadows = false
		lighting.Brightness = 0
		lighting.ClockTime = 14
		lighting.EnvironmentDiffuseScale = 0
		lighting.EnvironmentSpecularScale = 0
		lighting.GlobalIntensity = 0
		lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 100)
		lighting.ShadowSoftness = 0
	end)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
			or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
			obj.Enabled = false
		end
		if obj:IsA("Explosion") then
			pcall(function() obj.Visible = false end)
		end
		if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
			obj.Enabled = false
		end
	end
	Workspace.FallenPartsDestroyHeight = -999999
	setFpsTarget(FpsTarget)
end

local function fpsOff()
	local lighting = game:GetService("Lighting")
	for key, val in pairs(FPSSettings) do
		pcall(function() lighting[key] = val end)
	end
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam")
			or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
			obj.Enabled = true
		end
		if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
			obj.Enabled = true
		end
	end
	Workspace.FallenPartsDestroyHeight = -500
end

-- -------------------------------------------------------
--  PARASITE FARM
-- -------------------------------------------------------
do
	local pestRemotes = {}
	local pestMap = {
		Monster = "MonsterKill",
		Zombie = "ZombieKill",
		Vampire = "VampireKill",
		Boss = "BossKill",
		Dino = "DinoKill",
		Worm = "WormKill",
		Spider = "SpiderKill",
	}
	local monsterFolder = Workspace:FindFirstChild("MonsterModels") or Workspace:FindFirstChild("Monsters")

	local function setupPests()
		if not Config.ParasiteFarm then return end
		for name, remoteName in pairs(pestMap) do
			local remote = Remotes[remoteName]
			if remote then pestRemotes[name] = remote end
		end
		if monsterFolder then
			track(monsterFolder.ChildAdded:Connect(function(child)
				if not Config.ParasiteFarm then return end
				for name in pairs(pestRemotes) do
					if child.Name:lower():find(name:lower(), 1, true) then
						task.delay(0.15, function()
							if Config.ParasiteFarm then
								pcall(function() pestRemotes[name]:FireServer() end)
							end
						end)
					end
				end
			end))
		end
		for _, child in ipairs(monsterFolder and monsterFolder:GetChildren() or {}) do
			if Config.ParasiteFarm then
				for name in pairs(pestRemotes) do
					if child.Name:lower():find(name:lower(), 1, true) then
						pcall(function() pestRemotes[name]:FireServer() end)
					end
				end
			end
		end
	end

	local function startPestLoop()
		spawnLoop(function()
			while alive() do
				if Config.ParasiteFarm and monsterFolder then
					for _, child in ipairs(monsterFolder:GetChildren()) do
						for name in pairs(pestRemotes) do
							if child.Name:lower():find(name:lower(), 1, true) then
								pcall(function() pestRemotes[name]:FireServer() end)
							end
						end
					end
				end
				task.wait(1.5)
			end
		end)
	end

	setupPests()
	startPestLoop()
end

-- -------------------------------------------------------
--  TREADMILL
-- -------------------------------------------------------
do
	local function findTreadmill()
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("BasePart") and obj.Name:lower():find("treadmill", 1, true) then
				return obj
			end
		end
		return nil
	end

	local function getBelt()
		local tm = findTreadmill()
		if not tm then return nil end
		for _, child in ipairs(tm:GetDescendants()) do
			if child:IsA("BasePart") and child.Name:lower():find("belt", 1, true) then
				return child
			end
		end
		return tm
	end

	spawnLoop(function()
		while alive() do
			if Config.AutoTreadmill then
				local belt = getBelt()
				local hrp = root()
				if belt and hrp then
					local cf = belt.CFrame
					hrp.CFrame = cf * CFrame.new(0, 3, 0)
					callNet(Remotes.TreadmillStart)
					task.wait(1)
				end
			end
			task.wait(2)
		end
	end)
end

-- -------------------------------------------------------
--  AUTO FIRE PROX
-- -------------------------------------------------------
do
	local function fireNearbyPrompts()
		if not Config.AutoFireProx then return end
		local hrp = root()
		if not hrp then return end
		for _, obj in ipairs(Workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") and obj.Enabled then
				local ok, part = pcall(function() return obj.Parent end)
				if ok and part and part:IsA("BasePart") then
					local d = (part.Position - hrp.Position).Magnitude
					if d <= 30 then
						pcall(function() firePrompt(obj) end)
					end
				end
			end
		end
	end

	spawnLoop(function()
		while alive() do
			if Config.AutoFireProx then pcall(fireNearbyPrompts) end
			task.wait(1)
		end
	end)
end

FX.pickList = pickList
FX.areaLabels = areaLabels
FX.sortAreas = sortAreas
FX.Rarities = Rarities
FX.warnToast = warnToast
FX.goHome = goHome
FX.voidDrop = voidDrop
FX.sellPets = sellPets
FX._hatchAll = _hatchAll
FX.fpsOn = fpsOn
FX.fpsOff = fpsOff
FX.serverHop = serverHop
FX.autoStealOn = autoStealOn

end

-- -------------------------------------------------------
--  OBSIDIANULTRA UI
-- -------------------------------------------------------
do
	local genv = getgenv()
	local ls, ts, ss = genv._IvoryLibSrc, genv._IvoryTMSrc, genv._IvorySMSrc
	local Library, ThemeManager, SaveManager
	if ls then
		Library = loadstring(ls)()
		ThemeManager = loadstring(ts)()
		SaveManager = loadstring(ss)()
	else
		local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
		Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
		ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
		SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
	end
	if not Library then warn("[Ivory] ObsidianUltra load failed"); return end

	local Window = Library:CreateWindow({
		Title = "Ivory",
		Icon = "rbxassetid://110090697336524",
		Footer = {
			"v2.1 |",
			{ Text = "Steal An Egg", Copyable = true },
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

	local MainTab = Window:AddTab({ Name = "Main", Icon = "rbxassetid://110090697336524" })

	do
		local Sub = MainTab:AddSubTab("Steal", "rbxassetid://110090697336524")
		local L = Sub:AddLeftGroupbox("Egg Steal", "crosshair")
		local R = Sub:AddRightGroupbox("Base & Utility", "home")
		L:AddToggle("AutoSteal", { Text = "Auto Steal", Default = false, Callback = function(v)
			Config.AutoSteal = v
			if v then
				Config.PerfMode = true
				task.spawn(function()
					local ok = _Qk()
					Config.PhysReady = ok
					FX.warnToast(ok and "AC bypass active." or "Bypass failed.", 4)
				end)
				refreshTraps()
			else
				cancelTravel()
				releaseRoot()
			end
		end })
		L:AddDropdown("FarmMethod", { Text = "Farm Method", Values = { "Teleport", "TP Walk" }, Default = "TP Walk", Callback = function(v) Config.FarmMethod = v end })
		L:AddDropdown("AreaFocus", { Text = "Area Focus", Values = FX.areaLabels(), Multi = true, Callback = function(v) table.clear(Config.AreaFocus); for _, item in ipairs(v) do Config.AreaFocus[item] = true end end })
		L:AddDropdown("RarityFilter", { Text = "Rarity Filter", Values = FX.Rarities, Multi = true, Callback = function(v) table.clear(Config.RarityFilter); for _, item in ipairs(v) do Config.RarityFilter[item] = true end end })
		L:AddToggle("SecretPriority", { Text = "Secret Priority", Default = true, Callback = function(v) Config.SecretPriority = v end })
		L:AddToggle("AntiTrap", { Text = "Anti Trap", Default = true, Callback = function(v) Config.AntiTrap = v end })
		R:AddButton("Set Base Here", function() Config.ManualBase = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")) and LocalPlayer.Character.HumanoidRootPart.Position or nil; FX.warnToast(Config.ManualBase and "Base set!" or "No character.", 3) end)
		R:AddButton("Go Home", function() FX.goHome(20) end)
		R:AddButton("Void Drop", function() FX.voidDrop() end)
		R:AddButton("Sell Pets", function() FX.sellPets(false) end)
		R:AddButton("Sell All Eggs", function()
			local rarities = {}
			for _, name in ipairs(Rarities) do rarities[name] = true end
			callNet(Remotes.WriteAutoSell, rarities)
			callNet(Remotes.SatchelSale)
			FX.warnToast("Eggs sold!", 3)
		end)
		R:AddToggle("AutoSellEggs", { Text = "Auto Sell Eggs", Default = false, Callback = function(v)
			Config.AutoSellEggs = v
			if v then
				callNet(Remotes.WriteAutoSell, Config.SellEggRarities)
			else
				callNet(Remotes.WriteAutoSell, {})
			end
		end })
		R:AddDropdown("SellEggRarities", { Text = "Sell Egg Rarities", Values = FX.Rarities, Multi = true, Callback = function(v) table.clear(Config.SellEggRarities); for _, item in ipairs(v) do Config.SellEggRarities[item] = true end end })
	end

	do
		local Sub = MainTab:AddSubTab("Hatch & ESP", "rbxassetid://110090697336524")
		local L = Sub:AddLeftGroupbox("Hatching", "egg")
		local R = Sub:AddRightGroupbox("Visuals", "eye")
		L:AddToggle("AutoHatch", { Text = "Auto Hatch", Default = false, Callback = function(v) Config.AutoHatch = v end })
		L:AddButton("Hatch All (Walk)", function() FX._hatchAll(true) end)
		L:AddButton("Hatch All (TP)", function() FX._hatchAll(false) end)
		R:AddToggle("EggESP", { Text = "Egg ESP", Default = false, Callback = function(v) Config.EggESP = v end })
	end

	do
		local Sub = MainTab:AddSubTab("Automation", "rbxassetid://110090697336524")
		local L = Sub:AddLeftGroupbox("Farming", "sprout")
		local R = Sub:AddRightGroupbox("Performance", "zap")
		L:AddToggle("AutoEquipBest", { Text = "Auto Equip Best", Default = false, Callback = function(v) Config.AutoEquipBest = v end })
		L:AddToggle("ParasiteFarm", { Text = "Parasite Farm", Default = false, Callback = function(v) Config.ParasiteFarm = v end })
		L:AddToggle("AutoTreadmill", { Text = "Auto Treadmill", Default = false, Callback = function(v) Config.AutoTreadmill = v end })
		L:AddToggle("AutoFireProx", { Text = "Auto Fire Prox", Default = false, Callback = function(v) Config.AutoFireProx = v end })
		L:AddToggle("AntiAFK", { Text = "Anti AFK", Default = false, Callback = function(v) Config.AntiAFK = v end })
		R:AddToggle("FpsBoost", { Text = "FPS Boost", Default = false, Callback = function(v) if v then FX.fpsOn() else FX.fpsOff() end end })
		R:AddButton("Server Hop", function() FX.serverHop() end)
		R:AddButton("Join Discord For Dupe", function()
			if setclipboard then setclipboard("https://discord.gg/ivory") end
			FX.warnToast("Discord link copied!", 3)
		end)
	end

	do
		local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "rbxassetid://110090697336524" })
		ThemeManager:SetLibrary(Library)
		SaveManager:SetLibrary(Library)
		SaveManager:IgnoreThemeSettings()
		SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
		ThemeManager:SetFolder("IvoryHub")
		SaveManager:SetFolder("IvoryHub")
		SaveManager:SetSubFolder("game")
		ThemeManager:ApplyToTab(SettingsTab)
		SaveManager:BuildConfigSection(SettingsTab)
		local G = SettingsTab:AddLeftGroupbox("Menu", "settings")
		G:AddSlider("MenuKeybind", { Text = "Menu Keybind", Default = Enum.KeyCode.RightBracket.Value, Min = 0, Max = 400, Rounding = 0 })
		G:AddButton("Destroy UI", function() pcall(function() Library:Destroy() end) end)
		local AG = SettingsTab:AddLeftGroupbox("Anti-Cheat", "shield")
		AG:AddToggle("PerfMode", { Text = "Enable Anti-Cheat Bypass", Default = false, Callback = function(v)
			Config.PerfMode = v
			if v then
				Config.PhysReady = false
				task.spawn(function()
					local ok = _Qk()
					Config.PhysReady = ok
					FX.warnToast(ok and "AC bypass active." or "Bypass failed.", 4)
				end)
			else
				Config.PhysReady = false
				FX.warnToast("AC bypass disabled.", 3)
			end
		end })
	end
end

if Config.PhysReady then
	Config.PhysReady = false
end

print("[Ivory Hub] Steal An Egg loaded successfully!")