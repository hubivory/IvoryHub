-- ===============================================================
-- IVORY HUB - SAKURA EDITION
-- A general-purpose Roblox UI component library in a deep plum /
-- cherry-blossom pink / blossom-white theme, matching the Ivory Hub key
-- system. Comparable capability to Rayfield (window/tabs, buttons,
-- toggles, sliders, dropdowns, multi-dropdowns, color picker,
-- keybinds, inputs, labels, paragraphs, dividers, notifications,
-- config save/load, autosave, and Ctrl+F search) - all original
-- code and visuals in the Ivory Hub color language, not a copy of
-- any other library's assets or branding.
--
-- Usage:
--   local IvoryHub = loadstring(game:HttpGet("..."))()  -- or paste inline
--   local Window = IvoryHub.CreateWindow({ Name = "My Hub" })
--   local Tab = Window:CreateTab("Main")
--   Tab:CreateButton({ Name = "Click me", Callback = function() end })
--   ... etc, see the EXAMPLE USAGE section at the very bottom of this
--   file for one of every element type wired up and working.
-- ===============================================================

-- ===============================================================
-- SERVICES
-- ===============================================================
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

-- ===============================================================
-- CROSS-RUN STOPPER
-- Tear down a previous copy of this script before building a new
-- one. Re-executing after a failed run used to stack a second set
-- of while-loops, petal fields and input listeners on top of the
-- first, which is what makes the client feel laggier the longer a
-- session goes. Unload stops the old copy's loops; this runs first
-- so the old UI is gone before the new one is built.
-- ===============================================================
pcall(function()
    local previous = getgenv and getgenv().IvoryHub
    if type(previous) == "table" and previous.Unload then
        previous:Unload()
    end
end)

-- ===============================================================
-- DESIGN TOKENS - SAKURA EDITION
-- Deep plum-black surfaces with a cherry-blossom pink accent, warm
-- blossom-white highlights, and a spring-matcha green for success
-- states. Same key system shape as the original charcoal theme, fully
-- repainted for a softer, petal-drift aesthetic.
--
-- Every table in this block is mirrored in Theme.lua as a standalone,
-- human-editable reference (same names, same values). This file keeps
-- its own inline copy so the library stays a single loadstring-able
-- script with no external dependency - edit both if you change one.
-- ===============================================================
local Theme = {
    Plum900        = Color3.fromRGB(16, 9, 13),    -- deepest backdrop
    Plum800        = Color3.fromRGB(30, 17, 23),   -- card surface
    Plum700        = Color3.fromRGB(46, 25, 33),   -- alt surface / buttons
    Plum600        = Color3.fromRGB(64, 36, 46),   -- lighter panel wash

    Mauve          = Color3.fromRGB(120, 88, 100),
    Petal          = Color3.fromRGB(255, 226, 233),
    Blossom        = Color3.fromRGB(247, 36, 130), -- primary interactive accent, brand color #F72482
    BlossomLight   = Color3.fromRGB(255, 200, 217), -- lighter end of the wordmark/petal gradient

    TextPrimary    = Color3.fromRGB(252, 240, 244),
    TextSecondary  = Color3.fromRGB(198, 168, 178),
    TextTertiary   = Color3.fromRGB(140, 112, 122),

    Success        = Color3.fromRGB(150, 214, 168), -- spring matcha green
    Error          = Color3.fromRGB(226, 84, 96),   -- cherry red, distinct from accent pink
    Warning        = Color3.fromRGB(240, 188, 122), -- warm peach/gold
    Discord        = Color3.fromRGB(88, 101, 242),  -- brand color, left untouched
}

-- Fonts, text sizes, and corner radii reused across every component.
-- Named by scale (SM/MD/LG...) rather than by component, since the
-- same size is shared by many unrelated elements - change one entry
-- here and everything using it follows.
local Font = {
    Body   = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold   = Enum.Font.GothamBold,
    Black  = Enum.Font.GothamBlack, -- wordmark only, heavier than Bold
}

local TextSizes = {
    XS    = 10,
    SM    = 12,
    SMMD  = 12.5,
    MD    = 13,
    LG    = 14,
    XL    = 15,
    Title = 18,
}

local Radius = {
    Pill  = UDim.new(1, 0),  -- fully round (pills, dots, thumbs)
    XL    = UDim.new(0, 12), -- outer window / big cards
    LG    = UDim.new(0, 9),  -- section cards, header bars
    MD    = UDim.new(0, 7),  -- rows (toggle/slider/dropdown/keybind)
    SM    = UDim.new(0, 6),  -- small chips, option rows
    XS    = UDim.new(0, 5),
    Tiny  = UDim.new(0, 3),
    Micro = UDim.new(0, 2),
}

-- The two background/stroke opacities reused everywhere a surface
-- needs the same "barely there" treatment (mostly strokes, plus a
-- couple of near-invisible backgrounds). One-off animation targets
-- (fades, hover flashes) are left as inline values next to the tween
-- that uses them.
local Alpha = {
    CardFill      = 0.08,
    Faint         = 0.82,
}

-- ===============================================================
-- TWEEN HELPERS
-- ===============================================================
local EASE_OUT_SOFT = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local EASE_SPRING   = TweenInfo.new(0.4,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local EASE_QUICK    = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local EASE_SLOW     = TweenInfo.new(0.6,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- TweenService:Cancel does not exist in this environment (only
-- Tween:Cancel on the tween object), so tw() tracks every tween it
-- starts per-instance and animations cancel through this registry.
local activeTweens = {}

local function cancelTweens(instance)
    local list = activeTweens[instance]
    if not list then
        return
    end
    for i = #list, 1, -1 do
        local t = list[i]
        list[i] = nil
        pcall(function() t:Cancel() end)
    end
    activeTweens[instance] = nil
end

local function tw(instance, info, props)
    local tween = TweenService:Create(instance, info, props)
    local list = activeTweens[instance]
    if not list then
        list = {}
        activeTweens[instance] = list
    end
    table.insert(list, tween)
    tween.Completed:Connect(function()
        local l = activeTweens[instance]
        if not l then
            return
        end
        for i = #l, 1, -1 do
            if l[i] == tween then
                table.remove(l, i)
            end
        end
        if #l == 0 then
            activeTweens[instance] = nil
        end
    end)
    tween:Play()
    return tween
end

-- ===============================================================
-- MODULE TABLES
-- Every component below attaches onto these two shared tables
-- instead of declaring its own - this is what lets all the pieces
-- compose into one library.
-- ===============================================================
local Library = {}
local Elements = {}

-- Content layout: 2 = two side-by-side columns (CS2-cheat style),
-- 1 = one full-width column. Tab:_route() reads this for every new
-- element; Library:SetContentColumns reflows open windows live.
Library.ContentColumns = 2
Library._windows = {}


-- ============================================================
-- Input + Label + Paragraph + Section + Divider
-- ============================================================
--[[
    Ivory Hub - Input + Label + Paragraph + Divider
    Implements: Elements.CreateInput, Elements.CreateLabel,
                Elements.CreateParagraph, Elements.CreateDivider
]]

-- ============================================================
-- Elements.CreateInput
-- ============================================================
Elements.CreateInput = function(parent, config)
    config = config or {}

    local row = Instance.new("Frame")
    row.Name = config.Name or config.Text or "Input"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 46)
    row.ZIndex = 3
    row.Parent = parent

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.BackgroundColor3 = Theme.Plum700
    card.BackgroundTransparency = Alpha.CardFill
    card.Size = UDim2.new(1, 0, 1, 0)
    card.ZIndex = 3
    card.Parent = row

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = Radius.LG
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(255, 255, 255)
    cardStroke.Transparency = Alpha.Faint
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Font.Medium
    nameLabel.TextSize = TextSizes.LG
    nameLabel.TextColor3 = Theme.TextPrimary
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    -- Scale-based share that always stops before the right-side box
    -- (box left edge = 0.45W - 8), so label and box can never collide
    -- at any row width - the old 0.4/-8 overlapped below ~320px.
    nameLabel.Size = UDim2.new(0.45, -32, 1, 0)
    nameLabel.Position = UDim2.new(0, 16, 0, 0)
    nameLabel.Text = config.Name or config.Text or ""
    nameLabel.ZIndex = 4
    nameLabel.Parent = card

    local boxHolder = Instance.new("Frame")
    boxHolder.Name = "InputHolder"
    boxHolder.BackgroundColor3 = Theme.Plum600
    boxHolder.BackgroundTransparency = 0
    boxHolder.ClipsDescendants = true
    boxHolder.AnchorPoint = Vector2.new(1, 0.5)
    boxHolder.Position = UDim2.new(1, -16, 0.5, 0)
    boxHolder.Size = UDim2.new(0.55, -8, 0, 32)
    boxHolder.ZIndex = 4
    boxHolder.Parent = card

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = Radius.Pill
    boxCorner.Parent = boxHolder

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = Color3.fromRGB(255, 255, 255)
    boxStroke.Transparency = Alpha.Faint
    boxStroke.Thickness = 1
    boxStroke.Parent = boxHolder

    local boxScale = Instance.new("UIScale")
    boxScale.Scale = 1
    boxScale.Parent = boxHolder

    local textBox = Instance.new("TextBox")
    textBox.Name = "TextBox"
    textBox.BackgroundTransparency = 1
    textBox.Size = UDim2.new(1, -24, 1, 0)
    textBox.Position = UDim2.new(0, 12, 0, 0)
    textBox.Font = Font.Body
    textBox.TextSize = TextSizes.MD
    textBox.TextColor3 = Theme.TextPrimary
    textBox.PlaceholderText = config.PlaceholderText or ""
    textBox.PlaceholderColor3 = Theme.TextTertiary
    textBox.Text = config.CurrentValue or config.Default or ""
    textBox.ClearTextOnFocus = false
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Center
    textBox.ClipsDescendants = true
    textBox.ZIndex = 5
    textBox.Parent = boxHolder

    local controlObject
    controlObject = {
        Instance = row,
        Value = config.CurrentValue or "",
    }

    textBox.Focused:Connect(function()
        tw(boxStroke, EASE_QUICK, { Transparency = 0.25, Color = Theme.Blossom })
        tw(boxScale, EASE_QUICK, { Scale = 1.02 })
    end)

    textBox.FocusLost:Connect(function()
        tw(boxStroke, EASE_QUICK, { Transparency = Alpha.Faint, Color = Color3.fromRGB(255, 255, 255) })
        tw(boxScale, EASE_QUICK, { Scale = 1 })

        local text = textBox.Text
        controlObject.Value = text

        if config.Callback then
            pcall(config.Callback, text)
        end

        if config.RemoveTextAfterFocusLost then
            textBox.Text = ""
        end
    end)

    controlObject.Set = function(self, text, silent)
        text = text or ""
        textBox.Text = text
        self.Value = text
        if not silent and config.Callback then
            pcall(config.Callback, text)
        end
    end

    if Library._RegisterFlag and config.Flag then
        Library._RegisterFlag(config.Flag, controlObject)
    end

    if Library._RegisterSearchable then
        Library._RegisterSearchable(config.Name, row)
    end

    return controlObject
end

-- ============================================================
-- Elements.CreateLabel
-- ============================================================
Elements.CreateLabel = function(parent, text)
    local row = Instance.new("Frame")
    row.Name = "Label"
    row.BackgroundTransparency = 1
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.Size = UDim2.new(1, 0, 0, 0)
    row.ZIndex = 3
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "LabelText"
    label.BackgroundTransparency = 1
    label.Font = Font.Body
    label.TextSize = TextSizes.MD
    label.TextColor3 = Theme.TextSecondary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.TextWrapped = true
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.Size = UDim2.new(1, 0, 0, 0)
    label.Text = text or ""
    label.ZIndex = 3
    label.Parent = row

    local obj = {
        Instance = row,
        Set = function(self, newText)
            label.Text = newText or ""
        end,
    }
    obj.CreateKeybind = function(self, name, kbConfig)
        kbConfig = kbConfig or {}
        kbConfig.Name = kbConfig.Name or name
        return Elements.CreateKeybind(self.Instance.Parent, kbConfig)
    end
    obj.CreateColorPicker = function(self, name, cpConfig)
        cpConfig = cpConfig or {}
        cpConfig.Name = cpConfig.Name or name
        return Elements.CreateColorPicker(self.Instance.Parent, cpConfig)
    end
    return obj
end

-- ============================================================
-- Elements.CreateParagraph
-- ============================================================
Elements.CreateParagraph = function(parent, config)
    config = config or {}

    local row = Instance.new("Frame")
    row.Name = config.Title or config.Text or config.Name or "Paragraph"
    row.BackgroundTransparency = 1
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.Size = UDim2.new(1, 0, 0, 0)
    row.ZIndex = 3
    row.Parent = parent

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.BackgroundColor3 = Theme.Plum700
    card.BackgroundTransparency = Alpha.CardFill
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Size = UDim2.new(1, 0, 0, 0)
    card.ZIndex = 3
    card.Parent = row

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = Radius.MD
    cardCorner.Parent = card

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(255, 255, 255)
    cardStroke.Transparency = Alpha.Faint
    cardStroke.Thickness = 1
    cardStroke.Parent = card

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 14)
    padding.PaddingRight = UDim.new(0, 14)
    padding.PaddingTop = UDim.new(0, 12)
    padding.PaddingBottom = UDim.new(0, 12)
    padding.Parent = card

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = card

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Font.Bold
    titleLabel.TextSize = TextSizes.LG
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Top
    titleLabel.TextWrapped = true
    titleLabel.AutomaticSize = Enum.AutomaticSize.Y
    titleLabel.Size = UDim2.new(1, 0, 0, 0)
    titleLabel.LayoutOrder = 1
    titleLabel.Text = config.Title or ""
    titleLabel.ZIndex = 4
    titleLabel.Parent = card

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.BackgroundTransparency = 1
    contentLabel.Font = Font.Body
    contentLabel.TextSize = TextSizes.SMMD
    contentLabel.TextColor3 = Theme.TextSecondary
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.TextWrapped = true
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    contentLabel.Size = UDim2.new(1, 0, 0, 0)
    contentLabel.LayoutOrder = 2
    contentLabel.Text = config.Content or ""
    contentLabel.ZIndex = 4
    contentLabel.Parent = card

    if Library._RegisterSearchable then
        Library._RegisterSearchable(config.Title, row)
    end

    return {
        Instance = row,
        Set = function(self, newConfig)
            newConfig = newConfig or {}
            if newConfig.Title ~= nil then
                titleLabel.Text = newConfig.Title
                row.Name = newConfig.Title
            end
            if newConfig.Content ~= nil then
                contentLabel.Text = newConfig.Content
            end
        end,
    }
end

-- ============================================================
-- Elements.CreateSection
-- A small caption-style heading that breaks a tab's content into named
-- groups (same visual language as the ACTIVE header on the Active Features
-- panel) - the Rayfield-parity equivalent of CreateSection, since ported
-- scripts lean on it heavily.
-- ============================================================
Elements.CreateSection = function(parent, title)
    local row = Instance.new("Frame")
    row.Name = "Section"
    row.BackgroundTransparency = 1
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.Size = UDim2.new(1, 0, 0, 0)
    row.ZIndex = 3
    row.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = row

    -- CS2-cheat reference layout: title centered over a thin accent
    -- underline that spans the card, instead of an uppercase left label.
    local label = Instance.new("TextLabel")
    label.Name = "SectionLabel"
    label.BackgroundTransparency = 1
    label.Font = Font.Bold
    label.TextSize = TextSizes.MD
    label.TextColor3 = Theme.TextPrimary
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.Size = UDim2.new(1, 0, 0, 16)
    -- Negative orders: content rows default to LayoutOrder 0 and used to
    -- sort ABOVE their own section header (verified: button Y 297 vs
    -- header Y 351). Header first, then the line, then the content.
    label.LayoutOrder = -2
    label.Text = tostring(title or "Section")
    label.ZIndex = 3
    label.Parent = row

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.BackgroundColor3 = Theme.Blossom
    line.BackgroundTransparency = 0.55
    line.BorderSizePixel = 0
    line.Size = UDim2.new(1, 0, 0, 1)
    line.LayoutOrder = -1
    line.ZIndex = 3
    line.Parent = row

    if Library._RegisterAccentBound then
        Library._RegisterAccentBound(function(color)
            if line.Parent then
                line.BackgroundColor3 = color
            end
        end)
    end

    return {
        Instance = row,
        Set = function(self, newTitle)
            label.Text = tostring(newTitle or "")
        end,
    }
end

-- ============================================================
-- Elements.CreateDivider
-- ============================================================
Elements.CreateDivider = function(parent)
    local row = Instance.new("Frame")
    row.Name = "Divider"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 13)
    row.ZIndex = 3
    row.Parent = parent

    local line = Instance.new("Frame")
    line.Name = "Line"
    line.BackgroundColor3 = Theme.TextTertiary
    line.BackgroundTransparency = 0.85
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0, 0.5)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.Size = UDim2.new(1, 0, 0, 1)
    line.ZIndex = 3
    line.Parent = row

    return row
end

-- ============================================================
-- Button + Toggle
-- ============================================================
-- Ivory Hub - Button + Toggle elements
-- Plain ASCII only. Icons (chevron) are hand-built out of Frames.

-- ============================================================
-- Elements.CreateButton
-- ============================================================
Elements.CreateButton = function(parent, config)
	config = config or {}

	local rowFrame = Instance.new("TextButton")
	rowFrame.Name = "ButtonRow"
	rowFrame.AutoButtonColor = false
	rowFrame.Text = ""
	rowFrame.Size = UDim2.new(1, 0, 0, 46)
	rowFrame.BackgroundColor3 = Theme.Plum700
	rowFrame.BackgroundTransparency = Alpha.CardFill
	rowFrame.BorderSizePixel = 0
	rowFrame.ClipsDescendants = false
	rowFrame.ZIndex = 3
	rowFrame.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = Radius.MD
	rowCorner.Parent = rowFrame

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 1
	rowStroke.Color = Color3.fromRGB(255, 255, 255)
	rowStroke.Transparency = Alpha.Faint
	rowStroke.Parent = rowFrame

	local rowScale = Instance.new("UIScale")
	rowScale.Scale = 1
	rowScale.Parent = rowFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -60, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.Font = Font.Medium
	label.TextSize = TextSizes.LG
	label.TextColor3 = Theme.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = config.Name or config.Text or "Button"
	label.ZIndex = 4
	label.Parent = rowFrame

	-- Chevron built from two short rotated bars, hidden at rest, slides in on hover
	local chevronHolder = Instance.new("Frame")
	chevronHolder.Name = "Chevron"
	chevronHolder.BackgroundTransparency = 1
	chevronHolder.Size = UDim2.new(0, 14, 0, 14)
	chevronHolder.AnchorPoint = Vector2.new(1, 0.5)
	chevronHolder.Position = UDim2.new(1, -24, 0.5, 0)
	chevronHolder.ZIndex = 4
	chevronHolder.Parent = rowFrame

	local chevBarTop = Instance.new("Frame")
	chevBarTop.Name = "Top"
	chevBarTop.AnchorPoint = Vector2.new(1, 0.5)
	chevBarTop.Size = UDim2.new(0, 7, 0, 2)
	chevBarTop.Position = UDim2.new(1, 0, 0.5, -3)
	chevBarTop.Rotation = -45
	chevBarTop.BackgroundColor3 = Theme.TextSecondary
	chevBarTop.BackgroundTransparency = 1
	chevBarTop.BorderSizePixel = 0
	chevBarTop.ZIndex = 4
	chevBarTop.Parent = chevronHolder

	local chevTopCorner = Instance.new("UICorner")
	chevTopCorner.CornerRadius = Radius.Pill
	chevTopCorner.Parent = chevBarTop

	local chevBarBottom = Instance.new("Frame")
	chevBarBottom.Name = "Bottom"
	chevBarBottom.AnchorPoint = Vector2.new(1, 0.5)
	chevBarBottom.Size = UDim2.new(0, 7, 0, 2)
	chevBarBottom.Position = UDim2.new(1, 0, 0.5, 3)
	chevBarBottom.Rotation = 45
	chevBarBottom.BackgroundColor3 = Theme.TextSecondary
	chevBarBottom.BackgroundTransparency = 1
	chevBarBottom.BorderSizePixel = 0
	chevBarBottom.ZIndex = 4
	chevBarBottom.Parent = chevronHolder

	local chevBottomCorner = Instance.new("UICorner")
	chevBottomCorner.CornerRadius = Radius.Pill
	chevBottomCorner.Parent = chevBarBottom

	-- Gloss gradient overlay for cool hover effect
	local gloss = Instance.new("Frame")
	gloss.Name = "Gloss"
	gloss.Size = UDim2.new(1, 0, 0.5, 0)
	gloss.Position = UDim2.new(0, 0, 0, 0)
	gloss.BackgroundTransparency = 1
	gloss.ZIndex = 4
	gloss.Parent = rowFrame

	local glossGradient = Instance.new("UIGradient")
	glossGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
	})
	glossGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(0.5, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	glossGradient.Rotation = 90
	glossGradient.Parent = gloss

	local glossCorner = Instance.new("UICorner")
	glossCorner.CornerRadius = Radius.MD
	glossCorner.Parent = gloss

	rowFrame.MouseEnter:Connect(function()
		tw(rowFrame, EASE_OUT_SOFT, { BackgroundColor3 = Theme.Plum600, BackgroundTransparency = 0.05 })
		tw(rowStroke, EASE_OUT_SOFT, { Transparency = 0.3, Color = Theme.Blossom })
		tw(rowScale, EASE_OUT_SOFT, { Scale = 1.03 })
		tw(gloss, EASE_OUT_SOFT, { Transparency = 0.85 })
		tw(chevronHolder, EASE_OUT_SOFT, { Position = UDim2.new(1, -14, 0.5, 0) })
		tw(chevBarTop, EASE_OUT_SOFT, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Blossom })
		tw(chevBarBottom, EASE_OUT_SOFT, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Blossom })
	end)

	rowFrame.MouseLeave:Connect(function()
		tw(rowFrame, EASE_OUT_SOFT, { BackgroundColor3 = Theme.Plum700, BackgroundTransparency = Alpha.CardFill })
		tw(rowStroke, EASE_OUT_SOFT, { Transparency = Alpha.Faint, Color = Color3.fromRGB(255, 255, 255) })
		tw(rowScale, EASE_OUT_SOFT, { Scale = 1 })
		tw(gloss, EASE_OUT_SOFT, { Transparency = 1 })
		tw(chevronHolder, EASE_OUT_SOFT, { Position = UDim2.new(1, -24, 0.5, 0) })
		tw(chevBarTop, EASE_OUT_SOFT, { BackgroundTransparency = 1, BackgroundColor3 = Theme.TextSecondary })
		tw(chevBarBottom, EASE_OUT_SOFT, { BackgroundTransparency = 1, BackgroundColor3 = Theme.TextSecondary })
	end)

	rowFrame.MouseButton1Click:Connect(function()
		local downTween = tw(rowScale, EASE_QUICK, { Scale = 0.96 })
		downTween.Completed:Wait()
		tw(rowScale, EASE_SPRING, { Scale = 1.04 })
		task.delay(0.12, function()
			tw(rowScale, EASE_OUT_SOFT, { Scale = 1 })
		end)
		pcall(function()
			if config.Callback then
				config.Callback()
			end
		end)
	end)

	local buttonObject = {
		Instance = rowFrame,
	}

	buttonObject.SetName = function(self, newName)
		label.Text = newName
	end

	if Library._RegisterSearchable then
		Library._RegisterSearchable(config.Name, rowFrame)
	end

	return buttonObject
end

-- ============================================================
-- Elements.CreateToggle
-- ============================================================
Elements.CreateToggle = function(parent, config)
	config = config or {}

	local rowFrame = Instance.new("TextButton")
	rowFrame.Name = "ToggleRow"
	rowFrame.AutoButtonColor = false
	rowFrame.Text = ""
	rowFrame.Size = UDim2.new(1, 0, 0, 46)
	rowFrame.BackgroundColor3 = Theme.Plum700
	rowFrame.BackgroundTransparency = Alpha.CardFill
	rowFrame.BorderSizePixel = 0
	rowFrame.ZIndex = 3
	rowFrame.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = Radius.MD
	rowCorner.Parent = rowFrame

	local rowStroke = Instance.new("UIStroke")
	rowStroke.Thickness = 1
	rowStroke.Color = Color3.fromRGB(255, 255, 255)
	rowStroke.Transparency = Alpha.Faint
	rowStroke.Parent = rowFrame

	local rowScale = Instance.new("UIScale")
	rowScale.Scale = 1
	rowScale.Parent = rowFrame

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -72, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.Font = Font.Medium
	label.TextSize = TextSizes.LG
	label.TextColor3 = Theme.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Text = config.Name or config.Text or "Toggle"
	label.ZIndex = 4
	label.Parent = rowFrame

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(1, 0.5)
	track.Size = UDim2.new(0, 40, 0, 22)
	track.Position = UDim2.new(1, -14, 0.5, 0)
	track.BackgroundColor3 = Theme.Plum600
	track.BorderSizePixel = 0
	track.ZIndex = 4
	track.Parent = rowFrame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = Radius.Pill
	trackCorner.Parent = track

	local trackStroke = Instance.new("UIStroke")
	trackStroke.Thickness = 1
	trackStroke.Color = Color3.fromRGB(255, 255, 255)
	trackStroke.Transparency = Alpha.Faint
	trackStroke.Parent = track

	local thumb = Instance.new("Frame")
	thumb.Name = "Thumb"
	thumb.AnchorPoint = Vector2.new(0, 0.5)
	thumb.Size = UDim2.new(0, 18, 0, 18)
	thumb.Position = UDim2.new(0, 2, 0.5, 0)
	thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel = 0
	thumb.ZIndex = 5
	thumb.Parent = track

	local thumbCorner = Instance.new("UICorner")
	thumbCorner.CornerRadius = Radius.Pill
	thumbCorner.Parent = thumb

	local ON_POSITION = UDim2.new(1, -20, 0.5, 0)
	local OFF_POSITION = UDim2.new(0, 2, 0.5, 0)

	local function applyVisual(value, animate)
		local targetColor = value and Theme.Blossom or Theme.Plum600
		local targetPos = value and ON_POSITION or OFF_POSITION
		if animate then
			tw(track, EASE_QUICK, { BackgroundColor3 = targetColor })
			tw(thumb, EASE_SPRING, { Position = targetPos })
		else
			track.BackgroundColor3 = targetColor
			thumb.Position = targetPos
		end
	end

	-- Accept both spellings: CurrentValue is the canonical key, Default is
	-- what SetupDefaultTabs in UIFEATURES.txt and most callers pass.
	local initialValue = config.CurrentValue == true or (config.CurrentValue == nil and config.Default == true)

	-- build the returned table as a local first
	local toggleObject = {
		Instance = rowFrame,
		Value = initialValue,
	}

	-- reflect CurrentValue on creation without firing the callback and without animating
	applyVisual(initialValue, false)

	-- wire Set to mutate the local table
	toggleObject.Set = function(self, value, silent)
		value = value == true
		self.Value = value
		applyVisual(value, true)
		if config.TrackActive and Library._SetFeatureActive then
			Library._SetFeatureActive(rowFrame, config.Name or "Toggle", value)
		end
		if not silent and config.Callback then
			pcall(config.Callback, value)
		end
	end

	-- opt-in: shows this toggle in the Active Features panel while it's on
	if config.TrackActive and Library._SetFeatureActive then
		Library._SetFeatureActive(rowFrame, config.Name or "Toggle", initialValue)
		rowFrame.Destroying:Connect(function()
			Library._SetFeatureActive(rowFrame, config.Name or "Toggle", false)
		end)
	end

	rowFrame.MouseEnter:Connect(function()
		tw(rowFrame, EASE_OUT_SOFT, { BackgroundColor3 = Theme.Plum600, BackgroundTransparency = 0.05 })
		tw(rowStroke, EASE_OUT_SOFT, { Transparency = 0.3 })
		tw(rowScale, EASE_OUT_SOFT, { Scale = 1.02 })
	end)

	rowFrame.MouseLeave:Connect(function()
		tw(rowFrame, EASE_OUT_SOFT, { BackgroundColor3 = Theme.Plum700, BackgroundTransparency = Alpha.CardFill })
		tw(rowStroke, EASE_OUT_SOFT, { Transparency = Alpha.Faint })
		tw(rowScale, EASE_OUT_SOFT, { Scale = 1 })
	end)

	rowFrame.MouseButton1Click:Connect(function()
		local downTween = tw(rowScale, EASE_QUICK, { Scale = 0.96 })
		downTween.Completed:Wait()
		tw(rowScale, EASE_QUICK, { Scale = 1 })
		toggleObject:Set(not toggleObject.Value, false)
	end)

	toggleObject.CreateKeybind = function(self, name, kbConfig)
		kbConfig = kbConfig or {}
		kbConfig.Name = kbConfig.Name or name
		return Elements.CreateKeybind(self.Instance.Parent, kbConfig)
	end
	toggleObject.CreateColorPicker = function(self, name, cpConfig)
		cpConfig = cpConfig or {}
		cpConfig.Name = cpConfig.Name or name
		return Elements.CreateColorPicker(self.Instance.Parent, cpConfig)
	end

	-- register hooks, then return
	if Library._RegisterFlag and config.Flag then
		Library._RegisterFlag(config.Flag, toggleObject)
	end

	if Library._RegisterSearchable then
		Library._RegisterSearchable(config.Name, rowFrame)
	end

	return toggleObject
end


-- ============================================================
-- Slider
-- ============================================================
-- Ivory Hub - Slider element
-- Elements.CreateSlider(parent, config)
-- config = {
--   Name = string,
--   Range = {min, max},
--   Increment = number | nil (default 1),
--   Suffix = string | nil,
--   CurrentValue = number,
--   Flag = string | nil,
--   Callback = function(value) end,
-- }

