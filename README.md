# Farm Mutation MMO

A Rojo-ready Roblox multiplayer farming simulator scaffold with:

- Shared 24-plot server world generation
- Central town hub with shop, trading, auction, pet, and daily reward stations
- Four exploration biomes: Forest, Crystal Cave, Volcano, Sky Island
- Grid-based crop planting with visible growth stages and mutation outcomes
- Tool progression from Starter to Mythic
- Automation machines with plot power limits
- Safe player trading and a server auction board
- Farm level progression, leaderboard stats, pets, and rotating mutation contests

## Project Layout

- `default.project.json`: Rojo mapping
- `src/ReplicatedStorage/Shared`: shared definitions, constants, formatting helpers, remote names
- `src/ServerScriptService/Boot.server.lua`: startup entrypoint
- `src/ServerScriptService/Services`: server gameplay systems
- `src/StarterPlayer/StarterPlayerScripts/ClientBoot.client.lua`: HUD, panels, notifications, trading UI

## Core Loop

1. Join and receive a personal farm plot.
2. Equip the hoe, pick a seed from the seed dock, and click a plot tile to plant.
3. Water crops with the watering can or automate them later with sprinklers.
4. Harvest mature crops, discover mutations, and sell produce from the inventory dock.
5. Upgrade tools, unlock seeds and biomes, buy pets, and place automation machines.
6. Trade rare produce with other players or post it on the auction board.
7. Compete in timed Mutation Clash contests for gems and coins.

## Running In Roblox Studio

1. Open the project through [Rojo](https://rojo.space/) using `default.project.json`.
2. Start a local server with multiple test players to exercise trading and shared-world features.
3. Use the central town prompts or the top navigation HUD buttons to open shops and systems.

## Notes

- The world is generated at runtime, so no `.rbxl` place file is required.
- Persistence uses Roblox DataStores and falls back to default session profiles if Studio access is unavailable.
- Machines are returned to the player's inventory when they leave, but live crop plots are session-based.
