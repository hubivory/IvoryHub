if getgenv().IvoryMVSD_Executed then
    print("Ivory MVSD already loaded!")
    return
end
getgenv().IvoryMVSD_Executed = true

local getName = identifyexecutor or getexecutorname
if getName then
    local ok, name = pcall(getName)
    if ok and name then
        local execName = tostring(name):lower()
        if execName:find("solara") or execName:find("xeno") then
            game:GetService("Players").LocalPlayer:Kick("EXECUTOR NOT SUPPORTED")
            return
        end
    end
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"))()
local Toggles = Library.Toggles or {}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Collection = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "Ivory",
    Width = 720,
    Height = 600,
})

local Tabs = {
    Combat = Window:CreateTab({Name = "Combat"}),
    ESP = Window:CreateTab({Name = "ESP"}),
    KillAll = Window:CreateTab({Name = "Kill All"}),
    Abilities = Window:CreateTab({Name = "Abilities"}),
    Teleport = Window:CreateTab({Name = "Teleport"}),
    FOV = Window:CreateTab({Name = "FOV Shooting"}),
    Misc = Window:CreateTab({Name = "Misc"}),
    ["UI Settings"] = Window:CreateTab({Name = "UI Settings"}),
}

getgenv().match = false
local canShoot = true
local matchEnemies = {}

task.spawn(function()
    while true do
        if Player then
            if Player:GetAttribute("Match") then
                getgenv().match = true
            else
                getgenv().match = false
            end
        end
        task.wait(0.1)
    end
end)

task.spawn(function()
    while task.wait(0.1) do
        local currentMatch = Player:GetAttribute("Match")
        local tempTable = {}
        if currentMatch then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= Player and v:GetAttribute("Match") == currentMatch then
                    local char = v.Character
                    if char and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                        table.insert(tempTable, v)
                    end
                end
            end
        end
        matchEnemies = tempTable
    end
end)

task.spawn(function()
    local lastGunTracked = nil
    local soundConnection = nil
    while task.wait(0.1) do
        local character = Player.Character
        local gun = nil
        local locations = { Player:FindFirstChild("Backpack") }
        if character then table.insert(locations, character) end
        for _, container in ipairs(locations) do
            if container then
                for _, tool in ipairs(container:GetChildren()) do
                    if tool:IsA("Tool") and tool:FindFirstChild("Fire") and tool:FindFirstChild("Reload") then
                        gun = tool
                        break
                    end
                end
            end
            if gun then break end
        end
        if gun then
            if gun ~= lastGunTracked then
                lastGunTracked = gun
                if soundConnection then soundConnection:Disconnect() end
                local fireSound = gun:FindFirstChild("Fire")
                if fireSound and fireSound:IsA("Sound") then
                    soundConnection = fireSound.Played:Connect(function()
                        lastFiredTime = tick()
                    end)
                end
            end
        else
            lastGunTracked = nil
            if soundConnection then soundConnection:Disconnect() soundConnection = nil end
        end
    end
end)

local function getGun()
    local character = Player.Character
    local locations = { Player:FindFirstChild("Backpack") }
    if character then table.insert(locations, character) end
    for _, container in ipairs(locations) do
        if container then
            for _, tool in ipairs(container:GetChildren()) do
                if tool:IsA("Tool") and tool:FindFirstChild("Fire") and tool:FindFirstChild("Reload") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function equipGun()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if not character or not backpack then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if getgenv().match then
        local gun = getGun()
        if gun then humanoid:EquipTool(gun) return true end
    end
    return false
end

local function equipKnife()
    local character = Player.Character
    local backpack = Player:FindFirstChildOfClass("Backpack")
    if not character or not backpack then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if getgenv().match then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and tool:GetAttribute("EquipAnimation") == "Knife_Equip" then
                humanoid:EquipTool(tool)
                return true
            end
        end
    end
    return false
end

local BulletRendererColor = Color3.fromRGB(255, 255, 255)
local function BulletRenderer(origin, targetPos)
    local function CreatePseudoPart(cf)
        local p = Instance.new("Part")
        p.Size = Vector3.new(0.1, 0.1, 0.1)
        p.Transparency = 1
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Anchored = true
        p.CFrame = cf
        p.Parent = workspace
        return p
    end
    local startPart = CreatePseudoPart(CFrame.lookAt(origin, targetPos) * CFrame.new(0, 0, -1))
    local endPart = CreatePseudoPart(CFrame.new(targetPos))
    local beam = Instance.new("Beam")
    beam.Texture = ""
    beam.TextureLength = 1
    beam.TextureMode = Enum.TextureMode.Stretch
    beam.TextureSpeed = 0
    beam.Color = ColorSequence.new(BulletRendererColor)
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Brightness = 5
    beam.Width0 = 0
    beam.Width1 = 0
    local att0 = Instance.new("Attachment", startPart)
    local att1 = Instance.new("Attachment", endPart)
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Parent = startPart
    local fadeIn = TweenService:Create(beam, TweenInfo.new(0.05, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), { Width0 = 0.3, Width1 = 0.6 })
    local fadeOut = TweenService:Create(beam, TweenInfo.new(0.1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Width0 = 0, Width1 = 0 })
    fadeIn:Play()
    fadeIn.Completed:Connect(function() fadeOut:Play() end)
    Debris:AddItem(startPart, 0.3)
    Debris:AddItem(endPart, 0.3)
end

local function CharacterRayOrigin(char)
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    return (hrp.CFrame * CFrame.new(0, 0, hrp.Size.Z / 2)).Position
end

local function ShootGun(target)
    local myChar = Player.Character
    if not myChar then return end
    local origin = CharacterRayOrigin(myChar)
    if not origin then return end
    local hitPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
    local tool = getGun()
    if not tool then return end
    if hitPart then
        canShoot = false
        local targetPos = hitPart.Position
        local muzzle = tool:FindFirstChild("Muzzle", true)
        local startPos = muzzle and muzzle.WorldPosition or origin
        BulletRenderer(startPos, targetPos)
        ReplicatedStorage.Remotes.ShootGun:FireServer(origin, targetPos, hitPart, targetPos)
        local sound = tool and tool:FindFirstChild("Fire")
        if sound and sound:IsA("Sound") then sound:Play() end
        task.delay(2.5, function() canShoot = true end)
    end
end

local function FeatureActivated(boolean)
    Library.Notify({
        Title = "Ivory",
        Content = boolean and "Feature Activated!" or "Feature Disabled!",
        Type = boolean and "Success" or "Info",
        Duration = 3,
    })
end

