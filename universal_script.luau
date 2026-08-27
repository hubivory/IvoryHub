--[[ ============================================================================
  Ivory Hub | World Class Edition v2
  Dark liquid-glass UI. Key fix from v1: shadow/glow are no longer children of
  the panel they sit behind (a child can never render behind its own parent's
  fill — that's what caused the hard "picture frame" artifacts). They now live
  as siblings inside a transparent PanelWrapper, with the panel layered above.
============================================================================ ]]

-- ============================================================================
-- SERVICES
-- ============================================================================

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- CLEANUP
-- ============================================================================

for _, obj in ipairs(CoreGui:GetChildren()) do
	if obj.Name == "IvorySplash" then
		obj:Destroy()
	end
end

-- ============================================================================
-- GAME DETECTION
-- ============================================================================

local PlaceId = game.PlaceId
local GameName = tostring(PlaceId)
pcall(function()
	GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

local GameScripts = {
	[7243409883] = { name = "Elemental Magic Arena", file = "games/ElementalMagicArena.luau" },
	[116497287371701] = { name = "Karinderya", file = "games/Karinderya.luau" },
	[99521272836282] = { name = "Final Swarm", file = "games/FinalSwarm.luau" },
	[79787558257549] = { name = "Final Swarm", file = "games/FinalSwarm.luau" },
	[95919006508862] = { name = "Melt The Ice", file = "games/MeltTheIce.luau" },
	[1962086868] = { name = "Tower of Hell", file = "games/Towerofhell.luau" },
	[138501044883253] = { name = "Build A Burger", file = "games/BuildABurger.luau" },
	[105963809208632] = { name = "Build A Burger", file = "games/BuildABurger.luau" },
	[100293509865504] = { name = "Catch A Billion Ducks", file = "games/CatchABillionDucks.luau" },
	[120617974337690] = { name = "Catch A Billion Ducks", file = "games/CatchABillionDucks.luau" },
	[137363360166684] = { name = "Rocks RNG", file = "games/RocksRNG.luau" },
	[9772878203] = { name = "Floppa 2", file = "games/Floppa2.luau" },
	[13772394625] = { name = "Blade Ball", file = "games/Bladeball.luau" },
	[142823291] = { name = "Murder Mystery 2", file = "games/MM2.luau" },
}

local DetectedGame = GameScripts[PlaceId]

-- ============================================================================
-- DESIGN TOKENS
-- ============================================================================

local Tokens = {
	PanelBase = Color3.fromRGB(27, 24, 38),
	SurfaceLow = Color3.fromRGB(255, 255, 255),
	Border = Color3.fromRGB(255, 255, 255),
	BorderAccent = Color3.fromRGB(196, 178, 255),
	TextPrimary = Color3.fromRGB(246, 244, 251),
	TextSecondary = Color3.fromRGB(174, 168, 195),
	TextTertiary = Color3.fromRGB(112, 106, 134),
	Accent = Color3.fromRGB(157, 130, 250),
	AccentBright = Color3.fromRGB(196, 178, 255),
	Success = Color3.fromRGB(101, 224, 152),
	TrafficRed = Color3.fromRGB(255, 95, 87),
	TrafficYellow = Color3.fromRGB(255, 189, 46),
	TrafficGreen = Color3.fromRGB(39, 200, 100),
	Shadow = Color3.fromRGB(4, 3, 8),
}

-- ============================================================================
-- GLOW / SHADOW STACK — a soft blurred edge built from several plain Frames
-- instead of a single image asset. Multiple layers, each slightly larger and
-- more transparent than the last, read as a smooth gradient falloff without
-- gambling on an external texture's actual pixel content or 9-slice geometry.
-- ============================================================================

local function createGlowStack(parent, color, layers, innerTransparency, outerTransparency, cornerBase, cornerStep, sizeStep, zIndexBase, circular)
	local stack = {}
	for i = 1, layers do
		local f = Instance.new("Frame")
		f.BackgroundColor3 = color
		f.BackgroundTransparency = 1
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.new(0.5, 0, 0.5, 0)
		f.Size = UDim2.new(1, sizeStep * i, 1, sizeStep * i)
		f.ZIndex = zIndexBase - i
		f.Parent = parent

		local c = Instance.new("UICorner")
		c.CornerRadius = circular and UDim.new(1, 0) or UDim.new(0, cornerBase + cornerStep * i)
		c.Parent = f

		local target = (layers > 1) and (innerTransparency + (i - 1) / (layers - 1) * (outerTransparency - innerTransparency)) or innerTransparency
		table.insert(stack, { frame = f, target = target })
	end
	return stack
end

local function setGlowStack(stack, info, visible)
	for _, layer in ipairs(stack) do
		TweenService:Create(layer.frame, info, { BackgroundTransparency = visible and layer.target or 1 }):Play()
	end
end

-- ============================================================================
-- ACRYLIC GRAIN — a static field of 1px dots (alternating light/dark, near-
-- invisible) clipped to the panel's rounded shape. This is the texture that
-- reads as "frosted acrylic" rather than a flat gradient tint.
-- ============================================================================

local function addGrain(parent, cornerRadiusPx, widthPx, heightPx, count)
	local container = Instance.new("Frame")
	container.BackgroundTransparency = 1
	container.Size = UDim2.new(1, 0, 1, 0)
	container.ClipsDescendants = true
	container.ZIndex = 2
	container.Parent = parent

	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, cornerRadiusPx)
	cc.Parent = container

	for _ = 1, count do
		local dot = Instance.new("Frame")
		local light = math.random() > 0.5
		dot.BackgroundColor3 = light and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(0, 0, 0)
		dot.BackgroundTransparency = 0.94 + math.random() * 0.045
		dot.BorderSizePixel = 0
		dot.Size = UDim2.new(0, 1, 0, 1)
		dot.Position = UDim2.new(0, math.random(0, widthPx), 0, math.random(0, heightPx))
		dot.ZIndex = 2
		dot.Parent = container
	end

	return container
end

-- ============================================================================
-- BLOSSOM MARK — the Ivory icon, built entirely from primitives (five petal
-- ovals arranged radially around a center dot) instead of an external image
-- asset. Several of the previously-used rbxassetid icons turned out to be
-- Roblox's own internal UI glyphs (one rendered as a plain dropdown chevron,
-- indistinguishable from this UI's own arrow affordance) or simply broken —
-- an asset-id gamble that failed twice now (the shadow texture earlier, the
-- icon set this time). A vector mark can't 404 and can't accidentally match
-- an unrelated control; it also ties directly into the falling sakura petals.
-- ============================================================================

local function createBlossomMark(parent, diameter, color, zIndex)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(0, diameter, 0, diameter)
	container.BackgroundTransparency = 1
	container.ZIndex = zIndex
	container.Parent = parent

	local parts = {}
	local petalCount = 5
	local petalW = diameter * 0.34
	local petalH = diameter * 0.52
	local radius = diameter * 0.2

	for i = 0, petalCount - 1 do
		local angle = (360 / petalCount) * i - 90
		local rad = math.rad(angle)

		local petal = Instance.new("Frame")
		petal.AnchorPoint = Vector2.new(0.5, 0.5)
		petal.Position = UDim2.new(0.5, math.cos(rad) * radius, 0.5, math.sin(rad) * radius)
		petal.Size = UDim2.new(0, petalW, 0, petalH)
		petal.Rotation = angle + 90
		petal.BackgroundColor3 = color
		petal.BackgroundTransparency = 1
		petal.BorderSizePixel = 0
		petal.ZIndex = zIndex
		petal.Parent = container

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = petal

		table.insert(parts, petal)
	end

	local center = Instance.new("Frame")
	center.AnchorPoint = Vector2.new(0.5, 0.5)
	center.Position = UDim2.new(0.5, 0, 0.5, 0)
	center.Size = UDim2.new(0, diameter * 0.24, 0, diameter * 0.24)
	center.BackgroundColor3 = color
	center.BackgroundTransparency = 1
	center.BorderSizePixel = 0
	center.ZIndex = zIndex + 1
	center.Parent = container

	local centerCorner = Instance.new("UICorner")
	centerCorner.CornerRadius = UDim.new(1, 0)
	centerCorner.Parent = center

	table.insert(parts, center)

	return container, parts
end

local function fadeBlossom(parts, info, transparent)
	for _, p in ipairs(parts) do
		TweenService:Create(p, info, { BackgroundTransparency = transparent }):Play()
	end
end

local function recolorBlossom(parts, info, color)
	for _, p in ipairs(parts) do
		TweenService:Create(p, info, { BackgroundColor3 = color }):Play()
	end
end

-- ============================================================================
-- SCREEN SETUP
-- ============================================================================

local BackgroundBlur = Instance.new("BlurEffect")
BackgroundBlur.Size = 0
BackgroundBlur.Parent = Lighting

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IvorySplash"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true

-- ============================================================================
-- AMBIENT BACKDROP — restrained: two slow blooms, a sparse field of motes
-- ============================================================================

local AmbientLayer = Instance.new("Frame")
AmbientLayer.Name = "AmbientLayer"
AmbientLayer.Size = UDim2.new(1, 0, 1, 0)
AmbientLayer.BackgroundTransparency = 1
AmbientLayer.Parent = ScreenGui
AmbientLayer.ZIndex = 1

local function makeAmbientBloom(color, size, startPos)
	local bloomStack = createGlowStack(AmbientLayer, color, 4, 0.9, 0.97, 0, 0, 0, 1, true)
	for _, l in ipairs(bloomStack) do
		l.frame.Size = UDim2.new(0, size, 0, size)
		l.frame.Position = startPos
		l.frame.AnchorPoint = Vector2.new(0, 0)
	end
	return bloomStack, size
end

local bloomAStack, bloomASize = makeAmbientBloom(Tokens.Accent, 900, UDim2.new(0.08, 0, 0.12, 0))
local bloomBStack, bloomBSize = makeAmbientBloom(Color3.fromRGB(110, 150, 255), 700, UDim2.new(0.78, 0, 0.62, 0))

local function moveBloom(stack, pos)
	for _, l in ipairs(stack) do
		TweenService:Create(l.frame, TweenInfo.new(9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { Position = pos }):Play()
	end
end

task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		moveBloom(bloomAStack, UDim2.new(0.16, 0, 0.24, 0))
		moveBloom(bloomBStack, UDim2.new(0.7, 0, 0.5, 0))
		task.wait(9.5)
		moveBloom(bloomAStack, UDim2.new(0.08, 0, 0.1, 0))
		moveBloom(bloomBStack, UDim2.new(0.8, 0, 0.68, 0))
		task.wait(10)
	end
end)

-- Motes drift upward, driven by RenderStepped with real delta-time so motion
-- stays smooth and frame-rate independent (a task.wait loop drifts/stutters
-- under load; a render-synced connection doesn't).
local motes = {}
for _ = 1, 14 do
	local mote = Instance.new("Frame")
	mote.Size = UDim2.new(0, math.random(2, 3), 0, math.random(2, 3))
	mote.BackgroundColor3 = Tokens.TextPrimary
	mote.BackgroundTransparency = 0.88
	mote.BorderSizePixel = 0
	mote.ZIndex = 2
	mote.Parent = AmbientLayer

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = mote

	table.insert(motes, {
		frame = mote,
		x = math.random(0, 1280),
		y = math.random(0, 800),
		vy = -math.random(30, 70),
	})
end

-- ============================================================================
-- SAKURA PETALS — two depth layers: most drift behind the glass panel (in the
-- ambient layer), a handful drift in front of it, so the panel reads as
-- something petals fall PAST rather than a flat sticker on top of them.
-- Built from primitives (rotated oval Frames), not an external image asset —
-- guaranteed to render correctly, unlike a gambled-on texture id.
-- ============================================================================

local PETAL_COLORS = {
	Color3.fromRGB(244, 194, 210), -- soft sakura pink
	Color3.fromRGB(232, 170, 194), -- deeper blossom pink
	Color3.fromRGB(214, 160, 196), -- plum blossom
}

local FrontPetalLayer = Instance.new("Frame")
FrontPetalLayer.Name = "FrontPetalLayer"
FrontPetalLayer.Size = UDim2.new(1, 0, 1, 0)
FrontPetalLayer.BackgroundTransparency = 1
FrontPetalLayer.ZIndex = 40
FrontPetalLayer.Parent = ScreenGui

local petals = {}

local function makePetal(parent, big)
	local w = big and math.random(9, 13) or math.random(6, 9)
	local h = w * 0.62

	local petal = Instance.new("Frame")
	petal.Size = UDim2.new(0, w, 0, h)
	petal.BackgroundColor3 = PETAL_COLORS[math.random(1, #PETAL_COLORS)]
	petal.BackgroundTransparency = 1
	petal.BorderSizePixel = 0
	petal.ZIndex = parent == FrontPetalLayer and 40 or 2
	petal.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = petal

	-- a soft inner crease line down the middle sells the "petal" silhouette
	local crease = Instance.new("Frame")
	crease.AnchorPoint = Vector2.new(0.5, 0.5)
	crease.Size = UDim2.new(0.62, 0, 0.94, 0)
	crease.Position = UDim2.new(0.5, 0, 0.5, 0)
	crease.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	crease.BackgroundTransparency = 0.75
	crease.BorderSizePixel = 0
	crease.ZIndex = petal.ZIndex
	crease.Parent = petal
	local creaseCorner = Instance.new("UICorner")
	creaseCorner.CornerRadius = UDim.new(1, 0)
	creaseCorner.Parent = crease

	local restTransparency = big and (0.25 + math.random() * 0.15) or (0.45 + math.random() * 0.2)

	table.insert(petals, {
		frame = petal,
		x = math.random(0, 1280),
		y = math.random(-800, 0),
		fallSpeed = big and math.random(34, 52) or math.random(22, 38),
		swayAmp = math.random(18, 46),
		swayFreq = 0.4 + math.random() * 0.6,
		swayPhase = math.random() * 6.28,
		spin = (math.random() - 0.5) * 70,
		rotation = math.random(0, 360),
		restTransparency = restTransparency,
	})

	TweenService:Create(petal, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = restTransparency }):Play()
end

for _ = 1, 20 do
	makePetal(AmbientLayer, math.random() > 0.5)
end
for _ = 1, 6 do
	makePetal(FrontPetalLayer, true)
end

local ambientClock = 0
local ambientConn
ambientConn = RunService.RenderStepped:Connect(function(dt)
	if not (ScreenGui and ScreenGui.Parent) then
		if ambientConn then ambientConn:Disconnect() end
		return
	end
	ambientClock = ambientClock + dt

	for _, m in ipairs(motes) do
		m.y = m.y + m.vy * dt
		if m.y < -10 then
			m.y = 810
			m.x = math.random(0, 1280)
		end
		m.frame.Position = UDim2.new(0, m.x, 0, m.y)
	end

	for _, p in ipairs(petals) do
		p.y = p.y + p.fallSpeed * dt
		p.rotation = p.rotation + p.spin * dt
		local sway = math.sin(ambientClock * p.swayFreq + p.swayPhase) * p.swayAmp
		if p.y > 820 then
			p.y = math.random(-120, -20)
			p.x = math.random(0, 1280)
		end
		p.frame.Position = UDim2.new(0, p.x + sway, 0, p.y)
		p.frame.Rotation = p.rotation
	end
end)

-- ============================================================================
-- ROBUST DRAG — dragInput-tracked pattern
-- ============================================================================

local function makeDraggable(frame, handle)
	local dragging = false
	local dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- ============================================================================
-- PANEL WRAPPER — the thing that actually gets centered/dragged/scaled.
-- Transparent, no fill of its own, so its children (shadow behind, panel in
-- front) can layer correctly without one painting over the other's content.
-- ============================================================================

local PANEL_W, PANEL_H = 480, 392

local PanelWrapper = Instance.new("Frame")
PanelWrapper.Name = "PanelWrapper"
PanelWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
PanelWrapper.Size = UDim2.new(0, PANEL_W, 0, PANEL_H)
PanelWrapper.Position = UDim2.new(0.5, 0, 0.5, 0)
PanelWrapper.BackgroundTransparency = 1
PanelWrapper.Parent = ScreenGui
PanelWrapper.ZIndex = 10

local PanelScale = Instance.new("UIScale")
PanelScale.Scale = 0.9
PanelScale.Parent = PanelWrapper

-- Layered elevation shadow, sits BEHIND the panel. Many layers with SMALL
-- size/corner steps (not a few big jumps) so the falloff actually reads as a
-- smooth gradient instead of visible concentric rings — a few big steps is
-- what produced the "picture frame" / "onion ring" artifact previously; many
-- small steps is the correct way to fake a soft blur out of flat layers.
-- Kept deliberately subtle (high transparency floor, small max spread) —
-- this is ambient elevation, not a decorative halo.
local shadowStack = createGlowStack(PanelWrapper, Tokens.Shadow, 10, 0.78, 0.97, 20, 2, 4, 5)

-- ============================================================================
-- MAIN GLASS PANEL — fills PanelWrapper exactly, painted ABOVE the shadow
-- stack so only the outward-bleeding margin of the shadow is ever visible.
-- ============================================================================

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(1, 0, 1, 0)
MainFrame.Position = UDim2.new(0, 0, 0, 0)
MainFrame.BackgroundColor3 = Tokens.PanelBase
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.ZIndex = 20
MainFrame.Parent = PanelWrapper

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 20)
MainCorner.Parent = MainFrame

local GlassStroke = Instance.new("UIStroke")
GlassStroke.Color = Tokens.Border
GlassStroke.Transparency = 1
GlassStroke.Thickness = 1.5
GlassStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
GlassStroke.Parent = MainFrame

local GlassGradient = Instance.new("UIGradient")
GlassGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(205, 200, 224)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 145, 175)),
})
GlassGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.82),
	NumberSequenceKeypoint.new(0.5, 0.95),
	NumberSequenceKeypoint.new(1, 0.88),
})
GlassGradient.Rotation = 90
GlassGradient.Parent = MainFrame

