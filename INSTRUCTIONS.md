# Ivory Hub - Script Instructions

## Branding

- Window Title: `"Ivory"`
- Footer: `"v1.4 | Lobby/Game | UserId"` (copyable)
- All GUI text must say "Ivory" -- never display the game name
- Key UI header: `"Ivory Hub"`

## Key System

Every script MUST include this block at the very top, before any other code:

```lua
-- ═══════════════════════════════════════════════════════════════
-- KEY SYSTEM - DO NOT MODIFY THIS BLOCK
-- ═══════════════════════════════════════════════════════════════
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

### Key UI Layout (Frame: 380x295)

- Window: Dark `Color3.fromRGB(20, 20, 25)`, UICorner 8, UIStroke purple `90, 60, 200`
- Title: "Ivory Hub", color `200, 170, 255`, size 22, GothamBold
- Subtitle: "Enter your key to continue", color `140, 140, 150`, size 13
- TextBox: Dark input `30, 30, 38`, placeholder "Paste your key here", Gotham code font, UICorner 6
- Verify Button: Purple `90, 60, 200`, white text, GothamBold size 15, UICorner 6
- Status Label: Below verify button, shows errors/success

### 3 Key Buttons (below status label, stacked vertically)

**Button 1 - Discord (y=188, height=20)**
- Background: Discord blurple `88, 101, 242`
- Text: `"Join for dupe"`, white, GothamBold size 11
- UICorner 4
- On click: `setclipboard("https://discord.gg/mrQFkCJfEe")`, show "Copied!" in green `80, 220, 120`, revert after 1.5s
- Fallback: display URL as text

**Button 2 - Work.ink (y=212, height=20)**
- Background: dark `35, 35, 42`
- Text: `"Get Key - Work.ink"`, blue `120, 180, 255`, GothamBold size 11
- UICorner 4
- On click: `setclipboard("https://work.ink/2STL/Ivory")`, show "Copied!" in green, revert after 1.5s
- Fallback: display URL as text

**Button 3 - LootLabs (y=236, height=20)**
- Background: dark `35, 35, 42`
- Text: `"Get Key - LootLabs"`, purple `200, 130, 255`, GothamBold size 11
- UICorner 4
- On click: `setclipboard("https://loot-link.com/s?L6z5Q0nE")`, show "Copied!" in green, revert after 1.5s
- Fallback: display URL as text

### LootLabs Key (XOR Obfuscated)

The LootLabs key is embedded directly in the script, NOT fetched from a public file.
Encoded with XOR so the plaintext never appears in source or bytecode strings.
To rotate: encode the new key with `ord(char) ^ 0x5A` and update the `_b` table.

```lua
local _lootKey = ""
do
    local _s = 0x5A
    local _b = {19,12,21,8,3,119,8,99,109,29,119,15,98,0,2,119,24,22,22,22,119,30,105,25,0}
    local _c = {}
    for _i = 1, #_b do _c[_i] = string.char(_b[_i] ~ _s) end
    _lootKey = table.concat(_c)
end
```

### Dual Validation (Work.ink + LootLabs)

In `_doValidate(key)`, check LootLabs key FIRST (exact match), then fall back to Work.ink API:

```lua
-- LootLabs check (exact match against embedded key)
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
    _st.Text = "Access granted"
    _st.TextColor3 = Color3.fromRGB(80, 220, 120)
    _btn.Text = "Loading..."
    task.wait(0.4)
    _awaiting = false
    _kg:Destroy()
    return
end

-- Work.ink check (API validation)
local ok, res = pcall(function()
    return request({ Url = "https://work.ink/_api/v2/token/isValid/" .. key .. "?deleteToken=1", Method = "GET" })
end)
if ok and res and res.Body then
    local s, data = pcall(function()
        return json.decode(res.Body)
    end)
    if s and type(data) == "table" and data.valid then
        -- grant access (see below)
    end
end
```

On valid Work.ink response:
```lua
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
```

On invalid: show `"Invalid key - get one at work.ink/2STL/Ivory"`

**Do NOT** remove `deleteToken=1` from the Work.ink URL -- required by Work.ink.

### Key Persistence (writefile/readfile)

Saves to disk with `writefile`/`readfile` so it survives rejoins. Falls back to `getgenv()`.
Format: `key\nexpiry\nhwid` (3 lines). HWID binds the key to one machine.

**On startup** (right after `local _awaiting = true`, BEFORE the Discord button):

```lua
local _savedKey = nil
local _savedExpiry = nil
local _savedHwid = nil
pcall(function()
    if isfile("IvoryKey.txt") then
        local data = readfile("IvoryKey.txt")
        _savedKey, _savedExpiry, _savedHwid = data:match("^(.-)\n(.-)\n?(.-)$")
        _savedExpiry = tonumber(_savedExpiry)
        if _savedHwid == "" then _savedHwid = nil end
    end
end)
if not _savedKey then
    pcall(function() _savedKey = _genv._ivoryKey end)
    pcall(function() _savedExpiry = _genv._ivoryExpiry end)
