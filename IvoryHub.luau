--[[
    IvoryHub - Loader
    PlaceId: 90086669327265 (Cut Grass Adventure)
    
    This loader routes to the correct script based on the game.
    Add your PlaceId(s) to the GameScripts table below.
]]

local PlaceId = game.PlaceId

local GameScripts = {
    [90086669327265] = "games/cutgrass.luau",
}

local scriptPath = GameScripts[PlaceId]

if scriptPath then
    print("[IvoryHub] Loading script for PlaceId: " .. PlaceId)
    loadstring(readfile(scriptPath))()
else
    warn("[IvoryHub] No script configured for PlaceId: " .. PlaceId)
    warn("[IvoryHub] Supported PlaceIds: " .. table.concat(GameScripts, ", "))
end
