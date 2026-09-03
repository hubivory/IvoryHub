--// Ivory Hub - 99 Nights
--// PlaceIds: 13271790403, 14502339080

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local function httpGet(url)
	return request({ Url = url, Method = "GET" }).Body
end
local Library = loadstring(httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(httpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
	Title = "Ivory",
	Icon = "moon",
	Footer = {
		"v1.4 |",
		{ Text = "99 Nights", Copyable = true },
		"|",
		{ Text = tostring(LocalPlayer.UserId), Copyable = true },
	},
	CopyableFooter = true,
	FuzzySearch = true,
	SearchValues = true,
	Minimizable = true,
	MinimizeKeybind = Enum.KeyCode.RightBracket,
	MinimizedWidth = 280,
	NotifySide = "Right",
	ShowCustomCursor = true,
	SearchKeybind = Enum.KeyCode.F,
	CornerRadius = 4,
	Animations = {SubTabUnderline = true},
})

if Library.ScreenGui and Library.ScreenGui.Parent and Library.ScreenGui.Parent ~= game:GetService("CoreGui") then
	Library.ScreenGui.Parent = game:GetService("CoreGui")
end

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub")
SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("99Nights")

local function getChar() return LocalPlayer.Character end
local function getHRP() local c = getChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function getHumanoid() local c = getChar() return c and c:FindFirstChildOfClass("Humanoid") end
local function notify(title, msg) pcall(function() Library:Notify({ Title = title, Description = msg, Type = "Info", Time = 3 }) end) end

local function getRemoteEvents()
	local ok, folder = pcall(function() return ReplicatedStorage:WaitForChild("RemoteEvents", 10) end)
	if ok and folder then
		return {
			RequestStartDraggingItem = folder:FindFirstChild("RequestStartDraggingItem"),
			StopDraggingItem = folder:FindFirstChild("StopDraggingItem"),
			RequestConsumeItem = folder:FindFirstChild("RequestConsumeItem"),
			RequestOpenItemChest = folder:FindFirstChild("RequestOpenItemChest"),
			ToolDamageObject = folder:FindFirstChild("ToolDamageObject"),
		}
	end
	return {}
end

local REMOTES = getRemoteEvents()

local function notifyRemote(name)
	if not REMOTES[name] then
		notify("Error", name .. " remote not found in this game version")
		return false
	end
	return true
end

local FUEL_ITEMS = { Log = true, Coal = true, ["Oil Barrel"] = true, ["Fuel Canister"] = true, Cultist = true, ["Bear Corpse"] = true, ["Alpha Wolf Corpse"] = true, ["Wolf Corpse"] = true, ["Crossbow Cultist"] = true }
local METAL_ITEMS = { Bolt = true, ["Sheet Metal"] = true, ["UFO Junk"] = true, ["UFO Component"] = true, ["Broken Fan"] = true, ["Broken Radio"] = true, ["Broken Microwave"] = true, Tyre = true, ["Metal Chair"] = true, ["Old Car Engine"] = true, ["Cultist Experiment"] = true, ["Washing Machine"] = true, ["Cultist Prototype"] = true, ["UFO Scrap"] = true }
local FOOD_ITEMS = { Steak = true, ["BBQ Ribs"] = true, ["Candy Apple"] = true, Carrot = true, Berry = true, ["Cotton Candy"] = true, Chili = true, ["Lava Eel"] = true, ["Candy Corn"] = true, Morsel = true, Stew = true, Corn = true, Pumpkin = true, Casserole = true, Apple = true, ["Berry Juice"] = true, Ribs = true, Cake = true, ["Hearty Stew"] = true, Shark = true, Swordfish = true, Eel = true, Char = true, Mackerel = true, Salmon = true, Clownfish = true }
local AMMO_ITEMS = { ["Revolver Ammo"] = true, ["Rifle Ammo"] = true, ["Shotgun Ammo"] = true }
local TOOL_ITEMS = { Bandage = true, Rifle = true, Revolver = true, ["Laser Cannon"] = true, ["Ray Gun"] = true, ["Laser Sword"] = true, Katana = true, ["Strong Flashlight"] = true, ["Old Flashlight"] = true }

local bringState = { Fuel = false, Metal = false, Food = false, Ammo = false, Tools = false, Sapling = false, LogSingle = false, CoalSingle = false, MicrowaveSingle = false, SteakSingle = false }
local savedCFrame = nil

