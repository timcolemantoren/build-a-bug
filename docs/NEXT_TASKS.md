# Next Tasks

## Current playable loop

- Persistent backyard world with a nest/lobby area.
- Physical match queue circle with 20-second countdown.
- Shared multiplayer match roster with a final 3-second roster lock.
- Queued players enter the same two-minute survival round at separate spawn points.
- Nonparticipants remain in the lobby and can queue for the next match.
- Player elimination records individual survival time; rounds end on time expiry or when all active players are eliminated.
- Pickups and temporary hazards reset between rounds; the map itself remains.
- Per-player results show crumbs collected and DNA earned during that round.
- Current map registry supports future selectable maps.
- Playable bugs use articulated visual rigs over the reliable Roblox Humanoid controller.
- Free starter trio: Ant, Beetle, Grasshopper.
- First progression bugs: Ladybug at 850 Available DNA and Mantis at 2,500 Available DNA.
- Ladybug has Wing Burst and modest passive damage reduction. Mantis has Pounce and a stronger jump profile.
- Bug unlock purchases use the same explicit Buy / Cancel confirmation principle as DNA cosmetics.
- Player identity tags show name, level/title, bug, rounds played, and best survival.
- Lobby Profile / Customize hub uses scalable tabs for Stats, Builds, Colors, Eyes, Patterns, and Awards.
- Body Color, Eyes, and Patterns are functional mix-and-match cosmetic slots.
- Cosmetic ownership is account-wide, but each bug species remembers its own equipped appearance.
- Each bug has six explicit saved preset slots, Build 1 through Build 6. Saved-build count is config-driven for future expansion.
- Available DNA is spendable currency. Lifetime DNA is permanent level/title progression and never decreases when DNA is spent.
- Lifetime DNA progression now uses wider milestones: 150, 400, 800, 1,500, 2,500, 4,000, 6,000, 8,000, and 10,000 DNA for levels 2 through 10.
- Exit Round rolls back both available and lifetime DNA earned during the forfeited round.
- DNA purchases require explicit Buy / Cancel confirmation showing cost, current balance, and post-purchase balance.
- Starter Awards have expanded into eight milestones spanning full-round survival, rounds played, food collected, and Lifetime DNA.
- Longer-tail Awards include 10 full survives, 25 rounds, 500 food, and 2,500 Lifetime DNA, with exclusive cosmetic rewards.
- Premium full-body Skin architecture now exists separately from standard cosmetics. Neon Circuit, Candy Pop, and Ember are the first Robux-only Skin concepts. Their Roblox Pass IDs remain disabled at `0` until real Passes are created.
- Standard cosmetic visual definitions remain separated from commerce metadata so prices, rarity, availability, achievements, and future Robux shortcuts can evolve independently.
- Grass is interactive: some blades fall when touched and occasional nearby blades can coil and flick an active bug during a round.
- Crumbs and DNA have distinct pickup sounds; phase, hazard, impact, and elimination prototype audio is centralized for later replacement.
- Any real health loss during a round produces proportional red screen feedback plus a centralized hit sound.
- Backyard hazards include Shoe Stomp, Sprinkler Burst, Bird Shadow, Rolling Ball, Giant Raindrop, non-damaging Wind Gust, and physical Rake Sweep.

## Next progression / collection pass

1. Field-test Ladybug and Mantis unlock flow, silhouettes, animation, powers, and DNA prices. Tune them as sidegrades rather than upgrades.
2. Add pattern parity to the extended Ladybug and Mantis rigs; color and eye cosmetics should remain fully compatible.
3. Add a read-only Skins collection/preview tab, then activate actual Robux purchase buttons only after real Roblox Pass IDs exist.
4. Expand bug progression beyond the first two unlockables only after their pacing is tested. Candidates should fill distinct movement/ability niches while remaining insects.
5. Test the widened level curve against actual Lifetime DNA earned per round. Preserve a quick early sense of progress while making later levels multi-session goals.
6. Expand Awards with skill-oriented badges after the long-tail stat milestones are proven: critical-health recovery, bug-specific survival, streaks, hazard escapes, and map-specific accomplishments.
7. Add richer cosmetic slots such as shell/wing treatment, antenna accents, and trails.
8. Tune standard Color, Eye, and Pattern DNA prices against bug-unlock costs so cosmetics remain tempting without making new bugs feel unreachable.
9. Test six saved Builds slots on desktop and iPad, including scrolling, save, overwrite, load, species switching, and empty-slot behavior.
10. Continue multiplayer testing with 2-4 Studio clients and verify queue, elimination, pickups, progression unlocks, and results behavior.
11. Add map voting after the collection/progression loop is stable.
12. Consider a lobby collection showcase or leaderboard once persistent progression has enough history to make it meaningful.

## Audio / music roadmap

Treat audio as part of the core experience rather than final-launch decoration.

- Lobby/nest ambience should feel safe, curious, and playful.
- Round music should build by phase: Scavenge, Trouble, Chaos, Final Scramble.
- Important gameplay events need distinct readable cues: queue lock, round start, phase transitions, hazard warnings, hazard impacts, player damage, grass flick, crumb pickup, DNA pickup, healing, ability use, low health, squish/elimination, reward/unlock, bug unlock, and cosmetic equip/purchase.
- Environment should have subtle macro-backyard ambience: grass rustle, wind, distant birds, hose/water, occasional human/toy noises.
- Bug movement sounds should remain light and stylized rather than noisy on every footstep.
- Sound cues should reinforce danger and anticipation without becoming necessary for players who play muted.
- Keep SFX event names/config centralized so maps, bugs, and cosmetics can add audio without hard-coding asset IDs throughout gameplay services.

## Monetization / store roadmap

- Never sell survival power.
- Standard colors, eyes, patterns, and similar cosmetics remain earnable through DNA or achievements.
- A subset of standard cosmetics may later have an optional Robux shortcut.
- Premium full-body Skins are Robux-only and remain visual-only.
- Permanent one-time premium Skins should use Roblox Pass entitlements. Current Skin Pass IDs remain disabled placeholders until real Passes are created.
- Keep some achievement cosmetics exclusive so certain looks communicate accomplishment rather than spending.
- Any spendable action requires explicit player confirmation. Roblox purchases also receive the platform purchase prompt.
- Do not grant paid ownership from client purchase-finished events.
- Future v2 option: rotating featured stock for rarer standard cosmetics, with most items still earnable for DNA when in stock.
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
