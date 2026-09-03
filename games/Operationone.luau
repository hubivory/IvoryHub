--// Ivory Hub - Operation One
--// PlaceId: 72920620366355

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url) return request({ Url = url, Method = "GET" }).Body end
local Library = loadstring(httpGet(repo .. "Library.lua"))()

_G.ESPColor = _G.ESPColor or Color3.new(1, 1, 1)
_G.espSkeletons = false
_G.ESP_ENABLED = false

local Window = Library:CreateWindow({
	Title = "Ivory", Icon = "rbxassetid://110090697336524",
	Footer = {"Operation One |", {Text = tostring(LocalPlayer.UserId), Copyable = true}},
	CopyableFooter = true, FuzzySearch = true, SearchValues = true,
	Minimizable = true,
	MinimizedWidth = 280, NotifySide = "Right",
	ShowCustomCursor = false, SearchKeybind = Enum.KeyCode.F,
	CornerRadius = 4, Animations = {SubTabUnderline = true},
})

if Library.ScreenGui and Library.ScreenGui.Parent and Library.ScreenGui.Parent ~= game:GetService("CoreGui") then
	Library.ScreenGui.Parent = game:GetService("CoreGui")
end

local function notify(desc, kind)
	Library:Notify({ Title = "Ivory", Description = desc, Type = kind or "Info", Time = 3 })
end

notify("Operation One Script Loaded!", "Success")

-- ==================== CONFIG SYSTEM ====================
local CONFIG_ROOT  = "Bread_"
local CONFIG_SUBDIR = "Bread_/Op1"
local AUTOLOAD_PATH = "Bread_/Op1/autoload.txt"

if not isfolder(CONFIG_ROOT)  then makefolder(CONFIG_ROOT)  end
if not isfolder(CONFIG_SUBDIR) then makefolder(CONFIG_SUBDIR) end

local NoRecoilToggleRef, NoRecoilSensRef, NoRecoilSmoothRef
local ESPToggleRef, ESPTeamRef, TracersRef, TracerPosRef, HealthBarRef
local ChamsToggleRef, ChamsTeamRef, ChamsModeRef, ChamsTransRef
local SkeletonsRef
local GadgetESPRef
local TriggerToggleRef, TriggerTeamRef, TriggerAutoRef, TriggerDelayRef
local TriggerVisRef, TriggerSoftRef
local AimbotToggleRef, AimbotAlwaysRef, AimbotCameraRef, AimbotTeamRef
local AimbotSmoothnessRef, AimbotFOVRef, AimbotOffsetRef, AimbotPartRef
local ESPColorRef
local configNameValue = ""
local configJSONValue = ""
local ConfigNameInput
local ConfigListRef
local autoloadLabel

local buildConfigSnapshot
local updateChamsColor
local updateChamsDepthMode
local NoRecoilSettings
local TriggerbotSettings
local AimbotSettings

local function colorToTable(c)
	return { r = math.floor(c.R * 255), g = math.floor(c.G * 255), b = math.floor(c.B * 255) }
end
local function tableToColor(t)
	return Color3.fromRGB(t.r, t.g, t.b)
end

