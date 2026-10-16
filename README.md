# Incoming Text

A scrolling damage list, a scrolling healing list, and a scrolling status list. Each has its own place, size, face, and direction. Dodge, parry, and the other misses stay on the damage list. `+Combat`, `-Combat`, and dispels stay on the status list.

Target client: World of Warcraft **Forever** (`## Interface: 16001`).

## Features

- Damage and misses go to the damage list. Healing goes to the healing list. Combat state and dispels go to the status list. Each list has its own **Enable**. The damage list has **Show misses**. The status list has **Show combat** and **Show dispels**. **Show combat** prints `+Combat` when you enter combat and `-Combat` when you leave. **Show dispels** prints the name of an aura removed from you, such as `Polymorph dispelled`.
- Each list has **Lock position**, **Font**, **Font size**, **Crit size**, **Opacity**, **Fade time**, **Lines shown**, **Text align**, and **Grow**. The same rows on the main page write those values onto all three lists. The font list includes faces from other addons when the shared media library is installed. Turn **Lock position** off to drag an area or either edge. Right-click it to lock.
- The **Damage** page colors physical hits, critical hits, each spell school, and misses. The **Healing** page colors heals and critical heals. A critical line uses that list's critical color. The **Status** page colors combat state and dispels.
- One minimap launcher, via LibDBIcon when present, otherwise a built-in button. On by default. The addon compartment and `/it` open settings.

## Commands

| Command | Effect |
| --- | --- |
| `/it`, `/incoming` | Open the settings panel |
| `/it test` | Show sample lines |
| `/it help` | List these commands |

## Files

Loaded in TOC order; modules communicate only through the shared `ns` table.

| File | Concern |
| --- | --- |
| `Database.lua` | SavedVariables defaults and validation |
| `List.lua` | Three line pools, fade, drag position |
| `Events.lua` | Hits on you, combat state, dispels, login line |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button, addon compartment |
| `Options.lua` | Damage, Healing, and Status settings pages, slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\IncomingText" "D:\Repos\Joipov\IncomingText"
```

Static checks (no game client needed):

```
luacheck .            # .luacheckrc: Lua 5.1, explicit WoW globals
luajit tests/run.lua  # or: lua5.1 tests/run.lua
```

LuaLS uses `.luarc.json` and Ketho's WoW API annotations. The repo-local
`.annotations/` folder declares the Forever secret-value helpers those
annotations lack.

`assets/` is release media for CurseForge and Wago (screenshots, and a logo
when one exists). The game does not load it, and it is not part of the addon
zip. Do not delete it during cleanup.

Local zip, with the addon folder at the root, written to `.release/`:

```
powershell -File package.ps1
```

Releases: push an annotated tag (`git tag -a 2.1.0 -m "2.1.0"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
