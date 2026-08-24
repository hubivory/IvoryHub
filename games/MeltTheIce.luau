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
FloatingRow.Size = UDim2.new(1, 0, 0, 40)
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
    local btn = Instance.new("TextButton")
    btn.Name = label
    btn.Size = UDim2.fromOffset(92, 36)
    btn.LayoutOrder = order
    btn.BackgroundColor3 = iconColor
    btn.BackgroundTransparency = 0.7
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Text = label:gsub("\n", " ")
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.ZIndex = 7
    btn.Parent = FloatingRow
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn

    btn.MouseButton1Click:Connect(function()
        local ok = pcall(function() setclipboard(copyText) end)
        if ok then
            btn.Text = "Copied!"
        else
            btn.Text = copyText
        end
        task.delay(1.5, function()
            btn.Text = label:gsub("\n", " ")
        end)
    end)

    return btn
end

CreateFloatingButton(1, IconChat, Theme.Discord, "Discord\n(dupe)", "https://discord.gg/mrQFkCJfEe")
CreateFloatingButton(2, IconWorkMark, Theme.WorkInkTeal, "Work.ink\nKey", "https://work.ink/2STL/Ivory")
CreateFloatingButton(3, function(parent, color) IconLootGem(parent, color, Theme.LootGold) end,
    Theme.LootPurple, "LootLabs\nKey", "https://loot-link.com/s?L6z5Q0nE")

-- -- footer tag --
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

end -- close key system UI block

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LP = Players.LocalPlayer
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
	ClaimPlaytimeReward = Events:WaitForChild("ClaimPlaytimeReward"),
	HoldItem = Events:WaitForChild("HoldItem"),
	MountainMelt = Events:WaitForChild("MountainMelt"),
	MountainPickup = Events:WaitForChild("MountainPickup"),
	ColdUpdate = Events:WaitForChild("ColdUpdate"),
	IndexClaim = Events:WaitForChild("IndexClaim"),
}

local Map = Workspace:WaitForChild("Map")

local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("GameConfig"))

local _nameToRarity = {}
do
	for _, v in pairs(GameConfig.ItemById) do
		if type(v) == "table" and v.name and v.rarity then
			_nameToRarity[v.name] = v.rarity
		end
	end
end

local function httpGet(url)
	local ok, res = pcall(function()
		return request({ Url = url, Method = "GET" })
	end)
	if ok and res and res.Body then
		local body = res.Body
		if body:byte(1) == 0xEF and body:byte(2) == 0xBB and body:byte(3) == 0xBF then
			body = body:sub(4)
		end
		return body
	end
	return nil
end

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

local STATE = {
	AutoMelt = false,
	AutoSell = false,
	AutoCollect = false,
	AutoBuyWeapon = false,
	AutoBuyBackpack = false,
	AutoBuyUpgrade = false,
	AutoBuyPotion = false,
	AutoSpin = false,
	AutoPlaytime = false,
	AutoIndexClaim = false,
	TeleportStage = 1,
	Noclip = false,
	InfiniteJump = false,
	ESP = false,
	ESPDistance = false,
	ESPColor = Color3.fromRGB(255, 100, 100),
	WalkSpeed = 22,
	JumpPower = 50,
	CollectRarities = { Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true, Transcendent = true, Secret = true },
}

local function getHRP()
	local c = LP.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
	local c = LP.Character
	return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getTool()
	local c = LP.Character
	if c then
		for _, v in ipairs(c:GetChildren()) do
			if v:IsA("Tool") then return v end
		end
	end
	for _, v in ipairs(LP.Backpack:GetChildren()) do
		if v:IsA("Tool") then return v end
	end
	return nil
end

local function getZoneNames()
	local names = {}
	for _, v in ipairs(Map:GetChildren()) do
		if v.Name:match("^Zone %d+$") then
			table.insert(names, v.Name)
		end
	end
	table.sort(names, function(a, b)
		return tonumber(a:match("%d+")) < tonumber(b:match("%d+"))
	end)
	return names
