-- ===============================================================
-- IVORY HUB - KEY SYSTEM UI
-- "Liquid Glass - Sakura" edition
-- Central glowing logo, 3 floating buttons, falling sakura petals,
-- real backdrop blur, animated liquid gradient blobs, spring UI.
-- ===============================================================

-- ===============================================================
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ===============================================================
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = ""
pcall(function() _hwid = game:GetService("RbxAnalyticsService"):GetClientId() end)
if _hwid == "" then _hwid = game:GetService("HttpService"):JSONEncode({game.Players.LocalPlayer.UserId, math.random(1,999999)}) end
local _genv = getgenv()
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
    local _b = {19,12,21,8,3,119,20,11,98,25,119,9,13,111,18,119,105,28,99,13,119,24,25,2,10}
    local _c = {}
    for _i = 1, #_b do _c[_i] = string.char(bit32.bxor(_b[_i], _s)) end
    _lootKey = table.concat(_c)
end

-- ===============================================================
-- DESIGN TOKENS  (liquid glass / iOS-26 inspired palette + sakura accents)
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
-- Every icon is drawn from plain Frames/UIStroke/UIGradient - no
-- font glyphs, no Unicode, no missing-character "tofu boxes".
-- Each builder draws into `parent` (any size) centered via scale
-- anchors, so it drops cleanly into any container.
-- ===============================================================

-- small rounded-diamond brand mark (used for the central logo)
local function IconDiamondMark(parent, color, size)
    size = size or 30
    local dot = Color3.fromRGB(20, 18, 28)
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

-- chat-bubble glyph (Discord) - pill bubble + tail + three "typing" dots
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


-- Work.ink-inspired mark: a bold rounded "W" built from 4 diagonal bars,
-- meant to evoke their wordmark on their teal circle badge. Original
-- geometry (computed zigzag, not a traced copy of their exact letterform).
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

-- LootLabs-inspired mark: a two-tone faceted gem (purple body, gold
-- highlight facet) evoking their purple/gold palette without tracing
-- their actual isometric cube glyph.
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

-- small right-pointing chevron (two angled bars forming a ">") - returns
-- both bars so callers can slide/fade them for a hover micro-interaction
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

-- tiny left-aligned key icon (used inside the input field)
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

-- crossed-bar "x" mark (used for the unload button) - returns both bars so callers can recolor them
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

-- 4-point sparkle (two crossed bars) - returns both bars so callers can animate a twinkle
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

-- forward declarations - assigned once the full UI exists, but referenced by
-- handlers (unload button, music fade) that get wired up earlier in the file
local _unloaded = false
local unloadUI

-- -- large soft ambient aura glow drifting behind the whole card --
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

-- -- cloud curtain system --
-- Coverage and decoration are split into two completely separate layers:
--   - a solid opaque PANEL that is the only thing responsible for hiding
--     the game - it sweeps between fully covering the screen and fully
--     off-screen, so opacity is never in question.
--   - small decorative PUFFS that never move to "cover" anything; they
--     just sit at the screen edge, gently drifting, all the time. Their
--     only job is texture on top of the panel, so they stay small and few
--     enough to read as a soft accent instead of a wall of overlapping
--     circles (that muddy look was 15 puffs per side, up to 460px each,
--     spreading toward center - way too much translucent stacking).
local CLOUD_PALETTE = { Theme.AccentA, Theme.AccentB, Theme.AccentC, Theme.SakuraLight }

local function makeCloudCluster(side)
    local root = Instance.new("Frame")
    root.Name = "Cloud" .. side
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundTransparency = 1
    root.ZIndex = 2
    root.Parent = ScreenGui

    local state = { puffs = {} }

    -- solid opaque panel - the only thing that hides the game. Sized with
    -- generous overlap so both sides' panels meet with margin to spare,
    -- and slides fully off-screen once open.
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

    -- decorative edge puffs - small, few, permanently parked at the edge
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

    -- puffs drift continuously, independent of the panel's open/closed state
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

-- Sine is the gentlest easing curve Roblox offers - none of Quint's sharp
-- snap, which reads mechanical rather than like drifting cloud mass.
-- Only the solid panel moves here; the puffs have their own permanent
-- drift loop and are left alone.
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

-- how long the curtains take to fully open + dissolve away on exit - used
-- both here and by closeUI/unloadUI so the final ScreenGui:Destroy() never
-- cuts the animation off mid-flight
local CURTAIN_EXIT_OPEN = 0.9
local CURTAIN_EXIT_SETTLE = 0.4
local CURTAIN_EXIT_FADE = 0.35
local CURTAIN_EXIT_TOTAL = CURTAIN_EXIT_OPEN + CURTAIN_EXIT_SETTLE + CURTAIN_EXIT_FADE + 0.15

-- -- slow-rotating light-ray burst radiating from behind the card --
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

-- Exit sequence: the curtains stay shut for the entire key view, so leaving
-- (success or unload) needs to explicitly part them again before anything
-- disappears - otherwise the game would stay hidden forever. They sweep
-- open, hold a beat, then the decorative puffs dissolve away entirely so
-- nothing curtain-related is left on screen once the game is visible again.
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
-- Plug in your own uploaded/licensed rbxassetid below - a real
-- copyrighted track can't be embedded here, only wired up.
-- ===============================================================
local IntroMusic = Instance.new("Sound")
IntroMusic.Name = "IvoryAmbientMusic"
IntroMusic.SoundId = "rbxassetid://0" -- <- replace with your own track's asset id
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

local PetalsBack = makePetalField(3, 26, 8, 16, 26, 55)   -- drifting behind the card
local PetalsFront = makePetalField(30, 7, 12, 20, 55, 90) -- a few drifting in front of the glass

-- ===============================================================
-- SHADOW HELPER
-- Pure vector (stacked rounded frames, no image asset) - an image-
-- based 9-slice shadow can mismatch its real pixel layout and bleed
-- hard-edged notches past a rounded corner; this can't.
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
CardHolder.Visible = false -- revealed by revealCard() once the cinematic intro finishes
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

-- living glass edge - the highlight slowly drifts around the border
task.spawn(function()
    while CardStroke.Parent do
        CardStrokeGradient.Rotation = (CardStrokeGradient.Rotation + 0.15) % 360
        RunService.Heartbeat:Wait()
    end
end)

-- -- liquid animated blob accents --
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

-- frosted sheen sweep
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

-- drag logic (drag anywhere in the top region)
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

-- -- unload button - fully tears down the UI if someone changes their mind --
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

-- pulsing glow ring behind the logo
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

-- central logo orb
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

-- gentle idle float for the whole logo + ring
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

-- slow shimmering rotation on the logo gradient
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

-- -- twinkling sparkle accents scattered around the logo --
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

-- -- glass pill input --
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

-- -- verify button (liquid gradient pill) --
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

-- trailing chevron - nudges right on hover for a small modern CTA feel
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

-- spinner ring (shown in place of the label while a key is being checked)
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

-- -- status row --
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

-- ===============================================================
-- 3 FLOATING PROVIDER BUTTONS
-- ===============================================================
local FloatingRow = Instance.new("Frame")
FloatingRow.Name = "FloatingRow"
FloatingRow.Size = UDim2.new(1, 0, 0, 240)
FloatingRow.LayoutOrder = 4
FloatingRow.BackgroundTransparency = 1
FloatingRow.ZIndex = 7
FloatingRow.Parent = Content

local FloatingLayout = Instance.new("UIListLayout")
FloatingLayout.FillDirection = Enum.FillDirection.Vertical
FloatingLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
FloatingLayout.VerticalAlignment = Enum.VerticalAlignment.Top
FloatingLayout.Padding = UDim.new(0, 8)
FloatingLayout.SortOrder = Enum.SortOrder.LayoutOrder
FloatingLayout.Parent = FloatingRow

