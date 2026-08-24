-- ===============================================================
-- IVORY HUB - KEY SYSTEM UI
-- "Liquid Glass - Sakura" edition
-- ===============================================================

-- ===============================================================
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ===============================================================
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = tostring(math.random(100000,999999)) .. tostring(tick()):sub(-6)
local _integritySalt = 0x4A
local function _verifyIntegrity()
    if not _k or not _k.v then return false end
    if _k.i ~= (_integritySalt + #(_k.s or "")) then _k.v = false; return false end
    return true
end

do -- wrap key system UI in a block to avoid hitting the 200 local register limit

-- ===============================================================
-- SERVICES
-- ===============================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Camera = workspace.CurrentCamera

-- ===============================================================
-- EMBEDDED LOOTLABS KEY (OBFUSCATED - table parts, concatenated at runtime)
-- ===============================================================
local _lootKey = ""
do
    local _s = 0x5A
    local _b = {19,12,21,8,3,119,11,31,12,0,119,108,2,8,98,119,10,99,99,98,119,29,109,22,108}
    local _c = {}
    for _i = 1, #_b do _c[_i] = string.char(bit32.bxor(_b[_i], _s)) end
    _lootKey = table.concat(_c)
end

-- ===============================================================
-- DESIGN TOKENS
-- ===============================================================
local Theme = {
    GlassCard      = Color3.fromRGB(18, 16, 26),
    GlassCardAlt   = Color3.fromRGB(26, 22, 38),
    GlassInput     = Color3.fromRGB(255, 255, 255),
    Stroke         = Color3.fromRGB(255, 255, 255),
    TextPrimary    = Color3.fromRGB(248, 244, 255),
    TextSecondary  = Color3.fromRGB(184, 176, 205),
    TextTertiary   = Color3.fromRGB(134, 126, 156),
    AccentA        = Color3.fromRGB(168, 120, 255),
    AccentB        = Color3.fromRGB(255, 130, 205),
    AccentC        = Color3.fromRGB(110, 100, 255),
    Sakura         = Color3.fromRGB(255, 183, 206),
    SakuraLight    = Color3.fromRGB(255, 224, 235),
    Success        = Color3.fromRGB(96, 235, 150),
    Error          = Color3.fromRGB(255, 108, 108),
    Discord        = Color3.fromRGB(114, 137, 218),
    Blue           = Color3.fromRGB(120, 180, 255),
    WorkInkTeal    = Color3.fromRGB(0, 158, 130),
    LootPurple     = Color3.fromRGB(124, 58, 205),
    LootGold       = Color3.fromRGB(255, 196, 40),
}

-- ===============================================================
-- TWEEN HELPERS
-- ===============================================================
local EASE_OUT_SOFT = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local EASE_SPRING   = TweenInfo.new(0.4,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local EASE_QUICK    = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local EASE_SLOW     = TweenInfo.new(0.6,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function tw(instance, info, props)
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

-- ===============================================================
-- VECTOR ICON BUILDERS
-- ===============================================================

local function IconDiamondMark(parent, color, size)
    size = size or 30
    local gem = Instance.new("Frame")
    gem.Size = UDim2.fromOffset(size, size)
    gem.Position = UDim2.fromScale(0.5, 0.5)
    gem.AnchorPoint = Vector2.new(0.5, 0.5)
    gem.Rotation = 45
    gem.BackgroundColor3 = color
    gem.BorderSizePixel = 0
    gem.ZIndex = parent.ZIndex + 1
    gem.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = gem
    local shine = Instance.new("UIGradient")
    shine.Rotation = 90
    shine.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.45, color),
        ColorSequenceKeypoint.new(1, color),
    })
    shine.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.5, 0.35),
        NumberSequenceKeypoint.new(1, 0.35),
    })
    shine.Parent = gem
    return gem
end

local function IconChat(parent, color)
    local dot = Color3.fromRGB(20, 18, 28)
    local bubble = Instance.new("Frame")
    bubble.Size = UDim2.fromOffset(24, 16)
    bubble.Position = UDim2.new(0.5, 0, 0.5, -3)
    bubble.AnchorPoint = Vector2.new(0.5, 0.5)
    bubble.BackgroundColor3 = color
    bubble.BorderSizePixel = 0
    bubble.ZIndex = parent.ZIndex + 1
    bubble.Parent = parent
    local bubbleCorner = Instance.new("UICorner")
    bubbleCorner.CornerRadius = UDim.new(1, 0)
    bubbleCorner.Parent = bubble

    local tail = Instance.new("Frame")
    tail.Size = UDim2.fromOffset(7, 7)
    tail.Position = UDim2.new(0.5, -6, 0.5, 5)
    tail.AnchorPoint = Vector2.new(0.5, 0.5)
    tail.Rotation = 45
    tail.BackgroundColor3 = color
    tail.BorderSizePixel = 0
    tail.ZIndex = parent.ZIndex + 1
    tail.Parent = parent
    local tailCorner = Instance.new("UICorner")
    tailCorner.CornerRadius = UDim.new(0, 2)
    tailCorner.Parent = tail

    for i = 0, 2 do
        local d = Instance.new("Frame")
        d.Size = UDim2.fromOffset(3, 3)
        d.Position = UDim2.new(0.5, -7 + i * 7, 0.5, -3)
        d.AnchorPoint = Vector2.new(0.5, 0.5)
        d.BackgroundColor3 = dot
        d.BorderSizePixel = 0
        d.ZIndex = parent.ZIndex + 2
        d.Parent = parent
        local dCorner = Instance.new("UICorner")
        dCorner.CornerRadius = UDim.new(1, 0)
        dCorner.Parent = d
    end
end

local function IconWorkMark(parent, color)
    local points = {
        { -11, -7 }, { -5.5, 7 }, { 0, -2 }, { 5.5, 7 }, { 11, -7 },
    }
    for i = 1, #points - 1 do
        local x1, y1 = points[i][1], points[i][2]
        local x2, y2 = points[i + 1][1], points[i + 1][2]
        local dx, dy = x2 - x1, y2 - y1
        local length = math.sqrt(dx * dx + dy * dy)
        local angle = math.deg(math.atan2(dy, dx))
        local midX, midY = (x1 + x2) / 2, (y1 + y2) / 2

        local bar = Instance.new("Frame")
        bar.Size = UDim2.fromOffset(length + 3, 4.4)
        bar.Position = UDim2.new(0.5, midX, 0.5, midY)
        bar.AnchorPoint = Vector2.new(0.5, 0.5)
        bar.Rotation = angle
        bar.BackgroundColor3 = color
        bar.BorderSizePixel = 0
        bar.ZIndex = parent.ZIndex + 1
        bar.Parent = parent
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = bar
    end
end

local function IconLootGem(parent, colorA, colorB)
    local gem = Instance.new("Frame")
    gem.Size = UDim2.fromOffset(20, 20)
    gem.Position = UDim2.fromScale(0.5, 0.5)
    gem.AnchorPoint = Vector2.new(0.5, 0.5)
    gem.Rotation = 45
    gem.BackgroundColor3 = colorA
    gem.BorderSizePixel = 0
    gem.ZIndex = parent.ZIndex + 1
    gem.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = gem

    local facet = Instance.new("Frame")
    facet.Size = UDim2.fromOffset(9, 9)
    facet.Position = UDim2.new(0, -1, 0, -1)
    facet.AnchorPoint = Vector2.new(0, 0)
    facet.BackgroundColor3 = colorB
    facet.BorderSizePixel = 0
    facet.ZIndex = parent.ZIndex + 2
    facet.Parent = gem
    local facetCorner = Instance.new("UICorner")
    facetCorner.CornerRadius = UDim.new(0, 2)
    facetCorner.Parent = facet

    local shine = Instance.new("UIGradient")
    shine.Rotation = 90
    shine.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.4, colorA),
        ColorSequenceKeypoint.new(1, colorA),
    })
    shine.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(0.45, 0.55),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    shine.Parent = gem
end

