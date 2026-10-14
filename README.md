# Incoming Text

A scrolling list of damage, healing, and misses that land on you. The list has its own place, size, face, and direction.

Target client: World of Warcraft **Forever** (`## Interface: 16001`).

## Features

- Damage, healing, and misses are hits on you. **Show damage**, **Show healing**, and **Show misses** choose which lines appear.
- **Font**, **Font size**, **Crit size**, and **Opacity** set the text. Lines sit on the left or the right, and new lines grow up or down. The font list includes faces from other addons when the shared media library is installed. Turn **Lock position** off to drag the corner square. Right-click the square to lock it.
- Physical hits, critical hits, each spell school, healing, and misses each have a color on the same page. A critical hit uses the critical color.
- Minimap launcher via LibDBIcon when present, otherwise a built-in button. On by default. The addon compartment and `/it` open settings.

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
| `List.lua` | Line pool, fade, drag position |
| `Events.lua` | Hits on you, login line |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button, addon compartment |
| `Options.lua` | Settings page, slash commands |

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

Releases: push an annotated tag (`git tag -a 2.0.0 -m "2.0.0"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
