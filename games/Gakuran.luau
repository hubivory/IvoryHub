-- PlaceId: 128736949265057
-- Ivory Hub - Gakuran (Bootstrapper)

do
    local prev = _G.IvoryGakuran
    if prev and type(prev.Unload) == "function" then pcall(prev.Unload) end
end
_G.IvoryGakuran = { conns = {}, dead = false, loops = {} }

local repo = "https://raw.githubusercontent.com/joustingmatch/ObsidianUltra/main/"
local httpGet = function(url) return request({ Url = url, Method = "GET" }).Body end

local Library = loadstring(getgenv()._IvoryLibSrc or httpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(getgenv()._IvoryTMSrc or httpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(getgenv()._IvorySMSrc or httpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles
Library.ShowToggleFrameInKeybinds = true

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "Ivory | Gakuran",
    Footer = { "v1.0 |", { Text = "Gakuran", Copyable = true }, "|", { Text = tostring(LocalPlayer.UserId), Copyable = true } },
    CopyableFooter = true, FuzzySearch = true, SearchValues = true, Minimizable = true,
    MinimizeKeybind = Enum.KeyCode.RightBracket, MinimizedWidth = 280, NotifySide = "Right",
    ShowCustomCursor = false, SearchKeybind = Enum.KeyCode.F, CornerRadius = 4,
    Animations = { SubTabUnderline = true },
})

ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("IvoryHub"); SaveManager:SetFolder("IvoryHub")
SaveManager:SetSubFolder("gakuran")

local CombatTab = Window:AddTab({ Name = "Combat", Icon = "swords", Description = "Parry, dodge & punish" })
local VisualTab = Window:AddTab({ Name = "Visuals", Icon = "eye", Description = "ESP & world" })
local MoveTab = Window:AddTab({ Name = "Movement", Icon = "run", Description = "Speed, fly & teleport" })
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "star", Description = "Game & server" })
local SettingsTab = Window:AddTab({ Name = "Settings", Icon = "settings", Description = "UI settings" })

_G.IvoryGakuranCtx = {
    Library = Library, ThemeManager = ThemeManager, SaveManager = SaveManager,
    Options = Options, Toggles = Toggles,
    Window = Window, CombatTab = CombatTab, VisualTab = VisualTab,
    MoveTab = MoveTab, MiscTab = MiscTab, SettingsTab = SettingsTab,
}

local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub/"
local GITHUB_API = "https://api.github.com/repos/hubivory/IvoryHub/commits?per_page=1"
local commitHash = "main"
pcall(function()
    local apiRes = request({ Url = GITHUB_API, Method = "GET" })
    if apiRes and apiRes.Body then
        local hash = apiRes.Body:match('"sha":"(%w+)"')
        if hash then commitHash = hash end
    end
end)

local url = GITHUB_RAW .. commitHash .. "/games/Gakuran_logic.luau"
local res = request({ Url = url, Method = "GET" })
local content = res and res.Body or nil
if content then
    if content:byte(1) == 0xEF and content:byte(2) == 0xBB and content:byte(3) == 0xBF then
        content = content:sub(4)
    end
    local fn, err = loadstring(content)
    if fn then fn() else warn("[Ivory Gakuran] Compile error:", err) end
end
