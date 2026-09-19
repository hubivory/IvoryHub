--[[
    Ivory Hub - Steal an Egg
    PlaceId: 107778070777162
    Version: 1.4
    1:1 KiraHub port (game logic), IvoryHub UI/branding
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local ProximityPromptService = game:GetService("ProximityPromptService")
local PhysicsService = game:GetService("PhysicsService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	pcall(function() Players:GetPropertyChangedSignal("LocalPlayer"):Wait() end)
	LocalPlayer = Players.LocalPlayer
end

local UserId = tostring(LocalPlayer and LocalPlayer.UserId or 0)
local PLACE_ID = game.PlaceId

local function waitChar()
	local deadline = os.clock() + 60
	while LocalPlayer and os.clock() < deadline do
		local c = LocalPlayer.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local hrp = c and c:FindFirstChild("HumanoidRootPart")
		if h and hrp and h.Health > 0 then task.wait(0.45) return c, hrp, h end
		task.wait(0.1)
	end
	return nil, nil, nil
end

local char, hrp, humanoid = waitChar()

-- ═══════════════════════════════════════════════
-- LIBRARY LOADING
-- ═══════════════════════════════════════════════
local httpGet do
	local fn = request or http_request or (syn and syn.request)
	if fn then httpGet = function(url) local r = fn({Url=url,Method="GET"}); return r and r.Body end
	else httpGet = function(url) return game:HttpGet(url,true) end end
end

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER.."/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder,LIB_FOLDER) end
if not isfile(LIB_FILE) then writefile(LIB_FILE,httpGet(LIB_URL)) end
local Library = loadstring(readfile(LIB_FILE))()

-- ═══════════════════════════════════════════════
-- CONSTANTS
-- ═══════════════════════════════════════════════
local AREAS = {"Forest","Desert","Lake","Jungle","Snow","Volcano","Prehistoric","Cosmic","Abyss Ocean","Cherry Blossom"}
local RARITIES = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine","Titan"}
local MUTATIONS = {"Golden","Rainbow","Galaxy","Crystal","Bloom"}

-- ═══════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════
local cfg = {
	AutoSteal = false, StealTravel = "Speed", StealSpeed = 300,
	StealMode = "Best value", GenSnipeFloor = "",
	Areas = {"Forest","Desert","Lake","Jungle","Snow","Volcano","Prehistoric","Cosmic","Abyss Ocean","Cherry Blossom"},
	UseRarity = false, Rarities = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine","Titan"},
	UseMutation = false, Mutations = {"Golden","Rainbow","Galaxy","Crystal","Bloom"},
	MinWeight = "", AutoEvent = false, EventKeepGen = "",
	AutoPlaceEggs = false, NeverPlaceRarity = "Place all", PlaceMinGen = "",
	AutoHatch = false, EquipBest = false,
	UpgTrails = false, UpgTreadmill = false, UpgPen = false, KeepMoney = "",
	SellUnderGen = "", AutoSellPets = false, AutoSellEggs = false,
	AutoTreadmill = false, TrainWhenIdle = true, ReadyEarly = 4,
	AutoHop = false, HopIdle = "", HopAfter = "", HopPages = 3, HopSkipFull = true, HopPlayers = "Lowest",
	EggESP = false, ESPFilter = "All eggs", ESPBeam = false, PlotESP = false,
	StatsPanel = false, ClaimIndex = false,
	AntiTrap = false, AntiMob = false, BatAura = false,
	BypassSpeed = false, BypassCap = 880,
	Flight = false, FlightSpeed = 880, FlightBind = Enum.KeyCode.F,
	Optimizer = false, FPSCap = 0,
	HookEnabled = false, HookUrl = "https://", HookStolen = true, HookHatched = true,
	HookSold = false, HookRewards = false, HookMinGen = "", HookRarityFloor = "Any",
	SessionDigest = false, HookPing = "No ping", HookUserId = "", HookUsername = false, ExportUrl = false,
	OpenBind = Enum.KeyCode.RightShift, StartMin = false, Theme = "Dark",
	MenuKeybind = "RightShift", UIScale = 100,
}

-- ═══════════════════════════════════════════════
-- SAVE / LOAD CONFIG
-- ═══════════════════════════════════════════════
local CONFIG_FOLDER = "IvoryHub"
local CONFIG_FILE = CONFIG_FOLDER.."/StealAnEgg_Config.json"
local function saveConfig()
	pcall(function()
		if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
		local data = {}
		for k,v in pairs(cfg) do data[k]=v end
		writefile(CONFIG_FILE, HttpService:JSONEncode(data))
	end)
end
local function loadConfig()
	pcall(function()
		if isfile(CONFIG_FILE) then
			local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
			for k,v in pairs(data) do if cfg[k]~=nil then cfg[k]=v end end
		end
	end)
end
loadConfig()

-- ═══════════════════════════════════════════════
-- CONNECTION TRACKING
-- ═══════════════════════════════════════════════
local isRunning = true
local allConns = {}
local function addConn(c) if c then allConns[#allConns+1]=c end; return c end

-- ═══════════════════════════════════════════════
-- CHARACTER HELPERS
-- ═══════════════════════════════════════════════
local function getChar()
	local c = LocalPlayer.Character
	if not c then return nil,nil,nil end
	return c, c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
end

local function getNetworking()
	return ReplicatedStorage:FindFirstChild("Packages") and ReplicatedStorage.Packages:FindFirstChild("Networking")
end
local function getRF(cat,name)
	local net = getNetworking(); if not net then return nil end
	local folder = net:FindFirstChild("RF") and net.RF:FindFirstChild(cat)
	return folder and folder:FindFirstChild(name)
end
local function getRE(cat,name)
	local net = getNetworking(); if not net then return nil end
	local folder = net:FindFirstChild("RE") and net.RE:FindFirstChild(cat)
	return folder and folder:FindFirstChild(name)
end
local function fireRemote(cat,name,...)
	local rf = getRF(cat,name)
	if typeof(rf)=="Instance" and rf:IsA("RemoteFunction") then return rf:InvokeServer(...) end
	local re = getRE(cat,name)
	if typeof(re)=="Instance" and re:IsA("RemoteEvent") then re:FireServer(...); return true end
	return false
end
local function invokeRemote(cat,name,...)
	local rf = getRF(cat,name)
	if typeof(rf)=="Instance" and rf:IsA("RemoteFunction") then return rf:InvokeServer(...) end
	return false,"not RF"
end

local function getPlotInfo()
	local ok,info = pcall(function() return require(ReplicatedStorage.Client.PlotState).ResolvePlot() end)
	if ok and type(info)=="table" then return info end
	return nil
end
local function getPlotPosition()
	local info = getPlotInfo()
	if info then
		if typeof(info.RespawnPointCFrame)=="CFrame" then return info.RespawnPointCFrame.Position + Vector3.new(0,4,0) end
		local sp = info.PlotFolder and info.PlotFolder:FindFirstChild("SpawnPoint",true)
		if sp and sp:IsA("BasePart") then return sp.Position+Vector3.new(0,4,0) end
	end
	return nil
end
local function getSafeZone()
	local sp = workspace:FindFirstChildOfClass("SpawnLocation")
	if sp and sp:IsA("BasePart") then return sp.Position+Vector3.new(0,4,0) end
	return getPlotPosition()
end

local function getEggWorld()
	local ok,mod = pcall(function()
		local c = ReplicatedStorage:FindFirstChild("Client")
		if c then return require(c:FindFirstChild("EggState") or c:FindFirstChild("PlotState")) end
	end)
	if ok and type(mod)=="table" then return mod end
	return nil
end

local function readFieldEggs()
	local ew = getEggWorld(); if not ew then return {} end
	local fn = ew.SyncFieldEggs or ew.ReadFieldEggs
	if type(fn)~="function" then return {} end
	local ok,res = pcall(fn)
	if not ok or type(res)~="table" then return {} end
	local recs = res.Records; if type(recs)~="table" then return {} end
	local eggs = {}
	for _,v in pairs(recs) do
		if type(v)=="table" and v.Uid then eggs[#eggs+1]=v end
	end
	return eggs
end

local function getEggPosition(rec)
	if type(rec)~="table" then return nil end
	-- Use BoundsCFrame directly from the record (primary source)
	if typeof(rec.BoundsCFrame)=="CFrame" then return rec.BoundsCFrame.Position + Vector3.new(0,3,0) end
	if typeof(rec.BottomCFrame)=="CFrame" then return rec.BottomCFrame.Position + Vector3.new(0,3,0) end
	-- Try EggState module function
	local ew = getEggWorld()
	if ew and type(ew.GetFieldEggPosition)=="function" then
		local ok,pos = pcall(ew.GetFieldEggPosition,rec)
		if ok and typeof(pos)=="Vector3" then return pos end
	end
	return nil
end

local function getEggEarning(rec,cd)
	-- Egg records don't have EarningRate directly; use AssetScale as proxy
	if type(rec)=="table" then
		local scale = tonumber(rec.AssetScale) or 1
		local base = 10 * scale
		return base
	end
	return 0
end
local function getEggRarity(rec)
	if type(rec)~="table" then return "?" end
	-- Rarity is derived from AssetCategory via data lookup
	-- For now, use AssetCategory as the name
	return tostring(rec.AssetCategory or "?")
end
local function getRarityNumber(rec)
	-- Egg records don't have Rarity.RarityNumber directly
	-- Use AssetScale as a rough proxy for rarity (bigger = rarer)
	if type(rec)=="table" then return tonumber(rec.AssetScale) or 1 end
	return 1
end
local function formatMoney(n)
	n=tonumber(n) or 0; local a=math.abs(n)
	if a>=1e12 then return string.format("%.2fT",n/1e12) end
	if a>=1e9 then return string.format("%.2fB",n/1e9) end
	if a>=1e6 then return string.format("%.2fm",n/1e6) end
	if a>=1e3 then return string.format("%.1fk",n/1e3) end
	return string.format("%.0f",n)
end
local function parseMoney(s)
	if type(s)~="string" or s=="" then return 0 end
	s=string.lower(s); local num=tonumber(s:match("([%d%.]+)"))
	if not num then return 0 end
	if s:find("t") then return num*1e12 end
	if s:find("b") then return num*1e9 end
	if s:find("m") then return num*1e6 end
	if s:find("k") then return num*1e3 end
	return num
end
local function getEggAssetConfig(rec)
	-- EggState records don't have a separate config - use record directly
	return rec
end
local function isNearPlot(pos)
	if typeof(pos)~="Vector3" then return false end
	local info = getPlotInfo()
	if not info or not info.PlotFolder then return false end
	local c = info.CenterPoint
	if c and c:IsA("BasePart") then return (Vector3.new(pos.X-c.Position.X,0,pos.Z-c.Position.Z)).Magnitude<=56 end
	local pp = info.PlotFolder:FindFirstChildWhichIsA("BasePart")
	if pp then return (Vector3.new(pos.X-pp.Position.X,0,pos.Z-pp.Position.Z)).Magnitude<=56 end
	return false
end
local function matchesFilter(rec)
	local pos = getEggPosition(rec); if not pos then return false end
	if isNearPlot(pos) then return false end
	local state = rec.State; if state~="Slot" and state~="Dropped" then return false end
	local carrier = tonumber(rec.CarrierUserId)
	if carrier and carrier~=0 and carrier~=LocalPlayer.UserId then return false end
	local af = cfg.Areas
	if type(af)=="table" and #af<#AREAS then
		local aid = tostring(rec.AreaId or ""); local areaMatch=false
		for _,a in ipairs(af) do if a==aid then areaMatch=true; break end end
		if not areaMatch then return false end
	end
	if cfg.UseRarity then
		local rar = getEggRarity(rec); local rm=false
		for _,r in ipairs(cfg.Rarities) do if r==rar then rm=true; break end end
		if not rm then return false end
	end
	if cfg.UseMutation then
		local muts = rec.Mutations
		if type(muts)=="table" and #muts>0 then
			local mm=false
			for _,m in ipairs(muts) do for _,f in ipairs(cfg.Mutations) do if m==f then mm=true; break end end; if mm then break end end
			if not mm then return false end
		end
	end
	local mw = parseMoney(cfg.MinWeight)
	if mw>0 then local w=tonumber(rec.ModelWeight) or 0; if w>0 and w<mw then return false end end
	return true
end
local function pickBestEgg(eggs)
	local mode = cfg.StealMode or "Best value"
	local list = {}
	for _,rec in ipairs(eggs) do
		if matchesFilter(rec) then
			local cd = getEggAssetConfig(rec)
			local earn = getEggEarning(rec,cd)
			local rar = getRarityNumber(rec)
			if mode=="Gen ($/s) snipe" then
				local floor = parseMoney(cfg.GenSnipeFloor)
				if floor>0 and earn<floor then continue end
			end
			list[#list+1] = {rec=rec, cfg=cd, earn=earn, rar=rar, name=tostring(rec.Uid or "")}
		end
	end
	table.sort(list, function(a,b)
		if mode=="Rarity snipe" or mode=="Egg type filter" then
			if a.rar~=b.rar then return a.rar>b.rar end
			if a.earn~=b.earn then return a.earn>b.earn end
		else
			if a.earn~=b.earn then return a.earn>b.earn end
			if a.rar~=b.rar then return a.rar>b.rar end
		end
		return a.name < b.name
	end)
	return list[1]
end

local function rarityColor(rn)
	rn = tonumber(rn) or 0
	if rn>=11 then return Color3.fromRGB(255,236,150) end
	if rn>=10 then return Color3.fromRGB(255,90,210) end
	if rn>=9 then return Color3.fromRGB(120,210,255) end
	if rn>=8 then return Color3.fromRGB(255,80,110) end
	if rn>=7 then return Color3.fromRGB(255,186,70) end
	if rn>=6 then return Color3.fromRGB(186,120,255) end
	if rn>=5 then return Color3.fromRGB(255,220,90) end
	if rn>=4 then return Color3.fromRGB(160,120,255) end
	if rn>=3 then return Color3.fromRGB(90,170,255) end
	if rn>=2 then return Color3.fromRGB(120,200,120) end
	return Color3.fromRGB(210,210,210)
end

-- ═══════════════════════════════════════════════
-- NIGHT CYCLE
-- ═══════════════════════════════════════════════
local function getSecondsUntilNextCycle()
	local ok, result = pcall(function()
		local stn = workspace:GetServerTimeNow()
		local disabledAt = workspace:GetAttribute("AreaEggCycleDisabledAt")
		if type(disabledAt)=="number" then stn = math.min(stn, disabledAt) end
		local anchorAt = workspace:GetAttribute("AreaEggCycleAnchorAt") or 0
		local anchorIdx = workspace:GetAttribute("AreaEggCycleAnchorIndex") or 0
		local nextEnd = anchorAt + (math.max(0, anchorIdx + math.floor((stn - anchorAt)/300)) + 1) * 300
		return math.max(0, nextEnd - stn)
	end)
	return ok and result or 999
end
local function isInNight()
	local secs = getSecondsUntilNextCycle()
	local nightSecs = workspace:GetAttribute("AreaEggCycleNightSeconds") or 10
	return secs <= math.clamp(nightSecs, 1, 300)
end

-- ═══════════════════════════════════════════════
-- MOVEMENT ENGINE (1:1 KiraHub)
-- ═══════════════════════════════════════════════
local engine = {
	supportPart = nil,
	supportY = nil,
	dest = nil,
	flyLook = Vector3.new(0,0,-1),
	origWalkSpeed = 16,
	useFlySpeed = false,
	hookedStates = {},
	validators = {},
	savedCanTouch = {},
	supportActive = false,
}

-- Camera direction helpers
local function camForward()
	local cam = workspace.CurrentCamera
	if not cam then return Vector3.new(0,0,-1) end
	local look = Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)
	if look.Magnitude<0.001 then return Vector3.new(0,0,-1) end
	return look.Unit
end

-- WASD input (camera-relative)
local function getWASDDir()
	local fwd = camForward()
	local right = Vector3.new(-fwd.Z,0,fwd.X)
	local dir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir+=fwd end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir-=fwd end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir+=right end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir-=right end
	if dir.Magnitude<0.001 then return Vector3.zero end
	return dir.Unit
end

-- Flight velocity (WASD + Space/Ctrl)
local function getFlightVelocity()
	local spd = math.clamp(tonumber(cfg.FlightSpeed) or 880,150,1300)
	local wasd = getWASDDir()
	local vy = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vy=40
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vy=-40 end
	if wasd.Magnitude>0.05 then return Vector3.new(wasd.X*spd,vy,wasd.Z*spd) end
	return Vector3.new(0,vy,0)
end

local function isFlyMode()
	if cfg.Flight then return true end
	if engine.dest and typeof(engine.dest)=="Vector3" and engine.useFlySpeed then return true end
	return false
end

local function getTargetSpeed()
	if cfg.Flight then return math.clamp(tonumber(cfg.FlightSpeed) or 880,150,1300) end
	if engine.useFlySpeed and typeof(engine.dest)=="Vector3" then return math.clamp(tonumber(cfg.StealSpeed) or 300,16,1300) end
	if cfg.BypassSpeed then return math.clamp(tonumber(cfg.BypassCap) or 880,150,1300) end
	return engine.origWalkSpeed
end

-- Ground raycast (same as KiraHub v1147)
local function groundY(pos)
	if typeof(pos)~="Vector3" then return pos.Y end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {LocalPlayer.Character}
	if engine.supportPart then filter[#filter+1]=engine.supportPart end
	if workspace.CurrentCamera then filter[#filter+1]=workspace.CurrentCamera end
	params.FilterDescendantsInstances = filter
	local origin = Vector3.new(pos.X, math.max(pos.Y+48,80), pos.Z)
	local result = workspace:Raycast(origin,Vector3.new(0,-360,0),params)
	if result then return result.Position.Y end
	return pos.Y
end

-- KiraSupport part creation + positioning (v1148)
local function updateSupportPart(hrp, yVelDelta)
	if not engine.supportPart or not engine.supportPart.Parent then
		pcall(function()
			if engine.supportPart then engine.supportPart:Destroy() end
			local p = Instance.new("Part")
			p.Name = "IvorySupport"
			p.Size = Vector3.new(8,1.2,8)
			p.Anchored = true; p.CanCollide = true; p.CanQuery = true; p.CanTouch = false
			p.CastShadow = false; p.Transparency = 1; p.Material = Enum.Material.Concrete
			p.Parent = workspace
			engine.supportPart = p
		end)
	end
	local hipH = 2.51
	local supportH = math.max(3.8, hipH)
	local baseY = hrp.Position.Y - supportH - 0.6

	if isFlyMode() then
		engine.supportY = baseY
	else
		if engine.supportY == nil then
			engine.supportY = baseY
		elseif (yVelDelta or 0) > 8 then
			engine.supportY = math.max(engine.supportY, baseY)
		elseif (yVelDelta or 0) < -8 then
			engine.supportY = baseY
		elseif (hrp.Position.Y - (engine.supportY + 0.6)) > (supportH + 8) then
			engine.supportY = baseY
		end
	end
	engine.supportPart.CFrame = CFrame.new(hrp.Position.X, engine.supportY, hrp.Position.Z)
	engine.supportActive = true
end

local function removeSupportPart()
	if engine.supportPart then pcall(function() engine.supportPart:Destroy() end); engine.supportPart=nil end
	engine.supportActive = false; engine.supportY = nil
end

-- CFrame-based movement: no hooks needed, anti-cheat can't block CFrame teleport
-- (Spoofing state tables and hooking PostSimulation was causing instability.
--  CFrame teleport bypasses velocity checks entirely.)
-- ═══════════════════════════════════════════════
-- ANTI-DETECTION (CanTouch, CollisionGroup)
-- ═══════════════════════════════════════════════
local function disableCharCanTouch()
	local c = LocalPlayer.Character; if not c then return end
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then
			if not engine.savedCanTouch[p] then engine.savedCanTouch[p]=p.CanTouch end
			pcall(function() p.CanTouch=false end)
		end
	end
end
local function restoreCharCanTouch()
	for p,v in pairs(engine.savedCanTouch) do
		if typeof(p)=="Instance" and p.Parent then pcall(function() p.CanTouch=v end) end
	end
	engine.savedCanTouch = {}
end

local function setupCollisionGroups()
	pcall(function()
		for _,g in ipairs({"Guards","Players","GuardsNoCollide"}) do
			pcall(function() PhysicsService:RegisterCollisionGroup(g) end)
		end
		PhysicsService:CollisionGroupSetCollidable("Guards","Players",false)
		PhysicsService:CollisionGroupSetCollidable("Players","Guards",false)
		PhysicsService:CollisionGroupSetCollidable("GuardsNoCollide","Players",false)
		PhysicsService:CollisionGroupSetCollidable("Players","GuardsNoCollide",false)
		PhysicsService:CollisionGroupSetCollidable("GuardsNoCollide","Default",false)
		PhysicsService:CollisionGroupSetCollidable("GuardsNoCollide","Guards",false)
	end)
end

local function applyGuardBypass()
	if not cfg.AntiMob then return end
	setupCollisionGroups()
	-- Find guard models and make them non-collidable
	local objects = workspace:FindFirstChild("__OBJECTS")
	if objects then
		local guards = objects:FindFirstChild("Guards")
		if guards then
			for _,model in ipairs(guards:GetDescendants()) do
				if model:IsA("Model") or model:IsA("BasePart") then
					for _,p in ipairs((model:IsA("Model") and model:GetDescendants()) or {model}) do
						if p:IsA("BasePart") then
							pcall(function() p.CanTouch=false end)
							pcall(function() p.CanCollide=false end)
							pcall(function() p.CollisionGroup="GuardsNoCollide" end)
						end
					end
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════
-- ANTI-TRAP (v1158)
-- ═══════════════════════════════════════════════
local function clearTrapAttributes()
	local c = LocalPlayer.Character; if not c then return end
	pcall(function() c:SetAttribute("IsTrapped",nil) end)
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") then
			pcall(function()
				p.Anchored = false
				p:SetAttribute("IsTrapped",nil)
				local bb = p:FindFirstChild("TrapBillboard")
				if bb then bb:Destroy() end
			end)
		end
	end
end

-- ═══════════════════════════════════════════════
-- ANTI-RAGDOLL HOOKS
-- ═══════════════════════════════════════════════
local function hookRagdollBypass()
	-- Disabled: hookfunction on game scripts causes instability
	-- Guard remotes are now handled via character CanTouch=false
end

-- ═══════════════════════════════════════════════
-- TREADMILL AVOIDANCE (v1224)
-- ═══════════════════════════════════════════════
local function getTreadmillBoxes()
	local boxes = {}
	local objects = workspace:FindFirstChild("__OBJECTS")
	if objects then
		local treadmills = objects:FindFirstChild("Treadmills")
		if treadmills then
			for _,tm in ipairs(treadmills:GetDescendants()) do
				if tm:IsA("BasePart") then
					boxes[#boxes+1] = {
						min = tm.Position - tm.Size*0.5,
						max = tm.Position + tm.Size*0.5,
						center = tm.Position,
					}
				end
			end
		end
	end
	return boxes
end

local function obstacleDetour(from, to, spawnPos)
	if typeof(from)~="Vector3" or typeof(to)~="Vector3" then return to end
	local boxes = getTreadmillBoxes()
	if #boxes==0 then return to end
	local origin = from; local dest = to
	for _,box in ipairs(boxes) do
		-- Simple AABB segment intersection
		local closest = Vector3.new(
			math.clamp(origin.X, box.min.X, box.max.X),
			math.clamp(origin.Y, box.min.Y, box.max.Y),
			math.clamp(origin.Z, box.min.Z, box.max.Z)
		)
		if (closest - origin).Magnitude < 2 and (dest - origin).Magnitude > 2 then
			-- Reroute around treadmill
			local toCenter = (box.center - origin)
			local along = toCenter.Unit
			local perp = Vector3.new(-along.Z, 0, along.X)
			local waypoint = box.center + perp * 32
			return waypoint
		end
	end
	return to
end

local function navigateTo(dest)
	if typeof(dest)~="Vector3" then return end
	engine.dest = dest
	engine.useFlySpeed = (cfg.StealTravel == "Fly" or cfg.StealTravel == "Teleport")
end

-- ═══════════════════════════════════════════════
-- MAIN MOVEMENT LOOP (Stepped)
-- ═══════════════════════════════════════════════
local origWalkSpeed = 16

local function resetCharState(hrp, hum, dropping)
	if not hum or not hrp then return end
	pcall(function()
		hum.PlatformStand = false; hum.Sit = false; hum.AutoRotate = true
		hum.AutoJumpEnabled = true; hum.Jump = false
		if type(hum.WalkSpeed)=="number" and hum.WalkSpeed>0 and hum.WalkSpeed<=36 then
			origWalkSpeed = hum.WalkSpeed
		end
		hum.WalkSpeed = origWalkSpeed
		if dropping then hum:ChangeState(Enum.HumanoidStateType.Freefall) end
	end)
	pcall(function()
		hrp.Anchored = false
		if dropping then hrp.AssemblyLinearVelocity = Vector3.new(0,math.min(hrp.AssemblyLinearVelocity.Y,-22),0) end
		hrp.AssemblyAngularVelocity = Vector3.zero
	end)
end

local mainSteppedConn
local function startMovementEngine()
	setupCollisionGroups()

	mainSteppedConn = addConn(RunService.Stepped:Connect(function(_, dt)
		if not isRunning then return end
		local c,h,hum = getChar()
		if not h or not hum or hum.Health<=0 then return end
		hrp = h; humanoid = hum

		-- Track orig walkspeed
		if type(hum.WalkSpeed)=="number" and hum.WalkSpeed>0 and hum.WalkSpeed<=36 then
			origWalkSpeed = hum.WalkSpeed
		end

		-- Safety: if character is falling through the world, teleport back to safe zone
		local pos = h.Position
		local gY = groundY(pos)
		if gY and pos.Y < gY - 12 then
			local safe = getPlotPosition() or getSafeZone()
			if safe then
				pcall(function()
					h.CFrame = CFrame.new(safe)
					h.AssemblyLinearVelocity = Vector3.zero
					hum:ChangeState(Enum.HumanoidStateType.Running)
				end)
			end
		end

		-- Dest direction
		local dest = engine.dest
		local targetSpd = getTargetSpeed()
		local dtClamped = math.min(dt, 0.05)

		if cfg.Flight and not dest then
			-- Manual flight via CFrame
			local fv = getFlightVelocity()
			if fv.Magnitude > 0.1 then
				engine.flyLook = Vector3.new(fv.X,0,fv.Z)
				if engine.flyLook.Magnitude > 0.001 then engine.flyLook = engine.flyLook.Unit end
				local step = fv * dtClamped
				pcall(function()
					h.CFrame = h.CFrame + step
					h.AssemblyLinearVelocity = Vector3.zero
					hum:ChangeState(Enum.HumanoidStateType.Running)
				end)
			end
			return
		end

		if dest and typeof(dest)=="Vector3" then
			local flatDir = Vector3.new(dest.X - h.Position.X, 0, dest.Z - h.Position.Z)
			if flatDir.Magnitude > 1.2 then
				engine.flyLook = flatDir.Unit
			end
			-- CFrame teleport toward destination
			local step = flatDir.Unit * targetSpd * dtClamped
			pcall(function()
				h.CFrame = h.CFrame + step
				h.AssemblyLinearVelocity = Vector3.zero
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end)
		else
			-- No dest: maintain bypass speed if needed
			if cfg.BypassSpeed then
				local md = hum.MoveDirection
				if md.Magnitude > 0.05 then
					-- CFrame move in current direction
					local step = md.Unit * targetSpd * dtClamped
					pcall(function()
						h.CFrame = h.CFrame + step
						h.AssemblyLinearVelocity = Vector3.zero
					end)
				end
			end
		end
	end))
end
-- ═══════════════════════════════════════════════
-- AUTO-STEAL STATE MACHINE (13 states, 1:1)
-- ═══════════════════════════════════════════════
local steal = {
	running = false, state = "Idle",
	target = nil, targetCfg = nil,
	carrying = false, heldUid = nil,
	lockUid = nil, lockPos = nil, lockAt = 0,
	lastGrab = 0, lastBankAt = 0, banked = 0,
	lastPos = nil, stillFor = 0,
	wallRestY = nil, wallSealedAt = 0, eggResetAt = 0, eggResetGrew = false,
	stuckCooldown = 0, lastReset = 0,
	stateTime = 0, scanCount = 0,
}

local function stealTransition(newState)
	if newState ~= steal.state then
		steal.state = newState; steal.stateTime = 0
	end
end

-- Wall-up detection (v1229)
local function isWallUp()
	local resetWall
	pcall(function()
		resetWall = require(ReplicatedStorage.Client.AreaEggResetWall)
	end)
	if type(resetWall)=="table" and type(resetWall.IsSealed)=="function" then
		local ok,sealed = pcall(resetWall.IsSealed)
		if ok and sealed==true then steal.wallSealedAt=os.clock(); return true end
	end
	local collapseSecs = type(resetWall)=="table" and (resetWall.CollapseSeconds or 0.5) or 0.5
	collapseSecs = math.clamp(collapseSecs, 0.15, 2)
	if steal.wallSealedAt > 0 and os.clock()-steal.wallSealedAt < collapseSecs+0.12 then return true end
	-- Visual check
	local wallPart = workspace:FindFirstChild("__OBJECTS",true)
		and workspace.__OBJECTS:FindFirstChild("Areas",true)
		and workspace.__OBJECTS.Areas:FindFirstChild("WallStartVisual")
	if wallPart and wallPart:IsA("BasePart") and wallPart.Transparency < 0.85 then
		local sy = wallPart.Size.Y
		if steal.wallRestY==nil or steal.wallRestY > sy+0.05 then steal.wallRestY=sy end
		if sy > steal.wallRestY+3 then return true end
	end
	return false
end

-- Check if at safe zone (within 28 studs of spawn)
local function atSafeZone(pos)
	local safe = getPlotPosition() or getSafeZone()
	if not safe or not pos then return false end
	return (Vector3.new(pos.X-safe.X,0,pos.Z-safe.Z)).Magnitude <= 28
end

-- Stuck reset (v1237)
local function resetStuck(hrp, hum)
	if os.clock()-steal.lastReset < 2.5 then return end
	steal.lastReset = os.clock()
	local safe = getPlotPosition() or getSafeZone()
	if safe then
		if steal.carrying then
			pcall(function() hrp.CFrame = CFrame.new(safe) end)
		else
			pcall(function() hrp.CFrame = CFrame.new(safe + Vector3.new(math.random(-6,6),4,0)) end)
		end
		pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end)
		pcall(function() hum.Sit=false; hum.PlatformStand=false end)
	end
end

-- Carry state tracking
local function processCarry()
	local ew = getEggWorld()
	if not ew then return end
	local fn = ew.ReadOwnedEggs or ew.ReadOwnerEggs
	if type(fn)~="function" then return end
	local ok,res = pcall(fn)
	if ok and type(res)=="table" then
		local carrying = false
		for _,v in pairs(res) do
			if type(v)=="table" and (v.State=="Carried" or v.CarrierUserId==LocalPlayer.UserId) then
				carrying = true; break
			end
		end
		steal.carrying = carrying
	end
end

-- Grab egg (v1236)
local function tryGrab(rec)
	if steal.carrying then return end
	if os.clock()-steal.lastGrab < 0.03 then return end
	steal.lastGrab = os.clock()
	steal.heldUid = rec.Uid
	steal.lockUid = rec.Uid; steal.lockAt = os.clock()

	-- Primary: EggState module function
	local ew = getEggWorld()
	if ew and type(ew.CarryFieldEgg)=="function" then
		local slotKey = rec.NestId or rec.AreaId or ""
		pcall(ew.CarryFieldEgg, rec.Uid, slotKey)
	end
	-- Fallback: RemoteFunction
	pcall(function()
		local rf = getRF("EggWorld", "AskFieldEggCarry")
		if rf then rf:InvokeServer(rec.Uid) end
	end)
	-- Fallback: ProximityPrompt
	local prompt = workspace:FindFirstChildWhichIsA("ProximityPrompt",true)
	if prompt and hrp and (prompt.Parent.Position - hrp.Position).Magnitude < 10 then
		pcall(function() ProximityPromptService:PromptHoldBegan(LocalPlayer, prompt) end)
		task.wait(0.05)
		pcall(function() ProximityPromptService:PromptHoldEnded(LocalPlayer, prompt) end)
	end
end

-- Count the steal
local function countSteal()
	steal.banked = steal.banked + 1
	steal.lastBankAt = os.clock()
	steal.heldUid = nil; steal.lockUid = nil; steal.lockPos = nil
	steal.target = nil; steal.targetCfg = nil
	steal.carrying = false
	statsData.eggs = steal.banked
end

-- Check if should pause (night / wall / egg reset)
local function shouldPause()
	if steal.state=="Return" or steal.state=="Bank" or steal.state=="Feed" or steal.state=="ChestOpen" then return false end
	if isInNight() then return "night" end
	if isWallUp() then return "wall" end
	if steal.eggResetAt > 0 and os.clock()-steal.eggResetAt < 5 then return "egg_reset" end
	return false
end

-- The main tick (u1132)
local function tickSteal(dt)
	if not cfg.AutoSteal or not steal.running then
		steal.state = "Idle"; engine.dest = nil; return
	end
	local c,h,hum = getChar()
	if not h or not hum or hum.Health<=0 then
		steal.state = "Idle"; engine.dest = nil; return
	end
	hrp = h; humanoid = hum
	steal.stateTime = steal.stateTime + dt

	-- Process carry state
	processCarry()

	-- Void rescue: below floor
	local floorY = groundY(h.Position)
	if floorY and h.Position.Y < floorY-8 then
		pcall(function()
			local safe = getPlotPosition() or getSafeZone()
			if safe then h.CFrame = CFrame.new(safe) end
		end)
		return
	end

	-- Night / wall pause
	local pause = shouldPause()
	if pause == "night" then
		if steal.state ~= "Night" then
			stealTransition("Night"); engine.dest = nil
		end
		return
	elseif pause == "wall" or pause == "egg_reset" then
		engine.dest = nil
		if steal.state=="Scan" or steal.state=="GoEgg" or steal.state=="Grab" then
			steal.target = nil; steal.lockUid = nil
			stealTransition("Scan")
		end
		return
	end
	if steal.state == "Night" then
		stealTransition("Scan"); return
	end

	-- Stuck detection
	if engine.dest and typeof(engine.dest)=="Vector3" then
		local dist = (Vector3.new(h.Position.X-engine.dest.X,0,h.Position.Z-engine.dest.Z)).Magnitude
		if steal.lastPos and (Vector3.new(h.Position.X-steal.lastPos.X,0,h.Position.Z-steal.lastPos.Z)).Magnitude < 1.2 then
			steal.stillFor = steal.stillFor + dt
		else
			steal.stillFor = 0
		end
		steal.lastPos = h.Position

		if steal.stillFor > 0.85 then
			pcall(function() hum.Jump=true; hum.AutoJumpEnabled=true end)
		end
		if steal.stillFor > 2.6 then
			resetStuck(h, hum)
			steal.stillFor = 0
			if steal.state == "GoEgg" and not steal.carrying and not steal.lockUid then
				steal.target = nil; stealTransition("Scan")
			end
		end
	else
		steal.stillFor = 0; steal.lastPos = nil
	end

	-- STATE MACHINE
	if steal.state == "Idle" then
		engine.dest = nil
		stealTransition("Scan")

	elseif steal.state == "Scan" then
		engine.dest = nil
		steal.scanCount = steal.scanCount + 1

		-- Pick best egg
		local eggs = readFieldEggs()
		local best = pickBestEgg(eggs)
		if best and best.rec then
			steal.target = best.rec; steal.targetCfg = best.cfg
			local targetPos = getEggPosition(best.rec)
			if targetPos then
				-- If on safe zone, go to egg
				local safe = getPlotPosition() or getSafeZone()
				if safe and atSafeZone(h.Position) then
					stealTransition("GoEgg")
					navigateTo(obstacleDetour(h.Position, targetPos, safe))
				else
					stealTransition("GoEgg")
					navigateTo(targetPos)
				end
			end
		end

	elseif steal.state == "GoEgg" then
		local t = steal.target
		if not t then stealTransition("Scan"); return end
		local pos = getEggPosition(t)
		if not pos then steal.target=nil; stealTransition("Scan"); return end

		-- Timeout
		if steal.stateTime > 45 then
			steal.target=nil; steal.lockUid=nil; stealTransition("Scan"); return
		end

		local dist = (Vector3.new(h.Position.X-pos.X,0,h.Position.Z-pos.Z)).Magnitude
		local grabDist = steal.carrying and 5 or (t.State=="Dropped" and 16 or 10)
		if dist <= grabDist then
			engine.dest = nil
			stealTransition("Grab")
		else
			local safe = getPlotPosition() or getSafeZone()
			navigateTo(obstacleDetour(h.Position, pos, safe))
		end

	elseif steal.state == "Grab" then
		local t = steal.target
		if not t then stealTransition("Scan"); return end
		if steal.carrying then stealTransition("Return"); return end

		if steal.stateTime > 8 then
			steal.target=nil; stealTransition("Scan"); return
		end

		local pos = getEggPosition(t)
		if not pos then steal.target=nil; stealTransition("Scan"); return end

		local dist = (Vector3.new(h.Position.X-pos.X,0,h.Position.Z-pos.Z)).Magnitude
		if dist <= 5 then
			tryGrab(t)
			task.wait(0.15)
			if steal.carrying then stealTransition("Return") end
		else
			navigateTo(pos)
		end

	elseif steal.state == "Chase" then
		-- Chase carrier player (bat aura mode)
		engine.dest = nil
		if not cfg.BatAura then stealTransition("Scan"); return end
		if steal.stateTime > 20 then stealTransition("Scan"); return end
		-- Find carrier
		local bestDist = 60
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LocalPlayer and p.Character then
				local ph = p.Character:FindFirstChild("HumanoidRootPart")
				if ph then
					local d = (h.Position-ph.Position).Magnitude
					if d<bestDist then bestDist=d; navigateTo(ph.Position) end
				end
			end
		end

	elseif steal.state == "Return" then
		local safe = getPlotPosition() or getSafeZone()
		if not safe then stealTransition("Scan"); return end
		if not steal.carrying then stealTransition("Scan"); return end

		if atSafeZone(h.Position) then
			engine.dest = nil
			stealTransition("Bank")
		else
			navigateTo(safe)
		end

		if steal.stateTime > 28 then
			steal.target = nil; steal.lockUid=nil
			if steal.lockPos then stealTransition("GoEgg") else stealTransition("Scan") end
		end

	elseif steal.state == "Bank" then
		local safe = getPlotPosition() or getSafeZone()
		if safe then engine.dest = safe end

		if not steal.carrying then
			countSteal()
			stealTransition("Scan")
			return
		end

		if steal.stateTime > 4 then
			stealTransition("Return")
		end

	elseif steal.state == "FeedGo" then
		-- TODO: monster feeding logic
		if steal.stateTime > 36 then stealTransition("Scan") end

	elseif steal.state == "Feed" then
		if steal.stateTime > 10 then stealTransition("Scan") end

	elseif steal.state == "ChestGo" then
		if steal.stateTime > 12 then stealTransition("Scan") end

	elseif steal.state == "ChestOpen" then
		if steal.stateTime > 8 then stealTransition("Scan") end
	end
end

-- ═══════════════════════════════════════════════
-- BAT AURA (1:1 KiraHub)
-- ═══════════════════════════════════════════════
local bat = {cooldown = 0, equipCooldown = 0, lastTarget = nil}

local function findBatTool()
	local c = LocalPlayer.Character; if not c then return nil end
	-- Check character
	for _,t in ipairs(c:GetChildren()) do
		if t:IsA("Tool") then
			-- Check attribute (KiraHub uses s18 from Data.Sakura.BatToolAttribute)
			local hasAttr = false
			pcall(function()
				local batAttr = ReplicatedStorage:FindFirstChild("Data")
					and ReplicatedStorage.Data:FindFirstChild("Sakura")
					and ReplicatedStorage.Data.Sakura:FindFirstChild("BatToolAttribute")
				if batAttr then hasAttr = t:GetAttribute(tostring(batAttr.Value)) end
			end)
			if hasAttr or t.Name:lower():find("bat") or t.Name:lower():find("stick") then return t end
		end
	end
	-- Check backpack
	local bp = LocalPlayer:FindFirstChild("Backpack"); if not bp then return nil end
	for _,t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") then
			local hasAttr = false
			pcall(function()
				local batAttr = ReplicatedStorage:FindFirstChild("Data")
					and ReplicatedStorage.Data:FindFirstChild("Sakura")
					and ReplicatedStorage.Data.Sakura:FindFirstChild("BatToolAttribute")
				if batAttr then hasAttr = t:GetAttribute(tostring(batAttr.Value)) end
			end)
			if hasAttr or t.Name:lower():find("bat") or t.Name:lower():find("stick") then return t end
		end
	end
	return nil
end

local function getNearestPlayerWithEgg(maxDist)
	maxDist = maxDist or 60
	local c,h = getChar(); if not h then return nil end
	local best,bestDist = nil,maxDist
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character then
			local ph = p.Character:FindFirstChild("HumanoidRootPart")
			if ph then
				local d = (h.Position-ph.Position).Magnitude
				-- Bias for steal target
				local bias = 0
				if steal.target and steal.target.CarrierUserId == p.UserId then bias = 40 end
				local adjusted = d - bias
				if adjusted < bestDist then best=p; bestDist=adjusted end
			end
		end
	end
	return best
end

local function tickBatAura(dt)
	if not cfg.BatAura then bat.cooldown=0; bat.equipCooldown=0; return end
	bat.cooldown = bat.cooldown - dt
	bat.equipCooldown = bat.equipCooldown - dt

	-- Auto-equip bat
	if bat.equipCooldown <= 0 then
		bat.equipCooldown = 0.35
		local tool = findBatTool()
		if tool and not tool.Parent:FindFirstChildOfClass("Humanoid") then
			pcall(function()
				local bp = LocalPlayer:FindFirstChild("Backpack")
				if bp and tool.Parent == bp then
					tool.Parent = LocalPlayer.Character
				end
			end)
		end
	end

	if bat.cooldown > 0 then return end
	bat.cooldown = 0.7

	local tool = findBatTool()
	if not tool then return end

	local target = getNearestPlayerWithEgg(60)
	if target then
		-- Equip and swing
		pcall(function()
			local c = LocalPlayer.Character
			if c and not c:FindFirstChild(tool.Name) then
				tool.Parent = c
				task.wait(0.08)
			end
		end)
		pcall(function() fireRemote("BatSwing","Trigger") end)
	end
end
-- ═══════════════════════════════════════════════
-- ESP SYSTEM (1:1 KiraHub)
-- ═══════════════════════════════════════════════
local esp = {billboards={}, beams={}, plotLabels={}, iconCache={}}
local espUpdateTimer = 0

local function clearEsp()
	for _,bb in pairs(esp.billboards) do pcall(function() bb:Destroy() end) end
	for _,b in pairs(esp.beams) do pcall(function() b:Destroy() end) end
	for _,l in ipairs(esp.plotLabels) do pcall(function() l:Destroy() end) end
	esp.billboards={}; esp.beams={}; esp.plotLabels={}
end

local function resolveEggIcon(rec)
	if type(rec)~="table" then return nil end
	if esp.iconCache[rec.Uid] then return esp.iconCache[rec.Uid] end
	-- Try multiple sources (KiraHub 3-pass scan)
	local sources = {}
	pcall(function()
		local dir = getEggWorld()
		if dir then sources[#sources+1] = dir end
	end)
	pcall(function() sources[#sources+1] = ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("UI") end)
	pcall(function()
		local dir = getEggWorld(); if dir then sources[#sources+1] = dir end
	end)
	pcall(function() sources[#sources+1] = ReplicatedStorage:FindFirstChild("Data") end)
	pcall(function() sources[#sources+1] = LocalPlayer:FindFirstChild("PlayerGui") end)

	for _,src in ipairs(sources) do
		if typeof(src)=="Instance" then
			for _,child in ipairs(src:GetDescendants()) do
				if child:IsA("ImageLabel") or child:IsA("ImageButton") then
					local img = child.Image
					if img and img~="" then
						esp.iconCache[rec.Uid] = img
						return img
					end
				end
			end
		end
	end
	return nil
end

local function createEggBB(rec)
	local pos = getEggPosition(rec)
	if not pos then return nil end
	local rar = getEggRarity(rec)
	local rn = getRarityNumber(rec)

	local bb = Instance.new("BillboardGui")
	bb.Name = "IvoryESP"
	bb.Size = UDim2.new(0,152,0,34)
	bb.StudsOffset = Vector3.new(0,4,0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.MaxDistance = 1000000
	bb.Parent = workspace.CurrentCamera

	local fr = Instance.new("Frame", bb)
	fr.Size = UDim2.new(1,0,1,0)
	fr.BackgroundColor3 = rarityColor(rn)
	fr.BackgroundTransparency = 0.2
	fr.BorderSizePixel = 0
	fr.Corner = Instance.new("UICorner", fr); fr.Corner.CornerRadius = UDim.new(0,6)

	-- Icon
	local icon = resolveEggIcon(rec)
	if icon then
		local img = Instance.new("ImageLabel", fr)
		img.Size = UDim2.new(0,26,0,26)
		img.Position = UDim2.new(0,4,0.5,-13)
		img.BackgroundTransparency = 1
		img.Image = icon
		img.ScaleType = Enum.ScaleType.Fit
	end

	-- Name + rarity text
	local tl = Instance.new("TextLabel", fr)
	tl.Size = UDim2.new(1,icon and -38 or -10,1,0)
	tl.Position = UDim2.new(0,icon and 36 or 5,0,0)
	tl.BackgroundTransparency = 1
	tl.Text = rar
	tl.TextColor3 = Color3.new(0,0,0)
	tl.TextScaled = true
	tl.Font = Enum.Font.GothamBold
	tl.TextXAlignment = Enum.TextXAlignment.Left

	return bb
end

local function tickESP(dt)
	if not cfg.EggESP and not cfg.PlotESP then clearEsp(); return end
	espUpdateTimer = espUpdateTimer + dt
	if espUpdateTimer < 0.08 then return end -- 80ms throttle like KiraHub
	espUpdateTimer = 0

	if cfg.EggESP then
		local eggs = readFieldEggs()
		local alive = {}
		for _,rec in ipairs(eggs) do
			if matchesFilter(rec) then alive[rec.Uid] = rec end
		end
		-- Add new
		for uid,rec in pairs(alive) do
			if not esp.billboards[uid] then
				local bb = createEggBB(rec)
				if bb then esp.billboards[uid] = bb end
			end
		end
		-- Remove dead
		for uid,bb in pairs(esp.billboards) do
			if not alive[uid] then pcall(function() bb:Destroy() end); esp.billboards[uid]=nil end
		end
	end

	if cfg.PlotESP then
		for _,l in ipairs(esp.plotLabels) do pcall(function() l:Destroy() end) end
		esp.plotLabels = {}
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LocalPlayer then
				local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if ph then
					local bb = Instance.new("BillboardGui")
					bb.Size = UDim2.new(0,140,0,30)
					bb.StudsOffset = Vector3.new(0,6,0)
					bb.AlwaysOnTop = true
					bb.Adornee = ph
					bb.Parent = workspace.CurrentCamera
					local tl = Instance.new("TextLabel", bb)
					tl.Size = UDim2.new(1,0,1,0)
					tl.BackgroundTransparency = 0.5
					tl.BackgroundColor3 = Color3.fromRGB(40,40,40)
					tl.Text = p.Name
					tl.TextColor3 = Color3.new(1,1,1)
					tl.TextScaled = true
					tl.Font = Enum.Font.GothamBold
					esp.plotLabels[#esp.plotLabels+1] = bb
				end
			end
		end
	end
end

-- ═══════════════════════════════════════════════
-- STATS PANEL
-- ═══════════════════════════════════════════════
local statsGui = nil
local statsLabels = {}
local statsUpdateTimer = 0
local statsData = {eggs=0, money=0, hops=0, nextHop="", state="Idle"}

local function createStatsPanel()
	if statsGui then pcall(function() statsGui:Destroy() end) end
	local sg = Instance.new("ScreenGui")
	sg.Name = "IvoryStatsPanel"; sg.ResetOnSpawn = false; sg.DisplayOrder = 5
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = LocalPlayer:WaitForChild("PlayerGui")

	local fr = Instance.new("Frame", sg)
	fr.Size = UDim2.new(0,260,0,320); fr.Position = UDim2.new(1,-270,0,10)
	fr.BackgroundColor3 = Color3.fromRGB(25,25,30); fr.BackgroundTransparency = 0.15
	fr.BorderSizePixel = 0
	fr.Corner = Instance.new("UICorner", fr); fr.Corner.CornerRadius = UDim.new(0,8)

	local title = Instance.new("TextLabel", fr)
	title.Size = UDim2.new(1,0,0,32); title.BackgroundColor3 = Color3.fromRGB(35,35,42)
	title.BackgroundTransparency = 0.1; title.Text = "Stats"
	title.TextColor3 = Color3.fromRGB(220,220,220); title.TextSize = 16
	title.Font = Enum.Font.GothamBold; title.BorderSizePixel = 0

	local list = Instance.new("UIListLayout", fr)
	list.Padding = UDim.new(0,4); list.HorizontalAlignment = Enum.HorizontalAlignment.Center; list.SortOrder = Enum.SortOrder.LayoutOrder
	local pad = Instance.new("UIPadding", fr)
	pad.PaddingTop = UDim.new(0,38); pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight = UDim.new(0,8)

	local labels = {}
	local names = {"Session Eggs","Session Money","Hop Count","Next Hop","Steal State","Speed"}
	for i,nm in ipairs(names) do
		local l = Instance.new("TextLabel", fr)
		l.Size = UDim2.new(1,0,0,26); l.BackgroundColor3 = Color3.fromRGB(30,30,38)
		l.BackgroundTransparency = 0.3; l.Text = nm..": 0"
		l.TextColor3 = Color3.fromRGB(190,190,190); l.TextSize = 13
		l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
		l.BorderSizePixel = 0
		l.Corner = Instance.new("UICorner", l); l.Corner.CornerRadius = UDim.new(0,4)
		local lp = Instance.new("UIPadding", l); lp.PaddingLeft = UDim.new(0,6)
		labels[nm] = l
	end
	statsGui = sg; statsLabels = labels
end

local function updateStatsPanel(dt)
	if not cfg.StatsPanel then
		if statsGui then pcall(function() statsGui:Destroy() end); statsGui=nil end
		return
	end
	if not statsGui then createStatsPanel() end
	statsUpdateTimer = statsUpdateTimer + dt
	if statsUpdateTimer < 0.5 then return end
	statsUpdateTimer = 0
	statsData.state = steal.state
	statsData.speed = getTargetSpeed()
	statsData.nextHop = cfg.AutoHop and (cfg.HopAfter or cfg.HopIdle or "Off") or "Off"
	if statsLabels["Session Eggs"] then statsLabels["Session Eggs"].Text = "Session Eggs: "..statsData.eggs end
	if statsLabels["Session Money"] then statsLabels["Session Money"].Text = "Session Money: "..formatMoney(statsData.money) end
	if statsLabels["Hop Count"] then statsLabels["Hop Count"].Text = "Hop Count: "..statsData.hops end
	if statsLabels["Next Hop"] then statsLabels["Next Hop"].Text = "Next Hop: "..statsData.nextHop end
	if statsLabels["Steal State"] then statsLabels["Steal State"].Text = "Steal State: "..statsData.state end
	if statsLabels["Speed"] then statsLabels["Speed"].Text = "Speed: "..math.floor(statsData.speed) end
end

-- ═══════════════════════════════════════════════
-- OPTIMIZER (1:1 KiraHub)
-- ═══════════════════════════════════════════════
local optConn = nil
local optSavedSettings = nil

local function applyOptimizer()
	if not cfg.Optimizer then
		if optConn then optConn:Disconnect(); optConn=nil end
		-- Restore settings
		if optSavedSettings then
			pcall(function()
				Lighting.GlobalShadows = optSavedSettings.GlobalShadows
				Lighting.FogEnd = optSavedSettings.FogEnd
				Lighting.ExposureCompensation = optSavedSettings.ExposureCompensation
			end)
			optSavedSettings = nil
		end
		return
	end
	if optConn then return end

	-- Save current settings
	optSavedSettings = {
		GlobalShadows = Lighting.GlobalShadows,
		FogEnd = Lighting.FogEnd,
		ExposureCompensation = Lighting.ExposureCompensation,
	}
	-- Override settings
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 250
		Lighting.ExposureCompensation = -0.4
	end)
	-- Disable terrain water
	pcall(function()
		workspace.Terrain.WaterTransparency = 1
		workspace.Terrain.WaterReflectance = 0
		workspace.Terrain.WaterWaveSize = 0
		workspace.Terrain.WaterWaveSpeed = 0
	end)
	-- Disable existing effects
	for _,d in ipairs(Lighting:GetDescendants()) do
		if d:IsA("PostEffect") or d:IsA("Atmosphere") or d:IsA("Sky") or d:IsA("Clouds") then
			pcall(function() d.Enabled = false end)
		end
	end
	for _,d in ipairs(workspace:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
			or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles")
			or d:IsA("Highlight") or d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			pcall(function() d.Enabled = false end)
		end
	end
	-- Live hook for new descendants
	optConn = addConn(workspace.DescendantAdded:Connect(function(d)
		if not cfg.Optimizer then return end
		if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam")
			or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles")
			or d:IsA("Highlight") then
			pcall(function() d.Enabled = false end)
		end
		if d:IsA("BasePart") then pcall(function() d.CastShadow = false end) end
		if d:IsA("PostEffect") or d:IsA("Atmosphere") or d:IsA("Sky") or d:IsA("Clouds") then
			pcall(function() d.Enabled = false end)
		end
		if d:IsA("PointLight") or d:IsA("SpotLight") or d:IsA("SurfaceLight") then
			pcall(function() d.Enabled = false end)
		end
	end))
end

-- ═══════════════════════════════════════════════
-- SERVER HOP (1:1 KiraHub)
-- ═══════════════════════════════════════════════
local hop = {lastHopTime = 0, seenServers = {}, ring = {}, idleStart = 0, count = 0}

local function getServerList(cursor, limit)
	cursor = cursor or ""; limit = limit or 100
	local sort = cfg.HopPlayers=="Lowest" and "Asc" or (cfg.HopPlayers=="Highest" and "Desc" or "Asc")
	local ok,res = pcall(function()
		return HttpService:JSONDecode(game:HttpGet(
			"https://games.roblox.com/v1/games/"..PLACE_ID.."/servers/Public?sortOrder="..sort.."&limit="..limit.."&cursor="..cursor
		))
	end)
	if ok and type(res)=="table" then return res end
	return nil
end

local function hopToRandom()
	local seen = {}; local candidates = {}
	local pages = math.clamp(tonumber(cfg.HopPages) or 3,1,10)
	local cursor = ""
	for page=1,pages do
		local data = getServerList(cursor)
		if not data or not data.data then break end
		for _,s in ipairs(data.data) do
			if not seen[s.id] and s.id~=game.JobId and not hop.ring[s.id] then
				seen[s.id]=true
				if not cfg.HopSkipFull or (tonumber(s.playing) or 0) < (tonumber(s.maxPlayers) or 0) then
					candidates[#candidates+1] = s
				end
			end
		end
		cursor = data.nextPageCursor or ""; if cursor=="" then break end
	end
	if #candidates==0 then return false end
	-- Pick random from top 12
	local pickRange = math.min(12, #candidates)
	local pick = candidates[math.random(1,pickRange)]
	-- Dedup ring
	hop.ring[pick.id] = true
	local ringSize = 0
	for _ in pairs(hop.ring) do ringSize=ringSize+1 end
	if ringSize > 48 then
		for k in pairs(hop.ring) do hop.ring[k]=nil; break end
	end
	hop.count = hop.count + 1
	statsData.hops = hop.count
	pcall(function() TeleportService:TeleportToPlaceInstance(PLACE_ID, pick.id, LocalPlayer) end)
	return true
end

local function tickHop(dt)
	if not cfg.AutoHop then hop.idleStart=0; return end
	local t = tick()
	-- Idle trigger: counts seconds since last banked steal
	if cfg.HopIdle and cfg.HopIdle~="" then
		local idleSec = tonumber(cfg.HopIdle) or 0
		if idleSec > 0 then
			local idleSince = t - steal.lastBankAt
			if idleSince >= idleSec then
				hop.lastHopTime=t; hopToRandom()
			end
		end
	end
	-- Time trigger: HopAfter in seconds
	if cfg.HopAfter and cfg.HopAfter~="" then
		local afterSec = tonumber(cfg.HopAfter) or 0
		if afterSec > 0 and (t-hop.lastHopTime) >= afterSec then
			hop.lastHopTime=t; hopToRandom()
		end
	end
end

-- ═══════════════════════════════════════════════
-- WEBHOOK / HOOK (1:1 KiraHub)
-- ═══════════════════════════════════════════════
local webhook = {digest={stolen=0,hatched=0,sold=0,rewards=0,money=0,startTime=os.clock()}}

local function sendHTTP(payload)
	if not cfg.HookEnabled or not cfg.HookUrl or cfg.HookUrl=="" or cfg.HookUrl=="https://" then return end
	pcall(function()
		local fn = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
		if fn then
			fn({Url=cfg.HookUrl, Method="POST",
				Headers={["Content-Type"]="application/json"},
				Body=HttpService:JSONEncode(payload)})
		end
	end)
end

local function sendEmbed(title, desc, color, fields)
	if not cfg.HookEnabled then return end
	local embed = {title=title, description=desc, color=color or 0x00AAFF, timestamp=DateTime.now():ToIsoDate()}
	if fields then embed.fields = fields end
	if cfg.HookUsername then embed.author = {name=LocalPlayer.Name.." ["..UserId.."]"} end
	embed.footer = {text="Ivory Hub | v1.4"}
	sendHTTP({username="Ivory Hub", embeds={embed}})
end

local function sendStolenEmbed(rec)
	if not cfg.HookStolen then return end
	local fields = {}
	local earn = getEggEarning(rec, getEggAssetConfig(rec))
	local rar = getEggRarity(rec)
	local weight = tonumber(rec.ModelWeight) or 0
	table.insert(fields, {name="Rarity", value=rar, inline=true})
	table.insert(fields, {name="Earn", value=formatMoney(earn).."/s", inline=true})
	table.insert(fields, {name="Weight", value=string.format("%.1f",weight), inline=true})
	local area = tostring(rec.AreaId or "?")
	table.insert(fields, {name="Area", value=area, inline=true})
	if type(rec.Mutations)=="table" and #rec.Mutations>0 then
		table.insert(fields, {name="Mutations", value=table.concat(rec.Mutations,","), inline=true})
	end
	sendEmbed("Egg Stolen", "Successfully grabbed an egg!", 0x00FF88, fields)
end

local function tickHook(dt)
	if not cfg.HookEnabled then return end
	-- Session digest every 600s
	if cfg.SessionDigest and (os.clock()-webhook.digest.startTime) >= 600 then
		webhook.digest.startTime = os.clock()
		local fields = {}
		table.insert(fields, {name="Stolen", value=tostring(steal.banked), inline=true})
		table.insert(fields, {name="Session Time", value=string.format("%.0fs",os.clock()-webhook.digest.startTime), inline=true})
		sendEmbed("Session Digest", "Periodic session summary", 0xFFAA00, fields)
	end
end
-- ═══════════════════════════════════════════════
-- MAIN LOOP (Heartbeat)
-- ═══════════════════════════════════════════════
local lastTick = tick()
local mainLoopConn = addConn(RunService.Heartbeat:Connect(function(dt)
	if not isRunning then return end
	local now = tick(); lastTick = now

	-- Anti-trap
	if cfg.AntiTrap then pcall(clearTrapAttributes) end
	-- CanTouch disable
	pcall(disableCharCanTouch)
	-- Guard bypass
	pcall(applyGuardBypass)
	-- Auto-steal
	tickSteal(dt)
	-- Bat aura
	tickBatAura(dt)
	-- ESP
	tickESP(dt)
	-- Stats
	updateStatsPanel(dt)
	-- Optimizer
	applyOptimizer()
	-- Server hop
	tickHop(dt)
	-- Webhook
	tickHook(dt)
	-- FPS cap
	if cfg.FPSCap and cfg.FPSCap > 0 then
		pcall(function() settings().Rendering.FrameRateCap = cfg.FPSCap end)
	end
end))

-- ═══════════════════════════════════════════════
-- FLIGHT KEYBIND
-- ═══════════════════════════════════════════════
addConn(UserInputService.InputBegan:Connect(function(input,gpe)
	if gpe then return end
	if input.KeyCode == cfg.FlightBind then
		cfg.Flight = not cfg.Flight
		if not cfg.Flight then engine.dest=nil; removeSupportPart() end
		pcall(function() Library.Notify({Title="Ivory",Content="Flight: "..(cfg.Flight and "ON" or "OFF"),Type="Info",Duration=2}) end)
	end
end))

-- ═══════════════════════════════════════════════
-- UI LIBRARY (IvoryHub)
-- ═══════════════════════════════════════════════
local Window = Library.CreateWindow({Name="Ivory", Width=720, Height=600})

-- ═══════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════
local CombatTab = Window:CreateTab({Name="Combat"})

local StealSection = CombatTab:CreateSection("Steal")
StealSection:CreateToggle({Name="Auto Steal",CurrentValue=cfg.AutoSteal,Callback=function(v)
	cfg.AutoSteal=v
	if v then steal.running=true; stealTransition("Scan") else steal.running=false; steal.state="Idle"; engine.dest=nil end
	saveConfig()
end})
StealSection:CreateDropdown({Name="Steal Travel",Values={"Speed","Walk","Teleport","Fly"},CurrentOption={cfg.StealTravel},Callback=function(v) cfg.StealTravel=v[1]; engine.useFlySpeed=(v[1]=="Fly" or v[1]=="Teleport"); saveConfig() end})
StealSection:CreateSlider({Name="Steal Speed",Range={50,1300},Increment=10,CurrentValue=cfg.StealSpeed,Callback=function(v) cfg.StealSpeed=v saveConfig() end})
StealSection:CreateDropdown({Name="Steal Mode",Values={"Best value","Rarity snipe","Gen ($/s) snipe","Egg type filter"},CurrentOption={cfg.StealMode},Callback=function(v) cfg.StealMode=v[1] saveConfig() end})
StealSection:CreateInput({Name="Gen Snipe Floor",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.GenSnipeFloor=v saveConfig() end})
StealSection:CreateToggle({Name="Use Rarity Filter",CurrentValue=cfg.UseRarity,Callback=function(v) cfg.UseRarity=v saveConfig() end})
StealSection:CreateDropdown({Name="Rarities",Values=RARITIES,CurrentOption=cfg.Rarities,Multiple=true,Callback=function(v) cfg.Rarities=v saveConfig() end})
StealSection:CreateToggle({Name="Use Mutation Filter",CurrentValue=cfg.UseMutation,Callback=function(v) cfg.UseMutation=v saveConfig() end})
StealSection:CreateDropdown({Name="Mutations",Values=MUTATIONS,CurrentOption=cfg.Mutations,Multiple=true,Callback=function(v) cfg.Mutations=v saveConfig() end})
StealSection:CreateInput({Name="Min Weight",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.MinWeight=v saveConfig() end})
StealSection:CreateDropdown({Name="Areas",Values=AREAS,CurrentOption=cfg.Areas,Multiple=true,Callback=function(v) cfg.Areas=v saveConfig() end})
StealSection:CreateToggle({Name="Auto Event",CurrentValue=cfg.AutoEvent,Callback=function(v) cfg.AutoEvent=v saveConfig() end})
StealSection:CreateInput({Name="Event Keep Gen",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.EventKeepGen=v saveConfig() end})

local PetSection = CombatTab:CreateSection("Pets & Upgrades")
PetSection:CreateToggle({Name="Auto Hatch",CurrentValue=cfg.AutoHatch,Callback=function(v) cfg.AutoHatch=v saveConfig() end})
PetSection:CreateToggle({Name="Equip Best",CurrentValue=cfg.EquipBest,Callback=function(v) cfg.EquipBest=v saveConfig() end})
PetSection:CreateToggle({Name="Auto Sell Pets",CurrentValue=cfg.AutoSellPets,Callback=function(v) cfg.AutoSellPets=v saveConfig() end})
PetSection:CreateToggle({Name="Auto Sell Eggs",CurrentValue=cfg.AutoSellEggs,Callback=function(v) cfg.AutoSellEggs=v saveConfig() end})
PetSection:CreateInput({Name="Sell Under Gen",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.SellUnderGen=v saveConfig() end})
PetSection:CreateInput({Name="Keep Money",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.KeepMoney=v saveConfig() end})
PetSection:CreateToggle({Name="Upgrade Trails",CurrentValue=cfg.UpgTrails,Callback=function(v) cfg.UpgTrails=v saveConfig() end})
PetSection:CreateToggle({Name="Upgrade Treadmill",CurrentValue=cfg.UpgTreadmill,Callback=function(v) cfg.UpgTreadmill=v saveConfig() end})
PetSection:CreateToggle({Name="Upgrade Pen",CurrentValue=cfg.UpgPen,Callback=function(v) cfg.UpgPen=v saveConfig() end})

local TreadmillSection = CombatTab:CreateSection("Treadmill")
TreadmillSection:CreateToggle({Name="Auto Treadmill",CurrentValue=cfg.AutoTreadmill,Callback=function(v) cfg.AutoTreadmill=v saveConfig() end})
TreadmillSection:CreateToggle({Name="Train When Idle",CurrentValue=cfg.TrainWhenIdle,Callback=function(v) cfg.TrainWhenIdle=v saveConfig() end})
TreadmillSection:CreateSlider({Name="Ready Early %",Range={0,10},Increment=1,CurrentValue=cfg.ReadyEarly,Callback=function(v) cfg.ReadyEarly=v saveConfig() end})

local PlaceSection = CombatTab:CreateSection("Placing")
PlaceSection:CreateToggle({Name="Auto Place Eggs",CurrentValue=cfg.AutoPlaceEggs,Callback=function(v) cfg.AutoPlaceEggs=v saveConfig() end})
PlaceSection:CreateDropdown({Name="Never Place Rarity",Values=RARITIES,CurrentOption={cfg.NeverPlaceRarity},Callback=function(v) cfg.NeverPlaceRarity=v[1] saveConfig() end})
PlaceSection:CreateInput({Name="Place Min Gen",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.PlaceMinGen=v saveConfig() end})

local BypassSection = CombatTab:CreateSection("Bypass")
BypassSection:CreateToggle({Name="Bypass Speed",CurrentValue=cfg.BypassSpeed,Callback=function(v) cfg.BypassSpeed=v saveConfig() end})
BypassSection:CreateSlider({Name="Bypass Cap",Range={50,1300},Increment=10,CurrentValue=cfg.BypassCap,Callback=function(v) cfg.BypassCap=v saveConfig() end})
BypassSection:CreateToggle({Name="Flight",CurrentValue=cfg.Flight,Callback=function(v) cfg.Flight=v if not v then engine.dest=nil; removeSupportPart() end saveConfig() end})
BypassSection:CreateSlider({Name="Flight Speed",Range={150,1300},Increment=10,CurrentValue=cfg.FlightSpeed,Callback=function(v) cfg.FlightSpeed=v saveConfig() end})

local CombatMiscSection = CombatTab:CreateSection("Combat Misc")
CombatMiscSection:CreateToggle({Name="Anti Trap",CurrentValue=cfg.AntiTrap,Callback=function(v) cfg.AntiTrap=v saveConfig() end})
CombatMiscSection:CreateToggle({Name="Anti Mob",CurrentValue=cfg.AntiMob,Callback=function(v) cfg.AntiMob=v if v then applyGuardBypass() end saveConfig() end})
CombatMiscSection:CreateToggle({Name="Bat Aura",CurrentValue=cfg.BatAura,Callback=function(v) cfg.BatAura=v saveConfig() end})

-- ═══════════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════════
local VisualsTab = Window:CreateTab({Name="Visuals"})
local ESPSection = VisualsTab:CreateSection("ESP")
ESPSection:CreateToggle({Name="Egg ESP",CurrentValue=cfg.EggESP,Callback=function(v) cfg.EggESP=v if not v then clearEsp() end saveConfig() end})
ESPSection:CreateDropdown({Name="ESP Filter",Values={"All eggs","Area","Rarity","Mutation","Dropped","Carried"},CurrentOption={cfg.ESPFilter},Callback=function(v) cfg.ESPFilter=v[1] saveConfig() end})
ESPSection:CreateToggle({Name="ESP Beam",CurrentValue=cfg.ESPBeam,Callback=function(v) cfg.ESPBeam=v saveConfig() end})
ESPSection:CreateToggle({Name="Plot ESP",CurrentValue=cfg.PlotESP,Callback=function(v) cfg.PlotESP=v if not v then clearEsp() end saveConfig() end})

local StatsSection = VisualsTab:CreateSection("Stats Panel")
StatsSection:CreateToggle({Name="Show Stats Panel",CurrentValue=cfg.StatsPanel,Callback=function(v) cfg.StatsPanel=v saveConfig() end})
StatsSection:CreateToggle({Name="Claim Index",CurrentValue=cfg.ClaimIndex,Callback=function(v) cfg.ClaimIndex=v saveConfig() end})

local DiscordSection = VisualsTab:CreateSection("Discord")
DiscordSection:CreateButton({Name="Join Discord For Dupe",Callback=function()
	if setclipboard then setclipboard("https://discord.gg/bac") end
	pcall(function() Library.Notify({Title="Ivory",Content="Discord link copied!",Type="Info",Duration=3}) end)
end})

-- ═══════════════════════════════════════════════
-- WORLD TAB
-- ═══════════════════════════════════════════════
local WorldTab = Window:CreateTab({Name="World"})

local OptSection = WorldTab:CreateSection("Performance")
OptSection:CreateToggle({Name="Optimizer",CurrentValue=cfg.Optimizer,Callback=function(v) cfg.Optimizer=v applyOptimizer() saveConfig() end})
OptSection:CreateSlider({Name="FPS Cap",Range={0,240},Increment=5,CurrentValue=cfg.FPSCap,Callback=function(v) cfg.FPSCap=v saveConfig() end})

local HopSection = WorldTab:CreateSection("Server Hop")
HopSection:CreateToggle({Name="Auto Hop",CurrentValue=cfg.AutoHop,Callback=function(v) cfg.AutoHop=v saveConfig() end})
HopSection:CreateInput({Name="Hop Idle (sec)",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.HopIdle=v saveConfig() end})
HopSection:CreateInput({Name="Hop After (sec)",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.HopAfter=v saveConfig() end})
HopSection:CreateSlider({Name="Hop Pages",Range={1,10},Increment=1,CurrentValue=cfg.HopPages,Callback=function(v) cfg.HopPages=v saveConfig() end})
HopSection:CreateToggle({Name="Hop Skip Full",CurrentValue=cfg.HopSkipFull,Callback=function(v) cfg.HopSkipFull=v saveConfig() end})
HopSection:CreateDropdown({Name="Hop Players",Values={"Lowest","Highest","Random"},CurrentOption={cfg.HopPlayers},Callback=function(v) cfg.HopPlayers=v[1] saveConfig() end})
HopSection:CreateButton({Name="Hop Now",Callback=function() hop.lastHopTime=tick(); hopToRandom() end})

-- ═══════════════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════════════
local MiscTab = Window:CreateTab({Name="Misc"})
local HookSection = MiscTab:CreateSection("Webhook / Hook")
HookSection:CreateToggle({Name="Hook Enabled",CurrentValue=cfg.HookEnabled,Callback=function(v) cfg.HookEnabled=v saveConfig() end})
HookSection:CreateInput({Name="Hook URL",Placeholder="https://...",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.HookUrl=v saveConfig() end})
HookSection:CreateToggle({Name="Hook Stolen",CurrentValue=cfg.HookStolen,Callback=function(v) cfg.HookStolen=v saveConfig() end})
HookSection:CreateToggle({Name="Hook Hatched",CurrentValue=cfg.HookHatched,Callback=function(v) cfg.HookHatched=v saveConfig() end})
HookSection:CreateToggle({Name="Hook Sold",CurrentValue=cfg.HookSold,Callback=function(v) cfg.HookSold=v saveConfig() end})
HookSection:CreateToggle({Name="Hook Rewards",CurrentValue=cfg.HookRewards,Callback=function(v) cfg.HookRewards=v saveConfig() end})
HookSection:CreateInput({Name="Hook Min Gen",Placeholder="",RemoveTextAfterFocusLost=false,Callback=function(v) cfg.HookMinGen=v saveConfig() end})
HookSection:CreateDropdown({Name="Hook Rarity Floor",Values={"Any","Common","Uncommon","Rare","Epic","Legendary","Mythic"},CurrentOption={cfg.HookRarityFloor},Callback=function(v) cfg.HookRarityFloor=v[1] saveConfig() end})
HookSection:CreateToggle({Name="Session Digest",CurrentValue=cfg.SessionDigest,Callback=function(v) cfg.SessionDigest=v saveConfig() end})
HookSection:CreateToggle({Name="Hook Username",CurrentValue=cfg.HookUsername,Callback=function(v) cfg.HookUsername=v saveConfig() end})
HookSection:CreateToggle({Name="Export URL",CurrentValue=cfg.ExportUrl,Callback=function(v) cfg.ExportUrl=v saveConfig() end})

local WebhookSection = MiscTab:CreateSection("Webhook Test")
WebhookSection:CreateButton({Name="Send Test Embed",Callback=function()
	sendEmbed("Ivory Hub Test","Test webhook from Steal an Egg script",0x00AAFF)
	pcall(function() Library.Notify({Title="Ivory",Content="Test embed sent!",Type="Info",Duration=3}) end)
end})

-- ═══════════════════════════════════════════════
-- UI SETTINGS TAB (always last)
-- ═══════════════════════════════════════════════
local SettingsTab = Window:CreateTab({Name="UI Settings"})

local MenuSection = SettingsTab:CreateSection("Menu")
MenuSection:CreateKeybind({Name="Menu Keybind",CurrentKeybind=cfg.MenuKeybind,Callback=function() end})
MenuSection:CreateSlider({Name="UI Scale",Range={50,200},Increment=5,CurrentValue=cfg.UIScale,Callback=function(v) cfg.UIScale=v saveConfig() end})
MenuSection:CreateToggle({Name="Start Minimized",CurrentValue=cfg.StartMin,Callback=function(v) cfg.StartMin=v saveConfig() end})

local CreditsSection = SettingsTab:CreateSection("Credits")
CreditsSection:CreateLabel({Text="Ivory Hub - Steal an Egg"})
CreditsSection:CreateLabel({Text="Ported from KiraHub"})
CreditsSection:CreateLabel({Text="Version: 1.4"})

local ServerSection = SettingsTab:CreateSection("Server")
ServerSection:CreateButton({Name="Rejoin",Callback=function()
	pcall(function() TeleportService:Teleport(PLACE_ID, LocalPlayer) end)
end})
ServerSection:CreateButton({Name="Server Hop",Callback=function()
	hop.lastHopTime=tick(); hopToRandom()
end})

local ThemeSection = SettingsTab:CreateSection("Theme")
ThemeSection:CreateColorPicker({Name="Accent Color",Color=Color3.fromRGB(0,170,255),Callback=function(c) cfg.Theme="Custom"; saveConfig() end})

local ConfigSection = SettingsTab:CreateSection("Configuration")
ConfigSection:CreateButton({Name="Save Config",Callback=function() saveConfig()
	pcall(function() Library.Notify({Title="Ivory",Content="Config saved!",Type="Info",Duration=2}) end)
end})
ConfigSection:CreateButton({Name="Load Config",Callback=function() loadConfig()
	pcall(function() Library.Notify({Title="Ivory",Content="Config loaded!",Type="Info",Duration=2}) end)
end})
ConfigSection:CreateButton({Name="Export Config",Callback=function()
	pcall(function()
		local data = HttpService:JSONEncode(cfg)
		if setclipboard then setclipboard(data) end
		Library.Notify({Title="Ivory",Content="Config copied to clipboard!",Type="Info",Duration=3})
	end)
end})
ConfigSection:CreateButton({Name="Import Config",Callback=function()
	pcall(function()
		local data = getclipboard and getclipboard() or ""
		if data and data~="" then
			local parsed = HttpService:JSONDecode(data)
			for k,v in pairs(parsed) do if cfg[k]~=nil then cfg[k]=v end end
			saveConfig()
			Library.Notify({Title="Ivory",Content="Config imported!",Type="Info",Duration=3})
		end
	end)
end})
ConfigSection:CreateButton({Name="Unload",Callback=function()
	isRunning = false
	for _,c in ipairs(allConns) do pcall(function() c:Disconnect() end) end
	allConns = {}
	clearEsp(); removeSupportPart()
	if statsGui then pcall(function() statsGui:Destroy() end); statsGui=nil end
	restoreCharCanTouch()
	pcall(function() Library.Unload() end)
end})

pcall(function() Window:SetFooter("v1.4 | Steal an Egg | "..UserId) end)

-- ═══════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════
startMovementEngine()

task.spawn(function()
	task.wait(1)
	if cfg.HookEnabled and cfg.HookUrl and cfg.HookUrl~="" and cfg.HookUrl~="https://" then
		sendEmbed("Loaded","Ivory Hub loaded in Steal an Egg\nUser: "..LocalPlayer.Name.." ["..UserId.."]\nVersion: 1.4",0x00AAFF)
	end
end)

pcall(function() Library.Notify({Title="Ivory",Content="Steal an Egg loaded!",Type="Success",Duration=3}) end)