-- Acrylic grain, clipped to the panel's own rounded corners (ZIndex 2 — just
-- above the bare background, well below every piece of real content)
addGrain(MainFrame, 20, PANEL_W, PANEL_H, 260)

-- Crisp 1px specular highlight at the top edge
local TopHighlight = Instance.new("Frame")
TopHighlight.Size = UDim2.new(1, -40, 0, 1)
TopHighlight.Position = UDim2.new(0, 20, 0, 1)
TopHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopHighlight.BackgroundTransparency = 1
TopHighlight.BorderSizePixel = 0
TopHighlight.ZIndex = 12
TopHighlight.Parent = MainFrame

-- ============================================================================
-- CHROME BAR — invisible drag handle across the top of the panel
-- ============================================================================

local ChromeBar = Instance.new("Frame")
ChromeBar.Name = "ChromeBar"
ChromeBar.Size = UDim2.new(1, 0, 0, 44)
ChromeBar.Position = UDim2.new(0, 0, 0, 0)
ChromeBar.BackgroundTransparency = 1
ChromeBar.ZIndex = 11
ChromeBar.Parent = MainFrame

makeDraggable(PanelWrapper, ChromeBar)

-- ============================================================================
-- CLOSE BUTTON — a single quiet glass control, no OS chrome mimicry.
-- X drawn from two rotated bars, never a font glyph (zero fallback risk).
-- ============================================================================

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -46, 0, 14)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.BackgroundTransparency = 1
CloseButton.Text = ""
CloseButton.AutoButtonColor = false
CloseButton.ZIndex = 15
CloseButton.Parent = MainFrame