Elements.CreateSlider = function(parent, config)
    config = config or {}

    local sliderName = tostring(config.Name or config.Text or "Slider")
    local range = config.Range or config.Min and config.Max and {config.Min, config.Max} or {0, 100}
    local minVal = range[1] or 0
    local maxVal = range[2] or 100
    if maxVal < minVal then
        minVal, maxVal = maxVal, minVal
    end

    local increment = config.Increment or 1
    if increment <= 0 then
        increment = 1
    end

    local suffix = config.Suffix or ""

    -- CurrentValue is canonical; Default accepted as alias (SetupDefaultTabs
    -- in UIFEATURES.txt passes Default, which used to be silently ignored -> slider stuck at min)
    local initialValue = config.CurrentValue
    if initialValue == nil then
        initialValue = config.Default
    end
    if initialValue == nil then
        initialValue = minVal
    end
    initialValue = math.clamp(initialValue, minVal, maxVal)

    -- figure out how many decimal places to render based on Increment
    local function countDecimals(n)
        local s = tostring(n)
        local dotIndex = string.find(s, "%.")
        if not dotIndex then
            return 0
        end
        return #s - dotIndex
    end
    local decimalPlaces = countDecimals(increment)

    local function formatValue(v)
        if decimalPlaces <= 0 then
            return string.format("%d", math.floor(v + 0.5))
        else
            return string.format("%." .. decimalPlaces .. "f", v)
        end
    end

    ------------------------------------------------------------------
    -- build UI
    ------------------------------------------------------------------

    local rowFrame = Instance.new("Frame")
    rowFrame.Name = "Slider_" .. sliderName
    rowFrame.Size = UDim2.new(1, 0, 0, 54)
    rowFrame.BackgroundColor3 = Theme.Plum700
    rowFrame.BackgroundTransparency = Alpha.CardFill
    rowFrame.BorderSizePixel = 0
    rowFrame.ClipsDescendants = false
    rowFrame.ZIndex = 3
    rowFrame.Parent = parent

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = Radius.MD
    rowCorner.Parent = rowFrame

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Transparency = Alpha.Faint
    rowStroke.Thickness = 1
    rowStroke.Parent = rowFrame

    local rowPadding = Instance.new("UIPadding")
    rowPadding.PaddingLeft = UDim.new(0, 14)
    rowPadding.PaddingRight = UDim.new(0, 14)
    rowPadding.PaddingTop = UDim.new(0, 8)
    rowPadding.PaddingBottom = UDim.new(0, 6)
    rowPadding.Parent = rowFrame

    -- top line: name left, value right
    local topLine = Instance.new("Frame")
    topLine.Name = "TopLine"
    topLine.BackgroundTransparency = 1
    topLine.Size = UDim2.new(1, 0, 0, 16)
    topLine.Position = UDim2.new(0, 0, 0, 0)
    topLine.ZIndex = 4
    topLine.Parent = rowFrame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "Name"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.Font = Font.Medium
    nameLabel.TextSize = TextSizes.LG
    nameLabel.TextColor3 = Theme.TextPrimary
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextYAlignment = Enum.TextYAlignment.Center
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Text = sliderName
    nameLabel.ZIndex = 4
    nameLabel.Parent = topLine

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.BackgroundTransparency = 1
    valueLabel.Size = UDim2.new(0.4, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.6, 0, 0, 0)
    valueLabel.Font = Font.Body
    valueLabel.TextSize = TextSizes.LG
    valueLabel.TextColor3 = Theme.TextSecondary
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextYAlignment = Enum.TextYAlignment.Center
    valueLabel.Text = formatValue(initialValue) .. suffix
    valueLabel.ZIndex = 4
    valueLabel.Parent = topLine

    -- track hit area (the interactive control)
    local trackButton = Instance.new("TextButton")
    trackButton.Name = "Track"
    trackButton.AutoButtonColor = false
    trackButton.Text = ""
    trackButton.BackgroundTransparency = 1
    trackButton.Size = UDim2.new(1, 0, 0, 18)
    trackButton.Position = UDim2.new(0, 0, 0, 22)
    trackButton.ZIndex = 3
    trackButton.Parent = rowFrame

    local trackBG = Instance.new("Frame")
    trackBG.Name = "TrackBG"
    trackBG.AnchorPoint = Vector2.new(0, 0.5)
    trackBG.Position = UDim2.new(0, 0, 0.5, 0)
    trackBG.Size = UDim2.new(1, 0, 0, 6)
    trackBG.BackgroundColor3 = Theme.Plum600
    trackBG.BorderSizePixel = 0
    trackBG.ZIndex = 3
    trackBG.Parent = trackButton

    local trackBGCorner = Instance.new("UICorner")
    trackBGCorner.CornerRadius = Radius.Pill
    trackBGCorner.Parent = trackBG

    local fillBar = Instance.new("Frame")
    fillBar.Name = "Fill"
    fillBar.BackgroundColor3 = Theme.Blossom
    fillBar.BorderSizePixel = 0
    fillBar.Size = UDim2.new(0, 0, 1, 0)
    fillBar.ZIndex = 4
    fillBar.Parent = trackBG

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = Radius.Pill
    fillCorner.Parent = fillBar

    local thumb = Instance.new("Frame")
    thumb.Name = "Thumb"
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    thumb.Position = UDim2.new(0, 0, 0.5, 0)
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 5
    thumb.Parent = trackBG

    local thumbCorner = Instance.new("UICorner")
    thumbCorner.CornerRadius = Radius.Pill
    thumbCorner.Parent = thumb

    local thumbStroke = Instance.new("UIStroke")
    thumbStroke.Color = Theme.Blossom
    thumbStroke.Transparency = 0.4
    thumbStroke.Thickness = 1.5
    thumbStroke.Parent = thumb

    local thumbScale = Instance.new("UIScale")
    thumbScale.Scale = 1
    thumbScale.Parent = thumb

    ------------------------------------------------------------------
    -- value logic
    ------------------------------------------------------------------

    local controlObject = {}
    controlObject.Instance = rowFrame
    controlObject.Value = initialValue

    local dragging = false

    local function applyValue(newValue, silent)
        newValue = math.clamp(newValue, minVal, maxVal)

        local steps = math.floor((newValue - minVal) / increment + 0.5)
        newValue = minVal + (steps * increment)
        newValue = math.clamp(newValue, minVal, maxVal)

        controlObject.Value = newValue

        local span = maxVal - minVal
        local fillScale = 0
        if span > 0 then
            fillScale = (newValue - minVal) / span
        end
        fillScale = math.clamp(fillScale, 0, 1)

        if dragging then
            fillBar.Size = UDim2.new(fillScale, 0, 1, 0)
            thumb.Position = UDim2.new(fillScale, 0, 0.5, 0)
        else
            cancelTweens(fillBar)
            cancelTweens(thumb)
            tw(fillBar, EASE_QUICK, { Size = UDim2.new(fillScale, 0, 1, 0) })
            tw(thumb, EASE_QUICK, { Position = UDim2.new(fillScale, 0, 0.5, 0) })
        end
        valueLabel.Text = formatValue(newValue) .. suffix

        if not silent and config.Callback then
            pcall(config.Callback, newValue)
        end
    end

    function controlObject:Set(value, silent)
        applyValue(value, silent)
    end

    local function updateFromX(xPos)
        local trackPos = trackBG.AbsolutePosition.X
        local trackSize = trackBG.AbsoluteSize.X
        if trackSize <= 0 then
            return
        end
        local relative = (xPos - trackPos) / trackSize
        relative = math.clamp(relative, 0, 1)
        local raw = minVal + (relative * (maxVal - minVal))
        applyValue(raw, false)
    end

    ------------------------------------------------------------------
    -- input (mouse + touch), drag + click-to-jump
    ------------------------------------------------------------------

    local function setActiveVisual(active)
        tw(thumbScale, EASE_QUICK, {Scale = active and 1.15 or 1})
        tw(rowStroke, EASE_QUICK, {Transparency = active and 0.35 or 0.82})
        tw(thumbStroke, EASE_QUICK, {Transparency = active and 0.1 or 0.4})
    end

    trackButton.MouseEnter:Connect(function()
        if not dragging then
            tw(rowStroke, EASE_QUICK, {Transparency = 0.55})
        end
    end)

    trackButton.MouseLeave:Connect(function()
        if not dragging then
            tw(rowStroke, EASE_QUICK, {Transparency = Alpha.Faint})
        end
    end)

    trackButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            cancelTweens(fillBar)
            cancelTweens(thumb)
            setActiveVisual(true)
            updateFromX(input.Position.X)
        end
    end)

    local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            updateFromX(input.Position.X)
        end
    end)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if not dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            setActiveVisual(false)
        end
    end)

    rowFrame.Destroying:Connect(function()
        if inputChangedConn then
            inputChangedConn:Disconnect()
        end
        if inputEndedConn then
            inputEndedConn:Disconnect()
        end
    end)

    -- initial paint, no callback fire on construction
    applyValue(initialValue, true)

    ------------------------------------------------------------------
    -- registration hooks
    ------------------------------------------------------------------

    if Library._RegisterFlag and config.Flag then
        Library._RegisterFlag(config.Flag, controlObject)
    end

    if Library._RegisterSearchable then
        Library._RegisterSearchable(config.Name, rowFrame)
    end

    return controlObject
end


-- ============================================================
-- Dropdown + MultiDropdown
-- ============================================================
-- Ivory Hub - Dropdown + MultiDropdown elements
-- Single-select and multi-select dropdown controls with an inline option
-- panel that reflows the surrounding UIListLayout (no floating overlays).

do
    local function tableContains(tbl, val)
        for _, v in ipairs(tbl) do
            if v == val then
                return true
            end
        end
        return false
    end

    local function pointInGui(gui, pos)
        if not gui or not gui.Parent then
            return false
        end
        local ap = gui.AbsolutePosition
        local asz = gui.AbsoluteSize
        return pos.X >= ap.X and pos.X <= ap.X + asz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + asz.Y
    end

    -- Builds a chevron icon (two rotated bars) inside `container`, pointing
    -- down at Rotation 0. Rotate the returned holder 180 to point it up.
    local function addChevron(parent, color, zIndex)
        zIndex = zIndex or 1
        local holder = Instance.new("Frame")
        holder.Name = "Chevron"
        holder.AnchorPoint = Vector2.new(1, 0.5)
        holder.Position = UDim2.new(1, 0, 0.5, 0)
        holder.Size = UDim2.new(0, 12, 0, 12)
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.Rotation = 0
        holder.ZIndex = zIndex
        holder.Parent = parent

        local left = Instance.new("Frame")
        left.Name = "Left"
        left.AnchorPoint = Vector2.new(0.5, 0.5)
        left.Size = UDim2.new(0, 7, 0, 1.6)
        left.Position = UDim2.new(0.28, 0, 0.42, 0)
        left.Rotation = 45
        left.BackgroundColor3 = color
        left.BorderSizePixel = 0
        left.ZIndex = zIndex
        left.Parent = holder
        local leftCorner = Instance.new("UICorner")
        leftCorner.CornerRadius = Radius.Pill
        leftCorner.Parent = left

        local right = Instance.new("Frame")
        right.Name = "Right"
        right.AnchorPoint = Vector2.new(0.5, 0.5)
        right.Size = UDim2.new(0, 7, 0, 1.6)
        right.Position = UDim2.new(0.72, 0, 0.42, 0)
        right.Rotation = -45
        right.BackgroundColor3 = color
        right.BorderSizePixel = 0
        right.ZIndex = zIndex
        right.Parent = holder
        local rightCorner = Instance.new("UICorner")
        rightCorner.CornerRadius = Radius.Pill
        rightCorner.Parent = right

        return holder
    end

    -- Builds a checkmark (two rotated bars) inside `parent`, returns a holder
    -- Frame whose Visible property toggles the whole mark on/off.
    local function addCheckmark(parent, color, zIndex)
        zIndex = zIndex or 1
        local holder = Instance.new("Frame")
        holder.Name = "Checkmark"
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.new(0.5, 0, 0.5, 0)
        holder.Size = UDim2.new(1, 0, 1, 0)
        holder.BackgroundTransparency = 1
        holder.BorderSizePixel = 0
        holder.Visible = false
        holder.ZIndex = zIndex
        holder.Parent = parent

        local scale = Instance.new("UIScale")
        scale.Scale = 1
        scale.Parent = holder

        local short = Instance.new("Frame")
        short.Name = "Short"
        short.AnchorPoint = Vector2.new(0.5, 0.5)
        short.Size = UDim2.new(0, 5, 0, 1.6)
        short.Position = UDim2.new(0.33, 0, 0.56, 0)
        short.Rotation = 45
        short.BackgroundColor3 = color
        short.BorderSizePixel = 0
        short.ZIndex = zIndex
        short.Parent = holder
        local shortCorner = Instance.new("UICorner")
        shortCorner.CornerRadius = Radius.Pill
        shortCorner.Parent = short

        local long = Instance.new("Frame")
        long.Name = "Long"
        long.AnchorPoint = Vector2.new(0.5, 0.5)
        long.Size = UDim2.new(0, 9, 0, 1.6)
        long.Position = UDim2.new(0.6, 0, 0.4, 0)
        long.Rotation = -45
        long.BackgroundColor3 = color
        long.BorderSizePixel = 0
        long.ZIndex = zIndex
        long.Parent = holder
        local longCorner = Instance.new("UICorner")
        longCorner.CornerRadius = Radius.Pill
        longCorner.Parent = long

        return holder
    end

    ----------------------------------------------------------------
    -- CreateDropdown (single-select)
    ----------------------------------------------------------------
    Elements.CreateDropdown = function(parent, config)
        config = config or {}
        local options = config.Options or {}
        local initial = config.CurrentOption or config.Default
        if initial == nil or not tableContains(options, initial) then
            initial = options[1]
        end

        local rowFrame = Instance.new("Frame")
        rowFrame.Name = "Dropdown_" .. tostring(config.Name or config.Text or "Dropdown")
        rowFrame.BackgroundTransparency = 1
        rowFrame.BorderSizePixel = 0
        rowFrame.Size = UDim2.new(1, 0, 0, 0)
        rowFrame.AutomaticSize = Enum.AutomaticSize.Y
        rowFrame.ZIndex = 3
        rowFrame.Parent = parent

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 6)
        rowLayout.Parent = rowFrame

        local headerFrame = Instance.new("Frame")
        headerFrame.Name = "Header"
        headerFrame.LayoutOrder = 1
        headerFrame.Size = UDim2.new(1, 0, 0, 46)
        headerFrame.BackgroundColor3 = Theme.Plum700
        headerFrame.BackgroundTransparency = Alpha.CardFill
        headerFrame.BorderSizePixel = 0
        headerFrame.ZIndex = 3
        headerFrame.Parent = rowFrame

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = Radius.LG
        headerCorner.Parent = headerFrame

        local headerStroke = Instance.new("UIStroke")
        headerStroke.Thickness = 1
        headerStroke.Color = Color3.fromRGB(255, 255, 255)
        headerStroke.Transparency = Alpha.Faint
        headerStroke.Parent = headerFrame

        local headerPadding = Instance.new("UIPadding")
        headerPadding.PaddingLeft = UDim.new(0, 14)
        headerPadding.PaddingRight = UDim.new(0, 14)
        headerPadding.Parent = headerFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Label"
        nameLabel.BackgroundTransparency = 1
        nameLabel.BorderSizePixel = 0
        -- Proportional label + proportional pill (both scale with the
        -- row): the gap between them is a constant ~30px at every width,
        -- so shrinking the window keeps the label text instead of
        -- crushing it to a few characters, and neither can overlap or
        -- spill out of the card.
        nameLabel.Size = UDim2.new(0.55, -8, 1, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.Font = Font.Medium
        nameLabel.TextSize = TextSizes.LG
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Text = tostring(config.Name or config.Text or "Dropdown")
        nameLabel.ZIndex = 4
        nameLabel.Parent = headerFrame

        local pillButton = Instance.new("TextButton")
        pillButton.Name = "Pill"
        pillButton.AutoButtonColor = false
        pillButton.Text = ""
        pillButton.AnchorPoint = Vector2.new(1, 0.5)
        pillButton.Position = UDim2.new(1, 0, 0.5, 0)
        pillButton.Size = UDim2.new(0.45, -22, 0, 32)
        pillButton.BackgroundColor3 = Theme.Plum600
        pillButton.BackgroundTransparency = 0.1
        pillButton.BorderSizePixel = 0
        pillButton.ZIndex = 4
        pillButton.Parent = headerFrame
        local pillClamp = Instance.new("UISizeConstraint")
        pillClamp.MinSize = Vector2.new(64, 32)
        pillClamp.MaxSize = Vector2.new(176, 32)
        pillClamp.Parent = pillButton

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = Radius.Pill
        pillCorner.Parent = pillButton

        local pillStroke = Instance.new("UIStroke")
        pillStroke.Thickness = 1
        pillStroke.Color = Color3.fromRGB(255, 255, 255)
        pillStroke.Transparency = Alpha.Faint
        pillStroke.Parent = pillButton

        local pillScale = Instance.new("UIScale")
        pillScale.Scale = 1
        pillScale.Parent = pillButton

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.BackgroundTransparency = 1
        valueLabel.BorderSizePixel = 0
        valueLabel.Position = UDim2.new(0, 14, 0, 0)
        valueLabel.Size = UDim2.new(1, -40, 1, 0)
        valueLabel.Font = Font.Body
        valueLabel.TextSize = TextSizes.MD
        valueLabel.TextColor3 = Theme.TextSecondary
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextYAlignment = Enum.TextYAlignment.Center
        valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
        valueLabel.Text = tostring(initial ~= nil and initial or "Select...")
        valueLabel.ZIndex = 5
        valueLabel.Parent = pillButton

        local chevronIcon = addChevron(pillButton, Theme.TextSecondary, 5)

        local panelFrame = Instance.new("Frame")
        panelFrame.Name = "Panel"
        panelFrame.LayoutOrder = 2
        panelFrame.Size = UDim2.new(1, 0, 0, 0)
        panelFrame.BackgroundColor3 = Theme.Plum800
        panelFrame.BackgroundTransparency = 0.05
        panelFrame.BorderSizePixel = 0
        panelFrame.ClipsDescendants = true
        panelFrame.Visible = false
        panelFrame.ZIndex = 3
        panelFrame.Parent = rowFrame

        local panelCorner = Instance.new("UICorner")
        panelCorner.CornerRadius = Radius.MD
        panelCorner.Parent = panelFrame

        local panelStroke = Instance.new("UIStroke")
        panelStroke.Thickness = 1
        panelStroke.Color = Color3.fromRGB(255, 255, 255)
        panelStroke.Transparency = Alpha.Faint
        panelStroke.Parent = panelFrame

        local panelPadding = Instance.new("UIPadding")
        panelPadding.PaddingTop = UDim.new(0, 4)
        panelPadding.PaddingBottom = UDim.new(0, 4)
        panelPadding.Parent = panelFrame

        local panelLayout = Instance.new("UIListLayout")
        panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
        panelLayout.Padding = UDim.new(0, 0)
        panelLayout.Parent = panelFrame

        local isOpen = false
        local optionButtons = {}
        local dropdownObj

        local function calcPanelHeight()
            local count = #options
            if count == 0 then
                count = 1
            end
            return count * 36 + 8
        end

        local function updateIndicators()
            for _, entry in ipairs(optionButtons) do
                local selected = entry.Option == dropdownObj.Value
                if selected then
                    if not entry.Dot.Visible then
                        entry.Dot.Visible = true
                        local dotScale = entry.Dot:FindFirstChildOfClass("UIScale")
                        if dotScale then
                            cancelTweens(dotScale)
                            dotScale.Scale = 0.3
                            tw(dotScale, EASE_SPRING, { Scale = 1 })
                        end
                    end
                else
                    entry.Dot.Visible = false
                end
                entry.Label.TextColor3 = selected and Theme.TextPrimary or Theme.TextSecondary
            end
        end

        local outsideConn = nil
        local function disconnectOutside()
            if outsideConn then
                outsideConn:Disconnect()
                outsideConn = nil
            end
        end

        local closeTween = nil

        local function setOpen(open)
            isOpen = open
            if open then
                if closeTween then
                    closeTween:Cancel()
                    closeTween = nil
                end
                panelFrame.Visible = true
                tw(panelFrame, EASE_OUT_SOFT, {Size = UDim2.new(1, 0, 0, calcPanelHeight())})
                tw(chevronIcon, EASE_QUICK, {Rotation = 180})
                tw(pillStroke, EASE_QUICK, {Transparency = 0.25})
                disconnectOutside()
                outsideConn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local pos = input.Position
                        if not pointInGui(pillButton, pos) and not pointInGui(panelFrame, pos) then
                            setOpen(false)
                        end
                    end
                end)
            else
                tw(chevronIcon, EASE_QUICK, {Rotation = 0})
                tw(pillStroke, EASE_QUICK, {Transparency = Alpha.Faint})
                closeTween = tw(panelFrame, EASE_OUT_SOFT, {Size = UDim2.new(1, 0, 0, 0)})
                local thisTween = closeTween
                thisTween.Completed:Connect(function()
                    if not isOpen and closeTween == thisTween then
                        panelFrame.Visible = false
                    end
                end)
                disconnectOutside()
            end
        end

        local function buildOptionRows()
            for _, entry in ipairs(optionButtons) do
                entry.Button:Destroy()
            end
            table.clear(optionButtons)

            if #options == 0 then
                local emptyRow = Instance.new("Frame")
                emptyRow.Name = "Empty"
                emptyRow.LayoutOrder = 1
                emptyRow.Size = UDim2.new(1, 0, 0, 36)
                emptyRow.BackgroundTransparency = 1
                emptyRow.BorderSizePixel = 0
                emptyRow.ZIndex = 3
                emptyRow.Parent = panelFrame

                local emptyLabel = Instance.new("TextLabel")
                emptyLabel.BackgroundTransparency = 1
                emptyLabel.BorderSizePixel = 0
                emptyLabel.Size = UDim2.new(1, -28, 1, 0)
                emptyLabel.Position = UDim2.new(0, 14, 0, 0)
                emptyLabel.Font = Font.Body
                emptyLabel.TextSize = TextSizes.MD
                emptyLabel.TextColor3 = Theme.TextTertiary
                emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
                emptyLabel.Text = "No options"
                emptyLabel.ZIndex = 4
                emptyLabel.Parent = emptyRow
                return
            end

            for i, optionValue in ipairs(options) do
                local optCopy = optionValue
                local optionRow = Instance.new("TextButton")
                optionRow.Name = "Option_" .. tostring(i)
                optionRow.AutoButtonColor = false
                optionRow.Text = ""
                optionRow.LayoutOrder = i
                optionRow.Size = UDim2.new(1, 0, 0, 36)
                optionRow.BackgroundColor3 = Theme.Plum600
                optionRow.BackgroundTransparency = 1
                optionRow.BorderSizePixel = 0
                optionRow.ZIndex = 3
                optionRow.Parent = panelFrame

                local optCorner = Instance.new("UICorner")
                optCorner.CornerRadius = Radius.SM
                optCorner.Parent = optionRow

                local dot = Instance.new("Frame")
                dot.Name = "Dot"
                dot.AnchorPoint = Vector2.new(0, 0.5)
                dot.Position = UDim2.new(0, 14, 0.5, 0)
                dot.Size = UDim2.new(0, 6, 0, 6)
                dot.BackgroundColor3 = Theme.Blossom
                dot.BorderSizePixel = 0
                dot.Visible = (optCopy == dropdownObj.Value)
                dot.ZIndex = 4
                dot.Parent = optionRow

                local dotCorner = Instance.new("UICorner")
                dotCorner.CornerRadius = Radius.Pill
                dotCorner.Parent = dot

                local dotScale = Instance.new("UIScale")
                dotScale.Scale = 1
                dotScale.Parent = dot

                local optLabel = Instance.new("TextLabel")
                optLabel.BackgroundTransparency = 1
                optLabel.BorderSizePixel = 0
                optLabel.Position = UDim2.new(0, 32, 0, 0)
                optLabel.Size = UDim2.new(1, -46, 1, 0)
                optLabel.Font = Font.Body
                optLabel.TextSize = TextSizes.MD
                optLabel.TextColor3 = Theme.TextSecondary
                optLabel.TextXAlignment = Enum.TextXAlignment.Left
                optLabel.TextYAlignment = Enum.TextYAlignment.Center
                optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                optLabel.Text = tostring(optCopy)
                optLabel.ZIndex = 4
                optLabel.Parent = optionRow

                optionRow.MouseEnter:Connect(function()
                    tw(optionRow, EASE_QUICK, {BackgroundTransparency = 0.85})
                end)
                optionRow.MouseLeave:Connect(function()
                    tw(optionRow, EASE_QUICK, {BackgroundTransparency = 1})
                end)

                optionRow.Activated:Connect(function()
                    dropdownObj:Set(optCopy, false)
                    setOpen(false)
                end)

                table.insert(optionButtons, {Button = optionRow, Dot = dot, Label = optLabel, Option = optCopy})
            end

            updateIndicators()
        end

        pillButton.MouseEnter:Connect(function()
            tw(pillStroke, EASE_QUICK, {Transparency = isOpen and 0.25 or 0.4})
            tw(pillScale, EASE_QUICK, {Scale = 1.02})
        end)
        pillButton.MouseLeave:Connect(function()
            tw(pillStroke, EASE_QUICK, {Transparency = isOpen and 0.25 or 0.82})
            tw(pillScale, EASE_QUICK, {Scale = 1})
        end)
        pillButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tw(pillScale, EASE_QUICK, {Scale = 0.96})
            end
        end)
        pillButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tw(pillScale, EASE_QUICK, {Scale = 1.02})
            end
        end)
        pillButton.Activated:Connect(function()
            setOpen(not isOpen)
        end)

        dropdownObj = {
            Instance = rowFrame,
            Value = initial ~= nil and initial or "",
        }

        function dropdownObj:Set(option, silent)
            if option == nil then
                return
            end
            self.Value = option
            valueLabel.Text = tostring(option ~= "" and option or "Select...")
            updateIndicators()
            if not silent and type(config.Callback) == "function" then
                pcall(config.Callback, option)
            end
        end

        function dropdownObj:Refresh(newOptions)
            options = newOptions or {}
            config.Options = options
            buildOptionRows()
            if isOpen then
                tw(panelFrame, EASE_OUT_SOFT, {Size = UDim2.new(1, 0, 0, calcPanelHeight())})
            end
            if not tableContains(options, self.Value) then
                self:Set(options[1] ~= nil and options[1] or "", true)
            else
                updateIndicators()
            end
        end

        buildOptionRows()

        rowFrame.Destroying:Connect(function()
            disconnectOutside()
        end)

        if Library._RegisterFlag and config.Flag then
            Library._RegisterFlag(config.Flag, dropdownObj)
        end
        if Library._RegisterSearchable then
            Library._RegisterSearchable(config.Name, rowFrame)
        end

        return dropdownObj
    end

    ----------------------------------------------------------------
    -- CreateMultiDropdown (multi-select)
    ----------------------------------------------------------------
    Elements.CreateMultiDropdown = function(parent, config)
        config = config or {}
        local options = config.Options or {}
        local initialValues = {}
        if config.CurrentOption then
            for _, v in ipairs(config.CurrentOption) do
                if tableContains(options, v) and not tableContains(initialValues, v) then
                    table.insert(initialValues, v)
                end
            end
        end

        local rowFrame = Instance.new("Frame")
        rowFrame.Name = "MultiDropdown_" .. tostring(config.Name or "MultiDropdown")
        rowFrame.BackgroundTransparency = 1
        rowFrame.BorderSizePixel = 0
        rowFrame.Size = UDim2.new(1, 0, 0, 0)
        rowFrame.AutomaticSize = Enum.AutomaticSize.Y
        rowFrame.ZIndex = 3
        rowFrame.Parent = parent

        local rowLayout = Instance.new("UIListLayout")
        rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rowLayout.Padding = UDim.new(0, 6)
        rowLayout.Parent = rowFrame

        local headerFrame = Instance.new("Frame")
        headerFrame.Name = "Header"
        headerFrame.LayoutOrder = 1
        headerFrame.Size = UDim2.new(1, 0, 0, 46)
        headerFrame.BackgroundColor3 = Theme.Plum700
        headerFrame.BackgroundTransparency = Alpha.CardFill
        headerFrame.BorderSizePixel = 0
        headerFrame.ZIndex = 3
        headerFrame.Parent = rowFrame

        local headerCorner = Instance.new("UICorner")
        headerCorner.CornerRadius = Radius.LG
        headerCorner.Parent = headerFrame

        local headerStroke = Instance.new("UIStroke")
        headerStroke.Thickness = 1
        headerStroke.Color = Color3.fromRGB(255, 255, 255)
        headerStroke.Transparency = Alpha.Faint
        headerStroke.Parent = headerFrame

        local headerPadding = Instance.new("UIPadding")
        headerPadding.PaddingLeft = UDim.new(0, 14)
        headerPadding.PaddingRight = UDim.new(0, 14)
        headerPadding.Parent = headerFrame

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Label"
        nameLabel.BackgroundTransparency = 1
        nameLabel.BorderSizePixel = 0
        -- Same proportional split as the single dropdown: label keeps
        -- its share of the text at every window size, pill shrinks with
        -- the row (constant ~32px gap, never overlapping).
        nameLabel.Size = UDim2.new(0.5, -8, 1, 0)
        nameLabel.Position = UDim2.new(0, 0, 0, 0)
        nameLabel.Font = Font.Medium
        nameLabel.TextSize = TextSizes.LG
        nameLabel.TextColor3 = Theme.TextPrimary
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextYAlignment = Enum.TextYAlignment.Center
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Text = tostring(config.Name or "MultiDropdown")
        nameLabel.ZIndex = 4
        nameLabel.Parent = headerFrame

        local pillButton = Instance.new("TextButton")
        pillButton.Name = "Pill"
        pillButton.AutoButtonColor = false
        pillButton.Text = ""
        pillButton.AnchorPoint = Vector2.new(1, 0.5)
        pillButton.Position = UDim2.new(1, 0, 0.5, 0)
        pillButton.Size = UDim2.new(0.5, -24, 0, 32)
        pillButton.BackgroundColor3 = Theme.Plum600
        pillButton.BackgroundTransparency = 0.1
        pillButton.BorderSizePixel = 0
        pillButton.ZIndex = 4
        pillButton.Parent = headerFrame
        local pillClamp = Instance.new("UISizeConstraint")
        pillClamp.MinSize = Vector2.new(64, 32)
        pillClamp.MaxSize = Vector2.new(190, 32)
        pillClamp.Parent = pillButton

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = Radius.Pill
        pillCorner.Parent = pillButton

        local pillStroke = Instance.new("UIStroke")
        pillStroke.Thickness = 1
        pillStroke.Color = Color3.fromRGB(255, 255, 255)
        pillStroke.Transparency = Alpha.Faint
        pillStroke.Parent = pillButton

        local pillScale = Instance.new("UIScale")
        pillScale.Scale = 1
        pillScale.Parent = pillButton

        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.BackgroundTransparency = 1
        valueLabel.BorderSizePixel = 0
        valueLabel.Position = UDim2.new(0, 14, 0, 0)
        valueLabel.Size = UDim2.new(1, -40, 1, 0)
        valueLabel.Font = Font.Body
        valueLabel.TextSize = TextSizes.MD
        valueLabel.TextColor3 = Theme.TextSecondary
        valueLabel.TextXAlignment = Enum.TextXAlignment.Left
        valueLabel.TextYAlignment = Enum.TextYAlignment.Center
        valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
        valueLabel.Text = "None"
        valueLabel.ZIndex = 5
        valueLabel.Parent = pillButton

        local chevronIcon = addChevron(pillButton, Theme.TextSecondary, 5)

        local panelFrame = Instance.new("Frame")
        panelFrame.Name = "Panel"
        panelFrame.LayoutOrder = 2
        panelFrame.Size = UDim2.new(1, 0, 0, 0)
        panelFrame.BackgroundColor3 = Theme.Plum800
        panelFrame.BackgroundTransparency = 0.05
        panelFrame.BorderSizePixel = 0
        panelFrame.ClipsDescendants = true
        panelFrame.Visible = false
        panelFrame.ZIndex = 3
        panelFrame.Parent = rowFrame

        local panelCorner = Instance.new("UICorner")
        panelCorner.CornerRadius = Radius.MD
        panelCorner.Parent = panelFrame

        local panelStroke = Instance.new("UIStroke")
        panelStroke.Thickness = 1
        panelStroke.Color = Color3.fromRGB(255, 255, 255)
        panelStroke.Transparency = Alpha.Faint
        panelStroke.Parent = panelFrame

        local panelPadding = Instance.new("UIPadding")
        panelPadding.PaddingTop = UDim.new(0, 4)
        panelPadding.PaddingBottom = UDim.new(0, 4)
        panelPadding.Parent = panelFrame

        local panelLayout = Instance.new("UIListLayout")
        panelLayout.SortOrder = Enum.SortOrder.LayoutOrder
        panelLayout.Padding = UDim.new(0, 0)
        panelLayout.Parent = panelFrame

        local isOpen = false
        local optionButtons = {}
        local multiObj

        local function calcPanelHeight()
            local count = #options
            if count == 0 then
                count = 1
            end
            return count * 36 + 8
        end

        local function summarize(values)
            if #values == 0 then
                return "None"
            elseif #values <= 2 then
                return table.concat(values, ", ")
            else
                return tostring(#values) .. " selected"
            end
        end

        local function updateSummary()
            valueLabel.Text = summarize(multiObj.Value)
        end

        local function isSelected(option)
            return tableContains(multiObj.Value, option)
        end

        local function updateIndicators()
            for _, entry in ipairs(optionButtons) do
                local selected = isSelected(entry.Option)
                if selected then
                    if not entry.Check.Visible then
                        entry.Check.Visible = true
                        local checkScale = entry.Check:FindFirstChildOfClass("UIScale")
                        if checkScale then
                            cancelTweens(checkScale)
                            checkScale.Scale = 0.4
                            tw(checkScale, EASE_SPRING, { Scale = 1 })
                        end
                    end
                else
                    entry.Check.Visible = false
                end
                tw(entry.CheckboxStroke, EASE_QUICK, {Transparency = selected and 0.15 or 0.7})
                entry.Label.TextColor3 = selected and Theme.TextPrimary or Theme.TextSecondary
            end
        end

        local outsideConn = nil
        local function disconnectOutside()
            if outsideConn then
                outsideConn:Disconnect()
                outsideConn = nil
            end
        end

        local closeTween = nil

        local function setOpen(open)
            isOpen = open
            if open then
                if closeTween then
                    closeTween:Cancel()
                    closeTween = nil
                end
                panelFrame.Visible = true
                tw(panelFrame, EASE_OUT_SOFT, {Size = UDim2.new(1, 0, 0, calcPanelHeight())})
                tw(chevronIcon, EASE_QUICK, {Rotation = 180})
                tw(pillStroke, EASE_QUICK, {Transparency = 0.25})
                disconnectOutside()
                outsideConn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local pos = input.Position
                        if not pointInGui(pillButton, pos) and not pointInGui(panelFrame, pos) then
                            setOpen(false)
                        end
                    end
                end)
            else
                tw(chevronIcon, EASE_QUICK, {Rotation = 0})
                tw(pillStroke, EASE_QUICK, {Transparency = Alpha.Faint})
                closeTween = tw(panelFrame, EASE_OUT_SOFT, {Size = UDim2.new(1, 0, 0, 0)})
                local thisTween = closeTween
                thisTween.Completed:Connect(function()
                    if not isOpen and closeTween == thisTween then
                        panelFrame.Visible = false
                    end
                end)
                disconnectOutside()
            end
        end

        local function toggleOption(option)
            if isSelected(option) then
                for i, v in ipairs(multiObj.Value) do
                    if v == option then
                        table.remove(multiObj.Value, i)
                        break
                    end
                end
            else
                table.insert(multiObj.Value, option)
            end
            updateSummary()
            updateIndicators()
            if type(config.Callback) == "function" then
                local copy = {}
                for i, v in ipairs(multiObj.Value) do
                    copy[i] = v
                end
                pcall(config.Callback, copy)
            end
        end

        local function buildOptionRows()
            for _, entry in ipairs(optionButtons) do
                entry.Button:Destroy()
            end
            table.clear(optionButtons)

            if #options == 0 then
                local emptyRow = Instance.new("Frame")
                emptyRow.Name = "Empty"
                emptyRow.LayoutOrder = 1
                emptyRow.Size = UDim2.new(1, 0, 0, 36)
                emptyRow.BackgroundTransparency = 1
                emptyRow.BorderSizePixel = 0
                emptyRow.ZIndex = 3
                emptyRow.Parent = panelFrame

                local emptyLabel = Instance.new("TextLabel")
                emptyLabel.BackgroundTransparency = 1
                emptyLabel.BorderSizePixel = 0
                emptyLabel.Size = UDim2.new(1, -28, 1, 0)
                emptyLabel.Position = UDim2.new(0, 14, 0, 0)
                emptyLabel.Font = Font.Body
                emptyLabel.TextSize = TextSizes.MD
                emptyLabel.TextColor3 = Theme.TextTertiary
                emptyLabel.TextXAlignment = Enum.TextXAlignment.Left
                emptyLabel.Text = "No options"
                emptyLabel.ZIndex = 4
                emptyLabel.Parent = emptyRow
                return
            end

            for i, optionValue in ipairs(options) do
                local optCopy = optionValue
                local optionRow = Instance.new("TextButton")
                optionRow.Name = "Option_" .. tostring(i)
                optionRow.AutoButtonColor = false
                optionRow.Text = ""
                optionRow.LayoutOrder = i
                optionRow.Size = UDim2.new(1, 0, 0, 36)
                optionRow.BackgroundColor3 = Theme.Plum600
                optionRow.BackgroundTransparency = 1
                optionRow.BorderSizePixel = 0
                optionRow.ZIndex = 3
                optionRow.Parent = panelFrame

                local optCorner = Instance.new("UICorner")
                optCorner.CornerRadius = Radius.SM
                optCorner.Parent = optionRow

                local checkbox = Instance.new("Frame")
                checkbox.Name = "Checkbox"
                checkbox.AnchorPoint = Vector2.new(0, 0.5)
                checkbox.Position = UDim2.new(0, 12, 0.5, 0)
                checkbox.Size = UDim2.new(0, 16, 0, 16)
                checkbox.BackgroundColor3 = Theme.Plum700
                checkbox.BorderSizePixel = 0
                checkbox.ZIndex = 4
                checkbox.Parent = optionRow

                local checkboxCorner = Instance.new("UICorner")
                checkboxCorner.CornerRadius = Radius.Tiny
                checkboxCorner.Parent = checkbox

                local checkboxStroke = Instance.new("UIStroke")
                checkboxStroke.Thickness = 1
                checkboxStroke.Color = Color3.fromRGB(255, 255, 255)
                checkboxStroke.Transparency = 0.7
                checkboxStroke.Parent = checkbox

                local checkHolder = addCheckmark(checkbox, Theme.Blossom, 5)

                local optLabel = Instance.new("TextLabel")
                optLabel.BackgroundTransparency = 1
                optLabel.BorderSizePixel = 0
                optLabel.Position = UDim2.new(0, 38, 0, 0)
                optLabel.Size = UDim2.new(1, -52, 1, 0)
                optLabel.Font = Font.Body
                optLabel.TextSize = TextSizes.MD
                optLabel.TextColor3 = Theme.TextSecondary
                optLabel.TextXAlignment = Enum.TextXAlignment.Left
                optLabel.TextYAlignment = Enum.TextYAlignment.Center
                optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                optLabel.Text = tostring(optCopy)
                optLabel.ZIndex = 4
                optLabel.Parent = optionRow

                optionRow.MouseEnter:Connect(function()
                    tw(optionRow, EASE_QUICK, {BackgroundTransparency = 0.85})
                end)
                optionRow.MouseLeave:Connect(function()
                    tw(optionRow, EASE_QUICK, {BackgroundTransparency = 1})
                end)

                optionRow.Activated:Connect(function()
                    toggleOption(optCopy)
                end)

                table.insert(optionButtons, {
                    Button = optionRow,
                    Check = checkHolder,
                    CheckboxStroke = checkboxStroke,
                    Label = optLabel,
                    Option = optCopy,
                })
            end

            updateIndicators()
        end

        pillButton.MouseEnter:Connect(function()
            tw(pillStroke, EASE_QUICK, {Transparency = isOpen and 0.25 or 0.4})
            tw(pillScale, EASE_QUICK, {Scale = 1.02})
        end)
        pillButton.MouseLeave:Connect(function()
            tw(pillStroke, EASE_QUICK, {Transparency = isOpen and 0.25 or 0.82})
            tw(pillScale, EASE_QUICK, {Scale = 1})
        end)
        pillButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tw(pillScale, EASE_QUICK, {Scale = 0.96})
            end
        end)
        pillButton.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                tw(pillScale, EASE_QUICK, {Scale = 1.02})
            end
        end)
        pillButton.Activated:Connect(function()
            setOpen(not isOpen)
        end)

        multiObj = {
            Instance = rowFrame,
            Value = initialValues,
        }

        function multiObj:Set(optionsArray, silent)
            local newValues = {}
            if optionsArray then
                for _, v in ipairs(optionsArray) do
                    if tableContains(options, v) and not tableContains(newValues, v) then
                        table.insert(newValues, v)
                    end
                end
            end
            self.Value = newValues
            updateSummary()
            updateIndicators()
            if not silent and type(config.Callback) == "function" then
                local copy = {}
                for i, v in ipairs(self.Value) do
                    copy[i] = v
                end
                pcall(config.Callback, copy)
            end
        end

        function multiObj:Refresh(newOptions)
            options = newOptions or {}
            config.Options = options
            local filtered = {}
            for _, v in ipairs(self.Value) do
                if tableContains(options, v) then
                    table.insert(filtered, v)
                end
            end
            self.Value = filtered
            buildOptionRows()
            updateSummary()
            if isOpen then
                tw(panelFrame, EASE_OUT_SOFT, {Size = UDim2.new(1, 0, 0, calcPanelHeight())})
            end
        end

        buildOptionRows()
        updateSummary()

        rowFrame.Destroying:Connect(function()
            disconnectOutside()
        end)

        if Library._RegisterFlag and config.Flag then
            Library._RegisterFlag(config.Flag, multiObj)
        end
        if Library._RegisterSearchable then
            Library._RegisterSearchable(config.Name, rowFrame)
        end

        return multiObj
    end
