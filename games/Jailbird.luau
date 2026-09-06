-- Join Discord For Free Keys | discord.gg/MCWYKBdB4E

--[[ Jailbird Full Suite - IvoryHubLibrary
  PlaceId: 14939963714 (InMatch) / 14772802900 (Lobby)
  Universe: 5091490171
]]

--------------------------------------------------------------------------------
-- SERVICES
--------------------------------------------------------------------------------
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local Camera             = workspace.CurrentCamera
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local TeleportService    = game:GetService("TeleportService")
local HttpService        = game:GetService("HttpService")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer

--------------------------------------------------------------------------------
-- LIBRARY
--------------------------------------------------------------------------------
local httpGet do
	local fn = request or http_request or (syn and syn.request)
	if fn then
		httpGet = function(url) local res = fn({ Url = url, Method = "GET" }); return res and res.Body end
	else
		httpGet = function(url) return game:HttpGet(url, true) end
	end
end

local LIB_SRC = httpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua")
if not LIB_SRC or LIB_SRC == "" then error("[Ivory] Failed to fetch library") end
LIB_SRC = LIB_SRC:gsub("^\239\187\191", "")
local Library = loadstring(LIB_SRC)()
if not Library then error("[Ivory] Failed to load library") end

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 720,
	Height = 600,
	AccentColor = Color3.fromRGB(128, 0, 255),
	MinimizeKey = Enum.KeyCode.RightShift,
})

--------------------------------------------------------------------------------
-- CONTROL REGISTRY
--------------------------------------------------------------------------------
local CTL = {}
local function reg(key, handle)
	CTL[key] = handle
	return handle
end

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local CONFIG = {
	aimEnabled = true, aimFov = 120, aimSmooth = 1, aimWallCheck = true, aimAliveCheck = true,
	aimKey = "MouseButton2", aimPart = "Head", aimPriority = "Crosshair",
	silentEnabled = false, silentFov = 300, silentPart = "Head", silentMaxDist = 700,
	boxEnabled = false, nameEnabled = false, distEnabled = false, healthEnabled = false,
	tracerEnabled = false, skeletonEnabled = false, weaponEspEnabled = false,
	highlightEnabled = false, highlightWallCheck = false, teamColorEnabled = false,
	tracerOrigin = "Bottom",
	speedEnabled = false, speedValue = 20,
	jumpEnabled = false, jumpValue = 50,
	noFallDamage = false, autoReload = false, autoRespawn = false,
	teleportToPlayer = false,
	antiAfk = false, fpsUnlocker = false,
	maxDist = 1500, textSize = 14, textOutline = true,
	boxColor = Color3.fromRGB(255, 0, 0), healthColor = Color3.fromRGB(0, 255, 0),
	highlightFill = Color3.fromRGB(255, 0, 0),
	menuKey = "RightShift",
}

local aimHeld = false
local CONFIG_DIR = "IvoryHub/Jailbird"

local function ensureFolders()
	if not isfolder("IvoryHub") then makefolder("IvoryHub") end
	if not isfolder(CONFIG_DIR) then makefolder(CONFIG_DIR) end
end

local function listConfigs()
	ensureFolders()
	local names = {}
	local files = listfiles(CONFIG_DIR)
	for _, f in ipairs(files) do
		if f:match("%.json$") then table.insert(names, f:match("([^/\\]+)%.json$")) end
	end
	table.sort(names)
	return names
end

local function saveConfig(name)
	ensureFolders()
	writefile(CONFIG_DIR .. "/" .. name .. ".json", HttpService:JSONEncode(CONFIG))
end

local function loadConfigByName(name)
	local path = CONFIG_DIR .. "/" .. name .. ".json"
	if not isfile(path) then return false end
	local data = HttpService:JSONDecode(readfile(path))
	for k, v in pairs(data) do if CONFIG[k] ~= nil then CONFIG[k] = v end end
	return true
end

local function applyConfigToUI()
	for key, value in pairs(CONFIG) do
		local handle = CTL[key]
		if handle then pcall(function() handle:Set(value) end) end
	end
end

local function deleteConfig(name)
	ensureFolders()
	local path = CONFIG_DIR .. "/" .. name .. ".json"
	if isfile(path) then delfile(path) end
end

