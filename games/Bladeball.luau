local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

-- Kill all old copies of this script
if getgenv().IvoryBladeBallVersion then
	pcall(getgenv().IvoryBladeBallVersion)
end
getgenv().IvoryBladeBallVersion = function() end

-- Destroy old GUIs
for _, obj in ipairs(CoreGui:GetChildren()) do
	if obj.Name == "IvoryBallESP" or obj.Name == "IvoryBallTag" or obj.Name == "IvoryVelTag" or obj.Name == "IvoryPing" or obj.Name == "IvoryClashBtn" then
		obj:Destroy()
	end
end
for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		local hl = plr.Character:FindFirstChild("IvoryHighlight")
		if hl then hl:Destroy() end
	end
end

wait(0.5)

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
		"v1.4 |",
		{ Text = "Blade Ball", Copyable = true },
		"|",
		{ Text = tostring(LocalPlayer.UserId), Copyable = true },
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
})

local Tabs = {
	Combat = Window:AddTab({ Name = "Combat", Icon = "swords", Description = "Auto parry" }),
	ESP = Window:AddTab({ Name = "ESP", Icon = "eye", Description = "Ball & player ESP" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "UI settings" }),
}

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════

local Disclaimer1Group = Tabs.Combat:AddLeftGroupbox("Disclaimer!", "alert-triangle")
Disclaimer1Group:AddLabel('<font color="#FFB7C5"><b>!! Works best at 50 ping or under !!</b></font>', true)

local Disclaimer2Group = Tabs.Combat:AddRightGroupbox("Disclaimer!", "alert-triangle")
Disclaimer2Group:AddLabel('<font color="#FFB7C5"><b>!! Keep Roblox focused for auto parry !!</b></font>', true)

local ParryGroup = Tabs.Combat:AddLeftGroupbox("Auto Parry", "shield")

ParryGroup:AddToggle("AutoParry", {
	Text = "Auto Parry",
	Default = true,
	Tooltip = "Clicks when ball targets you, adapts to ping",
})

ParryGroup:AddSlider("ParryDist", {
	Text = "Parry Distance",
	Default = 30,
	Min = 8,
	Max = 60,
	Rounding = 0,
})

ParryGroup:AddSlider("ParryCooldown", {
	Text = "Cooldown (ms)",
	Default = 350,
	Min = 100,
	Max = 600,
	Rounding = 0,
})

ParryGroup:AddDropdown("PingPreset", {
	Text = "Your Ping Range",
	Values = {"50", "75", "100", "125", "150", "175", "200+"},
	Default = "50",
	Tooltip = "Tell it your ping so it calibrates better",
})

ParryGroup:AddButton({
	Text = "Apply Preset",
	Func = function()
		local ping = Options.PingPreset.Value
		local presets = {
			["50"]   = { dist = 30, cd = 350 },
			["75"]   = { dist = 32, cd = 380 },
			["100"]  = { dist = 35, cd = 420 },
			["125"]  = { dist = 38, cd = 450 },
			["150"]  = { dist = 40, cd = 480 },
			["175"]  = { dist = 42, cd = 500 },
			["200+"] = { dist = 45, cd = 550 },
		}
		local p = presets[ping]
		if p then
			Options.ParryDist:SetValue(p.dist)
			Options.ParryCooldown:SetValue(p.cd)
		end
	end,
})

local ClashGroup = Tabs.Combat:AddRightGroupbox("Clash", "zap")

local ClashToggle = ClashGroup:AddToggle("ClashMode", {
	Text = "Clash Mode",
	Default = false,
	Tooltip = "Spams clicks when ON",
})

ClashToggle:AddKeyPicker("ClashKeybind", { Default = "V", Text = "Clash keybind" })

ClashGroup:AddSlider("ClashCPS", {
	Text = "Clash CPS",
	Default = 30,
	Min = 10,
	Max = 60,
	Rounding = 0,
	Tooltip = "Clicks per second during clash mode",
})

-- ═══════════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════════