local CloseButtonCorner = Instance.new("UICorner")
CloseButtonCorner.CornerRadius = UDim.new(1, 0)
CloseButtonCorner.Parent = CloseButton

local CloseButtonStroke = Instance.new("UIStroke")
CloseButtonStroke.Color = Tokens.Border
CloseButtonStroke.Transparency = 1
CloseButtonStroke.Thickness = 1
CloseButtonStroke.Parent = CloseButton

local function closeBar(rotation)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0.5)
	bar.Size = UDim2.new(0, 11, 0, 1.5)
	bar.Position = UDim2.new(0.5, 0, 0.5, 0)
	bar.BackgroundColor3 = Tokens.TextSecondary
	bar.BackgroundTransparency = 1
	bar.BorderSizePixel = 0
	bar.Rotation = rotation
	bar.ZIndex = 16
	bar.Parent = CloseButton
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = bar
	return bar
end

local closeBarA = closeBar(45)
local closeBarB = closeBar(-45)

CloseButton.MouseEnter:Connect(function()
	TweenService:Create(CloseButton, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.85 }):Play()
	TweenService:Create(CloseButtonStroke, TweenInfo.new(0.18), { Transparency = 0.55 }):Play()
	TweenService:Create(closeBarA, TweenInfo.new(0.18), { BackgroundColor3 = Tokens.TextPrimary }):Play()
	TweenService:Create(closeBarB, TweenInfo.new(0.18), { BackgroundColor3 = Tokens.TextPrimary }):Play()
