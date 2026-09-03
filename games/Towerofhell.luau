-- ═══════════════════════════════════════════════════════════════
-- IVORY HUB - TOWER OF HELL
-- ═══════════════════════════════════════════════════════════════

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(request({ Url = repo .. "Library.lua", Method = "GET" }).Body)()
local ThemeManager = loadstring(request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body)()
local SaveManager = loadstring(request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body)()
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

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("toh")

local Window = Library:CreateWindow({
    Title = "Ivory",
    Icon = "swords",
    Footer = {
        "v1.4 |",
        { Text = "Game", Copyable = true },
        "|",
        { Text = tostring(LocalPlayer.UserId), Copyable = true },
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
    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Groupbox = false,
        Dropdown = false,
        KeyPicker = false,
        SubTabUnderline = true,
    },
})
Window:SetCornerRadius(Tokens.cornerRadius)

local Tabs = {
    Main = Window:AddTab({ Name = "Tower", Icon = "mountain" }),
    Movement = Window:AddTab({ Name = "Movement", Icon = "user" }),
    Settings = Window:AddTab({ Name = "Settings", Icon = "settings" }),
}

Tabs.Main:SetSubTabAlignment("Center")
local AutoSubTab = Tabs.Main:AddSubTab({ Name = "Auto Win", Icon = "trophy" })
local SkipSubTab = Tabs.Main:AddSubTab({ Name = "Skip", Icon = "skip-forward" })

local State = { AutoWinEnabled = false, AutoWinDelay = 1.2, InfiniteJump = false, JumpHeight = 50 }

local function findTowerFolder()
    for _, name in ipairs({"tower","Tower","TOWER","Map","map"}) do
        local f = Workspace:FindFirstChild(name)
        if f then return f end
    end
    return Workspace
end

local function getTopCFrame()
    local folder = findTowerFolder()

    if workspace.tower.sections.finish.FinishGlow ~= nil then
        return workspace.tower.sections.finish.FinishGlow.CFrame
    end

    local bestPart, bestY = nil, -math.huge
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            local n = v.Name:lower()
            if not n:find("finishglow") and not n:find("streaming") and not n:find("particle") and not n:find("wall") then
                local area = v.Size.X * v.Size.Z
                if area > 200 and v.Position.Y > bestY then
                    bestPart, bestY = v, v.Position.Y
                end
            end
        end
    end
    if bestPart then
        local topY = bestPart.Position.Y + (bestPart.Size.Y / 2) + 1
        return CFrame.new(bestPart.Position.X, topY, bestPart.Position.Z)
    end
    return nil
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChildOfClass("Humanoid")
end

local function safeTeleport(cf)
    local hrp = getHRP()
    print(hrp)
    print(cf)
    if not hrp or not cf then return end
    hrp.CFrame = cf
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN > AUTO WIN
-- ═══════════════════════════════════════════════════════════════

