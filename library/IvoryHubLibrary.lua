--!strict
--!native
--!optimize 2
--Selene: allow unused_variable, shadowing
--[[
    Ivory Hub — Sakura Edition
    Cherry-blossom theme with a deep-plum base

    Color Palette (sakura edition):
      bgDeep          #100911
      bgMid           #1a1225
      bgSurface       #231a30
      bgElevated      #2d2238
      bgHover         #382c44
      bgCard          #1e1628
      accent          #F72482
      accentDark      #c41d68
      accentLight     #ff6eb4
      textPrimary     #f5f0f7
      textSecondary   #b8a9c0
      textMuted       #8a7a94
      border          #3d2e4a
      borderLight     #4e3d5c
      borderAccent    #F72482
      success         #2dd4a8
      warning         #fbbf24
      danger          #ef4444
      info            #60a5fa
      white           #ffffff
      shadow          #0a0610
      scrollbarThumb  #3d2e4a
      scrollbarTrack  #1a1225
      inputBg         #1a1225
      dropdownBg      #1e1628
      menuBg          #100911
      titlebarBg      #1a1225

    Features:
      * CreateWindow, CreateTab, CreateSection, CreateButton, CreateToggle
      * CreateSlider, CreateDropdown, CreateMultiDropdown, CreateColorPicker
      * CreateKeybind, CreateInput, CreateLabel, CreateParagraph, CreateDivider
      * Built-in ConfigSaving  – SaveConfiguration / LoadConfiguration / Autosave
      * Built-in Notification  – Library.Notify({ Title, Content, Type, Duration })
      * Built-in Watermark     – toggled via Watermark widget on Settings tab
      * Built-in Search        – Ctrl+F (or configured keybind) to fuzzy-search across all tabs
      * Built-in universal     – Speed / Noclip / ESP / Fullbright / Anti-AFK (settings tab)
      * Built-in info          – version, player-name, UID, game, exploit
      * Built-in ThemeWidget   – accent colour picker, corner, blur, transparency, font
      * Built-in MenuKeybind   – configurable (default RightShift)
      * Roblox-compatible (no getfenv debug.getupvalue; uses pcall-based profiling)
      * Graceful degradation for drawing library (ESP/fullbright optional)
      * Custom Font support via FontFace override on every Text element

    NOTE: If you want to bypass executors that block `hookmetamethod`, you can
          disable the custom __namecall wrapper by setting
              Library.WrapNamecall = false
          before calling CreateWindow. The library works fine without it.
]]

local Library = {}

Library.Version = "2.1.1 (sakura)"
Library.Debug = false
Library.WrapNamecall = true

-- ── Fallback drawing library ──────────────────────────────────────────────────
local DrawingAny = (getgenv and getgenv().Drawing and getgenv().Drawing.new)
    or (Drawing and Drawing.new)
    or nil

local function safeDrawing(class: string, props: {[string]: any}?): any
    if not DrawingAny then return nil end
    local ok, obj = pcall(DrawingAny, class)
    if not ok or not obj then return nil end
    if props then
        for k, v in pairs(props) do
            pcall(function() obj[k] = v end)
        end
    end
    return obj
end

-- ── Services ──────────────────────────────────────────────────────────────────

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local CoreGui            = game:GetService("CoreGui")
local TextService        = game:GetService("TextService")
local HttpService        = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local StarterGui         = game:GetService("StarterGui")

local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")
local Mouse             = LocalPlayer:GetMouse()

-- ── Type Definitions ──────────────────────────────────────────────────────────

export type WindowConfig = {
    Name:               string?,
    Width:              number?,
    Height:             number?,
    Resizable:          boolean?,
    Stagger:            boolean?,
    AutoSize:           boolean?,
    NotifyPosition:     string?,
    NotifyDuration:     number?,
    DragSpeed:          number?,
    CornerRadius:       number?,
    ToggleKeybind:      Enum.KeyCode?,
    CustomFont:         Font?,
    Watermark:          boolean?,
    WatermarkEnabled:   boolean?,
    AccentColor:        Color3?,
    ConfigSaving:       boolean?,
    ConfigName:         string?,
    AutoSaveInterval:   number?,
    MergedTabBar:     boolean?,
}

export type Tab = {
    Name:           string,
    Icon:           string?,
    Active:         boolean,
    Elements:       {any},
    Container:      Frame,
    TabButton:      TextButton,
    Destroy:        (self: Tab) -> (),
    CreateSection:  (self: Tab, name: string) -> Section,
    CreateButton:   (self: Tab, config: ButtonConfig) -> Button,
    CreateToggle:   (self: Tab, config: ToggleConfig) -> Toggle,
    CreateSlider:   (self: Tab, config: SliderConfig) -> Slider,
    CreateDropdown: (self: Tab, config: DropdownConfig) -> Dropdown,
    CreateMultiDropdown: (self: Tab, config: MultiDropdownConfig) -> MultiDropdown,
    CreateColorPicker:   (self: Tab, config: ColorPickerConfig) -> ColorPicker,
    CreateKeybind:  (self: Tab, config: KeybindConfig) -> Keybind,
    CreateInput:    (self: Tab, config: InputConfig) -> Input,
    CreateLabel:    (self: Tab, text: string) -> Label,
    CreateParagraph:(self: Tab, config: ParagraphConfig) -> Paragraph,
    CreateDivider:  (self: Tab) -> Divider,
}

export type Section = {
    Name:           string,
    Container:      Frame,
    Elements:       {any},
    Destroy:        (self: Section) -> (),
    CreateButton:   (self: Section, config: ButtonConfig) -> Button,
    CreateToggle:   (self: Section, config: ToggleConfig) -> Toggle,
    CreateSlider:   (self: Section, config: SliderConfig) -> Slider,
    CreateDropdown: (self: Section, config: DropdownConfig) -> Dropdown,
    CreateMultiDropdown: (self: Section, config: MultiDropdownConfig) -> MultiDropdown,
    CreateColorPicker:   (self: Section, config: ColorPickerConfig) -> ColorPicker,
    CreateKeybind:  (self: Section, config: KeybindConfig) -> Keybind,
    CreateInput:    (self: Section, config: InputConfig) -> Input,
    CreateLabel:    (self: Section, text: string) -> Label,
    CreateParagraph:(self: Section, config: ParagraphConfig) -> Paragraph,
    CreateDivider:  (self: Section) -> Divider,
}

export type Button = {
    Name:       string,
    Container:  Frame,
    Callback:   () -> (),
    SetText:    (self: Button, text: string) -> (),
    SetCallback:(self: Button, callback: () -> ()) -> (),
    Destroy:    (self: Button) -> (),
}

export type Toggle = {
    Name:           string,
    CurrentValue:   boolean,
    Container:      Frame,
    Callback:       (value: boolean) -> (),
    SetValue:       (self: Toggle, value: boolean) -> (),
    SetCallback:    (self: Toggle, callback: (value: boolean) -> ()) -> (),
    Destroy:        (self: Toggle) -> (),
}

export type Slider = {
    Name:           string,
    CurrentValue:   number,
    Min:            number,
    Max:            number,
    Increment:      number,
    Container:      Frame,
    Callback:       (value: number) -> (),
    SetValue:       (self: Slider, value: number) -> (),
    SetCallback:    (self: Slider, callback: (value: number) -> ()) -> (),
    Destroy:        (self: Slider) -> (),
}

export type Dropdown = {
    Name:           string,
    CurrentOption:  string,
    Options:        {string},
    Container:      Frame,
    Callback:       (option: string) -> (),
    SetOptions:     (self: Dropdown, options: {string}) -> (),
    SetValue:       (self: Dropdown, value: string) -> (),
    SetCallback:    (self: Dropdown, callback: (option: string) -> ()) -> (),
    Destroy:        (self: Dropdown) -> (),
}

export type MultiDropdown = {
    Name:           string,
    CurrentOption:  {string},
    Options:        {string},
    Container:      Frame,
    Callback:       (options: {string}) -> (),
    SetOptions:     (self: MultiDropdown, options: {string}) -> (),
    SetValue:       (self: MultiDropdown, values: {string}) -> (),
    SetCallback:    (self: MultiDropdown, callback: (options: {string}) -> ()) -> (),
    Destroy:        (self: MultiDropdown) -> (),
}

export type ColorPicker = {
    Name:           string,
    Color:          Color3,
    Container:      Frame,
    Callback:       (color: Color3) -> (),
    SetValue:       (self: ColorPicker, color: Color3) -> (),
    SetCallback:    (self: ColorPicker, callback: (color: Color3) -> ()) -> (),
    Destroy:        (self: ColorPicker) -> (),
}

export type Keybind = {
    Name:           string,
    CurrentKeybind: string,
    Container:      Frame,
    Callback:       (keybind: string) -> (),
    ChangedCallback:(keybind: string) -> (),
    SetKeybind:     (self: Keybind, keybind: string) -> (),
    SetCallback:    (self: Keybind, callback: (keybind: string) -> ()) -> (),
    SetChangedCallback:(self: Keybind, callback: (keybind: string) -> ()) -> (),
    Destroy:        (self: Keybind) -> (),
}

export type Input = {
    Name:               string,
    CurrentValue:       string,
    PlaceholderText:    string,
    Container:          Frame,
    Callback:           (text: string) -> (),
    SetValue:           (self: Input, value: string) -> (),
    SetCallback:        (self: Input, callback: (text: string) -> ()) -> (),
    Destroy:            (self: Input) -> (),
}

export type Label = {
    Name:       string,
    Container:  Frame,
    SetText:    (self: Label, text: string) -> (),
    Destroy:    (self: Label) -> (),
}

export type Paragraph = {
    Name:       string,
    Container:  Frame,
    SetTitle:   (self: Paragraph, title: string) -> (),
    SetContent: (self: Paragraph, content: string) -> (),
    Destroy:    (self: Paragraph) -> (),
}

export type Divider = {
    Container:  Frame,
    Destroy:    (self: Divider) -> (),
}

export type Window = {
    Name:           string,
    Tabs:           {Tab},
    Elements:       {any},
    Container:      Frame,
    MainFrame:      Frame,
    TopBar:         Frame,
    Destroy:        (self: Window) -> (),
    CreateTab:      (self: Window, config: string | {Name: string, Icon: string?}) -> Tab,
    SetName:        (self: Window, name: string) -> (),
    SetAccentColor: (self: Window, color: Color3) -> (),
}

Library.__index = Library

-- ── Constants ─────────────────────────────────────────────────────────────────

local BLOSSOM_PINK    = Color3.fromHex("#F72482")
local DEEP_PLUM       = Color3.fromHex("#100911")
local PLUM_MID        = Color3.fromHex("#1a1225")
local PLUM_SURFACE    = Color3.fromHex("#231a30")
local PLUM_ELEVATED   = Color3.fromHex("#2d2238")
local PLUM_HOVER      = Color3.fromHex("#382c44")
local PLUM_CARD       = Color3.fromHex("#1e1628")
local TEXT_PRIMARY     = Color3.fromHex("#f5f0f7")
local TEXT_SECONDARY   = Color3.fromHex("#b8a9c0")
local TEXT_MUTED       = Color3.fromHex("#8a7a94")
local BORDER          = Color3.fromHex("#3d2e4a")
local BORDER_LIGHT    = Color3.fromHex("#4e3d5c")
local SUCCESS         = Color3.fromHex("#2dd4a8")
local WARNING         = Color3.fromHex("#fbbf24")
local DANGER          = Color3.fromHex("#ef4444")
local INFO            = Color3.fromHex("#60a5fa")
local SHADOW          = Color3.fromHex("#0a0610")
local SCROLLBAR_THUMB = Color3.fromHex("#3d2e4a")
local SCROLLBAR_TRACK = Color3.fromHex("#1a1225")
local INPUT_BG        = Color3.fromHex("#1a1225")
local DROPDOWN_BG     = Color3.fromHex("#1e1628")
local MENU_BG         = Color3.fromHex("#100911")
local TITLEBAR_BG     = Color3.fromHex("#1a1225")

local IVORY_BLOSSOM_ICON  = "rbxassetid://79379082636309"
local IVORY_WORDMARK_ID   = "rbxassetid://79379082636309"
local IVORY_UV_DASH       = "rbxassetid://13603376803"
local IVORY_UV_LOGO       = "rbxassetid://13708364360"
local IVORY_BLOSSOM_ASSET_ID = "rbxassetid://79379082636309"

local MAX_RECURSION       = 500
local CORNER_RADIUS       = UDim.new(0, 6)
local ELEMENT_HEIGHT      = UDim.new(0, 32)
local SECTION_PADDING     = 6

local FONT_LIGHT     = Enum.Font.Gotham
local FONT_MEDIUM    = Enum.Font.GothamMedium
local FONT_BOLD      = Enum.Font.GothamBold
local FONT_SEMIBOLD  = Enum.Font.GothamSemibold

Library.FONT_LIGHT    = FONT_LIGHT
Library.FONT_MEDIUM   = FONT_MEDIUM
Library.FONT_BOLD     = FONT_BOLD
Library.FONT_SEMIBOLD = FONT_SEMIBOLD

Library.BLOSSOM_PINK    = BLOSSOM_PINK
Library.DEEP_PLUM       = DEEP_PLUM
Library.PLUM_MID        = PLUM_MID
Library.PLUM_SURFACE    = PLUM_SURFACE
Library.PLUM_ELEVATED   = PLUM_ELEVATED
Library.PLUM_HOVER      = PLUM_HOVER
Library.PLUM_CARD       = PLUM_CARD
Library.TEXT_PRIMARY     = TEXT_PRIMARY
Library.TEXT_SECONDARY   = TEXT_SECONDARY
Library.TEXT_MUTED       = TEXT_MUTED
Library.BORDER          = BORDER
Library.BORDER_LIGHT    = BORDER_LIGHT
Library.SUCCESS         = SUCCESS
Library.WARNING         = WARNING
Library.DANGER          = DANGER
Library.INFO            = INFO
Library.SHADOW          = SHADOW
Library.SCROLLBAR_THUMB = SCROLLBAR_THUMB
Library.SCROLLBAR_TRACK = SCROLLBAR_TRACK
Library.INPUT_BG        = INPUT_BG
Library.DROPDOWN_BG     = DROPDOWN_BG
Library.MENU_BG         = MENU_BG
Library.TITLEBAR_BG     = TITLEBAR_BG

