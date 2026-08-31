-- IvoryLib — Sakura Glass theme with falling petal effects
local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LP = Players.LocalPlayer

local function getGuiParent()
    if type(gethui) == "function" then return gethui() end
    return CoreGui
end

local Theme = {
    GlassCard      = Color3.fromRGB(18, 16, 26),
    GlassCardAlt   = Color3.fromRGB(26, 22, 38),
    Stroke         = Color3.fromRGB(255, 255, 255),
    TextPrimary    = Color3.fromRGB(248, 244, 255),
    TextSecondary  = Color3.fromRGB(184, 176, 205),
    TextTertiary   = Color3.fromRGB(134, 126, 156),
    AccentA        = Color3.fromRGB(168, 120, 255),
    AccentB        = Color3.fromRGB(255, 130, 205),
    Sakura         = Color3.fromRGB(255, 183, 206),
    SakuraLight    = Color3.fromRGB(255, 224, 235),
    Success        = Color3.fromRGB(96, 235, 150),
    Error          = Color3.fromRGB(255, 108, 108),
    Blue           = Color3.fromRGB(120, 180, 255),
}

local EASE_OUT_SOFT = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local EASE_SPRING   = TweenInfo.new(0.4,  Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local EASE_QUICK    = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

local function tw(instance, info, props)
    local tween = TweenService:Create(instance, info, props)
    tween:Play()
    return tween
end

-- Falling sakura petals
local function makePetalField(sg, zIndex, count, sizeMin, sizeMax, speedMin, speedMax)
    local field = Instance.new("Frame")
    field.Name = "PetalField"
    field.Size = UDim2.fromScale(1, 1)
    field.BackgroundTransparency = 1
    field.ZIndex = zIndex
    field.Parent = sg

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

        Instance.new("UICorner", petal).CornerRadius = UDim.new(1, 0)

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

-- Notification system
local notifGui = Instance.new("ScreenGui")
notifGui.Name = "IvoryGakuranNotifGui"
notifGui.ResetOnSpawn = false
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifGui.DisplayOrder = 100
notifGui.Parent = getGuiParent()

local function Notify(opts)
    local title = opts.Title or "Ivory"
    local content = opts.Content or ""
    local kind = opts.Type or "Info"
    local dur = opts.Duration or 2.5

    local colors = {
        Success = Theme.Success,
        Error = Theme.Error,
        Info = Theme.AccentA,
    }

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, -310, 1, -70)
    frame.BackgroundColor3 = Theme.GlassCard
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Theme.Stroke
    stroke.Transparency = 0.88
    stroke.Thickness = 1

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = colors[kind] or colors.Info
    accent.BorderSizePixel = 0
    accent.Parent = frame

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -20, 0, 22)
    titleLbl.Position = UDim2.new(0, 14, 0, 6)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.TextPrimary
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame

    local contentLbl = Instance.new("TextLabel")
    contentLbl.Size = UDim2.new(1, -20, 0, 22)
    contentLbl.Position = UDim2.new(0, 14, 0, 28)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text = content
    contentLbl.TextColor3 = Theme.TextSecondary
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.TextSize = 12
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextTruncate = Enum.TextTruncate.AtEnd
    contentLbl.Parent = frame

    tw(frame, EASE_OUT_SOFT, {Position = UDim2.new(1, -310, 1, -70)})
    task.delay(dur, function()
        if frame and frame.Parent then
            tw(frame, EASE_QUICK, {Position = UDim2.new(1, -310, 1, 10)})
            task.delay(0.2, function()
                if frame and frame.Parent then frame:Destroy() end
            end)
        end
    end)
end

-- Window class
local Window = {}
Window.__index = Window