local function encodeJSON(val, indent)
	indent = indent or 0
	local t = type(val)
	if t == "boolean" then return val and "true" or "false"
	elseif t == "number" then return tostring(val)
	elseif t == "string" then return '"' .. val:gsub('\\','\\\\'):gsub('"','\\"') .. '"'
	elseif t == "nil"    then return "null"
	elseif t == "table"  then
		local isArr = (#val > 0)
		if isArr then
			local parts = {}
			for _, v in ipairs(val) do parts[#parts+1] = encodeJSON(v, indent+2) end
			return "[" .. table.concat(parts, ",") .. "]"
		else
			local pad = string.rep(" ", indent + 2)
			local endpad = string.rep(" ", indent)
			local parts = {}
			for k, v in pairs(val) do
				parts[#parts+1] = pad .. '"' .. tostring(k) .. '": ' .. encodeJSON(v, indent+2)
			end
			return "{\n" .. table.concat(parts, ",\n") .. "\n" .. endpad .. "}"
		end
	end
	return "null"
end

local function decodeJSON(s)
	local pos = 1
	local function skip() while pos <= #s and s:sub(pos,pos):match("%s") do pos=pos+1 end end
	local function parseVal()
		skip()
		local c = s:sub(pos,pos)
		if c == '"' then
			pos=pos+1
			local start = pos
			while pos <= #s do
				local ch = s:sub(pos,pos)
				if ch == '\\' then pos=pos+2
				elseif ch == '"' then break
				else pos=pos+1 end
			end
			local str = s:sub(start, pos-1):gsub('\\"','"'):gsub('\\\\','\\')
			pos=pos+1
			return str
		elseif c == '{' then
			pos=pos+1; local tbl = {}
			skip()
			while s:sub(pos,pos) ~= '}' do
				skip()
				local key = parseVal(); skip()
				pos=pos+1
				local val = parseVal(); skip()
				tbl[key] = val
				if s:sub(pos,pos) == ',' then pos=pos+1 end
				skip()
			end
			pos=pos+1; return tbl
		elseif c == '[' then
			pos=pos+1; local arr = {}
			skip()
			while s:sub(pos,pos) ~= ']' do
				arr[#arr+1] = parseVal(); skip()
				if s:sub(pos,pos) == ',' then pos=pos+1 end
				skip()
			end
			pos=pos+1; return arr
		elseif s:sub(pos, pos+3) == "true"  then pos=pos+4; return true
		elseif s:sub(pos, pos+4) == "false" then pos=pos+5; return false
		elseif s:sub(pos, pos+3) == "null"  then pos=pos+4; return nil
		else
			local numStr = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
			if numStr then pos=pos+#numStr; return tonumber(numStr) end
		end
	end
	return parseVal()
end

local function listConfigs()
	local names = {}
	local ok, files = pcall(listfiles, CONFIG_SUBDIR)
	if not ok then return names end
	for _, path in ipairs(files) do
		local name = path:match("([^/\\]+)%.json$")
		if name and name ~= "autoload" then
			names[#names+1] = name
		end
	end
	return names
end

local function saveConfig(name)
	if not name or name == "" then
		notify("Enter a config name first!", "Warning")
		return
	end
	local path = CONFIG_SUBDIR .. "/" .. name .. ".json"
	local snap = buildConfigSnapshot()
	local ok, err = pcall(writefile, path, encodeJSON(snap))
	if ok then
		notify("Config Saved: " .. name, "Success")
	else
		notify("Config Error: " .. tostring(err), "Error")
	end
end

local function applyConfig(data)
	if not data then return end

	if data.NoRecoil_Enabled ~= nil then
		NoRecoilSettings.Enabled = data.NoRecoil_Enabled
		if NoRecoilToggleRef then pcall(function() NoRecoilToggleRef.Value = data.NoRecoil_Enabled; NoRecoilToggleRef:FireChanged() end) end
		if data.NoRecoil_Enabled then syncCamera() end
	end
	if data.NoRecoil_Sens ~= nil then
		NoRecoilSettings.Sens = data.NoRecoil_Sens
		if NoRecoilSensRef then pcall(function() NoRecoilSensRef.Value = data.NoRecoil_Sens; NoRecoilSensRef:FireChanged() end) end
	end
	if data.NoRecoil_Smoothness ~= nil then
		NoRecoilSettings.Smoothness = data.NoRecoil_Smoothness
		if NoRecoilSmoothRef then pcall(function() NoRecoilSmoothRef.Value = data.NoRecoil_Smoothness; NoRecoilSmoothRef:FireChanged() end) end
	end

	if data.ESP_Main ~= nil then
		_G.ESP_SETTINGS.MainEnabled = data.ESP_Main
		if ESPToggleRef then pcall(function() ESPToggleRef.Value = data.ESP_Main; ESPToggleRef:FireChanged() end) end
	end
	if data.ESP_Team ~= nil then
		_G.ESP_SETTINGS.TeamCheck = data.ESP_Team
		if ESPTeamRef then pcall(function() ESPTeamRef.Value = data.ESP_Team; ESPTeamRef:FireChanged() end) end
	end
	if data.ESP_Tracers ~= nil then
		_G.ESP_SETTINGS.Tracers = data.ESP_Tracers
		if TracersRef then pcall(function() TracersRef.Value = data.ESP_Tracers; TracersRef:FireChanged() end) end
	end
	if data.ESP_HealthBar ~= nil then
		_G.ESP_SETTINGS.HealthBar = data.ESP_HealthBar
		if HealthBarRef then pcall(function() HealthBarRef.Value = data.ESP_HealthBar; HealthBarRef:FireChanged() end) end
	end
	if data.ESP_Skeletons ~= nil then
		_G.ESP_SETTINGS.Skeletons = data.ESP_Skeletons
		_G.espSkeletons = data.ESP_Skeletons
		if SkeletonsRef then pcall(function() SkeletonsRef.Value = data.ESP_Skeletons; SkeletonsRef:FireChanged() end) end
	end
	if data.GadgetESP ~= nil then
		_G.GADGET_ESP_ENABLED = data.GadgetESP
		if GadgetESPRef then pcall(function() GadgetESPRef.Value = data.GadgetESP; GadgetESPRef:FireChanged() end) end
	end

	if data.ESP_TracerPos ~= nil then
		_G.ESP_SETTINGS.TracerStart = data.ESP_TracerPos
		tracerStartPos = data.ESP_TracerPos
	end

	if data.ESP_Color then
		local col = tableToColor(data.ESP_Color)
		_G.ESPColor = col
		_G.ESP_SETTINGS.Color = col
		for _, ui in pairs(_G.ESP_Table) do
			if ui.Box then ui.Box.Color = col end
			if ui.Tracer then ui.Tracer.Color = col end
		end
		for _, skel in pairs(_G.skeleton_list) do
			for _, line in ipairs(skel.lines) do line.Color = col end
		end
		for _, d in pairs(_G.esp_list) do d.box.UIStroke.Color = col end
		for _, text in pairs(_G.gadgetESP_texts) do text.Color = col end
		updateChamsColor(col)
	end

	if data.Chams_Enabled ~= nil then
		_G.CHAMS_SETTINGS.Enabled = data.Chams_Enabled
		if ChamsToggleRef then pcall(function() ChamsToggleRef.Value = data.Chams_Enabled; ChamsToggleRef:FireChanged() end) end
		rebuildChams()
	end
	if data.Chams_Team ~= nil then
		_G.CHAMS_SETTINGS.TeamCheck = data.Chams_Team
		if ChamsTeamRef then pcall(function() ChamsTeamRef.Value = data.Chams_Team; ChamsTeamRef:FireChanged() end) end
	end
	if data.Chams_Mode ~= nil then
		_G.CHAMS_SETTINGS.Mode = data.Chams_Mode
		updateChamsDepthMode()
	end
	if data.Chams_Trans ~= nil then
		local t = data.Chams_Trans / 100
		_G.CHAMS_SETTINGS.Transparency = t
		updateChamsTransparency(t)
	end

	if data.TB_Enabled ~= nil then
		TriggerbotSettings.Enabled = data.TB_Enabled
		if TriggerToggleRef then pcall(function() TriggerToggleRef.Value = data.TB_Enabled; TriggerToggleRef:FireChanged() end) end
	end
	if data.TB_Team ~= nil then
		TriggerbotSettings.TeamCheck = data.TB_Team
		if TriggerTeamRef then pcall(function() TriggerTeamRef.Value = data.TB_Team; TriggerTeamRef:FireChanged() end) end
	end
	if data.TB_Auto ~= nil then
		TriggerbotSettings.AutoGunMode = data.TB_Auto
		if TriggerAutoRef then pcall(function() TriggerAutoRef.Value = data.TB_Auto; TriggerAutoRef:FireChanged() end) end
	end
	if data.TB_Delay ~= nil then
		TriggerbotSettings.Delay = data.TB_Delay
		if TriggerDelayRef then pcall(function() TriggerDelayRef.Value = data.TB_Delay; TriggerDelayRef:FireChanged() end) end
	end
	if data.TB_Vis ~= nil then
		TriggerbotSettings.VisibilityCheck = data.TB_Vis
		if TriggerVisRef then pcall(function() TriggerVisRef.Value = data.TB_Vis; TriggerVisRef:FireChanged() end) end
	end
	if data.TB_Soft ~= nil then
		TriggerbotSettings.AllowSoftVisible = data.TB_Soft
		if TriggerSoftRef then pcall(function() TriggerSoftRef.Value = data.TB_Soft; TriggerSoftRef:FireChanged() end) end
	end

	if data.AB_Enabled ~= nil then
		AimbotSettings.Enabled = data.AB_Enabled
		if AimbotToggleRef then pcall(function() AimbotToggleRef.Value = data.AB_Enabled; AimbotToggleRef:FireChanged() end) end
		if data.AB_Enabled then enableAimbot() else disableAimbot() end
	end
	if data.AB_AlwaysOn ~= nil then
		AimbotSettings.AlwaysOn = data.AB_AlwaysOn
		if AimbotAlwaysRef then pcall(function() AimbotAlwaysRef.Value = data.AB_AlwaysOn; AimbotAlwaysRef:FireChanged() end) end
	end
	if data.AB_Camera ~= nil then
		AimbotSettings.UseCameraAim = data.AB_Camera
		if AimbotCameraRef then pcall(function() AimbotCameraRef.Value = data.AB_Camera; AimbotCameraRef:FireChanged() end) end
	end
	if data.AB_Team ~= nil then
		AimbotSettings.TeamCheck = data.AB_Team
		if AimbotTeamRef then pcall(function() AimbotTeamRef.Value = data.AB_Team; AimbotTeamRef:FireChanged() end) end
	end
	if data.AB_Smoothness ~= nil then
		AimbotSettings.Smoothness = data.AB_Smoothness
		if AimbotSmoothnessRef then pcall(function() AimbotSmoothnessRef.Value = data.AB_Smoothness; AimbotSmoothnessRef:FireChanged() end) end
	end
	if data.AB_FOV ~= nil then
		AimbotSettings.FOV = data.AB_FOV
		if AimbotFOVRef then pcall(function() AimbotFOVRef.Value = data.AB_FOV; AimbotFOVRef:FireChanged() end) end
		if AimbotSettings.FOVCircle then AimbotSettings.FOVCircle.Radius = data.AB_FOV end
	end
	if data.AB_OffsetY ~= nil then
		AimbotSettings.AimOffsetY = data.AB_OffsetY
		if AimbotOffsetRef then pcall(function() AimbotOffsetRef.Value = data.AB_OffsetY; AimbotOffsetRef:FireChanged() end) end
	end
	if data.AB_Part ~= nil then
		AimbotSettings.AimPart = data.AB_Part
		if AimbotPartRef then pcall(function() AimbotPartRef:Set(data.AB_Part) end) end
	end
end

local function loadConfig(name)
	if not name or name == "" then
		notify("Enter a config name first!", "Warning")
		return
	end
	local path = CONFIG_SUBDIR .. "/" .. name .. ".json"
	if not isfile(path) then
		notify(name .. " not found", "Error")
		return
	end
	local ok, raw = pcall(readfile, path)
	if not ok then
		notify("Could not read file", "Error")
		return
	end
	local ok2, data = pcall(decodeJSON, raw)
	if not ok2 or type(data) ~= "table" then
		notify("Corrupt config", "Error")
		return
	end
	applyConfig(data)
	notify("Config Loaded: " .. name, "Success")
end

local function deleteConfig(name)
	if not name or name == "" then return end
	local path = CONFIG_SUBDIR .. "/" .. name .. ".json"
	if isfile(path) then
		pcall(delfile, path)
		notify("Config Deleted: " .. name, "Info")
	else
		notify(name .. " not found", "Warning")
	end
end

local function setAutoload(name)
	if not name or name == "" then
		notify("Enter a config name", "Warning")
		return
	end
	pcall(writefile, AUTOLOAD_PATH, name)
	notify("Autoload Set: " .. name, "Success")
end

local function clearAutoload()
	if isfile(AUTOLOAD_PATH) then pcall(delfile, AUTOLOAD_PATH) end
	notify("Autoload Cleared", "Info")
end

-- ==================== NO RECOIL ====================
NoRecoilSettings = {
	Enabled = false,
	ActiveKey = Enum.UserInputType.MouseButton1,
	Sens = 1.0,
	Smoothness = 0.12
}
local targetX, targetY, targetZ = 0, 0, 0
local isFiring = false
local recoveryTime = 0

local function syncCamera()
	local x, y, z = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
	targetX, targetY, targetZ = x, y, z
end
syncCamera()

RunService:BindToRenderStep("DynamicZeroRecoil", Enum.RenderPriority.Camera.Value + 1, function(dt)
	if not NoRecoilSettings.Enabled then return end
	if UserInputService.MouseBehavior == Enum.MouseBehavior.Default then syncCamera() return end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then
		syncCamera(); return
	end
	local delta = UserInputService:GetMouseDelta()
	local _, _, realZ = Camera.CFrame:ToEulerAnglesYXZ()
	local flip = (Camera.CFrame.UpVector.Y < 0) and -1 or 1
	if UserInputService:IsMouseButtonPressed(NoRecoilSettings.ActiveKey) then
		isFiring = true; recoveryTime = 0.35
		targetY = targetY - math.rad(delta.X * NoRecoilSettings.Sens * 0.48 * flip)
		targetX = targetX - math.rad(delta.Y * NoRecoilSettings.Sens * 0.48)
		targetX = math.clamp(targetX, math.rad(-85), math.rad(85))
		Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(targetX, targetY, realZ)
	elseif isFiring and recoveryTime > 0 then
		recoveryTime = recoveryTime - dt
		if delta.Magnitude > 0 then
			targetY = targetY - math.rad(delta.X * NoRecoilSettings.Sens * 0.48 * flip)
			targetX = targetX - math.rad(delta.Y * NoRecoilSettings.Sens * 0.48)
			targetX = math.clamp(targetX, math.rad(-85), math.rad(85))
			Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(targetX, targetY, realZ)
		end
	else
		syncCamera(); isFiring = false
	end
end)

-- ==================== TABS ====================
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "rbxassetid://110090697336524" })
local CombatSub = CombatTab:AddSubTab("Combat", "rbxassetid://110090697336524")
local DiscordGrp = CombatSub:AddLeftGroupbox("Discord", "link")
local CombatLeft = CombatSub:AddLeftGroupbox("No Recoil", "crosshair")
local CombatRight = CombatSub:AddRightGroupbox("Aimbot", "crosshair")

local DiscordLabel = DiscordGrp:AddLabel({ Text = "Join discord for free keys!", DoesWrap = true, Size = 26 })

task.spawn(function()
	task.wait(0.5)
	local discordTextLabel = nil
	pcall(function()
		for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
			if desc:IsA("TextLabel") and desc.Text:find("discord") then
				discordTextLabel = desc
				break
			end
		end
	end)

	if discordTextLabel then
		discordTextLabel.RichText = false
		discordTextLabel.TextColor3 = Color3.fromRGB(157, 130, 250)
		discordTextLabel.Font = Enum.Font.GothamBold
		discordTextLabel.TextSize = 26
	end

	task.wait(0.3)

	local fullText = "Join discord for free keys!"
	local cursor = "_"
	while true do
		for i = 1, #fullText do
			pcall(function()
				DiscordLabel:SetText(string.sub(fullText, 1, i) .. cursor)
			end)
			pcall(function()
				if discordTextLabel and discordTextLabel.Parent then
					discordTextLabel.RichText = false
					discordTextLabel.TextColor3 = Color3.fromRGB(157, 130, 250)
					discordTextLabel.Font = Enum.Font.GothamBold
					discordTextLabel.TextSize = 26
				end
			end)
			task.wait(0.06)
		end
		pcall(function()
			DiscordLabel:SetText(fullText)
		end)
		pcall(function()
			if discordTextLabel and discordTextLabel.Parent then
				discordTextLabel.RichText = false
				discordTextLabel.TextColor3 = Color3.fromRGB(157, 130, 250)
				discordTextLabel.Font = Enum.Font.GothamBold
				discordTextLabel.TextSize = 26
			end
		end)
		task.wait(1.5)
		for i = #fullText, 0, -1 do
			pcall(function()
				DiscordLabel:SetText(string.sub(fullText, 1, i) .. cursor)
			end)
			pcall(function()
				if discordTextLabel and discordTextLabel.Parent then
					discordTextLabel.RichText = false
					discordTextLabel.TextColor3 = Color3.fromRGB(157, 130, 250)
					discordTextLabel.Font = Enum.Font.GothamBold
					discordTextLabel.TextSize = 26
				end
			end)
			task.wait(0.04)
		end
		pcall(function()
			DiscordLabel:SetText("")
		end)
		task.wait(0.5)
	end
end)

DiscordGrp:AddButton({ Text = "Copy Discord Link", Callback = function()
	pcall(function() setclipboard("https://discord.gg/ivory") end)
	notify("Discord Link Copied!", "Success")
end })

NoRecoilToggleRef = CombatLeft:AddToggle("NoRecoil", {
	Text = "No Recoil",
	Default = false,
	Callback = function(Value) NoRecoilSettings.Enabled = Value; if Value then syncCamera() end end,
})

NoRecoilSensRef = CombatLeft:AddSlider("NoRecoilSens", {
	Text = "No Recoil Sensitivity",
	Min = 0.1, Max = 2.0, Default = 1.0, Rounding = 1,
	Callback = function(Value) NoRecoilSettings.Sens = Value end,
})

NoRecoilSmoothRef = CombatLeft:AddSlider("NoRecoilSmooth", {
	Text = "No Recoil Smoothness",
	Min = 0.01, Max = 0.5, Default = 0.12, Rounding = 2,
	Callback = function(Value) NoRecoilSettings.Smoothness = Value end,
})

-- ==================== ESP TAB ====================
local tracerStartPos = "bottom"
local ESPTab = Window:AddTab({ Name = "ESP", Icon = "rbxassetid://110090697336524" })
local ESPSub = ESPTab:AddSubTab("ESP", "rbxassetid://110090697336524")
local ESPGrp = ESPSub:AddLeftGroupbox("ESP Settings", "eye")
local ChamsGrp = ESPSub:AddRightGroupbox("Chams", "palette")

_G.ESP_SETTINGS = {
	MainEnabled = false, Tracers = true, TracerStart = "bottom",
	HealthBar = true, Color = Color3.new(1,1,1), Skeletons = false, TeamCheck = false,
}
_G.ESP_Table = {}

-- ==================== VIEWMODEL CACHING ====================
local playerViewmodels = {}

local function getCharacterForViewmodel(viewmodel)
	if not viewmodel then return nil end
	local torso = viewmodel:FindFirstChild("torso")
	if not torso then return nil end
	local motor = torso:FindFirstChild("JointMotor")
	if motor and motor:IsA("Motor6D") and motor.Part0 then
		local char = motor.Part0.Parent
		if char and char:IsA("Model") and char:FindFirstChild("HumanoidRootPart") then
			return char
		end
	end
	return nil
end

local function linkViewmodelToPlayer(viewmodel)
	if not viewmodel or viewmodel.Name == "LocalViewmodel" then return end
	task.delay(0.3, function()
		if not viewmodel or not viewmodel.Parent then return end
		local torso = viewmodel:FindFirstChild("torso")
		if not torso then return end
		local motor = torso:FindFirstChild("JointMotor")
		if motor and motor:IsA("Motor6D") and motor.Part0 then
			local char = motor.Part0.Parent
			if char and char:IsA("Model") then
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Character == char then playerViewmodels[player] = viewmodel; return end
				end
				for _, player in ipairs(Players:GetPlayers()) do
					if player.Name == char.Name then playerViewmodels[player] = viewmodel; return end
				end
			end
		end
	end)
end

local function unlinkViewmodel(viewmodel)
	for player, vm in pairs(playerViewmodels) do
		if vm == viewmodel then playerViewmodels[player] = nil; break end
	end
end

local viewmodelsFolder = workspace:FindFirstChild("Viewmodels")
if viewmodelsFolder then
	for _, vm in ipairs(viewmodelsFolder:GetChildren()) do
		if vm:IsA("Model") then linkViewmodelToPlayer(vm) end
	end
	viewmodelsFolder.ChildAdded:Connect(function(vm)
		if vm:IsA("Model") then linkViewmodelToPlayer(vm) end
	end)
	viewmodelsFolder.ChildRemoved:Connect(function(vm) unlinkViewmodel(vm) end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function() playerViewmodels[player] = nil end)
end)

-- ==================== CHAMS SYSTEM ====================
_G.CHAMS_SETTINGS = { Enabled = false, Mode = "Visible", Transparency = 0.3, TeamCheck = true }
_G.chams_highlights = {}

local function isChamsTeammate(viewmodel)
	local char = getCharacterForViewmodel(viewmodel)
	if not char then return false end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Name == char.Name then
			return player.Team == LocalPlayer.Team
		end
	end
	return false
end

local function getChamsDepthMode()
	if _G.CHAMS_SETTINGS.Mode == "Visible" then
		return Enum.HighlightDepthMode.AlwaysOnTop
	else
		return Enum.HighlightDepthMode.Occluded
	end
end

local function createCham(viewmodel)
	if not viewmodel or viewmodel.Name == "LocalViewmodel" then return end
	if _G.chams_highlights[viewmodel] then return end
	task.delay(0.35, function()
		if not viewmodel or not viewmodel.Parent then return end
		if viewmodel.Name == "LocalViewmodel" then return end
		if _G.CHAMS_SETTINGS.TeamCheck and isChamsTeammate(viewmodel) then return end
		local hl = Instance.new("Highlight")
		hl.Name = "ChamsHighlight"
		hl.Adornee = viewmodel
		hl.FillColor = _G.ESPColor
		hl.OutlineColor = _G.ESPColor
		hl.FillTransparency = _G.CHAMS_SETTINGS.Transparency
		hl.OutlineTransparency = _G.CHAMS_SETTINGS.Transparency
		hl.DepthMode = getChamsDepthMode()
		hl.Enabled = _G.CHAMS_SETTINGS.Enabled
	hl.Parent = workspace
		_G.chams_highlights[viewmodel] = hl
	end)
end

local function removeCham(viewmodel)
	local hl = _G.chams_highlights[viewmodel]
	if hl then hl:Destroy(); _G.chams_highlights[viewmodel] = nil end
end

local function clearAllChams()
	for _, hl in pairs(_G.chams_highlights) do hl:Destroy() end
	_G.chams_highlights = {}
end

local function rebuildChams()
	clearAllChams()
	if not _G.CHAMS_SETTINGS.Enabled then return end
	local vms = workspace:FindFirstChild("Viewmodels")
	if not vms then return end
	for _, vm in ipairs(vms:GetChildren()) do
		if vm:IsA("Model") and vm.Name ~= "LocalViewmodel" then createCham(vm) end
	end
end

updateChamsColor = function(color)
	for _, hl in pairs(_G.chams_highlights) do
		hl.FillColor = color; hl.OutlineColor = color
	end
end

local function updateChamsTransparency(t)
	for _, hl in pairs(_G.chams_highlights) do
		hl.FillTransparency = t; hl.OutlineTransparency = t
	end
end

updateChamsDepthMode = function()
	local mode = getChamsDepthMode()
	for _, hl in pairs(_G.chams_highlights) do hl.DepthMode = mode end
end


if viewmodelsFolder then
	viewmodelsFolder.ChildAdded:Connect(function(vm)
		if vm:IsA("Model") and _G.CHAMS_SETTINGS.Enabled then createCham(vm) end
	end)
	viewmodelsFolder.ChildRemoved:Connect(function(vm) removeCham(vm) end)
	for _, vm in ipairs(viewmodelsFolder:GetChildren()) do
		if vm:IsA("Model") and vm.Name ~= "LocalViewmodel" then createCham(vm) end
	end
end

-- ==================== ESP FUNCTIONS ====================
local function setupESP()
	local ESP = _G.ESP_Table

	local function newDrawing(type2, props)
		local obj = Drawing.new(type2)
		for k,v in pairs(props) do obj[k] = v end
		return obj
	end

	local function hide(ui)
		ui.Box.Visible=false; ui.Tracer.Visible=false
		ui.Health.Visible=false; ui.Name.Visible=false
	end

	local function isTeammateViewmodel(vm)
		if not vm then return false end
		local char = getCharacterForViewmodel(vm)
		if not char then return false end
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Name == char.Name then
				return player.Team == LocalPlayer.Team
			end
		end
		return false
	end

	local function findCharESP(player)
		local vm = playerViewmodels[player]
		if vm then
			local char = getCharacterForViewmodel(vm)
			if char then
				local hum = char:FindFirstChildOfClass("Humanoid")
				local root = char:FindFirstChild("HumanoidRootPart")
				if hum and root then return char, hum, root end
			end
		end
		for _,model in ipairs(workspace:GetChildren()) do
			if model:IsA("Model") and model.Name == player.Name then
				local hum = model:FindFirstChildOfClass("Humanoid")
				local root = model:FindFirstChild("HumanoidRootPart")
				if hum and root then return model, hum, root end
			end
		end
		return nil
	end

	local function getBox(player)
		local vm = playerViewmodels[player]
		if not vm then return nil end
		if _G.ESP_SETTINGS.TeamCheck and isTeammateViewmodel(vm) then return nil end
		local cf, size = vm:GetBoundingBox()
		local top = cf.Position + Vector3.new(0, size.Y/2, 0)
		local bottom = cf.Position - Vector3.new(0, size.Y/2, 0)
		local topPos, vis1 = Camera:WorldToViewportPoint(top)
		local bottomPos, vis2 = Camera:WorldToViewportPoint(bottom)
		if not vis1 or not vis2 then return nil end
		local height = math.abs(topPos.Y - bottomPos.Y)
		local width = height / 2
		return Vector2.new(topPos.X - width/2, topPos.Y), width, height
	end

	local function getTracerStart()
		local vp = Camera.ViewportSize
		if tracerStartPos=="bottom" then return Vector2.new(vp.X/2, vp.Y)
		elseif tracerStartPos=="middle" then return Vector2.new(vp.X/2, vp.Y/2)
		elseif tracerStartPos=="top"    then return Vector2.new(vp.X/2, 0)
		elseif tracerStartPos=="left"   then return Vector2.new(0, vp.Y/2)
		elseif tracerStartPos=="right"  then return Vector2.new(vp.X, vp.Y/2)
		else return Vector2.new(vp.X/2, vp.Y) end
	end

	local function createESP(player)
		if player == LocalPlayer or ESP[player] then return end
		ESP[player] = {
			Player = player,
			Box    = newDrawing("Square", {Thickness=1, Filled=false, Color=_G.ESP_SETTINGS.Color, Visible=false}),
			Tracer = newDrawing("Line",   {Thickness=1, Color=_G.ESP_SETTINGS.Color, Visible=false}),
			Health = newDrawing("Line",   {Thickness=3, Visible=false}),
			Name   = newDrawing("Text",   {Size=13, Center=true, Outline=true, Font=2, Visible=false}),
			LastPosition = nil, StuckTime = 0
		}
	end

	for _,player in ipairs(Players:GetPlayers()) do createESP(player) end
	Players.PlayerAdded:Connect(createESP)

	local MAX_STUCK_TIME = 1.5

	RunService.RenderStepped:Connect(function(dt)
		if not (_G.ESP_SETTINGS.MainEnabled or _G.ESP_SETTINGS.Tracers or _G.ESP_SETTINGS.HealthBar) then
			for _,ui in pairs(ESP) do hide(ui) end
			return
		end
		for player,ui in pairs(ESP) do
			pcall(function()
				if player == LocalPlayer then hide(ui); return end
				if _G.ESP_SETTINGS.TeamCheck and player.Team == LocalPlayer.Team then hide(ui); return end
				local character, humanoid, root = findCharESP(player)
				if not character or not humanoid or humanoid.Health <= 0 then hide(ui); return end
				local pos, width, height = getBox(player)
				if not pos then hide(ui); return end
				if ui.LastPosition and (ui.LastPosition - pos).Magnitude < 1 then
					ui.StuckTime = ui.StuckTime + dt
				else
					ui.StuckTime = 0
				end
				if ui.StuckTime >= MAX_STUCK_TIME then hide(ui); return end
				ui.LastPosition = pos

				ui.Box.Visible = _G.ESP_SETTINGS.MainEnabled
				if _G.ESP_SETTINGS.MainEnabled then
					ui.Box.Size=Vector2.new(width,height); ui.Box.Position=pos; ui.Box.Color=_G.ESP_SETTINGS.Color
				end
				ui.Name.Visible = _G.ESP_SETTINGS.MainEnabled
				if _G.ESP_SETTINGS.MainEnabled then
					local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					ui.Name.Text = myRoot and player.Name.." ["..math.floor((myRoot.Position-root.Position).Magnitude).."m]" or player.Name
					ui.Name.Position = Vector2.new(pos.X+width/2, pos.Y-15)
				end
				if _G.ESP_SETTINGS.Tracers then
					ui.Tracer.From=getTracerStart(); ui.Tracer.To=Vector2.new(pos.X+width/2,pos.Y)
					ui.Tracer.Color=_G.ESP_SETTINGS.Color; ui.Tracer.Visible=true
				else
					ui.Tracer.Visible=false
				end
				if _G.ESP_SETTINGS.HealthBar then
					local hp = humanoid.Health/humanoid.MaxHealth
					local hh = height*hp
					ui.Health.From=Vector2.new(pos.X-5, pos.Y+height)
					ui.Health.To=Vector2.new(pos.X-5, pos.Y+height-hh)
					ui.Health.Color=Color3.fromRGB(255-(255*hp), 255*hp, 0)
					ui.Health.Visible=true
				else
					ui.Health.Visible=false
				end
			end)
		end
	end)
end

setupESP()

-- ==================== ESP UI ====================
ESPToggleRef = ESPGrp:AddToggle("ESPEnabled", {
	Text = "ESP", Default = false,
	Callback = function(Value) _G.ESP_SETTINGS.MainEnabled = Value end,
})

ESPTeamRef = ESPGrp:AddToggle("ESPTeamCheck", {
	Text = "Hide Teammates (ESP)", Default = false,
	Callback = function(Value) _G.ESP_SETTINGS.TeamCheck = Value end,
})

TracersRef = ESPGrp:AddToggle("Tracers", {
	Text = "Tracers", Default = true,
	Callback = function(Value) _G.ESP_SETTINGS.Tracers = Value end,
})

TracerPosRef = ESPGrp:AddSlider("TracerPos", {
	Text = "Tracer Position (0=B,1=M,2=T,3=L,4=R)", Min = 0, Max = 4, Default = 0, Rounding = 0,
	Callback = function(Value)
		local positions = {"bottom","middle","top","left","right"}
		local index = math.floor(Value + 0.5) + 1
		tracerStartPos = positions[index] or "bottom"
		_G.ESP_SETTINGS.TracerStart = tracerStartPos
	end,
})

HealthBarRef = ESPGrp:AddToggle("HealthBar", {
	Text = "Health Bars", Default = true,
	Callback = function(Value) _G.ESP_SETTINGS.HealthBar = Value end,
})

GadgetESPRef = ESPGrp:AddToggle("GadgetESP", {
	Text = "Gadget ESP", Default = false,
	Callback = function(Value)
		_G.GADGET_ESP_ENABLED = Value
		if not Value then for _,text in pairs(_G.gadgetESP_texts) do text.Visible=false end end
	end,
})

SkeletonsRef = ESPGrp:AddToggle("Skeletons", {
	Text = "Skeletons", Default = false,
	Callback = function(Value)
		_G.espSkeletons=Value; _G.ESP_ENABLED=Value; _G.ESP_SETTINGS.Skeletons=Value
	end,
})

-- ==================== GADGET ESP ====================
_G.GADGET_ESP_ENABLED = false
local gadgetNames = {
	"NeedleMine","Drone","RemoteC4","ToxicCharge","StickyCamera",
	"Claymore","ProximityAlarm","BulletproofCamera","DeployableShield",
	"BarbedWire","SignalDisruptor","ShockBattery"
}
_G.gadgetESP_texts = {}

local function isGadget(obj)
	for _, name in ipairs(gadgetNames) do if obj.Name == name then return true end end
	return false
end

local function getGadgetPosition(obj)
	if obj:IsA("BasePart") then return obj.Position
	elseif obj:IsA("Model") then
		local p = obj.PrimaryPart
		return p and p.Position or obj:GetPivot().Position
	end
	return nil
end

local function createGadgetESP(obj)
	if _G.gadgetESP_texts[obj] then return end
	local text = Drawing.new("Text")
	text.Visible=false; text.Size=14; text.Center=true; text.Outline=true
	text.OutlineColor=Color3.new(0,0,0); text.Font=2; text.Color=_G.ESPColor; text.Text=obj.Name
	_G.gadgetESP_texts[obj] = text
end

local function removeGadgetESP(obj)
	local text = _G.gadgetESP_texts[obj]
	if text then text:Remove(); _G.gadgetESP_texts[obj] = nil end
end

for _, child in ipairs(workspace:GetChildren()) do if isGadget(child) then createGadgetESP(child) end end
workspace.ChildAdded:Connect(function(child) if isGadget(child) then createGadgetESP(child) end end)
workspace.ChildRemoved:Connect(function(child) if isGadget(child) then removeGadgetESP(child) end end)

RunService.RenderStepped:Connect(function()
	for obj, text in pairs(_G.gadgetESP_texts) do
		if not obj or not obj.Parent then text:Remove(); _G.gadgetESP_texts[obj]=nil; continue end
		local worldPos = getGadgetPosition(obj)
		if not worldPos then text.Visible=false; continue end
		local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
		if onScreen then
			text.Position=Vector2.new(screenPos.X, screenPos.Y-20); text.Visible=_G.GADGET_ESP_ENABLED
		else
			text.Visible=false
		end
	end
end)

-- ==================== SKELETONS ====================
local bones = {
	{"torso","head"},{"torso","shoulder1"},{"torso","shoulder2"},
	{"shoulder1","arm1"},{"shoulder2","arm2"},{"torso","hip1"},
	{"torso","hip2"},{"hip1","leg1"},{"hip2","leg2"}
}
local required_bones = {"torso","head","shoulder1","shoulder2","arm1","arm2","hip1","hip2","leg1","leg2"}

_G.esp_list = {}
_G.skeleton_list = {}

local viewmodels = workspace:FindFirstChild("Viewmodels")
local camera = workspace.CurrentCamera
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() camera = workspace.CurrentCamera end)

local function isSkeletonTeammate(model)
	if not _G.ESP_SETTINGS.TeamCheck then return false end
	local char = getCharacterForViewmodel(model)
	if not char then return false end
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Name == char.Name then
			return player.Team == LocalPlayer.Team
		end
	end
	return false
end

_G.TeammateHighlights = _G.TeammateHighlights or {}
workspace.ChildAdded:Connect(function(child)
	if child:IsA("Highlight") then _G.TeammateHighlights[child] = true end
end)
workspace.ChildRemoved:Connect(function(child)
	if child:IsA("Highlight") then _G.TeammateHighlights[child] = nil end
end)

local function is_teammate(model)
	for highlight in pairs(_G.TeammateHighlights) do
		if highlight.Adornee == model and highlight.Name ~= "ChamsHighlight" then return true end
	end
	return isSkeletonTeammate(model)
end

local function is_valid(model)
	if not model or not model.Parent or model.Name=="LocalViewmodel" or not viewmodels or model.Parent~=viewmodels then return false end
	local torso = model:FindFirstChild("torso")
	return torso and torso:IsA("BasePart")
end

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = "IvorySkeletons"
screen_gui.Parent = gethui and gethui() or game:GetService("CoreGui")

local function remove_skeleton(character)
	local data = _G.skeleton_list[character]
	if not data then return end
	for _,line in ipairs(data.lines) do line:Remove() end
	_G.skeleton_list[character] = nil
end

local function create_skeleton(character)
	if not character or _G.skeleton_list[character] or not is_valid(character) then return end
	local char_bones = {}
	for _,name in ipairs(required_bones) do
		local b = character:FindFirstChild(name)
		if not b or not b:IsA("BasePart") then return end
		char_bones[name] = b
	end
	local lines = {}
	for i=1,#bones do
		local line = Drawing.new("Line")
		line.Visible=false; line.Color=_G.ESPColor; line.Thickness=1; line.Transparency=1
		lines[i] = line
	end
	_G.skeleton_list[character] = {lines=lines, bones=char_bones}
end

local function create_esp(character)
	if not character or not is_valid(character) or _G.esp_list[character] then return end
	local folder = Instance.new("Folder", screen_gui)
	local box    = Instance.new("Frame", folder)
	local stk    = Instance.new("UIStroke", box)
	box.BackgroundTransparency=1; box.BorderSizePixel=0
	stk.Color=_G.ESPColor; stk.Thickness=1
	_G.esp_list[character] = {folder=folder, box=box}
end

RunService.RenderStepped:Connect(function()
	for character, data in pairs(_G.esp_list) do
		local box = data.box; local folder = data.folder
		if not character or not character.Parent or not is_valid(character) then
			box.Visible=false; folder:Destroy()
			_G.esp_list[character]=nil; remove_skeleton(character); continue
		end
		local torso = character:FindFirstChild("torso")
		if not torso or torso.Transparency >= 1 or is_teammate(character) then box.Visible=false; continue end
		local pos, on_screen = camera:WorldToScreenPoint(torso.Position)
		if on_screen and (camera.CFrame.Position - torso.Position).Magnitude <= 3571.4 then
			if _G.espSkeletons then
				if not _G.skeleton_list[character] then create_skeleton(character) end
				local skel = _G.skeleton_list[character]
				if skel then
					local min_x,min_y = math.huge,math.huge
					local max_x,max_y = -math.huge,-math.huge
					for i,conn in ipairs(bones) do
						local b1,b2 = skel.bones[conn[1]], skel.bones[conn[2]]
						if b1 and b2 then
							local p1 = camera:WorldToViewportPoint(b1.Position)
							local p2 = camera:WorldToViewportPoint(b2.Position)
							local s1 = camera:WorldToScreenPoint(b1.Position)
							local s2 = camera:WorldToScreenPoint(b2.Position)
							if s1.Z>0 then min_x=math.min(min_x,s1.X);max_x=math.max(max_x,s1.X);min_y=math.min(min_y,s1.Y);max_y=math.max(max_y,s1.Y) end
							if s2.Z>0 then min_x=math.min(min_x,s2.X);max_x=math.max(max_x,s2.X);min_y=math.min(min_y,s2.Y);max_y=math.max(max_y,s2.Y) end
							if p1.Z>0 and p2.Z>0 then
								skel.lines[i].From=Vector2.new(p1.X,p1.Y)
								skel.lines[i].To=Vector2.new(p2.X,p2.Y)
								skel.lines[i].Visible=true
							else skel.lines[i].Visible=false end
						else skel.lines[i].Visible=false end
					end
					if _G.ESP_ENABLED and min_x~=math.huge then
						local pad=4; box.Visible=true
						box.Position=UDim2.fromOffset(min_x-pad, min_y-pad)
						box.Size=UDim2.fromOffset(max_x-min_x+pad*2, max_y-min_y+pad*2)
					else box.Visible=false end
				end
			else remove_skeleton(character); box.Visible=false end
		else box.Visible=false; remove_skeleton(character) end
	end
end)

if viewmodels then
	for _,v in ipairs(viewmodels:GetChildren()) do
		if v:IsA("Model") then task.delay(0.1, create_esp, v) end
	end
	viewmodels.ChildAdded:Connect(function(v)
		if v:IsA("Model") then task.delay(0.2, create_esp, v) end
	end)
	viewmodels.ChildRemoved:Connect(function(v)
		if _G.esp_list[v] then _G.esp_list[v].folder:Destroy(); _G.esp_list[v]=nil end
		remove_skeleton(v)
	end)
end

-- ==================== ESP COLOR ====================
ESPColorRef = ESPGrp:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = _G.ESPColor,
	Title = "ESP Color",
	Callback = function(Value)
		_G.ESPColor=Value; _G.ESP_SETTINGS.Color=Value
		for _,ui in pairs(_G.ESP_Table) do
			if ui.Box then ui.Box.Color=Value end
			if ui.Tracer then ui.Tracer.Color=Value end
		end
		for _,skel in pairs(_G.skeleton_list) do
			for _,line in ipairs(skel.lines) do line.Color=Value end
		end
		for _,d in pairs(_G.esp_list) do d.box.UIStroke.Color=Value end
		for _,text in pairs(_G.gadgetESP_texts) do text.Color=Value end
		updateChamsColor(Value)
	end,
})

