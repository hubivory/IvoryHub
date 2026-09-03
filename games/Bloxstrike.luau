local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local hitboxsafe = true
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"

local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = 'Ivory | Bloxstrike',
    Icon = "swords",
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    Footer = "made by Veqxoo"
})

local Tabs = {
    Combat = Window:AddTab('Combat', 'swords'),
    Visuals = Window:AddTab('Visuals', 'eye'),
    Weapons = Window:AddTab('Weapons', 'crosshair'),
    StyleChanger = Window:AddTab('StyleChanger', 'paintbrush'),
    Settings = Window:AddTab('Settings', 'settings'),
}

local CharactersFolder = Workspace:WaitForChild("Characters", 10)

local function GetCharacter(player)
    return CharactersFolder and CharactersFolder:FindFirstChild(player.Name)
end

local function IsEnemy(p)
    if p == LocalPlayer then return false end
    local myTeam = LocalPlayer:GetAttribute("Team")
    local theirTeam = p:GetAttribute("Team")
    if myTeam and theirTeam then
        return myTeam ~= theirTeam
    end
    return false
end

local function IsAlive(player)
    local char = GetCharacter(player)
    if not char then return false end
    local dead = player:GetAttribute("Dead")
    if dead == true or dead == "true" then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return true
end

-- ═══════════════════════════════════════════
-- COMBAT TAB
-- ═══════════════════════════════════════════

local DiscordBox = Tabs.Combat:AddLeftGroupbox("Discord", "users")
DiscordBox:AddLabel("JOIN DISCORD FOR DUPE")
DiscordBox:AddButton("Copy Link", function()
    if setclipboard then setclipboard("https://discord.gg/ivory") end
    Library:Notify({ Title = "Discord", Description = "Copied to clipboard!", Time = 3 })
end)

local CombatSilentBox = Tabs.Combat:AddLeftGroupbox("Silent Aim", "target")

CombatSilentBox:AddToggle("SilentAim", {
    Text = "Enable Silent Aim",
    Default = false,
    Disabled = typeof(hookfunction) ~= "function",
    DisabledTooltip = "This feature is not available on your executor.",
})

Toggles.SilentAim:AddKeyPicker("SilentAimHoldkey", {
    Text = "Hold Key",
    Default = "MB2",
    Mode = "Hold",
})

local BlatantDependencyBox = CombatSilentBox:AddDependencyBox()

BlatantDependencyBox:AddDropdown("SilentHitPart", {
    Text = "Hit Selection",
    Values = {
        "HumanoidRootPart", "Head", "LeftLowerArm", "LowerTorso",
        "RightHand", "RightLowerArm", "LeftFoot", "LeftHand",
        "RightFoot", "RightLowerLeg", "LeftLowerLeg", "RightUpperArm",
        "LeftUpperArm", "UpperTorso", "RightUpperLeg", "LeftUpperLeg"
    },
    Default = "HumanoidRootPart",
})

BlatantDependencyBox:AddToggle("SilentTeamCheck", {
    Text = "Enable Team Check",
    Default = true,
})

BlatantDependencyBox:AddToggle("SilentWallbang", {
    Text = "Wallbang",
    Default = false,
})

CombatSilentBox:AddDivider()

CombatSilentBox:AddToggle("SilentAimVisibleCheck", {
    Text = "Visibility Check",
    Default = true,
})

local CombatRageBox = Tabs.Combat:AddRightGroupbox("Rage", "bolt")

CombatRageBox:AddToggle("Ragebot", {
    Text = "Enable Ragebot",
    Default = false,
    Disabled = typeof(hookfunction) ~= "function",
    DisabledTooltip = "This feature is not available on your executor.",
})

CombatRageBox:AddDropdown("RageHitPart", {
    Text = "Hit Selection",
    Values = {"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso"},
    Default = "HumanoidRootPart",
})

CombatRageBox:AddSlider("RageDelay", {
    Text = "Shoot Delay",
    Default = 0.02,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
    Compact = true,
})

local RageDependencyBox = CombatRageBox:AddDependencyBox()

RageDependencyBox:AddToggle("RagebotTeamCheck", {
    Text = "Enable Team Check",
    Default = true,
})

RageDependencyBox:SetupDependencies({
    {Toggles.Ragebot, true}
})

