# Changelog

## 2.4.2

A hidden hit keeps its color. A physical hit is white, and every other school keeps its own color.

### Fixed

- The color is applied before the number is drawn. A hidden amount blocked a color set afterward, so a physical hit could stay green.
- A physical hit is white. Holy, fire, nature, frost, shadow, and arcane each use their own color. A critical hit stays gold.

## 2.4.1

Healing shows again when the client hides the amount, and a critical heal is a lighter green.

### Fixed

- A heal or damage amount the client marks secret is drawn with its sign. It is not grouped with commas, because the number cannot be read. A readable amount is unchanged.

### Changed

- A critical heal is a lighter green than a normal heal. The old gold default on the healing list updates. A color you chose stays. Damage criticals stay gold.

## 2.4.0

A completed cast prints the mana, rage, energy, or focus it spent, in its own list.

### Added

- **Power** list. A cast that lands prints the amount it spent, such as `-8%` for mana and `-15` for rage. A downranked cast prints that rank's cost. A free cast prints nothing.
- Mana is a percent of your maximum by default. Rage, energy, and focus show the cost itself. Each resource has its own setting and color.
- The list starts to the right of center. Unlock it and drag, the same as the other lists.
- The main page sets lock, font, size, opacity, fade, lines, align, grow, and animate entry on all four lists. Crit size stays on damage, healing, and status.

## 2.3.1

Re-checked against the current Forever client; no code change was needed.

### Changed

- Verified against Forever client 1.60.1.70862 and the current EllesmereUIDamageMeters host.

## 2.3.0

`+Combat` is red, `-Combat` is green, and only one of them is ever on screen.

### Changed

- **Entering combat** and **Leaving combat** on the Status page are separate colors, red and green by default. The old single combat color is gone.
- A new combat line replaces the one still on screen at once, in the same repaint. The two never show together.
- A burst of hits within one frame repaints the damage and healing lists once, on the next frame, instead of once per hit. The combat line still replaces at once.

## 2.2.1

A change on the main page sets the same row on all three lists.

### Changed

- **Lock position**, font, size, opacity, fade, lines, align, grow, and animate entry on the main page set those rows on Damage, Healing, and Status. The rows there move to the new value.

## 2.2.0

Lines can sit in the center, and a new line can fade and slide into place.

### Added

- **Text align** includes **Center**. Lines sit on the middle of the anchor. While unlocked, a centered list shows only the top edge when it grows down, and only the bottom edge when it grows up.
- **Animate entry** fades a new line in and slides it into place. It is on by default. Turn it off for a line to appear at once.
- An unlocked list shows sample lines, so the drag block matches the text. They hide while a real line is on screen, and when the list is locked.

### Removed

- **Show dispels** is gone. The status list is combat only: `+Combat` and `-Combat`.

## 2.1.0

Combat state and dispels on you have their own list.

### Added

- **Status** is a third list, below healing. It has its own place, look, and colors.
- **Show dispels** prints the name of an aura removed from you, such as `Polymorph dispelled`.
- **Show combat** on the status page prints `+Combat` when you enter combat and `-Combat` when you leave.

### Changed

- **Show combat** moved from the damage page to the status page. A saved choice comes with it.

## 2.0.0

A scrolling list of damage, healing, and misses that land on you.

### Added

- **Enable Incoming Text** shows hits on you. New lines appear at the top.
- **Show damage**, **Show healing**, and **Show misses** choose which hits appear.
- **Font**, **Font size**, **Crit size**, **Opacity**, **Lines shown**, **Text align**, and **Grow** control the list. Fonts from other addons appear when the shared media library is installed.
- **Colors** sets physical hits, critical hits, spell schools, healing, and misses. A critical hit uses the critical color.
- **Lock position** locks the list. Turn it off to drag the corner square. Right-click the square to lock it.
- **Minimap button** opens settings. `/it` opens settings. `/it test` shows sample lines.