function Library:CreateWindow(opts)
    local self = setmetatable({}, Window)
    self.Name = opts.Name or "Ivory"
    self.Tabs = {}
    self.ScreenGui = nil
    self.MainFrame = nil
    self.TabButtons = nil
    self.TabPages = nil
    self.CurrentTab = nil
    self.Notify = Notify

    local sg = Instance.new("ScreenGui")
    sg.Name = "IvoryGakuranGui"
    sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 50
    sg.Parent = getGuiParent()
    self.ScreenGui = sg

    makePetalField(sg, 3, 18, 8, 14, 20, 45)
    makePetalField(sg, 30, 5, 12, 20, 45, 75)

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 520, 0, 420)
    main.Position = UDim2.new(0.5, -260, 0.5, -210)
    main.BackgroundColor3 = Theme.GlassCard
    main.BackgroundTransparency = 0.1
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    self.MainFrame = main

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    local mainStroke = Instance.new("UIStroke", main)
    mainStroke.Color = Theme.Stroke
    mainStroke.Transparency = 0.85
    mainStroke.Thickness = 1.5

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 36)
    titleBar.BackgroundColor3 = Theme.GlassCardAlt
    titleBar.BackgroundTransparency = 0.1
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main

    local titleCorner = Instance.new("UICorner", titleBar)
    titleCorner.CornerRadius = UDim.new(0, 12)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 4)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Theme.TextTertiary
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        tw(main, EASE_SPRING, {Size = UDim2.new(0, 0, 0, 0)})
        task.delay(0.3, function()
            main.Visible = false
            main.Size = UDim2.new(0, 520, 0, 420)
        end)
    end)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -50, 1, 0)
    titleLbl.Position = UDim2.new(0, 14, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = self.Name
    titleLbl.TextColor3 = Theme.SakuraLight
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 15
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = titleBar

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0, 125, 1, -36)
    tabBar.Position = UDim2.new(0, 0, 0, 36)
    tabBar.BackgroundColor3 = Theme.GlassCardAlt
    tabBar.BackgroundTransparency = 0.15
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    self.TabButtons = tabBar
    Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 0)

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.Padding = UDim.new(0, 3)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, -125, 1, -36)
    tabContent.Position = UDim2.new(0, 125, 0, 36)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Parent = main
    self.TabPages = tabContent

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            if main.Visible then
                tw(main, EASE_SPRING, {Size = UDim2.new(0, 0, 0, 0)})
                task.delay(0.3, function()
                    main.Visible = false
                    main.Size = UDim2.new(0, 520, 0, 420)
                end)
            else
                main.Size = UDim2.new(0, 0, 0, 0)
                main.Visible = true
                tw(main, EASE_SPRING, {Size = UDim2.new(0, 520, 0, 420)})
            end
        end
    end)

    main.Size = UDim2.new(0, 0, 0, 0)
    main.Visible = true
    tw(main, EASE_SPRING, {Size = UDim2.new(0, 520, 0, 420)})

    Notify({Title = self.Name, Content = "Loaded!", Type = "Success", Duration = 3})
    return self
end

function Window:Destroy()
    if self.ScreenGui then self.ScreenGui:Destroy() end
    if notifGui then notifGui:Destroy() end
end

function Window:Notify(opts)
    Notify(opts)
end

-- Tab class
local Tab = {}
Tab.__index = Tab

function Window:AddTab(opts)
    local tab = setmetatable({}, Tab)
    tab.Name = opts.Name or "Tab"
    tab.Window = self
    tab.SubTabs = {}
    tab.Button = nil
    tab.Page = nil
    self.Tabs[tab.Name] = tab

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -12, 0, 32)
    btn.Position = UDim2.new(0, 6, 0, 0)
    btn.BackgroundColor3 = Theme.GlassCard
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. opts.Name
    btn.TextColor3 = Theme.TextTertiary
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.LayoutOrder = #self.TabButtons:GetChildren()
    btn.Parent = self.TabButtons
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    tab.Button = btn

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 3, 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = Theme.Sakura
    indicator.BackgroundTransparency = 1
    indicator.BorderSizePixel = 0
    indicator.Parent = btn
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    tab.Indicator = indicator

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -12, 1, -12)
    page.Position = UDim2.new(0, 6, 0, 6)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Sakura
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = self.TabPages
    tab.Page = page

    local layout = Instance.new("UIListLayout", page)
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    Instance.new("UIPadding", page).PaddingTop = UDim.new(0, 4)

    if not self.CurrentTab then
        self.CurrentTab = tab
        page.Visible = true
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Theme.TextPrimary
        indicator.Size = UDim2.new(0, 3, 0, 20)
        indicator.BackgroundTransparency = 0
    end

    btn.MouseButton1Click:Connect(function()
        if self.CurrentTab then
            self.CurrentTab.Page.Visible = false
            self.CurrentTab.Button.BackgroundTransparency = 1
            self.CurrentTab.Button.TextColor3 = Theme.TextTertiary
            tw(self.CurrentTab.Indicator, EASE_QUICK, {Size = UDim2.new(0, 3, 0, 0), BackgroundTransparency = 1})
        end
        self.CurrentTab = tab
        page.Visible = true
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Theme.TextPrimary
        tw(indicator, EASE_SPRING, {Size = UDim2.new(0, 3, 0, 20), BackgroundTransparency = 0})
    end)

    return tab
