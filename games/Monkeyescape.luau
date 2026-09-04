-- +1 Speed Monkey Escape | Ivory Hub | Hybrid: fixed loop + all old features
-- Loop: treadmill (best unlocked, no Robux) -> wins (best farmable, yellow only) -> tails (no Stop, fix buy/equip) -> rebirth (just fire) + all GAME_FEATURES

local LIB_SRC = getgenv()._IvoryLibSrc
if not LIB_SRC then
	local ok, src = pcall(function()
		return request({
			Url = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua",
			Method = "GET"
		}).Body
	end)
	if ok then LIB_SRC = src end
end
local Library = loadstring(LIB_SRC)()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local CollectionService = game:GetService("CollectionService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")

local isLobby = false
pcall(function() isLobby = workspace:FindFirstChild("Lobby") ~= nil end)

local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 460,
    Height = 360,
    FuzzySearch = true,
    SearchValues = true,
    Minimizable = true,
})

-- Embedded configs (avoid Plugin require)
local UpgradesCfg = {
    {WinsRequirement=0, Multi=1, Skin="Basic"},
    {Multi=2, Skin="Grey", WinsRequirement=3},
    {Multi=4, Skin="Tiger", WinsRequirement=15},
    {Multi=8, Skin="Curly", WinsRequirement=100},
    {Multi=16, Skin="Rainbow", WinsRequirement=500},
    {Multi=32, Skin="Golden", WinsRequirement=2500},
    {Multi=64, Skin="Magma", WinsRequirement=15000},
    {Multi=128, Skin="Frozen", WinsRequirement=50000},
    {Multi=256, Skin="Devil", WinsRequirement=250000},
    {Multi=512, Skin="Night", WinsRequirement=1000000},
    {Multi=1000, Skin="Inferno", WinsRequirement=1000000},
    {Multi=2000, Skin="Verdant", WinsRequirement=5000000},
    {Multi=4000, Skin="Abyss", WinsRequirement=25000000},
    {Multi=8000, Skin="Arcane", WinsRequirement=100000000},
    {Multi=16000, Skin="Divine", WinsRequirement=500000000},
    {Multi=32000, Skin="Crimson", WinsRequirement=3000000000},
}
local MainCfg = {WorldRebirthsRequired={World2=8,World3=16,World4=24,World5=32}, RebirthLevels={15,25,40,60,80,100,125,150,165,175,190,210,230,250,275,300,315,325,340,360,380,400,425,450,465,475,490,510,530,550,575,600,615,625,640,660,680}, MaxLevel=690, StageWins={World1={1,5,20,100,500,3000,15000,50000,200000}, World2={1000000,5000000,25000000,100000000,600000000,3000000000,25000000000,150000000000,1000000000000}, World3={5000000000000,20000000000000,75000000000000,250000000000000,1000000000000000,5000000000000000,25000000000000000,100000000000000000,400000000000000000}, World4={2000000000000000000,10000000000000000000,75000000000000000000,350000000000000000000,2000000000000000000000,10000000000000000000000,50000000000000000000000,250000000000000000000000,1000000000000000000000000}, World5={5000000000000000000000000,25000000000000000000000000,75000000000000000000000000,250000000000000000000000000,1000000000000000000000000000,5000000000000000000000000000,20000000000000000000000000000,80000000000000000000000000000,350000000000000000000000000000}}}
local TreadmillCfg = {Multis={Reward=1.5, Golden=3, Diamond=9, Galaxy=25, Emerald=100, Void=100, Celestial=1000, Sunken=2, Quantum=10, Basic=1}}
local Formatter = {Format=function(v) return tostring(v) end}
local BigNum = {
    GreaterEqual=function(a,b)
        local av = 0
        if a and a:FindFirstChild("Digits") then av = tonumber(a.Digits.Value) or 0 elseif a and a:FindFirstChild("Value") then av = tonumber(a.Value) or 0 elseif a and a.Value then av = tonumber(a.Value) or 0 end
        local bv = tonumber(b) or 0
        return av >= bv
    end,
    OnChanged=function(a,cb)
        if a and a.Changed then a.Changed:Connect(function() cb() end) end
        if a and a:FindFirstChild("Digits") and a.Digits.Changed then a.Digits.Changed:Connect(function() cb() end) end
    end
}

local Tabs = {
    Main = Window:CreateTab({Name="Main"}),
    Farming = Window:CreateTab({Name="Farming"}),
    Inventory = Window:CreateTab({Name="Inventory"}),
    Rebirth = Window:CreateTab({Name="Rebirth"}),
    Settings = Window:CreateTab({Name="Settings"}),
}
local FarmTrain = Tabs.Farming:CreateSection("Train")
local FarmWins = Tabs.Farming:CreateSection("Wins")
local FarmCollect = Tabs.Farming:CreateSection("Collecting")
local FarmRace = Tabs.Farming:CreateSection("Race")
local FarmRewards = Tabs.Farming:CreateSection("Rewards")

local InvTails = Tabs.Inventory:CreateSection("Tails")
local InvTrails = Tabs.Inventory:CreateSection("Trails")
local InvAuras = Tabs.Inventory:CreateSection("Auras")
local InvCharmsBuy = Tabs.Inventory:CreateSection("Charms - Shop")
local InvCharmsManage = Tabs.Inventory:CreateSection("Charms - Manage")
local InvConsumables = Tabs.Inventory:CreateSection("Consumables")

local RebirthAuto = Tabs.Rebirth:CreateSection("Auto")
local RebirthInfo = Tabs.Rebirth:CreateSection("Info")

local function safeFire(remote,...)
    if not remote then return false end
    local ok,err
    local cn = remote.ClassName
    if cn=="RemoteEvent" then ok,err = pcall(function(...) remote:FireServer(...) end, ...)
    elseif cn=="RemoteFunction" then ok,err = pcall(function(...) return remote:InvokeServer(...) end, ...)
    else ok,err = pcall(function(...) remote:FireServer(...) end, ...) end
    if not ok then warn("[FireFailed] "..remote.Name..": "..tostring(err)) end
    return ok
end
local function createIntervalSlider(section,id,text,def)
    return section:CreateSlider({Name=text, Range={0.01, 10}, Increment=0.01, CurrentValue=def or 0.5})
end
local Loops={}
local function runLoop(id,toggleId,intervalId,fn)
    if Loops[id] then task.cancel(Loops[id]); Loops[id]=nil end
    Loops[id]=task.spawn(function()
        while Toggles[toggleId] and Toggles[toggleId].Value do
            local ok,err=pcall(fn)
            if not ok then warn("["..id.."]",err) end
            local iv=0.5
            if Options[intervalId] then iv=Options[intervalId].Value end
            task.wait(iv)
        end
        Loops[id]=nil
    end)