local function IconChevron(parent, color, size)
    size = size or 6
    local top = Instance.new("Frame")
    top.Size = UDim2.fromOffset(size, 1.8)
    top.Position = UDim2.new(0.5, 0, 0.5, -size * 0.36)
    top.AnchorPoint = Vector2.new(0.5, 0.5)
    top.Rotation = 45
    top.BackgroundColor3 = color
    top.BorderSizePixel = 0
    top.ZIndex = parent.ZIndex + 1
    top.Parent = parent
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(1, 0)
    c1.Parent = top

    local bottom = top:Clone()
    bottom.Position = UDim2.new(0.5, 0, 0.5, size * 0.36)
    bottom.Rotation = -45
    bottom.Parent = parent

    return top, bottom
end

local function IconKeyMini(parent, color)
    local ring = Instance.new("Frame")
    ring.Size = UDim2.fromOffset(9, 9)
    ring.Position = UDim2.new(0, 0, 0.5, 0)
    ring.AnchorPoint = Vector2.new(0, 0.5)
    ring.BackgroundTransparency = 1
    ring.ZIndex = parent.ZIndex + 1
    ring.Parent = parent
    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(1, 0)
    ringCorner.Parent = ring
    local ringStroke = Instance.new("UIStroke")
    ringStroke.Thickness = 1.6
    ringStroke.Color = color
    ringStroke.Parent = ring

    local shaft = Instance.new("Frame")
    shaft.Size = UDim2.fromOffset(9, 1.6)
    shaft.Position = UDim2.new(0, 8, 0.5, 0)
    shaft.AnchorPoint = Vector2.new(0, 0.5)
    shaft.BackgroundColor3 = color
    shaft.BorderSizePixel = 0
    shaft.ZIndex = parent.ZIndex + 1
    shaft.Parent = parent

    local tooth = Instance.new("Frame")
    tooth.Size = UDim2.fromOffset(1.6, 4)
    tooth.Position = UDim2.new(0, 15, 0.5, 0)
    tooth.AnchorPoint = Vector2.new(0, 0)
    tooth.BackgroundColor3 = color
    tooth.BorderSizePixel = 0
    tooth.ZIndex = parent.ZIndex + 1
    tooth.Parent = parent
end

local function IconCross(parent, color, size)
    size = size or 14
    local bar1 = Instance.new("Frame")
    bar1.Size = UDim2.fromOffset(size, 2)
    bar1.Position = UDim2.fromScale(0.5, 0.5)
    bar1.AnchorPoint = Vector2.new(0.5, 0.5)
    bar1.Rotation = 45
    bar1.BackgroundColor3 = color
    bar1.BorderSizePixel = 0
    bar1.ZIndex = parent.ZIndex + 1
    bar1.Parent = parent
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(1, 0)
    c1.Parent = bar1
    local bar2 = bar1:Clone()
    bar2.Rotation = -45
    bar2.Parent = parent
    return bar1, bar2
end

local function IconSparkle(parent, color, size)
    size = size or 10
    local bar1 = Instance.new("Frame")
    bar1.Size = UDim2.fromOffset(size, 2)
    bar1.Position = UDim2.fromScale(0.5, 0.5)
    bar1.AnchorPoint = Vector2.new(0.5, 0.5)
    bar1.BackgroundColor3 = color
    bar1.BackgroundTransparency = 0.6
    bar1.BorderSizePixel = 0
    bar1.ZIndex = parent.ZIndex + 1
    bar1.Parent = parent
    local c1 = Instance.new("UICorner")
    c1.CornerRadius = UDim.new(1, 0)
    c1.Parent = bar1
    local bar2 = bar1:Clone()
    bar2.Rotation = 90
    bar2.Parent = parent
    return bar1, bar2
end

-- ===============================================================
-- ROOT SCREENGUI
-- ===============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IvoryKey"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- ===============================================================
-- REAL BACKDROP BLUR
-- ===============================================================
local BackdropBlur = Instance.new("BlurEffect")
BackdropBlur.Name = "IvoryBackdropBlur"
BackdropBlur.Size = 0
pcall(function() BackdropBlur.Parent = Lighting end)
tw(BackdropBlur, EASE_SLOW, { Size = 22 })

local Dim = Instance.new("Frame")
Dim.Name = "Dim"
Dim.Size = UDim2.fromScale(1, 1)
Dim.BackgroundColor3 = Color3.fromRGB(8, 6, 14)
Dim.BackgroundTransparency = 1
Dim.BorderSizePixel = 0
Dim.ZIndex = 1
Dim.Parent = ScreenGui
tw(Dim, EASE_SLOW, { BackgroundTransparency = 0.5 })

local _unloaded = false
local unloadUI

local Aura = Instance.new("Frame")
Aura.Name = "Aura"
Aura.AnchorPoint = Vector2.new(0.5, 0.5)
Aura.Position = UDim2.fromScale(0.5, 0.5)
Aura.Size = UDim2.fromOffset(640, 640)
Aura.BackgroundColor3 = Theme.AccentA
Aura.BackgroundTransparency = 1
Aura.BorderSizePixel = 0
Aura.ZIndex = 2
Aura.Parent = ScreenGui
local AuraCorner = Instance.new("UICorner")
AuraCorner.CornerRadius = UDim.new(1, 0)
AuraCorner.Parent = Aura
local AuraGradient = Instance.new("UIGradient")
AuraGradient.Rotation = 45
AuraGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentA),
    ColorSequenceKeypoint.new(0.5, Theme.AccentC),
    ColorSequenceKeypoint.new(1, Theme.AccentB),
})
AuraGradient.Parent = Aura
local AuraScale = Instance.new("UIScale")
AuraScale.Parent = Aura
tw(Aura, EASE_SLOW, { BackgroundTransparency = 0.88 })

task.spawn(function()
    while Aura.Parent do
        tw(AuraScale, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1.1 })
        tw(Aura, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.93 })
        task.wait(3.2)
        tw(AuraScale, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1 })
        tw(Aura, TweenInfo.new(3.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.88 })
        task.wait(3.2)
    end
end)

-- ===============================================================
-- CLOUD CURTAIN SYSTEM
-- ===============================================================
local CLOUD_PALETTE = { Theme.AccentA, Theme.AccentB, Theme.AccentC, Theme.SakuraLight }