end

if _savedKey and _savedExpiry and os.time() * 1000 < _savedExpiry then
    if _savedHwid and _savedHwid ~= _hwid then
        pcall(function() delfile("IvoryKey.txt") end)
    else
        _k.v = true
        _k.s = _savedKey
        _k.h = _hwid
        _k.t = os.time()
        _k.i = 0x4A + #_savedKey
        _awaiting = false
        pcall(function() _kg:Destroy() end)
    end
end
```

### Integrity Check

Run every 45-90 seconds (random interval):

```lua
task.spawn(function()
    while true do
        task.wait(math.random(45, 90))
        if _k and _k.v and not _verifyIntegrity() then
            pcall(function()
                for _, gui in ipairs(game:GetService("CoreGui"):GetDescendants()) do
                    if gui.Name == "IvoryKey" then gui:Destroy() end
                end
            end)
        end
    end
end)
```

### Waiting Loop

After key setup, block until validated:

```lua
local _awaiting = true
-- ... persistence check, buttons, etc set _awaiting = false on success ...
while _awaiting do task.wait(0.1) end
```

## Scattered Validation Checks

**Every feature loop** must check `_k` before executing. Use 4 different patterns randomly:

| Pattern | Where |
|---------|-------|
| `and _k and _k.v and _k.i` | Main automation features |
| `and _k and _k.v and _k.s` | Secondary automation |
| `and _k and _k.v` | Simple toggles |
| `and _k and _k.v and _verifyIntegrity()` | Speed/movement (risky) |

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
local function httpGet(url)
    return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()
```

### ObsidianUltra Key API Notes

- `AddSubTab(Name, Icon)` -- creates sidebar dropdown + button row. Parent tab hides its own columns once it has sub tabs.
- `SubTab:AddLeftGroupbox(Name, Icon)` / `SubTab:AddRightGroupbox(Name, Icon)` -- columns inside sub tabs.
- `AddToggle`, `AddSlider`, `AddDropdown`, `AddLabel`, `AddDivider` -- standard elements.
- `AddButton` takes a string and callback: `Group:AddButton("Text", function() ... end)` -- do NOT use `{Text = ..., Func = ...}`.
- `Dropdown` supports `Searchable = true`, `Expandable = true`, `Multi = true`, `SelectAllButtons = true`.
- `AddKeyPicker` attaches to toggles: `:AddKeyPicker("Name", { Default, Text, Mode, SyncToggleState, NoUI })`.
- `AddColorPicker` must be chained on a label: `Group:AddLabel("Label Text"):AddColorPicker("Name", { Default, Title, Callback })`.
- `Library:Notify({ Title, Description, Type, Time })` -- Type is "Success", "Info", or "Error".
- `Library.Scheme.BlueColor` -- available for custom elements.
- `Window:SetMinimized(true/false)`, `Window:ToggleMinimized()`.
- Minimize keybind, custom cursor, DPI scale, corner radius all configurable in Settings tab.

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

Use `AddSubTab()` for sidebar dropdowns. Do NOT create flat tabs for sub-sections.

```lua
local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local SubTab = MainTab:AddSubTab("Automation", "zap")
local Group = SubTab:AddLeftGroupbox("Feature Group", "box-icon")
```

### Typical Tab Layout

```
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
```

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
- [ ] 3 key buttons: Discord ("Join for dupe"), Work.ink, LootLabs
- [ ] LootLabs key embedded obfuscated (table parts, not fetched from public file)
- [ ] Dual validation: LootLabs exact match first, then Work.ink API
- [ ] Key persistence: writefile/readfile to IvoryKey.txt, fallback to getgenv
- [ ] Key saved after BOTH LootLabs and Work.ink validation
- [ ] Window title says "Ivory" (not the game name)
- [ ] Footer shows "v1.4 | Lobby/Game | UserId"
- [ ] Sub-tab sidebar structure with AddSubTab (not flat tabs)
- [ ] All AddButton calls use `Group:AddButton("Text", function() ... end)` format (not `{Text=..., Func=...}`)
- [ ] All AddColorPicker calls chained on AddLabel (not called directly on group)
- [ ] Scattered _k checks across ALL feature loops using 4 different patterns
- [ ] Integrity check running in background (45-90s interval)
- [ ] ThemeManager + SaveManager setup
- [ ] Settings tab with menu controls (always last tab)
- [ ] Game added to IvoryHub.luau loader with correct PlaceId(s)
- [ ] No game names anywhere in the UI
- [ ] Make sure that YOU HAVE TESTED THE ENTIRE SCRIPT, MADE SURE EVERYTHING WORKS AND YOU HAVE ADDED EVERY SINGLE POSSIBLE FEATURE.




