--// Ivory Hub - Unfreeze an Animal
--// PlaceId: 88773823105878

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LP = Players.LocalPlayer

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

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
	writefile(LIB_FILE, httpGet(LIB_URL))
end
local Library = loadstring(readfile(LIB_FILE))()

local KnitServices = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("sleitnick_knit@1.7.0"):WaitForChild("knit"):WaitForChild("Services")

local function getRE(name, svcName)
	local svc = KnitServices:FindFirstChild(svcName)
	if not svc then return nil end
	local reFolder = svc:FindFirstChild("RE")
	if not reFolder then return nil end
	return reFolder:FindFirstChild(name)
end

local function getRF(name, svcName)
	local svc = KnitServices:FindFirstChild(svcName)
	if not svc then return nil end
	local rfFolder = svc:FindFirstChild("RF")
	if not rfFolder then return nil end
	return rfFolder:FindFirstChild(name)
end

local Remotes = {
	QuickTravelBase = getRF("GoBase", "QuickTravelService"),
	QuickTravelShop = getRF("GoShop", "QuickTravelService"),
	PackClaimed = getRE("Claimed", "PackService"),
	DiscoveryRF = getRF("Claim", "DiscoveryService"),
	PackRF = getRF("Claim", "PackService"),
	MeltPassInfo = getRF("GetInfo", "MeltPassService"),
	PowerShopRF = getRF("Buy", "PowerShopService"),
	RebirthRF = getRF("Buy", "RebirthService"),
	Shockwave = getRE("Shock", "ShockwaveService"),
	PetIceBreak = getRE("IceBreak", "PetService"),
	PetEggCrack = getRE("EggCrack", "PetService"),
	PetGetPanel = getRF("GetPanel", "PetService"),
	PetPlace = getRF("Place", "PetService"),
	PetPickUp = getRF("PickUp", "PetService"),
	BaseBuySlot = getRE("BuySlot", "BaseService"),
	ParkourGateEnter = getRF("Enter", "ParkourGateService"),
}

local Bases = Workspace:WaitForChild("Bases")
local AnimalsFolder = Workspace:WaitForChild("Animals")
local MeltPassStations = Workspace:WaitForChild("MeltPassStations")
local GroupRewardStations = Workspace:WaitForChild("GroupRewardStations")
local InfPowerStations = Workspace:WaitForChild("InfPowerStations")

local BaseConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BaseConfig"))

local RARITY_COLORS = {
	Common = Color3.fromRGB(190, 190, 190),
	Uncommon = Color3.fromRGB(96, 214, 96),
	Rare = Color3.fromRGB(70, 150, 255),
	Epic = Color3.fromRGB(185, 95, 255),
	Legendary = Color3.fromRGB(255, 175, 40),
	Mythic = Color3.fromRGB(255, 70, 70),
	Exotic = Color3.fromRGB(255, 110, 210),
	Cosmic = Color3.fromRGB(70, 225, 235),
	Secret = Color3.fromRGB(255, 225, 90),
	Special = Color3.fromRGB(225, 205, 255),
}

local RARITY_ORDER = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Exotic","Cosmic","Secret","Special"}

local function getHRP()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = LP.Character
	return c and c:FindFirstChild("Humanoid")
end

local function teleportTo(part)
	local hrp = getHRP()
	if hrp and part then
		hrp.CFrame = part.CFrame + Vector3.new(0, 5, 0)
	end
end

local function getAnimalRarity(name)
	local info = BaseConfig.Animals and BaseConfig.Animals[name]
	return info and info.rarity or "Common"
end

local function getAnimalIncome(name)
	local info = BaseConfig.Animals and BaseConfig.Animals[name]
	return info and info.income or 0
end

local function getAnimalRoot(model)
	if not model then return nil end
	if model:IsA("BasePart") then return model end
	local sphere = model:FindFirstChild("IceSphere", true)
	if sphere and sphere:IsA("BasePart") then return sphere end
	local primary = model.PrimaryPart
	if primary then return primary end
	return model:FindFirstChildWhichIsA("BasePart")
end

local function getTaggedAnimals()
	return CollectionService:GetTagged("FrozenAnimal")