Library.IVORY_BLOSSOM_ICON  = IVORY_BLOSSOM_ICON
Library.IVORY_WORDMARK_ID   = IVORY_WORDMARK_ID
Library.IVORY_UV_DASH       = IVORY_UV_DASH
Library.IVORY_UV_LOGO       = IVORY_UV_LOGO
Library.IVORY_BLOSSOM_ASSET_ID = IVORY_BLOSSOM_ASSET_ID

-- ── Theme ─────────────────────────────────────────────────────────────────────

Library.Theme = {
    AccentColor       = BLOSSOM_PINK,
    Dark              = true,
    Transparency      = 0,
    FontSize          = 13,
    TitleSize         = 14,
    ElementPadding    = 4,
    SectionPadding    = 8,
    CornerRadius      = UDim.new(0, 6),
    BorderThickness   = 1,
    GlowEnabled       = false,
    Font              = FONT_MEDIUM,
    TitleFont         = FONT_BOLD,
    HeaderFont        = FONT_SEMIBOLD,
    CustomFont        = nil :: Font?,
    ElementHeight     = UDim.new(0, 32),
    SmallElementHeight = UDim.new(0, 26),
    MiniElementHeight  = UDim.new(0, 20),
    DropdownHeight     = UDim.new(0, 28),
    ToggledColor      = BLOSSOM_PINK,
    UntoggledColor    = BORDER,
    DisabledColor     = Color3.fromHex("#2d2238"),
}

-- ── State ─────────────────────────────────────────────────────────────────────

Library._themeListeners = {}
Library._activeDropdown = nil :: {Frame: Frame, Destroy: () -> ()}?  :: any
Library._activeColorPicker = nil :: {Frame: Frame, Destroy: () -> ()}?  :: any
Library._draggingWindow = nil :: {Window: Frame, Start: Vector2, Offset: Vector2}?
Library._hoveringWindow = nil :: Frame?
Library._focusedInput = nil :: TextBox?
Library._openMenuKeybindFrame = nil :: Frame?
Library._menuOpen = false
Library._menuKeybind = Enum.KeyCode.RightShift
Library._guiParent = nil :: Instance?
Library._activeHighlight = nil :: Frame?
Library._activeHighlightTime = 0
Library._dodgeCooldown = 0
Library._notifications = {}
Library._configAutosaveThread = nil :: thread?
Library._searchThread = nil :: thread?
Library._soundClick = nil :: Sound?
Library._hoverDebounce = false
Library._topBarDropdownActive = false
Library._topBarDropdownFrame = nil :: Frame?
Library._topBarDropdownClose = nil :: (() -> ())?
Library._menuKeybindFrame = nil :: Frame?
Library._suppressInputTick = false

-- ── Utilities ─────────────────────────────────────────────────────────────────

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[deepCopy(k)] = deepCopy(v)
    end
    return setmetatable(copy, getmetatable(t))
end

local function getThreadCounter(): number
    if not Library._threadCounter then
        Library._threadCounter = 0
    end
    Library._threadCounter += 1
    return Library._threadCounter
end

local function getThreads(): {[string]: boolean}
    if not Library._threads then
        Library._threads = {}
    end
    return Library._threads
end

local function cleanupThread(name: string)
    local threads = getThreads()
    if threads[name] then
        pcall(task.cancel, threads[name])
    end
end