local CombatTriggerBox = Tabs.Combat:AddRightGroupbox("Triggerbot", "zap")

CombatTriggerBox:AddToggle("Triggerbot", {
    Text = "Enable Triggerbot",
    Default = false,
})

CombatTriggerBox:AddSlider("TriggerbotDelay", {
    Text = "Trigger Delay",
    Default = 0,
    Min = 0,
    Max = 0.5,
    Rounding = 2,
    Compact = true,
})

local HitboxBox = Tabs.Combat:AddLeftGroupbox("Hitbox Expander", "expand")

HitboxBox:AddToggle("Hitbox", {
    Text = "Enable Hitbox Expander",
    Default = false,
})

HitboxBox:AddSlider("HitboxSize", {
    Text = "Hitbox Size",
    Default = 50,
    Min = 2,
    Max = 100,
    Rounding = 0,
})

HitboxBox:AddSlider("HitboxTransparency", {
    Text = "Hitbox Transparency",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
})

-- ═══════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════

local HighlightESPBox = Tabs.Visuals:AddLeftGroupbox("Highlight ESP", "eye")

HighlightESPBox:AddToggle("HighlightESP", {
    Text = "Enable Highlight",
    Default = false,
})

HighlightESPBox:AddLabel("Fill Color"):AddColorPicker("HighlightFillColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Title = "Fill Color",
})

HighlightESPBox:AddSlider("HighlightFillTransparency", {
    Text = "Fill Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Rounding = 0,
})

HighlightESPBox:AddLabel("Outline Color"):AddColorPicker("HighlightOutlineColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Outline Color",
})

HighlightESPBox:AddSlider("HighlightOutlineTransparency", {
    Text = "Outline Transparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Rounding = 0,
})

-- ═══════════════════════════════════════════
-- HIGHLIGHT ESP
-- ═══════════════════════════════════════════

local Highlights = {}

local function UpdateHighlights()
    if not CharactersFolder then return end
    for _, child in next, CharactersFolder:GetChildren() do
        if child:IsA("Model") and child:FindFirstChild("HumanoidRootPart") then
            local player = Players:FindFirstChild(child.Name)
            if player and player ~= LocalPlayer and Toggles.HighlightESP.Value and IsEnemy(player) and IsAlive(player) then
                if not Highlights[player] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "IvoryHighlight"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = child
                    Highlights[player] = hl
                end
                local hl = Highlights[player]
                hl.FillColor = Options.HighlightFillColor.Value
                hl.FillTransparency = Options.HighlightFillTransparency.Value / 100
                hl.OutlineColor = Options.HighlightOutlineColor.Value
                hl.OutlineTransparency = Options.HighlightOutlineTransparency.Value / 100
                hl.Enabled = true
                if hl.Parent ~= child then hl.Parent = child end
            else
                if Highlights[player] then Highlights[player]:Destroy(); Highlights[player] = nil end
            end
        end
    end
end

local function DestroyAllHighlights()
    for player, hl in next, Highlights do if hl and hl.Parent then hl:Destroy() end end
    Highlights = {}
end

Toggles.HighlightESP:OnChanged(function() if not Toggles.HighlightESP.Value then DestroyAllHighlights() end end)

if CharactersFolder then
    CharactersFolder.ChildRemoved:Connect(function(child)
        local player = Players:FindFirstChild(child.Name)
        if player and Highlights[player] then Highlights[player]:Destroy(); Highlights[player] = nil end
    end)
end

-- ═══════════════════════════════════════════
-- SKIN CHANGER
-- ═══════════════════════════════════════════

local SkinsBox = Tabs.StyleChanger:AddLeftGroupbox("Skins", "palette")
local Skins2Box = Tabs.StyleChanger:AddRightGroupbox("Skins 2", "brush")

local ApplySkinTextures = nil

for _, obj in next, getgc() do
    if type(obj) == "function" and debug.getinfo(obj).name == "ApplySkinTextures" then
        ApplySkinTextures = obj
        break
    end
end

local function getCurrentWeapon() return Workspace.Camera:FindFirstChildOfClass("Model") end

local Skins = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Skins")

local skinList = {}
for key, skin in next, Skins:GetChildren() do
    if #skin:GetChildren() > 1 then
        table.insert(skinList, skin)
    end
end

