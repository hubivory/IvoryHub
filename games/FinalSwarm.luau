local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Networker = require(ReplicatedStorage.Packages.Networker)
local DataService = require(ReplicatedStorage.Packages.DataService)

local isLobby = (game.PlaceId == 99521272836282)
local isGame = (game.PlaceId == 79787558257549)

local upgradeNames = { "Damage", "Attack Speed", "Health", "Crit Chance", "Multishot", "Projectile Count", "Ricochet", "Piercing", "Lifesteal", "Movement Speed", "Luck", "XP Gain", "Regen", "Armor", "Size", "Projectile Speed", "Extra Jump", "Knockback" }

local STATE = {
	AutoUpgrade = false,

	AutoCollect = false,
	ESP = false,
	SpeedBoost = false,
	SpeedValue = 16,
	AutoDodge = false,
	DodgeRange = 15,
	DodgeSpeed = 50,
	DodgeHeight = 4,
	DodgeMode = "Fly",
	LobbyAutoChest = false,
	LobbyAutoClaim = false,
	LobbyAutoQueue = false,
	LobbyAutoDaily = false,
	AutoContinue = false,
	AutoAgain = false,
	AutoLobby = false,
	LobbyWorld = "Grasslands",
	LobbyDifficulty = "Normal",
	LobbyChallenge = "None",
	UpgradePriority = {},
	InfJump = false,
	ESPColor = Color3.fromRGB(255, 80, 80),
}
getgenv().FSH_STATE = STATE

local espCache = {}
local function ClearESP()
	for _, obj in pairs(espCache) do
		pcall(function() if obj and obj.Parent then obj:Destroy() end end)
	end
	espCache = {}
end

local function UpdateESP()
	ClearESP()
	if not STATE.ESP then return end
	pcall(function()
		local EnemyServiceClient = require(ReplicatedStorage.Shared.Services.EnemyService.EnemyServiceClient)
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local enemies = EnemyServiceClient:GetEnemiesInRadius(hrp.Position, 200)
		for _, entry in ipairs(enemies) do
			local enemy = entry[1]
			if enemy and enemy.Model and enemy.Model.PrimaryPart then
				local root = enemy.Model.PrimaryPart
				local bbg = Instance.new("BillboardGui")
				bbg.Name = "FSH_ESP"
				bbg.Adornee = root
				bbg.Size = UDim2.new(0, 120, 0, 30)
				bbg.StudsOffset = Vector3.new(0, 3, 0)
				bbg.AlwaysOnTop = true
				bbg.LightInfluence = 0
				local lbl = Instance.new("TextLabel")
				lbl.Parent = bbg
				lbl.Size = UDim2.new(1, 0, 1, 0)
				lbl.BackgroundTransparency = 0.5
				lbl.BackgroundColor3 = Color3.new(0, 0, 0)
				lbl.TextColor3 = STATE.ESPColor
				lbl.TextStrokeTransparency = 0.3
				lbl.TextScaled = true
				lbl.Font = Enum.Font.GothamBold
				lbl.Text = string.format("%s [%.0f/%.0f]", enemy.Name, enemy.Health or 0, enemy.MaxHealth or 0)
				bbg.Parent = LocalPlayer:WaitForChild("PlayerGui")
				table.insert(espCache, bbg)
			end
		end
	end)
end

local GameServiceClient = nil
local UpgradeLabel = nil
if isGame then
	GameServiceClient = require(ReplicatedStorage.Shared.Services.GameService.GameServiceClient)
	getgenv().FSH_GameServiceClient = GameServiceClient
end

