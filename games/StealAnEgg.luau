--// Ivory Hub | Steal An Egg
--// Place ID: 107778070777162
--// Core movement, egg stealing via remotes, trap avoidance

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
	AutoSteal = false,
	FarmMethod = "TP Walk",
	PerfMode = false,
	PhysReady = false,
	AntiTrap = true,
	TargetArea = "All",
	SelectedRarities = {},
	ManualBase = nil,
	SecretPriority = true,
	AutoHatch = false,
	AutoEquipBest = false,
	AutoClaim = false,
	AutoUpgrade = false,
	AntiAFK = false,
	EggESP = false,
	ServerHop = false,
	ServerHopDelay = 30,
	ServerHopCount = 0,
	ServerHopMax = 15,
	Unloaded = false,
}

local Threads = {}
local Conns = {}

-- ═══════════════════════════════════════════════════════
--  NETWORKING — remotes under ReplicatedStorage.Packages.Networking
-- ═══════════════════════════════════════════════════════
local NET = ReplicatedStorage:FindFirstChild("Packages")
NET = NET and NET:FindFirstChild("Networking") or nil

local Remotes = {
	EggSnapshot   = "RF/EggWorld/AskFieldEggSnapshot",
	EggCarry      = "RF/EggWorld/AskFieldEggCarry",
	EggPlace      = "RF/EggWorld/AskPlaceEgg",
	EggDrop       = "RF/EggWorld/AskFieldEggDrop",
	Hatch         = "RF/EggWorld/AskHatch",
	HatchFinish   = "RF/EggWorld/AskFinishHatch",
	SkipGrowth    = "RF/EggWorld/AskSkipGrowth",
	PlotState     = "RF/Homestead/AskState",
	BaseTierRaise = "RE/Homestead/AskBaseTierRaise",
	NearbyBuy     = "RE/Homestead/AskNearbyPurchase",
	Collect       = "RF/AwayEarnings/AskCollect",
	CodexAll      = "RF/Codex/AskRedeemAll",
	WearBest      = "RF/Haul/WearBest",
	SellEveryPet  = "RE/PetSatchel/SellEveryPet",
	PetWear       = "RF/PenRoster/AskWear",
	PetDoff       = "RF/PenRoster/AskDoff",
	TreadRaise    = "RF/Treadmill/AskTierRaise",
	WearTool      = "RF/EggWorld/AskWearTool",
	DoffTool      = "RF/EggWorld/AskDoffTool",
	RigWipe       = "RE/RigSync/AskRigWipe",
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

local function askUid(name, uid)
	local res = callNet(name, { Uid = uid })
	if res ~= nil and res ~= false then return true end
	local res2 = callNet(name, uid)
	if res2 ~= nil and res2 ~= false then return true end
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

-- ═══════════════════════════════════════════════════════
--  RARITY SYSTEM
-- ═══════════════════════════════════════════════════════
local Rarities = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary",
	"Mythic", "Cosmic", "Secret", "Divine", "Eternal",
	"Exotic", "Limited", "Exclusive", "Superior", "Titan",
}

local RarityCache = {}
local rarityLadder = {}
for i, name in ipairs(Rarities) do
	rarityLadder[name] = i
end

local function ladderOf(name)
	if type(name) ~= "string" then return 0 end
	return rarityLadder[name] or 0
end

local function rarityOf(rec)
	local v = rec.Rarity or rec.RarityName or rec.Tier or rec.RarityId
	if type(v) == "table" then
		v = v.DisplayName or v._id or v.Name or v.Id
	end
	return type(v) == "string" and v or nil
end

