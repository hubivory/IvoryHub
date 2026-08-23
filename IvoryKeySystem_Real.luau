-- ===============================================================
-- IVORY HUB - KEY SYSTEM UI  (Real executor optimized)
-- "Liquid Glass - Sakura" edition
-- Changes vs original:
--   * game:HttpGet → request() (Real has no HttpGet)
--   * getgenv() captured once at top
--   * debug wrapper logs every major step + pcall failures
--   * integrity check removed (executor-only, no anticheat value)
-- ===============================================================

-- ===============================================================
-- DEBUG HELPER
-- ===============================================================
local DEBUG = true
local function dbg(fmt, ...)
    if not DEBUG then return end
    local msg = "[IvoryDBG] " .. string.format(fmt, ...)
    print(msg)
end

local function dbgWarn(fmt, ...)
    local msg = "[IvoryDBG WARN] " .. string.format(fmt, ...)
    warn(msg)
end

local function dbgPcall(tag, fn, ...)
    local args = { ... }
    local ok, err = xpcall(function()
        return fn(unpack(args))
    end, function(e)
        return debug.traceback(tostring(e), 2)
    end)
    if not ok then
        dbgWarn("%s FAILED: %s", tag, tostring(err))
    end
    return ok, err
end

dbg("Script chunk entered")

-- ===============================================================
-- KEY SYSTEM
-- ===============================================================
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = ""
pcall(function() _hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
if _hwid == "" then _hwid = HttpService:JSONEncode({Players.LocalPlayer.UserId, math.random(1,999999)}) end
dbg("HWID generated: %s", _hwid)

-- ===============================================================
-- CAPTURE GETGENV ONCE (Real caveat: two calls may return
-- different table identities)
-- ===============================================================
local genv = getgenv()
dbg("getgenv captured")

-- ===============================================================
-- SERVICES
-- ===============================================================
local TweenService    = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService      = game:GetService("RunService")
local Lighting        = game:GetService("Lighting")
local HttpService     = game:GetService("HttpService")
local Players         = game:GetService("Players")
local SoundService    = game:GetService("SoundService")
local Camera          = workspace.CurrentCamera
dbg("Services loaded")

-- ===============================================================
-- EMBEDDED LOOTLABS KEY
-- ===============================================================
local _lootKey = ""
do
    local _s = 0x5A
    local _b = {19,12,21,8,3,119,25,14,28,21,119,111,15,98,104,119,25,11,16,3,119,24,111,15,110}
    local _c = {}
    for _i = 1, #_b do _c[_i] = string.char(_b[_i] ~ _s) end
    _lootKey = table.concat(_c)
end
dbg("LootKey assembled (len=%d)", #_lootKey)

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

dbg("Icon builders defined")

-- ===============================================================
-- ROOT SCREENGUI
-- ===============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IvoryKey"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 9999
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local guiOk = pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not guiOk or not ScreenGui.Parent then
    dbg("CoreGui parent failed, falling back to PlayerGui")
    ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end
dbg("ScreenGui parented to: %s", ScreenGui.Parent and ScreenGui.Parent:GetFullName() or "nil")

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

-- Ambient aura glow
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

-- Light-ray burst
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

dbg("Backdrop + clouds + rays built")

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
dbg("Petal fields created")

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

-- Liquid animated blob accents
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

-- Frosted sheen sweep
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

dbg("Card + blobs + sheen built")

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

-- Drag logic
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

-- Unload button
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

-- Pulsing glow ring
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

-- Central logo orb
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

-- Idle float
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

-- Shimmering rotation
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

-- Sparkle accents
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

dbg("Top region built")

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

-- Glass pill input
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

-- Verify button
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

-- Spinner
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

-- Status row
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

dbg("Content column built")

-- Forward declaration (defined later in KEY VALIDATION section)
local ValidateKey

-- ===============================================================
-- 3 FLOATING PROVIDER BUTTONS
-- ===============================================================
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
        while circle.Parent do
            local t = tick() - t0
            local bob = math.sin(t * 1.3 + phase) * 5
            circle.Position = UDim2.new(0.5, 0, 0, bob)
            glow.Position = UDim2.new(0.5, 0, 0, 30 + bob)
            RunService.Heartbeat:Wait()
        end
    end)

    circle.MouseEnter:Connect(function()
        tw(circle, EASE_QUICK, { BackgroundTransparency = 0.1 })
        tw(circleStroke, EASE_QUICK, { Transparency = 0.15 })
        tw(scale, EASE_QUICK, { Scale = 1.08 })
    end)
    circle.MouseLeave:Connect(function()
        tw(circle, EASE_QUICK, { BackgroundTransparency = 0.28 })
        tw(circleStroke, EASE_QUICK, { Transparency = 0.55 })
        tw(scale, EASE_QUICK, { Scale = 1 })
    end)
    circle.MouseButton1Down:Connect(function() tw(scale, EASE_QUICK, { Scale = 0.92 }) end)
    circle.MouseButton1Up:Connect(function() tw(scale, EASE_SPRING, { Scale = 1.08 }) end)

    circle.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(copyText) end)
        if ok then
            toast.Text = "Copied!"
            toast.TextColor3 = Theme.Success
        else
            toast.Text = "Link ready"
            toast.TextColor3 = Theme.Blue
        end
        tw(toast, EASE_OUT_SOFT, { TextTransparency = 0, Position = UDim2.new(0.5, 0, 0, -14) })
        task.delay(1.3, function()
            tw(toast, EASE_OUT_SOFT, { TextTransparency = 1, Position = UDim2.new(0.5, 0, 0, -6) })
        end)
        if not ok then
            setStatus("Link: " .. copyText, Theme.Blue)
            task.delay(3, function() setStatus("Ready", Theme.TextTertiary) end)
        end
    end)

    return wrap
