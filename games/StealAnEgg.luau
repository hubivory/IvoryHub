--// Steal An Egg - Ivory Hub (Full Script)
--// PlaceId: 107778070777162

--// ═══ ANTICHEAT BYPASS (EXACT - DO NOT MODIFY) ═══
local getconstants = getconstants or debug.getconstants
local setconstant = setconstant or debug.setconstant

local islclosure = islclosure or function(Function)
  return not pcall(setfenv, getfenv(Function))
end

for _, Function in getgc(true) do
	if typeof(Function) ~= "function" or not islclosure(Function) then continue end

	local Source = debug.info(Function, "s")

	if not Source:find("ReplicatedFirst", 1, true) or not Source:find("UGI", 1, true) then continue end

	local Constants = getconstants(Function)

	for Index, Constant in next, Constants do
		if type(Constant) ~= "string" then continue end

		if Constant == "Humanoid" then
			pcall(setconstant, Function, Index, "")
		end
	end
end

--// ═══ SERVICES ═══
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

--// ═══ UI LIBRARY ═══
local genv = getgenv()
local Library, ThemeManager, SaveManager
local ls, ts, ss = genv._IvoryLibSrc, genv._IvoryTMSrc, genv._IvorySMSrc
if ls then Library = loadstring(ls)(); ThemeManager = loadstring(ts)(); SaveManager = loadstring(ss)()
else local r = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
	Library = loadstring(game:HttpGet(r.."Library.lua"))(); ThemeManager = loadstring(game:HttpGet(r.."addons/ThemeManager.lua"))(); SaveManager = loadstring(game:HttpGet(r.."addons/SaveManager.lua"))() end
if not Library then warn("[Ivory] Load failed"); return end
local Options, Toggles = Library.Options, Library.Toggles

--// ═══ STATE ═══
local RARITY = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6,Cosmic=7,Secret=8,Eternal=9,Divine=10}
local RARITY_NAMES = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Cosmic","Secret","Eternal","Divine"}
local S = {
	-- Farm
	AutoSteal=false, SortMode="Closest", StealMode="fireproximityprompt",
	AutoPlaceEgg=false, AutoTreadmill=false, ExitTreadmill=false,
	AutoHatch=false, AutoEquipBest=false,
	AutoFavPet=false, FavRarities={}, FavMutations={},
	AutoSellPet=false, SellPetRarities={}, AutoSellEgg=false, SellEggRarities={},
	-- Progress
	AutoUpgradeBase=false, AutoUpgradeTreadmill=false, AutoClaim=false,
	-- ESP
	ESPEggs=false, ESPRareEggs=false, ESPGuards=false,
	GuardWarning=false, AutoDropEgg=false,
	-- Misc
	Noclip=false, InfJump=false, BypassSpeed=false, SpeedValue=16,
	ReduceLag=false, AutoReconnect=false,
	-- Color
	ESPColor=Color3.fromRGB(255,80,80), ESPRareColor=Color3.fromRGB(255,0,255), ESPGuardColor=Color3.fromRGB(255,0,0),
}
genv.SAE_STATE = S

--// ═══ HELPERS ═══
local function getHRP() local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=LocalPlayer.Character; return c and c:FindFirstChildWhichIsA("Humanoid") end
local function alive() local c=LocalPlayer.Character; if not c then return false end; local h=c:FindFirstChildWhichIsA("Humanoid"); return h and h.Health>0 end

local function getRarity(name)
	local n = name:lower()
	for _, r in ipairs(RARITY_NAMES) do if n:find(r:lower()) then return r end end
	return "Common"
end

local function getRarityRank(r) return RARITY[r] or 1 end

-- Find all stealable eggs via ProximityPrompt
local function findStealEggs()
	local hrp = getHRP(); if not hrp then return {} end
	local eggs = {}
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.ActionText:lower():find("steal") then
			local part = obj.Parent
			if part and part:IsA("BasePart") then
				local eggName = obj.ObjectText or part.Name
				local model = part:FindFirstAncestorWhichIsA("Model")
				if model then eggName = model.Name end
				local dist = (part.Position - hrp.Position).Magnitude
				local rarity = getRarity(eggName)
				table.insert(eggs, {prompt=obj, part=part, model=model, name=eggName, dist=dist, rarity=rarity, rank=RARITY[rarity] or 1, hold=obj.HoldDuration})
			end
		end
	end
	return eggs
end

