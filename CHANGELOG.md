# Changelog

## 1.5.1

A buff no longer names the next damage number.

### Fixed

- Slice and Dice and other buffs no longer label the white swing that lands just after them. A damage number keeps a name only when the cast can hit an enemy. A heal keeps a name only from a helpful spell.
- A harmful spell that does not deal the hit, such as Gouge, can still name a swing that lands in the same moment.

## 1.5.0

Each list picks its own font and opacity. Right-click locks both lists.

### Added

- **Font** includes faces from other addons when the shared media library is installed. Friz Quadrata, Arial Narrow, Skurri, and Morpheus stay available without it.
- **Opacity** on **Incoming** and **Outgoing** sets how solid that list's text and icons are. They fade out from that level.
- Right-click an unlocked list to lock both. The frame shows "Right-click to lock."

### Changed

- **Opacity** left **General**. An older save copies that one value onto both lists.
- A saved font key such as FRIZ becomes the face name Friz Quadrata.

## 1.4.0

A line can put the icon, the number, and the name in the order you pick. Text and icons share one opacity.

### Added

- **Opacity** sets how solid the text and icons are. They fade out from that level.
- **Line order** chooses the order of the icon, the number, and the spell name. A piece that is off is skipped.
- **Icons on normal hits**, **Icons on crits**, and **Icons on white hits** turn the icon on for that kind of hit. A white hit uses the weapon that just swung: sword, axe, wand, bow, and so on.

### Changed

- **Show spell names** and **Show spell icons** are now **Line order**. An older save that showed icons keeps the icon in front of the number, with normal and crit icons on.

## 1.3.0

An outgoing spell can show as initials, or as its icon.

### Added

- **Shorten spell names** turns a spell into its initials. Sinister Strike becomes SS. A one-word name stays whole.
- **Show spell icons** puts the spell's icon in place of its name. The icon matches the line size. The interrupt line uses the same short name or icon.

## 1.2.0

Each list can be hidden on its own, and the text has a size, a face, and a color you can change.

### Added

- **Show incoming** and **Show outgoing** hide that list and stop its events.
- **Crit size** sets the size of a critical hit. **Font** is Friz Quadrata, Arial Narrow, Skurri, or Morpheus.
- **Colors** sets physical hits, critical hits, spell schools, healing, misses, and interrupts. A critical hit uses the critical color. A line still on screen picks up a color change.

### Changed

- A critical hit uses **Crit size** instead of a larger copy of **Font size**.

## 1.1.0

Incoming and outgoing hits are two lists, each with its own place and text.

### Added

- **General**, **Incoming**, and **Outgoing** are separate settings pages.
- **Text align** puts a list on the left or the right.
- **Grow** puts the newest line at the top or at the bottom.
- Each list has its own **Font size** and **Lines shown**.

### Changed

- **Lock position** locks both lists. Turn it off and each list drags on its own.
- **Show misses** is set separately for incoming and outgoing.

## 1.0.0

A scrolling list of incoming and outgoing damage and healing.

### Added

- **Enable Combat Text** shows incoming and outgoing hits in a list. New lines appear at the top.
- **Show incoming damage**, **Show incoming healing**, **Show outgoing damage**, and **Show outgoing healing** choose which hits appear. Outgoing hits are everything that lands on your target.
- **Show misses** adds miss, dodge, parry, block, and similar lines.
- **Show spell names** puts your latest direct cast on the next outgoing hit.
- **Font size**, **Lines shown**, and **Lock position** control the list. Turn the lock off to drag it.
- **Minimap button** opens settings. `/ct` opens settings. `/ct test` shows sample lines.
