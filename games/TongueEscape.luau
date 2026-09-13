--// Ivory Hub - +1 Tongue Escape
--// PlaceId: 122245938604556

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer

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
	writefile(LIB_FILE, httpGet(LIB_URL))
end
local Library = loadstring(readfile(LIB_FILE))()

local Events = ReplicatedStorage:WaitForChild("Events", 15)
local Modules = ReplicatedStorage:WaitForChild("Modules", 15)
local SharedModule = ReplicatedStorage:WaitForChild("TongueShared", 15)
assert(Events and Modules and SharedModule, "[Ivory] Game data unavailable. Rejoin and try again.")

local Shared = require(SharedModule)
local PlaytimeConfig = require(Modules:WaitForChild("PlaytimeRewardsConfig", 10))
local TrailConfig = require(Modules:WaitForChild("TrailConfigurations", 10))

local function Stat(Name)
	local Stats = LP:FindFirstChild("leaderstats")
	local Value = Stats and Stats:FindFirstChild(Name)
	return Value and tonumber(Value.Value) or 0
end

local function CharacterParts()
	local Character = LP.Character
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if Root and Humanoid and Humanoid.Health > 0 then
		return Character, Root, Humanoid
	end
end

local function Number(Value)
	local Text = string.format("%.0f", Value)
	return Text:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function Fire(Name, ...)
	local Remote = Events:FindFirstChild(Name)
	assert(Remote and Remote:IsA("RemoteEvent"), "Missing game event: " .. Name)
	Remote:FireServer(...)
end

local function ReadProperty(Object, Property)
	local Success, Value = pcall(function()
		return Object[Property]
	end)
	if not Success and type(gethiddenproperty) == "function" then
		Success, Value = pcall(gethiddenproperty, Object, Property)
	end
	return Success, Value
end

local function WriteProperty(Object, Property, Value)
	local Success = pcall(function()
		Object[Property] = Value
	end)
	if not Success and type(sethiddenproperty) == "function" then
		pcall(sethiddenproperty, Object, Property, Value)
	end
	return Success
end

local cfg = {
	autoTongue = false,
	autoRebirth = false,
	autoWins = false,
	autoRewards = false,
	autoTrails = false,
	antiAfk = false,
	bypassPause = false,
	noclip = false,
	infJump = false,
	tongueInterval = 0.02,
	winInterval = 1.5,
	winGeneration = 0,
	winMisses = 0,
	retryAt = {},
	idleConnections = {},
	gameAfkScript = nil,
	gameAfkWasEnabled = nil,
	idleHandler = nil,
	pauseConnection = nil,
	originalPauseMode = nil,
	originalPauseNotice = nil,
	pauseModeChanged = false,
}

local espObjects = {}

local Window = Library.CreateWindow({
	Name = "Ivory",
	Width = 720,
	Height = 600,
})

local Tabs = {
	Main = Window:CreateTab({ Name = "Main" }),
	Player = Window:CreateTab({ Name = "Player" }),
	["UI Settings"] = Window:CreateTab({ Name = "UI Settings" }),
}

local AutoSec = Tabs.Main:CreateSection("Automation")

AutoSec:CreateToggle({
	Name = "Auto Farm Tongue",
	CurrentValue = false,
	Callback = function(v) cfg.autoTongue = v end,
})

AutoSec:CreateSlider({
	Name = "Tongue Interval",
	Min = 0.02,
	Max = 1,
	CurrentValue = 0.02,
	Callback = function(v) cfg.tongueInterval = v end,
})

AutoSec:CreateToggle({
	Name = "Auto Rebirth",
	CurrentValue = false,
	Callback = function(v) cfg.autoRebirth = v end,
})

AutoSec:CreateToggle({
	Name = "Auto Farm Wins",
	CurrentValue = false,
	Callback = function(v)
		cfg.autoWins = v
		cfg.winGeneration = cfg.winGeneration + 1
		cfg.winMisses = 0
	end,
})

AutoSec:CreateToggle({
	Name = "Auto Claim Rewards",
	CurrentValue = false,
	Callback = function(v) cfg.autoRewards = v end,
})

AutoSec:CreateToggle({
	Name = "Auto Buy & Equip Trails",
	CurrentValue = false,
	Callback = function(v) cfg.autoTrails = v end,
})

local StatusSec = Tabs.Main:CreateSection("Status")

local TongueLabel = StatusSec:CreateLabel({ Text = "Tongue: 0" })
local LevelLabel = StatusSec:CreateLabel({ Text = "Level: 0" })
local WinsLabel = StatusSec:CreateLabel({ Text = "Wins: 0" })
local RebirthsLabel = StatusSec:CreateLabel({ Text = "Rebirths: 0" })
local StatusLabel = StatusSec:CreateLabel({ Text = "Status: Idle" })