local function CreateFloatingButton(order, iconBuilder, iconColor, label, copyText)
    local btn = Instance.new("TextButton")
    btn.Name = label
    btn.Size = UDim2.new(1, -10, 0, 70)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = Theme.GlassCard
    btn.BackgroundTransparency = 0.18
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 7
    btn.Parent = FloatingRow
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 16)
    c.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.4
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.65
    stroke.Parent = btn

    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 0
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, iconColor),
        ColorSequenceKeypoint.new(0.5, Theme.Sakura),
        ColorSequenceKeypoint.new(1, iconColor),
    })
    strokeGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.3),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0.3),
    })
    strokeGrad.Parent = stroke

    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.fromOffset(18, 18)
    iconFrame.Position = UDim2.new(0, 14, 0, 15)
    iconFrame.BackgroundTransparency = 1
    iconFrame.ZIndex = 9
    iconFrame.Parent = btn
    iconBuilder(iconFrame, iconColor)

    local iconGlow = Instance.new("Frame")
    iconGlow.Size = UDim2.fromOffset(28, 28)
    iconGlow.Position = UDim2.new(0, 9, 0, 10)
    iconGlow.BackgroundColor3 = iconColor
    iconGlow.BackgroundTransparency = 0.85
    iconGlow.BorderSizePixel = 0
    iconGlow.ZIndex = 8
    iconGlow.Parent = btn
    local igCorner = Instance.new("UICorner")
    igCorner.CornerRadius = UDim.new(1, 0)
    igCorner.Parent = iconGlow

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, -38, 0, 14)
    txt.Position = UDim2.new(0, 36, 0, 12)
    txt.BackgroundTransparency = 1
    txt.Text = label:gsub("\n", " ")
    txt.TextColor3 = Theme.TextPrimary
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 11
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.ZIndex = 9
    txt.Parent = btn

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, -38, 0, 12)
    sub.Position = UDim2.new(0, 36, 0, 26)
    sub.BackgroundTransparency = 1
    sub.Text = "click to copy"
    sub.TextColor3 = Theme.TextTertiary
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 9
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.ZIndex = 9
    sub.Parent = btn

    task.spawn(function()
        while btn.Parent do
            strokeGrad.Rotation = (strokeGrad.Rotation + 0.5) % 360
            RunService.Heartbeat:Wait()
        end
    end)

    btn.MouseEnter:Connect(function()
        tw(btn, EASE_QUICK, { BackgroundTransparency = 0.08 })
        tw(stroke, EASE_QUICK, { Transparency = 0.3 })
        tw(iconGlow, EASE_QUICK, { BackgroundTransparency = 0.7 })
    end)
    btn.MouseLeave:Connect(function()
        tw(btn, EASE_QUICK, { BackgroundTransparency = 0.18 })
        tw(stroke, EASE_QUICK, { Transparency = 0.65 })
        tw(iconGlow, EASE_QUICK, { BackgroundTransparency = 0.85 })
    end)

    btn.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(copyText) end)
        local orig = txt.Text
        txt.Text = ok and "Copied!" or copyText
        txt.TextColor3 = ok and Theme.Success or Theme.Blue
        sub.Text = ok and "saved to clipboard" or ""
        tw(strokeGrad, EASE_QUICK, { Rotation = 180 })
        task.delay(1.5, function()
            txt.Text = orig
            txt.TextColor3 = Theme.TextPrimary
            sub.Text = "click to copy"
            tw(strokeGrad, EASE_QUICK, { Rotation = 360 })
        end)
    end)

    return btn
end

CreateFloatingButton(1, IconChat, Theme.Discord, "Discord\n(dupe)", "https://discord.gg/mrQFkCJfEe")
CreateFloatingButton(2, IconWorkMark, Theme.WorkInkTeal, "Work.ink\nKey", "https://work.ink/2STL/Ivory")
CreateFloatingButton(3, function(parent, color) IconLootGem(parent, color, Theme.LootGold) end,
    Theme.LootPurple, "LootLabs\nKey", "https://loot-link.com/s?L6z5Q0nE")

-- ===============================================================
-- CARD REVEAL / CLOSE / UNLOAD  (reverse animation + full teardown)
-- ===============================================================
local function revealCard()
    CardHolder.Visible = true
    tw(CardScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
end

local function closeUI(delay)
    task.delay(delay or 0, function()
        tw(CardScale, EASE_OUT_SOFT, { Scale = 0.85 })
        tw(Card, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
        teardownBackdrop() -- curtains open + dissolve here; wait matches that full animation
        fadeOutMusic()
        task.wait(CURTAIN_EXIT_TOTAL)
        pcall(function() ScreenGui:Destroy() end)
    end)
end

unloadUI = function()
    if _unloaded then return end
    _unloaded = true
    setStatus("Unloaded", Theme.Error)
    tw(CardScale, EASE_OUT_SOFT, { Scale = 0.8 })
    tw(Card, EASE_OUT_SOFT, { BackgroundTransparency = 1 })
    teardownBackdrop() -- curtains open + dissolve here; wait matches that full animation
    fadeOutMusic()
    task.wait(CURTAIN_EXIT_TOTAL)
    pcall(function() ScreenGui:Destroy() end)
end

-- ===============================================================
-- CINEMATIC INTRO - plays once before the key card is revealed
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

-- The intro fades out under cover of the curtains sweeping shut, and the
-- card gets swapped in while fully hidden. Unlike the opening reveal, the
-- curtains do NOT reopen here - they stay shut for the entire key view, so
-- the game underneath stays completely hidden until the user is done
-- (teardownBackdrop() is what finally reopens them, on success or unload).
local function finishIntro()
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
    -- curtains open first, unveiling the intro underneath as they part
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

-- ===============================================================
-- KEY VALIDATION
-- ===============================================================
local isVerifying = false

function ValidateKey(key)
    if isVerifying or _unloaded then return end
    isVerifying = true
    setVerifying(true)

    setStatus("Checking key...", Theme.TextTertiary)

    -- LootLabs exact match (checked first)
    if _lootKey ~= "" and key == _lootKey then
        _k.v = true
        _k.s = key
        _k.h = _hwid
        _k.t = os.time()
        _k.i = 0x4A + #key

        pcall(function()
            _genv._ivoryKey = key
            _genv._ivoryExpiry = os.time() * 1000 + 43200000
            writefile("IvoryKey.txt", key .. "\n" .. tostring(os.time() * 1000 + 43200000) .. "\n" .. _hwid)
        end)

        setStatus("Access granted", Theme.Success)
        setVerifying(false)
        VerifyLabel.Text = "Loading..."
        closeUI(1.1)
        return
    end

    -- Work.ink API validation
    local ok, res = pcall(function()
        return request({ Url = "https://work.ink/_api/v2/token/isValid/" .. key .. "?deleteToken=1", Method = "GET" })
    end)

    local handled = false
    if ok and res and res.Body then
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(res.Body)
        end)

        if not decodeOk then
            warn("[IvoryKey] JSON decode failed: " .. tostring(data))
        elseif data and data.valid then
            handled = true
            _k.v = true
            _k.s = key
            _k.h = _hwid
            _k.t = os.time()
            _k.i = 0x4A + #key

            pcall(function()
                _genv._ivoryKey = key
                _genv._ivoryExpiry = data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)
                writefile("IvoryKey.txt", key .. "\n" .. tostring(data.info and data.info.expiresAfter or (os.time() * 1000 + 86400000)) .. "\n" .. _hwid)
            end)

            setStatus("Access granted: " .. key, Theme.Success)
            setVerifying(false)
            VerifyLabel.Text = "Close"
            VerifyBtn.MouseButton1Click:Connect(function() closeUI(0) end)
        elseif data then
            warn("[IvoryKey] API response: valid=" .. tostring(data.valid) .. " body=" .. tostring(res.Body):sub(1, 200))
        end
    elseif ok and res then
        warn("[IvoryKey] Empty response body")
    else
        warn("[IvoryKey] HTTP request failed: " .. tostring(res))
    end

    if not handled then
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

-- ===============================================================
-- KEY PERSISTENCE (checked right on load)
-- ===============================================================
local function CheckSavedKey()
    if _unloaded then return end
    local savedKey, savedExpiry = nil, nil

    pcall(function()
        if isfile("IvoryKey.txt") then
            local data = readfile("IvoryKey.txt")
            savedKey, savedExpiry = data:match("^(.-)\n(.-)$")
            savedExpiry = tonumber(savedExpiry)
        end
    end)

    if not savedKey then
        pcall(function() savedKey = _genv._ivoryKey end)
        pcall(function() savedExpiry = _genv._ivoryExpiry end)
    end

    if savedKey and savedExpiry and os.time() * 1000 < savedExpiry then
        _k.v = true
        _k.s = savedKey
        _k.h = _hwid
        _k.t = os.time()
        _k.i = 0x4A + #savedKey

        setStatus("Welcome back - key restored", Theme.Success)
        setVerifying(false)
        VerifyLabel.Text = "Loading..."
        closeUI(0.9)
    end
end

task.delay(0.25, CheckSavedKey)

-- ===============================================================
-- INTEGRITY CHECK (background, random 45-90s interval - self-terminates
-- once the gui is gone, whether from success, close, or unload)
-- ===============================================================
task.spawn(function()
    while true do
        task.wait(math.random(45, 90))
        if not ScreenGui.Parent then break end
        if _k and _k.v and not _verifyIntegrity() then
            pcall(function()
                for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
                    if gui.Name == "IvoryKey" then gui:Destroy() end
                end
            end)
        end
    end
end)

-- ===============================================================
-- WAITING LOOP - block until validated, unloaded, or destroyed
-- ===============================================================
local _awaiting = true
while _awaiting do
    task.wait(0.1)
    if _k and _k.v then _awaiting = false end
    if _unloaded then _awaiting = false end
    if not ScreenGui.Parent then _awaiting = false end
end

if _unloaded then
    print("Ivory Hub - unloaded by user, nothing further will run")
    return
end

print("Ivory Hub key system - liquid glass - sakura UI loaded")

-- Clean up old instances
for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
    if gui:IsA("ScreenGui") and gui.Name == "Obsidian" then gui:Destroy() end
end
for k, v in pairs(getgenv and getgenv() or {}) do
    if type(v) == "table" and v.CreateWindow and v.Toggles then v.Toggled = false; break end