end


-- ============================================================
-- ColorPicker
-- ============================================================
-- Ivory Hub - ColorPicker element
-- Closed row with a live swatch; expands into a saturation/value field,
-- a hue strip, and a synced hex input. Plain-ASCII, no images/fonts.

Elements.CreateColorPicker = function(parent, config)
	config = config or {}

	local pickerName = config.Name or config.Text or "Color Picker"
	local initialColor = config.Color or config.Default or Color3.fromRGB(255, 255, 255)
	local flag = config.Flag
	local callback = config.Callback or function() end

	local hue, sat, val = initialColor:ToHSV()
	local color = initialColor

	local PANEL_HEIGHT = 236

	-- ===== helpers =====

	local function toHex(c)
		return string.format(
			"#%02X%02X%02X",
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5)
		)
	end

	local function hexToColor3(text)
		local clean = text:gsub("#", ""):gsub("%s+", "")
		if #clean == 3 then
			local r, g, b = clean:sub(1, 1), clean:sub(2, 2), clean:sub(3, 3)
			clean = r .. r .. g .. g .. b .. b
		end
		if #clean ~= 6 then
			return nil
		end
		if not clean:match("^%x%x%x%x%x%x$") then
			return nil
		end
		local num = tonumber(clean, 16)
		if not num then
			return nil
		end
		local r = math.floor(num / 65536) % 256
		local g = math.floor(num / 256) % 256
		local b = num % 256
		return Color3.fromRGB(r, g, b)
	end

	-- ===== root layout =====

	local Container = Instance.new("Frame")
	Container.Name = "ColorPicker"
	Container.BackgroundTransparency = 1
	Container.Size = UDim2.new(1, 0, 0, 46)
	Container.AutomaticSize = Enum.AutomaticSize.Y
	Container.ZIndex = 3
	Container.Parent = parent

	local ContainerLayout = Instance.new("UIListLayout")
	ContainerLayout.FillDirection = Enum.FillDirection.Vertical
	ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContainerLayout.Padding = UDim.new(0, 8)
	ContainerLayout.Parent = Container

	-- ===== closed row =====

	local Row = Instance.new("Frame")
	Row.Name = "Row"
	Row.LayoutOrder = 1
	Row.Size = UDim2.new(1, 0, 0, 46)
	Row.BackgroundColor3 = Theme.Plum700
	Row.BackgroundTransparency = Alpha.CardFill
	Row.BorderSizePixel = 0
	Row.ZIndex = 3
	Row.Parent = Container

	local RowCorner = Instance.new("UICorner")
	RowCorner.CornerRadius = Radius.MD
	RowCorner.Parent = Row

	local NameLabel = Instance.new("TextLabel")
	NameLabel.Name = "NameLabel"
	NameLabel.BackgroundTransparency = 1
	NameLabel.Position = UDim2.new(0, 14, 0, 0)
	NameLabel.Size = UDim2.new(1, -70, 1, 0)
	NameLabel.Font = Font.Medium
	NameLabel.TextSize = TextSizes.LG
	NameLabel.TextColor3 = Theme.TextPrimary
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	NameLabel.Text = pickerName
	NameLabel.ZIndex = 4
	NameLabel.Parent = Row

	local SwatchButton = Instance.new("TextButton")
	SwatchButton.Name = "SwatchButton"
	SwatchButton.AnchorPoint = Vector2.new(1, 0.5)
	SwatchButton.Position = UDim2.new(1, -14, 0.5, 0)
	SwatchButton.Size = UDim2.new(0, 28, 0, 28)
	SwatchButton.BackgroundTransparency = 1
	SwatchButton.AutoButtonColor = false
	SwatchButton.Text = ""
	SwatchButton.ZIndex = 4
	SwatchButton.Parent = Row

	local SwatchScale = Instance.new("UIScale")
	SwatchScale.Scale = 1
	SwatchScale.Parent = SwatchButton

	local SwatchFill = Instance.new("Frame")
	SwatchFill.Name = "SwatchFill"
	SwatchFill.Size = UDim2.new(1, 0, 1, 0)
	SwatchFill.BackgroundColor3 = color
	SwatchFill.BorderSizePixel = 0
	SwatchFill.ZIndex = 5
	SwatchFill.Parent = SwatchButton

	local SwatchCorner = Instance.new("UICorner")
	SwatchCorner.CornerRadius = Radius.SM
	SwatchCorner.Parent = SwatchFill

	local SwatchStroke = Instance.new("UIStroke")
	SwatchStroke.Thickness = 1.5
	SwatchStroke.Color = Theme.Plum700
	SwatchStroke.Transparency = 0.1
	SwatchStroke.Parent = SwatchFill

	-- ===== expandable panel =====

	local Panel = Instance.new("Frame")
	Panel.Name = "Panel"
	Panel.LayoutOrder = 2
	Panel.Size = UDim2.new(1, 0, 0, 0)
	Panel.BackgroundColor3 = Theme.Plum800
	Panel.BackgroundTransparency = 0.05
	Panel.BorderSizePixel = 0
	Panel.ClipsDescendants = true
	Panel.ZIndex = 3
	Panel.Parent = Container

	local PanelCorner = Instance.new("UICorner")
	PanelCorner.CornerRadius = Radius.LG
	PanelCorner.Parent = Panel

	local PanelStroke = Instance.new("UIStroke")
	PanelStroke.Thickness = 1
	PanelStroke.Color = Color3.fromRGB(255, 255, 255)
	PanelStroke.Transparency = Alpha.Faint
	PanelStroke.Parent = Panel

	local ContentHolder = Instance.new("Frame")
	ContentHolder.Name = "ContentHolder"
	ContentHolder.BackgroundTransparency = 1
	ContentHolder.Size = UDim2.new(1, 0, 0, PANEL_HEIGHT)
	ContentHolder.ZIndex = 4
	ContentHolder.Parent = Panel

	local ContentPadding = Instance.new("UIPadding")
	ContentPadding.PaddingTop = UDim.new(0, 12)
	ContentPadding.PaddingBottom = UDim.new(0, 12)
	ContentPadding.PaddingLeft = UDim.new(0, 12)
	ContentPadding.PaddingRight = UDim.new(0, 12)
	ContentPadding.Parent = ContentHolder

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.FillDirection = Enum.FillDirection.Vertical
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ContentLayout.Padding = UDim.new(0, 10)
	ContentLayout.Parent = ContentHolder

	-- ===== saturation / value field =====

	local SatValContainer = Instance.new("Frame")
	SatValContainer.Name = "SatValContainer"
	SatValContainer.LayoutOrder = 1
	SatValContainer.Size = UDim2.new(0, 140, 0, 140)
	SatValContainer.BackgroundTransparency = 1
	SatValContainer.Active = true
	SatValContainer.ZIndex = 3
	SatValContainer.Parent = ContentHolder

	local SatValBase = Instance.new("Frame")
	SatValBase.Name = "SatValBase"
	SatValBase.Size = UDim2.new(1, 0, 1, 0)
	SatValBase.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SatValBase.BorderSizePixel = 0
	SatValBase.ClipsDescendants = true
	SatValBase.ZIndex = 3
	SatValBase.Parent = SatValContainer

	local SatValBaseCorner = Instance.new("UICorner")
	SatValBaseCorner.CornerRadius = Radius.MD
	SatValBaseCorner.Parent = SatValBase

	local BaseGradient = Instance.new("UIGradient")
	BaseGradient.Rotation = 0
	BaseGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1))
	BaseGradient.Parent = SatValBase

	local ValOverlay = Instance.new("Frame")
	ValOverlay.Name = "ValOverlay"
	ValOverlay.Size = UDim2.new(1, 0, 1, 0)
	ValOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	ValOverlay.BackgroundTransparency = 0
	ValOverlay.BorderSizePixel = 0
	ValOverlay.ZIndex = 4
	ValOverlay.Parent = SatValBase

	local OverlayGradient = Instance.new("UIGradient")
	OverlayGradient.Rotation = 90
	OverlayGradient.Color = ColorSequence.new(Color3.new(0, 0, 0))
	OverlayGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})
	OverlayGradient.Parent = ValOverlay

	local SVMarker = Instance.new("Frame")
	SVMarker.Name = "SVMarker"
	SVMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	SVMarker.Size = UDim2.new(0, 12, 0, 12)
	SVMarker.Position = UDim2.new(sat, 0, 1 - val, 0)
	SVMarker.BackgroundColor3 = Color3.new(1, 1, 1)
	SVMarker.BorderSizePixel = 0
	SVMarker.ZIndex = 5
	SVMarker.Parent = SatValContainer

	local SVMarkerCorner = Instance.new("UICorner")
	SVMarkerCorner.CornerRadius = Radius.Pill
	SVMarkerCorner.Parent = SVMarker

	local SVMarkerStroke = Instance.new("UIStroke")
	SVMarkerStroke.Thickness = 1.5
	SVMarkerStroke.Color = Color3.new(0, 0, 0)
	SVMarkerStroke.Transparency = 0.2
	SVMarkerStroke.Parent = SVMarker

	-- ===== hue strip =====

	local HueContainer = Instance.new("Frame")
	HueContainer.Name = "HueContainer"
	HueContainer.LayoutOrder = 2
	HueContainer.Size = UDim2.new(0, 140, 0, 20)
	HueContainer.BackgroundTransparency = 1
	HueContainer.Active = true
	HueContainer.ZIndex = 3
	HueContainer.Parent = ContentHolder

	local HueStripFrame = Instance.new("Frame")
	HueStripFrame.Name = "HueStripFrame"
	HueStripFrame.AnchorPoint = Vector2.new(0, 0.5)
	HueStripFrame.Position = UDim2.new(0, 0, 0.5, 0)
	HueStripFrame.Size = UDim2.new(1, 0, 0, 14)
	HueStripFrame.BackgroundColor3 = Color3.new(1, 1, 1)
	HueStripFrame.BorderSizePixel = 0
	HueStripFrame.ClipsDescendants = true
	HueStripFrame.ZIndex = 3
	HueStripFrame.Parent = HueContainer

	local HueStripCorner = Instance.new("UICorner")
	HueStripCorner.CornerRadius = Radius.XS
	HueStripCorner.Parent = HueStripFrame

	local HueGradient = Instance.new("UIGradient")
	HueGradient.Rotation = 0
	HueGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
		ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
		ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
		ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
		ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
	})
	HueGradient.Parent = HueStripFrame

	local HueMarker = Instance.new("Frame")
	HueMarker.Name = "HueMarker"
	HueMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	HueMarker.Size = UDim2.new(0, 6, 0, 18)
	HueMarker.Position = UDim2.new(hue, 0, 0.5, 0)
	HueMarker.BackgroundColor3 = Color3.new(1, 1, 1)
	HueMarker.BorderSizePixel = 0
	HueMarker.ZIndex = 5
	HueMarker.Parent = HueContainer

	local HueMarkerCorner = Instance.new("UICorner")
	HueMarkerCorner.CornerRadius = Radius.Micro
	HueMarkerCorner.Parent = HueMarker

	local HueMarkerStroke = Instance.new("UIStroke")
	HueMarkerStroke.Thickness = 1.5
	HueMarkerStroke.Color = Color3.new(0, 0, 0)
	HueMarkerStroke.Transparency = 0.2
	HueMarkerStroke.Parent = HueMarker

	-- ===== hex input =====

	local HexRow = Instance.new("Frame")
	HexRow.Name = "HexRow"
	HexRow.LayoutOrder = 3
	HexRow.Size = UDim2.new(0, 140, 0, 32)
	HexRow.BackgroundColor3 = Theme.Plum700
	HexRow.BackgroundTransparency = Alpha.CardFill
	HexRow.BorderSizePixel = 0
	HexRow.ZIndex = 4
	HexRow.Parent = ContentHolder

	local HexRowCorner = Instance.new("UICorner")
	HexRowCorner.CornerRadius = Radius.SM
	HexRowCorner.Parent = HexRow

	local HexRowStroke = Instance.new("UIStroke")
	HexRowStroke.Thickness = 1
	HexRowStroke.Color = Color3.fromRGB(255, 255, 255)
	HexRowStroke.Transparency = Alpha.Faint
	HexRowStroke.Parent = HexRow

	local HexBox = Instance.new("TextBox")
	HexBox.Name = "HexBox"
	HexBox.BackgroundTransparency = 1
	HexBox.Position = UDim2.new(0, 10, 0, 0)
	HexBox.Size = UDim2.new(1, -20, 1, 0)
	HexBox.Font = Font.Body
	HexBox.TextSize = TextSizes.MD
	HexBox.TextColor3 = Theme.TextPrimary
	HexBox.PlaceholderColor3 = Theme.TextTertiary
	HexBox.PlaceholderText = "#RRGGBB"
	HexBox.ClearTextOnFocus = false
	HexBox.Text = toHex(color)
	HexBox.TextXAlignment = Enum.TextXAlignment.Left
	HexBox.ZIndex = 5
	HexBox.Parent = HexRow

	-- ===== state application =====

	local controlObject

	local function refreshVisuals()
		SwatchFill.BackgroundColor3 = color
		BaseGradient.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(hue, 1, 1))
		SVMarker.Position = UDim2.new(sat, 0, 1 - val, 0)
		HueMarker.Position = UDim2.new(hue, 0, 0.5, 0)
		if not HexBox:IsFocused() then
			HexBox.Text = toHex(color)
		end
	end

	local function applyState(fireCallback)
		color = Color3.fromHSV(hue, sat, val)
		if controlObject then
			controlObject.Value = color
		end
		refreshVisuals()
		if fireCallback then
			pcall(callback, color)
		end
	end

	-- ===== drag handling (mouse + touch) =====

	local draggingSV = false
	local draggingHue = false

	local function isPointerInputType(inputType)
		return inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch
	end

	local function updateSVFromInput(input)
		local abs = SatValContainer.AbsolutePosition
		local size = SatValContainer.AbsoluteSize
		if size.X <= 0 or size.Y <= 0 then
			return
		end
		local relX = (input.Position.X - abs.X) / size.X
		local relY = (input.Position.Y - abs.Y) / size.Y
		sat = math.clamp(relX, 0, 1)
		val = 1 - math.clamp(relY, 0, 1)
		applyState(true)
	end

	local function updateHueFromInput(input)
		local abs = HueContainer.AbsolutePosition
		local size = HueContainer.AbsoluteSize
		if size.X <= 0 then
			return
		end
		local relX = (input.Position.X - abs.X) / size.X
		hue = math.clamp(relX, 0, 1)
		applyState(true)
	end

	SatValContainer.InputBegan:Connect(function(input)
		if isPointerInputType(input.UserInputType) then
			draggingSV = true
			updateSVFromInput(input)
		end
	end)

	HueContainer.InputBegan:Connect(function(input)
		if isPointerInputType(input.UserInputType) then
			draggingHue = true
			updateHueFromInput(input)
		end
	end)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if draggingSV then
				updateSVFromInput(input)
			elseif draggingHue then
				updateHueFromInput(input)
			end
		end
	end)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if isPointerInputType(input.UserInputType) then
			draggingSV = false
			draggingHue = false
		end
	end)

	Container.Destroying:Connect(function()
		inputChangedConn:Disconnect()
		inputEndedConn:Disconnect()
	end)

	-- ===== hex sync =====

	HexBox.Focused:Connect(function()
		tw(HexRowStroke, EASE_QUICK, { Transparency = 0.25 })
	end)

	HexBox.FocusLost:Connect(function()
		tw(HexRowStroke, EASE_QUICK, { Transparency = Alpha.Faint })
		local parsed = hexToColor3(HexBox.Text)
		if parsed then
			hue, sat, val = parsed:ToHSV()
			applyState(true)
		else
			HexBox.Text = toHex(color)
		end
	end)

	-- ===== expand / collapse =====

	local expanded = false

	SwatchButton.MouseEnter:Connect(function()
		tw(SwatchStroke, EASE_QUICK, { Color = Theme.Blossom, Transparency = 0 })
		tw(SwatchScale, EASE_QUICK, { Scale = 1.02 })
	end)

	SwatchButton.MouseLeave:Connect(function()
		tw(SwatchStroke, EASE_QUICK, { Color = Theme.Plum700, Transparency = 0.1 })
		tw(SwatchScale, EASE_QUICK, { Scale = 1 })
	end)

	SwatchButton.MouseButton1Down:Connect(function()
		tw(SwatchScale, EASE_QUICK, { Scale = 0.96 })
	end)

	SwatchButton.MouseButton1Up:Connect(function()
		tw(SwatchScale, EASE_QUICK, { Scale = 1.02 })
	end)

	SwatchButton.MouseButton1Click:Connect(function()
		expanded = not expanded
		if expanded then
			tw(Panel, EASE_OUT_SOFT, { Size = UDim2.new(1, 0, 0, PANEL_HEIGHT) })
		else
			tw(Panel, EASE_OUT_SOFT, { Size = UDim2.new(1, 0, 0, 0) })
		end
	end)

	-- ===== public control object =====

	controlObject = {
		Instance = Container,
		Value = color,
		Set = function(self, newColor, silent)
			if typeof(newColor) ~= "Color3" then
				return
			end
			hue, sat, val = newColor:ToHSV()
			applyState(not silent)
		end,
	}

	controlObject.CreateKeybind = function(self, name, kbConfig)
		kbConfig = kbConfig or {}
		kbConfig.Name = kbConfig.Name or name
		return Elements.CreateKeybind(self.Instance.Parent, kbConfig)
	end
	controlObject.CreateColorPicker = function(self, name, cpConfig)
		cpConfig = cpConfig or {}
		cpConfig.Name = cpConfig.Name or name
		return Elements.CreateColorPicker(self.Instance.Parent, cpConfig)
	end

	refreshVisuals()

	if Library._RegisterFlag and flag then
		Library._RegisterFlag(flag, controlObject)
	end

	if Library._RegisterSearchable then
		Library._RegisterSearchable(pickerName, Container)
	end

	return controlObject
end


-- ============================================================
-- Keybind
-- ============================================================
-- Ivory Hub - Keybind element
-- Row: label left, pill button right showing current bound key, e.g. "[ E ]".
-- Click the pill to enter listening mode and rebind; the bound key is also
-- watched globally afterward so pressing it anywhere fires config.Callback
-- as an activation event (true on press, false on release if
-- config.HoldToInteract is set), independent of the rebind flow.
--
-- config.Callback always receives a boolean, never the key name - a
-- rebind (via the UI, or a manual :Set(key)) instead calls
-- config.ChangedCallback(keyString), if provided, since that's a "the
-- binding changed" event, not a "the key fired" one. Keeping these
-- separate matters in practice: any non-empty key name is truthy in
-- Lua, so a Callback that does `if value then ... end` would otherwise
-- misfire every time the key gets rebound.

Elements.CreateKeybind = function(parent, config)
	config = config or {}

	local function formatKeyText(keyName)
		if not keyName or keyName == "" then
			keyName = "None"
		end
		return "[ " .. tostring(keyName) .. " ]"
	end

	local currentKey = config.CurrentKeybind or config.Default or "None"
	local listening = false

	-- Row background
	local rowFrame = Instance.new("Frame")
	rowFrame.Name = "KeybindRow"
	rowFrame.Size = UDim2.new(1, 0, 0, 46)
	rowFrame.BackgroundColor3 = Theme.Plum700
	rowFrame.BackgroundTransparency = Alpha.CardFill
	rowFrame.BorderSizePixel = 0
	rowFrame.ZIndex = 3
	rowFrame.Parent = parent

	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = Radius.LG
	rowCorner.Parent = rowFrame

	local rowPadding = Instance.new("UIPadding")
	rowPadding.PaddingLeft = UDim.new(0, 14)
	rowPadding.PaddingRight = UDim.new(0, 14)
	rowPadding.Parent = rowFrame

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Label"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2.new(1, -114, 1, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.Font = Font.Medium
	nameLabel.TextSize = TextSizes.LG
	nameLabel.TextColor3 = Theme.TextPrimary
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Text = config.Name or config.Text or "Keybind"
	nameLabel.ZIndex = 4
	nameLabel.Parent = rowFrame

	-- Pill button
	local keybindButton = Instance.new("TextButton")
	keybindButton.Name = "KeybindButton"
	keybindButton.AutoButtonColor = false
	keybindButton.Text = ""
	keybindButton.AnchorPoint = Vector2.new(1, 0.5)
	keybindButton.Position = UDim2.new(1, 0, 0.5, 0)
	keybindButton.Size = UDim2.new(0, 92, 0, 30)
	keybindButton.BackgroundColor3 = Theme.Plum600
	keybindButton.BackgroundTransparency = 0.1
	keybindButton.BorderSizePixel = 0
	keybindButton.ZIndex = 4
	keybindButton.Parent = rowFrame

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = Radius.Pill
	pillCorner.Parent = keybindButton

	local pillStroke = Instance.new("UIStroke")
	pillStroke.Thickness = 1
	pillStroke.Color = Color3.fromRGB(255, 255, 255)
	pillStroke.Transparency = Alpha.Faint
	pillStroke.Parent = keybindButton

	local pillScale = Instance.new("UIScale")
	pillScale.Scale = 1
	pillScale.Parent = keybindButton

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.BackgroundTransparency = 1
	keyLabel.Size = UDim2.new(1, 0, 1, 0)
	keyLabel.Font = Font.Body
	keyLabel.TextSize = TextSizes.MD
	keyLabel.TextColor3 = Theme.TextPrimary
	keyLabel.TextXAlignment = Enum.TextXAlignment.Center
	keyLabel.TextYAlignment = Enum.TextYAlignment.Center
	keyLabel.Text = formatKeyText(currentKey)
	keyLabel.ZIndex = 5
	keyLabel.Parent = keybindButton

	-- Hover / press feedback (skipped while actively listening, which owns
	-- the stroke/label visuals during that state)
	keybindButton.MouseEnter:Connect(function()
		if listening then
			return
		end
		tw(pillStroke, EASE_QUICK, { Transparency = 0.3 })
		tw(pillScale, EASE_QUICK, { Scale = 1.02 })
	end)

	keybindButton.MouseLeave:Connect(function()
		if listening then
			return
		end
		tw(pillStroke, EASE_QUICK, { Transparency = Alpha.Faint })
		tw(pillScale, EASE_QUICK, { Scale = 1 })
	end)

	keybindButton.MouseButton1Down:Connect(function()
		tw(pillScale, EASE_QUICK, { Scale = 0.96 })
	end)

	keybindButton.MouseButton1Up:Connect(function()
		tw(pillScale, EASE_QUICK, { Scale = listening and 1.02 or 1 })
	end)

	-- The control object returned to callers / registered as a flag
	local keybindControl = {}
	keybindControl.Instance = rowFrame
	keybindControl.Value = currentKey

	local listenConnection = nil

	local function stopListening()
		listening = false
		if listenConnection then
			listenConnection:Disconnect()
			listenConnection = nil
		end
		tw(pillStroke, EASE_QUICK, { Transparency = Alpha.Faint, Color = Color3.fromRGB(255, 255, 255) })
		tw(keyLabel, EASE_QUICK, { TextTransparency = 0, TextColor3 = Theme.TextPrimary })
		keyLabel.Text = formatKeyText(currentKey)
	end

	local function startListening()
		if listening then
			return
		end
		listening = true
		keyLabel.Text = "..."
		tw(pillStroke, EASE_QUICK, { Transparency = 0.2, Color = Theme.Blossom })
		tw(keyLabel, EASE_QUICK, { TextColor3 = Theme.Blossom })

		-- Gentle pulse while listening; self terminates once listening ends
		-- or the button is removed from the tree.
		task.spawn(function()
			while listening and keybindButton.Parent do
				tw(keyLabel, EASE_SLOW, { TextTransparency = 0.55 })
				task.wait(0.45)
				if not (listening and keybindButton.Parent) then
					break
				end
				tw(keyLabel, EASE_SLOW, { TextTransparency = 0 })
				task.wait(0.45)
			end
			if keyLabel.Parent then
				keyLabel.TextTransparency = 0
			end
		end)

		listenConnection = UserInputService.InputBegan:Connect(function(input)
			if not listening then
				return
			end

			if input.KeyCode == Enum.KeyCode.Escape then
				stopListening()
				return
			end

			local newKey = nil
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
				newKey = input.KeyCode.Name
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				newKey = "MouseButton1"
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				newKey = "MouseButton2"
			end

			if newKey then
				currentKey = newKey
				keybindControl.Value = currentKey
				stopListening()
				-- Rebinding is a "the key changed" event, not a "the key
				-- fired" one - it goes to ChangedCallback, never Callback.
				-- Callback is reserved for the true/false activation
				-- signal below; since any non-empty key name is truthy in
				-- Lua, feeding it through Callback would make a plain
				-- `if value then ... end` handler misfire on every rebind.
				if config.ChangedCallback then
					pcall(config.ChangedCallback, currentKey)
				end
			end
		end)
	end

	keybindButton.MouseButton1Click:Connect(startListening)

	-- Persistent global listener: fires the bound key as an activation
	-- event anywhere in the game, independent from the rebind flow above.
	local function matchesCurrentKey(input)
		if currentKey == "MouseButton1" then
			return input.UserInputType == Enum.UserInputType.MouseButton1
		elseif currentKey == "MouseButton2" then
			return input.UserInputType == Enum.UserInputType.MouseButton2
		elseif input.UserInputType == Enum.UserInputType.Keyboard then
			return input.KeyCode.Name == currentKey
		end
		return false
	end

	local activationBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if listening then
			return
		end
		-- NOT gated on gameProcessedEvent: this game claims its keys
		-- (observed RightShift arriving as gameProcessed=true), which made
		-- every bound key a silent no-op. Textbox focus is the real
		-- "player is typing" signal the guard existed for.
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if matchesCurrentKey(input) then
			if config.Callback then
				pcall(config.Callback, true)
			end
		end
	end)

	local activationEndedConn = nil
	if config.HoldToInteract then
		activationEndedConn = UserInputService.InputEnded:Connect(function(input)
			if listening then
				return
			end
			if matchesCurrentKey(input) then
				if config.Callback then
					pcall(config.Callback, false)
				end
			end
		end)
	end

	rowFrame.Destroying:Connect(function()
		listening = false
		if listenConnection then
			listenConnection:Disconnect()
			listenConnection = nil
		end
		if activationBeganConn then
			activationBeganConn:Disconnect()
		end
		if activationEndedConn then
			activationEndedConn:Disconnect()
		end
	end)

	function keybindControl:Set(keyString, silent)
		currentKey = keyString or "None"
		self.Value = currentKey
		keyLabel.Text = formatKeyText(currentKey)
		-- Same split as the rebind-via-UI path above: this changes which
		-- key is bound, it isn't the key firing, so it goes to
		-- ChangedCallback rather than the boolean activation Callback.
		if not silent and config.ChangedCallback then
			pcall(config.ChangedCallback, currentKey)
		end
	end

	if Library._RegisterFlag and config.Flag then
		Library._RegisterFlag(config.Flag, keybindControl)
	end

	if Library._RegisterSearchable then
		Library._RegisterSearchable(config.Name, rowFrame)
	end

	return keybindControl