end

local function getNearestUnownedAnimal(maxDist)
	local hrp = getHRP()
	if not hrp then return nil, math.huge end
	local nearest, nearDist = nil, math.huge
	for _, animal in ipairs(getTaggedAnimals()) do
		if animal:IsA("Model") then
			local root = getAnimalRoot(animal)
			if root then
				local owner = animal:GetAttribute("OwnerUserId")
				if not owner or owner ~= LP.UserId then
					local d = (root.Position - hrp.Position).Magnitude
					if d < nearDist and (not maxDist or d <= maxDist) then
						nearDist = d
						nearest = animal
					end
				end
			end
		end
	end
	return nearest, nearDist
end

local function getMyBaseFolder()
	for _, base in ipairs(Bases:GetChildren()) do
		if base:GetAttribute("OwnerUserId") == LP.UserId then
			return base
		end
	end
	return nil
end

local function isNearMyBase(pos)
	local myBase = getMyBaseFolder()
	if not myBase then return false end
	local parts = myBase:FindFirstChild("Parts")
	if not parts then return false end
	for _, p in ipairs(parts:GetChildren()) do
		if p:IsA("BasePart") and (p.Position - pos).Magnitude < 20 then
			return true
		end
	end
	return false
end

local function isNearOtherBase(pos)
	for _, base in ipairs(Bases:GetChildren()) do
		if base:GetAttribute("OwnerUserId") ~= LP.UserId then
			local parts = base:FindFirstChild("Parts")
			if parts then
				for _, p in ipairs(parts:GetChildren()) do
					if p:IsA("BasePart") and (p.Position - pos).Magnitude < 20 then
						return true
					end
				end
			end
		end
	end
	return false
end

local function findShopPrompt(promptName)
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Folder") or obj:IsA("Model") then
			for _, desc in ipairs(obj:GetDescendants()) do
				if desc:IsA("ProximityPrompt") and desc.Name == promptName then
					return desc.Parent
				end
			end
		end
	end
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") and desc.Name == promptName then
			return desc.Parent
		end
	end
	return nil
end

local function activatePrompt(part)
	if not part then return end
	for _, desc in ipairs(part:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			pcall(function() desc:InputHoldBegin() end)
			task.wait(0.1)
			pcall(function() desc:InputHoldEnd() end)
			return
		end
	end
end

local function activateNearestPrompt(folder, promptName)
	local hrp = getHRP()
	if not hrp then return end
	local nearest, nearDist = nil, math.huge
	for _, obj in ipairs(folder:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Name == promptName then
			local part = obj.Parent
			if part and part:IsA("BasePart") then
				local d = (part.Position - hrp.Position).Magnitude
				if d < nearDist then
					nearDist = d
					nearest = obj
				end
			end
		end
	end
	if nearest then
		pcall(function() nearest:InputHoldBegin() end)
		task.wait(0.1)
		pcall(function() nearest:InputHoldEnd() end)
	end
end

local function equipBestPets()
	local changes = 0

	for _ = 1, 30 do
		local panel = Remotes.PetGetPanel:InvokeServer()
		if not panel then break end

		local equipped = panel.pets or {}
		local inv = panel.inventory or {}
		local capacity = panel.capacity or 10

		local bestCandidate = nil
		for _, item in ipairs(inv) do
			if not item.isEgg and (not bestCandidate or (item.income or 0) > (bestCandidate.income or 0)) then
				bestCandidate = item
			end
		end

		if #equipped < capacity then
			if not bestCandidate then break end
			pcall(function() Remotes.PetPlace:InvokeServer(bestCandidate.index) end)
			task.wait(0.15)
			changes += 1
		else
			local worstEquipped = equipped[1]
			for _, pet in ipairs(equipped) do
				if (pet.income or 0) < (worstEquipped.income or 0) then
					worstEquipped = pet
				end
			end

			if not bestCandidate then break end
			if (bestCandidate.income or 0) <= (worstEquipped.income or 0) then break end

			pcall(function() Remotes.PetPickUp:InvokeServer(worstEquipped.id) end)
			task.wait(0.15)

			panel = Remotes.PetGetPanel:InvokeServer()
			if not panel then break end
			inv = panel.inventory or {}
			bestCandidate = nil
			for _, item in ipairs(inv) do
				if not item.isEgg and (not bestCandidate or (item.income or 0) > (bestCandidate.income or 0)) then
					bestCandidate = item
				end
			end

			if bestCandidate then
				pcall(function() Remotes.PetPlace:InvokeServer(bestCandidate.index) end)
				task.wait(0.15)
				changes += 1
			end
		end
	end

	return changes
end

local STATE = {
	AutoPush = false,
	AutoPushRange = 100,
	AutoPushTarget = "Nearest",
	AutoUnfreeze = false,
	AutoSell = false,
	AutoGroupReward = false,
	AutoMeltPass = false,
	AutoInfPower = false,
	AutoClaimPacks = false,
	AutoClaimDiscovery = false,
	AutoShockwave = false,
	AutoCampfire = false,
	AutoBuyPower = false,
	PowerBuyAmount = 100,
	AutoRebirth = false,
	AutoQuickBase = false,
	AutoQuickShop = false,
	AutoPetEgg = false,
	AutoPetIceBreak = false,
	AutoEquipBest = false,
	Noclip = false,
	InfiniteJump = false,
	ESP = false,
	ESPDistance = false,
	ESPAnimals = false,
	WalkSpeed = 16,
	JumpPower = 50,
	Gravity = 196.2,
	TeleportBase = "Base1",
}

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 720,
	Height = 600,
})

