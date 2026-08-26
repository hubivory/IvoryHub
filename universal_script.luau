-- BLLEHHH >:P
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local BackgroundBlur = Instance.new("BlurEffect")
local Shadow = Instance.new("ImageLabel")
local Subtitle = Instance.new("TextLabel")
local MemeText = Instance.new("TextLabel")
local Icon = Instance.new("ImageLabel")
local FloatOffset = 0
local FloatDirection = 1
BackgroundBlur.Size = 24
BackgroundBlur.Parent = game:GetService("Lighting")
ScreenGui.Name = "option"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 340)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BackgroundTransparency = 0.15
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
Shadow.Name = "Shadow"
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.8
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, -10)
Shadow.BackgroundTransparency = 1
Shadow.Parent = MainFrame
UICorner.CornerRadius = UDim.new(0, 14)
UICorner.Parent = MainFrame
Icon.Size = UDim2.new(0, 40, 0, 40)
Icon.Position = UDim2.new(0.5, -20, 0.05, 0)
Icon.Image = "rbxassetid://96858797315175"
Icon.BackgroundTransparency = 1
Icon.ImageTransparency = 1
Icon.ScaleType = Enum.ScaleType.Fit
Icon.Parent = MainFrame
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Position = UDim2.new(0, 0, 0.15, 0)
Title.BackgroundTransparency = 1
Title.Text = "Gravel.cc"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.Code
Title.TextSize = 28
Title.TextTransparency = 1
Title.Parent = MainFrame
Subtitle.Size = UDim2.new(1, 0, 0, 25)
Subtitle.Position = UDim2.new(0, 0, 0.28, 0)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "choose ur adventure or smth"
Subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextSize = 14
Subtitle.TextTransparency = 1
Subtitle.Parent = MainFrame
MemeText.Size = UDim2.new(1, 0, 0, 20)
MemeText.Position = UDim2.new(0, 0, 0.95, 0)
MemeText.BackgroundTransparency = 1
MemeText.Text = ""
MemeText.TextColor3 = Color3.fromRGB(120, 120, 120)
MemeText.Font = Enum.Font.Code
MemeText.TextSize = 11
MemeText.TextTransparency = 1
MemeText.TextXAlignment = Enum.TextXAlignment.Center
MemeText.Parent = MainFrame

local rngTitles = {
	"Gravel.cc",
	"G.cc",
	"HBSS.cc",
	"Gravel-est",
	"Gravel-er",
	"Graaaavel.cc",
	"Gravelly.cc",
	"Gravel.com",
	"Hi! I'm Gravel.cc",
	"Gravel :3",
	"GRAVEL.CC >:D",
	"holy gravel.cc",
	"GravelGravelGravel.cc",
	"I like gravel",
	"Gravel.cheatcheat",
	"Gravel.yes",
	"Gravel.no",
	"Gravel.lua",
	"GRAVEL GRAVEL.CC",
	"rock solid ui",
	"gravel is not sand",
	"is gravel just sand",
	"gravel cute :3",
	"gravel go brr",
	"Gpssickle's child",
	"shovel upgrade 1+",
	"crushed rocks simulator",
	"the gravel experience",
}

