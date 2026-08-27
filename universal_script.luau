--// Ivory Hub | Splash Screen
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local LocalPlayer = Players.LocalPlayer

--// Cleanup old copies
for _, obj in ipairs(CoreGui:GetChildren()) do
	if obj.Name == "IvorySplash" then obj:Destroy() end
end

--// Game detection
local PlaceId = game.PlaceId
local GameName = tostring(PlaceId)
pcall(function()
	GameName = MarketplaceService:GetProductInfo(PlaceId).Name
end)

local GameScripts = {
	[116497287371701] = { name = "Karinderya", file = "games/Karinderya.luau" },
	[99521272836282] = { name = "Final Swarm", file = "games/FinalSwarm.luau" },
	[79787558257549] = { name = "Final Swarm", file = "games/FinalSwarm.luau" },
	[95919006508862] = { name = "Melt The Ice", file = "games/MeltTheIce.luau" },
	[1962086868] = { name = "Tower of Hell", file = "games/Towerofhell.luau" },
	[138501044883253] = { name = "Build A Burger", file = "games/BuildABurger.luau" },
	[105963809208632] = { name = "Build A Burger", file = "games/BuildABurger.luau" },
	[100293509865504] = { name = "Catch A Billion Ducks", file = "games/CatchABillionDucks.luau" },
	[120617974337690] = { name = "Catch A Billion Ducks", file = "games/CatchABillionDucks.luau" },
	[137363360166684] = { name = "Rocks RNG", file = "games/RocksRNG.luau" },
	[9772878203] = { name = "Floppa 2", file = "games/Floppa2.luau" },
	[13772394625] = { name = "Blade Ball", file = "games/Bladeball.luau" },
	[142823291] = { name = "Murder Mystery 2", file = "games/MM2.luau" },
}

local DetectedGame = GameScripts[PlaceId]

--// Colors
local IVORY_DARK = Color3.fromRGB(18, 14, 28)
local IVORY_MID = Color3.fromRGB(25, 20, 35)
local IVORY_ACCENT = Color3.fromRGB(140, 110, 220)
local IVORY_LIGHT = Color3.fromRGB(225, 215, 245)
local IVORY_SUB = Color3.fromRGB(155, 135, 185)
local IVORY_DIM = Color3.fromRGB(100, 80, 140)

--// Blur
local BackgroundBlur = Instance.new("BlurEffect")
BackgroundBlur.Size = 0
BackgroundBlur.Parent = Lighting

--// ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IvorySplash"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

--// Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 340)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -170)
MainFrame.BackgroundColor3 = IVORY_DARK
MainFrame.BackgroundTransparency = 1
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = MainFrame

--// Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 1
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.Size = UDim2.new(1, 24, 1, 24)
Shadow.Position = UDim2.new(0, -12, 0, -12)
Shadow.BackgroundTransparency = 1
Shadow.Parent = MainFrame

--// Glow
local Glow = Instance.new("ImageLabel")
Glow.Name = "Glow"
Glow.Image = "rbxassetid://5028857084"
Glow.ImageColor3 = IVORY_ACCENT
Glow.ImageTransparency = 1
Glow.ScaleType = Enum.ScaleType.Slice
Glow.SliceCenter = Rect.new(24, 24, 276, 276)
Glow.Size = UDim2.new(1, 80, 1, 80)
Glow.Position = UDim2.new(0, -40, 0, -40)
Glow.BackgroundTransparency = 1
Glow.ZIndex = 0
Glow.Parent = MainFrame

--// Accent line
local AccentLine = Instance.new("Frame")
AccentLine.Name = "AccentLine"
AccentLine.Size = UDim2.new(0, 0, 0, 2)
AccentLine.Position = UDim2.new(0, 0, 0, 0)
AccentLine.BackgroundColor3 = IVORY_ACCENT
AccentLine.BorderSizePixel = 0
AccentLine.Parent = MainFrame

local AccentCorner = Instance.new("UICorner")
AccentCorner.CornerRadius = UDim.new(0, 14)
AccentCorner.Parent = AccentLine