end
task.wait(0.3)

end -- close key system UI block

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(request({ Url = repo .. "Library.lua", Method = "GET" }).Body)()
local ThemeManager = loadstring(request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body)()
local SaveManager = loadstring(request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body)()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CounterRemotes = Remotes:WaitForChild("CounterRemotes")
local GetCounterInfo = CounterRemotes:WaitForChild("GetCounterInfo")
local AssignNPC = CounterRemotes:WaitForChild("AssignNPC")
local RejectNPC = CounterRemotes:WaitForChild("RejectNPC")
local RedeemCodeRemote = Remotes:WaitForChild("RedeemCode"):WaitForChild("RedeemCode")
local ShopRemotes = Remotes:WaitForChild("ShopRemotes")
local BuyFurniture = ShopRemotes:WaitForChild("BuyFurniture")
local GetShopInfo = ShopRemotes:WaitForChild("GetShopInfo")
local GetFurnitureInventory = ShopRemotes:WaitForChild("GetFurnitureInventory")
local BuyTableEvent = Remotes:WaitForChild("BuyTableEvent")
local GetUnlockedTables = Remotes:WaitForChild("GetUnlockedTables")
local PlaceFurnitureEvent = Remotes:WaitForChild("PlaceFurnitureEvent")
local BuyIngredient = ShopRemotes:WaitForChild("BuyIngredient")
local ToggleStoreStatus = Remotes:WaitForChild("ToggleStoreStatus")
local UseBoostEvent = Remotes:WaitForChild("UseBoostEvent")
local UpgradeToGoldenPan = Remotes:WaitForChild("UpgradeToGoldenPan")
local NPCRemotes = Remotes:WaitForChild("NPCRemotes")
local MenuRemotes = Remotes:WaitForChild("MenuRemotes")
local UnlockMenu = MenuRemotes:WaitForChild("UnlockMenu")
local ToggleMenu = MenuRemotes:WaitForChild("ToggleMenu")
local GetMenuData = MenuRemotes:WaitForChild("GetMenuData")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local FoodConfig = require(Modules:WaitForChild("FoodConfig"))
local IngredientsConfig = require(Modules:WaitForChild("IngredientsConfig"))
local FurnitureConfig = require(Modules:WaitForChild("FurnitureConfig"))
local NPCConfig = require(Modules:WaitForChild("NPCConfig"))

-- Build NPC list with rarities
local npcNamesWithRarity = {}
local npcRarityMap = {}
for name, data in pairs(NPCConfig.Types) do
    local rarity = data.Rarity or "Unknown"
    table.insert(npcNamesWithRarity, name .. " [" .. rarity .. "]")
    npcRarityMap[name .. " [" .. rarity .. "]"] = name
end
table.sort(npcNamesWithRarity)
table.insert(npcNamesWithRarity, 1, "None")

local Toggles = Library.Toggles
local Options = Library.Options

-- ═══════════════════════════════════════
-- TELEPORT LOCK - only one feature teleports at a time
-- ═══════════════════════════════════════
local tpLock = false

-- Waits until the lock is free, takes it, returns a release function
local function acquireTp()
    while tpLock do task.wait(0.05) end
    tpLock = true
    return function() tpLock = false end
end

local function getChar() return LocalPlayer.Character, LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") end

local function tp(cframe)
    local c = LocalPlayer.Character
    if c then local h = c:FindFirstChild("HumanoidRootPart") if h then h.CFrame = cframe end end
end

local function getPlot()
    for _, v in ipairs(Workspace:GetChildren()) do
        if string.find(v.Name, "^Karenderya") and v:GetAttribute("Owner") == LocalPlayer.UserId then return v end
    end
end

local function hasIngredients(orderName)
    if not orderName or not FoodConfig[orderName] then return true end
    local req = FoodConfig[orderName].RequiredIngredients
    if not req then return true end
    local ing = LocalPlayer:FindFirstChild("Ingredients")
    if not ing then return false end
    for _, name in ipairs(req) do local v = ing:FindFirstChild(name) if not v or v.Value <= 0 then return false end end
    return true
end

-- Parse inventory key "Tables_MonoblockTable" -> "Tables", "MonoblockTable"
local function parseInvKey(fullKey)
    local cat, key = string.match(fullKey, "^(%w+)_(.+)$")
    return cat, key
end

local function getCash()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then local c = ls:FindFirstChild("Cash") if c then return c.Value end end
    return 0
end

-- ═══════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════
local cfg = {
    autoServe = false,
    autoOrder = false,
    autoRejectNPC = false,
    rejectNPCList = {},
    autoClaimCodes = false,
    autoPan = false,
    autoClean = false,
    autoWash = false,
    autoBuyFurniture = false,
    autoPlaceFurniture = false,
    furnitureWhitelist = {},
    autoBuyIngredients = false,
    autoUseBoosts = false,
    autoUnlockTables = false,
    autoUnlockMenu = false,
    noclip = false,
    antiAfk = false,
    espNPCs = false,
    walkSpeed = 16,
    infJump = false,
}

-- ═══════════════════════════════════════
-- MONEY LOGGING
-- ═══════════════════════════════════════
local moneyLog = { entries = {}, totalEarned = 0, totalSpent = 0, startCash = getCash() }

local function logMoney(action, amount)
    table.insert(moneyLog.entries, 1, {
        time = os.date("%H:%M:%S"),
        action = action,
        amount = amount,
        cash = getCash(),
    })
    if amount > 0 then
        moneyLog.totalEarned = moneyLog.totalEarned + amount
    else
        moneyLog.totalSpent = moneyLog.totalSpent + math.abs(amount)
    end
end

-- ═══════════════════════════════════════
-- STATUS TRACKING
-- ═══════════════════════════════════════
local status = {
    serve = "Idle",
    order = "Idle",
    codes = "Idle",
    pan = "Idle",
    clean = "Idle",
    buyFurn = "Idle",
    placeFurn = "Idle",
    buyIng = "Idle",
    boosts = "Idle",
    unlockTbl = "Idle",
    unlockMenu = "Idle",
}

local function setStatus(key, text)
    status[key] = text
end

-- ═══════════════════════════════════════
-- MY NPCs TRACKING (for runaway filtering)
-- ═══════════════════════════════════════
local myAssignedNPCs = {} -- tracks NPCs assigned to my tables

local function trackNPC(npcId)
    if npcId and npcId ~= "" then
        myAssignedNPCs[npcId] = true
    end
end

local function isMyRunaway(npc)
    local id = npc.Name
    return myAssignedNPCs[id] == true
end

-- Background scanner: continuously track NPCs at my tables
task.spawn(function() while true do
    local plot = getPlot()
    if plot then
        local dp = plot:FindFirstChild("DiningPlot1")
        if dp then
            for _, slot in ipairs(dp:GetChildren()) do
                if slot:IsA("Model") then
                    local o1 = slot:GetAttribute("OccupiedBy1")
                    local o2 = slot:GetAttribute("OccupiedBy2")
                    if o1 then trackNPC(o1) end
                    if o2 then trackNPC(o2) end
                end
            end
        end
    end
    task.wait(1)
end end)

-- ═══════════════════════════════════════
-- WINDOW
-- ═══════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "Ivory",
    Footer = { "Ivory | v1.0", { Text = "v1.0", Copyable = true } },
    Minimizable = true, FuzzySearch = true, SearchValues = true,
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "utensils", Description = "Core Automation" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "shopping-cart", Description = "Buying & Inventory" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user", Description = "Character Mods" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "Themes & UI" })
local LogsTab = Window:AddTab({ Name = "Logs", Icon = "scroll-text", Description = "Money & Status" })

-- ═══ MAIN TAB: Automation Sub-Tab ═══
local AutoSub = MainTab:AddSubTab({ Name = "Automation", Icon = "zap" })

local FoodBox = AutoSub:AddLeftGroupbox("Food", "utensils")
FoodBox:AddToggle("AutoServe", { Text = "Auto Serve Food", Default = false })
FoodBox:AddToggle("AutoOrder", { Text = "Auto Assign Customers", Default = false })

FoodBox:AddDropdown("RejectNPCList", {
	Values = {},
	Multi = true,
	Default = {},
	Text = "Reject NPCs",
})
Options.RejectNPCList:SetValues(npcNamesWithRarity)
FoodBox:AddToggle("AutoRejectNPC", { Text = "Auto Reject Selected NPCs", Default = false })

local KitchenBox = AutoSub:AddLeftGroupbox("Kitchen", "chef-hat")
KitchenBox:AddToggle("AutoClean", { Text = "Auto Clean Tables", Default = false })
KitchenBox:AddToggle("AutoWash", { Text = "Auto Wash Dishes", Default = false, Tooltip = "Auto-collects dirty dishes, puts in sink, and washes them" })
KitchenBox:AddToggle("AutoPan", { Text = "Auto Pan (Hit Runaway)", Default = false })

local CodesBox = AutoSub:AddRightGroupbox("Codes", "ticket")
CodesBox:AddToggle("AutoClaimCodes", { Text = "Auto Claim Codes", Default = false })

