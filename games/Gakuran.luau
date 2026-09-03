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
--// Patch window icon to use custom image
local IVORY_ICON = "rbxassetid://110090697336524"
task.spawn(function()
	task.wait()
	local function trySetIcon(parent)
		for _, gui in ipairs(parent:GetChildren()) do
			if gui:IsA("ScreenGui") then
				for _, obj in ipairs(gui:GetDescendants()) do
					if obj:IsA("ImageLabel") and obj.Size.X.Offset >= 20 and obj.Size.X.Offset <= 40 and obj.Size.Y.Offset >= 20 and obj.Size.Y.Offset <= 40 then
						local par = obj.Parent
						if par then
							for _, sib in ipairs(par:GetChildren()) do
								if sib:IsA("TextLabel") and sib.Text == "Ivory" then
									obj.Image = IVORY_ICON
									obj.ImageRectOffset = Vector2.new(0, 0)
									obj.ImageRectSize = Vector2.new(0, 0)
									return true
								end
							end
						end
					end
				end
			end
		end
		return false
	end
	pcall(function() trySetIcon(CoreGui) end)
	pcall(function() trySetIcon(LocalPlayer.PlayerGui) end)
end)
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
