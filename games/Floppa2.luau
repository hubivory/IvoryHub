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

local genv = getgenv()
local Library, ThemeManager, SaveManager
local ls, ts, ss = genv._IvoryLibSrc, genv._IvoryTMSrc, genv._IvorySMSrc
if ls then Library=loadstring(ls)(); ThemeManager=loadstring(ts)(); SaveManager=loadstring(ss)()
else local r="https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
Library=loadstring(game:HttpGet(r.."Library.lua"))(); ThemeManager=loadstring(game:HttpGet(r.."addons/ThemeManager.lua"))(); SaveManager=loadstring(game:HttpGet(r.."addons/SaveManager.lua"))() end
if not Library then warn("[Ivory] Load failed"); return end
local Options, Toggles = Library.Options, Library.Toggles

local Events = RS:WaitForChild("Events")
local R = {
	CollectRent=Events["Collect Rent 2"], RaiseRent=Events["Raise Rent 2"],
	Cooking=Events.Cooking, Brew=Events.Brew, Rain=Events.Rain,
	Rebirth=Events.Rebirth, Save=Events.Save, Unlock=Events.Unlock,
	SmallVault=Events["Small Vault"], BigVault=Events["Big Vault"],
	SlotsSpin=Events["Slots Spin"], Planter=Events.Planter,
	MagicLamp=Events["Magic Lamp"], RebirthVault=Events["Rebirth Vault"],
	FloppaSlots=Events["Floppa Slots"], LockVault=Events["Lock Vault"],
	Ascend=Events.Ascend, Skin=Events.Skin, Wormhole=Events.Wormhole,
}

local S = {
	AutoClick=false, ClickSpeed=0.1,
	AutoCollectDrops=false, AutoPayRent=false, AutoCleanPoop=false,
	AutoRefillBowls=false, AutoCollectRoommateRent=false,
	AutoInterwebs=false, AutoFishing=false,
	BackroomsBypass=false, AutoAlmondWater=false,
	AutoPlant=false, AutoCook=false,
	AntiRaid=false, AltarAutoFight=false, RaidFailSafe=false,
	InfJump=false, Noclip=false, AntiAfk=false,
	SpeedBoost=false, SpeedValue=16, JumpBoost=false, JumpValue=50,
	ESPEnabled=false, ESPEggs=true, ESPItems=true, ESPEnemies=true,
	ESPColor=Color3.fromRGB(255,80,80),
	AutoRebirth=false, AutoSave=false, AutoSlots=false,
	ReduceLag=false,
}
genv.FLOPPA_STATE = S

local function gHRP() local c=LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function gHum() local c=LP.Character; return c and c:FindFirstChildWhichIsA("Humanoid") end
local function alive() local c=LP.Character; if not c then return false end; local h=c:FindFirstChildWhichIsA("Humanoid"); return h and h.Health>0 end
local function getFloppa() return WS:FindFirstChild("Floppa") end