-- ==================== CHAMS ====================
ChamsGrp:AddLabel("--- Chams ---")

ChamsToggleRef = ChamsGrp:AddToggle("ChamsEnabled", {
	Text = "Chams", Default = false,
	Callback = function(Value)
		_G.CHAMS_SETTINGS.Enabled = Value
		if Value then rebuildChams()
		else for _,hl in pairs(_G.chams_highlights) do hl.Enabled=false end end
	end,
})

ChamsTeamRef = ChamsGrp:AddToggle("ChamsTeamCheck", {
	Text = "Hide Teammates (Chams)", Default = true,
	Callback = function(Value) _G.CHAMS_SETTINGS.TeamCheck=Value; rebuildChams() end,
})

ChamsModeRef = ChamsGrp:AddDropdown("ChamsMode", {
	Text = "Chams Mode", Values = {"Visible","Not Visible"}, Default = "Visible",
	Callback = function(Value)
		_G.CHAMS_SETTINGS.Mode = (Value=="Not Visible") and "NotVisible" or "Visible"
		updateChamsDepthMode()
	end,
})

ChamsTransRef = ChamsGrp:AddSlider("ChamsTrans", {
	Text = "Chams Transparency", Min = 0, Max = 100, Default = 30, Rounding = 0,
	Callback = function(Value)
		local t = Value/100
		_G.CHAMS_SETTINGS.Transparency = t
		updateChamsTransparency(t)
	end,
})

