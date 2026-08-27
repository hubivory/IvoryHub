-- ═══════════════════════════════════════════════════════════
-- IVORY HUB | HYPERSHOT
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
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

-- ═══════════════════════════════════════════════════════════
-- UI LIBRARY
-- ═══════════════════════════════════════════════════════════

for _, obj in ipairs(CoreGui:GetChildren()) do
	if obj.Name == "IvoryHypershot" then obj:Destroy() end
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
	ShowCustomCursor = true,
	Footer = {
		"v1.0 |",
		{ Text = "Hypershot", Copyable = true },
		"|",
		{ Text = tostring(LocalPlayer.UserId), Copyable = true },
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
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

local Tabs = {
	Aimbot = Window:AddTab({ Name = "Aimbot", Icon = "crosshair", Description = "Aimbot & Triggerbot" }),
	Visuals = Window:AddTab({ Name = "Visuals", Icon = "eye", Description = "ESP, Chams, FOV" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "UI settings" }),
}

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════

local MobsFolder = workspace:WaitForChild("Mobs", 5)

local function HasToggle(name)
	return Toggles[name] ~= nil
end

local function ToggleOn(name)
	return HasToggle(name) and Toggles[name].Value
end

local function GetLocalChar()
	return LocalPlayer and LocalPlayer.Character
end

local function GetLocalRoot()
	local c = GetLocalChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetLocalHumanoid()
	local c = GetLocalChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(model)
	if not model then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function IsOnTeam(target)
	if not LocalPlayer.Team then return false end
	if target.IsPlayer and target.Player then
		return target.Player.Team and target.Player.Team == LocalPlayer.Team
	end
	return false
end

local function IsBot(model)
	return model and model:IsDescendantOf(MobsFolder)
end

local function GetAllTargets()
	local targets = {}

	-- Real players
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			table.insert(targets, { Model = player.Character, Name = player.Name, DisplayName = player.DisplayName, IsPlayer = true, Player = player })
		end
	end

	-- Bots
	if MobsFolder and ToggleOn("IncludeBots") then
		for _, bot in ipairs(MobsFolder:GetChildren()) do
			if bot:IsA("Model") and IsAlive(bot) then
				local cleanName = bot.Name:gsub("__Bot$", "")
				table.insert(targets, { Model = bot, Name = cleanName, DisplayName = cleanName, IsPlayer = false, Player = nil })
			end
		end
	end

	return targets
end

local lockedTarget = nil

local IgnoreFolder = workspace:FindFirstChild("IgnoreThese")

local function IsWallCheckClear(targetRoot)
	if not ToggleOn("WallCheck") then return true end

	local origin = Camera.CFrame.Position
	local targetPos = targetRoot.Position
	local direction = targetPos - origin

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = {}
	if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
	if targetRoot.Parent then table.insert(filter, targetRoot.Parent) end
	if IgnoreFolder then table.insert(filter, IgnoreFolder) end
	params.FilterDescendantsInstances = filter

	local result = workspace:Raycast(origin, direction, params)
	if not result then return true end

	-- Check if hit is part of target
	if result.Instance and result.Instance:IsDescendantOf(targetRoot.Parent) then
		return true
	end

	-- Check if hit is between us and the target (not floor/ceiling)
	local hitPos = result.Position
	local myPos = origin
	local targetMid = (myPos + targetPos) / 2
	local minY = math.min(myPos.Y, targetPos.Y) - 2
	local maxY = math.max(myPos.Y, targetPos.Y) + 2
	if hitPos.Y < minY or hitPos.Y > maxY then
		return true
	end

	return false
end

local function GetClosestTargetToCursor()
	local closest = nil
	local shortestDist = math.huge
	local mousePos = UserInputService:GetMouseLocation()
	local fov = Options.AimbotFOV and Options.AimbotFOV.Value or 150
	local teamCheck = ToggleOn("TeamCheck")
	local wallCheck = ToggleOn("WallCheck")
	local targetMode = Options.TargetMode and Options.TargetMode.Value or "Crosshair"
	local myRoot = GetLocalRoot()

	for _, target in ipairs(GetAllTargets()) do
		if teamCheck and IsOnTeam(target) then continue end
		if not IsAlive(target.Model) then continue end

		local root = target.Model:FindFirstChild("HumanoidRootPart")
		if not root then continue end
		if not myRoot then continue end

		local dist = (myRoot.Position - root.Position).Magnitude
		if dist > (Options.AimbotDistance and Options.AimbotDistance.Value or 500) then continue end

		local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
		if not onScreen then continue end

		if wallCheck and not IsWallCheckClear(root) then continue end

		local sortDist
		if targetMode == "Distance" then
			sortDist = dist
		else
			sortDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
		end

		if sortDist < shortestDist then
			-- Crosshair mode: still check FOV
			if targetMode == "Crosshair" and sortDist >= fov then continue end
			shortestDist = sortDist
			closest = target
		end
	end

	return closest
end

local function GetAimPart(target)
	local partName = Options.AimPart and Options.AimPart.Value or "Head"
	return target.Model:FindFirstChild(partName)
end

-- ═══════════════════════════════════════════════════════════
-- MENU HOVER CHECK
-- ═══════════════════════════════════════════════════════════

local function IsMouseOverMenu()
	local frame = Library.MainFrame or Library.Window or Library.Container
	if not frame then return false end
	if not frame.Visible then return false end
	local mousePos = UserInputService:GetMouseLocation()
	local pos = frame.AbsolutePosition
	local size = frame.AbsoluteSize
	return mousePos.X >= pos.X and mousePos.X <= pos.X + size.X
		and mousePos.Y >= pos.Y and mousePos.Y <= pos.Y + size.Y
end

-- ═══════════════════════════════════════════════════════════
-- HOLD AIMBOT STATE
-- ═══════════════════════════════════════════════════════════

local holdActive = false

local function GetHoldKeyCode()
	local key = Options.HoldKey and Options.HoldKey.Value or "Right Click"
	if key == "Right Click" then return Enum.UserInputType.MouseButton2
	elseif key == "Left Click" then return Enum.UserInputType.MouseButton1
	else return Enum.KeyCode[key] end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if not ToggleOn("HoldAimbot") then return end
	if input.UserInputType == GetHoldKeyCode() or input.KeyCode == GetHoldKeyCode() then
		holdActive = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == GetHoldKeyCode() or input.KeyCode == GetHoldKeyCode() then
		holdActive = false
	end
	-- Right click clears sticky target
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		lockedTarget = nil
	end
end)

