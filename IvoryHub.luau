--// Ivory Hub - Loader
--// https://github.com/hubivory/IvoryHub
--// Automatically loads the script for your current game

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/"
local GITHUB_API = "https://api.github.com/repos/hubivory/IvoryHub/commits?per_page=1"

local GameScripts = {
	[7243409883] = "games/ElementalMagicArena.luau",
	[116497287371701] = "games/Karinderya.luau",
	[99521272836282] = "games/FinalSwarm.luau",
	[79787558257549] = "games/FinalSwarm.luau",
	[95919006508862] = "games/MeltTheIce.luau",
	[1962086868] = "games/Towerofhell.luau",
	[138501044883253] = "games/BuildABurger.luau",
	[105963809208632] = "games/BuildABurger.luau",
	[100293509865504] = "games/CatchABillionDucks.luau",
	[120617974337690] = "games/CatchABillionDucks.luau",
	[137363360166684] = "games/RocksRNG.luau",
	[9772878203] = "games/Floppa2.luau",
	[13772394625] = "games/Bladeball_BAC.luau",
	[16281300371] = "games/Bladeball_BAC.luau",
	[142823291] = "games/MM2.luau",
	[17516596118] = "games/Hypershot.luau",
	[92637789841354] = "games/CleanAllTheLeaves.luau",
	[100068273119174] = "games/CleanAllTheLeaves.luau",
	[114697347887839] = "games/Monkeyescape.luau",
	[120851538706364] = "games/Murderduels.luau",
	[2753915549] = "games/Bloxfruits.luau",
	[79091703265657] = "games/Bloxfruits.luau",
	[114234929420007] = "games/Bloxstrike.luau",
	[83038462357724] = "games/DigAndClean.luau",
	[117539213094671] = "games/RollAGnome.luau",
	[90086669327265] = "games/cutgrass.luau",
	[9285238704] = "games/raceclick.luau",
	[107778070777162] = "games/StealAnEgg.luau",
	[128736949265057] = "games/Gakuran.luau",
	[72920620366355] = "games/Operationone.luau",
	-- Add more: [PlaceId] = "games/ScriptName.luau"
}

local UniverseScripts = {
	[4777817887] = "games/Bladeball_BAC.luau",
	-- Add more: [UniverseId] = "games/ScriptName.luau"
}

local PlaceId = game.PlaceId
local ScriptFile = GameScripts[PlaceId] or UniverseScripts[game.GameId]

if not ScriptFile then
	--// No game script found, load universal splash screen
	local commitHash = "main"
	pcall(function()
		local apiRes = request({ Url = GITHUB_API, Method = "GET" })
		if apiRes and apiRes.Body then
			local hash = apiRes.Body:match('"sha":"(%w+)"')
			if hash then commitHash = hash end
		end
	end)
	local url = GITHUB_RAW .. commitHash .. "/universal_script.luau"
	local res = request({ Url = url, Method = "GET" })
	local content = res and res.Body or nil
	if content then
		if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
			content = content:sub(4)
		end
		loadstring(content)()
	end
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
			if hash then
				commitHash = hash
			end
		end
	end)

	-- Pre-fetch ObsidianUltra source code for game scripts
	local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
	pcall(function()
		local genv = getgenv()
		genv._IvoryLibSrc = request({ Url = repo .. "Library.lua", Method = "GET" }).Body
		genv._IvoryTMSrc = request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body
		genv._IvorySMSrc = request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body
		print("[Ivory Hub] ObsidianUltra sources cached")
	end)

	local url = GITHUB_RAW .. commitHash .. "/" .. ScriptFile
	local res = request({ Url = url, Method = "GET" })
	local content = res and res.Body or nil
	if not content then
		error("HTTP fetch failed")
	end
	-- Strip UTF-8 BOM if present
	if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
		content = content:sub(4)
	end
	local fn, loadErr = loadstring(content)
	if not fn then
		error("Compile error: " .. tostring(loadErr))
	end
	fn()
end)

if success then
	print("[Ivory Hub] Loaded successfully!")
else
	warn("[Ivory Hub] Failed to load:", err)
end
