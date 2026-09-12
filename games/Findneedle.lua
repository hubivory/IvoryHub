--// Ivory Hub | Search For The Needle (IvoryHub)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
LocalPlayer.CharacterAdded:Connect(function(c) Character = c; Humanoid = c:WaitForChild("Humanoid"); HumanoidRootPart = c:WaitForChild("HumanoidRootPart") end)

local NeedleHaystack = ReplicatedStorage:WaitForChild("NeedleHaystack", 10)
local Config = require(NeedleHaystack:WaitForChild("Config"))
local PickHay = NeedleHaystack:WaitForChild("PickHay")
local SellHay = NeedleHaystack:WaitForChild("SellHay")
local BuyShopItem = NeedleHaystack:WaitForChild("BuyShopItem")
local BuyUpgrade = NeedleHaystack:WaitForChild("BuyUpgrade")
local NeedleTargetChanged = NeedleHaystack:WaitForChild("NeedleTargetChanged")
local PitchforkDig = NeedleHaystack:WaitForChild("PitchforkDig")
local VacuumAction = NeedleHaystack:WaitForChild("VacuumAction")
local CollectGem = NeedleHaystack:WaitForChild("CollectGem")
local HotbarSlots = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("HotbarSlots"))
local BarnShop = Workspace:WaitForChild("BarnShop")
local SellModel = Workspace:WaitForChild("SellModel")
local Cow = SellModel.Cow.Cow
local CowLook = Cow.CFrame.LookVector

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
    writefile(LIB_FILE, game:HttpGet(LIB_URL))
end
local Library = loadstring(readfile(LIB_FILE))()

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 720,
	Height = 600,
	AccentColor = Color3.fromRGB(180, 130, 255),
	MinimizeKey = Enum.KeyCode.RightBracket
})

local menuOpen = true
UserInputService.ModalEnabled = true
UserInputService.MouseBehavior = Enum.MouseBehavior.Default

local function setMenuOpen(open)
	menuOpen = open
	if open then
		UserInputService.ModalEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		UserInputService.ModalEnabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

local origToggle = Window.ToggleMinimize
if origToggle then
	Window.ToggleMinimize = function(self, ...)
		local result = origToggle(self, ...)
		setMenuOpen(not menuOpen)
		return result
	end
end

RunService.RenderStepped:Connect(function()
	if menuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		UserInputService.ModalEnabled = true
	end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.RightBracket or input.KeyCode == Enum.KeyCode.RightShift then
		setMenuOpen(not menuOpen)
	end
end)

local FarmTab = Window:CreateTab("Farm")
local TeleportTab = Window:CreateTab("Teleport")
local PlayerTab = Window:CreateTab("Player")
local VisualsTab = Window:CreateTab("Visuals")
local SettingsTab = Window:CreateTab("Settings")

local CTL = {}

local STATE = {AutoCollect=false,AutoSell=false,AutoFarmLoop=false,SpeedBoost=16,InfiniteJump=false,NoClip=false,AutoBuyShop=false,AutoBuyUpgrades=false,TeleportToNeedle=false,NeedleESP=false,SellPartESP=false,ShopESP=false,GemESP=false,MutationESP=false,SelectedShopItem="CapacityBag",SelectedWeapon="All"}
local noclipConn=nil; local needlePosition=nil
local espFolder = Instance.new("Folder"); espFolder.Name="IvoryESP"; espFolder.Parent=Workspace

NeedleTargetChanged.OnClientEvent:Connect(function(...) for _,arg in ipairs({...}) do if typeof(arg)=="Vector3" then needlePosition=arg elseif typeof(arg)=="CFrame" then needlePosition=arg.Position elseif typeof(arg)=="Instance" and arg:IsA("BasePart") then needlePosition=arg.Position end end end)

local function getHRP() local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=LocalPlayer.Character; return c and c:FindFirstChildWhichIsA("Humanoid") end
local function isFull() local held=LocalPlayer:GetAttribute("HayHeld") or 0; local cap=LocalPlayer:GetAttribute("HayCapacity") or 25; if LocalPlayer:GetAttribute("InfiniteBagOwned")==true then return false end; return held>=cap end