end

CreateFloatingButton(1, IconChat, Theme.Discord, "Discord\n(dupe)", "https://discord.gg/mrQFkCJfEe")
CreateFloatingButton(2, IconWorkMark, Theme.WorkInkTeal, "Work.ink\nKey", "https://work.ink/2STL/Ivory")
CreateFloatingButton(3, function(parent, color) IconLootGem(parent, color, Theme.LootGold) end,
    Theme.LootPurple, "LootLabs\nKey", "https://loot-link.com/s?L6z5Q0nE")

dbg("Floating buttons built")

-- Footer
local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 14)
Footer.LayoutOrder = 5
Footer.BackgroundTransparency = 1
Footer.TextColor3 = Theme.TextTertiary
Footer.TextSize = 10
Footer.Font = Enum.Font.Gotham
Footer.Text = "IVORY HUB  -  v1.4"
Footer.ZIndex = 7
Footer.Parent = Content

-- ===============================================================
-- CARD REVEAL / CLOSE / UNLOAD
-- ===============================================================
local function revealCard()
    CardHolder.Visible = true
    tw(CardScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
    dbg("Card revealed")
end

local function closeUI(delay)
    task.delay(delay or 0, function()
        dbg("closeUI called (delay=%s)", tostring(delay))
        tw(CardScale, EASE_OUT_SOFT, { Scale = 0.85 })
        tw(Card, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
        teardownBackdrop()
        fadeOutMusic()
        task.wait(CURTAIN_EXIT_TOTAL)
        pcall(function() ScreenGui:Destroy() end)
        dbg("ScreenGui destroyed (closeUI)")
    end)
end

unloadUI = function()
    if _unloaded then return end
    _unloaded = true
    dbg("unloadUI called")
    setStatus("Unloaded", Theme.Error)
    tw(CardScale, EASE_OUT_SOFT, { Scale = 0.8 })
    tw(Card, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    teardownBackdrop()
    fadeOutMusic()
    task.wait(CURTAIN_EXIT_TOTAL)
    pcall(function() ScreenGui:Destroy() end)
    dbg("ScreenGui destroyed (unloadUI)")
end

-- ===============================================================
-- CINEMATIC INTRO
-- ===============================================================
local introSkip = false

local Intro = Instance.new("TextButton")
Intro.Name = "Intro"
Intro.Size = UDim2.fromScale(1, 1)
Intro.BackgroundTransparency = 1
Intro.AutoButtonColor = false
Intro.Text = ""
Intro.ZIndex = 40
Intro.Parent = ScreenGui
Intro.MouseButton1Click:Connect(function() introSkip = true end)

local IntroLogo = Instance.new("Frame")
IntroLogo.AnchorPoint = Vector2.new(0.5, 0.5)
IntroLogo.Position = UDim2.fromScale(0.5, 0.36)
IntroLogo.Size = UDim2.fromOffset(84, 84)
IntroLogo.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
IntroLogo.BackgroundTransparency = 1
IntroLogo.ZIndex = 41
IntroLogo.Parent = Intro
local IntroLogoCorner = Instance.new("UICorner")
IntroLogoCorner.CornerRadius = UDim.new(1, 0)
IntroLogoCorner.Parent = IntroLogo
local IntroLogoGradient = Instance.new("UIGradient")
IntroLogoGradient.Rotation = 45
IntroLogoGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentA),
    ColorSequenceKeypoint.new(0.5, Theme.AccentC),
    ColorSequenceKeypoint.new(1, Theme.AccentB),
})
IntroLogoGradient.Parent = IntroLogo
local IntroLogoStroke = Instance.new("UIStroke")
IntroLogoStroke.Thickness = 1.5
IntroLogoStroke.Color = Color3.fromRGB(255, 255, 255)
IntroLogoStroke.Transparency = 1
IntroLogoStroke.Parent = IntroLogo
local IntroLogoScale = Instance.new("UIScale")
IntroLogoScale.Scale = 0.5
IntroLogoScale.Parent = IntroLogo
local introGem = IconDiamondMark(IntroLogo, Color3.fromRGB(255, 255, 255), 34)
introGem.BackgroundTransparency = 1