end)
CloseButton.MouseLeave:Connect(function()
	TweenService:Create(CloseButton, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(CloseButtonStroke, TweenInfo.new(0.18), { Transparency = 1 }):Play()
	TweenService:Create(closeBarA, TweenInfo.new(0.18), { BackgroundColor3 = Tokens.TextSecondary }):Play()
	TweenService:Create(closeBarB, TweenInfo.new(0.18), { BackgroundColor3 = Tokens.TextSecondary }):Play()
end)

-- ============================================================================
-- ICON, TITLE, STATUS ROW — all horizontally centered via AnchorPoint, not
-- manual half-width math, so they stay perfectly centered regardless of size.
-- ============================================================================

local IconChip = Instance.new("Frame")
IconChip.AnchorPoint = Vector2.new(0.5, 0)
IconChip.Size = UDim2.new(0, 56, 0, 56)
IconChip.Position = UDim2.new(0.5, 0, 0, 52)
IconChip.BackgroundColor3 = Tokens.SurfaceLow
IconChip.BackgroundTransparency = 1
IconChip.ZIndex = 15
IconChip.Parent = MainFrame

local IconChipCorner = Instance.new("UICorner")
IconChipCorner.CornerRadius = UDim.new(0, 17)
IconChipCorner.Parent = IconChip

local IconChipStroke = Instance.new("UIStroke")
IconChipStroke.Color = Tokens.Border
IconChipStroke.Transparency = 1
IconChipStroke.Thickness = 1.25
IconChipStroke.Parent = IconChip

local IconChipGradient = Instance.new("UIGradient")
IconChipGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 70, 110)),
})
IconChipGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.85),
	NumberSequenceKeypoint.new(1, 0.94),
})
IconChipGradient.Rotation = 105
IconChipGradient.Parent = IconChip

