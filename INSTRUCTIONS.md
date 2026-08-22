# Ivory Hub - Script Instructions

## Branding

- Window Title: "Ivory"
- Footer: "v1.4 | Lobby/Game | UserId" (copyable)
- All GUI text must say "Ivory" -- never display the game name
- Key UI header: "Ivory Hub"

## Key System

Every script MUST include this block at the very top, before any other code:

```lua
-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ═══════════════════════════════════════════════════════════════
local _k = { v = false, s = nil, h = nil, i = nil, t = 0 }
local _hwid = tostring(math.random(100000,999999)) .. tostring(tick()):sub(-6)
local _integritySalt = 0x4A
local function _verifyIntegrity()
    if not _k or not _k.v then return false end
    if _k.i ~= (_integritySalt + #(_k.s or "")) then _k.v = false; return false end
    return true
end
```

### Key UI Setup

```lua
local _kg = Instance.new("ScreenGui")
_kg.Name = "IvoryKey"
_kg.ResetOnSpawn = false
_kg.DisplayOrder = 9999
pcall(function() _kg.Parent = game:GetService("CoreGui") end)
if not _kg.Parent then _kg.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
```

### Key UI Layout (Frame: 380x265)

- Window: Dark Color3.fromRGB(20, 20, 25), UICorner 8, UIStroke purple 90, 60, 200
- Title: "Ivory Hub", color 200, 170, 255, size 22, GothamBold
- Subtitle: "Enter your key to continue", color 140, 140, 150, size 13
- TextBox: Dark input 30, 30, 38, placeholder "Paste your key here", Gotham code font, UICorner 6
- Verify Button: Purple 90, 60, 200, white text, GothamBold size 15, UICorner 6
- Status Label: Below verify button, shows errors/success
- Get Key Button: Clickable, dark 35, 35, 42 background, blue text 120, 180, 255, UICorner 4
  - Text: "Get Key - work.ink/2STL/Ivory"
  - On click: setclipboard("https://work.ink/2STL/Ivory") then show "Copied!" in green 80, 220, 120
   - Fallback: if setclipboard unavailable, show the URL as text
- Discord Button: Clickable, Discord blurple 88, 101, 242 background, white text, UICorner 4
  - Text: "Join for dupe"
  - On click: setclipboard("https://discord.gg/mrQFkCJfEe") then show "Copied!" in green
  - Fallback: if setclipboard unavailable, show "discord.gg/mrQFkCJfEe"

### Validation

```lua
local ok, res = pcall(function()
    return game:HttpGet("https://work.ink/_api/v2/token/isValid/" .. key .. "?deleteToken=1", true)
end)
```

On valid:
```lua
_k.v = true
_k.s = key
_k.h = _hwid
_k.t = os.time()
_k.i = 0x4A + #key
```

On invalid: show "Invalid key - get one at work.ink/2STL/Ivory"

### Integrity Check

Run every 45-90 seconds (random interval):

```lua
task.spawn(function()
    while true do
        task.wait(math.random(45, 90))
        if _k and _k.v and not _verifyIntegrity() then
            -- destroy the key GUI to lock the script
        end
    end
end)
```

### Waiting Loop

After key setup, block until validated:

```lua
local _awaiting = true
-- ... button connections set _awaiting = false on success ...
while _awaiting do task.wait(0.1) end
```

## Scattered Validation Checks

**Every feature loop** must check _k before executing. Use 4 different patterns randomly:

| Pattern | Where |
|---------|-------|
| nd _k and _k.v and _k.i | Main automation features |
| nd _k and _k.v and _k.s | Secondary automation |
| nd _k and _k.v | Simple toggles |
| nd _k and _k.v and _verifyIntegrity() | Speed/movement (risky) |

Example:
```lua
if STATE.AutoFarm and _k and _k.v and _k.i then
    -- feature code
end
```

**Do NOT** put the check only in one place. Spread them across ALL feature loops.

## UI Library: ObsidianUltra

```lua
local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
```

## Window Setup

```lua
local Window = Library:CreateWindow({
    Title = "Ivory",
    Icon = "swords",
    Footer = {
        "v1.4 |",
        { Text = isLobby and "Lobby" or "Game", Copyable = true },
        "|",
        { Text = tostring(LocalPlayer.UserId), Copyable = true },
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
    Animations = {
        ToggleWindow = false,
        TabSwitch = false,
        Groupbox = false,
        Dropdown = false,
        KeyPicker = false,
        SubTabUnderline = true,
    },
})
```

## Tab Structure (Sub-Tab Sidebar Style)

Use AddSubTab() for sidebar dropdowns. Do NOT create flat tabs for sub-sections.

```lua
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local SubTab = MainTab:AddSubTab("Automation", "zap")
local Group = SubTab:AddLeftGroupbox("Feature Group", "box-icon")
```

### Typical Tab Layout

`
Tab: Main
  SubTab: Automation
    LeftGroupbox: Core Features
    RightGroupbox: Extra Features
  SubTab: Config
    LeftGroupbox: Settings

Tab: Shop/Tools
  SubTab: Category A
    LeftGroupbox: ...
    RightGroupbox: ...
  SubTab: Category B

Tab: Player
  SubTab: Movement
    LeftGroupbox: Speed
    RightGroupbox: Jump
  SubTab: Visuals
    LeftGroupbox: ESP

Tab: Settings (always last)
  ThemeManager:ApplyToTab(SettingsTab)
  SaveManager:BuildConfigSection(SettingsTab)
  LeftGroupbox: Menu (keybind, cursor, DPI, unload)
`

## Theme and Save Manager

```lua
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
if isGame then
    SaveManager:SetSubFolder("game")
else
    SaveManager:SetSubFolder("lobby")
end
```

## Settings Tab (Always Last)

Must include:

- ThemeManager section
- SaveManager config section
- Menu groupbox with:
  - Keybind menu toggle
  - Custom cursor toggle
  - Test notification button
  - Notification side dropdown (Left/Right)
  - DPI scale dropdown (50%-200%)
  - Corner radius slider (0-20)
  - Menu keybind picker (RightShift default)
  - Unload button

## Loader Entry (IvoryHub.luau)

Add your game PlaceId(s) to the loader:

```lua
local GameScripts = {
    [PLACEID] = "games/YourGame.luau",
}
```

## Checklist

Before submitting a script, verify all of these:

- [ ] Key system block at very top of file
- [ ] Key UI with Ivory branding, Get Key button, work.ink validation
- [ ] Window title says "Ivory" (not the game name)
- [ ] Footer shows "v1.4 | Lobby/Game | UserId"
- [ ] Sub-tab sidebar structure with AddSubTab (not flat tabs)
- [ ] Scattered _k checks across ALL feature loops using 4 different patterns
- [ ] Integrity check running in background (45-90s interval)
- [ ] ThemeManager + SaveManager setup
- [ ] Settings tab with menu controls (always last tab)
- [ ] Game added to IvoryHub.luau loader with correct PlaceId(s)
- [ ] No game names anywhere in the UI