local function makeCloudCluster(side)
    local root = Instance.new("Frame")
    root.Name = "Cloud" .. side
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.ZIndex = 2
    root.Parent = ScreenGui

    local state = { puffs = {} }

    local panel = Instance.new("Frame")
    panel.Name = "CurtainPanel"
    panel.Size = UDim2.new(0.58, 0, 1.3, 0)
    panel.BackgroundColor3 = Theme.GlassCard
    panel.BorderSizePixel = 0
    panel.ZIndex = 2
    panel.Parent = root
    local panelGradient = Instance.new("UIGradient")
    panelGradient.Rotation = side == "left" and 25 or -25
    panelGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentC),
        ColorSequenceKeypoint.new(0.55, Theme.GlassCard),
        ColorSequenceKeypoint.new(1, Theme.AccentA),
    })
    panelGradient.Parent = panel

    local panelCoverX = side == "left" and -0.08 or 0.46
    local panelRestX = side == "left" and -0.62 or 1.04
    panel.Position = UDim2.fromScale(panelCoverX, -0.15)
    state.panel = { inst = panel, restX = panelRestX, coverX = panelCoverX, y = -0.15 }

    local puffCount = 8
    for i = 1, puffCount do
        local size = math.random(90, 190)
        local puff = Instance.new("Frame")
        puff.Size = UDim2.fromOffset(size, size)
        puff.AnchorPoint = Vector2.new(0.5, 0.5)
        puff.BackgroundColor3 = CLOUD_PALETTE[math.random(1, #CLOUD_PALETTE)]
        puff.BackgroundTransparency = 0.8 + math.random() * 0.12
        puff.BorderSizePixel = 0
        puff.ZIndex = 2
        puff.Parent = root
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = puff

        local edge = (i - 1) / (puffCount - 1)
        local restX = side == "left"
            and (-0.09 + edge * 0.14 + (math.random() - 0.5) * 0.025)
            or (0.95 + edge * 0.14 + (math.random() - 0.5) * 0.025)
        local restY = 0.08 + edge * 0.84 + (math.random() - 0.5) * 0.04

        puff.Position = UDim2.fromScale(restX, restY)

        table.insert(state.puffs, {
            inst = puff,
            restX = restX, restY = restY,
            phase = math.random() * 6.28,
            speed = 0.1 + math.random() * 0.16,
            amp = 0.007 + math.random() * 0.01,
        })
    end

    task.spawn(function()
        local t0 = tick()
        while root.Parent do
            local t = tick() - t0
            for _, p in ipairs(state.puffs) do
                local dx = math.sin(t * p.speed + p.phase) * p.amp
                local dy = math.cos(t * p.speed * 0.8 + p.phase) * p.amp
                p.inst.Position = UDim2.fromScale(p.restX + dx, p.restY + dy)
            end
            RunService.Heartbeat:Wait()
        end
    end)

    return root, state
end

local CloudLeftRoot, CloudLeftState = makeCloudCluster("left")
local CloudRightRoot, CloudRightState = makeCloudCluster("right")

local function sweepClouds(open, duration)
    for _, state in ipairs({ CloudLeftState, CloudRightState }) do
        local panelX = open and state.panel.restX or state.panel.coverX
        tw(state.panel.inst, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Position = UDim2.fromScale(panelX, state.panel.y),
        })
    end
end

local function revealClouds(duration) sweepClouds(true, duration or 1.1) end
local function concealClouds(duration) sweepClouds(false, duration or 0.65) end

local CURTAIN_EXIT_OPEN = 0.9
local CURTAIN_EXIT_SETTLE = 0.4
local CURTAIN_EXIT_FADE = 0.35
local CURTAIN_EXIT_TOTAL = CURTAIN_EXIT_OPEN + CURTAIN_EXIT_SETTLE + CURTAIN_EXIT_FADE + 0.15

local RayBurst = Instance.new("Frame")
RayBurst.Name = "RayBurst"
RayBurst.Size = UDim2.fromScale(1, 1)
RayBurst.BackgroundTransparency = 1
RayBurst.ZIndex = 2
RayBurst.Parent = ScreenGui

local rays = {}
local RAY_COUNT = 12
for i = 1, RAY_COUNT do
    local ray = Instance.new("Frame")
    ray.Size = UDim2.fromOffset(3, 820)
    ray.AnchorPoint = Vector2.new(0.5, 0.5)
    ray.Position = UDim2.fromScale(0.5, 0.5)
    ray.Rotation = (360 / RAY_COUNT) * i
    ray.BackgroundColor3 = Color3.fromRGB(220, 195, 255)
    ray.BorderSizePixel = 0
    ray.ZIndex = 2
    ray.Parent = RayBurst
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new(Color3.fromRGB(230, 205, 255))
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.46, 0.95),
        NumberSequenceKeypoint.new(0.5, 0.9),
        NumberSequenceKeypoint.new(0.54, 0.95),
        NumberSequenceKeypoint.new(1, 1),
    })
    grad.Parent = ray
    table.insert(rays, ray)
end

task.spawn(function()
    while RayBurst.Parent do
        for _, ray in ipairs(rays) do
            ray.Rotation = ray.Rotation + 0.025
        end
        RunService.Heartbeat:Wait()
    end
end)

local function teardownBackdrop()
    tw(Dim, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    tw(Aura, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    local t = tw(BackdropBlur, EASE_OUT_SOFT, { Size = 0 })
    t.Completed:Connect(function()
        pcall(function() BackdropBlur:Destroy() end)
    end)
    for _, ray in ipairs(rays) do
        tw(ray, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    end

    revealClouds(CURTAIN_EXIT_OPEN)
    task.delay(CURTAIN_EXIT_OPEN + CURTAIN_EXIT_SETTLE, function()
        for _, state in ipairs({ CloudLeftState, CloudRightState }) do
            for _, p in ipairs(state.puffs) do
                tw(p.inst, TweenInfo.new(CURTAIN_EXIT_FADE, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1,
                })
            end
        end
    end)
end

-- ===============================================================
-- AMBIENT MUSIC (optional)
-- ===============================================================
local IntroMusic = Instance.new("Sound")
IntroMusic.Name = "IvoryAmbientMusic"
IntroMusic.SoundId = "rbxassetid://0"
IntroMusic.Volume = 0
IntroMusic.Looped = true
pcall(function() IntroMusic.Parent = SoundService end)
if IntroMusic.SoundId ~= "rbxassetid://0" then
    pcall(function() IntroMusic:Play() end)
    tw(IntroMusic, TweenInfo.new(1.5), { Volume = 0.32 })
end

local function fadeOutMusic()
    if IntroMusic.SoundId ~= "rbxassetid://0" then
        local t = tw(IntroMusic, EASE_SLOW, { Volume = 0 })
        t.Completed:Connect(function()
            pcall(function() IntroMusic:Stop(); IntroMusic:Destroy() end)
        end)
    end
end

-- ===============================================================
-- FALLING SAKURA PETALS
-- ===============================================================
local function makePetalField(zIndex, count, sizeMin, sizeMax, speedMin, speedMax)
    local field = Instance.new("Frame")
    field.Name = "PetalField"
    field.Size = UDim2.fromScale(1, 1)
    field.BackgroundTransparency = 1
    field.ZIndex = zIndex
    field.Parent = ScreenGui

    local petals = {}

    local function newPetal(initial)
        local vp = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
        local size = math.random(sizeMin * 10, sizeMax * 10) / 10
        local petal = Instance.new("Frame")
        petal.Size = UDim2.fromOffset(size, size * 0.68)
        petal.AnchorPoint = Vector2.new(0.5, 0.5)
        petal.BackgroundColor3 = Theme.SakuraLight
        petal.BackgroundTransparency = 0.25 + math.random() * 0.4
        petal.BorderSizePixel = 0
        petal.Rotation = math.random(0, 360)
        petal.ZIndex = zIndex
        petal.Parent = field

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = petal

        local grad = Instance.new("UIGradient")
        grad.Rotation = math.random(0, 180)
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Theme.Sakura),
            ColorSequenceKeypoint.new(1, Theme.SakuraLight),
        })
        grad.Parent = petal

        return {
            inst = petal,
            x = math.random(0, math.floor(vp.X)),
            y = initial and math.random(-40, math.floor(vp.Y)) or -30,
            speed = speedMin + math.random() * (speedMax - speedMin),
            swayAmp = 12 + math.random() * 22,
            swayFreq = 0.4 + math.random() * 0.8,
            phase = math.random() * 6.28,
            rotSpeed = (math.random() - 0.5) * 60,
        }
    end

    for _ = 1, count do
        table.insert(petals, newPetal(true))
    end

    task.spawn(function()
        while field.Parent do
            local dt = RunService.Heartbeat:Wait()
            local vp = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
            for _, p in ipairs(petals) do
                p.y = p.y + p.speed * dt
                p.phase = p.phase + dt
                local swayX = math.sin(p.phase * p.swayFreq) * p.swayAmp
                p.inst.Position = UDim2.fromOffset(p.x + swayX, p.y)
                p.inst.Rotation = p.inst.Rotation + p.rotSpeed * dt
                if p.y > vp.Y + 40 then
                    p.y = -30 - math.random(0, 200)
                    p.x = math.random(0, math.floor(vp.X))
                end
            end
        end
    end)

    return field
end

local PetalsBack = makePetalField(3, 26, 8, 16, 26, 55)
local PetalsFront = makePetalField(30, 7, 12, 20, 55, 90)

-- ===============================================================
-- SHADOW HELPER
-- ===============================================================
local function attachShadow(parent, cornerRadius, layers)
    layers = layers or 7
    cornerRadius = cornerRadius or 30
    local holder = Instance.new("Frame")
    holder.Name = "Shadow"
    holder.Size = UDim2.fromScale(1, 1)
    holder.BackgroundTransparency = 1
    holder.ZIndex = parent.ZIndex - 1
    holder.Parent = parent.Parent
    for i = layers, 1, -1 do
        local grow = i * 12
        local layer = Instance.new("Frame")
        layer.AnchorPoint = Vector2.new(0.5, 0.5)
        layer.Position = UDim2.new(0.5, 0, 0.5, 10)
        layer.Size = UDim2.new(1, grow, 1, grow)
        layer.BackgroundColor3 = Color3.fromRGB(5, 3, 10)
        layer.BackgroundTransparency = 0.9 - (layers - i) * (0.42 / layers)
        layer.BorderSizePixel = 0
        layer.ZIndex = holder.ZIndex
        layer.Parent = holder
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, cornerRadius + grow / 2)
        c.Parent = layer
    end
    return holder
end