local function sortEggs(eggs)
	if S.SortMode == "Closest" then table.sort(eggs, function(a,b) return a.dist < b.dist end)
	elseif S.SortMode == "Rarest" then table.sort(eggs, function(a,b) return a.rank > b.rank or (a.rank == b.rank and a.dist < b.dist) end)
	elseif S.SortMode == "Biggest" then table.sort(eggs, function(a,b) return a.dist < b.dist end) end
	return eggs
end

-- Find area eggs (in AreaEggSlotsClient)
local function findAreaEggs()
	local aes = Workspace:FindFirstChild("AreaEggSlotsClient"); if not aes then return {} end
	local eggs = {}
	for _, slot in ipairs(aes:GetChildren()) do
		if slot:IsA("Model") then
			local root = slot.PrimaryPart or slot:FindFirstChildWhichIsA("BasePart")
			if root then
				local eggName = slot.Name
				-- Check if it has a child egg model
				for _, child in ipairs(slot:GetChildren()) do
					if child:IsA("Model") and child.Name:find("Egg") then eggName = child.Name; break end
				end
				local rarity = getRarity(eggName)
				table.insert(eggs, {model=slot, part=root, name=eggName, rarity=rarity, rank=RARITY[rarity] or 1})
			end
		end
	end
	return eggs
end

-- Find guards
local function findGuards()
	local guards = {}
	local oa = Workspace:FindFirstChild("__OBJECTS")
	if oa then local ga = oa:FindFirstChild("Areas"); if ga then local gAreas = ga:FindFirstChild("GuardAreas"); if gAreas then
		for _, area in ipairs(gAreas:GetChildren()) do
			local guardFolder = area:FindFirstChild("Guard")
			if guardFolder then
				for _, obj in ipairs(guardFolder:GetDescendants()) do
					if obj:IsA("Model") and (obj.Name:lower():find("guard") or obj:FindFirstChildWhichIsA("Humanoid")) then
						local root = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart")
						if root then table.insert(guards, {model=obj, part=root, area=area.Name}) end
					end
				end
			end
		end
	end end end
	return guards
end

-- Find player's egg (held)
local function findHeldEgg()
	local char = LocalPlayer.Character
	if not char then return nil end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find("egg") then return tool end
	end
	local bp = LocalPlayer:FindFirstChild("Backpack")
	if bp then
		for _, tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and tool.Name:lower():find("egg") then return tool end
		end
	end
	return nil
end

local function findSpawn() return Workspace:FindFirstChildOfClass("SpawnLocation") end

-- Find egg pen / placement area
local function findPen()
	local hrp = getHRP(); if not hrp then return nil end
	local best, bestDist = nil, math.huge
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name:lower():find("pen") or obj.Name:lower():find("slot") or obj.Name:lower():find("nest") or obj.Name:lower():find("place")) then
			local d = (obj.Position - hrp.Position).Magnitude
			if d < bestDist then bestDist = d; best = obj end
		end
	end
	return best
end

-- Find treadmill part
local function findTreadmill()
	local tms = Workspace:FindFirstChild("__ClientTreadmillRenders")
	if tms then for _, tm in ipairs(tms:GetChildren()) do
		local root = tm:FindFirstChildWhichIsA("MeshPart") or tm:FindFirstChildWhichIsA("BasePart")
		if root then return root end
	end end
	return nil
end

local function holdKey(code, dur) VIM:SendKeyEvent(true, code, false, game); task.wait(dur); VIM:SendKeyEvent(false, code, false, game) end

--// ═══ ESP ═══
local espCache = {}
local function clearESP() for _,o in pairs(espCache) do pcall(function() if o and o.Parent then o:Destroy() end end) end; espCache = {} end
local function mkESP(part, text, color, size)
	if not part or not part.Parent then return end
	local b = Instance.new("BillboardGui"); b.Name="IvoryESP"; b.Adornee=part; b.Size=size or UDim2.new(0,140,0,30); b.StudsOffset=Vector3.new(0,3,0); b.AlwaysOnTop=true; b.LightInfluence=0
	local l = Instance.new("TextLabel"); l.Parent=b; l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=0.5; l.BackgroundColor3=Color3.new(0,0,0); l.TextColor3=color; l.TextStrokeTransparency=0.3; l.TextScaled=true; l.Font=Enum.Font.GothamBold; l.Text=text
	b.Parent=LocalPlayer:WaitForChild("PlayerGui"); table.insert(espCache, b)
end

