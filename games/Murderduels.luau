-- ═══════════════════════════════════════════════════════════
-- IVORY HUB | MURDER DUELS
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local PINK = Color3.fromRGB(255, 105, 180)
local RED = Color3.fromRGB(255, 50, 50)
local GREEN = Color3.fromRGB(50, 255, 50)
local BLUE = Color3.fromRGB(50, 150, 255)
local YELLOW = Color3.fromRGB(255, 255, 50)
local WHITE = Color3.fromRGB(255, 255, 255)
local CYAN = Color3.fromRGB(0, 255, 255)
local PURPLE = Color3.fromRGB(170, 0, 255)
local ORANGE = Color3.fromRGB(255, 165, 0)

-- ═══════════════════════════════════════════════════════════
-- UI LIBRARY
-- ═══════════════════════════════════════════════════════════

for _, obj in ipairs(CoreGui:GetChildren()) do
	if obj.Name == "IvoryMurderDuels" then obj:Destroy() end
end

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Ivory Hub",
	NotifySide = "Right",
	ShowCustomCursor = false,
	Footer = {
		"v1.0 |",
		{ Text = "Murder Duels", Copyable = true },
		"|",
		{ Text = tostring(LocalPlayer.UserId), Copyable = true },
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	UnlockMouseWhileOpen = false,
})

local menuVisible = true

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		menuVisible = not menuVisible
		pcall(function()
			Library.MainFrame.Visible = menuVisible
		end)
	end
end)

