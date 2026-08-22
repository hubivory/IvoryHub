# Final Swarm [Skills] - Feature Reference

## Game Overview
- **Game:** Final Swarm [Skills] by Evolution Studio Games
- **Genre:** Wave-based zombie survival combat
- **Core Loop:** Kill zombies → Collect XP → Choose upgrades → Survive waves → Repeat

## Combat System
- **Weapons:** Melee and ranged weapons with elemental damage
- **Kill Aura:** Auto-damage nearby enemies within range
- **Auras:** Area-of-effect damage over time
- **Projectiles:** Ranged attack system (FastCastRedux)

## Enemy System
- **Enemies:** Zombies spawning in waves
- **Health Bars:** Billboard GUIs on enemies
- **Enemy Types:** Various with different stats
- **Boss Enemies:** Special enemies with health bars in HUD

## Upgrade System
- **Selection Screen:** Choose 1 of 3 upgrades per wave
- **Reroll:** Re-roll available upgrades (costs currency)
- **Banish:** Remove an upgrade from future selections
- **Upgrade Categories:** Various combat and utility upgrades

## Wave System
- **Waves:** Progressive difficulty scaling
- **Milestones:** Special rewards at wave milestones
- **Final Swarm:** Special mode with reward multipliers
- **Wave Timer:** Countdown between waves

## Player Stats
- **XP:** Experience points for leveling
- **Level:** Player level progression
- **Gold:** In-game currency
- **Kills:** Total enemy kills
- **Damage:** Total damage dealt

## Collectables
- **XP Orbs:** Dropped by enemies
- **Chests:** Treasure chests (regular and large)
- **Pots:** Smashable containers
- **Magnet:** Auto-collect all items

## Services (Networker-based)
- GameService: Round management, difficulty
- WeaponService: Weapons, auras, damage
- EnemyService: Enemy spawning and management
- CollectableService: Item collection
- ChestService: Chest interactions
- ChallengeService: Special challenges
- PlayerStatus: Player state
- PlayerRunData: Run statistics

## Network Architecture
- Uses `leifstout_networker` package for remotes
- Pattern: `Networker.client.new("ServiceName", handlers)`
- Fire: `networker:fire("Method", ...)`
- Fetch: `networker:fetch("Method", ...)`