local function toTarget(Pos)
	local hrp=getHRP(); if not hrp then return end; local hum=getHum(); if not hum then return end
	if hum.Health<=0 then repeat task.wait() until getHum() and getHum().Health>0; task.wait(0.2); hrp=getHRP(); if not hrp then return end end
	local target; if typeof(Pos)=="Vector3" then target=CFrame.new(Pos) elseif typeof(Pos)=="CFrame" then target=Pos else return end
	local dist=(target.Position-hrp.Position).Magnitude; if dist<5 then hrp.CFrame=target; return end
	pcall(function() local tw=TweenService:Create(hrp,TweenInfo.new(dist/200,Enum.EasingStyle.Linear),{CFrame=target}); tw:Play(); tw.Completed:Wait() end)
end

local function findNeedle()
	if needlePosition then return needlePosition end
	return nil
end

local function findHayPieces()
	local f=Workspace:FindFirstChild("HaystackClient"); if not f then return {},{} end
	local rainbow,normal={},{}
	for _,p in ipairs(f:GetChildren()) do if p:IsA("BasePart") then local hid=p:GetAttribute("HayId"); if hid then if Config.isRainbow(hid) then table.insert(rainbow,{hayId=hid,part=p}) else table.insert(normal,{hayId=hid,part=p}) end end end end
	return rainbow,normal
end