end

local function teleportToZone(zoneNum)
	local zone = Map:FindFirstChild("Zone " .. tostring(zoneNum))
	if zone then
		local hrp = getHRP()
		if hrp then
			local ground = zone:FindFirstChild("ZoneGround") or zone:FindFirstChildWhichIsA("BasePart")
			if ground then
				hrp.CFrame = ground.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end
end

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
end

local function updateESP()
	clearESP()
	if not (STATE.ESP and _k and _k.v and _k.i) then return end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local label = plr.Name
				if STATE.ESPDistance then
					local myHRP = getHRP()
					if myHRP then
						label = label .. " [" .. math.floor((myHRP.Position - hrp.Position).Magnitude) .. "m]"
					end
				end
				createESP(hrp, label, STATE.ESPColor)
			end
		end
	end
end

local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on and _k and _k.v and _verifyIntegrity() then
		noclipConn = RunService.Stepped:Connect(function()
			local c = LP.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

local ijConn = nil
local function setInfiniteJump(on)
	if ijConn then ijConn:Disconnect(); ijConn = nil end
	if on and _k and _k.v and _k.i then
		ijConn = UserInputService.JumpRequest:Connect(function()
			local c = LP.Character
			if c then
				local h = c:FindFirstChildWhichIsA("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
end

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "flame",
	Footer = {
		"v1.4 |",
		{ Text = "Game", Copyable = true },
		"|",
		{ Text = tostring(LP.UserId), Copyable = true },
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
})

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local ShopTab = Window:AddTab({ Name = "Shop", Icon = "shopping-cart" })
local PlayerTab = Window:AddTab({ Name = "Player", Icon = "user" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local AutoSub = MainTab:AddSubTab("Automation", "zap")
local MeltGroup = AutoSub:AddLeftGroupbox("Melt", "flame")
local SellGroup = AutoSub:AddRightGroupbox("Sell", "coins")
local CollectGroup = AutoSub:AddRightGroupbox("Collect", "package")
local SpinGroup = AutoSub:AddLeftGroupbox("Spin", "refresh-cw")
local PlaytimeGroup = AutoSub:AddRightGroupbox("Playtime", "clock")

MeltGroup:AddToggle("AutoMelt", {
	Text = "Auto Melt Ice",
	Default = false,
	Callback = function(v) STATE.AutoMelt = v end,
}):AddKeyPicker("AutoMeltKey", {
	Default = "None",
	Text = "Auto Melt Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

SellGroup:AddToggle("AutoSell", {
	Text = "Auto Sell",
	Default = false,
	Callback = function(v) STATE.AutoSell = v end,
}):AddKeyPicker("AutoSellKey", {
	Default = "None",
	Text = "Auto Sell Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

SellGroup:AddSlider("SellInterval", {
	Text = "Sell Interval",
	Default = 5,
	Min = 1,
	Max = 30,
	Rounding = 0,
	Callback = function(v) STATE.AutoSellInterval = v end,
})

SellGroup:AddButton("Sell All Now", function()
	pcall(function() Remotes.SellAll:InvokeServer() end)
end)

CollectGroup:AddToggle("AutoCollect", {
	Text = "Auto Collect Drops",
	Default = false,
	Callback = function(v) STATE.AutoCollect = v end,
})

local rarityOrder = { "Common", "Rare", "Epic", "Legendary", "Transcendent", "Secret" }
for _, rarity in ipairs(rarityOrder) do
	CollectGroup:AddToggle("Rarity_" .. rarity, {
		Text = rarity,
		Default = STATE.CollectRarities[rarity] or false,
		Callback = function(v) STATE.CollectRarities[rarity] = v end,
	})
end

CollectGroup:AddButton("Collect All Drops Now", function()
	if _k and _k.v and _k.i then
		pcall(function()
			local hrp = getHRP()
			if not hrp then return end
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("ProximityPrompt") and obj:GetAttribute("MountainIdx") and obj.Enabled then
					local parent = obj.Parent
					if parent and parent:IsA("BasePart") then
						hrp.CFrame = CFrame.new(parent.Position + Vector3.new(0, 3, 0))
						task.wait(0.2)
						local idx = obj:GetAttribute("MountainIdx")
						if idx then
							pcall(function() Remotes.MountainPickup:FireServer(idx) end)
						end
						pcall(function()
							obj:InputHoldBegin()
							task.wait(obj.HoldDuration + 0.3)
							obj:InputHoldEnd()
						end)
						task.wait(0.3)
					end
				end
			end
		end)
	end
end)

SpinGroup:AddToggle("AutoSpin", {
	Text = "Auto Spin",
	Default = false,
	Callback = function(v) STATE.AutoSpin = v end,
})

SpinGroup:AddButton("Claim Free Spin", function()
	pcall(function() Remotes.SpinClaim:FireServer() end)
end)

SpinGroup:AddButton("Roll Spin", function()
	pcall(function() Remotes.SpinRoll:InvokeServer() end)
end)

PlaytimeGroup:AddToggle("AutoPlaytime", {
	Text = "Auto Claim Playtime",
	Default = false,
	Callback = function(v) STATE.AutoPlaytime = v end,
})

PlaytimeGroup:AddButton("Claim Playtime Now", function()
	pcall(function() Remotes.ClaimPlaytimeReward:InvokeServer() end)
end)

PlaytimeGroup:AddToggle("AutoIndexClaim", {
	Text = "Auto Claim Index Stages",
	Default = false,
	Callback = function(v) STATE.AutoIndexClaim = v end,
})

PlaytimeGroup:AddButton("Claim All Index Stages", function()
	if _k and _k.v and _k.i then
		for i = 1, 40 do
			pcall(function() Remotes.IndexClaim:InvokeServer(i) end)
		end
	end
end)

local TeleSub = MainTab:AddSubTab("Teleport", "map-pin")
local TeleGroup = TeleSub:AddLeftGroupbox("Stage Teleport", "navigation")

TeleGroup:AddDropdown("TeleportDropdown", {
	Values = getZoneNames(),
	Default = "Zone 1",
	Text = "Select Stage",
	Callback = function(v)
		local num = tonumber(v:match("%d+"))
		if num then STATE.TeleportStage = num end
	end,
})

TeleGroup:AddButton("Teleport to Selected", function()
	if _k and _k.v and _k.s then
		teleportToZone(STATE.TeleportStage)
	end
end)

TeleGroup:AddButton("TP to Current Stage", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.TeleportToStage:FireServer() end)
	end
end)

local UpgradeSub = ShopTab:AddSubTab("Upgrades", "arrow-up-circle")
local UpgradeGroup = UpgradeSub:AddLeftGroupbox("Upgrades", "trending-up")

UpgradeGroup:AddToggle("AutoBuyUpgrade", {
	Text = "Auto Buy Upgrades",
	Default = false,
	Callback = function(v) STATE.AutoBuyUpgrade = v end,
})

UpgradeGroup:AddButton("Buy Melt Power", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyUpgrade:InvokeServer("melt", 1) end)
	end
end)

UpgradeGroup:AddButton("Buy Speed", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyUpgrade:InvokeServer("speed", 1) end)
	end
end)

UpgradeGroup:AddButton("Buy Warmth", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyUpgrade:InvokeServer("warmth", 1) end)
	end
end)

UpgradeGroup:AddButton("Buy Max Melt", function()
	if _k and _k.v and _k.i then
		pcall(function()
			local data = Remotes.BuyUpgrade:InvokeServer("milt", 999)
		end)
	end
end)

local WeaponSub = ShopTab:AddSubTab("Weapons", "swords")
local WeaponGroup = WeaponSub:AddLeftGroupbox("Weapons", "shield")

WeaponGroup:AddToggle("AutoBuyWeapon", {
	Text = "Auto Buy Best Weapon",
	Default = false,
	Callback = function(v) STATE.AutoBuyWeapon = v end,
})

WeaponGroup:AddButton("Buy Weapon Now", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyWeapon:InvokeServer() end)
	end
end)

local BackpackGroup = WeaponSub:AddRightGroupbox("Backpacks", "package")

BackpackGroup:AddToggle("AutoBuyBackpack", {
	Text = "Auto Buy Backpack",
	Default = false,
	Callback = function(v) STATE.AutoBuyBackpack = v end,
})

BackpackGroup:AddButton("Buy Backpack Now", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyBackpack:InvokeServer() end)
	end
end)

local PotionSub = ShopTab:AddSubTab("Potions", "droplet")
local PotionGroup = PotionSub:AddLeftGroupbox("Potions", "droplet")

PotionGroup:AddToggle("AutoBuyPotion", {
	Text = "Auto Buy Melt Potion",
	Default = false,
	Callback = function(v) STATE.AutoBuyPotion = v end,
})

PotionGroup:AddButton("Buy Melt Potion", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyPotion:InvokeServer("melt_1") end)
	end
end)

PotionGroup:AddButton("Buy Big Melt Potion", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyPotion:InvokeServer("melt_2") end)
	end
end)

