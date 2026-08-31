-- IvoryLib Minimal Wrapper — provides the API the Gakuran script expects
-- using a simple ScreenGui-based interface

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

local function getGuiParent()
    if type(gethui) == "function" then return gethui() end
    return CoreGui
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
        Success = Color3.fromRGB(40, 180, 80),
        Error = Color3.fromRGB(220, 50, 50),
        Info = Color3.fromRGB(60, 130, 220),
    }

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 280, 0, 60)
    frame.Position = UDim2.new(1, -290, 1, -70)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

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
    titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = frame

    local contentLbl = Instance.new("TextLabel")
    contentLbl.Size = UDim2.new(1, -20, 0, 22)
    contentLbl.Position = UDim2.new(0, 14, 0, 28)
    contentLbl.BackgroundTransparency = 1
    contentLbl.Text = content
    contentLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    contentLbl.Font = Enum.Font.Gotham
    contentLbl.TextSize = 12
    contentLbl.TextXAlignment = Enum.TextXAlignment.Left
    contentLbl.TextTruncate = Enum.TextTruncate.AtEnd
    contentLbl.Parent = frame

    task.delay(dur, function()
        if frame and frame.Parent then frame:Destroy() end
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

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 500, 0, 400)
    main.Position = UDim2.new(0.5, -250, 0.5, -200)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BorderSizePixel = 0
    main.Active = true
    main.Draggable = true
    main.Parent = sg
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
    self.MainFrame = main

    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.new(1, -40, 1, 0)
    titleLbl.Position = UDim2.new(0, 12, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = self.Name
    titleLbl.TextColor3 = Color3.fromRGB(200, 200, 255)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = titleBar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -32, 0, 2)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(0, 120, 1, -32)
    tabBar.Position = UDim2.new(0, 0, 0, 32)
    tabBar.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    self.TabButtons = tabBar

    local tabLayout = Instance.new("UIListLayout", tabBar)
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, -120, 1, -32)
    tabContent.Position = UDim2.new(0, 120, 0, 32)
    tabContent.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    tabContent.BorderSizePixel = 0
    tabContent.Parent = main
    self.TabPages = tabContent

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
        end
    end)

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
    btn.Size = UDim2.new(1, -8, 0, 30)
    btn.Position = UDim2.new(0, 4, 0, 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.BackgroundTransparency = 0.5
    btn.Text = opts.Name
    btn.TextColor3 = Color3.fromRGB(160, 160, 160)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 12
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.LayoutOrder = #self.TabButtons:GetChildren()
    btn.Parent = self.TabButtons
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 8)
    tab.Button = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -8, 1, -8)
    page.Position = UDim2.new(0, 4, 0, 4)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
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
        btn.TextColor3 = Color3.fromRGB(200, 200, 255)
    end

    btn.MouseButton1Click:Connect(function()
        if self.CurrentTab then
            self.CurrentTab.Page.Visible = false
            self.CurrentTab.Button.BackgroundTransparency = 0.5
            self.CurrentTab.Button.TextColor3 = Color3.fromRGB(160, 160, 160)
        end
        self.CurrentTab = tab
        page.Visible = true
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Color3.fromRGB(200, 200, 255)
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
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.Text = "  " .. opts.Name
    header.TextColor3 = Color3.fromRGB(120, 120, 150)
    header.Font = Enum.Font.GothamBold
    header.TextSize = 11
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.LayoutOrder = #self.Page:GetChildren() * 1000
    header.Parent = self.Page

    return subtab
end

-- Element helpers
local function makeRow(parent, name, layoutOrder)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -8, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 33)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = layoutOrder or 0
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    Instance.new("UIPadding", frame).PaddingLeft = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
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
    btn.Size = UDim2.new(0, 44, 0, 22)
    btn.Position = UDim2.new(1, -54, 0.5, -11)
    btn.BackgroundColor3 = opts.Default and Color3.fromRGB(0, 160, 70) or Color3.fromRGB(120, 30, 30)
    btn.Text = opts.Default and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.BorderSizePixel = 0
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local state = opts.Default or false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 160, 70) or Color3.fromRGB(120, 30, 30)
        btn.Text = state and "ON" or "OFF"
        if opts.Callback then opts.Callback(state) end
    end)
end