--------------------------------------------------------------------------------
-- UTILITIES
--------------------------------------------------------------------------------
local function getCharacter() return LocalPlayer.Character end
local function getHumanoid() local c = getCharacter(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRootPart() local c = getCharacter(); return c and c:FindFirstChild("HumanoidRootPart") end
local function isAlive() local hum = getHumanoid(); return hum and hum.Health > 0 end

local function isEnemy(player)
	if player == LocalPlayer then return false end
	local myTeam = LocalPlayer.Team
	local theirTeam = player.Team
	if not myTeam or not theirTeam then return true end
	return myTeam ~= theirTeam
end

local function worldToScreen(pos)
	local sp, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

local function getDistance(pos)
	local root = getRootPart()
	if not root then return math.huge end
	return (root.Position - pos).Magnitude
end

local function wallCheck(from, to)
	if not CONFIG.aimWallCheck then return true end
	local char = getCharacter()
	if not char then return false end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	params.RespectCanCollide = false
	local result = workspace:Raycast(from, to - from, params)
	if not result then return true end
	if result.Instance and result.Instance:IsDescendantOf(char) then return true end
	return false
end

local function getEyePosition()
	local root = getRootPart()
	if not root then return Camera.CFrame.Position end
	return root.Position + Vector3.new(0, 1.5, 0)
end

local function getClosestPlayer()
	if not isAlive() then return nil end
	local root = getRootPart()
	if not root then return nil end
	local eyePos = getEyePosition()
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local closest, closestScore = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and isEnemy(player) then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then continue end
				if CONFIG.aimAliveCheck and hum.Health <= 0 then continue end
				local targetPart = char:FindFirstChild(CONFIG.aimPart) or char:FindFirstChild("HumanoidRootPart")
				if not targetPart then continue end
				local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
				if not onScreen then continue end
				local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				if CONFIG.aimPriority == "Crosshair" then
					if screenDist >= CONFIG.aimFov then continue end
					if CONFIG.aimWallCheck and not wallCheck(eyePos, targetPart.Position) then continue end
					if screenDist < closestScore then closestScore = screenDist; closest = {player = player, part = targetPart, dist = screenDist} end
				else
					local worldDist = getDistance(targetPart.Position)
					if screenDist >= CONFIG.aimFov then continue end
					if CONFIG.aimWallCheck and not wallCheck(eyePos, targetPart.Position) then continue end
					if worldDist < closestScore then closestScore = worldDist; closest = {player = player, part = targetPart, dist = screenDist} end
				end
			end
		end
	end
	return closest
end

local function getCrosshairTarget()
	if not isAlive() then return nil end
	local char = getCharacter()
	if not char then return nil end
	local tool = char:FindFirstChildOfClass("Tool")
	if not tool then return nil end
	local ammo = tool:GetAttribute("Ammo")
	if ammo and ammo <= 0 then return nil end
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and isEnemy(player) then
			local pchar = player.Character
			if pchar then
				local hum = pchar:FindFirstChildOfClass("Humanoid")
				if not hum or hum.Health <= 0 then continue end
				for _, part in ipairs(pchar:GetChildren()) do
					if part:IsA("BasePart") then
						local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
						if onScreen then
							local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
							if dist < 25 then
								local eyePos = getEyePosition()
								if CONFIG.aimWallCheck and not wallCheck(eyePos, part.Position) then continue end
								return player
							end
						end
					end
				end
			end
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- ESP DRAWING
--------------------------------------------------------------------------------
local espObjects = {}
local tracers = {}
local skeletons = {}
local weaponLabels = {}

local function clearESP()
	for _, obj in pairs(espObjects) do
		for _, v in pairs(obj) do if v.Remove then pcall(function() v:Remove() end) end end
	end
	espObjects = {}
	for _, v in pairs(tracers) do pcall(function() v:Remove() end) end
	tracers = {}
	for _, v in pairs(skeletons) do for _, l in pairs(v) do pcall(function() l:Remove() end) end end
	skeletons = {}
	for _, v in pairs(weaponLabels) do pcall(function() v:Remove() end) end
	weaponLabels = {}
end

local function anyEspEnabled()
	return CONFIG.boxEnabled or CONFIG.nameEnabled or CONFIG.distEnabled or CONFIG.healthEnabled
		or CONFIG.tracerEnabled or CONFIG.skeletonEnabled or CONFIG.weaponEspEnabled
end

local function rebuildESP()
	clearESP()
	if not anyEspEnabled() then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and isEnemy(player) then
			espObjects[player] = {}
			if CONFIG.boxEnabled then
				local bo = Drawing.new("Quad"); bo.Thickness = 3; bo.Color = Color3.new(0,0,0); bo.Filled = false; bo.Transparency = 0.8; bo.Visible = false
				local b = Drawing.new("Quad"); b.Thickness = 1; b.Color = CONFIG.boxColor; b.Filled = false; b.Transparency = 1; b.Visible = false
				espObjects[player].boxOutline = bo; espObjects[player].box = b
			end
			if CONFIG.nameEnabled then
				local no = Drawing.new("Text"); no.Size = CONFIG.textSize; no.Color = Color3.new(0,0,0); no.Center = true; no.Outline = false; no.Transparency = 0.8; no.Visible = false
				local n = Drawing.new("Text"); n.Size = CONFIG.textSize; n.Color = Color3.new(1,1,1); n.Center = true; n.Outline = CONFIG.textOutline; n.Transparency = 1; n.Visible = false
				espObjects[player].nameOutline = no; espObjects[player].name = n
			end
			if CONFIG.distEnabled then
				local do2 = Drawing.new("Text"); do2.Size = CONFIG.textSize; do2.Color = Color3.new(0,0,0); do2.Center = true; do2.Outline = false; do2.Transparency = 0.8; do2.Visible = false
				local d = Drawing.new("Text"); d.Size = CONFIG.textSize; d.Color = Color3.new(1,1,1); d.Center = true; d.Outline = CONFIG.textOutline; d.Transparency = 1; d.Visible = false
				espObjects[player].distOutline = do2; espObjects[player].dist = d
			end
			if CONFIG.healthEnabled then
				local hb = Drawing.new("Line"); hb.Thickness = 5; hb.Color = Color3.new(0,0,0); hb.Transparency = 0.6; hb.Visible = false
				local h = Drawing.new("Line"); h.Thickness = 3; h.Color = CONFIG.healthColor; h.Transparency = 1; h.Visible = false
				espObjects[player].healthBg = hb; espObjects[player].health = h
			end
			if CONFIG.tracerEnabled then
				local tr = Drawing.new("Line"); tr.Thickness = 1; tr.Color = Color3.new(1,1,1); tr.Transparency = 0.8; tr.Visible = false
				tracers[player] = tr
			end
			if CONFIG.skeletonEnabled then
				skeletons[player] = {}
				for _ = 1, 5 do
					local l = Drawing.new("Line"); l.Thickness = 1; l.Color = Color3.new(1,1,1); l.Transparency = 0.8; l.Visible = false
					table.insert(skeletons[player], l)
				end
				local hc = Drawing.new("Circle"); hc.Thickness = 1; hc.NumSides = 24; hc.Radius = 3; hc.Filled = true; hc.Color = Color3.new(1,1,1); hc.Transparency = 0.8; hc.Visible = false
				skeletons[player].headCircle = hc
			end
			if CONFIG.weaponEspEnabled then
				local wl = Drawing.new("Text"); wl.Size = CONFIG.textSize; wl.Color = Color3.fromRGB(255, 255, 0); wl.Center = true; wl.Outline = CONFIG.textOutline; wl.Transparency = 1; wl.Visible = false
				weaponLabels[player] = wl
			end
		end
	end
end

local function getWeaponName(player)
	local char = player.Character
	if not char then return nil end
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Tool") then return v.Name end
	end
	return nil
end

local function getBones(char)
	local head = char:FindFirstChild("Head")
	local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	local lArm = char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftUpperArm")
	local rArm = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightUpperArm")
	local lLeg = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftUpperLeg")
	local rLeg = char:FindFirstChild("Right Leg") or char:FindFirstChild("RightUpperLeg")
	if not (head and torso and lArm and rArm and lLeg and rLeg) then return nil end
	return {
		{head.Position, torso.Position},
		{torso.Position, lArm.Position},
		{torso.Position, rArm.Position},
		{torso.Position, lLeg.Position},
		{torso.Position, rLeg.Position},
	}
end

local function getTracerStart()
	if CONFIG.tracerOrigin == "Center" then
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	elseif CONFIG.tracerOrigin == "Bottom" then
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
	else
		return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y * 0.75)
	end