PotionGroup:AddButton("Buy Luck Potion", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyPotion:InvokeServer("luck_1") end)
	end
end)

PotionGroup:AddButton("Buy Cash Potion", function()
	if _k and _k.v and _k.i then
		pcall(function() Remotes.BuyPotion:InvokeServer("coins_1") end)
	end
end)

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
}):AddKeyPicker("NoclipKey", {
	Default = "None",
	Text = "Noclip Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

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
}):AddKeyPicker("InfJumpKey", {
	Default = "None",
	Text = "Infinite Jump Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

local ESPSub = VisualsTab:AddSubTab("ESP", "eye")
local ESPGroup = ESPSub:AddLeftGroupbox("Player ESP", "users")

ESPGroup:AddToggle("ESPEnabled", {
	Text = "Enable ESP",
	Default = false,
	Callback = function(v)
		STATE.ESP = v
		if v then updateESP() else clearESP() end
	end,
}):AddKeyPicker("ESPKey", {
	Default = "None",
	Text = "ESP Key",
	Mode = "Toggle",
	SyncToggleState = true,
	NoUI = false,
})

ESPGroup:AddToggle("ESPDistance", {
	Text = "Show Distance",
	Default = true,
	Callback = function(v)
		STATE.ESPDistance = v
		if STATE.ESP then updateESP() end
	end,
})

ESPGroup:AddLabel("ESP Color"):AddColorPicker("ESPColor", {
	Default = Color3.fromRGB(255, 100, 100),
	Title = "ESP Color",
	Callback = function(v)
		STATE.ESPColor = v
		if STATE.ESP then updateESP() end
	end,
})

local WorldGroup = ESPSub:AddRightGroupbox("World", "globe")

WorldGroup:AddButton("Full Bright", function()
	if _k and _k.v and _k.i then
		game:GetService("Lighting").Brightness = 2
		game:GetService("Lighting").ClockTime = 14
	end
end)

WorldGroup:AddButton("Remove Fog", function()
	if _k and _k.v and _k.s then
		game:GetService("Lighting").FogEnd = 999999
		game:GetService("Lighting").FogStart = 0
	end
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("melttheice")
ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local MenuGroup = SettingsTab:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(v) Library.KeybindFrame.Visible = v end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = Library.ShowCustomCursor,
	Callback = function(v) Library.ShowCustomCursor = v end,
})
MenuGroup:AddButton("Test Notification", function()
	Library:Notify({ Title = "Ivory", Description = "Works!", Time = 4 })
end)
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",
	Text = "Notification Side",
	Callback = function(v) Library:SetNotifySide(v) end,
})
MenuGroup:AddSlider("UICornerSlider", {
	Text = "Corner Radius",
	Default = Library.CornerRadius,
	Min = 0,
	Max = 20,
	Rounding = 0,
	Callback = function(v) Window:SetCornerRadius(v) end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
	Default = "RightShift",
	NoUI = true,
	Text = "Menu keybind",
})
MenuGroup:AddButton("Unload", function()
	clearESP()
	setNoclip(false)
	setInfiniteJump(false)
	Workspace.Gravity = 196.2
	Library:Unload()
end)