--// Icon
local Icon = Instance.new("ImageLabel")
Icon.Size = UDim2.new(0, 48, 0, 48)
Icon.Position = UDim2.new(0.5, -24, 0.04, 0)
Icon.Image = "rbxassetid://96858797315175"
Icon.BackgroundTransparency = 1
Icon.ImageTransparency = 1
Icon.ImageColor3 = IVORY_ACCENT
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = MainFrame

--// Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Position = UDim2.new(0, 0, 0.16, 0)
Title.BackgroundTransparency = 1
Title.Text = "Ivory"
Title.TextColor3 = IVORY_LIGHT
Title.Font = Enum.Font.Code
Title.TextSize = 32
Title.TextTransparency = 1
Title.Parent = MainFrame

--// Subtitle
local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, 0, 0, 25)
Subtitle.Position = UDim2.new(0, 0, 0.3, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "choose ur adventure or smth"
Subtitle.TextColor3 = IVORY_SUB
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 14
Subtitle.TextTransparency = 1
Subtitle.Parent = MainFrame

--// Meme text
local MemeText = Instance.new("TextLabel")
MemeText.Size = UDim2.new(1, 0, 0, 20)
MemeText.Position = UDim2.new(0, 0, 0.94, 0)
MemeText.BackgroundTransparency = 1
MemeText.Text = ""
MemeText.TextColor3 = IVORY_DIM
MemeText.Font = Enum.Font.Code
MemeText.TextSize = 11
MemeText.TextTransparency = 1
MemeText.TextXAlignment = Enum.TextXAlignment.Center
MemeText.Parent = MainFrame

--// Float state
local FloatOffset = 0
local FloatDirection = 1

--// RNG titles
local rngTitles = {
	"Ivory", "Ivory Hub", "ivory :3", "Ivory.exe", "Ivory.lua",
	"IVORY HUB", "ivory is cool", "Ivory (real)", "the ivory experience",
	"ivory go brr", "Ivory <3", "i am ivory", "Ivory on top",
	"welcome to ivory", "Ivory moment", "ivory for the win",
	"Ivory sweep", "ilovivory", "ivory deluxe", "ivory pro max",
	"ivory studio", "Ivory Central", "peak ivory", "ivory core",
	"Ivory's revenge", "return of ivory", "ivory strikes back",
	"ultra ivory", "mega ivory", "super ivory", "ivory supreme",
	"ultimate ivory", "ivory edition", "platinum ivory", "ivory XL",
}

--// RNG memes
local rngMemes = {
	"did someone say spaghetti", "my code is pasta", "al dente and tangled",
	"bon appetit", "gaming chair diff fr", "i got the 4000$ chair",
	"that's why i never miss", "totally not aimbot", "me and the boys",
	"running the script", "and getting banned", "worth it every time",
	"the script is free", "and open source", "and has silent aim",
	"what more could you want", "Error: can't find message",
	"i'm not having errors actually", "or maybe I am, who knows??",
	"is that a hack?", "no it's a gaming chair", "my chair has aimbot",
	"you should get one", "please read the info tab",
	"and credit me if u did a snippet", "i'm not a robot", "i'm ivory",
	"robots are metal", "ivory is rock", "big difference",
	"u ever just", "silent aim someone", "and they go '??? how'",
	"and then u say ping diff", "well I did that", "ivory has 0 calories",
	"wait this isn't a virus", "it's open source", "you can literally read it",
	"meow :3 .... MAW >:3", "can ivory run doom?", "ifone 90 proe max",
	"welcome to ivory hub", "loading features...", "esp go brr",
	"aimbot activated (not really)", "toggle spam real", "sliders > toggles",
	"color pickers go brr", "theme manager moment", "save configs pog",
	"notify me :3", "minimize keybind go", "dpi scale 200%",
	"corner radius 20", "obsidian ultra base", "library loaded",
	"tabs within tabs", "subtabs for the win", "sidebar dropdowns",
	"footer is copyable", "v1.4 baby", "try pressing F",
	"right bracket minimize", "o_o", ":3", "lololololooloo",
	"bombastic side eye", "oh shiddings nott gud D:",
}

--// Floating icon
task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		FloatOffset = FloatOffset + (0.5 * FloatDirection)
		if FloatOffset > 12 then
			FloatDirection = -1
		elseif FloatOffset < -12 then
			FloatDirection = 1
		end
		Icon.Position = UDim2.new(0.5, -24, 0.04 + (FloatOffset / 1200), 0)
		task.wait(0.02)
	end
end)

