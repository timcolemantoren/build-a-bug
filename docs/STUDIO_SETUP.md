# Roblox Studio Setup

## 1. Clone the repo

```bash
git clone https://github.com/timcolemantoren/build-a-bug.git
cd build-a-bug
```

## 2. Install Rojo

Install Rojo 7+ from the official Rojo releases or with your preferred package manager.

Verify:

```bash
rojo --version
```

## 3. Start Rojo

From the repo root:

```bash
rojo serve
```

## 4. Connect Roblox Studio

1. Open Roblox Studio.
2. Create or open a blank baseplate/place.
3. Install/open the Rojo Studio plugin.
4. Connect to the local Rojo server.
5. The project should sync into:
   - `ReplicatedStorage/BuildABug`
   - `ServerScriptService/BuildABugServer`
   - `StarterPlayer/StarterPlayerScripts/BuildABugClient`

## 5. First Studio work

Create a rough arena in Workspace:

```text
Workspace
  BuildABugArena
    Crumbs      -- script will create this if missing
    Spawns      -- optional future spawn points
    Cover       -- leaf/tool cover objects
    Hazards     -- future hazard parts
```

For now, the scripts can create placeholder crumbs automatically.

## 6. DataStore note

Roblox DataStores require API services to be enabled for full Studio testing. If data does not save during local tests, check Studio game settings.