local currentTarget = nil
RunService.RenderStepped:Connect(function()
    local closestTarget = nil
    local shortestDistance = (Options.SilentAimFOV and Options.SilentAimFOV.Value) or 650
    local mousePos = UserInputService:GetMouseLocation()
    local charsFolder = Workspace:FindFirstChild("Characters")
    local characters = charsFolder and charsFolder:GetChildren() or Workspace:GetChildren()
    for _, char in ipairs(characters) do
        if char:IsA("Model") and char ~= LocalPlayer.Character then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local mySide = LocalPlayer:GetAttribute("MatchSide")
                local theirSide = char:GetAttribute("MatchSide")
                if mySide and theirSide and mySide == theirSide then
                    if char:GetAttribute("BotMatchBot") ~= true and char:GetAttribute("Decoy") ~= true then
                        continue
                    end
                end
                local aimPart
                if Toggles.SilentAimRandomPart and Toggles.SilentAimRandomPart.Value then
                    local headPct = Options.SilentAimHeadPercent and Options.SilentAimHeadPercent.Value or 25
                    local rootPct = Options.SilentAimRootPercent and Options.SilentAimRootPercent.Value or 25
                    local upperPct = Options.SilentAimUpperPercent and Options.SilentAimUpperPercent.Value or 25
                    local lowerPct = Options.SilentAimLowerPercent and Options.SilentAimLowerPercent.Value or 25
                    local roll = math.random(1, 100)
                    if roll <= headPct then
                        aimPart = char:FindFirstChild("Head")
                    elseif roll <= headPct + rootPct then
                        aimPart = char:FindFirstChild("HumanoidRootPart")
                    elseif roll <= headPct + rootPct + upperPct then
                        aimPart = char:FindFirstChild("UpperTorso")
                    else
                        aimPart = char:FindFirstChild("LowerTorso")
                    end
                    aimPart = aimPart or char:FindFirstChild("HumanoidRootPart")
                else
                    aimPart = char:FindFirstChild(Options.SilentAimPart and Options.SilentAimPart.Value or "Head") or char:FindFirstChild("HumanoidRootPart")
                end
                if aimPart then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestTarget = aimPart
                        end
                    end
                end
            end
        end
    end
    currentTarget = closestTarget
end)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() and currentTarget then
        if method == "FireServer" then
            if self.Name == "ThrowReplicate" and type(args[1]) == "table" then
                args[1].target = currentTarget.Position
                return oldNamecall(self, unpack(args))
            elseif self.Name == "ShootReplicate" and type(args[1]) == "table" then
                args[1].hitInstance = currentTarget
                args[1].hitPos = currentTarget.Position
                args[1].to = currentTarget.Position
                args[1].isCharacterHit = true
                if args[1].segments and type(args[1].segments) == "table" and #args[1].segments > 0 then
                    local lastSegment = args[1].segments[#args[1].segments]
                    lastSegment.hitInstance = currentTarget
                    lastSegment.hitPos = currentTarget.Position
                    lastSegment.isCharacterHit = true
                end
                return oldNamecall(self, unpack(args))
            end
        elseif method == "Fire" then
            if self.Name == "SpawnKnife" and type(args[1]) == "table" then
                args[1].target = currentTarget.Position
                return oldNamecall(self, unpack(args))
            elseif self.Name == "SpawnBullet" and type(args[1]) == "table" then
                args[1].hitInstance = currentTarget
                args[1].hitPos = currentTarget.Position
                args[1].to = currentTarget.Position
                args[1].isCharacterHit = true
                if args[1].segments and type(args[1].segments) == "table" and #args[1].segments > 0 then
                    local lastSegment = args[1].segments[#args[1].segments]
                    lastSegment.hitInstance = currentTarget
                    lastSegment.hitPos = currentTarget.Position
                    lastSegment.isCharacterHit = true
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

local Tabs = {
	Aimbot = Window:AddTab({ Name = "Aimbot", Icon = "crosshair", Description = "Aimbot & Silent Aim" }),
	Visuals = Window:AddTab({ Name = "Visuals", Icon = "eye", Description = "ESP, Highlights, Health" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "UI settings" }),
}

-- ═══════════════════════════════════════════════════════════
-- GAME REFERENCES
-- ═══════════════════════════════════════════════════════════

local CharactersFolder = workspace:WaitForChild("Characters", 5)

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════

local espObjects = {}
local highlights = {}
local connections = {}
local aimbotHeld = false

local function GetCharacter()
	return LocalPlayer.Character
end

local function GetHRP()
	local char = GetCharacter()
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local char = GetCharacter()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetEnemyCharacters()
	local enemies = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local hum = player.Character:FindFirstChildOfClass("Humanoid")
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				table.insert(enemies, {Player = player, Character = player.Character, Humanoid = hum, HRP = hrp})
			end
		end
	end
	return enemies
end

local function WorldToScreen(pos)
	local vec, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function GetTeamColor(player)
	if not player.Team then return WHITE end
	local tc = player.Team.TeamColor
	if tc == BrickColor.new("Bright blue") then return BLUE end
	if tc == BrickColor.new("Bright red") then return RED end
	if tc == BrickColor.new("Bright green") then return GREEN end
	return WHITE
end

-- ═══════════════════════════════════════════════════════════
-- AIMBOT LOGIC (defined BEFORE GetAimTarget)
-- ═══════════════════════════════════════════════════════════

local adsHeld = false
local stickyTarget = nil

local function IsAimbotActive()
	local enabled = Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value
	if not enabled then return false end

	local rightClick = Toggles.RightClickAim and Toggles.RightClickAim.Value
	local leftClick = Toggles.LeftClickAim and Toggles.LeftClickAim.Value
	if rightClick and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		return true
	end
	if leftClick and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		return true
	end

	return aimbotHeld
end

local function IsSilentAimActive()
	return Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value
end

local function GetMaxDistance()
	return Options.MaxDistance and Options.MaxDistance.Value or 500
end

local function IsTargetValid(target)
	if not target then return false end
	if not target.Character then return false end
	local hum = target.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then return false end
	local hrp = target.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local myHRP = GetHRP()
	if myHRP and (myHRP.Position - hrp.Position).Magnitude > GetMaxDistance() then return false end
	return true
end

local function GetClosestTarget(fovOverride)
	local myHRP = GetHRP()
	if not myHRP then return nil end

	local fov = fovOverride or 120
	local targetPart = Options.AimbotTarget and Options.AimbotTarget.Value or "Head"
	local teamCheck = Toggles.AimbotTeamCheck and Toggles.AimbotTeamCheck.Value
	local aliveCheck = Toggles.AimbotAliveCheck and Toggles.AimbotAliveCheck.Value
	local maxDist = GetMaxDistance()
	local sortBy = Options.AimSort and Options.AimSort.Value or "Crosshair"
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	local closest = nil
	local closestScore = math.huge

	for _, enemy in ipairs(GetEnemyCharacters()) do
		if teamCheck and enemy.Player.Team == LocalPlayer.Team then continue end
		if aliveCheck and enemy.Humanoid.Health <= 0 then continue end

		local worldDist = (myHRP.Position - enemy.HRP.Position).Magnitude
		if worldDist > maxDist then continue end

		local target = enemy.Character:FindFirstChild(targetPart) or enemy.HRP
		local screenPos, onScreen = WorldToScreen(target.Position)
		if not onScreen then continue end

		local score
		if sortBy == "Distance" then
			score = worldDist
		else
			score = (screenPos - center).Magnitude
		end

		if score < closestScore and score < fov then
			closestScore = score
			closest = enemy
		end
	end
	return closest
end

local function IsCrosshairOnTarget(target)
	if not target then return false end
	local targetPart = Options.AimbotTarget and Options.AimbotTarget.Value or "Head"
	local part = target.Character:FindFirstChild(targetPart) or target.HRP
	if not part then return false end

	local screenPos, onScreen = WorldToScreen(part.Position)
	if not onScreen then return false end

	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local dist = (screenPos - center).Magnitude
	return dist < 40
end

local function GetSilentAimTarget()
	if not IsSilentAimActive() then return nil end
	local myHRP = GetHRP()
	if not myHRP then return nil end

	local fov = Options.SilentAimFOV and Options.SilentAimFOV.Value or 150
	local targetPart = Options.AimbotTarget and Options.AimbotTarget.Value or "Head"
	local teamCheck = Toggles.SilentAimTeamCheck and Toggles.SilentAimTeamCheck.Value
	local aliveCheck = Toggles.SilentAimAliveCheck and Toggles.SilentAimAliveCheck.Value
	local wallCheck = Toggles.SilentAimWallCheck and Toggles.SilentAimWallCheck.Value
	local maxDist = GetMaxDistance()
	local sortBy = Options.AimSort and Options.AimSort.Value or "Crosshair"
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	local closest = nil
	local closestScore = math.huge

	for _, enemy in ipairs(GetEnemyCharacters()) do
		if teamCheck and enemy.Player.Team == LocalPlayer.Team then continue end
		if aliveCheck and enemy.Humanoid.Health <= 0 then continue end

		local worldDist = (myHRP.Position - enemy.HRP.Position).Magnitude
		if worldDist > maxDist then continue end

		local target = enemy.Character:FindFirstChild(targetPart) or enemy.HRP
		local screenPos, onScreen = WorldToScreen(target.Position)
		if not onScreen then continue end

		if wallCheck then
			local rayOrigin = Camera.CFrame.Position
			local rayDir = (target.Position - rayOrigin).Unit * worldDist
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = {LocalPlayer.Character, enemy.Character}
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local result = Workspace:Raycast(rayOrigin, rayDir, rayParams)
			if result and not result.Instance:IsDescendantOf(enemy.Character) then
				continue
			end
		end

		local score
		if sortBy == "Distance" then
			score = worldDist
		else
			score = (screenPos - center).Magnitude
		end

		if score < closestScore and score < fov then
			closestScore = score
			closest = enemy
		end
	end
	return closest
end

local function GetAimTarget()
	if not IsAimbotActive() and not IsSilentAimActive() then
		stickyTarget = nil
		return nil
	end

	local stickyEnabled = Toggles.StickyAim and Toggles.StickyAim.Value
	if stickyEnabled and stickyTarget and IsTargetValid(stickyTarget) then
		return stickyTarget
	end

	stickyTarget = nil
	local fov = Options.AimbotFOV and Options.AimbotFOV.Value or 120
	local newTarget = GetClosestTarget(fov)
	if newTarget and stickyEnabled then
		stickyTarget = newTarget
	end
	return newTarget
end

local function AimAtTarget(target)
	if not target then return end
	local targetPart = Options.AimbotTarget and Options.AimbotTarget.Value or "Head"
	local part = target.Character:FindFirstChild(targetPart) or target.HRP
	if not part then return end

	local screenPos, onScreen = WorldToScreen(part.Position)
	if not onScreen then return end
	local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local delta = screenPos - center
	local smoothing = Options.AimbotSmoothing and Options.AimbotSmoothing.Value or 5
	local scale = math.clamp(1 - (smoothing - 1) / 29, 0.03, 1)
	local dx = math.clamp(delta.X * scale, -500, 500)
	local dy = math.clamp(delta.Y * scale, -500, 500)
	if math.abs(dx) > 0.5 or math.abs(dy) > 0.5 then
		mousemoverel(dx, dy)
	end
end

-- ═══════════════════════════════════════════════════════════
-- AIMBOT TAB
-- ═══════════════════════════════════════════════════════════

local AimbotGroup = Tabs.Aimbot:AddLeftGroupbox("Aimbot")
local SilentAimGroup = Tabs.Aimbot:AddRightGroupbox("Silent Aim")

AimbotGroup:AddToggle("AimbotEnabled", {
	Text = "Enable Aimbot",
	Default = false,
	Tooltip = "Locks mouse to closest enemy",
})

AimbotGroup:AddDropdown("AimSort", {
	Text = "Target Sort",
	Values = {"Crosshair", "Distance"},
	Default = "Crosshair",
	Tooltip = "Crosshair = nearest to screen center | Distance = nearest in world",
})

AimbotGroup:AddLabel("Aim Key"):AddKeyPicker("AimKey", {
	Default = "E",
	NoUI = false,
	Text = "Aim Keybind",
})

AimbotGroup:AddToggle("RightClickAim", {
	Text = "Right Click Aim",
	Default = false,
	Tooltip = "Also aim when holding right mouse button (ADS)",
})

AimbotGroup:AddToggle("LeftClickAim", {
	Text = "Left Click Aim",
	Default = false,
	Tooltip = "Also aim when holding left mouse button",
})

AimbotGroup:AddToggle("AimbotFOVEnabled", {
	Text = "Show FOV",
	Default = false,
	Tooltip = "Shows aimbot FOV circle",
})

AimbotGroup:AddSlider("AimbotFOV", {
	Text = "FOV Size",
	Default = 120,
	Min = 30,
	Max = 500,
	Rounding = 0,
})

AimbotGroup:AddSlider("AimbotSmoothing", {
	Text = "Smoothing",
	Default = 5,
	Min = 1,
	Max = 30,
	Rounding = 0,
	Tooltip = "Lower = snappier, higher = smoother",
})

AimbotGroup:AddDropdown("AimbotTarget", {
	Text = "Target Part",
	Values = {"HumanoidRootPart", "Head", "UpperTorso"},
	Default = "Head",
})

AimbotGroup:AddToggle("AimbotTeamCheck", {
	Text = "Team Check",
	Default = true,
})

AimbotGroup:AddToggle("AimbotAliveCheck", {
	Text = "Alive Check",
	Default = true,
})

AimbotGroup:AddToggle("StickyAim", {
	Text = "Sticky Aim",
	Default = true,
	Tooltip = "Keeps locked on same target until they die or you release key",
})

AimbotGroup:AddSlider("MaxDistance", {
	Text = "Max Distance",
	Default = 500,
	Min = 10,
	Max = 2000,
	Rounding = 0,
	Tooltip = "Max world distance for aimbot + ESP",
})

-- Silent Aim
SilentAimGroup:AddToggle("SilentAimEnabled", {
	Text = "Enable Silent Aim",
	Default = false,
	Tooltip = "Snaps to target when shooting",
})

SilentAimGroup:AddSlider("SilentAimFOV", {
	Text = "FOV Size",
	Default = 150,
	Min = 30,
	Max = 500,
	Rounding = 0,
})

SilentAimGroup:AddToggle("SilentAimFOVEnabled", {
	Text = "Show FOV",
	Default = false,
	Tooltip = "Shows silent aim FOV circle",
})

SilentAimGroup:AddDropdown("SilentAimPart", {
	Text = "Target Part",
	Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
	Default = "Head",
})

SilentAimGroup:AddToggle("SilentAimRandomPart", {
	Text = "Random Part",
	Default = false,
	Tooltip = "Randomly picks a body part each shot based on % below",
})

SilentAimGroup:AddSlider("SilentAimHeadPercent", {
	Text = "Head %",
	Default = 20,
	Min = 0,
	Max = 100,
	Rounding = 0,
})

SilentAimGroup:AddSlider("SilentAimRootPercent", {
	Text = "Root %",
	Default = 30,
	Min = 0,
	Max = 100,
	Rounding = 0,
})

SilentAimGroup:AddSlider("SilentAimUpperPercent", {
	Text = "UpperTorso %",
	Default = 30,
	Min = 0,
	Max = 100,
	Rounding = 0,
})

SilentAimGroup:AddSlider("SilentAimLowerPercent", {
	Text = "LowerTorso %",
	Default = 20,
	Min = 0,
	Max = 100,
	Rounding = 0,
})

SilentAimGroup:AddToggle("SilentAimTeamCheck", {
	Text = "Team Check",
	Default = true,
})

SilentAimGroup:AddToggle("SilentAimAliveCheck", {
	Text = "Alive Check",
	Default = true,
})

SilentAimGroup:AddToggle("SilentAimWallCheck", {
	Text = "Wall Check",
	Default = true,
	Tooltip = "Won't shoot through walls",
})

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = false
fovCircle.Thickness = 1.5
fovCircle.Color = PINK
fovCircle.Filled = false
fovCircle.Transparency = 0.8

local silentAimFOVCircle = Drawing.new("Circle")
silentAimFOVCircle.Visible = false
silentAimFOVCircle.Thickness = 1.5
silentAimFOVCircle.Color = Color3.fromRGB(255, 165, 0)
silentAimFOVCircle.Filled = false
silentAimFOVCircle.Transparency = 0.8

local function UpdateFOV()
	local enabled = Toggles.AimbotFOVEnabled and Toggles.AimbotFOVEnabled.Value
	local size = Options.AimbotFOV and Options.AimbotFOV.Value or 120
	if enabled then
		fovCircle.Radius = size
		fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		fovCircle.Visible = true
	else
		fovCircle.Visible = false
	end
end

local function UpdateSilentAimFOV()
	local enabled = Toggles.SilentAimFOVEnabled and Toggles.SilentAimFOVEnabled.Value
	local size = Options.SilentAimFOV and Options.SilentAimFOV.Value or 150
	if enabled then
		silentAimFOVCircle.Radius = size
		silentAimFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		silentAimFOVCircle.Visible = true
	else
		silentAimFOVCircle.Visible = false
	end
end

-- Aim Key Input
local function MatchesAimKey(input)
	local aimKeyValue = Options.AimKey and Options.AimKey.Value
	if not aimKeyValue or aimKeyValue == "None" then return false end
	if input.KeyCode and input.KeyCode.Name == aimKeyValue then return true end
	if input.UserInputType then
		local typeName = input.UserInputType.Name
		if typeName == aimKeyValue then return true end
		if aimKeyValue == "MouseButton1" and typeName == "MouseButton1" then return true end
		if aimKeyValue == "MouseButton2" and typeName == "MouseButton2" then return true end
		if aimKeyValue == "MouseButton3" and typeName == "MouseButton3" then return true end
	end
	return false
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if MatchesAimKey(input) then
		aimbotHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
	if MatchesAimKey(input) then
		aimbotHeld = false
	end
end)

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════════════════════

local BoxESPGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP")
local HighlightGroup = Tabs.Visuals:AddRightGroupbox("Highlights")

-- Box ESP
BoxESPGroup:AddToggle("BoxESP", {
	Text = "Enable Box ESP",
	Default = false,
})

BoxESPGroup:AddToggle("NameESP", {
	Text = "Show Names",
	Default = false,
})

BoxESPGroup:AddToggle("DistanceESP", {
	Text = "Show Distance",
	Default = false,
})

BoxESPGroup:AddToggle("TeamColorESP", {
	Text = "Team Color",
	Default = true,
})

BoxESPGroup:AddToggle("BoxESPFilled", {
	Text = "Filled Boxes",
	Default = false,
})

BoxESPGroup:AddSlider("BoxESPTransparency", {
	Text = "Transparency",
	Default = 3,
	Min = 1,
	Max = 10,
	Rounding = 0,
})

-- Highlight / Chams
HighlightGroup:AddToggle("HighlightEnabled", {
	Text = "Enable Highlights",
	Default = false,
	Tooltip = "Draws chams on enemies through walls",
})

HighlightGroup:AddToggle("HighlightFillColorPick", {
	Text = "Fill Color",
	Default = false,
}):AddColorPicker("HighlightFillColor", {
	Default = PURPLE,
})

HighlightGroup:AddToggle("HighlightOutlineColorPick", {
	Text = "Outline Color",
	Default = false,
}):AddColorPicker("HighlightOutlineColor", {
	Default = WHITE,
})

HighlightGroup:AddSlider("HighlightFillTrans", {
	Text = "Fill Transparency",
	Default = 5,
	Min = 1,
	Max = 10,
	Rounding = 0,
})

HighlightGroup:AddSlider("HighlightOutlineTrans", {
	Text = "Outline Transparency",
	Default = 1,
	Min = 1,
	Max = 10,
	Rounding = 0,
})

HighlightGroup:AddDropdown("HighlightDepth", {
	Text = "Depth Mode",
	Values = {"AlwaysOnTop", "Occluded"},
	Default = "AlwaysOnTop",
})

-- ESP Drawing
local function CreateESPObjects()
	return {
		BoxOutline = Drawing.new("Square"),
		Box = Drawing.new("Square"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
	}
end

local function DestroyESPObjects(objs)
	for _, v in pairs(objs) do v:Remove() end
end

local function UpdatePlayerESP()
	local espEnabled = Toggles.BoxESP and Toggles.BoxESP.Value
	local nameESP = Toggles.NameESP and Toggles.NameESP.Value
	local distESP = Toggles.DistanceESP and Toggles.DistanceESP.Value
	local teamColor = Toggles.TeamColorESP and Toggles.TeamColorESP.Value
	local filled = Toggles.BoxESPFilled and Toggles.BoxESPFilled.Value
	local transparencyVal = Options.BoxESPTransparency and Options.BoxESPTransparency.Value or 3
	local trans = math.clamp(transparencyVal / 10, 0.1, 1)
	local maxDist = GetMaxDistance()
	local myHRP = GetHRP()

	for _, enemy in ipairs(GetEnemyCharacters()) do
		local key = enemy.Player.UserId

		if myHRP then
			local worldDist = (myHRP.Position - enemy.HRP.Position).Magnitude
			if worldDist > maxDist then
				if espObjects[key] then
					DestroyESPObjects(espObjects[key])
					espObjects[key] = nil
				end
				continue
			end
		end

		if not espObjects[key] then
			espObjects[key] = CreateESPObjects()
		end
		local objs = espObjects[key]
		local hrp = enemy.HRP
		local rootPos = hrp.Position
		local screenPos, onScreen = WorldToScreen(rootPos)

		if espEnabled and onScreen then
			local color = teamColor and GetTeamColor(enemy.Player) or PINK
			local topPos, topOnScreen = WorldToScreen(rootPos + Vector3.new(0, 3, 0))
			local bottomPos, bottomOnScreen = WorldToScreen(rootPos - Vector3.new(0, 3.5, 0))

			if topOnScreen and bottomOnScreen then
				local height = math.abs(topPos.Y - bottomPos.Y)
				local width = height * 0.6
				local x = screenPos.X
				local y = topPos.Y

				objs.BoxOutline.Size = Vector2.new(width + 2, height + 2)
				objs.BoxOutline.Position = Vector2.new(x - width / 2 - 1, y - 1)
				objs.BoxOutline.Color = Color3.new(0, 0, 0)
				objs.BoxOutline.Thickness = 3
				objs.BoxOutline.Filled = false
				objs.BoxOutline.Transparency = 1
				objs.BoxOutline.Visible = true

				objs.Box.Size = Vector2.new(width, height)
				objs.Box.Position = Vector2.new(x - width / 2, y)
				objs.Box.Color = color
				objs.Box.Thickness = 1.5
				objs.Box.Filled = filled
				objs.Box.Transparency = filled and trans or 1
				objs.Box.Visible = true

				if nameESP then
					objs.Name.Text = enemy.Player.DisplayName
					objs.Name.Position = Vector2.new(x, y - 18)
					objs.Name.Color = WHITE
					objs.Name.Size = 14
					objs.Name.Center = true
					objs.Name.Outline = true
					objs.Name.OutlineColor = Color3.new(0, 0, 0)
					objs.Name.Font = 2
					objs.Name.Visible = true
				else
					objs.Name.Visible = false
				end

				if distESP then
					local myHRP = GetHRP()
					if myHRP then
						local dist = math.floor((myHRP.Position - rootPos).Magnitude)
						objs.Distance.Text = dist .. "m"
						objs.Distance.Position = Vector2.new(x, y + height + 2)
						objs.Distance.Color = WHITE
						objs.Distance.Size = 12
						objs.Distance.Center = true
						objs.Distance.Outline = true
						objs.Distance.OutlineColor = Color3.new(0, 0, 0)
						objs.Distance.Font = 2
						objs.Distance.Visible = true
					end
				else
					objs.Distance.Visible = false
				end
			else
				objs.BoxOutline.Visible = false
				objs.Box.Visible = false
				objs.Name.Visible = false
				objs.Distance.Visible = false
			end
		else
			objs.BoxOutline.Visible = false
			objs.Box.Visible = false
			objs.Name.Visible = false
			objs.Distance.Visible = false
		end
	end

	for key, objs in pairs(espObjects) do
		local found = false
		for _, p in ipairs(Players:GetPlayers()) do
			if p.UserId == key and p.Character then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					found = true
				end
			end
		end
		if not found then
			DestroyESPObjects(objs)
			espObjects[key] = nil
		end
	end
end

local function AddHighlight(model, key)
	if highlights[key] then return end
	if not model then return end
	local hl = Instance.new("Highlight")
	hl.Name = "IvoryHighlight"
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = CoreGui
	highlights[key] = hl
end

local function UpdateHighlights()
	local enabled = Toggles.HighlightEnabled and Toggles.HighlightEnabled.Value
	local fillCol = Options.HighlightFillColor and Options.HighlightFillColor.Value or PURPLE
	local outlineCol = Options.HighlightOutlineColor and Options.HighlightOutlineColor.Value or WHITE
	local fillTrans = Options.HighlightFillTrans and (Options.HighlightFillTrans.Value / 10) or 0.5
	local outlineTrans = Options.HighlightOutlineTrans and (Options.HighlightOutlineTrans.Value / 10) or 0
	local depth = Options.HighlightDepth and Options.HighlightDepth.Value or "AlwaysOnTop"
	local depthMode = depth == "AlwaysOnTop" and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	local maxDist = GetMaxDistance()
	local myHRP = GetHRP()

	local activeNames = {}

	if enabled then
		for _, enemy in ipairs(GetEnemyCharacters()) do
			local key = "enemy_" .. enemy.Player.UserId

			if myHRP then
				local worldDist = (myHRP.Position - enemy.HRP.Position).Magnitude
				if worldDist > maxDist then
					if highlights[key] then
						pcall(function() highlights[key]:Destroy() end)
						highlights[key] = nil
					end
					continue
				end
			end

			activeNames[key] = true

			if not highlights[key] or not highlights[key].Parent then
				AddHighlight(enemy.Character, key)
			end

			if highlights[key] then
				highlights[key].FillColor = fillCol
				highlights[key].OutlineColor = outlineCol
				highlights[key].FillTransparency = fillTrans
				highlights[key].OutlineTransparency = outlineTrans
				highlights[key].DepthMode = depthMode
				highlights[key].Adornee = enemy.Character
			end
		end
	end

	for key, hl in pairs(highlights) do
		local userId = tonumber(key:match("enemy_(%d+)"))
		local alive = false
		if userId then
			local p = Players:GetPlayerByUserId(userId)
			if p and p.Character then
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hum and hum.Health > 0 then
					alive = true
				end
			end
		end
		if not alive then
			pcall(function() hl:Destroy() end)
			highlights[key] = nil
		end
	end
end

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Menu")
local CreditsGroup = Tabs.Settings:AddRightGroupbox("Credits")

SettingsGroup:AddButton({
	Text = "Copy Discord Link",
	Func = function()
		if setclipboard then
			setclipboard("https://discord.gg/ivory")
			Library:Notify("Discord link copied!", 3)
		end
	end,
	Tooltip = "Join for dupe",
})

SettingsGroup:AddButton({
	Text = "Destroy UI",
	Func = function()
		for _, conn in pairs(connections) do
			if conn.Connected then conn:Disconnect() end
		end
		fovCircle:Remove()
		silentAimFOVCircle:Remove()
		for _, objs in pairs(espObjects) do
			for _, v in pairs(objs) do v:Remove() end
		end
		for _, hl in pairs(highlights) do
			pcall(function() hl:Destroy() end)
		end
		for key, size in pairs(originalSizes) do
			for _, player in ipairs(Players:GetPlayers()) do
				if player.UserId == key and player.Character then
					local hrp = player.Character:FindFirstChild("HumanoidRootPart")
					if hrp then hrp.Size = size; hrp.Transparency = 1 end
				end
			end
		end
		pcall(function() Library:Unload() end)
	end,
	Tooltip = "Closes the menu",
})

SettingsGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = false,
	Text = "Menu Toggle Key",
})

