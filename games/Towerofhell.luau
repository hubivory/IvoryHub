-- ---------------------------------------------------------------
-- IVORY HUB - TOWER OF HELL
-- ---------------------------------------------------------------

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

local LIB_SRC = httpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua")
if not LIB_SRC or #LIB_SRC == 0 then
	error("[Ivory] Failed to fetch library. Check HTTP support.")
end
local Library = loadstring(LIB_SRC)()
if not Library then
	error("[Ivory] Failed to compile library")
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Window = Library.CreateWindow({Name = "Ivory", Width = 460, Height = 360, Minimizable = true, NotifySide = "Right", ShowCustomCursor = false, CornerRadius = 4})

local Tabs = {
    Main = Window:CreateTab({Name = "Tower"}),
    Movement = Window:CreateTab({Name = "Movement"}),
    Settings = Window:CreateTab({Name = "Settings"}),
}

local AutoSubTab = Tabs.Main:CreateSection("Auto Win")
local SkipSubTab = Tabs.Main:CreateSection("Skip")

local State = { AutoWinEnabled = false, AutoWinDelay = 1.2, InfiniteJump = false, JumpHeight = 50 }

local function findTowerFolder()
    for _, name in ipairs({"tower","Tower","TOWER","Map","map"}) do
        local f = Workspace:FindFirstChild(name)
        if f then return f end
    end
    return Workspace
end

local function getTopCFrame()
    local folder = findTowerFolder()

    if workspace.tower.sections.finish.FinishGlow ~= nil then
        return workspace.tower.sections.finish.FinishGlow.CFrame
    end

    local bestPart, bestY = nil, -math.huge
    for _, v in ipairs(folder:GetDescendants()) do
        if v:IsA("BasePart") and v.CanCollide then
            local n = v.Name:lower()
            if not n:find("finishglow") and not n:find("streaming") and not n:find("particle") and not n:find("wall") then
                local area = v.Size.X * v.Size.Z
                if area > 200 and v.Position.Y > bestY then
                    bestPart, bestY = v, v.Position.Y
                end
            end
        end
    end
    if bestPart then
        local topY = bestPart.Position.Y + (bestPart.Size.Y / 2) + 1
        return CFrame.new(bestPart.Position.X, topY, bestPart.Position.Z)
    end
    return nil
end

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    return char:FindFirstChildOfClass("Humanoid")
end

local function safeTeleport(cf)
    local hrp = getHRP()
    print(hrp)
    print(cf)
    if not hrp or not cf then return end
    hrp.CFrame = cf
end

-- ---------------------------------------------------------------
-- MAIN > AUTO WIN
-- ---------------------------------------------------------------

do
    local left = AutoSubTab:CreateSection("Auto Win")
    left:CreateToggle({Name = "Auto Win (loop)", CurrentValue = State.AutoWinEnabled, Callback = function(v)
        State.AutoWinEnabled = v
    end})
    left:CreateSlider({Name = "Delay", Range = {0.3, 5}, Increment = 0.1, CurrentValue = State.AutoWinDelay, Callback = function(v)
        State.AutoWinDelay = v
    end})
    left:CreateButton({Name = "Win Now", Callback = function()
        local hrp = getHRP()
        local offset
        if hrp.Position.Z < getTopCFrame().Position.Z then
            offset = Vector3.new(0, 0, -1)
        elseif hrp.Position.Z > getTopCFrame().Position.Z then
            offset = Vector3.new(0, 0, 1)
        else
            offset = Vector3.new(0, 0, 0)
        end
        local cf = getTopCFrame() + offset
        if cf then
            safeTeleport(cf)
            Library.Notify({Title = "Ivory", Content = "Teleported!", Duration = 2, Type = "Success"})
        else
            Library.Notify({Title = "Ivory", Content = "Top not found", Duration = 3, Type = "Error"})
        end
    end})

    local right = AutoSubTab:CreateSection("Info")
    right:CreateLabel("Flies UP then DOWN to finish - avoids all kill bricks")
    right:CreateKeybind({Name = "Toggle Auto Win", CurrentKeybind = "N"})