-- ==================== COMBAT TAB ====================
do
    local discordSection = Tabs.Combat:CreateSection("discord")
    discordSection:CreateLabel({Text = "join discord for free keys!", TextSize = 26})
    discordSection:CreateButton({Name = "Copy Discord Link", Callback = function()
        pcall(setclipboard, "https://discord.gg/MCWYKBdB4E")
        Library.Notify({Title = "Ivory", Content = "Discord Link Copied!", Type = "Success", Duration = 3})
    end})

    local combatSection = Tabs.Combat:CreateSection("combat")
    local configSection = Tabs.Combat:CreateSection("configuration")

    configSection:CreateToggle("AutoUnanchor", {
        Text = "auto unanchor character",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().autounanchor = Value
            local function monitorCharacter(character)
                local rootPart = character:WaitForChild("HumanoidRootPart", 5)
                local humanoid = character:WaitForChild("Humanoid", 5)
                if not rootPart or not humanoid then return end
                local connection
                connection = RunService.Heartbeat:Connect(function()
                    if not character.Parent or humanoid.Health <= 0 then
                        connection:Disconnect()
                        return
                    end
                    if rootPart.Anchored and getgenv().autounanchor then
                        rootPart.Anchored = false
                    end
                end)
            end
            if Player.Character then task.spawn(monitorCharacter, Player.Character) end
            Player.CharacterAdded:Connect(monitorCharacter)
        end
    })

    configSection:CreateLabel({Text = "bullet tracer color"}):CreateColorPicker("BulletTracerColor", {
        Default = BulletRendererColor,
        Callback = function(color) BulletRendererColor = color end,
    })

    getgenv().autoshoot_enabled = false
    getgenv().max_distance = 300
    getgenv().autoshoot_cooldown = 2
    local autoshoot_thread = nil

    combatSection:CreateToggle("EnableAutoshoot", {
        Text = "enable autoshoot",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().autoshoot_enabled = Value
            FeatureActivated(Value)
            if autoshoot_thread then task.cancel(autoshoot_thread) autoshoot_thread = nil end
            if getgenv().autoshoot_enabled then
                local function has_clear_los(fromPos, toPos, myCharacter, targetCharacter)
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = { myCharacter, targetCharacter }
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local result = workspace:Raycast(fromPos, (toPos - fromPos), params)
                    if result then
                        if not result.Instance:IsDescendantOf(targetCharacter) then return false end
                    end
                    return true
                end
                autoshoot_thread = task.spawn(function()
                    while getgenv().autoshoot_enabled do
                        local myChar = Player.Character
                        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local myHum = myChar and myChar:FindFirstChild("Humanoid")
                        if getgenv().match and myRoot and myHum and myHum.Health > 0 then
                            local closestTarget = nil
                            local closestDistance = getgenv().max_distance or 1000
                            for _, enemy in ipairs(matchEnemies) do
                                local char = enemy.Character
                                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                                local hum = char and char:FindFirstChild("Humanoid")
                                if enemy ~= Player and hum and hum.Health > 0 and hrp then
                                    local dist = (hrp.Position - myRoot.Position).Magnitude
                                    if dist < closestDistance then
                                        local onDifferentTeam = (not enemy.Team or enemy.Team ~= Player.Team)
                                        local isVisibleInFov = (Camera.CFrame.LookVector:Dot((hrp.Position - Camera.CFrame.Position).Unit) >= 0.9)
                                        if onDifferentTeam and isVisibleInFov then
                                            closestDistance = dist
                                            closestTarget = enemy
                                        end
                                    end
                                end
                            end
                            if closestTarget and canShoot then
                                local targetChar = closestTarget.Character
                                local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
                                if targetHrp and has_clear_los(myRoot.Position, targetHrp.Position, myChar, targetChar) then
                                    ShootGun(closestTarget)
                                end
                            end
                        end
                        task.wait(0.03)
                    end
                end)
            end
        end
    })

    combatSection:CreateSlider("AutoshootMaxDistance", {
        Text = "autoshoot max distance",
        Default = 300,
        Min = 0,
        Max = 1000,
        Rounding = 0,
        Callback = function(value) getgenv().max_distance = value end,
    })

    combatSection:CreateSlider("AutoshootCooldown", {
        Text = "cooldown",
        Default = 2,
        Min = 0.5,
        Max = 10,
        Rounding = 1,
        Callback = function(value) getgenv().autoshoot_cooldown = value end,
    })

    getgenv().auto_throw_enabled = false
    getgenv().throw_cooldown = 2
    local autoThrowThread = nil
    local lastThrowTime = 0

    local function throwKnife(targetChar)
        local tool = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if not tool or not tool:FindFirstChild("RightHandle") then return end
        local targetHrp = targetChar:FindFirstChild("HumanoidRootPart")
        if not targetHrp then return end
        local origin = CharacterRayOrigin(game.Players.LocalPlayer.Character)
        local direction = (targetHrp.Position - origin).Unit
        ReplicatedStorage.Remotes.ThrowStart:FireServer(origin, direction)
        require(ReplicatedStorage.Modules.KnifeProjectileController)({
            Speed = tool:GetAttribute("ThrowSpeed"),
            KnifeProjectile = tool.RightHandle:Clone(),
            Direction = direction,
            Origin = origin
        }, function(raycastResult)
            ReplicatedStorage.Remotes.ThrowHit:FireServer(raycastResult and raycastResult.Instance, raycastResult and raycastResult.Position)
        end)
        lastThrowTime = tick()
    end

    combatSection:CreateToggle("AutoThrowKnife", {
        Text = "enable auto throw knife",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().auto_throw_enabled = Value
            FeatureActivated(Value)
            if autoThrowThread then task.cancel(autoThrowThread) autoThrowThread = nil end
            if Value then
                autoThrowThread = task.spawn(function()
                    while getgenv().auto_throw_enabled do
                        if (tick() - lastThrowTime) >= getgenv().throw_cooldown then
                            local myChar = game.Players.LocalPlayer.Character
                            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                            if myRoot then
                                local closestTarget = nil
                                local shortestDist = getgenv().max_distance
                                for _, player in matchEnemies do
                                    if player ~= game.Players.LocalPlayer and player.Character and player.Team ~= Player.Team then
                                        local enemyHrp = player.Character:FindFirstChild("HumanoidRootPart")
                                        local enemyHum = player.Character:FindFirstChild("Humanoid")
                                        if enemyHrp and enemyHum and enemyHum.Health > 0 then
                                            local dist = (enemyHrp.Position - myRoot.Position).Magnitude
                                            local params = RaycastParams.new()
                                            params.FilterDescendantsInstances = { myChar, player.Character }
                                            params.FilterType = Enum.RaycastFilterType.Exclude
                                            local result = workspace:Raycast(myRoot.Position, (enemyHrp.Position - myRoot.Position), params)
                                            if dist < shortestDist and not result then
                                                shortestDist = dist
                                                closestTarget = player.Character
                                            end
                                        end
                                    end
                                end
                                if closestTarget then throwKnife(closestTarget) end
                            end
                        end
                        task.wait(0.1)
                    end
                end)
            end
        end
    })

    combatSection:CreateSlider("ThrowMaxDistance", {
        Text = "max throw distance",
        Default = 300,
        Min = 0,
        Max = 1000,
        Rounding = 0,
        Callback = function(v) getgenv().max_distance = v end,
    })

    combatSection:CreateSlider("ThrowCooldown", {
        Text = "throw cooldown",
        Default = 2,
        Min = 0.5,
        Max = 10,
        Rounding = 1,
        Callback = function(v) getgenv().throw_cooldown = v end,
    })

    getgenv().triggerbot_enabled = false
    getgenv().triggerbot_firing = false
    getgenv().triggerbot_cooldown = 1

    local function triggerbot_valid_enemy(enemy)
        if not enemy or enemy == Player then return false end
        local character = enemy.Character
        if not character or character.Parent ~= Workspace then return false end
        if enemy.Team and enemy.Team == Player.Team then return false end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local my_hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not (humanoid and hrp and my_hrp) then return false end
        if humanoid.Health <= 0 then return false end
        if Collection:HasTag(character, "Invulnerable") or Collection:HasTag(character, "SpeedTrail") then return false end
        return true
    end

    local function triggerbot_shoot(target)
        local my_char = Player.Character
        local my_root = my_char and my_char:FindFirstChild("HumanoidRootPart")
        local target_hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not (my_root and target_hrp) then getgenv().triggerbot_firing = false return end
        local hit_part = target.Character:FindFirstChild("LowerTorso") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
        if hit_part then ShootGun(target) else getgenv().triggerbot_firing = false end
    end

    RunService.Heartbeat:Connect(function()
        if not getgenv().triggerbot_enabled then return end
        if not getgenv().match then return end
        if getgenv().triggerbot_firing then return end
        local character = Player.Character
        if not character then return end
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = { character }
        rayParams.IgnoreWater = true
        local result = Workspace:Raycast(ray.Origin, ray.Direction * 2000, rayParams)
        if not result then return end
        local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
        if not hitCharacter then return end
        local hitPlayer = Players:GetPlayerFromCharacter(hitCharacter)
        if not hitPlayer then return end
        if triggerbot_valid_enemy(hitPlayer) then
            getgenv().triggerbot_firing = true
            triggerbot_shoot(hitPlayer)
            task.delay(getgenv().triggerbot_cooldown, function() getgenv().triggerbot_firing = false end)
        end
    end)

    combatSection:CreateToggle("TriggerBot", {
        Text = "trigger bot",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().triggerbot_enabled = Value
            FeatureActivated(Value)
        end
    })

    combatSection:CreateSlider("TriggerBotCooldown", {
        Text = "trigger bot cooldown",
        Default = 1,
        Min = 0,
        Max = 3,
        Rounding = 1,
        Callback = function(value) getgenv().triggerbot_cooldown = value end,
    })

    getgenv().hitbox_expander = false
    getgenv().hitbox_size = 13
    getgenv().hitbox_color = Color3.fromRGB(255, 0, 0)

    combatSection:CreateToggle("HitboxExpander", {
        Text = "enable hitbox expander",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().hitbox_expander = Value
            FeatureActivated(Value)
            if not getgenv().hitbox_expander then
                for _, player in matchEnemies do
                    if player ~= Player then
                        local character = player.Character
                        local hrp = character and character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.CanCollide = false
                            local hit_box = hrp:FindFirstChild("hit_box")
                            if hit_box then hit_box:Destroy() end
                        end
                    end
                end
                return
            end
            task.spawn(function()
                while getgenv().hitbox_expander and task.wait(0.1) do
                    for _, player in pairs(Players:GetPlayers()) do
                        if player ~= Player and player.Character then
                            local character = player.Character
                            local hrp = character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local enemy = player.Team ~= Player.Team
                                if enemy then
                                    hrp.Size = Vector3.new(getgenv().hitbox_size, getgenv().hitbox_size, getgenv().hitbox_size)
                                    hrp.CanCollide = true
                                    local hit_box = hrp:FindFirstChild("hit_box")
                                    if not hit_box then
                                        local box_handle = Instance.new("BoxHandleAdornment")
                                        box_handle.Name = "hit_box"
                                        box_handle.Adornee = hrp
                                        box_handle.AlwaysOnTop = true
                                        box_handle.ZIndex = 10
                                        box_handle.Size = hrp.Size
                                        box_handle.Color3 = getgenv().hitbox_color
                                        box_handle.Transparency = 0.8
                                        box_handle.Parent = hrp
                                    else
                                        hit_box.Size = hrp.Size
                                    end
                                else
                                    hrp.Size = Vector3.new(2, 2, 1)
                                    hrp.CanCollide = false
                                    local hit_box = hrp:FindFirstChild("hit_box")
                                    if hit_box then hit_box:Destroy() end
                                end
                            end
                        end
                    end
                end
            end)
        end
    })

    combatSection:CreateSlider("HitboxSize", {
        Text = "hitbox size",
        Default = 13,
        Min = 5,
        Max = 100,
        Rounding = 0,
        Callback = function(size) getgenv().hitbox_size = size end,
    })

    combatSection:CreateLabel({Text = "hitbox color"}):CreateColorPicker("HitboxColor", {
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(color) getgenv().hitbox_color = color end,
    })

    getgenv().original_cooldowns = {}
    combatSection:CreateToggle("RemoveGunCooldown", {
        Text = "remove gun cooldown",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().remove_gun_cooldown = Value
            FeatureActivated(Value)
            if Value then
                getgenv().original_cooldowns = {}
                task.spawn(function()
                    while getgenv().remove_gun_cooldown do
                        task.wait(0.1)
                        local tools = {}
                        for _, container in ipairs({ Player:FindFirstChild("Backpack"), Player.Character }) do
                            if container then
                                for _, tool in ipairs(container:GetChildren()) do
                                    if tool:IsA("Tool") and tool:FindFirstChild("Fire") then
                                        table.insert(tools, tool)
                                    end
                                end
                            end
                        end
                        for _, tool in ipairs(tools) do
                            if getgenv().original_cooldowns[tool] == nil then
                                getgenv().original_cooldowns[tool] = tool:GetAttribute("Cooldown")
                            end
                            if tool:GetAttribute("Cooldown") ~= 0 then
                                tool:SetAttribute("Cooldown", 0)
                            end
                        end
                    end
                end)
            else
                for tool, cooldown in pairs(getgenv().original_cooldowns) do
                    if tool and tool.Parent then tool:SetAttribute("Cooldown", cooldown) end
                end
                getgenv().original_cooldowns = {}
            end
        end,
    })