local Icon, IconParts = createBlossomMark(IconChip, 28, Tokens.AccentBright, 16)
Icon.AnchorPoint = Vector2.new(0.5, 0.5)
Icon.Position = UDim2.new(0.5, 0, 0.5, 0)

-- Gentle float, driven by RenderStepped (frame-locked, no task.wait drift)
do
	local floatT = 0
	local baseY = 52
	local floatConn
	floatConn = RunService.RenderStepped:Connect(function(dt)
		if not (ScreenGui and ScreenGui.Parent) then
			if floatConn then floatConn:Disconnect() end
			return
		end
		floatT = floatT + dt
		IconChip.Position = UDim2.new(0.5, 0, 0, baseY + math.sin(floatT * 0.9) * 3)
	end)
end

local Title = Instance.new("TextLabel")
Title.AnchorPoint = Vector2.new(0.5, 0)
Title.Size = UDim2.new(0, 300, 0, 36)
Title.Position = UDim2.new(0.5, 0, 0, 124)
Title.BackgroundTransparency = 1
Title.Text = "Ivory"
Title.TextColor3 = Tokens.TextPrimary
Title.Font = Enum.Font.GothamMedium
Title.TextSize = 26
Title.TextTransparency = 1
Title.ZIndex = 15
Title.Parent = MainFrame

-- Status row: a "beeping" live dot + label — a splash screen that reads as
-- running software, not a static poster.
-- AutomaticSize.X shrinks the row to its actual content width, so the
-- AnchorPoint(0.5, 0) centering is always exact regardless of label length —
-- no more guessing a fixed width and ending up visually off-center.
local StatusRow = Instance.new("Frame")
StatusRow.AnchorPoint = Vector2.new(0.5, 0)
StatusRow.AutomaticSize = Enum.AutomaticSize.X
StatusRow.Size = UDim2.new(0, 0, 0, 16)
StatusRow.Position = UDim2.new(0.5, 0, 0, 164)
StatusRow.BackgroundTransparency = 1
StatusRow.ZIndex = 15
StatusRow.Parent = MainFrame

local StatusLayout = Instance.new("UIListLayout")
StatusLayout.FillDirection = Enum.FillDirection.Horizontal
StatusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
StatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
StatusLayout.Padding = UDim.new(0, 7)
StatusLayout.Parent = StatusRow

-- Ping ring sits behind the dot in its own fixed-size cell so the list layout
-- doesn't reflow when the ring expands
local StatusDotCell = Instance.new("Frame")
StatusDotCell.Size = UDim2.new(0, 16, 0, 16)
StatusDotCell.BackgroundTransparency = 1
StatusDotCell.LayoutOrder = 1
StatusDotCell.ZIndex = 15
StatusDotCell.Parent = StatusRow

local StatusPing = Instance.new("Frame")
StatusPing.AnchorPoint = Vector2.new(0.5, 0.5)
StatusPing.Position = UDim2.new(0.5, 0, 0.5, 0)
StatusPing.Size = UDim2.new(0, 6, 0, 6)
StatusPing.BackgroundColor3 = Tokens.Success
StatusPing.BackgroundTransparency = 1
StatusPing.ZIndex = 14
StatusPing.Parent = StatusDotCell

local StatusPingCorner = Instance.new("UICorner")
StatusPingCorner.CornerRadius = UDim.new(1, 0)
StatusPingCorner.Parent = StatusPing

local StatusDot = Instance.new("Frame")
StatusDot.AnchorPoint = Vector2.new(0.5, 0.5)
StatusDot.Position = UDim2.new(0.5, 0, 0.5, 0)
StatusDot.Size = UDim2.new(0, 6, 0, 6)
StatusDot.BackgroundColor3 = Tokens.Success
StatusDot.BackgroundTransparency = 1
StatusDot.ZIndex = 15
StatusDot.Parent = StatusDotCell

local StatusDotCorner = Instance.new("UICorner")
StatusDotCorner.CornerRadius = UDim.new(1, 0)
StatusDotCorner.Parent = StatusDot

local StatusLabel = Instance.new("TextLabel")
StatusLabel.AutomaticSize = Enum.AutomaticSize.X
StatusLabel.Size = UDim2.new(0, 0, 1, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "ready to load"
StatusLabel.TextColor3 = Tokens.TextSecondary
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextTransparency = 1
StatusLabel.LayoutOrder = 2
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.ZIndex = 15
StatusLabel.Parent = StatusRow

-- The "beep": a quick brightness/scale pop on the dot in sync with an
-- expanding, fading ping ring — reads as a heartbeat, not a slow breathe.
local statusBeeping = true
task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		if statusBeeping then
			StatusPing.Size = UDim2.new(0, 6, 0, 6)
			StatusPing.BackgroundTransparency = 0.35
			TweenService:Create(StatusPing, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 22, 0, 22), BackgroundTransparency = 1 }):Play()

			TweenService:Create(StatusDot, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0 }):Play()
			task.wait(0.12)
			TweenService:Create(StatusDot, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ BackgroundTransparency = 0.35 }):Play()
		end
		task.wait(1.6)
	end
