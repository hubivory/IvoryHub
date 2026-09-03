local P = game:GetService("ReplicatedStorage")
local K = P.Packages.Knit.Services
local L = game.Players.LocalPlayer

local function R(s,r,n) local sv=K:FindFirstChild(s) and K[s]:FindFirstChild(r) and K[s][r]:FindFirstChild(n) return sv end
local function I(r,...) if r then local a={...} local ok,res=pcall(function() return r:InvokeServer(unpack(a)) end) return res end end

local CK = R("ClickService","RF","Click")
local AC = R("ClickService","RF","ToggleAutoClick")
local GCA = R("ClickService","RF","GetClickAmount")
local RB = R("RebirthService","RF","Rebirth")
local RU = R("RebirthService","RF","Upgrade")
local RC = R("RaceService","RF","ReachedCheckpoint")
local EB = R("PetsService","RF","EquipBest")
local CA = R("PetsService","RF","CraftAll")
local OE = R("EggService","RF","Open")
local CR = R("CodesService","RF","Redeem")
local SP = R("GachaService","RF","Spin")
local FS = R("GachaService","RF","ClaimFreeSpin")
local PC = R("PlaytimeGiftsService","RF","Claim")
local DR = R("DailyRewardsService","RF","Claim")
local PL = R("PacksService","RF","ClaimPack")
local LR = R("LoginRewardService","RF","Claim")
local FP = R("FreePetService","RF","Claim")
local OC = R("CratesService","RF","OpenCrate")

local function GetStages()
    local t = workspace:FindFirstChild("LoadedWorld") and workspace.LoadedWorld:FindFirstChild("Track")
    if not t then return {} end
    local s = {}
    for _,v in ipairs(t:GetChildren()) do
        local n = tonumber(v.Name:match("%d+"))
        local sg = v:FindFirstChild("Sign")
        if n and sg then table.insert(s,{n=n,sg=sg}) end
    end
    table.sort(s,function(a,b) return a.n < b.n end)
    return s
end

local eggs = {}
local ok,data = pcall(function() return require(P.Shared.Modules.EggsData) end)
if ok and data then for name in pairs(data) do table.insert(eggs,name) end end
if #eggs == 0 then eggs = {"Starter01","Starter02","Forest01","Ocean01","Pro01"} end
table.sort(eggs)

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local W = nil
local T = nil
local S = nil

pcall(function()
    W = loadstring(game:HttpGet(repo.."Library.lua"))()
    T = loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
    S = loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()
end)

if not W then
    warn("[Ivory] UI library failed to load - running features without UI")
end

if W and T and S then
    T:SetLibrary(W) S:SetLibrary(W) S:IgnoreThemeSettings() S:SetIgnoreIndexes({"MenuKeybind"})
    T:SetFolder("IvoryHub") S:SetFolder("IvoryHub") S:SetSubFolder("game")
end

if W then

local win = W:CreateWindow({
    Title="Ivory", Icon = "swords",
    Footer={"v1.7 |",{Text="Game",Copyable=true},"|",{Text=tostring(L.UserId),Copyable=true}},
    CopyableFooter=true, FuzzySearch=true, SearchValues=true,
    Minimizable=true, MinimizeKeybind=Enum.KeyCode.RightBracket,
    NotifySide="Right",     ShowCustomCursor=false, SearchKeybind=Enum.KeyCode.F,
    CornerRadius=4, Animations={ToggleWindow=false,TabSwitch=false,Groupbox=false,Dropdown=false,KeyPicker=false,SubTabUnderline=true},
})

local MT = win:AddTab({Name="Home",Icon = "swords"})
local PT = win:AddTab({Name="Player",Icon = "swords"})
local WT = win:AddTab({Name="World",Icon = "swords"})
local ST = win:AddTab({Name="Settings",Icon = "swords"})

local QK = MT:AddSubTab("Quick Actions","rbxassetid://110090697336524")
local AB = MT:AddSubTab("About","rbxassetid://110090697336524")

