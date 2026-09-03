-- Murder Mystery 2 | ObsidianUltra UI
-- Pink Neon Theme | v4.0

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

Library.Scheme.MainColor = Color3.fromRGB(30, 20, 30)
Library.Scheme.AccentColor = Color3.fromRGB(255, 105, 180)
Library.Scheme.AcccentDark = Color3.fromRGB(200, 80, 150)
Library.Scheme.OutlineColor = Color3.fromRGB(80, 40, 70)
Library.Scheme.FontColor = Color3.fromRGB(255, 220, 240)
Library.Scheme.SubText = Color3.fromRGB(180, 140, 170)
Library.Scheme.Bright = Color3.fromRGB(45, 30, 50)
Library.Scheme.Dark = Color3.fromRGB(20, 12, 22)
Library.Scheme.Risky = Color3.fromRGB(255, 50, 100)

Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Ivory | MM2",
	Icon = "swords",
	NotifySide = "Right",
	ShowCustomCursor = false,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	MinimizedWidth = 280,
	Footer = { "MM2 |", { Text = "v4.0", Copyable = true } },
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	SearchKeybind = Enum.KeyCode.F,
})
--// Patch window icon to use custom image
local IVORY_ICON = "rbxassetid://113133903091338"
task.spawn(function()
	task.wait()
	local function trySetIcon(parent)
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("ImageLabel") and obj.Size.X.Offset >= 20 and obj.Size.X.Offset <= 40 and obj.Size.Y.Offset >= 20 and obj.Size.Y.Offset <= 40 then
						local par = obj.Parent
						if par then
							for _, sib in ipairs(par:GetChildren()) do
								if sib:IsA("TextLabel") and sib.Text == "Ivory" then
									obj.Image = IVORY_ICON
									obj.ImageRectOffset = Vector2.new(0, 0)
									obj.ImageRectSize = Vector2.new(0, 0)
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end
	pcall(function() trySetIcon(CoreGui) end)
	pcall(function() trySetIcon(LocalPlayer.PlayerGui) end)
end)

local Tabs = {
	Main = Window:AddTab({ Name = "ESP", Icon = "swords", Description = "Boxes, Names, Roles" }),
	Visuals = Window:AddTab({ Name = "Visuals", Icon = "swords", Description = "Highlights & X-Ray" }),
	Aim = Window:AddTab({ Name = "Aim", Icon = "swords", Description = "Aimbot" }),
	Settings = Window:AddTab({ Name = "Settings", Icon = "swords", Description = "UI & Config" }),
}

local State = {
	ESP_Enabled = false,
	ESP_Box = true,
	ESP_Name = true,
	ESP_Distance = true,
	ESP_Role = true,
	ESP_Tracer = false,
	ESP_XRay = false,
	BoxThickness = 2,
	TextSize = 16,
	BoxWidthScale = 0.65,
	Color_Box = Color3.fromRGB(255, 105, 180),
	Color_Name = Color3.fromRGB(255, 220, 240),
	Color_Distance = Color3.fromRGB(180, 140, 170),
	Color_Tracer = Color3.fromRGB(255, 105, 180),
	Highlight_Enabled = false,
	Highlight_Mode = "Full Body",
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Depth = false,
	Highlight_Self = false,
	Color_Innocent = Color3.fromRGB(255, 105, 180),
	Color_Sheriff = Color3.fromRGB(255, 230, 50),
	Color_Murderer = Color3.fromRGB(255, 50, 50),
	RoleRevealer = false,
	Aimbot = false,
	Aimbot_FOV = 100,
	Aimbot_Smooth = 5,
	Aimbot_OnlyMurderer = true,
	Aimbot_WallCheck = true,
	Aimbot_Prediction = true,
	Aimbot_PredictionOffset = 0.5,
	Aimbot_FOV_Circle = true,
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = State.Aimbot_FOV
FOVCircle.Filled = false
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 105, 180)
FOVCircle.Transparency = 0.8

local CurrentRoundClient = require(game.ReplicatedStorage.Modules.CurrentRoundClient)

local function getRole(player)
	local pd = CurrentRoundClient.PlayerData
	if pd and pd[player.Name] and pd[player.Name].Role then
		return pd[player.Name].Role
	end
	return "Innocent"
end

pcall(function()
	game.ReplicatedStorage.Remotes.Gameplay.PlayerDataChanged.OnClientEvent:Connect(function(data)
		CurrentRoundClient.PlayerData = data
	end)
end)