local DelaysBox = AutoSub:AddRightGroupbox("Delays", "settings")
DelaysBox:AddSlider("ServeDelay", { Text = "Serve Delay", Default = 1, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })
DelaysBox:AddSlider("OrderDelay", { Text = "Order Delay", Default = 2, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })
DelaysBox:AddSlider("CleanDelay", { Text = "Clean Delay", Default = 2, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })
DelaysBox:AddSlider("WashDelay", { Text = "Wash Delay", Default = 2, Min = 0.5, Max = 10, Rounding = 1, Suffix = "s" })

-- ═══ MAIN TAB: Furniture & Menu Sub-Tab ═══
local FurnMenuSub = MainTab:AddSubTab({ Name = "Furniture & Menu", Icon = "armchair" })

local FurnBox = FurnMenuSub:AddLeftGroupbox("Furniture", "armchair")
FurnBox:AddToggle("AutoBuyFurniture", { Text = "Auto Buy Furniture", Default = false })
FurnBox:AddToggle("AutoPlaceFurniture", { Text = "Auto Place Furniture", Default = false })
FurnBox:AddSlider("FurnDelay", { Text = "Furniture Delay", Default = 5, Min = 2, Max = 20, Rounding = 1, Suffix = "s" })

-- Build furniture list for dropdown
local furnitureList = {}
do
    local furnCfg = require(Modules:WaitForChild("FurnitureConfig"))
    if furnCfg.Dining then
        if furnCfg.Dining.Tables then
            for k, v in pairs(furnCfg.Dining.Tables) do
                if type(v) == "table" then table.insert(furnitureList, "Tables: " .. k) end
            end
        end
        if furnCfg.Dining.Chairs then
            for k, v in pairs(furnCfg.Dining.Chairs) do
                if type(v) == "table" then table.insert(furnitureList, "Chairs: " .. k) end
            end
        end
    end
    if furnCfg.Kitchen and furnCfg.Kitchen.Stoves then
        for k, v in pairs(furnCfg.Kitchen.Stoves) do
            if type(v) == "table" then table.insert(furnitureList, "Stoves: " .. k) end
        end
    end
    table.sort(furnitureList)
    table.insert(furnitureList, 1, "None")
end

FurnBox:AddDropdown("FurnitureWhitelist", {
    Values = furnitureList,
    Multi = true,
    Default = {},
    Text = "Buy Only These",
    Tooltip = "Select which furniture to auto-buy. Empty = buy all",
})

local MenuBox = FurnMenuSub:AddRightGroupbox("Menu", "book-open")
MenuBox:AddToggle("AutoUnlockMenu", { Text = "Auto Unlock Menu", Default = false, Tooltip = "Unlocks SILOG & LUTONG BAHAY when requirements met" })
MenuBox:AddButton({ Text = "Enable All Menus", Func = function()
    pcall(function() ToggleMenu:InvokeServer("LUGAW", true) end)
    pcall(function() ToggleMenu:InvokeServer("SILOG", true) end)
    pcall(function() ToggleMenu:InvokeServer("LUTONG BAHAY", true) end)
end })

-- ═══ SHOP TAB: Groceries Sub-Tab ═══
local GrocerySub = ShopTab:AddSubTab({ Name = "Groceries", Icon = "apple" })

local GroceryBox = GrocerySub:AddLeftGroupbox("Ingredients", "apple")
GroceryBox:AddToggle("AutoBuyIngredients", { Text = "Auto Buy Ingredients", Default = false, Tooltip = "Auto-buys ingredients when stock is low" })
GroceryBox:AddSlider("IngBuyThreshold", { Text = "Buy When Below", Default = 5, Min = 1, Max = 50, Rounding = 1, Tooltip = "Buy ingredient when count drops below this" })

local UnlockBox = GrocerySub:AddRightGroupbox("Unlocks", "lock-open")
UnlockBox:AddToggle("AutoUnlockTables", { Text = "Auto Unlock Tables", Default = false, Tooltip = "Auto-unlocks Table7-12 when affordable" })
UnlockBox:AddButton({ Text = "Upgrade to Golden Pan", Func = function() pcall(function() UpgradeToGoldenPan:InvokeServer() end) end })

-- ═══ SHOP TAB: Boosts & Store Sub-Tab ═══
local BoostStoreSub = ShopTab:AddSubTab({ Name = "Boosts & Store", Icon = "zap" })

local BoostBox = BoostStoreSub:AddLeftGroupbox("Boosts", "zap")
BoostBox:AddToggle("AutoUseBoosts", { Text = "Auto Use Boosts", Default = false, Tooltip = "Auto-uses Cash/Luck/UltraLuck potions" })
BoostBox:AddButton({ Text = "Use Cash Potion", Func = function() pcall(function() UseBoostEvent:FireServer("CashPotion") end) end })
BoostBox:AddButton({ Text = "Use Luck Potion", Func = function() pcall(function() UseBoostEvent:FireServer("LuckPotion") end) end })
BoostBox:AddButton({ Text = "Use Ultra Luck Potion", Func = function() pcall(function() UseBoostEvent:FireServer("UltraLuckPotion") end) end })

local StoreBox = BoostStoreSub:AddRightGroupbox("Store", "store")
StoreBox:AddButton({ Text = "Toggle Store Open/Close", Func = function() pcall(function() ToggleStoreStatus:InvokeServer() end) end })

-- ═══ PLAYER TAB: Character Sub-Tab ═══
local CharSub = PlayerTab:AddSubTab({ Name = "Character", Icon = "person-standing" })

local CharBox = CharSub:AddLeftGroupbox("Movement", "person-standing")
CharBox:AddSlider("WalkSpeed", { Text = "Walk Speed", Default = 16, Min = 16, Max = 100, Rounding = 0 })
CharBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false })
CharBox:AddToggle("NoClip", { Text = "NoClip", Default = false, Tooltip = "Walk through walls" })
CharBox:AddToggle("AntiAfk", { Text = "Anti-AFK", Default = false, Tooltip = "Prevents AFK kick" })

local EspBox = CharSub:AddRightGroupbox("Visuals", "eye")
EspBox:AddToggle("EspNPCs", { Text = "ESP NPCs", Default = false, Tooltip = "Highlights all NPCs with colored boxes" })

-- ═══ PLAYER TAB: Teleports Sub-Tab ═══
local TPSub = PlayerTab:AddSubTab({ Name = "Teleports", Icon = "map-pin" })

local PlotTPBox = TPSub:AddLeftGroupbox("My Plot", "map-pin")
PlotTPBox:AddButton({ Text = "Teleport to Counter", Func = function() local p = getPlot() if p then local c = p:FindFirstChild("Counter") if c then local cp = c:FindFirstChild("Comp", true) if cp then tp(cp.CFrame * CFrame.new(0,3,0)) end end end end })
PlotTPBox:AddButton({ Text = "Teleport to Kitchen", Func = function() local p = getPlot() if p then local k = p:FindFirstChild("KitchenPlot1") if k then local f = k:GetChildren()[1] if f then tp(f:GetPivot() * CFrame.new(0,3,0)) end end end end })
PlotTPBox:AddButton({ Text = "Teleport to Serve Area", Func = function() local p = getPlot() if p then local s = p:FindFirstChild("Serve") if s then local f = s:GetChildren()[1] if f then tp(f:GetPivot() * CFrame.new(0,3,0)) end end end end })
PlotTPBox:AddButton({ Text = "Teleport to NPC Spawn", Func = function() local p = getPlot() if p then local ns = p:FindFirstChild("NpcSpawn") if ns then tp(ns:GetPivot() * CFrame.new(0,3,0)) end end end })

local WorldTPBox = TPSub:AddRightGroupbox("World", "globe")
WorldTPBox:AddButton({ Text = "Teleport to Grocery", Func = function() local g = Workspace:FindFirstChild("Grocery") if g then local c = g:FindFirstChild("Comp", true) if c then tp(c.CFrame * CFrame.new(0,3,0)) end end end })
WorldTPBox:AddButton({ Text = "Teleport to Shop", Func = function() local s = Workspace:FindFirstChild("SHOP") if s then local sh = s:FindFirstChild("Shop") if sh then local pp = sh:FindFirstChild("ProximityPrompt") if pp and pp.Parent:IsA("BasePart") then tp(pp.Parent.CFrame * CFrame.new(0,3,0)) end end end end })

-- ═══ SETTINGS TAB ═══
local ThemesSub = SettingsTab:AddSubTab({ Name = "Themes & UI", Icon = "palette" })
local ConfigSub = SettingsTab:AddSubTab({ Name = "Config", Icon = "save" })

-- LOGS TAB
local StatusBox = LogsTab:AddLeftGroupbox("Status", "activity")
local StatusLabels = {}
local statusOrder = {"serve", "order", "codes", "pan", "clean", "wash", "buyFurn", "placeFurn", "buyIng", "boosts", "unlockTbl", "unlockMenu"}
local statusNames = {serve="Serve", order="Order", codes="Codes", pan="Pan", clean="Clean", wash="Wash", buyFurn="Buy Furn", placeFurn="Place Furn", buyIng="Buy Ing", boosts="Boosts", unlockTbl="Unlock Tbl", unlockMenu="Unlock Menu"}
for _, key in ipairs(statusOrder) do
    StatusLabels[key] = StatusBox:AddLabel(statusNames[key] .. ": Idle", true)
