-- PlaceId: 128736949265057
-- Ivory Hub - Gakuran (Bootstrapper)
-- Loads the UI library and game logic as separate chunks (200 registers each)

do
    local prev = _G.IvoryGakuran
    if prev and type(prev.Unload) == "function" then pcall(prev.Unload) end
end
_G.IvoryGakuran = { conns = {}, dead = false, loops = {} }

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/"
local GITHUB_API = "https://api.github.com/repos/hubivory/IvoryHub/commits?per_page=1"

local commitHash = "main"
pcall(function()
    local apiRes = request({ Url = GITHUB_API, Method = "GET" })
    if apiRes and apiRes.Body then
        local hash = apiRes.Body:match('"sha":"(%w+)"')
        if hash then commitHash = hash end
    end
end)

local function loadGameFile(filename)
    local url = GITHUB_RAW .. commitHash .. "/games/" .. filename
    local res = request({ Url = url, Method = "GET" })
    local content = res and res.Body or nil
    if not content then
        warn("[Ivory Gakuran] Failed to fetch: " .. filename)
        return false
    end
    if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
        content = content:sub(4)
    end
    local fn, err = loadstring(content)
    if not fn then
        warn("[Ivory Gakuran] Compile error in " .. filename .. ": " .. tostring(err))
        return false
    end
    fn()
    return true
end

-- Load UI library (sets _G.IvoryGakuranLib)
if not loadGameFile("GakuranLib.lua") then return end

-- Load game logic (reads _G.IvoryGakuranLib)
if not loadGameFile("GakuranLogic.lua") then return end

print("[Ivory Hub] Gakuran loaded!")
