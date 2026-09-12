# AGENTS.md

## Project state

IvoryHub - A Roblox exploit hub hosted on GitHub at `hubivory/IvoryHub`. Contains:
- `IvoryHub.luau` - Loader that routes PlaceIds to game scripts
- `games/*.luau` / `games/*.lua` - Per-game scripts (42+ games)
- `library/IvoryHubLibrary.lua` - Shared UI library

## Library loading (anti-detect)

All game scripts MUST use `getcustomasset` to load the UI library. Never use raw `loadstring(game:HttpGet(url))` — it gets flagged by BAC.

Standard pattern:
```lua
local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
    writefile(LIB_FILE, httpGet(LIB_URL))
end
local Library = loadstring(readfile(LIB_FILE))()
```

## UI Library API

- `Library.CreateWindow({Name = "Ivory", Width = 720, Height = 600})` - Creates main window
- `Window:CreateTab({Name = "TabName"})` - Creates a tab
- `Tab:CreateSection("name")` - Creates a section (NOT AddLeftGroupbox/AddRightGroupbox)
- `Section:CreateButton({Name = "text", Callback = fn})` - Button
- `Section:CreateToggle({Name, CurrentValue, Callback})` - Toggle
- `Section:CreateDropdown({Name, Values, CurrentOption, Callback})` - Dropdown
- `Section:CreateKeybind({Name, CurrentKeybind, Callback})` - Keybind
- `Section:CreateLabel({Text})` - Label
- `Library:Unload()` - Unloads the library
- `Library.Notify({Title, Content, Type, Duration})` - Shows notification
- `Window:SetFooter(text)` - Sets footer text

## Branding conventions

- Window title: "Ivory" (never the game name)
- Footer format: `v1.4 | Lobby/Game | UserId`
- Discord link: `https://discord.gg/bac` (labeled "Join Discord For Dupe")
- Config tab is always the last tab, named "UI Settings"

## When creating new game scripts

1. Add the PlaceId-to-script mapping in `IvoryHub.luau` loader
2. Use the standard library loading pattern above
3. Include: Discord button, footer with version/location/userid, Settings tab as last tab
4. Use `Section:CreateButton/Toggle/Dropdown` API (NOT AddLeftGroupbox/AddRightGroupbox)
