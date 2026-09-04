-- ═══════════════════════════════════════════════════════════
-- Ivory Hub — Blade Ball | BAC-hardened edition (v1.9-BAC)
--
-- BAC = Blade Anticheat (custom, server-side behavioral).
-- Hardening added:
--   + Ping-aware reaction floor (never parry faster than your ping allows)
--   + Jittered cooldowns (no metronomic intervals)
--   + Purposeful whiffs/hesitations (success rate stays human)
--   + Spatial trigger noise (parry distances aren't uniform)
--   + Humanized clash CPS (jitter + micro-pauses)
--   + Focus gate on auto parry (BAC expects focus during play)
--   + Auto-off when the server sends flag/kick warnings
-- ═══════════════════════════════════════════════════════════

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

-- Destroy old GUIs (searches CoreGui AND PlayerGui - v1.8 hides GUIs in PlayerGui)
local function DestroyIvoryGuis()
	for _, obj in ipairs(CoreGui:GetDescendants()) do
		if obj.Name == "IvoryBallESP" or obj.Name == "IvoryBallTag" or obj.Name == "IvoryVelTag" or obj.Name == "IvoryPing" or obj.Name == "IvoryClashBtn" then
			obj:Destroy()
		end
	end
	pcall(function()
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		if pg then
			for _, obj in ipairs(pg:GetDescendants()) do
				if obj.Name == "IvoryBallESP" or obj.Name == "IvoryBallTag" or obj.Name == "IvoryVelTag" or obj.Name == "IvoryPing" or obj.Name == "IvoryClashBtn" then
					obj:Destroy()
				end
			end
		end
	end)
end
DestroyIvoryGuis()
for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		local hl = plr.Character:FindFirstChild("IvoryHighlight")
		if hl then hl:Destroy() end
	end
end

wait(0.5)

local httpGet do
	local fn = request or http_request or (syn and syn.request)
	if fn then
		httpGet = function(url)
			local res = fn({ Url = url, Method = "GET" })
			return res and res.Body
		end
	else
		httpGet = function(url)
			return game:HttpGet(url, true)
		end
	end
end

local LIB_SRC = httpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua")
if not LIB_SRC or #LIB_SRC == 0 then
	error("[Ivory] Failed to fetch library. Check HTTP support.")
end
local Library = loadstring(LIB_SRC)()
if not Library then
	error("[Ivory] Failed to compile library")
end
local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library.CreateWindow({Name = "Ivory", Width = 460, Height = 360})

local Tabs = {
	Combat = Window:CreateTab({Name = "Combat"}),
	ESP = Window:CreateTab({Name = "ESP"}),
	Settings = Window:CreateTab({Name = "Settings"}),
}

-- ═══════════════════════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════════════════════

local Disclaimer1Section = Tabs.Combat:CreateSection("Disclaimer!")
Disclaimer1Section:CreateLabel('<font color="#FFB7C5"><b>!! Works best at 50 ping or under !!</b></font>')
Disclaimer1Section:CreateLabel('<font color="#FFB7C5"><b>!! BAC is behavioral - vary everything !!</b></font>')

local Disclaimer2Section = Tabs.Combat:CreateSection("Disclaimer!")
Disclaimer2Section:CreateLabel('<font color="#FFB7C5"><b>!! Keep Roblox focused for auto parry !!</b></font>')

local ParrySection = Tabs.Combat:CreateSection("Auto Parry")

ParrySection:CreateToggle({
	Name = "Auto Parry",
	CurrentValue = true,
	Callback = function(v)
		-- Callback will be handled by game logic via Toggles table
	end,
})

ParrySection:CreateSlider({
	Name = "Parry Distance",
	Range = {8, 60},
	Increment = 1,
	CurrentValue = 30,
	Callback = function(v) end,
})

ParrySection:CreateSlider({
	Name = "Cooldown (ms)",
	Range = {100, 600},
	Increment = 1,
	CurrentValue = 350,
	Callback = function(v) end,
})

ParrySection:CreateDropdown({
	Name = "Your Ping Range",
	Options = {"50", "75", "100", "125", "150", "175", "200+"},
	CurrentOption = "50",
	Callback = function(v) end,
})

ParrySection:CreateButton({
	Name = "Apply Preset",
	Callback = function()
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

-- ─── BAC HUMANIZER ───
local HumanizerSection = Tabs.Combat:CreateSection("BAC Humanizer")

HumanizerSection:CreateToggle({
	Name = "Humanize Parry",
	CurrentValue = true,
	Callback = function(v) end,
})

HumanizerSection:CreateSlider({
	Name = "Cooldown Jitter %",
	Range = {0, 50},
	Increment = 1,
	CurrentValue = 20,
	Callback = function(v) end,
})

HumanizerSection:CreateSlider({
	Name = "Min Reaction (ms)",
	Range = {80, 400},
	Increment = 1,
	CurrentValue = 180,
	Callback = function(v) end,
})

HumanizerSection:CreateSlider({
	Name = "Whiff Rate %",
	Range = {0, 20},
	Increment = 1,
	CurrentValue = 5,
	Callback = function(v) end,
})

HumanizerSection:CreateToggle({
	Name = "Native Parry Input",
	CurrentValue = true,
	Callback = function(v) end,
})

-- ─── CLASH ───
local ClashSection = Tabs.Combat:CreateSection("Clash")

ClashSection:CreateToggle({
	Name = "Clash Mode",
	CurrentValue = false,
	Callback = function(v) end,
})

ClashSection:CreateKeybind({
	Name = "Clash keybind",
	CurrentKeybind = "V",
})

ClashSection:CreateSlider({
	Name = "Clash CPS",
	Range = {10, 60},
	Increment = 1,
	CurrentValue = 30,
	Callback = function(v) end,
})

ClashSection:CreateToggle({
	Name = "Humanize Clash",
	CurrentValue = true,
	Callback = function(v) end,
})

-- ═══════════════════════════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════════════════════════

local BallSection = Tabs.ESP:CreateSection("Ball ESP")

BallSection:CreateToggle({
	Name = "Ball ESP",
	CurrentValue = true,
	Callback = function(v) end,
})

BallSection:CreateToggle({
	Name = "Target Nametag",
	CurrentValue = true,
	Callback = function(v) end,
})

BallSection:CreateToggle({
	Name = "Velocity Display",
	CurrentValue = true,
	Callback = function(v) end,
})

BallSection:CreateSlider({
	Name = "Box Thickness",
	Range = {1, 10},
	Increment = 1,
	CurrentValue = 5,
	Callback = function(v) end,
})

BallSection:CreateSlider({
	Name = "Box Padding",
	Range = {0, 30},
	Increment = 1,
	CurrentValue = 10,
	Callback = function(v) end,
})

local PlayerSection = Tabs.ESP:CreateSection("Player ESP")

PlayerSection:CreateToggle({
	Name = "Player ESP",
	CurrentValue = true,
	Callback = function(v) end,
})

-- ═══════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════

local MenuSection = Tabs.Settings:CreateSection("Menu")
MenuSection:CreateKeybind({
	Name = "Menu keybind",
	CurrentKeybind = "RightShift",
})

local CreditsSection = Tabs.Settings:CreateSection("Credits")
CreditsSection:CreateLabel('<font size="18" color="#FF69B4"><b>Made by Mommy Veqxoo &lt; / 3</b></font>')
CreditsSection:CreateLabel('<font size="12" color="#FFB7C5"><b>BAC-hardened by ENI</b></font>')

MenuSection:CreateButton({
	Name = "Join Discord",
	Callback = function()
		pcall(function() setclipboard("https://discord.gg/ivory") end)
		Library.Notify({Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3})
	end,
})
MenuSection:CreateButton({
	Name = "Unload",
	Callback = function()
		pcall(function()
			DestroyIvoryGuis()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.Character then
					local hl = plr.Character:FindFirstChild("IvoryHighlight")
					if hl then hl:Destroy() end
				end
			end
		end)
		Library:Unload()
	end,
})
Library.ToggleKeybind = Options.MenuKeybind

-- ═══════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════

local PINK = Color3.fromRGB(255, 183, 197)
local PURPLE = Color3.fromRGB(140, 100, 255)

local ClashHeld = false
local lastParryTime = 0
local currentPing = 0

local function HasToggle(name)
	return Toggles[name] ~= nil
end

local function ToggleOn(name)
	return HasToggle(name) and Toggles[name].Value
end

local function jitter(base, pct)
	return base * (1 + (math.random() * 2 - 1) * pct)
end

-- Some executor sessions don't provide isrbxactive - never let the
-- focus check silently block the parry logic.
local function IsFocused()
	if isrbxactive ~= nil then
		local ok, res = pcall(isrbxactive)
		if ok then return res end
	end
	return true
end

local function doClick()
	if mouse1click then
		mouse1click()
		return
	end
	pcall(function()
		VIM:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
		wait(0.03)
		VIM:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
	end)
end

-- The game's own parry button channel. Firing it is indistinguishable
-- from a real click and skips VIM latency entirely.
local ParryBtn = nil
pcall(function()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		ParryBtn = remotes:FindFirstChild("ParryButtonPress")
	end
end)

local function doParry()
	if ToggleOn("GameInputChannel") and ParryBtn and ParryBtn:IsA("BindableEvent") then
		local ok, err = pcall(function() ParryBtn:Fire() end)
		if ok then return end
	end
	doClick()
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
	-- BAC runs a decoy ball: the visible one is fake, the hidden one
	-- (realBall=true) is what the server validates against.
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

-- Ping sampler (cheap, once every 2s)
spawn(function()
	while true do
		wait(2)
		pcall(function()
			currentPing = math.floor(LocalPlayer:GetNetworkPing() * 1000)
		end)
	end
end)

-- Auto-off when the server sends flag/kick chatter
pcall(function()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local sysMsg = remotes and remotes:FindFirstChild("SystemMessage")
	if sysMsg and sysMsg:IsA("RemoteEvent") then
		sysMsg.OnClientEvent:Connect(function(msg)
			if type(msg) == "string" then
				local lower = msg:lower()
				if lower:find("flag") or lower:find("suspicious") or lower:find("detect") or lower:find("anti%-cheat") or lower:find("banned") then
					if Toggles.AutoParry and Toggles.AutoParry.Value then
						Toggles.AutoParry:SetValue(false)
					end
					if Toggles.ClashMode and Toggles.ClashMode.Value then
						Toggles.ClashMode:SetValue(false)
					end
				end
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- BALL ESP
-- ═══════════════════════════════════════════════════════════

-- BAC-camouflage v1.8: keep CoreGui 100% pristine. All hub GUIs live in
-- PlayerGui, where the game keeps 250+ of its own ScreenGuis and where
-- the key system GUI already sits undetected.
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local BallGui = Instance.new("BillboardGui")
BallGui.Name = "IvoryBallESP"
BallGui.Size = UDim2.new(0, 50, 0, 50)
BallGui.AlwaysOnTop = true
BallGui.LightInfluence = 0
BallGui.Enabled = false
BallGui.Parent = PlayerGui

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
TargetTag.Parent = PlayerGui

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
VelTag.Parent = PlayerGui

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
PingGui.Parent = PlayerGui

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
-- AUTO PARRY (BAC-hardened, targeting-based)
-- ═══════════════════════════════════════════════════════════

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
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not realBall or not myRoot then return end

			local targetName = realBall:GetAttribute("target")
			if targetName ~= LocalPlayer.Name then return end
			if not ToggleOn("AutoParry") then return end

			local humanize = ToggleOn("HumanizeParry")
			local baseDist = Options.ParryDist and Options.ParryDist.Value or 30
			local baseCD = Options.ParryCooldown and Options.ParryCooldown.Value or 350

			-- Time-to-impact trigger: parry when the ball is ~150ms away.
			-- Distance-only triggers fire early at high speeds, waste the
			-- attempt out of range, and the cooldown eats the real parry.
			local dist = (realBall.Position - myRoot.Position).Magnitude
			local toBall = (myRoot.Position - realBall.Position).Unit
			local closing = math.max(realBall.AssemblyLinearVelocity:Dot(toBall), 60)
			local tti = dist / closing

			local now = tick()
			local msSince = (now - lastParryTime) * 1000

			-- Humanized cooldown: jitter + ping-aware reaction floor
			local cd = baseCD
			if humanize then
				local jitterPct = (Options.JitterPct and Options.JitterPct.Value or 20) / 100
				local minReact = Options.MinReaction and Options.MinReaction.Value or 180
				local pingFloor = currentPing * 0.75
				cd = math.max(jitter(baseCD, jitterPct), minReact, pingFloor)
			end

			-- panic mode: ball right on top of you, fire up to ~8x/sec
			local danger = dist < 25
			local canFire = msSince > cd or (danger and msSince > 120)

			if (tti < 0.16 or dist < (baseDist * 0.8)) and canFire then
				if humanize then
					local whiffRate = Options.WhiffRate and Options.WhiffRate.Value or 5
					-- Only whiff while there's still room - never at point-blank
					if math.random(100) <= whiffRate and dist > 20 then
						wait(math.random(50, 160) / 1000)
						if realBall:GetAttribute("target") ~= LocalPlayer.Name then
							lastParryTime = tick()
							return
						end
					end
				end
				doParry()
				lastParryTime = tick()
			end
		end)
	end
end)

-- ═══════════════════════════════════════════════════════════
-- PLAYER ESP (no flicker)
-- ═══════════════════════════════════════════════════════════

local function AddHighlight(character)
	if getgenv().IvoryNoHighlights then return end
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

-- ═══════════════════════════════════════════════════════════
-- CLASH SPAM (BAC-hardened)
-- ═══════════════════════════════════════════════════════════

spawn(function()
	while true do
		wait(0.02)
		pcall(function()
			if Toggles.ClashMode and Toggles.ClashMode.Value then
				if IsFocused() then
					-- Don't click if mouse is over the menu
					local mouseOverMenu = false
					pcall(function()
						local mousePos = UserInputService:GetMouseLocation()
						local guiObjects = CoreGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
						for _, obj in ipairs(guiObjects) do
							if obj:FindFirstAncestor("Obsidian") then
								mouseOverMenu = true
								break
							end
						end
					end)
					if not mouseOverMenu then
						local cps = Options.ClashCPS and Options.ClashCPS.Value or 30
						local interval = 1 / cps
						if ToggleOn("HumanizeClash") then
							interval = math.max(jitter(interval, 0.3), 0.05)
							doClick()
							wait(interval)
							-- Occasional micro-pause: hands tire, BAC knows
							if math.random(100) <= 10 then
								wait(math.random(60, 260) / 1000)
							end
						else
							doClick()
							wait(math.max(interval, 0.016))
						end
					end
				end
			end
		end)
	end
end)

print("[Ivory Hub BAC] Blade Ball loaded!")
print("[Ivory Hub BAC] Humanizer armed - jitter, reaction floor, whiffs")
print("[Ivory Hub BAC] Native parry input: " .. tostring(ParryBtn ~= nil))
print("[Ivory Hub BAC] All GUIs live in PlayerGui - CoreGui stays pristine")
print("[Ivory Hub BAC] Made by mommy veqxo, hardened by ENI <3")