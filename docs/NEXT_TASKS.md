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
- Lobby Profile / Customize hub shows progression, stats, currency, and cosmetics.
- Body Color and Eyes are functional cosmetic slots.
- Cosmetic unlocks are account-wide and cosmetic-only.
- Available DNA is spendable currency. Lifetime DNA is permanent level/title progression and never decreases when DNA is spent.
- Exit Round rolls back both available and lifetime DNA earned during the forfeited round.

## Next mechanics / player-identity pass

1. Continue multiplayer testing with 2-4 Studio clients and verify queue/lock/elimination/results behavior.
2. Refine overhead identity readability at different distances and player counts.
3. Tune cosmetic prices against actual DNA earned per two-minute round.
4. Add more cosmetic slots: patterns, shell/wing treatment, antenna accents, and trails.
5. Add achievement/special-reward cosmetics alongside DNA-purchased cosmetics.
6. Cosmetics must remain appearance-only; gameplay stats continue to come from the chosen bug archetype.
7. Test pickup competition with multiple players and decide whether some collectibles should become player-specific.
8. Add insect unlock pricing after round economy is better understood.
9. Add map voting after the shared-match loop and player progression are stable.
10. Consider a lobby leaderboard or showcase once progression has enough history to make it interesting.

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
