# Combat Text audit — 2026-10-14

Target: World of Warcraft Forever, `## Interface: 16001`, Lua 5.1.
References: Ketho's vscode-wow-api annotations, the Forever API, and the other Joipov addons.

## Already in good shape

- One event frame. `OnUpdate` runs only while a line is fading. The line pool is fixed.
- Secret values are checked before compare, index, or arithmetic.
- TOC fields follow the house order. The minimap button matches the shared file apart from the title and icon.
- **Enable Combat Text** and **Minimap button** stay active. Every other row greys while the addon is off.
- Settings rows go through `Settings.RegisterInitializer`, so the settings search stays secure.
- LibSharedMedia, LibDataBroker, and LibDBIcon stay optional and are not embedded.
- The login line, the compartment tooltip, and the slash commands use the house wording.

## This pass

- A buff no longer names the next damage number. Damage keeps a harmful cast. A heal keeps a helpful cast.
- The store page says the same.
- `assets/screenshots/` is present, the same as the other addons.