local function startsWith(str, start)
    return str:sub(1, #start) == start
end

local function endsWith(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

local function includes(str, pattern)
    return str:find(pattern, 1, true) ~= nil
end

local function trim(str)
    return str:match("^%s*(.-)%s*$")
end

local function round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(val, min, max)
    return math.min(math.max(val, min), max)
end

local function map(value, inMin, inMax, outMin, outMax)
    return outMin + (outMax - outMin) * ((value - inMin) / (inMax - inMin))
end

local function shallowMerge(a, b)
    local result = {}
    for k, v in pairs(a) do result[k] = v end
    for k, v in pairs(b) do result[k] = v end
    return result
end

local function getLayerCollector(): LayerCollector
    local gui = Library._guiParent
    if gui and gui:IsA("LayerCollector") then return gui end
    return CoreGui
end

local function guiParent(): Instance
    if Library._guiParent then return Library._guiParent end
    local ok, old = pcall(function()
        local g = getgenv()
        if not g.OldScreenGui then
            g.OldScreenGui = CoreGui:FindFirstChild("OBSIDIAN__MODERN")
            if g.OldScreenGui then
                g.OldScreenGui.Name = "OBSIDIAN"
            end
        end
        return g.OldScreenGui
    end)
    if ok and old then
        Library._guiParent = old
        return old
    end
    local sgui = Instance.new("ScreenGui")
    sgui.Name = "IvoryHub"
    sgui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sgui.DisplayOrder = 1147483647
    sgui.ResetOnSpawn = false
    sgui.IgnoreGuiInset = true
    pcall(function() sgui.Parent = gethui() end)
    if not sgui.Parent then sgui.Parent = CoreGui end
    Library._guiParent = sgui
    return sgui
end

local function getCorner(parent: Frame, radius: UDim?): UICorner
    local existing = parent:FindFirstChildWhichIsA("UICorner")
    if existing then
        if radius then existing.CornerRadius = radius end
        return existing
    end
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or Library.Theme.CornerRadius
    c.Parent = parent
    return c
end

local function getStroke(parent: Frame, color: Color3?, thickness: number?, mode: Enum.ApplyStrokeMode?): UIStroke
    local existing = parent:FindFirstChildWhichIsA("UIStroke")
    if existing then
        if color then existing.Color = color end
        if thickness then existing.Thickness = thickness end
        if mode then existing.ApplyStrokeMode = mode end
        return existing
    end
    local s = Instance.new("UIStroke")
    s.Color = color or BORDER
    s.Thickness = thickness or Library.Theme.BorderThickness
    s.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function getPadding(parent: Frame, padding: UDim?): UIPadding
    local existing = parent:FindFirstChildWhichIsA("UIPadding")
    if existing then
        if padding then
            existing.PaddingTop = padding
            existing.PaddingBottom = padding
            existing.PaddingLeft = padding
            existing.PaddingRight = padding
        end
        return existing
    end
    local p = Instance.new("UIPadding")
    if padding then
        p.PaddingTop = padding
        p.PaddingBottom = padding
        p.PaddingLeft = padding
        p.PaddingRight = padding
    else
        p.PaddingTop = UDim.new(0, 8)
        p.PaddingBottom = UDim.new(0, 8)
        p.PaddingLeft = UDim.new(0, 8)
        p.PaddingRight = UDim.new(0, 8)
    end
    p.Parent = parent
    return p
end

local function addShadow(frame: Frame, transparency: number?)
    local existing = frame:FindFirstChild("IvoryShadow")
    if existing then return existing end
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "IvoryShadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.fromScale(0.5, 0.5)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = transparency or 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.Parent = frame
    return shadow
end

local function addGlow(parent: Frame, color: Color3?): Frame
    local existing = parent:FindFirstChild("IvoryGlow")
    if existing then return existing end
    local glow = Instance.new("Frame")
    glow.Name = "IvoryGlow"
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.BackgroundTransparency = 1
    glow.Position = UDim2.fromScale(0.5, 0.5)
    glow.Size = UDim2.new(1, 8, 1, 8)
    glow.ZIndex = parent.ZIndex - 1
    glow.Parent = parent
    local glowImage = Instance.new("ImageLabel")
    glowImage.Name = "GlowImage"
    glowImage.AnchorPoint = Vector2.new(0.5, 0.5)
    glowImage.BackgroundTransparency = 1
    glowImage.Position = UDim2.fromScale(0.5, 0.5)
    glowImage.Size = UDim2.new(1, 0, 1, 0)
    glowImage.ZIndex = parent.ZIndex - 1
    glowImage.Image = "rbxassetid://5554236805"
    glowImage.ImageColor3 = color or Library.Theme.AccentColor
    glowImage.ImageTransparency = 0.85
    glowImage.ScaleType = Enum.ScaleType.Slice
    glowImage.SliceCenter = Rect.new(23, 23, 277, 277)
    glowImage.Parent = glow
    return glow
end

local function removeShadow(frame: Frame)
    local shadow = frame:FindFirstChild("IvoryShadow")
    if shadow then shadow:Destroy() end
    local glow = frame:FindFirstChild("IvoryGlow")
    if glow then glow:Destroy() end
end

local function createTween(
    object: Instance,
    info: TweenInfo,
    properties: {[string]: any}
): Tween
    return TweenService:Create(object, info, properties)
end

local function makeDraggable(frame: Frame, handle: GuiObject?, smooth: boolean?, speed: number?)
    local dragStart, startPos, dragging

    local function update(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        if smooth then
            createTween(frame, TweenInfo.new(speed or 0.15, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = position}):Play()
        else
            frame.Position = position
        end
    end

    local handleGui = handle or frame

    handleGui.InputBegan:Connect(function(input)
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

    handleGui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            Library._draggingWindow = {
                Window = frame,
                Start = input.Position,
                Offset = Vector2.new(0, 0),
            }
            if dragging then
                update(input)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            update(input)
        end
    end)
end

-- ── Dropdown Logic ────────────────────────────────────────────────────────────

local function closeDropdown()
    if Library._activeDropdown then
        local active = Library._activeDropdown
        Library._activeDropdown = nil
        active:Destroy()
    end
end

local function openDropdown(config: {
    Parent: Frame,
    Options: {string},
    CurrentOption: string,
    Callback: (option: string) -> (),
    ZIndex: number,
    Scrollable: boolean?,
    Multi: boolean?,
    CurrentOptions: {string}?,
})
    closeDropdown()

    local Selected = config.CurrentOption
    local SelectedT = if config.Multi then (config.CurrentOptions or {}) else nil

    local dropFrame = Instance.new("Frame")
    dropFrame.Name = "DropdownMenu"
    dropFrame.BackgroundColor3 = DROPDOWN_BG
    dropFrame.BorderSizePixel = 0
    dropFrame.ZIndex = config.ZIndex + 5
    dropFrame.Archivable = false
    dropFrame.ClipsDescendants = true
    dropFrame.Parent = config.Parent

    getCorner(dropFrame, UDim.new(0, 6))
    getStroke(dropFrame, BORDER, 1)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.Parent = dropFrame

    local paddingIns = getPadding(dropFrame, UDim.new(0, 4))

    local maxVisible = math.min(#config.Options, 8)
    local optionHeight = 26
    local totalHeight = maxVisible * optionHeight + 8
    local minWidth = config.Parent.AbsoluteSize.X

    local longestText = 0
    for _, opt in ipairs(config.Options) do
        local textSize = TextService:GetTextSize(opt, 12, FONT_MEDIUM, Vector2.new(9999, 24))
        longestText = math.max(longestText, textSize.X)
    end
    local finalWidth = math.max(minWidth, longestText + 36)

    dropFrame.Size = UDim2.new(0, finalWidth, 0, 0)
    dropFrame.Position = UDim2.new(0, 0, 1, 4)
    dropFrame.BackgroundTransparency = 0
    dropFrame.ClipsDescendants = true
    dropFrame.Visible = true

    local function layoutDrop()
        layout:ApplyLayoutStart()
    end

    local function destroyDropdown()
        dropFrame.Visible = false
        pcall(function() dropFrame:Destroy() end)
    end

    for i, option in ipairs(config.Options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Name = "Option_" .. i
        optBtn.BackgroundColor3 = Color3.new(0, 0, 0)
        optBtn.BackgroundTransparency = 1
        optBtn.BorderSizePixel = 0
        optBtn.Font = FONT_MEDIUM
        optBtn.TextColor3 = TEXT_PRIMARY
        optBtn.TextSize = 12
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.ZIndex = config.ZIndex + 6
        optBtn.Text = "   " .. option
        optBtn.LayoutOrder = i
        optBtn.AutoButtonColor = false
        optBtn.Size = UDim2.new(1, 0, 0, optionHeight)
        optBtn.Parent = dropFrame

        getCorner(optBtn, UDim.new(0, 4))

        local isSelected = false
        if config.Multi then
            isSelected = table.find(SelectedT, option) ~= nil
        else
            isSelected = option == Selected
        end
        if isSelected then
            optBtn.BackgroundColor3 = Library.Theme.AccentColor
            optBtn.BackgroundTransparency = 0.9
        end

        optBtn.MouseEnter:Connect(function()
            if isSelected then return end
            optBtn.BackgroundTransparency = 0.9
            optBtn.BackgroundColor3 = BORDER_LIGHT
        end)
        optBtn.MouseLeave:Connect(function()
            if isSelected then return end
            optBtn.BackgroundTransparency = 1
        end)

        optBtn.MouseButton1Click:Connect(function()
            if config.Multi then
                local idx = table.find(SelectedT, option)
                if idx then
                    table.remove(SelectedT, idx)
                else
                    table.insert(SelectedT, option)
                end
                config.Callback(SelectedT)
            else
                Selected = option
                config.Callback(Selected)
                destroyDropdown()
                Library._activeDropdown = nil
            end
        end)
    end

    task.defer(function()
        dropFrame.Size = UDim2.new(0, finalWidth, 0, totalHeight + 8)
    end)

    Library._activeDropdown = {
        Frame = dropFrame,
        Destroy = destroyDropdown,
    }

    local function closeOnInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
            or (input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape)
        then
            if Library._activeDropdown then
                Library._activeDropdown:Destroy()
                Library._activeDropdown = nil
            end
            UserInputService.InputBegan:Once(closeOnInput)
        end
    end
    UserInputService.InputBegan:Once(closeOnInput)

    return destroyDropdown
end

-- ── Color Picker Logic ────────────────────────────────────────────────────────

local function destroyColorPicker()
    if Library._activeColorPicker then
        Library._activeColorPicker:Destroy()
        Library._activeColorPicker = nil
    end
end

local function openColorPicker(config: {
    Parent: GuiObject,
    Color: Color3,
    Callback: (color: Color3) -> (),
    ZIndex: number,
})
    destroyColorPicker()

    local h, s, v = config.Color:ToHSV()

    local cpFrame = Instance.new("Frame")
    cpFrame.Name = "ColorPickerMenu"
    cpFrame.BackgroundColor3 = PLUM_ELEVATED
    cpFrame.BorderSizePixel = 0
    cpFrame.ZIndex = config.ZIndex + 10
    cpFrame.Size = UDim2.new(0, 220, 0, 260)
    cpFrame.ClipsDescendants = true
    cpFrame.Parent = config.Parent

    getCorner(cpFrame, UDim.new(0, 6))
    getStroke(cpFrame, BORDER, 1)

    local cpPad = getPadding(cpFrame, UDim.new(0, 8))

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.BackgroundColor3 = TITLEBAR_BG
    titleBar.BorderSizePixel = 0
    titleBar.Size = UDim2.new(1, 0, 0, 28)
    titleBar.ZIndex = config.ZIndex + 11
    titleBar.Parent = cpFrame
    getCorner(titleBar, UDim.new(0, 6))

    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.BackgroundTransparency = 1
    titleText.Size = UDim2.new(1, 0, 1, 0)
    titleText.Font = FONT_BOLD
    titleText.Text = "Color Picker"
    titleText.TextColor3 = TEXT_PRIMARY
    titleText.TextSize = 11
    titleText.ZIndex = config.ZIndex + 12
    titleText.Parent = titleBar

    local svFrame = Instance.new("Frame")
    svFrame.Name = "SVPanel"
    svFrame.BackgroundColor3 = Color3.new(1, 1, 1)
    svFrame.BorderSizePixel = 0
    svFrame.Size = UDim2.new(1, 0, 0, 140)
    svFrame.Position = UDim2.new(0, 0, 0, 34)
    svFrame.ZIndex = config.ZIndex + 11
    svFrame.Parent = cpFrame
    getCorner(svFrame, UDim.new(0, 4))

    local svGrad = Instance.new("UIGradient")
    svGrad.Name = "SVGradient"
    svGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
    })
    svGrad.Rotation = 0
    svGrad.Parent = svFrame

    local svBlack = Instance.new("Frame")
    svBlack.Name = "BlackOverlay"
    svBlack.BackgroundColor3 = Color3.new(0, 0, 0)
    svBlack.BackgroundTransparency = 0
    svBlack.BorderSizePixel = 0
    svBlack.Size = UDim2.new(1, 0, 1, 0)
    svBlack.ZIndex = config.ZIndex + 12
    svBlack.Parent = svFrame

    local svBlackGrad = Instance.new("UIGradient")
    svBlackGrad.Name = "BlackGradient"
    svBlackGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
    })
    svBlackGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    svBlackGrad.Rotation = 90
    svBlackGrad.Parent = svBlack

    local svCursor = Instance.new("Frame")
    svCursor.Name = "Cursor"
    svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    svCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    svCursor.BorderSizePixel = 0
    svCursor.Size = UDim2.new(0, 10, 0, 10)
    svCursor.ZIndex = config.ZIndex + 14
    svCursor.Parent = svFrame

    getCorner(svCursor, UDim.new(1, 0))
    local svStroke = getStroke(svCursor, Color3.new(0, 0, 0), 2)
    svStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual

    local hueBar = Instance.new("Frame")
    hueBar.Name = "HueBar"
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.BorderSizePixel = 0
    hueBar.Size = UDim2.new(1, 0, 0, 14)
    hueBar.Position = UDim2.new(0, 0, 0, 178)
    hueBar.ZIndex = config.ZIndex + 11
    hueBar.Parent = cpFrame
    getCorner(hueBar, UDim.new(1, 0))

    local hueGrad = Instance.new("UIGradient")
    hueGrad.Name = "HueGradient"
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
        ColorSequenceKeypoint.new(1 / 6, Color3.new(1, 1, 0)),
        ColorSequenceKeypoint.new(2 / 6, Color3.new(0, 1, 0)),
        ColorSequenceKeypoint.new(3 / 6, Color3.new(0, 1, 1)),
        ColorSequenceKeypoint.new(4 / 6, Color3.new(0, 0, 1)),
        ColorSequenceKeypoint.new(5 / 6, Color3.new(1, 0, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0)),
    })
    hueGrad.Rotation = 0
    hueGrad.Parent = hueBar

    local hueCursor = Instance.new("Frame")
    hueCursor.Name = "HueCursor"
    hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
    hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
    hueCursor.BorderSizePixel = 0
    hueCursor.Size = UDim2.new(0, 6, 1, 4)
    hueCursor.ZIndex = config.ZIndex + 14
    hueCursor.Parent = hueBar

    getCorner(hueCursor, UDim.new(1, 0))
    getStroke(hueCursor, Color3.new(0, 0, 0), 2)

    local previewFrame = Instance.new("Frame")
    previewFrame.Name = "Preview"
    previewFrame.BackgroundColor3 = config.Color
    previewFrame.BorderSizePixel = 0
    previewFrame.Size = UDim2.new(0.3, 0, 0, 16)
    previewFrame.Position = UDim2.new(0, 0, 0, 198)
    previewFrame.ZIndex = config.ZIndex + 11
    previewFrame.Parent = cpFrame
    getCorner(previewFrame, UDim.new(0, 4))
    getStroke(previewFrame, BORDER, 1)

    local hexLabel = Instance.new("TextLabel")
    hexLabel.Name = "HexLabel"
    hexLabel.BackgroundTransparency = 1
    hexLabel.Size = UDim2.new(0.7, -4, 0, 16)
    hexLabel.Position = UDim2.new(0.3, 4, 0, 198)
    hexLabel.Font = FONT_MEDIUM
    hexLabel.Text = "#" .. config.Color:ToHex():upper()
    hexLabel.TextColor3 = TEXT_PRIMARY
    hexLabel.TextSize = 11
    hexLabel.TextXAlignment = Enum.TextXAlignment.Left
    hexLabel.ZIndex = config.ZIndex + 11
    hexLabel.Parent = cpFrame

    local function updateSV()
        local hueColor = Color3.fromHSV(h, 1, 1)
        svGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, hueColor),
        })
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        local newColor = Color3.fromHSV(h, s, v)
        previewFrame.BackgroundColor3 = newColor
        hexLabel.Text = "#" .. newColor:ToHex():upper()
    end

    local function updateHue(newH: number)
        h = clamp(newH, 0, 0.999)
        updateSV()
        config.Callback(Color3.fromHSV(h, s, v))
    end

    local function updateSVColor(newS: number, newV: number)
        s = clamp(newS, 0, 1)
        v = clamp(newV, 0, 1)
        local hueColor = Color3.fromHSV(h, 1, 1)
        svGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, hueColor),
        })
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
        local newColor = Color3.fromHSV(h, s, v)
        previewFrame.BackgroundColor3 = newColor
        hexLabel.Text = "#" .. newColor:ToHex():upper()
        config.Callback(newColor)
    end

    local svDragging = false
    local hueDragging = false

    svFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = true
            local absPos = svFrame.AbsolutePosition
            local absSize = svFrame.AbsoluteSize
            local nx = clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
            local ny = clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
            updateSVColor(nx, 1 - ny)
        end
    end)

    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            hueDragging = true
            local absPos = hueBar.AbsolutePosition
            local absSize = hueBar.AbsoluteSize
            local nx = clamp((input.Position.X - absPos.X) / absSize.X, 0, 0.999)
            updateHue(nx)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            if svDragging then
                local absPos = svFrame.AbsolutePosition
                local absSize = svFrame.AbsoluteSize
                local nx = clamp((input.Position.X - absPos.X) / absSize.X, 0, 1)
                local ny = clamp((input.Position.Y - absPos.Y) / absSize.Y, 0, 1)
                updateSVColor(nx, 1 - ny)
            end
            if hueDragging then
                local absPos = hueBar.AbsolutePosition
                local absSize = hueBar.AbsoluteSize
                local nx = clamp((input.Position.X - absPos.X) / absSize.X, 0, 0.999)
                updateHue(nx)
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            svDragging = false
            hueDragging = false
        end
    end)

    local function destroyCP()
        cpFrame.Visible = false
        pcall(function() cpFrame:Destroy() end)
    end

    Library._activeColorPicker = {
        Frame = cpFrame,
        Destroy = destroyCP,
    }

    updateSV()

    task.defer(function()
        local pos = config.Parent.AbsolutePosition
        local size = config.Parent.AbsoluteSize
        local cpSize = cpFrame.Size
        local newPos = UDim2.new(0, pos.X + size.X - cpSize.X.Offset - 4, 0, pos.Y)
        cpFrame.Position = newPos
    end)

    local function closeOnInput(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local hitCP = false
            pcall(function()
                local guiObjects = cpFrame:GetGuiObjectsAtPosition(
                    cpFrame.AbsolutePosition.X + (input.Position.X - cpFrame.AbsolutePosition.X),
                    cpFrame.AbsolutePosition.Y + (input.Position.Y - cpFrame.AbsolutePosition.Y)
                )
                for _, obj in ipairs(guiObjects) do
                    if obj:IsDescendantOf(cpFrame) then
                        hitCP = true
                        break
                    end
                end
            end)
            if not hitCP then
                destroyColorPicker()
                UserInputService.InputBegan:Once(closeOnInput)
            end
        elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
            destroyColorPicker()
            UserInputService.InputBegan:Once(closeOnInput)
        end
    end
    UserInputService.InputBegan:Once(closeOnInput)

    return destroyCP
end

-- ── Search ────────────────────────────────────────────────────────────────────

local function searchAll(query: string)
    Library._searchQuery = query:lower()
end

local function clearSearch()
    Library._searchQuery = nil
end

-- ── Notification ──────────────────────────────────────────────────────────────

function Library.Notify(config: {Title: string?, Content: string, Type: string?, Duration: number?})
    task.spawn(function()
        local notifDuration = config.Duration or 4
        local notifType = config.Type or "Info"

        local colorMap = {
            Info    = INFO,
            Success = SUCCESS,
            Warning = WARNING,
            Danger  = DANGER,
        }
        local notifColor = colorMap[notifType] or INFO

        local notifHolder = guiParent():FindFirstChild("IvoryNotifications")
        if not notifHolder then
            notifHolder = Instance.new("Frame")
            notifHolder.Name = "IvoryNotifications"
            notifHolder.BackgroundTransparency = 1
            notifHolder.Size = UDim2.new(0, 300, 1, 0)
            notifHolder.Position = UDim2.new(1, -320, 0, 20)
            notifHolder.ZIndex = 9999
            notifHolder.Parent = guiParent()
            local list = Instance.new("UIListLayout")
            list.Padding = UDim.new(0, 8)
            list.SortOrder = Enum.SortOrder.LayoutOrder
            list.VerticalAlignment = Enum.VerticalAlignment.Top
            list.Parent = notifHolder
            local pad = Instance.new("UIPadding")
            pad.PaddingRight = UDim.new(0, 12)
            pad.Parent = notifHolder
        end

        local notifCard = Instance.new("Frame")
        notifCard.Name = "Notif_" .. HttpService:GenerateGUID(false)
        notifCard.BackgroundColor3 = PLUM_ELEVATED
        notifCard.BorderSizePixel = 0
        notifCard.Size = UDim2.new(1, 0, 0, 0)
        notifCard.ZIndex = 10000
        notifCard.ClipsDescendants = true
        notifCard.Parent = notifHolder

        getCorner(notifCard, UDim.new(0, 8))
        getStroke(notifCard, notifColor, 1.5)

        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.BackgroundColor3 = notifColor
        accentBar.BorderSizePixel = 0
        accentBar.Size = UDim2.new(0, 3, 1, 0)
        accentBar.Position = UDim2.new(0, 0, 0, 0)
        accentBar.ZIndex = 10001
        accentBar.Parent = notifCard

        local contentFrame = Instance.new("Frame")
        contentFrame.Name = "ContentFrame"
        contentFrame.BackgroundTransparency = 1
        contentFrame.Position = UDim2.new(0, 12, 0, 0)
        contentFrame.Size = UDim2.new(1, -20, 1, 0)
        contentFrame.ZIndex = 10001
        contentFrame.Parent = notifCard

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "TitleLabel"
        titleLabel.BackgroundTransparency = 1
        titleLabel.Size = UDim2.new(1, 0, 0, 16)
        titleLabel.Position = UDim2.new(0, 0, 0, 6)
        titleLabel.Font = FONT_BOLD
        titleLabel.Text = config.Title or "Ivory"
        titleLabel.TextColor3 = TEXT_PRIMARY
        titleLabel.TextSize = 12
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.ZIndex = 10002
        titleLabel.Parent = contentFrame

        local typeIcon = Instance.new("TextLabel")
        typeIcon.Name = "TypeIcon"
        typeIcon.BackgroundTransparency = 1
        typeIcon.Size = UDim2.new(0, 20, 0, 16)
        typeIcon.Position = UDim2.new(1, -20, 0, 6)
        typeIcon.Font = FONT_BOLD
        typeIcon.Text = ({
            Info = "ℹ", Success = "✓", Warning = "⚠", Danger = "✕"
        })[notifType] or "ℹ"
        typeIcon.TextColor3 = notifColor
        typeIcon.TextSize = 12
        typeIcon.ZIndex = 10002
        typeIcon.Parent = contentFrame

        local bodyLabel = Instance.new("TextLabel")
        bodyLabel.Name = "BodyLabel"
        bodyLabel.BackgroundTransparency = 1
        bodyLabel.Size = UDim2.new(1, 0, 0, 0)
        bodyLabel.Position = UDim2.new(0, 0, 0, 22)
        bodyLabel.Font = FONT_MEDIUM
        bodyLabel.Text = config.Content
        bodyLabel.TextColor3 = TEXT_SECONDARY
        bodyLabel.TextSize = 11
        bodyLabel.TextWrapped = true
        bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
        bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
        bodyLabel.ZIndex = 10002
        bodyLabel.Parent = contentFrame

        local totalHeight = 22 + bodyLabel.TextBounds.Y + 12
        notifCard.Size = UDim2.new(1, 0, 0, 0)

        task.defer(function()
            createTween(notifCard, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 0, totalHeight)
            }):Play()
        end)

        task.delay(notifDuration, function()
            createTween(notifCard, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                Size = UDim2.new(1, 0, 0, 0),
            }):Play()
            task.delay(0.35, function()
                pcall(function() notifCard:Destroy() end)
            end)
        end)
    end)
end

-- ── Config Saving ─────────────────────────────────────────────────────────────

Library._config = {}
Library._configName = "IvoryHub"
Library._configAutosave = true
Library._configAutosaveInterval = 60

function Library.SetConfigName(name: string)
    Library._configName = name
end

function Library.SetAutosave(enabled: boolean, interval: number?)
    Library._configAutosave = enabled
    if interval then Library._configAutosaveInterval = interval end
end