local function getGrabCandidates(part)
	local grabCount=LocalPlayer:GetAttribute("HayGrabCount") or 1
	local grabRadius=LocalPlayer:GetAttribute("HayGrabRadius") or 0
	if grabCount<=1 or grabRadius<=0 then return {} end
	local f=Workspace:FindFirstChild("HaystackClient"); if not f then return {} end
	local op=OverlapParams.new(); op.FilterType=Enum.RaycastFilterType.Include; op.FilterDescendantsInstances={f}
	local candidates={}
	for _,p in ipairs(Workspace:GetPartBoundsInRadius(part.Position,grabRadius,op)) do
		if p~=part and p:IsA("BasePart") then
			local hid=p:GetAttribute("HayId")
			if hid then local d=(p.Position-part.Position).Magnitude; table.insert(candidates,{hayId=hid,dist=d}) end
		end
	end
	table.sort(candidates,function(a,b) return a.dist<b.dist end)
	local result={}
	for i=1,math.min(grabCount-1,#candidates) do table.insert(result,candidates[i].hayId) end
	return result
end

local function clearESP(name) for _,c in ipairs(espFolder:GetChildren()) do if c.Name==name then c:Destroy() end end end
local function makeHL(name,part,fc,oc,ft) local hl=Instance.new("Highlight"); hl.Name=name; hl.FillColor=fc; hl.OutlineColor=oc; hl.FillTransparency=ft or 0.7; hl.OutlineTransparency=0; hl.Adornee=part; hl.Parent=espFolder; return hl end
local function makeBB(name,part,txt,tc,sz) local bb=Instance.new("BillboardGui"); bb.Name=name; bb.Size=sz or UDim2.new(0,100,0,40); bb.StudsOffset=Vector3.new(0,3,0); bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.Adornee=part; bb.Parent=espFolder; local tl=Instance.new("TextLabel"); tl.Size=UDim2.new(1,0,1,0); tl.BackgroundTransparency=1; tl.Text=txt; tl.TextColor3=tc; tl.TextSize=16; tl.Font=Enum.Font.GothamBold; tl.TextStrokeTransparency=0.3; tl.TextStrokeColor3=Color3.new(0,0,0); tl.Parent=bb; return bb end

local function collectOne(data)
	local slot=HotbarSlots.getEquipped()
	if slot==Config.PITCHFORK_SLOT_INDEX then
		LocalPlayer:SetAttribute("HoveredHayId",data.hayId)
		LocalPlayer:SetAttribute("PitchforkPhase","strike")
		PitchforkDig:FireServer(data.hayId)
		LocalPlayer:SetAttribute("PitchforkPhase","idle")
		task.wait(Config.PITCHFORK_COOLDOWN+0.1)
	elseif slot==Config.TNT_SLOT_INDEX then
		return
	else
		PickHay:FireServer(data.hayId,getGrabCandidates(data.part))
		task.wait(0.15)
	end
end

local function findGems()
	local gc=Workspace:FindFirstChild("GemsClient"); if not gc then return {} end
	local gems={}
	for _,g in ipairs(gc:GetChildren()) do if g:IsA("Model") then
		local p=g:FindFirstChildWhichIsA("BasePart")
		if p then local gid=p:GetAttribute("GemId") or g:GetAttribute("GemId"); if gid then table.insert(gems,{gemId=gid,part=p}) end end
	end end
	return gems
end

local function collectGem(gemData)
	pcall(function() CollectGem:FireServer(gemData.gemId) end)
	task.wait(0.2)
end

-- FARM TAB
FarmTab:CreateSection("Discord")
local DiscordLabel = FarmTab:CreateLabel("Join discord for free keys!")
FarmTab:CreateButton({Name = "Copy Discord Link", Callback = function()
	pcall(function() setclipboard("https://discord.gg/MCWYKBdB4E") end)
	Library.Notify({Title = "Ivory", Content = "Discord Link Copied!", Type = "success", Duration = 3})
end})

task.spawn(function()
	task.wait(1)
	local purpleColor = Color3.fromRGB(180,130,255)
	local fullText = "Join discord for free keys!"
	local cursor = "_"
	local function styleDc()
		pcall(function()
			local lbl = DiscordLabel.Instance
			if lbl then
				lbl.RichText = false
				lbl.TextColor3 = purpleColor
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 26
			end
		end)
	end
	styleDc()
	while true do
		for i=1,#fullText do
			pcall(function()
				DiscordLabel:Set(string.sub(fullText,1,i)..cursor)
				styleDc()
			end)
			task.wait(0.06)
		end
		pcall(function()
			DiscordLabel:Set(fullText)
			styleDc()
		end)
		task.wait(1.5)
		for i=#fullText,0,-1 do
			pcall(function()
				DiscordLabel:Set(string.sub(fullText,1,i)..cursor)
				styleDc()
			end)
			task.wait(0.04)
		end
		pcall(function()
			DiscordLabel:Set("")
			styleDc()
		end)
		task.wait(0.5)
	end
end)

FarmTab:CreateSection("Auto Collect")
FarmTab:CreateLabel("Best used with hand or pitchfork")
CTL.AutoCollect = FarmTab:CreateToggle({Name = "Auto Collect Hay", CurrentValue = false, Callback = function(v)
	STATE.AutoCollect=v; if v then task.spawn(function()
		while STATE.AutoCollect do pcall(function()
			if isFull() then return end
			local gems=findGems()
			for _,gd in ipairs(gems) do if not STATE.AutoCollect or isFull() then break end; collectGem(gd) end
			local rb,nm=findHayPieces()
			for _,data in ipairs(rb) do if not STATE.AutoCollect or isFull() then break end; collectOne(data) end
			for _,data in ipairs(nm) do if not STATE.AutoCollect or isFull() then break end; collectOne(data) end
		end); task.wait(0.1) end
	end) end
end})

FarmTab:CreateSection("Auto Sell")
CTL.AutoSell = FarmTab:CreateToggle({Name = "Auto Sell When Full", CurrentValue = false, Callback = function(v)
	STATE.AutoSell=v; if v then task.spawn(function()
		while STATE.AutoSell do pcall(function()
			if isFull() then
				local sp=SellModel:FindFirstChild("SellPart"); if sp then toTarget(sp.Position+Vector3.new(0,3,0)); task.wait(0.5); SellHay:FireServer(); task.wait(1) end
				toTarget(Config.PILE_CENTER+Vector3.new(0,8,0))
			end
		end); task.wait(0.5) end
	end) end
end})

FarmTab:CreateSection("Full Farm Loop")
CTL.AutoFarmLoop = FarmTab:CreateToggle({Name = "Auto Farm Loop (Collect + Sell)", CurrentValue = false, Callback = function(v)
	STATE.AutoFarmLoop=v
	if v then
		STATE.AutoCollect=true
		STATE.NoClip=true
		if not noclipConn then noclipConn=RunService.Stepped:Connect(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end
		task.spawn(function()
			toTarget(Config.PILE_CENTER+Vector3.new(0,8,0))
			while STATE.AutoFarmLoop do pcall(function()
				if isFull() then
					local sp=SellModel:FindFirstChild("SellPart"); if sp then toTarget(sp.Position+Vector3.new(0,3,0)); task.wait(0.5); SellHay:FireServer(); task.wait(1) end
					toTarget(Config.PILE_CENTER+Vector3.new(0,8,0)); task.wait(0.5)
				else
					local gems2=findGems()
					for _,gd in ipairs(gems2) do if not STATE.AutoFarmLoop or isFull() then break end; collectGem(gd) end
					local rb2,nm2=findHayPieces()
					for _,data in ipairs(rb2) do if not STATE.AutoFarmLoop or isFull() then break end; collectOne(data) end
					for _,data in ipairs(nm2) do if not STATE.AutoFarmLoop or isFull() then break end; collectOne(data) end
				end
			end); task.wait(0.1) end
		end)
	else
		STATE.NoClip=false
		if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
	end
end})

FarmTab:CreateSection("Auto Buy")
local shopDisplayNames={"Capacity Bag","Infinite Bag","Pitchfork","TNT","Drone","Vacuum"}
local shopItemIds={"CapacityBag","InfiniteBag","Pitchfork","Tnt","Drone","Vacuum"}
STATE.SelectedShopItem=shopItemIds[1]
CTL.ShopItemSelect = FarmTab:CreateDropdown({Name = "Item to Buy", Options = shopDisplayNames, CurrentOption = {shopDisplayNames[1]}, Callback = function(v) for i,n in ipairs(shopDisplayNames) do if n==v then STATE.SelectedShopItem=shopItemIds[i]; break end end end})
CTL.AutoBuyShop = FarmTab:CreateToggle({Name = "Auto Buy Selected Item", CurrentValue = false, Callback = function(v) STATE.AutoBuyShop=v; if v then task.spawn(function() while STATE.AutoBuyShop do pcall(function() BuyShopItem:FireServer(STATE.SelectedShopItem) end); task.wait(2) end end) end end})

local weaponDisplayNames={"All","Hand","Pitchfork","TNT","Drone","Vacuum"}
local weaponUpgradeKeys={
	All={"Capacity","HandHold","Speed","Grab","TntLuck","TntCooldown","TntPower","PitchforkCooldown","PitchforkHold","Pitchfork","DroneSpeed","DroneGrab","DroneCapacity","VacuumPower","VacuumCooling","VacuumRuntime"},
	Hand={"Capacity","HandHold","Speed","Grab"},
	Pitchfork={"PitchforkCooldown","PitchforkHold","Pitchfork"},
	TNT={"TntLuck","TntCooldown","TntPower"},
	Drone={"DroneSpeed","DroneGrab","DroneCapacity"},
	Vacuum={"VacuumPower","VacuumCooling","VacuumRuntime"}
}
STATE.SelectedWeapon="All"
CTL.WeaponSelect = FarmTab:CreateDropdown({Name = "Weapon Upgrades", Options = weaponDisplayNames, CurrentOption = {"All"}, Callback = function(v) STATE.SelectedWeapon=v end})
CTL.AutoBuyUpgrades = FarmTab:CreateToggle({Name = "Auto Buy Weapon Upgrades", CurrentValue = false, Callback = function(v) STATE.AutoBuyUpgrades=v; if v then task.spawn(function() while STATE.AutoBuyUpgrades do pcall(function() local keys=weaponUpgradeKeys[STATE.SelectedWeapon] or weaponUpgradeKeys.All; for _,t in ipairs(keys) do BuyUpgrade:FireServer(t); task.wait(0.1) end end); task.wait(5) end end) end end})

-- TELEPORT TAB
TeleportTab:CreateSection("Needle")
TeleportTab:CreateButton({Name = "Teleport to Needle", Callback = function() local pos=findNeedle(); if pos then toTarget(pos+Vector3.new(0,5,0)) end end})
CTL.TeleportNeedle = TeleportTab:CreateToggle({Name = "Auto Teleport to Needle", CurrentValue = false, Callback = function(v) STATE.TeleportToNeedle=v; if v then task.spawn(function() while STATE.TeleportToNeedle do pcall(function() local pos=findNeedle(); if pos then toTarget(pos+Vector3.new(0,5,0)) end end); task.wait(1) end end) end end})
TeleportTab:CreateButton({Name = "Teleport to Haystack", Callback = function()
	local f=Workspace:FindFirstChild("HaystackClient")
	if f then local topY=0; for _,p in ipairs(f:GetChildren()) do if p:IsA("BasePart") and p.Position.Y>topY then topY=p.Position.Y end end; if topY>0 then toTarget(Vector3.new(Config.PILE_CENTER.X,topY+5,Config.PILE_CENTER.Z)) end end
end})

TeleportTab:CreateSection("Shop")
TeleportTab:CreateButton({Name = "Teleport to Sell Cow", Callback = function() local cp=Cow.Position; local fp=cp+CowLook*6; toTarget(CFrame.new(fp.X,cp.Y+1,fp.Z)*CFrame.Angles(0,math.atan2(-CowLook.X,-CowLook.Z),0)) end})
TeleportTab:CreateButton({Name = "Teleport to Barn Shop", Callback = function() local s=BarnShop:FindFirstChild("InfiniteCapacityBag"); if s then local h=s:FindFirstChild("ShopHitbox"); if h then toTarget(h.Position+Vector3.new(0,3,0)) end end end})

TeleportTab:CreateSection("Locations")
TeleportTab:CreateButton({Name = "Teleport to Haystack Center", Callback = function() toTarget(Config.PILE_CENTER+Vector3.new(0,8,0)) end})

-- PLAYER TAB
PlayerTab:CreateSection("Movement")
CTL.WalkSpeed = PlayerTab:CreateSlider({Name = "Walk Speed", Range = {16, 500}, CurrentValue = 16, Callback = function(v) STATE.SpeedBoost=v; pcall(function() Humanoid.WalkSpeed=v end) end})
CTL.InfJump = PlayerTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Callback = function(v) STATE.InfiniteJump=v end})
CTL.NoClip = PlayerTab:CreateToggle({Name = "No Clip", CurrentValue = false, Callback = function(v) STATE.NoClip=v; if v then noclipConn=RunService.Stepped:Connect(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) else if noclipConn then noclipConn:Disconnect(); noclipConn=nil end end end})
UserInputService.JumpRequest:Connect(function() if STATE.InfiniteJump then pcall(function() local c=LocalPlayer.Character; if c then local h=c:FindFirstChildWhichIsA("Humanoid"); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end) end end)