local midPoint = math.ceil(#skinList / 2)

for i = 1, midPoint do
    local skin = skinList[i]
    SkinsBox:AddDropdown(tostring(skin), {
        Text = tostring(skin),
        Values = skin:GetChildren(),
        Default = 1,
        Multi = false,
    })
end

for i = midPoint + 1, #skinList do
    local skin = skinList[i]
    Skins2Box:AddDropdown(tostring(skin), {
        Text = tostring(skin),
        Values = skin:GetChildren(),
        Default = 1,
        Multi = false,
    })
end

local lastWeapon = nil
local lastSkinValue = nil

task.spawn(function()
    while task.wait(0.1) do
        local currweapon = getCurrentWeapon()
        if currweapon then
            local option = Options[tostring(currweapon)]
            local skinValue = option and option.Value

            if currweapon ~= lastWeapon or skinValue ~= lastSkinValue then
                pcall(function()
                    if skinValue then
                        ApplySkinTextures(currweapon, skinValue.Camera["Factory New"])
                    end
                end)
                lastWeapon = currweapon
                lastSkinValue = skinValue
            end
        else
            lastWeapon = nil
            lastSkinValue = nil
        end
    end
end)

-- ═══════════════════════════════════════════
-- WEAPONS TAB
-- ═══════════════════════════════════════════

local WeaponsTab = Tabs.Weapons
local WeaponsBox = WeaponsTab:AddLeftGroupbox("Weapons", "crosshair")

WeaponsBox:AddToggle("Firerate", {
    Text = "Enable Firerate",
    Default = false,
})

WeaponsBox:AddSlider("FirerateSlider", {
    Text = "Firerate",
    Default = 0.05,
    Min = 0.01,
    Max = 0.5,
    Rounding = 2,
})

WeaponsBox:AddToggle("NoRecoil", {
    Text = "No Recoil",
    Default = false,
})

WeaponsBox:AddToggle("NoSpread", {
    Text = "No Spread",
    Default = false,
})

WeaponsBox:AddToggle("Antiflashbang", {
    Text = "Anti Flashbang",
    Default = false,
})

WeaponsBox:AddToggle("Antismoke", {
    Text = "Anti Smoke",
    Default = false,
})

-- ═══════════════════════════════════════════
-- TARGETING
-- ═══════════════════════════════════════════

local SilentTarget = nil
local RageTarget = nil

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true

local frameCounter = 0

local function isVisible(target)
    local lchar = GetCharacter(Players.LocalPlayer)
    rayParams.FilterDescendantsInstances = {lchar}
    local result = Workspace:Raycast(Workspace.CurrentCamera.CFrame.Position, target.Position - Workspace.CurrentCamera.CFrame.Position, rayParams)
    if result then
        local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
        if hitModel then return Players:FindFirstChild(hitModel.Name) ~= nil end
    end
    return true
end

local function FindAllTargets()
    local cam = Workspace.CurrentCamera
    local lchar = GetCharacter(Players.LocalPlayer)
    if not lchar or not lchar:FindFirstChild("Head") then return end
    local lHeadPos = lchar.Head.Position
    local screenCenter = cam.ViewportSize / 2
    local sDist, sClose = math.huge, nil
    local rDist, rClose = math.huge, nil

    for _, v in next, Players:GetPlayers() do
        if v == LocalPlayer then continue end
        local char = GetCharacter(v)
        if not char then continue end
        if v:GetAttribute("Dead") == true or v:GetAttribute("Dead") == "true" then continue end
        local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end
        local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
        local enemy = IsEnemy(v)

        if Toggles.Ragebot.Value and enemy then
            local rPart = char:FindFirstChild(Options.RageHitPart.Value) or targetPart
            local alive = true
            if Toggles.RagebotVisibleCheck and Toggles.RagebotVisibleCheck.Value and not onScreen then alive = false end
            if alive then local rd = (lHeadPos - rPart.Position).Magnitude; if rd < rDist then rDist = rd; rClose = rPart end end
        end
        if Toggles.SilentAim.Value and onScreen then
            if not Toggles.SilentTeamCheck.Value or enemy then
                local sd = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                if sd < sDist then
                    if not Toggles.SilentWallbang.Value and not isVisible(targetPart) then continue end
                    sDist = sd; sClose = targetPart
                end
            end
        end
    end
    SilentTarget = sClose; RageTarget = rClose
end

-- ═══════════════════════════════════════════
-- MAIN RENDER LOOP
-- ═══════════════════════════════════════════

RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1

    if frameCounter % 3 == 0 then
        FindAllTargets()
        UpdateHighlights()
    end

    for _, player in next, Players:GetPlayers() do
        if player ~= LocalPlayer then
            local char = GetCharacter(player)
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if Toggles.Hitbox.Value and not IsEnemy(player) and hitboxsafe then
                    hrp.Size = Vector3.new(Options.HitboxSize.Value, Options.HitboxSize.Value, Options.HitboxSize.Value)
                    hrp.Transparency = Options.HitboxTransparency.Value
                else
                    if hrp.Size.X ~= 2 then hrp.Size = Vector3.new(2, 2, 2); hrp.Transparency = 1 end
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════
-- HOOKS & GAME FUNCTIONS
-- ═══════════════════════════════════════════

local original = {}
local firerateobjs = {}
local SendFunc = nil
local getCurrentEquipped = nil

pcall(function()
    for _, obj in next, filtergc("table", {Keys = {"FireRate"}}) do
        pcall(function() table.insert(original, table.clone(obj)); table.insert(firerateobjs, obj) end)
    end
    for _, obj in next, filtergc("table", {Keys = {"setWeaponRecoil"}}) do
        pcall(function() local old; old = hookfunction(obj.setWeaponRecoil, function(...) if Toggles.NoRecoil.Value then return end; return old(...) end) end)
    end
    for _, obj in next, filtergc("function", {Name = "calculateRecoilOffset"}) do
        pcall(function() local old; old = hookfunction(obj, function(...) if Toggles.NoRecoil.Value then return UDim2.new() end; return old(...) end) end)
    end
    for _, obj in next, filtergc("table", {Keys = {"weaponKick"}}) do
        pcall(function() local old; old = hookfunction(obj.weaponKick, function(p1,p2) if Toggles.NoRecoil.Value then return end; return old(p1,p2) end) end)
    end
    for _, obj in next, filtergc("table", {Keys = {"getTrueSpread"}}) do
        pcall(function() local old; old = hookfunction(obj.getTrueSpread, function(p1) if Toggles.NoSpread.Value then return 0 end; return old(p1) end) end)
    end
    for _, obj in next, filtergc("function", {Name = "Flash"}) do
        pcall(function() local old; old = hookfunction(obj, function(...) if Toggles.Antiflashbang.Value then return end; return old(...) end) end)
    end
    for _, obj in next, filtergc("function", {Name = "CreateVoxel"}) do
        pcall(function()
            if debug.getupvalue(obj, 1) and tostring(debug.getupvalue(obj, 1)) == "Smoke" then
                local old; old = hookfunction(obj, function(...) if Toggles.Antismoke.Value then return end; return old(...) end)
            end
        end)
    end
    for _, obj in next, filtergc("table", {Keys = {"shoot"}}) do
        pcall(function()
            if obj.shoot and typeof(obj.shoot) == "function" and #debug.getupvalues(obj.shoot) == 26 then
                SendFunc = debug.getupvalue(obj.shoot, 14).Inventory.ShootWeapon.Send
            end
        end)
    end
    for _, obj in next, filtergc("table", {Keys = {"getCurrentEquipped"}}) do
        pcall(function() getCurrentEquipped = obj.getCurrentEquipped end)
    end
end)

local function getEquipped()
    local success, result = pcall(function() return debug.getupvalue(getCurrentEquipped, 1).CurrentEquipped end)
    if not success then return nil end
    return result
end

local Weapon = nil
task.spawn(function()
    while task.wait(1) do
        pcall(function() if getEquipped then Weapon = getEquipped() end end)
    end
end)

local old56
pcall(function()
    old56 = hookfunction(task.wait, function(t)
        if t == 5 then hitboxsafe = true; t = 9e9 end
        return old56(t)
    end)
end)

task.spawn(function()
    repeat wait() until hitboxsafe
    Library:Notify({ Title = "Success", Description = "Hitbox will now work", Time = 4 })
end)

task.spawn(function()
    while true do
        task.wait(Options.RageDelay.Value or 0.02)
        if Toggles.Ragebot.Value and RageTarget and Weapon and Weapon.IsEquipped and Weapon.Rounds > 0 then
            Weapon:shoot()
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Options.TriggerbotDelay.Value or 0)
        if Toggles.Triggerbot.Value then
            local mouse = LocalPlayer:GetMouse()
            if mouse and mouse.Target then
                local char = mouse.Target:FindFirstAncestorOfClass("Model")
                if not char then continue end
                local player = Players:FindFirstChild(char.Name)
                if not player or player == LocalPlayer then continue end
                if char:GetAttribute("Dead") == true or char:GetAttribute("Dead") == "true" then continue end
                if IsEnemy(player) then
                    if Weapon and Weapon.IsEquipped and Weapon.Rounds > 0 then Weapon:shoot() end
                end
            end
        end
    end
end)