function SubTab:AddSlider(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    row.Size = UDim2.new(1, -8, 0, 40)

    local valLabel = Instance.new("TextLabel")
    valLabel.Size = UDim2.new(0, 50, 0, 14)
    valLabel.Position = UDim2.new(1, -60, 0, 2)
    valLabel.BackgroundTransparency = 1
    valLabel.Text = tostring(opts.Default or opts.Min)
    valLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    valLabel.Font = Enum.Font.Gotham
    valLabel.TextSize = 11
    valLabel.Parent = row

    local slider = Instance.new("TextButton")
    slider.Size = UDim2.new(1, -16, 0, 14)
    slider.Position = UDim2.new(0, 8, 0, 22)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    slider.BorderSizePixel = 0
    slider.Text = ""
    slider.Parent = row
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((opts.Default - opts.Min) / (opts.Max - opts.Min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 130, 255)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

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
    selected.Size = UDim2.new(0, 120, 0, 22)
    selected.Position = UDim2.new(1, -130, 0.5, -11)
    selected.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    selected.Text = opts.Default or ""
    selected.TextColor3 = Color3.fromRGB(200, 200, 200)
    selected.Font = Enum.Font.Gotham
    selected.TextSize = 11
    selected.BorderSizePixel = 0
    selected.Parent = row
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 4)

    local dropdown = Instance.new("ScrollingFrame")
    dropdown.Size = UDim2.new(0, 130, 0, math.min(#opts.Options * 26, 150))
    dropdown.Position = UDim2.new(1, -140, 1, 2)
    dropdown.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    dropdown.BorderSizePixel = 0
    dropdown.ScrollBarThickness = 3
    dropdown.CanvasSize = UDim2.new(0, 0, 0, #opts.Options * 26)
    dropdown.Visible = false
    dropdown.ZIndex = 10
    dropdown.Parent = row
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 4)

    local dLayout = Instance.new("UIListLayout", dropdown)
    dLayout.Padding = UDim.new(0, 2)

    local function refresh(options)
        for _, c in ipairs(dropdown:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, opt in ipairs(options) do
            local item = Instance.new("TextButton")
            item.Size = UDim2.new(1, 0, 0, 24)
            item.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            item.Text = "  " .. opt
            item.TextColor3 = Color3.fromRGB(200, 200, 200)
            item.Font = Enum.Font.Gotham
            item.TextSize = 11
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.BorderSizePixel = 0
            item.ZIndex = 11
            item.Parent = dropdown
            item.MouseButton1Click:Connect(function()
                selected.Text = opt
                dropdown.Visible = false
                if opts.Callback then opts.Callback(opt) end
            end)
        end
        dropdown.CanvasSize = UDim2.new(0, 0, 0, #options * 26)
        dropdown.Size = UDim2.new(0, 130, 0, math.min(#options * 26, 150))
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
        SetOptions = function(_, options)
            refresh(options)
        end,
        SetValues = function(_, options)
            refresh(options)
        end,
    }
end

function SubTab:AddMultiDropdown(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    row.Size = UDim2.new(1, -8, 0, 34)

    local selected = Instance.new("TextLabel")
    selected.Size = UDim2.new(0, 120, 0, 22)
    selected.Position = UDim2.new(1, -130, 0.5, -11)
    selected.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    selected.Text = "None"
    selected.TextColor3 = Color3.fromRGB(200, 200, 200)
    selected.Font = Enum.Font.Gotham
    selected.TextSize = 11
    selected.BorderSizePixel = 0
    selected.Parent = row
    Instance.new("UICorner", selected).CornerRadius = UDim.new(0, 4)

    local dropdown = Instance.new("ScrollingFrame")
    dropdown.Size = UDim2.new(0, 130, 0, math.min(#(opts.Options or {}) * 26, 150))
    dropdown.Position = UDim2.new(1, -140, 1, 2)
    dropdown.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    dropdown.BorderSizePixel = 0
    dropdown.ScrollBarThickness = 3
    dropdown.CanvasSize = UDim2.new(0, 0, 0, #(opts.Options or {}) * 26)
    dropdown.Visible = false
    dropdown.ZIndex = 10
    dropdown.Parent = row
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 4)

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
            item.Size = UDim2.new(1, 0, 0, 24)
            item.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
            item.Text = (selectedSet[opt] and "[X] " or "[ ] ") .. opt
            item.TextColor3 = Color3.fromRGB(200, 200, 200)
            item.Font = Enum.Font.Gotham
            item.TextSize = 11
            item.TextXAlignment = Enum.TextXAlignment.Left
            item.BorderSizePixel = 0
            item.ZIndex = 11
            item.Parent = dropdown
            item.MouseButton1Click:Connect(function()
                selectedSet[opt] = not selectedSet[opt]
                refresh()
                local sel = {}
                for k, v in pairs(selectedSet) do if v then table.insert(sel, k) end end
                selected.Text = #sel > 0 and table.concat(sel, ", ") or "None"
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
        SetOptions = function(_, opts2)
            options = opts2
            refresh()
        end,
        SetValues = function(_, opts2)
            options = opts2
            refresh()
        end,
    }
end

function SubTab:AddButton(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())
    label.TextColor3 = Color3.fromRGB(180, 200, 255)

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = ">"
    arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 14
    arrow.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        if opts.Callback then opts.Callback() end
    end)
end

function SubTab:AddColorPicker(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 24, 0, 24)
    preview.Position = UDim2.new(1, -34, 0.5, -12)
    preview.BackgroundColor3 = opts.Default or Color3.fromRGB(255, 255, 255)
    preview.BorderSizePixel = 0
    preview.Parent = row
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        local colors = {
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 255, 255),
            Color3.fromRGB(255, 0, 255), Color3.fromRGB(255, 128, 0),
        }
        local current = preview.BackgroundColor3
        local next = colors[1]
        for i, c in ipairs(colors) do
            if c == current and i < #colors then next = colors[i + 1]; break end
        end
        preview.BackgroundColor3 = next
        if opts.Callback then opts.Callback(next) end
    end)
end

function SubTab:AddKeybind(opts)
    local row, label = makeRow(self.Tab.Page, opts.Name, nextOrder())

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Size = UDim2.new(0, 80, 0, 22)
    keyLabel.Position = UDim2.new(1, -90, 0.5, -11)
    keyLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    keyLabel.Text = tostring(opts.Default and opts.Default.Name or "None")
    keyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    keyLabel.Font = Enum.Font.Gotham
    keyLabel.TextSize = 11
    keyLabel.BorderSizePixel = 0
    keyLabel.Parent = row
    Instance.new("UICorner", keyLabel).CornerRadius = UDim.new(0, 4)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == (opts.Default or Enum.KeyCode.RightShift) then
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