-- ═══════════════════════════════════════════════════════════
-- AIMBOT TAB
-- ═══════════════════════════════════════════════════════════

local DiscordGroup = Tabs.Aimbot:AddLeftGroupbox("Ivory Hub", "info")
DiscordGroup:AddButton("JOIN DISCORD FOR DUPE", function()
	pcall(setclipboard, "https://discord.gg/MCWYKBdB4E")
	Library:Notify({ Title = "Ivory Hub", Description = "Discord link copied!", Time = 2, Type = "Success" })
end)

local AimbotGroup = Tabs.Aimbot:AddLeftGroupbox("Aimbot", "crosshair")

AimbotGroup:AddToggle("Aimbot", {
	Text = "Aimbot",
	Default = false,
	Tooltip = "Smooth aim toward closest player",
})

AimbotGroup:AddToggle("HoldAimbot", {
	Text = "Hold to Aim",
	Default = false,
	Tooltip = "Only aim while holding the key below",
})

AimbotGroup:AddDropdown("HoldKey", {
	Text = "Hold Key",
	Values = {"Right Click", "Left Click", "E", "Q", "Left Shift", "Left Ctrl", "C", "V", "X", "Z"},
	Default = "Right Click",
	Tooltip = "Key to hold for aimbot",
})

AimbotGroup:AddToggle("StickyAim", {
	Text = "Sticky Aim",
	Default = false,
	Tooltip = "Stay locked on current target until they die or you right click",
})

AimbotGroup:AddDropdown("AimPart", {
	Text = "Aim Part",
	Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
	Default = "Head",
	Tooltip = "Body part to aim at",
})

AimbotGroup:AddDropdown("TargetMode", {
	Text = "Target Mode",
	Values = {"Crosshair", "Distance"},
	Default = "Crosshair",
	Tooltip = "Crosshair = closest to your mouse | Distance = closest to your character",
})

AimbotGroup:AddSlider("AimbotFOV", {
	Text = "FOV",
	Default = 150,
	Min = 30,
	Max = 500,
	Rounding = 0,
})

AimbotGroup:AddSlider("AimbotStrength", {
	Text = "Strength",
	Default = 100,
	Min = 10,
	Max = 100,
	Rounding = 0,
	Tooltip = "How much the aim moves toward target (%)",
})

AimbotGroup:AddSlider("AimbotSpeed", {
	Text = "Speed",
	Default = 50,
	Min = 1,
	Max = 100,
	Rounding = 0,
	Tooltip = "Aim speed (lower = faster)",
})

AimbotGroup:AddSlider("AimbotSmoothing", {
	Text = "Smoothing",
	Default = 5,
	Min = 1,
	Max = 20,
	Rounding = 0,
	Tooltip = "Higher = smoother (slower)",
})

AimbotGroup:AddToggle("TeamCheck", {
	Text = "Team Check",
	Default = false,
	Tooltip = "Don't aim at teammates",
})