local function bringLoop(category, filter, singleName)
	task.spawn(function()
		while bringState[category] do
			local items = workspace:FindFirstChild("Items")
			if items and savedCFrame then
				for _, item in ipairs(items:GetChildren()) do
					if not bringState[category] then break end
					local match = false
					if filter then match = filter[item.Name] == true elseif singleName then match = item.Name == singleName end
					if match and item:IsA("Model") and item.PrimaryPart then
						if REMOTES.RequestStartDraggingItem and REMOTES.StopDraggingItem then
							REMOTES.RequestStartDraggingItem:FireServer(item)
							task.wait(0.1)
							item:PivotTo(savedCFrame * CFrame.new(0, 3, 0))
							task.wait(0.1)
							REMOTES.StopDraggingItem:FireServer(item)
						else
							item:PivotTo(savedCFrame * CFrame.new(0, 3, 0))
						end
						task.wait(0.2)
					end
				end
			end
			task.wait(1)
		end
	end)
end

local function stopAllBrings()
	for k in pairs(bringState) do bringState[k] = false end
	local hrp = getHRP()
	if hrp and savedCFrame then hrp.CFrame = savedCFrame; savedCFrame = nil end
	notify("Collection", "Stopped all bring functions.")
end

local function makeBringToggle(grp, label, stateKey, filter, singleName)
	grp:AddToggle("bring_" .. stateKey, { Text = "Bring " .. label, Default = false, Callback = function(val)
		bringState[stateKey] = val
		if val then local hrp = getHRP() if hrp then savedCFrame = hrp.CFrame end; bringLoop(stateKey, filter, singleName); notify("Collection", "Bring " .. label .. " Activated")
		else notify("Collection", "Bring " .. label .. " Deactivated") end
	end })
end

local espState = { Fuel = false, Metal = false, Food = false }
local espConnections = {}

local function clearESP(prefix)
	local items = workspace:FindFirstChild("Items")
	if items then for _, item in ipairs(items:GetChildren()) do local h = item:FindFirstChild(prefix .. "Highlight") if h then h:Destroy() end; local b = item:FindFirstChild(prefix .. "Billboard") if b then b:Destroy() end end end
end

local function addESP(item, prefix, filter, color)
	if not item:IsA("Model") or not item.PrimaryPart then return end
	if filter[item.Name] then
		if not item:FindFirstChild(prefix .. "Highlight") then local h = Instance.new("Highlight"); h.Name = prefix .. "Highlight"; h.FillColor = color; h.OutlineColor = Color3.fromRGB(255,255,255); h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.Adornee = item; h.Parent = item.PrimaryPart end
		if not item:FindFirstChild(prefix .. "Billboard") then local bb = Instance.new("BillboardGui"); bb.Name = prefix .. "Billboard"; bb.Adornee = item.PrimaryPart; bb.Size = UDim2.new(0,200,0,50); bb.StudsOffset = Vector3.new(0,3,0); bb.AlwaysOnTop = true; bb.Parent = item; local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1,0,1,0); tl.BackgroundTransparency = 1; tl.Text = item.Name; tl.TextColor3 = color; tl.TextStrokeColor3 = Color3.fromRGB(0,0,0); tl.TextStrokeTransparency = 0; tl.TextSize = 14; tl.Font = Enum.Font.SourceSansBold; tl.Parent = bb end
	end
end

local function setupESP(prefix, filter, color)
	local items = workspace:FindFirstChild("Items")
	if items then for _, item in ipairs(items:GetChildren()) do addESP(item, prefix, filter, color) end end
	if not espConnections[prefix] then local itemsFolder = workspace:WaitForChild("Items"); espConnections[prefix] = itemsFolder.ChildAdded:Connect(function(item) task.wait(0.2) if espState[prefix] then addESP(item, prefix, filter, color) end end) end
end

local function stopESP(prefix) clearESP(prefix) if espConnections[prefix] then espConnections[prefix]:Disconnect(); espConnections[prefix] = nil end end

local autoDaysEnabled = false; local autoDaysAngle = 0; local autoDaysRadius = 150; local autoDaysHeight = 100; local autoDaysSpeed = 1
RunService.RenderStepped:Connect(function(dt) if autoDaysEnabled then local hrp = getHRP() if hrp then autoDaysAngle = autoDaysAngle + autoDaysSpeed * dt; hrp.CFrame = CFrame.new(Vector3.new(math.cos(autoDaysAngle)*autoDaysRadius, autoDaysHeight, math.sin(autoDaysAngle)*autoDaysRadius), Vector3.new(0,autoDaysHeight,0)) end end end)

