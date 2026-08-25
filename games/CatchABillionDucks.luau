local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local LocalPlayer = Players.LocalPlayer

local Value
pcall(function()
    Value = require(ReplicatedStorage:FindFirstChild("UmePointer").Value)
end)
if not Value then warn("[Ivory] Failed to load UmePointer") return end
local Network = Value.Network

local cfg = {
    autoJoinGame = false, autoBuyWeapons = false, autoEquipBestDog = false,
    autoOpenCrates = false, autoRollDailyQuests = false, autoBuyUpgrades = false,
    autoClaimGroup = false, crateAmount = 1, priorityUpgrade = "Damage",
    autoShoot = false, silentAim = false, killAura = false, killAuraRadius = 200,
    autoTargetMadBirds = false, stayBehindSpawn = false, rapidFire = false,
    removeGameplayPaused = false, autoReturnLobby = false, autoSellDucks = false,
    autoCollectDrops = false, autoSkipDay = false, noclip = false,
}

local function getChar()
    return LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isLobby()
    return game.PlaceId == 100293509865504
end

local function isGame()
    return game.PlaceId == 120617974337690
end

local function isAlive()
    local char, hrp = getChar()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hrp and hum and hum.Health > 0
end

local function hasWeapon()
    local char = LocalPlayer.Character
    if not char then return false end
    if char:FindFirstChildOfClass("Tool") then return true end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then return true end
        end
    end
    return false
end

local function getAmmo()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("AmmoGui")
    if not gui then return 0 end
    local frame = gui:FindFirstChild("AmmoFrame", true)
    if not frame then return 0 end
    local container = frame:FindFirstChild("Container", true)
    if not container then return 0 end
    local ammoContainer = container:FindFirstChild("AmmoContainer", true)
    if not ammoContainer then return 0 end
    local amount = ammoContainer:FindFirstChild("AmmoAmount")
    if not amount then return 0 end
    if amount.Text:find("Reloading") then return 0 end
    return tonumber(amount.Text) or 0
end

local function isReloading()
    local gui = LocalPlayer.PlayerGui:FindFirstChild("AmmoGui")
    if not gui then return false end
    local frame = gui:FindFirstChild("AmmoFrame", true)
    if not frame then return false end
    local container = frame:FindFirstChild("Container", true)
    if not container then return false end
    local ammoContainer = container:FindFirstChild("AmmoContainer", true)
    if not ammoContainer then return false end
    local amount = ammoContainer:FindFirstChild("AmmoAmount")
    if not amount then return false end
    return amount.Text:find("Reloading") ~= nil
end

local shotRecord = {}
local SHOT_COOLDOWN = 2.5
local _reloadHooked = false
local _origReload = nil

local function ensureReloadHook()
    if _reloadHooked then return end
    _reloadHooked = true
    local reloadFn = filtergc("function", {
        Name = "reload",
        Constants = {"WeaponController_Reload", "SetFiring", "SetReloading"},
    }, true)
    if reloadFn then
        _origReload = hookfunction(reloadFn, newcclosure(function(...)
            if cfg.autoShoot and getAmmo() > 0 then return end
            return _origReload(...)
        end))
    end
end

local function wasRecentlyShot(name)
    local t = shotRecord[name]
    return t and (tick() - t) < SHOT_COOLDOWN
end

local function recordShot(name)
    shotRecord[name] = tick()
end

local function cleanupShotRecord()
    local now = tick()
    for k, v in pairs(shotRecord) do
        if (now - v) > SHOT_COOLDOWN * 2 then
            shotRecord[k] = nil
        end
    end
end