local IntroTitle = Instance.new("TextLabel")
IntroTitle.Size = UDim2.new(0, 560, 0, 44)
IntroTitle.Position = UDim2.fromScale(0.5, 0.48)
IntroTitle.AnchorPoint = Vector2.new(0.5, 0.5)
IntroTitle.BackgroundTransparency = 1
IntroTitle.TextColor3 = Theme.TextPrimary
IntroTitle.TextSize = 36
IntroTitle.Font = Enum.Font.GothamBold
IntroTitle.Text = ""
IntroTitle.ZIndex = 41
IntroTitle.Parent = Intro

local IntroCredit = Instance.new("TextLabel")
IntroCredit.Size = UDim2.new(0, 560, 0, 20)
IntroCredit.Position = UDim2.fromScale(0.5, 0.565)
IntroCredit.AnchorPoint = Vector2.new(0.5, 0.5)
IntroCredit.BackgroundTransparency = 1
IntroCredit.TextColor3 = Theme.TextTertiary
IntroCredit.TextSize = 14
IntroCredit.Font = Enum.Font.Gotham
IntroCredit.Text = ""
IntroCredit.ZIndex = 41
IntroCredit.Parent = Intro

local BarTrack = Instance.new("Frame")
BarTrack.Size = UDim2.fromOffset(240, 3)
BarTrack.Position = UDim2.fromScale(0.5, 0.66)
BarTrack.AnchorPoint = Vector2.new(0.5, 0.5)
BarTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarTrack.BackgroundTransparency = 0.88
BarTrack.BorderSizePixel = 0
BarTrack.ZIndex = 41
BarTrack.Parent = Intro
local BarTrackCorner = Instance.new("UICorner")
BarTrackCorner.CornerRadius = UDim.new(1, 0)
BarTrackCorner.Parent = BarTrack