end

-- ==================== ESP TAB ====================
do
    local espSection = Tabs.ESP:CreateSection("highlights")
    local colorSection = Tabs.ESP:CreateSection("colors")

    getgenv().esp_team_color = Color3.fromRGB(0, 255, 0)
    getgenv().esp_enemy_color = Color3.fromRGB(255, 0, 0)
    getgenv().esp_charms_highlighter = false
    local charms_esp = CoreGui:FindFirstChild("Highlights") or Instance.new("Folder")
    charms_esp.Name = "CharmsESP"
    charms_esp.Parent = CoreGui

    espSection:CreateToggle("EspCharms", {
        Text = "enable charms highlighter",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().esp_charms_highlighter = Value
            if not getgenv().esp_charms_highlighter then
                for _, esp_players in ipairs(charms_esp:GetChildren()) do esp_players:Destroy() end
                return
            end
            task.spawn(function()
                while getgenv().esp_charms_highlighter do
                    task.wait(0.1)
                    for _, v in matchEnemies do
                        if not getgenv().esp_charms_highlighter then break end
                        if v ~= Player then
                            local character = v.Character
                            if character then
                                local highlight = charms_esp:FindFirstChild(v.Name)
                                if not highlight then
                                    highlight = Instance.new("Highlight")
                                    highlight.Name = v.Name
                                    highlight.FillTransparency = 0.6
                                    highlight.OutlineTransparency = 0.4
                                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                                    highlight.Parent = charms_esp
                                end
                                local teamColor = (v.Team == Player.Team) and getgenv().esp_team_color or getgenv().esp_enemy_color
                                highlight.FillColor = teamColor
                                highlight.OutlineColor = teamColor
                                highlight.Adornee = character
                            end
                        end
                    end
                end
            end)
        end
    })

    getgenv().esp_skeleton = false
    local skeleton_folder = CoreGui:FindFirstChild("Skeletons") or Instance.new("Folder")
    skeleton_folder.Name = "Skeletons"
    skeleton_folder.Parent = CoreGui

    espSection:CreateToggle("EspSkeleton", {
        Text = "enable skeletal highlighter",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().esp_skeleton = Value
            local function cleanup()
                for _, child in ipairs(skeleton_folder:GetChildren()) do child:Destroy() end
            end
            if not Value then cleanup() return end
            task.spawn(function()
                local function createLine()
                    local line = Instance.new("LineHandleAdornment")
                    line.Thickness = 2
                    line.ZIndex = 10
                    line.AlwaysOnTop = true
                    return line
                end
                local bones = {
                    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
                    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
                    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
                    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
                    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" }
                }
                while getgenv().esp_skeleton do
                    task.wait(0.1)
                    for _, v in matchEnemies do
                        local char = v.Character
                        local holder = skeleton_folder:FindFirstChild(v.Name)
                        if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                            if not holder then
                                holder = Instance.new("Folder")
                                holder.Name = v.Name
                                holder.Parent = skeleton_folder
                            end
                            local color = (v.Team == Player.Team) and getgenv().esp_team_color or getgenv().esp_enemy_color
                            for i, bonePair in ipairs(bones) do
                                local p1, p2 = char:FindFirstChild(bonePair[1]), char:FindFirstChild(bonePair[2])
                                if p1 and p2 then
                                    local line = holder:FindFirstChild(tostring(i)) or createLine()
                                    line.Name = tostring(i)
                                    line.Color3 = color
                                    line.Adornee = p1
                                    line.CFrame = CFrame.new(Vector3.zero, p1.CFrame:PointToObjectSpace(p2.Position))
                                    line.Length = (p1.Position - p2.Position).Magnitude
                                    line.Parent = holder
                                end
                            end
                        elseif holder then
                            holder:Destroy()
                        end
                    end
                    for _, child in ipairs(skeleton_folder:GetChildren()) do
                        if not Players:FindFirstChild(child.Name) then child:Destroy() end
                    end
                end
                cleanup()
            end)
        end
    })

    getgenv().esp_tracers = false
    local tracers_folder = CoreGui:FindFirstChild("Tracers") or Instance.new("Folder")
    tracers_folder.Name = "Tracers"
    tracers_folder.Parent = CoreGui
    local tracerConnection = nil

    espSection:CreateToggle("EspTracers", {
        Text = "enable tracers highlighter",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().esp_tracers = Value
            local function cleanup()
                for _, child in ipairs(tracers_folder:GetChildren()) do child:Destroy() end
            end
            if tracerConnection then tracerConnection:Disconnect() tracerConnection = nil end
            if not Value then cleanup() return end
            tracerConnection = RunService.RenderStepped:Connect(function()
                if not getgenv().esp_tracers then
                    if tracerConnection then tracerConnection:Disconnect() tracerConnection = nil end
                    cleanup()
                    return
                end
                local myChar = Player.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    for _, v in ipairs(matchEnemies) do
                        if v ~= Player and v.Parent then
                            local char = v.Character
                            local tracer = tracers_folder:FindFirstChild(v.Name)
                            if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0 then
                                if not tracer then
                                    tracer = Instance.new("LineHandleAdornment")
                                    tracer.Name = v.Name
                                    tracer.Thickness = 1.5
                                    tracer.ZIndex = 10
                                    tracer.AlwaysOnTop = true
                                    tracer.Parent = tracers_folder
                                end
                                local targetRoot = char.HumanoidRootPart
                                local color = (v.Team == Player.Team) and getgenv().esp_team_color or getgenv().esp_enemy_color
                                tracer.Color3 = color
                                tracer.Adornee = workspace.Terrain
                                tracer.CFrame = CFrame.lookAt(myRoot.Position, targetRoot.Position)
                                tracer.Length = (myRoot.Position - targetRoot.Position).Magnitude
                            elseif tracer then
                                tracer:Destroy()
                            end
                        end
                    end
                else
                    cleanup()
                end
                for _, child in ipairs(tracers_folder:GetChildren()) do
                    if not Players:FindFirstChild(child.Name) then child:Destroy() end
                end
            end)
        end
    })

    colorSection:CreateLabel({Text = "team color"}):CreateColorPicker("EspTeamColor", {
        Default = Color3.fromRGB(0, 255, 0),
        Callback = function(color) getgenv().esp_team_color = color end,
    })

    colorSection:CreateLabel({Text = "enemy color"}):CreateColorPicker("EspEnemyColor", {
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(color) getgenv().esp_enemy_color = color end,
    })