local function InitRaritySystem()
	pcall(function()
		local rarityData = require(ReplicatedStorage:WaitForChild("Data"):WaitForChild("Rarity"))
		if rarityData and rarityData.Configs then
			for name, config in pairs(rarityData.Configs) do
				if config.DisplayName then
					RarityCache[name] = config.DisplayName
				end
			end
		end
	end)
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
		local AREA_NAMES_ORDER = {"Forest", "Desert", "Lake", "Jungle", "Snow", "Volcano", "Prehistoric", "Abyss Ocean", "Cherry Blossom", "Cosmic", "Titan Temple"}
		for i, name in ipairs(AREA_NAMES_ORDER) do
			addArea(name, name, i, nil)
		end
	end
	table.sort(AreaData.areaOrder, function(a, b)
		local ra, rb = AreaData.areaRarity[a] or 0, AreaData.areaRarity[b] or 0
		if ra == rb then return tostring(AreaData.areaLabel[a]) < tostring(AreaData.areaLabel[b]) end
		return ra < rb
	end)
end

-- ═══════════════════════════════════════════════════════
--  EGG SNAPSHOT / FIELD EGG SYSTEM
-- ═══════════════════════════════════════════════════════
local EggList = {}
local EggListAt = 0
local TriedUids = {}
local FailUids = {}
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
				end
				local own = rarityOf(rec)
				if ladderOf(own) == 0 then own = nil end
				local name = own or (id and AreaData.areaTierName[id]) or rarityOf(rec)
				list[#list + 1] = {
					uid = rec.Uid,
					area = id,
					label = id and AreaData.areaLabel[id] or "Unknown",
					pos = pos,
					tier = id and AreaData.areaRarity[id] or 0,
					rarity = name,
					rank = ladderOf(name),
					mutated = isMutated(rec),
					size = rec.BoundsSize and rec.BoundsSize.Magnitude or 3,
				}
			end
		end
	end
	EggList = list
	EggListAt = tick()
	return list
end

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
--  MOVEMENT — floor raycast, pinRoot, releaseRoot
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
--  ROUTING — walkability, hub centroid, routeTo
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
--  TRAVEL — tpLeg (45-stud CFrame steps) + travelLeg (speed slide)
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

-- Travel safety watchdog
track(RunService.Heartbeat:Connect(function()
	if Travelling and tick() - TravelStep > 6 then
		Travelling = false
		releaseRoot()
	end
end))

-- Reset state on respawn
track(LocalPlayer.CharacterAdded:Connect(function()
	cancelTravel()
	TravelStep = 0
	Config.PhysReady = false
end))

-- ═══════════════════════════════════════════════════════
--  PLOT / BASE DETECTION
-- ═══════════════════════════════════════════════════════
local CachedPlot = nil
local CachedSlot = nil
local PlotTried = 0

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

local function penPivot()
	local p = myPlot()
	if p then
		for _, d in ipairs(p:GetDescendants()) do
			if d.Name:lower():find("pen", 1, true) then
				if d:IsA("BasePart") then return d.CFrame end
				if d:IsA("Model") then
					local ok, pv = pcall(function() return d:GetPivot() end)
					if ok and pv then return pv end
				end
			end
		end
	end
	local base = plotPivot()
	return base and (base * CFrame.new(0, 0, 15)) or nil
end

local function baseOrigins()
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
	return list
end

local function inRange(pos, reach)
	local hrp = root()
	if not hrp or not pos then return false end
	local a = Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
	local b = Vector3.new(pos.X, 0, pos.Z)
	return (a - b).Magnitude <= (reach or 12) + 8
end

-- ═══════════════════════════════════════════════════════
--  EGG STEALING — grab, hold, deliver
-- ═══════════════════════════════════════════════════════
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

local CarryingUid = nil
local DeliverFails = 0
local DryRuns = 0

local function autoStealOn()
	return alive() and Config.AutoSteal
end