local Tabs = {
	Main = Window:CreateTab({Name = "Main"}),
	Teleport = Window:CreateTab({Name = "Teleport"}),
	Shop = Window:CreateTab({Name = "Shop"}),
	Pets = Window:CreateTab({Name = "Pets"}),
	Player = Window:CreateTab({Name = "Player"}),
	Visuals = Window:CreateTab({Name = "Visuals"}),
	Settings = Window:CreateTab({Name = "UI Settings"}),
}

--// MAIN TAB
local PushSec = Tabs.Main:CreateSection("Push")
local UnfreezeSec = Tabs.Main:CreateSection("Unfreeze")
local SellSec = Tabs.Main:CreateSection("Sell")
local ClaimSec = Tabs.Main:CreateSection("Claims")
local MiscAutoSec = Tabs.Main:CreateSection("Misc Auto")

PushSec:CreateToggle({
	Name = "Auto Push Animals",
	CurrentValue = false,
	Callback = function(v) STATE.AutoPush = v end,
})

PushSec:CreateToggle({
	Name = "Push Range (200 studs)",
	CurrentValue = false,
	Callback = function(v) STATE.AutoPushRange = v and 200 or 100 end,
})

PushSec:CreateDropdown({
	Name = "Push Target",
	Values = { "Nearest", "Rarest", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Exotic", "Cosmic", "Secret", "Special" },
	CurrentOption = "Nearest",
	Callback = function(v) STATE.AutoPushTarget = v end,
})

UnfreezeSec:CreateToggle({
	Name = "Auto Unfreeze (ProximityPrompts)",
	CurrentValue = false,
	Callback = function(v) STATE.AutoUnfreeze = v end,
})

SellSec:CreateToggle({
	Name = "Auto Sell",
	CurrentValue = false,
	Callback = function(v) STATE.AutoSell = v end,
})

SellSec:CreateButton({
	Name = "Sell Now",
	Callback = function()
		local zone = findShopPrompt("SellShopPrompt")
		if zone then
			teleportTo(zone)
			task.wait(0.5)
			activatePrompt(zone)
		end
	end,
})

ClaimSec:CreateToggle({
	Name = "Auto Claim Group Rewards",
	CurrentValue = false,
	Callback = function(v) STATE.AutoGroupReward = v end,
})

ClaimSec:CreateToggle({
	Name = "Auto Melt Pass",
	CurrentValue = false,
	Callback = function(v) STATE.AutoMeltPass = v end,
})

ClaimSec:CreateToggle({
	Name = "Auto Inf Power",
	CurrentValue = false,
	Callback = function(v) STATE.AutoInfPower = v end,
})

ClaimSec:CreateToggle({
	Name = "Auto Claim Packs",
	CurrentValue = false,
	Callback = function(v) STATE.AutoClaimPacks = v end,
})

ClaimSec:CreateToggle({
	Name = "Auto Claim Discovery",
	CurrentValue = false,
	Callback = function(v) STATE.AutoClaimDiscovery = v end,
})

MiscAutoSec:CreateToggle({
	Name = "Auto Shockwave",
	CurrentValue = false,
	Callback = function(v) STATE.AutoShockwave = v end,
})

MiscAutoSec:CreateToggle({
	Name = "Auto Campfire",
	CurrentValue = false,
	Callback = function(v) STATE.AutoCampfire = v end,
})

--// TELEPORT TAB
local TeleportSec = Tabs.Teleport:CreateSection("Teleports")

local baseNames = {}
for i = 1, 6 do table.insert(baseNames, "Base" .. i) end

TeleportSec:CreateDropdown({
	Name = "Select Base",
	Values = baseNames,
	CurrentOption = "Base1",
	Callback = function(v) STATE.TeleportBase = v end,
})

TeleportSec:CreateButton({
	Name = "Teleport to Selected Base",
	Callback = function()
		local base = Bases:FindFirstChild(STATE.TeleportBase)
		if base then
			local parts = base:FindFirstChild("Parts")
			if parts then
				for _, p in ipairs(parts:GetChildren()) do
					if p:IsA("BasePart") then
						teleportTo(p)
						return
					end
				end
			end
		end
	end,
})

TeleportSec:CreateButton({
	Name = "Quick Travel to Base",
	Callback = function()
		pcall(function() Remotes.QuickTravelBase:InvokeServer() end)
	end,
})

TeleportSec:CreateButton({
	Name = "Quick Travel to Shop",
	Callback = function()
		pcall(function() Remotes.QuickTravelShop:InvokeServer() end)
	end,
})

--// SHOP TAB
local ShopSec = Tabs.Shop:CreateSection("Shop Automation")
local PowerOfferAmounts = {1, 10, 100, 1000, 10000, 100000, 1000000}

ShopSec:CreateDropdown({
	Name = "Power Buy Amount",
	Values = { "1", "10", "100", "1000", "10000", "100000", "1000000" },
	CurrentOption = "100",
	Callback = function(v) STATE.PowerBuyAmount = tonumber(v) or 100 end,
})

ShopSec:CreateToggle({
	Name = "Auto Buy Power",
	CurrentValue = false,
	Callback = function(v) STATE.AutoBuyPower = v end,
})

ShopSec:CreateButton({
	Name = "Buy Power Now",
	Callback = function()
		pcall(function()
			local amount = STATE.PowerBuyAmount or 100
			local idx = 1
			for i, a in ipairs(PowerOfferAmounts) do
				if a == amount then idx = i; break end
			end
			Remotes.PowerShopRF:InvokeServer(idx)
		end)
	end,
})

--// PETS TAB
local PetsSec = Tabs.Pets:CreateSection("Pets")

PetsSec:CreateButton({
	Name = "Equip Best Pets",
	Callback = function()
		pcall(function()
			local n = equipBestPets()
			Library.Notify({Title = "Equip Best", Content = "Equipped " .. n .. " best pets", Type = "success", Duration = 3})
		end)
	end,
})

PetsSec:CreateToggle({
	Name = "Auto Equip Best",
	CurrentValue = false,
	Callback = function(v) STATE.AutoEquipBest = v end,
})

PetsSec:CreateButton({
	Name = "Unequip All Pets",
	Callback = function()
		pcall(function()
			local panel = Remotes.PetGetPanel:InvokeServer()
			if not panel then return end
			local equipped = panel.pets or {}
			for _, pet in ipairs(equipped) do
				if pet.id then
					pcall(function() Remotes.PetPickUp:InvokeServer(pet.id) end)
					task.wait(0.15)
				end
			end
			Library.Notify({Title = "Unequip All", Content = "Removed all pets from base", Type = "success", Duration = 3})
		end)
	end,
})

PetsSec:CreateToggle({
	Name = "Auto Crack Eggs",
	CurrentValue = false,
	Callback = function(v) STATE.AutoPetEgg = v end,
})

PetsSec:CreateButton({
	Name = "Crack Egg Now",
	Callback = function()
		pcall(function() Remotes.PetEggCrack:FireServer() end)
	end,
})

PetsSec:CreateToggle({
	Name = "Auto Ice Break",
	CurrentValue = false,
	Callback = function(v) STATE.AutoPetIceBreak = v end,
})

PetsSec:CreateButton({
	Name = "Break Ice Now",
	Callback = function()
		pcall(function() Remotes.PetIceBreak:FireServer() end)
	end,
})

--// PLAYER TAB
local PlayerSec = Tabs.Player:CreateSection("Movement")

PlayerSec:CreateDropdown({
	Name = "Walk Speed",
	Values = { "16", "50", "100", "200", "500" },
	CurrentOption = "16",
	Callback = function(v)
		STATE.WalkSpeed = tonumber(v) or 16
		local h = getHum()
		if h then h.WalkSpeed = STATE.WalkSpeed end
	end,
})

PlayerSec:CreateDropdown({
	Name = "Jump Power",
	Values = { "50", "100", "200", "500" },
	CurrentOption = "50",
	Callback = function(v)
		STATE.JumpPower = tonumber(v) or 50
		local h = getHum()
		if h then h.JumpPower = STATE.JumpPower end
	end,
})

PlayerSec:CreateDropdown({
	Name = "Gravity",
	Values = { "196.2", "100", "50", "25" },
	CurrentOption = "196.2",
	Callback = function(v)
		STATE.Gravity = tonumber(v) or 196.2
		Workspace.Gravity = STATE.Gravity
	end,
})

PlayerSec:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Callback = function(v) STATE.Noclip = v end,
})

