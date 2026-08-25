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
    [138501044883253] = "games/BuildABurger.luau",
    [105963809208632] = "games/BuildABurger.luau",
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

    -- Pre-load ObsidianUltra library so game scripts don't need their own HTTP
    local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
    local function httpGet(url)
        return request({ Url = url, Method = "GET" }).Body
    end
    pcall(function()
        local genv = getgenv()
        if not genv._IvoryUILoaded then
            local req = request
            local env = setmetatable({}, { __index = getfenv(0) })
            env.request = req
            env.http_request = req

            local libFn = loadstring(httpGet(repo .. "Library.lua"))
            if libFn then setfenv(libFn, env) end
            genv._IvoryLib = libFn and libFn() or nil

            local tmFn = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))
            if tmFn then setfenv(tmFn, env) end
            genv._IvoryThemeManager = tmFn and tmFn() or nil

            local smFn = loadstring(httpGet(repo .. "addons/SaveManager.lua"))
            if smFn then setfenv(smFn, env) end
            genv._IvorySaveManager = smFn and smFn() or nil

            genv._IvoryUILoaded = genv._IvoryLib ~= nil
            if genv._IvoryUILoaded then
                print("[Ivory Hub] ObsidianUltra loaded")
            else
                warn("[Ivory Hub] ObsidianUltra failed to initialize")
            end
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
