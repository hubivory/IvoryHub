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
	local lastLog = 0
	while true do
		wait(0.01)
		pcall(function()
			if not ParryEnabled then return end
			local realBall = GetRealBall()
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not realBall or not myRoot then return end

			local targetName = realBall:GetAttribute("target")
			local now = tick()

			-- light heartbeat log so we can verify the loop is alive
			if now - lastLog > 2 then
				lastLog = now
				print(string.format("[Ivory Stealth] alive | target=%s me=%s dist=%d", tostring(targetName), LocalPlayer.Name, math.floor((realBall.Position - myRoot.Position).Magnitude)))
			end

			if targetName ~= LocalPlayer.Name then return end

			-- Time-to-impact trigger: parry when the ball is ~150ms away.
			-- Distance-based triggers fire early at high speeds, waste the
			-- attempt out of range, and the cooldown eats the real parry.
			local dist = (realBall.Position - myRoot.Position).Magnitude
			local toBall = (myRoot.Position - realBall.Position).Unit
			local closing = math.max(realBall.AssemblyLinearVelocity:Dot(toBall), 60)
			local tti = dist / closing

			local msSince = (now - lastParryTime) * 1000
			local cd = math.max(jitter(350, 0.2), 180, currentPing * 0.75)

			-- panic mode: ball right on top of you, fire up to ~8x/sec
			local danger = dist < 25
			local canFire = msSince > cd or (danger and msSince > 120)

			if (tti < 0.16 or dist < 22) and canFire then
				doParry()
				lastParryTime = tick()
			end
		end)
	end
end)

print("[Ivory Stealth] headless running - zero GUIs, zero highlights")
print("[Ivory Stealth] auto-parry enabled: " .. tostring(ParryEnabled))
