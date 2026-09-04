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

if not Library then
    warn("[Ivory] UI library failed to load - running features without UI")
end

if Library then

local win = Library.CreateWindow({
    Name = "Ivory",
    Width = 460,
    Height = 360,
})

local MT = win:CreateTab({Name="Home"})
local PT = win:CreateTab({Name="Player"})
local WT = win:CreateTab({Name="World"})
local ST = win:CreateTab({Name="Settings"})

local QK = MT:CreateSection("Quick Actions")
local AB = MT:CreateSection("About")

local TRS = WT:CreateSection("Teleport")
local WTS = WT:CreateSection("Teleport to Mouse")

local WTMG = WTS:CreateSection("Click Teleport")
WTMG:CreateButton({Name="Teleport to Mouse",Callback=function()
    local m = L:GetMouse()
    if m.Hit and L.Character and L.Character:FindFirstChild("HumanoidRootPart") then
        L.Character.HumanoidRootPart.CFrame = m.Hit.CFrame + Vector3.new(0,3,0)
    end
end})

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
            Library.Notify({Title="Ivory",Content="Teleporting to "..display.."!",Type="Success",Duration=3})
        else
            Library.Notify({Title="Ivory",Content=display.." is locked!",Type="Error",Duration=3})
        end
    end
end

local evCol = TRS:CreateSection("Events")
for _, w in ipairs(worldNames) do
    if w.event then
        evCol:CreateButton({Name=w.display, Callback=doTravel(w.key, w.display)})
    end
end
evCol:CreateDivider()
evCol:CreateButton({Name="Halloween Obby → Finish",Callback=function()
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
            Library.Notify({Title="Ivory",Content="Teleported to Halloween Obby finish!",Type="Success",Duration=3})
        end
    end
end})

local regularWorlds = {}
for _, w in ipairs(worldNames) do
    if not w.event then table.insert(regularWorlds, w) end
end