end
local function stopLoop(id) if Loops[id] then task.cancel(Loops[id]); Loops[id]=nil end end
local AntiAFKConn
local function setAntiAFK(s)
    if s then
        if AntiAFKConn then AntiAFKConn:Disconnect() end
        AntiAFKConn=LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
        end)
    else
        if AntiAFKConn then AntiAFKConn:Disconnect(); AntiAFKConn=nil end
    end
end

-- MAIN
do
    local L=Tabs.Main:CreateSection("Info")
    L:CreateLabel("PlaceId: "..tostring(game.PlaceId))
    L:CreateDivider()
    local start=tick()
    L:CreateLabel("Session: 00:00:00")
    task.spawn(function()
        while true do task.wait(1)
            local e=math.floor(tick()-start)
            local h=math.floor(e/3600); local m=math.floor((e%3600)/60); local s=e%60
            if Options.SessionTime then Options.SessionTime:SetText(string.format("Session: %02d:%02d:%02d",h,m,s)) end
        end
    end)
    L:CreateLabel("Train -> Wins (yellow) -> Rebirth -> Tails")
    L:CreateDivider()
    L:CreateButton({Name="JOIN DISCORD FOR DUPE", Callback=function()
        if setclipboard then setclipboard("https://discord.gg/ivory") end
        Library.Notify({Title="Ivory", Content="Discord link copied!", Duration=3})
    end})
    local R=Tabs.Main:CreateSection("Quick Status")
    local function upd() return string.format("Lvl %d | Rebirths %d | Wins %s", Data.Level.Value, Data.Rebirths.Value, Data.Wins:FindFirstChild("Digits") and Data.Wins.Digits.Value or "?") end
    R:CreateLabel(upd())
    Data.Level.Changed:Connect(function() end)
end

-- FARMING > TRAIN (best unlocked, no Robux)
do
    local G=FarmTrain
    local TreadmillTypes={"Basic","Golden","Diamond","Galaxy","Void","Celestial","Sunken","Quantum","Reward","Emerald"}
    pcall(function()
        TreadmillTypes={}
        for k,_ in pairs(TreadmillCfg.Multis) do table.insert(TreadmillTypes,k) end
        table.sort(TreadmillTypes)
    end)
    G:CreateDropdown({Name="Manual Treadmill (if not Best)", Options=TreadmillTypes, CurrentOption=1})
    G:CreateToggle({Name="Auto Train on Treadmill", CurrentValue=false})
    G:CreateSlider({Name="Interval", Range={5, 10}, Increment=0.1, CurrentValue=5})
    G:CreateToggle({Name="Use Best UNLOCKED (no Robux)", CurrentValue=true})
    G:CreateLabel("Checks CollectionService Tagged 'Treadmill' + 'TreadmillLabel' + Data.Passes. Free = Basic, Sunken, Quantum etc")

    local function isTreadmillUnlocked(ttype)
        if ttype=="Sunken" then local s=Data:FindFirstChild("CollectedShards") if not s or #s:GetChildren()<9 then return false end end
        if ttype=="Quantum" then return false end
        local paidList={Golden=true, Diamond=true, Galaxy=true, Void=true, Celestial=true}
        if not paidList[ttype] then return true end
        return Data.Passes:FindFirstChild(ttype) ~= nil
    end
    local function getTreadmillPart(preferred)
        local best=nil; local bestMulti=-1
        for _,part in CollectionService:GetTagged("Treadmill") do
            if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
                local ttype = part:GetAttribute("Type") or part.Name
                if not isTreadmillUnlocked(ttype) then continue end
                local multi = TreadmillCfg.Multis[ttype] or 0
                if preferred and ttype:lower()==preferred:lower() then return part end
                if not preferred then
                    if multi > bestMulti then bestMulti=multi; best=part end
                end
            end
        end
        if best then return best end
        for _,part in CollectionService:GetTagged("Treadmill") do
            if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
                local ttype = part:GetAttribute("Type") or part.Name
                if isTreadmillUnlocked(ttype) then return part end
            end
        end
        return nil
    end

    local function startTrain()
        runLoop("AutoTrain","AutoTrain","AutoTrain_Interval",function()
            local useBest = Toggles.AutoTrain_Best and Toggles.AutoTrain_Best.Value
            local sel = Options.TrainTreadmill_Select and Options.TrainTreadmill_Select.Value or "Basic"
            local part = getTreadmillPart(if useBest then nil else sel)
            if not part then return end
            local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            pcall(function() firetouchinterest(hrp, part, 0) end)
            hrp.CFrame = part.CFrame + Vector3.new(0,5,0)
            task.wait(0.15)
            pcall(function() firetouchinterest(hrp, part, 1) end)
        end)
    end
    Toggles.AutoTrain:OnChanged(function() if Toggles.AutoTrain.Value then startTrain() else stopLoop("AutoTrain") end end)
    if Toggles.AutoTrain_Best then Toggles.AutoTrain_Best:OnChanged(function() if Toggles.AutoTrain.Value then stopLoop("AutoTrain"); task.wait(0.2); startTrain() end end) end

    local G2=FarmTrain
    G2:CreateLabel("SpeedMulti: "..tostring(Data.SpeedMulti.Value))
    G2:CreateLabel("Level: "..tostring(Data.Level.Value))
    G2:CreateButton({Name="TP to Best Unlocked Treadmill", Callback=function()
        local p=getTreadmillPart(nil)
        if p and LocalPlayer.Character then LocalPlayer.Character.HumanoidRootPart.CFrame = p.CFrame + Vector3.new(0,5,0) end
    end})
    G2:CreateButton({Name="List Treadmills + Unlock", Callback=function()
        local s=""
        for _,p in CollectionService:GetTagged("Treadmill") do
            local t=p:GetAttribute("Type") or p.Name
            local multi=TreadmillCfg.Multis[t] or 0
            local unlocked=isTreadmillUnlocked(t)
            s=s..t.." multi "..multi.." unlocked "..tostring(unlocked).."\n"
        end
        print(s); Library.Notify({Title="Ivory", Content=s:sub(1,300), Duration=5})
    end})
end