end

local function getTeamColor(player)
	if not CONFIG.teamColorEnabled then return nil end
	if not player.Team then return Color3.new(1, 1, 1) end
	if player.Team.Name == "Blue" then return Color3.fromRGB(85, 175, 235) end
	return Color3.fromRGB(255, 135, 135)
end

local function updateESP()
	local tracerStart = CONFIG.tracerEnabled and getTracerStart() or nil
	for player, objs in pairs(espObjects) do
		local show = false
		if player.Parent and player ~= LocalPlayer then
			local char = player.Character
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")
				local head = char:FindFirstChild("Head")
				if hum and root and head and hum.Health > 0 then
					local dist = getDistance(root.Position)
					if dist <= CONFIG.maxDist then
						local topPos, topOn = worldToScreen(root.Position + Vector3.new(0, 3, 0))
						local botPos, botOn = worldToScreen(root.Position - Vector3.new(0, 3, 0))
						if topOn or botOn then
							show = true
							local boxH = (topPos - botPos).Magnitude
							local boxW = boxH / 2
							local tl = topPos + Vector2.new(-boxW / 2, 0)
							local tr = topPos + Vector2.new(boxW / 2, 0)
							local bl = botPos + Vector2.new(-boxW / 2, 0)
							local br = botPos + Vector2.new(boxW / 2, 0)
							local teamCol = getTeamColor(player)

							if objs.box then pcall(function()
								objs.box.PointA = tl; objs.box.PointB = tr; objs.box.PointC = br; objs.box.PointD = bl
								objs.box.Color = teamCol or CONFIG.boxColor; objs.box.Visible = CONFIG.boxEnabled
							end) end
							if objs.boxOutline then pcall(function()
								objs.boxOutline.PointA = tl; objs.boxOutline.PointB = tr; objs.boxOutline.PointC = br; objs.boxOutline.PointD = bl
								objs.boxOutline.Visible = CONFIG.boxEnabled
							end) end
							if objs.name then pcall(function()
								objs.name.Position = Vector2.new(topPos.X, topPos.Y - CONFIG.textSize - 2)
								objs.name.Text = player.DisplayName; objs.name.Size = CONFIG.textSize
								objs.name.Color = teamCol or Color3.new(1,1,1); objs.name.Visible = CONFIG.nameEnabled
							end) end
							if objs.nameOutline then pcall(function()
								objs.nameOutline.Position = Vector2.new(topPos.X, topPos.Y - CONFIG.textSize - 2)
								objs.nameOutline.Text = player.DisplayName; objs.nameOutline.Size = CONFIG.textSize
								objs.nameOutline.Visible = CONFIG.nameEnabled
							end) end
							if objs.dist then pcall(function()
								objs.dist.Position = Vector2.new(botPos.X, botPos.Y + 4)
								objs.dist.Text = math.floor(dist) .. "m"; objs.dist.Size = CONFIG.textSize; objs.dist.Visible = CONFIG.distEnabled
							end) end
							if objs.distOutline then pcall(function()
								objs.distOutline.Position = Vector2.new(botPos.X, botPos.Y + 4)
								objs.distOutline.Text = math.floor(dist) .. "m"; objs.distOutline.Size = CONFIG.textSize; objs.distOutline.Visible = CONFIG.distEnabled
							end) end
							if objs.health and objs.healthBg then pcall(function()
								local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
								local bTop = topPos + Vector2.new(-boxW / 2 - 6, 0)
								local bBot = botPos + Vector2.new(-boxW / 2 - 6, 0)
								local barH = (bTop - bBot).Magnitude
								objs.healthBg.From = bTop; objs.healthBg.To = bBot; objs.healthBg.Visible = CONFIG.healthEnabled
								objs.health.From = bTop; objs.health.To = bTop + Vector2.new(0, barH * pct)
								objs.health.Color = pct > 0.5 and CONFIG.healthColor or (pct > 0.25 and Color3.fromRGB(255,165,0) or Color3.fromRGB(255,0,0))
								objs.health.Visible = CONFIG.healthEnabled
							end) end
						end
					end
				end
			end
		end
		if not show then
			for _, v in pairs(objs) do if v.Visible ~= nil then pcall(function() v.Visible = false end) end end
		end
	end

	-- Tracers
	if CONFIG.tracerEnabled and tracerStart then
		for player, tr in pairs(tracers) do
			pcall(function()
				if player.Parent and player ~= LocalPlayer then
					local char = player.Character
					if char then
						local root = char:FindFirstChild("HumanoidRootPart")
						local hum = char:FindFirstChildOfClass("Humanoid")
						if root and hum and hum.Health > 0 then
							local dist = getDistance(root.Position)
							if dist <= CONFIG.maxDist then
								local sPos, onScreen = worldToScreen(root.Position)
								if onScreen then
									tr.From = tracerStart; tr.To = sPos
									tr.Color = getTeamColor(player) or Color3.new(1,1,1)
									tr.Visible = true; return
								end
							end
						end
					end
				end
				tr.Visible = false
			end)
		end
	end

	-- Skeletons
	if CONFIG.skeletonEnabled then
		for player, lines in pairs(skeletons) do
			pcall(function()
				if player.Parent and player ~= LocalPlayer then
					local char = player.Character
					if char then
						local root = char:FindFirstChild("HumanoidRootPart")
						local hum = char:FindFirstChildOfClass("Humanoid")
						if root and hum and hum.Health > 0 then
							local dist = getDistance(root.Position)
							if dist <= CONFIG.maxDist then
								local bones = getBones(char)
								if bones then
									for i, bone in ipairs(bones) do
										if lines[i] then
											local p1, on1 = worldToScreen(bone[1])
											local p2, on2 = worldToScreen(bone[2])
											if on1 and on2 then
												lines[i].From = p1; lines[i].To = p2
												lines[i].Color = getTeamColor(player) or Color3.new(1,1,1)
												lines[i].Visible = true
											else
												lines[i].Visible = false
											end
										end
									end
									local head = char:FindFirstChild("Head")
									if head and lines.headCircle then
										local headPos, headOn = worldToScreen(head.Position)
										if headOn then
											lines.headCircle.Position = headPos
											lines.headCircle.Color = getTeamColor(player) or Color3.new(1,1,1)
											lines.headCircle.Visible = true
										else
											lines.headCircle.Visible = false
										end
									end
									return
								end
							end
						end
					end
				end
				for _, l in pairs(lines) do if l.Visible ~= nil then l.Visible = false end end
			end)
		end
	end

	-- Weapon ESP
	if CONFIG.weaponEspEnabled then
		for player, wl in pairs(weaponLabels) do
			pcall(function()
				if player.Parent and player ~= LocalPlayer then
					local char = player.Character
					if char then
						local root = char:FindFirstChild("HumanoidRootPart")
						local hum = char:FindFirstChildOfClass("Humanoid")
						if root and hum and hum.Health > 0 then
							local dist = getDistance(root.Position)
							if dist <= CONFIG.maxDist then
								local wep = getWeaponName(player)
								if wep then
									local sPos, onScreen = worldToScreen(root.Position + Vector3.new(0, 4, 0))
									if onScreen then
										wl.Position = sPos; wl.Text = wep; wl.Size = CONFIG.textSize
										wl.Visible = true; return
									end
								end
							end
						end
					end
				end
				wl.Visible = false
			end)
		end
	end
