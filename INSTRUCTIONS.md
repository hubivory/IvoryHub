# Ivory Hub - Script Instructions

## Branding

- Window Title: `"Ivory"`
- Footer: `"v1.4 | Lobby/Game | UserId"` (copyable)
- All GUI text must say "Ivory" -- never display the game name

## UI Library: IvoryHubLibrary

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"))()
```

### Key API

```lua
-- Window
local Window = Library.CreateWindow({ Name = "Ivory", Width = 700, Height = 600 })

-- Tabs (accepts string or {Name = "..."})
local CombatTab = Window:CreateTab("Combat")
local MiscTab = Window:CreateTab({ Name = "Misc" })

-- Sections (replace AddLeftGroupbox/AddRightGroupbox)
local Section = CombatTab:CreateSection("section name")

-- Elements — two calling styles supported:
-- 1. Table config (preferred)
Section:CreateToggle({ Name = "toggle text", CurrentValue = false, Callback = function(v) end })
Section:CreateSlider({ Name = "slider text", Min = 0, Max = 100, CurrentValue = 50, Callback = function(v) end })
Section:CreateDropdown({ Name = "dropdown text", Values = {"A","B"}, CurrentOption = "A", Callback = function(v) end })
Section:CreateButton({ Name = "button text", Callback = function() end })
Section:CreateLabel("label text")
Section:CreateLabel({ Text = "label text" })
Section:CreateInput({ Name = "input text", Default = "", Placeholder = "type here", Callback = function(v) end })

-- 2. Two-arg style (ObsidianUltra compat)
Section:CreateToggle("FlagName", { Text = "toggle text", CurrentValue = false, Callback = function(v) end })
Section:CreateSlider("SliderName", { Text = "slider text", Min = 0, Max = 100, CurrentValue = 50, Callback = function(v) end })
Section:CreateDropdown("DropdownName", { Text = "dropdown text", Values = {"A","B"}, CurrentOption = "A", Callback = function(v) end })
Section:CreateButton("button text", function() end)
Section:CreateInput("InputName", { Text = "input text", Default = "", Placeholder = "type here", Callback = function(v) end })

-- Chained ColorPicker (on label)
Section:CreateLabel({Text = "color label"}):CreateColorPicker("PickerName", { Default = Color3.new(1,1,1), Callback = function(c) end })

-- Chained Keybind (on toggle or label)
Section:CreateLabel("keybind label"):CreateKeybind("KeybindName", { Default = "RightShift", Callback = function(k) end })

-- DependencyBox (hides contents when dependency not met)
local depBox = Section:CreateDependencyBox()
depBox:CreateSlider("DepSlider", { Text = "only visible when toggle is on", ... })
depBox:SetupDependencies({ { someToggle, true } })

-- Nested sections
local sub = Section:CreateSection("sub section")

-- Keybind (standalone)
Section:CreateKeybind({ Name = "Menu Keybind", CurrentKeybind = "RightShift" })

-- Notifications
Library.Notify({ Title = "Ivory", Content = "message", Type = "Success", Duration = 3 })

