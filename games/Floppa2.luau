--// Raise a Floppa 2 - Ivory Hub
--// PlaceId: 9772878203

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

local genv = getgenv()
local Library, ThemeManager, SaveManager
local ls, ts, ss = genv._IvoryLibSrc, genv._IvoryTMSrc, genv._IvorySMSrc
if ls then Library = loadstring(ls)(); ThemeManager = loadstring(ts)(); SaveManager = loadstring(ss)()
else local r = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
	Library = loadstring(game:HttpGet(r.."Library.lua"))(); ThemeManager = loadstring(game:HttpGet(r.."addons/ThemeManager.lua"))(); SaveManager = loadstring(game:HttpGet(r.."addons/SaveManager.lua"))() end
if not Library then warn("[Ivory] Load failed"); return end
local Options, Toggles = Library.Options, Library.Toggles

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = {
	CollectRent = Events["Collect Rent"],
	RaiseRent = Events["Raise Rent"],
	Cooking = Events.Cooking,
	Brew = Events.Brew,
	Rain = Events.Rain,
	Rebirth = Events.Rebirth,
	Save = Events.Save,
	SmallVault = Events["Small Vault"],
	BigVault = Events["Big Vault"],
	SlotsSpin = Events["Slots Spin"],
	Planter = Events.Planter,
	MagicLamp = Events["Magic Lamp"],
	RebirthVault = Events["Rebirth Vault"],
	FloppaSlots = Events["Floppa Slots"],
}

local STATE = {
	AutoClick = false, ClickSpeed = 0.1,
	AutoCollectRent = false, AutoRaiseRent = false,
	AutoCook = false, AutoBrew = false, AutoRain = false,
	AutoSlots = false, AutoRebirth = false, AutoSave = false,
	InfJump = false, Noclip = false, AntiAfk = false,
	SpeedBoost = false, SpeedValue = 16,
	ESPEnabled = false, ESPColor = Color3.fromRGB(255, 80, 80),
}
genv.FLOPPA_STATE = STATE

local function getHRP() local c=LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=LocalPlayer.Character; return c and c:FindFirstChildWhichIsA("Humanoid") end
local function alive() local c=LocalPlayer.Character; if not c then return false end; local h=c:FindFirstChildWhichIsA("Humanoid"); return h and h.Health>0 end

local espCache = {}
local function clearESP()
	for _,o in pairs(espCache) do pcall(function() if o and o.Parent then o:Destroy() end end) end
	espCache = {}
end
local function mkESP(part,text,color)
	if not part or not part.Parent then return end
	local b=Instance.new("BillboardGui"); b.Name="IvoryESP"; b.Adornee=part; b.Size=UDim2.new(0,140,0,30); b.StudsOffset=Vector3.new(0,3,0); b.AlwaysOnTop=true; b.LightInfluence=0
	local l=Instance.new("TextLabel"); l.Parent=b; l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=0.5; l.BackgroundColor3=Color3.new(0,0,0); l.TextColor3=color; l.TextStrokeTransparency=0.3; l.TextScaled=true; l.Font=Enum.Font.GothamBold; l.Text=text
	b.Parent=LocalPlayer:WaitForChild("PlayerGui"); table.insert(espCache,b)
end
local function updateESP()
	clearESP(); if not STATE.ESPEnabled then return end
	local floppa = Workspace:FindFirstChild("Floppa")
	if floppa and floppa:FindFirstChild("HumanoidRootPart") then
		mkESP(floppa.HumanoidRootPart, "Floppa", Color3.fromRGB(255, 200, 50))
	end
end

local Window = Library:CreateWindow({
	Title="Ivory", Icon="cat",
	Footer={"v1.4 |",{Text="Game",Copyable=true},"|",{Text=tostring(LocalPlayer.UserId),Copyable=true}},
	CopyableFooter=true, FuzzySearch=true, SearchValues=true,
	Minimizable=true, MinimizeKeybind=Enum.KeyCode.RightBracket, MinimizedWidth=280,
	NotifySide="Right", ShowCustomCursor=true, SearchKeybind=Enum.KeyCode.F, CornerRadius=4,
	Animations={ToggleWindow=false,TabSwitch=false,Groupbox=false,Dropdown=false,KeyPicker=false,SubTabUnderline=true},
})