CreditsGroup:AddLabel('<font size="18" color="#FF69B4"><b>Made by Mommy Veqxoo &lt; / 3</b></font>', true)
CreditsGroup:AddLabel("Ivory Hub v1.0 | Murder Duels")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════════
-- FOV number input at bottom of groupbox
local function AddFOVInput(groupbox, sliderOption)
	local container = groupbox.Container
	local inputFrame = Instance.new("Frame")
	inputFrame.Size = UDim2.new(1, 0, 0, 26)
	inputFrame.BackgroundTransparency = 1
	inputFrame.Parent = container

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = inputFrame

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 22)
	box.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	box.BorderSizePixel = 0
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.PlaceholderText = "Type FOV number..."
	box.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
	box.TextSize = 12
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.Text = ""
	box.Parent = inputFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = box

	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num then
			num = math.clamp(num, sliderOption.Min or 1, sliderOption.Max or 500)
			sliderOption:SetValue(num)
		end
		box.Text = ""
	end)

	sliderOption:OnChanged(function(val)
		box.PlaceholderText = "Current: " .. tostring(val) .. " | Type new value..."
	end)
end

pcall(function()
	AddFOVInput(AimbotGroup, Options.AimbotFOV)
end)
pcall(function()
	AddFOVInput(SilentAimGroup, Options.SilentAimFOV)
end)

-- ═══════════════════════════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════════════════════════

connections.mainLoop = RunService.RenderStepped:Connect(function(dt)
	Camera = workspace.CurrentCamera

	adsHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

	pcall(UpdateFOV)
	pcall(UpdateSilentAimFOV)

	local aimTarget = GetAimTarget()

	-- Aimbot (Camera or Mouse mode via dropdown)
	if aimTarget and IsAimbotActive() then
		pcall(AimAtTarget, aimTarget)
	end

	-- Silent aim handled by __namecall hook + RenderStepped target loop above

	pcall(UpdatePlayerESP)
	pcall(UpdateHighlights)

	pcall(function()
		Library.MainFrame.Visible = menuVisible
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	if espObjects[player.UserId] then
		DestroyESPObjects(espObjects[player.UserId])
		espObjects[player.UserId] = nil
	end
	if highlights[player.UserId] then
		pcall(function() highlights[player.UserId]:Destroy() end)
		highlights[player.UserId] = nil
	end
end)

Library:Notify("Ivory Hub loaded! Press RightShift to toggle menu.", 5)