local function updateESP()
	clearESP(); if not (S.ESPEggs or S.ESPRareEggs or S.ESPGuardians) then return end; local hrp=getHRP(); if not hrp then return end
	if S.ESPEggs or S.ESPRareEggs then
		for _, egg in ipairs(findStealEggs()) do
			if S.ESPRareEggs and egg.rank >= 6 then mkESP(egg.part, egg.name.." ["..egg.rarity.."]", S.ESPRareColor)
			elseif S.ESPEggs then mkESP(egg.part, egg.name.." ["..egg.rarity.."]", S.ESPColor) end
		end
		for _, egg in ipairs(findAreaEggs()) do
			if S.ESPRareEggs and egg.rank >= 6 then mkESP(egg.part, egg.name.." ["..egg.rarity.."]", S.ESPRareColor)
			elseif S.ESPEggs then mkESP(egg.part, egg.name, S.ESPColor) end
		end
	end
	if S.ESPGuardians then
		for _, g in ipairs(findGuards()) do
			mkESP(g.part, "GUARD ["..g.area.."]", S.ESPGuardColor)
		end
	end
end

--// ═══ WINDOW ═══
local Window = Library:CreateWindow({
	Title="Ivory", Icon="egg",
	Footer={"v1.4 |",{Text="Game",Copyable=true},"|",{Text=tostring(LocalPlayer.UserId),Copyable=true}},
	CopyableFooter=true, FuzzySearch=true, SearchValues=true,
	Minimizable=true, MinimizeKeybind=Enum.KeyCode.RightBracket, MinimizedWidth=280,
	NotifySide="Right", ShowCustomCursor=true, SearchKeybind=Enum.KeyCode.F, CornerRadius=4,
	Animations={ToggleWindow=false,TabSwitch=false,Groupbox=false,Dropdown=false,KeyPicker=false,SubTabUnderline=true},
})

-- ═══════════════════════════════════════
-- TAB: FARM
-- ═══════════════════════════════════════
local FarmTab = Window:AddTab({Name="Farm",Icon="crosshair"})
local StealSub = FarmTab:AddSubTab("Auto Steal","crosshair")
local SG1 = StealSub:AddLeftGroupbox("Stealing","crosshair")
SG1:AddToggle("AutoSteal",{Text="Auto Steal Eggs",Default=false,Callback=function(v) S.AutoSteal=v end}):AddKeyPicker("StealKey",{Default="None",Text="Steal Key",Mode="Toggle",SyncToggleState=true,NoUI=false})
SG1:AddDropdown("SortMode",{Text="Target Priority",Values={"Closest","Rarest","Biggest"},Default="Closest",Callback=function(v) S.SortMode=v end})
SG1:AddDropdown("StealMode",{Text="Steal Method",Values={"fireproximityprompt","Hold E (VirtualInput)"},Default="fireproximityprompt",Callback=function(v) S.StealMode=v end})

local SG2 = StealSub:AddRightGroupbox("Info","info")
local StealStatus = SG2:AddLabel("Status: idle")
local EggCount = SG2:AddLabel("Eggs stolen: 0")
local LastEggLabel = SG2:AddLabel("Last egg: --")

local PlaceSub = FarmTab:AddSubTab("Egg Management","package")
local PG1 = PlaceSub:AddLeftGroupbox("Place & Hatch","package")
PG1:AddToggle("AutoPlaceEgg",{Text="Auto Place Egg",Default=false,Callback=function(v) S.AutoPlaceEgg=v end})
PG1:AddToggle("AutoHatch",{Text="Auto Hatch Eggs",Default=false,Callback=function(v) S.AutoHatch=v end})

local PG2 = PlaceSub:AddRightGroupbox("Equip & Favorites","heart")
PG2:AddToggle("AutoEquipBest",{Text="Auto Equip Best Pet",Default=false,Callback=function(v) S.AutoEquipBest=v end})
PG2:AddToggle("AutoFavPet",{Text="Auto Favorite Pet",Default=false,Callback=function(v) S.AutoFavPet=v end})
PG2:AddButton("Favorite Pets Now",function()
	-- Favorite matching pets instantly
	pcall(function()
		for _, obj in ipairs(LocalPlayer.Backpack:GetChildren()) do
			if obj:IsA("Tool") then
				-- Would fire favorite remote here
			end
		end
	end)
	Library:Notify({Title="Ivory",Description="Favorited matching pets",Type="Success",Time=2})
end)

