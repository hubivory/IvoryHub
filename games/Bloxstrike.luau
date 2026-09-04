local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local hitboxsafe = true

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

local Window = Library.CreateWindow({
    Name = 'Ivory | Bloxstrike',
    Width = 460,
    Height = 360,
})

local Tabs = {
    Combat = Window:CreateTab({ Name = 'Combat' }),
    Visuals = Window:CreateTab({ Name = 'Visuals' }),
    Weapons = Window:CreateTab({ Name = 'Weapons' }),
    StyleChanger = Window:CreateTab({ Name = 'StyleChanger' }),
    Settings = Window:CreateTab({ Name = 'Settings' }),
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

local DiscordSection = Tabs.Combat:CreateSection("Discord")
DiscordSection:CreateLabel("JOIN DISCORD FOR DUPE")
DiscordSection:CreateButton({Name = "Copy Link", Callback = function()
    if setclipboard then setclipboard("https://discord.gg/ivory") end
    Library.Notify({ Title = "Discord", Content = "Copied to clipboard!", Duration = 3 })
end})

local CombatSilentSection = Tabs.Combat:CreateSection("Silent Aim")

CombatSilentSection:CreateToggle({
    Name = "Enable Silent Aim",
    CurrentValue = false,
})

CombatSilentSection:CreateKeybind({
    Name = "Hold Key",
    CurrentKeybind = "MB2",
})

CombatSilentSection:CreateDropdown({
    Name = "Hit Selection",
    Options = {
        "HumanoidRootPart", "Head", "LeftLowerArm", "LowerTorso",
        "RightHand", "RightLowerArm", "LeftFoot", "LeftHand",
        "RightFoot", "RightLowerLeg", "LeftLowerLeg", "RightUpperArm",
        "LeftUpperArm", "UpperTorso", "RightUpperLeg", "LeftUpperLeg"
    },
    CurrentOption = "HumanoidRootPart",
})

CombatSilentSection:CreateToggle({
    Name = "Enable Team Check",
    CurrentValue = true,
})

CombatSilentSection:CreateToggle({
    Name = "Wallbang",
    CurrentValue = false,
})

CombatSilentSection:CreateDivider()

CombatSilentSection:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = true,
})

local CombatRageSection = Tabs.Combat:CreateSection("Rage")

CombatRageSection:CreateToggle({
    Name = "Enable Ragebot",
    CurrentValue = false,
})

CombatRageSection:CreateDropdown({
    Name = "Hit Selection",
    Options = {"HumanoidRootPart", "Head", "UpperTorso", "LowerTorso"},
    CurrentOption = "HumanoidRootPart",
})

CombatRageSection:CreateSlider({
    Name = "Shoot Delay",
    Range = {0.01, 0.5},
    Increment = 0.01,
    CurrentValue = 0.02,
})

CombatRageSection:CreateToggle({
    Name = "Enable Team Check",
    CurrentValue = true,
})

local CombatTriggerSection = Tabs.Combat:CreateSection("Triggerbot")

CombatTriggerSection:CreateToggle({
    Name = "Enable Triggerbot",
    CurrentValue = false,
})

CombatTriggerSection:CreateSlider({
    Name = "Trigger Delay",
    Range = {0, 0.5},
    Increment = 0.01,
    CurrentValue = 0,
})

local HitboxSection = Tabs.Combat:CreateSection("Hitbox Expander")

HitboxSection:CreateToggle({
    Name = "Enable Hitbox Expander",
    CurrentValue = false,
})

HitboxSection:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 100},
    Increment = 1,
    CurrentValue = 50,
})

HitboxSection:CreateSlider({
    Name = "Hitbox Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
})

-- ═══════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════

local HighlightESPSection = Tabs.Visuals:CreateSection("Highlight ESP")

HighlightESPSection:CreateToggle({
    Name = "Enable Highlight",
    CurrentValue = false,
})

HighlightESPSection:CreateColorPicker({
    Name = "Fill Color",
    Color = Color3.fromRGB(255, 0, 0),
})

HighlightESPSection:CreateSlider({
    Name = "Fill Transparency",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 50,
})

HighlightESPSection:CreateColorPicker({
    Name = "Outline Color",
    Color = Color3.fromRGB(255, 255, 255),
})

HighlightESPSection:CreateSlider({
    Name = "Outline Transparency",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 0,
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

local SkinsSection = Tabs.StyleChanger:CreateSection("Skins")
local Skins2Section = Tabs.StyleChanger:CreateSection("Skins 2")

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
    SkinsSection:CreateDropdown({
        Name = tostring(skin),
        Options = skin:GetChildren(),
        CurrentOption = 1,
    })
end

for i = midPoint + 1, #skinList do
    local skin = skinList[i]
    Skins2Section:CreateDropdown({
        Name = tostring(skin),
        Options = skin:GetChildren(),
        CurrentOption = 1,
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
local WeaponsSection = WeaponsTab:CreateSection("Weapons")

WeaponsSection:CreateToggle({
    Name = "Enable Firerate",
    CurrentValue = false,
})

WeaponsSection:CreateSlider({
    Name = "Firerate",
    Range = {0.01, 0.5},
    Increment = 0.01,
    CurrentValue = 0.05,
})

WeaponsSection:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
})

WeaponsSection:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
})

WeaponsSection:CreateToggle({
    Name = "Anti Flashbang",
    CurrentValue = false,
})

WeaponsSection:CreateToggle({
    Name = "Anti Smoke",
    CurrentValue = false,
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
    Library.Notify({ Title = "Success", Content = "Hitbox will now work", Duration = 4 })
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

local CreditSection = Tabs.Settings:CreateSection("Credits")
CreditSection:CreateLabel("Made by Mommy Veqxoo < / 3")

local MenuSection = Tabs.Settings:CreateSection("Menu")
local originalParent = Library.ScreenGui.Parent

MenuSection:CreateKeybind({
    Name = "Menu Keybind",
    CurrentKeybind = "RightShift",
})

MenuSection:CreateDivider()

MenuSection:CreateButton({Name = "Unload", Callback = function()
    Library:Unload()
end})

MenuSection:CreateButton({Name = "Join Discord", Callback = function()
    if setclipboard then setclipboard("https://discord.gg/ivory") end
    Library.Notify({ Title = "Discord", Content = "Copied to clipboard!", Duration = 3 })
end})

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