-- ESP
local espC={}
local function clearESP() for _,o in pairs(espC) do pcall(function() if o and o.Parent then o:Destroy() end end) end; espC={} end
local function mkESP(p,t,c) if not p or not p.Parent then return end; local b=Instance.new("BillboardGui");b.Name="IvoryESP";b.Adornee=p;b.Size=UDim2.new(0,140,0,30);b.StudsOffset=Vector3.new(0,3,0);b.AlwaysOnTop=true;b.LightInfluence=0;local l=Instance.new("TextLabel");l.Parent=b;l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=0.5;l.BackgroundColor3=Color3.new(0,0,0);l.TextColor3=c;l.TextStrokeTransparency=0.3;l.TextScaled=true;l.Font=Enum.Font.GothamBold;l.Text=t;b.Parent=LP:WaitForChild("PlayerGui");table.insert(espC,b) end
local function updateESP()
	clearESP(); if not S.ESPEnabled then return end
	local hrp=gHRP(); if not hrp then return end
	if S.ESPEggs then
		local f=getFloppa()
		if f and f:FindFirstChild("HumanoidRootPart") then mkESP(f.HumanoidRootPart,"Floppa [H:"..(f:FindFirstChild("Display") and f.Display:FindFirstChild("Happiness") and f.Display.Happiness.Text or "?").."]",Color3.fromRGB(255,200,50)) end
	end
	if S.ESPEnemies then
		for _,e in ipairs(WS:FindFirstChild("Enemies") and WS.Enemies:GetChildren() or {}) do
			if e:FindFirstChild("HumanoidRootPart") then mkESP(e.HumanoidRootPart,e.Name,Color3.fromRGB(255,50,50)) end
		end
	end
	if S.ESPItems then
		for _,d in ipairs(WS:GetDescendants()) do
			if d:IsA("BasePart") and (d.Name:find("Cash") or d.Name:find("Gold") or d.Name:find("Key") or d.Name:find("Meteorite")) then
				local d2=(d.Position-hrp.Position).Magnitude; if d2<100 then mkESP(d,d.Name.." ["..math.floor(d2).."m]",Color3.fromRGB(100,255,100)) end
			end
		end
	end
end

--// WINDOW
local Window = Library:CreateWindow({
	Title="Ivory", Icon="cat",
	Footer={"v1.4 |",{Text="Game",Copyable=true},"|",{Text=tostring(LP.UserId),Copyable=true}},
	CopyableFooter=true, FuzzySearch=true, SearchValues=true,
	Minimizable=true, MinimizeKeybind=Enum.KeyCode.RightBracket, MinimizedWidth=280,
	NotifySide="Right", ShowCustomCursor=true, SearchKeybind=Enum.KeyCode.F, CornerRadius=4,
	Animations={ToggleWindow=false,TabSwitch=false,Groupbox=false,Dropdown=false,KeyPicker=false,SubTabUnderline=true},
})

-- ═══ MAIN TAB ═══
local MainTab = Window:AddTab({Name="Main",Icon="home"})

local FarmSub = MainTab:AddSubTab("Farm","crosshair")
local FG1=FarmSub:AddLeftGroupbox("Floppa","cat")
FG1:AddToggle("AutoClick",{Text="Auto Click Floppa",Default=false,Callback=function(v) S.AutoClick=v end}):AddKeyPicker("ClickKey",{Default="None",Text="Click Key",Mode="Toggle",SyncToggleState=true,NoUI=false})
FG1:AddSlider("ClickSpeed",{Text="Click Speed",Default=0.1,Min=0.02,Max=1,Rounding=2,Suffix="s",Callback=function(v) S.ClickSpeed=v end})
FG1:AddToggle("AutoCollectDrops",{Text="Auto Collect Drops",Default=false,Callback=function(v) S.AutoCollectDrops=v end})
FG1:AddToggle("AutoCleanPoop",{Text="Auto Clean Poop",Default=false,Callback=function(v) S.AutoCleanPoop=v end})

local FG2=FarmSub:AddRightGroupbox("Rent & Bowls","dollar-sign")
FG2:AddToggle("AutoPayRent",{Text="Auto Pay Rent",Default=false,Callback=function(v) S.AutoPayRent=v end})
FG2:AddToggle("AutoCollectRoommateRent",{Text="Auto Collect Roommate Rent",Default=false,Callback=function(v) S.AutoCollectRoommateRent=v end})
FG2:AddToggle("AutoRefillBowls",{Text="Auto Refill Bowls",Default=false,Callback=function(v) S.AutoRefillBowls=v end})

local UpgSub = MainTab:AddSubTab("Upgrades","trending-up")
local UG1=UpgSub:AddLeftGroupbox("Interwebs & Fishing","wifi")
UG1:AddToggle("AutoInterwebs",{Text="Auto Buy Interwebs",Default=false,Callback=function(v) S.AutoInterwebs=v end})
UG1:AddToggle("AutoFishing",{Text="Auto Fish",Default=false,Callback=function(v) S.AutoFishing=v end})

