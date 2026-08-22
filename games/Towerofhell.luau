-- Tower of Hell | Pink Neon - ObsidianUltra Build FULL
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Options = Library.Options
local Toggles = Library.Toggles
local Tokens = {
    primary = Color3.fromRGB(255, 105, 180),
    background = Color3.fromRGB(30, 20, 30),
    surface = Color3.fromRGB(45, 30, 50),
    text = Color3.fromRGB(255, 220, 240),
    cornerRadius = 8,
}
Library.Scheme.BackgroundColor = Tokens.background
Library.Scheme.MainColor = Tokens.surface
Library.Scheme.AccentColor = Tokens.primary
Library.Scheme.FontColor = Tokens.text
local Window = Library:CreateWindow({
    Title = "ToH | Pink Neon",
    Footer = {"ToH Pink Neon v1.0 |", {Text="discord.gg/mspaint", Copyable=true}},
    Center=true, AutoShow=true, CornerRadius=Tokens.cornerRadius,
    Minimizable=true, ToggleKeybind=Enum.KeyCode.RightShift,
})
Window:SetCornerRadius(Tokens.cornerRadius)
local Tabs = {
    Main = Window:AddTab({Name="Tower", Icon="mountain", Description="Auto Win & Skip"}),
    Movement = Window:AddTab({Name="Movement", Icon="person-standing"}),
    Settings = Window:AddTab({Name="UI Settings", Icon="settings"}),
}
Tabs.Main:SetSubTabAlignment("Center")
local AutoSubTab = Tabs.Main:AddSubTab({Name="Auto Win", Icon="trophy"})
local SkipSubTab = Tabs.Main:AddSubTab({Name="Skip", Icon="skip-forward"})
local State = {AutoWinEnabled=false, AutoWinDelay=1.2, InfiniteJump=false, JumpHeight=50}
local function findTowerFolder()
    for _,name in ipairs({"tower","Tower","TOWER","Map","map"}) do
        local f = Workspace:FindFirstChild(name)
        if f then return f end
    end
    return Workspace
end
local function getTopCFrame()
    local folder = findTowerFolder()
    local topPart, topY = nil, -math.huge
    for _,v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            local n = v.Name:lower()
            if n:find("finish") or n:find("win") or n:find("end") or n:find("top") then
                if v.Position.Y > topY then topPart, topY = v, v.Position.Y end
            end
        end
    end
    if topPart then return topPart.CFrame + Vector3.new(0, 5, 0) end
    for _,v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and v.Position.Y > topY then topPart, topY = v, v.Position.Y end
    end
    if topPart then return topPart.CFrame + Vector3.new(0, 6, 0) end
    return nil
end
local function tweenTo(cf, time)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp or not cf then return end
    time = time or 0.8
    local tween = TweenService:Create(hrp, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame=cf})
    tween:Play()
    return tween
end
local function getHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChildOfClass("Humanoid")
end
do
    local left = AutoSubTab:AddLeftGroupbox("Auto Win", "trophy")
    left:AddToggle("AutoWinEnabled", {Text="Auto Win (loop)", Default=State.AutoWinEnabled}):OnChanged(function() State.AutoWinEnabled = Toggles.AutoWinEnabled.Value end)
    left:AddSlider("AutoWinDelay", {Text="Delay", Default=State.AutoWinDelay, Min=0.3, Max=5, Rounding=1, Suffix="s"}):OnChanged(function() State.AutoWinDelay = Options.AutoWinDelay.Value end)
    left:AddButton({Text="Win Now", Func = function()
        local cf = getTopCFrame()
        if cf then tweenTo(cf, 0.6); Library:Notify({Title="Auto Win", Description="Teleported!", Time=2, Type="Success"})
        else Library:Notify({Title="Auto Win", Description="Top not found", Time=3, Type="Warning"}) end
    end})
    local right = AutoSubTab:AddRightGroupbox("Info", "info")
    right:AddLabel("Finds highest Finish pad or highest part. Tween Quad Out.", true)
    right:AddLabel("Key N toggle"):AddKeyPicker("AutoWinKey", {Default="N", Mode="Toggle", Text="Toggle Auto Win", Callback=function(v) State.AutoWinEnabled=v; Toggles.AutoWinEnabled:SetValue(v) end})