local function getDucks()
    local ducks = {}
    for _, v in ipairs(workspace.Ume:GetChildren()) do
        if v.Name:find("DuckController_Client") and v:IsA("Model") then
            local root = v:FindFirstChild("RootPart")
            local hitbox = v:FindFirstChild("Hitbox")
            local lovpoly = v:FindFirstChild("LovPoly")
            if root and (hitbox or lovpoly) then
                local targetPart = hitbox or lovpoly
                if not targetPart or targetPart.Transparency >= 1 then
                    targetPart = lovpoly or root
                end
                table.insert(ducks, { model = v, root = root, hitbox = targetPart })
            end
        end
    end
    local duckFolder = workspace.Ume:FindFirstChild("DuckController_LandedDucks")
    if duckFolder then
        for _, v in ipairs(duckFolder:GetChildren()) do
            if v:IsA("Model") then
                local root = v:FindFirstChild("RootPart")
                local lovpoly = v:FindFirstChild("LovPoly")
                if root and lovpoly and lovpoly.Transparency < 1 then
                    table.insert(ducks, { model = v, root = root, hitbox = lovpoly })
                end
            end
        end
    end
    return ducks
end

local function isMadBird(duck)
    return duck.model:FindFirstChild("DuckController_AngryHighlight") ~= nil
end

local function getBoss()
    local boss = workspace.Ume and workspace.Ume:FindFirstChild("BossController_Client_1")
    if boss then
        local hitbox = boss:FindFirstChild("Hitbox")
        local root = boss:FindFirstChild("RootPart") or boss:FindFirstChild("HumanoidRootPart")
        local target = hitbox or root
        if target then return boss, target end
    end
    return nil
end

local function findTarget(prioritizeMad, radius)
    local _, hrp = getChar()
    if not hrp then return nil end
    if prioritizeMad then
        for _, duck in ipairs(getDucks()) do
            if isMadBird(duck) and not wasRecentlyShot(duck.model.Name) then
                return duck.hitbox or duck.root
            end
        end
    end
    local boss, bossRoot = getBoss()
    if boss and not wasRecentlyShot("boss") then
        return bossRoot
    end
    local closest, closestDist = nil, radius or math.huge
    for _, duck in ipairs(getDucks()) do
        if not wasRecentlyShot(duck.model.Name) then
            local t = duck.hitbox or duck.root
            local d = (t.Position - hrp.Position).Magnitude
            if d < closestDist then
                closestDist = d
                closest = duck
            end
        end
    end
    if closest then return closest.hitbox or closest.root end
    return nil
end

local function getFreezer()
    local freezerFolder = workspace.Ume and workspace.Ume:FindFirstChild("DuckController_Freezers")
    if freezerFolder then
        local myFreezer = freezerFolder:FindFirstChild("DuckController_Freezer_" .. LocalPlayer.UserId)
        if myFreezer then return myFreezer end
    end
    return nil
end

-- ===============================================================
-- LOAD LIBRARY & UI
-- ===============================================================
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(request({ Url = repo .. "Library.lua", Method = "GET" }).Body)()
local ThemeManager = loadstring(request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body)()
local SaveManager = loadstring(request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body)()

local Toggles = Library.Toggles
local Options = Library.Options

local Window = Library:CreateWindow({
    Title = "Ivory",
    Footer = { "Ivory | v1.0", { Text = "v1.0", Copyable = true } },
    Minimizable = true, FuzzySearch = true, SearchValues = true,
})