end

-- ==================== KILL ALL TAB ====================
do
    local killSection = Tabs.KillAll:CreateSection("gun kills")
    local knifeSection = Tabs.KillAll:CreateSection("knife kills")

    getgenv().autoKillGun = false
    killSection:CreateButton({Name = "[GUN] Kill all players once", Callback = function()
        if getgenv().match then
            local myMatch = Player:GetAttribute("Match")
            if myMatch then
                equipGun()
                Library.Notify({Title = "Ivory", Content = "Killing all players!", Type = "Success", Duration = 3})
                for _, plr in matchEnemies do
                    if plr.Team ~= Player.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local target = plr.Character.HumanoidRootPart
                        local origin = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                        if origin then
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShootGun"):FireServer(origin.Position, target.Position, target, target.Position)
                        end
                    end
                    task.wait(0.1)
                end
            end
        end
    end})

    killSection:CreateToggle("AutoKillGun", {
        Text = "[GUN] auto kill all players",
        CurrentValue = false,
        Callback = function(state)
            getgenv().autoKillGun = state
            FeatureActivated(state)
        end
    })

    task.spawn(function()
        while true do
            if getgenv().autoKillGun then
                local myMatch = Player:GetAttribute("Match")
                if myMatch then
                    equipGun()
                    for _, plr in matchEnemies do
                        if plr.Team ~= Player.Team and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                            local target = plr.Character.HumanoidRootPart
                            local origin = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                            if origin then
                                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ShootGun"):FireServer(origin.Position, target.Position, target, target.Position)
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)

    getgenv().autoKillKnife = false
    knifeSection:CreateButton({Name = "[KNIFE] Kill all players once", Callback = function()
        if getgenv().match then
            local myMatch = Player:GetAttribute("Match")
            if myMatch then
                equipKnife()
                Library.Notify({Title = "Ivory", Content = "Killing all players!", Type = "Success", Duration = 3})
                for _, target in ipairs(Players:GetPlayers()) do
                    if target ~= Player and target.Character then
                        local humanoid = target.Character:FindFirstChild("Humanoid")
                        local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
                        if humanoid and humanoid.Health > 0 and rootPart then
                            ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ThrowHit"):FireServer(rootPart, rootPart.Position)
                        end
                    end
                    task.wait(0.1)
                end
            end
        end
    end})

    knifeSection:CreateToggle("AutoKillKnife", {
        Text = "[KNIFE] auto kill all players",
        CurrentValue = false,
        Callback = function(state)
            getgenv().autoKillKnife = state
            FeatureActivated(state)
        end
    })

    task.spawn(function()
        while true do
            if getgenv().autoKillKnife then
                local myMatch = Player:GetAttribute("Match")
                if myMatch then
                    equipKnife()
                    for _, target in matchEnemies do
                        if target ~= Player and target.Character then
                            local humanoid = target.Character:FindFirstChild("Humanoid")
                            local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
                            if humanoid and humanoid.Health > 0 and rootPart then
                                ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ThrowHit"):FireServer(rootPart, rootPart.Position)
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ==================== ABILITIES TAB ====================
do
    local abilitySection = Tabs.Abilities:CreateSection("abilities")
    local cooldownSection = Tabs.Abilities:CreateSection("cooldowns")

    getgenv().autoShroud = false
    getgenv().lowExecutorsShroud = false
    getgenv().shroudRate = 1

    local ConfigSuccess, Config = pcall(function()
        return require(game:GetService("ReplicatedStorage").Ability.AbilityConfig)
    end)
    local ActivateShroud = ReplicatedStorage.Ability:WaitForChild("ActivateShroud")
    local isLocked = (not ConfigSuccess)
    local originals = {
        SprintCooldown = not isLocked and Config.SprintCooldown or 15,
        DashCooldown = not isLocked and Config.DashCooldown or 6,
        ShroudCooldown = not isLocked and Config.ShroudCooldown or 7,
        SoulReapCombatDelay = not isLocked and Config.SoulReapCombatDelay or 0.35
    }

    local function blind(targetPlayer)
        local character = Players.LocalPlayer.Character
        if targetPlayer and targetPlayer.Character and character then
            local targetPart = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local root = character:FindFirstChild("HumanoidRootPart")
            if targetPart and root then
                local origin, direction
                if getgenv().lowExecutorsShroud then
                    origin = root.Position
                    direction = (targetPart.Position - origin).Unit
                    ActivateShroud:FireServer(origin, direction)
                else
                    local s1, CharacterRayOrigin = pcall(function() return require(ReplicatedStorage.Modules.CharacterRayOrigin) end)
                    local s2, ShroudProjectileController = pcall(function() return require(ReplicatedStorage.Ability.ShroudProjectileController) end)
                    if s1 and s2 then
                        origin = CharacterRayOrigin(character)
                        direction = (targetPart.Position - origin).Unit
                        ActivateShroud:FireServer(origin, direction)
                        ShroudProjectileController(origin, direction)
                    else
                        getgenv().lowExecutorsShroud = true
                        origin = root.Position
                        direction = (targetPart.Position - origin).Unit
                        ActivateShroud:FireServer(origin, direction)
                    end
                end
            end
        end
    end

    if isLocked then
        abilitySection:CreateLabel({Text = "ability module not found - some features limited"})
    end

    abilitySection:CreateToggle("AutoShroud", {
        Text = "auto shroud all",
        CurrentValue = false,
        Callback = function(state) getgenv().autoShroud = state end
    })

    abilitySection:CreateSlider("ShroudRate", {
        Text = "shrouds per enemy",
        Default = 1,
        Min = 1,
        Max = 10000,
        Rounding = 0,
        Callback = function(value) getgenv().shroudRate = value end,
    })

    task.spawn(function()
        while true do
            if getgenv().autoShroud then
                for _, p in matchEnemies do blind(p) end
                task.wait(1 / getgenv().shroudRate)
            else
                task.wait(0.5)
            end
        end
    end)

    cooldownSection:CreateToggle("RemoveSprintCooldown", {
        Text = "remove sprint cooldown",
        CurrentValue = false,
        Callback = function(state)
            FeatureActivated(state)
            if not isLocked then Config.SprintCooldown = state and 0 or originals.SprintCooldown end
        end
    })

    cooldownSection:CreateToggle("RemoveDashCooldown", {
        Text = "remove dash cooldown",
        CurrentValue = false,
        Callback = function(state)
            FeatureActivated(state)
            if not isLocked then Config.DashCooldown = state and 0 or originals.DashCooldown end
        end
    })

    cooldownSection:CreateToggle("RemoveShroudCooldown", {
        Text = "remove shroud cooldown",
        CurrentValue = false,
        Callback = function(state)
            FeatureActivated(state)
            if not isLocked then Config.ShroudCooldown = state and 0 or originals.ShroudCooldown end
        end
    })

    cooldownSection:CreateToggle("RemoveSoulReapDelay", {
        Text = "remove soul reap combat delay",
        CurrentValue = false,
        Callback = function(state)
            FeatureActivated(state)
            if not isLocked then Config.SoulReapCombatDelay = state and 0 or originals.SoulReapCombatDelay end
        end
    })

    local statSection = Tabs.Abilities:CreateSection("stats")

    statSection:CreateSlider("SprintTime", {
        Text = "sprint time",
        Default = not isLocked and Config.SprintTime or 0,
        Min = 0.5,
        Max = 10,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.SprintTime = value end end,
    })

    statSection:CreateSlider("SprintBoost", {
        Text = "sprint boost",
        Default = not isLocked and Config.SprintBoost or 0,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.SprintBoost = value end end,
    })

    statSection:CreateSlider("SoulReapTime", {
        Text = "soul reap time",
        Default = not isLocked and Config.SoulReapTime or 0,
        Min = 0.5,
        Max = 10,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.SoulReapTime = value end end,
    })

    statSection:CreateSlider("SoulReapSpeedBoost", {
        Text = "soul reap speed boost",
        Default = not isLocked and Config.SoulReapSpeedBoost or 0,
        Min = 0.1,
        Max = 10,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.SoulReapSpeedBoost = value end end,
    })

    statSection:CreateSlider("PropellerJumpBoost", {
        Text = "propeller jump boost",
        Default = not isLocked and Config.PropellerJumpBoost or 0,
        Min = 0.1,
        Max = 5,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.PropellerJumpBoost = value end end,
    })

    statSection:CreateSlider("ShroudTime", {
        Text = "shroud time",
        Default = not isLocked and Config.ShroudTime or 0,
        Min = 0.5,
        Max = 10,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.ShroudTime = value end end,
    })

    statSection:CreateSlider("ShroudProjectileSpeed", {
        Text = "shroud projectile speed",
        Default = not isLocked and Config.ShroudProjectileSpeed or 0,
        Min = 2.5,
        Max = 100,
        Rounding = 1,
        Callback = function(value) if not isLocked then Config.ShroudProjectileSpeed = value end end,
    })

    statSection:CreateSlider("ShroudProjectileRange", {
        Text = "shroud projectile range",
        Default = not isLocked and Config.ShroudProjectileRange or 0,
        Min = 5,
        Max = 1000,
        Rounding = 0,
        Callback = function(value) if not isLocked then Config.ShroudProjectileRange = value end end,
    })
end

-- ==================== TELEPORT TAB ====================
do
    local teleportSection = Tabs.Teleport:CreateSection("auto walk")
    local padSection = Tabs.Teleport:CreateSection("duel pads")

    local lobby = workspace:WaitForChild("Lobby")
    local groups = { DuelRing_1v1 = 1, DuelRing_2v2 = 2, DuelRing_3v3 = 3, DuelRing_4v4 = 4 }
    local autoWalkToDuelPad = false
    local currentPadModel = nil
    local lastJumpTime = 0

    local function walkTo(model)
        local character = Player.Character
        if not character then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if humanoid and rootPart and model and model.PrimaryPart then
            local targetPosition = model.PrimaryPart.Position
            local distance = (rootPart.Position - targetPosition).Magnitude
            if distance <= 6 then
                getgenv().noclip = false
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
                return
            end
            humanoid.WalkSpeed = 35
            humanoid:MoveTo(targetPosition)
            if os.clock() - lastJumpTime >= 2 then
                humanoid.Jump = true
                lastJumpTime = os.clock()
            end
            getgenv().noclip = true
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end

    teleportSection:CreateToggle("AutoWalkDuelPad", {
        Text = "enable auto walk to duel pads",
        CurrentValue = false,
        Callback = function(value) autoWalkToDuelPad = value end
    })

    task.spawn(function()
        while true do
            if not Player:GetAttribute("Match") then
                if autoWalkToDuelPad then
                    local character = Player.Character
                    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                    if currentPadModel and rootPart then
                        local currentMaxCount = 1
                        for groupName, maxCount in pairs(groups) do
                            if lobby:FindFirstChild("DuelRingsGroup") and lobby.DuelRingsGroup:FindFirstChild(groupName) then
                                if lobby.DuelRingsGroup[groupName]:FindFirstChild(currentPadModel.Name) then
                                    currentMaxCount = maxCount
                                    break
                                end
                            end
                        end
                        if currentMaxCount == 1 then
                            local opponentFound = false
                            for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
                                if otherPlayer ~= Player and otherPlayer.Character then
                                    local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                                    if otherRoot then
                                        local dist = (rootPart.Position - otherRoot.Position).Magnitude
                                        if dist <= 8 then opponentFound = true break end
                                    end
                                end
                            end
                            if not opponentFound then currentPadModel = nil end
                        end
                    end
                    if currentPadModel and rootPart then
                        local stillValid = false
                        for _, groupFolder in ipairs(lobby:GetChildren()) do
                            if groupFolder.Name == "DuelRingsGroup" then
                                for groupName, maxCount in pairs(groups) do
                                    local ringFolder = groupFolder:FindFirstChild(groupName)
                                    if ringFolder and ringFolder:FindFirstChild(currentPadModel.Name) then
                                        local totalPlayersInGroup = 0
                                        local maxPlayersForGroup = maxCount * 2
                                        local targetedPadStillNeedsPlayer = false
                                        for _, model in ipairs(ringFolder:GetChildren()) do
                                            if model:IsA("Model") and model.Name == "DuelPad" then
                                                local count = model:GetAttribute("CharacterCount") or 0
                                                totalPlayersInGroup = totalPlayersInGroup + count
                                                if model == currentPadModel and count < maxCount then
                                                    targetedPadStillNeedsPlayer = true
                                                end
                                            end
                                        end
                                        if (totalPlayersInGroup == maxPlayersForGroup - 1 and targetedPadStillNeedsPlayer) or (totalPlayersInGroup == maxPlayersForGroup) then
                                            stillValid = true
                                        end
                                        break
                                    end
                                end
                            end
                            if stillValid then break end
                        end
                        if not stillValid then currentPadModel = nil end
                    end
                    if not currentPadModel then
                        local foundNewPad = false
                        for _, groupFolder in ipairs(lobby:GetChildren()) do
                            if groupFolder.Name == "DuelRingsGroup" then
                                for groupName, maxCount in pairs(groups) do
                                    local ringFolder = groupFolder:FindFirstChild(groupName)
                                    if ringFolder then
                                        local pads = {}
                                        local totalPlayersInGroup = 0
                                        local maxPlayersForGroup = maxCount * 2
                                        for _, model in ipairs(ringFolder:GetChildren()) do
                                            if model:IsA("Model") and model.Name == "DuelPad" then
                                                local count = model:GetAttribute("CharacterCount") or 0
                                                totalPlayersInGroup = totalPlayersInGroup + count
                                                table.insert(pads, { model = model, count = count })
                                            end
                                        end
                                        if totalPlayersInGroup == maxPlayersForGroup - 1 then
                                            for _, pad in ipairs(pads) do
                                                if pad.count < maxCount then
                                                    local opponentReady = true
                                                    if maxCount == 1 then
                                                        opponentReady = false
                                                        for _, otherPlayer in ipairs(game:GetService("Players"):GetPlayers()) do
                                                            if otherPlayer ~= Player and otherPlayer.Character then
                                                                local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                                                                if otherRoot and pad.model.PrimaryPart then
                                                                    local dist = (otherRoot.Position - pad.model.PrimaryPart.Position).Magnitude
                                                                    if dist <= 8 then opponentReady = true break end
                                                                end
                                                            end
                                                        end
                                                    end
                                                    if opponentReady then
                                                        walkTo(pad.model)
                                                        if rootPart and pad.model.PrimaryPart then
                                                            local distance = (rootPart.Position - pad.model.PrimaryPart.Position).Magnitude
                                                            if distance <= 6 then currentPadModel = pad.model end
                                                        end
                                                        foundNewPad = true
                                                        task.wait(0.5)
                                                        break
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    if foundNewPad then break end
                                end
                            end
                            if foundNewPad then break end
                        end
                    end
                else
                    currentPadModel = nil
                end
            else
                currentPadModel = nil
            end
            task.wait(0.2)
        end
    end)

    if lobby and lobby:FindFirstChild("DuelRingsGroup") then
        for groupName, _ in pairs(groups) do
            local ringFolder = lobby.DuelRingsGroup:FindFirstChild(groupName)
            if ringFolder then
                local padIndex = 1
                for _, model in ipairs(ringFolder:GetChildren()) do
                    if model:IsA("Model") and model.Name == "DuelPad" then
                        local sideName = (padIndex % 2 == 1) and "Right" or "Left"
                        local cleanTitle = "walk to " .. groupName .. " " .. sideName
                        padSection:CreateButton({Name = cleanTitle, Callback = function()
                            Library.Notify({Title = "Ivory", Content = "Walking to position!", Type = "Info", Duration = 3})
                            walkTo(model)
                        end})
                        padIndex = padIndex + 1
                    end
                end
            end
        end
    end
end

-- ==================== FOV SHOOTING TAB ====================
do
    local fovSection = Tabs.FOV:CreateSection("fov settings")
    local fovSection2 = Tabs.FOV:CreateSection("fov controls")

    local fov_autoshoot_enabled = false
    local fov_manualShoot_enabled = false
    local fov_circle_enabled = false
    local fov_radius = 100
    local fov_shoot_cooldown = 1
    local fov_last_shot = 0
    local fov_circle = nil
    local fov_gunController = nil

    local function createFovCircle()
        if fov_circle then fov_circle:Remove() end
        fov_circle = Drawing.new("Circle")
        fov_circle.Thickness = 2
        fov_circle.NumSides = 64
        fov_circle.Radius = fov_radius
        fov_circle.Color = Color3.fromRGB(255, 255, 255)
        fov_circle.Transparency = 1
        fov_circle.Visible = false
        fov_circle.Filled = false
    end
    createFovCircle()

    local function update_fov_circle()
        if fov_circle and (fov_circle_enabled or fov_autoshoot_enabled or fov_manualShoot_enabled) then
            local mouse_pos = UserInputService:GetMouseLocation()
            fov_circle.Position = Vector2.new(mouse_pos.X, mouse_pos.Y)
            fov_circle.Radius = fov_radius
            fov_circle.Visible = true
        elseif fov_circle then
            fov_circle.Visible = false
        end
    end

    local function is_in_fov(target_position)
        local screen_pos, on_screen = Camera:WorldToViewportPoint(target_position)
        if not on_screen then return false end
        local mouse_pos = UserInputService:GetMouseLocation()
        local distance = math.sqrt((screen_pos.X - mouse_pos.X) ^ 2 + (screen_pos.Y - mouse_pos.Y) ^ 2)
        return distance <= fov_radius
    end

    local function has_clear_los_fov(from_pos, to_pos, target_character)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { Player.Character, target_character }
        params.FilterType = Enum.RaycastFilterType.Exclude
        local result = Workspace:Raycast(from_pos, (to_pos - from_pos), params)
        if result then
            if not result.Instance:IsDescendantOf(target_character) then return false end
        end
        return true
    end

    local function valid_enemy(enemy)
        if not enemy or enemy == Player then return false end
        local character = enemy.Character
        if not character or character.Parent ~= Workspace then return false end
        if enemy.Team and enemy.Team == Player.Team then return false end
        local humanoid = character:FindFirstChild("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local my_hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if not (humanoid and hrp and my_hrp) then return false end
        if humanoid.Health <= 0 then return false end
        if Collection:HasTag(character, "Invulnerable") or Collection:HasTag(character, "SpeedTrail") then return false end
        return true
    end

    local function shoot_enemy(target)
        local my_char = Player.Character
        local my_root = my_char and my_char:FindFirstChild("HumanoidRootPart")
        local target_hrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        if not (my_root and target_hrp) then return false end
        if not has_clear_los_fov(my_root.Position, target_hrp.Position, target.Character) then return false end
        if not is_in_fov(target_hrp.Position) then return false end
        local current_time = tick()
        if current_time - fov_last_shot < fov_shoot_cooldown then return false end
        local hit_part = target.Character:FindFirstChild("LowerTorso") or target.Character:FindFirstChild("UpperTorso") or target.Character:FindFirstChild("Head")
        if hit_part then
            ShootGun(target)
            fov_last_shot = current_time
            return true
        end
        return false
    end

    RunService.Heartbeat:Connect(function()
        update_fov_circle()
        if not fov_autoshoot_enabled then return end
        local my_char = Player.Character
        if not my_char then return end
        for _, enemy in pairs(Players:GetPlayers()) do
            if valid_enemy(enemy) then
                if shoot_enemy(enemy) then break end
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if fov_manualShoot_enabled and input.UserInputType == Enum.UserInputType.MouseButton1 then
            local current_time = tick()
            if current_time - fov_last_shot < fov_shoot_cooldown then return end
            local my_char = Player.Character
            if not my_char then return end
            for _, enemy in pairs(Players:GetPlayers()) do
                if valid_enemy(enemy) then
                    if shoot_enemy(enemy) then break end
                end
            end
        end
    end)

    local function start_gun_controller_loop()
        if fov_gunController then task.cancel(fov_gunController) end
        fov_gunController = task.spawn(function()
            while fov_manualShoot_enabled do
                task.wait()
                local gun_controller = Workspace:FindFirstChild(Player.Name)
                if gun_controller then
                    local controller = gun_controller:FindFirstChild("GunController")
                    if controller then controller.Parent = nil end
                end
            end
        end)
    end

    local function stop_gun_controller_loop()
        if fov_gunController then task.cancel(fov_gunController) fov_gunController = nil end
    end

    fovSection:CreateToggle("FovCircle", {
        Text = "enable fov circle",
        CurrentValue = false,
        Callback = function(value) fov_circle_enabled = value end
    })

    fovSection:CreateToggle("FovAutoshoot", {
        Text = "autoshoot fov",
        CurrentValue = false,
        Callback = function(value)
            fov_autoshoot_enabled = value
            if value then
                fov_manualShoot_enabled = false
                stop_gun_controller_loop()
            end
        end
    })

    fovSection:CreateToggle("FovManualShoot", {
        Text = "fov manual shoot",
        CurrentValue = false,
        Callback = function(value)
            fov_manualShoot_enabled = value
            if value then
                fov_autoshoot_enabled = false
                start_gun_controller_loop()
            else
                stop_gun_controller_loop()
            end
        end
    })

    fovSection2:CreateSlider("FovCircleSize", {
        Text = "fov circle size",
        Default = 100,
        Min = 35,
        Max = 300,
        Rounding = 0,
        Callback = function(value) fov_radius = value end,
    })

    fovSection2:CreateSlider("FovAutoshootCooldown", {
        Text = "fov autoshoot cooldown",
        Default = 2,
        Min = 0,
        Max = 5,
        Rounding = 1,
        Callback = function(value) fov_shoot_cooldown = value end,
    })
end

-- ==================== MISC TAB ====================
do
    local miscSection = Tabs.Misc:CreateSection("movement")

    getgenv().original_speed = 16
    getgenv().speed_enabled = false
    getgenv().current_speed = 16

    miscSection:CreateToggle("AutoSpin", {
        Text = "auto spin",
        CurrentValue = false,
        Callback = function(state)
            getgenv().autoSpin = state
            task.spawn(function()
                while getgenv().autoSpin do
                    if not Player:GetAttribute("Match") then
                        local SpinnerService = require(game:GetService("ReplicatedStorage").Dailies.SpinnerService)
                        SpinnerService.Spin()
                    end
                    task.wait(0.1)
                end
            end)
        end,
    })

    miscSection:CreateToggle("Noclip", {
        Text = "noclip",
        CurrentValue = false,
        Callback = function(state)
            getgenv().noclip = state
            FeatureActivated(state)
            if state then
                local noclipLoop
                noclipLoop = game:GetService("RunService").Stepped:Connect(function()
                    if not getgenv().noclip then noclipLoop:Disconnect() return end
                    local char = Player.Character
                    if char then
                        for _, part in ipairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then part.CanCollide = false end
                        end
                    end
                end)
            end
        end,
    })

    miscSection:CreateToggle("SpeedChanger", {
        Text = "enable speed changer",
        CurrentValue = false,
        Callback = function(Value)
            getgenv().speed_enabled = Value
            if Value then
                task.spawn(function()
                    while getgenv().speed_enabled do
                        local character = Player.Character
                        local humanoid = character and character:FindFirstChild("Humanoid")
                        if humanoid and humanoid.WalkSpeed ~= getgenv().current_speed then
                            humanoid.WalkSpeed = getgenv().current_speed
                        end
                        task.wait(0.1)
                    end
                end)
            else
                local character = Player.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = getgenv().original_speed end
            end
        end
    })

    miscSection:CreateSlider("WalkSpeed", {
        Text = "walk speed",
        Default = 16,
        Min = 16,
        Max = 200,
        Rounding = 0,
        Callback = function(speed)
            getgenv().current_speed = speed
            if getgenv().speed_enabled then
                local character = Player.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid then humanoid.WalkSpeed = speed end
            end
        end
    })

    Player.CharacterAdded:Connect(function(character)
        task.wait(0.2)
        if getgenv().speed_enabled then
            local humanoid = character:WaitForChild("Humanoid")
            humanoid.WalkSpeed = getgenv().current_speed
        end
    end)
end

-- ==================== UI SETTINGS TAB ====================
do
    local creditsSection = Tabs["UI Settings"]:CreateSection("credits")
    creditsSection:CreateLabel({Text = "made by mommy veqxoo", TextSize = 26})

    local menuSection = Tabs["UI Settings"]:CreateSection("menu settings")

    menuSection:CreateLabel("menu bind"):CreateKeybind("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "menu keybind",
    })

    menuSection:CreateToggle("KeybindVisible", {
        Text = "keybind list",
        CurrentValue = false,
    })

    menuSection:CreateSlider("FPSCap", {
        Text = "fps cap (0 = off)",
        Default = 0,
        Min = 0,
        Max = 9999,
        Rounding = 0,
        Compact = true,
        Callback = function(Value)
            if not setfpscap then return end
            if Value == nil or Value <= 0 or Value >= 9999 then
                setfpscap(0)
            else
                setfpscap(math.floor(Value))
            end
        end
    })

    menuSection:CreateDropdown("InstanceLanguage", {
        Text = "language",
        Values = { "english", "korean", "spanish" },
        Value = getgenv().InstanceLanguage or "english",
        Callback = function(val)
            getgenv().InstanceLanguage = val
            if getgenv().InstanceReloadLanguageFont then getgenv().InstanceReloadLanguageFont(val) end
            if getgenv().InstanceApplyUIFont then getgenv().InstanceApplyUIFont() end
            if getgenv().InstanceRefreshLocaleUI then pcall(getgenv().InstanceRefreshLocaleUI) end
        end,
    })

    menuSection:CreateToggle("AntiAFK", {
        Text = "anti afk",
        CurrentValue = true,
        Callback = function(val)
            if val then
                pcall(function()
                    local VirtualUser = game:GetService("VirtualUser")
                    game:GetService("Players").LocalPlayer.Idled:Connect(function()
                        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                        task.wait(0.1)
                        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
                    end)
                end)
            end
        end
    })

    menuSection:CreateButton({Name = "test notification", Callback = function()
        Library.Notify({Title = "Ivory", Content = "Notification works!", Type = "Success", Duration = 3})
    end})

    menuSection:CreateDropdown("NotifySideDropdown", {
        Text = "notification side",
        Value = "Right",
        Values = { "Left", "Right" },
        Callback = function(state) Library.SetNotifySide(state) end,
    })

    menuSection:CreateDropdown("DPIScale", {
        Text = "dpi scale",
        Value = "100%",
        Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
        Callback = function(state)
            local val = tonumber(state:gsub("%%", "")) / 100
            Library.DPIScale = val
        end,
    })

    menuSection:CreateSlider("CornerRadius", {
        Text = "corner radius",
        Default = 4,
        Min = 0,
        Max = 20,
        Rounding = 0,
        Callback = function(state) Library.CornerRadius = state end,
    })

    menuSection:CreateButton({Name = "unload menu", Callback = function() Library.Unload() end})
end

do
    local serverSection = Tabs["UI Settings"]:CreateSection("server")

    local function serverlist(cursor)
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end
        local success, response = pcall(function() return game:HttpGet(url) end)
        if not success then return nil end
        local success2, data = pcall(function() return HttpService:JSONDecode(response) end)
        if not success2 or not data or not data.data then return nil end
        return data
    end

    local function allservers()
        local servers = {}
        local cursor = nil
        repeat
            local data = serverlist(cursor)
            if not data then break end
            for _, server in ipairs(data.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    table.insert(servers, server)
                end
            end
            cursor = data.nextPageCursor
        until not cursor
        return servers
    end

    serverSection:CreateButton({Name = "rejoin server", Callback = function()
        if game.JobId ~= "" then
            Library.Notify({Title = "Ivory", Content = "Rejoining...", Type = "Info", Duration = 3})
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
        else
            Library.Notify({Title = "Ivory", Content = "No valid JobId", Type = "Error", Duration = 3})
        end
    end})

    serverSection:CreateButton({Name = "server hop (random)", Callback = function()
        local servers = allservers()
        if #servers == 0 then
            Library.Notify({Title = "Ivory", Content = "No servers found", Type = "Error", Duration = 3})
            return
        end
        local s = servers[math.random(#servers)]
        Library.Notify({Title = "Ivory", Content = "Hopping (" .. s.playing .. "/" .. s.maxPlayers .. ")", Type = "Info", Duration = 5})
        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
    end})

    serverSection:CreateButton({Name = "join lowest players", Callback = function()
        local servers = allservers()
        if #servers == 0 then
            Library.Notify({Title = "Ivory", Content = "No servers found", Type = "Error", Duration = 3})
            return
        end
        table.sort(servers, function(a, b) return a.playing < b.playing end)
        local s = servers[1]
        Library.Notify({Title = "Ivory", Content = "Joining lowest (" .. s.playing .. "/" .. s.maxPlayers .. ")", Type = "Info", Duration = 5})
        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
    end})

    serverSection:CreateButton({Name = "join biggest server", Callback = function()
        local servers = allservers()
        if #servers == 0 then
            Library.Notify({Title = "Ivory", Content = "No servers found", Type = "Error", Duration = 3})
            return
        end
        table.sort(servers, function(a, b) return a.playing > b.playing end)
        local s = servers[1]
        Library.Notify({Title = "Ivory", Content = "Joining biggest (" .. s.playing .. "/" .. s.maxPlayers .. ")", Type = "Info", Duration = 5})
        TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
    end})
end

do
    local themesSection = Tabs["UI Settings"]:CreateSection("themes")

    themesSection:CreateLabel({Text = "background"}):CreateColorPicker("ThemeBG", {
        Default = Color3.fromRGB(20, 20, 30),
        Title = "Background Color",
        Callback = function(Value)
            pcall(function()
                for _, obj in ipairs(Library.ScreenGui:GetDescendants()) do
                    if obj:IsA("Frame") and obj.BackgroundTransparency < 0.5 then
                        obj.BackgroundColor3 = Value
                    end
                end
            end)
        end,
    })

    themesSection:CreateLabel({Text = "accent"}):CreateColorPicker("ThemeAccent", {
        Default = Color3.fromRGB(128, 0, 255),
        Title = "Accent Color",
        Callback = function(Value)
            if Library.SetAccentColor then pcall(function() Library.SetAccentColor(Value) end) end
        end,
    })

    themesSection:CreateDropdown("ThemeList", {
        Text = "theme list",
        Values = { "Default", "Midnight", "Ocean", "Sunset", "Matrix" },
        Value = "Default",
        Callback = function(Value)
            Library.Notify({Title = "Ivory", Content = "Theme: " .. Value, Type = "Info", Duration = 3})
        end,
    })

    themesSection:CreateButton({Name = "set as default", Callback = function()
        Library.Notify({Title = "Ivory", Content = "Default theme saved", Type = "Success", Duration = 3})
    end})
end

-- ==================== CUSTOM CONFIG SYSTEM ====================
local _CONFIG_ROOT  = "IvoryHub"
local _CONFIG_SUBDIR = "IvoryHub/MVSD"
local _AUTOLOAD_PATH = "IvoryHub/MVSD/autoload.txt"

if not isfolder("IvoryHub") then makefolder("IvoryHub") end
if not isfolder(_CONFIG_SUBDIR) then makefolder(_CONFIG_SUBDIR) end

local _cfgRefs = {}
local _cfgBuildSnapshot = function() return {} end
local _cfgApplyFn = function(data) end

local function _cfgColorToTable(c)
    return { r = math.floor(c.R * 255), g = math.floor(c.G * 255), b = math.floor(c.B * 255) }
end
local function _cfgTableToColor(t)
    return Color3.fromRGB(t.r, t.g, t.b)
end

local function _cfgEncodeJSON(val, indent)
    indent = indent or 0
    local t = type(val)
    if t == "boolean" then return val and "true" or "false"
    elseif t == "number" then return tostring(val)
    elseif t == "string" then return '"' .. val:gsub('\\','\\\\'):gsub('"','\\"') .. '"'
    elseif t == "nil" then return "null"
    elseif t == "table" then
        local isArr = (#val > 0)
        if isArr then
            local parts = {}
            for _, v in ipairs(val) do parts[#parts+1] = _cfgEncodeJSON(v, indent+2) end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local pad = string.rep(" ", indent + 2)
            local endpad = string.rep(" ", indent)
            local parts = {}
            for k, v in pairs(val) do
                parts[#parts+1] = pad .. '"' .. tostring(k) .. '": ' .. _cfgEncodeJSON(v, indent+2)
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. endpad .. "}"
        end
    end
    return "null"
end

local function _cfgDecodeJSON(s)
    local pos = 1
    local function skip() while pos <= #s and s:sub(pos,pos):match("%s") do pos=pos+1 end end
    local function parseVal()
        skip()
        local c = s:sub(pos,pos)
        if c == '"' then
            pos=pos+1
            local start = pos
            while pos <= #s do
                local ch = s:sub(pos,pos)
                if ch == '\\' then pos=pos+2
                elseif ch == '"' then break
                else pos=pos+1 end
            end
            local str = s:sub(start, pos-1):gsub('\\"','"'):gsub('\\\\','\\')
            pos=pos+1
            return str
        elseif c == '{' then
            pos=pos+1; local tbl = {}
            skip()
            while s:sub(pos,pos) ~= '}' do
                skip()
                local key = parseVal(); skip()
                pos=pos+1
                local val = parseVal(); skip()
                tbl[key] = val
                if s:sub(pos,pos) == ',' then pos=pos+1 end
                skip()
            end
            pos=pos+1; return tbl
        elseif c == '[' then
            pos=pos+1; local arr = {}
            skip()
            while s:sub(pos,pos) ~= ']' do
                arr[#arr+1] = parseVal(); skip()
                if s:sub(pos,pos) == ',' then pos=pos+1 end
                skip()
            end
            pos=pos+1; return arr
        elseif s:sub(pos, pos+3) == "true" then pos=pos+4; return true
        elseif s:sub(pos, pos+4) == "false" then pos=pos+5; return false
        elseif s:sub(pos, pos+3) == "null" then pos=pos+4; return nil
        else
            local numStr = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
            if numStr then pos=pos+#numStr; return tonumber(numStr) end
        end
    end
    return parseVal()
end

local function _cfgListConfigs()
    local names = {}
    local ok, files = pcall(listfiles, _CONFIG_SUBDIR)
    if not ok then return names end
    for _, path in ipairs(files) do
        local name = path:match("([^/\\]+)%.json$")
        if name and name ~= "autoload" then names[#names+1] = name end
    end
    return names
end

local function _cfgSave(name)
    if not name or name == "" then
        Library.Notify({Title = "Ivory", Content = "Enter a config name first!", Type = "Error", Duration = 3})
        return
    end
    local path = _CONFIG_SUBDIR .. "/" .. name .. ".json"
    local snap = _cfgBuildSnapshot()
    local ok, err = pcall(writefile, path, _cfgEncodeJSON(snap))
    if ok then
        Library.Notify({Title = "Ivory", Content = "Config Saved: " .. name, Type = "Success", Duration = 3})
    else
        Library.Notify({Title = "Ivory", Content = "Config Error: " .. tostring(err), Type = "Error", Duration = 3})
    end
end

local function _cfgDelete(name)
    if not name or name == "" then return end
    local path = _CONFIG_SUBDIR .. "/" .. name .. ".json"
    if isfile(path) then
        pcall(delfile, path)
        Library.Notify({Title = "Ivory", Content = "Config Deleted: " .. name, Type = "Info", Duration = 3})
    end
end

local function _cfgSetAutoload(name)
    if not name or name == "" then return end
    pcall(writefile, _AUTOLOAD_PATH, name)
end

local function _cfgClearAutoload()
    if isfile(_AUTOLOAD_PATH) then pcall(delfile, _AUTOLOAD_PATH) end
end

local function _cfgLoad(name)
    if not name or name == "" then
        Library.Notify({Title = "Ivory", Content = "Enter a config name first!", Type = "Error", Duration = 3})
        return
    end
    local path = _CONFIG_SUBDIR .. "/" .. name .. ".json"
    if not isfile(path) then
        Library.Notify({Title = "Ivory", Content = name .. " not found", Type = "Error", Duration = 3})
        return
    end
    local ok, raw = pcall(readfile, path)
    if not ok then
        Library.Notify({Title = "Ivory", Content = "Could not read file", Type = "Error", Duration = 3})
        return
    end
    local ok2, data = pcall(_cfgDecodeJSON, raw)
    if not ok2 or type(data) ~= "table" then
        Library.Notify({Title = "Ivory", Content = "Corrupt config", Type = "Error", Duration = 3})
        return
    end
    if _cfgApplyFn then _cfgApplyFn(data) end
    Library.Notify({Title = "Ivory", Content = "Config Loaded: " .. name, Type = "Success", Duration = 3})
end

local function _cfgRefreshList(dropdownRef)
    local names = _cfgListConfigs()
    names[#names+1] = "---"
    if dropdownRef then pcall(function() dropdownRef:Refresh(names, "---") end) end
end

do
    local configSection = Tabs["UI Settings"]:CreateSection("configuration")
    local configNameValue = ""

    _cfgRefs.ConfigNameInput = configSection:CreateInput("ConfigName", {
        Text = "config name",
        Default = "",
        Placeholder = "myconfig",
        Callback = function(v) configNameValue = v end,
    })

    configSection:CreateButton({Name = "create config", Callback = function()
        _cfgSave(configNameValue)
        _cfgRefreshList(_cfgRefs.ConfigList)
    end})

    local initialNames = _cfgListConfigs()
    initialNames[#initialNames+1] = "---"

    _cfgRefs.ConfigList = configSection:CreateDropdown("ConfigList", {
        Text = "config list",
        Values = initialNames,
        Value = "---",
        Callback = function(Value)
            if Value ~= "---" then
                configNameValue = Value
                pcall(function() _cfgRefs.ConfigNameInput:Set(Value) end)
            end
        end,
    })

    configSection:CreateButton({Name = "load config", Callback = function() _cfgLoad(configNameValue) end})

    configSection:CreateButton({Name = "overwrite config", Callback = function()
        if not configNameValue or configNameValue == "" then return end
        _cfgSave(configNameValue)
    end})

    configSection:CreateButton({Name = "delete config", Callback = function()
        _cfgDelete(configNameValue)
        _cfgRefreshList(_cfgRefs.ConfigList)
    end})

    configSection:CreateButton({Name = "refresh list", Callback = function()
        _cfgRefreshList(_cfgRefs.ConfigList)
        Library.Notify({Title = "Ivory", Content = "List refreshed", Type = "Info", Duration = 3})
    end})

    configSection:CreateButton({Name = "set as autoload", Callback = function()
        _cfgSetAutoload(configNameValue)
        Library.Notify({Title = "Ivory", Content = "Autoload set: " .. configNameValue, Type = "Success", Duration = 3})
    end})

    configSection:CreateButton({Name = "reset autoload", Callback = function()
        _cfgClearAutoload()
        Library.Notify({Title = "Ivory", Content = "Autoload cleared", Type = "Info", Duration = 3})
    end})

    configSection:CreateLabel({Text = "current autoload: none"})

    local configJSONValue = ""
    configSection:CreateInput("ConfigJSON", {
        Text = "config json",
        Default = "",
        Placeholder = "paste config json here",
        Callback = function(v) configJSONValue = v end,
    })

    configSection:CreateButton({Name = "import config", Callback = function()
        if not configNameValue or configNameValue == "" then return end
        if not configJSONValue or configJSONValue == "" then return end
        local ok2, data = pcall(_cfgDecodeJSON, configJSONValue)
        if not ok2 or type(data) ~= "table" then
            Library.Notify({Title = "Ivory", Content = "Invalid JSON", Type = "Error", Duration = 3})
            return
        end
        local path = _CONFIG_SUBDIR .. "/" .. configNameValue .. ".json"
        pcall(writefile, path, configJSONValue)
        Library.Notify({Title = "Ivory", Content = "Config imported: " .. configNameValue, Type = "Success", Duration = 3})
    end})

    configSection:CreateButton({Name = "export current config", Callback = function()
        if not configNameValue or configNameValue == "" then return end
        local path = _CONFIG_SUBDIR .. "/" .. configNameValue .. ".json"
        if not isfile(path) then return end
        local ok, raw = pcall(readfile, path)
        if ok and raw then
            pcall(setclipboard, raw)
            Library.Notify({Title = "Ivory", Content = "Config JSON copied to clipboard", Type = "Success", Duration = 3})
        end
    end})
end

_cfgBuildSnapshot = function()
    local snap = {}
    for name, toggle in pairs(Toggles) do
        if type(toggle) == "table" and toggle.Value ~= nil then
            local v = toggle.Value
            if typeof(v) == "Color3" then
                snap[name] = _cfgColorToTable(v)
            elseif typeof(v) == "EnumItem" then
                snap[name] = tostring(v)
            else
                snap[name] = v
            end
        end
    end
    return snap
end

_cfgApplyFn = function(data)
    if not data then return end
    for name, value in pairs(data) do
        if Toggles[name] and type(Toggles[name]) == "table" then
            pcall(function()
                if typeof(value) == "table" and value.r and value.g and value.b then
                    Toggles[name].Value = _cfgTableToColor(value)
                else
                    Toggles[name].Value = value
                end
                if Toggles[name].Set then Toggles[name]:Set(value) end
            end)
        end
    end
end

task.delay(0.5, function()
    if isfile(_AUTOLOAD_PATH) then
        local ok, name = pcall(readfile, _AUTOLOAD_PATH)
        if ok and name and name ~= "" then
            name = name:gsub("%s+","")
            if name ~= "" then
                Library.Notify({Title = "Ivory", Content = "Loading config: \""..name.."\"", Type = "Info", Duration = 3})
                task.wait(0.3)
                _cfgLoad(name)
            end
        end
    end
end)

Library.Notify({Title = "Ivory MVSD", Content = "Loaded successfully!", Type = "Success", Duration = 5})