-- VISUALS TAB
VisualsTab:CreateSection("ESP")
CTL.NeedleESP = VisualsTab:CreateToggle({Name = "Needle ESP", CurrentValue = false, Callback = function(v) STATE.NeedleESP=v; if not v then clearESP("NeedleESP") end; if v then task.spawn(function() while STATE.NeedleESP do pcall(function() clearESP("NeedleESP"); local pos=findNeedle(); if pos then local p=Instance.new("Part"); p.Size=Vector3.new(2,2,2); p.Position=pos; p.Anchored=true; p.CanCollide=false; p.Transparency=1; p.Parent=espFolder; makeHL("NeedleESP",p,Color3.fromRGB(255,50,50),Color3.fromRGB(255,0,0),0.5); makeBB("NeedleESP",p,"NEEDLE",Color3.fromRGB(255,50,50)) end end); task.wait(0.5) end end) end end})
CTL.SellPartESP = VisualsTab:CreateToggle({Name = "Sell Part ESP", CurrentValue = false, Callback = function(v) STATE.SellPartESP=v; if not v then clearESP("SellESP") end; if v then task.spawn(function() while STATE.SellPartESP do pcall(function() clearESP("SellESP"); for _,part in ipairs(SellModel:GetChildren()) do if part.Name=="SellPart" and part:IsA("BasePart") then makeHL("SellESP",part,Color3.fromRGB(50,255,50),Color3.fromRGB(0,200,0),0.6); makeBB("SellESP",part,"SELL",Color3.fromRGB(50,255,50),UDim2.new(0,80,0,30)) end end end); task.wait(1) end end) end end})
CTL.ShopESP = VisualsTab:CreateToggle({Name = "Shop ESP", CurrentValue = false, Callback = function(v) STATE.ShopESP=v; if not v then clearESP("ShopESP") end; if v then task.spawn(function() while STATE.ShopESP do pcall(function() clearESP("ShopESP"); for _,item in ipairs(BarnShop:GetChildren()) do if item:IsA("Model") or item:IsA("BasePart") then local h=item:FindFirstChild("ShopHitbox"); if h then makeHL("ShopESP",h,Color3.fromRGB(255,200,50),Color3.fromRGB(255,150,0),0.7); makeBB("ShopESP",h,item.Name,Color3.fromRGB(255,200,50),UDim2.new(0,80,0,30)) end end end end); task.wait(1) end end) end end})
CTL.GemESP = VisualsTab:CreateToggle({Name = "Gem ESP", CurrentValue = false, Callback = function(v) STATE.GemESP=v; if not v then clearESP("GemESP") end; if v then task.spawn(function() while STATE.GemESP do pcall(function() clearESP("GemESP"); local gc=Workspace:FindFirstChild("GemsClient"); if gc then for _,gem in ipairs(gc:GetChildren()) do if gem:IsA("Model") then local p=gem:FindFirstChildWhichIsA("BasePart"); if p then makeHL("GemESP",p,Color3.fromRGB(100,200,255),Color3.fromRGB(0,150,255),0.5); makeBB("GemESP",p,"GEM",Color3.fromRGB(100,200,255),UDim2.new(0,60,0,25)) end end end end end); task.wait(1) end end) end end})
CTL.MutationESP = VisualsTab:CreateToggle({Name = "Mutation (Rainbow) ESP", CurrentValue = false, Callback = function(v) STATE.MutationESP=v; if not v then clearESP("MutationESP") end; if v then task.spawn(function() while STATE.MutationESP do pcall(function() clearESP("MutationESP"); local hc=Workspace:FindFirstChild("HaystackClient"); local hrp=getHRP(); if hc and hrp then for _,piece in ipairs(hc:GetChildren()) do if piece:IsA("BasePart") then local hid=piece:GetAttribute("HayId"); if hid and Config.isRainbow(hid) then local d=(piece.Position-hrp.Position).Magnitude; if d<60 then makeHL("MutationESP",piece,Color3.fromRGB(255,0,255),Color3.fromRGB(255,255,0),0.3); if d<20 then makeBB("MutationESP",piece,"RAINBOW x"..Config.RAINBOW_VALUE_MULTIPLIER,Color3.fromRGB(255,0,255),UDim2.new(0,120,0,30)) end end end end end end end); task.wait(0.5) end end) end end})

