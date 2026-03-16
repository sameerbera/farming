# Start Here

This workspace already contains the Roblox source for **Farm Mutation MMO**.

## Fastest Way To Open It In Roblox Studio

1. Install the **Rojo Studio plugin** from the Roblox Creator Marketplace.
2. Install the **Rojo CLI** on your PC.
3. Open Roblox Studio.
4. Create a new `Baseplate` place.
5. In this folder, run:
   ```powershell
   .\scripts\Serve-Rojo.cmd
   ```
6. In Studio, open the Rojo plugin and connect to the local project.
7. Sync the project into Studio.
8. Press `Play` or start a local server to test multiplayer features.

## If Rojo Is Not Installed

The helper script will tell you, but here are common install options:

- `winget install Rojo.Rojo`
- `choco install rojo`

If neither works, install it manually from the official Rojo releases page.

After installing, run:

```powershell
.\scripts\Serve-Rojo.cmd
```

## What This Project Syncs

- `ReplicatedStorage`
- `ServerScriptService`
- `StarterPlayer`

The sync mapping lives in [default.project.json](C:/Users/samee/OneDrive/Desktop/codex/default.project.json).

## How To Give Me Access To Your Existing Roblox Game

Use one of these options and place the files in this workspace:

### Option 1: Export Your Place

1. Open your game in Roblox Studio.
2. Click `File` -> `Save to File As...`
3. Save it as a `.rbxlx` file into this folder:
   - `C:\Users\samee\OneDrive\Desktop\codex\incoming`

### Option 2: Export Your Existing Rojo Project

If your game already uses Rojo, copy the whole project folder here:

- `C:\Users\samee\OneDrive\Desktop\codex\incoming\your-project`

Include:

- `default.project.json`
- `src\...`
- any shared packages or config files

## After You Add Your Existing Game

Tell me one of these:

- `I added a .rbxlx file in incoming`
- `I copied my Rojo project into incoming\your-project`

Then I can:

- inspect your current game structure
- merge Farm Mutation MMO into it
- preserve your existing systems where possible
- reshape this scaffold into your current Studio layout

## Helpful Files

- [README.md](C:/Users/samee/OneDrive/Desktop/codex/README.md)
- [default.project.json](C:/Users/samee/OneDrive/Desktop/codex/default.project.json)
- [Boot.server.lua](C:/Users/samee/OneDrive/Desktop/codex/src/ServerScriptService/Boot.server.lua)
- [ClientBoot.client.lua](C:/Users/samee/OneDrive/Desktop/codex/src/StarterPlayer/StarterPlayerScripts/ClientBoot.client.lua)