-- FARMING > WINS (map all worlds, best farmable)
do
    local G=FarmWins
    G:CreateToggle({Name="Auto Farm Wins (Yellow Only)", CurrentValue=false})
    createIntervalSlider(G, "AutoWins_Interval", "Interval", 0.6)
    local winOptions={}
    for world, stages in pairs(MainCfg.StageWins) do
        for i, wins in ipairs(stages) do
            table.insert(winOptions, string.format("%s Stage%d (%s wins)", world, i, Formatter.Format(wins)))
        end
    end
    table.sort(winOptions)
    local FixedWinPos={World1={[1]=Vector3.new(-682.16,23.04,-255.05),[2]=Vector3.new(-935.66,23.04,-255.05),[3]=Vector3.new(-1214.16,23.04,-255.05),[4]=Vector3.new(-1569.16,23.04,-255.05),[5]=Vector3.new(-2183.16,118.04,-255.05),[6]=Vector3.new(-3046.41,118.04,-255.05),[7]=Vector3.new(-4318.16,277.04,-255.05),[8]=Vector3.new(-6158.66,277.04,-254.66),[9]=Vector3.new(-9459,399,-255)}, World2={[1]=Vector3.new(-735.16,23.04,-2565.05),[2]=Vector3.new(-1095.01,38.04,-2565.05),[3]=Vector3.new(-1880.16,-51.96,-2565.05),[4]=Vector3.new(-2400.16,55.34,-2565.05),[5]=Vector3.new(-3247.16,55.34,-2565.05),[6]=Vector3.new(-3605.38,55.34,-3697.49),[7]=Vector3.new(-3605.38,55.34,-4607.49),[8]=Vector3.new(-3605.38,55.34,-5827.49),[9]=Vector3.new(-3603,164,-9379)}, World3={[1]=Vector3.new(-684.16,22.54,2740.95),[2]=Vector3.new(-953.63,22.54,2740.95),[3]=Vector3.new(-1286.63,22.54,2740.95),[4]=Vector3.new(-1684.63,22.54,2740.95),[5]=Vector3.new(-2240.63,22.54,2740.95),[6]=Vector3.new(-2560.63,278.54,2740.95),[7]=Vector3.new(-4208.63,278.54,2740.95),[8]=Vector3.new(-5420.63,278.54,2740.95),[9]=Vector3.new(-8077.63,278.54,2740.95)}, World4={[1]=Vector3.new(-684.16,22.54,5740.95),[2]=Vector3.new(-892.16,22.54,5740.95),[3]=Vector3.new(-1206.66,22.54,5740.95),[4]=Vector3.new(-1592.66,22.54,5740.95),[5]=Vector3.new(-1852.06,172.54,5740.95),[6]=Vector3.new(-2718.06,172.54,5740.95),[7]=Vector3.new(-3933.06,172.54,5740.95),[8]=Vector3.new(-5663.06,17.50,5740.95),[9]=Vector3.new(-7760.11,17.50,5740.95)}, World5={[1]=Vector3.new(-684.16,22.54,7561.95),[2]=Vector3.new(-1005.16,22.54,7561.95),[3]=Vector3.new(-1333.16,22.54,7561.95),[4]=Vector3.new(-1778.15,103.54,7444.95),[5]=Vector3.new(-2369.24,103.54,7444.95),[6]=Vector3.new(-2828.45,283.54,7801.31)}}
    G:CreateDropdown({Name="Manual Win Pad", Options=winOptions, CurrentOption=1})
    G:CreateDropdown({Name="World Filter", Options={"World1","World2","World3","World4","World5","All"}, CurrentOption=6})
    G:CreateLabel("Yellow = NormalWin.Button New Yeller. Red VipWin skipped.")

    local function parseWinOption(opt)
        local world, stage = opt:match("(%w+) Stage(%d+)")
        return world, tonumber(stage)
    end
    local function isWorldUnlocked(world)
        local num = tonumber(world:match("World(%d+)") or 0)
        if num==1 then return true end
        local req = (MainCfg.WorldRebirthsRequired :: any)[world] or (MainCfg.WorldRebirthsRequired :: any)["World"..num]
        if not req then return true end
        return Data.Rebirths.Value >= req
    end
    local function getAllNormalWins(filterWorld)
        local list={}
        for _,m in workspace:GetDescendants() do
            if m.Name=="NormalWin" and m:IsA("Model") then
                local btn=m:FindFirstChild("Button")
                if btn and btn:IsA("BasePart") and btn.BrickColor.Name=="New Yeller" then
                    local path=m:GetFullName()
                    local world = path:match("World%d") or "World1"
                    if filterWorld and filterWorld~="All" and world ~= filterWorld then continue end
                    local stage = 1
                    local s = path:match("Stage(%d+)")
                    if s then stage=tonumber(s) end
                    local winsVal = 0
                    if MainCfg.StageWins[world] and MainCfg.StageWins[world][stage] then winsVal=MainCfg.StageWins[world][stage] end
                    table.insert(list, {part=btn, world=world, stage=stage, wins=winsVal, model=m})
                end
            end
        end
        for world, stages in pairs(MainCfg.StageWins) do
            if filterWorld and filterWorld~="All" and world ~= filterWorld then continue end
            if not isWorldUnlocked(world) then continue end
            for stage, wins in ipairs(stages) do
                local found=false
                for _,e in ipairs(list) do if e.world==world and e.stage==stage then found=true break end end
                if not found then
                    local worldFolder = workspace:FindFirstChild("Map") and workspace:FindFirstChild("Map") and workspace:FindFirstChild("Map"):FindFirstChild(world)
                    local stagesFolder = worldFolder and worldFolder:FindFirstChild("Stages")
                    local stageFolder = stagesFolder and stagesFolder:FindFirstChild("Stage"..stage)
                    if stageFolder then
                        local cand=nil
                        local main = stageFolder:FindFirstChild("Main")
                        if main then
                            local se = main:FindFirstChild("StageEnd")
                            if se then
                                if se:IsA("Model") then cand=se:FindFirstChild("Button") or se:FindFirstChildWhichIsA("BasePart", true) end
                                if not cand and se:IsA("BasePart") then cand=se end
                            end
                        end
                        if not cand then
                            for _,d in stageFolder:GetDescendants() do
                                if d:IsA("BasePart") and d.BrickColor.Name=="New Yeller" and d.Name=="Button" then cand=d break end
                            end
                        end
                        if not cand then cand=stageFolder:FindFirstChildWhichIsA("BasePart", true) end
                        if cand then table.insert(list, {part=cand, world=world, stage=stage, wins=wins, model=stageFolder, fallback=true}) end
                    end
                end
            end
        end
        return list
    end
    local function getBestFixed()
        local best=nil; local bestWins=-1
        for world, stages in pairs(FixedWinPos) do
            if not isWorldUnlocked(world) then continue end
            for stage, pos in pairs(stages) do
                local wins = MainCfg.StageWins[world] and MainCfg.StageWins[world][stage] or 0
                if wins > bestWins then bestWins=wins; best={world=world, stage=stage, wins=wins, pos=pos} end
            end
        end
        if not best then return nil end
        return {part={CFrame=CFrame.new(best.pos), Position=best.pos, BrickColor={Name="New Yeller"}, Name="Button", GetFullName=function() return "Fixed:"..best.world..best.stage end}, world=best.world, stage=best.stage, wins=best.wins, isFixed=true}
    end
    local function getBestFarmable()
        local fixed=getBestFixed()
        if fixed then return fixed end
        local best=nil
        local bestWins=-1
        local list=getAllNormalWins("All")
        for _,e in ipairs(list) do
            if e.fallback then continue end
            if not isWorldUnlocked(e.world) then continue end
            if e.wins > bestWins then bestWins=e.wins; best=e end
        end
        if not best then
            for _,e in ipairs(list) do
                if not isWorldUnlocked(e.world) then continue end
                if e.wins > bestWins then bestWins=e.wins; best=e end
            end
        end
        if not best and #list>0 then best=list[#list] end
        return best
    end
    local function getManualTarget()
        local opt = Options.AutoWins_Manual and Options.AutoWins_Manual.Value or winOptions[1]
        local world,stage = parseWinOption(opt)
        if not world then return nil end
        if FixedWinPos[world] and FixedWinPos[world][stage] then
            local pos=FixedWinPos[world][stage]
            local bestPart=nil; local bestDist=80
            for _,v in workspace:GetDescendants() do
                if v:IsA("BasePart") and v.BrickColor.Name=="New Yeller" and v.Name=="Button" then
                    local d=(v.Position - pos).Magnitude
                    if d < bestDist then bestDist=d; bestPart=v end
                end
            end
            if bestPart then
                return {part=bestPart, world=world, stage=stage, wins=MainCfg.StageWins[world][stage] or 0, model=bestPart.Parent}
            else
                return {part={CFrame=CFrame.new(pos), Position=pos, BrickColor={Name="New Yeller"}, Name="Button", GetFullName=function() return "Fixed:"..world..stage end}, world=world, stage=stage, wins=MainCfg.StageWins[world][stage] or 0, isFixed=true}
            end
        end
        for _,e in getAllNormalWins(world) do
            if e.world==world and e.stage==stage then return e end
        end
        return nil
    end

    Toggles.AutoWins:OnChanged(function()
        if Toggles.AutoWins.Value then
            runLoop("AutoWins","AutoWins","AutoWins_Interval",function()
                local targetEntry = getManualTarget()
                if not targetEntry or not targetEntry.part then return end
                local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                if targetEntry.isFixed then
                    local pos = FixedWinPos[targetEntry.world] and FixedWinPos[targetEntry.world][targetEntry.stage] or targetEntry.part.Position
                    hrp.CFrame = CFrame.new(pos + Vector3.new(0,5,0))
                    local bestPart=nil; local bestDist=80
                    for _,v in workspace:GetDescendants() do
                        if v:IsA("BasePart") and v.BrickColor.Name=="New Yeller" and v.Name=="Button" then
                            local d=(v.Position - pos).Magnitude
                            if d < bestDist then bestDist=d; bestPart=v end
                        end
                    end
                    if bestPart then
                        pcall(function() firetouchinterest(hrp, bestPart, 0) task.wait(0.1) firetouchinterest(hrp, bestPart, 1) end)
                    else
                        pcall(function() firetouchinterest(hrp, targetEntry.part, 0) task.wait(0.1) firetouchinterest(hrp, targetEntry.part, 1) end)
                    end
                else
                    hrp.CFrame = targetEntry.part.CFrame + Vector3.new(0,3,0)
                    pcall(function()
                        firetouchinterest(hrp, targetEntry.part, 0)
                        task.wait(0.1)
                        firetouchinterest(hrp, targetEntry.part, 1)
                    end)
                end
                task.wait(0.2)
            end)
        else stopLoop("AutoWins") end
    end)

    local G2=FarmWins
    G2:CreateButton({Name="List All NormalWins", Callback=function()
        local list=getAllNormalWins("All")
        local s=""
        for _,e in ipairs(list) do s=s..e.world.." Stage"..e.stage.." "..Formatter.Format(e.wins)..(isWorldUnlocked(e.world) and " [unlocked]" or " [locked]").."\n" end
        print(s)
        Library.Notify({Title="Ivory", Content="See console F9", Duration=3})
    end})
    G2:CreateButton({Name="Show World Requirements", Callback=function()
        local s=""
        for w,req in pairs(MainCfg.WorldRebirthsRequired) do s=s..w.." needs "..req.." rebirths\n" end
        Library.Notify({Title="Ivory", Content=s, Duration=4})
    end})