PlayerSec:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Callback = function(v) STATE.InfiniteJump = v end,
})

--// VISUALS TAB
local VisualSec = Tabs.Visuals:CreateSection("Visuals")

VisualSec:CreateButton({
	Name = "Full Bright",
	Callback = function()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
		Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	end,
})

VisualSec:CreateButton({
	Name = "Remove Fog",
	Callback = function()
		Lighting.FogEnd = 100000
		Lighting.FogStart = 0
		Lighting.Atmosphere.Density = 0
	end,
})

VisualSec:CreateToggle({
	Name = "Animal ESP",
	CurrentValue = false,
	Callback = function(v) STATE.ESPAnimals = v end,
})

VisualSec:CreateToggle({
	Name = "Player ESP",
	CurrentValue = false,
	Callback = function(v) STATE.ESP = v end,
})

VisualSec:CreateToggle({
	Name = "ESP Distance",
	CurrentValue = false,
	Callback = function(v) STATE.ESPDistance = v end,
})

--// SETTINGS TAB
local SettingsSec = Tabs.Settings:CreateSection("Server")

SettingsSec:CreateButton({
	Name = "Server Hop",
	Callback = function()
		pcall(function()
			local servers = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100&excludeFullServers=true")
			local HttpService = game:GetService("HttpService")
			local data = HttpService:JSONDecode(servers)
			if data and data.data then
				for _, server in ipairs(data.data) do
					if server.id ~= game.JobId then
						game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, server.id, LP)
						break
					end
				end
			end
		end)
	end,
})