local function getRoleColor(role)
	role = role:lower()
	if role == "murderer" or role == "murder" then
		return State.Color_Murderer
	elseif role == "sheriff" then
		return State.Color_Sheriff
	end
	return State.Color_Innocent
end

local function worldToScreen(position)
	local screenPos, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local DiscordGroup = Tabs.Main:AddLeftGroupbox("Community", "users")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function() game:GetService("GuiService"):OpenBrowserWindow("https://discord.gg/ivory") end)
end)
DiscordGroup:AddLabel("Click above to join our Discord for dupes, updates & more!")

local ESPGroup = Tabs.Main:AddLeftGroupbox("ESP Controls", "eye")

ESPGroup:AddToggle("ESP Enabled", {
	Text = "Enable ESP", Default = false,
	Callback = function(v) State.ESP_Enabled = v end,
})
ESPGroup:AddToggle("ESP Box", {
	Text = "Show Box", Default = true,
	Callback = function(v) State.ESP_Box = v end,
})
ESPGroup:AddToggle("ESP Name", {
	Text = "Show Name", Default = true,
	Callback = function(v) State.ESP_Name = v end,
})
ESPGroup:AddToggle("ESP Distance", {
	Text = "Show Distance", Default = true,
	Callback = function(v) State.ESP_Distance = v end,
})
ESPGroup:AddToggle("ESP Role", {
	Text = "Show Role", Default = true,
	Callback = function(v) State.ESP_Role = v end,
})
ESPGroup:AddToggle("ESP Tracer", {
	Text = "Show Tracer Line", Default = false,
	Callback = function(v) State.ESP_Tracer = v end,
})
ESPGroup:AddToggle("ESP XRay", {
	Text = "X-Ray (Through Walls)", Default = false,
	Callback = function(v) State.ESP_XRay = v end,
})

local ESPStyle = Tabs.Main:AddLeftGroupbox("ESP Style", "sliders")

ESPStyle:AddSlider("BoxThickness", {
	Text = "Box Thickness", Default = 2, Min = 1, Max = 5, Rounding = 0,
	Callback = function(v) State.BoxThickness = v end,
})
ESPStyle:AddSlider("TextSize", {
	Text = "Text Size", Default = 16, Min = 10, Max = 30, Rounding = 0,
	Callback = function(v) State.TextSize = v end,
})
ESPStyle:AddSlider("BoxWidthScale", {
	Text = "Box Width", Default = 65, Min = 40, Max = 100, Rounding = 0,
	Callback = function(v) State.BoxWidthScale = v / 100 end,
})

local ESPColors = Tabs.Main:AddRightGroupbox("ESP Colors", "palette")

ESPColors:AddLabel("Box Color"):AddColorPicker("ColorBox", {
	Default = Color3.fromRGB(255, 105, 180), Title = "Box",
	Callback = function(v) State.Color_Box = v end,
})
ESPColors:AddLabel("Name Color"):AddColorPicker("ColorName", {
	Default = Color3.fromRGB(255, 220, 240), Title = "Name",
	Callback = function(v) State.Color_Name = v end,
})
ESPColors:AddLabel("Distance Color"):AddColorPicker("ColorDistance", {
	Default = Color3.fromRGB(180, 140, 170), Title = "Distance",
	Callback = function(v) State.Color_Distance = v end,
})
ESPColors:AddLabel("Tracer Color"):AddColorPicker("ColorTracer", {
	Default = Color3.fromRGB(255, 105, 180), Title = "Tracer",
	Callback = function(v) State.Color_Tracer = v end,
})

local RolesGroup = Tabs.Main:AddRightGroupbox("Role Revealer", "users")
RolesGroup:AddToggle("RoleRevealer", {
	Text = "Show Roles", Default = false,
	Callback = function(v) State.RoleRevealer = v end,
})
RolesGroup:AddLabel("Shows each player's role above their head.")

local HighlightGroup = Tabs.Visuals:AddLeftGroupbox("Highlights", "highlighter")