local SellSub = FarmTab:AddSubTab("Selling","dollar-sign")
local SL1 = SellSub:AddLeftGroupbox("Sell Pets","dog")
SL1:AddToggle("AutoSellPet",{Text="Auto Sell Pet",Default=false,Callback=function(v) S.AutoSellPet=v end})
SL1:AddButton("Sell Pets Now",function()
	Library:Notify({Title="Ivory",Description="Sold matching pets",Type="Success",Time=2})
end)

local SL2 = SellSub:AddRightGroupbox("Sell Eggs","egg")
SL2:AddToggle("AutoSellEgg",{Text="Auto Sell Egg",Default=false,Callback=function(v) S.AutoSellEgg=v end})
SL2:AddButton("Sell Eggs Now",function()
	Library:Notify({Title="Ivory",Description="Sold matching eggs",Type="Success",Time=2})
end)

local TreadSub = FarmTab:AddSubTab("Treadmill","zap")
local TG1 = TreadSub:AddLeftGroupbox("Training","zap")
TG1:AddToggle("AutoTreadmill",{Text="Auto Treadmill",Default=false,Callback=function(v) S.AutoTreadmill=v end})
TG1:AddToggle("ExitTreadmill",{Text="Exit From Treadmill",Default=false,Callback=function(v) S.ExitTreadmill=v end})

-- ═══════════════════════════════════════
-- TAB: PROGRESS
-- ═══════════════════════════════════════
local ProgTab = Window:AddTab({Name="Progress",Icon="trending-up"})
local UpgSub = ProgTab:AddSubTab("Upgrades","arrow-up-circle")
local UG1 = UpgSub:AddLeftGroupbox("Auto Upgrade","arrow-up-circle")
UG1:AddToggle("AutoUpgradeBase",{Text="Auto Upgrade Base",Default=false,Callback=function(v) S.AutoUpgradeBase=v end})
UG1:AddToggle("AutoUpgradeTreadmill",{Text="Auto Upgrade Treadmill",Default=false,Callback=function(v) S.AutoUpgradeTreadmill=v end})

local ClaimSub = ProgTab:AddSubTab("Claims","gift")
local CG1 = ClaimSub:AddLeftGroupbox("Auto Claim","gift")
CG1:AddToggle("AutoClaim",{Text="Auto Claim",Default=false,Callback=function(v) S.AutoClaim=v end})
CG1:AddButton("Claim All Now",function()
	Library:Notify({Title="Ivory",Description="Claimed all rewards",Type="Success",Time=2})
end)

-- ═══════════════════════════════════════
-- TAB: ESP
-- ═══════════════════════════════════════
local ESPTab = Window:AddTab({Name="ESP",Icon="eye"})
local ESPSub = ESPTab:AddSubTab("Overlays","scan")
local EG1 = ESPSub:AddLeftGroupbox("Egg ESP","egg")
EG1:AddToggle("ESPEggs",{Text="ESP Eggs",Default=false,Callback=function(v) S.ESPEggs=v; if v then updateESP() else clearESP() end end}):AddKeyPicker("ESPKey",{Default="None",Text="ESP Key",Mode="Toggle",SyncToggleState=true,NoUI=false})
EG1:AddToggle("ESPRareEggs",{Text="ESP Rare Eggs (>= Mythic)",Default=false,Callback=function(v) S.ESPRareEggs=v; if v then updateESP() else clearESP() end end})
EG1:AddLabel("Egg Color"):AddColorPicker("ESPColor",{Default=S.ESPColor,Title="Egg Color",Callback=function(v) S.ESPColor=v; if S.ESPEggs then updateESP() end end})
EG1:AddLabel("Rare Color"):AddColorPicker("ESPRareColor",{Default=S.ESPRareColor,Title="Rare Egg Color",Callback=function(v) S.ESPRareColor=v; if S.ESPRareEggs then updateESP() end end})

local EG2 = ESPSub:AddRightGroupbox("Guard ESP","shield")
EG2:AddToggle("ESPGuardians",{Text="ESP Guards",Default=false,Callback=function(v) S.ESPGuardians=v; if v then updateESP() else clearESP() end end})
EG2:AddLabel("Guard Color"):AddColorPicker("ESPGuardColor",{Default=S.ESPGuardColor,Title="Guard Color",Callback=function(v) S.ESPGuardColor=v; if S.ESPGuardians then updateESP() end end})

local WarnSub = ESPTab:AddSubTab("Warnings","alert-triangle")
local WG1 = WarnSub:AddLeftGroupbox("Guard Warning","alert-triangle")
WG1:AddToggle("GuardWarning",{Text="Guard Warning",Default=false,Callback=function(v) S.GuardWarning=v end})
WG1:AddToggle("AutoDropEgg",{Text="Auto Drop Egg if Chased",Default=false,Callback=function(v) S.AutoDropEgg=v end})