if isGame then

	task.spawn(function()
		local lastClickTime = 0
		while true do
			task.wait(0.3)
			local choosing = false
			pcall(function() choosing = GameServiceClient._choosingUpgrade end)

			if choosing and (os.clock() - lastClickTime > 2) then
				task.wait(0.5)

				if STATE.AutoUpgrade then
					pcall(function()
						local frames = LocalPlayer.PlayerGui:FindFirstChild("Frames")
						if not frames then return end
						local upg = frames:FindFirstChild("Upgrades")
						if not upg or not upg.Visible then return end

						local holder = upg:FindFirstChild("Holder")
						if not holder then return end

						local cards = {}
						for _, child in ipairs(holder:GetDescendants()) do
							if child:IsA("GuiButton") and child.Visible and child.AbsoluteSize.X > 50 then
								local itemTitle = child:FindFirstChild("ItemTitle")
								local name = itemTitle and itemTitle:IsA("TextLabel") and itemTitle.Text or ""
								table.insert(cards, { button = child, name = name })
							end
						end

						if #cards == 0 then return end

						for _, card in ipairs(cards) do
							warn("[FSH] Card: '" .. card.name .. "'")
						end

						local selected = cards[1]
						local priorityList = STATE.UpgradePriority
						if type(priorityList) == "table" then
							local hasSpecific = false
							for k, v in pairs(priorityList) do
								local name = type(k) == "string" and k or v
								if v == true or type(v) ~= "boolean" then
									if name ~= "Any" and name ~= "None" then hasSpecific = true break end
								end
							end
							if hasSpecific then
								for _, card in ipairs(cards) do
									if priorityList[card.name] == true or table.find(priorityList, card.name) then
										selected = card
										break
									end
								end
							end
						end
						warn("[FSH] Picked: '" .. selected.name .. "'")

						local conns = getconnections(selected.button.MouseButton1Up)
						if #conns > 0 and conns[1].Function then
							conns[1].Function()
							STATE.LastUpgrade = selected.name
							warn("[FSH] Upgrade picked: " .. selected.name)
							pcall(function()
								if UpgradeLabel then
									UpgradeLabel:SetText("Last: " .. selected.name)
								end
							end)
						end
					end)
					lastClickTime = os.clock()
				end
			end
		end
	end)

	task.spawn(function()
		local Task = nil
		pcall(function() Task = require(ReplicatedStorage.Shared.Modules.Core.Task) end)
		if not Task then return end
		while true do
			task.wait(3)
			if Task._stopping then
				pcall(function() Task:Start() end)
			end
		end
	end)

	task.spawn(function()
		local EnemyServiceClient = nil
		pcall(function() EnemyServiceClient = require(ReplicatedStorage.Shared.Services.EnemyService.EnemyServiceClient) end)
		if not EnemyServiceClient then return end

		local CANDIDATES = 16
		local LOOKAHEAD = 5
		local ENEMY_PENALTY = 80
		local VFX_PENALTY = 120
		local SAFE_BONUS = 30
		local SMOOTH = 0.3

		local flyActive = false
		local flyY = nil
		local lastVel = Vector3.zero

		local dangerNames = { DangerArea = true, SlashZone = true, DangerAreaBox = true }
		local prevProjectilePos = {}

		local function getVFXThreats(pos, dt)
			local threats = {}
			local vfxFolder = Workspace:FindFirstChild("VFX")
			if not vfxFolder then return threats end

			for _, vfx in ipairs(vfxFolder:GetChildren()) do
				if not vfx:IsA("Model") then continue end

				if dangerNames[vfx.Name] then
					local pivot = vfx:GetPivot()
					local vfxPos = Vector3.new(pivot.Position.X, pos.Y, pivot.Position.Z)
					local scale = 1
					for _, p in ipairs(vfx:GetDescendants()) do
						if p:IsA("BasePart") then
							scale = math.max(scale, math.max(p.Size.X, p.Size.Z))
							break
						end
					end
					table.insert(threats, { pos = vfxPos, radius = scale / 2 + 5, type = "aoe" })
					continue
				end

				local pivot = vfx:GetPivot()
				local partPos = pivot.Position
				local distToMe = (Vector3.new(partPos.X, pos.Y, partPos.Z) - Vector3.new(pos.X, pos.Y, pos.Z)).Magnitude

				if distToMe > 80 then continue end

				local root = vfx.PrimaryPart
				if not root then
					for _, d in ipairs(vfx:GetDescendants()) do
						if d:IsA("BasePart") then root = d break end
					end
				end
				if not root then continue end

				local prevPos = prevProjectilePos[vfx]
				if prevPos then
					local velocity = (partPos - prevPos) / math.max(dt, 0.01)
					if velocity.Magnitude > 5 then
						local toMe = Vector3.new(pos.X, pos.Y, pos.Z) - Vector3.new(partPos.X, pos.Y, partPos.Z)
						if toMe.Magnitude > 0.1 then
							local dirToMe = toMe.Unit
							local moveDir = velocity.Unit
							local dot = dirToMe:Dot(moveDir)
							if dot > 0.3 then
								local threatRadius = math.max(root.Size.X, root.Size.Y, root.Size.Z) / 2 + 3
								local timeToHit = toMe.Magnitude / math.max(velocity.Magnitude, 1)
								local urgency = 1 / math.max(timeToHit, 0.1)
								table.insert(threats, {
									pos = Vector3.new(partPos.X, pos.Y, partPos.Z),
									radius = threatRadius + urgency * 2,
									type = "projectile",
									speed = velocity.Magnitude,
									urgency = urgency,
								})
							end
						end
					end
				end
				prevProjectilePos[vfx] = partPos
			end

			for k, v in pairs(prevProjectilePos) do
				if not k.Parent then prevProjectilePos[k] = nil end
			end

			return threats
		end

		local function getEnemies(pos, range)
			local list = {}
			local success, result = pcall(function()
				return EnemyServiceClient:GetEnemiesInRadius(pos, range)
			end)
			if success and result then
				for _, entry in ipairs(result) do
					local enemy = entry[1]
					local dist = entry[2]
					if enemy and enemy.active and dist > 0 then
						table.insert(list, { pos = enemy.Position, dist = dist })
					end
				end
			end
			return list
		end

		local WALL_PENALTY = 600
		local WALL_SAFE_DIST = 12

		local wallRayParams = RaycastParams.new()
		wallRayParams.FilterType = Enum.RaycastFilterType.Exclude

		local function checkWallInDirection(myPos, dir, char)
			wallRayParams.FilterDescendantsInstances = { char }
			for _, dist in ipairs({ 2, 4, 6, 8 }) do
				local hit = Workspace:Raycast(myPos + Vector3.new(0, 1, 0), dir * (dist + 2), wallRayParams)
				if hit then
					local wallDist = (hit.Position - myPos).Magnitude
					if wallDist < WALL_SAFE_DIST then
						return wallDist, hit.Normal
					end
				end
			end
			return nil, nil
		end

		local function scoreDirection(dir, myPos, enemies, vfxThreats, char)
			local candidatePos = myPos + dir * LOOKAHEAD
			local score = 0

			local wallDist, wallNormal = checkWallInDirection(myPos, dir, char)
			if wallDist then
				local factor = 1 - wallDist / WALL_SAFE_DIST
				score = score - WALL_PENALTY * factor
				if wallNormal then
					local dirDotNormal = dir.Unit:Dot(wallNormal.Unit)
					if dirDotNormal < -0.3 then
						score = score - WALL_PENALTY * 1.5 * math.abs(dirDotNormal)
					end
				end
			end

			local _, reverseNormal = checkWallInDirection(myPos, -dir, char)
			if reverseNormal then
				local behindDot = dir.Unit:Dot((-reverseNormal).Unit)
				if behindDot < -0.3 then
					score = score - WALL_PENALTY * 0.5 * math.abs(behindDot)
				end
			end

			for _, e in ipairs(enemies) do
				local d = (candidatePos - e.pos).Magnitude
				if d < 3 then
					score = score - ENEMY_PENALTY * 2
				elseif d < 8 then
					score = score - ENEMY_PENALTY * (1 - (d - 3) / 5)
				end
			end
			for _, v in ipairs(vfxThreats) do
				local d = (candidatePos - v.pos).Magnitude
				local penalty = VFX_PENALTY
				if v.type == "projectile" then
					penalty = penalty + (v.urgency or 0) * 40
				end
				if d < v.radius then
					score = score - penalty
				elseif d < v.radius + 4 then
					score = score - penalty * 0.4
				end
			end
			local closestEnemy = math.huge
			for _, e in ipairs(enemies) do
				local d = (myPos - e.pos).Magnitude
				if d < closestEnemy then closestEnemy = d end
			end
			if closestEnemy > 8 then
				score = score + SAFE_BONUS
			end
			return score
		end

		local lastTime = os.clock()
		while true do
			task.wait(0.03)
			local now = os.clock()
			local dt = now - lastTime
			lastTime = now
		if STATE.AutoDodge then
			pcall(function()
				local char = LocalPlayer.Character
					if not char then return end
					local hrp = char:FindFirstChild("HumanoidRootPart")
					local hum = char:FindFirstChildWhichIsA("Humanoid")
					if not hrp or not hum or hum.Health <= 0 then return end
					local choosing = false
					pcall(function() choosing = GameServiceClient._choosingUpgrade end)
					if choosing then return end

					if not flyActive then
						flyActive = true
						lastVel = Vector3.zero
						if STATE.DodgeMode == "Fly" then
							flyY = hrp.Position.Y + STATE.DodgeHeight
							hum.PlatformStand = true
						else
							flyY = hrp.Position.Y
						end
					end

					local pos = hrp.Position
					local enemies = getEnemies(pos, STATE.DodgeRange)
					local vfxThreats = getVFXThreats(pos, dt)

					local hasThreat = #enemies > 0 or #vfxThreats > 0
					if hasThreat then
						local closestDist = math.huge
						for _, e in ipairs(enemies) do
							if e.dist < closestDist then closestDist = e.dist end
						end
						for _, v in ipairs(vfxThreats) do
							local d = (pos - v.pos).Magnitude
							if d < closestDist then closestDist = d end
						end

						local bestDir = nil
						local bestScore = -math.huge
						for i = 1, CANDIDATES do
							local angle = (i / CANDIDATES) * math.pi * 2
							local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
							local score = scoreDirection(dir, pos, enemies, vfxThreats, char)
							if score > bestScore then
								bestScore = score
								bestDir = dir
							end
						end

						if bestDir then
							local speed = STATE.DodgeSpeed
							if closestDist < 10 then
								speed = speed + (10 - closestDist) * 6
							end
							local targetVel = Vector3.new(bestDir.X * speed, 0, bestDir.Z * speed)
							lastVel = lastVel:Lerp(targetVel, SMOOTH)
						end
					else
						lastVel = lastVel:Lerp(Vector3.zero, SMOOTH)
					end

					local targetPos = pos + lastVel * 0.03
					targetPos = Vector3.new(targetPos.X, flyY, targetPos.Z)
					hrp.CFrame = CFrame.new(targetPos, targetPos + Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z))
					hrp.AssemblyLinearVelocity = Vector3.zero
				end)
			else
				pcall(function()
					local char = LocalPlayer.Character
					if not char then return end
					local hum = char:FindFirstChildWhichIsA("Humanoid")
					if hum then hum.PlatformStand = false end
				end)
				flyActive = false
				flyY = nil
				lastVel = Vector3.zero
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
		if STATE.AutoCollect then
			pcall(function()
				local CollectableServiceClient = require(ReplicatedStorage.Shared.Services.CollectableService.CollectableServiceClient)
					CollectableServiceClient:Collected("collectAll")
				end)
			end
		end
	end)

	task.spawn(function()
		while true do
			UpdateESP()
			task.wait(2)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			pcall(function()
				local frames = LocalPlayer.PlayerGui:FindFirstChild("Frames")
				if not frames then return end

				local deathFrame = frames:FindFirstChild("DeathFrame")
				if deathFrame and deathFrame.Visible and STATE.AutoContinue then
					local continueBtn = deathFrame:FindFirstChild("Buttons")
					if continueBtn then
						continueBtn = continueBtn:FindFirstChild("Continue")
					end
					if continueBtn then
						GameServiceClient:Continue()
						task.wait(2)
					end
				end

				local roundEnd = frames:FindFirstChild("RoundEnd")
				if roundEnd and roundEnd.Visible then
				if STATE.AutoAgain then
					GameServiceClient:PlayAgain()
					task.wait(2)
				elseif STATE.AutoLobby then
						GameServiceClient:Continue()
						task.wait(2)
					end
				end
			end)
		end
	end)