local MainTab = Window:AddTab({Name="Main",Icon="home"})

local FloppaSub = MainTab:AddSubTab("Floppa","cat")
local FG1 = FloppaSub:AddLeftGroupbox("Floppa","cat")
FG1:AddToggle("AutoClick",{Text="Auto Click Floppa",Default=false,Callback=function(v) STATE.AutoClick=v end}):AddKeyPicker("ClickKey",{Default="None",Text="Click Key",Mode="Toggle",SyncToggleState=true,NoUI=false})
FG1:AddSlider("ClickSpeed",{Text="Click Speed",Default=0.1,Min=0.05,Max=1,Rounding=2,Suffix="s",Callback=function(v) STATE.ClickSpeed=v end})

local FG2 = FloppaSub:AddRightGroupbox("Rent","dollar-sign")
FG2:AddToggle("AutoCollectRent",{Text="Auto Collect Rent",Default=false,Callback=function(v) STATE.AutoCollectRent=v end})
FG2:AddToggle("AutoRaiseRent",{Text="Auto Raise Rent",Default=false,Callback=function(v) STATE.AutoRaiseRent=v end})

local EconSub = MainTab:AddSubTab("Economy","coins")
local EG1 = EconSub:AddLeftGroupbox("Cooking & Brewing","flame")
EG1:AddToggle("AutoCook",{Text="Auto Cook",Default=false,Callback=function(v) STATE.AutoCook=v end})
EG1:AddToggle("AutoBrew",{Text="Auto Brew",Default=false,Callback=function(v) STATE.AutoBrew=v end})
EG1:AddToggle("AutoRain",{Text="Auto Rain",Default=false,Callback=function(v) STATE.AutoRain=v end})

local EG2 = EconSub:AddRightGroupbox("Slots & Vault","zap")
EG2:AddToggle("AutoSlots",{Text="Auto Slots Spin",Default=false,Callback=function(v) STATE.AutoSlots=v end})
EG2:AddButton("Collect Small Vault",function() Remotes.SmallVault:FireServer() end)
EG2:AddButton("Collect Big Vault",function() Remotes.BigVault:FireServer() end)

local ProgSub = MainTab:AddSubTab("Progress","trending-up")
local PG1 = ProgSub:AddLeftGroupbox("Rebirth","refresh-cw")
PG1:AddToggle("AutoRebirth",{Text="Auto Rebirth",Default=false,Callback=function(v) STATE.AutoRebirth=v end})
PG1:AddButton("Rebirth Now",function() Remotes.Rebirth:FireServer() end)

local PG2 = ProgSub:AddRightGroupbox("Save & Misc","save")
PG2:AddToggle("AutoSave",{Text="Auto Save",Default=false,Callback=function(v) STATE.AutoSave=v end})
PG2:AddButton("Save Now",function() Remotes.Save:FireServer() end)
PG2:AddButton("Plant Seed",function() Remotes.Planter:FireServer() end)