local BarFill = Instance.new("Frame")
BarFill.Size = UDim2.new(0, 0, 1, 0)
BarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
BarFill.BorderSizePixel = 0
BarFill.ZIndex = 42
BarFill.Parent = BarTrack
local BarFillCorner = Instance.new("UICorner")
BarFillCorner.CornerRadius = UDim.new(1, 0)
BarFillCorner.Parent = BarFill
local BarFillGradient = Instance.new("UIGradient")
BarFillGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Theme.AccentA),
    ColorSequenceKeypoint.new(0.5, Theme.AccentC),
    ColorSequenceKeypoint.new(1, Theme.AccentB),
})
BarFillGradient.Parent = BarFill

local BarLabel = Instance.new("TextLabel")
BarLabel.Size = UDim2.fromOffset(240, 16)
BarLabel.Position = UDim2.fromScale(0.5, 0.705)
BarLabel.AnchorPoint = Vector2.new(0.5, 0.5)
BarLabel.BackgroundTransparency = 1
BarLabel.TextColor3 = Theme.TextTertiary
BarLabel.TextSize = 11
BarLabel.Font = Enum.Font.Gotham
BarLabel.Text = ""
BarLabel.ZIndex = 41
BarLabel.Parent = Intro

local SkipHint = Instance.new("TextLabel")
SkipHint.Size = UDim2.fromOffset(200, 16)
SkipHint.Position = UDim2.new(0.5, 0, 1, -36)
SkipHint.AnchorPoint = Vector2.new(0.5, 1)
SkipHint.BackgroundTransparency = 1
SkipHint.TextColor3 = Theme.TextTertiary
SkipHint.TextSize = 11
SkipHint.Font = Enum.Font.Gotham
SkipHint.Text = "tap anywhere to skip"
SkipHint.TextTransparency = 1
SkipHint.ZIndex = 41
SkipHint.Parent = Intro
tw(SkipHint, TweenInfo.new(0.6), { TextTransparency = 0.55 })

local function typeText(label, text, charDelay)
    for i = 1, #text do
        if introSkip then
            label.Text = text
            return
        end
        label.Text = string.sub(text, 1, i)
        task.wait(charDelay)
    end
end

local function skippableWait(duration)
    local elapsed = 0
    while elapsed < duration and not introSkip do
        elapsed = elapsed + task.wait(0.05)
    end
end

local function finishIntro()
    dbg("finishIntro called")
    tw(IntroLogo, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    tw(introGem, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    tw(IntroLogoStroke, EASE_OUT_SOFT, { Transparency = 1 })
    tw(IntroTitle, EASE_OUT_SOFT, { TextTransparency = 1 })
    tw(IntroCredit, EASE_OUT_SOFT, { TextTransparency = 1 })
    tw(BarTrack, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    tw(BarFill, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    tw(BarLabel, EASE_OUT_SOFT, { TextTransparency = 1 })
    tw(SkipHint, EASE_OUT_SOFT, { TextTransparency = 1 })
    concealClouds(0.65)
    task.wait(0.85)
    pcall(function() Intro:Destroy() end)
    revealCard()
end

task.spawn(function()
    dbg("Intro cinematic starting")
    task.wait(0.2)
    revealClouds(1.15)

    tw(IntroLogo, EASE_OUT_SOFT, { BackgroundTransparency = 0 })
    tw(introGem, EASE_OUT_SOFT, { BackgroundTransparency = 0 })
    tw(IntroLogoStroke, EASE_OUT_SOFT, { Transparency = 0.4 })
    tw(IntroLogoScale, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
    skippableWait(0.55)
    if introSkip then finishIntro() return end

    typeText(IntroTitle, "I V O R Y   H U B", 0.035)
    skippableWait(0.25)
    if introSkip then finishIntro() return end

    typeText(IntroCredit, "built by FakeCrow & Veqxo", 0.032)
    skippableWait(0.45)
    if introSkip then finishIntro() return end

    BarLabel.Text = "Loading assets..."
    tw(BarFill, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0.6, 0, 1, 0) })
    skippableWait(1.1)
    if introSkip then finishIntro() return end

    BarLabel.Text = "Preparing interface..."
    tw(BarFill, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(0.9, 0, 1, 0) })
    skippableWait(0.7)
    if introSkip then finishIntro() return end

    BarLabel.Text = "Ready"
    tw(BarFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0) })
    skippableWait(0.55)

    finishIntro()
end)

