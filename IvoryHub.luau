--// Ivory Hub - Loader
--// https://github.com/hubivory/IvoryHub
--// Automatically loads the script for your current game

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/"
local GITHUB_API = "https://api.github.com/repos/hubivory/IvoryHub/commits?per_page=1"

local GameScripts = {
    [116497287371701] = "games/Karinderya.luau",
    [99521272836282] = "games/FinalSwarm.luau",
    [79787558257549] = "games/FinalSwarm.luau",
    [95919006508862] = "games/MeltTheIce.luau",
    [1962086868] = "games/Towerofhell.luau",
    [138501044883253] = "games/BurgerPerfect.luau",
    [105963809208632] = "games/BurgerPerfect.luau",
    [100293509865504] = "games/CatchABillionDucks.luau",
    [120617974337690] = "games/CatchABillionDucks.luau",
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
    -- Get latest commit hash to bypass CDN cache
    local commitHash = "main"
    pcall(function()
        local apiRes = request({ Url = GITHUB_API, Method = "GET" })
        if apiRes and apiRes.Body then
            local hash = apiRes.Body:match('"sha":"(%w+)"')
            if hash then commitHash = hash end
        end
    end)
    local url = GITHUB_RAW .. commitHash .. "/" .. ScriptFile
    local res = request({ Url = url, Method = "GET" })
    local content = res and res.Body or nil
    if not content then error("HTTP fetch failed") end
    -- Strip UTF-8 BOM if present
    if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
        content = content:sub(4)
    end
    local fn, loadErr = loadstring(content)
    if not fn then error("Compile error: " .. tostring(loadErr)) end
    fn()
end)

if success then
    print("[Ivory Hub] Loaded successfully!")
else
    warn("[Ivory Hub] Failed to load:", err)
end
