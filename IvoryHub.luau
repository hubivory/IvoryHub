--// Ivory Hub - Loader
--// https://github.com/hubivory/IvoryHub
--// Automatically loads the script for your current game

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/"

local GameScripts = {
    [116497287371701] = "games/Karinderya.luau",
    -- Add more: [PlaceId] = "games/ScriptName.luau"
}

local PlaceId = game.PlaceId
local ScriptFile = GameScripts[PlaceId]

if not ScriptFile then
    warn("[Ivory Hub] Unsupported game: " .. PlaceId)
    return
end

print("[Ivory Hub] Loading for game: " .. PlaceId)

local success, err = pcall(function()
    local content = game:HttpGet(GITHUB_RAW .. ScriptFile)
    loadstring(content)()
end)

if success then
    print("[Ivory Hub] Loaded successfully!")
else
    warn("[Ivory Hub] Failed to load:", err)
end