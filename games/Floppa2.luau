--// Raise a Floppa 2 - Ivory Hub (Full)
--// PlaceId: 9772878203

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local WS = game:GetService("Workspace")
local LP = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")
local Lighting = game:GetService("Lighting")

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

local genv = getgenv()

local Events = RS:WaitForChild("Events")
local R = {
	CollectRent = Events["Collect Rent 2"], RaiseRent = Events["Raise Rent 2"],
	Cooking = Events.Cooking, Brew = Events.Brew, Rain = Events.Rain,
	Rebirth = Events.Rebirth, Save = Events.Save, Unlock = Events.Unlock,
	SmallVault = Events["Small Vault"], BigVault = Events["Big Vault"],
	SlotsSpin = Events["Slots Spin"], Planter = Events.Planter,
	MagicLamp = Events["Magic Lamp"], RebirthVault = Events["Rebirth Vault"],
	FloppaSlots = Events["Floppa Slots"], LockVault = Events["Lock Vault"],
	Ascend = Events.Ascend, Skin = Events.Skin, Wormhole = Events.Wormhole,
}

local S = {
	AutoClick = false, AutoPet = false, ClickSpeed = 0.1,
	AutoCollectDrops = false, AutoPayRent = false, AutoCleanPoop = false,
	AutoRefillBowls = false, AutoCollectRoommateRent = false,
	AutoInterwebs = false, AutoFishing = false,
	BackroomsBypass = false, AutoAlmondWater = false,
	AutoPlant = false, AutoCook = false,
	AntiRaid = false, AltarAutoFight = false, RaidFailSafe = false,
	InfJump = false, Noclip = false, AntiAfk = false,
	SpeedBoost = false, SpeedValue = 16, JumpBoost = false, JumpValue = 50,
	ESPEnabled = false, ESPEggs = true, ESPItems = true, ESPEnemies = true,
	ESPColor = Color3.fromRGB(255, 80, 80),
	AutoRebirth = false, AutoSave = false, AutoSlots = false,
	ReduceLag = false,
}
genv.FLOPPA_STATE = S

local function gHRP() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function gHum() local c = LP.Character; return c and c:FindFirstChildWhichIsA("Humanoid") end
local function alive() local c = LP.Character; if not c then return false end; local h = c:FindFirstChildWhichIsA("Humanoid"); return h and h.Health > 0 end
local function getFloppa() return WS:FindFirstChild("Floppa") end

-- ESP
local espC = {}
local function clearESP() for _, o in pairs(espC) do pcall(function() if o and o.Parent then o:Destroy() end end) end; espC = {} end
local function mkESP(p, t, c) if not p or not p.Parent then return end; local b = Instance.new("BillboardGui"); b.Name = "IvoryESP"; b.Adornee = p; b.Size = UDim2.new(0, 140, 0, 30); b.StudsOffset = Vector3.new(0, 3, 0); b.AlwaysOnTop = true; b.LightInfluence = 0; local l = Instance.new("TextLabel"); l.Parent = b; l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 0.5; l.BackgroundColor3 = Color3.new(0, 0, 0); l.TextColor3 = c; l.TextStrokeTransparency = 0.3; l.TextScaled = true; l.Font = Enum.Font.GothamBold; l.Text = t; b.Parent = LP:WaitForChild("PlayerGui"); table.insert(espC, b) end
local function updateESP()
	clearESP(); if not S.ESPEnabled then return end
	local hrp = gHRP(); if not hrp then return end
	if S.ESPEggs then
		local f = getFloppa()
		if f and f:FindFirstChild("HumanoidRootPart") then mkESP(f.HumanoidRootPart, "Floppa [H:" .. (f:FindFirstChild("Display") and f.Display:FindFirstChild("Happiness") and f.Display.Happiness.Text or "?") .. "]", Color3.fromRGB(255, 200, 50)) end
	end
	if S.ESPEnemies then
		for _, e in ipairs(WS:FindFirstChild("Enemies") and WS.Enemies:GetChildren() or {}) do
			if e:FindFirstChild("HumanoidRootPart") then mkESP(e.HumanoidRootPart, e.Name, Color3.fromRGB(255, 50, 50)) end
		end
	end
	if S.ESPItems then
		for _, d in ipairs(WS:GetDescendants()) do
			if d:IsA("BasePart") and (d.Name:find("Cash") or d.Name:find("Gold") or d.Name:find("Key") or d.Name:find("Meteorite")) then
				local d2 = (d.Position - hrp.Position).Magnitude; if d2 < 100 then mkESP(d, d.Name .. " [" .. math.floor(d2) .. "m]", Color3.fromRGB(100, 255, 100)) end
			end
		end
	end
