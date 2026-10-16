# Changelog

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