local PlayerTab = Window:AddTab({Name="Player",Icon="user"})
local MoveSub = PlayerTab:AddSubTab("Movement","move")
local MG1 = MoveSub:AddLeftGroupbox("Character","person-standing")
MG1:AddToggle("InfJump",{Text="Infinite Jump",Default=false,Callback=function(v) STATE.InfJump=v end}):AddKeyPicker("InfJumpKey",{Default="None",Text="Inf Jump",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddToggle("Noclip",{Text="Noclip",Default=false,Callback=function(v) STATE.Noclip=v end}):AddKeyPicker("NoclipKey",{Default="None",Text="Noclip",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddToggle("AntiAfk",{Text="Anti-AFK",Default=false,Callback=function(v) STATE.AntiAfk=v end})
MG1:AddToggle("SpeedBoost",{Text="Speed Boost",Risky=true,Default=false,Callback=function(v) STATE.SpeedBoost=v end}):AddKeyPicker("SpeedKey",{Default="None",Text="Speed",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG1:AddSlider("SpeedVal",{Text="Walk Speed",Default=16,Min=16,Max=200,Rounding=0,Callback=function(v) STATE.SpeedValue=v end})

local MG2 = MoveSub:AddRightGroupbox("Teleports","map-pin")
MG2:AddButton("Teleport to Floppa",function() local f=Workspace:FindFirstChild("Floppa"); if f and f:FindFirstChild("HumanoidRootPart") then local h=getHRP(); if h then h.CFrame=f.HumanoidRootPart.CFrame+Vector3.new(0,5,0) end end end)
MG2:AddButton("Teleport to House",function() local house=Workspace:FindFirstChild("House"); if house then local r=house:FindFirstChildWhichIsA("BasePart"); if r then local h=getHRP(); if h then h.CFrame=r.CFrame+Vector3.new(0,5,0) end end end end)
MG2:AddButton("Teleport to Village",function() local v=Workspace:FindFirstChild("Village"); if v then local r=v:FindFirstChildWhichIsA("BasePart"); if r then local h=getHRP(); if h then h.CFrame=r.CFrame+Vector3.new(0,5,0) end end end end)

local VisTab = Window:AddTab({Name="Visuals",Icon="eye"})
local ESPSub = VisTab:AddSubTab("ESP","scan")
local VG1 = ESPSub:AddLeftGroupbox("ESP","eye")
VG1:AddToggle("ESPEnabled",{Text="Enable ESP",Default=false,Callback=function(v) STATE.ESPEnabled=v; if v then updateESP() else clearESP() end end}):AddKeyPicker("ESPKey",{Default="None",Text="ESP Key",Mode="Toggle",SyncToggleState=true,NoUI=false})
local VG2 = ESPSub:AddRightGroupbox("Color","palette")
VG2:AddLabel("ESP Color"):AddColorPicker("ESPColorPicker",{Default=STATE.ESPColor,Title="ESP Color",Callback=function(v) STATE.ESPColor=v; if STATE.ESPEnabled then updateESP() end end})

ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("IvoryHub"); SaveManager:SetFolder("IvoryHub"); SaveManager:SetSubFolder("floppa2")

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

-- LOOPS
UserInputService.JumpRequest:Connect(function() if STATE.InfJump then pcall(function() local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end) end end)
task.spawn(function() while true do task.wait(0.5) if STATE.Noclip then pcall(function() local c=LocalPlayer.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end end end)
task.spawn(function() while true do task.wait(0.1) if STATE.SpeedBoost then pcall(function() local h=getHum(); if h and h.WalkSpeed~=STATE.SpeedValue then h.WalkSpeed=STATE.SpeedValue end end) end end end)
task.spawn(function() while true do task.wait(60) if STATE.AntiAfk then pcall(function() VIM:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame); task.wait(0.1); VIM:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame) end) end end end)
task.spawn(function() while true do task.wait(2) if STATE.ESPEnabled then pcall(updateESP) end end end)
task.spawn(function() while true do task.wait(STATE.ClickSpeed) if STATE.AutoClick and alive() then pcall(function() local f=Workspace:FindFirstChild("Floppa"); if f then local cd=f:FindFirstChild("ClickDetector"); if cd then fireclickdetector(cd) end end end) end end end)
task.spawn(function() while true do task.wait(2) if STATE.AutoCollectRent then pcall(function() Remotes.CollectRent:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if STATE.AutoRaiseRent then pcall(function() Remotes.RaiseRent:FireServer() end) end end end)
task.spawn(function() while true do task.wait(3) if STATE.AutoCook then pcall(function() Remotes.Cooking:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if STATE.AutoBrew then pcall(function() Remotes.Brew:FireServer() end) end end end)
task.spawn(function() while true do task.wait(10) if STATE.AutoRain then pcall(function() Remotes.Rain:FireServer() end) end end end)
task.spawn(function() while true do task.wait(3) if STATE.AutoSlots then pcall(function() Remotes.SlotsSpin:FireServer() end) end end end)
task.spawn(function() while true do task.wait(5) if STATE.AutoRebirth then pcall(function() Remotes.Rebirth:FireServer() end) end end end)
task.spawn(function() while true do task.wait(30) if STATE.AutoSave then pcall(function() Remotes.Save:FireServer() end) end end end)

Library:Notify({Title="Ivory",Description="Raise a Floppa 2 loaded!",Type="Success",Time=3})
