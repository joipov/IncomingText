# Incoming Text

A scrolling damage list, a scrolling healing list, a scrolling status list, and a scrolling power list. Each has its own place, size, face, and direction. Dodge, parry, and the other misses stay on the damage list. `+Combat` and `-Combat` stay on the status list. The mana, rage, energy, or focus a completed cast spends stays on the power list.

Target client: World of Warcraft **Forever**, release client (`_forever_`, `## Interface: 16001`). The old Forever beta (`_classic_beta_`) uses the same TOC and game type.

## Features

- Damage and misses go to the damage list. Healing goes to the healing list. Combat state goes to the status list. Spell cost goes to the power list. Each list has its own **Enable**. The damage list has **Show misses**. The status list has **Show combat**, which prints `+Combat` when you enter combat and `-Combat` when you leave. The power list prints the cost of a cast that lands, such as `-8%` or `-15`. A free cast prints nothing. Mana is a percent of your maximum by default. Rage, energy, and focus show the cost itself. Each resource has its own percent setting and color: mana blue, rage red, energy yellow, focus orange.
- Each list has **Lock position**, **X**, **Y**, **Font**, **Font size**, **Opacity**, **Fade time**, **Lines shown**, **Text align**, **Grow**, and **Animate entry**. Damage, healing, and status also have **Crit size**. **Text align** is left, center, or right. **Animate entry** fades a new line in and slides it into place. The same rows on the main page set those values on all four lists, and the rows there move to the new value. Crit size on the main page sets damage, healing, and status. The font list includes faces from other addons when the shared media library is installed. Turn **Lock position** off to drag an area or an edge. Sample lines show where the text will sit until a real line is on screen. Type **X** and **Y** on the mover or in settings for pixel placement. Right-click it to lock. The power list starts to the right of center.
- The **Damage** page colors physical hits, critical hits, each spell school, and misses. A physical hit is white. Holy, fire, nature, frost, shadow, and arcane each use their own color. A critical hit stays gold. The **Healing** page colors heals and critical heals. A normal heal is green, and a critical heal is a lighter green. An amount the client hides is still shown, with its sign and without commas. A readable amount is grouped as before. The **Status** page colors entering combat (red by default) and leaving combat (green by default) separately. Only one combat line is ever on screen: a new state replaces the old one at once.
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
| `List.lua` | Four line pools, fade, drag position |
| `Power.lua` | Spell cost, percent or raw text |
| `Events.lua` | Hits on you, combat state, spell cost, login line |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button, addon compartment |
| `Options.lua` | Damage, Healing, Status, and Power settings pages, slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\IncomingText" "D:\Repos\Joipov\IncomingText"
```

The same link works under `_classic_beta_` if the old beta client is still installed.

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

Releases: push an annotated tag (`git tag -a 2.4.3 -m "2.4.3"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