local BRSub = MainTab:AddSubTab("Backrooms","door-open")
local BG1=BRSub:AddLeftGroupbox("Backrooms","door-open")
BG1:AddToggle("BackroomsBypass",{Text="Backrooms Maze Bypass",Default=false,Callback=function(v) S.BackroomsBypass=v end})
BG1:AddToggle("AutoAlmondWater",{Text="Auto Feed Almond Water",Default=false,Callback=function(v) S.AutoAlmondWater=v end})

local FarmSub2 = MainTab:AddSubTab("Farming","sprout")
local FM1=FarmSub2:AddLeftGroupbox("Plants & Cooking","sprout")
FM1:AddToggle("AutoPlant",{Text="Auto Plant & Harvest",Default=false,Callback=function(v) S.AutoPlant=v end})
FM1:AddToggle("AutoCook",{Text="Auto Cook",Default=false,Callback=function(v) S.AutoCook=v end})

local CmbSub = MainTab:AddSubTab("Combat","swords")
local CM1=CmbSub:AddLeftGroupbox("Defense","shield")
CM1:AddToggle("AntiRaid",{Text="Anti-Raid / Auto-Kill",Default=false,Callback=function(v) S.AntiRaid=v end})
CM1:AddToggle("AltarAutoFight",{Text="Altar Boss Auto-Fight",Default=false,Callback=function(v) S.AltarAutoFight=v end})
CM1:AddToggle("RaidFailSafe",{Text="Raid Fail-Safe (Server Hop)",Default=false,Callback=function(v) S.RaidFailSafe=v end})

local ProgSub = MainTab:AddSubTab("Progress","refresh-cw")
local PG1=ProgSub:AddLeftGroupbox("Rebirth & Save","refresh-cw")
PG1:AddToggle("AutoRebirth",{Text="Auto Rebirth",Default=false,Callback=function(v) S.AutoRebirth=v end})
PG1:AddButton("Rebirth Now",function() R.Rebirth:FireServer() end)
PG1:AddToggle("AutoSave",{Text="Auto Save",Default=false,Callback=function(v) S.AutoSave=v end})
PG1:AddButton("Save Now",function() R.Save:FireServer() end)
PG1:AddToggle("AutoSlots",{Text="Auto Slots Spin",Default=false,Callback=function(v) S.AutoSlots=v end})

-- ═══ PLAYER TAB ═══
local PlayerTab = Window:AddTab({Name="Player",Icon="user"})
local TpSub = PlayerTab:AddSubTab("Teleports","map-pin")
local TG1=TpSub:AddLeftGroupbox("Locations","map-pin")
TG1:AddButton("To Floppa",function() local f=getFloppa(); if f and f:FindFirstChild("HumanoidRootPart") then local h=gHRP(); if h then h.CFrame=f.HumanoidRootPart.CFrame+Vector3.new(0,5,0) end end end)
TG1:AddButton("To House",function() local h=WS:FindFirstChild("House"); if h then local r=h:FindFirstChildWhichIsA("BasePart"); if r then local h2=gHRP(); if h2 then h2.CFrame=r.CFrame+Vector3.new(0,5,0) end end end end)
TG1:AddButton("To Village",function() local v=WS:FindFirstChild("Village"); if v then local r=v:FindFirstChildWhichIsA("BasePart"); if r then local h=gHRP(); if h then h.CFrame=r.CFrame+Vector3.new(0,5,0) end end end end)
TG1:AddButton("To Backrooms Door",function() local d=WS:FindFirstChild("DoorPoint"); if d then local h=gHRP(); if h then h.CFrame=d.CFrame+Vector3.new(0,3,0) end end end)