end

-- ---------------------------------------------------------------
-- MAIN > SKIP
-- ---------------------------------------------------------------

do
    local left = SkipSubTab:CreateSection("Skip Level")
    left:CreateButton({Name = "Skip 35 studs", Callback = function()
        local hrp = getHRP()
        if hrp then
            safeTeleport(hrp.CFrame + Vector3.new(0, 35, 0))
            Library.Notify({Title = "Ivory", Content = "Skipped 35", Duration = 1.5})
        end
    end})
    left:CreateSlider({Name = "Custom Skip Height", Range = {10, 100}, Increment = 1, CurrentValue = 35})
    left:CreateButton({Name = "Custom Skip", Callback = function()
        local hrp = getHRP()
        if hrp then safeTeleport(hrp.CFrame + Vector3.new(0, 35, 0)) end
    end})

    local right = SkipSubTab:CreateSection("Teleport")
    right:CreateButton({Name = "To Lobby", Callback = function()
        local spawn = Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawn then
            safeTeleport(spawn.CFrame + Vector3.new(0, 3, 0))
        else
            local hrp = getHRP()
            if hrp then safeTeleport(CFrame.new(11, 9, 25)) end
        end
    end})
end

-- ---------------------------------------------------------------
-- PLAYER > MOVEMENT
-- ---------------------------------------------------------------

do
    local left = Tabs.Movement:CreateSection("Infinite Jump")
    left:CreateToggle({Name = "Infinite Jump", CurrentValue = State.InfiniteJump, Callback = function(v)
        State.InfiniteJump = v
    end})
    left:CreateSlider({Name = "Jump Power", Range = {20, 120}, Increment = 1, CurrentValue = State.JumpHeight, Callback = function(v)
        State.JumpHeight = v
    end})

    local right = Tabs.Movement:CreateSection("Movement Helpers")
    right:CreateSlider({Name = "WalkSpeed", Range = {16, 40}, Increment = 1, CurrentValue = 16, Callback = function(v)
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end})
    right:CreateSlider({Name = "Gravity", Range = {30, 196}, Increment = 1, CurrentValue = Workspace.Gravity, Callback = function(v)
        Workspace.Gravity = v
    end})
    right:CreateButton({Name = "Reset", Callback = function()
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = 16; hum.JumpPower = 50 end
        Workspace.Gravity = 196.2
    end})
end

-- ---------------------------------------------------------------
-- SETTINGS
-- ---------------------------------------------------------------

do
    local menu = Tabs.Settings:CreateSection("Menu")
    menu:CreateButton({Name = "Join Discord", Callback = function() pcall(function() setclipboard("https://discord.gg/ivory") end); Library.Notify({Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3}) end})
    menu:CreateButton({Name = "Unload", Callback = function() Library:Unload() end})

    local creditBox = Tabs.Settings:CreateSection("Credits")
    creditBox:CreateLabel("Made by mommy veqxo <3")
end

-- ---------------------------------------------------------------
-- EVENT HANDLERS & MAIN LOOP
-- ---------------------------------------------------------------

local jumpConn = UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump then
        local hum = getHumanoid()
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
            if State.JumpHeight ~= 50 then hum.JumpPower = State.JumpHeight end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(State.AutoWinDelay)
        if State.AutoWinEnabled then
            local cf = getTopCFrame()
            if cf then
                local hrp = getHRP()
                if hrp and (hrp.Position - cf.Position).Magnitude > 12 then
                    safeTeleport(cf)
                end
            end
        end
        if Library.Unloaded then break end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    local hum = char:WaitForChild("Humanoid")
    if State.JumpHeight then hum.JumpPower = State.JumpHeight end
end)

if jumpConn then jumpConn:Disconnect() end
print("Ivory Hub unloaded")

Library.Notify({
    Title = "Ivory",
    Content = "Tower of Hell loaded. RightShift to open menu.",
    Type = "Success",
    Duration = 4,
})
