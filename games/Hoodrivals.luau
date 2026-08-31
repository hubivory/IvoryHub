--// Ivory Hub | Hood Rivals
--// Place IDs: 77463332823746, 113272123504853

-- ═══════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(c)
	Character = c
	Humanoid = c:WaitForChild("Humanoid")
	HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
end)

-- ═══════════════════════════════════════════════════════
--  LOAD OBSIDIANULTRA
-- ═══════════════════════════════════════════════════════
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
	return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(getgenv()._IvoryLibSrc or httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(getgenv()._IvoryTMSrc or httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(getgenv()._IvorySMSrc or httpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.Scheme.MainColor = Color3.fromRGB(18, 14, 28)
Library.Scheme.AccentColor = Color3.fromRGB(140, 110, 220)
Library.Scheme.AcccentDark = Color3.fromRGB(110, 80, 190)
Library.Scheme.OutlineColor = Color3.fromRGB(50, 40, 70)
Library.Scheme.FontColor = Color3.fromRGB(225, 215, 245)
Library.Scheme.SubText = Color3.fromRGB(155, 135, 185)
Library.Scheme.Bright = Color3.fromRGB(32, 26, 48)
Library.Scheme.Dark = Color3.fromRGB(12, 10, 20)
Library.Scheme.Risky = Color3.fromRGB(220, 80, 120)
Library.ShowToggleFrameInKeybinds = true
Library.ForceCheckbox = false

-- ═══════════════════════════════════════════════════════
--  STATE
-- ═══════════════════════════════════════════════════════
local State = {
	Speed_Enabled = false,
	Speed_Value = 16,
	NoRecoil = false,
	SilentAim = false,
	SilentAim_HitPart = "Head",
	SilentAim_FOV = 150,
	SilentAim_FOV_Circle = true,
	Highlight_Enabled = false,
	Highlight_FillTransparency = 0.5,
	Highlight_OutlineTransparency = 0,
	Highlight_Color = Color3.fromRGB(140, 110, 220),
	Highlight_Self = false,
	AutoRespawn = false,
}

-- ═══════════════════════════════════════════════════════
--  REMOTES
-- ═══════════════════════════════════════════════════════
local MapVote = ReplicatedStorage:WaitForChild("MapVote", 10)
local RequestRespawn = ReplicatedStorage:WaitForChild("RequestRespawn", 10)
local SpectateTarget = ReplicatedStorage:WaitForChild("SpectateTarget", 10)

-- ═══════════════════════════════════════════════════════
--  NO RECOIL
-- ═══════════════════════════════════════════════════════
pcall(function()
	local WeaponModule = require(ReplicatedStorage:WaitForChild("Weapon_Module"))
	State._OrigRecoil = WeaponModule.recoil
	WeaponModule.recoil = function() end
end)

local function applyNoRecoil()
	pcall(function()
		local WeaponModule = require(ReplicatedStorage:WaitForChild("Weapon_Module"))
		if State.NoRecoil then
			State._OrigRecoil = State._OrigRecoil or WeaponModule.recoil
			WeaponModule.recoil = function() end
		else
			if State._OrigRecoil then
				WeaponModule.recoil = State._OrigRecoil
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════
local isLobby = false

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.5 |",
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

-- ═══════════════════════════════════════════════════════
--  TABS
-- ═══════════════════════════════════════════════════════
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local WorldTab = Window:AddTab({ Name = "World", Icon = "globe" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ═══════════════════════════════════════════════════════
--  MAIN TAB — INFO
-- ═══════════════════════════════════════════════════════
local MainInfo = MainTab:AddSubTab("Info", "info")
local GameInfoGroup = MainInfo:AddLeftGroupbox("Current Game", "gamepad-2")
GameInfoGroup:AddLabel("PlaceId: " .. tostring(game.PlaceId))
GameInfoGroup:AddButton("Copy JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)
GameInfoGroup:AddButton("Copy PlaceId", function()
	setclipboard(tostring(game.PlaceId))
	Library:Notify({ Title = "Ivory", Description = "PlaceId copied!", Type = "Success", Time = 2 })
end)
GameInfoGroup:AddButton("Rejoin Server", function()
	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)
GameInfoGroup:AddButton("Server Hop", function()
	pcall(function()
		local servers = HttpService:JSONDecode(request({
			Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET",
		}).Body)
		if servers and servers.data then
			for _, server in ipairs(servers.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					break
				end
			end
		end
	end)
end)

local DiscordGroup = MainInfo:AddRightGroupbox("Community", "heart")
DiscordGroup:AddButton("Join Discord For Dupe", function()
	pcall(function()
		if setclipboard then setclipboard("https://discord.gg/MCWYKBdB4E") end
	end)
	Library:Notify({ Title = "Ivory", Description = "Discord link copied to clipboard!", Type = "Info", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  MAIN TAB — MATCH
-- ═══════════════════════════════════════════════════════
local MainMatch = MainTab:AddSubTab("Match", "swords")
local MatchGroup = MainMatch:AddLeftGroupbox("Match Controls", "target")
MatchGroup:AddButton("Request Respawn", function()
	pcall(function() RequestRespawn:FireServer() end)
end)
MatchGroup:AddButton("Vote Map 1", function()
	pcall(function() MapVote:FireServer(1) end)
end)
MatchGroup:AddButton("Vote Map 2", function()
	pcall(function() MapVote:FireServer(2) end)
end)
MatchGroup:AddButton("Vote Map 3", function()
	pcall(function() MapVote:FireServer(3) end)
end)

local SpectateGroup = MainMatch:AddRightGroupbox("Spectate", "eye")
SpectateGroup:AddToggle("AutoRespawn", { Text = "Auto Respawn", Default = false, Callback = function(v) State.AutoRespawn = v end })

local SpectateList = {}
local function refreshSpectateList()
	SpectateList = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(SpectateList, p.Name)
		end
	end
end
refreshSpectateList()
Players.PlayerAdded:Connect(refreshSpectateList)
Players.PlayerRemoving:Connect(refreshSpectateList)

SpectateGroup:AddDropdown("SpectateTarget", { Text = "Spectate Player", Values = SpectateList, Default = "", Callback = function(v)
	local target = Players:FindFirstChild(v)
	if target then
		pcall(function() SpectateTarget:FireServer(target) end)
	end
end })

SpectateGroup:AddButton("Refresh Players", function()
	refreshSpectateList()
	local dd = Options.SpectateTarget
	if dd then dd:Refresh(SpectateList) end
	Library:Notify({ Title = "Ivory", Description = "Player list refreshed!", Type = "Success", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  COMBAT TAB — SILENT AIM
-- ═══════════════════════════════════════════════════════
local SilentAimSub = CombatTab:AddSubTab("Silent Aim", "target")
local SilentAimGroup = SilentAimSub:AddLeftGroupbox("Silent Aim", "target")
SilentAimGroup:AddToggle("SilentAim", { Text = "Enable Silent Aim", Default = false, Callback = function(v) State.SilentAim = v end })
SilentAimGroup:AddDropdown("SilentAim HitPart", { Text = "Hit Part", Values = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Random" }, Default = "Head", Callback = function(v) State.SilentAim_HitPart = v end })
SilentAimGroup:AddSlider("SilentAim FOV", { Text = "FOV (px)", Default = 150, Min = 20, Max = 500, Rounding = 0, Callback = function(v) State.SilentAim_FOV = v end })
SilentAimGroup:AddToggle("SilentAim FOV Circle", { Text = "Show FOV Circle", Default = true, Callback = function(v) State.SilentAim_FOV_Circle = v end })

-- ═══════════════════════════════════════════════════════
--  COMBAT TAB — WEAPON MODS
-- ═══════════════════════════════════════════════════════
local WeaponSub = CombatTab:AddSubTab("Weapon Mods", "zap")
local WeaponGroup = WeaponSub:AddLeftGroupbox("Weapon Mods", "zap")
WeaponGroup:AddToggle("NoRecoil", { Text = "No Recoil", Default = false, Callback = function(v) State.NoRecoil = v applyNoRecoil() end })

-- ═══════════════════════════════════════════════════════
--  PLAYER TAB — SPEED
-- ═══════════════════════════════════════════════════════
local MovementSub = PlayerTab:AddSubTab("Movement", "move")
local SpeedGroup = MovementSub:AddLeftGroupbox("Speed", "zap")
SpeedGroup:AddToggle("Speed Enabled", { Text = "Enable Speed", Default = false, Callback = function(v)
	State.Speed_Enabled = v
	if not v then pcall(function() Humanoid.WalkSpeed = 16 end) end
end })
SpeedGroup:AddSlider("Speed Value", { Text = "Walk Speed", Default = 16, Min = 16, Max = 250, Rounding = 0, Callback = function(v) State.Speed_Value = v end })
SpeedGroup:AddButton("Apply Speed", function() pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end)

-- ═══════════════════════════════════════════════════════
--  VISUALS TAB — HIGHLIGHTS
-- ═══════════════════════════════════════════════════════
local HighlightSub = VisualsTab:AddSubTab("Highlights", "highlighter")
local HighlightGroup = HighlightSub:AddLeftGroupbox("Highlights", "highlighter")
HighlightGroup:AddToggle("Highlight Enabled", { Text = "Enable Highlights", Default = false, Callback = function(v)
	State.Highlight_Enabled = v
	if not v then
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				local hl = player.Character:FindFirstChild("IvoryHighlight")
				if hl then hl:Destroy() end
			end
		end
	end
end })
HighlightGroup:AddToggle("Highlight Self", { Text = "Highlight Yourself", Default = false, Callback = function(v) State.Highlight_Self = v end })
HighlightGroup:AddSlider("Highlight Fill", { Text = "Fill Transparency", Default = 50, Min = 0, Max = 100, Rounding = 0, Callback = function(v) State.Highlight_FillTransparency = v / 100 end })
HighlightGroup:AddSlider("Highlight Outline", { Text = "Outline Transparency", Default = 0, Min = 0, Max = 100, Rounding = 0, Callback = function(v) State.Highlight_OutlineTransparency = v / 100 end })

local HighlightColors = HighlightSub:AddRightGroupbox("Highlight Colors", "palette")
HighlightColors:AddLabel("Highlight Color"):AddColorPicker("HighlightColor", { Default = Color3.fromRGB(140, 110, 220), Title = "Highlight", Callback = function(v) State.Highlight_Color = v end })

-- ═══════════════════════════════════════════════════════
--  WORLD TAB
-- ═══════════════════════════════════════════════════════
local WorldMiscTab = WorldTab:AddSubTab("World Misc", "globe")

local ServerGroup = WorldMiscTab:AddRightGroupbox("Server", "server")
ServerGroup:AddButton("Rejoin Now", function()
	pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
end)
ServerGroup:AddButton("Server Hop", function()
	pcall(function()
		local servers = HttpService:JSONDecode(request({
			Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100",
			Method = "GET",
		}).Body)
		if servers and servers.data then
			for _, server in ipairs(servers.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
					break
				end
			end
		end
	end)
end)
ServerGroup:AddButton("Copy Server JobId", function()
	setclipboard(game.JobId)
	Library:Notify({ Title = "Ivory", Description = "JobId copied!", Type = "Success", Time = 2 })
end)

-- ═══════════════════════════════════════════════════════
--  SETTINGS TAB
-- ═══════════════════════════════════════════════════════
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("hoodrivals")

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(value) Library.KeybindFrame.Visible = value end })
MenuGroup:AddToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = Library.ShowCustomCursor, Callback = function(Value) Library.ShowCustomCursor = Value end })
MenuGroup:AddButton("Test Notification", function() Library:Notify({ Title = "Ivory", Description = "This is a test notification!", Type = "Info", Time = 3 }) end)
MenuGroup:AddDropdown("NotifySide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notification Side", Callback = function(Value) Library.NotifySide = Value end })
MenuGroup:AddDropdown("DPIDropdown", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(Value) Library:SetDPIScale(tonumber(Value:gsub("%%", ""))) end })
MenuGroup:AddSlider("UICornerSlider", { Text = "Corner Radius", Default = 4, Min = 0, Max = 20, Rounding = 0, Callback = function(value) Window:SetCornerRadius(value) end })
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu: RightShift (default)"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════════════════════
--  HIGHLIGHTS
-- ═══════════════════════════════════════════════════════
local function applyHighlight(player)
	if player == LocalPlayer and not State.Highlight_Self then return end
	if not player.Character then return end
	local hl = player.Character:FindFirstChild("IvoryHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "IvoryHighlight"
		hl.Parent = player.Character
	end
	hl.FillColor = State.Highlight_Color
	hl.OutlineColor = State.Highlight_Color
	hl.Adornee = player.Character
	hl.FillTransparency = State.Highlight_FillTransparency
	hl.OutlineTransparency = State.Highlight_OutlineTransparency
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled = State.Highlight_Enabled
end

local function removeHighlight(player)
	if player.Character then
		local hl = player.Character:FindFirstChild("IvoryHighlight")
		if hl then hl:Destroy() end
	end
end

-- ═══════════════════════════════════════════════════════
--  SILENT AIM (GetAimDirection hook)
-- ═══════════════════════════════════════════════════════
local SilentAimFOVCircle = Drawing.new("Circle")
SilentAimFOVCircle.Thickness = 1.5
SilentAimFOVCircle.NumSides = 64
SilentAimFOVCircle.Radius = State.SilentAim_FOV
SilentAimFOVCircle.Filled = false
SilentAimFOVCircle.Visible = false
SilentAimFOVCircle.Color = Color3.fromRGB(255, 100, 100)
SilentAimFOVCircle.Transparency = 0.8

local SilentAimHighlight = Instance.new("Highlight")
SilentAimHighlight.Name = "SilentAimHighlight"
SilentAimHighlight.FillColor = Color3.fromRGB(255, 0, 0)
SilentAimHighlight.FillTransparency = 0.4
SilentAimHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
SilentAimHighlight.OutlineTransparency = 0

local CurrentSilentTarget = nil
local CurrentSilentHead = nil

local function GetClosestEnemyHead()
	local LocalChar = LocalPlayer.Character
	if not LocalChar or not LocalChar:FindFirstChild("HumanoidRootPart") then
		return nil, nil
	end
	local closestPlayer = nil
	local shortestDist = State.SilentAim_FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local Char = player.Character
			if Char and Char:FindFirstChild("Humanoid") and Char.Humanoid.Health > 0 then
				local hitPartName = State.SilentAim_HitPart
				if hitPartName == "Random" then
					local parts = { "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso" }
					hitPartName = parts[math.random(1, #parts)]
				end
				local hitPart = Char:FindFirstChild(hitPartName)
				if hitPart then
					local pos = Camera:WorldToViewportPoint(hitPart.Position)
					local screenDist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
					if screenDist < shortestDist then
						shortestDist = screenDist
						closestPlayer = player
					end
				end
			end
		end
	end

	if closestPlayer and closestPlayer.Character then
		local head = closestPlayer.Character:FindFirstChild("Head")
		return closestPlayer.Character, head
	end
	return nil, nil
end

local function hookSilentAim()
	local LocalChar = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local TargetScript = nil

	for _, Obj in ipairs(LocalChar:GetDescendants()) do
		if Obj:IsA("LocalScript") and Obj.Name == "FirearmLocal" then
			TargetScript = Obj
			break
		end
	end
	if not TargetScript then
		for _, Obj in ipairs(LocalPlayer.PlayerScripts:GetDescendants()) do
			if Obj:IsA("LocalScript") and Obj.Name == "FirearmLocal" then
				TargetScript = Obj
				break
			end
		end
	end

	if TargetScript and getsenv then
		local success, Env = pcall(getsenv, TargetScript)
		if success and Env then
			local OldGetAimDirection = Env.GetAimDirection
			Env.GetAimDirection = function(Spread)
				if State.SilentAim and CurrentSilentHead then
					local MyChar = LocalPlayer.Character
					if MyChar and MyChar:FindFirstChild("Head") then
						local StartPos = MyChar.Head.Position
						local TargetPos = CurrentSilentHead.Position
						return (TargetPos - StartPos).Unit, StartPos
					end
				end
				if OldGetAimDirection then
					return OldGetAimDirection(Spread)
				end
				return Camera.CFrame.LookVector, Camera.CFrame.Position
			end
		end
	end
end

pcall(hookSilentAim)
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	pcall(hookSilentAim)
end)

-- ═══════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════
RunService.RenderStepped:Connect(function()
	Camera = workspace.CurrentCamera
	Character = LocalPlayer.Character or Character
	Humanoid = Character and Character:FindFirstChildOfClass("Humanoid") or Humanoid
	HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart") or HumanoidRootPart

	if State.Speed_Enabled then pcall(function() Humanoid.WalkSpeed = State.Speed_Value end) end

	-- Silent Aim highlight
	if State.SilentAim then
		local TargetChar, Head = GetClosestEnemyHead()
		if TargetChar and Head then
			CurrentSilentTarget = TargetChar
			CurrentSilentHead = Head
			SilentAimHighlight.Parent = TargetChar
		else
			CurrentSilentTarget = nil
			CurrentSilentHead = nil
			SilentAimHighlight.Parent = nil
		end
	else
		CurrentSilentTarget = nil
		CurrentSilentHead = nil
		SilentAimHighlight.Parent = nil
	end

	-- Silent Aim FOV Circle
	if State.SilentAim_FOV_Circle and State.SilentAim then
		SilentAimFOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		SilentAimFOVCircle.Radius = State.SilentAim_FOV
		SilentAimFOVCircle.Visible = true
	else
		SilentAimFOVCircle.Visible = false
	end

	-- Highlights
	for _, player in ipairs(Players:GetPlayers()) do
		if State.Highlight_Enabled then applyHighlight(player) else removeHighlight(player) end
	end
end)

-- ═══════════════════════════════════════════════════════
--  AUTO RESPAWN
-- ═══════════════════════════════════════════════════════
task.spawn(function()
	while true do
		task.wait(1)
		if State.AutoRespawn then
			pcall(function()
				if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Humanoid") or LocalPlayer.Character.Humanoid.Health <= 0 then
					RequestRespawn:FireServer()
				end
			end)
		end
	end
end)

-- ═══════════════════════════════════════════════════════
--  UNLOAD CLEANUP
-- ═══════════════════════════════════════════════════════
Library:OnUnload(function()
	SilentAimFOVCircle:Remove()
	SilentAimHighlight:Destroy()
	for _, player in ipairs(Players:GetPlayers()) do removeHighlight(player) end
	pcall(function()
		if State._OrigRecoil then
			local WeaponModule = require(ReplicatedStorage:WaitForChild("Weapon_Module"))
			WeaponModule.recoil = State._OrigRecoil
		end
	end)
end)

Library:Notify({ Title = "Ivory", Description = "Script loaded. RightBracket to toggle menu.", Type = "Success", Time = 3 })
print("[Ivory] Hood Rivals loaded!")