local function getSelectedRarities()
	local sel = {}
	local raw = Options.RarityFilter and Options.RarityFilter.Value
	if type(raw) == "table" then
		for k, v in pairs(raw) do
			if v == true or v == 1 or v == "Selected" then
				sel[#sel + 1] = tostring(k):lower()
			end
		end
	elseif type(raw) == "string" and #raw > 0 then
		sel[#sel + 1] = raw:lower()
	end
	return sel
end

local function pickEgg()
	local hrp = root()
	if not hrp then return nil end
	refreshEggs(false)
	local origin = hrp.Position
	local best, bestScore
	local selRarities = getSelectedRarities()
	for i = 1, #EggList do
		local e = EggList[i]
		-- area filter
		if Config.TargetArea ~= "All" and e.label ~= Config.TargetArea then
			-- skip
		else
			-- rarity filter
			local rarityOk = #selRarities == 0
			if not rarityOk then
				local eRarity = e.rarity and e.rarity:lower() or ""
				for _, r in ipairs(selRarities) do
					if r == eRarity then rarityOk = true; break end
				end
			end
			if rarityOk then
				-- cooldown check
				local at = TriedUids[e.uid]
				if at then
					local f = FailUids[e.uid] or 0
					local hold = 6
					if f >= 4 then hold = 600
					elseif f == 3 then hold = 120
					elseif f == 2 then hold = 45
					elseif f == 1 then hold = 18 end
					if tick() - at < hold then rarityOk = false end
				end
			end
			if rarityOk then
				local d = (e.pos - origin).Magnitude
				local tier = e.tier > 0 and e.tier or e.rank
				local score = e.rank * 1e12 + tier * 1e8 + (e.mutated and 1e6 or 0) - math.min(d, 1e5)
				if not bestScore or score > bestScore then
					best, bestScore = e, score
				end
			end
		end
	end
	return best
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

local function placeEggOnBase(uid)
	local basePos = Config.ManualBase or (plotPivot() and plotPivot().Position)
	if not basePos then return false end
	if not inRange(basePos, 20) then
		travelTo(basePos, 12, autoStealOn)
	end
	-- Try AskPlaceEgg remote
	local r = net(Remotes.EggPlace)
	if r and r:IsA("RemoteFunction") then
		local origins = baseOrigins()
		local o = origins[1]
		if o and holdingEgg() then
			local lp = (o:Inverse() * CFrame.new(basePos)).Position
			local lcf = CFrame.new(lp)
			local ok, res = pcall(function()
				return r:InvokeServer({ Uid = uid, LocalCFrame = lcf })
			end)
			if ok and (res == true or res == nil) then
				for _ = 1, 16 do
					if not holdingEgg() then return true end
					RunService.Heartbeat:Wait()
				end
			end
		end
	end
	-- Fallback: smart place prompt
	for _, pp in ipairs({ smartPlacePrompt() }) do
		if promptInRange(pp) and firePrompt(pp) then
			for _ = 1, 12 do
				if not holdingEgg() then return true end
				RunService.Heartbeat:Wait()
			end
		end
	end
	-- Last resort: doff
	askUid(Remotes.DoffTool, uid)
	return not holdingEgg()
end

local function deliver(uid)
	local basePos = Config.ManualBase or (plotPivot() and plotPivot().Position)
	if basePos and not inRange(basePos, 26) then
		travelTo(basePos, 14, autoStealOn)
	end
	if Config.FarmMethod == "TP Walk" then
		askUid(Remotes.DoffTool, uid)
		return true
	end
	return placeEggOnBase(uid)
end

-- ═══════════════════════════════════════════════════════
--  MAIN AUTO STEAL LOOP
-- ═══════════════════════════════════════════════════════
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
					if deliver(CarryingUid) then
						CarryingUid = nil
						DeliverFails = 0
					else
						DeliverFails = DeliverFails + 1
						if DeliverFails >= 4 then
							DeliverFails = 0
							askUid(Remotes.DoffTool, CarryingUid)
							CarryingUid = nil
						end
					end
					return
				end
				-- Secret Priority
				if Config.SecretPriority then
					refreshEggs(false)
					for i = 1, #EggList do
						local e = EggList[i]
						if e.rank >= (rarityLadder.Secret or 8) then
							-- found a secret+, pick it
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
				local keep = function()
					return autoStealOn() and eggAlive(e.uid)
				end
				local target = e.pos
				local part = eggPart(e.uid)
				if part then target = part.Position end
				if not inRange(target, reach) then
					travelTo(target, reach, keep)
					if not autoStealOn() then return end
				end
				local got = grabEgg(e.uid)
				if not got then
					task.wait(0.1)
					got = grabEgg(e.uid)
				end
				if got then
					FailUids[e.uid] = nil
					CarryingUid = e.uid
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
		if idle > 0 then
			task.wait(idle)
		else
			RunService.Heartbeat:Wait()
		end
	end
end)

-- ═══════════════════════════════════════════════════════
--  ANTI TRAP LOOP
-- ═══════════════════════════════════════════════════════
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

-- ═══════════════════════════════════════════════════════
--  ESP
-- ═══════════════════════════════════════════════════════
local ESPTags = {}
local ESPFolder = nil

local rarityColor = {
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

local function espParent()
	if ESPFolder and ESPFolder.Parent then return ESPFolder end
	ESPFolder = Instance.new("Folder")
	ESPFolder.Name = "IvoryEggESP"
	ESPFolder.Parent = LocalPlayer:WaitForChild("PlayerGui")
	return ESPFolder
end

local function clearESP()
	for uid, tag in pairs(ESPTags) do
		pcall(function() tag:Destroy() end)
		ESPTags[uid] = nil
	end
	if ESPFolder then
		pcall(function() ESPFolder:Destroy() end)
		ESPFolder = nil
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

-- ═══════════════════════════════════════════════════════
--  AUTOMATION LOOPS
-- ═══════════════════════════════════════════════════════
local function hatchAll()
	local records = {}
	local live = callNet(Remotes.EggSnapshot)
	local recs = live and live.Records
	if type(recs) == "table" then
		for _, rec in pairs(recs) do
			if type(rec) == "table" and rec.Uid then records[#records + 1] = rec end
		end
	end
	local n = 0
	for _, rec in ipairs(records) do
		local uid = rec.Uid
		if uid then
			askUid(Remotes.SkipGrowth, uid)
			askUid(Remotes.Hatch, uid)
			askUid(Remotes.HatchFinish, uid)
			task.wait(0.06)
			n = n + 1
		end
	end
	return n
end

spawnLoop(function()
	while alive() do
		if Config.AutoHatch and charReady() and not Travelling then
			pcall(hatchAll)
		end
		task.wait(2)
	end
end)

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

-- ═══════════════════════════════════════════════════════
--  SERVER HOP
-- ═══════════════════════════════════════════════════════
local function serverList()
	local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
		.. "/servers/Public?sortOrder=Desc&excludeFullGames=true&limit=100"
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if not ok or type(body) ~= "string" then return {} end
	local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
	if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" then return {} end
	local out = {}
	for _, s in ipairs(data.data) do
		if s.id and s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 30) then
			out[#out + 1] = s.id
		end
	end
	for i = #out, 2, -1 do
		local j = math.random(i)
		out[i], out[j] = out[j], out[i]
	end
	return out
end

local function serverHop()
	local list = serverList()
	for _, id in ipairs(list) do
		Config.ServerHopCount = Config.ServerHopCount + 1
		local ok = pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer)
		end)
		if ok then
			task.wait(6)
			return true
		end
	end
	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
	return #list > 0
end

spawnLoop(function()
	while alive() do
		if Config.ServerHop then
			if Config.ServerHopCount >= Config.ServerHopMax then
				Config.ServerHop = false
			else
				pcall(serverHop)
			end
		end
		task.wait(math.clamp(Config.ServerHopDelay, 5, 300))
	end
end)

-- ═══════════════════════════════════════════════════════
--  OBSIDIANULTRA UI
-- ═══════════════════════════════════════════════════════
local genv = getgenv()
local Library = nil
local ThemeManager = nil
local SaveManager = nil

local libSrc = genv._IvoryLibSrc
local tmSrc = genv._IvoryTMSrc
local smSrc = genv._IvorySMSrc

if libSrc then
	Library = loadstring(libSrc)()
	ThemeManager = loadstring(tmSrc)()
	SaveManager = loadstring(smSrc)()
else
	local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
	pcall(function() Library = loadstring(game:HttpGet(repo .. "Library.lua"))() end)
	pcall(function() ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))() end)
	pcall(function() SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))() end)