end

-- FARMING > COLLECTING (Bananas + Shards)
do
    local G=FarmCollect
    G:CreateToggle({Name="Auto Collect Bananas", CurrentValue=false})
    createIntervalSlider(G, "AutoCollectBananas_Interval", "Interval", 0.5)
    G:CreateDropdown({Name="Auto Collect Sunken Shards", Options={"Shard1","Shard2","Shard3","Shard4","Shard5","Shard6","Shard7","Shard8","Shard9"}, CurrentOption=1})
    G:CreateToggle({Name="Auto Collect Sunken Shards", CurrentValue=false})
    createIntervalSlider(G, "AutoCollectShards_Interval", "Interval", 0.8)

    Toggles.AutoCollectBananas:OnChanged(function()
        if Toggles.AutoCollectBananas.Value then
            runLoop("AutoCollectBananas","AutoCollectBananas","AutoCollectBananas_Interval",function()
                for _,v in workspace:GetDescendants() do
                    if v.Name:lower():find("banana") and v:IsA("BasePart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v, 0)
                            task.wait(0.05)
                            firetouchinterest(LocalPlayer.Character.HumanoidRootPart, v, 1)
                        end)
                    end
                end
                for _,p in workspace:GetDescendants() do
                    if p:IsA("ProximityPrompt") and p.ObjectText:lower():find("banana") then pcall(function() fireproximityprompt(p) end) end
                end
            end)
        else stopLoop("AutoCollectBananas") end
    end)
    Toggles.AutoCollectShards:OnChanged(function()
        if Toggles.AutoCollectShards.Value then
            runLoop("AutoCollectShards","AutoCollectShards","AutoCollectShards_Interval",function()
                local sel = Options.AutoCollectShards_Select and Options.AutoCollectShards_Select.Value or {}
                local toCollect={}
                if type(sel)=="table" then for k,v in pairs(sel) do if v then table.insert(toCollect,k) end end end
                if #toCollect==0 then toCollect={"Shard1","Shard2","Shard3","Shard4","Shard5","Shard6","Shard7","Shard8","Shard9"} end
                for _,sh in ipairs(toCollect) do if Remotes:FindFirstChild("CollectShard") then safeFire(Remotes.CollectShard, sh) end end
            end)
        else stopLoop("AutoCollectShards") end
    end)
end

-- FARMING > RACE
do
    local G=FarmRace
    G:CreateToggle({Name="Auto Join Race", CurrentValue=false})
    createIntervalSlider(G, "AutoJoinRace_Interval", "Interval", 2)
    Toggles.AutoJoinRace:OnChanged(function()
        if Toggles.AutoJoinRace.Value then
            runLoop("AutoJoinRace","AutoJoinRace","AutoJoinRace_Interval",function()
                if Remotes:FindFirstChild("JoinRace") then safeFire(Remotes.JoinRace) end
            end)
        else stopLoop("AutoJoinRace") end
    end)