HighlightGroup:AddToggle("Highlight Enabled", {
	Text = "Enable Highlights", Default = false,
	Callback = function(v)
		State.Highlight_Enabled = v
		if not v then
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character then
					local hl = player.Character:FindFirstChild("MM2Highlight")
					if hl then hl:Destroy() end
				end
			end
		end
	end,
})
HighlightGroup:AddDropdown("HighlightMode", {
	Values = { "Full Body", "Outline Only" }, Default = "Full Body", Text = "Highlight Mode",
	Callback = function(v) State.Highlight_Mode = v end,
})
HighlightGroup:AddToggle("Highlight Depth", {
	Text = "Occluded (Through Walls)", Default = false,
	Callback = function(v) State.Highlight_Depth = v end,
})
HighlightGroup:AddToggle("Highlight Self", {
	Text = "Highlight Yourself", Default = false,
	Callback = function(v) State.Highlight_Self = v end,
})

local HighlightStyle = Tabs.Visuals:AddRightGroupbox("Highlight Colors", "palette")

HighlightStyle:AddLabel("Innocent Color"):AddColorPicker("ColorInnocent", {
	Default = Color3.fromRGB(255, 105, 180), Title = "Innocent",
	Callback = function(v) State.Color_Innocent = v end,
})
HighlightStyle:AddLabel("Sheriff Color"):AddColorPicker("ColorSheriff", {
	Default = Color3.fromRGB(255, 230, 50), Title = "Sheriff",
	Callback = function(v) State.Color_Sheriff = v end,
})
HighlightStyle:AddLabel("Murderer Color"):AddColorPicker("ColorMurderer", {
	Default = Color3.fromRGB(255, 50, 50), Title = "Murderer",
	Callback = function(v) State.Color_Murderer = v end,
})
HighlightStyle:AddSlider("FillTransparency", {
	Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.Highlight_FillTransparency = v / 100 end,
})
HighlightStyle:AddSlider("OutlineTransparency", {
	Text = "Outline Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0,
	Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end,
})

local AimbotGroup = Tabs.Aim:AddLeftGroupbox("Aimbot", "crosshair")

AimbotGroup:AddToggle("Aimbot", {
	Text = "Enable Aimbot", Default = false,
	Callback = function(v) State.Aimbot = v end,
})
AimbotGroup:AddToggle("Aimbot Hold", {
	Text = "Hold Aimbot", Default = false,
	Callback = function(v) State.Aimbot = v end,
})
AimbotGroup:AddLabel("Aimbot Keybind"):AddKeyPicker("AimbotKeybind", {
	Default = "MouseButton2", NoUI = true, Text = "Aimbot Key",
})
AimbotGroup:AddSlider("AimbotFOV", {
	Text = "FOV (px)", Default = 100, Min = 20, Max = 500, Rounding = 0,
	Callback = function(v) State.Aimbot_FOV = v end,
})
AimbotGroup:AddInput("AimbotFOVInput", {
	Text = "FOV Value", Default = "100", Placeholder = "Type a number",
	Callback = function(v)
		local num = tonumber(v)
		if num then
			State.Aimbot_FOV = math.clamp(num, 20, 500)
		end
	end,
})
AimbotGroup:AddSlider("AimbotSmooth", {
	Text = "Smoothing", Default = 5, Min = 1, Max = 20, Rounding = 0,
	Callback = function(v) State.Aimbot_Smooth = v end,
})
AimbotGroup:AddToggle("AimbotOnlyMurderer", {
	Text = "Only Target Murderer", Default = true,
	Callback = function(v) State.Aimbot_OnlyMurderer = v end,
})
AimbotGroup:AddToggle("AimbotWallCheck", {
	Text = "Wall Check", Default = true,
	Callback = function(v) State.Aimbot_WallCheck = v end,
})
AimbotGroup:AddToggle("AimbotPrediction", {
	Text = "Predict Movement", Default = true,
	Callback = function(v) State.Aimbot_Prediction = v end,
})
AimbotGroup:AddSlider("AimbotPredOffset", {
	Text = "Prediction Lead", Default = 5, Min = 0, Max = 50, Rounding = 0,
	Callback = function(v) State.Aimbot_PredictionOffset = v / 10 end,
})
AimbotGroup:AddToggle("AimbotFOVCircle", {
	Text = "Show FOV Circle", Default = true,
	Callback = function(v) State.Aimbot_FOV_Circle = v end,
})

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu",
	Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor", Default = Library.ShowCustomCursor,
	Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "75%", "100%", "125%", "150%" }, Default = "100%", Text = "DPI Scale",
	Callback = function(Value) Library:SetDPIScale(tonumber(Value:gsub("%%", ""))) end,
})
MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius", Default = 8, Min = 0, Max = 20, Rounding = 0,
	Callback = function(value) Window:SetCornerRadius(value) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu: RightShift (default)"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