local ShopTab = Window:AddTab({ Name = "Shop", Icon = "shopping-cart", Description = "Buy & Open" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Themes & UI" })

-- ===============================================================
-- GAME TAB (only in-game)
-- ===============================================================
if isGame() then
    local MainTab = Window:AddTab({ Name = "Main", Icon = "crosshair", Description = "Combat & Farm" })
    local CombatSub = MainTab:AddSubTab({ Name = "Combat", Icon = "swords" })
    local FarmSub = MainTab:AddSubTab({ Name = "Farm", Icon = "zap" })

    local CombatBox = CombatSub:AddLeftGroupbox("Combat", "crosshair")
    CombatBox:AddToggle("AutoShoot", { Text = "Auto Shoot", Default = false, Tooltip = "Automatically shoot ducks" })
    CombatBox:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Tooltip = "Aim at ducks directly" })
    CombatBox:AddToggle("KillAura", { Text = "Kill Aura", Default = false, Tooltip = "Auto-damage ducks in radius" })
    CombatBox:AddSlider("KillAuraRadius", { Text = "Kill Aura Radius", Default = 200, Min = 50, Max = 1000, Rounding = 0, Suffix = " studs" })
    CombatBox:AddToggle("AutoTargetMadBirds", { Text = "Target Mad/Boss Birds", Default = false, Tooltip = "Prioritize angry/boss ducks" })
    CombatBox:AddToggle("RapidFire", { Text = "Rapid Fire", Default = false, Tooltip = "Faster shooting" })

    local PositionBox = CombatSub:AddRightGroupbox("Positioning", "map-pin")
    PositionBox:AddToggle("StayBehindSpawn", { Text = "Behind Duck Spawn", Default = false, Tooltip = "Stay behind duck spawn for safety" })
    PositionBox:AddToggle("NoClip", { Text = "Noclip", Default = false, Tooltip = "Walk through walls" })
    PositionBox:AddButton({ Text = "Back to Spawn", Func = function()
        local _, hrp = getChar()
        if hrp then
            local spawn = workspace.Ume:FindFirstChild("BaseSpawn")
            if spawn then
                hrp.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
            end
        end
    end })

    local FarmBox = FarmSub:AddLeftGroupbox("Auto Farm", "zap")
    FarmBox:AddToggle("AutoSellDucks", { Text = "Auto Sell Ducks", Default = false, Tooltip = "Auto deposit ducks to freezer" })
    FarmBox:AddToggle("AutoCollectDrops", { Text = "Auto Collect Drops", Default = false, Tooltip = "Auto collect drops" })
    FarmBox:AddToggle("AutoSkipDay", { Text = "Auto Skip Day", Default = false, Tooltip = "Vote to skip day" })
    FarmBox:AddToggle("RemoveGameplayPaused", { Text = "Remove Gameplay Paused", Default = false, Tooltip = "Remove pause GUI" })
    FarmBox:AddToggle("AutoReturnLobby", { Text = "Auto Return to Lobby", Default = false, Tooltip = "Return to lobby when game ends" })

    -- In-Game onChanged
    Toggles.AutoShoot:OnChanged(function(s) cfg.autoShoot = s end)
    Toggles.SilentAim:OnChanged(function(s) cfg.silentAim = s end)
    Toggles.KillAura:OnChanged(function(s) cfg.killAura = s end)
    Options.KillAuraRadius:OnChanged(function(v) cfg.killAuraRadius = v end)
    Toggles.AutoTargetMadBirds:OnChanged(function(s) cfg.autoTargetMadBirds = s end)
    Toggles.StayBehindSpawn:OnChanged(function(s) cfg.stayBehindSpawn = s end)
    Toggles.RapidFire:OnChanged(function(s) cfg.rapidFire = s end)
    Toggles.RemoveGameplayPaused:OnChanged(function(s) cfg.removeGameplayPaused = s end)
    Toggles.AutoReturnLobby:OnChanged(function(s) cfg.autoReturnLobby = s end)
    Toggles.AutoSellDucks:OnChanged(function(s) cfg.autoSellDucks = s end)
    Toggles.AutoCollectDrops:OnChanged(function(s) cfg.autoCollectDrops = s end)
    Toggles.AutoSkipDay:OnChanged(function(s) cfg.autoSkipDay = s end)
    Toggles.NoClip:OnChanged(function(s) cfg.noclip = s end)
end