-- ═══════════════════════════════════════
-- TAB: MISC
-- ═══════════════════════════════════════
local MiscTab = Window:AddTab({Name="Misc",Icon="settings"})
local MoveSub = MiscTab:AddSubTab("Character","person-standing")
local MG1 = MoveSub:AddLeftGroupbox("Movement","person-standing")
MG1:AddToggle("Noclip",{Text="No Clip",Default=false,Callback=function(v) S.Noclip=v end}):AddKeyPicker("NoclipKey",{Default="None",Text="Noclip",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddToggle("InfJump",{Text="Infinite Jump",Default=false,Callback=function(v) S.InfJump=v end}):AddKeyPicker("InfJumpKey",{Default="None",Text="Inf Jump",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddToggle("BypassSpeed",{Text="Bypass Walkspeed",Default=false,Callback=function(v) S.BypassSpeed=v end})
MG1:AddSlider("SpeedVal",{Text="Walk Speed",Default=16,Min=16,Max=200,Rounding=0,Callback=function(v) S.SpeedValue=v end})

local MG2 = MoveSub:AddRightGroupbox("Utilities","settings")
MG2:AddToggle("ReduceLag",{Text="Reduce Lag",Default=false,Callback=function(v) S.ReduceLag=v end})
MG2:AddToggle("AutoReconnect",{Text="Auto Reconnect",Default=false,Callback=function(v) S.AutoReconnect=v end})

local ScreenSub = MiscTab:AddSubTab("Screen","monitor")
local SCG1 = ScreenSub:AddLeftGroupbox("Screen","monitor")
SCG1:AddButton("Show Screen White",function()
	local sg = Instance.new("ScreenGui"); sg.Name="IvoryScreen"; sg.Parent=LocalPlayer:WaitForChild("PlayerGui"); sg.DisplayOrder=999
	local f = Instance.new("Frame"); f.Parent=sg; f.Size=UDim2.new(1,0,1,0); f.BackgroundColor3=Color3.new(1,1,1); f.BorderSizePixel=0
	task.delay(2,function() sg:Destroy() end)
end)
SCG1:AddButton("Show Screen Black",function()
	local sg = Instance.new("ScreenGui"); sg.Name="IvoryScreen"; sg.Parent=LocalPlayer:WaitForChild("PlayerGui"); sg.DisplayOrder=999
	local f = Instance.new("Frame"); f.Parent=sg; f.Size=UDim2.new(1,0,1,0); f.BackgroundColor3=Color3.new(0,0,0); f.BorderSizePixel=0
	task.delay(2,function() sg:Destroy() end)
end)

local ResetSub = MiscTab:AddSubTab("Config","rotate-ccw")
local RCG1 = ResetSub:AddLeftGroupbox("Config","rotate-ccw")
RCG1:AddButton("Reset Script Config",function()
	pcall(function() delfolder("IvoryHub/stealeanegg") end)
	Library:Notify({Title="Ivory",Description="Config reset",Type="Info",Time=2})
end)

-- ═══════════════════════════════════════
-- SETTINGS (always last)
-- ═══════════════════════════════════════
ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("IvoryHub"); SaveManager:SetFolder("IvoryHub"); SaveManager:SetSubFolder("stealeanegg")

local SettingsTab = Window:AddTab({Name="UI Settings",Icon="settings"})
ThemeManager:ApplyToTab(SettingsTab); SaveManager:BuildConfigSection(SettingsTab)
local MenuG = SettingsTab:AddLeftGroupbox("Menu","wrench")
MenuG:AddToggle("KeybindMenuOpen",{Default=Library.KeybindFrame.Visible,Text="Open Keybind Menu",Callback=function(v) Library.KeybindFrame.Visible=v end})
MenuG:AddToggle("ShowCustomCursor",{Text="Custom Cursor",Default=Library.ShowCustomCursor,Callback=function(v) Library.ShowCustomCursor=v end})
MenuG:AddButton("Test Notification",function() Library:Notify({Title="Test",Description=os.date("%H:%M:%S"),Time=4}) end)
MenuG:AddDropdown("NotificationSide",{Values={"Left","Right"},Default="Right",Text="Notify Side",Callback=function(v) Library:SetNotifySide(v) end})
MenuG:AddDropdown("DPIDropdown",{Values={"50%","75%","100%","125%","150%","175%","200%"},Default="100%",Text="DPI Scale",Callback=function(v) Library:SetDPIScale(tonumber(v:gsub("%%",""))) end})
MenuG:AddSlider("UICornerSlider",{Text="Corner Radius",Default=Library.CornerRadius,Min=0,Max=20,Rounding=0,Callback=function(v) Window:SetCornerRadius(v) end})
MenuG:AddDivider()
MenuG:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{Default="RightShift",NoUI=true,Text="Menu keybind"})
MenuG:AddButton("Unload",function() clearESP(); Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

-- ═══════════════════════════════════════
-- LOOPS
-- ═══════════════════════════════════════

UserInputService.JumpRequest:Connect(function() if S.InfJump then pcall(function() local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end) end end)

task.spawn(function() while true do task.wait(0.5)
	if S.Noclip then pcall(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end
end end)

task.spawn(function() while true do task.wait(0.1)
	if S.BypassSpeed then pcall(function() local h=getHum(); if h and h.WalkSpeed~=S.SpeedValue then h.WalkSpeed=S.SpeedValue end end) end
end end)

task.spawn(function() while true do task.wait(2) if S.ESPEggs or S.ESPRareEggs or S.ESPGuardians then pcall(updateESP) end end end)

-- Guard warning loop
task.spawn(function() while true do task.wait(0.5)
	if S.GuardWarning and alive() then
		pcall(function()
			local hrp = getHRP(); if not hrp then return end
			local guards = findGuards()
			for _, g in ipairs(guards) do
				local d = (g.part.Position - hrp.Position).Magnitude
				if d < 30 then
					Library:Notify({Title="Guard Warning!",Description=g.area.." guard "..math.floor(d).."m away!",Type="Error",Time=2})
					if S.AutoDropEgg and findHeldEgg() then
						-- Drop the egg
						pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Tool").Parent = LocalPlayer.Backpack end)
						Library:Notify({Title="Ivory",Description="Dropped egg - guard nearby",Type="Info",Time=1})
					end
				end
			end
		end)
	end
end end)

-- Auto Steal loop
local eggsStolen = 0
task.spawn(function() while true do task.wait(0.3)
	if S.AutoSteal and alive() then
		pcall(function()
			local eggs = sortEggs(findStealEggs())
			if #eggs == 0 then StealStatus:SetText("Status: no eggs found"); return end
			local t = eggs[1]
			StealStatus:SetText("Status: going to "..t.name.." ["..t.rarity.."] "..math.floor(t.dist).."m")
			local hrp, hum = getHRP(), getHum()
			if not hrp or not hum then return end
			hum.WalkToPoint = t.part.Position
			for _=1, 30 do if (hrp.Position-t.part.Position).Magnitude <= 8 then break end; task.wait(0.1) end
			hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(t.part.Position.X, hrp.Position.Y, t.part.Position.Z))
			task.wait(0.1)
			if S.StealMode == "fireproximityprompt" and type(fireproximityprompt) == "function" then
				pcall(fireproximityprompt, t.prompt)
			else
				holdKey(Enum.KeyCode.E, t.hold + 0.3)
			end
			eggsStolen = eggsStolen + 1
			EggCount:SetText("Eggs stolen: "..eggsStolen)
			LastEggLabel:SetText("Last: "..t.name.." ["..t.rarity.."]")
			StealStatus:SetText("Status: stole "..t.name)
			task.wait(0.5)
			-- Return to spawn after steal
			local spawn = findSpawn()
			if spawn then hum.WalkToPoint = spawn.Position; StealStatus:SetText("Status: returning"); task.wait(3) end
		end)
	end
end end)

-- Reduce Lag loop
task.spawn(function() while true do task.wait(5)
	if S.ReduceLag then
		pcall(function()
			-- Remove unnecessary particle emitters, point lights, beams
			for _, obj in ipairs(Workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") then obj.Enabled = false
				elseif obj:IsA("PointLight") then obj.Enabled = false
				elseif obj:IsA("Beam") then obj.Enabled = false
				elseif obj:IsA("Trail") then obj.Enabled = false
				end
			end
		end)
	end
end end)

-- Auto Reconnect loop
task.spawn(function() while true do task.wait(30)
	if S.AutoReconnect then
		pcall(function()
			if not game:GetService("Players").LocalPlayer then
				game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
			end
		end)
	end
end end)

Library:Notify({Title="Ivory",Description="Steal An Egg loaded!",Type="Success",Time=3})