end


-- ============================================================
-- Notifications
-- ============================================================
-- Ivory Hub - Notifications (toast system)

local NotifyTypeColors = {
    Success = Theme.Success,
    Error = Theme.Error,
    Warning = Theme.Warning,
    Info = Theme.Blossom,
}

local function NotifyMakePillBar(parent, w, h, x, y, rot, color)
    local bar = Instance.new("Frame")
    bar.Name = "IconShape"
    bar.AnchorPoint = Vector2.new(0.5, 0.5)
    bar.Size = UDim2.new(0, w, 0, h)
    bar.Position = UDim2.new(0, x, 0, y)
    bar.Rotation = rot
    bar.BackgroundColor3 = color
    bar.BackgroundTransparency = 1
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Radius.Pill
    corner.Parent = bar

    return bar
end

-- A soft same-hue circular badge behind the bars, so the icon reads as
-- a contained badge rather than a few line fragments floating loose.
local function NotifyMakeBadge(iconBox, color)
    local badge = Instance.new("Frame")
    badge.Name = "Badge"
    badge.Size = UDim2.new(1, 0, 1, 0)
    badge.BackgroundColor3 = color
    badge.BackgroundTransparency = 1
    badge.BorderSizePixel = 0
    badge.ZIndex = 2
    badge.Parent = iconBox

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Radius.Pill
    corner.Parent = badge

    return badge
end

-- Returns (barShapes, badge) separately, not one flat list - the badge
-- fades in to a faint tint (Alpha.Faint-ish) while the bars drawn on
-- top of it fade to fully opaque. They're the same hue, so collapsing
-- both into one "fade everything to 0" list would leave the badge
-- fully opaque behind bars of an identical color - i.e. the bars
-- disappearing into their own background.
local function NotifyBuildIcon(iconBox, notifyType, color)
    local badge = NotifyMakeBadge(iconBox, color)
    local bars = {}
    if notifyType == "Success" then
        table.insert(bars, NotifyMakePillBar(iconBox, 6, 2, 5, 9, 45, color))
        table.insert(bars, NotifyMakePillBar(iconBox, 10, 2, 10, 6, -45, color))
    elseif notifyType == "Error" then
        table.insert(bars, NotifyMakePillBar(iconBox, 12, 2, 8, 8, 45, color))
        table.insert(bars, NotifyMakePillBar(iconBox, 12, 2, 8, 8, -45, color))
    elseif notifyType == "Warning" then
        table.insert(bars, NotifyMakePillBar(iconBox, 2, 7, 8, 5, 0, color))
        table.insert(bars, NotifyMakePillBar(iconBox, 2, 2, 8, 12, 0, color))
    else
        table.insert(bars, NotifyMakePillBar(iconBox, 2, 2, 8, 4, 0, color))
        table.insert(bars, NotifyMakePillBar(iconBox, 2, 7, 8, 10, 0, color))
    end
    return bars, badge
end

local function NotifyGetGuiParent()
    local ok, hui = pcall(function()
        return gethui and gethui()
    end)
    if ok and hui then
        return hui
    end

    local ok2, coreGui = pcall(function()
        return game:GetService("CoreGui")
    end)
    if ok2 and coreGui then
        local writable = pcall(function()
            local probe = Instance.new("Folder")
            probe.Name = "__LootUIProbe"
            probe.Parent = coreGui
            probe:Destroy()
        end)
        if writable then
            return coreGui
        end
    end

    local player = Players.LocalPlayer
    if not player then
        player = Players.PlayerAdded:Wait()
    end
    return player:WaitForChild("PlayerGui")
end

local function NotifyEnsureHolder()
    local holder = Library._NotifyHolder
    if holder and holder.Parent then
        local existingContainer = holder:FindFirstChild("Container")
        if existingContainer then
            return holder, existingContainer
        end
    end

    holder = Instance.new("ScreenGui")
    holder.Name = "LootNotifyHolder"
    holder.ResetOnSpawn = false
    holder.IgnoreGuiInset = true
    holder.DisplayOrder = 99999
    holder.Parent = NotifyGetGuiParent()

    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(1, 1)
    container.Position = UDim2.new(1, -16, 1, -16)
    -- Scale-based width (not a fixed 300px) so this shrinks to fit a
    -- narrow phone screen instead of dominating most of it; the size
    -- constraint below caps it at the original 300px on anything wider.
    container.Size = UDim2.new(1, -32, 1, -32)
    container.BackgroundTransparency = 1
    container.Parent = holder

    local containerConstraint = Instance.new("UISizeConstraint")
    containerConstraint.MaxSize = Vector2.new(300, math.huge)
    containerConstraint.Parent = container

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = container

    Library._NotifyHolder = holder
    return holder, container
end

Library.Notify = function(config)
    config = config or {}

    local notifyType = config.Type
    if not NotifyTypeColors[notifyType] then
        notifyType = "Info"
    end
    local accentColor = NotifyTypeColors[notifyType]

    local duration = config.Duration
    if type(duration) ~= "number" or duration <= 0 then
        duration = 5
    end

    local titleText = tostring(config.Title or "Notification")
    local contentText = tostring(config.Content or "")

    local _, container = NotifyEnsureHolder()

    Library._NotifyOrderCounter = (Library._NotifyOrderCounter or 0) + 1
    local order = Library._NotifyOrderCounter

    local fadeList = {}

    local slot = Instance.new("Frame")
    slot.Name = "NotificationSlot"
    slot.BackgroundTransparency = 1
    slot.Size = UDim2.new(1, 0, 0, 0)
    slot.AutomaticSize = Enum.AutomaticSize.Y
    slot.ClipsDescendants = false
    slot.LayoutOrder = order
    slot.Parent = container

    local card = Instance.new("TextButton")
    card.Name = "Card"
    card.AutoButtonColor = false
    card.Text = ""
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.Position = UDim2.new(0, 40, 0, 0)
    card.BackgroundColor3 = Theme.Plum800
    card.BackgroundTransparency = 1
    card.BorderSizePixel = 0
    card.ClipsDescendants = true
    card.Parent = slot
    table.insert(fadeList, {obj = card, prop = "BackgroundTransparency", rest = 0})

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = Radius.LG
    cardCorner.Parent = card

    -- Tinted to the notification's own accent rather than plain white, so
    -- the card reads as a soft colored glow-rim instead of a neutral
    -- outline - the same "the brand color does the framing" idea as the
    -- wordmark and buttons elsewhere in the library.
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = accentColor
    stroke.Transparency = 1
    stroke.Parent = card
    table.insert(fadeList, {obj = stroke, prop = "Transparency", rest = 0.55})

    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = card

    local accentLight = accentColor:Lerp(Color3.new(1, 1, 1), 0.45)

    local accentBar = Instance.new("Frame")
    accentBar.Name = "Accent"
    accentBar.Size = UDim2.new(0, 4, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = accentColor
    accentBar.BackgroundTransparency = 1
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 3
    accentBar.Parent = card
    table.insert(fadeList, {obj = accentBar, prop = "BackgroundTransparency", rest = 0})

    local accentGradient = Instance.new("UIGradient")
    accentGradient.Rotation = 90
    accentGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, accentColor),
        ColorSequenceKeypoint.new(1, accentLight),
    })
    accentGradient.Parent = accentBar

    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1, 0, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Parent = card

    local innerLayout = Instance.new("UIListLayout")
    innerLayout.FillDirection = Enum.FillDirection.Vertical
    innerLayout.SortOrder = Enum.SortOrder.LayoutOrder
    innerLayout.Padding = UDim.new(0, 4)
    innerLayout.Parent = inner

    local innerPadding = Instance.new("UIPadding")
    innerPadding.PaddingLeft = UDim.new(0, 16)
    innerPadding.PaddingRight = UDim.new(0, 14)
    innerPadding.PaddingTop = UDim.new(0, 12)
    innerPadding.PaddingBottom = UDim.new(0, 16)
    innerPadding.Parent = inner

    local headerRow = Instance.new("Frame")
    headerRow.Name = "Header"
    headerRow.BackgroundTransparency = 1
    headerRow.Size = UDim2.new(1, 0, 0, 16)
    headerRow.LayoutOrder = 1
    headerRow.Parent = inner

    local iconBox = Instance.new("Frame")
    iconBox.Name = "Icon"
    iconBox.BackgroundTransparency = 1
    iconBox.Size = UDim2.new(0, 16, 0, 16)
    iconBox.Position = UDim2.new(0, 0, 0, 0)
    iconBox.Parent = headerRow

    local iconBars, iconBadge = NotifyBuildIcon(iconBox, notifyType, accentColor)
    for _, shape in ipairs(iconBars) do
        table.insert(fadeList, {obj = shape, prop = "BackgroundTransparency", rest = 0})
    end
    table.insert(fadeList, {obj = iconBadge, prop = "BackgroundTransparency", rest = 0.85})

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, -22, 0, 16)
    titleLabel.Position = UDim2.new(0, 22, 0, 0)
    titleLabel.Font = Font.Bold
    titleLabel.TextSize = TextSizes.MD
    titleLabel.TextColor3 = Theme.TextPrimary
    titleLabel.TextTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextYAlignment = Enum.TextYAlignment.Center
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Text = titleText
    titleLabel.Parent = headerRow
    table.insert(fadeList, {obj = titleLabel, prop = "TextTransparency", rest = 0})

    local contentLabel = Instance.new("TextLabel")
    contentLabel.Name = "Content"
    contentLabel.BackgroundTransparency = 1
    contentLabel.Size = UDim2.new(1, 0, 0, 0)
    contentLabel.AutomaticSize = Enum.AutomaticSize.Y
    contentLabel.Font = Font.Body
    contentLabel.TextSize = TextSizes.SM
    contentLabel.TextColor3 = Theme.TextSecondary
    contentLabel.TextTransparency = 1
    contentLabel.TextWrapped = true
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextYAlignment = Enum.TextYAlignment.Top
    contentLabel.LayoutOrder = 2
    contentLabel.Text = contentText
    contentLabel.Visible = contentText ~= ""
    contentLabel.Parent = inner
    if contentText ~= "" then
        table.insert(fadeList, {obj = contentLabel, prop = "TextTransparency", rest = 0})
    end

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.AnchorPoint = Vector2.new(0, 1)
    progressTrack.Position = UDim2.new(0, 0, 1, 0)
    progressTrack.Size = UDim2.new(1, 0, 0, 3)
    progressTrack.BackgroundColor3 = Theme.Plum700
    progressTrack.BackgroundTransparency = 1
    progressTrack.BorderSizePixel = 0
    progressTrack.ZIndex = 3
    progressTrack.Parent = card
    table.insert(fadeList, {obj = progressTrack, prop = "BackgroundTransparency", rest = 0.5})

    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Position = UDim2.new(0, 0, 0, 0)
    progressFill.Size = UDim2.new(1, 0, 1, 0)
    progressFill.BackgroundColor3 = accentColor
    progressFill.BackgroundTransparency = 1
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 4
    progressFill.Parent = progressTrack
    table.insert(fadeList, {obj = progressFill, prop = "BackgroundTransparency", rest = 0})

    local dismissed = false
    local progressTween = nil

    local function dismiss()
        if dismissed then
            return
        end
        dismissed = true

        if progressTween then
            progressTween:Cancel()
        end

        for _, item in ipairs(fadeList) do
            tw(item.obj, EASE_QUICK, {[item.prop] = 1})
        end
        local exitTween = tw(card, EASE_QUICK, {Position = UDim2.new(0, 40, 0, 0)})
        exitTween.Completed:Connect(function()
            if slot then
                slot:Destroy()
            end
        end)
    end

    card.Activated:Connect(dismiss)

    card.MouseEnter:Connect(function()
        if dismissed then
            return
        end
        tw(scale, EASE_QUICK, {Scale = 1.02})
        tw(stroke, EASE_QUICK, {Transparency = 0.3})
    end)
    card.MouseLeave:Connect(function()
        if dismissed then
            return
        end
        tw(scale, EASE_QUICK, {Scale = 1})
        tw(stroke, EASE_QUICK, {Transparency = Alpha.Faint})
    end)
    card.MouseButton1Down:Connect(function()
        if dismissed then
            return
        end
        tw(scale, EASE_QUICK, {Scale = 0.96})
    end)
    card.MouseButton1Up:Connect(function()
        if dismissed then
            return
        end
        tw(scale, EASE_QUICK, {Scale = 1.02})
    end)

    -- Entrance: slide + fade in
    for _, item in ipairs(fadeList) do
        tw(item.obj, EASE_SPRING, {[item.prop] = item.rest})
    end
    tw(card, EASE_SPRING, {Position = UDim2.new(0, 0, 0, 0)})

    -- Bottom progress bar drains from full to empty over Duration seconds
    local drainInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    progressTween = tw(progressFill, drainInfo, {Size = UDim2.new(0, 0, 1, 0)})
    progressTween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            dismiss()
        end
    end)

    return {
        Dismiss = dismiss,
        Instance = card,
    }
end


-- ============================================================
-- Config / Save system
-- ============================================================
-- ============================================================
-- Ivory Hub - Config / Save system
-- Flag registry, JSON configuration save/load, and autosave loop.
-- ============================================================

-- Flags table is the one exception permitted by the contract: this
-- module owns it, so it is declared fresh here.
Library.Flags = {}
Library.Toggles = {}

-- Registers a control object under a flag name so it can be saved,
-- loaded, and looked up by other parts of the library (e.g. a
-- consuming script doing Library.Flags["MyToggle"].Value).
-- controlObject is expected to expose:
--   .Value        -- current value (bool / number / string / Color3 / table)
--   :Set(value, silent) -- programmatically set the value; silent=true
--                          must not fire the element's user Callback
Library._RegisterFlag = function(flagName, controlObject)
	if type(flagName) ~= "string" or flagName == "" then
		return
	end
	Library.Flags[flagName] = controlObject
end

-- Converts a raw flag value into something HttpService:JSONEncode can
-- handle. Only Color3 needs special treatment - everything else
-- (bool, number, string, plain table) already round-trips through
-- JSON fine on its own.
local function LootUI_SerializeValue(value)
	if typeof(value) == "Color3" then
		return {
			__color3 = true,
			r = value.R,
			g = value.G,
			b = value.B,
		}
	end
	return value
end

-- Reverses LootUI_SerializeValue: rebuilds a Color3 from the
-- {__color3=true, r=, g=, b=} shape, otherwise passes the value
-- straight through untouched.
local function LootUI_DeserializeValue(value)
	if type(value) == "table" and value.__color3 == true then
		return Color3.new(value.r or 0, value.g or 0, value.b or 0)
	end
	return value
end

-- Writes every registered flag's current .Value out to
-- "<fileName>.json" via the executor's writefile global.
-- silent defaults to false so a manual "Save now" button keeps showing
-- its confirmation toast; EnableAutosave passes true so the periodic
-- background save doesn't pop a notification every interval forever.
Library.SaveConfiguration = function(fileName, silent)
	fileName = fileName or "LootUIConfig"

	local success = pcall(function()
		local dataTable = {}

		for flagName, controlObject in pairs(Library.Flags) do
			if controlObject ~= nil and controlObject.Value ~= nil then
				dataTable[flagName] = LootUI_SerializeValue(controlObject.Value)
			end
		end

		local encoded = HttpService:JSONEncode(dataTable)
		writefile(fileName .. ".json", encoded)
	end)

	if not silent and Library.Notify then
		if success then
			Library.Notify({
				Title = "Configuration Saved",
				Content = fileName,
				Type = "Success",
			})
		else
			Library.Notify({
				Title = "Configuration Save Failed",
				Content = fileName,
				Type = "Error",
			})
		end
	end

	return success
end

-- Reads "<fileName>.json" back in (if it exists) and applies every key
-- it finds to the matching registered flag.
--
-- By default (fireCallbacks omitted or false) this restores UI/control
-- state and .Value silently, without re-triggering each element's
-- Callback - so an Auto Farm toggle would repaint as "on" without its
-- farming loop actually starting back up. That silent default stays,
-- for backward compatibility with scripts that already re-apply loaded
-- state themselves after calling this.
--
-- Pass fireCallbacks = true to instead have every restored flag fire
-- its real Callback (Keybind fires ChangedCallback, since a restored
-- key is a "the binding changed" event, not a "the key fired" one) -
-- for a script that wants LoadConfiguration to fully re-apply saved
-- state on its own, with no second manual pass required.
Library.LoadConfiguration = function(fileName, fireCallbacks)
	fileName = fileName or "LootUIConfig"

	local success, err = pcall(function()
		if not isfile(fileName .. ".json") then
			return
		end

		local raw = readfile(fileName .. ".json")
		local decoded = HttpService:JSONDecode(raw)

		for key, rawValue in pairs(decoded) do
			local controlObject = Library.Flags[key]
			if controlObject and controlObject.Set then
				local value = LootUI_DeserializeValue(rawValue)
				controlObject:Set(value, not fireCallbacks)
			end
		end
	end)

	if not success and Library.Notify then
		Library.Notify({
			Title = "Configuration Load Failed",
			Content = tostring(err),
			Type = "Error",
		})
	end

	return success
end

-- Spawns a background loop that periodically calls SaveConfiguration.
-- NOTE: unlike the per-element idle animation loops in this library,
-- autosave has no natural UI instance to gate its "while" condition
-- on (the whole point is that it keeps saving even if the user closes
-- individual menus/tabs). It intentionally runs for the lifetime of
-- the process/session, matching how a real hub's autosave behaves.
-- Call this at most once per fileName to avoid stacking loops.
Library.EnableAutosave = function(fileName, intervalSeconds)
	fileName = fileName or "LootUIConfig"
	intervalSeconds = intervalSeconds or 30

	task.spawn(function()
		while not Library.Unloaded do
			task.wait(intervalSeconds)
			pcall(function()
				Library.SaveConfiguration(fileName, true)
			end)
		end
	end)
end

Library.ListConfigurations = function(folder)
	folder = folder or "IvoryHubConfigs"
	local names = {}
	pcall(function()
		for _, path in ipairs(listfiles(folder)) do
			local base = path:match("([^/\\]+)$") or path
			local name = base:match("^(.+)%.json$")
			if name and name ~= "" then
				table.insert(names, name)
			end
		end
	end)
	table.sort(names)
	return names
end

Library.CreateConfigControls = function(section, folder)
	folder = folder or "IvoryHubConfigs"
	if not section then
		return nil
	end

	local currentName = ""
	local dropdown

	local function sanitize(name)
		name = tostring(name or "")
		name = name:gsub("[%c]", "")
		name = name:gsub("[/\\:*?\"<>|]", "")
		name = name:match("^%s*(.-)%s*$") or ""
		if #name > 40 then
			name = name:sub(1, 40)
		end
		return name
	end

	local function pathFor(name)
		return folder .. "/" .. name
	end

	local function refreshList()
		local names = Library.ListConfigurations(folder)
		local hasCurrent = false
		for _, n in ipairs(names) do
			if n == currentName then
				hasCurrent = true
				break
			end
		end
		if currentName ~= "" and not hasCurrent then
			table.insert(names, currentName)
			table.sort(names)
		end
		if #names == 0 then
			names = { "Default" }
		end
		dropdown:Refresh(names)
		dropdown:Set(currentName ~= "" and currentName or names[1], true)
		currentName = dropdown.Value
	end

	dropdown = section:CreateDropdown({
		Name = "Config",
		Options = { "Default" },
		CurrentOption = "Default",
		Callback = function(value)
			currentName = value
		end,
	})

	refreshList()

	section:CreateInput({
		Name = "New Config Name",
		PlaceholderText = "Type name + Enter",
		RemoveTextAfterFocusLost = true,
		Callback = function(text)
			local name = sanitize(text)
			if name == "" then
				return
			end
			currentName = name
			refreshList()
			if Library.Notify then
				Library.Notify({
					Title = "Configuration",
					Content = "New config: " .. name,
					Type = "Info",
					Duration = 2,
				})
			end
		end,
	})

	section:CreateButton({
		Name = "Save Config",
		Callback = function()
			local name = currentName ~= "" and currentName or "Default"
			Library.SaveConfiguration(pathFor(name))
			refreshList()
		end,
	})

	section:CreateButton({
		Name = "Load Config",
		Callback = function()
			local name = currentName ~= "" and currentName or "Default"
			if not isfile(pathFor(name) .. ".json") then
				if Library.Notify then
					Library.Notify({
						Title = "Configuration",
						Content = "No saved config named " .. name,
						Type = "Warning",
						Duration = 2,
					})
				end
				return
			end
			Library.LoadConfiguration(pathFor(name), true)
			if Library.Notify then
				Library.Notify({
					Title = "Configuration",
					Content = "Loaded " .. name,
					Type = "Success",
					Duration = 2,
				})
			end
		end,
	})

	return {
		Refresh = refreshList,
		GetCurrent = function()
			return currentName
		end,
	}
end

-- ============================================================
-- Search
-- ============================================================
-- Ivory Hub - Search
-- Fuzzy title bar search: a magnifying-glass icon button that expands into a
-- TextBox and filters every registered searchable element by substring match.

Library._SearchIndex = Library._SearchIndex or {}

Library._RegisterSearchable = function(name, instance)
    if not name or not instance then
        return
    end
    table.insert(Library._SearchIndex, { name = name, instance = instance })
end

Library.CreateSearchBar = function(parentTitleBarFrame)
    local searchOpen = false

    local function applyFilter(query)
        query = query or ""
        local q = query:lower()
        for _, entry in ipairs(Library._SearchIndex) do
            local inst = entry.instance
            if inst and inst.Parent then
                if q == "" then
                    inst.Visible = true
                else
                    local name = (entry.name or ""):lower()
                    inst.Visible = string.find(name, q, 1, true) ~= nil
                end
            end
        end
    end

    -- Icon button (magnifying glass), pinned to the right side of the title bar
    local IconButton = Instance.new("TextButton")
    IconButton.Name = "SearchIconButton"
    IconButton.AutoButtonColor = false
    IconButton.Text = ""
    IconButton.BackgroundColor3 = Theme.Plum700
    IconButton.BackgroundTransparency = 1
    IconButton.Size = UDim2.new(0, 28, 0, 28)
    IconButton.AnchorPoint = Vector2.new(1, 0.5)
    -- Sits left of the minimize (-48) and close (-14) title bar buttons
    -- (26px wide each) with an 8px gap, so it never overlaps them.
    IconButton.Position = UDim2.new(1, -82, 0.5, 0)
    IconButton.ZIndex = 5
    IconButton.Parent = parentTitleBarFrame

    local IconCorner = Instance.new("UICorner")
    IconCorner.CornerRadius = Radius.Pill
    IconCorner.Parent = IconButton

    local IconStroke = Instance.new("UIStroke")
    IconStroke.Thickness = 1
    IconStroke.Color = Color3.fromRGB(255, 255, 255)
    IconStroke.Transparency = Alpha.Faint
    IconStroke.Parent = IconButton

    local IconScale = Instance.new("UIScale")
    IconScale.Scale = 1
    IconScale.Parent = IconButton

    -- Hand-drawn magnifying glass: circle outline + short diagonal handle
    -- bar, meeting exactly at the circle's own edge so the handle reads as
    -- one continuous stroke rather than a separate floating tick.
    local GlassFrame = Instance.new("Frame")
    GlassFrame.Name = "Glass"
    GlassFrame.BackgroundTransparency = 1
    GlassFrame.Size = UDim2.new(0, 18, 0, 18)
    GlassFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    GlassFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlassFrame.ZIndex = 6
    GlassFrame.Parent = IconButton

    local GlassCircle = Instance.new("Frame")
    GlassCircle.Name = "Circle"
    GlassCircle.BackgroundTransparency = 1
    GlassCircle.Size = UDim2.new(0, 11, 0, 11)
    GlassCircle.Position = UDim2.new(0, 0, 0, 0)
    GlassCircle.ZIndex = 6
    GlassCircle.Parent = GlassFrame

    local GlassCircleCorner = Instance.new("UICorner")
    GlassCircleCorner.CornerRadius = Radius.Pill
    GlassCircleCorner.Parent = GlassCircle

    local GlassCircleStroke = Instance.new("UIStroke")
    GlassCircleStroke.Thickness = 1.75
    GlassCircleStroke.Color = Theme.TextSecondary
    GlassCircleStroke.Transparency = 0
    GlassCircleStroke.Parent = GlassCircle

    -- Roblox rotates a Frame around its own geometric CENTER, never around
    -- its AnchorPoint - a top-center anchor does not hinge from that point
    -- the way it would in an SVG/CSS transform-origin model. That mismatch
    -- (previously anchoring at the circle's edge and expecting the bar to
    -- swing from there) is what rendered as a spiral/tail instead of a
    -- clean handle. The fix: anchor at the bar's true center and place that
    -- center directly on the 45-degree line running through the circle's
    -- edge, so the already-correct center needs no pivot compensation.
    local GlassHandle = Instance.new("Frame")
    GlassHandle.Name = "Handle"
    GlassHandle.BackgroundColor3 = Theme.TextSecondary
    GlassHandle.BorderSizePixel = 0
    GlassHandle.Size = UDim2.new(0, 1.75, 0, 7)
    GlassHandle.AnchorPoint = Vector2.new(0.5, 0.5)
    GlassHandle.Position = UDim2.new(0, 11.86, 0, 11.86)
    GlassHandle.Rotation = 45
    GlassHandle.ZIndex = 6
    GlassHandle.Parent = GlassFrame

    local GlassHandleCorner = Instance.new("UICorner")
    GlassHandleCorner.CornerRadius = Radius.Pill
    GlassHandleCorner.Parent = GlassHandle

    -- Inline expanding search field
    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.Text = ""
    SearchBox.PlaceholderText = "Search..."
    SearchBox.ClearTextOnFocus = false
    SearchBox.Font = Font.Body
    SearchBox.TextSize = TextSizes.MD
    SearchBox.TextColor3 = Theme.TextPrimary
    SearchBox.PlaceholderColor3 = Theme.TextTertiary
    SearchBox.TextXAlignment = Enum.TextXAlignment.Left
    SearchBox.BackgroundColor3 = Theme.Plum700
    SearchBox.BackgroundTransparency = 0.15
    SearchBox.ClipsDescendants = true
    SearchBox.Visible = false
    SearchBox.AnchorPoint = Vector2.new(1, 0.5)
    -- Right-anchored just left of the search icon (-82 - 28 wide - 6px gap),
    -- so it expands leftward without ever reaching under the icon/buttons.
    SearchBox.Position = UDim2.new(1, -116, 0.5, 0)
    SearchBox.Size = UDim2.new(0, 0, 0, 28)
    SearchBox.ZIndex = 5
    SearchBox.Parent = parentTitleBarFrame

    local SearchBoxCorner = Instance.new("UICorner")
    SearchBoxCorner.CornerRadius = Radius.SM
    SearchBoxCorner.Parent = SearchBox

    local SearchBoxStroke = Instance.new("UIStroke")
    SearchBoxStroke.Thickness = 1
    SearchBoxStroke.Color = Color3.fromRGB(255, 255, 255)
    SearchBoxStroke.Transparency = Alpha.Faint
    SearchBoxStroke.Parent = SearchBox

    local SearchBoxPadding = Instance.new("UIPadding")
    SearchBoxPadding.PaddingLeft = UDim.new(0, 10)
    SearchBoxPadding.PaddingRight = UDim.new(0, 10)
    SearchBoxPadding.Parent = SearchBox

    local function setIconHover(hovering)
        tw(IconButton, EASE_QUICK, { BackgroundTransparency = hovering and 0.85 or 1 })
        tw(IconScale, EASE_QUICK, { Scale = hovering and 1.02 or 1 })
        tw(GlassCircleStroke, EASE_QUICK, { Color = hovering and Theme.TextPrimary or Theme.TextSecondary })
        tw(GlassHandle, EASE_QUICK, { BackgroundColor3 = hovering and Theme.TextPrimary or Theme.TextSecondary })
        if not searchOpen then
            tw(IconStroke, EASE_QUICK, { Transparency = hovering and 0.3 or 0.82 })
        end
    end

    IconButton.MouseEnter:Connect(function()
        setIconHover(true)
    end)

    IconButton.MouseLeave:Connect(function()
        setIconHover(false)
    end)

    IconButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tw(IconScale, EASE_QUICK, { Scale = 0.96 })
        end
    end)

    IconButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tw(IconScale, EASE_QUICK, { Scale = 1 })
        end
    end)

    local function openSearch()
        if searchOpen then
            SearchBox:CaptureFocus()
            return
        end
        searchOpen = true
        SearchBox.Visible = true
        tw(IconStroke, EASE_QUICK, { Color = Theme.Blossom, Transparency = 0.3 })
        tw(SearchBox, EASE_SPRING, { Size = UDim2.new(0, 160, 0, 28) })
        task.delay(0.05, function()
            if searchOpen then
                SearchBox:CaptureFocus()
            end
        end)
    end

    local function closeSearch()
        if not searchOpen then
            return
        end
        searchOpen = false
        SearchBox:ReleaseFocus()
        SearchBox.Text = ""
        applyFilter("")
        tw(IconStroke, EASE_QUICK, { Color = Color3.fromRGB(255, 255, 255), Transparency = Alpha.Faint })
        local closeTween = tw(SearchBox, EASE_SPRING, { Size = UDim2.new(0, 0, 0, 28) })
        closeTween.Completed:Connect(function()
            if not searchOpen then
                SearchBox.Visible = false
            end
        end)
    end

    local function toggleSearch()
        if searchOpen then
            closeSearch()
        else
            openSearch()
        end
    end

    IconButton.MouseButton1Click:Connect(function()
        toggleSearch()
    end)

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applyFilter(SearchBox.Text)
    end)

    SearchBox.Focused:Connect(function()
        tw(SearchBoxStroke, EASE_QUICK, { Color = Theme.Blossom, Transparency = 0.2 })
    end)

    SearchBox.FocusLost:Connect(function()
        tw(SearchBoxStroke, EASE_QUICK, { Color = Color3.fromRGB(255, 255, 255), Transparency = Alpha.Faint })
    end)

    UserInputService.InputBegan:Connect(function(input)
        -- No gameProcessed guard: this game claims keys (Escape and
        -- Ctrl+F arrive as gameProcessed=true), so the old guard meant
        -- the search hotkeys never fired here.
        if input.KeyCode == Enum.KeyCode.Escape then
            if searchOpen then
                closeSearch()
            end
        elseif input.KeyCode == Enum.KeyCode.F then
            if UserInputService:GetFocusedTextBox() then
                return
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                openSearch()
            end
        end
    end)

    return {
        IconButton = IconButton,
        SearchBox = SearchBox,
        Open = openSearch,
        Close = closeSearch,
        Toggle = toggleSearch,
    }