end

if isLobby then
	local ChestServiceClient = require(ReplicatedStorage.Shared.Services.ChestService.ChestServiceClient)
	local ChestNet = ChestServiceClient._networker
	local StoreNet = Networker.client.new("Store", {})
	local QuestNet = Networker.client.new("Quests", {})
	local WorldNet = Networker.client.new("WorldSelection", {})

	task.spawn(function()
		while true do
			task.wait(3)
		if STATE.LobbyAutoChest then
			pcall(function()
				local chests = DataService.client:get({"inventory", "chests"})
					if chests then
						for chestType, count in pairs(chests) do
							if count > 0 then
								ChestNet:fire("OpenMultipleChests", chestType, count)
								task.wait(0.5)
							end
						end
					end
				end)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(5)
		if STATE.LobbyAutoDaily then
			pcall(function() StoreNet:fire("ClaimDailyBasicChest") end)
				task.wait(0.3)
				pcall(function() StoreNet:fire("ClaimDailyGroupChest") end)
				task.wait(0.3)
				pcall(function() StoreNet:fire("ClaimDailyVIPChest") end)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(5)
		if STATE.LobbyAutoClaim then
			pcall(function()
				local slots = DataService.client:get({"quests", "daily", "slots"})
					if slots then
						for i, slot in ipairs(slots) do
							if slot and not slot.claimed then
								QuestNet:fire("claimDaily", i)
								task.wait(0.3)
							end
						end
					end
				end)
			end
		end
	end)

	task.spawn(function()
		local queued = false
		local inQueue = false
		pcall(function()
			local QueueService = require(ReplicatedStorage.Shared.Services.QueueService.QueueServiceClient)
			QueueService.QueueKicked:Connect(function()
				queued = false
				inQueue = false
			end)
			QueueService.QueueJoined:Connect(function()
				inQueue = true
			end)
		end)
		while true do
			task.wait(2)
			if STATE.LobbyAutoQueue and not queued and not inQueue then
				pcall(function()
					WorldNet:fire("SetWorld", STATE.LobbyWorld)
					WorldNet:fire("SetDifficulty", STATE.LobbyDifficulty)
					WorldNet:fire("SetChallenge", STATE.LobbyChallenge)
					task.wait(0.2)
					local result = WorldNet:fetch("EnterQueue")
					if result ~= false then
						queued = true
						pcall(function()
							local QueueNet = Networker.client.new("QueueService", {})
							QueueNet:fire("PartySizeSelected", 1)
							QueueNet:fire("Created")
						end)
						warn("[FSH] Queued: " .. STATE.LobbyWorld .. " / " .. STATE.LobbyDifficulty .. " / " .. STATE.LobbyChallenge)
					end
				end)
			end
			if not STATE.LobbyAutoQueue then
				queued = false
				inQueue = false
			end
		end
	end)
