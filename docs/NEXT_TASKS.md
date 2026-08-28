# Next Tasks

## Current playable loop

- Persistent backyard world with a nest/lobby area.
- Physical match queue circle with 20-second countdown.
- Shared multiplayer match roster.
- Roster locks for the final 3 seconds before a match.
- Queued players enter the same round at separate spawn points.
- Nonparticipants remain in the lobby and can queue for the next match.
- Player elimination records individual survival time.
- Round ends when time expires or all active players are eliminated.
- Pickups and temporary hazards reset between rounds; the map itself remains.
- Per-player results show crumbs collected and DNA earned during that round.
- Current map registry supports future selectable maps.
- Starter bugs use articulated visual rigs over the reliable Roblox Humanoid controller.
- Ant, Beetle, and Grasshopper have different silhouettes, movement profiles, abilities, and play styles.
- Player identity tags show name, level/title, bug, rounds played, and best survival.
- Lobby Profile / Customize hub uses scalable tabs for Stats, Builds, Colors, Eyes, Patterns, and Awards.
- Body Color, Eyes, and Patterns are functional cosmetic slots.
- Cosmetic ownership is account-wide, but each bug species remembers its own equipped appearance.
- Each bug also has three explicit saved preset slots: Build 1, Build 2, and Build 3. Presets are snapshots and are not automatically overwritten while experimenting.
- Three preset slots are a prototype starting point, not a product limit. Preset count should become config-driven so we can expand to 6+ saved builds per bug without changing the persistence model or rebuilding the UI.
- Available DNA is spendable currency. Lifetime DNA is permanent level/title progression and never decreases when DNA is spent.
- Exit Round rolls back both available and lifetime DNA earned during the forfeited round.
- Cosmetic visual definitions are separated from commerce metadata so prices, rarity, availability, achievements, and future Robux products can evolve independently.
- PlayerDataService has one GrantCosmetic path for future DNA, achievement, event, and Robux entitlements.
- Starter Awards track full-round survival, rounds played, food collected, and Lifetime DNA, with achievement-only cosmetic rewards.
- Achievement unlocks have their own reward banner and audio cue.
- Grass is interactive: some blades fall when touched and occasional nearby blades can coil and flick an active bug during a round.
- Crumbs and DNA have distinct pickup sounds; phase, hazard, impact, and elimination prototype audio is centralized for later replacement.
- Any real health loss during a round now produces proportional red screen feedback plus a centralized hit sound, independent of the damage source.
- Backyard hazards now include Shoe Stomp, Sprinkler Burst, Bird Shadow, a moving Rolling Ball, and a falling Giant Raindrop with a visible splash landing zone.

## Next mechanics / player-identity pass

1. Continue adding genuinely different hazard motion patterns: gusts, leaf sweeps, rake passes, and similar readable backyard events. The Raindrop fall behavior can later be reused for acorns in Fall Backyard.
2. Make saved-build preset count config-driven, then expand beyond the current three slots once the final customization breadth is clearer.
3. Test the Builds tab on desktop and iPad, including save, overwrite, load, species switching, and empty-slot behavior.
4. Test the Awards tab and achievement unlock pacing, then expand with skill-based achievements such as critical-health recovery, bug-specific survival, and streaks.
5. Tune Body Color, Eyes, and Pattern prices against actual DNA earned per two-minute round.
6. Add additional cosmetic slots: shell/wing treatment, antenna accents, and trails.
7. Refine overhead identity readability at different distances and player counts.
8. Continue multiplayer testing with 2-4 Studio clients and verify queue/lock/elimination/results behavior.
9. Test pickup competition with multiple players and decide whether some collectibles should become player-specific.
10. Add insect unlock pricing after round economy is better understood.
11. Add map voting after the shared-match loop and player progression are stable.
12. Consider a lobby leaderboard or showcase once progression has enough history to make it interesting.

## Audio / music roadmap

Treat audio as part of the core experience rather than final-launch decoration.

- Lobby/nest ambience should feel safe, curious, and playful.
- Round music should build by phase: Scavenge, Trouble, Chaos, Final Scramble.
- Important gameplay events need distinct readable cues: queue lock, round start, phase transitions, hazard warnings, hazard impacts, player damage, grass flick, crumb pickup, DNA pickup, healing, ability use, low health, squish/elimination, reward/unlock, and cosmetic equip/purchase.
- Environment should have subtle macro-backyard ambience: grass rustle, wind, distant birds, hose/water, occasional human/toy noises.
- Bug movement sounds should remain light and stylized rather than noisy on every footstep.
- Sound cues should reinforce danger and anticipation without becoming necessary for players who play muted.
- Keep SFX event names/config centralized so maps and cosmetics can add audio without hard-coding asset IDs throughout gameplay services.

## Monetization / store roadmap

- Keep gameplay power earnable and separate from cosmetic monetization.
- Allow standard cosmetics to be earned with DNA; many can later offer an alternate Robux purchase path.
- Keep a small number of achievement cosmetics exclusive so some looks communicate accomplishment rather than spending.
- Configure actual Roblox Developer Product IDs only after products are created. Current catalog IDs remain disabled placeholders.
- Robux receipts should grant through the same permanent cosmetic ownership system as DNA and achievements.
- Do not grant purchases from client purchase-finished events.
- Future v2 option: rotating featured stock for rarer cosmetics, with most items still earnable for DNA when in stock and optional Robux availability.
- Store rotation should encourage return visits without creating gameplay advantages or excessively punitive missed windows.
- See `docs/MONETIZATION_PLAN.md` for the detailed architecture and rules.

## Environment polish backlog

- Mushrooms still read too flat; give them stronger 3D silhouettes and useful collision where appropriate.
- Rework the brick/brick-mound element; it currently feels visually out of place.
- Scatter occasional recognizable backyard toys and human objects as landmarks.
- Continue improving natural silhouettes for grass, leaves, rocks, twigs, puddles, and terrain over time.
- Keep the environment stylized and readable rather than chasing photorealism.

## Future maps / modes

Build map selection as an expansion system, with each map using the same core match mechanics but its own environment and hazards.

- **Backyard**: default/core map.
- **Fall Backyard**: seasonal leaves, acorns, wind, mud/rain, pumpkins, rakes, autumn palette.
- **Forest**: denser vegetation, logs, streams, mushrooms, predators, vertical traversal.
- **Wacky / Space**: intentionally playful non-realistic map with unusual gravity, hazards, and traversal.
- Additional seasonal or themed maps can plug into the same map registry and future voting system.