local autoKillBunny = false; local bunnyCFrame = nil; local bunnyTarget = nil; local bunnyUpdateTimer = 0
local function updateBunnyTarget() local chars = workspace:FindFirstChild("Characters") if chars then bunnyTarget = chars:FindFirstChild("Bunny") else bunnyTarget = nil end end
RunService.RenderStepped:Connect(function(dt) if autoKillBunny then local hrp = getHRP() if hrp then bunnyUpdateTimer = bunnyUpdateTimer + dt; if bunnyUpdateTimer >= 10 then updateBunnyTarget(); bunnyUpdateTimer = 0 end; if bunnyTarget and bunnyTarget.PrimaryPart then hrp.CFrame = hrp.CFrame:Lerp(bunnyTarget.PrimaryPart.CFrame * CFrame.new(0,0,-2), 0.3); VirtualUser:Button1Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame); VirtualUser:Button1Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame) end end end end)

local killAuraEnabled = false; local killAuraRange = 70
task.spawn(function() while true do task.wait(0.1) if killAuraEnabled then local hrp = getHRP(); local inv = LocalPlayer:FindFirstChild("Inventory") if hrp and inv then local tool = inv:FindFirstChild("Old Axe") or inv:FindFirstChild("Good Axe") or inv:FindFirstChild("Strong Axe") or inv:FindFirstChild("Chainsaw") if tool then local chars = workspace:FindFirstChild("Characters") if chars then for _, mob in pairs(chars:GetChildren()) do if mob:IsA("Model") and mob.PrimaryPart and mob ~= LocalPlayer.Character then local dist = (mob.PrimaryPart.Position - hrp.Position).Magnitude if dist <= killAuraRange then if REMOTES.ToolDamageObject then REMOTES.ToolDamageObject:InvokeServer(mob, tool, 999, hrp.CFrame) end end end end end end end end end end)

local autoChopEnabled = false; local autoChopRange = 100
task.spawn(function() while true do task.wait(0.1) if autoChopEnabled then local hrp = getHRP(); local inv = LocalPlayer:FindFirstChild("Inventory") if hrp and inv then local tool = inv:FindFirstChild("Old Axe") or inv:FindFirstChild("Good Axe") or inv:FindFirstChild("Strong Axe") or inv:FindFirstChild("Chainsaw") if tool then local function chopTrees(folder) if not folder then return end; for _, obj in pairs(folder:GetChildren()) do if obj:IsA("Model") and (obj.Name == "Small Tree" or obj.Name == "TreeBig1" or obj.Name == "TreeBig2") and obj.PrimaryPart then local dist = (obj.PrimaryPart.Position - hrp.Position).Magnitude if dist <= autoChopRange then if REMOTES.ToolDamageObject then REMOTES.ToolDamageObject:InvokeServer(obj, tool, 999, hrp.CFrame) end end end end end; local map = workspace:FindFirstChild("Map") if map then chopTrees(map:FindFirstChild("Foliage")); chopTrees(map:FindFirstChild("Landmarks")) end end end end end end)

local autoEatConn = nil; local fullBrightConn = nil

