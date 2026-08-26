-- Scan for burger/equip related remotes in this game
local RS = game:GetService("ReplicatedStorage")
local function scan(parent, depth)
    if depth > 4 then return end
    for _, child in ipairs(parent:GetChildren()) do
        local name = child.Name:lower()
        if name:find("equip") or name:find("select") or name:find("burger") or name:find("swap") or name:find("best") or name:find("slot") or name:find("place") or name:find("set") then
            print("[SCAN] " .. child.ClassName .. " - " .. child:GetFullName())
        end
        if child:IsA("Folder") or child:IsA("Model") then
            scan(child, depth + 1)
        end
    end
end
print("=== Scanning ReplicatedStorage ===")
scan(RS, 0)
print("=== Done ===")