local rngMemes = {
	"did someone say spaghetti",
	"my code is pasta",
	"al dente and tangled",
	"bon appetit",
	"gaming chair diff fr",
	"i got the 4000$ chair",
	"that's why i never miss",
	"totally not aimbot",
	"me and the boys",
	"running the script",
	"and getting banned",
	"worth it every time",
	"the script is free",
	"and open source",
	"and has silent aim",
	"what more could you want",
	"Error: can't find message",
	"i'm not having errors actually",
	"or maybe I am, who knows??",
	"is that a hack?",
	"no it's a gaming chair",
	"my chair has aimbot",
	"you should get one",
	"please read the InfoTab",
	"and credit me if u did a snippet",
	"i'm not a robot",
	"i'm a gravel",
	"robots are metal",
	"gravel is rock",
	"big difference",
	"u ever just",
	"silent aim someone",
	"and they go '??? how'",
	"and then u say ping diff",
	"well I did that",
	"Gravel has 0 calories",
	"wait this isn't a virus",
	"it's open source",
	"you can literally read it",
	"meow :3 .... MAW >:3",
	"can gravel run doom?",
	"ifone 90 proe max",
	"wth is ts",
	"hell nah",
	"OHHHH HELLL NAH",
	"pop-up goes bye bye",
	"isn't phonk just noise?",
	"guys it's a-a, a-a h-hacker!?!?!",
	"tiki tiki",
	"Nosirski!",
	"click here or ur gay",
	"lolzer-fying",
	"helohi",
	"portal above portal below *jumps in*",
	"GRAVEL-MAN",
	"IM SKYLER WHITE, YO",
	"my diet is gravel",
	"dab me up :>",
	"how much saves do u has",
	"O rly",
	":3",
	"lololololooloo",
	"is that a toby?",
	"Gugu Gaga Ultimated Flex Works",
	"why is there ai slop on my TikTok fyp",
	"bombastic side eye",
	"oh shiddings nott gud D:",
}

task.spawn(function()
	while ScreenGui and ScreenGui.Parent do
		FloatOffset = FloatOffset + (0.5 * FloatDirection)
		if FloatOffset > 12 then
			FloatDirection = -1
		elseif FloatOffset < -12 then
			FloatDirection = 1
		end
		Icon.Position = UDim2.new(0.5, -20, 0.05 + (FloatOffset / 1200), 0)
		task.wait(0.02)
	end
end)

task.spawn(function()
	local lastTitleChange = 0
	while ScreenGui and ScreenGui.Parent do
		if tick() - lastTitleChange > math.random(4, 9) then
			local newTitle = rngTitles[math.random(1, #rngTitles)]
			local tween =
				TweenService:Create(Title, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
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
	IconContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	IconContainer.BackgroundTransparency = 0.9
	IconContainer.Parent = Container
	IconCorner.CornerRadius = UDim.new(1, 0)
	IconCorner.Parent = IconContainer

	OptionIcon.Size = UDim2.new(0, 40, 0, 40)
	OptionIcon.Position = UDim2.new(0.5, -20, 0.5, -20)
	OptionIcon.Image = iconId
	OptionIcon.BackgroundTransparency = 1
	OptionIcon.ImageTransparency = 1
	OptionIcon.Parent = IconContainer

	OptionTitle.Size = UDim2.new(1, 0, 0, 30)
	OptionTitle.Position = UDim2.new(0, 0, 0.48, 0)
	OptionTitle.BackgroundTransparency = 1
	OptionTitle.Text = text
	OptionTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
	OptionTitle.Font = Enum.Font.GothamSemibold
	OptionTitle.TextSize = 16
	OptionTitle.TextTransparency = 1
	OptionTitle.Parent = Container

	OptionDesc.Size = UDim2.new(1, -20, 0, 40)
	OptionDesc.Position = UDim2.new(0, 10, 0.62, 0)
	OptionDesc.BackgroundTransparency = 1
	OptionDesc.Text = description
	OptionDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
	OptionDesc.Font = Enum.Font.Gotham
	OptionDesc.TextSize = 12
	OptionDesc.TextTransparency = 1
	OptionDesc.TextWrapped = true
	OptionDesc.Parent = Container

	Button.Size = UDim2.new(0, 140, 0, 36)
	Button.Position = UDim2.new(0.5, -70, 0.85, 0)
	Button.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	Button.BackgroundTransparency = 0.9
	Button.Text = "Select"
	Button.Font = Enum.Font.GothamSemibold
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextSize = 14
	Button.AutoButtonColor = true
	Button.TextTransparency = 1
	Button.Parent = Container
	BtnCorner.CornerRadius = UDim.new(0, 8)
	BtnCorner.Parent = Button

	BtnStroke.Color = Color3.fromRGB(80, 80, 80)
	BtnStroke.Transparency = 0.8
	BtnStroke.Thickness = 1
	BtnStroke.Parent = Button

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.7,
			BackgroundColor3 = Color3.fromRGB(50, 50, 50),
		}):Play()
		TweenService:Create(BtnStroke, TweenInfo.new(0.2), {
			Transparency = 0.5,
		}):Play()
		TweenService:Create(IconContainer, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.7,
		}):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.9,
			BackgroundColor3 = Color3.fromRGB(45, 45, 45),
		}):Play()
		TweenService:Create(BtnStroke, TweenInfo.new(0.2), {
			Transparency = 0.8,
		}):Play()
		TweenService:Create(IconContainer, TweenInfo.new(0.2), {
			BackgroundTransparency = 0.9,
		}):Play()
	end)

	return Button, OptionIcon, OptionTitle, OptionDesc, IconContainer