end

-- FARMING > REWARDS (claims + redeem + spin etc)
do
    local G=FarmRewards
    G:CreateToggle({Name="Auto Claim Free Reward", CurrentValue=false})
    createIntervalSlider(G, "AutoClaimFreeReward_Interval", "Interval", 5)
    G:CreateToggle({Name="Auto Claim Streak Reward", CurrentValue=false})
    createIntervalSlider(G, "AutoClaimStreakReward_Interval", "Interval", 5)
    G:CreateToggle({Name="Auto Claim Offline Earnings", CurrentValue=false})
    createIntervalSlider(G, "AutoClaimOfflineEarnings_Interval", "Interval", 5)
    G:CreateToggle({Name="Auto Redeem Code", CurrentValue=false})
    createIntervalSlider(G, "AutoRedeemCode_Interval", "Interval", 3)
    G:CreateToggle({Name="Auto Redeem Discord Code", CurrentValue=false})
    createIntervalSlider(G, "AutoRedeemDiscordCode_Interval", "Interval", 3)

    local map={AutoClaimFreeReward="ClaimFreeReward", AutoClaimStreakReward="ClaimStreakReward", AutoClaimOfflineEarnings="ClaimOfflineEarnings"}
    for tog,rem in pairs(map) do
        Toggles[tog]:OnChanged(function()
            if Toggles[tog].Value then
                runLoop(tog,tog,tog.."_Interval",function() if Remotes:FindFirstChild(rem) then safeFire(Remotes[rem]) end end)
            else stopLoop(tog) end
        end)
    end
    Toggles.AutoRedeemCode:OnChanged(function()
        if Toggles.AutoRedeemCode.Value then
            runLoop("AutoRedeemCode","AutoRedeemCode","AutoRedeemCode_Interval",function()
                local codes={"RELEASE","MONKEY","SPEED","WINS"}
                for _,code in ipairs(codes) do if Remotes:FindFirstChild("RedeemCode") then safeFire(Remotes.RedeemCode, code) end end
            end)
        else stopLoop("AutoRedeemCode") end
    end)
    Toggles.AutoRedeemDiscordCode:OnChanged(function()
        if Toggles.AutoRedeemDiscordCode.Value then
            runLoop("AutoRedeemDiscordCode","AutoRedeemDiscordCode","AutoRedeemDiscordCode_Interval",function()
                if Remotes:FindFirstChild("RedeemDiscordCode") then safeFire(Remotes.RedeemDiscordCode) end
            end)
        else stopLoop("AutoRedeemDiscordCode") end
    end)

    local G2=FarmRewards
    G2:CreateToggle({Name="Auto Spin Wheel", CurrentValue=false})
    createIntervalSlider(G2, "AutoSpinWheel_Interval", "Interval", 3)
    G2:CreateToggle({Name="Auto Open Skull Chest", CurrentValue=false})
    createIntervalSlider(G2, "AutoOpenSkullChest_Interval", "Interval", 1)
    G2:CreateToggle({Name="Auto Open Secret Chest", CurrentValue=false})
    createIntervalSlider(G2, "AutoOpenSecretChest_Interval", "Interval", 1)
    G2:CreateToggle({Name="Auto Enter Secret Door", CurrentValue=false})
    createIntervalSlider(G2, "AutoEnterSecretDoor_Interval", "Interval", 2)
    G2:CreateToggle({Name="Auto Set Gift Target", CurrentValue=false})
    createIntervalSlider(G2, "AutoSetGiftTarget_Interval", "Interval", 5)

    Toggles.AutoSpinWheel:OnChanged(function()
        if Toggles.AutoSpinWheel.Value then
            runLoop("AutoSpinWheel","AutoSpinWheel","AutoSpinWheel_Interval",function()
                if Remotes:FindFirstChild("SpawnWheel") then safeFire(Remotes.SpawnWheel) end
                if Remotes:FindFirstChild("PlayLootBoxSpin") then safeFire(Remotes.PlayLootBoxSpin) end
            end)
        else stopLoop("AutoSpinWheel") end
    end)
    Toggles.AutoOpenSkullChest:OnChanged(function()
        if Toggles.AutoOpenSkullChest.Value then
            runLoop("AutoOpenSkullChest","AutoOpenSkullChest","AutoOpenSkullChest_Interval",function()
                if Remotes:FindFirstChild("OpenSkullChest") then safeFire(Remotes.OpenSkullChest, 1) end
            end)
        else stopLoop("AutoOpenSkullChest") end
    end)
    Toggles.AutoOpenSecretChest:OnChanged(function()
        if Toggles.AutoOpenSecretChest.Value then
            runLoop("AutoOpenSecretChest","AutoOpenSecretChest","AutoOpenSecretChest_Interval",function()
                if Remotes:FindFirstChild("OpenSecretChest") then safeFire(Remotes.OpenSecretChest, 1) end
            end)
        else stopLoop("AutoOpenSecretChest") end
    end)
    Toggles.AutoEnterSecretDoor:OnChanged(function()
        if Toggles.AutoEnterSecretDoor.Value then
            runLoop("AutoEnterSecretDoor","AutoEnterSecretDoor","AutoEnterSecretDoor_Interval",function()
                if Remotes:FindFirstChild("SecretDoorRequestEnter") then safeFire(Remotes.SecretDoorRequestEnter) end
            end)
        else stopLoop("AutoEnterSecretDoor") end
    end)
    Toggles.AutoSetGiftTarget:OnChanged(function()
        if Toggles.AutoSetGiftTarget.Value then
            runLoop("AutoSetGiftTarget","AutoSetGiftTarget","AutoSetGiftTarget_Interval",function()
                if Remotes:FindFirstChild("SetGiftTarget") then safeFire(Remotes.SetGiftTarget, LocalPlayer.Name) end
            end)
        else stopLoop("AutoSetGiftTarget") end
    end)
end