--// Random title
task.spawn(function()
	local lastTitleChange = 0
	while ScreenGui and ScreenGui.Parent do
		if tick() - lastTitleChange > math.random(4, 9) then
			local newTitle = rngTitles[math.random(1, #rngTitles)]
			local tween = TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				TextTransparency = 1,
			})
			tween:Play()
			tween.Completed:Wait()
			Title.Text = newTitle
			TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				TextTransparency = 0,
			}):Play()
			lastTitleChange = tick()
		end
		task.wait(0.5)
	end
end)

--// Typewriter meme text
task.spawn(function()
	local currentText = ""
	local cursorVisible = true
	local charIndex = 1
	local isErasing = false
	local currentMessage = ""

	while ScreenGui and ScreenGui.Parent do
		if not isErasing and (not currentMessage or currentMessage == "") then
			currentMessage = rngMemes[math.random(1, #rngMemes)]
			charIndex = 1
			currentText = ""
		end

		if not isErasing then
			if charIndex <= #currentMessage then
				currentText = currentText .. currentMessage:sub(charIndex, charIndex)
				charIndex = charIndex + 1
				MemeText.Text = currentText .. (cursorVisible and "_" or " ")
				task.wait(math.random(3, 8) / 100)
			else
				task.wait(math.random(15, 35) / 10)
				isErasing = true
			end
		else
			if #currentText > 0 then
				currentText = currentText:sub(1, #currentText - 1)
				MemeText.Text = currentText .. (cursorVisible and "_" or " ")
				task.wait(math.random(2, 5) / 100)
			else
				isErasing = false
				currentMessage = ""
				task.wait(math.random(5, 15) / 10)
			end
		end

		cursorVisible = not cursorVisible
		if not isErasing and currentText ~= "" then
			MemeText.Text = currentText .. (cursorVisible and "_" or " ")
		end
	end
end)

--// Glow pulse
task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		TweenService:Create(Glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			ImageTransparency = 0.85,
		}):Play()
		task.wait(2)
		TweenService:Create(Glow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			ImageTransparency = 0.95,
		}):Play()
		task.wait(2)
	end
end)