local ProtSec = Tabs.Player:CreateSection("Protection")

ProtSec:CreateToggle({
	Name = "Anti-AFK",
	CurrentValue = false,
	Callback = function(v) cfg.antiAfk = v end,
})

ProtSec:CreateToggle({
	Name = "Bypass Gameplay Paused",
	CurrentValue = false,
	Callback = function(v) cfg.bypassPause = v end,
})

local MoveSec = Tabs.Player:CreateSection("Movement")

MoveSec:CreateToggle({
	Name = "Noclip",
	CurrentValue = false,
	Callback = function(v) cfg.noclip = v end,
})

MoveSec:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Callback = function(v) cfg.infJump = v end,
})

local DiscordSec = Tabs["UI Settings"]:CreateSection("Discord")
DiscordSec:CreateButton({
	Name = "Join Discord For Dupe",
	Callback = function()
		pcall(function() setclipboard("https://discord.gg/bac") end)
		Library.Notify({ Title = "Ivory", Content = "Discord link copied!", Type = "Success", Duration = 3 })
	end,
})

local CreditSec = Tabs["UI Settings"]:CreateSection("Credits")
CreditSec:CreateLabel("Made by Ivory Team")

local MenuSec = Tabs["UI Settings"]:CreateSection("Menu Settings")

MenuSec:CreateKeybind({
	Name = "Menu Keybind",
	CurrentKeybind = "RightShift",
})

MenuSec:CreateToggle({
	Name = "Keybind List Toggle",
	CurrentValue = false,
	Callback = function(v) Library.KeybindFrame.Visible = v end,
})

MenuSec:CreateSlider({
	Name = "FPS Cap",
	Min = 30,
	Max = 240,
	CurrentValue = 60,
	Callback = function(v)
		pcall(function() setfpscap(v) end)
	end,
})

MenuSec:CreateDropdown({
	Name = "Notification Side",
	Values = { "Left", "Right" },
	CurrentOption = "Right",
	Callback = function(v) Library:SetNotifySide(v) end,
})

MenuSec:CreateToggle({
	Name = "Custom Cursor",
	CurrentValue = false,
	Callback = function(v) Library.ShowCustomCursor = v end,
})

MenuSec:CreateButton({
	Name = "Test Notification",
	Callback = function()
		Library.Notify({ Title = "Ivory", Content = "It works!", Duration = 3 })
	end,
})

MenuSec:CreateDropdown({
	Name = "DPI Scale",
	Values = { "50%", "75%", "100%", "125%", "150%", "200%" },
	CurrentOption = "100%",
	Callback = function(v)
		local scale = tonumber(v:gsub("%%", "")) / 100
		pcall(function() Library:SetScale(scale) end)
	end,
})

MenuSec:CreateSlider({
	Name = "Corner Radius",
	Min = 0,
	Max = 20,
	CurrentValue = 8,
	Callback = function(v)
		pcall(function() Library:SetCornerRadius(v) end)
	end,
})

MenuSec:CreateButton({
	Name = "Unload",
	Callback = function()
		clearESP()
		setNoclip(false)
		setInfiniteJump(false)
		restorePause()
		restoreAFK()
		Library:Unload()
	end,
})

local ServerSec = Tabs["UI Settings"]:CreateSection("Server")

ServerSec:CreateButton({
	Name = "Rejoin Server",
	Callback = function()
		pcall(function()
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LP)
		end)
	end,
})

ServerSec:CreateButton({
	Name = "Server Hop",
	Callback = function()
		pcall(function()
			local servers = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
			local id = servers:match('"id":"(.-)"')
			if id and id ~= game.JobId then
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, id, LP)
			end
		end)
	end,
})

local ConfigSec = Tabs["UI Settings"]:CreateSection("Configuration")

ConfigSec:CreateButton({
	Name = "Save Config",
	Callback = function()
		pcall(function()
			local data = HttpService:JSONEncode({
				autoTongue = cfg.autoTongue,
				autoRebirth = cfg.autoRebirth,
				autoWins = cfg.autoWins,
				autoRewards = cfg.autoRewards,
				autoTrails = cfg.autoTrails,
				tongueInterval = cfg.tongueInterval,
			})
			writefile("IvoryHub/TongueEscape_Config.json", data)
			Library.Notify({ Title = "Ivory", Content = "Config saved!", Type = "Success", Duration = 3 })
		end)
	end,
})