-- ==================== OPTIMIZATIONS TAB ====================
local OptTab = Window:AddTab({ Name = "Optimizations", Icon = "rbxassetid://110090697336524" })
local OptGrp = OptTab:AddSubTab("Performance", "rbxassetid://110090697336524"):AddLeftGroupbox("Performance", "zap")

OptGrp:AddLabel("Warning: Optimize will break scoped weapons!")

local fullbrightBrightness = 2

OptGrp:AddSlider("FullbrightBrightness", {
	Text = "Fullbright Brightness", Min = 0, Max = 4, Default = 2, Rounding = 0,
	Callback = function(Value) fullbrightBrightness = Value end,
})

OptGrp:AddButton({ Text = "Fullbright", Callback = function()
	Lighting.Brightness=fullbrightBrightness; Lighting.ClockTime=14
	Lighting.FogEnd=100000; Lighting.GlobalShadows=false
	Lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
	notify("Brightness set to: "..fullbrightBrightness, "Success")
end })

local optimizeConnection = nil

OptGrp:AddButton({ Text = "Optimize", Callback = function()
	notify("This WILL break scoped weapons! Proceeding...", "Warning")
	task.wait(1)
	if optimizeConnection then optimizeConnection:Disconnect(); optimizeConnection=nil end
	local Terrain = workspace:FindFirstChildWhichIsA("Terrain")
	if Terrain then
		Terrain.WaterWaveSize=0; Terrain.WaterWaveSpeed=0
		Terrain.WaterReflectance=0; Terrain.WaterTransparency=1
	end
	Lighting.GlobalShadows=false; Lighting.FogEnd=9e9; Lighting.FogStart=9e9
	settings().Rendering.QualityLevel=1
	for _,v in pairs(game:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CastShadow=false; v.Material="Plastic"; v.Reflectance=0
			v.BackSurface="SmoothNoOutlines"; v.BottomSurface="SmoothNoOutlines"
			v.FrontSurface="SmoothNoOutlines"; v.LeftSurface="SmoothNoOutlines"
			v.RightSurface="SmoothNoOutlines"; v.TopSurface="SmoothNoOutlines"
		elseif v:IsA("Decal") then
			v.Transparency=1; v.Texture=""
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Lifetime=NumberRange.new(0)
		end
	end
	for _,v in pairs(Lighting:GetDescendants()) do
		if v:IsA("PostEffect") then v.Enabled=false end
	end
	optimizeConnection = workspace.DescendantAdded:Connect(function(child)
		task.spawn(function()
			if child:IsA("ForceField") or child:IsA("Sparkles") or child:IsA("Smoke")
			   or child:IsA("Fire") or child:IsA("Beam") then
				RunService.Heartbeat:Wait(); child:Destroy()
			elseif child:IsA("BasePart") then child.CastShadow=false end
		end)
	end)
	notify("Game optimized! (Scopes may be broken)", "Success")
end })

-- ==================== TRIGGERBOT ====================

CombatLeft:AddLabel("--- Triggerbot ---")

TriggerbotSettings = {
	Enabled = false, TeamCheck = false, AutoGunMode = false, Delay = 0,
	Connection = nil, IsWaiting = false, WaitStartTime = 0,
	IsFiring = false, IsPressed = false, LastClick = 0,
	ClickInterval = 0.05, VisibilityCheck = false, AllowSoftVisible = false,
}

local function findCharacter(player)
	local vm = playerViewmodels[player]
	if vm then
		local char = getCharacterForViewmodel(vm)
		if char then return char, char:FindFirstChildOfClass("Humanoid"), char:FindFirstChild("HumanoidRootPart") end
	end
	for _,model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model.Name==player.Name then
			local hum=model:FindFirstChildOfClass("Humanoid")
			local root=model:FindFirstChild("HumanoidRootPart")
			if hum and root then return model,hum,root end
		end
	end
	return nil
end

local function getPlayerScreenBox(character)
	local cf,size = character:GetBoundingBox()
	local top    = cf.Position + Vector3.new(0,size.Y/2,0)
	local bottom = cf.Position - Vector3.new(0,size.Y/2,0)
	local topPos,vis1    = Camera:WorldToViewportPoint(top)
	local bottomPos,vis2 = Camera:WorldToViewportPoint(bottom)
	if not vis1 or not vis2 then return nil end
	local height = math.abs(topPos.Y-bottomPos.Y)
	local width  = height/2
	return Vector2.new(topPos.X-width/2, topPos.Y), width, height
end

local function pointInBox(point, boxPos, boxWidth, boxHeight)
	local pad=5
	return point.X>=boxPos.X-pad and point.X<=boxPos.X+boxWidth+pad
	   and point.Y>=boxPos.Y-pad and point.Y<=boxPos.Y+boxHeight+pad
end

local function isPlayerVisible(targetPlayer)
	local localChar = LocalPlayer.Character
	if not localChar then return false end
	local targetChar,_,rootPart = findCharacter(targetPlayer)
	if not targetChar or not rootPart then return false end
	local cam = workspace.CurrentCamera
	local rayOrigin = cam.CFrame.Position
	local rayDirection = (rootPart.Position - rayOrigin)
	local rayLength = rayDirection.Magnitude
	local rayDir = rayDirection.Unit
	local filterList = {localChar}
	local vms2 = workspace:FindFirstChild("Viewmodels")
	if vms2 then
		local lvm = vms2:FindFirstChild("LocalViewmodel")
		if lvm then table.insert(filterList, lvm) end
	end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.FilterDescendantsInstances = filterList
	local rayResult = workspace:Raycast(rayOrigin, rayDir*rayLength, rayParams)
	if not rayResult then return true end
	local hitPart = rayResult.Instance
	if hitPart:IsDescendantOf(targetChar) then return true end
	if hitPart.Transparency > 0.2 then return true end
	if hitPart.CanCollide == false then return "soft_visible" end
	if hitPart:FindFirstChild("Breakable") then return "soft_visible" end
	return false
end

local function releaseMouse()
	if TriggerbotSettings.IsPressed then
		mouse1release(); TriggerbotSettings.IsPressed=false
	end
end

local function triggerbotLoop()
	TriggerbotSettings.Connection = RunService.RenderStepped:Connect(function(dt)
		if not TriggerbotSettings.Enabled then
			releaseMouse(); TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=false; return
		end
		if not LocalPlayer.Character or LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health<=0 then
			releaseMouse(); TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=false; return
		end
		if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			releaseMouse(); TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=false; return
		end
		local mousePos = UserInputService:GetMouseLocation()
		local validEnemy = false
		for _,player in ipairs(Players:GetPlayers()) do
			if player==LocalPlayer then continue end
			if TriggerbotSettings.TeamCheck and player.Team==LocalPlayer.Team then continue end
			local character,humanoid,root = findCharacter(player)
			if not character or not humanoid or humanoid.Health<=0 then continue end
			local boxPos,boxWidth,boxHeight = getPlayerScreenBox(character)
			if not boxPos then continue end
			if pointInBox(mousePos, boxPos, boxWidth, boxHeight) then
				if TriggerbotSettings.VisibilityCheck then
					local vis = isPlayerVisible(player)
					if vis==true then validEnemy=true; break
					elseif vis=="soft_visible" and TriggerbotSettings.AllowSoftVisible then validEnemy=true; break end
				else validEnemy=true; break end
			end
		end
		if not validEnemy then
			releaseMouse(); TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=false
		else
			if not TriggerbotSettings.IsFiring then
				if not TriggerbotSettings.IsWaiting then
					TriggerbotSettings.IsWaiting=true; TriggerbotSettings.WaitStartTime=tick()
				else
					local elapsed=(tick()-TriggerbotSettings.WaitStartTime)*1000
					if elapsed>=TriggerbotSettings.Delay then
						TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=true
					end
				end
			end
			if TriggerbotSettings.IsFiring then
				if TriggerbotSettings.AutoGunMode then
					if not TriggerbotSettings.IsPressed then mouse1press(); TriggerbotSettings.IsPressed=true end
				else
					releaseMouse()
					local now=tick()
					if now-TriggerbotSettings.LastClick>=TriggerbotSettings.ClickInterval then
						TriggerbotSettings.LastClick=now; mouse1click()
					end
				end
			end
		end
	end)
end

TriggerToggleRef = CombatLeft:AddToggle("Triggerbot", {
	Text = "Triggerbot", Default = false,
	Callback = function(Value)
		TriggerbotSettings.Enabled=Value
		if Value then
			if not TriggerbotSettings.Connection then triggerbotLoop() end
		else
			if TriggerbotSettings.Connection then TriggerbotSettings.Connection:Disconnect(); TriggerbotSettings.Connection=nil end
			releaseMouse(); TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=false
		end
	end,
})

TriggerTeamRef = CombatLeft:AddToggle("TriggerTeam", {
	Text = "Don't Shoot Teammates", Default = false,
	Callback = function(Value) TriggerbotSettings.TeamCheck=Value end,
})

TriggerAutoRef = CombatLeft:AddToggle("TriggerAuto", {
	Text = "Automatic or Semi gun", Default = false,
	Callback = function(Value)
		TriggerbotSettings.AutoGunMode=Value
		releaseMouse(); TriggerbotSettings.IsFiring=false; TriggerbotSettings.IsWaiting=false
	end,
})

TriggerDelayRef = CombatLeft:AddSlider("TriggerDelay", {
	Text = "Delay (MS)", Min = 0, Max = 400, Default = 0, Rounding = 0,
	Callback = function(Value) TriggerbotSettings.Delay=Value end,
})

TriggerVisRef = CombatLeft:AddToggle("TriggerVis", {
	Text = "Visibility Check", Default = false,
	Callback = function(Value) TriggerbotSettings.VisibilityCheck=Value end,
})

TriggerSoftRef = CombatLeft:AddToggle("TriggerSoft", {
	Text = "Allow Soft Visible", Default = false,
	Callback = function(Value) TriggerbotSettings.AllowSoftVisible=Value end,
})

-- ==================== AIMBOT ====================
local isMobile = UserInputService.TouchEnabled

AimbotSettings = {
	Enabled = false, Smoothness = 0, FOV = 150, AimOffsetY = 40,
	AimPart = "Head", RandomPart = nil, FOVCircle = nil,
	Connection = nil, WasRMBPressed = false, AlwaysOn = false,
	UseCameraAim = false, MobileScopeActive = false, TeamCheck = false,
	Keybind = nil,
}

local function getPlayerFromCharacter(character)
	if not character then return nil end
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr.Name==character.Name then return plr end
	end
	return nil
end

local function isValidAimbotTarget(vm)
	local char = getCharacterForViewmodel(vm)
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health<=0 then return false end
	local torso = vm:FindFirstChild("torso")
	if torso and hum.Health<=0 and torso.Transparency>=1 then return false end
	return true
end

local AimbotModeText = Drawing.new("Text")
AimbotModeText.Text=""; AimbotModeText.Size=18; AimbotModeText.Center=true
AimbotModeText.Outline=true; AimbotModeText.Color=Color3.new(1,1,1)
AimbotModeText.Visible=false
AimbotModeText.Position=Vector2.new(Camera.ViewportSize.X/2, 50)

local function updateAimbotIndicator()
	local mode
	if AimbotSettings.AlwaysOn then mode="Always Active"
	elseif isMobile then mode=AimbotSettings.MobileScopeActive and "Scope Toggle (ON)" or "Scope Toggle (OFF)"
	else mode="Hold RMB" end
	local method = AimbotSettings.UseCameraAim and " (Camera)" or " (Mouse)"
	local teamText = AimbotSettings.TeamCheck and " [No Teammates]" or ""
	AimbotModeText.Text = "Aimbot: "..mode..method..teamText
	AimbotModeText.Position = Vector2.new(Camera.ViewportSize.X/2, 50)
end

if isMobile then
	local function deactivateAimbotIfActive()
		if AimbotSettings.Enabled and AimbotSettings.MobileScopeActive then
			AimbotSettings.MobileScopeActive=false; AimbotSettings.WasRMBPressed=false
			updateAimbotIndicator()
		end
	end
	pcall(function()
		local sb=LocalPlayer:WaitForChild("PlayerGui",5):WaitForChild("Game",5):WaitForChild("Right",5):WaitForChild("Center",5):WaitForChild("ScopeButton",5)
		sb.Activated:Connect(function()
			AimbotSettings.MobileScopeActive=not AimbotSettings.MobileScopeActive
			if AimbotSettings.MobileScopeActive then AimbotSettings.WasRMBPressed=false end
			updateAimbotIndicator()
		end)
	end)
	pcall(function()
		local rb=LocalPlayer:WaitForChild("PlayerGui",5):WaitForChild("Game",5):WaitForChild("Right",5):WaitForChild("Center",5):WaitForChild("ReloadButton",5)
		rb.Activated:Connect(deactivateAimbotIfActive)
	end)
	pcall(function()
		local bi=LocalPlayer:WaitForChild("PlayerGui",5):WaitForChild("Game",5):WaitForChild("Right",5):WaitForChild("Bottom",5):WaitForChild("BackpackItems",5)
		for _,item in ipairs(bi:GetChildren()) do
			if item:IsA("ImageButton") or item:IsA("TextButton") then item.Activated:Connect(deactivateAimbotIfActive) end
		end
		bi.ChildAdded:Connect(function(item)
			if item:IsA("ImageButton") or item:IsA("TextButton") then item.Activated:Connect(deactivateAimbotIfActive) end
		end)
	end)
end

local function getViewmodelPartPosition(model, partName)
	if partName=="Head" then
		local h=model:FindFirstChild("head")
		if h and h:IsA("BasePart") then return h.Position end
	elseif partName=="Torso" then
		local t=model:FindFirstChild("torso")
		if t and t:IsA("BasePart") then return t.Position end
	elseif partName=="Feet" then
		local l=model:FindFirstChild("LeftFoot") or model:FindFirstChild("leftfoot")
		local r2=model:FindFirstChild("RightFoot") or model:FindFirstChild("rightfoot")
		if l and l:IsA("BasePart") then return l.Position end
		if r2 and r2:IsA("BasePart") then return r2.Position end
		local t=model:FindFirstChild("torso")
		if t and t:IsA("BasePart") then return t.Position end
	end
	for _,child in ipairs(model:GetChildren()) do
		if child:IsA("BasePart") and child.Name~="HumanoidRootPart" then return child.Position end
	end
	return nil
end

local aimPartOptions = {"Head","Torso","Feet"}

local function getClosestPartToCenter(partName)
	local center = Camera.ViewportSize/2
	local bestDist = AimbotSettings.FOV
	local bestTarget,bestWorldPos = nil,nil
	local vms3 = workspace:FindFirstChild("Viewmodels")
	if not vms3 then return nil,nil end
	for _,model in ipairs(vms3:GetChildren()) do
		if not model:IsA("Model") then continue end
		if model.Name=="LocalViewmodel" then continue end
		if not isValidAimbotTarget(model) then continue end
		if AimbotSettings.TeamCheck then
			local char = getCharacterForViewmodel(model)
			if char then
				local plr = getPlayerFromCharacter(char)
				if plr and plr.Team==LocalPlayer.Team then continue end
			end
		end
		local partPos = getViewmodelPartPosition(model, partName)
		if not partPos then continue end
		local screenPos, onScreen = Camera:WorldToScreenPoint(partPos)
		if not onScreen then continue end
		screenPos = Vector2.new(screenPos.X, screenPos.Y+AimbotSettings.AimOffsetY)
		local dist = (screenPos-center).Magnitude
		if dist<bestDist then bestDist=dist; bestTarget=screenPos; bestWorldPos=partPos end
	end
	return bestTarget, bestWorldPos
end

local function aimbotLoop()
	AimbotSettings.Connection = RunService.RenderStepped:Connect(function(dt)
		if not AimbotSettings.Enabled then return end
		local rmbPressed
		if AimbotSettings.AlwaysOn then rmbPressed=true
		elseif isMobile then rmbPressed=AimbotSettings.MobileScopeActive
		else rmbPressed=UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
		if not rmbPressed then
			AimbotSettings.WasRMBPressed=false; AimbotSettings.RandomPart=nil; return
		end
		if not AimbotSettings.WasRMBPressed then
			AimbotSettings.WasRMBPressed=true
			if AimbotSettings.AimPart=="Random" then
				AimbotSettings.RandomPart=aimPartOptions[math.random(#aimPartOptions)]
			else AimbotSettings.RandomPart=nil end
		end
		local currentPart = (AimbotSettings.AimPart=="Random" and AimbotSettings.RandomPart) or AimbotSettings.AimPart
		local screenTarget, worldTarget = getClosestPartToCenter(currentPart)
		if not screenTarget then return end
		local center = Camera.ViewportSize/2
		local smoothness = AimbotSettings.Smoothness
		local factor = (smoothness<=0) and 1 or math.clamp(1-(smoothness/10), 0.05, 1)
		if AimbotSettings.UseCameraAim and worldTarget then
			local desiredLook = CFrame.lookAt(Camera.CFrame.Position, worldTarget)
			Camera.CFrame = Camera.CFrame:Lerp(desiredLook, factor)
		else
			local delta = screenTarget-center
			mousemoverel(delta.X*factor, delta.Y*factor)
		end
	end)
end

local function enableAimbot()
	AimbotSettings.Enabled = true
	if not AimbotSettings.Connection then aimbotLoop() end
	if not AimbotSettings.FOVCircle then
		AimbotSettings.FOVCircle = Drawing.new("Circle")
		AimbotSettings.FOVCircle.Visible=false; AimbotSettings.FOVCircle.Color=Color3.new(1,1,1)
		AimbotSettings.FOVCircle.Thickness=1; AimbotSettings.FOVCircle.Filled=false
		AimbotSettings.FOVCircle.Transparency=1
		AimbotSettings.FOVCircle.Position=Camera.ViewportSize/2
		AimbotSettings.FOVCircle.Radius=AimbotSettings.FOV
	end
	AimbotSettings.FOVCircle.Visible=true
	AimbotModeText.Visible=true
	updateAimbotIndicator()
end

local function disableAimbot()
	AimbotSettings.Enabled = false
	if AimbotSettings.Connection then AimbotSettings.Connection:Disconnect(); AimbotSettings.Connection=nil end
	if AimbotSettings.FOVCircle then AimbotSettings.FOVCircle.Visible=false end
	AimbotSettings.WasRMBPressed=false; AimbotSettings.RandomPart=nil
	AimbotModeText.Visible=false
end

buildConfigSnapshot = function()
	return {
		NoRecoil_Enabled    = NoRecoilSettings.Enabled,
		NoRecoil_Sens       = NoRecoilSettings.Sens,
		NoRecoil_Smoothness = NoRecoilSettings.Smoothness,
		ESP_Main       = _G.ESP_SETTINGS.MainEnabled,
		ESP_Team       = _G.ESP_SETTINGS.TeamCheck,
		ESP_Tracers    = _G.ESP_SETTINGS.Tracers,
		ESP_TracerPos  = _G.ESP_SETTINGS.TracerStart,
		ESP_HealthBar  = _G.ESP_SETTINGS.HealthBar,
		ESP_Skeletons  = _G.ESP_SETTINGS.Skeletons,
		ESP_Color      = colorToTable(_G.ESPColor),
		GadgetESP      = _G.GADGET_ESP_ENABLED,
		Chams_Enabled  = _G.CHAMS_SETTINGS.Enabled,
		Chams_Team     = _G.CHAMS_SETTINGS.TeamCheck,
		Chams_Mode     = _G.CHAMS_SETTINGS.Mode,
		Chams_Trans    = math.floor(_G.CHAMS_SETTINGS.Transparency * 100),
		TB_Enabled     = TriggerbotSettings.Enabled,
		TB_Team        = TriggerbotSettings.TeamCheck,
		TB_Auto        = TriggerbotSettings.AutoGunMode,
		TB_Delay       = TriggerbotSettings.Delay,
		TB_Vis         = TriggerbotSettings.VisibilityCheck,
		TB_Soft        = TriggerbotSettings.AllowSoftVisible,
		AB_Enabled     = AimbotSettings.Enabled,
		AB_AlwaysOn    = AimbotSettings.AlwaysOn,
		AB_Camera      = AimbotSettings.UseCameraAim,
		AB_Team        = AimbotSettings.TeamCheck,
		AB_Smoothness  = AimbotSettings.Smoothness,
		AB_FOV         = AimbotSettings.FOV,
		AB_OffsetY     = AimbotSettings.AimOffsetY,
		AB_Part        = AimbotSettings.AimPart,
	}
end

CombatRight:AddLabel("--- Aimbot ---")

AimbotToggleRef = CombatRight:AddToggle("AimbotEnabled", {
	Text = "Aimbot", Default = false,
	Callback = function(Value) if Value then enableAimbot() else disableAimbot() end end,
})

AimbotAlwaysRef = CombatRight:AddToggle("AimbotAlways", {
	Text = "Always On", Default = false,
	Callback = function(Value) AimbotSettings.AlwaysOn=Value; updateAimbotIndicator() end,
})

AimbotCameraRef = CombatRight:AddToggle("AimbotCamera", {
	Text = "Camera Aim (Silent)", Default = false,
	Callback = function(Value) AimbotSettings.UseCameraAim=Value; updateAimbotIndicator() end,
})

AimbotTeamRef = CombatRight:AddToggle("AimbotTeam", {
	Text = "Don't Target Teammates", Default = false,
	Callback = function(Value) AimbotSettings.TeamCheck=Value; updateAimbotIndicator() end,
})

AimbotPartRef = CombatRight:AddDropdown("AimPart", {
	Text = "Aim Part", Values = {"Head","Torso","Random"}, Default = "Head",
	Callback = function(Value)
		AimbotSettings.AimPart = Value
		if Value ~= "Random" then AimbotSettings.RandomPart=nil end
	end,
})

AimbotSmoothnessRef = CombatRight:AddSlider("AimbotSmooth", {
	Text = "Smoothness", Min = 0, Max = 20, Default = 0, Rounding = 0,
	Callback = function(Value) AimbotSettings.Smoothness=Value end,
})

AimbotFOVRef = CombatRight:AddSlider("AimbotFOV", {
	Text = "FOV", Min = 30, Max = 750, Default = 150, Rounding = 0,
	Callback = function(Value)
		AimbotSettings.FOV=Value
		if AimbotSettings.FOVCircle then AimbotSettings.FOVCircle.Radius=Value end
	end,
})

AimbotOffsetRef = CombatRight:AddSlider("AimbotOffset", {
	Text = "Aim Offset Y", Min = -60, Max = 60, Default = 40, Rounding = 0,
	Callback = function(Value) AimbotSettings.AimOffsetY=Value end,
})

RunService.RenderStepped:Connect(function()
	if AimbotSettings.FOVCircle and AimbotSettings.FOVCircle.Visible then
		AimbotSettings.FOVCircle.Position = Camera.ViewportSize/2
	end
end)

-- ==================== UTILITY TAB ====================
local UtilityTab = Window:AddTab({ Name = "Utilities", Icon = "rbxassetid://110090697336524" })
local UtilSub = UtilityTab:AddSubTab("Utilities", "rbxassetid://110090697336524")
local UtilGrp = UtilSub:AddLeftGroupbox("Tools", "wrench")

UtilGrp:AddButton({ Text = "Check Account Ages", Callback = function()
	local allPlayers = Players:GetPlayers()
	if #allPlayers==0 then notify("No players in the server.", "Warning"); return end
	for _,player in ipairs(allPlayers) do
		local ageDays=player.AccountAge
		local ageDisplay = ageDays>=365 and string.format("%.1f years",ageDays/365) or ageDays.." days"
		local classification=""
		if ageDays<20 then classification=" - POSSIBLE CHEATER"
		elseif ageDays<40 then classification=" - VERY SUSPICIOUS"
		elseif ageDays<60 then classification=" - SUSPICIOUS" end
		notify(player.Name..": "..ageDisplay..classification, "Info")
		task.wait(2)
	end
end })

local transparencyValue = 50

UtilGrp:AddLabel("Warning: Applying transparency to breakables may lag.")

UtilGrp:AddSlider("BreakableTrans", {
	Text = "Breakable Transparency", Min = 0, Max = 100, Default = 50, Rounding = 0,
	Callback = function(Value) transparencyValue=Value end,
})

UtilGrp:AddButton({ Text = "Apply Transparency to Breakables", Callback = function()
	local count=0
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj:FindFirstChild("Breakable") then
			obj.Transparency=transparencyValue/100; count=count+1
		end
	end
	notify("Updated "..count.." breakable objects.", "Success")
end })

-- ==================== SETTINGS TAB ====================
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "rbxassetid://110090697336524" })
local SettingsSub = SettingsTab:AddSubTab("Settings", "rbxassetid://110090697336524")
local SettingsLeft = SettingsSub:AddLeftGroupbox("Credits", "heart")
local SettingsRight = SettingsSub:AddRightGroupbox("Configuration", "save")

-- ==================== LEFT: CREDITS ====================
local CreditLabel = SettingsLeft:AddLabel({ Text = "Made by Mommy Veqxoo", DoesWrap = true, Size = 26 })

task.spawn(function()
	task.wait(0.5)

	local creditTextLabel = nil
	pcall(function()
		for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
			if desc:IsA("TextLabel") and desc.Text:find("Veqxoo") then
				creditTextLabel = desc
				break
			end
		end
	end)

	if creditTextLabel then
		creditTextLabel.RichText = false
		creditTextLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
		creditTextLabel.Font = Enum.Font.GothamBold
		creditTextLabel.TextSize = 26
	end

	task.wait(0.3)

	local fullText = "Made by Mommy Veqxoo </3"
	local cursor = "_"
	while true do
		for i = 1, #fullText do
			pcall(function()
				CreditLabel:SetText(string.sub(fullText, 1, i) .. cursor)
			end)
			pcall(function()
				if creditTextLabel and creditTextLabel.Parent then
					creditTextLabel.RichText = false
					creditTextLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
					creditTextLabel.Font = Enum.Font.GothamBold
					creditTextLabel.TextSize = 26
				end
			end)
			task.wait(0.06)
		end
		pcall(function()
			CreditLabel:SetText(fullText)
		end)
		pcall(function()
			if creditTextLabel and creditTextLabel.Parent then
				creditTextLabel.RichText = false
				creditTextLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
				creditTextLabel.Font = Enum.Font.GothamBold
				creditTextLabel.TextSize = 26
			end
		end)
		task.wait(1.5)
		for i = #fullText, 0, -1 do
			pcall(function()
				CreditLabel:SetText(string.sub(fullText, 1, i) .. cursor)
			end)
			pcall(function()
				if creditTextLabel and creditTextLabel.Parent then
					creditTextLabel.RichText = false
					creditTextLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
					creditTextLabel.Font = Enum.Font.GothamBold
					creditTextLabel.TextSize = 26
				end
			end)
			task.wait(0.03)
		end
		task.wait(0.5)
	end
end)

-- ==================== LEFT: THEMES ====================
SettingsLeft:AddLabel("Theme Colors")

SettingsLeft:AddLabel("Background"):AddColorPicker("ThemeBG", {
	Default = Color3.fromRGB(20, 20, 30),
	Title = "Background Color",
	Callback = function(Value)
		pcall(function()
			local gui = Library.ScreenGui
			if gui then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("Frame") and obj.BackgroundTransparency < 0.5 then
						obj.BackgroundColor3 = Value
					end
				end
			end
		end)
	end,
})

SettingsLeft:AddLabel("Main"):AddColorPicker("ThemeMain", {
	Default = Color3.fromRGB(30, 30, 45),
	Title = "Main Color",
	Callback = function(Value)
		pcall(function()
			local gui = Library.ScreenGui
			if gui then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("Frame") and obj.BackgroundTransparency < 0.5 then
						obj.BackgroundColor3 = Value
					end
				end
			end
		end)
	end,
})

SettingsLeft:AddLabel("Accent"):AddColorPicker("ThemeAccent", {
	Default = Color3.fromRGB(128, 0, 255),
	Title = "Accent Color",
	Callback = function(Value)
		if Library.SetAccent then pcall(function() Library:SetAccent(Value) end) end
	end,
})

SettingsLeft:AddLabel("Outline"):AddColorPicker("ThemeOutline", {
	Default = Color3.fromRGB(60, 60, 80),
	Title = "Outline Color",
	Callback = function(Value)
		pcall(function()
			local gui = Library.ScreenGui
			if gui then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("UIStroke") then
						obj.Color = Value
					end
				end
			end
		end)
	end,
})

SettingsLeft:AddLabel("Font"):AddColorPicker("ThemeFont", {
	Default = Color3.fromRGB(255, 255, 255),
	Title = "Font Color",
	Callback = function(Value)
		pcall(function()
			local gui = Library.ScreenGui
			if gui then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("TextLabel") or obj:IsA("TextButton") then
						obj.TextColor3 = Value
					end
				end
			end
		end)
	end,
})

SettingsLeft:AddDropdown("ThemeFontFace", {
	Text = "Font Face", Values = {"Code", "Gotham", "GothamBold", "GothamMedium", "Legacy", "SourceSans", "SourceSansBold"}, Default = "Code",
	Callback = function(Value)
		pcall(function()
			local gui = Library.ScreenGui
			if gui then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
						obj.Font = Enum.Font[Value] or Enum.Font.Code
					end
				end
			end
		end)
	end,
})

SettingsLeft:AddDropdown("ThemeList", {
	Text = "Theme List", Values = {"Default", "Midnight", "Ocean", "Sunset", "Matrix"}, Default = "Default",
	Callback = function(Value) notify("Theme: " .. Value, "Info") end,
})

SettingsLeft:AddButton({ Text = "Set as Default", Callback = function()
	notify("Default theme saved", "Success")
end })

-- ==================== RIGHT: CONFIGURATION ====================
SettingsRight:AddLabel("Config Manager")

configNameValue = ""
ConfigNameInput = SettingsRight:AddInput("ConfigName", {
	Text = "Config Name", Default = "", Placeholder = "myconfig",
	Callback = function(v) configNameValue = v end,
})

SettingsRight:AddButton({ Text = "Create Config", Callback = function() saveConfig(configNameValue) end })

local initialNames = listConfigs()
initialNames[#initialNames+1] = "---"

ConfigListRef = SettingsRight:AddDropdown("ConfigList", {
	Text = "Config List", Values = initialNames, Default = "---",
	Callback = function(Value)
		if Value ~= "---" then
			configNameValue = Value
			pcall(function() ConfigNameInput:Set(Value) end)
		end
	end,
})

SettingsRight:AddButton({ Text = "Load Config", Callback = function() loadConfig(configNameValue) end })

SettingsRight:AddButton({ Text = "Overwrite Config", Callback = function()
	if not configNameValue or configNameValue == "" then
		notify("Enter a config name first!", "Warning")
		return
	end
	saveConfig(configNameValue)
end })

SettingsRight:AddButton({ Text = "Delete Config", Callback = function()
	deleteConfig(configNameValue)
	local names = listConfigs()
	names[#names+1] = "---"
	if ConfigListRef then pcall(function() ConfigListRef:Refresh(names, "---") end) end
end })

SettingsRight:AddButton({ Text = "Refresh List", Callback = function()
	local names = listConfigs()
	names[#names+1] = "---"
	pcall(function() ConfigListRef:Refresh(names, "---") end)
	notify("List refreshed ("..tostring(#names-1).." configs)", "Info")
end })

SettingsRight:AddButton({ Text = "Set as Autoload", Callback = function()
	setAutoload(configNameValue)
	if autoloadLabel then pcall(function() autoloadLabel:Set("Current autoload config: " .. configNameValue) end) end
end })

SettingsRight:AddButton({ Text = "Reset Autoload", Callback = function()
	clearAutoload()
	if autoloadLabel then pcall(function() autoloadLabel:Set("Current autoload config: none") end) end
end })

autoloadLabel = SettingsRight:AddLabel("Current autoload config: none")

configJSONValue = ""
SettingsRight:AddInput("ConfigJSON", {
	Text = "Config JSON", Default = "", Placeholder = "paste config JSON here",
	Callback = function(v) configJSONValue = v end,
})

SettingsRight:AddButton({ Text = "Import Config", Callback = function()
	if not configNameValue or configNameValue == "" then
		notify("Enter a config name first!", "Warning")
		return
	end
	if not configJSONValue or configJSONValue == "" then
		notify("Paste config JSON first!", "Warning")
		return
	end
	local ok2, data = pcall(decodeJSON, configJSONValue)
	if not ok2 or type(data) ~= "table" then
		notify("Invalid JSON", "Error")
		return
	end
	local path = CONFIG_SUBDIR .. "/" .. configNameValue .. ".json"
	pcall(writefile, path, configJSONValue)
	notify("Config imported: " .. configNameValue, "Success")
end })

SettingsRight:AddButton({ Text = "Export Current Config", Callback = function()
	if not configNameValue or configNameValue == "" then
		notify("Enter a config name first!", "Warning")
		return
	end
	local path = CONFIG_SUBDIR .. "/" .. configNameValue .. ".json"
	if not isfile(path) then
		notify(configNameValue .. " not found", "Error")
		return
	end
	local ok, raw = pcall(readfile, path)
	if ok and raw then
		pcall(setclipboard, raw)
		notify("Config JSON copied to clipboard", "Success")
	end
end })

SettingsRight:AddButton({ Text = "Unload Cheat", Callback = function()
	notify("Unloading...", "Warning")
	NoRecoilSettings.Enabled=false
	pcall(function() RunService:UnbindFromRenderStep("DynamicZeroRecoil") end)
	_G.ESP_SETTINGS.MainEnabled=false; _G.ESP_SETTINGS.Tracers=false
	_G.ESP_SETTINGS.HealthBar=false; _G.espSkeletons=false
	_G.ESP_ENABLED=false; _G.GADGET_ESP_ENABLED=false
	_G.CHAMS_SETTINGS.Enabled=false; clearAllChams()
	for _,ui in pairs(_G.ESP_Table) do
		if ui.Box then ui.Box:Remove() end; if ui.Tracer then ui.Tracer:Remove() end
		if ui.Health then ui.Health:Remove() end; if ui.Name then ui.Name:Remove() end
	end
	_G.ESP_Table={}
	for _,data in pairs(_G.skeleton_list) do for _,line in ipairs(data.lines) do line:Remove() end end
	_G.skeleton_list={}
	for _,data in pairs(_G.esp_list) do data.folder:Destroy() end
	_G.esp_list={}
	for _,text in pairs(_G.gadgetESP_texts) do text:Remove() end
	_G.gadgetESP_texts={}
	TriggerbotSettings.Enabled=false
	if TriggerbotSettings.Connection then TriggerbotSettings.Connection:Disconnect(); TriggerbotSettings.Connection=nil end
	releaseMouse(); TriggerbotSettings.IsWaiting=false; TriggerbotSettings.IsFiring=false; TriggerbotSettings.IsPressed=false
	disableAimbot()
	if AimbotSettings.FOVCircle then AimbotSettings.FOVCircle:Remove(); AimbotSettings.FOVCircle=nil end
	AimbotModeText:Remove()
	if optimizeConnection then optimizeConnection:Disconnect(); optimizeConnection=nil end
	for player in pairs(playerViewmodels) do playerViewmodels[player]=nil end
	screen_gui:Destroy()
	pcall(function() Library.ScreenGui:Destroy() end)
	notify("Cheat fully unloaded", "Info")
end })

-- ==================== RIGHTSHIFT TOGGLE ====================
local menuOpen = true

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		menuOpen = not menuOpen
		if Library.ScreenGui then
			Library.ScreenGui.Enabled = menuOpen
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not menuOpen and Library.ScreenGui and Library.ScreenGui.Enabled then
		Library.ScreenGui.Enabled = false
	end
end)

RunService.Heartbeat:Connect(function()
	if not menuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
		if Library.ScreenGui and Library.ScreenGui.Enabled then
			Library.ScreenGui.Enabled = false
		end
	end
end)

-- ==================== AUTOLOAD ON INJECT ====================
task.delay(0.5, function()
	if isfile(AUTOLOAD_PATH) then
		local ok, name = pcall(readfile, AUTOLOAD_PATH)
		if ok and name and name ~= "" then
			name = name:gsub("%s+","")
			if name ~= "" then
				notify("Loading config: \""..name.."\"", "Info")
				task.wait(0.3)
				loadConfig(name)
			end
		end
	end
end)