local oldshoot
pcall(function()
    oldshoot = hookfunction(SendFunc, function(...)
        local args = {...}
        if args[1].Bullets[1].Hits[1] then
            if Toggles.Ragebot.Value and RageTarget then
                args[1].Bullets[1].Hits[1].Instance = RageTarget
                args[1].Bullets[1].Hits[1].Position = RageTarget.Position
            end
            if Toggles.SilentAim.Value and SilentTarget then
                args[1].Bullets[1].Hits[1].Instance = SilentTarget
                args[1].Bullets[1].Hits[1].Position = SilentTarget.Position
            end
        end
        return oldshoot(unpack(args))
    end)
end)

task.spawn(function()
    while task.wait(0.05) do
        pcall(function()
            if Toggles.Firerate.Value then
                for _, obj in next, firerateobjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", math.max(Options.FirerateSlider.Value, 0.01))
                        setreadonly(obj, true)
                    end)
                end
            else
                for i, obj in next, firerateobjs do
                    pcall(function()
                        setreadonly(obj, false)
                        rawset(obj, "FireRate", original[i].FireRate)
                        setreadonly(obj, true)
                    end)
                end
            end
        end)
    end
end)

-- ═══════════════════════════════════════════
-- SETTINGS
-- ═══════════════════════════════════════════

