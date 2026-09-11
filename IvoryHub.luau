--[[
    Ivory Hub - Loader
    This is the main entry point for all Ivory Hub scripts.
    It routes to the correct game script based on the PlaceId.
]]

local PlaceId = game.PlaceId

local GameScripts = {
    [126870639873289] = "games/126870639873289.luau", -- Jump for Animals
    [70654235200182] = "games/JumpingBaddies.luau", -- Baddie Jumping
}

local ScriptPath = GameScripts[PlaceId]

if not ScriptPath then
    error("[Ivory] Unsupported game. PlaceId: " .. tostring(PlaceId))
end

-- Fetch and execute the script
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

local success, err = pcall(function()
    -- Try to fetch from GitHub first
    local baseUrl = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/"
    local scriptSrc = httpGet(baseUrl .. ScriptPath)
    
    if scriptSrc and #scriptSrc > 0 then
        -- Strip UTF-8 BOM if present
        if scriptSrc:byte(1) == 0xEF and scriptSrc:byte(2) == 0xBB and scriptSrc:byte(3) == 0xBF then
            scriptSrc = scriptSrc:sub(4)
        end
        
        loadstring(scriptSrc)()
    else
        -- Fallback: try to load from workspace
        local files = listfiles and listfiles("IvoryHub") or {}
        for _, file in ipairs(files) do
            if file:match("%.luau?$") and file:find(tostring(PlaceId)) then
                local content = readfile("IvoryHub/" .. file)
                if content and #content > 0 then
                    loadstring(content)()
                    return
                end
            end
        end
        error("[Ivory] Failed to load game script. Check your connection.")
    end
end)

if not success then
    error("[Ivory] Error: " .. tostring(err))
end