-- ===============================================================
-- MAIN GLASS CARD
-- ===============================================================
local CardHolder = Instance.new("Frame")
CardHolder.Name = "CardHolder"
CardHolder.AnchorPoint = Vector2.new(0.5, 0.5)
CardHolder.Position = UDim2.fromScale(0.5, 0.5)
CardHolder.Size = UDim2.fromOffset(420, 580)
CardHolder.BackgroundTransparency = 1
CardHolder.ZIndex = 5
CardHolder.Visible = false
CardHolder.Parent = ScreenGui

local CardScale = Instance.new("UIScale")
CardScale.Scale = 0.86
CardScale.Parent = CardHolder

local Card = Instance.new("Frame")
Card.Name = "Card"
Card.Size = UDim2.fromScale(1, 1)
Card.BackgroundColor3 = Theme.GlassCard
Card.BackgroundTransparency = 0.16
Card.BorderSizePixel = 0
Card.ClipsDescendants = true
Card.ZIndex = 5
Card.Parent = CardHolder

local CardCorner = Instance.new("UICorner")
CardCorner.CornerRadius = UDim.new(0, 30)
CardCorner.Parent = Card

attachShadow(Card, 30, 7)

local CardStroke = Instance.new("UIStroke")
CardStroke.Thickness = 1.4
CardStroke.Color = Theme.Stroke
CardStroke.Transparency = 0.55
CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
CardStroke.Parent = Card

local CardStrokeGradient = Instance.new("UIGradient")
CardStrokeGradient.Rotation = 105
CardStrokeGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(210, 180, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255,255,255)),
})
CardStrokeGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.15),
    NumberSequenceKeypoint.new(0.5, 0.85),
    NumberSequenceKeypoint.new(1, 0.2),
})
CardStrokeGradient.Parent = CardStroke

task.spawn(function()
    while CardStroke.Parent do
        CardStrokeGradient.Rotation = (CardStrokeGradient.Rotation + 0.15) % 360
        RunService.Heartbeat:Wait()
    end
end)

local BlobLayer = Instance.new("Frame")
BlobLayer.Name = "BlobLayer"
BlobLayer.Size = UDim2.fromScale(1, 1)
BlobLayer.BackgroundTransparency = 1
BlobLayer.ZIndex = 5
BlobLayer.Parent = Card

local function makeBlob(color, size, startPos)
    local blob = Instance.new("Frame")
    blob.BackgroundColor3 = color
    blob.BackgroundTransparency = 0.72
    blob.Size = UDim2.fromOffset(size, size)
    blob.Position = startPos
    blob.AnchorPoint = Vector2.new(0.5, 0.5)
    blob.BorderSizePixel = 0
    blob.ZIndex = 4
    blob.Parent = BlobLayer
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = blob
    return blob
end

local blobA = makeBlob(Theme.AccentA, 230, UDim2.fromScale(0.08, 0.05))
local blobB = makeBlob(Theme.AccentB, 200, UDim2.fromScale(0.95, 0.16))
local blobC = makeBlob(Theme.AccentC, 250, UDim2.fromScale(0.85, 1.0))

task.spawn(function()
    local t0 = tick()
    while BlobLayer.Parent do
        local t = tick() - t0
        blobA.Position = UDim2.fromScale(0.08 + math.sin(t * 0.35) * 0.05, 0.05 + math.cos(t * 0.28) * 0.04)
        blobB.Position = UDim2.fromScale(0.95 + math.sin(t * 0.22 + 2) * 0.04, 0.16 + math.cos(t * 0.31 + 1) * 0.05)
        blobC.Position = UDim2.fromScale(0.85 + math.sin(t * 0.26 + 4) * 0.05, 1.0 + math.cos(t * 0.24 + 3) * 0.04)
        RunService.Heartbeat:Wait()
    end
end)

local Sheen = Instance.new("Frame")
Sheen.BackgroundColor3 = Color3.fromRGB(255,255,255)
Sheen.BackgroundTransparency = 1
Sheen.Size = UDim2.fromScale(1, 1)
Sheen.ZIndex = 6
Sheen.Parent = Card
local SheenGradient = Instance.new("UIGradient")
SheenGradient.Rotation = 115
SheenGradient.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
SheenGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.42, 1),
    NumberSequenceKeypoint.new(0.5, 0.9),
    NumberSequenceKeypoint.new(0.58, 1),
    NumberSequenceKeypoint.new(1, 1),
})
SheenGradient.Parent = Sheen

-- ===============================================================
-- TOP REGION - CENTRAL GLOWING LOGO (draggable handle)
-- ===============================================================
local TopRegion = Instance.new("Frame")
TopRegion.Name = "TopRegion"
TopRegion.Size = UDim2.new(1, 0, 0, 176)
TopRegion.BackgroundTransparency = 1
TopRegion.Active = true
TopRegion.ZIndex = 6
TopRegion.Parent = Card

do
    local dragging, dragStart, startPos = false, nil, nil

    local function updateDrag(input)
        local delta = input.Position - dragStart
        CardHolder.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    TopRegion.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = CardHolder.Position
            tw(CardScale, EASE_QUICK, { Scale = 0.975 })
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    tw(CardScale, EASE_SPRING, { Scale = 1 })
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)
end

local UnloadBtn = Instance.new("TextButton")
UnloadBtn.Name = "UnloadBtn"
UnloadBtn.Size = UDim2.fromOffset(34, 34)
UnloadBtn.Position = UDim2.new(1, -16, 0, 16)
UnloadBtn.AnchorPoint = Vector2.new(1, 0)
UnloadBtn.BackgroundColor3 = Theme.GlassCardAlt
UnloadBtn.BackgroundTransparency = 0.35
UnloadBtn.AutoButtonColor = false
UnloadBtn.Text = ""
UnloadBtn.ZIndex = 8
UnloadBtn.Parent = TopRegion
local UnloadCorner = Instance.new("UICorner")
UnloadCorner.CornerRadius = UDim.new(1, 0)
UnloadCorner.Parent = UnloadBtn
local UnloadStroke = Instance.new("UIStroke")
UnloadStroke.Thickness = 1.2
UnloadStroke.Color = Color3.fromRGB(255, 255, 255)
UnloadStroke.Transparency = 0.75
UnloadStroke.Parent = UnloadBtn
local UnloadScale = Instance.new("UIScale")
UnloadScale.Parent = UnloadBtn

local xBar1, xBar2 = IconCross(UnloadBtn, Theme.TextSecondary, 13)

local UnloadTip = Instance.new("TextLabel")
UnloadTip.Size = UDim2.fromOffset(80, 18)
UnloadTip.Position = UDim2.new(0.5, 0, 1, 8)
UnloadTip.AnchorPoint = Vector2.new(0.5, 0)
UnloadTip.BackgroundTransparency = 1
UnloadTip.Text = "Unload UI"
UnloadTip.TextColor3 = Theme.Error
UnloadTip.Font = Enum.Font.GothamMedium
UnloadTip.TextSize = 11
UnloadTip.TextTransparency = 1
UnloadTip.ZIndex = 9
UnloadTip.Parent = UnloadBtn

UnloadBtn.MouseEnter:Connect(function()
    tw(UnloadBtn, EASE_QUICK, { BackgroundTransparency = 0.1, BackgroundColor3 = Theme.Error })
    tw(UnloadStroke, EASE_QUICK, { Transparency = 0.3, Color = Theme.Error })
    tw(xBar1, EASE_QUICK, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
    tw(xBar2, EASE_QUICK, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) })
    tw(UnloadScale, EASE_QUICK, { Scale = 1.1 })
    tw(UnloadTip, EASE_QUICK, { TextTransparency = 0 })
end)
UnloadBtn.MouseLeave:Connect(function()
    tw(UnloadBtn, EASE_QUICK, { BackgroundTransparency = 0.35, BackgroundColor3 = Theme.GlassCardAlt })
    tw(UnloadStroke, EASE_QUICK, { Transparency = 0.75, Color = Color3.fromRGB(255, 255, 255) })
    tw(xBar1, EASE_QUICK, { BackgroundColor3 = Theme.TextSecondary })
    tw(xBar2, EASE_QUICK, { BackgroundColor3 = Theme.TextSecondary })
    tw(UnloadScale, EASE_QUICK, { Scale = 1 })
    tw(UnloadTip, EASE_QUICK, { TextTransparency = 1 })
end)
UnloadBtn.MouseButton1Down:Connect(function() tw(UnloadScale, EASE_QUICK, { Scale = 0.9 }) end)
UnloadBtn.MouseButton1Up:Connect(function() tw(UnloadScale, EASE_SPRING, { Scale = 1.1 }) end)
UnloadBtn.MouseButton1Click:Connect(function()
    if unloadUI then unloadUI() end
end)