local BallGroup = Tabs.ESP:AddLeftGroupbox("Ball ESP", "circle")

BallGroup:AddToggle("BallESP", {
	Text = "Ball ESP",
	Default = true,
})

BallGroup:AddToggle("TargetTag", {
	Text = "Target Nametag",
	Default = true,
})

BallGroup:AddToggle("VelocityTag", {
	Text = "Velocity Display",
	Default = true,
})

BallGroup:AddSlider("BoxThickness", {
	Text = "Box Thickness",
	Default = 5,
	Min = 1,
	Max = 10,
	Rounding = 0,
})

BallGroup:AddSlider("BoxPadding", {
	Text = "Box Padding",
	Default = 10,
	Min = 0,
	Max = 30,
	Rounding = 0,
})

local PlayerGroup = Tabs.ESP:AddLeftGroupbox("Player ESP", "users")

PlayerGroup:AddToggle("PlayerESP", {
	Text = "Player ESP",
	Default = true,
	Tooltip = "Highlights all players blueish-purple",
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

local CreditsGroup = Tabs.Settings:AddLeftGroupbox("Credits", "heart")
CreditsGroup:AddLabel('<font size="18" color="#FF69B4"><b>Made by Mommy Veqxoo &lt; / 3</b></font>', true)

MenuGroup:AddButton("Unload", function()
	pcall(function()
		for _, obj in ipairs(CoreGui:GetChildren()) do
			if obj.Name == "IvoryBallESP" or obj.Name == "IvoryBallTag" or obj.Name == "IvoryVelTag" or obj.Name == "IvoryPing" or obj.Name == "IvoryClashBtn" then
				obj:Destroy()
			end
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Character then
				local hl = plr.Character:FindFirstChild("IvoryHighlight")
				if hl then hl:Destroy() end
			end
		end
	end)
	Library:Unload()
end)
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub/bladeball")
SaveManager:SetSubFolder("place")
ThemeManager:ApplyToTab(Tabs["Settings"])
SaveManager:BuildConfigSection(Tabs["Settings"])
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════

local PINK = Color3.fromRGB(255, 183, 197)
local PURPLE = Color3.fromRGB(140, 100, 255)

local function HasToggle(name)
	return Toggles[name] ~= nil
end

local function ToggleOn(name)
	return HasToggle(name) and Toggles[name].Value
end

local function GetVisibleBall()
	for _, obj in ipairs(Workspace.Balls:GetChildren()) do
		if obj:IsA("BasePart") and obj.Transparency < 0.5 then
			return obj
		end
	end
	return nil
end

local function GetRealBall()
	for _, obj in ipairs(Workspace.Balls:GetChildren()) do
		if obj:IsA("BasePart") and obj:GetAttribute("realBall") == true then
			return obj
		end
	end
	for _, obj in ipairs(Workspace.Balls:GetChildren()) do
		if obj:IsA("BasePart") then
			local t = obj:GetAttribute("target")
			if t and t ~= "" then return obj end
		end
	end
	return nil
end

-- ═══════════════════════════════════════════════════════════
-- BALL ESP
-- ═══════════════════════════════════════════════════════════

local BallGui = Instance.new("BillboardGui")
BallGui.Name = "IvoryBallESP"
BallGui.Size = UDim2.new(0, 50, 0, 50)
BallGui.AlwaysOnTop = true
BallGui.LightInfluence = 0
BallGui.Enabled = false
BallGui.Parent = CoreGui

local BoxFrame = Instance.new("Frame")
BoxFrame.Name = "Box"
BoxFrame.Size = UDim2.new(1, 0, 1, 0)
BoxFrame.BackgroundTransparency = 1
BoxFrame.BorderSizePixel = 0
BoxFrame.Parent = BallGui

local BoxStroke = Instance.new("UIStroke")
BoxStroke.Color = PINK
BoxStroke.Thickness = 5
BoxStroke.Transparency = 0
BoxStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
BoxStroke.Parent = BoxFrame
Instance.new("UICorner", BoxFrame).CornerRadius = UDim.new(0, 3)

local DistLabel = Instance.new("TextLabel")
DistLabel.Name = "Dist"
DistLabel.Size = UDim2.new(0, 60, 0, 16)
DistLabel.Position = UDim2.new(0.5, -30, 1, 2)
DistLabel.BackgroundTransparency = 0.5
DistLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DistLabel.Text = "0m"
DistLabel.TextColor3 = PINK
DistLabel.TextSize = 11
DistLabel.Font = Enum.Font.GothamBold
DistLabel.Parent = BallGui
Instance.new("UICorner", DistLabel).CornerRadius = UDim.new(0, 3)

-- Target nametag (no background)
local TargetTag = Instance.new("BillboardGui")
TargetTag.Name = "IvoryBallTag"
TargetTag.Size = UDim2.new(0, 200, 0, 30)
TargetTag.StudsOffset = Vector3.new(0, 4, 0)
TargetTag.AlwaysOnTop = true
TargetTag.LightInfluence = 0
TargetTag.Enabled = false
TargetTag.Parent = CoreGui

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Name = "Tag"
TargetLabel.Size = UDim2.new(1, 0, 1, 0)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Target: ???"
TargetLabel.TextColor3 = PINK
TargetLabel.TextSize = 14
TargetLabel.TextStrokeTransparency = 0.4
TargetLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TargetLabel.Font = Enum.Font.GothamBold
TargetLabel.Parent = TargetTag

-- Velocity tag (no background)
local VelTag = Instance.new("BillboardGui")
VelTag.Name = "IvoryVelTag"
VelTag.Size = UDim2.new(0, 200, 0, 20)
VelTag.StudsOffset = Vector3.new(0, 3.5, 0)
VelTag.AlwaysOnTop = true
VelTag.LightInfluence = 0
VelTag.Enabled = false
VelTag.Parent = CoreGui

local VelLabel = Instance.new("TextLabel")
VelLabel.Name = "Vel"
VelLabel.Size = UDim2.new(1, 0, 1, 0)
VelLabel.BackgroundTransparency = 1
VelLabel.Text = "0 studs/s"
VelLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
VelLabel.TextSize = 11
VelLabel.TextStrokeTransparency = 0.5
VelLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
VelLabel.Font = Enum.Font.GothamBold
VelLabel.Parent = VelTag

-- Ping display (top center, pink)
local PingGui = Instance.new("ScreenGui")
PingGui.Name = "IvoryPing"
PingGui.ResetOnSpawn = false
PingGui.IgnoreGuiInset = true
PingGui.DisplayOrder = 999
PingGui.Parent = CoreGui

local PingFrame = Instance.new("Frame")
PingFrame.Name = "Frame"
PingFrame.Size = UDim2.new(0, 260, 0, 24)
PingFrame.Position = UDim2.new(0.5, -130, 0, 4)
PingFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
PingFrame.BackgroundTransparency = 0.5
PingFrame.BorderSizePixel = 0
PingFrame.Parent = PingGui
Instance.new("UICorner", PingFrame).CornerRadius = UDim.new(0, 6)

local PingLabel = Instance.new("TextLabel")
PingLabel.Name = "Ping"
PingLabel.Size = UDim2.new(0, 80, 1, 0)
PingLabel.Position = UDim2.new(0, 0, 0, 0)
PingLabel.BackgroundTransparency = 1
PingLabel.Text = "Ping: ...ms"
PingLabel.TextColor3 = PINK
PingLabel.TextSize = 12
PingLabel.Font = Enum.Font.GothamBold
PingLabel.Parent = PingFrame

local DirLabel = Instance.new("TextLabel")
DirLabel.Name = "Dir"
DirLabel.Size = UDim2.new(0, 80, 1, 0)
DirLabel.Position = UDim2.new(0, 85, 0, 0)
DirLabel.BackgroundTransparency = 1
DirLabel.Text = "Dir: ..."
DirLabel.TextColor3 = PINK
DirLabel.TextSize = 12
DirLabel.Font = Enum.Font.GothamBold
DirLabel.Parent = PingFrame

local ClashLabel = Instance.new("TextLabel")
ClashLabel.Name = "Clash"
ClashLabel.Size = UDim2.new(0, 80, 1, 0)
ClashLabel.Position = UDim2.new(0, 170, 0, 0)
ClashLabel.BackgroundTransparency = 1
ClashLabel.Text = "Clash: OFF"
ClashLabel.TextColor3 = PINK
ClashLabel.TextSize = 12
ClashLabel.Font = Enum.Font.GothamBold
ClashLabel.Parent = PingFrame

-- ═══════════════════════════════════════════════════════════
-- PING LOOP
-- ═══════════════════════════════════════════════════════════

spawn(function()
	while true do
		wait(0.2)
		pcall(function()
			local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
			PingLabel.Text = "Ping: " .. ping .. "ms"
			PingLabel.TextColor3 = PINK

			-- Direction
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if myRoot then
				local vel = myRoot.AssemblyLinearVelocity
				if vel.Magnitude > 1 then
					local look = myRoot.CFrame.LookVector
					local angle = math.deg(math.atan2(look.X, look.Z))
					if angle < 0 then angle = angle + 360 end
					local dirs = {"N", "NE", "E", "SE", "S", "SW", "W", "NW"}
					local idx = math.floor((angle + 22.5) / 45) % 8 + 1
					DirLabel.Text = "Dir: " .. dirs[idx]
				else
					DirLabel.Text = "Dir: Idle"
				end
			end

			-- Clash status
			ClashHeld = ToggleOn("ClashMode")
			if ClashHeld then
				ClashLabel.Text = "Clash: ON"
				ClashLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
			else
				ClashLabel.Text = "Clash: OFF"
				ClashLabel.TextColor3 = PINK
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- ESP LOOP
-- ═══════════════════════════════════════════════════════════

spawn(function()
	wait(1)
	while true do
		wait(0.03)
		pcall(function()
			local visBall = GetVisibleBall()
			local realBall = GetRealBall()
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

			-- Ball ESP box
			if visBall and visBall.Parent and ToggleOn("BallESP") and myRoot then
				local cam = Workspace.CurrentCamera
				if cam then
					local dist = (visBall.Position - cam.CFrame.Position).Magnitude
					local ballDiam = visBall.Size.X
					local vpY = cam.ViewportSize.Y
					local fov = cam.FieldOfView
					local pxPerStud = vpY / (2 * dist * math.tan(math.rad(fov / 2)))
					local boxPx = (ballDiam * pxPerStud) + (Options.BoxPadding and Options.BoxPadding.Value or 10)

					BallGui.Size = UDim2.new(0, boxPx, 0, boxPx)
					BallGui.Adornee = visBall
					BallGui.Enabled = true
					BoxStroke.Thickness = Options.BoxThickness and Options.BoxThickness.Value or 5
					DistLabel.Text = math.floor((visBall.Position - myRoot.Position).Magnitude) .. "m"
				end
			else
				BallGui.Enabled = false
			end

			-- Target nametag
			if realBall and realBall.Parent and ToggleOn("TargetTag") and visBall then
				local targetName = realBall:GetAttribute("target")
				if targetName and targetName ~= "" then
					TargetTag.Adornee = visBall
					TargetTag.Enabled = true
					if targetName == LocalPlayer.Name then
						TargetLabel.Text = "YOU!!!"
						TargetLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
					else
						TargetLabel.Text = targetName
						TargetLabel.TextColor3 = PINK
					end
				else
					TargetTag.Enabled = false
				end
			else
				TargetTag.Enabled = false
			end

			-- Velocity display (read from realBall)
			if visBall and visBall.Parent and ToggleOn("VelocityTag") and realBall then
				local vel = realBall.AssemblyLinearVelocity.Magnitude
				VelTag.Adornee = visBall
				VelTag.Enabled = true
				VelLabel.Text = math.floor(vel) .. " studs/s"
				if vel > 200 then
					VelLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
				elseif vel > 100 then
					VelLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
				else
					VelLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
				end
			else
				VelTag.Enabled = false
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- AUTO PARRY (targeting-based)
-- ═══════════════════════════════════════════════════════════

local lastParryTime = 0

local ClashHeld = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	pcall(function()
		local kp = Options.ClashKeybind
		if kp and kp.Value and typeof(kp.Value) == "string" and kp.Value ~= "None" and kp.Value ~= "Unknown" then
			if input.KeyCode == Enum.KeyCode[kp.Value] then
				local toggle = Toggles.ClashMode
				if toggle then
					toggle:SetValue(not toggle.Value)
				end
			end
		end
	end)
end)

spawn(function()
	wait(1)
	while true do
		wait(0.01)
		pcall(function()
			local realBall = GetRealBall()
			local visBall = GetVisibleBall()
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not realBall or not visBall or not myRoot then return end

			local targetName = realBall:GetAttribute("target")
			if targetName ~= LocalPlayer.Name then return end

			local dist = (visBall.Position - myRoot.Position).Magnitude
			local now = tick()

			if ToggleOn("AutoParry") then
				local baseDist = Options.ParryDist and Options.ParryDist.Value or 30
				local baseCD = Options.ParryCooldown and Options.ParryCooldown.Value or 350

				-- Faster ball = parry from much further away
				local speed = realBall.AssemblyLinearVelocity.Magnitude
				local adaptiveDist = math.clamp(baseDist + (speed / 3), baseDist, 150)

				if dist < adaptiveDist and (now - lastParryTime) * 1000 > baseCD then
					mouse1click()
					lastParryTime = now
				end
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- PLAYER ESP (no flicker)
-- ═══════════════════════════════════════════════════════════

local function AddHighlight(character)
	if not character then return end
	if character:FindFirstChild("IvoryHighlight") then return end
	local hl = Instance.new("Highlight")
	hl.Name = "IvoryHighlight"
	hl.FillColor = PURPLE
	hl.OutlineColor = PURPLE
	hl.FillTransparency = 0.6
	hl.OutlineTransparency = 0
	hl.Adornee = character
	hl.Parent = character
end

local function RemoveHighlight(character)
	if not character then return end
	local hl = character:FindFirstChild("IvoryHighlight")
	if hl then hl:Destroy() end
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr ~= LocalPlayer and plr.Character then
		AddHighlight(plr.Character)
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		wait(1)
		if ToggleOn("PlayerESP") then
			AddHighlight(char)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(plr)
	if plr.Character then
		RemoveHighlight(plr.Character)
	end
end)

local lastPlayerESPState = nil
spawn(function()
	wait(2)
	while true do
		wait(2)
		pcall(function()
			local on = ToggleOn("PlayerESP")
			if on == lastPlayerESPState then return end
			lastPlayerESPState = on
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character then
					if on then
						AddHighlight(plr.Character)
					else
						RemoveHighlight(plr.Character)
					end
				end
			end
		end)
	end
end)

spawn(function()
	while true do
		wait(0.1)
		pcall(function()
			if Toggles.ClashMode and Toggles.ClashMode.Value then
				if isrbxactive() then
					-- Don't click if mouse is over the menu
					local mouseOverMenu = false
					pcall(function()
						local mousePos = UserInputService:GetMouseLocation()
						local guiObjects = game:GetService("CoreGui"):GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
						for _, obj in ipairs(guiObjects) do
							if obj:FindFirstAncestor("Obsidian") then
								mouseOverMenu = true
								break
							end
						end
					end)
					if not mouseOverMenu then
						local cps = Options.ClashCPS and Options.ClashCPS.Value or 30
						local interval = math.max(1 / cps, 0.016)
						mouse1click()
						wait(interval)
					end
				end
			end
		end)
	end
end)

print("[Ivory Hub] Blade Ball loaded!")
print("[Ivory Hub] Made by mommy veqxo <3")
