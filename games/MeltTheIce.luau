local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = {
	SellAll = Events:WaitForChild("SellAll"),
	BuyWeapon = Events:WaitForChild("BuyWeapon"),
	BuyBackpack = Events:WaitForChild("BuyBackpack"),
	BuyUpgrade = Events:WaitForChild("BuyUpgrade"),
	TeleportToStage = Events:WaitForChild("TeleportToStage"),
	SpinRoll = Events:WaitForChild("SpinRoll"),
	SpinClaim = Events:WaitForChild("SpinClaim"),
	EquipWeapon = Events:WaitForChild("EquipWeapon"),
	EquipBackpack = Events:WaitForChild("EquipBackpack"),
	BuyPotion = Events:WaitForChild("BuyPotion"),
	ClaimPlaytimeReward = Events:WaitForChild("ClaimPlaytimeReward"),
	HoldItem = Events:WaitForChild("HoldItem"),
	MountainMelt = Events:WaitForChild("MountainMelt"),
	MountainPickup = Events:WaitForChild("MountainPickup"),
	ColdUpdate = Events:WaitForChild("ColdUpdate"),
	IndexClaim = Events:WaitForChild("IndexClaim"),
}

local Map = Workspace:WaitForChild("Map")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local _nameToRarity = {}
do
	for _, v in pairs(GameConfig.ItemById) do
		if type(v) == "table" and v.name and v.rarity then
			_nameToRarity[v.name] = v.rarity
		end
	end
end

local function httpGet(url)
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

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

local STATE = {
	AutoMelt = false,
	AutoSell = false,
	AutoCollect = false,
	AutoBuyWeapon = false,
	AutoBuyBackpack = false,
	AutoBuyUpgrade = false,
	AutoBuyPotion = false,
	AutoSpin = false,
	AutoPlaytime = false,
	AutoIndexClaim = false,
	TeleportStage = 1,
	Noclip = false,
	InfiniteJump = false,
	ESP = false,
	ESPDistance = false,
	ESPColor = Color3.fromRGB(255, 100, 100),
	WalkSpeed = 22,
	JumpPower = 50,
	CollectRarities = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true, Transcendent = true, Secret = true },
}

local function getHRP()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = LP.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getTool()
	local c = LP.Character
	if c then
		for _, v in ipairs(c:GetChildren()) do
			if v:IsA("Tool") then return v end
		end
	end
	for _, v in ipairs(LP.Backpack:GetChildren()) do
		if v:IsA("Tool") then return v end
	end
	return nil
end

local function getZoneNames()
	local names = {}
	for _, v in ipairs(Map:GetChildren()) do
		if v.Name:match("^Zone %d+$") then
			table.insert(names, v.Name)
		end
	end
	table.sort(names, function(a, b)
		return tonumber(a:match("%d+")) < tonumber(b:match("%d+"))
	end)
	return names
end

local function teleportToZone(zoneNum)
	local zone = Map:FindFirstChild("Zone " .. tostring(zoneNum))
	if zone then
		local hrp = getHRP()
		if hrp then
			local ground = zone:FindFirstChild("ZoneGround") or zone:FindFirstChildWhichIsA("BasePart")
			if ground then
				hrp.CFrame = ground.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end
end

local ESPObjects = {}

local function clearESP()
	for _, obj in ipairs(ESPObjects) do
		if obj and obj.Parent then obj:Destroy() end
	end
	ESPObjects = {}
end

