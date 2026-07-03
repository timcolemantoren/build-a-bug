# Build a Bug

A Roblox/Rojo project for a kid-friendly insect survival game.

**Working concept:** players choose a bug base, enter a giant backyard survival round, dodge hazards, collect crumbs/DNA, and unlock cosmetic bug parts.

## MVP target

The first playable milestone is intentionally small:

1. Player joins.
2. Player chooses Ant, Beetle, or Grasshopper.
3. Player enters a graybox backyard arena.
4. A timed survival round starts.
5. Crumbs spawn as collectibles.
6. A simple environmental hazard fires.
7. The round ends and DNA is awarded.

## Project structure

```text
src/
  client/   LocalScripts and UI controllers
  server/   Server scripts and services
  shared/   Config, types, and remote names shared by client/server
```

## Local setup

Recommended tools:

- Roblox Studio
- Rojo 7+
- VS Code
- Git / GitHub Desktop

Typical workflow:

```bash
git clone https://github.com/timcolemantoren/build-a-bug.git
cd build-a-bug
rojo serve
```

Then open Roblox Studio, install/use the Rojo plugin, and connect to the local Rojo server.

## Design direction

Visual target: **stylized macro backyard adventure** — oversized grass, dirt clumps, crumbs, flowers, garden tools, water droplets, and cute-cool bugs.

Initial bug bases:

- **Ant** — balanced worker, carries more food
- **Beetle** — armored survivor, slower movement
- **Grasshopper** — fragile but fast with a big leap

## Development rule

Keep the first version playable before making it pretty. A graybox backyard with a real loop is more valuable than a beautiful map with no game.