local TRS = WT:AddSubTab("Teleport","rbxassetid://110090697336524")
local WTS = WT:AddSubTab("Teleport to Mouse","rbxassetid://110090697336524")

local WTMG = WTS:AddLeftGroupbox("Click Teleport","mouse-pointer")
WTMG:AddButton("Teleport to Mouse",function()
    local m = L:GetMouse()
    if m.Hit and L.Character and L.Character:FindFirstChild("HumanoidRootPart") then
        L.Character.HumanoidRootPart.CFrame = m.Hit.CFrame + Vector3.new(0,3,0)
    end
end)

local worldNames = {
    {key="HalloweenObby", display="Halloween Obby", order=-2, event=true},
    {key="Event", display="Fantasy Event", order=-1, event=true},
    {key="Home", display="Home", order=1},
    {key="Space", display="Space", order=2},
    {key="Ocean", display="Ocean", order=3},
    {key="Candy", display="Candy", order=4},
    {key="Hell", display="Lava", order=5},
    {key="Pirate", display="Pirate", order=6},
    {key="Castle", display="Castle", order=7},
    {key="Robot", display="Robot", order=8},
    {key="Forest", display="Forest", order=9},
    {key="Circus", display="Circus", order=10},
    {key="Nuclear", display="Nuclear", order=11},
    {key="Sky River", display="Sky River", order=12},
    {key="Theme Park", display="Theme Park", order=13},
    {key="Water Park", display="Water Park", order=14},
    {key="School", display="School", order=15},
    {key="Bank", display="Bank", order=16},
    {key="Airport", display="Airport", order=17},
    {key="Zoo World", display="Zoo World", order=18},
    {key="Pool", display="Pool", order=19},
    {key="Iceberg", display="Iceberg", order=20},
    {key="Coral", display="Coral", order=21},
    {key="Underwater", display="Underwater", order=22},
    {key="Atlantis", display="Atlantis", order=23},
    {key="Wild West", display="Wild West", order=24},
    {key="Mine", display="Mine", order=25},
    {key="Toy", display="Toy", order=26},
    {key="Prison", display="Prison", order=27},
    {key="Race Track", display="Race Track", order=28},
}

local function doTravel(key, display)
    return function()
        local tsv = K.WorldService.RF.Travel
        local ok, res = pcall(function() return tsv:InvokeServer(key) end)
        if ok and res == true then
            W:Notify({Title="Ivory",Description="Teleporting to "..display.."!",Type="Success",Time=3})
        else
            W:Notify({Title="Ivory",Description=display.." is locked!",Type="Error",Time=3})
        end
    end
end

local evCol = TRS:AddLeftGroupbox("Events","sparkles")
for _, w in ipairs(worldNames) do
    if w.event then
        evCol:AddButton(w.display, doTravel(w.key, w.display))
    end
end
evCol:AddDivider()
evCol:AddButton("Halloween Obby → Finish",function()
    local hrp = L.Character and L.Character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local ok = pcall(function()
            local ending = workspace.LoadedWorld.WorldMain:FindFirstChild("Ending")
            if ending then
                hrp.CFrame = ending.CFrame + Vector3.new(0, 5, 0)
            else
                local t = workspace.LoadedWorld:FindFirstChild("Track")
                if t then
                    local last = nil
                    for _, v in ipairs(t:GetChildren()) do
                        local n = tonumber(v.Name:match("%d+"))
                        local sg = v:FindFirstChild("Sign")
                        if n and sg then
                            if not last or n > last.n then last = {n=n, sg=sg} end
                        end
                    end
                    if last then hrp.CFrame = last.sg.CFrame + Vector3.new(0,3,0) end
                end
            end
        end)
        if ok then
            W:Notify({Title="Ivory",Description="Teleported to Halloween Obby finish!",Type="Success",Time=3})
        end
    end
end)

local regularWorlds = {}
for _, w in ipairs(worldNames) do
    if not w.event then table.insert(regularWorlds, w) end
