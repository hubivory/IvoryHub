-- ═══════════════════════════════════════════════════════════
-- Ivory Stealth — headless BAC test build
-- Zero GUIs, zero highlights, zero library. Pure auto-parry.
-- If this gets kicked, visual artifacts were never the trigger.
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local VIM = game:GetService("VirtualInputManager")

-- Set getgenv().StealthParryEnabled = false to run with logic only,
-- never firing a single parry. Separates GUI triggers from behavior.
local ParryEnabled = getgenv().StealthParryEnabled ~= false

local lastParryTime = 0
local currentPing = 0

local ParryBtn = nil
pcall(function()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		ParryBtn = remotes:FindFirstChild("ParryButtonPress")
	end
end)

local function doParry()
	if ParryBtn and ParryBtn:IsA("BindableEvent") then
		local ok = pcall(function() ParryBtn:Fire() end)
		if ok then return end
	end
	if mouse1click then
		mouse1click()
		return
	end
	pcall(function()
		VIM:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
		wait(0.03)
		VIM:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
	end)
end

local function jitter(base, pct)
	return base * (1 + (math.random() * 2 - 1) * pct)
end

local function GetRealBall()
	for _, obj in ipairs(Workspace.Balls:GetChildren()) do
		if obj:IsA("BasePart") and obj:GetAttribute("realBall") == true then
			return obj
		end
	end
	for _, obj in ipairs(Workspace.Balls:GetChildren()) do
		if obj:IsA("BasePart") then
			local t = obj:GetAttribute("target")
			if t and t ~= "" then return obj end
		end
	end
	return nil
end

spawn(function()
	while true do
		wait(2)
		pcall(function()
			currentPing = math.floor(LocalPlayer:GetNetworkPing() * 1000)
		end)
	end
end)

spawn(function()
	wait(1)
	while true do
		wait(0.01)
		pcall(function()
			if not ParryEnabled then return end
			local realBall = GetRealBall()
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not realBall or not myRoot then return end

			local targetName = realBall:GetAttribute("target")
			if targetName ~= LocalPlayer.Name then return end
			if not isrbxactive() then return end

			local baseDist = 30
			local baseCD = 350

			local speed = realBall.AssemblyLinearVelocity.Magnitude
			local adaptiveDist = math.clamp(baseDist + (speed / 3), baseDist, 150)

			local distNoise = (math.random() * 2 - 1) * 5
			local dist = (realBall.Position - myRoot.Position).Magnitude
			local now = tick()
			local msSince = (now - lastParryTime) * 1000

			local cd = math.max(jitter(baseCD, 0.2), 180, currentPing * 0.75)

			if dist < (adaptiveDist + distNoise) and msSince > cd then
				if math.random(100) <= 5 and dist > 20 then
					wait(math.random(50, 160) / 1000)
					if realBall:GetAttribute("target") ~= LocalPlayer.Name then
						lastParryTime = tick()
						return
					end
				end
				doParry()
				lastParryTime = tick()
			end
		end)
	end
end)

print("[Ivory Stealth] headless running - zero GUIs, zero highlights")
print("[Ivory Stealth] auto-parry enabled: " .. tostring(ParryEnabled))