SettingsSec:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
	end,
})

SettingsSec:CreateButton({
	Name = "Join Discord For Dupe",
	Callback = function()
		pcall(function() setclipboard("https://discord.gg/bac") end)
		Library.Notify({Title = "Discord", Content = "Copied discord.gg/bac to clipboard", Type = "success", Duration = 3})
	end,
})

--// AUTO LOOPS

-- Noclip
RunService.Stepped:Connect(function()
	if STATE.Noclip then
		local char = LP.Character
		if char then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					part.CanCollide = false
				end
			end
		end
	end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
	if STATE.InfiniteJump then
		local char = LP.Character
		if char then
			local h = char:FindFirstChildOfClass("Humanoid")
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end
end)

-- Auto Push
task.spawn(function()
	while true do
		task.wait(0.5)
		if STATE.AutoPush then
			pcall(function()
				local hrp = getHRP()
				local hum = getHum()
				if not hrp or not hum or hum.Health <= 0 then return end

				local target = nil
				local targetDist = math.huge

				for _, animal in ipairs(getTaggedAnimals()) do
					if animal:IsA("Model") then
						local root = getAnimalRoot(animal)
						if root then
							local owner = animal:GetAttribute("OwnerUserId")
							if not owner or owner ~= LP.UserId then
								local animalPos = root.Position

								if isNearOtherBase(animalPos) or isNearMyBase(animalPos) then
									continue
								end

								local d = (animalPos - hrp.Position).Magnitude
								if d <= STATE.AutoPushRange then
									if STATE.AutoPushTarget == "Nearest" then
										if d < targetDist then
											targetDist = d
											target = animal
										end
									elseif STATE.AutoPushTarget == "Rarest" then
										local rarity = getAnimalRarity(animal.Name)
										local curRarity = target and getAnimalRarity(target.Name) or nil
										local ri = 0
										local cri = 0
										for i, r in ipairs(RARITY_ORDER) do
											if r == rarity then ri = i end
											if r == curRarity then cri = i end
										end
										if ri > cri then
											target = animal
										end
									else
										local rarity = getAnimalRarity(animal.Name)
										if rarity == STATE.AutoPushTarget then
											target = animal
											break
										end
									end
								end
							end
						end
					end
				end

				if target then
					local root = getAnimalRoot(target)
					if root then
						local myBase = getMyBaseFolder()
						local basePos = nil
						if myBase then
							local parts = myBase:FindFirstChild("Parts")
							if parts then
								for _, p in ipairs(parts:GetChildren()) do
									if p:IsA("BasePart") then
										basePos = p.Position
										break
									end
								end
							end
						end
						if not basePos then return end

						for _ = 1, 10 do
							if not target or not target.Parent then break end
							root = getAnimalRoot(target)
							if not root then break end

							local animalPos = root.Position
							local toBase = (basePos - animalPos)
							toBase = Vector3.new(toBase.X, 0, toBase.Z)

							if toBase.Magnitude < 1 then break end

							local behindPos = animalPos - toBase.Unit * 5
							behindPos = Vector3.new(behindPos.X, animalPos.Y + 2, behindPos.Z)
							hrp.CFrame = CFrame.new(behindPos, animalPos)

							local dir = toBase.Unit
							pcall(function()
								local IntentRemote = getRE("Intent", "PushService")
								if IntentRemote then IntentRemote:FireServer(target, dir) end
							end)
							task.wait(0.1)
						end
					end
				end
			end)
		end
	end
end)