end

local col1 = TRS:AddLeftGroupbox("Worlds 1-14","globe")
for i = 1, math.min(14, #regularWorlds) do
    local w = regularWorlds[i]
    col1:AddButton(w.display, doTravel(w.key, w.display))
end

local col2 = TRS:AddRightGroupbox("Worlds 15-28","map")
for i = 15, #regularWorlds do
    local w = regularWorlds[i]
    col2:AddButton(w.display, doTravel(w.key, w.display))
end

local QG = QK:AddLeftGroupbox("Auto Clicker","mouse-pointer")
QG:AddLabel("Spam clicks to build speed before racing:")
QG:AddDivider()
local ACT = QG:AddToggle("ACT",{Text="Auto Clicker",Default=false,Tooltip="Rapidly clicks for you"})
local MCS = QG:AddSlider("MCS",{Text="Click Speed (ms)",Default=50,Min=10,Max=500,Rounding=0,Tooltip="Lower = faster clicks"})
ACT:OnChanged(function()
    if ACT.Value then
        task.spawn(function()
            while ACT.Value do
                I(CK)
                task.wait(MCS.Value / 1000)
            end
        end)
    end
end)

local QGR = QK:AddRightGroupbox("Auto Win","trophy")
QGR:AddLabel("Teleports through all 12 checkpoints:")
QGR:AddDivider()
local AWT = QGR:AddToggle("AWT",{Text="Auto Win",Default=false,Tooltip="Teleports through checkpoints to win"})
local AWV = QGR:AddSlider("AWV",{Text="Stage Delay (s)",Default=0.3,Min=0.1,Max=2,Rounding=1})
AWT:OnChanged(function()
    if AWT.Value then
        task.spawn(function()
            while AWT.Value do
                local hrp = L.Character and L.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local st = GetStages()
                    if #st > 0 then
                        for _,s in ipairs(st) do
                            if not AWT.Value then break end
                            pcall(function() hrp.CFrame = s.sg.CFrame + Vector3.new(0,3,0) end)
                            task.wait(0.15)
                            I(RC,s.n)
                            task.wait(AWV.Value)
                        end
                    else I(RC) task.wait(1) end
                else task.wait(1) end
            end
        end)
    end
end)

local QGP = QK:AddLeftGroupbox("Auto Farm","cpu")
local RBT = QGP:AddToggle("RBT",{Text="Auto Rebirth",Default=false,Tooltip="Automatically rebirth when available"})
RBT:OnChanged(function() if RBT.Value then task.spawn(function() while RBT.Value do I(RB) task.wait(3) end end) end end)

local QGR2 = QK:AddRightGroupbox("Quick Rewards","gift")
QGR2:AddLabel("Claim all rewards with one click:")
QGR2:AddDivider()
QGR2:AddButton("Claim All Rewards",function()
    local c = 0
    if I(FS) then c=c+1 end task.wait(0.2)
    if I(SP) then c=c+1 end task.wait(0.2)
    if I(PC) then c=c+1 end task.wait(0.2)
    if I(DR) then c=c+1 end task.wait(0.2)
    if I(PL) then c=c+1 end task.wait(0.2)
    if I(LR) then c=c+1 end task.wait(0.2)
    if I(FP) then c=c+1 end task.wait(0.2)
    if I(OC) then c=c+1 end task.wait(0.2)
    W:Notify({Title="Ivory",Description="Claimed "..c.." reward(s)!",Type="Success",Time=3})
end)
QGR2:AddDivider()
QGR2:AddButton("Free Spin",function() I(FS) end)
QGR2:AddButton("Spin Wheel",function() I(SP) end)
QGR2:AddButton("Playtime Gift",function() I(PC) end)
QGR2:AddButton("Daily Reward",function() I(DR) end)
QGR2:AddButton("Free Pet",function() I(FP) end)

local AEG = QK:AddLeftGroupbox("Quick Eggs","egg")
AEG:AddLabel(#eggs.." eggs available — pick one to open:")
local SEL = eggs[1] or "Starter01"
local EDD = AEG:AddDropdown("EDD",{Text="Select Egg",Values=eggs,Default=SEL,Multi=false})
EDD:OnChanged(function(v) SEL = v end)
local AOE = AEG:AddToggle("AOE",{Text="Auto Open Egg",Default=false,Tooltip="Opens the selected egg on repeat"})
local AOS = AEG:AddSlider("AOS",{Text="Open Interval (s)",Default=2,Min=1,Max=10,Rounding=0})
AOE:OnChanged(function() if AOE.Value then task.spawn(function() while AOE.Value do I(OE,SEL) task.wait(AOS.Value) end end) end end)
AEG:AddButton("Refresh Egg List",function()
    eggs = {}
    local ok2,d2 = pcall(function() return require(P.Shared.Modules.EggsData) end)
    if ok2 and d2 then for name in pairs(d2) do table.insert(eggs,name) end end
    table.sort(eggs) EDD:SetValues(eggs)
    W:Notify({Title="Ivory",Description=#eggs.." eggs loaded!",Type="Info",Time=2})
end)

local AG = QK:AddRightGroupbox("Auto Pets","box")
local EBT2 = AG:AddToggle("EBT2",{Text="Auto Equip Best",Default=false,Tooltip="Equips your strongest pets automatically"})
EBT2:OnChanged(function() if EBT2.Value then task.spawn(function() while EBT2.Value do I(EB) task.wait(5) end end) end end)
local ACT2 = AG:AddToggle("ACT2",{Text="Auto Craft All",Default=false,Tooltip="Crafts duplicate pets automatically"})
ACT2:OnChanged(function() if ACT2.Value then task.spawn(function() while ACT2.Value do I(CA) task.wait(10) end end) end end)

local AIG = AB:AddLeftGroupbox("Ivory Hub","swords")
AIG:AddLabel("Version: 1.7")
AIG:AddLabel("Game: Race Clicker")
AIG:AddLabel("User: "..tostring(L.UserId))
AIG:AddDivider()
AIG:AddLabel("Press F to search any feature")
AIG:AddLabel("Press ] to minimize the window")
AIG:AddLabel("Use the purple I button on mobile")
AIG:AddDivider()
AIG:AddButton("Copy Discord Link",function() if setclipboard then setclipboard("https://discord.gg/MCWYKBdB4E") W:Notify({Title="Ivory",Description="Discord link copied!",Type="Success",Time=3}) end end)

local SGR = AB:AddRightGroupbox("Live Stats","bar-chart")
local CL = SGR:AddLabel("Clicks: Loading...")
task.spawn(function() while true do pcall(function() local a=I(GCA) if a then local raw = tostring(a) local num = tonumber((raw:match("[%d%.]+"))) or 0 local suffix = raw:match("([KMBT])") if suffix == "K" then num = num * 1000 elseif suffix == "M" then num = num * 1000000 end CL:SetText("Clicks: "..tostring(num)) end end) task.wait(2) end end)

local MS = PT:AddSubTab("Movement","rbxassetid://110090697336524")
local VS = PT:AddSubTab("Visuals","rbxassetid://110090697336524")

local SPG = MS:AddLeftGroupbox("Walk Speed","gauge")
local WST = SPG:AddToggle("WST",{Text="Enable Walk Speed",Default=false,Tooltip="Change your movement speed"})
local WSV = SPG:AddSlider("WSV",{Text="Speed Value",Default=16,Min=16,Max=500,Rounding=0,Tooltip="16 = default, higher = faster"})
WST:OnChanged(function() pcall(function() if WST.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.WalkSpeed=WSV.Value end end) end)
WSV:OnChanged(function() pcall(function() if WST.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.WalkSpeed=WSV.Value end end) end)

local JG = MS:AddRightGroupbox("Jump Power","arrow-up")
local JPT = JG:AddToggle("JPT",{Text="Enable Jump Power",Default=false,Tooltip="Change how high you jump"})
local JPV = JG:AddSlider("JPV",{Text="Jump Value",Default=50,Min=50,Max=500,Rounding=0,Tooltip="50 = default, higher = jump higher"})
JPT:OnChanged(function() pcall(function() if JPT.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.JumpPower=JPV.Value end end) end)
JPV:OnChanged(function() pcall(function() if JPT.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.JumpPower=JPV.Value end end) end)

local EG = MS:AddLeftGroupbox("Special Abilities","plus")
local NT = EG:AddToggle("NT",{Text="Noclip",Default=false,Tooltip="Walk through walls"})
local FT = EG:AddToggle("FT",{Text="Fly",Default=false,Tooltip="Fly around the map (WASD + Space/Shift)"})
local FSV = EG:AddSlider("FSV",{Text="Fly Speed",Default=100,Min=50,Max=500,Rounding=0})
local IJT = EG:AddToggle("IJT",{Text="Infinite Jump",Default=false,Tooltip="Jump as many times as you want in the air"})

local EPG = VS:AddLeftGroupbox("Player ESP","eye")
EPG:AddLabel("Show other players through walls:")
local ET = EPG:AddToggle("ET",{Text="Enable ESP",Default=false,Tooltip="Turn on player highlighting"})
local EBT = EPG:AddToggle("EBT",{Text="Boxes",Default=true,Tooltip="Show bounding boxes"})
local ENT = EPG:AddToggle("ENT",{Text="Names",Default=true,Tooltip="Show player names"})
local EHT = EPG:AddToggle("EHT",{Text="Health Bars",Default=true,Tooltip="Show health bars"})
local EDT = EPG:AddToggle("EDT",{Text="Distance",Default=true,Tooltip="Show distance to players"})

local WV = VS:AddRightGroupbox("World","globe")
local FB = WV:AddToggle("FB",{Text="Fullbright",Default=false,Tooltip="Max brightness, no shadows — see everything clearly"})

if T then T:ApplyToTab(ST) end
if S then S:BuildConfigSection(ST) end
local MG = ST:AddLeftGroupbox("Menu","menu")
MG:AddToggle("MKT",{Text="Toggle Menu",Default=true}):AddKeyPicker("MK",{Default="RightShift",Text="Menu Keybind",Mode="Toggle",SyncToggleState=true,NoUI=false})
MG:AddButton("Test Notification",function() W:Notify({Title="Ivory",Description="UI is working!",Type="Info",Time=3}) end)
MG:AddDivider()
MG:AddButton("Unload (Destroy All)",function()
    pcall(function() if NC then NC:Disconnect() end end)
    pcall(function() if EC then EC:Disconnect() end end)
    pcall(function() if FC then FC:Disconnect() end end)
    pcall(function() if IJC then IJC:Disconnect() end end)
    pcall(function() if FV then FV:Destroy() end end)
    pcall(function() if FG then FG:Destroy() end end)
    pcall(function() if L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.WalkSpeed=16 L.Character.Humanoid.JumpPower=50 end end)
    pcall(function() GUI:Destroy() end)
    pcall(function() MobileBtn:Destroy() end)
    pcall(function() W:Toggle() end)
end)

local ESP = {}
local GUI = Instance.new("ScreenGui") GUI.Name="IvoryESP" GUI.ResetOnSpawn=false GUI.DisplayOrder=999
pcall(function() GUI.Parent=game:GetService("CoreGui") end)
if not GUI.Parent then GUI.Parent=L:WaitForChild("PlayerGui") end
local function MakeESP(p)
    if p==L then return end
    pcall(function()
        local e={}
        e.B=Instance.new("BillboardGui",GUI) e.B.Size=UDim2.fromOffset(22,32) e.B.StudsOffset=Vector3.new(0,2.5,0) e.B.AlwaysOnTop=true e.B.MaxDistance=500 e.B.Enabled=false
        e.N=Instance.new("BillboardGui",GUI) e.N.Size=UDim2.fromOffset(200,20) e.N.StudsOffset=Vector3.new(0,3.5,0) e.N.AlwaysOnTop=true e.N.MaxDistance=500 e.N.Enabled=false
        local nl=Instance.new("TextLabel",e.N) nl.Size=UDim2.fromScale(1,1) nl.BackgroundTransparency=1 nl.TextColor3=Color3.new(1,1,1) nl.TextStrokeTransparency=0.5 nl.Font=Enum.Font.Code nl.TextSize=13 nl.Text=p.DisplayName
        e.H=Instance.new("BillboardGui",GUI) e.H.Size=UDim2.fromOffset(4,32) e.H.StudsOffset=Vector3.new(-1.5,2.5,0) e.H.AlwaysOnTop=true e.H.MaxDistance=500 e.H.Enabled=false
        local hf=Instance.new("Frame",e.H) hf.Size=UDim2.fromScale(1,1) hf.BackgroundColor3=Color3.new(0,0,0) hf.BackgroundTransparency=0.4
        local fi=Instance.new("Frame",hf) fi.Size=UDim2.fromScale(1,1) fi.BackgroundColor3=Color3.new(0,1,0)
        ESP[p]=e
    end)
end
local function UpdateESP()
    for p,e in pairs(ESP) do
        pcall(function()
            local c=p.Character local hr=c and c:FindFirstChild("HumanoidRootPart") local hu=c and c:FindFirstChild("Humanoid")
            if hr and hu and hu.Health>0 then
                local my=L.Character and L.Character:FindFirstChild("HumanoidRootPart")
                if my then e.B.Adornee=hr e.N.Adornee=hr e.H.Adornee=hr e.B.Enabled=EBT.Value e.N.Enabled=ENT.Value e.H.Enabled=EHT.Value
                    local f=e.H:FindFirstChild("Frame",true) if f then local ff=f:FindFirstChild("Frame",true) if ff then ff.Size=UDim2.fromScale(1,hu.Health/hu.MaxHealth) ff.BackgroundColor3=Color3.fromHSV(hu.Health/hu.MaxHealth*0.3,1,1) end end
                else e.B.Enabled=false e.N.Enabled=false e.H.Enabled=false end
            else e.B.Enabled=false e.N.Enabled=false e.H.Enabled=false end
        end)
    end
end
for _,p in ipairs(game.Players:GetPlayers()) do if p~=L then MakeESP(p) end end
game.Players.PlayerAdded:Connect(MakeESP)
game.Players.PlayerRemoving:Connect(function(p) if ESP[p] then pcall(function() for _,v in pairs(ESP[p]) do v:Destroy() end end) ESP[p]=nil end end)
local EC
ET:OnChanged(function() if ET.Value then EC=game:GetService("RunService").RenderStepped:Connect(UpdateESP) else if EC then EC:Disconnect() EC=nil end; for _,e in pairs(ESP) do e.B.Enabled=false e.N.Enabled=false e.H.Enabled=false end end end)

local NC
NT:OnChanged(function() if NT.Value then NC=game:GetService("RunService").Stepped:Connect(function() pcall(function() if L.Character then for _,p in ipairs(L.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end end end) end) else if NC then NC:Disconnect() NC=nil end end end)

local FC,FV,FG
FT:OnChanged(function()
    if FT.Value then
        pcall(function() FV=Instance.new("BodyVelocity") FV.MaxForce=Vector3.new(1e9,1e9,1e9) FV.Velocity=Vector3.zero FV.Parent=L.Character.HumanoidRootPart; FG=Instance.new("BodyGyro") FG.MaxTorque=Vector3.new(1e9,1e9,1e9) FG.P=9000 FG.D=500 FG.Parent=L.Character.HumanoidRootPart end)
        FC=game:GetService("RunService").RenderStepped:Connect(function() pcall(function() local d=Vector3.zero local c=workspace.CurrentCamera.CFrame if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then d+=c.LookVector end if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then d-=c.LookVector end if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then d-=c.RightVector end if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then d+=c.RightVector end if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then d+=Vector3.new(0,1,0) end if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then d-=Vector3.new(0,1,0) end if d.Magnitude>0 then d=d.Unit*FSV.Value end FV.Velocity=d FG.CFrame=c end) end)
    else if FC then FC:Disconnect() FC=nil end pcall(function() FV:Destroy() FG:Destroy() end) FV=nil FG=nil end
end)

local IJC
IJT:OnChanged(function() if IJT.Value then IJC=game:GetService("UserInputService").JumpRequest:Connect(function() pcall(function() if L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end) end) else if IJC then IJC:Disconnect() IJC=nil end end end)

local FBC
FB:OnChanged(function()
    if FB.Value then game.Lighting.Brightness=2 game.Lighting.ClockTime=14 game.Lighting.FogEnd=1e5 game.Lighting.GlobalShadows=false game.Lighting.Ambient=Color3.fromRGB(178,178,178)
    else game.Lighting.Brightness=1 game.Lighting.ClockTime=12 game.Lighting.GlobalShadows=true game.Lighting.Ambient=Color3.fromRGB(128,128,128) end
end)

local UIS = game:GetService("UserInputService")
local menuOpen = true
local locked = false

local function ForceCursor()
    pcall(function() UIS.MouseIconEnabled = true end)
    pcall(function()
        if L.Character and L.Character:FindFirstChild("Humanoid") then
            L.Character.Humanoid.MouseIconEnabled = true
        end
    end)
end

local MobileBtn = Instance.new("ScreenGui")
MobileBtn.Name = "IvoryMobileToggle"
MobileBtn.ResetOnSpawn = false
MobileBtn.DisplayOrder = 1000
pcall(function() MobileBtn.Parent = game:GetService("CoreGui") end)
if not MobileBtn.Parent then MobileBtn.Parent = L:WaitForChild("PlayerGui") end

local btn = Instance.new("TextButton",MobileBtn)
btn.Size = UDim2.fromOffset(50,50)
btn.Position = UDim2.new(0,10,0.5,-25)
btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 20
btn.Text = "I"
btn.BorderSizePixel = 0
btn.AutoButtonColor = true
btn.Draggable = true
btn.Active = true
Instance.new("UICorner",btn).CornerRadius = UDim.new(1,0)
local stroke = Instance.new("UIStroke",btn)
stroke.Color = Color3.fromRGB(100,80,160)
stroke.Thickness = 2

local function UpdateBtn()
    if menuOpen then
        btn.BackgroundColor3 = Color3.fromRGB(90,60,180)
        stroke.Color = Color3.fromRGB(170,130,255)
    else
        btn.BackgroundColor3 = Color3.fromRGB(25,25,25)
        stroke.Color = Color3.fromRGB(100,80,160)
    end
    ForceCursor()
end
UpdateBtn()

local ToggleBtn = MG:AddButton("Toggle UI (RightShift)",function()
    if not locked then menuOpen = not menuOpen; W:Toggle(); UpdateBtn() end
end)
local LockBtn = MG:AddButton("Lock UI",function()
    locked = not locked
    LockBtn:SetText(locked and "Unlock UI" or "Lock UI")
    W:Notify({Title="Ivory",Description=locked and "UI Locked" or "UI Unlocked",Type="Info",Time=2})
end)

btn.MouseButton1Click:Connect(function()
    if not locked then menuOpen = not menuOpen; W:Toggle(); UpdateBtn() end
end)

UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not locked then menuOpen = not menuOpen; W:Toggle(); UpdateBtn() end
    end
end)

S:LoadAutoloadConfig()
ForceCursor()
task.spawn(function() while true do ForceCursor() task.wait(1) end end)
W:Notify({Title="Ivory",Description="Ivory Hub v1.7 loaded! RightShift to toggle.",Type="Success",Time=5})

end -- end if W then
