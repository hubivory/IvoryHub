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
	while true do
		wait(0.01)
		pcall(function()
			if getgenv().IvoryParryToken ~= myToken then return end

			local realBall = GetMyBall()
			local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if not realBall or not myRoot then return end

			local dist = (realBall.Position - myRoot.Position).Magnitude
			local toBall = (myRoot.Position - realBall.Position).Unit
			local closing = math.max(realBall.AssemblyLinearVelocity:Dot(toBall), 60)
			local tti = dist / closing

			local now = tick()
			local msSince = (now - lastParryTime) * 1000

			local inWindow = dist < 38 or tti < 0.16
			local panic = dist < 25
			local canFire = msSince > 350 or (panic and msSince > 150)

			if inWindow and canFire then
				doParry()
				lastParryTime = tick()
				if now - lastLog > 3 then
					lastLog = now
					print(string.format("[Ivory Parry] fired | dist=%d", dist))
				end
			end
		end)
	end
end)

print("[Ivory Parry] running - minimal auto-parry, no GUI")
print("[Ivory Parry] input: " .. (ParryBtn and "ParryButtonPress" or "mouse1click"))