local CreditGroup = Tabs.Settings:AddLeftGroupbox("Credits", "heart")
CreditGroup:AddLabel("CREDIT_PLACEHOLDER")

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("Ivoryhub")
SaveManager:SetFolder("Ivoryhub/bloxstrike")
SaveManager:SetSubFolder("bloxstrike")
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu", "settings")
local originalParent = Library.ScreenGui.Parent

MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    Text = "Menu Keybind",
    SyncToggleState = false,
    Mode = "Toggle",
    Callback = function(state)
        if not Library or not Library.ScreenGui then return end
        Library.Toggled = state
        if state then
            Library.ScreenGui.Parent = originalParent
            UserInputService.MouseIconEnabled = not Library.ShowCustomCursor
        else
            pcall(function() Library.ScreenGui.Parent = game:GetService("Lighting") end)
            UserInputService.MouseIconEnabled = true
        end
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

MenuGroup:AddButton("Join Discord", function()
    if setclipboard then setclipboard("https://discord.gg/ivory") end
    Library:Notify({ Title = "Discord", Description = "Copied to clipboard!", Time = 3 })
end)

SaveManager:Load()
SaveManager:LoadAutoloadConfig()

task.spawn(function()
    task.wait(1)
    local gui = Library.ScreenGui
    if not gui then return end
    local main = gui:FindFirstChild("Main", true)
    if main then
        main.Size = UDim2.new(0, 820, 0, 600)
    end
    for _, desc in next, gui:GetDescendants() do
        if desc:IsA("TextLabel") then
            if desc.Text == "JOIN DISCORD FOR DUPE" then
                desc.TextColor3 = Color3.fromRGB(180, 0, 255)
                desc.TextSize = 18
                desc.RichText = false
                pcall(function() desc.Font = Enum.Font.GothamBlack end)
            elseif desc.Text:find("Mommy") or desc.Text == "CREDIT_PLACEHOLDER" then
                desc.RichText = false
                desc.Text = "Made by Mommy Veqxoo </3"
                desc.TextColor3 = Color3.fromRGB(255, 0, 200)
                desc.TextSize = 20
                desc.TextWrapped = true
                pcall(function() desc.Font = Enum.Font.GothamBlack end)
            end
        end
    end
end)

print("[Ivory Hub] Loaded - RightShift for menu")
