-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ═══════════════════════════════════════════════════════════════
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = tostring(math.random(100000,999999)) .. tostring(tick()):sub(-6)
local _integritySalt = 0x4A
local function _verifyIntegrity()
    if not _k or not _k.v then return false end
    if _k.i ~= (_integritySalt + #(_k.s or "")) then _k.v = false; return false end
    return true
end

local _kg = Instance.new("ScreenGui")
_kg.Name = "IvoryKey"
_kg.ResetOnSpawn = false
_kg.DisplayOrder = 9999
pcall(function() _kg.Parent = game:GetService("CoreGui") end)
if not _kg.Parent then _kg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local _mf = Instance.new("Frame", _kg)
_mf.Size = UDim2.new(0, 380, 0, 295)
_mf.Position = UDim2.new(0.5, -190, 0.5, -110)
_mf.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
_mf.BorderSizePixel = 0
Instance.new("UICorner", _mf).CornerRadius = UDim.new(0, 8)
local _stroke = Instance.new("UIStroke", _mf)
_stroke.Color = Color3.fromRGB(90, 60, 200)
_stroke.Thickness = 1.5

local _title = Instance.new("TextLabel", _mf)
_title.Size = UDim2.new(1, 0, 0, 40)
_title.BackgroundTransparency = 1
_title.Text = "Ivory Hub"
_title.TextColor3 = Color3.fromRGB(200, 170, 255)
_title.TextSize = 22
_title.Font = Enum.Font.GothamBold

local _sub = Instance.new("TextLabel", _mf)
_sub.Size = UDim2.new(1, -30, 0, 20)
_sub.Position = UDim2.new(0, 15, 0, 38)
_sub.BackgroundTransparency = 1
_sub.Text = "Enter your key to continue"
_sub.TextColor3 = Color3.fromRGB(140, 140, 150)
_sub.TextSize = 13
_sub.Font = Enum.Font.Gotham
_sub.TextXAlignment = Enum.TextXAlignment.Left

local _inp = Instance.new("TextBox", _mf)
_inp.Size = UDim2.new(1, -30, 0, 36)
_inp.Position = UDim2.new(0, 15, 0, 65)
_inp.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
_inp.BorderSizePixel = 0
_inp.TextColor3 = Color3.fromRGB(220, 220, 230)
_inp.PlaceholderText = "Paste your key here"
_inp.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
_inp.TextSize = 14
_inp.Font = Enum.Font.Code
_inp.ClearTextOnFocus = false
Instance.new("UICorner", _inp).CornerRadius = UDim.new(0, 6)

local _btn = Instance.new("TextButton", _mf)
_btn.Size = UDim2.new(1, -30, 0, 36)
_btn.Position = UDim2.new(0, 15, 0, 110)
_btn.BackgroundColor3 = Color3.fromRGB(90, 60, 200)
_btn.BorderSizePixel = 0
_btn.Text = "Verify"
_btn.TextColor3 = Color3.fromRGB(255, 255, 255)
_btn.TextSize = 15
_btn.Font = Enum.Font.GothamBold
_btn.AutoButtonColor = true
Instance.new("UICorner", _btn).CornerRadius = UDim.new(0, 6)

local _st = Instance.new("TextLabel", _mf)
_st.Size = UDim2.new(1, -30, 0, 20)
_st.Position = UDim2.new(0, 15, 0, 152)
_st.BackgroundTransparency = 1
_st.Text = ""
_st.TextColor3 = Color3.fromRGB(255, 80, 80)
_st.TextSize = 12
_st.Font = Enum.Font.Gotham

local _link = Instance.new("TextButton", _mf)
_link.Size = UDim2.new(1, -30, 0, 22)
_link.Position = UDim2.new(0, 15, 0, 188)
_link.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
_link.BorderSizePixel = 0
_link.Text = "Get Key - work.ink/2STL/Ivory"
            _link.TextColor3 = Color3.fromRGB(120, 180, 255)
_link.TextSize = 11
_link.Font = Enum.Font.GothamBold
_link.AutoButtonColor = true
Instance.new("UICorner", _link).CornerRadius = UDim.new(0, 4)
_link.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://work.ink/2STL/Ivory")
            _link.Text = "Copied!"
            _link.TextColor3 = Color3.fromRGB(80, 220, 120)
            task.wait(1.5)
_link.Text = "Get Key - work.ink/2STL/Ivory"
            _link.TextColor3 = Color3.fromRGB(120, 180, 255)
        else
            _link.Text = "work.ink/2STL/Ivory"
        end
    end)
end)

local _awaiting = true