function Library.SaveConfiguration(name: string?)
    local cfgName = name or Library._configName
    local cfgData = {}
    for key, value in pairs(Library._config) do
        if type(value) == "function" then
            cfgData[key] = nil
        else
            cfgData[key] = value
        end
    end
    local ok, encoded = pcall(function() return HttpService:JSONEncode(cfgData) end)
    if not ok then return end
    pcall(function()
        if writefile then
            writefile("IvoryHub/" .. cfgName .. ".json", encoded)
        end
    end)
end

function Library.LoadConfiguration(name: string?)
    local cfgName = name or Library._configName
    local raw = nil
    pcall(function()
        if readfile then
            raw = readfile("IvoryHub/" .. cfgName .. ".json")
        end
    end)
    if not raw then return end
    local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not ok or type(data) ~= "table" then return end
    for key, value in pairs(data) do
        Library._config[key] = value
    end
    Library._configLoaded = true
end

function Library.GetConfig()
    return Library._config
end

function Library.SetConfigValue(key: string, value: any)
    Library._config[key] = value
end

function Library.GetConfigValue(key: string, default: any): any
    return Library._config[key] or default
end

function Library.StartAutosave()
    if Library._configAutosaveThread then return end
    Library._configAutosaveThread = task.spawn(function()
        while Library._configAutosave do
            task.wait(Library._configAutosaveInterval)
            Library.SaveConfiguration()
        end
        Library._configAutosaveThread = nil
    end)
end

function Library.StopAutosave()
    Library._configAutosave = false
    if Library._configAutosaveThread then
        pcall(task.cancel, Library._configAutosaveThread)
        Library._configAutosaveThread = nil
    end
end

-- ── Theme Helpers ─────────────────────────────────────────────────────────────

local themeUpdateQueue = {}

local function onThemeChanged(callback)
    table.insert(themeUpdateQueue, callback)
end

local function notifyThemeChanged()
    for _, callback in ipairs(themeUpdateQueue) do
        pcall(callback)
    end
end

function Library.SetAccentColor(color: Color3)
    Library.Theme.AccentColor = color
    notifyThemeChanged()
end

function Library.SetMenuKeybind(keyCode: Enum.KeyCode)
    Library._menuKeybind = keyCode
end

function Library.GetAccentColor(): Color3
    return Library.Theme.AccentColor
end

-- ── Sound ─────────────────────────────────────────────────────────────────────

local function playClick()
    if not Library._soundClick then
        Library._soundClick = Instance.new("Sound")
        Library._soundClick.SoundId = "rbxassetid://130767489"
        Library._soundClick.Volume = 0.15
        Library._soundClick.Parent = guiParent()
    end
    Library._soundClick:Play()
end

-- ── Element Highlight ─────────────────────────────────────────────────────────

local function highlightElement(element: GuiObject)
    if Library._activeHighlight then
        Library._activeHighlight:Destroy()
    end
    local hl = Instance.new("Frame")
    hl.Name = "ElementHighlight"
    hl.AnchorPoint = Vector2.new(0.5, 0.5)
    hl.BackgroundTransparency = 0.92
    hl.BackgroundColor3 = Library.Theme.AccentColor
    hl.BorderSizePixel = 0
    hl.Position = UDim2.new(0.5, 0, 0.5, 0)
    hl.Size = UDim2.new(1, 6, 1, 6)
    hl.ZIndex = element.ZIndex - 1
    hl.Parent = element
    getCorner(hl, UDim.new(0, 8))
    Library._activeHighlight = hl
    Library._activeHighlightTime = tick()
    task.delay(0.4, function()
        if Library._activeHighlight == hl then
            createTween(hl, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = 1,
            }):Play()
            task.delay(0.35, function()
                if Library._activeHighlight == hl then
                    hl:Destroy()
                    Library._activeHighlight = nil
                end
            end)
        end
    end)
end

-- ── Internal: Element builders ────────────────────────────────────────────────

local function createElementContainer(parent: Frame, config: {Name: string?, Height: number?, ZIndex: number?})
    local holder = Instance.new("Frame")
    holder.Name = "Element_" .. (config.Name or "Unnamed")
    holder.BackgroundColor3 = PLUM_CARD
    holder.BorderSizePixel = 0
    holder.Size = UDim2.new(1, 0, config.Height or 0, 0)
    holder.AutomaticSize = if (config.Height or 0) == 0 then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
    holder.ZIndex = config.ZIndex or parent.ZIndex + 1
    holder.Parent = parent
    getCorner(holder, Library.Theme.CornerRadius)
    getStroke(holder, BORDER, Library.Theme.BorderThickness)
    return holder
end

local function createRow(parent: Frame, direction: Enum.FillDirection?, zindex: number?): Frame
    local row = Instance.new("Frame")
    row.Name = "Row"
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.ZIndex = zindex or parent.ZIndex + 1
    row.Parent = parent

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = direction or Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    layout.Parent = row

    local pad = getPadding(row, UDim.new(0, 4))
    return row
end

local function makeBase(parent: Frame, height: number?, zindex: number?): (Frame, number)
    local base = Instance.new("Frame")
    base.Name = "ElementBase"
    base.BackgroundTransparency = 1
    base.Size = UDim2.new(1, 0, height or 32, 0)
    base.ZIndex = zindex or parent.ZIndex + 1
    base.Parent = parent
    return base, base.ZIndex
end

local function createLabel(parent: Frame, text: string, font: Enum.Font?, size: number?, color: Color3?, zindex: number?): TextLabel
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Font = font or FONT_MEDIUM
    lbl.Text = text
    lbl.TextColor3 = color or TEXT_PRIMARY
    lbl.TextSize = size or 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = zindex or parent.ZIndex + 1
    lbl.Parent = parent
    return lbl
end

local function createToggleGraphics(parent: Frame, config: {CurrentValue: boolean, AccentColor: Color3?}, zindex: number?): (Frame, Frame, ImageLabel)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "ToggleFrame"
    toggleFrame.BackgroundColor3 = BORDER
    toggleFrame.Size = UDim2.new(0, 36, 0, 18)
    toggleFrame.ZIndex = zindex or parent.ZIndex + 1
    toggleFrame.Parent = parent
    getCorner(toggleFrame, UDim.new(1, 0))

    local toggleAccent = Instance.new("Frame")
    toggleAccent.Name = "ToggleAccent"
    toggleAccent.BackgroundColor3 = config.AccentColor or Library.Theme.AccentColor
    toggleAccent.Size = UDim2.new(0, 36, 0, 18)
    toggleAccent.BackgroundTransparency = config.CurrentValue and 0.2 or 1
    toggleAccent.ZIndex = zindex or parent.ZIndex + 2
    toggleAccent.Parent = toggleFrame
    getCorner(toggleAccent, UDim.new(1, 0))

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Name = "ToggleCircle"
    toggleCircle.BackgroundColor3 = TEXT_PRIMARY
    toggleCircle.Size = UDim2.new(0, 14, 0, 14)
    toggleCircle.Position = UDim2.new(0, config.CurrentValue and 20 or 2, 0.5, -7)
    toggleCircle.ZIndex = zindex or parent.ZIndex + 3
    toggleCircle.Parent = toggleFrame
    getCorner(toggleCircle, UDim.new(1, 0))

    return toggleFrame, toggleAccent, toggleCircle
end

-- ── Window ────────────────────────────────────────────────────────────────────