end

--// WINDOW
local Window = Library.CreateWindow({
	Name = "Ivory", Width = 460, Height = 360,
})

-- ═══ MAIN TAB ═══
local MainTab = Window:CreateTab("Main")

local FarmSec = MainTab:CreateSection("Farm")
FarmSec:CreateToggle("AutoClick", { Text = "Auto Click Floppa", Default = false, Callback = function(v) S.AutoClick = v end }):CreateKeybind("ClickKey", { Default = "None", Text = "Click Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })
FarmSec:CreateToggle("AutoPet", { Text = "Auto Pet Floppa", Default = false, Callback = function(v) S.AutoPet = v end }):CreateKeybind("PetKey", { Default = "None", Text = "Pet Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })
FarmSec:CreateSlider("ClickSpeed", { Text = "Click Speed", Default = 0.1, Min = 0.02, Max = 1, Rounding = 2, Suffix = "s", Callback = function(v) S.ClickSpeed = v end })
FarmSec:CreateToggle("AutoCollectDrops", { Text = "Auto Collect Drops", Default = false, Callback = function(v) S.AutoCollectDrops = v end })
FarmSec:CreateToggle("AutoCleanPoop", { Text = "Auto Clean Poop", Default = false, Callback = function(v) S.AutoCleanPoop = v end })

local RentSec = MainTab:CreateSection("Rent & Bowls")
RentSec:CreateToggle("AutoPayRent", { Text = "Auto Pay Rent", Default = false, Callback = function(v) S.AutoPayRent = v end })
RentSec:CreateToggle("AutoCollectRoommateRent", { Text = "Auto Collect Roommate Rent", Default = false, Callback = function(v) S.AutoCollectRoommateRent = v end })
RentSec:CreateToggle("AutoRefillBowls", { Text = "Auto Refill Bowls", Default = false, Callback = function(v) S.AutoRefillBowls = v end })

local UpgSec = MainTab:CreateSection("Upgrades")
UpgSec:CreateToggle("AutoInterwebs", { Text = "Auto Buy Interwebs", Default = false, Callback = function(v) S.AutoInterwebs = v end })
UpgSec:CreateToggle("AutoFishing", { Text = "Auto Fish", Default = false, Callback = function(v) S.AutoFishing = v end })

local BRSec = MainTab:CreateSection("Backrooms")
BRSec:CreateToggle("BackroomsBypass", { Text = "Backrooms Maze Bypass", Default = false, Callback = function(v) S.BackroomsBypass = v end })
BRSec:CreateToggle("AutoAlmondWater", { Text = "Auto Feed Almond Water", Default = false, Callback = function(v) S.AutoAlmondWater = v end })

local FarmSec2 = MainTab:CreateSection("Farming")
FarmSec2:CreateToggle("AutoPlant", { Text = "Auto Plant & Harvest", Default = false, Callback = function(v) S.AutoPlant = v end })
FarmSec2:CreateToggle("AutoCook", { Text = "Auto Cook", Default = false, Callback = function(v) S.AutoCook = v end })

local CmbSec = MainTab:CreateSection("Combat")
CmbSec:CreateToggle("AntiRaid", { Text = "Anti-Raid / Auto-Kill", Default = false, Callback = function(v) S.AntiRaid = v end })
CmbSec:CreateToggle("AltarAutoFight", { Text = "Altar Boss Auto-Fight", Default = false, Callback = function(v) S.AltarAutoFight = v end })
CmbSec:CreateToggle("RaidFailSafe", { Text = "Raid Fail-Safe (Server Hop)", Default = false, Callback = function(v) S.RaidFailSafe = v end })

local ProgSec = MainTab:CreateSection("Progress")
ProgSec:CreateToggle("AutoRebirth", { Text = "Auto Rebirth", Default = false, Callback = function(v) S.AutoRebirth = v end })
ProgSec:CreateButton("Rebirth Now", function() R.Rebirth:FireServer() end)
ProgSec:CreateToggle("AutoSave", { Text = "Auto Save", Default = false, Callback = function(v) S.AutoSave = v end })
ProgSec:CreateButton("Save Now", function() R.Save:FireServer() end)
ProgSec:CreateToggle("AutoSlots", { Text = "Auto Slots Spin", Default = false, Callback = function(v) S.AutoSlots = v end })

-- ═══ PLAYER TAB ═══
local PlayerTab = Window:CreateTab("Player")
local TpSec = PlayerTab:CreateSection("Teleports")
TpSec:CreateButton("To Floppa", function() local f = getFloppa(); if f and f:FindFirstChild("HumanoidRootPart") then local h = gHRP(); if h then h.CFrame = f.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0) end end end)
TpSec:CreateButton("To House", function() local h = WS:FindFirstChild("House"); if h then local r = h:FindFirstChildWhichIsA("BasePart"); if r then local h2 = gHRP(); if h2 then h2.CFrame = r.CFrame + Vector3.new(0, 5, 0) end end end end)
TpSec:CreateButton("To Village", function() local v = WS:FindFirstChild("Village"); if v then local r = v:FindFirstChildWhichIsA("BasePart"); if r then local h = gHRP(); if h then h.CFrame = r.CFrame + Vector3.new(0, 5, 0) end end end end)
TpSec:CreateButton("To Backrooms Door", function() local d = WS:FindFirstChild("DoorPoint"); if d then local h = gHRP(); if h then h.CFrame = d.CFrame + Vector3.new(0, 3, 0) end end end)

local MvSec = PlayerTab:CreateSection("Movement")
MvSec:CreateToggle("InfJump", { Text = "Infinite Jump", Default = false, Callback = function(v) S.InfJump = v end }):CreateKeybind("InfJumpKey", { Default = "None", Text = "Inf Jump", Mode = "Toggle", SyncToggleState = true, NoUI = false })
MvSec:CreateToggle("Noclip", { Text = "Noclip", Default = false, Callback = function(v) S.Noclip = v end }):CreateKeybind("NoclipKey", { Default = "None", Text = "Noclip", Mode = "Toggle", SyncToggleState = true, NoUI = false })
MvSec:CreateToggle("AntiAfk", { Text = "Anti-AFK", Default = false, Callback = function(v) S.AntiAfk = v end })
MvSec:CreateToggle("SpeedBoost", { Text = "Speed Boost", Risky = true, Default = false, Callback = function(v) S.SpeedBoost = v end }):CreateKeybind("SpeedKey", { Default = "None", Text = "Speed", Mode = "Toggle", SyncToggleState = true, NoUI = false })
MvSec:CreateSlider("SpeedVal", { Text = "Walk Speed", Default = 16, Min = 16, Max = 200, Rounding = 0, Callback = function(v) S.SpeedValue = v end })
MvSec:CreateToggle("JumpBoost", { Text = "Jump Boost", Default = false, Callback = function(v) S.JumpBoost = v end })
MvSec:CreateSlider("JumpVal", { Text = "Jump Power", Default = 50, Min = 50, Max = 200, Rounding = 0, Callback = function(v) S.JumpValue = v end })

-- ═══ VISUALS TAB ═══
local VisTab = Window:CreateTab("Visuals")
local ESPSec = VisTab:CreateSection("ESP")
ESPSec:CreateToggle("ESPEnabled", { Text = "Enable ESP", Default = false, Callback = function(v) S.ESPEnabled = v; if v then updateESP() else clearESP() end end }):CreateKeybind("ESPKey", { Default = "None", Text = "ESP Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })
ESPSec:CreateToggle("ESPEggs", { Text = "Show Floppa", Default = true, Callback = function(v) S.ESPEggs = v end })
ESPSec:CreateToggle("ESPItems", { Text = "Show Items", Default = true, Callback = function(v) S.ESPItems = v end })
ESPSec:CreateToggle("ESPEnemies", { Text = "Show Enemies", Default = true, Callback = function(v) S.ESPEnemies = v end })
ESPSec:CreateLabel("ESP Color"):CreateColorPicker("ESPColorPicker", { Default = S.ESPColor, Title = "ESP Color", Callback = function(v) S.ESPColor = v end })

local FPSSec = VisTab:CreateSection("Optimizer")
FPSSec:CreateButton("Remove Textures", function()
	for _, d in ipairs(WS:GetDescendants()) do
		if d:IsA("Decal") then d.Transparency = 1
		elseif d:IsA("Texture") then d.Transparency = 1 end
	end
	Lighting.GlobalShadows = false
	Lighting.Brightness = 0
	Lighting.FogEnd = 999999
	Lighting.FogStart = 0
	Library.Notify({ Title = "Ivory", Content = "Textures removed", Duration = 2 })
end)

-- ═══ SETTINGS ═══
local SettingsTab = Window:CreateTab("UI Settings")

local CreditGroup = SettingsTab:CreateSection("Credits")
local CreditLabel = CreditGroup:CreateLabel({ Text = "", Size = 26, DoesWrap = true })
local CreditTL = CreditLabel.TextLabel
CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
CreditTL.Font = Enum.Font.GothamBold
CreditTL.TextSize = 26

task.spawn(function()
	local full = "Made by mommy Crow"
	local cursor = "_"
	while true do
		local shown = ""
		for i = 1, #full do
			shown = shown .. full:sub(i, i)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(4, 9) / 100)
		end
		task.wait(2)
		for i = #full, 1, -1 do
			shown = full:sub(1, i - 1)
			CreditLabel:SetText(shown .. cursor)
			CreditTL.TextColor3 = Color3.fromRGB(255, 105, 180)
			task.wait(math.random(2, 5) / 100)
		end
		task.wait(0.8)
	end
end)

local MG = SettingsTab:CreateSection("Menu")
MG:CreateToggle("KeybindMenuOpen", { Default = Library.KeybindFrame.Visible, Text = "Open Keybind Menu", Callback = function(v) Library.KeybindFrame.Visible = v end })
MG:CreateToggle("ShowCustomCursor", { Text = "Custom Cursor", Default = Library.ShowCustomCursor, Callback = function(v) Library.ShowCustomCursor = v end })
MG:CreateButton("Test Notification", function() Library.Notify({ Title = "Test", Content = os.date("%H:%M:%S"), Duration = 4 }) end)
MG:CreateDropdown("NotificationSide", { Values = { "Left", "Right" }, Default = "Right", Text = "Notify Side", Callback = function(v) Library:SetNotifySide(v) end })
MG:CreateDropdown("DPIDropdown", { Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, Default = "100%", Text = "DPI Scale", Callback = function(v) Library:SetDPIScale(tonumber(v:gsub("%%", ""))) end })
MG:CreateSlider("UICornerSlider", { Text = "Corner Radius", Default = Library.CornerRadius, Min = 0, Max = 20, Rounding = 0, Callback = function(v) Window:SetCornerRadius(v) end })
MG:CreateDivider()
MG:CreateLabel("Menu bind"):CreateKeybind("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })
MG:CreateButton("Join Discord", function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Duration = 3 }) end)
MG:CreateButton("Unload", function() clearESP(); Library:Unload() end)

-- ═══ LOOPS ═══
UIS.JumpRequest:Connect(function() if S.InfJump then pcall(function() local h = gHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end) end end)
task.spawn(function() while true do task.wait(0.5) if S.Noclip then pcall(function() local c = LP.Character; if c then for _, p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end end) end end end)
task.spawn(function() while true do task.wait(0.1) if S.SpeedBoost then pcall(function() local h = gHum(); if h and h.WalkSpeed ~= S.SpeedValue then h.WalkSpeed = S.SpeedValue end end) end end end)
task.spawn(function() while true do task.wait(0.1) if S.JumpBoost then pcall(function() local h = gHum(); if h and h.JumpPower ~= S.JumpValue then h.JumpPower = S.JumpValue end end) end end end)
task.spawn(function() while true do task.wait(60) if S.AntiAfk then pcall(function() VIM:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame); task.wait(0.1); VIM:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) end) end end end)
task.spawn(function() while true do task.wait(2) if S.ESPEnabled then pcall(updateESP) end end end)
task.spawn(function() while true do task.wait(S.ClickSpeed) if S.AutoClick and alive() then pcall(function() local f = getFloppa(); if f then local cd = f:FindFirstChild("ClickDetector"); if cd then fireclickdetector(cd) end end end) end end end)
task.spawn(function() while true do task.wait(2) if S.AutoCollectRoommateRent then pcall(function() R.CollectRent:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if S.AutoPayRent then pcall(function() R.RaiseRent:FireServer() end) end end end)
task.spawn(function() while true do task.wait(3) if S.AutoCook then pcall(function() R.Cooking:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if S.AutoBrew then pcall(function() R.Brew:FireServer() end) end end end)
task.spawn(function() while true do task.wait(10) if S.AutoRain then pcall(function() R.Rain:FireServer() end) end end end)
task.spawn(function() while true do task.wait(3) if S.AutoSlots then pcall(function() R.SlotsSpin:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if S.AutoRebirth then pcall(function() R.Rebirth:FireServer() end) end end end)
task.spawn(function() while true do task.wait(30) if S.AutoSave then pcall(function() R.Save:FireServer() end) end end end)
task.spawn(function() while true do task.wait(1) if S.AutoCollectDrops then pcall(function()
	for _, d in ipairs(WS:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:find("Cash") or d.Name:find("Gold") or d.Name:find("Key") or d.Name:find("Meteorite")) then
			local h = gHRP(); if h then d.CFrame = h.CFrame end
		end
	end
end) end end end)

-- Auto Clean Poop: delete Poop models from Litter Box
task.spawn(function() while true do task.wait(0.5)
	if S.AutoCleanPoop then pcall(function()
		local lb = WS:FindFirstChild("Key Parts") and WS["Key Parts"]:FindFirstChild("Litter Box")
		if lb then
			for _, obj in ipairs(lb:GetChildren()) do
				if obj.Name == "Poop" and obj:IsA("Model") then
					obj:Destroy()
				end
			end
		end
	end) end
end end)

-- Auto Pet Floppa: teleport close if happiness < 50%, then fire Pet prompt
task.spawn(function() while true do task.wait(1)
	if S.AutoPet and alive() then pcall(function()
		local f = getFloppa(); if not f then return end
		-- Check happiness from FloppaUI HUD
		local happy = 100
		local gui = LP:FindFirstChild("PlayerGui")
		if gui then
			local floppaUI = gui:FindFirstChild("FloppaUI")
			if floppaUI then
				local frame = floppaUI:FindFirstChild("Frame")
				if frame then
					local floppaFrame = frame:FindFirstChild("Floppa")
					if floppaFrame then
						local happ = floppaFrame:FindFirstChild("Happiness")
						if happ then
							local pct = happ:FindFirstChild("Percentage")
							if pct and pct:IsA("TextLabel") then
								local val = pct.Text:match("(%d+)")
								if val then happy = tonumber(val) end
							end
						end
					end
				end
			end
		end
		-- Teleport close if happiness < 50%, then return after petting
		local savedPos = nil
		if happy < 50 then
			local root = f:FindFirstChild("HumanoidRootPart")
			local hrp = gHRP()
			if root and hrp then
				savedPos = hrp.CFrame
				hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
			end
		end
		-- Pet Floppa: spam E key presses
		for i = 1, 5 do
			VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.3)
			VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
			task.wait(0.3)
		end
		-- Return to original position
		if savedPos then
			task.wait(0.5)
			local hrp = gHRP()
			if hrp then hrp.CFrame = savedPos end
		end
	end) end
end end)

-- Auto Fish: equip rod, Activate to cast, wait, Activate to catch
task.spawn(function() while true do task.wait(0.5)
	if S.AutoFishing and alive() then pcall(function()
		local water = WS:FindFirstChild("Water For Fishies")
		if not water then return end

		-- Find fishing rod
		local rod = nil
		local char = LP.Character
		if char then for _, obj in ipairs(char:GetChildren()) do
			if obj:IsA("Tool") and obj.Name:find("Fish") then rod = obj; break end
		end end
		if not rod then
			local bp = LP:FindFirstChild("Backpack")
			if bp then for _, obj in ipairs(bp:GetChildren()) do
				if obj:IsA("Tool") and obj.Name:find("Fish") then rod = obj; break end
			end end
		end
		if not rod then
			for _, obj in ipairs(WS:GetDescendants()) do
				if obj:IsA("Tool") and obj.Name:find("Fish") then rod = obj; break end
			end
		end
		if not rod then return end

		-- Equip rod
		if char and not char:FindFirstChild("Fishing Rod") then
			rod.Parent = char
			task.wait(0.5)
		end

		-- Face water and cast
		local hrp = gHRP()
		if hrp then
			local dir = (water.Position - hrp.Position).Unit
			hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(dir.X, 0, dir.Z))
			task.wait(0.2)
		end
		rod:Activate()
		local waitTime = math.random(5000, 8000) / 1000
		print("[Ivory] Fishing: waiting " .. waitTime .. "s after cast")
		task.wait(waitTime)

		-- Catch
		rod:Activate()
		task.wait(2)
	end) end
end end)

Library.Notify({ Title = "Ivory", Content = "Raise a Floppa 2 loaded!", Duration = 3 })