dbg("Intro elements built")

-- ===============================================================
-- KEY VALIDATION  (uses request() instead of game:HttpGet for Real)
-- ===============================================================
local isVerifying = false

ValidateKey = function(key)
    if isVerifying or _unloaded then return end
    isVerifying = true
    setVerifying(true)
    dbg("ValidateKey called (key len=%d)", #key)

    setStatus("Checking key...", Theme.TextTertiary)

    -- LootLabs exact match
    if _lootKey ~= "" and key == _lootKey then
        dbg("LootLabs key matched")
        _k.v = true
        _k.s = key
        _k.h = _hwid
        _k.t = os.time()
        _k.i = 0x4A + #key

        dbgPcall("setgenv-loot", function()
            genv._ivoryKey = key
            genv._ivoryExpiry = os.time() * 1000 + 43200000
        end)
        dbgPcall("writefile-loot", function()
            writefile("IvoryKey.txt", key .. "\n" .. tostring(os.time() * 1000 + 43200000) .. "\n" .. _hwid)
        end)

        setStatus("Access granted: " .. key, Theme.Success)
        setVerifying(false)
        VerifyLabel.Text = "Close"
        VerifyBtn.MouseButton1Click:Connect(function() closeUI(0) end)
        isVerifying = false
        return
    end

    -- Work.ink API validation
    -- FIX: Real has no game:HttpGet(); use request() instead
    dbg("Calling Work.ink API for key validation")
    local httpOk, httpRes = pcall(function()
        return request({
            Url = "https://work.ink/_api/v2/token/isValid/" .. key .. "?deleteToken=1",
            Method = "GET",
        })
    end)

    if not httpOk then
        dbgWarn("HTTP request failed: %s", tostring(httpRes))
        setStatus("Network error - try again", Theme.Error)
        setVerifying(false)
        isVerifying = false
        return
    end

    dbg("HTTP response: status=%s, body=%s",
        tostring(httpRes and httpRes.StatusCode),
        tostring(httpRes and httpRes.Body and httpRes.Body:sub(1, 200) or "nil"))

    local handled = false
    if httpOk and httpRes and httpRes.Body then
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(httpRes.Body)
        end)

        if not decodeOk then
            dbgWarn("JSON decode failed: %s", tostring(data))
        elseif data and data.valid then
            dbg("Work.ink key valid")
            handled = true
            _k.v = true
            _k.s = key
            _k.h = _hwid
            _k.t = os.time()
            _k.i = 0x4A + #key

            local expiry = data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)
            dbgPcall("setgenv-workink", function()
                genv._ivoryKey = key
                genv._ivoryExpiry = expiry
            end)
            dbgPcall("writefile-workink", function()
                writefile("IvoryKey.txt", key .. "\n" .. tostring(expiry) .. "\n" .. _hwid)
            end)

            setStatus("Access granted: " .. key, Theme.Success)
            setVerifying(false)
            VerifyLabel.Text = "Close"
            VerifyBtn.MouseButton1Click:Connect(function() closeUI(0) end)
        else
            dbg("Work.ink response: valid=%s", tostring(data and data.valid))
        end
    end

    if not handled then
        dbg("Key validation failed - no match")
        setStatus("Invalid key - get one at work.ink/2STL/Ivory", Theme.Error)
        setVerifying(false)
        VerifyLabel.Text = "Verify Key"
        tw(InputStroke, EASE_QUICK, { Color = Theme.Error, Transparency = 0.2 })
        task.wait(0.4)
        tw(InputStroke, EASE_OUT_SOFT, { Color = Color3.fromRGB(255,255,255), Transparency = 0.82 })
    end

    isVerifying = false
