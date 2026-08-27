-- ═══════════════════════════════════════════════════════════
-- Ivory Parry — Blade Ball | minimal auto-parry (no GUI)
--
-- Singleton: re-deploying instantly retires any older instance.
-- Wide trigger: any ball targeting you inside ~38 studs = fire.
-- Curved balls lie about velocity, distance never does.
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local myToken = tostring({})
getgenv().IvoryParryToken = myToken

local lastParryTime = 0
local lastLog = 0
local currentPing = 0

spawn(function()
	while true do
		wait(2)
		pcall(function()
			currentPing = math.floor(LocalPlayer:GetNetworkPing() * 1000)
		end)
	end
end)

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
	end
end

local function GetMyBall()
	-- With multiple balls in play, always track the one targeting YOU.
	for _, obj in ipairs(Workspace.Balls:GetChildren()) do
		if obj:IsA("BasePart") and obj:GetAttribute("realBall") == true and obj:GetAttribute("target") == LocalPlayer.Name then
			return obj
		end
	end
	return nil
end

spawn(function()
	wait(1)
	local wasOnMe = false
	while true do
		wait(0.01)
		pcall(function()
			if getgenv().IvoryParryToken ~= myToken then return end

			local realBall = GetMyBall()
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not realBall or not myRoot then
				wasOnMe = false
				return
			end

			local dist = (realBall.Position - myRoot.Position).Magnitude
			local speed = realBall.AssemblyLinearVelocity.Magnitude
			local pingSec = currentPing / 1000

			-- The ball accelerates hard the instant it flips target, so its
			-- current velocity lies. Fire on the flip itself, plus a lead.
			local leadDist = 40 + speed * (pingSec + 0.15)
			leadDist = math.clamp(leadDist, 50, 250)

			local now = tick()
			local msSince = (now - lastParryTime) * 1000

			local panic = dist < 25
			local canFire = msSince > 300 or (panic and msSince > 140)

			if (not wasOnMe or dist < leadDist) and canFire then
				doParry()
				lastParryTime = tick()
				if now - lastLog > 3 then
					lastLog = now
					print(string.format("[Ivory Parry] fired | dist=%d speed=%d lead=%d ping=%d flip=%s", dist, speed, leadDist, currentPing, tostring(not wasOnMe)))
				end
			end
			wasOnMe = true
		end)
	end
end)

print("[Ivory Parry] running - minimal auto-parry, no GUI")
print("[Ivory Parry] input: " .. (ParryBtn and "ParryButtonPress" or "mouse1click"))