local _savedKey = nil
local _savedExpiry = nil
pcall(function()
    if isfile("IvoryKey.txt") then
        local data = readfile("IvoryKey.txt")
        _savedKey, _savedExpiry = data:match("^(.-)\n(.-)$")
        _savedExpiry = tonumber(_savedExpiry)
    end
end)
if not _savedKey then
    pcall(function() _savedKey = getgenv()._ivoryKey end)
    pcall(function() _savedExpiry = getgenv()._ivoryExpiry end)
end

if _savedKey and _savedExpiry and os.time() * 1000 < _savedExpiry then
    _k.v = true
    _k.s = _savedKey
    _k.h = _hwid
    _k.t = os.time()
    _k.i = 0x4A + #_savedKey
    _awaiting = false
    pcall(function() _kg:Destroy() end)
end

local _discord = Instance.new("TextButton", _mf)
_discord.Size = UDim2.new(1, -30, 0, 20)
_discord.Position = UDim2.new(0, 15, 0, 188)
_discord.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
_discord.BorderSizePixel = 0
_discord.Text = "Join for dupe"
_discord.TextColor3 = Color3.fromRGB(255, 255, 255)
_discord.TextSize = 11
_discord.Font = Enum.Font.GothamBold
_discord.AutoButtonColor = true
Instance.new("UICorner", _discord).CornerRadius = UDim.new(0, 4)
_discord.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/mrQFkCJfEe")
            _discord.Text = "Copied!"
            _discord.TextColor3 = Color3.fromRGB(80, 220, 120)
            task.wait(1.5)
            _discord.Text = "Join for dupe"
            _discord.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            _discord.Text = "discord.gg/mrQFkCJfEe"
        end
    end)
end)

local _workink = Instance.new("TextButton", _mf)
_workink.Size = UDim2.new(1, -30, 0, 20)
_workink.Position = UDim2.new(0, 15, 0, 212)
_workink.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
_workink.BorderSizePixel = 0
_workink.Text = "Get Key - Work.ink"
_workink.TextColor3 = Color3.fromRGB(120, 180, 255)
_workink.TextSize = 11
_workink.Font = Enum.Font.GothamBold
_workink.AutoButtonColor = true
Instance.new("UICorner", _workink).CornerRadius = UDim.new(0, 4)
_workink.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://work.ink/2STL/Ivory")
            _workink.Text = "Copied!"
            _workink.TextColor3 = Color3.fromRGB(80, 220, 120)
            task.wait(1.5)
            _workink.Text = "Get Key - Work.ink"
            _workink.TextColor3 = Color3.fromRGB(120, 180, 255)
        else
            _workink.Text = "work.ink/2STL/Ivory"
        end
    end)
end)

local _lootlabs = Instance.new("TextButton", _mf)
_lootlabs.Size = UDim2.new(1, -30, 0, 20)
_lootlabs.Position = UDim2.new(0, 15, 0, 236)
_lootlabs.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
_lootlabs.BorderSizePixel = 0
_lootlabs.Text = "Get Key - LootLabs"
_lootlabs.TextColor3 = Color3.fromRGB(200, 130, 255)
_lootlabs.TextSize = 11
_lootlabs.Font = Enum.Font.GothamBold
_lootlabs.AutoButtonColor = true
Instance.new("UICorner", _lootlabs).CornerRadius = UDim.new(0, 4)
_lootlabs.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://loot-link.com/s?L6z5Q0nE")
            _lootlabs.Text = "Copied!"
            _lootlabs.TextColor3 = Color3.fromRGB(80, 220, 120)
            task.wait(1.5)
            _lootlabs.Text = "Get Key - LootLabs"
            _lootlabs.TextColor3 = Color3.fromRGB(200, 130, 255)
        else
            _lootlabs.Text = "loot-link.com/s?L6z5Q0nE"
        end
    end)
end)

local _lootKey = ""
pcall(function()
    _lootKey = game:HttpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/lootlabs-key.txt")
    _lootKey = _lootKey:match("^%s*(.-)%s*$")
end)