local col1 = TRS:CreateSection("Worlds 1-14")
for i = 1, math.min(14, #regularWorlds) do
    local w = regularWorlds[i]
    col1:CreateButton({Name=w.display, Callback=doTravel(w.key, w.display)})
end

local col2 = TRS:CreateSection("Worlds 15-28")
for i = 15, #regularWorlds do
    local w = regularWorlds[i]
    col2:CreateButton({Name=w.display, Callback=doTravel(w.key, w.display)})
end

local QG = QK:CreateSection("Auto Clicker")
QG:CreateLabel("Spam clicks to build speed before racing:")
QG:CreateDivider()
local ACT = QG:CreateToggle({Name="Auto Clicker",CurrentValue=false})
local MCS = QG:CreateSlider({Name="Click Speed (ms)",Range={10,500},Increment=1,CurrentValue=50})

local autoClickConn = nil
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

local QGR = QK:CreateSection("Auto Win")
QGR:CreateLabel("Teleports through all 12 checkpoints:")
QGR:CreateDivider()
local AWT = QGR:CreateToggle({Name="Auto Win",CurrentValue=false})
local AWV = QGR:CreateSlider({Name="Stage Delay (s)",Range={0.1,2},Increment=0.1,CurrentValue=0.3})
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

local QGP = QK:CreateSection("Auto Farm")
local RBT = QGP:CreateToggle({Name="Auto Rebirth",CurrentValue=false})
RBT:OnChanged(function() if RBT.Value then task.spawn(function() while RBT.Value do I(RB) task.wait(3) end end) end end)

local QGR2 = QK:CreateSection("Quick Rewards")
QGR2:CreateLabel("Claim all rewards with one click:")
QGR2:CreateDivider()
QGR2:CreateButton({Name="Claim All Rewards",Callback=function()
    local c = 0
    if I(FS) then c=c+1 end task.wait(0.2)
    if I(SP) then c=c+1 end task.wait(0.2)
    if I(PC) then c=c+1 end task.wait(0.2)
    if I(DR) then c=c+1 end task.wait(0.2)
    if I(PL) then c=c+1 end task.wait(0.2)
    if I(LR) then c=c+1 end task.wait(0.2)
    if I(FP) then c=c+1 end task.wait(0.2)
    if I(OC) then c=c+1 end task.wait(0.2)
    Library.Notify({Title="Ivory",Content="Claimed "..c.." reward(s)!",Type="Success",Duration=3})
end})
QGR2:CreateDivider()
QGR2:CreateButton({Name="Free Spin",Callback=function() I(FS) end})
QGR2:CreateButton({Name="Spin Wheel",Callback=function() I(SP) end})
QGR2:CreateButton({Name="Playtime Gift",Callback=function() I(PC) end})
QGR2:CreateButton({Name="Daily Reward",Callback=function() I(DR) end})
QGR2:CreateButton({Name="Free Pet",Callback=function() I(FP) end})

local AEG = QK:CreateSection("Quick Eggs")
AEG:CreateLabel(#eggs.." eggs available — pick one to open:")
local SEL = eggs[1] or "Starter01"
local EDD = AEG:CreateDropdown({Name="Select Egg",Options=eggs,CurrentOption=SEL})
EDD:OnChanged(function(v) SEL = v end)
local AOE = AEG:CreateToggle({Name="Auto Open Egg",CurrentValue=false})
local AOS = AEG:CreateSlider({Name="Open Interval (s)",Range={1,10},Increment=1,CurrentValue=2})
AOE:OnChanged(function() if AOE.Value then task.spawn(function() while AOE.Value do I(OE,SEL) task.wait(AOS.Value) end end) end end)
AEG:CreateButton({Name="Refresh Egg List",Callback=function()
    eggs = {}
    local ok2,d2 = pcall(function() return require(P.Shared.Modules.EggsData) end)
    if ok2 and d2 then for name in pairs(d2) do table.insert(eggs,name) end end
    table.sort(eggs) EDD:SetValues(eggs)
    Library.Notify({Title="Ivory",Content=#eggs.." eggs loaded!",Type="Info",Duration=2})
end})

local AG = QK:CreateSection("Auto Pets")
local EBT2 = AG:CreateToggle({Name="Auto Equip Best",CurrentValue=false})
EBT2:OnChanged(function() if EBT2.Value then task.spawn(function() while EBT2.Value do I(EB) task.wait(5) end end) end end)
local ACT2 = AG:CreateToggle({Name="Auto Craft All",CurrentValue=false})
ACT2:OnChanged(function() if ACT2.Value then task.spawn(function() while ACT2.Value do I(CA) task.wait(10) end end) end end)

local AIG = AB:CreateSection("Ivory Hub")
AIG:CreateLabel("Version: 1.7")
AIG:CreateLabel("Game: Race Clicker")
AIG:CreateLabel("User: "..tostring(L.UserId))
AIG:CreateDivider()
AIG:CreateLabel("Press F to search any feature")
AIG:CreateLabel("Press ] to minimize the window")
AIG:CreateLabel("Use the purple I button on mobile")
AIG:CreateDivider()
AIG:CreateButton({Name="Copy Discord Link",Callback=function() if setclipboard then setclipboard("https://discord.gg/MCWYKBdB4E") Library.Notify({Title="Ivory",Content="Discord link copied!",Type="Success",Duration=3}) end end})

local SGR = AB:CreateSection("Live Stats")
local CL = SGR:CreateLabel("Clicks: Loading...")
task.spawn(function() while true do pcall(function() local a=I(GCA) if a then local raw = tostring(a) local num = tonumber((raw:match("[%d%.]+"))) or 0 local suffix = raw:match("([KMBT])") if suffix == "K" then num = num * 1000 elseif suffix == "M" then num = num * 1000000 end CL:SetText("Clicks: "..tostring(num)) end end) task.wait(2) end end)

local MS = PT:CreateSection("Movement")
local VS = PT:CreateSection("Visuals")

local SPG = MS:CreateSection("Walk Speed")
local WST = SPG:CreateToggle({Name="Enable Walk Speed",CurrentValue=false})
local WSV = SPG:CreateSlider({Name="Speed Value",Range={16,500},Increment=1,CurrentValue=16})
WST:OnChanged(function() pcall(function() if WST.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.WalkSpeed=WSV.Value end end) end)
WSV:OnChanged(function() pcall(function() if WST.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.WalkSpeed=WSV.Value end end) end)

local JG = MS:CreateSection("Jump Power")
local JPT = JG:CreateToggle({Name="Enable Jump Power",CurrentValue=false})
local JPV = JG:CreateSlider({Name="Jump Value",Range={50,500},Increment=1,CurrentValue=50})
JPT:OnChanged(function() pcall(function() if JPT.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.JumpPower=JPV.Value end end) end)
JPV:OnChanged(function() pcall(function() if JPT.Value and L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.JumpPower=JPV.Value end end) end)

local EG = MS:CreateSection("Special Abilities")
local NT = EG:CreateToggle({Name="Noclip",CurrentValue=false})
local FT = EG:CreateToggle({Name="Fly",CurrentValue=false})
local FSV = EG:CreateSlider({Name="Fly Speed",Range={50,500},Increment=1,CurrentValue=100})
local IJT = EG:CreateToggle({Name="Infinite Jump",CurrentValue=false})

local EPG = VS:CreateSection("Player ESP")
EPG:CreateLabel("Show other players through walls:")
local ET = EPG:CreateToggle({Name="Enable ESP",CurrentValue=false})
local EBT = EPG:CreateToggle({Name="Boxes",CurrentValue=true})
local ENT = EPG:CreateToggle({Name="Names",CurrentValue=true})
local EHT = EPG:CreateToggle({Name="Health Bars",CurrentValue=true})
local EDT = EPG:CreateToggle({Name="Distance",CurrentValue=true})

local WV = VS:CreateSection("World")
local FB = WV:CreateToggle({Name="Fullbright",CurrentValue=false})

local MG = ST:CreateSection("Menu")
MG:CreateToggle({Name="Toggle Menu",CurrentValue=true})
MG:CreateKeybind({Name="Menu Keybind",CurrentKeybind="RightShift"})
MG:CreateButton({Name="Test Notification",Callback=function() Library.Notify({Title="Ivory",Content="UI is working!",Type="Info",Duration=3}) end})
MG:CreateDivider()
MG:CreateButton({Name="Unload (Destroy All)",Callback=function()
    pcall(function() if NC then NC:Disconnect() end end)
    pcall(function() if EC then EC:Disconnect() end end)
    pcall(function() if FC then FC:Disconnect() end end)
    pcall(function() if IJC then IJC:Disconnect() end end)
    pcall(function() if FV then FV:Destroy() end end)
    pcall(function() if FG then FG:Destroy() end end)
    pcall(function() if L.Character and L.Character:FindFirstChild("Humanoid") then L.Character.Humanoid.WalkSpeed=16 L.Character.Humanoid.JumpPower=50 end end)
    pcall(function() GUI:Destroy() end)
    pcall(function() MobileBtn:Destroy() end)
    pcall(function() Library:Toggle() end)
end})

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

local ToggleBtn = MG:CreateButton({Name="Toggle UI (RightShift)",Callback=function()
    if not locked then menuOpen = not menuOpen; Library:Toggle(); UpdateBtn() end
end})
local LockBtn = MG:CreateButton({Name="Lock UI",Callback=function()
    locked = not locked
    Library.Notify({Title="Ivory",Content=locked and "UI Locked" or "UI Unlocked",Type="Info",Duration=2})
end})

btn.MouseButton1Click:Connect(function()
    if not locked then menuOpen = not menuOpen; Library:Toggle(); UpdateBtn() end
end)

UIS.InputBegan:Connect(function(input,gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        if not locked then menuOpen = not menuOpen; Library:Toggle(); UpdateBtn() end
    end
end)

ForceCursor()
task.spawn(function() while true do ForceCursor() task.wait(1) end end)
Library.Notify({Title="Ivory",Content="Ivory Hub v1.7 loaded! RightShift to toggle.",Type="Success",Duration=5})

end -- end if Library