local GlowRing = Instance.new("Frame")
GlowRing.AnchorPoint = Vector2.new(0.5, 0.5)
GlowRing.Position = UDim2.new(0.5, 0, 0, 62)
GlowRing.Size = UDim2.fromOffset(96, 96)
GlowRing.BackgroundTransparency = 1
GlowRing.ZIndex = 6
GlowRing.Parent = TopRegion
local GlowStroke = Instance.new("UIStroke")
GlowStroke.Thickness = 2
GlowStroke.Color = Theme.AccentA
GlowStroke.Transparency = 0.35
GlowStroke.Parent = GlowRing
local GlowCorner = Instance.new("UICorner")
GlowCorner.CornerRadius = UDim.new(1, 0)
GlowCorner.Parent = GlowRing
local GlowScale = Instance.new("UIScale")
GlowScale.Parent = GlowRing

task.spawn(function()
    while GlowRing.Parent do
        tw(GlowScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1.18 })
        tw(GlowStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.85 })
        task.wait(1.6)
        tw(GlowScale, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Scale = 1 })
        tw(GlowStroke, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Transparency = 0.35 })
        task.wait(1.6)
    end
end)

local Logo = Instance.new("Frame")
Logo.AnchorPoint = Vector2.new(0.5, 0.5)
Logo.Position = UDim2.new(0.5, 0, 0, 62)
Logo.Size = UDim2.fromOffset(76, 76)
Logo.BackgroundColor3 = Color3.fromRGB(255,255,255)
Logo.ZIndex = 7
Logo.Parent = TopRegion
local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = Logo
local LogoGradient = Instance.new("UIGradient")
LogoGradient.Rotation = 45
LogoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentA),
    ColorSequenceKeypoint.new(0.5, Theme.AccentC),
    ColorSequenceKeypoint.new(1, Theme.AccentB),
})
LogoGradient.Parent = Logo
local LogoStroke = Instance.new("UIStroke")
LogoStroke.Thickness = 1.5
LogoStroke.Color = Color3.fromRGB(255,255,255)
LogoStroke.Transparency = 0.4
LogoStroke.Parent = Logo

IconDiamondMark(Logo, Color3.fromRGB(255, 255, 255), 30)

task.spawn(function()
    local t0 = tick()
    local baseLogoY, baseRingY = 62, 62
    while Logo.Parent do
        local t = tick() - t0
        local bob = math.sin(t * 1.1) * 4
        Logo.Position = UDim2.new(0.5, 0, 0, baseLogoY + bob)
        GlowRing.Position = UDim2.new(0.5, 0, 0, baseRingY + bob)
        RunService.Heartbeat:Wait()
    end
end)

task.spawn(function()
    while Logo.Parent do
        LogoGradient.Rotation = (LogoGradient.Rotation + 0.6) % 360
        RunService.Heartbeat:Wait()
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 0, 26)
Title.Position = UDim2.new(0, 20, 0, 112)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.TextPrimary
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Text = "Ivory Hub"
Title.ZIndex = 7
Title.Parent = TopRegion

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -40, 0, 16)
Subtitle.Position = UDim2.new(0, 20, 0, 140)
Subtitle.BackgroundTransparency = 1
Subtitle.TextColor3 = Theme.TextTertiary
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Center
Subtitle.Text = "Enter your key to continue"
Subtitle.ZIndex = 7
Subtitle.Parent = TopRegion

local function addSparkle(parent, x, y, size, startDelay)
    local bar1, bar2 = IconSparkle(parent, Color3.fromRGB(255, 255, 255), size)
    bar1.Position = UDim2.new(0, x, 0, y)
    bar2.Position = UDim2.new(0, x, 0, y)
    task.spawn(function()
        task.wait(startDelay)
        while bar1.Parent do
            tw(bar1, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.1 })
            tw(bar2, TweenInfo.new(1.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.1 })
            task.wait(1.1)
            tw(bar1, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.9 })
            tw(bar2, TweenInfo.new(1.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.9 })
            task.wait(1.3)
        end
    end)
end

addSparkle(TopRegion, 58, 28, 8, 0)
addSparkle(TopRegion, 335, 42, 6, 0.5)
addSparkle(TopRegion, 300, 104, 7, 1.1)
addSparkle(TopRegion, 48, 108, 6, 1.7)

-- ===============================================================
-- CONTENT COLUMN
-- ===============================================================
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -48, 1, -196)
Content.Position = UDim2.new(0, 24, 0, 180)
Content.BackgroundTransparency = 1
Content.ZIndex = 7
Content.Parent = Card

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.FillDirection = Enum.FillDirection.Vertical
ContentLayout.Padding = UDim.new(0, 14)
ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.Parent = Content

local InputWrap = Instance.new("Frame")
InputWrap.Name = "InputWrap"
InputWrap.Size = UDim2.new(1, 0, 0, 52)
InputWrap.BackgroundColor3 = Theme.GlassInput
InputWrap.BackgroundTransparency = 0.93
InputWrap.LayoutOrder = 1
InputWrap.ZIndex = 7
InputWrap.Parent = Content
local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 16)
InputCorner.Parent = InputWrap
local InputStroke = Instance.new("UIStroke")
InputStroke.Thickness = 1.2
InputStroke.Color = Color3.fromRGB(255,255,255)
InputStroke.Transparency = 0.82
InputStroke.Parent = InputWrap
local InputPad = Instance.new("UIPadding")
InputPad.PaddingLeft = UDim.new(0, 16)
InputPad.PaddingRight = UDim.new(0, 16)
InputPad.Parent = InputWrap

local InputIcon = Instance.new("Frame")
InputIcon.Size = UDim2.fromOffset(20, 18)
InputIcon.Position = UDim2.new(0, 0, 0.5, 0)
InputIcon.AnchorPoint = Vector2.new(0, 0.5)
InputIcon.BackgroundTransparency = 1
InputIcon.ZIndex = 7
InputIcon.Parent = InputWrap
IconKeyMini(InputIcon, Theme.TextTertiary)

local InputBox = Instance.new("TextBox")
InputBox.Name = "KeyInput"
InputBox.Size = UDim2.new(1, -28, 1, 0)
InputBox.Position = UDim2.new(0, 28, 0, 0)
InputBox.BackgroundTransparency = 1
InputBox.Text = ""
InputBox.TextColor3 = Theme.TextPrimary
InputBox.PlaceholderColor3 = Theme.TextTertiary
InputBox.PlaceholderText = "Paste your key here"
InputBox.Font = Enum.Font.Code
InputBox.TextSize = 14
InputBox.ClearTextOnFocus = false
InputBox.TextXAlignment = Enum.TextXAlignment.Left
InputBox.ZIndex = 7
InputBox.Parent = InputWrap

InputBox.Focused:Connect(function()
    tw(InputStroke, EASE_OUT_SOFT, { Transparency = 0.15, Color = Theme.AccentA, Thickness = 1.6 })
    tw(InputWrap, EASE_OUT_SOFT, { BackgroundTransparency = 0.88 })
end)
InputBox.FocusLost:Connect(function(enterPressed)
    tw(InputStroke, EASE_OUT_SOFT, { Transparency = 0.82, Color = Color3.fromRGB(255,255,255), Thickness = 1.2 })
    tw(InputWrap, EASE_OUT_SOFT, { BackgroundTransparency = 0.93 })
    if enterPressed then
        local key = InputBox.Text:gsub("%s", "")
        if key ~= "" then ValidateKey(key) end
    end
end)

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Name = "VerifyBtn"
VerifyBtn.Size = UDim2.new(1, 0, 0, 50)
VerifyBtn.LayoutOrder = 2
VerifyBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
VerifyBtn.Text = ""
VerifyBtn.AutoButtonColor = false
VerifyBtn.ZIndex = 7
VerifyBtn.ClipsDescendants = true
VerifyBtn.Parent = Content
local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 16)
VerifyCorner.Parent = VerifyBtn
local VerifyGradient = Instance.new("UIGradient")
VerifyGradient.Rotation = 20
VerifyGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentA),
    ColorSequenceKeypoint.new(0.5, Theme.AccentC),
    ColorSequenceKeypoint.new(1, Theme.AccentB),
})
VerifyGradient.Parent = VerifyBtn
local VerifyScale = Instance.new("UIScale")
VerifyScale.Parent = VerifyBtn

