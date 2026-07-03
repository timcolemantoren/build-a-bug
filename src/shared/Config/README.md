# Shared Config

These files are the first balancing layer for Build a Bug.

- `BugArchetypes.lua` — playable base bugs and their starting stats
- `BugOrder.lua` — display order for bug selection UI
- `CosmeticItems.lua` — cosmetic-only unlock catalog
- `GameConstants.lua` — names and global switches
- `HazardConfig.lua` — hazard definitions and warning values
- `RoundConfig.lua` — round timing and reward tuning

As the game grows, prefer adding/tuning values here before hardcoding behavior in controllers or services.