do
    local left = AutoSubTab:AddLeftGroupbox("Auto Win", "trophy")
    left:AddToggle("AutoWinEnabled", {
        Text = "Auto Win (loop)",
        Default = State.AutoWinEnabled,
    }):OnChanged(function()
        State.AutoWinEnabled = Toggles.AutoWinEnabled.Value
    end)
    left:AddSlider("AutoWinDelay", {
        Text = "Delay",
        Default = State.AutoWinDelay,
        Min = 0.3,
        Max = 5,
        Rounding = 1,
        Suffix = "s",
    }):OnChanged(function()
        State.AutoWinDelay = Options.AutoWinDelay.Value
    end)
    left:AddButton({
        Text = "Win Now",
        Func = function()
            local hrp = getHRP()
            local offset
            if hrp.Position.Z < getTopCFrame().Position.Z then
                offset = Vector3.new(0, 0, -1)
            elseif hrp.Position.Z > getTopCFrame().Position.Z then
                offset = Vector3.new(0, 0, 1)
            else 
                offset = Vector3.new(0, 0, 0)
            end
            local cf = getTopCFrame() + offset
            if cf then
                safeTeleport(cf)
                Library:Notify({ Title = "Ivory", Description = "Teleported!", Time = 2, Type = "Success" })
            else
                Library:Notify({ Title = "Ivory", Description = "Top not found", Time = 3, Type = "Error" })
            end
        end,
    })

    local right = AutoSubTab:AddRightGroupbox("Info", "info")
    right:AddLabel("Flies UP then DOWN to finish — avoids all kill bricks", true)
    right:AddLabel("Key N toggle"):AddKeyPicker("AutoWinKey", {
        Default = "N",
        Mode = "Toggle",
        Text = "Toggle Auto Win",
        Callback = function(v)
            State.AutoWinEnabled = v
            Toggles.AutoWinEnabled:SetValue(v)
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- MAIN > SKIP
-- ═══════════════════════════════════════════════════════════════

do
    local left = SkipSubTab:AddLeftGroupbox("Skip Level", "skip-forward")
    left:AddButton({
        Text = "Skip 35 studs",
        Func = function()
            local hrp = getHRP()
            if hrp then
                safeTeleport(hrp.CFrame + Vector3.new(0, 35, 0))
                Library:Notify({ Title = "Ivory", Description = "Skipped 35", Time = 1.5 })
            end
        end,
    })
    left:AddSlider("SkipAmount", {
        Text = "Custom Skip Height",
        Default = 35,
        Min = 10,
        Max = 100,
        Rounding = 0,
        Suffix = " studs",
    })
    left:AddButton({
        Text = "Custom Skip",
        Func = function()
            local amt = Options.SkipAmount and Options.SkipAmount.Value or 35
            local hrp = getHRP()
            if hrp then safeTeleport(hrp.CFrame + Vector3.new(0, amt, 0)) end
        end,
    })

    local right = SkipSubTab:AddRightGroupbox("Teleport", "map-pinned")
    right:AddButton({
        Text = "To Lobby",
        Func = function()
            local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
            if spawn then
                safeTeleport(spawn.CFrame + Vector3.new(0, 3, 0))
            else
                local hrp = getHRP()
                if hrp then safeTeleport(CFrame.new(11, 9, 25)) end
            end
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- PLAYER > MOVEMENT
-- ═══════════════════════════════════════════════════════════════

do
    local left = Tabs.Movement:AddLeftGroupbox("Infinite Jump", "arrow-up")
    left:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = State.InfiniteJump,
    }):OnChanged(function()
        State.InfiniteJump = Toggles.InfiniteJump.Value
    end)
    left:AddSlider("JumpHeight", {
        Text = "Jump Power",
        Default = State.JumpHeight,
        Min = 20,
        Max = 120,
        Rounding = 0,
        Suffix = " pw",
    }):OnChanged(function()
        State.JumpHeight = Options.JumpHeight.Value
    end)

    local right = Tabs.Movement:AddRightGroupbox("Movement Helpers", "activity")
    right:AddSlider("WalkSpeed", {
        Text = "WalkSpeed",
        Default = 16,
        Min = 16,
        Max = 40,
        Rounding = 0,
        Suffix = " stud/s",
        Callback = function(v)
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = v end
        end,
    })
    right:AddSlider("Gravity", {
        Text = "Gravity",
        Default = Workspace.Gravity,
        Min = 30,
        Max = 196,
        Rounding = 0,
        Callback = function(v)
            Workspace.Gravity = v
        end,
    })
    right:AddButton({
        Text = "Reset",
        Func = function()
            local hum = getHumanoid()
            if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
            Workspace.Gravity = 196.2
            Options.WalkSpeed:SetValue(16)
            Options.Gravity:SetValue(196)
        end,
    })
end

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════════════════════════

do
    local menu = Tabs.Settings:AddLeftGroupbox("Menu", "menu")
    menu:AddToggle("KeybindMenuOpen", {
        Default = Library.KeybindFrame.Visible,
        Text = "Open Keybind Menu",
        Callback = function(v) Library.KeybindFrame.Visible = v end,
    })
    menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind",
    })
    menu:AddButton("Join Discord", function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library:Notify({ Title = "Ivory", Description = "Discord link copied!", Type = "Success", Time = 3 }) end)
    menu:AddButton("Unload", function() Library:Unload() end)
    Library.ToggleKeybind = Options.MenuKeybind

    local creditBox = Tabs.Settings:AddLeftGroupbox("Credits", "heart")
    creditBox:AddLabel('<font color="#FF69B4" size="18"><b>Made by mommy veqxo &lt;3</b></font>', true)

    local theme = Tabs.Settings:AddRightGroupbox("Theme", "palette")
    theme:AddLabel("Pink Neon: " .. tostring(Tokens.background) .. " / " .. tostring(Tokens.surface), true)
    ThemeManager:ApplyToTab(Tabs.Settings)
    SaveManager:BuildConfigSection(Tabs.Settings)
    SaveManager:LoadAutoloadConfig()
end

-- ═══════════════════════════════════════════════════════════════
-- EVENT HANDLERS & MAIN LOOP
-- ═══════════════════════════════════════════════════════════════

local jumpConn = UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            if State.JumpHeight ~= 50 then hum.JumpPower = State.JumpHeight end
        end
    end
end)

if Options.JumpHeight then
    Options.JumpHeight:OnChanged(function()
        State.JumpHeight = Options.JumpHeight.Value
        local hum = getHumanoid()
        if hum then hum.JumpPower = State.JumpHeight end
    end)
end

task.spawn(function()
    while true do
        task.wait(State.AutoWinDelay)
        if State.AutoWinEnabled then
            local cf = getTopCFrame()
            if cf then
                local hrp = getHRP()
                if hrp and (hrp.Position - cf.Position).Magnitude > 12 then
                    safeTeleport(cf)
                end
            end
        end
        if Library.Unloaded then break end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid")
    if State.JumpHeight then hum.JumpPower = State.JumpHeight end
end)

Library:OnUnload(function()
    if jumpConn then jumpConn:Disconnect() end
    print("Ivory Hub unloaded")
end)

Library:Notify({
    Title = "Ivory",
    Description = "Tower of Hell loaded. RightShift to open menu.",
    Type = "Success",
    Time = 4,
})
Window:SetMinimizedSubtitle("Ivory | Auto Win + Movement")