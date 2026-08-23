-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ═══════════════════════════════════════════════════════════════
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = tostring(math.random(100000,999999)) .. tostring(tick()):sub(-6)
local _genv = getgenv()
local _integritySalt = 0x4A
local function _verifyIntegrity()
    if not _k or not _k.v then return false end
    if _k.i ~= (_integritySalt + #(_k.s or "")) then _k.v = false; return false end
    return true
end

local _kg = Instance.new("ScreenGui")
_kg.Name = "IvoryKey"
_kg.ResetOnSpawn = false
_kg.DisplayOrder = 9999
pcall(function() _kg.Parent = game:GetService("CoreGui") end)
if not _kg.Parent then _kg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local _lootKey = ""
do
    local _s = 0x5A
    local _b = {19,12,21,8,3,119,19,16,99,2,119,31,108,15,24,119,23,9,25,14,119,15,29,18,0}
    local _c = {}
    for _i = 1, #_b do _c[_i] = string.char(_b[_i] ~ _s) end
    _lootKey = table.concat(_c)
end

local _awaiting = true
local _st

local _savedKey = nil
local _savedExpiry = nil
pcall(function()
    if isfile("IvoryKey.txt") then
        local data = readfile("IvoryKey.txt")
        _savedKey, _savedExpiry = data:match("^(.-)\n(.-)$")
        _savedExpiry = tonumber(_savedExpiry)
    end
end)
if not _savedKey then
    pcall(function() _savedKey = _genv._ivoryKey end)
    pcall(function() _savedExpiry = _genv._ivoryExpiry end)
end

if _savedKey and _savedExpiry and os.time() * 1000 < _savedExpiry then
    _k.v = true; _k.s = _savedKey; _k.h = _hwid; _k.t = os.time()
    _k.i = 0x4A + #_savedKey
    _awaiting = false
    pcall(function() _kg:Destroy() end)
end
if _awaiting then
    local _f = Instance.new("Frame")
    _f.Size = UDim2.fromOffset(380, 295)
    _f.Position = UDim2.fromScale(0.5, 0.5)
    _f.AnchorPoint = Vector2.new(0.5, 0.5)
    _f.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    _f.BorderSizePixel = 0
    _f.Parent = _kg
    Instance.new("UICorner", _f).CornerRadius = UDim.new(0, 8)
    local _stroke = Instance.new("UIStroke", _f)
    _stroke.Color = Color3.fromRGB(90, 60, 200)
    _stroke.Thickness = 1.5

    local function _mkLbl(text, y, color, size, font, parent)
        local l = Instance.new("TextLabel", parent or _f)
        l.Size = UDim2.new(1, -20, 0, size + 6)
        l.Position = UDim2.fromOffset(10, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = color
        l.TextSize = size
        l.Font = font or Enum.Font.Gotham
        return l
    end

    _mkLbl("Ivory Hub", 12, Color3.fromRGB(200, 170, 255), 22, Enum.Font.GothamBold)
    _mkLbl("Enter your key to continue", 40, Color3.fromRGB(140, 140, 150), 13)

    local _inp = Instance.new("TextBox", _f)
    _inp.Size = UDim2.new(1, -20, 0, 32)
    _inp.Position = UDim2.fromOffset(10, 64)
    _inp.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    _inp.TextColor3 = Color3.fromRGB(200, 200, 210)
    _inp.PlaceholderText = "Paste your key here"
    _inp.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    _inp.Text = ""
    _inp.TextSize = 14
    _inp.Font = Enum.Font.Code
    _inp.BorderSizePixel = 0
    Instance.new("UICorner", _inp).CornerRadius = UDim.new(0, 6)

    local _btn = Instance.new("TextButton", _f)
    _btn.Size = UDim2.new(1, -20, 0, 32)
    _btn.Position = UDim2.fromOffset(10, 104)
    _btn.BackgroundColor3 = Color3.fromRGB(90, 60, 200)
    _btn.TextColor3 = Color3.new(1, 1, 1)
    _btn.Text = "Verify"
    _btn.TextSize = 15
    _btn.Font = Enum.Font.GothamBold
    _btn.BorderSizePixel = 0
    Instance.new("UICorner", _btn).CornerRadius = UDim.new(0, 6)

    _st = _mkLbl("", 142, Color3.fromRGB(140, 140, 150), 12)

    local function _mkBtn(text, y, bg, textColor, cb)
        local b = Instance.new("TextButton", _f)
        b.Size = UDim2.new(1, -20, 0, 20)
        b.Position = UDim2.fromOffset(10, y)
        b.BackgroundColor3 = bg
        b.TextColor3 = textColor
        b.Text = text
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(cb)
    end

    _mkBtn("Join for dupe", 188, Color3.fromRGB(88, 101, 242), Color3.new(1, 1, 1), function()
        pcall(setclipboard, "https://discord.gg/mrQFkCJfEe")
        _st.Text = "Copied!"
        _st.TextColor3 = Color3.fromRGB(80, 220, 120)
        task.delay(1.5, function() _st.Text = "" end)
    end)

    _mkBtn("Get Key - Work.ink", 212, Color3.fromRGB(35, 35, 42), Color3.fromRGB(120, 180, 255), function()
        pcall(setclipboard, "https://work.ink/2STL/Ivory")
        _st.Text = "Copied!"
        _st.TextColor3 = Color3.fromRGB(80, 220, 120)
        task.delay(1.5, function() _st.Text = "" end)
    end)

    _mkBtn("Get Key - LootLabs", 236, Color3.fromRGB(35, 35, 42), Color3.fromRGB(200, 130, 255), function()
        pcall(setclipboard, "https://loot-link.com/s?L6z5Q0nE")
        _st.Text = "Copied!"
        _st.TextColor3 = Color3.fromRGB(80, 220, 120)
        task.delay(1.5, function() _st.Text = "" end)
    end)

    local function _doValidate(key)
        if _lootKey ~= "" and key == _lootKey then
            _k.v = true; _k.s = key; _k.h = _hwid; _k.t = os.time()
            _k.i = 0x4A + #key
            pcall(function()
                _genv._ivoryKey = key
                _genv._ivoryExpiry = os.time() * 1000 + 43200000
                writefile("IvoryKey.txt", key .. "\n" .. tostring(os.time() * 1000 + 43200000))
            end)
            _st.Text = "Access granted"
            _st.TextColor3 = Color3.fromRGB(80, 220, 120)
            _btn.Text = "Loading..."
            task.wait(0.4)
            _awaiting = false
            _kg:Destroy()
            return
        end
        local ok, res = pcall(function()
            return request({ Url = "https://work.ink/_api/v2/token/isValid/" .. key .. "?deleteToken=1", Method = "GET" })
        end)
        if ok and res and res.Body then
            local dOk, data = pcall(function() return json.decode(res.Body) end)
            if dOk and data and data.valid then
                _k.v = true; _k.s = key; _k.h = _hwid; _k.t = os.time()
                _k.i = 0x4A + #key
                pcall(function()
                    _genv._ivoryKey = key
                    local exp = data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)
                    _genv._ivoryExpiry = exp
                    writefile("IvoryKey.txt", key .. "\n" .. tostring(exp))
                end)
                _st.Text = "Access granted"
                _st.TextColor3 = Color3.fromRGB(80, 220, 120)
                _btn.Text = "Loading..."
                task.wait(0.4)
                _awaiting = false
                _kg:Destroy()
                return
            end
        end
        _st.Text = "Invalid key - get one at work.ink/2STL/Ivory"
        _st.TextColor3 = Color3.fromRGB(220, 80, 80)
    end

    _btn.MouseButton1Click:Connect(function()
        local key = _inp.Text:match("^%s*(.-)%s*$")
        if #key < 5 then
            _st.Text = "Key too short"
            _st.TextColor3 = Color3.fromRGB(220, 80, 80)
            return
        end
        _btn.Text = "Verifying..."
        _doValidate(key)
    end)

    _inp.FocusLost:Connect(function(enter)
        if enter then
            local key = _inp.Text:match("^%s*(.-)%s*$")
            if #key >= 5 then
                _btn.Text = "Verifying..."
                _doValidate(key)
            end
        end
    end)
end

task.spawn(function()
    while true do
        task.wait(math.random(45, 90))
        if _k and _k.v and not _verifyIntegrity() then
            pcall(function()
                for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
                    if gui.Name == "IvoryKey" then gui:Destroy() end
                end
            end)
        end
    end
end)

while _awaiting do task.wait(0.1) end

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
    ShowCustomCursor = true,
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

    -- Priority 1: exit carpet in finish area (the green win pad)
    if workspace.tower.sections.finish.FinishGlow ~= nil then
        return workspace.tower.sections.finish.FinishGlow.CFrame
    end

    -- Priority 2: highest wide collidable platform
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

-- Safe teleport: instant CFrame set (bypasses tween that hits kill bricks)
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
            if not (_k and _k.v and _k.i) then return end
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
            if not (_k and _k.v and _k.s) then return end
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
            if not (_k and _k.v and _k.s) then return end
            local amt = Options.SkipAmount and Options.SkipAmount.Value or 35
            local hrp = getHRP()
            if hrp then safeTeleport(hrp.CFrame + Vector3.new(0, amt, 0)) end
        end,
    })

    local right = SkipSubTab:AddRightGroupbox("Teleport", "map-pinned")
    right:AddButton({
        Text = "To Lobby",
        Func = function()
            if not (_k and _k.v and _k.v) then return end
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
            if not (_k and _k.v and _k.i) then return end
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
            if not (_k and _k.v and _k.s) then return end
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
    if State.InfiniteJump and _k and _k.v and _k.i then
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

-- AUTO WIN LOOP: Uses arc teleport to fly OVER all kill bricks
task.spawn(function()
    while true do
        task.wait(State.AutoWinDelay)
        if State.AutoWinEnabled and _k and _k.v and _k.i then
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