end


-- ============================================================
-- HUD overlays + customization
-- ============================================================
-- Ivory Hub - HUD overlays + customization
-- Watermark (brand + live FPS/ping), an Active Features panel, accent-color
-- customization, a global menu-visibility keybind, and an info-panel helper
-- (PlaceId/JobId/join script). All pure ScreenGui overlays - nothing here
-- touches Lighting, so the game view is never blurred or distorted.

-- ===================== FPS / Ping =====================
local fpsTrackingStarted = false
local function ensureFPSTracking()
    if fpsTrackingStarted then
        return
    end
    fpsTrackingStarted = true
    task.spawn(function()
        local lastTime = tick()
        local frameCount = 0
        while not Library.Unloaded do
            RunService.Heartbeat:Wait()
            frameCount = frameCount + 1
            local now = tick()
            if now - lastTime >= 0.5 then
                Library._CurrentFPS = math.floor(frameCount / (now - lastTime) + 0.5)
                frameCount = 0
                lastTime = now
            end
        end
    end)
end

Library.GetFPS = function()
    ensureFPSTracking()
    return Library._CurrentFPS or 0
end

Library.GetPing = function()
    local ok, ping = pcall(function()
        return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    if ok and ping then
        return math.floor(ping)
    end
    return nil
end

-- Logo shown in every window bottom-left profile card. Accepts a bare
-- asset id or a full rbxassetid:// string; pass "" to clear it.
-- Library.SubscriptionText, when set, is shown under the player name
-- instead of the ping/fps line.
function Library.SetProfileLogo(assetId)
    local id = tostring(assetId or "")
    if id ~= "" and not id:find("rbxassetid", 1, true) then
        id = "rbxassetid://" .. id
    end
    Library.ProfileLogo = id ~= "" and id or nil
    for _, window in ipairs(Library._windows) do
        local avatar = window._profileAvatar
        if avatar then
            avatar.Image = Library.ProfileLogo or ""
        end
    end
    return Library.ProfileLogo
end

-- ===================== Accent color customization =====================
-- Theme.Blossom is a shared table entry, read by every component at ITS OWN
-- creation time - mutating it here means every element created AFTER this
-- call picks up the new accent automatically. Elements already on screen
-- keep their baked-in color unless the thing that made them registered an
-- updater below (persistent window chrome does this; per-element accents
-- inside already-built rows do not retroactively repaint).
Library._AccentBoundUpdaters = {}

Library._RegisterAccentBound = function(updater)
    table.insert(Library._AccentBoundUpdaters, updater)
end

Library.SetAccentColor = function(color)
    if typeof(color) ~= "Color3" then
        return
    end
    Theme.Blossom = color
    for _, updater in ipairs(Library._AccentBoundUpdaters) do
        pcall(updater, color)
    end
end

-- ===================== Global menu keybind =====================
Library._MenuKeybind = Enum.KeyCode.RightShift
Library._MenuKeybindWindows = {}

Library.SetMenuKeybind = function(keyCode)
    if typeof(keyCode) == "EnumItem" then
        Library._MenuKeybind = keyCode
    end
end

local menuKeybindListenerStarted = false
local function ensureMenuKeybindListener()
    if menuKeybindListenerStarted then
        return
    end
    menuKeybindListenerStarted = true
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        -- Deliberately NOT checking gameProcessed: this game's own input
        -- sink claims RightShift (observed: InputBegan fires with
        -- gameProcessed=true), which used to make the menu keybind a
        -- permanent no-op here. Textbox focus is the real hazard the
        -- guard existed for - if the player is typing (chat, search,
        -- an input row), leave the key to them.
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == Library._MenuKeybind then
            -- Single toggle path: flips Library.Toggled + ScreenGui.Enabled
            -- together, so the mobile button and the keybind never disagree.
            Library:Toggle()
        end
    end)
end

-- Called by Library.CreateWindow (shell) so every window responds to the
-- menu keybind without the shell needing to know keybind internals.
Library._RegisterMenuKeybindWindow = function(window)
    ensureMenuKeybindListener()
    table.insert(Library._MenuKeybindWindows, window)
end

-- ===================== Shared draggable-pill builder =====================
-- Both the watermark and the active-features panel are small draggable
-- pills/cards pinned to a screen corner - this builds the common shell.
local function createHudScreenGui(name)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = name
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 99999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    local player = Players.LocalPlayer
    local playerGui = player and (player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui"))
    if playerGui then
        screenGui.Parent = playerGui
    else
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
        end)
    end
    return screenGui
end

local function makeDraggable(handle, target)
    local dragging = false
    local dragStart, startPos, dragInput

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then
                        changedConn:Disconnect()
                    end
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
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ===================== Watermark =====================
Library.CreateWatermark = function(config)
    config = config or {}
    if Library._Watermark then
        return Library._Watermark
    end

    ensureFPSTracking()

    local screenGui = createHudScreenGui("LootUIWatermark")

    local pill = Instance.new("Frame")
    pill.Name = "Watermark"
    pill.AnchorPoint = Vector2.new(1, 0)
    pill.Position = UDim2.new(1, -16, 0, 16)
    pill.Size = UDim2.fromOffset(0, 32)
    pill.AutomaticSize = Enum.AutomaticSize.X
    pill.BackgroundColor3 = Theme.Plum800
    pill.BackgroundTransparency = 1
    pill.BorderSizePixel = 0
    pill.Active = true
    pill.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Radius.Pill
    corner.Parent = pill

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 1
    stroke.Parent = pill

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = pill

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = pill

    local markHolder = Instance.new("Frame")
    markHolder.LayoutOrder = 1
    markHolder.BackgroundTransparency = 1
    markHolder.ZIndex = 2
    markHolder.Parent = pill
    local mw, mh = Library._BuildIvoryWordmark(markHolder, Theme.TextPrimary, 0.4)
    markHolder.Size = UDim2.fromOffset(mw, mh)

    local showStats = (config.ShowFPS ~= false) or (config.ShowPing ~= false)

    local divider = Instance.new("Frame")
    divider.LayoutOrder = 2
    divider.Size = UDim2.new(0, 1, 0, 14)
    divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    divider.BackgroundTransparency = 0.75
    divider.BorderSizePixel = 0
    divider.Visible = showStats
    divider.Parent = pill

    local statsLabel = Instance.new("TextLabel")
    statsLabel.LayoutOrder = 3
    statsLabel.BackgroundTransparency = 1
    statsLabel.Size = UDim2.fromOffset(0, 32)
    statsLabel.AutomaticSize = Enum.AutomaticSize.X
    statsLabel.Font = Font.Body
    statsLabel.TextSize = TextSizes.SM
    statsLabel.TextColor3 = Theme.TextSecondary
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Text = ""
    statsLabel.Visible = showStats
    statsLabel.Parent = pill

    makeDraggable(pill, pill)

    tw(pill, EASE_OUT_SOFT, { BackgroundTransparency = Alpha.CardFill })
    tw(stroke, EASE_OUT_SOFT, { Transparency = 0.8 })

    if showStats then
        task.spawn(function()
            while pill.Parent do
                local parts = {}
                if config.ShowFPS ~= false then
                    table.insert(parts, tostring(Library.GetFPS()) .. " FPS")
                end
                if config.ShowPing ~= false then
                    local ping = Library.GetPing()
                    if ping then
                        table.insert(parts, tostring(ping) .. "ms")
                    end
                end
                statsLabel.Text = table.concat(parts, "  |  ")
                task.wait(0.5)
            end
        end)
    end

    local watermark = {
        Instance = pill,
        ScreenGui = screenGui,
    }

    function watermark:SetVisible(visible)
        pill.Visible = visible
    end

    function watermark:Destroy()
        screenGui:Destroy()
        Library._Watermark = nil
    end

    Library._Watermark = watermark
    return watermark
end

Library.SetWatermarkEnabled = function(enabled)
    if enabled then
        if not Library._Watermark then
            Library.CreateWatermark({})
        else
            Library._Watermark.Instance.Visible = true
        end
    elseif Library._Watermark then
        Library._Watermark.Instance.Visible = false
    end
end

-- ===================== Active Features panel =====================
-- Elements.CreateToggle registers into this when created with
-- config.TrackActive = true, so this panel needs no per-window wiring -
-- any toggle anywhere that opts in shows up here automatically.
Library._ActiveFeatures = {}
Library._ActiveFeatureNames = {}

Library._SetFeatureActive = function(id, name, active)
    if active then
        if not Library._ActiveFeatureNames[id] then
            Library._ActiveFeatureNames[id] = name
            table.insert(Library._ActiveFeatures, id)
        end
    else
        if Library._ActiveFeatureNames[id] then
            Library._ActiveFeatureNames[id] = nil
            for i, v in ipairs(Library._ActiveFeatures) do
                if v == id then
                    table.remove(Library._ActiveFeatures, i)
                    break
                end
            end
        end
    end
    if Library._RefreshActiveFeaturesPanel then
        Library._RefreshActiveFeaturesPanel()
    end
end

Library.CreateActiveFeaturesPanel = function(config)
    config = config or {}
    if Library._ActiveFeaturesPanel then
        return Library._ActiveFeaturesPanel
    end

    local screenGui = createHudScreenGui("LootUIActiveFeatures")

    local panel = Instance.new("Frame")
    panel.Name = "ActiveFeatures"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -16, 0, 56)
    panel.Size = UDim2.new(0, 170, 0, 0)
    panel.AutomaticSize = Enum.AutomaticSize.Y
    panel.BackgroundColor3 = Theme.Plum800
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Visible = config.AlwaysVisible == true
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Radius.MD
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.85
    stroke.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 4)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = panel

    local header = Instance.new("TextLabel")
    header.LayoutOrder = 1
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 16)
    header.Font = Font.Bold
    header.TextSize = TextSizes.XS
    header.TextColor3 = Theme.TextTertiary
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Text = "ACTIVE"
    header.Parent = panel

    local rowsHolder = Instance.new("Frame")
    rowsHolder.LayoutOrder = 2
    rowsHolder.BackgroundTransparency = 1
    rowsHolder.Size = UDim2.new(1, 0, 0, 0)
    rowsHolder.AutomaticSize = Enum.AutomaticSize.Y
    rowsHolder.Parent = panel

    local rowsLayout = Instance.new("UIListLayout")
    rowsLayout.FillDirection = Enum.FillDirection.Vertical
    rowsLayout.Padding = UDim.new(0, 3)
    rowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    rowsLayout.Parent = rowsHolder

    -- the whole panel is the drag handle (matches the watermark pattern) -
    -- the header alone would be too small a target, and panel already has
    -- Active = true set above
    makeDraggable(panel, panel)

    local rowInstances = {}

    Library._RefreshActiveFeaturesPanel = function()
        for id, label in pairs(rowInstances) do
            if not Library._ActiveFeatureNames[id] then
                label:Destroy()
                rowInstances[id] = nil
            end
        end

        for _, id in ipairs(Library._ActiveFeatures) do
            if not rowInstances[id] then
                local row = Instance.new("TextLabel")
                row.BackgroundTransparency = 1
                row.Size = UDim2.new(1, 0, 0, 16)
                row.Font = Font.Body
                row.TextSize = TextSizes.SM
                row.TextColor3 = Theme.Success
                row.TextXAlignment = Enum.TextXAlignment.Left
                row.TextTruncate = Enum.TextTruncate.AtEnd
                row.Text = "* " .. Library._ActiveFeatureNames[id]
                row.Parent = rowsHolder
                rowInstances[id] = row
            end
        end

        panel.Visible = config.AlwaysVisible == true or #Library._ActiveFeatures > 0
    end

    Library._RefreshActiveFeaturesPanel()

    local activeFeaturesPanel = {
        Instance = panel,
        ScreenGui = screenGui,
    }

    function activeFeaturesPanel:Destroy()
        screenGui:Destroy()
        Library._ActiveFeaturesPanel = nil
        Library._RefreshActiveFeaturesPanel = nil
    end

    Library._ActiveFeaturesPanel = activeFeaturesPanel
    return activeFeaturesPanel
end

-- ============================================================
-- Window + Tab shell
-- ============================================================
-- Window + Tab shell for Ivory Hub
-- Builds the ScreenGui, the draggable/resizable main window card, sidebar tab
-- list, per-tab scrolling content areas, and the Window/Tab object API.

-- Window chrome dimensions. Mirrored in Theme.lua under Layout for
-- reference; kept as plain locals here (not Theme.Layout.X) since Luau
-- reads these as compile-time constants in a few size calculations below.
local SHADOW_LAYERS = 5
local SHADOW_BUFFER = 40
local SIDEBAR_WIDTH = 150
local TITLEBAR_HEIGHT = 44
local MIN_WINDOW_WIDTH = 480
local MIN_WINDOW_HEIGHT = 320
local SIDEBAR_MIN_WIDTH = 46
local SIDEBAR_MAX_WIDTH = 300
local SIDEBAR_COLLAPSE_WIDTH = 92
local PROFILE_CARD_HEIGHT = 84
local DEFAULT_WINDOW_WIDTH = 755
local DEFAULT_WINDOW_HEIGHT = 550
local MINIMIZED_PILL_WIDTH = 210

-- Mobile screens can be narrower than MIN_WINDOW_WIDTH itself (Roblox
-- mobile viewports commonly run ~350-400 units wide in portrait) - a
-- window that only ever floors at 480 would sit with part of itself
-- pushed off-screen and no way to shrink out of it. Both the initial
-- size and the resize-drag floor get clamped against the CURRENT
-- screen, read fresh each time rather than cached, since a player can
-- rotate their device or the window can be built before the camera
-- has settled.
local function getScreenSize()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(1280, 720)
end

local function clampWindowSize(width, height)
    local vp = getScreenSize()
    local maxWidth = math.max(240, vp.X - 24)
    local maxHeight = math.max(180, vp.Y - 24)
    return math.min(width, maxWidth), math.min(height, maxHeight)
end
local MINIMIZED_PILL_HEIGHT = 36

local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- ===================== Ivory Hub wordmark (brand mark) =====================
-- The blossom mark is a real Roblox decal, not hand-drawn - Frame
-- composition (rotated pill shapes for petals, layered circles for a
-- glow) couldn't get a genuinely convincing sakura silhouette at these
-- small icon sizes, no matter how it was layered. Everything else in
-- the library still draws itself with no image assets (windows,
-- toggles, sliders, dropdowns, the ambient falling petals); this one
-- brand mark is the deliberate exception, since a small, fixed,
-- first-party asset here doesn't carry the same "will this load on
-- every executor" risk that ruled out images for the functional UI.
-- Same asset used on the key-gate screen (example.lua), so the hub
-- carries the same identity end to end.
local WORDMARK_BLOSSOM_ASSET_ID = "rbxassetid://79379082636309"

-- Builds the blossom icon into `parent` (a frame already sized to
-- `size` x `size`). `color` is accepted for call-site compatibility
-- with the old hand-drawn version but unused - the decal carries its
-- own baked-in colors, so tinting it via ImageColor3 would distort it.
local function buildWordmarkBlossom(parent, color, size)
    local image = Instance.new("ImageLabel")
    image.BackgroundTransparency = 1
    image.Size = UDim2.fromScale(1, 1)
    image.Image = WORDMARK_BLOSSOM_ASSET_ID
    image.ScaleType = Enum.ScaleType.Fit
    image.ZIndex = parent.ZIndex + 1
    image.Parent = parent
end

-- Builds the wordmark (blossom icon + "IVORY" + "HUB" text) into `parent`
-- at the given scale, returns its total pixel width/height so the caller
-- can size/position the holder. "IVORY" is a plain label in `color`;
-- "HUB" is a second, immediately adjacent label carrying a Blossom-to-
-- BlossomLight UIGradient (a UIGradient recolors TextLabel glyphs, not
-- just backgrounds), so the two halves read as one word with a
-- brand-colored back half, independent of whatever `color` is.
local function buildIvoryWordmark(parent, color, scale)
    scale = scale or 1
    local textSize = 22 * scale
    local blossomSize = textSize * 0.85
    local gap = 6 * scale

    local blossomHolder = Instance.new("Frame")
    blossomHolder.BackgroundTransparency = 1
    blossomHolder.Size = UDim2.fromOffset(blossomSize, blossomSize)
    blossomHolder.ZIndex = parent.ZIndex
    blossomHolder.Parent = parent
    buildWordmarkBlossom(blossomHolder, Theme.Blossom, blossomSize)

    local ivoryBounds = TextService:GetTextSize("IVORY", textSize, Font.Black, Vector2.new(1000, 100))
    local hubBounds = TextService:GetTextSize("HUB", textSize, Font.Black, Vector2.new(1000, 100))
    local totalHeight = math.max(ivoryBounds.Y, hubBounds.Y, blossomSize)

    blossomHolder.Position = UDim2.fromOffset(0, (totalHeight - blossomSize) / 2)

    local ivoryLabel = Instance.new("TextLabel")
    ivoryLabel.BackgroundTransparency = 1
    ivoryLabel.Position = UDim2.fromOffset(blossomSize + gap, (totalHeight - ivoryBounds.Y) / 2)
    ivoryLabel.Size = UDim2.fromOffset(ivoryBounds.X, ivoryBounds.Y)
    ivoryLabel.Font = Font.Black
    ivoryLabel.TextSize = textSize
    ivoryLabel.TextColor3 = color
    ivoryLabel.TextXAlignment = Enum.TextXAlignment.Left
    ivoryLabel.Text = "IVORY"
    ivoryLabel.ZIndex = parent.ZIndex + 1
    ivoryLabel.Parent = parent

    local hubLabel = Instance.new("TextLabel")
    hubLabel.BackgroundTransparency = 1
    hubLabel.Position = UDim2.fromOffset(blossomSize + gap + ivoryBounds.X, (totalHeight - hubBounds.Y) / 2)
    hubLabel.Size = UDim2.fromOffset(hubBounds.X, hubBounds.Y)
    hubLabel.Font = Font.Black
    hubLabel.TextSize = textSize
    hubLabel.TextColor3 = Color3.new(1, 1, 1)
    hubLabel.TextXAlignment = Enum.TextXAlignment.Left
    hubLabel.Text = "HUB"
    hubLabel.ZIndex = parent.ZIndex + 1
    hubLabel.Parent = parent

    local hubGradient = Instance.new("UIGradient")
    hubGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.Blossom),
        ColorSequenceKeypoint.new(1, Theme.BlossomLight),
    })
    hubGradient.Parent = hubLabel

    local totalWidth = blossomSize + gap + ivoryBounds.X + hubBounds.X
    return totalWidth, totalHeight
end

-- Exposed on Library (not just left as a bare local) so other files can
-- call it regardless of assembly order - a bare local is only a valid
-- upvalue for code textually AFTER this declaration in the same chunk,
-- and hud.lua's CreateWatermark is assembled before shell.lua.
Library._BuildIvoryWordmark = buildIvoryWordmark

-- ===================== Ambient sakura petals =====================
-- Small drifting petals, falling gently with sway, twinkle, and a slow
-- tumbling spin. Each petal is an elongated capsule (Radius.Pill on a
-- non-square frame reads as a petal silhouette rather than a round dot).
-- Pure ScreenGui-layer overlay - no Lighting effects, so the game view
-- behind the window is never blurred or distorted, only the petals
-- themselves are drawn. Self-terminates its animation loop once the
-- field is destroyed.
-- Base-to-tip color pairs, not flat colors, so each falling petal shows
-- the same two-tone gradient the wordmark and the marketing site use
-- rather than a single flat fill. Read live from Theme on every call so
-- petals spawned after a theme change use the new palette (a static
-- table here would keep repainting old Sakura colors forever).
local function PETAL_GRADIENTS()
    return {
        { Theme.Blossom, Theme.BlossomLight },
        { Theme.Blossom, Theme.Petal },
        { Theme.Mauve, Theme.BlossomLight },
    }
end

local _petalFieldMeta = setmetatable({}, { __mode = "k" })

local function createPetalField(parent, zIndex, count, sizeMin, sizeMax, speedMin, speedMax)
    local field = Instance.new("Frame")
    field.Name = "PetalField"
    field.Size = UDim2.fromScale(1, 1)
    field.BackgroundTransparency = 1
    field.ClipsDescendants = true
    field.ZIndex = zIndex
    field.Parent = parent

    local camera = workspace.CurrentCamera
    local petals = {}

    local function newPetal(initial)
        local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
        local size = math.random(sizeMin * 10, sizeMax * 10) / 10
        local petal = Instance.new("Frame")
        petal.Size = UDim2.fromOffset(size * 0.62, size * 1.4)
        petal.AnchorPoint = Vector2.new(0.5, 0.5)
        petal.BackgroundColor3 = Color3.new(1, 1, 1)
        local baseTransparency = 0.45 + math.random() * 0.35
        petal.BackgroundTransparency = baseTransparency
        petal.BorderSizePixel = 0
        petal.ZIndex = zIndex
        petal.Parent = field
        local corner = Instance.new("UICorner")
        corner.CornerRadius = Radius.Pill
        corner.Parent = petal

        local toneList = PETAL_GRADIENTS()
        local tones = toneList[math.random(1, #toneList)]
        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 90
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, tones[1]),
            ColorSequenceKeypoint.new(1, tones[2]),
        })
        gradient.Parent = petal

        return {
            inst = petal,
            x = math.random(0, math.floor(vp.X)),
            y = initial and math.random(-40, math.floor(vp.Y)) or -30,
            speed = speedMin + math.random() * (speedMax - speedMin),
            swayAmp = 10 + math.random() * 20,
            swayFreq = 0.3 + math.random() * 0.6,
            phase = math.random() * 6.28,
            baseTransparency = baseTransparency,
            twinklePhase = math.random() * 6.28,
            rotation = math.random(0, 360),
            rotationSpeed = (math.random() * 2 - 1) * 50,
        }
    end

    for _ = 1, count do
        table.insert(petals, newPetal(true))
    end

    _petalFieldMeta[field] = {
        petals = petals,
        newPetal = newPetal,
    }

    task.spawn(function()
        while field.Parent do
            local dt = RunService.Heartbeat:Wait()
            local vp = camera and camera.ViewportSize or Vector2.new(1280, 720)
            local fw = field.AbsoluteSize.X > 0 and field.AbsoluteSize.X or vp.X
            local fh = field.AbsoluteSize.Y > 0 and field.AbsoluteSize.Y or vp.Y
            for _, fl in ipairs(petals) do
                fl.y = fl.y + fl.speed * dt
                fl.phase = fl.phase + dt
                fl.twinklePhase = fl.twinklePhase + dt * 1.2
                fl.rotation = fl.rotation + fl.rotationSpeed * dt
                local swayX = math.sin(fl.phase * fl.swayFreq) * fl.swayAmp
                fl.inst.Position = UDim2.fromOffset(fl.x + swayX, fl.y)
                fl.inst.Rotation = fl.rotation
                fl.inst.BackgroundTransparency = math.clamp(fl.baseTransparency + math.sin(fl.twinklePhase) * 0.12, 0, 1)
                if fl.y > fh + 30 then
                    fl.y = -30 - math.random(0, 150)
                    fl.x = math.random(0, math.floor(fw))
                end
            end
        end
    end)

    return field
end

-- Wires up hover-grow / press-shrink UIScale animation and (optionally) a
-- UIStroke brighten-on-hover effect for any interactive TextButton, per the
-- shared visual conventions.
local function attachInteraction(button, opts)
    opts = opts or {}
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local stroke = opts.Stroke
    local restTransparency = opts.RestTransparency or 0.82
    local hoverTransparency = opts.HoverTransparency or 0.25

    button.MouseEnter:Connect(function()
        tw(scale, EASE_QUICK, {Scale = 1.02})
        if stroke then
            tw(stroke, EASE_QUICK, {Transparency = hoverTransparency})
        end
    end)

    button.MouseLeave:Connect(function()
        tw(scale, EASE_QUICK, {Scale = 1})
        if stroke then
            tw(stroke, EASE_QUICK, {Transparency = restTransparency})
        end
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tw(scale, EASE_QUICK, {Scale = 0.96})
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            tw(scale, EASE_QUICK, {Scale = 1.02})
        end
    end)

    return scale
end

local function makeCrossBar(parent, rotation)
    local bar = Instance.new("Frame")
    bar.Name = "Bar"
    bar.AnchorPoint = Vector2.new(0.5, 0.5)
    bar.Position = UDim2.new(0.5, 0, 0.5, 0)
    bar.Size = UDim2.new(0, 11, 0, 1.5)
    bar.BackgroundColor3 = Theme.TextPrimary
    bar.BorderSizePixel = 0
    bar.Rotation = rotation
    bar.ZIndex = 6
    bar.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Radius.Pill
    corner.Parent = bar

    return bar
end

-- Builds one of the small circular title bar buttons (minimize / close).
local function makeTitleBarButton(titleBar, offsetFromRight)
    local button = Instance.new("TextButton")
    button.Name = "TitleBarButton"
    button.AutoButtonColor = false
    button.Text = ""
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, offsetFromRight, 0.5, 0)
    button.Size = UDim2.new(0, 26, 0, 26)
    button.BackgroundColor3 = Theme.Plum700
    button.BackgroundTransparency = 0.2
    button.BorderSizePixel = 0
    button.ZIndex = 4
    button.Parent = titleBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = Radius.Pill
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = Alpha.Faint
    stroke.Thickness = 1
    stroke.Parent = button

    attachInteraction(button, {Stroke = stroke})

    return button
end

-- Recomputes the wrapper (shadow bleed) size and each shadow layer's size to
-- track the current visible card size. Used by the resize-handle drag.
local function applyCardSize(self, width, height)
    width = math.max(MIN_WINDOW_WIDTH, width)
    height = math.max(MIN_WINDOW_HEIGHT, height)
    -- Screen fit wins over the nominal minimum above - a device too
    -- small even for MIN_WINDOW_WIDTH still needs a window that fits it.
    width, height = clampWindowSize(width, height)

    self._cardWidth = width
    self._cardHeight = height

    if self._sizeLabel then
        self._sizeLabel.Text = string.format("%d x %d", math.floor(width), math.floor(height))
    end

    self.Wrapper.Size = UDim2.new(0, width + SHADOW_BUFFER * 2, 0, height + SHADOW_BUFFER * 2)
    self.MainFrame.Size = UDim2.new(0, width, 0, height)

    for i, layer in ipairs(self._shadowLayers) do
        local pad = i * 6
        layer.Size = UDim2.new(0, width + pad, 0, height + pad)
    end
end

-- Tweens the wrapper (shadow bleed) and every shadow layer to track a given
-- width/height, without touching the persisted _cardWidth/_cardHeight. Used
-- by ToggleMinimize so the drop shadow shrinks/grows together with the main
-- frame instead of staying pinned at the expanded size.
local function applyShadowMetrics(self, width, height, tweenInfo)
    tw(self.Wrapper, tweenInfo, {Size = UDim2.new(0, width + SHADOW_BUFFER * 2, 0, height + SHADOW_BUFFER * 2)})

    for i, layer in ipairs(self._shadowLayers) do
        local pad = i * 6
        tw(layer, tweenInfo, {Size = UDim2.new(0, width + pad, 0, height + pad)})
    end
end

-- ===================== Tab element wrappers =====================
-- Each of these is a thin, defensive pass-through into the Elements module,
-- which may be authored by a different agent and may not exist yet when this
-- file is tested in isolation.

-- CS2-cheat reference layout: a tab's top-level creations alternate
-- between two side-by-side column frames instead of stacking in one
-- list, so content fills the card like the reference UIs. Children
-- created through a wrapped section still parent into that section's
-- own row (they never come through here), so a section stays whole in
-- whichever column it landed in. Falls back to the flat content frame
-- if the tab was built without columns (defensive: hand-built Tabs).
function Tab:_route()
    if not self.Columns then
        return self.Content
    end
    if (Library.ContentColumns or 2) < 2 then
        return self.Columns[1]
    end
    self._routeIdx = (self._routeIdx or 0) + 1
    return self.Columns[(self._routeIdx - 1) % 2 + 1]
end

function Tab:CreateButton(nameOrConfig, callback)
    if Elements.CreateButton then
        local cfg
        if type(nameOrConfig) == "string" then
            cfg = { Name = nameOrConfig, Callback = callback }
        else
            cfg = nameOrConfig or {}
        end
        return Elements.CreateButton(self:_route(), cfg)
    end
end

function Tab:CreateToggle(nameOrConfig, config)
    if Elements.CreateToggle then
        local flagName, cfg
        if type(nameOrConfig) == "string" then
            flagName = nameOrConfig
            cfg = config or {}
        else
            cfg = nameOrConfig or {}
            flagName = cfg.Flag
        end
        if cfg.CurrentValue == nil and cfg.Default ~= nil then
            cfg.CurrentValue = cfg.Default
        end
        local obj = Elements.CreateToggle(self:_route(), cfg)
        if flagName and obj then
            Library.Toggles[flagName] = obj
            if Library._RegisterFlag then
                Library._RegisterFlag(flagName, obj)
            end
        end
        return obj
    end
end

function Tab:CreateSlider(nameOrConfig, config)
    if Elements.CreateSlider then
        local cfg
        if type(nameOrConfig) == "string" then
            cfg = config or {}
            cfg.Text = cfg.Text or nameOrConfig
        else
            cfg = nameOrConfig or {}
        end
        if cfg.CurrentValue == nil and cfg.Default ~= nil then
            cfg.CurrentValue = cfg.Default
        end
        return Elements.CreateSlider(self:_route(), cfg)
    end
end

function Tab:CreateDropdown(nameOrConfig, config)
    if Elements.CreateDropdown then
        local cfg
        if type(nameOrConfig) == "string" then
            cfg = config or {}
            cfg.Text = cfg.Text or nameOrConfig
        else
            cfg = nameOrConfig or {}
        end
        if cfg.Values and not cfg.Options then
            cfg.Options = cfg.Values
        end
        if cfg.CurrentOption == nil and cfg.Value ~= nil then
            cfg.CurrentOption = cfg.Value
        end
        return Elements.CreateDropdown(self:_route(), cfg)
    end