AimbotGroup:AddToggle("WallCheck", {
	Text = "Wall Check",
	Default = false,
	Tooltip = "Don't aim through walls",
})

AimbotGroup:AddToggle("AliveCheck", {
	Text = "Alive Check",
	Default = true,
	Tooltip = "Only aim at alive players",
})

AimbotGroup:AddToggle("IncludeBots", {
	Text = "Include Bots",
	Default = true,
	Tooltip = "Also aim at NPC bots",
})

AimbotGroup:AddSlider("AimbotDistance", {
	Text = "Max Distance",
	Default = 500,
	Min = 50,
	Max = 2000,
	Rounding = 0,
})

-- Triggerbot
local TriggerGroup = Tabs.Aimbot:AddRightGroupbox("Triggerbot", "zap")

TriggerGroup:AddToggle("Triggerbot", {
	Text = "Triggerbot",
	Default = false,
	Tooltip = "Auto fire when crosshair is on enemy",
})

TriggerGroup:AddSlider("TriggerReaction", {
	Text = "Reaction (ms)",
	Default = 100,
	Min = 0,
	Max = 500,
	Rounding = 0,
	Tooltip = "Delay before shooting (ms)",
})

TriggerGroup:AddSlider("TriggerFOV", {
	Text = "FOV",
	Default = 30,
	Min = 5,
	Max = 150,
	Rounding = 0,
})

TriggerGroup:AddToggle("TriggerShowFOV", {
	Text = "Show Trigger FOV",
	Default = false,
})

TriggerGroup:AddToggle("TriggerHoverOnly", {
	Text = "Only on Hover",
	Default = false,
	Tooltip = "Only shoot when mouse is directly on target",
})

TriggerGroup:AddDropdown("TriggerAimPart", {
	Text = "Aim Part",
	Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
	Default = "Head",
})

TriggerGroup:AddToggle("TriggerTeamCheck", {
	Text = "Team Check",
	Default = false,
})

TriggerGroup:AddToggle("TriggerWallCheck", {
	Text = "Wall Check",
	Default = false,
})

TriggerGroup:AddToggle("TriggerAliveCheck", {
	Text = "Alive Check",
	Default = true,
})

TriggerGroup:AddSlider("TriggerDistance", {
	Text = "Max Distance",
	Default = 500,
	Min = 50,
	Max = 2000,
	Rounding = 0,
})

-- ═══════════════════════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════════════════════

-- FOV Circle
local FOVGroup = Tabs.Visuals:AddLeftGroupbox("FOV Circle", "circle")

FOVGroup:AddToggle("FOVCircle", {
	Text = "FOV Circle",
	Default = false,
	Tooltip = "Shows aimbot FOV on screen",
})

FOVGroup:AddSlider("FOVSize", {
	Text = "Size",
	Default = 150,
	Min = 30,
	Max = 500,
	Rounding = 0,
})

FOVGroup:AddToggle("FOVFill", {
	Text = "Filled",
	Default = false,
})

FOVGroup:AddSlider("FOVFillTransparency", {
	Text = "Fill Transparency",
	Default = 0.8,
	Min = 0,
	Max = 1,
	Rounding = 1,
})

FOVGroup:AddToggle("FOVSpin", {
	Text = "Spin",
	Default = false,
	Tooltip = "Circle spins slowly",
})

FOVGroup:AddSlider("FOVSpinSpeed", {
	Text = "Spin Speed",
	Default = 50,
	Min = 10,
	Max = 200,
	Rounding = 0,
})

FOVGroup:AddLabel("FOV Color")
	:AddColorPicker("FOVColor", { Default = PINK })

-- ESP
local ESPGroup = Tabs.Visuals:AddLeftGroupbox("Player ESP", "users")

ESPGroup:AddToggle("PlayerESP", {
	Text = "Player ESP",
	Default = false,
	Tooltip = "Highlights all players",
})

ESPGroup:AddToggle("ESPBox", {
	Text = "Box ESP",
	Default = false,
})

ESPGroup:AddSlider("ESPBoxThickness", {
	Text = "Box Thickness",
	Default = 1.5,
	Min = 0.5,
	Max = 5,
	Rounding = 1,
})

ESPGroup:AddToggle("ESPGradient", {
	Text = "Gradient Box",
	Default = false,
	Tooltip = "Two-color gradient on the box",
})

ESPGroup:AddLabel("Gradient Top")
	:AddColorPicker("ESPGradTop", { Default = PURPLE })

ESPGroup:AddLabel("Gradient Bottom")
	:AddColorPicker("ESPGradBot", { Default = PINK })

ESPGroup:AddSlider("ESPTextSize", {
	Text = "Text Size",
	Default = 13,
	Min = 8,
	Max = 24,
	Rounding = 0,
})

ESPGroup:AddToggle("ESPName", {
	Text = "Name",
	Default = true,
})

