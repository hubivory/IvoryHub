-- IVORY HUB | Gamepass Tools
-- Universal: works in any game
-- Features: fake purchases, scan gamepasses/products, log prompts, supported games

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

local LIB_FOLDER = "IvoryHub"
local LIB_FILE = LIB_FOLDER .. "/Library.lua"
local LIB_URL = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/library/IvoryHubLibrary.lua"
if not isfolder(LIB_FOLDER) then pcall(makefolder, LIB_FOLDER) end
if not isfile(LIB_FILE) then
	local src = httpGet(LIB_URL)
	if type(src) == "string" and #src > 0 then
		if src:byte(1) == 0xEF and src:byte(2) == 0xBB and src:byte(3) == 0xBF then
			src = src:sub(4)
		end
		pcall(writefile, LIB_FILE, src)
	end
end
local Library = loadstring(readfile(LIB_FILE))()

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local function copyText(text)
	local fn = setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set)
	if fn then
		local ok = pcall(fn, tostring(text))
		return ok
	end
	return false
end

local function commas(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	return (s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", ""))
end

local function getJson(url)
	local ok, res = pcall(function()
		return game:HttpGet(url, true)
	end)
	if not ok or type(res) ~= "string" then return nil end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, res)
	return ok2 and data or nil
end

local infoTypes = {
	Product = Enum.InfoType.Product,
	Gamepass = Enum.InfoType.GamePass,
	Asset = Enum.InfoType.Asset,
}

local infoCache = {}
local knownKinds = {}

local function getInfo(kind, id)
	local key = kind .. ":" .. tostring(id)
	if infoCache[key] ~= nil then return infoCache[key] end
	local info = false
	if infoTypes[kind] and tonumber(id) then
		local ok, res = pcall(function()
			return MarketplaceService:GetProductInfo(tonumber(id), infoTypes[kind])
		end)
		if ok and type(res) == "table" then
			info = res
		end
	end
	infoCache[key] = info
	return info
end

local function detectKind(id)
	local known = knownKinds[tostring(id)]
	if known then return known end
	for _, kind in ipairs({"Product", "Gamepass", "Asset"}) do
		if getInfo(kind, id) then
			knownKinds[tostring(id)] = kind
			return kind
		end
	end
	return "Product"
end

local function fakePurchase(id)
	local kind = detectKind(id)
	if kind == "Product" then
		MarketplaceService:SignalPromptProductPurchaseFinished(LocalPlayer.UserId, id, true)
	elseif kind == "Gamepass" then
		MarketplaceService:SignalPromptGamePassPurchaseFinished(LocalPlayer, id, true)
	elseif kind == "Asset" then
		MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer, id, true)
	end
	return kind
end

local Window = Library.CreateWindow({ Name = "Ivory" })

local HomeTab = Window:CreateTab("Home")
local FakerTab = Window:CreateTab("Faker")
local PassesTab = Window:CreateTab("Passes")
local LoggerTab = Window:CreateTab("Logger")
local SupportedTab = Window:CreateTab("Supported")
local SettingsTab = Window:CreateTab("UI Settings")

local function notify(title, content, ntype)
	pcall(function()
		Library.Notify({ Title = title or "Ivory", Content = content or "", Type = ntype or "Info", Duration = 4 })
	end)
end

HomeTab:CreateSection("Info")
HomeTab:CreateParagraph({
	Title = "Gamepass Tools",
	Content = "Fake purchases, scan gamepasses and products, log purchase prompts, and browse supported games."
})
HomeTab:CreateDivider()
HomeTab:CreateSection("Links")
HomeTab:CreateButton({
	Name = "Join Discord For Dupe",
	Callback = function()
		if copyText("https://discord.gg/bac") then
			notify("Ivory", "Discord link copied!", "Success")
		else
			notify("Ivory", "Clipboard unavailable", "Error")
		end
	end
})
HomeTab:CreateButton({
	Name = "Copy GitHub",
	Callback = function()
		if copyText("https://github.com/hubivory/IvoryHub") then
			notify("Ivory", "GitHub link copied!", "Success")
		end
	end
})