end

--------------------------------------------------------------------------------
-- HIGHLIGHTS
--------------------------------------------------------------------------------
local highlights = {}
local function clearHighlights()
	for _, hl in pairs(highlights) do pcall(function() if hl and hl.Parent then hl:Destroy() end end) end
	highlights = {}
end

local function updateHighlights()
	clearHighlights()
	if not CONFIG.highlightEnabled then return end
	local eyePos = getEyePosition()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and isEnemy(player) then
			local char = player.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local visible = true
				if CONFIG.highlightWallCheck and eyePos then
					local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
					if head then
						visible = wallCheck(eyePos, head.Position)
					end
				end
				if visible then
					pcall(function()
						local hl = Instance.new("Highlight")
						hl.Adornee = char
						hl.FillColor = CONFIG.highlightFill
						hl.OutlineColor = Color3.new(1,1,1)
						hl.FillTransparency = 0.5
						hl.OutlineTransparency = 0
						hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						hl.Parent = game:GetService("CoreGui")
						highlights[player] = hl
					end)
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- AIMBOT
--------------------------------------------------------------------------------
local function aimAtTarget(target)
	if not target then return end
	local targetPos = target.part.Position + Vector3.new(0, 0.5, 0)
	local camPos = Camera.CFrame.Position
	local direction = (targetPos - camPos)
	local smoothFactor = 1 - (CONFIG.aimSmooth / 20)
	Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(camPos, camPos + direction), smoothFactor)
end

--------------------------------------------------------------------------------
-- SILENT AIM (target detection)
--------------------------------------------------------------------------------
local getSilentTarget = function()
	if not CONFIG.silentEnabled then return nil end
	if not isAlive() then return nil end
	local mousePos = UserInputService:GetMouseLocation()
	local closest, shortest = nil, CONFIG.silentFov
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer or not player.Character then continue end
		if not isEnemy(player) then continue end
		local char = player.Character
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end
		local targetPart = char:FindFirstChild(CONFIG.silentPart) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		if not targetPart then continue end
		local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
		if not onScreen then continue end
		local worldDist = getDistance(targetPart.Position)
		if worldDist > CONFIG.silentMaxDist then continue end
		local eyePos = getEyePosition()
		if not wallCheck(eyePos, targetPart.Position) then continue end
		local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		if dist < shortest then
			shortest = dist
			closest = targetPart
		end
	end
	return closest
end

local shootRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Shoot", 5)
local reloadRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("Reload", 5)
local spawnRemote = ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("SpawnPlayer", 5)

--------------------------------------------------------------------------------
-- SILENT AIM
--------------------------------------------------------------------------------
local silentFovCircle = Drawing.new("Circle")
silentFovCircle.Thickness = 2; silentFovCircle.NumSides = 100; silentFovCircle.Radius = CONFIG.silentFov
silentFovCircle.Color = Color3.fromRGB(255, 0, 180); silentFovCircle.Transparency = 0.75; silentFovCircle.Visible = false
silentFovCircle.Filled = false

local OldBulletRayCast, OldKnifeRayCast

local function silentRedirect(origin, direction, distance, ignoreList, isKnife)
	local target = getSilentTarget()
	if target then
		local newDirection = (target.Position - origin).Unit
		if isKnife and OldKnifeRayCast then
			return OldKnifeRayCast(origin, newDirection, distance, ignoreList)
		elseif OldBulletRayCast then
			return OldBulletRayCast(origin, newDirection, distance, ignoreList)
		end
	end
	if isKnife and OldKnifeRayCast then
		return OldKnifeRayCast(origin, direction, distance, ignoreList)
	elseif OldBulletRayCast then
		return OldBulletRayCast(origin, direction, distance, ignoreList)
	end
end