local antiWolfConn = nil; local antiWolfEnabled = false; local antiWolfAbove = true; local antiWolfFixed = Vector3.new(0,10,0); local antiWolfOriginals = {}; local antiWolfLoopConn = nil
local WOLF_KEYWORDS = { "wolf", "Bear" }
local function isWolf(model) if not model or not model:IsA("Model") then return false end; local name = tostring(model.Name):lower(); for _, kw in ipairs(WOLF_KEYWORDS) do if string.find(name, kw:lower(), 1, true) then return true end end; return false end
local function getAllParts(model) local parts = {}; for _, desc in ipairs(model:GetDescendants()) do if desc:IsA("BasePart") then table.insert(parts, desc) end end; return parts end
local function saveWolfState(model) if antiWolfOriginals[model] then return end; local state = { parts = {}, model = model, primaryCFrame = nil }; for _, part in ipairs(getAllParts(model)) do state.parts[part] = { Anchored = part.Anchored, CanCollide = part.CanCollide, CFrame = part.CFrame } end; if model.PrimaryPart then state.primaryCFrame = model:GetPrimaryPartCFrame() end; antiWolfOriginals[model] = state end
local function restoreWolf(model) local state = antiWolfOriginals[model]; if not state then return end; pcall(function() for part, orig in pairs(state.parts) do if part and part.Parent then if orig.CFrame then pcall(function() part.CFrame = orig.CFrame end) end; part.Anchored = orig.Anchored; part.CanCollide = orig.CanCollide end end; if state.primaryCFrame and model.PrimaryPart then pcall(function() model:SetPrimaryPartCFrame(state.primaryCFrame) end) end end); antiWolfOriginals[model] = nil end
local function teleportWolf(model, targetCF) pcall(function() if model.PrimaryPart then model:SetPrimaryPartCFrame(targetCF) else local parts = getAllParts(model); local center = Vector3.new(0,0,0); local count = 0; for _, p in ipairs(parts) do center = center + p.Position; count = count + 1 end; if count == 0 then return end; center = center / count; for _, p in ipairs(parts) do p.CFrame = CFrame.new(targetCF.Position + (p.Position - center)) * (p.CFrame - p.CFrame.Position) end end end) end
local function bringAllWolves() local hrp = getHRP(); local target = if antiWolfAbove and hrp then hrp.Position + Vector3.new(0,10,0) else antiWolfFixed; local folder = workspace:FindFirstChild("Characters") or workspace; for _, obj in ipairs(folder:GetChildren()) do if isWolf(obj) then saveWolfState(obj); for part in pairs(antiWolfOriginals[obj].parts) do if part and part.Parent then pcall(function() part.Anchored = true; part.CanCollide = false end) end end; antiWolfOriginals[obj].moved = true; teleportWolf(obj, CFrame.new(target)) end end end
local function startAntiWolfLoop() if antiWolfLoopConn then return end; antiWolfLoopConn = RunService.Heartbeat:Connect(function() if not antiWolfEnabled then return end; local hrp = getHRP(); local target = if antiWolfAbove and hrp then hrp.Position + Vector3.new(0,10,0) else antiWolfFixed; local folder = workspace:FindFirstChild("Characters") or workspace; for _, obj in ipairs(folder:GetChildren()) do if isWolf(obj) then if not antiWolfOriginals[obj] then saveWolfState(obj); for part in pairs(antiWolfOriginals[obj].parts) do pcall(function() part.Anchored = true; part.CanCollide = false end) end; antiWolfOriginals[obj].moved = true end; local offset = math.abs(tonumber(tostring(obj:GetDebugId())) or 0); local xOff = (offset % 6) - 3; pcall(function() teleportWolf(obj, CFrame.new(target + Vector3.new(xOff*2,0,0))) end) end end end) end
local function stopAntiWolfLoop() if antiWolfLoopConn then antiWolfLoopConn:Disconnect(); antiWolfLoopConn = nil end end
local function restoreAllWolves() for model in pairs(antiWolfOriginals) do pcall(function() restoreWolf(model) end) end; antiWolfOriginals = {} end
local function setupAntiWolfDescendant() local folder = workspace:FindFirstChild("Characters") or workspace; antiWolfConn = folder.DescendantAdded:Connect(function(desc) if not antiWolfEnabled then return end; if desc:IsA("Model") and isWolf(desc) then saveWolfState(desc); for part in pairs(antiWolfOriginals[desc].parts) do pcall(function() part.Anchored = true; part.CanCollide = false end) end else local parent = desc.Parent; while parent and parent ~= workspace and parent ~= folder do if isWolf(parent) then saveWolfState(parent); for part in pairs(antiWolfOriginals[parent].parts) do pcall(function() part.Anchored = true; part.CanCollide = false end) end; break end; parent = parent.Parent end end end) end

local MainTab = Window:AddTab({ Name = "Main", Icon = "home" })
local DiscordGrp = MainTab:AddLeftGroupbox("Discord", "link")
local DiscordLabel = DiscordGrp:AddLabel({ Text = "Join discord for free keys!", DoesWrap = true, Size = 26 })

task.spawn(function()
	task.wait(0.5)
	local discordTextLabel = nil
	pcall(function() for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do if desc:IsA("TextLabel") and desc.Text:find("discord") then discordTextLabel = desc; break end end end)
	if discordTextLabel then discordTextLabel.RichText = false; discordTextLabel.TextColor3 = Color3.fromRGB(157,130,250); discordTextLabel.Font = Enum.Font.GothamBold; discordTextLabel.TextSize = 26 end
	task.wait(0.3)
	local fullText = "Join discord for free keys!"; local cursor = "_"
	while true do
		for i = 1, #fullText do pcall(function() DiscordLabel:SetText(string.sub(fullText, 1, i) .. cursor) end); pcall(function() if discordTextLabel and discordTextLabel.Parent then discordTextLabel.TextColor3 = Color3.fromRGB(157,130,250); discordTextLabel.Font = Enum.Font.GothamBold; discordTextLabel.TextSize = 26 end end); task.wait(0.06) end
		pcall(function() DiscordLabel:SetText(fullText) end); task.wait(1.5)
		for i = #fullText, 0, -1 do pcall(function() DiscordLabel:SetText(string.sub(fullText, 1, i) .. cursor) end); task.wait(0.04) end
		pcall(function() DiscordLabel:SetText("") end); task.wait(0.5)
	end
end)