-- SETTINGS TAB
SettingsTab:CreateSection("Credits")
local CreditsLabel = SettingsTab:CreateLabel("Made by Mommy Veqxoo")

task.spawn(function()
	task.wait(1)
	local creditsColor = Color3.fromRGB(255,175,186)
	local fullText = "Made by Mommy Veqxoo\n</3"
	local cursor = "_"
	local function styleCredit()
		pcall(function()
			local lbl = CreditsLabel.Instance
			if lbl then
				lbl.RichText = false
				lbl.TextColor3 = creditsColor
				lbl.Font = Enum.Font.GothamBold
				lbl.TextSize = 26
			end
		end)
	end
	styleCredit()
	while true do
		for i=1,#fullText do
			pcall(function()
				CreditsLabel:Set(string.sub(fullText,1,i)..cursor)
				styleCredit()
			end)
			task.wait(0.06)
		end
		pcall(function()
			CreditsLabel:Set(fullText)
			styleCredit()
		end)
		task.wait(1.5)
		for i=#fullText,0,-1 do
			pcall(function()
				CreditsLabel:Set(string.sub(fullText,1,i)..cursor)
				styleCredit()
			end)
			task.wait(0.04)
		end
		pcall(function()
			CreditsLabel:Set("")
			styleCredit()
		end)
		task.wait(0.5)
	end
end)

SettingsTab:CreateSection("Menu")
SettingsTab:CreateKeybind({Name = "Menu Keybind", CurrentKeybind = "RightShift", HoldToActivate = false})

SettingsTab:CreateButton({Name = "Unload Script", Callback = function()
	pcall(function()
		STATE.AutoCollect=false; STATE.AutoSell=false; STATE.AutoFarmLoop=false; STATE.TeleportToNeedle=false
		STATE.NeedleESP=false; STATE.SellPartESP=false; STATE.ShopESP=false; STATE.GemESP=false; STATE.MutationESP=false
		STATE.AutoBuyShop=false; STATE.AutoBuyUpgrades=false
		if noclipConn then noclipConn:Disconnect() end
		espFolder:ClearAllChildren(); espFolder:Destroy()
	end)
	UserInputService.ModalEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	Library.Unload()
end})

Library.Notify({Title = "Ivory", Content = "Search For The Needle loaded!", Type = "success", Duration = 5})