end

local YesBtn, OldIcon, OldTitle, OldDesc, OldIconContainer = createOption(
	"Yes",
	"rbxassetid://7734056878",
	UDim2.new(0.05, 0, 0.3, 0),
	"LEGACY VERSION",
	"Good old days won't be updated\n(Bad injectors work here)"
)

local NoBtn, NewIcon, NewTitle, NewDesc, NewIconContainer = createOption(
	"No",
	"rbxassetid://96858797315175",
	UDim2.new(0.52, 0, 0.3, 0),
	"NEW VERSION",
	"New bs & updated regularly\n(Bad injectors not recommended)"
)

local function tw()
	local info = TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local info2 = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	TweenService:Create(Icon, info2, { ImageTransparency = 0 }):Play()
	TweenService:Create(MainFrame, info, { BackgroundTransparency = 0.15 }):Play()
	task.wait(0.1)
	TweenService:Create(Title, info, { TextTransparency = 0 }):Play()
	TweenService:Create(Subtitle, info, { TextTransparency = 0 }):Play()
	TweenService:Create(MemeText, info, { TextTransparency = 0 }):Play()
	task.wait(0.2)
	TweenService:Create(OldIcon, info, { ImageTransparency = 0 }):Play()
	TweenService:Create(NewIcon, info, { ImageTransparency = 0 }):Play()
	TweenService:Create(OldIconContainer, info, { BackgroundTransparency = 0.9 }):Play()
	TweenService:Create(NewIconContainer, info, { BackgroundTransparency = 0.9 }):Play()
	TweenService:Create(OldTitle, info, { TextTransparency = 0 }):Play()
	TweenService:Create(NewTitle, info, { TextTransparency = 0 }):Play()
	TweenService:Create(OldDesc, info, { TextTransparency = 0 }):Play()
	TweenService:Create(NewDesc, info, { TextTransparency = 0 }):Play()
	TweenService:Create(YesBtn, info, { TextTransparency = 0, BackgroundTransparency = 0.9 }):Play()
	TweenService:Create(NoBtn, info, { TextTransparency = 0, BackgroundTransparency = 0.9 }):Play()
end

local function get(url)
	local info = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	TweenService:Create(BackgroundBlur, info, { Size = 0 }):Play()
	TweenService:Create(MainFrame, info, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(Shadow, info, { ImageTransparency = 1 }):Play()

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
	loadstring(game:HttpGet(url))()
end

local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://9120299810"
hoverSound.Volume = 0.15
hoverSound.Parent = ScreenGui

YesBtn.MouseEnter:Connect(function()
	hoverSound:Play()
end)
NoBtn.MouseEnter:Connect(function()
	hoverSound:Play()
end)

YesBtn.MouseButton1Click:Connect(function()
	get("https://raw.githubusercontent.com/hm5650/HBSS/refs/heads/main/HBSS_Old.lua")
end)

NoBtn.MouseButton1Click:Connect(function()
	get("https://raw.githubusercontent.com/hm5650/HBSS/refs/heads/main/HBSS_New.lua")
end)

tw()