local function setupSilentAim()
	if not CONFIG.silentEnabled then return end
	if OldBulletRayCast then return end
	pcall(function()
		local tbl = filtergc("table", { Keys = {"BulletRayCast", "KnifeRayCast"} }, true)
		if tbl then
			OldBulletRayCast = tbl.BulletRayCast
			OldKnifeRayCast = tbl.KnifeRayCast
			tbl.BulletRayCast = function(a, b, c, d)
				return silentRedirect(a, b, c, d, false)
			end
			tbl.KnifeRayCast = function(a, b, c, d)
				return silentRedirect(a, b, c, d, true)
			end
		end
	end)
end

task.spawn(function()
	if not CONFIG.silentEnabled then return end
	local tries = 0
	while tries < 25 and not OldBulletRayCast do
		setupSilentAim()
		if OldBulletRayCast then break end
		tries += 1
		task.wait(0.6)
	end
end)

--------------------------------------------------------------------------------
-- FOV CIRCLE
--------------------------------------------------------------------------------
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1; fovCircle.NumSides = 64; fovCircle.Radius = CONFIG.aimFov
fovCircle.Filled = false; fovCircle.Color = Color3.fromRGB(255,255,255); fovCircle.Transparency = 0.8; fovCircle.Visible = false

local _lastHighlightUpdate = 0

--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera
	if not Camera then return end

	-- Aimbot
	if CONFIG.aimEnabled and aimHeld and isAlive() then
		local target = getClosestPlayer()
		if target then aimAtTarget(target) end
	end

	-- FOV circle
	fovCircle.Radius = CONFIG.aimFov
	fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	fovCircle.Visible = CONFIG.aimEnabled

	-- Silent aim FOV circle (pink, follows mouse)
	silentFovCircle.Radius = CONFIG.silentFov
	silentFovCircle.Position = UserInputService:GetMouseLocation()
	silentFovCircle.Visible = CONFIG.silentEnabled

	-- ESP
	if anyEspEnabled() then updateESP() end

	-- Highlights with wall check
	if CONFIG.highlightEnabled and CONFIG.highlightWallCheck then
		if not _lastHighlightUpdate or (tick() - _lastHighlightUpdate) > 0.2 then
			_lastHighlightUpdate = tick()
			updateHighlights()
		end
	end
end)

--------------------------------------------------------------------------------
-- SPEED & JUMP
--------------------------------------------------------------------------------
local speedConn, jumpConn
local function applySpeedJump()
	local hum = getHumanoid()
	if not hum then return end
	if CONFIG.speedEnabled then
		pcall(function() hum.WalkSpeed = CONFIG.speedValue end)
		if speedConn then speedConn:Disconnect() end
		speedConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
			if CONFIG.speedEnabled and hum.WalkSpeed ~= CONFIG.speedValue then
				hum.WalkSpeed = CONFIG.speedValue
			end
		end)
	end
	if CONFIG.jumpEnabled then
		pcall(function() hum.JumpHeight = CONFIG.jumpValue end)
		if jumpConn then jumpConn:Disconnect() end
		jumpConn = hum:GetPropertyChangedSignal("JumpHeight"):Connect(function()
			if CONFIG.jumpEnabled and hum.JumpHeight ~= CONFIG.jumpValue then
				hum.JumpHeight = CONFIG.jumpValue
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- NO FALL DAMAGE
--------------------------------------------------------------------------------
local fallDamageConn
local function setupNoFallDamage()
	if fallDamageConn then fallDamageConn:Disconnect() end
	if not CONFIG.noFallDamage then return end
	local hum = getHumanoid()
	if not hum then return end
	fallDamageConn = hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Freefall then
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end
	end)
end

--------------------------------------------------------------------------------
-- AUTO RELOAD
--------------------------------------------------------------------------------
local autoReloadConn
local function setupAutoReload()
	if autoReloadConn then autoReloadConn:Disconnect() end
	if not CONFIG.autoReload then return end
	autoReloadConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.autoReload then return end
		if not isAlive() then return end
		local char = getCharacter()
		if not char then return end
		for _, tool in ipairs(char:GetChildren()) do
			if tool:IsA("Tool") then
				local ammo = tool:GetAttribute("Ammo")
				if ammo and ammo <= 0 then
					pcall(function() reloadRemote:FireServer(tool.Name) end)
				end
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- AUTO RESPAWN
--------------------------------------------------------------------------------
local autoRespawnConn
local function setupAutoRespawn()
	if autoRespawnConn then autoRespawnConn:Disconnect() end
	if not CONFIG.autoRespawn then return end
	autoRespawnConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.autoRespawn then return end
		if not isAlive() and spawnRemote then
			pcall(function() spawnRemote:FireServer() end)
		end
	end)
end

--------------------------------------------------------------------------------
-- ANTI-AFK
--------------------------------------------------------------------------------
local antiAfkConn
local function setupAntiAfk()
	if antiAfkConn then antiAfkConn:Disconnect() end
	if not CONFIG.antiAfk then return end
	antiAfkConn = RunService.Heartbeat:Connect(function()
		if not CONFIG.antiAfk then return end
		pcall(function()
		VirtualUser = game:GetService("VirtualUser")
			LocalPlayer.Idled:Connect(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end)
	end)
end

--------------------------------------------------------------------------------
-- FPS UNLOCKER
--------------------------------------------------------------------------------
local function setupFpsUnlocker()
	if not CONFIG.fpsUnlocker then return end
	pcall(function()
		if setfpscap then setfpscap(999) end
	end)
end

--------------------------------------------------------------------------------
-- INPUT
--------------------------------------------------------------------------------
local function getAimKeyCode()
	local key = CONFIG.aimKey
	if key == "MouseButton2" then return nil, Enum.UserInputType.MouseButton2 end
	if key == "MouseButton1" then return nil, Enum.UserInputType.MouseButton1 end
	if key == "MouseButton3" then return nil, Enum.UserInputType.MouseButton3 end
	for _, enum in ipairs(Enum.KeyCode:GetEnumItems()) do
		if enum.Name == key then return enum, nil end
	end
	return nil, Enum.UserInputType.MouseButton2
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	local aimKC, aimIT = getAimKeyCode()
	if aimKC and input.KeyCode == aimKC then aimHeld = true
	elseif aimIT and input.UserInputType == aimIT then aimHeld = true end
end)