--// Option creator
local function createOption(name, iconId, pos, text, description)
	local Container = Instance.new("Frame")
	local IconContainer = Instance.new("Frame")
	local OptionIcon = Instance.new("ImageLabel")
	local Button = Instance.new("TextButton")
	local BtnCorner = Instance.new("UICorner")
	local BtnStroke = Instance.new("UIStroke")
	local OptionTitle = Instance.new("TextLabel")
	local OptionDesc = Instance.new("TextLabel")
	local IconCorner = Instance.new("UICorner")

	Container.Size = UDim2.new(0, 200, 0, 180)
	Container.Position = pos
	Container.BackgroundTransparency = 1
	Container.Parent = MainFrame

	IconContainer.Size = UDim2.new(0, 70, 0, 70)
	IconContainer.Position = UDim2.new(0.5, -35, 0.08, 0)
	IconContainer.BackgroundColor3 = Color3.fromRGB(30, 24, 45)
	IconContainer.BackgroundTransparency = 1
	IconContainer.Parent = Container
	IconCorner.CornerRadius = UDim.new(1, 0)
	IconCorner.Parent = IconContainer

	OptionIcon.Size = UDim2.new(0, 36, 0, 36)
	OptionIcon.Position = UDim2.new(0.5, -18, 0.5, -18)
	OptionIcon.Image = iconId
	OptionIcon.BackgroundTransparency = 1
	OptionIcon.ImageTransparency = 1
	OptionIcon.ImageColor3 = IVORY_ACCENT
	OptionIcon.Parent = IconContainer

	OptionTitle.Size = UDim2.new(1, 0, 0, 30)
	OptionTitle.Position = UDim2.new(0, 0, 0.48, 0)
	OptionTitle.BackgroundTransparency = 1
	OptionTitle.Text = text
	OptionTitle.TextColor3 = IVORY_LIGHT
	OptionTitle.Font = Enum.Font.GothamSemibold
	OptionTitle.TextSize = 16
	OptionTitle.TextTransparency = 1
	OptionTitle.Parent = Container

	OptionDesc.Size = UDim2.new(1, -20, 0, 40)
	OptionDesc.Position = UDim2.new(0, 10, 0.62, 0)
	OptionDesc.BackgroundTransparency = 1
	OptionDesc.Text = description
	OptionDesc.TextColor3 = IVORY_SUB
	OptionDesc.Font = Enum.Font.Gotham
	OptionDesc.TextSize = 12
	OptionDesc.TextTransparency = 1
	OptionDesc.TextWrapped = true
	OptionDesc.Parent = Container

	Button.Size = UDim2.new(0, 140, 0, 36)
	Button.Position = UDim2.new(0.5, -70, 0.85, 0)
	Button.BackgroundColor3 = Color3.fromRGB(35, 28, 52)
	Button.BackgroundTransparency = 1
	Button.Text = "Select"
	Button.Font = Enum.Font.GothamSemibold
	Button.TextColor3 = IVORY_LIGHT
	Button.TextSize = 14
	Button.AutoButtonColor = false
	Button.TextTransparency = 1
	Button.Parent = Container
	BtnCorner.CornerRadius = UDim.new(0, 8)
	BtnCorner.Parent = Button

	BtnStroke.Color = IVORY_ACCENT
	BtnStroke.Transparency = 1
	BtnStroke.Thickness = 1
	BtnStroke.Parent = Button

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(50, 40, 75),
			BackgroundTransparency = 0,
		}):Play()
		TweenService:Create(BtnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 0.4,
			Color = Color3.fromRGB(180, 150, 255),
		}):Play()
		TweenService:Create(IconContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.6,
		}):Play()
		TweenService:Create(OptionIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageColor3 = Color3.fromRGB(200, 170, 255),
		}):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundColor3 = Color3.fromRGB(35, 28, 52),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(BtnStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Color = IVORY_ACCENT,
		}):Play()
		TweenService:Create(IconContainer, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(OptionIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageColor3 = IVORY_ACCENT,
		}):Play()
	end)

	return Button, OptionIcon, OptionTitle, OptionDesc, IconContainer
end

--// Game supported = show game script option + universal option
--// No game = show only universal option
local GameBtn, GameIcon, GameTitle, GameDesc, GameContainer
local UniBtn, UniIcon, UniTitle, UniDesc, UniContainer

if DetectedGame then
	GameBtn, GameIcon, GameTitle, GameDesc, GameContainer = createOption("Game",
		"rbxassetid://7734056878",
		UDim2.new(0.05, 0, 0.3, 0),
		"GAME SCRIPT",
		DetectedGame.name .. "\nFull game-specific features"
	)

	UniBtn, UniIcon, UniTitle, UniDesc, UniContainer = createOption("Universal",
		"rbxassetid://96858797315175",
		UDim2.new(0.52, 0, 0.3, 0),
		"UNIVERSAL",
		"Works in any game\nESP, Aimbot, Speed, etc."
	)
else
	UniBtn, UniIcon, UniTitle, UniDesc, UniContainer = createOption("Universal",
		"rbxassetid://96858797315175",
		UDim2.new(0.5, -100, 0.3, 0),
		"UNIVERSAL",
		"Works in any game\nESP, Aimbot, Speed, etc."
	)
end

