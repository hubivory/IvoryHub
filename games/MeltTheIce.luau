-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ═══════════════════════════════════════════════════════════════
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = tostring(math.random(100000,999999)) .. tostring(tick()):sub(-6)
local _integritySalt = 0x4A
local function _verifyIntegrity()
    if not _k or not _k.v then return false end
    if _k.i ~= (_integritySalt + #(_k.s or "")) then _k.v = false; return false end
    return true
end

local _lootKey = ""
do
    local _e = {"IVORY","-","GHRR","-","6PUO","-","8P69","-","ZKGY"}
    for _, _p in ipairs(_e) do _lootKey = _lootKey .. _p end
end

local _kg = Instance.new("ScreenGui")
_kg.Name = "IvoryKey"
_kg.ResetOnSpawn = false
_kg.DisplayOrder = 9999
pcall(function() _kg.Parent = game:GetService("CoreGui") end)
if not _kg.Parent then _kg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local _awaiting = true

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
    pcall(function() _savedKey = getgenv()._ivoryKey end)
    pcall(function() _savedExpiry = getgenv()._ivoryExpiry end)
end

if _savedKey and _savedExpiry and os.time() * 1000 < _savedExpiry then
    _k.v = true
    _k.s = _savedKey
    _k.h = _hwid
    _k.t = os.time()
    _k.i = 0x4A + #_savedKey
    _awaiting = false
    pcall(function() _kg:Destroy() end)
end

if _awaiting then
    local _frame = Instance.new("Frame")
    _frame.Size = UDim2.new(0, 380, 0, 295)
    _frame.Position = UDim2.new(0.5, -190, 0.5, -147)
    _frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    _frame.BorderSizePixel = 0
    _frame.Parent = _kg
    Instance.new("UICorner", _frame).CornerRadius = UDim.new(0, 8)
    local _stroke = Instance.new("UIStroke")
    _stroke.Color = Color3.fromRGB(90, 60, 200)
    _stroke.Thickness = 1.5
    _stroke.Parent = _frame

    local _title = Instance.new("TextLabel")
    _title.Size = UDim2.new(1, -20, 0, 30)
    _title.Position = UDim2.new(0, 10, 0, 12)
    _title.BackgroundTransparency = 1
    _title.Text = "Ivory Hub"
    _title.TextColor3 = Color3.fromRGB(200, 170, 255)
    _title.TextSize = 22
    _title.Font = Enum.Font.GothamBold
    _title.Parent = _frame

    local _sub = Instance.new("TextLabel")
    _sub.Size = UDim2.new(1, -20, 0, 18)
    _sub.Position = UDim2.new(0, 10, 0, 40)
    _sub.BackgroundTransparency = 1
    _sub.Text = "Enter your key to continue"
    _sub.TextColor3 = Color3.fromRGB(140, 140, 150)
    _sub.TextSize = 13
    _sub.Font = Enum.Font.Gotham
    _sub.Parent = _frame

    local _input = Instance.new("TextBox")
    _input.Size = UDim2.new(1, -24, 0, 34)
    _input.Position = UDim2.new(0, 12, 0, 64)
    _input.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    _input.BorderSizePixel = 0
    _input.PlaceholderText = "Paste your key here"
    _input.PlaceholderColor3 = Color3.fromRGB(80, 80, 90)
    _input.Text = ""
    _input.TextColor3 = Color3.fromRGB(220, 220, 220)
    _input.TextSize = 14
    _input.Font = Enum.Font.Code
    _input.ClearTextOnFocus = true
    _input.Parent = _frame
    Instance.new("UICorner", _input).CornerRadius = UDim.new(0, 6)

    local _btn = Instance.new("TextButton")
    _btn.Size = UDim2.new(1, -24, 0, 34)
    _btn.Position = UDim2.new(0, 12, 0, 104)
    _btn.BackgroundColor3 = Color3.fromRGB(90, 60, 200)
    _btn.Text = "Verify Key"
    _btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    _btn.TextSize = 15
    _btn.Font = Enum.Font.GothamBold
    _btn.BorderSizePixel = 0
    _btn.Parent = _frame
    Instance.new("UICorner", _btn).CornerRadius = UDim.new(0, 6)

    local _st = Instance.new("TextLabel")
    _st.Size = UDim2.new(1, -24, 0, 18)
    _st.Position = UDim2.new(0, 12, 0, 142)
    _st.BackgroundTransparency = 1
    _st.Text = ""
    _st.TextColor3 = Color3.fromRGB(255, 80, 80)
    _st.TextSize = 12
    _st.Font = Enum.Font.Gotham
    _st.Parent = _frame

    local function _copyBtn(y, text, bgColor, textColor, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -24, 0, 20)
        b.Position = UDim2.new(0, 12, 0, y)
        b.BackgroundColor3 = bgColor
        b.Text = text
        b.TextColor3 = textColor
        b.TextSize = 11
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.Parent = _frame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(function()
            pcall(callback)
            b.Text = "Copied!"
            b.TextColor3 = Color3.fromRGB(80, 220, 120)
            task.delay(1.5, function()
                b.Text = text
                b.TextColor3 = textColor
            end)
        end)
    end

    _copyBtn(172, "Join for dupe", Color3.fromRGB(88, 101, 242), Color3.fromRGB(255, 255, 255), function()
        setclipboard("https://discord.gg/mrQFkCJfEe")
    end)
    _copyBtn(196, "Get Key - Work.ink", Color3.fromRGB(35, 35, 42), Color3.fromRGB(120, 180, 255), function()
        setclipboard("https://work.ink/2STL/Ivory")
    end)
    _copyBtn(220, "Get Key - LootLabs", Color3.fromRGB(35, 35, 42), Color3.fromRGB(200, 130, 255), function()
        setclipboard("https://loot-link.com/s?L6z5Q0nE")
    end)

    local function _doValidate(key)
        if not key or #key < 4 then
            _st.Text = "Key too short"
            _st.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end
        if _lootKey ~= "" and key == _lootKey then
            _k.v = true
            _k.s = key
            _k.h = _hwid
            _k.t = os.time()
            _k.i = 0x4A + #key
            pcall(function()
                getgenv()._ivoryKey = key
                getgenv()._ivoryExpiry = os.time() * 1000 + 43200000
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
            local data = json.decode(res.Body)
            if data and data.isValid then
                _k.v = true
                _k.s = key
                _k.h = _hwid
                _k.t = os.time()
                _k.i = 0x4A + #key
                pcall(function()
                    getgenv()._ivoryKey = key
                    getgenv()._ivoryExpiry = data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)
                    writefile("IvoryKey.txt", key .. "\n" .. tostring(data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)))
                end)
                _st.Text = "Access granted"
                _st.TextColor3 = Color3.fromRGB(80, 220, 120)
                _btn.Text = "Loading..."
                task.wait(0.4)
                _awaiting = false
                _kg:Destroy()
            else
                _st.Text = "Invalid key - get one at work.ink/2STL/Ivory"
                _st.TextColor3 = Color3.fromRGB(255, 80, 80)
            end
        else
            _st.Text = "Validation error - try again"
            _st.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end

    _btn.MouseButton1Click:Connect(function()
        _doValidate(_input.Text)
    end)
    _input.FocusLost:Connect(function(enter)
        if enter then _doValidate(_input.Text) end
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
-- SERVICES
-- ═══════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = {
    SellAll = Events:WaitForChild("SellAll"),
    BuyWeapon = Events:WaitForChild("BuyWeapon"),
    BuyBackpack = Events:WaitForChild("BuyBackpack"),
    BuyUpgrade = Events:WaitForChild("BuyUpgrade"),
    TeleportToStage = Events:WaitForChild("TeleportToStage"),
    SpinRoll = Events:WaitForChild("SpinRoll"),
    SpinClaim = Events:WaitForChild("SpinClaim"),
    EquipWeapon = Events:WaitForChild("EquipWeapon"),
    EquipBackpack = Events:WaitForChild("EquipBackpack"),
    BuyPotion = Events:WaitForChild("BuyPotion"),
    IndexClaim = Events:WaitForChild("IndexClaim"),
    ClaimPlaytimeReward = Events:WaitForChild("ClaimPlaytimeReward"),
    HoldItem = Events:WaitForChild("HoldItem"),
}

local Workspace = game:GetService("Workspace")
local Map = Workspace:WaitForChild("Map")

local LocalPlayer = LP

local function httpGet(url)
    local ok, res = pcall(function()
        return request({ Url = url, Method = "GET" })
    end)
    if ok and res and res.Body then
        return res.Body
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════
-- UI LIBRARY
-- ═══════════════════════════════════════════════════════════════
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

-- ═══════════════════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════════════════
local STATE = {
    AutoMelt = false,
    AutoMeltSpeed = 0.05,
    AutoSell = false,
    AutoSellInterval = 5,
    AutoCollect = false,
    AutoBuyWeapon = false,
    AutoBuyBackpack = false,
    AutoBuyUpgrade = false,
    AutoUpgradeType = "All",
    AutoSpin = false,
    AutoPlaytime = false,
    AutoIndex = false,
    TeleportStage = 1,
    Noclip = false,
    InfiniteJump = false,
    ESP = false,
    ESPBoxes = false,
    ESPNames = false,
    ESPTracers = false,
    ESPDistance = false,
    ESPColor = Color3.fromRGB(255, 100, 100),
    WalkSpeed = 22,
    JumpPower = 50,
    Gravity = 196.2,
    ServerHop = false,
}

-- ═══════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════
local function getChar()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getTool()
    local c = LocalPlayer.Character
    if c then
        for _, v in ipairs(c:GetChildren()) do
            if v:IsA("Tool") then return v end
        end
    end
    for _, v in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if v:IsA("Tool") then return v end
    end
    return nil
end

local function getZones()
    local zones = {}
    for _, v in ipairs(Map:GetChildren()) do
        if v.Name:match("^Zone %d+$") then
            table.insert(zones, {name = v.Name, num = tonumber(v.Name:match("%d+"))})
        end
    end
    table.sort(zones, function(a, b) return a.num < b.num end)
    return zones
end

local function getZoneNames()
    local names = {}
    for _, z in ipairs(getZones()) do
        table.insert(names, z.name)
    end
    return names
end

local function teleportToZone(zoneNum)
    local zoneName = "Zone " .. tostring(zoneNum)
    local zone = Map:FindFirstChild(zoneName)
    if zone then
        local hrp = getHRP()
        if hrp then
            local target = zone.WorldPivot.Position + Vector3.new(0, 5, 0)
            hrp.CFrame = CFrame.new(target)
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- ESP MODULE
-- ═══════════════════════════════════════════════════════════════
local ESPObjects = {}

local function clearESP()
    for _, obj in ipairs(ESPObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    ESPObjects = {}
end

local function createESP(part, text, color)
    if not part or not part.Parent then return end
    local bb = Instance.new("BillboardGui")
    bb.Name = "IvoryESP"
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = part
    bb.Parent = part

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = text
    tl.TextColor3 = color or STATE.ESPColor
    tl.TextSize = 14
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0.3
    tl.TextStrokeColor3 = Color3.new(0, 0, 0)
    tl.Parent = bb

    table.insert(ESPObjects, bb)
    return bb
end

local function updateESP()
    clearESP()
    if not (STATE.ESP and _k and _k.v and _k.i) then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local label = plr.Name
                if STATE.ESPDistance then
                    local myHRP = getHRP()
                    if myHRP then
                        local dist = math.floor((myHRP.Position - hrp.Position).Magnitude)
                        label = label .. " [" .. dist .. "m]"
                    end
                end
                createESP(hrp, label, STATE.ESPColor)
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════════════════
local noclipConn = nil
local function setNoclip(on)
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    if on and _k and _k.v and _verifyIntegrity() then
        noclipConn = RunService.Stepped:Connect(function()
            local c = LocalPlayer.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════════════════════════════
local ijConn = nil
local function setInfiniteJump(on)
    if ijConn then ijConn:Disconnect(); ijConn = nil end
    if on and _k and _k.v and _k.i then
        ijConn = UserInputService.JumpRequest:Connect(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildWhichIsA("Humanoid")
                if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
            end
        end)
    end
end


-- ═══════════════════════════════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "Ivory",
    Icon = "flame",
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

-- ═══════════════════════════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════════════════════════
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "shopping-cart" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

-- ─── MAIN: Automation ───────────────────────────────────────
local AutoSub = MainTab:AddSubTab("Automation", "zap")
local MeltGroup = AutoSub:AddLeftGroupbox("Melt", "flame")
local SellGroup = AutoSub:AddRightGroupbox("Sell", "coins")
local CollectGroup = AutoSub:AddLeftGroupbox("Collect", "package")
local SpinGroup = AutoSub:AddRightGroupbox("Spin", "refresh-cw")
local PlaytimeGroup = AutoSub:AddLeftGroupbox("Playtime", "clock")

MeltGroup:AddToggle("AutoMelt", {
    Text = "Auto Melt Ice",
    Default = false,
    Callback = function(v)
        STATE.AutoMelt = v
    end,
}):AddKeyPicker("AutoMeltKey", { Default = "None", Text = "Auto Melt Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

MeltGroup:AddSlider("MeltSpeed", {
    Text = "Melt Interval",
    Default = 0.05,
    Min = 0.02,
    Max = 0.5,
    Rounding = 2,
    Suffix = "s",
    Callback = function(v)
        STATE.AutoMeltSpeed = v
    end,
})

SellGroup:AddToggle("AutoSell", {
    Text = "Auto Sell",
    Default = false,
    Callback = function(v)
        STATE.AutoSell = v
    end,
}):AddKeyPicker("AutoSellKey", { Default = "None", Text = "Auto Sell Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

SellGroup:AddSlider("SellInterval", {
    Text = "Sell Interval",
    Default = 5,
    Min = 1,
    Max = 30,
    Rounding = 0,
    Suffix = "s",
    Callback = function(v)
        STATE.AutoSellInterval = v
    end,
})

SellGroup:AddButton({
    Text = "Sell All Now",
    Func = function()
        pcall(function() Remotes.SellAll:InvokeServer() end)
    end,
})

CollectGroup:AddToggle("AutoCollect", {
    Text = "Auto Collect Drops",
    Default = false,
    Callback = function(v)
        STATE.AutoCollect = v
    end,
})

SpinGroup:AddToggle("AutoSpin", {
    Text = "Auto Spin",
    Default = false,
    Callback = function(v)
        STATE.AutoSpin = v
    end,
})

SpinGroup:AddButton({
    Text = "Claim Free Spin",
    Func = function()
        pcall(function() Remotes.SpinClaim:FireServer() end)
    end,
})

SpinGroup:AddButton({
    Text = "Roll Spin",
    Func = function()
        pcall(function() Remotes.SpinRoll:InvokeServer() end)
    end,
})

PlaytimeGroup:AddToggle("AutoPlaytime", {
    Text = "Auto Claim Playtime",
    Default = false,
    Callback = function(v)
        STATE.AutoPlaytime = v
    end,
})

PlaytimeGroup:AddButton({
    Text = "Claim Playtime Now",
    Func = function()
        pcall(function() Remotes.ClaimPlaytimeReward:InvokeServer() end)
    end,
})

-- ─── MAIN: Teleport ─────────────────────────────────────────
local TeleSub = MainTab:AddSubTab("Teleport", "map-pin")
local TeleGroup = TeleSub:AddLeftGroupbox("Stage Teleport", "navigation")

TeleGroup:AddDropdown("TeleportDropdown", {
    Text = "Select Stage",
    Values = getZoneNames(),
    Default = "Zone 1",
    Multi = false,
    Callback = function(v)
        local num = tonumber(v:match("%d+"))
        if num then STATE.TeleportStage = num end
    end,
})

TeleGroup:AddButton({
    Text = "Teleport to Selected",
    Func = function()
        if _k and _k.v and _k.s then
            teleportToZone(STATE.TeleportStage)
        end
    end,
})

TeleGroup:AddButton({
    Text = "TP to Current Stage",
    Func = function()
        if _k and _k.v and _k.i then
            pcall(function()
                Remotes.TeleportToStage:FireServer()
            end)
        end
    end,
})

-- ─── SHOP: Upgrades ─────────────────────────────────────────
local UpgradeSub = ShopTab:AddSubTab("Upgrades", "arrow-up-circle")
local UpgradeGroup = UpgradeSub:AddLeftGroupbox("Upgrades", "trending-up")

UpgradeGroup:AddDropdown("UpgradeType", {
    Text = "Upgrade Type",
    Values = {"All", "Fire Power", "Speed", "Backpack"},
    Default = "All",
    Multi = false,
    Callback = function(v)
        STATE.AutoUpgradeType = v
    end,
})

UpgradeGroup:AddToggle("AutoBuyUpgrade", {
    Text = "Auto Buy Upgrades",
    Default = false,
    Callback = function(v)
        STATE.AutoBuyUpgrade = v
    end,
})

UpgradeGroup:AddButton({
    Text = "Buy Upgrade Now",
    Func = function()
        if _k and _k.v and _k.i then
            pcall(function() Remotes.BuyUpgrade:InvokeServer() end)
        end
    end,
})

-- ─── SHOP: Weapons ──────────────────────────────────────────
local WeaponSub = ShopTab:AddSubTab("Weapons", "swords")
local WeaponGroup = WeaponSub:AddLeftGroupbox("Weapons", "shield")

WeaponGroup:AddToggle("AutoBuyWeapon", {
    Text = "Auto Buy Best Weapon",
    Default = false,
    Callback = function(v)
        STATE.AutoBuyWeapon = v
    end,
})

WeaponGroup:AddButton({
    Text = "Buy Weapon Now",
    Func = function()
        if _k and _k.v and _k.i then
            pcall(function() Remotes.BuyWeapon:InvokeServer() end)
        end
    end,
})

-- ─── SHOP: Backpacks ────────────────────────────────────────
local BackpackGroup = WeaponSub:AddRightGroupbox("Backpacks", "package")

BackpackGroup:AddToggle("AutoBuyBackpack", {
    Text = "Auto Buy Backpack",
    Default = false,
    Callback = function(v)
        STATE.AutoBuyBackpack = v
    end,
})

BackpackGroup:AddButton({
    Text = "Buy Backpack Now",
    Func = function()
        if _k and _k.v and _k.i then
            pcall(function() Remotes.BuyBackpack:InvokeServer() end)
        end
    end,
})

-- ─── SHOP: Potions ──────────────────────────────────────────
local PotionGroup = WeaponSub:AddLeftGroupbox("Potions", "droplet")

PotionGroup:AddButton({
    Text = "Buy Potion",
    Func = function()
        if _k and _k.v and _k.s then
            pcall(function() Remotes.BuyPotion:InvokeServer() end)
        end
    end,
})


-- ─── PLAYER: Movement ──────────────────────────────────────
local MoveSub = PlayerTab:AddSubTab("Movement", "move")
local SpeedGroup = MoveSub:AddLeftGroupbox("Speed", "zap")
local JumpGroup = MoveSub:AddRightGroupbox("Jump", "arrow-up")

SpeedGroup:AddSlider("WalkSpeed", {
    Text = "Walk Speed",
    Default = 22,
    Min = 16,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        STATE.WalkSpeed = v
        local h = getHum()
        if h and _k and _k.v and _k.s then h.WalkSpeed = v end
    end,
})

SpeedGroup:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(v)
        STATE.Noclip = v
        setNoclip(v)
    end,
}):AddKeyPicker("NoclipKey", { Default = "None", Text = "Noclip Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

JumpGroup:AddSlider("JumpPower", {
    Text = "Jump Power",
    Default = 50,
    Min = 50,
    Max = 200,
    Rounding = 0,
    Callback = function(v)
        STATE.JumpPower = v
        local h = getHum()
        if h and _k and _k.v and _k.i then h.JumpPower = v end
    end,
})

JumpGroup:AddToggle("InfJump", {
    Text = "Infinite Jump",
    Default = false,
    Callback = function(v)
        STATE.InfiniteJump = v
        setInfiniteJump(v)
    end,
}):AddKeyPicker("InfJumpKey", { Default = "None", Text = "Infinite Jump Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

-- ─── PLAYER: Gravity ────────────────────────────────────────
local GravGroup = MoveSub:AddLeftGroupbox("Gravity", "down")

GravGroup:AddSlider("Gravity", {
    Text = "Gravity",
    Default = 196.2,
    Min = 0,
    Max = 500,
    Rounding = 1,
    Callback = function(v)
        STATE.Gravity = v
        if _k and _k.v and _verifyIntegrity() then
            Workspace.Gravity = v
        end
    end,
})

-- ─── VISUALS: ESP ───────────────────────────────────────────
local ESPSub = VisualsTab:AddSubTab("ESP", "eye")
local ESPGroup = ESPSub:AddLeftGroupbox("Player ESP", "users")

ESPGroup:AddToggle("ESPEnabled", {
    Text = "Enable ESP",
    Default = false,
    Callback = function(v)
        STATE.ESP = v
        if v then updateESP() else clearESP() end
    end,
}):AddKeyPicker("ESPKey", { Default = "None", Text = "ESP Key", Mode = "Toggle", SyncToggleState = true, NoUI = false })

ESPGroup:AddToggle("ESPNames", {
    Text = "Show Names",
    Default = true,
    Callback = function(v)
        STATE.ESPNames = v
        if STATE.ESP then updateESP() end
    end,
})

ESPGroup:AddToggle("ESPDistance", {
    Text = "Show Distance",
    Default = true,
    Callback = function(v)
        STATE.ESPDistance = v
        if STATE.ESP then updateESP() end
    end,
})

ESPGroup:AddColorPicker("ESPColor", {
    Text = "ESP Color",
    Default = Color3.fromRGB(255, 100, 100),
    Callback = function(v)
        STATE.ESPColor = v
        if STATE.ESP then updateESP() end
    end,
})

ESPGroup:AddSlider("ESPRefresh", {
    Text = "Refresh Rate",
    Default = 2,
    Min = 0.5,
    Max = 10,
    Rounding = 1,
    Suffix = "s",
})

-- ─── VISUALS: World ─────────────────────────────────────────
local WorldGroup = ESPSub:AddRightGroupbox("World", "globe")

WorldGroup:AddButton({
    Text = "Full Bright",
    Func = function()
        if _k and _k.v and _k.i then
            local light = Instance.new("PointLight")
            light.Brightness = 1
            light.Range = 100
            light.Parent = getHRP()
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
        end
    end,
})

WorldGroup:AddButton({
    Text = "Remove Fog",
    Func = function()
        if _k and _k.v and _k.s then
            game:GetService("Lighting").FogEnd = 999999
            game:GetService("Lighting").FogStart = 0
            game:GetService("Lighting").Atmosphere.Density = 0
        end
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════════════════════════
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("melttheice")
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "menu")
MenuGroup:AddToggle("MenuToggle", {
    Text = "Menu Toggle",
    Default = true,
    Callback = function() end,
}):AddKeyPicker("MenuKeybind", { Default = "RightShift", Text = "Menu Keybind", Mode = "Toggle", NoUI = true })

MenuGroup:AddButton({
    Text = "Unload Script",
    Func = function()
        clearESP()
        setNoclip(false)
        setInfiniteJump(false)
        Workspace.Gravity = 196.2
        pcall(function() Library:Notify({ Title = "Ivory", Description = "Unloaded", Type = "Info", Time = 3 }) end)
        task.wait(1)
        pcall(function() _kg:Destroy() end)
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- MAIN LOOPS
-- ═══════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(STATE.AutoMeltSpeed)
        if STATE.AutoMelt and _k and _k.v and _k.i then
            pcall(function()
                local tool = getTool()
                if tool then
                    tool:Activate()
                    task.wait(0.05)
                    tool:Deactivate()
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(STATE.AutoSellInterval)
        if STATE.AutoSell and _k and _k.v and _k.s then
            pcall(function() Remotes.SellAll:InvokeServer() end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if STATE.AutoCollect and _k and _k.v and _k.i then
            pcall(function()
                local hrp = getHRP()
                if hrp then
                    for _, obj in ipairs(Map:GetDescendants()) do
                        if obj:IsA("BasePart") and obj.Name:match("Drop|Loot|Coin|Medal|Cash") then
                            local dist = (obj.Position - hrp.Position).Magnitude
                            if dist < 100 then
                                obj.CFrame = hrp.CFrame
                            end
                        end
                    end
                end
            end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if STATE.AutoBuyWeapon and _k and _k.v and _k.i then
            pcall(function() Remotes.BuyWeapon:InvokeServer() end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if STATE.AutoBuyBackpack and _k and _k.v and _k.s then
            pcall(function() Remotes.BuyBackpack:InvokeServer() end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(3)
        if STATE.AutoBuyUpgrade and _k and _k.v and _k.i then
            pcall(function() Remotes.BuyUpgrade:InvokeServer() end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(5)
        if STATE.AutoSpin and _k and _k.v and _k.s then
            pcall(function() Remotes.SpinRoll:InvokeServer() end)
            task.wait(1)
            pcall(function() Remotes.SpinClaim:FireServer() end)
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        if STATE.AutoPlaytime and _k and _k.v and _k.i then
            pcall(function() Remotes.ClaimPlaytimeReward:InvokeServer() end)
        end
    end
end)

-- Apply speed on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    local h = char:WaitForChild("Humanoid", 5)
    if h and _k and _k.v and _k.s then
        h.WalkSpeed = STATE.WalkSpeed
    end
    if h and _k and _k.v and _k.i then
        h.JumpPower = STATE.JumpPower
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- NOTIFICATION
-- ═══════════════════════════════════════════════════════════════
pcall(function()
    Library:Notify({
        Title = "Ivory",
        Description = "Melt The Ice loaded!",
        Type = "Success",
        Time = 5,
    })
end)