function Library.CreateWindow(config: WindowConfig | string?): Window
    if type(config) == "string" then
        config = {Name = config}
    end
    config = config or {} :: WindowConfig

    local WindowConfig = shallowMerge({
        Name            = "Ivory Hub",
        Width           = 460,
        Height          = 360,
        Resizable       = true,
        Stagger         = true,
        AutoSize        = true,
        NotifyPosition  = "Right",
        NotifyDuration  = 4,
        DragSpeed       = 0.15,
        CornerRadius    = UDim.new(0, 6),
        ToggleKeybind   = Enum.KeyCode.RightShift,
        CustomFont      = nil,
        Watermark       = false,
        WatermarkEnabled = true,
        AccentColor     = BLOSSOM_PINK,
        ConfigSaving    = true,
        ConfigName      = "IvoryHub",
        AutoSaveInterval = 60,
        MergedTabBar    = true,
    }, config or {})

    if WindowConfig.CustomFont then
        Library.Theme.CustomFont = WindowConfig.CustomFont
    end
    Library.Theme.CornerRadius = WindowConfig.CornerRadius
    Library._menuKeybind = WindowConfig.ToggleKeybind
    Library.Theme.AccentColor = WindowConfig.AccentColor

    local Window = {} :: Window
    setmetatable(Window, {
        __index = function(self, key)
            if key == "LoadConfiguration" then
                return function(_, name: string?)
                    Library.LoadConfiguration(name or WindowConfig.ConfigName)
                end
            end
            return rawget(self, key)
        end,
    })

    Window.Name = WindowConfig.Name
    Window.Tabs = {}
    Window.Elements = {}

    guiParent()

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = DEEP_PLUM
    mainFrame.BorderSizePixel = 0
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.Size = UDim2.new(0, WindowConfig.Width, 0, WindowConfig.Height)
    mainFrame.ZIndex = 100
    mainFrame.Parent = guiParent()
    mainFrame.ClipsDescendants = true
    Window.MainFrame = mainFrame
    Window.Container = mainFrame

    getCorner(mainFrame, WindowConfig.CornerRadius)
    getStroke(mainFrame, BORDER, 1)
    addShadow(mainFrame, 0.55)
    makeDraggable(mainFrame, mainFrame, true, WindowConfig.DragSpeed)

    local topBar = Instance.new("Frame")
    topBar.Name = "TopBar"
    topBar.BackgroundColor3 = TITLEBAR_BG
    topBar.BorderSizePixel = 0
    topBar.Size = UDim2.new(1, 0, 0, 34)
    topBar.ZIndex = 101
    topBar.Parent = mainFrame
    topBar.ClipsDescendants = true
    Window.TopBar = topBar
    makeDraggable(mainFrame, topBar, true, WindowConfig.DragSpeed)

    local topAccent = Instance.new("Frame")
    topAccent.Name = "AccentLine"
    topAccent.BackgroundColor3 = Library.Theme.AccentColor
    topAccent.BorderSizePixel = 0
    topAccent.Size = UDim2.new(1, 0, 0, 2)
    topAccent.Position = UDim2.new(0, 0, 1, -2)
    topAccent.ZIndex = 102
    topAccent.Parent = topBar

    onThemeChanged(function()
        topAccent.BackgroundColor3 = Library.Theme.AccentColor
    end)

    local topPad = getPadding(topBar, UDim.new(0, 8))

    local blossomIcon = Instance.new("ImageLabel")
    blossomIcon.Name = "BlossomIcon"
    blossomIcon.BackgroundTransparency = 1
    blossomIcon.Image = IVORY_BLOSSOM_ICON
    blossomIcon.ImageColor3 = Library.Theme.AccentColor
    blossomIcon.Size = UDim2.new(0, 18, 0, 18)
    blossomIcon.Position = UDim2.new(0, 4, 0.5, -9)
    blossomIcon.ScaleType = Enum.ScaleType.Fit
    blossomIcon.ZIndex = 102
    blossomIcon.Parent = topBar

    onThemeChanged(function()
        blossomIcon.ImageColor3 = Library.Theme.AccentColor
    end)

    local titleBox = Instance.new("TextLabel")
    titleBox.Name = "Title"
    titleBox.BackgroundTransparency = 1
    titleBox.Size = UDim2.new(0, 80, 1, 0)
    titleBox.Position = UDim2.new(0, 24, 0, 0)
    titleBox.Font = FONT_BOLD
    titleBox.Text = WindowConfig.Name
    titleBox.TextColor3 = TEXT_PRIMARY
    titleBox.TextSize = 14
    titleBox.TextXAlignment = Enum.TextXAlignment.Left
    titleBox.ZIndex = 102
    titleBox.Parent = topBar

    local versionLabel = Instance.new("TextLabel")
    versionLabel.Name = "VersionLabel"
    versionLabel.BackgroundTransparency = 1
    versionLabel.Size = UDim2.new(0, 50, 1, 0)
    versionLabel.Position = UDim2.new(0, titleBox.Position.X.Offset + TextService:GetTextSize(WindowConfig.Name, 14, FONT_BOLD, Vector2.new(500, 30)).X + 6, 0, 0)
    versionLabel.Font = FONT_LIGHT
    versionLabel.Text = Library.Version
    versionLabel.TextColor3 = TEXT_MUTED
    versionLabel.TextSize = 10
    versionLabel.TextXAlignment = Enum.TextXAlignment.Left
    versionLabel.ZIndex = 102
    versionLabel.Parent = topBar

    local SearchBox = Instance.new("TextBox")
    SearchBox.Name = "SearchBox"
    SearchBox.BackgroundColor3 = INPUT_BG
    SearchBox.Size = UDim2.new(0, 120, 0, 22)
    SearchBox.Position = UDim2.new(1, -252, 0.5, -11)
    SearchBox.Font = FONT_MEDIUM
    SearchBox.PlaceholderText = "Search..."
    SearchBox.PlaceholderColor3 = TEXT_MUTED
    SearchBox.Text = ""
    SearchBox.TextColor3 = TEXT_PRIMARY
    SearchBox.TextSize = 11
    SearchBox.ClearTextOnFocus = false
    SearchBox.BorderSizePixel = 0
    SearchBox.ZIndex = 102
    SearchBox.Parent = topBar
    getCorner(SearchBox, UDim.new(0, 4))
    getStroke(SearchBox, BORDER, 1)

    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchAll(SearchBox.Text)
    end)

    local searchIcon = Instance.new("TextLabel")
    searchIcon.Name = "SearchIcon"
    searchIcon.BackgroundTransparency = 1
    searchIcon.Size = UDim2.new(0, 16, 0, 16)
    searchIcon.Position = UDim2.new(0, 4, 0.5, -8)
    searchIcon.Font = FONT_BOLD
    searchIcon.Text = "⌕"
    searchIcon.TextColor3 = TEXT_MUTED
    searchIcon.TextSize = 12
    searchIcon.ZIndex = 103
    searchIcon.Parent = SearchBox

    local ctrlFHint = Instance.new("TextLabel")
    ctrlFHint.Name = "CtrlFHint"
    ctrlFHint.BackgroundTransparency = 1
    ctrlFHint.Size = UDim2.new(0, 30, 0, 22)
    ctrlFHint.Position = UDim2.new(1, -34, 0, 0)
    ctrlFHint.Font = FONT_LIGHT
    ctrlFHint.Text = "Ctrl+F"
    ctrlFHint.TextColor3 = TEXT_MUTED
    ctrlFHint.TextSize = 9
    ctrlFHint.ZIndex = 103
    ctrlFHint.Parent = SearchBox
    ctrlFHint.TextTransparency = 0.4

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.BackgroundColor3 = DANGER
    CloseBtn.BackgroundTransparency = 0.85
    CloseBtn.Size = UDim2.new(0, 18, 0, 18)
    CloseBtn.Position = UDim2.new(1, -26, 0.5, -9)
    CloseBtn.Font = FONT_BOLD
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = DANGER
    CloseBtn.TextSize = 10
    CloseBtn.ZIndex = 102
    CloseBtn.Parent = topBar
    getCorner(CloseBtn, UDim.new(1, 0))

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.BackgroundColor3 = WARNING
    MinimizeBtn.BackgroundTransparency = 0.85
    MinimizeBtn.Size = UDim2.new(0, 18, 0, 18)
    MinimizeBtn.Position = UDim2.new(1, -48, 0.5, -9)
    MinimizeBtn.Font = FONT_BOLD
    MinimizeBtn.Text = "—"
    MinimizeBtn.TextColor3 = WARNING
    MinimizeBtn.TextSize = 10
    MinimizeBtn.ZIndex = 102
    MinimizeBtn.Parent = topBar
    getCorner(MinimizeBtn, UDim.new(1, 0))

    local minimized = false
    local originalSize = mainFrame.Size
    local originalPos = mainFrame.Position

    MinimizeBtn.MouseButton1Click:Connect(function()
        playClick()
        minimized = not minimized
        if minimized then
            createTween(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 200, 0, 34),
            }):Play()
        else
            createTween(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = originalSize,
            }):Play()
        end
    end)

    local minimizedDragging = false
    MinimizeBtn.MouseButton1Down:Connect(function()
        minimizedDragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            minimizedDragging = false
        end
    end)

    local minimizedWindow = Instance.new("Frame")
    minimizedWindow.Name = "MinimizedWindow"
    minimizedWindow.BackgroundColor3 = DEEP_PLUM
    minimizedWindow.Size = UDim2.new(0, 200, 0, 34)
    minimizedWindow.Position = UDim2.new(0.5, -100, 0, 40)
    minimizedWindow.ZIndex = 150
    minimizedWindow.Visible = false
    minimizedWindow.Parent = guiParent()
    getCorner(minimizedWindow, WindowConfig.CornerRadius)
    getStroke(minimizedWindow, BORDER, 1)
    addShadow(minimizedWindow, 0.55)
    makeDraggable(minimizedWindow, minimizedWindow, true, 0.15)

    local miniBar = Instance.new("Frame")
    miniBar.Name = "MiniBar"
    miniBar.BackgroundColor3 = TITLEBAR_BG
    miniBar.Size = UDim2.new(1, 0, 0, 34)
    miniBar.ZIndex = 151
    miniBar.Parent = minimizedWindow
    miniBar.ClipsDescendants = true
    makeDraggable(minimizedWindow, miniBar, true, 0.15)

    local miniTitle = Instance.new("TextLabel")
    miniTitle.BackgroundTransparency = 1
    miniTitle.Size = UDim2.new(1, -28, 1, 0)
    miniTitle.Position = UDim2.new(0, 8, 0, 0)
    miniTitle.Font = FONT_BOLD
    miniTitle.Text = "  " .. WindowConfig.Name
    miniTitle.TextColor3 = TEXT_PRIMARY
    miniTitle.TextSize = 13
    miniTitle.TextXAlignment = Enum.TextXAlignment.Left
    miniTitle.ZIndex = 152
    miniTitle.Parent = miniBar

    local miniRestore = Instance.new("TextButton")
    miniRestore.Name = "RestoreBtn"
    miniRestore.BackgroundColor3 = SUCCESS
    miniRestore.BackgroundTransparency = 0.85
    miniRestore.Size = UDim2.new(0, 18, 0, 18)
    miniRestore.Position = UDim2.new(1, -26, 0.5, -9)
    miniRestore.Font = FONT_BOLD
    miniRestore.Text = "+"
    miniRestore.TextColor3 = SUCCESS
    miniRestore.TextSize = 10
    miniRestore.ZIndex = 152
    miniRestore.Parent = miniBar
    getCorner(miniRestore, UDim.new(1, 0))

    miniRestore.MouseButton1Click:Connect(function()
        playClick()
        minimized = false
        minimizedWindow.Visible = false
        mainFrame.Visible = true
        createTween(mainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = originalSize,
            Position = originalPos,
        }):Play()
    end)

    local updateMinimize = function()
        mainFrame.Visible = not minimized
        minimizedWindow.Visible = minimized
        if minimized then
            mainFrame.Size = UDim2.new(0, 200, 0, 34)
        else
            mainFrame.Size = originalSize
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(updateMinimize)
    miniRestore.MouseButton1Click:Connect(function() updateMinimize() end)

    local TabsContainer = Instance.new("Frame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.BackgroundTransparency = 1
    TabsContainer.Size = UDim2.new(1, -12, 1, -42)
    TabsContainer.Position = UDim2.new(0, 6, 0, 38)
    TabsContainer.ZIndex = 101
    TabsContainer.Parent = mainFrame

    local TabsLayout = Instance.new("UIListLayout")
    TabsLayout.Name = "TabsLayout"
    TabsLayout.Padding = UDim.new(0, 4)
    TabsLayout.FillDirection = Enum.FillDirection.Horizontal
    TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    TabsLayout.Parent = TabsContainer

    local TabsPad = getPadding(TabsContainer, UDim.new(0, 2))

    local PagesContainer = Instance.new("Frame")
    PagesContainer.Name = "PagesContainer"
    PagesContainer.BackgroundTransparency = 1
    PagesContainer.Size = UDim2.new(1, -12, 1, -82)
    PagesContainer.Position = UDim2.new(0, 6, 0, 44)
    PagesContainer.ZIndex = 101
    PagesContainer.ClipsDescendants = true
    PagesContainer.Parent = mainFrame

    local PagesPad = getPadding(PagesContainer, UDim.new(0, 2))

    local activeTab = nil
    local tabCount = 0

    function Window.CreateTab(self, tabConfig: string | {Name: string, Icon: string?}): Tab
        local name, icon
        if type(tabConfig) == "string" then
            name = tabConfig
            icon = nil
        else
            name = tabConfig.Name
            icon = tabConfig.Icon
        end

        tabCount += 1

        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. name
        tabButton.BackgroundColor3 = PLUM_CARD
        tabButton.BackgroundTransparency = 0.8
        tabButton.Size = UDim2.new(0, 0, 0, 28)
        tabButton.AutomaticSize = Enum.AutomaticSize.X
        tabButton.Font = FONT_MEDIUM
        tabButton.Text = "   " .. name
        tabButton.TextColor3 = TEXT_SECONDARY
        tabButton.TextSize = 12
        tabButton.LayoutOrder = tabCount
        tabButton.ZIndex = 102
        tabButton.AutoButtonColor = false
        tabButton.Parent = TabsContainer
        getCorner(tabButton, UDim.new(0, 6))

        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Name = "TabContent_" .. name
        tabContent.BackgroundTransparency = 1
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.ScrollBarThickness = 3
        tabContent.ScrollBarImageColor3 = Library.Theme.AccentColor
        tabContent.ScrollBarImageTransparency = 0.4
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        tabContent.AutomaticCanvasSize = Enum.AutomaticCanvasSize.Y
        tabContent.ElasticBehavior = Enum.ElasticBehavior.Never
        tabContent.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        tabContent.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
        tabContent.ZIndex = 102
        tabContent.BorderSizePixel = 0
        tabContent.Visible = false
        tabContent.Parent = PagesContainer
        getCorner(tabContent, UDim.new(0, 6))

        local tabContentLayout = Instance.new("UIListLayout")
        tabContentLayout.Padding = UDim.new(0, 4)
        tabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        tabContentLayout.Parent = tabContent

        local tabContentPad = getPadding(tabContent, UDim.new(0, 4))

        local Tab = {} :: Tab
        Tab.Name = name
        Tab.Icon = icon
        Tab.Active = false
        Tab.Elements = {}
        Tab.Container = tabContent
        Tab.TabButton = tabButton

        if icon then
            local iconLabel = Instance.new("TextLabel")
            iconLabel.Name = "Icon"
            iconLabel.BackgroundTransparency = 1
            iconLabel.Size = UDim2.new(0, 16, 0, 16)
            iconLabel.Position = UDim2.new(0, 6, 0.5, -8)
            iconLabel.Font = FONT_BOLD
            iconLabel.Text = icon
            iconLabel.TextColor3 = TEXT_MUTED
            iconLabel.TextSize = 10
            iconLabel.ZIndex = 103
            iconLabel.Parent = tabButton
        end

        local function activateTab()
            if activeTab then
                activeTab.Active = false
                activeTab.TabButton.BackgroundTransparency = 0.8
                activeTab.TabButton.TextColor3 = TEXT_SECONDARY
                activeTab.Container.Visible = false
                local prevIcon = activeTab.TabButton:FindFirstChild("Icon")
                if prevIcon then prevIcon.TextColor3 = TEXT_MUTED end
            end
            Tab.Active = true
            activeTab = Tab
            Tab.ButtonBackgroundTransparency = 0
            Tab.TabButton.BackgroundTransparency = 0
            Tab.TabButton.BackgroundColor3 = Library.Theme.AccentColor
            Tab.TabButton.BackgroundTransparency = 0.85
            Tab.TabButton.TextColor3 = TEXT_PRIMARY
            Tab.Container.Visible = true
            local curIcon = Tab.TabButton:FindFirstChild("Icon")
            if curIcon then curIcon.TextColor3 = Library.Theme.AccentColor end
        end

        onThemeChanged(function()
            if Tab.Active then
                Tab.TabButton.BackgroundColor3 = Library.Theme.AccentColor
                local ci = Tab.TabButton:FindFirstChild("Icon")
                if ci then ci.TextColor3 = Library.Theme.AccentColor end
            end
        end)

        tabButton.MouseButton1Click:Connect(function()
            playClick()
            activateTab()
        end)

        if not activeTab then
            activateTab()
        end

        local sectionOrder = 0

        function Tab.CreateSection(self, sectionName: string): Section
            sectionOrder += 1

            local section = {} :: Section
            section.Name = sectionName
            section.Elements = {}

            local sectionFrame = Instance.new("Frame")
            sectionFrame.Name = "Section_" .. sectionName
            sectionFrame.BackgroundColor3 = PLUM_CARD
            sectionFrame.BackgroundTransparency = 0.2
            sectionFrame.Size = UDim2.new(1, 0, 0, 0)
            sectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            sectionFrame.ZIndex = 103
            sectionFrame.LayoutOrder = sectionOrder
            sectionFrame.Parent = tabContent
            getCorner(sectionFrame, UDim.new(0, 6))
            getStroke(sectionFrame, BORDER, 1)

            local sectionPad = getPadding(sectionFrame, UDim.new(0, 6))

            local sectionHeader = Instance.new("TextLabel")
            sectionHeader.Name = "SectionHeader"
            sectionHeader.BackgroundTransparency = 1
            sectionHeader.Size = UDim2.new(1, 0, 0, 20)
            sectionHeader.Font = FONT_BOLD
            sectionHeader.Text = " " .. sectionName
            sectionHeader.TextColor3 = Library.Theme.AccentColor
            sectionHeader.TextSize = 11
            sectionHeader.TextXAlignment = Enum.TextXAlignment.Left
            sectionHeader.ZIndex = 104
            sectionHeader.Parent = sectionFrame

            onThemeChanged(function()
                sectionHeader.TextColor3 = Library.Theme.AccentColor
            end)

            local sectionContent = Instance.new("Frame")
            sectionContent.Name = "Content"
            sectionContent.BackgroundTransparency = 1
            sectionContent.Size = UDim2.new(1, 0, 0, 0)
            sectionContent.AutomaticSize = Enum.AutomaticSize.Y
            sectionContent.ZIndex = 104
            sectionContent.LayoutOrder = 2
            sectionContent.Parent = sectionFrame

            local sectionLayout = Instance.new("UIListLayout")
            sectionLayout.Padding = UDim.new(0, 4)
            sectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            sectionLayout.Parent = sectionContent

            section.Container = sectionContent

            local elemOrder = 0

            local function addElement(elem)
                elemOrder += 1
                elem.LayoutOrder = elemOrder
                elem.Parent = sectionContent
                table.insert(section.Elements, elem)
                table.insert(Tab.Elements, elem)
                table.insert(Window.Elements, elem)
            end

            function Section.CreateButton(self, btnConfig: ButtonConfig): Button
                local cfg = shallowMerge({
                    Name     = "Button",
                    Callback = function() end,
                }, btnConfig)

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local btnFrame = Instance.new("TextButton")
                btnFrame.Name = "Btn_" .. cfg.Name
                btnFrame.BackgroundColor3 = PLUM_ELEVATED
                btnFrame.Size = UDim2.new(1, 0, 1, 0)
                btnFrame.Font = FONT_MEDIUM
                btnFrame.Text = "  " .. cfg.Name
                btnFrame.TextColor3 = TEXT_PRIMARY
                btnFrame.TextSize = 12
                btnFrame.TextXAlignment = Enum.TextXAlignment.Left
                btnFrame.ZIndex = zIdx + 1
                btnFrame.AutoButtonColor = false
                btnFrame.Parent = base
                getCorner(btnFrame, UDim.new(0, 4))

                btnFrame.MouseEnter:Connect(function()
                    createTween(btnFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = PLUM_HOVER,
                    }):Play()
                end)
                btnFrame.MouseLeave:Connect(function()
                    createTween(btnFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                        BackgroundColor3 = PLUM_ELEVATED,
                    }):Play()
                end)
                btnFrame.MouseButton1Click:Connect(function()
                    playClick()
                    highlightElement(btnFrame)
                    cfg.Callback()
                end)

                local btn = {} :: Button
                btn.Name = cfg.Name
                btn.Container = base
                btn.Callback = cfg.Callback
                function btn:SetText(t) btnFrame.Text = "  " .. t end
                function btn:SetCallback(cb) btn.Callback = cb end
                function btn:Destroy() base:Destroy() end

                addElement(base)
                return btn
            end

            function Section.CreateToggle(self, togConfig: ToggleConfig): Toggle
                local cfg = shallowMerge({
                    Name         = "Toggle",
                    CurrentValue = false,
                    Callback     = function(v: boolean) end,
                }, togConfig)

                local configKey = "toggle_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    cfg.CurrentValue = Library._config[configKey]
                end

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local toggleBg = Instance.new("TextButton")
                toggleBg.Name = "ToggleBg_" .. cfg.Name
                toggleBg.BackgroundColor3 = Color3.new(0, 0, 0)
                toggleBg.BackgroundTransparency = 1
                toggleBg.Size = UDim2.new(1, 0, 1, 0)
                toggleBg.Font = FONT_MEDIUM
                toggleBg.Text = ""
                toggleBg.ZIndex = zIdx + 1
                toggleBg.AutoButtonColor = false
                toggleBg.Parent = base

                local toggleLabel = Instance.new("TextLabel")
                toggleLabel.Name = "ToggleLabel"
                toggleLabel.BackgroundTransparency = 1
                toggleLabel.Size = UDim2.new(1, -48, 1, 0)
                toggleLabel.Position = UDim2.new(0, 8, 0, 0)
                toggleLabel.Font = FONT_MEDIUM
                toggleLabel.Text = cfg.Name
                toggleLabel.TextColor3 = TEXT_PRIMARY
                toggleLabel.TextSize = 12
                toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                toggleLabel.ZIndex = zIdx + 1
                toggleLabel.Parent = toggleBg

                local toggleFrame, toggleAccent, toggleCircle = createToggleGraphics(toggleBg, {
                    CurrentValue = cfg.CurrentValue,
                    AccentColor = Library.Theme.AccentColor,
                }, zIdx + 1)

                toggleFrame.Position = UDim2.new(1, -44, 0.5, -9)

                local function updateToggleVisuals(value: boolean)
                    createTween(toggleCircle, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, value and 20 or 2, 0.5, -7),
                    }):Play()
                    createTween(toggleAccent, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = value and 0.2 or 1,
                    }):Play()
                end

                updateToggleVisuals(cfg.CurrentValue)

                onThemeChanged(function()
                    if cfg.CurrentValue then
                        toggleAccent.BackgroundColor3 = Library.Theme.AccentColor
                    end
                end)

                local function toggleCallback()
                    cfg.CurrentValue = not cfg.CurrentValue
                    updateToggleVisuals(cfg.CurrentValue)
                    Library.SetConfigValue(configKey, cfg.CurrentValue)
                    cfg.Callback(cfg.CurrentValue)
                end

                toggleBg.MouseButton1Click:Connect(function()
                    playClick()
                    highlightElement(toggleBg)
                    toggleCallback()
                end)

                local toggle = {} :: Toggle
                toggle.Name = cfg.Name
                toggle.CurrentValue = cfg.CurrentValue
                toggle.Container = base
                toggle.Callback = cfg.Callback

                function toggle:SetValue(value: boolean)
                    cfg.CurrentValue = value
                    toggle.CurrentValue = value
                    updateToggleVisuals(value)
                    Library.SetConfigValue(configKey, value)
                    cfg.Callback(value)
                end

                function toggle:SetCallback(callback)
                    cfg.Callback = callback
                    toggle.Callback = callback
                end

                function toggle:Destroy()
                    base:Destroy()
                end

                addElement(base)
                return toggle
            end

            function Section.CreateSlider(self, sliderConfig: SliderConfig): Slider
                local cfg = shallowMerge({
                    Name         = "Slider",
                    Range        = {0, 100},
                    Increment    = 1,
                    CurrentValue = 50,
                    Callback     = function(v: number) end,
                }, sliderConfig)

                local configKey = "slider_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    cfg.CurrentValue = Library._config[configKey]
                end

                local base, zIdx = makeBase(sectionContent, 38, 104)

                local sliderLabel = Instance.new("TextLabel")
                sliderLabel.Name = "SliderLabel"
                sliderLabel.BackgroundTransparency = 1
                sliderLabel.Size = UDim2.new(0.5, 0, 0, 16)
                sliderLabel.Position = UDim2.new(0, 8, 0, 2)
                sliderLabel.Font = FONT_MEDIUM
                sliderLabel.Text = cfg.Name
                sliderLabel.TextColor3 = TEXT_PRIMARY
                sliderLabel.TextSize = 12
                sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                sliderLabel.ZIndex = zIdx + 1
                sliderLabel.Parent = base

                local valueLabel = Instance.new("TextLabel")
                valueLabel.Name = "ValueLabel"
                valueLabel.BackgroundTransparency = 1
                valueLabel.Size = UDim2.new(0.5, -8, 0, 16)
                valueLabel.Position = UDim2.new(0.5, 0, 0, 2)
                valueLabel.Font = FONT_MEDIUM
                valueLabel.Text = tostring(cfg.CurrentValue)
                valueLabel.TextColor3 = Library.Theme.AccentColor
                valueLabel.TextSize = 12
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.ZIndex = zIdx + 1
                valueLabel.Parent = base

                onThemeChanged(function()
                    valueLabel.TextColor3 = Library.Theme.AccentColor
                end)

                local sliderBar = Instance.new("Frame")
                sliderBar.Name = "SliderBar"
                sliderBar.BackgroundColor3 = PLUM_HOVER
                sliderBar.Size = UDim2.new(1, -16, 0, 6)
                sliderBar.Position = UDim2.new(0, 8, 0, 24)
                sliderBar.ZIndex = zIdx + 1
                sliderBar.Parent = base
                getCorner(sliderBar, UDim.new(1, 0))

                local sliderFill = Instance.new("Frame")
                sliderFill.Name = "SliderFill"
                sliderFill.BackgroundColor3 = Library.Theme.AccentColor
                sliderFill.Size = UDim2.new(
                    map(cfg.CurrentValue, cfg.Range[1], cfg.Range[2], 0, 1),
                    0,
                    1, 0
                )
                sliderFill.ZIndex = zIdx + 2
                sliderFill.Parent = sliderBar
                getCorner(sliderFill, UDim.new(1, 0))

                onThemeChanged(function()
                    sliderFill.BackgroundColor3 = Library.Theme.AccentColor
                end)

                local sliderKnob = Instance.new("Frame")
                sliderKnob.Name = "SliderKnob"
                sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
                sliderKnob.BackgroundColor3 = TEXT_PRIMARY
                sliderKnob.Size = UDim2.new(0, 12, 0, 12)
                sliderKnob.Position = UDim2.new(
                    map(cfg.CurrentValue, cfg.Range[1], cfg.Range[2], 0, 1),
                    0,
                    0.5, 0
                )
                sliderKnob.ZIndex = zIdx + 3
                sliderKnob.Parent = sliderBar
                getCorner(sliderKnob, UDim.new(1, 0))
                getStroke(sliderKnob, Library.Theme.AccentColor, 2)

                onThemeChanged(function()
                    local ok, _ = pcall(function()
                        sliderKnob:FindFirstChildWhichIsA("UIStroke").Color = Library.Theme.AccentColor
                    end)
                end)

                local function updateSlider(inputX: number)
                    local absPos = sliderBar.AbsolutePosition.X
                    local absSize = sliderBar.AbsoluteSize.X
                    local fraction = clamp((inputX - absPos) / absSize, 0, 1)
                    local rawVal = lerp(cfg.Range[1], cfg.Range[2], fraction)
                    local stepped = round(rawVal / cfg.Increment) * cfg.Increment
                    local clamped = clamp(stepped, cfg.Range[1], cfg.Range[2])
                    cfg.CurrentValue = clamped

                    sliderFill.Size = UDim2.new(map(clamped, cfg.Range[1], cfg.Range[2], 0, 1), 0, 1, 0)
                    sliderKnob.Position = UDim2.new(map(clamped, cfg.Range[1], cfg.Range[2], 0, 1), 0, 0.5, 0)
                    valueLabel.Text = tostring(clamped)

                    Library.SetConfigValue(configKey, clamped)
                    cfg.Callback(clamped)
                end

                local draggingSlider = false

                sliderBar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true
                        updateSlider(input.Position.X)
                    end
                end)

                sliderKnob.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true
                        updateSlider(input.Position.X)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateSlider(input.Position.X)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = false
                    end
                end)

                local slider = {} :: Slider
                slider.Name = cfg.Name
                slider.CurrentValue = cfg.CurrentValue
                slider.Min = cfg.Range[1]
                slider.Max = cfg.Range[2]
                slider.Increment = cfg.Increment
                slider.Container = base
                slider.Callback = cfg.Callback

                function slider:SetValue(value: number)
                    local clamped = clamp(round(value / cfg.Increment) * cfg.Increment, cfg.Range[1], cfg.Range[2])
                    cfg.CurrentValue = clamped
                    slider.CurrentValue = clamped
                    sliderFill.Size = UDim2.new(map(clamped, cfg.Range[1], cfg.Range[2], 0, 1), 0, 1, 0)
                    sliderKnob.Position = UDim2.new(map(clamped, cfg.Range[1], cfg.Range[2], 0, 1), 0, 0.5, 0)
                    valueLabel.Text = tostring(clamped)
                    Library.SetConfigValue(configKey, clamped)
                    cfg.Callback(clamped)
                end

                function slider:SetCallback(callback)
                    cfg.Callback = callback
                    slider.Callback = callback
                end

                function slider:Destroy() base:Destroy() end

                addElement(base)
                return slider
            end

            function Section.CreateDropdown(self, dropConfig: DropdownConfig): Dropdown
                local cfg = shallowMerge({
                    Name          = "Dropdown",
                    Options       = {},
                    CurrentOption = "",
                    Callback      = function(option: string) end,
                }, dropConfig)

                local configKey = "dropdown_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    cfg.CurrentOption = Library._config[configKey]
                end

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local dropLabel = Instance.new("TextLabel")
                dropLabel.Name = "DropLabel"
                dropLabel.BackgroundTransparency = 1
                dropLabel.Size = UDim2.new(0.4, 0, 1, 0)
                dropLabel.Position = UDim2.new(0, 8, 0, 0)
                dropLabel.Font = FONT_MEDIUM
                dropLabel.Text = cfg.Name
                dropLabel.TextColor3 = TEXT_PRIMARY
                dropLabel.TextSize = 12
                dropLabel.TextXAlignment = Enum.TextXAlignment.Left
                dropLabel.ZIndex = zIdx + 1
                dropLabel.Parent = base

                local dropBtn = Instance.new("TextButton")
                dropBtn.Name = "DropBtn"
                dropBtn.BackgroundColor3 = PLUM_HOVER
                dropBtn.Size = UDim2.new(0.58, 0, 0, 24)
                dropBtn.Position = UDim2.new(0.4, 0, 0.5, -12)
                dropBtn.Font = FONT_MEDIUM
                dropBtn.Text = " " .. (cfg.CurrentOption ~= "" and cfg.CurrentOption or "Select...")
                dropBtn.TextColor3 = cfg.CurrentOption ~= "" and TEXT_PRIMARY or TEXT_MUTED
                dropBtn.TextSize = 11
                dropBtn.TextXAlignment = Enum.TextXAlignment.Left
                dropBtn.ZIndex = zIdx + 1
                dropBtn.AutoButtonColor = false
                dropBtn.Parent = base
                getCorner(dropBtn, UDim.new(0, 4))

                local dropArrow = Instance.new("TextLabel")
                dropArrow.Name = "DropArrow"
                dropArrow.BackgroundTransparency = 1
                dropArrow.Size = UDim2.new(0, 16, 0, 16)
                dropArrow.Position = UDim2.new(1, -18, 0.5, -8)
                dropArrow.Font = FONT_BOLD
                dropArrow.Text = "▼"
                dropArrow.TextColor3 = TEXT_MUTED
                dropArrow.TextSize = 8
                dropArrow.ZIndex = zIdx + 2
                dropArrow.Parent = dropBtn

                local isDropped = false

                local function refreshDropdownText()
                    local current = cfg.CurrentOption
                    if current ~= "" then
                        dropBtn.Text = " " .. current
                        dropBtn.TextColor3 = TEXT_PRIMARY
                    else
                        dropBtn.Text = " Select..."
                        dropBtn.TextColor3 = TEXT_MUTED
                    end
                end

                dropBtn.MouseButton1Click:Connect(function()
                    playClick()
                    highlightElement(dropBtn)
                    isDropped = not isDropped
                    createTween(dropArrow, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = isDropped and 180 or 0,
                    }):Play()

                    if isDropped then
                        openDropdown({
                            Parent     = dropBtn,
                            Options    = cfg.Options,
                            CurrentOption = cfg.CurrentOption,
                            Callback   = function(option)
                                cfg.CurrentOption = option
                                refreshDropdownText()
                                Library.SetConfigValue(configKey, option)
                                cfg.Callback(option)
                            end,
                            ZIndex     = zIdx + 10,
                            Scrollable = true,
                        })
                    else
                        closeDropdown()
                    end
                end)

                dropBtn.MouseLeave:Connect(function()
                    task.delay(0.25, function()
                        if not dropBtn:IsDescendantOf(game) then return end
                        local mousePos = UserInputService:GetMouseLocation()
                        local btnPos = dropBtn.AbsolutePosition
                        local btnSize = dropBtn.AbsoluteSize
                        if mousePos.X < btnPos.X or mousePos.X > btnPos.X + btnSize.X
                            or mousePos.Y < btnPos.Y or mousePos.Y > btnPos.Y + btnSize.Y then
                            if isDropped then
                                isDropped = false
                                createTween(dropArrow, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                    Rotation = 0,
                                }):Play()
                                closeDropdown()
                            end
                        end
                    end)
                end)

                local dropdown = {} :: Dropdown
                dropdown.Name = cfg.Name
                dropdown.CurrentOption = cfg.CurrentOption
                dropdown.Options = cfg.Options
                dropdown.Container = base
                dropdown.Callback = cfg.Callback

                function dropdown:SetOptions(options: {string})
                    cfg.Options = options
                    dropdown.Options = options
                    if not table.find(options, cfg.CurrentOption) then
                        cfg.CurrentOption = options[1] or ""
                        dropdown.CurrentOption = cfg.CurrentOption
                        refreshDropdownText()
                    end
                end

                function dropdown:SetValue(value: string)
                    cfg.CurrentOption = value
                    dropdown.CurrentOption = value
                    refreshDropdownText()
                    Library.SetConfigValue(configKey, value)
                    cfg.Callback(value)
                end

                function dropdown:SetCallback(callback)
                    cfg.Callback = callback
                    dropdown.Callback = callback
                end

                function dropdown:Destroy() base:Destroy() end

                addElement(base)
                return dropdown
            end

            function Section.CreateMultiDropdown(self, multiConfig: MultiDropdownConfig): MultiDropdown
                local cfg = shallowMerge({
                    Name          = "MultiDropdown",
                    Options       = {},
                    CurrentOption = {},
                    Callback      = function(options: {string}) end,
                }, multiConfig)

                local configKey = "multi_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    cfg.CurrentOption = Library._config[configKey]
                end

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local multiLabel = Instance.new("TextLabel")
                multiLabel.Name = "MultiLabel"
                multiLabel.BackgroundTransparency = 1
                multiLabel.Size = UDim2.new(0.4, 0, 1, 0)
                multiLabel.Position = UDim2.new(0, 8, 0, 0)
                multiLabel.Font = FONT_MEDIUM
                multiLabel.Text = cfg.Name
                multiLabel.TextColor3 = TEXT_PRIMARY
                multiLabel.TextSize = 12
                multiLabel.TextXAlignment = Enum.TextXAlignment.Left
                multiLabel.ZIndex = zIdx + 1
                multiLabel.Parent = base

                local multiBtn = Instance.new("TextButton")
                multiBtn.Name = "MultiBtn"
                multiBtn.BackgroundColor3 = PLUM_HOVER
                multiBtn.Size = UDim2.new(0.58, 0, 0, 24)
                multiBtn.Position = UDim2.new(0.4, 0, 0.5, -12)
                multiBtn.Font = FONT_MEDIUM
                multiBtn.Text = " Select..."
                multiBtn.TextColor3 = TEXT_MUTED
                multiBtn.TextSize = 11
                multiBtn.TextXAlignment = Enum.TextXAlignment.Left
                multiBtn.ZIndex = zIdx + 1
                multiBtn.AutoButtonColor = false
                multiBtn.Parent = base
                getCorner(multiBtn, UDim.new(0, 4))

                local multiArrow = Instance.new("TextLabel")
                multiArrow.Name = "MultiArrow"
                multiArrow.BackgroundTransparency = 1
                multiArrow.Size = UDim2.new(0, 16, 0, 16)
                multiArrow.Position = UDim2.new(1, -18, 0.5, -8)
                multiArrow.Font = FONT_BOLD
                multiArrow.Text = "▼"
                multiArrow.TextColor3 = TEXT_MUTED
                multiArrow.TextSize = 8
                multiArrow.ZIndex = zIdx + 2
                multiArrow.Parent = multiBtn

                local function refreshMultiText()
                    if #cfg.CurrentOption > 0 then
                        local display = table.concat(cfg.CurrentOption, ", ")
                        if #display > 20 then
                            display = display:sub(1, 18) .. ".."
                        end
                        multiBtn.Text = " " .. display
                        multiBtn.TextColor3 = TEXT_PRIMARY
                    else
                        multiBtn.Text = " Select..."
                        multiBtn.TextColor3 = TEXT_MUTED
                    end
                end

                local isDropped = false

                multiBtn.MouseButton1Click:Connect(function()
                    playClick()
                    highlightElement(multiBtn)
                    isDropped = not isDropped
                    createTween(multiArrow, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Rotation = isDropped and 180 or 0,
                    }):Play()

                    if isDropped then
                        openDropdown({
                            Parent     = multiBtn,
                            Options    = cfg.Options,
                            CurrentOption = "",
                            Callback   = function(selected)
                                if type(selected) == "table" then
                                    cfg.CurrentOption = selected
                                else
                                    local idx = table.find(cfg.CurrentOption, selected)
                                    if idx then
                                        table.remove(cfg.CurrentOption, idx)
                                    else
                                        table.insert(cfg.CurrentOption, selected)
                                    end
                                end
                                refreshMultiText()
                                Library.SetConfigValue(configKey, cfg.CurrentOption)
                                cfg.Callback(cfg.CurrentOption)
                            end,
                            ZIndex     = zIdx + 10,
                            Scrollable = true,
                            Multi      = true,
                            CurrentOptions = cfg.CurrentOption,
                        })
                    else
                        closeDropdown()
                    end
                end)

                multiBtn.MouseLeave:Connect(function()
                    task.delay(0.25, function()
                        if not multiBtn:IsDescendantOf(game) then return end
                        local mousePos = UserInputService:GetMouseLocation()
                        local btnPos = multiBtn.AbsolutePosition
                        local btnSize = multiBtn.AbsoluteSize
                        if mousePos.X < btnPos.X or mousePos.X > btnPos.X + btnSize.X
                            or mousePos.Y < btnPos.Y or mousePos.Y > btnPos.Y + btnSize.Y then
                            if isDropped then
                                isDropped = false
                                createTween(multiArrow, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                    Rotation = 0,
                                }):Play()
                                closeDropdown()
                            end
                        end
                    end)
                end)

                local multi = {} :: MultiDropdown
                multi.Name = cfg.Name
                multi.CurrentOption = cfg.CurrentOption
                multi.Options = cfg.Options
                multi.Container = base
                multi.Callback = cfg.Callback

                function multi:SetOptions(options: {string})
                    cfg.Options = options
                    multi.Options = options
                    local newSelected = {}
                    for _, opt in ipairs(cfg.CurrentOption) do
                        if table.find(options, opt) then
                            table.insert(newSelected, opt)
                        end
                    end
                    cfg.CurrentOption = newSelected
                    multi.CurrentOption = newSelected
                    refreshMultiText()
                end

                function multi:SetValue(values: {string})
                    cfg.CurrentOption = values
                    multi.CurrentOption = values
                    refreshMultiText()
                    Library.SetConfigValue(configKey, values)
                    cfg.Callback(values)
                end

                function multi:SetCallback(callback)
                    cfg.Callback = callback
                    multi.Callback = callback
                end

                function multi:Destroy() base:Destroy() end

                addElement(base)
                return multi
            end

            function Section.CreateColorPicker(self, cpConfig: ColorPickerConfig): ColorPicker
                local cfg = shallowMerge({
                    Name  = "ColorPicker",
                    Color = BLOSSOM_PINK,
                    Callback = function(color: Color3) end,
                }, cpConfig)

                local configKey = "color_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    local v = Library._config[configKey]
                    if typeof(v) == "Color3" then
                        cfg.Color = v
                    elseif type(v) == "string" then
                        pcall(function() cfg.Color = Color3.fromHex(v) end)
                    end
                end

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local cpLabel = Instance.new("TextLabel")
                cpLabel.Name = "CPLabel"
                cpLabel.BackgroundTransparency = 1
                cpLabel.Size = UDim2.new(0.6, 0, 1, 0)
                cpLabel.Position = UDim2.new(0, 8, 0, 0)
                cpLabel.Font = FONT_MEDIUM
                cpLabel.Text = cfg.Name
                cpLabel.TextColor3 = TEXT_PRIMARY
                cpLabel.TextSize = 12
                cpLabel.TextXAlignment = Enum.TextXAlignment.Left
                cpLabel.ZIndex = zIdx + 1
                cpLabel.Parent = base

                local cpSwatch = Instance.new("TextButton")
                cpSwatch.Name = "CPSwatch"
                cpSwatch.BackgroundColor3 = cfg.Color
                cpSwatch.Size = UDim2.new(0, 24, 0, 24)
                cpSwatch.Position = UDim2.new(1, -32, 0.5, -12)
                cpSwatch.ZIndex = zIdx + 1
                cpSwatch.Text = ""
                cpSwatch.AutoButtonColor = false
                cpSwatch.Parent = base
                getCorner(cpSwatch, UDim.new(0, 4))
                getStroke(cpSwatch, BORDER, 1)

                local cpOpen = false

                cpSwatch.MouseButton1Click:Connect(function()
                    playClick()
                    highlightElement(cpSwatch)
                    cpOpen = not cpOpen
                    if cpOpen then
                        openColorPicker({
                            Parent   = cpSwatch,
                            Color    = cfg.Color,
                            Callback = function(color)
                                cfg.Color = color
                                cpSwatch.BackgroundColor3 = color
                                Library.SetConfigValue(configKey, color)
                                cfg.Callback(color)
                            end,
                            ZIndex   = zIdx + 10,
                        })
                    else
                        destroyColorPicker()
                    end
                end)

                cpSwatch.MouseLeave:Connect(function()
                    task.delay(0.3, function()
                        if not cpSwatch:IsDescendantOf(game) then return end
                        local mousePos = UserInputService:GetMouseLocation()
                        local swatchPos = cpSwatch.AbsolutePosition
                        local swatchSize = cpSwatch.AbsoluteSize
                        if mousePos.X < swatchPos.X or mousePos.X > swatchPos.X + swatchSize.X
                            or mousePos.Y < swatchPos.Y or mousePos.Y > swatchPos.Y + swatchSize.Y then
                            if cpOpen then
                                cpOpen = false
                                destroyColorPicker()
                            end
                        end
                    end)
                end)

                local cp = {} :: ColorPicker
                cp.Name = cfg.Name
                cp.Color = cfg.Color
                cp.Container = base
                cp.Callback = cfg.Callback

                function cp:SetValue(color: Color3)
                    cfg.Color = color
                    cp.Color = color
                    cpSwatch.BackgroundColor3 = color
                    Library.SetConfigValue(configKey, color)
                    cfg.Callback(color)
                end

                function cp:SetCallback(callback)
                    cfg.Callback = callback
                    cp.Callback = callback
                end

                function cp:Destroy() base:Destroy() end

                addElement(base)
                return cp
            end

            function Section.CreateKeybind(self, kbConfig: KeybindConfig): Keybind
                local cfg = shallowMerge({
                    Name           = "Keybind",
                    CurrentKeybind = "None",
                    Callback       = function(keybind: string) end,
                    ChangedCallback = function(keybind: string) end,
                }, kbConfig)

                local configKey = "keybind_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    cfg.CurrentKeybind = Library._config[configKey]
                end

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local kbLabel = Instance.new("TextLabel")
                kbLabel.Name = "KBLabel"
                kbLabel.BackgroundTransparency = 1
                kbLabel.Size = UDim2.new(0.6, 0, 1, 0)
                kbLabel.Position = UDim2.new(0, 8, 0, 0)
                kbLabel.Font = FONT_MEDIUM
                kbLabel.Text = cfg.Name
                kbLabel.TextColor3 = TEXT_PRIMARY
                kbLabel.TextSize = 12
                kbLabel.TextXAlignment = Enum.TextXAlignment.Left
                kbLabel.ZIndex = zIdx + 1
                kbLabel.Parent = base

                local kbBtn = Instance.new("TextButton")
                kbBtn.Name = "KBBtn"
                kbBtn.BackgroundColor3 = PLUM_HOVER
                kbBtn.Size = UDim2.new(0, 80, 0, 24)
                kbBtn.Position = UDim2.new(1, -88, 0.5, -12)
                kbBtn.Font = FONT_MEDIUM
                kbBtn.Text = cfg.CurrentKeybind
                kbBtn.TextColor3 = TEXT_PRIMARY
                kbBtn.TextSize = 11
                kbBtn.ZIndex = zIdx + 1
                kbBtn.AutoButtonColor = false
                kbBtn.Parent = base
                getCorner(kbBtn, UDim.new(0, 4))

                local listening = false

                kbBtn.MouseButton1Click:Connect(function()
                    playClick()
                    if listening then return end
                    listening = true
                    kbBtn.Text = "..."
                    kbBtn.BackgroundColor3 = Library.Theme.AccentColor

                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            cfg.CurrentKeybind = input.KeyCode.Name
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                            cfg.CurrentKeybind = "MouseButton1"
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                            cfg.CurrentKeybind = "MouseButton2"
                        end
                        kbBtn.Text = cfg.CurrentKeybind
                        kbBtn.BackgroundColor3 = PLUM_HOVER
                        listening = false
                        Library.SetConfigValue(configKey, cfg.CurrentKeybind)
                        cfg.Callback(cfg.CurrentKeybind)
                        cfg.ChangedCallback(cfg.CurrentKeybind)
                        conn:Disconnect()
                    end)
                end)

                local kb = {} :: Keybind
                kb.Name = cfg.Name
                kb.CurrentKeybind = cfg.CurrentKeybind
                kb.Container = base
                kb.Callback = cfg.Callback
                kb.ChangedCallback = cfg.ChangedCallback

                function kb:SetKeybind(keybind: string)
                    cfg.CurrentKeybind = keybind
                    kb.CurrentKeybind = keybind
                    kbBtn.Text = keybind
                    Library.SetConfigValue(configKey, keybind)
                    cfg.Callback(keybind)
                    cfg.ChangedCallback(keybind)
                end

                function kb:SetCallback(callback)
                    cfg.Callback = callback
                    kb.Callback = callback
                end

                function kb:SetChangedCallback(callback)
                    cfg.ChangedCallback = callback
                    kb.ChangedCallback = callback
                end

                function kb:Destroy() base:Destroy() end

                addElement(base)
                return kb
            end

            function Section.CreateInput(self, inputConfig: InputConfig): Input
                local cfg = shallowMerge({
                    Name            = "Input",
                    CurrentValue    = "",
                    PlaceholderText = "Type here...",
                    Callback        = function(text: string) end,
                }, inputConfig)

                local configKey = "input_" .. cfg.Name
                if Library._configLoaded and Library._config[configKey] ~= nil then
                    cfg.CurrentValue = Library._config[configKey]
                end

                local base, zIdx = makeBase(sectionContent, 32, 104)

                local inputLabel = Instance.new("TextLabel")
                inputLabel.Name = "InputLabel"
                inputLabel.BackgroundTransparency = 1
                inputLabel.Size = UDim2.new(0.35, 0, 1, 0)
                inputLabel.Position = UDim2.new(0, 8, 0, 0)
                inputLabel.Font = FONT_MEDIUM
                inputLabel.Text = cfg.Name
                inputLabel.TextColor3 = TEXT_PRIMARY
                inputLabel.TextSize = 12
                inputLabel.TextXAlignment = Enum.TextXAlignment.Left
                inputLabel.ZIndex = zIdx + 1
                inputLabel.Parent = base

                local inputBox = Instance.new("TextBox")
                inputBox.Name = "InputBox"
                inputBox.BackgroundColor3 = PLUM_HOVER
                inputBox.Size = UDim2.new(0.62, 0, 0, 24)
                inputBox.Position = UDim2.new(0.36, 0, 0.5, -12)
                inputBox.Font = FONT_MEDIUM
                inputBox.PlaceholderText = cfg.PlaceholderText
                inputBox.PlaceholderColor3 = TEXT_MUTED
                inputBox.Text = cfg.CurrentValue
                inputBox.TextColor3 = TEXT_PRIMARY
                inputBox.TextSize = 11
                inputBox.ClearTextOnFocus = false
                inputBox.ZIndex = zIdx + 1
                inputBox.Parent = base
                getCorner(inputBox, UDim.new(0, 4))

                inputBox.FocusLost:Connect(function(enterPressed)
                    cfg.CurrentValue = inputBox.Text
                    Library.SetConfigValue(configKey, cfg.CurrentValue)
                    cfg.Callback(inputBox.Text)
                end)

                local inp = {} :: Input
                inp.Name = cfg.Name
                inp.CurrentValue = cfg.CurrentValue
                inp.PlaceholderText = cfg.PlaceholderText
                inp.Container = base
                inp.Callback = cfg.Callback

                function inp:SetValue(value: string)
                    cfg.CurrentValue = value
                    inp.CurrentValue = value
                    inputBox.Text = value
                    Library.SetConfigValue(configKey, value)
                    cfg.Callback(value)
                end

                function inp:SetCallback(callback)
                    cfg.Callback = callback
                    inp.Callback = callback
                end

                function inp:Destroy() base:Destroy() end

                addElement(base)
                return inp
            end

            function Section.CreateLabel(self, text: string): Label
                local base, zIdx = makeBase(sectionContent, 20, 104)
                base.BackgroundTransparency = 1
                base.Size = UDim2.new(1, 0, 0, 20)

                local lbl = createLabel(base, text, FONT_MEDIUM, 12, TEXT_PRIMARY, zIdx + 1)
                lbl.Position = UDim2.new(0, 4, 0, 0)

                local labelObj = {} :: Label
                labelObj.Name = text
                labelObj.Container = base

                function labelObj:SetText(t)
                    lbl.Text = t
                    labelObj.Name = t
                end

                function labelObj:Destroy() base:Destroy() end

                addElement(base)
                return labelObj
            end

            function Section.CreateParagraph(self, paraConfig: ParagraphConfig): Paragraph
                local cfg = shallowMerge({
                    Title   = "Paragraph",
                    Content = "",
                }, paraConfig)

                local base, zIdx = makeBase(sectionContent, 0, 104)
                base.AutomaticSize = Enum.AutomaticSize.Y

                local paraFrame = Instance.new("Frame")
                paraFrame.Name = "ParaFrame"
                paraFrame.BackgroundColor3 = PLUM_CARD
                paraFrame.BackgroundTransparency = 0.5
                paraFrame.Size = UDim2.new(1, 0, 0, 0)
                paraFrame.AutomaticSize = Enum.AutomaticSize.Y
                paraFrame.ZIndex = zIdx + 1
                paraFrame.Parent = base
                getCorner(paraFrame, UDim.new(0, 4))
                getStroke(paraFrame, BORDER, 1)

                local paraPad = getPadding(paraFrame, UDim.new(0, 8))

                local titleLabel = Instance.new("TextLabel")
                titleLabel.Name = "TitleLabel"
                titleLabel.BackgroundTransparency = 1
                titleLabel.Size = UDim2.new(1, 0, 0, 18)
                titleLabel.Font = FONT_BOLD
                titleLabel.Text = cfg.Title
                titleLabel.TextColor3 = Library.Theme.AccentColor
                titleLabel.TextSize = 12
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.ZIndex = zIdx + 2
                titleLabel.Parent = paraFrame

                onThemeChanged(function()
                    titleLabel.TextColor3 = Library.Theme.AccentColor
                end)

                local contentLabel = Instance.new("TextLabel")
                contentLabel.Name = "ContentLabel"
                contentLabel.BackgroundTransparency = 1
                contentLabel.Size = UDim2.new(1, 0, 0, 0)
                contentLabel.Position = UDim2.new(0, 0, 0, 18)
                contentLabel.AutomaticSize = Enum.AutomaticSize.Y
                contentLabel.Font = FONT_MEDIUM
                contentLabel.Text = cfg.Content
                contentLabel.TextColor3 = TEXT_SECONDARY
                contentLabel.TextSize = 11
                contentLabel.TextWrapped = true
                contentLabel.TextXAlignment = Enum.TextXAlignment.Left
                contentLabel.ZIndex = zIdx + 2
                contentLabel.Parent = paraFrame

                local para = {} :: Paragraph
                para.Name = cfg.Title
                para.Container = base

                function para:SetTitle(t) titleLabel.Text = t end
                function para:SetContent(c) contentLabel.Text = c end
                function para:Destroy() base:Destroy() end

                addElement(base)
                return para
            end

            function Section.CreateDivider(self): Divider
                local divider = Instance.new("Frame")
                divider.Name = "Divider"
                divider.BackgroundColor3 = BORDER
                divider.BackgroundTransparency = 0.5
                divider.Size = UDim2.new(1, 0, 0, 1)
                divider.ZIndex = 105
                divider.LayoutOrder = 9998
                divider.Parent = sectionContent

                local dividerObj = {} :: Divider
                dividerObj.Container = divider
                function dividerObj:Destroy() divider:Destroy() end

                table.insert(section.Elements, divider)
                table.insert(Tab.Elements, divider)
                table.insert(Window.Elements, divider)

                return dividerObj
            end

            return section
        end

        function Tab.CreateButton(self, btnConfig: ButtonConfig): Button
            local section = self:CreateSection("")
            return section:CreateButton(btnConfig)
        end

        function Tab.CreateToggle(self, togConfig: ToggleConfig): Toggle
            local section = self:CreateSection("")
            return section:CreateToggle(togConfig)
        end

        function Tab.CreateSlider(self, sliderConfig: SliderConfig): Slider
            local section = self:CreateSection("")
            return section:CreateSlider(sliderConfig)
        end

        function Tab.CreateDropdown(self, dropConfig: DropdownConfig): Dropdown
            local section = self:CreateSection("")
            return section:CreateDropdown(dropConfig)
        end

        function Tab.CreateMultiDropdown(self, multiConfig: MultiDropdownConfig): MultiDropdown
            local section = self:CreateSection("")
            return section:CreateMultiDropdown(multiConfig)
        end

        function Tab.CreateColorPicker(self, cpConfig: ColorPickerConfig): ColorPicker
            local section = self:CreateSection("")
            return section:CreateColorPicker(cpConfig)
        end

        function Tab.CreateKeybind(self, kbConfig: KeybindConfig): Keybind
            local section = self:CreateSection("")
            return section:CreateKeybind(kbConfig)
        end

        function Tab.CreateInput(self, inputConfig: InputConfig): Input
            local section = self:CreateSection("")
            return section:CreateInput(inputConfig)
        end

        function Tab.CreateLabel(self, text: string): Label
            local section = self:CreateSection("")
            return section:CreateLabel(text)
        end

        function Tab.CreateParagraph(self, paraConfig: ParagraphConfig): Paragraph
            local section = self:CreateSection("")
            return section:CreateParagraph(paraConfig)
        end

        function Tab.CreateDivider(self): Divider
            local section = self:CreateSection("")
            return section:CreateDivider()
        end

        function Tab.Destroy(self)
            tabButton:Destroy()
            tabContent:Destroy()
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    function Window.SetName(self, name: string)
        Window.Name = name
        titleBox.Text = name
    end

    function Window.SetAccentColor(self, color: Color3)
        Library.SetAccentColor(color)
    end

    function Window.Destroy(self)
        mainFrame:Destroy()
        minimizedWindow:Destroy()
    end

    -- ═══ Built-in Settings Tab ════════════════════════════════════════════════

    task.spawn(function()
        local settingsTab = Window:CreateTab({Name = "Settings", Icon = "⚙"})

        local themeSection = settingsTab:CreateSection("Theme")

        themeSection:CreateColorPicker({
            Name = "Accent Color",
            Color = Library.Theme.AccentColor,
            Callback = function(color)
                Library.SetAccentColor(color)
            end,
        })

        themeSection:CreateSlider({
            Name = "Corner Radius",
            Range = {0, 20},
            Increment = 1,
            CurrentValue = Library.Theme.CornerRadius.Offset,
            Callback = function(value)
                Library.Theme.CornerRadius = UDim.new(0, value)
            end,
        })

        local uiSection = settingsTab:CreateSection("UI")

        uiSection:CreateKeybind({
            Name = "Menu Toggle",
            CurrentKeybind = Library._menuKeybind.Name,
            Callback = function(keybind)
                Library.SetMenuKeybind(Enum.KeyCode[keybind] or Enum.KeyCode.RightShift)
            end,
        })

        uiSection:CreateButton({
            Name = "Close Menu",
            Callback = function()
                mainFrame.Visible = false
            end,
        })

        uiSection:CreateButton({
            Name = "Open Menu",
            Callback = function()
                mainFrame.Visible = true
            end,
        })

        local configSection = settingsTab:CreateSection("Config")

        configSection:CreateInput({
            Name = "Config Name",
            CurrentValue = Library._configName,
            PlaceholderText = "Enter config name...",
            Callback = function(text)
                Library.SetConfigName(text)
            end,
        })

        configSection:CreateButton({
            Name = "Save Config",
            Callback = function()
                Library.SaveConfiguration()
                Library.Notify({Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 2})
            end,
        })

        configSection:CreateButton({
            Name = "Load Config",
            Callback = function()
                Library.LoadConfiguration()
                Library.Notify({Title = "Ivory", Content = "Config loaded!", Type = "Info", Duration = 2})
            end,
        })

        local infoSection = settingsTab:CreateSection("Info")

        local player = Players.LocalPlayer
        infoSection:CreateParagraph({
            Title = "Player",
            Content = string.format("Name: %s\nUserId: %d", player.Name, player.UserId),
        })

        local gameName = "Unknown"
        pcall(function()
            gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)
        infoSection:CreateParagraph({
            Title = "Game",
            Content = string.format("Name: %s\nPlaceId: %d", gameName, game.PlaceId),
        })

        infoSection:CreateParagraph({
            Title = "Library",
            Content = string.format("Version: %s\nExploit: %s", Library.Version, (identifyexecutor and identifyexecutor()) or "Unknown"),
        })

        local universalSection = settingsTab:CreateSection("Universal")

        universalSection:CreateButton({
            Name = "Anti-AFK",
            Callback = function()
                pcall(function()
                    local VirtualUser = game:GetService("VirtualUser")
                    VirtualUser:ClickButton2(Vector2.new())
                end)
                Library.Notify({Title = "Ivory", Content = "Anti-AFK triggered!", Type = "Success", Duration = 2})
            end,
        })

        universalSection:CreateButton({
            Name = "Copy JobId",
            Callback = function()
                pcall(function() setclipboard(game.JobId) end)
                Library.Notify({Title = "Ivory", Content = "JobId copied!", Type = "Success", Duration = 2})
            end,
        })

        universalSection:CreateButton({
            Name = "Rejoin Server",
            Callback = function()
                pcall(function()
                    game:GetService("TeleportService"):Teleport(game.PlaceId, player)
                end)
            end,
        })

        pcall(function()
            Library.LoadConfiguration(WindowConfig.ConfigName)
        end)

        if WindowConfig.ConfigSaving and WindowConfig.AutoSaveInterval then
            Library.SetAutosave(true, WindowConfig.AutoSaveInterval)
            Library.StartAutosave()
        end
    end)

    -- ═══ Menu keybind ═════════════════════════════════════════════════════════

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Library._menuKeybind then
            mainFrame.Visible = not mainFrame.Visible
            if minimized then
                minimized = false
                minimizedWindow.Visible = false
                mainFrame.Visible = true
                mainFrame.Size = originalSize
            end
        end
    end)

    -- ═══ Ctrl+F search ════════════════════════════════════════════════════════

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            SearchBox:CaptureFocus()
        end
    end)

    -- ═══ Watermark ════════════════════════════════════════════════════════════

    if WindowConfig.Watermark or WindowConfig.WatermarkEnabled then
        local watermark = Instance.new("Frame")
        watermark.Name = "IvoryWatermark"
        watermark.BackgroundColor3 = PLUM_ELEVATED
        watermark.BackgroundTransparency = 0.15
        watermark.Size = UDim2.new(0, 250, 0, 24)
        watermark.Position = UDim2.new(0, 12, 0, 12)
        watermark.ZIndex = 9998
        watermark.Parent = guiParent()
        getCorner(watermark, UDim.new(0, 6))
        getStroke(watermark, BORDER, 1)

        local wmAccent = Instance.new("Frame")
        wmAccent.Name = "AccentBar"
        wmAccent.BackgroundColor3 = Library.Theme.AccentColor
        wmAccent.Size = UDim2.new(0, 3, 1, 0)
        wmAccent.ZIndex = 9999
        wmAccent.Parent = watermark

        onThemeChanged(function()
            wmAccent.BackgroundColor3 = Library.Theme.AccentColor
        end)

        local wmText = Instance.new("TextLabel")
        wmText.Name = "WMText"
        wmText.BackgroundTransparency = 1
        wmText.Size = UDim2.new(1, -10, 1, 0)
        wmText.Position = UDim2.new(0, 8, 0, 0)
        wmText.Font = FONT_MEDIUM
        wmText.Text = "  " .. WindowConfig.Name .. " | " .. Library.Version .. " | " .. Players.LocalPlayer.Name
        wmText.TextColor3 = TEXT_PRIMARY
        wmText.TextSize = 11
        wmText.TextXAlignment = Enum.TextXAlignment.Left
        wmText.ZIndex = 9999
        wmText.Parent = watermark
    end

    -- ═══ Search filtering ══════════════════════════════════════════════════════

    task.spawn(function()
        while true do
            if Library._searchQuery and Library._searchQuery ~= "" then
                local query = Library._searchQuery:lower()
                for _, elem in ipairs(Window.Elements) do
                    if elem and elem:IsA("GuiObject") then
                        local name = elem.Name or ""
                        local visible = name:lower():find(query, 1, true) ~= nil
                        elem.Visible = visible
                    end
                end
            else
                for _, elem in ipairs(Window.Elements) do
                    if elem and elem:IsA("GuiObject") then
                        elem.Visible = true
                    end
                end
            end
            task.wait(0.1)
        end
    end)

    return Window
end

return Library