end

VerifyBtn.MouseButton1Click:Connect(function()
    local key = InputBox.Text:gsub("%s", "")
    if key ~= "" then
        ValidateKey(key)
    else
        setStatus("Please enter a key", Theme.Error)
        tw(InputStroke, EASE_QUICK, { Color = Theme.Error, Transparency = 0.2 })
        task.wait(0.4)
        tw(InputStroke, EASE_OUT_SOFT, { Color = Color3.fromRGB(255,255,255), Transparency = 0.82 })
    end
end)

dbg("Key validation wired up")

-- ===============================================================
-- KEY PERSISTENCE
-- ===============================================================
local function CheckSavedKey()
    if _unloaded then return end
    dbg("CheckSavedKey running")
    local savedKey, savedExpiry, savedHwid = nil, nil, nil

    local readOk, readErr = pcall(function()
        if isfile("IvoryKey.txt") then
            local data = readfile("IvoryKey.txt")
            savedKey, savedExpiry, savedHwid = data:match("^(.-)\n(.-)\n?(.-)$")
            savedExpiry = tonumber(savedExpiry)
            if savedHwid == "" then savedHwid = nil end
            dbg("Read IvoryKey.txt: key=%s, expiry=%s, hwid=%s",
                savedKey and savedKey:sub(1,8) .. "..." or "nil",
                tostring(savedExpiry),
                savedHwid and savedHwid:sub(1,12) .. "..." or "nil")
        else
            dbg("No IvoryKey.txt found")
        end
    end)
    if not readOk then
        dbgWarn("readfile failed: %s", tostring(readErr))
    end

    if not savedKey then
        pcall(function() savedKey = genv._ivoryKey end)
        pcall(function() savedExpiry = genv._ivoryExpiry end)
        dbg("Checked genv: key=%s", savedKey and savedKey:sub(1,8) .. "..." or "nil")
    end

    if savedKey and savedExpiry and os.time() * 1000 < savedExpiry then
        if savedHwid and savedHwid ~= _hwid then
            dbgWarn("HWID mismatch: saved=%s, current=%s", tostring(savedHwid), tostring(_hwid))
            pcall(function() delfile("IvoryKey.txt") end)
            setStatus("Key bound to another device", Theme.Error)
        else
            dbg("Saved key still valid, restoring")
            _k.v = true
            _k.s = savedKey
            _k.h = _hwid
            _k.t = os.time()
            _k.i = 0x4A + #savedKey

            setStatus("Welcome back: " .. savedKey, Theme.Success)
            setVerifying(false)
            VerifyLabel.Text = "Close"
            VerifyBtn.MouseButton1Click:Connect(function() closeUI(0) end)
        end
    else
        dbg("No valid saved key (expiry check: saved=%s, now=%s)",
            tostring(savedExpiry), tostring(os.time() * 1000))
    end
end

task.delay(0.25, CheckSavedKey)

-- ===============================================================
-- WAITING LOOP
-- ===============================================================
dbg("Entering waiting loop")
local _awaiting = true
while _awaiting do
    task.wait(0.1)
    if _k and _k.v then
        dbg("Key validated - exiting loop")
        _awaiting = false
    end
    if _unloaded then
        dbg("Unloaded - exiting loop")
        _awaiting = false
    end
    if not ScreenGui.Parent then
        dbg("ScreenGui lost parent - exiting loop")
        _awaiting = false
    end
end

if _unloaded then
    print("Ivory Hub - unloaded by user, nothing further will run")
    return
end

dbg("Key system complete - proceeding")
print("Ivory Hub key system - liquid glass - sakura UI loaded")
