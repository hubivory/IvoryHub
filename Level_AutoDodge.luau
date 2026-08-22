--// Level (85776757589518) - Auto Dodge + Float Kill
--// Uses ObsidianUltra UI Library

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

--// State
getgenv().LH = {
    AutoDodge = false,
    FloatKill = false,
    AutoSwing = false,
    AutoAbilities = false,
    DodgeRadius = 25,
    FloatHeight = 5,
    SwingInterval = 0.35,
    AbilityInterval = 2.0,
}
local State = getgenv().LH

local function getCharacter()
    return LocalPlayer.Character,
        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"),
        LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
end

local function isAlive()
    local char, hrp, hum = getCharacter()
    return char and hrp and hum and hum.Health > 0
end

local function getAliveEnemies()
    local enemies = {}
    local hrp = select(2, getCharacter())
    if not hrp then return enemies end

    local function scanFolder(folder)
        if not folder then return end
        for _, obj in ipairs(folder:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                local hum = obj:FindFirstChild("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                if hum and root and hum.Health > 0 then
                    local d = (root.Position - hrp.Position).Magnitude
                    table.insert(enemies, {model = obj, humanoid = hum, root = root, dist = d})
                end
            end
        end
    end

    scanFolder(workspace:FindFirstChild("enemies"))
    local dungeon = workspace:FindFirstChild("dungeon")
    if dungeon then
        for _, room in ipairs(dungeon:GetChildren()) do
            scanFolder(room:FindFirstChild("enemyFolder"))
        end
    end

    table.sort(enemies, function(a, b) return a.dist < b.dist end)
    return enemies
end

local function getClosestEnemy()
    local enemies = getAliveEnemies()
    return enemies[1]
end

--// Combat
local function performSwing()
    if not isAlive() then return end
    if not State.FloatKill then
        local enemy = getClosestEnemy()
        if not enemy or enemy.dist > 15 then return end
    end

    local char = LocalPlayer.Character
    if not char then return end
    local busyCasting = char:FindFirstChild("busyCasting")
    if busyCasting and busyCasting.Value ~= false then return end
    local peaceful = LocalPlayer:FindFirstChild("peaceful")
    if peaceful and peaceful.Value ~= false then return end

    local weapon = nil
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") and obj:FindFirstChild("Weapon") then
            weapon = obj
            break
        end
    end

    if weapon then
        local swingRemote = weapon:FindFirstChildOfClass("RemoteEvent")
        if swingRemote then swingRemote:FireServer() end
        local remotes = ReplicatedStorage:FindFirstChild("remotes")
        local weaponUsed = remotes and remotes:FindFirstChild("weaponUsed")
        if weaponUsed then weaponUsed:FireServer() end
        return
    end

    for _, obj in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if obj:IsA("Accessory") and obj:FindFirstChild("Weapon") then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:EquipTool(obj)
                task.wait(0.1)
                local swingRemote = obj:FindFirstChildOfClass("RemoteEvent")
                if swingRemote then swingRemote:FireServer() end
                local remotes = ReplicatedStorage:FindFirstChild("remotes")
                local weaponUsed = remotes and remotes:FindFirstChild("weaponUsed")
                if weaponUsed then weaponUsed:FireServer() end
            end
            return
        end
    end
end

local function isSlotOnCooldown(slot)
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:FindFirstChild("abilitySlot") and tool.abilitySlot.Value == slot then
            local cd = tool:FindFirstChild("cooldown")
            if cd and cd.Value > 0 then return true end
        end
    end
    local char = LocalPlayer.Character
    if char then
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChild("abilitySlot") and tool.abilitySlot.Value == slot then
                local cd = tool:FindFirstChild("cooldown")
                if cd and cd.Value > 0 then return true end
            end
        end
    end
    return false
end

local function performAbility(slot)
    if not isAlive() then return end
    if isSlotOnCooldown(slot) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local busyCasting = char:FindFirstChild("busyCasting")
    if busyCasting and busyCasting.Value ~= false then return end
    local peaceful = LocalPlayer:FindFirstChild("peaceful")
    if peaceful and peaceful.Value ~= false then return end

    local abilityTool = nil
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:FindFirstChild("abilitySlot") and tool.abilitySlot.Value == slot then
            abilityTool = tool
            break
        end
    end
    if not abilityTool then return end

    abilityTool.localEvent:Fire()
    local abilityRemote = ReplicatedStorage:FindFirstChild("remotes")
    abilityRemote = abilityRemote and abilityRemote:FindFirstChild("abilityUsed")
    if abilityRemote then abilityRemote:FireServer(slot, abilityTool) end
end

-- Boss attack warning: set true when boss fires an attack remote, auto-fades
local BossWarning = false
local BossWarningExpiry = 0

local function hookBossRemotes()
    local remotes = ReplicatedStorage:FindFirstChild("remotes")
    if remotes then
        for _, name in ipairs({"bossSpecficEvents", "enchantedBossSpecficEvents",
            "volcanicBossSpecficEvents", "aquaticBossSpecficEvents", "steampunkBossSpecficEvents",
            "ghastlyBossSpecficEvents", "easterIslandBossSpecficEvents"}) do
            local remote = remotes:FindFirstChild(name)
            if remote then
                remote.OnClientEvent:Connect(function(...)
                    if State.AutoDodge then
                        local _, hrp = getCharacter()
                        if hrp then
                            local enemies = getAliveEnemies()
                            for _, e in ipairs(enemies) do
                                if e.dist < 80 then
                                    BossWarning = true
                                    BossWarningExpiry = tick() + 1.5
                                    print("[Dodge] BossRemote:", name, "bossDist=" .. math.floor(e.dist))
                                    return
                                end
                            end
                        end
                    end
                end)
            end
        end
    end

    local mapRemotes = ReplicatedStorage:FindFirstChild("mapSpecificRemotes")
    if mapRemotes then
        for _, remote in ipairs(mapRemotes:GetChildren()) do
            if remote:IsA("RemoteEvent") then
                remote.OnClientEvent:Connect(function(...)
                    if State.AutoDodge then
                        local _, hrp = getCharacter()
                        if hrp then
                            local enemies = getAliveEnemies()
                            for _, e in ipairs(enemies) do
                                if e.dist < 80 then
                                    BossWarning = true
                                    BossWarningExpiry = tick() + 1.5
                                    print("[Dodge] MapRemote:", remote.Name, "bossDist=" .. math.floor(e.dist))
                                    return
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
end
hookBossRemotes()

--// Main Loop
local mainConnection = nil
local lastSwingTime = 0
local lastAbilityTime = 0
local lastHealth = 0
local DodgeCooldown = 0

local function startMain()
    if mainConnection then return end
    lastHealth = 0
    DodgeCooldown = 0

    mainConnection = RunService.Heartbeat:Connect(function()
        if not State.AutoDodge and not State.FloatKill then return end

        local char, hrp, hum = getCharacter()
        if not char or not hrp or not hum or hum.Health <= 0 then return end

        local pos = hrp.Position
        local enemies = getAliveEnemies()
        local curHealth = hum.Health

        -- Initialize health on first frame
        if lastHealth == 0 then
            lastHealth = curHealth
            return
        end

        -------------------------------------------------------
        -- HP DROP DETECTION: emergency retreat
        -------------------------------------------------------
        local hpLost = lastHealth - curHealth
        if hpLost > 0 and tick() > DodgeCooldown then
            DodgeCooldown = tick() + 0.8
        end
        lastHealth = curHealth

        if BossWarning and tick() < BossWarningExpiry and tick() > DodgeCooldown then
            DodgeCooldown = tick() + 0.8
        end

        -------------------------------------------------------
        -- FLOAT KILL: fly above closest enemy, face down, swing
        -------------------------------------------------------
        if State.FloatKill then
            local enemy = enemies[1]
            if not enemy then
                hum.PlatformStand = false
                local dungeon = workspace:FindFirstChild("dungeon")
                if dungeon then
                    for _, room in ipairs(dungeon:GetChildren()) do
                        local ef = room:FindFirstChild("enemyFolder")
                        if ef then
                            local sp = ef:FindFirstChild("spawn") or ef:FindFirstChildOfClass("SpawnLocation")
                            if sp then
                                hrp.CFrame = CFrame.new(sp.Position + Vector3.new(0, 3, 0))
                                break
                            end
                        end
                    end
                end
                return
            end

            local target = enemy.root.Position
            local flyPos = Vector3.new(target.X, target.Y + State.FloatHeight, target.Z)

            local lookDir = (target - flyPos)
            if lookDir.Magnitude > 0.1 then
                hrp.CFrame = CFrame.new(flyPos, flyPos + Vector3.new(lookDir.X, lookDir.Y, lookDir.Z))
            else
                hrp.CFrame = CFrame.new(flyPos)
            end

            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero

            if State.AutoSwing and (tick() - lastSwingTime) >= State.SwingInterval then
                performSwing()
                lastSwingTime = tick()
            end

            if State.AutoAbilities and (tick() - lastAbilityTime) >= State.AbilityInterval then
                performAbility("q")
                task.wait(State.AbilityInterval * 0.5)
                performAbility("e")
                lastAbilityTime = tick()
            end

            return
        end

        -------------------------------------------------------
        -- AUTO DODGE: keep distance, swing from range
        -------------------------------------------------------
        hum.PlatformStand = false
        local closestEnemyDist = math.huge
        local closestEnemyRoot = nil
        if #enemies > 0 then
            closestEnemyDist = enemies[1].dist
            closestEnemyRoot = enemies[1].root
        end

        -- Emergency retreat if HP dropped: back off 40 studs
        if hpLost > 0 and closestEnemyRoot then
            local awayDir = (pos - closestEnemyRoot.Position)
            awayDir = Vector3.new(awayDir.X, 0, awayDir.Z)
            if awayDir.Magnitude > 0 then awayDir = awayDir.Unit else awayDir = Vector3.new(1, 0, 0) end
            local retreatTarget = pos + awayDir * 40
            local floorRay = workspace:Raycast(retreatTarget + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
            if floorRay then retreatTarget = Vector3.new(retreatTarget.X, floorRay.Position.Y + 3, retreatTarget.Z) end
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            hrp.CFrame = CFrame.new(retreatTarget, retreatTarget + Vector3.new(awayDir.X, 0, awayDir.Z))
            hrp.AssemblyLinearVelocity = Vector3.zero
            print("[Dodge] RETREAT hpLost=" .. math.floor(hpLost))
            return
        end

        -- Keep 30m distance from closest enemy
        if closestEnemyRoot then
            local enemyPos = closestEnemyRoot.Position
            local toUs = (pos - enemyPos)
            local horizDist = Vector3.new(toUs.X, 0, toUs.Z).Magnitude

            -- Too close (<25m): strafe sideways to avoid attacks
            if horizDist < 25 and horizDist > 0 then
                local strafeDir = Vector3.new(-toUs.Z, 0, toUs.X).Unit
                local strafeTarget = pos + strafeDir * 15
                local floorRay = workspace:Raycast(strafeTarget + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
                if floorRay then strafeTarget = Vector3.new(strafeTarget.X, floorRay.Position.Y + 3, strafeTarget.Z) end
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                hrp.CFrame = CFrame.new(strafeTarget, enemyPos)
                hrp.AssemblyLinearVelocity = Vector3.zero

            -- Too far (>50m): walk closer
            elseif horizDist > 50 then
                hum:MoveTo(Vector3.new(enemyPos.X, pos.Y, enemyPos.Z))
            end
            -- 25-50m: sweet spot, stay and swing
        end

        -- Swing and abilities (works at range based on testing)
        if State.AutoSwing and (tick() - lastSwingTime) >= State.SwingInterval then
            if closestEnemyDist <= 50 then
                performSwing()
                lastSwingTime = tick()
            end
        end
        if State.AutoAbilities and (tick() - lastAbilityTime) >= State.AbilityInterval then
            if closestEnemyDist <= 50 then
                performAbility("q")
                lastAbilityTime = tick()
            end
        end
    end)
end

local function stopMain()
    if mainConnection then
        mainConnection:Disconnect()
        mainConnection = nil
    end
    local _, _, hum = getCharacter()
    if hum then hum.PlatformStand = false end
end

getgenv().LHStart = startMain
getgenv().LHStop = stopMain

--// UI
local Window = Library:CreateWindow({
    Title = "Level Hub",
    Subtitle = "Auto Dodge + Float Kill",
    Footer = { { Text = "Level Hub v1.2", Copyable = false } },
    Size = UDim2.fromOffset(520, 580),
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "sword", Description = "Core features" })
local CombatTab = Window:AddTab({ Name = "Combat", Icon = "crosshair", Description = "Combat automation" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Tune parameters" })

--// Main Tab
local DodgeGroup = MainTab:AddLeftGroupbox("Auto Dodge", "shield")
DodgeGroup:AddToggle("AutoDodge", {
    Text = "Enable Auto Dodge",
    Default = false,
    Callback = function(val)
        State.AutoDodge = val
        if val then startMain() else
            if not State.FloatKill then stopMain() end
        end
    end,
})

local FloatGroup = MainTab:AddRightGroupbox("Float Kill", "airplay")
FloatGroup:AddToggle("FloatKill", {
    Text = "Enable Float Kill",
    Default = false,
    Callback = function(val)
        State.FloatKill = val
        if val then startMain() else
            if not State.AutoDodge then stopMain() end
        end
    end,
})

FloatGroup:AddToggle("AutoSwingFloat", {
    Text = "Auto Swing",
    Default = true,
    Callback = function(val) State.AutoSwing = val end,
})

FloatGroup:AddToggle("AutoAbilities", {
    Text = "Auto Abilities",
    Default = false,
    Callback = function(val) State.AutoAbilities = val end,
})

FloatGroup:AddSlider("FloatHeight", {
    Text = "Float Height",
    Default = 5,
    Min = 2,
    Max = 20,
    Rounding = 0,
    Callback = function(val) State.FloatHeight = val end,
})

--// Combat Tab
local AttackGroup = CombatTab:AddLeftGroupbox("Auto Attack", "swords")
AttackGroup:AddSlider("SwingInterval", {
    Text = "Swing Interval (s)",
    Default = 0.35,
    Min = 0.1,
    Max = 1.0,
    Rounding = 2,
    Callback = function(val) State.SwingInterval = val end,
})

AttackGroup:AddSlider("AbilityInterval", {
    Text = "Ability Interval (s)",
    Default = 2.0,
    Min = 0.5,
    Max = 5.0,
    Rounding = 1,
    Callback = function(val) State.AbilityInterval = val end,
})

local InfoGroup = CombatTab:AddRightGroupbox("Info", "info")
local EnemyLabel = InfoGroup:AddLabel("Enemies: 0")
local HealthLabel = InfoGroup:AddLabel("Health: 0 / 0")

task.spawn(function()
    while task.wait(1) do
        local enemies = getAliveEnemies()
        local _, _, hum = getCharacter()
        local hp = hum and hum.Health or 0
        local maxHp = hum and hum.MaxHealth or 0
        pcall(function()
            EnemyLabel:SetText("Enemies: " .. #enemies)
            HealthLabel:SetText("Health: " .. math.floor(hp) .. " / " .. math.floor(maxHp))
        end)
    end
end)

--// Settings Tab
local MiscGroup = SettingsTab:AddRightGroupbox("Misc", "cog")
MiscGroup:AddButton("Toggle UI", function() Library:Toggle() end)

MiscGroup:AddButton("Teleport to Enemies", function()
    local enemy = getClosestEnemy()
    if enemy then
        local _, hrp = getCharacter()
        if hrp then hrp.CFrame = enemy.root.CFrame + Vector3.new(0, 5, 0) end
    end
end)

MiscGroup:AddButton("Stop All", function()
    State.AutoDodge = false
    State.FloatKill = false
    State.AutoSwing = false
    State.AutoAbilities = false
    stopMain()
end)

print("[Level Hub] Loaded successfully!")