end

if not Library then warn("[Ivory] ObsidianUltra failed to load") return end

local Toggles = Library.Toggles
local Options = Library.Options

local Window = Library:CreateWindow({
	Title = "Ivory",
	Footer = {
		"v1.4 |",
		{ Text = "Lobby/Game", Copyable = true },
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
	ShowCustomCursor = false,
	CornerRadius = 4,
	Animations = {
		SubTabUnderline = true,
	},
})

local Tabs = {
	Main = Window:AddTab({ Name = "Main", Icon = "home", Description = "Steal & Automate" }),
	Visuals = Window:AddTab({ Name = "Visuals", Icon = "eye", Description = "ESP" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Themes & UI" }),
}

-- ═══════════════════════════════════════════════════════════
--  MAIN TAB — STEAL SUBTAB
-- ═══════════════════════════════════════════════════════════
local StealSub = Tabs.Main:AddSubTab("Steal", "zap")

local MovementBox = StealSub:AddLeftGroupbox("Movement", "arrow-up-circle")

MovementBox:AddToggle("PerfMode", {
	Text = "Performance Mode",
	Default = false,
	Callback = function(state)
		Config.PerfMode = state
		if state then
			task.spawn(function()
				local ok = _Qk()
				Config.PhysReady = ok
			end)
		else
			Config.PhysReady = false
		end
	end,
})

MovementBox:AddToggle("AntiTrap", {
	Text = "Anti-Trap",
	Default = true,

	Callback = function(state)
		Config.AntiTrap = state
		if state then task.spawn(refreshTraps) end
	end,
})

MovementBox:AddDropdown("FarmMethod", {
	Text = "Farm Method",
	Values = { "TP Walk", "Speed" },
	Default = "TP Walk",

	Callback = function(state)
		Config.FarmMethod = state
		cancelTravel()
	end,
})

local TargetingBox = StealSub:AddRightGroupbox("Targeting", "crosshair")

local areaOptions = { "All" }
for _, area in ipairs(AreaData.areaOrder) do
	table.insert(areaOptions, AreaData.areaLabel[area])
end

TargetingBox:AddDropdown("TargetArea", {
	Text = "Target Area",
	Values = areaOptions,
	Default = "All",
	Callback = function(state)
		Config.TargetArea = state
	end,
})

TargetingBox:AddDropdown("RarityFilter", {
	Text = "Rarity Filter",
	Values = Rarities,
	Default = {},
	Multi = true,
	Callback = function(state)
		local arr = {}
		if type(state) == "table" then
			for k, v in pairs(state) do
				if v == true or v == 1 or v == "Selected" then
					arr[#arr + 1] = k
				end
			end
		end
		Config.SelectedRarities = arr
	end,
})

TargetingBox:AddToggle("SecretPriority", {
	Text = "Secret Egg Priority",
	Default = true,
	Callback = function(state)
		Config.SecretPriority = state
	end,
})

-- ═══════════════════════════════════════════════════════════
--  MAIN TAB — AUTO STEAL SUBTAB
-- ═══════════════════════════════════════════════════════════
local AutoStealSub = Tabs.Main:AddSubTab("Auto Steal", "download")

local StealControlsBox = AutoStealSub:AddLeftGroupbox("Controls", "play")

StealControlsBox:AddToggle("AutoStealEggs", {
	Text = "Auto Steal Eggs",
	Default = false,
	Callback = function(state)
		Config.AutoSteal = state
		if state then
			Config.PerfMode = true
			task.spawn(function()
				_Ek()
				refreshTraps()
			end)
		else
			cancelTravel()
			releaseRoot()
		end
	end,
})

StealControlsBox:AddButton("Set Base Here", function()
	local r = root()
	if r then Config.ManualBase = r.Position end
end)

StealControlsBox:AddButton("Clear Base Pin", function()
	Config.ManualBase = nil
end)

StealControlsBox:AddButton("Steal Nearest Egg", function()
	if not charReady() then return end
	local hrp = root()
	if not hrp then return end
	refreshEggs(false)
	local best, bestDist
	local selRarities = getSelectedRarities()
	for _, e in ipairs(EggList) do
		if Config.TargetArea == "All" or e.label == Config.TargetArea then
			local rarityOk = #selRarities == 0
			if not rarityOk then
				local eRarity = e.rarity and e.rarity:lower() or ""
				for _, r in ipairs(selRarities) do
					if r == eRarity then rarityOk = true; break end
				end
			end
			if rarityOk then
				local d = (e.pos - hrp.Position).Magnitude
				if not bestDist or d < bestDist then
					best, bestDist = e, d
				end
			end
		end
	end
	if best then
		local reach = math.max(9, best.size * 0.6 + 7)
		if not inRange(best.pos, reach) then
			travelTo(best.pos, reach)
		end
		grabEgg(best.uid)
		task.wait(0.2)
		local basePos = Config.ManualBase or (plotPivot() and plotPivot().Position)
		if basePos then
			travelTo(basePos, 12)
			askUid(Remotes.DoffTool, best.uid)
		end
	end
end)

local StealAreasBox = AutoStealSub:AddRightGroupbox("Areas", "map")

StealAreasBox:AddButton("Refresh Areas", function()
	table.clear(AreaData.areaLabel)
	table.clear(AreaData.areaRarity)
	table.clear(AreaData.areaTierName)
	table.clear(AreaData.areaByLabel)
	table.clear(AreaData.areaOrder)
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
	table.sort(AreaData.areaOrder, function(a, b)
		local ra, rb = AreaData.areaRarity[a] or 0, AreaData.areaRarity[b] or 0
		if ra == rb then return tostring(AreaData.areaLabel[a]) < tostring(AreaData.areaLabel[b]) end
		return ra < rb
	end)
	Library:Notify({ Title = "Ivory", Description = "Areas refreshed (" .. #AreaData.areaOrder .. " found)", Type = "Success", Time = 2 })
end)

StealAreasBox:AddButton("Join Discord For Dupe", function()
	pcall(function()
		if setclipboard then setclipboard("https://discord.gg/MCWYKBdB4E") end
	end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied to clipboard!", Type = "Info", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════════
--  MAIN TAB — AUTOMATION SUBTAB
-- ═══════════════════════════════════════════════════════════
local AutoSub = Tabs.Main:AddSubTab("Automation", "settings")

local HatchBox = AutoSub:AddLeftGroupbox("Hatch & Pets", "box")

HatchBox:AddToggle("AutoHatch", {
	Text = "Auto Hatch Eggs",
	Default = false,
	Callback = function(state) Config.AutoHatch = state end,
})

HatchBox:AddButton("Hatch Once", function()
	task.spawn(function() pcall(hatchAll) end)
end)

HatchBox:AddToggle("AutoEquipBest", {
	Text = "Auto Equip Best Pet",
	Default = false,
	Callback = function(state) Config.AutoEquipBest = state end,
})

local ClaimBox = AutoSub:AddRightGroupbox("Claim & Upgrade", "arrow-up")

ClaimBox:AddToggle("AutoClaim", {
	Text = "Auto Claim",
	Default = false,
	Callback = function(state)
		Config.AutoClaim = state
		if state then
			spawnLoop(function()
				while alive() and Config.AutoClaim and charReady() and not Travelling do
					pcall(function()
						local pp = promptsUnder(myPlot(), { "claim", "collect", "coin", "cash" })
						for _, p in ipairs(pp) do
							if promptInRange(p) and firePrompt(p) then task.wait(0.06) end
						end
						callNet(Remotes.Collect)
						callNet(Remotes.CodexAll)
					end)
					task.wait(20)
				end
			end)
		end
	end,
})

ClaimBox:AddToggle("AutoUpgrade", {
	Text = "Auto Upgrade",
	Default = false,
	Callback = function(state)
		Config.AutoUpgrade = state
		if state then
			spawnLoop(function()
				while alive() and Config.AutoUpgrade and charReady() and not Travelling do
					pcall(function()
						local pp = promptsUnder(myPlot(), { "upgrade", "buy", "purchase", "tier", "level" })
						for _, p in ipairs(pp) do
							if promptInRange(p) and firePrompt(p) then task.wait(0.06) end
						end
						callNet(Remotes.BaseTierRaise)
						callNet(Remotes.NearbyBuy)
					end)
					task.wait(30)
				end
			end)
		end
	end,
})

ClaimBox:AddToggle("AntiAFK", {
	Text = "Anti AFK",
	Default = false,
	Callback = function(state) Config.AntiAFK = state end,
})

-- ═══════════════════════════════════════════════════════════
--  VISUALS TAB — EGG ESP
-- ═══════════════════════════════════════════════════════════
local ESPSub = Tabs.Visuals:AddSubTab("Egg ESP", "eye")

local ESPBox = ESPSub:AddLeftGroupbox("Egg ESP", "circle")

ESPBox:AddToggle("ShowEggESP", {
	Text = "Show Egg ESP",
	Default = false,
	Callback = function(state)
		Config.EggESP = state
		if not state then clearESP() end
	end,
})

ESPBox:AddButton("Refresh ESP", function()
	clearESP()
	refreshEggs(true)
end)

-- ═══════════════════════════════════════════════════════════
--  SETTINGS TAB
-- ═══════════════════════════════════════════════════════════
local ThemesSub = Tabs.Settings:AddSubTab("Themes & UI", "palette")
local ConfigSub = Tabs.Settings:AddSubTab("Config", "file-text")
local ServerSub = Tabs.Settings:AddSubTab("Server", "server")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("stealanegg")

local MenuGroup = ThemesSub:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddButton("Unload", function()
	Config.Unloaded = true
	Config.AutoSteal = false
	cancelTravel()
	releaseRoot()
	clearESP()
	for _, c in ipairs(Conns) do
		pcall(function() c:Disconnect() end)
	end
	for _, th in ipairs(Threads) do
		pcall(task.cancel, th)
	end
	Library:Unload()
end)

ThemeManager:ApplyToTab(ThemesSub)
SaveManager:BuildConfigSection(ConfigSub)

local ServerGroup = ServerSub:AddLeftGroupbox("Server Hop", "globe")

ServerGroup:AddSlider("ServerHopDelay", {
	Text = "Hop Delay (s)",
	Default = 30,
	Min = 10,
	Max = 300,
	Rounding = 0,
	Callback = function(v) Config.ServerHopDelay = v end,
})

ServerGroup:AddToggle("AutoServerHop", {
	Text = "Auto Server Hop",
	Default = false,
	Callback = function(state) Config.ServerHop = state end,
})

ServerGroup:AddButton("Hop Now", function()
	task.spawn(serverHop)
end)

ServerGroup:AddButton("Rejoin Server", function()
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

InitRaritySystem()

Library:Notify({
	Title = "Ivory",
	Description = "Steal An Egg loaded. RightBracket to toggle menu.",
	Type = "Success",
	Time = 3,
})
