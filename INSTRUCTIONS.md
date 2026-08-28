# Ivory Hub - Script Instructions

## Branding

- Window Title: `"Ivory"`
- Footer: `"v1.4 | Lobby/Game | UserId"` (copyable)
- All GUI text must say "Ivory" -- never display the game name

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

- [ ] Window title says "Ivory" (not the game name)
- [ ] Footer shows "v1.4 | Lobby/Game | UserId"
- [ ] Sub-tab sidebar structure with AddSubTab (not flat tabs)
- [ ] All AddButton calls use `Group:AddButton("Text", function() ... end)` format (not `{Text=..., Func=...}`)
- [ ] All AddColorPicker calls chained on AddLabel (not called directly on group)
- [ ] ThemeManager + SaveManager setup
- [ ] Settings tab with menu controls (always last tab)
- [ ] Game added to IvoryHub.luau loader with correct PlaceId(s)
- [ ] No game names anywhere in the UI
- [ ] Make sure that YOU HAVE TESTED THE ENTIRE SCRIPT, MADE SURE EVERYTHING WORKS AND YOU HAVE ADDED EVERY SINGLE POSSIBLE FEATURE.
- [ ] ALWAYS make sure there is a discord link https://discord.gg/MCWYKBdB4E on the main tab of the script that says "Join Discord For Dupe" and when you click it it copys the discord link to your clipboard