FakerTab:CreateSection("Fake Purchase")
FakerTab:CreateLabel("Enter a gamepass, product, or asset ID and click Fake to simulate a purchase.")

local idText = ""
FakerTab:CreateInput({
	Name = "ID",
	Placeholder = "Enter ID here",
	Flag = "FakeId",
	Callback = function(text)
		idText = tostring(text or "")
	end
})

FakerTab:CreateButton({
	Name = "Fake Purchase",
	Callback = function()
		local raw = idText
		if raw == "" then
			local flag = Library.Flags and Library.Flags.FakeId
			if flag and flag.Value then raw = tostring(flag.Value) end
		end
		local id = tonumber((raw:gsub("%s", "")):match("^%d+$"))
		if not id then
			notify("Ivory", "Enter a valid ID", "Error")
			return
		end
		local ok, kind = pcall(fakePurchase, id)
		if ok then
			notify("Ivory", "Fired " .. tostring(kind):lower() .. " " .. id, "Success")
		else
			notify("Ivory", "Error: " .. tostring(kind), "Error")
		end
	end
})

FakerTab:CreateDivider()
FakerTab:CreateParagraph({
	Title = "Note",
	Content = "This will NOT work in the majority of games. Only games that check client-side purchase signals will be affected."
})

local passElements = {}
local function clearPassElements()
	for _, el in ipairs(passElements) do
		pcall(function()
			if el.Frame then el.Frame:Destroy() end
		end)
		pcall(function()
			if el.Gui then el.Gui:Destroy() end
		end)
		pcall(function()
			if el.Destroy then el:Destroy() end
		end)
	end
	table.clear(passElements)
end

local function addToPassList(data)
	local kind = data.kind or "Gamepass"
	local price = data.price and ("R$" .. commas(data.price)) or "Offsale"
	local info = getInfo(kind, data.id)
	local name = data.name or (info and (info.Name or info.DisplayName)) or tostring(data.id)
	local el = PassesTab:CreateParagraph({
		Title = name,
		Content = kind .. "  |  " .. price .. "  |  ID: " .. tostring(data.id)
	})
	table.insert(passElements, el)
	local btn = PassesTab:CreateButton({
		Name = "  Use: " .. name,
		Callback = function()
			idText = tostring(data.id)
			notify("Ivory", "ID loaded: " .. tostring(data.id), "Info")
			pcall(function()
				Library.Flags.FakeId.Value = tostring(data.id)
			end)
		end
	})
	table.insert(passElements, btn)
end

PassesTab:CreateSection("Scanner")
PassesTab:CreateLabel("Scan the current game for gamepasses and developer products.")

