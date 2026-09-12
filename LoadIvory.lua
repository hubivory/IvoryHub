local GITHUB_RAW = "https://raw.githubusercontent.com/hubivory/IvoryHub-Public/"

local GameScripts = {
    [2822776643] = "games/ElementalMagicArena.luau",
    [10648820673] = "games/Karinderya.luau",
    [9551044479] = "games/FinalSwarm.luau",
    [10508706289] = "games/MeltTheIce.luau",
    [703124385] = "games/Towerofhell.luau",
    [7498898979] = "games/BuildABurger.luau",
    [105963809208632] = "games/BuildABurger.luau",
    [10516888336] = "games/CatchABillionDucks.luau",
    [6035872082] = "games/IvoryRivals.luau",
    [10292888022] = "games/RocksRNG.luau",
    [3620011279] = "games/Floppa2.luau",
    [4777817887] = "games/Bladeball_BAC.luau",
    [66654135] = "games/MM2.luau",
    [5995470825] = "games/Hypershot.luau",
    [10539411000] = "games/CleanAllTheLeaves.luau",
    [10144280947] = "games/Monkeyescape.luau",
    [9561553764] = "games/Murderduels.luau",
    [994732206] = "games/Bloxfruits.luau",
    [7633926880] = "games/Bloxstrike.luau",
    [10475794799] = "games/DigAndClean.luau",
    [10514280922] = "games/RollAGnome.luau",
    [10410945205] = "games/cutgrass.luau",
    [3476371299] = "games/raceclick.luau",
    [10563114921] = "games/StealAnEgg.luau",
    [9199655655] = "games/Gakuran.luau",
    [8307114974] = "games/Operationone.luau",
    [10648640958] = "games/Hoodrivals.luau",
    [7326934954] = "games/99nights.luau",
    [7395930870] = "games/SellLemons.luau",
    [10391825421] = "games/LootEvo.luau",
    [9280810829] = "games/LootUp.luau",
    [10756011174] = "games/Findneedle.lua",
    [4348829796] = "games/MVSD.luau",
    [10440833423] = "games/GreedyGrowers.luau",
    [10548152848] = "games/Runeheaven.luau",
    [10090256806] = "games/TTK.luau",
    [5091490171] = "games/Jailbird.luau",
    [1119466531] = "games/LegendsOfSpeed.luau",
    [7265339759] = "games/Redliner.luau",
    [10690360998] = "games/JumpForAnimals.luau",
    [9587877329] = "games/JumpingBaddies.luau",
    [6701277882] = "games/FishIt.luau",
}

local function GetGameScript(gameId)
    local scriptPath = GameScripts[gameId]
    if scriptPath then
        return GITHUB_RAW .. "main/" .. scriptPath
    end
    return nil
end

local script = GetGameScript(game.GameId)
if script then
    loadstring(script)()
else
    warn("Game script not found for GameId: " .. game.GameId)
end