end

function Tab:CreateMultiDropdown(nameOrConfig, config)
    if Elements.CreateMultiDropdown then
        local cfg
        if type(nameOrConfig) == "string" then
            cfg = config or {}
            cfg.Text = cfg.Text or nameOrConfig
        else
            cfg = nameOrConfig or {}
        end
        return Elements.CreateMultiDropdown(self:_route(), cfg)
    end
end

function Tab:CreateColorPicker(nameOrConfig, config)
    if Elements.CreateColorPicker then
        local cfg
        if type(nameOrConfig) == "string" then
            cfg = config or {}
            cfg.Text = cfg.Text or nameOrConfig
        else
            cfg = nameOrConfig or {}
        end
        return Elements.CreateColorPicker(self:_route(), cfg)
    end
end

function Tab:CreateKeybind(nameOrConfig, config)
    if Elements.CreateKeybind then
        local cfg
        if type(nameOrConfig) == "string" then
            cfg = config or {}
            cfg.Text = cfg.Text or nameOrConfig
        else
            cfg = nameOrConfig or {}
        end
        return Elements.CreateKeybind(self:_route(), cfg)
    end
end

function Tab:CreateInput(config)
    if Elements.CreateInput then
        return Elements.CreateInput(self:_route(), config)
    end
end

function Tab:CreateLabel(config)
    if Elements.CreateLabel then
        return Elements.CreateLabel(self:_route(), config)
    end
end

function Tab:CreateParagraph(config)
    if Elements.CreateParagraph then
        return Elements.CreateParagraph(self:_route(), config)
    end
end

function Tab:CreateDivider(config)
    if Elements.CreateDivider then
        return Elements.CreateDivider(self:_route(), config)
    end
end

function Tab:CreateSection(title)
    if Elements.CreateSection then
        local section = Elements.CreateSection(self:_route(), title)
        return Tab._wrapSection(section)
    end
end

function Tab:CreateDependencyBox()
    local frame = Instance.new("Frame")
    frame.Name = "DependencyBox"
    frame.BackgroundTransparency = 1
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.ZIndex = 3
    frame.Parent = self:_route()
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = frame
    local wrapped = Tab._wrapSection({Instance = frame, Set = function() end})

    local function checkDeps(deps)
        for _, dep in ipairs(deps) do
            local toggle, expected = dep[1], dep[2]
            if toggle and toggle.Value ~= expected then
                return false
            end
        end
        return true
    end

    wrapped.SetupDependencies = function(_, deps)
        local function applyState()
            local met = checkDeps(deps)
            frame.Visible = met
        end

        for _, dep in ipairs(deps) do
            local toggle = dep[1]
            if toggle and toggle.Set then
                local oldSet = toggle.Set
                toggle.Set = function(self, value, silent)
                    oldSet(self, value, silent)
                    task.defer(applyState)
                end
            end
        end

        applyState()
    end

    return wrapped
end

Tab._wrapSection = function(section)
        section.CreateLabel = function(_, textOrConfig)
            if type(textOrConfig) == "table" then
                textOrConfig = textOrConfig.Text or textOrConfig.Name or textOrConfig.Title or ""
            end
            return Elements.CreateLabel(section.Instance, textOrConfig)
        end
        section.CreateButton = function(_, nameOrConfig, callback)
            local cfg
            if type(nameOrConfig) == "string" then
                cfg = { Name = nameOrConfig, Callback = callback }
            else
                cfg = nameOrConfig or {}
            end
            return Elements.CreateButton(section.Instance, cfg)
        end
        section.CreateToggle = function(_, nameOrConfig, config)
            local flagName, cfg
            if type(nameOrConfig) == "string" then
                flagName = nameOrConfig
                cfg = config or {}
            else
                cfg = nameOrConfig or {}
                flagName = cfg.Flag
            end
            if cfg.CurrentValue == nil and cfg.Default ~= nil then
                cfg.CurrentValue = cfg.Default
            end
            local obj = Elements.CreateToggle(section.Instance, cfg)
            if flagName and obj then
                Library.Toggles[flagName] = obj
                if Library._RegisterFlag then
                    Library._RegisterFlag(flagName, obj)
                end
            end
            return obj
        end
        section.CreateSlider = function(_, nameOrConfig, config)
            local cfg
            if type(nameOrConfig) == "string" then
                cfg = config or {}
                cfg.Text = cfg.Text or nameOrConfig
            else
                cfg = nameOrConfig or {}
            end
            if cfg.CurrentValue == nil and cfg.Default ~= nil then
                cfg.CurrentValue = cfg.Default
            end
            return Elements.CreateSlider(section.Instance, cfg)
        end
        section.CreateDropdown = function(_, nameOrConfig, config)
            local cfg
            if type(nameOrConfig) == "string" then
                cfg = config or {}
                cfg.Text = cfg.Text or nameOrConfig
            else
                cfg = nameOrConfig or {}
            end
            if cfg.Values and not cfg.Options then
                cfg.Options = cfg.Values
            end
            if cfg.CurrentOption == nil and cfg.Value ~= nil then
                cfg.CurrentOption = cfg.Value
            end
            return Elements.CreateDropdown(section.Instance, cfg)
        end
        if Elements.CreateMultiDropdown then
            section.CreateMultiDropdown = function(_, nameOrConfig, config)
                local cfg
                if type(nameOrConfig) == "string" then
                    cfg = config or {}
                    cfg.Text = cfg.Text or nameOrConfig
                else
                    cfg = nameOrConfig or {}
                end
                return Elements.CreateMultiDropdown(section.Instance, cfg)
            end
        end
        if Elements.CreateColorPicker then
            section.CreateColorPicker = function(_, config)
                return Elements.CreateColorPicker(section.Instance, config)
            end
        end
        if Elements.CreateKeybind then
            section.CreateKeybind = function(_, config)
                return Elements.CreateKeybind(section.Instance, config)
            end
        end
        if Elements.CreateInput then
            section.CreateInput = function(_, nameOrConfig, config)
                local cfg
                if type(nameOrConfig) == "string" then
                    cfg = config or {}
                    cfg.Text = cfg.Text or nameOrConfig
                else
                    cfg = nameOrConfig or {}
                end
                return Elements.CreateInput(section.Instance, cfg)
            end
        end
        if Elements.CreateParagraph then
            section.CreateParagraph = function(_, config)
                return Elements.CreateParagraph(section.Instance, config)
            end
        end
        section.CreateDivider = function(_)
            return Elements.CreateDivider(section.Instance)
        end
        section.CreateSection = function(_, subTitle)
            local sub = Elements.CreateSection(section.Instance, subTitle)
            return Tab._wrapSection(sub)
        end
        section.CreateDependencyBox = function(_)
            local frame = Instance.new("Frame")
            frame.Name = "DependencyBox"
            frame.BackgroundTransparency = 1
            frame.AutomaticSize = Enum.AutomaticSize.Y
            frame.Size = UDim2.new(1, 0, 0, 0)
            frame.ZIndex = 3
            frame.Parent = section.Instance
            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Padding = UDim.new(0, 6)
            layout.Parent = frame
            local wrapped = Tab._wrapSection({Instance = frame, Set = function() end})

            local function checkDeps(deps)
                for _, dep in ipairs(deps) do
                    local toggle, expected = dep[1], dep[2]
                    if toggle and toggle.Value ~= expected then
                        return false
                    end
                end
                return true
            end

            wrapped.SetupDependencies = function(_, deps)
                local function applyState()
                    local met = checkDeps(deps)
                    frame.Visible = met
                end

                for _, dep in ipairs(deps) do
                    local toggle = dep[1]
                    if toggle and toggle.Set then
                        local oldSet = toggle.Set
                        toggle.Set = function(self, value, silent)
                            oldSet(self, value, silent)
                            task.defer(applyState)
                        end
                    end
                end

                applyState()
            end

            return wrapped
        end
        return section
end

-- ===================== Window methods =====================

-- Small glyph shown to the left of each sidebar tab label, keyed off the
-- tab name (lowercased). Unmapped names get a stable glyph from a fallback
-- pool, so any tab any script creates still shows a symbol of its own.
local TAB_ICONS = {
    ["main"] = "◆",
    ["home"] = "◆",
    ["legit"] = "✚",
    ["aimbot"] = "✚",
    ["visuals"] = "◉",
    ["visual"] = "◉",
    ["esp"] = "◉",
    ["misc"] = "▩",
    ["miscellaneous"] = "▩",
    ["other"] = "▩",
    ["grenade"] = "❖",
    ["grenade helper"] = "❖",
    ["configs"] = "▦",
    ["config"] = "▦",
    ["configuration"] = "▦",
    ["player"] = "●",
    ["combat"] = "⚔",
    ["world"] = "◈",
    ["features"] = "★",
    ["movement"] = "☆",
    ["showcase"] = "❖",
    ["settings"] = "⚙",
    ["about"] = "ℹ",
    ["rage"] = "♦",
    ["hvh"] = "☆",
    ["aa"] = "☆",
    ["antiaim"] = "☆",
    ["anti aim"] = "☆",
    ["aim"] = "✚",
    ["silentaim"] = "✚",
    ["silent aim"] = "✚",
    ["trigger"] = "✚",
    ["triggerbot"] = "✚",
    ["crosshair"] = "✚",
    ["prediction"] = "✚",
    ["recoil"] = "✚",
    ["weapons"] = "⚔",
    ["weapon"] = "⚔",
    ["guns"] = "⚔",
    ["gun"] = "⚔",
    ["knife"] = "⚔",
    ["melee"] = "⚔",
    ["chams"] = "◉",
    ["glow"] = "◉",
    ["skeleton"] = "◉",
    ["tracers"] = "◉",
    ["radar"] = "◉",
    ["box"] = "◉",
    ["overlay"] = "◉",
    ["fly"] = "☆",
    ["speed"] = "☆",
    ["noclip"] = "☆",
    ["jump"] = "☆",
    ["spin"] = "☆",
    ["teleport"] = "☆",
    ["tp"] = "☆",
    ["glide"] = "☆",
    ["players"] = "●",
    ["team"] = "●",
    ["teams"] = "●",
    ["lobby"] = "●",
    ["server"] = "●",
    ["servers"] = "●",
    ["character"] = "●",
    ["characters"] = "●",
    ["map"] = "◈",
    ["environment"] = "◈",
    ["env"] = "◈",
    ["npc"] = "◈",
    ["npcs"] = "◈",
    ["objects"] = "◈",
    ["items"] = "◈",
    ["inventory"] = "▦",
    ["inv"] = "▦",
    ["shop"] = "▦",
    ["store"] = "▦",
    ["trade"] = "▦",
    ["skins"] = "▦",
    ["crates"] = "▦",
    ["hud"] = "▩",
    ["gui"] = "▩",
    ["theme"] = "▩",
    ["interface"] = "▩",
    ["menu"] = "▩",
    ["colors"] = "▩",
    ["music"] = "▩",
    ["radio"] = "▩",
    ["chat"] = "▩",
    ["fun"] = "▩",
    ["troll"] = "▩",
    ["party"] = "▩",
    ["scripts"] = "◆",
    ["script"] = "◆",
    ["hub"] = "◆",
    ["loader"] = "◆",
    ["help"] = "ℹ",
    ["credits"] = "ℹ",
    ["changelog"] = "ℹ",
    ["faq"] = "ℹ",
    ["discord"] = "ℹ",
    ["update"] = "ℹ",
    ["updates"] = "ℹ",
    ["info"] = "ℹ",
}

local TAB_ICON_FALLBACK = { "◆", "●", "◈", "⚔", "✚", "◉", "▦", "★", "♦", "☆" }

local function fallbackTabIcon(name)
    local sum = 0
    for i = 1, #name do
        sum = sum + string.byte(name, i)
    end
    return TAB_ICON_FALLBACK[(sum % #TAB_ICON_FALLBACK) + 1]
end

-- Sidebar collapse: under SIDEBAR_COLLAPSE_WIDTH the tab labels are hidden
-- and the glyph is centered and bolded, so a narrow sidebar still reads as
-- tabs. Applied on creation too, for tabs built while already collapsed.
local function setTabCollapsed(tab, collapsed)
    local icon = tab.Icon
    local label = tab.Label
    if not icon or not label then
        return
    end
    label.Visible = not collapsed
    if collapsed then
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.Font = Font.Bold
        icon.TextColor3 = Theme.TextPrimary
    else
        icon.AnchorPoint = Vector2.new(0, 0)
        icon.Position = UDim2.new(0, 12, 0, 0)
        icon.Font = Font.Medium
        icon.TextColor3 = Theme.TextTertiary
    end
end

-- Live sidebar width: tab list, divider, drag handle, content area and the
-- bottom profile card all track it, and crossing SIDEBAR_COLLAPSE_WIDTH
-- flips every tab between full and icon-only presentation.
function Window:SetSidebarWidth(width)
    local cardW = self._cardWidth or DEFAULT_WINDOW_WIDTH
    local maxW = math.min(SIDEBAR_MAX_WIDTH, math.max(SIDEBAR_MIN_WIDTH + 60, cardW - 240))
    width = math.clamp(width, SIDEBAR_MIN_WIDTH, maxW)
    self._sidebarWidth = width

    if self.Sidebar then
        self.Sidebar.Size = UDim2.new(0, width, 1, -(TITLEBAR_HEIGHT + PROFILE_CARD_HEIGHT))
    end
    if self._sidebarDivider then
        self._sidebarDivider.Position = UDim2.new(0, width, 0, TITLEBAR_HEIGHT)
    end
    if self.SidebarDragHandle then
        self.SidebarDragHandle.Position = UDim2.new(0, width - 4, 0, TITLEBAR_HEIGHT)
    end
    if self.ContentArea then
        self.ContentArea.Position = UDim2.new(0, width, 0, TITLEBAR_HEIGHT)
        self.ContentArea.Size = UDim2.new(1, -width, 1, -TITLEBAR_HEIGHT)
    end
    local collapsed = width < SIDEBAR_COLLAPSE_WIDTH
    if self._profileCard then
        self._profileCard.Size = UDim2.new(0, math.max(0, width - 16), 0, PROFILE_CARD_HEIGHT)
        if self._profileAvatar then
            local avatarD = collapsed and math.max(24, math.min(44, width - 16)) or 44
            self._profileAvatar.Size = UDim2.new(0, avatarD, 0, avatarD)
        end
        if self._profileName then
            self._profileName.Visible = not collapsed
        end
        if self._profileStats then
            self._profileStats.Visible = not collapsed
        end
    end

    if collapsed ~= (self._sidebarCollapsed == true) then
        self._sidebarCollapsed = collapsed
        for _, tab in ipairs(self._tabs) do
            setTabCollapsed(tab, collapsed)
        end
    end
    return width
end

function Window:CreateTab(name)
    local tabName = tostring((type(name) == "table" and name.Name) or name or "Tab")
    local tabIndex = #self._tabs + 1

    local tabButton = Instance.new("TextButton")
    tabButton.Name = "TabButton_" .. tabName
    tabButton.AutoButtonColor = false
    tabButton.Text = ""
    tabButton.Size = UDim2.new(1, 0, 0, 44)
    tabButton.BackgroundColor3 = Theme.Plum700
    tabButton.BackgroundTransparency = 1
    tabButton.BorderSizePixel = 0
    tabButton.LayoutOrder = tabIndex
    tabButton.ZIndex = 3
    tabButton.Parent = self.Sidebar

    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = Radius.MD
    tabCorner.Parent = tabButton

    -- Same glass-edge stroke language as everything else in the theme -
    -- the selected state reads as a soft outlined chip instead of a flat
    -- solid block.
    local tabStroke = Instance.new("UIStroke")
    tabStroke.Thickness = 1
    tabStroke.Color = Color3.fromRGB(255, 255, 255)
    tabStroke.Transparency = 1
    tabStroke.Parent = tabButton

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.AnchorPoint = Vector2.new(0, 0.5)
    accent.Position = UDim2.new(0, 0, 0.5, 0)
    accent.Size = UDim2.new(0, 3, 1, -16)
    accent.BackgroundColor3 = Theme.Blossom
    accent.BackgroundTransparency = 1
    accent.BorderSizePixel = 0
    accent.ZIndex = 4
    accent.Parent = tabButton

    if Library._RegisterAccentBound then
        Library._RegisterAccentBound(function(color)
            if accent.Parent then
                accent.BackgroundColor3 = color
            end
        end)
    end

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = Radius.Pill
    accentCorner.Parent = accent

    local icon = Instance.new("TextLabel")
    icon.Name = "Icon"
    icon.BackgroundTransparency = 1
    icon.Position = UDim2.new(0, 12, 0, 0)
    icon.Size = UDim2.new(0, 18, 1, 0)
    icon.Font = Font.Medium
    icon.TextSize = TextSizes.XL
    icon.TextColor3 = Theme.TextTertiary
    icon.TextXAlignment = Enum.TextXAlignment.Center
    icon.Text = TAB_ICONS[string.lower(tabName)] or fallbackTabIcon(tabName)
    icon.ZIndex = 4
    icon.Parent = tabButton

    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.BackgroundTransparency = 1
    label.Position = UDim2.new(0, 38, 0, 0)
    label.Size = UDim2.new(1, -46, 1, 0)
    label.Font = Font.Medium
    label.TextSize = TextSizes.LG
    label.TextColor3 = Theme.TextSecondary
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Text = tabName
    label.ZIndex = 4
    label.Parent = tabButton

    attachInteraction(tabButton)

    local content = Instance.new("ScrollingFrame")
    content.Name = "TabContent_" .. tabName
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.Size = UDim2.new(1, 0, 1, 0)
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollBarThickness = 3
    content.ScrollBarImageColor3 = Theme.Blossom
    content.ScrollBarImageTransparency = 0.4
    content.ScrollingDirection = Enum.ScrollingDirection.Y
    content.ZIndex = 3
    content.Visible = false
    content.Parent = self.ContentArea

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 4)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 16)
    padding.Parent = content

    local switchScale = Instance.new("UIScale")
    switchScale.Name = "SwitchScale"
    switchScale.Scale = 1
    switchScale.Parent = content

    -- Two side-by-side columns (CS2-cheat reference layout). Each column
    -- carries its own vertical layout; Tab:_route() hands top-level
    -- creations to them alternately so a tab fills both columns. The
    -- scroll canvas tracks whichever column ends up taller.
    local function makeColumn(name, xPos)
        local column = Instance.new("Frame")
        column.Name = name
        column.BackgroundTransparency = 1
        column.Position = xPos
        column.Size = UDim2.new(0.5, -8, 0, 0)
        column.AutomaticSize = Enum.AutomaticSize.Y
        column.ZIndex = 3
        column.Parent = content
        local list = Instance.new("UIListLayout")
        list.FillDirection = Enum.FillDirection.Vertical
        list.Padding = UDim.new(0, 10)
        list.SortOrder = Enum.SortOrder.LayoutOrder
        list.Parent = column
        return column, list
    end

    local colL, colLLayout = makeColumn("ColumnL", UDim2.new(0, 0, 0, 0))
    local colR, colRLayout = makeColumn("ColumnR", UDim2.new(0.5, 8, 0, 0))

    -- Open directly in single-column mode if that's the active setting
    -- (SetContentColumns only reflows windows that already exist).
    if (Library.ContentColumns or 2) < 2 then
        colL.Size = UDim2.new(1, 0, 0, 0)
        colR.Visible = false
    end

    local function updateCanvas()
        local h = math.max(colLLayout.AbsoluteContentSize.Y, colRLayout.AbsoluteContentSize.Y)
        content.CanvasSize = UDim2.new(0, 0, 0, h + 16)
    end
    colLLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)
    colRLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(updateCanvas)

    local tabObject = setmetatable({
        Name = tabName,
        Window = self,
        Button = tabButton,
        Stroke = tabStroke,
        Accent = accent,
        Icon = icon,
        Label = label,
        Content = content,
        Columns = { colL, colR },
        _routeIdx = 0,
        ListLayout = colLLayout,
    }, Tab)

    table.insert(self._tabs, tabObject)

    tabButton.MouseButton1Click:Connect(function()
        self:SelectTab(tabObject)
    end)

    tabButton.MouseEnter:Connect(function()
        if self._activeTab ~= tabObject then
            tw(tabButton, EASE_QUICK, {BackgroundTransparency = Alpha.Faint})
        end
    end)

    tabButton.MouseLeave:Connect(function()
        if self._activeTab ~= tabObject then
            tw(tabButton, EASE_QUICK, {BackgroundTransparency = 1})
        end
    end)

    if Library._RegisterSearchable then
        Library._RegisterSearchable(tabName, tabButton)
    end

    if #self._tabs == 1 then
        self:SelectTab(tabObject)
    end

    if self._sidebarCollapsed then
        setTabCollapsed(tabObject, true)
    end

    return tabObject
end

function Window:SelectTab(tab)
    if not tab or self._activeTab == tab then
        return
    end

    local previous = self._activeTab
    if previous then
        previous.Content.Visible = false
        tw(previous.Button, EASE_QUICK, {BackgroundTransparency = 1})
        tw(previous.Stroke, EASE_QUICK, {Transparency = 1})
        tw(previous.Accent, EASE_QUICK, {BackgroundTransparency = 1})
        tw(previous.Label, EASE_QUICK, {TextColor3 = Theme.TextSecondary})
        if previous.Icon then
            tw(previous.Icon, EASE_QUICK, {TextColor3 = Theme.TextTertiary})
        end
    end

    tab.Content.Visible = true
    self._activeTab = tab

    cancelTweens(tab.Content)
    tab.Content.Position = UDim2.new(0, 0, 0, 8)
    tw(tab.Content, EASE_QUICK, { Position = UDim2.new(0, 0, 0, 0) })
    local switchScale = tab.Content:FindFirstChild("SwitchScale")
    if switchScale then
        cancelTweens(switchScale)
        switchScale.Scale = 0.975
        tw(switchScale, EASE_QUICK, { Scale = 1 })
    end

    -- A soft tint + thin outline reads as a selected chip; the old 0.15
    -- transparency was a near-solid block that clashed with the rest of
    -- the theme's restrained glass-edge language.
    tw(tab.Button, EASE_QUICK, {BackgroundTransparency = 0.88})
    tw(tab.Stroke, EASE_QUICK, {Transparency = 0.72})
    tw(tab.Accent, EASE_QUICK, {BackgroundTransparency = 0})
    tw(tab.Label, EASE_QUICK, {TextColor3 = Theme.TextPrimary})
    if tab.Icon then
        tw(tab.Icon, EASE_QUICK, {TextColor3 = Theme.Blossom})
    end
end

