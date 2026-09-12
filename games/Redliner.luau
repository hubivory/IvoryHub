--!nocheck
-- REDLINER  -  Ivory Hub
--
-- A movement shooter that is half swordfight: melee, gun, grapple, dash, slide,
-- wallrun, and a PARRY that stops bullets as well as blades. Three places, all
-- three read from the game's own CEnum.PlaceIds:
--
--     MAIN_PLACE   94987506187454   hub + matchmaking
--     MATCH_PLACE  126691165749976  1v1 / 2v2 duels
--     FFA_PLACE    115875349872417  free-for-all, 12 players

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local plr = Players.LocalPlayer
local cam = Workspace.CurrentCamera

--------------------------------------------------------------------------------
-- library loading
--------------------------------------------------------------------------------

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

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
    writefile(LIB_FILE, httpGet(LIB_URL))
end
local Library = loadstring(readfile(LIB_FILE))()

--------------------------------------------------------------------------------
-- generation guard
--------------------------------------------------------------------------------

_G.__REDLINER = (_G.__REDLINER or 0) + 1
local GEN = _G.__REDLINER
local function live() return GEN == _G.__REDLINER end

if _G.__REDLINER_POOL then
    for _, set in pairs(_G.__REDLINER_POOL) do
        for _, obj in pairs(set) do pcall(function() obj:Remove() end) end
    end
end
_G.__REDLINER_POOL = {}
local POOL = _G.__REDLINER_POOL

if _G.__REDLINER_CHAMS then
    for _, hl in pairs(_G.__REDLINER_CHAMS) do pcall(function() hl:Destroy() end) end
end
_G.__REDLINER_CHAMS = {}
local CHAMS = _G.__REDLINER_CHAMS

for _, name in ipairs({ "__REDLINER_AIM", "__REDLINER_ESP" }) do
    pcall(function() RunService:UnbindFromRenderStep(name) end)
end

--------------------------------------------------------------------------------
-- places
--------------------------------------------------------------------------------

local PLACE_MAIN, PLACE_MATCH, PLACE_FFA = 94987506187454, 126691165749976, 115875349872417

local function placeKind()
    local id = game.PlaceId
    if id == PLACE_MAIN then return "HUB" end
    if id == PLACE_FFA then return "FFA" end
    if id == PLACE_MATCH then return "DUEL" end
    local m = ReplicatedFirst:FindFirstChild("IS_MATCH_PLACE")
    local mm = ReplicatedFirst:FindFirstChild("IS_MATCHMAKING_PLACE")
    if m and m.Value then return "DUEL" end
    if mm and mm.Value then return "HUB" end
    return "?"
end

--------------------------------------------------------------------------------
-- config
--------------------------------------------------------------------------------

local CONFIG = {
    esp = true,
    espBox = true,
    espName = true,
    espDist = true,
    espHealth = false,
    espHeadDot = false,
    espSkeleton = false,
    espTracer = false,
    espChams = false,
    espMaxDist = 900,
    espVisibleOnly = false,
    espTextSize = 14,
    espFont = "System",
    espColour = Color3.fromRGB(255, 64, 64),

    aim = false,
    aimActivation = "Hotkey",
    aimKey = "E",
    aimPart = "Head",
    aimPick = "Crosshair",
    aimFov = 120,
    aimSmoothH = 4,
    aimSmoothV = 4,
    aimMaxDist = 400,
    aimVisibleOnly = true,
    aimSticky = true,
    aimShowFov = true,

    trigger = false,
    triggerActivation = "Hotkey",
    triggerKey = "C",
    triggerDelayMin = 60,
    triggerDelayMax = 140,
    triggerHeadOnly = false,
    triggerMaxDist = 400,
    triggerLockout = 250,

    parry = false,
    parryKey = "F",
    parryRange = 30,
    parryDelay = 100,
    parryGun = true,
    parryGunRange = 250,
    parryFacing = true,
    parryCooldown = 0,

    aura = false,
    auraActivation = "Hotkey",
    auraKey = "V",
    auraRange = 25,
    auraAngle = 45,
    auraFaceTarget = false,
    auraInterval = 660,
    auraNeedSword = true,
    auraVisibleOnly = true,

    moveBhop = false,
    moveBhopKey = "Space",
    moveBhopRate = 60,
    moveSlide = false,
    moveSlideKey = "LeftControl",
    moveSlideEvery = 1200,

    humanTurnCap = 420,
    humanWindup = 60,
    humanDeadzone = 2,
    humanReactMin = 40,
    humanReactMax = 110,
}

local DEFAULTS = {}
for k, v in pairs(CONFIG) do DEFAULTS[k] = v end

local STATE = {
    note = "",
    targets = 0,
    drawn = 0,
    target = nil,
    fps = 0,
    parryAttacks = 0,
    parryFired = 0,
    parrySuccess = 0,
    parryLast = "-",
    shots = 0,
    aimStep = 0,
    aimPeak = 0,
    healthMoves = 0,
    healthSamples = 0,
    auraClicks = 0,
    auraSwings = 0,
    auraHits = 0,
    lastSwingAt = 0,
    auraModel = nil,
    lastSwingSeen = 0,
    auraTarget = nil,
    bhops = 0,
    slides = 0,
}

local function note(text) STATE.note = tostring(text) end

--------------------------------------------------------------------------------
-- accessors
--------------------------------------------------------------------------------

local ENTITIES = Workspace:FindFirstChild("Entities")

local function entitiesFolder()
    if ENTITIES and ENTITIES.Parent then return ENTITIES end
    ENTITIES = Workspace:FindFirstChild("Entities")
    return ENTITIES
end

local function myChar() return plr.Character end

local function myRoot()
    local c = myChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function roFolder()
    local ro = ReplicatedStorage:FindFirstChild("ReadOnly")
    return ro and ro:FindFirstChild("Players")
end

local function roEntry(name)
    local folder = roFolder()
    if not folder then return nil end
    local p = Players:FindFirstChild(name)
    if not p then return nil end
    return folder:FindFirstChild(tostring(p.UserId))
end

local function roValue(name, field, fallback)
    local e = roEntry(name)
    local v = e and e:FindFirstChild(field)
    if v and v:IsA("ValueBase") then return v.Value end
    return fallback
end