end
do
    local left = SkipSubTab:AddLeftGroupbox("Skip Level", "skip-forward")
    left:AddButton({Text="Skip 35 studs", Func=function()
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then tweenTo(hrp.CFrame + Vector3.new(0,35,0),0.5); Library:Notify({Title="Skip", Description="Skipped 35", Time=1.5}) end
    end})
    left:AddSlider("SkipAmount", {Text="Custom Skip Height", Default=35, Min=10, Max=100, Rounding=0, Suffix=" studs"})
    left:AddButton({Text="Custom Skip", Func=function()
        local amt = Options.SkipAmount and Options.SkipAmount.Value or 35
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then tweenTo(hrp.CFrame + Vector3.new(0,amt,0),0.5) end
    end})
    local right = SkipSubTab:AddRightGroupbox("Teleport", "map-pinned")
    right:AddButton({Text="To Lobby", Func=function()
        local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then tweenTo(spawn.CFrame + Vector3.new(0,3,0),0.6) else
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then tweenTo(CFrame.new(11,9,25),0.6) end
        end
    end})
end
do
    local left = Tabs.Movement:AddLeftGroupbox("Infinite Jump", "arrow-up")
    left:AddToggle("InfiniteJump", {Text="Infinite Jump", Default=State.InfiniteJump}):OnChanged(function() State.InfiniteJump = Toggles.InfiniteJump.Value end)
    left:AddSlider("JumpHeight", {Text="Jump Power", Default=State.JumpHeight, Min=20, Max=120, Rounding=0, Suffix=" pw"}):OnChanged(function() State.JumpHeight = Options.JumpHeight.Value end)
    local right = Tabs.Movement:AddRightGroupbox("Movement Helpers", "activity")
    right:AddSlider("WalkSpeed", {Text="WalkSpeed", Default=16, Min=16, Max=40, Rounding=0, Suffix=" stud/s", Callback=function(v) local hum=getHumanoid(); if hum then hum.WalkSpeed=v end end})
    right:AddSlider("Gravity", {Text="Gravity", Default=Workspace.Gravity, Min=30, Max=196, Rounding=0, Callback=function(v) Workspace.Gravity=v end})
    right:AddButton({Text="Reset", Func=function()
        local hum=getHumanoid(); if hum then hum.WalkSpeed=16; hum.JumpPower=50 end
        Workspace.Gravity=196.2; Options.WalkSpeed:SetValue(16); Options.Gravity:SetValue(196)
    end})
end
do
    local menu = Tabs.Settings:AddLeftGroupbox("Menu", "wrench")
    menu:AddToggle("KeybindMenuOpen", {Default=Library.KeybindFrame.Visible, Text="Open Keybind Menu", Callback=function(v) Library.KeybindFrame.Visible=v end})
    menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default="RightShift", NoUI=true, Text="Menu keybind"})
    menu:AddButton("Unload", function() Library:Unload() end)
    Library.ToggleKeybind = Options.MenuKeybind
    local theme = Tabs.Settings:AddRightGroupbox("Theme", "palette")
    theme:AddLabel("Pink Neon: "..tostring(Tokens.background).." / "..tostring(Tokens.surface), true)
    ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library); SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({"MenuKeybind"})
    ThemeManager:SetFolder("PinkNeonToH"); SaveManager:SetFolder("PinkNeonToH/ToH")
    SaveManager:BuildConfigSection(Tabs.Settings); ThemeManager:ApplyToTab(Tabs.Settings); SaveManager:LoadAutoloadConfig()
end
local jumpConn = UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum=getHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping); if State.JumpHeight~=50 then hum.JumpPower=State.JumpHeight end end
    end
end)
if Options.JumpHeight then Options.JumpHeight:OnChanged(function() State.JumpHeight=Options.JumpHeight.Value; local hum=getHumanoid(); if hum then hum.JumpPower=State.JumpHeight end end) end
task.spawn(function()
    while true do
        task.wait(State.AutoWinDelay)
        if State.AutoWinEnabled then
            local cf=getTopCFrame()
            if cf then
                local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - cf.Position).Magnitude>12 then tweenTo(cf,0.9) end
            end
        end
        if Library.Unloaded then break end
    end
end)
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); local hum=char:WaitForChild("Humanoid"); if State.JumpHeight then hum.JumpPower=State.JumpHeight end end)
Library:OnUnload(function() if jumpConn then jumpConn:Disconnect() end; print("ToH unloaded") end)
Library:Notify({Title="ToH Pink Neon Loaded", Description="Auto Win + Skip + Infinite Jump ready. RightShift", Time=4, Type="Success"})
Window:SetMinimizedSubtitle("ToH | Auto Win + Movement")