end

local MoneyBox = LogsTab:AddRightGroupbox("Money Log", "dollar-sign")
local MoneyEarnedLabel = MoneyBox:AddLabel("Earned: $0", true)
local MoneySpentLabel = MoneyBox:AddLabel("Spent: $0", true)
local MoneyNetLabel = MoneyBox:AddLabel("Net: $0", true)
local MoneyStartLabel = MoneyBox:AddLabel("Start: $" .. moneyLog.startCash, true)

local MONEY_DISPLAY = 15
local moneyScrollOffset = 0
local MoneyLogLines = {}
for i = 1, MONEY_DISPLAY do
    MoneyLogLines[i] = MoneyBox:AddLabel("", true)
end

local function refreshMoneyDisplay()
    for i = 1, MONEY_DISPLAY do
        local entry = moneyLog.entries[i + moneyScrollOffset]
        if entry then
            local sign = entry.amount >= 0 and "+" or ""
            MoneyLogLines[i]:SetText(entry.time .. " | " .. entry.action .. " | " .. sign .. "$" .. entry.amount .. " | Bal: $" .. entry.cash)
        else
            MoneyLogLines[i]:SetText(i == 1 and "No entries yet" or "")
        end
    end
end

MoneyBox:AddButton({ Text = "Clear Logs", Func = function()
    moneyLog.entries = {}
    moneyLog.totalEarned = 0
    moneyLog.totalSpent = 0
    moneyLog.startCash = getCash()
    moneyScrollOffset = 0
    for i = 1, MONEY_DISPLAY do MoneyLogLines[i]:SetText("") end
    MoneyEarnedLabel:SetText("Earned: $0")
    MoneySpentLabel:SetText("Spent: $0")
    MoneyNetLabel:SetText("Net: $0")
    MoneyStartLabel:SetText("Start: $" .. getCash())
end })

MoneyBox:AddButton({ Text = "Scroll Up", Func = function()
    moneyScrollOffset = math.max(0, moneyScrollOffset - MONEY_DISPLAY)
    refreshMoneyDisplay()
end })