end

-- SubTab class
local SubTab = {}
SubTab.__index = SubTab

function Tab:AddSubTab(opts)
    if type(opts) == "string" then opts = {Name = opts} end
    local subtab = setmetatable({}, SubTab)
    subtab.Name = opts.Name or ""
    subtab.Tab = self
    subtab.Elements = {}

    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 26)
    header.BackgroundTransparency = 1
    header.Text = "  " .. opts.Name
    header.TextColor3 = Theme.AccentB
    header.Font = Enum.Font.GothamBold
    header.TextSize = 12
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = #self.Page:GetChildren() * 1000
    header.Parent = self.Page

    return subtab
end

-- Element helpers
local function makeRow(parent, name, layoutOrder)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 32)
    frame.BackgroundColor3 = Theme.GlassCardAlt
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.LayoutOrder = layoutOrder or 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", frame).PaddingLeft = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Theme.Stroke
    stroke.Transparency = 0.92
    stroke.Thickness = 0.5

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.TextPrimary
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    return frame, label
end

local orderCounter = 0
local function nextOrder()
    orderCounter = orderCounter + 1
    return orderCounter
end

function SubTab:AddToggle(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 24)
    btn.Position = UDim2.new(1, -58, 0.5, -12)
    btn.BackgroundColor3 = opts.Default and Theme.AccentA or Theme.GlassCard
    btn.Text = opts.Default and "ON" or "OFF"
    btn.TextColor3 = opts.Default and Color3.new(1,1,1) or Theme.TextTertiary
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 10
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = opts.Default and Theme.AccentA or Theme.Stroke
    stroke.Transparency = opts.Default and 0.5 or 0.9
    stroke.Thickness = 1

    local state = opts.Default or false
    btn.MouseButton1Click:Connect(function()
        state = not state
        tw(btn, EASE_QUICK, {
            BackgroundColor3 = state and Theme.AccentA or Theme.GlassCard
        })
        btn.Text = state and "ON" or "OFF"
        btn.TextColor3 = state and Color3.new(1,1,1) or Theme.TextTertiary
        stroke.Color = state and Theme.AccentA or Theme.Stroke
        stroke.Transparency = state and 0.5 or 0.9
        if opts.Callback then opts.Callback(state) end
    end)
end

