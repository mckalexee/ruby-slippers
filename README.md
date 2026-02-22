# Hearthstone Helper

A World of Warcraft addon that tracks your hearthstone toy collection and lets you use a random hearthstone with one click.

## Features

- **Random Hearthstone Button** - A floating button that uses a random hearthstone from your collection each click. Bind it to a key with `/click HearthstoneHelperButton` in a macro.
- **Collection Tab** - Adds a "Hearthstones" tab to the Collections Journal showing all 37+ hearthstone toys, which ones you own, and where to get the rest.
- **Favorites & Exclusions** - Star your favorites or exclude hearthstones from the random pool.
- **Filters & Search** - Filter by category (Home/Garrison/Dalaran), ownership, or search by name.
- **Settings** - Configure button scale, lock position, toggle Garrison/Dalaran hearthstones in the random pool, favorites-only mode.
- **Minimap Compartment** - Access from the addon compartment dropdown on the minimap.

## Installation

Copy the `HearthstoneHelper/` folder into:

```
World of Warcraft/_retail_/Interface/AddOns/
```

## Usage

### Slash Commands

| Command | Action |
|---------|--------|
| `/hs` | Toggle the floating button |
| `/hs show` / `hide` | Show or hide the button |
| `/hs lock` / `unlock` | Lock or unlock button dragging |
| `/hs random` | Pick a new random hearthstone |
| `/hs scale 0.5-2.0` | Set button scale |
| `/hs collection` | Open the Collections Journal |
| `/hs config` | Open settings |

### Macro

Create a macro with the following to bind a random hearthstone to a key:

```
/click HearthstoneHelperButton
```

### Button Controls

- **Left-click** - Use a random hearthstone
- **Right-click** - Open the Collections Journal
- **Drag** - Move the button (unless locked)

## Requirements

- World of Warcraft 12.0 (The War Within / Midnight)
- Interface version 120001

## Bundled Libraries

- [LibStub](https://www.wowace.com/addons/libstub/) - Library versioning
- [SecureTabs-2.0](https://github.com/Jaliborc/SecureTabs-2.0) by Jaliborc - Taint-free tab injection
