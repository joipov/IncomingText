# Incoming Text audit

Target: World of Warcraft Forever, `## Interface: 16001` (client 1.60.1.70425), Lua 5.1.
First audit for this addon. Compared 2026-10-21 against Shadowflare 0.21.3
(2026-10-21) and EllesmereUIDamageMeters / EllesmereUIChat 9.6.1 (2026-10-19).

This note is for development. It is not shipped in the addon zip.

## Premise confirmed

No compared addon reads the combat log on Forever. Shadowflare uses
`UNIT_AURA`, spell-activation, and usable-spell events; Ellesmere's meter
uses the aggregated `C_DamageMeter` session API. `UNIT_COMBAT` on the
player remains the only per-hit source here, and it stays. `C_DamageMeter`
was not adopted: it is aggregated, has no per-hit amounts, and would be
that addon's feature, not a fix.

## What changed in 2.3.0 (with the combat-color pass)

- Paint coalescing: a burst of hits within one frame repaints the damage
  or healing list once, on the next frame (`paintedThisFrame` /
  `pendingPaint` in `List.lua`). Combat-state replacement still paints in
  the same call, so `+Combat` and `-Combat` never draw together. A full
  24-slot `Paint()` previously ran per hit.
- School masks no longer assume the client's `bit` library: `bit.band` is
  used when present, with the same test done arithmetically otherwise.
  Plain Lua 5.1 has no bit library (lua.org 5.1 manual).

## Secret amounts (documented behaviour, not a defect to engineer around)

`UNIT_COMBAT` amounts pass through `PlainNumber`, which drops combat
secrets. If this build delivers amounts as secrets in combat, those hits
cannot be turned into text by any means available to an addon, and the
drop is the honest behaviour. It is stated in `Events.lua` where it
happens. The school and action fields are read the same way.

## Still holds

- One event frame, player-only unit events, feature-gated registration
  (events register only while their list is enabled), a frame pool built
  once, and `OnUpdate` only while a line is entering or fading.
- Settings registration uses `Settings.RegisterInitializer`; the other
  Joipov addons use the direct form. Both work on this client; no
  mass conversion. See STYLE.md.
- Per-list Enable rows stand in for a master Enable. Recorded in STYLE.md.

## Checked in the client (manual pass, 2.3.0)

- [ ] Dense combat: damage and healing lines keep up, with no visible
      stutter; entering and leaving combat still swaps the status line
      at once.
- [ ] `/it test` shows the sample lines, including `+Combat`.