end)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, -48, 0, 1)
Divider.Position = UDim2.new(0, 24, 0, 204)
Divider.BackgroundColor3 = Tokens.Border
Divider.BackgroundTransparency = 1
Divider.BorderSizePixel = 0
Divider.ZIndex = 15
Divider.Parent = MainFrame

local DividerGradient = Instance.new("UIGradient")
DividerGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.75),
	NumberSequenceKeypoint.new(1, 1),
})
DividerGradient.Parent = Divider

-- Footer meme line — a typewriter that cycles through goofy one-liners.
-- Monospace font sells the "typing" feel; text is filled in by the
-- typewriter task further down, after the card list exists.
local FooterText = Instance.new("TextLabel")
FooterText.AnchorPoint = Vector2.new(0.5, 0)
FooterText.Size = UDim2.new(1, -32, 0, 18)
FooterText.Position = UDim2.new(0.5, 0, 0, 352)
FooterText.BackgroundTransparency = 1
FooterText.Text = ""
FooterText.TextColor3 = Tokens.TextSecondary
FooterText.Font = Enum.Font.Code
FooterText.TextSize = 12
FooterText.TextTransparency = 1
FooterText.ZIndex = 15
FooterText.Parent = MainFrame

local rngMemes = {
	"ivory hub on top gang", "no cap this hub is different",
	"certified ivory moment", "we don't miss, we ivory",
	"did someone say spaghetti", "my code is pasta",
	"al dente and tangled", "bon appetit",
	"gaming chair diff fr", "i got the 4000$ chair",
	"that's why i never miss", "totally not aimbot",
	"me and the boys", "running the script",
	"and getting banned", "worth it every time",
	"the script is free", "and open source",
	"and has silent aim", "what more could you want",
	"Error: can't find message", "i'm not having errors actually",
	"or maybe I am, who knows??", "is that a hack?",
	"no it's a gaming chair", "my chair has aimbot",
	"you should get one", "please read the info tab",
	"and credit me if u did a snippet", "i'm not a robot",
	"i'm ivory", "robots are metal", "ivory is rock",
	"big difference", "u ever just", "silent aim someone",
	"and they go '??? how'", "and then u say ping diff",
	"well I did that", "ivory has 0 calories",
	"wait this isn't a virus", "it's open source",
	"you can literally read it", "meow :3",
	"can ivory run doom?", "welcome to ivory hub",
	"esp go brr", "aimbot activated (not really)",
	"toggle spam real", "sliders > toggles",
	"color pickers go brr", "not a virus i promise",
	"ivory gang rise up", "built different fr fr",
	"top tier hub behavior", "ratio + you fell off + ivory won",
	"we stay winning", "goated with the sauce",
	"ivory > every other hub", "trust the process",
	"this hub hits different", "sigma script energy",
	"lowkey the best hub", "highkey the best hub",
}

-- ============================================================================
-- OPTION CARDS
-- ============================================================================

