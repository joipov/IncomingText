# Combat Text

Two lists of damage and healing, one for hits on you and one for hits on your target. Each list has its own place, size, face, and direction.

Target client: World of Warcraft **Forever** (`## Interface: 16001`).

## Features

- Incoming damage and healing are hits on you, in their own list. **Show incoming** hides that list.
- Outgoing damage and healing are hits on your target, in their own list. The game does not say who landed the hit, so in a group other players' hits are included. Alone, it is you and your pet. **Show outgoing** hides that list.
- Each list chooses **Font**, **Font size**, **Crit size**, and **Opacity**, left or right alignment, and whether new lines grow up or down. The font list includes faces from other addons when the shared media library is installed. Turn **Lock position** off to drag them. Right-click a list to lock both.
- **Colors** is shared by both lists: physical hits, critical hits, each spell school, healing, misses, and interrupts. A critical hit uses the critical color.
- **Line order** places the icon, the number, and the spell name. **Shorten spell names** turns Sinister Strike into SS. **Icons on normal hits** and **Icons on crits** add the spell icon. **Icons on white hits** adds the weapon from your latest swing: sword, axe, wand, bow, and so on. A white hit with no swing of yours stays a number. Damage over time stays unlabeled. A buff does not name the next hit. Damage keeps a name only from a spell that can hit an enemy, and a heal only from a helpful spell. A harmful spell that does not deal that hit, such as Gouge, can still name a swing in the same moment.
- A cast that dies on your target is one line. The line does not name your kick. The spell on that line follows the same order, and its icon follows **Icons on normal hits**.
- Miss, dodge, parry, block, and similar lines are optional.
- Minimap launcher via LibDBIcon when present, otherwise a built-in button. On by default. The addon compartment and `/ct` open settings.

## Commands

| Command | Effect |
| --- | --- |
| `/ct`, `/combattext` | Open the settings panel |
| `/ct test` | Show sample lines |
| `/ct help` | List these commands |

## Files

Loaded in TOC order; modules communicate only through the shared `ns` table.

| File | Concern |
| --- | --- |
| `Database.lua` | SavedVariables defaults, migrations, validation |
| `SpellLabel.lua` | Line order, short spell names, icon text, and which casts can name a hit |
| `List.lua` | Incoming and outgoing pools, fade, drag position |
| `Events.lua` | Unit combat feed, cast-name guess, login line |
| `MinimapButton.lua` | LibDBIcon launcher or built-in button, addon compartment |
| `Options.lua` | Settings pages, slash commands |

## Development

The repository lives outside the game folder; the AddOns entry is a
directory junction to it:

```
mklink /J "C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\CombatText" "D:\Repos\Joipov\CombatText"
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

Releases: push an annotated tag (`git tag -a 1.5.1 -m "1.5.1"`). The
`Package and release` workflow runs BigWigsMods/packager, which reads the game
version from the TOC and the manual changelog from `CHANGELOG.md`.
The audit note is not shipped.
