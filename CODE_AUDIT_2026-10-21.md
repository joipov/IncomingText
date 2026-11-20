# Incoming Text audit

Target: World of Warcraft Forever, `## Interface: 16001` (client 1.60.1.70862), Lua 5.1.
First audit for this addon. Compared 2026-10-21 against Shadowflare 0.21.3
(2026-10-21) and EllesmereUIDamageMeters / EllesmereUIChat 9.6.1 (2026-10-19).
Re-checked against client 1.60.1.70862 and EllesmereUIDamageMeters /
EllesmereUIChat 9.8.2 on 2026-11-08.

This note is for development. It is not shipped in the addon zip.

## What changed in 2.3.1

- Re-checked `UNIT_COMBAT`, the combat-state events, and the shared media
  font lookup against client 1.60.1.70862. The addon has no direct
  Ellesmere hooks, so the 9.8.2 damage-meter changes do not reach it. No
  code change.

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

## Secret amounts

As of 2.4.1, a secret `UNIT_COMBAT` amount is signed and handed to the
font. It is not read, compared, or grouped. A readable amount still goes
through `PlainNumber` and `FormatAmount`. The school and action fields
are read the same way as before: a secret school falls back to physical,
and a secret crit flag is not a crit. Spell cost in `Power.lua` still
drops a secret amount, because that line is a formatted percent or cost.

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