-- ===============================================================
-- LOBBY TAB (only in lobby)
-- ===============================================================
if isLobby() then
    local LobbyTab = Window:AddTab({ Name = "Lobby", Icon = "building", Description = "Lobby Features" })
    local QueueSub = LobbyTab:AddSubTab({ Name = "Queue", Icon = "play" })
    local UpgradeSub = LobbyTab:AddSubTab({ Name = "Upgrades", Icon = "trending-up" })
    local MiscSub = LobbyTab:AddSubTab({ Name = "Misc", Icon = "zap" })

    local QueueBox = QueueSub:AddLeftGroupbox("Auto Queue", "play")
    QueueBox:AddToggle("AutoJoinGame", { Text = "Auto Join Game", Default = false, Tooltip = "Teleport to queue when in lobby" })

    local UpgradeBox = UpgradeSub:AddLeftGroupbox("Auto Upgrades", "arrow-up-circle")
    UpgradeBox:AddToggle("AutoBuyUpgrades", { Text = "Auto Buy Upgrades", Default = false, Tooltip = "Buy upgrades automatically" })
    UpgradeBox:AddDropdown("PriorityUpgrade", {
        Values = { "Damage", "AmmoCount", "ReloadSpeed", "SpawnRate", "Luck", "Dog Speed", "Dog Capacity", "Dog Dexterity" },
        Default = "Damage",
        Text = "Priority Upgrade",
        Tooltip = "Which upgrade to buy first",
    })

    local DogBox = UpgradeSub:AddRightGroupbox("Dogs", "heart")
    DogBox:AddToggle("AutoEquipBestDog", { Text = "Auto Equip Best Dog", Default = false, Tooltip = "Equip the best dog automatically" })

    local MiscBox = MiscSub:AddLeftGroupbox("Misc", "zap")
    MiscBox:AddToggle("AutoRollDailyQuests", { Text = "Auto Roll Daily Quests", Default = false, Tooltip = "Roll daily quests automatically" })
    MiscBox:AddToggle("AutoClaimGroup", { Text = "Auto Claim Group Reward", Default = false, Tooltip = "Claim group reward automatically" })

    -- Lobby onChanged
    Toggles.AutoJoinGame:OnChanged(function(s) cfg.autoJoinGame = s end)
    Toggles.AutoBuyUpgrades:OnChanged(function(s) cfg.autoBuyUpgrades = s end)
    Toggles.AutoEquipBestDog:OnChanged(function(s) cfg.autoEquipBestDog = s end)
    Toggles.AutoRollDailyQuests:OnChanged(function(s) cfg.autoRollDailyQuests = s end)
    Toggles.AutoClaimGroup:OnChanged(function(s) cfg.autoClaimGroup = s end)
    Options.PriorityUpgrade:OnChanged(function(v) cfg.priorityUpgrade = v end)
end

-- ===============================================================
-- SHOP TAB (works in both)
-- ===============================================================
do
    local WeaponSub = ShopTab:AddSubTab({ Name = "Weapons", Icon = "swords" })
    local CrateSub = ShopTab:AddSubTab({ Name = "Crates", Icon = "package" })

    local WeaponBox = WeaponSub:AddLeftGroupbox("Weapons", "swords")
    WeaponBox:AddToggle("AutoBuyWeapons", { Text = "Auto Buy Weapons", Default = false, Tooltip = "Buy all affordable weapons" })

    local CrateBox = CrateSub:AddLeftGroupbox("Crates", "package")
    CrateBox:AddToggle("AutoOpenCrates", { Text = "Auto Open Crates", Default = false, Tooltip = "Open crates automatically" })
    CrateBox:AddDropdown("CrateAmount", {
        Values = { 1, 3, 10 },
        Default = 1,
        Text = "Crate Amount",
        Tooltip = "How many crates to open at once",
    })

    Toggles.AutoBuyWeapons:OnChanged(function(s) cfg.autoBuyWeapons = s end)
    Toggles.AutoOpenCrates:OnChanged(function(s) cfg.autoOpenCrates = s end)
    Options.CrateAmount:OnChanged(function(v) cfg.crateAmount = v end)
end

-- ===============================================================
-- COMBAT SYSTEM
-- ===============================================================
local mouseHeld = false