local function createOption(pos, width, title, description, callback)
	local Card = Instance.new("TextButton")
	Card.Size = UDim2.new(0, width, 0, 116)
	Card.Position = pos
	Card.BackgroundColor3 = Tokens.SurfaceLow
	Card.BackgroundTransparency = 1
	Card.Text = ""
	Card.AutoButtonColor = false
	Card.ZIndex = 15
	Card.Parent = MainFrame

	local REST_FILL, HOVER_FILL = 0.9, 0.78
	local REST_STROKE, HOVER_STROKE = 0.72, 0.35

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = Card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Tokens.Border
	stroke.Transparency = 1
	stroke.Thickness = 1.25
	stroke.Parent = Card

	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 1
	cardScale.Parent = Card

	local iconChip = Instance.new("Frame")
	iconChip.Size = UDim2.new(0, 40, 0, 40)
	iconChip.Position = UDim2.new(0, 16, 0, 16)
	iconChip.BackgroundColor3 = Tokens.SurfaceLow
	iconChip.BackgroundTransparency = 1
	iconChip.ZIndex = 17
	iconChip.Parent = Card

	local iconChipCorner = Instance.new("UICorner")
	iconChipCorner.CornerRadius = UDim.new(0, 12)
	iconChipCorner.Parent = iconChip

	local iconChipStroke = Instance.new("UIStroke")
	iconChipStroke.Color = Tokens.Border
	iconChipStroke.Transparency = 1
	iconChipStroke.Thickness = 1
	iconChipStroke.Parent = iconChip

	local iconChipGradient = Instance.new("UIGradient")
	iconChipGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 70, 110)),
	})
	iconChipGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.88),
		NumberSequenceKeypoint.new(1, 0.95),
	})
	iconChipGradient.Rotation = 105
	iconChipGradient.Parent = iconChip

	local icon, iconParts = createBlossomMark(iconChip, 20, Tokens.AccentBright, 18)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.new(0.5, 0, 0.5, 0)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -32, 0, 22)
	titleLabel.Position = UDim2.new(0, 16, 0, 62)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Tokens.TextPrimary
	titleLabel.Font = Enum.Font.GothamMedium
	titleLabel.TextSize = 15
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextTransparency = 1
	titleLabel.ZIndex = 17
	titleLabel.Parent = Card

	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -32, 0, 30)
	descLabel.Position = UDim2.new(0, 16, 0, 84)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Tokens.TextSecondary
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextSize = 11
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.TextWrapped = true
	descLabel.TextTransparency = 1
	descLabel.ZIndex = 17
	descLabel.Parent = Card

	local arrow = Instance.new("Frame")
	arrow.Size = UDim2.new(0, 16, 0, 16)
	arrow.Position = UDim2.new(1, -32, 0, 18)
	arrow.BackgroundTransparency = 1
	arrow.ZIndex = 17
	arrow.Parent = Card

	local function chevronBar(rotation, yOff)
		local bar = Instance.new("Frame")
		bar.Size = UDim2.new(0, 8, 0, 1.5)
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.new(0.5, 0, 0.5, yOff)
		bar.BackgroundColor3 = Tokens.TextSecondary
		bar.BackgroundTransparency = 1
		bar.BorderSizePixel = 0
		bar.Rotation = rotation
		bar.ZIndex = 17
		bar.Parent = arrow
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent = bar
		return bar
	end

	local chevA = chevronBar(45, -2.5)
	local chevB = chevronBar(-45, 2.5)

	Card.MouseEnter:Connect(function()
		TweenService:Create(Card, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = HOVER_FILL, Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset - 3) }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = HOVER_STROKE, Color = Tokens.BorderAccent }):Play()
		TweenService:Create(iconChip, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.65 }):Play()
		TweenService:Create(iconChipStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 0.4, Color = Tokens.BorderAccent }):Play()
		recolorBlossom(iconParts, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Tokens.BorderAccent)
		TweenService:Create(chevA, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.15 }):Play()
		TweenService:Create(chevB, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.15 }):Play()
	end)

	Card.MouseLeave:Connect(function()
		TweenService:Create(Card, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = REST_FILL, Position = pos }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = REST_STROKE, Color = Tokens.Border }):Play()
		TweenService:Create(iconChip, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 0.82 }):Play()
		TweenService:Create(iconChipStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Transparency = 0.7, Color = Tokens.Border }):Play()
		recolorBlossom(iconParts, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Tokens.AccentBright)
		TweenService:Create(chevA, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()
		TweenService:Create(chevB, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }):Play()
	end)

	Card.MouseButton1Down:Connect(function()
		TweenService:Create(cardScale, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.96 }):Play()
	end)
	Card.MouseButton1Up:Connect(function()
		TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end)

	Card.MouseButton1Click:Connect(callback)

	return {
		card = Card, stroke = stroke, iconChip = iconChip, iconChipStroke = iconChipStroke,
		icon = icon, iconParts = iconParts, title = titleLabel, desc = descLabel,
		chevA = chevA, chevB = chevB, restFill = REST_FILL, restStroke = REST_STROKE,
	}
end

-- ============================================================================
-- LOAD SCRIPT LOGIC
-- ============================================================================

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/"