local VerifyLabel = Instance.new("TextLabel")
VerifyLabel.BackgroundTransparency = 1
VerifyLabel.Size = UDim2.fromScale(1, 1)
VerifyLabel.Position = UDim2.new(0.5, -14, 0.5, 0)
VerifyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
VerifyLabel.Text = "Verify Key"
VerifyLabel.TextColor3 = Color3.fromRGB(255,255,255)
VerifyLabel.Font = Enum.Font.GothamBold
VerifyLabel.TextSize = 15
VerifyLabel.ZIndex = 8
VerifyLabel.Parent = VerifyBtn

local ChevronWrap = Instance.new("Frame")
ChevronWrap.Size = UDim2.fromOffset(14, 14)
ChevronWrap.Position = UDim2.new(0.5, 46, 0.5, 0)
ChevronWrap.AnchorPoint = Vector2.new(0.5, 0.5)
ChevronWrap.BackgroundTransparency = 1
ChevronWrap.ZIndex = 8
ChevronWrap.Parent = VerifyBtn
IconChevron(ChevronWrap, Color3.fromRGB(255, 255, 255), 7)

local VerifyShine = Instance.new("Frame")
VerifyShine.BackgroundColor3 = Color3.fromRGB(255,255,255)
VerifyShine.BackgroundTransparency = 1
VerifyShine.Size = UDim2.fromScale(1, 1)
VerifyShine.ZIndex = 8
VerifyShine.Parent = VerifyBtn
local VerifyShineGradient = Instance.new("UIGradient")
VerifyShineGradient.Rotation = 15
VerifyShineGradient.Color = ColorSequence.new(Color3.fromRGB(255,255,255))
VerifyShineGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 1),
    NumberSequenceKeypoint.new(0.46, 1),
    NumberSequenceKeypoint.new(0.5, 0.82),
    NumberSequenceKeypoint.new(0.54, 1),
    NumberSequenceKeypoint.new(1, 1),
})
VerifyShineGradient.Parent = VerifyShine

local Spinner = Instance.new("Frame")
Spinner.Size = UDim2.fromOffset(20, 20)
Spinner.Position = UDim2.fromScale(0.5, 0.5)
Spinner.AnchorPoint = Vector2.new(0.5, 0.5)
Spinner.BackgroundTransparency = 1
Spinner.Visible = false
Spinner.ZIndex = 8
Spinner.Parent = VerifyBtn
local SpinnerStroke = Instance.new("UIStroke")
SpinnerStroke.Thickness = 2.4
SpinnerStroke.Color = Color3.fromRGB(255, 255, 255)
SpinnerStroke.Parent = Spinner
local SpinnerGradient = Instance.new("UIGradient")
SpinnerGradient.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
SpinnerGradient.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(0.75, 0.95),
    NumberSequenceKeypoint.new(1, 0),
})
SpinnerGradient.Parent = SpinnerStroke

task.spawn(function()
    while Spinner.Parent do
        if Spinner.Visible then
            SpinnerGradient.Rotation = (SpinnerGradient.Rotation + 8) % 360
        end
        RunService.Heartbeat:Wait()
    end
end)

local function setVerifying(active)
    Spinner.Visible = active
    VerifyLabel.Visible = not active
    ChevronWrap.Visible = not active
end

task.spawn(function()
    while VerifyShine.Parent do
        VerifyShineGradient.Offset = Vector2.new(-1, 0)
        tw(VerifyShineGradient, TweenInfo.new(1.8, Enum.EasingStyle.Sine), { Offset = Vector2.new(1, 0) })
        task.wait(3.4)
    end
end)

VerifyBtn.MouseEnter:Connect(function()
    tw(VerifyScale, EASE_QUICK, { Scale = 1.02 })
    tw(ChevronWrap, EASE_QUICK, { Position = UDim2.new(0.5, 52, 0.5, 0) })
end)
VerifyBtn.MouseLeave:Connect(function()
    tw(VerifyScale, EASE_QUICK, { Scale = 1 })
    tw(ChevronWrap, EASE_QUICK, { Position = UDim2.new(0.5, 46, 0.5, 0) })
end)
VerifyBtn.MouseButton1Down:Connect(function() tw(VerifyScale, EASE_QUICK, { Scale = 0.96 }) end)
VerifyBtn.MouseButton1Up:Connect(function() tw(VerifyScale, EASE_SPRING, { Scale = 1 }) end)

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 18)
StatusLabel.LayoutOrder = 3
StatusLabel.BackgroundTransparency = 1
StatusLabel.TextColor3 = Theme.TextTertiary
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready"
StatusLabel.ZIndex = 7
StatusLabel.Parent = Content

local function setStatus(text, color)
    tw(StatusLabel, EASE_QUICK, { TextTransparency = 1 })
    task.delay(0.12, function()
        StatusLabel.Text = text
        StatusLabel.TextColor3 = color or Theme.TextTertiary
        tw(StatusLabel, EASE_QUICK, { TextTransparency = 0 })
    end)
end

local ValidateKey

local FloatingRow = Instance.new("Frame")
FloatingRow.Name = "FloatingRow"
FloatingRow.Size = UDim2.new(1, 0, 0, 108)
FloatingRow.LayoutOrder = 4
FloatingRow.BackgroundTransparency = 1
FloatingRow.ZIndex = 7
FloatingRow.Parent = Content

local FloatingLayout = Instance.new("UIListLayout")
FloatingLayout.FillDirection = Enum.FillDirection.Horizontal
FloatingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
FloatingLayout.VerticalAlignment = Enum.VerticalAlignment.Top
FloatingLayout.Padding = UDim.new(0, 22)
FloatingLayout.SortOrder = Enum.SortOrder.LayoutOrder
FloatingLayout.Parent = FloatingRow