-- INVENTORY > TAILS (fixed, no Stop, buy + equip best)
do
    local G=InvTails
    G:CreateToggle({Name="Auto Buy Best Tail", CurrentValue=false})
    createIntervalSlider(G, "AutoBuyTails_Interval", "Interval", 1)
    G:CreateToggle({Name="Auto Equip Best Owned Tail", CurrentValue=false})
    createIntervalSlider(G, "AutoEquipBestTails_Interval", "Interval", 1)
    G:CreateLabel("No Stop dropdown. Uses SelectUpgrade remote + UnlockedUpgrades check.")

    local function getBestAffordableLocked()
        local BN=nil
        pcall(function() BN=require(game.ReplicatedStorage.Util.BigNum) end)
        if not BN then BN=BigNum end
        local best=nil; local bestReq=-1
        for idx,cfg in ipairs(UpgradesCfg) do
            local req=cfg and cfg.WinsRequirement
            if cfg and not Data.UnlockedUpgrades:FindFirstChild(tostring(idx)) and req then
                local affordable=false
                if BN and BN.GreaterEqual then
                    affordable=BN.GreaterEqual(Data.Wins, req)
                else
                    affordable=BigNum.GreaterEqual(Data.Wins, req)
                end
                if affordable and req > bestReq then bestReq=req; best=idx end
            end
        end
        return best
    end
    local function getBestAffordable()
        local best=Data.SelectedUpgrade.Value
        local bestReq=-1
        for idx,cfg in ipairs(UpgradesCfg) do
            if cfg and cfg.WinsRequirement and BigNum.GreaterEqual(Data.Wins, cfg.WinsRequirement) then
                if cfg.WinsRequirement > bestReq then bestReq=cfg.WinsRequirement; best=idx end
            end
        end
        return best
    end
    local function getBestOwned()
        local best=1
        local maxIdx=1
        for _,v in Data.UnlockedUpgrades:GetChildren() do
            local n=tonumber(v.Name)
            if n and n>maxIdx then maxIdx=n end
        end
        return maxIdx
    end

    Toggles.AutoBuyTails:OnChanged(function()
        if Toggles.AutoBuyTails.Value then
            runLoop("AutoBuyTails","AutoBuyTails","AutoBuyTails_Interval",function()
                local best=getBestAffordableLocked()
                if best and best ~= Data.SelectedUpgrade.Value then
                    safeFire(Remotes.SelectUpgrade, best)
                    for _,btn in CollectionService:GetTagged("UpgradeButton") do
                        if btn:GetAttribute("Upgrade")==best then
                            local part=btn:FindFirstChild("Button")
                            if part and LocalPlayer.Character then
                                local hrp=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    pcall(function()
                                        firetouchinterest(hrp, part, 0)
                                        task.wait(0.05)
                                        firetouchinterest(hrp, part, 1)
                                    end)
                                end
                            end
                            break
                        end
                    end
                end
            end)
        else stopLoop("AutoBuyTails") end
    end)
    Toggles.AutoEquipBestTails:OnChanged(function()
        if Toggles.AutoEquipBestTails.Value then
            runLoop("AutoEquipBestTails","AutoEquipBestTails","AutoEquipBestTails_Interval",function()
                local best=getBestOwned()
                if best ~= Data.SelectedUpgrade.Value then safeFire(Remotes.SelectUpgrade, best) end
            end)
        else stopLoop("AutoEquipBestTails") end
    end)

    local G2=InvTails
    G2:CreateLabel("Current: "..tostring(UpgradesCfg[Data.SelectedUpgrade.Value] and UpgradesCfg[Data.SelectedUpgrade.Value].Skin or "?").." idx "..tostring(Data.SelectedUpgrade.Value))
    Data.SelectedUpgrade.Changed:Connect(function()
        local cur=UpgradesCfg[Data.SelectedUpgrade.Value]
        if cur then Library.Notify({Title="Ivory", Content=cur.Skin.." (+"..Formatter.Format(cur.Multi)..")", Duration=2}) end
    end)
    G2:CreateButton({Name="Equip Best Now", Callback=function()
        local best=getBestOwned()
        safeFire(Remotes.SelectUpgrade, best)
    end})
    G2:CreateButton({Name="Buy Best Affordable Now", Callback=function()
        local best=getBestAffordable()
        safeFire(Remotes.SelectUpgrade, best)
    end})
end

-- INVENTORY > TRAILS (fixed: Buy Next + Equip Best, no Stop, no duplicate)
do
    local Trails={"Red","Blue","Green","Rainbow","Galaxy","Divine","Fairy","Spectral","Yin Yang","Bloodmoon","Sakura","Flash","Void","Steampunk"}
    local G=InvTrails
    G:CreateToggle({Name="Auto Buy Next Trail", CurrentValue=false})
    createIntervalSlider(G, "AutoBuyTrail_Interval", "Interval", 1)
    local G2=InvTrails
    G2:CreateToggle({Name="Auto Equip Best Trail", CurrentValue=false})
    createIntervalSlider(G2, "AutoEquipBestTrail_Interval", "Interval", 1)
    Toggles.AutoBuyTrail:OnChanged(function()
        if Toggles.AutoBuyTrail.Value then
            runLoop("AutoBuyTrail","AutoBuyTrail","AutoBuyTrail_Interval",function()
                for _,name in ipairs(Trails) do
                    if not Data.UnlockedTrails:FindFirstChild(name) then
                        if Remotes:FindFirstChild("BuyTrail") then safeFire(Remotes.BuyTrail, name) end
                        break
                    end
                end
            end)
        else stopLoop("AutoBuyTrail") end
    end)
    Toggles.AutoEquipBestTrail:OnChanged(function()
        if Toggles.AutoEquipBestTrail.Value then
            runLoop("AutoEquipBestTrail","AutoEquipBestTrail","AutoEquipBestTrail_Interval",function()
                local best=nil
                for i=#Trails,1,-1 do if Data.UnlockedTrails:FindFirstChild(Trails[i]) then best=Trails[i] break end end
                if best and Remotes:FindFirstChild("EquipTrail") then safeFire(Remotes.EquipTrail, best) end
            end)
        else stopLoop("AutoEquipBestTrail") end
    end)
end

-- INVENTORY > AURAS
do
    local Auras={"Amber","Ice Cold","Nature","Rainbow","Lunar","Sparkle","Fairy","Spectral","Yin Yang","Bloodmoon","Sakura","Electric","Void","Steampunk"}
    local G=InvAuras
    G:CreateToggle({Name="Auto Buy Next Aura", CurrentValue=false})
    createIntervalSlider(G, "AutoBuyAura_Interval", "Interval", 1)
    local G2=InvAuras
    G2:CreateToggle({Name="Auto Equip Best Aura", CurrentValue=false})
    createIntervalSlider(G2, "AutoEquipAura_Interval", "Interval", 1)
    Toggles.AutoBuyAura:OnChanged(function()
        if Toggles.AutoBuyAura.Value then
            runLoop("AutoBuyAura","AutoBuyAura","AutoBuyAura_Interval",function()
                for _,name in ipairs(Auras) do
                    if not Data.UnlockedAuras:FindFirstChild(name) then
                        if Remotes:FindFirstChild("BuyAura") then safeFire(Remotes.BuyAura, name) end
                        break
                    end
                end
            end)
        else stopLoop("AutoBuyAura") end
    end)
    Toggles.AutoEquipAura:OnChanged(function()
        if Toggles.AutoEquipAura.Value then
            runLoop("AutoEquipAura","AutoEquipAura","AutoEquipAura_Interval",function()
                local best=nil
                for i=#Auras,1,-1 do
                    if Data.UnlockedAuras:FindFirstChild(Auras[i]) then best=Auras[i]; break end
                end
                if best and Remotes:FindFirstChild("EquipAura") then safeFire(Remotes.EquipAura, best) end
            end)
        else stopLoop("AutoEquipAura") end
    end)