ESPGroup:AddToggle("ESPTeam", {
	Text = "Team",
	Default = false,
})

ESPGroup:AddToggle("ESPDistance", {
	Text = "Distance",
	Default = true,
})

ESPGroup:AddToggle("ESPHealthbar", {
	Text = "Healthbar",
	Default = true,
})

ESPGroup:AddToggle("ESPHealthText", {
	Text = "Health Text",
	Default = false,
})

ESPGroup:AddSlider("ESPMaxDistance", {
	Text = "Max Distance",
	Default = 500,
	Min = 50,
	Max = 2000,
	Rounding = 0,
})

-- ESP Highlight
local HighlightGroup = Tabs.Visuals:AddRightGroupbox("Highlight ESP", "layers")

HighlightGroup:AddToggle("ESPHighlight", {
	Text = "Highlight ESP",
	Default = false,
	Tooltip = "Highlights through walls",
})

HighlightGroup:AddLabel("Fill Color")
	:AddColorPicker("HighlightFillColor", { Default = PURPLE })

HighlightGroup:AddLabel("Outline Color")
	:AddColorPicker("HighlightOutlineColor", { Default = WHITE })

HighlightGroup:AddSlider("HighlightFillTransparency", {
	Text = "Fill Transparency",
	Default = 0.5,
	Min = 0,
	Max = 1,
	Rounding = 1,
})

HighlightGroup:AddSlider("HighlightOutlineTransparency", {
	Text = "Outline Transparency",
	Default = 0,
	Min = 0,
	Max = 1,
	Rounding = 1,
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Show Cursor",
	Default = true,
}):OnChanged(function(v)
	Library.ShowCustomCursor = v
end)

MenuGroup:AddToggle("NotifySide", {
	Text = "Notifications",
	Default = true,
}):OnChanged(function(v)
	Library.NotifySide = v and "Right" or "Left"
end)

MenuGroup:AddButton("Discord", function()
	pcall(setclipboard, "https://discord.gg/MCWYKBdB4E")
	Library:Notify({ Title = "Ivory Hub", Description = "Discord link copied!", Time = 2, Type = "Success" })
end)

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

local CreditsGroup = Tabs.Settings:AddLeftGroupbox("Credits", "heart")
CreditsGroup:AddLabel('<font size="18" color="#FF69B4"><b>Made by Mommy Veqxoo &lt; / 3</b></font>', true)

local ThemeGroup = Tabs.Settings:AddRightGroupbox("Theme", "palette")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub/hypershot")
SaveManager:SetSubFolder("place")

ThemeManager:ApplyToTab(Tabs["Settings"])
SaveManager:BuildConfigSection(Tabs["Settings"])

SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════════
-- AIMBOT LOOP
-- ═══════════════════════════════════════════════════════════

