--// Ivory Hub - Loader
--// https://github.com/hubivory/IvoryHub
--// Automatically loads the script for your current game

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/"

local GameScripts = {
    [116497287371701] = "games/Karinderya.luau",
    [99521272836282] = "games/FinalSwarm.luau",
    [79787558257549] = "games/FinalSwarm.luau",
    [95919006508862] = "games/MeltTheIce.luau",
    [1962086868] = "games/Towerofhell.luau",
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
    local res = request({ Url = GITHUB_RAW .. ScriptFile, Method = "GET" })
    local content = res and res.Body or nil
    if not content then error("HTTP fetch failed") end
    -- Strip UTF-8 BOM if present
    if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
        content = content:sub(4)
    end
    loadstring(content)()
end)

if success then
    print("[Ivory Hub] Loaded successfully!")
else
    warn("[Ivory Hub] Failed to load:", err)
end