local _meltActivated = false
local _coldLevel = 0
local _goingToFire = false
local _collectingDrop = false

local function isOnZoneGround()
	local hrp = getHRP()
	if not hrp then return false end
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Name == "ZoneGround" then
			local pos = obj.Position
			local size = obj.Size
			local lp = hrp.Position
			if math.abs(lp.X - pos.X) < size.X / 2 + 10
				and math.abs(lp.Z - pos.Z) < size.Z / 2 + 10
				and math.abs(lp.Y - pos.Y) < 30 then
				return true
			end
		end
	end
	return false
end

local function getMedals()
	local ok, v = pcall(function()
		return LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Medals") and LP.leaderstats.Medals.Value
	end)
	return ok and v or 0
end

local function getCash()
	local ok, v = pcall(function()
		return LP:FindFirstChild("leaderstats") and LP.leaderstats:FindFirstChild("Cash") and LP.leaderstats.Cash.Value
	end)
	return ok and v or 0
end

local _ownedWeapons = {}
local _ownedBackpacks = {}
local _lastOwnedCheck = 0

local function findNextWeapon()
	local cash = getCash()
	for _, w in ipairs(GameConfig.WEAPONS) do
		if w.cost > 0 and w.cost <= cash and not _ownedWeapons[w.id] then
			local ok, res = pcall(function() return Remotes.BuyWeapon:InvokeServer(w.id) end)
			if ok and res == true then
				_ownedWeapons[w.id] = true
				return w.id
			elseif ok then
				_ownedWeapons[w.id] = true
			end
		end
	end
	return nil
