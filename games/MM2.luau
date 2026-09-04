-- Murder Mystery 2 | Ivory Hub Sakura Edition
-- Pink Neon Theme | v4.0

local LIB_SRC = getgenv()._IvoryLibSrc
if not LIB_SRC then
	local ok, src = pcall(function()
		return request({
			Url = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua",
			Method = "GET"
		}).Body
	end)
	if ok then LIB_SRC = src end
end
local Library = loadstring(LIB_SRC)()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Window = Library.CreateWindow({
	Name = "Ivory | MM2",
	Width = 460,
	Height = 360,
	NotifySide = "Right",
	ShowCustomCursor = false,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	MinimizedWidth = 280,
	FuzzySearch = true,
	SearchValues = true,
	SearchKeybind = Enum.KeyCode.F,
})

local Tabs = {
	Main = Window:CreateTab({ Name = "ESP" }),
	Visuals = Window:CreateTab({ Name = "Visuals" }),
	Aim = Window:CreateTab({ Name = "Aim" }),
	Settings = Window:CreateTab({ Name = "Settings" }),
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

local DiscordSection = Tabs.Main:CreateSection("Community")
DiscordSection:CreateButton({Name = "Join Discord For Dupe", Callback = function()
	pcall(function() game:GetService("GuiService"):OpenBrowserWindow("https://discord.gg/ivory") end)
end})
DiscordSection:CreateLabel("Click above to join our Discord for dupes, updates & more!")

local ESPSection = Tabs.Main:CreateSection("ESP Controls")

ESPSection:CreateToggle({
	Name = "Enable ESP",
	CurrentValue = false,
	Callback = function(v) State.ESP_Enabled = v end,
})
ESPSection:CreateToggle({
	Name = "Show Box",
	CurrentValue = true,
	Callback = function(v) State.ESP_Box = v end,
})
ESPSection:CreateToggle({
	Name = "Show Name",
	CurrentValue = true,
	Callback = function(v) State.ESP_Name = v end,
})
ESPSection:CreateToggle({
	Name = "Show Distance",
	CurrentValue = true,
	Callback = function(v) State.ESP_Distance = v end,
})
ESPSection:CreateToggle({
	Name = "Show Role",
	CurrentValue = true,
	Callback = function(v) State.ESP_Role = v end,
})
ESPSection:CreateToggle({
	Name = "Show Tracer Line",
	CurrentValue = false,
	Callback = function(v) State.ESP_Tracer = v end,
})
ESPSection:CreateToggle({
	Name = "X-Ray (Through Walls)",
	CurrentValue = false,
	Callback = function(v) State.ESP_XRay = v end,
})

local ESPStyleSection = Tabs.Main:CreateSection("ESP Style")

ESPStyleSection:CreateSlider({
	Name = "Box Thickness",
	Range = {1, 5},
	Increment = 1,
	CurrentValue = 2,
	Callback = function(v) State.BoxThickness = v end,
})
ESPStyleSection:CreateSlider({
	Name = "Text Size",
	Range = {10, 30},
	Increment = 1,
	CurrentValue = 16,
	Callback = function(v) State.TextSize = v end,
})
ESPStyleSection:CreateSlider({
	Name = "Box Width",
	Range = {40, 100},
	Increment = 1,
	CurrentValue = 65,
	Callback = function(v) State.BoxWidthScale = v / 100 end,
})

local ESPColorsSection = Tabs.Main:CreateSection("ESP Colors")

ESPColorsSection:CreateColorPicker({
	Name = "Box",
	Color = Color3.fromRGB(255, 105, 180),
	Callback = function(v) State.Color_Box = v end,
})
ESPColorsSection:CreateColorPicker({
	Name = "Name",
	Color = Color3.fromRGB(255, 220, 240),
	Callback = function(v) State.Color_Name = v end,
})
ESPColorsSection:CreateColorPicker({
	Name = "Distance",
	Color = Color3.fromRGB(180, 140, 170),
	Callback = function(v) State.Color_Distance = v end,
})
ESPColorsSection:CreateColorPicker({
	Name = "Tracer",
	Color = Color3.fromRGB(255, 105, 180),
	Callback = function(v) State.Color_Tracer = v end,
})

local RolesSection = Tabs.Main:CreateSection("Role Revealer")
RolesSection:CreateToggle({
	Name = "Show Roles",
	CurrentValue = false,
	Callback = function(v) State.RoleRevealer = v end,
})
RolesSection:CreateLabel("Shows each player's role above their head.")

local HighlightSection = Tabs.Visuals:CreateSection("Highlights")

HighlightSection:CreateToggle({
	Name = "Enable Highlights",
	CurrentValue = false,
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
HighlightSection:CreateDropdown({
	Name = "Highlight Mode",
	Options = { "Full Body", "Outline Only" },
	CurrentOption = "Full Body",
	Callback = function(v) State.Highlight_Mode = v end,
})
HighlightSection:CreateToggle({
	Name = "Occluded (Through Walls)",
	CurrentValue = false,
	Callback = function(v) State.Highlight_Depth = v end,
})
HighlightSection:CreateToggle({
	Name = "Highlight Yourself",
	CurrentValue = false,
	Callback = function(v) State.Highlight_Self = v end,
})

local HighlightColorsSection = Tabs.Visuals:CreateSection("Highlight Colors")

HighlightColorsSection:CreateColorPicker({
	Name = "Innocent",
	Color = Color3.fromRGB(255, 105, 180),
	Callback = function(v) State.Color_Innocent = v end,
})
HighlightColorsSection:CreateColorPicker({
	Name = "Sheriff",
	Color = Color3.fromRGB(255, 230, 50),
	Callback = function(v) State.Color_Sheriff = v end,
})
HighlightColorsSection:CreateColorPicker({
	Name = "Murderer",
	Color = Color3.fromRGB(255, 50, 50),
	Callback = function(v) State.Color_Murderer = v end,
})
HighlightColorsSection:CreateSlider({
	Name = "Fill Transparency",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 50,
	Callback = function(v) State.Highlight_FillTransparency = v / 100 end,
})
HighlightColorsSection:CreateSlider({
	Name = "Outline Transparency",
	Range = {0, 100},
	Increment = 1,
	CurrentValue = 0,
	Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end,
})

local AimbotSection = Tabs.Aim:CreateSection("Aimbot")

AimbotSection:CreateToggle({
	Name = "Enable Aimbot",
	CurrentValue = false,
	Callback = function(v) State.Aimbot = v end,
})
AimbotSection:CreateToggle({
	Name = "Hold Aimbot",
	CurrentValue = false,
	Callback = function(v) State.Aimbot = v end,
})
AimbotSection:CreateKeybind({
	Name = "Aimbot Key",
	CurrentKeybind = "MouseButton2",
})
AimbotSection:CreateSlider({
	Name = "FOV (px)",
	Range = {20, 500},
	Increment = 1,
	CurrentValue = 100,
	Callback = function(v) State.Aimbot_FOV = v end,
})
AimbotSection:CreateTextBox({
	Name = "FOV Value",
	CurrentValue = "100",
	Placeholder = "Type a number",
	Callback = function(v)
		local num = tonumber(v)
		if num then
			State.Aimbot_FOV = math.clamp(num, 20, 500)
		end
	end,
})
AimbotSection:CreateSlider({
	Name = "Smoothing",
	Range = {1, 20},
	Increment = 1,
	CurrentValue = 5,
	Callback = function(v) State.Aimbot_Smooth = v end,
})
AimbotSection:CreateToggle({
	Name = "Only Target Murderer",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_OnlyMurderer = v end,
})
AimbotSection:CreateToggle({
	Name = "Wall Check",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_WallCheck = v end,
})
AimbotSection:CreateToggle({
	Name = "Predict Movement",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_Prediction = v end,
})
AimbotSection:CreateSlider({
	Name = "Prediction Lead",
	Range = {0, 50},
	Increment = 1,
	CurrentValue = 5,
	Callback = function(v) State.Aimbot_PredictionOffset = v / 10 end,
})
AimbotSection:CreateToggle({
	Name = "Show FOV Circle",
	CurrentValue = true,
	Callback = function(v) State.Aimbot_FOV_Circle = v end,
})

local MenuSection = Tabs.Settings:CreateSection("Menu")

MenuSection:CreateToggle({
	Name = "Open Keybind Menu",
	CurrentValue = Library.KeybindFrame.Visible,
	Callback = function(value) Library.KeybindFrame.Visible = value end,
})
MenuSection:CreateToggle({
	Name = "Custom Cursor",
	CurrentValue = Library.ShowCustomCursor,
	Callback = function(Value) Library.ShowCustomCursor = Value end,
})
MenuSection:CreateDropdown({
	Name = "DPI Scale",
	Options = { "75%", "100%", "125%", "150%" },
	CurrentOption = "100%",
	Callback = function(Value) Library:SetDPIScale(tonumber(Value:gsub("%%", ""))) end,
})
MenuSection:CreateSlider({
	Name = "Corner Radius",
	Range = {0, 20},
	Increment = 1,
	CurrentValue = 8,
	Callback = function(value) Window:SetCornerRadius(value) end,
})
MenuSection:CreateDivider()
MenuSection:CreateKeybind({
	Name = "Menu keybind",
	CurrentKeybind = "RightShift",
})
MenuSection:CreateButton({Name = "Unload", Callback = function() Library:Unload() end})
MenuSection:CreateLabel("Made by mommy Veqxo < / 3")

Library.ToggleKeybind = Options.MenuKeybind

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

FOVCircle:Remove()
disableXRay()
for player, _ in pairs(espObjects) do removeESP(player) end
espObjects = {}
for _, player in ipairs(Players:GetPlayers()) do removeHighlight(player) end
removeHighlight(LocalPlayer)

print("[Ivory] v4.0 loaded")