MoneyBox:AddButton({ Text = "Scroll Down", Func = function()
    local maxOffset = math.max(0, #moneyLog.entries - MONEY_DISPLAY)
    moneyScrollOffset = math.min(maxOffset, moneyScrollOffset + MONEY_DISPLAY)
    refreshMoneyDisplay()
end })

local RefreshBox = LogsTab:AddLeftGroupbox("Auto Refresh", "refresh-cw")
RefreshBox:AddToggle("AutoRefreshLogs", { Text = "Auto Refresh", Default = true })
RefreshBox:AddSlider("RefreshInterval", { Text = "Refresh Interval", Default = 2, Min = 1, Max = 10, Rounding = 0, Suffix = "s" })

-- CALLBACKS
Toggles.AutoServe:OnChanged(function(s) cfg.autoServe = s end)
Toggles.AutoOrder:OnChanged(function(s) cfg.autoOrder = s end)
Toggles.AutoRejectNPC:OnChanged(function(s) cfg.autoRejectNPC = s end)
Options.RejectNPCList:OnChanged(function(v)
    if v["None"] then
        -- "None" selected, clear everything
        Options.RejectNPCList:SetValue({})
        cfg.rejectNPCList = {}
        return
    end
    cfg.rejectNPCList = {}
    for displayName, selected in pairs(v) do
        if selected and displayName ~= "None" then
            local npcName = npcRarityMap[displayName]
            if npcName then
                cfg.rejectNPCList[npcName] = true
            end
        end
    end
end)
Toggles.AutoClaimCodes:OnChanged(function(s) cfg.autoClaimCodes = s end)
Toggles.AutoPan:OnChanged(function(s) cfg.autoPan = s end)
Toggles.AutoClean:OnChanged(function(s) cfg.autoClean = s end)
Toggles.AutoWash:OnChanged(function(s) cfg.autoWash = s end)
Toggles.AutoBuyFurniture:OnChanged(function(s) cfg.autoBuyFurniture = s end)
Toggles.AutoPlaceFurniture:OnChanged(function(s) cfg.autoPlaceFurniture = s end)
Options.FurnitureWhitelist:OnChanged(function(v)
    if v["None"] then
        -- "None" selected, clear everything
        Options.FurnitureWhitelist:SetValue({})
        cfg.furnitureWhitelist = {}
        return
    end
    cfg.furnitureWhitelist = {}
    for name, enabled in pairs(v) do
        if enabled and name ~= "None" then cfg.furnitureWhitelist[name] = true end
    end
end)
Toggles.AutoBuyIngredients:OnChanged(function(s) cfg.autoBuyIngredients = s end)
Toggles.AutoUseBoosts:OnChanged(function(s) cfg.autoUseBoosts = s end)
Toggles.AutoUnlockTables:OnChanged(function(s) cfg.autoUnlockTables = s end)
Toggles.AutoUnlockMenu:OnChanged(function(s) cfg.autoUnlockMenu = s end)
Toggles.NoClip:OnChanged(function(s) cfg.noclip = s end)
Toggles.AntiAfk:OnChanged(function(s) cfg.antiAfk = s end)
Toggles.EspNPCs:OnChanged(function(s) cfg.espNPCs = s end)
Options.WalkSpeed:OnChanged(function(v) cfg.walkSpeed = v local _,h = getChar() if h then h.WalkSpeed = v end end)
Toggles.InfJump:OnChanged(function(s) cfg.infJump = s end)
Toggles.AutoRefreshLogs:OnChanged(function(s) cfg.autoRefreshLogs = s end)

-- ═══ AUTO SERVE ═══
task.spawn(function() while true do
    if cfg.autoServe and _k and _k.v and _k.i then
        local cashBefore = getCash()
        setStatus("serve", "Scanning...")
        local served = 0
        local plot = getPlot()
        if plot then
            local dp = plot:FindFirstChild("DiningPlot1")
            if dp then
                for _, slot in ipairs(dp:GetChildren()) do
                    if served >= 3 then break end
                    if slot:IsA("Model") then
                        for _, desc in ipairs(slot:GetDescendants()) do
                            if served >= 3 then break end
                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                local action = desc.ActionText
                                if string.sub(action, 1, 5) == "Serve" then
                                    local pp = desc.Parent
                                    if pp and pp:IsA("BasePart") then
                                        local release = acquireTp()
                                        tp(pp.CFrame * CFrame.new(0, 3, 0))
                                        task.wait(0.15)
                                        fireproximityprompt(desc)
                                        release()
                                        served = served + 1
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local serve = plot:FindFirstChild("Serve")
            if serve then
                for _, desc in ipairs(serve:GetDescendants()) do
                    if served >= 3 then break end
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local pp = desc.Parent
                        if pp and pp:IsA("BasePart") then
                            local release = acquireTp()
                            tp(pp.CFrame * CFrame.new(0, 3, 0))
                            task.wait(0.15)
                            fireproximityprompt(desc)
                            release()
                            served = served + 1
                            task.wait(0.2)
                        end
                    end
                end
            end
        end
        local cashAfter = getCash()
        local diff = cashAfter - cashBefore
        if served > 0 then
            setStatus("serve", "Served " .. served .. " food")
        else
            setStatus("serve", "No food to serve")
        end
        if diff ~= 0 then
            logMoney("Serve Food", diff)
        end
    else
        setStatus("serve", "Disabled")
    end
    task.wait(0.3)
end end)

-- ═══ AUTO ORDER ═══
task.spawn(function() while true do
    if cfg.autoOrder and _k and _k.v and _k.i then
        local totalAssigned = 0
        for attempt = 1, 15 do
            setStatus("order", "Assigning... (" .. totalAssigned .. ")")
            local plot = getPlot()
            if plot then
                local counter = plot:FindFirstChild("Counter")
                if counter then
                    local comp = counter:FindFirstChild("Comp", true)
                    if comp then
                        for _, desc in ipairs(comp:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                local action = desc.ActionText
                                if string.find(action, "Take Order") or string.find(action, "Take") then
                                    local pp = desc.Parent
                                    if pp and pp:IsA("BasePart") then
                                        local release = acquireTp()
                                        tp(pp.CFrame * CFrame.new(0, 3, 0))
                                        task.wait(0.1)
                                        fireproximityprompt(desc)
                                        release()
                                        task.wait(0.15)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local ok, npc, tbls = pcall(function() return GetCounterInfo:InvokeServer() end)
            if ok and npc and tbls then
                local id = npc.NpcId or npc.TemplateName or ""
                local templateName = npc.TemplateName or ""
                if cfg.autoRejectNPC and cfg.rejectNPCList[templateName] then
                    pcall(function() RejectNPC:FireServer(id) end)
                    setStatus("order", "Rejected " .. templateName)
                    task.wait(0.5)
                    break
                end
                trackNPC(id)
                local s = false
                for _, t in ipairs(tbls) do
                    if t.Slot and t.Seat then
                        s = pcall(function() AssignNPC:FireServer({Slot=t.Slot, Seat=t.Seat, NPCName=id, NpcId=id}) end)
                        if s then totalAssigned = totalAssigned + 1 break end
                    end
                end
                if not s then break end
            else
                break
            end
            task.wait(0.05)
        end
        setStatus("order", totalAssigned > 0 and "Assigned " .. totalAssigned or "No NPC")
    else
        setStatus("order", "Disabled")
    end
    task.wait(0.5)
end end)

-- ═══ AUTO CLAIM CODES ═══
task.spawn(function() local claimed = {} while true do
    if cfg.autoClaimCodes and _k and _k.v then
        setStatus("codes", "Claiming codes...")
        local count = 0
        for _, code in ipairs({"LERISNATO"}) do
            if not claimed[code] then
                pcall(function() RedeemCodeRemote:FireServer(code) end)
                claimed[code] = true
                count = count + 1
                task.wait(3)
            end
        end
        if count > 0 then
            setStatus("codes", "Claimed " .. count .. " code(s)")
        else
            setStatus("codes", "All codes claimed")
        end
    else
        setStatus("codes", "Disabled")
    end
    task.wait(10)
end end)

-- ═══ AUTO PAN ═══
task.spawn(function() while true do
    if cfg.autoPan and _k and _k.v and _verifyIntegrity() then
        local char, hum = getChar()
        if char and hum then
            local bp = LocalPlayer:FindFirstChild("Backpack")
            local pan = bp and bp:FindFirstChild("Pan") if not pan then pan = char:FindFirstChild("Pan") end

            if not pan then
                setStatus("pan", "No pan equipped")
            else
                local chased = false
                for attempt = 1, 10 do
                    local cn = Workspace:FindFirstChild("ClientNPCs")
                    local runawayNPC = nil
                    if cn then
                        for _, npc in ipairs(cn:GetChildren()) do
                            if npc:IsA("Model") and npc:GetAttribute("IsRunaway") == true and isMyRunaway(npc) then
                                runawayNPC = npc
                                break
                            end
                        end
                    end

                    if not runawayNPC then
                        setStatus("pan", chased and "Done!" or "No my runaways")
                        break
                    end

                    local nh = runawayNPC:FindFirstChild("HumanoidRootPart") or runawayNPC.PrimaryPart
                    if not nh then break end
                    local npcCF = nh.CFrame

                    chased = true
                    setStatus("pan", "Chasing... (" .. attempt .. ")")

                    if pan.Parent ~= char then
                        hum:EquipTool(pan)
                        task.wait(0.2)
                    end

                    local release = acquireTp()
                    tp(npcCF * CFrame.new(0, 0, -3))
                    task.wait(0.1)

                    if pan.Parent == char then
                        pcall(function() pan:Activate() end)
                    end

                    release()
                    task.wait(0.4)

                    if pan.Parent == char then
                        hum:UnequipTools()
                        task.wait(0.15)
                    end
                end
            end
        end
    else
        setStatus("pan", "Disabled")
    end
    task.wait(0.5)
end end)

-- ═══ AUTO CLEAN ═══
task.spawn(function() while true do
    if cfg.autoClean and _k and _k.v and _k.i then
        setStatus("clean", "Scanning...")
        local cleaned = 0
        local plot = getPlot()
        if plot then
            local dp = plot:FindFirstChild("DiningPlot1")
            if dp then
                for _, tm in ipairs(dp:GetChildren()) do
                    if tm:IsA("Model") or tm:IsA("Folder") then
                        for _, desc in ipairs(tm:GetDescendants()) do
                            if desc:IsA("ProximityPrompt") and desc.Enabled then
                                local action = desc.ActionText:lower()
                                if string.find(action, "clean") or string.find(action, "pick") or string.find(action, "dispose") or string.find(action, "collect") or string.find(action, "trash") then
                                    local pp = desc.Parent
                                    if pp and pp:IsA("BasePart") then
                                        local release = acquireTp()
                                        tp(pp.CFrame * CFrame.new(0, 3, 0))
                                        task.wait(0.15)
                                        fireproximityprompt(desc)
                                        release()
                                        cleaned = cleaned + 1
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            local serve = plot:FindFirstChild("Serve")
            if serve then
                for _, desc in ipairs(serve:GetDescendants()) do
                    if desc:IsA("ProximityPrompt") and desc.Enabled then
                        local action = desc.ActionText:lower()
                        if string.find(action, "clean") or string.find(action, "pick") or string.find(action, "dispose") then
                            local pp = desc.Parent
                            if pp and pp:IsA("BasePart") then
                                local release = acquireTp()
                                tp(pp.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.15)
                                fireproximityprompt(desc)
                                release()
                                cleaned = cleaned + 1
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
            local others = plot:FindFirstChild("Others")
            if others then
                local trash = others:FindFirstChild("Trash")
                if trash then
                    for _, desc in ipairs(trash:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") and desc.Enabled then
                            local pp = desc.Parent
                            if pp and pp:IsA("BasePart") then
                                local release = acquireTp()
                                tp(pp.CFrame * CFrame.new(0, 3, 0))
                                task.wait(0.15)
                                fireproximityprompt(desc)
                                release()
                                cleaned = cleaned + 1
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
        if cleaned > 0 then
            setStatus("clean", "Cleaned " .. cleaned .. " items")
        else
            setStatus("clean", "Nothing to clean")
        end
    else
        setStatus("clean", "Disabled")
    end
    task.wait(Options.CleanDelay and Options.CleanDelay.Value or 2)
end end)

-- ═══ AUTO WASH ═══
task.spawn(function() while true do
    if cfg.autoWash and _k and _k.v and _k.s then
        setStatus("wash", "Scanning...")
        local plot = getPlot()
        if plot then
            local sink = plot:FindFirstChild("Sink")
            local washed = 0

            -- Step 1: Collect dirty dishes from entire plot and put them in sink
            for _, desc in ipairs(plot:GetDescendants()) do
                if desc:IsA("ProximityPrompt") and desc.Enabled then
                    local action = desc.ActionText:lower()
                    local obj = desc.ObjectText:lower()
                    if string.find(obj, "dirty") or string.find(obj, "dish") or string.find(action, "wash") or string.find(action, "pick") then
                        local pp = desc.Parent
                        if pp and pp:IsA("BasePart") then
                            -- Pick up the dish
                            local release = acquireTp()
                            tp(pp.CFrame * CFrame.new(0, 3, 0))
                            task.wait(0.2)
                            if desc.Enabled then
                                fireproximityprompt(desc)
                            end
                            release()

                            -- Wait until holding a tool
                            local gotTool = false
                            for _ = 1, 30 do
                                local c = LocalPlayer.Character
                                if c and c:FindFirstChildOfClass("Tool") then
                                    gotTool = true
                                    break
                                end
                                task.wait(0.1)
                            end

                            if gotTool and sink then
                                task.wait(0.2)
                                -- Find the Put prompt in sink
                                local putPrompt = nil
                                for _, pd in ipairs(sink:GetDescendants()) do
                                    if pd:IsA("ProximityPrompt") and (pd.Name == "Put" or string.find(pd.ActionText:lower(), "put") or string.find(pd.ActionText:lower(), "place")) then
                                        putPrompt = pd
                                        break
                                    end
                                end
                                if putPrompt then
                                    local release2 = acquireTp()
                                    tp(putPrompt.Parent.CFrame * CFrame.new(0, 3, 0))
                                    task.wait(0.25)
                                    if putPrompt.Enabled then
                                        fireproximityprompt(putPrompt)
                                    end
                                    release2()
                                    task.wait(0.8)
                                end
                            end
                        end
                    end
                end
            end

            -- Step 2: Wash all dishes in sink (loop until no more prompts)
            if sink then
                -- Debug: list all prompts in sink
                for _, pd in ipairs(sink:GetDescendants()) do
                    if pd:IsA("ProximityPrompt") then
                        warn("[IvoryWash] Sink prompt: Name=" .. pd.Name .. " Action=" .. pd.ActionText .. " Object=" .. pd.ObjectText .. " Enabled=" .. tostring(pd.Enabled))
                    end
                end

                for attempt = 1, 15 do
                    -- Find any enabled prompt in the sink (Wash, Clean, Scrub, etc.)
                    local washPrompt = nil
                    for _, pd in ipairs(sink:GetDescendants()) do
                        if pd:IsA("ProximityPrompt") and pd.Enabled then
                            local a = pd.ActionText:lower()
                            local o = pd.ObjectText:lower()
                            if string.find(a, "wash") or string.find(a, "clean") or string.find(a, "scrub")
                                or string.find(o, "dish") or string.find(o, "dirty") or string.find(o, "plate") then
                                washPrompt = pd
                                break
                            end
                        end
                    end
                    if not washPrompt then break end

                    local release3 = acquireTp()
                    tp(washPrompt.Parent.CFrame * CFrame.new(0, 3, 0))
                    task.wait(0.3)
                    if washPrompt.Enabled then
                        -- Simulate holding the interaction key
                        local holdTime = washPrompt.HoldDuration or 1
                        local VIM = game:GetService("VirtualInputManager")
                        pcall(function()
                            VIM:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                            task.wait(holdTime + 0.5)
                            VIM:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        end)
                        -- Fallback: also fire the prompt
                        pcall(fireproximityprompt, washPrompt)
                        washed = washed + 1
                    end
                    release3()
                    task.wait(1.0)
                end
            end

            if washed > 0 then
                setStatus("wash", "Washed " .. washed .. " dishes")
            else
                setStatus("wash", "Nothing to wash")
            end
        end
    else
        setStatus("wash", "Disabled")
    end
    task.wait(Options.WashDelay and Options.WashDelay.Value or 2)
end end)

-- ═══ AUTO BUY FURNITURE ═══
task.spawn(function() while true do
    if cfg.autoBuyFurniture and _k and _k.v then
        setStatus("buyFurn", "Checking shop...")
        local cash = getCash()
        local ok, shopData = pcall(function() return GetShopInfo:InvokeServer() end)
        if ok and shopData then
            local furnCfg = FurnitureConfig
            local allItems = {}
            local hasWhitelist = next(cfg.furnitureWhitelist) ~= nil
            for _, category in ipairs({"Tables", "Chairs", "Stoves"}) do
                local items = shopData[category]
                if items then
                    for _, item in ipairs(items) do
                        if item.Stock and item.Stock > 0 then
                            local displayName = category .. ": " .. item.Key
                            if not hasWhitelist or cfg.furnitureWhitelist[displayName] then
                                local price = 0
                                local sysType = item.SystemType or "Dining"
                                if sysType == "Kitchen" then
                                    local stoves = furnCfg.Kitchen and furnCfg.Kitchen.Stoves
                                    if stoves and stoves[item.Key] and type(stoves[item.Key]) == "table" then
                                        price = stoves[item.Key].Price or 0
                                    end
                                else
                                    local catData = furnCfg.Dining and furnCfg.Dining[category]
                                    if catData and catData[item.Key] and type(catData[item.Key]) == "table" then
                                        price = catData[item.Key].Price or 0
                                    end
                                end
                                table.insert(allItems, {item = item, price = price})
                            end
                        end
                    end
                end
            end
            table.sort(allItems, function(a, b) return a.price > b.price end)

            local bought = 0
            for _, entry in ipairs(allItems) do
                if entry.price <= cash and entry.price > 0 then
                    local cashBefore = getCash()
                    pcall(function()
                        BuyFurniture:InvokeServer(entry.item.SystemType, entry.item.Category, entry.item.Key)
                    end)
                    local cashAfter = getCash()
                    local diff = cashAfter - cashBefore
                    if diff ~= 0 then
                        logMoney("Buy " .. entry.item.Key, diff)
                    end
                    cash = cashAfter
                    bought = bought + 1
                    task.wait(0.5)
                end
            end
            if bought > 0 then
                setStatus("buyFurn", "Bought " .. bought .. " items")
            else
                setStatus("buyFurn", "Nothing affordable")
            end
        else
            setStatus("buyFurn", "Shop query failed")
        end
    else
        setStatus("buyFurn", "Disabled")
    end
    task.wait(Options.FurnDelay and Options.FurnDelay.Value or 5)
end end)

-- ═══ AUTO PLACE / UPGRADE FURNITURE ═══
task.spawn(function()
    local priceLookup = {}
    local furnCfg = FurnitureConfig
    if furnCfg.Dining then
        if furnCfg.Dining.Tables then
            for k, v in pairs(furnCfg.Dining.Tables) do
                if type(v) == "table" and v.Price then priceLookup["Tables_" .. k] = v.Price end
            end
        end
        if furnCfg.Dining.Chairs then
            for k, v in pairs(furnCfg.Dining.Chairs) do
                if type(v) == "table" and v.Price then priceLookup["Chairs_" .. k] = v.Price end
            end
        end
    end
    if furnCfg.Kitchen and furnCfg.Kitchen.Stoves then
        for k, v in pairs(furnCfg.Kitchen.Stoves) do
            if type(v) == "table" and v.Price then priceLookup["Stoves_" .. k] = v.Price end
        end
    end

    local modelNameToKey = {}
    if furnCfg.Dining then
        if furnCfg.Dining.Tables then
            for k, v in pairs(furnCfg.Dining.Tables) do
                if type(v) == "table" and v.Name then modelNameToKey[v.Name] = k end
            end
        end
        if furnCfg.Dining.Chairs then
            for k, v in pairs(furnCfg.Dining.Chairs) do
                if type(v) == "table" and v.Name then modelNameToKey[v.Name] = k end
            end
        end
    end
    if furnCfg.Kitchen and furnCfg.Kitchen.Stoves then
        for k, v in pairs(furnCfg.Kitchen.Stoves) do
            if type(v) == "table" and v.Name then modelNameToKey[v.Name] = k end
        end
    end

    while true do
        if cfg.autoPlaceFurniture and _k and _k.v and _k.i then
            setStatus("placeFurn", "Checking inventory...")
            local plot = getPlot()
            if plot then
                local ok, inv = pcall(function() return GetFurnitureInventory:InvokeServer() end)
                if ok and inv then
                    local inventory = {Tables = {}, Chairs = {}, Stoves = {}}
                    for fullKey, count in pairs(inv) do
                        if type(count) == "number" and count > 0 then
                            local cat, key = parseInvKey(fullKey)
                            if cat and inventory[cat] then
                                table.insert(inventory[cat], {key = key, count = count, price = priceLookup[fullKey] or 0})
                            end
                        end
                    end
                    for _, list in pairs(inventory) do
                        table.sort(list, function(a, b) return a.price > b.price end)
                    end

                    local dp = plot:FindFirstChild("DiningPlot1")
                    if dp then
                        for _, slot in ipairs(dp:GetChildren()) do
                            if slot:IsA("Model") then
                                local ct = slot:FindFirstChild("CurrentTable")
                                if ct then
                                    local currentChildren = ct:GetChildren()
                                    local currentPrice = 0
                                    if #currentChildren > 0 then
                                        local currentModel = currentChildren[1]
                                        local currentKey = modelNameToKey[currentModel.Name] or currentModel.Name
                                        currentPrice = priceLookup["Tables_" .. currentKey] or 0
                                    end
                                    if #inventory.Tables > 0 then
                                        local best = inventory.Tables[1]
                                        if best.price > currentPrice then
                                            pcall(function() PlaceFurnitureEvent:FireServer(slot, "Tables", best.key) end)
                                            task.wait(1)
                                        end
                                    end
                                end
                                local cc = slot:FindFirstChild("CurrentChair")
                                if cc then
                                    local currentChildren = cc:GetChildren()
                                    local currentPrice = 0
                                    if #currentChildren > 0 then
                                        local currentModel = currentChildren[1]
                                        local currentKey = modelNameToKey[currentModel.Name] or currentModel.Name
                                        currentPrice = priceLookup["Chairs_" .. currentKey] or 0
                                    end
                                    if #inventory.Chairs > 0 then
                                        local best = inventory.Chairs[1]
                                        if best.price > currentPrice then
                                            pcall(function() PlaceFurnitureEvent:FireServer(slot, "Chairs", best.key) end)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end

                    local kp = plot:FindFirstChild("KitchenPlot1")
                    if kp then
                        for _, slot in ipairs(kp:GetChildren()) do
                            if slot:IsA("Model") or slot:IsA("Folder") then
                                local cb = slot:FindFirstChild("CurrentBuilding")
                                if cb then
                                    local currentChildren = cb:GetChildren()
                                    local currentPrice = 0
                                    if #currentChildren > 0 then
                                        local currentModel = currentChildren[1]
                                        local currentKey = modelNameToKey[currentModel.Name] or currentModel.Name
                                        currentPrice = priceLookup["Stoves_" .. currentKey] or 0
                                    end
                                    if #inventory.Stoves > 0 then
                                        local best = inventory.Stoves[1]
                                        if best.price > currentPrice then
                                            pcall(function() PlaceFurnitureEvent:FireServer(slot, "Stoves", best.key, "Kitchen") end)
                                            task.wait(1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            setStatus("placeFurn", "Placement done")
        else
            setStatus("placeFurn", "Disabled")
        end
        task.wait(Options.FurnDelay and Options.FurnDelay.Value or 5)
    end
end)

-- ═══ AUTO BUY INGREDIENTS ═══
task.spawn(function() while true do
    if cfg.autoBuyIngredients and _k and _k.v and _k.i then
        setStatus("buyIng", "Checking stock...")
        local cash = getCash()
        local threshold = Options.IngBuyThreshold and Options.IngBuyThreshold.Value or 5
        local bought = 0
        local ing = LocalPlayer:FindFirstChild("Ingredients")
        if ing then
            for name, data in pairs(IngredientsConfig) do
                local val = ing:FindFirstChild(name)
                if val and val.Value < threshold then
                    local price = data.Cost or 0
                    local buyCount = math.max(1, threshold - val.Value)
                    for i = 1, buyCount do
                        if cash >= price then
                            local cashBefore = getCash()
                            pcall(function() BuyIngredient:InvokeServer(name, 1, "Cash") end)
                            local cashAfter = getCash()
                            local diff = cashAfter - cashBefore
                            if diff ~= 0 then
                                logMoney("Buy " .. name, diff)
                            end
                            cash = cashAfter
                            bought = bought + 1
                            task.wait(0.3)
                        else
                            break
                        end
                    end
                end
            end
        end
        if bought > 0 then
            setStatus("buyIng", "Bought " .. bought .. " ingredients")
        else
            setStatus("buyIng", "Stock OK")
        end
    else
        setStatus("buyIng", "Disabled")
    end
    task.wait(5)
end end)

-- ═══ AUTO USE BOOSTS ═══
task.spawn(function() while true do
    if cfg.autoUseBoosts and _k and _k.v and _k.s then
        local used = 0
        local cashPotions = LocalPlayer:GetAttribute("CashPotionCount") or 0
        if cashPotions > 0 then
            setStatus("boosts", "Using Cash Potion...")
            pcall(function() UseBoostEvent:FireServer("CashPotion") end)
            used = used + 1
            task.wait(1)
        end
        local luckPotions = LocalPlayer:GetAttribute("LuckPotionCount") or 0
        if luckPotions > 0 then
            setStatus("boosts", "Using Luck Potion...")
            pcall(function() UseBoostEvent:FireServer("LuckPotion") end)
            used = used + 1
            task.wait(1)
        end
        local ultraPotions = LocalPlayer:GetAttribute("UltraLuckPotionCount") or 0
        if ultraPotions > 0 then
            setStatus("boosts", "Using Ultra Luck Potion...")
            pcall(function() UseBoostEvent:FireServer("UltraLuckPotion") end)
            used = used + 1
            task.wait(1)
        end
        if used > 0 then
            setStatus("boosts", "Used " .. used .. " potion(s)")
        else
            setStatus("boosts", "No potions")
        end
    else
        setStatus("boosts", "Disabled")
    end
    task.wait(30)
end end)

-- ═══ AUTO UNLOCK TABLES ═══
task.spawn(function() while true do
    if cfg.autoUnlockTables and _k and _k.v and _verifyIntegrity() then
        setStatus("unlockTbl", "Checking tables...")
        local cash = getCash()
        local ok, unlocked = pcall(function() return GetUnlockedTables:InvokeServer() end)
        if ok and unlocked then
            local count = 0
            for _, v in pairs(unlocked) do if v == true then count = count + 1 end end
            local cost = (count + 1) * 20000
            if cash >= cost then
                for i = 7, 12 do
                    local tableName = "Table" .. i
                    if not unlocked[tableName] then
                        local cashBefore = getCash()
                        pcall(function() BuyTableEvent:InvokeServer(tableName) end)
                        local cashAfter = getCash()
                        local diff = cashAfter - cashBefore
                        if diff ~= 0 then
                            logMoney("Unlock " .. tableName, diff)
                            setStatus("unlockTbl", "Unlocked " .. tableName)
                        end
                        task.wait(0.5)
                        break
                    end
                end
            else
                setStatus("unlockTbl", "Need $" .. cost .. " (have $" .. cash .. ")")
            end
        else
            setStatus("unlockTbl", "Query failed")
        end
    else
        setStatus("unlockTbl", "Disabled")
    end
    task.wait(10)
end end)

-- ═══ AUTO UNLOCK MENU ═══
task.spawn(function() while true do
    if cfg.autoUnlockMenu and _k and _k.v and _k.i then
        setStatus("unlockMenu", "Checking menu...")
        local ok, menuData = pcall(function() return GetMenuData:InvokeServer() end)
        if ok and menuData then
            local served = menuData.TotalServed or 0
            if served >= 100 and not menuData.UnlockedMenus.SILOG then
                setStatus("unlockMenu", "Unlocking SILOG...")
                pcall(function() UnlockMenu:InvokeServer("SILOG") end)
                setStatus("unlockMenu", "SILOG unlocked!")
                task.wait(1)
            elseif served >= 670 and not (menuData.UnlockedMenus["LUTONG BAHAY"]) then
                setStatus("unlockMenu", "Unlocking LUTONG BAHAY...")
                pcall(function() UnlockMenu:InvokeServer("LUTONG BAHAY") end)
                setStatus("unlockMenu", "LUTONG BAHAY unlocked!")
                task.wait(1)
            else
                setStatus("unlockMenu", served .. " served")
            end
        else
            setStatus("unlockMenu", "Query failed")
        end
    else
        setStatus("unlockMenu", "Disabled")
    end
    task.wait(15)
end end)

-- ═══ NOCLIP ═══
RunService.Stepped:Connect(function()
    if cfg.noclip and _k and _k.v then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- ═══ ANTI-AFK ═══
task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if cfg.antiAfk and _k and _k.v and _k.i then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)
end)

-- ═══ ESP NPCS ═══
task.spawn(function()
    local espFolder = Instance.new("Folder")
    espFolder.Name = "KarinderyaESP"
    espFolder.Parent = CoreGui

    local function addESP(npc)
        if not npc:IsA("Model") then return end
        if npc:FindFirstChild("KarinderyaESP") then return end
        local highlight = Instance.new("Highlight")
        highlight.Name = "KarinderyaESP"
        highlight.FillTransparency = 0.7
        highlight.OutlineTransparency = 0.2
        if npc:GetAttribute("IsRunaway") then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 50, 50)
        elseif npc:GetAttribute("Order") then
            highlight.FillColor = Color3.fromRGB(0, 170, 255)
            highlight.OutlineColor = Color3.fromRGB(0, 120, 255)
        else
            highlight.FillColor = Color3.fromRGB(0, 255, 100)
            highlight.OutlineColor = Color3.fromRGB(0, 200, 80)
        end
        highlight.Adornee = npc
        highlight.Parent = npc
    end

    local function removeESP(npc)
        local esp = npc:FindFirstChild("KarinderyaESP")
        if esp then esp:Destroy() end
    end

    while true do
        local cn = Workspace:FindFirstChild("ClientNPCs")
        if cn then
            for _, npc in ipairs(cn:GetChildren()) do
                if cfg.espNPCs and _k and _k.v and _k.s then
                    addESP(npc)
                else
                    removeESP(npc)
                end
            end
        end
        if not cfg.espNPCs and cn then
            for _, npc in ipairs(cn:GetChildren()) do
                removeESP(npc)
            end
        end
        task.wait(1)
    end
end)

-- ═══════════════════════════════════════
-- WALKSPEED & INFINITE JUMP
-- ═══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(c) local h = c:WaitForChild("Humanoid",10) if h then h.WalkSpeed = cfg.walkSpeed end end)
do local _,h = getChar() if h then h.WalkSpeed = cfg.walkSpeed end end
UserInputService.JumpRequest:Connect(function() if cfg.infJump and _k and _k.v and _k.i then local _,h = getChar() if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end end end)

-- ═══════════════════════════════════════
-- LOGS REFRESH LOOP
-- ═══════════════════════════════════════
task.spawn(function() while true do
    if Library.Toggled then
        for _, key in ipairs(statusOrder) do
            if StatusLabels[key] then
                StatusLabels[key]:SetText(statusNames[key] .. ": " .. (status[key] or "Idle"))
            end
        end
        MoneyEarnedLabel:SetText("Earned: $" .. moneyLog.totalEarned)
        MoneySpentLabel:SetText("Spent: $" .. moneyLog.totalSpent)
        MoneyNetLabel:SetText("Net: $" .. (moneyLog.totalEarned - moneyLog.totalSpent))
        MoneyStartLabel:SetText("Start: $" .. moneyLog.startCash .. " | Now: $" .. getCash())
        refreshMoneyDisplay()
    end
    local interval = Options.RefreshInterval and Options.RefreshInterval.Value or 2
    task.wait(interval)
end end)

-- ═══════════════════════════════════════
-- CASH MONITOR (passive detection)
-- ═══════════════════════════════════════
task.spawn(function()
    local lastCash = getCash()
    while true do
        task.wait(3)
        local currentCash = getCash()
        local diff = currentCash - lastCash
        if diff ~= 0 and not cfg.autoServe and not cfg.autoBuyFurniture and not cfg.autoBuyIngredients and not cfg.autoUnlockTables then
            if diff > 0 then
                logMoney("Passive earn", diff)
            else
                logMoney("Passive spend", diff)
            end
        end
        lastCash = currentCash
    end
end)

-- THEME & SAVE
ThemeManager:SetLibrary(Library) SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings() SaveManager:SetIgnoreIndexes({})
ThemeManager:SetFolder("KarinderyaScript") SaveManager:SetFolder("KarinderyaScript/saves")
ThemeManager:ApplyToTab(ThemesSub)
SaveManager:BuildConfigSection(ConfigSub) SaveManager:LoadAutoloadConfig()

if not Library.Toggled then Library:Toggle() end
print("[Karinderya] Loaded - RightControl to toggle")