local scanning = false
PassesTab:CreateButton({
	Name = "Scan Gamepasses & Products",
	Callback = function()
		if scanning then return end
		scanning = true
		notify("Ivory", "Scanning...", "Info")
		clearPassElements()

		task.spawn(function()
			local universeId = game.GameId
			local passes = nil
			local products = nil

			task.spawn(function()
				if universeId and universeId ~= 0 then
					local url = ("https://games.roblox.com/v1/games/%d/game-passes?limit=100&sortOrder=Asc"):format(universeId)
					local d = getJson(url)
					if d and type(d.data) == "table" then
						passes = {}
						for _, p in ipairs(d.data) do
							table.insert(passes, { id = p.id, name = p.displayName or p.name, price = p.price, kind = "Gamepass" })
						end
						local cursor = d.nextPageCursor
						local pages = 1
						while cursor and pages < 25 do
							local url2 = ("https://games.roblox.com/v1/games/%d/game-passes?limit=100&sortOrder=Asc&cursor=%s"):format(universeId, HttpService:UrlEncode(cursor))
							local d2 = getJson(url2)
							if not d2 or not d2.data then break end
							for _, p in ipairs(d2.data) do
								table.insert(passes, { id = p.id, name = p.displayName or p.name, price = p.price, kind = "Gamepass" })
							end
							cursor = d2.nextPageCursor
							pages = pages + 1
						end
					end
				end
			end)

			task.spawn(function()
				local ok, pager = pcall(function()
					return MarketplaceService:GetDeveloperProductsAsync()
				end)
				if ok and pager then
					products = {}
					for _ = 1, 50 do
						local okPage, page = pcall(function() return pager:GetCurrentPage() end)
						if not okPage then break end
						for _, item in ipairs(page) do
							local iconId = item.IconImageAssetId
							table.insert(products, {
								id = item.ProductId or item.DeveloperProductId,
								name = item.Name or item.DisplayName,
								price = item.PriceInRobux,
								icon = iconId and iconId ~= 0 and "rbxassetid://" .. iconId or nil,
								kind = "Product"
							})
						end
						if pager.IsFinished or not pcall(function() pager:AdvanceToNextPageAsync() end) then
							break
						end
					end
				end
			end)

			while (passes == nil or products == nil) do
				task.wait()
			end

			local all = {}
			if passes then
				for _, p in ipairs(passes) do table.insert(all, p) end
			end
			if products then
				for _, p in ipairs(products) do table.insert(all, p) end
			end

			table.sort(all, function(a, b)
				return (a.price or math.huge) < (b.price or math.huge)
			end)

			for _, item in ipairs(all) do
				if item.id then
					knownKinds[tostring(item.id)] = item.kind
					addToPassList(item)
				end
			end

			local nP, nD = passes and #passes or 0, products and #products or 0
			if not passes and not products then
				notify("Ivory", "Could not fetch passes or products", "Error")
			elseif not passes then
				notify("Ivory", ("Found %d products, gamepass fetch failed"):format(nD), "Warning")
			elseif not products then
				notify("Ivory", ("Found %d gamepasses, product fetch failed"):format(nP), "Warning")
			else
				notify("Ivory", ("Found %d gamepasses, %d products"):format(nP, nD), "Success")
			end
			scanning = false
		end)
	end
})

LoggerTab:CreateSection("Purchase Logger")
LoggerTab:CreateLabel("Automatically logs purchase prompts in the current game.")

local logElements = {}
local logLimit = 50
local lastPrompt = {}

local function addLogEntry(kind, id, info)
	local name = info and (info.Name or info.DisplayName) or tostring(id)
	local price = info and (info.PriceInRobux or info.Price)
	local priceStr = price and ("R$" .. commas(price)) or ""
	local time = os.date("%H:%M:%S")
	local content = kind .. (priceStr ~= "" and ("  |  " .. priceStr) or "") .. "  |  " .. time

	local el = LoggerTab:CreateParagraph({
		Title = name,
		Content = content
	})
	table.insert(logElements, el)

	if #logElements > logLimit then
		local old = table.remove(logElements, 1)
		pcall(function()
			if old.Frame then old.Frame:Destroy() end
		end)
		pcall(function()
			if old.Gui then old.Gui:Destroy() end
		end)
		pcall(function()
			if old.Destroy then old:Destroy() end
		end)
	end
end

local function logPrompt(kind, id)
	if id == nil then return end
	local key = kind .. ":" .. tostring(id)
	local now = os.clock()
	if lastPrompt[key] and now - lastPrompt[key] < 0.5 then return end
	lastPrompt[key] = now

	task.spawn(function()
		local info = getInfo(kind, id)
		knownKinds[tostring(id)] = kind
		addLogEntry(kind, id, info)
		notify("Ivory", ("Logged %s %s"):format(kind:lower(), tostring(id)), "Info")
	end)
end

local promptKinds = {
	ProductPurchase = "Product",
	GamePassPurchase = "Gamepass",
	Purchase = "Asset",
	BundlePurchase = "Bundle",
}