end

-- INVENTORY > CHARMS SHOP (multi-select)
do
    local Charms={"Lucky Key","Treasure Coin","Emerald Talisman","Royal Crown","Lucky Idol","Monkey Paw","Banana Peel","Jungle Gem","Wind Feather","Vine Bracelet","Cheetah Totem","Swift Mask","Lava Drop","Hot Coal","Flame Skull","Magma Crystal","Phoenix Feather","Inferno Crown","Fire Boot","Flame Roller","Rocket Ember","Lava Lightning Bolt","Flaming Wing","Inferno Jetpack","Coconut","Starfish","Treasure Chest","Beach Bucket","Golden Pineapple","Sun Idol","Flip Flop","Sunglasses","Surfboard","Seagull Wing","Rocket Surfboard","Rainbow Wave","Gummy Bear","Candy Corn","Chocolate Bar","Lollipop","Giant Cupcake","Candy Castle","Peppermint","Candy Cane","Bubblegum Rocket","Sugar Star","Rainbow Candy Wing","Chocolate Mask","Snowflake","Ice Crystal","Frozen Chest","Snow Globe","Ice Crown","Glacier Core","Ice Skate","Frozen Feather","Blizzard Arrow","Snowboard","Frost Wing","Aurora Crystal"}
    local G=InvCharmsBuy
    G:CreateDropdown({Name="Charms to Buy", Options=Charms, CurrentOption=1})
    G:CreateToggle({Name="Auto Buy Selected Charms", CurrentValue=false})
    createIntervalSlider(G, "AutoBuyCharm_Interval", "Interval", 1)
    Toggles.AutoBuyCharm:OnChanged(function()
        if Toggles.AutoBuyCharm.Value then
            runLoop("AutoBuyCharm","AutoBuyCharm","AutoBuyCharm_Interval",function()
                local sel = Options.AutoBuyCharm_Select and Options.AutoBuyCharm_Select.Value or {}
                local selected={}
                if type(sel)=="table" then for k,v in pairs(sel) do if v then selected[k]=true end end
                elseif type(sel)=="string" then selected[sel]=true end
                local hasSel=false; for _ in pairs(selected) do hasSel=true break end
                if not hasSel then selected["Lucky Key"]=true end
                local worldShop = Data:FindFirstChild("CharmShop") and Data.CharmShop:FindFirstChild("World"..tostring(Data.World.Value))
                if not worldShop then return end
                for i=1,3 do
                    local slot=worldShop:FindFirstChild("Slot"..i)
                    local bought=worldShop:FindFirstChild("Bought"..i)
                    if slot and slot:IsA("StringValue") and bought and not bought.Value then
                        local name=slot.Value
                        if selected[name] and Remotes:FindFirstChild("BuyCharm") then
                            safeFire(Remotes.BuyCharm, i)
                            task.wait(0.6)
                        end
                    end
                end
            end)
        else stopLoop("AutoBuyCharm") end
    end)
end

-- INVENTORY > CHARMS MANAGE
do
    local Rarities={"Rare","Epic","Legendary","Mythic"}
    local G=InvCharmsManage
    G:CreateDropdown({Name="Equip Best Mode", Options={"Wins","Speed"}, CurrentOption=1})
    G:CreateToggle({Name="Auto Equip Best Charms", CurrentValue=false})
    createIntervalSlider(G, "AutoEquipBestCharms_Interval", "Interval", 1)
    G:CreateToggle({Name="Auto Toggle Lock Charms", CurrentValue=false})
    createIntervalSlider(G, "AutoToggleLockCharms_Interval", "Interval", 1)
    local G2=InvCharmsManage
    G2:CreateDropdown({Name="Stop on Rarity (Delete)", Options=Rarities, CurrentOption=3})
    G2:CreateToggle({Name="Auto Delete Charms", CurrentValue=false})
    createIntervalSlider(G2, "AutoDeleteCharms_Interval", "Interval", 1)
    G2:CreateToggle({Name="Auto Fuse Charms (to Max)", CurrentValue=false})
    createIntervalSlider(G2, "AutoFuseCharms_Interval", "Interval", 1)
    Toggles.AutoEquipBestCharms:OnChanged(function()
        if Toggles.AutoEquipBestCharms.Value then
            runLoop("AutoEquipBestCharms","AutoEquipBestCharms","AutoEquipBestCharms_Interval",function()
                local mode = Options.AutoEquipBestCharms_Mode and Options.AutoEquipBestCharms_Mode.Value or "Wins"
                if mode~="Wins" and mode~="Speed" then mode="Wins" end
                if Remotes:FindFirstChild("EquipBestCharms") then
                    safeFire(Remotes.EquipBestCharms, mode)
                end
            end)
        else stopLoop("AutoEquipBestCharms") end
    end)
    Toggles.AutoToggleLockCharms:OnChanged(function()
        if Toggles.AutoToggleLockCharms.Value then
            runLoop("AutoToggleLockCharms","AutoToggleLockCharms","AutoToggleLockCharms_Interval",function()
                if Remotes:FindFirstChild("ToggleLockCharms") then safeFire(Remotes.ToggleLockCharms) end
            end)
        else stopLoop("AutoToggleLockCharms") end
    end)
    Toggles.AutoDeleteCharms:OnChanged(function()
        if Toggles.AutoDeleteCharms.Value then
            runLoop("AutoDeleteCharms","AutoDeleteCharms","AutoDeleteCharms_Interval",function()
                local sel=Options.AutoDeleteCharms_StopOn and Options.AutoDeleteCharms_StopOn.Value or "Rare"
                if Remotes:FindFirstChild("DeleteCharms") then safeFire(Remotes.DeleteCharms, sel) end
            end)
        else stopLoop("AutoDeleteCharms") end
    end)
    Toggles.AutoFuseCharms:OnChanged(function()
        if Toggles.AutoFuseCharms.Value then
            runLoop("AutoFuseCharms","AutoFuseCharms","AutoFuseCharms_Interval",function()
                local charmsFolder = Data:FindFirstChild("Charms")
                if not charmsFolder then return end
                local byKey={}
                for _,c in ipairs(charmsFolder:GetChildren()) do
                    local charmName = c:GetAttribute("CharmName") or c:GetAttribute("Name") or ""
                    if charmName=="" then continue end
                    if c:GetAttribute("Locked") then continue end
                    local starVal = c:GetAttribute("Stars")
                    if type(starVal)~="number" then starVal=0 end
                    if starVal >= 3 then continue end
                    local k = charmName.."_"..tostring(starVal)
                    byKey[k] = byKey[k] or {}
                    table.insert(byKey[k], c.Name)
                end
                for k, ids in pairs(byKey) do
                    if #ids >= 3 then
                        local toFuse={ids[1], ids[2], ids[3]}
                        if Remotes:FindFirstChild("FuseCharms") then safeFire(Remotes.FuseCharms, toFuse) end
                        return
                    end
                end
            end)
        else stopLoop("AutoFuseCharms") end
    end)