local function createESP(part, text, color)
	if not part or not part.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "IvoryESP"
	bb.Size = UDim2.new(0, 120, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = part
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color or STATE.ESPColor
	tl.TextSize = 14
	tl.Font = Enum.Font.GothamBold
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.Parent = bb
	table.insert(ESPObjects, bb)
end

local function updateESP()
	clearESP()
	if not STATE.ESP then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local label = plr.Name
				if STATE.ESPDistance then
					local myHRP = getHRP()
					if myHRP then
						label = label .. " [" .. math.floor((myHRP.Position - hrp.Position).Magnitude) .. "m]"
					end
				end
				createESP(hrp, label, STATE.ESPColor)
			end
		end
	end
end

local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = LP.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

local ijConn = nil
local function setInfiniteJump(on)
	if ijConn then ijConn:Disconnect(); ijConn = nil end
	if on then
		ijConn = UserInputService.JumpRequest:Connect(function()
			local c = LP.Character
			if c then
				local h = c:FindFirstChildWhichIsA("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
end

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "swords",
	Footer = {
		"v1.4 |",
		{ Text = "Game", Copyable = true },
		"|",
		{ Text = tostring(LP.UserId), Copyable = true },
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

local MainTab = Window:AddTab({ Name = "Main", Icon = "swords" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "swords" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "swords" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "swords" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "swords" })

local AutoSub = MainTab:AddSubTab("Automation", "rbxassetid://113133903091338")
local MeltGroup = AutoSub:AddLeftGroupbox("Melt", "flame")
local SellGroup = AutoSub:AddRightGroupbox("Sell", "coins")
local CollectGroup = AutoSub:AddRightGroupbox("Collect", "package")
local SpinGroup = AutoSub:AddLeftGroupbox("Spin", "refresh-cw")
local PlaytimeGroup = AutoSub:AddRightGroupbox("Playtime", "clock")

MeltGroup:AddToggle("AutoMelt", {
	Text = "Auto Melt Ice",
	Default = false,
	Callback = function(v) STATE.AutoMelt = v end,
}):AddKeyPicker("AutoMeltKey", {
	Default = "None",
	Text = "Auto Melt Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

SellGroup:AddToggle("AutoSell", {
	Text = "Auto Sell",
	Default = false,
	Callback = function(v) STATE.AutoSell = v end,
}):AddKeyPicker("AutoSellKey", {
	Default = "None",
	Text = "Auto Sell Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

SellGroup:AddSlider("SellInterval", {
	Text = "Sell Interval",
	Default = 5,
	Min = 1,
	Max = 30,
	Rounding = 0,
	Callback = function(v) STATE.AutoSellInterval = v end,
})

SellGroup:AddButton("Sell All Now", function()
	pcall(function() Remotes.SellAll:InvokeServer() end)
end)

CollectGroup:AddToggle("AutoCollect", {
	Text = "Auto Collect Drops",
	Default = false,
	Callback = function(v) STATE.AutoCollect = v end,
})

local rarityOrder = { "Common", "Rare", "Epic", "Legendary", "Transcendent", "Secret" }
for _, rarity in ipairs(rarityOrder) do
	CollectGroup:AddToggle("Rarity_" .. rarity, {
		Text = rarity,
		Default = STATE.CollectRarities[rarity] or false,
		Callback = function(v) STATE.CollectRarities[rarity] = v end,
	})
end

CollectGroup:AddButton("Collect All Drops Now", function()
	pcall(function()
		local hrp = getHRP()
		if not hrp then return end
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("ProximityPrompt") and obj:GetAttribute("MountainIdx") and obj.Enabled then
				local parent = obj.Parent
				if parent and parent:IsA("BasePart") then
					hrp.CFrame = CFrame.new(parent.Position + Vector3.new(0, 3, 0))
					task.wait(0.2)
					local idx = obj:GetAttribute("MountainIdx")
					if idx then
						pcall(function() Remotes.MountainPickup:FireServer(idx) end)
					end
					pcall(function()
						obj:InputHoldBegin()
						task.wait(obj.HoldDuration + 0.3)
						obj:InputHoldEnd()
					end)
					task.wait(0.3)
				end
			end
		end
	end)
end)

SpinGroup:AddToggle("AutoSpin", {
	Text = "Auto Spin",
	Default = false,
	Callback = function(v) STATE.AutoSpin = v end,
})

SpinGroup:AddButton("Claim Free Spin", function()
	pcall(function() Remotes.SpinClaim:FireServer() end)
end)

SpinGroup:AddButton("Roll Spin", function()
	pcall(function() Remotes.SpinRoll:InvokeServer() end)
end)

PlaytimeGroup:AddToggle("AutoPlaytime", {
	Text = "Auto Claim Playtime",
	Default = false,
	Callback = function(v) STATE.AutoPlaytime = v end,
})

PlaytimeGroup:AddButton("Claim Playtime Now", function()
	pcall(function() Remotes.ClaimPlaytimeReward:InvokeServer() end)
end)

PlaytimeGroup:AddToggle("AutoIndexClaim", {
	Text = "Auto Claim Index Stages",
	Default = false,
	Callback = function(v) STATE.AutoIndexClaim = v end,
})

PlaytimeGroup:AddButton("Claim All Index Stages", function()
	for i = 1, 40 do
		pcall(function() Remotes.IndexClaim:InvokeServer(i) end)
	end
end)

local TeleSub = MainTab:AddSubTab("Teleport", "rbxassetid://113133903091338")
local TeleGroup = TeleSub:AddLeftGroupbox("Stage Teleport", "navigation")

TeleGroup:AddDropdown("TeleportDropdown", {
	Values = getZoneNames(),
	Default = "Zone 1",
	Text = "Select Stage",
	Callback = function(v)
		local num = tonumber(v:match("%d+"))
		if num then STATE.TeleportStage = num end
	end,
})

TeleGroup:AddButton("Teleport to Selected", function()
	teleportToZone(STATE.TeleportStage)
end)

TeleGroup:AddButton("TP to Current Stage", function()
	pcall(function() Remotes.TeleportToStage:FireServer() end)
end)

local UpgradeSub = ShopTab:AddSubTab("Upgrades", "rbxassetid://113133903091338")
local UpgradeGroup = UpgradeSub:AddLeftGroupbox("Upgrades", "trending-up")

UpgradeGroup:AddToggle("AutoBuyUpgrade", {
	Text = "Auto Buy Upgrades",
	Default = false,
	Callback = function(v) STATE.AutoBuyUpgrade = v end,
})

UpgradeGroup:AddButton("Buy Melt Power", function()
	pcall(function() Remotes.BuyUpgrade:InvokeServer("melt", 1) end)
end)

UpgradeGroup:AddButton("Buy Speed", function()
	pcall(function() Remotes.BuyUpgrade:InvokeServer("speed", 1) end)
end)

UpgradeGroup:AddButton("Buy Warmth", function()
	pcall(function() Remotes.BuyUpgrade:InvokeServer("warmth", 1) end)
end)

UpgradeGroup:AddButton("Buy Max Melt", function()
	pcall(function()
		local data = Remotes.BuyUpgrade:InvokeServer("milt", 999)
	end)
end)

local WeaponSub = ShopTab:AddSubTab("Weapons", "rbxassetid://113133903091338")
local WeaponGroup = WeaponSub:AddLeftGroupbox("Weapons", "shield")

WeaponGroup:AddToggle("AutoBuyWeapon", {
	Text = "Auto Buy Best Weapon",
	Default = false,
	Callback = function(v) STATE.AutoBuyWeapon = v end,
})

WeaponGroup:AddButton("Buy Weapon Now", function()
	pcall(function() Remotes.BuyWeapon:InvokeServer() end)
end)

local BackpackGroup = WeaponSub:AddRightGroupbox("Backpacks", "package")

BackpackGroup:AddToggle("AutoBuyBackpack", {
	Text = "Auto Buy Backpack",
	Default = false,
	Callback = function(v) STATE.AutoBuyBackpack = v end,
})

BackpackGroup:AddButton("Buy Backpack Now", function()
	pcall(function() Remotes.BuyBackpack:InvokeServer() end)
end)

local PotionSub = ShopTab:AddSubTab("Potions", "rbxassetid://113133903091338")
local PotionGroup = PotionSub:AddLeftGroupbox("Potions", "droplet")

PotionGroup:AddToggle("AutoBuyPotion", {
	Text = "Auto Buy Melt Potion",
	Default = false,
	Callback = function(v) STATE.AutoBuyPotion = v end,
})

PotionGroup:AddButton("Buy Melt Potion", function()
	pcall(function() Remotes.BuyPotion:InvokeServer("melt_1") end)
end)

PotionGroup:AddButton("Buy Big Melt Potion", function()
	pcall(function() Remotes.BuyPotion:InvokeServer("melt_2") end)
end)

PotionGroup:AddButton("Buy Luck Potion", function()
	pcall(function() Remotes.BuyPotion:InvokeServer("luck_1") end)
end)

PotionGroup:AddButton("Buy Cash Potion", function()
	pcall(function() Remotes.BuyPotion:InvokeServer("coins_1") end)
end)

local MoveSub = PlayerTab:AddSubTab("Movement", "rbxassetid://113133903091338")
local SpeedGroup = MoveSub:AddLeftGroupbox("Speed", "zap")
local JumpGroup = MoveSub:AddRightGroupbox("Jump", "arrow-up")

SpeedGroup:AddSlider("WalkSpeed", {
	Text = "Walk Speed",
	Default = 22,
	Min = 16,
	Max = 200,
	Rounding = 0,
	Callback = function(v)
		STATE.WalkSpeed = v
		local h = getHum()
		if h then h.WalkSpeed = v end
	end,
})

SpeedGroup:AddToggle("Noclip", {
	Text = "Noclip",
	Default = false,
	Callback = function(v)
		STATE.Noclip = v
		setNoclip(v)
	end,
}):AddKeyPicker("NoclipKey", {
	Default = "None",
	Text = "Noclip Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

JumpGroup:AddSlider("JumpPower", {
	Text = "Jump Power",
	Default = 50,
	Min = 50,
	Max = 200,
	Rounding = 0,
	Callback = function(v)
		STATE.JumpPower = v
		local h = getHum()
		if h then h.JumpPower = v end
	end,
})

JumpGroup:AddToggle("InfJump", {
	Text = "Infinite Jump",
	Default = false,
	Callback = function(v)
		STATE.InfiniteJump = v
		setInfiniteJump(v)
	end,
}):AddKeyPicker("InfJumpKey", {
	Default = "None",
	Text = "Infinite Jump Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

local ESPSub = VisualsTab:AddSubTab("ESP", "rbxassetid://113133903091338")
local ESPGroup = ESPSub:AddLeftGroupbox("Player ESP", "users")

ESPGroup:AddToggle("ESPEnabled", {
	Text = "Enable ESP",
	Default = false,
	Callback = function(v)
		STATE.ESP = v
		if v then updateESP() else clearESP() end
	end,
}):AddKeyPicker("ESPKey", {
	Default = "None",
	Text = "ESP Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

ESPGroup:AddToggle("ESPDistance", {
	Text = "Show Distance",
	Default = true,
	Callback = function(v)
		STATE.ESPDistance = v
		if STATE.ESP then updateESP() end
	end,
})

ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = Color3.fromRGB(255, 100, 100),
	Title = "ESP Color",
	Callback = function(v)
		STATE.ESPColor = v
		if STATE.ESP then updateESP() end
	end,
})

local WorldGroup = ESPSub:AddRightGroupbox("World", "globe")

WorldGroup:AddButton("Full Bright", function()
	game:GetService("Lighting").Brightness = 2
	game:GetService("Lighting").ClockTime = 14
end)

WorldGroup:AddButton("Remove Fog", function()
	game:GetService("Lighting").FogEnd = 999999
	game:GetService("Lighting").FogStart = 0
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("melttheice")
local DiscordGroup = SettingsTab:AddLeftGroupbox("Discord", "users")
DiscordGroup:AddButton("Join Discord", function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 }) end)

local CreditGroup = SettingsTab:AddLeftGroupbox("Credits", "heart")
local CreditLabel = CreditGroup:AddLabel({ Text = "", Size = 26, DoesWrap = true })
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

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(v) Library.KeybindFrame.Visible = v end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddButton("Test Notification", function()
	Library:Notify({ Title = "Ivory", Description = "Works!", Time = 4 })
end)
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(v) Window:SetCornerRadius(v) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})
MenuGroup:AddButton("Unload", function()
	clearESP()
	setNoclip(false)
	setInfiniteJump(false)
	Workspace.Gravity = 196.2
	Library:Unload()
end)

local _meltActivated = false
local _coldLevel = 0
local _goingToFire = false
local _collectingDrop = false

local function isOnZoneGround()
	local hrp = getHRP()
	if not hrp then return false end
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "ZoneGround" then
			local pos = obj.Position
			local size = obj.Size
			local lp = hrp.Position
			if math.abs(lp.X - pos.X) < size.X / 2 + 10
				and math.abs(lp.Z - pos.Z) < size.Z / 2 + 10
				and math.abs(lp.Y - pos.Y) < 30 then
				return true
			end
		end
	end
	return false
end

local function getMedals()
	local ok, v = pcall(function()
		return LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Medals") and LP.leaderstats.Medals.Value
	end)
	return ok and v or 0
end

local function getCash()
	local ok, v = pcall(function()
		return LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Cash") and LP.leaderstats.Cash.Value
	end)
	return ok and v or 0
end

local _ownedWeapons = {}
local _ownedBackpacks = {}
local _lastOwnedCheck = 0

local function findNextWeapon()
	local cash = getCash()
	for _, w in ipairs(GameConfig.WEAPONS) do
		if w.cost > 0 and w.cost <= cash and not _ownedWeapons[w.id] then
			local ok, res = pcall(function() return Remotes.BuyWeapon:InvokeServer(w.id) end)
			if ok and res == true then
				_ownedWeapons[w.id] = true
				return w.id
			elseif ok then
				_ownedWeapons[w.id] = true
			end
		end
	end
	return nil
end

local function findNextBackpack()
	local cash = getCash()
	for _, b in ipairs(GameConfig.BACKPACKS) do
		if b.cost > 0 and b.cost <= cash and not _ownedBackpacks[b.id] then
			local ok, res = pcall(function() return Remotes.BuyBackpack:InvokeServer(b.id) end)
			if ok and res == true then
				_ownedBackpacks[b.id] = true
				return b.id
			elseif ok then
				_ownedBackpacks[b.id] = true
			end
		end
	end
	return nil
end

local _upgradeFailCount = 0

local function findNearestWarmthFire()
	local hrp = getHRP()
	if not hrp then return nil end
	local best, bestDist = nil, math.huge
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == "WarmthFire" then
			local wz = obj:FindFirstChild("WarmZone")
			if wz and wz:IsA("BasePart") then
				local d = (wz.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					best = wz
				end
			end
		end
	end
	return best
end

local function findNearestDrop()
	local hrp = getHRP()
	if not hrp then return nil, math.huge end
	local best, bestDist = nil, math.huge
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Name == "DropPrompt" and obj.Enabled then
			local parent = obj.Parent
			if parent and parent:IsA("BasePart") then
				local rarity = _nameToRarity[parent.Name] or "Common"
				if STATE.CollectRarities[rarity] then
					local d = (parent.Position - hrp.Position).Magnitude
					if d < bestDist then
						bestDist = d
						best = parent
					end
				end
			end
		end
	end
	return best, bestDist
end

local function getCurrentStage()
	local hrp = getHRP()
	if not hrp then return 1 end
	local bestLevel, bestDist = 1, math.huge
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("MountainWall") then
			local level = obj:GetAttribute("Level")
			if level then
				local d = (obj.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestLevel = level
				end
			end
		end
	end
	return bestLevel
end

local function aimCameraAtIceWall(level)
	local hrp = getHRP()
	if not hrp then return end
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("MountainWall") and obj:GetAttribute("Level") == level then
			local cam = workspace.CurrentCamera
			local eyePos = hrp.Position + Vector3.new(0, 2, 0)
			cam.CFrame = CFrame.new(eyePos, Vector3.new(obj.Position.X, eyePos.Y, obj.Position.Z))
			return true
		end
	end
	return false
end

local function equipBestTool()
	local LP = game.Players.LocalPlayer
	local char = LP.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not humanoid then return end
	if char:FindFirstChildWhichIsA("Tool") then return end
	local backpack = LP:FindFirstChild("Backpack")
	if backpack then
		local tool = backpack:FindFirstChildWhichIsA("Tool")
		if tool then
			humanoid:EquipTool(tool)
		end
	end
end

local function activateGameAutoMelt()
	LP:SetAttribute("Set_AutoMeltBtn", true)
	LP:SetAttribute("AutoMelt", true)

	equipBestTool()

	local level = getCurrentStage()
	aimCameraAtIceWall(level)

	task.wait(0.5)
	local HUD = LP:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	if not HUD then return end
	local btn = HUD:FindFirstChild("AutoMeltBTN", true)
	if btn and btn.Visible then
		local onBtn = btn:FindFirstChild("AutoMeltOn", true)
		local offClip = btn:FindFirstChild("AutoMeltOffClip", true)
		if onBtn and onBtn.Visible then
			local pos = onBtn.AbsolutePosition + onBtn.AbsoluteSize / 2
			mousemoveabs(pos.X, pos.Y)
			task.wait(0.1)
			mouse1click()
			_meltActivated = true
		elseif offClip and offClip.Visible then
			_meltActivated = true
		end
	end
end

local function teleportToCurrentStage()
	local hrp = getHRP()
	if not hrp then return end
	local level = getCurrentStage()
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("MountainWall") and obj:GetAttribute("Level") == level then
			local icePos = obj.Position
			local iceSize = obj.Size
			local spawnZ = icePos.Z - iceSize.Z / 2 - 15
			hrp.CFrame = CFrame.new(icePos.X, 5, spawnZ)
			local humanoid = LP.Character and LP.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
			return true
		end
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if STATE.AutoMelt then
			pcall(function()
				if _goingToFire then return end
				local hrp = getHRP()
				if not hrp then return end

				if _coldLevel >= 35 then
					_goingToFire = true
					local fire = findNearestWarmthFire()
					if fire then
						local firePos = fire.Position
						hrp.CFrame = CFrame.new(firePos.X + 6, firePos.Y + 3, firePos.Z + 6)
						local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
						if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
						while _coldLevel > 5 do
							task.wait(1)
						end
					end
					_goingToFire = false
					return
				end

				if not isOnZoneGround() then
					teleportToCurrentStage()
					task.wait(0.5)
					local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
					if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
				end
				equipBestTool()
				Remotes.MountainMelt:FireServer()
			end)
		end
	end
end)

local function isBagFull()
	local ok, result = pcall(function()
		local HUD = LP:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
		if not HUD then return false end

		local toast = HUD:FindFirstChild("notificationToast", true)
		if toast then
			local ml = toast:FindFirstChild("MedalsLabel", true)
			if ml and ml:IsA("TextLabel") and ml.Text:find("FULL") then
				return true
			end
		end

		local amt = HUD:FindFirstChild("Boosts", true)
		if amt then
			amt = amt:FindFirstChild("backpack", true)
			if amt then
				amt = amt:FindFirstChild("amount", true)
				if amt and amt:IsA("TextLabel") then
					local cur, max = amt.Text:match("(%d+)/(%d+)")
					if cur and max then
						return tonumber(cur) >= tonumber(max)
					end
				end
			end
		end

		return false
	end)
	return ok and result
end

task.spawn(function()
	while true do
		task.wait(1)
		if STATE.AutoSell then
			pcall(function()
				if isBagFull() then
					Remotes.SellAll:InvokeServer()
					task.wait(2)
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		if STATE.AutoCollect then
			pcall(function()
				local hrp = getHRP()
				if not hrp then return end
				if _collectingDrop then return end

				local drop, dist = findNearestDrop()
				if drop and dist < 100 then
					_collectingDrop = true

					local savedPos = hrp.CFrame
					hrp.CFrame = CFrame.new(drop.Position + Vector3.new(0, 3, 0))
					task.wait(0.2)

					local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt")
					if prompt and prompt.Enabled then
						local idx = prompt:GetAttribute("MountainIdx")
						if idx then
							pcall(function() Remotes.MountainPickup:FireServer(idx) end)
						end
						pcall(function()
							prompt:InputHoldBegin()
							task.wait(prompt.HoldDuration + 0.3)
							prompt:InputHoldEnd()
						end)
					end

					task.wait(0.3)
					_collectingDrop = false
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoBuyWeapon then
			pcall(function() findNextWeapon() end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoBuyBackpack then
			pcall(function() findNextBackpack() end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(STATE.AutoBuyUpgrade and _upgradeFailCount > 0 and math.min(30, 5 * _upgradeFailCount) or 5)
		if STATE.AutoBuyUpgrade then
			pcall(function()
				local medals = getMedals()
				local bought = false
				for _, key in ipairs({"speed", "melt", "warmth"}) do
					local ok, res = Remotes.BuyUpgrade:InvokeServer(key, 1)
					if ok and res then
						local success = (type(res) == "table") and (res.success ~= false) or (res == true)
						if success then
							bought = true
							_upgradeFailCount = 0
						end
					end
				end
				if not bought then
					_upgradeFailCount = _upgradeFailCount + 1
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoBuyPotion then
			pcall(function()
				local cash = getCash()
				for i = #GameConfig.POTIONS, 1, -1 do
					local p = GameConfig.POTIONS[i]
					if cash >= p.cost then
						Remotes.BuyPotion:InvokeServer(p.id)
						break
					end
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoSpin then
			pcall(function() Remotes.SpinRoll:InvokeServer() end)
			task.wait(1)
			pcall(function() Remotes.SpinClaim:FireServer() end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(10)
		if STATE.AutoPlaytime then
			pcall(function() Remotes.ClaimPlaytimeReward:InvokeServer() end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(30)
		if STATE.AutoIndexClaim then
			for i = 1, 40 do
				pcall(function() Remotes.IndexClaim:InvokeServer(i) end)
			end
		end
	end
end)

Events:WaitForChild("ColdUpdate").OnClientEvent:Connect(function(value)
	_coldLevel = tonumber(value) or 0
end)

LP.CharacterAdded:Connect(function(char)
	_meltActivated = false
	_goingToFire = false
	_collectingDrop = false

	task.wait(2)
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		h.WalkSpeed = STATE.WalkSpeed
	end
	if h then
		h.JumpPower = STATE.JumpPower
	end

	if STATE.AutoMelt then
		task.wait(1)
		if not isOnZoneGround() then
			teleportToCurrentStage()
			task.wait(1)
		end
		equipBestTool()
	end
end)

pcall(function()
	Library:Notify({
		Title = "Ivory",
		Description = "Melt The Ice loaded!",
		Type = "Success",
		Time = 5,
	})
end)