DiscordGrp:AddButton("Copy Discord Link", function() pcall(function() setclipboard("https://discord.gg/ivory") end); notify("Discord Link Copied!", "Success") end)

local AutoTab = Window:AddTab({ Name = "Automation", Icon = "zap" })
local AutoGrp = AutoTab:AddLeftGroupbox("Automation", "zap")
AutoGrp:AddToggle("auto_days", { Text = "Auto Days", Default = false, Callback = function(val) autoDaysEnabled = val; notify("Automation", val and "Auto Days Enabled" or "Auto Days Disabled") end })
AutoGrp:AddToggle("auto_kill_bunny", { Text = "Auto Kill Bunny", Default = false, Callback = function(val) autoKillBunny = val; local hrp = getHRP() if val then if hrp then bunnyCFrame = hrp.CFrame end; updateBunnyTarget() else if bunnyCFrame and hrp then hrp.CFrame = bunnyCFrame end end; notify("Automation", val and "Auto Kill Bunny Enabled" or "Auto Kill Bunny Disabled") end })
AutoGrp:AddButton("Open All Chests", function() local items = workspace:FindFirstChild("Items") if items then for _, item in ipairs(items:GetChildren()) do if item.Name == "Item Chest" or item.Name == "Item Chest2" or item.Name == "Item Chest3" or item.Name == "Item Chest4" or item.Name == "Item Chest5" or item.Name == "Item Chest6" or item.Name == "Alien Chest" then if REMOTES.RequestOpenItemChest then REMOTES.RequestOpenItemChest:FireServer(item) end end end; notify("Automation", "Opened all chests!") else notify("Automation", "Items folder not found") end end)

