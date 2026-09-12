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

local httpGet = function(url)
	local ok, res = pcall(function()
		return request({ Url = url, Method = "GET" })
	end)
	if ok and res and res.Body then
		local body = res.Body
		if body:byte(1) == 0xEF and body:byte(2) == 0xBB and body:byte(3) == 0xBF then
			body = body:sub(4)
		end
		return body
	end
	return nil
end

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
    writefile(LIB_FILE, httpGet(LIB_URL))
end
local Library = loadstring(game:HttpGet(getcustomasset(LIB_FILE), true))()

local Window = Library.CreateWindow({ Name = "Blade Ball" })

local CombatTab = Window:CreateTab("Combat")
local ESPTab = Window:CreateTab("ESP")
local SettingsTab = Window:CreateTab("Settings")

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════

CombatTab:CreateSection("Disclaimer")
CombatTab:CreateLabel("!! Works best at 50 ping or under !!")
CombatTab:CreateLabel("!! Keep Roblox focused for auto parry !!")
CombatTab:CreateDivider()

CombatTab:CreateSection("Auto Parry")

local AutoParryToggle = CombatTab:CreateToggle({
	Name = "Auto Parry",
	CurrentValue = true,
	TrackActive = true,
	Flag = "AutoParry",
})

local ParryDistSlider = CombatTab:CreateSlider({
	Name = "Parry Distance",
	Range = { 8, 60 },
	Increment = 1,
	CurrentValue = 30,
	Flag = "ParryDist",
})

local ParryCooldownSlider = CombatTab:CreateSlider({
	Name = "Cooldown (ms)",
	Range = { 100, 600 },
	Increment = 10,
	CurrentValue = 350,
	Flag = "ParryCooldown",
})

local PingPresetDropdown = CombatTab:CreateDropdown({
	Name = "Your Ping Range",
	Options = { "50", "75", "100", "125", "150", "175", "200+" },
	CurrentOption = "50",
	Flag = "PingPreset",
})

CombatTab:CreateButton({
	Name = "Apply Preset",
	Callback = function()
		local ping = Library.Flags.PingPreset and Library.Flags.PingPreset.Value
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
			if Library.Flags.ParryDist then Library.Flags.ParryDist:Set(p.dist) end
			if Library.Flags.ParryCooldown then Library.Flags.ParryCooldown:Set(p.cd) end
		end
	end,
})

CombatTab:CreateDivider()
CombatTab:CreateSection("Clash")

local ClashModeToggle = CombatTab:CreateToggle({
	Name = "Clash Mode",
	CurrentValue = false,
	TrackActive = true,
	Flag = "ClashMode",
})

CombatTab:CreateKeybind({
	Name = "Clash Keybind",
	CurrentKeybind = "V",
	Flag = "ClashKeybind",
	ChangedCallback = function(key) end,
})

CombatTab:CreateSlider({
	Name = "Clash CPS",
	Range = { 10, 60 },
	Increment = 1,
	CurrentValue = 30,
	Flag = "ClashCPS",
})

-- ═══════════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════════

ESPTab:CreateSection("Ball ESP")

ESPTab:CreateToggle({
	Name = "Ball ESP",
	CurrentValue = true,
	TrackActive = true,
	Flag = "BallESP",
})

ESPTab:CreateToggle({
	Name = "Target Nametag",
	CurrentValue = true,
	TrackActive = true,
	Flag = "TargetTag",
})

ESPTab:CreateToggle({
	Name = "Velocity Display",
	CurrentValue = true,
	TrackActive = true,
	Flag = "VelocityTag",
})

ESPTab:CreateSlider({
	Name = "Box Thickness",
	Range = { 1, 10 },
	Increment = 1,
	CurrentValue = 5,
	Flag = "BoxThickness",
})

ESPTab:CreateSlider({
	Name = "Box Padding",
	Range = { 0, 30 },
	Increment = 1,
	CurrentValue = 10,
	Flag = "BoxPadding",
})

ESPTab:CreateDivider()
ESPTab:CreateSection("Player ESP")

ESPTab:CreateToggle({
	Name = "Player ESP",
	CurrentValue = true,
	TrackActive = true,
	Flag = "PlayerESP",
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

SettingsTab:CreateSection("Menu")

SettingsTab:CreateKeybind({
	Name = "Menu Keybind",
	CurrentKeybind = "RightShift",
	NoUI = true,
	Flag = "MenuKeybind",
	ChangedCallback = function(key)
		Library.SetMenuKeybind(Enum.KeyCode[key] or Enum.KeyCode.RightShift)
	end,
})

SettingsTab:CreateDivider()
SettingsTab:CreateSection("Credits")

local CreditLabel = SettingsTab:CreateLabel("")
task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:Set(shown .. cursor)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:Set(shown .. cursor)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

SettingsTab:CreateButton({
	Name = "Join Discord",
	Callback = function()
		pcall(function() setclipboard("https://discord.gg/bac") end)
		Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 })
	end,
})

SettingsTab:CreateButton({
	Name = "Unload",
	Callback = function()
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
		Library.Unload()
	end,
})

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════

local PINK = Color3.fromRGB(255, 183, 197)
local PURPLE = Color3.fromRGB(140, 100, 255)

local function ToggleOn(flagName)
	local flag = Library.Flags[flagName]
	return flag ~= nil and flag.Value == true
end

local function GetFlagValue(flagName)
	local flag = Library.Flags[flagName]
	return flag and flag.Value or nil
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
					local boxPx = (ballDiam * pxPerStud) + (GetFlagValue("BoxPadding") or 10)

					BallGui.Size = UDim2.new(0, boxPx, 0, boxPx)
					BallGui.Adornee = visBall
					BallGui.Enabled = true
					BoxStroke.Thickness = GetFlagValue("BoxThickness") or 5
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
		local kp = Library.Flags.ClashKeybind
		if kp and kp.Value and typeof(kp.Value) == "string" and kp.Value ~= "None" and kp.Value ~= "Unknown" then
			if input.KeyCode == Enum.KeyCode[kp.Value] then
				local toggle = Library.Flags.ClashMode
				if toggle then
					toggle:Set(not toggle.Value, false)
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
				local baseDist = GetFlagValue("ParryDist") or 30
				local baseCD = GetFlagValue("ParryCooldown") or 350

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
			if ToggleOn("ClashMode") then
				if isrbxactive() then
					-- Don't click if mouse is over the menu
					local mouseOverMenu = false
					pcall(function()
						local mousePos = UserInputService:GetMouseLocation()
						local guiObjects = game:GetService("CoreGui"):GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
						for _, obj in ipairs(guiObjects) do
							if obj:FindFirstAncestor("LootUI") then
								mouseOverMenu = true
								break
							end
						end
					end)
					if not mouseOverMenu then
						local cps = GetFlagValue("ClashCPS") or 30
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