local function aimAtTarget(target)
    if not target or not target.Parent then
        if mouseHeld then mouse1release() mouseHeld = false end
        return false
    end
    local cam = workspace.CurrentCamera
    if not cam then
        if mouseHeld then mouse1release() mouseHeld = false end
        return false
    end
    if not hasWeapon() or isReloading() or getAmmo() <= 0 then
        if mouseHeld then mouse1release() mouseHeld = false end
        return false
    end

    local screenPos, onScreen = cam:WorldToViewportPoint(target.Position)
    if not onScreen then
        if mouseHeld then mouse1release() mouseHeld = false end
        return false
    end

    local viewportSize = cam.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2
    local dx = screenPos.X - centerX
    local dy = screenPos.Y - centerY

    mousemoverel(math.clamp(dx, -500, 500), math.clamp(dy, -500, 500))

    if not mouseHeld then
        mouse1press()
        mouseHeld = true
    end
    return true
end

local combatCleanup = 0
RunService.Heartbeat:Connect(function()
    if not isGame() or not isAlive() then
        if mouseHeld then mouse1release() mouseHeld = false end
        return
    end
    if not (cfg.autoShoot or cfg.silentAim or cfg.killAura) then
        if mouseHeld then mouse1release() mouseHeld = false end
        return
    end

    combatCleanup = combatCleanup + 1
    if combatCleanup >= 300 then
        combatCleanup = 0
        cleanupShotRecord()
    end

    local target = findTarget(cfg.autoTargetMadBirds, cfg.killAuraRadius)
    if not target then
        if mouseHeld then mouse1release() mouseHeld = false end
        return
    end

    local targetName = target.Parent and target.Parent.Name or target.Name
    if wasRecentlyShot(targetName) then return end

    if aimAtTarget(target) then
        recordShot(targetName)
    end
end)

-- ===============================================================
-- IN-GAME: STAY BEHIND SPAWN (fly + hover)
-- ===============================================================
task.spawn(function()
    local bp, bg, hum, wasPlatformStand
    local function cleanup()
        if bp then pcall(function() bp:Destroy() end) bp = nil end
        if bg then pcall(function() bg:Destroy() end) bg = nil end
        if hum and wasPlatformStand ~= nil then
            pcall(function() hum.PlatformStand = wasPlatformStand end)
            wasPlatformStand = nil
        end
    end
    while true do
        local ok, err = pcall(function()
            local char, hrp = getChar()
            hum = char and char:FindFirstChildOfClass("Humanoid")
            if cfg.stayBehindSpawn and isGame() and hrp and hum then
                local gf = workspace.Ume:FindFirstChild("GameFunctions")
                local spawner = gf and gf:FindFirstChild("Ducks-DuckSpawner")
                local spawnerPart = spawner and spawner:FindFirstChild("SpawnerPart")
                if spawnerPart then
                    local targetPos = spawnerPart.CFrame * CFrame.new(0, 0, 30)
                    if wasPlatformStand == nil then
                        wasPlatformStand = hum.PlatformStand
                    end
                    hum.PlatformStand = true
                    if not bp or not bp.Parent then
                        bp = Instance.new("BodyPosition")
                        bp.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                        bp.P = 1e4
                        bp.D = 500
                        bp.Parent = hrp
                    end
                    if not bg or not bg.Parent then
                        bg = Instance.new("BodyGyro")
                        bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
                        bg.P = 1e4
                        bg.D = 500
                        bg.Parent = hrp
                    end
                    bp.Position = targetPos.Position
                    bg.CFrame = spawnerPart.CFrame
                end
            else
                cleanup()
            end
        end)
        if not ok then cleanup() end
        task.wait(0.1)
    end
end)

-- ===============================================================
-- IN-GAME: AUTO SELL DUCKS
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoSellDucks and isGame() then
            pcall(function()
                if Value and Value.DuckController and Value.DuckController.SellDucks then
                    Value.DuckController.SellDucks()
                end
            end)
        end
        task.wait(3)
    end
end)