local creditLabel = MenuGroup:AddLabel("Made by mommy Veqxo < / 3")
pcall(function()
	local tl = creditLabel.TextLabel
	if tl then
		tl.TextColor3 = Color3.fromRGB(255, 20, 147)
		tl.TextSize = 18
		tl.Font = Enum.Font.GothamBold
		tl.TextXAlignment = Enum.TextXAlignment.Center
	end
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MM2Script")
SaveManager:SetFolder("MM2Script/configs")
SaveManager:BuildConfigSection(Tabs["Settings"])
ThemeManager:ApplyToTab(Tabs["Settings"])
SaveManager:LoadAutoloadConfig()

local espObjects = {}

local function createESP(player)
	if player == LocalPlayer then return end
	local esp = {
		Box = Drawing.new("Square"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Role = Drawing.new("Text"),
		Tracer = Drawing.new("Line"),
	}
	esp.Box.Thickness = State.BoxThickness
	esp.Box.Filled = false
	esp.Name.Size = State.TextSize
	esp.Name.Center = true
	esp.Name.Outline = true
	esp.Name.Font = Drawing.Fonts.UI
	esp.Distance.Size = State.TextSize - 2
	esp.Distance.Center = true
	esp.Distance.Outline = true
	esp.Distance.Font = Drawing.Fonts.UI
	esp.Role.Size = State.TextSize - 1
	esp.Role.Center = true
	esp.Role.Outline = true
	esp.Role.Font = Drawing.Fonts.UI
	esp.Tracer.Thickness = 1
	esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
	espObjects[player] = esp
end

local function removeESP(player)
	if espObjects[player] then
		for _, obj in pairs(espObjects[player]) do obj:Remove() end
		espObjects[player] = nil
	end
end

for _, player in ipairs(Players:GetPlayers()) do createESP(player) end
Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

local function applyHighlight(player)
	if player == LocalPlayer and not State.Highlight_Self then return end
	if not player.Character then return end
	local hl = player.Character:FindFirstChild("MM2Highlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "MM2Highlight"
		hl.Parent = player.Character
	end
	local role = getRole(player)
	local color = getRoleColor(role)
	hl.FillColor = color
	hl.OutlineColor = color
	hl.Adornee = player.Character
	if State.Highlight_Mode == "Full Body" then
		hl.FillTransparency = State.Highlight_FillTransparency
		hl.OutlineTransparency = State.Highlight_OutlineTransparency
	else
		hl.FillTransparency = 1
		hl.OutlineTransparency = State.Highlight_OutlineTransparency
	end
	hl.DepthMode = State.Highlight_Depth and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
	hl.Enabled = State.Highlight_Enabled
end

local function removeHighlight(player)
	if player.Character then
		local hl = player.Character:FindFirstChild("MM2Highlight")
		if hl then hl:Destroy() end
	end
end

local aimbotKeyDown = false
local aimbotBindType = "Mouse"
local aimbotBindCode = Enum.UserInputType.MouseButton2

local function updateAimbotBind()
	local ok, val = pcall(function() return Options.AimbotKeybind.Value end)
	if ok and val and val ~= "" then
		if val:find("MouseButton") then
			aimbotBindType = "Mouse"
			aimbotBindCode = Enum.UserInputType[val]
		else
			aimbotBindType = "Keyboard"
			aimbotBindCode = Enum.KeyCode[val]
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if aimbotBindType == "Keyboard" and input.KeyCode == aimbotBindCode then
		aimbotKeyDown = true
	elseif aimbotBindType == "Mouse" and input.UserInputType == aimbotBindCode then
		aimbotKeyDown = true
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if aimbotBindType == "Keyboard" and input.KeyCode == aimbotBindCode then
		aimbotKeyDown = false
	elseif aimbotBindType == "Mouse" and input.UserInputType == aimbotBindCode then
		aimbotKeyDown = false
	end
end)

local function isPartVisible(targetPart)
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin)
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {LocalPlayer.Character, targetPart.Parent}
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(origin, direction, rayParams) == nil
end

local function getNearestTarget()
	local closestPlayer = nil
	local closestDist = State.Aimbot_FOV
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local role = getRole(player)
			if not State.Aimbot_OnlyMurderer or role:lower():find("murder") then
				if not State.Aimbot_WallCheck or isPartVisible(player.Character.HumanoidRootPart) then
					local pos = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
					local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
					if dist < closestDist then
						closestDist = dist
						closestPlayer = player
					end
				end
			end
		end
	end
	return closestPlayer
end

local xrayOriginals = {}
local xrayEnabled = false

local function enableXRay()
	if xrayEnabled then return end
	xrayEnabled = true
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not obj:IsA("Terrain") and not obj:FindFirstChild("MM2Highlight") then
			if not xrayOriginals[obj] then
				xrayOriginals[obj] = obj.LocalTransparencyModifier
			end
			obj.LocalTransparencyModifier = 0.7
		end
	end
end

local function disableXRay()
	if not xrayEnabled then return end
	xrayEnabled = false
	for obj, mod in pairs(xrayOriginals) do
		if obj and obj.Parent then
			obj.LocalTransparencyModifier = mod
		end
	end
	xrayOriginals = {}
end

RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera
	updateAimbotBind()

	if State.ESP_XRay then
		enableXRay()
	else
		disableXRay()
	end

	if State.Highlight_Enabled and State.Highlight_Self then
		applyHighlight(LocalPlayer)
	elseif not State.Highlight_Self then
		removeHighlight(LocalPlayer)
	end

	if State.Aimbot_FOV_Circle and State.Aimbot then
		FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		FOVCircle.Radius = State.Aimbot_FOV
		FOVCircle.Visible = true
	else
		FOVCircle.Visible = false
	end

	if State.Aimbot and aimbotKeyDown then
		local target = getNearestTarget()
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
			local hrp = target.Character.HumanoidRootPart
			local targetPos = hrp.Position
			if State.Aimbot_Prediction then
				targetPos = targetPos + hrp.CFrame.LookVector * State.Aimbot_PredictionOffset
			end
			Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Camera.CFrame.Position, targetPos), 1 / State.Aimbot_Smooth)
		end
	end

	for player, esp in pairs(espObjects) do
		local show = State.ESP_Enabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0

		if State.Highlight_Enabled then applyHighlight(player) else removeHighlight(player) end

		if show then
			local hrp = player.Character.HumanoidRootPart
			local _, onScreen, dist = worldToScreen(hrp.Position)
			if onScreen and dist > 0 then
				local rootPos = Camera:WorldToViewportPoint(hrp.Position)
				local headPos = Camera:WorldToViewportPoint(hrp.Position + Vector3.new(0, 2.5, 0))
				local boxHeight = math.abs(rootPos.Y - headPos.Y) * 2.2
				local boxWidth = boxHeight * State.BoxWidthScale
				local role = getRole(player)
				local color = getRoleColor(role)

				esp.Box.Size = Vector2.new(boxWidth, boxHeight)
				esp.Box.Position = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)
				esp.Box.Thickness = State.BoxThickness
				esp.Box.Color = color
				esp.Box.Visible = State.ESP_Box

				esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 20)
				esp.Name.Text = player.DisplayName
				esp.Name.Size = State.TextSize
				esp.Name.Color = color
				esp.Name.Visible = State.ESP_Name

				esp.Distance.Position = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2 + 6)
				esp.Distance.Text = math.floor(dist) .. "m"
				esp.Distance.Size = State.TextSize - 2
				esp.Distance.Color = State.Color_Distance
				esp.Distance.Visible = State.ESP_Distance

				esp.Role.Position = Vector2.new(rootPos.X, rootPos.Y - boxHeight / 2 - 38)
				esp.Role.Text = role
				esp.Role.Color = color
				esp.Role.Size = State.TextSize - 1
				esp.Role.Visible = State.ESP_Role or State.RoleRevealer

				esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
				esp.Tracer.To = Vector2.new(rootPos.X, rootPos.Y + boxHeight / 2)
				esp.Tracer.Color = color
				esp.Tracer.Visible = State.ESP_Tracer
			else
				esp.Box.Visible = false
				esp.Name.Visible = false
				esp.Distance.Visible = false
				esp.Role.Visible = false
				esp.Tracer.Visible = false
			end
		else
			esp.Box.Visible = false
			esp.Name.Visible = false
			esp.Distance.Visible = false
			esp.Role.Visible = false
			esp.Tracer.Visible = false
		end
	end
end)

Library:OnUnload(function()
	FOVCircle:Remove()
	disableXRay()
	for player, _ in pairs(espObjects) do removeESP(player) end
	espObjects = {}
	for _, player in ipairs(Players:GetPlayers()) do removeHighlight(player) end
	removeHighlight(LocalPlayer)
end)

print("[Ivory] v4.0 loaded")