--// Entrance animation
local function tw()
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local infoFast = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(BackgroundBlur, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = 24,
	}):Play()
	TweenService:Create(MainFrame, info, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(Shadow, info, { ImageTransparency = 0.75 }):Play()

	task.wait(0.1)
	TweenService:Create(AccentLine, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(1, 0, 0, 2),
	}):Play()
	TweenService:Create(Glow, info, { ImageTransparency = 0.9 }):Play()

	TweenService:Create(Icon, infoFast, { ImageTransparency = 0 }):Play()
	task.wait(0.1)
	TweenService:Create(Title, info, { TextTransparency = 0 }):Play()
	TweenService:Create(Subtitle, info, { TextTransparency = 0 }):Play()
	TweenService:Create(MemeText, info, { TextTransparency = 0 }):Play()

	task.wait(0.2)
	if GameBtn then
		TweenService:Create(GameIcon, info, { ImageTransparency = 0 }):Play()
		TweenService:Create(GameTitle, info, { TextTransparency = 0 }):Play()
		TweenService:Create(GameDesc, info, { TextTransparency = 0 }):Play()
		TweenService:Create(GameBtn, info, { TextTransparency = 0, BackgroundTransparency = 1 }):Play()
	end
	TweenService:Create(UniIcon, info, { ImageTransparency = 0 }):Play()
	TweenService:Create(UniTitle, info, { TextTransparency = 0 }):Play()
	TweenService:Create(UniDesc, info, { TextTransparency = 0 }):Play()
	TweenService:Create(UniBtn, info, { TextTransparency = 0, BackgroundTransparency = 1 }):Play()
end

--// Exit animation + load
local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/main/"

local function loadScript(url)
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	TweenService:Create(BackgroundBlur, info, { Size = 0 }):Play()
	TweenService:Create(MainFrame, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(Shadow, info, { ImageTransparency = 1 }):Play()
	TweenService:Create(Glow, info, { ImageTransparency = 1 }):Play()
	TweenService:Create(AccentLine, info, { Size = UDim2.new(0, 0, 0, 2) }):Play()

	for _, v in pairs(MainFrame:GetDescendants()) do
		if v:IsA("TextLabel") or v:IsA("TextButton") then
			TweenService:Create(v, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
		elseif v:IsA("ImageLabel") then
			TweenService:Create(v, info, { ImageTransparency = 1 }):Play()
		elseif v:IsA("Frame") then
			TweenService:Create(v, info, { BackgroundTransparency = 1 }):Play()
		elseif v:IsA("UIStroke") then
			TweenService:Create(v, info, { Transparency = 1 }):Play()
		end
	end

	task.wait(0.5)
	ScreenGui:Destroy()
	BackgroundBlur:Destroy()

	--// Fetch and run
	local success, err = pcall(function()
		local commitHash = "main"
		pcall(function()
			local apiRes = request({
				Url = "https://api.github.com/repos/hubivory/IvoryHub/commits?per_page=1",
				Method = "GET",
			})
			if apiRes and apiRes.Body then
				local hash = apiRes.Body:match('"sha":"(%w+)"')
				if hash then commitHash = hash end
			end
		end)

		--// Cache ObsidianUltra
		local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
		pcall(function()
			local genv = getgenv()
			genv._IvoryLibSrc = request({ Url = repo .. "Library.lua", Method = "GET" }).Body
			genv._IvoryTMSrc = request({ Url = repo .. "addons/ThemeManager.lua", Method = "GET" }).Body
			genv._IvorySMSrc = request({ Url = repo .. "addons/SaveManager.lua", Method = "GET" }).Body
		end)

		local fetchUrl = GITHUB_RAW .. commitHash .. "/" .. url
		local res = request({ Url = fetchUrl, Method = "GET" })
		local content = res and res.Body or nil
		if not content then error("HTTP fetch failed") end
		if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
			content = content:sub(4)
		end
		local fn, loadErr = loadstring(content)
		if not fn then error("Compile error: " .. tostring(loadErr)) end
		fn()
	end)

	if success then
		print("[Ivory] Loaded successfully!")
	else
		warn("[Ivory] Failed to load:", err)
	end
end

--// Hover sound
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://9120299810"
hoverSound.Volume = 0.15
hoverSound.Parent = ScreenGui

--// Button handlers
if GameBtn then
	GameBtn.MouseEnter:Connect(function() hoverSound:Play() end)
	GameBtn.MouseButton1Click:Connect(function()
		loadScript(DetectedGame.file)
	end)
end

UniBtn.MouseEnter:Connect(function() hoverSound:Play() end)
UniBtn.MouseButton1Click:Connect(function()
	loadScript("Loader.luau")
end)

--// Run
tw()