ConfigSec:CreateButton({
	Name = "Load Config",
	Callback = function()
		pcall(function()
			if isfile("IvoryHub/TongueEscape_Config.json") then
				local data = HttpService:JSONDecode(readfile("IvoryHub/TongueEscape_Config.json"))
				for k, v in pairs(data) do
					if cfg[k] ~= nil then
						cfg[k] = v
					end
				end
				Library.Notify({ Title = "Ivory", Content = "Config loaded!", Type = "Success", Duration = 3 })
			end
		end)
	end,
})

local function restoreAFK()
	if cfg.idleHandler then
		cfg.idleHandler:Disconnect()
		cfg.idleHandler = nil
	end
	for _, Connection in cfg.idleConnections do
		pcall(function() Connection:Enable() end)
	end
	table.clear(cfg.idleConnections)
	if cfg.gameAfkScript and cfg.gameAfkScript.Parent and cfg.gameAfkWasEnabled then
		pcall(function() cfg.gameAfkScript.Enabled = true end)
	end
	cfg.gameAfkScript = nil
	cfg.gameAfkWasEnabled = nil
end

local function setAFK(Enabled)
	restoreAFK()
	if not Enabled then return end

	local Scripts = LP:FindFirstChild("PlayerScripts")
	local AFKScript = Scripts and Scripts:FindFirstChild("AntiAfkSystem")
	if AFKScript and AFKScript:IsA("LocalScript") then
		local Success, WasEnabled = pcall(function()
			local Old = AFKScript.Enabled
			AFKScript.Enabled = false
			return Old
		end)
		if Success then
			cfg.gameAfkScript = AFKScript
			cfg.gameAfkWasEnabled = WasEnabled
		end
	end

	if type(getconnections) == "function" then
		pcall(function()
			for _, Connection in getconnections(LP.Idled) do
				if Connection.Enabled then
					local Success = pcall(function()
						Connection:Disable()
					end)
					if Success then
						table.insert(cfg.idleConnections, Connection)
					end
				end
			end
		end)
	end

	cfg.idleHandler = LP.Idled:Connect(function()
		if not cfg.antiAfk then return end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.zero)
		end)
	end)
end

local function restorePause()
	if cfg.pauseConnection then
		cfg.pauseConnection:Disconnect()
		cfg.pauseConnection = nil
	end
	if cfg.pauseModeChanged and cfg.originalPauseMode ~= nil then
		WriteProperty(workspace, "StreamingIntegrityMode", cfg.originalPauseMode)
	end
	if cfg.originalPauseNotice ~= nil then
		pcall(function()
			GuiService:SetGameplayPausedNotificationEnabled(cfg.originalPauseNotice)
		end)
	end
	cfg.pauseModeChanged = nil
	cfg.originalPauseMode = nil
	cfg.originalPauseNotice = nil
end

local function setPauseBypass(Enabled)
	restorePause()
	if not Enabled then return end

	local ReadMode, Mode = ReadProperty(workspace, "StreamingIntegrityMode")
	if ReadMode then
		cfg.originalPauseMode = Mode
		cfg.pauseModeChanged = WriteProperty(workspace, "StreamingIntegrityMode", Enum.StreamingIntegrityMode.Disabled)
	end

	local ReadNotice, Notice = pcall(function()
		return GuiService:GetGameplayPausedNotificationEnabled()
	end)
	if ReadNotice then
		cfg.originalPauseNotice = Notice
		pcall(function()
			GuiService:SetGameplayPausedNotificationEnabled(false)
		end)
	end

	cfg.pauseConnection = LP:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
		if cfg.bypassPause and LP.GameplayPaused then
			WriteProperty(LP, "GameplayPaused", false)
		end
	end)

	if LP.GameplayPaused then
		WriteProperty(LP, "GameplayPaused", false)
	end
end