local function addTweenLostChild(name) AutoGrp:AddButton("Tween to " .. name, function() local hrp = getHRP() if not hrp then return end; local origCF = hrp.CFrame; local function findChild() local chars = workspace:WaitForChild("Characters") for _, child in pairs(chars:GetChildren()) do if child.Name == name then local part = child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart") if part then return part end end end; return nil end; local target = findChild() if not target then notify("Error", "Cannot find " .. name); return end; notify("Lost Children", "Tweening to " .. name .. "..."); local dist = (hrp.Position - target.Position).Magnitude; local tween = TweenService:Create(hrp, TweenInfo.new(dist / 500, Enum.EasingStyle.Linear), { CFrame = target.CFrame + Vector3.new(0,3,0) }); tween:Play(); tween.Completed:Wait(); task.wait(15); TweenService:Create(hrp, TweenInfo.new(1, Enum.EasingStyle.Linear), { CFrame = origCF }):Play() end) end
addTweenLostChild("Lost Child"); addTweenLostChild("Lost Child2"); addTweenLostChild("Lost Child3"); addTweenLostChild("Lost Child4")

AutoGrp:AddToggle("auto_eat", { Text = "Auto Eat Cooked Morsel", Default = false, Callback = function(val) if val then local function eatMorsel() local items = workspace:FindFirstChild("Items") if items then for _, item in ipairs(items:GetChildren()) do if item.Name == "Cooked Morsel" then if REMOTES.RequestConsumeItem then REMOTES.RequestConsumeItem:InvokeServer(item) end; break end end end end; pcall(function() local hungerBar = LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Interface"):WaitForChild("StatBars"):WaitForChild("HungerBar"):WaitForChild("Bar"); autoEatConn = hungerBar:GetPropertyChangedSignal("Size"):Connect(function() if hungerBar.Size.X.Scale < 0.9 then eatMorsel() end end); if hungerBar.Size.X.Scale < 0.9 then eatMorsel() end end); notify("Food", "Auto Eat Active") else if autoEatConn then autoEatConn:Disconnect(); autoEatConn = nil end; notify("Food", "Auto Eat Disabled") end end })
AutoGrp:AddButton("Cook Foods", function() local hrp = getHRP() if not hrp then return end; local campfire = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campground") and workspace.Map.Campground:FindFirstChild("MainFire") if not campfire or not campfire:IsA("Model") or not campfire.PrimaryPart then notify("Food", "Campfire not found"); return end; local items = workspace:FindFirstChild("Items") if items then for _, item in ipairs(items:GetChildren()) do if item:IsA("Model") and item.PrimaryPart and (string.find(item.Name, "Morsel") or string.find(item.Name, "Steak")) then if REMOTES.RequestStartDraggingItem and REMOTES.StopDraggingItem then REMOTES.RequestStartDraggingItem:FireServer(item); item:PivotTo(campfire.PrimaryPart.CFrame * CFrame.new(0,8,0)); REMOTES.StopDraggingItem:FireServer(item) else item:PivotTo(campfire.PrimaryPart.CFrame * CFrame.new(0,8,0)) end end end; notify("Food", "Cooked raw foods!") end end)

local CollTab = Window:AddTab({ Name = "Item Collection", Icon = "package" })
local CollGrp = CollTab:AddLeftGroupbox("Item Collection", "package")
CollGrp:AddButton("Stop All Brings", function() stopAllBrings() end)
makeBringToggle(CollGrp, "Fuel Items", "Fuel", FUEL_ITEMS, nil)
makeBringToggle(CollGrp, "Metal Items", "Metal", METAL_ITEMS, nil)
makeBringToggle(CollGrp, "Food Items", "Food", FOOD_ITEMS, nil)
makeBringToggle(CollGrp, "Ammo Items", "Ammo", AMMO_ITEMS, nil)
makeBringToggle(CollGrp, "Tools & Weapons", "Tools", TOOL_ITEMS, nil)
makeBringToggle(CollGrp, "Saplings", "Sapling", nil, "Sapling")
makeBringToggle(CollGrp, "Logs Only", "LogSingle", nil, "Log")
makeBringToggle(CollGrp, "Coal Only", "CoalSingle", nil, "Coal")
makeBringToggle(CollGrp, "Microwaves Only", "MicrowaveSingle", nil, "Broken Microwave")
makeBringToggle(CollGrp, "Steaks Only", "SteakSingle", nil, "Steak")

local CombatTab = Window:AddTab({ Name = "Combat & Farming", Icon = "swords" })
local CombatGrp = CombatTab:AddLeftGroupbox("Combat", "swords")
CombatGrp:AddToggle("kill_aura", { Text = "Kill Aura", Default = false, Callback = function(val) killAuraEnabled = val; notify("Combat", val and "Kill Aura Active" or "Kill Aura Disabled") end })
CombatGrp:AddSlider("kill_aura_range", { Text = "Kill Aura Distance", Default = 70, Min = 20, Max = 1200, Rounding = 0, Callback = function(val) killAuraRange = val end })
CombatGrp:AddToggle("auto_chop", { Text = "Auto Chop Tree", Default = false, Callback = function(val) autoChopEnabled = val; notify("Combat", val and "Tree Aura Active" or "Tree Aura Disabled") end })
CombatGrp:AddSlider("auto_chop_range", { Text = "Tree Aura Distance", Default = 100, Min = 20, Max = 100, Rounding = 0, Callback = function(val) autoChopRange = val end })

local EspTab = Window:AddTab({ Name = "Visuals & ESP", Icon = "eye" })
local EspGrp = EspTab:AddLeftGroupbox("Item ESP", "eye")
EspGrp:AddToggle("esp_fuel", { Text = "Fuel ESP", Default = false, Callback = function(val) espState.Fuel = val; if val then setupESP("Fuel", FUEL_ITEMS, Color3.fromRGB(255,215,0)) else stopESP("Fuel") end end })
EspGrp:AddToggle("esp_metal", { Text = "Metal ESP", Default = false, Callback = function(val) espState.Metal = val; if val then setupESP("Metal", METAL_ITEMS, Color3.fromRGB(255,0,0)) else stopESP("Metal") end end })
EspGrp:AddToggle("esp_food", { Text = "Food ESP", Default = false, Callback = function(val) espState.Food = val; if val then setupESP("Food", FOOD_ITEMS, Color3.fromRGB(0,255,0)) else stopESP("Food") end end })

local PlayerTab = Window:AddTab({ Name = "Player & Utilities", Icon = "user" })
local SpeedGrp = PlayerTab:AddLeftGroupbox("Movement", "bar-chart-2")
local MiscGrp = PlayerTab:AddRightGroupbox("Utilities", "sliders")
local customSpeed = 70; local defaultSpeed = 16; local speedEnabled = false
SpeedGrp:AddSlider("walk_speed", { Text = "WalkSpeed", Default = 70, Min = 20, Max = 1200, Rounding = 0, Callback = function(val) customSpeed = val; if speedEnabled then local hum = getHumanoid() if hum then hum.WalkSpeed = customSpeed end end end })
SpeedGrp:AddToggle("toggle_speed", { Text = "Toggle Speed", Default = false, Callback = function(val) speedEnabled = val; local hum = getHumanoid() if hum then hum.WalkSpeed = val and customSpeed or defaultSpeed end end })
MiscGrp:AddToggle("god_mode", { Text = "God Mode", Default = false, Callback = function(val) if val then pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/ProBaconHub/DATABASE/refs/heads/main/99%20Nights%20in%20the%20Forest/Infinite%20Health.lua"))() end); notify("Player", "Infinite Health script loaded!") end end })
MiscGrp:AddToggle("full_bright", { Text = "Full Bright", Default = false, Callback = function(val) if val then fullBrightConn = RunService.RenderStepped:Connect(function() Lighting.Ambient = Color3.fromRGB(255,255,255); Lighting.ColorShift_Bottom = Color3.fromRGB(255,255,255); Lighting.ColorShift_Top = Color3.fromRGB(255,255,255); Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1 end); notify("Visuals", "Fullbright Enabled") else if fullBrightConn then fullBrightConn:Disconnect(); fullBrightConn = nil end; Lighting.Ambient = Color3.fromRGB(127,127,127); Lighting.ColorShift_Bottom = Color3.fromRGB(0,0,0); Lighting.ColorShift_Top = Color3.fromRGB(127,127,127); Lighting.Brightness = 1; Lighting.ClockTime = 12; Lighting.FogEnd = 1000; notify("Visuals", "Fullbright Disabled") end end })
MiscGrp:AddButton("Teleport to Campfire", function() local hrp = getHRP(); local campfire = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("Campground") and workspace.Map.Campground:FindFirstChild("MainFire") if hrp and campfire and campfire:IsA("Model") and campfire.PrimaryPart then hrp.CFrame = campfire.PrimaryPart.CFrame + Vector3.new(0,5,0); notify("Utilities", "Teleported to campfire!") else notify("Utilities", "Campfire not found") end end)

MiscGrp:AddButton("Anti-Wolf GUI", function()
	local gui = Instance.new("ScreenGui"); gui.Name = "AntiWolfBringGUI"; gui.ResetOnSpawn = false; gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0,300,0,140); frame.Position = UDim2.new(0,12,0,12); frame.BackgroundColor3 = Color3.fromRGB(30,30,30); frame.BackgroundTransparency = 0.12; frame.BorderSizePixel = 0; frame.Draggable = true
	local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(1,-12,0,28); title.Position = UDim2.new(0,6,0,6); title.BackgroundTransparency = 1; title.Text = "Anti-Wolf: Bring & Hold"; title.TextColor3 = Color3.new(1,1,1); title.Font = Enum.Font.SourceSansBold; title.TextSize = 18; title.TextXAlignment = Enum.TextXAlignment.Left
	local enableBtn = Instance.new("TextButton", frame); enableBtn.Size = UDim2.new(0,140,0,34); enableBtn.Position = UDim2.new(0,6,0,40); enableBtn.Text = "Enable"; enableBtn.Font = Enum.Font.SourceSans; enableBtn.TextSize = 16; enableBtn.BackgroundColor3 = Color3.fromRGB(70,70,70); enableBtn.TextColor3 = Color3.new(1,1,1)
	local modeBtn = Instance.new("TextButton", frame); modeBtn.Size = UDim2.new(0,140,0,34); modeBtn.Position = UDim2.new(0,156,0,40); modeBtn.Text = "Mode: Above Player"; modeBtn.Font = Enum.Font.SourceSans; modeBtn.TextSize = 14; modeBtn.BackgroundColor3 = Color3.fromRGB(70,70,70); modeBtn.TextColor3 = Color3.new(1,1,1)
	local scanBtn = Instance.new("TextButton", frame); scanBtn.Size = UDim2.new(0,140,0,28); scanBtn.Position = UDim2.new(0,6,0,84); scanBtn.Text = "Scan Now"; scanBtn.Font = Enum.Font.SourceSans; scanBtn.TextSize = 14; scanBtn.BackgroundColor3 = Color3.fromRGB(80,80,80); scanBtn.TextColor3 = Color3.new(1,1,1)
	local closeBtn = Instance.new("TextButton", frame); closeBtn.Size = UDim2.new(0,140,0,28); closeBtn.Position = UDim2.new(0,156,0,84); closeBtn.Text = "Close"; closeBtn.Font = Enum.Font.SourceSans; closeBtn.TextSize = 14; closeBtn.BackgroundColor3 = Color3.fromRGB(80,80,80); closeBtn.TextColor3 = Color3.new(1,1,1)
	local infoLabel = Instance.new("TextLabel", frame); infoLabel.Size = UDim2.new(1,-12,0,18); infoLabel.Position = UDim2.new(0,6,1,-24); infoLabel.BackgroundTransparency = 1; infoLabel.Font = Enum.Font.SourceSans; infoLabel.TextSize = 12; infoLabel.TextColor3 = Color3.fromRGB(200,200,200); infoLabel.Text = "Client-side only. Server may correct positions."
	enableBtn.MouseButton1Click:Connect(function() antiWolfEnabled = not antiWolfEnabled if antiWolfEnabled then enableBtn.Text = "Disable"; bringAllWolves(); startAntiWolfLoop(); setupAntiWolfDescendant(); StarterGui:SetCore("SendNotification", { Title = "Anti-Wolf", Text = "Bring & Hold ENABLED", Duration = 2 }) else enableBtn.Text = "Enable"; stopAntiWolfLoop(); restoreAllWolves() if antiWolfConn then antiWolfConn:Disconnect(); antiWolfConn = nil end; StarterGui:SetCore("SendNotification", { Title = "Anti-Wolf", Text = "Bring & Hold DISABLED", Duration = 2 }) end end)
	modeBtn.MouseButton1Click:Connect(function() antiWolfAbove = not antiWolfAbove; modeBtn.Text = antiWolfAbove and "Mode: Above Player" or ("Mode: " .. tostring(antiWolfFixed)) end)
	scanBtn.MouseButton1Click:Connect(function() bringAllWolves(); StarterGui:SetCore("SendNotification", { Title = "Anti-Wolf", Text = "Manual scan executed", Duration = 1.6 }) end)
	closeBtn.MouseButton1Click:Connect(function() frame.Visible = false end)
	setupAntiWolfDescendant()
end)

local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings" })

local CreditsGrp = SettingsTab:AddLeftGroupbox("Credits", "heart")
local CreditsLabel = CreditsGrp:AddLabel({ Text = " ", DoesWrap = true, Size = 26 })

task.spawn(function()
	task.wait(0.5)
	local creditsTextLabel = nil
	pcall(function()
		for _, desc in ipairs(Library.ScreenGui:GetDescendants()) do
			if desc:IsA("TextLabel") and desc.Text == " " then
				creditsTextLabel = desc
				break
			end
		end
	end)
	if creditsTextLabel then
		creditsTextLabel.RichText = false
		creditsTextLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
		creditsTextLabel.Font = Enum.Font.GothamBold
		creditsTextLabel.TextSize = 26
		creditsTextLabel.TextWrapped = true
	end
	task.wait(0.3)
	local fullText = "Made by Mommy Veqxoo < / 3"; local cursor = "_"
	while true do
		for i = 1, #fullText do
			pcall(function() CreditsLabel:SetText(string.sub(fullText, 1, i) .. cursor) end)
			pcall(function()
				if creditsTextLabel and creditsTextLabel.Parent then
					creditsTextLabel.RichText = false
					creditsTextLabel.TextColor3 = Color3.fromRGB(255, 105, 180)
					creditsTextLabel.Font = Enum.Font.GothamBold
					creditsTextLabel.TextSize = 26
				end
			end)
			task.wait(0.06)
		end
		pcall(function() CreditsLabel:SetText(fullText) end)
		task.wait(1.5)
		for i = #fullText, 0, -1 do
			pcall(function() CreditsLabel:SetText(string.sub(fullText, 1, i) .. cursor) end)
			task.wait(0.04)
		end
		pcall(function() CreditsLabel:SetText("") end)
		task.wait(0.5)
	end
end)

ThemeManager:ApplyToTab(SettingsTab)
SaveManager:BuildConfigSection(SettingsTab)

local menuOpen = true
UserInputService.InputBegan:Connect(function(input, gpe) if gpe then return end; if input.KeyCode == Enum.KeyCode.RightShift then menuOpen = not menuOpen; if Library.ScreenGui then Library.ScreenGui.Enabled = menuOpen end end end)
RunService.Heartbeat:Connect(function() if not menuOpen then UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter; UserInputService.MouseIconEnabled = false; if Library.ScreenGui and Library.ScreenGui.Enabled then Library.ScreenGui.Enabled = false end end end)

LocalPlayer.CharacterAdded:Connect(function() task.wait(1) if antiWolfConn then antiWolfConn:Disconnect(); antiWolfConn = nil end; if antiWolfLoopConn then antiWolfLoopConn:Disconnect(); antiWolfLoopConn = nil end; antiWolfOriginals = {}; local gui = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild("AntiWolfBringGUI") if gui then gui:Destroy() end end)

notify("Ivory Hub", "99 Nights loaded!")
