# Server Scripts

Server-owned systems live here.

- `Main.server.lua` — creates remotes and initializes services
- `PlayerDataService.lua` — saves player inventory/progress
- `RewardService.lua` — awards crumbs/DNA
- `HazardService.lua` — sends hazard warnings
- `RoundService.lua` — starts/ends survival rounds and spawns placeholder crumbs

Keep trusted game logic on the server. The client can request actions, but the server decides what is valid.