local noclipConn = nil
local function setNoclip(on)
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if on then
		noclipConn = RunService.Stepped:Connect(function()
			local c = LP.Character
			if c then
				for _, p in ipairs(c:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
		end)
	end
end

local infJumpConn = nil
local function setInfiniteJump(on)
	if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
	if on then
		infJumpConn = UserInputService.JumpRequest:Connect(function()
			local c = LP.Character
			if c then
				local h = c:FindFirstChildWhichIsA("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end
		end)
	end
end

local function clearESP()
	for _, obj in ipairs(espObjects) do
		if obj and obj.Parent then pcall(function() obj:Destroy() end) end
	end
	espObjects = {}
end

local function createESP(part, text, color)
	if not part or not part.Parent then return end
	local bb = Instance.new("BillboardGui")
	bb.Name = "IvoryESP"
	bb.Size = UDim2.new(0, 150, 0, 40)
	bb.StudsOffset = Vector3.new(0, 3, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = part
	bb.Parent = part
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color
	tl.TextSize = 14
	tl.Font = Enum.Font.GothamBold
	tl.TextStrokeTransparency = 0.3
	tl.TextStrokeColor3 = Color3.new(0, 0, 0)
	tl.Parent = bb
	table.insert(espObjects, bb)
end

task.spawn(function()
	while true do
		if cfg.autoTongue then
			local Character, Root, Humanoid = CharacterParts()
			if Root then
				pcall(function() Fire("AddTongue") end)
				StatusLabel:Set("Status: Training Tongue")
			end
		end
		task.wait(cfg.tongueInterval)
	end
end)

task.spawn(function()
	while true do
		if cfg.autoRebirth then
			pcall(function()
				local Required = Shared.levelForRebirth(Stat("Rebirths"))
				if Stat("Level") >= Required then
					local Remote = Events:FindFirstChild("RequestRebirth")
					assert(Remote and Remote:IsA("RemoteFunction"), "Rebirth unavailable")
					Remote:InvokeServer()
					StatusLabel:Set("Status: Rebirth complete!")
				end
			end)
		end
		task.wait(1)
	end
end)

local function BestWinButton()
	local Map = workspace:FindFirstChild("Map")
	local GiveWins = Map and Map:FindFirstChild("GiveWins")
	local Row = GiveWins and GiveWins:FindFirstChild("OneWin")
	if not Row then return end
	local Best, BestAmount = nil, -1
	for _, Model in Row:GetChildren() do
		local Amount = tonumber(Model:GetAttribute("WinAmount")) or 0
		if Model:IsA("Model") and Amount > BestAmount then
			Best, BestAmount = Model, Amount
		end
	end
	return Best, BestAmount
end

task.spawn(function()
	while true do
		if cfg.autoWins then
			local Character, Root, Humanoid = CharacterParts()
			if Root then
				local Generation = cfg.winGeneration
				local Model = BestWinButton()
				if Model then
					local Pivot = Model:GetPivot()
					local Touch = Model:FindFirstChild("Touch")
					if not Touch then
						pcall(function()
							LP:RequestStreamAroundAsync(Pivot.Position, 3)
						end)
						Touch = Model:FindFirstChild("Touch")
					end
					if not cfg.autoWins or Generation ~= cfg.winGeneration then continue end
					local Before = Stat("Wins")
					local UsedTouch = false
					if Touch and Touch:IsA("BasePart") and type(firetouchinterest) == "function" and cfg.winMisses < 2 then
						UsedTouch = pcall(function()
							firetouchinterest(Root, Touch, 0)
							task.wait(0.1)
							if Root.Parent and Touch.Parent then
								firetouchinterest(Root, Touch, 1)
							end
						end)
					end
					if not UsedTouch then
						local Target = Touch and Touch.CFrame or Pivot
						Humanoid.Sit = false
						if (Root.Position - Target.Position).Magnitude < 12 then
							Character:PivotTo(Target + Vector3.new(0, 7, 14))
							task.wait(0.15)
						end
						Root.AssemblyLinearVelocity = Vector3.zero
						Root.AssemblyAngularVelocity = Vector3.zero
						Character:PivotTo(Target + Vector3.new(0, 3, 0))
					end
					local Deadline = os.clock() + 1.2
					repeat
						task.wait(0.1)
					until not cfg.autoWins or Generation ~= cfg.winGeneration or Stat("Wins") > Before or os.clock() >= Deadline
					if cfg.autoWins and Generation == cfg.winGeneration then
						local Collected = Stat("Wins") > Before
						cfg.winMisses = Collected and 0 or cfg.winMisses + 1
					end
				end
			end
		end
		task.wait(cfg.winInterval)
	end
end)

local function ClaimOnce(Key, Remote, Cooldown, ...)
	if not cfg.autoRewards then return end
	local Now = os.clock()
	if Now < (cfg.retryAt[Key] or 0) then return end
	pcall(function()
		Fire(Remote, ...)
	end)
	cfg.retryAt[Key] = Now + Cooldown
	task.wait(0.2)
end

task.spawn(function()
	while true do
		if cfg.autoRewards then
			pcall(function()
				local Now = workspace:GetServerTimeNow()
				local Start = LP:GetAttribute("PlaytimeStart")
				local Elapsed = typeof(Start) == "number" and math.max(0, (tonumber(LP:GetAttribute("PlaytimeBase")) or 0) + Now - Start) or 0
				local Claimed = {}
				for Index in tostring(LP:GetAttribute("PlaytimeClaimed") or ""):gmatch("%d+") do
					Claimed[tonumber(Index)] = true
				end
				for Index, Reward in PlaytimeConfig.Rewards do
					if not Claimed[Index] and Elapsed >= Reward.Minute * 60 then
						ClaimOnce("Playtime" .. Index, "PlaytimeClaim", 10, Index)
					end
				end
				local LastDaily = tonumber(LP:GetAttribute("DailyLastClaim"))
				if LastDaily and (LastDaily <= 0 or Now - LastDaily >= 86400) then
					ClaimOnce("Daily", "DailyClaim", 15)
				end
				if LP:GetAttribute("LeaveBonusClaimed") == false then
					ClaimOnce("LeaveBonus", "LeaveBonusClaim", 30)
				end
				if LP:GetAttribute("GroupRewardClaimed") == false then
					local CheckAt = cfg.retryAt.GroupCheck or 0
					if os.clock() >= CheckAt then
						cfg.retryAt.GroupCheck = os.clock() + 120
						local Success, Member = pcall(function()
							return LP:IsInGroupAsync(602332660)
						end)
						if Success and Member then
							ClaimOnce("Group", "GroupRewardClaim", 120)
						end
					end
				end
			end)
		end
		task.wait(5)
	end
end)

task.spawn(function()
	while true do
		if cfg.autoTrails then
			pcall(function()
				local Owned = LP:FindFirstChild("Trails")
				if not Owned then return end
				local BestOwned, Purchase
				local Wins = Stat("Wins")
				for _, Trail in TrailConfig.Trails do
					if Owned:FindFirstChild(Trail.ID) then
						if not BestOwned or Trail.TongueBoost > BestOwned.TongueBoost then
							BestOwned = Trail
						end
					elseif type(Trail.WinCost) == "number" and Trail.WinCost >= 0 then
						if Trail.WinCost <= Wins and (not Purchase or Trail.TongueBoost > Purchase.TongueBoost) then
							Purchase = Trail
						end
					end
				end
				local Now = os.clock()
				local Equipped = Owned:FindFirstChild("Equipped")
				if BestOwned and Equipped and Equipped.Value ~= BestOwned.ID and Now >= (cfg.retryAt.EquipTrail or 0) then
					Fire("TrailAction", "Equip", BestOwned.ID)
					cfg.retryAt.EquipTrail = Now + 3
				end
				if Purchase then
					Fire("TrailAction", "BuyWins", Purchase.ID)
				end
			end)
		end
		task.wait(1)
	end
end)

RunService.Stepped:Connect(function()
	if cfg.noclip then
		local c = LP.Character
		if c then
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if cfg.infJump then
		local c = LP.Character
		if c then
			local h = c:FindFirstChildWhichIsA("Humanoid")
			if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
		end
	end
end)

task.spawn(function()
	while true do
		if cfg.antiAfk then
			if not cfg.idleHandler then
				setAFK(true)
			end
		else
			if cfg.idleHandler then
				restoreAFK()
			end
		end
		task.wait(1)
	end
end)

task.spawn(function()
	while true do
		if cfg.bypassPause then
			if not cfg.pauseConnection then
				setPauseBypass(true)
			end
		else
			if cfg.pauseConnection then
				restorePause()
			end
		end
		task.wait(1)
	end
end)

task.spawn(function()
	while true do
		pcall(function()
			TongueLabel:Set("Tongue: " .. Number(Stat("Tongue")))
			LevelLabel:Set("Level: " .. Number(Stat("Level")))
			WinsLabel:Set("Wins: " .. Number(Stat("Wins")))
			RebirthsLabel:Set("Rebirths: " .. Number(Stat("Rebirths")))
		end)
		task.wait(1)
	end
end)

task.spawn(function()
	while true do
		local footer = "v1.4 | Game | " .. LP.UserId
		pcall(function() Window:SetFooter(footer) end)
		task.wait(1)
	end
end)

LP.CharacterAdded:Connect(function(char)
	task.wait(2)
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		if cfg.noclip then setNoclip(true) end
		if cfg.infJump then setInfiniteJump(true) end
	end
end)

if not Library.Toggled then Library:Toggle() end
task.spawn(function()
	task.wait(1)
	Library.Notify({
		Title = "Ivory",
		Content = "+1 Tongue Escape loaded!",
		Type = "Success",
		Duration = 5,
	})
end)
print("[Ivory] +1 Tongue Escape loaded - RightShift to toggle")