spawn(function()
	while true do
		RunService.RenderStepped:Wait()
		pcall(function()
			if not ToggleOn("Aimbot") then
				lockedTarget = nil
				return
			end
			if IsMouseOverMenu() then return end
			if ToggleOn("HoldAimbot") and not holdActive then
				lockedTarget = nil
				return
			end

			local target = nil
			local sticky = ToggleOn("StickyAim")
			local maxDist = Options.AimbotDistance and Options.AimbotDistance.Value or 500

			-- Check if locked target is still valid
			if sticky and lockedTarget then
				if not IsAlive(lockedTarget.Model) then
					lockedTarget = nil
				else
					local root = lockedTarget.Model:FindFirstChild("HumanoidRootPart")
					local myRoot = GetLocalRoot()
					if not root or not myRoot then
						lockedTarget = nil
					else
						local dist = (myRoot.Position - root.Position).Magnitude
						if dist > maxDist then
							lockedTarget = nil
						else
							local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
							if not onScreen then
								lockedTarget = nil
							elseif ToggleOn("WallCheck") and not IsWallCheckClear(root) then
								lockedTarget = nil
							else
								target = lockedTarget
							end
						end
					end
				end
			end

			-- Find new target if no lock
			if not target then
				target = GetClosestTargetToCursor()
				if sticky and target then
					lockedTarget = target
				end
			end

			if not target then return end

			local aimPart = GetAimPart(target)
			if not aimPart then return end

			local myRoot = GetLocalRoot()
			if not myRoot then return end

			local targetRoot = target.Model:FindFirstChild("HumanoidRootPart")
			if not targetRoot then return end

			local screenPos, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
			if not onScreen then return end

			local mousePos = UserInputService:GetMouseLocation()
			local delta = Vector2.new(screenPos.X - mousePos.X, screenPos.Y - mousePos.Y)

			local strength = (Options.AimbotStrength and Options.AimbotStrength.Value or 100) / 100
			local smoothing = Options.AimbotSmoothing and Options.AimbotSmoothing.Value or 5
			local speed = (Options.AimbotSpeed and Options.AimbotSpeed.Value or 50) / 100

			local moveX = delta.X * strength * speed / smoothing
			local moveY = delta.Y * strength * speed / smoothing

			if moveX ~= 0 or moveY ~= 0 then
				mousemoverel(moveX, moveY)
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- TRIGGERBOT LOOP
-- ═══════════════════════════════════════════════════════════

local lastTriggerTime = 0

-- Triggerbot FOV circle
local TriggerFOVObj = Drawing.new("Circle")
TriggerFOVObj.Visible = false
TriggerFOVObj.Thickness = 1.5
TriggerFOVObj.Radius = 30
TriggerFOVObj.Color = CYAN
TriggerFOVObj.Filled = false
TriggerFOVObj.Transparency = 0.8

spawn(function()
	while true do
		RunService.RenderStepped:Wait()
		pcall(function()
			-- Update trigger FOV circle
			if ToggleOn("Triggerbot") and ToggleOn("TriggerShowFOV") then
				local fov = Options.TriggerFOV and Options.TriggerFOV.Value or 30
				TriggerFOVObj.Radius = fov
				TriggerFOVObj.Position = UserInputService:GetMouseLocation()
				TriggerFOVObj.Visible = true
			else
				TriggerFOVObj.Visible = false
			end

			if not ToggleOn("Triggerbot") then return end
			if IsMouseOverMenu() then return end

			local now = tick()
			local reaction = (Options.TriggerReaction and Options.TriggerReaction.Value or 100) / 1000
			if (now - lastTriggerTime) < reaction then return end

			local mousePos = UserInputService:GetMouseLocation()
			local fov = Options.TriggerFOV and Options.TriggerFOV.Value or 30
			local teamCheck = ToggleOn("TriggerTeamCheck")
			local hoverOnly = ToggleOn("TriggerHoverOnly")

			for _, target in ipairs(GetAllTargets()) do
				if teamCheck and IsOnTeam(target) then continue end
				if ToggleOn("TriggerAliveCheck") and not IsAlive(target.Model) then continue end

				local root = target.Model:FindFirstChild("HumanoidRootPart")
				if not root then continue end

				local myRoot = GetLocalRoot()
				if not myRoot then continue end

				local dist = (myRoot.Position - root.Position).Magnitude
				if dist > (Options.TriggerDistance and Options.TriggerDistance.Value or 500) then continue end

				local partName = Options.TriggerAimPart and Options.TriggerAimPart.Value or "Head"
				local part = target.Model:FindFirstChild(partName)
				if not part then continue end

				local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if not onScreen then continue end

				local hitDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
				if hitDist < fov then
					if ToggleOn("TriggerWallCheck") and not IsWallCheckClear(root) then continue end
					if hoverOnly and hitDist > 15 then continue end
					lastTriggerTime = now
					mouse1click()
					break
				end
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- FOV CIRCLE
-- ═══════════════════════════════════════════════════════════

local FOVObj = Drawing.new("Circle")
FOVObj.Visible = false
FOVObj.Thickness = 1.5
FOVObj.NumSides = 60
FOVObj.Radius = 150
FOVObj.Color = PINK
FOVObj.Filled = false
FOVObj.Transparency = 0.8

local spinAngle = 0

spawn(function()
	while true do
		RunService.RenderStepped:Wait()
		pcall(function()
			if ToggleOn("FOVCircle") then
				local size = Options.FOVSize and Options.FOVSize.Value or 150
				local col = Options.FOVColor and Options.FOVColor.Value or PINK
				local filled = ToggleOn("FOVFill")
				local fillTrans = Options.FOVFillTransparency and Options.FOVFillTransparency.Value or 0.8

				FOVObj.Radius = size
				FOVObj.Color = col
				FOVObj.Filled = filled
				FOVObj.Transparency = filled and fillTrans or 0.8
				FOVObj.Position = UserInputService:GetMouseLocation()
				FOVObj.Visible = true

				if ToggleOn("FOVSpin") then
					local spinSpeed = (Options.FOVSpinSpeed and Options.FOVSpinSpeed.Value or 50) / 1000
					spinAngle = spinAngle + spinSpeed
					FOVObj.Rotation = spinAngle
				end
			else
				FOVObj.Visible = false
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- PLAYER ESP (Drawing)
-- ═══════════════════════════════════════════════════════════

local espObjects = {}

local function ClearESP()
	for key, objs in pairs(espObjects) do
		for _, obj in ipairs(objs) do
			pcall(function() obj:Remove() end)
		end
	end
	espObjects = {}
end

local function CreateESPObject(key)
	local boxOutline = Drawing.new("Square")
	boxOutline.Filled = false
	boxOutline.Thickness = 3
	boxOutline.Color = Color3.new(0, 0, 0)
	boxOutline.Visible = false

	-- Gradient outline: 8 line pairs for left/right + top/bottom
	local gradLines = {}
	for i = 1, 10 do
		local left = Drawing.new("Line")
		left.Thickness = 1.5
		left.Visible = false
		table.insert(gradLines, left)

		local right = Drawing.new("Line")
		right.Thickness = 1.5
		right.Visible = false
		table.insert(gradLines, right)
	end
	local topLine = Drawing.new("Line")
	topLine.Thickness = 1.5
	topLine.Visible = false
	table.insert(gradLines, topLine)
	local botLine = Drawing.new("Line")
	botLine.Thickness = 1.5
	botLine.Visible = false
	table.insert(gradLines, botLine)

	local nameLabel = Drawing.new("Text")
	nameLabel.Size = 13
	nameLabel.Center = true
	nameLabel.Outline = true
	nameLabel.Color = WHITE
	nameLabel.Visible = false

	local distLabel = Drawing.new("Text")
	distLabel.Size = 12
	distLabel.Center = true
	distLabel.Outline = true
	distLabel.Color = WHITE
	distLabel.Visible = false

	local teamLabel = Drawing.new("Text")
	teamLabel.Size = 12
	teamLabel.Center = true
	teamLabel.Outline = true
	teamLabel.Color = CYAN
	teamLabel.Visible = false

	local healthBar = Drawing.new("Line")
	healthBar.Thickness = 3
	healthBar.Color = GREEN
	healthBar.Visible = false

	local healthBarOutline = Drawing.new("Line")
	healthBarOutline.Thickness = 5
	healthBarOutline.Color = Color3.new(0, 0, 0)
	healthBarOutline.Visible = false

	local healthText = Drawing.new("Text")
	healthText.Size = 12
	healthText.Center = true
	healthText.Outline = true
	healthText.Color = GREEN
	healthText.Visible = false

	espObjects[key] = {
		boxOutline = boxOutline,
		gradLines = gradLines,
		nameLabel = nameLabel,
		distLabel = distLabel,
		teamLabel = teamLabel,
		healthBar = healthBar,
		healthBarOutline = healthBarOutline,
		healthText = healthText,
	}
end

local function RemoveESPObject(key)
	if espObjects[key] then
		pcall(function() espObjects[key].boxOutline:Remove() end)
		for _, line in ipairs(espObjects[key].gradLines) do
			pcall(function() line:Remove() end)
		end
		pcall(function() espObjects[key].nameLabel:Remove() end)
		pcall(function() espObjects[key].distLabel:Remove() end)
		pcall(function() espObjects[key].teamLabel:Remove() end)
		pcall(function() espObjects[key].healthBar:Remove() end)
		pcall(function() espObjects[key].healthBarOutline:Remove() end)
		pcall(function() espObjects[key].healthText:Remove() end)
		espObjects[key] = nil
	end
end

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(player)
	RemoveESPObject(player.Name)
end)

-- ESP Update Loop
local function LerpColor(c1, c2, t)
	return Color3.new(
		c1.R + (c2.R - c1.R) * t,
		c1.G + (c2.G - c1.G) * t,
		c1.B + (c2.B - c1.B) * t
	)
end

spawn(function()
	while true do
		RunService.RenderStepped:Wait()
		pcall(function()
			local showESP = ToggleOn("PlayerESP")
			local showBox = ToggleOn("ESPBox")
			local showName = ToggleOn("ESPName")
			local showTeam = ToggleOn("ESPTeam")
			local showDist = ToggleOn("ESPDistance")
			local showHealthbar = ToggleOn("ESPHealthbar")
			local showHealthText = ToggleOn("ESPHealthText")
			local maxDist = Options.ESPMaxDistance and Options.ESPMaxDistance.Value or 500
			local boxThickness = Options.ESPBoxThickness and Options.ESPBoxThickness.Value or 1.5
			local textSize = Options.ESPTextSize and Options.ESPTextSize.Value or 13
			local useGradient = ToggleOn("ESPGradient")
			local gradTop = Options.ESPGradTop and Options.ESPGradTop.Value or PURPLE
			local gradBot = Options.ESPGradBot and Options.ESPGradBot.Value or PINK

			local activeKeys = {}

			for _, target in ipairs(GetAllTargets()) do
				local key = target.Name
				activeKeys[key] = true

				if not espObjects[key] then
					CreateESPObject(key)
				end

				local objs = espObjects[key]
				local char = target.Model
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")

				if not showESP or not root or not hum or hum.Health <= 0 then
					objs.boxOutline.Visible = false
					for _, s in ipairs(objs.gradLines) do s.Visible = false end
					objs.nameLabel.Visible = false
					objs.distLabel.Visible = false
					objs.teamLabel.Visible = false
					objs.healthBar.Visible = false
					objs.healthBarOutline.Visible = false
					objs.healthText.Visible = false
					continue
				end

				local myRoot = GetLocalRoot()
				if not myRoot then
					objs.boxOutline.Visible = false
					for _, s in ipairs(objs.gradLines) do s.Visible = false end
					objs.nameLabel.Visible = false
					objs.distLabel.Visible = false
					objs.teamLabel.Visible = false
					objs.healthBar.Visible = false
					objs.healthBarOutline.Visible = false
					objs.healthText.Visible = false
					continue
				end

				local dist = (myRoot.Position - root.Position).Magnitude
				if dist > maxDist then
					objs.boxOutline.Visible = false
					for _, s in ipairs(objs.gradLines) do s.Visible = false end
					objs.nameLabel.Visible = false
					objs.distLabel.Visible = false
					objs.teamLabel.Visible = false
					objs.healthBar.Visible = false
					objs.healthBarOutline.Visible = false
					objs.healthText.Visible = false
					continue
				end

				local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
				if not onScreen then
					objs.boxOutline.Visible = false
					for _, s in ipairs(objs.gradLines) do s.Visible = false end
					objs.nameLabel.Visible = false
					objs.distLabel.Visible = false
					objs.teamLabel.Visible = false
					objs.healthBar.Visible = false
					objs.healthBarOutline.Visible = false
					objs.healthText.Visible = false
					continue
				end

				-- Box dimensions
				local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 3, 0))
				local botPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
				local height = math.abs(topPos.Y - botPos.Y)
				local width = height * 0.6

				-- Box outline
				objs.boxOutline.Visible = showBox
				objs.boxOutline.Size = Vector2.new(width + 2, height + 2)
				objs.boxOutline.Position = Vector2.new(screenPos.X - (width + 2) / 2, topPos.Y)
				objs.boxOutline.Thickness = boxThickness + 1.5

				-- Gradient outline
				local boxX = screenPos.X - width / 2
				local boxX2 = screenPos.X + width / 2
				local segH = height / 10

				-- Left + right edges (gradient top to bottom)
				for i = 1, 10 do
					local t = (i - 1) / 9
					local col = useGradient and LerpColor(gradTop, gradBot, t) or gradTop
					local y1 = topPos.Y + (i - 1) * segH
					local y2 = topPos.Y + i * segH

					local left = objs.gradLines[i * 2 - 1]
					left.Visible = showBox
					left.From = Vector2.new(boxX, y1)
					left.To = Vector2.new(boxX, y2)
					left.Color = col
					left.Thickness = boxThickness

					local right = objs.gradLines[i * 2]
					right.Visible = showBox
					right.From = Vector2.new(boxX2, y1)
					right.To = Vector2.new(boxX2, y2)
					right.Color = col
					right.Thickness = boxThickness
				end

				-- Top edge
				local topLine = objs.gradLines[21]
				topLine.Visible = showBox
				topLine.From = Vector2.new(boxX, topPos.Y)
				topLine.To = Vector2.new(boxX2, topPos.Y)
				topLine.Color = useGradient and gradTop or gradTop
				topLine.Thickness = boxThickness

				-- Bottom edge
				local botLine = objs.gradLines[22]
				botLine.Visible = showBox
				botLine.From = Vector2.new(boxX, botPos.Y)
				botLine.To = Vector2.new(boxX2, botPos.Y)
				botLine.Color = useGradient and gradBot or gradTop
				botLine.Thickness = boxThickness

				-- Name
				local nameText = ""
				if not target.IsPlayer then
					nameText = "BOT!!"
				else
					if showName then nameText = target.Name end
				end
				objs.nameLabel.Visible = nameText ~= ""
				objs.nameLabel.Text = nameText
				objs.nameLabel.Size = textSize
				objs.nameLabel.Color = not target.IsPlayer and YELLOW or WHITE
				objs.nameLabel.Position = Vector2.new(screenPos.X, topPos.Y - textSize - 2)

				-- Distance
				objs.distLabel.Visible = showDist
				objs.distLabel.Text = math.floor(dist) .. "m"
				objs.distLabel.Size = textSize - 1
				objs.distLabel.Position = Vector2.new(screenPos.X, botPos.Y + 4)

				-- Team
				objs.teamLabel.Visible = showTeam and target.IsPlayer and target.Player.Team ~= nil
				if target.IsPlayer and target.Player.Team then
					objs.teamLabel.Text = target.Player.Team.Name
				else
					objs.teamLabel.Text = "Bot"
				end
				objs.teamLabel.Size = textSize - 1
				objs.teamLabel.Position = Vector2.new(screenPos.X, topPos.Y - (textSize * 2) - 4)

				-- Healthbar
				local healthPct = hum.Health / hum.MaxHealth
				local barY = topPos.Y

				objs.healthBarOutline.Visible = showHealthbar
				objs.healthBarOutline.From = Vector2.new(screenPos.X - width / 2 - 5, barY)
				objs.healthBarOutline.To = Vector2.new(screenPos.X - width / 2 - 5, barY + height)

				objs.healthBar.Visible = showHealthbar
				objs.healthBar.From = Vector2.new(screenPos.X - width / 2 - 5, barY)
				objs.healthBar.To = Vector2.new(screenPos.X - width / 2 - 5, barY + height * healthPct)
				objs.healthBar.Color = healthPct > 0.5 and GREEN or healthPct > 0.25 and YELLOW or RED

				-- Health Text
				objs.healthText.Visible = showHealthText
				objs.healthText.Text = math.floor(hum.Health)
				objs.healthText.Size = textSize - 1
				objs.healthText.Color = objs.healthBar.Color
				objs.healthText.Position = Vector2.new(screenPos.X - width / 2 - 5, barY + height + 4)
			end

			-- Hide stale ESP
			for key, objs in pairs(espObjects) do
				if not activeKeys[key] then
					objs.boxOutline.Visible = false
					for _, s in ipairs(objs.gradLines) do s.Visible = false end
					objs.nameLabel.Visible = false
					objs.distLabel.Visible = false
					objs.teamLabel.Visible = false
					objs.healthBar.Visible = false
					objs.healthBarOutline.Visible = false
					objs.healthText.Visible = false
				end
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- HIGHLIGHT ESP
-- ═══════════════════════════════════════════════════════════

local highlights = {}

local function AddHighlight(model, name)
	if highlights[name] then return end
	if not model then return end

	local hl = Instance.new("Highlight")
	hl.Name = "IvoryHighlight"
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Parent = CoreGui

	highlights[name] = hl
end

local function RemoveHighlight(name)
	if highlights[name] then
		pcall(function() highlights[name]:Destroy() end)
		highlights[name] = nil
	end
end

-- Highlight Loop
spawn(function()
	while true do
		task.wait(0.3)
		pcall(function()
			local activeNames = {}

			if ToggleOn("ESPHighlight") then
				local fillCol = Options.HighlightFillColor and Options.HighlightFillColor.Value or PURPLE
				local outlineCol = Options.HighlightOutlineColor and Options.HighlightOutlineColor.Value or WHITE
				local fillTrans = Options.HighlightFillTransparency and Options.HighlightFillTransparency.Value or 0.5
				local outlineTrans = Options.HighlightOutlineTransparency and Options.HighlightOutlineTransparency.Value or 0

				-- Players
				for _, player in ipairs(Players:GetPlayers()) do
					if player ~= LocalPlayer and IsAlive(player) and player.Character then
						local key = "player_" .. player.Name
						activeNames[key] = true

						if not highlights[key] or not highlights[key].Parent then
							AddHighlight(player.Character, key)
						end

						if highlights[key] then
							highlights[key].FillColor = fillCol
							highlights[key].OutlineColor = outlineCol
							highlights[key].FillTransparency = fillTrans
							highlights[key].OutlineTransparency = outlineTrans
							highlights[key].Adornee = player.Character
						end
					end
				end

				-- Bots
				if MobsFolder and ToggleOn("IncludeBots") then
					for _, bot in ipairs(MobsFolder:GetChildren()) do
						if bot:IsA("Model") and IsAlive(bot) then
							local cleanName = bot.Name:gsub("__Bot$", "")
							local key = "bot_" .. cleanName
							activeNames[key] = true

							if not highlights[key] or not highlights[key].Parent then
								AddHighlight(bot, key)
							end

							if highlights[key] then
								highlights[key].FillColor = fillCol
								highlights[key].OutlineColor = outlineCol
								highlights[key].FillTransparency = fillTrans
								highlights[key].OutlineTransparency = outlineTrans
								highlights[key].Adornee = bot
							end
						end
					end
				end
			end

			-- Remove stale
			for key, hl in pairs(highlights) do
				if not activeNames[key] then
					pcall(function() hl:Destroy() end)
					highlights[key] = nil
				end
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- CLEANUP ON UNLOAD
-- ═══════════════════════════════════════════════════════════

Library:OnUnload(function()
	FOVObj:Remove()
	TriggerFOVObj:Remove()
	ClearESP()
	for key, hl in pairs(highlights) do
		pcall(function() hl:Destroy() end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- LOADED
-- ═══════════════════════════════════════════════════════════

print("[Ivory Hub] Hypershot loaded!")
print("[Ivory Hub] Made by mommy veqxo <3")