-- Switch between one full-width content column and two side-by-side
-- columns. Every open window is reflowed live: each tab's items are
-- merged back into creation order (interleaving the two columns, which
-- is exactly the order they were created in), then re-split for the
-- new mode. LayoutOrder ties are broken by child index so the visual
-- order survives the round-trip.
function Library:SetContentColumns(count)
    local cols = (count == 1) and 1 or 2
    Library.ContentColumns = cols

    for _, win in ipairs(Library._windows) do
        for _, tab in ipairs(win._tabs or {}) do
            local colL = tab.Columns and tab.Columns[1]
            local colR = tab.Columns and tab.Columns[2]
            if colL and colL.Parent and colR and colR.Parent then
                local function collect(col)
                    local decorated = {}
                    for i, child in ipairs(col:GetChildren()) do
                        if child:IsA("GuiObject") then
                            table.insert(decorated, { obj = child, idx = i })
                        end
                    end
                    table.sort(decorated, function(a, b)
                        local ao = a.obj.LayoutOrder or 0
                        local bo = b.obj.LayoutOrder or 0
                        if ao ~= bo then
                            return ao < bo
                        end
                        return a.idx < b.idx
                    end)
                    local items = {}
                    for _, d in ipairs(decorated) do
                        table.insert(items, d.obj)
                    end
                    return items
                end

                local L, R = collect(colL), collect(colR)
                local merged = {}
                for i = 1, math.max(#L, #R) do
                    if L[i] then
                        table.insert(merged, L[i])
                    end
                    if R[i] then
                        table.insert(merged, R[i])
                    end
                end

                if cols == 1 then
                    colL.Size = UDim2.new(1, 0, 0, 0)
                    colR.Visible = false
                    for _, item in ipairs(merged) do
                        item.Parent = colL
                    end
                else
                    colL.Size = UDim2.new(0.5, -8, 0, 0)
                    colR.Visible = true
                    for i, item in ipairs(merged) do
                        item.Parent = (i % 2 == 1) and colL or colR
                    end
                end
                tab._routeIdx = #merged
            end
        end
    end
end

-- Minimizing collapses the whole window down into a small draggable pill
-- showing the wordmark plus live FPS/ping - the same shape and content as
-- the standalone watermark, so minimizing reads as "collapse into a
-- watermark" rather than an unrelated shape. The title bar is resized to
-- fill that whole pill, so its existing drag connections keep working
-- across it for free; a short (non-drag) click on the pill restores the
-- window, so no separate button is needed to unminimize.
function Window:ToggleMinimize()
    if not self.MainFrame then
        return
    end

    self._minimized = not self._minimized

    if self._minimized then
        self._expandedWidth = self._cardWidth
        self._expandedHeight = self._cardHeight

        tw(self.MainFrame, EASE_SPRING, { Size = UDim2.fromOffset(MINIMIZED_PILL_WIDTH, MINIMIZED_PILL_HEIGHT) })
        applyShadowMetrics(self, MINIMIZED_PILL_WIDTH, MINIMIZED_PILL_HEIGHT, EASE_SPRING)
        if self._mainCorner then
            tw(self._mainCorner, EASE_SPRING, { CornerRadius = Radius.Pill })
        end

        if self.TitleBar then
            tw(self.TitleBar, EASE_SPRING, { Size = UDim2.fromScale(1, 1) })
        end
        if self._titleMarkHolder then
            self._titleMarkHolder.Visible = false
        end
        if self._titleLabel then
            self._titleLabel.Visible = false
        end
        if self._sizeLabel then
            self._sizeLabel.Visible = false
        end
        if self._minimizeButton then
            self._minimizeButton.Visible = false
        end
        if self._closeButton then
            self._closeButton.Visible = false
        end
        if self._cubeMarkHolder then
            self._cubeMarkHolder.Parent = self.MainFrame
            self._cubeMarkHolder.Visible = true
        end
        if self.Sidebar then
            self.Sidebar.Visible = false
        end
        if self.ContentArea then
            self.ContentArea.Visible = false
        end
    else
        local restoreWidth = self._expandedWidth or self._cardWidth or DEFAULT_WINDOW_WIDTH
        local restoreHeight = self._expandedHeight or self._cardHeight or DEFAULT_WINDOW_HEIGHT
        restoreWidth, restoreHeight = clampWindowSize(restoreWidth, restoreHeight)
        self._cardWidth, self._cardHeight = restoreWidth, restoreHeight

        self.MainFrame.Visible = true
        tw(self.MainFrame, EASE_SPRING, { Size = UDim2.fromOffset(restoreWidth, restoreHeight) })
        applyShadowMetrics(self, restoreWidth, restoreHeight, EASE_SPRING)
        if self._mainCorner then
            tw(self._mainCorner, EASE_SPRING, { CornerRadius = Radius.XL })
        end
        if self.TitleBar and self._titleBarRestSize then
            tw(self.TitleBar, EASE_SPRING, { Size = self._titleBarRestSize })
        end
        if self._titleMarkHolder then
            self._titleMarkHolder.Visible = true
        end
        if self._titleLabel then
            self._titleLabel.Visible = true
        end
        if self._sizeLabel then
            self._sizeLabel.Visible = true
        end
        if self._minimizeButton then
            self._minimizeButton.Visible = true
        end
        if self._closeButton then
            self._closeButton.Visible = true
        end
        if self._cubeMarkHolder then
            self._cubeMarkHolder.Visible = false
            self._cubeMarkHolder.Parent = nil
        end
        if self.Sidebar then
            self.Sidebar.Visible = true
        end
        if self.ContentArea then
            self.ContentArea.Visible = true
        end

        -- Clamp wrapper position so the restored window stays on-screen and
        -- the title bar is always reachable (fixes "can't drag after restore
        -- from top of screen").
        task.defer(function()
            if not self.Wrapper then return end
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
            local ww = (self._cardWidth or DEFAULT_WINDOW_WIDTH) + SHADOW_BUFFER * 2
            local wh = (self._cardHeight or DEFAULT_WINDOW_HEIGHT) + SHADOW_BUFFER * 2
            local pos = self.Wrapper.Position
            local cx = pos.X.Scale * vp.X + pos.X.Offset
            local cy = pos.Y.Scale * vp.Y + pos.Y.Offset
            local halfW = ww / 2
            local halfH = wh / 2
            cx = math.max(halfW, math.min(vp.X - halfW, cx))
            cy = math.max(halfH + 10, math.min(vp.Y - halfH, cy))
            self.Wrapper.Position = UDim2.new(0, cx, 0, cy)
        end)
    end

    if self.ResizeHandle then
        self.ResizeHandle.Visible = not self._minimized
    end
    if self.SidebarDragHandle then
        self.SidebarDragHandle.Visible = not self._minimized
    end
    if self._profileCard then
        self._profileCard.Visible = not self._minimized
    end
end

-- Direct, idempotent minimize control - ToggleMinimize flips whatever
-- the current state is, which is right for a click handler but awkward
-- to drive from a script (e.g. "minimize the hub during a cutscene"),
-- since that requires reaching into the private _minimized field to
-- know whether calling it would even do the right thing. These three
-- are the actual "minimize command" surface: call Minimize/Restore
-- and get that exact state regardless of what it was, or check
-- IsMinimized without touching internals at all.
function Window:Minimize()
    if not self._minimized then
        self:ToggleMinimize()
    end
end

function Window:Restore()
    if self._minimized then
        self:ToggleMinimize()
    end
end

function Window:IsMinimized()
    return self._minimized == true
end

function Window:Destroy()
    for _, conn in ipairs(self._connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end

    local wrapper = self.Wrapper
    local screenGui = self.ScreenGui
    local finished = false

    local function finish()
        if finished then
            return
        end
        finished = true
        if screenGui then
            screenGui:Destroy()
        end
    end

    if wrapper then
        if self._uiScale then
            tw(self._uiScale, EASE_QUICK, {Scale = 0.9})
        end
        local fadeTween = tw(wrapper, EASE_QUICK, {GroupTransparency = 1})
        if fadeTween then
            fadeTween.Completed:Connect(finish)
        end
    end

    task.delay(0.45, finish)
end

-- ===================== Window construction =====================

Library.CreateWindow = function(config)
    config = config or {}
    -- No brand-name fallback: the wordmark carries identity on its own, so an
    -- unnamed window just shows no title text rather than redundant text.
    local windowName = config.Name or ""

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LootUI"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 99999
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

    local player = Players.LocalPlayer
    local playerGui = player and (player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui"))
    if playerGui then
        screenGui.Parent = playerGui
    else
        pcall(function()
            screenGui.Parent = game:GetService("CoreGui")
        end)
    end

    local self = setmetatable({}, Window)
    self.ScreenGui = screenGui
    Library.ScreenGui = screenGui
    print("[Ivory] ScreenGui parented to:", screenGui.Parent and screenGui.Parent:GetFullName() or "nil")
    Library.KeybindFrame = Instance.new("Frame")
    Library.KeybindFrame.Name = "KeybindFrame"
    Library.KeybindFrame.Visible = false
    Library.KeybindFrame.Parent = screenGui
    Library.Unloaded = false
    Library.CornerRadius = 4
    Library.DPIScale = 100
    Library.ToggleKeybind = nil
    self._tabs = {}
    self._connections = {}
    self._activeTab = nil
    self._minimized = false
    table.insert(Library._windows, self)
    -- config.Width/Height let a script ask for a specific size; either
    -- way, clamp against the actual screen so the window never opens
    -- larger than the device it's rendering on (the main mobile-
    -- friendliness fix - previously this was always exactly 640x420
    -- regardless of screen size, which can overflow a phone screen
    -- entirely with no way to shrink out of it before the resize
    -- handle itself becomes reachable).
    local requestedWidth = tonumber(config.Width) or DEFAULT_WINDOW_WIDTH
    local requestedHeight = tonumber(config.Height) or DEFAULT_WINDOW_HEIGHT
    self._cardWidth, self._cardHeight = clampWindowSize(requestedWidth, requestedHeight)
    self.ConfigurationSaving = config.ConfigurationSaving
    Library.ConfigurationSaving = config.ConfigurationSaving

    if Library._RegisterMenuKeybindWindow then
        Library._RegisterMenuKeybindWindow(self)
    end

    -- ---------------- Ambient effects (behind + in front of the window) ----------------
    -- All pure ScreenGui-layer overlays - no Lighting effects anywhere, so the
    -- game view itself is never blurred or distorted, only these sit on top.

    -- Forward-declared: wrapper itself isn't created until further down (it's
    -- the CanvasGroup mainFrame lives in), but the aura/glow-blob position
    -- tracking below needs to close over it as an upvalue. Assigned with a
    -- plain `wrapper = ...` (no `local`) at its actual creation point.
    local wrapper

    self.Aura = nil
    -- the window, each with its own blossom/petal/mauve UIGradient that
    -- keeps rotating - replaces the old fixed ray-burst spokes with
    -- something softer and genuinely in motion, matching the marketing
    -- site's gradient glow treatment. ZIndex -1 for the same reason as
    -- the aura above.
    self._glowBlobs = {}

    -- Wrapper is a CanvasGroup so the whole window (card + shadow bleed) can
    -- fade and scale in as one unit, and so the shadow layers are allowed to
    -- bleed outward past the card edges without being clipped by it.
    -- (No `local` here - wrapper was already forward-declared above the
    -- aura/glow-blob setup so those closures can see it.)
    wrapper = Instance.new("CanvasGroup")
    wrapper.Name = "WindowWrapper"
    wrapper.AnchorPoint = Vector2.new(0.5, 0.5)
    wrapper.Position = UDim2.fromScale(0.5, 0.5)
    wrapper.Size = UDim2.new(0, self._cardWidth + SHADOW_BUFFER * 2, 0, self._cardHeight + SHADOW_BUFFER * 2)
    wrapper.BackgroundTransparency = 1
    wrapper.GroupTransparency = 1
    wrapper.Parent = screenGui
    self.Wrapper = wrapper
    Library.MainFrame = wrapper

    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 0.9
    uiScale.Parent = wrapper
    self._uiScale = uiScale

    local shadowLayers = {}
    for i = 1, SHADOW_LAYERS do
        local pad = i * 6
        local layer = Instance.new("Frame")
        layer.Name = "ShadowLayer" .. i
        layer.AnchorPoint = Vector2.new(0.5, 0.5)
        layer.Position = UDim2.new(0.5, 0, 0.5, i * 2)
        layer.Size = UDim2.new(0, self._cardWidth + pad, 0, self._cardHeight + pad)
        layer.BackgroundColor3 = Theme.Plum900
        layer.BackgroundTransparency = 0.65 + (i * 0.055)
        layer.BorderSizePixel = 0
        layer.ZIndex = 1
        layer.Parent = wrapper

        local layerCorner = Instance.new("UICorner")
        layerCorner.CornerRadius = UDim.new(0, 12 + pad / 2)
        layerCorner.Parent = layer

        table.insert(shadowLayers, layer)
    end
    self._shadowLayers = shadowLayers

    -- Ambient sakura petals: a sparse layer drifting behind the window,
    -- and a few petals drifting in front of it, parented to a clip frame
    -- inside wrapper so they stay inside the GUI window only.
    local petalClip = Instance.new("Frame")
    petalClip.Name = "PetalClip"
    petalClip.Size = UDim2.new(0, self._cardWidth, 0, self._cardHeight)
    petalClip.AnchorPoint = Vector2.new(0.5, 0.5)
    petalClip.Position = UDim2.new(0.5, 0, 0.5, 0)
    petalClip.BackgroundTransparency = 1
    petalClip.ClipsDescendants = true
    petalClip.ZIndex = 50
    petalClip.Parent = wrapper
    self._petalClip = petalClip

    local petalBack = createPetalField(petalClip, -1, 90, 1.5, 4, 16, 34)
    local petalFront = createPetalField(petalClip, 60, 27, 2.5, 5, 26, 46)
    self._petalFields = { petalBack, petalFront }

    -- Petal control API: toggle visibility and adjust count
    function self:SetPetalsEnabled(enabled)
        for _, field in ipairs(self._petalFields) do
            field.Visible = enabled
        end
    end

    function self:SetPetalCount(count)
        local totalFields = #self._petalFields
        local backCount = math.floor(count * 90 / 117)
        local frontCount = count - backCount
        local targets = { backCount, frontCount }
        for i, field in ipairs(self._petalFields) do
            local meta = _petalFieldMeta[field]
            if not meta then continue end
            local target = targets[i] or 0
            local existing = #meta.petals
            if target > existing then
                for _ = 1, target - existing do
                    local p = meta.newPetal(false)
                    table.insert(meta.petals, p)
                end
            elseif target < existing then
                for j = existing, target + 1, -1 do
                    if meta.petals[j] and meta.petals[j].inst then
                        meta.petals[j].inst:Destroy()
                    end
                end
                for _ = existing, target + 1, -1 do
                    table.remove(meta.petals)
                end
            end
        end
    end

    self._petalsEnabled = true
    self._petalCount = 117

    -- ---------------- Corner accents ----------------
    -- Small L-shaped accents living in the ambient glow margin around the
    -- card (inside the wrapper, outside mainFrame entirely) - since they
    -- never share space with mainFrame's content, they can never conflict
    -- with the logo, title bar buttons, search bar, or resize handle no
    -- matter how the window is resized.
    local BRACKET_INSET = 18
    local BRACKET_LEG = 14
    local BRACKET_THICKNESS = 1.5
    self._bracketBars = {}

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.Size = UDim2.new(0, self._cardWidth, 0, self._cardHeight)
    mainFrame.BackgroundColor3 = Theme.Plum800
    -- Fully opaque, not a hint of transparency: at 0.02 this let bright
    -- backgrounds (a sunny sky, a lit-up room) bleed through, and every
    -- semi-transparent row card stacked on top of it compounded that into
    -- a visibly washed-out look over content specifically - rows have
    -- their own translucency, sidebar labels don't, so content read as
    -- "foggier" than the sidebar even though nothing was actually wrong
    -- with either one individually. A solid backing card means every row's
    -- own transparency only ever blends against Plum800, never
    -- whatever's rendering behind the window.
    mainFrame.BackgroundTransparency = 0
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.ZIndex = 2
    mainFrame.Parent = wrapper
    self.MainFrame = mainFrame

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = Radius.XL
    mainCorner.Parent = mainFrame
    self._mainCorner = mainCorner

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255, 255, 255)
    mainStroke.Transparency = 0.55
    mainStroke.Thickness = 1.2
    mainStroke.Parent = mainFrame

    -- Full-window drag surface: a transparent TextButton covering the entire
    -- mainFrame at ZIndex 1. Interactive elements (buttons, toggles, sliders)
    -- sit at ZIndex 2+ and capture input first, so clicking them doesn't
    -- start a drag. Clicking empty space hits this surface instead.
    local dragSurface = Instance.new("TextButton")
    dragSurface.Name = "DragSurface"
    dragSurface.Size = UDim2.new(1, 0, 1, 0)
    dragSurface.BackgroundColor3 = Color3.new(0, 0, 0)
    dragSurface.BackgroundTransparency = 1
    dragSurface.Text = ""
    dragSurface.AutoButtonColor = false
    dragSurface.ZIndex = 1
    dragSurface.Parent = mainFrame

    -- ---------------- Title bar ----------------

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Active = true
    titleBar.BackgroundTransparency = 1
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.Size = UDim2.new(1, 0, 0, TITLEBAR_HEIGHT)
    titleBar.ZIndex = 3
    titleBar.Parent = mainFrame
    self.TitleBar = titleBar

    -- Brand wordmark, small scale, sits to the left of the title text.
    local titleMarkHolder = Instance.new("Frame")
    titleMarkHolder.Name = "TitleMark"
    titleMarkHolder.AnchorPoint = Vector2.new(0, 0.5)
    titleMarkHolder.Position = UDim2.new(0, 18, 0.5, 0)
    titleMarkHolder.BackgroundTransparency = 1
    titleMarkHolder.ZIndex = 3
    titleMarkHolder.Parent = titleBar
    local titleMarkWidth, titleMarkHeight = buildIvoryWordmark(titleMarkHolder, Theme.TextPrimary, 0.75)
    titleMarkHolder.Size = UDim2.fromOffset(titleMarkWidth, titleMarkHeight)

    -- Live card-size readout: the exact current window size in px, kept
    -- up to date by applyCardSize while the resize handle is dragged.
    local sizeLabel = Instance.new("TextLabel")
    sizeLabel.Name = "SizeReadout"
    sizeLabel.BackgroundTransparency = 1
    sizeLabel.AnchorPoint = Vector2.new(1, 0.5)
    sizeLabel.Position = UDim2.new(1, -84, 0.5, 0)
    sizeLabel.Size = UDim2.fromOffset(76, 20)
    sizeLabel.Font = Font.Medium
    sizeLabel.TextSize = TextSizes.SM
    sizeLabel.TextColor3 = Theme.TextSecondary
    sizeLabel.TextXAlignment = Enum.TextXAlignment.Right
    sizeLabel.Text = string.format("%d x %d",
        math.floor(self._cardWidth or DEFAULT_WINDOW_WIDTH),
        math.floor(self._cardHeight or DEFAULT_WINDOW_HEIGHT))
    sizeLabel.ZIndex = 3
    sizeLabel.Parent = titleBar

    local closeButton = makeTitleBarButton(titleBar, -14)
    makeCrossBar(closeButton, 45)
    makeCrossBar(closeButton, -45)

    local minimizeButton = makeTitleBarButton(titleBar, -48)
    local minimizeBar = Instance.new("Frame")
    minimizeBar.Name = "Bar"
    minimizeBar.AnchorPoint = Vector2.new(0.5, 0.5)
    minimizeBar.Position = UDim2.new(0.5, 0, 0.5, 0)
    minimizeBar.Size = UDim2.new(0, 11, 0, 1.5)
    minimizeBar.BackgroundColor3 = Theme.TextPrimary
    minimizeBar.BorderSizePixel = 0
    minimizeBar.ZIndex = 6
    minimizeBar.Parent = minimizeButton
    local minimizeBarCorner = Instance.new("UICorner")
    minimizeBarCorner.CornerRadius = Radius.Pill
    minimizeBarCorner.Parent = minimizeBar

    closeButton.MouseButton1Click:Connect(function()
        Library:AnimateClose(wrapper, uiScale, mainCorner, function()
            self:Destroy()
        end)
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)

    -- Title bar dragging (moves the Wrapper, which is anchored/centered so
    -- the card and its shadow move together as one unit).
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    -- Below this distance, a press-and-release on the title bar counts as a
    -- click rather than a drag. While minimized, a click anywhere on the
    -- pill (the title bar fills it entirely) restores the window - the pill
    -- itself is the "unminimize" control, no separate button needed.
    local CLICK_DRAG_THRESHOLD = 4

    table.insert(self._connections, titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = wrapper.Position
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then
                        changedConn:Disconnect()
                    end
                    if self._minimized and (input.Position - dragStart).Magnitude < CLICK_DRAG_THRESHOLD then
                        self:ToggleMinimize()
                    end
                end
            end)
        end
    end))

    table.insert(self._connections, titleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(self._connections, dragSurface.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = wrapper.Position
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then
                        changedConn:Disconnect()
                    end
                end
            end)
        end
    end))

    table.insert(self._connections, dragSurface.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            wrapper.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end))

    -- References ToggleMinimize needs (it's a separate method, so anything
    -- it touches has to live on self, not just as a closure-local here).
    self._titleMarkHolder = titleMarkHolder
    self._sizeLabel = sizeLabel
    self._minimizeButton = minimizeButton
    self._closeButton = closeButton
    self._titleBarRestSize = titleBar.Size

    -- Minimized pill content: wordmark + live FPS/ping, laid out exactly
    -- like the standalone watermark so collapsing the window reads as
    -- "becomes a watermark," not an unrelated shape. Shown only while
    -- minimized, centered in the shrunk mainFrame.
    local cubeMarkHolder = Instance.new("Frame")
    cubeMarkHolder.Name = "MinimizedPill"
    cubeMarkHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    cubeMarkHolder.Position = UDim2.fromScale(0.5, 0.5)
    cubeMarkHolder.Size = UDim2.new(1, -20, 1, 0)
    cubeMarkHolder.BackgroundTransparency = 1
    cubeMarkHolder.Visible = false
    cubeMarkHolder.ZIndex = 3
    cubeMarkHolder.Parent = nil
    self._cubeMarkHolder = cubeMarkHolder

    local cubeLayout = Instance.new("UIListLayout")
    cubeLayout.FillDirection = Enum.FillDirection.Horizontal
    cubeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    cubeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    cubeLayout.Padding = UDim.new(0, 10)
    cubeLayout.SortOrder = Enum.SortOrder.LayoutOrder
    cubeLayout.Parent = cubeMarkHolder

    local cubeMarkInner = Instance.new("Frame")
    cubeMarkInner.LayoutOrder = 1
    cubeMarkInner.BackgroundTransparency = 1
    cubeMarkInner.ZIndex = 3
    cubeMarkInner.Parent = cubeMarkHolder
    local cubeMarkWidth, cubeMarkHeight = buildIvoryWordmark(cubeMarkInner, Theme.TextPrimary, 0.45)
    cubeMarkInner.Size = UDim2.fromOffset(cubeMarkWidth, cubeMarkHeight)

    local cubeDivider = Instance.new("Frame")
    cubeDivider.LayoutOrder = 2
    cubeDivider.Size = UDim2.new(0, 1, 0, 14)
    cubeDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cubeDivider.BackgroundTransparency = 0.75
    cubeDivider.BorderSizePixel = 0
    cubeDivider.ZIndex = 3
    cubeDivider.Parent = cubeMarkHolder

    local cubeStatsLabel = Instance.new("TextLabel")
    cubeStatsLabel.LayoutOrder = 3
    cubeStatsLabel.BackgroundTransparency = 1
    cubeStatsLabel.Size = UDim2.fromOffset(0, 20)
    cubeStatsLabel.AutomaticSize = Enum.AutomaticSize.X
    cubeStatsLabel.Font = Font.Body
    cubeStatsLabel.TextSize = TextSizes.SM
    cubeStatsLabel.TextColor3 = Theme.TextSecondary
    cubeStatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    cubeStatsLabel.Text = ""
    cubeStatsLabel.ZIndex = 3
    cubeStatsLabel.Parent = cubeMarkHolder

    task.spawn(function()
        while self.ScreenGui and self.ScreenGui.Parent do
            if Library.GetFPS then
                local parts = { tostring(Library.GetFPS()) .. " FPS" }
                local ping = Library.GetPing and Library.GetPing()
                if ping then
                    table.insert(parts, tostring(ping) .. "ms")
                end
                cubeStatsLabel.Text = table.concat(parts, "  |  ")
            end
            task.wait(0.5)
        end
    end)

    -- ---------------- Sidebar ----------------

    -- ScrollingFrame, not a plain Frame: with enough tabs the list overflows
    -- the sidebar's fixed height, and a plain Frame just clips the overflow
    -- with no way to reach it short of resizing the whole window.
    local sidebar = Instance.new("ScrollingFrame")
    sidebar.Name = "Sidebar"
    sidebar.BackgroundTransparency = 1
    sidebar.BorderSizePixel = 0
    sidebar.Position = UDim2.new(0, 0, 0, TITLEBAR_HEIGHT)
    sidebar.Size = UDim2.new(0, SIDEBAR_WIDTH, 1, -(TITLEBAR_HEIGHT + PROFILE_CARD_HEIGHT))
    sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    sidebar.ScrollBarThickness = 3
    sidebar.ScrollBarImageColor3 = Theme.Blossom
    sidebar.ScrollBarImageTransparency = 0.4
    sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
    sidebar.ZIndex = 2
    sidebar.Parent = mainFrame
    self.Sidebar = sidebar
    self._sidebarWidth = SIDEBAR_WIDTH
    self._sidebarCollapsed = false

    local sidebarPadding = Instance.new("UIPadding")
    sidebarPadding.PaddingTop = UDim.new(0, 8)
    sidebarPadding.PaddingLeft = UDim.new(0, 8)
    sidebarPadding.PaddingRight = UDim.new(0, 8)
    sidebarPadding.PaddingBottom = UDim.new(0, 8)
    sidebarPadding.Parent = sidebar

    -- Parented to mainFrame (not sidebar) so it sits outside the sidebar's
    -- UIListLayout - a GuiObject child of sidebar would otherwise be swept
    -- into the tab list flow (and, sized full-height, would push every tab
    -- button below the visible area).
    local sidebarDivider = Instance.new("Frame")
    sidebarDivider.Name = "SidebarDivider"
    sidebarDivider.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, TITLEBAR_HEIGHT)
    sidebarDivider.Size = UDim2.new(0, 1, 1, -TITLEBAR_HEIGHT)
    sidebarDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sidebarDivider.BackgroundTransparency = 0.92
    sidebarDivider.BorderSizePixel = 0
    sidebarDivider.ZIndex = 3
    sidebarDivider.Parent = mainFrame
    self._sidebarDivider = sidebarDivider

    local sidebarList = Instance.new("UIListLayout")
    sidebarList.FillDirection = Enum.FillDirection.Vertical
    sidebarList.Padding = UDim.new(0, 6)
    sidebarList.SortOrder = Enum.SortOrder.LayoutOrder
    sidebarList.Parent = sidebar

    sidebarList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sidebar.CanvasSize = UDim2.new(0, 0, 0, sidebarList.AbsoluteContentSize.Y + 16)
    end)

    -- ---------------- Content area ----------------

    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundTransparency = 1
    contentArea.Position = UDim2.new(0, SIDEBAR_WIDTH, 0, TITLEBAR_HEIGHT)
    contentArea.Size = UDim2.new(1, -SIDEBAR_WIDTH, 1, -TITLEBAR_HEIGHT)
    contentArea.ZIndex = 2
    contentArea.Parent = mainFrame
    self.ContentArea = contentArea

    local contentPadding = Instance.new("UIPadding")
    contentPadding.PaddingLeft = UDim.new(0, 14)
    contentPadding.PaddingRight = UDim.new(0, 10)
    contentPadding.PaddingTop = UDim.new(0, 10)
    contentPadding.PaddingBottom = UDim.new(0, 10)
    contentPadding.Parent = contentArea

    -- ---------------- Bottom profile card ----------------
    -- Avatar circle over the player name and a live stats line, pinned to
    -- the sidebar bottom edge: subscription text when the script sets
    -- Library.SubscriptionText, otherwise ping/fps. Collapsed sidebars
    -- keep only the avatar.

    local profileCard = Instance.new("Frame")
    profileCard.Name = "ProfileCard"
    profileCard.BackgroundTransparency = 1
    profileCard.AnchorPoint = Vector2.new(0, 1)
    profileCard.Position = UDim2.new(0, 8, 1, -6)
    profileCard.Size = UDim2.new(0, SIDEBAR_WIDTH - 16, 0, PROFILE_CARD_HEIGHT)
    profileCard.ZIndex = 5
    profileCard.Parent = mainFrame
    self._profileCard = profileCard

    local avatar = Instance.new("ImageLabel")
    avatar.Name = "Avatar"
    avatar.AnchorPoint = Vector2.new(0.5, 0)
    avatar.Position = UDim2.new(0.5, 0, 0, 0)
    avatar.Size = UDim2.new(0, 44, 0, 44)
    avatar.BackgroundColor3 = Theme.Plum700
    avatar.BackgroundTransparency = 0
    avatar.BorderSizePixel = 0
    avatar.ScaleType = Enum.ScaleType.Crop
    avatar.Image = Library.ProfileLogo or ""
    avatar.ZIndex = 6
    avatar.Parent = profileCard
    self._profileAvatar = avatar

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = Radius.Pill
    avatarCorner.Parent = avatar

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Thickness = 1
    avatarStroke.Color = Color3.fromRGB(255, 255, 255)
    avatarStroke.Transparency = 0.75
    avatarStroke.Parent = avatar

    local nameTag = Instance.new("TextLabel")
    nameTag.Name = "ProfileName"
    nameTag.BackgroundTransparency = 1
    nameTag.Position = UDim2.new(0, 0, 0, 50)
    nameTag.Size = UDim2.new(1, 0, 0, 14)
    nameTag.Font = Font.Bold
    nameTag.TextSize = TextSizes.SM
    nameTag.TextColor3 = Theme.TextPrimary
    nameTag.TextXAlignment = Enum.TextXAlignment.Center
    nameTag.TextTruncate = Enum.TextTruncate.AtEnd
    nameTag.Text = ""
    nameTag.ZIndex = 6
    nameTag.Parent = profileCard
    self._profileName = nameTag

    local statsTag = Instance.new("TextLabel")
    statsTag.Name = "ProfileStats"
    statsTag.BackgroundTransparency = 1
    statsTag.Position = UDim2.new(0, 0, 0, 66)
    statsTag.Size = UDim2.new(1, 0, 0, 14)
    statsTag.Font = Font.Body
    statsTag.TextSize = TextSizes.SM
    statsTag.TextColor3 = Theme.TextTertiary
    statsTag.TextXAlignment = Enum.TextXAlignment.Center
    statsTag.TextTruncate = Enum.TextTruncate.AtEnd
    statsTag.Text = ""
    statsTag.ZIndex = 6
    statsTag.Parent = profileCard
    self._profileStats = statsTag

    task.spawn(function()
        local player = Players.LocalPlayer
        while self.ScreenGui and self.ScreenGui.Parent and not Library.Unloaded do
            if player then
                nameTag.Text = (player.DisplayName ~= "" and player.DisplayName) or player.Name
            end
            local sub = Library.SubscriptionText
            if sub and sub ~= "" then
                statsTag.Text = tostring(sub)
            else
                local parts = {}
                local ping = Library.GetPing and Library.GetPing()
                if ping then
                    table.insert(parts, tostring(ping) .. "ms")
                end
                local fps = Library.GetFPS and Library.GetFPS()
                if fps then
                    table.insert(parts, tostring(fps) .. " fps")
                end
                statsTag.Text = table.concat(parts, " | ")
            end
            task.wait(0.5)
        end
    end)

    -- ---------------- Sidebar drag handle ----------------
    -- Invisible strip over the sidebar right edge; dragging it resizes
    -- the sidebar live and collapses tabs to icons below the threshold.

    local sidebarHandle = Instance.new("TextButton")
    sidebarHandle.Name = "SidebarDragHandle"
    sidebarHandle.AutoButtonColor = false
    sidebarHandle.Text = ""
    sidebarHandle.BackgroundTransparency = 1
    sidebarHandle.Position = UDim2.new(0, SIDEBAR_WIDTH - 4, 0, TITLEBAR_HEIGHT)
    sidebarHandle.Size = UDim2.new(0, 8, 1, -(TITLEBAR_HEIGHT + PROFILE_CARD_HEIGHT))
    sidebarHandle.ZIndex = 6
    sidebarHandle.Parent = mainFrame
    self.SidebarDragHandle = sidebarHandle

    local sidebarDragging = false
    local sidebarDragStart
    local sidebarStartWidth

    table.insert(self._connections, sidebarHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sidebarDragging = true
            sidebarDragStart = input.Position
            sidebarStartWidth = self._sidebarWidth or SIDEBAR_WIDTH
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    sidebarDragging = false
                    if changedConn then
                        changedConn:Disconnect()
                    end
                end
            end)
        end
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if sidebarDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - sidebarDragStart
            self:SetSidebarWidth(sidebarStartWidth + delta.X)
        end
    end))

    -- ---------------- Resize handle ----------------

    local resizeHandle = Instance.new("TextButton")
    resizeHandle.Name = "ResizeHandle"
    resizeHandle.AutoButtonColor = false
    resizeHandle.Text = ""
    resizeHandle.BackgroundTransparency = 1
    resizeHandle.AnchorPoint = Vector2.new(1, 1)
    resizeHandle.Position = UDim2.new(1, -4, 1, -4)
    resizeHandle.Size = UDim2.new(0, 16, 0, 16)
    resizeHandle.ZIndex = 5
    resizeHandle.Parent = mainFrame
    self.ResizeHandle = resizeHandle

    for i = 1, 3 do
        local grip = Instance.new("Frame")
        grip.Name = "Grip" .. i
        grip.AnchorPoint = Vector2.new(0.5, 0.5)
        grip.Size = UDim2.new(0, 8 - (i - 1) * 2, 0, 1.5)
        grip.Position = UDim2.new(1, -3 - (i - 1) * 4, 1, -3 - (i - 1) * 4)
        grip.Rotation = -45
        grip.BackgroundColor3 = Theme.TextTertiary
        grip.BackgroundTransparency = 0.3
        grip.BorderSizePixel = 0
        grip.ZIndex = 6
        grip.Parent = resizeHandle

        local gripCorner = Instance.new("UICorner")
        gripCorner.CornerRadius = Radius.Pill
        gripCorner.Parent = grip
    end

    local resizing = false
    local resizeStart
    local startWidth
    local startHeight

    table.insert(self._connections, resizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            resizeStart = input.Position
            startWidth = self._cardWidth
            startHeight = self._cardHeight
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
                    if changedConn then
                        changedConn:Disconnect()
                    end
                end
            end)
        end
    end))

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - resizeStart
            applyCardSize(self, startWidth + delta.X, startHeight + delta.Y)
        end
    end))

    -- ---------------- Optional loading splash ----------------

    if config.LoadingTitle or config.LoadingSubtitle then
        local loadingOverlay = Instance.new("Frame")
        loadingOverlay.Name = "LoadingOverlay"
        loadingOverlay.BackgroundColor3 = Theme.Plum800
        loadingOverlay.BackgroundTransparency = 0
        loadingOverlay.Size = UDim2.new(1, 0, 1, 0)
        loadingOverlay.ZIndex = 50
        loadingOverlay.Parent = mainFrame

        local loadingCorner = Instance.new("UICorner")
        loadingCorner.CornerRadius = Radius.XL
        loadingCorner.Parent = loadingOverlay

        local loadingTitleLabel = Instance.new("TextLabel")
        loadingTitleLabel.BackgroundTransparency = 1
        loadingTitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        loadingTitleLabel.Position = UDim2.new(0.5, 0, 0.5, -10)
        loadingTitleLabel.Size = UDim2.new(0.8, 0, 0, 24)
        loadingTitleLabel.Font = Font.Bold
        loadingTitleLabel.TextSize = TextSizes.Title
        loadingTitleLabel.TextColor3 = Theme.TextPrimary
        loadingTitleLabel.Text = config.LoadingTitle or windowName
        loadingTitleLabel.ZIndex = 51
        loadingTitleLabel.Parent = loadingOverlay

        local loadingSubtitleLabel = Instance.new("TextLabel")
        loadingSubtitleLabel.BackgroundTransparency = 1
        loadingSubtitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        loadingSubtitleLabel.Position = UDim2.new(0.5, 0, 0.5, 16)
        loadingSubtitleLabel.Size = UDim2.new(0.8, 0, 0, 18)
        loadingSubtitleLabel.Font = Font.Body
        loadingSubtitleLabel.TextSize = TextSizes.MD
        loadingSubtitleLabel.TextColor3 = Theme.TextSecondary
        loadingSubtitleLabel.Text = config.LoadingSubtitle or ""
        loadingSubtitleLabel.ZIndex = 51
        loadingSubtitleLabel.Parent = loadingOverlay

        task.spawn(function()
            task.wait(0.9)
            if loadingOverlay and loadingOverlay.Parent then
                tw(loadingOverlay, EASE_OUT_SOFT, {BackgroundTransparency = 1})
                tw(loadingTitleLabel, EASE_OUT_SOFT, {TextTransparency = 1})
                tw(loadingSubtitleLabel, EASE_OUT_SOFT, {TextTransparency = 1})
                task.wait(0.3)
                if loadingOverlay then
                    loadingOverlay:Destroy()
                end
            end
        end)
    end





    -- ---------------- Floating particles ----------------

    -- ---------------- Background blur ----------------
    Library._BlurFrame = Library:AddBackgroundBlur(screenGui, 0)

    -- ---------------- Entrance animation ----------------
    Library:AnimateOpen(wrapper, uiScale, mainCorner)

    -- Menu toggle is bound in ONE place only: Library._MenuKeybind
    -- (default RightShift, configurable from Settings). This window used
    -- to bind RightShift a second time here as well, so every press ran
    -- BOTH handlers and the UI toggled twice.

    -- ---------------- Floating mobile buttons (outside the UI) ----------------
    local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if isMobile then
        local mobileScreen = Instance.new("ScreenGui")
        mobileScreen.Name = "IvoryMobileButtons"
        mobileScreen.ResetOnSpawn = false
        mobileScreen.DisplayOrder = 10000
        mobileScreen.IgnoreGuiInset = true
        mobileScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local mPg = Players.LocalPlayer and Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if mPg then
            mobileScreen.Parent = mPg
        else
            pcall(function() mobileScreen.Parent = game:GetService("CoreGui") end)
        end

        local BUTTON_SIZE = 44
        local BUTTON_GAP = 10
        local SIDE_PAD = 14
        local BOTTOM_PAD = 60

        local container = Instance.new("Frame")
        container.Name = "MobileControls"
        container.AnchorPoint = Vector2.new(1, 1)
        container.Position = UDim2.new(1, -SIDE_PAD, 1, -BOTTOM_PAD)
        container.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE * 2 + BUTTON_GAP)
        container.BackgroundTransparency = 1
        container.Parent = mobileScreen

        local function makeMobileBtn(parent, name, iconText, order)
            local btn = Instance.new("TextButton")
            btn.Name = name
            btn.AnchorPoint = Vector2.new(0.5, 0.5)
            btn.Position = UDim2.new(0.5, 0, 0, BUTTON_SIZE / 2 + (order - 1) * (BUTTON_SIZE + BUTTON_GAP))
            btn.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
            btn.BackgroundColor3 = Theme.Plum800
            btn.BackgroundTransparency = 0.15
            btn.BorderSizePixel = 0
            btn.Text = iconText
            btn.TextColor3 = Theme.TextPrimary
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 18
            btn.ZIndex = 100
            btn.Parent = parent

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(1, 0)
            corner.Parent = btn

            local stroke = Instance.new("UIStroke")
            stroke.Color = Theme.Blossom
            stroke.Thickness = 1.5
            stroke.Transparency = 0.5
            stroke.Parent = btn

            return btn
        end

        -- Button 1: Toggle UI visibility
        local toggleBtn = makeMobileBtn(container, "ToggleUI", "UI", 1)
        toggleBtn.MouseButton1Click:Connect(function()
            Library:Toggle()
            if Library.Toggled then
                toggleBtn.Text = "UI"
                toggleBtn.BackgroundColor3 = Theme.Plum800
            else
                toggleBtn.Text = ">>"
                toggleBtn.BackgroundColor3 = Theme.Blossom
            end
        end)

        -- Button 2: Re-center window
        local centerBtn = makeMobileBtn(container, "Center", "+", 2)
        centerBtn.TextSize = 22
        centerBtn.MouseButton1Click:Connect(function()
            if self.Wrapper then
                tw(self.Wrapper, EASE_SPRING, {
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                })
            end
            if self.Aura then
                tw(self.Aura, EASE_QUICK, {Position = UDim2.new(0.5, 0, 0.5, 0)})
            end
            for _, blob in ipairs(self._glowBlobs or {}) do
                blob.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
        end)

        -- Show/hide mobile buttons with the main UI
        self._mobileScreen = mobileScreen
    end

    return self
end

-- ===================== ObsidianUltra compat methods =====================