-- Auto Unfreeze
task.spawn(function()
	while true do
		task.wait(0.5)
		if STATE.AutoUnfreeze then
			pcall(function()
				activateNearestPrompt(MeltPassStations, "MeltPassPrompt")
			end)
		end
	end
end)

-- Auto Sell
task.spawn(function()
	while true do
		task.wait(3)
		if STATE.AutoSell then
			pcall(function()
				local zone = findShopPrompt("SellShopPrompt")
				if zone then
					teleportTo(zone)
					task.wait(0.3)
					activatePrompt(zone)
				end
			end)
		end
	end
end)

-- Auto Group Reward
task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoGroupReward then
			pcall(function()
				activateNearestPrompt(GroupRewardStations, "GroupRewardPrompt")
			end)
		end
	end
end)

-- Auto Melt Pass
task.spawn(function()
	while true do
		task.wait(2)
		if STATE.AutoMeltPass then
			pcall(function()
				activateNearestPrompt(MeltPassStations, "MeltPassPrompt")
			end)
		end
	end
end)

-- Auto Inf Power
task.spawn(function()
	while true do
		task.wait(2)
		if STATE.AutoInfPower then
			pcall(function()
				activateNearestPrompt(InfPowerStations, "InfPowerPrompt")
			end)
		end
	end
end)

-- Auto Claim Packs
task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoClaimPacks then
			pcall(function()
				if Remotes.PackClaimed then Remotes.PackClaimed:FireServer() end
				if Remotes.PackRF then Remotes.PackRF:InvokeServer() end
			end)
		end
	end