local function CreateFloatingButton(order, iconBuilder, iconColor, label, copyText)
    local wrap = Instance.new("Frame")
    wrap.Name = label
    wrap.Size = UDim2.fromOffset(92, 108)
    wrap.LayoutOrder = order
    wrap.BackgroundTransparency = 1
    wrap.ZIndex = 7
    wrap.Parent = FloatingRow

    local glow = Instance.new("Frame")
    glow.Size = UDim2.fromOffset(90, 90)
    glow.Position = UDim2.new(0.5, 0, 0, 30)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundColor3 = iconColor
    glow.BackgroundTransparency = 0.88
    glow.BorderSizePixel = 0
    glow.ZIndex = 6
    glow.Parent = wrap
    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(1, 0)
    glowCorner.Parent = glow
    task.spawn(function()
        task.wait(math.random() * 2)
        while glow.Parent do
            tw(glow, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.72 })
            task.wait(2.4)
            tw(glow, TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { BackgroundTransparency = 0.88 })
            task.wait(2.4)
        end
    end)

    local toast = Instance.new("TextLabel")
    toast.Size = UDim2.new(1, 20, 0, 20)
    toast.Position = UDim2.new(0.5, 0, 0, -6)
    toast.AnchorPoint = Vector2.new(0.5, 1)
    toast.BackgroundTransparency = 1
    toast.Text = "Copied!"
    toast.TextColor3 = Theme.Success
    toast.Font = Enum.Font.GothamBold
    toast.TextSize = 12
    toast.TextTransparency = 1
    toast.ZIndex = 9
    toast.Parent = wrap

    local circle = Instance.new("TextButton")
    circle.Name = "Circle"
    circle.Size = UDim2.fromOffset(60, 60)
    circle.Position = UDim2.new(0.5, 0, 0, 0)
    circle.AnchorPoint = Vector2.new(0.5, 0)
    circle.BackgroundColor3 = Theme.GlassCardAlt
    circle.BackgroundTransparency = 0.28
    circle.AutoButtonColor = false
    circle.Text = ""
    circle.ZIndex = 7
    circle.Parent = wrap

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle

    local circleStroke = Instance.new("UIStroke")
    circleStroke.Thickness = 1.3
    circleStroke.Color = iconColor
    circleStroke.Transparency = 0.55
    circleStroke.Parent = circle

    local circleGlow = Instance.new("Frame")
    circleGlow.Size = UDim2.fromScale(1, 1)
    circleGlow.BackgroundColor3 = iconColor
    circleGlow.BackgroundTransparency = 0.82
    circleGlow.ZIndex = 6
    circleGlow.Parent = circle
    local glowCorner2 = Instance.new("UICorner")
    glowCorner2.CornerRadius = UDim.new(1, 0)
    glowCorner2.Parent = circleGlow

    local scale = Instance.new("UIScale")
    scale.Parent = circle

    iconBuilder(circle, iconColor)

    local caption = Instance.new("TextLabel")
    caption.Size = UDim2.new(1, 10, 0, 30)
    caption.Position = UDim2.new(0.5, 0, 0, 68)
    caption.AnchorPoint = Vector2.new(0.5, 0)
    caption.BackgroundTransparency = 1
    caption.Text = label
    caption.TextColor3 = Theme.TextSecondary
    caption.TextWrapped = true
    caption.Font = Enum.Font.GothamMedium
    caption.TextSize = 11
    caption.ZIndex = 7
    caption.Parent = wrap

    local phase = math.random() * 6.28
    task.spawn(function()
        local t0 = tick()
        while wrap.Parent do
            local t = tick() - t0
            wrap.Position = UDim2.new(wrap.Position.X.Scale, wrap.Position.X.Offset, 0, math.sin(t * 0.9 + phase) * 3)
            RunService.Heartbeat:Wait()
        end
    end)

    circle.MouseEnter:Connect(function()
        tw(scale, EASE_QUICK, { Scale = 1.12 })
        tw(circleStroke, EASE_QUICK, { Transparency = 0.2 })
        tw(glow, EASE_QUICK, { BackgroundTransparency = 0.72 })
    end)
    circle.MouseLeave:Connect(function()
        tw(scale, EASE_QUICK, { Scale = 1 })
        tw(circleStroke, EASE_QUICK, { Transparency = 0.55 })
        tw(glow, EASE_QUICK, { BackgroundTransparency = 0.88 })
    end)
    circle.MouseButton1Down:Connect(function() tw(scale, EASE_QUICK, { Scale = 0.92 }) end)
    circle.MouseButton1Up:Connect(function() tw(scale, EASE_SPRING, { Scale = 1.08 }) end)
    circle.MouseButton1Click:Connect(function()
        pcall(function() setclipboard(copyText) end)
        tw(toast, EASE_QUICK, { TextTransparency = 0 })
        task.delay(1.5, function()
            tw(toast, EASE_QUICK, { TextTransparency = 1 })
        end)
    end)
end

CreateFloatingButton(1, IconChat, Theme.Discord, "Discord\n(dupe)", "https://discord.gg/ivoryhub")
CreateFloatingButton(2, IconWorkMark, Theme.WorkInkTeal, "Work.ink\nKey", "https://work.ink/ivorykey")
CreateFloatingButton(3, IconLootGem, Theme.LootPurple, "LootLabs\nKey", "https://loot-link.com/s?L6z5Q0nE")

-- ===============================================================
-- KEY VALIDATION
-- ===============================================================
local _awaiting = true

local function _doValidate(key)
    if _k and _k.v and _k.i and _verifyIntegrity() then
        if _k.s == key then
            setStatus("Key already verified", Theme.Success)
            return true
        end
    end

    setVerifying(true)
    setStatus("Verifying...", Theme.AccentA)

    if _lootKey ~= "" and key == _lootKey then
        _k.v = true
        _k.s = key
        _k.h = _hwid
        _k.t = os.time()
        _k.i = 0x4A + #key
        setVerifying(false)
        setStatus("Verified (LootLabs)!", Theme.Success)
        task.delay(1.5, function()
            _awaiting = false
        end)
        return true
    end

    local ok, result = pcall(function()
        return request({
            Url = "https://api.workink.net/v1/verify",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ key = key, hwid = _hwid })
        })
    end)

    if ok and result and result.StatusCode == 200 then
        local body = HttpService:JSONDecode(result.Body)
        if body and body.valid then
            _k.v = true
            _k.s = key
            _k.h = _hwid
            _k.t = os.time()
            _k.i = 0x4A + #key
            setVerifying(false)
            setStatus("Verified!", Theme.Success)
            task.delay(1.5, function()
                _awaiting = false
            end)
            return true
        end
    end

    setVerifying(false)
    setStatus("Invalid key", Theme.Error)
    return false
end

ValidateKey = function(key)
    _doValidate(key)
end

VerifyBtn.MouseButton1Click:Connect(function()
    local key = InputBox.Text:gsub("%s", "")
    if key ~= "" then
        ValidateKey(key)
    end
end)

-- ===============================================================
-- SAVE/LOAD KEY
-- ===============================================================
local SAVE_KEY = "IvoryHub_Key_v1"

local function saveKey(key)
    pcall(function()
        if writefile then
            writefile(SAVE_KEY, key)
        end
    end)
end

local function loadSavedKey()
    pcall(function()
        if readfile and isfile then
            if isfile(SAVE_KEY) then
                local key = readfile(SAVE_KEY)
                if key and key ~= "" then
                    InputBox.Text = key
                    _doValidate(key)
                end
            end
        end
    end)
end

task.spawn(function()
    task.wait(1)
    loadSavedKey()
end)