end

-- INVENTORY > CONSUMABLES
do
    local G=InvConsumables
    local Potions={"Speed 10m","Speed 30m","Speed 1h","Wins 10m","Wins 30m","Wins 1h"}
    for _,potion in ipairs(Potions) do
        local id="AutoUsePotion_"..potion:gsub(" ",""):gsub("10m","10"):gsub("30m","30"):gsub("1h","60")
        G:CreateToggle({Name="Auto Use Potion: "..potion, CurrentValue=false})
        createIntervalSlider(G, id.."_Interval", potion.." Interval", 2)
    end
    task.spawn(function()
        task.wait(0.5)
        for _,potion in ipairs(Potions) do
            local id="AutoUsePotion_"..potion:gsub(" ",""):gsub("10m","10"):gsub("30m","30"):gsub("1h","60")
            if Toggles[id] then
                Toggles[id]:OnChanged(function()
                    if Toggles[id].Value then
                        runLoop(id,id,id.."_Interval",function()
                            if Remotes:FindFirstChild("UsePotion") then safeFire(Remotes.UsePotion, potion) end
                        end)
                    else stopLoop(id) end
                end)
            end
        end
    end)
    do
        local G2=InvConsumables
        G2:CreateLabel("Limited Tails are Robux GamePasses - not farmable.")
    end
end

-- REBIRTH (just fire, no level mapping)
do
    local G=RebirthAuto
    G:CreateToggle({Name="Auto Rebirth", CurrentValue=false})
    createIntervalSlider(G, "AutoRebirth_Interval", "Interval", 1)
    Toggles.AutoRebirth:OnChanged(function()
        if Toggles.AutoRebirth.Value then
            runLoop("AutoRebirth","AutoRebirth","AutoRebirth_Interval",function()
                if Remotes:FindFirstChild("Rebirth") then safeFire(Remotes.Rebirth) end
            end)
        else stopLoop("AutoRebirth") end
    end)
    local G2=RebirthInfo
    local txt=string.format("Rebirths: %d | Level %d", Data.Rebirths.Value, Data.Level.Value)
    G2:CreateLabel(txt)
    Data.Level.Changed:Connect(function()
        if Options.RebirthInfoLabel then Options.RebirthInfoLabel:SetText(string.format("Rebirths: %d | Level %d", Data.Rebirths.Value, Data.Level.Value)) end
    end)
    Data.Rebirths.Changed:Connect(function()
        if Options.RebirthInfoLabel then Options.RebirthInfoLabel:SetText(string.format("Rebirths: %d | Level %d", Data.Rebirths.Value, Data.Level.Value)) end
    end)
    G2:CreateButton({Name="Rebirth Now", Callback=function() if Remotes:FindFirstChild("Rebirth") then safeFire(Remotes.Rebirth) end end})
end

-- SETTINGS (always last)
do
    local G=Tabs.Settings:CreateSection("Menu")
    G:CreateToggle({Name="Anti-AFK", CurrentValue=true})
    Toggles.AntiAFK:OnChanged(function() setAntiAFK(Toggles.AntiAFK.Value) end)
    setAntiAFK(true)
    do
        local COREGUI=game:GetService("CoreGui")
        local networkPaused=nil
        local function enableAntiPause()
            pcall(function() if networkPaused then networkPaused:Disconnect() end end)
            networkPaused = COREGUI.RobloxGui.ChildAdded:Connect(function(obj)
                if obj.Name == "CoreScripts/NetworkPause" then
                    pcall(function() obj:Destroy() end)
                end
            end)
            pcall(function()
                local existing=COREGUI.RobloxGui:FindFirstChild("CoreScripts/NetworkPause") or COREGUI.RobloxGui:FindFirstChild("NetworkPause")
                if existing then existing:Destroy() end
                local cs=COREGUI.RobloxGui:FindFirstChild("CoreScripts")
                if cs and cs:FindFirstChild("NetworkPause") then cs.NetworkPause:Destroy() end
            end)
        end
        enableAntiPause()
        task.spawn(function()
            while true do
                task.wait(5)
                pcall(function()
                    local np=COREGUI.RobloxGui:FindFirstChild("CoreScripts/NetworkPause")
                    if np then np:Destroy() end
                end)
            end
        end)
        pcall(function()
            if _G.addcmd or getgenv().addcmd then
                local addcmd = _G.addcmd or getgenv().addcmd
                addcmd("antigameplaypaused", {}, function(args, speaker)
                    pcall(function() if networkPaused then networkPaused:Disconnect() end end)
                    networkPaused = COREGUI.RobloxGui.ChildAdded:Connect(function(obj)
                        if obj.Name == "CoreScripts/NetworkPause" then obj:Destroy() end
                    end)
                    pcall(function() COREGUI.RobloxGui["CoreScripts/NetworkPause"]:Destroy() end)
                end)
            end
        end)
    end
    G:CreateButton({Name="Join Discord", Callback=function()
        if setclipboard then setclipboard("https://discord.gg/ivory") end
        Library.Notify({Title="Ivory", Content="Discord link copied!", Duration=3})
    end})
    G:CreateKeybind({
        Name = "Menu Keybind",
        CurrentKeybind = "RightShift",
    })
    Library.ToggleKeybind=Options.MenuKeybind
    G:CreateDivider()
    G:CreateButton({Name="Unload", Callback=function() Library:Unload() end})
end

do
    local GC = Tabs.Settings:CreateSection("Credits")
    GC:CreateLabel("Made by Mommy")
    GC:CreateLabel("Veqxoo < / 3")
    task.spawn(function()
        task.wait(2)
        pcall(function()
            for _, obj in game:GetService("CoreGui"):GetDescendants() do
                if obj:IsA("TextLabel") and (obj.Text:find("Mommy") or obj.Text:find("Veqxoo")) then
                    obj.TextColor3 = Color3.fromRGB(255, 0, 255)
                    obj.TextSize = 22
                    obj.Font = Enum.Font.GothamBold
                    obj.TextWrapped = true
                    obj.AutomaticSize = Enum.AutomaticSize.Y
                end
            end
        end)
    end)
end

Library.Notify({Title="Ivory", Content="Ivory Hub loaded. Best unlocked train + best win + tails fixed.", Duration=5})
for id,_ in pairs(Loops) do stopLoop(id) end
if AntiAFKConn then AntiAFKConn:Disconnect() end
print("Ivory unloaded")
