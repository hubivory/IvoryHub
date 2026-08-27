-- ═══════════════════════════════════════════════════════════
-- Ivory Parry v2 — Blade Ball | minimal auto-parry (no GUI)
--
-- v2 fixes:
--   + Blade Ball's block has its own ~1s cooldown. Clicking during it
--     is a wasted click that can eat the parry that would save you.
--     All clicks now respect a global 1100ms spacing.
--   + Only fires in parry range (<45 studs) or on a close flip (<60).
--   + Singleton token retires older Ivory Parry instances.
-- ═══════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

local myToken = tostring({})
getgenv().IvoryParryToken = myToken
getgenv().IvoryParryLastClick = getgenv().IvoryParryLastClick or 0

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
			local now = tick()
			local msSinceClick = (now - getgenv().IvoryParryLastClick) * 1000

			-- The game's block cooldown eats rapid clicks - respect it.
			local panic = dist < 25
			local minGap = panic and 450 or 1100
			local canClick = msSinceClick > minGap

			-- Parry range discipline: only click when it can connect.
			local inRange = dist < 45
			local closeFlip = (not wasOnMe) and dist < 60

			if (inRange or closeFlip) and canClick then
				doParry()
				getgenv().IvoryParryLastClick = tick()
				if now - lastLog > 3 then
					lastLog = now
					print(string.format("[Ivory Parry] click | dist=%d flip=%s", dist, tostring(not wasOnMe)))
				end
			end
			wasOnMe = true
		end)
	end
end)

print("[Ivory Parry v2] running - 1100ms click spacing, 45-stud range")
print("[Ivory Parry v2] input: " .. (ParryBtn and "ParryButtonPress" or "mouse1click"))