local function fadeOutAndDestroy(afterFade)
	local info = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	statusBeeping = false
	TweenService:Create(BackgroundBlur, info, { Size = 0 }):Play()
	TweenService:Create(PanelScale, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.92 }):Play()

	for _, v in pairs(PanelWrapper:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			TweenService:Create(v, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		elseif v:IsA("ImageLabel") then
			TweenService:Create(v, info, { ImageTransparency = 1 }):Play()
		elseif v:IsA("Frame") then
			TweenService:Create(v, info, { BackgroundTransparency = 1 }):Play()
		elseif v:IsA("UIStroke") then
			TweenService:Create(v, info, { Transparency = 1 }):Play()
		end
	end

	task.delay(0.38, function()
		if ScreenGui then ScreenGui:Destroy() end
		if BackgroundBlur then BackgroundBlur:Destroy() end
		if afterFade then afterFade() end
	end)
end

local function loadScript(url)
	StatusLabel.Text = "loading..."
	fadeOutAndDestroy(function()
		local success, err = pcall(function()
			local commitHash = "main"
			pcall(function()
				local apiRes = request({
					Url = "https://api.github.com/repos/hubivory/IvoryHub/commits?per_page=1",
					Method = "GET",
				})
				if apiRes and apiRes.Body then
					local hash = apiRes.Body:match('"sha":"(%w+)"')
					if hash then commitHash = hash end
				end
			end)

			local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
			pcall(function()
				local genv = getgenv()
				genv._IvoryLibSrc = request({ Url = repo .. "Library.lua", Method = "GET" }).Body
				genv._IvoryTMSrc = request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body
				genv._IvorySMSrc = request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body
			end)

			local fetchUrl = GITHUB_RAW .. commitHash .. "/" .. url
			local res = request({ Url = fetchUrl, Method = "GET" })
			local content = res and res.Body or nil
			if not content then error("HTTP fetch failed") end

			if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
				content = content:sub(4)
			end

			local fn, loadErr = loadstring(content)
			if not fn then error("Compile error: " .. tostring(loadErr)) end
			fn()
		end)

		if success then
			print("[Ivory] Loaded successfully!")
		else
			warn("[Ivory] Failed to load:", err)
		end
	end)
end

-- ============================================================================
-- BUILD OPTIONS
-- ============================================================================

local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://9120299810"
hoverSound.Volume = 0.08
hoverSound.Parent = ScreenGui

local cards = {}

if DetectedGame then
	local gameCard = createOption(
		UDim2.new(0, 24, 0, 224), 208,
		"Game Script",
		DetectedGame.name,
		function() loadScript(DetectedGame.file) end
	)
	gameCard.card.MouseEnter:Connect(function() hoverSound:Play() end)
	table.insert(cards, gameCard)

	local uniCard = createOption(
		UDim2.new(0, 248, 0, 224), 208,
		"Universal",
		"Works in any game",
		function() loadScript("Loader.luau") end
	)
	uniCard.card.MouseEnter:Connect(function() hoverSound:Play() end)
	table.insert(cards, uniCard)
else
	local uniCard = createOption(
		UDim2.new(0, 24, 0, 224), 432,
		"Universal",
		"Works in any game — ESP, aimbot, speed, and more",
		function() loadScript("Loader.luau") end
	)
	uniCard.card.MouseEnter:Connect(function() hoverSound:Play() end)
	table.insert(cards, uniCard)
end

-- ============================================================================
-- BLOSSOM MARK MOTION — a slow, shared rotation across the header icon and
-- every card icon, frame-locked via RenderStepped. Replaces the old image-
-- swap cycle (which depended on a set of asset ids that turned out to include
-- broken/mismatched glyphs) with motion that can't fail: the same vector mark,
-- everywhere, just turning gently.
-- ============================================================================

local blossomMarks = { Icon }
for _, c in ipairs(cards) do
	table.insert(blossomMarks, c.icon)
end

do
	local spinT = 0
	local spinConn
	spinConn = RunService.RenderStepped:Connect(function(dt)
		if not (ScreenGui and ScreenGui.Parent) then
			if spinConn then spinConn:Disconnect() end
			return
		end
		spinT = spinT + dt * 6 -- degrees per second
		for _, mark in ipairs(blossomMarks) do
			mark.Rotation = spinT
		end
	end)
end

-- ============================================================================
-- FOOTER TYPEWRITER — cycles through the meme list, character by character,
-- with a blinking cursor and an erase pass between lines.
-- ============================================================================

task.spawn(function()
	local currentText = ""
	local cursorVisible = true
	local charIndex = 1
	local isErasing = false
	local currentMessage = ""

	while ScreenGui and ScreenGui.Parent do
		if not isErasing and currentMessage == "" then
			currentMessage = rngMemes[math.random(1, #rngMemes)]
			charIndex = 1
			currentText = ""
		end

		if not isErasing then
			if charIndex <= #currentMessage then
				currentText = currentText .. currentMessage:sub(charIndex, charIndex)
				charIndex = charIndex + 1
				FooterText.Text = currentText .. (cursorVisible and "_" or "")
				task.wait(math.random(3, 8) / 100)
			else
				task.wait(math.random(15, 35) / 10)
				isErasing = true
			end
		else
			if #currentText > 0 then
				currentText = currentText:sub(1, #currentText - 1)
				FooterText.Text = currentText .. (cursorVisible and "_" or "")
				task.wait(math.random(2, 5) / 100)
			else
				isErasing = false
				currentMessage = ""
				task.wait(math.random(5, 15) / 10)
			end
		end

		cursorVisible = not cursorVisible
		if not isErasing and currentText ~= "" then
			FooterText.Text = currentText .. (cursorVisible and "_" or "")
		end
	end
end)

-- ============================================================================
-- CLOSE
-- ============================================================================

local function closeEverything()
	fadeOutAndDestroy(nil)
end

CloseButton.MouseButton1Click:Connect(closeEverything)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Escape and ScreenGui and ScreenGui.Parent then
		closeEverything()
	end
end)

-- ============================================================================
-- ENTRANCE ANIMATION
-- ============================================================================

local function entranceAnimation()
	local easeOut = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local easeOutSlow = TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local popIn = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	TweenService:Create(BackgroundBlur, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = 18 }):Play()
	TweenService:Create(PanelScale, popIn, { Scale = 1 }):Play()
	TweenService:Create(MainFrame, easeOutSlow, { BackgroundTransparency = 0.1 }):Play()
	TweenService:Create(GlassStroke, easeOutSlow, { Transparency = 0.35 }):Play()
	TweenService:Create(TopHighlight, easeOutSlow, { BackgroundTransparency = 0.75 }):Play()
	setGlowStack(shadowStack, easeOutSlow, true)

	task.wait(0.1)
	TweenService:Create(closeBarA, easeOut, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(closeBarB, easeOut, { BackgroundTransparency = 0 }):Play()

	task.wait(0.08)
	TweenService:Create(IconChip, easeOut, { BackgroundTransparency = 0.78 }):Play()
	TweenService:Create(IconChipStroke, easeOut, { Transparency = 0.6 }):Play()
	fadeBlossom(IconParts, easeOut, 0)

	task.wait(0.08)
	TweenService:Create(Title, easeOut, { TextTransparency = 0 }):Play()

	task.wait(0.06)
	TweenService:Create(StatusLabel, easeOut, { TextTransparency = 0 }):Play()

	task.wait(0.08)
	TweenService:Create(Divider, easeOut, { BackgroundTransparency = 0.75 }):Play()

	task.wait(0.08)
	for i, c in ipairs(cards) do
		task.delay((i - 1) * 0.08, function()
			TweenService:Create(c.card, easeOut, { BackgroundTransparency = c.restFill }):Play()
			TweenService:Create(c.stroke, easeOut, { Transparency = c.restStroke }):Play()
			TweenService:Create(c.iconChip, easeOut, { BackgroundTransparency = 0.82 }):Play()
			TweenService:Create(c.iconChipStroke, easeOut, { Transparency = 0.7 }):Play()
			fadeBlossom(c.iconParts, easeOut, 0)
			TweenService:Create(c.title, easeOut, { TextTransparency = 0 }):Play()
			TweenService:Create(c.desc, easeOut, { TextTransparency = 0.15 }):Play()
		end)
	end

	task.wait(0.3)
	TweenService:Create(FooterText, easeOut, { TextTransparency = 0.1 }):Play()
end

entranceAnimation()