function SubTab:AddSlider(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    row.Size = UDim2.new(1, -8, 0, 44)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 60, 0, 14)
    valLabel.Position = UDim2.new(1, -70, 0, 2)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(opts.Default or opts.Min)
    valLabel.TextColor3 = Theme.SakuraLight
    valLabel.Font = Enum.Font.GothamBold
    valLabel.TextSize = 11
    valLabel.Parent = row

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, -16, 0, 12)
    slider.Position = UDim2.new(0, 8, 0, 26)
    slider.BackgroundColor3 = Theme.GlassCard
    slider.BorderSizePixel = 0
    slider.Text = ""
    slider.Parent = row
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((opts.Default - opts.Min) / (opts.Max - opts.Min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.AccentA
    fill.BorderSizePixel = 0
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local grad = Instance.new("UIGradient", fill)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.AccentA),
        ColorSequenceKeypoint.new(1, Theme.AccentB),
    })

    local min, max = opts.Min or 0, opts.Max or 100
    local val = opts.Default or min
    local dragging = false

    local function update(input)
        local pct = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        val = math.floor(min + (max - min) * pct + 0.5)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        valLabel.Text = tostring(val) .. (opts.Suffix or "")
        if opts.Callback then opts.Callback(val) end
    end

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function SubTab:AddDropdown(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    row.Size = UDim2.new(1, -8, 0, 34)

    local selected = Instance.new("TextLabel")
    selected.Size = UDim2.new(0, 130, 0, 24)
    selected.Position = UDim2.new(1, -140, 0.5, -12)
    selected.BackgroundColor3 = Theme.GlassCard
    selected.BackgroundTransparency = 0.3
    selected.Text = "  " .. (opts.Default or "")
    selected.TextColor3 = Theme.TextPrimary
    selected.Font = Enum.Font.Gotham
    selected.TextSize = 11
    selected.TextXAlignment = Enum.TextXAlignment.Left
    selected.BorderSizePixel = 0
    selected.Parent = row
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", selected).Color = Theme.Stroke
    Instance.new("UIStroke", selected).Transparency = 0.9

    local dropdown = Instance.new("ScrollingFrame")
    dropdown.Size = UDim2.new(0, 140, 0, math.min(#(opts.Options or {}) * 28, 160))
    dropdown.Position = UDim2.new(1, -150, 1, 4)
    dropdown.BackgroundColor3 = Theme.GlassCard
    dropdown.BackgroundTransparency = 0.05
    dropdown.BorderSizePixel = 0
    dropdown.ScrollBarThickness = 3
    dropdown.ScrollBarImageColor3 = Theme.Sakura
    dropdown.CanvasSize = UDim2.new(0, 0, 0, #(opts.Options or {}) * 28)
    dropdown.Visible = false
    dropdown.ZIndex = 10
    dropdown.Parent = row
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", dropdown).Color = Theme.Stroke
    Instance.new("UIStroke", dropdown).Transparency = 0.85

    local dLayout = Instance.new("UIListLayout", dropdown)
    dLayout.Padding = UDim.new(0, 2)

    local function refresh(options)
        for _, c in ipairs(dropdown:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 26)
            item.BackgroundColor3 = Theme.GlassCardAlt
            item.BackgroundTransparency = 0.3
            item.Text = "  " .. opt
            item.TextColor3 = Theme.TextPrimary
            item.Font = Enum.Font.Gotham
            item.TextSize = 11
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.BorderSizePixel = 0
            item.ZIndex = 11
            item.Parent = dropdown
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
            item.MouseButton1Click:Connect(function()
                selected.Text = "  " .. opt
                dropdown.Visible = false
                tw(selected, EASE_QUICK, {BackgroundColor3 = Theme.AccentA})
                task.delay(0.15, function()
                    tw(selected, EASE_QUICK, {BackgroundColor3 = Theme.GlassCard})
                end)
                if opts.Callback then opts.Callback(opt) end
            end)
        end
        dropdown.CanvasSize = UDim2.new(0, 0, 0, #options * 28)
        dropdown.Size = UDim2.new(0, 140, 0, math.min(#options * 28, 160))
    end

    refresh(opts.Options or {})

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 12
    toggleBtn.Parent = selected
    toggleBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)

    return {
        SetOptions = function(_, options) refresh(options) end,
        SetValues = function(_, options) refresh(options) end,
    }
end

function SubTab:AddMultiDropdown(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    row.Size = UDim2.new(1, -8, 0, 34)

    local selected = Instance.new("TextLabel")
    selected.Size = UDim2.new(0, 130, 0, 24)
    selected.Position = UDim2.new(1, -140, 0.5, -12)
    selected.BackgroundColor3 = Theme.GlassCard
    selected.BackgroundTransparency = 0.3
    selected.Text = "  None"
    selected.TextColor3 = Theme.TextPrimary
    selected.Font = Enum.Font.Gotham
    selected.TextSize = 11
    selected.TextXAlignment = Enum.TextXAlignment.Left
    selected.BorderSizePixel = 0
    selected.Parent = row
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", selected).Color = Theme.Stroke
    Instance.new("UIStroke", selected).Transparency = 0.9

    local dropdown = Instance.new("ScrollingFrame")
    dropdown.Size = UDim2.new(0, 140, 0, math.min(#(opts.Options or {}) * 28, 160))
    dropdown.Position = UDim2.new(1, -150, 1, 4)
    dropdown.BackgroundColor3 = Theme.GlassCard
    dropdown.BackgroundTransparency = 0.05
    dropdown.BorderSizePixel = 0
    dropdown.ScrollBarThickness = 3
    dropdown.ScrollBarImageColor3 = Theme.Sakura
    dropdown.CanvasSize = UDim2.new(0, 0, 0, #(opts.Options or {}) * 28)
    dropdown.Visible = false
    dropdown.ZIndex = 10
    dropdown.Parent = row
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 8)
    Instance.new("UIStroke", dropdown).Color = Theme.Stroke
    Instance.new("UIStroke", dropdown).Transparency = 0.85

    local dLayout = Instance.new("UIListLayout", dropdown)
    dLayout.Padding = UDim.new(0, 2)

    local selectedSet = {}
    local options = opts.Options or {}

    local function refresh()
        for _, c in ipairs(dropdown:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 26)
            item.BackgroundColor3 = Theme.GlassCardAlt
            item.BackgroundTransparency = 0.3
            item.Text = (selectedSet[opt] and "  [X] " or "  [ ] ") .. opt
            item.TextColor3 = Theme.TextPrimary
            item.Font = Enum.Font.Gotham
            item.TextSize = 11
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.BorderSizePixel = 0
            item.ZIndex = 11
            item.Parent = dropdown
            Instance.new("UICorner", item).CornerRadius = UDim.new(0, 4)
            item.MouseButton1Click:Connect(function()
                selectedSet[opt] = not selectedSet[opt]
                refresh()
                local sel = {}
                for k, v in pairs(selectedSet) do if v then table.insert(sel, k) end end
                selected.Text = "  " .. (#sel > 0 and table.concat(sel, ", ") or "None")
                if opts.Callback then opts.Callback(sel) end
            end)
        end
    end

    refresh()

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.ZIndex = 12
    toggleBtn.Parent = selected
    toggleBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
    end)

    return {
        SetOptions = function(_, opts2) options = opts2; refresh() end,
        SetValues = function(_, opts2) options = opts2; refresh() end,
    }
end

function SubTab:AddButton(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    label.TextColor3 = Theme.SakuraLight

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.TextColor3 = Theme.AccentA
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        tw(row, EASE_QUICK, {BackgroundColor3 = Theme.AccentA})
        task.delay(0.1, function()
            tw(row, EASE_QUICK, {BackgroundColor3 = Theme.GlassCardAlt})
        end)
        if opts.Callback then opts.Callback() end
    end)
end

function SubTab:AddColorPicker(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 26, 0, 26)
    preview.Position = UDim2.new(1, -36, 0.5, -13)
    preview.BackgroundColor3 = opts.Default or Color3.new(1,1,1)
    preview.BorderSizePixel = 0
    preview.Parent = row
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", preview).Color = Theme.Stroke
    Instance.new("UIStroke", preview).Transparency = 0.85

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        local colors = {
            Theme.AccentA, Theme.AccentB, Theme.Sakura, Theme.Blue,
            Theme.Success, Theme.Error, Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0),
        }
        local current = preview.BackgroundColor3
        local nextC = colors[1]
        for i, c in ipairs(colors) do
            if c == current and i < #colors then nextC = colors[i + 1]; break end
        end
        tw(preview, EASE_QUICK, {BackgroundColor3 = nextC})
        if opts.Callback then opts.Callback(nextC) end
    end)
end

function SubTab:AddKeybind(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0, 80, 0, 24)
    keyLabel.Position = UDim2.new(1, -90, 0.5, -12)
    keyLabel.BackgroundColor3 = Theme.GlassCard
    keyLabel.BackgroundTransparency = 0.3
    keyLabel.Text = tostring(opts.Default and opts.Default.Name or "None")
    keyLabel.TextColor3 = Theme.TextSecondary
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 11
    keyLabel.BorderSizePixel = 0
    keyLabel.Parent = row
    Instance.new("UICorner", keyLabel).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", keyLabel).Color = Theme.Stroke
    Instance.new("UIStroke", keyLabel).Transparency = 0.9

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == (opts.Default or Enum.KeyCode.RightShift) then
                tw(keyLabel, EASE_QUICK, {BackgroundColor3 = Theme.AccentA})
                task.delay(0.15, function()
                    tw(keyLabel, EASE_QUICK, {BackgroundColor3 = Theme.GlassCard})
                end)
                if opts.OnPress then opts.OnPress() end
            end
        end
    end)
end

-- Config stubs
function Library:SaveConfig(name) end
function Library:LoadConfig(name) end
function Library:ListConfigs() return {} end

_G.IvoryGakuranLib = Library