UserInputService.InputEnded:Connect(function(input)
	local aimKC, aimIT = getAimKeyCode()
	if aimKC and input.KeyCode == aimKC then aimHeld = false
	elseif aimIT and input.UserInputType == aimIT then aimHeld = false end
end)

--------------------------------------------------------------------------------
-- PLAYER EVENTS
--------------------------------------------------------------------------------
local function onCharacterAdded()
	task.wait(1)
	if CONFIG.speedEnabled or CONFIG.jumpEnabled then applySpeedJump() end
	if CONFIG.noFallDamage then setupNoFallDamage() end
	if CONFIG.highlightEnabled then updateHighlights() end
	if anyEspEnabled() then rebuildESP() end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
Players.PlayerAdded:Connect(function()
	task.wait(2)
	if CONFIG.highlightEnabled then updateHighlights() end
	if anyEspEnabled() then rebuildESP() end
end)
Players.PlayerRemoving:Connect(function(player)
	espObjects[player] = nil
	tracers[player] = nil
	skeletons[player] = nil
	weaponLabels[player] = nil
	pcall(function() if highlights[player] then highlights[player]:Destroy() end end)
	highlights[player] = nil
end)

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------
local CreditsLabel, DiscordLabel
local configNameInput, configDropdown
local espDropdown

-- COMBAT
do
	local tab = Window:CreateTab("combat")

	DiscordLabel = tab:CreateSection("Discord"):CreateLabel({ Text = "Join Discord For Free Keys" })
	tab:CreateSection("Discord"):CreateButton({ Name = "Copy Discord Link", Callback = function()
		pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
		Library.Notify({ Title = "Ivory", Content = "Discord Link Copied!", Type = "Success", Duration = 3 })
	end })

	local aim = tab:CreateSection("Aimbot")
	aim:CreateLabel("Hold right-click to aim. FOV circle always shows.")
	reg("aimEnabled", aim:CreateToggle({ Name = "Aimbot enabled", CurrentValue = CONFIG.aimEnabled, Callback = function(v) CONFIG.aimEnabled = v end }))
	aim:CreateKeybind({ Name = "Aim key", CurrentKeybind = CONFIG.aimKey, Callback = function() end, ChangedCallback = function(k) CONFIG.aimKey = k end })
	reg("aimFov", aim:CreateSlider({ Name = "FOV (pixels)", Min = 10, Max = 800, CurrentValue = CONFIG.aimFov, Callback = function(v) CONFIG.aimFov = v end }))
	reg("aimSmooth", aim:CreateSlider({ Name = "Smooth", Min = 1, Max = 20, CurrentValue = CONFIG.aimSmooth, Callback = function(v) CONFIG.aimSmooth = v end }))
	reg("aimWallCheck", aim:CreateToggle({ Name = "Wall check", CurrentValue = CONFIG.aimWallCheck, Callback = function(v) CONFIG.aimWallCheck = v end }))
	reg("aimAliveCheck", aim:CreateToggle({ Name = "Alive check", CurrentValue = CONFIG.aimAliveCheck, Callback = function(v) CONFIG.aimAliveCheck = v end }))
	reg("aimPart", aim:CreateDropdown({ Name = "Aim at", Values = { "Head", "HumanoidRootPart" }, CurrentOption = CONFIG.aimPart, Callback = function(v) CONFIG.aimPart = v end }))
	reg("aimPriority", aim:CreateDropdown({ Name = "Priority", Values = { "Crosshair", "Distance" }, CurrentOption = CONFIG.aimPriority, Callback = function(v) CONFIG.aimPriority = v end }))

	local silent = tab:CreateSection("Silent Aim")
	silent:CreateLabel("Redirects bullets to nearest enemy in pink FOV circle.")
	reg("silentEnabled", silent:CreateToggle({ Name = "Silent aim enabled", CurrentValue = CONFIG.silentEnabled, Callback = function(v) CONFIG.silentEnabled = v; if v and not OldBulletRayCast then setupSilentAim() end end }))
	reg("silentFov", silent:CreateSlider({ Name = "FOV (pixels)", Min = 30, Max = 800, CurrentValue = CONFIG.silentFov, Callback = function(v) CONFIG.silentFov = v end }))
	reg("silentPart", silent:CreateDropdown({ Name = "Aim at", Values = { "Head", "HumanoidRootPart" }, CurrentOption = CONFIG.silentPart, Callback = function(v) CONFIG.silentPart = v end }))
	reg("silentMaxDist", silent:CreateSlider({ Name = "Max distance", Min = 100, Max = 2000, CurrentValue = CONFIG.silentMaxDist, Callback = function(v) CONFIG.silentMaxDist = v end }))
end