-- ===============================================================
-- IN-GAME: AUTO COLLECT DROPS
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoCollectDrops and isGame() then
            pcall(function()
                local _, hrp = getChar()
                if hrp then
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") and v:FindFirstChild("TouchInterest") then
                            local dist = (v.Position - hrp.Position).Magnitude
                            if dist < 50 and dist > 3 then
                                hrp.CFrame = v.CFrame
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ===============================================================
-- IN-GAME: AUTO SKIP DAY
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoSkipDay and isGame() then
            pcall(function()
                local skipGui = LocalPlayer.PlayerGui:FindFirstChild("SkipDayGui")
                if skipGui and skipGui.Enabled then
                    if Value and Value.Bosses and Value.Bosses.VoteSkipDay then
                        Value.Bosses.VoteSkipDay()
                    end
                end
            end)
        end
        task.wait(2)
    end
end)

-- ===============================================================
-- IN-GAME: REMOVE GAMEPLAY PAUSED
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.removeGameplayPaused and isGame() then
            pcall(function()
                for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                    if gui:IsA("ScreenGui") then
                        local dim = gui:FindFirstChild("_Dim")
                        if dim then dim:Destroy() end
                        local pause = gui:FindFirstChild("Paused")
                        if pause then pause:Destroy() end
                    end
                end
            end)
        end
        task.wait(1)
    end
end)

-- ===============================================================
-- IN-GAME: AUTO RETURN TO LOBBY
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoReturnLobby and isGame() then
            pcall(function()
                if Value and Value.Respawn_Controller and Value.Respawn_Controller.LeaveGame then
                    Value.Respawn_Controller.LeaveGame()
                end
            end)
        end
        task.wait(10)
    end
end)

-- ===============================================================
-- NOCLIP
-- ===============================================================
task.spawn(function()
    local conn
    while true do
        if cfg.noclip then
            if not conn then
                conn = RunService.Stepped:Connect(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                end)
            end
        else
            if conn then conn:Disconnect() conn = nil end
        end
        task.wait(0.5)
    end
end)

-- ===============================================================
-- LOBBY: AUTO JOIN GAME
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoJoinGame and isLobby() then
            pcall(function()
                local queue = workspace:FindFirstChild("Queue")
                if queue then
                    local _, hrp = getChar()
                    if hrp then
                        for _, v in ipairs(queue:GetDescendants()) do
                            if v:IsA("BasePart") and v.Name == "RootPart" then
                                hrp.CFrame = v.CFrame + Vector3.new(0, 3, 0)
                                task.wait(1)
                                break
                            end
                        end
                    end
                end
            end)
        end
        task.wait(10)
    end
end)

-- ===============================================================
-- LOBBY: AUTO BUY WEAPONS
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoBuyWeapons and isLobby() then
            pcall(function()
                local state = Network.Invoke("Weapons_GetState")
                if state and state.Owned then
                    local weapons = ReplicatedStorage.Instance.Modules.Main.Weapons.Data.Weapons
                    for _, weapon in ipairs(weapons:GetChildren()) do
                        if not state.Owned[weapon.Name] then
                            Network.Invoke("Weapons_Buy", weapon.Name)
                            task.wait(0.5)
                        end
                    end
                end
            end)
        end
        task.wait(10)
    end
end)

-- ===============================================================
-- LOBBY: AUTO EQUIP BEST DOG
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoEquipBestDog and isLobby() then
            pcall(function() Network.Invoke("Dogs_EquipBest") end)
        end
        task.wait(10)
    end
end)

-- ===============================================================
-- LOBBY: AUTO OPEN CRATES
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoOpenCrates and isLobby() then
            pcall(function()
                Network.Invoke("Gacha_BuyCrate", "Dogs_Crate", cfg.crateAmount)
            end)
        end
        task.wait(5)
    end
end)

-- ===============================================================
-- LOBBY: AUTO ROLL DAILY QUESTS
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoRollDailyQuests and isLobby() then
            pcall(function()
                local qm = workspace.Ume.Components:FindFirstChild("QuestMachine")
                local pp = qm and qm:FindFirstChild("PromptPart")
                local prompt = pp and pp:FindFirstChildOfClass("ProximityPrompt")
                if prompt and prompt.Enabled then
                    local _, hrp = getChar()
                    if hrp then
                        hrp.CFrame = pp.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5)
                        fireproximityprompt(prompt)
                    end
                end
            end)
        end
        task.wait(30)
    end