-- ===============================================================
-- CINEMATIC INTRO
-- ===============================================================
local function revealCard()
    CardHolder.Visible = true
    CardScale.Scale = 0.86
    tw(CardScale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
end

task.spawn(function()
    concealClouds(0)
    task.wait(0.3)
    revealCard()
    task.wait(0.5)
    revealClouds(1.1)
end)

-- ===============================================================
-- UNLOAD
-- ===============================================================
unloadUI = function()
    if _unloaded then return end
    _unloaded = true
    _awaiting = false

    fadeOutMusic()
    teardownBackdrop()

    task.delay(CURTAIN_EXIT_TOTAL, function()
        pcall(function() ScreenGui:Destroy() end)
        pcall(function() BackdropBlur:Destroy() end)
    end)
end

end -- close key system UI block

-- ===============================================================
-- GAME SCRIPT: Catch 1 Billion Ducks
-- ===============================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Wait for key verification
while _awaiting do task.wait(0.5) end
if not (_k and _k.v and _k.i) then return end

-- ===============================================================
-- UME NETWORK ACCESS
-- ===============================================================
local Value
pcall(function()
    Value = require(ReplicatedStorage:FindFirstChild("UmePointer").Value)
end)

if not Value then
    warn("[Ivory] Failed to load UmePointer")
    return
end

local Network = Value.Network

-- ===============================================================
-- CONFIG
-- ===============================================================
local cfg = {
    autoFarm = false,
    autoShoot = false,
    silentAim = false,
    killAura = false,
    killAuraRadius = 200,
    autoSell = false,
    autoBuyUpgrades = false,
    autoJoinGame = false,
    autoReturnLobby = false,
    rapidFire = false,
    autoTargetMadBirds = false,
    stayBehindSpawn = false,
    removeGameplayPaused = false,
    priorityUpgrade = "Damage",
}

-- ===============================================================
-- HELPER FUNCTIONS
-- ===============================================================
local function getChar()
    return LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local char = getChar()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getDucks()
    local ducks = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 and v.Name:lower():find("duck") then
                table.insert(ducks, v)
            end
        end
    end
    return ducks
end

local function getClosestDuck(radius)
    local _, hrp = getChar()
    if not hrp then return nil end
    local closest, dist = nil, radius or math.huge
    for _, duck in ipairs(getDucks()) do
        local root = duck:FindFirstChild("HumanoidRootPart")
        if root then
            local d = (root.Position - hrp.Position).Magnitude
            if d < dist then
                dist = d
                closest = duck
            end
        end
    end
    return closest, dist
end

local function isMadBird(duck)
    local name = duck.Name:lower()
    return name:find("angry") or name:find("mad") or name:find("frenzy") or name:find("boss")
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

local MainTab = Window:AddTab({ Name = "Main", Icon = "crosshair", Description = "Auto Farm & Combat" })
local UpgradeTab = Window:AddTab({ Name = "Upgrades", Icon = "arrow-up-circle", Description = "Auto Upgrades" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Themes & UI" })

-- ===============================================================
-- MAIN TAB
-- ===============================================================
local CombatSub = MainTab:AddSubTab({ Name = "Combat", Icon = "swords" })
local MiscSub = MainTab:AddSubTab({ Name = "Misc", Icon = "zap" })

local CombatBox = CombatSub:AddLeftGroupbox("Combat", "crosshair")
CombatBox:AddToggle("AutoFarm", { Text = "Auto Farm (Full)", Default = false, Tooltip = "Shoots ducks automatically" })
CombatBox:AddToggle("KillAura", { Text = "Kill Aura", Default = false, Tooltip = "Auto-shoot ducks in radius" })
CombatBox:AddSlider("KillAuraRadius", { Text = "Kill Aura Radius", Default = 200, Min = 50, Max = 1000, Rounding = 0, Suffix = " studs" })
CombatBox:AddToggle("SilentAim", { Text = "Silent Aim", Default = false, Tooltip = "Bullets hit ducks directly" })
CombatBox:AddToggle("AutoTargetMadBirds", { Text = "Target Mad/Boss Birds", Default = false, Tooltip = "Prioritize angry/boss ducks" })
CombatBox:AddToggle("RapidFire", { Text = "Rapid Fire", Default = false, Tooltip = "Faster shooting (may not work)" })

local PositionBox = CombatSub:AddRightGroupbox("Positioning", "map-pin")
PositionBox:AddToggle("StayBehindSpawn", { Text = "Behind Duck Spawn", Default = false, Tooltip = "Stay behind duck spawn for safety" })

local SellBox = MiscSub:AddLeftGroupbox("Economy", "dollar-sign")
SellBox:AddToggle("AutoSell", { Text = "Auto Sell Ducks", Default = false })

local QueueBox = MiscSub:AddRightGroupbox("Queue", "play")
QueueBox:AddToggle("AutoJoinGame", { Text = "Auto Join Game", Default = false, Tooltip = "Auto queue when in lobby" })
QueueBox:AddToggle("AutoReturnLobby", { Text = "Auto Return to Lobby", Default = false, Tooltip = "Return to lobby when game ends" })

-- ===============================================================
-- UPGRADES TAB
-- ===============================================================
local UpgradesSub = UpgradeTab:AddSubTab({ Name = "Upgrades", Icon = "trending-up" })
local UpgradeBox = UpgradesSub:AddLeftGroupbox("Auto Upgrades", "arrow-up-circle")
UpgradeBox:AddToggle("AutoBuyUpgrades", { Text = "Auto Buy Upgrades", Default = false })
UpgradeBox:AddDropdown("PriorityUpgrade", {
    Values = { "Damage", "Pellet Count", "Reload Speed", "Spawn Rate", "Luck", "Dog Speed", "Dog Capacity", "Dog Dexterity" },
    Default = "Damage",
    Text = "Priority Upgrade",
    Tooltip = "Which upgrade to buy first",
})

-- ===============================================================
-- ONCHANGED HANDLERS
-- ===============================================================
Toggles.AutoFarm:OnChanged(function(s) cfg.autoFarm = s end)
Toggles.KillAura:OnChanged(function(s) cfg.killAura = s end)
Options.KillAuraRadius:OnChanged(function(v) cfg.killAuraRadius = v end)
Toggles.SilentAim:OnChanged(function(s) cfg.silentAim = s end)
Toggles.AutoTargetMadBirds:OnChanged(function(s) cfg.autoTargetMadBirds = s end)
Toggles.RapidFire:OnChanged(function(s) cfg.rapidFire = s end)
Toggles.StayBehindSpawn:OnChanged(function(s) cfg.stayBehindSpawn = s end)
Toggles.AutoSell:OnChanged(function(s) cfg.autoSell = s end)
Toggles.AutoJoinGame:OnChanged(function(s) cfg.autoJoinGame = s end)
Toggles.AutoReturnLobby:OnChanged(function(s) cfg.autoReturnLobby = s end)
Toggles.AutoBuyUpgrades:OnChanged(function(s) cfg.autoBuyUpgrades = s end)
Options.PriorityUpgrade:OnChanged(function(v) cfg.priorityUpgrade = v end)

-- ===============================================================
-- AUTO FARM LOOP
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoFarm and _k and _k.v and _verifyIntegrity() then
            local char, hrp = getChar()
            if char and hrp then
                local target = nil

                if cfg.autoTargetMadBirds then
                    for _, duck in ipairs(getDucks()) do
                        if isMadBird(duck) then
                            target = duck
                            break
                        end
                    end
                end

                if not target then
                    target = getClosestDuck(cfg.killAuraRadius)
                end

                if target then
                    local root = target:FindFirstChild("HumanoidRootPart")
                    if root then
                        if cfg.stayBehindSpawn then
                            local spawnPos = workspace.Ume and workspace.Ume:FindFirstChild("BaseSpawn")
                            if spawnPos then
                                local behindPos = spawnPos.CFrame * CFrame.new(0, 0, -20)
                                hrp.CFrame = behindPos
                            end
                        end

                        if cfg.silentAim then
                            hrp.CFrame = CFrame.new(hrp.Position, root.Position)
                        end
                    end
                end
            end
        end
        task.wait(0.1)
    end
end)

-- ===============================================================
-- KILL AURA LOOP
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.killAura and _k and _k.v and _verifyIntegrity() then
            local _, hrp = getChar()
            if hrp then
                for _, duck in ipairs(getDucks()) do
                    local root = duck:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - hrp.Position).Magnitude
                        if dist <= cfg.killAuraRadius then
                            pcall(function()
                                local hum = duck:FindFirstChildOfClass("Humanoid")
                                if hum then
                                    hum.Health = 0
                                end
                            end)
                        end
                    end
                end
            end
        end
        task.wait(0.2)
    end
end)

-- ===============================================================
-- AUTO SELL LOOP
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoSell and _k and _k.v and _verifyIntegrity() then
            pcall(function()
                local freezer = workspace.Ume and workspace.Ume:FindFirstChild("Components") and workspace.Ume.Components:FindFirstChild("FreezerPart")
                if freezer then
                    local prompt = freezer:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        local _, hrp = getChar()
                        if hrp then
                            hrp.CFrame = freezer.CFrame + Vector3.new(0, 3, 0)
                            task.wait(0.3)
                            fireproximityprompt(prompt)
                        end
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

-- ===============================================================
-- AUTO JOIN GAME LOOP
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoJoinGame and _k and _k.v and _verifyIntegrity() then
            local mapId = Value and Value.Config and Value.Config.PlaceLoader and Value.Config.PlaceLoader.MapId
            if mapId == "Game_Lobby" then
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
        end
        task.wait(10)
    end
end)

-- ===============================================================
-- AUTO RETURN TO LOBBY
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoReturnLobby and _k and _k.v and _verifyIntegrity() then
            pcall(function()
                Network.Fire("Respawn_Controller_ReturnToLobby")
            end)
        end
        task.wait(30)
    end
end)

-- ===============================================================
-- AUTO BUY UPGRADES
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.autoBuyUpgrades and _k and _k.v and _verifyIntegrity() then
            pcall(function()
                local upgradesGui = LocalPlayer.PlayerGui:FindFirstChild("Upgrades")
                if upgradesGui then
                    for _, v in ipairs(upgradesGui:GetDescendants()) do
                        if v:IsA("TextButton") and v.Text:find("$") then
                            local price = tonumber(v.Text:match("%$(%d+)"))
                            if price then
                                local coins = LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Coins")
                                if coins and coins.Value >= price then
                                    -- Click the upgrade button
                                    for _, btn in ipairs(v.Parent:GetDescendants()) do
                                        if btn:IsA("TextButton") and btn.Text:find("Upgrade") then
                                            -- Trigger the button
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
        end
        task.wait(5)
    end
end)

-- ===============================================================
-- REMOVE GAMEPLAY PAUSED
-- ===============================================================
task.spawn(function()
    while true do
        if cfg.removeGameplayPaused and _k and _k.v and _verifyIntegrity() then
            pcall(function()
                local pauseGui = LocalPlayer.PlayerGui:FindFirstChild("GameplayPaused")
                if pauseGui then
                    pauseGui:Destroy()
                end
            end)
        end
        task.wait(1)
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