-- VISUALS
do
	local tab = Window:CreateTab("visuals")

	local esp = tab:CreateSection("ESP")
	reg("boxEnabled", esp:CreateToggle({ Name = "Box ESP", CurrentValue = CONFIG.boxEnabled, Callback = function(v) CONFIG.boxEnabled = v; rebuildESP() end }))
	reg("nameEnabled", esp:CreateToggle({ Name = "Name tag", CurrentValue = CONFIG.nameEnabled, Callback = function(v) CONFIG.nameEnabled = v; rebuildESP() end }))
	reg("distEnabled", esp:CreateToggle({ Name = "Distance", CurrentValue = CONFIG.distEnabled, Callback = function(v) CONFIG.distEnabled = v; rebuildESP() end }))
	reg("healthEnabled", esp:CreateToggle({ Name = "Health bar", CurrentValue = CONFIG.healthEnabled, Callback = function(v) CONFIG.healthEnabled = v; rebuildESP() end }))
	reg("tracerEnabled", esp:CreateToggle({ Name = "Tracers", CurrentValue = CONFIG.tracerEnabled, Callback = function(v) CONFIG.tracerEnabled = v; rebuildESP() end }))
	reg("skeletonEnabled", esp:CreateToggle({ Name = "Skeleton ESP", CurrentValue = CONFIG.skeletonEnabled, Callback = function(v) CONFIG.skeletonEnabled = v; rebuildESP() end }))
	reg("weaponEspEnabled", esp:CreateToggle({ Name = "Weapon ESP", CurrentValue = CONFIG.weaponEspEnabled, Callback = function(v) CONFIG.weaponEspEnabled = v; rebuildESP() end }))
	reg("highlightEnabled", esp:CreateToggle({ Name = "Highlight ESP", CurrentValue = CONFIG.highlightEnabled, Callback = function(v) CONFIG.highlightEnabled = v; if v then updateHighlights() else clearHighlights() end end }))
	reg("highlightWallCheck", esp:CreateToggle({ Name = "Highlight wall check", CurrentValue = CONFIG.highlightWallCheck, Callback = function(v) CONFIG.highlightWallCheck = v; if CONFIG.highlightEnabled then updateHighlights() end end }))
	reg("teamColorEnabled", esp:CreateToggle({ Name = "Team colors", CurrentValue = CONFIG.teamColorEnabled, Callback = function(v) CONFIG.teamColorEnabled = v; rebuildESP() end }))
	esp:CreateDropdown({ Name = "Tracer origin", Values = { "Bottom", "Center", "Mouse" }, CurrentOption = CONFIG.tracerOrigin, Callback = function(v) CONFIG.tracerOrigin = v end })
	reg("maxDist", esp:CreateSlider({ Name = "Max distance", Min = 100, Max = 3000, CurrentValue = CONFIG.maxDist, Callback = function(v) CONFIG.maxDist = v end }))
	reg("textSize", esp:CreateSlider({ Name = "Text size", Min = 10, Max = 24, CurrentValue = CONFIG.textSize, Callback = function(v) CONFIG.textSize = v; rebuildESP() end }))
	reg("textOutline", esp:CreateToggle({ Name = "Text outline", CurrentValue = CONFIG.textOutline, Callback = function(v) CONFIG.textOutline = v; rebuildESP() end }))
end

-- UTILITY
do
	local tab = Window:CreateTab("utility")

	local move = tab:CreateSection("Movement")
	reg("speedEnabled", move:CreateToggle({ Name = "Speed hack", CurrentValue = CONFIG.speedEnabled, Callback = function(v) CONFIG.speedEnabled = v; if v then applySpeedJump() else local h = getHumanoid(); if h then pcall(function() h.WalkSpeed = 10 end) end end end }))
	reg("speedValue", move:CreateSlider({ Name = "Walk speed", Min = 10, Max = 200, CurrentValue = CONFIG.speedValue, Callback = function(v) CONFIG.speedValue = v; if CONFIG.speedEnabled then applySpeedJump() end end }))
	reg("jumpEnabled", move:CreateToggle({ Name = "Jump boost", CurrentValue = CONFIG.jumpEnabled, Callback = function(v) CONFIG.jumpEnabled = v; if v then applySpeedJump() else local h = getHumanoid(); if h then pcall(function() h.JumpHeight = 25 end) end end end }))
	reg("jumpValue", move:CreateSlider({ Name = "Jump height", Min = 25, Max = 200, CurrentValue = CONFIG.jumpValue, Callback = function(v) CONFIG.jumpValue = v; if CONFIG.jumpEnabled then applySpeedJump() end end }))

	local safe = tab:CreateSection("Safety")
	reg("noFallDamage", safe:CreateToggle({ Name = "No fall damage", CurrentValue = CONFIG.noFallDamage, Callback = function(v) CONFIG.noFallDamage = v; setupNoFallDamage() end }))

	local auto = tab:CreateSection("Automation")
	reg("autoReload", auto:CreateToggle({ Name = "Auto reload", CurrentValue = CONFIG.autoReload, Callback = function(v) CONFIG.autoReload = v; setupAutoReload() end }))
	reg("autoRespawn", auto:CreateToggle({ Name = "Auto respawn", CurrentValue = CONFIG.autoRespawn, Callback = function(v) CONFIG.autoRespawn = v; setupAutoRespawn() end }))
end

-- MISC
do
	local tab = Window:CreateTab("misc")

	local afk = tab:CreateSection("Anti-AFK")
	reg("antiAfk", afk:CreateToggle({ Name = "Anti-AFK", CurrentValue = CONFIG.antiAfk, Callback = function(v) CONFIG.antiAfk = v; setupAntiAfk() end }))

	local fps = tab:CreateSection("Performance")
	reg("fpsUnlocker", fps:CreateToggle({ Name = "FPS Unlocker", CurrentValue = CONFIG.fpsUnlocker, Callback = function(v) CONFIG.fpsUnlocker = v; setupFpsUnlocker() end }))

	local tp = tab:CreateSection("Teleport")
	local playerNames = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then table.insert(playerNames, p.DisplayName) end
	end
	local tpDropdown = tp:CreateDropdown({ Name = "Teleport to", Values = playerNames, Callback = function(v)
		for _, p in ipairs(Players:GetPlayers()) do
			if p.DisplayName == v and p.Character then
				local root = p.Character:FindFirstChild("HumanoidRootPart")
				local myRoot = getRootPart()
				if root and myRoot then
					myRoot.CFrame = root.CFrame * CFrame.new(0, 0, 3)
					Library.Notify({ Title = "Ivory", Content = "Teleported to " .. v, Type = "Success", Duration = 2 })
				end
				break
			end
		end
	end })
	tp:CreateButton({ Name = "Refresh Player List", Callback = function()
		local names = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then table.insert(names, p.DisplayName) end
		end
		if tpDropdown and tpDropdown.Set then pcall(function() tpDropdown:Set(names) end) end
	end })

	local srv = tab:CreateSection("Server")
	srv:CreateButton({ Name = "Rejoin Server", Callback = function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end })
	srv:CreateButton({ Name = "Server Hop", Callback = function()
		local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
		if servers and servers.data then
			for _, s in ipairs(servers.data) do
				if s.id ~= game.JobId and s.playing < s.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
					break
				end
			end
		end
	end })
end