-- ObsidianUltra compat methods
Library:Create("Frame", { Parent = Library.ScreenGui, ... })
Library:AddToRegistry(instance, props)
Library:OnUnload(callback)
Library:Unload() / Library:Destroy()
Library:Toggle()
Library.Toggled
Library.ScreenGui
Library.MainFrame
Library.KeybindFrame
Library.Toggles
Library.Options
Library.Scheme
Library:UpdateColorsUsingRegistry()
Library:RemoveFromRegistry(instance)
```

## Window Setup

```lua
local Window = Library.CreateWindow({
    Name = "Ivory",
    Width = 720,
    Height = 600,
})
```

## Mobile Support

- Title bar is touch-draggable
- **Re-center button** appears automatically on mobile devices only (touch-enabled, no keyboard)
- Re-center button is a small circle with a ring, positioned left of minimize/close
- Tapping it tweens the window back to screen center

## Tab Structure

Tabs are created with `Window:CreateTab()`. Each tab has sections created with `Tab:CreateSection()`.

```lua
local Tabs = {
    Combat = Window:CreateTab({ Name = "Combat" }),
    Visuals = Window:CreateTab({ Name = "Visuals" }),
    World = Window:CreateTab({ Name = "World" }),
    Misc = Window:CreateTab({ Name = "Misc" }),
    ["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

local combatSection = Tabs.Combat:CreateSection("aimbot")
local espSection = Tabs.Visuals:CreateSection("esp")
```

### Typical Tab Layout

```
Tab: Combat
  Section: aimbot
  Section: gun
  Section: ragebot

Tab: Visuals
  Section: esp
  Section: utility
  Section: lighting

Tab: World
  Section: hit effects
  Section: hit sounds
  Section: view model

Tab: Misc
  Section: miscellaneous
  Section: textures

Tab: UI Settings
  Section: credits
  Section: menu settings
  Section: server
  Section: themes
  Section: configuration
```

## Settings Tab (Always Last)

Must include:

- Credits section
- Menu settings section with:
  - Menu keybind picker (RightShift default)
  - Keybind list toggle
  - FPS cap slider
  - Language dropdown
  - Anti AFK toggle
  - Custom cursor toggle
  - Test notification button
  - Notification side dropdown (Left/Right)
  - DPI scale dropdown (50%-200%)
  - Corner radius slider (0-20)
  - Unload button
- Server section with rejoin/hop buttons
- Themes section with color pickers
- Configuration section with config save/load

## Loader Entry (IvoryHub.luau)

Add your game PlaceId(s) to the loader:

```lua
local GameScripts = {
    [PLACEID] = "games/YourGame.luau",
}
```

## Library Loading Pattern

Always use this pattern to load the library (handles HTTP differences across executors):

```lua
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
-- Strip UTF-8 BOM if present
if LIB_SRC:byte(1) == 0xEF and LIB_SRC:byte(2) == 0xBB and LIB_SRC:byte(3) == 0xBF then
    LIB_SRC = LIB_SRC:sub(4)
end
local Library = loadstring(LIB_SRC)()
if not Library then
    error("[Ivory] Failed to compile library")
end
```

## Difficulty Selection (Games with Difficulty)

For games with difficulty modes (NORMAL, HARDCORE, NIGHTMARE), add a dropdown in the Lobby section:

```lua
cfg.difficulty = "NORMAL"

LobbySection:CreateDropdown({
    Name = "Difficulty",
    Values = { "NORMAL", "HARDCORE", "NIGHTMARE" },
    CurrentOption = "NORMAL",
    Callback = function(v)
        cfg.difficulty = v
    end,
})

LobbySection:CreateButton({
    Name = "Select Difficulty",
    Callback = function()
        -- Find and interact with difficulty selection
        local difficultyPart = workspace:FindFirstChild("DifficultySelect")
        if difficultyPart then
            local prompt = difficultyPart:FindFirstChildOfClass("ProximityPrompt")
            if prompt and prompt.Enabled then
                local _, hrp = getChar()
                if hrp then
                    hrp.CFrame = difficultyPart.CFrame + Vector3.new(0, 3, 0)
                    task.wait(0.5)
                    fireproximityprompt(prompt)
                end
            end
        end
    end,
})
```

Update the footer to show difficulty when in lobby:

```lua
task.spawn(function()
    while true do
        local location = isLobby() and "Lobby" or (isGame() and "Game" or "Unknown")
        local diff = isLobby() and (" | " .. cfg.difficulty) or ""
        local footer = "v1.4 | " .. location .. diff .. " | " .. LocalPlayer.UserId
        pcall(function()
            Window:SetFooter(footer)
        end)
        task.wait(1)
    end
end)
```

## Checklist

Before submitting a script, verify all of these:

- [ ] Window title says "Ivory" (not the game name)
- [ ] Footer shows "v1.4 | Lobby/Game | UserId"
- [ ] Sections created with `Tab:CreateSection("name")` (not AddLeftGroupbox/AddRightGroupbox)
- [ ] All CreateButton calls use `{Name = "text", Callback = function() end}` format
- [ ] All CreateColorPicker calls chained on CreateLabel
- [ ] Settings tab with menu controls (always last tab)
- [ ] Game added to IvoryHub.luau loader with correct PlaceId(s)
- [ ] No game names anywhere in the UI
- [ ] Make sure that YOU HAVE TESTED THE ENTIRE SCRIPT, MADE SURE EVERYTHING WORKS AND YOU HAVE ADDED EVERY SINGLE POSSIBLE FEATURE.
- [ ] ALWAYS make sure there is a discord link https://discord.gg/bac on the main tab of the script that says "Join Discord For Dupe" and when you click it it copys the discord link to your clipboard