function Library:Create(className, props)
    local inst = Instance.new(className)
    props = props or {}
    for k, v in pairs(props) do
        if k ~= "Parent" and k ~= "Name" then
            pcall(function() inst[k] = v end)
        end
    end
    if props.Name then inst.Name = props.Name end
    if props.Parent then inst.Parent = props.Parent end
    return inst
end

Library._registry = {}

function Library:AddToRegistry(instance, props)
    table.insert(Library._registry, {Instance = instance, Props = props or {}})
end

function Library:UpdateDependencyBoxes()
    -- stub; dependency boxes self-update via SetupDependencies
end

function Library:CreateLabel(config)
    config = config or {}
    local text = config.Text or config.Name or config.Title or config.Content or ""
    local parent = config.Parent or Library.ScreenGui
    local label = Instance.new("TextLabel")
    label.Name = config.Name or "Label"
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = text
    label.Parent = parent
    return label
end

Library._unloadCallbacks = {}

function Library:OnUnload(callback)
    table.insert(Library._unloadCallbacks, callback)
end

function Library:Unload()
    -- Flag first: the fps/autosave/noclip while-loops all gate on this,
    -- so they stop on this exact call instead of running forever.
    Library.Unloaded = true
    for _, cb in ipairs(Library._unloadCallbacks) do
        pcall(cb)
    end
    if Library.ScreenGui then
        Library.ScreenGui:Destroy()
        Library.ScreenGui = nil
    end
    -- Also remove this run's HUD overlays (notifications, watermark,
    -- active-features panel, mobile buttons) so a re-execution starts
    -- from a clean screen instead of stacking a second set.
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, guiName in ipairs({ "LootNotifyHolder", "LootUIWatermark", "LootUIActiveFeatures", "IvoryMobileButtons" }) do
            local gui = playerGui:FindFirstChild(guiName)
            if gui then
                gui:Destroy()
            end
        end
    end
end

Library.Destroy = Library.Unload

Library.Toggled = true

function Library:Toggle()
    Library.Toggled = not Library.Toggled
    local gui = Library.ScreenGui
    if not gui then
        return
    end

    -- Resolve the shell pieces the animation functions expect so a
    -- RightShift press plays the same animated entrance/exit the window
    -- gets on creation - this is what makes Animation Style/Speed
    -- observable: previously Toggle just flipped ScreenGui.Enabled, so
    -- the menu popped in/out instantly and the animation settings only
    -- ran once at startup.
    local wrapper = gui:FindFirstChild("WindowWrapper")
    local uiScale = wrapper and wrapper:FindFirstChildOfClass("UIScale")
    local mainFrame = wrapper and wrapper:FindFirstChild("MainFrame")
    local mainCorner = mainFrame and mainFrame:FindFirstChildOfClass("UICorner")

    if not (wrapper and uiScale) then
        gui.Enabled = Library.Toggled
        return
    end

    if Library.Toggled then
        gui.Enabled = true
        pcall(function()
            Library:AnimateOpen(wrapper, uiScale, mainCorner)
        end)
    else
        pcall(function()
            Library:AnimateClose(wrapper, uiScale, mainCorner, function()
                -- Still closed by the time the tween finished? Hide it.
                -- (If the menu keybind was pressed again mid-animation,
                -- AnimateOpen already took the properties back over.)
                if not Library.Toggled then
                    gui.Enabled = false
                end
            end)
        end)
    end
end

function Library:SetDPIScale(scale)
end

function Library:SetNotifySide(side)
end

function Library:SetAccent(color)
    if Library.SetAccentColor then
        Library.SetAccentColor(color)
    end
end

-- ============================================================
-- IVORY HUB - FULL FEATURE SET
-- Theme presets, animation, gradient accent, particles, blur,
-- status bar, settings, config, etc.
-- ============================================================

-- ============================================================
-- THEME PRESETS
-- ============================================================
Library.ThemePresets = {
    Zero = {
        Plum900 = Color3.fromRGB(18, 18, 22),
        Plum800 = Color3.fromRGB(24, 24, 30),
        Plum700 = Color3.fromRGB(32, 32, 40),
        Plum600 = Color3.fromRGB(42, 42, 52),
        Blossom = Color3.fromRGB(120, 120, 140),
        BlossomLight = Color3.fromRGB(180, 180, 200),
        Mauve = Color3.fromRGB(80, 80, 95),
        Petal = Color3.fromRGB(200, 200, 215),
        TextPrimary = Color3.fromRGB(240, 240, 245),
        TextSecondary = Color3.fromRGB(160, 160, 170),
        TextTertiary = Color3.fromRGB(100, 100, 110),
        Success = Color3.fromRGB(140, 200, 150),
        Error = Color3.fromRGB(220, 90, 95),
        Warning = Color3.fromRGB(230, 180, 110),
    },
    Sakura = {
        Plum900 = Color3.fromRGB(16, 9, 13),
        Plum800 = Color3.fromRGB(30, 17, 23),
        Plum700 = Color3.fromRGB(46, 25, 33),
        Plum600 = Color3.fromRGB(64, 36, 46),
        Blossom = Color3.fromRGB(247, 36, 130),
        BlossomLight = Color3.fromRGB(255, 200, 217),
        Mauve = Color3.fromRGB(120, 88, 100),
        Petal = Color3.fromRGB(255, 226, 233),
        TextPrimary = Color3.fromRGB(252, 240, 244),
        TextSecondary = Color3.fromRGB(198, 168, 178),
        TextTertiary = Color3.fromRGB(140, 112, 122),
        Success = Color3.fromRGB(150, 214, 168),
        Error = Color3.fromRGB(226, 84, 96),
        Warning = Color3.fromRGB(240, 188, 122),
    },
    Ocean = {
        Plum900 = Color3.fromRGB(8, 14, 24),
        Plum800 = Color3.fromRGB(14, 24, 40),
        Plum700 = Color3.fromRGB(22, 36, 58),
        Plum600 = Color3.fromRGB(32, 50, 78),
        Blossom = Color3.fromRGB(40, 140, 230),
        BlossomLight = Color3.fromRGB(120, 200, 255),
        Mauve = Color3.fromRGB(60, 90, 130),
        Petal = Color3.fromRGB(160, 210, 250),
        TextPrimary = Color3.fromRGB(230, 240, 252),
        TextSecondary = Color3.fromRGB(150, 175, 210),
        TextTertiary = Color3.fromRGB(90, 115, 155),
        Success = Color3.fromRGB(110, 210, 170),
        Error = Color3.fromRGB(240, 90, 110),
        Warning = Color3.fromRGB(250, 190, 100),
    },
    Forest = {
        Plum900 = Color3.fromRGB(10, 16, 10),
        Plum800 = Color3.fromRGB(18, 28, 18),
        Plum700 = Color3.fromRGB(28, 42, 28),
        Plum600 = Color3.fromRGB(40, 58, 40),
        Blossom = Color3.fromRGB(60, 180, 80),
        BlossomLight = Color3.fromRGB(140, 225, 150),
        Mauve = Color3.fromRGB(60, 100, 65),
        Petal = Color3.fromRGB(170, 230, 175),
        TextPrimary = Color3.fromRGB(230, 245, 230),
        TextSecondary = Color3.fromRGB(150, 185, 155),
        TextTertiary = Color3.fromRGB(90, 125, 95),
        Success = Color3.fromRGB(110, 220, 120),
        Error = Color3.fromRGB(220, 90, 80),
        Warning = Color3.fromRGB(240, 200, 110),
    },
    Sunset = {
        Plum900 = Color3.fromRGB(20, 10, 8),
        Plum800 = Color3.fromRGB(36, 18, 14),
        Plum700 = Color3.fromRGB(54, 28, 20),
        Plum600 = Color3.fromRGB(74, 40, 28),
        Blossom = Color3.fromRGB(255, 120, 40),
        BlossomLight = Color3.fromRGB(255, 190, 120),
        Mauve = Color3.fromRGB(150, 80, 55),
        Petal = Color3.fromRGB(255, 215, 180),
        TextPrimary = Color3.fromRGB(252, 242, 235),
        TextSecondary = Color3.fromRGB(200, 160, 140),
        TextTertiary = Color3.fromRGB(140, 100, 85),
        Success = Color3.fromRGB(170, 215, 130),
        Error = Color3.fromRGB(240, 80, 70),
        Warning = Color3.fromRGB(255, 170, 80),
    },
    Purple = {
        Plum900 = Color3.fromRGB(12, 8, 20),
        Plum800 = Color3.fromRGB(22, 14, 36),
        Plum700 = Color3.fromRGB(34, 22, 54),
        Plum600 = Color3.fromRGB(48, 32, 74),
        Blossom = Color3.fromRGB(140, 80, 240),
        BlossomLight = Color3.fromRGB(200, 160, 255),
        Mauve = Color3.fromRGB(90, 60, 140),
        Petal = Color3.fromRGB(215, 190, 255),
        TextPrimary = Color3.fromRGB(242, 235, 252),
        TextSecondary = Color3.fromRGB(175, 155, 210),
        TextTertiary = Color3.fromRGB(115, 95, 155),
        Success = Color3.fromRGB(140, 220, 170),
        Error = Color3.fromRGB(235, 90, 140),
        Warning = Color3.fromRGB(245, 195, 120),
    },
    Midnight = {
        Plum900 = Color3.fromRGB(6, 6, 12),
        Plum800 = Color3.fromRGB(12, 12, 22),
        Plum700 = Color3.fromRGB(20, 20, 34),
        Plum600 = Color3.fromRGB(30, 30, 48),
        Blossom = Color3.fromRGB(100, 100, 220),
        BlossomLight = Color3.fromRGB(160, 160, 250),
        Mauve = Color3.fromRGB(60, 60, 120),
        Petal = Color3.fromRGB(180, 180, 240),
        TextPrimary = Color3.fromRGB(220, 220, 245),
        TextSecondary = Color3.fromRGB(140, 140, 175),
        TextTertiary = Color3.fromRGB(85, 85, 120),
        Success = Color3.fromRGB(130, 200, 180),
        Error = Color3.fromRGB(230, 85, 105),
        Warning = Color3.fromRGB(235, 185, 120),
    },
    Rose = {
        Plum900 = Color3.fromRGB(18, 8, 12),
        Plum800 = Color3.fromRGB(32, 14, 22),
        Plum700 = Color3.fromRGB(48, 22, 34),
        Plum600 = Color3.fromRGB(66, 32, 48),
        Blossom = Color3.fromRGB(220, 60, 100),
        BlossomLight = Color3.fromRGB(255, 150, 175),
        Mauve = Color3.fromRGB(130, 65, 85),
        Petal = Color3.fromRGB(255, 200, 215),
        TextPrimary = Color3.fromRGB(250, 238, 242),
        TextSecondary = Color3.fromRGB(195, 155, 170),
        TextTertiary = Color3.fromRGB(135, 95, 110),
        Success = Color3.fromRGB(160, 215, 165),
        Error = Color3.fromRGB(230, 75, 95),
        Warning = Color3.fromRGB(245, 190, 125),
    },
    Gold = {
        Plum900 = Color3.fromRGB(18, 14, 6),
        Plum800 = Color3.fromRGB(32, 24, 10),
        Plum700 = Color3.fromRGB(48, 36, 16),
        Plum600 = Color3.fromRGB(66, 50, 24),
        Blossom = Color3.fromRGB(240, 190, 40),
        BlossomLight = Color3.fromRGB(255, 225, 120),
        Mauve = Color3.fromRGB(150, 115, 50),
        Petal = Color3.fromRGB(255, 235, 170),
        TextPrimary = Color3.fromRGB(252, 248, 235),
        TextSecondary = Color3.fromRGB(200, 180, 140),
        TextTertiary = Color3.fromRGB(140, 120, 80),
        Success = Color3.fromRGB(180, 215, 140),
        Error = Color3.fromRGB(230, 100, 80),
        Warning = Color3.fromRGB(250, 200, 90),
    },
}

function Library:ApplyThemePreset(presetName)
    local preset = Library.ThemePresets[presetName]
    if not preset then return end

    -- Color3 CANNOT be used as a table key in Luau: lookup hashes by
    -- reference while Color3 == compares by value, so t[Color3.fromRGB(1,2,3)]
    -- built from two equal instances misses. That bug made every repaint
    -- no-op (only hover states, which read Theme live, appeared to change).
    -- Encode the color as a hex string key instead.
    local function colorKey(c)
        return string.format(
            "%02x%02x%02x",
            math.floor(c.R * 255 + 0.5),
            math.floor(c.G * 255 + 0.5),
            math.floor(c.B * 255 + 0.5)
        )
    end

    -- Reverse map: any Color3 this library has ever painted -> its token.
    -- Seeded from the live Theme first (so the current palette wins any
    -- collision), then every preset, so an element painted by an earlier
    -- theme still resolves to the right token when a later theme applies.
    local reverseMap = {}
    for tokenName, color in pairs(Theme) do
        if typeof(color) == "Color3" then
            reverseMap[colorKey(color)] = tokenName
        end
    end
    for _, otherPreset in pairs(Library.ThemePresets) do
        for tokenName, color in pairs(otherPreset) do
            if typeof(color) == "Color3" and reverseMap[colorKey(color)] == nil then
                reverseMap[colorKey(color)] = tokenName
            end
        end
    end

    -- Update Theme table with new preset values
    for k, v in pairs(preset) do
        Theme[k] = v
    end
    Library._AccentColor = preset.Blossom
    Library._CurrentThemePreset = presetName

    local function repaintToken(color)
        local tokenName = reverseMap[colorKey(color)]
        if tokenName and preset[tokenName] then
            return preset[tokenName]
        end
        return nil
    end

    -- Repaint every live screen: window, HUD overlays and notification
    -- stack alike - backgrounds, text, strokes, scrollbars and gradient
    -- keypoints all go through the reverse map, so the WHOLE UI changes,
    -- not just the parts that happen to be re-created later.
    local guis = {}
    if Library.ScreenGui then
        table.insert(guis, Library.ScreenGui)
    end
    local player = Players.LocalPlayer
    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
    if playerGui then
        for _, guiName in ipairs({ "LootNotifyHolder", "LootUIWatermark", "LootUIActiveFeatures", "IvoryMobileButtons" }) do
            local gui = playerGui:FindFirstChild(guiName)
            if gui then
                table.insert(guis, gui)
            end
        end
    end

    for _, gui in ipairs(guis) do
        for _, desc in ipairs(gui:GetDescendants()) do
            pcall(function()
                if desc:IsA("Frame") or desc:IsA("ScrollingFrame") or desc:IsA("CanvasGroup") or desc:IsA("TextButton") then
                    local newColor = repaintToken(desc.BackgroundColor3)
                    if newColor then
                        desc.BackgroundColor3 = newColor
                    end
                end
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local newColor = repaintToken(desc.TextColor3)
                    if newColor then
                        desc.TextColor3 = newColor
                    end
                end
                if desc:IsA("UIStroke") then
                    local newColor = repaintToken(desc.Color)
                    if newColor then
                        desc.Color = newColor
                    end
                end
                if desc:IsA("ScrollingFrame") then
                    local newColor = repaintToken(desc.ScrollBarImageColor3)
                    if newColor then
                        desc.ScrollBarImageColor3 = newColor
                    end
                end
                if desc:IsA("UIGradient") then
                    local seq = desc.Color
                    local keypoints = {}
                    local changed = false
                    for i, kp in ipairs(seq.Keypoints) do
                        local newColor = repaintToken(kp.Value)
                        if newColor then
                            changed = true
                            keypoints[i] = ColorSequenceKeypoint.new(kp.Time, newColor)
                        else
                            keypoints[i] = kp
                        end
                    end
                    if changed then
                        desc.Color = ColorSequence.new(keypoints)
                    end
                end
            end)
        end
    end

    -- Semantic notification colors follow the preset too
    NotifyTypeColors.Success = Theme.Success or NotifyTypeColors.Success
    NotifyTypeColors.Error = Theme.Error or NotifyTypeColors.Error
    NotifyTypeColors.Warning = Theme.Warning or NotifyTypeColors.Warning
    NotifyTypeColors.Info = Theme.Blossom

    if Library.SetAccentColor then
        Library.SetAccentColor(preset.Blossom)
    end

    if Library.Notify then
        pcall(function()
            Library.Notify({ Title = "Theme", Content = "Applied " .. presetName, Type = "Info", Duration = 2 })
        end)
    end
end

-- ============================================================
-- ANIMATION SPEED MULTIPLIER
-- ============================================================
Library.AnimationSpeed = 1

Library.AnimationStyle = "Ripple Soft"

Library.AnimationStyles = {
    Drop = { open = "DropBounce", close = "DropBounce" },
    Ripple = { open = "Ripple", close = "Ripple" },
    ["Ripple Soft"] = { open = "RippleSoft", close = "RippleSoft" },
}

function Library:AnimateOpen(wrapper, uiScale, mainCorner)
    -- Slider semantics: 0.1 = slowest, 5 = fastest. The raw value used to
    -- be multiplied into tween durations, which inverted the feel (0.1
    -- became the fastest), so invert it here: duration = base / value.
    local rawSpeed = Library.AnimationSpeed
    local speed = (type(rawSpeed) == "number" and rawSpeed > 0) and (1 / rawSpeed) or 1
    local style = Library.AnimationStyle

    -- Any new animation invalidates an in-flight Drop chain and takes the
    -- animated properties over cleanly (otherwise two tweens would fight
    -- over Position/Scale when the menu is re-opened mid-flight).
    Library._dropAnimGen = (Library._dropAnimGen or 0) + 1
    local myGen = Library._dropAnimGen
    cancelTweens(wrapper)
    cancelTweens(uiScale)

    -- A previous Drop-style close leaves wrapper off-screen (y = 1.2);
    -- every style must start from the on-screen anchor or the window
    -- fades back in somewhere nobody can see it.
    if style ~= "Drop" then
        wrapper.Position = UDim2.new(0.5, 0, 0.5, 0)
    end
    wrapper.Rotation = 0

    if style == "Ripple" then
        wrapper.GroupTransparency = 1
        uiScale.Scale = 0
        tw(wrapper, TweenInfo.new(0.5 * speed, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {GroupTransparency = 0})
        tw(uiScale, TweenInfo.new(0.5 * speed, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Scale = 1})
    elseif style == "Ripple Soft" then
        wrapper.GroupTransparency = 1
        uiScale.Scale = 0
        tw(wrapper, TweenInfo.new(0.5 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
        tw(uiScale, TweenInfo.new(0.5 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
    else
        -- Drop-Bounce (default): a full-screen drop sequence -
        --   1. falls in from above the top edge (gravity: slow, then fast),
        --   2. slams down to the bottom of the screen,
        --   3. rebounds to a high apex above the middle,
        --   4. falls back down under gravity and lands softly dead center.
        -- Scale stays constant through the fall and rebound (no random
        -- size pop mid-air); it only grows during the final descent so the
        -- growth reads as part of the landing, not a glitch.
        -- Position.Y.Scale: 0 = top edge, 0.5 = center, 1 = bottom edge
        -- (wrapper is anchored 0.5,0.5). Phases chain on Completed inside a
        -- spawned thread so CreateWindow and Library:Toggle never block on
        -- the animation, and each phase checks the generation token before
        -- continuing so a re-open/close mid-flight aborts the stale chain
        -- instead of yanking the window back.
        wrapper.GroupTransparency = 1
        uiScale.Scale = 0.6
        wrapper.Position = UDim2.new(0.5, 0, -0.55, 0)

        task.spawn(function()
            if Library._dropAnimGen ~= myGen then return end

            -- 1. Fall from the top of the screen to the bottom (Quad In =
            --    constant acceleration, like gravity).
            tw(wrapper, TweenInfo.new(0.25 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0})
            local fall = tw(wrapper, TweenInfo.new(0.42 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.85, 0)})
            fall.Completed:Wait()
            if Library._dropAnimGen ~= myGen then return end

            -- 2. Rebound: fast off the floor, decelerating to a high apex
            --    (velocity approaches 0 at the top, like a real bounce).
            local rise = tw(wrapper, TweenInfo.new(0.5 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.3, 0)})
            rise.Completed:Wait()
            if Library._dropAnimGen ~= myGen then return end

            -- 3. Fall back from the apex under gravity (slow start at the
            --    apex, accelerating), growing to full size as it drops...
            tw(uiScale, TweenInfo.new(0.28 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.92})
            local drop = tw(wrapper, TweenInfo.new(0.28 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0.44, 0)})
            drop.Completed:Wait()
            if Library._dropAnimGen ~= myGen then return end

            --    ...then a short soft landing that decelerates to rest
            --    (velocity matched at the seam so there is no visible kink).
            tw(uiScale, TweenInfo.new(0.12 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1})
            local land = tw(wrapper, TweenInfo.new(0.12 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0.5, 0)})
            land.Completed:Wait()
        end)
    end
end

function Library:AnimateClose(wrapper, uiScale, mainCorner, callback)
    -- Same inversion as AnimateOpen: low slider value = slow, high = fast.
    local rawSpeed = Library.AnimationSpeed
    local speed = (type(rawSpeed) == "number" and rawSpeed > 0) and (1 / rawSpeed) or 1
    local style = Library.AnimationStyle

    -- Abort any in-flight Drop open chain before this close starts
    -- tweening the same properties.
    Library._dropAnimGen = (Library._dropAnimGen or 0) + 1
    cancelTweens(wrapper)
    cancelTweens(uiScale)

    if style == "Ripple" then
        tw(wrapper, TweenInfo.new(0.3 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
        tw(uiScale, TweenInfo.new(0.3 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
        task.delay(0.35 * speed, function() if callback then callback() end end)
    elseif style == "Ripple Soft" then
        tw(wrapper, TweenInfo.new(0.3 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
        tw(uiScale, TweenInfo.new(0.3 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0})
        task.delay(0.35 * speed, function() if callback then callback() end end)
    else
        -- Drop-Bounce (default)
        tw(wrapper, TweenInfo.new(0.25 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {GroupTransparency = 1})
        tw(wrapper, TweenInfo.new(0.4 * speed, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 1.2, 0)})
        tw(uiScale, TweenInfo.new(0.3 * speed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Scale = 0.5})
        task.delay(0.45 * speed, function() if callback then callback() end end)
    end
end

-- ============================================================
-- GRADIENT ACCENT
-- ============================================================
Library._GradientAccents = {}

-- ============================================================
-- FLOATING PARTICLES
-- ============================================================
Library._FloatingParticles = {}

function Library:SpawnFloatingParticles(screenGui, color, count)
    count = count or 12
    for i = 1, count do
        local particle = Instance.new("Frame")
        particle.Name = "FloatingParticle"
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.Size = UDim2.new(0, math.random(3, 6), 0, math.random(3, 6))
        particle.BackgroundColor3 = color or Theme.Blossom
        particle.BackgroundTransparency = math.random(85, 95) / 100
        particle.BorderSizePixel = 0
        particle.ZIndex = 0
        particle.Position = UDim2.new(math.random(), 0, 1.1, 0)
        particle.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = Radius.Pill
        corner.Parent = particle

        table.insert(Library._FloatingParticles, particle)

        task.spawn(function()
            local speed = math.random(20, 50) / 10
            local drift = (math.random() - 0.5) * 0.3
            local startX = particle.Position.X.Scale
            while particle.Parent do
                local dt = RunService.Heartbeat:Wait()
                local newPos = particle.Position.Y.Scale - dt / speed
                if newPos < -0.1 then
                    newPos = 1.1
                    startX = math.random()
                end
                particle.Position = UDim2.new(
                    startX + math.sin(tick() * drift) * 0.05, 0,
                    newPos, 0
                )
            end
        end)
    end
end

-- ============================================================
-- ACCENT SHIMMER
-- ============================================================
function Library:AddAccentShimmer(parent, zIndex)
    local shimmer = Instance.new("Frame")
    shimmer.Name = "AccentShimmer"
    shimmer.AnchorPoint = Vector2.new(0, 0.5)
    shimmer.Position = UDim2.new(-0.3, 0, 0.5, 0)
    shimmer.Size = UDim2.new(0.15, 0, 1.5, 0)
    shimmer.Rotation = 20
    shimmer.BackgroundColor3 = Color3.new(1, 1, 1)
    shimmer.BackgroundTransparency = 0.92
    shimmer.BorderSizePixel = 0
    shimmer.ZIndex = zIndex or 3
    shimmer.Parent = parent

    local shimmerCorner = Instance.new("UICorner")
    shimmerCorner.CornerRadius = Radius.Pill
    shimmerCorner.Parent = shimmer

    task.spawn(function()
        while shimmer.Parent do
            shimmer.Position = UDim2.new(-0.3, 0, 0.5, 0)
            tw(shimmer, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1.3, 0, 0.5, 0)
            })
            task.wait(4)
        end
    end)

    return shimmer
end

-- ============================================================
-- BACKGROUND BLUR
-- ============================================================
function Library:AddBackgroundBlur(screenGui, intensity)
    intensity = intensity or 0.5
    local blurFrame = Instance.new("Frame")
    blurFrame.Name = "BackgroundBlur"
    blurFrame.Size = UDim2.new(1, 0, 1, 0)
    blurFrame.BackgroundColor3 = Color3.new(0, 0, 0)
    blurFrame.BackgroundTransparency = 1 - intensity
    blurFrame.BorderSizePixel = 0
    blurFrame.ZIndex = -2
    blurFrame.Parent = screenGui

    pcall(function()
        local blur = Instance.new("UIBlurEffect")
        blur.Size = math.floor(intensity * 30)
        blur.Parent = blurFrame
    end)

    return blurFrame
end

-- ============================================================
-- STATUS BAR
-- ============================================================
-- ============================================================
-- Typewriter Effect
-- ============================================================
-- Library:Typewriter(textLabel, text, speed)
--   Animates text character-by-character into a TextLabel.
--   Returns the coroutine so callers can :Cancel() it.
--   speed = seconds per character (default 0.03)

function Library:Typewriter(label, text, speed)
    if not label then return nil end
    text = tostring(text or "")
    speed = tonumber(speed) or 0.03

    local cor = coroutine.create(function()
        label.Text = ""
        for i = 1, #text do
            label.Text = string.sub(text, 1, i)
            task.wait(speed)
        end
    end)
    coroutine.resume(cor)
    return cor
end

-- ============================================================
-- Text Customization
-- ============================================================
-- Library:SetTextAppearance(config)
--   Applies font, text size, and text color to every TextLabel and
--   TextButton currently inside the ScreenGui. Call again after
--   adding new elements to re-apply.
--
--   config = {
--       Font      = Enum.Font.GothamBold,
--       TextSize  = 14,
--       TextColor = Color3.new(1, 1, 1),
--   }
--   All fields are optional; omitted fields leave existing values.

function Library:SetTextAppearance(config)
    config = config or {}
    local screenGui = Library.ScreenGui
    if not screenGui then return end

    for _, desc in ipairs(screenGui:GetDescendants()) do
        if desc:IsA("TextLabel") or desc:IsA("TextButton") then
            pcall(function()
                if config.Font then desc.Font = config.Font end
                if config.TextSize then desc.TextSize = config.TextSize end
                if config.TextColor then desc.TextColor3 = config.TextColor end
            end)
        end
    end
end

Library.Theme = Theme
Library.Font = Font
Library.TextSizes = TextSizes
Library.Radius = Radius

getgenv().IvoryHub = Library

-- ===============================================================
-- SETTINGS TAB AUTO-INJECTION
-- Every window a script builds through Library.CreateWindow gets
-- this Settings tab merged into it: into the script's own Settings
-- tab when it creates one, otherwise as a new tab at the end. All
-- script features stay exactly as they are. ShowSettings(window)
-- injects on demand and skips windows that already have it.
-- ===============================================================
function Library.ShowSettings(window)
    window = window or Library._windows[1]
    if not window then
        window = Library.CreateWindow({
            Name = "Ivory Hub",
            Width = 755,
            Height = 550,
        })
    end
    if window._IvorySettingsInjected then
        return window
    end
    window._IvorySettingsInjected = true

    -- Script windows often open small (their own Width/Height config);
    -- once the full Settings tab is attached, bump the card to the
    -- standard default so the two-column layout has room to breathe.
    if (window._cardWidth or 0) < 755 or (window._cardHeight or 0) < 550 then
        applyCardSize(window, math.max(window._cardWidth or 0, 755), math.max(window._cardHeight or 0, 550))
    end

    local SettingsTab
    for _, tab in ipairs(window._tabs) do
        if tab.Name == "Settings" then
            SettingsTab = tab
            break
        end
    end
    if not SettingsTab then
        SettingsTab = window:CreateTab("Settings")
    end

    local demoNoticeDuration = 3

    -- ---------------- Settings tab ----------------

    -- ---------------- Themes: one dropdown repaints everything ----------------
    local ThemeSection = SettingsTab:CreateSection("Themes")

    local themeNames = {}
    for name in pairs(Library.ThemePresets) do
        table.insert(themeNames, name)
    end
    table.sort(themeNames)

    ThemeSection:CreateDropdown({
        Name = "Theme Preset",
        Options = themeNames,
        CurrentOption = "Sakura",
        Callback = function(value)
            Library:ApplyThemePreset(value)
        end,
    })

    ThemeSection:CreateParagraph({
        Title = "Themes change everything",
        Content = "Picking a preset repaints every open screen: window, panels, buttons, text, strokes, scrollbars, gradients, notification colors and the falling petals.",
    })

    local AnimSection = SettingsTab:CreateSection("Animation")

    AnimSection:CreateDropdown({
        Name = "Animation Style",
        Options = { "Drop", "Ripple", "Ripple Soft" },
        CurrentOption = "Ripple Soft",
        Callback = function(value)
            Library.AnimationStyle = value
        end,
    })

    AnimSection:CreateSlider({
        Name = "Animation Speed",
        Range = { 0.1, 5 },
        Increment = 0.1,
        CurrentValue = 1,
        Callback = function(value)
            Library.AnimationSpeed = value
        end,
    })

    local NoticeSection = SettingsTab:CreateSection("Notifications")

    NoticeSection:CreateToggle({
        Name = "Show Watermark",
        CurrentValue = false,
        Callback = function(value)
            Library.SetWatermarkEnabled(value)
        end,
    })

    NoticeSection:CreateSlider({
        Name = "Notification Duration",
        Range = { 1, 10 },
        Increment = 1,
        Suffix = "s",
        CurrentValue = 3,
        Callback = function(value)
            demoNoticeDuration = value
        end,
    })

    NoticeSection:CreateButton({
        Name = "Test Notification",
        Callback = function()
            Library.Notify({
                Title = "Test",
                Content = "This is a test notification.",
                Type = "Info",
                Duration = demoNoticeDuration,
            })
        end,
    })

    local ConfigSection = SettingsTab:CreateSection("Configuration")

    Library.CreateConfigControls(ConfigSection)

    ConfigSection:CreateButton({
        Name = "Unload Hub",
        Callback = function()
            Library:Unload()
        end,
    })

    -- Fifth top-level section (left column, under Notifications).
    local LayoutSection = SettingsTab:CreateSection("Layout")

    LayoutSection:CreateDropdown({
        Name = "Columns",
        Options = { "Two", "One" },
        CurrentOption = "Two",
        Callback = function(value)
            Library:SetContentColumns(value == "One" and 1 or 2)
        end,
    })

    LayoutSection:CreateParagraph({
        Title = "Column layout",
        Content = "Two spreads sections across the card like a CS2 cheat menu; One stacks every section full-width.",
    })

    Library.Notify({
        Title = "Ivory Hub",
        Content = "Press RightShift to toggle the menu.",
        Type = "Info",
        Duration = 5,
    })

    return window
end

local rawCreateWindow = Library.CreateWindow
Library.CreateWindow = function(config)
    local window = rawCreateWindow(config)
    task.defer(function()
        local tries = 0
        while #window._tabs == 0 and not window._IvorySettingsInjected and tries < 20 do
            task.wait(0.1)
            tries = tries + 1
        end
        if not window._IvorySettingsInjected and window.ScreenGui and window.ScreenGui.Parent then
            Library.ShowSettings(window)
        end
    end)
    return window
end

return Library