local hooked = 0
for suffix, kind in pairs(promptKinds) do
	local ok = pcall(function()
		MarketplaceService["Prompt" .. suffix .. "Requested"]:Connect(function(_, ...)
			local id = nil
			for i = 1, select("#", ...) do
				local v = select(i, ...)
				if type(v) == "number" or (type(v) == "string" and v ~= "") then
					id = v
					break
				end
			end
			logPrompt(kind, id)
		end)
	end)
	if ok then
		hooked = hooked + 1
	end
end

if hooked == 0 and hookmetamethod and getnamecallmethod then
	pcall(function()
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			local method = getnamecallmethod()
			if self == MarketplaceService and method:sub(1, 6) == "Prompt" then
				local kind = promptKinds[method:sub(7)]
				if kind then
					local id = select(2, ...)
					task.spawn(logPrompt, kind, id)
				end
			end
			return old(self, ...)
		end)
	end)
end

LoggerTab:CreateDivider()
LoggerTab:CreateButton({
	Name = "Clear Log",
	Callback = function()
		for _, el in ipairs(logElements) do
			pcall(function()
				if el.Frame then el.Frame:Destroy() end
			end)
			pcall(function()
				if el.Gui then el.Gui:Destroy() end
			end)
			pcall(function()
				if el.Destroy then el:Destroy() end
			end)
		end
		table.clear(logElements)
		notify("Ivory", "Log cleared", "Info")
	end
})

SupportedTab:CreateSection("Supported Games")
SupportedTab:CreateLabel("Games where client-side purchase checks are used.")

local supportedElements = {}
local SUPPORTED_URL = "https://loadstring.net/raw/TCiFuJc4kK"

local function clearSupported()
	for _, el in ipairs(supportedElements) do
		pcall(function()
			if el.Frame then el.Frame:Destroy() end
		end)
		pcall(function()
			if el.Gui then el.Gui:Destroy() end
		end)
		pcall(function()
			if el.Destroy then el:Destroy() end
		end)
	end
	table.clear(supportedElements)
end

SupportedTab:CreateButton({
	Name = "Load Supported Games",
	Callback = function()
		notify("Ivory", "Loading supported games...", "Info")
		clearSupported()

		task.spawn(function()
			local ok, list = pcall(function()
				return loadstring(game:HttpGet(SUPPORTED_URL))()
			end)
			if not ok or type(list) ~= "table" then
				notify("Ivory", "Could not load supported games list", "Error")
				return
			end

			local here = false
			for i, entry in ipairs(list) do
				local placeId, name = entry, nil
				if type(entry) == "table" then
					placeId = entry.PlaceId or entry[1]
					name = entry.Name
				end
				placeId = tonumber(placeId)
				if placeId then
					local isHere = placeId == game.PlaceId
					here = here or isHere
					local display = name or ("Place " .. placeId)
					local el = SupportedTab:CreateParagraph({
						Title = display .. (isHere and "  (You're here)" or ""),
						Content = "PlaceId: " .. placeId
					})
					table.insert(supportedElements, el)
					local btn = SupportedTab:CreateButton({
						Name = "  Teleport to " .. display,
						Callback = function()
							if isHere then
								notify("Ivory", "You're already in this game", "Warning")
							else
								notify("Ivory", "Teleporting...", "Info")
								pcall(function()
									TeleportService:Teleport(placeId, LocalPlayer)
								end)
							end
						end
					})
					table.insert(supportedElements, btn)
				end
			end

			if here then
				notify("Ivory", "This game is supported!", "Success")
			else
				notify("Ivory", ("Loaded %d supported games"):format(#list), "Info")
			end
		end)
	end
})

SettingsTab:CreateSection("UI Settings")
SettingsTab:CreateLabel("Customize the Ivory interface.")

local function updateFooter()
	local text = "v1.4 | " .. (game.PlaceId ~= 0 and tostring(game.PlaceId) or "Universal") .. " | " .. LocalPlayer.UserId
	pcall(function() Window:SetFooter(text) end)
end

task.spawn(function()
	while true do
		updateFooter()
		task.wait(30)
	end
end)
updateFooter()

print("[Ivory Hub] Gamepass Tools loaded!")