-- SETTINGS
do
	local tab = Window:CreateTab("settings")

	CreditsLabel = tab:CreateSection("Credits"):CreateLabel({ Text = "Made by Mommy Veqxoo </3" })

	local cfg = tab:CreateSection("Config")
	configNameInput = cfg:CreateInput({ Name = "Config Name", CurrentValue = "default", PlaceholderText = "Enter config name..." })

	local function refreshConfigList()
		local names = listConfigs()
		if #names == 0 then names = { "default" } end
		if configDropdown and configDropdown.Set then pcall(function() configDropdown:Set(names) end) end
	end

	configDropdown = cfg:CreateDropdown({ Name = "Select Config", Values = listConfigs(), Callback = function(v) configNameInput:Set(v) end })

	cfg:CreateButton({ Name = "Save Config", Callback = function()
		local name = configNameInput and configNameInput.Value or "default"
		if not name or name == "" then name = "default" end
		saveConfig(name); refreshConfigList()
		Library.Notify({ Title = "Ivory", Content = "Config saved: " .. name, Type = "Success", Duration = 3 })
	end })

	cfg:CreateButton({ Name = "Load Config", Callback = function()
		local name = configNameInput and configNameInput.Value or "default"
		if not name or name == "" then name = "default" end
		if loadConfigByName(name) then
			applyConfigToUI(); rebuildESP()
			if CONFIG.highlightEnabled then updateHighlights() end
			fovCircle.Visible = CONFIG.aimEnabled
			silentFovCircle.Visible = CONFIG.silentEnabled
			applySpeedJump()
			setupNoFallDamage(); setupAutoReload(); setupAutoRespawn()
			setupAntiAfk(); setupFpsUnlocker()
			if CONFIG.silentEnabled then setupSilentAim() end
			Library.Notify({ Title = "Ivory", Content = "Config loaded: " .. name, Type = "Success", Duration = 3 })
		else
			Library.Notify({ Title = "Ivory", Content = "Config not found: " .. name, Type = "Error", Duration = 3 })
		end
	end })

	cfg:CreateButton({ Name = "Delete Config", Callback = function()
		local name = configNameInput and configNameInput.Value or "default"
		if not name or name == "" then name = "default" end
		deleteConfig(name); refreshConfigList()
		Library.Notify({ Title = "Ivory", Content = "Config deleted: " .. name, Type = "Info", Duration = 3 })
	end })

	cfg:CreateButton({ Name = "Refresh Config List", Callback = function()
		refreshConfigList()
		Library.Notify({ Title = "Ivory", Content = "Config list refreshed", Type = "Info", Duration = 2 })
	end })

	local kb = tab:CreateSection("Keybinds")
	kb:CreateKeybind({ Name = "Menu Keybind", CurrentKeybind = CONFIG.menuKey, Callback = function() end, ChangedCallback = function(k) CONFIG.menuKey = k end })

	local ul = tab:CreateSection("Unload")
	ul:CreateButton({ Name = "Unload Script", Callback = function()
		clearESP(); clearHighlights(); fovCircle:Remove(); silentFovCircle:Remove()
		if OldBulletRayCast then
			pcall(function()
				local tbl = filtergc("table", { Keys = {"BulletRayCast", "KnifeRayCast"} }, true)
				if tbl then
					tbl.BulletRayCast = OldBulletRayCast
					tbl.KnifeRayCast = OldKnifeRayCast
				end
			end)
			OldBulletRayCast = nil; OldKnifeRayCast = nil
		end
		Library.Notify({ Title = "Ivory", Content = "Script unloaded", Type = "Info", Duration = 2 })
	end })
end

--------------------------------------------------------------------------------
-- DISCORD TYPEWRITER
--------------------------------------------------------------------------------
task.spawn(function()
	task.wait(2)
	local purpleColor = Color3.fromRGB(128, 0, 255)
	local fullText = "Join Discord For Free Keys"
	local cursor = "_"
	local function styleDc()
		pcall(function()
			local inst = DiscordLabel.Instance
			local lbl = inst and inst:FindFirstChild("LabelText")
			if lbl then lbl.RichText = false; lbl.TextColor3 = purpleColor; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 26 end
		end)
	end
	while true do
		for i = 1, #fullText do pcall(function() DiscordLabel:Set(string.sub(fullText, 1, i) .. cursor); styleDc() end); task.wait(0.06) end
		pcall(function() DiscordLabel:Set(fullText); styleDc() end); task.wait(1.5)
		for i = #fullText, 0, -1 do pcall(function() DiscordLabel:Set(string.sub(fullText, 1, i) .. cursor); styleDc() end); task.wait(0.04) end
		pcall(function() DiscordLabel:Set(""); styleDc() end); task.wait(0.5)
	end
end)

--------------------------------------------------------------------------------
-- CREDITS TYPEWRITER
--------------------------------------------------------------------------------
task.spawn(function()
	task.wait(2)
	local pinkColor = Color3.fromRGB(255, 105, 180)
	local fullText = "Made by Mommy Veqxoo </3"
	local cursor = "_"
	local function styleCr()
		pcall(function()
			local inst = CreditsLabel.Instance
			local lbl = inst and inst:FindFirstChild("LabelText")
			if lbl then lbl.RichText = false; lbl.TextColor3 = pinkColor; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 22 end
		end)
	end
	while true do
		for i = 1, #fullText do pcall(function() CreditsLabel:Set(string.sub(fullText, 1, i) .. cursor); styleCr() end); task.wait(0.06) end
		pcall(function() CreditsLabel:Set(fullText); styleCr() end); task.wait(1.5)
		for i = #fullText, 0, -1 do pcall(function() CreditsLabel:Set(string.sub(fullText, 1, i) .. cursor); styleCr() end); task.wait(0.04) end
		pcall(function() CreditsLabel:Set(""); styleCr() end); task.wait(0.5)
	end
end)

Library.Notify({ Title = "Ivory", Content = "Jailbird loaded! Tabs: Combat, Visuals, Utility, Misc, Settings", Type = "Success", Duration = 4 })