local function aliveOf(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local status = roValue(model.Name, "status", "alive")
    return status ~= "suspended" and status ~= "dead"
end

local function combatants()
    local folder = entitiesFolder()
    local out = {}
    if not folder then return out end
    local mine = myChar()
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") and m ~= mine and m.Name ~= plr.Name then
            local root = m:FindFirstChild("HumanoidRootPart")
            if root and aliveOf(m) then out[#out + 1] = m end
        end
    end
    return out
end

local function headHurtbox(model)
    local hb = model:FindFirstChild("Hurtboxes")
    local part = hb and hb:FindFirstChild("Head_Hurtbox")
    if part and part:IsA("BasePart") then return part end
    return model:FindFirstChild("Head")
end

local function bodyPart(model)
    return model:FindFirstChild("Torso") or model:FindFirstChild("HumanoidRootPart")
end

local function equippedWeapon(model)
    for _, m in ipairs(model:GetChildren()) do
        if m:IsA("Model") then
            local motors = m:FindFirstChild("CharacterMotor6D")
            local eq = motors and motors:FindFirstChild("Equipped")
            if eq and eq:IsA("Motor6D") and eq.Part0 then return m.Name end
        end
    end
    return nil
end

local function healthOf(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then return 0, 100 end
    return hum.Health, math.max(hum.MaxHealth, 1)
end

--------------------------------------------------------------------------------
-- visibility
--------------------------------------------------------------------------------

local ignore = {}
local ignoreAt = 0

local function rebuildIgnore()
    local list = {}
    local folder = entitiesFolder()
    if folder then
        for _, m in ipairs(folder:GetChildren()) do list[#list + 1] = m end
    end
    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, d in ipairs(map:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency >= 1 and not d.CanCollide then
                list[#list + 1] = d
            end
        end
    end
    local fx = Workspace:FindFirstChild("Effects")
    if fx then list[#list + 1] = fx end
    local debris = Workspace:FindFirstChild("Debris")
    if debris then list[#list + 1] = debris end
    ignore = list
    ignoreAt = os.clock()
end

local function ignoreList()
    if os.clock() - ignoreAt > 1 then rebuildIgnore() end
    return ignore
end

local function visibleTo(part)
    if not part then return false end
    local origin = cam.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = ignoreList()
    local dir = part.Position - origin
    local hit = Workspace:Raycast(origin, dir, params)
    return hit == nil
end

--------------------------------------------------------------------------------
-- drawing pool
--------------------------------------------------------------------------------

local FONTS = { UI = 0, System = 1, Plex = 2, Monospace = 3 }

local function fontId() return FONTS[CONFIG.espFont] or 1 end

local function make(kind, props)
    local ok, obj = pcall(function() return Drawing.new(kind) end)
    if not ok or not obj then return nil end
    for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    return obj
end

local BONES = {
    { "Head", "Torso" },
    { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local function objectsFor(model)
    local set = POOL[model]
    if set then return set end
    set = {}
    set.box = make("Square", { Thickness = 1, Filled = false, Color = Color3.new(1, 0, 0) })
    set.outline = make("Square", { Thickness = 3, Filled = false, Color = Color3.new(0, 0, 0) })
    set.name = make("Text", { Size = 14, Center = true, Outline = true, Font = 1 })
    set.info = make("Text", { Size = 13, Center = true, Outline = true, Font = 1 })
    set.hpBack = make("Square", { Thickness = 1, Filled = true, Color = Color3.new(0, 0, 0) })
    set.hpFill = make("Square", { Thickness = 1, Filled = true, Color = Color3.new(0, 1, 0) })
    set.head = make("Circle", { Thickness = 1, Filled = false, NumSides = 14 })
    set.tracer = make("Line", { Thickness = 1 })
    set.bones = {}
    for i = 1, #BONES do
        set.bones[i] = make("Line", { Thickness = 1 })
    end
    POOL[model] = set
    return set
end

local function hideSet(set)
    for k, obj in pairs(set) do
        if k == "bones" then
            for _, b in ipairs(obj) do if b then b.Visible = false end end
        elseif obj then
            obj.Visible = false
        end
    end
end

local function hideAll()
    for _, set in pairs(POOL) do hideSet(set) end
end

local function reapPool()
    for model, set in pairs(POOL) do
        if not model.Parent then
            for k, obj in pairs(set) do
                if k == "bones" then
                    for _, b in ipairs(obj) do if b then pcall(function() b:Remove() end) end end
                elseif obj then
                    pcall(function() obj:Remove() end)
                end
            end
            POOL[model] = nil
        end
    end
end

--------------------------------------------------------------------------------
-- chams
--------------------------------------------------------------------------------

local chamRoot

local function chamsRoot()
    if chamRoot and chamRoot.Parent then return chamRoot end
    local candidates = {}
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then candidates[#candidates + 1] = hui end
    end
    local ok2, core = pcall(function() return game:GetService("CoreGui") end)
    if ok2 and core then candidates[#candidates + 1] = core end
    candidates[#candidates + 1] = plr:FindFirstChildOfClass("PlayerGui")
    for _, parent in ipairs(candidates) do
        local made = pcall(function()
            local f = Instance.new("Folder")
            f.Name = "RL_" .. tostring(math.random(100000, 999999))
            f.Parent = parent
            chamRoot = f
        end)
        if made and chamRoot then return chamRoot end
    end
    return nil
end

local function chamFor(model)
    local hl = CHAMS[model]
    if hl and hl.Parent then return hl end
    local root = chamsRoot()
    if not root then return nil end
    local ok, made = pcall(function()
        local h = Instance.new("Highlight")
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.65
        h.OutlineTransparency = 0
        h.Adornee = model
        h.Parent = root
        return h
    end)
    if ok and made then
        CHAMS[model] = made
        return made
    end
    return nil
end

local function clearChams()
    for model, hl in pairs(CHAMS) do
        pcall(function() hl:Destroy() end)
        CHAMS[model] = nil
    end
end

--------------------------------------------------------------------------------
-- geometry
--------------------------------------------------------------------------------

local function dimmed(colour)
    local h, s, v = Color3.toHSV(colour)
    return Color3.fromHSV(h, s, v * 0.55)
end

local function screenRect(model)
    local head = model:FindFirstChild("Head")
    local ll = model:FindFirstChild("Left Leg")
    local rl = model:FindFirstChild("Right Leg")
    local root = model:FindFirstChild("HumanoidRootPart")
    if not head or not root then return nil end
    local low = ll
    if rl and (not ll or rl.Position.Y <= ll.Position.Y) then low = rl end
    local topPos = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.35, 0)
    local botPos = low and (low.Position - Vector3.new(0, low.Size.Y / 2, 0))
        or (root.Position - Vector3.new(0, 3, 0))
    local sTop, onTop = cam:WorldToViewportPoint(topPos)
    local sBot = cam:WorldToViewportPoint(botPos)
    if sTop.Z <= 0 or sBot.Z <= 0 or not onTop then return nil end
    local h = math.abs(sBot.Y - sTop.Y)
    if h < 3 then return nil end
    local w = h * 0.52
    return sTop.X - w / 2, sTop.Y, w, h
end

local function centreOf()
    local ok, loc = pcall(function() return UserInputService:GetMouseLocation() end)
    if ok and loc then return Vector2.new(loc.X, loc.Y) end
    return cam.ViewportSize / 2
end

--------------------------------------------------------------------------------
-- ESP render pass
--------------------------------------------------------------------------------

local fovCircle = make("Circle", { Thickness = 1, Filled = false, NumSides = 48,
    Color = Color3.fromRGB(200, 200, 200), Transparency = 0.7 })

local lastHealth = {}

local function renderPass()
    if not live() then return end
    local drawn = 0
    local list = combatants()
    STATE.targets = #list

    if not CONFIG.esp then
        hideAll()
        if fovCircle then fovCircle.Visible = false end
        clearChams()
        return
    end

    local root = myRoot()
    local seen = {}

    for _, model in ipairs(list) do
        seen[model] = true
        local set = objectsFor(model)
        local head = model:FindFirstChild("Head")
        local body = bodyPart(model)
        local dist = (root and body) and (root.Position - body.Position).Magnitude or 0

        local hp, maxHp = healthOf(model)
        local prev = lastHealth[model]
        if prev and math.abs(prev - hp) > 0.5 then STATE.healthMoves = STATE.healthMoves + 1 end
        lastHealth[model] = hp
        STATE.healthSamples = STATE.healthSamples + 1

        local vis = (not CONFIG.espVisibleOnly) or visibleTo(headHurtbox(model))
        local inRange = dist <= CONFIG.espMaxDist

        if CONFIG.espChams and inRange then
            local hl = chamFor(model)
            if hl then
                hl.Adornee = model
                hl.FillColor = vis and CONFIG.espColour or dimmed(CONFIG.espColour)
                hl.OutlineColor = CONFIG.espColour
                hl.Enabled = true
            end
        elseif CHAMS[model] then
            CHAMS[model].Enabled = false
        end

        local x, y, w, h = nil, nil, nil, nil
        if inRange and (vis or not CONFIG.espVisibleOnly) then
            x, y, w, h = screenRect(model)
        end

        if not x then
            hideSet(set)
        else
            drawn = drawn + 1
            local colour = vis and CONFIG.espColour or dimmed(CONFIG.espColour)
            local textSize = math.max(12, math.floor(CONFIG.espTextSize))

            if CONFIG.espBox and set.box and set.outline then
                set.outline.Size = Vector2.new(w, h)
                set.outline.Position = Vector2.new(x, y)
                set.outline.Color = Color3.new(0, 0, 0)
                set.outline.Visible = true
                set.box.Size = Vector2.new(w, h)
                set.box.Position = Vector2.new(x, y)
                set.box.Color = colour
                set.box.Visible = true
            else
                if set.box then set.box.Visible = false end
                if set.outline then set.outline.Visible = false end
            end

            if CONFIG.espName and set.name then
                set.name.Text = model.Name
                set.name.Size = textSize
                set.name.Font = fontId()
                set.name.Color = colour
                set.name.Position = Vector2.new(x + w / 2, y - textSize - 2)
                set.name.Visible = true
            elseif set.name then set.name.Visible = false end

            if CONFIG.espDist and set.info then
                local lvl = roValue(model.Name, "level", nil)
                local streak = roValue(model.Name, "killstreak", nil)
                local bits = { math.floor(dist) .. "m" }
                if lvl then bits[#bits + 1] = "lv" .. tostring(lvl) end
                local weapon = equippedWeapon(model)
                if weapon then bits[#bits + 1] = weapon end
                if streak and streak > 0 then bits[#bits + 1] = "x" .. tostring(streak) end
                set.info.Text = table.concat(bits, "  ")
                set.info.Size = math.max(12, textSize - 1)
                set.info.Font = fontId()
                set.info.Color = colour
                set.info.Position = Vector2.new(x + w / 2, y + h + 2)
                set.info.Visible = true
            elseif set.info then set.info.Visible = false end

            if CONFIG.espHealth and set.hpBack and set.hpFill then
                local frac = math.clamp(hp / maxHp, 0, 1)
                set.hpBack.Size = Vector2.new(3, h)
                set.hpBack.Position = Vector2.new(x - 6, y)
                set.hpBack.Visible = true
                set.hpFill.Size = Vector2.new(3, h * frac)
                set.hpFill.Position = Vector2.new(x - 6, y + h * (1 - frac))
                set.hpFill.Color = Color3.fromRGB(255 - math.floor(200 * frac), 60 + math.floor(180 * frac), 60)
                set.hpFill.Visible = true
            else
                if set.hpBack then set.hpBack.Visible = false end
                if set.hpFill then set.hpFill.Visible = false end
            end

            if CONFIG.espHeadDot and set.head and head then
                local sp = cam:WorldToViewportPoint(head.Position)
                if sp.Z > 0 then
                    set.head.Radius = math.max(2, h * 0.075)
                    set.head.Position = Vector2.new(sp.X, sp.Y)
                    set.head.Color = colour
                    set.head.Visible = true
                else
                    set.head.Visible = false
                end
            elseif set.head then set.head.Visible = false end

            if CONFIG.espTracer and set.tracer then
                set.tracer.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                set.tracer.To = Vector2.new(x + w / 2, y + h)
                set.tracer.Color = colour
                set.tracer.Visible = true
            elseif set.tracer then set.tracer.Visible = false end

            if CONFIG.espSkeleton and set.bones then
                for i, bone in ipairs(BONES) do
                    local a = model:FindFirstChild(bone[1])
                    local b = model:FindFirstChild(bone[2])
                    local line = set.bones[i]
                    if line and a and b then
                        local pa = cam:WorldToViewportPoint(a.Position)
                        local pb = cam:WorldToViewportPoint(b.Position)
                        if pa.Z > 0 and pb.Z > 0 then
                            line.From = Vector2.new(pa.X, pa.Y)
                            line.To = Vector2.new(pb.X, pb.Y)
                            line.Color = colour
                            line.Visible = true
                        else
                            line.Visible = false
                        end
                    elseif line then
                        line.Visible = false
                    end
                end
            elseif set.bones then
                for _, line in ipairs(set.bones) do if line then line.Visible = false end end
            end
        end
    end

    for model, set in pairs(POOL) do
        if not seen[model] then hideSet(set) end
    end
    for model, hl in pairs(CHAMS) do
        if not seen[model] then hl.Enabled = false end
    end

    if fovCircle then
        if CONFIG.aim and CONFIG.aimShowFov then
            local c = centreOf()
            fovCircle.Position = c
            fovCircle.Radius = CONFIG.aimFov
            fovCircle.Visible = true
        else
            fovCircle.Visible = false
        end
    end

    STATE.drawn = drawn
end

--------------------------------------------------------------------------------
-- input helpers
--------------------------------------------------------------------------------

local TOUCH = UserInputService.TouchEnabled
    and not UserInputService.MouseEnabled
    and not UserInputService.KeyboardEnabled
if _G.__REDLINER_FORCE_TOUCH then TOUCH = true end

local keyCache = {}

local function resolveKey(name)
    if keyCache[name] ~= nil then return keyCache[name] end
    local found = nil
    pcall(function()
        if Enum.UserInputType[name] then found = { kind = "mouse", value = Enum.UserInputType[name] } end
    end)
    if not found then
        pcall(function()
            if Enum.KeyCode[name] then found = { kind = "key", value = Enum.KeyCode[name] } end
        end)
    end
    keyCache[name] = found or false
    return keyCache[name]
end

local function reachable(name)
    local k = resolveKey(name)
    if not k then return false end
    if k.kind == "mouse" then return UserInputService.MouseEnabled end
    return UserInputService.KeyboardEnabled
end

local function screenHeld()
    local ok2, touches = pcall(function() return UserInputService:GetMouseButtonsPressed() end)
    if ok2 and touches then
        for _, t in ipairs(touches) do
            if t.UserInputType == Enum.UserInputType.Touch then return true end
        end
    end
    return false
end

local function keyHeld(name)
    local k = resolveKey(name)
    if not k then return false end
    local ok, down = pcall(function()
        if k.kind == "mouse" then
            return UserInputService:IsMouseButtonPressed(k.value)
        end
        return UserInputService:IsKeyDown(k.value)
    end)
    return ok and down or false
end

local function hotkeyHeld(name)
    if TOUCH and not reachable(name) then return screenHeld() end
    return keyHeld(name)
end

local INPUT = { key = "none", mouse = "none", probed = false }

local function vimService()
    local ok, vim = pcall(function() return game:GetService("VirtualInputManager") end)
    if ok then return vim end
    return nil
end

local function probeInput()
    if INPUT.probed then return end
    INPUT.probed = true
    local arrived = nil
    local conn = UserInputService.InputBegan:Connect(function(i)
        if i.KeyCode == Enum.KeyCode.F13 then arrived = true end
    end)

    local function tryPath(name, send)
        arrived = false
        pcall(send)
        local t = os.clock()
        while os.clock() - t < 0.25 and not arrived do task.wait() end
        if arrived and INPUT.key == "none" then INPUT.key = name end
        return arrived
    end

    if keypress and keyrelease then
        tryPath("keypress", function()
            keypress(Enum.KeyCode.F13.Value)
            task.wait(0.03)
            keyrelease(Enum.KeyCode.F13.Value)
        end)
    end
    local vim = vimService()
    if INPUT.key == "none" and vim then
        tryPath("VirtualInputManager", function()
            vim:SendKeyEvent(true, Enum.KeyCode.F13, false, game)
            task.wait(0.03)
            vim:SendKeyEvent(false, Enum.KeyCode.F13, false, game)
        end)
    end
    pcall(function() conn:Disconnect() end)

    if INPUT.key == "VirtualInputManager" then
        INPUT.mouse = "VirtualInputManager"
    elseif INPUT.key == "keypress" and mouse1click then
        INPUT.mouse = "mouse1click"
    elseif vim then
        INPUT.mouse = "VirtualInputManager"
    elseif mouse1click then
        INPUT.mouse = "mouse1click"
    end
    note("input: key " .. INPUT.key .. ", mouse " .. INPUT.mouse)
end

local function pullTrigger()
    if INPUT.mouse == "mouse1click" and mouse1click then
        mouse1click()
        return true
    end
    local vim = vimService()
    if not vim then
        if mouse1press and mouse1release then
            mouse1press() task.wait(0.02) mouse1release()
            return true
        end
        return false
    end
    local c = centreOf()
    local ok = pcall(function()
        vim:SendMouseButtonEvent(c.X, c.Y, 0, true, game, 0)
        task.wait(0.02)
        vim:SendMouseButtonEvent(c.X, c.Y, 0, false, game, 0)
    end)
    return ok
end

local function clickMethod()
    return INPUT.mouse == "none" and "NONE" or INPUT.mouse
end

local function tapKey(name)
    local k = resolveKey(name)
    if not k or k.kind ~= "key" then return false end
    if INPUT.key == "keypress" and keypress and keyrelease then
        local ok = pcall(function()
            keypress(k.value.Value)
            task.wait(0.02)
            keyrelease(k.value.Value)
        end)
        if ok then return true end
    end
    local vim = vimService()
    if not vim then return false end
    return (pcall(function()
        vim:SendKeyEvent(true, k.value, false, game)
        task.wait(0.02)
        vim:SendKeyEvent(false, k.value, false, game)
    end))
end

local function holdKey(name, down)
    local k = resolveKey(name)
    if not k or k.kind ~= "key" then return false end
    local vim = vimService()
    if not vim then return false end
    return (pcall(function() vim:SendKeyEvent(down, k.value, false, game) end))
end

local function keyMethod()
    return INPUT.key == "none" and "NONE" or INPUT.key
end

--------------------------------------------------------------------------------
-- PARRY
--------------------------------------------------------------------------------

local ATTACK_MELEE = {
    ["rbxassetid://105441036119013"] = "LAttack",
    ["rbxassetid://87457990259233"]  = "RAttack",
    ["rbxassetid://71188211641772"]  = "CAttack",
}

local ATTACK_GUN = {
    ["rbxassetid://110389010823335"] = "Castigate/Revolt",
    ["rbxassetid://96091952971711"]  = "Monarch",
    ["rbxassetid://82893125154254"]  = "Siege",
    ["rbxassetid://115498395958050"] = "Phoenix",
}

local PARRY_SUCCESS = "rbxassetid://88427023415444"
local PARRY_OWN     = "rbxassetid://74124883232856"

local lastParryAt = 0
local watchedHum = {}

local function facingTarget(model)
    local body = bodyPart(model)
    if not body then return false end
    local to = body.Position - cam.CFrame.Position
    if to.Magnitude < 0.1 then return true end
    return cam.CFrame.LookVector:Dot(to.Unit) > 0.5
end

local function facingUs(model)
    local root = model:FindFirstChild("HumanoidRootPart")
    local mine = myRoot()
    if not root or not mine then return false end
    local toUs = (mine.Position - root.Position)
    if toUs.Magnitude < 0.1 then return true end
    return root.CFrame.LookVector:Dot(toUs.Unit) > 0.45
end

local function onAttackSeen(model, kind, label)
    if not live() or not CONFIG.parry then return end
    local mine = myRoot()
    local root = model:FindFirstChild("HumanoidRootPart")
    if not mine or not root then return end
    local dist = (mine.Position - root.Position).Magnitude
    local range = (kind == "gun") and CONFIG.parryGunRange or CONFIG.parryRange
    if dist > range then return end
    if kind == "gun" and not CONFIG.parryGun then return end
    if CONFIG.parryFacing and not facingUs(model) then return end
    local now = os.clock() * 1000
    if now - lastParryAt < CONFIG.parryCooldown then return end
    lastParryAt = now
    STATE.parryAttacks = STATE.parryAttacks + 1
    STATE.parryLast = label .. "  " .. math.floor(dist) .. "m"
    task.spawn(function()
        task.wait(CONFIG.parryDelay / 1000)
        if not live() or not CONFIG.parry then return end
        if tapKey(CONFIG.parryKey) then STATE.parryFired = STATE.parryFired + 1 end
    end)
end

local MY_SWING = {
    ["rbxassetid://105441036119013"] = true,
    ["rbxassetid://87457990259233"]  = true,
    ["rbxassetid://71188211641772"]  = true,
}

local lastAnim = {}

local function onAnimation(model, id)
    if not live() or not id then return end
    local key = tostring(model) .. id
    local now = os.clock()
    if lastAnim[key] and now - lastAnim[key] < 0.08 then return end
    lastAnim[key] = now
    if model == myChar() then
        if id == PARRY_SUCCESS then STATE.parrySuccess = STATE.parrySuccess + 1 end
        if MY_SWING[id] then
            if now - (STATE.lastSwingSeen or 0) > 0.3 then
                STATE.lastSwingSeen = now
                STATE.auraSwings = STATE.auraSwings + 1
            end
        end
        return
    end
    local melee = ATTACK_MELEE[id]
    if melee then return onAttackSeen(model, "melee", melee) end
    local gun = ATTACK_GUN[id]
    if gun then return onAttackSeen(model, "gun", gun) end
end

local function watchHumanoid(model)
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or watchedHum[hum] then return end
    watchedHum[hum] = true
    hum.AnimationPlayed:Connect(function(track)
        onAnimation(model, track.Animation and track.Animation.AnimationId)
    end)
    local animator = hum:FindFirstChildOfClass("Animator")
    if animator then
        animator.AnimationPlayed:Connect(function(track)
            onAnimation(model, track.Animation and track.Animation.AnimationId)
        end)
    end
end

local function startParryWatch()
    local folder = entitiesFolder()
    if not folder then return end
    for _, m in ipairs(folder:GetChildren()) do
        if m:IsA("Model") then task.defer(watchHumanoid, m) end
    end
    folder.ChildAdded:Connect(function(m)
        if not live() then return end
        task.defer(function()
            task.wait(0.2)
            if m:IsA("Model") then watchHumanoid(m) end
        end)
    end)
    plr.CharacterAdded:Connect(function(c)
        if not live() then return end
        task.wait(0.3)
        watchHumanoid(c)
    end)
    local c = myChar()
    if c then watchHumanoid(c) end
end

--------------------------------------------------------------------------------
-- KILL AURA
--------------------------------------------------------------------------------

local function swordOut()
    local c = myChar()
    return c ~= nil and equippedWeapon(c) == "Redliner"
end

local function auraActive()
    if not CONFIG.aura then return false end
    local mode = CONFIG.auraActivation
    if mode == "Always" then return true end
    if mode == "Screen held" then return screenHeld() end
    return hotkeyHeld(CONFIG.auraKey)
end

local function hittable(model)
    local root = myRoot()
    local body = bodyPart(model)
    if not root or not body then return false, nil end
    local d = (root.Position - body.Position).Magnitude
    if d > CONFIG.auraRange then return false, d end
    local to = body.Position - cam.CFrame.Position
    if to.Magnitude > 0.1 then
        local dot = math.clamp(cam.CFrame.LookVector:Dot(to.Unit), -1, 1)
        if math.deg(math.acos(dot)) > CONFIG.auraAngle then return false, d end
    end
    if CONFIG.auraVisibleOnly and not visibleTo(body) then return false, d end
    return true, d
end

local function auraPick()
    local best, bestD
    for _, model in ipairs(combatants()) do
        local ok, d = hittable(model)
        if ok and (not bestD or d < bestD) then best, bestD = model, d end
    end
    return best, bestD
end

local function watchHits()
    local fx = Workspace:FindFirstChild("Effects")
    if not fx then return end
    fx.DescendantAdded:Connect(function(o)
        if not live() or not o:IsA("BasePart") then return end
        if o.Name ~= "DamageNumber" then return end
        if os.clock() * 1000 - STATE.lastSwingAt > 1200 then return end
        local mine = myRoot()
        if mine and (o.Position - mine.Position).Magnitude < 12 then return end
        for _, m in ipairs(combatants()) do
            local b = bodyPart(m)
            if b and (o.Position - b.Position).Magnitude < 14 then
                STATE.auraHits = STATE.auraHits + 1
                return
            end
        end
    end)
end

local function auraLoop()
    task.wait()
    while live() do
        local ok = pcall(function()
            if not auraActive() then STATE.auraTarget = nil return end
            if CONFIG.auraNeedSword and not swordOut() then
                STATE.auraTarget = "no sword equipped"
                return
            end
            local near, nd
            for _, m in ipairs(combatants()) do
                local b = bodyPart(m)
                local r = myRoot()
                if b and r then
                    local d = (r.Position - b.Position).Magnitude
                    if d <= CONFIG.auraRange and (not nd or d < nd) then near, nd = m, d end
                end
            end
            STATE.auraModel = near

            local target, dist = auraPick()
            if not target then
                if not near then
                    for _, m in ipairs(combatants()) do
                        local b = bodyPart(m)
                        local r = myRoot()
                        if b and r then
                            local d = (r.Position - b.Position).Magnitude
                            if not nd or d < nd then near, nd = m, d end
                        end
                    end
                end
                STATE.auraTarget = near
                    and string.format("nearest %s at %sm - out of reach or arc", near.Name, math.floor(nd))
                    or nil
                return
            end
            STATE.auraTarget = target.Name .. "  " .. math.floor(dist) .. "m"
            local now = os.clock() * 1000
            if now - STATE.lastSwingAt < CONFIG.auraInterval then return end
            STATE.lastSwingAt = now
            if pullTrigger() then STATE.auraClicks = STATE.auraClicks + 1 end
        end)
        if not ok then task.wait(0.2) end
        task.wait(0.03)
    end
end

--------------------------------------------------------------------------------
-- MOVEMENT
--------------------------------------------------------------------------------

local function bhopLoop()
    task.wait()
    while live() do
        local ok = pcall(function()
            if not CONFIG.moveBhop then return end
            if tapKey(CONFIG.moveBhopKey) then STATE.bhops = STATE.bhops + 1 end
        end)
        if not ok then task.wait(0.3) end
        task.wait(math.max(CONFIG.moveBhopRate, 30) / 1000)
    end
end

local function slideLoop()
    task.wait()
    while live() do
        local ok = pcall(function()
            if not CONFIG.moveSlide then return end
            if tapKey(CONFIG.moveSlideKey) then STATE.slides = STATE.slides + 1 end
        end)
        if not ok then task.wait(0.3) end
        task.wait(math.max(CONFIG.moveSlideEvery, 200) / 1000)
    end
end

--------------------------------------------------------------------------------
-- aim assist
--------------------------------------------------------------------------------

local sticky = nil

local function aimActive()
    if not CONFIG.aim then return false end
    local mode = CONFIG.aimActivation
    if mode == "Always" then return true end
    if mode == "Screen held" then return screenHeld() end
    if mode == "While firing" then
        if TOUCH then return false end
        return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    end
    return hotkeyHeld(CONFIG.aimKey)
end

local function aimTargetPart(model)
    if CONFIG.aimPart == "Head" then return headHurtbox(model) end
    if CONFIG.aimPart == "Torso" then return bodyPart(model) end
    local head, body = headHurtbox(model), bodyPart(model)
    if not head then return body end
    if not body then return head end
    local c = centreOf()
    local ph = cam:WorldToViewportPoint(head.Position)
    local pb = cam:WorldToViewportPoint(body.Position)
    local dh = (Vector2.new(ph.X, ph.Y) - c).Magnitude
    local db = (Vector2.new(pb.X, pb.Y) - c).Magnitude
    return dh <= db and head or body
end

local function pickTarget()
    local root = myRoot()
    if not root then return nil end
    local c = centreOf()
    local best, bestScore
    for _, model in ipairs(combatants()) do
        local part = aimTargetPart(model)
        if part then
            local dist = (root.Position - part.Position).Magnitude
            if dist <= CONFIG.aimMaxDist then
                local sp = cam:WorldToViewportPoint(part.Position)
                if sp.Z > 0 then
                    local px = (Vector2.new(sp.X, sp.Y) - c).Magnitude
                    if px <= CONFIG.aimFov then
                        if (not CONFIG.aimVisibleOnly) or visibleTo(part) then
                            local score
                            if CONFIG.aimPick == "World" then
                                score = dist
                            elseif CONFIG.aimPick == "Lowest HP" then
                                score = select(1, healthOf(model))
                            else
                                score = px
                            end
                            if not bestScore or score < bestScore then
                                best, bestScore = model, score
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function approach(smooth, dt)
    local base = 1 / math.max(1, smooth)
    return 1 - (1 - base) ^ math.max(dt * 60, 0.0001)
end

local function angleDelta(a, b)
    local d = (b - a) % (math.pi * 2)
    if d > math.pi then d = d - math.pi * 2 end
    return d
end

local function aimPass(dt)
    if not live() then return end
    if not aimActive() then
        sticky = nil
        STATE.target = nil
        STATE.aimStep = 0
        return
    end

    local target = sticky
    if CONFIG.aimSticky and target then
        local ok = target.Parent and aliveOf(target)
        if ok then
            local part = aimTargetPart(target)
            local sp = part and cam:WorldToViewportPoint(part.Position)
            if not sp or sp.Z <= 0 or (Vector2.new(sp.X, sp.Y) - centreOf()).Magnitude > CONFIG.aimFov * 1.6 then
                ok = false
            end
        end
        if not ok then target = nil end
    else
        target = nil
    end
    if not target then target = pickTarget() end
    sticky = target
    STATE.target = target and target.Name or nil
    if not target then STATE.aimStep = 0 return end

    local part = aimTargetPart(target)
    if not part then return end

    local pos = cam.CFrame.Position
    local curPitch, curYaw = cam.CFrame:ToOrientation()
    local wantPitch, wantYaw = CFrame.lookAt(pos, part.Position):ToOrientation()

    local dYaw = angleDelta(curYaw, wantYaw) * approach(CONFIG.aimSmoothH, dt)
    local dPitch = angleDelta(curPitch, wantPitch) * approach(CONFIG.aimSmoothV, dt)

    local step = math.sqrt(dYaw * dYaw + dPitch * dPitch)
    local cap = math.rad(CONFIG.humanTurnCap) * dt
    if cap > 0 and step > cap then
        local scale = cap / step
        dYaw, dPitch = dYaw * scale, dPitch * scale
        step = cap
    end

    local sp = cam:WorldToViewportPoint(part.Position)
    if sp.Z > 0 and (Vector2.new(sp.X, sp.Y) - centreOf()).Magnitude < CONFIG.humanDeadzone then
        STATE.aimStep = 0
        return
    end

    cam.CFrame = CFrame.new(pos) * CFrame.fromOrientation(curPitch + dPitch, curYaw + dYaw, 0)

    local degS = math.deg(step) / math.max(dt, 1e-4)
    STATE.aimStep = degS
    if degS > STATE.aimPeak then STATE.aimPeak = degS end
end

--------------------------------------------------------------------------------
-- trigger
--------------------------------------------------------------------------------

local function trigActive()
    if not CONFIG.trigger then return false end
    local mode = CONFIG.triggerActivation
    if mode == "Always" then return true end
    if mode == "Screen held" then return screenHeld() end
    return hotkeyHeld(CONFIG.triggerKey)
end

local function underCrosshair()
    local root = myRoot()
    if not root then return nil end
    local origin = cam.CFrame.Position
    local c = centreOf()
    local ray = cam:ViewportPointToRay(c.X, c.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local list = {}
    local mine = myChar()
    if mine then list[#list + 1] = mine end
    local map = Workspace:FindFirstChild("Map")
    if map then
        for _, d in ipairs(map:GetDescendants()) do
            if d:IsA("BasePart") and d.Transparency >= 1 and not d.CanCollide then
                list[#list + 1] = d
            end
        end
    end
    local fx = Workspace:FindFirstChild("Effects")
    if fx then list[#list + 1] = fx end
    params.FilterDescendantsInstances = list
    local hit = Workspace:Raycast(ray.Origin, ray.Direction * CONFIG.triggerMaxDist, params)
    if not hit or not hit.Instance then return nil end
    local inst = hit.Instance
    local folder = entitiesFolder()
    while inst and inst.Parent do
        if folder and inst.Parent == folder then
            if inst:IsA("Model") and inst ~= mine and aliveOf(inst) then
                if CONFIG.triggerHeadOnly then
                    local hb = headHurtbox(inst)
                    if hit.Instance ~= hb and hit.Instance.Name ~= "Head" then return nil end
                end
                local dist = (origin - hit.Position).Magnitude
                if dist <= CONFIG.triggerMaxDist then return inst end
            end
            return nil
        end
        inst = inst.Parent
    end
    return nil
end

local function triggerLoop()
    task.wait()
    local lastShot = 0
    while live() do
        local ok = pcall(function()
            if not trigActive() then return end
            local now = os.clock() * 1000
            if now - lastShot < CONFIG.triggerLockout then return end
            if not underCrosshair() then return end
            local lo = math.min(CONFIG.triggerDelayMin, CONFIG.triggerDelayMax)
            local hi = math.max(CONFIG.triggerDelayMin, CONFIG.triggerDelayMax)
            task.wait(math.random(lo, hi) / 1000)
            if not trigActive() or not underCrosshair() then return end
            if pullTrigger() then
                STATE.shots = STATE.shots + 1
                lastShot = os.clock() * 1000
            end
        end)
        if not ok then task.wait(0.2) end
        task.wait(0.01)
    end
end

--------------------------------------------------------------------------------
-- loops
--------------------------------------------------------------------------------

RunService:BindToRenderStep("__REDLINER_ESP", Enum.RenderPriority.Camera.Value + 2, function()
    if not live() then
        pcall(function() RunService:UnbindFromRenderStep("__REDLINER_ESP") end)
        return
    end
    pcall(renderPass)
end)

RunService:BindToRenderStep("__REDLINER_AIM", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not live() then
        pcall(function() RunService:UnbindFromRenderStep("__REDLINER_AIM") end)
        return
    end
    STATE.fps = math.floor(1 / math.max(dt, 1e-4))
    pcall(aimPass, dt)
    if CONFIG.aura and CONFIG.auraFaceTarget and STATE.auraModel then
        pcall(function()
            local model = STATE.auraModel
            if not model.Parent then STATE.auraModel = nil return end
            local body = bodyPart(model)
            if not body then return end
            local pos = cam.CFrame.Position
            local curPitch, curYaw = cam.CFrame:ToOrientation()
            local wantPitch, wantYaw = CFrame.lookAt(pos, body.Position):ToOrientation()
            local dYaw = angleDelta(curYaw, wantYaw) * approach(CONFIG.aimSmoothH, dt)
            local dPitch = angleDelta(curPitch, wantPitch) * approach(CONFIG.aimSmoothV, dt)
            local step = math.sqrt(dYaw * dYaw + dPitch * dPitch)
            local cap = math.rad(CONFIG.humanTurnCap) * dt
            if cap > 0 and step > cap then
                local scale = cap / step
                dYaw, dPitch = dYaw * scale, dPitch * scale
            end
            cam.CFrame = CFrame.new(pos) * CFrame.fromOrientation(curPitch + dPitch, curYaw + dYaw, 0)
        end)
    end
end)

task.spawn(triggerLoop)
task.spawn(auraLoop)
task.spawn(function() task.wait() pcall(watchHits) end)
task.spawn(bhopLoop)
task.spawn(slideLoop)
task.spawn(function()
    task.wait()
    pcall(probeInput)
end)
task.spawn(function()
    task.wait()
    startParryWatch()
    while live() do
        pcall(reapPool)
        task.wait(2)
    end
end)

--------------------------------------------------------------------------------
-- auto-arm
--------------------------------------------------------------------------------

local ARMED_BY = { "espBox", "espName", "espDist", "espHealth", "espHeadDot",
    "espSkeleton", "espTracer", "espChams" }

task.spawn(function()
    task.wait()
    local prev = {}
    for _, key in ipairs(ARMED_BY) do prev[key] = CONFIG[key] end
    while live() do
        for _, key in ipairs(ARMED_BY) do
            local now = CONFIG[key]
            if now and not prev[key] and not CONFIG.esp then
                CONFIG.esp = true
                note("ESP master armed by " .. key)
            end
            prev[key] = now
        end
        task.wait(0.2)
    end
end)

--------------------------------------------------------------------------------
-- UI
--------------------------------------------------------------------------------

local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 720,
    Height = 600,
})

--------------------------------------------------------------------------------
-- footer
--------------------------------------------------------------------------------

task.spawn(function()
    task.wait(2)
    while live() do
        pcall(function()
            local kind = placeKind()
            Window:SetFooter("v1.4 | " .. kind .. " | " .. plr.UserId)
        end)
        task.wait(1)
    end
end)

--------------------------------------------------------------------------------
-- helper
--------------------------------------------------------------------------------

local function makeReadout(section, count)
    local labels = {}
    for i = 1, count do
        labels[i] = section:CreateLabel("")
    end
    return {
        set = function(self, lines)
            for i = 1, math.min(count, #lines) do
                if labels[i] then
                    pcall(function() labels[i]:Set(lines[i]) end)
                end
            end
        end
    }
end

local function featureKeybind(section, caption, field)
    return section:CreateKeybind({
        Name = caption,
        CurrentKeybind = CONFIG[field],
        Callback = function() end,
        ChangedCallback = function(newKey)
            CONFIG[field] = newKey
            keyCache = {}
        end
    })
end

--------------------------------------------------------------------------------
-- TAB: COMBAT
--------------------------------------------------------------------------------

local Tabs = {
    Combat = Window:CreateTab({ Name = "Combat" }),
    Visuals = Window:CreateTab({ Name = "Visuals" }),
    World = Window:CreateTab({ Name = "World" }),
    Misc = Window:CreateTab({ Name = "Misc" }),
    ["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

local CTL = {}
local function reg(key, handle)
    CTL[key] = handle
    return handle
end

local function syncCTL()
    for key, handle in pairs(CTL) do
        if CONFIG[key] ~= nil then
            pcall(function() handle:Set(CONFIG[key]) end)
        end
    end
end

local DiscordLabel, CreditsLabel

do
local dcSection = Tabs.Combat:CreateSection("")
dcSection:CreateLabel("DISCORD")
DiscordLabel = dcSection:CreateLabel({ Text = "Join Discord For Free Keys!" })
dcSection:CreateButton({ Name = "Copy Discord Link", Callback = function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/syZX9Zte7t")
        end
    end)
    Library.Notify({ Title = "Ivory", Content = "Discord link copied to clipboard!", Type = "Success", Duration = 3 })
end })
local aimSection = Tabs.Combat:CreateSection("aimbot")
    reg("aim", aimSection:CreateToggle({ Name = "Aim assist", CurrentValue = CONFIG.aim, Callback = function(v) CONFIG.aim = v end }))
    reg("aimActivation", aimSection:CreateDropdown({ Name = "Activation", Values = { "Hotkey", "Always", "While firing", "Screen held" }, CurrentOption = CONFIG.aimActivation, Callback = function(v) CONFIG.aimActivation = v end }))
    reg("aimKey", aimSection:CreateDropdown({ Name = "Aim key", Values = { "MouseButton2", "MouseButton3", "LeftShift", "LeftAlt", "LeftControl", "E", "Q", "C", "V", "X", "Z" }, CurrentOption = CONFIG.aimKey, Callback = function(v) CONFIG.aimKey = v end }))
    reg("aimPart", aimSection:CreateDropdown({ Name = "Aim at", Values = { "Head", "Torso", "Nearest" }, CurrentOption = CONFIG.aimPart, Callback = function(v) CONFIG.aimPart = v end }))
    reg("aimPick", aimSection:CreateDropdown({ Name = "Choose target by", Values = { "Crosshair", "World", "Lowest HP" }, CurrentOption = CONFIG.aimPick, Callback = function(v) CONFIG.aimPick = v end }))
    reg("aimSticky", aimSection:CreateToggle({ Name = "Sticky target", CurrentValue = CONFIG.aimSticky, Callback = function(v) CONFIG.aimSticky = v end }))
    reg("aimFov", aimSection:CreateSlider({ Name = "FOV (px)", Min = 20, Max = 600, CurrentValue = CONFIG.aimFov, Callback = function(v) CONFIG.aimFov = v end }))
    reg("aimSmoothH", aimSection:CreateSlider({ Name = "Smoothing horizontal", Min = 1, Max = 50, CurrentValue = CONFIG.aimSmoothH, Callback = function(v) CONFIG.aimSmoothH = v end }))
    reg("aimSmoothV", aimSection:CreateSlider({ Name = "Smoothing vertical", Min = 1, Max = 50, CurrentValue = CONFIG.aimSmoothV, Callback = function(v) CONFIG.aimSmoothV = v end }))
    reg("aimMaxDist", aimSection:CreateSlider({ Name = "Max distance", Min = 50, Max = 1000, CurrentValue = CONFIG.aimMaxDist, Callback = function(v) CONFIG.aimMaxDist = v end }))
    reg("aimVisibleOnly", aimSection:CreateToggle({ Name = "Visible only", CurrentValue = CONFIG.aimVisibleOnly, Callback = function(v) CONFIG.aimVisibleOnly = v end }))
    reg("aimShowFov", aimSection:CreateToggle({ Name = "Draw FOV ring", CurrentValue = CONFIG.aimShowFov, Callback = function(v) CONFIG.aimShowFov = v end }))
    local aimLive = makeReadout(aimSection, 3)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                aimLive:set({
                    string.format("Target: %s", STATE.target or "-"),
                    string.format("Turn: %s deg/s | Peak: %s | Cap: %s", math.floor(STATE.aimStep), math.floor(STATE.aimPeak), CONFIG.humanTurnCap),
                    string.format("FPS: %s", STATE.fps),
                })
            end)
            task.wait(0.2)
        end
    end)

    local trigSection = Tabs.Combat:CreateSection("trigger")
    reg("trigger", trigSection:CreateToggle({ Name = "Triggerbot", CurrentValue = CONFIG.trigger, Callback = function(v) CONFIG.trigger = v end }))
    reg("triggerActivation", trigSection:CreateDropdown({ Name = "Activation", Values = { "Hotkey", "Always", "Screen held" }, CurrentOption = CONFIG.triggerActivation, Callback = function(v) CONFIG.triggerActivation = v end }))
    featureKeybind(trigSection, "Key", "triggerKey")
    reg("triggerHeadOnly", trigSection:CreateToggle({ Name = "Head only", CurrentValue = CONFIG.triggerHeadOnly, Callback = function(v) CONFIG.triggerHeadOnly = v end }))
    reg("triggerDelayMin", trigSection:CreateSlider({ Name = "Reaction min (ms)", Min = 0, Max = 400, CurrentValue = CONFIG.triggerDelayMin, Callback = function(v) CONFIG.triggerDelayMin = v end }))
    reg("triggerDelayMax", trigSection:CreateSlider({ Name = "Reaction max (ms)", Min = 0, Max = 600, CurrentValue = CONFIG.triggerDelayMax, Callback = function(v) CONFIG.triggerDelayMax = v end }))
    reg("triggerLockout", trigSection:CreateSlider({ Name = "Refire lockout (ms)", Min = 0, Max = 2000, CurrentValue = CONFIG.triggerLockout, Callback = function(v) CONFIG.triggerLockout = v end }))
    reg("triggerMaxDist", trigSection:CreateSlider({ Name = "Max distance", Min = 50, Max = 1000, CurrentValue = CONFIG.triggerMaxDist, Callback = function(v) CONFIG.triggerMaxDist = v end }))
    local trigLive = makeReadout(trigSection, 2)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                trigLive:set({
                    string.format("Shots: %s", STATE.shots),
                    string.format("Input: %s", clickMethod()),
                })
            end)
            task.wait(0.4)
        end
    end)

    local auraSection = Tabs.Combat:CreateSection("kill aura")
    auraSection:CreateLabel("Not an aimbot. Swings only when the target is ALREADY hittable - inside your reach and inside the arc you are looking at.")
    reg("aura", auraSection:CreateToggle({ Name = "Kill aura", CurrentValue = CONFIG.aura, Callback = function(v) CONFIG.aura = v end }))
    reg("auraActivation", auraSection:CreateDropdown({ Name = "Activation", Values = { "Hotkey", "Always", "Screen held" }, CurrentOption = CONFIG.auraActivation, Callback = function(v) CONFIG.auraActivation = v end }))
    featureKeybind(auraSection, "Key", "auraKey")
    reg("auraRange", auraSection:CreateSlider({ Name = "Reach (studs)", Min = 5, Max = 60, CurrentValue = CONFIG.auraRange, Callback = function(v) CONFIG.auraRange = v end }))
    reg("auraAngle", auraSection:CreateSlider({ Name = "Arc (degrees)", Min = 5, Max = 120, CurrentValue = CONFIG.auraAngle, Callback = function(v) CONFIG.auraAngle = v end }))
    reg("auraInterval", auraSection:CreateSlider({ Name = "Interval (ms)", Min = 200, Max = 1500, CurrentValue = CONFIG.auraInterval, Callback = function(v) CONFIG.auraInterval = v end }))
    reg("auraNeedSword", auraSection:CreateToggle({ Name = "Only with sword out", CurrentValue = CONFIG.auraNeedSword, Callback = function(v) CONFIG.auraNeedSword = v end }))
    reg("auraVisibleOnly", auraSection:CreateToggle({ Name = "Only when in sight", CurrentValue = CONFIG.auraVisibleOnly, Callback = function(v) CONFIG.auraVisibleOnly = v end }))
    reg("auraFaceTarget", auraSection:CreateToggle({ Name = "Turn towards them", CurrentValue = CONFIG.auraFaceTarget, Callback = function(v) CONFIG.auraFaceTarget = v end }))
    local auraLive = makeReadout(auraSection, 4)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                auraLive:set({
                    string.format("%s", STATE.auraTarget or "nobody in reach"),
                    string.format("Swings sent: %s (%s)", STATE.auraClicks, clickMethod()),
                    string.format("Confirmed: %s", STATE.auraSwings),
                    string.format("HITS: %s", STATE.auraHits),
                })
            end)
            task.wait(0.3)
        end
    end)

    local parrySection = Tabs.Combat:CreateSection("auto parry")
    parrySection:CreateLabel("Timing is NOT measured. The account never got out of the deploy menu. Turn it on, watch the counters, and tune the delay until PARRY SUCCESS climbs.")
    reg("parry", parrySection:CreateToggle({ Name = "Auto parry", CurrentValue = CONFIG.parry, Callback = function(v) CONFIG.parry = v end }))
    featureKeybind(parrySection, "Parry key", "parryKey")
    reg("parryDelay", parrySection:CreateSlider({ Name = "Delay (ms)", Min = 0, Max = 500, CurrentValue = CONFIG.parryDelay, Callback = function(v) CONFIG.parryDelay = v end }))
    reg("parryCooldown", parrySection:CreateSlider({ Name = "Cooldown (ms)", Min = 0, Max = 1500, CurrentValue = CONFIG.parryCooldown, Callback = function(v) CONFIG.parryCooldown = v end }))
    reg("parryRange", parrySection:CreateSlider({ Name = "Melee range", Min = 5, Max = 80, CurrentValue = CONFIG.parryRange, Callback = function(v) CONFIG.parryRange = v end }))
    reg("parryGun", parrySection:CreateToggle({ Name = "Also parry gunshots", CurrentValue = CONFIG.parryGun, Callback = function(v) CONFIG.parryGun = v end }))
    reg("parryGunRange", parrySection:CreateSlider({ Name = "Gun range", Min = 20, Max = 600, CurrentValue = CONFIG.parryGunRange, Callback = function(v) CONFIG.parryGunRange = v end }))
    reg("parryFacing", parrySection:CreateToggle({ Name = "Only when facing you", CurrentValue = CONFIG.parryFacing, Callback = function(v) CONFIG.parryFacing = v end }))
    local parryLive = makeReadout(parrySection, 4)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                parryLive:set({
                    string.format("Attacks seen: %s", STATE.parryAttacks),
                    string.format("Parries fired: %s (%s)", STATE.parryFired, keyMethod()),
                    string.format("PARRY SUCCESS: %s", STATE.parrySuccess),
                    string.format("Last: %s", STATE.parryLast),
                })
            end)
            task.wait(0.3)
        end
    end)

end

--------------------------------------------------------------------------------
-- TAB: VISUALS
--------------------------------------------------------------------------------

do
    local espSection = Tabs.Visuals:CreateSection("esp")
    reg("esp", espSection:CreateToggle({ Name = "ESP", CurrentValue = CONFIG.esp, Callback = function(v) CONFIG.esp = v end }))
    reg("espBox", espSection:CreateToggle({ Name = "Box", CurrentValue = CONFIG.espBox, Callback = function(v) CONFIG.espBox = v end }))
    reg("espName", espSection:CreateToggle({ Name = "Name", CurrentValue = CONFIG.espName, Callback = function(v) CONFIG.espName = v end }))
    reg("espDist", espSection:CreateToggle({ Name = "Distance and level", CurrentValue = CONFIG.espDist, Callback = function(v) CONFIG.espDist = v end }))
    reg("espHealth", espSection:CreateToggle({ Name = "Health bar", CurrentValue = CONFIG.espHealth, Callback = function(v) CONFIG.espHealth = v end }))
    reg("espHeadDot", espSection:CreateToggle({ Name = "Head dot", CurrentValue = CONFIG.espHeadDot, Callback = function(v) CONFIG.espHeadDot = v end }))
    reg("espSkeleton", espSection:CreateToggle({ Name = "Skeleton", CurrentValue = CONFIG.espSkeleton, Callback = function(v) CONFIG.espSkeleton = v end }))
    reg("espTracer", espSection:CreateToggle({ Name = "Tracer", CurrentValue = CONFIG.espTracer, Callback = function(v) CONFIG.espTracer = v end }))
    reg("espChams", espSection:CreateToggle({ Name = "Chams", CurrentValue = CONFIG.espChams, Callback = function(v)
        CONFIG.espChams = v
        if not v then clearChams() end
    end }))

    local utilSection = Tabs.Visuals:CreateSection("utility")
    reg("espMaxDist", utilSection:CreateSlider({ Name = "Max distance", Min = 100, Max = 2000, CurrentValue = CONFIG.espMaxDist, Callback = function(v) CONFIG.espMaxDist = v end }))
    reg("espVisibleOnly", utilSection:CreateToggle({ Name = "Visible only", CurrentValue = CONFIG.espVisibleOnly, Callback = function(v) CONFIG.espVisibleOnly = v end }))
    reg("espTextSize", utilSection:CreateSlider({ Name = "Text size", Min = 12, Max = 24, CurrentValue = CONFIG.espTextSize, Callback = function(v) CONFIG.espTextSize = v end }))
    reg("espFont", utilSection:CreateDropdown({ Name = "Font", Values = { "System", "UI", "Plex", "Monospace" }, CurrentOption = CONFIG.espFont, Callback = function(v) CONFIG.espFont = v end }))
    utilSection:CreateLabel({ Text = "ESP Colour" }):CreateColorPicker("EspColour", { Default = CONFIG.espColour, Callback = function(c) CONFIG.espColour = c end })

    local espLive = makeReadout(utilSection, 3)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                espLive:set({
                    string.format("Targets: %s | Drawn: %s | FPS: %s", STATE.targets, STATE.drawn, STATE.fps),
                    string.format("Place: %s", placeKind()),
                    STATE.note ~= "" and STATE.note or "-",
                })
            end)
            task.wait(0.3)
        end
    end)
end

--------------------------------------------------------------------------------
-- TAB: WORLD
--------------------------------------------------------------------------------

do
    local moveSection = Tabs.World:CreateSection("movement")
    moveSection:CreateLabel("No speed slider. WalkSpeed reads 16 while the character moves at 106+ studs/s. The game runs its own movement controller. What works is pressing the game's OWN movement keys.")
    reg("moveBhop", moveSection:CreateToggle({ Name = "Auto bhop", CurrentValue = CONFIG.moveBhop, Callback = function(v) CONFIG.moveBhop = v end }))
    featureKeybind(moveSection, "Jump key", "moveBhopKey")
    reg("moveBhopRate", moveSection:CreateSlider({ Name = "Every (ms)", Min = 30, Max = 400, CurrentValue = CONFIG.moveBhopRate, Callback = function(v) CONFIG.moveBhopRate = v end }))
    reg("moveSlide", moveSection:CreateToggle({ Name = "Auto slide", CurrentValue = CONFIG.moveSlide, Callback = function(v) CONFIG.moveSlide = v end }))
    featureKeybind(moveSection, "Slide key", "moveSlideKey")
    reg("moveSlideEvery", moveSection:CreateSlider({ Name = "Every (ms)", Min = 200, Max = 4000, CurrentValue = CONFIG.moveSlideEvery, Callback = function(v) CONFIG.moveSlideEvery = v end }))

    local moveLive = makeReadout(moveSection, 3)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                local ch = myChar()
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                local root = ch and ch:FindFirstChild("HumanoidRootPart")
                local v = root and root.AssemblyLinearVelocity
                local flat = v and math.floor(Vector3.new(v.X, 0, v.Z).Magnitude) or 0
                moveLive:set({
                    string.format("Speed: %s studs/s (WalkSpeed: %s)", flat, hum and math.floor(hum.WalkSpeed) or "-"),
                    string.format("Bhop taps: %s (%s)", STATE.bhops, keyMethod()),
                    string.format("Slide taps: %s", STATE.slides),
                })
            end)
            task.wait(0.3)
        end
    end)
end

--------------------------------------------------------------------------------
-- TAB: MISC
--------------------------------------------------------------------------------

do
    local humanSection = Tabs.Misc:CreateSection("miscellaneous")
    reg("humanTurnCap", humanSection:CreateSlider({ Name = "Turn speed cap (deg/s)", Min = 30, Max = 3000, CurrentValue = CONFIG.humanTurnCap, Callback = function(v) CONFIG.humanTurnCap = v end }))
    reg("humanDeadzone", humanSection:CreateSlider({ Name = "Deadzone (px)", Min = 0, Max = 20, CurrentValue = CONFIG.humanDeadzone, Callback = function(v) CONFIG.humanDeadzone = v end }))

    local panicSection = Tabs.Misc:CreateSection("panic")
    panicSection:CreateButton({ Name = "Everything off", Callback = function()
        CONFIG.aim = false
        CONFIG.trigger = false
        CONFIG.parry = false
        CONFIG.aura = false
        CONFIG.moveBhop = false
        CONFIG.moveSlide = false
        syncCTL()
        note("panic: all features off")
    end })

    local infoSection = Tabs.Misc:CreateSection("info")
    local infoOut = makeReadout(infoSection, 6)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                local n = plr.Name
                infoOut:set({
                    string.format("Level: %s", tostring(roValue(n, "level", "-"))),
                    string.format("Yen: %s", tostring(roValue(n, "yen", "-"))),
                    string.format("Crimson: %s", tostring(roValue(n, "crimson", "-"))),
                    string.format("Killstreak: %s", tostring(roValue(n, "killstreak", "-"))),
                    string.format("Winstreak: %s", tostring(roValue(n, "casual_duel_winstreak", "-"))),
                    string.format("Status: %s", tostring(roValue(n, "status", "-"))),
                })
            end)
            task.wait(0.5)
        end
    end)

    local serverSection = Tabs.Misc:CreateSection("server")
    local serverOut = makeReadout(serverSection, 4)
    task.spawn(function()
        task.wait()
        while live() do
            pcall(function()
                local n = plr.Name
                local moved = STATE.healthMoves
                serverOut:set({
                    string.format("Place: %s", placeKind()),
                    string.format("Enemies: %s", STATE.targets),
                    string.format("Ping: %s ms", math.floor((roValue(n, "rtt", 0) or 0) * 1000)),
                    moved == 0 and "Health: not observed changing" or string.format("Health: %s/%s samples moved", moved, STATE.healthSamples),
                })
            end)
            task.wait(0.5)
        end
    end)
end

--------------------------------------------------------------------------------
-- TAB: UI SETTINGS
--------------------------------------------------------------------------------

do
    local creditsSection = Tabs["UI Settings"]:CreateSection("")
    creditsSection:CreateLabel("CREDITS")
    CreditsLabel = creditsSection:CreateLabel({ Text = "Made By Mommy Veqxoo </3" })
    creditsSection:CreateLabel("Ivory Hub - Redliner Script")
    creditsSection:CreateLabel("v1.4")

    local menuSection = Tabs["UI Settings"]:CreateSection("menu settings")
    menuSection:CreateKeybind({ Name = "Menu Keybind", CurrentKeybind = "RightShift", Callback = function() end, ChangedCallback = function() end })
    menuSection:CreateSlider({ Name = "FPS Cap", Min = 30, Max = 240, CurrentValue = 240, Callback = function(v)
        pcall(function() setfpscap(v) end)
    end })
    menuSection:CreateDropdown({ Name = "Language", Values = { "English" }, CurrentOption = "English", Callback = function(v) end })
    menuSection:CreateToggle({ Name = "Anti AFK", CurrentValue = false, Callback = function(v)
        if v then
            plr.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end)
        end
    end })
    menuSection:CreateToggle({ Name = "Custom cursor", CurrentValue = true, Callback = function(v)
        pcall(function()
            UserInputService.MouseIconEnabled = v
        end)
    end })
    menuSection:CreateButton({ Name = "Test notification", Callback = function()
        Library.Notify({ Title = "Ivory", Content = "This is a test notification!", Type = "Info", Duration = 3 })
    end })
    menuSection:CreateDropdown({ Name = "Notification side", Values = { "Right", "Left" }, CurrentOption = "Right", Callback = function(v)
        pcall(function()
            Library.NotifySide = v
        end)
    end })
    menuSection:CreateDropdown({ Name = "DPI Scale", Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" }, CurrentOption = "100%", Callback = function(v)
        pcall(function()
            local scale = tonumber(v:gsub("%%", "")) / 100
            if Library.MainFrame then
                Library.MainFrame.Size = UDim2.fromOffset(720 * scale, 600 * scale)
            end
        end)
    end })
    menuSection:CreateSlider({ Name = "Corner radius", Min = 0, Max = 20, CurrentValue = 4, Callback = function(v)
        pcall(function()
            Library.Scheme.CornerRadius = v
            Library:UpdateColorsUsingRegistry()
        end)
    end })
    menuSection:CreateButton({ Name = "Unload", Callback = function()
        for _, set in pairs(POOL) do
            for _, obj in pairs(set) do pcall(function() obj:Remove() end) end
        end
        for _, hl in pairs(CHAMS) do pcall(function() hl:Destroy() end) end
        for _, name in ipairs({ "__REDLINER_AIM", "__REDLINER_ESP" }) do
            pcall(function() RunService:UnbindFromRenderStep(name) end)
        end
        _G.__REDLINER = (_G.__REDLINER or 0) + 1
        Library:Unload()
    end })

    local serverMenuSection = Tabs["UI Settings"]:CreateSection("server")
    serverMenuSection:CreateButton({ Name = "Rejoin", Callback = function()
        pcall(function()
            TeleportService:Teleport(game.PlaceId, plr)
        end)
    end })
    serverMenuSection:CreateButton({ Name = "Server hop", Callback = function()
        task.spawn(function()
            local ok, servers = pcall(function()
                return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            end)
            if ok and servers and servers.data then
                for _, server in ipairs(servers.data) do
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, plr)
                        break
                    end
                end
            else
                Library.Notify({ Title = "Ivory", Content = "No alternative servers found.", Type = "Error", Duration = 3 })
            end
        end)
    end })

    local themesSection = Tabs["UI Settings"]:CreateSection("themes")
    themesSection:CreateLabel({ Text = "Accent color" }):CreateColorPicker("AccentColor", { Default = Color3.fromRGB(255, 64, 64), Callback = function(c)
        pcall(function()
            Library.Scheme.Accent = c
            Library:UpdateColorsUsingRegistry()
        end)
    end })
    themesSection:CreateLabel({ Text = "Background color" }):CreateColorPicker("BgColor", { Default = Color3.fromRGB(20, 20, 20), Callback = function(c)
        pcall(function()
            Library.Scheme.Background = c
            Library:UpdateColorsUsingRegistry()
        end)
    end })

    local configSection = Tabs["UI Settings"]:CreateSection("configuration")

    local CONFIG_DIR = "Ivory/Redliner/configs"
    local CONFIG_META = CONFIG_DIR .. "/_meta.json"
    local configName = ""
    local configDropdown = nil

    local function getMeta()
        local ok, data = pcall(readfile, CONFIG_META)
        if ok and data then
            local decoded = HttpService:JSONDecode(data)
            return decoded
        end
        return { autoLoad = "" }
    end

    local function saveMeta(meta)
        pcall(function()
            writefile(CONFIG_META, HttpService:JSONEncode(meta))
        end)
    end

    local function listConfigs()
        local names = {}
        pcall(function()
            local files = listfiles(CONFIG_DIR)
            for _, f in ipairs(files) do
                local name = f:match("([^/\\]+)%.json$")
                if name and name ~= "_meta" then
                    names[#names + 1] = name
                end
            end
        end)
        return names
    end

    local function refreshDropdown()
        if not configDropdown then return end
        local names = listConfigs()
        local meta = getMeta()
        if #names == 0 then
            names = { "(none)" }
        end
        pcall(function() configDropdown:Refresh(names) end)
    end

    local function loadNamedConfig(name)
        pcall(function()
            local ok, data = pcall(readfile, CONFIG_DIR .. "/" .. name .. ".json")
            if ok and data then
                local decoded = HttpService:JSONDecode(data)
                for k, v in pairs(decoded) do
                    CONFIG[k] = v
                end
                syncCTL()
                Library.Notify({ Title = "Ivory", Content = "Loaded config: " .. name, Type = "Success", Duration = 3 })
                return true
            else
                Library.Notify({ Title = "Ivory", Content = "Config not found: " .. name, Type = "Error", Duration = 3 })
                return false
            end
        end)
        return false
    end

    local function saveNamedConfig(name)
        pcall(function()
            pcall(function() makefolder(CONFIG_DIR) end)
            local data = HttpService:JSONEncode(CONFIG)
            writefile(CONFIG_DIR .. "/" .. name .. ".json", data)
            Library.Notify({ Title = "Ivory", Content = "Saved config: " .. name, Type = "Success", Duration = 3 })
            refreshDropdown()
        end)
    end

    local function deleteNamedConfig(name)
        pcall(function()
            local path = CONFIG_DIR .. "/" .. name .. ".json"
            local ok = pcall(delfile, path)
            if ok then
                Library.Notify({ Title = "Ivory", Content = "Deleted config: " .. name, Type = "Success", Duration = 3 })
                local meta = getMeta()
                if meta.autoLoad == name then
                    meta.autoLoad = ""
                    saveMeta(meta)
                end
                refreshDropdown()
            else
                Library.Notify({ Title = "Ivory", Content = "Could not delete: " .. name, Type = "Error", Duration = 3 })
            end
        end)
    end

    local function setAutoLoad(name)
        pcall(function()
            local meta = getMeta()
            if meta.autoLoad == name then
                meta.autoLoad = ""
                Library.Notify({ Title = "Ivory", Content = "Auto-load cleared", Type = "Info", Duration = 3 })
            else
                meta.autoLoad = name
                Library.Notify({ Title = "Ivory", Content = "Auto-load set to: " .. name, Type = "Success", Duration = 3 })
            end
            saveMeta(meta)
        end)
    end

    local function getAutoLoad()
        local meta = getMeta()
        return meta.autoLoad or ""
    end

    configSection:CreateInput({ Name = "Config name", Default = "", Placeholder = "type config name here", Callback = function(v) configName = v end })

    local names = listConfigs()
    if #names == 0 then names = { "(none)" } end
    configDropdown = configSection:CreateDropdown({ Name = "Saved configs", Values = names, CurrentOption = names[1], Callback = function(v) configName = v end })

    configSection:CreateButton({ Name = "Save config", Callback = function()
        if configName == "" then
            Library.Notify({ Title = "Ivory", Content = "Enter a config name first", Type = "Error", Duration = 3 })
            return
        end
        saveNamedConfig(configName)
    end })

    configSection:CreateButton({ Name = "Load config", Callback = function()
        if configName == "" then
            Library.Notify({ Title = "Ivory", Content = "Select or type a config name first", Type = "Error", Duration = 3 })
            return
        end
        loadNamedConfig(configName)
    end })

    configSection:CreateButton({ Name = "Delete config", Callback = function()
        if configName == "" then
            Library.Notify({ Title = "Ivory", Content = "Select a config to delete", Type = "Error", Duration = 3 })
            return
        end
        deleteNamedConfig(configName)
    end })

    configSection:CreateButton({ Name = "Set as auto-load", Callback = function()
        if configName == "" then
            Library.Notify({ Title = "Ivory", Content = "Select a config first", Type = "Error", Duration = 3 })
            return
        end
        setAutoLoad(configName)
    end })

    local autoLoadName = getAutoLoad()
    if autoLoadName ~= "" then
        configSection:CreateLabel("Auto-load: " .. autoLoadName)
        loadNamedConfig(autoLoadName)
    else
        configSection:CreateLabel("Auto-load: none")
    end

    configSection:CreateButton({ Name = "Reset to defaults", Callback = function()
        for k, v in pairs(DEFAULTS) do CONFIG[k] = v end
        syncCTL()
        Library.Notify({ Title = "Ivory", Content = "Config reset to defaults", Type = "Success", Duration = 3 })
    end })
end

--------------------------------------------------------------------------------
-- DISCORD TYPEWRITER
--------------------------------------------------------------------------------
task.spawn(function()
    task.wait(2)
    local pinkColor = Color3.fromRGB(180, 105, 255)
    local fullText = "Join Discord For Free Keys!"
    local cursor = "_"
    local function styleDc()
        pcall(function()
            local inst = DiscordLabel.Instance
            local lbl = inst and inst:FindFirstChild("LabelText")
            if lbl then lbl.RichText = false; lbl.TextColor3 = pinkColor; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 26 end
        end)
    end
    while live() do
        for i = 1, #fullText do pcall(function() DiscordLabel:Set(string.sub(fullText, 1, i) .. cursor); styleDc() end); task.wait(0.06) end
        pcall(function() DiscordLabel:Set(fullText); styleDc() end); task.wait(1.5)
        for i = #fullText, 0, -1 do pcall(function() DiscordLabel:Set(string.sub(fullText, 1, i) .. cursor); styleDc() end); task.wait(0.04) end
        pcall(function() DiscordLabel:Set(""); styleDc() end); task.wait(0.5)
    end
end)

--------------------------------------------------------------------------------
-- CREDITS TYPEWRITER
--------------------------------------------------------------------------------
task.spawn(function()
    task.wait(2)
    local pinkColor = Color3.fromRGB(255, 105, 180)
    local fullText = "Made By Mommy Veqxoo </3"
    local cursor = "_"
    local function styleCr()
        pcall(function()
            local inst = CreditsLabel.Instance
            local lbl = inst and inst:FindFirstChild("LabelText")
            if lbl then lbl.RichText = false; lbl.TextColor3 = pinkColor; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 22 end
        end)
    end
    while live() do
        for i = 1, #fullText do pcall(function() CreditsLabel:Set(string.sub(fullText, 1, i) .. cursor); styleCr() end); task.wait(0.06) end
        pcall(function() CreditsLabel:Set(fullText); styleCr() end); task.wait(1.5)
        for i = #fullText, 0, -1 do pcall(function() CreditsLabel:Set(string.sub(fullText, 1, i) .. cursor); styleCr() end); task.wait(0.04) end
        pcall(function() CreditsLabel:Set(""); styleCr() end); task.wait(0.5)
    end
end)

--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

_G.__REDLINER_DBG = {
    CONFIG = CONFIG, STATE = STATE, DEFAULTS = DEFAULTS,
    combatants = combatants, aliveOf = aliveOf, headHurtbox = headHurtbox,
    visibleTo = visibleTo, screenRect = screenRect, centreOf = centreOf,
    pickTarget = pickTarget, underCrosshair = underCrosshair,
    aimTargetPart = aimTargetPart, placeKind = placeKind,
    roValue = roValue, tapKey = tapKey, pullTrigger = pullTrigger, holdKey = holdKey,
    equippedWeapon = equippedWeapon, swordOut = swordOut, auraPick = auraPick,
    hittable = hittable, auraActive = auraActive,
    probeInput = probeInput, INPUT = INPUT, clickMethod = clickMethod, keyMethod = keyMethod,
    ATTACK_MELEE = ATTACK_MELEE, ATTACK_GUN = ATTACK_GUN,
    POOL = POOL, CHAMS = CHAMS,
}

note("ready  -  " .. placeKind())