end

local function findNextBackpack()
	local cash = getCash()
	for _, b in ipairs(GameConfig.BACKPACKS) do
		if b.cost > 0 and b.cost <= cash and not _ownedBackpacks[b.id] then
			local ok, res = pcall(function() return Remotes.BuyBackpack:InvokeServer(b.id) end)
			if ok and res == true then
				_ownedBackpacks[b.id] = true
				return b.id
			elseif ok then
				_ownedBackpacks[b.id] = true
			end
		end
	end
	return nil
end

local _upgradeFailCount = 0

local function findNearestWarmthFire()
	local hrp = getHRP()
	if not hrp then return nil end
	local best, bestDist = nil, math.huge
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("Model") and obj.Name == "WarmthFire" then
			local wz = obj:FindFirstChild("WarmZone")
			if wz and wz:IsA("BasePart") then
				local d = (wz.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					best = wz
				end
			end
		end
	end
	return best
end

local function findNearestDrop()
	local hrp = getHRP()
	if not hrp then return nil, math.huge end
	local best, bestDist = nil, math.huge
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("ProximityPrompt") and obj.Name == "DropPrompt" and obj.Enabled then
			local parent = obj.Parent
			if parent and parent:IsA("BasePart") then
				local rarity = _nameToRarity[parent.Name] or "Common"
				if STATE.CollectRarities[rarity] then
					local d = (parent.Position - hrp.Position).Magnitude
					if d < bestDist then
						bestDist = d
						best = parent
					end
				end
			end
		end
	end
	return best, bestDist
end

local function getCurrentStage()
	local hrp = getHRP()
	if not hrp then return 1 end
	local bestLevel, bestDist = 1, math.huge
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("MountainWall") then
			local level = obj:GetAttribute("Level")
			if level then
				local d = (obj.Position - hrp.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestLevel = level
				end
			end
		end
	end
	return bestLevel
end

local function aimCameraAtIceWall(level)
	local hrp = getHRP()
	if not hrp then return end
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("MountainWall") and obj:GetAttribute("Level") == level then
			local cam = workspace.CurrentCamera
			local eyePos = hrp.Position + Vector3.new(0, 2, 0)
			cam.CFrame = CFrame.new(eyePos, Vector3.new(obj.Position.X, eyePos.Y, obj.Position.Z))
			return true
		end
	end
	return false
end

local function equipBestTool()
	local LP = game.Players.LocalPlayer
	local char = LP.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not humanoid then return end
	if char:FindFirstChildWhichIsA("Tool") then return end
	local backpack = LP:FindFirstChild("Backpack")
	if backpack then
		local tool = backpack:FindFirstChildWhichIsA("Tool")
		if tool then
			humanoid:EquipTool(tool)
		end
	end
end

local function activateGameAutoMelt()
	LP:SetAttribute("Set_AutoMeltBtn", true)
	LP:SetAttribute("AutoMelt", true)

	equipBestTool()

	local level = getCurrentStage()
	aimCameraAtIceWall(level)

	task.wait(0.5)
	local HUD = LP:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
	if not HUD then return end
	local btn = HUD:FindFirstChild("AutoMeltBTN", true)
	if btn and btn.Visible then
		local onBtn = btn:FindFirstChild("AutoMeltOn", true)
		local offClip = btn:FindFirstChild("AutoMeltOffClip", true)
		if onBtn and onBtn.Visible then
			local pos = onBtn.AbsolutePosition + onBtn.AbsoluteSize / 2
			mousemoveabs(pos.X, pos.Y)
			task.wait(0.1)
			mouse1click()
			_meltActivated = true
		elseif offClip and offClip.Visible then
			_meltActivated = true
		end
	end
end

local function teleportToCurrentStage()
	local hrp = getHRP()
	if not hrp then return end
	local level = getCurrentStage()
	for _, obj in ipairs(Map:GetDescendants()) do
		if obj:IsA("BasePart") and obj:GetAttribute("MountainWall") and obj:GetAttribute("Level") == level then
			local icePos = obj.Position
			local iceSize = obj.Size
			local spawnZ = icePos.Z - iceSize.Z / 2 - 15
			hrp.CFrame = CFrame.new(icePos.X, 5, spawnZ)
			local humanoid = LP.Character and LP.Character:FindFirstChild("Humanoid")
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
			return true
		end
	end
	return false
end

task.spawn(function()
	while true do
		task.wait(0.5)
		if STATE.AutoMelt and _k and _k.v and _k.i then
			pcall(function()
				if _goingToFire then return end
				local hrp = getHRP()
				if not hrp then return end

				if _coldLevel >= 35 then
					_goingToFire = true
					local fire = findNearestWarmthFire()
					if fire then
						local firePos = fire.Position
						hrp.CFrame = CFrame.new(firePos.X + 6, firePos.Y + 3, firePos.Z + 6)
						local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
						if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
						while _coldLevel > 5 do
							task.wait(1)
							if not (_k and _k.v and _k.i) then break end
						end
					end
					_goingToFire = false
					return
				end

				if not isOnZoneGround() then
					teleportToCurrentStage()
					task.wait(0.5)
					local hum = LP.Character and LP.Character:FindFirstChild("Humanoid")
					if hum then hum:ChangeState(Enum.HumanoidStateType.Running) end
				end
				equipBestTool()
				Remotes.MountainMelt:FireServer()
			end)
		end
	end
end)

local function isBagFull()
	local ok, result = pcall(function()
		local HUD = LP:WaitForChild("PlayerGui"):WaitForChild("HUD", 5)
		if not HUD then return false end

		local toast = HUD:FindFirstChild("notificationToast", true)
		if toast then
			local ml = toast:FindFirstChild("MedalsLabel", true)
			if ml and ml:IsA("TextLabel") and ml.Text:find("FULL") then
				return true
			end
		end

		local amt = HUD:FindFirstChild("Boosts", true)
		if amt then
			amt = amt:FindFirstChild("backpack", true)
			if amt then
				amt = amt:FindFirstChild("amount", true)
				if amt and amt:IsA("TextLabel") then
					local cur, max = amt.Text:match("(%d+)/(%d+)")
					if cur and max then
						return tonumber(cur) >= tonumber(max)
					end
				end
			end
		end

		return false
	end)
	return ok and result
end

task.spawn(function()
	while true do
		task.wait(1)
		if STATE.AutoSell and _k and _k.v and _k.s then
			pcall(function()
				if isBagFull() then
					Remotes.SellAll:InvokeServer()
					task.wait(2)
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(0.5)
		if STATE.AutoCollect and _k and _k.v and _k.i then
			pcall(function()
				local hrp = getHRP()
				if not hrp then return end
				if _collectingDrop then return end

				local drop, dist = findNearestDrop()
				if drop and dist < 100 then
					_collectingDrop = true

					local savedPos = hrp.CFrame
					hrp.CFrame = CFrame.new(drop.Position + Vector3.new(0, 3, 0))
					task.wait(0.2)

					local prompt = drop:FindFirstChildWhichIsA("ProximityPrompt")
					if prompt and prompt.Enabled then
						local idx = prompt:GetAttribute("MountainIdx")
						if idx then
							pcall(function() Remotes.MountainPickup:FireServer(idx) end)
						end
						pcall(function()
							prompt:InputHoldBegin()
							task.wait(prompt.HoldDuration + 0.3)
							prompt:InputHoldEnd()
						end)
					end

					task.wait(0.3)
					_collectingDrop = false
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoBuyWeapon and _k and _k.v and _k.i then
			pcall(function() findNextWeapon() end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoBuyBackpack and _k and _k.v and _k.i then
			pcall(function() findNextBackpack() end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(STATE.AutoBuyUpgrade and _upgradeFailCount > 0 and math.min(30, 5 * _upgradeFailCount) or 5)
		if STATE.AutoBuyUpgrade and _k and _k.v and _k.i then
			pcall(function()
				local medals = getMedals()
				local bought = false
				for _, key in ipairs({"speed", "melt", "warmth"}) do
					local ok, res = Remotes.BuyUpgrade:InvokeServer(key, 1)
					if ok and res then
						local success = (type(res) == "table") and (res.success ~= false) or (res == true)
						if success then
							bought = true
							_upgradeFailCount = 0
						end
					end
				end
				if not bought then
					_upgradeFailCount = _upgradeFailCount + 1
				end
			end)
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(5)
		if STATE.AutoBuyPotion and _k and _k.v and _k.i then
			pcall(function()
				local cash = getCash()
				for i = #GameConfig.POTIONS, 1, -1 do
					local p = GameConfig.POTIONS[i]
					if cash >= p.cost then
						Remotes.BuyPotion:InvokeServer(p.id)
						break
					end
				end
			end)
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

task.spawn(function()
	while true do
		task.wait(30)
		if STATE.AutoIndexClaim and _k and _k.v and _k.i then
			for i = 1, 40 do
				pcall(function() Remotes.IndexClaim:InvokeServer(i) end)
			end
		end
	end
end)

Events:WaitForChild("ColdUpdate").OnClientEvent:Connect(function(value)
	_coldLevel = tonumber(value) or 0
end)

LP.CharacterAdded:Connect(function(char)
	_meltActivated = false
	_goingToFire = false
	_collectingDrop = false

	task.wait(2)
	local h = char:WaitForChild("Humanoid", 5)
	if h and _k and _k.v and _k.s then
		h.WalkSpeed = STATE.WalkSpeed
	end
	if h and _k and _k.v and _k.i then
		h.JumpPower = STATE.JumpPower
	end

	if STATE.AutoMelt and _k and _k.v and _k.i then
		task.wait(1)
		if not isOnZoneGround() then
			teleportToCurrentStage()
			task.wait(1)
		end
		equipBestTool()
	end
end)

pcall(function()
	Library:Notify({
		Title = "Ivory",
		Description = "Melt The Ice loaded!",
		Type = "Success",
		Time = 5,
	})
end)