end)

-- Auto Claim Discovery
task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoClaimDiscovery then
			pcall(function()
				if Remotes.DiscoveryRF then Remotes.DiscoveryRF:InvokeServer() end
			end)
		end
	end
end)

-- Auto Shockwave
task.spawn(function()
	while true do
		task.wait(3)
		if STATE.AutoShockwave then
			pcall(function()
				if Remotes.Shockwave then Remotes.Shockwave:FireServer() end
			end)
		end
	end
end)

-- Auto Buy Power
task.spawn(function()
	while true do
		task.wait(3)
		if STATE.AutoBuyPower then
			pcall(function()
				local amount = STATE.PowerBuyAmount or 100
				local idx = 1
				for i, a in ipairs(PowerOfferAmounts) do
					if a == amount then idx = i; break end
				end
				Remotes.PowerShopRF:InvokeServer(idx)
			end)
		end
	end
end)

-- Auto Rebirth
task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoRebirth then
			pcall(function()
				if Remotes.RebirthRF then Remotes.RebirthRF:InvokeServer() end
			end)
		end
	end
end)

-- Auto Quick Travel Base
task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoQuickBase then
			pcall(function() Remotes.QuickTravelBase:InvokeServer() end)
		end
	end
end)

-- Auto Quick Travel Shop
task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoQuickShop then
			pcall(function() Remotes.QuickTravelShop:InvokeServer() end)
		end
	end
end)

-- Auto Crack Eggs
task.spawn(function()
	while true do
		task.wait(2)
		if STATE.AutoPetEgg then
			pcall(function() Remotes.PetEggCrack:FireServer() end)
		end
	end
end)

-- Auto Ice Break
task.spawn(function()
	while true do
		task.wait(2)
		if STATE.AutoPetIceBreak then
			pcall(function() Remotes.PetIceBreak:FireServer() end)
		end
	end
end)

-- Auto Equip Best
task.spawn(function()
	while true do
		task.wait(10)
		if STATE.AutoEquipBest then
			pcall(function() equipBestPets() end)
		end
	end
end)

-- ESP
local espFolder = Instance.new("Folder")
espFolder.Name = "IvoryESP"
espFolder.Parent = game:GetService("CoreGui")

local function clearESP()
	for _, child in ipairs(espFolder:GetChildren()) do
		child:Destroy()
	end
end

local function makeESP(part, text, color)
	if not part then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "IvoryESP"
	bb.Size = UDim2.new(0, 200, 0, 50)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = espFolder

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Parent = bb
end

local function updateESP()
	clearESP()
	local hrp = getHRP()

	if STATE.ESPAnimals then
		for _, animal in ipairs(getTaggedAnimals()) do
			if animal:IsA("Model") then
				local root = getAnimalRoot(animal)
				if root then
					local rarity = getAnimalRarity(animal.Name)
					local color = RARITY_COLORS[rarity] or Color3.new(1, 1, 1)
					local label = animal.Name .. " [" .. rarity .. "]"
					if hrp then
						local d = math.floor((root.Position - hrp.Position).Magnitude)
						label = label .. " (" .. d .. "m)"
					end
					makeESP(root, label, color)
				end
			end
		end
	end

	if STATE.ESP then
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LP and player.Character then
				local root = player.Character:FindFirstChild("HumanoidRootPart")
				if root then
					local label = player.Name
					if STATE.ESPDistance and hrp then
						local d = math.floor((root.Position - hrp.Position).Magnitude)
						label = label .. " (" .. d .. "m)"
					end
					makeESP(root, label, Color3.fromRGB(255, 100, 100))
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		if STATE.ESP or STATE.ESPAnimals then
			pcall(updateESP)
		end
		task.wait(2)
	end
end)

LP.CharacterAdded:Connect(function(char)
	task.wait(2)
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		h.WalkSpeed = STATE.WalkSpeed
		h.JumpPower = STATE.JumpPower
	end
end)

Window:SetFooter("v1.4 | Unfreeze an Animal | " .. LP.UserId)