end)

-- ===============================================================
-- LOBBY: AUTO BUY UPGRADES
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoBuyUpgrades and isLobby() then
            pcall(function()
                if not Value or not Value.Network then return end
                local stateOk, state = pcall(function() return Value.Network.Invoke("Upgrades_GetState") end)
                if not stateOk or not state then return end

                local upgrades = {}
                local priorityMap = {
                    ["Damage"] = { cat = "Weapon", stat = "Damage" },
                    ["AmmoCount"] = { cat = "Weapon", stat = "AmmoCount" },
                    ["ReloadSpeed"] = { cat = "Weapon", stat = "ReloadSpeed" },
                    ["SpawnRate"] = { cat = "Duck", stat = "SpawnRate" },
                    ["Luck"] = { cat = "Duck", stat = "Luck" },
                    ["Dog Speed"] = { cat = "Dog", stat = "Speed" },
                    ["Dog Capacity"] = { cat = "Dog", stat = "Strength" },
                    ["Dog Dexterity"] = { cat = "Dog", stat = "Dexterity" },
                }

                if state.Weapon and state.Weapon.Stats then
                    for statName, statData in pairs(state.Weapon.Stats) do
                        if type(statData) == "table" and statData.Price and statData.Next then
                            table.insert(upgrades, { cat = "Weapon", stat = statName, price = statData.Price })
                        end
                    end
                end
                if state.Duck then
                    if state.Duck.Luck and state.Duck.Luck.Price and state.Duck.Luck.Next then
                        table.insert(upgrades, { cat = "Duck", stat = "Luck", price = state.Duck.Luck.Price })
                    end
                    if state.Duck.SpawnRate and state.Duck.SpawnRate.Price and state.Duck.SpawnRate.Next then
                        table.insert(upgrades, { cat = "Duck", stat = "SpawnRate", price = state.Duck.SpawnRate.Price })
                    end
                end
                if state.Dog and state.Dog.Stats then
                    for statName, statData in pairs(state.Dog.Stats) do
                        if type(statData) == "table" and statData.Price and statData.Next then
                            table.insert(upgrades, { cat = "Dog", stat = statName, price = statData.Price })
                        end
                    end
                end

                if #upgrades == 0 then return end

                local priKey = priorityMap[cfg.priorityUpgrade]
                table.sort(upgrades, function(a, b)
                    if priKey then
                        local aPri = (a.cat == priKey.cat and a.stat == priKey.stat) and 0 or 1
                        local bPri = (b.cat == priKey.cat and b.stat == priKey.stat) and 0 or 1
                        if aPri ~= bPri then return aPri < bPri end
                    end
                    return a.price < b.price
                end)

                for _, upg in ipairs(upgrades) do
                    if Value.Currency.HasEnough("Cash", upg.price) then
                        pcall(function() Value.Network.Invoke("Upgrades_Purchase", upg.cat, upg.stat, state) end)
                        task.wait(0.5)
                        break
                    end
                end
            end)
        end
        task.wait(3)
    end
end)

-- ===============================================================
-- LOBBY: AUTO CLAIM GROUP REWARD
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoClaimGroup and isLobby() then
            pcall(function()
                local groupPart = workspace.Ume.Components:FindFirstChild("JoinGroupPart")
                local prompt = groupPart and groupPart:FindFirstChildOfClass("ProximityPrompt")
                if prompt and prompt.Enabled then
                    local _, hrp = getChar()
                    if hrp then
                        hrp.CFrame = groupPart.CFrame + Vector3.new(0, 3, 0)
                        task.wait(0.5)
                        fireproximityprompt(prompt)
                    end
                end
            end)
        end
        task.wait(60)
    end
end)

-- ===============================================================
-- THEME & SAVE
-- ===============================================================
ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("IvoryHub") SaveManager:SetFolder("IvoryHub/catchducks")
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab) SaveManager:LoadAutoloadConfig()

if not Library.Toggled then Library:Toggle() end
print("[Ivory] Catch 1 Billion Ducks - Loaded!")