local MvSub = PlayerTab:AddSubTab("Movement","move")
local MG1=MvSub:AddLeftGroupbox("Character","person-standing")
MG1:AddToggle("InfJump",{Text="Infinite Jump",Default=false,Callback=function(v) S.InfJump=v end}):AddKeyPicker("InfJumpKey",{Default="None",Text="Inf Jump",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddToggle("Noclip",{Text="Noclip",Default=false,Callback=function(v) S.Noclip=v end}):AddKeyPicker("NoclipKey",{Default="None",Text="Noclip",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddToggle("AntiAfk",{Text="Anti-AFK",Default=false,Callback=function(v) S.AntiAfk=v end})
MG1:AddToggle("SpeedBoost",{Text="Speed Boost",Risky=true,Default=false,Callback=function(v) S.SpeedBoost=v end}):AddKeyPicker("SpeedKey",{Default="None",Text="Speed",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddSlider("SpeedVal",{Text="Walk Speed",Default=16,Min=16,Max=200,Rounding=0,Callback=function(v) S.SpeedValue=v end})
MG1:AddToggle("JumpBoost",{Text="Jump Boost",Default=false,Callback=function(v) S.JumpBoost=v end})
MG1:AddSlider("JumpVal",{Text="Jump Power",Default=50,Min=50,Max=200,Rounding=0,Callback=function(v) S.JumpValue=v end})

-- ═══ VISUALS TAB ═══
local VisTab = Window:AddTab({Name="Visuals",Icon="eye"})
local ESPSub=VisTab:AddSubTab("ESP","scan")
local VG1=ESPSub:AddLeftGroupbox("ESP","eye")
VG1:AddToggle("ESPEnabled",{Text="Enable ESP",Default=false,Callback=function(v) S.ESPEnabled=v; if v then updateESP() else clearESP() end end}):AddKeyPicker("ESPKey",{Default="None",Text="ESP Key",Mode="Toggle",SyncToggleState=true,NoUI=false})
VG1:AddToggle("ESPEggs",{Text="Show Floppa",Default=true,Callback=function(v) S.ESPEggs=v end})
VG1:AddToggle("ESPItems",{Text="Show Items",Default=true,Callback=function(v) S.ESPItems=v end})
VG1:AddToggle("ESPEnemies",{Text="Show Enemies",Default=true,Callback=function(v) S.ESPEnemies=v end})
local VG2=ESPSub:AddRightGroupbox("Color","palette")
VG2:AddLabel("ESP Color"):AddColorPicker("ESPColorPicker",{Default=S.ESPColor,Title="ESP Color",Callback=function(v) S.ESPColor=v end})

local FPSSub=VisTab:AddSubTab("Optimizer","monitor")
local FG3=FPSSub:AddLeftGroupbox("FPS Boost","monitor")
FG3:AddButton("Remove Textures",function()
	for _,d in ipairs(WS:GetDescendants()) do
		if d:IsA("Decal") then d.Transparency=1
		elseif d:IsA("Texture") then d.Transparency=1 end
	end
	Lighting.GlobalShadows=false
	Lighting.Brightness=0
	Lighting.FogEnd=999999
	Lighting.FogStart=0
	Library:Notify({Title="Ivory",Description="Textures removed",Type="Success",Time=2})
end)

-- ═══ SETTINGS (always last) ═══
ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("IvoryHub"); SaveManager:SetFolder("IvoryHub"); SaveManager:SetSubFolder("floppa2")

local SettingsTab = Window:AddTab({Name="UI Settings",Icon="settings"})
ThemeManager:ApplyToTab(SettingsTab); SaveManager:BuildConfigSection(SettingsTab)
local MG=SettingsTab:AddLeftGroupbox("Menu","wrench")
MG:AddToggle("KeybindMenuOpen",{Default=Library.KeybindFrame.Visible,Text="Open Keybind Menu",Callback=function(v) Library.KeybindFrame.Visible=v end})
MG:AddToggle("ShowCustomCursor",{Text="Custom Cursor",Default=Library.ShowCustomCursor,Callback=function(v) Library.ShowCustomCursor=v end})
MG:AddButton("Test Notification",function() Library:Notify({Title="Test",Description=os.date("%H:%M:%S"),Time=4}) end)
MG:AddDropdown("NotificationSide",{Values={"Left","Right"},Default="Right",Text="Notify Side",Callback=function(v) Library:SetNotifySide(v) end})
MG:AddDropdown("DPIDropdown",{Values={"50%","75%","100%","125%","150%","175%","200%"},Default="100%",Text="DPI Scale",Callback=function(v) Library:SetDPIScale(tonumber(v:gsub("%%",""))) end})
MG:AddSlider("UICornerSlider",{Text="Corner Radius",Default=Library.CornerRadius,Min=0,Max=20,Rounding=0,Callback=function(v) Window:SetCornerRadius(v) end})
MG:AddDivider()
MG:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind",{Default="RightShift",NoUI=true,Text="Menu keybind"})
MG:AddButton("Unload",function() clearESP(); Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind
SaveManager:LoadAutoloadConfig()

-- ═══ LOOPS ═══
UIS.JumpRequest:Connect(function() if S.InfJump then pcall(function() local h=gHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end) end end)
task.spawn(function() while true do task.wait(0.5) if S.Noclip then pcall(function() local c=LP.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end end end)
task.spawn(function() while true do task.wait(0.1) if S.SpeedBoost then pcall(function() local h=gHum(); if h and h.WalkSpeed~=S.SpeedValue then h.WalkSpeed=S.SpeedValue end end) end end end)
task.spawn(function() while true do task.wait(0.1) if S.JumpBoost then pcall(function() local h=gHum(); if h and h.JumpPower~=S.JumpValue then h.JumpPower=S.JumpValue end end) end end end)
task.spawn(function() while true do task.wait(60) if S.AntiAfk then pcall(function() VIM:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame); task.wait(0.1); VIM:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame) end) end end end)
task.spawn(function() while true do task.wait(2) if S.ESPEnabled then pcall(updateESP) end end end)
task.spawn(function() while true do task.wait(S.ClickSpeed) if S.AutoClick and alive() then pcall(function() local f=getFloppa(); if f then local cd=f:FindFirstChild("ClickDetector"); if cd then fireclickdetector(cd) end end end) end end end)
task.spawn(function() while true do task.wait(2) if S.AutoCollectRoommateRent then pcall(function() R.CollectRent:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if S.AutoPayRent then pcall(function() R.RaiseRent:FireServer() end) end end end)
task.spawn(function() while true do task.wait(3) if S.AutoCook then pcall(function() R.Cooking:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if S.AutoBrew then pcall(function() R.Brew:FireServer() end) end end end)
task.spawn(function() while true do task.wait(10) if S.AutoRain then pcall(function() R.Rain:FireServer() end) end end end)
task.spawn(function() while true do task.wait(3) if S.AutoSlots then pcall(function() R.SlotsSpin:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if S.AutoRebirth then pcall(function() R.Rebirth:FireServer() end) end end end)
task.spawn(function() while true do task.wait(30) if S.AutoSave then pcall(function() R.Save:FireServer() end) end end end)
task.spawn(function() while true do task.wait(1) if S.AutoCollectDrops then pcall(function()
	for _,d in ipairs(WS:GetDescendants()) do
		if d:IsA("BasePart") and (d.Name:find("Cash") or d.Name:find("Gold") or d.Name:find("Key") or d.Name:find("Meteorite")) then
			local h=gHRP(); if h then d.CFrame=h.CFrame end
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
	if S.AutoClick and alive() then pcall(function()
		local f=getFloppa(); if not f then return end
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
		-- Teleport close if happiness < 50%
		if happy < 50 then
			local root = f:FindFirstChild("HumanoidRootPart")
			local hrp = gHRP()
			if root and hrp then
				hrp.CFrame = root.CFrame + Vector3.new(0, 3, 0)
			end
		end
		-- Fire Pet ProximityPrompt
		for _, d in ipairs(f:GetDescendants()) do
			if d:IsA("ProximityPrompt") and d.ActionText:lower():find("pet") then
				fireproximityprompt(d)
			end
		end
	end) end
end end)

Library:Notify({Title="Ivory",Description="Raise a Floppa 2 loaded!",Type="Success",Time=3})