end

UserInputService.JumpRequest:Connect(function()
	if STATE.InfJump then
		pcall(function()
			local char = LocalPlayer.Character
			if char then
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
end)

task.spawn(function()
	while true do
		task.wait(0.1)
		if STATE.SpeedBoost then
			pcall(function()
				local char = LocalPlayer.Character
				if char then
					local hum = char:FindFirstChildWhichIsA("Humanoid")
					if hum and hum.WalkSpeed ~= STATE.SpeedValue then
						hum.WalkSpeed = STATE.SpeedValue
					end
				end
			end)
		end
	end
end)

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"

local req = request or http_request or (syn and syn.request) or (http and http.request) or function(options)
	return { Body = game:HttpGet(options.Url) }
end

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library, ThemeManager, SaveManager

local function fetch(path)
	local res = req({ Url = repo .. path, Method = "GET" })
	if res and res.Body then
		return loadstring(res.Body)()
	end
	error("Failed to fetch " .. path)
end

pcall(function()
	Library = fetch("Library.lua")
	ThemeManager = fetch("addons/ThemeManager.lua")
	SaveManager = fetch("addons/SaveManager.lua")
end)

if not Library then
	warn("[FSH] ObsidianUltra failed to load - features running with defaults")
	return
end

local Options = Library.Options
local Toggles = Library.Toggles

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
	ShowCustomCursor = false,
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

if isLobby then
	local LobbyTab = Window:AddTab({ Name = "Lobby", Icon = "building" })
	local LSub = LobbyTab:AddSubTab("Automation", "zap")

	local LG1 = LSub:AddLeftGroupbox("Chests", "package")
	LG1:AddToggle("LobbyAutoChest", {
		Text = "Auto Open All Chests",
		Default = false,
		Callback = function(v) STATE.LobbyAutoChest = v end,
	})
	LG1:AddButton({
		Text = "Open Chests Now",
		Func = function()
			pcall(function()
				local chests = DataService.client:get({"inventory", "chests"})
				if chests then
					local ChestServiceClient = require(ReplicatedStorage.Shared.Services.ChestService.ChestServiceClient)
					local ChestNet = ChestServiceClient._networker
					for chestType, count in pairs(chests) do
						if count > 0 then
							ChestNet:fire("OpenMultipleChests", chestType, count)
							task.wait(0.5)
						end
					end
				end
			end)
			Library:Notify({ Title = "Chests", Description = "Opened all chests", Type = "Success", Time = 2 })
		end,
	})

	LG1:AddDivider()

	local LG1b = LSub:AddRightGroupbox("Rewards", "gift")
	LG1b:AddToggle("LobbyAutoDaily", {
		Text = "Auto Claim Daily Chests",
		Default = false,
		Callback = function(v) STATE.LobbyAutoDaily = v end,
	})
	LG1b:AddToggle("LobbyAutoClaim", {
		Text = "Auto Claim Quests",
		Default = false,
		Callback = function(v) STATE.LobbyAutoClaim = v end,
	})
	LG1b:AddButton({
		Text = "Claim All Now",
		Func = function()
			pcall(function()
				local StoreNet = Networker.client.new("Store", {})
				StoreNet:fire("ClaimDailyBasicChest")
				task.wait(0.3)
				StoreNet:fire("ClaimDailyGroupChest")
				task.wait(0.3)
				StoreNet:fire("ClaimDailyVIPChest")
			end)
			pcall(function()
				local QuestNet = Networker.client.new("Quests", {})
				local slots = DataService.client:get({"quests", "daily", "slots"})
				if slots then
					for i, slot in ipairs(slots) do
						if slot and not slot.claimed then
							QuestNet:fire("claimDaily", i)
							task.wait(0.3)
						end
					end
				end
			end)
			Library:Notify({ Title = "Rewards", Description = "Claimed all dailies + quests", Type = "Success", Time = 2 })
		end,
	})

	local LG3 = LSub:AddLeftGroupbox("Queue", "play")
	LG3:AddToggle("LobbyAutoQueue", {
		Text = "Auto Queue for Game",
		Default = false,
		Callback = function(v) STATE.LobbyAutoQueue = v end,
	})
	LG3:AddDropdown("LobbyWorld", {
		Text = "World",
		Default = "Grasslands",
		Values = { "Grasslands", "Desert", "Swamp", "Jungle", "Frost Forest" },
		Searchable = true,
		Callback = function(v) STATE.LobbyWorld = v end,
	})
	LG3:AddDropdown("LobbyDifficulty", {
		Text = "Difficulty",
		Default = "Normal",
		Values = { "Normal", "Hard", "Nightmare" },
		Callback = function(v) STATE.LobbyDifficulty = v end,
	})
	LG3:AddDropdown("LobbyChallenge", {
		Text = "Challenge",
		Default = "None",
		Values = { "None" },
		Callback = function(v) STATE.LobbyChallenge = v end,
	})
	LG3:AddButton({
		Text = "Queue Now",
		Func = function()
			pcall(function()
				local WorldNet = Networker.client.new("WorldSelection", {})
				WorldNet:fire("SetWorld", STATE.LobbyWorld)
				WorldNet:fire("SetDifficulty", STATE.LobbyDifficulty)
				WorldNet:fire("SetChallenge", STATE.LobbyChallenge)
				task.wait(0.2)
				WorldNet:fetch("EnterQueue")
				pcall(function()
					local QueueNet = Networker.client.new("QueueService", {})
					QueueNet:fire("PartySizeSelected", 1)
					QueueNet:fire("Created")
				end)
			end)
			Library:Notify({ Title = "Queue", Description = "Queued: " .. STATE.LobbyWorld, Type = "Info", Time = 2 })
		end,
	})
end

if isGame then
	local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
	local DefSub = CombatTab:AddSubTab("Defense", "shield")
	local DG1 = DefSub:AddLeftGroupbox("Dodge", "move")
	DG1:AddToggle("AutoDodge", {
		Text = "Auto Dodge",
		Default = false,
		Callback = function(v) STATE.AutoDodge = v end,
	}):AddKeyPicker("DodgeKeybind", {
		Default = "None",
		Text = "Dodge Toggle Key",
		Mode = "Toggle",
		SyncToggleState = true,
		NoUI = false,
	})
	DG1:AddSlider("DodgeRange", {
		Text = "Avoidance Range",
		Default = 15,
		Min = 5,
		Max = 30,
		Rounding = 0,
		Suffix = " studs",
		Callback = function(v) STATE.DodgeRange = v end,
	})
	DG1:AddSlider("DodgeSpeed", {
		Text = "Dodge Speed",
		Default = 50,
		Min = 16,
		Max = 100,
		Rounding = 0,
		Callback = function(v) STATE.DodgeSpeed = v end,
	})
	DG1:AddSlider("DodgeHeight", {
		Text = "Dodge Height",
		Default = 4,
		Min = 1,
		Max = 15,
		Rounding = 0,
		Suffix = " studs",
		Callback = function(v) STATE.DodgeHeight = v end,
	})
	DG1:AddDropdown("DodgeMode", {
		Text = "Dodge Mode",
		Values = { "Fly", "Ground" },
		Default = "Fly",
		Callback = function(v) STATE.DodgeMode = v end,
	})

	local DG2 = DefSub:AddRightGroupbox("Collect", "magnet")
	DG2:AddToggle("AutoCollect", {
		Text = "Magnet (Collect All)",
		Default = false,
		Callback = function(v) STATE.AutoCollect = v end,
	}):AddKeyPicker("CollectKeybind", {
		Default = "None",
		Text = "Collect Toggle Key",
		Mode = "Toggle",
		SyncToggleState = true,
		NoUI = false,
	})

	local UpgTab = Window:AddTab({ Name = "Upgrades", Icon = "arrow-up-circle" })
	local UpgSub = UpgTab:AddSubTab("Auto Select", "zap")
	local UG1 = UpgSub:AddLeftGroupbox("Auto Upgrade", "arrow-up-circle")
	UG1:AddToggle("AutoUpgrade", {
		Text = "Auto Pick Upgrade",
		Default = false,
		Callback = function(v) STATE.AutoUpgrade = v end,
	}):AddKeyPicker("UpgradeKeybind", {
		Default = "None",
		Text = "Upgrade Toggle Key",
		Mode = "Toggle",
		SyncToggleState = true,
		NoUI = false,
	})
	UG1:AddDivider()
	UG1:AddDropdown("UpgradePriority", {
		Text = "Priority",
		Values = { "Any", "None", "Damage", "Attack Speed", "Health", "Crit Chance", "Multishot", "Projectile Count", "Ricochet", "Piercing", "Lifesteal", "Movement Speed", "Luck", "XP Gain", "Regen", "Armor", "Size", "Projectile Speed", "Extra Jump", "Knockback" },
		Multi = true,
		Searchable = true,
		Expandable = true,
		Default = {},
		Callback = function(v) STATE.UpgradePriority = v end,
	})
	UpgradeLabel = UG1:AddLabel("Last: waiting...")
	task.spawn(function()
		local last = nil
		while true do
			task.wait(1)
			if STATE.LastUpgrade and STATE.LastUpgrade ~= last then
				last = STATE.LastUpgrade
				pcall(function() UpgradeLabel:SetText("Last: " .. last) end)
			end
		end
	end)

	local VisTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
	local VisSub = VisTab:AddSubTab("ESP", "scan")
	local VG1 = VisSub:AddLeftGroupbox("Enemy ESP", "eye")
	VG1:AddToggle("ESP", {
		Text = "Show Enemy Health",
		Default = false,
		Callback = function(v) STATE.ESP = v end,
	}):AddKeyPicker("ESPKeybind", {
		Default = "None",
		Text = "ESP Toggle Key",
		Mode = "Toggle",
		SyncToggleState = true,
		NoUI = false,
	})
	VG1:AddLabel("ESP Color"):AddColorPicker("ESPColorPicker", {
		Default = Color3.fromRGB(255, 80, 80),
		Title = "ESP Color",
		Callback = function(Value)
			STATE.ESPColor = Value
		end,
	})
	Options.ESPColorPicker:OnChanged(function()
		STATE.ESPColor = Options.ESPColorPicker.Value
	end)

	task.spawn(function()
		while true do
			UpdateESP()
			task.wait(2)
		end
	end)

	local AutoTab = Window:AddTab({ Name = "Auto", Icon = "refresh-cw" })
	local AutoSub = AutoTab:AddSubTab("Post-Game", "zap")
	local AG1 = AutoSub:AddLeftGroupbox("After Death", "skull")
	AG1:AddToggle("AutoContinue", {
		Text = "Auto Continue (Death)",
		Default = false,
		Callback = function(v) STATE.AutoContinue = v end,
	})

	local AG2 = AutoSub:AddRightGroupbox("After Round", "flag")
	AG2:AddToggle("AutoAgain", {
		Text = "Auto Play Again",
		Default = false,
		Callback = function(v) STATE.AutoAgain = v end,
	})
	AG2:AddToggle("AutoLobby", {
		Text = "Auto Back to Lobby",
		Default = false,
		Callback = function(v) STATE.AutoLobby = v end,
	})

	local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
	local PlSub = PlayerTab:AddSubTab("Movement", "move")
	local PG1 = PlSub:AddLeftGroupbox("Speed", "zap")
	PG1:AddToggle("SpeedBoost", {
		Text = "Speed Boost",
		Risky = true,
		Default = false,
		Callback = function(v) STATE.SpeedBoost = v end,
	}):AddKeyPicker("SpeedKeybind", {
		Default = "None",
		Text = "Speed Toggle Key",
		Mode = "Toggle",
		SyncToggleState = true,
		NoUI = false,
	})
	PG1:AddSlider("SpeedVal", {
		Text = "Walk Speed",
		Default = 16,
		Min = 16,
		Max = 32,
		Rounding = 0,
		Callback = function(v) STATE.SpeedValue = v end,
	})
	PG1:AddLabel("Max safe: 32")

	PG1:AddDivider()

	local PG2 = PlSub:AddRightGroupbox("Jump", "arrow-up")
	PG2:AddToggle("InfJump", {
		Text = "Infinite Jump",
		Default = false,
		Callback = function(v) STATE.InfJump = v end,
	})
end

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("FinalSwarmHub")
SaveManager:SetFolder("FinalSwarmHub")
if isGame then
	SaveManager:SetSubFolder("game")
else
	SaveManager:SetSubFolder("lobby")
end

	local SettingsTab = Window:AddTab({ Name = "UI Settings", Icon = "settings" })
local CreditGroup = SettingsTab:AddLeftGroupbox("Credits", "heart")
local CreditLabel = CreditGroup:AddLabel({ Text = "", Size = 26, DoesWrap = true })
local CreditTL = CreditLabel.TextLabel
CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
CreditTL.Font = Enum.Font.GothamBold
CreditTL.TextSize = 26

task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddButton("Test Notification", function()
	Library:Notify({
		Title = "Test Notification",
		Description = "Fired at " .. os.date("%H:%M:%S"),
		Time = 4,
	})
end)
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",
	Text = "DPI Scale",
	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)
		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(value)
		Window:SetCornerRadius(value)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Join Discord", function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 }) end)
MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)
Library.ToggleKeybind = Options.MenuKeybind

SaveManager:LoadAutoloadConfig()

Library:Notify({
	Title = "Ivory",
	Description = "v1.4 loaded successfully",
	Type = "Success",
	Time = 3,
})