local function _doValidate(key)
    if not key or key == "" then
        _st.Text = "Please enter a key"
        _st.TextColor3 = Color3.fromRGB(255, 80, 80)
        return
    end
    _st.Text = "Verifying..."
    _st.TextColor3 = Color3.fromRGB(180, 170, 255)
    _btn.Text = "..."
    _btn.AutoButtonColor = false

    if _lootKey ~= "" and key == _lootKey then
        _k.v = true
        _k.s = key
        _k.h = _hwid
        _k.t = os.time()
        _k.i = 0x4A + #key
        pcall(function()
            getgenv()._ivoryKey = key
            getgenv()._ivoryExpiry = os.time() * 1000 + 43200000
            writefile("IvoryKey.txt", key .. "\n" .. tostring(os.time() * 1000 + 43200000))
        end)
        _st.Text = "Access granted"
        _st.TextColor3 = Color3.fromRGB(80, 220, 120)
        _btn.Text = "Loading..."
        task.wait(0.4)
        _awaiting = false
        _kg:Destroy()
        return
    end

    local ok, res = pcall(function()
        return game:HttpGet("https://work.ink/_api/v2/token/isValid/" .. key .. "?deleteToken=1", true)
    end)
    if ok and res then
        local s, data = pcall(function()
            return game:GetService("HttpService"):JSONDecode(res)
        end)
        if s and type(data) == "table" and data.valid then
            if data.info and data.info.expiresAfter then
                if os.time() * 1000 > data.info.expiresAfter then
                    _st.Text = "Key expired - get a new one"
                    _st.TextColor3 = Color3.fromRGB(255, 80, 80)
                    _btn.Text = "Verify"
                    _btn.AutoButtonColor = true
                    return
                end
            end
            _k.v = true
            _k.s = key
            _k.h = _hwid
            _k.t = os.time()
            _k.i = 0x4A + #key
            pcall(function()
                getgenv()._ivoryKey = key
                getgenv()._ivoryExpiry = data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)
                writefile("IvoryKey.txt", key .. "\n" .. tostring(data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)))
            end)
            _st.Text = "Access granted"
            _st.TextColor3 = Color3.fromRGB(80, 220, 120)
            _btn.Text = "Loading..."
            task.wait(0.4)
            _awaiting = false
            _kg:Destroy()
            return
        end
    end
    _st.Text = "Invalid key - get one at work.ink/2STL/Ivory"
    _st.TextColor3 = Color3.fromRGB(255, 80, 80)
    _btn.Text = "Verify"
    _btn.AutoButtonColor = true
end

_btn.MouseButton1Click:Connect(function() _doValidate(_inp.Text) end)
_inp.FocusLost:Connect(function(enter) if enter then _doValidate(_inp.Text) end end)

while _awaiting do task.wait(0.1) end

task.spawn(function()
    while true do
        task.wait(math.random(45, 90))
        if _k and _k.v and not _verifyIntegrity() then
            pcall(function()
                for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
                    if gui.Name == "IvoryKey" then gui:Destroy() end
                end
            end)
        end
    end
end)
-- ═══ END KEY SYSTEM ════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local Networker = require(ReplicatedStorage.Packages.Networker)
local DataService = require(ReplicatedStorage.Packages.DataService)

local isLobby = (game.PlaceId == 99521272836282)
local isGame = (game.PlaceId == 79787558257549)

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
	UpgradePriority = "Any",
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
	if not STATE.ESP or not _k or not _k.v then return end
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

				if STATE.AutoUpgrade and _k and _k.v and _k.i then
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

						local selected = cards[1]
						if STATE.UpgradePriority ~= "Any" then
							for _, card in ipairs(cards) do
								if card.name == STATE.UpgradePriority then
									selected = card
									break
								end
							end
						end

						local conns = getconnections(selected.button.MouseButton1Up)
						if #conns > 0 and conns[1].Function then
							conns[1].Function()
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
		if STATE.AutoDodge and _k and _k.v and _k.s then
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
		if STATE.AutoCollect and _k and _k.v then
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
				if deathFrame and deathFrame.Visible and STATE.AutoContinue and _k and _k.v and _k.i then
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
				if STATE.AutoAgain and _k and _k.v then
					GameServiceClient:PlayAgain()
					task.wait(2)
				elseif STATE.AutoLobby and _k and _k.v and _k.s then
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
		if STATE.LobbyAutoChest and _k and _k.v then
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
		if STATE.LobbyAutoDaily and _k and _k.v and _k.i then
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
		if STATE.LobbyAutoClaim and _k and _k.v then
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
			if STATE.LobbyAutoQueue and _k and _k.v and _k.s and not queued and not inQueue then
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
	if STATE.InfJump and _k and _k.v then
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
		if STATE.SpeedBoost and _k and _k.v and _verifyIntegrity() then
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
local Library = nil
local ThemeManager = nil
local SaveManager = nil

pcall(function()
	Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
	ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
	SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
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
	UG1:AddDropdown("UpgradePriority", {
		Text = "Priority",
		Default = "Any",
		Values = { "Any", "Damage", "Attack Speed", "Health", "Crit Chance", "Multishot", "Projectile Count", "Ricochet", "Piercing", "Lifesteal", "Movement Speed", "Luck", "XP Gain", "Regen", "Armor", "Size", "Projectile Speed", "Extra Jump", "Knockback" },
		Searchable = true,
		Expandable = true,
		ExpandColumns = 2,
		Callback = function(v) STATE.UpgradePriority = v end,
	})
	UG1:AddLabel("Clicks the matching card")

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
