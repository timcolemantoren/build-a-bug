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
- Starter bugs now use articulated visual rigs over the reliable Roblox Humanoid controller.
- Ant, Beetle, and Grasshopper have different silhouettes, movement profiles, abilities, and play styles.

## Next mechanics / player-identity pass

1. Continue multiplayer testing with 2-4 Studio clients and verify queue/lock/elimination/results behavior.
2. Refine bug animation and ground contact without changing the proven movement controller.
3. Keep bug powers/roles clearly explained in pre-round selection UI.
4. Keep player identity visible above each insect in lobby and gameplay: name, level/title, bug, rounds played, and best survival.
5. Add a dedicated lobby Profile / Customization area rather than burying customization inside bug selection.
6. Cosmetics should change appearance only; gameplay stats continue to come from the chosen bug archetype.
7. Candidate customization categories: body color, pattern, eyes, shell/wing treatment, antenna details, and earned cosmetic accents.
8. Decide which cosmetics are DNA unlocks versus achievements/special rewards.
9. Tune reward pacing now that per-round reward deltas are visible.
10. Test pickup competition with multiple players and decide whether some collectibles should become player-specific.
11. Add map voting only after the core shared-match loop is stable.
12. Add insect unlock pricing after round economy is better understood.

## Environment polish backlog

- Mushrooms still read too flat; give them stronger 3D silhouettes and useful collision where appropriate.
- Rework the brick/brick-mound element; it currently feels visually out of place.
- Scatter occasional recognizable backyard toys and human objects as landmarks.
- Continue improving natural silhouettes for grass, leaves, rocks, twigs, puddles, and terrain over time.
- Keep the environment stylized and readable rather than chasing photorealism.

## Future maps / modes

Build map selection as an expansion system, with each map using the same core match mechanics but its own environment and hazards.

- **Backyard** — default/core map.
- **Fall Backyard** — seasonal leaves, acorns, wind, mud/rain, pumpkins, rakes, autumn palette.
- **Forest** — denser vegetation, logs, streams, mushrooms, predators, vertical traversal.
- **Wacky / Space** — intentionally playful non-realistic map with unusual gravity, hazards, and traversal.
- Additional seasonal or themed maps can plug into the same map registry and future voting system.
